# Lab: Understand PostgreSQL Internals

## Goal of This Lab

The goal of this lab is simple. I want to *see* PostgreSQL internals instead of just reading about them. By the end of this lab, I should be able to map theory to real commands and outputs.

This lab is not about tuning or optimization. It is about observation and understanding.

---

- [Lab: Understand PostgreSQL Internals](#lab-understand-postgresql-internals)
  - [Goal of This Lab](#goal-of-this-lab)
  - [Lab Prerequisites](#lab-prerequisites)
  - [Step 1: Verify PostgreSQL Is Running](#step-1-verify-postgresql-is-running)
  - [Step 2: Observe PostgreSQL Processes](#step-2-observe-postgresql-processes)
  - [Step 3: Connect to PostgreSQL](#step-3-connect-to-postgresql)
  - [Step 4: Observe Backend Processes](#step-4-observe-backend-processes)
  - [Step 5: Inspect Active Sessions](#step-5-inspect-active-sessions)
  - [Step 6: Check Memory-Related Settings](#step-6-check-memory-related-settings)
  - [Step 7: Locate the Data Directory](#step-7-locate-the-data-directory)
  - [Step 8: Observe WAL Activity](#step-8-observe-wal-activity)
  - [Step 9: Exit Cleanly](#step-9-exit-cleanly)
  - [What I Learned From This Lab](#what-i-learned-from-this-lab)


<br>
<br>

## Lab Prerequisites

- PostgreSQL should be installed and running on my Rocky Linux system.

- I should have access to the postgres system user.

---

<br>
<br>

## Step 1: Verify PostgreSQL Is Running

First, I confirm that PostgreSQL is active.
```bash
sudo systemctl status postgresql-15
```
If the service is not running, I start it:
```bash
sudo systemctl start postgresql-15
```
---

<br>
<br>

## Step 2: Observe PostgreSQL Processes

Now I check how PostgreSQL looks at the OS level.
```bash
ps -ef | grep postgres
```
I should see:

* One postmaster process
* Multiple postgres processes
* Background processes

This confirms the process-based architecture.

---

<br>
<br>

## Step 3: Connect to PostgreSQL

I switch to the postgres user and open psql.
```bash
sudo -i -u postgres
psql
```
Once connected, I confirm PostgreSQL is responding:
```bash
SELECT version();
```
---

<br>
<br>

## Step 4: Observe Backend Processes

While psql is open, I open another terminal and run:
```bash
ps -ef | grep postgres
```
I should notice an additional backend process created for my psql session.

This confirms that one client creates one backend process.

---

<br>
<br>

## Step 5: Inspect Active Sessions

From inside psql, I check active connections.
```bash
SELECT pid, usename, datname, state, query
FROM pg_stat_activity;
```
I should see my current session listed here.

---

<br>
<br>

## Step 6: Check Memory-Related Settings

Now I inspect key memory parameters.
```bash
SHOW shared_buffers;
SHOW work_mem;
SHOW maintenance_work_mem;
```
I am not tuning anything yet. I am only observing.

---

<br>
<br>

## Step 7: Locate the Data Directory

I find where PostgreSQL stores its data.
```bash
SHOW data_directory;
```
I note the path but do not touch anything inside it.

---

<br>
<br>

## Step 8: Observe WAL Activity

I check WAL-related settings.
```bash
SHOW wal_level;
SHOW synchronous_commit;
```
This confirms that WAL is enabled and active.

---

<br>
<br>

## Step 9: Exit Cleanly

I exit psql and return to my normal user.
``` bash
\q
exit
```
---

<br>
<br>

## What I Learned From This Lab

In this lab, I verified that:

* PostgreSQL runs as Linux processes
* Each client creates a backend process
* Memory settings are visible and configurable
* PostgreSQL data lives in a single data directory
* WAL is always active

This lab turns architecture theory into real, observable behavior.

---
