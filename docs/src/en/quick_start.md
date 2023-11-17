# Quick Start

This page shows you how to get started with HoraeDB quickly. You'll start a standalone HoraeDB server, and then insert and read some sample data using SQL.

## Start server

[HoraeDB docker image](https://hub.docker.com/r/ceresdb/ceresdb-server) is the easiest way to get started, if you haven't installed Docker, go [there](https://www.docker.com/products/docker-desktop/) to install it first.

> Note: please choose tag version >= v1.0.0, others are mainly for testing.

You can use command below to start a standalone server

```bash
docker run -d --name horaedb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  ceresdb/ceresdb-server
```

HoraeDB will listen three ports when start:

- 8831, gRPC port
- 3307, MySQL port
- 5440, HTTP port

The easiest to use is HTTP, so sections below will use it for demo. For production environments, gRPC/MySQL are recommended.

### Customize docker configuration

Refer the command as below, you can customize the configuration of ceresdb-server in docker, and mount the data directory `/data` to the hard disk of the docker host machine.

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

## Write and read data

### Create table

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

### Write data

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
INSERT INTO demo (t, name, value)
    VALUES (1651737067000, "ceresdb", 100)
'
```

### Read data

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
SELECT
    *
FROM
    `demo`
'
```

### Show create table

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
SHOW CREATE TABLE `demo`
'
```

### Drop table

```shell
curl --location --request POST 'http://127.0.0.1:5440/sql' \
-d '
DROP TABLE `demo`
'
```

## Using the SDKs

See [sdk](./sdk/README.md)

## Next Step

Congrats, you have finished this tutorial. For more information about HoraeDB, see the following:

- [SQL Syntax](sql/README.md)
- [Deployment](cluster_deployment/README.md)
- [Operation](operation/README.md)
