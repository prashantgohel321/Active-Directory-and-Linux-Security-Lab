# pg_restore and Selective Restore in PostgreSQL

## In simple words

`pg_restore` is used to restore logical backups that were created in **custom**, **directory**, or **tar** format.

Unlike plain SQL restore, pg_restore gives **control**:

* what to restore
* how to restore
* how fast to restore

This makes it very powerful for real DBA work.

---

## Why pg_restore exists

Plain SQL dumps:

* must be restored fully
* execute line by line
* cannot skip objects easily

pg_restore exists to solve these problems.

It works only with **non-plain** dump formats:

* `-Fc` (custom)
* `-Fd` (directory)
* `-Ft` (tar)

---

## How pg_restore works internally

pg_restore:

* reads dump metadata
* understands database objects
* decides restore order
* executes commands selectively

It does **not** blindly replay SQL like psql.

---

## Basic pg_restore syntax

```bash
pg_restore -d target_db backup.dump
```

This restores everything from the dump into `target_db`.

---

## Creating a compatible dump for pg_restore

```bash
pg_dump -Fc dbname > dbname.dump
```

Without this format, pg_restore cannot be used.

---

## Listing dump contents (very important)

Before restoring, I always inspect the dump:

```bash
pg_restore -l dbname.dump
```

This shows:

* tables
* schemas
* indexes
* functions
* extensions

It helps decide what to restore.

---

## Restoring specific objects

Only one table:

```bash
pg_restore -t customers -d target_db dbname.dump
```

Only one schema:

```bash
pg_restore -n sales -d target_db dbname.dump
```

Selective restore is not possible with plain SQL dumps.

---

## Excluding objects during restore

Exclude table:

```bash
pg_restore --exclude-table=logs -d target_db dbname.dump
```

Exclude schema:

```bash
pg_restore --exclude-schema=test -d target_db dbname.dump
```

This is useful in debugging and migrations.

---

## Restoring schema and data separately

Schema only:

```bash
pg_restore -s -d target_db dbname.dump
```

Data only:

```bash
pg_restore -a -d target_db dbname.dump
```

This allows controlled restore sequences.

---

## Parallel restore (big performance boost)

```bash
pg_restore -j 4 -d target_db dbname.dump
```

Meaning:

* `-j 4` = use 4 parallel jobs

Parallel restore:

* speeds up large restores
* requires directory or custom format

---

## Handling ownership and permissions

Skip ownership:

```bash
pg_restore --no-owner -d target_db dbname.dump
```

Skip privileges:

```bash
pg_restore --no-privileges -d target_db dbname.dump
```

Very common when restoring to test or staging.

---

## Common pg_restore failures

pg_restore fails when:

* roles do not exist
* target database is missing
* permissions are insufficient
* objects already exist

Most issues are environment-related, not tool-related.

---

## When pg_restore is the right tool

I use pg_restore when:

* restoring large databases
* restoring selective objects
* doing migrations
* minimizing restore time

It offers control and speed.

---

## When pg_restore is NOT useful

pg_restore cannot:

* restore plain SQL dumps
* restore physical backups
* bypass permission rules

Tool choice must match dump format.

---

## Final mental model

* pg_dump creates structured dumps
* pg_restore understands dump structure
* selective restore saves time
* parallel restore improves performance

---

## One-line explanation (interview ready)

pg_restore restores custom-format logical backups with fine-grained control over objects, order, and performance.
