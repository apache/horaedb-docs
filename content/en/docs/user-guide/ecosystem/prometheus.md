---
title: "Prometheus"
---

[Prometheus](https://prometheus.io/) is a popular cloud-native monitoring tool that is widely adopted by organizations due to its scalability, reliability, and scalability. It is used to scrape metrics from cloud-native services, such as Kubernetes and OpenShift, and stores it in a time-series database. Prometheus is also easily extensible, allowing users to extend its features and capabilities with other databases.

HoraeDB can be used as a long-term storage solution for Prometheus. Both remote read and remote write API are supported.

## Config

You can configure Prometheus to use HoraeDB as a remote storage by adding following lines to `prometheus.yml`:

```yml
remote_write:
  - url: "http://<address>:<http_port>/prom/v1/write"
remote_read:
  - url: "http://<address>:<http_port>/prom/v1/read"
```

Each metric will be converted to one table in HoraeDB:

- labels are mapped to corresponding `string` tag column
- timestamp of sample is mapped to a timestamp `timestmap` column
- value of sample is mapped to a double `value` column

For example, `up` metric below will be mapped to `up` table:

```
up{env="dev", instance="127.0.0.1:9090", job="prometheus-server"}
```

Its corresponding table in HoraeDB(Note: The TTL for creating a table is 7d, and points written exceed TTL will be discarded directly):

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
