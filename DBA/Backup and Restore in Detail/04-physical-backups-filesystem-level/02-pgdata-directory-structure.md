# PGDATA Directory Structure (What Actually Gets Backed Up)

## In simple words

`$PGDATA` is the **heart of PostgreSQL**.

Every physical backup is basically a copy of this directory.
If you don’t understand what lives here, physical backups will always feel risky.

---

## What PGDATA represents

PGDATA is the directory where PostgreSQL stores:

* all databases
* system catalogs
* transaction metadata
* WAL files (or links)

When PostgreSQL starts, it reads PGDATA first.

---

## High-level layout of PGDATA

Inside PGDATA, you will usually see:

* base/
* global/
* pg_wal/
* pg_multixact/
* pg_xact/
* pg_commit_ts/
* pg_tblspc/
* postgresql.conf
* pg_hba.conf
* pg_ident.conf

Each directory has a very specific job.

---

## base/ directory (user databases)

This directory contains **actual table and index files**.

* each database has its own subdirectory
* filenames are numeric OIDs
* data is stored in 8KB pages

This is where most disk space is consumed.

---

## global/ directory (cluster metadata)

This stores cluster-wide information:

* roles
* databases list
* shared system catalogs

If global/ is missing or corrupted:

* PostgreSQL will not start

---

## pg_wal/ directory (write-ahead log)

This is the **most critical directory for recovery**.

It stores WAL segments that:

* record every data change
* ensure crash safety
* enable PITR

If pg_wal fills up:

* database can stop accepting writes

---

## pg_xact/ (transaction status)

Tracks:

* committed transactions
* aborted transactions

PostgreSQL uses this to decide which rows are visible.

Missing or corrupted pg_xact leads to data inconsistency.

---

## pg_multixact/

Used when:

* multiple transactions lock the same row

Common in systems with heavy concurrent updates.

This directory must be included in physical backups.

---

## pg_commit_ts/

Stores commit timestamps (if enabled).

Not always active, but must be backed up if present.

---

## pg_tblspc/ (tablespaces)

Contains symbolic links to tablespaces located outside PGDATA.

Important rule:

> Backing up PGDATA alone is NOT enough when tablespaces exist.

Tablespace directories must be backed up separately.

---

## Configuration files inside PGDATA

Usually includes:

* postgresql.conf
* pg_hba.conf
* pg_ident.conf

Depending on setup, these may be outside PGDATA.

Do not assume configs are always included in backups.

---

## Files you should never touch

Never manually edit:

* files inside base/
* WAL files
* transaction metadata

PostgreSQL expects full control over these.

---

## Common DBA mistake

Copying only base/ and ignoring:

* global/
* pg_wal/
* pg_xact/

This leads to broken restores.

---

## Final mental model

* PGDATA = database brain
* base = user data
* pg_wal = recovery engine
* global = cluster identity
* tablespaces need extra care

---

## One-line explanation (interview ready)

PGDATA contains all PostgreSQL data files, WAL, and metadata required for physical backup and recovery.
