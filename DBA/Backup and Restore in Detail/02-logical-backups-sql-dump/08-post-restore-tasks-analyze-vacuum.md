# Post‑Restore Tasks: ANALYZE, VACUUM, and Verification

## In simple words

After a restore, the database *looks* fine but it usually **does not perform fine**.

Post‑restore tasks exist to:

* fix planner statistics
* clean internal states
* verify data correctness
* make the database production‑ready

Restore without post‑restore work is incomplete.

---

## Why performance is bad after restore

During logical restore:

* data is inserted in bulk
* indexes are rebuilt
* planner statistics are **empty or outdated**

Without fresh statistics, PostgreSQL guesses wrong plans.
That is why queries feel slow even though data is present.

---

## ANALYZE (most important step)

### What ANALYZE does

`ANALYZE` scans tables and builds statistics about:

* row counts
* data distribution
* column selectivity

The query planner depends on these stats to choose indexes.

### When I run it

Immediately after restore.

```sql
ANALYZE;
```

For large systems, this single command fixes most post‑restore issues.

---

## VACUUM after restore

### What VACUUM does

* cleans dead tuples
* updates visibility map
* helps index‑only scans

After a fresh restore, heavy VACUUM is usually **not required**,
but a light vacuum helps internal bookkeeping.

```sql
VACUUM;
```

Do **not** run aggressive VACUUM FULL right after restore.

---

## Why VACUUM FULL is dangerous

`VACUUM FULL`:

* locks tables
* rewrites data
* blocks concurrent access

After restore, it usually adds risk without benefit.
Use it only when space reclaim is required.

---

## Refreshing sequence values

After restore, sequences may become out of sync.

Check:

```sql
SELECT last_value FROM my_table_id_seq;
```

Fix if needed:

```sql
SELECT setval('my_table_id_seq', MAX(id)) FROM my_table;
```

This prevents duplicate key errors.

---

## Validating data correctness

I always verify:

* table row counts
* critical business tables
* foreign key integrity

Example:

```sql
SELECT count(*) FROM important_table;
```

Never assume restore was perfect.

---

## Checking application connectivity

Before declaring success:

* connect application users
* run basic queries
* confirm permissions

Restore is successful only if applications work.

---

## Autovacuum considerations

Autovacuum may:

* start running after restore
* consume I/O unexpectedly

In large restores:

* monitor autovacuum
* avoid tuning changes immediately

Let the system stabilize first.

---

## Logging and monitoring

After restore, I check:

* PostgreSQL logs
* error messages
* slow queries

Hidden issues appear only in logs.

---

## Common DBA mistake

Declaring restore complete after SQL finishes.

Correct mindset:

> Restore ends only after performance and correctness are verified.

---

## Final mental model

* Restore builds data
* ANALYZE builds intelligence
* VACUUM maintains health
* Verification builds confidence

---

## One‑line explanation (interview ready)

After restore, a DBA must run ANALYZE, verify data, and check system health to ensure correct performance and consistency.
