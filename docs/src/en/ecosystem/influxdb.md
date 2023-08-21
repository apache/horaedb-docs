# InfluxDB

[InfluxDB](https://www.influxdata.com/products/influxdb-overview/) is a time series database designed to handle high write and query loads. It is an integral component of the TICK stack. InfluxDB is meant to be used as a backing store for any use case involving large amounts of timestamped data, including DevOps monitoring, application metrics, IoT sensor data, and real-time analytics.

CeresDB support [InfluxDB v1.8](https://docs.influxdata.com/influxdb/v1.8/tools/api/#influxdb-1x-http-endpoints) write and query API.

> Warn: users need to add following config to server's config in order to try InfluxDB write/query.

```toml
[server.default_schema_config]
default_timestamp_column_name = "time"
```

# Write

```shell
curl -i -XPOST "http://localhost:5440/influxdb/v1/write" --data-binary '
demo,tag1=t1,tag2=t2 field1=90,field2=100 1679994647000
demo,tag1=t1,tag2=t2 field1=91,field2=101 1679994648000
demo,tag1=t11,tag2=t22 field1=90,field2=100 1679994647000
demo,tag1=t11,tag2=t22 field1=91,field2=101 1679994648000
'
```

Post payload is in [InfluxDB line protocol](https://docs.influxdata.com/influxdb/v1.8/write_protocols/line_protocol_reference/) format.

Measurement will be mapped to table in CeresDB, and it will be created automatically in first write(Note: The default TTL is 7d, and points written exceed TTL will be discarded directly).

For example, when inserting data above, table below will be automatically created in CeresDB:

```sql
CREATE TABLE `demo` (
    `tsid` uint64 NOT NULL,
    `time` timestamp NOT NULL,
    `field1` double,
    `field2` double,
    `tag1` string TAG,
    `tag2` string TAG,
    PRIMARY KEY (tsid, time),
    timestamp KEY (time))
```

## Note

- When InfluxDB writes data, the timestamp precision is nanosecond by default, CeresDB only supports millisecond timestamp, user can specify the data precision by `precision` parameter, CeresDB will automatically convert to millisecond precision internally.
- Query string parameters such as `db` aren't supported.

# Query

```shell
 curl -G 'http://localhost:5440/influxdb/v1/query' --data-urlencode 'q=SELECT * FROM "demo"'
```

Query result is same with InfluxDB:

```json
{
  "results": [
    {
      "statement_id": 0,
      "series": [
        {
          "name": "demo",
          "columns": ["time", "field1", "field2", "tag1", "tag2"],
          "values": [
            [1679994647000, 90.0, 100.0, "t1", "t2"],
            [1679994647000, 90.0, 100.0, "t11", "t22"],
            [1679994648000, 91.0, 101.0, "t1", "t2"],
            [1679994648000, 91.0, 101.0, "t11", "t22"]
          ]
        }
      ]
    }
  ]
}
```

## Usage in Grafana

CeresDB can be used as InfluxDB data source in Grafana.

- Select InfluxDB type when add data source
- Then input `http://{ip}:{5440}/influxdb/v1/` in HTTP URL. For local deployment, URL is http://localhost:5440/influxdb/v1/
- `Save & test`

## Note

Query string parameters such as `epoch`, `db`, `pretty` aren't supported.
