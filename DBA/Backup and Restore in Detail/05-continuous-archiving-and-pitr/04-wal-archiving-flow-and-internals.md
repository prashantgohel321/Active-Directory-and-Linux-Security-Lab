# WAL Archiving Flow and Internals (How PostgreSQL Moves WAL)

## In simple words

WAL archiving is not magic.

PostgreSQL follows a **strict lifecycle** for every WAL segment:

* create
* write
* close
* archive
* recycle

Understanding this flow is the key to debugging PITR issues.

---

## WAL lifecycle at a high level

Each WAL segment goes through these stages:

1. active in `pg_wal`
2. completed and ready to archive
3. archived successfully
4. recycled or removed

Archiving decides when a WAL is safe to delete.

---

## How a WAL segment is created

* PostgreSQL writes changes continuously
* WAL files are written sequentially
* default WAL segment size is 16MB

While a WAL file is active:

* it cannot be archived
* PostgreSQL keeps writing to it

---

## When a WAL becomes archive-ready

A WAL segment becomes archive-ready when:

* it is completely filled, or
* PostgreSQL switches to a new WAL file

At this point:

* PostgreSQL calls `archive_command`
* the WAL file is copied to archive storage

---

## archive_command execution flow

For each completed WAL file:

* PostgreSQL runs `archive_command`
* passes `%p` (path) and `%f` (filename)
* waits for success

If the command fails:

* WAL is retried
* WAL is not removed

This guarantees no WAL is lost silently.

---

## What happens on archive failure

If archiving fails repeatedly:

* WAL files accumulate in `pg_wal`
* disk usage grows
* database may stop accepting writes

This is one of the most common PITR-related outages.

---

## How PostgreSQL knows WAL is archived

PostgreSQL tracks:

* successful archive operations
* failed archive attempts

You can inspect this using:

```sql
SELECT * FROM pg_stat_archiver;
```

This view is your first stop during debugging.

---

## WAL recycling vs archiving

Without archiving:

* WAL files are reused when safe

With archiving enabled:

* WAL files are kept until archived
* recycling waits for archive success

Archiving changes WAL cleanup behavior.

---

## Timelines (basic concept)

Each recovery creates a new **timeline**.

Timelines allow:

* divergence from old history
* safe recovery without overwriting past states

WAL files belong to specific timelines.

---

## Why timelines matter

During PITR:

* PostgreSQL selects correct WAL timeline
* old timelines are preserved

Mixing WAL from different timelines causes restore failure.

---

## Where DBAs get confused

Common confusion points:

* WAL files not disappearing
* pg_wal growing endlessly
* archive directory filling up

These are symptoms, not bugs.

---

## DBA debugging checklist

When WAL archiving issues occur, I check:

* `pg_stat_archiver`
* archive_command exit behavior
* disk space on archive destination
* permissions

Most issues are operational, not PostgreSQL bugs.

---

## Final mental model

* WAL flows forward
* Archiving freezes history
* Recycling waits for safety
* Timelines protect recovery paths

---

## One-line explanation (interview ready)

PostgreSQL archives WAL segments only after they are completed, using archive_command, and manages retention through strict lifecycle and timeline rules.
