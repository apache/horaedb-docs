---
title: "Table Operation"
---
## Query Table Information

Like Mysql's `information_schema.tables`, HoraeDB provides `system.public.tables` to save tables information.
Columns:

- timestamp([TimeStamp])
- catalog([String])
- schema([String])
- table_name([String])
- table_id([Uint64])
- engine([String])

### Example

Query table information via table_name like this:

```shell
curl --location --request POST 'http://localhost:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "select * from system.public.tables where `table_name`=\"my_table\""
}'
```

### Response

```json
{
    "rows":[
        {
            "timestamp":0,
            "catalog":"horaedb",
            "schema":"public",
            "table_name":"my_table",
            "table_id":3298534886446,
            "engine":"Analytic"
        }
}
```
