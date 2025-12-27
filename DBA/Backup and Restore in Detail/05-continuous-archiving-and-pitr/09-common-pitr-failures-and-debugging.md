# Common PITR Failures and Debugging (PostgreSQL)

## In simple words

Most PITR failures are not PostgreSQL bugs.
They are **missing files, wrong configs, or bad assumptions**.

This file lists the failures DBAs actually hit and how to debug them calmly.

---

## Failure 1: Recovery does not start at all

### Symptom

* PostgreSQL starts normally
* No WAL replay
* Database opens immediately

### Root cause

* `recovery.signal` file missing

### Fix

* Place an empty `recovery.signal` file in PGDATA
* Restart PostgreSQL

PostgreSQL does not guess recovery intent.

---

## Failure 2: Recovery starts but stops immediately

### Symptom

* Recovery messages appear
* Recovery exits very fast

### Root cause

* No recovery target set
* Or WAL archive empty

### Fix

* Verify WAL files exist
* Set proper `recovery_target_*`

---

## Failure 3: Recovery waits forever

### Symptom

* PostgreSQL stays in recovery
* Repeats WAL fetch attempts

### Root cause

* Missing required WAL file
* restore_command cannot fetch WAL

### Debug

* Check PostgreSQL logs
* Validate archive path
* Test restore_command manually

---

## Failure 4: restore_command fails silently

### Symptom

* `pg_wal` requests WAL
* archive directory has files
* recovery still fails

### Root cause

* restore_command returns non-zero
* permission or path issue

### Debug

```bash
# test manually
cp /backup/wal_archive/WALFILE /tmp/test
```

Fix permissions or command syntax.

---

## Failure 5: Wrong recovery target time

### Symptom

* Data still missing
* Or bad data still present

### Root cause

* Wrong timestamp
* Timezone confusion

### Fix

* Check `timezone` setting
* Confirm application log time

One-minute mistake = wrong recovery.

---

## Failure 6: Missing timeline history file

### Symptom

* Recovery aborts with timeline error

### Root cause

* `.history` file missing in archive

### Fix

* Ensure timeline history files are archived
* Never delete `.history` files

---

## Failure 7: WAL archive filled disk

### Symptom

* Archiving stops
* Database slows or stops

### Root cause

* No retention policy
* Archive destination full

### Fix

* Clean old WAL safely
* Implement retention automation

---

## Failure 8: Restoring into dirty PGDATA

### Symptom

* Random startup errors
* Inconsistent state

### Root cause

* Old files mixed with restored files

### Fix

* Always restore into empty PGDATA
* Never overlay restore

---

## Failure 9: PITR works once, fails later

### Symptom

* First restore works
* Second restore fails

### Root cause

* Wrong timeline selected
* Old WAL reused incorrectly

### Fix

* Restore from base backup again
* Respect timeline branching

---

## DBA debugging checklist

When PITR fails, I check:

* PostgreSQL logs (first)
* `pg_stat_archiver`
* WAL archive content
* recovery settings
* timestamps and timeline

Logs always tell the truth.

---

## Final mental model

* PITR failures are procedural
* WAL and timelines are fragile
* Logs are your guide
* Calm debugging wins

---

## One-line explanation (interview ready)

Most PITR failures occur due to missing WAL files, incorrect recovery configuration, or timeline mismatches rather than PostgreSQL bugs.
