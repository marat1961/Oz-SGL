(*********************************************)
(* Standard Generic Library (SGL) for Pascal *)
(*********************************************)

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
  private
    Pool: THeapPool;
    Heap: PMemSegment;
    IsSegmented: Boolean;
    Used: Boolean;
    ItemSize: Cardinal;
    BlockSize: Cardinal;
    FCapacity: Integer;
    OnFree: TFreeProc;
    procedure GrowHeap(NewCount: Integer);
    function Grow(NewCount: Integer): Integer;
    function GetOccupiedCount(S: PMemSegment): Integer;
    procedure FreeHeap;
    function Valid: Boolean;
  public
    // Segmented region provides immutable pointer addresses
    procedure Init(Pool: THeapPool; IsSegmented: Boolean;
      ItemSize, BlockSize: Cardinal; OnFree: TFreeProc);
    // Free the region
    procedure Free;
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
    // Get free procedure
    procedure GetOnFree(var proc: TFreeProc);
    property Capacity: Integer read FCapacity;
  end;

{$EndRegion}

{$Region 'TsdItemFactory: Factory of list items using the memory pool'}

  TsdPointersArrayRange = 0..$7FFFFFFF div (sizeof(Pointer) * 2) - 1;
  TsdPointers = array [TsdPointersArrayRange] of Pointer;
  PsdPointers = ^TsdPointers;

  PsdItemFactory = ^TsdItemFactory;
  TsdItemFactory = record
  var
    // region for pointers
    ListRegion: PMemoryRegion;
    // region for items
    ItemsRegion: PMemoryRegion;
    // item size
    ItemSize: Integer;
  public
    constructor From(ItemSize: Integer; OnFree: TFreeProc);
    procedure Free;
    // Change the list capacity and return the heap address to store list pointers
    procedure CheckCapacity(var List: PsdPointers; NewCount: Integer);
    // Add an element and return its pointer
    function AddItem(Item: Pointer): Pointer;
    // Create an empty item and return its pointer
    function CreateItem: Pointer;
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
  strict private
    FRegions: PMemoryRegion;
    FRealesed: TRegionItems;
    FBlockSize: Cardinal;
    // Occupy region
    function FindOrCreateRegion(IsSegmented: Boolean; ItemSize: Cardinal;
      OnFree: TFreeProc): PMemoryRegion;
  private
    // Release the region
    procedure Release(r: PMemoryRegion);
  public
    constructor Create(BlockSize: Cardinal = 8 * 1024);
    destructor Destroy; override;
    // Create a continuous region (e.g. memory for arrays)
    function CreateUnbrokenRegion(ItemSize: Cardinal;
      OnFree: TFreeProc = nil): PMemoryRegion;
    // Create a segmented region (for elements with a fixed address)
    function CreateRegion(ItemSize: Cardinal;
      OnFree: TFreeProc = nil): PMemoryRegion;
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

procedure TMemoryRegion.Init(Pool: THeapPool; IsSegmented: Boolean;
  ItemSize, BlockSize: Cardinal; OnFree: TFreeProc);
begin
  Self.Pool := Pool;
  Self.IsSegmented := IsSegmented;
  Self.Used := True;
  Self.BlockSize := BlockSize;
  Self.ItemSize := ItemSize;
  Self.FCapacity := 0;
  Self.Heap := nil;
  Self.OnFree := OnFree;
end;

function TMemoryRegion.Valid: Boolean;
begin
  Result := Pool = nil;
end;

procedure TMemoryRegion.Free;
begin
  if Pool = nil then
    FreeHeap
  else
    Pool.Release(@Self);
end;

procedure TMemoryRegion.FreeHeap;
var
  p, q: PMemSegment;
  N: Integer;
  Ptr: Pointer;
  a, b: NativeUInt;
begin
  p := Heap;
  while p <> nil do
  begin
    q := p.Next;
    if Assigned(OnFree) then
    begin
      Ptr := p.GetHeapRef;
      N := GetOccupiedCount(p);
      while N > 0 do
      begin
        OnFree(Ptr);
        a := NativeUInt(Ptr);
        Ptr := Pointer(NativeUInt(Ptr) + ItemSize);
        b := NativeUInt(Ptr);
        Check(a + ItemSize = b);
        Dec(N);
      end;
    end;
    FreeMem(p);
    p := q;
  end;
  Heap := nil;
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
  Size := (Capacity - Old) * Integer(ItemSize);
  Alloc(Size);
end;

function TMemoryRegion.GetOccupiedCount(S: PMemSegment): Integer;
begin
  Result := (S.HeapSize - sizeof(TMemSegment) - S.FreeSize) div ItemSize;
end;

procedure TMemoryRegion.GetOnFree(var proc: TFreeProc);
begin
  proc := OnFree;
end;

procedure TMemoryRegion.GrowHeap(NewCount: Integer);
var
  BlockCount, Size, NewHeapSize: Cardinal;
  p: PMemSegment;
begin
  Size := Grow(NewCount) * Integer(ItemSize);
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
  FCapacity := (Heap.HeapSize - sizeof(TMemSegment)) div ItemSize;
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
  Check(Valid and (Size mod ItemSize = 0));
{$ENDIF}
  if (Heap = nil) or (Heap.FreeSize < Size) then
    GrowHeap(Size div ItemSize + 1);
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

{$Region 'TsdItemFactory'}

constructor TsdItemFactory.From(ItemSize: Integer; OnFree: TFreeProc);
begin
  Self.ListRegion := HeapPool.CreateUnbrokenRegion(sizeof(Pointer));
  Self.ItemSize := ItemSize;
  Self.ItemsRegion := HeapPool.CreateRegion(ItemSize, OnFree);
end;

procedure TsdItemFactory.Free;
begin
  ItemsRegion.Free;
  ListRegion.Free;
  ItemSize := 0;
end;

procedure TsdItemFactory.CheckCapacity(var List: PsdPointers; NewCount: Integer);
begin
  if ListRegion.Capacity <= NewCount then
    List := ListRegion.IncreaseAndAlloc(NewCount);
end;

function TsdItemFactory.AddItem(Item: Pointer): Pointer;
begin
  Result := ItemsRegion.Alloc(ItemSize);
  Move(Item^, Result^, ItemSize);
end;

function TsdItemFactory.CreateItem: Pointer;
begin
  Result := ItemsRegion.Alloc(ItemSize);
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
  Item.r.FreeHeap;
end;

constructor THeapPool.Create(BlockSize: Cardinal);
begin
  inherited Create;
  FBlockSize := BlockSize;
  New(FRegions);
  FRegions.Init(nil, True, sizeof(TMemoryRegion), BlockSize, FreeRegion);
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

function THeapPool.CreateUnbrokenRegion(ItemSize: Cardinal; OnFree: TFreeProc)
  : PMemoryRegion;
begin
  Result := FindOrCreateRegion(False, ItemSize, OnFree);
end;

function THeapPool.CreateRegion(ItemSize: Cardinal; OnFree: TFreeProc)
  : PMemoryRegion;
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
  p.r.Init(Self, IsSegmented, ItemSize, FBlockSize, OnFree);
  Result := @p.r;
end;

procedure THeapPool.Release(r: PMemoryRegion);
begin
  try
    r.FreeHeap;
  except
  end;
end;

{$EndRegion}

initialization

finalization

ClearHeapPool;

end.
