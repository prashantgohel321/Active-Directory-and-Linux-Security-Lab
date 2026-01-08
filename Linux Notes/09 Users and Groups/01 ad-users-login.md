# ad-users-login.md

This file explains **exactly how AD users log into a Linux system**, what components participate, what conditions must be met, what commands confirm each step, and what breaks when something is misconfigured.

This is 100% practical:  
- how AD users are recognized  
- how authentication happens  
- how session setup works  
- how to debug when AD logins fail

This file assumes your Linux system is already joined to AD using SSSD + realmd.

---

- [ad-users-login.md](#ad-users-loginmd)
- [1. Requirements for AD user login to work](#1-requirements-for-ad-user-login-to-work)
- [2. How AD user login works (step-by-step)](#2-how-ad-user-login-works-step-by-step)
- [3. How Linux identifies an AD user](#3-how-linux-identifies-an-ad-user)
- [4. How password authentication works for AD users](#4-how-password-authentication-works-for-ad-users)
- [5. How group membership affects login](#5-how-group-membership-affects-login)
    - [Group-based access restrictions](#group-based-access-restrictions)
- [6. What domain format users can use to log in](#6-what-domain-format-users-can-use-to-log-in)
    - [1. `username`](#1-username)
    - [2. suffix formats](#2-suffix-formats)
- [7. Home directory creation for AD users](#7-home-directory-creation-for-ad-users)
- [8. testing AD login end-to-end](#8-testing-ad-login-end-to-end)
    - [Test identity lookup](#test-identity-lookup)
    - [Test Kerberos authentication](#test-kerberos-authentication)
    - [Test SSSD communication](#test-sssd-communication)
    - [Test PAM login](#test-pam-login)
    - [Test SSH login](#test-ssh-login)
- [9. Real-world failure scenarios (and exact fixes)](#9-real-world-failure-scenarios-and-exact-fixes)
  - [Scenario 1 — AD user exists but login fails](#scenario-1--ad-user-exists-but-login-fails)
  - [Scenario 2 — "Permission denied" even with correct password](#scenario-2--permission-denied-even-with-correct-password)
  - [Scenario 3 — AD user login extremely slow](#scenario-3--ad-user-login-extremely-slow)
  - [Scenario 4 — AD user login works on console but not SSH](#scenario-4--ad-user-login-works-on-console-but-not-ssh)
  - [Scenario 5 — AD users can log in but have wrong UID/GID](#scenario-5--ad-users-can-log-in-but-have-wrong-uidgid)
- [10. How to verify login policies applied from AD](#10-how-to-verify-login-policies-applied-from-ad)
- [11. Summary — what must work for AD users to log in](#11-summary--what-must-work-for-ad-users-to-log-in)
- [What you achieve after this file](#what-you-achieve-after-this-file)


<br>
<br>

# 1. Requirements for AD user login to work

AD login depends on FOUR systems working correctly at the same time:

1. **DNS** must resolve DCs
2. **Kerberos** must authenticate passwords
3. **SSSD** must provide identity, group memberships, and access rules
4. **PAM** must be configured to use pam_sss

If ANY of these are broken → AD login fails.

Use this checklist:
```bash
host -t SRV _kerberos._tcp.gohel.local
kinit username
id username
sssctl domain-status
```

If *all four* work, AD login will succeed.

---

<br>
<br>

# 2. How AD user login works (step-by-step)

Example login:
```bash
ssh testuser@server
```

The real sequence behind this is:

```bash
SSH → PAM → system-auth → pam_sss → SSSD → Kerberos → LDAP → Access rules → PAM session → Shell
```

This file focuses on the part directly related to AD users.

---

<br>
<br>

# 3. How Linux identifies an AD user

SSSD changes how Linux resolves accounts.  
The command:
```bash
id testuser
```
should return something like:
```bash
uid=123456789(testuser) gid=123456789(domain users) groups=...
```
This means:
- SSSD successfully looked up the user in AD
- SSSD fetched the UID/GID mapping
- SSSD fetched group memberships

If `id` returns:
```bash
id: 'testuser': no such user
```
AD login **cannot** work.  
Identity lookup must succeed *before* password authentication.

To debug:
```bash
sssctl user-show testuser
tail -f /var/log/sssd/sssd_*.log
```

---

<br>
<br>

# 4. How password authentication works for AD users

Once identity lookup succeeds, PAM calls SSSD through `pam_sss.so`.

sssd performs Kerberos authentication using the password.

Manually test:
```bash
kinit testuser
```
If this fails, AD login fails.

Common Kerberos errors:
- DNS wrong → cannot locate KDC
- time skew → Clock skew too great
- wrong realm → Cannot find KDC
- wrong password → Preauthentication failed

Logs:
```bash
tail -f /var/log/sssd/sssd_pam.log
```

---

<br>
<br>

# 5. How group membership affects login

Linux does not check AD groups directly.  
SSSD does the lookup and provides groups to PAM.

Check groups:
```bash
groups testuser
```
If this outputs nothing → SSSD group lookup is failing.

### Group-based access restrictions
You may restrict AD user logins using:
```bash
access_provider = simple
simple_allow_groups = LinuxUsers
```
Or using AD LDAP filters:
```bash
ad_access_filter = (memberOf=CN=LinuxUsers,OU=Groups,DC=gohel,DC=local)
```

If the user is not in allowed groups, login fails with:
```bash
pam_sss(sshd:account): Access denied for user
```

---

<br>
<br>

# 6. What domain format users can use to log in

Linux accepts several username formats:

### 1. `username`
Most common. Works when:
```bash
default_domain_suffix = gohel.local
```
is set in `sssd.conf`.

### 2.<DOMAIN> suffix formats
```bash
username@gohel.local
GOHEL\\username
```
All depend on:
```bash
use_fully_qualified_names = False/True
```

If set to `True`, only FQN format works.

Check:
```bash
grep use_fully_qualified /etc/sssd/sssd.conf
```

---

<br>
<br>

# 7. Home directory creation for AD users

AD users do NOT have local home directories until they log in.

Automatically create home directory:
```bash
session required pam_mkhomedir.so skel=/etc/skel/ umask=0077
```
Service required:
```bash
systemctl enable --now oddjobd
```

If missing, user logs in but gets:
```bash
Could not chdir to home directory
``` 
Fix by enabling `pam_mkhomedir`.

---

<br>
<br>

# 8. testing AD login end-to-end

### Test identity lookup
```bash
id testuser
```
### Test Kerberos authentication
```bash
kinit testuser
klist
```
### Test SSSD communication
```bash
sssctl domain-status
sssctl user-show testuser
```
### Test PAM login
```bash
pamtester sshd testuser authenticate
```
### Test SSH login
```bash
ssh -vvv testuser@server
```

---

<br>
<br>

# 9. Real-world failure scenarios (and exact fixes)

## Scenario 1 — AD user exists but login fails
Error:
```bash
pam_sss(sshd:account): Access denied
```
Fix:
- check SSSD access rules
- check group membership in AD
- check ad_access_filter in `sssd.conf`

---

## Scenario 2 — "Permission denied" even with correct password
Check Kerberos:
```bash
kinit testuser
```
If this fails, fix DNS or time sync.

---

## Scenario 3 — AD user login extremely slow
Causes:
- slow LDAP queries
- unreachable DC
- SSSD waiting for timeout on bad DC

Check:
```bash
sssctl domain-status
```

---

## Scenario 4 — AD user login works on console but not SSH
Cause: `password-auth` broken.

Fix:
```bash
diff /etc/pam.d/system-auth /etc/pam.d/password-auth
```

---

## Scenario 5 — AD users can log in but have wrong UID/GID
Fix mapping provider:
```bash
id_provider = ad
ldap_id_mapping = True
```

If mapping changes after users exist → inconsistent UID → fix manually.

---

# 10. How to verify login policies applied from AD

SSSD respects:
- disabled accounts  
- locked accounts  
- expired passwords  
- login hours (time-of-day restrictions)

Test with:
```bash
sssctl user-show testuser
```
Look for:
```bash
accountExpires
userAccountControl
logonHours
```

If restricted → login denied.

---

<br>
<br>

# 11. Summary — what must work for AD users to log in

```bash
1. DNS resolves domain and DCs
2. SSSD can find the user in AD
3. Kerberos validates the password
4. LDAP returns group memberships
5. SSSD access rules allow login
6. PAM processes SSSD result correctly
7. Session modules create home dir and limits
```

If any step breaks, AD login fails.  
This file ensures you know exactly where and how to test each one.

---

<br>
<br>

# What you achieve after this file

After reading this file you can:
- test AD login pipeline end-to-end  
- diagnose identity, Kerberos, LDAP, or access issues  
- understand how groups affect login  
- control which AD users can log in  
- troubleshoot common and uncommon AD login errors

This file prepares you for deeper work in group policies, sudo rules, and access controls for enterprise environments.