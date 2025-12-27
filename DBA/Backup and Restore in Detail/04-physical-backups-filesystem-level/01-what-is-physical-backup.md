# What Is a Physical Backup in PostgreSQL

## In simple words

A physical backup is a **byte-by-byte copy of PostgreSQL’s data files**.

It does not rebuild the database using SQL.
It **clones the database exactly as it exists on disk**.

This is why physical backups restore much faster than logical backups.

---

## Why physical backups exist

Logical backups rebuild databases.
That is slow for large systems.

Physical backups exist to:

* restore very fast
* preserve exact on-disk state
* support point-in-time recovery (PITR)
* handle large databases reliably

At scale, physical backups become mandatory.

---

## What a physical backup actually includes

A physical backup copies:

* table and index files
* system catalogs
* visibility maps and FSM
* control files
* required WAL files

Everything under `$PGDATA` matters.

This is a **cluster-level backup**, not database-level.

---

## What physical backups do NOT include

Physical backups do not include:

* OS packages
* PostgreSQL config outside PGDATA (sometimes)
* external scripts
* monitoring tools

DBAs must back these up separately if needed.

---

## Offline vs online physical backups

### Offline physical backup

* PostgreSQL is stopped
* files are copied
* consistency is guaranteed

This is simple but causes downtime.

---

### Online physical backup

* PostgreSQL keeps running
* files are copied while users work
* WAL ensures consistency

This avoids downtime but needs careful planning.

---

## The role of WAL in physical backups

When PostgreSQL runs:

* data pages may be half-written
* files can be inconsistent during copy

WAL solves this.

During restore:

* PostgreSQL replays WAL
* fixes partial writes
* reaches a consistent state

Without WAL, online physical backups are unusable.

---

## Common tools for physical backups

* `pg_basebackup`
* filesystem snapshot tools (LVM, cloud snapshots)
* custom rsync-based scripts (carefully)

Each tool relies on WAL for safety.

---

## Why physical backups are fast to restore

Restore steps:

* place files back into PGDATA
* start PostgreSQL
* replay WAL

No table rebuilds.
No index recreation.

Speed is the biggest advantage.

---

## Limitations of physical backups

Physical backups:

* must match PostgreSQL major version
* require similar architecture
* cannot restore single tables

They trade flexibility for speed.

---

## When I use physical backups

I use physical backups when:

* database is large
* fast recovery is required
* PITR is needed
* downtime must be minimal

They are the backbone of production recovery.

---

## Final mental model

* Physical backup = exact clone
* WAL = safety net
* Restore = file copy + WAL replay
* Speed beats flexibility

---

## One-line explanation (interview ready)

A physical backup copies PostgreSQL’s data files directly and restores them quickly using WAL replay for consistency.
