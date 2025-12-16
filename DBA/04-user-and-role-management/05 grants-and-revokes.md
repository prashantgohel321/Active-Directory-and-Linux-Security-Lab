# Grants and Revokes

## Why Grants and Revokes Matter

Authentication only decides who can log in. Grants and revokes decide what a user can actually do after logging in. Most security problems in PostgreSQL come from overly broad grants, not weak passwords.

Understanding this clearly prevents accidental data exposure.

---

<br>
<br>

## What GRANT Does

GRANT is used to give permissions on database objects like databases, schemas, tables, and sequences.

Permissions are always explicit. If a role is not granted access, it has no access.

---

<br>
<br>

## Common Permissions I Actually Use

- In daily work, I mostly deal with a small set of privileges.
- CONNECT allows a role to connect to a database.
- USAGE allows access to a schema.
- SELECT allows reading data from tables.
- INSERT, UPDATE, DELETE allow modifying data.

---

<br>
<br>

## Granting Permissions (Simple Examples)

Allow a role to connect to a database:
```bash
GRANT CONNECT ON DATABASE appdb TO app_user;
```
Allow read access on all tables in a schema:
```bash
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
```
Allow full access on tables:
```bash
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;
```
---

<br>
<br>

## What REVOKE Does

REVOKE removes permissions that were previously granted.

If access should be removed, revoke is always safer than deleting users.

Example:
```bash
REVOKE INSERT ON ALL TABLES IN SCHEMA public FROM app_readonly;
```
---

<br>
<br>

## Granting to Roles, Not Users

Best practice is to grant permissions to group roles, not directly to login roles.

Login roles inherit permissions through role membership. This keeps access control clean and manageable.

---

<br>
<br>

## Checking Permissions

To inspect role privileges, I usually rely on:

\dp

or system catalog views when needed.

---

<br>
<br>

## Simple Takeaway

Authentication decides who gets in.

Grants decide what they can do.

Grant permissions to roles, not individual users, and revoke access carefully.
