---
title: Release 2.1.0
date: 2024-11-18
---

The Apache HoraeDB(incubating) team are pleased to announce that v2.1.0 is released, which has closed over 60 issues, including two major features:

- Introduce a new WAL implementation based on local disk.

  In previous version, there is a RocksDB-based WAL. Although it works well in most cases, it has following issues:

  - Compiling from source can be a challenging task, especially since RocksDB is primarily written in C++.
  - For WAL, RocksDB can be somewhat overkill. If you are not familiar with RocksDB, tuning it can be very challenging.

- Access object store with [Apache OpenDAL](https://github.com/apache/opendal)

Other bug fixes and improvements can be seen here:

- https://github.com/apache/horaedb/releases/tag/v2.1.0

As always, we warmly welcome you to join our [community](/community) and share your insights.
