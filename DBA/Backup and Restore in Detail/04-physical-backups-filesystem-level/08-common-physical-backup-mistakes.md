# Common Physical Backup Mistakes in PostgreSQL (Real-World Failures)

## In simple words

Physical backups are powerful, but also dangerous when done casually.

Most PostgreSQL disaster stories happen not because physical backups are bad, but because **DBAs misunderstood or skipped critical steps**.

This file lists the mistakes that actually cause data loss.

---

## Mistake 1: Copying PGDATA while PostgreSQL is running

Some DBAs assume:

> “cp -r $PGDATA is enough”

If PostgreSQL is running:

* files are changing
* pages may be half-written
* backup becomes inconsistent

This backup may restore but corrupt data silently.

Correct approach:

* stop PostgreSQL
* or use WAL-aware methods

---

## Mistake 2: Ignoring WAL during online backups

Online physical backups **require WAL**.

Common wrong assumptions:

* snapshot alone is enough
* crash recovery will fix everything

Without required WAL:

* restore fails
* or data corruption occurs

Never take online physical backups without WAL planning.

---

## Mistake 3: Running out of disk due to WAL growth

During backup:

* WAL retention increases
* archived WAL piles up

If disk fills:

* database may stop
* writes fail
* replication breaks

Monitoring WAL size during backups is mandatory.

---

## Mistake 4: Forgetting tablespaces

Backing up only PGDATA while tablespaces exist:

* misses real data
* breaks restore

This mistake is extremely common.

Correct approach:

* always inventory tablespaces
* back up all tablespace paths

---

## Mistake 5: Inconsistent snapshots across filesystems

Snapshots taken at different times:

* PGDATA snapshot now
* tablespace snapshot later

This creates mismatched states.
Restore may succeed but data will be wrong.

Snapshots must be coordinated.

---

## Mistake 6: Restoring to different paths or permissions

Physical restore expects:

* same directory layout
* correct ownership
* correct permissions

Wrong paths or ownership:

* PostgreSQL refuses to start
* recovery fails

Always match original environment.

---

## Mistake 7: Mixing PostgreSQL versions

Physical backups are version-specific.

Restoring:

* PG 14 backup into PG 15
* will fail

Upgrades require logical backups or pg_upgrade.

---

## Mistake 8: No restore testing

Many teams:

* take physical backups daily
* never test restore

Until the day recovery is needed.

Physical backups must be tested, especially with WAL replay.

---

## Mistake 9: Deleting WAL files manually

Deleting WAL to free space:

* breaks recovery chain
* makes backups unusable

WAL cleanup must be automated and controlled.

---

## Mistake 10: Overconfidence in automation

Automation hides failures.

If:

* scripts fail silently
* snapshot does not complete

You think backups exist, but they don’t.

Automation must include verification.

---

## Final mental model

* Physical backups are unforgiving
* WAL and tablespaces are critical
* Snapshots need coordination
* Testing is non-negotiable

---

## One-line explanation (interview ready)

Most physical backup failures in PostgreSQL occur due to WAL mishandling, missing tablespaces, inconsistent snapshots, or untested restore processes.
