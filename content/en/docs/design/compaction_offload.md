---
title: "Compaction Offload"
---

**Note: This feature is still in development.**

This chapter discusses compaction offload, which is designed to separate the compaction workload from the local horaedb nodes and delegate it to external compaction nodes.

## Overview

```plaintext
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                           HoraeMeta Cluster                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
    ▲                ▲                           |                   |
    │                │1.Fetch compaction         │(Monitor compaction│
    │                │  node  info               │node)              │
    |                │                           ▼                   ▼
┌────────────┐  ┌────────────┐              ┌────────────┐   ┌────────────┐
│            │  │            │2.Offload Task│            │   │            │
│  HoraeDB   │  │  HoraeDB   │  ─────────▶  │ Compaction │   │ Compaction │
│            │  │            │  ◀─────────  │ Node       │   │ Node       │
└────────────┘  └────────────┘ 4.Ret Result └────────────┘   └────────────┘
    |                |                            |                 |
    │  5.Update the  │                            │    3.Compact    │
    │    SSTable     │                            │                 │
    ▼                ▼                            ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                ┌─────────────────────┐  │
│                            Object Storage      │ Temporary Workspace │  │
│                                                └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

The diagram above describes the architecture of cluster for compaction offload, where some key concepts need to be explained:

- `Compaction Node`: Takes responsibility to handle offloaded compaction tasks. The compaction node receives the compaction task and performs the actual merging of SSTables, then sends back the task result to HoraeDB.
- `HoraeMeta Cluster`: HoraeMeta acts as a compaction nodes manager in the compaction offload scenario. It monitors the compaction nodes cluster and schedule the compaction nodes.

The procedure of remote compaction based above architecture diagram is:

1. HoraeDB fetchs the information of suitable compaction node from the HoraeMeta.
2. HoraeDB distributes the compaction task to the remote compaction node, according to the information fetch from HoraeMeta.
3. Compaction node executes the task and outputs compaction results to the temporary workspace.
4. Compaction node sends compaction results back to HoraeDB.
5. HoraeDB receives the result, installs the data in temporary workspace and purges compaction input files.

The architecture above makes it easy to implement some wonderful features like load balancing and high availability. Let's dive into the key components in the architecture and talking about how these features are implemented.

### Compaction Node

`Compaction Node` runs the main logic of compaction. It is implemented based on HoraeDB and distinguished by:

- `NodeType`: A config parameter used to distinguished the `HoraeDB` and `CompactionNode`. This info would be sent to HoraeMeta through heartbeat.

The compaction service is implemented as grpc service.

### HoraeMeta

`HoraeMeta` manages the compaction nodes cluster with `CompactionNodeManager`, which takes responsibilities for compaction nodes metadata management and scheduling.

The compaction nodes metadata includes:

- Compaction node information, such as node name, node state;
- A compaction node name list, used as the key to access compaction node info, for better scheduling with round-robin strategy;
- ...

As for the compaction nodes scheduling work, it mainly includes:

- Receiving the heartbeats from the compaction node and determining the online status of these registered nodes.
- Performing load balancing according to the compaction nodes cluster info.
- Providing the info of suitable compaction node for HoraeDB when remote compaction execution is needed.

## Load Balancing

Load Balancing is critical for compaction nodes cluster to make their overall processing more efficient. The effect of load balancing mainly based on the schedule algorithm for compaction nodes impl in `CompactionNodeManager`.

_(ps: The current implementation of schedule algorithm is round-robin strategy for easiness.)_

The main process for the schedule algorithm based on real load is:

- HoraeMeta collects the compaction nodes load information through the heartbeats to create a load overview of the compaction nodes cluster.
- Pick a compaction node with low load according to the load overview.

## High Availability

The fault tolerance of above architecture can be achieved by such a procedure:

- When detecting that the heartbeat is broken, `HoraeMeta` determines that the compaction node is offline.
- When `HoraeMeta` can not provide suitable compaction node for HoraeDB or compaction node doesn't return the task result successfully, HoraeDB would switches to run compaction task locally.
