# PostgreSQL Architecture Overview

## Why I Am Starting With Architecture

- I am starting PostgreSQL with architecture because most real problems are not SQL problems. When PostgreSQL becomes slow, runs out of memory, or stops accepting connections, the reason is almost always how it works internally, not what query someone wrote.

- If I understand the basics of architecture, debugging becomes logical instead of guessing.

---

- [PostgreSQL Architecture Overview](#postgresql-architecture-overview)
  - [Why I Am Starting With Architecture](#why-i-am-starting-with-architecture)
  - [How PostgreSQL Is Built](#how-postgresql-is-built)
  - [Why Connections Matter So Much](#why-connections-matter-so-much)
  - [PostgreSQL and Disk Safety](#postgresql-and-disk-safety)
  - [Data Directory](#data-directory)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## How PostgreSQL Is Built

- PostgreSQL uses <mark><b>a process-based design</b></mark>. This simply means it creates separate Linux processes instead of using threads.

- When PostgreSQL starts, it creates one main process called the <mark><b>postmaster</b></mark>. This process waits for client connections. Whenever a client connects, the postmaster creates a new backend process only for that client.

- One client equals one backend process. This is the most important rule to remember.

I can see this clearly on Linux using:
```bash
ps -ef | grep postgres

# -e → show all processes
# -f → full format (user, PID, PPID, command, etc.)
```

---

<br>
<br>

## Why Connections Matter So Much

- Because every connection creates a backend process, connections are expensive. More connections mean more memory usage.

- This is why increasing max_connections blindly causes problems and why connection pooling is common in production.

To check active connections, I use:
```bash
SELECT count(*) FROM pg_stat_activity;
```

---

<br>
<br>

## PostgreSQL and Disk Safety

- PostgreSQL does not write data directly to disk. Changes are first recorded in WAL files and then written to data files. This makes PostgreSQL safe during crashes and power failures.

- This design is the reason PostgreSQL can recover cleanly after unexpected shutdowns.

---

## Data Directory

- All PostgreSQL data lives inside one data directory. If this directory is lost and no backup exists, the data is gone.

I can find its location using:
```bash
SHOW data_directory;
```
I should never manually edit files inside this directory.

---

## Simple Takeaway

PostgreSQL is not a black box. It is a collection of Linux processes using memory and disk in a predictable way. Once I understand this, everything else becomes easier.
