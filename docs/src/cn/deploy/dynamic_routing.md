# 动态路由部署

本章介绍基于 CeresMeta 的动态路由部署方式。

## 部署 CeresMeta

CeresMeta 是 CeresDB 分布式模式的核心服务之一，用于管理 CeresDB 节点的调度，为 CeresDB 集群提供高可用、负载均衡、集群管控等能力。
CeresMeta 本身通过嵌入式的 etcd 保障高可用。

### 编译打包
- 安装 Golang，版本号 >= 1.19。
- 在项目根目录下使用 `make build`进行编译打包。
### 部署方式
#### 部署模式
CeresMeta 基于 etcd 实现高可用，在线上环境我们一般部署多个节点，但是在本地环境和测试时，可以直接部署单个节点来简化整个部署流程。
* 单节点
```
# ceresmeta0
mkdir /tmp/ceresmeta0
./ceresmeta --config ./config/example-standalone.toml
```
* 多节点
```
# Create directories.
mkdir /tmp/ceresmeta0
mkdir /tmp/ceresmeta1
mkdir /tmp/ceresmeta2

# Ceresmeta0
./ceresmeta --config ./config/exampl-cluster0.toml

# Ceresmeta1
./ceresmeta --config ./config/exampl-cluster1.toml

# Ceresmeta2
./ceresmeta --config ./config/exampl-cluster2.toml
```
#### 启动配置
目前 CeresMeta 支持以配置文件和环境变量两种方式来指定服务启动配置。我们提供了配置文件方式启动的示例，具体可以参考 [config](https://github.com/CeresDB/ceresmeta/tree/main/config)。
环境变量的配置优先级高于配置文件，当同时存在时，以环境变量为准。
* 全局配置

| name | description |
| --- | --- |
| log-level | 日志输出级别 |
| log-file | 日志输出文件 |
| gprc-handle-timeout-ms | 处理 grpc 请求的超时时间 |
| lease-sec | CeresMeta 节点心跳的超时时间 |
| data-dir | 本地数据存储目录 |
| wal-dir | 本地 wal 文件存储目录 |
| storage-root-path | 数据存储在 etcd 中的根目录 |
| max-scan-limit | 读取数据时单批次最大数量限制 |
| id-allocator-step | 分配 id 时单次申请的总 id 数，用于减小对 etcd 的写入量 |
| default-http-port | CeresMeta 服务节点的 http 端口号 |

* etcd 相关的配置

| name | description |
| --- | --- |
| etcd-log-level | etcd 日志输出级别 |
| etcd-log-file | etcd 日志输出文件 |
| etcd-start-timeout-ms | etcd 启动的超时时间 |
| etcd-call-timeout-ms | etcd 调用的超时时间 |
| etcd-max-txn-ops | etcd 单次事务中的操作数量最大限制 |
| initial-cluster | etcd 集群的初始节点列表 |
| initial-cluster-state | etcd 集群的初始状态 |
| initial-cluster-token | etcd 集群的 token |
| tick-interval-ms | etcd 的 raft tick |
| election-timeout-ms | etcd 选举的超时时间 |
| quota-backend-bytes | QuotaBackendBytes Raise alarms when backend size exceeds the given quota. |
| auto-compaction-mode | AutoCompactionMode is either 'periodic' or 'revision'. The default value is 'periodic'. |
| auto-compaction-retention | AutoCompactionRetention is either duration string with time unit. |
| max-request-bytes | 单次请求的大小限制 |
| client-urls | 当前节点监听其它 peer 的 client list |
| peer-urls | 当前节点监听其它 peer 的 url list |
| advertise-client-urls | 当前节点的 client url |
| advertise-peer-urls | 当前节点的 peer url |

* 集群相关配置

| name | description |
| --- | --- |
| node-name | 当前节点的名称，不能与 CeresMeta 集群内的其它节点重复 |
| default-cluster-name | 默认 CeresDB 集群的名称 |
| default-cluster-node-count | 默认 CeresDB 集群的节点数量 |
| default-cluster-replication-factor | 默认 CeresDB 集群的主从比例 |
| default-cluster-shard-total | 默认 CeresDB 集群的总 Shard 数 |
| default-partition_table_proportion_of_nodes | 创建分区表时超级表占集群节点数的比例 |


上述的配置名均为配置文件中的使用方式，如果需要以环境变量的方式使用，需要做一个简单的修改，例如：将 `node-name` 转换为 `NODE_NAME`。

## 部署 CeresDB 实例

### 配置文件

#### 持久化存储配置

数据存储可以选择如下两种：

* 本地存储

本地存储配置参数可以参考[静态路由部署](./static_routing.md)，注意本地存储在机器出现故障的时候，数据会出现丢失。
  
* OSS 存储

OSS 是阿里云提供的高可用的对象存储，在这种方式下即使CeresDB机器出现宕机等情况，数据也是完整的。

```
[analytic.storage.object_store]
type = "Aliyun"
key_id = "key_id"
key_secret = "key_secret"
endpoint = "endpoint"
bucket = "bucket"
prefix = "data_dir"
```

#### WAL 配置

WAL 配置有三种配置方式:

* 本地 RocksDB
  
使用本地 RocksDB 作为 WAL 的配置参数可以参考[静态路由部署](./static_routing.md)，同使用本地存储作为数据持久化的方式类似，在机器宕机时最近写入的数据会丢失。

* OceanBase

OceanBase 是一种分布式高可用的存储系统，基于此实现的 WAL具备高可用可扩展的能力。

```
[analytic.wal_storage]
type = "Obkv"

[analytic.wal_storage.wal]
ttl = "365d"

[analytic.wal_storage.manifest]
ttl = "365d"

[analytic.wal_storage.obkv]
full_user_name = "xxx"
param_url = "xxxx"
password = "xxx"

[analytic.wal_storage.obkv.client]
sys_user_name = "xxx"
sys_password = "xxx"

```

* Kafka

TODO

#### Meta 客户端配置

```
[cluster.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://{CeresMetaAddr}:2379'
lease = "10s"
timeout = "5s"
```

#### 完整配置

* [本地 RocksDB WAL + OSS](../../resources/config_local_oss.toml)
* [OceanBase WAL + OSS](../../resources/config_obkv_oss.toml)
* [Kafka WAL + OSS](./todo)

### 启动实例

根据实际情况配置完成后便可以启动 CeresDB 集群了。

```bash
# Update address of CeresMeta in CeresDB config.
docker run -d --name ceresdb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  -v {project_path}/docs/example-cluster-0.toml:/etc/ceresdb/ceresdb.toml \
  ceresdb/ceresdb-server:v0.3.1
  
docker run -d --name ceresdb-server2 \
  -p 8832:8832 \
  -p 13307:13307 \
  -p 5441:5441 \
  -v {project_path}/docs/example-cluster-1.toml:/etc/ceresdb/ceresdb.toml \
  ceresdb/ceresdb-server:v0.3.1
```