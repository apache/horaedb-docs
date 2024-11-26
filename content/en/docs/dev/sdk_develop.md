---
title: "SDK Development"
---

## Rust

https://github.com/apache/horaedb-client-rs

First install cargo with

```bash
curl https://sh.rustup.rs -sSf | sh
```

Then build with

```bash
cargo build
```

## Python

https://github.com/apache/horaedb-client-py

### Requirements

- python 3.7+

The Python SDK rely on Rust SDK, so [cargo](https://doc.rust-lang.org/stable/cargo/getting-started/installation.html) is also required, then install build tool [maturin](https://github.com/PyO3/maturin):

```bash
pip install maturin
```

Then build Python SDK with this:

```bash
maturin build
```

## Go

https://github.com/apache/horaedb-client-go

```bash
go build ./...
```

## Java

https://github.com/apache/horaedb-client-java

### Requirements

- java 1.8
- maven 3.6.3+

```bash
mvn clean install -DskipTests=true -Dmaven.javadoc.skip=true -B -V
```
