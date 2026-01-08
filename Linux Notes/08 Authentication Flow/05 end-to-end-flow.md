# end-to-end-flow.md

This file gives you the **complete, end‑to‑end authentication flow** from the moment an SSH connection hits the Linux server until the user gets a shell.  
This combines everything you learned so far into a single, continuous chain with exact decision points, logs, failure scenarios, and practical debugging checkpoints.

This is the file you will come back to every time an AD login fails.  
It gives you the **entire story in one place**.

---

# 1. Full authentication flow (high‑level map)

```
SSH client → sshd → PAM (sshd) → password-auth → system-auth → pam_sss → SSSD → Kerberos → LDAP groups → Access control → PAM session → Shell
```

Every failure in AD authentication occurs in **one** of these stages.  
This file shows how to identify exactly which stage is failing.

---

# 2. Step 1 — SSH client connects to sshd

Client runs:
```
ssh user@server
```

Server receives TCP connection on port 22.  
sshd starts processing and loads **/etc/ssh/sshd_config**.

Key directives that affect authentication:
```
UsePAM yes
PasswordAuthentication yes
ChallengeResponseAuthentication yes/no
PubkeyAuthentication yes
GSSAPIAuthentication yes/no
```

If `UsePAM no`, PAM is bypassed entirely → AD password login impossible.  
If `PasswordAuthentication no`, sshd never contacts PAM.

Logs:
```
tail -f /var/log/secure
```

---

# 3. Step 2 — sshd hands control to PAM

sshd now loads:
```
/etc/pam.d/sshd
```

Typical lines:
```
auth       substack     password-auth
account    include       password-auth
password   include       password-auth
session    include       password-auth
session    include       postlogin
```

`substack password-auth` means sshd defers all work to another PAM stack.

If this reference is wrong or missing → SSH login always fails.

---

# 4. Step 3 — password-auth includes system-auth

Inside `/etc/pam.d/password-auth`:
```
include  system-auth
```

Meaning:
- sshd → password-auth → system-auth  
- system-auth is the REAL authentication logic

Break password-auth → SSH fails  
Break system-auth → SSH, su, login, cron, everything fails

---

# 5. Step 4 — AUTH phase of system-auth

This is where the password is validated.

Typical AUTH stack:
```
auth required      pam_env.so
auth required      pam_faillock.so preauth silent audit deny=3 unlock_time=900
auth sufficient    pam_unix.so try_first_pass nullok
auth sufficient    pam_sss.so use_first_pass
auth required      pam_faillock.so authfail audit deny=3 unlock_time=900
auth required      pam_deny.so
```

Process:
1. `pam_env`: set environment
2. `pam_faillock`: check lockout
3. `pam_unix`: try local users
4. `pam_sss`: try AD users through SSSD
5. `pam_faillock`: update counters
6. `pam_deny`: fail if nothing succeeded

If pam_sss is missing → AD login cannot work, only local users.

Test AUTH phase:
```
pamtester sshd username authenticate
```

---

# 6. Step 5 — PAM calls SSSD for AD authentication

`pam_sss.so` hands credentials to SSSD via an internal pipe here:
```
/var/lib/sss/pipes/pam
```

If this pipe is missing or SSSD stopped:
```
pam_sss(sshd:auth): Request to sssd failed
```
Login fails instantly.

Check:
```
systemctl status sssd
ls -l /var/lib/sss/pipes/
```

---

# 7. Step 6 — SSSD identity lookup

Before Kerberos auth, SSSD checks if the user exists.
```
sssctl user-show username
```
If not found → PAM returns "user unknown" → auth fails.

If DNS wrong, you get:
```
SSSD nss: Cannot contact server
```

---

# 8. Step 7 — Kerberos authentication inside SSSD

SSSD performs Kerberos AS-REQ using the password.

Test outside SSSD:
```
kinit username
```
If kinit fails → AD login fails.

Common Kerberos errors:
- `Clock skew too great` → fix NTP
- `Cannot contact any KDC` → DNS wrong
- `Preauthentication failed` → wrong password

Live logs:
```
tail -f /var/log/sssd/sssd_pam.log
```

---

# 9. Step 8 — LDAP group enumeration

After Kerberos success, SSSD queries LDAP for group membership.

Check groups:
```
groups username
```
Slow group fetch = slow login.

If group enumeration fails:
```
SSSD: Error retrieving groups for user
```

---

# 10. Step 9 — SSSD access control evaluation

Even with correct password, SSSD may deny login based on:
- ad_access_filter
- simple_allow_users
- simple_allow_groups
- login hours
- AD account disabled

Logs:
```
pam_sss(sshd:account): Access denied
```

Check filters:
```
grep access_provider /etc/sssd/sssd.conf
```

---

# 11. Step 10 — PAM ACCOUNT phase

ACCOUNT phase runs AFTER successful password authentication.

`system-auth` typically contains:
```
account required pam_unix.so
account [default=bad success=ok user_unknown=ignore] pam_sss.so
account required pam_permit.so
```

Failures here return:
```
Permission denied
```
Even though password was correct.

---

# 12. Step 11 — PAM SESSION phase

SESSION phase sets up:
- ulimits via pam_limits
- home directory via pam_mkhomedir
- SELinux context
- keyring

Example lines:
```
session required pam_limits.so
session required pam_mkhomedir.so skel=/etc/skel/ umask=0077
session optional pam_sss.so
```

Failures here look like:
```
Could not chdir to home directory
``` 
Meaning home directory missing → pam_mkhomedir or oddjobd issue.

Fix:
```
systemctl enable --now oddjobd
```

---

# 13. Step 12 — Shell granted

If all phases succeed, PAM returns success to sshd.
sshd launches the user shell defined in `/etc/passwd` or the AD override.

Check shell:
```
getent passwd username
```

AD user shell can be set via SSSD config:
```
default_shell = /bin/bash
```

---

# 14. End-to-end troubleshooting: Where EXACTLY did it fail?

### Step 1 — Does identity lookup work?
```
id username
```
If no → SSSD identity error.

### Step 2 — Does Kerberos work?
```
kinit username
```
If no → DNS/time/realm error.

### Step 3 — Does SSSD receive PAM requests?
```
tail -f /var/log/sssd/sssd_pam.log
```
If no → system-auth / password-auth ordering wrong.

### Step 4 — Does PAM allow authentication?
```
tail -f /var/log/secure
```
Look for pam_deny, faillock, access errors.

### Step 5 — Does session succeed?
Home dir? Limits? SELinux?

You now know exactly where the flow failed.

---

# 15. Complete flow summary (the entire chain in one unbroken diagram)

```
1. ssh client connects
2. sshd loads sshd_config
3. sshd calls PAM → /etc/pam.d/sshd
4. sshd delegates to password-auth
5. password-auth includes system-auth
6. system-auth AUTH phase starts
7. pam_unix checks local users
8. pam_sss hands to SSSD
9. SSSD performs identity lookup via LDAP
10. SSSD performs Kerberos auth
11. SSSD retrieves LDAP groups
12. SSSD evaluates access rules
13. SSSD returns success/failure to PAM
14. PAM ACCOUNT phase checks restrictions
15. PAM SESSION phase sets environment, limits, home
16. sshd launches shell
17. user logged in
```

This is the EXACT real authentication flow you must understand as a Linux + AD administrator.

---

# What you achieve after this file

By finishing this file, you now have:
- a complete, correct picture of the entire authentication flow
- the ability to diagnose any AD login failure by isolating the failing stage
- understanding of where PAM stops and where SSSD starts
- clarity of how Kerberos participates in the process
- a systematic troubleshooting blueprint for production environments

This file is your **master reference** for the whole authentication pipeline.
