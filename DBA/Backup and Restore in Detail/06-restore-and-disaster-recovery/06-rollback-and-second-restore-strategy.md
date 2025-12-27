# Rollback and Second Restore Strategy (When First Recovery Is Not Enough)

## In simple words

Not every restore works perfectly the first time.

Sometimes:

* the wrong recovery point is chosen
* business data is still missing
* verification fails

A good DBA plans **how to roll back a restore and try again safely**.

This file explains that mindset and process.

---

## Why second restores are normal

Real-world recovery is done under pressure.

Common reasons first restore fails:

* incorrect timestamp
* timezone mismatch
* misunderstanding of incident time
* missing business validation

Doing a second restore is not failure.
It is **controlled correction**.

---

## Golden rule before any restore

> Never destroy your restore source.

Before starting the first restore, I ensure:

* base backup remains untouched
* WAL archive remains intact

This guarantees I can restore again.

---

## What rollback really means here

Rollback does NOT mean undoing the restore inside PostgreSQL.

It means:

* discarding the restored data directory
* restoring again from backup
* choosing a different recovery target

PostgreSQL recovery is not reversible once completed.

---

## Scenario: wrong PITR timestamp chosen

Example:

* Bad DELETE at 11:42:10
* DBA restores to 11:42:30 (too late)
* Deleted data is still missing

This is a common mistake.

---

## Correct rollback approach

Steps:

1. Stop PostgreSQL
2. Discard current PGDATA
3. Restore base backup again
4. Configure PITR again
5. Choose earlier recovery target
6. Start PostgreSQL

Never try to "rewind" forward from a recovered state.

---

## Why you must restore from base backup again

After PITR:

* PostgreSQL creates a new timeline
* new WAL is generated

Old WAL history diverges.

Trying to reuse recovered PGDATA:

* mixes timelines
* breaks recovery

Always start from base backup.

---

## Keeping recovery attempts safe

I always:

* copy base backup read-only
* keep WAL archive immutable during recovery
* document every attempt

This prevents accidental data loss.

---

## Deciding when to stop retrying

Multiple restores are acceptable, but not infinite.

I stop retrying when:

* correct data point is confirmed
* business signs off
* recovery objective is met

Endless retries increase risk.

---

## Communication during second restore

Very important:

* explain why another restore is needed
* give updated ETA
* clarify data-loss boundaries

Silence damages trust more than delay.

---

## Common DBA mistakes here

* deleting WAL to save space
* trying to PITR from an already recovered DB
* changing backups during restore

These permanently destroy recovery options.

---

## Real DBA mindset

A senior DBA thinks:

> “How do I preserve options?”

Not:

> “How do I finish fastest?”

Safety beats speed.

---

## Final mental model

* First restore may be wrong
* Rollback = discard and retry
* Base backup + WAL are sacred
* Options matter more than ego

---

## One-line explanation (interview ready)

A rollback or second restore strategy means safely discarding a failed recovery attempt and re-restoring from the original base backup with a corrected recovery target.
