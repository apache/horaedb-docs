# InfluxDB

[InfluxDB](https://www.influxdata.com/products/influxdb-overview/) is a time series database designed to handle high write and query loads. It is an integral component of the TICK stack. InfluxDB is meant to be used as a backing store for any use case involving large amounts of timestamped data, including DevOps monitoring, application metrics, IoT sensor data, and real-time analytics.

CeresDB support both write and query through [influxDB 1.x http api described in doc of influxDB 1.8](https://docs.influxdata.com/influxdb/v1.8/tools/api/#influxdb-1x-http-endpoints).

## Write api

Insert data by POST HTTP requests:

```shell
curl -i -XPOST "http://localhost:5440/influxdb/v1/write?db=public&precision=ms" --data-binary 'mymeas,mytag=1 myfield=90 1463683075'
```

- Body:

  1. Inserted data formatted by [line protocol](https://docs.influxdata.com/influxdb/v1.8/concepts/glossary/#influxdb-line-protocol).

- Query parameters:

  1. `precision`, precision of timestamps in the line protocol, default to `ms`.
  2. `db`, not supported to set now.

Measurement will be created automatically like what in influxDB, and each measurement will be mapped to a table.

You need to mention that timestamp column must be time now, and users who want to try influxql should add following config:

```toml
[server.default_schema_config]
default_timestamp_column_name = "time"
```

For example, when inserting data above, table as following will be created in CeresDB:

```sql
  CREATE TABLE `mymeas` (
    `tsid` uint64 NOT NULL,
    `time` timestamp NOT NULL,
    `myfield` double,
    `mytag` string TAG,
    PRIMARY KEY(tsid,time), TIMESTAMP KEY(time)
  )
```

## Query api

```shell
 curl -G 'http://localhost:5440/influxdb/v1/query?db=public' --data-urlencode 'q=SELECT * FROM "mymeas"'
```

- Body:

  1. `q`, influxQL string to execute(when query by POST requests).

- Query parameters:

  1. `q`, when query by GET requests, see also in body.
  2. `db`, `epoch`, `pretty`, `chunked` are not supported to set now.
