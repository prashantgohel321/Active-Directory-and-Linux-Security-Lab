# PostgreSQL Internal Architecture – How It Really Works Inside

## Why I Am Writing This

Whenever I use PostgreSQL, I can easily run queries and get results. But for a long time, I did not really understand what happens inside when I type a simple SELECT or INSERT. This file is written to explain PostgreSQL internals in a very human way, step by step, without jumping into heavy theory. I am writing this as if I am explaining it to myself while learning, so the flow stays natural and easy to grasp. Thoda hinglish bhi aayega, because that’s how we actually think.

## The Big Picture First

PostgreSQL is not a single program doing everything. It is a collection of processes working together. One main parent process controls everything, and many child processes do the actual work. When I connect to PostgreSQL and run a query, that query travels through multiple internal layers before I see the output. Understanding this journey is the key to understanding PostgreSQL architecture.

## PostgreSQL Starts With the Postmaster

When PostgreSQL starts, the first and most important process that comes up is called the postmaster. You can think of it as the boss process. It does not run queries itself, but it manages the entire database server. It listens for new client connections, starts background processes, and creates new worker processes whenever a client connects.

So whenever my application or psql tries to connect, it is the postmaster that receives that request first. If postmaster is not running, PostgreSQL is effectively dead. No connections, no queries, nothing.

## Client Connection and Authentication Flow

When I run psql or when an application connects, the request reaches the postmaster. The postmaster then forks a new backend process for that client. This is very important to understand. PostgreSQL uses a process-based model, not a thread-based one. One client equals one backend process.

That backend process now handles everything for that client. Authentication happens here using whatever method is configured, like password, Kerberos, LDAP, or anything else. Once authentication succeeds, this backend process stays alive until the client disconnects.

This is why PostgreSQL can struggle with too many connections. Each connection is a full OS process, not a lightweight thread. That is also why tools like PgBouncer exist.

## Life of a Query Starts Here

Now assume the connection is successful and I run a query. The query does not directly touch data. First, it goes through the query processing pipeline. PostgreSQL breaks query execution into clear internal phases so that it can optimize and execute efficiently.

## Query Parsing Phase

The first thing PostgreSQL does is parse the query. Here it checks whether the SQL syntax is correct. If I make a typo or write invalid SQL, the error comes from this phase. At this stage, PostgreSQL only cares about grammar, not whether tables or columns actually exist.

The output of this phase is a parse tree. It is just a structured representation of my SQL statement.

## Query Rewriting Phase

Next comes query rewriting. This is where rules are applied. For example, views are expanded here. If I query a view, PostgreSQL rewrites that query into the actual underlying table queries.

Most people never notice this phase, but it is important. PostgreSQL is silently transforming my query into something more executable.

## Query Planning and Optimization

Now comes one of the smartest parts of PostgreSQL: the planner. The planner looks at multiple ways to execute the same query and tries to choose the cheapest one.

Here PostgreSQL checks indexes, table statistics, row counts, and data distribution. It estimates cost based on disk IO and CPU usage. This is why outdated statistics can lead to slow queries. The planner is not guessing blindly, it is using statistics collected earlier.

At the end of this phase, PostgreSQL creates an execution plan. This plan defines exactly how the data will be accessed.

## Query Execution Phase

Now the executor takes over. It follows the execution plan step by step. This is the phase where actual data is read or written.

If the plan says to use an index, PostgreSQL uses it. If it says to scan the table, it scans it. The executor works closely with the storage and memory layers to fetch and modify data.

## Memory Architecture – Where Data Lives Temporarily

PostgreSQL uses memory heavily to avoid disk access as much as possible. Memory is divided into shared memory and local memory.

Shared memory is accessible by all backend processes. The most important part here is shared buffers. This is where PostgreSQL keeps frequently accessed data blocks. If data is already in shared buffers, PostgreSQL does not need to go to disk, which makes queries much faster.

Each backend process also has its own local memory. This is used for things like sorting, hashing, and intermediate query results. This memory is not shared with other sessions.

## Storage Architecture – Where Data Is Permanently Stored

On disk, PostgreSQL stores data in files, but not in a simple one-table-one-file way. Each table is divided into multiple segments, and each segment contains fixed-size pages.

PostgreSQL reads and writes data in blocks, not row by row. Each block is usually 8KB in size. This block-based design is why understanding IO patterns is important for performance tuning.

Indexes are stored separately but follow a similar block structure.

## WAL – The Safety Net of PostgreSQL

Whenever PostgreSQL modifies data, it does not immediately write changes to disk. Instead, it first writes changes to the Write Ahead Log, commonly called WAL.

The rule is simple: WAL first, data later. This ensures durability. If PostgreSQL crashes, it can replay WAL records and recover to a consistent state.

This is why even if data files are not fully written, PostgreSQL can still recover safely after a crash.

## Background Processes – Silent Workers

PostgreSQL runs several background processes that users never directly interact with. One important process is the checkpointer. It periodically writes dirty pages from memory to disk.

Another important process is the WAL writer, which flushes WAL records to disk. There is also the autovacuum process, which cleans up dead rows created due to MVCC.

These processes work continuously in the background to keep the system healthy and performant.

## MVCC – How PostgreSQL Handles Concurrency

PostgreSQL uses Multi-Version Concurrency Control. Instead of locking rows aggressively, it creates multiple versions of a row.

When I update a row, PostgreSQL does not overwrite it. It creates a new version and marks the old one as obsolete. Other transactions can still see the old version if needed.

This design allows readers and writers to work together without blocking each other too much. The downside is that old rows need cleanup, which is handled by autovacuum.

## Transaction Flow in Simple Words

A transaction in PostgreSQL is like a promise. Either everything inside it succeeds, or nothing does.

Internally, PostgreSQL assigns transaction IDs, tracks visibility using snapshots, writes changes to WAL, and only then commits. If something fails, it simply ignores the uncommitted changes.

## How Everything Connects Together

So when I look at the full flow, it becomes clear. A client connects, postmaster creates a backend process, authentication happens, query goes through parsing, rewriting, planning, and execution, memory and disk are used smartly, WAL ensures safety, background processes maintain health, and MVCC ensures concurrency.

Once I see this flow end to end, PostgreSQL stops feeling like a black box. It starts feeling like a well-organized system where every component has a clear responsibility.

## Final Thought

If I understand this architecture properly, performance tuning, debugging, and production troubleshooting become much easier. I stop guessing and start reasoning. That is the real power of understanding PostgreSQL internals.
