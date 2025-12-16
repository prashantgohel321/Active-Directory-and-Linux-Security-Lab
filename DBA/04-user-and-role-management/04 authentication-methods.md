# Authentication Methods in PostgreSQL

## Why Authentication Methods Matter

Authentication decides how PostgreSQL verifies who is trying to connect. If authentication is weak or misconfigured, the database becomes insecure. If it is too strict or misunderstood, users cannot log in.

Most connection issues come from misunderstanding authentication methods, not from PostgreSQL itself.

---

- [Authentication Methods in PostgreSQL](#authentication-methods-in-postgresql)
  - [Why Authentication Methods Matter](#why-authentication-methods-matter)
  - [peer Authentication](#peer-authentication)
  - [md5 Authentication](#md5-authentication)
  - [scram-sha-256 Authentication](#scram-sha-256-authentication)
  - [ident Authentication](#ident-authentication)
  - [Where Authentication Is Defined](#where-authentication-is-defined)
  - [Reloading Changes](#reloading-changes)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## peer Authentication

peer authentication trusts the operating system user. If the OS user name matches the PostgreSQL role, login is allowed without a password.

This method is commonly used for local admin access.

It works only for local connections, not for remote ones.

---

<br>
<br>

## md5 Authentication

md5 authentication requires a password. PostgreSQL stores and checks a hashed version of the password.

This method is widely used and simple, but it is not the most secure option available today.

---

<br>
<br>

## scram-sha-256 Authentication

scram-sha-256 is a more secure password-based authentication method.

It protects against common password attacks better than md5 and is recommended for new setups.

---

<br>
<br>

## ident Authentication

ident authentication maps remote operating system users to PostgreSQL users.

It is rarely used today and mainly appears in legacy or very controlled environments.

---

<br>
<br>

## Where Authentication Is Defined

Authentication methods are defined in pg_hba.conf.

PostgreSQL checks rules from top to bottom and applies the first matching rule.

If no rule matches, the connection is rejected.

---

<br>
<br>

## Reloading Changes

When authentication rules are changed, PostgreSQL does not need a restart.

I reload the configuration using:
```bash
sudo systemctl reload postgresql-15
```
---

<br>
<br>

## Simple Takeaway

peer is for trusted local access.

scram-sha-256 is preferred for password-based access.

Authentication is controlled by pg_hba.conf, and rule order matters.
