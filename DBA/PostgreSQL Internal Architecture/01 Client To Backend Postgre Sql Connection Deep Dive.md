# PostgreSQL Internal Architecture – From Client to Backend Process (Extreme Deep Dive)

## Read This Slowly

This file explains only one thing: how a single client connection is born and becomes a living backend process inside PostgreSQL. Nothing else. No WAL internals, no disk layout, no tuning. If you try to rush, you will lose the mental model. Read it like someone is speaking to you.

<br>
<br>

## The World Before PostgreSQL Is Even Involved

- Everything starts outside PostgreSQL. An application decides it needs data and tries to connect to the database. It uses a PostgreSQL client library, which speaks the PostgreSQL network protocol, not human language. The connection begins as a normal TCP connection to the server’s IP and port 5432, handled first by the operating system. Only after this network connection is accepted does PostgreSQL itself come into the picture.

<br>
<br>

## The Postmaster: Why a Single Gatekeeper Must Exist

- Inside PostgreSQL, a single process called the postmaster <mark><b>listens for all new connections</b></mark>. It acts as the <mark><b>main controller of the entire PostgreSQL process tree</b></mark>. Because PostgreSQL uses <mark><b>separate operating system processes for each client</b></mark>, process creation and coordination must be tightly controlled. The postmaster exists to manage this safely. It does not run queries itself; it only decides whether a connection is allowed and creates backend processes when needed. Every new connection reaches the postmaster first.

<br>
<br>

## The First Question PostgreSQL Asks: Should I Even Talk to You?

- Before doing anything else, PostgreSQL first <mark><b>decides whether it should even accept the connection</b></mark>. This check is only about trust, not about SQL or data. PostgreSQL consults the <mark><b>pg_hba.conf</b></mark> file, which acts as <mark><b>its internal firewall</b></mark>, to verify the client’s IP, requested database, user name, and authentication method. If no rule matches, the connection is rejected immediately, without creating a backend process or using resources, to keep the system secure.

<br>
<br>

## Authentication: Proving Identity, Not Permissions

- If pg_hba.conf allows the connection, PostgreSQL then <mark><b>verifies the client’s identity</b></mark>. This step is only about <mark><b>proving who the user is</b></mark>, not what permissions they have. PostgreSQL relies on existing (external) authentication systems like passwords, PAM, LDAP, Kerberos, or certificates instead of building its own. Here PostgreSQL asks one simple question: <mark><b>is the client really who it claims to be?</b></mark> If authentication fails, the connection is immediately closed and no backend process is created, because trust is the foundation of everything that follows.

<br>
<br>

## Role Validation: Does This User Exist Inside PostgreSQL?

- Even after authentication succeeds, PostgreSQL still <mark><b>checks its own internal records</b></mark>. Users are stored as roles in PostgreSQL’s system catalogs, which describe the database itself. PostgreSQL verifies that the role exists, is allowed to log in, and is permitted to connect to the requested database. Only after these checks pass does PostgreSQL accept the client as a valid user.

<br>
<details>
<summary><b>System Catalogs</b></summary>
<br>

System catalogs are PostgreSQL’s internal tables where it <mark><b>stores metadata about itself</b></mark>. They hold information about users (roles), databases, tables, columns, indexes, permissions, and many other internal details. PostgreSQL constantly reads these catalogs to understand what exists in the database and how it should behave.

</details>
<br>

<br>
<br>

## Where PgBouncer Fits Into This Story

- Sometimes a client does not connect directly to PostgreSQL but goes through **PgBouncer**, which sits in between as a connection pooler. PgBouncer exists because PostgreSQL creates one operating system process per connection, and too many connections can waste memory and CPU. Instead of letting every client open its own PostgreSQL connection, PgBouncer <mark><b>keeps a limited number of real connections</b></mark> and <mark><b>reuses them</b></mark>. When a client connects, PgBouncer decides whether to reuse an existing connection, make the client wait, or reject it. From PostgreSQL’s point of view, PgBouncer is just another normal client, and PostgreSQL is unaware that pooling is happening.

<br>
<br>

## The Birth of a Backend Process

- After authentication and role validation succeed, the <mark><b>postmaster creates a new backend process for the client</b></mark>. This <mark><b>backend process is dedicated to only one connection</b></mark> and exists for as long as the client stays connected. PostgreSQL uses one process per connection to keep strong isolation, so a crash in one backend does not affect others. The <mark><b>backend has access to shared memory</b></mark> but <mark><b>also its own private memory</b></mark>, and from this point onward, the client communicates directly with this backend, not with the postmaster.

<br>
<br>

## What a Backend Process Actually Is

- A backend process is <mark><b>a complete executor dedicated to one client</b></mark>, not just a simple worker. It <u><b>manages the session</b></u> and <u><b>transaction state</b></u>, <u><b>handles memory</b></u> and <u><b>locks</b></u>, <u><b>understands SQL</b></u>, <u><b>builds execution plans</b></u>, <u><b>runs queries</b></u>, and <u><b>sends results back to the client</b></u>. While it does all this on behalf of the client, it constantly coordinates with shared memory and background processes to work safely within PostgreSQL.

<br>
<details>
<summary><b>Backend Process and Background Process</b></summary>
<br>

<mark><b>Backend process</b></mark> is created for a client.
It talks directly to the client, runs their SQL queries, reads and changes data in memory, and sends results back. One client = one backend process.

<mark><b>Background processes</b></mark> are created for PostgreSQL itself, not for users.
They run continuously in the background to keep the system healthy, like writing data to disk, flushing WAL, running checkpoints, cleaning up memory, and helping with recovery. Clients never talk to them directly.

</details>
<br>

<br>
<br>

## What You Should Understand After This File

At this point, you should have a clear mental image of how a client connection becomes a backend process. You should understand why the postmaster exists, why authentication happens before backend creation, why PgBouncer exists, and why PostgreSQL chooses process-based isolation.

Nothing in PostgreSQL happens accidentally. Every step exists because something breaks without it.

In the next file, we will take this same backend process and follow a single SQL query through it, step by step, without breaking the mental flow.
