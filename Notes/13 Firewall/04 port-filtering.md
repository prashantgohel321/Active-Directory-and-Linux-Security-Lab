# port-filtering.md

This file is a full, practical guide to **port filtering with firewalld** — how to allow or deny network ports, how to apply rules per zone, how to filter by source IP, how to block ports even if a service is running, how to debug port issues, and how attackers typically try to bypass port filtering.

Everything here is command-first and production-oriented.

---

# 1. What port filtering actually means

Port filtering controls **which TCP/UDP ports can receive or send traffic**. Even if an application listens on a port, firewalld can block access based on zone, protocol, source address, or rich rules.

Port filtering determines whether packets reaching the interface are:
- accepted
- dropped silently
- explicitly rejected
- logged

This is separate from whether the service is *listening*. Both must match.

---

# 2. Basic port allow rules (runtime vs permanent)

### Allow port temporarily (runtime)
```
firewall-cmd --add-port=8080/tcp
```

### Allow port permanently
```
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

### Allow UDP port
```
firewall-cmd --add-port=53/udp --permanent
```

### Allow port range
```
firewall-cmd --add-port=3000-3100/tcp --permanent
```

Check:
```
firewall-cmd --list-ports
```

---

# 3. Filtering ports by zone (critical)

The single biggest mistake admins make: **adding ports to the wrong zone**.

Check which zone your interface uses:
```
firewall-cmd --get-active-zones
```
Example:
```
public
  interfaces: ens160
```
This means ports must be added to the **public zone**, not internal/home.

Correct usage:
```
firewall-cmd --zone=public --add-port=8080/tcp --permanent
```

List per-zone ports:
```
firewall-cmd --zone=public --list-ports
```

---

# 4. Allowing or blocking ports based on source IP

This is where port filtering becomes powerful.

### Allow access to a port only from a specific IP
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.10.10.5" port port="22" protocol="tcp" accept' --permanent
```

### Allow from a subnet only
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="3306" protocol="tcp" accept' --permanent
```

### Block a port from a specific IP
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.20.30.40" port port="80" protocol="tcp" drop' --permanent
```

### Reject instead of drop
```
firewall-cmd --add-rich-rule='rule family="ipv4" port port="25" protocol="tcp" reject' --permanent
```

Difference:
- **drop** = silent
- **reject** = send ICMP error

---

# 5. Completely blocking a port

Sometimes you want to block a port even if a service is listening.

### Block port globally in zone
```
firewall-cmd --add-rich-rule='rule family="ipv4" port port="23" protocol="tcp" drop' --permanent
```

This overrides any allowed service.

### Block multiple ports
```
firewall-cmd --add-rich-rule='rule family="ipv4" port port="20-21" protocol="tcp" drop' --permanent
```

List rules:
```
firewall-cmd --list-rich-rules
```

---

# 6. Logging port blocks

Logging is essential for security monitoring.

### Log traffic before dropping
```
firewall-cmd --add-rich-rule='rule family="ipv4" port port="445" protocol="tcp" log prefix="FW-DROP:" level="info" drop' --permanent
```

Check logs:
```
journalctl -f | grep FW-DROP
```

---

# 7. Port filtering with services (safer)

Instead of opening ports manually, use predefined `firewalld` services.

Example: allow SSH safely
```
firewall-cmd --add-service=ssh --permanent
```

Shows ports inside service:
```
firewall-cmd --info-service=ssh
```

Advantages:
- reduces mistakes
- automatically allows all related ports
- easier to audit

---

# 8. Port filtering with interface-based rules

When an interface belongs to a zone, all port rules for that zone apply.

Bind interface permanently:
```
firewall-cmd --zone=internal --change-interface=ens224 --permanent
firewall-cmd --reload
```

Now port rules in **internal** zone apply to this interface.

---

# 9. Port filtering + masquerading (NAT scenarios)

If server is acting as a router/gateway:
```
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --reload
```

Forward port:
```
firewall-cmd --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
```

Forward to another host:
```
firewall-cmd --add-forward-port=port=443:proto=tcp:toaddr=10.0.0.100 --permanent
```

Filter forwarded ports using rich rules:
```
firewall-cmd --add-rich-rule='rule family="ipv4" forward-port port="80" protocol="tcp" accept' --permanent
```

---

# 10. Troubleshooting port filtering issues

### 1. Service reachable locally but not externally
Check if the port is open on firewall:
```
firewall-cmd --zone=public --list-ports
```
Check if service listens externally:
```
ss -tulnp | grep <port>
```
Service listening only on 127.0.0.1 will never be reachable.

### 2. Wrong zone problem
Most common issue.
```
firewall-cmd --get-active-zones
```
If interface belongs to a zone without rules → service unreachable.

### 3. SELinux interference
```
sealert -a /var/log/audit/audit.log
```
Common with ports used by non-default services.

### 4. IPv6 blocked unintentionally
Remember to allow IPv6 as well:
```
firewall-cmd --add-port=8080/tcp --permanent --zone=public
firewall-cmd --add-port=8080/tcp --permanent --zone=public --add-port=8080/tcp --permanent
```
Or explicitly:
```
firewall-cmd --add-rich-rule='rule family="ipv6" port port="8080" protocol="tcp" accept' --permanent
```

### 5. Testing from external host
```
nc -vz <ip> <port>
```
Or use `nmap`:
```
nmap -sT <server_ip>
```

---

# 11. Best practices for port filtering

- Use **services**, not raw ports, whenever possible.
- Always specify the **zone** explicitly.
- Test rules in runtime before making them permanent.
- Avoid exposing unnecessary ports to public.
- Restrict SSH and management ports by IP.
- Log drops for sensitive ports.
- Keep zones minimal; avoid overly permissive configurations.

---

# 12. Cheat sheet

```
# allow port
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload

# block port
firewall-cmd --add-rich-rule='rule family="ipv4" port port=23 protocol=tcp drop' --permanent

# allow port from specific IP
firewall-cmd --add-rich-rule='rule family="ipv4" source address=10.0.0.5 port port=22 protocol=tcp accept' --permanent

# check zone
firewall-cmd --get-active-zones

# test port
nc -vz <ip> <port>
```

---

# What you achieve after this file

You will be able to filter, restrict, block, and log ports with full control. You will know exactly how firewalld interprets port rules, how to apply them per zone, and how to debug issues when services don’t behave as expected.