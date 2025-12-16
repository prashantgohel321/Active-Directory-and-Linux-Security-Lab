# PostgreSQL System Catalogs Overview

## Why System Catalogs Matter

- PostgreSQL stores all its internal information inside tables. These tables are called system catalogs. They tell PostgreSQL what databases exist, what users exist, what tables are created, and who owns what.

- If PostgreSQL forgets something, it checks system catalogs. This is why they are critical.

---

- [PostgreSQL System Catalogs Overview](#postgresql-system-catalogs-overview)
  - [Why System Catalogs Matter](#why-system-catalogs-matter)
  - [What System Catalogs Really Are](#what-system-catalogs-really-are)
  - [Commonly Used System Catalogs](#commonly-used-system-catalogs)
  - [How I Use System Catalogs in Practice](#how-i-use-system-catalogs-in-practice)
  - [System Catalogs vs Information Schema](#system-catalogs-vs-information-schema)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## What System Catalogs Really Are

- System catalogs are normal tables stored inside PostgreSQL. The difference is that PostgreSQL manages them internally.

- They store metadata, not user data. Things like table names, column names, data types, permissions, and indexes are all stored here.

- I never edit these tables directly. I only read from them.

---

<br>
<br>

## Commonly Used System Catalogs

- In daily work, I don’t need to know all catalogs. A few are enough to be effective.
- **`pg_database`** tells me about databases.
- **`pg_roles`** tells me about users and roles.
- **`pg_tables`** shows user tables.
- **`pg_class`** stores information about tables and indexes.

---

<br>
<br>

## How I Use System Catalogs in Practice

- When something looks wrong, system catalogs help me confirm reality.

For example, to see all databases:
```bash
SELECT datname FROM pg_database;
```
To see users and roles:
```bash
SELECT rolname FROM pg_roles;
```
To list tables:
```bash
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
```
These queries are safe and very useful for troubleshooting.

---

<br>
<br>

## System Catalogs vs Information Schema

- PostgreSQL also provides information_schema, which is more standard and portable.

- System catalogs are PostgreSQL-specific and more detailed. In real troubleshooting, system catalogs give more accurate answers.

---

<br>
<br>

## Simple Takeaway

- System catalogs are PostgreSQL’s internal memory. They tell PostgreSQL what exists and how things are connected.

- As an administrator, I read them to understand the system, but I never change them directly.
