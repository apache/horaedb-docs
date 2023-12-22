## 剖析

### CPU 剖析

HoraeDB 提供 CPU 剖析 http 接口 `debug/profile/cpu`.

例子:

```
// 60s CPU 采样数据
curl 0:5000/debug/profile/cpu/60

// 产出文件
/tmp/flamegraph_cpu.svg
```

### 内存剖析

HoraeDB 提供内存剖析 http 接口 `debug/profile/heap`.

### 安装依赖

```
sudo yum install -y jemalloc-devel ghostscript graphviz
```

例子:

```
// 开启 malloc prof
export MALLOC_CONF=prof:true

// 运行 horaedb-server
./horaedb-server ....

// 60s 内存采样数据
curl -L '0:5000/debug/profile/heap/60' > /tmp/heap_profile
jeprof --show_bytes --pdf /usr/bin/horaedb-server /tmp/heap_profile > profile_heap.pdf

jeprof --show_bytes --svg /usr/bin/horaedb-server /tmp/heap_profile > profile_heap.svg
```
