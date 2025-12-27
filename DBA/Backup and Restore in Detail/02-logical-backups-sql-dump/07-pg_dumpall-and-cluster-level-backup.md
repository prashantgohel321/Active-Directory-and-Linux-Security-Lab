# pg_dumpall and Cluster-Level Backups in PostgreSQL

## In simple words

`pg_dumpall` is used to back up **the entire PostgreSQL cluster**, not just one database.

It captures:

* all databases
* all roles and users
* role memberships
* global objects

If pg_dump backs up *data*, pg_dumpall backs up the *identity of the cluster*.

---

## Why pg_dumpall exists

Backing up only databases is not enough.

Real restores fail because:

* roles do not exist
* ownership is missing
* permissions break

pg_dumpall exists to solve this by capturing **global objects**.

---

## What pg_dumpall actually backs up

pg_dumpall includes:

* CREATE ROLE statements
* role passwords (hashed)
* role memberships
* CREATE DATABASE statements
* all databases (as SQL)

It does NOT back up:

* server configuration files
* physical WAL or data files

---

## How pg_dumpall works internally

* connects as a superuser
* reads global system catalogs
* dumps roles and privileges first
* dumps each database sequentially

All output is written as **plain SQL**.

---

## Basic pg_dumpall usage

```bash
pg_dumpall > cluster_backup.sql
```

This creates one large SQL file containing everything.

---

## Role requirements (very important)

pg_dumpall **must run as a superuser**.

Reason:

* global catalogs are restricted
* role passwords and memberships require superuser access

Non-superuser runs will fail.

---

## Restoring from pg_dumpall

Restore is done using psql:

```bash
psql -f cluster_backup.sql postgres
```

What happens:

* roles are created first
* databases are created
* database contents are restored

Restore should be done on a clean cluster.

---

## Common pg_dumpall problems

* extremely large output files
* slow restore
* no parallel restore support
* hard to debug failures

Because everything is in one file, recovery is all-or-nothing.

---

## pg_dumpall vs pg_dump (real difference)

pg_dump:

* single database
* flexible formats
* selective restore

pg_dumpall:

* entire cluster
* plain SQL only
* no selective restore

They serve different purposes.

---

## When I actually use pg_dumpall

I use pg_dumpall mainly for:

* backing up roles and global objects
* disaster recovery documentation
* rebuilding a cluster from scratch

For data backups, I still prefer pg_dump.

---

## Best practice (important)

Instead of using pg_dumpall alone:

* back up databases with pg_dump
* back up roles separately with pg_dumpall --globals-only

Example:

```bash
pg_dumpall --globals-only > globals.sql
```

This gives more control during restore.

---

## Security warning

pg_dumpall output contains:

* role definitions
* password hashes

Backup files must be:

* protected
* access-controlled
* stored securely

---

## Final mental model

* pg_dump = database-level backup
* pg_dumpall = cluster identity backup
* roles matter as much as data

---

## One-line explanation (interview ready)

pg_dumpall creates a logical backup of all databases and global objects in a PostgreSQL cluster using plain SQL.
