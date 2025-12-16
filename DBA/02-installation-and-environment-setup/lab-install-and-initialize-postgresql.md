# Lab: Install and Initialize PostgreSQL on Rocky Linux

## Goal of This Lab

- The goal of this lab is to install PostgreSQL from scratch on Rocky Linux and bring it to a working state. By the end, PostgreSQL should be running, initialized, and accessible using psql.

- This lab is practical. I am not tuning anything. I am only installing, starting, and verifying.

---

- [Lab: Install and Initialize PostgreSQL on Rocky Linux](#lab-install-and-initialize-postgresql-on-rocky-linux)
  - [Goal of This Lab](#goal-of-this-lab)
  - [Lab Prerequisites](#lab-prerequisites)
  - [Step 1: Disable Default PostgreSQL Module](#step-1-disable-default-postgresql-module)
  - [Step 2: Add Official PostgreSQL Repository](#step-2-add-official-postgresql-repository)
  - [Step 3: Install PostgreSQL Packages](#step-3-install-postgresql-packages)
  - [Step 4: Initialize the Database Cluster](#step-4-initialize-the-database-cluster)
  - [Step 5: Start and Enable PostgreSQL Service](#step-5-start-and-enable-postgresql-service)
  - [Step 6: Connect Using psql](#step-6-connect-using-psql)
  - [Step 7: Basic Verification](#step-7-basic-verification)
  - [Step 8: Exit Cleanly](#step-8-exit-cleanly)
  - [What I Learned From This Lab](#what-i-learned-from-this-lab)


## Lab Prerequisites

I need a Rocky Linux system with sudo access and internet connectivity.

---

<br>
<br>

## Step 1: Disable Default PostgreSQL Module

Rocky Linux ships PostgreSQL through AppStream modules. To avoid conflicts, I disable it first.
```bash
sudo dnf -qy module disable postgresql
```
---

<br>
<br>

## Step 2: Add Official PostgreSQL Repository

I add the PostgreSQL Global Development Group repository so I get a clean and supported version.
```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```

---

<br>
<br>

## Step 3: Install PostgreSQL Packages

I install the PostgreSQL server and client packages. I am using version 15 here.
```bash
sudo dnf install -y postgresql15 postgresql15-server
```
---

<br>
<br>

## Step 4: Initialize the Database Cluster

After installation, PostgreSQL is not usable until the data directory is initialized.
```bash
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
```
This creates the data directory and internal system tables.

---

<br>
<br>

## Step 5: Start and Enable PostgreSQL Service

Now I start PostgreSQL and enable it to start on boot.
```bash
sudo systemctl enable postgresql-15
nsudo systemctl start postgresql-15
```
I verify the service status:
```bash
sudo systemctl status postgresql-15
```
---

<br>
<br>

## Step 6: Connect Using psql

I switch to the postgres system user and connect using psql.
```bash
sudo -i -u postgres
psql
```
Once connected, I confirm PostgreSQL is responding:
```bash
SELECT version();
```
---

<br>
<br>

## Step 7: Basic Verification

I run a few simple checks to confirm everything is working.

Check current user:
```bash
SELECT current_user;
```
Check data directory location:
```bash
SHOW data_directory;
```
---

<br>
<br>

## Step 8: Exit Cleanly

I exit psql and return to my normal user.
```bash
\q
exit
```
---

<br>
<br>

## What I Learned From This Lab

In this lab, I installed PostgreSQL cleanly, initialized the cluster, started the service, and verified connectivity.

If these steps work, PostgreSQL is correctly installed and ready for configuration.

