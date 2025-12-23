# PostgreSQL System Catalogs – Step‑By‑Step Real Scenario Guide

<br>
<br>

- [PostgreSQL System Catalogs – Step‑By‑Step Real Scenario Guide](#postgresql-system-catalogs--stepbystep-real-scenario-guide)
  - [What are system catalogs?](#what-are-system-catalogs)
  - [Scenario Overview](#scenario-overview)
  - [Step 1: PostgreSQL Starts With an Empty Cluster](#step-1-postgresql-starts-with-an-empty-cluster)
  - [Step 2: Creating a New Database](#step-2-creating-a-new-database)
  - [Step 3: Connecting to the Database](#step-3-connecting-to-the-database)
  - [Step 4: Creating a Table](#step-4-creating-a-table)
  - [Step 5: Understanding **`pg_class`**](#step-5-understanding-pg_class)
  - [Step 6: Adding an Index](#step-6-adding-an-index)
  - [Step 7: Creating a User](#step-7-creating-a-user)
  - [Step 8: Granting Permissions](#step-8-granting-permissions)
  - [Step 9: Creating a Function](#step-9-creating-a-function)
  - [Step 10: Installing an Extension](#step-10-installing-an-extension)
  - [Step 11: Triggers and Constraints](#step-11-triggers-and-constraints)
  - [Step 12: Tablespaces and Cluster‑Wide Metadata](#step-12-tablespaces-and-clusterwide-metadata)
  - [Step 13: How psql Commands Work](#step-13-how-psql-commands-work)
  - [Step 14: Why Catalogs Must Never Be Modified Manually](#step-14-why-catalogs-must-never-be-modified-manually)
  - [Final Understanding Through This Flow](#final-understanding-through-this-flow)

<br>
<br>

## What are system catalogs?

- System catalogs are PostgreSQL’s own internal tables where it remembers everything about itself — 
  - what tables exist, 
  - who owns them, 
  - which columns they have, 
  - what permissions apply, and 
  - how things are linked.

<br>
<br>

## Scenario Overview

- A PGSQL server is running normally. A DBA creates databases, tables, users, indexes, and permissions every day. 


PostgreSQL somehow remembers all of this information and uses it internally to answer questions like:
- Which databases exist?
- Which tables belong to which schema?
- Which columns exist and what are their data types?
- Who owns what?
- Which user can access which object?

All of this information lives in system catalogs.

---

<br>
<br>

## Step 1: PostgreSQL Starts With an Empty Cluster

- When PGSQL is installed and initialized, it creates a database cluster. At this moment, there are no user tables yet, but PostgreSQL already creates a set of internal tables. These internal tables are called <mark><b>system catalogs</b></mark>.

- They are regular tables <mark><b>stored on disk</b></mark>, but PGSQL treats them as <mark><b>read‑only metadata storage</b></mark>. Every database action depends on them.

---

<br>
<br>

## Step 2: Creating a New Database

A DBA runs:

```bash
CREATE DATABASE appdb;
```

- PostgreSQL does not create catalogs from scratch. Instead, it copies most catalog data from a template database, usually **`template1`**.

- This means appdb already contains catalog tables that describe schemas, data types, functions, and defaults.

- One catalog that changes immediately is **`pg_database`**. A new row is added describing appdb.

At this point:

* PostgreSQL knows appdb exists
* clients can connect to it
* internal metadata is ready

---

<br>
<br>

## Step 3: Connecting to the Database

- A client connects to **`appdb`**.

- PostgreSQL checks **`pg_database`** to confirm the database exists and is allowed to accept connections.

- Without **`pg_database`**, PostgreSQL would not even know where to route the connection.

---

<br>
<br>

## Step 4: Creating a Table

Inside appdb, the DBA runs:

```bash
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT
);
```

PostgreSQL does not just create a data file on disk. It first records metadata.

- **`pg_class`** receives a new entry describing the table itself.
- **`pg_namespace`** is used to record which schema the table belongs to.
- **`pg_attribute`** receives one row per column describing column names, data types, and order.
- **`pg_constraint`** stores the primary key constraint.

Only after catalogs are updated does PostgreSQL create the physical table files.

---

<br>
<br>

## Step 5: Understanding **`pg_class`**

- **`pg_class`** is the catalog that describes relations.

Relations include:

* tables
* indexes
* views
* sequences

- Whenever PGSQL needs to know whether an object exists or what type it is, it reads **`pg_class`**.

> If **`pg_class`** loses consistency, PostgreSQL cannot function.

---

<br>
<br>

## Step 6: Adding an Index

The DBA runs:

```bash
CREATE INDEX idx_users_email ON users(email);
```

PostgreSQL updates pg_class again to register the index.

pg_index stores which table the index belongs to and which column it references.

Now PostgreSQL knows:

* this index exists
* which table it supports
* how to use it during query planning

<br>
<details>
<summary><mark><b style="color:black">INDEX explained and Query Breakdown (CREATE INDEX idx_users_email ON users(email);)</b></mark></summary>
<br>

```bash
CREATE INDEX idx_users_email ON users(email);
```

- **`CREATE INDEX`**: Tells PostgreSQL to build an index for faster lookups.
- **`idx_users_email`**: Name of the index being created.
- **`ON users`**: Specifies the table on which the index is built.
- **`(email)`**: Column used in the index.

**Think of it like**: Create a shortcut on the email column of the users table so searches become faster.


---

**What index is?**
- An index is a data structure PostgreSQL creates to find rows faster, so it doesn’t have to scan the entire table every time.
- It’s like the index page of a book — instead of reading every page, PostgreSQL jumps directly to the needed data.

**Verify the index exist:**
```bash
\di

# OR

select indexname, indexdef from pg_indexes where tablename = 'users';
```

**Check if queries actually use it**
```bash
EXPLAIN SELECT * FRPM users WHERE email='a@b.com';
# Shows how PostgreSQL plans to run the query — which index or scan it thinks it will use and the estimated cost.
# It does not actually run the query.


# OR

EXPLAIN ANALYZE SELECT * FROM users WHERE email='a@b.com';
# Actually runs the query and then shows the real execution details — real time taken, rows processed, and whether the plan was accurate.

# In short:
  # EXPLAIN = plan only (estimates)
  # EXPLAIN ANALYZE = plan + real execution
```

> If you see index scan, the index is being used.

**Maintain it:**
Indexes need:
- VACCUM -> to clean dead entries
- REINDEX -> If bloated or corrupted

```bash
REINDEX INDEX idx_users_email;
```

**Drop it if useless:**
If an index is never used:
```bash
DROP INDEX idx_users_email;
```

**Monitor index usage:**
```bash
SELECT relname, idx_scan 
FROM pg_stats_user_indexes
WHERE indexrelname='idx_users_email';
```

> Indexes are not free. They Speed up reads but slow down writes and use disk space.

</details>
<br>

---

<br>
<br>

## Step 7: Creating a User

The DBA creates a new role:

```bash
CREATE USER app_user WITH PASSWORD 'secret';
```

- PostgreSQL records this in **`pg_authid`**.

- **`pg_authid`** is shared across the entire cluster. All databases see the same roles.

- <u><b>Authentication</b></u>, <u><b>permissions</b></u>, and <u><b>ownership</b></u> checks all depend on this catalog.

<br>
<details>
<summary><mark><b>USER ROLES Explained and Query Breakdown CREATE USER app_user WITH PASSWORD 'secret';</b></mark></summary>
<br>

```bash
CREATE USER app_user WITH PASSWORD 'secret';
```

**What it does:**
- Creates a login role named **`app_user`**
- Assigns a password so the user can authenticate
- The user can now connect to PGSQL, but has no permissions yet


**What this user can do by default:**
- Can log in
- Cannot access any database objects
- Cannot create tables, databases, or roles
- Cannot read or write data

This is intentional and secure.

---

**What we can do next:**
**1. Allow database connection:**
```bash
GRANT CONNECT ON DATABASE appdb2 TO app_user;
```

**2. Give Permissions via roles:**
```bash
GRANT app_readwrite TO app_user;
```

**3. Restrict access:**
```bash
REVOKE ALL ON DATABASE appdb2 FROM app_user;
```

**4. Change Password Later:**
```bash
ALTER USER app_user WITH PASSWORD 'newsecret';
```

**5. Remove the user:**
```bash
DROP USER app_user;
```

**Notes:**
- Password is stored hashed, not plain text.
- Work only if **`pg_hba.conf`** allows password (**`md5`** / **`scram`**)
- Should never be granted permissions directly in production.

</details>
<br>

---

<br>
<br>

## Step 8: Granting Permissions

The DBA runs:

```bash
GRANT SELECT ON users TO app_user;
```

- PostgreSQL updates permission metadata stored in catalogs linked to **`pg_class`** and **`pg_authid`**.

- Later, when **`app_user`** runs a **`SELECT`**, PostgreSQL checks these catalog entries before executing the query.

---

<br>
<br>

## Step 9: Creating a Function

A function is added:

```bash
CREATE FUNCTION get_user_count()
RETURNS integer AS $$
SELECT COUNT(*) FROM users;
$$ LANGUAGE SQL;
```

- PostgreSQL stores this function definition in **`pg_proc`**.
- **`pg_proc`** holds all functions and procedures known to the database.
- Whenever a function is called, PostgreSQL reads **`pg_proc`** to know how to execute it.

<br>
<details>
<summary><mark><b>What function is and Query Breakdown.</b></mark></summary>
<br>

**What is a function?**
- A function is a stored piece of logic inside the database that runs on the server and returns a result.
- It lets me reuse logic, keep code close to data, and avoid repeating the same SQL everywhere.

Think of it like:
- “A reusable SQL shortcut with a name.”

```bash
CREATE FUNCTION get_user_count()
RETURNS integer AS $$
SELECT COUNT(*) FROM users;
$$ LANGUAGE SQL;
```

- **`CREATE FUNCTION get_user_count():`**Creates a function named **`get_user_count`** that takes no arguments.
- **`Returns integer:`** The function will return a single integer value.

```bash
# The actual logic of the function.

AS $$
SELECT COUNT(*) FROM appdb2_users;
$$

# Here it counts rows in the users table.
```

- **`LANGUAGE SQL:`** Tells PostgreSQL this function is written in plain SQL (not PL/pgSQL, Python, etc.).

---

**How to use it:**

**Call the function:**
```bash
SELECT get_user_count();
```

**Security Control:**
```bash
GRANT EXECUTE ON FUNCTION get_user_count() TO app_user;

# I can deny direct table access.
# I can allow users to execute the function only.
```

**Drop the function:**
```bash
DROP FUNCTION get_user_count();
```

</details>
<br>

---

<br>
<br>

## Step 10: Installing an Extension

The DBA runs:

```bash
CREATE EXTENSION uuid-ossp;
```

PostgreSQL records the extension inside **`pg_extension`**.

This allows PostgreSQL to track:

* which extensions are installed
* which objects belong to which extension

This makes upgrades and clean removals possible.

<br>
<details>
<summary><mark><b>Extensions Explained</b></mark></summary>
<br>

**What is Extension?**
- An extension is a packaged feature set that adds extra functionality in PGSQL without you writing code.
- A plugin that adds new functions, data types or operators to the database.
- PGSQL core stays small, and extensions add power when needed.
- Install extension only once per database. Extensions are database-specific, not clsuter-wide.
- Only super users (or users with permissions) can install extensions, because extensions can add powerful functions.

```bash
CREATE EXTENSION uuid-ossp;
```

- **`CREATE EXTENSION:`** Tells PGSQL to install and enable an extension in the current database.
- **`uuid-ossp:`** Name of the extension that provides UUID generation functions.

**What is uuid-ossp is used for?**
- It adds functions to generate UUIDs (Universally Unique Identifiers).

Most common function:
```bash
uuid_generate_v4()
```
Used when:
- we want globally unique ids.
- we dont want predictable IDs (like 1, 2, 3)
- Data is generated across multiple servers or services.

---

Example Usage:

**Create table with UUID primary key:**
```bash
CREATE TABLE users(
  id UUID DEFAULT uuid_generate_v4(),
  name TEXT
);

# Each insert automatically gets a unique ID

INSERT INTO users (name) VALUES ('ABC');
```

**Why use UUID instead of SERIAL?**
- SERIAL -> sequential, predictable
- UUID -> random, globally unique

UUIDs are better for:
- distributed systems
- microservices
- replication across regions

**Check installed extensions:**
```bash
\dx
```

**Grant usage to users:**
```bash
GRANT USAGE ON SCHEMA public TO app_user;
```

**Remove Extension:**
```bash
DROP EXTENSION uuid-ossp;
```

</details>
<br>

---

<br>
<br>

## Step 11: Triggers and Constraints

If a trigger is added:

```bash
CREATE TRIGGER trg_users
BEFORE INSERT ON users
FOR EACH ROW EXECUTE FUNCTION some_function();
```

- PostgreSQL stores trigger metadata in **`pg_trigger`**.

- Every time an insert happens, PostgreSQL consults pg_trigger to know which trigger to fire.

- Similarly, check, foreign key, and unique constraints are stored in pg_constraint.

<br>
<details>
<summary><mark><b>Triggers Explained</b></mark></summary>
<br>

**What is a trigger?**
- A trigger is automatic logic that runs when something happens in a table like INSERT, UPDATE, or DELETE.
- No need to call it manually; PGSQL fires it automatically.
- If this even happens, automatically run this function.

```bash
CREATE TRIGGER trg_users
BEFORE INSERT ON users
FOR EACH ROW EXECUTE FUNCTION some_function();
```

- **`CREATE TRIGGER trg_users`**: Creates a trigger named trg_users.
- **`BEFORE INSERT ON users`**: The trigger fires before a new is inserted into the users table.
- **`FOR EACH ROW`**: Runs once per row, not once per statement.
- **`EXECUTE FUNCTION some_function()`**: Calls the trigger function that contains the logic to execute.

--- 

**Disable or Drop trigger:**
```bash
ALTER TABLE users DISABLE TRIGGER trg_users;
DROP TRIGGER trg_users ON users;
```


</details>
<br>

---

<br>
<br>

## Step 12: Tablespaces and Cluster‑Wide Metadata

- Tablespaces are recorded in pg_tablespace.

- This catalog is shared across the entire cluster.

- PGSQL uses it to map logical storage locations to physical directories.

<br>
<details>
<summary><mark><b>Tablespace explained in detail</b></mark></summary>
<br>

- A tablespace tells PGSQL where on disk data should be stored. PGSQL keeps track of all tablespaces inside the **`pg_tablespace`** system catalog.

- This catalog is shared across the entire cluster, not tied to a single database. That’s why tablespaces can be reused by multiple databases.

- PGSQL uses **`pg_tablespace`** as a mapping book — it connects the logical name of a tablespace to the actual physical directory on disk where the data lives.

- **In simple words:** Tablespaces let PGSQL remember which data goes to which disk location across the whole cluster.

- If you create or move a database or table to a tablespace, PostgreSQL stores its data on that physical disk location, not the default data directory.

- If you don’t specify a tablespace, PostgreSQL stores the data in the default tablespace: **`$PGDATA/base/`**


---

**Create a tablespace:**
```bash
CREATE TABLESPACE fast_space
LOCATION '/mnt/fast_disk/pgdata';

# Creates a logical tablespace pointing to a physical directory.
```

**List all tablespaces (from pg_tablespace):**
```bash
SELECT spcname, pg_tablespace_location(oid)
FROM pg_tablespace;
```

**Create a database using a tablespace:**
```bash
CREATE DATABASE salesdb TABLESPACE fast_space;
```

**Create a table in a specific tablespace:**
```bash
CREATE TABLE orders (
  id INT,
  amount NUMERIC
) TABLESPACE fast_space;
```

**Move an existing table:**
```bash
ALTER TABLE orders SET TABLESPACE fast_space;
```

**Check tablespace usage:**
```bash
SELECT relname, spcname
FROM pg_class c
JOIN pg_tablespace t ON c.reltablespace = t.oid;
```

**Where PGSQL stores tablespaces links:**
```bash
ls $PGDATA/pg_tblspc/
```
This dir contains symlinks pointing to actual tablespace locations.

</details>
<br>

---

<br>
<br>

## Step 13: How psql Commands Work

Commands like:

```bash
\dt # pg_class
\d users # pg_authid
\du # pg_namespace
```

- do not scan disk files.
- They query system catalogs like pg_class, pg_attribute, pg_authid, and pg_namespace.
- This is why these commands are fast and accurate.

---

<br>
<br>

## Step 14: Why Catalogs Must Never Be Modified Manually

- System catalogs are tightly linked.
- If one catalog row changes incorrectly, PostgreSQL loses consistency.
- That is why **`INSERT`**, **`UPDATE`**, or **`DELETE`** should never be used directly on catalogs.
- Safe commands like **`CREATE`**, **`ALTER`**, **`DROP`**, **`GRANT`**, and **`REVOKE`** update catalogs in controlled ways.

---

<br>
<br>

## Final Understanding Through This Flow

- System catalogs are PostgreSQL’s internal database that describes every object, permission, and rule.
- Every SQL command first updates or reads catalogs before touching real data.
- Without system catalogs, PostgreSQL would not know what exists, who owns it, or how to execute queries.
- They are the brain and memory of the PostgreSQL cluster.
