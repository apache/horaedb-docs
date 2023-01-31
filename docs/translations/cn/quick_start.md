# 快速开始
本章介绍如何快速启动CeresDB。在这里你将会学到启动一个单机模式的CeresDB，然后使用SQL写入一些数据并查询查询处理。

## 启动

使用[CeresDB docker 镜像](https://hub.docker.com/r/ceresdb/ceresdb-server) 是一种最简单的启动方式；如果你还没有一个安装Docker，请首先参考 [这里](https://www.docker.com/products/docker-desktop/) 安装Docker.

使用如下命令安装并启动一个单机版CeresDB。
```bash
docker run -d --name ceresdb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  ceresdb/ceresdb-server:v0.3.1
```

启动后CeresDB会监听如下端口:
- 8831, gRPC port
- 3307, MySQL port
- 5440, HTTP port

`HTTP`协议是最简单的交互方式，接下来的演示会使用`HTTP`协议进行介绍。不过在生产环境，我们推荐使用`gRPC/MySQL`.

## 写入和查询数据

### 建表
```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
--data-raw '
CREATE TABLE `demo` (
    `name` string TAG,
    `value` double NOT NULL,
    `t` timestamp NOT NULL,
    timestamp KEY (t))
ENGINE=Analytic
  with
(enable_ttl="false")
'
```

### 写数据
```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
--data-raw '
INSERT INTO demo (t, name, value)
    VALUES (1651737067000, "ceresdb", 100)
'
```

### 查询
```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
--data-raw '
SELECT
    *
FROM
    `demo`
'
```

### 展示建表语句
```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
--data-raw '
SHOW CREATE TABLE `demo`
'
```

### 删除表
```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
--data-raw '
DROP TABLE `demo`
'
```

## 使用SDK

当前我们支持多种开发语言SDK，例如Java，Rust，Python, Go等,具体使用请参考 [sdk](./sdk.md)

## 下一步

恭喜你，你已经学习了CeresDB的简单使用。关于CeresDB的更多信息，请参见以下内容。
- [SQL语法](sql/README.md)
- [部署文档](deploy/README.md)
- [运维文档](operation/README.md)
