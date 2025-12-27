# Restore with PITR (Physical Restore + Time Rewind)

## In simple words

Restoring with PITR means:

* restore a physical base backup
* replay WAL files
* **stop at an exact chosen moment**

This is the safest way to recover from **human mistakes** like bad DELETEs or updates.

---

## When PITR restore is the right decision

I choose PITR restore when:

* bad data was **committed**
* database is otherwise healthy
* exact recovery moment is known
* WAL archiving is available

If WAL is missing, PITR is impossible.

---

## What PITR restore needs (checklist)

Before starting, I confirm:

* last base backup exists
* WAL archive is complete
* timestamps are accurate
* recovery target is decided

Skipping this thinking causes wrong recovery.

---

## High‑level PITR restore flow

1. Stop PostgreSQL
2. Restore base backup
3. Enable recovery mode
4. Configure restore_command
5. Set recovery target
6. Start PostgreSQL
7. Verify data

Each step has a purpose.

---

## Step 1: Stop PostgreSQL

```bash
sudo systemctl stop postgresql
```

Ensure no postgres processes remain.

---

## Step 2: Restore base backup

```bash
rm -rf $PGDATA/*
cp -a /backup/base/* $PGDATA/
```

Always restore into a clean PGDATA.

---

## Step 3: Enable recovery mode

Create recovery signal file:

```bash
touch $PGDATA/recovery.signal
```

This tells PostgreSQL to enter PITR.

---

## Step 4: Configure restore_command

In `postgresql.conf`:

```conf
restore_command = 'cp /backup/wal_archive/%f %p'
```

PostgreSQL will fetch WAL files using this command.

---

## Step 5: Set recovery target

### Time‑based recovery (most common)

```conf
recovery_target_time = '2025-02-15 11:42:09'
```

Choose a time **just before** the mistake.

---

## Step 6: Start PostgreSQL

```bash
sudo systemctl start postgresql
```

PostgreSQL will:

* start in recovery
* replay WAL sequentially
* stop at target time
* create a new timeline

---

## Step 7: Verify recovered data

Before opening access:

* check critical tables
* confirm deleted data exists
* review PostgreSQL logs

Recovery success ≠ business success.

---

## What happens internally during PITR

Internally PostgreSQL:

* applies committed WAL records
* skips uncommitted transactions
* enforces consistency
* freezes history at recovery target

Everything is deterministic.

---

## Common PITR restore mistakes

* choosing wrong timestamp
* timezone mismatch
* missing WAL file
* restoring into dirty PGDATA

Most PITR failures are human mistakes.

---

## Real DBA mindset

During PITR restore, I:

* move slowly
* trust logs
* verify before reopening

One wrong second can change outcome.

---

## Final mental model

* Base backup = starting line
* WAL = full timeline
* PITR = controlled rewind
* New timeline = safe future

---

## One‑line explanation (interview ready)

Restoring with PITR replays archived WAL on top of a base backup and stops at a chosen moment to undo committed mistakes safely.
