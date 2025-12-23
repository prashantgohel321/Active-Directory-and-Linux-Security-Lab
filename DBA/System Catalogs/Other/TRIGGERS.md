# TRIGGERS

**What is a trigger?**
- A trigger is automatic logic that runs when something happens in a table like INSERT, UPDATE, or DELETE.
- No need to call it manually; PGSQL fires it automatically.
- If this even happens, automatically run this function.

```bash
CREATE TRIGGER trg_users
BEFORE INSERT ON users
FOR EACH ROW EXECUTE FUNCTION some_function();
```

- **`CREATE TRIGGER trg_users`**: Creates a trigger named trg_users.
- **`BEFORE INSERT ON users`**: The trigger fires before a new is inserted into the users table.
- **`FOR EACH ROW`**: Runs once per row, not once per statement.
- **`EXECUTE FUNCTION some_function()`**: Calls the trigger function that contains the logic to execute.

--- 

**Disable or Drop trigger:**
```bash
ALTER TABLE users DISABLE TRIGGER trg_users;
DROP TRIGGER trg_users ON users;
```