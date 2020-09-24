(*********************************************)
(* Standard Generic Library (SGL) for Pascal *)
(*********************************************)

unit Oz.SGL.Collections;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Oz.SGL.Heap;

{$EndRegion}

{$T+}

{$Region 'TsdList<T>: List of records using the memory pool'}

type

  PsdListHelper = ^TsdListHelper;
  TsdListHelper = record
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
    procedure Assign(const Source: TsdListHelper);
  end;

  TsdList<T> = record
  private type
    TItems = array [0..High(Word)] of T;
    PItems = ^TItems;
    PItem = ^T;
  private
    FOnFree: TFreeProc;
    FListHelper: TsdListHelper; // FListHelper must be before FItems
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
    procedure Assign(Source: TsdList<T>); inline;
    function GetPtr(Index: Integer): PItem; inline;
    function IsEmpty: Boolean; inline;
    property Count: Integer read FListHelper.FCount write SetCount;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
    property List: PItems read FItems;
  end;

{$EndRegion}

// Check the index entry into the range [0...Count - 1].
procedure CheckIndex(Index, Count: Integer);

implementation

procedure CheckIndex(Index, Count: Integer);
begin
  if Cardinal(Index) >= Cardinal(Count) then
    raise ESglError.CreateFmt('List index error (%d)', [Count]);
end;

{$Region 'TsdListHelper'}

procedure TsdListHelper.Init(SizeItem: Integer; OnFree: TFreeProc);
begin
  FRegion := HeapPool.CreateUnbrokenRegion(SizeItem, OnFree);
  FCount := 0;
  FSizeItem := SizeItem;
end;

procedure TsdListHelper.Free;
begin
  FRegion.Free;
  FCount := 0;
  FSizeItem := 0;
end;

procedure TsdListHelper.Clear;
var
  SizeItem: Integer;
  OnFree: TFreeProc;
begin
  // todo: Make a cleanup implementation without deleting and creating
  SizeItem := FSizeItem;
  Check(SizeItem > 0, 'TsdListHelper.Clear: uninitialized');
  FRegion.GetOnFree(OnFree);
  Free;
  Init(SizeItem, OnFree);
end;

function TsdListHelper.GetPtr(Index: Integer): Pointer;
begin
  CheckIndex(Index, FCount);
  Result := @PByte(GetFItems^)[(Index) * FSizeItem];
end;

function TsdListHelper.Add(const Value): Integer;
begin
  if FRegion.Capacity <= FCount then
    GetFItems^ := FRegion.IncreaseCapacity(FCount + 1);
  FRegion.Alloc(FSizeItem);
  Result := FCount;
  Inc(FCount);
  SetItem(Result, Value);
end;

procedure TsdListHelper.SetCount(NewCount: Integer);
begin
  if NewCount <> FCount then
  begin
    CheckCapacity(NewCount);
    FCount := NewCount;
  end;
end;

procedure TsdListHelper.CheckCapacity(NewCount: Integer);
begin
  if FRegion.Capacity <= NewCount then
    GetFItems^ := FRegion.IncreaseAndAlloc(NewCount);
end;

procedure TsdListHelper.Delete(Index: Integer);
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

procedure TsdListHelper.QuickSort(Compare: TListSortCompareFunc; L, R: Integer);
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

procedure TsdListHelper.Sort(Compare: TListSortCompare);
begin
  if FCount > 1 then
    QuickSort(Compare, 0, FCount - 1);
end;

procedure TsdListHelper.Exchange(Index1, Index2: Integer);
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

procedure TsdListHelper.Insert(Index: Integer; const Value);
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

function TsdListHelper.Remove(const Value): Integer;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do
    if Compare(PByte(GetFItems^)[i * FSizeItem], Byte(Value)) then
      exit(i);
  Result := -1;
end;

procedure TsdListHelper.Reverse;
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

procedure TsdListHelper.Assign(const Source: TsdListHelper);
var
  i: Integer;
  Items: PPointer;
begin
  FCount := 0;
  Items := Source.GetFItems;
  for i := 0 to Source.FCount - 1 do
    Add(PByte(Items^)[i * FSizeItem]);
end;

function TsdListHelper.GetFItems: PPointer;
begin
  Result := PPointer(PByte(@Self) + SizeOf(Self));
end;

procedure TsdListHelper.SetItem(Index: Integer; const Value);
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

function TsdListHelper.Compare(const Left, Right): Boolean;
begin
  Result := CompareMem(@Left, @Right, FSizeItem)
end;

{$EndRegion}

{$Region 'TsdList<T>'}

constructor TsdList<T>.From(OnFree: TFreeProc);
begin
  FOnFree := OnFree;
  FListHelper.Init(sizeof(T), OnFree);
end;

procedure TsdList<T>.Free;
begin
  FListHelper.Free;
end;

procedure TsdList<T>.Clear;
begin
  FListHelper.Clear;
end;

function TsdList<T>.Add(const Value: T): Integer;
begin
  Result := FListHelper.Add(Value);
end;

procedure TsdList<T>.Delete(Index: Integer);
begin
  FListHelper.Delete(Index);
end;

procedure TsdList<T>.Insert(Index: Integer; const Value: T);
begin
  FListHelper.Insert(Index, Value);
end;

function TsdList<T>.Remove(const Value: T): Integer;
begin
  Result := FListHelper.Remove(Value);
end;

procedure TsdList<T>.Exchange(Index1, Index2: Integer);
begin
  FListHelper.Exchange(Index1, Index2);
end;

procedure TsdList<T>.Reverse;
begin
  FListHelper.Reverse;
end;

procedure TsdList<T>.Sort(Compare: TListSortCompare);
begin
  FListHelper.Sort(Compare);
end;

procedure TsdList<T>.Assign(Source: TsdList<T>);
begin
  FListHelper.Assign(Source.FListHelper);
end;

function TsdList<T>.GetPtr(Index: Integer): PItem;
begin
  Result := FListHelper.GetPtr(Index);
end;

function TsdList<T>.GetItem(Index: Integer): T;
begin
  CheckIndex(Index, FListHelper.FCount);
  Result := FItems[Index];
end;

function TsdList<T>.IsEmpty: Boolean;
begin
  Result := FListHelper.FCount = 0;
end;

procedure TsdList<T>.SetCount(Value: Integer);
begin
  FListHelper.SetCount(Value);
end;

procedure TsdList<T>.SetItem(Index: Integer; const Value: T);
begin
  FListHelper.SetItem(Index, Value);
end;

{$EndRegion}

end.

