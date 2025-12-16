# PostgreSQL Process Architecture

## Why Process Architecture Is Important

PostgreSQL runs as a set of Linux processes. If I understand this, many problems become easy to explain. If I don’t, everything looks random when the database slows down or stops responding.

Most real issues like high memory usage, too many connections, or CPU spikes are directly related to PostgreSQL processes.

---

- [PostgreSQL Process Architecture](#postgresql-process-architecture)
  - [Why Process Architecture Is Important](#why-process-architecture-is-important)
  - [One Client = One Process](#one-client--one-process)
  - [What the Postmaster Does](#what-the-postmaster-does)
  - [What Backend Processes Do](#what-backend-processes-do)
  - [Why Too Many Connections Is a Problem](#why-too-many-connections-is-a-problem)
  - [Background Processes](#background-processes)
  - [Simple Takeaway](#simple-takeaway)

<br>
<br>

## One Client = One Process

- PostgreSQL follows a very simple rule. Every client connection gets its own backend process.

- When PostgreSQL starts, it creates one main process called the postmaster. This process listens for connections. Whenever a client connects, the postmaster creates a new backend process only for that client.

- That backend process lives as long as the client is connected. When the client disconnects, the process exits.

I can see all these processes using:
```bash
ps -ef | grep postgres
```
---

<br>
<br>

## What the Postmaster Does

The postmaster is the parent process. It does not run queries or touch data.

Its job is to:

* Accept client connections
* Create backend processes
* Monitor background processes
* Shut down PostgreSQL cleanly

If the postmaster stops, PostgreSQL is down.

---

<br>
<br>

## What Backend Processes Do

- Backend processes do the actual work. They parse SQL, execute queries, read and write data, and use memory.

- Backend processes do not talk to each other directly. They coordinate using shared memory and locks.

To see which backends are active, I use:
```bash
SELECT pid, usename, datname, state, query
FROM pg_stat_activity;
```
---

<br>
<br>

## Why Too Many Connections Is a Problem

- Each backend process uses memory. More connections mean more processes and more memory usage.

- This is why increasing max_connections without thinking causes problems. In real setups, a connection pooler is usually placed in front of PostgreSQL.

To check how many connections are active:
```bash
SELECT count(*) FROM pg_stat_activity;
```
---

<br>
<br>

## Background Processes

Apart from client backends, PostgreSQL runs background processes. These handle WAL writing, flushing data to disk, collecting stats, and cleanup work.

These processes are always running in a healthy system. If they are blocked or killed, performance drops quickly.

---

<br>
<br>

## Simple Takeaway

PostgreSQL is a collection of Linux processes working together. If I understand which process does what, troubleshooting becomes straightforward instead of confusing.
