﻿(* Standard Generic Library (SGL) for Pascal
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

unit Oz.SGL.Heap;

interface

{$Region 'Uses'}

uses
  System.SysUtils, System.Math, System.Generics.Collections;

{$EndRegion}

{$T+}

{$Region 'Forward declarations'}

type
  THeapPool = class;
  TFreeProc = procedure(Item: Pointer);
  TPairItemsProc = procedure(A, B: Pointer);
  THashProc = function(Key: Pointer): Cardinal;
  TEqualsFunc = function(A, B: Pointer): Boolean;

{$Region 'TsgUtils'}

{$Region 'ESglError'}

  ESglError = class(Exception)
  const
    NotImplemented = 0;
    ListIndexError = 1;
    ListCountError = 2;
    ErrorMax = 2;
  private type
    TErrorMessages = array [0..ErrorMax] of string;
  private const
    ErrorMessages: TErrorMessages = (
      'Not implemented',
      'List index error (%d)',
      'List count error (%d)');
  public
    constructor Create(ErrNo: Integer); overload;
    constructor Create(ErrNo, IntParam: Integer); overload;
  end;

{$EndRegion}

{$Region 'TsgMeta: metadata for item of some type'}

  TsgMeta = record
  var
    TypeInfo: Pointer;
    ItemSize: Cardinal;
    TypeKind: System.TTypeKind;
    ManagedType: Boolean;
    HasWeakRef: Boolean;
  public
    procedure Init<T>;
  end;
  PsgMeta = ^TsgMeta;

{$EndRegion}

{$Region 'TsgItem: structure for a collection item of some type'}

  TsgItem = record
  type
    TAssignProc = procedure(const Value) of object;
    TFreeProc = procedure of object;
  var
    Item: Pointer;
    Meta: PsgMeta;
    Assign: TAssignProc;
    Free: TFreeProc;
  private
    // Item^ := Value;
    procedure Assign1(const Value);
    procedure Assign2(const Value);
    procedure Assign4(const Value);
    procedure Assign8(const Value);
    procedure AssignItem(const Value);
    procedure AssignManaged(const Value);
    procedure AssignVariant(const Value);
    procedure AssignMRef(const Value);
    // Item.Free;
    procedure Free1;
    procedure Free2;
    procedure Free4;
    procedure Free8;
    procedure FreeItem;
    procedure FreeManaged;
    procedure FreeVariant;
    procedure FreeMRef;
  public
    procedure Init(var Value; const Meta: TsgMeta; OnFree: TsgItem.TFreeProc = nil);
  end;

{$EndRegion}

{$Region 'TsgItemProc'}

  PsgItemProc = ^TsgItemProc;
  TsgItemProc = record
  var
    FTypeInfo: Pointer;
    FFreeProc: TFreeProc;
    FAssignProc: TPairItemsProc;
  public
    procedure Init<T>;
    // Item := Default(T);
    class procedure Free<T>(var Item: T); static;
    // A := B;
    class procedure Assign<T>(var A, B: T); static;
    // A <=> B;
    class procedure Swap<T>(var A, B: T); static;
  end;

  PsgPairProc = ^TsgPairProc;
  TsgPairProc = record
  var
    HashProc: THashProc;
    EqualsFunc: TEqualsFunc;
    FreePairProc: TFreeProc;
  public
    procedure Init<Key, Value>(Hash: THashProc; Equals: TEqualsFunc; Free: TFreeProc);
  end;

{$EndRegion}

{$Region 'TMemSegment'}

  PMemSegment = ^TMemSegment;

  TMemSegment = record
  private
    Next: PMemSegment;
    HeapSize: Cardinal;
    FreePtr: Pointer;
    FreeSize: Cardinal;
  public
    function GetHeapRef: Pointer; inline;
    procedure CheckPointer(Ptr: Pointer; Size: Cardinal);
    function Occupy(Size: Cardinal): Pointer;
  end;

{$EndRegion}

{$Region 'TMemoryRegion'}

  PMemoryRegion = ^TMemoryRegion;
  TMemoryRegion = record
  private const
    Seed = 46147635;
  private
    FSeed: Integer;
    Heap: PMemSegment;
    IsSegmented: Boolean;
    Used: Boolean;
    FItemSize: Cardinal;
    BlockSize: Cardinal;
    FCapacity: Integer;
    FOnFree: TFreeProc;
    procedure GrowHeap(NewCount: Integer);
    function Grow(NewCount: Integer): Integer;
    function GetOccupiedCount(S: PMemSegment): Integer;
    procedure FreeHeap(var Heap: PMemSegment);
    procedure FreeItems(p: PMemSegment);
    function Valid: Boolean;
  public
    // Segmented region provides immutable pointer addresses
    procedure Init(IsSegmented: Boolean; ItemSize, BlockSize: Cardinal; OnFree: TFreeProc);
    // Free the region
    procedure Free;
    // Erases all elements from the memory region.
    procedure Clear;
    // Increase capacity
    function IncreaseCapacity(NewCount: Integer): Pointer;
    // Increase capacity and allocate
    function IncreaseAndAlloc(NewCount: Integer): Pointer;
    // Allocate memory of a specified size and return its pointer
    function Alloc(Size: Cardinal): Pointer;
    // Get a pointer to an element of an array of the specified type
    function GetItemPtr<T>(Index: Integer): Pointer;
    // Get a piece of memory as an array element of the specified type
    procedure GetItemAs<T>(Index: Integer; var Item: T);
    // propeties
    property OnFree: TFreeProc read FOnFree;
    property Capacity: Integer read FCapacity;
    property ItemSize: Cardinal read FItemSize;
  end;

{$EndRegion}

{$Region 'TsgItemFactory: Factory of list items using the memory pool'}

  TsgPointersArrayRange = 0..$7FFFFFFF div (sizeof(Pointer) * 2) - 1;
  TsgPointers = array [TsgPointersArrayRange] of Pointer;
  PsgPointers = ^TsgPointers;

  PsgItemFactory = ^TsgItemFactory;
  TsgItemFactory = record
  private
    // region for pointers
    FListRegion: PMemoryRegion;
    // region for items
    FItemsRegion: PMemoryRegion;
    // item size
    FItemSize: Cardinal;
  public
    constructor From(ItemSize: Integer; OnFree: TFreeProc);
    procedure Free;
    // Change the list capacity and return the heap address to store list pointers
    procedure CheckCapacity(var List: PsgPointers; NewCount: Integer);
    // Add an element and return its pointer
    function AddItem(Item: Pointer): Pointer;
    // Create an empty item and return its pointer
    function CreateItem: Pointer;
    property ItemSize: Cardinal read FItemSize;
    property ItemsRegion: PMemoryRegion read FItemsRegion;
  end;

{$EndRegion}

{$Region 'THeapPool: Memory Pool'}

  // List item
  PRegionItem = ^TRegionItem;

  TRegionItem = record
    r: TMemoryRegion;
    Next: PRegionItem;
  end;

  // List of memory regions
  TRegionItems = record
    root: PRegionItem;
    procedure Init; inline;
    // Add region
    procedure Add(p: PRegionItem);
    // Remove from the list
    function Remove: PRegionItem;
    // List is empty
    function Empty: Boolean; inline;
  end;

  THeapPool = class
  private const
    Seed = 45647631;
  strict private
    FSeed: Integer;
    FRegions: PMemoryRegion;
    FRealesed: TRegionItems;
    FBlockSize: Cardinal;
    // Occupy region
    function FindOrCreateRegion(IsSegmented: Boolean; ItemSize: Cardinal;
      OnFree: TFreeProc): PMemoryRegion;
  public
    constructor Create(BlockSize: Cardinal = 8 * 1024);
    destructor Destroy; override;
    // Create a continuous region (e.g. memory for arrays)
    function CreateUnbrokenRegion(ItemSize: Cardinal;
      OnFree: TFreeProc = nil): PMemoryRegion;
    // Create a segmented region (for elements with a fixed address)
    function CreateRegion(ItemSize: Cardinal;
      OnFree: TFreeProc = nil): PMemoryRegion;
    // Release the region
    procedure Release(r: PMemoryRegion);
    function Valid: Boolean;
  end;

{$EndRegion}

{$Region 'Procedures and functions'}

// Return main memory pool
function HeapPool: THeapPool;

// Clear main memory pool
procedure ClearHeapPool;

procedure Check(ok: Boolean; const Msg: string = '');

procedure FatalError(const Msg: string);

{$EndRegion}

implementation

var
  FHeapPool: THeapPool = nil;

{$Region 'Procedures and functions'}

function HeapPool: THeapPool;
begin
  if FHeapPool = nil then
    FHeapPool := THeapPool.Create;
  Result := FHeapPool;
end;

procedure ClearHeapPool;
begin
  FreeAndNil(FHeapPool);
end;

procedure Check(ok: Boolean; const Msg: string = '');
begin
  if ok then
    exit;
  if Msg = '' then
    raise ESglError.Create('Check error')
  else
    raise ESglError.Create(Msg);
end;

procedure FatalError(const Msg: string);
begin
  raise ESglError.Create(Msg);
end;

{$EndRegion}

{$Region 'ESglError'}

constructor ESglError.Create(ErrNo: Integer);
var
  Msg: string;
begin
  if InRange(ErrNo, 0, ErrorMax) then
    Msg := ErrorMessages[ErrNo]
  else
    Msg := 'Error: ' + IntToStr(ErrNo);
  Create(Msg);
end;

constructor ESglError.Create(ErrNo, IntParam: Integer);
var
  Msg: string;
begin
  if InRange(ErrNo, 0, ErrorMax) then
    Msg := ErrorMessages[ErrNo]
  else
    Msg := 'Error: ' + IntToStr(ErrNo);
  CreateFmt(Msg, [IntParam]);
end;

{$EndRegion}

{$Region 'TsgItem'}

procedure TsgItem.Assign1(const Value);
begin
  PByte(Item)^ := Byte(Value)
end;

procedure TsgItem.Assign2(const Value);
begin
  PWord(Item)^ := Word(Value)
end;

procedure TsgItem.Assign4(const Value);
begin
  PCardinal(Item)^ := Cardinal(Value);
end;

procedure TsgItem.Assign8(const Value);
begin
  PUInt64(Item)^ := UInt64(Value);
end;

procedure TsgItem.AssignItem(const Value);
begin
  Move(Value, Item^, Meta.ItemSize);
end;

procedure TsgItem.AssignManaged(const Value);
begin
  System.CopyArray(Item, @Value, Meta.TypeInfo, 1);
end;

procedure TsgItem.AssignVariant(const Value);
begin
  PVariant(Item)^ := Variant(Value)
end;

procedure TsgItem.AssignMRef(const Value);
type
  PBytes = ^TBytes;
  PInterface = ^IInterface;
begin
  if not IsConstValue(Meta.TypeKind) then
    raise ESglError.Create(ESglError.NotImplemented);
  case Meta.TypeKind of
    TTypeKind.tkUString: PString(Item)^ := string(Value);
    TTypeKind.tkDynArray: PBytes(Item)^ := TBytes(Value);
    TTypeKind.tkInterface: PInterface(Item)^ := IInterface(Value);
{$IF Defined(AUTOREFCOUNT)}
    TTypeKind.tkClass: PObject(Item)^ := TObject(Value);
{$ENDIF}
    TTypeKind.tkLString: PRawByteString(Item)^ := RawByteString(Value);
{$IF not Defined(NEXTGEN)}
    TTypeKind.tkWString: PWideString(Item)^ := WideString(Value);
{$ENDIF}
  end;
end;

procedure TsgItem.Free1;
begin
  PByte(Item)^ := 0;
end;

procedure TsgItem.Free2;
begin
  PByte(Item)^ := 0;
end;

procedure TsgItem.Free4;
begin
  PByte(Item)^ := 0;
end;

procedure TsgItem.Free8;
begin
  PByte(Item)^ := 0;
end;

procedure TsgItem.FreeItem;
begin
  FillChar(Item^, Meta.ItemSize, 0);
end;

procedure TsgItem.FreeManaged;
begin
  FinalizeArray(Item, Meta.TypeInfo, 1);
  FillChar(Item^, Meta.ItemSize, 0);
end;

procedure TsgItem.FreeMRef;
begin
  FinalizeArray(Item, Meta.TypeInfo, 1);
  PPointer(Item^) := nil;
end;

procedure TsgItem.FreeVariant;
begin
  PVariant(Item)^.Clear;
end;

procedure TsgItem.Init(var Value; const Meta: TsgMeta; OnFree: TsgItem.TFreeProc);
begin
  Self.Item := @Value;
  Self.Meta := @Meta;
  if Meta.ManagedType then
  begin
    if (Meta.ItemSize = SizeOf(Pointer)) and not Meta.HasWeakRef and
      not (Meta.TypeKind in [tkRecord, tkMRecord]) then
    begin
      Self.Assign := AssignMRef;
      if not Assigned(OnFree) then
        Self.Free := FreeMRef;
    end
    else if Meta.TypeKind = TTypeKind.tkVariant then
    begin
      Self.Assign := AssignVariant;
      if not Assigned(OnFree) then
        Self.Free := FreeVariant;
    end
    else
    begin
      Self.Assign := AssignManaged;
      if not Assigned(OnFree) then
        Self.Free := FreeManaged;
    end
  end
  else
    case Meta.ItemSize of
      0, 3, 5, 6, 7:
        raise ESglError.Create('impossible');
      1:
        begin
          Self.Assign := Assign1;
          if not Assigned(OnFree) then
            Self.Free := Free1;
        end;
      2:
        begin
          Self.Assign := Assign2;
          if not Assigned(OnFree) then
            Self.Free := Free2;
        end;
      4:
        begin
          Self.Assign := Assign4;
          if not Assigned(OnFree) then
            Self.Free := Free4;
        end;
      8:
        begin
          Self.Assign := Assign8;
          if not Assigned(OnFree) then
            Self.Free := Free8;
        end;
      else
      begin
        Self.Assign := AssignItem;
        if not Assigned(OnFree) then
          Self.Free := FreeItem;
      end;
    end;
end;

{$EndRegion}

{$Region 'TsgMeta'}

procedure TsgMeta.Init<T>;
begin
  TypeInfo := System.TypeInfo(T);
  TypeKind := System.GetTypeKind(T);
  ManagedType := System.IsManagedType(T);
  HasWeakRef := System.HasWeakRef(T);
  ItemSize := sizeof(T);
end;

{$EndRegion}

{$Region 'TsgItemProc'}

procedure TsgItemProc.Init<T>;
begin
  FFreeProc := TFreeProc(@TsgItemProc.Free<T>);
  FTypeInfo := TypeInfo(TArray<T>);
end;

class procedure TsgItemProc.Free<T>(var Item: T);
begin
  Item := Default(T);
end;

class procedure TsgItemProc.Assign<T>(var A, B: T);
begin
  A := B;
end;

class procedure TsgItemProc.Swap<T>(var A, B: T);
var
  Temp: T;
begin
  Temp := A;
  A := B;
  B := Temp;
end;

{$EndRegion}

{$Region 'TsgPairProc'}

procedure TsgPairProc.Init<Key, Value>(Hash: THashProc; Equals: TEqualsFunc; Free: TFreeProc);
begin
  HashProc := Hash;
  EqualsFunc := Equals;
  FreePairProc := Free;
end;

{$EndRegion}

{$Region 'TMemSegment'}

procedure NewSegment(var p: PMemSegment; HeapSize: Cardinal);
begin
  // Create a new memory segment
  GetMem(p, HeapSize);
  p.Next := nil;
  p.HeapSize := HeapSize;
  // Determine the size of free memory
  p.FreeSize := p.HeapSize - sizeof(TMemSegment);
  // Set the free memory pointer to the rest of the block
  p.FreePtr := Pointer(NativeUInt(p) + sizeof(TMemSegment));
  FillChar(p.FreePtr^, p.FreeSize, 0);
end;

procedure IncreaseHeapSize(var p: PMemSegment; NewHeapSize: Cardinal);
var
  OldHeapSize, OldFreeSize: Cardinal;
begin
  Check((p <> nil) and (NewHeapSize > p.HeapSize), 'IncreaseHeapSize error');
  OldHeapSize := p.HeapSize;
  OldFreeSize := p.FreeSize;
  ReallocMem(p, NewHeapSize);
  // Increase memory segment size
  p.HeapSize := NewHeapSize;
  // Increase the size of free memory
  p.FreeSize := OldFreeSize + NewHeapSize - OldHeapSize;
  // Set the free memory pointer to the rest of the block
  p.FreePtr := Pointer(NativeUInt(p) + p.HeapSize - p.FreeSize);
  FillChar(p.FreePtr^, p.FreeSize, 0);
end;

function TMemSegment.Occupy(Size: Cardinal): Pointer;
begin
  // if there is not enough memory
  if FreeSize < Size then
    exit(nil);
  Result := FreePtr;
{$IFDEF DEBUG}
  CheckPointer(Result, Size);
{$ENDIF}
  // reduce its size
  FreeSize := FreeSize - Size;
  // offset free memory pointer
  FreePtr := Pointer(NativeUInt(FreePtr) + Size);
end;

procedure TMemSegment.CheckPointer(Ptr: Pointer; Size: Cardinal);
var
  lo, hi: NativeUInt;
begin
  lo := NativeUInt(@Self) + sizeof(TMemSegment);
  hi := NativeUInt(@Self) + HeapSize - Size;
  Check(InRange(NativeUInt(Ptr), lo, hi));
end;

function TMemSegment.GetHeapRef: Pointer;
begin
  Result := Pointer(NativeUInt(@Self) + sizeof(TMemSegment));
end;

{$EndRegion}

{$Region 'TMemoryRegion'}

procedure TMemoryRegion.Init(IsSegmented: Boolean;
  ItemSize, BlockSize: Cardinal; OnFree: TFreeProc);
begin
  Self.FSeed := Seed;
  Self.IsSegmented := IsSegmented;
  Self.Used := True;
  Self.BlockSize := BlockSize;
  Self.FItemSize := ItemSize;
  Self.FCapacity := 0;
  Self.Heap := nil;
  Self.FOnFree := OnFree;
end;

function TMemoryRegion.Valid: Boolean;
begin
  Result := FSeed = Seed;
end;

procedure TMemoryRegion.Clear;
begin
  // Clear the memory of all segments.
  // Return to the heap memory of all segments except the first.
  FreeHeap(Heap.Next);
  FreeItems(Heap);
  // Determine the size of free memory
  Heap.FreeSize := Heap.HeapSize - sizeof(TMemSegment);
  // Set the free memory pointer to the rest of the block
  Heap.FreePtr := Pointer(NativeUInt(Heap) + sizeof(TMemSegment));
  FillChar(Heap.FreePtr^, Heap.FreeSize, 0);
end;

procedure TMemoryRegion.Free;
begin
  FreeHeap(Heap);
end;

procedure TMemoryRegion.FreeHeap(var Heap: PMemSegment);
var
  p, q: PMemSegment;
begin
  p := Heap;
  while p <> nil do
  begin
    q := p.Next;
    FreeItems(p);
    FreeMem(p);
    p := q;
  end;
  Heap := nil;
end;

procedure TMemoryRegion.FreeItems(p: PMemSegment);
var
  N: Integer;
  Ptr: Pointer;
  a, b: NativeUInt;
begin
  if Assigned(OnFree) then
  begin
    Ptr := p.GetHeapRef;
    N := GetOccupiedCount(p);
    while N > 0 do
    begin
      OnFree(Ptr);
      a := NativeUInt(Ptr);
      Ptr := Pointer(NativeUInt(Ptr) + FItemSize);
      b := NativeUInt(Ptr);
      Check(a + FItemSize = b);
      Dec(N);
    end;
  end;
end;

function TMemoryRegion.IncreaseCapacity(NewCount: Integer): Pointer;
begin
  GrowHeap(NewCount);
  Result := Heap.GetHeapRef;
end;

function TMemoryRegion.IncreaseAndAlloc(NewCount: Integer): Pointer;
var
  Old, Size: Integer;
begin
  Old := Capacity;
  Result := IncreaseCapacity(NewCount);
  Size := (Capacity - Old) * Integer(FItemSize);
  Alloc(Size);
end;

function TMemoryRegion.GetOccupiedCount(S: PMemSegment): Integer;
begin
  Result := (S.HeapSize - sizeof(TMemSegment) - S.FreeSize) div FItemSize;
end;

procedure TMemoryRegion.GrowHeap(NewCount: Integer);
var
  BlockCount, Size, NewHeapSize: Cardinal;
  p: PMemSegment;
begin
  Size := Grow(NewCount) * Integer(FItemSize);
  BlockCount := (Size + sizeof(TMemoryRegion)) div BlockSize + 1;
  NewHeapSize := BlockCount * BlockSize;
  if Heap = nil then
    // create a new segment
    NewSegment(Heap, NewHeapSize)
  else if not IsSegmented then
    // increase the size of the memory segment
    IncreaseHeapSize(Heap, NewHeapSize)
  else
  begin
    // create a new segment and place it at the beginning of the list
    NewSegment(p, NewHeapSize);
    p.Next := Heap;
    Heap := p;
  end;
  FCapacity := (Heap.HeapSize - sizeof(TMemSegment)) div FItemSize;
end;

function TMemoryRegion.Grow(NewCount: Integer): Integer;
begin
  Result := Capacity;
  repeat
    if Result > 64 then
      Result := (Result * 3) div 2
    else
      Result := Result + 16;
    if Result < 0 then
      OutOfMemoryError;
  until Result >= NewCount;
end;

function TMemoryRegion.Alloc(Size: Cardinal): Pointer;
begin
{$IFDEF DEBUG}
  Check(Valid and (Size mod FItemSize = 0));
{$ENDIF}
  if (Heap = nil) or (Heap.FreeSize < Size) then
    GrowHeap(Size div FItemSize + 1);
  Result := Heap.Occupy(Size);
  if Result = nil then
    OutOfMemoryError;
end;

function TMemoryRegion.GetItemPtr<T>(Index: Integer): Pointer;
var
  ItemsPtr: Pointer;
begin
  ItemsPtr := Heap.GetHeapRef;
  Result := Pointer(NativeUInt(ItemsPtr) + NativeUInt(index * sizeof(T)));
end;

procedure TMemoryRegion.GetItemAs<T>(Index: Integer; var Item: T);
type
  PItem = ^T;
var
  p: Pointer;
begin
  p := GetItemPtr<T>(index);
  Item := PItem(p)^;
end;

{$EndRegion}

{$Region 'TsgItemFactory'}

constructor TsgItemFactory.From(ItemSize: Integer; OnFree: TFreeProc);
begin
  FListRegion := HeapPool.CreateUnbrokenRegion(sizeof(Pointer));
  FItemSize := ItemSize;
  FItemsRegion := HeapPool.CreateRegion(ItemSize, OnFree);
end;

procedure TsgItemFactory.Free;
begin
  FItemsRegion.Free;
  FListRegion.Free;
  FItemSize := 0;
end;

procedure TsgItemFactory.CheckCapacity(var List: PsgPointers; NewCount: Integer);
begin
  if FListRegion.Capacity <= NewCount then
    List := FListRegion.IncreaseAndAlloc(NewCount);
end;

function TsgItemFactory.AddItem(Item: Pointer): Pointer;
begin
  Result := ItemsRegion.Alloc(FItemSize);
  // todo:
  Move(Item^, Result^, FItemSize);
end;

function TsgItemFactory.CreateItem: Pointer;
begin
  Result := ItemsRegion.Alloc(FItemSize);
end;

{$EndRegion}

{$Region 'TRegionItems'}

procedure TRegionItems.Init;
begin
  root := nil;
end;

procedure TRegionItems.Add(p: PRegionItem);
begin
  p.Next := root;
  root := p;
end;

function TRegionItems.Remove: PRegionItem;
var
  p: PRegionItem;
begin
  p := root;
  root := p.Next;
  p.Next := nil;
  Result := p;
end;

function TRegionItems.Empty: Boolean;
begin
  Result := root = nil;
end;

{$EndRegion}

{$Region 'THeapPool'}

procedure FreeRegion(Ptr: Pointer);
var
  Item: PRegionItem;
begin
  Item := PRegionItem(Ptr);
  Item.r.FreeHeap(Item.r.Heap);
end;

constructor THeapPool.Create(BlockSize: Cardinal);
begin
  inherited Create;
  FSeed := Seed;
  FBlockSize := BlockSize;
  New(FRegions);
  FRegions.Init(True, sizeof(TMemoryRegion), BlockSize, FreeRegion);
  FRealesed.Init;
end;

destructor THeapPool.Destroy;
begin
  if FRegions <> nil then
  begin
    FRegions.Free;
    Dispose(FRegions);
    FRegions := nil;
  end;
  inherited;
end;

function THeapPool.CreateUnbrokenRegion(ItemSize: Cardinal;
  OnFree: TFreeProc): PMemoryRegion;
begin
  Result := FindOrCreateRegion(False, ItemSize, OnFree);
end;

function THeapPool.CreateRegion(ItemSize: Cardinal;
  OnFree: TFreeProc): PMemoryRegion;
begin
  Result := FindOrCreateRegion(True, ItemSize, OnFree);
end;

function THeapPool.FindOrCreateRegion(IsSegmented: Boolean; ItemSize: Cardinal;
  OnFree: TFreeProc): PMemoryRegion;
var
  p: PRegionItem;
begin
  if not FRealesed.Empty then
    p := FRealesed.Remove
  else
    p := FRegions.Alloc(sizeof(TMemoryRegion));
  p.r.Init(IsSegmented, ItemSize, FBlockSize, OnFree);
  Result := @p.r;
end;

procedure THeapPool.Release(r: PMemoryRegion);
begin
  try
    r.FreeHeap(r.Heap);
  except
  end;
end;

function THeapPool.Valid: Boolean;
begin
  Result := FSeed = Seed;
end;

{$EndRegion}

initialization

finalization

ClearHeapPool;

end.
