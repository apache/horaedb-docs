# 数据类型

CeresDB实现了`Table`模型，支持的数据类型和MySQL比较类似。
下列表格列出了CeresDB的数据类型和MySQL的数据类型的对应关系。

## 支持的数据类型(大小写不敏感)

| SQL            | CeresDB   |
|----------------|-----------|
| null           | Null      |
| timestamp      | Timestamp |
| double         | Double    |
| float          | Float     |
| string         | String    |
| Varbinary      | Varbinary |
| uint64         | UInt64    |
| uint32         | UInt32    |
| uint16         | UInt16    |
| uint8          | UInt8     |
| int64/bigint   | Int64     |
| int32/int      | Int32     |
| int16/smallint | Int16     |
| int8/tinyint   | Int8      |
| boolean        | Boolean   |