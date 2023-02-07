# Prometheus

[Prometheus](https://prometheus.io/) is a popular cloud-native monitoring tool that is widely adopted by organizations due to its scalability, reliability, and scalability. It is used to scrape metrics from cloud-native services, such as Kubernetes and OpenShift, and stores it in a time-series database. Prometheus is also easily extensible, allowing users to extend its features and capabilities with other databases.

CeresDB can be used as a long-term storage solution for Prometheus. Both remote read and remote write API are supported.

## Config

You can configure Prometheus to use CeresDB as a remote storage by adding following lines to `prometheus.yml`:

```yml
remote_write:
  - url: "http://<address>:<http_port>/prom/v1/write"
remote_read:
  - url: "http://<address>:<http_port>/prom/v1/read"
```

Each metric will be converted to one table in CeresDB:

- labels are mapped to corresponding string tag column
- timestamp of sample is mapped to a timestamp `timestmap` column
- value of sample is mapped to a double `value` column
