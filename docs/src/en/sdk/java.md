# Java

## Introduction

CeresDB Client is a high-performance Java client for CeresDB.

## Requirements

- Java 8 or later is required for compilation

## Dependency

```xml
<dependency>
  <groupId>io.ceresdb</groupId>
  <artifactId>ceresdb-all</artifactId>
  <version>1.0.0</version>
</dependency>
```

## Init CeresDB Client

```java
final CeresDBOptions opts = CeresDBOptions.newBuilder("127.0.0.1", 8831, DIRECT) // CeresDB default grpc port 8831，use DIRECT RouteMode
        .database("public") // use database for client, can be overridden by the RequestContext in request
        // maximum retry times when write fails
        // (only some error codes will be retried, such as the routing table failure)
        .writeMaxRetries(1)
        // maximum retry times when read fails
        // (only some error codes will be retried, such as the routing table failure)
        .readMaxRetries(1).build();

final CeresDBClient client = new CeresDBClient();
if (!client.init(opts)) {
    throw new IllegalStateException("Fail to start CeresDBClient");
}
```

The initialization requires at least three parameters:

- `Endpoint`: 127.0.0.1
- `Port`: 8831
- `RouteMode`: DIRECT/PROXY

`Endpoihnt` and `Port` are simple.
Here is the explanation of `RouteMode`. There are two kinds of `RouteMode`,The `Direct` mode should be adopted to avoid forwarding overhead if all the servers are accessible to the client.
However, the `Proxy` mode is the only choice if the access to the servers from the client must go through a gateway.
For more configuration options, see [configuration](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/configuration.md)

Notice: CeresDB currently only supports the default database `public` now, multiple databases will be supported in the future;

## Create Table Example

CeresDB is a Schema-less time-series database, so creating table schema ahead of data ingestion is not required (CeresDB will create a default schema according to the very first data you write into it). Of course, you can also manually create a schema for fine grained management purposes (eg. managing index).

The following table creation statement（using the SQL API included in SDK ）shows all field types supported by CeresDB：

```java
// Create table manually, creating table schema ahead of data ingestion is not required
String createTableSql = "CREATE TABLE IF NOT EXISTS machine_table(" +                                                                                              "ts TIMESTAMP NOT NULL," + //
        "ts TIMESTAMP NOT NULL," +
        "city STRING TAG NOT NULL," +
        "ip STRING TAG NOT NULL," +
        "cpu DOUBLE NULL," +
        "mem DOUBLE NULL," +
        "TIMESTAMP KEY(ts)" + // timestamp column must be specified
        ") ENGINE=Analytic";

Result<SqlQueryOk, Err> createResult = client.sqlQuery(new SqlQueryRequest(createTableSql)).get();
if (!createResult.isOk()) {
        throw new IllegalStateException("Fail to create table");
}
```

## Drop Table Example

Here is an example of dropping table：

```java
String dropTableSql = "DROP TABLE machine_table";

Result<SqlQueryOk, Err> dropResult = client.sqlQuery(new SqlQueryRequest(dropTableSql)).get();
if (!createResult.isOk()) {
        throw new IllegalStateException("Fail to drop table");
}
```

## Write Data Example

Firstly, you can use `PointBuilder` to build CeresDB points:

```java
List<Point> pointList = new LinkedList<>();
for (int i = 0; i < 100; i++) {
    // build one point
    final Point point = Point.newPointBuilder("machine_table")
            .setTimestamp(t0).addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1").addField("cpu", Value.withDouble(0.23))
            .addField("mem", Value.withDouble(0.55)).build();
    points.add(point);
}
```

Then, you can use `write` interface to write data:

```java
final CompletableFuture<Result<WriteOk, Err>> wf = client.write(new WriteRequest(pointList));
// here the `future.get` is just for demonstration, a better async programming practice would be using the CompletableFuture API
final Result<WriteOk, Err> writeResult = wf.get();
        Assert.assertTrue(writeResult.isOk());
        // `Result` class referenced the Rust language practice, provides rich functions (such as mapXXX, andThen) transforming the result value to improve programming efficiency. You can refer to the API docs for detail usage.
        Assert.assertEquals(3, writeResult.getOk().getSuccess());
        Assert.assertEquals(3, writeResult.mapOr(0, WriteOk::getSuccess).intValue());
        Assert.assertEquals(0, writeResult.mapOr(-1, WriteOk::getFailed).intValue());
```

See [write](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/write.md)

## Query Data Example

```java
final SqlQueryRequest queryRequest = SqlQueryRequest.newBuilder()
        .forTables("machine_table") // table name is optional. If not provided, SQL parser will parse the `ssql` to get the table name and do the routing automaticly
        .sql("select * from machine_table where ts = %d", t0) //
        .build();
final CompletableFuture<Result<SqlQueryOk, Err>> qf = client.sqlQuery(queryRequest);
// here the `future.get` is just for demonstration, a better async programming practice would be using the CompletableFuture API
final Result<SqlQueryOk, Err> queryResult = qf.get();

Assert.assertTrue(queryResult.isOk());

final SqlQueryOk queryOk = queryResult.getOk();
Assert.assertEquals(1, queryOk.getRowCount());

// get rows as list
final List<Row> rows = queryOk.getRowList();
Assert.assertEquals(t0, rows.get(0).getColumnValue("ts").getTimestamp());
Assert.assertEquals("Singapore", rows.get(0).getColumnValue("city").getString());
Assert.assertEquals("10.0.0.1", rows.get(0).getColumnValue("ip").getString());
Assert.assertEquals(0.23, rows.get(0).getColumnValue("cpu").getDouble(), 0.0000001);
Assert.assertEquals(0.55, rows.get(0).getColumnValue("mem").getDouble(), 0.0000001);

// get rows as stream
final Stream<Row> rowStream = queryOk.stream();
rowStream.forEach(row -> System.out.println(row.toString()));
```

See [read](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/read.md)

## Stream Write/Read Example

CeresDB support streaming writing and reading，suitable for large-scale data reading and writing。

```java
long start = System.currentTimeMillis();
long t = start;
final StreamWriteBuf<Point, WriteOk> writeBuf = client.streamWrite("machine_table");

for (int i = 0; i < 1000; i++) {
    final List<Point> streamData = Point.newPointsBuilder("machine_table")
        .addPoint()
            .setTimestamp(t)
            .addTag("city", "Beijing")
            .addTag("ip", "10.0.0.3")
            .addField("cpu", Value.withDouble(0.42))
            .addField("mem", Value.withDouble(0.67))
            .build()
        .build();
        writeBuf.writeAndFlush(streamData);
        t = t+1;
}
final CompletableFuture<WriteOk> writeOk = writeBuf.completed();
Assert.assertEquals(1000, writeOk.join().getSuccess());

final SqlQueryRequest streamQuerySql = SqlQueryRequest.newBuilder()
        .sql("select * from %s where city = '%s' and ts >= %d and ts < %d", "machine_table", "Beijing", start, t).build();
final Result<SqlQueryOk, Err> streamQueryResult = client.sqlQuery(streamQuerySql).get();
Assert.assertTrue(streamQueryResult.isOk());
Assert.assertEquals(1000, streamQueryResult.getOk().getRowCount());
```

See [streaming](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/streaming.md)
