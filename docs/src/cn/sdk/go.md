# Go

## 安装

```
go get github.com/CeresDB/ceresdb-client-go
```

## 如何使用

### 初始化客户端

```go
	client, err := ceresdb.NewClient(endpoint, ceresdb.Direct,
		ceresdb.WithDefaultDatabase("public"), // Client所使用的database
	)
```

| 参数名称          | 说明                                                                                          |
| ----------------- | --------------------------------------------------------------------------------------------- |
| defaultDatabase   | 所使用的 database，可以被单个 `Write` 或者 `SQLRequest` 请求中的 database 覆盖                |
| RPCMaxRecvMsgSize | grpc `MaxCallRecvMsgSize` 配置, 默认是 1024 _ 1024 _ 1024                                     |
| RouteMaxCacheSize | 如果 router 客户端中的 路由缓存超过了这个值，将会淘汰最不活跃的直至降低这个阈值, 默认是 10000 |

注意： CeresDB 当前仅支持预创建的 `public` database , 未来会支持多个 database。

### 管理表

CeresDB 使用 SQL 来管理表格，比如创建表、删除表或者新增列等等，这和你在使用 SQL 管理其他的数据库时没有太大的区别。

为了方便使用，在使用 gRPC 的 write 接口进行写入时，如果某个表不存在，CeresDB 会根据第一次的写入自动创建一个表。

当然你也可以通过 `create table` 语句来更精细化的管理的表（比如添加索引等）。

**创建表的样例**

```go
	createTableSQL := `
		CREATE TABLE IF NOT EXISTS demo (
			name string TAG,
			value double,
			t timestamp NOT NULL,
			TIMESTAMP KEY(t)
		) ENGINE=Analytic with (enable_ttl=false)`

	req := ceresdb.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    createTableSQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
```

**删除表的样例**

```go
	dropTableSQL := `DROP TABLE demo`
	req := ceresdb.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    dropTableSQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
```

### 构建写入数据

```go
	points := make([]ceresdb.Point, 0, 2)
	for i := 0; i < 2; i++ {
		point, err := ceresdb.NewPointBuilder("demo").
			SetTimestamp(now)).
			AddTag("name", ceresdb.NewStringValue("test_tag1")).
			AddField("value", ceresdb.NewDoubleValue(0.4242)).
			Build()
		if err != nil {
			panic(err)
		}
		points = append(points, point)
	}
```

### 写入数据

```go
	req := ceresdb.WriteRequest{
		Points: points,
	}
	resp, err := client.Write(context.Background(), req)
```

### 查询数据

```go
	querySQL := `SELECT * FROM demo`
	req := ceresdb.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    querySQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
	if err != nil {
        panic(err)
	}
	fmt.Printf("query table success, rows:%+v\n", resp.Rows)
```

## 示例

你可以在[这里](https://github.com/CeresDB/ceresdb-client-go/blob/main/examples/read_write.go)找到完整的示例。
