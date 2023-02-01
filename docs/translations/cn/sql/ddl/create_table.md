# 创建表

## 基础语法

建表的基础语法如下 ( `[]` 之间的内容是可选部分):
```sql
CREATE TABLE [IF NOT EXIST] 
    table_name ( column_definitions ) 
    ENGINE = engine_type 
    [WITH ( table_options )];
```

列定义的语法:

```sql
column_name column_type [[NOT] NULL] {[TAG] | [TIMESTAMP KEY] | [PRIMARY KEY]}
```

表选项的语法是键-值对，值用单引号（`'`）来引用。例如：

```sql
... WITH ( enable_ttl='false' )
```

## IF NOT EXIST

添加`IF NOT EXIST`时，CeresDB在表名已经存在时会忽略建表错误。

## 定义列

一个列的定义至少应该包含名称和类型部分，支持的类型见[这里](../model/data_types.md)。

列默认为可空，即 "NULL "关键字是隐含的；添加`NOT NULL`时列不可为空。


```sql
-- this definition
a_nullable int
-- equals to
a_nullable int NULL

-- add NOT NULL to make it required
b_not_null NOT NULL
```

定义列时可以使用相关的关键字标记列为 [特殊列](../model/special_columns.md)。

## 引擎设置

CeresDB支持指定某个表使用哪种引擎，目前支持的引擎类型为[`Analytic`](../../analytic_engine/README.md)。注意这个属性设置后不可更改。
