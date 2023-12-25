# OpenTSDB

[OpenTSDB](http://opentsdb.net/) 是基于 HBase 的分布式、可伸缩的时间序列数据库。

# 写入

HoraeDB 遵循 [OpenTSDB put](http://opentsdb.net/docs/build/html/api_http/put.html) 写入接口。

`summary` 和 `detailed` 还未支持。

```
curl --location 'http://localhost:5440/opentsdb/api/put' \
--header 'Content-Type: application/json' \
-d '[{
    "metric": "sys.cpu.nice",
    "timestamp": 1692588459000,
    "value": 18,
    "tags": {
       "host": "web01",
       "dc": "lga"
    }
},
{
    "metric": "sys.cpu.nice",
    "timestamp": 1692588459000,
    "value": 18,
    "tags": {
       "host": "web01"
    }
}]'
```

`metric` 将映射到 HoraeDB 中的一个表，在首次写入时 server 会自动进行建表(注意：创建表的 TTL 是 7d，写入超过当前周期数据会被丢弃)。

例如，在上面插入数据时，HoraeDB 中将创建下表：

```
CREATE TABLE `sys.cpu.nice`(
    `tsid` uint64 NOT NULL,
    `timestamp` timestamp NOT NULL,
    `dc` string TAG,
    `host` string TAG,
    `value` bigint,
    PRIMARY KEY(tsid, timestamp),
    TIMESTAMP KEY(timestamp))
    ENGINE = Analytic
    WITH(arena_block_size = '2097152', compaction_strategy = 'default',
    compression = 'ZSTD', enable_ttl = 'true', num_rows_per_row_group = '8192',
    segment_duration = '2h', storage_format = 'AUTO', ttl = '7d',
    update_mode = 'OVERWRITE', write_buffer_size = '33554432')
```

# 查询

暂不支持 OpenTSDB 查询，[tracking issue](https://github.com/apache/incubator-horaedb/issues/904)。
