# Go

## Installation

```
go get github.com/CeresDB/ceresdb-client-go@v1.1.0
```

You can get latest version [here](https://github.com/CeresDB/ceresdb-client-go/tags).

## How To Use

### Init CeresDB Client

```go
	client, err := ceresdb.NewClient(endpoint, ceresdb.Direct,
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

For ease of use, when using gRPC's write interface for writing, if a table does not exist, CeresDB will automatically create a table based on the first write.

Of course, you can also use `create table` statement to manage the table more finely (such as adding indexes).

**Example for creating table**

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

**Example for droping table**

```go
	dropTableSQL := `DROP TABLE demo`
	req := ceresdb.SQLQueryRequest{
		Tables: []string{"demo"},
		SQL:    dropTableSQL,
	}
	resp, err := client.SQLQuery(context.Background(), req)
```

### How To Build Write Data

```go
	points := make([]ceresdb.Point, 0, 2)
	for i := 0; i < 2; i++ {
		point, err := ceresdb.NewPointBuilder("demo").
			SetTimestamp(now).
			AddTag("name", ceresdb.NewStringValue("test_tag1")).
			AddField("value", ceresdb.NewDoubleValue(0.4242)).
			Build()
		if err != nil {
			panic(err)
		}
		points = append(points, point)
	}
```

### Write Example

```go
	req := ceresdb.WriteRequest{
		Points: points,
	}
	resp, err := client.Write(context.Background(), req)
```

### Query Example

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

## Example

You can find the complete example [here](https://github.com/CeresDB/ceresdb-client-go/blob/main/examples/read_write.go).
