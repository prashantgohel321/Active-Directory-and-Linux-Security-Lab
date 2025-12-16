# Database Lifecycle in PostgreSQL

## Why Database Lifecycle Matters

In real environments, databases are not created once and forgotten. They are created, modified, renamed, maintained, and sometimes removed. If I don’t understand this lifecycle, I risk breaking applications or losing data.

This file focuses on the everyday actions I actually perform as an admin.

---

<br>
<br>

## Creating a Database

A database is created at the PostgreSQL level. I usually do this as an admin role.
```bash
CREATE DATABASE appdb;
```
By default, the postgres user becomes the owner. Ownership matters because the owner controls permissions.

---

<br>
<br>

## Listing Existing Databases

To see all databases:
```bash
\l
```
This is the fastest way to check what exists on the server.

---

<br>
<br>

## Connecting to a Database

Permissions apply per database, so I often switch databases:
```bash
\c appdb
```
If I cannot connect, it usually means CONNECT permission is missing.

---

<br>
<br>

## Changing Database Ownership

Sometimes ownership needs to change, especially when postgres should not own application databases.
```bash
ALTER DATABASE appdb OWNER TO app_owner;
```
Ownership defines who can manage the database.

---

<br>
<br>

## Renaming a Database

Databases can be renamed, but this should be done carefully and usually during downtime.
```bash
ALTER DATABASE appdb RENAME TO appdb_new;
```
Active connections must be closed before renaming.

---

<br>
<br>

## Dropping a Database

Dropping a database permanently deletes all data inside it.
```bash
DROP DATABASE appdb;
```
This command should never be run casually. I always double-check the database name.

---

<br>
<br>

## Simple Takeaway

A database has a lifecycle: create, use, manage, and eventually remove.

If I handle ownership and permissions correctly, database management stays safe and predictable.
