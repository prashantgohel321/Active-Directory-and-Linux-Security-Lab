# ssh-to-pam.md

This file explains the **first stage of the full authentication flow**: when an SSH connection arrives and sshd hands the request to PAM.

This is not theoretical — it describes exactly what happens inside the system when:
```bash
ssh user@server
```
You will understand which steps occur, which configs are checked, which modules run, and how failures look in logs.

This knowledge is mandatory when troubleshooting SSH, PAM, SSSD, or AD authentication.

---

- [ssh-to-pam.md](#ssh-to-pammd)
- [1. SSH connection arrival → what happens before PAM](#1-ssh-connection-arrival--what-happens-before-pam)
  - [Step 1: sshd receives TCP connection on port 22](#step-1-sshd-receives-tcp-connection-on-port-22)
  - [Step 2: sshd checks sshd\_config](#step-2-sshd-checks-sshd_config)
  - [Step 3: sshd decides authentication method](#step-3-sshd-decides-authentication-method)
- [2. sshd hands control to PAM](#2-sshd-hands-control-to-pam)
- [3. sshd → password-auth → system-auth](#3-sshd--password-auth--system-auth)
- [4. AUTH phase inside password-auth](#4-auth-phase-inside-password-auth)
    - [What each step means](#what-each-step-means)
- [5. What sshd logs during PAM authentication](#5-what-sshd-logs-during-pam-authentication)
- [6. Interaction with SSSD during SSH authentication](#6-interaction-with-sssd-during-ssh-authentication)
- [7. ACCOUNT phase after password is correct](#7-account-phase-after-password-is-correct)
- [8. SESSION phase after successful authentication](#8-session-phase-after-successful-authentication)
- [9. Real-world failure scenarios (and exact fixes)](#9-real-world-failure-scenarios-and-exact-fixes)
  - [Scenario 1: AD users cannot SSH but local users can](#scenario-1-ad-users-cannot-ssh-but-local-users-can)
  - [Scenario 2: su works but SSH fails](#scenario-2-su-works-but-ssh-fails)
  - [Scenario 3: password correct but access denied](#scenario-3-password-correct-but-access-denied)
  - [Scenario 4: long SSH delay before password prompt](#scenario-4-long-ssh-delay-before-password-prompt)
  - [Scenario 5: key login works but password login fails](#scenario-5-key-login-works-but-password-login-fails)
- [10. Debugging ssh → PAM flow in real time](#10-debugging-ssh--pam-flow-in-real-time)
- [11. Summary of SSH → PAM flow](#11-summary-of-ssh--pam-flow)
- [What you achieve after this file](#what-you-achieve-after-this-file)

<br>
<br>

# 1. SSH connection arrival → what happens before PAM

When you run:
```bash
ssh username@server
```
this is what happens on the server **before PAM even starts**.

## Step 1: sshd receives TCP connection on port 22
Service:
```bash
/usr/sbin/sshd
```

Check logs:
```bash
tail -f /var/log/secure | grep sshd
```

## Step 2: sshd checks sshd_config
File:
```bash
/etc/ssh/sshd_config
```
Key directives controlling PAM:
```bash
UsePAM yes
PasswordAuthentication yes
ChallengeResponseAuthentication yes/no
PubkeyAuthentication yes
GSSAPIAuthentication yes/no
```

If **UsePAM no**, then PAM is bypassed completely.
If **PasswordAuthentication no**, sshd will never send the password to PAM.

## Step 3: sshd decides authentication method
SSH has multiple methods:
- public key
- password
- GSSAPI/Kerberos
- keyboard-interactive

Only password and keyboard-interactive methods call PAM.

If the user uses a key:
```bash
ssh -i key.pem user@server
```
PAM AUTH phase is *skipped*, but SESSION phase still runs.

---

<br>
<br>

# 2. sshd hands control to PAM

If password authentication is allowed, sshd calls:
```bash
/etc/pam.d/sshd
```
This is the **entry point for all SSH PAM operations**.

Inside sshd PAM file:
```bash
auth       substack    password-auth
auth       include     postlogin
account    include     password-auth
password   include     password-auth
session    include     password-auth
session    include     postlogin
```

The important part:
```bash
auth substack password-auth
```
This transfers control to the **password-auth** PAM stack.

If this is missing → SSH login will *always* fail.

---

<br>
<br>

# 3. sshd → password-auth → system-auth

The chain looks like this:
```bash
sshd
 ↓
/etc/pam.d/sshd
 ↓
/etc/pam.d/password-auth
 ↓
/etc/pam.d/system-auth (included inside password-auth)
```

Meaning:
- sshd does *not* authenticate users itself
- sshd delegates everything to the PAM stack
- PAM stack delegates AD authentication to SSSD

---

<br>
<br>

# 4. AUTH phase inside password-auth

When sshd sends the password to PAM, the following modules run in this order:

Typical configuration:
```bash
auth required      pam_env.so
auth required      pam_faillock.so preauth silent audit deny=3 unlock_time=900
auth sufficient    pam_unix.so try_first_pass nullok
auth sufficient    pam_sss.so use_first_pass
auth required      pam_faillock.so authfail audit deny=3 unlock_time=900
auth required      pam_deny.so
```

### What each step means
1. `pam_env.so` sets environment
2. `pam_faillock.so preauth` updates fail counters
3. `pam_unix.so` tries local users
4. `pam_sss.so` tries AD users through SSSD
5. `pam_faillock.so authfail` increments failure counter on wrong password
6. `pam_deny.so` fails the request if nothing succeeded

If any module misbehaves → SSH authentication fails.

---

<br>
<br>

# 5. What sshd logs during PAM authentication

Check sshd logs:
```bash
tail -f /var/log/secure | grep sshd
```
You will see messages like:
```bash
sshd[8023]: pam_unix(sshd:auth): authentication failure
sshd[8023]: pam_sss(sshd:auth): received for user <username>:  Authentication failure
sshd[8023]: Failed password for user from 10.x.x.x port 52144 ssh2
```

If password is correct but ACCOUNT phase later denies access, sshd still logs `Failed password` — misleading but expected.

---

<br>
<br>

# 6. Interaction with SSSD during SSH authentication

When `pam_sss.so` is called, SSSD performs:

1. identity lookup  
2. password verification (Kerberos)  
3. group enumeration  
4. access control evaluation (ad_access_filter)  


Check SSSD logs:
```bash
tail -f /var/log/sssd/sssd_pam.log
```

Possible log entries:
```bash
Access denied for user (group mismatch)
PAM auth failed: invalid password
No such user found in domain
Offline authentication failed
```

If SSSD logs show nothing during SSH login → PAM is not calling pam_sss → wrong ordering in password-auth.

---

<br>
<br>

# 7. ACCOUNT phase after password is correct

Even if the password is correct, SSH login can still fail during ACCOUNT phase:

```bash
account include password-auth
```

Common causes:
- AD account disabled
- AD access filter rejecting user
- login hours restricted
- expired local account

Check logs:
```bash
tail -f /var/log/secure
```
Look for:
```bash
pam_sss(sshd:account): Access denied
```

---

<br>
<br>

# 8. SESSION phase after successful authentication

If authentication + account checks succeed, sshd runs session modules:
```bash
session include password-auth
session include postlogin
```

This handles:
- pam_limits (ulimits)
- pam_mkhomedir (home auto-create)
- environment setup

If a user logs in successfully but receives:
```bash
Could not chdir to home directory
```
this is a SESSION phase failure.

Check:
```bash
systemctl status oddjobd
```

---

<br>
<br>

# 9. Real-world failure scenarios (and exact fixes)

## Scenario 1: AD users cannot SSH but local users can
Cause:
- pam_sss missing in password-auth
Fix:
```bash
auth sufficient pam_sss.so use_first_pass
```

---

## Scenario 2: su works but SSH fails
Cause:
- system-auth OK
- password-auth broken
Fix:
```bash
diff /etc/pam.d/system-auth /etc/pam.d/password-auth
```

---

## Scenario 3: password correct but access denied
Cause:
- account phase blocked by access filter
Check:
```bash
tail -f /var/log/sssd/sssd_pam.log
```

---

## Scenario 4: long SSH delay before password prompt
Cause:
- DNS SRV lookup delay
Fix DNS.

---

## Scenario 5: key login works but password login fails
Cause:
- PasswordAuthentication no
Fix:
```bash
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
```

---

<br>
<br>

# 10. Debugging ssh → PAM flow in real time

Open 2 terminals.

Terminal 1:
```bash
tail -f /var/log/secure /var/log/sssd/sssd_pam.log
```

Terminal 2:
```bash
ssh -vvv user@server
```

Look for:
- which PAM module failed  
- whether pam_sss was called  
- failcount  
- access-denied messages  


---

<br>
<br>

# 11. Summary of SSH → PAM flow

```bash
SSH client
   ↓
TCP connection to sshd
   ↓
sshd checks sshd_config (UsePAM, PasswordAuth)
   ↓
sshd loads /etc/pam.d/sshd
   ↓
AUTH phase (password-auth → system-auth)
   ↓
pam_unix & pam_sss verify credentials
   ↓
ACCOUNT phase checks access
   ↓
SESSION phase sets environment, limits, home
   ↓
User login successful
```

This is the complete first half of the full authentication pipeline.

---

# What you achieve after this file

You now understand exactly:
- how sshd decides to use PAM
- how the password flows into the PAM stack
- how PAM calls SSSD for AD authentication
- how each PAM phase affects SSH login
- how to debug failures at each stage

This file prepares you for the next step: **PAM → system-auth** in the overall authentication chain.