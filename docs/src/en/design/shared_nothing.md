# Shared Nothing Architecture

## Background

In the [cluster architecture](./clustering.md) CeresDB's cluster solution is introduced, which can be
summarized as follows:

- Computing and storage are separated;
- Managed by a centralized metadata center that oversees the entire cluster;

However, in the architecture of computing and storage separation, an important issue is how to ensure that data in the
shared storage layer will not be corrupted due to different computing nodes accessing it during the cluster scheduling .
For example, if the same data block is updated by multiple computing nodes simultaneously, data corruption may
occur.

CeresDB's solution is to achieve a similar effect to
the [Shared-Nothing architecture](https://en.wikipedia.org/wiki/Shared-nothing_architecture) through specific mechanisms
in the
case of shared storage. This means that the data in the storage layer is partitioned according to certain rules, and
**only one CeresDB instance can update it at any given time**. This feature is defined in this article as the
**correctness of
the cluster topology**. If this correctness is ensured, data will not be damaged due to the flexible scheduling of the
cluster.

This article does not elaborate on the pros and cons of the Shared-Nothing architecture. Instead, it mainly shares how
CeresDB's cluster solution implements it (i.e. how to ensure the **correctness of the cluster
topology**) in the case of computing and storage separation.

## Data partitioning

To implement the Shared-Nothing architecture, it is necessary to partition the data logically and physically on the
shared
storage layer. The basic function of `Shard` was introduced in the previous cluster
introduction [article](./clustering.md#shard). As the basic
scheduling unit of the cluster, it is also the basic partition unit of data distribution. Different Shards correspond to
isolated data in the storage layer:

In WAL, the written Table data is organized according to Shard and written to different areas of WAL according to Shard.
The data of different Shards in WAL is isolated.
In Object Storage, data management is partitioned according to Table, and the relationship between Shard and Table is a
one-to-many relationship. That is to say, any Table belongs to only one Shard, so the data between Shards in Object
Storage is also isolated.

## Shard Lock

After the data is divided, it is necessary to ensure that at any time, only one CeresDB instance can update the data of
a shard. So how can we ensure this? Naturally, mutual exclusion can be achieved through locks, but in a distributed
cluster, we need distributed locks. Through distributed locks, when a shard is assigned to a CeresDB instance, CeresDB
must first obtain the corresponding Shard Lock to complete the opening operation of the shard. Correspondingly, when the
shard is closed, the CeresDB instance also needs to release the Shard Lock actively.

The metadata service of the CeresDB cluster, CeresMeta, is built on ETCD. It is very convenient to implement distributed
Shard Lock based on ETCD. Therefore, we choose to implement Shard Lock based on existing ETCD. The specific logic is as
follows:

Using the Shard ID as the Key of ETCD, obtaining the Shard Lock is equivalent to creating this Key.
The corresponding value can encode the address of CeresDB (used for CeresMeta scheduling).
After obtaining the Shard Lock, the CeresDB instance needs to renew it through the interface provided by ETCD to ensure
that the Shard Lock will not be released.
CeresMeta exposes the ETCD service to the CeresDB cluster to build the Shard Lock. The following figure shows the
workflow of Shard Lock. The two CeresDB instances in the figure both try to open Shard 1, but due to the existence of
Shard Lock, only one CeresDB instance can ultimately complete the opening of Shard 1.

```
             ┌────────────────────┐
             │                    │
             │                    │
             ├───────┐            │
   ┌─────┬──▶│ ETCD  │            │
   │     │   └───────┴────CeresMeta
   │     │       ▲
   │     │       └──────┬─────┐
   │     │          Rejected  │
   │     │              │     │
┌─────┬─────┐        ┌─────┬─────┐
│Shard│Shard│        │Shard│Shard│
│  0  │  1  │        │  1  │  2  │
├─────┴─────┤        ├─────┴─────┤
└─────CeresDB        └─────CeresDB
```

## Other Solutions

The Shard Lock solution essentially ensures that in a cluster, at any given moment, **there is only one CeresDB instance
that can perform update operations on any given shard**. This is achieved by using ETCD to ensure the **correctness of
the
cluster topology**. It should be noted that this guarantee actually becomes a capability provided by the CeresDB
instance (though implemented using ETCD), and CeresMeta does not need to provide this guarantee. In the following
comparison, this is a significant advantage of the Shard Lock solution.

In addition to the Shard Lock solution, we have also considered two other solutions:

### CeresMeta state synchronization

CeresMeta plans and stores the topology state of the cluster, ensures its correctness, and synchronizes the correct
topology state to CeresDB. CeresDB itself has no right to decide whether a shard can be opened. The specified shard can
only be opened after being notified by CeresMeta. In addition, CeresDB needs to continuously send heartbeats to
CeresMeta, on the one hand to report its own load information, and on the other hand to let CeresMeta know that the node
is still online to calculate the latest correct topology status.

This solution is also the one adopted by CeresDB at the beginning. The idea of this solution is simple, but it is
difficult to do well in the implementation process. The difficulty lies in that when CeresMeta executes scheduling, it
needs to make a decision based on the latest topology state. New changes are applied to the CeresDB cluster, but when
this change reaches a specific CeresDB instance and is about to take effect, the solution cannot simply guarantee that
the cluster state at this moment is still the same as the one based on the change decision The cluster state is
consistent.

Let's describe it in more precise language:

```
t0: The cluster state is S0, based on which CeresMeta calculates the change U;
t1: CeresMeta sends U to a CeresDB instance to make the change;
t2: The cluster state becomes S1;
t3: CeresDB receives U and is ready to make changes;
```

The problem with the above example is, is it correct for CeresDB to execute the change U at time t3? Will the data be
corrupted by executing this change U? This correctness requires CeresMeta to complete quite complex logic to ensure that
even when the cluster state is S1, there will be no problems in executing U changes. In addition, state rollback is also
a very troublesome process.

To give an example, you can find that the processing of this solution is more troublesome:

```
t0: CeresMeta tries to open Shard0 on CeresDB0, but CeresDB0 encounters some problems when opening Shard0, Hang is stuck, and CeresMeta can only consider the opening to fail after a timeout;
t1: CeresMeta calculates the new topology and tries to continue to open Shard0 on CeresDB1;
t2: CeresDB0 and CeresDB1 may open Shard0 at the same time;
```

Naturally, there are some ways to avoid things at time t2. For example, after a failure at time t0, it is necessary to
wait for a heartbeat cycle to know whether CeresDB0 is still trying to open Shard0, so as to avoid commands issued at
time t1, but such a logical comparison Cumbersome and difficult to maintain.

Comparing the Shard Lock scheme, it can be found that this scheme tries to achieve stronger consistency, that is, it
tries to ensure that the topology state of the cluster needs to be consistent with the cluster state in CeresMeta at any
time. Obviously, such consistency must be guaranteed The **correctness of the cluster topology**, but it is also more
complicated to implement because of this, and the scheme based on Shard Lock gives up such a known and correct cluster
topology state, and only needs to ensure that the cluster state is correct. Yes, without **knowing what this state is**.
More importantly, from another perspective, the logic of ensuring the correctness of the cluster topology is decoupled
from the scheduling of the cluster, so the logic of CeresMeta is greatly simplified, and only needs to focus on
completing the cluster scheduling work of load balancing , while the **correctness of the cluster topology** is
guaranteed
by CeresDB itself.

## CeresDB provides a consensus protocol

This solution refers to TiDB's metadata service PD. PD manages all TiKV data nodes, but PD does not need to maintain a
consistent cluster state, and it is applied to TiKV nodes, because in the TiKV cluster, each Raft Group, All can achieve
consistency, that is to say, TiKV does not need to rely on PD, and it has the ability to make the entire cluster
topology correct (one Raft Group will not have two Leaders).

Referring to this solution, in fact, we can also implement a consistency protocol between CeresDB instances, so that
they themselves have such capabilities, but introducing a consistency protocol between CeresDB seems to make things more
complicated, and it is currently not There is no more data to be synchronized, and the same effect can still be achieved
through external services (ETCD). From the perspective of CeresMeta, it is equivalent to CeresDB itself obtaining the
ability to make the cluster consistent.

Therefore, the Shard Lock scheme can be regarded as a variant of this scheme, which is a clever but practical
implementation.

## Summarize

The ultimate goal of the CeresDB distributed solution is naturally not enough to ensure that the cluster topology is
correct, but maintaining correctness is an important cornerstone of subsequent features. Once the logic of this part is
concise and clear, with sufficient theoretical guarantees, subsequent features can be implemented as well. The same
elegance and simplicity. For example, in order to make each node in the CeresDB cluster achieve load balancing effect,
CeresMeta must schedule the nodes in the cluster according to the message reported by the CeresDB instance, and the
scheduling unit must be shard, but any change of shard may Cause data damage (a shard is opened by two instances at the
same time), with the guarantee of the shard lock, CeresMeta can safely generate a scheduling plan, calculate the best
scheduling result of the current state according to the reported load information, and then Send it to the involved
CeresDB instance for execution, even if the premise of the calculation may be wrong (that is, the cluster state is
different from the state when the scheduling result is calculated), there is no need to worry about the correctness of
the cluster topology being destroyed, so CeresMeta The scheduling logic becomes concise and elegant (only needs to be
generated and executed, and does not need to consider failure handling).
