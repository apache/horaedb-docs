# 静态路由
本章介绍如何部署基于静态规则路由的 CeresDB 集群。

这里最关键的一点是，CeresDB 服务端针对表名提供了可配置的路由功能，所以我们需要提供一个包含路由规则的正确配置。根据这个配置，请求会被运送到集群中的每个 CeresDB 实例。


## 目标
首先假设我们要搭建的集群中包含部署在同一台机器上的两个 CeresDB 实例。
当然一个更大规模的集群也可以参考此方案进行部署。

## 准备配置文件

### 基础配置

CeresDB 的基础配置如下 :
```toml
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831
log_level = "info"
enable_cluster = true

[analytic]
wal_path = "/tmp/ceresdb"

[analytic.storage]
type = "Local"
data_path = "/tmp/ceresdb"
```

为了在同一个机器上部署两个实例，我们需要为每个实例配置不同的服务端口和数据目录。

实例 `CeresDB_0` 的配置如下：
```toml
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831
log_level = "info"
enable_cluster = true

[analytic]
wal_path = "/tmp/ceresdb_0"

[analytic.storage]
type = "Local"
data_path = "/tmp/ceresdb_0"
```

实例 `CeresDB_1` 的配置如下：
```toml
bind_addr = "0.0.0.0"
http_port = 15440
grpc_port = 18831
log_level = "info"
enable_cluster = true

[analytic]
wal_path = "/tmp/ceresdb_1"

[analytic.storage]
type = "Local"
data_path = "/tmp/ceresdb_1"
```

### Schema&Shard 定义

接下来我们需要定义 `Schema` 和分片以及路由规则。

如下定义了 `Schema` 和分片：
```toml
[[static_route.topology.schema_shards]]
schema = 'public_0'
[[static_route.topology.schema_shards.shard_views]]
shard_id = 0
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[static_route.topology.schema_shards.shard_views]]
shard_id = 1
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831

[[static_route.topology.schema_shards]]
schema = 'public_1'
[[static_route.topology.schema_shards.shard_views]]
shard_id = 0
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[static_route.topology.schema_shards.shard_views]]
shard_id = 1
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 18831
```

上述的配置中，定义了两个 `Schema`：
* `public_0` 有两个分片在 `CeresDB_0` 实例上。
* `public_1` 有两个分片同时在 `CeresDB_0` 和 `CeresDB_1` 实例上。

### 路由规则

定义 `Schema` 和分片后，需要定义路由规则，如下是一个前缀路由规则：
```toml
[[route_rules.prefix_rules]]
schema = 'public_0'
prefix = 'prod_'
shard = 0
```

在这个规则里，`public_0` 中表名以 `prod_` 为前缀的所有表属于，相关操作会被路由到 `shard_0` 也就是 `CeresDB_0` 实例。 `public_0` 中其他的表会以 hash 的方式路由到 `shard_0` 和 `shard_1`.

在前缀规则之外，我们也可以定义一个 hash 规则：
```toml
[[route_rules.hash_rules]]
schema = 'public_1'
shards = [0, 1]
```
这个规则告诉 CeresDB, `public_1` 的所有表会被路由到 `public_1` 的 `shard_0` and `shard_1`, 也就是 `CeresDB0` 和 `CeresDB_1`. 
实际上如果没有定义 `public_1` 的路由规则，这是默认的路由行为。

`CeresDB_0` 和 `CeresDB_1` 实例完整的配置文件如下 :

```toml
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831
log_level = "info"
enable_cluster = true

[analytic]
wal_path = "/tmp/ceresdb_0"

[analytic.storage]
type = "Local"
data_path = "/tmp/ceresdb_0"

[[static_route.topology.schema_shards]]
schema = 'public_0'
[[static_route.topology.schema_shards.shard_views]]
shard_id = 0
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[static_route.topology.schema_shards.shard_views]]
shard_id = 1
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831

[[static_route.topology.schema_shards]]
schema = 'public_1'
[[static_route.topology.schema_shards.shard_views]]
shard_id = 0
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[static_route.topology.schema_shards.shard_views]]
shard_id = 1
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 18831

[[static_route.rules.prefix_rules]]
schema = 'public_0'
prefix = 'prod_'
shard = 0

[[static_route.rules.hash_rules]]
schema = 'public_1'
shards = [0, 1]
```

```toml
bind_addr = "0.0.0.0"
http_port = 15440
grpc_port = 18831
log_level = "info"
enable_cluster = true

[analytic]
wal_path = "/tmp/ceresdb_1"

[analytic.storage]
type = "Local"
data_path = "/tmp/ceresdb_1"

[[static_route.topology.schema_shards]]
schema = 'public_0'
[[static_route.topology.schema_shards.shard_views]]
shard_id = 0
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[static_route.topology.schema_shards.shard_views]]
shard_id = 1
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831

[[static_route.topology.schema_shards]]
schema = 'public_1'
[[static_route.topology.schema_shards.shard_views]]
shard_id = 0
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[static_route.topology.schema_shards.shard_views]]
shard_id = 1
[static_route.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 18831

[[static_route.rules.prefix_rules]]
schema = 'public_0'
prefix = 'prod_'
shard = 0

[[static_route.rules.hash_rules]]
schema = 'public_1'
shards = [0, 1]
```

我们给这两份不同的配置文件分别命名为 `config_0.toml` 和 `config_1.toml`；
但是在实际环境中不同的实例可以部署在不同的服务器上，也就是说，不同的实例没有必要设置不同的服务端口和数据目录，这种情况下实例的配置可以使用同一份配置文件。 

## 启动 CeresDB

配置准备好后，我们就可以开始启动 CeresDB 容器了。

启动命令如下：
```shell
sudo docker run -d -t --name ceresdb_0 -p 5440:5440 -p 8831:8831 -v $(pwd)/config_0.toml:/etc/ceresdb/ceresdb.toml ceresdb/ceresdb-server:v0.1.0-alpha
sudo docker run -d -t --name ceresdb_1 -p 15440:15440 -p 18831:18831 -v $(pwd)/config_1.toml:/etc/ceresdb/ceresdb.toml ceresdb/ceresdb-server:v0.1.0-alpha
```

容器启动成功后，两个实例的 CeresDB 集群就搭建完成了，可以开始提供读写服务。
