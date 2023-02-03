# Dynamic Routing

This guide shows how to deploy a CeresDB cluster with CeresMeta.

## Deploy CeresMeta

### Introduce

CeresMeta is one of the core services of CeresDB distributed mode, it is used to manage and schedule the CeresDB
cluster, CeresMeta itself ensures its high availability through embed etcd.

### Build

- Golang version >= 1.19.
- run `make build`in root path of this [project](https://github.com/CeresDB/ceresmeta).

### Deploy

#### Mode

CeresMeta is based on etcd to achieve high availability. In product environment, we usually deploy multiple nodes, but
in local environment and testing, we can directly deploy a single node to simplify the entire deployment process.

* Standalone

```
# ceresmeta0
mkdir /tmp/ceresmeta0
./ceresmeta --config ./config/example-standalone.toml
```

* Cluster

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

#### Config

At present, CeresMeta supports specifying service startup configuration in two ways: configuration file and environment
variable. We provide an example of configuration file startup. For details, please refer
to [config](https://github.com/CeresDB/ceresmeta/tree/main/config).
The configuration priority of environment variables is higher than that of configuration files. When they exist at the
same time, the environment variables shall prevail.

* Global Config

| name | description |
| --- | --- |
| log-level | Log output level. |
| log-file | Log output file. |
| gprc-handle-timeout-ms | Timeout for processing grpc requests. |
| lease-sec | Timeout of heartbeat of CeresMeta node. |
| data-dir | Local data store directory. |
| wal-dir | Local wal file storage directory. |
| storage-root-path | Root directory where data is stored in etcd. |
| max-scan-limit | Maximum quantity limit of single batch when scaning data. |
| id-allocator-step | The number of ids applied for a single time when allocating ids is used to reduce the amount of write to etcd. |
| default-http-port | Http port number of CeresMeta service node. |

* Etcd Config

| name | description |
| --- | --- |
| etcd-log-level | Etcd log output level. |
| etcd-log-file | Etcd log output file. |
| etcd-start-timeout-ms | Timeout for etcd startup. |
| etcd-call-timeout-ms | Timeout of etcd call. |
| etcd-max-txn-ops | Maximum number of operations in a single transaction of etcd. |
| initial-cluster | Initial node list of the etcd cluster. |
| initial-cluster-state | Initial state of the etcd cluster. |
| initial-cluster-token | Token of etcd cluster. |
| tick-interval-ms | Raft tick of etcd cluster. |
| election-timeout-ms | Timeout of etcd election. |
| quota-backend-bytes | QuotaBackendBytes Raise alarms when backend size exceeds the given quota. |
| auto-compaction-mode | AutoCompactionMode is either 'periodic' or 'revision'. The default value is 'periodic'. |
| auto-compaction-retention | AutoCompactionRetention is either duration string with time unit. |
| max-request-bytes | Size limit of a single request. |
| client-urls | Current node listens to the client list of other peers. |
| peer-urls | Current node listens to the url list of other peers. |
| advertise-client-urls | Client url of the current node. |
| advertise-peer-urls | Peer url of the current node. |

* Cluster Config

| name | description |
| --- | --- |
| node-name | The name of the current node cannot be the same as other nodes in the CeresMeta cluster. |
| default-cluster-name | The name of the default CeresDB cluster. |
| default-cluster-node-count | Number of nodes in the default CeresDB cluster. |
| default-cluster-replication-factor | The leader-follower ratio of the default CeresDB cluster. |
| default-cluster-shard-total | Total shards of the default CeresDB cluster. |
| default-partition_table_proportion_of_nodes | Proportion of super table to cluster nodes when creating partition table. |

The above configuration names are used in the configuration file. If they are set through environment variables, simple
conversion is required, for example: convert `node-name` to `NODE_NAME`.

## Deploy CeresDB

### Configuration

#### Persistence Configuration

Two types of storage are supported in CeresDB:

* Local Storage

Configuration parameters of local storage refer to [Static Routing](./static_routing.md),
notice that data is lost when server crash in this mode.

* OSS 

Aliyun OSS (Object Storage Service) is a cloud storage service provided by Alibaba Cloud.
The data remains complete even if the CeresDB machine crashes.

```
[analytic.storage.object_store]
type = "Aliyun"
key_id = "key_id"
key_secret = "key_secret"
endpoint = "endpoint"
bucket = "bucket"
prefix = "data_dir"
```

#### WAL Configuration
 
Three types of wal are supported in CeresDB:

* RocksDB

Configuration parameters of wal implemented base on RocksDB refer to [Static Routing](./static_routing.md),
Similar to using local storage for data persistence, recently written data is lost when server crash.

* OceanBaseKV

OceanBaseKV is a distributed, highly available Key-Value storage system provided by OceanBase, 
and the WAL implemented based on which has high availability and scalability.

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

#### Meta Client Configuration

```
[cluster.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://{CeresMetaAddr}:2379'
lease = "10s"
timeout = "5s"
```

#### Complete Configuration

* [RocksDB WAL + OSS](./config_local_oss.toml)
* [OBKV WAL + OSS](./config_obkv_oss.toml)
* [Kafka WAL + OSS](./todo)

### Start CeresDB Instances

The CeresDB cluster can be started once the configuration is complete.
You need to replace {project_path} with the actual project path.

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
