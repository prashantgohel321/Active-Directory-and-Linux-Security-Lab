# ftp-hardening.md

This file is a complete, practical guide to **hardening FTP services** on Linux. It covers vsftpd and ProFTPD configuration, securing FTP with TLS (FTPS), passive vs active modes, firewall and NAT considerations, user isolation (chroot), virtual users, PAM integration, SELinux contexts, logging, monitoring, and denial-of-service mitigations. Everything is command-first and oriented for Rocky Linux / RHEL environments but applies to other distributions with small path adjustments.

FTP is inherently insecure if left default. Use this guide to run only a hardened, monitored, and minimal FTP service — or better yet, prefer SFTP (SSH File Transfer) where possible.

---

# 1. First decision: FTP vs SFTP

SFTP (SSH File Transfer Protocol) runs over SSH and is far more secure than FTP. If you only need secure file access, use SFTP. FTP may be required for legacy clients, anonymous downloads, or specific appliances. If you must run FTP, use FTPS (FTP over explicit TLS) or implicit TLS, and restrict everything else.

SFTP advantage checklist:
- no separate TLS setup
- uses SSH keys and existing SSH hardening
- easier to audit and integrate with PAM/SSH

If you choose FTP, harden it thoroughly as below.

---

# 2. Choose and install a secure FTP server

Two common servers:
- `vsftpd` — simple, secure by default, widely used
- `proftpd` — more feature rich, flexible, but complex

Install vsftpd:
```
dnf install vsftpd -y
systemctl enable --now vsftpd
```
Install ProFTPD:
```
dnf install proftpd -y
systemctl enable --now proftpd
```
For most cases prefer `vsftpd` for simplicity and security.

---

# 3. Basic vsftpd hardening (recommended defaults)

Edit `/etc/vsftpd/vsftpd.conf` and apply these core settings:
```
# Disable anonymous by default
anonymous_enable=NO

# Local users allowed to login
local_enable=YES

# Allow uploads only if explicitly permitted
write_enable=NO

# Chroot local users (isolate them)
chroot_local_user=YES
allow_writeable_chroot=NO

# Use TLS (explicit FTPS)
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=NO
ssl_sslv2=NO
ssl_sslv3=NO
```
Generate a certificate (self-signed for lab):
```
mkdir -p /etc/vsftpd/ssl
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/vsftpd/ssl/vsftpd.key -out /etc/vsftpd/ssl/vsftpd.crt -subj "/CN=ftp.example.local"
chmod 600 /etc/vsftpd/ssl/vsftpd.key
chown root:root /etc/vsftpd/ssl/vsftpd.*
```
Point vsftpd to the certs in `vsftpd.conf`:
```
rsa_cert_file=/etc/vsftpd/ssl/vsftpd.crt
rsa_private_key_file=/etc/vsftpd/ssl/vsftpd.key
```
Restart:
```
systemctl restart vsftpd
```

Always test TLS with an FTP client that supports explicit TLS (FTPES) and verify the certificate.

---

# 4. Passive vs Active FTP and firewall/NAT considerations

Passive mode is the norm for clients behind NAT. You must configure a passive port range and open it in the firewall.

vsftpd.conf settings:
```
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
pasv_address=203.0.113.10    # public IP if behind NAT
```
Open ports in firewalld:
```
firewall-cmd --zone=public --add-port=21/tcp --permanent
firewall-cmd --zone=public --add-port=40000-40100/tcp --permanent
firewall-cmd --reload
```
If NAT, ensure port forward rules map the passive range and control access to only required clients.

---

# 5. Enforce TLS and disable insecure fallbacks

Force encrypted control and data channels:
```
force_local_logins_ssl=YES
force_local_data_ssl=YES
```
Disable anonymous TLS and weak protocols (already shown). Restrict ciphers if server supports configuration. Test with `openssl s_client` and FTP clients.

Check TLS negotiation by capturing a client session with `tcpdump` or using `lftp -d`.

---

# 6. User isolation and chrooting

Chroot prevents users from escaping their home directories. For vsftpd:
```
chroot_local_user=YES
allow_writeable_chroot=NO
```
If users need write access inside chroot, create a writable subdirectory and set its owner appropriately. Example:
```
mkdir -p /home/alice/ftp/uploads
chown nobody:nogroup /home/alice/ftp
chown alice:alice /home/alice/ftp/uploads
chmod 755 /home/alice/ftp
```
This avoids writable chroot root directory, which newer vsftpd refuses unless `allow_writeable_chroot=YES` is set (avoid setting it unless necessary).

---

# 7. Virtual users vs system users

For public FTP sites, use virtual users mapped to a single system account to avoid creating many real Linux accounts.

vsftpd can use `pam_userdb` or `db4` for virtual users. High level steps:
1. Create a Berkeley DB of users:
```
echo -e "alice
secret" > /tmp/virtusers.txt
# format: user\npassword
db_load -T -t hash -f /tmp/virtusers.txt /etc/vsftpd/virtusers.db
chmod 600 /etc/vsftpd/virtusers.db
```
2. Configure PAM `/etc/pam.d/vsftpd-virtual` to use `pam_userdb.so db=/etc/vsftpd/virtusers` and map them to an internal system user via `user_sub_token` and `guest_username=ftp` in `vsftpd.conf`.

Virtual users reduce attack surface on the OS account level and simplify management.

---

# 8. PAM and password policies

Ensure PAM stack enforces strong passwords and lockouts for FTP logins.

Edit `/etc/pam.d/vsftpd` to include `pam_pwquality.so` and `pam_faillock.so` rules similar to `sshd`:
```
# password quality
password requisite pam_pwquality.so try_first_pass local_users_only

# account lockout on repeated failures
auth required pam_faillock.so preauth silent deny=5 unlock_time=900
auth [default=die] pam_faillock.so authfail deny=5 unlock_time=900
```
Test lockouts and ensure that legitimate users are not inadvertently blocked.

---

# 9. SELinux considerations for FTP

SELinux enforces file contexts and booleans for FTP daemons. Check default contexts:
```
ls -Z /srv/ftp
semanage fcontext -l | grep ftp
```
Common booleans for vsftpd:
```
getsebool -a | grep ftp
# example
setsebool -P allow_ftpd_full_access off
setsebool -P ftpd_full_access off
```
If you need FTP to access user home directories:
```
setsebool -P ftp_home_dir on
```
For FTPS and passive ports, ensure SELinux allows the port range if constrained. Add custom ports if needed:
```
semanage port -a -t ftp_port_t -p tcp 40000-40100
```
Note: `semanage port -a` may require exact port entries; some SELinux versions do not support ranges — split if required.

---

# 10. Logging, monitoring, and alerting

Enable and monitor FTP logs — vsftpd logs to `/var/log/messages` by default or `/var/log/vsftpd.log` if configured.

Configure verbose logging in `vsftpd.conf`:
```
xferlog_enable=YES
log_ftp_protocol=YES
xferlog_std_format=NO
```
Forward logs to central SIEM and create alerts for:
- repeated failed login attempts
- anonymous access events (if enabled)
- large upload/download volumes
- unexpected client IPs

Use `fail2ban` to ban repeated failures. Example jail for vsftpd:
```
[vsftpd]
enabled = true
port = ftp,ftp-data,ftps
filter = vsftpd
logpath = /var/log/vsftpd.log
banaction = firewallcmd-ipset
maxretry = 5
```
Test ban by forcing failed logins and monitoring `fail2ban-client status vsftpd`.

---

# 11. Denial-of-service and abuse mitigation

FTP servers can be abused for bandwidth or connection exhaustion.

Mitigations:
- Limit passive port range tightly and monitor usage.
- Use connection limits in vsftpd (`max_clients` and `max_per_ip`):
```
max_clients=50
max_per_ip=5
```
- Use firewall rate limits for SYN and new connections via `nftables` or `firewalld` rich rules.
- Use ipset to block repeated offenders.
- Consider running FTP behind a reverse proxy or dedicated NAT with DDoS protections.

---

# 12. Anonymous FTP — avoid if possible, lock it down if required

If you must offer anonymous download:
```
anonymous_enable=YES
anon_root=/srv/ftp/pub
no_anon_password=YES
```
Ensure uploads are disabled, and the anonymous directory is read-only and owned by a non-privileged user. Monitor downloads with logging and quota.

---

# 13. Testing and validation

1. Test explicit TLS (FTPES) with `lftp` or FileZilla.
```
lftp -u alice,secret -e "set ftp:ssl-force true; set ftp:ssl-protect-data true; ls; bye" ftp://203.0.113.10
```
2. Test passive mode from behind NAT with a client behind another NAT.
3. Test chroot escape attempts by trying `cd ..` and uploading files to the root of chroot.
4. Test fail2ban bans and unbans.
5. Test SELinux denials with `ausearch -m avc -ts recent` and fix via `semanage fcontext`/`restorecon`.

---

# 14. Alternatives and migration strategy

If possible, migrate users to SFTP or HTTPS-based file transfer (WebDAV over HTTPS) or use secure file transfer platforms. For automation and scripting, prefer SCP/SFTP over FTP to avoid TLS complexity and passive-mode firewall issues.

---

# 15. Quick reference — commands you will actually use

```
# install vsftpd
dnf install vsftpd -y
systemctl enable --now vsftpd

# generate certs
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/vsftpd/ssl/vsftpd.key -out /etc/vsftpd/ssl/vsftpd.crt

# firewall for passive range
firewall-cmd --add-port=21/tcp --permanent
firewall-cmd --add-port=40000-40100/tcp --permanent
firewall-cmd --reload

# basic SELinux checks
getsebool -a | grep ftp
semanage port -a -t ftp_port_t -p tcp 40000-40100

# restart
systemctl restart vsftpd

# logs
tail -f /var/log/vsftpd.log /var/log/messages

# fail2ban status
fail2ban-client status vsftpd
```

---

# What you achieve after this file

You will be able to deploy and operate a hardened FTP service that uses explicit TLS, isolates users, integrates with PAM and SELinux correctly, limits passive ports and firewall exposure, resists tampering and DoS, and logs/alerts for suspicious activity. You will also know when to avoid FTP entirely and move users to SFTP or HTTPS-based solutions for better security and operational simplicity.
