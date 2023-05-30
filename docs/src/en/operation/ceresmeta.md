# Cluster Operation

The Operations for CeresDB cluster mode, it can only be used when CeresMeta is deployed.

## Operation Interface

You need to replace {CeresMetaAddr} with the actual project path, if you are start CeresMeta in localhost, You can directly replace it with `127.0.0.1`.

- Query the route of table

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/route' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "schemaName":"public",
    "table":["demo"]
}'
```

- Query the mapping of shard and node

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/getNodeShards' \
--header 'Content-Type: application/json' \
--data-raw '{
    "ClusterName":"defaultCluster"
}'
```

- Query the mapping of table and shard

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/getShardTables' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "nodeName":"127.0.0.1:8831",
    "shardIDs": [1,2]
}'
```

- Drop table

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/dropTable' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName": "defaultCluster",
    "schemaName": "public",
    "table": "demo"
}'
```

- Transfer leader shard

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/transferLeader' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "shardID": 1,
    "oldLeaderNodeName": "127.0.0.1:8831",
    "newLeaderNodeName": "127.0.0.1:18831"
}'
```

- Split shard

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/split' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName" : "defaultCluster",
    "schemaName" :"public",
    "nodeName" :"127.0.0.1:8831",
    "shardID" : 0,
    "splitTables":["demo"]
}'
```

- Create cluster

```
curl --location 'http://{CeresMetaAddr}:8080/api/v1/clusters' \
--header 'Content-Type: application/json' \
--data '{
    "name":"testCluster",
    "nodeCount":3,
    "shardTotal":9,
    "enableScheduler":true,
    "topologyType":"static"
}'
```

- Update cluster

```
curl --location --request PUT 'http://{CeresMetaAddr}:8080/api/v1/clusters/{NewClusterName}' \
--header 'Content-Type: application/json' \
--data '{
    "nodeCount":28,
    "shardTotal":128,
    "enableSchedule":true,
    "topologyType":"dynamic"
}'
```

- list clusters

```
curl --location 'http://{CeresMetaAddr}:8080/api/v1/clusters'
```

- Update flow limiter

```
curl --location --request PUT 'http://{CeresMetaAddr}:8080/api/v1/flowLimiter' \
--header 'Content-Type: application/json' \
--data '{
    "allowedTps":1000,
    "burstTps":10000,
    "enable":true
}'
```
