# EXTENSIONS

**What is Extension?**
- An extension is a packaged feature set that adds extra functionality in PGSQL without you writing code.
- A plugin that adds new functions, data types or operators to the database.
- PGSQL core stays small, and extensions add power when needed.
- Install extension only once per database. Extensions are database-specific, not clsuter-wide.
- Only super users (or users with permissions) can install extensions, because extensions can add powerful functions.

```bash
CREATE EXTENSION uuid-ossp;
```

- **`CREATE EXTENSION:`** Tells PGSQL to install and enable an extension in the current database.
- **`uuid-ossp:`** Name of the extension that provides UUID generation functions.

**What is uuid-ossp is used for?**
- It adds functions to generate UUIDs (Universally Unique Identifiers).

Most common function:
```bash
uuid_generate_v4()
```
Used when:
- we want globally unique ids.
- we dont want predictable IDs (like 1, 2, 3)
- Data is generated across multiple servers or services.

---

Example Usage:

**Create table with UUID primary key:**
```bash
CREATE TABLE users(
  id UUID DEFAULT uuid_generate_v4(),
  name TEXT
);

# Each insert automatically gets a unique ID

INSERT INTO users (name) VALUES ('ABC');
```

**Why use UUID instead of SERIAL?**
- SERIAL -> sequential, predictable
- UUID -> random, globally unique

UUIDs are better for:
- distributed systems
- microservices
- replication across regions

**Check installed extensions:**
```bash
\dx
```

**Grant usage to users:**
```bash
GRANT USAGE ON SCHEMA public TO app_user;
```

**Remove Extension:**
```bash
DROP EXTENSION uuid-ossp;
```