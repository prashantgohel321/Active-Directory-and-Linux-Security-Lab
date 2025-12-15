#!/bin/bash
set -e

PROFILE=myprofile

# Create custom authselect profile if missing
if [ ! -d /etc/authselect/custom/$PROFILE ]; then
  authselect create-profile $PROFILE --base-on sssd
fi

# Copy sshd PAM file
cat << EOF > /etc/authselect/custom/$PROFILE/sshd
#%PAM-1.0

auth       sufficient   pam_sss.so
auth       substack     password-auth
auth       include      postlogin

account    required     pam_sepermit.so
account    required     pam_nologin.so
account    [success=1 default=ignore] pam_sss.so # CHANGE
account    requisite    pam_deny.so # CHANGE
account    include      password-auth

password   include      password-auth

session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_keyinit.so force revoke
session    required     pam_selinux.so open env_params
session    include      password-auth
session    include      postlogin
EOF

# Apply profile
authselect select custom/$PROFILE --force
authselect apply-changes

# Restart services
systemctl restart sssd sshd
systemctl enable --now oddjob-mkhomedir || true

echo "SSHD + PAM configuration applied successfully"
