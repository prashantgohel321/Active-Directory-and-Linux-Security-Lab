# Parallel Backup and Restore in PostgreSQL

## In simple words

Parallel backup and restore means using **multiple workers at the same time** to speed things up.

It reduces total backup or restore time by splitting work across CPU cores.

Used correctly, it saves hours.
Used blindly, it hurts production.

---

## Why parallelism exists

Single-threaded backups become too slow as databases grow.

Parallelism exists to:

* speed up restore time
* use modern multi-core CPUs
* reduce outage windows

But it increases CPU, I/O, and lock pressure.

---

## Important rule (must remember)

> **pg_dump does NOT support parallel backup.**

Only **pg_restore** supports parallelism.

This surprises many DBAs.

---

## Parallel restore using pg_restore

Parallel restore works with:

* custom format (-Fc)
* directory format (-Fd)

Example:

```bash
pg_restore -j 4 -d target_db backup.dump
```

Here:

* `-j 4` means 4 parallel workers

Each worker restores different objects.

---

## Why directory format is best for parallel restore

Directory format stores objects as separate files.

This allows:

* maximum parallelism
* minimal contention
* fastest restore

For very large databases, directory format + parallel restore is the best combo.

---

## What actually runs in parallel

Parallel restore can process:

* table data
* indexes
* constraints

Some objects are still restored serially:

* roles
* extensions
* dependencies

So parallelism is helpful, but not unlimited.

---

## Choosing the right number of jobs

More jobs ≠ always faster.

Guidelines:

* start with CPU cores / 2
* monitor disk I/O
* avoid saturating production disks

Typical values: 4 to 8 jobs.

---

## Parallel restore on production vs test

On test or DR servers:

* aggressive parallelism is fine

On production systems:

* restore `I/O` can starve other workloads
* parallel restore must be planned

Restore speed must not crash the system.

---

## When parallel restore helps the most

Parallel restore is most effective when:

* database has many large tables
* many indexes exist
* directory format is used

It helps less with:

* small databases
* few tables

---

## Common mistakes

* using `-j` too high
* ignoring disk limits
* running parallel restore on live production

These cause timeouts and system slowdown.

---

## Testing parallel restore

Always test:

* different `-j` values
* restore duration
* system load

One-size-fits-all does not exist.

---

## Final mental model

* Parallelism saves time
* pg_restore enables it
* directory format scales best
* limits must be respected

---

## One-line explanation (interview ready)

Parallel restore in PostgreSQL uses multiple workers via pg_restore to speed up logical restores, mainly when using custom or directory formats.
