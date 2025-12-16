# Lab: Role-Based Access Control (RBAC) in PostgreSQL

## Goal of This Lab

The goal of this lab is to implement proper role-based access control in PostgreSQL the way it is done in real environments. By the end of this lab, users will not get permissions directly. All access will be managed through roles.

This lab focuses on correctness and simplicity, not shortcuts.

---

<br>
<br>

## Lab Scenario (Real-World Style)

Assume I have an application database called `appdb`.

I want:

* One role for read-only access
* One role for read-write access
* One login user for the application

Permissions should be easy to change later without touching the user.

---

<br>
<br>

## Step 1: Connect as PostgreSQL Admin

I connect as the postgres user:

sudo -i -u postgres
psql

---

<br>
<br>

## Step 2: Create the Database

I create a database for the application:

CREATE DATABASE appdb;

---

<br>
<br>

## Step 3: Create Group Roles (No Login)

These roles will hold permissions only.

CREATE ROLE app_readonly;
CREATE ROLE app_readwrite;

---

<br>
<br>

## Step 4: Create Login Role

This role will be used by the application to connect:

CREATE ROLE app_user WITH LOGIN PASSWORD 'strongpassword';

---

<br>
<br>

## Step 5: Grant Role Membership

I assign permissions through role membership:

GRANT app_readwrite TO app_user;

Now, app_user will inherit permissions from app_readwrite.

---

<br>
<br>

## Step 6: Grant Database Access

I allow the roles to connect to the database:

GRANT CONNECT ON DATABASE appdb TO app_readonly;
GRANT CONNECT ON DATABASE appdb TO app_readwrite;

---

<br>
<br>

## Step 7: Grant Schema Permissions

I switch to the application database:

\c appdb

Then I grant schema access:

GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT USAGE ON SCHEMA public TO app_readwrite;

---

<br>
<br>

## Step 8: Grant Table Permissions

I grant table permissions:

GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;

---

<br>
<br>

## Step 9: Set Default Privileges

To make sure future tables follow the same rules:

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;

---

<br>
<br>

## Step 10: Verify Access

I check role assignments:

\du

I check permissions:

\dp

Optionally, I can test by logging in as app_user.

---

<br>
<br>

## What I Learned From This Lab

In this lab, I:

* Created login and non-login roles
* Used inheritance instead of direct grants
* Applied permissions at database, schema, and table level
* Configured default privileges for future objects

This is a clean and scalable RBAC model.
