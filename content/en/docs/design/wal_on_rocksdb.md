---
title: "WAL on RocksDB"
---
## Architecture

In this section we present a standalone WAL implementation (based on RocksDB). Write-ahead logs(hereinafter referred to as logs) of tables are managed here by table, and we call the corresponding storage data structure `TableUnit`. All related data (logs or some metadata) is stored in a single column family for simplicity.

```text
            ┌───────────────────────────────┐
            │         HoraeDB               │
            │                               │
            │ ┌─────────────────────┐       │
            │ │         WAL         │       │
            │ │                     │       │
            │ │        ......       │       │
            │ │                     │       │
            │ │  ┌────────────────┐ │       │
 Write ─────┼─┼──►   TableUnit    │ │Delete │
            │ │  │                │ ◄────── │
 Read  ─────┼─┼──► ┌────────────┐ │ │       │
            │ │  │ │ RocksDBRef │ │ │       │
            │ │  │ └────────────┘ │ │       │
            │ │  │                | |       |
            │ │  └────────────────┘ │       │
            │ │        ......       │       │
            │ └─────────────────────┘       │
            │                               │
            └───────────────────────────────┘
```

## Data Model

### Common Log Format

We use the common key and value format here.
Here is the defined key format, and the following is introduction for fields in it:

- `namespace`: multiple instances of WAL can exist for different purposes (e.g. manifest also needs wal). The namespace is used to distinguish them.
- `region_id`: in some WAL implementations we may need to manage logs from multiple tables, region is the concept to describe such a set of table logs. Obviously the region id is the identification of the region.
- `table_id`: identification of the table logs to which they belong.
- `sequence_num`: each login table can be assigned an identifier, called a sequence number here.
- `version`: for compatibility with old and new formats.

```text
+---------------+----------------+-------------------+--------------------+-------------+
| namespace(u8) | region_id(u64) |   table_id(u64)   |  sequence_num(u64) | version(u8) |
+---------------+----------------+-------------------+--------------------+-------------+
```

Here is the defined value format, `version` is the same as the key format, `payload` can be understood as encoded log content.

```text
+-------------+----------+
| version(u8) | payload  |
+-------------+----------+
```

### Metadata

The metadata here is stored in the same key-value format as the log. Actually only the last flushed sequence is stored in this implementation. Here is the defined metadata key format and field instructions:

- `namespace`, `table_id`, `version` are the same as the log format.
- `key_type`, used to define the type of metadata. MaxSeq now defines that metadata of this type will only record the most recently flushed sequence in the table.
  Because it is only used in wal on RocksDB, which manages the logs at table level, so there is no region id in this key.

```text
+---------------+--------------+----------------+-------------+
| namespace(u8) | key_type(u8) | table_id(u64)  | version(u8) |
+---------------+--------------+----------------+-------------+
```

Here is the defined metadata value format, as you can see, just the `version` and `max_seq`(flushed sequence) in it:

```text
+-------------+--------------+
| version(u8) | max_seq(u64) |
+-------------+--------------+
```

## Main Process

- Open `TableUnit`:
  - Read the latest log entry of all tables to recover the next sequence numbers of tables mainly.
  - Scan the metadata to recover next sequence num as a supplement (because some table has just triggered flush and no new written logs after this, so no logs exists now).
- Write and read logs. Just write and read key-value from RocksDB.
- Delete logs. For simplicity It will remove corresponding logs synchronously.
