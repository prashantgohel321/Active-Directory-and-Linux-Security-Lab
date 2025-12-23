# PGSQL pg_class – Step-By-Step Real Scenario Guide (DBA Focused)

<br>
<br>

- [PGSQL pg\_class – Step-By-Step Real Scenario Guide (DBA Focused)](#pgsql-pg_class--step-by-step-real-scenario-guide-dba-focused)
  - [What is `pg_class`?](#what-is-pg_class)
  - [Scenario Overview](#scenario-overview)
  - [Step 1: A Table Is Created](#step-1-a-table-is-created)
  - [Step 2: `pg_class` Is the Object Registry](#step-2-pg_class-is-the-object-registry)
  - [Step 3: Identifying the Object](#step-3-identifying-the-object)
  - [Step 4: What Kind of Object Is This?](#step-4-what-kind-of-object-is-this)
  - [Step 5: Who Owns the Object](#step-5-who-owns-the-object)
  - [Step 6: Where the Data Lives on Disk](#step-6-where-the-data-lives-on-disk)
  - [Step 7: Table Size and Planner Estimates](#step-7-table-size-and-planner-estimates)
  - [Step 8: Visibility Map and Index-Only Scans](#step-8-visibility-map-and-index-only-scans)
  - [Step 9: TOAST Tables and Large Columns](#step-9-toast-tables-and-large-columns)
  - [Step 10: Persistence and Temporary Objects](#step-10-persistence-and-temporary-objects)
  - [Step 11: Index, Trigger, and Rule Flags](#step-11-index-trigger-and-rule-flags)
  - [Step 12: Partitions and Inheritance](#step-12-partitions-and-inheritance)
  - [Step 13: Transaction Freezing and Vacuum Safety](#step-13-transaction-freezing-and-vacuum-safety)
  - [Step 14: Access Control at Relation Level](#step-14-access-control-at-relation-level)
  - [Step 15: Why DBAs Never Modify pg\_class](#step-15-why-dbas-never-modify-pg_class)
  - [Final Understanding Through This Flow](#final-understanding-through-this-flow)

<br>
<br>

## What is `pg_class`?
- **`pg_class`** is the system catalog where PGSQL <mark><b>keeps one entry for every database object</b></mark> like tables, indexes, sequences, views, and materialized views.

**In simple words:** It’s PGSQL’s master list of objects, telling it what exists, what type it is, and where it lives (OID, tablespace, etc.).

<br>
<br>

## Scenario Overview

- A PGSQL server is running in production. Tables exist, indexes are created and dropped, queries are slow or fast, VACUUM runs, and disk usage keeps changing. PGSQL must always know **what objects exist** and **how they behave**.
- That information lives in `pg_class`.

---

<br>
<br>

## Step 1: A Table Is Created

A DBA runs:

```bash
CREATE TABLE orders (
  id bigint PRIMARY KEY,
  customer text,
  amount numeric,
  created_at timestamp
);
```

- At this moment, PGSQL registers a **relation**.
- A relation is PGSQL’s generic word for anything table-like. Tables, indexes, views, sequences, materialized views — all are relations.
- PGSQL creates **one row in **`pg_class`**** to describe this table.
- If **`pg_class`** did not exist, PGSQL would not even know that `orders` exists.

---

<br>
<br>

## Step 2: `pg_class` Is the Object Registry

- Each row in `pg_class` represents exactly one relation.

- From a DBA perspective, `pg_class` answers questions like:
  * does this table or index exist?
  * what type of object is it?
  * who owns it?
  * does it have storage on disk?
  * how big does PGSQL *think* it is?

Every query, every DDL command, and every planner decision starts by reading `pg_class`.

---

<br>
<br>

## Step 3: Identifying the Object

- PGSQL identifies relations using:
  - `relname` — the object name, like `orders`
  - `relnamespace` — the schema it belongs to

- This combination allows multiple objects with the same name in different schemas.

---

<br>
<br>

## Step 4: What Kind of Object Is This?

- `relkind` tells PGSQL what the relation actually is.

When the DBA creates different objects:

```bash
CREATE INDEX idx_orders_created ON orders(created_at);
CREATE VIEW recent_orders AS SELECT * FROM orders;
```

- PGSQL creates **new pg_class rows** with different `relkind` values.

- This is how PGSQL knows whether to:
  * scan heap pages (tables)
  * walk index trees (indexes)
  * rewrite queries (views)

- Understanding `relkind` explains why PGSQL treats tables, indexes, and views so differently.

---

<br>
<br>

## Step 5: Who Owns the Object

- When a table is created, PGSQL records ownership in `relowner`.
- Permissions, DROP commands, and ALTER commands all depend on this value.
- If a DBA cannot drop a table, the first thing PGSQL checks is `relowner` and related privileges.

---

<br>
<br>

## Step 6: Where the Data Lives on Disk

- For relations that have storage, PGSQL records a file identifier in `relfilenode`.
- This value maps the logical table name to a physical file inside the data directory.

If a table is moved to another tablespace:

```bash
ALTER TABLE orders SET TABLESPACE fast_disk;
```

- PGSQL updates the tablespace reference in `reltablespace`.
- This is how PGSQL finds the correct file on disk.

---

<br>
<br>

## Step 7: Table Size and Planner Estimates

- We should know that PGSQL doesn't count actual rows every time we run a query – that's too slow.

- Instead, it uses estimates stored in the system catalog pg_class:
    - **`relpages`**: How many disk pages PGSQL thinks the table uses (for size).
    - **`reltuples`**: How many rows PGSQL thinks the table has.

- These estimates get updated when we run:
  - ANALYZE (or VACUUM ANALYZE)
  - VACUUM (in some cases)

- **Why it matters:** The query planner uses these numbers to choose the best query plan (index scan vs full scan, join order, etc.).

- **Common problem**: If we do lots of **`INSERT`**/**`DELETE`**/**`UPDATE`** without running **`ANALYZE`**, these estimates become stale (wrong). Then queries can suddenly become slow because the planner picks bad plans based on old info.
- **Fix**: We should run **`ANALYZE table_name`**; (or **`VACUUM ANALYZE;`**) regularly, especially after big data changes.
- **Short tip**: Stale **`reltuples`**/**`relpages`** = common reason for sudden slow queries! Run **`ANALYZE`** to keep planner happy

---

<br>
<br>

## Step 8: Visibility Map and Index-Only Scans

- We can think of the visibility map as a special bitmap that PGSQL keeps for each table. It marks which pages are all-visible – meaning every row on that page is visible to all transactions (no old versions or cleanup needed).

- **`relallvisible`** in **`pg_class`** tells us how many pages are marked all-visible.

- This directly powers index-only scans:
    - An index-only scan lets PGSQL answer queries straight from the index (without touching the table/heaps) – super fast!
    - But it only works if the visibility map says the needed pages are all-visible.

Why **`VACUUM`** matters so much:
- **`VACUUM`** updates the visibility map by marking pages as all-visible when possible.
- If **`VACUUM`** isn't running regularly (or **`autovacuum`** is **`disabled`**/**`tuned`** badly), relallvisible stays low.
- Even with perfect indexes, PGSQL skips index-only scans and falls back to slower heap scans.

- **Result**: Queries become slower than they should be – even if indexes exist.

- **Short tip**: Slow queries despite good indexes? Check relallvisible and make sure VACUUM runs properly. Regular VACUUM = faster index-only scans + better performance overall!

---

<br>
<br>

## Step 9: TOAST Tables and Large Columns

- We can think of TOAST as PGSQL's way to handle big column values (like long text, bytea, jsonb) that don't fit in a normal row.
- When a row has large data:
  - PostgreSQL moves the big values out of the main table.
  - It stores them in a hidden TOAST table linked to the main table.
  - The main row keeps only a small pointer to the TOAST data.

- Key system catalog link:
    - **`reltoastrelid`** in **`pg_class`** tells us the OID of the TOAST table for a specific main table.

- Why it matters:
    - If disk usage suddenly grows a lot, we can check pg_class for the TOAST table (using **`reltoastrelid`**).
    - This shows exactly where the extra storage is coming from (e.g., too many big JSONs or images).

- **Short tip**: Unexpected bloat? Look at TOAST tables via **`reltoastrelid`** – they often hide the real space eaters!

---

<br>
<br>

## Step 10: Persistence and Temporary Objects

- `relpersistence` tells PGSQL how long the relation lives.
- Permanent tables survive restarts.
- Temporary tables vanish when the session ends.
- Unlogged tables skip WAL for speed but lose data on crash.
- This single flag explains many durability surprises.

---

<br>
<br>

## Step 11: Index, Trigger, and Rule Flags

- Flags like `relhasindex`, `relhastriggers`, and `relhasrules` tell PGSQL whether additional structures exist.
- These flags are updated lazily.
- For example, `relhasindex` may stay true even after indexes are dropped until VACUUM cleans it.
- This explains why catalog flags do not always immediately reflect reality.

---

<br>
<br>

## Step 12: Partitions and Inheritance

When tables are partitioned:

```bash
CREATE TABLE orders_2025 PARTITION OF orders ...
```

- PGSQL records partition metadata using `relispartition` and related fields.
- This allows PGSQL to route inserts and queries correctly.
- Partition problems often trace back to incorrect `pg_class` state.

---

<br>
<br>

## Step 13: Transaction Freezing and Vacuum Safety

- We can think of **`relfrozenxid`** and **`relminmxid`** in **`pg_class`** as markers that show how far VACUUM has gone in freezing old transaction IDs for each table.
    - **`relfrozenxid`**: The oldest transaction ID that still needs freezing in this table.
    - **`relminmxid`**: Similar for MultiXact IDs (used for row locking).

- Why it matters:
    - PostgreSQL uses 32-bit transaction IDs – they can wrap around after ~4 billion transactions.
    - If old unfrozen IDs lag too far, we risk transaction ID wraparound – a serious problem that can stop the database (data loss risk!).

- Autovacuum's role:
    - Autovacuum watches these values.
    - When they get too old, it triggers aggressive **`VACUUM`** to freeze rows and prevent wraparound.

- For DBAs:
    - Sudden aggressive vacuuming (high CPU/disk usage)? Check **`relfrozenxid`** and **`relminmxid`**.
    - They tell us exactly why PostgreSQL is forcing urgent cleanup.

- **Short tip**: Old **`relfrozenxid`** = danger of wraparound. Keep autovacuum running and monitor these – they keep the database safe from transaction ID disasters!

---

<br>
<br>

## Step 14: Access Control at Relation Level

- Permissions granted on tables are stored in `relacl`.
- When a query runs, PGSQL checks `relacl` before touching data.
- Unexpected permission errors often trace back to this field.

---

<br>
<br>

## Step 15: Why DBAs Never Modify pg_class

- `pg_class` is deeply interconnected with `pg_attribute`, `pg_index`, `pg_constraint`, and physical storage.
- A manual change here breaks the logical-to-physical mapping.
- This leads to corrupted reads, missing tables, or server crashes.
- All changes must happen through SQL commands.

---

<br>
<br>

## Final Understanding Through This Flow

- `pg_class` is PGSQL’s master registry of objects.
- Every table, index, view, sequence, and partition exists because `pg_class` says it exists.
- When performance degrades, disk usage looks wrong, or objects behave strangely, `pg_class` often explains why.
- For a DBA, understanding `pg_class` means understanding how PGSQL keeps track of reality.