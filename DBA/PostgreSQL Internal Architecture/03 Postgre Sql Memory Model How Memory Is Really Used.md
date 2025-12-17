# PostgreSQL Internal Architecture – Memory Model (Why Memory Is Split and How It Is Actually Used)

## Slow Down Again Before Going Further

Up to now, we followed a connection and then a query. Both of those things felt logical because they followed time. Memory is different. Memory is always there. Every operation touches it. If you don’t understand memory properly, PostgreSQL performance will always feel random.

<br>
<br>

## Why PostgreSQL Cannot Use One Big Memory Pool

- PostgreSQL cannot use one big memory pool <mark><b>because it runs many queries at the same time in different backend processes</b></mark>. Each backend needs its own <mark><b>private memory for work that only it should see</b></mark>, while some data must be shared so all backends can coordinate correctly. If everything were mixed into a single pool, it would cause data corruption, race conditions, and unpredictable behavior, so PostgreSQL clearly separates private memory and shared memory.

<br>
<details>
<summary><b>What is Private Memory?</b></summary>
<br>

Private memory is the memory that <mark><b>belongs to a single backend process</b></mark>. Only that backend can use it, and other backends cannot see or touch it. PostgreSQL uses private memory for things like query execution, temporary results, and session-specific work so that different connections do not interfere with each other.

</details>
<br>

<br>
<details>
<summary><b>What is Shared Memory?</b></summary>
<br>

Shared memory is the memory that is created once by PostgreSQL and <mark><b>shared by all backend processes</b></mark>. It is used for data and control information that multiple backends must see at the same time, such as cached data pages, locks, and transaction status, so all processes can work together safely.

</details>
<br>

<br>
<details>
<summary><b>What is Transaction?</b></summary>
<br>

A transaction is a set of database operations that must either all succeed or all fail together. For example, when transferring money between two accounts, both the debit and the credit happen as one transaction, and if any step fails, no change is saved.

</details>
<br>

<br>
<br>

## Private Memory: Memory That Belongs to One Backend Only

- Private memory is the memory that <mark><b>belongs to a single backend process</b></mark> and cannot be accessed by other backends. This isolation is enforced by the operating system, not PostgreSQL. It exists so each backend can run its queries independently, storing temporary results and execution state without interfering with other sessions.

<br>
<details>
<summary><b>How does PostgreSQL decide between private memory and shared memory?</b></summary>
<br>

PostgreSQL uses <mark><b>private memory</b></mark> when the data is required only by a single backend while running its own query. For example, temporary data created during sorting or joining rows is kept in private memory so only that backend can use it.

PostgreSQL uses <mark><b>shared memory</b></mark> when the data must be seen or coordinated by multiple backends. For example, cached table pages or lock information are stored in shared memory so all backends can safely work on the same database at the same time.

</details>
<br>

<br>
<br>

## Memory Contexts: How PostgreSQL Avoids Memory Leaks

- Memory contexts are how PostgreSQL manages memory safely inside a backend process. Instead of allocating memory randomly, PostgreSQL <mark><b>groups allocations into logical containers</b></mark> called memory contexts. 

- When a query or transaction ends, PostgreSQL can free the entire context in one step, rather than cleaning up each allocation individually. This design prevents memory leaks in a long-running server by giving PostgreSQL a clean reset after every query.

<br>
<br>

## work_mem: Memory for Doing Actual Query Work

- work_mem is the memory PostgreSQL gives to a query for one single task at a time, like sorting rows or doing a join.
  - If a query does one sort, it can use up to work_mem.
  - If the same query does two sorts or joins, each one can use up to work_mem again.

- So one query can use work_mem many times, not just once.
- That’s why setting work_mem too high is risky — a single query can suddenly use much more memory than you expect.

<br>
<br>

## Why work_mem Spills to Disk

- If `work_mem` is not enough, PostgreSQL <mark><b>does not fail or crash</b></mark>. Instead, it <mark><b>writes the extra temporary data to disk</b></mark> and continues the query. This keeps the system stable, but disk access is much slower than memory, so performance drops. PostgreSQL is designed this way because staying correct and stable is more important than being fast.

<br>
<br>

## maintenance_work_mem: Memory for Heavy, Rare Operations

- `maintenance_work_mem` is memory reserved for heavy and infrequent operations like creating indexes, vacuuming tables, or rebuilding database structures. These tasks need more temporary memory than normal queries, but they do not run all the time. That is why this memory is kept separate from work_mem. If both shared the same limit, a maintenance task could consume too much memory and slow down or block normal query execution.

<br>
<details>
<summary><b>Vacuuming Tables</b></summary>
<br>

Vacuuming a table means PostgreSQL cleans up old, unused row versions that are left behind after updates or deletes. This frees space, keeps the table efficient, and helps PostgreSQL maintain correct visibility of data.

</details>
<br>

<br>
<br>

## Shared Memory: Memory That Everyone Must Agree On

- Shared memory is a common memory area that <mark><b>all PostgreSQL processes can see and use</b></mark>. It exists because some information must be the same for everyone. 

- For example, if one backend updates a row, other backends must know that this row is now changed or locked. That information cannot stay private. Shared memory is where PostgreSQL keeps such common, agreed-upon data so all processes stay in sync and the database remains correct.

<br>
<br>

## Shared Buffers: Caching Data Pages

- PostgreSQL stores data on disk in fixed-size blocks called pages. A page is the smallest unit PostgreSQL reads or writes, usually 8 KB. PostgreSQL never reads a single row directly from disk; it always reads the entire page that contains that row.

- Shared buffers are a shared memory area where PostgreSQL keeps copies of these pages after they are read from disk. When a backend needs data, it first checks shared buffers. If the required page is already there, PostgreSQL reads it from memory, which is fast. If the page is not there, PostgreSQL reads it from disk and places it into shared buffers.

- Because shared buffers are shared by all backends, once one backend loads a page, other backends can reuse the same page without reading from disk again. This reduces disk I/O and improves overall performance.

<br>
<br>

## Dirty Pages: Why Writes Are Deferred

- When a backend changes data, it modifies the page in shared buffers, and that page becomes dirty, meaning it is different from what is stored on disk. 

- PostgreSQL does not write this change to disk immediately because doing so for every change would create heavy disk I/O. Instead, PostgreSQL allows dirty pages to collect in memory and writes them to disk later using background processes, which improves overall performance and keeps disk activity smooth.

<br>
<br>

## WAL Buffers: Describing Change Before Applying It

When PostgreSQL changes data, it does not write the data to disk first.
Instead, it first writes a small record that says what change happened.
This record is written into WAL buffers.

Think of WAL buffers as a place where PostgreSQL writes instructions, not data pages.
For example, instead of writing “this page now has new values”, PostgreSQL writes “row X was updated in this way”.

<br>
<br>

## Why WAL Buffers Are Separate from Shared Buffers

WAL buffers are separate from shared buffers because they serve different purposes. Shared buffers hold the current state of data, meaning how the data looks right now. WAL holds the history of changes, meaning what happened and in what order.

If both were mixed, PostgreSQL would not know what the data looked like before a crash or how to rebuild it. WAL is written sequentially, which is fast and reliable for recovery, while data pages are updated in many random places. Keeping them separate lets PostgreSQL recover safely and handle each type of work in the most efficient way.

<br>
<br>

## CLOG Buffers: Remembering Transaction Decisions

- A <mark><b>transaction</b></mark> is one unit of work that either fully succeeds or fully fails. When it finishes, PostgreSQL must take a final decision: commit (keep the changes) or abort (discard them). That decision is permanent and very important.

<br>
<details>
<summary><b>Example of Transaction</b></summary>
<br>

For example, if a query updates two rows, PostgreSQL will treat both updates as one transaction. If everything goes fine, the transaction commits and the changes become visible. If something fails, the transaction aborts, and PostgreSQL throws away all those changes as if they never happened.

</details>
<br>

<mark><b>CLOG buffers</b></mark> are where PostgreSQL temporarily stores this decision. They record, for each transaction ID, whether that transaction committed or aborted. PostgreSQL needs this because data pages can contain row versions created by many different transactions. When a query reads a row, PostgreSQL checks CLOG and asks, did the transaction that created this row commit or not?

If CLOG says committed, the row is valid.
If CLOG says aborted, the row is ignored.

<br>
<details>
<summary><b>MVCC (Multi-Version Concurrency Control)</b></summary>
<br>

- MVCC means **Multi-Version Concurrency Control**. It allows multiple transactions to work on the same data at the same time without blocking each other. PostgreSQL keeps multiple versions of a row, and each transaction sees only the version that is valid for it based on transaction status and time.

</details>
<br>

<br>
<br>

## Lock Tables and Other Shared Structures

- When many users work on the database at the same time, PostgreSQL needs a way to coordinate them so they don’t mess up each other’s work.

For that, PostgreSQL keeps some shared control information in shared memory:
- Locks tell who is currently using a table or row, so others don’t change it in an unsafe way.
- Snapshots tell a query which data versions it is allowed to see.
- Other metadata helps PostgreSQL track who is doing what.

This data is not actual table data. It’s just coordination information so all backends can work together safely without conflicts.

<br>
<br>

## How Memory Pressure Builds Up

Memory pressure does not come from one place. It builds up when many backends use work_mem simultaneously, when shared buffers are too small to cache working sets, or when maintenance tasks run alongside heavy queries.

Understanding this interaction is more important than memorizing settings.

<br>
<br>

## The Big Mental Picture

- Private memory is about independence. Shared memory is about cooperation.

- PostgreSQL survives heavy concurrency by strictly separating these responsibilities.

- Once this memory model is clear, performance problems stop being mysterious.

- In the next file, we will follow data durability and background processes. That is where PostgreSQL’s crash safety truly reveals itself.
