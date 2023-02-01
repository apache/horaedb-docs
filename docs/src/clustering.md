# Introduction to Architecture of CeresDB Cluster

## Overview
```plaintext
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                           CeresMeta Cluster                           │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                              ▲               ▲                 ▲        
                              │               │                 │        
                              │               │                 │        
                              ▼               ▼                 ▼        
┌───────┐Route Info ┌CeresDB─────┬┬─┐ ┌CeresDB─────┬┬─┐ ┌CeresDB─────┬┬─┐
│client │◀────────▶ │  │  │TableN││ │ │  │  │TableN││ │ │  │  │TableN││ │
└───────┘Write/Query└──Shard(L)──┴┴─┘ └──Shard(F)──┴┴─┘ └──Shard(F)──┴┴─┘
                            ▲ │                 ▲               ▲        
                              │                 │               │        
                            │ Write─────────┐   ├────Sync───────┘        
                                            │   │                        
                            │     ┌────────┬▼───┴────┬──────────────────┐
              Upload/Download     │        │         │                  │
                    SST     │     │WAL     │Region N │                  │
                                  │Service │         │                  │
                            │     └────────┴─────────┴──────────────────┘
                                                                         
                            ▼                                            
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                            Object Storage                             │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

The diagram above describes the architecture of a CeresDB cluster, where some key concepts need to be explained:
- `CeresMeta Cluster`: Takes responsibilities for managing the metadata and resource scheduling of the cluster;
- `Shard(L)/Shard(F)`: Leader shard and follower shard consisting of multiple tables;
- `CeresDB`: One CeresDB instance consisting of multiple shards;
- `WAL Service`: Write-ahead log service for storing new-written real-time data;
- `Object Storage`: Object storage service for storing SST converted from memtable;

From the architecture diagram above, it can be concluded that the compute and storage are separated in the CeresDB cluster, which makes it easy to implement useful distributed features, such as elastic expansion/contraction of compute/storage resources, high availability, load balancing, and so on.

Let's dive into some of the key components mentioned above before explaining how these features are implemented.

### Shard
`Shard` is the basic scheduling unit in the cluster, which consists of a group of tables. And the tables in a shard share the same region for better storage locality in the `WAL Service`, and because of this, it is efficient to recover the data of all tables in the shard by scanning the entire WAL region. For most of implementations of `WAL Service`, without the shard concept, it costs a lot to recover the table data one by one due to massive random IO, and this case will deteriorate sharply when the number of tables grows to a certain level.

A specific role, `Leader` or `Follower`, should be assigned to a shard. A pair of leader-follower shards share the same set of tables, and the leader shard can serve the write and query requests from the client while the follower shard can only serve the read-only requests, and must synchronize the newly written data from the WAL service in order to provide the latest snapshot for data retrieval. Actually, the follower is not needed if the high availability is not required, while with at least one follower, it takes only a short time to resume service by simply switching the `Follower` to `Leader` when the CeresDB instance on which the leader shard exists crashes.

The diagram below concludes the relationship between CeresDB instance, `Shard`, `Table`. As shown in the diagram, the leader and follower shards are interleaved on the CeresDB instance.
```plaintext
┌─CeresDB Instance0──────┐     ┌─CeresDB Instance1──────┐
│  ┌─Shard0(L)────────┐  │     │  ┌─Shard0(F)────────┐  │
│  │ ┌────┬────┬────┐ │  │     │  │ ┌────┬────┬────┐ │  │
│  │ │ T0 │ T1 │ T2 │ │  │     │  │ │ T0 │ T1 │ T2 │ │  │
│  │ └────┴────┴────┘ │  │     │  │ └────┴────┴────┘ │  │
│  └──────────────────┘  │     │  └──────────────────┘  │
│                        │     │                        │
│  ┌─Shard1(F)────────┐  │     │  ┌─Shard1(L)────────┐  │
│  │ ┌────┬────┬────┐ │  │     │  │ ┌────┬────┬────┐ │  │
│  │ │ T0 │ T1 │ T2 │ │  │     │  │ │ T0 │ T1 │ T2 │ │  │
│  │ └────┴────┴────┘ │  │     │  │ └────┴────┴────┘ │  │
│  └──────────────────┘  │     │  └──────────────────┘  │
└────────────────────────┘     └────────────────────────┘
```

Since `Shard` is the basic scheduling unit, it is natural to introduce some basic shard operations:
- Create/Drop table to/from a shard;
- Open/Close a shard;
- Split one shard into two shards;
- Merge two shards into one shard;
- Switch the role of a shard;

With these basic shard operations, some complex scheduling logic can be implemented, e.g. perform an expansion by splitting one shard into two shards and migrating one of them to the new CeresDB instance.

### CeresMeta
Just like the `pd` in the TiDB, `CeresMeta` is implemented by embedding an ETCD inside to ensure consistency and takes responsibilities for cluster metadata management and scheduling.

The cluster metadata includes:
- Table information, such as table name, table ID, and which cluster the table belongs to;
- The mapping between table and shard and between shard and CeresDB instance;
- ...

As for the cluster scheduling work, it mainly includes:
- Receiving the heartbeats from the CeresDB instances and determining the online status of these registered instances;
- Assigning specific role shards to the registered CeresDB instances;
- Participating in table creation by assigning a unique table ID and the most appropriate shard to the table;
- Performing load balancing through shard operations according to the load information sent with the heartbeats;
- Performing expansion through shard operations when new instances are registered;
- Initiating failover through shard operations when old instances go offline;

### Route
In order to avoid the overhead of forwarding requests, the communication between clients and the CeresDB instances is peer-to-peer, that is to say, the client should retrieve routing information from the server before sending any specific write/query requests.

Actually, the routing information is decided by the `CeresMeta`, but clients are only allowed the access to it through the CeresDB instances rather than `CeresMeta`, to avoid potential performance issues on the `CeresMeta`.

### WAL Service & Object Storage
In the CeresDB cluster, `WAL Service` and `Object Storage` exist as separate distributed systems featured with HA, data replication and scalability. Current distributed implementations for `WAL Service` includes `Kafka` and `OBKV` (access `OceanBase` by its table api), and the implementations for `Object Storage` include popular object storage services, such as AWS S3, Azure object storage and Aliyun OSS.

The two components are similar in that they are introduced to serve as the underlying storage layer for separating compute and storage, while the difference between two components is obvious that `WAL Service` is used to store the newly written data from the real-time write requests whose individual size is small but quantity is large, and `Object Storage` is used to store the read-friendly data files (SST) organized in the background, whose individual size is large and aggregate size is much larger.

The two components make it much easier to implement the ceresdb cluster, which features horizontal scalability, high availability and load balancing.

## Scalability
Scalability is an important feature for a distributed system. Let's take a look at to how the horizontal scalability of the CeresDB cluster is achieved.

First, the two storage components should be horizontally scalable when deciding on the actual implementations for them, so the two storage services can be expanded separately if the storage capacity is not sufficient.

It will be a little bit complex when discussing the scalability of the compute service. Basically, these cases will bring the capacity problem:
- Massive queries on massive tables;
- Massive queries on a single large table;
- Massive queries on a normal table;

For the first case, it is easy to achieve horizontal scalability just by assigning shards that are created or split from old shards to expanded CeresDB instances.

For the second case, the table partitioning is proposed and after partitioning, massive queries are distributed across multiple CeresDB instances.

And the last case is the most important and the most difficult. Actually, the follower shard can handle part of the queries, but the number of follower shards is limited by the throughput threshold of the synchronization from the WAL regions. As shown in the diagram below, a pure compute shard can be introduced if the followers are not enough to handle the massive queries. Such a shard is not required to synchronize data with the leader shard, and retrieves the newly written data from the leader/follower shard only when the query comes. As for the SSTs required by the query, they will be downloaded from `Object Storage` and cached afterwards. With the two parts of the data, the compute resources are fully utilized to execute the CPU-intensive query plan. As we can see, such a shard can be added with only a little overhead (retrieving some data from the leader/follower shard when it needs), so to some extent, the horizontal scalability is achieved.

```plaintext
                                             ┌CeresDB─────┬┬─┐
                            ┌──newly written─│  │  │TableN││ │
                            ▼                └──Shard(L/F)┴┴─┘
┌───────┐  Query  ┌CeresDB─────┬┬─┐                           
│client │────────▶│  │  │TableN││ │                           
└───────┘         └──Shard─────┴┴─┘          ┌───────────────┐
                            ▲                │    Object     │
                            └───old SST──────│    Storage    │
                                             └───────────────┘
```


## High Availability
Assuming that `WAL service` and `Object Storage` are highly available, the high availability of the CeresDB cluster can be achieved by such a procedure:
- When detecting that the heartbeat is broken, `CeresMeta` determines that the CeresDB instance is offline;
- The follower shards whose paired leader shards exist on the offline instance are switched to leader shards for fast failover;
- A slow failover can be achieved by opening the crashed shards on another instance if such follower shards don't exist.

```plaintext
┌─────────────────────────────────────────────────────────┐                                             
│                                                         │                                             
│                    CeresMeta Cluster                    │                                             
│                                                         │                                             
└─────────────────────────────────────────────────────────┘                                             
                             ▲                                                                          
             ┌ ─ ─Broken ─ ─ ┤                                                                          
                             │                                                                          
             │               │                                                                          
┌ CeresDB Instance0 ─ ─ ─    │   ┌─CeresDB Instance1──────┐                   ┌─CeresDB Instance1──────┐
   ┌─Shard0(L)────────┐  │   │   │  ┌─Shard0(F)────────┐  │                   │  ┌─Shard0(L)────────┐  │
│  │ ┌────┬────┬────┐ │      │   │  │ ┌────┬────┬────┐ │  │                   │  │ ┌────┬────┬────┐ │  │
   │ │ T0 │ T1 │ T2 │ │  │   ├───│  │ │ T0 │ T1 │ T2 │ │  │                   │  │ │ T0 │ T1 │ T2 │ │  │
│  │ └────┴────┴────┘ │      │   │  │ └────┴────┴────┘ │  │                   │  │ └────┴────┴────┘ │  │
   └──────────────────┘  │   │   │  └──────────────────┘  │     Failover      │  └──────────────────┘  │
│                            │   ├─CeresDB Instance2──────┤   ───────────▶    ├─CeresDB Instance2──────┤
   ┌─Shard1(L)────────┐  │   │   │  ┌─Shard1(F)────────┐  │                   │  ┌─Shard1(L)────────┐  │
│  │ ┌────┬────┬────┐ │      │   │  │ ┌────┬────┬────┐ │  │                   │  │ ┌────┬────┬────┐ │  │
   │ │ T0 │ T1 │ T2 │ │  │   └───│  │ │ T0 │ T1 │ T2 │ │  │                   │  │ │ T0 │ T1 │ T2 │ │  │
│  │ └────┴────┴────┘ │          │  │ └────┴────┴────┘ │  │                   │  │ └────┴────┴────┘ │  │
   └──────────────────┘  │       │  └──────────────────┘  │                   │  └──────────────────┘  │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        └────────────────────────┘                   └────────────────────────┘
```

## Load Balancing
CeresMeta collects the instance load information contained in the received heartbeats to create a load overview of the whole cluster, according to which the load balancing can be implemented as an automatic mechanism:
- Pick a shard on a low-load instance for the newly created table;
- Migrate a shard from a high-load instance load to another low-load instance;
- Split the large shard on the high-load instance and migrate the split shards to other low-load instances;