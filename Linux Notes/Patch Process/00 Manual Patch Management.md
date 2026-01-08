# Linux Patch Management & Package Management (DNF & RPM)

<br>
<br>

- [Linux Patch Management \& Package Management (DNF \& RPM)](#linux-patch-management--package-management-dnf--rpm)
  - [1. What Is Patching (In Practical Terms)](#1-what-is-patching-in-practical-terms)
  - [2. Role of a Linux Administrator in Patching](#2-role-of-a-linux-administrator-in-patching)
  - [3. Understanding DNF (dandified yum) (High-Level)](#3-understanding-dnf-dandified-yum-high-level)
  - [4. Cache Management (Very Important Before Patching)](#4-cache-management-very-important-before-patching)
    - [4.1 Why Cache Exists](#41-why-cache-exists)
    - [4.2 `dnf clean all`](#42-dnf-clean-all)
    - [4.3 Selective Cleaning Options](#43-selective-cleaning-options)
  - [5. Repository Management](#5-repository-management)
    - [5.1 Listing Repositories](#51-listing-repositories)
    - [5.2 Repository Files Location](#52-repository-files-location)
    - [5.3 Querying Repositories](#53-querying-repositories)
    - [5.4 Package Information (Repo Side)](#54-package-information-repo-side)
  - [6. Checking Available Updates (Safe Step)](#6-checking-available-updates-safe-step)
    - [6.1 `dnf check-update`](#61-dnf-check-update)
  - [7. Updating a Single Package (Controlled Update)](#7-updating-a-single-package-controlled-update)
    - [7.1 Why Single Package Update Matters](#71-why-single-package-update-matters)
    - [7.2 Update a Specific Package](#72-update-a-specific-package)
    - [7.3 Verifying Installed Package (DNF)](#73-verifying-installed-package-dnf)
  - [8. RPM (Low-Level Package Management)](#8-rpm-low-level-package-management)
    - [8.1 List All Installed Packages](#81-list-all-installed-packages)
    - [8.2 Get Package Information](#82-get-package-information)
    - [8.3 List Files Installed by a Package](#83-list-files-installed-by-a-package)
    - [8.4 Find Which Package Owns a File](#84-find-which-package-owns-a-file)
    - [8.5 Other Useful RPM Queries](#85-other-useful-rpm-queries)
  - [9. Downgrading Packages (Damage Control)](#9-downgrading-packages-damage-control)
    - [9.1 Downgrade a Package](#91-downgrade-a-package)
  - [10. DNF History (Most Important Safety Net)](#10-dnf-history-most-important-safety-net)
    - [10.1 View History](#101-view-history)
    - [10.2 Inspect a Specific Event](#102-inspect-a-specific-event)
    - [10.3 Undo a Transaction](#103-undo-a-transaction)
  - [11. Updating All Packages (Full Patch Cycle)](#11-updating-all-packages-full-patch-cycle)
    - [11.1 When to Do Full Update](#111-when-to-do-full-update)
    - [11.2 Full Update Procedure](#112-full-update-procedure)
  - [12. Post-Patching Validation (Mandatory)](#12-post-patching-validation-mandatory)
    - [12.1 Basic System Checks](#121-basic-system-checks)
    - [12.2 Service Validation](#122-service-validation)
    - [12.3 Logs Check](#123-logs-check)
  - [13. Monitoring After Patching](#13-monitoring-after-patching)
  - [14. Useful Extra DNF Commands (Admins Use These)](#14-useful-extra-dnf-commands-admins-use-these)
  - [15. Final Admin Mindset](#15-final-admin-mindset)


---

<br>
<br>

## 1. What Is Patching (In Practical Terms)

Patching means **bringing installed software to a safer, stable, or fixed state** using updates provided by vendors or repositories.

**Patching usually includes:**
* Security fixes
* Bug fixes
* Stability improvements
* Occasionally performance or compatibility changes

**As a Linux administrator, patching is not clicking update blindly. It is:**
* Knowing **what will change**
* Controlling **when it changes**
* Being able to **rollback if things break**

---

<br>
<br>

## 2. Role of a Linux Administrator in Patching

**A Linux admin is responsible for:**

* Verifying repositories
* Checking update scope
* Applying **minimum required changes**
* Preventing accidental upgrades
* Tracking change history
* Reverting incorrect updates
* Validating system health after patching

Patching is **risk management**, not just updating packages.

---

<br>
<br>

## 3. Understanding DNF (dandified yum) (High-Level)

`dnf` is the modern package manager for RPM‑based systems.

**What DNF does internally:**
* Talks to configured repositories
* Downloads metadata (package lists, versions)
* Resolves dependencies
* Downloads RPM files
* Hands off installation to RPM
* Records every transaction in history

DNF does **dependency resolution**.
RPM does **package installation and tracking**.

Both matter.

---

<br>
<br>

## 4. Cache Management (Very Important Before Patching)

### 4.1 Why Cache Exists

**DNF stores:**
* Downloaded RPM packages
* Repository metadata
* Temporary transaction files

<br>

**Location (important):**

```bash
/var/cache/dnf/
```

<br>

**Problems caused by cache:**
* Corrupt metadata
* Old repo data
* Inconsistent update results

So before patching → **clean cache**.

---

<br>
<br>

### 4.2 `dnf clean all`

```bash
dnf clean all
```

**What it does:**
* Removes downloaded RPM files
* Deletes repository metadata
* Clears temporary DNF files

**Impact:**
* Frees disk space
* Forces fresh metadata download
* Fixes repo mismatch issues

Recommended usage:

```bash
sudo dnf clean all
```

**Why sudo:**

* User cache + system cache both get cleared

---

<br>
<br>

### 4.3 Selective Cleaning Options

```bash
sudo dnf clean metadata
```

Clears only repository metadata (package lists).

```bash
sudo dnf clean packages
```

Clears only downloaded RPM files.

Use cases:

* Metadata issue → clean metadata
* Disk space issue → clean packages

---

<br>
<br>

## 5. Repository Management

Repositories define **where packages come from**.

Misconfigured repos = broken updates.

---

<br>
<br>

### 5.1 Listing Repositories

```bash
dnf repolist
```

Shows:

* Enabled repositories only

---

<br>
<br>

```bash
dnf repolist all
```

Shows:

* Enabled repos
* Disabled repos

This is what admins mostly use.

---

<br>
<br>

```bash
dnf repolist --disabled
```

Shows only disabled repos.

Useful when:

* Verifying optional repos
* Checking why a package is missing

---

<br>
<br>

### 5.2 Repository Files Location

Repositories are defined in:

```
/etc/yum.repos.d/
```

Each `.repo` file describes:

* Name
* BaseURL
* GPG key
* Enabled status

Admins should **review repo files before patching**.

---

<br>
<br>

### 5.3 Querying Repositories

```bash
dnf repoquery
```

Used to:

* Find which repo provides a package
* Check available versions

Example:

```bash
dnf repoquery podman
```

---

<br>
<br>

### 5.4 Package Information (Repo Side)

```bash
dnf info podman
```

**Shows:**
* Version
* Release
* Architecture
* Repository
* Summary and description

This tells you **what you are about to install or update**.

---

<br>
<br>

## 6. Checking Available Updates (Safe Step)

### 6.1 `dnf check-update`

```bash
dnf check-update
```

**What it does:**

* Checks repositories
* Compares installed versions
* Lists newer versions

**Important:**

* **Does NOT install anything**
* Safe command

Admins use this before every patching window.

---

<br>
<br>

## 7. Updating a Single Package (Controlled Update)

### 7.1 Why Single Package Update Matters

Blind `dnf update` can:

* Update kernel
* Update critical libraries
* Cause service downtime

So sometimes you update **only what is required**.

---

<br>
<br>

### 7.2 Update a Specific Package

```bash
sudo dnf update podman -y
```

What happens:

* Only `podman` is considered
* Dependencies updated **only if required**

Best practice:

* Update specific packages first
* Avoid mass updates on production

---

<br>
<br>

### 7.3 Verifying Installed Package (DNF)

```bash
dnf list installed podman
```

Shows:

* Installed version
* Architecture
* Repo origin

---

<br>
<br>

## 8. RPM (Low-Level Package Management)

DNF uses RPM underneath.

**RPM knows:**

* What is installed
* What files belong to which package
* When packages were installed

RPM does **not resolve dependencies** by itself.

---

<br>
<br>

### 8.1 List All Installed Packages

```bash
rpm -qa
```

Flags:

* `-q` → query
* `-a` → all

Often combined with grep:

```bash
rpm -qa | grep podman
```

---

<br>
<br>

### 8.2 Get Package Information

```bash
rpm -qi podman
```

Shows:

* Version
* Install date
* Vendor
* Description

---

<br>
<br>

### 8.3 List Files Installed by a Package

```bash
rpm -ql podman
```

Use cases:

* Debug file locations
* Verify binary paths

---

<br>
<br>

### 8.4 Find Which Package Owns a File

```bash
rpm -qf /usr/bin/podman
```

Critical for troubleshooting:

* Missing files
* Permission issues

---

<br>
<br>

### 8.5 Other Useful RPM Queries

```bash
rpm -qa --last
```

Shows install order (recent first).

```bash
rpm -qc podman
```

Lists config files only.

```bash
rpm -qd podman
```

Lists documentation files.

```bash
rpm -qR podman
```

Lists package dependencies.

---

<br>
<br>

## 9. Downgrading Packages (Damage Control)

Mistakes happen.

Wrong update → rollback is mandatory skill.

---

<br>
<br>

### 9.1 Downgrade a Package

```bash
sudo dnf downgrade podman -y
```

What it does:

* Installs previous available version
* Uses repo history

Works only if:

* Older version still exists in repos or cache

---

<br>
<br>

## 10. DNF History (Most Important Safety Net)

DNF tracks **every transaction**.

---

<br>
<br>

### 10.1 View History

```bash
dnf history
```

Shows:

* ID
* Command
* Date/time
* Action (install, upgrade, downgrade, remove)

Admins always check this after patching.

---

<br>
<br>

### 10.2 Inspect a Specific Event

```bash
dnf history info 4
```

Shows:

* Exactly what changed
* Which packages were affected
* Old vs new versions

---

<br>
<br>

### 10.3 Undo a Transaction

Example scenario:

* `zsh` installed by mistake

```bash
dnf install -y zsh
```

Check history:

```bash
dnf history
```

Undo install:

```bash
dnf history undo 6
```

This restores system to **previous state**.

---

<br>
<br>

## 11. Updating All Packages (Full Patch Cycle)

### 11.1 When to Do Full Update

Only when:

* Approved patch window
* Maintenance mode
* Snapshot/backup exists

---

<br>
<br>

### 11.2 Full Update Procedure

```bash
sudo dnf clean all
sudo dnf check-update
sudo dnf update -y
```

Then:

```bash
reboot
```

Kernel or core libraries often require reboot.

---

<br>
<br>

## 12. Post-Patching Validation (Mandatory)

Never skip this.

### 12.1 Basic System Checks

```bash
uptime
```

```bash
systemctl status
```

```bash
df -h
```

---

### 12.2 Service Validation

```bash
systemctl status <service>
```

```bash
ss -tulpn
```

---

### 12.3 Logs Check

```bash
journalctl -p err -b
```

Checks critical errors after reboot.

---

## 13. Monitoring After Patching

Watch for:

* CPU spikes
* Memory leaks
* Service failures

Tools:

```bash
top
htop
free -m
vmstat
```

---

## 14. Useful Extra DNF Commands (Admins Use These)

```bash
dnf provides /usr/bin/python3
```

```bash
dnf search nginx
```

```bash
dnf remove <package>
```

```bash
dnf autoremove
```

```bash
dnf list available
```

---

## 15. Final Admin Mindset

* Never update blindly
* Always check history
* Always validate post-patch
* Always know rollback plan

Patching is **controlled change**, not a routine command.

---

**End of Document**
