# 存储引擎

存储引擎主要提供以下两个功能：
1.  数据的持久化
2.  在保证数据正确性的前提下，用最合理的方式来组织数据，来满足不同场景的查询需求

本篇文档就来介绍 CeresDB 中存储引擎的内部实现，读者可以参考这里面的内容，来探索如何高效使用 CeresDB。


# 整体架构

CeresDB 是一种基于 share-nothing 架构的分布式存储系统，不同服务器之间的数据相互隔离，互不影响。每一个单机中的存储引擎是 LSM（Log-structured merge-tree）的一个变种，针对时序场景做了优化，下图展示了其主要组件的运作方式：

![](../resources/images/storage-overview.svg)

## Write Ahead Log (WAL)

一次写入请求的数据会写到两个部分：
1.  内存中的 memtable
2.  可持久化的 WAL

由于 memtable 不是实时持久化到底层存储系统，因此需要用 WAL 来保证 memtable 中数据的可靠性。

另一方面，由于分布式架构的设计，要求 WAL 本身是高可用的，现在 CeresDB 中，主要有以下几种实现：
- 本地磁盘（基于 [RocksDB](http://rocksdb.org/)，无分布式高可用）
- [Oceanbase](https://www.oceanbase.com)
- Kafka

## Memtable

Memtable 是一个内存的数据结构，用来保存最近写入的数据。一个表对应一个 memtable。

Memtable 默认是可读写的（称为 active），当写入达到一起阈值时，会变成只读的并且被一个新的 memtable 替换掉。只读的 memtable 会被后台线程以 SST 的形式写入到底层存储系统中，写入完成后，只读的 memtable 就可以被销毁，同时 WAL 中也可以删除对应部分的数据。

## Sorted String Table（SST）

SST 是数据的持久化格式，按照表主键的顺序存放，目前 CeresDB 采用 parquet 格式来存储。

对于 CeresDB 来说，SST 有一个重要特性： `segment_duration`，只有同一个 segment 内的 SST 才有可能进行合并操作。而且有了 segment，也方便淘汰过期的数据。

除了存放原始数据外，SST 内也会存储数据的统计信息来加速查询，比如：最大值、最小值等。

## Compactor

Compactor 可以把多个小 SST 文件合并成一个，用于解决小文件数过多的问题。此外，Compactor 也会在合并时进行过期数据的删除，重复数据的去重。目前 CeresDB 中的合并策略参考自 Cassandra，主要有两个：
- [SizeTieredCompactionStrategy](https://cassandra.apache.org/doc/latest/cassandra/operating/compaction/stcs.html)
- [TimeWindowCompactionStrategy](https://cassandra.apache.org/doc/latest/cassandra/operating/compaction/twcs.html)

## Manifest

Manifest 记录表、SST文件元信息，比如：一个 SST 内数据的最小、最大时间戳。

由于分布式架构的设计，要求 Manifest 本身是高可用的，现在 CeresDB 中，主要有以下几种实现：
- WAL
- ObjectStore

## ObjectStore

ObjectStore 是数据（即 SST）持久化的地方，一般来说各大云厂商均有对应服务，像阿里云的 OSS，AWS 的 S3。
