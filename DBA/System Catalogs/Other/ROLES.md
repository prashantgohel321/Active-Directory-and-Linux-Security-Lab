# ROLES


```bash
CREATE USER app_user WITH PASSWORD 'secret';
```

**What it does:**
- Creates a login role named **`app_user`**
- Assigns a password so the user can authenticate
- The user can now connect to PGSQL, but has no permissions yet


**What this user can do by default:**
- Can log in
- Cannot access any database objects
- Cannot create tables, databases, or roles
- Cannot read or write data

This is intentional and secure.

---

**What we can do next:**
**1. Allow database connection:**
```bash
GRANT CONNECT ON DATABASE appdb2 TO app_user;
```

**2. Give Permissions via roles:**
```bash
GRANT app_readwrite TO app_user;
```

**3. Restrict access:**
```bash
REVOKE ALL ON DATABASE appdb2 FROM app_user;
```

**4. Change Password Later:**
```bash
ALTER USER app_user WITH PASSWORD 'newsecret';
```

**5. Remove the user:**
```bash
DROP USER app_user;
```

**Notes:**
- Password is stored hashed, not plain text.
- Work only if **`pg_hba.conf`** allows password (**`md5`** / **`scram`**)
- Should never be granted permissions directly in production.