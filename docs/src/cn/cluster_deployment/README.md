# 集群部署

在[快速开始](../quick_start.md)部分我们已经介绍过单机版本 CeresDB 的部署。

除此之外，CeresDB 作为一个分布式时序数据库，多个 CeresDB 实例能够以集群的方式提供可伸缩和高可用的数据服务。

由于目前 CeresDB 对于 Kubernetes 的支持还在开发之中，目前 CeresDB 集群部署只能通过手动完成，集群部署的模式主要有两种，两者的区别在于是否需要部署 CeresMeta，对于 `NoMeta` 的模式，我们仅建议在简单场景（无高可用、数据容灾要求，数据量不大，或者测试验证场景）下使用。

- [NoMeta 模式](no_meta.md)
- [WithMeta 模式](with_meta.md)
