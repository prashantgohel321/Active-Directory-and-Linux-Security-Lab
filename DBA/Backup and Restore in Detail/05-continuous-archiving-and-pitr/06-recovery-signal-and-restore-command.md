# recovery.signal and restore_command (How PostgreSQL Enters Recovery)

## In simple words

PostgreSQL does **not guess** when to perform recovery.

It enters recovery mode only when I explicitly tell it to.
That signal comes from two things:

* `recovery.signal`
* `restore_command`

If either is missing or wrong, recovery does not work.

---

## How PostgreSQL decides to start recovery

When PostgreSQL starts, it checks the data directory.

If it finds:

* `recovery.signal` → start recovery mode

If it does not find it:

* PostgreSQL starts normally
* WAL replay stops

This small file controls everything.

---

## What is recovery.signal

`recovery.signal` is an **empty file** placed in `PGDATA`.

Its presence means:

> “This cluster must recover using archived WAL.”

It replaces older `recovery.conf` (pre-PostgreSQL 12).

---

## Why recovery.signal exists

Before PostgreSQL 12:

* recovery was controlled by `recovery.conf`

Now:

* recovery settings live in `postgresql.conf`
* `recovery.signal` only triggers recovery mode

This simplifies startup logic.

---

## What is restore_command

`restore_command` tells PostgreSQL:

> “Where and how to fetch archived WAL files.”

It is a shell command executed during recovery.

Example:

```conf
restore_command = 'cp /backup/wal_archive/%f %p'
```

Meaning:

* `%f` = WAL file name
* `%p` = path where PostgreSQL expects WAL

---

## restore_command execution flow

During recovery:

* PostgreSQL requests next WAL file
* runs restore_command
* expects the file to be placed at `%p`

If command succeeds:

* WAL is replayed

If command fails:

* recovery stops

---

## Common restore_command mistakes

* wrong archive path
* incorrect permissions
* command returns non-zero
* missing WAL file

Any one of these breaks recovery.

---

## Full recovery setup example

Steps:

1. Restore base backup into PGDATA
2. Place `recovery.signal` file
3. Configure restore_command
4. (Optional) set recovery_target_time
5. Start PostgreSQL

PostgreSQL handles the rest.

---

## What happens after recovery completes

Once recovery reaches its target:

* PostgreSQL removes `recovery.signal`
* creates a new timeline
* starts accepting writes

Recovery mode ends automatically.

---

## When recovery does NOT stop

Recovery keeps waiting when:

* target WAL is not available
* restore_command cannot fetch WAL

PostgreSQL will keep retrying until WAL appears.

---

## DBA verification during recovery

I monitor:

* PostgreSQL logs
* recovery progress messages
* WAL fetch activity

Logs tell exactly what is missing.

---

## Final mental model

* recovery.signal = enter recovery
* restore_command = fetch WAL
* WAL replay = rebuild state
* new timeline = safe future

---

## One-line explanation (interview ready)

PostgreSQL enters recovery mode when recovery.signal is present and uses restore_command to fetch archived WAL files during PITR.
