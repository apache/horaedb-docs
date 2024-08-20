---
title: "集群部署"
weight: 20
---

在[快速开始](../quick_start.md)部分我们已经介绍过单机版本 HoraeDB 的部署。

除此之外，HoraeDB 作为一个分布式时序数据库，多个 HoraeDB 实例能够以集群的方式提供可伸缩和高可用的数据服务。

由于目前 HoraeDB 对于 Kubernetes 的支持还在开发之中，目前 HoraeDB 集群部署只能通过手动完成，集群部署的模式主要有两种，两者的区别在于是否需要部署 HoraeMeta，对于 `NoMeta` 的模式，我们仅建议在测试场景下使用。
