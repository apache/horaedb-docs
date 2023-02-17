# WithMeta

This guide shows how to deploy a CeresDB cluster with CeresMeta. And with the CeresMeta, the whole CeresDB cluster will feature: high availability, load balancing and horizontal scalability if the underlying storage used by CeresDB is separated service.

## Deploy CeresMeta

### Introduce

CeresMeta is one of the core services of CeresDB distributed mode, it is used to manage and schedule the CeresDB
cluster.By the way, the high availability of CeresMeta is ensured by embedding [ETCD](https://github.com/etcd-io/etcd).

### Build

- Golang version >= 1.19.
- run `make build` in root path of [CeresMeta](https://github.com/CeresDB/ceresmeta).

### Deploy

#### Mode

CeresMeta is based on etcd to achieve high availability. In product environment, we usually deploy multiple nodes, but
in local environment and testing, we can directly deploy a single node to simplify the entire deployment process.

- Standalone

```
# ceresmeta0
mkdir /tmp/ceresmeta0
./ceresmeta --config ./config/example-standalone.toml
```

- Cluster

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

#### Config

At present, CeresMeta supports specifying service startup configuration in two ways: configuration file and environment
variable. We provide an example of configuration file startup. For details, please refer
to [config](https://github.com/CeresDB/ceresmeta/tree/main/config).
The configuration priority of environment variables is higher than that of configuration files. When they exist at the
same time, the environment variables shall prevail.

- Global Config

| name                   | description                                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| log-level              | Log output level.                                                                                              |
| log-file               | Log output file.                                                                                               |
| gprc-handle-timeout-ms | Timeout for processing grpc requests.                                                                          |
| lease-sec              | Timeout of heartbeat of CeresMeta node.                                                                        |
| data-dir               | Local data store directory.                                                                                    |
| wal-dir                | Local wal file storage directory.                                                                              |
| storage-root-path      | Root directory where data is stored in etcd.                                                                   |
| max-scan-limit         | Maximum quantity limit of single batch when scaning data.                                                      |
| id-allocator-step      | The number of ids applied for a single time when allocating ids is used to reduce the amount of write to etcd. |
| default-http-port      | Http port number of CeresMeta service node.                                                                    |

- Etcd Config

| name                      | description                                                                             |
| ------------------------- | --------------------------------------------------------------------------------------- |
| etcd-log-level            | Etcd log output level.                                                                  |
| etcd-log-file             | Etcd log output file.                                                                   |
| etcd-start-timeout-ms     | Timeout for etcd startup.                                                               |
| etcd-call-timeout-ms      | Timeout of etcd call.                                                                   |
| etcd-max-txn-ops          | Maximum number of operations in a single transaction of etcd.                           |
| initial-cluster           | Initial node list of the etcd cluster.                                                  |
| initial-cluster-state     | Initial state of the etcd cluster.                                                      |
| initial-cluster-token     | Token of etcd cluster.                                                                  |
| tick-interval-ms          | Raft tick of etcd cluster.                                                              |
| election-timeout-ms       | Timeout of etcd election.                                                               |
| quota-backend-bytes       | QuotaBackendBytes Raise alarms when backend size exceeds the given quota.               |
| auto-compaction-mode      | AutoCompactionMode is either 'periodic' or 'revision'. The default value is 'periodic'. |
| auto-compaction-retention | AutoCompactionRetention is either duration string with time unit.                       |
| max-request-bytes         | Size limit of a single request.                                                         |
| client-urls               | Current node listens to the client list of other peers.                                 |
| peer-urls                 | Current node listens to the url list of other peers.                                    |
| advertise-client-urls     | Client url of the current node.                                                         |
| advertise-peer-urls       | Peer url of the current node.                                                           |

- Cluster Config

| name                                        | description                                                                              |
| ------------------------------------------- | ---------------------------------------------------------------------------------------- |
| node-name                                   | The name of the current node cannot be the same as other nodes in the CeresMeta cluster. |
| default-cluster-name                        | The name of the default CeresDB cluster.                                                 |
| default-cluster-node-count                  | Number of nodes in the default CeresDB cluster.                                          |
| default-cluster-replication-factor          | The leader-follower ratio of the default CeresDB cluster.                                |
| default-cluster-shard-total                 | Total shards of the default CeresDB cluster.                                             |
| default-partition_table_proportion_of_nodes | Proportion of super table to cluster nodes when creating partition table.                |

The above configuration names are used in the configuration file. If they are set through environment variables, simple
conversion is required, for example: convert `node-name` to `NODE_NAME`.

## Deploy CeresDB

In the `NoMeta` mode, CeresDB only requires the local disk as the underlying storage because the topology of the CeresDB cluster is static. However, with CeresMeta, the cluster topology can be dynamic, that is to say, CeresDB can be configured to use a non-local storage service for the features of a distributed system: HA, load balancing, scalability and so on. And CeresDB can be still configured to use a local storage with CeresMeta, which certainly leads to a static cluster topology.

The relevant storage configurations include two parts:
- Object Storage
- WAL Storage

### Object Storage
#### Local Storage
Similarly, we can configure CeresDB to use a local disk as the underlying storage:
```toml
[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/ceresdb"
```

#### OSS
Aliyun OSS can be also used as the underlying storage for CeresDB, with which the data is replicated for disaster recovery. Here is a example config, and you have to replace the templates with the real OSS parameters:
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
The WAL based on RocksDB is also a kind of local storage for CeresDB, which is easy for a quick start:
```toml
[analytic.wal]
type = "RocksDB"
data_dir = "/home/admin/data/ceresdb"
```

#### OceanBase
If you have deployed a OceanBase cluster, CeresDB can use it as the WAL storage for data disaster recovery. Here is a example config for such WAL, and you have to replace the templates with real OceanBase parameters:
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
If you have deployed a Kafka cluster, CeresDB can also use it as the WAL storage. Here is example config for it, and you have to replace the templates with real parameters of the Kafka cluster:
```toml
[analytic.wal]
type = "Kafka"

[analytic.wal.kafka.client]
boost_broker = "{boost_broker}"
```

### Meta Client Config
Besides the storage configurations, CeresDB must be configured to start in `WithMeta` mode and connect to the deployed CeresMeta:
```toml
[cluster_deployment]
mode = "WithMeta"

[cluster_deployment.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://{CeresMetaAddr}:2379'
lease = "10s"
timeout = "5s"
```


### Complete Config of CeresDB
With all the parts of the configurations mentioned above, a runnable complete config for CeresDB can be made. In order to make the CeresDB cluster runnable, we can decide to adopt RocksDB-based WAL and local-disk-based Object Storage:
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

Let's name this config file as `config.toml`. And the example configs, in which the templates must be replaced with real parameters before use, for remote storages are also provided:
- [RocksDB WAL + OSS](../../resources/config_local_oss.toml)
- [OceanBase WAL + OSS](../../resources/config_obkv_oss.toml)
- [Kafka WAL + OSS](../../resources/config_kafka_oss.toml)

## Run CeresDB cluster with CeresMeta
Firstly, let's start the CeresMeta:
```bash
(TODO)
```

With the started CeresMeta cluster, let's start the CeresDB instance:
```bash
docker run -d --name ceresdb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  -v /etc/ceresdb/ceresdb.toml:./config.toml \
  ceresdb/ceresdb-server
```
