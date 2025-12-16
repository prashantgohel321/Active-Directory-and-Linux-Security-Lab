# Database Templates in PostgreSQL

## Why Database Templates Exist

When PostgreSQL creates a new database, it does not start from nothing. It copies an existing database called a template. Understanding templates helps me control what a new database looks like from the beginning.

This matters in real environments where databases must be consistent.

---

<br>
<br>

## Default Templates

PostgreSQL provides two default templates.

template1 is the main template used to create new databases.

template0 is a clean, untouched template used for special cases.

By default, every CREATE DATABASE command copies template1.

---

<br>
<br>

## What template1 Is Used For

template1 is meant to be customized.

If I add extensions, schemas, or settings to template1, every new database created later will include those changes automatically.

This is useful when all databases should share the same baseline.

---

<br>
<br>

## What template0 Is Used For

template0 is read-only and should never be modified.

It exists so I can create a database without inheriting anything from template1.

This is useful when restoring databases or creating very clean environments.

---

<br>
<br>

## Creating a Database from a Specific Template

To create a database using template0:

CREATE DATABASE clean_db TEMPLATE template0;

This database will not inherit customizations from template1.

---

<br>
<br>

## When Templates Matter in Practice

Templates are useful when:

* Multiple databases need the same extensions
* Standard schemas are required
* Consistent encoding or locale is needed

Using templates avoids repeating the same setup steps.

---

<br>
<br>

## Simple Takeaway

PostgreSQL databases are created by copying templates.

template1 is customizable.

template0 is a clean fallback.

Understanding templates gives me control over database consistency.
