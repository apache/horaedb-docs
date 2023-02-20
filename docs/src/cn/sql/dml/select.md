# SELECT

## 基础语法

数据查询的基础语法如下：

```sql
SELECT select_expr [, select_expr] ...
    FROM table_name
    [WHERE where_condition]
    [GROUP BY {col_name | expr} ... ]
    [ORDER BY {col_name | expr}
    [ASC | DESC]
    [LIMIT [offset,] row_count ]
```

数据查询的语法和 mysql 类似，示例如下：

```sql
SELECT * FROM `demo` WHERE time_stamp > '2022-10-11 00:00:00' AND time_stamp < '2022-10-12 00:00:00' LIMIT 10
```
