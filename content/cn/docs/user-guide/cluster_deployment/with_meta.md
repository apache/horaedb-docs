---
title: "WithMeta 模式"
---

本文展示如何部署一个由 HoraeMeta 控制的 HoraeDB 集群，有了 HoraeMeta 提供的服务，如果 HoraeDB 使用存储不在本地的话，就可以实现很多分布式特性，比如水平扩容、负载均衡、服务高可用等。

## 部署 HoraeMeta

HoraeMeta 是 HoraeDB 分布式模式的核心服务之一，用于管理 HoraeDB 节点的调度，为 HoraeDB 集群提供高可用、负载均衡、集群管控等能力。
HoraeMeta 本身通过嵌入式的 [ETCD](https://github.com/etcd-io/etcd) 保障高可用。此外，ETCD 的服务也被暴露给 HoraeDB 用于实现分布式锁使用。

### 编译打包

- 安装 Golang，版本号 >= 1.19。
- 在项目根目录下使用 `make build` 进行编译打包。

### 部署方式

#### 启动配置

目前 HoraeMeta 支持以配置文件和环境变量两种方式来指定服务启动配置。我们提供了配置文件方式启动的示例，具体可以参考 [config](https://github.com/apache/horaedb/tree/main/horaemeta/config)。
环境变量的配置优先级高于配置文件，当同时存在时，以环境变量为准。

#### 动态拓扑和静态拓扑

即使使用了 HoraeMeta 来部署 HoraeDB 集群，也可以选择静态拓扑或动态拓扑。对于静态拓扑，表的分布在集群初始化后是静态的，而对于动态拓扑，表可以在不同的 HoraeDB 节点之间进行动态迁移以达到负载平衡或者 failover 的目的。但是动态拓扑只有在 HoraeDB 节点使用的存储是非本地的情况下才能启用，否则会因为表的数据是持久化在本地，当表转移到不同的 HoraeDB 节点时会导致数据损坏。

目前，HoraeMeta 默认关闭集群拓扑的动态调度，并且在本篇指南中，这个选项也不会被开启，因为指南中的例子采用的是本地存储。如果要启用动态调度，可以将 `TOPOLOGY_TYPE` 设置为 `dynamic`（默认为 `static`），之后负载均衡和 failover 将会起作用。但是需要注意的是，如果底层存储是本地磁盘，则不要启用它。

此外对于静态拓扑，参数 `DEFAULT_CLUSTER_NODE_COUNT` 表示已部署集群中 HoraeDB 节点的数量，应该被设置为 HoraeDB 服务器的实际机器数，这个参数非常重要，因为集群初始化完毕之后，HoraeDB 集群将无法再增减机器。

#### 启动实例

HoraeMeta 基于 etcd 实现高可用，在线上环境我们一般部署多个节点，但是在本地环境和测试时，可以直接部署单个节点来简化整个部署流程。

- 单节点

```bash
docker run -d --name horaemeta-server \
  -p 2379:2379 \
  ghcr.io/apache/horaemeta-server:nightly-20231225-ab067bf0
```

- 多节点

```bash
wget https://horaedb.apache.org/config-horaemeta-cluster0.toml

docker run -d --network=host --name horaemeta-server0 \
  -v $(pwd)/config-horaemeta-cluster0.toml:/etc/horaemeta/horaemeta.toml \
  ghcr.io/apache/horaemeta-server:nightly-20231225-ab067bf0

wget https://horaedb.apache.org/config-horaemeta-cluster1.toml

docker run -d --network=host --name horaemeta-server1 \
  -v $(pwd)/config-horaemeta-cluster1.toml:/etc/horaemeta/horaemeta.toml \
  ghcr.io/apache/horaemeta-server:nightly-20231225-ab067bf0

wget https://horaedb.apache.org/config-horaemeta-cluster2.toml

docker run -d --network=host --name horaemeta-server2 \
  -v $(pwd)/config-horaemeta-cluster2.toml:/etc/horaemeta/horaemeta.toml \
  ghcr.io/apache/horaemeta-server:nightly-20231225-ab067bf0
```

如果 HoraeDB 底层采用的是远程存储，可以环境变量来开启动态调度：只需将 `-e ENABLE_SCHEDULE=true` 加入到 docker run 命令中去。

## 部署 HoraeDB

在 `NoMeta` 模式中，由于 HoraeDB 集群拓扑是静态的，因此 HoraeDB 只需要一个本地存储来作为底层的存储层即可。但是在 `WithMeta` 模式中，集群的拓扑是可以变化的，因此如果 HoraeDB 的底层存储使用一个独立的存储服务的话，HoraeDB 集群就可以获得分布式系统的一些特性：高可用、负载均衡、水平扩展等。
当然，HoraeDB 仍然可以使用本地存储，这样的话，集群的拓扑仍然是静态的。

存储相关的配置主要包括两个部分：

- Object Storage
- WAL Storage

注意：在生产环境中如果我们把 HoraeDB 部署在多个节点上时，请按照如下方式把机器的网络地址设置到环境变量中：

```shell
export HORAEDB_SERVER_ADDR="{server_addr}:8831"
```

注意，此网络地址用于 HoraeMeta 和 HoraeDB 通信使用，需保证网络联通可用。

### Object Storage

#### 本地存储

类似 `NoMeta` 模式，我们仍然可以为 HoraeDB 配置一个本地磁盘作为底层存储：

```toml
[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/horaedb"
```

#### OSS

Aliyun OSS 也可以作为 HoraeDB 的底层存储，以此提供数据容灾能力。下面是一个配置示例，示例中的模版变量需要被替换成实际的 OSS 参数才可以真正的使用：

```toml
[analytic.storage.object_store]
type = "Aliyun"
key_id = "{key_id}"
key_secret = "{key_secret}"
endpoint = "{endpoint}"
bucket = "{bucket}"
prefix = "{data_dir}"
```

#### S3

Amazon S3 也可以作为 HoraeDB 的底层存储，下面是一个配置示例，示例中的模版变量需要被替换成实际的 S3 参数才可以真正的使用：

```toml
[analytic.storage.object_store]
type = "S3"
region = "{region}"
key_id = "{key_id}"
key_secret = "{key_secret}"
endpoint = "{endpoint}"
bucket = "{bucket}"
prefix = "{prefix}"
```

### WAL Storage

#### RocksDB

基于 RocksDB 的 WAL 也是一种本地存储，无第三方依赖，可以很方便的快速部署：

```toml
[analytic.wal]
type = "RocksDB"
data_dir = "/home/admin/data/horaedb"
```

#### OceanBase

如果已经有了一个部署好的 OceanBase 集群的话，HoraeDB 可以使用它作为 WAL Storage 来保证其数据的容灾性。下面是一个配置示例，示例中的模版变量需要被替换成实际的 OceanBase 集群的参数才可以真正的使用：

```toml
[analytic.wal]
type = "Obkv"

[analytic.wal.data_namespace]
ttl = "365d"

[analytic.wal.obkv]
full_user_name = "{full_user_name}"
param_url = "{param_url}"
password = "{password}"

[analytic.wal.obkv.client]
sys_user_name = "{sys_user_name}"
sys_password = "{sys_password}"
```

#### Kafka

如果你已经部署了一个 Kafka 集群，HoraeDB 可以也可以使用它作为 WAL Storage。下面是一个配置示例，示例中的模版变量需要被替换成实际的 Kafka 集群的参数才可以真正的使用：

```toml
[analytic.wal]
type = "Kafka"

[analytic.wal.kafka.client]
boost_broker = "{boost_broker}"
```

#### Meta 客户端配置

除了存储层的配置外，HoraeDB 需要 HoraeMeta 相关的配置来与 HoraeMeta 集群进行通信：

```
[cluster.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://{HoraeMetaAddr}:2379'
lease = "10s"
timeout = "5s"

[cluster_deployment.etcd_client]
server_addrs = ['http://{HoraeMetaAddr}:2379']
```

### 完整配置

将上面提到的所有关键配置合并之后，我们可以得到一个完整的、可运行的配置。为了让这个配置可以直接运行起来，配置中均采用了本地存储：基于 RocksDB 的 WAL 和本地磁盘的 Object Storage：

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831

[logger]
level = "info"

[runtime]
read_thread_num = 20
write_thread_num = 16
background_thread_num = 12

[cluster_deployment]
mode = "WithMeta"

[cluster_deployment.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://127.0.0.1:2379'
lease = "10s"
timeout = "5s"

[cluster_deployment.etcd_client]
server_addrs = ['127.0.0.1:2379']

[analytic]
write_group_worker_num = 16
replay_batch_size = 100
max_replay_tables_per_batch = 128
write_group_command_channel_cap = 1024
sst_background_read_parallelism = 8

[analytic.manifest]
scan_batch_size = 100
snapshot_every_n_updates = 10000
scan_timeout = "5s"
store_timeout = "5s"

[analytic.wal]
type = "RocksDB"
data_dir = "/home/admin/data/horaedb"

[analytic.storage]
mem_cache_capacity = "20GB"
# 1<<8=256
mem_cache_partition_bits = 8

[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/horaedb/"

[analytic.table_opts]
arena_block_size = 2097152
write_buffer_size = 33554432

[analytic.compaction]
schedule_channel_len = 16
schedule_interval = "30m"
max_ongoing_tasks = 8
memory_limit = "4G"
```

将这个配置命名成 `config.toml`。至于使用远程存储的配置示例在下面我们也提供了，需要注意的是，配置中的相关参数需要被替换成实际的参数才能真正使用：

- [本地 RocksDB WAL + OSS](../../resources/config_local_oss.toml)
- [OceanBase WAL + OSS](../../resources/config_obkv_oss.toml)
- [Kafka WAL + OSS](../../resources/config_kafka_oss.toml)

### 启动集群

首先，我们先启动 HoraeMeta：

```bash
docker run -d --name horaemeta-server \
  -p 2379:2379 \
  ghcr.io/apache/horaemeta-server:nightly-20231225-ab067bf0
```

HoraeMeta 启动好了，没有问题之后，就可以把 HoraeDB 的容器创建出来：
TODO: 补充完整
