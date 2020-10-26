# Tuple

## Tasks
 - Define semantics and operations for the tuple.
 - Implement structures for working with tuples and their elements.
 - Implement a typed memory region for tuples.

### Tuple

A tuple is a finite ordered sequence of elements.
Many programming languages offer an alternative to tuples, known as record types, with unordered elements accessed by field name.
We plan to place tuples in a typed memory region.
```
TsgPair <T1, T2> = record
type
  PT1 = ^ T1;
  PT2 = ^ T2;
var
  Value: T1;
  Value: T2;
end;
```
We will not explicitly declare such a structure, and if we define such a structure, we may run into problems related to the location of such a structure in memory.
The structure parameters depend on the used memory model 32/64 bits and the alignment parameters of the tuple elements in memory.
We will use metadata to work with tuples.
The metadata for the tuple will be defined at runtime when the tuple is initialized.
```
  TsgTupleMeta = record
  const
    AllignTuple = sizeof (Pointer); // Align tuple to the word boundary
  var
    TypeInfo: Pointer;
    Size: Cardinal; // Memory size
    Offset: Cardinal; // The offset of an element in a tuple
    h: hMeta;
  public
    procedure Init <T> (Offset: Cardinal);
    // Determine the offset to the start of the next tuple.
    function NextTupleOffset (Allign: Boolean): Cardinal;
  end;
```
We will work with tuples through the tuple builder, memory region and proxy objects.
The builder is an intermediary for working with tuples located in the memory region.
In the program code for manipulating tuples, we will use proxy objects.
A proxy object is an intermediate structure that contains a reference to a tuple in a memory region and its metadata.

### Operations for a tuple
 - `Init <T1, ...>` - creates a tuple object of the type defined by generic types
 - `Assign (TTuple)` - assigns the contents of one tuple to another
 - `Swap` - swap the contents of two tuples
 - `Get (Index: Integer)`- return a reference to the element of the tuple
 - `Tie` - returns a tuple of pointers to the elements of the tuple

### Tuple element
Each element of a tuple has a type, size, and offset in the tuple.
The type defines how operations are performed on an element of a tuple.
The size and offset are needed to organize access to the element of the tuple.
- `procedure Assign(pvalue: PT1);` - assign value
 - `function GetPvalue: T1;` - return a reference to the value