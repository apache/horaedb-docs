**注意：此功能仍在开发中，API 将来可能会发生变化。**

# 分区表

本章讨论 `PartitionTable`。

HoraeDB 使用的分区表语法类似于 [MySQL](https://dev.mysql.com/doc/refman/8.0/en/partitioning-types.html) 。

一般的分区表包括`Range Partitioning`、`List Partitoning`、`Hash Partitioning`和`Key Partititioning`。

HoraeDB 目前仅支持 Key Partitioning。

## 设计

与 MySQL 类似，分区表的不同部分作为单独的表存储在不同的位置。

目前设计，一个分区表可以在多个 HoraeDB 节点上打开，支持同时写入和查询，可以水平扩展。

如下图所示，在 node0 和 node1 上打开了`PartitionTable`，在 node2 和 node3 上打开了存放实际数据的物理子表。

```
                        ┌───────────────────────┐      ┌───────────────────────┐
                        │Node0                  │      │Node1                  │
                        │   ┌────────────────┐  │      │  ┌────────────────┐   │
                        │   │ PartitionTable │  │      │  │ PartitionTable │   │
                        │   └────────────────┘  │      │  └────────────────┘   │
                        │            │          │      │           │           │
                        └────────────┼──────────┘      └───────────┼───────────┘
                                     │                             │
                                     │                             │
             ┌───────────────────────┼─────────────────────────────┼───────────────────────┐
             │                       │                             │                       │
┌────────────┼───────────────────────┼─────────────┐ ┌─────────────┼───────────────────────┼────────────┐
│Node2       │                       │             │ │Node3        │                       │            │
│            ▼                       ▼             │ │             ▼                       ▼            │
│ ┌─────────────────────┐ ┌─────────────────────┐  │ │  ┌─────────────────────┐ ┌─────────────────────┐ │
│ │                     │ │                     │  │ │  │                     │ │                     │ │
│ │     SubTable_0      │ │     SubTable_1      │  │ │  │     SubTable_2      │ │     SubTable_3      │ │
│ │                     │ │                     │  │ │  │                     │ │                     │ │
│ └─────────────────────┘ └─────────────────────┘  │ │  └─────────────────────┘ └─────────────────────┘ │
│                                                  │ │                                                  │
└──────────────────────────────────────────────────┘ └──────────────────────────────────────────────────┘
```

### Key 分区

`Key Partitioning`支持一列或多列计算，使用 HoraeDB 内置的 hash 算法进行计算。

使用限制：

- 仅支持 `tag` 列作为分区键。
- 暂时不支持 `LINEAR KEY`。

key 分区的建表语句如下：

```sql
CREATE TABLE `demo`(
    `name`string TAG,
    `id` int TAG,
    `value` double NOT NULL,
    `t` timestamp NOT NULL,
    TIMESTAMP KEY(t)
    ) PARTITION BY KEY(name) PARTITIONS 2 ENGINE = Analytic
```

参考 [MySQL key partitioning](https://dev.mysql.com/doc/refman/5.7/en/partitioning-key.html)。

## 查询

由于分区表数据实际上是存放在不同的物理表中，所以查询时需要根据查询请求计算出实际请求的物理表。

首先查询会根据查询语句计算出要查询的物理表， 然后通过 HoraeDB 内部服务 [remote engine](https://github.com/apache/incubator-horaedb/blob/89dca646c627de3cee2133e8f3df96d89854c1a3/server/src/grpc/remote_engine_service/mod.rs) 远程请求物理表所在节点获取数据（支持谓词下推）。

分区表的实现在 [PartitionTableImpl](https://github.com/apache/incubator-horaedb/blob/89dca646c627de3cee2133e8f3df96d89854c1a3/analytic_engine/src/table/partition.rs) 中。

- 第一步：解析查询 sql，根据查询参数计算出要查询的物理表。
- 第二步：查询物理表数据。
- 第三步：用拉取的数据进行计算。

```
                       │
                     1 │
                       │
                       ▼
               ┌───────────────┐
               │Node0          │
               │               │
               │               │
               └───────────────┘
                       ┬
                2      │       2
        ┌──────────────┴──────────────┐
        │              ▲              │
        │       3      │       3      │
        ▼ ─────────────┴───────────── ▼
┌───────────────┐             ┌───────────────┐
│Node1          │             │Node2          │
│               │             │               │
│               │             │               │
└───────────────┘             └───────────────┘
```

### Key 分区

- 带有 `and`, `or`, `in`, `=` 的过滤器将选择特定的子表。
- 支持模糊匹配过滤器，如 `<`, `>`，但可能性能较差，因为它会扫描所有物理表。

`Key partitioning` 规则实现在 [KeyRule](https://github.com/apache/incubator-horaedb/blob/89dca646c627de3cee2133e8f3df96d89854c1a3/table_engine/src/partition/rule/key.rs)。

## 写入

写入过程与查询过程类似。

首先根据分区规则，将写入请求拆分到不同的物理表中，然后通过 `remote engine` 服务发送到不同的物理节点进行实际的数据写入。
