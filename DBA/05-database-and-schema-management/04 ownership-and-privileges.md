# Ownership and Privileges in PostgreSQL

## Why Ownership Matters

In PostgreSQL, every object has an owner. The owner has special power over that object, including changing its structure and granting permissions to others. If ownership is wrong, access control becomes messy and risky.

In real environments, postgres should not own application objects.

---

## What Ownership Means

The owner of a database, schema, or table can:

* Modify or drop the object
* Grant or revoke privileges
* Change ownership to another role

Other roles can only do what they are explicitly allowed to do.

---

## Setting Correct Ownership

When creating objects, I should use a dedicated owner role.

Example for database ownership:

ALTER DATABASE appdb OWNER TO app_owner;

Example for schema ownership:

ALTER SCHEMA app_schema OWNER TO app_owner;

This keeps control centralized and clean.

---

## Privileges vs Ownership

Ownership is stronger than privileges.

Even if a role has many privileges, it cannot drop or alter an object unless it is the owner.

This separation is intentional and improves safety.

---

## Avoid Using postgres as Owner

The postgres role is a superuser. Using it as owner everywhere increases risk.

Best practice is:

* postgres only for administration
* application owners for application objects

---

## Checking Ownership

To check who owns objects, I can use:

\dp

or query system catalogs when needed.

---

## Simple Takeaway

Ownership defines control.

Privileges define access.

Keep postgres out of application ownership to maintain clean and secure setups.
