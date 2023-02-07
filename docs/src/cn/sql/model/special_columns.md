# 特殊字段

CeresDB 的表的约束如下：

- 必须有主键
- 主键必须包含时间列，并且只能包含一个时间列
- 主键不可为空，并且主键的组成字段也不可为空

## Timestamp 列

CeresDB 的表必须包含一个时间戳列，对应时序数据中的时间，例如 OpenTSDB/Prometheus 的 `timestamp`。
时间戳列通过关键字 `timestamp key` 设置，例如 `TIMESTAMP KEY(ts)`。

## Tag 列

`Tag` 关键字定义了一个字段作为标签列，和时序数据中的 `tag` 类似，例如 OpenTSDB 的 `tag` 或 Prometheus 的 `label`。

## 主键

主键用于数据去重和排序，由一些列和一个时间列组成。
主键可以通过以下一些方式设置：

- 使用 `primary key` 关键字
- 使用 `tag` 来自动生成 TSID，CeresDB 默认将使用 `(TSID,timestamp)` 作为主键。
- 只设置时间戳列，CeresDB 将使用 `(timestamp)` 作为主键。

注意：如果同时指定了主键和 `Tag` 列，那么 `Tag` 列只是一个额外的信息标识，不会影响主键生成逻辑。

```sql
CREATE TABLE with_primary_key(
  ts TIMESTAMP NOT NULL,
  c1 STRING NOT NULL,
  c2 STRING NULL,
  c4 STRING NULL,
  c5 STRING NULL,
  TIMESTAMP KEY(ts),
  PRIMARY KEY(c1, ts)
) ENGINE=Analytic WITH (ttl='7d');

CREATE TABLE with_tag(
    ts TIMESTAMP NOT NULL,
    c1 STRING TAG NOT NULL,
    c2 STRING TAG NULL,
    c3 STRING TAG NULL,
    c4 DOUBLE NULL,
    c5 STRING NULL,
    c6 STRING NULL,
    TIMESTAMP KEY(ts)
) ENGINE=Analytic WITH (ttl='7d');

CREATE TABLE with_timestamp(
    ts TIMESTAMP NOT NULL,
    c1 STRING NOT NULL,
    c2 STRING NULL,
    c3 STRING NULL,
    c4 DOUBLE NULL,
    c5 STRING NULL,
    c6 STRING NULL,
    TIMESTAMP KEY(ts)
) ENGINE=Analytic WITH (ttl='7d');
```

## TSID

如果建表时没有设置主键，并且提供了 `Tag` 列，CeresDB 会自动生成一个 `TSID` 列和时间戳列作为主键。`TSID` 由所有 `Tag` 列的 hash 值生成，本质上这是一种自动生成 ID 的机制。
