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

unit Oz.SGL.Heap;

interface

{$Region 'Uses'}

uses
  System.SysUtils, System.Math;

{$EndRegion}

{$T+}

{$Region 'Forward declarations'}

type
  TCompareProc = function(const A, B): Integer of object;
  TFreeItem = procedure(p: Pointer) of object;
  TFreeProc = procedure(p: Pointer);
  TEqualsFunc = function(const A, B): Boolean;
  THashProc = function(const Value): Cardinal;

{$EndRegion}

{$Region 'ESglError'}

  ESglError = class(Exception)
  const
    NotImplemented = 0;
    ListIndexError = 1;
    ListCountError = 2;
    IncompatibleDataType = 3;
    ErrorMax = 3;
  private type
    TErrorMessages = array [0..ErrorMax] of string;
  private const
    ErrorMessages: TErrorMessages = (
      'Not implemented',
      'List index error (%d)',
      'List count error (%d)',
      'Incompatible data type');
  public
    constructor Create(ErrNo: Integer); overload;
    constructor Create(ErrNo, IntParam: Integer); overload;
  end;

{$EndRegion}

{$Region 'TsgItemMeta: metadata for item of some type'}

type

  // Action to remove an element from the collection
  TRemoveAction = (
    HoldValue = 0,  // Hold the item value
    Clear = 1,      // Clear the item value
    Reuse = 2,      // Clear the item value and allow reuse
    Other = 3);     // Reserved

  // packed collection flags
  hMeta = packed record
  private const
    Seed: Word = 25117;
    function GetTypeKind: System.TTypeKind;
    function GetManagedType: Boolean;
    function GetHasWeakRef: Boolean;
    function GetSegmented: Boolean;
    procedure SetSegmented(const Value: Boolean);
    function GetRangeCheck: Boolean;
    procedure SetRangeCheck(const Value: Boolean);
    function GetNotification: Boolean;
    procedure SetNotification(const Value: Boolean);
    function GetOwnedObject: Boolean;
    procedure SetOwnedObject(const Value: Boolean);
    function GetRemoveAction: TRemoveAction;
    procedure SetRemoveAction(const Value: TRemoveAction);
  public
    constructor From(TypeKind: System.TTypeKind; ManagedType, HasWeakRef: Boolean);
    function Valid: Boolean; inline;
    // property
    property TypeKind: System.TTypeKind read GetTypeKind;
    property ManagedType: Boolean read GetManagedType;
    property HasWeakRef: Boolean read GetHasWeakRef;
    property Segmented: Boolean read GetSegmented write SetSegmented;
    property RangeCheck: Boolean read GetRangeCheck write SetRangeCheck;
    property Notification: Boolean read GetNotification write SetNotification;
    property OwnedObject: Boolean read GetOwnedObject write SetOwnedObject;
    property RemoveAction: TRemoveAction read GetRemoveAction write SetRemoveAction;
  case Integer of
    0: (
      v: Integer);
    1: (
      MetaFlags: Byte;
      RegionFlags: Byte;
      SeedValue: Word
      );
  end;

  TsgItemMeta = record
  var
    TypeInfo: Pointer;
    ItemSize: Cardinal;
    h: hMeta;
    OnFree: TFreeProc;
  public
    procedure Init<T>(OnFree: TFreeProc = nil);
  end;
  PsgItemMeta = ^TsgItemMeta;

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

{$Region 'TMemoryRegion: typed memory region'}

  PMemoryRegion = ^TMemoryRegion;
  TMemoryRegion = record
  type
    TAssignProc = procedure(Dest, Value: Pointer) of object;
    TSwapProc = procedure(A, B: Pointer) of object;
    PBytes = ^TBytes;
    PInterface = ^IInterface;
  private
    Heap: PMemSegment;
    BlockSize: Cardinal;
    FCapacity: Integer;
    FMeta: TsgItemMeta;
    // procedural types
    FFreeItem: TFreeItem;
    FAssignItem: TAssignProc;
    FSwapItems: TSwapProc;
    FCompareItems: TCompareProc;
    procedure GrowHeap(NewCount: Integer);
    function Grow(NewCount: Integer): Integer;
    function GetOccupiedCount(p: PMemSegment): Integer;
    procedure FreeHeap(var Heap: PMemSegment);
    procedure FreeItems(p: PMemSegment);
    function Valid: Boolean; inline;
    function GetMeta: PsgItemMeta; inline;
    procedure UDFree(p: Pointer);
  strict private
    // Dest := Value;
    procedure Assign1(Dest, Value: Pointer);
    procedure Assign2(Dest, Value: Pointer);
    procedure Assign4(Dest, Value: Pointer);
    procedure Assign8(Dest, Value: Pointer);
    procedure AssignItemValue(Dest, Value: Pointer);
    procedure AssignManaged(Dest, Value: Pointer);
    procedure AssignVariant(Dest, Value: Pointer);
    procedure AssignMRef(Dest, Value: Pointer);
    // Value.Free;
    procedure FreeManaged(p: Pointer);
    procedure FreeVariant(p: Pointer);
    procedure FreeMRef(p: Pointer);
  public
    // Segmented region provides immutable pointer addresses
    procedure Init(Segmented: Boolean; const Meta: TsgItemMeta; BlockSize: Cardinal);
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
    function GetItemPtr(Index: Cardinal): Pointer;
    // Add an element and return a pointer to it
    function AddItem(Item: Pointer): Pointer;
    // propeties
    property Meta: PsgItemMeta read GetMeta;
    property Capacity: Integer read FCapacity;
    property ItemSize: Cardinal read FMeta.ItemSize;
    // item methods
    property FreeItem: TFreeItem read FFreeItem;
    property AssignItem: TAssignProc read FAssignItem;
    property SwapItems: TSwapProc read FSwapItems;
    property CompareItems: TCompareProc read FCompareItems;
  end;

{$EndRegion}

{$Region 'TsgItem: structure for a collection item of some type'}

  TsgItem = record
  private
    Ptr: Pointer;
    Region: PMemoryRegion;
  public
    procedure Init<T>(const Region: TMemoryRegion; var Value: T);
    procedure Assign(const Value);
    procedure Free;
  end;
  PsgItem = ^TsgItem;

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
    Seed: Word = 19927;
  strict private
    FRegions: PMemoryRegion;
    FRealesed: TRegionItems;
    FBlockSize: Word;
    FSeed: Word;
    // Occupy region
    function FindOrCreateRegion(Segmented: Boolean;
      const Meta: TsgItemMeta): PMemoryRegion;
  public
    constructor Create(BlockSize: Word = 8 * 1024);
    destructor Destroy; override;
    // Create a continuous region (e.g. memory for arrays)
    function CreateUnbrokenRegion(const Meta: TsgItemMeta): PMemoryRegion;
    // Create a segmented region (for elements with a fixed address)
    function CreateRegion(const Meta: TsgItemMeta): PMemoryRegion;
    // Release the region
    procedure Release(r: PMemoryRegion);
    function Valid: Boolean; inline;
  end;

{$EndRegion}

{$Region 'Procedures and functions'}

// Return main memory pool
function HeapPool: THeapPool;
// Clear main memory pool
procedure ClearHeapPool;
// if not ok raise error
procedure Check(ok: Boolean; const Msg: string = '');
// raise fatal error
procedure FatalError(const Msg: string);

{$EndRegion}

var
  PointerMeta: TsgItemMeta;
  MemoryRegionMeta: TsgItemMeta;

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

{$Region 'hMeta'}

constructor hMeta.From(TypeKind: System.TTypeKind; ManagedType, HasWeakRef: Boolean);
var
  b: Integer;
begin
  b := Seed shl 9;
  if HasWeakRef then b := b or 1;
  b := b shl 1;
  if ManagedType then b := b or 1;
  b := b shl 6;
  b := b + Ord(TypeKind) and $1F;
  v := b;
end;

function hMeta.Valid: Boolean;
begin
  Result := SeedValue = Seed;
end;

function hMeta.GetTypeKind: System.TTypeKind;
begin
  Result := System.TTypeKind(MetaFlags and $1F);
end;

function hMeta.GetManagedType: Boolean;
begin
  Result := False;
  if v and $40 <> 0 then
    Result := True;
end;

function hMeta.GetHasWeakRef: Boolean;
begin
  Result := False;
  if v and $80 <> 0 then
    Result := True;
end;

function hMeta.GetSegmented: Boolean;
begin
  Result := False;
  if v and $8000 <> 0 then
    Result := True;
end;

procedure hMeta.SetSegmented(const Value: Boolean);
begin
  if Value then
    v := v or $8000
  else
    v := v and not $8000;
end;

function hMeta.GetRangeCheck: Boolean;
begin
  Result := False;
  if v and $100 <> 0 then
    Result := True;
end;

procedure hMeta.SetRangeCheck(const Value: Boolean);
begin
  if Value then
    v := v or $100
  else
    v := v and not $100;
end;

function hMeta.GetNotification: Boolean;
begin
  Result := False;
  if v and $200 <> 0 then
    Result := True;
end;

procedure hMeta.SetNotification(const Value: Boolean);
begin
  if Value then
    v := v or $200
  else
    v := v and not $200;
end;

function hMeta.GetOwnedObject: Boolean;
begin
  Result := False;
  if v and $400 <> 0 then
    Result := True;
end;

procedure hMeta.SetOwnedObject(const Value: Boolean);
begin
  if Value then
    v := v or $400
  else
    v := v and not $400;
end;

function hMeta.GetRemoveAction: TRemoveAction;
begin
  Result := TRemoveAction((v shr 11) and $3);
end;

procedure hMeta.SetRemoveAction(const Value: TRemoveAction);
begin
  v := v or ((Ord(Value) and $3) shl 11);
end;

{$EndRegion}

{$Region 'TsgItemMeta'}

procedure TsgItemMeta.Init<T>(OnFree: TFreeProc);
begin
  TypeInfo := System.TypeInfo(T);
  h := hMeta.From(System.GetTypeKind(T), System.IsManagedType(T), System.HasWeakRef(T));
  ItemSize := sizeof(T);
  Self.OnFree := OnFree;
end;

{$EndRegion}

{$Region 'TsgItem'}

procedure TsgItem.Init<T>(const Region: TMemoryRegion; var Value: T);
begin
  Self.Region := @Region;
  if System.TypeInfo(T) <> Region.FMeta.TypeInfo then
    raise ESglError.Create(ESglError.IncompatibleDataType);
  Ptr := @Value;
end;

procedure TsgItem.Assign(const Value);
begin
  Region.FAssignItem(Ptr, @Value);
end;

procedure TsgItem.Free;
begin
  Region.FFreeItem(Ptr);
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

procedure TMemoryRegion.Init(Segmented: Boolean; const Meta: TsgItemMeta;
  BlockSize: Cardinal);
begin
  FillChar(Self, sizeof(TMemoryRegion), 0);
  Self.FMeta := Meta;
  Self.FMeta.h.Segmented := Segmented;
  Self.BlockSize := BlockSize;
  Self.FCapacity := 0;
  Self.Heap := nil;
  if FMeta.h.ManagedType then
  begin
    if (FMeta.ItemSize = SizeOf(Pointer)) and not FMeta.h.HasWeakRef and
      not (FMeta.h.TypeKind in [tkRecord, tkMRecord]) then
    begin
      FAssignItem := Self.AssignMRef;
      if not Assigned(FMeta.OnFree) then
        FFreeItem := Self.FreeMRef;
    end
    else if FMeta.h.TypeKind = TTypeKind.tkVariant then
    begin
      FAssignItem := Self.AssignVariant;
      if not Assigned(FMeta.OnFree) then
        FFreeItem := Self.FreeVariant;
    end
    else
    begin
      FAssignItem := Self.AssignManaged;
      if not Assigned(FMeta.OnFree) then
        FFreeItem := Self.FreeManaged;
    end
  end
  else
  begin
    case FMeta.ItemSize of
      0: raise ESglError.Create('impossible');
      1: FAssignItem := Self.Assign1;
      2: FAssignItem := Self.Assign2;
      4: FAssignItem := Self.Assign4;
      8: FAssignItem := Self.Assign8;
      else FAssignItem := Self.AssignItemValue;
    end;
    if Assigned(FMeta.OnFree) then
      FFreeItem := UDFree;
  end;
end;

function TMemoryRegion.Valid: Boolean;
begin
  Result := FMeta.h.Valid;
end;

procedure TMemoryRegion.Clear;
begin
  // Clear the memory of all segments.
  // Return to the heap memory of all segments except the first.
  FreeHeap(Heap.Next);
  if Assigned(FFreeItem) then
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
    if Assigned(FFreeItem) then
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
  Ptr := p.GetHeapRef;
  N := GetOccupiedCount(p);
  while N > 0 do
  begin
    FFreeItem(Ptr);
    a := NativeUInt(Ptr);
    Ptr := Pointer(NativeUInt(Ptr) + FMeta.ItemSize);
    b := NativeUInt(Ptr);
    Check(a + FMeta.ItemSize = b);
    Dec(N);
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
  Size := (Capacity - Old) * Integer(FMeta.ItemSize);
  Alloc(Size);
end;

function TMemoryRegion.GetOccupiedCount(p: PMemSegment): Integer;
begin
  Result := (p.HeapSize - sizeof(TMemSegment) - p.FreeSize) div FMeta.ItemSize;
end;

procedure TMemoryRegion.GrowHeap(NewCount: Integer);
var
  BlockCount, Size, NewHeapSize: Cardinal;
  p: PMemSegment;
begin
  Size := Grow(NewCount) * Integer(FMeta.ItemSize);
  BlockCount := (Size + sizeof(TMemoryRegion)) div BlockSize + 1;
  NewHeapSize := BlockCount * BlockSize;
  if Heap = nil then
    // create a new segment
    NewSegment(Heap, NewHeapSize)
  else if not FMeta.h.Segmented then
    // increase the size of the memory segment
    IncreaseHeapSize(Heap, NewHeapSize)
  else
  begin
    // create a new segment and place it at the beginning of the list
    NewSegment(p, NewHeapSize);
    p.Next := Heap;
    Heap := p;
  end;
  FCapacity := (Heap.HeapSize - sizeof(TMemSegment)) div FMeta.ItemSize;
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
  Check(Valid and (Size mod FMeta.ItemSize = 0));
{$ENDIF}
  if (Heap = nil) or (Heap.FreeSize < Size) then
    GrowHeap(Size div FMeta.ItemSize + 1);
  Result := Heap.Occupy(Size);
  if Result = nil then
    OutOfMemoryError;
end;

function TMemoryRegion.GetItemPtr(Index: Cardinal): Pointer;
var
  ItemsPtr: Pointer;
begin
  ItemsPtr := Heap.GetHeapRef;
  Result := Pointer(NativeUInt(ItemsPtr) + NativeUInt(Index * FMeta.ItemSize));
end;

function TMemoryRegion.AddItem(Item: Pointer): Pointer;
begin
  Result := Alloc(ItemSize);
  FAssignItem(Result, Item);
end;

function TMemoryRegion.GetMeta: PsgItemMeta;
begin
  Result := @FMeta;
end;

procedure TMemoryRegion.Assign1(Dest, Value: Pointer);
begin
  PByte(Dest)^ := PByte(Value)^;
end;

procedure TMemoryRegion.Assign2(Dest, Value: Pointer);
begin
  PWord(Dest)^ := PWord(Value)^;
end;

procedure TMemoryRegion.Assign4(Dest, Value: Pointer);
begin
  PCardinal(Dest)^ := PCardinal(Value)^;
end;

procedure TMemoryRegion.Assign8(Dest, Value: Pointer);
begin
  PUInt64(Dest)^ := PUInt64(Value)^;
end;

procedure TMemoryRegion.AssignItemValue(Dest, Value: Pointer);
begin
  Move(Value^, Dest^, FMeta.ItemSize);
end;

procedure TMemoryRegion.AssignManaged(Dest, Value: Pointer);
begin
  System.CopyRecord(Dest, Value, FMeta.TypeInfo);
end;

procedure TMemoryRegion.AssignVariant(Dest, Value: Pointer);
begin
  PVariant(Dest)^ := PVariant(Value)^;
end;

procedure TMemoryRegion.AssignMRef(Dest, Value: Pointer);
begin
  case FMeta.h.TypeKind of
    TTypeKind.tkUString: PString(Dest)^ := PString(Value)^;
    TTypeKind.tkDynArray: PBytes(Dest)^ := PBytes(Value)^;
    TTypeKind.tkInterface: PInterface(Dest)^ := PInterface(Value)^;
{$IF Defined(AUTOREFCOUNT)}
    TTypeKind.tkClass: PObject(Dest)^ := PObject(Value)^;
{$ENDIF}
    TTypeKind.tkLString: PRawByteString(Dest)^ := PRawByteString(Value)^;
{$IF not Defined(NEXTGEN)}
    TTypeKind.tkWString: PWideString(Dest)^ := PWideString(Value)^;
{$ENDIF}
  end;
end;

procedure TMemoryRegion.UDFree(p: Pointer);
begin
  FMeta.OnFree(p);
end;

procedure TMemoryRegion.FreeManaged(p: Pointer);
begin
  FinalizeRecord(p, FMeta.TypeInfo);
  FillChar(p^, FMeta.ItemSize, 0);
end;

procedure TMemoryRegion.FreeMRef(p: Pointer);
begin
  case FMeta.h.TypeKind of
    TTypeKind.tkUString: PString(p)^ := '';
    TTypeKind.tkDynArray: PBytes(p)^ := nil;
    TTypeKind.tkInterface: PInterface(p)^ := nil;
{$IF Defined(AUTOREFCOUNT)}
    TTypeKind.tkClass: PObject(p)^ := nil;
{$ENDIF}
    TTypeKind.tkLString: PRawByteString(p)^ := '';
{$IF not Defined(NEXTGEN)}
    TTypeKind.tkWString: PWideString(p)^ := '';
{$ENDIF}
  end;
end;

procedure TMemoryRegion.FreeVariant(p: Pointer);
begin
  PVariant(p)^ := 0;
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

constructor THeapPool.Create(BlockSize: Word);
begin
  inherited Create;
  FSeed := Seed;
  FBlockSize := BlockSize;
  New(FRegions);
  FRegions.Init(True, MemoryRegionMeta, BlockSize);
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

function THeapPool.CreateUnbrokenRegion(const Meta: TsgItemMeta): PMemoryRegion;
begin
  Result := FindOrCreateRegion(False, Meta);
end;

function THeapPool.CreateRegion(const Meta: TsgItemMeta): PMemoryRegion;
begin
  Result := FindOrCreateRegion(True, Meta);
end;

function THeapPool.FindOrCreateRegion(Segmented: Boolean;
  const Meta: TsgItemMeta): PMemoryRegion;
var
  p: PRegionItem;
begin
  if not FRealesed.Empty then
    p := FRealesed.Remove
  else
    p := FRegions.Alloc(sizeof(TMemoryRegion));
  p.r.Init(Segmented, Meta, FBlockSize);
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

procedure InitMeta;
begin
  PointerMeta.Init<Pointer>;
  MemoryRegionMeta.Init<TMemoryRegion>(FreeRegion);
end;

initialization
  InitMeta;

finalization
  ClearHeapPool;

end.

