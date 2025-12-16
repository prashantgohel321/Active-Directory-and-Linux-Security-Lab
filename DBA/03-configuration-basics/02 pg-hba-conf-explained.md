# pg_hba.conf Explained

## Why pg_hba.conf Is Critical

- pg_hba.conf controls who can connect to PostgreSQL and how they are allowed to authenticate. If a user cannot connect, this file is usually the reason.

- PostgreSQL does not guess. If access is not explicitly allowed here, the connection is rejected.

---

- [pg\_hba.conf Explained](#pg_hbaconf-explained)
  - [Why pg\_hba.conf Is Critical](#why-pg_hbaconf-is-critical)
  - [What pg\_hba.conf Actually Does](#what-pg_hbaconf-actually-does)
  - [Structure of a pg\_hba.conf Rule](#structure-of-a-pg_hbaconf-rule)
  - [Common Connection Types](#common-connection-types)
  - [Authentication Methods I Will Actually Use](#authentication-methods-i-will-actually-use)
  - [Reloading pg\_hba.conf](#reloading-pg_hbaconf)
  - [How I Debug Login Issues](#how-i-debug-login-issues)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## What pg_hba.conf Actually Does

- pg_hba.conf stands for Host-Based Authentication.

- Every connection request is checked against the rules in this file. PostgreSQL reads the file from top to bottom and applies the first rule that matches.

- Order matters. A wrong rule at the top can block everything below it.

---

<br>
<br>

## Structure of a pg_hba.conf Rule

- Each line defines who can connect, from where, to which database, and using which authentication method.

A typical rule looks like this:
```bash
host    all    all    192.168.1.0/24    md5
```
This means any user can connect to any database from that network using password authentication.

---

<br>
<br>

## Common Connection Types

- `local` rules apply to local connections using Unix sockets.
- `host` rules apply to TCP/IP connections.
- Most login problems come from misunderstanding this difference.

---

<br>
<br>

## Authentication Methods I Will Actually Use

- `peer` means PostgreSQL trusts the OS user. This is common for local admin access.
- `md5` means password authentication.
- `scram-sha-25`6 is a more secure password method and preferred in newer setups.
- 
---

<br>
<br>

## Reloading pg_hba.conf

After editing pg_hba.conf, PostgreSQL does not need a restart.

I reload the configuration:
```bash
sudo systemctl reload postgresql-15
```
If I forget this step, my changes will not apply.

---

<br>
<br>

## How I Debug Login Issues

When a connection fails, PostgreSQL logs usually explain why.

I check logs using:
```bash
journalctl -u postgresql-15
```
The error message usually points directly to pg_hba.conf.

---

<br>
<br>

## Simple Takeaway

pg_hba.conf is PostgreSQL’s security gate. Order matters, rules must match exactly, and reload is required.

Most access issues are solved by reading this file carefully, not by reinstalling PostgreSQL.
