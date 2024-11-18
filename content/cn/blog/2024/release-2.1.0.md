---
title: 2.1.0 版本发布
date: 2024-11-18
tags: release
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

## 下载

见[下载页面](/downloads)。

## 其他

其他错误修复和改进请参见此处：
https://github.com/apache/horaedb/releases/tag/v2.1.0

> 我们一如既往地热忱欢迎您加入[我们的社区](/community)，分享您的真知灼见。
