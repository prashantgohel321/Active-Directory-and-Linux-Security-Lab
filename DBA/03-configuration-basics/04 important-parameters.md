# Important PostgreSQL Parameters

## Why These Parameters Matter

- PostgreSQL has hundreds of configuration parameters, but in real life I only touch a few of them regularly. These parameters directly affect connectivity, stability, and basic performance.

- If PostgreSQL behaves strangely, these are the first settings I check.

---

<br>
<br>

## listen_addresses

- This parameter controls on which network interfaces PostgreSQL listens.

- By default, it listens only on localhost. This means only local connections are allowed.

- If I want remote clients to connect, I must change this value.

To check the current value:
```bash
SHOW listen_addresses;
```
After changing it in postgresql.conf, I reload or restart PostgreSQL depending on the setup.

---

<br>
<br>

## port

- This defines the port PostgreSQL listens on. The default is 5432.

- I rarely change this unless another service is using the same port or for security-by-obscurity reasons.

To check the port:
```bash
SHOW port;
```
---

<br>
<br>

## max_connections

- This parameter defines how many client connections PostgreSQL will accept.

- More connections mean more backend processes and more memory usage. Increasing this value without a connection pool is a common mistake.

To check it:
```bash
SHOW max_connections;
```
---

<br>
<br>

## shared_buffers

- shared_buffers controls how much memory PostgreSQL uses to cache data.

- If it is too small, PostgreSQL hits disk too often. If it is too large, the OS suffers.

To check the value:
```bash
SHOW shared_buffers;
```
---

<br>
<br>

## logging_collector

- This parameter controls whether PostgreSQL collects logs internally.

- On Rocky Linux, logs are often handled by systemd, but this parameter is still important to understand when logs are missing.

To check:
```bash
SHOW logging_collector;
```
---

<br>
<br>

## Applying Changes Safely

- Some parameters can be reloaded, others require a restart.

- If PostgreSQL ignores my change, the first thing I check is whether a restart was required.

---

<br>
<br>

## Simple Takeaway

- I don’t need to know every PostgreSQL parameter.

- If I understand these few settings and their impact, I can solve most basic configuration issues quickly.
