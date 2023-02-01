# Wal on Kafka
## Architecture
In this section we present a distributed WAL implementation (based on Kafka). Logs of tables are managed here by region, which can be simply understood as a shared log file of multiple tables. Region can usually be mapped to shard (a set of tables for scheduling of datanodes in CeresDB).
As shown in the following figure, regions are mapped to topic (with only one partition) in Kafka. And usually two regions are needed by a region, one used for storing logs and the other used for storing metadata.
```text
                                                 ┌──────────────────────────┐
                                                 │         Kafka            │
                                                 │                          │
                                                 │         ......           │
                                                 │                          │
                                                 │ ┌─────────────────────┐  │
                                                 │ │      Meta Topic     │  │
                                                 │ │                     │  │
                                         Delete  │ │ ┌─────────────────┐ │  │
               ┌──────────────────────┐  ┌───────┼─┼─►    Partition    │ │  │
               │       CeresDB        │  │       │ │ │                 │ │  │
               │                      │  │       │ │ └─────────────────┘ │  │
               │ ┌──────────────────┐ │  │       │ │                     │  │
               │ │       WAL        │ │  │       │ └─────────────────────┘  │
               │ │      ......      │ │  │       │                          │
               │ │ ┌──────────────┐ │ │  │       │ ┌──────────────────────┐ │
               │ │ │    Region    │ │ │  │       │ │     Data Topic       │ │
               │ │ │              ├─┼─┼──┘       │ │                      │ │
               | | | ┌──────────┐ │ │ │          │ │ ┌──────────────────┐ │ │
               │ │ │ │ Metadata │ │ │ │          │ │ │    Partition     │ │ │
        Write  │ │ │ └──────────┘ │ │ │    Write │ │ │                  │ │ │
Logs ──────────┼─┼─►              ├─┼─┼───┐      │ │ │ ┌──┬──┬──┬──┬──┐ │ │ │
               │ │ │ ┌──────────┐ │ │ │   └──────┼─┼─┼─►  │  │  │  │  ├─┼─┼─┼────┐
        Read   │ │ │ │  Client  │ │ │ │          │ │ │ └──┴──┴──┴──┴──┘ │ │ │    │
Logs ◄─────────┼─┼─┤ └──────────┘ │ │ │          │ │ │                  │ │ │    │
               │ │ │              │ │ │          │ │ └──────────────────┘ │ │    │
               │ │ └──▲───────────┘ │ │          │ │                      │ │    │
               │ │    │ ......      │ │          │ └──────────────────────┘ │    │
               │ └────┼─────────────┘ │          │         ......           │    │
               │      │               │          └──────────────────────────┘    │
               └──────┼───────────────┘                                          │
                      │                                                          │
                      │                                                          │
                      │                        Read                              │
                      └──────────────────────────────────────────────────────────┘
```
## Data model
### Log format
The common log format described in [wal on RocksDB](./wal_on_rocksdb.md) is used here.
### Metadata
Each region will maintain its metadata both in memory and in Kafka, we call it RegionMeta here. It can be thought of as a map, taking TableId as a key and TableMeta as a value.
We briefly introduce the variables in TableMeta ere :
+ `Next_seq_num`, the sequence number allocated to the next log entry.
+ `Latest_marked_deleted`, the last flushed sequence number, all logs in the table with a lower sequence number than it can be removed.
+ `Current_high_watermark`, the high watermark in the Kafka partition after the last writing of this table.
+ `Seq_offset_mapping`, mapping from sequence numbers to offsets is done on every write and is removed after flushing to the erased sequence number.
```
┌─────────────────────────────────────────┐
│              RegionMeta                 │
│                                         │
│ Map<TableId, TableMeta> table_metas     │
└─────────────────┬───────────────────────┘
                  │
                  │
                  │
                  └─────┐
                        │
                        │
 ┌──────────────────────┴──────────────────────────────┐
 │                       TableMeta                     │
 │                                                     │
 │ SequenceNumber next_seq_num                         │
 │                                                     │
 │ SequenceNumber latest_mark_deleted                  │
 │                                                     │
 │ KafkaOffset high_watermark                          │
 │                                                     │
 │ Map<SequenceNumber, KafkaOffset> seq_offset_mapping │
 └─────────────────────────────────────────────────────┘
```
## Main process
We focus on the main process in one region, following process will be introduced:
+ Write to and read from region.
+ Open or create region.
+ Delete logs.
### Write to and read from region
The writing and reading process is simple. 
For writing:
+ Open the specified region (auto create it if necessary).
+ Put the logs to specified Kafka partition by client.
+ Update next_seq_num,  current_high_watermark and sequence_offset_mapping in corresponding TableMeta. 
For reading:
+ Open the specified region.
+ Just read all the logs of the region, and the split and replay work will be done by the caller.
### Open or create region
#### Steps
  + Search the region in the opened namespace.
  + If the region found, the most important thing we need to do is to recover its metadata, we will introduce this later.
  + If the region not found and auto creating is defined, just create the corresponding topic in Kafka.
  + Add the found or created region to cache, return it afterwards.
#### Recovery
As mentioned above, the RegionMeta is actually a map of the TableMeta. So here we will focus on recovering a specific TableMeta, and examples will be given to better illustrate this process.
+ First, restore the RegionMeta snapshot. We will take a snapshot of the RegionMeta in some scenarios (e.g. mark logs deleted, clean logs) and put it in the meta topic. The snapshot is actually the RegionMeta at a particular point in time. When recovering a region, we can use it to avoid scanning all logs in the data topic. The following is the example, we recover from the snapshot taken at the time when Kafka high watermark is 64:
```text
high watermark in snapshot: 64

 ┌──────────────────────────────┐
 │         RegionMeta           │
 │                              │
 │          ......              │
 │ ┌──────────────────────────┐ │
 │ │       TableMeta          │ │
 │ │                          │ │
 │ │ next_seq_num: 5          │ │
 │ │                          │ │
 │ │ latest_mark_deleted: 2   │ │
 │ │                          │ │
 │ │ high_watermark: 32       │ │
 │ │                          │ │
 │ │ seq_offset_mapping:      │ │
 │ │                          │ │
 │ │ (2, 16) (3, 16) (4, 31)  │ │
 │ └──────────────────────────┘ │
 │          ......              │
 └──────────────────────────────┘
```
+ Recovering from logs. After recovering from snapshot, we can continue to recover by scanning logs in data topicfrom the Kafka high watermark when it is taken, and obviously that avoid scanning the whole data topic. Let's see the example:
```text
┌────────────────────────────────────┐
│                                    │                 
│    high_watermark in snapshot: 64  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │         RegionMeta           │  │
│  │                              │  │
│  │          ......              │  │
│  │ ┌──────────────────────────┐ │  │
│  │ │       TableMeta          │ │  │
│  │ │                          │ │  │
│  │ │ next_seq_num: 5          │ │  │                  ┌────────────────────────────────┐
│  │ │                          │ │  │                  │          RegionMeta            │
│  │ │ latest_mark_deleted: 2   │ │  │                  │                                │
│  │ │                          │ │  │                  │            ......              │
│  │ │ high_watermark: 32       │ │  │                  │ ┌────────────────────────────┐ │
│  │ │                          │ │  │                  │ │         TableMeta          │ │
│  │ │ seq_offset_mapping:      │ │  │                  │ │                            │ │
│  │ │                          │ │  │                  │ │ next_seq_num: 8            │ │
│  │ │ (2, 16) (3, 16) (4, 31)  │ │  │                  │ │                            │ │
│  │ └──────────────────────────┘ │  │                  │ │ latest_mark_deleted: 2     │ │
│  │          ......              │  │                  │ │                            │ │
│  └──────────────────────────────┘  ├──────────────────► │ high_watermark: 32         │ │
│                                    │                  │ │                            │ │
│ ┌────────────────────────────────┐ │                  │ │ seq_offset_mapping:        │ │
│ │          Data topic            │ │                  │ │                            │ │
│ │                                │ │                  │ │ (2, 16) (3, 16) (4, 31)    │ │
│ │ ┌────────────────────────────┐ │ │                  │ │                            │ │
│ │ │        Partition           │ │ │                  │ │ (5, 72) (6, 81) (7, 90)    │ │
│ │ │                            │ │ │                  │ │                            │ │
│ │ │ ┌────┬────┬────┬────┬────┐ │ │ │                  │ └────────────────────────────┘ │
│ │ │ │ 64 │ 65 │ ...│ 99 │100 │ │ │ │                  │             ......             │
│ │ │ └────┴────┴────┴────┴────┘ │ │ │                  └────────────────────────────────┘
│ │ │                            │ │ │
│ │ └────────────────────────────┘ │ │
│ │                                │ │
│ └────────────────────────────────┘ │
│                                    │
└────────────────────────────────────┘
```
### Delete logs
Log's deletion can be split to two steps:
+ Mark the deleted offset.
+ Do delayed cleaning work periodically in a background thread.
#### Mark
+ Update latest_mark_deleted and sequence_offset_mapping(just retain the entries whose's sequences >= updated latest_mark_deleted) in TableMeta.
+ Maybe we need to make and sync the RegionMeta snapshot to Kafka while dropping table.
#### Clean
The cleaning logic done in a background thread called cleaner:
+ Make RegionMeta snapshot.
+ Decide whether to clean the logs based on the snapshot.
+ If so, sync the snapshot to Kafka first, then clean the logs.
