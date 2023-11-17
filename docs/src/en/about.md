![HoraeDB](https://github.com/CeresDB/horaedb/raw/main/docs/logo/CeresDB.png)

![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)
[![CI](https://github.com/CeresDB/horaedb/actions/workflows/ci.yml/badge.svg)](https://github.com/CeresDB/horaedb/actions/workflows/ci.yml)
[![OpenIssue](https://img.shields.io/github/issues/CeresDB/horaedb)](https://github.com/CeresDB/horaedb/issues)
[![Slack](https://badgen.net/badge/Slack/Join%20CeresDB/0abd59?icon=slack)](https://join.slack.com/t/ceresdbcommunity/shared_invite/zt-1dcbv8yq8-Fv8aVUb6ODTL7kxbzs9fnA)
[![Docker](https://img.shields.io/docker/v/ceresdb/ceresdb-server?logo=docker)](https://hub.docker.com/r/ceresdb/ceresdb-server)

HoraeDB is a high-performance, distributed, cloud native time-series database.

# Motivation

In the classic timeseries database, the `Tag` columns (InfluxDB calls them `Tag` and Prometheus calls them `Label`) are normally indexed by generating an inverted index. However, it is found that the cardinality of `Tag` varies in different scenarios. And in some scenarios the cardinality of `Tag` is very high, and it takes a very high cost to store and retrieve the inverted index. On the other hand, it is observed that scanning+pruning often used by the analytical databases can do a good job to handle such these scenarios.

The basic design idea of HoraeDB is to adopt a hybrid storage format and the corresponding query method for a better performance in processing both timeseries and analytic workloads.

# How does HoraeDB work?

- See [Quick Start](quick_start.md) to learn about how to get started
- For data model of HoraeDB, see [Data Model](sql/model/README.md)
- For the supported SQL data types, operators, and commands, please navigate to [SQL reference](sql/README.md)
- For the supported SDKs, please navigate to [SDK](sdk/README.md)
