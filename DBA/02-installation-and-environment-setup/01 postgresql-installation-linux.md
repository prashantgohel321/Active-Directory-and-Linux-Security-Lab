# PostgreSQL Installation on Rocky Linux

## What I Am Doing in This Step

- In this step, I am installing PostgreSQL properly on Rocky Linux. I am not using random packages or defaults. I want a clean, predictable setup that behaves the same way on servers.

- The goal is simple: install PostgreSQL, initialize it, start it, and confirm it works.

---

- [PostgreSQL Installation on Rocky Linux](#postgresql-installation-on-rocky-linux)
  - [What I Am Doing in This Step](#what-i-am-doing-in-this-step)
  - [Why Not Use Default Rocky Packages](#why-not-use-default-rocky-packages)
  - [Step 1: Disable the Default PostgreSQL Module](#step-1-disable-the-default-postgresql-module)
  - [Step 2: Add the Official PostgreSQL Repository](#step-2-add-the-official-postgresql-repository)
  - [Step 3: Install PostgreSQL Packages](#step-3-install-postgresql-packages)
  - [Step 4: Initialize the Database Cluster](#step-4-initialize-the-database-cluster)
  - [Step 5: Start and Enable PostgreSQL](#step-5-start-and-enable-postgresql)
  - [Step 6: First Connection Test](#step-6-first-connection-test)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## Why Not Use Default Rocky Packages

- Rocky Linux ships PostgreSQL through AppStream modules, but these are often older versions and can cause confusion later.

- In real environments, PostgreSQL is installed from the official PostgreSQL repository so versions are clear and upgrades are controlled.

---

<br>
<br>

## Step 1: Disable the Default PostgreSQL Module

First, I disable the built-in PostgreSQL module to avoid conflicts.
```bash
sudo dnf -qy module disable postgresql
```
---

<br>
<br>

## Step 2: Add the Official PostgreSQL Repository

- Next, I add the PostgreSQL Global Development Group repository.

For Rocky Linux 9:
```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```
---

<br>
<br>

## Step 3: Install PostgreSQL Packages

- Now I install the PostgreSQL server and client packages. I am choosing version 15 here, but the version can change later.
```bash
sudo dnf install -y postgresql15 postgresql15-server
```
---

<br>
<br>

## Step 4: Initialize the Database Cluster

- After installation, PostgreSQL is not ready yet. I must initialize the data directory.
```bash
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
```
This step creates the data directory and internal system files.

---

<br>
<br>

## Step 5: Start and Enable PostgreSQL

Now I enable PostgreSQL to start on boot and start it immediately.
```bash
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15
```
To confirm it is running:
```bash
sudo systemctl status postgresql-15
```
---

<br>
<br>

## Step 6: First Connection Test

PostgreSQL creates a system user called postgres. I switch to that user and connect.
```bash
sudo -i -u postgres
psql
```
Inside psql, I confirm the server is responding:
```bash
SELECT version();
```
---

<br>
<br>

## Simple Takeaway

- PostgreSQL installation on Rocky Linux is straightforward if done correctly. Disable defaults, use the official repo, initialize the cluster, and verify.

- If installation is clean, everything else becomes easier.
