# 表操作

HoraeDB 支持标准的 SQL，用户可以使用 Http 协议创建表和读写表。更多内容可以参考 [SQL 语法](../sql/README.md)

## 创建表

示例如下

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "CREATE TABLE `demo` (`name` string TAG, `value` double NOT NULL, `t` timestamp NOT NULL, TIMESTAMP KEY(t)) ENGINE=Analytic with (enable_ttl='\''false'\'')"
}'
```

## 写数据

示例如下

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "INSERT INTO demo(t, name, value) VALUES(1651737067000, '\''ceresdb'\'', 100)"
}'
```

## 读数据

示例如下

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "select * from demo"
}'
```

## 查询表信息

示例如下

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "show create table demo"
}'
```

### Drop 表

示例如下

```shell
curl --location --request POST 'http://127.0.0.1:5000/sql' \
--header 'Content-Type: application/json' \
-d '{
    "query": "DROP TABLE demo"
}'
```

## 查询表路由

示例如下

```shell
curl --location --request GET 'http://127.0.0.1:5000/route/{table_name}'
```
