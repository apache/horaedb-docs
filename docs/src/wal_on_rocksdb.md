# Wal on RocksDB
## 架构
在本节中，我们将介绍单机版 WAL 的实现（基于 RocksDB）。日志在这里是按表级别来管理的，对应的存储数据结构为 `TableUnit`。为简单起见，所有相关数据（日志或一些元数据）都存储在单个 column family中。
```text
            ┌─────────────────────────┐
            │         CeresDB         │
            │                         │
            │ ┌─────────────────────┐ │
            │ │         WAL         │ │
            │ │                     │ │
            │ │        ......       │ │
            │ │                     │ │
            │ │  ┌────────────────┐ │ │
 Write ─────┼─┼──►   TableUnit    │ │ │
            │ │  │                │ │ │
 Read  ─────┼─┼──► ┌────────────┐ │ │ │
            │ │  │ │ RocksDBRef │ │ │ │
            │ │  │ └────────────┘ │ │ │
Delete ─────┼─┼──►                │ │ │
            │ │  └────────────────┘ │ │
            │ │        ......       │ │
            │ └─────────────────────┘ │
            │                         │
            └─────────────────────────┘
```
## 数据模型
### 通用日志格式
通用日志格式分为 key 格式和 value 格式，下面是对 key 格式各个字段的介绍:
+ `Namespace`: 出于不同的目的，可能会存在多个 WAL 实例（例如，manifest 也依赖于 wal）, `namespace` 用于区分它们。
+ `Region_id`: 在一些WAL实现中我们可能需要管理来自多个表的日志，`region` 就是描述这样一组表日志的概念, 而 `region id` 就是其标识。
+ `Table_id`: 表的标识。 
+ `Sequence_num`: 特定表中单条日志的标识。 
+ `Version`: 用于兼容新旧格式。 

```text
+---------------+----------------+-------------------+--------------------+--------------------+
| namespace(u8) | region_id(u64) |   table_id(u64)   |  sequence_num(u64) | version header(u8) |
+---------------+----------------+-------------------+--------------------+--------------------+
```
下面是对 value 格式各个字段的介绍(`payload` 可以理解为编码后的具体日志内容):

```text
+--------------------+----------+
| version header(u8) | payload  |
+--------------------+----------+
```
### Metadata
The metadata here is stored in the same key-value format as the log. Actually only the last flushed sequence is stored in this implementation.
Here is the defined metadata key format and field instructions:
+ `Namespace`, `table_id`, `version` are the same as the log format.
+ `Key_type`, used to define the type of metadata. MaxSeq now defines that metadata of this type will only record the most recently flushed sequence in the table.    
Because it is only used in wal on RocksDB, which manages the logs at table level, so there is no region id in this key.
```text
+---------------+--------------+----------------+-------------+
| namespace(u8) | key_type(u8) | table_id(u64)  | version(u8) |
+---------------+--------------+----------------+-------------+
```
Here is the defined metadata value format, as you can see, just the version and max_seq(flushed sequence) in it:
```text
+-------------+--------------+
| version(u8) | max_seq(u64) |
+-------------+--------------+
```
## Main process
+ Open region: 
  + Read the latest log entry of all tables to recover the next sequence numbers of tables mainly.
  + Scan the metadata to recover next sequence num as a supplement (because some table has just triggered flush and no new written logs after this, so no logs exists now).
+ Write to and read from region. Just write and read key-value from RocksDB.
+ Delete logs. For simplicity It will remove corresponding logs synchronously.
