---
title: "下载"
type: docs
menu:
  main:
    weight: 30
    pre: <i class='fa-solid fa-download'></i>
---

Apache HoraeDB 使用源码压缩包进行发布。

# 最新发布

最新一次发布版本：2.0.0(2024-05-23)，源码[下载地址](https://downloads.apache.org/incubator/horaedb/horaedb/v2.0.0/apache-horaedb-incubating-v2.0.0-src.tar.gz)。

用户可以按照以下指南使用 [signatures](https://downloads.apache.org/incubator/horaedb/horaedb/v2.0.0/apache-horaedb-incubating-v2.0.0-src.tar.gz.asc) 和 [checksums](https://downloads.apache.org/incubator/horaedb/horaedb/v2.0.0/apache-horaedb-incubating-v2.0.0-src.tar.gz.sha512) 验证此版本。

## Docker 镜像

暂不提供预构建好的二进制文件，用户可以使用源码[编译]({{< ref "compile_run.md" >}})或者使用 docker 镜像：

- https://hub.docker.com/r/apache/horaemeta-server
- https://hub.docker.com/r/apache/horaedb-server

## 历史版本

历史已发布版本，可以在[这里](https://downloads.apache.org/incubator/horaedb/horaedb/)查询得到。

# 验证 signatures 和 checksums

强烈建议用户验证下载的文件。

HoraeDB 为所有在下载站点上的文件提供 SHA digest 文件和 PGP 签名文件，验证文件以原始文件命名，并带有 `sha512`、`asc` 扩展名。

## 验证 Checksums

用户需要下载 `tar.gz` 文件和 `tar.gz.sha512` 文件来验证 Checksums。验证命令：

```bash
sha512sum -c apache-horaedb-incubating-v2.0.0-src.tar.gz.sha512
```

正确结果：

```
apache-horaedb-incubating-v2.0.0-src.tar.gz: OK
```

## 验证 Signatures

验证 PGP Signatures，用户需要下载 [release KEYS](https://downloads.apache.org/incubator/horaedb/KEYS) 文件。

导入下载的 KEYS 文件：

```bash
gpg --import KEYS
```

验证命令：

```bash
gpg --verify apache-horaedb-incubating-v2.0.0-src.tar.gz.asc
```

正确结果：

```
gpg: Signature made Wed 12 Jun 2024 11:05:04 AM CST using RSA key ID 08A0BAB4
gpg: Good signature from "jiacai2050@apache.org"
gpg:                 aka "Jiacai Liu <hello@liujiacai.net>"
gpg:                 aka "Jiacai Liu <dev@liujiacai.net>"
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 6F73 4AE4 297C 7F62 B605  4F91 D302 6E5C 08A0 BAB4
```
