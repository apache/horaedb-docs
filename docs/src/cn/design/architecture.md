# CeresDB 架构介绍

## 本文目标

- 为想了解更多关于 CeresDB 但不知道从何入手的开发者提供 CeresDB 的概览
- 简要介绍 CeresDB 的主要模块以及这些模块之间的联系，但不涉及它们实现的细节

## 动机

CeresDB 是一个时序数据库，与经典时序数据库相比，CeresDB 的目标是能够同时处理时序型和分析型两种模式的数据，并提供高效的读写。

在经典的时序数据库中，`Tag` 列（ `InfluxDB` 称之为 `Tag`，`Prometheus` 称之为 `Label`）通常会对其生成倒排索引，但在实际使用中，`Tag` 的基数在不同的场景中是不一样的 ———— 在某些场景下，`Tag` 的基数非常高（这种场景下的数据，我们称之为分析型数据），而基于倒排索引的读写要为此付出很高的代价。而另一方面，分析型数据库常用的扫描 + 剪枝方法，可以比较高效地处理这样的分析型数据。

因此 CeresDB 的基本设计理念是采用混合存储格式和相应的查询方法，从而达到能够同时高效处理时序型数据和分析型数据。

## 架构

```plaintext
┌──────────────────────────────────────────┐
│       RPC Layer (HTTP/gRPC/MySQL)        │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│                 SQL Layer                │
│ ┌─────────────────┐  ┌─────────────────┐ │
│ │     Parser      │  │     Planner     │ │
│ └─────────────────┘  └─────────────────┘ │
└──────────────────────────────────────────┘
┌───────────────────┐  ┌───────────────────┐
│    Interpreter    │  │      Catalog      │
└───────────────────┘  └───────────────────┘
┌──────────────────────────────────────────┐
│               Query Engine               │
│ ┌─────────────────┐  ┌─────────────────┐ │
│ │    Optimizer    │  │    Executor     │ │
│ └─────────────────┘  └─────────────────┘ │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│         Pluggable Table Engine           │
│  ┌────────────────────────────────────┐  │
│  │              Analytic              │  │
│  │┌────────────────┐┌────────────────┐│  │
│  ││      Wal       ││    Memtable    ││  │
│  │└────────────────┘└────────────────┘│  │
│  │┌────────────────┐┌────────────────┐│  │
│  ││     Flush      ││   Compaction   ││  │
│  │└────────────────┘└────────────────┘│  │
│  │┌────────────────┐┌────────────────┐│  │
│  ││    Manifest    ││  Object Store  ││  │
│  │└────────────────┘└────────────────┘│  │
│  └────────────────────────────────────┘  │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│           Another Table Engine        │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
└──────────────────────────────────────────┘
```

上图展示了 CeresDB 单机版本的架构，下面将会介绍重要模块的细节。

### RPC 层

模块路径：https://github.com/CeresDB/ceresdb/tree/main/server

当前的 RPC 支持多种协议，包括 HTTP、gRPC、MySQL。

通常 HTTP 和 MySQL 用于调试 CeresDB，手动查询和执行 DDL 操作（如创建、删除表等）。而 gRPC 协议可以被看作是一种用于高性能的定制协议，更适用于大量的读写操作。

### SQL 层

模块路径：https://github.com/CeresDB/ceresdb/tree/main/query_frontend

SQL 层负责解析 SQL 并生成查询计划。

CeresDB 基于 [sqlparser](https://github.com/sqlparser-rs/sqlparser-rs) 提供了一种 SQL 方言，为了更好的适配时序数据，引入一些概念，包括 Tag 和 Timestamp。此外，利用 [DataFusion](https://github.com/apache/arrow-datafusion)，CeresDB 不仅可以生成常规的逻辑计划，还可以生成自定义的计划来实现时序场景要求的特殊算子，例如为了适配 PromQL 协议而做的工作就是利用了这个特性。

### Interpreter

模块路径：https://github.com/CeresDB/ceresdb/tree/main/interpreters

`Interpreter` 模块封装了 SQL 的 `CRUD` 操作。在查询流程中，一个 SQL 语句会经过解析，生成出对应的查询计划，然后便会在特定的解释器中执行，例如 `SelectInterpreter`、`InsertInterpreter` 等。

### Catalog

模块路径：https://github.com/CeresDB/ceresdb/tree/main/catalog_impls

`Catalog` 实际上是管理元数据的模块，CeresDB 采用的元数据分级与 PostgreSQL 类似：`Catalog > Schema > Table`，但目前它们只用作命名空间。

目前，`Catalog` 和 `Schema` 在单机模式和分布式模式存在两种不同实现，因为一些生成 id 和持久化元数据的策略在这两种模式下有所不同。

### 查询引擎

模块路径：https://github.com/CeresDB/ceresdb/tree/main/query_engine

查询引擎负责优化和执行由 SQL 层解析出来的 SQL 计划，目前查询引擎实际上基于 [DataFusion](https://github.com/apache/arrow-datafusion) 来实现的。

除了 SQL 的基本功能外，CeresDB 还通过利用 [DataFusion](https://github.com/apache/arrow-datafusion) 提供的扩展接口，为某些特定的查询（比如 `PromQL`）构建了一些定制的查询协议和优化规则。

### Pluggable Table Engine

模块路径：https://github.com/CeresDB/ceresdb/tree/main/table_engine

`Table Engine` 是 CeresDB 中用于管理表的存储引擎，其可插拔性是 CeresDB 的一个核心设计，对于实现我们的一些长远目标（比如增加 Log 或 Tracing 类型数据的存储引擎）至关重要。CeresDB 将会有多种 `Table Engine` 用于不同的工作负载，根据工作负载模式，应该选择最合适的存储引擎。

现在对 Table Engine 的要求是：

- 管理引擎下的所有共享资源：
  - 内存
  - 存储
  - CPU
- 管理表的元数据，如表的结构、表的参数选项；
- 能够提供 `Table` 实例，该实例可以提供 `read` 和 `write` 的能力；
- 负责 `Table` 实例的创建、打开、删除和关闭；
- ....

实际上，`Table Engine` 需要处理的事情有点复杂。现在在 CeresDB 中，只提供了一个名为 `Analytic` 的 `Table Engine`，它在处理分析工作负载方面做得很好，但是在时序工作负载上还有很大的进步空间（我们计划通过添加一些帮助处理时序工作负载的索引来提高性能）。

以下部分描述了 `Analytic Table Engine` 的详细信息。

#### WAL

模块路径：https://github.com/CeresDB/ceresdb/tree/main/wal

CeresDB 处理数据的模型是 `WAL` + `MemTable`，最近写入的数据首先被写入 `WAL`，然后写入 `MemTable`，在 `MemTable` 中累积了一定数量的数据后，该数据将以便于查询的形式被重新构建，并存储到持久化设备上。

目前，为 `standalone` 模式和分布式模式提供了三种 `WAL` 实现：

- 对于 `standalone` 模式，`WAL` 基于 `RocksDB`，数据存储在本地磁盘上。
- 对于分布式模式，需要 `WAL` 作为一个分布式组件，负责新写入数据的可靠性，因此，我们现在提供了基于 [`OceanBase`](https://github.com/oceanbase/oceanbase) 的实现。
- 对于分布式模式，除了 [`OceanBase`](https://github.com/oceanbase/oceanbase)，我们还提供了一个更轻量级的基于 [`Apache Kafka`](https://github.com/apache/kafka) 实现。

#### MemTable

模块路径：https://github.com/CeresDB/ceresdb/tree/main/analytic_engine/src/memtable

由于 `WAL` 无法提供高效的查询，因此新写入的数据会存储一份到 `Memtable` 用于查询，并且在积累了一定数量后，CeresDB 将 `MemTable` 中的数据组织成便于查询的存储格式（`SST`）并存储到持久化设备中。

MemTable 的当前实现基于 [agatedb 的 skiplist](https://github.com/tikv/agatedb/blob/8510bff2bfde5b766c3f83cf81c00141967d48a4/skiplist)。它允许并发读取和写入，并且可以根据 [Arena](https://github.com/CeresDB/ceresdb/tree/main/components/skiplist) 控制内存使用。

#### Flush

模块路径：https://github.com/CeresDB/ceresdb/blob/main/analytic_engine/src/instance/flush_compaction.rs

当 `MemTable` 的内存使用量达到阈值时，`Flush` 操作会选择一些老的 `MemTable`，将其中的数据组织成便于查询的 `SST` 存储到持久化设备上。

在刷新过程中，数据将按照一定的时间段（由表选项 `Segment Duration` 配置）进行划分，保证任何一个 `SST` 的所有数据的时间戳都属于同一个 `Segment`。实际上，这也是大多数时序数据库中常见的操作，按照时间维度组织数据，以加速后续的时间相关操作，如查询一段时间内的数据，清除超出 `TTL` 的数据等。

#### Compaction

模块路径：https://github.com/CeresDB/ceresdb/tree/main/analytic_engine/src/compaction

`MemTable` 的数据被刷新为 `SST` 文件，但最近刷新的 `SST` 文件可能非常小，而过小或过多的 `SST` 文件会导致查询性能不佳，因此，引入 `Compaction` 来重新整理 SST 文件，使多个较小的 `SST` 文件可以合并成较大的 `SST` 文件。

#### Manifest

模块路径：https://github.com/CeresDB/ceresdb/tree/main/analytic_engine/src/meta

`Manifest` 负责管理每个表的元数据，包括：

- 表的结构和表的参数选项；
- 最新 `Flush` 过的 sequence number；
- 表的所有 `SST` 文件的信息。

现在 `Manifest` 是基于 `WAL` 和 `Object Store` 来实现的，新的改动会直接写入到 `WAL`，而为了避免元数据无限增长（实际上每次 `Flush` 操作都会触发更新），会对其写入的记录做快照，生成的快照会被持久化道 `Object Store`。

#### Object Storage

模块路径：https://github.com/CeresDB/ceresdb/tree/main/components/object_store

`Flush` 操作产生的 `SST` 文件需要持久化存储，而用于抽象持久化存储设备的就是 `Object Storage`，其中包括多种实现：

- 基于本地文件系统；
- 基于[阿里云 OSS](https://www.alibabacloud.com/product/object-storage-service)。

CeresDB 的分布式架构的一个核心特性就是存储和计算分离，因此要求 `Object Storage` 是一个高可用的服务，并独立于 CeresDB。因此，像[Amazon S3](https://aws.amazon.com/s3/)、[阿里云 OSS](https://www.alibabacloud.com/product/object-storage-service)等存储系统是不错的选择，未来还将计划实现在其他云服务提供商的存储系统上。

#### SST

模块路径：https://github.com/CeresDB/ceresdb/tree/main/analytic_engine/src/sst

`SST` 本身实际上是一种抽象，可以有多种具体实现。目前的实现是基于 [Parquet](https://parquet.apache.org/)，它是一种面向列的数据文件格式，旨在实现高效的数据存储和检索。

`SST` 的格式对于数据检索非常关键，也是决定查询性能的关键所在。目前，我们基于 [Parquet](https://parquet.apache.org/) 的 `SST` 实现在处理分析型数据时表现良好，但目前在处理时序型数据上还有较高的提升空间。在我们的路线图中，我们将探索更多的存储格式，以便在两种类型的数据处理上都取得良好的性能。

#### Space

模块路径：https://github.com/CeresDB/ceresdb/blob/main/analytic_engine/src/space.rs

在 `Analytic Engine` 中，有一个叫做 `space` 的概念，这里着重解释一下，以解决阅读源代码时出现的一些歧义。
实际上，`Analytic Engine` 没有 `catalog` 和 `schema` 的概念，只提供两个层级的关系：`space` 和 `table`。在实现中，上层的 `schema id`（要求在所有的 `catalogs` 中都应该是唯一的）实际上会直接映射成 `space id`。

`Analytic Engine` 中的 `space` 主要用于隔离不同租户的资源，如内存的使用。

## Critical Path

简要介绍了 CeresDB 的一些重要模块后，我们将对代码中的一些关键路径进行描述，希望为有兴趣的开发人员在阅读代码时提供一些帮助。

### Query

```plaintext
┌───────┐      ┌───────┐      ┌───────┐
│       │──1──▶│       │──2──▶│       │
│Server │      │  SQL  │      │Catalog│
│       │◀─10──│       │◀─3───│       │
└───────┘      └───────┘      └───────┘
                │    ▲
               4│   9│
                │    │
                ▼    │
┌─────────────────────────────────────┐
│                                     │
│             Interpreter             │
│                                     │
└─────────────────────────────────────┘
                           │    ▲
                          5│   8│
                           │    │
                           ▼    │
                   ┌──────────────────┐
                   │                  │
                   │   Query Engine   │
                   │                  │
                   └──────────────────┘
                           │    ▲
                          6│   7│
                           │    │
                           ▼    │
 ┌─────────────────────────────────────┐
 │                                     │
 │            Table Engine             │
 │                                     │
 └─────────────────────────────────────┘
```

以 `SELECT` SQL 为例，上图展示了查询过程，其中的数字表示模块之间调用的顺序。

以下是详细流程：

- Server 模块根据请求使用的协议选择合适的 rpc 模块（可能是 HTTP、gRPC 或 mysql）来处理请求；
- 使用 parser 解析请求中的 sql ；
- 根据解析好的 sql 以及 catalog/schema 提供的元信息，通过 [DataFusion](https://github.com/apache/arrow-datafusion) 可以生成逻辑计划；
- 根据逻辑计划创建相应的 `Interpreter`，并由其执行逻辑计划；
- 对于正常 `SELECT` SQL 的逻辑计划，它将通过 `SelectInterpreter` 执行；
- 在 `SelectInterpreter` 中，特定的查询逻辑由 `Query Engine` 执行：
  - 优化逻辑计划；
  - 生成物理计划；
  - 优化物理计划；
  - 执行物理计划；
- 执行物理计划涉及到 `Analytic Engine`：
  - 通过 `Analytic Engine` 提供的 `Table` 实例的 `read` 方法获取数据；
  - 表数据的来源是 `SST` 和 `Memtable`，可以通过谓词下推进行提前过滤；
  - 在检索到表数据后，`Query Engine` 将完成具体计算并生成最终结果；
- `SelectInterpreter` 获取结果并将其传输给 Protocol 模块；
- 协议模块完成转换结果后，Server 模块将其响应给客户端。

以下是[v1.2.2](https://github.com/CeresDB/ceresdb/releases/tag/v1.2.2)的函数调用流程。

```
                                                       ┌───────────────────────◀─────────────┐    ┌───────────────────────┐
                                                       │      handle_sql       │────────┐    │    │       parse_sql       │
                                                       └───────────────────────┘        │    │    └────────────────┬──────┘
                                                           │             ▲              │    │           ▲         │
                                                           │             │              │    │           │         │
                                                           │             │              │    └36───┐     │        11
                                                          1│             │              │          │     │         │
                                                           │            8│              │          │     │         │
                                                           │             │              │          │    10         │
                                                           │             │              │          │     │         │
                                                           ▼             │              │          │     │         ▼
                                                       ┌─────────────────┴─────┐       9│         ┌┴─────┴────────────────┐───────12─────────▶┌───────────────────────┐
                                                       │maybe_forward_sql_query│        └────────▶│fetch_sql_query_output │                   │   statement_to_plan   │
                                                       └───┬───────────────────┘                  └────┬──────────────────┘◀───────19─────────└───────────────────────┘
                                                           │             ▲                             │              ▲                           │               ▲
                                                           │             │                             │              │                           │               │
                                                           │             │                             │              │                           │               │
                                                           │             │                             │             35                          13              18
                                                          2│            7│                            20              │                           │               │
                                                           │             │                             │              │                           │               │
                                                           │             │                             │              │                           │               │
                                                           │             │                             │              │                           ▼               │
                                                           ▼             │                             ▼              │                       ┌───────────────────────┐
          ┌───────────────────────┐───────────6───────▶┌─────────────────┴─────┐                    ┌─────────────────┴─────┐                 │Planner::statement_to_p│
          │ forward_with_endpoint │                    │        forward        │                    │execute_plan_involving_│                 │          lan          │
          └───────────────────────┘◀────────5──────────└───┬───────────────────┘                 ┌──│    partition_table    │◀────────┐       └───┬───────────────────┘
                                                           │             ▲                       │  └───────────────────────┘         │           │              ▲
                                                           │             │                       │     │              ▲               │           │              │
                                                           │             │                       │     │              │               │          14             17
           ┌───────────────────────┐                       │            4│                       │     │              │               │           │              │
     ┌─────│ PhysicalPlan::execute │                      3│             │                       │    21              │               │           │              │
     │     └───────────────────────┘◀──┐                   │             │                       │     │             22               │           │              │
     │                                 │                   │             │                       │     │              │               │           ▼              │
     │                                 │                   │             │                       │     │              │               │       ┌────────────────────────┐
     │                                 │                   ▼             │                       │     ▼              │              34       │sql_statement_to_datafus│
     │     ┌───────────────────────┐  30               ┌─────────────────┴─────┐                 │  ┌─────────────────┴─────┐         │       │        ion_plan        │
    31     │ build_df_session_ctx  │   │               │         route         │                 │  │   build_interpreter   │         │       └────────────────────────┘
     │     └────┬──────────────────┘   │               └───────────────────────┘                 │  └───────────────────────┘         │           │              ▲
     │          │           ▲          │                                                         │                                    │           │              │
     │         27          26          │                                                        23                                    │          15             16
     │          ▼           │          │                                                         │                                    │           │              │
     └────▶┌────────────────┴──────┐   │               ┌───────────────────────┐                 │                                    │           │              │
           │ execute_logical_plan  ├───┴────32────────▶│       execute         │──────────┐      │   ┌───────────────────────┐        │           ▼              │
           └────┬──────────────────┘◀────────────25────┴───────────────────────┘         33      │   │interpreter_execute_pla│        │       ┌────────────────────────┐
                │           ▲                                           ▲                 └──────┴──▶│           n           │────────┘       │SqlToRel::sql_statement_│
               28           │                                           └──────────24────────────────┴───────────────────────┘                │   to_datafusion_plan   │
                │          29                                                                                                                 └────────────────────────┘
                ▼           │
           ┌────────────────┴──────┐
           │     optimize_plan     │
           └───────────────────────┘
```
```
1. 收到请求经过各种协议转换会转到`handle_sql`中执行,由于该请求可能是非本节点处理的，可能需要转发，进入`maybe_forward_sql_query`处理转发逻辑。
2. 在`maybe_forward_sql_query`中构造好`ForwardRequest`后，调用`forward`
3. 在`forward`中构造好`RouteRequest`,后调用`route`
4. 使用`route`获取目的节点`endpoint`后回到`forward`
5. 调用`forward_with_endpoint`将请求进行转发
6. 回到 `forward `
7. 回到`maybe_forward_sql_query`
8. 回到`handle_sql`
9. 此时若是`Local`请求，调用`fetch_sql_query_output`进行处理
10. 调用`parse_sql`将`sql`解析成`Statment`
11. 回到`fetch_sql_query_output`
12. 使用`Statment`调用`statement_to_plan`
13. 在其中使用`ctx`和`Statment`构造`Planner`,调用`planner`的`statement_to_plan`方法
14. `planner`中会对于请求的类别调用对应的`planner`方法，此时我们的`sql`是查询，会调用`sql_statement_to_plan`
15. 调用`sql_statement_to_datafusion_plan`,其中会生成`datafusion`的对象，然后调用`SqlToRel::sql_statement_to_plan`
16. `SqlToRel::sql_statement_to_plan`中会返回生成的逻辑计划
17. 返回
18. 返回
19. 返回
20. 调用`execute_plan_involving_partition_table`（默认配置）进行该逻辑计划的后续优化和执行
21. 调用`build_interpreter` 生成`Interpreter`
22. 返回
23. 使用刚刚生成的`Interpreter`调用`interpreter_execute_plan`进行逻辑计划的执行
24. 调用对应执行函数，此时`sql`是查询，所以会调用`SelectInterpreter`的`execute`
25. 调用`execute_logical_plan`，其中会调用`build_df_session_ctx`生成优化器
26. `build_df_session_ctx`中会使用`config`信息生成对应上下文,首先生成逻辑计划优化器，使用`datafusion`和自定义的一些优化规则生成(在`logical_optimize_rules()`中)生成逻辑计划优化器,使用`apply_adapters_for_physical_optimize_rules`生成物理计划优化器
27. 将优化器返回
28. 调用`optimize_plan`使用刚刚生成的优化器首先进行逻辑计划的优化随后进行物理计划的计划
29. 返回优化后物理计划
30. 执行物理计划
31. 执行后返回
32. 收集所以分片的结果后，返回
33. 返回
34. 返回
35. 返回
36. 返回，随后进行网络协议转化后返回给请求发送方
```

### Write

```plaintext
┌───────┐      ┌───────┐      ┌───────┐
│       │──1──▶│       │──2──▶│       │
│Server │      │  SQL  │      │Catalog│
│       │◀─8───│       │◀─3───│       │
└───────┘      └───────┘      └───────┘
                │    ▲
               4│   7│
                │    │
                ▼    │
┌─────────────────────────────────────┐
│                                     │
│             Interpreter             │
│                                     │
└─────────────────────────────────────┘
      │    ▲
      │    │
      │    │
      │    │
      │    │       ┌──────────────────┐
      │    │       │                  │
     5│   6│       │   Query Engine   │
      │    │       │                  │
      │    │       └──────────────────┘
      │    │
      │    │
      │    │
      ▼    │
 ┌─────────────────────────────────────┐
 │                                     │
 │            Table Engine             │
 │                                     │
 └─────────────────────────────────────┘
```

以 `INSERT` SQL 为例，上图展示了查询过程，其中的数字表示模块之间调用的顺序。

以下是详细流程：

- Server 模块根据请求使用的协议选择合适的 rpc 模块（可能是 HTTP、gRPC 或 mysql）来处理请求；
- 使用 parser 解析请求中的 sql；
- 根据解析好的 sql 以及 catalog/schema 提供的元信息，通过 [DataFusion](https://github.com/apache/arrow-datafusion) 可以生成逻辑计划；
- 根据逻辑计划创建相应的 `Interpreter` ，并由其执行逻辑计划；
- 对于正常 `INSERT` SQL 的逻辑计划，它将通过 `InsertInterpreter` 执行；
- 在 `InsertInterpreter` 中，调用 `Analytic Engine` 提供的 `Table` 的 `write` 方法：
  - 首先将数据写入 `WAL`；
  - 然后写入 `MemTable`；
- 在写入 `MemTable` 之前，会检查内存使用情况。如果内存使用量过高，则会触发 `Flush`：
  - 将一些旧的 `MemTable` 持久化为 `SST`；
  - 将新的 SST 信息记录到 `Manifest`；
  - 记录最新 Flush 的 `WAL` 序列号；
  - 删除相应的 `WAL` 日志；
- Server 模块将执行结果响应给客户端。
