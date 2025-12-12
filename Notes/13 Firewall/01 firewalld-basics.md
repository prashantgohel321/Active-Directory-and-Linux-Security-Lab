# firewalld-basics.md

This file gives you a **complete, practical, real-world introduction to firewalld** — how it works, how to inspect active rules, how zones behave, how to open/close ports safely, how to test rules, and how to debug issues when services don’t respond.

No shallow theory. Everything here is what a sysadmin actually uses in production.

---

# 1. What firewalld is and how it works

`firewalld` is a dynamic firewall manager for Linux (including Rocky Linux) that wraps **nftables** (or legacy iptables on older systems). It supports:
- zones (trust levels)
- services (predefined port groups)
- runtime vs permanent rules
- rich rules (fine-grained filtering)
- interfaces bound to zones

firewalld is **stateful** — it tracks connection states and is aware of established sessions.

Service control:
```
systemctl status firewalld
systemctl start firewalld
systemctl enable firewalld
```

Check backend (nftables expected):
```
firewall-cmd --backend
```

---

# 2. Zones — the foundation of firewalld

A **zone** represents a trust level. Each network interface belongs to **one zone**.

Common zones:
- `public` — default for most systems
- `home` / `work` — more permissive
- `internal` — trusted
- `external` — NAT, masquerading
- `drop` — drop all incoming traffic
- `trusted` — allow everything

List zones:
```
firewall-cmd --get-zones
```

Find default zone:
```
firewall-cmd --get-default-zone
```

Find which zone an interface (ex: ens160) belongs to:
```
firewall-cmd --get-active-zones
```

Assign an interface permanently:
```
firewall-cmd --zone=public --change-interface=ens160 --permanent
firewall-cmd --reload
```

**Tip:** Always verify which zone your interface is in before opening ports. Most misconfigurations happen here.

---

# 3. Runtime vs Permanent rules

firewalld maintains two rule sets:
- **runtime** — live, disappears on reboot
- **permanent** — persistent after reload/reboot

Example: open port temporarily (runtime):
```
firewall-cmd --add-port=8080/tcp
```

Open permanently:
```
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

Show runtime rules:
```
firewall-cmd --list-all
```

Show permanent rules:
```
firewall-cmd --list-all --permanent
```

**Rule of thumb:** Always make changes permanent unless you are testing.

---

# 4. Services vs Ports

firewalld includes predefined **services** stored in XML under `/usr/lib/firewalld/services/`.

Examples:
```
ssh
http
https
smtp
kerberos
freeipa-ldap
freeipa-ldaps
```

Add service:
```
firewall-cmd --add-service=ssh
```

Add port:
```
firewall-cmd --add-port=22/tcp
```

Allow service permanently:
```
firewall-cmd --add-service=http --permanent
firewall-cmd --reload
```

List allowed services:
```
firewall-cmd --list-services
```

Check service definition:
```
firewall-cmd --info-service=ssh
```

Use services when possible. Use ports when service definition does not exist.

---

# 5. Practical: Open common ports safely

### SSH
```
firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload
```

### HTTP/HTTPS
```
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --reload
```

### Custom port (ex: 8080)
```
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

Verify:
```
firewall-cmd --list-all
ss -tulnp | grep 8080
```

---

# 6. Rich rules — fine-grained filtering

Rich rules allow firewall-like syntax inside firewalld.

Example: allow SSH only from specific IP:
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.10.10.5" service name="ssh" accept' --permanent
firewall-cmd --reload
```

Block an IP:
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.50" drop' --permanent
```

Allow a port only for a subnet:
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" port port="3306" protocol="tcp" accept' --permanent
```

Log dropped packets:
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" log prefix="FW-DROP:" level="info" drop' --permanent
```

Check rich rules:
```
firewall-cmd --list-rich-rules
```

---

# 7. Masquerading and NAT

Enable NAT (common in gateway / router setups):
```
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --reload
```

Port forwarding example:
```
firewall-cmd --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
```

Forward to another host:
```
firewall-cmd --add-forward-port=port=80:proto=tcp:toaddr=192.168.1.20 --permanent
```

List NAT rules:
```
firewall-cmd --list-all
```

---

# 8. Testing firewall rules

Check if port is open from **local** machine:
```
ss -tulnp | grep 8080
```

Test externally:
```
nc -vz <server_ip> 8080
```

Scan open ports:
```
nmap -sT <server_ip>
```

Be careful with aggressive scans on production or monitored networks.

---

# 9. Debugging common firewall issues

### Issue: Service running but unreachable
Steps:
1. Check service is listening:
   ```
   ss -tulnp | grep <port>
   ```
2. Check firewall zone of interface:
   ```
   firewall-cmd --get-active-zones
   ```
3. Check rules:
   ```
   firewall-cmd --list-all
   ```
4. Check SELinux:
   ```
   sealert -a /var/log/audit/audit.log
   ```

### Issue: You opened port but still blocked
- You added runtime rule only → add `--permanent` + reload.
- Interface is bound to another zone.
- Service listens only on localhost.
- SELinux blocking connection.

### Issue: DNS not working
Open ports:
```
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload
```
Ensure server listens on port 53.

### Issue: Cannot reach web server
Open HTTP/HTTPS:
```
firewall-cmd --add-service=http --add-service=https --permanent
``` 
And confirm service is actually running.

---

# 10. Viewing and exporting firewalld configuration

Show entire configuration:
```
firewall-cmd --list-all
firewall-cmd --list-all-zones
```

Export as XML (for backups):
```
firewall-offline-cmd --zone=public --list-services
```

View service definitions:
```
less /usr/lib/firewalld/services/ssh.xml
```

---

# 11. Resetting firewalld (carefully)

Reset to defaults:
```
firewall-cmd --complete-reload
firewall-cmd --reload
```

Hard reset all rules:
```
firewall-offline-cmd --set-default-zone=public
```

Only do this when you have console access — firewalls can lock you out.

---

# 12. Cheat sheet

```
# view zones
firewall-cmd --get-active-zones

# open port
firewall-cmd --add-port=8080/tcp --permanent

# open service
firewall-cmd --add-service=ssh --permanent

# view rules
firewall-cmd --list-all

# add rich rule
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.5" service name="ssh" accept' --permanent

# reload
firewall-cmd --reload
```

---

# What you achieve after this file

You gain total confidence in using firewalld: zones, ports, services, rich rules, NAT, testing, and troubleshooting. You will be able to secure servers at a professional level without guesswork.