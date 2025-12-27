# Compression and Splitting Techniques for PostgreSQL Backups

## In simple words

Compression and splitting exist to solve two real problems:

* backups are too big
* backups are hard to move and restore

At scale, storing and handling backups becomes as important as creating them.

---

## Why compression is needed

- Large databases produce:
  * huge dump files
  * high storage usage
  * slow transfers

- Compression reduces:
  * disk space usage
  * network transfer time

But it always trades disk savings for CPU usage.

---

<br>
<br>

## Compression with logical backups

### External compression using gzip

```bash
pg_dump mydb | gzip > mydb.sql.gz
```

What happens:

* **`pg_dump`** outputs SQL
* **`gzip`** compresses the stream
* a smaller file is written

This is simple and widely used.

---

## Compression with custom format

```bash
pg_dump -Fc mydb > mydb.dump
```

Custom format:

* uses internal compression
* avoids external gzip
* restores faster than plain SQL

For most production systems, this is the preferred option.

---

## CPU impact of compression

Compression is CPU-heavy.

High compression levels:

* reduce file size
* slow down backup

Low compression levels:

* faster backups
* larger files

DBAs must balance CPU availability and backup windows.

---

## Splitting large backups (file management)

Very large backup files are:

* difficult to move
* harder to store
* risky to handle

Splitting breaks a large backup into manageable chunks.

---

## Splitting plain SQL dumps

```bash
pg_dump mydb | split -b 5G - mydb_part_
```

This creates multiple 5GB files.

During restore:

```bash
cat mydb_part_* | psql -d target_db
```

---

## Splitting compressed dumps

```bash
pg_dump mydb | gzip | split -b 2G - mydb.gz_
```

Restore:

```bash
cat mydb.gz_* | gunzip | psql -d target_db
```

Splitting helps with storage and transfer limits.

---

## Directory format avoids splitting issues

Using directory format:

```bash
pg_dump -Fd mydb -f mydb_dir
```

Advantages:

* files are already separated
* supports parallel restore
* easier to manage large datasets

This is the cleanest solution for very large databases.

---

## Network transfer considerations

Compressed backups:

* reduce bandwidth usage
* increase CPU load

Uncompressed backups:

* faster CPU usage
* slower transfers

Network speed matters more than compression level.

---

## Common mistakes

* compressing on already CPU-saturated servers
* using maximum compression blindly
* splitting without restore testing

Compression must be tested, not assumed.

---

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

## One-line explanation (interview ready)

Compression and splitting help manage large PostgreSQL backups by reducing storage size and improving transfer reliability, at the cost of additional CPU usage.
