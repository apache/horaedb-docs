# WithMeta

This guide shows how to deploy a HoraeDB cluster with HoraeMeta. And with the HoraeMeta, the whole HoraeDB cluster will feature: high availability, load balancing and horizontal scalability if the underlying storage used by HoraeDB is separated service.

## Deploy HoraeMeta

### Introduce

HoraeMeta is one of the core services of HoraeDB distributed mode, it is used to manage and schedule the HoraeDB cluster. By the way, the high availability of HoraeMeta is ensured by embedding [ETCD](https://github.com/etcd-io/etcd). Also, the ETCD service is provided for HoraeDB servers to manage the distributed shard locks.

### Build

- Golang version >= 1.19.
- run `make build` in root path of [HoraeMeta](https://github.com/CeresDB/horaemeta).

### Deploy

#### Config

At present, HoraeMeta supports specifying service startup configuration in two ways: configuration file and environment variable. We provide an example of configuration file startup. For details, please refer to [config](https://github.com/CeresDB/horaemeta/tree/main/config). The configuration priority of environment variables is higher than that of configuration files. When they exist at the same time, the environment variables shall prevail.

#### Dynamic or Static

Even with the HoraeMeta, the HoraeDB cluster can be deployed with a static or a dynamic topology. With a static topology, the table distribution is static after the cluster is initialized while with the dynamic topology, the tables can migrate between different HoraeDB nodes to achieve load balance or failover. However, the dynamic topology can be enabled only if the storage used by the HoraeDB node is remote, otherwise the data may be corrupted when tables are transferred to a different HoraeDB node when the data of HoraeDB is persisted locally.

Currently, the dynamic scheduling over the cluster topology is disabled by default in HoraeMeta, and in this guide, we won't enable it because local storage is adopted here. If you want to enable the dynamic scheduling, the `TOPOLOGY_TYPE` can be set as `dynamic` (`static` by default), and after that, load balancing and failover will work. However, don't enable it if what the underlying storage is local disk.

With the static topology, the params `DEFAULT_CLUSTER_NODE_COUNT`, which denotes the number of the HoraeDB nodes in the deployed cluster and should be set to the real number of machines for HoraeDB server, matters a lot because after cluster initialization the HoraeDB nodes can't be changed any more.

#### Start HoraeMeta Instances

HoraeMeta is based on etcd to achieve high availability. In product environment, we usually deploy multiple nodes, but in local environment and testing, we can directly deploy a single node to simplify the entire deployment process.

- Standalone

```bash
docker run -d --name horaemeta-server \
  -p 2379:2379 \
  ceresdb/ceresmeta-server:latest
```

- Cluster

```bash
wget https://raw.githubusercontent.com/CeresDB/docs/main/docs/src/resources/config-ceresmeta-cluster0.toml

docker run -d --network=host --name horaemeta-server0 \
  -v $(pwd)/config-ceresmeta-cluster0.toml:/etc/ceresmeta/ceresmeta.toml \
  ceresdb/ceresmeta-server:latest

wget https://raw.githubusercontent.com/CeresDB/docs/main/docs/src/resources/config-ceresmeta-cluster1.toml

docker run -d --network=host --name horaemeta-server1 \
  -v $(pwd)/config-ceresmeta-cluster1.toml:/etc/ceresmeta/ceresmeta.toml \
  ceresdb/ceresmeta-server:latest

wget https://raw.githubusercontent.com/CeresDB/docs/main/docs/src/resources/config-ceresmeta-cluster2.toml

docker run -d --network=host --name horaemeta-server2 \
  -v $(pwd)/config-ceresmeta-cluster2.toml:/etc/ceresmeta/ceresmeta.toml \
  ceresdb/ceresmeta-server:latest
```

And if the storage used by the HoraeDB is remote and you want to enable the dynamic schedule features of the HoraeDB cluster, the `-e TOPOLOGY_TYPE=dynamic` can be added to the docker run command.

## Deploy HoraeDB

In the `NoMeta` mode, HoraeDB only requires the local disk as the underlying storage because the topology of the HoraeDB cluster is static. However, with HoraeMeta, the cluster topology can be dynamic, that is to say, HoraeDB can be configured to use a non-local storage service for the features of a distributed system: HA, load balancing, scalability and so on. And HoraeDB can be still configured to use a local storage with HoraeMeta, which certainly leads to a static cluster topology.

The relevant storage configurations include two parts:

- Object Storage
- WAL Storage

Note: If you are deploying HoraeDB over multiple nodes in a production environment, please set the environment variable for the server address as follows:

```shell
export CERESDB_SERVER_ADDR="{server_address}:8831"
```

This address is used for communication between HoraeMeta and HoraeDB, please ensure it is valid.

### Object Storage

#### Local Storage

Similarly, we can configure HoraeDB to use a local disk as the underlying storage:

```toml
[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/ceresdb"
```

#### OSS

Aliyun OSS can be also used as the underlying storage for HoraeDB, with which the data is replicated for disaster recovery. Here is a example config, and you have to replace the templates with the real OSS parameters:

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

Amazon S3 can be also used as the underlying storage for HoraeDB. Here is a example config, and you have to replace the templates with the real S3 parameters:

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

The WAL based on RocksDB is also a kind of local storage for HoraeDB, which is easy for a quick start:

```toml
[analytic.wal]
type = "RocksDB"
data_dir = "/home/admin/data/ceresdb"
```

#### OceanBase

If you have deployed a OceanBase cluster, HoraeDB can use it as the WAL storage for data disaster recovery. Here is a example config for such WAL, and you have to replace the templates with real OceanBase parameters:

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

If you have deployed a Kafka cluster, HoraeDB can also use it as the WAL storage. Here is example config for it, and you have to replace the templates with real parameters of the Kafka cluster:

```toml
[analytic.wal]
type = "Kafka"

[analytic.wal.kafka.client]
boost_broker = "{boost_broker}"
```

### Meta Client Config

Besides the storage configurations, HoraeDB must be configured to start in `WithMeta` mode and connect to the deployed HoraeMeta:

```toml
[cluster_deployment]
mode = "WithMeta"

[cluster_deployment.meta_client]
cluster_name = 'defaultCluster'
meta_addr = 'http://{HoraeMetaAddr}:2379'
lease = "10s"
timeout = "5s"

[cluster_deployment.etcd_client]
server_addrs = ['http://{HoraeMetaAddr}:2379']
```

### Complete Config of HoraeDB

With all the parts of the configurations mentioned above, a runnable complete config for HoraeDB can be made. In order to make the HoraeDB cluster runnable, we can decide to adopt RocksDB-based WAL and local-disk-based Object Storage:

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
data_dir = "/home/admin/data/ceresdb"

[analytic.storage]
mem_cache_capacity = "20GB"
# 1<<8=256
mem_cache_partition_bits = 8

[analytic.storage.object_store]
type = "Local"
data_dir = "/home/admin/data/ceresdb/"

[analytic.table_opts]
arena_block_size = 2097152
write_buffer_size = 33554432

[analytic.compaction]
schedule_channel_len = 16
schedule_interval = "30m"
max_ongoing_tasks = 8
memory_limit = "4G"
```

Let's name this config file as `config.toml`. And the example configs, in which the templates must be replaced with real parameters before use, for remote storages are also provided:

- [RocksDB WAL + OSS](../../resources/config_local_oss.toml)
- [OceanBase WAL + OSS](../../resources/config_obkv_oss.toml)
- [Kafka WAL + OSS](../../resources/config_kafka_oss.toml)

## Run HoraeDB cluster with HoraeMeta

Firstly, let's start the HoraeMeta:

```bash
docker run -d --name horaemeta-server \
  -p 2379:2379 \
  ceresdb/ceresmeta-server
```

With the started HoraeMeta cluster, let's start the HoraeDB instance:

```bash
wget https://raw.githubusercontent.com/CeresDB/docs/main/docs/src/resources/config-ceresdb-cluster0.toml

docker run -d --name horaedb-server0 \
  -p 5440:5440 \
  -p 8831:8831 \
  -p 3307:3307 \
  -v $(pwd)/config-ceresdb-cluster0.toml:/etc/ceresdb/ceresdb.toml \
  ceresdb/ceresdb-server

wget https://raw.githubusercontent.com/CeresDB/docs/main/docs/src/resources/config-ceresdb-cluster1.toml

docker run -d --name horaedb-server1 \
  -p 5441:5441 \
  -p 8832:8832 \
  -p 13307:13307 \
  -v $(pwd)/config-ceresdb-cluster1.toml:/etc/ceresdb/ceresdb.toml \
  ceresdb/ceresdb-server
```
