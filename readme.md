# Standard Generic Library (SGL) for Pascal

## Why this project appeared
In the process of porting code from C ++ to Delphi, very often
have to port code using STL collections.
The set of collections offered by Delphi is very ascetic and therefore sometimes  
it is difficult to find a suitable replacement.
Sometimes you come across the code where the object is placed in the stack or 
uses its own memory allocator.

I really dislike the suggested data refresh mode.
To update the data, I need to retrieve the value placed in it from the collection, update the value and then put the changed value back.
This requires at least two additional copy operations.
We cannot pass a data item as a var parameter to a procedure.

There is no way for a collection to change how memory is allocated.
Memory for objects and records is allocated from one shared heap.
After use, the memory must be carefully returned to the heap.
Freeing memory correctly is not always a trivial task, and it takes both processor time and the programmer's time to write this code.
In STL, you can specify your own memory allocator for all kinds of collections.

This implementation relies on records and pointers.
So far, I see no way to implement what I want using standard objects.
The creation and destruction of objects uses a shared heap of memory.
There is no way to place objects on the call stack.
The good old "object" is declared deprecated and adding new features for this type is not supported.

## Typed region-based memory management
This collection implementation relies on the mechanism
memory management based on typed memory regions.
The use of typed memory regions makes it possible to simplify the solution of a number of tasks:
 - Memory release code.

The task of freeing memory becomes easier and
can be done much faster.
 - Parallel programming.

It is a well-known fact that a standard memory manager must be thread-safe.
Only one thread can access the memory manager at any given time.
Allocating and freeing memory uses mutual exclusion mechanisms and is not a fast operation,
especially if the memory is heavily defragmented.
When using a separate typed memory region, we refer to the standard memory manager only at the moment of increasing the required memory and deleting the structure after its use.

## Standard data structures
Support for basic structures with the ability to specify a memory allocator.
The elements of the list are accessed through pointers.
As a rule, the memory for values is located in the so-called segmented memory region, which will not be moved during operation.
If it is necessary to increase the memory of a region, an additional memory segment is allocated for it.
This means that we can access data items located in such a region through a pointer.
  
For arrays, we use the so-called contiguous memory region.
Data items are accessed through an index.
If necessary, increase the memory of the region,
a segment with a large size is allocated for it and data from the current memory segment is copied to the new segment.
After copying the data, the old segment will be deleted.
 
Ultimately, working through pointers is very convenient and efficient.
The code becomes much simpler and more concise.
However, if you have no experience with pointers, it is easy to "shoot yourself in the foot".
For fans of encapsulation, you can aggregate the desired structure as a private field.
Next, we open only the necessary part of the interface by overriding the required methods and properties in the public section.
If we put the inline option, we avoid additional costs.
The Delphi compiler will not generate code for overridden methods.
At the place of the method call, there will be a direct call to the aggregate structure method.

### Generic lists and dictionaries
 - `TsgPair<T1, T2>, TsgTrio<T1, T2, T3>, TsgQuad<T1, T2, T3, T4> ...` Generic Tuples  
 - `TsgList<T>` Generic List of Values
 - `TsgRecordList<T>` Generic List of Values accessed by pointer
 - `TsgLinkedList<T>` Generic Bidirectional Linked List
 - `TsgForwardList<T>` Generic Unidirectional Linked List
 - `TsgHashMap<Key, T>` Generic Unordered dictionary
 - `TsgMap<Key, T>` Generic Ordered Dictionary based on 2-3 tree
 - `TsgSet<Key>` Generic Set based on 2-3 trees
 
### Untyped data structures
 - `TsgPointerArray` Untyped List of Pointers
 - `TsgPointerList` Untyped List of Values accessed by pointer
 - `TCustomLinkedList` Untyped Bidirectional Linked List
 - `TsgCustomTree` Untyped Dictionary based on 2-3 trees 

## Iterators
We've started adding Delphi iterators.
Now we can use the construction `for p in List do;`
The most interesting thing is that we use **record** to implement the iterator and it works!
Compared to using objects, the generated code is much more efficient and, which is nice,
no calls to the heap, the variable for the iterator is located on the stack.
This turned out to be quite a pleasant surprise for me!

## Memory allocator
The ability to specify a memory allocator also means that we work mainly with records.
Typically, some structure uses one or more memory regions, which is a simple memory manager.
After using the structure, we have the opportunity return all the memory occupied by freeing up the memory region.
We have limitations using inheritance.
In some cases, we can replace inheritance with aggregation and helpers.
Typically for implementing collections, this is not a problem.
Using records allows collections to be stacked. This is sometimes very convenient.

## Object pool
An object pool allows you to manage the reuse of structures when creating objects 
is memory intensive or when a limited number of objects of a certain type can be created.

If we stop using something, it is not always worth deleting the structure or object.
Often times the object has to be re-created.
