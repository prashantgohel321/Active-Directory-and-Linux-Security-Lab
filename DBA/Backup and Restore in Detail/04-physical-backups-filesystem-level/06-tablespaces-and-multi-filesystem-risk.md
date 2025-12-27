# Tablespaces and Multi-Filesystem Risks in PostgreSQL Backups

## In simple words

Tablespaces allow PostgreSQL to store data **outside the main PGDATA directory**.

This improves flexibility and performance, but it **greatly increases backup risk** if not handled carefully.

Most broken physical backups involve tablespaces.

---

## What a tablespace really is

A tablespace is:

* a directory on disk
* located outside PGDATA
* linked internally via pg_tblspc

PostgreSQL uses tablespaces to:

* spread I/O across disks
* store large tables separately
* manage storage growth

---

## Why tablespaces complicate backups

When tablespaces exist:

* data is spread across multiple filesystems
* PGDATA alone is incomplete
* restoring only PGDATA breaks the database

Every tablespace directory is part of the physical backup.

---

## How PostgreSQL tracks tablespaces

Inside PGDATA:

* pg_tblspc contains symbolic links
* links point to external directories

If these directories are missing during restore:

* PostgreSQL fails to start

---

## Offline backup with tablespaces

For offline backups:

* stop PostgreSQL
* copy PGDATA
* copy **all tablespace directories**

Restore requires:

* same directory paths
* same ownership and permissions

Missing any tablespace is fatal.

---

## Online backup and tablespaces

For online backups:

* WAL must cover all tablespace writes
* snapshot or base backup must include every filesystem

Partial snapshots across filesystems cause corruption.

---

## Snapshot backups and ordering risk

Taking snapshots one volume at a time is dangerous.

If:

* PGDATA is snapshotted first
* tablespace disks snapshot later

Then:

* internal references mismatch
* restore may fail or corrupt

Snapshots must be:

* coordinated
* taken at the same moment

---

## Cloud snapshot pitfalls

In cloud environments:

* volumes are snapshotted independently
* snapshot timing differences matter

DBAs must ensure:

* all volumes are frozen together
* PostgreSQL backup mode is active

Cloud convenience hides real risk.

---

## Common DBA mistakes

* forgetting to back up tablespaces
* assuming pg_basebackup includes external mounts automatically
* restoring tablespaces to wrong paths
* mixing snapshots from different times

These mistakes surface only during restore.

---

## Best practices for tablespace safety

* document all tablespaces
* standardize mount points
* include tablespaces in backup scripts
* test restore with tablespaces present

Tablespaces require discipline.

---

## Final mental model

* Tablespaces live outside PGDATA
* Backups must include every filesystem
* Snapshots must be coordinated
* Restore paths must match

---

## One-line explanation (interview ready)

Tablespaces store PostgreSQL data outside PGDATA, requiring coordinated backups across multiple filesystems to avoid restore failures.
