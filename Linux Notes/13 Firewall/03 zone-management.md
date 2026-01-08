# zone-management.md

This file explains **everything about firewalld zones** — what they actually do, how interfaces bind to zones, how traffic is evaluated, how to move services between zones, how to troubleshoot wrong zone assignments, and how to design a proper zone architecture for secure environments.

Zones are the backbone of firewalld security. Misunderstanding them leads to ports not working, services being exposed unintentionally, or admins locking themselves out. This guide fixes that.

---

# 1. What a zone is — the real meaning

A **zone** defines the trust level of network traffic. Every interface on the system belongs to **one zone at a time**. Each zone has its own rules: allowed services, ports, rich rules, masquerading, forwarding, etc.

Traffic filtering is done **per zone**, not globally.

Common zones (provided by firewalld):
- `public` — untrusted networks, minimal allowed services
- `home`, `work` — more trusted
- `internal` — trusted LANs with more open traffic
- `external` — for NAT gateways
- `drop` — drop everything silently
- `block` — reject everything with ICMP unreachable
- `trusted` — allow all incoming traffic (rarely appropriate)

You must understand: **your firewall rules only apply to the zone your interface uses**.

---

# 2. Checking active zones and interfaces

See all zones currently active:
```
firewall-cmd --get-active-zones
```
Example output:
```
public
  interfaces: ens160
```
This means *all rules in the public zone* apply to interface `ens160`.

See default zone:
```
firewall-cmd --get-default-zone
```
The default zone is assigned to any interface without an explicit zone.

---

# 3. Changing an interface's zone

Assign interface permanently to a zone:
```
firewall-cmd --zone=internal --change-interface=ens160 --permanent
firewall-cmd --reload
```
Assign temporarily (runtime):
```
firewall-cmd --zone=internal --change-interface=ens160
```

Verify:
```
firewall-cmd --get-active-zones
```

If a service is not working, **90% of the time the interface is in the wrong zone**.

---

# 4. Listing rules inside zones

Show active rules for the zone tied to your interface:
```
firewall-cmd --list-all
```
Show for specific zone:
```
firewall-cmd --zone=public --list-all
```
Show permanent rules only:
```
firewall-cmd --zone=public --list-all --permanent
```

---

# 5. Adding rules to the correct zone

### Adding a service permanently:
```
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --reload
```

### Adding a port:
```
firewall-cmd --zone=public --add-port=9000/tcp --permanent
firewall-cmd --reload
```

### Adding a rich rule:
```
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.0.50" service name="ssh" accept' --permanent
```

If you forget to specify `--zone=...`, the command applies to the **default zone**, which might not be the zone your interface is using.

---

# 6. Evaluating traffic: how firewalld decides allow/deny

When a packet arrives:
1. firewalld checks **which interface** received the packet.
2. firewalld checks **which zone** that interface belongs to.
3. firewalld checks the zone's rules:
   - allowed services
   - allowed ports
   - rich rules
   - forward/mask rules
4. firewalld accepts or denies the packet.

Zones do not interact with each other. They are strict boundaries.

Example mistake:
- You opened `ssh` in `internal` zone.
- Interface is using `public` zone.
- SSH will still be blocked.

---

# 7. Trust design: how enterprises use zones

Typical design:

**public zone (internet-facing):**
- Only expose required ports
- Strong restrictions
- Use rich rules for specific IP allow lists

**internal zone:**
- Allow common internal ports: DNS, NTP, LDAP, AD, Kerberos
- Useful for servers joined to AD domains

**trusted zone:**
- Avoid using; equivalent to disabling firewall

**drop/block zone:**
- Redirect unused interfaces here
- Useful for management or honeypot NICs

---

# 8. Creating your own custom zone

You can define zone XML manually.

Create:
```
/etc/firewalld/zones/mysecurezone.xml
```
Example:
```
<zone>
  <short>MySecureZone</short>
  <description>Strict internal services only</description>
  <service name="ssh"/>
  <port protocol="tcp" port="9090"/>
</zone>
```
Reload:
```
firewall-cmd --reload
```
Assign interface:
```
firewall-cmd --zone=mysecurezone --change-interface=ens160 --permanent
```

---

# 9. Masquerading and NAT per zone

Enable masquerade:
```
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --reload
```

Zone-specific port forwarding:
```
firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent
```

Only zones marked for routing/NAT should use masquerading.

---

# 10. Diagnostics: when zones break things

### Problem: service not reachable
1. Check interface zone:
   ```
   firewall-cmd --get-active-zones
   ```
2. Check if port/service is added under that zone:
   ```
   firewall-cmd --zone=public --list-all
   ```
3. Check SELinux (commonly overlooked):
   ```
   sealert -a /var/log/audit/audit.log
   ```
4. Check if service listens on the correct IP:
   ```
   ss -tulnp | grep <port>
   ```
5. Check rich rules blocking traffic.

### Problem: new rule added but doesn’t work
- Did you add runtime only?
- Did you reload permanent rules?
- Did you add rule to wrong zone?
- Did you forget IPv6 version of rule?

### Problem: interface moved zones unexpectedly
Cause: NetworkManager changes.
Fix:
```
nmcli connection modify <name> connection.zone internal
nmcli connection up <name>
```

---

# 11. Resetting zone assignments

Remove interface from a zone:
```
firewall-cmd --zone=public --remove-interface=ens160 --permanent
```
Set new default zone:
```
firewall-cmd --set-default-zone=internal
```
Reload:
```
firewall-cmd --reload
```

---

# 12. Cheat Sheet

```
# view active zones
firewall-cmd --get-active-zones

# change zone for interface
firewall-cmd --zone=internal --change-interface=ens160 --permanent
firewall-cmd --reload

# list rules in a zone
firewall-cmd --zone=public --list-all

# add service to correct zone
firewall-cmd --zone=public --add-service=http --permanent

# add rich rule
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" port port=22 protocol=tcp accept' --permanent
```

---

# What you achieve after this file

You will understand exactly **how zones govern firewall behavior**, how to assign interfaces properly, how to isolate networks using zones, and how to debug issues when traffic doesn’t match your expectations. This is one of the most important skills in Linux firewall administration.