#!/bin/bash

# ===== VARIABLES =====
DOMAIN="gohel.local"
REALM="GOHEL.LOCAL"
DC_IP="192.168.84.130"        
AD_ADMIN="Administrator"      # AD admin user
HOSTNAME="$(hostname -s).${DOMAIN}"

# ===== PRECHECK =====
if [[ $EUID -ne 0 ]]; then
  echo "Run as root"
  exit 1
fi

echo "[+] Setting hostname"
hostnamectl set-hostname "$HOSTNAME"

echo "[+] Setting DNS to Domain Controller"
nmcli con mod "$(nmcli -t -f NAME con show --active)" ipv4.dns "$DC_IP"
nmcli con mod "$(nmcli -t -f NAME con show --active)" ipv4.ignore-auto-dns yes
nmcli con up "$(nmcli -t -f NAME con show --active)"

echo "[+] Installing required packages"
dnf install -y realmd sssd adcli oddjob oddjob-mkhomedir \
               samba-common-tools krb5-workstation authselect

echo "[+] Discovering domain"
realm discover "$DOMAIN" || exit 1

echo "[+] Joining domain"
realm join "$DOMAIN" -U "$AD_ADMIN" || exit 1

echo "[+] Enabling SSSD + mkhomedir"
authselect select sssd with-mkhomedir --force

echo "[+] Restarting services"
systemctl restart sssd
systemctl enable sssd

echo "[+] Domain join complete"
realm list
