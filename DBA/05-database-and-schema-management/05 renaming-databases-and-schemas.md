    # Renaming Databases and Schemas

## Why Renaming Needs Care

Renaming databases or schemas sounds simple, but in real systems it can break applications, scripts, and connections if done casually. This is not a daily operation. It should be done only when there is a clear reason.

Understanding the rules around renaming helps avoid downtime and surprises.

---

## Renaming a Database

A database can be renamed using ALTER DATABASE. However, no active connections are allowed at the time.

Before renaming, I must make sure all clients are disconnected.

Example:

ALTER DATABASE appdb RENAME TO appdb_new;

If there are active connections, PostgreSQL will reject the command.

This is why database renaming is usually done during maintenance windows.

---

## Checking Active Connections

Before renaming, I check whether anyone is connected:

SELECT datname, count(*)
FROM pg_stat_activity
GROUP BY datname;

If connections exist, I wait or stop the application.

---

## Renaming a Schema

Schemas are easier to rename because they do not require disconnecting users.

Example:

ALTER SCHEMA app_schema RENAME TO app_schema_new;

This change is immediate.

---

## Impact of Schema Renaming

Renaming a schema changes object paths.

Any code that uses fully qualified names must be updated. search_path settings may also need review.

This is why schema renaming should be tested carefully.

---

## What Not to Do

I should never rename databases or schemas just for cosmetic reasons.

Renaming should always have a clear technical or organizational purpose.

---

## Simple Takeaway

Database renaming requires zero active connections and careful timing.

Schema renaming is easier but can still break applications.

Always check impact before renaming anything.
