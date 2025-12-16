# PostgreSQL Memory Architecture

## Why Memory Matters So Much

Most PostgreSQL problems in real life are memory-related. The database becomes slow, stops accepting connections, or the OS starts killing processes. All of this happens because memory was not understood properly.

PostgreSQL memory behavior is actually simple if I keep a few core ideas clear.

---

- [PostgreSQL Memory Architecture](#postgresql-memory-architecture)
  - [Why Memory Matters So Much](#why-memory-matters-so-much)
  - [Two Types of Memory in PostgreSQL](#two-types-of-memory-in-postgresql)
  - [Shared Buffers](#shared-buffers)
  - [work\_mem (Most Common Mistake)](#work_mem-most-common-mistake)
  - [maintenance\_work\_mem](#maintenance_work_mem)
  - [Memory and Connections](#memory-and-connections)
  - [PostgreSQL vs OS Memory](#postgresql-vs-os-memory)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## Two Types of Memory in PostgreSQL

- PostgreSQL uses two main types of memory: shared memory and private memory.

- Shared memory is created once when PostgreSQL starts. All backend processes use it together. Private memory is created separately inside each backend process when clients connect.

- This difference explains almost every memory issue.

---

<br>
<br>

## Shared Buffers

- **`shared_buffers`** is PostgreSQL’s main cache. When data is read from disk, it is kept here so future queries can read faster.

- If **`shared_buffers`** is too small, PostgreSQL keeps hitting disk. If it is too large, the OS does not get enough memory and the system becomes unstable.

I can check its value using:
```bash
SHOW shared_buffers;
```
---

<br>
<br>

## work_mem (Most Common Mistake)

- **`work_mem`** is private memory. It is used for operations like sorting and joins.

- This memory is allocated per operation, not per session. That means one query can use **`work_mem`** multiple times.

- If I set **`work_mem`** too high, memory usage explodes when many queries run at the same time.

To check it:
```bash
SHOW work_mem;
```
---

<br>
<br>

## maintenance_work_mem

- **`maintenance_work_mem`** is used for tasks like VACUUM and CREATE INDEX.

- Higher values make maintenance faster, but very high values can hurt if many maintenance tasks run together.

I can see its value using:
```bash
SHOW maintenance_work_mem;
```
---

<br>
<br>

## Memory and Connections

- Each client connection creates a backend process, and each <mark><b>backend process uses private memory</b></mark>.

- More connections mean more memory usage. This is why connection pooling is common and why max_connections should be kept reasonable.

To see current connections:
```bash
SELECT count(*) FROM pg_stat_activity;
```
---

<br>
<br>

## PostgreSQL vs OS Memory

- PostgreSQL depends on the operating system for caching as well. If PostgreSQL takes too much memory, the OS starts swapping, which is very bad for databases.

- A healthy setup leaves enough memory for the OS.

---

<br>
<br>

## Simple Takeaway

- PostgreSQL memory is predictable. Shared memory is global. Private memory grows with connections and queries.

- If I remember this, memory tuning stops being confusing and starts making sense.
