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
  THeapPool = class;
  TFreeProc = procedure(Item: Pointer);

{$EndRegion}

{$Region 'ESglError'}

  ESglError = class(Exception)
  const
    NotImplemented = 0;
  public
    constructor Create(ErrNo: Integer); overload;
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
  case ErrNo of
    NotImplemented:
      Msg := 'Not implemented';
  else
    Msg := 'Error: ' + IntToStr(ErrNo);
  end;
  Create(Msg);
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
