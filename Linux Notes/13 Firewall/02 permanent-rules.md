# permanent-rules.md

This file explains **everything you need to know about permanent firewall rules in firewalld** — how they work, how they differ from runtime rules, how to manage them safely, best practices for production, validation techniques, rollback strategies, and troubleshooting.

Permanent rules are what actually secure your server after reboot. Misconfiguring them can lock you out instantly, so you must understand them properly.

---

# 1. Runtime vs Permanent Rules — the core concept

firewalld maintains two separate rule sets:

### Runtime rules
- apply immediately
- disappear on reboot or on `--complete-reload`
- safe for testing

### Permanent rules
- stored on disk
- survive reboot and reload
- require `firewall-cmd --reload` to take effect
- used for production security

Check current runtime rules:
```
firewall-cmd --list-all
```
Check permanent rules:
```
firewall-cmd --list-all --permanent
```
These **will not match** unless you explicitly applied permanent rules and reloaded.

---

# 2. How permanent rules are stored (internal structure)

firewalld saves permanent configuration as XML files under:
```
/etc/firewalld/zones/<zone>.xml
```
Example:
```
/etc/firewalld/zones/public.xml
```
A typical zone file:
```
<zone>
  <service name="ssh"/>
  <port protocol="tcp" port="8080"/>
  <masquerade/>
</zone>
```
Manual editing is possible but risky — always prefer `firewall-cmd`.

---

# 3. Adding permanent rules — ports, services, rich rules

### Add permanent port
```
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
```

### Add permanent service
```
firewall-cmd --add-service=http --permanent
firewall-cmd --reload
```

### Add permanent rich rule
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.5" port port="22" protocol="tcp" accept' --permanent
firewall-cmd --reload
```

### Add permanent masquerade
```
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload
```

**Important:** permanent changes **do not apply** until you reload:
```
firewall-cmd --reload
```
This loads XML config into runtime.

---

# 4. Safely applying permanent rules (critical)

Bad firewall rules can instantly disconnect you. Use this safe workflow:

### Step 1 — Add rule as runtime
```
firewall-cmd --add-port=8080/tcp
```
Verify service works.

### Step 2 — Add rule permanently
```
firewall-cmd --add-port=8080/tcp --permanent
```

### Step 3 — Reload safely
```
firewall-cmd --reload
```
Make sure you have console access if working on remote servers.

---

# 5. Verifying permanent configuration

List permanent zone config:
```
firewall-cmd --zone=public --list-all --permanent
```

List all permanent zones:
```
firewall-cmd --list-all-zones --permanent
```

Check if a port is permanently allowed:
```
firewall-cmd --info-zone=public | grep 8080
```

---

# 6. Binding interfaces permanently to zones

By default, interfaces may belong to the `public` zone. You can change permanently:
```
firewall-cmd --zone=internal --change-interface=ens160 --permanent
firewall-cmd --reload
```

Check mapping:
```
firewall-cmd --get-active-zones
```

If the interface belongs to the wrong zone, your permanent rules won’t apply.

---

# 7. Permanent services — creating custom service definitions

Create your own service XML:
```
/etc/firewalld/services/myapp.xml
```
Example:
```
<service>
  <short>MyApp</short>
  <description>My Application Service</description>
  <port protocol="tcp" port="9000"/>
</service>
```
Reload firewalld service definitions:
```
firewall-cmd --reload
```
Enable permanently:
```
firewall-cmd --add-service=myapp --permanent
firewall-cmd --reload
```

---

# 8. Permanent rich rules — advanced filtering

Rich rules allow granular control.

### Allow SSH only from specific subnet
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.10.0.0/16" service name="ssh" accept' --permanent
```

### Drop traffic from a specific IP
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" drop' --permanent
```

### Log traffic before dropping
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" log prefix="FW-DROP:" level="info" drop' --permanent
```

List rich rules:
```
firewall-cmd --list-rich-rules
```

---

# 9. Permanent NAT and masquerade rules

Enable masquerade permanently:
```
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload
```

Port forwarding:
```
firewall-cmd --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
firewall-cmd --reload
```

Forward to another host:
```
firewall-cmd --add-forward-port=port=80:proto=tcp:toaddr=10.0.0.50 --permanent
```

---

# 10. Exporting and backing up permanent configuration

Backup zones:
```
cp -r /etc/firewalld/zones /root/fw-backup-$(date +%F)
```

Backup services:
```
cp -r /etc/firewalld/services /root/fw-services-backup
```

Restore by copying back and reloading.

---

# 11. Resetting permanent rules (dangerous)

Reset zone to defaults:
```
firewall-offline-cmd --zone=public --set-target=default
```

Reset everything:
```
rm -rf /etc/firewalld/zones/*
systemctl restart firewalld
```

Only do this if you **have console access**, otherwise you may lock yourself out.

---

# 12. Troubleshooting permanent rule issues

### Issue: Rule shows in permanent list but not applied
Cause: You forgot to reload.
```
firewall-cmd --reload
```

### Issue: Rule added to wrong zone
Fix: specify zone explicitly.
```
firewall-cmd --zone=public --add-port=8080/tcp --permanent
```

### Issue: Interface is not using the zone you think
```
firewall-cmd --get-active-zones
```
Assign interface correctly.

### Issue: Connection still blocked
Check SELinux:
```
sealert -a /var/log/audit/audit.log
```
Check service binding:
```
ss -tulnp | grep <port>
```
Check if firewalld backend is nftables and working properly.

---

# 13. Cheat sheet

```
# add permanent rule
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload

# list permanent rules
firewall-cmd --list-all --permanent

# add rich rule permanently
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.10" accept' --permanent

# check interface zone
firewall-cmd --get-active-zones
```

---

# What you achieve after this file

You will confidently manage, validate, and troubleshoot permanent firewall rules — avoiding downtime and misconfigurations. This knowledge is essential for production Linux administration and security engineering.