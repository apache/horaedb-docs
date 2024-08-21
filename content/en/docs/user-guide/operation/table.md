---
title: "Table Operation"
---

HoraeDB supports standard SQL protocols and allows you to create tables and read/write data via http requests. More [SQL](../sql/README.md)

## Create Table

### Example

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "CREATE TABLE `demo` (`name` string TAG, `value` double NOT NULL, `t` timestamp NOT NULL, TIMESTAMP KEY(t)) ENGINE=Analytic with (enable_ttl='\''false'\'')"
}'
```

## Write Data

### Example

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "INSERT INTO demo(t, name, value) VALUES(1651737067000, '\''horaedb'\'', 100)"
}'
```

## Read Data

### Example

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "select * from demo"
}'
```

## Query Table Info

### Example

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "show create table demo"
}'
```

### Drop Table

### Example

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "DROP TABLE demo"
}'
```

## Route Table

### Example

```shell
curl --location --request GET 'http://127.0.0.1:5000/route/{table_name}'
```
