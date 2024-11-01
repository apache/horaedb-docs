---
title: "编译"
weight: 10
---

为了编译 HoraeDB, 首先需要安装相关的依赖（包括 `Rust` 的工具链)。

# 依赖

## Ubuntu

假设我们的开发环境是 Ubuntu20.04, 可以执行如下命令来安装所需的依赖。

```shell
sudo apt install git curl gcc g++ libssl-dev pkg-config protobuf-compiler
```

## macOS

如果你的开发环境是 `MacOS` ，可以使用如下命令手动安装这些依赖项的高版本。

1. 安装命令行工具：

```shell
xcode-select --install
```

2. 安装 protobuf:

```shell
brew install protobuf
```

# Rust

`Rust` 可以使用 [rustup](https://rustup.rs/) 来安装。
安装 `Rust` 后，进入 HoraeDB 工程目录，根据工具链文件指定的 `Rust` 版本会被自动下载。

执行后，你需要添加环境变量来使用 `Rust` 工具链。只要把下面的命令放到你的`~/.bashrc`或`~/.bash_profile`中即可。

```shell
source $HOME/.cargo/env
```

# 编译运行

编译 HoraeDB 命令如下:

```
cargo build
```

然后可以使用特定的配置文件运行 HoraeDB。

```bash
./target/debug/horaedb-server --config ./docs/minimal.toml
```

# 常见问题

在 macOS 上编译时，可能会遇到下面的错误：

```
IO error: while open a file for lock: /var/folders/jx/grdtrdms0zl3hy6zp251vjh80000gn/T/.tmpmFOAF9/manifest/LOCK: Too many open files

or

error: could not compile `regex-syntax` (lib)
warning: build failed, waiting for other jobs to finish...
LLVM ERROR: IO failure on output stream: File too large
error: could not compile `syn` (lib)

```

可以通过下面的命令来解决：

```bash
ulimit -n unlimited
ulimit -f unlimited
```
