#!/bin/bash
set -e

PROFILE="TSS"

echo "[+] Creating custom authselect profile if not exists"

if [ ! -d /etc/authselect/custom/${PROFILE} ]; then
    authselect create-profile ${PROFILE} --base-on sssd
fi

echo "[+] Writing sshd PAM file into custom profile"

if [ ! -f /etc/pam.d/sshd.bkp ]; then
    cp /etc/pam.d/sshd /etc/pam.d/sshd.bkp
fi

cp /tmp/sshd.pam.template /etc/pam.d/sshd
chmod 644 /etc/pam.d/sshd

echo "[+] Selecting custom authselect profile"
authselect select custom/${PROFILE} --force

echo "[+] Applying authselect changes"
authselect apply-changes

echo "[+] Restarting services"
systemctl restart sssd sshd
systemctl enable --now oddjob-mkhomedir || true

echo "[✓] SSHD PAM + authselect configuration applied successfully"