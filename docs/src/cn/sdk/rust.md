# Rust

## 安装

```bash
cargo add ceresdb-client
```

你可以在这里找到最新的版本 [here](https://github.com/apache/incubator-horaedb-client-rs/tags).

## 初始化客户端

首先，我们需要初始化客户端。

- 创建客户端的 builder，你必须设置 `endpoint` 和 `mode`：
  - `endpoint` 是类似 "ip/domain_name:port" 形式的字符串。
  - `mode` 用于指定访问 HoraeDB 服务器的方式，[关于 mode 的详细信息](https://github.com/apache/incubator-horaedb-client-rs/blob/main/src/db_client/builder.rs#L20)。

```rust
let mut builder = Builder::new("ip/domain_name:port", Mode::Direct/Mode::Proxy);
```

- 创建和设置 `rpc_config`，可以按需进行定义或者直接使用默认值，更多详细参数请参考[这里](https://github.com/apache/incubator-horaedb-client-rs/blob/main/src/options.rs)：

```rust
let rpc_config = RpcConfig {
    thread_num: Some(1),
    default_write_timeout: Duration::from_millis(1000),
    ..Default::default()
};
let builder = builder.rpc_config(rpc_config);
```

- 设置 `default_database`，这会在执行 RPC 请求时未通过 RpcContext 设置 database 的情况下，将被作为目标 database 使用。

```rust
    let builder = builder.default_database("public");
```

- 最后，我们从 builder 中创建客户端：

```rust
    let client = builder.build();
```

## 管理表

为了方便使用，在使用 gRPC 的 write 接口进行写入时，如果某个表不存在，HoraeDB 会根据第一次的写入自动创建一个表。

当然你也可以通过 `create table` 语句来更精细化的管理的表（比如添加索引等）。

- 建表:

```rust
let create_table_sql = r#"CREATE TABLE IF NOT EXISTS horaedb (
            str_tag string TAG,
            int_tag int32 TAG,
            var_tag varbinary TAG,
            str_field string,
            int_field int32,
            bin_field varbinary,
            t timestamp NOT NULL,
            TIMESTAMP KEY(t)) ENGINE=Analytic with
            (enable_ttl='false')"#;
let req = SqlQueryRequest {
    tables: vec!["horaedb".to_string()],
    sql: create_table_sql.to_string(),
};

let resp = client
    .sql_query(rpc_ctx, &req)
    .await
    .expect("Should succeed to create table");
```

- 删表：

```rust
let drop_table_sql = "DROP TABLE horaedb";
let req = SqlQueryRequest {
    tables: vec!["horaedb".to_string()],
    sql: drop_table_sql.to_string(),
};

let resp = client
    .sql_query(rpc_ctx, &req)
    .await
    .expect("Should succeed to create table");
```

## 写入数据

我们支持使用类似 [InfluxDB](https://awesome.influxdata.com/docs/part-2/influxdb-data-model) 的时序数据模型进行写入。

- 利用 `PointBuilder` 创建 `point`，`tag value` 和 `field value` 的相关数据结构为 `Value`，[`Value` 的详细信息](detail about Value](https://github.com/apache/incubator-horaedb-client-rs/blob/main/src/model/value.rs：

```rust
let test_table = "horaedb";
let ts = Local::now().timestamp_millis();
let point = PointBuilder::new(test_table.to_string())
        .timestamp(ts)
        .tag("str_tag".to_string(), Value::String("tag_val".to_string()))
        .tag("int_tag".to_string(), Value::Int32(42))
        .tag(
            "var_tag".to_string(),
            Value::Varbinary(b"tag_bin_val".to_vec()),
        )
        .field(
            "str_field".to_string(),
            Value::String("field_val".to_string()),
        )
        .field("int_field".to_string(), Value::Int32(42))
        .field(
            "bin_field".to_string(),
            Value::Varbinary(b"field_bin_val".to_vec()),
        )
        .build()
        .unwrap();
```

- 将 `point` 添加到 `write request` 中：

```rust
let mut write_req = WriteRequest::default();
write_req.add_point(point);
```

- 创建 `rpc_ctx`，同样地可以按需设置或者使用默认值，`rpc_ctx` 的详细信息请参考[这里](https://github.com/apache/incubator-horaedb-client-rs/blob/main/src/rpc_client/mod.rs#L23)：

```rust
let rpc_ctx = RpcContext {
    database: Some("public".to_string()),
    ..Default::default()
};
```

- 最后，利用客户端写入数据到服务器：

```rust
let rpc_ctx = RpcContext {
    database: Some("public".to_string()),
    ..Default::default()
};
let resp = client.write(rpc_ctx, &write_req).await.expect("Should success to write");
```

## Sql query

我们支持使用 sql 进行数据查询。

- 在 `sql query request` 中指定相关的表和 sql 语句：

```rust
let req = SqlQueryRequest {
    tables: vec![table name 1,...,table name n],
    sql: sql string (e.g. select * from xxx),
};
```

- 利用客户端进行查询：

```rust
let resp = client.sql_query(rpc_ctx, &req).await.expect("Should success to write");
```

## 示例

你可以在本项目的仓库中找到[完整的例子](https://github.com/apache/incubator-horaedb-client-rs/blob/main/examples/read_write.rs)。
