# 集群运维

集群运维接口的使用前提是，CeresDB 部署为使用 CeresMeta 的集群模式。

## 运维接口

注意： 如下接口在实际使用时需要将 {CeresMetaAddr} 替换为 CeresMeta 的真实地址，如果部署在本地，可以直接替换为 `127.0.0.1`

- 查询表的路由信息

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/route' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "schemaName":"public",
    "table":["demo"]
}'
```

- 查询节点对应的 Shard 信息

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/getNodeShards' \
--header 'Content-Type: application/json' \
--data-raw '{
    "ClusterName":"defaultCluster"
}'
```

- 查询 Shard 对应的表信息

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/getShardTables' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "nodeName":"127.0.0.1:8831",
    "shardIDs": [1,2]
}'
```

- 删除指定表的元数据

```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/dropTable' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName": "defaultCluster",
    "schemaName": "public",
    "table": "demo"
}'
```

- Shard 切主

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

- Shard 分裂

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

- 创建 CeresDB 集群

```
curl --location 'http://{CeresMetaAddr}:8080/api/v1/clusters' \
--header 'Content-Type: application/json' \
--data '{
    "name":"testCluster",
    "nodeCount":3,
    "ShardTotal":9,
    "enableScheduler":true,
    "topologyType":"static"
}'
```

- 更新 CeresDB 集群

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

- 列出 CeresDB 集群

```
curl --location 'http://{CeresMetaAddr}:8080/api/v1/clusters'
```

- 更新限流器

```
curl --location --request PUT 'http://{CeresMetaAddr}:8080/api/v1/flowLimiter' \
--header 'Content-Type: application/json' \
--data '{
    "limit":1000,
    "burst":10000,
    "enable":true
}'
```

- 查询限流器信息

```
curl --location 'http://{CeresMetaAddr}:8080/api/v1/flowLimiter'
```