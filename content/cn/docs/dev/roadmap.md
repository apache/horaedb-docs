---
title: "RoadMap"
weight: 30
---

### v0.1.0

- [x] 支持基于本地磁盘的 Standalone 版本
- [x] 支持分析存储格式
- [x] 支持 SQL

### v0.2.0

- [x] 静态路由的分布式版本
- [x] 远端存储支持阿里云 OSS
- [x] 支持基于 [OBKV](https://github.com/oceanbase/oceanbase)的 WAL

### v0.3.0

- [x] 发布多语言客户端，包括 Java, Rust 和 Python
- [x] 支持使用 `HoraeMeta` 的静态集群
- [x] 混合存储格式基本实现

### v0.4.0

- [x] 实现更复杂的集群方案，增强 HoraeDB 的可靠性和可扩展性
- [x] 构建日常运行的、基于 TSBS 的压测任务

### v1.0.0-alpha (Released)

- [x] 基于 `Apache Kafka` 实现分布式 WAL
- [x] 发布 Golang 客户端
- [x] 优化时序场景下的查询性能
- [x] 支持集群模式下表的动态转移

### v1.0.0

- [x] 正式发布 HoraeDB 和相关 SDK，并完成所有的 breaking changes
- [x] 完成分区表的主要工作
- [x] 优化查询性能，特别是云原生集群模式下，包括：
  - 多级缓存
  - 多种方式减少从远端获取的数据量(提高 SST 数据过滤精度)
  - 提高获取远程对象存储数据的并发度
- [x] 通过控制合并时的资源消耗，提高数据写入性能

### Afterwards

随着对时序数据库及其各种使用情况的深入了解，我们的大部分工作将聚焦在性能、可靠性、可扩展性、易用性以及与开源社区的合作方面

- [ ] 增加支持 `PromQL`, `InfluxQL`, `OpenTSDB` 协议
- [ ] 提供基础的运维工具。特别包括如下：
  - 适配云基础设施的部署工具，如 `Kubernetes`
  - 加强自监控能力，特别是关键的日志和指标
- [ ] 开发多种工具，方便使用 HoraeDB，例如，数据导入和导出工具
- [ ] 探索新的存储格式，提高混合负载（分析和时序负载）的性能