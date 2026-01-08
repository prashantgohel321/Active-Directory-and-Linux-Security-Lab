# Foreman Patch Management – Content Views and Versioning

This file explains **Content Views** and **versioning** in Foreman.

This is the point where **real patch control starts**.

If this file is not clear:

* Patches will look random
* Rollback will not make sense
* Prod stability will be at risk


---

<br>
<br>

- [Foreman Patch Management – Content Views and Versioning](#foreman-patch-management--content-views-and-versioning)
  - [1. What Is a Content View (Simple Definition)](#1-what-is-a-content-view-simple-definition)
  - [2. Why Content Views Exist](#2-why-content-views-exist)
  - [3. What “Freezing Content” Means](#3-what-freezing-content-means)
  - [4. Creating a Content View (Web UI)](#4-creating-a-content-view-web-ui)
  - [5. Publishing a Content View Version](#5-publishing-a-content-view-version)
  - [6. Content View Versions](#6-content-view-versions)
  - [7. Promotion Uses Versions (Not Repos)](#7-promotion-uses-versions-not-repos)
  - [8. How Servers Use Content Views](#8-how-servers-use-content-views)
  - [9. Client-Side Result (dnf View)](#9-client-side-result-dnf-view)
  - [10. Rollback Using Content Views](#10-rollback-using-content-views)
  - [11. Common Mistakes](#11-common-mistakes)
  - [12. What You Must Be Clear About Now](#12-what-you-must-be-clear-about-now)


<br>
<br>

## 1. What Is a Content View (Simple Definition)

A Content View is a **controlled snapshot of repositories**.

It defines:

* Which repositories are included
* Which package versions are visible

Content Views decide **what servers are allowed to see**.

---

<br>
<br>

## 2. Why Content Views Exist

Repositories change all the time.

**If servers point directly to repos:**
* New packages appear suddenly
* Versions change without notice

Content Views stop this.
They freeze content into **stable, predictable sets**.

---

<br>
<br>

## 3. What “Freezing Content” Means

When a Content View version is published:

* Current package versions are captured
* That snapshot never changes
* Future repo syncs do not affect it

This makes patching **safe and repeatable**.

---

<br>
<br>

## 4. Creating a Content View (Web UI)

UI path:

```bash
Content → Content Views → Create Content View
```

You must choose:

* Name
* Repositories

At this stage:

* No servers are affected

---

<br>
<br>

## 5. Publishing a Content View Version

After repos are synced:

UI path:

```bash
Content → Content Views → Select View → Publish New Version
```

What happens:

* Foreman takes a snapshot
* Assigns a version number
* Locks package versions

This is a **key patching step**.

---

<br>
<br>

## 6. Content View Versions

Each publish creates:

* Version 1.0
* Version 1.1
* Version 1.2

Each version:

* Is immutable
* Can be promoted independently

Old versions are kept for rollback.

---

<br>
<br>

## 7. Promotion Uses Versions (Not Repos)

Promotion always works on:

* A specific Content View version

UI path:

```bash
Content → Content Views → Versions → Promote
```

Promotion:

* Moves the same snapshot forward
* Does not change packages

---

<br>
<br>

## 8. How Servers Use Content Views

Servers are attached to:

* One Content View
* One Lifecycle Environment

UI path:

```bash
Hosts → All Hosts → Edit
```

Server behavior:

* Sees only its assigned version
* Never sees future versions

---

<br>
<br>

## 9. Client-Side Result (dnf View)

On a server:

```bash
dnf repolist
```

Repos point to:

* Foreman URLs
* Specific Content View versions

This enforces patch control.

---

<br>
<br>

## 10. Rollback Using Content Views

If an update causes issues:

* Promote older version back
* Reattach server if needed

Rollback works because:

* Old versions still exist
* They never change

This is why versioning matters.

---

<br>
<br>

## 11. Common Mistakes

Avoid these:

* Publishing without testing
* Deleting old versions too early
* Confusing repo sync with version publish
* Attaching servers to wrong view

These break patch safety.

---

## 12. What You Must Be Clear About Now

You should clearly know:

* Content Views freeze repositories
* Versions are immutable snapshots
* Promotion moves versions, not repos
* Rollback depends on old versions

---


