# RBAC — Linux Sudoers Access Control Using AD Groups

**Author:** Prashant Gohel
**Date:** 2025-12-11

---

- [RBAC — Linux Sudoers Access Control Using AD Groups](#rbac--linux-sudoers-access-control-using-ad-groups)
  - [Overview](#overview)
  - [Objective](#objective)
  - [Why I Used a Custom Sudoers File](#why-i-used-a-custom-sudoers-file)
  - [AD Groups Used for RBAC](#ad-groups-used-for-rbac)
  - [Final Sudoers File — `/etc/sudoers.d/linux-rbac`](#final-sudoers-file--etcsudoersdlinux-rbac)
  - [Why This RBAC Model Works](#why-this-rbac-model-works)
    - [✔ Admins have unrestricted control](#-admins-have-unrestricted-control)
    - [✔ Read-Write users can run only safe operational commands](#-read-write-users-can-run-only-safe-operational-commands)
    - [✔ Read-Only users cannot escalate privileges](#-read-only-users-cannot-escalate-privileges)
  - [Testing I Performed](#testing-i-performed)
    - [1. Test Admin](#1-test-admin)
    - [2. Test RW User](#2-test-rw-user)
    - [3. Test RO User](#3-test-ro-user)
  - [Operational Notes](#operational-notes)
  - [Rollback Procedure (Safe Procedure)](#rollback-procedure-safe-procedure)
  - [Final Thoughts](#final-thoughts)


<br>
<br>

## Overview

This document explains the **Role-Based Access Control (RBAC)** implementation I configured on Rocky Linux using **Active Directory groups** + **custom sudoers rules**. The goal was to enforce consistent and secure administrative behavior across Linux servers while avoiding local user management.

This is a standalone file focusing only on **Part 2 of the project: Sudo RBAC**.

---

<br>
<br>

## Objective

Implement command-level restrictions based entirely on AD groups:

* **Admin role** → Full sudo
* **Read-Write role** → Restricted set of allowed commands; critical commands blocked
* **Read-Only role** → No sudo access

This ensures that Linux systems follow least privilege principles and that permissions are granted by **AD group membership**, not by modifying servers individually.

---

<br>
<br>

## Why I Used a Custom Sudoers File

I avoided editing `/etc/sudoers` because:

* It is risky — a syntax error can break sudo everywhere.
* It is harder to automate.
* Best practice is to put custom rules under `/etc/sudoers.d/`.

So I created a dedicated RBAC file:

```bash
/etc/sudoers.d/linux-rbac
```

This file contains all AD-based sudo permissions and restrictions.

---

<br>
<br>

## AD Groups Used for RBAC

For the test environment, I created three AD groups:

* **Linux-Admin**
* **Linux-ReadWrite**
* **Linux-ReadOnly**

In real production, these would be replaced with department groups such as:

* ITTeam
* DevOps
* Automation
* Security
* AI Team
* NextAML

but the structure remains the same.

---

<br>
<br>

## Final Sudoers File — `/etc/sudoers.d/linux-rbac`

Below is the exact configuration I implemented.

```bash
# =============================
# ADMIN ROLE — FULL PRIVILEGE
# =============================
%Linux-Admin ALL=(ALL:ALL) ALL


# =============================
# RW ROLE — ALLOWED COMMANDS
# =============================
Cmnd_Alias RW_CMNDS = /usr/bin/systemctl, /usr/bin/journalctl


# =============================
# DENIED COMMAND GROUPS
# =============================
# 1. Software Management
Cmnd_Alias SW_MGMT = /bin/rpm, /usr/bin/dnf, /usr/bin/up2date

# 2. Storage & Filesystem
Cmnd_Alias STR_FS = /sbin/fdisk, /sbin/sfdisk, /sbin/parted, /sbin/partprobe, \
                    /bin/mount, /bin/umount, /usr/sbin/mkfs*

# 3. System Control
Cmnd_Alias SYS_CTRL = /usr/bin/killall, /usr/sbin/halt, /usr/sbin/reboot, /usr/sbin/shutdown

# 4. Networking Configuration
Cmnd_Alias NET_CFG = /sbin/route, /sbin/ifconfig, /sbin/dhclient, /sbin/iptables

# 5. Delegation & Permissions
Cmnd_Alias DELEG = /usr/sbin/visudo, /usr/sbin/chroot, /usr/bin/chmod, /usr/bin/chown, /usr/bin/chgrp

# Combine all deny categories
Cmnd_Alias RW_DENY = SW_MGMT, STR_FS, SYS_CTRL, NET_CFG, DELEG


# =============================
# RW ROLE — FINAL PERMISSION
# =============================
%Linux-ReadWrite ALL=(ALL:ALL) RW_CMNDS, !RW_DENY


# =============================
# RO ROLE – NO PRIVILEGES
# =============================
%Linux-ReadOnly ALL=(ALL) 
```

---

<br>
<br>

## Why This RBAC Model Works

### ✔ Admins have unrestricted control

- They manage the full system — this is necessary for Linux admin teams.

### ✔ Read-Write users can run only safe operational commands

They can:

* restart services,
* view logs,
* troubleshoot issues

But they cannot:

* install/remove software,
* modify filesystem structures,
* manipulate permissions,
* reboot/shutdown systems,
* change sudo rules.

### ✔ Read-Only users cannot escalate privileges
- This group is allowed to log in, but has **zero** sudo rights.

---

<br>
<br>

## Testing I Performed
- I performed all tests using AD accounts from each group.

### 1. Test Admin

```bash
sudo su -
```
> ✔ Worked — full privilege.

### 2. Test RW User

```bash
sudo systemctl restart sshd     → Allowed
sudo reboot                      → Denied
sudo dnf install httpd           → Denied
```
> ✔ Worked exactly as expected.

### 3. Test RO User

```bash
sudo su -                        → Not allowed
sudo systemctl status sshd       → Not allowed
```
> ✔ Correct — no sudo rights.

---

<br>
<br>

## Operational Notes

* All role assignments happen in **Active Directory**, not on Linux.
* No local sudoers edits are needed when moving a user between roles.
* The sudoers file is static and reusable across all servers.
* This design scales across large infrastructures (100+ servers).

---

<br>
<br>

## Rollback Procedure (Safe Procedure)

If anything breaks:

```bash
sudo rm /etc/sudoers.d/linux-rbac
```
And `sudo` returns to default behavior.

Always test with:
```bash
sudo visudo -cf /etc/sudoers.d/linux-rbac # -c for check and -f to specify file
```

before applying.

---

<br>
<br>

## Final Thoughts

This RBAC model is exactly what enterprises expect: clean, role-based, AD-integrated, and safe. It prevents accidental privilege escalation while giving operational teams the tools they need. The sudoers file can be placed under version control or pushed via Ansible for consistent behavior across all Linux servers.