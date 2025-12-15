# Part 01 – SSH Access Control & RBAC Foundations (PAM + Sudoers)

## Task Overview

In this task, my goal was to design and implement a **secure and enterprise-aligned access control model** on Linux servers. The primary focus was on two things:

First, controlling **who is allowed to log in via SSH**, with a clear rule that *local users must not be allowed to SSH*, while future AD users should be allowed. Second, implementing **role-based access control (RBAC)** using sudo, where permissions are assigned strictly based on roles and groups, not individual users.

I intentionally separated this work into two layers:

* Authentication and access enforcement (PAM + authselect)
* Authorization and command control (sudoers)

This separation mirrors how things are handled in real enterprise environments.

---

## Why I Chose a Custom authselect Profile

Instead of modifying system PAM files directly, I created a **custom authselect profile based on the default SSSD profile**. This decision was deliberate.

Directly editing files like `/etc/pam.d/sshd` or `system-auth` is risky because those files can be overwritten by system updates or configuration tools. Using authselect allows me to make controlled, repeatable changes that survive updates and can be deployed consistently across servers.

I based my custom profile on `sssd` because the long-term design assumes Active Directory integration. Even though domain join was not performed during this phase, the PAM logic was designed with AD users in mind from the beginning.

---

## SSH Access Control Logic (PAM Design)

The main security requirement was simple but strict:

* Local users must **not** be allowed to log in via SSH
* SSH access must be reserved for directory-based users (SSSD / AD)
* Console login and `su` for local users should still work

To achieve this, I created a custom PAM stack for `sshd` inside the authselect profile.

### sshd_pam_fix.sh – What This Script Does

This script is responsible for creating and activating the custom authselect profile and enforcing the SSH PAM rules.

At the beginning, the script checks whether the custom profile already exists. If it does not, it creates one based on the `sssd` profile. This makes the script safe to run multiple times without breaking anything.

Once the profile exists, the script writes a **custom `sshd` PAM file** into the profile directory. This file defines exactly how SSH authentication and account validation should work.

The most important part of the PAM logic is the account phase:

* `pam_sss.so` is evaluated first. If the user is known to SSSD (future AD user), access continues.
* If SSSD does not recognize the user, the flow immediately hits `pam_deny.so`.

This single decision point ensures that **local users are denied SSH access**, while directory users are allowed.

After writing the PAM file, the script selects the custom authselect profile, applies the changes, and restarts the required services. I made the `oddjob-mkhomedir` service optional using `|| true` because home directory creation is only relevant once AD users start logging in.

This approach avoided unnecessary failures while still keeping the script production-safe.

---

## Role-Based Access Control with sudo

Once SSH access control was in place, the next step was defining **what users can do after they log in**. For this, I implemented RBAC using sudo.

The roles were intentionally simple:

* **AI servers**: Read-only access, no sudo at all
* **DevOps servers**: Limited operational access (services and logs), but no system-level changes
* **Admin servers**: Full administrative access

Permissions were tied strictly to **groups**, not users. This aligns with enterprise RBAC models and avoids privilege sprawl.

### sudoers_setup.sh – What This Script Does

This script applies sudo rules based on the role of the server. It takes the role as an argument (`ai`, `devops`, or `admin`) and configures sudo accordingly.

Before applying new rules, the script removes any existing `linux-*` sudoers files to ensure a clean state. This prevents old or conflicting permissions from lingering.

For admin servers, the logic is straightforward: members of the `Linux-Admin` group receive full sudo access.

For DevOps servers, the logic is more controlled. I defined command aliases that explicitly allow operational commands like `systemctl` and `journalctl`, while denying package management, filesystem manipulation, networking changes, and privilege-delegation commands.

The deny list is just as important as the allow list. Even if someone tries to bypass restrictions, sudo explicitly blocks those commands.

After writing the sudoers file, permissions are locked down, and the configuration is validated using `visudo`. This ensures syntax errors are caught immediately.

AI servers intentionally receive no sudoers configuration at all, because their role does not require elevated privileges.

---

## Issues Encountered and How I Solved Them

During testing on AWS, I observed that package installation was still working on DevOps servers, even though it should have been denied. After investigation, I found that this behavior was caused by the default `ec2-user` account.

On AWS, `ec2-user` is automatically granted full passwordless sudo via a cloud-init file. Because sudo stops at the first matching rule, my RBAC rules were never evaluated.

This was not a design flaw. It was an environment-specific behavior unique to AWS.

Once I identified this, the conclusion was clear: in real on-prem environments, where users authenticate via AD and no cloud bootstrap account exists, this issue does not occur. The RBAC logic itself was correct.

This reinforced an important real-world lesson: **RBAC must always be tested with the same class of users that will exist in production**.

---

## Final Outcome of Part 01

At the end of this task, I achieved the following:

* SSH access is controlled via PAM using a custom authselect profile
* Local users are blocked from SSH without affecting console or `su`
* RBAC is enforced via sudo using group-based rules
* The solution is automated, repeatable, and safe for large-scale deployment

This forms the foundation for integrating Active Directory in the next phase, without requiring redesign or rework.
