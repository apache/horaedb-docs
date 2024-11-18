---
title: Release 2.1.0
date: 2024-11-18
tags: release
---

The Apache HoraeDB(incubating) team are pleased to announce that v2.1.0 is released, which has closed over 60 issues, including two major features:

## 1. New WAL implementation based on local disk.

In previous version, there is a RocksDB-based WAL. Although it works well in most cases, it has following issues:

- Compiling from source can be a challenging task, especially since RocksDB is primarily written in C++.
- For WAL, RocksDB can be somewhat overkill. If you are not familiar with RocksDB, tuning it can be very challenging.

With this new WAL, the above two problems are solved very well, and in performance test, the new WAL slightly outperforms the previous implementation, giving a solid foundation for future optimizations.

![Comparison of Write throughout](/images/local-wal-write.png)
![Comparison of Replay time](/images/local-wal-replay.png)

Interested readers can refer to the design documentation [here]({{< ref "wal_on_disk" >}}) for more details on this feature.

### How to enable

```
[analytic.wal]
type = "Local"
data_dir = "/path/to/local/wal"
```

## 2. Access object store with [Apache OpenDAL](https://github.com/apache/opendal)

OpenDAL (Open Data Access Layer) is a project that provides a unified API for accessing various data storage backends.
It offers several advantages for developers and organizations. Here are some key benefits:

- Unified API. OpenDAL provides a consistent and unified API for accessing different storage backends, such as AWS S3, Azure Blob Storage, and local file systems.
- Optimized for Efficiency: OpenDAL is built with performance in mind. It includes optimizations to ensure efficient data access and manipulation, making it suitable for high-performance applications.
- Comprehensive Documentation: The project provides detailed documentation, making it easier for developers to get started and understand how to use the library effectively.

## Download

Go to [download pages](/downloads).

## Others

Other bug fixes and improvements can be seen here:

- https://github.com/apache/horaedb/releases/tag/v2.1.0

> As always, we warmly welcome you to join our [community](/community) and share your insights.
