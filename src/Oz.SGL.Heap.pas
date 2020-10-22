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
  TCompareProc = function(const Value): Integer of object;
  TFreeItem = procedure(var Value) of object;
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
  TsgItemMeta = record
  var
    TypeInfo: Pointer;
    ItemSize: Cardinal;
    OnFree: TFreeProc;
    TypeKind: System.TTypeKind;
    ManagedType: Boolean;
    HasWeakRef: Boolean;
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
    TAssignProc = procedure(var Dest; const Value) of object;
    TSwapProc = procedure(var A, B) of object;
  private const
    Seed = 46147635;
  private
    FSeed: Integer;
    Heap: PMemSegment;
    IsSegmented: Boolean;
    Used: Boolean;
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
    function GetOccupiedCount(S: PMemSegment): Integer;
    procedure FreeHeap(var Heap: PMemSegment);
    procedure FreeItems(p: PMemSegment);
    function Valid: Boolean;
    function GetMeta: PsgItemMeta; inline;
  strict private
    // Dest := Value;
    procedure Assign1(var Dest; const Value);
    procedure Assign2(var Dest; const Value);
    procedure Assign4(var Dest; const Value);
    procedure Assign8(var Dest; const Value);
    procedure AssignItemValue(var Dest; const Value);
    procedure AssignManaged(var Dest; const Value);
    procedure AssignVariant(var Dest; const Value);
    procedure AssignMRef(var Dest; const Value);
    // Value.Free;
    procedure Free1(var Value);
    procedure Free2(var Value);
    procedure Free4(var Value);
    procedure Free8(var Value);
    procedure FreeItemValue(var Value);
    procedure FreeManaged(var Value);
    procedure FreeVariant(var Value);
    procedure FreeMRef(var Value);
  public
    // Segmented region provides immutable pointer addresses
    procedure Init(IsSegmented: Boolean; const Meta: TsgItemMeta; BlockSize: Cardinal);
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
    function GetItemSize: Cardinal;
  public
    constructor From(const Meta: TsgItemMeta);
    procedure Free;
    // Change the list capacity and return the heap address to store list pointers
    procedure CheckCapacity(var List: PsgPointers; NewCount: Integer);
    // Add an element and return its pointer
    function AddItem(Item: Pointer): Pointer;
    // Create an empty item and return its pointer
    function CreateItem: Pointer;
    property ItemSize: Cardinal read GetItemSize;
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
    function FindOrCreateRegion(IsSegmented: Boolean;
      const Meta: TsgItemMeta): PMemoryRegion;
  public
    constructor Create(BlockSize: Cardinal = 8 * 1024);
    destructor Destroy; override;
    // Create a continuous region (e.g. memory for arrays)
    function CreateUnbrokenRegion(const Meta: TsgItemMeta): PMemoryRegion;
    // Create a segmented region (for elements with a fixed address)
    function CreateRegion(const Meta: TsgItemMeta): PMemoryRegion;
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

{$Region 'TsgItemMeta'}

procedure TsgItemMeta.Init<T>(OnFree: TFreeProc);
begin
  TypeInfo := System.TypeInfo(T);
  TypeKind := System.GetTypeKind(T);
  ManagedType := System.IsManagedType(T);
  HasWeakRef := System.HasWeakRef(T);
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
  Region.FAssignItem(Ptr^, Value);
end;

procedure TsgItem.Free;
begin
  Region.FFreeItem(Ptr^);
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

procedure TMemoryRegion.Init(IsSegmented: Boolean; const Meta: TsgItemMeta;
  BlockSize: Cardinal);
begin
  FillChar(Self, sizeof(TMemoryRegion), 0);
  Self.FSeed := Seed;
  Self.IsSegmented := IsSegmented;
  Self.Used := True;
  Self.FMeta := Meta;
  Self.BlockSize := BlockSize;
  Self.FCapacity := 0;
  Self.Heap := nil;
  if FMeta.ManagedType then
  begin
    if (FMeta.ItemSize = SizeOf(Pointer)) and not FMeta.HasWeakRef and
      not (FMeta.TypeKind in [tkRecord, tkMRecord]) then
    begin
      FAssignItem := Self.AssignMRef;
      if not Assigned(FMeta.OnFree) then
        FFreeItem := Self.FreeMRef;
    end
    else if FMeta.TypeKind = TTypeKind.tkVariant then
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
    case FMeta.ItemSize of
      0:
        raise ESglError.Create('impossible');
      1:
        begin
          FAssignItem := Self.Assign1;
          if not Assigned(FMeta.OnFree) then
            FFreeItem := Self.Free1;
        end;
      2:
        begin
          FAssignItem := Self.Assign2;
          if not Assigned(FMeta.OnFree) then
            FFreeItem := Self.Free2;
        end;
      4:
        begin
          FAssignItem := Self.Assign4;
          if not Assigned(FMeta.OnFree) then
            FFreeItem := Self.Free4;
        end;
      8:
        begin
          FAssignItem := Self.Assign8;
          if not Assigned(FMeta.OnFree) then
            FFreeItem := Self.Free8;
        end;
      else
      begin
        FAssignItem := Self.AssignItemValue;
        if not Assigned(FMeta.OnFree) then
          FFreeItem := Self.FreeItemValue;
      end;
    end;
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
  if Assigned(FMeta.OnFree) then
  begin
    Ptr := p.GetHeapRef;
    N := GetOccupiedCount(p);
    while N > 0 do
    begin
      FMeta.OnFree(Ptr);
      a := NativeUInt(Ptr);
      Ptr := Pointer(NativeUInt(Ptr) + FMeta.ItemSize);
      b := NativeUInt(Ptr);
      Check(a + FMeta.ItemSize = b);
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
  Size := (Capacity - Old) * Integer(FMeta.ItemSize);
  Alloc(Size);
end;

function TMemoryRegion.GetOccupiedCount(S: PMemSegment): Integer;
begin
  Result := (S.HeapSize - sizeof(TMemSegment) - S.FreeSize) div FMeta.ItemSize;
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

function TMemoryRegion.GetItemPtr<T>(Index: Integer): Pointer;
var
  ItemsPtr: Pointer;
begin
  ItemsPtr := Heap.GetHeapRef;
  Result := Pointer(NativeUInt(ItemsPtr) + NativeUInt(index * sizeof(T)));
end;

function TMemoryRegion.GetMeta: PsgItemMeta;
begin
  Result := @FMeta;
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

procedure TMemoryRegion.Assign1(var Dest; const Value);
begin
  Byte(Dest) := Byte(Value)
end;

procedure TMemoryRegion.Assign2(var Dest; const Value);
begin
  Word(Dest) := Word(Value)
end;

procedure TMemoryRegion.Assign4(var Dest; const Value);
begin
  Cardinal(Dest) := Cardinal(Value);
end;

procedure TMemoryRegion.Assign8(var Dest; const Value);
begin
  UInt64(Dest) := UInt64(Value);
end;

procedure TMemoryRegion.AssignItemValue(var Dest; const Value);
begin
  Move(Value, Dest, FMeta.ItemSize);
end;

procedure TMemoryRegion.AssignManaged(var Dest; const Value);
begin
  System.CopyRecord(@Dest, @Value, FMeta.TypeInfo);
end;

procedure TMemoryRegion.AssignVariant(var Dest; const Value);
begin
  Variant(Dest) := Variant(Value)
end;

procedure TMemoryRegion.AssignMRef(var Dest; const Value);
type
  PBytes = ^TBytes;
  PInterface = ^IInterface;
begin
  case FMeta.TypeKind of
    TTypeKind.tkUString: string(Dest) := string(Value);
    TTypeKind.tkDynArray: TBytes(Dest) := TBytes(Value);
    TTypeKind.tkInterface: IInterface(Dest) := IInterface(Value);
{$IF Defined(AUTOREFCOUNT)}
    TTypeKind.tkClass: TObject(Dest) := TObject(Value);
{$ENDIF}
    TTypeKind.tkLString: RawByteString(Dest) := RawByteString(Value);
{$IF not Defined(NEXTGEN)}
    TTypeKind.tkWString: WideString(Dest) := WideString(Value);
{$ENDIF}
  end;
end;

procedure TMemoryRegion.Free1(var Value);
begin
  Byte(Value) := 0;
end;

procedure TMemoryRegion.Free2(var Value);
begin
  Word(Value) := 0;
end;

procedure TMemoryRegion.Free4(var Value);
begin
  Cardinal(Value) := 0;
end;

procedure TMemoryRegion.Free8(var Value);
begin
  UInt64(Value) := 0;
end;

procedure TMemoryRegion.FreeItemValue(var Value);
begin
  FillChar(Value, FMeta.ItemSize, 0);
end;

procedure TMemoryRegion.FreeManaged(var Value);
begin
  FinalizeArray(@Value, FMeta.TypeInfo, 1);
  FillChar(Value, FMeta.ItemSize, 0);
end;

procedure TMemoryRegion.FreeMRef(var Value);
begin
  FinalizeArray(@Value, FMeta.TypeInfo, 1);
  Pointer(Value) := nil;
end;

procedure TMemoryRegion.FreeVariant(var Value);
begin
  Variant(Value) := 0;
  FillChar(Value, sizeof(Variant), 0);
end;

{$EndRegion}

{$Region 'TsgItemFactory'}

constructor TsgItemFactory.From(const Meta: TsgItemMeta);
begin
  FListRegion := HeapPool.CreateUnbrokenRegion(PointerMeta);
  FItemsRegion := HeapPool.CreateRegion(Meta);
end;

function TsgItemFactory.GetItemSize: Cardinal;
begin
  Result := FItemsRegion.FMeta.ItemSize;
end;

procedure TsgItemFactory.Free;
begin
  FItemsRegion.Free;
  FListRegion.Free;
end;

procedure TsgItemFactory.CheckCapacity(var List: PsgPointers; NewCount: Integer);
begin
  if FListRegion.Capacity <= NewCount then
    List := FListRegion.IncreaseAndAlloc(NewCount);
end;

function TsgItemFactory.AddItem(Item: Pointer): Pointer;
var
  ItemSize: Cardinal;
begin
  ItemSize := FItemsRegion.FMeta.ItemSize;
  Result := ItemsRegion.Alloc(ItemSize);
  // todo:
  Move(Item^, Result^, ItemSize);
end;

function TsgItemFactory.CreateItem: Pointer;
begin
  Result := ItemsRegion.Alloc(FItemsRegion.FMeta.ItemSize);
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

function THeapPool.FindOrCreateRegion(IsSegmented: Boolean;
  const Meta: TsgItemMeta): PMemoryRegion;
var
  p: PRegionItem;
begin
  if not FRealesed.Empty then
    p := FRealesed.Remove
  else
    p := FRegions.Alloc(sizeof(TMemoryRegion));
  p.r.Init(IsSegmented, Meta, FBlockSize);
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
