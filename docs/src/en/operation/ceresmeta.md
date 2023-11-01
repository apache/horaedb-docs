# Cluster Operation

The Operations for CeresDB cluster mode, it can only be used when CeresMeta is deployed.

## Operation Interface

You need to replace 127.0.0.1 with the actual project path.

- Query table
  When tableNames is not empty, use tableNames for query.
  When tableNames is empty, ids are used for query. When querying with ids, schemaName is useless.

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

- Query the route of table

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/route' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "schemaName":"public",
    "table":["demo"]
}'
```

- Query the mapping of shard and node

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/getNodeShards' \
--header 'Content-Type: application/json' \
-d '{
    "ClusterName":"defaultCluster"
}'
```

- Query the mapping of table and shard
  If ShardIDs in the request is empty, query with all shardIDs in the cluster.

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/getShardTables' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName":"defaultCluster",
    "shardIDs": [1,2]
}'
```

- Drop table

```
curl --location --request POST 'http://127.0.0.1:8080/api/v1/dropTable' \
--header 'Content-Type: application/json' \
-d '{
    "clusterName": "defaultCluster",
    "schemaName": "public",
    "table": "demo"
}'
```

- Transfer leader shard

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

- Split shard

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

- Create cluster

```
curl --location 'http://127.0.0.1:8080/api/v1/clusters' \
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
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/clusters/{NewClusterName}' \
--header 'Content-Type: application/json' \
--data '{
    "nodeCount":28,
    "shardTotal":128,
    "enableSchedule":true,
    "topologyType":"dynamic"
}'
```

- List clusters

```
curl --location 'http://127.0.0.1:8080/api/v1/clusters'
```

- Update DeployMode

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/cluster/{ClusterName}/deployMode' \
--header 'Content-Type: application/json' \
--data '{
    "enable":true
}'
```

- Query DeployMode

```
curl --location 'http://127.0.0.1:8080/api/v1/cluster/{ClusterName}/deployMode'
```

- Update flow limiter

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/flowLimiter' \
--header 'Content-Type: application/json' \
--data '{
    "limit":1000,
    "burst":10000,
    "enable":true
}'
```

- Query information of flow limiter

```
curl --location 'http://127.0.0.1:8080/api/v1/flowLimiter'
```

- List nodes of CeresMeta cluster

```
curl --location 'http://127.0.0.1:8080/api/v1/etcd/member'
```

- Move leader of CeresMeta cluster

```
curl --location 'http://127.0.0.1:8080/api/v1/etcd/moveLeader' \
--header 'Content-Type: application/json' \
--data '{
    "memberName":"meta1"
}'
```

- Add node of CeresMeta cluster

```
curl --location --request PUT 'http://127.0.0.1:8080/api/v1/etcd/member' \
--header 'Content-Type: application/json' \
--data '{
    "memberAddrs":["http://127.0.0.1:42380"]
}'
```

- Replace node of CeresMeta cluster

```
curl --location 'http://127.0.0.1:8080/api/v1/etcd/member' \
--header 'Content-Type: application/json' \
--data '{
    "oldMemberName":"meta0",
    "newMemberAddr":["http://127.0.0.1:42380"]
}'
```
