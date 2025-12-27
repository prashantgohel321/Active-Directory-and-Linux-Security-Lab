# Roles, Permissions, and Backup Requirements in PostgreSQL

<br>
<br>

- [Roles, Permissions, and Backup Requirements in PostgreSQL](#roles-permissions-and-backup-requirements-in-postgresql)
  - [In simple words](#in-simple-words)
  - [Why roles matter in backup and restore](#why-roles-matter-in-backup-and-restore)
  - [Common PostgreSQL backup tools and permissions](#common-postgresql-backup-tools-and-permissions)
  - [Role requirements for logical backups (pg\_dump)](#role-requirements-for-logical-backups-pg_dump)
    - [Practical rule](#practical-rule)
  - [Why pg\_dump fails even though the database exists](#why-pg_dump-fails-even-though-the-database-exists)
  - [Role requirements for pg\_dumpall](#role-requirements-for-pg_dumpall)
  - [Role requirements for physical backups](#role-requirements-for-physical-backups)
  - [Restore-side role requirements](#restore-side-role-requirements)
    - [Best practice](#best-practice)
  - [Restoring as a different role](#restoring-as-a-different-role)
  - [Backups do not include everything](#backups-do-not-include-everything)
  - [Backup security is critical](#backup-security-is-critical)
  - [When I plan backup roles](#when-i-plan-backup-roles)
  - [Final mental model](#final-mental-model)
  - [One-line explanation (interview ready)](#one-line-explanation-interview-ready)

<br>
<br>

## In simple words

Backups do not fail because of tools.
They fail because of **permissions**.

PostgreSQL backup tools only read what the connected role is allowed to see. If the role lacks access to even one required object, the backup can fail or become incomplete.

---

## Why roles matter in backup and restore

PostgreSQL is strict about access control.
Every database object has an owner and permissions.

When a backup tool connects:

* it acts like a normal client
* it obeys all role and permission rules

There is no special "backup mode" that bypasses security.

---

## Common PostgreSQL backup tools and permissions

* `pg_dump` → backs up **one database**
* `pg_dumpall` → backs up **entire cluster metadata + all databases**
* `pg_basebackup` → takes **physical backups** of the cluster

Each tool requires different permission levels.

---

## Role requirements for logical backups (pg_dump)

To successfully dump a database:

* the role must be able to connect to the database
* the role must have read access to **all schemas, tables, views, and sequences** being dumped

If the role lacks access to even one table, pg_dump stops with an error.

### Practical rule

In production, pg_dump is usually run as:

* database owner, or
* a role with full read access, or
* a superuser

---

## Why pg_dump fails even though the database exists

Common reasons:

* role cannot access one schema
* role cannot read a table or view
* role cannot access a function

pg_dump does not silently skip objects.
If it cannot read something, it fails.

---

## Role requirements for pg_dumpall

`pg_dumpall` captures:

* roles
* role memberships
* tablespaces
* all databases

This requires:

* superuser privileges

A non-superuser cannot dump global objects.

---

## Role requirements for physical backups

Physical backups access raw database files.

Tools like `pg_basebackup` require:

* superuser, or
* replication role with backup privilege (newer PostgreSQL versions)

Without sufficient privileges, the server refuses access.

---

## Restore-side role requirements

Restore often fails because roles do not exist on the target server.

Logical backups may contain:

* object ownership
* GRANT statements

If referenced roles are missing:

* restore completes with errors
* ownership and permissions break

### Best practice

Always restore roles **before** restoring databases.

---

## Restoring as a different role

Sometimes, original roles are not needed on the target system.

Options:

* use `--no-owner` during restore
* use `--no-privileges` to skip GRANT statements

This avoids permission conflicts in test or staging systems.

---

## Backups do not include everything

Logical backups:

* do not include PostgreSQL users unless pg_dumpall is used
* do not include server configuration files

Physical backups:

* include cluster files
* but may not include external scripts or OS-level configs

DBAs must know what is and is not covered.

---

## Backup security is critical

Backup files contain:

* full data
* sensitive information
* passwords (indirectly)

Best practices:

* restrict file permissions
* encrypt backups when possible
* limit who can run backup tools

A leaked backup is a full data breach.

---

## When I plan backup roles

I ensure that:

* backup roles have minimum required permissions
* backups run non-interactively
* role permissions are documented

Permissions should enable backups, not weaken security.

---

## Final mental model

* Backup tools obey role permissions
* Superuser makes backups easy but risky
* Missing roles break restores
* Security applies even during backup

---

## One-line explanation (interview ready)

PostgreSQL backup tools work under role permissions, so proper access rights are required to back up and restore database objects safely.
