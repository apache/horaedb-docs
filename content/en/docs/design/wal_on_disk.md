---
title: "WAL on Disk"
---

## Architecture

This section introduces the implementation of a standalone Write-Ahead Log (WAL, hereinafter referred to as "the log") based on a local disk. In this implementation, the log is managed at the region level.

```
            ┌────────────────────────────┐
            │          HoraeDB           │
            │                            │
            │ ┌────────────────────────┐ │
            │ │          WAL           │ │         ┌────────────────────────┐
            │ │                        │ │         │                        │
            │ │         ......         │ │         │      File System       │
            │ │                        │ │         │                        │
            │ │ ┌────────────────────┐ │ │ manage  │ ┌────────────────────┐ │
 Write ─────┼─┼─►       Region       ├─┼─┼─────────┼─►     Region Dir     │ │
            │ │ │                    │ │ │         │ │                    │ │
 Read  ─────┼─┼─►   ┌────────────┐   │ │ │  mmap   │ │ ┌────────────────┐ │ │
            │ │ │   │  Segment 0 ├───┼─┼─┼─────────┼─┼─► Segment File 0 │ │ │
            │ │ │   └────────────┘   │ │ │         │ │ └────────────────┘ │ │
Delete ─────┼─┼─►   ┌────────────┐   │ │ │  mmap   │ │ ┌────────────────┐ │ │
            │ │ │   │  Segment 1 ├───┼─┼─┼─────────┼─┼─► Segment File 1 │ │ │
            │ │ │   └────────────┘   │ │ │         │ │ └────────────────┘ │ │
            │ │ │   ┌────────────┐   │ │ │  mmap   │ │ ┌────────────────┐ │ │
            │ │ │   │  Segment 2 ├───┼─┼─┼─────────┼─┼─► Segment File 2 │ │ │
            │ │ │   └────────────┘   │ │ │         │ │ └────────────────┘ │ │
            │ │ │       ......       │ │ │         │ │       ......       │ │
            │ │ └────────────────────┘ │ │         │ └────────────────────┘ │
            │ │         ......         │ │         │         ......         │
            │ └────────────────────────┘ │         └────────────────────────┘
            └────────────────────────────┘
```

## Data Model

### File Paths

Each region has its own directory to manage all segments for that region. The directory is named after the region's ID. Each segment is named using the format `segment_<id>.wal`, with IDs starting from 0 and incrementing.

### Segment Format

Logs for all tables within a region are stored in segments, arranged in ascending order of sequence numbers. The structure of the segment files is as follows:

```
   Segment0            Segment1
┌────────────┐      ┌────────────┐
│ Magic Num  │      │ Magic Num  │
├────────────┤      ├────────────┤
│   Record   │      │   Record   │
├────────────┤      ├────────────┤
│   Record   │      │   Record   │
├────────────┤      ├────────────┤   ....
│   Record   │      │   Record   │
├────────────┤      ├────────────┤
│     ...    │      │     ...    │
│            │      │            │
└────────────┘      └────────────┘
    seg_0               seg_1
```

In memory, each segment stores additional information used for read, write, and delete operations:

```rust
pub struct Segment {
    /// A hashmap storing both min and max sequence numbers of records within
    /// this segment for each `TableId`.
    table_ranges: HashMap<TableId, (SequenceNumber, SequenceNumber)>,

    /// An optional vector of positions within the segment.
    record_position: Vec<Position>,

    ...
}
```

### Log Format

The log format within a segment is as follows:

```
+---------+--------+------------+--------------+--------------+-------+
| version |  crc   |  table id  | sequence num | value length | value |
|  (u8)   | (u32)  |   (u64)    |    (u64)     |     (u32)    |(bytes)|
+---------+--------+------------+--------------+--------------+-------+
```

Field Descriptions:

1. `version`: Log version number.

2. `crc`: Used to ensure data consistency. Computes the CRC checksum from the table id to the end of the record.

3. `length`: The number of bytes from the table id to the end of the record.

4. `table id`: The unique identifier of the table.

5. `sequence num`: The sequence number of the record.

6. `value length`: The byte length of the value.

7. `value`: The value in the general log format.

The region ID is not stored in the log because it can be obtained from the file path.

## Main Processes

### Opening the WAL

1. Identify all region directories under the WAL directory.

2. In each region directory, identify all segment files.

3. Open each segment file, traverse all logs within it, record the start and end offsets of each log, and record the minimum and maximum sequence numbers of each `TableId` in the segment, then close the file.

4. If there is no region directory or there are no segment files under the directory, automatically create the corresponding directory and files.

### Reading Logs

1. Based on the metadata of the segments, determine all segments involved in the current read operation.

2. Open these segments in order of their IDs from smallest to largest, and decode the raw bytes into logs.

### Writing Logs

1. Serialize the logs to be written into byte data and append them to the segment file with the largest ID.

2. When a segment is created, it pre-allocates a fixed size of 64MB and will not change dynamically. When the pre-allocated space is used up, a new segment is created, and appending continues in the new segment.

3. After each append, `flush` is not called immediately; by default, `flush` is performed every ten writes or when the segment file is closed.

4. Update the segment's metadata `table_ranges` in memory.

### Deleting Logs

Suppose logs in the table with ID `table_id` and sequence numbers less than `seq_num` need to be marked as deleted:

1. Update the `table_ranges` field of the relevant segments in memory, updating the minimum sequence number of the table to `seq_num + 1`.

2. If after modification, the minimum sequence number of the table in this segment is greater than the maximum sequence number, remove the table from `table_ranges`.

3. If a segment's `table_ranges` is empty and it is not the segment with the largest ID, delete the segment file.
