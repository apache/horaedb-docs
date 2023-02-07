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
  - [引擎参数](sql/engine_options.md)
  - [常见 SQL](sql/utility.md)

- [部署文档](deploy/README.md)

  - [支持平台](deploy/platform.md)
  - [静态路由](deploy/static_routing.md)
  - [动态路由](deploy/dynamic_routing.md)

- [SDK 文档](sdk.md)
  - [Java SDK](sdk/java.md)
  - [Go SDK](sdk/go.md)
  - [Python SDK](sdk/python.md)
  - [Rust SDK](sdk/rust.md)
- [运维文档](operation/README.md)
  - [Table](operation/table.md)
  - [System Table](operation/system_table.md)
  - [黑名单](operation/block_list.md)
  - [监控](operation/observability.md)
- [周边生态](ecosystem/README.md)
  - [Prometheus](ecosystem/prometheus.md)

# 开发者手册

- [支持平台](dev/platform.md)
- [编译运行](dev/compile_run.md)
- [开发规约](dev/conventional_commit.md)
- [风格规范](dev/style_guide.md)
- [里程碑](dev/roadmap.md)

# 技术系列文章

- [整体架构](architecture.md)
- [集群](clustering.md)
- [存储介绍](storage.md)
- [查询介绍](query.md)
- [Wal 介绍](wal.md)
- [表分区](table_partitioning.md)
