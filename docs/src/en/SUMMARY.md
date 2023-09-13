# Summary

# Introduction

- [What is CeresDB](about.md)
- [Quick Start](quick_start.md)

# User Guide

- [SQL Syntax](sql/README.md)
  - [Data Model](sql/model/README.md)
    - [Data Types](sql/model/data_types.md)
    - [Special Columns](sql/model/special_columns.md)
  - [Identifier](sql/identifier.md)
  - [Data Definition Statements](sql/ddl/README.md)
    - [CREATE TABLE](sql/ddl/create_table.md)
    - [ALTER TABLE](sql/ddl/alter_table.md)
    - [DROP TABLE](sql/ddl/drop_table.md)
  - [Data Manipulation Statements](sql/dml/README.md)
    - [INSERT](sql/dml/insert.md)
    - [SELECT](sql/dml/select.md)
  - [Utility Statements](sql/utility.md)
  - [Engine Options](sql/engine_options.md)
  - [Scalar Functions](sql/functions/scalar_functions.md)
  - [Aggregate Functions](sql/functions/aggregate_functions.md)
- [Cluster Deployment](cluster_deployment/README.md)
  - [Supported Platform](cluster_deployment/platform.md)
  - [NoMeta Mode](cluster_deployment/no_meta.md)
  - [WithMeta Mode](cluster_deployment/with_meta.md)
- [SDK](sdk/README.md)
  - [Java](sdk/java.md)
  - [Go](sdk/go.md)
  - [Python](sdk/python.md)
  - [Rust](sdk/rust.md)
- [Operation](operation/README.md)
  - [Table](operation/table.md)
  - [System Table](operation/system_table.md)
  - [Block List](operation/block_list.md)
  - [Observability](operation/observability.md)
  - [CeresMeta](operation/ceresmeta.md)
- [Ecosystem](ecosystem/README.md)
  - [Prometheus](ecosystem/prometheus.md)
  - [InfluxDB](ecosystem/influxdb.md)
  - [OpenTSDB](ecosystem/opentsdb.md)

# Dev Guide

- [Supported Platform](dev/platform.md)
- [Compile and Running](dev/compile_run.md)
  - [Profile](dev/profiling.md)
- [Conventional Commit](dev/conventional_commit.md)
- [Style guide](dev/style_guide.md)
- [Roadmap](dev/roadmap.md)

# Technical and Design

- [Architecture](design/architecture.md)
- [Cluster](design/clustering.md)
- [Storage](design/storage.md)
- [WAL](design/wal.md)
  - [WAL on RocksDB](design/wal_on_rocksdb.md)
  - [WAL on Kafka](design/wal_on_kafka.md)
- [Table Partitioning](design/table_partitioning.md)

[//]: # "- [Query](query.md)"
