---
title: "Docs"
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

Apache HoraeDB™ (incubating) is a high-performance, distributed, cloud native time-series database.

# Motivation

In the classic timeseries database, the `Tag` columns (InfluxDB calls them `Tag` and Prometheus calls them `Label`) are normally indexed by generating an inverted index. However, it is found that the cardinality of `Tag` varies in different scenarios. And in some scenarios the cardinality of `Tag` is very high, and it takes a very high cost to store and retrieve the inverted index. On the other hand, it is observed that scanning+pruning often used by the analytical databases can do a good job to handle such these scenarios.

The basic design idea of HoraeDB is to adopt a hybrid storage format and the corresponding query method for a better performance in processing both timeseries and analytic workloads.
