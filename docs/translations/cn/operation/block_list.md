# 黑名单

## 增加黑名单
如果你想限制某个表的查询，可以把表名加到`read_block_list`中。

示例如下：
```shell
curl --location --request POST 'http://localhost:5000/block' \
--header 'Content-Type: application/json' \
-d '{
    "operation":"Add",
    "write_block_list":[],
    "read_block_list":["my_table"]
}'
```

返回结果：

```json
{
  "write_block_list":[

  ],
  "read_block_list":[
    "my_table"
  ]
}
```

## 设置黑名单

设置黑名单的操作首先会清理已有的列表，然后再把新的表设置进去。

示例如下：
```shell
curl --location --request POST 'http://localhost:5000/block' \
--header 'Content-Type: application/json' \
-d '{
    "operation":"Set",
    "write_block_list":[],
    "read_block_list":["my_table1","my_table2"]
}'
```

返回结果：

```json
{
  "write_block_list":[

  ],
  "read_block_list":[
    "my_table1",
    "my_table2"
  ]
}
```

## 删除黑名单

如果你想把表从黑名单中移除，可以使用如下命令：

```shell
curl --location --request POST 'http://localhost:5000/block' \
--header 'Content-Type: application/json' \
-d '{
    "operation":"Remove",
    "write_block_list":[],
    "read_block_list":["my_table1"]
}'
```

返回结果：

```json
{
  "write_block_list":[

  ],
  "read_block_list":[
    "my_table2"
  ]
}
```