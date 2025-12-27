# Snapshot-Based Backups in PostgreSQL (LVM / Cloud Snapshots)

## In simple words

Snapshot-based backup means:

* I take a **filesystem or storage snapshot**
* instead of manually copying files

The snapshot freezes disk state instantly.
PostgreSQL keeps running.

This gives **fast backups with very low downtime** — if done correctly.

---

## Why snapshot-based backups exist

Copying large data directories takes time.
Stopping PostgreSQL is often not acceptable.

Snapshots exist to:

* freeze disk state in seconds
* reduce downtime to near-zero
* back up very large databases

This is common in enterprise and cloud setups.

---

## Types of snapshots used

Snapshot backups are usually taken at:

* LVM level (on Linux)
* Cloud storage level (AWS EBS, Azure Disk, GCP PD)
* Enterprise storage arrays

PostgreSQL does not create these snapshots itself.
It cooperates with them.

---

## The BIG misconception (very important)

> A filesystem snapshot alone is **NOT** enough.

If PostgreSQL is writing data while snapshot is taken:

* files can be inconsistent
* restore may fail

Snapshots must be coordinated with PostgreSQL.

---

## Safe snapshot workflow (correct way)

### Step 1: Force WAL consistency

Before snapshot:

```sql
SELECT pg_start_backup('snapshot_backup');
```

This tells PostgreSQL:

* I am about to take a filesystem snapshot
* make sure WAL protects all in-flight changes

---

### Step 2: Take filesystem snapshot

At OS or cloud level:

* create snapshot of all data volumes
* include tablespaces if present

This operation is usually instant.

---

### Step 3: End backup mode

After snapshot:

```sql
SELECT pg_stop_backup();
```

This releases WAL pressure and marks snapshot complete.

---

## What pg_start_backup / pg_stop_backup actually do

They do NOT stop writes.

They ensure:

* full-page writes are enabled
* WAL contains enough data to fix inconsistencies
* restore can recover safely

This is why WAL size often increases during snapshot backups.

---

## Restore from snapshot backup

Restore process:

* attach snapshot volume to server
* mount filesystem
* place data directory back
* start PostgreSQL
* WAL replay fixes partial pages

Restore is usually fast.

---

## Tablespaces and snapshots

If tablespaces exist:

* snapshot **every volume**
* snapshot them **at the same time**

Missing or mismatched snapshots cause restore failure.

---

## Common snapshot mistakes

* taking snapshot without pg_start_backup
* forgetting tablespace volumes
* restoring without required WAL
* assuming crash recovery is enough

These mistakes lead to silent corruption.

---

## Snapshot vs pg_basebackup

Snapshots:

* extremely fast
* storage dependent
* more operational risk

pg_basebackup:

* slower
* PostgreSQL-managed
* safer and simpler

Senior DBAs choose based on environment maturity.

---

## When I use snapshot-based backups

I use them when:

* database is very large
* downtime must be minimal
* storage supports snapshots well
* WAL archiving is reliable

Snapshots demand discipline.

---

## Final mental model

* Snapshot freezes disk, not PostgreSQL
* WAL ensures consistency
* Coordination is mandatory
* Speed comes with responsibility

---

## One-line explanation (interview ready)

Snapshot-based backups use filesystem or storage snapshots coordinated with PostgreSQL WAL to enable fast, low-downtime physical backups.
