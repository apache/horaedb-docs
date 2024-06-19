# Rust

```
git clone https://github.com/apache/horaedb-client-rs
cargo build
```

# Python

The Python SDK rely on Rust SDK, so [cargo](https://doc.rust-lang.org/stable/cargo/getting-started/installation.html) is also required, then install build tool [maturin](https://github.com/PyO3/maturin) with

```
pip install maturin
```

Then we can build Python SDK with
```bash
git clone https://github.com/apache/horaedb-client-py

maturin build
```

# Go

```bash
git clone https://github.com/apache/horaedb-client-go

go build ./...
```

# Java

> Note: Java 1.8 is required

```bash
git clone https://github.com/apache/horaedb-client-java

mvn clean install -DskipTests=true -Dmaven.javadoc.skip=true -B -V
```
