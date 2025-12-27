# Point-in-Time Recovery (PITR) in PostgreSQL

## In simple words

Point-in-Time Recovery (PITR) allows PostgreSQL to **rewind the database to an exact moment in time**.

Instead of restoring only to the time of the last backup, PITR lets me restore to:

* a specific timestamp
* just before a bad transaction
* the last known good state

This is the **real power** of WAL archiving.

---

## Why PITR exists

Backups alone restore databases to fixed points.

Real incidents happen **between backups**:

* accidental DELETE
* bad deployment
* faulty script

PITR exists so I can recover data **without losing hours of work**.

---

## What PITR actually needs

PITR requires two things:

1. a base backup
2. continuous WAL archive

If either is missing, PITR is impossible.

---

## How PITR works (high-level flow)

1. Restore base backup
2. PostgreSQL starts in recovery mode
3. WAL files are replayed sequentially
4. Replay stops at chosen recovery point
5. Database becomes usable

Recovery is deterministic and repeatable.

---

## Choosing a recovery target

PostgreSQL allows recovery based on:

* timestamp
* transaction ID
* named restore point

Most commonly, timestamp-based recovery is used.

---

## Timestamp-based recovery example

If accident happened at `2025-02-10 11:37:00`, I recover to:

```conf
recovery_target_time = '2025-02-10 11:36:59'
```

This restores the database to just before the mistake.

---

## What happens during WAL replay

During recovery:

* WAL changes are applied
* committed transactions are replayed
* uncommitted ones are skipped

PostgreSQL ensures consistency automatically.

---

## Recovery targets and safety

Recovery stops when:

* target time is reached
* or required WAL is missing

If WAL is missing:

* recovery fails
* data loss occurs

This is why WAL retention is critical.

---

## After recovery completes

Once recovery stops:

* PostgreSQL creates a new timeline
* old WAL history is preserved
* database starts accepting writes

Recovery cannot continue past this point unless re-restored.

---

## Common PITR mistakes

* missing WAL files
* wrong recovery target
* restoring into dirty PGDATA
* forgetting to switch to new timeline

Most PITR failures are procedural errors.

---

## Testing PITR

A PITR setup must be tested:

* simulate bad deletes
* recover to a time before error
* verify data correctness

Untested PITR is false confidence.

---

## Final mental model

* Base backup = starting point
* WAL archive = full history
* PITR = controlled rewind
* Testing = real safety

---

## One-line explanation (interview ready)

Point-in-Time Recovery allows PostgreSQL to restore a database to an exact moment using a base backup and archived WAL files.
