# ALTER TABLE

使用 `ALTER TABLE` 可以改变表的结构和参数 .

例如可以使用 `ADD COLUMN` 增加表的列 :

```sql
-- create a table and add a column to it
CREATE TABLE `t`(a int, t timestamp NOT NULL, TIMESTAMP KEY(t)) ENGINE = Analytic;
ALTER TABLE `t` ADD COLUMN (b string);
```

变更后的表结构如下：

```
-- DESCRIBE TABLE `t`;

name    type        is_primary  is_nullable is_tag

t       timestamp   true        false       false
tsid    uint64      true        false       false
a       int         false       true        false
b       string      false       true        false
```
