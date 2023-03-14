# Java 客户端使用文档

## 介绍

CeresDBClient 是 CeresDB 的高性能 Java 版客户端。

## 环境要求

Java 8 及以上

## 依赖

```xml
<dependency>
  <groupId>io.ceresdb</groupId>
  <artifactId>ceresdb-all</artifactId>
  <version>1.0.1</version>
</dependency>
```

## 初始化客户端

```java
// CeresDB options
final CeresDBOptions opts = CeresDBOptions.newBuilder("127.0.0.1", 8831, DIRECT) // 默认 gprc 端口号，DIRECT 模式
        .database("public") // Client所使用的database，可被RequestContext的database覆盖
        .writeMaxRetries(1) // 写入失败重试次数上限（只有部分错误 code 才会重试，比如路由表失效）
        .readMaxRetries(1)  // 查询失败重试次数上限（只有部分错误 code 才会重试，比如路由表失效）
        .build();

final CeresDBClient client = new CeresDBClient();
if (!client.init(opts)) {
    throw new IllegalStateException("Fail to start CeresDBClient");
}
```

客户端初始化至少需要三个参数：

- EndPoint： 127.0.0.1
- Port： 8831
- RouteMode： DIRECT/PROXY

这里重点解释下 `RouteMode` 参数，`PROXY` 模式用在客户端和服务端存在网络隔离，请求需要经过转发的场景；`DIRECT` 模式用在客户端和服务端网络连通的场景，节省转发的开销，具有更高的性能。
更多的参数配置详情见 [configuration](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/configuration.md)。

注意： CeresDB 当前仅支持默认的 `public` database , 未来会支持多个 database。

## 建表

为了方便使用，在使用 gRPC 的 write 接口进行写入时，如果某个表不存在，CeresDB 会根据第一次的写入自动创建一个表。

当然你也可以通过 `create table` 语句来更精细化的管理的表（比如添加索引等）。

下面的建表语句（使用 SDK 的 SQL API）包含了 CeresDB 支持的所有字段类型：

```java
String createTableSql = "CREATE TABLE IF NOT EXISTS machine_table(" +
        "ts TIMESTAMP NOT NULL," +
        "city STRING TAG NOT NULL," +
        "ip STRING TAG NOT NULL," +
        "cpu DOUBLE NULL," +
        "mem DOUBLE NULL," +
        "TIMESTAMP KEY(ts)" + // 建表时必须指定时间戳序列
        ") ENGINE=Analytic";

Result<SqlQueryOk, Err> createResult = client.sqlQuery(new SqlQueryRequest(createTableSql)).get();
if (!createResult.isOk()) {
        throw new IllegalStateException("Fail to create table");
}
```

## 删表

下面是一个删表的示例：

```java
String dropTableSql = "DROP TABLE machine_table";

Result<SqlQueryOk, Err> dropResult = client.sqlQuery(new SqlQueryRequest(dropTableSql)).get();
if (!dropResult.isOk()) {
        throw new IllegalStateException("Fail to drop table");
}
```

## 数据写入

首先我们需要构建数据，示例如下：

```java
List<Point> pointList = new LinkedList<>();
for (int i = 0; i < 100; i++) {
    // 构建单个Point
    final Point point = Point.newPointBuilder("machine_table")
            .setTimestamp(t0)
            .addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1")
            .addField("cpu", Value.withDouble(0.23))
            .addField("mem", Value.withDouble(0.55))
            .build();
    points.add(point);
}
```

然后使用 `write` 接口写入数据，示例如下：

```java
final CompletableFuture<Result<WriteOk, Err>> wf = client.write(pointList);
// 这里用 `future.get` 只是方便演示，推荐借助 CompletableFuture 强大的 API 实现异步编程
final Result<WriteOk, Err> writeResult = wf.get();

Assert.assertTrue(writeResult.isOk());
Assert.assertEquals(3, writeResult.getOk().getSuccess());
// `Result` 类参考了 Rust 语言，提供了丰富的 mapXXX、andThen 类 function 方便对结果值进行转换，提高编程效率，欢迎参考 API 文档使用
Assert.assertEquals(3, writeResult.mapOr(0, WriteOk::getSuccess).intValue());
Assert.assertEquals(0, writeResult.getOk().getFailed());
Assert.assertEquals(0, writeResult.mapOr(-1, WriteOk::getFailed).intValue());
```

详情见 [write](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/write.md)

## 数据查询

```java
final SqlQueryRequest queryRequest = SqlQueryRequest.newBuilder()
        .forTables("machine_table") // 这里表名是可选的，如果未提供，SDK将自动解析SQL填充表名并自动路由
        .sql("select * from machine_table where ts = %d", t0) //
        .build();
final CompletableFuture<Result<SqlQueryOk, Err>> qf = client.sqlQuery(queryRequest);
// 这里用 `future.get` 只是方便演示，推荐借助 CompletableFuture 强大的 API 实现异步编程
final Result<SqlQueryOk, Err> queryResult = qf.get();

Assert.assertTrue(queryResult.isOk());

final SqlQueryOk queryOk = queryResult.getOk();
Assert.assertEquals(1, queryOk.getRowCount());

// 直接获取结果数组
final List<Row> rows = queryOk.getRowList();
Assert.assertEquals(t0, rows.get(0).getColumn("ts").getValue().getTimestamp());
Assert.assertEquals("Singapore", rows.get(0).getColumn("city").getValue().getString());
Assert.assertEquals("10.0.0.1", rows.get(0).getColumn("ip").getValue().getString());
Assert.assertEquals(0.23, rows.get(0).getColumn("cpu").getValue().getDouble(), 0.0000001);
Assert.assertEquals(0.55, rows.get(0).getColumn("mem").getValue().getDouble(), 0.0000001);

// 获取结果流
final Stream<Row> rowStream = queryOk.stream();
rowStream.forEach(row -> System.out.println(row.toString()));
```

详情见 [read](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/read.md)

## 流式读写

CeresDB 支持流式读写，适用于大规模数据读写。

```java
long start = System.currentTimeMillis();
long t = start;
final StreamWriteBuf<Point, WriteOk> writeBuf = client.streamWrite("machine_table");
for (int i = 0; i < 1000; i++) {
        final Point streamData = Point.newPointBuilder("machine_table")
                .setTimestamp(t)
                .addTag("city", "Beijing")
                .addTag("ip", "10.0.0.3")
                .addField("cpu", Value.withDouble(0.42))
                .addField("mem", Value.withDouble(0.67))
                .build();
        writeBuf.writeAndFlush(Collections.singletonList(streamData));
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

详情见 [streaming](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/streaming.md)
