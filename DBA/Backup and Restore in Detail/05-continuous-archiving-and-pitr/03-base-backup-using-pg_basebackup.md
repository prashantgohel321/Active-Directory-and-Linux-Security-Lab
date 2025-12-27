# Base Backup Using pg_basebackup (Foundation of PITR)

## In simple words

A base backup is a **physical snapshot of the entire PostgreSQL cluster** that acts as the starting point for recovery.

`pg_basebackup` is the official PostgreSQL tool to take this backup safely while the database is running.

Without a base backup, WAL archiving alone is useless.

---

## Why base backup is required

WAL files only store **changes**.
They do not store the starting data.

To recover a database, PostgreSQL needs:

1. a base backup (starting line)
2. WAL files (change history)

Base backup + WAL = full recovery chain.

---

## What pg_basebackup actually does

pg_basebackup:

* connects to PostgreSQL as a replication client
* copies the entire data directory
* ensures consistency using WAL
* optionally streams WAL during backup

It is WAL-aware by design.

---

## Role and permission requirements

pg_basebackup requires:

* superuser, or
* role with REPLICATION and BACKUP privileges

A normal database user cannot take a base backup.

---

## Basic pg_basebackup command

```bash
pg_basebackup -D /backup/base -Fp -X stream -P
```

Meaning:

* `-D` → destination directory
* `-Fp` → plain file format
* `-X stream` → stream WAL during backup
* `-P` → show progress

This creates a consistent physical backup.

---

## WAL handling during base backup

Two common options:

### Stream WAL (recommended)

```bash
-X stream
```

* WAL is streamed live
* safest option
* avoids missing WAL segments

---

### Fetch WAL after backup

```bash
-X fetch
```

* WAL is copied after data files
* riskier if WAL is recycled too fast

Streaming is preferred in production.

---

## Compression and performance

pg_basebackup supports compression:

```bash
pg_basebackup -D /backup/base -Fp -X stream -Z 9
```

Higher compression:

* reduces disk usage
* increases CPU load

Balance based on system capacity.

---

## Using tar format

```bash
pg_basebackup -D /backup/base -Ft -X stream
```

Tar format:

* creates archive files
* easier to move
* slower to extract during restore

---

## Impact on running database

During pg_basebackup:

* read I/O increases
* WAL generation increases
* archive pressure rises

This must be monitored on production systems.

---

## Restoring from a base backup

Restore steps:

* stop PostgreSQL
* clean or replace PGDATA
* copy base backup into place
* configure recovery settings
* start PostgreSQL

WAL replay completes the restore.

---

## Common pg_basebackup mistakes

* running without WAL streaming
* insufficient disk space
* wrong permissions on destination
* forgetting tablespaces

Base backups must be tested.

---

## When I use pg_basebackup

I use it when:

* PITR is required
* physical backups are primary recovery
* downtime must be minimal

It is the backbone of serious recovery setups.

---

## Final mental model

* Base backup = starting snapshot
* pg_basebackup = safe physical copier
* WAL streaming = consistency guarantee
* Restore = base + WAL replay

---

## One-line explanation (interview ready)

pg_basebackup takes a consistent physical snapshot of a PostgreSQL cluster, forming the base for WAL-based recovery and PITR.
