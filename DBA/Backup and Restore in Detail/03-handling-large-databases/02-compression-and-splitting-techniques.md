<center>

# 02 Compression and Splitting Techniques for PostgreSQL Backups
</center>

<br>
<br>

- [02 Compression and Splitting Techniques for PostgreSQL Backups](#02-compression-and-splitting-techniques-for-postgresql-backups)
  - [In simple words](#in-simple-words)
  - [Why compression is needed](#why-compression-is-needed)
  - [Compression with logical backups](#compression-with-logical-backups)
    - [External compression using gzip](#external-compression-using-gzip)
  - [Compression with custom format](#compression-with-custom-format)
  - [CPU impact of compression](#cpu-impact-of-compression)
  - [Splitting large backups (file management)](#splitting-large-backups-file-management)
  - [Splitting plain SQL dumps](#splitting-plain-sql-dumps)
  - [Splitting compressed dumps](#splitting-compressed-dumps)
  - [Directory format avoids splitting issues](#directory-format-avoids-splitting-issues)
  - [Network transfer considerations](#network-transfer-considerations)
  - [Common mistakes](#common-mistakes)
  - [DBA best practices](#dba-best-practices)
  - [Final mental model](#final-mental-model)
  - [One-line explanation](#one-line-explanation)

<br>
<br>

## In simple words

**Compression and splitting exist to solve two real problems:**

* backups are too big
* backups are hard to move and restore

At scale, storing and handling backups becomes as important as creating them.

---

<br>
<br>

## Why compression is needed

- **Large databases produce:**
  * huge dump files
  * high storage usage
  * slow transfers

<br>

- **Compression reduces:**
  * disk space usage
  * network transfer time

But it always trades disk savings for CPU usage.

---

<br>
<br>

<br>
<br>

## Compression with logical backups

### External compression using gzip

```bash
pg_dump mydb | gzip > mydb.sql.gz
```

<br>

**What happens:**

* **`pg_dump`** outputs SQL
* **`gzip`** compresses the stream
* a smaller file is written

This is simple and widely used.

---

<br>
<br>

## Compression with custom format

```bash
pg_dump -Fc mydb > mydb.dump
```

<br>

**Custom format:**
* uses internal compression
* avoids external gzip
* restores faster than plain SQL

For most production systems, this is the preferred option.

---

<br>
<br>

## CPU impact of compression

Compression is CPU-heavy.

<br>

- **High compression levels:**
  * reduce file size
  * slow down backup

<br>

- **Low compression levels:**
  * faster backups
  * larger files

DBAs must balance CPU availability and backup windows.

---

<br>
<br>

## Splitting large backups (file management)

**Very large backup files are:**

* difficult to move
* harder to store
* risky to handle

Splitting breaks a large backup into manageable chunks.

---

<br>
<br>

## Splitting plain SQL dumps

```bash
pg_dump mydb | split -b 5G - mydb_part_
```

This creates multiple 5GB files.

**During restore:**

```bash
cat mydb_part_* | psql -d target_db
```

---

<br>
<br>

## Splitting compressed dumps

```bash
pg_dump mydb | gzip | split -b 2G - mydb.gz_
```

**Restore:**

```bash
cat mydb.gz_* | gunzip | psql -d target_db
```

Splitting helps with storage and transfer limits.

---

<br>
<br>

## Directory format avoids splitting issues

**Using directory format:**

```bash
pg_dump -Fd mydb -f mydb_dir
```

**Advantages:**

* files are already separated
* supports parallel restore
* easier to manage large datasets

This is the cleanest solution for very large databases.

---

<br>
<br>

## Network transfer considerations

**Compressed backups:**

* reduce bandwidth usage
* increase CPU load

**Uncompressed backups:**

* faster CPU usage
* slower transfers

Network speed matters more than compression level.

---

<br>
<br>

## Common mistakes

* compressing on already CPU-saturated servers
* using maximum compression blindly
* splitting without restore testing

Compression must be tested, not assumed.

---

<br>
<br>

## DBA best practices

* prefer custom or directory formats
* compress when network or disk is limited
* avoid heavy compression during peak hours
* test restore using split files

---

## Final mental model

* Compression saves space, costs CPU
* Splitting improves manageability
* Directory format scales best
* Restore testing validates everything

---

<br>
<br>

## One-line explanation 

Compression and splitting help manage large PostgreSQL backups by reducing storage size and improving transfer reliability, at the cost of additional CPU usage.
