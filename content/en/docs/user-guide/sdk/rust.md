---
title: "Rust"
---

[![](https://img.shields.io/crates/v/horaedb-client.svg)](https://crates.io/crates/horaedb-client)
[![](https://img.shields.io/github/stars/apache/horaedb-client-rs)](https://github.com/apache/horaedb-client-rs)

## Install

```bash
cargo add horaedb-client
```

You can get latest version [here](https://github.com/apache/horaedb-client-rs/tags).

## Init Client

At first, we need to init the client.

- New builder for the client, and you must set `endpoint` and `mode`:
  - `endpoint` is a string which is usually like "ip/domain_name:port".
  - `mode` is used to define the way to access horaedb server, [detail about mode](https://github.com/apache/horaedb-client-rs/blob/main/src/db_client/builder.rs#L20).

```rust
let mut builder = Builder::new("ip/domain_name:port", Mode::Direct/Mode::Proxy);
```

- New and set `rpc_config`, it can be defined on demand or just use the default value, [detail about rpc config](https://github.com/apache/horaedb-client-rs/blob/main/src/options.rs):

```rust
let rpc_config = RpcConfig {
    thread_num: Some(1),
    default_write_timeout: Duration::from_millis(1000),
    ..Default::default()
};
let builder = builder.rpc_config(rpc_config);
```

- Set `default_database`, it will be used if following rpc calling without setting the database in the `RpcContext`(will be introduced in later):

```rust
    let builder = builder.default_database("public");
```

- Finally, we build client from builder:

```rust
    let client = builder.build();
```

## Manage Table

For ease of use, when using gRPC's write interface for writing, if a table does not exist, HoraeDB will automatically create a table based on the first write.

Of course, you can also use `create table` statement to manage the table more finely (such as adding indexes).

You can use the sql query interface to create or drop table, related setting will be introduced in `sql query` section.

- Create table:

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

- Drop table:

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

## Write

We support to write with the time series data model like [InfluxDB](https://awesome.influxdata.com/docs/part-2/influxdb-data-model/).

- Build the `point` first by `PointBuilder`, the related data structure of `tag value` and `field value` in it is defined as `Value`, [detail about Value](https://github.com/apache/horaedb-client-rs/blob/main/src/model/value.rs):

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

- Add the `point` to `write request`:

```rust
let mut write_req = WriteRequest::default();
write_req.add_point(point);
```

- New `rpc_ctx`, and it can also be defined on demand or just use the default value, [detail about rpc ctx](https://github.com/apache/horaedb-client-rs/blob/a72e673103463c7962e01a097592fc7edbcc0b79/src/rpc_client/mod.rs#L29):

- Finally, write to server by client.

```rust
let rpc_ctx = RpcContext {
    database: Some("public".to_string()),
    ..Default::default()
};
let resp = client.write(rpc_ctx, &write_req).await.expect("Should success to write");
```

## Sql Query

We support to query data with sql.

- Define related tables and sql in `sql query request`:

```rust
let req = SqlQueryRequest {
    tables: vec![table name 1,...,table name n],
    sql: sql string (e.g. select * from xxx),
};
```

- Query by client:

```rust
let resp = client.sql_query(rpc_ctx, &req).await.expect("Should success to write");
```

## Example

You can find the [complete example](https://github.com/apache/horaedb-client-rs/blob/main/examples/read_write.rs) in the project.
