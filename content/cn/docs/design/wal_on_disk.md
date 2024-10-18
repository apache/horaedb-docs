---
title: "基于本地磁盘的 WAL"
---

## 架构

本节将介绍基于本地磁盘的单机版 WAL（Write-Ahead Log，以下简称日志）的实现。在此实现中，日志按 region 级别进行管理。

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
            │ │ │   │  Segment 1 ├───┼─┼─┼─────────┼─┼─► SegmenteFile 1 │ │ │
            │ │ │   └────────────┘   │ │ │         │ │ └────────────────┘ │ │
            │ │ │   ┌────────────┐   │ │ │  mmap   │ │ ┌────────────────┐ │ │
            │ │ │   │  Segment 2 ├───┼─┼─┼─────────┼─┼─► SegmenteFile 2 │ │ │
            │ │ │   └────────────┘   │ │ │         │ │ └────────────────┘ │ │
            │ │ │       ......       │ │ │         │ │       ......       │ │
            │ │ └────────────────────┘ │ │         │ └────────────────────┘ │
            │ │         ......         │ │         │         ......         │
            │ └────────────────────────┘ │         └────────────────────────┘
            └────────────────────────────┘
```

## 数据模型

### 文件路径

每个 region 都拥有一个目录，用于管理该 region 的所有 segment。目录名为 region 的 ID。每个 segment 的命名方式为 `segment_<id>.wal`，ID 从 0 开始递增。

### Segment 的格式

一个 region 中所有表的日志都存储在 segments 中，并按照 sequence number 从小到大排列。segment 文件的结构如下：

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

在内存中，每个 segment 还会存储一些额外的信息以供读写和删除操作使用：

```
pub struct Segment {
    /// A hashmap storing both min and max sequence numbers of records within
    /// this segment for each `TableId`.
    table_ranges: HashMap<TableId, (SequenceNumber, SequenceNumber)>,

    /// An optional vector of positions within the segment.
    record_position: Vec<Position>,

    ...
}
```

### 日志格式

segment 中的日志格式如下：

```
+---------+--------+------------+--------------+--------------+-------+
| version |  crc   |  table id  | sequence num | value length | value |
|  (u8)   | (u32)  |   (u64)    |    (u64)     |     (u32)    |(bytes)|
+---------+--------+------------+--------------+--------------+-------+
```

字段说明：

1. `version`：日志版本号。

2. `crc`：用于确保数据一致性。计算从 table id 到该记录结束的 CRC 校验值。

3. `table id`：表的唯一标识符。

4. `sequence num`：记录的序列号。

5. `value length`：value 的字节长度。

6. `value`：通用日志格式中的值。

日志中不存储 region ID，因为可以通过文件路径获取该信息。

## 主要流程

### 打开 Wal

1. 识别 Wal 目录下的所有 region 目录。

2. 在每个 region 目录下，识别所有 segment 文件。

3. 打开每个 segment 文件，遍历其中的所有日志，记录其中每个日志开始和结束的偏移量和每个 `TableId` 在该 segment 中的最小和最大序列号，然后关闭文件。

4. 如果不存在 region 目录或目录下没有任何 segment 文件，则自动创建相应的目录和文件。

### 读日志

1. 根据 segment 的元数据，确定本次读取操作涉及的所有 segment。
2. 按照 id 从小到大的顺序，依次打开这些 segment，将原始字节解码为日志。

### 写日志

1. 将待写入的日志序列化为字节数据，追加到 id 最大的 segment 文件中。
2. 每个 segment 创建时预分配固定大小的 64MB，不会动态改变。当预分配的空间用完后，创建一个新的 segment，并切换到新的 segment 继续追加。

3. 每次追加后不会立即调用 flush；默认情况下，每写入十次或在 segment 文件关闭时才执行 flush。

4. 在内存中更新 segment 的元数据 `table_ranges`。

### 删除日志

假设需要将 id 为 `table_id` 的表中，序列号小于 seq_num 的日志标记为删除：

1. 在内存中更新相关 segment 的 `table_ranges` 字段，将该表的最小序列号更新为 seq_num + 1。

2. 如果修改后，该表在此 segment 中的最小序列号大于最大序列号，则从 `table_ranges` 中删除该表。

3. 如果一个 segment 的 `table_ranges` 为空，且不是 id 最大的 segment，则删除该 segment 文件。
