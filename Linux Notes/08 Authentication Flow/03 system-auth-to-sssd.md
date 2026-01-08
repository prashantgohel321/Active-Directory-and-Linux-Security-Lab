# system-auth-to-sssd.md

This file explains the **exact moment** the authentication flow leaves PAM’s `system-auth` stack and enters **SSSD**, which then performs:
- AD identity lookup
- Kerberos password validation
- group enumeration
- access control evaluation

If ANY part of this chain breaks, AD authentication fails — even if SSH, PAM, and other configs are perfect.

This file is purely practical and focuses on what actually happens inside the system, what commands show each transition, and how to troubleshoot each stage.

---

- [system-auth-to-sssd.md](#system-auth-to-sssdmd)
- [1. Where system-auth calls SSSD](#1-where-system-auth-calls-sssd)
- [2. What pam\_sss actually does](#2-what-pam_sss-actually-does)
- [3. What SSSD does when contacted by PAM](#3-what-sssd-does-when-contacted-by-pam)
  - [Step 1 — Check SSSD online/offline state](#step-1--check-sssd-onlineoffline-state)
  - [Step 2 — Identity lookup](#step-2--identity-lookup)
  - [Step 3 — Kerberos authentication](#step-3--kerberos-authentication)
  - [Step 4 — Group enumeration](#step-4--group-enumeration)
  - [Step 5 — Access control evaluation](#step-5--access-control-evaluation)
  - [Step 6 — Return status to pam\_sss](#step-6--return-status-to-pam_sss)
- [4. Logs that show system-auth → SSSD flow happening](#4-logs-that-show-system-auth--sssd-flow-happening)
- [5. The exact conditions required for system-auth → SSSD to work](#5-the-exact-conditions-required-for-system-auth--sssd-to-work)
- [6. Real-world failure scenarios (and exact diagnosis steps)](#6-real-world-failure-scenarios-and-exact-diagnosis-steps)
  - [Scenario 1 — Password always wrong for AD users](#scenario-1--password-always-wrong-for-ad-users)
  - [Scenario 2 — `id username` works but login fails](#scenario-2--id-username-works-but-login-fails)
  - [Scenario 3 — Authentication succeeds but login is extremely slow](#scenario-3--authentication-succeeds-but-login-is-extremely-slow)
  - [Scenario 4 — su works but SSH doesn’t](#scenario-4--su-works-but-ssh-doesnt)
  - [Scenario 5 — SSSD not responding to PAM at all](#scenario-5--sssd-not-responding-to-pam-at-all)
- [7. How to test system-auth → SSSD without involving SSH](#7-how-to-test-system-auth--sssd-without-involving-ssh)
    - [Method 1 — su test](#method-1--su-test)
    - [Method 2 — pamtester](#method-2--pamtester)
    - [Method 3 — direct Kerberos test](#method-3--direct-kerberos-test)
    - [Method 4 — direct identity lookup](#method-4--direct-identity-lookup)
- [8. How PAM receives the final response from SSSD](#8-how-pam-receives-the-final-response-from-sssd)
- [9. Summary of system-auth → SSSD transition](#9-summary-of-system-auth--sssd-transition)
- [What you achieve after this file](#what-you-achieve-after-this-file)


<br>
<br>

# 1. Where system-auth calls SSSD

Inside `system-auth`, the line that triggers AD authentication is:
```bash
auth   sufficient   pam_sss.so use_first_pass
```
This is the **handoff point**.

Meaning:
1. PAM reads the username and password.
2. Passes that password to pam_sss.
3. pam_sss hands credentials to **SSSD**.
4. SSSD decides whether to authenticate or deny.

If pam_sss is missing, misordered, or incorrectly flagged, **SSSD is never called**, and AD login will always fail.

Check:
```bash
grep pam_sss /etc/pam.d/system-auth
```
Expect lines in AUTH, ACCOUNT, and SESSION phases.

---

<br>
<br>

# 2. What pam_sss actually does

pam_sss is just a connector. It does NOT authenticate anything by itself.
It sends the request to sssd over `/var/lib/sss/pipes/pam`.

When pam_sss is triggered:
1. PAM sends username + password to pam_sss.
2. pam_sss packages this into an internal SSSD request.
3. The request is sent to the **pam responder** inside SSSD.
4. SSSD returns success or failure.

If this pipe is broken or SSSD is dead:
```bash
pam_sss(sshd:auth): Request to sssd failed. No such file or directory
``` 
AD login will fail instantly.

---

<br>
<br>

# 3. What SSSD does when contacted by PAM

Once pam_sss sends credentials, SSSD performs this exact sequence:

## Step 1 — Check SSSD online/offline state
```bash
sssctl domain-status
```
If offline:
- DNS broken
- AD unreachable
- Kerberos errors

You will see:
```bash
Offline status: ONLINE: no
```

## Step 2 — Identity lookup
SSSD checks if the username exists in AD.

Debug:
```bash
sssctl user-show username
```
If not found → PAM fails with "user unknown".

## Step 3 — Kerberos authentication
SSSD takes the password and runs Kerberos AS-REQ (Authentication Service Request) to DC:
```bash
kinit username
```
This mimics SSSD’s internal Kerberos process.

Common failures:
- time skew → `KRB5KRB_AP_ERR_SKEW`
- DNS issues → cannot contact KDC
- wrong password → `Preauthentication failed`

## Step 4 — Group enumeration
SSSD requests LDAP groups.
```bash
groups username
```
If group resolution is slow, login is slow.

## Step 5 — Access control evaluation
SSSD evaluates:
- ad_access_filter
- simple_allow_users
- simple_allow_groups
- simple_deny_users
- simple_deny_groups

Debug:
```bash
tail -f /var/log/sssd/sssd_pam.log
```
Look for:
```bash
Access denied for user
```

## Step 6 — Return status to pam_sss
SSSD sends:
- success → PAM AUTH phase succeeds
- failure → PAM moves to pam_deny or exits early

---

<br>
<br>

# 4. Logs that show system-auth → SSSD flow happening

To observe this live, open two terminals.

Terminal 1:
```bash
tail -f /var/log/secure /var/log/sssd/sssd_pam.log
```
Terminal 2:
```bash
su - username
ssh username@server
```

Expected log pattern:
```bash
pam_sss(sshd:auth): authentication test
SSSD debug: performing online identity request
SSSD debug: kerberos auth start
SSSD debug: access check allow
```

If you see nothing in SSSD logs → pam_sss isn't being called.

This means:
- system-auth broken
- password-auth broken
- wrong ordering
- pam_deny above pam_sss

---

<br>
<br>

# 5. The exact conditions required for system-auth → SSSD to work

SSSD must be able to:
1. Resolve domain controllers via DNS
```bash
host -t SRV _kerberos._tcp.gohel.local
```

2. Contact KDC
```bash
kinit username
```

3. Resolve identity
```bash
id username
```

4. Retrieve groups
```bash
groups username
```

If ANY of these fail, pam_sss will return error to PAM.

---

<br>
<br>

# 6. Real-world failure scenarios (and exact diagnosis steps)

## Scenario 1 — Password always wrong for AD users
Check if Kerberos works:
```
kinit username
```
If this fails → **not PAM**, not SSSD — it is Kerberos.

Fix time sync or DNS.

---

## Scenario 2 — `id username` works but login fails
Means identity lookup is fine, but access or password is being blocked.

Check ACCOUNT phase:
```bash
tail -f /var/log/sssd/sssd_pam.log
```
Look for:
```bash
Access denied
```

Check SSSD access filter:
```bash
grep access_provider /etc/sssd/sssd.conf
```

---

## Scenario 3 — Authentication succeeds but login is extremely slow
Cause:
- slow LDAP group enumeration
- unreachable DCs in the site
- group nesting depth large

Check SSSD performance:
```bash
sssctl domain-status
```
Look for:
```bash
Online: no (timeout)
```

---

## Scenario 4 — su works but SSH doesn’t
Likely cause:
- system-auth correct
- password-auth incorrect

Fix:
```bash
diff /etc/pam.d/system-auth /etc/pam.d/password-auth
```

---

## Scenario 5 — SSSD not responding to PAM at all
Check SSSD service:
```bash
systemctl status sssd
```
Check for socket errors:
```bash
ls -l /var/lib/sss/pipes/
```
Expect pipes like:
```bash
pam
nss
```
If missing → reinstall SSSD or fix permissions.

---

<br>
<br>

# 7. How to test system-auth → SSSD without involving SSH

### Method 1 — su test
```bash
su - username
```
If AD login works → system-auth → SSSD is functioning.

### Method 2 — pamtester
```bash
pamtester login username authenticate
```

### Method 3 — direct Kerberos test
```bash
kinit username
```
This verifies the credentials path that SSSD also uses.

### Method 4 — direct identity lookup
```bash
id username
sssctl user-show username
```

---

<br>
<br>

# 8. How PAM receives the final response from SSSD

After finishing checks, SSSD returns a value from:
- PAM_SUCCESS
- PAM_AUTH_ERR
- PAM_USER_UNKNOWN
- PAM_MAXTRIES
- PAM_ACCT_EXPIRED
- PAM_PERM_DENIED

PAM then:
- continues to next module
- stops stack execution
- or calls pam_deny

SSH sees only a generic "Permission denied", which is why **SSSD logs are mandatory**.

---

<br>
<br>

# 9. Summary of system-auth → SSSD transition

```bash
Service (SSH or su)
     ↓
PAM (service file)
     ↓
password-auth (if SSH)
     ↓
system-auth
     ↓
pam_sss.so
     ↓
SSSD (pam responder)
     ↓
Kerberos + LDAP
     ↓
Access rules
     ↓
Return success/failure to PAM
```

This is the real backend of AD authentication.

---

<br>
<br>

# What you achieve after this file

You now understand the **precise, internal transition** point where PAM delegates authentication to SSSD. You can:
- isolate where authentication failures occur
- distinguish PAM issues from SSSD or Kerberos issues
- debug identity, password, access, and group problems systematically
- read the logs that show the exact failure point

This is the most important part of the entire authentication flow, and mastering it makes you effective at diagnosing 99% of AD login failures on Linux.