![HoraeDB](https://github.com/CeresDB/horaedb/raw/main/docs/logo/CeresDB.png)

![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)
[![CI](https://github.com/CeresDB/horaedb/actions/workflows/ci.yml/badge.svg)](https://github.com/CeresDB/horaedb/actions/workflows/ci.yml)
[![OpenIssue](https://img.shields.io/github/issues/CeresDB/horaedb)](https://github.com/CeresDB/horaedb/issues)
[![Slack](https://badgen.net/badge/Slack/Join%20CeresDB/0abd59?icon=slack)](https://join.slack.com/t/ceresdbcommunity/shared_invite/zt-1dcbv8yq8-Fv8aVUb6ODTL7kxbzs9fnA)
[![Docker](https://img.shields.io/docker/v/ceresdb/ceresdb-server?logo=docker)](https://hub.docker.com/r/ceresdb/ceresdb-server)

HoraeDB 是一款高性能、分布式的云原生时序数据库。

# 愿景

在经典的时序数据库中，`Tag` 列（InfluxDB 称为 `Tag`，Prometheus 称为 `Label`）通常使用倒排来进行索引。
我们发现在不同的情况下，`Tag` 的基数差异很大。在某些情况下，`Tag` 的基数非常高，存储和检索倒排索引的成本非常高。
同时，我们发现分析型数据库经常使用的扫描+剪枝可以很好地处理这些场景。

HoraeDB 的基础设计思想是采用混合存储格式和相应的查询方法，以便在处理时序和分析场景时都获得更好的性能。

# 如何使用 HoraeDB？

- 查看 [快速开始](quick_start.md) 掌握快速使用 CeresDB 的方式
- HoraeDB 支持的数据模型请查看 [Data Model](sql/model/README.md)
- SQL 使用相关请查看 [SQL](sql/README.md)
- HoraeDB 支持的相关 SDK 请查看 [SDK](sdk/README.md)
