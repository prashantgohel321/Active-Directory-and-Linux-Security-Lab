# policybasics.md

This file explains **SELinux policy fundamentals** in a fully practical, administrator-focused way. You will learn exactly how SELinux policy works, how rules are structured, how domains and types interact, how modules are built and loaded, and how to modify policy safely without breaking the system. No academic theory — everything is oriented toward real troubleshooting and real server environments.

---

# 1. What SELinux policy actually is

An SELinux *policy* is a ruleset that tells the kernel:
- which **process domains** (types applied to processes) can perform which actions
- which **object types** (files, dirs, sockets, ports) they may access
- which **services** may transition into which domains
- which **booleans** allow optional behaviors

SELinux does not "learn" automatically — the entire enforcement logic comes from policy files compiled and loaded into the kernel.

There are two major policy bases in RHEL/Rocky:
- **targeted** (default): only selected daemons are confined (httpd, named, sshd, etc.)
- **MLS**: complex multi-level security systems; not used in typical enterprise servers

The default targeted policy is what you'll work with.

---

# 2. The core components inside an SELinux policy

SELinux policy is composed of:

### 1. **Types**
The heart of the policy. Every process runs in a *domain* (a type for processes). Every file/dir/socket has a *type*. Access decisions are based on these.

Example types:
- `httpd_t` → Apache process
- `httpd_sys_content_t` → static files served by httpd
- `ssh_port_t` → ports allowed for sshd

### 2. **Allow rules**
Define allowed interactions:
```
allow httpd_t httpd_sys_content_t:file read;
```

### 3. **Type transitions**
Define how process domain changes or how new files inherit correct type.
```
type_transition httpd_t httpd_sys_content_t:file httpd_sys_rw_content_t;
```

### 4. **Booleans**
Toggle optional behavior without loading a new module.
```
setsebool -P httpd_can_network_connect on
```

### 5. **Port and file context mappings**
Define what types ports and paths should have.
```
semanage port -l
semanage fcontext -l
```

### 6. **Policy modules**
Extend or override parts of the base policy without modifying core policy.
```
semodule -l
```

---

# 3. How policy is loaded and where it lives

Compiled policy is stored under:
```
/etc/selinux/targeted/policy/policy.*
```
Local modules live in:
```
/etc/selinux/targeted/modules/active/modules/
```
Use this to list all modules:
```
semodule -l
```

When you install new modules (`.pp` files), they are merged into the system policy and compiled into a new single binary.

---

# 4. Allow rules — how SELinux actually grants permissions

Example from policy:
```
allow httpd_t httpd_sys_content_t:file { read getattr open };
```
This means:
- a process running in domain `httpd_t`
- may perform actions on files labeled `httpd_sys_content_t`
- including read/get attributes/open

If your application needs write access:
```
allow httpd_t httpd_sys_rw_content_t:file { write append };
```
These rules are what `audit2allow` generates when creating a custom module.

---

# 5. Type transitions — why services run in the correct domains

A type transition is a rule that says: “When a process of type X executes file Y, transition process to type Z.”

Example:
```
type_transition init_t httpd_exec_t : process httpd_t;
```
Meaning:
- When systemd (init_t) executes `/usr/sbin/httpd` labeled `httpd_exec_t`, the resulting process domain becomes `httpd_t`.

Without this, httpd would run unconfined — a massive security hole.

File type transitions also exist:
```
type_transition httpd_t httpd_sys_rw_content_t:file httpd_sys_rw_content_t;
```
Used mostly for ensuring new files get the correct type.

---

# 6. Booleans — configurable parts of policy

Booleans toggle optional permissions.
```
getsebool -a
semanage boolean -l
```
Practical common booleans:
- `httpd_can_network_connect` — allow httpd outbound connections
- `samba_enable_home_dirs` — allow Samba to read home dirs
- `authlogin_nsswitch_use_ldap` — allow auth daemons to talk to LDAP

Enable permanently:
```
setsebool -P httpd_can_network_connect on
```
Booleans should be preferred over custom modules whenever possible because they are part of supported policy.

---

# 7. Port and file context policy

### Port policies
Bindability to ports is based on type:
```
semanage port -l | grep http
```
Add new port mapping:
```
semanage port -a -t http_port_t -p tcp 8080
```

### File context policies
Determine the correct default label for files.
```
semanage fcontext -l
```
Add custom:
```
semanage fcontext -a -t httpd_sys_rw_content_t '/srv/app/uploads(/.*)?'
restorecon -Rv /srv/app/uploads
```

This is the correct way to fix context issues permanently.

---

# 8. Writing policy modules — what they actually contain

Policy modules are small `.te` (type enforcement) files compiled into `.pp` modules.

A minimal `.te` file looks like:
```
module mymodule 1.0;
require {
    type httpd_t;
    type httpd_sys_rw_content_t;
    class file { read write open }; 
}
allow httpd_t httpd_sys_rw_content_t:file { read write open };
```
Compile and load:
```
checkmodule -M -m -o mymodule.mod mymodule.te
semodule_package -m mymodule.mod -o mymodule.pp
semodule -i mymodule.pp
```

But in real life, you often use `audit2allow` to generate these automatically.
```
ausearch -m avc -ts today > avc.log
cat avc.log | audit2allow -M mymodule
semodule -i mymodule.pp
```
Review before loading — never blindly apply everything.

---

# 9. What NOT to put into a custom policy module

- Don’t allow access to generic types like `var_t` for services — too broad.
- Don’t allow write access to system config directories unless required.
- Don’t allow `execmem` or `execstack` unless absolutely necessary — these are serious security risks.
- Don’t copy/paste huge auto-generated modules.
- Don’t use `allow *`-style shortcuts.

A module should be as small and specific as possible.

---

# 10. Debugging policy interactions — determining the correct fix

Workflow:
1. Capture AVCs:
```
ausearch -m avc -ts recent -i
```
2. Identify if issue is **file context**, **port label**, **boolean**, or **policy rule**.
3. Fix using the *least invasive* method:
   - Context via `semanage fcontext`
   - Port via `semanage port`
   - Boolean for optional permissions
   - Module only if no built-in mechanism exists
4. Test in permissive domain or permissive system mode if necessary.
5. Re-enable enforcing mode.

Always assume context/boolean issues before writing a policy module.

---

# 11. Viewing the active policy

List installed modules:
```
semodule -l
```
View content of a module (human readable):
```
semodule -l --full | less
```
Dump policy for inspection:
```
seinfo
sesearch -A -s httpd_t -t httpd_sys_content_t -c file -p read
```
Example query:
```
sesearch -A -s httpd_t -t httpd_sys_rw_content_t -c file -p write
```
This tells you whether a permission is already allowed.

---

# 12. Common mistakes new admins make

- Disabling SELinux instead of debugging the real problem.
- Using `chcon` instead of persistent `semanage fcontext`.
- Loading massive audit2allow modules that over-permit.
- Forgetting to label custom ports, causing services to fail silently.
- Running system daemons from oddly labeled directories.
- Ignoring `type_transition` rules, causing wrong process domains.

This file exists to prevent exactly these mistakes.

---

# 13. Quick reference — commands you will actually use

```
# list modules
semodule -l

# search policy
sesearch -A -s httpd_t -t httpd_sys_content_t -c file -p read

# generate module
ausearch -m avc -ts recent > avc.log
cat avc.log | audit2allow -M mymodule
semodule -i mymodule.pp

# fix file context
semanage fcontext -a -t TYPE '/path(/.*)?'
restorecon -Rv /path

# fix port
semanage port -a -t TYPE -p tcp 9000

# toggle boolean
setsebool -P httpd_can_network_connect on

# inspect contexts
ls -Z /path```

---

# What you achieve after this file

You gain a working, operational understanding of SELinux policy: how rules are structured, how access is granted or denied, how type transitions work, how to craft minimal modules, and how to debug policy issues without breaking security. This is the foundation required to administer SELinux-enabled servers confidently in production.