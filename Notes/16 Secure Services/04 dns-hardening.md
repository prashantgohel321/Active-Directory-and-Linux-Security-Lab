# dns-hardening.md

This file focuses on **DNS hardening** for Linux servers, especially when running BIND (named). Everything here is practical: configuration files, query restrictions, zone protections, logging, DNSSEC, rate limiting, chrooting, systemd sandboxing, and how to defend your DNS service from poisoning, amplification attacks, reconnaissance, and unauthorized zone transfers.

The goal is simple: build a DNS service that is locked down, predictable, and safe to expose internally or externally.

---

# 1. Understand what you are securing

DNS is extremely sensitive because it:
- exposes internal hostname and IP metadata
- can be abused for DDoS amplification
- can be poisoned or hijacked
- is a reconnaissance target for attackers

Your DNS hardening must aim to:
1. restrict who can query your DNS server
2. restrict who can perform zone transfers
3. ensure zones cannot be tampered with
4. keep logs for audit
5. reduce attack surface
6. support DNSSEC if required
7. run named in least-privileged mode

---

# 2. Disable recursion for public-facing DNS

If your server is authoritative only, **never** allow recursion.  
Recursion turns your DNS server into an open resolver (which attackers love).

In `/etc/named.conf`:
```
recursion no;
allow-recursion { none; };
```
Verify:
```
named-checkconf
systemctl reload named
```
Test:
```
dig @your-dns-server google.com
# Should return REFUSED
```

If this DNS server must serve internal clients, restrict recursion:
```
allow-recursion { 192.168.0.0/24; 10.0.0.0/16; localhost; };
```
Never leave recursion open to the internet.

---

# 3. Restrict zone transfers (AXFR) — critical for security

If zone transfers are unrestricted, *anyone* can clone your internal DNS zone and map your entire network.

In zone definition:
```
zone "example.local" IN {
    type master;
    file "/var/named/example.local.zone";
    allow-transfer { 192.168.1.10; };   # authorized secondary
};
```
Block transfers globally:
```
allow-transfer { none; };
```
Test:
```
dig AXFR example.local @your-dns-server
```
If your hardening is correct this should be REFUSED unless from authorized IP.

---

# 4. Hide BIND version information

Attackers use version information for targeted exploits.

Hide version:
```
version "not-disclosed";
```
Check:
```
dig CHAOS TXT version.bind @your-dns-server
```
---

# 5. Limit response rate (RRL) to prevent amplification attacks

DNS amplification attacks abuse your server to attack others.  
Use Response Rate Limiting:

Add to `named.conf`:
```
rate-limit {
    responses-per-second 5;
    window 5;
    slip 2;
    ipv4-prefix-length 24;
};
```
Restart:
```
systemctl reload named
```
Monitor logs to confirm rate limiting is in effect.

---

# 6. Use minimal anycast-like or bind-to-interface restrictions

Bind only to required interfaces:
```
listen-on { 192.168.1.5; 127.0.0.1; };
listen-on-v6 { none; };
```
To disable IPv6 entirely:
```
listen-on-v6 { none; };
```
`any` is unsafe unless you fully trust all interfaces.

---

# 7. DNSSEC — protect against tampering (optional but important)

DNSSEC ensures integrity by signing zones.

### Enable DNSSEC validation:
```
dnssec-validation yes;
```
### Create keys for your zone:
```
cd /var/named
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.local
```
This creates KSK/ZSK key pairs.

### Sign the zone:
```
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -d' ' -f1) -N increment -o example.local example.local.zone
```
Named will load the `.signed` file.

Add to zone config:
```
zone "example.local" IN {
    type master;
    file "example.local.zone.signed";
};
```
Restart named.

DNSSEC adds security but requires key rotation and correct DS record publishing.

---

# 8. Logging and audit hardening

Enable query logging only when needed because it is noisy:
```
logging {
    channel querylog {
        file "/var/log/named_query.log" versions 5 size 50m;
        severity info;
        print-time yes;
    };
    category queries { querylog; };
};
```
Logs to check regularly:
```
/var/log/messages
/var/log/named_query.log
journalctl -u named
```
Search for suspicious high-frequency queries, long TXT queries, or DNS tunneling patterns.

---

# 9. Prevent DNS tunneling (exfiltration technique)

DNS tunneling abuses TXT or NULL queries to send data out of the network.

Mitigations:
- Enable RRL
- Inspect logs for long TXT queries
- Block unauthorized outbound DNS servers using firewall
- Restrict which hosts can query your DNS

Firewall rule example:
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" port port="53" protocol="tcp" accept' --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" destination port="53" protocol="tcp" drop' --permanent
firewall-cmd --reload
```
This ensures only allowed clients use this DNS server.

---

# 10. Chroot BIND for additional isolation

Modern BIND runs well sandboxed via systemd, but chrooting adds an extra layer.

Install:
```
dnf install bind-chroot -y
```
Then ensure service uses it:
```
systemctl enable --now named-chroot
```
Chrooted files live under `/var/named/chroot/`.

---

# 11. Systemd hardening — reduce attack surface

Add in `/etc/systemd/system/named.service.d/hardening.conf`:
```
[Service]
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
RestrictAddressFamilies=AF_INET AF_INET6
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_SETUID CAP_SETGID
```
Reload systemd:
```
systemctl daemon-reload
systemctl restart named
```
This prevents named from accessing unnecessary files or using unwanted capabilities.

---

# 12. Drop all unnecessary DNS records and metadata

In authoritative zones remove:
- HINFO
- RP records
- LOC records
- TXT records not used for SPF/DMARC
- wildcard records unless required

The less information you expose, the harder reconnaissance becomes.

---

# 13. Test your DNS hardening

Run:
```
dig @your-dns-server version.bind chaos txt
```
Expect: "not-disclosed".

Test recursion off:
```
dig @your-dns-server google.com
# EXPECT: REFUSED
```
Test zone transfer protections:
```
dig AXFR example.local @your-dns-server
```
Expect: REFUSED unless from authorized secondary.

Check response rate limiting:
```
watch -n1 'journalctl -u named | grep rate'
```

Perform basic security scan:
```
nmap --script dns-recursion,dns-nsid,dns-zone-transfer -p 53 your-dns-server
```

---

# 14. Common DNS misconfigurations that weaken security

- Leaving recursion enabled on internet-facing DNS
- Allowing unrestricted zone transfers
- Exposing BIND version to attackers
- Not using RRL (easy for attackers to abuse)
- Running named with unnecessary privileges
- Forgetting IPv6 listeners (opening exposure)
- Allowing external clients to query internal-only zones
- No logging for analysis

Avoid these mistakes no matter what.

---

# 15. Quick reference — commands you will actually use

```
# check named config
named-checkconf
named-checkzone example.local /var/named/example.local.zone

# restart service
systemctl reload named
systemctl restart named

# test queries
dig @server domain.com
dig AXFR domain.com @server

dig CHAOS TXT version.bind @server

# RRL, recursion, transfers settings in named.conf
recursion no;
allow-transfer { none; };
rate-limit { responses-per-second 5; };

# log analysis
journalctl -u named
cat /var/log/named_query.log
```

---

# What you achieve after this file

By the end of this file you will know how to **lock down a DNS server thoroughly**, make it non-exploitable for amplification attacks, protect zones from unauthorized access, enforce least-privileged operation for named, deploy DNSSEC securely, detect tunneling attempts, and validate your hardening through testing. This is the standard expected from a competent Linux administrator managing DNS infrastructure in production.