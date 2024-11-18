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

In newer versions of OpenDAL, [object_store integration](https://github.com/apache/opendal/tree/main/integrations/object_store) is provided, which is very beneficial for HoraeDB code migration, as the APIs used by the upper layers remain virtually unchanged, and only the object store part needs to be abstracted to a unified OpenDAL operator:

```rust
// Create a new operator
let operator = Operator::new(S3::default())?.finish();

// Create a new object store
let object_store = Arc::new(OpendalStore::new(operator));
```

Additionally, since the Apache OpenDAL implementation of `object_store` is based on the latest version of the object_store, which has breaking changes from the previous version that HoraeDB is using, we've chosen to make it compatible in order to keep the scope of this upgrade as manageable as possible.

In the process of adapting to the new API, the `put_multipart` interface has changed the most, so the main adaptation logic is also here, HoraeDB's approach is to encapsulate the underlying `put_multipart` interface to ensure that the upper layer code is not modified, the details can be found in the reference:

https://github.com/apache/horaedb/blob/v2.1.0/src/components/object_store/src/multi_part.rs

> Note: The adaptation logic is only practical when parquet version < 52.0.0.

## Download

Go to [download pages](/downloads).

## Conclusion

Other bug fixes and improvements can be seen here:

- https://github.com/apache/horaedb/releases/tag/v2.1.0

> As always, we warmly welcome you to join our [community](/community) and share your insights.
