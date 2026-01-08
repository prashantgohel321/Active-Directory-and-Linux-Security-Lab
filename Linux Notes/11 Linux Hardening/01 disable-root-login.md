# disable-root-login.md

- This file explains **exact, practical, production-safe methods to disable root login on Linux**.  
- Root login is one of the biggest attack surfaces on any Linux system. Disabling it forces all administrators to authenticate using individual accounts and elevate using sudo. This increases accountability, forensics quality, and reduces brute-force exposure.

- This document covers:
  - all technical methods to disable root login
  - correct order of applying them
  - what each method protects against
  - testing steps
  - rollback and recovery procedures


---

<br>
<br>

- [disable-root-login.md](#disable-root-loginmd)
- [1. Why disable root login](#1-why-disable-root-login)
- [2. Disable root login through SSH (primary method)](#2-disable-root-login-through-ssh-primary-method)
  - [Step 1 — Edit sshd\_config](#step-1--edit-sshd_config)
  - [Step 2 — Validate config](#step-2--validate-config)
  - [Step 3 — Reload SSHD](#step-3--reload-sshd)
  - [Step 4 — Test](#step-4--test)
- [3. Disable root password (lock root account)](#3-disable-root-password-lock-root-account)
- [4. Disable root login using PAM (stronger, deeper control)](#4-disable-root-login-using-pam-stronger-deeper-control)
- [5. Restrict `su` so users cannot become root](#5-restrict-su-so-users-cannot-become-root)
- [6. Force all admins to use sudo instead](#6-force-all-admins-to-use-sudo-instead)
- [7. Optional: Disable root TTY access (console lock)](#7-optional-disable-root-tty-access-console-lock)
- [8. Optional: MFA before privilege escalation (very strong security)](#8-optional-mfa-before-privilege-escalation-very-strong-security)
- [9. Testing checklist](#9-testing-checklist)
- [10. Rollback steps (if you get locked out)](#10-rollback-steps-if-you-get-locked-out)
  - [SSHD rollback](#sshd-rollback)
  - [PAM rollback](#pam-rollback)
  - [Unlock root password](#unlock-root-password)
- [11. Common failure scenarios and fixes](#11-common-failure-scenarios-and-fixes)
    - [1. Root login still works after changes](#1-root-login-still-works-after-changes)
    - [2. Sudo stopped working for admins](#2-sudo-stopped-working-for-admins)
    - [3. `pam_succeed_if` denies legitimate root actions](#3-pam_succeed_if-denies-legitimate-root-actions)
    - [4. AD group not recognized in sudoers](#4-ad-group-not-recognized-in-sudoers)
- [12. Minimal recommended hardening combo](#12-minimal-recommended-hardening-combo)
- [What you achieve after this file](#what-you-achieve-after-this-file)


---

<br>
<br>

# 1. Why disable root login

- Direct root login means:
  - no audit trail (impossible to know WHO used root)
  - attackers can brute-force one account (root)
  - misconfiguration can allow passwordless root abuse
  - automation or scripts may be dangerously tied to root SSH

- Industry best practice is:
  - disable root SSH entirely
  - restrict local root use to sudo only
  - use MFA for escalation if possible

---

<br>
<br>

# 2. Disable root login through SSH (primary method)

- OpenSSH supports `PermitRootLogin` directive to control root login behavior.

## Step 1 — Edit sshd_config

```bash
cp /etc/ssh/sshd_config /root/sshd_config.bak-$(date +%F-%T)
```

Modify or append:

```bash
PermitRootLogin no
```

- This blocks ALL root login methods, including:
  - password
  - public key
  - keyboard-interactive

- You can also use more granular options:

```bash
PermitRootLogin prohibit-password  # allow only key-based root login
PermitRootLogin without-password   # older equivalent
```

## Step 2 — Validate config

```bash
sshd -t
```

If no output, configuration is valid.

## Step 3 — Reload SSHD

```bash
systemctl reload sshd
```

## Step 4 — Test

- Open a **new terminal** (keeping current session active):

```bash
ssh root@server
```
You should get:
```bash
Access denied
```

---

# 3. Disable root password (lock root account)

- Even if SSH is blocked, the root password still exists. Locking it adds another layer of protection.

```bash
passwd -l root
```

- This prepends `!` to the password hash in `/etc/shadow`, making password auth impossible.

Verify:
```bash
sudo grep '^root' /etc/shadow
```
Should show:
```bash
root:!...
```

Unlock if needed:
```bash
passwd -u root
```

**Note:** Locking root password does NOT prevent:
- root login using SSH keys (if PermitRootLogin allows it)
- root login from console (if PAM allows it)
- sudo escalation from users

---

<br>
<br>

# 4. Disable root login using PAM (stronger, deeper control)

PAM controls authentication for many services.  
To block root at PAM level:

Edit one of these depending on scope:
- `/etc/pam.d/sshd` (SSH only)
- `/etc/pam.d/login` (console login)
- `/etc/pam.d/system-auth` (global)

Add at the TOP of the `auth` section:

```
auth requisite pam_succeed_if.so uid != 0
```

Explanation:
- `uid != 0` means: fail if the user is root
- `requisite` stops the stack immediately

Test carefully — this can block all root access including console.

Safer variant (SSH only):

```bash
# In /etc/pam.d/sshd
auth [success=1 default=ignore] pam_succeed_if.so uid != 0
auth requisite pam_deny.so
```

This only denies root in SSH, not globally.

---

<br>
<br>

# 5. Restrict `su` so users cannot become root

Disable `su` unless user is in wheel (or an AD admin group).

Edit `/etc/pam.d/su`:

```bash`
auth required pam_wheel.so use_uid
```

Add valid admin user or AD admin group to wheel:

```bash
gpasswd -a adminuser wheel
# or for AD group
gpasswd -a 'LinuxAdmins@GOHEL.LOCAL' wheel
```

Test:
```bash
su -   # should fail for non-wheel users
```

---

<br>
<br>

# 6. Force all admins to use sudo instead

Create `/etc/sudoers.d/admins`:

```bash
%LinuxAdmins ALL=(ALL) ALL
```

Test:
```bash
sudo -l
sudo -i
```

This ensures:
- every privileged command is logged
- admins authenticate individually

---

<br>
<br>

# 7. Optional: Disable root TTY access (console lock)

Edit `/etc/securetty` and remove all contents:

```
>/etc/securetty
```

This blocks root from logging in on TTY consoles.

Risk:  
If you break sudo and lock root console, you may lock yourself out completely.

Use only if you have reliable out-of-band console access (VMware, iDRAC, etc.).

---

# 8. Optional: MFA before privilege escalation (very strong security)

Adding MFA (TOTP / Google Authenticator) for sudo or SSH.

Example for sudo in `/etc/pam.d/sudo`:

```
auth required pam_google_authenticator.so nullok
```

Then regular sudo stack continues.

Test:
```bash
sudo -i
```

---

# 9. Testing checklist

Before applying ANY hardening:
1. Ensure you have at least one user with sudo.
2. Ensure sudoers entry works:
```bash
sudo -l
```
3. Start a persistent SSH session.
4. Apply root restrictions.
5. Try new SSH session as root — should fail.
6. Try sudo escalation — should work.
7. Try su escalation if configured.

If ANYTHING breaks, revert immediately.

---

# 10. Rollback steps (if you get locked out)

## SSHD rollback
```bash
cp /root/sshd_config.bak-* /etc/ssh/sshd_config
systemctl restart sshd
```

## PAM rollback
```bash
cp /root/sshd.pam.bak-* /etc/pam.d/sshd
systemctl restart sshd
```

## Unlock root password
```bash
passwd -u root
```

If all else fails:  
Use **VMware console** to log in as root and fix configs manually.

---

# 11. Common failure scenarios and fixes

### 1. Root login still works after changes
Check:
```
grep -i PermitRootLogin /etc/ssh/sshd_config
```
Possible reasons:
- Duplicate PermitRootLogin lines
- Wrong file edited
- Missing sshd reload

### 2. Sudo stopped working for admins
Likely sudoers syntax error. Check:
```
visudo -c
```
Fix the sudoers file.

### 3. `pam_succeed_if` denies legitimate root actions
Move PAM rule to SSH-specific file only.

### 4. AD group not recognized in sudoers
Check:
```
getent group LinuxAdmins
id adminuser
```
Fix SSSD if identity resolution fails.

---

# 12. Minimal recommended hardening combo

For almost all environments, use:

1. Disable root SSH:
```
PermitRootLogin no
```
2. Lock root password:
```
passwd -l root
```
3. Restrict su to wheel:
```
auth required pam_wheel.so use_uid
```
4. Sudo for admin group:
```
%LinuxAdmins ALL=(ALL) ALL
```

This gives strong security without risking unnecessary lockouts.

---

# What you achieve after this file

You will:
- fully protect root from direct abuse
- shift all admin operations to audited channels
- understand each hardening layer, how it works, and how to revert
- be able to deploy root restrictions safely across lab and production

This is real, enterprise-grade root-access hardening.