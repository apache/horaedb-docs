# 标量函数

HoraeDB SQL 基于 [DataFusion](https://github.com/CeresDB/arrow-datafusion) 实现，支持的标量函数如下。更多详情请参考： [Datafusion](https://github.com/CeresDB/arrow-datafusion/blob/master/docs/source/user-guide/sql/scalar_functions.md)

## 数值函数

| 函数                  | 描述                         |
| --------------------- | ---------------------------- |
| abs(x)                | 绝对值                       |
| acos(x)               | 反余弦                       |
| asin(x)               | 反正弦                       |
| atan(x)               | 反正切                       |
| atan2(y, x)           | y/x 的反正切                 |
| ceil(x)               | 小于或等于参数的最接近整数   |
| cos(x)                | 余弦                         |
| exp(x)                | 指数                         |
| floor(x)              | 大于或等于参数的最接近整数   |
| ln(x)                 | 自然对数                     |
| log10(x)              | 以 10 为底的对数             |
| log2(x)               | 以 2 为底的对数              |
| power(base, exponent) | 幂函数                       |
| round(x)              | 四舍五入                     |
| signum(x)             | 根据参数的正负返回 -1、0、+1 |
| sin(x)                | 正弦                         |
| sqrt(x)               | 平方根                       |
| tan(x)                | 正切                         |
| trunc(x)              | 截断计算，取整（向零取整）   |

## 条件函数

| 函数     | 描述                                                                                                                                                  |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| coalesce | 如果它的参数中有一个不为 null，则返回第一个参数，如果所有参数均为 null，则返回 null。当从数据库中检索数据用于显示时，它经常用于用默认值替换 null 值。 |
| nullif   | 如果 value1 等于 value2，则返回 null 值；否则返回 value1。这可用于执行与 coalesce 表达式相反的操作                                                    |

## 字符函数

| 函数             | 描述                                                                                                                        |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| ascii            | 返回参数的第一个字符的 ascii 数字编码。在 UTF8 编码下，返回字符的 Unicode 码点。在其他多字节编码中，参数必须是 ASCII 字符。 |
| bit_length       | 返回字符串的比特位数。                                                                                                      |
| btrim            | 从字符串的开头和结尾删除给定字符串中的字符组成的最长字符串                                                                  |
| char_length      | 等效于 length。                                                                                                             |
| character_length | 等效于 length。                                                                                                             |
| concat           | 将两个或多个字符串合并为一个字符串。                                                                                        |
| concat_ws        | 使用给定的分隔符组合两个值。                                                                                                |
| chr              | 根据数字码返回字符。                                                                                                        |
| initcap          | 将字符串中每个单词的首字母大写。                                                                                            |
| left             | 返回字符串的指定最左边字符。                                                                                                |
| length           | 返回字符串中字符的数量。                                                                                                    |
| lower            | 将字符串中的所有字符转换为它们的小写。                                                                                      |
| lpad             | 使用特定字符集将字符串左填充到给定长度。                                                                                    |
| ltrim            | 从字符串的开头删除由字符中的字符组成的最长字符串（默认为空格）。                                                            |
| md5              | 计算给定字符串的 MD5 散列值。                                                                                               |
| octet_length     | 等效于 length。                                                                                                             |
| repeat           | 返回一个由输入字符串重复指定次数组成的字符串。                                                                              |
| replace          | 替换字符串中所有子字符串的出现为新子字符串。                                                                                |
| reverse          | 反转字符串。                                                                                                                |
| right            | 返回字符串的指定最右边字符。                                                                                                |
| rpad             | 使用特定字符集将字符串右填充到给定长度。                                                                                    |
| rtrim            | 从字符串的结尾删除包含 characters 中任何字符的最长字符串。                                                                  |
| digest           | 计算给定字符串的散列值。                                                                                                    |
| split_part       | 按指定分隔符拆分字符串，并从结果数组中返回                                                                                  |
| starts_with      | 检查字符串是否以给定字符串开始                                                                                              |
| strpos           | 搜索字符串是否包含一个给定的字符串，并返回位置                                                                              |
| substr           | 提取子字符串                                                                                                                |
| translate        | 把字符串翻译成另一种字符集 Translates one set of characters into another.                                                   |
| trim             | 移除字符串两侧的空白字符或其他指定字符。                                                                                    |
| upper            | 将字符串中的所有字符转换为它们的大写。                                                                                      |

## 正则函数

| 函数           | 描述                                   |
| -------------- | -------------------------------------- |
| regexp_match   | 判断一个字符串是否匹配正则表达式       |
| regexp_replace | 使用新字符串替换正则匹配的字符串中内容 |

## 时间函数

| 函数                 | 描述                                                  |
| -------------------- | ----------------------------------------------------- |
| to_timestamp         | 将字符串转换为 Timestamp(Nanoseconds，None)类型。     |
| to_timestamp_millis  | 将字符串转换为 Timestamp(Milliseconds，None)类型。    |
| to_timestamp_micros  | 将字符串转换为 Timestamp(Microseconds，None)类型。    |
| to_timestamp_seconds | 将字符串转换为 Timestamp(Seconds，None)类型。         |
| extract              | 从日期/时间值中检索年份或小时等子字段。               |
| date_part            | 从日期/时间值中检索子字段。                           |
| date_trunc           | 将日期/时间值截断到指定的精度。                       |
| date_bin             | 将日期/时间值按指定精度进行分组。                     |
| from_unixtime        | 将 Unix 时代转换为 Timestamp(Nanoseconds，None)类型。 |
| now                  | 作为 Timestamp(Nanoseconds，UTC)返回当前时间。        |

## 其他函数

| Function     | 描述                     |
| ------------ | ------------------------ |
| array        | 创建有一个数组           |
| arrow_typeof | 返回内置的数据类型       |
| in_list      | 检测数值是否在 list 里面 |
| random       | 生成随机值               |
| sha224       | sha224                   |
| sha256       | sha256                   |
| sha384       | sha384                   |
| sha512       | sha512                   |
| to_hex       | 转换为 16 进制           |
