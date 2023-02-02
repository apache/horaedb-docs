# 集群运维
集群运维的接口，必须在 CeresDB 集群模式，部署了 CeresMeta 的前提下才能使用。

## 运维接口
你需要将 {CeresMetaAddr} 替换为 CeresMeta 的实际地址，如果部署在本地，可以直接替换为 `127.0.0.1`

* 查询表的路由信息
```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/route' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "schemaName":"public",
    "table":["demo"]
}'
```
* 查询节点对应的 Shard 信息
```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/getNodeShards' \
--header 'Content-Type: application/json' \
--data-raw '{
    "ClusterName":"defaultCluster"
}'
```
* 查询 Shard 对应的表信息
```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/getShardTables' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName":"defaultCluster",
    "nodeName":"127.0.0.1:8831",
    "shardIDs": [1,2]
}'
```
* 删除指定表的元数据
```
curl --location --request POST 'http://{CeresMetaAddr}:8080/api/v1/dropTable' \
--header 'Content-Type: application/json' \
--data-raw '{
    "clusterName": "defaultCluster",
    "schemaName": "public",
    "table": "demo"
}'
```
* Shard 切主
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
* Shard 分裂
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