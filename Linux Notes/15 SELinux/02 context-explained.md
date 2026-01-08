# context-explained.md

This file explains **SELinux contexts** in practical detail: what each part of a context means, why contexts are the core of SELinux enforcement, how contexts are assigned and stored, how to inspect them for processes and files, how to change them correctly and persistently, and how to debug context-related problems in real life. Every command and example here is something you will run in the lab.

No vague theory — only concrete explanations and operational steps.

---

# 1. What a SELinux context is (fast answer)

A SELinux context is a four-part label attached to objects (files, sockets, ports) and subjects (processes). The canonical form looks like this:

```
user:role:type:level
```

Each field has a specific job:
- `user` — SELinux user identity (not the Linux account). Maps to a set of allowed roles. Examples: `system_u`, `unconfined_u`, `guest_u`.
- `role` — role the subject can assume; roles constrain which types a process may enter. Examples: `object_r`, `system_r`.
- `type` — the most important field for enforcement. Policies grant or deny access based on the `type`. Examples: `httpd_t` (httpd process type), `httpd_sys_content_t` (web content files), `etc_t` (config files). The type is the main gatekeeper.
- `level` — MLS/MCS sensitivity label used only if SELinux is configured for multi-level security. Typical default is `s0` (single-level). On systems using MCS you'll see values like `s0:c123,c456`.

When SELinux enforces a rule, it checks the source context (process) and the target context (file/type) and consults the policy for allowed `type`-based actions.

---

# 2. Why the `type` field matters most

The `type` (also called `domain` when used for processes) is the cornerstone of SELinux enforcement. Rules are written as `allow <source_type> <target_type>:<class> <permission>;` — for example:

```
allow httpd_t httpd_sys_content_t:file read;
```

This rule allows processes labeled `httpd_t` to read files labeled `httpd_sys_content_t` and nothing else. If the file has the wrong type, SELinux denies access even if Unix file permissions allow it. That is why fixing file contexts is the common solution for SELinux-related service failures.

---

# 3. How contexts are assigned and where they are stored

File contexts are governed by the policy's **file context database**, compiled into the policy and represented on disk by persistent rules. The live label on a file is stored in the filesystem extended attributes (xattr), which `ls -Z` reads.

The persistent mapping is available via `semanage fcontext` and is applied to files with `restorecon`. The default policy provides mappings for standard directories (e.g., `/etc` → `etc_t`, `/var/www` → `httpd_sys_content_t`).

Key files/commands:
- `/etc/selinux/targeted/contexts/files/file_contexts` (policy default)
- `semanage fcontext -l` (lists local customizations)
- `restorecon -Rv /path` (apply persistent contexts to files)
- `matchpathcon -V /path` (show which context policy expects)

Example: the default context for `/var/www/html/index.html` is `system_u:object_r:httpd_sys_content_t:s0`.

---

# 4. Inspecting contexts (commands you will use)

### Files and directories
```
ls -lZ /var/www/html
# example output
-rw-r--r--. root root system_u:object_r:httpd_sys_content_t:s0 index.html
```

### Processes
```
ps auxZ | grep httpd
# example
root   1234  ... system_u:system_r:httpd_t:s0 /usr/sbin/httpd
```

### Ports and sockets
```
semanage port -l | grep http_port_t
# or
ss -lntpZ | grep :80
```

### Show expected default context for a path
```
matchpathcon -V /srv/myapp/index.php
# displays the context the policy expects for that path
```

### List local file context customizations
```
semanage fcontext -l | grep myapp
```

---

# 5. Changing contexts — quick fix vs persistent fix

There are two ways to change a file's label.

### Quick (temporary) — `chcon`
`chcon` changes the file's live SELinux label immediately by writing the xattr. This change is not persistent across `restorecon` or policy relabels.

```
chcon -t httpd_sys_content_t /srv/myapp/index.php
```
Use `chcon` when you need a fast test or a temporary workaround.

### Correct (persistent) — `semanage fcontext` + `restorecon`
To persist the mapping:

```
semanage fcontext -a -t httpd_sys_content_t '/srv/myapp(/.*)?'
restorecon -Rv /srv/myapp
```
This registers a pattern in the policy's file context database and applies it. It survives relabels and is the proper method for production fixes.

If you only run `chcon` and later `restorecon`, your `chcon` changes will be undone.

---

# 6. Common real-world examples and fixes

### Example A: Web uploads failing (httpd can’t write to /srv/myapp/uploads)
Problem: Application returns permission denied on file write. Unix perms show `www-data` owns the dir.

Investigation:
```
ls -ldZ /srv/myapp/uploads
# likely output: unconfined_u:object_r:tmp_t:s0
```
Fix (persistent):
```
semanage fcontext -a -t httpd_sys_rw_content_t '/srv/myapp/uploads(/.*)?'
restorecon -Rv /srv/myapp/uploads
```
Then ensure `httpd` has the right SELinux boolean, e.g. `httpd_unified` or `httpd_enable_homedirs` if needed.

### Example B: PostgreSQL data directory inaccessible
Problem: `postgres` cannot start, SELinux denies file access.

Investigation:
```
ls -Z /var/lib/pgsql/data
# shows wrong type
ausearch -m avc -ts recent
```
Fix:
```
semanage fcontext -a -t postgresql_db_t '/var/lib/pgsql/data(/.*)?'
restorecon -Rv /var/lib/pgsql/data
```

### Example C: Service binding to custom port
Problem: A custom web app listens on port 8080 but SELinux blocks binding.

Investigation:
```
ausearch -m avc -ts recent | audit2allow -w -a
```
Fix:
```
semanage port -a -t http_port_t -p tcp 8080
```
Or change the service to use a port type already allowed to the process.

---

# 7. SELinux users and role mapping (practical notes)

Linux usernames (UIDs) map to SELinux users which then map to roles. Most servers use default mappings (e.g., Linux `root` → `sysadm_u` or `system_u`). You rarely change SELinux user mappings, but you should understand them when troubleshooting.

List SELinux users:
```
semanage login -l
```
Map a Linux user to an SELinux user:
```
semanage login -a -s staff_u alice
```
This is usually required for multi-user systems with restricted shell roles. Most server setups do not need custom mappings.

---

# 8. MCS/MLS `level` field explained briefly

Most systems use a single-level `s0`. If your organization uses Multi-Category Security (MCS) or Multi-Level Security (MLS), the `level` contains categories like `s0:c1,c2` representing compartments. MCS is commonly used in container separation to prevent cross-container access. You will encounter `level` values when working with SELinux in containerized platforms; for basic AD/Linux integration labs, `s0` is typical.

Do not modify levels unless you know how MLS/MCS works — mislabeling can create high-severity leaks or blockages.

---

# 9. Troubleshooting checklist for context problems

1. Reproduce the failure and capture AVCs: `ausearch -m avc -ts recent` or `journalctl -k | grep avc`.  
2. Identify the process context (`ps auxZ`) and the file context (`ls -Z`).  
3. Use `matchpathcon -V` to see what context the policy expects for the path.  
4. If file type is wrong, use `semanage fcontext` + `restorecon`. If missing mapping, add it with a pattern.  
5. If the process lacks permission due to port/type, consider `semanage port` or use booleans.  
6. Test temporary `chcon` or domain permissive if you need to collect AVCs without blocking production.  
7. After fixes, revert any permissive domain or permissive system settings and retest under enforcing mode.

---

# 10. Useful commands — quick reference

```
# show file contexts
ls -lZ /path/to/file

# show process contexts
ps auxZ | grep myservice

# show policy expected context
matchpathcon -V /path/to/file

# add persistent file context and apply
semanage fcontext -a -t TYPE '/path(/.*)?'
restorecon -Rv /path

# temporary live change
chcon -t TYPE /path/to/file

# list local custom contexts
semanage fcontext -l

# ports
semanage port -l | grep http_port_t
semanage port -a -t http_port_t -p tcp 8080

# list SELinux log denials
ausearch -m avc -ts today
ausearch -m avc -i

# map linux login to selinux user
semanage login -l
semanage login -a -s staff_u alice
```

---

# What you achieve after this file

You will have a clear, applied understanding of SELinux contexts: how to read them, why they matter, how to correct file and process contexts permanently and safely, how to map ports and users when necessary, and how to troubleshoot context-related access denials in a structured, repeatable way. These are the exact skills you will use daily when administering SELinux-enabled servers.
