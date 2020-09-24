Standard Generic Library (SGL) for Pascal
==========================================

Why this project appeared
--------------------------
In the process of porting code from C ++ to Delphi, very often
have to port code using stl collections.
The set of collections offered by Delphi is limited and poor.

There is no way to selectively specify your memory allocator.
Memory for objects is allocated from a single heap.
After use, the memory must be carefully returned to the system.
The correct freeing of memory is not always a trivial task and it takes both the processor time and the programmer's time to write this code.

Region-based memory management
-------------------------------------
This collection implementation relies on the mechanism
memory management based on regions.
The use of regions makes it possible to simplify the solution of a number of tasks:
 - Memory release code.
The task of freeing memory becomes easier and
can be done much faster.
 - Parallel programming.
It is a well-known fact that a standard memory manager must be thread-safe.
Allocating and freeing memory is not the fastest operation.

Standard data structures
----------------------------
Support for basic structures with the ability to specify a memory allocator.
Lists
 - List <T>
 - LinkedList <T>, DualLinkedList <>
Dictionaries
 - HashMap (Unordered dictionary)
 - Vocabulary based on 2-3 trees
 - Lots based on 2-3 wood

Memory allocator
----------------
The ability to specify a memory allocator also means that we work mainly with records.
Typically, some structure uses one or more memory regions, which is a simple memory manager.
After using the structure, we have the opportunity
return all the memory occupied by freeing up the memory region.
We have limitations using inheritance.
In some cases, we can replace inheritance with aggregation and helpers.
Typically for implementing collections, this is not a problem.
Using records allows collections to be stacked. This is sometimes very convenient.

Object pool
------------
If we stop using something, it is not always worth deleting the structure or object.
Often times the object has to be re-created.