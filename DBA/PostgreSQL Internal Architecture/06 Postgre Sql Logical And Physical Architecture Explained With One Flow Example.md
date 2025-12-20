# PostgreSQL Logical and Physical Architecture (Explained Through One Example Flow)

## The Purpose of This File

Instead of listing logical parts and physical parts separately, this file explains both together using one continuous example. You will see how a logical SQL object becomes real physical data under the hood.

<br>
<br>

## First, the Scenario

Imagine a very simple situation. A database contains a table called customers. The table has three columns: id, name, and city. A client inserts one new row:
```bash
INSERT INTO customers VALUES (1, 'John', 'London');
```
This one statement will flow through PostgreSQL’s logical architecture and then down into the physical architecture. Watching this travel path reveals how everything fits together.

<br>
<br>

## Logical Level: What Exists in the Database Structure

At the logical layer, PostgreSQL does not think about files or disk blocks. It thinks about objects.

The database itself is a logical container inside the PostgreSQL instance. Inside that database, there are schemas. Schemas organise objects logically and prevent naming conflicts. The customers table lives inside a schema.

A table is a logical definition. It describes columns, data types, constraints, and indexes. Nothing at this level cares about pages, rows on disk, or how memory stores information. From the client’s point of view, the table customers is a single object.

So at the logical stage, the INSERT statement means: put one new customer row into the customers table.

<br>
<br>

## Transition From Logical to Physical Begins With the Backend

The backend process receives the INSERT. The logical structure tells PostgreSQL where the data should conceptually live. But to make the row real, PostgreSQL must create a physical record.

The backend now prepares information needed to place the row physically. It decides which underlying files and pages must be updated.

At this point, logical structure provides direction, and physical structure performs the real work.

<br>
<br>

## Physical Level: Where the Table Lives

Behind the logical table definition, PostgreSQL stores data in heap files. The customers table is mapped to one or more physical files inside the database directory.

PostgreSQL does not overwrite existing areas blindly. It places new rows wherever free space exists inside heap pages.

So the backend process selects a page in the heap file that has enough space for the new row. This page is an 8 KB block. Pages are the smallest stored unit that PostgreSQL reads and writes.

<br>
<br>

## Creating the Physical Row Version

The backend creates a physical record for the row. This record contains the id, name, and city values. It also contains metadata: the transaction id that inserted the row and flags indicating the record state.

This metadata enables PostgreSQL to handle concurrency. Other sessions can see or ignore this row based on visibility rules.

The backend then places this record inside the chosen page. The page header updates pointers to track free space and record order.

<br>
<br>

## WAL Entry: Physical Protection for Logical Change

Before the row becomes part of the data file, PostgreSQL writes a WAL entry. This WAL entry describes the action: inserting a new row into customers.

This WAL entry is not optional. It allows PostgreSQL to recover the change if a crash occurs before the data reaches disk pages.

So WAL sits between the logical request and the physical data.

<br>
<br>

## Committing the Transaction: Logical Success Depends on Physical Safety

When the client commits the INSERT, PostgreSQL does not simply say “done”. It waits until the WAL entry is safely written to disk. Only then does the logical transaction succeed.

Logical success depends on physical guarantee.

<br>
<br>

## Retrieving the Data: Logical View on Physical Storage

Later, another query runs:

```bash
SELECT * FROM customers WHERE id = 1;
```
At the logical layer, the table is just a structure containing rows. The query engine decides what rows match the condition.

At the physical layer, PostgreSQL reads the page that contains the row record. The executor checks transaction metadata to confirm visibility. If valid, the record becomes a logical row in the result.

What appears as a simple SELECT is the physical system reading heap pages, filtering record versions, and reconstructing the logical row.

<br>
<br>

## Why This Dual Architecture Exists

Logical design makes PostgreSQL easy to use. Tables, columns, and SQL queries hide complexity.

Physical design makes PostgreSQL reliable, crash-safe, and efficient. Pages, heap files, WAL, and transaction metadata ensure correctness under heavy concurrency.

Logical and physical layers exist together because databases must be both user-friendly and mechanically disciplined.

<br>
<br>

## A Final Mental Picture

When you write SQL, you talk to the logical architecture. When PostgreSQL stores or retrieves your data, it works through the physical architecture.

One INSERT created:
logical meaning (a new customer row exists)
physical record (bytes stored inside a page)
WAL protection (change history preserved)
visibility metadata (row version controlled)

These pieces are inseparable. Without logical structure there is no usability. Without physical structure there is no durability.
