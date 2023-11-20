**注意：此功能仅供测试使用，不推荐生产使用，相关功能将来可能会发生变化。**

# NoMeta 模式

本章介绍如何部署一个静态（无 HoraeMeta）的 HoraeDB 集群。

在没有 HoraeMeta 的情况下，利用 HoraeDB 服务端针对表名提供了可配置的路由功能即可实现集群化部署，为此我们需要提供一个包含路由规则的正确配置。根据这个配置，请求会被发送到集群中的每个 HoraeDB 实例。

## 目标

本文的目标是：在同一台机器上部署一个集群，这个集群包含两个 HoraeDB 实例。

如果想要部署一个更大规模的集群，参考此方案也可以进行部署。

## 准备配置文件

### 基础配置

HoraeDB 的基础配置如下：

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831

[logger]
level = "info"

[tracing]
dir = "/tmp/horaedb"

[analytic.storage.object_store]
type = "Local"
data_dir = "/tmp/horaedb"

[analytic.wal]
type = "RocksDB"
data_dir = "/tmp/horaedb"
```

为了在同一个机器上部署两个实例，我们需要为每个实例配置不同的服务端口和数据目录。

实例 `HoraeDB_0` 的配置如下：

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831

[logger]
level = "info"

[tracing]
dir = "/tmp/horaedb_0"

[analytic.storage.object_store]
type = "Local"
data_dir = "/tmp/horaedb_0"

[analytic.wal]
type = "RocksDB"
data_dir = "/tmp/horaedb_0"
```

实例 `HoraeDB_1` 的配置如下：

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 15440
grpc_port = 18831

[logger]
level = "info"

[tracing]
dir = "/tmp/horaedb_1"

[analytic.storage.object_store]
type = "Local"
data_dir = "/tmp/horaedb_1"

[analytic.wal]
type = "RocksDB"
data_dir = "/tmp/horaedb_1"
```

### Schema 和 Shard

接下来我们需要定义 `Schema` 和分片以及路由规则。

如下定义了 `Schema` 和分片：

```toml
[cluster_deployment]
mode = "NoMeta"

[[cluster_deployment.topology.schema_shards]]
schema = 'public_0'
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 0
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 1
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831

[[cluster_deployment.topology.schema_shards]]
schema = 'public_1'
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 0
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 1
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 18831
```

上述的配置中，定义了两个 `Schema`：

- `public_0` 有两个分片在 `HoraeDB_0` 实例上。
- `public_1` 有两个分片同时在 `HoraeDB_0` 和 `HoraeDB_1` 实例上。

### 路由规则

定义 `Schema` 和分片后，需要定义路由规则，如下是一个前缀路由规则：

```toml
[[cluster_deployment.route_rules.prefix_rules]]
schema = 'public_0'
prefix = 'prod_'
shard = 0
```

在这个规则里，`public_0` 中表名以 `prod_` 为前缀的所有表属于，相关操作会被路由到 `shard_0` 也就是 `HoraeDB_0` 实例。 `public_0` 中其他的表会以 hash 的方式路由到 `shard_0` 和 `shard_1`.

在前缀规则之外，我们也可以定义一个 hash 规则：

```toml
[[cluster_deployment.route_rules.hash_rules]]
schema = 'public_1'
shards = [0, 1]
```

这个规则告诉 HoraeDB, `public_1` 的所有表会被路由到 `public_1` 的 `shard_0` and `shard_1`, 也就是 `HoraeDB0` 和 `HoraeDB_1`.
实际上如果没有定义 `public_1` 的路由规则，这是默认的路由行为。

`HoraeDB_0` 和 `HoraeDB_1` 实例完整的配置文件如下：

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831

[logger]
level = "info"

[tracing]
dir = "/tmp/horaedb_0"

[analytic.storage.object_store]
type = "Local"
data_dir = "/tmp/horaedb_0"

[analytic.wal]
type = "RocksDB"
data_dir = "/tmp/horaedb_0"

[cluster_deployment]
mode = "NoMeta"

[[cluster_deployment.topology.schema_shards]]
schema = 'public_0'
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 0
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 1
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831

[[cluster_deployment.topology.schema_shards]]
schema = 'public_1'
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 0
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 1
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 18831
```

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 15440
grpc_port = 18831

[logger]
level = "info"

[tracing]
dir = "/tmp/horaedb_1"

[analytic.storage.object_store]
type = "Local"
data_dir = "/tmp/horaedb_1"

[analytic.wal]
type = "RocksDB"
data_dir = "/tmp/horaedb_1"

[cluster_deployment]
mode = "NoMeta"

[[cluster_deployment.topology.schema_shards]]
schema = 'public_0'
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 0
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 1
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831

[[cluster_deployment.topology.schema_shards]]
schema = 'public_1'
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 0
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 8831
[[cluster_deployment.topology.schema_shards.shard_views]]
shard_id = 1
[cluster_deployment.topology.schema_shards.shard_views.endpoint]
addr = '127.0.0.1'
port = 18831
```

我们给这两份不同的配置文件分别命名为 `config_0.toml` 和 `config_1.toml`；
但是在实际环境中不同的实例可以部署在不同的服务器上，也就是说，不同的实例没有必要设置不同的服务端口和数据目录，这种情况下实例的配置可以使用同一份配置文件。

## 启动 HoraeDB

配置准备好后，我们就可以开始启动 HoraeDB 容器了。

启动命令如下：

```shell
sudo docker run -d -t --name horaedb_0 -p 5440:5440 -p 8831:8831 -v $(pwd)/config_0.toml:/etc/ceresdb/ceresdb.toml ceresdb/ceresdb-server
sudo docker run -d -t --name horaedb_1 -p 15440:15440 -p 18831:18831 -v $(pwd)/config_1.toml:/etc/ceresdb/ceresdb.toml ceresdb/ceresdb-server
```

容器启动成功后，两个实例的 HoraeDB 集群就搭建完成了，可以开始提供读写服务。
