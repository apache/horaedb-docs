# OpenTSDB

[OpenTSDB](http://opentsdb.net/) is a distributed and scalable time series database based on HBase.

# Write

CeresDB follows the [OpenTSDB put](http://opentsdb.net/docs/build/html/api_http/put.html) write protocol.

`summary` and `detailed` are not yet supported.

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
'
```

Metric will be mapped to table in CeresDB, and it will be created automatically in first write(Note: The default TTL is 7d, and data written beyond the current cycle will be discarded).

For example, when inserting data above, table below will be automatically created in CeresDB:

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

# Query

OpenTSDB query protocol is not currently supported, [tracking issue](https://github.com/CeresDB/ceresdb/issues/904).
