# selinux-modes.md

- This file explains SELinux modes in depth and gives you hands-on steps to manage, debug, and tune SELinux in a Rocky Linux / RHEL environment. You will learn what each mode does, when to use it, how to switch modes safely, how to interpret AVC denials, and practical recovery/roll-back strategies. Everything is written as real commands you will run in the lab.


---

<br>
<br>

- [selinux-modes.md](#selinux-modesmd)
- [1. What SELinux modes mean (plain language)](#1-what-selinux-modes-mean-plain-language)
- [2. Checking the current SELinux state and mode](#2-checking-the-current-selinux-state-and-mode)
- [3. Switching modes safely (runtime and persistent)](#3-switching-modes-safely-runtime-and-persistent)
- [4. Why permissive is useful — capture AVCs without breaking things](#4-why-permissive-is-useful--capture-avcs-without-breaking-things)
- [5. Interpreting AVC denials (the logs you need)](#5-interpreting-avc-denials-the-logs-you-need)
- [6. Quick fixes vs correct fixes (do the right thing)](#6-quick-fixes-vs-correct-fixes-do-the-right-thing)
- [7. Using audit2allow and building policy modules](#7-using-audit2allow-and-building-policy-modules)
- [8. SELinux booleans — flip allowed behaviors safely](#8-selinux-booleans--flip-allowed-behaviors-safely)
- [9. File contexts and types — the single most common SELinux issue](#9-file-contexts-and-types--the-single-most-common-selinux-issue)
- [10. SELinux and services — practical examples](#10-selinux-and-services--practical-examples)
- [11. Generating permissive domains (advanced safe workflow)](#11-generating-permissive-domains-advanced-safe-workflow)
- [12. Troubleshooting steps — a checklist you will use](#12-troubleshooting-steps--a-checklist-you-will-use)
- [13. Useful commands quick reference](#13-useful-commands-quick-reference)
- [14. When to disable SELinux (and safer alternatives)](#14-when-to-disable-selinux-and-safer-alternatives)
- [15. What you achieve after this file](#15-what-you-achieve-after-this-file)


<br>
<br>

---

# 1. What SELinux modes mean (plain language)

- SELinux runs in three modes: **enforcing**, **permissive**, and **disabled**. <mark><b>Enforcing</b></mark> applies policy decisions: if policy denies an action, the kernel blocks it and logs an AVC (Access Vector Cache) denial. <mark><b>Permissive</b></mark> does not block actions — it only logs what would have been denied. <mark><b>Disabled</b></mark> turns SELinux off entirely; neither blocking nor logging occurs.

<br>

- Use <mark><b>enforcing</b></mark> for production security. Use <mark><b>permissive</b></mark> for debugging or during policy development so you can collect AVCs and build rules without causing outages. Use <mark><b>disabled</b></mark> only when you cannot make SELinux work and have a clear, documented reason; prefer permissive as an intermediate step because it preserves logs for analysis.

---

<br>
<br>

# 2. Checking the current SELinux state and mode

**Commands to check quickly:**

```bash
getenforce          # prints Enforcing|Permissive|Disabled
sestatus            # more detailed status
```

<br>

`sestatus` shows policy name, loaded policy version, and whether file contexts are in place. If `getenforce` prints `Permissive`, the policy is still loaded but not enforced.

---

<br>
<br>

# 3. Switching modes safely (runtime and persistent)

**To switch mode at runtime (no reboot):**

```bash
# set to permissive
setenforce 0

# set to enforcing
setenforce 1

# verify
getenforce
```
This change lasts until reboot.

<br>

**To make a persistent change edit `/etc/selinux/config` and set `SELINUX=` to `enforcing`, `permissive`, or `disabled`:**
```bash
# /etc/selinux/config
SELINUX=enforcing
SELINUXTYPE=targeted
```
Then reboot for the persistent change to take effect.

<br>

**Important workflow:** When debugging a service that fails under SELinux, do not immediately disable SELinux. Instead switch to permissive, reproduce the failure to collect AVC logs, then analyze and create a tailored fix.

---

<br>
<br>

# 4. Why permissive is useful — capture AVCs without breaking things

- Permissive mode logs the exact AVC denials that would occur in enforcing mode, producing the data needed to write a correct policy or adjust file contexts. This avoids guesswork and prevents unnecessary disabling of SELinux.

<br>

**Workflow example:**
1. `setenforce 0` on the target host.  
2. Reproduce the failing action (e.g., start service, run app).  
3. Gather AVC logs from `/var/log/audit/audit.log` or `ausearch`.  
4. Use `audit2allow` to generate a module or see suggested rules.  
5. Test the generated module in permissive mode, refine, then load in enforcing mode.

Do not leave systems in permissive mode longer than necessary.

<br>
<details>
<summary><mark><b>What is AVC?</b></mark></summary>
<br>

- AVC means Access Vector Cache.
- In simple words, AVC is <mark><b>how SELinux decides and remembers access rules</b></mark>.
- When a program (like Apache or PostgreSQL) tries to access something (a file, port, directory), SELinux checks:
  - who is asking
  - what they want to access
  - whether it is allowed

<br>

- That decision is stored in the AVC.
- If access is allowed, SELinux lets it happen.
- If access is not allowed, SELinux blocks it and logs an AVC denial.

<br>

**That’s why you often see messages like:**
```bash
avc:  denied  { read } for  pid=1234 comm="httpd" ...
```

In simple terms:
- AVC is the decision engine
- AVC denials are SELinux saying “no”
- AVC logs tell you exactly what was blocked and why

When debugging SELinux issues, AVC messages are the first and most important thing to check.

</details>
<br>


---

<br>
<br>

# 5. Interpreting AVC denials (the logs you need)

When SELinux blocks something, you will see AVC messages in `/var/log/audit/audit.log` or via `journalctl` and optionally in `/var/log/messages`. Example:
```bash
type=AVC msg=audit(1712935032.532:491): avc:  denied  { write } for  pid=2345 comm="httpd" name="index.html" dev="sda1" ino=12345 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:var_t:s0 tclass=file
```
Key fields: `scontext` (source context — the process), `tcontext` (target context — the file), `tclass` (object class like file, dir, sock), and the permission attempted (`write`). Use these to plan a fix.

Search for AVC denials quickly:
```bash
ausearch -m avc -ts recent    # require audit package
ausearch -m avc -i            # human readable
journalctl -k | grep AVC
```

---

# 6. Quick fixes vs correct fixes (do the right thing)

Quick but risky fixes: change file ownership or broad file contexts with `chcon -R -t httpd_sys_rw_content_t /var/www/html` or run `setenforce 0`. These can solve immediate outages but may hide the root cause.

Correct fixes: fix the file context persistently with `semanage fcontext` and `restorecon`, or modify rules via a policy module.

Example persistent file-context fix:
```bash
semanage fcontext -a -t httpd_sys_content_t '/srv/myapp(/.*)?'
restorecon -Rv /srv/myapp
```
This assigns the correct `type` to the path across reboots and relabels existing files.

Use `chcon` for quick testing and `semanage` for persistent changes.

---

# 7. Using audit2allow and building policy modules

When AVCs show legitimate behavior that SELinux should permit, you can generate a minimal policy module.

Collect AVCs (example recent denials):
```
ausearch -m avc -ts today > /tmp/avc.log
```
Generate a suggested policy with `audit2allow` (from `policycoreutils-python-utils` package):
```
# show suggested allow rules
cat /tmp/avc.log | audit2allow -w -a
# create a module
cat /tmp/avc.log | audit2allow -M mymodule
# install the module
semodule -i mymodule.pp
```
`audit2allow -w` prints a human-friendly explanation and risk. Always inspect suggestions closely — `audit2allow` will allow whatever is in logs; be sure the activity is safe.

---

# 8. SELinux booleans — flip allowed behaviors safely

Booleans let you toggle common policy choices without writing new modules. For example, `httpd_can_network_connect` allows httpd to make outbound network connections.

List booleans and find relevant ones:
```
getsebool -a | grep httpd
semanage boolean -l | less
```
Set a boolean temporarily:
```
setsebool httpd_can_network_connect on
```
Make it persistent:
```
setsebool -P httpd_can_network_connect on
```
Use booleans whenever possible rather than custom modules. They are documented and less likely to introduce security holes.

---

# 9. File contexts and types — the single most common SELinux issue

Every object has a label: user:role:type:level. The `type` is what the policy uses to control access. Typical web content must be `httpd_sys_content_t` for read-only content or `httpd_sys_rw_content_t` for writeable directories used by uploads.

Check a file’s context:
```
ls -Z /var/www/html/index.html
```
If the type is wrong, set it persistently:
```
semanage fcontext -a -t httpd_sys_content_t '/var/www/html(/.*)?'
restorecon -Rv /var/www/html
```
Use `semanage fcontext -l` to list custom rules.

---

# 10. SELinux and services — practical examples

Example: PostgreSQL cannot read a data directory because of context. Fix:
```
semanage fcontext -a -t postgresql_db_t '/var/lib/pgsql/data(/.*)?'
restorecon -Rv /var/lib/pgsql/data
```
Example: A custom daemon needs to bind to a port not labeled for its type. Either change the service to use a socket file with correct context or add port mapping:
```
semanage port -a -t http_port_t -p tcp 8080
```
Then restart the service.

---

# 11. Generating permissive domains (advanced safe workflow)

When developing policy for a specific service, you can put a domain into permissive mode without making the whole system permissive. This logs denials for that domain while keeping overall enforcement.

Example: make `httpd_t` permissive:
```
semanage permissive -a httpd_t
```
To list permissive domains:
```
semanage permissive -l
```
Remove permissive flag when done:
```
semanage permissive -d httpd_t
```
This is safer than system-wide permissive mode because it isolates policy development.

---

# 12. Troubleshooting steps — a checklist you will use

1. Reproduce the failure while in permissive mode or put the domain permissive.  
2. Gather AVC logs: `ausearch -m avc -ts recent` and `journalctl -t setroubleshoot` if `setroubleshoot` is installed.  
3. Run `audit2allow -w -a` to see why denial occurred and how dangerous an allow would be.  
4. If it is a file-context issue, use `semanage fcontext` + `restorecon`. If it is a capability or port, use `semanage port` or booleans. If it is an unusual but legitimate flow, generate a minimal policy with `audit2allow -M` and install with `semodule -i`.  
5. Test in enforcing mode and remove permissive flags.  
6. Keep a backup of any custom modules and review them regularly.

---

# 13. Useful commands quick reference

```
# check mode
getenforce
sestatus

# switch mode at runtime
setenforce 0   # permissive
setenforce 1   # enforcing

# persistent mode change
vi /etc/selinux/config

# show AVCs
ausearch -m avc -ts today
ausearch -m avc -i
journalctl -t setroubleshoot

# suggested rules and modules
cat /var/log/audit/audit.log | audit2allow -w -a
cat /var/log/audit/audit.log | audit2allow -M mymodule
semodule -i mymodule.pp

# file contexts
ls -Z /path/to/file
semanage fcontext -a -t httpd_sys_content_t '/srv/myapp(/.*)?'
restorecon -Rv /srv/myapp

# booleans
getsebool -a | grep httpd
setsebool -P httpd_can_network_connect on

# permissive domain
semanage permissive -a httpd_t
semanage permissive -d httpd_t

# ports
semanage port -a -t http_port_t -p tcp 8080
semanage port -l | grep http_port_t
```

---

# 14. When to disable SELinux (and safer alternatives)

Disabling SELinux should be a last resort. Consider these steps before disabling:
- move to permissive, collect AVCs, fix with `semanage` and modules
- use permissive domains to focus on the failing service
- ensure file contexts and booleans are correct

If you must disable for a short maintenance window, document the reason, timeline, and rollback plan. Change `/etc/selinux/config` and reboot. Remember: disabled systems produce no SELinux logs — forensic trails vanish.

---

# 15. What you achieve after this file

You will understand the three SELinux modes deeply and be able to switch modes safely, collect and interpret AVC logs, fix context and policy issues properly, use booleans, build policy modules confidently, and avoid the common trap of disabling SELinux needlessly. This gives you practical mastery for administering SELinux-protected Linux servers in both lab and production environments.
