#!/bin/bash
set -e

HOSTNAME=$(hostname -s)
BACKUP_DIR="/root/access_backup_$(date +%F_%H%M%S)"

mkdir -p "$BACKUP_DIR"

echo "[INFO] Taking backups..."
cp -a /etc/pam.d/sshd "$BACKUP_DIR/sshd.pam.bak"
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak"
cp -a /etc/sudoers.d "$BACKUP_DIR/sudoers.d.bak" 2>/dev/null || true

# ---------- PAM SSHD ----------
echo "[INFO] Applying PAM sshd rules..."

cat >/etc/pam.d/sshd <<'EOF'
#%PAM-1.0
auth       sufficient   pam_sss.so
auth       requisite    pam_deny.so

account    sufficient   pam_sss.so
account    required     pam_nologin.so

password   include      password-auth
session    include      password-auth
EOF

# ---------- SSHD CONFIG ----------
echo "[INFO] Enforcing AD-only SSH..."

sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

systemctl reload sshd

# ---------- SUDOERS ----------
echo "[INFO] Applying sudo RBAC..."

rm -f /etc/sudoers.d/linux-* || true

case "$HOSTNAME" in
  admin)
    cat >/etc/sudoers.d/linux-admin <<'EOF'
%Linux-Admin ALL=(ALL) ALL
EOF
    ;;
  devops-01|devops-02)
    cat >/etc/sudoers.d/linux-devops <<'EOF'
%Linux-ReadWrite ALL=(ALL) /usr/bin/systemctl, /usr/bin/journalctl
EOF
    ;;
  ai-01|ai-02)
    echo "[INFO] AI server — no sudoers applied"
    ;;
  *)
    echo "[WARN] Unknown host — no sudo applied"
    ;;
esac

chmod 440 /etc/sudoers.d/* 2>/dev/null || true

echo "[DONE] Access control applied safely."
