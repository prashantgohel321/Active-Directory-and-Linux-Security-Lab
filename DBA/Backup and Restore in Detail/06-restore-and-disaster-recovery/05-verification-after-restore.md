# Verification After Restore (How a DBA Confirms Recovery Is Really Successful)

## In simple words

Starting PostgreSQL after a restore **does NOT mean recovery is complete**.

A database can start and still be:

* missing data
* logically broken
* inconsistent for applications

Verification is where a DBA proves:

> “Yes, this database is safe to use.”

---

## Why verification is critical

Many incidents fail **after** restore because:

* data is partially restored
* wrong recovery point was chosen
* application assumptions are broken

A restore without verification is blind trust.

---

## First check: PostgreSQL startup status

I always check:

* PostgreSQL logs
* recovery completion messages
* timeline switch confirmation

I want to see:

* recovery ended cleanly
* no PANIC or FATAL errors

Logs are the first truth.

---

## Second check: database accessibility

I verify:

* database accepts connections
* expected databases are present
* basic queries work

Example:

```sql
SELECT now();
```

Simple queries confirm engine stability.

---

## Third check: critical schema and tables

I confirm:

* important schemas exist
* critical tables are present
* table counts look reasonable

Example:

```sql
\dt important_schema.*
```

Missing tables = failed restore.

---

## Fourth check: data sanity (most important)

This is business-focused verification.

I verify:

* row counts in critical tables
* recently deleted or corrupted data
* known reference records

This confirms **logical correctness**, not just physical recovery.

---

## Fifth check: sequence correctness

After restore, sequences may be behind.

I check:

* auto-increment IDs
* next sequence values

Example:

```sql
SELECT last_value FROM my_table_id_seq;
```

Wrong sequences cause duplicate key errors later.

---

## Sixth check: application-level behavior

Before opening traffic:

* start application in read-only or limited mode
* test key workflows
* validate expected outputs

DB-only validation is not enough.

---

## Seventh check: performance readiness

After restore, I:

* run ANALYZE
* monitor slow queries
* check execution plans

Restored DB without stats feels broken.

---

## Eighth check: replication and WAL state (if applicable)

If replicas exist:

* check replication slots
* verify streaming resumes
* confirm no excessive lag

Restore can silently break replication.

---

## Ninth check: backup and PITR continuity

After restore, I ensure:

* WAL archiving is working
* new backups will succeed
* PITR chain is intact

A restored DB without future recovery is risky.

---

## Common verification mistakes

* assuming startup means success
* skipping business validation
* forgetting sequences
* opening application too early

Most post-restore issues start here.

---

## Real DBA mindset

A DBA does not ask:

> “Did PostgreSQL start?”

A DBA asks:

> “Is the system safe for users?”

Verification is responsibility, not formality.

---

## Final mental model

* Restore = technical recovery
* Verification = confidence
* Data correctness > uptime
* Calm checking saves incidents

---

## One-line explanation (interview ready)

Post-restore verification ensures PostgreSQL is not only running but also data-consistent, application-ready, and safe for production use.
