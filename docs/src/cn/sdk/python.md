# Python

## 介绍

[ceresdb-client](https://pypi.org/project/ceresdb-client/) 是 [CeresDB](https://github.com/CeresDB/ceresdb) python 客户端.

借助于 [PyO3](https://github.com/PyO3)，python 客户端的实现实际上是基于 [rust 客户端](https://github.com/CeresDB/ceresdb-client-rs) 的封装。

本手册将会介绍 python client 的一些基本用法，其中涉及到的完整示例，可以查看[该示例代码](https://github.com/CeresDB/ceresdb-client-py/blob/main/examples/read_write.py).

## 环境要求

- Python >= 3.7

## 安装

```bash
pip install ceresdb-client
```

## 初始化客户端

首先介绍下如何初始化客户端，代码示例如下：

```python
import asyncio
import datetime
from ceresdb_client import Builder, RpcContext, PointBuilder, ValueBuilder, WriteRequest, SqlQueryRequest, Mode, RpcConfig

rpc_config = RpcConfig()
rpc_config = RpcConfig()
rpc_config.thread_num = 1
rpc_config.default_write_timeout_ms = 1000

builder = Builder('127.0.0.1:8831', Mode.Direct)
builder.set_rpc_config(rpc_config)
builder.set_default_database('public')
client = builder.build()
```

代码的最开始部分是依赖库的导入，在后面的示例中将省略这部分。

客户端初始化需要至少两个参数：

- `Endpoint`： 服务端地址，由 ip 和端口组成，例如 `127.0.0.1：8831`;
- `Mode`: 客户端和服务端通信模式，有两种模式可供选择: `Direct` 和 `Proxy`。

这里重点介绍下通信模式 `Mode`， 当客户端可以访问所有的服务器的时候，建议采用 `Direct` 模式，以减少转发开销；但是如果客户端访问服务器必须要经过网关，那么只能选择 `Proxy` 模式。

至于 `default_database`，会在执行 RPC 请求时未通过 `RpcContext` 设置 database 的情况下，将被作为目标 database 使用。

最后，通过配置 `RpcConfig`, 可以管理客户端使用的资源和调整其性能，所有的配置参数可以参考[这里](https://github.com/CeresDB/ceresdb-client-py/blob/main/ceresdb_client.pyi).

## 建表

为了方便使用，在使用 gRPC 的 write 接口进行写入时，如果某个表不存在，CeresDB 会根据第一次的写入自动创建一个表。

当然你也可以通过 `create table` 语句来更精细化的管理的表（比如添加索引等）。

初始化客户端后，建表示例如下：

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

`RpcContext` 可以用来指定目标 database （可以覆盖在初始化的时候设置的 default_space） 和超时参数。

## 数据写入

可以使用 `PointBuilder` 来构建一个 point（实际上就是数据集的一行），多个 point 构成一个写入请求。

示例如下:

```python
async def async_write(client, ctx, req):
    return await client.write(ctx, req)

point_builder = PointBuilder('demo')
point_builder.set_timestamp(1000 * int(round(datetime.datetime.now().timestamp())))
point_builder.set_tag("name", ValueBuilder().string("test_tag1"))
point_builder.set_field("value", ValueBuilder().double(0.4242))
point = point_builder.build()

write_request = WriteRequest()
write_request.add_point(point)

event_loop = asyncio.get_event_loop()
event_loop.run_until_complete(async_write(client, ctx, req))
```

## 数据查询

通过 `sql_query` 接口, 可以方便地从服务端查询数据：

```
req = SqlQueryRequest(['demo'], 'select * from demo')
event_loop = asyncio.get_event_loop()
resp = event_loop.run_until_complete(async_query(client, ctx, req))
```

如示例所展示, 构建 `SqlQueryRequest` 需要两个参数:

- 查询 sql 中涉及到的表；
- 查询 sql.

当前为了查询的性能，第一个参数是必须的。

查询到数据后，逐行逐列处理数据的示例如下：

```python
# Access row by index in the resp.
for row_idx in range(0, resp.num_rows()):
    row_tokens = []
    row = resp.row_by_idx(row_idx)
    for col_idx in range(0, row.num_cols()):
        col = row.column_by_idx(col_idx)
        row_tokens.append(f"{col.name()}:{col.value()}#{col.data_type()}")
    print(f"row#{row_idx}: {','.join(row_tokens)}")

# Access row by iter in the resp.
for row in resp.iter_rows():
    row_tokens = []
    for col in row.iter_columns():
        row_tokens.append(f"{col.name()}:{col.value()}#{col.data_type()}")
    print(f"row: {','.join(row_tokens)}")
```

## 删表

和创建表类似，我们可以使用 sql 来删除表：

```python
drop_table_sql = 'DROP TABLE demo'

req = SqlQueryRequest(['demo'], drop_table_sql)

event_loop = asyncio.get_event_loop()
event_loop.run_until_complete(async_query(client, rpc_ctx, req))
```
