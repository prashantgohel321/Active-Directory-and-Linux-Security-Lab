# Roles and Users Basics in PostgreSQL

## Why Roles Matter

PostgreSQL does not really have separate concepts called users and groups. Everything is a role. A role can log in, own objects, or just hold permissions.

If I understand roles properly, access control becomes simple and predictable.

---

- [Roles and Users Basics in PostgreSQL](#roles-and-users-basics-in-postgresql)
  - [Why Roles Matter](#why-roles-matter)
  - [What a Role Is](#what-a-role-is)
  - [Login vs Non-Login Roles](#login-vs-non-login-roles)
  - [Creating a Login Role](#creating-a-login-role)
  - [Creating a Group Role](#creating-a-group-role)
  - [Granting Role Membership](#granting-role-membership)
  - [Listing Roles](#listing-roles)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## What a Role Is

A role is an identity inside PostgreSQL. It can represent a human user, an application, or a group.

Some roles can log in. Some roles cannot log in and are used only to group permissions.

This flexibility is intentional.

---

<br>
<br>

## Login vs Non-Login Roles

A login role is used by humans or applications to connect to PostgreSQL.

A non-login role is used only to hold privileges. Other roles inherit permissions from it.

This separation keeps security clean and avoids duplication.

---

<br>
<br>

## Creating a Login Role

Inside psql, I create a basic login role like this:
```bash
CREATE ROLE app_user WITH LOGIN PASSWORD 'strongpassword';
```
This role can now connect to PostgreSQL but has no permissions yet.

---

<br>
<br>

## Creating a Group Role

A group role does not need login access:
```bash
CREATE ROLE app_readonly;
```
This role will be used only to store permissions.

---

<br>
<br>

## Granting Role Membership

I assign a user to a group role like this:
```bash
GRANT app_readonly TO app_user;
```
Now app_user inherits permissions from app_readonly.

---

<br>
<br>

## Listing Roles

To see all roles:
```bash
\du
```
This command is used constantly when auditing access.

---

<br>
<br>

## Simple Takeaway

In PostgreSQL, everything is a role.

Login roles connect. Non-login roles hold permissions. Combining them keeps access control simple and secure.
