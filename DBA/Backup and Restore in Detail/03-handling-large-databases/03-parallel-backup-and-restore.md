<center>

# 03 Parallel Backup and Restore in PostgreSQL
</center>

<br>
<br>

- [03 Parallel Backup and Restore in PostgreSQL](#03-parallel-backup-and-restore-in-postgresql)
  - [In simple words](#in-simple-words)
  - [Why parallelism exists](#why-parallelism-exists)
  - [Important rule (must remember)](#important-rule-must-remember)
  - [Parallel restore using `pg_restore`](#parallel-restore-using-pg_restore)
  - [Why directory format is best for parallel restore](#why-directory-format-is-best-for-parallel-restore)
  - [What actually runs in parallel](#what-actually-runs-in-parallel)
  - [Choosing the right number of jobs](#choosing-the-right-number-of-jobs)
  - [Parallel restore on production vs test](#parallel-restore-on-production-vs-test)
  - [When parallel restore helps the most](#when-parallel-restore-helps-the-most)
  - [Common mistakes](#common-mistakes)
  - [Testing parallel restore](#testing-parallel-restore)
  - [Final mental model](#final-mental-model)
  - [One-line explanation (interview ready)](#one-line-explanation-interview-ready)

<br>
<br>

## In simple words

- Parallel backup and restore means doing the work using multiple workers at the same time instead of one. It splits the load across CPU cores, which can drastically reduce total backup or restore time. When planned properly, it can save hours, but if used blindly, it can overload the system and hurt production performance.

---

<br>
<br>

## Why parallelism exists

Single-threaded backups become too slow as databases grow.

**Parallelism exists to:**

* speed up restore time
* use modern multi-core CPUs
* reduce outage windows

But it increases CPU, I/O, and lock pressure.

---

<br>
<br>

## Important rule (must remember)

> **`pg_dump` does NOT support parallel backup.**

Only **`pg_restore`** supports parallelism.

This surprises many DBAs.

---

<br>
<br>

## Parallel restore using `pg_restore`

**Parallel restore works with:**

* custom format (`-Fc`)
* directory format (`-Fd`)

**Example:**

```bash
pg_restore -j 4 -d target_db backup.dump
```

**Here:**

* `-j 4` means 4 parallel workers

Each worker restores different objects.

---

<br>
<br>

## Why directory format is best for parallel restore

Directory format stores objects as separate files.

**This allows:**

* maximum parallelism
* minimal contention
* fastest restore

For very large databases, directory format + parallel restore is the best combo.

---

<br>
<br>

## What actually runs in parallel

**Parallel restore can process:**

* table data
* indexes
* constraints

**Some objects are still restored serially:**

* roles
* extensions
* dependencies

So parallelism is helpful, but not unlimited.

---

<br>
<br>

## Choosing the right number of jobs

More jobs ≠ always faster.

**Guidelines:**

* start with CPU cores / 2
* monitor disk I/O
* avoid saturating production disks

Typical values: 4 to 8 jobs.

---

<br>
<br>

## Parallel restore on production vs test

**On test or DR servers:**

* aggressive parallelism is fine

**On production systems:**

* restore `I/O` can starve other workloads
* parallel restore must be planned

Restore speed must not crash the system.

---

<br>
<br>

## When parallel restore helps the most

**Parallel restore is most effective when:**

* database has many large tables
* many indexes exist
* directory format is used

**It helps less with:**

* small databases
* few tables

---

<br>
<br>

## Common mistakes

* using `-j` too high
* ignoring disk limits
* running parallel restore on live production

These cause timeouts and system slowdown.

---

<br>
<br>

## Testing parallel restore

**Always test:**

* different `-j` values
* restore duration
* system load

One-size-fits-all does not exist.

---

<br>
<br>

## Final mental model

* Parallelism saves time
* `pg_restore` enables it
* directory format scales best
* limits must be respected

---

<br>
<br>

## One-line explanation (interview ready)

Parallel restore in PostgreSQL uses multiple workers via `pg_restore` to speed up logical restores, mainly when using custom or directory formats.
