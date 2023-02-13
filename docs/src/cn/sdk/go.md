# Go

## 介绍

CeresDBClient 是 CeresDB 的高性能 Golang 版客户端。

## 安装

```
go get github.com/CeresDB/ceresdb-client-go/ceresdb
```

## 如何使用

### 初始化客户端

```go
	client, err := ceresdb.NewClient(endpoint, types.Direct,
		ceresdb.WithDefaultDatabase("public"), // Client所使用的database
	)
```

注意: CeresDB 当前仅支持预创建的 `public` database , 未来会支持多个 database。

### 管理表

CeresDB 使用 SQL 来管理表格，比如创建表、删除表或者新增列等等，这和你在使用 SQL 管理其他的数据库时没有太大的区别。

CeresDB 是一个 Schema-less 的时序数据引擎，你可以不必创建 schema 就立刻写入数据（CeresDB 会根据你的第一次写入帮你创建一个默认的 schema）。
当然你也可以自行创建一个 schema 来更精细化的管理的表（比如索引等）。
创建表格的样例：

```go
	createTableSQL := `CREATE TABLE IF NOT EXISTS demo (
	name string TAG,
	value double,
	t timestamp NOT NULL,
	TIMESTAMP KEY(t)) ENGINE=Analytic with (enable_ttl=false)`

	req := types.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    createTableSQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
```

删除表格的样例：

```go
	dropTableSQL := `DROP TABLE demo`
	req := types.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    dropTableSQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
```

### 构建写入数据

我们提供两种构建数据的方式：
第一种支持用户使用 `PointBuilder` 每次单独构建一个 `Point`。

```go
	points := make([]types.Point, 0, 2)
	for i := 0; i < 2; i++ {
		point, err := ceresdb.NewPointBuilder("demo").
			SetTimestamp(utils.CurrentMS()).
			AddTag("name", types.NewStringValue("test_tag1")).
			AddField("value", types.NewDoubleValue(0.4242)).
			Build()
		if err != nil {
			panic(err)
		}
		points = append(points, point)
	}
```

第二种，用户也可以使用 `TablePointsBuilder` 直接构建同一张表下的多个 `Point`。

```go
    points, err := ceresdb.NewTablePointsBuilder("demo").
        AddPoint().
			SetTimestamp(utils.CurrentMS()).
			AddTag("name", types.NewStringValue("test_tag1")).
			AddField("value", types.NewDoubleValue(0.4242)).
			BuildAndContinue().
        AddPoint().
			SetTimestamp(utils.CurrentMS()).
			AddTag("name", types.NewStringValue("test_tag2")).
			AddField("value", types.NewDoubleValue(0.3235)).
			BuildAndContinue().
        Build()
```

### 写入数据

```go
	req := types.WriteRequest{
		Points: points,
	}
	resp, err := client.Write(context.Background(), req)
```

### 查询数据

```go
	querySQL := `SELECT * FROM demo`
	req := types.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    querySQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
	if err != nil {
        panic(err)
	}
	fmt.Printf("query table success, rows:%+v\n", resp.Rows)
```
