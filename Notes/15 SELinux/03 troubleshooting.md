# troubleshooting.md

This file is a **complete, practical SELinux troubleshooting guide**. It teaches you how to identify SELinux-related failures, extract AVC denials, fix file contexts, adjust ports, use booleans, test permissive modes, build policy modules, and avoid the common destructive mistakes (like disabling SELinux). Everything here is operational and directly applicable.

---

# 1. First question: *Is SELinux causing this issue?*

Most Linux service failures are not caused by SELinux. You confirm SELinux involvement by checking **AVC denials**.

Quick checks:
```
journalctl -k | grep -i avc
ausearch -m avc -ts recent     # most reliable if auditd is running
```
If no AVCs appear for the failing action, SELinux is probably **not** the cause.

If AVC messages show up at the moment of failure, SELinux is involved. Extract them before making assumptions.

---

# 2. Identify the failing operation using AVC logs

AVC logs tell you exactly what was denied.

Example AVC:
```
avc:  denied  { write } for  pid=2453 comm="httpd" name="uploads" dev="sda1" ino=12345 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:tmp_t:s0 tclass=dir
```
Important fields:
- `scontext`: process context (source)
- `tcontext`: object/file context (target)
- `tclass`: type of object (file, dir, sock)
- `{ write }`: operation attempted

This example shows httpd_t trying to write to a directory labeled tmp_t. That is not allowed.

Extract readable AVC messages:
```
ausearch -m avc -ts today -i
```

If `setroubleshootd` is installed:
```
journalctl -t setroubleshoot -f
```
It prints human-readable explanations and suggested fixes.

---

# 3. Determine *why* SELinux blocked the action

Typical root causes:

1. **Wrong file context** on files/directories.  
   Example: application writes to `/srv/app/uploads/` but directory is labeled `var_t` or `tmp_t` instead of `httpd_sys_rw_content_t`.

2. **Port not assigned** to correct SELinux port type.  
   Example: httpd tries to bind to 8080 but SELinux only allows `httpd_t` to bind to ports labeled `http_port_t`.

3. **Service needs outbound connection**, but boolean is off.  
   Example: httpd cannot connect externally; toggle `httpd_can_network_connect`.

4. **Process domain incorrect** due to custom systemd units or incorrect binary paths.

5. **Container / virtualization labeling issues** (MCS mismatches).

Identify which category you are in before applying fixes.

---

# 4. Fixing wrong file contexts (most common issue)

### Step 1: Inspect live context
```
ls -Z /path/to/file_or_dir
```

### Step 2: See expected context
```
matchpathcon -V /path/to/file_or_dir
```

If the actual type does not match the expected type, set persistent context mapping:
```
semanage fcontext -a -t httpd_sys_rw_content_t '/srv/app/uploads(/.*)?'
restorecon -Rv /srv/app/uploads
```

After relabeling, repeat failure test.

Temporary fix for debugging:
```
chcon -t httpd_sys_rw_content_t /srv/app/uploads
```
Do not rely on `chcon` in production — it is overwritten by `restorecon`.

---

# 5. Fixing incorrect SELinux port labels

List port types:
```
semanage port -l | grep http
```
If your service needs to bind to a new port:
```
semanage port -a -t http_port_t -p tcp 8080
```
If port exists but wrong type:
```
semanage port -m -t http_port_t -p tcp 8080
```
Restart service and retest.

---

# 6. Fixing domain permissions via SELinux booleans

Booleans adjust policy without writing modules.

Common booleans:
```
getsebool -a | grep httpd
```
Enable outbound connections:
```
setsebool -P httpd_can_network_connect on
```
Allow httpd to access user home directories:
```
setsebool -P httpd_enable_homedirs on
```
List all booleans with explanations:
```
semanage boolean -l
```
If a boolean exists for your scenario, always prefer enabling it instead of writing a custom module.

---

# 7. Using permissive mode for diagnosis (safe workflow)

Switch system to permissive mode temporarily:
```
setenforce 0
```
Reproduce issue.  
Check AVCs:
```
ausearch -m avc -ts recent -i
```
Fix file contexts, ports, or booleans as needed.

Return to enforcing:
```
setenforce 1
```

**Correct workflow:** permissive → gather AVCs → fix → enforce.  
Do *not* start in disabled mode.

---

# 8. Permissive *domain* (advanced and safer than global permissive)

Mark only one process domain permissive:
```
semanage permissive -a httpd_t
```
Now only httpd_t runs permissive; the rest of the system enforces.

Check:
```
semanage permissive -l
```
Remove permissive flag:
```
semanage permissive -d httpd_t
```
Use when debugging a specific service.

---

# 9. Generating SELinux policy modules (when needed)

Do this only when file contexts + booleans cannot solve the problem.

Collect AVC logs:
```
ausearch -m avc -ts today > /tmp/avc.log
```
Generate module:
```
cat /tmp/avc.log | audit2allow -M mymodule
semodule -i mymodule.pp
```
Keep modules minimal and review them manually.

Danger of using audit2allow blindly:  
It will allow everything in logs, including mistakes or attacks.

---

# 10. Relabeling the entire system (only use when contexts are massively corrupted)

Identify corrupted labels:
```
fixfiles check
```
If relabel required:
```
touch /.autorelabel
reboot
```
SELinux will relabel all files at boot using default policy.  
This is slow but guarantees clean labeling.

Avoid autorelabel on large systems unless necessary.

---

# 11. Troubleshooting patterns — real cases and solutions

### Case A: HTTP 403 on file upload
AVC: denied write to `tmp_t`.  
Fix: assign `httpd_sys_rw_content_t` to upload directory.

### Case B: Custom app on port 9000 cannot bind
AVC: denied name_bind.  
Fix: `semanage port -a -t http_port_t -p tcp 9000` or map app to a correct type.

### Case C: App needs outbound network access
AVC: denied name_connect.  
Fix: `setsebool -P httpd_can_network_connect on`.

### Case D: Systemd unit runs a custom script; SELinux blocks script access
Fix: place script under correct labeled directory or add custom fcontext rule.

---

# 12. What *not* to do (the traps new admins fall into)

- Don’t disable SELinux because “it’s easier”.  
- Don’t use `chcon` as the permanent solution.  
- Don’t run `audit2allow` blindly.  
- Don’t ignore the `type` mismatch between files and processes.  
- Don’t assume Unix permissions override SELinux — they don’t.

---

# 13. Quick reference — commands you will actually use

```
# check mode
ggetenforce
sestatus

# switch mode
setenforce 0
setenforce 1

# list AVCs
aausearch -m avc -ts recent -i
journalctl -k | grep avc

# fix file context
semanage fcontext -a -t TYPE '/path(/.*)?'
restorecon -Rv /path

# fix port
semanage port -a -t TYPE -p tcp 9000

# enable boolean
setsebool -P httpd_can_network_connect on

# permissive domain
semanage permissive -a httpd_t

# build module
cat avc.log | audit2allow -M mymodule
semodule -i mymodule.pp
```

---

# What you achieve after this file

You will be able to troubleshoot SELinux issues systematically: confirm SELinux involvement, read AVCs, diagnose context mismatches, fix file labels and port types, apply booleans, build minimal modules, and avoid the common destructive shortcuts. This puts you in control of SELinux instead of fighting it.