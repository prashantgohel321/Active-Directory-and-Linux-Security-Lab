# Lab: Secure and Configure PostgreSQL

## Goal of This Lab

The goal of this lab is to apply basic but important security and configuration settings to PostgreSQL. After this lab, PostgreSQL should be reachable only in the intended way, and configuration changes should be properly applied and verified.

This lab focuses on *safe defaults*, not performance tuning.

---

<br>
<br>

## Lab Prerequisites

PostgreSQL must already be installed, initialized, and running on Rocky Linux.

I should be able to connect using the postgres user and psql.

---

<br>
<br>

## Step 1: Review Current Configuration

Before changing anything, I first check the current important settings.

Inside psql, I run:
```bash
SHOW listen_addresses;
SHOW port;
SHOW max_connections;
```
This tells me how PostgreSQL is currently exposed and limited.

---

<br>
<br>

## Step 2: Restrict Network Exposure

By default, PostgreSQL should not be exposed to all networks.

I open the main configuration file:
```bash
sudo vi $(psql -U postgres -Atc "SHOW config_file;")
```
I ensure listen_addresses is set safely, for example:
```bash
listen_addresses = 'localhost'
```
This limits access to local connections only.

---

<br>
<br>

## Step 3: Secure pg_hba.conf

Next, I review pg_hba.conf to control who can connect.
```bash
sudo vi $(psql -U postgres -Atc "SHOW hba_file;")
```
I ensure:

* Local connections use peer authentication for admins
* Remote access is restricted or disabled

I avoid overly broad rules like allowing all networks.

---

<br>
<br>

## Step 4: Apply Configuration Changes

After editing configuration files, I reload PostgreSQL:
```bash
sudo systemctl reload postgresql-15
```
I do not restart unless required.

---

<br>
<br>

## Step 5: Verify Access Control

I test local access:
```bash
sudo -i -u postgres
psql
```
If this works, local admin access is correct.

If remote access is disabled, remote connection attempts should fail.

---

<br>
<br>

## Step 6: Verify Configuration Is Active

Inside psql, I confirm settings:
```bash
SHOW listen_addresses;
SHOW max_connections;
```
The values should match what I configured.

---

<br>
<br>

## Step 7: Check Logs for Errors

Finally, I check PostgreSQL logs to ensure there are no errors.
```bash
journalctl -u postgresql-15 --no-pager | tail
```
Logs should be clean after reload.

---

<br>
<br>

## What I Learned From This Lab

In this lab, I:

* Reviewed PostgreSQL configuration safely
* Restricted network exposure
* Controlled authentication rules
* Applied changes correctly using reload
* Verified behavior using psql and logs

This is the minimum security baseline for a fresh PostgreSQL setup.

---

## End of Lab
