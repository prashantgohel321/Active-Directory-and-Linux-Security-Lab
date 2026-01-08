# pam-to-system-auth.md

This file explains exactly what happens when PAM hands control to **system-auth** and how the `system-auth` stack is executed inside the broader authentication flow. This is the critical middle link: SSH (or another service) calls PAM → PAM calls `password-auth` or includes `system-auth` → `system-auth` executes the authentication, account, password, and session phases. If `system-auth` is wrong, nearly every entry point into the server breaks.

This file is 100% practical: exact commands to inspect, exact outputs to expect, concrete failure modes, and precise fixes.

---

- [pam-to-system-auth.md](#pam-to-system-authmd)
  - [Why `system-auth` is central](#why-system-auth-is-central)
  - [How services reference `system-auth`](#how-services-reference-system-auth)
  - [Anatomy of `system-auth` (practical baseline)](#anatomy-of-system-auth-practical-baseline)
  - [AUTH phase — exact behavior when `system-auth` runs](#auth-phase--exact-behavior-when-system-auth-runs)
  - [ACCOUNT phase — exact behavior and traps](#account-phase--exact-behavior-and-traps)
  - [PASSWORD phase — when `system-auth` matters](#password-phase--when-system-auth-matters)
  - [SESSION phase — what `system-auth` does after successful AUTH](#session-phase--what-system-auth-does-after-successful-auth)
  - [Real-world troubleshooting steps when system-auth is suspected](#real-world-troubleshooting-steps-when-system-auth-is-suspected)
  - [Safe editing strategy for system-auth](#safe-editing-strategy-for-system-auth)
  - [Common mistakes that break system-auth](#common-mistakes-that-break-system-auth)
  - [Quick recovery checklist if you are locked out after system-auth edit](#quick-recovery-checklist-if-you-are-locked-out-after-system-auth-edit)
  - [What you achieve after this file](#what-you-achieve-after-this-file)


<br>
<br>

## Why `system-auth` is central

Most PAM-aware services do not duplicate the entire PAM stack. Instead they either `include` or `substack` a shared file: `system-auth`. This avoids duplication and ensures consistent behavior across SSH, console login, su, sudo, graphical login, and other services.

A broken `system-auth` affects all those services simultaneously.

---

<br>
<br>

## How services reference `system-auth`

Common patterns inside service-level PAM files:

- `include system-auth` — imports all lines from `system-auth` at that point
- `auth substack password-auth` — `password-auth` itself includes `system-auth` in practice

Examples:

```bash
# /etc/pam.d/sshd
auth       substack     password-auth
account    include      password-auth
password   include      password-auth
session    include      password-auth
```

and

```bash
# /etc/pam.d/password-auth
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
```

So `/etc/pam.d/sshd` -> `/etc/pam.d/password-auth` -> `/etc/pam.d/system-auth`.

---

<br>
<br>

## Anatomy of `system-auth` (practical baseline)

A safe, practical `system-auth` for AD+SSSD environments looks like this:

```bash
# AUTH phase
auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=3 unlock_time=900
auth        sufficient    pam_unix.so try_first_pass nullok
auth        sufficient    pam_sss.so use_first_pass
auth        required      pam_faillock.so authsucc audit deny=3 unlock_time=900
auth        required      pam_deny.so

# ACCOUNT phase
account     required      pam_unix.so
account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required      pam_permit.so

# PASSWORD phase
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    sufficient    pam_unix.so try_first_pass
password    sufficient    pam_sss.so use_authtok
password    required      pam_deny.so

# SESSION phase
session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
session     required      pam_mkhomedir.so skel=/etc/skel/ umask=0077
session     optional      pam_sss.so
```

We will unpack each group with expected outputs and failure cases.

---

<br>
<br>

## AUTH phase — exact behavior when `system-auth` runs

1. `pam_env.so` loads environment variables. If missing, environment values may be absent but authentication proceeds.

2. `pam_faillock.so preauth` checks if the account is already locked before prompting for a password. If the account is locked, the authentication ends early.

3. `pam_unix.so try_first_pass` attempts local password verification against `/etc/shadow`. If the password matches a local account, PAM considers authentication successful and returns immediately because of `sufficient`.

4. If local auth didn't succeed, `pam_sss.so use_first_pass` calls SSSD to authenticate the user using the password already read by PAM. SSSD talks to Kerberos and LDAP. If SSSD returns success, authentication ends successfully.

5. `pam_faillock.so authsucc` records successful auth to reset the failure counter.

6. `pam_deny.so` is the fallback: if no previous module succeeded, deny.

Common testing commands and expected results:

- Test local auth success:
```bash
su - localuser
# expect shell; check /var/log/secure for pam_unix success entries
```

- Test AD auth success (after join):
```bash
su - testuser1
# expect shell; check /var/log/sssd/sssd_pam.log for pam_sss success
```

- If auth fails with no SSSD log entries, suspect ordering or missing pam_sss lines.

---

<br>
<br>

## ACCOUNT phase — exact behavior and traps

Account modules check policy but do not prompt for passwords. Typical checks:

- `pam_unix.so` checks local account expiry and lock
- `pam_sss.so` checks AD account status, disabled flag, login hours, and access filters
- `pam_permit.so` at the end allows a clean pass-through for local accounts after checks

Example failure messages you will see in logs and what they mean:

- `pam_sss(sshd:account): Access denied` → AD says user cannot log in (disabled account, not in allowed group, login hours)
- `pam_unix(account): user expired` → local account expired

How to test account phase:

```bash
sssctl user-show testuser1
getent passwd testuser1
```

Look for AD attributes that indicate disabled or expired accounts. If account-phase denies a user despite correct password, fix AD flags or adjust `ad_access_filter` in `/etc/sssd/sssd.conf`.

---

<br>
<br>

## PASSWORD phase — when `system-auth` matters

Password phase only runs on password-change operations. If a user is forced to change password at next login, PAM will move into password phase.

Important lines:

- `pam_pwquality.so` enforces complexity. If password changes fail, most likely `pam_pwquality` or AD policy is blocking the change.
- `pam_sss.so use_authtok` allows SSSD to forward password changes to AD.

Test password change from the console or SSH:

```bash
passwd
# interactively change password; if it fails, check /var/log/secure for pam_pwquality or pam_sss messages
```

If password changes fail for AD users, ensure `pam_sss` lines exist and SSSD has proper privileges to change passwords.

---

<br>
<br>

## SESSION phase — what `system-auth` does after successful AUTH

Typical session lines in `system-auth` create home directories, apply limits, and perform cleanup:

- `pam_limits.so` applies ulimits
- `pam_mkhomedir.so` creates home dirs automatically
- `pam_sss.so` optional session hooks

Common session-phase problems and fixes:

- "Could not chdir to home directory" → ensure `pam_mkhomedir.so` present or manually create home directories
- Home dirs created but permissions wrong → verify skel and umask settings
- Limits not applied → ensure `session required pam_limits.so` exists and sshd uses PAM

---

<br>
<br>

## Real-world troubleshooting steps when system-auth is suspected

Follow this sequence exactly.

1. Verify PAM inclusion chain from service to system-auth:
```bash
grep -E "include|substack" /etc/pam.d/sshd
grep -E "include|substack" /etc/pam.d/password-auth
```

2. Inspect `system-auth` lines where `pam_sss` or `pam_unix` appear:
```bash
grep -n "pam_sss.so\|pam_unix.so\|pam_deny.so\|pam_faillock.so" /etc/pam.d/system-auth
```

3. Open a real-time log monitor in one terminal:
```bash
tail -f /var/log/secure /var/log/sssd/sssd_pam.log
```

4. Attempt the failing action in another terminal (SSH or su). Observe logs.

5. If SSSD logs show no entries during an auth attempt, system-auth is likely not being invoked. Confirm that the service includes `system-auth`.

6. If SSSD logs show Kerberos errors, fix DNS/time before touching PAM.

7. If account-phase denies access, check `ad_access_filter` or AD account flags.

8. If session-phase issues appear (home dir, limits), verify `pam_mkhomedir` and `pam_limits` presence.

9. After changes, restart SSSD or SSHD only if necessary:
```bash
systemctl restart sssd
systemctl restart sshd
```

But do not restart sshd if you only edited PAM unless you have console access.

---

<br>
<br>

## Safe editing strategy for system-auth

1. Always backup:
```bash
cp /etc/pam.d/system-auth /root/system-auth.bak-$(date +%F-%T)
```

2. Edit carefully; comment lines instead of deleting.

3. Keep a root console or second SSH session open while testing.

4. Use `pamtester` to test PAM stacks without leaving an interactive lockout:
```bash
pamtester login <username> authenticate
```

Note: `pamtester` must be installed. If unavailable, rely on safe manual tests.

---

<br>
<br>

## Common mistakes that break system-auth

- Moving `pam_deny.so` above `pam_sss` or `pam_unix`
- Removing `pam_unix.so` leading to local users failing
- Incorrect `pam_faillock` placement causing immediate locks
- Forgetting `pam_mkhomedir` resulting in missing home directories for AD users
- Using `use_authtok` incorrectly in password phase

If any of these occur, restore from backup and correct order.

---

<br>
<br>

## Quick recovery checklist if you are locked out after system-auth edit

1. Use the VM console to access the machine.
2. Restore the backup.
```bash
cp /root/system-auth.bak-YYYY-MM-DD-HH:MM:SS /etc/pam.d/system-auth
systemctl restart sshd
```
3. If you cannot access the console, try using cloud provider serial console or rescue mode.

---

<br>
<br>

## What you achieve after this file

You now have a precise, practical understanding of how PAM hands control to `system-auth`, what each phase in `system-auth` does, how to test each phase, and how to recover safely from mistakes. This file connects the dots between service-level PAM files (like sshd) and the core authentication stack where most real failures occur.