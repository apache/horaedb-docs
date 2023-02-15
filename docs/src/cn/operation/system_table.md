# 系统表

## 查询 Table 信息

类似于 Mysql's `information_schema.tables`, CeresDB 提供 `system.public.tables` 存储表信息。

`system.public.tables` 表的列如下 :

- timestamp([TimeStamp])
- catalog([String])
- schema([String])
- table_name([String])
- table_id([Uint64])
- engine([String])

通过表名查询表信息示例如下：

```shell
curl --location --request POST 'http://localhost:5000/sql' \
--header 'Content-Type: application/json' \
--header 'x-ceresdb-access-schema: my_schema' \
-d '{
    "query": "select * from system.public.tables where `table_name`=\"my_table\""
}'
```

返回结果

```json
{
    "rows":[
        {
            "timestamp":0,
            "catalog":"ceresdb",
            "schema":"monitor_trace",
            "table_name":"my_table",
            "table_id":3298534886446,
            "engine":"Analytic"
        }
}
```
