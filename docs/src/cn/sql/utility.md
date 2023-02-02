# 常用 SQL

CeresDB 中有许多实用的 SQL 工具，可以帮助进行表操作或查询检查。

## 查看建表语句

```sql
SHOW CREATE TABLE table_name;
```

`SHOW CREATE TABLE` 返回指定表的当前版本的创建语句，包括列定义、表引擎和参数选项等。例如：
```sql
-- create one table
CREATE TABLE `t` (a bigint, b int default 3, c string default 'x', d smallint null, t timestamp NOT NULL, TIMESTAMP KEY(t)) ENGINE = Analytic;
-- Result: affected_rows: 0

-- show how one table should be created.
SHOW CREATE TABLE `t`;

-- Result DDL:
CREATE TABLE `t` (
    `t` timestamp NOT NULL,
    `tsid` uint64 NOT NULL,
    `a` bigint,
    `b` int,
    `c` string,
    `d` smallint,
    PRIMARY KEY(t,tsid),
    TIMESTAMP KEY(t)
) ENGINE=Analytic WITH (
    arena_block_size='2097152',
    compaction_strategy='default',
    compression='ZSTD',
    enable_ttl='true',
    num_rows_per_row_group='8192',
    segment_duration='',
    ttl='7d',
    update_mode='OVERWRITE',
    write_buffer_size='33554432'
)
```

## 查看表信息

```sql
DESCRIBE table_name;
```

`DESCRIBE` 语句返回一个表的详细结构信息，包括每个字段的名称和类型，字段是否为 `Tag` 或主键，字段是否可空等。
此外，自动生成的字段 `tsid` 也会展示在结果里。

例如 :

```sql
CREATE TABLE `t`(a int, b string, t timestamp NOT NULL, TIMESTAMP KEY(t)) ENGINE = Analytic;

DESCRIBE TABLE `t`;
```

返回结果如下 :
```
name    type        is_primary  is_nullable is_tag

t       timestamp   true        false       false
tsid    uint64      true        false       false
a       int         false       true        false
b       string      false       true        false
```

## 解释执行计划

```sql
EXPLAIN query;
```

`EXPLAIN` 语句结果展示一个查询如何被执行。例如：

```sql
EXPLAIN SELECT max(value) AS c1, avg(value) AS c2 FROM `t` GROUP BY name;
```

结果如下：

```
logical_plan
Projection: #MAX(07_optimizer_t.value) AS c1, #AVG(07_optimizer_t.value) AS c2
  Aggregate: groupBy=[[#07_optimizer_t.name]], aggr=[[MAX(#07_optimizer_t.value), AVG(#07_optimizer_t.value)]]
    TableScan: 07_optimizer_t projection=Some([name, value])

physical_plan
ProjectionExec: expr=[MAX(07_optimizer_t.value)@1 as c1, AVG(07_optimizer_t.value)@2 as c2]
  AggregateExec: mode=FinalPartitioned, gby=[name@0 as name], aggr=[MAX(07_optimizer_t.value), AVG(07_optimizer_t.value)]
    CoalesceBatchesExec: target_batch_size=4096
      RepartitionExec: partitioning=Hash([Column { name: \"name\", index: 0 }], 6)
        AggregateExec: mode=Partial, gby=[name@0 as name], aggr=[MAX(07_optimizer_t.value), AVG(07_optimizer_t.value)]
          ScanTable: table=07_optimizer_t, parallelism=8, order=None
```