# ALTER TABLE

使用 `ALTER TABLE` 可以改变表的结构和参数 .

## 变更表结构

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

## 变更表参数

例如可以使用 `MODIFY SETTING` 修改表的参数 :

```sql
-- create a table and add a column to it
CREATE TABLE `t`(a int, t timestamp NOT NULL, TIMESTAMP KEY(t)) ENGINE = Analytic;
ALTER TABLE `t` MODIFY SETTING write_buffer_size='300M';
```

上面的 SQL 用来更改 `writer_buffer` 大小，变更后的建表如下：

```sql
CREATE TABLE `t` (`tsid` uint64 NOT NULL, `t` timestamp NOT NULL, `a` int, PRIMARY KEY(tsid,t), TIMESTAMP KEY(t)) ENGINE=Analytic WITH(arena_block_size='2097152', compaction_strategy='default', compression='ZSTD', enable_ttl='true', num_rows_per_row_group='8192', segment_duration='', storage_format='AUTO', ttl='7d', update_mode='OVERWRITE', write_buffer_size='314572800')
```

除此之外，我们可以修改其 `ttl` 为 10 天：

```sql
ALTER TABLE `t` MODIFY SETTING ttl='10d';
```
