# Login vs Non-Login Roles

## Why This Separation Exists

PostgreSQL separates the idea of logging in from the idea of having permissions. This design avoids messy access control and makes large environments easier to manage.

If every user had direct permissions, security would become hard to track and audit.

---

- [Login vs Non-Login Roles](#login-vs-non-login-roles)
  - [Why This Separation Exists](#why-this-separation-exists)
  - [Login Roles](#login-roles)
  - [Non-Login Roles](#non-login-roles)
  - [Combining Both (Best Practice)](#combining-both-best-practice)
  - [Why This Matters in Real Life](#why-this-matters-in-real-life)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## Login Roles

A login role is allowed to connect to PostgreSQL. Humans and applications always use login roles.

A login role by itself should usually have very few permissions. Its main job is to authenticate.

Example:
```bash
CREATE ROLE app_user WITH LOGIN PASSWORD 'strongpassword';
```
---

<br>
<br>

## Non-Login Roles

A non-login role cannot connect to PostgreSQL. It exists only to hold permissions.

These roles act like groups.

Example:
```bash
CREATE ROLE app_readwrite;
```
---

<br>
<br>

## Combining Both (Best Practice)

The correct pattern is simple:

* Login roles authenticate
* Non-login roles own permissions

I grant group roles to login roles:
```bash
GRANT app_readwrite TO app_user;
```
This keeps permissions centralized and easy to change.

---

<br>
<br>

## Why This Matters in Real Life

If access needs to be removed, I remove role membership instead of editing many objects.

If permissions change, I update one group role and all users inherit the change.

This approach scales cleanly.

---

<br>
<br>

## Simple Takeaway

Login roles connect.

Non-login roles control permissions.

Keeping these separate makes PostgreSQL access control clean and manageable.
