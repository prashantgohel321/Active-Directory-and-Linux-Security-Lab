# Offline Filesystem Backup – Step by Step (PostgreSQL)

## In simple words

An offline filesystem backup means:

* PostgreSQL is **completely stopped**
* no users, no writes, no WAL activity
* data files are copied in a stable state

This is the **safest and simplest** form of physical backup.

---

## Why offline backups still matter

Even though online backups exist, offline backups are still used when:

* database is small or medium
* maintenance window is available
* absolute safety is required
* environment is simple

With PostgreSQL stopped, there is zero consistency risk.

---

## What makes offline backup safe

When PostgreSQL is stopped:

* no transactions are running
* no dirty buffers exist
* no WAL is being generated
* files are internally consistent

This removes the need for WAL replay during restore.

---

## Step-by-step offline backup process

### Step 1: Notify users and applications

Before stopping PostgreSQL:

* inform application teams
* stop background jobs
* ensure no active connections

Never stop PostgreSQL blindly in production.

---

### Step 2: Stop PostgreSQL cleanly

```bash
sudo systemctl stop postgresql
```

Or:

```bash
pg_ctl stop -D $PGDATA
```

Verify:

```bash
ps aux | grep postgres
```

No postgres process should be running.

---

### Step 3: Copy the data directory

```bash
cp -a $PGDATA /backup/pgdata_backup
```

Important:

* use recursive copy
* preserve ownership and permissions
* include hidden files

If tablespaces exist, back them up separately.

---

### Step 4: Verify backup completeness

Check:

* directory size
* number of files
* backup logs

A half-copied backup is dangerous.

---

### Step 5: Start PostgreSQL again

```bash
sudo systemctl start postgresql
```

Verify:

* database starts normally
* applications reconnect

Downtime ends here.

---

## Restoring from an offline backup

Restore process:

* stop PostgreSQL
* replace PGDATA with backup copy
* ensure ownership and permissions
* start PostgreSQL

No WAL replay is needed.

---

## Handling tablespaces

If tablespaces exist:

* copy tablespace directories separately
* restore them to the same paths
* ensure symlinks in pg_tblspc are intact

Missing tablespaces cause startup failure.

---

## Common mistakes during offline backup

* copying data while PostgreSQL is still running
* forgetting tablespaces
* insufficient disk space
* wrong file permissions

Most failures are operational errors.

---

## Pros and cons of offline backups

Pros:

* simplest method
* highest safety
* easiest restore

Cons:

* requires downtime
* not suitable for 24x7 systems

---

## When I choose offline backup

I choose offline backup when:

* database is non-critical
* downtime is acceptable
* environment is small
* simplicity matters more than availability

---

## Final mental model

* Offline = stop DB, copy files
* Zero consistency risk
* Downtime is the cost
* Restore is simple

---

## One-line explanation (interview ready)

An offline filesystem backup copies PostgreSQL data files after stopping the server, ensuring maximum consistency at the cost of downtime.
