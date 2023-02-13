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
  <version>1.0.0</version>
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

配置详情见 [configuration](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/configuration.md)。

注意: CeresDB 当前仅支持默认的 `public` database , 未来会支持多个database。

## 建表 Example

CeresDB 是一个 Schema-less 的时序数据引擎，你可以不必创建 schema 就立刻写入数据（CeresDB 会根据你的第一次写入帮你创建一个默认的 schema）。
当然你也可以自行创建一个 schema 来更精细化的管理的表（比如索引等）

下面的建表语句（使用 SDK 的 SQL API）包含了 CeresDB 支持的所有字段类型：

```java
String createTableSql = "CREATE TABLE IF NOT EXISTS machine_table(" +                                                                                              "ts TIMESTAMP NOT NULL," + //
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

详情见 [table](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/table.md)

## 构建写入数据

我们提供两种构建数据的方式：

第一种支持用户使用 `PointBuilder` 每次单独构建一个 `Point`。

```java
List<Point> pointList = new LinkedList<>();
for (int i = 0; i < 100; i++) {
    // 构建单个Point
    final Point point = Point.newPointBuilder("machine_table")
            .setTimestamp(t0).addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1").addField("cpu", Value.withDouble(0.23))
            .addField("mem", Value.withDouble(0.55)).build();
    points.add(point);
}
```

第二种支持用户使用 `TablePointsBuilder` 直接构建多个 `Point`。

```java
// 同一个表的数据可以一个tableBuilder快速构建
final List<Point> pointList = Point.newTablePointsBuilder("machine_table")
        .addPoint() // 第一个点
            .setTimestamp(t0)
            .addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1")
            .addField("cpu", Value.withDouble(0.23))
            .addField("mem", Value.withDouble(0.55))
            .buildAndContinue()
        .addPoint() // 第二个点
            .setTimestamp(t1)
            .addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1")
            .addField("cpu", Value.withDouble(0.25))
            .addField("mem", Value.withDouble(0.56))
            .buildAndContinue()
        .addPoint() // 第三个点
            .setTimestamp(t1)
            .addTag("city", "Shanghai")
            .addTag("ip", "10.0.0.2")
            .addField("cpu", Value.withDouble(0.21))
            .addField("mem", Value.withDouble(0.52))
            .buildAndContinue()
        .build();
```

## 写入 Example

```java
final long t0 = System.currentTimeMillis();
final long t1 = t0 + 1000;
final List<Point> data = Point.newPointsBuilder("machine_table") // 同一个表的数据可以一个builder快速构建数据
        .addPoint() // 第一个点
            .setTimestamp(t0)
            .addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1")
            .addField("cpu", Value.withDouble(0.23))
            .addField("mem", Value.withDouble(0.55))
            .build()
        .addPoint() // 第二个点
            .setTimestamp(t1)
            .addTag("city", "Singapore")
            .addTag("ip", "10.0.0.1")
            .addField("cpu", Value.withDouble(0.25))
            .addField("mem", Value.withDouble(0.56))
            .build()
        .addPoint() // 第三个点
            .setTimestamp(t1)
            .addTag("city", "Shanghai")
            .addTag("ip", "10.0.0.2")
            .addField("cpu", Value.withDouble(0.21))
            .addField("mem", Value.withDouble(0.52))
            .build()
        .build();

final CompletableFuture<Result<WriteOk, Err>> wf = client.write(data);
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

## 查询 Example

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
Assert.assertEquals(t0, rows.get(0).getColumnValue("ts").getTimestamp());
Assert.assertEquals("Singapore", rows.get(0).getColumnValue("city").getString());
Assert.assertEquals("10.0.0.1", rows.get(0).getColumnValue("ip").getString());
Assert.assertEquals(0.23, rows.get(0).getColumnValue("cpu").getDouble(), 0.0000001);
Assert.assertEquals(0.55, rows.get(0).getColumnValue("mem").getDouble(), 0.0000001);

// 获取结果流
final Stream<Row> rowStream = queryOk.stream();
rowStream.forEach(row -> System.out.println(row.toString()));
```

详情见 [read](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/read.md)

## 流式读写 Example

CeresDB 支持流式读写，适用于大规模数据读写。

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

详情见 [streaming](https://github.com/CeresDB/ceresdb-client-java/tree/main/docs/streaming.md)
