# FUNCTIONS

**What is a function?**
- A function is a stored piece of logic inside the database that runs on the server and returns a result.
- It lets me reuse logic, keep code close to data, and avoid repeating the same SQL everywhere.

Think of it like:
- “A reusable SQL shortcut with a name.”

```bash
CREATE FUNCTION get_user_count()
RETURNS integer AS $$
SELECT COUNT(*) FROM users;
$$ LANGUAGE SQL;
```

- **`CREATE FUNCTION get_user_count():`**Creates a function named **`get_user_count`** that takes no arguments.
- **`Returns integer:`** The function will return a single integer value.

```bash
# The actual logic of the function.

AS $$
SELECT COUNT(*) FROM appdb2_users;
$$

# Here it counts rows in the users table.
```

- **`LANGUAGE SQL:`** Tells PostgreSQL this function is written in plain SQL (not PL/pgSQL, Python, etc.).

---

**How to use it:**

**Call the function:**
```bash
SELECT get_user_count();
```

**Security Control:**
```bash
GRANT EXECUTE ON FUNCTION get_user_count() TO app_user;

# I can deny direct table access.
# I can allow users to execute the function only.
```

**Drop the function:**
```bash
DROP FUNCTION get_user_count();
```