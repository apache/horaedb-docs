# 部署

在[快速开始](../quick_start.md)部分我们已经介绍过单机版本 CeresDB 的部署。

除此之外，CeresDB 作为一个分布式时序数据库，多个 CeresDB 实例能够以集群的方式提供可伸缩和高可用的数据服务。

目前 CeresDB 支持两种集群部署模式：

- 基于规则的 [静态路由集群部署](static_routing.md)
- 基于 CeresMeta 的 [动态路由集群部署](dynamic_routing.md)
