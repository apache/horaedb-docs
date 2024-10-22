---
title: "Compile"
weight: 30
---

In order to compile HoraeDB, some relevant dependencies(including the `Rust` toolchain) should be installed.

# Dependencies

## Ubuntu

Assuming the development environment is Ubuntu20.04, execute the following command to install the required dependencies:

```shell
sudo apt install git curl gcc g++ libssl-dev pkg-config cmake protobuf-compiler
```

It should be noted that the compilation of the project requires a higher version of CMake; if your development environment is an older Linux distribution, you will need to manually install the dependencies for a higher version.

## macOS

If the development environment is MacOS, execute the following command to install the required dependencies.

1. Install command line tools:

```shell
xcode-select --install
```

2. Install cmake:

```shell
brew install cmake
```

3. Install protobuf:

```shell
brew install protobuf
```

# Rust

`Rust` can be installed by [rustup](https://rustup.rs/). After installing rustup, when entering the HoraeDB project, the specified `Rust` version will be automatically downloaded according to the rust-toolchain file.

After execution, you need to add environment variables to use the `Rust` toolchain. Basically, just put the following commands into your `~/.bashrc` or `~/.bash_profile`:

```shell
source $HOME/.cargo/env
```

# Compile and Run

Compile HoraeDB by the following command:

```
cargo build
```

Then you can run HoraeDB using the default configuration file provided in the codebase.

```bash
./target/debug/horaedb-server --config ./docs/minimal.toml
```
