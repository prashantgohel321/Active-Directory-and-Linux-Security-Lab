# Linux ACL (Access Control List) – Complete Practical & Real-World Guide

This document explains **Linux ACL from zero to advanced**, using **real scenarios, reasoning, and step-by-step flow**.

<br>
<br>

- [Linux ACL (Access Control List) – Complete Practical \& Real-World Guide](#linux-acl-access-control-list--complete-practical--real-world-guide)
  - [First: What Problem ACL Actually Solves](#first-what-problem-acl-actually-solves)
  - [Why Normal Permissions Are Often Not Enough (Real Scenario)](#why-normal-permissions-are-often-not-enough-real-scenario)
  - [What ACL Adds on Top of Normal Permissions](#what-acl-adds-on-top-of-normal-permissions)
  - [Checking Whether a File Has ACL](#checking-whether-a-file-has-acl)
  - [Giving Permission to a Specific User (Core Use Case)](#giving-permission-to-a-specific-user-core-use-case)
  - [Giving Permission to a Specific Group](#giving-permission-to-a-specific-group)
  - [How ACL Is Evaluated (Important Logic)](#how-acl-is-evaluated-important-logic)
  - [The ACL Mask (Most Important and Most Confusing Part)](#the-acl-mask-most-important-and-most-confusing-part)
  - [Removing a Specific ACL Entry](#removing-a-specific-acl-entry)
  - [Removing All ACL Entries (Back to Normal Permissions)](#removing-all-acl-entries-back-to-normal-permissions)
  - [ACL on Directories (Recursive Permissions)](#acl-on-directories-recursive-permissions)
  - [Default ACL (For New Files and Directories)](#default-acl-for-new-files-and-directories)
  - [Copying ACL Between Files](#copying-acl-between-files)
  - [Checking Effective Permissions](#checking-effective-permissions)
  - [Common ACL Commands (Quick Reference)](#common-acl-commands-quick-reference)
  - [When ACL Should Be Used (DBA / Admin View)](#when-acl-should-be-used-dba--admin-view)
  - [One-Line Mental Model](#one-line-mental-model)
  - [Final Practical Advice](#final-practical-advice)


<br>
<br>

---

## First: What Problem ACL Actually Solves

- Linux permissions were designed very early. They are simple and fast, but also limited.

<br>

- Every file or directory understands only three permission sets:
  * owner
  * group
  * others

- That’s it. No more.

<br>

If your requirement fits inside these three buckets, normal permissions are enough.

---

<br>
<br>

## Why Normal Permissions Are Often Not Enough (Real Scenario)

- **Two users exist on the system:**
  * user A
  * user B

<br>

- **User **A** creates a file:**

```bash
rw-rw-r--
```

- **Meaning:**
  * owner (A) → read, write
  * group (A’s group) → read, write
  * others → read only

<br>

- Now the requirement changes.
- You want **only user B** to edit this file.

<br>

- You do **not** want:
  * all group members editing
  * all other users editing

- Normal permissions cannot express this rule.
- If you give write permission to `others`, everyone can edit.
- If you change group ownership, you affect multiple users.
- This is exactly where ACL is required.

---

<br>
<br>

## What ACL Adds on Top of Normal Permissions

ACL adds **named permissions**.

- **Instead of only:**
  * user::
  * group::
  * other::

<br>

- **ACL allows:**
  * user:username:
  * group:groupname:

<br>

- **So permissions become:**
  * base permissions (owner, group, others)
  * **extra rules for specific users and groups**

ACL does **not** replace normal permissions. It extends them.

---

<br>
<br>

## Checking Whether a File Has ACL

**Run:**

```bash
getfacl testfile
```

**Example output:**

```bash
# file: testfile
# owner: A
# group: A
user::rw-
group::rw-
other::r--
```

- This means **no extra ACL entries exist yet**.
- If ACL exists, you will see named users or groups listed.

---

<br>
<br>

## Giving Permission to a Specific User (Core Use Case)

**Requirement:**
- Only user **B** should read and write `testfile`.

**Command:**

```bash
setfacl -m u:B:rw testfile
```

<br>

- **What this does internally:**
  * does NOT change owner
  * does NOT change group
  * does NOT change others
  * adds a new rule only for user B

<br>

- **Check again:**

```bash
getfacl testfile
```

**You will now see:**

```bash
user::rw-
user:B:rw-
group::rw-
other::r--
```

Only **B** gets extra permission. No one else is affected.

---

<br>
<br>

## Giving Permission to a Specific Group

**Requirement:**
- All users of a particular group should access the file.

**Command:**

```bash
setfacl -m g:devteam:rw testfile
```

Now only that group has access, without changing the file’s owning group.

<br>

- **ACL is commonly used when:**
  * multiple teams share files
  * ownership cannot be changed
  * permissions must be precise

---

<br>
<br>

## How ACL Is Evaluated (Important Logic)

**ACL evaluation follows this order:**

1. Named user ACL (user:username)
2. File owner
3. Named group ACL (group:groupname)
4. File group
5. Others

This means **named ACL rules override normal permissions**.

Understanding this order is critical while troubleshooting.

---

<br>
<br>

## The ACL Mask (Most Important and Most Confusing Part)

- ACL has something called a **mask**.

- **The mask defines the maximum permission allowed for:**
   * named users
   * named groups
   * owning group

If mask blocks write, then even if ACL says rw, write will not work.

**Check mask:**

```bash
getfacl testfile
```

Example:

```bash
mask::r--
```

- **This means:**
  * ACL entry may say `rw`
  * actual effective permission becomes read only

**Set mask explicitly:**

```bash
setfacl -m m:rw testfile
```

Always check mask when ACL "looks right but doesn’t work".

---

<br>
<br>

## Removing a Specific ACL Entry

**To remove ACL for user B:**

```bash
setfacl -x u:B testfile
```

This removes only that user’s rule.

Nothing else is touched.

---

<br>
<br>

## Removing All ACL Entries (Back to Normal Permissions)

**To completely remove ACL and return to traditional permissions:**

```bash
setfacl -b testfile
```

This is often done during cleanup or troubleshooting.

---

<br>
<br>

## ACL on Directories (Recursive Permissions)

**Requirement:**
- User B should access **everything inside a directory**.

**Command:**

```bash
setfacl -R -m u:B:rwx /path/to/dir
```

- **This applies ACL to:**
  * directory
  * all existing files
  * all subdirectories

Use carefully. Recursive ACL can affect many files.

---

<br>
<br>

## Default ACL (For New Files and Directories)

**Problem:**
- New files inside a directory should automatically get ACL.

Solution: **default ACL**

```bash
setfacl -d -m u:B:rw /shared/dir
```

- **Now:**
  * existing files remain unchanged
  * **newly created files inherit ACL**

- Check default ACL:
```bash
getfacl /shared/dir
```

Default ACL is one of the most powerful ACL features.

---

<br>
<br>

## Copying ACL Between Files

**To copy ACL from one file:**

```bash
getfacl file1 > acl.txt
setfacl --set-file=acl.txt file2
```

Useful for standard permission templates.

---

<br>
<br>

## Checking Effective Permissions

Sometimes permissions look correct but access is denied.

**Check effective permissions:**

```bash
getfacl testfile
```

**Look at:**
* mask
* effective permission comments

Effective permissions are what actually apply.

---

<br>
<br>

## Common ACL Commands (Quick Reference)

```bash
getfacl file
setfacl -m u:user:perm file
setfacl -m g:group:perm file
setfacl -x u:user file
setfacl -b file
setfacl -R -m u:user:perm dir
setfacl -d -m u:user:perm dir
```

---

<br>
<br>

## When ACL Should Be Used (DBA / Admin View)

**Use ACL when:**
* permissions must be user-specific
* ownership cannot be changed
* multiple teams share the same filesystem

**Avoid ACL when:**
* simple ownership solves the problem
* over-engineering permissions

ACL is powerful, but misuse leads to confusion.

---

<br>
<br>

## One-Line Mental Model

**ACL means:**

“This exact user or group can access this file — without touching owner, group, or others.”

If you remember this line, you remember why ACL exists.

---

<br>
<br>

## Final Practical Advice

**When debugging ACL issues:**
* always check `getfacl`
* always check the mask
* always confirm effective permissions

ACL is not hard. It is **precise**. Precision demands discipline.

If permissions behave oddly, ACL is often the reason — either used correctly or abused.

That’s the complete picture.
