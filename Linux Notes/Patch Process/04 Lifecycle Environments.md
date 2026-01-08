# Foreman Patch Management – Lifecycle Environments

This file explains **Lifecycle Environments** in Foreman.

Lifecycle Environments are the **core control mechanism** for safe patching.

If this concept is not clear:
* Production will get accidental updates
* Testing becomes meaningless
* Rollback becomes hard


---

<br>
<br>

- [Foreman Patch Management – Lifecycle Environments](#foreman-patch-management--lifecycle-environments)
  - [1. What Is a Lifecycle Environment](#1-what-is-a-lifecycle-environment)
  - [2. Why Lifecycle Environments Exist](#2-why-lifecycle-environments-exist)
  - [3. Lifecycle Environments Are Ordered](#3-lifecycle-environments-are-ordered)
  - [4. Library Environment (Special Case)](#4-library-environment-special-case)
  - [5. Creating Lifecycle Environments (Web UI)](#5-creating-lifecycle-environments-web-ui)
  - [6. Lifecycle Environments and Content Views](#6-lifecycle-environments-and-content-views)
  - [7. Promotion Between Environments](#7-promotion-between-environments)
  - [8. Real-Life Patch Flow Example](#8-real-life-patch-flow-example)
  - [9. How Servers Use Lifecycle Environments](#9-how-servers-use-lifecycle-environments)
  - [10. Client-Side View (dnf)](#10-client-side-view-dnf)
  - [11. What Lifecycle Environments Do NOT Do](#11-what-lifecycle-environments-do-not-do)
  - [12. Common Mistakes](#12-common-mistakes)
  - [13. What You Should Clearly Understand Now](#13-what-you-should-clearly-understand-now)


<br>
<br>

## 1. What Is a Lifecycle Environment

A Lifecycle Environment is a **stage** where content is used.

It answers one simple question:

> "Where is this content allowed to be used?"

Common environments:

* Dev
* Test
* QA
* Prod

They define **patch flow**, not servers.

---

<br>
<br>

## 2. Why Lifecycle Environments Exist

**Without lifecycle environments:**

* All servers see same updates
* No testing before production
* One mistake affects everything

<br>

**Lifecycle environments:**

* Separate testing from production
* Allow step-by-step promotion
* Prevent sudden production changes

---

<br>
<br>

## 3. Lifecycle Environments Are Ordered

Lifecycle environments follow a **fixed order**.

Example order:

```
Library → Dev → Test → Prod
```

Rules:

* Content must move forward
* Skipping is not allowed
* Going backward is not allowed

This enforces discipline.

---

<br>
<br>

## 4. Library Environment (Special Case)

`Library` is the first environment.

What it contains:

* Freshly synced repositories
* No controlled versions

Important:

* Servers should NOT be attached to Library
* Library is only for content preparation

---

<br>
<br>

## 5. Creating Lifecycle Environments (Web UI)

UI path:

```
Content → Lifecycle Environments
```

Steps:

1. Click Create Environment
2. Set Name (Dev/Test/Prod)
3. Select Prior Environment
4. Save

Order matters.

---

<br>
<br>

## 6. Lifecycle Environments and Content Views

Lifecycle environments **do nothing alone**.

They work **only with Content Views**.

Flow:

* Content View version is created
* Version is promoted to an environment
* Environment exposes that version

No Content View = no patch control.

---

<br>
<br>

## 7. Promotion Between Environments

Promotion means:

> Making the same content version available to the next stage.

UI path:

```bash
Content → Content Views → Versions → Promote
```

Promotion:

* Does not change packages
* Does not re-sync repos
* Uses the same frozen version

---

<br>
<br>

## 8. Real-Life Patch Flow Example

Example flow:

1. Sync repos (new patches arrive)
2. Publish Content View version 1.3
3. Promote 1.3 to Dev
4. Test on Dev servers
5. Promote same 1.3 to Test
6. Test again
7. Promote same 1.3 to Prod

Production receives **tested content only**.

---

<br>
<br>

## 9. How Servers Use Lifecycle Environments

Servers are attached to:

* One Lifecycle Environment
* One Content View

UI path:

```
Hosts → All Hosts → Edit
```

Server behavior:

* Sees only content for its environment
* Cannot see future patches

---

<br>
<br>

## 10. Client-Side View (dnf)

On a server:

```bash
dnf repolist
```

You will see:

* Repos with Foreman URLs
* URLs tied to environment and version

This is how enforcement works.

---

<br>
<br>

## 11. What Lifecycle Environments Do NOT Do

Important to avoid confusion:

They do NOT:

* Run updates
* Install packages
* Sync repositories

They only control **visibility of content**.

---

<br>
<br>

## 12. Common Mistakes

Avoid these:

* Attaching prod servers to Library
* Skipping environments
* Promoting untested versions
* Mixing environments per server

These break patch safety.

---

<br>
<br>

## 13. What You Should Clearly Understand Now

After this file, you must know:

* Why lifecycle environments exist
* How patch flow is controlled
* Why promotion is required
* How servers are protected

---

