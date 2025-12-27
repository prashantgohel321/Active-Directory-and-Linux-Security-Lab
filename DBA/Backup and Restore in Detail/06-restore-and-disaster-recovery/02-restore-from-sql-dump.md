# Restore from SQL Dump (Logical Restore – Real DBA Flow)

## In simple words

Restoring from an SQL dump means:

* rebuilding the database using SQL commands
* table by table, row by row

It is slow compared to physical restore, but it is **safe, flexible, and controllable**.

This file explains how a DBA actually restores from SQL dumps in real life.

---

## When SQL dump restore is the right choice

I choose SQL dump restore when:

* only logical backups are available
* migration or version upgrade is needed
* partial restore is required (schema/table)
* database size is small to medium

For large production outages, SQL dump is usually **not** the first option.

---

## What an SQL dump really contains

An SQL dump is a text file with:

* CREATE DATABASE / CREATE TABLE
* INSERT or COPY statements
* indexes, constraints
* functions and triggers

During restore, PostgreSQL executes this file like a script.

---

## Pre-restore checks (very important)

Before restoring, I verify:

* PostgreSQL version compatibility
* target database is empty
* required roles exist
* enough disk space is available

Skipping checks causes partial restores.

---

## Basic restore flow

Typical restore command:

```bash
psql -d target_db -f backup.sql
```

What happens:

* SQL is executed sequentially
* objects are created
* data is inserted

Errors during execution stop progress or skip objects.

---

## Restore into a new database (best practice)

Preferred approach:

```bash
createdb target_db
psql -d target_db -f backup.sql
```

Never restore into an existing, active database.

---

## Restoring compressed dumps

If dump is compressed:

```bash
gunzip -c backup.sql.gz | psql -d target_db
```

Streaming avoids temporary disk usage.

---

## Restoring as a specific user

```bash
psql -U dbuser -d target_db -f backup.sql
```

The restore user must:

* own objects, or
* have permission to create them

Ownership mismatches cause failures.

---

## Common restore errors and causes

### Role does not exist

Cause:

* dump contains objects owned by missing roles

Fix:

* create roles first
* or edit dump carefully

---

### Permission denied

Cause:

* restore user lacks privileges

Fix:

* use database owner or superuser

---

### Object already exists

Cause:

* restoring into non-empty database

Fix:

* drop and recreate database

---

## Monitoring restore progress

During restore, I monitor:

* PostgreSQL logs
* disk usage
* error output

For large dumps, restores can run for hours.

---

## Post-restore tasks (mandatory)

After restore:

* run ANALYZE
* verify row counts
* check sequences

Restore success ≠ performance ready.

---

## Limitations of SQL dump restore

* slow for large databases
* no parallel restore
* requires full rebuild

These are design trade-offs.

---

## Real DBA mindset

SQL dump restore is:

* safest logical option
* flexible
* slow but predictable

When used intentionally, it works well.

---

## Final mental model

* SQL dump = script
* restore = execute script
* flexibility > speed
* validation is required

---

## One-line explanation (interview ready)

Restoring from an SQL dump rebuilds a PostgreSQL database by executing SQL statements, offering flexibility and safety at the cost of restore speed.
