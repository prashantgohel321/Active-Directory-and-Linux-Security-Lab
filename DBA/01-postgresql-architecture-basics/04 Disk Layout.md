# PostgreSQL Disk Layout

## Why Disk Layout Is Important

When something goes wrong in PostgreSQL, like corruption, startup failure, or missing data, the first thing I need to understand is where PostgreSQL stores its data on disk.

PostgreSQL disk layout is simple, but touching it without understanding can permanently destroy data.

---

- [PostgreSQL Disk Layout](#postgresql-disk-layout)
  - [Why Disk Layout Is Important](#why-disk-layout-is-important)
  - [The Data Directory (Heart of PostgreSQL)](#the-data-directory-heart-of-postgresql)
  - [What Lives Inside the Data Directory](#what-lives-inside-the-data-directory)
  - [WAL Files (Write-Ahead Logs)](#wal-files-write-ahead-logs)
  - [Tablespaces (Advanced but Important)](#tablespaces-advanced-but-important)
  - [How PostgreSQL Reads and Writes Data](#how-postgresql-reads-and-writes-data)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## The Data Directory (Heart of PostgreSQL)

- PostgreSQL stores everything inside one main directory called the data directory. This directory contains database files, configuration files, WAL files, and internal metadata.

- If this directory is lost and no backup exists, the database cannot be recovered.

I can find the data directory using:

SHOW data_directory;

I should never edit files inside this directory manually.

---

<br>
<br>

## What Lives Inside the Data Directory

- Inside the data directory, PostgreSQL keeps multiple subdirectories and files. Each one has a purpose. Some store table data, some store indexes, some store transaction logs, and some store configuration.

- Even though files look like normal Linux files, they should never be modified directly. PostgreSQL controls them completely.

---

<br>
<br>

## WAL Files (Write-Ahead Logs)

- WAL files store records of every change made to the database. PostgreSQL writes to WAL first, and only later updates actual data files.

- This design allows PostgreSQL to recover safely after crashes or power failures.

- WAL files usually live inside the data directory, but in production they are often stored on separate disks for better performance and safety.

---

<br>
<br>

## Tablespaces (Advanced but Important)

- Tablespaces allow PostgreSQL to store data in locations outside the main data directory. This is useful when disks have different sizes or performance.

- For example, large tables or indexes can be placed on faster or larger disks.

- Even though tablespaces exist outside the data directory, PostgreSQL still controls them. Manual file operations are not allowed.

---

<br>
<br>

## How PostgreSQL Reads and Writes Data

- PostgreSQL does not directly read and write disk files for every query. Data is read into memory first, modified there, logged in WAL, and later written back to disk.

- This approach improves performance and keeps data safe.

---

<br>
<br>

## Simple Takeaway

- PostgreSQL disk layout is simple: one main data directory, WAL for safety, and optional tablespaces for flexibility.

- As a rule, I should never touch PostgreSQL files directly. If something is wrong at the disk level, the fix always goes through PostgreSQL commands, not Linux file edits.
