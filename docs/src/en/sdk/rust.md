# Rust
## Install
Just need to add dependency to Cargo.toml in your project:
```toml
[dependencies.ceresdb-client-rs]
git = "https://github.com/CeresDB/ceresdb-client-rs.git"
rev = "a72e673103463c7962e01a097592fc7edbcc0b79"  
```
## Build client
At first, we need to build the client.
+ We need to create builder for the client, and you must set `endpoint` and `mode`: 
  + `endpoint` is a string which is usually like "ip/domain_name:port".
  + `mode` is used to define the way to access ceresdb server, [detail about `mode`](https://github.com/CeresDB/ceresdb-client-rs/blob/a72e673103463c7962e01a097592fc7edbcc0b79/src/db_client/builder.rs#L20).
```rust
    let mut builder = Builder::new("ip/domain_name:port", Mode::Direct/Mode::Proxy);
```
+ You can modify the rpc configs rather than using the default value, [detail about rpc configs](https://github.com/CeresDB/ceresdb-client-rs/blob/main/src/options.rs):
```rust
    let builder = builder.grpc_config(...).rpc_opts(...);
```
+ Finally, we build client from builder:
```rust
    let client = builder.build();
```
## Write
We support to write with the time series data model like [influxdb](https://awesome.influxdata.com/docs/part-2/influxdb-data-model/).
+ You need to create a `point group` first, the related data structure of `tag value` and `field value` in it is defined as `Value`, [detail about Value](https://github.com/CeresDB/ceresdb-client-rs/blob/main/src/model/value.rs):
```rust
    let ts = Local::now().timestamp_millis();
    let point_group_builder = PointGroupBuilder::new(metric name);
    let point_group = point_group_builder
        // Add one point.
        .add_point()
        .timestamp(ts)
        .tag(tag name, tag value)
        .tag(...)
        .tag(...)
        .field(field name, field value)
        .field(...)
        .field(...)
        .finish()
        .unwrap()
        // Add an new point.
        .add_point()
        ... 
        .finish()
        .unwrap()
        // Build the point group.
        .build();
```
+ Add the `point group` to `write request`:
```rust
    let mut write_req = WriteRequest::default();
    write_req.add_point_group(point_group);
```
+ Finally, write to server by client, the `rpc ctx` is used to carry user information, [detail about rpc ctx](https://github.com/CeresDB/ceresdb-client-rs/blob/a72e673103463c7962e01a097592fc7edbcc0b79/src/rpc_client/mod.rs#L29):
```rust
    let resp = client.write(rpc_ctx, &write_req).await.expect("Should success to write");
```
## Sql query
We support to query data with sql.
+ You need to define related tables and sql in `read request`:
```rust
    let req = SqlQueryRequest {
        tables: vec![table name 1,...,table name n],
        sql: sql string (e.g. select * from xxx),
    };
```
+ Query from client:
```rust
    let resp = client.sql_query(rpc_ctx, &req).await.expect("Should success to write");
``` 
## Example
You can find the [complete example](https://github.com/CeresDB/ceresdb-client-rs/blob/main/examples/read_write.rs) in the project. 







