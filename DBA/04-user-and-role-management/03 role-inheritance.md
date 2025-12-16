# Role Inheritance

## Why Role Inheritance Exists

Role inheritance allows one role to automatically use the permissions of another role. This is how PostgreSQL avoids permission duplication and keeps access management simple.

Without inheritance, every user would need direct permissions on every object, which does not scale.

---

<br>
<br>

## How Inheritance Works

When a role is a member of another role, it can inherit that role’s permissions.

By default, roles inherit permissions unless inheritance is explicitly disabled.

This means a user does not need permissions directly if they are inherited through a group role.

---

<br>
<br>

## Simple Example

I create a group role:
```bash
CREATE ROLE app_readonly;
```
Then I create a login role:
```bash
CREATE ROLE app_user WITH LOGIN PASSWORD 'strongpassword';
```
Now I grant the group role to the user:
```bash
GRANT app_readonly TO app_user;
```
app_user now automatically gets all permissions assigned to app_readonly.

---

<br>
<br>

## Checking Role Membership

To see which roles a user belongs to:
```bash
\du
```
This helps me audit access quickly.

---

<br>
<br>

## Temporarily Disabling Inheritance

If I want a role to not inherit permissions automatically, I can disable inheritance when creating it.

Example:
```bash
CREATE ROLE temp_user WITH LOGIN NOINHERIT;
```
This user must explicitly set a role to use its permissions.

---

<br>
<br>

## Simple Takeaway

Role inheritance is how PostgreSQL keeps permission management clean.

Assign permissions to group roles and let users inherit them instead of granting permissions directly.
