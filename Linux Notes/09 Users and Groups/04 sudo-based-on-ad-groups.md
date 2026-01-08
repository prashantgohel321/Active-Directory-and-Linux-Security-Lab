# sudo-based-on-ad-groups.md

This file explains **how to give sudo access to Active Directory (AD) users and groups on a Linux system**, using SSSD and the sudoers system.  
This is a real enterprise requirement: teams want centralized AD groups controlling Linux privilege escalation.

This file is 100% practical:
- how sudo checks group membership
- how SSSD exposes AD groups to sudo
- how to configure sudoers safely
- exact commands to test sudo rights
- every failure scenario and fix

---

- [sudo-based-on-ad-groups.md](#sudo-based-on-ad-groupsmd)
- [1. How sudo works with AD groups](#1-how-sudo-works-with-ad-groups)
- [2. Requirements before configuring sudo](#2-requirements-before-configuring-sudo)
- [3. Method 1 — Grant sudo using AD groups (recommended)](#3-method-1--grant-sudo-using-ad-groups-recommended)
  - [Variants](#variants)
    - [Allow only specific commands:](#allow-only-specific-commands)
    - [Allow passwordless sudo:](#allow-passwordless-sudo)
- [4. Method 2 — Using FQDN AD group names](#4-method-2--using-fqdn-ad-group-names)
- [5. Method 3 — Using legacy domain style](#5-method-3--using-legacy-domain-style)
- [6. How sudo checks group membership internally](#6-how-sudo-checks-group-membership-internally)
- [7. Practical workflow to assign sudo to AD groups](#7-practical-workflow-to-assign-sudo-to-ad-groups)
    - [Step 1: Create AD group](#step-1-create-ad-group)
    - [Step 2: Add users to AD group](#step-2-add-users-to-ad-group)
    - [Step 3: Verify group membership on Linux](#step-3-verify-group-membership-on-linux)
    - [Step 4: Create sudoers rule](#step-4-create-sudoers-rule)
    - [Step 5: Test sudo](#step-5-test-sudo)
- [8. Real-world failure scenarios (and exact fixes)](#8-real-world-failure-scenarios-and-exact-fixes)
  - [Scenario 1: AD user cannot sudo but is in group](#scenario-1-ad-user-cannot-sudo-but-is-in-group)
  - [Scenario 2: Group resolves but sudo still denies](#scenario-2-group-resolves-but-sudo-still-denies)
  - [Scenario 3: FQDN group mismatch](#scenario-3-fqdn-group-mismatch)
  - [Scenario 4: user recently added to AD group but Linux doesn’t see it](#scenario-4-user-recently-added-to-ad-group-but-linux-doesnt-see-it)
  - [Scenario 5: sudo extremely slow](#scenario-5-sudo-extremely-slow)
- [9. Security best practices](#9-security-best-practices)
- [10. Summary — how AD group–based sudo works](#10-summary--how-ad-groupbased-sudo-works)
- [What you achieve after this file](#what-you-achieve-after-this-file)


<br>
<br>

# 1. How sudo works with AD groups

When a user runs:
```
sudo command
```
`sudo` checks:
1. user identity (from NSS/SSSD)
2. group membership
3. sudoers rules in:
   - `/etc/sudoers`
   - `/etc/sudoers.d/*`

Sudo does **not** authenticate with AD directly — it relies on SSSD to tell it whether the user belongs to a specific AD group.

If AD groups do not resolve → sudo cannot check membership → access denied.

Test group membership:
```
groups username
id username
``` 
If the expected group does NOT appear → fix SSSD identity resolution first.

---

<br>
<br>

# 2. Requirements before configuring sudo

These MUST work before editing sudoers:
1. AD user resolves:
```
id username
```
2. AD group resolves:
```
getent group LinuxAdmins
```
3. User is a member of that group.
4. SSSD is running and NSS configured with `sss`.

If these fail → sudo rules WILL NOT work.

---

<br>
<br>

# 3. Method 1 — Grant sudo using AD groups (recommended)

Never edit `/etc/sudoers` directly.  
Use files under `/etc/sudoers.d/`.

Example file:
```
/etc/sudoers.d/linux-admins
```

Content:
```
%LinuxAdmins ALL=(ALL) ALL
```
Where:
- `LinuxAdmins` is an AD group
- Members of this group get full sudo

Test:
```
sudo -l -U username
```
Should show allowed commands for that user.

## Variants

### Allow only specific commands:
```
%LinuxAdmins ALL=(ALL) /usr/bin/systemctl, /usr/bin/journalctl
```

### Allow passwordless sudo:
```
%LinuxAdmins ALL=(ALL) NOPASSWD: ALL
```
Use carefully.

---

<br>
<br>

# 4. Method 2 — Using FQDN AD group names

Sometimes SSSD exposes groups with domain suffix:
```
%LinuxAdmins@gohel.local ALL=(ALL) ALL
```
Check group name using:
```
getent group LinuxAdmins
```
If the group appears as:
```
LinuxAdmins@gohel.local
```
Use exactly that in sudoers:
```
%LinuxAdmins@gohel.local ALL=(ALL) ALL
```

---

<br>
<br>

# 5. Method 3 — Using legacy domain style

If fully qualified names are enabled in SSSD:
```
%GOHEL\\LinuxAdmins ALL=(ALL) ALL
```
This depends on:
```
use_fully_qualified_names = True
```

Check your SSSD config first.

---

<br>
<br>

# 6. How sudo checks group membership internally

Debugging sudo evaluation:
```
sudo -l -U username -k
```
This forces sudo to re-evaluate membership.

Check SSSD logs:
```
tail -f /var/log/sssd/sssd_nss.log
```
Look for:
```
NSS: Group resolution request
```

If sudo cannot resolve group membership, it fails silently with:
```
username is not allowed to run sudo on hostname
```

---

<br>
<br>

# 7. Practical workflow to assign sudo to AD groups

### Step 1: Create AD group
Example: `LinuxAdmins` under OU=Groups.

### Step 2: Add users to AD group
Use ADUC or PowerShell:
```
Add-ADGroupMember -Identity LinuxAdmins -Members testuser
```

### Step 3: Verify group membership on Linux
```
groups testuser
```
If not visible → wait for SSSD cache refresh or run:
```
sss_cache -E
```

### Step 4: Create sudoers rule
```
echo '%LinuxAdmins ALL=(ALL) ALL' > /etc/sudoers.d/linux-admins
chmod 440 /etc/sudoers.d/linux-admins
```

### Step 5: Test sudo
```
sudo -l -U testuser
```

If everything correct → sudo works.

---

<br>
<br>

# 8. Real-world failure scenarios (and exact fixes)

## Scenario 1: AD user cannot sudo but is in group

Check actual group list on Linux:
```
id testuser
```
If Linux does not show the group → SSSD never resolved it.

Debug:
```
sssctl user-show testuser
sssctl domain-status
```

Fix DNS or SSSD.

---

<br>
<br>

## Scenario 2: Group resolves but sudo still denies

Check sudo rules:
```
sudo -l -U testuser
```
Check sudoers syntax:
```
visudo -c
```

---

<br>
<br>

## Scenario 3: FQDN group mismatch

Check exact group name:
```
getent group LinuxAdmins
```
If result is:
```
LinuxAdmins@gohel.local
```
Then sudoers must use:
```
%LinuxAdmins@gohel.local ALL=(ALL) ALL
```

---

<br>
<br>

## Scenario 4: user recently added to AD group but Linux doesn’t see it
Because SSSD caches group entries.

Fix:
```
sss_cache -E
systemctl restart sssd
```

---

<br>
<br>

## Scenario 5: sudo extremely slow
Typically caused by SSSD trying unreachable DCs.

Fix:
```
sssctl domain-status
```
Update DNS or remove dead DCs.

---

<br>
<br>

# 9. Security best practices

- NEVER edit `/etc/sudoers` directly
- Use `/etc/sudoers.d/` with descriptive filenames
- Validate syntax on every edit:
```
visudo -cf /etc/sudoers.d/linux-admins
```
- Avoid wildcard ALL privileges unless required
- Use least-privilege model
- Combine sudo rules with AD group design

---

<br>
<br>

# 10. Summary — how AD group–based sudo works

```
1. Linux resolves AD user using SSSD
2. Linux resolves AD group using SSSD
3. User must appear in group membership list
4. sudoers must reference EXACT group name
5. SSSD must be online to evaluate group access
6. sudo checks rules → grants/refuses access
```

If any part fails, sudo fails.

---

<br>
<br>

# What you achieve after this file

You can now:
- assign sudo rights using AD groups
- debug sudo + SSSD integration
- test sudo access without logging in as the user
- identify and fix common privilege escalation issues in AD-integrated Linux systems

This is mandatory knowledge for enterprise Linux administration.