# sssd-kerberos.md

This file explains **exactly what happens when SSSD performs Kerberos authentication** during an AD login attempt. This is the stage after PAM hands credentials to SSSD but before SSSD returns success or failure. If Kerberos fails, AD users *cannot* authenticate, even if identity lookup, DNS, and PAM are perfect.

Everything here is practical: packet flow, real logs, real errors, exact fixes.

---

- [sssd-kerberos.md](#sssd-kerberosmd)
- [1. Where Kerberos fits in the full authentication chain](#1-where-kerberos-fits-in-the-full-authentication-chain)
- [2. What happens inside SSSD when Kerberos starts](#2-what-happens-inside-sssd-when-kerberos-starts)
- [3. The Kerberos configuration SSSD depends on](#3-the-kerberos-configuration-sssd-depends-on)
- [4. DNS requirements for Kerberos to work](#4-dns-requirements-for-kerberos-to-work)
- [5. Time synchronization requirement (+/- 5 min max)](#5-time-synchronization-requirement---5-min-max)
- [6. Real SSSD Kerberos flow (internal sequence)](#6-real-sssd-kerberos-flow-internal-sequence)
    - [Step 1 — Identity lookup](#step-1--identity-lookup)
    - [Step 2 — Start Kerberos AS-REQ](#step-2--start-kerberos-as-req)
    - [Step 3 — Preauth](#step-3--preauth)
    - [Step 4 — Ticket validation](#step-4--ticket-validation)
    - [Step 5 — Access phase](#step-5--access-phase)
- [7. SSSD logs for Kerberos (MOST important)](#7-sssd-logs-for-kerberos-most-important)
- [8. Common Kerberos failure cases and exact fixes](#8-common-kerberos-failure-cases-and-exact-fixes)
  - [Case 1 — Wrong password but logs look fine](#case-1--wrong-password-but-logs-look-fine)
  - [Case 2 — DNS broken](#case-2--dns-broken)
  - [Case 3 — Time out of sync](#case-3--time-out-of-sync)
  - [Case 4 — Cross-realm mismatch (common)](#case-4--cross-realm-mismatch-common)
  - [Case 5 — SSSD offline](#case-5--sssd-offline)
  - [Case 6 — Kerberos auth works but login still denied](#case-6--kerberos-auth-works-but-login-still-denied)
- [9. Testing SSSD Kerberos without SSH/PAM](#9-testing-sssd-kerberos-without-sshpam)
    - [Identity test](#identity-test)
    - [Kerberos direct test](#kerberos-direct-test)
    - [SSSD internal test](#sssd-internal-test)
- [10. Full Kerberos-based AD login flow summarized](#10-full-kerberos-based-ad-login-flow-summarized)
- [What you achieve after this file](#what-you-achieve-after-this-file)


<br>
<br>

# 1. Where Kerberos fits in the full authentication chain

Authentication flow up to this point:
```bash
SSH → PAM (sshd) → password-auth → system-auth → pam_sss.so → SSSD
```
Now SSSD must verify the password.

Kerberos handles this step.

SSSD does NOT check AD passwords using LDAP binds. It always uses Kerberos (kinit) unless configured otherwise.

---

<br>
<br>

# 2. What happens inside SSSD when Kerberos starts

When pam_sss sends credentials:
1. SSSD receives the username + password
2. SSSD determines the Kerberos realm from the domain
3. SSSD reads the kerberos config:
   `/etc/krb5.conf`
4. SSSD locates KDC servers using DNS SRV records:
```bash
host -t SRV _kerberos._tcp.gohel.local
```
5. SSSD sends AS-REQ (Authentication Service Request) to the KDC
6. KDC verifies password and sends AS-REP back
7. If successful, SSSD gets a TGT (Ticket-Granting Ticket)
8. SSSD returns **PAM_SUCCESS** to pam_sss

If any step breaks → Kerberos authentication fails.

---

<br>
<br>

# 3. The Kerberos configuration SSSD depends on

Key parts of `/etc/krb5.conf` must exist:
```bash
[libdefaults]
  default_realm = GOHEL.LOCAL
  dns_lookup_realm = true
  dns_lookup_kdc = true
  rdns = false

[realms]
  GOHEL.LOCAL = {
    kdc = dc01.gohel.local
    kdc = dc02.gohel.local
  }
```

If the realm or KDC entries are wrong, SSSD cannot authenticate.

Test immediately:
```bash
kinit username
klist
```
If kinit fails, SSSD authentication WILL fail.

---

<br>
<br>

# 4. DNS requirements for Kerberos to work

SSSD uses DNS to discover AD servers.

Check SRV records:
```bash
host -t SRV _kerberos._tcp.gohel.local
host -t SRV _ldap._tcp.gohel.local
```
You **must** get valid results.

If DNS fails:
- Kerberos cannot locate KDC
- SSSD enters offline mode
- logins fail

See state:
```bash
sssctl domain-status
```
Look for:
```bash
Online status: FALSE
```

---

<br>
<br>

# 5. Time synchronization requirement (+/- 5 min max)

Kerberos WILL NOT authenticate if time is off.

Check time sync:
```bash
chronyc tracking
```
If offset > 2 seconds → fix it.

If time skew occurs:
```bash
kinit: Clock skew too great
```
SSSD logs will contain:
```
KRB5KRB_AP_ERR_SKEW
```

Fix:
- configure chrony to point to the AD DC
- restart chronyd

---

<br>
<br>

# 6. Real SSSD Kerberos flow (internal sequence)

### Step 1 — Identity lookup
```bash
sssctl user-show username
```
If identity not found → Kerberos not attempted.

### Step 2 — Start Kerberos AS-REQ
SSSD internally calls the Kerberos libraries.

### Step 3 — Preauth
If AD requires preauth, user must provide correct password.

Wrong password example:
```bash
pam_sss(sshd:auth): authentication failed: Preauthentication failed
```

### Step 4 — Ticket validation
SSSD receives TGT.

Check via:
```bash
klist
```

### Step 5 — Access phase
Kerberos success does NOT guarantee login.  
A correct password does NOT guarantee login.  
If access_provider denies the user, login fails:
```bash
pam_sss(sshd:account): Access denied
```

---

<br>
<br>

# 7. SSSD logs for Kerberos (MOST important)

Live debug:
```bash
tail -f /var/log/sssd/sssd_pam.log
```
Look for:
```bash
Kerberos authentication failed
PAM auth failed: Preauthentication failed
No KDC found for realm
Cannot contact any KDC
Access denied for user
```

Also check domain logs:
```bash
tail -f /var/log/sssd/sssd_GOHEL.LOCAL.log
```

---

<br>
<br>

# 8. Common Kerberos failure cases and exact fixes

## Case 1 — Wrong password but logs look fine
SSSD logs show:
```bash
Preauthentication failed
```
Fix: user must provide correct password.

---

## Case 2 — DNS broken
Error:
```bash
Cannot contact any KDC for realm
```
Fix:
```bash
host -t SRV _kerberos._tcp.gohel.local
cat /etc/resolv.conf
```
Ensure AD DNS server is first entry.

---

## Case 3 — Time out of sync
Error:
```bash
KRB5KRB_AP_ERR_SKEW
```
Fix:
```bash
systemctl restart chronyd
chronyc tracking
```

---

## Case 4 — Cross-realm mismatch (common)
Error:
```bash
Cannot find KDC for requested realm
```
Fix `/etc/krb5.conf` REALM spelling.

---

## Case 5 — SSSD offline
Error:
```bash
pam_sss: Authentication is denied for offline user
```
Check:
```bash
sssctl domain-status
systemctl restart sssd
```

---

## Case 6 — Kerberos auth works but login still denied
Kerberos succeeded. Access provider denied.

Check:
```bash
tail -f /var/log/sssd/sssd_pam.log
```
Look for:
```bash
Access denied
```
Fix group membership or access_filter.

---

<br>
<br>

# 9. Testing SSSD Kerberos without SSH/PAM

### Identity test
```bash
id username
```

### Kerberos direct test
```bash
kinit username
klist
```

### SSSD internal test
```bash
sssctl user-show username
sssctl domain-status
```

If kinit fails, Kerberos → SSSD → PAM chain will fail.

---

<br>
<br>

# 10. Full Kerberos-based AD login flow summarized

```bash
SSH
  ↓
PAM (password read)
  ↓
pam_sss.so
  ↓
SSSD pam responder
  ↓
Kerberos AS-REQ to DC
  ↓
Preauthentication challenge
  ↓
Password validated by KDC
  ↓
TGT returned
  ↓
SSSD evaluates AD access rules
  ↓
Success or Access Denied passed back to PAM
```

This is EXACTLY what happens for every AD login.

---

<br>
<br>

# What you achieve after this file

You now understand the full, internal Kerberos authentication path used by SSSD:
- how SSSD calls Kerberos
- how DNS, time, realm, and SRV records impact login
- how to debug real Kerberos errors with real logs
- how to test each stage manually

This is the deepest part of the authentication chain. Mastering this makes you capable of diagnosing **99% of real AD login failures** in Linux environments.
