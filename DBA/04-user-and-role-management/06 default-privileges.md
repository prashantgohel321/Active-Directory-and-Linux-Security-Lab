# Default Privileges

## Why Default Privileges Exist

By default, when new tables or objects are created in PostgreSQL, only the owner can access them. This quickly becomes annoying in real projects where applications and teams expect access automatically.

Default privileges solve this problem. They define what permissions new objects should have *at creation time*.

---

<br>
<br>

## What Default Privileges Actually Do

Default privileges do not change existing tables. They only affect objects created in the future.

This is a very common misunderstanding. If I want to fix existing permissions, I still need normal GRANT commands.

---

<br>
<br>

## Common Real-World Use Case

In most setups, an application role creates tables, but another role needs read or write access.

Without default privileges, I would need to manually grant permissions every time a new table is created.

---

<br>
<br>

## Setting Default Privileges

To automatically grant read access on future tables:
```bash
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;
```
To automatically grant full access:
```bash
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;
```
---

<br>
<br>

## Important Detail (Very Common Mistake)

Default privileges are role-specific.

This means they apply only to objects created by a specific role. If a different role creates tables, the defaults will not apply.

---

<br>
<br>

## Verifying Behavior

The easiest way to verify default privileges is to create a new table and check permissions using:

\dp

---

<br>
<br>

## Simple Takeaway

Default privileges save time and prevent permission mistakes.

They affect future objects only and must be defined carefully for the correct role.
