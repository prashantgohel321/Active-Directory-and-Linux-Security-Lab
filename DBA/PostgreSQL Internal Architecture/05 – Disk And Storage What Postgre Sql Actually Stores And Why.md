# PostgreSQL Internal Architecture – Disk and Storage (What Is Stored, Where, and Why)

## Before We Touch the Disk, Fix One Idea in the Head

Up to now, we talked about connections, queries, memory, and WAL. All of that work eventually needs one thing: persistence. When PostgreSQL shuts down and comes back, data must still be there.

Disk is the only reason a database exists. Memory is temporary. WAL is a safety mechanism. Disk is the final truth.

So in this file, we will not talk about performance tricks. We will talk about how PostgreSQL *thinks* about disk and why it stores data the way it does.

## The Data Directory: PostgreSQL’s Home

PostgreSQL stores everything inside a single directory called the data directory. This directory is not just storage. It is the entire identity of the database server.

If this directory is lost, the database is lost. If it is copied correctly, the database can be recreated elsewhere.

PostgreSQL never scatters its files randomly across the system. Everything lives under this one controlled root so that consistency and recovery are manageable.

## Why PostgreSQL Needs Full Control of This Directory

PostgreSQL assumes it is the only authority over the data directory. External tools modifying files here will corrupt the database.

This strict ownership exists because PostgreSQL relies on internal invariants. Files must change only through PostgreSQL logic, otherwise WAL and recovery guarantees break.

## Important Configuration Files in the Data Directory

Inside the data directory, some files control how PostgreSQL behaves.

postgresql.conf defines server-level behavior. Memory usage, background processes, WAL behavior, and many other settings live here. PostgreSQL reads this file during startup.

pg_hba.conf controls who can connect and how authentication works. Every connection request consults this file before anything else.

pg_ident.conf exists to map external system identities to PostgreSQL roles. This is mainly used when PostgreSQL integrates with operating system users.

There is also a critical file called postmaster.pid. This file exists only while PostgreSQL is running. It prevents two PostgreSQL servers from using the same data directory at the same time. Without it, data corruption would be inevitable.

## Databases Are Not Files

A common beginner mistake is to think that one database equals one file. PostgreSQL does not work like that.

A database is a logical container. Physically, it is represented by a directory containing many files.

This design allows PostgreSQL to scale databases beyond single-file limits and manage storage efficiently.

## Tables Are Not Files Either

Similarly, a table is not a single file.

A table is a logical object. Physically, it is stored as one or more files called relations.

When a table grows beyond a certain size, PostgreSQL splits it into multiple segment files. This avoids filesystem limitations and improves manageability.

## Heap Tables: Where Rows Actually Live

PostgreSQL stores table data in heap tables. The word heap here does not mean memory heap. It means unordered storage.

Rows are placed wherever space is available. There is no guaranteed order.

This design exists because ordering on disk would make inserts and updates extremely expensive.

Indexes exist to provide logical ordering without forcing physical order.

## Pages: The Smallest Unit PostgreSQL Reads and Writes

PostgreSQL does not read individual rows from disk. It reads pages.

A page is a fixed-size block, usually 8 kilobytes.

This size is chosen as a balance. Too small and overhead dominates. Too large and memory waste increases.

Every disk access deals with pages, not rows.

## Why Pages Matter So Much

When PostgreSQL needs one row, it must read the entire page containing that row.

This is why table and index design matter. Poor locality means unnecessary disk reads.

Understanding pages explains many performance behaviors that otherwise feel mysterious.

## Records: What a Row Really Is

Inside a page, PostgreSQL stores records. A record is a physical representation of a row version.

A record does not contain just user data. It also contains metadata.

This metadata includes transaction identifiers. These identifiers allow PostgreSQL to decide which rows are visible to which transactions.

This design enables MVCC, which we will deep dive into later.

## Why Updates Create New Records

When PostgreSQL updates a row, it does not overwrite the old record. It creates a new record.

Overwriting would break concurrency. Readers might see partial updates.

Creating new versions allows readers and writers to work simultaneously without blocking each other.

The old record is marked as obsolete but not immediately removed.

## Free Space and Page Reuse

PostgreSQL tracks free space inside pages.

When new rows are inserted, PostgreSQL tries to reuse space left by old, obsolete records.

This reuse reduces file growth but requires careful bookkeeping.

This is why vacuuming exists.

## Index Storage on Disk

Indexes are stored separately from heap tables.

They contain references to heap pages and records.

Indexes do not store full rows. They store pointers.

This separation allows PostgreSQL to maintain multiple indexes on the same table without duplicating data.

## Why Disk Type Matters

Hard disks store data in rotating platters. Access time depends on physical movement.

Solid-state disks store data electronically. Access time is much more uniform.

PostgreSQL’s page-based design works on both, but random IO penalties are far worse on spinning disks.

This is why SSDs dramatically improve database performance.

## WAL Files on Disk

WAL files are stored separately from data files inside the data directory.

They are written sequentially.

This layout ensures that WAL writes do not compete excessively with random data page writes.

## Temporary Files on Disk

When memory is insufficient, PostgreSQL creates temporary files.

These files store intermediate query results.

They exist to protect the system from running out of memory.

Temporary files are cleaned up automatically when queries finish.

## Disk Space Is Not Just Capacity

Disk is not only about how much space you have.

It is about how fast data can be read, how fast WAL can be flushed, and how many concurrent IO operations can be handled.

Ignoring disk characteristics leads to misleading conclusions about database performance.

## How Disk, WAL, and Memory Fit Together

Memory reduces disk access.

WAL guarantees correctness when disk writes are delayed.

Disk stores the final state.

PostgreSQL survives by carefully balancing these three.

## What You Should Understand Now

At this point, disk should no longer feel like a black box.

You should understand what PostgreSQL stores, how it structures data, and why certain operations feel expensive.

In the next file, we will talk about concurrency, MVCC, and transaction visibility. That is where many hidden behaviors finally make sense.
