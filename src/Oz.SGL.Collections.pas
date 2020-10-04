(* Standard Generic Library (SGL) for Pascal
 * Copyright (c) 2020 Marat Shaimardanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

unit Oz.SGL.Collections;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Oz.SGL.Heap;

{$EndRegion}

{$T+}

{$Region 'TsgList<T>: List of records using the memory pool'}

type

  PsgListHelper = ^TsgListHelper;
  TsgListHelper = record
  strict private type
    PBytes = array of Byte;
    PWords = array of Word;
    PCardinals = array of Cardinal;
    PUInt64s = array of UInt64;
    function GetFItems: PPointer; inline;
    function Compare(const Left, Right): Boolean;
  private
    FRegion: PMemoryRegion;
    FCount: Integer;
    FSizeItem: Integer;
    procedure SetItem(Index: Integer; const Value);
    procedure SetCount(NewCount: Integer);
    procedure CheckCapacity(NewCount: Integer);
    procedure QuickSort(Compare: TListSortCompareFunc; L, R: Integer);
  public
    procedure Init(SizeItem: Integer; OnFree: TFreeProc = nil);
    procedure Free;
    procedure Clear;
    function GetPtr(Index: Integer): Pointer;
    function Add(const Value): Integer;
    procedure Delete(Index: Integer);
    procedure Insert(Index: Integer; const Value);
    function Remove(const Value): Integer;
    procedure Sort(Compare: TListSortCompare);
    procedure Exchange(Index1, Index2: Integer);
    procedure Reverse;
    procedure Assign(const Source: TsgListHelper);
  end;

  TsgList<T> = record
  private type
    TItems = array [0..High(Word)] of T;
    PItems = ^TItems;
    PItem = ^T;
  private
    FOnFree: TFreeProc;
    FListHelper: TsgListHelper; // FListHelper must be before FItems
    FItems: PItems; // FItems must be after FListHelper
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
    procedure SetCount(Value: Integer); inline;
  public
    constructor From(OnFree: TFreeProc);
    procedure Free; inline;
    procedure Clear; inline;
    function Add(const Value: T): Integer; inline;
    procedure Delete(Index: Integer); inline;
    procedure Insert(Index: Integer; const Value: T); inline;
    function Remove(const Value: T): Integer; inline;
    procedure Exchange(Index1, Index2: Integer); inline;
    procedure Reverse; inline;
    procedure Sort(Compare: TListSortCompare);
    procedure Assign(Source: TsgList<T>); inline;
    function GetPtr(Index: Integer): PItem; inline;
    function IsEmpty: Boolean; inline;
    property Count: Integer read FListHelper.FCount write SetCount;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
    property List: PItems read FItems;
  end;

{$EndRegion}

{$Region 'TsgPointerArray: Array of pointers'}

  // An array of pointers for quick sorting and searching.
  TsgPointerArray = record
  private
    // region for pointers
    FListRegion: PMemoryRegion;
    FList: PsgPointers;
    FCount: Integer;
    function Get(Index: Integer): Pointer;
    procedure Put(Index: Integer; Item: Pointer);
  public
    constructor From(Capacity: Integer);
    procedure Free;
    procedure Add(ptr: Pointer);
    procedure Sort(Compare: TListSortCompare);
    property Count: Integer read FCount;
    property Items[Index: Integer]: Pointer read Get write Put;
  end;

{$EndRegion}

{$Region 'TsgPointerList: List of pointers using a memory pool'}

  TItemFunc = reference to function(Item: Pointer): Boolean;

  PsgPointerList = ^TsgPointerList;
  TsgPointerList = record
  private
    FList: PsgPointers;
    FCount: Integer;
    FFactory: TsgItemFactory;
    function Get(Index: Integer): Pointer;
    procedure Put(Index: Integer; Item: Pointer);
    procedure CheckCapacity(NewCount: Integer);
    procedure SetCount(NewCount: Integer);
  public
    constructor From(ItemSize: Integer; OnFree: TFreeProc);
    procedure Free;
    procedure Clear;
    function First: Pointer; inline;
    function Last: Pointer; inline;
    function NextAfter(prev: Pointer): Pointer; inline;
    procedure Assign(const Source: TsgPointerList);
    function Add(Item: Pointer): Integer; overload;
    // Add an empty record and return its pointer
    function Add: Pointer; overload;
    procedure Insert(Index: Integer; Item: Pointer);
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function Extract(Item: Pointer): Pointer;
    function IndexOf(Item: Pointer): Integer;
    procedure Sort(Compare: TListSortCompare);
    procedure Reverse;
    function TraverseBy(F: TItemFunc): Pointer;
    procedure RemoveBy(F: TItemFunc);
    function IsEmpty: Boolean; inline;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Pointer read Get write Put;
  end;

{$EndRegion}

{$Region 'TsgRecordList<T: record>: Generic list using a memory pool'}

  TsgRecordList<T: record> = record
  type
    PItem = ^T;
  private
    FList: TsgPointerList;
    function Get(Index: Integer): PItem; inline;
    procedure Put(Index: Integer; Item: PItem);
    procedure SetCount(Value: Integer);
  public
    constructor From(OnFree: TFreeProc);
    procedure Free;
    procedure Clear;
    function Add(Item: PItem): Integer; overload; inline;
    // Add an empty record and return its pointer
    function Add: PItem; overload; inline;
    procedure Delete(Index: Integer); inline;
    procedure Exchange(Index1, Index2: Integer); inline;
    function Extract(Item: PItem): PItem;
    function IndexOf(Item: PItem): Integer; inline;
    procedure Assign(const Source: TsgRecordList<T>);
    procedure Sort(Compare: TListSortCompare); inline;
    procedure Reverse; inline;
    function IsEmpty: Boolean; inline;
    property Count: Integer read FList.FCount write SetCount;
    property Items[Index: Integer]: PItem read Get write Put;
    property List: TsgPointerList read FList;
  end;

{$EndRegion}

{$Region 'TCustomLinkedList: Untyped Linked List'}

  TCustomLinkedList = record
  type
    PItem = ^TItem;
    TItem = record
      next: PItem;
      prev: PItem;
    end;
  private
    FRegion: PMemoryRegion;
    FHead: PItem;
    FLast: PItem;
  public
    procedure Init(ItemSize: Cardinal; OnFree: TFreeProc);
    procedure Free;
    // Erases all elements from the container. After this call, Count returns zero.
    // Invalidates any references, pointers, or iterators referring to contained
    // elements. Any past-the-end iterator remains valid.
    procedure Clear;
    // Checks if the container has no elements, i.e. whether begin() == end().
    function Empty: Boolean; inline;
    // Returns the number of elements in the container,
    function Count: Integer;
    // Returns a reference to the first element in the container.
    // Calling front on an empty container is undefined.
    function Front: PItem;
    // Returns reference to the last element in the container.
    // Calling back on an empty container causes undefined behavior.
    function Back: PItem;
    // Prepends the the empty value to the beginning of the container.
    // No iterators or references are invalidated.
    function PushFront: PItem;
    // Appends the empty value to the end of list and return a pointer to it
    function PushBack: PItem;
    // Inserts value before pos
    function Insert(const Pos: PItem): PItem;
    // Removes the first element of the container.
    // If there are no elements in the container, the behavior is undefined.
    // References and iterators to the erased element are invalidated.
    procedure PopFront;
    // Removes the last element of the list.
    // Calling pop_back on an empty container results in undefined behavior.
    // References and iterators to the erased element are invalidated.
    procedure PopBack;
    // Reverses the order of the elements in the container.
    // No references or iterators become invalidated.
    procedure Reverse;
    // Sorts the elements in ascending order. The order of equal elements is preserved.
    procedure Sort(Compare: TListSortCompare);
  end;

{$EndRegion}

{$Region 'TsgLinkedList<T: record>: Generic Linked List'}

  TsgLinkedList<T: record> = record
  type
    PItem = ^TItem;
    TItem = record
      Link: TCustomLinkedList.TItem;
      Value: T;
    end;
    PValue = ^T;
    TIterator = record
    private
      Item: PItem;
      function GetValue: PValue;
    public
      // Go to the next node
      procedure Next;
      // Go to the previous node
      procedure Prev;
      // End of the list
      function Eol: Boolean;
      // Beginning of the list
      function Bol: Boolean;
      // pointer to Value
      property Value: PValue read GetValue;
    end;
  private
    FList: TCustomLinkedList;
  public
    procedure Init(OnFree: TFreeProc);
    procedure Free; inline;
    // Erases all elements from the container. After this call, Count returns zero.
    // Invalidates any references, pointers, or iterators referring to contained
    // elements. Any past-the-end iterator remains valid.
    procedure Clear; inline;
    // Checks if the container has no elements, i.e. whether begin() == end().
    function Empty: Boolean; inline;
    // Returns the number of elements in the container.
    function Count: Integer; inline;
    // Returns a reference to the first element in the container.
    // Calling front on an empty container is undefined.
    function Front: TIterator; inline;
    // Returns reference to the last element in the container.
    // Calling back on an empty container causes undefined behavior.
    function Back: TIterator; inline;
    // Prepends the the empty value to the beginning of the container.
    // No iterators or references are invalidated.
    function PushFront: TIterator; overload; inline;
    // Prepends the given element value to the beginning of the container.
    // No iterators or references are invalidated.
    procedure PushFront(const Value: T); overload; inline;
    // Appends the empty value to the end of list and return a pointer to it
    function PushBack: TIterator; overload; inline;
    // Appends the given element value to the end of list
    procedure PushBack(const Value: T); overload; inline;
    // Inserts value after Pos
    function Insert(Pos: TIterator; const Value: T): TIterator;
    // Removes the first element of the container.
    // If there are no elements in the container, the behavior is undefined.
    // References and iterators to the erased element are invalidated.
    procedure PopFront; inline;
    // Removes the last element of the list.
    // Calling pop_back on an empty container results in undefined behavior.
    // References and iterators to the erased element are invalidated.
    procedure PopBack; inline;
    // Reverses the order of the elements in the container.
    // No references or iterators become invalidated.
    procedure Reverse; inline;
    // Sorts the elements in ascending order. The order of equal elements is preserved.
    procedure Sort(Compare: TListSortCompare); inline;
  end;

{$EndRegion}

{$Region 'TsgHashMap<Key, T>: Unordered dictionary'}

  TsgHashMapIterator<Key, T> = record
  type
    PsgPair = ^TsgPair;
    TsgPair = TPair<Key, T>;
    PItem = ^T;
    PKey = ^Key;
  private
    vidx: Integer;
    Pairs: PsgListHelper;
    procedure Init(const Pairs: TsgListHelper; vidx: Integer);
  public
    class operator Equal(
      const a, b: TsgHashMapIterator<Key, T>): Boolean; inline;
    class operator NotEqual(
      const a, b: TsgHashMapIterator<Key, T>): Boolean; inline;
    procedure Next;
    function GetKey: PKey; inline;
    function GetValue: PItem; inline;
  end;

  // Has constant lookup time using memory pool
  TsgHashMap<Key, T> = record
  const
    SeedValue = 123454321;
  public type
    TKeyHash = function(const k: Key): Cardinal;
    TKeyEquals = function(const a, b: Key): Boolean;
  private type
    // Collision list element
    PCollision = ^TCollision;
    TCollision = record
      Next: PCollision;
      PairIndex: Integer;
    end;
    // Hash table element (entry)
    PEntry = ^TEntry;
    TEntry = record
      Head: PCollision;
      Cnt: Integer;
    end;
  private
    FSeed: Integer;
    FHash: TKeyHash;
    FKeyEquals: TKeyEquals;
    FEntries: TsgList<TEntry>;
    FCollisionRegion: PMemoryRegion;
    FPairs: TsgList<TPair<Key, T>>;
    // Set entry table size
    procedure SetEntriesLength(ExpectedSize: Integer);
  public
    constructor From(ExpectedSize: Integer; Hash: TKeyHash;
      KeyEquals: TKeyEquals; OnFreePair: TFreeProc = nil);
    procedure Free;
    procedure Clear;
    // Already initialized
    function Valid: Boolean; inline;
    function Find(k: Key): TsgHashMapIterator<Key, T>;
    function Insert(const pair: TPair<Key, T>): TsgHashMapIterator<Key, T>;
    // Return the iterator to the beginning
    function Begins: TsgHashMapIterator<Key, T>;
    // Next to the last one.
    function Ends: TsgHashMapIterator<Key, T>;
    // Pairs
    property Pairs: TsgList<TPair<Key, T>> read FPairs;
  end;

{$EndRegion}

{$Region 'TsgTreeIterator: Iterator for 2-3 tree'}

  TsgTreeAction = (taFind, taInsert, taInsertEmpty, taInsertOrAssign, taCount);

  TsgTreeIterator = record
  type
    PNode = ^TNode;
    PPNode = ^PNode;
    TNode = record
      left, right: PNode;
      case Integer of
        0: (lh, rh: Boolean);
        1: (forAlignment: Int64);   // field for area alignment
                                    // memory in different memory models
    end;
  private
    Stack: array of PNode;
    function Sentinel: PNode;       // 0 - element (always on the stack)
    function Current: PPNode;       // 1 - element (always on the stack)
    function Res: PPNode;           // 2 - element (always on the stack)
    procedure Push(Item: Pointer);
    function Pop: Pointer;
    function Empty: Boolean; inline;
  public
    constructor Init(Root, Sentinel: PNode);
    procedure Next;
    function GetItem: Pointer;
  end;

{$EndRegion}

{$Region 'TsgCustomTree: Dictionary based on 2-3 trees'}

  TsgCustomTree = record
  private type
    PNode = TsgTreeIterator.PNode;
    TParams = record
      action: TsgTreeAction;
      h, cnt: Integer;
      node: PNode;
      pval: Pointer;
      constructor From(ta: TsgTreeAction);
    end;
    TNodeProc = procedure(p: PNode) of object;
    TUpdateProc = procedure(p: PNode; pval: Pointer) of object;
  private
    Compare: TListSortCompare;
    Update: TUpdateProc;
    Visit: TNodeProc;
    Region: PMemoryRegion;
    Root, Sentinel: PNode;
    procedure Visiter(node: PNode);
    procedure Search(var p: PNode; var prm: TParams);
    procedure CreateNode(var p: PNode);
  public
    procedure Init(ItemSize: Cardinal; Compare: TListSortCompare;
      Update: TUpdateProc; OnFreeNode: TFreeProc = nil);
    procedure Free;
    procedure Clear;
    procedure Find(pval: Pointer; var iter: TsgTreeIterator);
    function Get(pval: Pointer): PNode;
    // Return the number of items with key
    function Count(pval: Pointer): Integer;
    procedure Insert(pval: Pointer);
    procedure InsertOrAssign(pval: Pointer);
    procedure Begins(var iter: TsgTreeIterator);
    // Next to the last (guard element)
    function Ends: PNode;
    // Tree bypass
    procedure Inorder(Visit: TNodeProc);
  end;

{$EndRegion}

{$Region 'TsgMap<Key, T>: Dictionary based on 2-3 tree'}

  {$Region 'TsgMapIterator<Key, T>: Iterator for 2-3 tree'}

  TsgMapIterator<Key: record; T: record> = record
  type
    PItem = ^T;
    PKey = ^Key;
    PNode = ^TNode;
    PPNode = ^PNode;
    TNode = record
      Dt: TsgTreeIterator.TNode;
      case Integer of
        0: (k: Key; v: T);
        1: (pair: TPair<Key, T>);
    end;
  private
    Iter: TsgTreeIterator;
  public
    constructor Init(Root, Sentinel: TsgTreeIterator.PNode);
    class operator Equal(const a: TsgMapIterator<Key, T>; b: PNode): Boolean;
    class operator NotEqual(const a: TsgMapIterator<Key, T>; b: PNode): Boolean;
    procedure Next; inline;
    function GetKey: PKey;
    function GetValue: PItem;
  end;

  {$EndRegion}

  TsgMap<Key: record; T: record> = record
  public type
    PItem = ^T;
    PNode = TsgMapIterator<Key, T>.PNode;
    TNodeProc = procedure(p: PNode) of object;
  private
    tree: TsgCustomTree;
    procedure UpdateValue(pnd: TsgCustomTree.PNode; pval: Pointer);
  public
    constructor From(Compare: TListSortCompare; OnFreeNode: TFreeProc = nil);
    procedure Free; inline;
    procedure Clear;
    function Find(const k: Key): TsgMapIterator<Key, T>; inline;
    function Count(const k: Key): Integer; inline;
    procedure Insert(const pair: TPair<Key, T>); inline;
    function Emplace(const k: Key): PNode;
    procedure InsertOrAssign(const pair: TPair<Key, T>);
    function Begins: TsgMapIterator<Key, T>; inline;
    function Ends: PNode;
    // Bypass the tree in order
    procedure Inorder(Visit: TNodeProc); inline;
    function Get(index: Key): PItem;
    procedure Put(index: Key; const Value: PItem);
    property Items[index: Key]: PItem read Get write Put; default;
  end;

{$EndRegion}

{$Region 'TsgSet<Key>: Set based on 2-3 trees'}

  {$Region 'TsgSetIterator<Key, T>: Iterator for 2-3 trees'}

  TsgSetIterator<Key: record> = record
  type
    PKey = ^Key;
    PNode = ^TNode;
    PPNode = ^PNode;
    TNode = record
      Dt: TsgTreeIterator.TNode;
      k: Key;
    end;
  private
    Iter: TsgTreeIterator;
  public
    constructor Init(Root, Sentinel: PNode);
    class operator Equal(const a: TsgSetIterator<Key>; b: PNode): Boolean;
    class operator NotEqual(const a: TsgSetIterator<Key>; b: PNode): Boolean;
    procedure Next; inline;
    function GetKey: PKey;
  end;

  {$EndRegion}

  TsgSet<Key: record> = record
  private type
    PNode = TsgSetIterator<Key>.PNode;
    TNodeProc = procedure(p: PNode) of object;
  private
    tree: TsgCustomTree;
    procedure UpdateValue(pnd: TsgCustomTree.PNode; pval: Pointer);
  public
    procedure Init(Compare: TListSortCompare; OnFree: TFreeProc = nil);
    procedure Free; inline;
    procedure Clear(Compare: TListSortCompare; OnFree: TFreeProc = nil);
    procedure Insert(const k: Key); inline;
    function Find(const k: Key): TsgSetIterator<Key>; inline;
    // Count the number of elements with key
    function Count(const k: Key): Integer; inline;
    // Bypass the tree in order
    procedure Inorder(Visit: TNodeProc); inline;
    function Begins: TsgSetIterator<Key>; inline;
    function Ends: PNode;
  end;

{$EndRegion}

{$Region 'TsgLog'}

  TsgLog = record
  private
    FLocalDebug: Boolean;
    FLog: TStringList;
    procedure AddLine(const Msg: string);
  public
    procedure Init;
    procedure Free;
    // Save to file
    procedure SaveToFile(const filename: string);
    // Logging when the FLocalDebug flag is set
    procedure print(const Msg: string); overload;
    procedure print(const Msg: string;
      const Args: array of const); overload;
    // Displaying an explanatory message to the user
    procedure Msg(const Msg: string); overload; inline;
    procedure Msg(const fmt: string;
      const Args: array of const); overload;
  end;

{$EndRegion}

{$Region 'Procedures and functions'}

// Check the index entry into the range [0...Count - 1].
procedure CheckIndex(Index, Count: Integer);

procedure QuickSort(List: PsgPointers; L, R: Integer; SCompare: TListSortCompareFunc);

{$EndRegion}

var
  log: TsgLog;

implementation

{$Region 'Procedures and functions'}

procedure Swap(var i, j: Double);
var
  temp: Double;
begin
  temp := i;
  i := j;
  j := temp;
end;

procedure Exchange(pointers: PsgPointers; i, j: Integer); inline;
var
  temp: Pointer;
begin
  temp := pointers[i];
  pointers[i] := pointers[j];
  pointers[j] := temp;
end;

procedure CheckIndex(Index, Count: Integer);
begin
  if Cardinal(Index) >= Cardinal(Count) then
    raise ESglError.CreateFmt('List index error (%d)', [Count]);
end;

procedure CheckCount(Count: Integer);
begin
  if Count < 0 then
    raise ESglError.CreateFmt('List count error (%d)', [Count]);
end;

procedure QuickSort(List: PsgPointers; L, R: Integer; SCompare: TListSortCompareFunc);

  procedure Sort(L, R: Integer);
  var
    i, j: Integer;
    x: Pointer;
  begin
    i := L;
    j := R;
    x := List[(L + R) div 2];
    repeat
      while SCompare(List[i], x) < 0 do
      begin
        if i >= R then break;
        Inc(i);
      end;
      while SCompare(List[j], x) > 0 do
      begin
        if j <= L then break;
        Dec(j);
      end;
      if i <= j then
      begin
        Exchange(List, i, j);
        Inc(i); Dec(j);
      end;
    until i > j;
    if L < j then QuickSort(List, L, j, SCompare);
    if i < R then QuickSort(List, i, R, SCompare);
  end;

  procedure ShortSort(L, R: Integer);
  var
    i, max: Integer;
  begin
    while R > L do
    begin
      max := L;
      for i := L + 1 to R do
        if SCompare(List[i], List[max]) > 0 then
          max := i;
      Exchange(List, max, R);
      Dec(R);
    end;
  end;

begin
  // Below a certain size, it is faster to use the O(n^2) sort method
  if (R - L) <= 8 then
    ShortSort(L, R)
  else
    Sort(L, R);
end;

{$EndRegion}

{$Region 'TsgListHelper'}

procedure TsgListHelper.Init(SizeItem: Integer; OnFree: TFreeProc);
begin
  FRegion := HeapPool.CreateUnbrokenRegion(SizeItem, OnFree);
  FCount := 0;
  FSizeItem := SizeItem;
end;

procedure TsgListHelper.Free;
begin
  FRegion.Free;
  FCount := 0;
  FSizeItem := 0;
end;

procedure TsgListHelper.Clear;
var
  SizeItem: Integer;
  OnFree: TFreeProc;
begin
  // todo: Make a cleanup implementation without deleting and creating
  SizeItem := FSizeItem;
  Check(SizeItem > 0, 'TsgListHelper.Clear: uninitialized');
  OnFree := FRegion.OnFree;
  Free;
  Init(SizeItem, OnFree);
end;

function TsgListHelper.GetPtr(Index: Integer): Pointer;
begin
  CheckIndex(Index, FCount);
  Result := @PByte(GetFItems^)[(Index) * FSizeItem];
end;

function TsgListHelper.Add(const Value): Integer;
begin
  if FRegion.Capacity <= FCount then
    GetFItems^ := FRegion.IncreaseCapacity(FCount + 1);
  FRegion.Alloc(FSizeItem);
  Result := FCount;
  Inc(FCount);
  SetItem(Result, Value);
end;

procedure TsgListHelper.SetCount(NewCount: Integer);
begin
  if NewCount <> FCount then
  begin
    CheckCapacity(NewCount);
    FCount := NewCount;
  end;
end;

procedure TsgListHelper.CheckCapacity(NewCount: Integer);
begin
  if FRegion.Capacity <= NewCount then
    GetFItems^ := FRegion.IncreaseAndAlloc(NewCount);
end;

procedure TsgListHelper.Delete(Index: Integer);
var
  MemSize: Integer;
begin
  CheckIndex(Index, FCount);
  Dec(FCount);
  if Index < FCount then
  begin
    MemSize := (FCount - Index) * FSizeItem;
    System.Move(
      PByte(GetFItems^)[(Index + 1) * FSizeItem],
      PByte(GetFItems^)[(Index) * FSizeItem],
      MemSize);
  end;
end;

procedure TsgListHelper.QuickSort(Compare: TListSortCompareFunc; L, R: Integer);
var
  I, J: Integer;
  pivot: Pointer;
begin
  if L < R then
  begin
    repeat
      if (R - L) = 1 then
      begin
        if Compare(GetPtr(L), GetPtr(R)) > 0 then
          Exchange(L, R);
        break;
      end;
      I := L;
      J := R;
      pivot := GetPtr(L + (R - L) shr 1);
      repeat
        while Compare(GetPtr(I), pivot) < 0 do
          Inc(I);
        while Compare(GetPtr(J), pivot) > 0 do
          Dec(J);
        if I <= J then
        begin
          if I <> J then
            Exchange(I, J);
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if (J - L) > (R - I) then
      begin
        if I < R then
          QuickSort(Compare, I, R);
        R := J;
      end
      else
      begin
        if L < J then
          QuickSort(Compare, L, J);
        L := I;
      end;
    until L >= R;
  end;
end;

procedure TsgListHelper.Sort(Compare: TListSortCompare);
begin
  if FCount > 1 then
    QuickSort(Compare, 0, FCount - 1);
end;

procedure TsgListHelper.Exchange(Index1, Index2: Integer);
var
  STemp: array [0..255] of Byte;
  DTemp: PByte;
  PTemp: PByte;
  Items: PPointer;
begin
  DTemp := nil;
  PTemp := @STemp[0];
  Items := GetFItems;
  try
    if FSizeItem > sizeof(STemp) then
    begin
      GetMem(DTemp, FSizeItem);
      PTemp := DTemp;
    end;
    Move(PByte(Items^)[Index1 * FSizeItem], PTemp[0], FSizeItem);
    Move(PByte(Items^)[Index2 * FSizeItem], PByte(Items^)[Index1 * FSizeItem], FSizeItem);
    Move(PTemp[0], PByte(Items^)[Index2 * FSizeItem], FSizeItem);
  finally
    FreeMem(DTemp);
  end;
end;

procedure TsgListHelper.Insert(Index: Integer; const Value);
var
  Items: PPointer;
  MemSize: Integer;
begin
  CheckIndex(Index, FCount + 1);
  Items := GetFItems;
  if FRegion.Capacity <= FCount then
    GetFItems^ := FRegion.IncreaseCapacity(FCount + 1);
  FRegion.Alloc(FSizeItem);
  if Index <> FCount then
  begin
    MemSize := (FCount - Index) * FSizeItem;
    System.Move(
      PByte(Items^)[Index * FSizeItem],
      PByte(Items^)[(Index + 1) * FSizeItem],
      MemSize);
  end;
  Move(Value, PByte(Items^)[Index * FSizeItem], FSizeItem);
  Inc(FCount);
end;

function TsgListHelper.Remove(const Value): Integer;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do
    if Compare(PByte(GetFItems^)[i * FSizeItem], Byte(Value)) then
      exit(i);
  Result := -1;
end;

procedure TsgListHelper.Reverse;
var
  b, e: Integer;
begin
  b := 0;
  e := FCount - 1;
  while b < e do
  begin
    Exchange(b, e);
    Inc(b);
    Dec(e);
  end;
end;

procedure TsgListHelper.Assign(const Source: TsgListHelper);
var
  i: Integer;
  Items: PPointer;
begin
  FCount := 0;
  Items := Source.GetFItems;
  for i := 0 to Source.FCount - 1 do
    Add(PByte(Items^)[i * FSizeItem]);
end;

function TsgListHelper.GetFItems: PPointer;
begin
  Result := PPointer(PByte(@Self) + SizeOf(Self));
end;

procedure TsgListHelper.SetItem(Index: Integer; const Value);
begin
  CheckIndex(Index, FCount);
  case FSizeItem of
    1: PBytes(GetFItems^)[Index] := Byte(Value);
    2: PWords(GetFItems^)[Index] := Word(Value);
    4: PCardinals(GetFItems^)[Index] := Cardinal(Value);
    8: PUInt64s(GetFItems^)[Index] := UInt64(Value);
    else Move(Value, PByte(GetFItems^)[Index * FSizeItem], FSizeItem);
  end;
end;

function TsgListHelper.Compare(const Left, Right): Boolean;
begin
  Result := CompareMem(@Left, @Right, FSizeItem)
end;

{$EndRegion}

{$Region 'TsgList<T>'}

constructor TsgList<T>.From(OnFree: TFreeProc);
begin
  FOnFree := OnFree;
  FListHelper.Init(sizeof(T), OnFree);
end;

procedure TsgList<T>.Free;
begin
  FListHelper.Free;
end;

procedure TsgList<T>.Clear;
begin
  FListHelper.Clear;
end;

function TsgList<T>.Add(const Value: T): Integer;
begin
  Result := FListHelper.Add(Value);
end;

procedure TsgList<T>.Delete(Index: Integer);
begin
  FListHelper.Delete(Index);
end;

procedure TsgList<T>.Insert(Index: Integer; const Value: T);
begin
  FListHelper.Insert(Index, Value);
end;

function TsgList<T>.Remove(const Value: T): Integer;
begin
  Result := FListHelper.Remove(Value);
end;

procedure TsgList<T>.Exchange(Index1, Index2: Integer);
begin
  FListHelper.Exchange(Index1, Index2);
end;

procedure TsgList<T>.Reverse;
begin
  FListHelper.Reverse;
end;

procedure TsgList<T>.Sort(Compare: TListSortCompare);
begin
  FListHelper.Sort(Compare);
end;

procedure TsgList<T>.Assign(Source: TsgList<T>);
begin
  FListHelper.Assign(Source.FListHelper);
end;

function TsgList<T>.GetPtr(Index: Integer): PItem;
begin
  Result := FListHelper.GetPtr(Index);
end;

function TsgList<T>.GetItem(Index: Integer): T;
begin
  CheckIndex(Index, FListHelper.FCount);
  Result := FItems[Index];
end;

function TsgList<T>.IsEmpty: Boolean;
begin
  Result := FListHelper.FCount = 0;
end;

procedure TsgList<T>.SetCount(Value: Integer);
begin
  FListHelper.SetCount(Value);
end;

procedure TsgList<T>.SetItem(Index: Integer; const Value: T);
begin
  FListHelper.SetItem(Index, Value);
end;

{$EndRegion}

{$Region 'TsgPointerArray: Array of pointers'}

constructor TsgPointerArray.From(Capacity: Integer);
begin
  FListRegion := HeapPool.CreateUnbrokenRegion(sizeof(Pointer));
  FList := FListRegion.IncreaseCapacity(Capacity);
  FCount := 0;
end;

procedure TsgPointerArray.Free;
begin
  FListRegion.Free;
end;

function TsgPointerArray.Get(Index: Integer): Pointer;
begin
  CheckIndex(Index, FCount);
  Result := FList[Index];
end;

procedure TsgPointerArray.Put(Index: Integer; Item: Pointer);
begin
  CheckIndex(Index, FCount);
  if Item <> FList[Index] then
    FList[Index] := Item;
end;

procedure TsgPointerArray.Add(ptr: Pointer);
var
  idx: Integer;
begin
  Check(ptr <> nil);
  idx := FCount;
  if FListRegion.Capacity <= idx then
    FList := FListRegion.IncreaseAndAlloc(idx);
  Inc(FCount);
  FList[idx] := ptr;
end;

procedure TsgPointerArray.Sort(Compare: TListSortCompare);
begin
  if Count > 1 then
    QuickSort(FList, 0, Count - 1,
      function(Item1, Item2: Pointer): Integer
      begin
        Result := Compare(Item1, Item2);
      end);
end;

{$EndRegion}

{$Region 'TsgPointerList'}

constructor TsgPointerList.From(ItemSize: Integer; OnFree: TFreeProc);
begin
  FList := nil;
  FCount := 0;
  FFactory := TsgItemFactory.From(ItemSize, OnFree);
end;

procedure TsgPointerList.Free;
begin
  FList := nil;
  FCount := 0;
  FFactory.Free;
end;

procedure TsgPointerList.Clear;
var
  ItemSize: Integer;
  OnFree: TFreeProc;
begin
  Check(FFactory.ItemSize > 0, 'TsgPointerList.Clear: uninitialized');
  ItemSize := FFactory.ItemSize;
  OnFree := FFactory.ItemsRegion.OnFree;
  Free;
  Self := TsgPointerList.From(ItemSize, OnFree);
end;

function TsgPointerList.First: Pointer;
begin
  if Count > 0 then
    Result := FList[0]
  else
    Result := nil;
end;

function TsgPointerList.Last: Pointer;
begin
  if Count > 0 then
    Result := FList[Count - 1]
  else
    Result := nil;
end;

function TsgPointerList.NextAfter(prev: Pointer): Pointer;
begin
  if prev = nil then
    Result := nil
  else if prev = FList[Count - 1] then
    Result := nil
  else
    Result := Pointer(NativeUInt(prev) + NativeUInt(FFactory.ItemSize));
end;

procedure TsgPointerList.Assign(const Source: TsgPointerList);
var
  i: Integer;
begin
  Count := 0;
  for i := 0 to Source.Count - 1 do
    Add(Source.Get(i));
end;

function TsgPointerList.Add(Item: Pointer): Integer;
begin
  Check(Item <> nil);
  Result := FCount;
  CheckCapacity(Result);
  Inc(FCount);
  FList[Result] := FFactory.AddItem(Item);
end;

procedure TsgPointerList.Insert(Index: Integer; Item: Pointer);
var
  MemSize: Integer;
begin
  if Index = FCount then
    Add(Item)
  else
  begin
    CheckIndex(Index, FCount + 1);
    Check(Item <> nil);
    CheckCapacity(FCount);
    MemSize := (FCount - Index) * SizeOf(Pointer);
    System.Move(FList[Index], FList[Index + 1], MemSize);
    FList[Index] := FFactory.AddItem(Item);
    Inc(FCount);
  end;
end;

function TsgPointerList.Add: Pointer;
var
  Index: Integer;
begin
  Index := FCount;
  CheckCapacity(Index);
  Inc(FCount);
  Result := FFactory.CreateItem;
  FList[Index] := Result;
end;

procedure TsgPointerList.Delete(Index: Integer);
var
  MemSize: Integer;
begin
  CheckIndex(Index, FCount);
  Dec(FCount);
  if Index < FCount then
  begin
    MemSize := (FCount - Index) * SizeOf(Pointer);
    System.Move(FList[Index + 1], FList[Index], MemSize);
  end;
end;

procedure TsgPointerList.Exchange(Index1, Index2: Integer);
var
  temp: Pointer;
begin
  CheckIndex(Index1, FCount);
  CheckIndex(Index2, FCount);
  temp := FList[Index1];
  FList[Index1] := FList[Index2];
  FList[Index2] := temp;
end;

function TsgPointerList.Extract(Item: Pointer): Pointer;
var
  i: Integer;
begin
  Result := nil;
  i := IndexOf(Item);
  if i >= 0 then
  begin
    Result := Item;
    FList[i] := nil;
    Delete(i);
  end;
end;

function TsgPointerList.IndexOf(Item: Pointer): Integer;
var
  P: PPointer;
begin
  P := Pointer(FList);
  for Result := 0 to FCount - 1 do
  begin
    if P^ = Item then
      exit;
    Inc(P);
  end;
  Result := -1;
end;

procedure TsgPointerList.Sort(Compare: TListSortCompare);
begin
  if Count > 1 then
    QuickSort(FList, 0, Count - 1,
      function(Item1, Item2: Pointer): Integer
      begin
        Result := Compare(Item1, Item2);
      end);
end;

procedure TsgPointerList.Reverse;
var
  b, e: Integer;
begin
  b := 0;
  e := Count - 1;
  while b < e do
  begin
    Exchange(b, e);
    Inc(b);
    Dec(e);
  end;
end;

function TsgPointerList.Get(Index: Integer): Pointer;
begin
  CheckIndex(Index, FCount);
  Result := FList[Index];
end;

procedure TsgPointerList.Put(Index: Integer; Item: Pointer);
begin
  CheckIndex(Index, FCount);
  if Item <> FList[Index] then
    FList[Index] := Item;
end;

procedure TsgPointerList.CheckCapacity(NewCount: Integer);
begin
  FFactory.CheckCapacity(FList, NewCount);
end;

procedure TsgPointerList.SetCount(NewCount: Integer);
begin
  CheckCount(NewCount);
  if NewCount > FCount then
    raise ESglError.CreateFmt(
      'Not allowed to increase the number of elements (%d)', [Count]);
  FCount := NewCount;
end;

function TsgPointerList.TraverseBy(F: TItemFunc): Pointer;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    Result := Get(i);
    if F(Result) then exit;
  end;
  Result := nil;
end;

procedure TsgPointerList.RemoveBy(F: TItemFunc);
var
  dest, src: Integer;
  item: Pointer;
begin
  dest := 0;
  for src := 0 to Count - 1 do
  begin
    item := Get(src);
    if F(item) then
      // this item will be removed
    else
    begin
      if src <> dest then
        Put(dest, item);
      Inc(dest);
    end;
  end;
  Count := dest;
end;

function TsgPointerList.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

{$EndRegion}

{$Region 'TsgRecordList<T>'}

constructor TsgRecordList<T>.From(OnFree: TFreeProc);
begin
  FList := TsgPointerList.From(sizeof(T), OnFree);
end;

procedure TsgRecordList<T>.Free;
begin
  FList.Free;
end;

procedure TsgRecordList<T>.Clear;
begin
  FList.Clear;
end;

function TsgRecordList<T>.Add(Item: PItem): Integer;
begin
  Result := FList.Add(Item);
end;

function TsgRecordList<T>.Add: PItem;
begin
  Result := FList.Add;
end;

procedure TsgRecordList<T>.Delete(Index: Integer);
begin
  FList.Delete(Index);
end;

procedure TsgRecordList<T>.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, Index2);
end;

function TsgRecordList<T>.Extract(Item: PItem): PItem;
begin
  Result := FList.Extract(Item);
end;

function TsgRecordList<T>.IndexOf(Item: PItem): Integer;
begin
  Result := FList.IndexOf(Item);
end;

procedure TsgRecordList<T>.Assign(const Source: TsgRecordList<T>);
var
  i: Integer;
begin
  Count := 0;
  for i := 0 to Source.Count - 1 do
    Add(Source.Items[i]);
end;

procedure TsgRecordList<T>.Sort(Compare: TListSortCompare);
begin
  FList.Sort(Compare);
end;

procedure TsgRecordList<T>.Reverse;
begin
  FList.Reverse;
end;

function TsgRecordList<T>.Get(Index: Integer): PItem;
begin
  Result := PItem(FList.Get(Index));
end;

procedure TsgRecordList<T>.Put(Index: Integer; Item: PItem);
begin
  FList.Put(Index, Item);
end;

procedure TsgRecordList<T>.SetCount(Value: Integer);
begin
  FList.SetCount(Value);
end;

function TsgRecordList<T>.IsEmpty: Boolean;
begin
  Result := FList.Count = 0;
end;

{$EndRegion}

{$Region 'TCustomLinkedList'}

procedure TCustomLinkedList.Init(ItemSize: Cardinal; OnFree: TFreeProc);
begin
  FRegion := HeapPool.CreateRegion(ItemSize, OnFree);
  FHead := FRegion.Alloc(FRegion.ItemSize);
  FLast := FHead;
end;

procedure TCustomLinkedList.Free;
begin
  FRegion.Free;
end;

procedure TCustomLinkedList.Clear;
begin
  FRegion.Clear;
  FHead := FRegion.Alloc(FRegion.ItemSize);
  FLast := FHead;
end;

function TCustomLinkedList.Empty: Boolean;
begin
  Result := FLast.prev = nil;
end;

function TCustomLinkedList.Count: Integer;
var
  p: PItem;
  n: Integer;
begin
  p := FHead;
  n := 0;
  while p <> FLast do
  begin
    Inc(n);
    p := p.next;
  end;
  Result := n;
end;

function TCustomLinkedList.Front: PItem;
begin
  Result := FHead;
end;

function TCustomLinkedList.Back: PItem;
begin
  Result := FLast.prev;
end;

function TCustomLinkedList.PushFront: PItem;
var
  new: PItem;
begin
  new := FRegion.Alloc(FRegion.ItemSize);
  new.next := FHead;
  FHead.prev := new;
  FHead := new;
  Result := new;
end;

function TCustomLinkedList.PushBack: PItem;
var
  p, new: PItem;
begin
  if FLast.prev = nil then
    Result := PushFront
  else
  begin
    p := FLast.prev;
    new := FRegion.Alloc(FRegion.ItemSize);
    new.next := FLast;
    new.prev := p;
    FLast.prev := new;
    p.next := new;
    Result := new;
  end;
end;

function TCustomLinkedList.Insert(const Pos: PItem): PItem;
var
  new: PItem;
begin
  new := FRegion.Alloc(FRegion.ItemSize);
  new.next := Pos.next;
  new.prev := Pos;
  Pos.next.prev := new;
  Pos.next := new;
  Result := new;
end;

procedure TCustomLinkedList.PopFront;
begin
  Check(not Empty, 'PopFront: list empty');
  FHead := FHead.next;
  FHead.prev := nil;
end;

procedure TCustomLinkedList.PopBack;
var
  p, q: PItem;
begin
  Check(not Empty, 'PopBack: list empty');
  p := FLast.prev;
  q := p.prev;
  if q = nil then
  begin
    FHead := FLast;
    FLast.prev := nil;
  end
  else
  begin
    q.next := FLast;
    FLast.prev := q;
  end;
end;

procedure TCustomLinkedList.Reverse;
var
  q, p, n: PItem;
begin
  if Empty then exit;
  q := FLast;
  p := FHead;
  n := FHead;
  while p <> FLast do
  begin
    n := n.next;
    p.prev := n;
    p.next := q;
    q := p;
    p := n;
  end;
  FLast.prev := FHead;
  FHead.next := nil;
  FHead := q;
  FHead.prev := nil;
end;

procedure TCustomLinkedList.Sort(Compare: TListSortCompare);
var
  i, n: Integer;
  pa: TsgPointerArray;
  p, q: PItem;
begin
  n := Count;
  if n <= 1 then exit;
  pa := TsgPointerArray.From(n);
  try
    p := FHead;
    while p <> FLast do
    begin
      pa.Add(p);
      p := p.next;
    end;
    pa.Sort(Compare);
    q := nil;
    for i := 0 to pa.Count - 1 do
    begin
      p := pa.Items[i];
      if i = 0 then
        FHead := p
      else
        q.next := p;
      p.prev := q;
      q := p;
    end;
    p.next := FLast;
  finally
    pa.Free
  end;
end;

{$EndRegion}

{$Region TsgLinkedList<T>.TIterator.'}

function TsgLinkedList<T>.TIterator.GetValue: PValue;
begin
  Result := @Item.Value;
end;

procedure TsgLinkedList<T>.TIterator.Next;
begin
  Item := PItem(Item.Link.next);
end;

procedure TsgLinkedList<T>.TIterator.Prev;
begin
  Item := PItem(Item.Link.prev);
end;

function TsgLinkedList<T>.TIterator.Eol: Boolean;
begin
  Result := (Item = nil) or (Item.Link.next = nil);
end;

function TsgLinkedList<T>.TIterator.Bol: Boolean;
begin
  Result := (Item = nil) or (Item.Link.prev = nil);
end;

{$EndRegion}

{$Region 'TsgLinkedList<T>'}

procedure TsgLinkedList<T>.Init(OnFree: TFreeProc);
begin
  FList.Init(sizeof(TItem), OnFree);
end;

function TsgLinkedList<T>.Insert(Pos: TIterator; const Value: T): TIterator;
begin
  Result.Item := PItem(FList.Insert(TCustomLinkedList.PItem(Pos)));
  Result.Item.Value := Value;
end;

procedure TsgLinkedList<T>.Free;
begin
  FList.Free;
end;

procedure TsgLinkedList<T>.Clear;
begin
  FList.Clear;
end;

function TsgLinkedList<T>.Empty: Boolean;
begin
  Result := FList.Empty;
end;

function TsgLinkedList<T>.Count: Integer;
begin
  Result := FList.Count;
end;

function TsgLinkedList<T>.Front: TIterator;
begin
  Result.Item := PItem(FList.Front);
end;

function TsgLinkedList<T>.Back: TIterator;
begin
  Result.Item := PItem(FList.Back);
end;

function TsgLinkedList<T>.PushFront: TIterator;
begin
  Result.Item := PItem(FList.PushFront);
end;

procedure TsgLinkedList<T>.PushFront(const Value: T);
begin
  PushFront.Value^ := Value;
end;

function TsgLinkedList<T>.PushBack: TIterator;
begin
  Result.Item := PItem(FList.PushBack);
end;

procedure TsgLinkedList<T>.PushBack(const Value: T);
begin
  PushBack.Value^ := Value;
end;

procedure TsgLinkedList<T>.PopFront;
begin
  FList.PopFront;
end;

procedure TsgLinkedList<T>.PopBack;
begin
  FList.PopBack;
end;

procedure TsgLinkedList<T>.Reverse;
begin
  FList.Reverse;
end;

procedure TsgLinkedList<T>.Sort(Compare: TListSortCompare);
begin
  FList.Sort(Compare);
end;

{$EndRegion}

{$Region 'TsgHashMapIterator<Key, T>'}

procedure TsgHashMapIterator<Key, T>.Init(const Pairs: TsgListHelper;
  vidx: Integer);
begin
  Self.Pairs := @Pairs;
  Self.vidx := vidx;
end;

class operator TsgHashMapIterator<Key, T>.Equal(
  const a, b: TsgHashMapIterator<Key, T>): Boolean;
begin
  Result := (a.Pairs = a.Pairs) and (a.vidx = b.vidx);
end;

class operator TsgHashMapIterator<Key, T>.NotEqual(
  const a, b: TsgHashMapIterator<Key, T>): Boolean;
begin
  Result := (a.Pairs <> a.Pairs) or (a.vidx <> b.vidx);
end;

procedure TsgHashMapIterator<Key, T>.Next;
begin
  Inc(vidx);
  if Cardinal(vidx) >= Cardinal(Pairs.FCount) then
    vidx := -1;
end;

function TsgHashMapIterator<Key, T>.GetKey: PKey;
var
  Pair: PsgPair;
begin
  Pair := Pairs.GetPtr(vidx);
  Result := @Pair.Key;
end;

function TsgHashMapIterator<Key, T>.GetValue: PItem;
var
  Pair: PsgPair;
begin
  Pair := Pairs.GetPtr(vidx);
  Result := @Pair.Value;
end;

{$EndRegion}

{$Region 'TsgHashMap<Key, T>'}

constructor TsgHashMap<Key, T>.From(ExpectedSize: Integer; Hash: TKeyHash;
  KeyEquals: TKeyEquals; OnFreePair: TFreeProc);
begin
  Self := Default(TsgHashMap<Key, T>);
  FSeed := SeedValue;
  FHash := Hash;
  FKeyEquals := KeyEquals;
  FPairs := TsgList<TPair<Key, T>>.From(OnFreePair);
  FCollisionRegion := HeapPool.CreateRegion(sizeof(TCollision));
  FEntries := TsgList<TEntry>.From(nil);
  SetEntriesLength(ExpectedSize);
end;

procedure TsgHashMap<Key, T>.Free;
begin
  Check(Valid);
  FCollisionRegion.Free;
  FEntries.Free;
  FPairs.Free;
  FHash := nil;
  FKeyEquals := nil;
  Fillchar(Self, sizeof(Self), 0);
end;

procedure TsgHashMap<Key, T>.Clear;
var
  OnFreePair: TFreeProc;
  ExpectedSize: Integer;
begin
  Check(Valid);
  OnFreePair := FPairs.FOnFree;
  // Delete
  ExpectedSize := FEntries.Count;
  FCollisionRegion.Free;
  FEntries.Free;
  FPairs.Free;
  // Create
  FPairs := TsgList<TPair<Key, T>>.From(OnFreePair);
  FCollisionRegion := HeapPool.CreateRegion(sizeof(TCollision));
  FEntries := TsgList<TEntry>.From(nil);
  SetEntriesLength(ExpectedSize);
end;

function TsgHashMap<Key, T>.Valid: Boolean;
begin
  Result := FSeed = SeedValue;
end;

function TsgHashMap<Key, T>.Find(k: Key): TsgHashMapIterator<Key, T>;
var
  eidx: Cardinal;
  p: PCollision;
begin
  eidx := Cardinal(FHash(k)) mod Cardinal(FEntries.Count);
  p := FEntries.GetPtr(eidx).Head;
  while p <> nil do
  begin
    if FKeyEquals(k, FPairs[p.PairIndex].Key) then
    begin
      Result.Init(FPairs.FListHelper, p.PairIndex);
      exit;
    end;
    p := p.Next;
  end;
  Result.Init(FPairs.FListHelper, -1);
end;

function TsgHashMap<Key, T>.Insert(
  const pair: TPair<Key, T>): TsgHashMapIterator<Key, T>;
var
  entry: PEntry;
  eidx, idx: Integer;
  p: PCollision;
begin
  eidx := Cardinal(FHash(pair.Key)) mod Cardinal(FEntries.Count);
  entry := FEntries.GetPtr(eidx);
  p := entry.Head;
  while p <> nil do
  begin
    if FKeyEquals(pair.Key, FPairs[p.PairIndex].Key) then
    begin
      Result.Init(FPairs.FListHelper, p.PairIndex);
      exit;
    end;
    p := p.Next;
  end;
  // Insert collision at the beginning of the list
  p := FCollisionRegion.Alloc(sizeof(TCollision));
  p.Next := entry.Head;
  entry.Head := p;
  Inc(entry.Cnt);
  idx := FPairs.Add(pair);
  p.PairIndex := idx;
  Result.Init(FPairs.FListHelper, idx);
end;

procedure TsgHashMap<Key, T>.SetEntriesLength(ExpectedSize: Integer);
var TabSize: Integer;
begin
  // the size of the entry table must be a prime number
  if ExpectedSize < 1000 then
    TabSize := 307
  else if ExpectedSize < 3000 then
    TabSize := 1103
  else if ExpectedSize < 10000 then
    TabSize := 2903
  else if ExpectedSize < 30000 then
    TabSize := 19477
  else
    TabSize := 32469;
  FEntries.Count := TabSize;
end;

function TsgHashMap<Key, T>.Begins: TsgHashMapIterator<Key, T>;
begin
  if FPairs.Count > 0 then
    Result.Init(FPairs.FListHelper, 0)
  else
    Result.Init(FPairs.FListHelper, -1);
end;

function TsgHashMap<Key, T>.Ends: TsgHashMapIterator<Key, T>;
begin
  Result.Init(FPairs.FListHelper, -1);
end;

{$EndRegion}

{$Region 'TsgTreeIterator'}

constructor TsgTreeIterator.Init(Root, Sentinel: PNode);
begin
  Stack := [Sentinel, Root, Root];
end;

function TsgTreeIterator.GetItem: Pointer;
begin
  Result := @Res^;
end;

function TsgTreeIterator.Sentinel: PNode;
begin
  Result := Stack[0];
end;

function TsgTreeIterator.Current: PPNode;
begin
  Result := @Stack[1];
end;

function TsgTreeIterator.Res: PPNode;
begin
  Result := @Stack[2];
end;

procedure TsgTreeIterator.Next;
begin
  while not Empty or (Current^ <> Sentinel) do
  begin
    if Current^ <> Sentinel then
    begin
      Push(Current^);
      Current^ := Current^.left;
    end
    else
    begin
      Current^ := Pop;
      Res^ := Current^;
      Current^ := Current^.right;
      break;
    end;
  end;
end;

function TsgTreeIterator.Pop: Pointer;
var
  Idx: Integer;
begin
  Check(not Empty, 'Stack empty');
  Idx := High(Stack);
  Result := Stack[Idx];
  SetLength(Stack, Idx);
end;

procedure TsgTreeIterator.Push(Item: Pointer);
begin
  System.Insert(Item, Stack, MaxInt);
end;

function TsgTreeIterator.Empty: Boolean;
begin
  Result := Length(Stack) <= 3;
end;

{$EndRegion}

{$Region 'TsgCustomTree'}

constructor TsgCustomTree.TParams.From(ta: TsgTreeAction);
begin
  Self := Default(TsgCustomTree.TParams);
  Self.action := ta;
end;

procedure TsgCustomTree.Init(ItemSize: Cardinal; Compare: TListSortCompare;
  Update: TUpdateProc; OnFreeNode: TFreeProc);
begin
  Self := Default(TsgCustomTree);
  Region := HeapPool.CreateRegion(ItemSize, OnFreeNode);
  Self.Compare := Compare;
  Self.Update := Update;
  CreateNode(Sentinel);
  Root := Sentinel;
end;

procedure TsgCustomTree.Free;
begin
  if Region <> nil then
    Region.Free;
  Self := Default(TsgCustomTree);
end;

procedure TsgCustomTree.Clear;
var
  ItemSize: Cardinal;
  Compare: TListSortCompare;
  Update: TUpdateProc;
  OnFree: TFreeProc;
begin
  ItemSize := Region.ItemSize;
  OnFree := Region.OnFree;
  Compare := Self.Compare;
  Update := Self.Update;
  Free;
  Init(ItemSize, Compare, Update, OnFree);
end;

procedure TsgCustomTree.Find(pval: Pointer; var iter: TsgTreeIterator);
var
  prm: TParams;
begin
  prm := TParams.From(TsgTreeAction.taFind);
  prm.pval := pval;
  Search(root, prm);
  iter.Init(prm.node, Sentinel);
end;

function TsgCustomTree.Get(pval: Pointer): PNode;
var
  prm: TParams;
begin
  prm := TParams.From(TsgTreeAction.taFind);
  prm.pval := pval;
  Search(root, prm);
  Result := prm.node;
end;

function TsgCustomTree.Count(pval: Pointer): Integer;
var
  prm: TParams;
begin
  prm := TParams.From(TsgTreeAction.taCount);
  prm.pval := pval;
  Search(root, prm);
  Result := prm.cnt;
end;

procedure TsgCustomTree.Insert(pval: Pointer);
var
  prm: TParams;
begin
  prm := TParams.From(TsgTreeAction.taInsert);
  prm.pval := pval;
  Search(root, prm);
end;

procedure TsgCustomTree.InsertOrAssign(pval: Pointer);
begin
  var prm := TParams.From(TsgTreeAction.taInsertOrAssign);
  prm.pval := pval;
  Search(root, prm);
end;

procedure TsgCustomTree.Begins(var iter: TsgTreeIterator);
begin
  iter.Init(Root, Sentinel);
end;

function TsgCustomTree.Ends: PNode;
begin
  Result := Sentinel;
end;

procedure TsgCustomTree.Search(var p: PNode; var prm: TParams);
const
  NodeSize = sizeof(TsgTreeIterator.TNode);
var
  q, r: PNode;
  pval: Pointer;
  cmp: Integer;
begin
  if p = Sentinel then
  begin
    // not found
    if prm.action = TsgTreeAction.taFind then
      prm.node := Sentinel
    else
    begin
      CreateNode(p);
      prm.h := 2;
      prm.node := p;
      if prm.action in [TsgTreeAction.taInsert, taInsertOrAssign] then
        Update(p, prm.pval);
    end
  end
  else
  begin
    pval := Pointer(NativeUInt(p) + NodeSize);
    cmp := Compare(prm.pval, pval);
    if cmp < 0 then
    begin
      Search(p.left, prm);
      if prm.h > 0 then
        if p.lh then
        begin
          q := p.left; prm.h := 2; p.lh := False;
          if q.lh then // LL
          begin
            p.left := q.right; q.lh := False;
            q.right := p; p := q;
          end
          else if q.rh then
          begin // LR
            r := q.right; q.rh := False;
            q.right := r.left; r.left := q;
            p.left := r.right; r.right := p; p := r;
          end;
        end
        else
        begin
          Dec(prm.h);
          if prm.h > 0 then p.lh := True;
        end;
    end
    else if cmp > 0 then
    begin
      Search(p.right, prm);
      if prm.h > 0 then
        if p.rh then
        begin
          q := p.right; prm.h := 2; p.rh := False;
          if q.rh then  // RR
          begin
            p.right := q.left;
            q.left := p; q.rh := False; p := q;
          end
          else
          begin  // RL
            r := q.left; q.lh := False;
            q.left := r.right; r.right := q;
            p.right := r.left; r.left := p; p := r;
          end;
        end
        else
        begin
          Dec(prm.h);
          if prm.h > 0 then p.rh := True;
        end;
    end
    else
    begin
      // found
      prm.node := p;
      Inc(prm.cnt);
      prm.h := 0;
      if prm.action = TsgTreeAction.taInsertOrAssign then
        Update(p, prm.pval);
    end;
  end;
end;

procedure TsgCustomTree.CreateNode(var p: PNode);
begin
  p := Region.Alloc(Region.ItemSize);
  p.left := Sentinel;
  p.right := Sentinel;
  p.lh := False;
  p.rh := False;
end;

procedure TsgCustomTree.Inorder(Visit: TNodeProc);
begin
  Self.Visit := Visit;
  Visiter(Root);
end;

procedure TsgCustomTree.Visiter(node: PNode);
begin
  if node <> Sentinel then
  begin
    Visiter(node.left);
    Visit(node);
    Visiter(node.right);
  end;
end;

{$EndRegion}

{$Region 'TsgMapIterator<Key, T>'}

constructor TsgMapIterator<Key, T>.Init(Root, Sentinel: TsgTreeIterator.PNode);
begin
  Iter.Init(Root, Sentinel);
end;

class operator TsgMapIterator<Key, T>.Equal(
  const a: TsgMapIterator<Key, T>; b: PNode): Boolean;
begin
  Result := a.Iter.Res^ = TsgTreeIterator.PNode(b);
end;

class operator TsgMapIterator<Key, T>.NotEqual(
  const a: TsgMapIterator<Key, T>; b: PNode): Boolean;
begin
  Result := a.Iter.Res^ <> TsgTreeIterator.PNode(b);
end;

function TsgMapIterator<Key, T>.GetKey: PKey;
begin
  Result := @PNode(Iter.Res^).k;
end;

function TsgMapIterator<Key, T>.GetValue: PItem;
begin
  Result := @PNode(Iter.Res^).v;
end;

procedure TsgMapIterator<Key, T>.Next;
begin
  Iter.Next;
end;

{$EndRegion}

{$Region 'TsgMap<Key, T>'}

constructor TsgMap<Key, T>.From(Compare: TListSortCompare;
  OnFreeNode: TFreeProc);
var size: Integer;
begin
  size := sizeof(TsgMapIterator<Key, T>.TNode);
  tree.Init(size, Compare, UpdateValue, OnFreeNode);
end;

procedure TsgMap<Key, T>.Free;
begin
  tree.Free;
end;

procedure TsgMap<Key, T>.Clear;
begin
  tree.Clear;
end;

function TsgMap<Key, T>.Find(const k: Key): TsgMapIterator<Key, T>;
begin
  tree.Find(@k, Result.Iter);
end;

function TsgMap<Key, T>.Count(const k: Key): Integer;
begin
  Result := tree.Count(@k);
end;

function TsgMap<Key, T>.Begins: TsgMapIterator<Key, T>;
begin
  tree.Begins(Result.Iter);
end;

procedure TsgMap<Key, T>.Insert(const pair: TPair<Key, T>);
begin
  tree.Insert(@pair);
end;

function TsgMap<Key, T>.Emplace(const k: Key): PNode;
var
  prm: TsgCustomTree.TParams;
begin
  prm := TsgCustomTree.TParams.From(TsgTreeAction.taInsertEmpty);
  prm.pval := @k;
  tree.Search(tree.root, prm);
  Result := PNode(prm.node);
  Result.k := k;
end;

procedure TsgMap<Key, T>.InsertOrAssign(const pair: TPair<Key, T>);
begin
  tree.Insert(@pair);
end;

function TsgMap<Key, T>.Ends: PNode;
begin
  Result := PNode(tree.Ends);
end;

procedure TsgMap<Key, T>.Inorder(Visit: TNodeProc);
begin
  tree.Inorder(TsgCustomTree.TNodeProc(Visit));
end;

function TsgMap<Key, T>.Get(index: Key): PItem;
var
  p: TsgTreeIterator.PNode;
begin
  p := tree.Get(@index);
  if p = tree.Ends then
    Result := nil
  else
    Result := @(PNode(p)^).v;
end;

procedure TsgMap<Key, T>.Put(index: Key; const Value: PItem);
var
  pair: TPair<Key, T>;
begin
  pair.Key := index;
  pair.Value := Value^;
  tree.Insert(@pair);
end;

procedure TsgMap<Key, T>.UpdateValue(pnd: TsgCustomTree.PNode; pval: Pointer);
type
  TPr = TPair<Key, T>;
  PT = ^Tpr;
begin
  PNode(pnd).pair := PT(pval)^;
end;

{$EndRegion}

{$Region 'TsgSetIterator<Key, T>'}

constructor TsgSetIterator<Key>.Init(Root, Sentinel: PNode);
begin
  Iter.Init(TsgTreeIterator.PNode(Root), TsgTreeIterator.PNode(Sentinel));
end;

class operator TsgSetIterator<Key>.Equal(
  const a: TsgSetIterator<Key>; b: PNode): Boolean;
begin
  Result := a.Iter.Res^ = TsgTreeIterator.PNode(b);
end;

class operator TsgSetIterator<Key>.NotEqual(
  const a: TsgSetIterator<Key>; b: PNode): Boolean;
begin
  Result := a.Iter.Res^ <> TsgTreeIterator.PNode(b);
end;

function TsgSetIterator<Key>.GetKey: PKey;
begin
  Result := @PNode(Iter.Res^).k;
end;

procedure TsgSetIterator<Key>.Next;
begin
  Iter.Next;
end;

{$EndRegion}

{$Region 'TsgSet<Key>'}

procedure TsgSet<Key>.Init(Compare: TListSortCompare; OnFree: TFreeProc);
begin
  tree.Init(sizeof(TsgSetIterator<Key>.TNode), Compare, UpdateValue, OnFree);
end;

procedure TsgSet<Key>.Free;
begin
  tree.Free;
end;

procedure TsgSet<Key>.Clear;
begin
  tree.Clear;
end;

function TsgSet<Key>.Find(const k: Key): TsgSetIterator<Key>;
begin
  tree.Find(@k, Result.Iter);
end;

function TsgSet<Key>.Count(const k: Key): Integer;
begin
  Result := tree.Count(@k);
end;

procedure TsgSet<Key>.Insert(const k: Key);
begin
  tree.Insert(@k);
end;

procedure TsgSet<Key>.Inorder(Visit: TNodeProc);
begin
  tree.Inorder(TsgCustomTree.TNodeProc(Visit));
end;

function TsgSet<Key>.Begins: TsgSetIterator<Key>;
begin
  tree.Begins(Result.Iter);
end;

function TsgSet<Key>.Ends: PNode;
begin
  Result := PNode(tree.Ends);
end;

procedure TsgSet<Key>.UpdateValue(pnd: TsgCustomTree.PNode; pval: Pointer);
type
  PK = ^Key;
begin
  PNode(pnd).k := PK(pval)^;
end;

{$EndRegion}

{$Region 'TsgLog'}

procedure TsgLog.Init;
begin
  FLog := TStringList.Create;
end;

procedure TsgLog.Free;
begin
  FreeAndNil(FLog);
end;

procedure TsgLog.SaveToFile(const filename: string);
begin
  FLog.SaveToFile(filename);
  FLog.Clear;
end;

procedure TsgLog.AddLine(const Msg: string);
begin
  FLog.Add(Msg);
end;

procedure TsgLog.print(const Msg: string);
begin
  AddLine(Msg);
end;

procedure TsgLog.print(const Msg: string; const Args: array of const);
var
  i: Integer;
  s, v: string;
  Arg: TVarRec;
begin
  s := Msg;
  for i := 0 to High(Args) do
  begin
    Arg := Args[i];
    case Arg.VType of
      vtInteger:
        v := IntToStr(Arg.VInteger);
      vtInt64:
        v := IntToStr(Arg.VInt64^);
      vtExtended, vtCurrency:
        v := Format('%.4f', [Arg.VExtended^]);
      vtUnicodeString:
        v := string(Arg.VUnicodeString);
      vtChar, vtWideChar:
        v := Char(Arg.VChar);
      else
        raise ESglError.Create('print: unsupported parameter type');
    end;
    s := s + v;
  end;
  AddLine(s);
end;

procedure TsgLog.Msg(const Msg: string);
begin
  AddLine(Msg);
end;

procedure TsgLog.Msg(const fmt: string; const Args: array of const);
begin
  AddLine(Format(fmt, Args));
end;

{$EndRegion}

end.

