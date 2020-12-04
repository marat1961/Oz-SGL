# Memory region

This collection implementation relies on a memory management mechanism based on typed memory regions.
A memory region stores objects of the same type.

Management using a typed memory region allows you to organize the allocation of memory to a group of objects within one or more memory blocks.
Each of the blocks must be large enough to allocate memory for many objects within it.

At the end of use, all allocated objects in one region of memory can be effectively deallocated with a single operation.
Like stack allocation, memory regions facilitate memory allocation and deallocation with low overhead; but they are more flexible, allowing objects to live longer than the stack frame in which they were placed.

We have implemented two variants of the memory region.

## Unbroken memory region
All objects in a region are allocated in a single contiguous range
of memory addresses, in the same way that memory for the stack is normally allocated.
Region attributes: type, item size, capacity, number of allocated items.
Given that we know the size and type of the item, we can refer to the items 
of the region as elements of an array using the index.
The object (item) of the region can be moved.
A contiguous region is used for regular data structures such as:
arrays, stacks, store, or queue.

## Segmented memory region
A linked list of several continuous regions.
A segmented region is implemented as a linked list of large memory blocks; 
The region data structure contains a pointer to the next free position inside the block, 
and if the block is filled to the end, the memory management system allocates 
a new block and adds it to the list.
Region attributes: type, size, capacity, number of allocated elements.
A region element may not be moved and its address shall be addressed to.
Segmented region is used for dynamic data structures such as: 
list, tree or dictionary.

## Unbroken region 
Operations: 
1. Add
2. Delete
3. Assign
4. Clean up
5. Return the element by index
6. Exchange two elements  
7. Sorting .

## Segmented memory region
Operations: 
1. Add
2. Delete
3. Assign .
4. Clean up
5. Return the item to its address

Functions:
1. Notification when performing operations
2. Checking the entry of the pointer into the region
3. For objects provide support for OwnedObject
4. Regional elements reuse
5. Element counter
6. For the memory segment GetItemPtr(Index: Cardinal): Pointer;

## Metadata
The typed region contains metadata.
Metadata contains the size and set of Boolean flags and seed in a packed record.
```
hMeta = record
  TypeKind     5 System.TTypeKind 0...22
  Reserved     1
  ManagedType  1 Boolean -- controlled type
  HasWeakRef   1 Boolean -- type contains weak links
               8
  RangeCheck   1 Boolean -- check index or pointer validity
  Notification 1 Boolean -- Notification when performing operations 
  Owned        1 Boolean -- objects belong to the region
  AtDeletion   2 TAtDeletion 0...2 Clear
end;
```
Removal behavior from the collection
AtDeletion -- What to do when removing from a collection:
- do nothing
- clear the element value;
- clear the element value and allow reuse;
- hold the element value.

Clear - clear the value and place it to the reuse list
HoldValue - hold and store item value