# INSERT

## 基础语法

写入数据的基础语法如下:

```sql
INSERT [INTO] tbl_name
    [(col_name [, col_name] ...)]
    { {VALUES | VALUE} (value_list) [, (value_list)] ... }
```

写入一行数据的示例如下:

```sql
INSERT INTO demo(`time_stammp`, tag1) VALUES(1667374200022, 'ceresdb')
```
