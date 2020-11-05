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
  TAssignProc = procedure(Dest, Value: Pointer) of object;
  TFreeProc = procedure(p: Pointer);
  TEqualsFunc = function(a, b: Pointer): Boolean;
  THashProc = function(const Value): Cardinal;

{$EndRegion}

{$Region 'EsgError'}

  EsgError = class(Exception)
  const
    NotImplemented = 0;
    ListIndexError = 1;
    ListCountError = 2;
    CapacityError = 3;
    IncompatibleDataType = 4;
    ErrorMax = 4;
  private type
    TErrorMessages = array [0..ErrorMax] of string;
  private const
    ErrorMessages: TErrorMessages = (
      'Not implemented',
      'List index error (%d)',
      'List count error (%d)',
      'List capacity error (%d)',
      'Incompatible data type');
  public
    constructor Create(ErrNo: Integer); overload;
    constructor Create(ErrNo, IntParam: Integer); overload;
  end;

{$EndRegion}

{$Region 'TsgMemoryManager'}

  PsgFreeBlock = ^TsgFreeBlock;
  TsgFreeBlock = record
    Next: PsgFreeBlock;
    Size: Cardinal;
  end;

  TsgMemoryManager = record
  const
    MinSize = sizeof(Pointer) * 2;
  var
    Avail, Rover: PsgFreeBlock;
    Heap: Pointer;
    TopMemory: Pointer;
  public
    procedure Init(Heap: Pointer; HeapSize: Cardinal);
    // Allocate memory and return a pointer
    function Alloc(Size: Cardinal): Pointer;
    // Return memory to heap
    procedure FreeMem(Ptr: Pointer; Size: Cardinal);
    // Return memory to the heap with parameter validation
    procedure Dealloc(Ptr: Pointer; Size: Cardinal);
    // Reallocate memory
    function Realloc(Ptr: Pointer; OldSize, Size: Cardinal): Pointer;
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

  TRegionFlag = (
    rfSegmented,
    rfRangeCheck,
    rfNotification,
    rfOwnedObject);
  TRegionFlagSet = set of TRegionFlag;

  TsgItemMeta = record
  type
    PBytes = ^TBytes;
    PInterface = ^IInterface;
  var
    TypeInfo: Pointer;
    ItemSize: Cardinal;
    h: hMeta;
    OnFree: TFreeProc;
    FreeItem: TFreeItem;
    AssignItem: TAssignProc;
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
    procedure InitMethods;
    procedure UDFree(p: Pointer);
  public
    procedure Init<T>(OnFree: TFreeProc = nil); overload;
    procedure Init<T>(Flags: TRegionFlagSet; RemoveAction: TRemoveAction;
      OnFree: TFreeProc = nil); overload;
    procedure InitTuple(ItemSize: Cardinal; Flags: TRegionFlagSet);
  end;
  PsgItemMeta = ^TsgItemMeta;

{$EndRegion}

{$Region 'TMemSegment: allocated memory segment'}

  PMemSegment = ^TMemSegment;
  TMemSegment = record
  private
    Next: PMemSegment;  // Next segment
    HeapSize: Cardinal; // Size of the memory segment
    FreePtr: Pointer;   // Free memory
    FreeSize: Cardinal; // Size of free memory
  public
    function GetHeapRef: Pointer; inline;
     // Whether the address is within the heap
    function GetHignRef: Pointer; inline;
     // Allocate a piece of memory of the specified size
    procedure CheckPointer(Ptr: Pointer; Size: Cardinal);
     // Return a reference to the beginning of the heap
    function Occupy(Size: Cardinal): Pointer;
  end;

{$EndRegion}

{$Region 'TMemoryRegion: typed memory region'}

  PMemoryRegion = ^TMemoryRegion;
  TMemoryRegion = record
  type
    TSwapProc = procedure(A, B: Pointer) of object;
  private
    Heap: PMemSegment;
    BlockSize: Cardinal;
    FCapacity: Integer;
    FMeta: TsgItemMeta;
    // procedural types
    FSwapItems: TSwapProc;
    FCompareItems: TCompareProc;
    procedure GrowHeap(NewCount: Integer);
    function Grow(NewCount: Integer): Integer;
    function GetOccupiedCount(p: PMemSegment): Integer;
    procedure FreeHeap(var Heap: PMemSegment);
    procedure FreeItems(p: PMemSegment);
    function Valid: Boolean; inline;
    function GetMeta: PsgItemMeta; inline;
  public
    // Segmented region provides immutable pointer addresses
    procedure Init(const Meta: TsgItemMeta; BlockSize: Cardinal);
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
    // Dispose count items
    procedure Dispose(Items: Pointer; Count: Cardinal);
    // Get a pointer to an element of an array of the specified type
    function GetItemPtr(Index: Cardinal): Pointer;
    // Get index for pointer to an element
    function GetItemIndex(Item: Pointer): Integer;
    // Increment pointer to an element
    function NextItem(Item: Pointer): Pointer;
    // Add an element and return a pointer to it
    function AddItem(Item: Pointer): Pointer;
    // propeties
    property Meta: PsgItemMeta read GetMeta;
    property Capacity: Integer read FCapacity;
    property ItemSize: Cardinal read FMeta.ItemSize;
    // item methods
    property FreeItem: TFreeItem read FMeta.FreeItem;
    property AssignItem: TAssignProc read FMeta.AssignItem;
    property SwapItems: TSwapProc read FSwapItems;
    property CompareItems: TCompareProc read FCompareItems;
  end;

{$EndRegion}


{$Region 'TsgHandle: Handle uniquely identify some other part of data'}

  TsgHandle = record
    v: Cardinal;
    constructor From(index, counter, typ: Cardinal);
    // 12 bits
    function Index: Cardinal; inline;
    // 15 bits
    function Counter: Cardinal; inline;
    // 5 bits
    function Typ: Cardinal; inline;
  end;

{$EndRegion}

{$Region 'HandleEntry: a pointer to the data and a other bookkeeping fields'}

  TsgHandleEntry = record
    nextFreeIndex: Cardinal;
    counter: Cardinal;
    active: Boolean;
    endOfList: Boolean;
    entry: Pointer;
  end;

{$EndRegion}

{$Region 'TSharedRegion: Shared typed memory region'}

  PSharedRegion = ^TSharedRegion;
  TSharedRegion = record
  private
    FRegion: TMemoryRegion;
    FMemoryManager: TsgMemoryManager;
    function GetMeta: PsgItemMeta; inline;
  public
    // Initialize shared memory region for collections
    procedure Init(const Meta: TsgItemMeta; Capacity: Cardinal);
    // Free the region
    procedure Free;
    // Allocate memory for collection items
    function Alloc(Count: Cardinal): Pointer;
    // Return memory to heap
    procedure FreeMem(Ptr: Pointer; Count: Cardinal);
    // Reallocate memory for collection items
    function Realloc(Ptr: Pointer; OldCount, Count: Cardinal): Pointer;
    property ItemSize: Cardinal read FRegion.FMeta.ItemSize;
    property Meta: PsgItemMeta read GetMeta;
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
    function FindOrCreateRegion(const Meta: TsgItemMeta): PMemoryRegion;
  public
    constructor Create(BlockSize: Word = 8 * 1024);
    destructor Destroy; override;
    // Create a continuous region (e.g. memory for arrays)
    function CreateUnbrokenRegion(Meta: TsgItemMeta): PMemoryRegion;
    // Create a segmented region (for elements with a fixed address)
    function CreateRegion(Meta: TsgItemMeta): PMemoryRegion;
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
  // meta for region of Pointer
  PointerMeta: TsgItemMeta;
  // meta for region of TMemoryRegion
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
    raise EsgError.Create('Check error')
  else
    raise EsgError.Create(Msg);
end;

procedure FatalError(const Msg: string);
begin
  raise EsgError.Create(Msg);
end;

{$EndRegion}

{$Region 'EsgError'}

constructor EsgError.Create(ErrNo: Integer);
var
  Msg: string;
begin
  if InRange(ErrNo, 0, ErrorMax) then
    Msg := ErrorMessages[ErrNo]
  else
    Msg := 'Error: ' + IntToStr(ErrNo);
  Create(Msg);
end;

constructor EsgError.Create(ErrNo, IntParam: Integer);
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

procedure TsgItemMeta.InitTuple(ItemSize: Cardinal; Flags: TRegionFlagSet);
begin
  FillChar(Self, sizeof(TsgItemMeta), 0);
  if rfSegmented in Flags then
    h.SetSegmented(True);
  if rfRangeCheck in Flags then
    h.SetRangeCheck(True);
  if rfNotification in Flags then
    h.SetNotification(True);
  if rfOwnedObject in Flags then
    h.SetOwnedObject(True);
  Self.ItemSize := ItemSize;
end;

procedure TsgItemMeta.Init<T>(OnFree: TFreeProc);
begin
  TypeInfo := System.TypeInfo(T);
  h := hMeta.From(System.GetTypeKind(T), System.IsManagedType(T), System.HasWeakRef(T));
  ItemSize := sizeof(T);
  Self.OnFree := OnFree;
  InitMethods;
end;

procedure TsgItemMeta.Init<T>(Flags: TRegionFlagSet; RemoveAction: TRemoveAction;
  OnFree: TFreeProc);
begin
  TypeInfo := System.TypeInfo(T);
  h := hMeta.From(System.GetTypeKind(T), System.IsManagedType(T), System.HasWeakRef(T));
  ItemSize := sizeof(T);
  Self.OnFree := OnFree;
  if rfSegmented in Flags then
    h.SetSegmented(True);
  if rfRangeCheck in Flags then
    h.SetRangeCheck(True);
  if rfNotification in Flags then
    h.SetNotification(True);
  if rfOwnedObject in Flags then
    h.SetOwnedObject(True);
  h.RemoveAction := RemoveAction;
  InitMethods;
end;

procedure TsgItemMeta.InitMethods;
begin
  if h.ManagedType then
  begin
    if (ItemSize = SizeOf(Pointer)) and not h.HasWeakRef and not (h.TypeKind in [tkRecord, tkMRecord]) then
    begin
      Self.AssignItem := AssignMRef;
      if Assigned(OnFree) then
        Self.FreeItem := UDFree
      else
        Self.FreeItem := FreeMRef;
    end
    else if h.TypeKind = TTypeKind.tkVariant then
    begin
      Self.AssignItem := AssignVariant;
      if Assigned(OnFree) then
        Self.FreeItem := UDFree
      else
        Self.FreeItem := FreeVariant;
    end
    else
    begin
      Self.AssignItem := AssignManaged;
      if Assigned(OnFree) then
        Self.FreeItem := UDFree
      else
        Self.FreeItem := FreeManaged;
    end;
  end
  else
  begin
    case ItemSize of
      0: raise EsgError.Create('impossible');
      1: Self.AssignItem := Assign1;
      2: Self.AssignItem := Assign2;
      4: Self.AssignItem := Assign4;
      8: Self.AssignItem := Assign8;
      else Self.AssignItem := AssignItemValue;
    end;
    if Assigned(OnFree) then
      Self.FreeItem := UDFree
    else
      Self.FreeItem := nil;
  end;
end;

procedure TsgItemMeta.Assign1(Dest, Value: Pointer);
begin
  PByte(Dest)^ := PByte(Value)^;
end;

procedure TsgItemMeta.Assign2(Dest, Value: Pointer);
begin
  PWord(Dest)^ := PWord(Value)^;
end;

procedure TsgItemMeta.Assign4(Dest, Value: Pointer);
begin
  PCardinal(Dest)^ := PCardinal(Value)^;
end;

procedure TsgItemMeta.Assign8(Dest, Value: Pointer);
begin
  PUInt64(Dest)^ := PUInt64(Value)^;
end;

procedure TsgItemMeta.AssignItemValue(Dest, Value: Pointer);
begin
  Move(Value^, Dest^, ItemSize);
end;

procedure TsgItemMeta.AssignManaged(Dest, Value: Pointer);
begin
  System.CopyRecord(Dest, Value, TypeInfo);
end;

procedure TsgItemMeta.AssignVariant(Dest, Value: Pointer);
begin
  PVariant(Dest)^ := PVariant(Value)^;
end;

procedure TsgItemMeta.AssignMRef(Dest, Value: Pointer);
begin
  case h.TypeKind of
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

procedure TsgItemMeta.UDFree(p: Pointer);
begin
  OnFree(p);
end;

procedure TsgItemMeta.FreeManaged(p: Pointer);
begin
  FinalizeRecord(p, TypeInfo);
end;

procedure TsgItemMeta.FreeMRef(p: Pointer);
begin
  case h.TypeKind of
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

procedure TsgItemMeta.FreeVariant(p: Pointer);
begin
  PVariant(p)^ := 0;
end;

{$EndRegion}

{$Region 'TsgItem'}

procedure TsgItem.Init<T>(const Region: TMemoryRegion; var Value: T);
begin
  Self.Region := @Region;
  if System.TypeInfo(T) <> Region.FMeta.TypeInfo then
    raise EsgError.Create(EsgError.IncompatibleDataType);
  Ptr := @Value;
end;

procedure TsgItem.Assign(const Value);
begin
  Region.AssignItem(Ptr, @Value);
end;

procedure TsgItem.Free;
begin
  Region.FreeItem(Ptr);
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

function TMemSegment.GetHignRef: Pointer;
begin
  Result := Pointer(NativeUInt(@Self) + sizeof(TMemSegment) + HeapSize);
end;

{$EndRegion}

{$Region 'TMemoryRegion'}

procedure TMemoryRegion.Init(const Meta: TsgItemMeta; BlockSize: Cardinal);
begin
  FillChar(Self, sizeof(TMemoryRegion), 0);
  Self.FMeta := Meta;
  Self.BlockSize := BlockSize;
  Self.FCapacity := 0;
  Self.Heap := nil;
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
  if Assigned(FreeItem) then
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
    if Assigned(FreeItem) then
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
    FreeItem(Ptr);
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

procedure TMemoryRegion.Dispose(Items: Pointer; Count: Cardinal);
begin
  // todo:
end;

function TMemoryRegion.GetItemPtr(Index: Cardinal): Pointer;
var
  p: NativeUInt;
begin
  p := NativeUInt(Heap.GetHeapRef);
  Result := Pointer(p + NativeUInt(Index * FMeta.ItemSize));
end;

function TMemoryRegion.GetItemIndex(Item: Pointer): Integer;
var
  p: NativeUInt;
begin
  p := NativeUInt(Heap.GetHeapRef);
  Heap.CheckPointer(Item, FMeta.ItemSize);
  Result := (NativeUInt(Item) - p) div FMeta.ItemSize;
end;

function TMemoryRegion.NextItem(Item: Pointer): Pointer;
var
  p: NativeUInt;
begin
  p := NativeUInt(Item) - NativeUInt(Heap.GetHeapRef);
  if p < Heap.HeapSize then
    Result := Pointer(NativeUInt(Item) + FMeta.ItemSize)
  else
    Result := nil;
end;

function TMemoryRegion.AddItem(Item: Pointer): Pointer;
begin
  Result := Alloc(ItemSize);
  AssignItem(Result, Item);
end;

function TMemoryRegion.GetMeta: PsgItemMeta;
begin
  Result := @FMeta;
end;

{$EndRegion}

{$Region 'TsgHandle}

constructor TsgHandle.From(index, counter, typ: Cardinal);
begin
  v := (typ shl 27) or (counter shl 12) or index;
end;

function TsgHandle.Index: Cardinal;
begin
  Result := v and $FFF;
end;

function TsgHandle.Counter: Cardinal;
begin
  Result := (v shr 12) and $7FFF;
end;

function TsgHandle.Typ: Cardinal;
begin
  Result := (v shr 27) and $1F;
end;

{$EndRegion}

{$Region 'TSharedRegion}

procedure TSharedRegion.Init(const Meta: TsgItemMeta; Capacity: Cardinal);
begin
  FRegion.Init(Meta, 4096);
  FRegion.GrowHeap(Capacity);
  FMemoryManager.Init(FRegion.Heap.GetHeapRef, Capacity * FRegion.ItemSize);
end;

procedure TSharedRegion.Free;
begin
  FRegion.Free;
end;

function TSharedRegion.Alloc(Count: Cardinal): Pointer;
begin
  Result := FMemoryManager.Alloc(Count * FRegion.ItemSize)
end;

procedure TSharedRegion.FreeMem(Ptr: Pointer; Count: Cardinal);
begin
  FMemoryManager.FreeMem(Ptr, Count * FRegion.ItemSize);
end;

function TSharedRegion.GetMeta: PsgItemMeta;
begin
  Result := FRegion.GetMeta;
end;

function TSharedRegion.Realloc(Ptr: Pointer; OldCount, Count: Cardinal): Pointer;
var
  ItemSize: Cardinal;
begin
  ItemSize := FRegion.ItemSize;
  Result := FMemoryManager.Realloc(Ptr, OldCount * ItemSize, Count * ItemSize);
  if Result = nil then
    EsgError.Create('TSharedRegion.Realloc: not enough memory');
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
  FRegions.Init(MemoryRegionMeta, BlockSize);
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

function THeapPool.CreateUnbrokenRegion(Meta: TsgItemMeta): PMemoryRegion;
begin
  Meta.h.SetSegmented(False);
  Result := FindOrCreateRegion(Meta);
end;

function THeapPool.CreateRegion(Meta: TsgItemMeta): PMemoryRegion;
begin
  Meta.h.SetSegmented(True);
  Result := FindOrCreateRegion(Meta);
end;

function THeapPool.FindOrCreateRegion(const Meta: TsgItemMeta): PMemoryRegion;
var
  p: PRegionItem;
begin
  if not FRealesed.Empty then
    p := FRealesed.Remove
  else
    p := FRegions.Alloc(sizeof(TMemoryRegion));
  p.r.Init(Meta, FBlockSize);
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

{$Region 'TsgMemoryManager'}

procedure TsgMemoryManager.Init(Heap: Pointer; HeapSize: Cardinal);
begin
  Avail := Heap;
  Avail^.Next := nil;
  HeapSize := (HeapSize + 3) and not 3;
  Avail^.Size := HeapSize;
  Self.Heap := Heap;
  TopMemory := Pointer(NativeUInt(Heap) + HeapSize);
end;

function TsgMemoryManager.Alloc(Size: Cardinal): Pointer;
var
  p, q: PsgFreeBlock;
begin
  // Align block size to 4 bytes.
  Size := (Size + 3) and not 3;
  if (Size = 0) or (Size mod MinSize <> 0) then
    raise EsgError.Create('Alloc: Invalid size');
  p := PsgFreeBlock(@Avail);
  repeat
    q := p^.Next;
    if q = nil then exit(nil);
    if Size = q.Size then
    begin
      p^.Next := q^.Next;
      exit(q);
    end;
    if Size < q.Size then
    begin
      p^.Next := PsgFreeBlock(PByte(p^.Next) + Size);
      p := p^.Next;
      p^.Next := q^.Next;
      p^.Size := q^.Size - Size;
      exit(q);
    end;
    p := q;
  until False;
end;

function TsgMemoryManager.Realloc(Ptr: Pointer;
  OldSize, Size: Cardinal): Pointer;
var
  delta: Cardinal;
  p, q, r, n: PsgFreeBlock;
begin
  OldSize := (OldSize + 3) and not 3;
  Size := (Size + 3) and not 3;
  if (OldSize >= Size) or (Size mod MinSize <> 0) then
    raise EsgError.Create('Alloc: Invalid size');
  n := nil;
  // look for a block with the address Ptr + OldSize in the free memory list
  r := PsgFreeBlock(NativeUInt(Ptr) + OldSize);
  p := PsgFreeBlock(@Avail);
  repeat
    q := p^.Next;
    if q = nil then
    begin
      // If we were unable to increase the transferred block of memory,
      // then we take a new block of memory
      if n <> nil then
      begin
        q := n.Next;
        if Size = q.Size then
          n^.Next := q^.Next
        else if Size < q.Size then
        begin
          n^.Next := PsgFreeBlock(PByte(n^.Next) + Size);
          n := n^.Next;
          n^.Next := q^.Next;
          n^.Size := q^.Size - Size;
        end;
        // and copy the values into it and delete the old block
        Move(Ptr^, q^, OldSize);
        FreeMem(Ptr, OldSize);
      end;
      Result := q;
      exit;
    end;
    if q = r then
    begin
      // is there the desired piece of memory
      delta := Size - OldSize;
      if delta = q.Size then
      begin
        Result := Ptr;
        p^.Next := q^.Next;
        break;
      end;
      if delta < q.Size then
      begin
        Result := Ptr;
        p^.Next := PsgFreeBlock(PByte(p^.Next) + delta);
        p := p^.Next;
        p^.Next := q^.Next;
        p^.Size := q^.Size - delta;
        break;
      end;
    end
    // If it is a suitable block, remember the pointer preceding it.
    else if (n = nil) and (Size <= q.Size) then
      n := p;
    p := q;
  until False;
  FillChar(r^, delta, 0);
end;

procedure TsgMemoryManager.FreeMem(Ptr: Pointer; Size: Cardinal);
var
  q, p, x: PsgFreeBlock;
begin
  p := Ptr;
  // Align block size to 4 bytes.
  p^.Size := (Size + 3) and not 3;
  q := PsgFreeBlock(@Avail);
  repeat
    x := q^.Next;
    if (x = nil) or (NativeUInt(p) <= NativeUInt(x)) then
    begin
      p^.Next := x;
      break;
    end;
    q := q^.Next;
  until False;
  q^.Next := p;
  // Combine two blocks into one.
  x := p^.Next;
  if p^.Size + NativeUInt(p) = NativeUInt(x) then
  begin
    p^.Next := x^.Next;
    Inc(p^.Size, x^.Size);
  end;
  p := q;
  // Combine two blocks into one.
  x := p^.Next;
  if p^.Size + NativeUInt(p) = NativeUInt(x) then
  begin
    p^.Next := x^.Next;
    Inc(p^.Size, x^.Size);
  end;
end;

procedure TsgMemoryManager.Dealloc(Ptr: Pointer; Size: Cardinal);
begin
  if (Ptr = nil) or
     (NativeUInt(Ptr) < NativeUInt(Heap)) or
     (NativeUInt(Ptr) > NativeUInt(TopMemory)) then
    raise EsgError.Create('Dealloc: Invalid Pointer');
  FreeMem(Ptr, Size);
end;

{$EndRegion}

procedure InitMeta;
begin
  PointerMeta.Init<Pointer>;
  MemoryRegionMeta.Init<TMemoryRegion>([rfSegmented], TRemoveAction.HoldValue, FreeRegion);
end;

initialization
  InitMeta;

finalization
  ClearHeapPool;

end.

