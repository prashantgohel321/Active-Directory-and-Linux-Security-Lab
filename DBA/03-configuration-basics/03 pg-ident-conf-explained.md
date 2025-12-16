# pg_ident.conf Explained

## Why pg_ident.conf Exists

- pg_ident.conf is used for mapping operating system users to PostgreSQL users. This file comes into play only in specific authentication setups, mainly when using peer or ident authentication.

- Most beginners never touch this file, but in enterprise and Linux-heavy environments, it becomes important.

---

- [pg\_ident.conf Explained](#pg_identconf-explained)
  - [Why pg\_ident.conf Exists](#why-pg_identconf-exists)
  - [What pg\_ident.conf Actually Does](#what-pg_identconf-actually-does)
  - [When pg\_ident.conf Is Used](#when-pg_identconf-is-used)
  - [Basic pg\_ident.conf Format](#basic-pg_identconf-format)
  - [Practical Example](#practical-example)
  - [Reloading Changes](#reloading-changes)
  - [Common Mistakes](#common-mistakes)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## What pg_ident.conf Actually Does

- pg_ident.conf does not control who can connect. That job belongs to pg_hba.conf.

- This file only answers one question: if PostgreSQL trusts the operating system user, which database user should that OS user become?

- In simple terms, it translates OS usernames into PostgreSQL usernames.

---

<br>
<br>

## When pg_ident.conf Is Used

- pg_ident.conf is used only when pg_hba.conf specifies peer or ident authentication.
- If pg_hba.conf uses md5 or scram-sha-256, this file is completely ignored.
- This is why many systems never need pg_ident.conf at all.

---

<br>
<br>

## Basic pg_ident.conf Format

- Each line defines a mapping rule. A simple example looks like this:
```bash
my_map   linuxuser   dbuser
```
This means when linuxuser logs in via peer authentication, PostgreSQL treats them as dbuser.

---

<br>
<br>

## Practical Example

- If I want the Linux user admin to connect as the PostgreSQL user postgres using peer authentication, I would add a mapping here and reference it from pg_hba.conf.

- Without this mapping, PostgreSQL will reject the connection even if pg_hba.conf allows peer access.

---

<br>
<br>

## Reloading Changes

- After editing pg_ident.conf, PostgreSQL does not require a restart.

I apply changes using:
```bash
sudo systemctl reload postgresql-15
```
---

<br>
<br>

## Common Mistakes

Most connection problems related to pg_ident.conf happen because:

* The mapping name is not referenced in pg_hba.conf
* The authentication method is not peer or ident
* The OS username does not match exactly

---

<br>
<br>

## Simple Takeaway

- pg_ident.conf is a mapping file, not an access control file.

- If peer authentication is not used, this file does nothing. When it is used, correct mapping is mandatory.
