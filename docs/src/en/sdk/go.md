# Go

## Introduction

ceresdb.Client is a Golang client for CeresDB.

## Installation

```
go get github.com/CeresDB/ceresdb-client-go/ceresdb
```

## How To Use

### Init CeresDB Client

```go
	client, err := ceresdb.NewClient(endpoint, types.Direct,
		ceresdb.WithDefaultDatabase("public"),
	)
```

| option name       | description                                                                                                |
| ----------------- | ---------------------------------------------------------------------------------------------------------- |
| defaultDatabase   | using database, database can be overwritten by ReqContext in single `Write` or `SQLRequest`                |
| RPCMaxRecvMsgSize | configration for grpc `MaxCallRecvMsgSize`, default 1024 _ 1024 _ 1024                                     |
| RouteMaxCacheSize | If the maximum number of router cache size, router client whill evict oldest if exceeded, default is 10000 |

Notice:

- CeresDB currently only supports the default database `public` now, multiple databases will be supported in the future

### Manage Table

CeresDB uses SQL to manage tables, such as creating tables, deleting tables, or adding columns, etc., which is not much different from when you use SQL to manage other databases.

CeresDB is a Schema-less time-series database, so creating table schema ahead of data ingestion is not required (CeresDB will create a default schema according to the very first data you write into it). Of course, you can also manually create a schema for fine grained management purposes (eg. managing index).

**Example for creating table**

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

**Example for droping table**

```go
	dropTableSQL := `DROP TABLE demo`
	req := types.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    dropTableSQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
```

### How To Build Write Data

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

### Write Example

```go
	req := types.WriteRequest{
		Points: points,
	}
	resp, err := client.Write(context.Background(), req)
```

### Query Example

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
