<center>

# 04 Performance Impact During Backup in PostgreSQL
</center>

<br>
<br>

- [04 Performance Impact During Backup in PostgreSQL](#04-performance-impact-during-backup-in-postgresql)
  - [In simple words](#in-simple-words)
  - [Why backups affect performance](#why-backups-affect-performance)
  - [Disk I/O is the biggest bottleneck](#disk-io-is-the-biggest-bottleneck)
  - [Impact of logical backups (`pg_dump`)](#impact-of-logical-backups-pg_dump)
  - [Impact of physical backups](#impact-of-physical-backups)
  - [Effect on replication](#effect-on-replication)
  - [Backup timing strategy](#backup-timing-strategy)
  - [Throttling backup impact](#throttling-backup-impact)
  - [Using replicas for backups](#using-replicas-for-backups)
  - [Monitoring during backups](#monitoring-during-backups)
  - [Common DBA mistakes](#common-dba-mistakes)
  - [Final mental model](#final-mental-model)
  - [One-line explanation](#one-line-explanation)

<br>
<br>

## In simple words

Backups are not free.

**Every backup consumes resources:**

* disk I/O
* CPU
* memory

If not planned properly, backups slow down live users and can even cause outages.

---

<br>
<br>

## Why backups affect performance

**During a backup, PostgreSQL:**

* reads large amounts of data
* scans tables sequentially
* competes with normal queries for I/O

On busy systems, this competition becomes visible to users.

---

<br>
<br>

## Disk I/O is the biggest bottleneck

Most backup pain comes from disk I/O.

**Symptoms of I/O saturation:**

* queries become slow
* replication lag increases
* checkpoints take longer
* timeouts appear

CPU is rarely the first problem; disks usually are.

---

<br>
<br>

## Impact of logical backups (`pg_dump`)

**`pg_dump`:**

* performs sequential scans
* generates continuous read load
* can evict useful pages from cache

On large databases, `pg_dump` can degrade query performance if run during peak hours.

---

<br>
<br>

## Impact of physical backups

**Physical backups:**

* read raw data files
* create sustained I/O pressure
* may impact WAL write speed

Online physical backups depend heavily on storage speed.

---

<br>
<br>

## Effect on replication

**During backups:**

* primary disk I/O increases
* WAL generation may increase
* replicas can lag

Replication lag during backup is a common production issue.

---

<br>
<br>

## Backup timing strategy

**Senior DBAs schedule backups:**

* during low traffic windows
* when batch jobs are minimal
* outside peak business hours

Timing matters more than backup speed.

---

<br>
<br>

## Throttling backup impact

**Ways to reduce impact:**

* limit parallel restore jobs
* reduce compression level
* use directory format wisely
* avoid running multiple backups at once

Gentle backups are better than fast ones that break production.

---

<br>
<br>

## Using replicas for backups

**A common strategy:**

* run backups on a standby server
* offload I/O from primary

This reduces impact on live users.

But replication lag must be monitored.

---

<br>
<br>

## Monitoring during backups

**While backups run, I monitor:**

* disk I/O metrics
* query latency
* replication lag
* PostgreSQL logs

Backups without monitoring are risky.

---

<br>
<br>

## Common DBA mistakes

* running backups during peak hours
* ignoring I/O limits
* using maximum compression blindly
* backing up primary when replicas exist

Most incidents are avoidable.

---

<br>
<br>

## Final mental model

* Backups consume resources
* I/O is the main enemy
* Timing reduces risk
* Monitoring keeps backups safe

---

<br>
<br>

## One-line explanation

PostgreSQL backups impact performance mainly through disk I/O, so timing, throttling, and offloading backups are critical in production systems.
