---
title: "Prometheus"
---

[Prometheus](https://prometheus.io/)是一个流行的云原生监控工具，由于其可扩展性、可靠性和可伸缩性，被企业广泛采用。它用于从云原生服务（如 Kubernetes 和 OpenShift）中获取指标，并将其存储在时序数据库中。Prometheus 也很容易扩展，允许用户用其他数据库扩展其特性和功能。

HoraeDB 可以作为 Prometheus 的长期存储解决方案，同时支持远程读取和远程写入 API。

## 配置

你可以通过在`prometheus.yml`中添加以下几行来配置 Prometheus 使用 HoraeDB 作为一个远程存储：

```yml
remote_write:
  - url: "http://<address>:<http_port>/prom/v1/write"
remote_read:
  - url: "http://<address>:<http_port>/prom/v1/read"
```

每一个指标都会对应一个 HoraeDB 中的表：

- 标签（labels）对应字符串类型的 `tag` 列
- 数据的时间戳对应一个 timestamp 类型的 `timestmap` 列
- 数据的值对应一个双精度浮点数类型的 `value` 列

比如有如下 Prometheus 指标：

```
up{env="dev", instance="127.0.0.1:9090", job="prometheus-server"}
```

对应 HoraeDB 中如下的表(注意：创建表的 TTL 是 7d，写入超过当前周期数据会被丢弃)：

```
CREATE TABLE `up` (
    `timestamp` timestamp NOT NULL,
    `tsid` uint64 NOT NULL,
    `env` string TAG,
    `instance` string TAG,
    `job` string TAG,
    `value` double,
    PRIMARY KEY (tsid, timestamp),
    timestamp KEY (timestamp)
);

SELECT * FROM up;
```

|         tsid         |   timestamp   | env |    instance    |        job        | value |
| :------------------: | :-----------: | :-: | :------------: | :---------------: | :---: |
| 12683162471309663278 | 1675824740880 | dev | 127.0.0.1:9090 | prometheus-server |   1   |
