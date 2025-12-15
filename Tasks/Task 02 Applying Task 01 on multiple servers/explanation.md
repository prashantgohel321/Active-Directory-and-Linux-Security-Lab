# Bootstrap Access Script — Line‑by‑Line Explanation

This document explains **exactly what the `bootstrap_access.sh` script does**, line by line, and *why each line exists*. If you can explain this file confidently, you actually understand Linux access control — otherwise you’re just executing commands blindly.

This script is a **temporary bootstrap** to enforce AD‑only SSH access and server‑wise RBAC. It prioritizes **safety (backups)** over elegance.

---

## Script Header & Execution Safety

```bash
#!/bin/bash
```

- Forces execution using **Bash**, not sh/dash/zsh
- Guarantees consistent behavior across servers
- Without this, the script may behave differently depending on the default shell

---

```bash
set -e
```

- **Fail fast mechanism**
- If *any* command exits with non‑zero status → script stops immediately
- This is critical for PAM/SSH work
- Prevents half‑applied authentication changes (which cause lockouts)

---

## Host Identity & Backup Strategy

```bash
HOSTNAME=$(hostname -s)
```

- Fetches **short hostname** (e.g. `ai-01`, `devops-02`)
- Used later to decide **which sudo policy applies**
- Temporary workaround instead of inventory‑driven logic

---

```bash
BACKUP_DIR="/root/access_backup_$(date +%F_%H%M%S)"
```

- Creates a **timestamped backup directory**
- Example:

```
/root/access_backup_2025-12-15_10:42:01
```

- Prevents overwriting old backups
- Enables rollback even after multiple executions

---

```bash
mkdir -p "$BACKUP_DIR"
```

- Creates the backup directory
- `-p` avoids errors if parent directories exist
- Script would fail early without this directory

---

## Backup Phase (Non‑Negotiable)

```bash
echo "[INFO] Taking backups..."
```

- Informational log for execution visibility
- Helps during Ansible output review

---

```bash
cp -a /etc/pam.d/sshd "$BACKUP_DIR/sshd.pam.bak"
```

- Backs up the **existing PAM SSH stack**
- `-a` preserves permissions and SELinux context
- This is the **most critical backup** in the script

---

```bash
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak"
```

• Backs up SSH daemon configuration
• Allows rollback if SSH stops accepting connections

---

```bash
cp -a /etc/sudoers.d "$BACKUP_DIR/sudoers.d.bak" 2>/dev/null || true
```

• Backs up **all sudo RBAC rules**
• Errors suppressed because directory may be empty
• `|| true` prevents `set -e` from exiting

---

## PAM SSHD Enforcement (Core Authentication Logic)

```bash
echo "[INFO] Applying PAM sshd rules..."
```

• Explicit phase boundary
• Useful when troubleshooting SSH failures

---

```bash
cat >/etc/pam.d/sshd <<'EOF'
```

• Overwrites `/etc/pam.d/sshd` completely
• `<<'EOF'` prevents variable expansion (safe heredoc)
• Guarantees **deterministic PAM behavior**

---

```bash
#%PAM-1.0
```

• Mandatory PAM file header
• Signals PAM parser to treat this as a valid config

---

```bash
auth       sufficient   pam_sss.so
```

• If authentication succeeds via **SSSD (AD)** → allow immediately
• No further auth rules are evaluated
• This is what enables **AD‑only SSH**

---

```bash
auth       requisite    pam_deny.so
```

• Any authentication that reaches this line is **denied**
• Local Linux users fail here
• Guarantees local users cannot SSH

---

```bash
account    sufficient   pam_sss.so
```

• Account validation via AD
• If AD account is valid → continue session

---

```bash
account    required     pam_nologin.so
```

• Blocks login if `/etc/nologin` exists
• Standard system safety control

---

```bash
password   include      password-auth
session    include      password-auth
```

• Delegates password & session handling to system defaults
• Keeps:
• password expiry
• SELinux sessions
• environment setup
• Prevents breaking `su` and console login

---

```bash
EOF
```

• Ends heredoc block
• PAM SSH rules are now fully replaced

---

## SSH Daemon Sanity Enforcement

```bash
echo "[INFO] Enforcing AD-only SSH..."
```

• Execution visibility

---

```bash
sed -i 's/^#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
```

• Ensures SSH actually uses PAM
• Without this, PAM rules are ignored
• Required for AD authentication

---

```bash
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
```

• Enables password authentication
• Required for Kerberos/SSSD flows
• Does NOT allow local users due to PAM deny rule

---

```bash
systemctl reload sshd
```

• Reloads SSH configuration safely
• Does NOT drop existing SSH sessions
• Required to activate new PAM + SSH config

---

## Sudo RBAC Enforcement (Authorization)

```bash
echo "[INFO] Applying sudo RBAC..."
```

• Marks transition from authentication to authorization

---

```bash
rm -f /etc/sudoers.d/linux-* || true
```

• Removes old RBAC rules managed by this script
• Ensures clean state
• `|| true` prevents script exit if no files exist

---

```bash
case "$HOSTNAME" in
```

• Branches sudo policy **based on server identity**
• Temporary replacement for Ansible inventory logic

---

### Admin Server Policy

```bash
admin)
```

• Matches `admin` hostname

```bash
cat >/etc/sudoers.d/linux-admin <<'EOF'
%Linux-Admin ALL=(ALL) ALL
EOF
```

• Grants **full sudo** to AD group `Linux-Admin`
• No individual users
• Clean RBAC

---

### DevOps Server Policy

```bash
devops-01|devops-02)
```

• Matches DevOps servers explicitly

```bash
cat >/etc/sudoers.d/linux-devops <<'EOF'
%Linux-ReadWrite ALL=(ALL) /usr/bin/systemctl, /usr/bin/journalctl
EOF
```

• Grants **limited operational sudo**
• No package installs, no disk ops
• Principle of least privilege

---

### AI Server Policy

```bash
ai-01|ai-02)
```

• Matches AI servers

```bash
echo "[INFO] AI server — no sudoers applied"
```

• No sudo rules at all
• Read‑only access enforced naturally

---

### Unknown Host Safety

```bash
*)
  echo "[WARN] Unknown host — no sudo applied"
  ;;
```

• Prevents accidental privilege grants
• Safe default behavior

---

```bash
esac
```

• Ends hostname‑based RBAC logic

---

```bash
chmod 440 /etc/sudoers.d/* 2>/dev/null || true
```

• Enforces correct sudoers permissions
• Prevents sudo from refusing files
• Suppresses errors if directory is empty

---

## Script Completion

```bash
echo "[DONE] Access control applied safely."
```

• Final confirmation
• Useful for Ansible logs and audits

---

## Final Reality Check

• This script is **safe**, not elegant
• Hostname‑based logic is **temporary technical debt**
• Backups make rollback possible
• PAM logic is strict and deterministic

This script buys **time**, not perfection.
The proper Ansible role‑based refactor will replace it later.

You now fully own this script.
