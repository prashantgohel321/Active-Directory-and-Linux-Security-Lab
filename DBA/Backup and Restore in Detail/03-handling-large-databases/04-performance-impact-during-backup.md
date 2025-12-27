# Performance Impact During Backup in PostgreSQL

## In simple words

Backups are not free.

Every backup consumes resources:

* disk I/O
* CPU
* memory

If not planned properly, backups slow down live users and can even cause outages.

---

## Why backups affect performance

During a backup, PostgreSQL:

* reads large amounts of data
* scans tables sequentially
* competes with normal queries for I/O

On busy systems, this competition becomes visible to users.

---

## Disk I/O is the biggest bottleneck

Most backup pain comes from disk I/O.

Symptoms of I/O saturation:

* queries become slow
* replication lag increases
* checkpoints take longer
* timeouts appear

CPU is rarely the first problem; disks usually are.

---

## Impact of logical backups (pg_dump)

pg_dump:

* performs sequential scans
* generates continuous read load
* can evict useful pages from cache

On large databases, pg_dump can degrade query performance if run during peak hours.

---

## Impact of physical backups

Physical backups:

* read raw data files
* create sustained I/O pressure
* may impact WAL write speed

Online physical backups depend heavily on storage speed.

---

## Effect on replication

During backups:

* primary disk I/O increases
* WAL generation may increase
* replicas can lag

Replication lag during backup is a common production issue.

---

## Backup timing strategy

Senior DBAs schedule backups:

* during low traffic windows
* when batch jobs are minimal
* outside peak business hours

Timing matters more than backup speed.

---

## Throttling backup impact

Ways to reduce impact:

* limit parallel restore jobs
* reduce compression level
* use directory format wisely
* avoid running multiple backups at once

Gentle backups are better than fast ones that break production.

---

## Using replicas for backups

A common strategy:

* run backups on a standby server
* offload I/O from primary

This reduces impact on live users.

But replication lag must be monitored.

---

## Monitoring during backups

While backups run, I monitor:

* disk I/O metrics
* query latency
* replication lag
* PostgreSQL logs

Backups without monitoring are risky.

---

## Common DBA mistakes

* running backups during peak hours
* ignoring I/O limits
* using maximum compression blindly
* backing up primary when replicas exist

Most incidents are avoidable.

---

## Final mental model

* Backups consume resources
* I/O is the main enemy
* Timing reduces risk
* Monitoring keeps backups safe

---

## One-line explanation (interview ready)

PostgreSQL backups impact performance mainly through disk I/O, so timing, throttling, and offloading backups are critical in production systems.
