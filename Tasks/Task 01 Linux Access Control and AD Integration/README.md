<h1> Requirements for Linux Access Control & AD Integration</h1>

- [1. Local User Access Restrictions](#1-local-user-access-restrictions)
- [2. Active Directory Integration](#2-active-directory-integration)
- [3. Access Roles (RBAC Model)](#3-access-roles-rbac-model)
- [4. Sudoers and Access Control Implementation](#4-sudoers-and-access-control-implementation)
- [5. Documentation \& Change Control](#5-documentation--change-control)



## 1. Local User Access Restrictions

- 1.1 Local user logins must be denied, including the root account (except for emergency access via console/DRAC/iLO/IPMI).
- 1.2 The root account should be locked for remote login (SSH disabled).
- 1.3 Local service accounts may exist, but must:
    - Not be allowed interactive login
    - Be restricted to system services only


## 2. Active Directory Integration

- 2.1 Linux servers must be integrated with Active Directory (AD) using SSSD.
- 2.2 Only AD users must be allowed to log in to the system.
- 2.3 Authentication and user/group information must be resolved from AD.
- 2.4 All access control decisions (sudo rights, login permission, roles) must rely on AD security groups, not individuals.


## 3. Access Roles (RBAC Model)

Access to Linux servers must be divided into three roles:

- 3.1 Read-Only Role
	- Default access for all AD users.
	- Basic commands only.
	- No ability to modify system or users files or configurations.

- 3.2 Read-Write Role
	- Elevated access for service operations teams or owner of server.
	- Allow management of services, logs, and routine operations.
	- Restrict:
        - System admin commands
        - OS-level config files
        - Package installation/removal
        - Kernel-level operations

- 3.3 Admin Role
	- Full system administrator privileges.
	- Assigned only to internal Linux Admin AD group.
	- Unlimited sudo access.

## 4. Sudoers and Access Control Implementation

- 4.1 Sudo rules must be assigned based exclusively on AD groups. No individual user access is allowed.
- 4.2 Sudo policies must be centrally managed (e.g., sudoers.d files with group rules).
- 4.3 Separation between command sets for each role must be enforced:
    - Read-Only: No sudo privileges
    - Read-Write: Limited sudo command set
    - Admin: Full sudo privileges


## 5. Documentation & Change Control
- 5.1 Maintain documentation for:
    - AD integration steps
    - Sudo group mappings
    - Role permissions
    - Server onboarding process