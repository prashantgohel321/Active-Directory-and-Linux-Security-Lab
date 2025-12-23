# Overview

- We can think of system catalogs as special built-in tables that <mark><b>store all the metadata about our PostgreSQL cluster</b></mark> – like <mark><b>information about</b></mark> <u><b>databases</b></u>, <u><b>tables</b></u>, <u><b>users</b></u>, <u><b>functions</b></u>, <u><b>permissions</b></u>, etc.

- When we create a new database, most catalogs are copied from a template (like template1) and become specific to that database. But a few are shared across the entire cluster (all databases).

Here’s a short and simple meaning of some important ones from the list:
- **`pg_database`**: Lists all databases in the cluster (shared).
- **`pg_class`**: Stores info about tables, indexes, views, sequences (one per database).
- **`pg_attribute`**: Describes columns in tables (what data type, name, etc.).
- **`pg_index`**: Details about indexes (which table, which columns).
- **`pg_proc`**: All functions and procedures we created.
- **`pg_authid`**: All roles/users (shared across cluster).
- **`pg_tablespace`**: Lists tablespaces (shared).
- **`pg_constraint`**: Check, unique, primary key, foreign key constraints.
- **`pg_trigger`**: All triggers on tables.
- **`pg_namespace`**: Schemas (like public, etc.).
- **`pg_extension`**: Installed extensions (like uuid-ossp, postgis).

**Key Point:**
- We <mark><b>should never update these catalogs</b></mark> directly with INSERT/UPDATE/DELETE (very risky!). We use commands like CREATE TABLE, CREATE USER, GRANT, etc. – <mark><b>PostgreSQL updates them automatically</b></mark>.
- These catalogs power commands like **`\d`**, **`\dt`**, **`\du`** in psql.
Short meaning: System catalogs = PostgreSQL's own "database about the database" – they keep track of everything inside!