# PostgreSQL Directory Structure

## Why Directory Structure Matters

- Before changing any configuration or troubleshooting issues, I need to know where PostgreSQL keeps its files. If I don’t know this, I end up guessing paths or touching the wrong files, which is dangerous for databases.

- This section is about knowing what exists and what I should never touch manually.

---

- [PostgreSQL Directory Structure](#postgresql-directory-structure)
  - [Why Directory Structure Matters](#why-directory-structure-matters)
  - [PostgreSQL Data Directory](#postgresql-data-directory)
  - [Important Files Inside the Data Directory](#important-files-inside-the-data-directory)
  - [WAL Directory](#wal-directory)
  - [Log Files](#log-files)
  - [Binary and Configuration Locations](#binary-and-configuration-locations)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## PostgreSQL Data Directory

- PostgreSQL stores all its data and internal files inside one main directory called the data directory.

I can find its exact location using:
```bash
SHOW data_directory;
```

- On Rocky Linux, this is usually under `/var/lib/pgsql/15/data`, but I should always verify instead of assuming.

- This directory contains database files, indexes, WAL files, and internal metadata. If this directory is deleted and no backup exists, the data is gone permanently.

---

<br>
<br>

## Important Files Inside the Data Directory

- Inside the data directory, I will see files like `postgresql.conf`, `pg_hba.conf`, and `pg_ident.conf`. These are configuration files and are safe to edit carefully.

- I will also see many folders with random-looking names. These store table data and indexes. Even though they look like normal files, I must never edit or delete them manually.

- PostgreSQL is the only thing that should touch these files.

---

<br>
<br>

## WAL Directory

- WAL files are stored in a directory called `pg_wal` inside the data directory.

- These files record every change made to the database. They are critical for crash recovery and data safety.

- If WAL files are deleted or corrupted manually, PostgreSQL may not start or data may be lost.

---

<br>
<br>

## Log Files

- PostgreSQL logs are not always inside the data directory. On Rocky Linux, logs are usually managed by systemd and can be viewed using:
```bash
journalctl -u postgresql-15
```
Logs are the first place I check when PostgreSQL fails to start or behaves strangely.

---

<br>
<br>

## Binary and Configuration Locations

- PostgreSQL binaries are installed under `/usr/pgsql-15/bin`. This is where commands like `psql` and `pg_ctl` live.

- System service files are managed by systemd, and I control PostgreSQL using `systemctl`.

---

<br>
<br>

## Simple Takeaway

- PostgreSQL has a clear directory layout. The data directory is the most critical part, and it should never be modified manually.

- If I know where files live and what they do, troubleshooting becomes much safer and easier.
