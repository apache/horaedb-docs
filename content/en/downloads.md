---
title: "Downloads"
type: docs
menu:
  main:
    weight: 30
    pre: <i class='fa-solid fa-download'></i>
---

## Server

Apache HoraeDB server is released as source code tarballs with corresponding docker images for convenience.

### The latest release

The latest release is 2.1.0(2024-11-18), the source code can be downloaded [here](https://downloads.apache.org/incubator/horaedb/horaedb/v2.1.0/apache-horaedb-incubating-v2.1.0-src.tar.gz).

Verify this release using the [signatures](https://downloads.apache.org/incubator/horaedb/horaedb/v2.1.0/apache-horaedb-incubating-v2.1.0-src.tar.gz.asc), [checksums](https://downloads.apache.org/incubator/horaedb/horaedb/v2.1.0/apache-horaedb-incubating-v2.1.0-src.tar.gz.sha512) by following guides below.

### Docker images

Pre-built binaries are not provided yet, users can [compile from source]({{< ref "compile_run.md" >}}) or using docker images:

- https://hub.docker.com/r/apache/horaemeta-server
- https://hub.docker.com/r/apache/horaedb-server

### All archived releases

For older releases, please check the [archive](https://downloads.apache.org/incubator/horaedb/horaedb/).

## Client

### Rust

The latest rust client version is v2.0.0(2024-07-11), source codes can be downloaded [here](https://downloads.apache.org/incubator/horaedb/horaedb-client-rust/v2.0.0/apache-horaedb-incubating-rust-client-v2.0.0-src.tar.gz), release note is [here](https://github.com/apache/horaedb-client-rs/releases/tag/v2.0.0).

Verify this release using the [signatures](https://downloads.apache.org/incubator/horaedb/horaedb-client-rust/v2.0.0/apache-horaedb-incubating-rust-client-v2.0.0-src.tar.gz.asc), [checksums](https://downloads.apache.org/incubator/horaedb/horaedb-client-rust/v2.0.0/apache-horaedb-incubating-rust-client-v2.0.0-src.tar.gz.sha512) by following guides below.

It's also available on [crates.io](https://crates.io/crates/horaedb-client).

### Python

The latest python client version is v2.0.0(2024-12-10), source codes can be downloaded [here](https://downloads.apache.org/incubator/horaedb/horaedb-client-python/v2.0.0/apache-horaedb-incubating-python-client-v2.0.0-src.tar.gz), release note is [here](https://github.com/apache/horaedb-client-py/releases/tag/v2.0.0).

Verify this release using the [signatures](https://downloads.apache.org/incubator/horaedb/horaedb-client-python/v2.0.0/apache-horaedb-incubating-python-client-v2.0.0-src.tar.gz.asc), [checksums](https://downloads.apache.org/incubator/horaedb/horaedb-client-python/v2.0.0/apache-horaedb-incubating-python-client-v2.0.0-src.tar.gz.sha512) by following guides below.

It's also available on [pypi.org](https://pypi.org/project/horaedb-client/).

## Verify signatures and checksums

It's highly recommended to verify the files that you download.

HoraeDB provides SHA digest and PGP signature files for all the files that we host on the download site. These files are named after the files they relate to but have `sha512`, `asc` extensions.

### Verify Checksums

To verify the SHA digests, you need the `tar.gz` and its associated `tar.gz.sha512` files. An example command:

```bash
sha512sum -c apache-horaedb-incubating-v2.0.0-src.tar.gz.sha512
```

It should output something like:

```
apache-horaedb-incubating-v2.0.0-src.tar.gz: OK
```

### Verify Signatures

To verify the PGP signatures, you will need to download the [release KEYS](https://downloads.apache.org/incubator/horaedb/KEYS) first.

Then import the downloaded KEYS:

```bash
gpg --import KEYS
```

Then you can verify signature:

```bash
gpg --verify apache-horaedb-incubating-v2.0.0-src.tar.gz.asc
```

It should output something like:

```
gpg: Signature made Wed 12 Jun 2024 11:05:04 AM CST using RSA key ID 08A0BAB4
gpg: Good signature from "jiacai2050@apache.org"
gpg:                 aka "Jiacai Liu <hello@liujiacai.net>"
gpg:                 aka "Jiacai Liu <dev@liujiacai.net>"
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 6F73 4AE4 297C 7F62 B605  4F91 D302 6E5C 08A0 BAB4
```
