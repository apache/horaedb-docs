# Deployment
CeresDB 是一个分布式时序数据库，也就是说，多个CeresDB数据库实例能够以集群的方式提供可伸缩和高可用的数据服务。

目前CeresDB支持两种集群部署模式：
* 基于规则的 [静态路由集群部署](static_routing.md)
* 基于CeresMeta的 [动态路由集群部署](dynamic_routing.md)