# PostgreSQL Internal Architecture – WAL and Background Processes (Why Data Does Not Get Corrupted)

## Stop Thinking About Performance for a Moment

Before this point, we talked about connections, queries, and memory. All of that assumes one dangerous thing: that the system keeps running normally.

Real systems do not behave like that.

Machines crash. Power goes off. Kernels panic. Processes are killed. Disks momentarily lie. PostgreSQL is designed with this reality in mind.

This file explains how PostgreSQL protects data when things go wrong. Not in slogans, but in mechanisms.

<br>
<br>

## The Fundamental Problem Databases Must Solve

- If a system crashes while a change is being written to disk, the database could end up with half-written data and become corrupted. Disk writes are slow and not atomic, so PostgreSQL cannot trust them to finish cleanly every time. That is why PostgreSQL’s durability design exists: to make sure data stays consistent even if a crash happens at the worst moment.

<br>
<br>

## Why PostgreSQL Never Trusts Data Files First

- PostgreSQL does not trust data files during updates because <mark><b>writing data to disk can stop at any moment if the system crashes</b></mark>. <mark><b>Data pages may be only half-written</b></mark>, which makes them unreliable.

- So PostgreSQL does not depend on data files to be correct at all times. Instead, it first records every change safely in WAL. If something goes wrong, PostgreSQL ignores the data files and uses WAL to fix them.

<br>
<br>

## What Write-Ahead Logging Really Means

- Write-ahead logging means PostgreSQL <mark><b>first records what change will happen</b></mark> <mark><b>before it writes the actual data to disk</b></mark>. This record is <mark><b>a description of the action</b></mark>, not the final data itself. PostgreSQL follows a strict rule that this<mark><b> WAL record must be safely written to disk before any data pages are written</b></mark>. Because of this rule, PostgreSQL can recover correctly after a crash.

<br>
<br>

## Why PostgreSQL Logs Actions Instead of State

- PostgreSQL <mark><b>logs actions instead of full data states</b></mark> because <mark><b>storing entire table contents would be huge and very slow</b></mark>. By logging actions like inserts, updates, and deletes, PostgreSQL keeps WAL small and efficient. These actions can be replayed after a crash to rebuild the final data state, which is why this design is the foundation of PostgreSQL’s durability.


<br>
<br>

## WAL Buffers: The First Stop for Changes

- When a backend changes data, it first <mark><b>creates WAL records in memory</b></mark>. These records are <mark><b>stored in WAL buffers</b></mark>, which live in shared memory. WAL buffers exist <mark><b>so PostgreSQL does not have to write to disk for every single change</b></mark>, which would be very slow. Instead, <mark><b>changes are collected in memory</b></mark> and <mark><b>written to disk in batches</b></mark>. Backends only describe what changed; they do not write WAL files directly.

<br>
<details>
<summary><b>Batches</b></summary>
<br>

Batches mean grouping multiple small changes together and writing them at once instead of one by one.

</details>
<br>

<br>
<br>

## Why WAL Must Be Sequential

- WAL must be written sequentially because <mark><b>disks handle sequential writes much faster than random writes</b></mark>. By always appending WAL records in order, PostgreSQL avoids slow random disk access. This makes writing changes efficient and keeps durability affordable, which is why PostgreSQL can handle heavy write workloads without falling apart.

<br>
<br>

## WAL Writer: Separating Work from IO

- The WAL writer is <mark><b>a background process</b></mark> whose job is <mark><b>to write WAL records from memory to disk</b></mark>. It exists so backend processes do not have to block on slow disk I/O while handling client queries. By moving this work to a separate process, PostgreSQL keeps backends responsive and smooths disk activity. Only at transaction commit does a backend wait for WAL to be flushed, because durability requires it.

<br>
<br>

## Commit: The Moment of Truth

- A transaction commit is the point where PostgreSQL guarantees the change will survive a crash. This guarantee is only valid after the related WAL records are safely written to disk. That’s why commit speed depends heavily on WAL performance. Once WAL is flushed, PostgreSQL can confidently tell the client that the transaction succeeded.

<br>
<br>

## Data Pages and the Illusion of Safety

- After WAL is safely written, PostgreSQL does not need to rush data pages to disk. The actual data pages may still be dirty in memory and not yet updated on disk, and that is completely fine. Because WAL exists, PostgreSQL can always replay the changes later if needed. This clear separation between durability and data placement is a deliberate design choice.

<br>
<br>

## Background Writer: Writing Data Without Blocking Users

- The background writer writes dirty pages to disk in the background so backend processes don’t have to block on disk I/O. This keeps query performance stable and avoids sudden spikes caused by backends doing disk writes themselves.

It works conservatively on purpose. If it writes too aggressively, it competes with active queries for disk resources. If it writes too slowly, checkpoints become heavy and expensive. Its goal is not speed, but balance.

<br>
<br>

## Checkpoints: Drawing a Line in Time

- A checkpoint is the moment when PostgreSQL draws a clear line and says, “everything before this point is safely written to disk.” Over time, WAL keeps growing and dirty pages keep accumulating in memory, so PostgreSQL periodically forces those dirty pages to disk and writes a checkpoint record into WAL. This record marks a safe starting point for crash recovery.

<br>
<br>

## Why Checkpoints Exist

- Checkpoints exist to make recovery practical. Without them, PostgreSQL would have to replay the entire WAL history after a crash, which could take a very long time. By creating checkpoints, PostgreSQL limits how much WAL needs to be replayed, trading some runtime work for much faster recovery.

<br>
<br>

## Checkpointer: Coordinating Safety

- The checkpointer is the background process that coordinates this. It makes sure dirty pages are flushed and that WAL reflects a consistent state. It doesn’t do all the writing itself but works together with the background writer and WAL writer, keeping responsibilities separate and reducing contention.

<br>
<br>

## What You Should Feel Now

At this point, you should feel why durability is expensive, why commits are slower than memory writes, and why background processes exist.

You are no longer trusting PostgreSQL blindly. You understand its safety contract.

In the next file, we will finally open the disk and look at what PostgreSQL actually stores there.
