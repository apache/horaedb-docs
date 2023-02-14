# Python

## Introduction

[ceresdb-client](https://pypi.org/project/ceresdb-client/) is the python client for [CeresDB](https://github.com/CeresDB/ceresdb).

Thanks to [PyO3](https://github.com/PyO3), the python client is actually a wrapper on the [rust client](https://github.com/CeresDB/ceresdb-client-rs).

The guide will give a basic introduction to the python client by [example](https://github.com/CeresDB/ceresdb-client-py/blob/main/examples/read_write.py).

## Requirements

- Python >= 3.7

## Installation

```bash
pip install ceresdb-client
```

## Init CeresDB Client

The client initialization comes first, here is a code snippet:

```python
import asyncio
import datetime
from ceresdb_client import Builder, RpcContext, PointBuilder, ValueBuilder, WriteRequest, SqlQueryRequest, Mode, RpcConfig

rpc_config = RpcConfig()
rpc_config = RpcConfig()
rpc_config.thread_num = 1
rpc_config.default_write_timeout_ms = 1000

client = Builder('127.0.0.1:8831', Mode.Direct) \
    .rpc_config(rpc_config) \
    .default_database('public') \
    .build()
```

Firstly, it's worth noting that the imported packages are used across all the code snippets in this guide, and they will not be repeated in the following.

The initialization requires at least two parameters:

- `Endpoint`: the server endpoint consisting of ip address and serving port, e.g. `127.0.0.1:8831`;
- `Mode`: The mode of the communication between client and server, and there are two kinds of `Mode`: `Direct` and `Proxy`.

`Endpoint` is simple, while `Mode` deserves more explanation. The `Direct` mode should be adopted to avoid forwarding overhead if all the servers are accessible to the client. However, the `Proxy` mode is the only choice if the access to the servers from the client must go through a gateway.

The `default_database` can be set and will be used if following rpc calling without setting the database in the `RpcContext`.

By configuring the `RpcConfig`, resource and performance of the client can be manipulated, and all of the configurations can be referred at [here](https://github.com/CeresDB/ceresdb-client-py/blob/main/ceresdb_client.pyi).

## Create Table

CeresDB is a Schema-less time-series database, so creating table schema ahead of data ingestion is not required (CeresDB will create a default schema according to the very first data you write into it). Of course, you can also manually create a schema for fine grained management purposes, e.g. managing index.

Here is a example for creating table by the initialized client:

```python
def async_query(client, ctx, req):
    await client.sql_query(ctx, req)

create_table_sql = 'CREATE TABLE IF NOT EXISTS demo ( \
    name string TAG, \
    value double, \
    t timestamp NOT NULL, \
    TIMESTAMP KEY(t)) ENGINE=Analytic with (enable_ttl=false)'

req = SqlQueryRequest(['demo'], create_table_sql)
rpc_ctx = RpcContext()
rpc_ctx.database = 'public'
rpc_ctx.timeout_ms = 100

event_loop = asyncio.get_event_loop()
event_loop.run_until_complete(async_query(client, rpc_ctx, req))
```

`RpcContext` can be used to overwrite the default database and timeout defined in the initialization of the client.

## Write Data

`PointBuilder` can be used to construct a point, which is actually a row in data set. The write request consists of multiple points.

The example is simple:

```python
async def async_write(client, ctx, req):
    return await client.write(ctx, req)

point_builder = PointBuilder('demo')
point = point_builder \
    .timestamp(int(round(datetime.datetime.now().timestamp()))) \
    .tag("name", ValueBuilder().string("test_tag1")) \
    .field("value", ValueBuilder().double(0.4242)) \
    .build()

write_request = WriteRequest()
write_request.add_point(point)

event_loop = asyncio.get_event_loop()
event_loop.run_until_complete(async_write(client, ctx, req))
```

## Query Data

By `sql_query` interface, it is easy to retrieve the data from the server:

```
req = SqlQueryRequest(['demo'], 'select * from demo')
event_loop = asyncio.get_event_loop()
resp = event_loop.run_until_complete(async_query(client, ctx, req))
```

As the example shows, two parameters are needed to construct the `SqlQueryRequest`:

- The tables involved by this sql query;
- The query sql.

Currently, the first parameter is necessary for performance on routing.

With retrieved data, we can process it row by row and column by column:

```python
for row_idx in range(0, resp.row_num()):
    row_tokens = []

    row = resp.get_row(row_idx)
    for col_idx in range(0, row.num_cols()):
        col = row.column_by_idx(col_idx)
        row_tokens.append(f"{col.name()}:{col.value()}#{col.data_type()}")

    print(f"row#{col_idx}: {','.join(row_tokens)}")
```

## Drop Table

Finally, we can drop the table by the sql api, which is similar to the table creation:

```python
drop_table_sql = 'DROP TABLE demo'

req = SqlQueryRequest(['demo'], drop_table_sql)

event_loop = asyncio.get_event_loop()
event_loop.run_until_complete(async_query(client, rpc_ctx, req))
```
