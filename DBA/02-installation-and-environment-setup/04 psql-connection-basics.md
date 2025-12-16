# psql Connection Basics

## Why psql Matters

- psql is the default command-line tool to interact with PostgreSQL. As a Linux or DevOps engineer, this is the first and most reliable way to check whether PostgreSQL is working.

- If psql connects successfully, PostgreSQL is alive.

---

- [psql Connection Basics](#psql-connection-basics)
  - [Why psql Matters](#why-psql-matters)
  - [Connecting as the postgres User](#connecting-as-the-postgres-user)
  - [Basic psql Prompt Understanding](#basic-psql-prompt-understanding)
  - [Common psql Meta Commands](#common-psql-meta-commands)
  - [Running Simple SQL Commands](#running-simple-sql-commands)
  - [Exiting psql Safely](#exiting-psql-safely)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## Connecting as the postgres User

- PostgreSQL creates a system user called postgres. This user has full access to the database by default.

To connect locally, I first switch to the postgres user:
```bash
sudo -i -u postgres
```
Then I open psql:
```bash
psql
```
If this works, PostgreSQL is running and accepting connections.

---

<br>
<br>

## Basic psql Prompt Understanding

Once inside psql, I see a prompt like:
```bash
postgres=#
```
This means I am connected to the postgres database as the postgres user.

If the prompt ends with `#`, I have superuser access. If it ends with `>`, I am a normal user.

---

<br>
<br>

## Common psql Meta Commands

psql has internal commands that start with a backslash. These are not SQL commands.

To list databases:
```bash
\l
```
To list users and roles:
```bash
\du
```
To list tables in the current database:
```bash
\dt
```
To switch databases:
```bash
\c dbname
```
These commands are used constantly in day-to-day work.

---

<br>
<br>

## Running Simple SQL Commands

Inside psql, I can run SQL directly.

To check PostgreSQL version:
```bash
SELECT version();
```
To check current user:
```bash
SELECT current_user;
```
---

<br>
<br>

## Exiting psql Safely

To exit psql:

\q

This closes the session cleanly.

---

<br>
<br>

## Simple Takeaway

psql is the fastest way to confirm PostgreSQL health and inspect basic information.

If I am comfortable with psql, PostgreSQL administration becomes much easier.
