Command to run:
```bash
ansible-playbook apply_changes.yml -e group=lnx_security

# OR
# if using custom inventory file then...
ansible-playbook -i hosts.ini apply_changes.yml -e group=lnx_security

# Specifying specific host
ansible-playbook -l myHost -i hosts.ini apply_changes.yml -e group=lnx_security
```