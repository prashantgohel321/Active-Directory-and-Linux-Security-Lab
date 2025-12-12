# ssh-hardening.md

This file provides a **complete, practical SSH hardening guide** for Linux servers. Everything here is operational, not theoretical. This includes cipher/MAC/KEX tightening, key-based authentication, restricting root login, rate limiting, banner enforcement, TCP wrappers relevance, firewalld integration, Fail2Ban interactions, systemd sandboxing, SSH logging, and advanced protections against enumeration and brute force.

The objective: convert a default SSH setup into a hardened, resilient, minimal-attack-surface service safe for enterprise environments.

---

# 1. Understand what SSH hardening tries to prevent

Hardening SSH is not only about stopping brute force attacks. You are defending against:
- password guessing and credential stuffing
- root login exposure
- weak cipher downgrade attempts
- user enumeration
- unchecked access from unauthorized networks
- SSH tunneling misuse
- port scanning and fingerprinting
- unmonitored access attempts

Your SSH security depends on tightening protocol settings, firewall restrictions, and identity rules.

---

# 2. Always start by enforcing key-based authentication

Passwords are a weak authentication method.

In `/etc/ssh/sshd_config`:
```
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
```
Restart:
```
systemctl reload sshd
```
Verify login:
```
ssh -i ~/.ssh/id_rsa user@server
```
If you cannot disable password login (enterprise requirement), combine it with:
- Fail2Ban
- AllowGroups
- lockout policies
- MFA (Google PAM or Duo)

---

# 3. Disable root login

This prevents lateral movement and brute-forcing the root account.

In `/etc/ssh/sshd_config`:
```
PermitRootLogin no
```
Recommended alternative: allow only key-based root login if absolutely required:
```
PermitRootLogin prohibit-password
```
Restart `sshd` and test.

---

# 4. Restrict which users and groups can SSH

Eliminate unnecessary login surfaces. Use AllowUsers or AllowGroups.

Example — allow only domain admins:
```
AllowGroups linuxadmins devops-team
```
Or restrict to specific users:
```
AllowUsers prashant ansible backupsvc
```
If both appear, AllowUsers overrides AllowGroups.

Test in a second terminal **before** closing your primary session.

---

# 5. Change SSH port (not a security feature, but reduces noise)

This does not improve security by itself, but reduces brute-force noise and log spam.
```
Port 2222
```
Remember to:
```
firewall-cmd --add-port=2222/tcp --permanent
firewall-cmd --remove-service=ssh --permanent
firewall-cmd --reload
```
Use alongside real hardening measures.

---

# 6. Harden SSH protocol and cipher suite

Use modern KEX, ciphers, and MACs. Remove legacy algorithms.

Recommended strong configuration (RHEL/Rocky, OpenSSH 8.x+):
```
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-512,hmac-sha2-256
```
Disable weak algorithms:
```
HostKeyAlgorithms -ssh-dss
Ciphers -aes128-cbc,-3des-cbc
```
Test supported ciphers:
```
ssh -Q cipher
ssh -Q kex
ssh -Q mac
```
If older OS or clients exist, ensure compatibility while keeping weak algorithms disabled.

---

# 7. Reduce information exposure

Disable SSH banners that reveal OS, version, or kernel.

In `/etc/ssh/sshd_config`:
```
DebianBanner no
```
Ensure no version leaks occur on handshake. Test using:
```
nc server 22
```
You should not expose distribution or kernel build metadata.

---

# 8. Defend against SSH tunneling abuse

SSH tunnels can bypass firewalls and exfiltrate data.

If your business requires tight restrictions:
```
PermitTunnel no
AllowTcpForwarding no
X11Forwarding no
```
If forwarding is required, limit to specific users via Match blocks:
```
Match User devops
    AllowTcpForwarding yes
    X11Forwarding no
```
Always restrict forwarding on production servers unless explicitly needed.

---

# 9. Use Match blocks for granular control

Example: give SRE team full access, but restrict interns.
```
Match Group sre
    AllowTcpForwarding yes
    X11Forwarding no
    PermitTTY yes

Match Group interns
    X11Forwarding no
    AllowTcpForwarding no
    ForceCommand internal-sftp
```
You can restrict by group, user, IP, or hostname.

---

# 10. Limit authentication attempts and sessions

Mitigate brute-force and automated login attempts.
```
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 20s
```
Aggressive settings reduce log noise and attack surface.

---

# 11. Enforce strong host keys

Ensure only secure host keys are used.

List keys:
```
ls -l /etc/ssh/*key*
```
Disable DSA and short RSA keys:
```
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
```
Generate new RSA 4096-bit key if needed:
```
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key
```
Restart sshd.

---

# 12. Use firewalld/ipset for IP-based SSH restrictions

Allow only specific networks:
```
firewall-cmd --add-rich-rule='rule family="ipv4" source address="203.0.113.5" port port="22" protocol="tcp" accept' --permanent
```
Deny everyone else:
```
firewall-cmd --add-rich-rule='rule family="ipv4" port port="22" protocol="tcp" drop' --permanent
```
Reload:
```
firewall-cmd --reload
```
This is significantly stronger than simply changing SSH port.

---

# 13. Integrate SSH with Fail2Ban

Example jail (`/etc/fail2ban/jail.d/sshd.conf`):
```
[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
banaction = firewallcmd-ipset
findtime = 600
maxretry = 5
bantime = 3600
```
Verify:
```
fail2ban-client status sshd
```
This protects against brute-force and credential stuffing.

---

# 14. Configure SSH logging for monitoring

Enable detailed logging:
```
LogLevel VERBOSE
```
Inspect logs:
```
journalctl -u sshd
journalctl -t sshd
cat /var/log/secure | grep sshd
```
Monitor for:
- repeated failed attempts
- unusual usernames
- logins from new geolocations
- abnormal session counts

---

# 15. Systemd sandboxing for sshd (additional restriction)

Add override file:
```
mkdir -p /etc/systemd/system/sshd.service.d
vi /etc/systemd/system/sshd.service.d/hardening.conf
```
Content:
```
[Service]
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
NoNewPrivileges=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
```
Reload systemd:
```
systemctl daemon-reload
systemctl restart sshd
```
This limits what sshd can access if compromised.

---

# 16. Protect SSH from user enumeration

Prevent attackers from distinguishing valid vs invalid usernames:
```
DenyUsers nobody nfsnobody
```
Ensure PAM does not leak authentication timing differences. Combine with Fail2Ban and two-factor authentication.

---

# 17. Two-factor authentication (optional but strong)

Enable Google PAM MFA:
```
dnf install google-authenticator qrencode
```
Add to `/etc/pam.d/sshd` *before* pam_unix:
```
auth required pam_google_authenticator.so nullok
```
In `sshd_config`:
```
ChallengeResponseAuthentication yes
```
Users must configure OTP with:
```
google-authenticator
```
Test thoroughly before forcing on all users.

---

# 18. SSH key management best practices

- Use ed25519 keys for admin access:
```
ssh-keygen -t ed25519
```
- Set correct permissions:
```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```
- Require command restrictions in authorized_keys if needed:
```
command="/usr/local/bin/backup.sh" ssh-ed25519 AAAA...
```
- Remove unused keys regularly.

---

# 19. Test your hardening

Test from client side:
```
ssh -vvv user@server
```
Check which algorithms negotiated, any refusals, key selection, and authentication flow.

Test brute-force defense:
```
for i in {1..10}; do ssh invalid@server; done
fail2ban-client status sshd
```
Use nmap:
```
nmap -sV -p 22 server
```
Expect minimal version leakage.

---

# 20. Common SSH hardening mistakes

- Disabling password login before installing keys
- Locking yourself out by misusing AllowUsers/AllowGroups
- Forgetting to update firewall rules when changing SSH port
- Using weak or deprecated ciphers
- Allowing root login unnecessarily
- Leaving SSH open to the internet with no rate limiting
- Allowing tunneling or agent forwarding on production servers without review

Avoid these errors in production.

---

# 21. Quick reference

```
# restart service
systemctl reload sshd
systemctl restart sshd

# configuration file
/etc/ssh/sshd_config

# check for syntax errors
sshd -t

# test connection
ssh -vvv user@server

# view logs
journalctl -u sshd
cat /var/log/secure | grep sshd

# fail2ban status
fail2ban-client status sshd
```

---

# What you achieve after this file

You will know how to harden SSH at every level — protocol, authentication, access control, firewall, ciphers, logging, fail2ban, systemd sandboxing, tunneling restrictions, and MFA integration. This produces a hardened SSH service suitable for real enterprise environments and secure production operations.