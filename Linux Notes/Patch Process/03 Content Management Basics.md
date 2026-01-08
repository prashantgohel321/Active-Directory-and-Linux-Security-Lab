# Foreman Patch Management – Content Management Basics

This file explains **how packages enter Foreman** and **how Foreman controls them**.

**If you do not understand this file properly:**
* You will not understand patching
* Content Views will feel confusing
* Lifecycle Environments will look useless

Everything here is **foundational**.

Simple English. Real admin flow. Accurate to Foreman Web UI.

---

<br>
<br>

- [Foreman Patch Management – Content Management Basics](#foreman-patch-management--content-management-basics)
  - [1. What “Content” Means in Foreman](#1-what-content-means-in-foreman)
  - [2. Why Content Management Exists](#2-why-content-management-exists)
  - [3. High-Level Content Flow (End to End)](#3-high-level-content-flow-end-to-end)
  - [4. Products (First Visible Layer)](#4-products-first-visible-layer)
  - [5. Repositories (Actual Source of Packages)](#5-repositories-actual-source-of-packages)
  - [6. Repository Sync (Very Important)](#6-repository-sync-very-important)
  - [7. What Happens During Sync (Internally)](#7-what-happens-during-sync-internally)
  - [8. Why Sync ≠ Patching](#8-why-sync--patching)
  - [9. Verify Synced Content (Web UI)](#9-verify-synced-content-web-ui)
  - [10. Verify Synced Content (CLI – Foreman Server)](#10-verify-synced-content-cli--foreman-server)
  - [11. Why Public Repos Must Be Removed from Clients](#11-why-public-repos-must-be-removed-from-clients)
  - [12. What Clients See After Proper Content Setup](#12-what-clients-see-after-proper-content-setup)
  - [13. Common Content Management Mistakes](#13-common-content-management-mistakes)
  - [14. What You Must Clearly Understand Now](#14-what-you-must-clearly-understand-now)


<br>
<br>

## 1. What “Content” Means in Foreman

**In Foreman (with Katello), **content** means:**
* RPM packages
* Repository metadata
* Update information

Foreman does **not create packages**.
It **collects, stores, and controls** packages.

Think of Foreman as a **controlled warehouse** for RPMs.

---

<br>
<br>

## 2. Why Content Management Exists

**Without content management:**
* Servers connect directly to public repos
* Package versions change unpredictably
* Patching is uncontrolled

<br>
<br>

**With Foreman:**
* You decide what packages are available
* You decide when updates move forward
* Servers only see approved content

This is the base of safe patching.

---

<br>
<br>

## 3. High-Level Content Flow (End to End)

**This is the full flow, simplified:**

1. Foreman connects to OS repositories
2. Repositories are synced into Foreman
3. Synced content is frozen into versions
4. Versions are assigned to environments
5. Servers consume only assigned content

No server pulls packages randomly.

<br>
<details>
<summary><mark><b>Explained in detail</b></mark></summary>
<br>

**Step 1: Foreman connects to OS repositories**

**What this means:**
- Foreman itself acts like a client to upstream OS repositories.

**Examples:**
- Rocky Linux BaseOS
- Rocky Linux AppStream
- EPEL

These are external package sources.

Foreman uses HTTPS to connect to them.

**Where you see this in Web UI**
```bash
Content → Products → Repositories
```

**Each repository has:**
- A repo URL
- SSL settings
- GPG key info

**What happens internally**
- Foreman reads the repo URL
- Pulp makes HTTPS connections to upstream mirrors
- Metadata and RPMs are requested

**At this stage:**
- No servers are involved
- Only Foreman talks to upstream repos

**Why this step exists**

**So that:**
- Only one system talks to the internet
- Clients don’t depend on public mirrors
- Admins control package intake

<br>
<br>

**Step 2: Repositories are synced into Foreman**

**What this means**
- “Sync” is download + store, nothing more.

**When you click Sync:**
- Repo metadata is downloaded
- RPM packages are downloaded
- Data is stored locally on Foreman

**Web UI path**
```bash
Content → Products → [Product] → Sync
```

**CLI (Foreman server)**
```bash
hammer repository synchronize --id <repo-id>
```

**What happens internally**
- Pulp downloads RPMs
- RPMs are saved on Foreman disk
- Metadata is indexed

**Important:**
- Sync makes packages available, not usable by servers.

**Real-life analogy**
```
Think of it like:

Stock arriving at a warehouse
Goods are inside the building, but not yet released
```

<br>
<br>

**Step 3: Synced content is frozen into versions**
- This is the most important step

**What “frozen” means**
- Foreman takes synced repositories and creates a snapshot.

**This snapshot:**
- Has exact package versions
- Never changes
- Is immutable
- This snapshot is called a Content View version.

**Web UI path**
```bash
Content → Content Views → Publish New Version
```

**What happens internally**
- Foreman selects synced repos
- Current package state is captured
- A version number is created

**After this:**
- New upstream packages do NOT affect this version
- Even if you sync again, this version stays same

**Why this step exists So that**:
- Prod never changes unexpectedly
- Patch state is reproducible
- Rollback is possible

<br>
<br>

**Step 4: Versions are assigned to environments**

**What this means**
- A Content View version is not used automatically.
- You must decide where it can be used.

**Typical environments:**
- Dev
- Test
- Prod

**Web UI path**
```bash
Content → Content Views → Versions → Promote
```

**What happens internally**
- Version is promoted to an environment
- Foreman records which environment can see which version
- Other environments do not see it

**Why this step exists So that:**
- New patches are tested before prod
- Same content flows step by step
- No direct jump to production

**Real example**
- Version 1.2 → Dev
- Same version → Test
- Same version → Prod

No re-sync, no re-build.

<br>
<br>

**Step 5: Servers consume only assigned content**

**What this means**

Servers:
- Are linked to one lifecycle environment
- Use only the Content View version assigned there
= They cannot see anything else.

**Web UI path**
```bash
Hosts → All Hosts → Edit → Lifecycle Environment / Content View
```

**Client-side view**

On the server:
```bash
dnf repolist
```

**You will see**:
- Foreman-generated repos
- URLs tied to content view versions

**Important internal rule**

Servers:
- Do not know about upstream repos
- Do not know about Products
- Do not know about Content Views

They just consume what Foreman exposes.

</details>
<br>

---

## 4. Products (First Visible Layer)

In Foreman UI:

```bash
Content → Products
```

A **Product** is a logical container.

Example product:

* Rocky Linux 9
* EPEL

Product purpose:

* Groups related repositories
* Makes repo management clean

Products do not contain packages directly.

---

<br>
<br>

## 5. Repositories (Actual Source of Packages)

In Foreman UI:

```bash
Content → Products → Repositories
```

A **Repository** is:

* A defined package source
* Like BaseOS or AppStream

Examples:

* Rocky 9 BaseOS
* Rocky 9 AppStream

Repositories are where RPMs come from.

---

<br>
<br>

## 6. Repository Sync (Very Important)

Foreman does **not automatically pull content**.

You must sync repositories manually or by schedule.

UI path:

```bash
Content → Products → Select Product → Sync
```

During sync:

* Foreman downloads metadata
* Foreman downloads RPMs
* Data is stored locally

No sync = no packages available.

---

<br>
<br>

## 7. What Happens During Sync (Internally)

When sync starts:

* Foreman talks to upstream repo
* Pulp downloads content
* Metadata is indexed
* Packages are stored on disk

Disk usage increases quickly.

This is expected.

---

<br>
<br>

## 8. Why Sync ≠ Patching

Very important concept:

**Syncing content does NOT patch servers**.

Sync only means:
* Packages are available in Foreman

Servers will not see new packages until:
* Content Views are updated
* Versions are promoted

This separation prevents accidents.

---

<br>
<br>

## 9. Verify Synced Content (Web UI)

After sync, verify:

```bash
Content → Products → Repositories → [Repo Name]
```

Check:

* Package count
* Last sync time
* Sync status

If package count is zero:

* Repo URL is wrong
* SSL or DNS issue exists

---

<br>
<br>

## 10. Verify Synced Content (CLI – Foreman Server)

On Foreman server:

```bash
hammer repository list
```

```bash
hammer repository info --id <repo-id>
```

These commands confirm:

* Repo exists
* Sync status
* Content availability

---

<br>
<br>

## 11. Why Public Repos Must Be Removed from Clients

Managed hosts should **not** use public repos.

Check on client:

```bash
dnf repolist
```

Expected:
* Repos point to Foreman URL

If public repos exist:
* Patching becomes uncontrolled
* Versions drift

Foreman must be the single source.

---

<br>
<br>

## 12. What Clients See After Proper Content Setup

Clients:

* Do not know about Products
* Do not know about Repositories
* Only see **Foreman-generated repos**

This is intentional.

Clients consume content.

Foreman controls content.

---

<br>
<br>

## 13. Common Content Management Mistakes

Avoid these:

* Syncing repos without disk planning
* Mixing OS versions in one product
* Syncing everything blindly
* Expecting sync to patch hosts

These lead to storage waste and confusion.

---

<br>
<br>

## 14. What You Must Clearly Understand Now

After this file, you must know:

* Where packages come from
* How they enter Foreman
* Why sync does not patch systems
* Why Foreman controls visibility, not `dnf`

If this is clear, patching logic becomes easy.

---

