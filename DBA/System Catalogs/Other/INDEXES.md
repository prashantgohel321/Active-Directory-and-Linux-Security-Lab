# INDEXES

## What index is?
- An index is a data structure PostgreSQL creates to find rows faster, so it doesn’t have to scan the entire table every time.
- It’s like the index page of a book — instead of reading every page, PostgreSQL jumps directly to the needed data.

```bash
CREATE INDEX idx_users_email ON users(email);
```

- **`CREATE INDEX`**: Tells PostgreSQL to build an index for faster lookups.
- **`idx_users_email`**: Name of the index being created.
- **`ON users`**: Specifies the table on which the index is built.
- **`(email)`**: Column used in the index.

**Think of it like**: Create a shortcut on the email column of the users table so searches become faster.

--- 

<br>
<br>

## Verify the index exist
```bash
\di # checks pg_indexes

# OR

select indexname, indexdef from pg_indexes where tablename = 'users';
```

---

<br>
<br>

## Check if queries actually use it
```bash
EXPLAIN SELECT * FRPM users WHERE email='a@b.com';
# Shows how PostgreSQL plans to run the query — which index or scan it thinks it will use and the estimated cost.
# It does not actually run the query.


# OR

EXPLAIN ANALYZE SELECT * FROM users WHERE email='a@b.com';
# Actually runs the query and then shows the real execution details — real time taken, rows processed, and whether the plan was accurate.

# In short:
  # EXPLAIN = plan only (estimates)
  # EXPLAIN ANALYZE = plan + real execution
```

> If you see index scan, the index is being used.

---

<br>
<br>

## Maintain it
Indexes need:
- VACCUM -> to clean dead entries
- REINDEX -> If bloated or corrupted

```bash
REINDEX INDEX idx_users_email;
```

---

<br>
<br>

## Drop it if useless
If an index is never used:
```bash
DROP INDEX idx_users_email;
```

---

<br>
<br>

## Monitor index usage
```bash
SELECT relname, idx_scan 
FROM pg_stats_user_indexes
WHERE indexrelname='idx_users_email';
```

> Indexes are not free. They Speed up reads but slow down writes and use disk space.