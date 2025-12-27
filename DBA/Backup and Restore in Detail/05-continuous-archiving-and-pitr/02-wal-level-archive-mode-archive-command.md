# WAL Level, archive_mode, and archive_command (How WAL Archiving Actually Works)

## In simple words

To make WAL archiving work, PostgreSQL needs **three settings to cooperate**:

* `wal_level`
* `archive_mode`
* `archive_command`

If even one is wrong, WAL archiving silently fails.

---

## Why configuration matters

PostgreSQL never guesses your intention.

Unless these settings are explicitly correct:

* WAL files are recycled
* change history is lost
* PITR becomes impossible

That’s why WAL archiving failures are usually **configuration failures**.

---

## wal_level (how much information WAL stores)

### What wal_level means

`wal_level` defines **how much detail** PostgreSQL writes into WAL.

Common values:

* `minimal`
* `replica`
* `logical`

---

### Which wal_level is required

For WAL archiving:

```conf
wal_level = replica
```

Why:

* `minimal` does not generate enough WAL
* `replica` guarantees crash recovery and PITR

Logical replication requires `logical`, but PITR does not.

---

## archive_mode (turns archiving on)

### What archive_mode does

`archive_mode` tells PostgreSQL:

> “Do not delete WAL until it is archived somewhere safe.”

Enable it with:

```conf
archive_mode = on
```

Without this, PostgreSQL reuses WAL files automatically.

---

## archive_command (how WAL is archived)

### What archive_command is

`archive_command` is a **shell command** executed every time a WAL segment is completed.

PostgreSQL runs it like:

```bash
archive_command %p %f
```

Where:

* `%p` = full path to WAL file
* `%f` = WAL file name

---

## A simple archive_command example

```conf
archive_command = 'cp %p /backup/wal_archive/%f'
```

Meaning:

* copy WAL file to archive directory
* only mark success if command exits with 0

If command fails, PostgreSQL retries.

---

## Why archive_command failures are dangerous

If archive_command:

* returns non-zero
* hangs
* writes to full disk

Then:

* WAL is not archived
* WAL cannot be recycled
* pg_wal directory grows
* database may stop

This is a classic production outage.

---

## Testing WAL archiving

Always verify:

```sql
SELECT * FROM pg_stat_archiver;
```

Check:

* archived_count increases
* failed_count stays zero

Never trust configuration blindly.

---

## Reload vs restart

Changes to these parameters require:

* `wal_level` → restart
* `archive_mode` → restart
* `archive_command` → reload

Restart planning is required.

---

## Security and permissions

archive_command runs as:

* PostgreSQL OS user

Ensure:

* archive directory permissions are correct
* command cannot be exploited

Security mistakes here leak data.

---

## Common DBA mistakes

* forgetting restart after wal_level change
* wrong archive path
* no monitoring of archive failures
* assuming archive = backup

WAL archiving is only as good as its validation.

---

## Final mental model

* wal_level = how much history
* archive_mode = keep history
* archive_command = where history goes

All three must work together.

---

## One-line explanation (interview ready)

PostgreSQL WAL archiving depends on wal_level for data detail, archive_mode to enable archiving, and archive_command to store WAL files safely.
