# Reload vs Restart in PostgreSQL

## Why This Difference Is Important

One of the most common PostgreSQL mistakes is changing a configuration file and expecting it to work immediately. Whether a change takes effect depends on whether PostgreSQL needs a reload or a full restart.

If I don’t understand this difference, I end up confused and waste time debugging something that was never applied.

---

- [Reload vs Restart in PostgreSQL](#reload-vs-restart-in-postgresql)
  - [Why This Difference Is Important](#why-this-difference-is-important)
  - [What Reload Means](#what-reload-means)
  - [What Restart Means](#what-restart-means)
  - [Examples From Real Life](#examples-from-real-life)
  - [How I Know What Is Required](#how-i-know-what-is-required)
  - [Simple Takeaway](#simple-takeaway)


<br>
<br>

## What Reload Means

A reload tells PostgreSQL to re-read its configuration files without stopping the database.

Existing connections stay active. Queries continue running. Only settings that support reload are updated.

To reload PostgreSQL:
```bash
sudo systemctl reload postgresql-15
```
Reload is safe and should be used whenever possible.

---

<br>
<br>

## What Restart Means

A restart stops PostgreSQL completely and then starts it again.

All client connections are dropped. Backend processes are killed and recreated. Memory is reallocated.

To restart PostgreSQL:
```bash
sudo systemctl restart postgresql-15
```
Restart is required for settings related to memory, process limits, or core behavior.

---

<br>
<br>

## Examples From Real Life

If I change pg_hba.conf, I only need a reload.

If I change logging settings, a reload is usually enough.

If I change shared_buffers or max_connections, a restart is mandatory.

---

<br>
<br>

## How I Know What Is Required

PostgreSQL tells me whether a parameter needs reload or restart.

I can check this using:
```bash
SELECT name, context FROM pg_settings WHERE name = 'shared_buffers';
```
If context is "postmaster", a restart is required. If it is "sighup", a reload is enough.

---

<br>
<br>

## Simple Takeaway

Reload when possible. Restart only when required.

If a change does not apply, the first thing I check is whether I should have restarted PostgreSQL instead of reloading it.
