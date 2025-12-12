# id-command-scope.md

This file explains **exactly what the `id` command does in Linux**, how it interacts with SSSD, AD, NSS, and local accounts, and how to use it to troubleshoot real authentication and access issues.

`id` is one of the simplest Linux commands but also one of the most powerful diagnostic tools when working with AD + SSSD.  
If `id` fails, **AD login cannot work** — it means identity lookup already broke before authentication.

This file covers:
- how `id` resolves users
- why SSSD controls the output for AD users
- how UID/GID mapping works
- why results differ between local users and AD users
- advanced debugging techniques using `id`
- all failure cases and their meaning

---

<br>
<br>

# 1. What the `id` command actually does

Syntax:
```
id username
```

The command queries the system’s identity providers using **NSS (Name Service Switch)**. NSS decides whether the user exists locally or in AD (through SSSD).

Process:
```
id → glibc → nsswitch.conf → SSSD or local files
```

If the user exists, `id` prints:
- UID
- primary GID
- group list

If not, `id` prints:
```
id: ‘username’: no such user
```

This means **identity lookup failed**, and authentication cannot succeed.

---

<br>
<br>

# 2. How `id` behaves for different types of users

## (A) Local Linux user
Stored in `/etc/passwd` and `/etc/group`.
Example output:
```
uid=1000(prashant) gid=1000(prashant) groups=1000(prashant),10(wheel)
```

Lookup path for local users:
```
nsswitch.conf → files → /etc/passwd
```

## (B) AD User with SSSD
Example:
```
id testuser
```
Output:
```
uid=123456789(testuser) gid=123456789(domain users) groups=123456789(domain users),123456790(devops),...
```

Lookup path for AD users:
```
nsswitch.conf → sss → SSSD → AD (LDAP)
```

If this lookup fails, SSSD logs the cause.

---

<br>
<br>

# 3. How `nsswitch.conf` determines the lookup order

Relevant lines:
```
passwd:     files sss
group:      files sss
```
Meaning:
- system checks `/etc/passwd` first
- then checks SSSD

If `sss` is removed, AD users cannot resolve → `id` fails → login fails.

Check:
```
cat /etc/nsswitch.conf | grep passwd
```

---

<br>
<br>

# 4. How SSSD resolves IDs for AD users

SSSD receives the username and queries AD LDAP for:
- `objectSID` (unique identifier in AD)
- group memberships

SSSD converts SIDs to UID/GID using deterministic mapping rules:
```
UID = algorithm(objectSID)
```
This ensures consistent UID/GID even across servers.

Verify identity resolution:
```
sssctl user-show username
```

If this succeeds but `id` fails, nsswitch is misconfigured.

---

<br>
<br>

# 5. Why UID/GID numbers look huge for AD users

Example:
```
uid=2020311108(testuser)
```
This is **correct**.  
SSSD converts AD SIDs to numeric Linux IDs using an algorithm.  
You should NOT modify or override these values.

If you switch from algorithmic mapping to LDAP-mapping, all UIDs change → massive break.

---

<br>
<br>

# 6. How group membership is resolved by `id`

When you run:
```
id testuser
```
SSSD must fetch:
- primary group from `primaryGroupID`
- all groups from `memberOf`

If slow or incomplete, check:
```
groups testuser
sssctl user-show testuser
```

### If group list is empty
SSSD cannot contact LDAP → login will still succeed but access filters may fail.

---

<br>
<br>

# 7. Using `id` for real troubleshooting

### Test identity lookup
```
id testuser
```
If this fails → AD login cannot work.

### Test group membership correctness
```
id testuser | tr ' ' '\n'
```
Analyse groups.

### Test multiple domain identities
```
id user@gohel.local
id GOHEL\\user
```
Check if domain suffix resolution works.

### Test case sensitivity issues
```
id TestUser
id testuser
```
Both should work — if not, SSSD misconfiguration.

### Test access control filters
If login fails but `id` works → SSSD access rules denying login.

Check:
```
tail -f /var/log/sssd/sssd_pam.log
```

---

<br>
<br>

# 8. Common failure scenarios and what they mean

## Scenario 1 — `id: no such user`
Meaning:
- SSSD cannot find the user in AD
- user does not exist in the domain
- DNS/LDAP unreachable
- nsswitch misconfigured

Debug:
```
sssctl user-show testuser
sssctl domain-status
```

---

## Scenario 2 — `id` works, but login fails
This means password or access rules failing.

Debug:
```
kinit testuser
tail -f /var/log/sssd/sssd_pam.log
```

---

## Scenario 3 — `id` extremely slow
Cause:
- LDAP timeout
- unreachable DC
- slow group resolution

Debug:
```
sssctl domain-status
```

---

## Scenario 4 — wrong UID or GID
Cause:
- changed mapping settings in sssd.conf
- legacy UID mapping from previous configurations

Check mapping mode:
```
grep id_provider /etc/sssd/sssd.conf
grep ldap_id_mapping /etc/sssd/sssd.conf
```

---

## Scenario 5 — AD users appear as `nobody` / `nobody4`
Cause:
- SSSD identity lookup failed fallbacks

Fix DNS or LDAP → restart SSSD.

---

<br>
<br>

# 9. How to debug `id` using SSSD logs

Monitor logs:
```
tail -f /var/log/sssd/sssd_nss.log
```
Look for:
```
NSS: User lookup failed
NSS: No such user
NSS: Error converting SID to UID
```

If the nss responder dies:
```
systemctl restart sssd
```

---

<br>
<br>

# 10. Useful variants of the `id` command

### Only UID
```
id -u username
```

### Only primary GID
```
id -g username
```

### All groups
```
id -G username
```

### Fully qualified name
```
id username@gohel.local
```

### Legacy domain style
```
id GOHEL\\username
```
---

<br>
<br>

# 11. Summary — what `id` proves

If `id username` works, it proves:
```
1. SSSD is running
2. DNS resolution of AD works
3. LDAP communication succeeds
4. UID/GID mapping works
5. Groups are resolved
6. Access filters probably not blocking identity
```

`id` does NOT prove:
- that password authentication works  
- that the user is allowed to log in (access phase)  
- that session setup will succeed

But it confirms the **identity part**, which MUST succeed before authentication.

---

<br>
<br>

# What you achieve after this file

You now understand how `id` interacts with SSSD, NSS, DNS, LDAP, and UID mapping.  
You know exactly how to use `id` to confirm or reject problems in AD login processing and how to interpret every meaningful failure.

This is one of the simplest but most powerful tools in Linux AD troubleshooting.