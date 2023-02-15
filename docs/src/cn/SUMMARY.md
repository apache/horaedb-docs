# 目录

# 简介

- [什么是 CeresDB](about.md)
- [快速开始](quick_start.md)

# 用户手册

- [SQL 语法](sql/README.md)

  - [数据模型](sql/model/README.md)
    - [数据类型](sql/model/data_types.md)
    - [特殊字段](sql/model/special_columns.md)
  - [标识符](sql/identifier.md)
  - [表结构操作](sql/ddl/README.md)
    - [建表](sql/ddl/create_table.md)
    - [表结构变更](sql/ddl/alter_table.md)
    - [删除表](sql/ddl/drop_table.md)
  - [数据操作](sql/dml/README.md)
    - [数据写入](sql/dml/insert.md)
    - [数据查询](sql/dml/select.md)
  - [引擎配置](sql/engine_options.md)
  - [常见 SQL](sql/utility.md)
  - [标量函数](sql/functions/scalar_functions.md)
  - [聚合函数](sql/functions/aggregate_functions.md)

- [部署文档](deploy/README.md)

  - [支持平台](deploy/platform.md)
  - [静态路由](deploy/static_routing.md)
  - [动态路由](deploy/dynamic_routing.md)

- [SDK 文档](sdk/README.md)
  - [Java SDK](sdk/java.md)
  - [Go SDK](sdk/go.md)
  - [Python SDK](sdk/python.md)
  - [Rust SDK](sdk/rust.md)
- [运维文档](operation/README.md)
  - [表](operation/table.md)
  - [系统表](operation/system_table.md)
  - [黑名单](operation/block_list.md)
  - [监控](operation/observability.md)
  - [集群运维](operation/cluster.md)
- [周边生态](ecosystem/README.md)
  - [Prometheus](ecosystem/prometheus.md)

# 开发者手册

- [支持平台](dev/platform.md)
- [编译运行](dev/compile_run.md)
- [开发规约](dev/conventional_commit.md)
- [风格规范](dev/style_guide.md)
- [里程碑](dev/roadmap.md)

# 技术系列文章

- [整体架构](design/architecture.md)
- [集群](design/clustering.md)
- [存储介绍](design/storage.md)
- [WAL 介绍](design/wal.md)
  - [WAL on RocksDB](design/wal_on_rocksdb.md)
  - [WAL on Kafka](design/wal_on_kafka.md)
- [分区表](design/table_partitioning.md)

[//]: # "- [查询介绍](query.md)"
