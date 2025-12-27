# Restore from Physical Backup (Base Backup + WAL)

## In simple words

Restoring from a physical backup means:

* placing back PostgreSQL data files
* letting PostgreSQL replay WAL
* getting the database back exactly as it was

This is the **fastest and most reliable restore method** for production systems.

---

## When physical restore is the right choice

I choose physical restore when:

* database is large
* full server or disk failure occurred
* PITR is required
* fast recovery is mandatory

This is the default restore path for serious outages.

---

## What is required before starting restore

Before restoring, I make sure:

* base backup is available
* required WAL files exist
* PostgreSQL version matches
* disk space is sufficient

Missing any one of these breaks recovery.

---

## High-level physical restore flow

The restore always follows this order:

1. Stop PostgreSQL
2. Clean PGDATA
3. Restore base backup
4. Configure recovery
5. Start PostgreSQL
6. Verify data

Skipping steps causes failures.

---

## Step 1: Stop PostgreSQL

```bash
sudo systemctl stop postgresql
```

Ensure no postgres process is running.

---

## Step 2: Clean or replace PGDATA

Never restore over existing data.

```bash
rm -rf $PGDATA/*
```

A dirty PGDATA causes unpredictable behavior.

---

## Step 3: Restore base backup

Copy base backup files into PGDATA:

```bash
cp -a /backup/base/* $PGDATA/
```

Ensure:

* ownership is postgres
* permissions are preserved

---

## Step 4: Configure recovery settings

Create `recovery.signal` in PGDATA:

```bash
touch $PGDATA/recovery.signal
```

Set restore command:

```conf
restore_command = 'cp /backup/wal_archive/%f %p'
```

(Optional) set recovery target:

```conf
recovery_target_time = '2025-02-15 11:42:09'
```

---

## Step 5: Start PostgreSQL

```bash
sudo systemctl start postgresql
```

PostgreSQL will:

* enter recovery mode
* replay WAL
* stop at target or end
* create new timeline

---

## Step 6: Verify restore

Before opening to users, I verify:

* PostgreSQL logs
* critical tables
* row counts
* application sanity

Never assume restore succeeded.

---

## What happens internally during restore

Internally PostgreSQL:

* reads control files
* validates data directory
* applies WAL sequentially
* ensures transaction consistency

All of this is automatic.

---

## Common physical restore failures

* missing WAL files
* wrong restore_command
* insufficient disk space
* wrong PostgreSQL version

Most failures are operational mistakes.

---

## Physical restore vs logical restore

Physical restore:

* very fast
* exact state
* full cluster only

Logical restore:

* slow
* flexible
* partial restore possible

Choose based on incident type.

---

## Real DBA mindset

During physical restore, I:

* follow steps strictly
* do not improvise
* trust logs more than assumptions

Calm execution matters.

---

## Final mental model

* Physical backup = exact snapshot
* Restore = file copy + WAL replay
* Speed comes from skipping rebuilds
* Validation completes recovery

---

## One-line explanation (interview ready)

Restoring from a physical PostgreSQL backup involves replacing the data directory with a base backup and replaying WAL files to reach a consistent state.
