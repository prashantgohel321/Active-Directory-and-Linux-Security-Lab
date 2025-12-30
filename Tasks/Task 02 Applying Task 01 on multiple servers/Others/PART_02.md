# Part 02 – Automated Rollout Using Ansible (Inventory & Playbook Design)

## Purpose of This Phase

After completing the SSH access control and RBAC foundation in Part 01, the next logical step was to make the entire setup **scalable and repeatable**. The real requirement was not to configure one or two servers manually, but to apply the same controls consistently across many servers.

This part focuses on **how I automated the rollout using Ansible**, how the inventory was structured, how the playbook was designed, and why the execution flow looks the way it does. The idea was to simulate a real enterprise environment where dozens or even hundreds of servers must be managed with the same security baseline.

---

## Why Ansible Was the Right Choice

I chose Ansible because it is agentless, easy to audit, and very commonly used in enterprise Linux environments. From a security perspective, it allows central enforcement of policies without logging into each server manually.

Another important reason was separation of concerns. The shell scripts handle *what* needs to be configured on a server, while Ansible handles *where* and *how* those scripts are executed. This makes troubleshooting easier and keeps responsibilities clear.

---

## Inventory Design (hosts.ini)

The inventory file is where I defined the server groups. Instead of listing all servers under a single group, I grouped them by **role**. This decision directly supports RBAC.

Each server belongs to exactly one role group:

* AI servers are grouped under `server-ai`
* DevOps servers are grouped under `server-devops`
* Admin servers are grouped under `server-admin`

This grouping allows Ansible to apply different logic to different servers without changing the scripts themselves. The same playbook can behave differently based on group membership.

The inventory also defines common connection variables, such as the SSH user and private key. These are defined once and reused for all servers, which keeps the configuration clean and avoids duplication.

Although some Active Directory–related variables are present in the inventory, they were intentionally not used during this phase. They are placeholders for the next stage, where domain integration will be automated.

---

## Playbook Structure (apply_changes.yml)

The playbook was written in multiple plays, each with a very specific responsibility. I avoided combining everything into a single large play because clarity and control are more important than compactness in production automation.

The first play targets **all servers**. This play is responsible for preparing the system and applying the SSH access control logic. It installs the required packages, copies the SSH/PAM configuration script, and executes it. Since SSH access control must be consistent everywhere, this play runs uniformly across all hosts.

Separating this logic into a single play ensures that every server, regardless of role, follows the same authentication baseline.

---

## Role-Specific Execution

After the common baseline is applied, the playbook moves into role-specific plays.

For AI servers, no sudo configuration is applied. This is intentional. These servers are meant to have read-only access, so the play simply logs that no sudoers configuration is required. This explicit step makes the intent clear to anyone reading the playbook later.

For DevOps servers, the playbook copies the sudoers setup script and runs it with the `devops` argument. This applies the limited operational permissions defined earlier. The same script is reused without modification, which keeps the logic centralized and consistent.

For Admin servers, the same sudoers script is copied and executed with the `admin` argument. This grants full administrative access to the appropriate group. Keeping Admin logic separate from DevOps logic reduces the risk of accidental privilege overlap.

---

## Why Scripts Are Copied Per Role

One important lesson during this phase was that each server group is isolated from the others. Copying a script to one group does not make it available to another. This behavior is intentional and aligns with Ansible’s design.

By explicitly copying the sudoers script in both the DevOps and Admin plays, I ensured that each server had the required files locally before execution. This avoids hidden dependencies and makes the playbook easier to reason about.

---

## Issues Encountered During Automation

During testing on AWS, I observed behavior that initially appeared to violate RBAC rules. Package installation was still possible on DevOps servers. After investigation, this turned out to be caused by the default AWS `ec2-user` account, which is granted full sudo privileges by cloud-init.

This issue was not related to Ansible or sudoers logic. It was an environment-specific artifact of cloud infrastructure. In an on-prem environment, where users authenticate via Active Directory and no bootstrap cloud user exists, this behavior does not occur.

This reinforced the importance of understanding the execution environment when validating security controls.

---

## Validation and Idempotency

Once the playbook executed successfully, I validated the results by checking the active authselect profile, verifying the SSH PAM stack, and testing sudo behavior on each server type.

I also re-ran the playbook to confirm idempotency. The fact that subsequent runs completed without errors or unexpected changes confirmed that the automation is safe to use repeatedly.

---

## Final Outcome of Part 02

By the end of this phase, I had a working automation pipeline that:

* Applies SSH access control consistently across servers
* Enforces RBAC based on server role
* Scales cleanly from a few servers to many
* Separates logic, configuration, and execution clearly

Together with Part 01, this completes a full foundation for secure Linux access management that can be extended to Active Directory integration without redesigning the system.
