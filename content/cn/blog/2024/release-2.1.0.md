---
title: 2.1.0 版本发布
date: 2024-11-18
tags:
  - release
---

Apache HoraeDB（孵化中）团队很高兴地宣布，v2.1.0 版本已于 2024-11-18 发布，这个版本解决了 60 多个问题，并且包括两个主要功能：

## 1. 引入基于本地磁盘的新 WAL 实现

在之前的版本中，有一个基于 RocksDB 的 WAL。虽然它在大多数情况下运行良好，但存在以下问题：

- 从源代码编译可能是一项具有挑战性的任务，尤其是因为 RocksDB 主要是用 C++ 编写的。
- 对于 WAL 而言，RocksDB 可能有些矫枉过正。如果你对 RocksDB 不熟悉，那么对它进行调整可能会非常具有挑战性。

通过这个新的 WAL，就很好的解决了上面两个问题，而且在性能测试结果，新 WAL 的表现略优于之前的实现，给以后的优化打下了结实的基础。

![写入速率对比](/images/local-wal-write.png)
![回放速率对比](/images/local-wal-replay.png)

感兴趣的朋友可以参考[这里的设计文档]({{< ref "wal_on_disk.md" >}})了解更多这个特性的细节。

## 2. 使用 Apache OpenDAL 访问对象存储

Apache OpenDAL 是一个为访问各种数据存储后端提供统一 API 的项目。以下是一些主要优势：

- 统一的 API：OpenDAL 为访问 AWS S3、Azure Blob Storage 和本地文件系统等不同存储后端提供了一致、统一的 API。
- 优化效率：OpenDAL 在构建时就考虑到了性能。它包括确保高效数据访问和操作的优化功能，使其适用于高性能应用程序。
- 全面的文档：该项目提供了详细的文档，使开发人员更容易上手并了解如何有效地使用该库。

在较新版本的 OpenDAL 中，提供了 `object_store` 的[集成](https://github.com/apache/opendal/tree/main/integrations/object_store)，这非常有利于 HoraeDB 的代码迁移，上层使用的 API 几乎没有发生变化，只需要将对象存储抽象为统一的 OpenDAL operator：

```rust
// Create a new operator
let operator = Operator::new(S3::default())?.finish();

// Create a new object store
let object_store = Arc::new(OpendalStore::new(operator));
```

此外，由于 Apache OpenDAL 实现的 `object_store` 是基于最新版本的，相较于 HoraeDB 之前使用的版本，`object_store` 接口发生了变化，为了保证本次升级范围尽量可控，我们选择对其进行兼容。

对新 API 适配的过程中， `put_multipart` 接口变化最大，因此主要的适配逻辑也在这里，HoraeDB 的做法是：对底层的 `put_multipart` 接口进行了封装，保证上层代码无修改，具体细节可参考：

- https://github.com/apache/horaedb/blob/v2.1.0/src/components/object_store/src/multi_part.rs

> 说明：在 parquet 最新版本中，写入路径上对新 `put_multipart` 接口适配程度较高，若用户使用的 parquet 版本 >= 52.0.0，则无需进行适配，若是更老的版本，可参考 HoraeDB 的适配实现。

## 下载

见[下载页面](/downloads)。

## 总结

其他错误修复和改进请参见此处：
https://github.com/apache/horaedb/releases/tag/v2.1.0

> 我们一如既往地热忱欢迎您加入[我们的社区](/community)，分享您的真知灼见。
