# 配置项

建表时可以使用下列的选项配置引擎：

- `enable_ttl`, `bool`. 默认为 `true`，当一个表打开 TTL 能力，早于 `ttl` 的数据不会被查询到并且会被删除
- `ttl`, `duration`, 默认值为`7d`，此项定义数据的生命周期，只在 `enable_ttl` 为 `true` 的情况下使用。
- `storage_format`, `string`. 数据存储的格式，有两种可选:

  - `columnar`, 默认值
  - `hybrid`

上述两种存储格式详见 [存储格式](#存储格式) 部分.

## 存储格式

CeresDB 支持两种存储格式，一个是 `columnar`, 这是传统的列式格式，一个物理列中存储表的一个列。

```plaintext
| Timestamp | Device ID | Status Code | Tag 1 | Tag 2 |
| --------- |---------- | ----------- | ----- | ----- |
| 12:01     | A         | 0           | v1    | v1    |
| 12:01     | B         | 0           | v2    | v2    |
| 12:02     | A         | 0           | v1    | v1    |
| 12:02     | B         | 1           | v2    | v2    |
| 12:03     | A         | 0           | v1    | v1    |
| 12:03     | B         | 0           | v2    | v2    |
| .....     |           |             |       |       |
```

另一个是 `hybrid`, 当前还在实验阶段的存储格式，用于在列式存储中模拟面向行的存储，以加速经典的时序查询。

在经典的时序场景中，如 IoT 或 DevOps，查询通常会先按系列 ID（或设备 ID）分组，然后再按时间戳分组。
为了在这些场景中实现良好的性能，数据的物理布局应该与这种风格相匹配， `hybrid` 格式就是这样提出的。

```plaintext
 | Device ID | Timestamp           | Status Code | Tag 1 | Tag 2 | minTime | maxTime |
 |-----------|---------------------|-------------|-------|-------|---------|---------|
 | A         | [12:01,12:02,12:03] | [0,0,0]     | v1    | v1    | 12:01   | 12:03   |
 | B         | [12:01,12:02,12:03] | [0,1,0]     | v2    | v2    | 12:01   | 12:03   |
 | ...       |                     |             |       |       |         |         |
```

- 在一个文件中，同一个主键（例如设备 ID）的数据会被压缩到一行。
- 除了主键之外的列被分成两类：
  - `collapsible`, 这些列会被压缩成一个 list，常用于时序表中的`field`字段。
    - 注意: 当前仅支持定长的字段。
  - `non-collapsible`, 这些列只能包含一个去重值，常用于时序表中的`tag`字段。
    - 注意: 当前仅支持字符串类型
- 另外多加了两个字段，`minTime` 和 `maxTime`， 用于查询中过滤不必要的数据。
  - 注意: 暂未实现此能力.

### 示例

```sql
CREATE TABLE `device` (
    `ts` timestamp NOT NULL,
    `tag1` string tag,
    `tag2` string tag,
    `value1` double,
    `value2` int,
    timestamp KEY (ts)) ENGINE=Analytic
  with (
    enable_ttl = 'false',
    storage_format = 'hybrid'
);
```

这段语句会创建一个混合存储格式的表, 这种情况下用户可以通过 [parquet-tools](https://formulae.brew.sh/formula/parquet-tools)查看数据格式.
上面定义的表的 parquet 结构如下所示:

```
message arrow_schema {
  optional group ts (LIST) {
    repeated group list {
      optional int64 item (TIMESTAMP(MILLIS,false));
    }
  }
  required int64 tsid (INTEGER(64,false));
  optional binary tag1 (STRING);
  optional binary tag2 (STRING);
  optional group value1 (LIST) {
    repeated group list {
      optional double item;
    }
  }
  optional group value2 (LIST) {
    repeated group list {
      optional int32 item;
    }
  }
}
```
