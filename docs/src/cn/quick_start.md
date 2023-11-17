# 快速开始

本章介绍如何快速启动 HoraeDB。在这里你将会学到启动一个单机模式的 CeresDB，然后使用 SQL 写入一些数据并查询结果。

## 启动

使用 [HoraeDB docker 镜像](https://hub.docker.com/r/ceresdb/ceresdb-server) 是一种最简单的启动方式；如果你还没有安装 Docker，请首先参考 [这里](https://www.docker.com/products/docker-desktop/) 安装 Docker。

> 注意：请选择一个大于等于 v1.0.0 的 tag 镜像。

使用如下命令安装并启动一个单机版 HoraeDB。

```bash
docker run -d --name horaedb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  ceresdb/ceresdb-server
```

启动后 CeresDB 会监听如下端口：

- 8831, gRPC port
- 3307, MySQL port
- 5440, HTTP port

`HTTP` 协议是最简单的交互方式，接下来的演示会使用 `HTTP` 协议进行介绍。不过在生产环境，我们推荐使用 `gRPC/MySQL`。

### 自定义 docker 的配置

参考如下命令，可以自定义 docker 中 ceresdb-server 的配置，并把数据目录 `/data` 挂载到 docker 母机的硬盘上。

```
wget -c https://raw.githubusercontent.com/CeresDB/ceresdb/main/docs/minimal.toml -O ceresdb.toml

sed -i 's/\/tmp\/ceresdb/\/data/g' ceresdb.toml

docker run -d --name ceresdb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  -v ./ceresdb.toml:/etc/ceresdb/ceresdb.toml \
  -v ./data:/data \
  ceresdb/ceresdb-server
```

## 写入和查询数据

### 建表

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
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
-d '
INSERT INTO demo (t, name, value)
    VALUES (1651737067000, "ceresdb", 100)
'
```

### 查询

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
SELECT
    *
FROM
    `demo`
'
```

### 展示建表语句

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
SHOW CREATE TABLE `demo`
'
```

### 删除表

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
DROP TABLE `demo`
'
```

## 使用 SDK

当前我们支持多种开发语言 SDK，例如 Java，Rust，Python, Go 等, 具体使用方式请参考 [sdk](sdk/README.md)。

## 下一步

恭喜你，你已经学习了 HoraeDB 的简单使用。关于 HoraeDB 的更多信息，请参见以下内容。

- [SQL 语法](sql/README.md)
- [部署文档](cluster_deployment/README.md)
- [运维文档](operation/README.md)
