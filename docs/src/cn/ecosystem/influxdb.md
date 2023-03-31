# InfluxDB

[InfluxDB](https://www.influxdata.com/products/influxdb-overview/) 是一个时间序列数据库，旨在处理高写入和查询负载。它是 TICK 堆栈的一个组成部分。InfluxDB 旨在用作涉及大量时间戳数据的任何用例的后备存储，包括 DevOps 监控、应用程序指标、物联网传感器数据和实时分析。

CeresDB 支持 [InfluxDB v1.8](https://docs.influxdata.com/influxdb/v1.8/tools/api/#influxdb-1x-http-endpoints) 写入和查询 API。

> 注意：用户需要将以下配置添加到服务器的配置中才能尝试 InfluxDB 写入/查询。

```
[server.default_schema_config]
default_timestamp_column_name = "time"
```

# 写入

```
curl -i -XPOST "http://localhost:5440/influxdb/v1/write" --data-binary '
demo,tag1=t1,tag2=t2 field1=90,field2=100 1679994647000
demo,tag1=t1,tag2=t2 field1=91,field2=101 1679994648000
demo,tag1=t11,tag2=t22 field1=90,field2=100 1679994647000
demo,tag1=t11,tag2=t22 field1=91,field2=101 1679994648000
'
```

Post 的内容采用的是 [InfluxDB line protocol](https://docs.influxdata.com/influxdb/v1.8/write_protocols/line_protocol_reference/) 格式。

`measurement` 将映射到 CeresDB 中的一个表，在首次写入时 server 会自动进行建表。

例如，在上面插入数据时，CeresDB 中将创建下表：

```
CREATE TABLE `demo` (
    `tsid` uint64 NOT NULL,
    `timestamp` timestamp NOT NULL,
    `field1` double,
    `field2` double,
    `tag1` string TAG,
    `tag2` string TAG,
    PRIMARY KEY (tsid, timestamp),
    timestamp KEY (timestamp))
```

## 注意事项

- 暂时不支持诸如 `precision`， `db` 等查询参数

# 查询

```sh
 curl -G 'http://localhost:5440/influxdb/v1/query' --data-urlencode 'q=SELECT * FROM "demo"'
```

查询结果和 InfluxDB 查询接口一致：

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

## 如何在 Grafana 中使用

CersDB 可以用作 Grafana 中的 InfluxDB 数据源。具体方式如下：

- 在新增数据源时，选择 InfluxDB 类型
- 在 HTTP URL 处，输入 `http://{ip}:{5440}/influxdb/v1/` 。对于本地部署的场景，可以直接输入 http://localhost:5440/influxdb/v1/
- `Save & test`

## 注意事项

1. 暂时不支持诸如 `epoch`, `db` 等的查询参数
2. 暂时不支持聚合查询，将在下一个版本中支持
