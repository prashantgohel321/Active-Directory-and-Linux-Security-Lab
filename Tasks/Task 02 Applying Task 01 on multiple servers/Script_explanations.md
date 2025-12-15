# Appendix – Line-by-Line Explanation of Automation Files

This document explains each final working file **line by line**, in plain language. The intention is not just to describe *what* a line does, but *why* it exists in the overall design. I wrote this as a reference that I can use later for revision, audits, or explanation to others.

---

## 1. `sshd_pam_fix.sh`

This script is responsible for SSH access control using PAM and authselect.

```bash
#!/bin/bash
# This tells the system to execute the script using the Bash shell.
```



```bash
set -e
# script exits immediately if any command fails
# important in automation so that partial or inconsistent configuration is avoided
```

```bash
# Here I check whether the custom authselect profile already exists. If it does not, I create it based on the default `sssd` profile. This makes the script idempotent and safe to run multiple times.

if [ ! -d /etc/authselect/custom/${PROFILE} ]; then
    authselect create-profile ${PROFILE} --base-on sssd
fi
```

```bash
cat << EOF > /etc/authselect/custom/${PROFILE}/sshd
```

This starts a here-document that writes the SSH PAM stack directly into the custom authselect profile. Writing here ensures the configuration is managed by authselect rather than manually editing system files.

```bash
EOF
```

This ends the here-document.

```bash
# This activates the custom authselect profile and forces replacement of the current configuration.
authselect select custom/${PROFILE} --force
```

```bash
# This applies the profile contents to the system PAM configuration.
authselect apply-changes
```

```bash
# This enables automatic home directory creation if the service exists. The `|| true` ensures the script does not fail if the service is not present.

systemctl enable --now oddjob-mkhomedir || true
```


---

<br>
<br>

## 2. `sudoers_setup.sh`

This script configures sudo access based on the server role.

```bash
ROLE="$1"
```

Reads the server role from the first command-line argument.

```bash
if [ -z "$ROLE" ]; then
  echo "Usage: sudoers_setup.sh <ai|devops|admin>"
  exit 1
fi
```

This validates that a role was provided and prevents accidental execution without context.

```bash
echo "[+] Cleaning old sudoers files"
rm -f /etc/sudoers.d/linux-*
```

This removes any previously applied RBAC sudoers files to ensure a clean state.

```bash
if [ "$ROLE" = "admin" ]; then
```

Checks if the role is admin.

```bash
cat << EOF > /etc/sudoers.d/linux-admin
%Linux-Admin ALL=(ALL:ALL) ALL
EOF
```

Grants full sudo access to the `Linux-Admin` group.

```bash
if [ "$ROLE" = "devops" ]; then
```

Checks if the role is devops.

```text
Cmnd_Alias RW_CMNDS = /usr/bin/systemctl, /usr/bin/journalctl
```

Defines allowed operational commands.

```text
Cmnd_Alias SW_MGMT  = /bin/rpm, /usr/bin/dnf, /usr/bin/up2date
Cmnd_Alias STR_FS   = /sbin/fdisk, /sbin/sfdisk, /bin/mount, /bin/umount
Cmnd_Alias SYS_CTRL = /usr/sbin/reboot, /usr/sbin/shutdown
Cmnd_Alias NET_CFG  = /sbin/iptables, /sbin/ifconfig
Cmnd_Alias DELEG    = /usr/sbin/visudo, /usr/bin/chmod, /usr/bin/chown
```

These aliases define explicitly denied command categories.

```text
Cmnd_Alias RW_DENY = SW_MGMT, STR_FS, SYS_CTRL, NET_CFG, DELEG
```

Combines all denied commands into a single alias.

```text
%Linux-ReadWrite ALL=(ALL:ALL) RW_CMNDS, !RW_DENY
```

Allows operational commands while explicitly denying sensitive ones.

```bash
chmod 440 /etc/sudoers.d/*
```

Secures the sudoers files with correct permissions.

```bash
visudo -cf /etc/sudoers.d/*
```

Validates the syntax to prevent sudo breakage.

---

## 3. `apply_changes.yml`

This Ansible playbook orchestrates execution across servers.

```yaml
- name: Apply SSHD PAM and authselect (all servers)
  hosts: all
  become: yes
```

Defines a play that runs on all servers with root privileges.

```yaml
- name: Install required packages
```

Ensures required packages are present before applying configuration.

```yaml
- name: Copy sshd_pam_fix.sh
```

Copies the SSH/PAM script to each server.

```yaml
- name: Apply SSHD PAM changes
```

Executes the script locally on each server.

```yaml
- name: Apply sudoers on AI servers (no sudo)
```

Defines a play that explicitly does nothing for AI servers, documenting intent.

```yaml
- name: Apply sudoers on DevOps servers
```

Applies RBAC sudo rules to DevOps servers.

```yaml
- name: Apply sudoers on Admin servers
```

Applies full sudo rules to Admin servers.

Each play is intentionally separated to maintain clarity and avoid accidental privilege overlap.

---

## 4. `hosts.ini`

This file defines inventory groups and connection details.

```ini
[server-ai]
ai     ansible_host=13.201.192.232
```

Defines the AI server group and its host.

```ini
[server-devops]
devops ansible_host=13.204.43.31
```

Defines the DevOps server group.

```ini
[server-admin]
admin     ansible_host=13.233.121.222
```

Defines the Admin server group.

```ini
[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/ansible_practice.pem
```

Defines common SSH connection variables for all servers.

Additional AD-related variables are included as placeholders for future automation and were not actively used in this phase.

---

## Final Note

Together, these four files form a complete, modular, and production-aligned automation solution. Each file has a single responsibility, and together they enforce secure access, RBAC, and scalable deployment without relying on manual configuration.
