# 集群运维

集群运维接口的使用前提是，HoraeDB 部署为使用 HoraeMeta 的集群模式。

## 运维接口

注意： 如下接口在实际使用时需要将 127.0.0.1 替换为 HoraeMeta 的真实地址。

- 查询表元信息
  当 tableNames 不为空的时候，使用 tableNames 进行查询。
  当 tableNames 为空的时候，使用 ids 进行查询。使用 ids 查询的时候，schemaName 不生效。

```
curl --location 'http://127.0.0.1:8080/api/v1/table/query' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "schemaName":"public",
    "names":["demo1", "__demo1_0"],
}'

curl --location 'http://127.0.0.1:8080/api/v1/table/query' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "ids":[0, 1]
}'
```

- 查询表的路由信息

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/route' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "schemaName":"public",
    "table":["demo"]
}'
```

- 查询节点对应的 Shard 信息

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/getNodeShards' \
--header 'Content-Type: application/json' \
-d '{
    "ClusterName":"defaultCluster"
}'
```

- 查询 Shard 对应的表信息
  如果 shardIDs 为空时，查询所有 shard 上表信息。

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/getShardTables' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "shardIDs": [1,2]
}'
```

- 删除指定表的元数据

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/dropTable' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName": "defaultCluster",
    "schemaName": "public",
    "table": "demo"
}'
```

- Shard 切主

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/transferLeader' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "shardID": 1,
    "oldLeaderNodeName": "127.0.0.1:8831",
    "newLeaderNodeName": "127.0.0.1:18831"
}'
```

- Shard 分裂

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/split' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName" : "defaultCluster",
    "schemaName" :"public",
    "nodeName" :"127.0.0.1:8831",
    "shardID" : 0,
    "splitTables":["demo"]
}'
```

- 创建 HoraeDB 集群

```
curl --location 'http://127.0.0.1:8080/api/v1/clusters' \
--header 'Content-Type: application/json' \
--data '{
    "name":"testCluster",
    "nodeCount":3,
    "ShardTotal":9,
    "enableScheduler":true,
    "topologyType":"static"
}'
```

- 更新 HoraeDB 集群

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/clusters/{NewClusterName}' \
--header 'Content-Type: application/json' \
--data '{
    "nodeCount":28,
    "shardTotal":128,
    "enableSchedule":true,
    "topologyType":"dynamic"
}'
```

- 列出 HoraeDB 集群

```
curl --location 'http://127.0.0.1:8080/api/v1/clusters'
```

- 修改 enableSchedule

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/clusters/{ClusterName}/enableSchedule' \
--header 'Content-Type: application/json' \
--data '{
    "enable":true
}'
```

- 查询 enableSchedule

```
curl --location 'http://127.0.0.1:8080/api/v1/clusters/{ClusterName}/enableSchedule'
```

- 更新限流器

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/flowLimiter' \
--header 'Content-Type: application/json' \
--data '{
    "limit":1000,
    "burst":10000,
    "enable":true
}'
```

- 查询限流器信息

```
curl --location 'http://127.0.0.1:8080/api/v1/flowLimiter'
```

- HoraeMeta 列出节点

```
curl --location 'http://127.0.0.1:8080/api/v1/etcd/member'
```

- HoraeMeta 节点切主

```
curl --location 'http://127.0.0.1:8080/api/v1/etcd/moveLeader' \
--header 'Content-Type: application/json' \
--data '{
    "memberName":"meta1"
}'
```

- HoraeMeta 节点扩容

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/etcd/member' \
--header 'Content-Type: application/json' \
--data '{
    "memberAddrs":["http://127.0.0.1:42380"]
}'
```

- HoraeMeta 替换节点

```
curl --location 'http://127.0.0.1:8080/api/v1/etcd/member' \
--header 'Content-Type: application/json' \
--data '{
    "oldMemberName":"meta0",
    "newMemberAddr":["http://127.0.0.1:42380"]
}'
```
