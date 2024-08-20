---
title: "CREATE TABLE"
---

## Basic syntax

Basic syntax:

```sql
CREATE TABLE [IF NOT EXISTS]
    table_name ( column_definitions )
    [partition_options]
    ENGINE = engine_type
    [WITH ( table_options )];
```

Column definition syntax:

```sql
column_name column_type [[NOT] NULL] [TAG | TIMESTAMP KEY | PRIMARY KEY] [DICTIONARY] [COMMENT '']
```

Partition options syntax:

```sql
PARTITION BY KEY (column_list) [PARTITIONS num]
```

Table options syntax are key-value pairs. Value should be quoted with quotation marks (`'`). E.g.:

```sql
... WITH ( enable_ttl='false' )
```

## IF NOT EXISTS

Add `IF NOT EXISTS` to tell HoraeDB to ignore errors if the table name already exists.

## Define Column

A column's definition should at least contains the name and type parts. All supported types are listed [here](../model/data_types.md).

Column is default be nullable. i.e. `NULL` keyword is implied. Adding `NOT NULL` constrains to make it required.

```sql
-- this definition
a_nullable int
-- equals to
a_nullable int NULL

-- add NOT NULL to make it required
b_not_null NOT NULL
```

A column can be marked as [special column](../model/special_columns.md) with related keyword.

For string tag column, we recommend to define it as dictionary to reduce memory consumption:

```sql
`tag1` string TAG DICTIONARY
```

## Engine

Specifies which engine this table belongs to. HoraeDB current support `Analytic` engine type. This attribute is immutable.

## Partition Options

> Note: This feature is only supported in distributed version.

```sql
CREATE TABLE ... PARTITION BY KEY
```

Example below creates a table with 8 partitions, and partitioned by `name`:

```sql
CREATE TABLE `demo` (
    `name` string TAG COMMENT 'client username',
    `value` double NOT NULL,
    `t` timestamp NOT NULL,
    timestamp KEY (t)
)
    PARTITION BY KEY(name) PARTITIONS 8
    ENGINE=Analytic
    with (
    enable_ttl='false'
)
```
