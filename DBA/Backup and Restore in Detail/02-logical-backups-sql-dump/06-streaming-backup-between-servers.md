# Streaming Backups Between Servers in PostgreSQL

## In simple words

Streaming backup means copying data from one PostgreSQL server to another **without creating an intermediate dump file**.

Data flows directly from source to target using a pipe.
This is fast, clean, and very useful for migrations.

---

## Why streaming backups exist

Creating dump files:

* needs disk space
* takes extra time
* creates cleanup work

Streaming avoids this by:

* reading from source
* writing to target immediately

No file sits in the middle.

---

## Most common streaming pattern

```bash
pg_dump source_db | psql -d target_db
```

What happens internally:

* pg_dump reads data from source
* output is sent through pipe
* psql receives and executes SQL
* target database is rebuilt live

---

## Streaming between two different servers

```bash
pg_dump -h source_ip -U src_user source_db \
| psql -h target_ip -U tgt_user -d target_db
```

This works across:

* different machines
* different data centers
* different PostgreSQL versions

---

## Why this works safely

* pg_dump uses a consistent snapshot
* psql executes commands in order
* data integrity is preserved

Users can keep working on source during streaming.

---

## When streaming is a good choice

I use streaming when:

* migrating databases
* cloning production to staging
* disk space is limited
* one-time transfers are needed

It is fast and simple.

---

## Limitations of streaming backups

Streaming backups:

* cannot be resumed if interrupted
* provide no backup file for reuse
* depend heavily on network stability

If network drops, restore fails.

---

## Streaming with compression

```bash
pg_dump source_db | gzip | gunzip | psql -d target_db
```

Used when network bandwidth is limited.
CPU cost increases.

---

## Handling errors during streaming

If error occurs:

* streaming stops immediately
* partial data may exist

Best practice:

* restore into empty database
* drop and retry on failure

---

## Streaming vs file-based backups

Streaming:

* faster
* less disk usage
* single-use

File-based:

* reusable
* resumable
* safer for long-term storage

Choose based on situation.

---

## DBA checklist before streaming

Before streaming I ensure:

* target DB is empty
* required roles exist
* permissions are correct
* network is stable

Preparation prevents failures.

---

## Final mental model

* Streaming = pipe + live restore
* No files in between
* Fast but fragile
* Best for migrations

---

## One-line explanation (interview ready)

Streaming backup transfers a logical dump directly from one PostgreSQL server to another using pipes, avoiding intermediate files.
