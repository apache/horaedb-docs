# WithMeta 模式

本文展示如何部署一个由 CeresMeta 控制的 CeresDB 集群，有了 CeresMeta 提供的服务，如果 CeresDB 使用存储不在本地的话，就可以实现很多分布式特性，比如水平扩容、负载均衡、服务高可用等。

## 部署 CeresMeta

CeresMeta 是 CeresDB 分布式模式的核心服务之一，用于管理 CeresDB 节点的调度，为 CeresDB 集群提供高可用、负载均衡、集群管控等能力。
CeresMeta 本身通过嵌入式的 [ETCD](https://github.com/etcd-io/etcd) 保障高可用。

### 编译打包

- 安装 Golang，版本号 >= 1.19。
- 在项目根目录下使用 `make build` 进行编译打包。

### 部署方式

#### 部署模式

CeresMeta 基于 etcd 实现高可用，在线上环境我们一般部署多个节点，但是在本地环境和测试时，可以直接部署单个节点来简化整个部署流程。

- 单节点

```
# ceresmeta0
mkdir /tmp/ceresmeta0
./ceresmeta --config ./config/example-standalone.toml
```

- 多节点

```
# Create directories.
mkdir /tmp/ceresmeta0
mkdir /tmp/ceresmeta1
mkdir /tmp/ceresmeta2

# Ceresmeta0
./ceresmeta --config ./config/example-cluster0.toml

# Ceresmeta1
./ceresmeta --config ./config/example-cluster1.toml

# Ceresmeta2
./ceresmeta --config ./config/example-cluster2.toml
```

#### 启动配置

目前 CeresMeta 支持以配置文件和环境变量两种方式来指定服务启动配置。我们提供了配置文件方式启动的示例，具体可以参考 [config](https://github.com/CeresDB/ceresmeta/tree/main/config)。
环境变量的配置优先级高于配置文件，当同时存在时，以环境变量为准。

- 全局配置

| name                   | description                                            |
| ---------------------- | ------------------------------------------------------ |
| log-level              | 日志输出级别                                           |
| log-file               | 日志输出文件                                           |
| gprc-handle-timeout-ms | 处理 grpc 请求的超时时间                               |
| lease-sec              | CeresMeta 节点心跳的超时时间                           |
| data-dir               | 本地数据存储目录                                       |
| wal-dir                | 本地 wal 文件存储目录                                  |
| storage-root-path      | 数据存储在 etcd 中的根目录                             |
| max-scan-limit         | 读取数据时单批次最大数量限制                           |
| id-allocator-step      | 分配 id 时单次申请的总 id 数，用于减小对 etcd 的写入量 |
| default-http-port      | CeresMeta 服务节点的 http 端口号                       |

- etcd 相关的配置

| name                      | description                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------- |
| etcd-log-level            | etcd 日志输出级别                                                                       |
| etcd-log-file             | etcd 日志输出文件                                                                       |
| etcd-start-timeout-ms     | etcd 启动的超时时间                                                                     |
| etcd-call-timeout-ms      | etcd 调用的超时时间                                                                     |
| etcd-max-txn-ops          | etcd 单次事务中的操作数量最大限制                                                       |
| initial-cluster           | etcd 集群的初始节点列表                                                                 |
| initial-cluster-state     | etcd 集群的初始状态                                                                     |
| initial-cluster-token     | etcd 集群的 token                                                                       |
| tick-interval-ms          | etcd 的 raft tick                                                                       |
| election-timeout-ms       | etcd 选举的超时时间                                                                     |
| quota-backend-bytes       | QuotaBackendBytes Raise alarms when backend size exceeds the given quota.               |
| auto-compaction-mode      | AutoCompactionMode is either 'periodic' or 'revision'. The default value is 'periodic'. |
| auto-compaction-retention | AutoCompactionRetention is either duration string with time unit.                       |
| max-request-bytes         | 单次请求的大小限制                                                                      |
| client-urls               | 当前节点监听其它 peer 的 client list                                                    |
| peer-urls                 | 当前节点监听其它 peer 的 url list                                                       |
| advertise-client-urls     | 当前节点的 client url                                                                   |
| advertise-peer-urls       | 当前节点的 peer url                                                                     |

- 集群相关配置

| name                                        | description                                           |
| ------------------------------------------- | ----------------------------------------------------- |
| node-name                                   | 当前节点的名称，不能与 CeresMeta 集群内的其它节点重复 |
| default-cluster-name                        | 默认 CeresDB 集群的名称                               |
| default-cluster-node-count                  | 默认 CeresDB 集群的节点数量                           |
| default-cluster-replication-factor          | 默认 CeresDB 集群的主从比例                           |
| default-cluster-shard-total                 | 默认 CeresDB 集群的总 Shard 数                        |
| default-partition_table_proportion_of_nodes | 创建分区表时超级表占集群节点数的比例                  |

上述的配置名均为配置文件中的使用方式，如果需要以环境变量的方式使用，需要做一个简单的修改，例如：将 `node-name` 转换为 `NODE_NAME`。

## 部署 CeresDB

在 `NoMeta` 模式中，由于 CeresDB 集群拓扑是静态的，因此 CeresDB 只需要一个本地存储来作为底层的存储层即可。但是在 `WithMeta` 模式中，集群的拓扑是可以变化的，因此如果 CeresDB 的底层存储使用一个独立的存储服务的话，CeresDB 集群就可以获得一个分布式系统的特性：高可用、负载均衡、水平扩展等特性。当然，CeresDB 仍然可以使用本地存储，这样的话，集群的拓扑仍然是静态的。

存储相关的配置主要包括两个部分：

- Object Storage
- WAL Storage

### Object Storage

#### 本地存储

类似 `NoMeta` 模式，我们仍然可以为 CeresDB 配置一个本地磁盘作为底层存储：

```toml
[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/ceresdb"
```

#### OSS

Aliyun OSS 也可以作为 CeresDB 的底层存储，以此提供数据容灾能力。下面是一个配置示例，示例中的模版变量需要被替换成实际的 OSS 参数才可以真正的使用：

```toml
[analytic.storage.object_store]
type = "Aliyun"
key_id = "{key_id}"
key_secret = "{key_secret}"
endpoint = "{endpoint}"
bucket = "{bucket}"
prefix = "{data_dir}"
```

### WAL Storage

#### RocksDB

基于 RocksDB 的 WAL 也是一种本地存储，无第三方依赖，可以很方便的快速部署：

```toml
[analytic.wal]
type = "RocksDB"
data_dir = "/home/admin/data/ceresdb"
```

#### OceanBase

如果已经有了一个部署好的 OceanBase 集群的话，CeresDB 可以使用它作为 WAL Storage 来保证其数据的容灾性。下面是一个配置示例，示例中的模版变量需要被替换成实际的 OceanBase 集群的参数才可以真正的使用：

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

如果你已经部署了一个 Kafka 集群，CeresDB 可以也可以使用它作为 WAL Storage。下面是一个配置示例，示例中的模版变量需要被替换成实际的 Kafka 集群的参数才可以真正的使用：

```toml
[analytic.wal]
type = "Kafka"

[analytic.wal.kafka.client]
boost_broker = "{boost_broker}"
```

#### Meta 客户端配置

除了存储层的配置外，CeresDB 需要 CeresMeta 相关的配置来与 CeresMeta 集群进行通信：

```
[cluster.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://{CeresMetaAddr}:2379'
lease = "10s"
timeout = "5s"
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
data_dir = "/home/admin/data/ceresdb"

[analytic.storage]
mem_cache_capacity = "20GB"
# 1<<8=256
mem_cache_partition_bits = 8
disk_cache_dir = "/home/admin/data/ceresdb/"
disk_cache_capacity = '2G'
disk_cache_page_size = '4M'

[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/ceresdb/"

[analytic.table_opts]
arena_block_size = 2097152
write_buffer_size = 33554432

[analytic.compaction_config]
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

首先，我们先启动 CeresMeta：

```bash
(TODO)
```

CeresMeta 启动好了，没有问题之后，就可以把 CeresDB 的容器创建出来：

```bash
docker run -d --name ceresdb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  -v /etc/ceresdb/ceresdb.toml:./config.toml \
  ceresdb/ceresdb-server
```
