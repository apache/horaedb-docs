---
title: "Profiling"
---

### CPU profiling

HoraeDB provides cpu profiling http api `debug/profile/cpu`.

Example:

```
// 60s cpu sampling data
curl 0:5000/debug/profile/cpu/60

// Output file path.
/tmp/flamegraph_cpu.svg
```

### Heap profiling

HoraeDB provides heap profiling http api `debug/profile/heap`.

### Install dependencies

```
sudo yum install -y jemalloc-devel ghostscript graphviz
```

Example:

```
// enable malloc prof
export MALLOC_CONF=prof:true

// run horaedb-server
./horaedb-server ....

// 60s cpu sampling data
curl -L '0:5000/debug/profile/heap/60' > /tmp/heap_profile
jeprof --show_bytes --pdf /usr/bin/horaedb-server /tmp/heap_profile > profile_heap.pdf

jeprof --show_bytes --svg /usr/bin/horaedb-server /tmp/heap_profile > profile_heap.svg
```
