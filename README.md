# Linux Administration and DBA

Hi 👋 and welcome to this repository.

This repo is my personal learning space where I document **real Linux Administration and PostgreSQL DBA concepts** in a simple, practical, and explainable way. Everything here is written while actually learning, breaking things, fixing them, and understanding how systems behave in real environments.

If you are tired of textbook theory and want things explained like a human would explain to another human, you are in the right place.

---

<br>
<br>

- [Linux Administration and DBA](#linux-administration-and-dba)
  - [What this repository is for](#what-this-repository-is-for)
  - [What you will find inside](#what-you-will-find-inside)
    - [Linux Administration](#linux-administration)
    - [PostgreSQL DBA](#postgresql-dba)
    - [Labs and Tasks](#labs-and-tasks)
  - [Who this repository is useful for](#who-this-repository-is-useful-for)
  - [How to use this repository](#how-to-use-this-repository)
  - [About the author](#about-the-author)
  - [Final note](#final-note)



<br>
<br>

## What this repository is for

This repository exists for one simple reason: **to make Linux and Database Administration understandable and usable in real life**.

Instead of copying commands or memorizing definitions, the focus here is on:

* understanding *why* something exists
* knowing *when* to use it
* seeing *how* it behaves in real systems
* learning through small labs and practical flows

Everything is written in **simple English**, step by step, and in a natural flow so you can connect the dots easily.

---

<br>
<br>

## What you will find inside

This repository is divided into clear sections so you can move gradually, without feeling overwhelmed.

### Linux Administration

You will find Linux concepts explained from the ground up, including:

* virtual lab setup (VMware, Rocky Linux, Windows Server)
* Active Directory basics and domain concepts
* joining Linux systems to AD
* SSSD, PAM, Kerberos, authentication flows
* SSH access control and hardening
* sudo rules based on AD groups
* system security, auditing, firewall, SELinux
* enterprise-level best practices

These are not random notes. They follow a **real-world system admin mindset**, exactly how things are handled in companies.

---

<br>
<br>

### PostgreSQL DBA

The DBA section is focused on PostgreSQL and goes from basics to advanced internals.

You will learn:

* PostgreSQL architecture (process, memory, disk)
* how a client query actually travels inside PostgreSQL
* system catalogs and how PostgreSQL stores metadata
* installation, initialization, and directory structure
* configuration files and parameters
* users, roles, permissions, and RBAC
* schemas, databases, ownership, and access control

A **very big focus** is given to **Backup and Restore**, including:

* logical backups using pg_dump and pg_restore
* physical backups and filesystem-level backups
* WAL, checkpoints, and crash recovery
* PITR (Point-In-Time Recovery)
* real production failure scenarios
* common mistakes DBAs make and how to avoid them

This is written with a **production DBA mindset**, not exam notes.

---

<br>
<br>

### Labs and Tasks

Almost every important topic includes:

* small labs to try things yourself
* real command outputs
* step-by-step execution
* explanation of what is happening in the background

There is also a dedicated **Tasks section**, where complete real-life tasks are implemented:

* Linux access control using AD
* applying RBAC across multiple servers
* automation using Ansible
* reusable scripts with explanations

This helps you think like an engineer, not just a learner.

---

<br>
<br>

## Who this repository is useful for

This repo is especially useful if you are:

* a Linux beginner who wants clarity
* preparing for Linux Admin or DBA roles
* learning PostgreSQL seriously (not just SQL)
* a DevOps or Cloud aspirant who needs strong fundamentals
* someone working in support / operations wanting deeper understanding

If you already work in IT, you will recognize many **real production scenarios** here.

---

<br>
<br>

## How to use this repository

You don’t need to read everything at once.

My suggestion:

1. Start with Linux basics and lab setup
2. Move into authentication, AD, and access control
3. Then jump into PostgreSQL architecture
4. Slowly reach backup, restore, and disaster recovery

Treat this like a **reference + learning journal**, not a book you must finish.

---

<br>
<br>

## About the author

This repository is maintained by **Prashant Gohel**.

I created this while learning Linux Administration and PostgreSQL DBA concepts hands-on. These notes reflect real confusion, real debugging, and real understanding gained over time.

GitHub: [https://github.com/prashantgohel321](https://github.com/prashantgohel321)

---

<br>
<br>

## Final note

This repository will keep growing.

I will continue adding more labs, diagrams, and real-world explanations as I learn more. If this helps even one person understand systems better, it has already done its job.

Feel free to explore, learn, and adapt it to your own journey.

Happy learning 🚀
