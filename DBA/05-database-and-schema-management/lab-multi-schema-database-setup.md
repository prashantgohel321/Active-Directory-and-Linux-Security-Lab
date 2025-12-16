# Lab: Multi-Schema Database Setup

## Goal of This Lab

The goal of this lab is to set up a single PostgreSQL database with multiple schemas and proper access control. This is a very common real-world pattern where different parts of an application or different teams use separate schemas.

The focus is on structure and permissions, not on application logic.

---

## Lab Scenario

I have one database called `appdb`.

Inside this database:

* One schema for application data
* One schema for reporting or read-only access
* Roles should access only what they need

---

## Step 1: Connect as Admin

I connect as the postgres user:

sudo -i -u postgres
psql

---

## Step 2: Create the Database

If the database does not already exist:

CREATE DATABASE appdb;

Then I connect to it:

\c appdb

---

## Step 3: Create Schemas

I create two schemas:

CREATE SCHEMA app_data;
CREATE SCHEMA reporting;

---

## Step 4: Create Roles

I create group roles for access control:

CREATE ROLE app_rw;
CREATE ROLE app_ro;

Then I create a login role:

CREATE ROLE app_user WITH LOGIN PASSWORD 'strongpassword';

---

## Step 5: Assign Role Membership

I grant role membership:

GRANT app_rw TO app_user;

---

## Step 6: Grant Schema Access

I allow roles to use schemas:

GRANT USAGE ON SCHEMA app_data TO app_rw;
GRANT USAGE ON SCHEMA reporting TO app_ro;

---

## Step 7: Grant Table Permissions

I grant permissions on existing tables:

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app_data TO app_rw;
GRANT SELECT ON ALL TABLES IN SCHEMA reporting TO app_ro;

---

## Step 8: Set Default Privileges

I make sure future tables follow the same rules:

ALTER DEFAULT PRIVILEGES IN SCHEMA app_data
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA reporting
GRANT SELECT ON TABLES TO app_ro;

---

## Step 9: Verify Setup

I verify roles:

\du

I verify permissions:

\dp

---

## What I Learned From This Lab

In this lab, I:

* Used schemas to separate data
* Applied role-based access per schema
* Avoided direct grants to users
* Ensured future objects follow rules

This is a clean and scalable database structure.

---

## End of Lab
