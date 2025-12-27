# WAL Requirement and Consistency in Physical Backups

## In simple words

WAL (Write‑Ahead Log) is the **safety net** of PostgreSQL.

Without WAL, physical backups are unreliable.
With WAL, PostgreSQL can repair half‑written pages and reach a consistent state after restore.

If you remember one thing:

> **Physical backup without WAL is incomplete.**

---

## Why WAL exists

PostgreSQL never writes data pages directly and blindly.

Flow:

* change is written to WAL first
* WAL is flushed to disk
* data pages are written later

This guarantees crash safety and recovery.

---

## Why WAL is critical for physical backups

During online physical backups:

* files are copied while PostgreSQL is running
* some pages may be copied mid‑write
* data directory snapshot may look inconsistent

WAL allows PostgreSQL to:

* replay changes
* fix partial writes
* make the backup usable

Without WAL, restore may fail or corrupt data silently.

---

## What “consistency” really means

Consistency means:

* all committed transactions are present
* no partial transactions exist
* database behaves like a real point in time

WAL is what enforces this during restore.

---

## WAL and offline physical backups

When PostgreSQL is stopped:

* no writes happen
* data files are consistent

In this case:

* WAL replay is minimal
* offline backup is naturally consistent

Still, WAL files are usually included for safety.

---

## WAL and online physical backups

For online backups:

* WAL is mandatory
* PostgreSQL increases WAL generation
* full‑page writes protect torn pages

Restore without required WAL segments will fail.

---

## Required WAL for restore

To restore a physical backup, PostgreSQL needs:

* WAL up to the backup end
* WAL required for crash recovery

Missing WAL leads to:

* startup failure
* recovery abort

---

## WAL retention during backup

During backup:

* PostgreSQL prevents WAL removal
* WAL accumulates until backup completes

If disk space is insufficient:

* WAL directory can fill
* database may stop

Monitoring WAL size is mandatory.

---

## WAL archiving and physical backups

In production:

* WAL archiving is usually enabled
* archived WALs support PITR

Physical backups + archived WAL = full recovery chain.

---

## Common WAL‑related mistakes

* deleting WAL files manually
* underestimating WAL growth during backup
* assuming snapshots don’t need WAL
* restoring backup without matching WAL timeline

These cause real outages.

---

## DBA best practices

* never touch pg_wal manually
* monitor WAL growth during backups
* ensure archive destination has space
* test restore with WAL replay

---

## Final mental model

* WAL = change history
* Physical backup = file snapshot
* Restore = file copy + WAL replay
* Consistency comes from WAL

---

## One‑line explanation (interview ready)

WAL ensures physical backups can be restored to a consistent state by replaying changes and fixing incomplete writes.
