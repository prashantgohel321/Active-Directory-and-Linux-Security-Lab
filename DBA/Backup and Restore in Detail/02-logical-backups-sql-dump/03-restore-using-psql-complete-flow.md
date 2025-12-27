# Restore Using psql – Complete Flow (PostgreSQL Logical Restore)

## In simple words

Restoring a SQL dump means running SQL commands again to rebuild the database.

PostgreSQL does not have a special “restore mode” for SQL dumps.
Restore is simply **executing the dump file using psql**.

---

## What restore actually does

A SQL dump contains:

* CREATE statements
* INSERT statements
* GRANT and ownership commands

When restoring:

* PostgreSQL executes these commands one by one
* objects are rebuilt logically
* indexes are recreated, not copied

Restore is a **replay process**, not a file copy.

---

## Pre-restore checklist (very important)

Before restoring, I always check:

* target server is correct
* PostgreSQL version is compatible
* sufficient disk space exists
* required roles already exist

Most restore failures happen due to missing preparation.

---

## Step 1: Create an empty database

```bash
createdb newdb
```

The target database must exist before restore.

Alternatively:

```bash
createdb -O app_user newdb
```

This sets correct ownership upfront.

---

## Step 2: Restore using psql

```bash
psql -d newdb -f backup.sql
```

What happens internally:

* psql reads SQL line by line
* PostgreSQL executes each statement
* errors are reported immediately

Restore speed depends on dump size and indexes.

---

## Restore directly from compressed dump

```bash
gunzip -c backup.sql.gz | psql -d newdb
```

This avoids extracting the file to disk.

Useful when storage space is limited.

---

## Restore from a remote server

```bash
psql -h server_ip -U postgres -d newdb < backup.sql
```

Restore works over network just like local execution.

---

## Common restore errors and causes

### Role does not exist

Error:

```
ERROR: role "app_user" does not exist
```

Fix:

* create role first
* or restore with `--no-owner`

---

### Permission denied

Occurs when restore role lacks privileges.

Fix:

* restore as superuser
* or adjust ownership and grants

---

### Object already exists

Occurs when restoring into a non-empty database.

Fix:

* drop and recreate database
* or clean objects manually

---

## Useful restore options

Skip ownership:

```bash
psql -d newdb -f backup.sql --set ON_ERROR_STOP=on
```

For controlled restores:

* run schema first
* then data

---

## Post-restore tasks (often forgotten)

After restore, I always run:

```sql
ANALYZE;
```

This regenerates statistics and improves performance.

I also verify:

* row counts
* application connectivity
* basic queries

Restore without verification is incomplete.

---

## Why restore takes time

SQL restore:

* executes millions of INSERTs
* rebuilds indexes
* processes constraints

This is slower than physical restore by design.

---

## When psql restore is the right choice

I use psql restore when:

* restoring plain SQL dumps
* migrating data
* doing partial or selective rebuilds
* debugging schema issues

It gives full visibility and control.

---

## Common DBA mistake

Assuming backup success means restore success.

A backup is only valid if restore completes cleanly.

---

## Final mental model

* Restore = replay SQL
* psql = execution engine
* errors must be fixed immediately
* verification is mandatory

---

## One-line explanation (interview ready)

Restoring a SQL dump means executing the exported SQL commands using psql to rebuild the database logically.
