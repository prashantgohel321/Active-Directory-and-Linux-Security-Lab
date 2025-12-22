# PostgreSQL File System Level Backup – Step‑By‑Step Real Scenario Guide

- [PostgreSQL File System Level Backup – Step‑By‑Step Real Scenario Guide](#postgresql-file-system-level-backup--stepbystep-real-scenario-guide)
  - [What a filesystem-level backup is:](#what-a-filesystem-level-backup-is)
  - [Scenario Overview](#scenario-overview)
  - [Step 1: Stop the Server Before Backup](#step-1-stop-the-server-before-backup)
  - [Step 2: Copy the Entire Data Directory](#step-2-copy-the-entire-data-directory)
  - [Step 3: Store the Backup Safely](#step-3-store-the-backup-safely)
  - [Step 4: Simulate Disaster](#step-4-simulate-disaster)
  - [Step 5: Remove the Damaged Data Directory](#step-5-remove-the-damaged-data-directory)
  - [Step 6: Extract the Backup](#step-6-extract-the-backup)
  - [Step 7: Start PostgreSQL](#step-7-start-postgresql)
  - [Step 8: Snapshot‑Based Backups (When Downtime Isn’t Allowed)](#step-8-snapshotbased-backups-when-downtime-isnt-allowed)
  - [Step 9: WAL Inclusion Requirement](#step-9-wal-inclusion-requirement)
  - [Step 10: Multi‑Filesystem Warning](#step-10-multifilesystem-warning)
  - [Step 11: File System Backups vs SQL Dumps](#step-11-file-system-backups-vs-sql-dumps)
  - [Final Understanding Through This Flow](#final-understanding-through-this-flow)


<br>
<br>

## What a filesystem-level backup is:
- It means copying the raw PostgreSQL data directory at the OS level (files, folders, blocks) instead of dumping SQL.

**Why needed?**
- Because it gives a full physical snapshot that can be restored exactly as it was — useful for PITR, replication, fast disaster recovery, and huge databases.

What it includes:
- data files
- WAL files
- config files
- tables + indexes (as physical pages)
- system catalogs

> Basically everything under $PGDATA.


<br>
<br>

## Scenario Overview

A PostgreSQL server is running a database on a Linux machine. Data lives inside the PostgreSQL data directory at:

```bash
/var/lib/pgql/15/main
# OR Simply
$PGDATA
```

**The goal**: create a full file system backup of the database, then restore it later to bring the server back exactly as it was. This guide follows that real flow, not theory.

---

<br>
<br>

## Step 1: Stop the Server Before Backup

- A file system backup must capture files in a frozen state. PostgreSQL constantly updates pages and transaction logs while running, so copying live files risks corruption.

Stop PostgreSQL cleanly:

```bash
sudo systemctl stop postgresql
```

- do not rely on blocking connections — the server must be offline.
- Once stopped, nothing is changing in the data directory and the files are safe to copy.

---

<br>
<br>

## Step 2: Copy the Entire Data Directory

After shutdown, take a full directory copy. Do not pick individual tables or subfolders.

Use tar to freeze everything:

```bash
cd /var/lib/pgsql/15
sudo tar -cf /backups/main_backup.tar main
```

This produces a file containing:
* heap tables
* indexes
* transaction logs
* system catalogs
* configuration files

The backup now represents the whole cluster at shutdown time.

<br>
<details>
<summary><b>Breakdown of sudo tar -cf /backups/main_backup.tar main</b></summary>
<br>

- **`tar`**: Archiving tool used to bundle files/folders.
- **`-c`**: Create a new archive.
- **`-f /backups/main_backup.tar`**: Write the archive to this file path and name.
- **`main`**: The directory being packed into the archive.

</details>
<br>

---

<br>
<br>

## Step 3: Store the Backup Safely

Move the tar file to external storage:

```bash
sudo mv /backups/main_backup.tar /safe/location/
```

- Physical backups are raw binary copies, so they will be large. They include everything inside PostgreSQL, even empty page space.

- Once stored, the tar file is your frozen state image.

---

<br>
<br>

## Step 4: Simulate Disaster

- Imagine that days later PostgreSQL fails. Files are damaged or deleted. The database will not start.

- The file system backup will now be used to restore.

Stop PostgreSQL immediately if it is running in a broken state:

```bash
sudo systemctl stop postgresql
```

---

<br>
<br>

## Step 5: Remove the Damaged Data Directory

- A restore requires replacing the cluster directory completely.

Delete the corrupted directory:

```bash
sudo rm -rf /var/lib/pgsql/15/main
```

Never mix backed‑up files with existing ones. The server expects perfect internal consistency.

---

<br>
<br>

## Step 6: Extract the Backup

Place the tar file back into PostgreSQL’s data location:

```bash
cd /var/lib/pgsql/15
sudo tar -xf /safe/location/main_backup.tar
```

Make sure permissions match the postgres user:

```bash
sudo chown -R postgres:postgres main
```

At this point the directory looks exactly like it did at backup time.

---

<br>
<br>

## Step 7: Start PostgreSQL

Start the server normally:

```bash
sudo systemctl start postgresql-15
```

- PostgreSQL reads the recovered files and boots into the same state they had when the backup was taken.

- If the previous shutdown happened cleanly, PostgreSQL starts normally. If the shutdown was dirty, PostgreSQL performs crash recovery automatically using the WAL files stored inside the backup.

---

<br>
<br>

## Step 8: Snapshot‑Based Backups (When Downtime Isn’t Allowed)

Some filesystems offer snapshot volume freezing. In this case PostgreSQL can remain online:

1. trigger filesystem snapshot
2. copy data directory from snapshot
3. release snapshot

After restore, PostgreSQL replays WAL and comes online.

Run a checkpoint before snapshot to reduce replay time:

```bash
CHECKPOINT;
```

Snapshots must include the entire cluster directory. Partial snapshots break consistency.

---

<br>
<br>

## Step 9: WAL Inclusion Requirement

- WAL information must be present inside the backup. PostgreSQL needs WAL to recover crash‑state pages.

- If WAL is missing, the restored instance cannot rebuild consistency.

- This is why copying only table files never works.

---

<br>
<br>

## Step 10: Multi‑Filesystem Warning

- If the cluster uses tablespaces on different disks, all locations must be snapped at the same instant.

If timestamps differ:

* table files reflect newer versions
* pg_xact reflects older transactions

The restored copy becomes unusable.

In such setups, consider continuous archiving or shutting down PostgreSQL before snapshotting.

---

<br>
<br>

## Step 11: File System Backups vs SQL Dumps

Physical backups include everything:

* index data
* empty space
* vacuum leftovers
* hint bits

They are larger than SQL dumps but much faster to produce.

SQL dumps rebuild databases logically. Physical backups restore them byte‑for‑byte.

---

<br>
<br>

## Final Understanding Through This Flow

A file system backup is simply freezing the PostgreSQL data directory and restoring it later. It works perfectly only when:

* PostgreSQL was shut down or the filesystem snapshot is atomic
* the entire directory is copied
* WAL remains intact

This method gives a full binary clone of the server. It is ideal for migrations to identical hardware or for fast full recovery where downtime is acceptable.
