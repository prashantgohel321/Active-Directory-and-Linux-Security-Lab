# getent-and-nsswitch.md

This file explains **how `getent` works**, how it interacts with the **Name Service Switch (NSS)**, how it pulls data from local files and SSSD/AD, and why it is one of the MOST important debugging commands when dealing with AD integration.

If `getent` fails, identity resolution is broken — and AD logins will not work.

This file covers:
- what `getent` actually does
- how `nsswitch.conf` controls lookup order
- how SSSD participates in NSS lookups
- practical examples for users, groups, hosts, services
- debugging identity issues using `getent`
- all common failure scenarios and real fixes

---

- [getent-and-nsswitch.md](#getent-and-nsswitchmd)
- [1. What `getent` actually does](#1-what-getent-actually-does)
- [2. How `nsswitch.conf` determines lookup order](#2-how-nsswitchconf-determines-lookup-order)
- [3. `getent passwd` for local users](#3-getent-passwd-for-local-users)
- [4. `getent passwd` for AD users via SSSD](#4-getent-passwd-for-ad-users-via-sssd)
- [5. `getent group` for AD groups](#5-getent-group-for-ad-groups)
- [6. `getent hosts` for DNS testing](#6-getent-hosts-for-dns-testing)
- [7. How `getent` interacts with SSSD](#7-how-getent-interacts-with-sssd)
- [8. Real troubleshooting using `getent`](#8-real-troubleshooting-using-getent)
  - [Case 1 — AD login fails AND `getent passwd username` fails](#case-1--ad-login-fails-and-getent-passwd-username-fails)
  - [Case 2 — `getent passwd username` works but `ssh username@server` fails](#case-2--getent-passwd-username-works-but-ssh-usernameserver-fails)
  - [Case 3 — `getent group` shows empty or missing groups](#case-3--getent-group-shows-empty-or-missing-groups)
  - [Case 4 — local user overrides AD user](#case-4--local-user-overrides-ad-user)
  - [Case 5 — `getent` very slow](#case-5--getent-very-slow)
- [9. Practical examples you will actually use](#9-practical-examples-you-will-actually-use)
    - [1. Check if AD user exists](#1-check-if-ad-user-exists)
    - [2. Check group membership](#2-check-group-membership)
    - [3. Check UID/GID mapping](#3-check-uidgid-mapping)
    - [4. Check if DNS resolution respects nsswitch](#4-check-if-dns-resolution-respects-nsswitch)
    - [5. Check AD group's members](#5-check-ad-groups-members)
- [10. Summary — what `getent` proves and what it doesn’t](#10-summary--what-getent-proves-and-what-it-doesnt)
  - [What `getent` proves:](#what-getent-proves)
  - [What `getent` does NOT prove:](#what-getent-does-not-prove)
- [What you achieve after this file](#what-you-achieve-after-this-file)


<br>
<br>

# 1. What `getent` actually does

Syntax examples:
```bash
getent passwd username
getent group LinuxUsers
getent hosts server.gohel.local
```

`getent` stands for **get entries** — it queries the system’s NSS (Name Service Switch) databases.

NSS is defined in:
```bash
/etc/nsswitch.conf
```

When you run:
```bash
getent passwd testuser
```
it does NOT read `/etc/passwd` directly.

Instead:
```bash
getent → glibc → nsswitch.conf → NSS modules → files/sss/dns/etc.
```

This means `getent` is the authoritative test for whether the system can *see* a user or group.

---

<br>
<br>

# 2. How `nsswitch.conf` determines lookup order

Typical relevant lines:
```bash
passwd:     files sss
group:      files sss
shadow:     files sss
hosts:      files dns
services:   files sss
```

Meaning:
- Linux checks **local files** first (`/etc/passwd`, `/etc/group`)
- If not found, it checks **SSSD** for AD users

If `sss` is removed → AD user resolution breaks.

Check:
```bash
cat /etc/nsswitch.conf | grep passwd
```

---

<br>
<br>

# 3. `getent passwd` for local users

Example:
```bash
getent passwd root
```
Output:
```bash
root:x:0:0:root:/root:/bin/bash
```
This confirms the system can resolve the local user.

---

<br>
<br>

# 4. `getent passwd` for AD users via SSSD

Example:
```bash
getent passwd testuser
```
Expected output:
```bash
testuser:*:123456789:123456789:Test User:/home/testuser:/bin/bash
```
This proves:
- SSSD resolved the identity
- UID/GID mapping succeeded
- LDAP communication works

If this works but login fails → authentication issue, not identity.

---

<br>
<br>

# 5. `getent group` for AD groups

Example:
```bash
getent group LinuxUsers
```
Expected output:
```bash
LinuxUsers:*:123456790:testuser,devuser,adminuser
```
This proves:
- SSSD successfully fetched group information
- LDAP group membership resolution works

If empty group or missing group → AD group resolution problem.

---

<br>
<br>

# 6. `getent hosts` for DNS testing

`getent` can also check DNS resolution:
```bash
getent hosts dc01.gohel.local
```
Equivalent to `host` or `dig`, but obeys nsswitch order.

If hosts: line is:
```bash
hosts: files dns
```
Then:
- `/etc/hosts` checked first
- Then DNS

This is IMPORTANT:  
If `/etc/hosts` contains wrong entries, DNS is never queried.

---

<br>
<br>

# 7. How `getent` interacts with SSSD

When `sss` appears in nsswitch, any of the following commands will call SSSD:
```bash
getent passwd username
getent group groupname
groups username
id username
```

SSSD responds using:
- sssd_nss.log (for identity resolution)
- LDAP/AD lookups for groups, home directory, shell

Debug NSS issues:
```bash
tail -f /var/log/sssd/sssd_nss.log
```
Look for errors like:
```bash
NSS: User lookup failed
NSS: Connection to Data Provider failed
Error retrieving groups for user
```

---

<br>
<br>

# 8. Real troubleshooting using `getent`

## Case 1 — AD login fails AND `getent passwd username` fails
Identity resolution is broken.

Possible causes:
- SSSD not running
- DNS broken
- AD unreachable
- nsswitch misconfigured

Debug:
```bash
systemctl status sssd
sssctl domain-status
sssctl user-show username
```

Fix DNS or SSSD.

---

## Case 2 — `getent passwd username` works but `ssh username@server` fails
Identity lookup OK, authentication failing.

Debug:
```bash
kinit username
tail -f /var/log/sssd/sssd_pam.log
```

Common causes:
- time skew
- wrong password
- access denied

---

## Case 3 — `getent group` shows empty or missing groups
Possible causes:
- SSSD can’t fetch group memberships from AD
- ldap_group_nesting_level too low
- AD replication delay

Debug:
```bash
tail -f /var/log/sssd/sssd_DOMAIN.log
```

Fix DNS or adjust SSSD.

---

## Case 4 — local user overrides AD user
If local `/etc/passwd` contains user `testuser`, NSS resolves that user BEFORE SSSD.

Output:
```bash
getent passwd testuser
```
If UID is small (<10000), it's local and overrides AD.

Fix: rename local user or adjust nsswitch order.

---

## Case 5 — `getent` very slow
Cause: SSSD trying multiple unreachable DCs.

Debug:
```bash
sssctl domain-status
```
Look for offline DC entries.

Fix DNS or add correct DCs.

---

<br>
<br>

# 9. Practical examples you will actually use

### 1. Check if AD user exists
```bash
getent passwd alice
```

### 2. Check group membership
```bash
getent group LinuxAdmins
```

### 3. Check UID/GID mapping
```bash
getent passwd bob | cut -d: -f3,4
```

### 4. Check if DNS resolution respects nsswitch
```bash
getent hosts dc01.gohel.local
```

### 5. Check AD group's members
```bash
getent group DevelopmentTeam
```

---

<br>
<br>

# 10. Summary — what `getent` proves and what it doesn’t

## What `getent` proves:
```bash
1. Whether the system can find AD user/group entries
2. Whether SSSD is working
3. Whether DNS/LDAP resolution works
4. Whether UID/GID mapping is correct
5. Whether group membership is fetched correctly
```

## What `getent` does NOT prove:
```bash
1. Password authentication (Kerberos) is working
2. User is allowed to log in (access control)
3. PAM session will succeed (home dir, limits)
```

But identity failure ALWAYS appears in `getent` first.

---

<br>
<br>

# What you achieve after this file

You can now use `getent` to validate the identity resolution pipeline end-to-end.  
You know how NSS, SSSD, LDAP, and local files interact and how to debug each component.

`getent` is the **first command** you should run every time AD login fails — and this file shows you exactly how to interpret it.