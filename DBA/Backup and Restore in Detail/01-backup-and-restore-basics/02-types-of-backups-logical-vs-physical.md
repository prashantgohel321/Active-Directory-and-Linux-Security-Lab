# Types of Backups in PostgreSQL: Logical vs Physical

<br>
<br>

- [Types of Backups in PostgreSQL: Logical vs Physical](#types-of-backups-in-postgresql-logical-vs-physical)
  - [In simple words](#in-simple-words)
  - [What is a logical backup?](#what-is-a-logical-backup)
  - [How logical backup works internally](#how-logical-backup-works-internally)
  - [When I use logical backups](#when-i-use-logical-backups)
  - [What is a physical backup?](#what-is-a-physical-backup)
  - [How physical backup works internally](#how-physical-backup-works-internally)
  - [Logical vs physical backup (core difference)](#logical-vs-physical-backup-core-difference)
  - [Restore behavior difference](#restore-behavior-difference)
  - [Partial restore capability](#partial-restore-capability)
  - [Downtime considerations](#downtime-considerations)
  - [PostgreSQL version compatibility](#postgresql-version-compatibility)
  - [How a DBA chooses between them](#how-a-dba-chooses-between-them)
  - [Final mental model](#final-mental-model)
  - [One‑line explanation (interview ready)](#oneline-explanation-interview-ready)

<br>
<br>

## In simple words

- PostgreSQL backups are mainly of two types: logical backups and physical backups.

<br>

- <mark><b>Logical backup</b></mark> means rebuilding the database using SQL commands.
- <mark><b>Physical backup</b></mark> means copying the database files exactly as they are on disk.

---

<br>
<br>

## What is a logical backup?

- A logical backup stores the database as SQL statements such as:
  * **`CREATE TABLE`**
  * **`CREATE INDEX`**
  * **`INSERT INTO`**
  * **`ALTER`** and **`GRANT`** commands

- When this backup is restored, PostgreSQL executes these SQL commands again to recreate the database.

<br>

- Tools commonly used:
  * **`pg_dump`**
  * **`pg_dumpall`**

---

<br>
<br>

## How logical backup works internally

* The database remains online
* PostgreSQL takes a transaction‑consistent snapshot
* Objects and data are read logically
* SQL statements are written to a dump file

Users can keep working during the backup without data corruption.

---

<br>
<br>

## When I use logical backups

I use logical backups when:
* migrating databases between servers
* upgrading PostgreSQL versions
* restoring only specific tables or schemas
* moving data across different platforms

Logical backups are flexible and portable.

---

<br>
<br>

## What is a physical backup?

- A physical backup copies PostgreSQL’s actual data files from disk.

<br>

- This includes everything inside the data directory:
  * table files
  * index files
  * system catalogs
  * WAL files
  * control and metadata files

- Physical backups recreate the database exactly as it was.

---

<br>
<br>

## How physical backup works internally

- Physical backups can be taken in two ways:

  - Offline method:
    * PostgreSQL is stopped
    * entire data directory is copied
    * consistency is guaranteed

  - Online method:
    * PostgreSQL keeps running
    * tools like pg_basebackup are used
    * WAL files ensure consistency

No SQL is involved. Files are copied byte‑by‑byte.

---

<br>
<br>

## Logical vs physical backup (core difference)

- Logical backup:
    * rebuilds database using SQL
    * slower restore
    * supports partial restore
    * works across PostgreSQL versions

- Physical backup:
    * clones the database files
    * very fast restore
    * no partial restore
    * must match PostgreSQL version and architecture

---

<br>
<br>

## Restore behavior difference

- Logical restore:
    * executes SQL one statement at a time
    * rebuilds indexes
    * requires ANALYZE after restore

- Physical restore:
    * places files back on disk
    * PostgreSQL starts and replays WAL
    * database becomes usable quickly

---

<br>
<br>

## Partial restore capability

- Logical backups allow:
  * restoring a single table
  * restoring a schema only

- Physical backups do not support partial restore.
- The entire cluster must be restored.

---

<br>
<br>

## Downtime considerations

- Logical backup:
  * backup runs online
  * restore takes longer

- Physical backup:
  * offline backup requires downtime
  * online base backup avoids downtime
  * restore downtime is minimal

---

<br>
<br>

## PostgreSQL version compatibility

- Logical backup:
    * can restore across PostgreSQL versions
    * safe for upgrades

- Physical backup:
    * must use the same PostgreSQL version
    * same architecture and layout expected

---

<br>
<br>

## How a DBA chooses between them

- I choose logical backups when flexibility matters.
- I choose physical backups when recovery speed matters.

> In real production systems, both are used together.

---

<br>
<br>

## Final mental model

* Logical backup = rebuild
* Physical backup = clone
* Logical = portable and flexible
* Physical = fast and exact

---

<br>
<br>

## One‑line explanation (interview ready)

Logical backups store SQL instructions to recreate a database, while physical backups copy the actual database files for faster full recovery.
