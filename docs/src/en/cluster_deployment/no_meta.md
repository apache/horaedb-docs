**Note: This feature is for testing use only, not recommended for production use, related features may change in the future.**

# NoMeta

This guide shows how to deploy a HoraeDB cluster without HoraeMeta, but with static, rule-based routing.

The crucial point here is that HoraeDB server provides configurable routing function on table name so what we need is just a valid config containing routing rules which will be shipped to every HoraeDB instance in the cluster.

## Target

First, let's assume that our target is to deploy a cluster consisting of two HoraeDB instances on the same machine. And a large cluster of more HoraeDB instances can be deployed according to the two-instance example.

## Prepare Config

### Basic

Suppose the basic config of HoraeDB is:

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

In order to deploy two HoraeDB instances on the same machine, the config should choose different ports to serve and data directories to store data.

Say the `HoraeDB_0`'s config is:

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

Then the `HoraeDB_1`'s config is:

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

### Schema&Shard Declaration

Then we should define the common part -- schema&shard declaration and routing rules.

Here is the config for schema&shard declaration:

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

In the config above, two schemas are declared:

- `public_0` has two shards served by `HoraeDB_0`.
- `public_1` has two shards served by both `HoraeDB_0` and `HoraeDB_1`.

### Routing Rules

Provided with schema&shard declaration, routing rules can be defined and here is an example of prefix rule:

```toml
[[cluster_deployment.route_rules.prefix_rules]]
schema = 'public_0'
prefix = 'prod_'
shard = 0
```

This rule means that all the table with `prod_` prefix belonging to `public_0` should be routed to `shard_0` of `public_0`, that is to say, `HoraeDB_0`. As for the other tables whose names are not prefixed by `prod_` will be routed by hash to both `shard_0` and `shard_1` of `public_0`.

Besides prefix rule, we can also define a hash rule:

```toml
[[cluster_deployment.route_rules.hash_rules]]
schema = 'public_1'
shards = [0, 1]
```

This rule tells HoraeDB to route `public_1`'s tables to both `shard_0` and `shard_1` of `public_1`, that is to say, `HoraeDB0` and `HoraeDB_1`. And actually this is default routing behavior if no such rule provided for schema `public_1`.

For now, we can provide the full example config for `HoraeDB_0` and `HoraeDB_1`:

```toml
[server]
bind_addr = "0.0.0.0"
http_port = 5440
grpc_port = 8831
mysql_port = 3307

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
mysql_port = 13307

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

Let's name the two different config files as `config_0.toml` and `config_1.toml` but you should know in the real environment the different HoraeDB instances can be deployed across different machines, that is to say, there is no need to choose different ports and data directories for different HoraeDB instances so that all the HoraeDB instances can share one exactly **same** config file.

## Start HoraeDBs

After the configs are prepared, what we should to do is to start HoraeDB container with the specific config.

Just run the commands below:

```shell
sudo docker run -d -t --name horaedb_0 -p 5440:5440 -p 8831:8831 -v $(pwd)/config_0.toml:/etc/ceresdb/ceresdb.toml ceresdb/ceresdb-server
sudo docker run -d -t --name horaedb_1 -p 15440:15440 -p 18831:18831 -v $(pwd)/config_1.toml:/etc/ceresdb/ceresdb.toml ceresdb/ceresdb-server
```

After the two containers are created and starting running, read and write requests can be served by the two-instances HoraeDB cluster.
