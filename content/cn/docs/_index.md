---
title: "文档"
weight: 1
menu:
  main:
    weight: 20
    pre: <i class='fa-solid fa-book'></i>
---

![HoraeDB](/images/horaedb-banner-white-small.jpg)

![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)
[![CI](https://github.com/apache/horaedb/actions/workflows/ci.yml/badge.svg)](https://github.com/apache/horaedb/actions/workflows/ci.yml)
[![OpenIssue](https://img.shields.io/github/issues/apache/horaedb)](https://github.com/apache/horaedb/issues)

Apache HoraeDB™ (incubating) 是一款高性能、分布式的云原生时序数据库。

# 愿景

在经典的时序数据库中，`Tag` 列（InfluxDB 称为 `Tag`，Prometheus 称为 `Label`）通常使用倒排来进行索引。
我们发现在不同的情况下，`Tag` 的基数差异很大。在某些情况下，`Tag` 的基数非常高，存储和检索倒排索引的成本非常高。
同时，我们发现分析型数据库经常使用的扫描+剪枝可以很好地处理这些场景。

HoraeDB 的基础设计思想是采用混合存储格式和相应的查询方法，以便在处理时序和分析场景时都获得更好的性能。

# 如何使用 HoraeDB？

- 查看 [快速开始]({{< ref "getting-started.md" >}}) 掌握快速使用 HoraeDB 的方式
- HoraeDB 支持的数据模型请查看 [Data Model]({{< ref "user-guide/sql/model/_index.md" >}})
- SQL 使用相关请查看[这里]({{< ref "user-guide/sql/_index.md" >}})
- SDK 使用请查看[这里]({{< ref "user-guide/sdk/_index.md" >}})
