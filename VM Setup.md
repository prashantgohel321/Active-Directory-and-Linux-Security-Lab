# Post‑VM Configuration Checklist (Rocky Linux)

- [Post‑VM Configuration Checklist (Rocky Linux)](#postvm-configuration-checklist-rocky-linux)
  - [1. Initial SSH Login](#1-initial-ssh-login)
    - [Step](#step)
    - [First‑time connection prompt](#firsttime-connection-prompt)
  - [2. Basic Disk \& System Verification](#2-basic-disk--system-verification)
    - [Check disk usage](#check-disk-usage)
    - [Check block devices](#check-block-devices)
  - [3. Partition the New Disk](#3-partition-the-new-disk)
    - [Wrong command (common mistake)](#wrong-command-common-mistake)
    - [Correct command](#correct-command)
    - [Inside fdisk](#inside-fdisk)
  - [4. Create LVM Structure](#4-create-lvm-structure)
    - [Create Physical Volume](#create-physical-volume)
    - [Create Volume Group](#create-volume-group)
    - [Create Logical Volume](#create-logical-volume)
  - [5. Format \& Mount Disk](#5-format--mount-disk)
    - [Format filesystem](#format-filesystem)
    - [Create mount directory](#create-mount-directory)
    - [Mount manually](#mount-manually)
    - [Verify](#verify)
  - [6. Persistent Mount (/etc/fstab)](#6-persistent-mount-etcfstab)
    - [Edit fstab](#edit-fstab)
    - [Reload systemd (important)](#reload-systemd-important)
    - [Test fstab](#test-fstab)
  - [7. Domain Join (AD / Realm)](#7-domain-join-ad--realm)
    - [Initial attempt](#initial-attempt)
    - [Common Issues \& Fixes](#common-issues--fixes)
      - [❌ SSL / certificate errors](#-ssl--certificate-errors)
      - [❌ Required packages missing](#-required-packages-missing)
    - [Final successful join](#final-successful-join)
    - [Verify](#verify-1)
  - [8. SSSD Post Configuration](#8-sssd-post-configuration)
    - [Edit config](#edit-config)
    - [Permissions are mandatory](#permissions-are-mandatory)
    - [Restart service](#restart-service)
  - [9. Install Docker](#9-install-docker)
    - [Install plugins](#install-plugins)
    - [Add Docker repo](#add-docker-repo)
    - [Install Docker](#install-docker)
    - [Start \& enable](#start--enable)
    - [Add user to docker group](#add-user-to-docker-group)
  - [10. Move Docker Data to /datadisk](#10-move-docker-data-to-datadisk)
    - [Stop Docker](#stop-docker)
    - [Move data directories](#move-data-directories)
    - [Create symlinks](#create-symlinks)
    - [Start Docker](#start-docker)
  - [11. Install Terraform](#11-install-terraform)
    - [Install yum utils](#install-yum-utils)
    - [Add HashiCorp repo](#add-hashicorp-repo)
    - [Install Terraform](#install-terraform)
    - [Verify](#verify-2)
  - [12. Password‑less Docker \& Terraform (Wrapper Method)](#12-passwordless-docker--terraform-wrapper-method)
    - [Wrapper scripts](#wrapper-scripts)
      - [`/usr/local/bin/docker`](#usrlocalbindocker)
      - [`/usr/local/bin/terraform`](#usrlocalbinterraform)
    - [Make executable](#make-executable)
    - [Sudoers entries](#sudoers-entries)
      - [`/etc/sudoers.d/docker`](#etcsudoersddocker)
      - [`/etc/sudoers.d/terraform`](#etcsudoersdterraform)
  - [13. Final System Update](#13-final-system-update)
  - [14. Reboot (Mandatory)](#14-reboot-mandatory)
  - [✅ Final Verification Checklist](#-final-verification-checklist)


---

<br>
<br>

## 1. Initial SSH Login

### Step

Connect from jump host / laptop.

```bash
ssh root@<VM_IP>
```

### First‑time connection prompt

```text
Are you sure you want to continue connecting (yes/no)? yes
```

✔ Adds host key to `~/.ssh/known_hosts`

---

<br>
<br>

## 2. Basic Disk & System Verification

### Check disk usage

```bash
df -h
```

### Check block devices

```bash
lsblk
```

✔ Identify:

* OS disk (`sda`)
* New raw disk (`sdb`)

---

<br>
<br>

## 3. Partition the New Disk

### Wrong command (common mistake)

```bash
fdisk sdb
```

❌ Fails because full path not given

### Correct command

```bash
fdisk /dev/sdb
```

### Inside fdisk

```text
n   → new partition
p   → primary
<enter> <enter> → full size
t   → change type
8e  → Linux LVM
w   → write
```

Verify:

```bash
lsblk
```

---

<br>
<br>

## 4. Create LVM Structure

### Create Physical Volume

```bash
pvcreate /dev/sdb1
```

### Create Volume Group

```bash
vgcreate rl2 /dev/sdb1
```

### Create Logical Volume

```bash
lvcreate -l 100%FREE -n datadisk rl2
```

---

<br>
<br>

## 5. Format & Mount Disk

### Format filesystem

```bash
mkfs.ext4 /dev/rl2/datadisk
```

### Create mount directory

```bash
mkdir /datadisk
```

### Mount manually

```bash
mount /dev/rl2/datadisk /datadisk
```

### Verify

```bash
df -h
```

---

<br>
<br>

## 6. Persistent Mount (/etc/fstab)

### Edit fstab

```bash
vi /etc/fstab
```

Example entry:

```text
/dev/mapper/rl2-datadisk  /datadisk  ext4  defaults  0 0
```

### Reload systemd (important)

```bash
systemctl daemon-reload
```

### Test fstab

```bash
umount /datadisk
mount -a
df -h
```

---

<br>
<br>

## 7. Domain Join (AD / Realm)

### Initial attempt

```bash
realm join TSS.COM -U <user> -v
```

### Common Issues & Fixes

#### ❌ SSL / certificate errors

Cause: internal repos using self‑signed certs

Fix:

```bash
cp foreman_katello.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
```

#### ❌ Required packages missing

Packages needed:

```text
oddjob
eoddjob-mkhomedir
sssd
adcli
```

Realm auto‑installs if repos are working.

### Final successful join

```bash
realm join TSS.COM -U <user> -v
```

### Verify

```bash
realm list
```

---

<br>
<br>

## 8. SSSD Post Configuration

### Edit config

```bash
vi /etc/sssd/sssd.conf
```

### Permissions are mandatory

```bash
chmod 600 /etc/sssd/sssd.conf
```

### Restart service

```bash
systemctl restart sssd
```

---

<br>
<br>

## 9. Install Docker

### Install plugins

```bash
dnf install -y dnf-plugins-core
```

### Add Docker repo

```bash
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
```

### Install Docker

```bash
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Start & enable

```bash
systemctl start docker
systemctl enable docker
```

### Add user to docker group

```bash
usermod -aG docker <user>
```

---

<br>
<br>

## 10. Move Docker Data to /datadisk

### Stop Docker

```bash
systemctl stop docker
```

### Move data directories

```bash
mv /var/lib/containerd /datadisk/
mv /var/lib/containers /datadisk/
mv /var/lib/docker /datadisk/
```

### Create symlinks

```bash
ln -s /datadisk/containerd /var/lib/containerd
ln -s /datadisk/containers /var/lib/containers
ln -s /datadisk/docker /var/lib/docker
```

### Start Docker

```bash
systemctl start docker
```

---

<br>
<br>

## 11. Install Terraform

### Install yum utils

```bash
dnf install -y yum-utils
```

### Add HashiCorp repo

```bash
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
```

### Install Terraform

```bash
yum install -y terraform
```

### Verify

```bash
terraform version
```

---

<br>
<br>

## 12. Password‑less Docker & Terraform (Wrapper Method)

### Wrapper scripts

#### `/usr/local/bin/docker`

```bash
#!/usr/bin/env sh
exec sudo /usr/bin/docker "$@"
```

#### `/usr/local/bin/terraform`

```bash
#!/usr/bin/env sh
exec sudo /usr/bin/terraform "$@"
```

### Make executable

```bash
chmod +x /usr/local/bin/docker /usr/local/bin/terraform
```

### Sudoers entries

#### `/etc/sudoers.d/docker`

```text
%DPT_Developers@TSS.COM ALL=(root) NOPASSWD: /usr/bin/docker
```

#### `/etc/sudoers.d/terraform`

```text
%DPT_Developers@TSS.COM ALL=(root) NOPASSWD: /usr/bin/terraform
```

---

<br>
<br>

## 13. Final System Update

```bash
dnf update -y
```

---

## 14. Reboot (Mandatory)

```bash
reboot
```

---

<br>
<br>

## ✅ Final Verification Checklist

* [ ] Disk mounted at `/datadisk`
* [ ] fstab working
* [ ] Realm joined
* [ ] SSSD running
* [ ] Docker running after reboot
* [ ] Docker data on `/datadisk`
* [ ] Terraform works without password
* [ ] No SSL repo errors

---


