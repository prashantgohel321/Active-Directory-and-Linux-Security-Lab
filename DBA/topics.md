# PostgreSQL Learning Roadmap (DevOps / Linux Admin Perspective)

This repository is structured to match how PostgreSQL is learned and used in real environments. Each folder contains:

* Concept explanations (what, why, how)
* Commands and configs
* One real-world practice lab that simulates production-like work

---

## 01-postgresql-architecture-basics

- 01 architecture-overview.md
- 02 process-architecture.md
- 03 memory-architecture.md
- 04 disk-layout.md
- 05 system-catalogs-overview.md

- lab-understand-postgresql-internals.md

---

## 02-installation-and-environment-setup

- postgresql-installation-linux.md
- directory-structure.md
- initdb-cluster-initialization.md
- service-management.md
- psql-connection-basics.md

lab-install-and-initialize-postgresql.md

---

## 03-configuration-basics

- postgresql-conf-explained.md
- pg-hba-conf-explained.md
- pg-ident-conf-explained.md
- important-parameters.md
- reload-vs-restart.md

lab-secure-and-configure-postgresql.md

---

## 04-user-and-role-management

- roles-and-users-basics.md
- login-vs-non-login-roles.md
- role-inheritance.md
- authentication-methods.md
- grants-and-revokes.md
- default-privileges.md

lab-role-based-access-control.md

---

## 05-database-and-schema-management

- database-lifecycle.md
- database-templates.md
- schema-management.md
- ownership-and-privileges.md
- renaming-databases-and-schemas.md

lab-multi-schema-database-setup.md
