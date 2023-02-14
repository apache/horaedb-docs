# Rust

## 安装

你只需要在项目的 Cargo.toml 文件中加入以下依赖：

```toml
[dependencies.ceresdb-client-rs]
git = "https://github.com/CeresDB/ceresdb-client-rs.git"
rev = "69948b9963597ccdb7c73756473393972dfdebd3"
```

## 初始化客户端

首先，我们需要初始化客户端。

- 创建客户端的 builder，你必须设置 `endpoint` 和 `mode`：
  - `endpoint` 是类似 "ip/domain_name:port" 形式的字符串。
  - `mode` 用于指定访问 CeresDB 服务器的方式，[关于 mode 的详细信息](https://github.com/CeresDB/ceresdb-client-rs/blob/main/src/db_client/builder.rs#L20)。

```rust
let mut builder = Builder::new("ip/domain_name:port", Mode::Direct/Mode::Proxy);
```

- 创建和设置 `rpc_config`，可以按需进行定义或者直接使用默认值，更多详细参数请参考[这里](https://github.com/CeresDB/ceresdb-client-rs/blob/main/src/options.rs)：

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
    let builder = builder.default_database('public');
```

- 最后，我们从 builder 中创建客户端：

```rust
    let client = builder.build();
```

## 管理表

CeresDB 是一个 Schema-less 的时序数据引擎，你可以不必创建 schema 就立刻写入数据（CeresDB 会根据你的第一次写入帮你创建一个默认的 schema）。 当然你也可以自行创建一个 schema 来更精细化的管理表（比如添加索引等）。

你可以通过 `sql query` 接口创建或者删除表，相关设置在 `sql query` 小节中介绍。

- 建表:

```rust
let create_table_sql = r#"CREATE TABLE IF NOT EXISTS ceresdb (
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
    tables: vec!["ceresdb".to_string()],
    sql: create_table_sql.to_string(),
};

let resp = client
    .sql_query(rpc_ctx, &req)
    .await
    .expect("Should succeed to create table");
```

- 删表：

```rust
let drop_table_sql = "DROP TABLE ceresdb";
let req = SqlQueryRequest {
    tables: vec!["ceresdb".to_string()],
    sql: drop_table_sql.to_string(),
};

let resp = client
    .sql_query(rpc_ctx, &req)
    .await
    .expect("Should succeed to create table");
```

## 写入数据

我们支持使用类似 [influxdb](https://awesome.influxdata.com/docs/part-2/influxdb-data-model) 的时序数据模型进行写入。

- 利用 `PointBuilder` 创建 `point`，`tag value` 和 `field value` 的相关数据结构为 `Value`，[`Value` 的详细信息](detail about Value](https://github.com/CeresDB/ceresdb-client-rs/blob/main/src/model/value.rs：

```rust
let test_table = "ceresdb";
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

- 创建 `rpc_ctx`，同样地可以按需设置或者使用默认值，`rpc_ctx` 的详细信息请参考[这里](https://github.com/CeresDB/ceresdb-client-rs/blob/a72e673103463c7962e01a097592fc7edbcc0b79/src/rpc_client/mod.rs#L29)：

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

你可以在本项目的仓库中找到[完整的例子](https://github.com/CeresDB/ceresdb-client-rs/blob/main/examples/read_write.rs)。
