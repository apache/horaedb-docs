# 基于 RocksDB 的 WAL

## 架构

在本节中，我们将介绍单机版 WAL 的实现（基于 RocksDB）。预写日志（write-ahead logs，以下简称日志）在本实现中是按表级别进行管理的，对应的数据结构为 `TableUnit`。为简单起见，所有相关数据（日志或元数据）都存储在单个 column family（RocksDB 中的概念，可以类比关系型数据库的表） 中。

```text
            ┌─────────────────────────┐
            │         HoraeDB         │
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

- `namespace`: 出于不同的目的，可能会存在多个 WAL 实例（例如，manifest 也依赖于 wal）, `namespace` 用于区分它们。
- `region_id`: 在一些 WAL 实现中我们可能需要在共享日志文件中，管理来自多个表的日志，`region` 就是描述这样一组表的概念， 而 `region id` 就是其标识。
- `table_id`: 表的标识。
- `sequence_num`: 特定表中单条日志的标识。
- `version`: 用于兼容新旧格式。

```text
+---------------+----------------+-------------------+--------------------+-------------+
| namespace(u8) | region_id(u64) |   table_id(u64)   |  sequence_num(u64) | version(u8) |
+---------------+----------------+-------------------+--------------------+-------------+
```

下面是对 value 格式各个字段的介绍(`payload` 可以理解为编码后的具体日志内容):

```text
+--------------------+----------+
| version header(u8) | payload  |
+--------------------+----------+
```

### 元数据

与日志格式相同，元数据以 key-value 格式存储, 本实现的元数据实际只是存储了每张表最近一次 flush 对应的 `sequence_num`。下面是定义的元数据 key 格式和其中字段的介绍：

- `namespace`, `table_id`, `version` 和日志格式中相同。
- `key_type`, 用于定义元数据的类型，现在只定义了 MaxSeq 类型的元数据，在。
  因为在 RocksDB 版本的 WAL 实现中，日志是按表级别进行管理，所以这个 key 格式里面没有 `region_id` 字段。

```text
+---------------+--------------+----------------+-------------+
| namespace(u8) | key_type(u8) | table_id(u64)  | version(u8) |
+---------------+--------------+----------------+-------------+
```

这是定义的元数据值格式，如下所示，其中只有 `version` 和 `max_seq`(flushed sequence):

```text
+-------------+--------------+
| version(u8) | max_seq(u64) |
+-------------+--------------+
```

## 主要流程

- 打开 `TableUnit`:
  - 读取所有表的最新日志条目，目的是恢复表的 next sequence num(将会分配给下一条写入的日志)。
  - 扫描 metadata 恢复上一步遗漏的表的 next sequence num（因为可能有表刚刚触发了 fl​​ush，并且之后没有新的写入日志，所以当前不存在日志数据）。
- 读写日志。从 RocksDB 读取或者写入相关日志数据。
- 删除日志。为简单起见，在本实现中只是同步地删除相应的日志数据。