# PostgreSQL Dump Formats: -Fp, -Fc, -Fd, -Ft (Explainable Guide)

## In simple words

When I take a logical backup with `pg_dump`, I must choose **how the backup is stored**.

That choice is called the **dump format**.

The format decides:

* file structure
* restore speed
* flexibility
* whether selective and parallel restore is possible

Choosing the wrong format is a common DBA mistake.

---

## Overview of available dump formats

PostgreSQL supports four main dump formats:

* `-Fp` → Plain SQL (default)
* `-Fc` → Custom format
* `-Fd` → Directory format
* `-Ft` → Tar format

Each format has a specific purpose.

---

## Plain format (-Fp)

### What it is

A human‑readable SQL file containing CREATE, INSERT, and GRANT statements.

```bash
pg_dump -Fp mydb > mydb.sql
```

### Characteristics

* text file
* readable and editable
* restored using `psql`

### Pros

* very simple
* easy to inspect or modify
* no special restore tool needed

### Cons

* largest file size
* slow restore
* no selective restore
* no parallel restore

### When I use it

* small databases
* learning and debugging
* manual inspection needed

---

## Custom format (-Fc)

### What it is

A compressed binary dump designed specifically for PostgreSQL.

```bash
pg_dump -Fc mydb > mydb.dump
```

### Characteristics

* binary format
* requires `pg_restore`
* internally structured

### Pros

* smaller size
* faster restore
* supports selective restore
* supports parallel restore

### Cons

* not human‑readable
* cannot be edited manually

### When I use it

* production backups
* medium to large databases
* when restore speed matters

---

## Directory format (-Fd)

### What it is

A folder containing separate files for database objects.

```bash
pg_dump -Fd mydb -f mydb_dir
```

### Characteristics

* one directory, many files
* best for parallel restore

### Pros

* fastest restore
* highest flexibility
* ideal for very large databases

### Cons

* not a single file
* harder to move manually

### When I use it

* very large databases
* enterprise systems
* time‑critical restores

---

## Tar format (-Ft)

### What it is

A tar archive containing dump contents.

```bash
pg_dump -Ft mydb > mydb.tar
```

### Characteristics

* single archive file
* intermediate flexibility

### Pros

* single file
* supports pg_restore

### Cons

* slower than custom and directory formats
* less commonly used

### When I use it

* when I need a single file but want pg_restore features

---

## Restore tool comparison

| Dump Format | Restore Tool | Selective Restore | Parallel Restore |
| ----------- | ------------ | ----------------- | ---------------- |
| -Fp         | psql         | No                | No               |
| -Fc         | pg_restore   | Yes               | Yes              |
| -Fd         | pg_restore   | Yes               | Yes (Best)       |
| -Ft         | pg_restore   | Yes               | Limited          |

---

## Performance reality

* Backup speed is similar across formats
* Restore speed varies significantly
* Parallel restore makes the biggest difference

Format choice matters most during restore, not backup.

---

## DBA recommendation (real world)

* Small DB → `-Fp`
* Medium / Large DB → `-Fc`
* Very Large / Mission‑critical DB → `-Fd`

Avoid default plain format in production unless you know why you are using it.

---

## Common mistakes to avoid

* Using plain format for huge databases
* Not planning restore strategy
* Choosing format without testing restore

Backup format must match recovery expectations.

---

## Final mental model

* Dump format defines restore power
* pg_restore needs structured formats
* Parallel restore saves hours
* Production ≠ plain SQL

---

## One‑line explanation (interview ready)

PostgreSQL dump formats define how backups are stored and restored, directly affecting flexibility, restore speed, and recovery options.
