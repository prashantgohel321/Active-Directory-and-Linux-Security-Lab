# Transaction Consistency and Snapshots in PostgreSQL Backups

<br>
<br>

- [Transaction Consistency and Snapshots in PostgreSQL Backups](#transaction-consistency-and-snapshots-in-postgresql-backups)
  - [In simple words](#in-simple-words)
  - [Why transaction consistency matters](#why-transaction-consistency-matters)
  - [What a snapshot actually is](#what-a-snapshot-actually-is)
  - [How **`pg_dump`** uses snapshots](#how-pg_dump-uses-snapshots)
  - [Why users can keep working during backup](#why-users-can-keep-working-during-backup)
  - [Snapshot consistency across multiple tables](#snapshot-consistency-across-multiple-tables)
  - [Physical backups and consistency](#physical-backups-and-consistency)
  - [Why WAL is critical for consistency](#why-wal-is-critical-for-consistency)
  - [Snapshots vs filesystem snapshots](#snapshots-vs-filesystem-snapshots)
  - [Common mistake to avoid](#common-mistake-to-avoid)
  - [When I rely on snapshot-based consistency](#when-i-rely-on-snapshot-based-consistency)
  - [Final mental model](#final-mental-model)
  - [One-line explanation (interview ready)](#one-line-explanation-interview-ready)


<br>
<br>

## In simple words

- Transaction consistency means the backup represents a database state that could actually exist at one moment in time.
- Even if users are actively inserting, updating, or deleting data, the backup must not be broken or half-written.
- PostgreSQL guarantees this using **snapshots and WAL**.

---

<br>
<br>

## Why transaction consistency matters

- A database is always changing.

<br>

- At any second:
  * some transactions are committed
  * some are running
  * some are rolled back

- If a backup captures a mix of these states, restore becomes useless.

<br>

- Transaction consistency ensures:
  * no partial transactions
  * no corrupted logic
  * restored database behaves like a real past moment

---

<br>
<br>

## What a snapshot actually is

A snapshot is PostgreSQL’s internal view of the database at a specific instant.

It answers three questions:

* Which transactions are committed?
* Which transactions are still running?
* Which transactions must be ignored?

Once a snapshot is taken, PostgreSQL reads data **as if time is frozen** at that point.

---

<br>
<br>

## How **`pg_dump`** uses snapshots

- When **`pg_dump`** starts:
  * PostgreSQL creates a transaction snapshot
  * **`pg_dump`** reads all tables using that snapshot

- Even if new data is inserted after the dump starts, **`pg_dump`** does not see it.

<br>

- This guarantees that:
  * all tables match the same point in time
  * foreign keys and references remain valid

---

<br>
<br>

## Why users can keep working during backup

- **`pg_dump`** does not block reads or writes.

<br>

- It only:
  * reads committed data visible to its snapshot
  * ignores later changes

- That is why backups can run on live production systems without downtime.

---

<br>
<br>

## Snapshot consistency across multiple tables

- Snapshots ensure that relationships stay intact.

- Example:
  * order exists
  * customer exists
  * both appear consistently in the backup

- Without snapshots, one table might reflect new data while another does not.

---

<br>
<br>

## Physical backups and consistency

- Physical backups copy actual data files.

<br>

**Consistency depends on **how** the backup is taken:**

- Offline physical backup
  * PostgreSQL is stopped
  * no data changes
  * consistency is guaranteed

- Online physical backup
  * PostgreSQL is running
  * WAL records all changes
  * WAL replay fixes partial file copies

---

<br>
<br>

## Why WAL is critical for consistency

- WAL (Write-Ahead Log) records every change before it reaches data files.

<br>

- During restore:
  * PostgreSQL replays WAL
  * incomplete pages are fixed
  * database reaches a consistent state

- Without WAL, online physical backups cannot be recovered.

---

<br>
<br>

## Snapshots vs filesystem snapshots

- PostgreSQL snapshot:
  * logical view of transactions
  * used by pg_dump

- Filesystem snapshot:
  * OS or storage-level freeze
  * used for physical backups

- Both freeze time, but at different layers.

---

<br>
<br>

## Common mistake to avoid

- Copying data files while PostgreSQL is running **without WAL or snapshot support** leads to:
  * broken backups
  * failed restores
  * silent corruption

- Never mix partial file copies with live databases.

---

<br>
<br>

## When I rely on snapshot-based consistency

- I rely on snapshots when:
  * taking logical backups
  * running backups on live production
  * ensuring zero data corruption

- Snapshots are what make online backups safe.

---

<br>
<br>

## Final mental model

* Snapshot = freeze database view
* WAL = fix incomplete writes
* Logical backup = snapshot-based
* Physical online backup = WAL-based

---

<br>
<br>

## One-line explanation (interview ready)

Transaction consistency ensures a backup reflects a real, complete database state at a single point in time, achieved using snapshots and WAL.
