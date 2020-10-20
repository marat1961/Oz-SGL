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

unit Oz.SGL.Test;

interface

{$Region 'Uses'}

uses
  // Delphi
  System.SysUtils,
  System.UITypes,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  System.Diagnostics,
  TestFramework,

  // Oz.SGL
  Oz.SGL.Heap,
  Oz.SGL.Collections;

{$EndRegion}

{$T+}

const
  ItemsCount = 3000;
  LengthEps = 1e-6;

type

{$Region 'TTestRecord'}

  TId = record
    v: Integer;
  end;

  PEntry = ^TEntry;
  TEntry = record
    tag: Integer;
    h: TId;
  end;

  PTestRecord = ^TTestRecord;
  TTestRecord = record
    e: TEntry;
    v: Integer;
    s: string;
    procedure Init(v, id: Integer);
    function Equals(const r: TTestRecord): Boolean;
  end;

{$EndRegion}

{$Region 'TPerson'}

  PPerson = ^TPerson;
  TPerson = record
    id: Integer;
    name: string;
    class function GenName(d: Integer): string; static;
    constructor From(const name: string);
    procedure Clear;
  end;

{$EndRegion}

{$Region 'TVector'}

  PVector = ^TVector;
  TVector = record
    x, y, z: Double;
    constructor From(x, y, z: Double);
    function Plus(const v: TVector): TVector;
    function Minus(const v: TVector): TVector;
    function Equals(const v: TVector; tol: Double = LengthEps): Boolean;
    function MagSquared: Double;
    function Hash: NativeInt;
  end;

{$EndRegion}

{$Region 'TMyInterface'}

  IIntId = interface
    procedure SetId(const id: Integer);
    function GetId: Integer;
    property Id: Integer read GetId write SetId;
  end;

  TIntId = class(TInterfacedObject, IIntId)
  private
    FId: Integer;
  public
    destructor Destroy; override;
    procedure SetId(const id: Integer);
    function GetId: Integer;
    property Id: Integer read GetId write SetId;
  end;

{$EndRegion}

{$Region 'TsgItemTest'}

  TsgItemTest = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestByte;
    procedure TestChar;
    procedure TestWord;
    procedure Test4;
    procedure Test8;
    procedure TestOtherSize;
    procedure TestItem;
    procedure TestManaged;
    procedure TestVariant;
    procedure TestObject;
    procedure TestInterface;
    procedure TestWeakRef;
    procedure TestDynArray;
    procedure TestString;
    procedure TestWideString;
    procedure TestRawByteString;
  end;

{$EndRegion}

{$Region 'THeapPoolTest'}

  PListNode = ^TListNode;
  TListNode = record
    next: PListNode;
    n: Integer;
  end;

  THeapPoolTest = class(TTestCase)
  public
    HeapPool: THeapPool;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure _CreateRegion;
    procedure _CreateUnbrokenRegion;
  end;

{$EndRegion}

{$Region 'TestTsgList'}

  TestTsgList = class(TTestCase)
  public
    List: TsgList<TTestRecord>;
    ItemProc: TsgItemProc;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAdd;
    procedure TestAdd1;
    procedure TestDelete;
    procedure TestInsert;
    procedure TestRemove;
    procedure TestExchange;
    procedure TestSort;
    procedure TestReverse;
    procedure TestAssign;
  end;

{$EndRegion}

{$Region 'TsgRecordListTest'}

  TsgRecordListTest = class(TTestCase)
  public
    List: TsgRecordList<TTestRecord>;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure _Add0;
    procedure _Add;
    procedure _Delete;
    procedure _Exchange;
    procedure _Extract;
    procedure _IndexOf;
    procedure _Sort;
    procedure _Reverse;
  end;

{$EndRegion}

{$Region 'TsgLinkedListTest'}

  TsgLinkedListTest = class(TTestCase)
  public
    List: TsgLinkedList<TPerson>;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure DumpList;
  published
    procedure _Clear;
    procedure _Empty;
    procedure _Count;
    procedure _Front;
    procedure _Back;
    procedure _PushFront;
    procedure _PushBack;
    procedure _Insert;
    procedure _PopFront;
    procedure _PopBack;
    procedure _Reverse;
    procedure _Sort;
    procedure _Eol;
    procedure _Bol;
  end;

{$EndRegion}

{$Region 'TestTsgHashMap'}

  // Test methods for class TsgHashMap
  TestTsgHashMap = class(TTestCase)
  type
    THashMapPair = TPair<TVector, Integer>;
    TIter = TsgHashMapIterator<TVector, Integer>;
  strict private
    FMap: TsgHashMap<TVector, Integer>;
    FPairProc: TsgPairProc;
  public
    procedure SetUp; override;
    procedure TearDown; override;
    procedure GenPair(i: Integer; var pair: THashMapPair);
  published
    procedure TestInsert;
    procedure TestFind;
    procedure TestIterator;
  end;

{$EndRegion}

{$Region 'TestTsgMap'}

  TMapPair = TPair<TPerson, Integer>;
  PMapPair = ^TMapPair;

  // Test methods for class TsgMap
  TestTsgMap = class(TTestCase)
  strict private
    FMap: TsgMap<TPerson, Integer>;
    nn: Integer;
    procedure CheckNode(p: TsgMapIterator<TPerson, Integer>.PNode);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestFind;
    procedure TestIterator;
  end;

{$EndRegion}

{$Region 'TestTsgSet'}

  TestTsgSet = class(TTestCase)
  strict private
    FSet: TsgSet<TPerson>;
    snn: Integer;
    procedure CheckSetNode(p: TsgSetIterator<TPerson>.PNode);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestFind;
    procedure TestIterator;
  end;

{$EndRegion}

function PersonIdCompare(a, b: Pointer): Integer;
function PersonCompare(a, b: Pointer): Integer;

implementation

function PersonIdCompare(a, b: Pointer): Integer;
type
  TIter = TsgLinkedList<TPerson>.TIterator;
begin
  Result := TIter(a).Value.id - TIter(b).Value.id;
end;

function PersonCompare(a, b: Pointer): Integer;
begin
  Result := CompareText(PPerson(a).name, PPerson(b).name);
end;

{$Region 'TTestRecord'}

procedure TTestRecord.Init(v, id: Integer);
begin
  e.tag := 0;
  e.h.v := id;
  Self.v := v;
end;

function TTestRecord.Equals(const r: TTestRecord): Boolean;
begin
  Result := (e.tag = r.e.tag) and (e.h.v = r.e.h.v) and (v = r.v) and (s = r.s);
end;

function TestRecordCompare(Left, Right: Pointer): Integer;
type
  PTestRecord = ^TTestRecord;
begin
  Result := PTestRecord(Left).v - PTestRecord(Right).v;
end;

{$EndRegion}

{$Region 'TPerson'}

constructor TPerson.From(const name: string);
begin
  Self.id := 0;
  Self.name := name;
end;

procedure TPerson.Clear;
begin
  Self := Default(TPerson);
end;

class function TPerson.GenName(d: Integer): string;
var
  n, c: Integer;
  ch: Char;
begin
  n := 5;
  Result := '';
  repeat
    c := d mod 10;
    d := d div 10;
    ch := Char(c + Ord('0'));
    Result := ch + Result;
    if n > 0 then Dec(n);
  until d = 0;
  while n > 0 do
  begin
    Result := '0' + Result;
    Dec(n);
  end;
  Result := 'P' + Result;
end;

{$EndRegion}

{$Region 'TsgItemTest'}

procedure TsgItemTest.SetUp;
begin
  inherited;
end;

procedure TsgItemTest.TearDown;
begin
  inherited;
end;

procedure TsgItemTest.TestByte;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: Byte;
begin
  a := 5;
  b := 43;
  meta.Init<Byte>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = 0);
end;

procedure TsgItemTest.TestChar;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: Char;
begin
  a := 'Q';
  b := 'F';
  meta.Init<Char>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = Chr(0));
end;

procedure TsgItemTest.TestWord;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: Word;
begin
  a := 5;
  b := 43;
  meta.Init<Word>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = 0);
end;

procedure TsgItemTest.Test4;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: Integer;
begin
  a := 5;
  b := 43;
  meta.Init<Integer>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = 0);
end;

procedure TsgItemTest.Test8;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: Int64;
begin
  a := 5;
  b := 43;
  meta.Init<Int64>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = 0);
end;

procedure TsgItemTest.TestOtherSize;
begin
  // for types 0, 3, 5, 6, 7
end;

procedure TsgItemTest.TestItem;
begin
  // record
end;

procedure TsgItemTest.TestManaged;
begin
  // record with managed fields
end;

procedure TsgItemTest.TestVariant;
begin
  // Variant
end;

procedure TsgItemTest.TestObject;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b, x: TIntId;
begin
  a := TIntId.Create;
  a.Id := 75;
  b := TIntId.Create;
  b.Id := 43;
  meta.Init<TIntId>;
  item.Init(meta);
  item.SetPtr(a);
  x := a;
  item.Assign(b);
  CheckTrue(a.Id = b.Id);
  item.Free;
  CheckTrue(a = nil);
  x.Free;
  b.Free;
end;

procedure TsgItemTest.TestInterface;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: IIntId;
begin
  a := TIntId.Create;
  a.Id := 75;
  b := TIntId.Create;
  b.Id := 43;
  meta.Init<IIntId>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a.Id = b.Id);
  item.Free;
  CheckTrue(a = nil);
end;

procedure TsgItemTest.TestWeakRef;
begin
  // WeakRef
end;

procedure TsgItemTest.TestDynArray;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: TArray<Integer>;
begin
  a := [5, 75, 588];
  b := [43];
  meta.Init<TArray<Integer>>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(Length(a) = 1);
  CheckTrue(a[0] = 43);
  item.Free;
  CheckTrue(a = nil);
end;

procedure TsgItemTest.TestString;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: string;
begin
  a := 'string a';
  b := 'string b';
  meta.Init<string>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = '');
end;

procedure TsgItemTest.TestWideString;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: WideString;
begin
  a := 'string a';
  b := 'string b';
  meta.Init<WideString>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = '');
end;

procedure TsgItemTest.TestRawByteString;
var
  meta: TsgItemMeta;
  item: TsgItem;
  a, b: RawByteString;
begin
  a := 'string a';
  b := 'string b';
  meta.Init<RawByteString>;
  item.Init(meta);
  item.SetPtr(a);
  item.Assign(b);
  CheckTrue(a = b);
  item.Free;
  CheckTrue(a = '');
end;

{$EndRegion}

{$Region 'THeapPoolTest'}

procedure THeapPoolTest.SetUp;
begin
  inherited;
  HeapPool := THeapPool.Create;
end;

procedure THeapPoolTest.TearDown;
begin
  inherited;
  HeapPool.Free;
  HeapPool := nil;
end;

procedure THeapPoolTest._CreateRegion;
var
  i: Integer;
  r: PMemoryRegion;
  head, newNode: PListNode;
begin
  r := HeapPool.CreateRegion(sizeof(TListNode));
  try
    head := nil;
    for i := 1 to ItemsCount do
    begin
      newNode := r.Alloc(sizeof(TListNode));
      newNode.next := head;
      newNode.n := i;
      head := newNode;
    end;
  finally
    r.Free;
  end;
end;

procedure THeapPoolTest._CreateUnbrokenRegion;
var
  i, j: Integer;
  r: PMemoryRegion;
  p, q, b: PListNode;
  a: TArray<NativeUInt>;
  pa, qa, a0, a1: NativeUInt;
begin
  r := HeapPool.CreateUnbrokenRegion(sizeof(TListNode));
  try
    q := nil;
    for i := 0 to ItemsCount - 1 do
    begin
      p := r.Alloc(sizeof(TListNode));
      p.next := p;
      p.n := i + 1;
      if q <> nil then
      begin
        pa := NativeUInt(p);
        qa := NativeUInt(q);
        if qa + sizeof(TListNode) <> pa then
        begin
          // was there moving data to a new block?
          CheckTrue(p.n = i + 1);
          CheckTrue(p.next = p);
        end;

        // read the value from the heap as from an array
        SetLength(a, i + 1);
        // copy data
        for j := 0 to i do
        begin
          b := PListNode(r.GetItemPtr<TListNode>(j));
          a[j] := NativeUInt(b);
          CheckTrue(b.n = j + 1);
        end;

        // check for continuity of addresses
        for j := 1 to i do
        begin
          a0 := a[j - 1];
          a1 := a[j];
          CheckTrue(a0 + sizeof(TListNode) = a1);
        end;
      end;
      q := p;
    end;
  finally
    r.Free;
  end;
end;

{$EndRegion}

{$Region 'TestTsgList'}

procedure TestTsgList.SetUp;
begin
  ItemProc.Init<TTestRecord>;
  List := TsgList<TTestRecord>.From(ItemProc);
end;

procedure TestTsgList.TearDown;
begin
  List.Clear;
end;

procedure TestTsgList.TestAdd;
var
  i, j: Integer;
  a, b: TTestRecord;
  p: PTestRecord;
begin
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i + 1);
    a.e.tag := i;
    List.Add(a);
    CheckTrue(List.Count = i);
    // ������� � ��������� ����������
    b := List.Items[i - 1];
    CheckTrue(b.v = i);
    CheckTrue(a.Equals(b));
    // ��������� ��� ����� ����������� ��������
    for j := 1 to i do
    begin
      a.Init(j, j + 1);
      a.e.tag := j;
      b := List.Items[j - 1];
      CheckTrue(b.v = j);
      CheckTrue(a.Equals(b));
    end;
  end;
  i := 0;
  for p in List do
  begin
    Inc(i);
    CheckTrue(p.e.tag = i);
  end;
  CheckTrue(i = ItemsCount);
end;

procedure TestTsgList.TestAdd1;
var
  v, r: TTestRecord;
begin
  CheckTrue(List.Count = 0);
  v.Init(457, 0);
  List.Add(v);
  r := List.Items[0];
  CheckTrue(r.Equals(v));
end;

procedure TestTsgList.TestDelete;
var
  i: Integer;
  v, r: TTestRecord;
begin
  for i := 0 to 99 do
  begin
    v.Init(i, i);
    List.Add(v);
  end;
  CheckTrue(List.Count = 100);
  r := List.Items[5];
  CheckTrue(r.v = 5);
  List.Delete(5);
  CheckTrue(List.Count = 99);
  r := List.Items[5];
  CheckTrue(r.v = 6);
end;

procedure TestTsgList.TestInsert;
var
  i: Integer;
  v, r: TTestRecord;
begin
  for i := 0 to 99 do
  begin
    v.Init(i, i);
    List.Add(v);
  end;
  CheckTrue(List.Count = 100);
  r := List.Items[5];
  CheckTrue(r.v = 5);
  v.Init(225, 225);
  List.Insert(5, v);
  r := List.Items[5];
  CheckTrue(r.v = 225);
  r := List.Items[6];
  CheckTrue(r.v = 5);
end;

procedure TestTsgList.TestRemove;
begin

end;

procedure TestTsgList.TestExchange;
var
  a, b, c, d, r: TTestRecord;
  j: Integer;
  i: Integer;
begin
  a.Init(1, 1);
  b.Init(23, 2);
  c.Init(45, 3);
  d.Init(-45, 4);
  List.Add(a);
  List.Add(b);
  i := 1;
  List.Add(c);
  List.Add(d);
  j := 3;
  List.Add(a);
  List.Add(a);
  r := List.Items[i];
  CheckTrue(r.Equals(b));
  r := List.Items[j];
  CheckTrue(r.Equals(d));
  List.Exchange(i, j);
  r := List.Items[i];
  CheckTrue(r.Equals(d));
  r := List.Items[j];
  CheckTrue(r.Equals(b));
end;

procedure TestTsgList.TestSort;
var
  i: Integer;
  a: TTestRecord;
begin
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i);
    List.Add(a);
  end;
  CheckTrue(List.Count = ItemsCount);
  List.Reverse;
  for i := 0 to ItemsCount - 1 do
  begin
    a := List.Items[i];
    if a.v <> ItemsCount - i then
      CheckTrue(a.v = ItemsCount - i);
  end;
  List.Sort(TestRecordCompare);
  for i := 0 to ItemsCount - 1 do
  begin
    a := List.Items[i];
    CheckTrue(a.v = i + 1);
  end;
end;

procedure TestTsgList.TestReverse;
var
  i: Integer;
  a: TTestRecord;
begin
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i);
    List.Add(a);
  end;
  List.Reverse;
  for i := 0 to ItemsCount - 1 do
  begin
    a := List.Items[i];
    if a.v <> ItemsCount - i then
      CheckTrue(a.v = ItemsCount - i);
  end;
end;

procedure TestTsgList.TestAssign;
var
  Source: TsgList<TTestRecord>;
  v, r: TTestRecord;
  p: PTestRecord;
begin
  v.Init(25, 1);
  v.s := '123';
  ItemProc.FAssignProc(@r, @v);
  CheckTrue(r.Equals(v));
  Source := TsgList<TTestRecord>.From(ItemProc);
  try
    Source.Add(v);
    p := Source.GetPtr(0);
    List.Assign(Source);
    CheckTrue(List.Count = 1);
    r := List.Items[0];
    CheckTrue(r.Equals(v));
  finally
    Source.Clear;
  end;
end;

{$EndRegion}

{$Region 'TsgRecordListTest'}

procedure TsgRecordListTest.SetUp;
begin
  List := TsgRecordList<TTestRecord>.From(nil);
end;

procedure TsgRecordListTest.TearDown;
begin
  List.Clear;
  ClearHeapPool;
end;

procedure TsgRecordListTest._Add0;
var
  i: Integer;
  a, b: PTestRecord;
begin
  for i := 1 to ItemsCount do
  begin
    a := List.Add;
    a.Init(i, i);
    a.e.tag := i;
    a.e.h.v := i + 1;
    CheckTrue(List.Count = i);
    // read and check content
    b := List.Items[i - 1];
    CheckTrue(b.v = i);
    CheckTrue(a.Equals(b^));
  end;
  CheckTrue(List.Count = ItemsCount);
  i := 0;
  for a in List do
  begin
    Inc(i);
    CheckTrue(a.e.tag = i);
    CheckTrue(a.e.h.v = i + 1);
  end;
  CheckTrue(i = ItemsCount);
end;

procedure TsgRecordListTest._Add;
var
  i, j: Integer;
  a, b: TTestRecord;
  p: PTestRecord;
begin
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i);
    a.e.tag := i;
    a.e.h.v := i + 1;
    List.Add(@a);
    CheckTrue(List.Count = i);
    // read and check content
    b := List.Items[i - 1]^;
    CheckTrue(b.v = i);
    CheckTrue(a.Equals(b));
    // check all previously added values
    for j := 1 to i do
    begin
      a.Init(j, i);
      a.e.tag := j;
      a.e.h.v := j + 1;
      p := List.Items[j - 1];
      CheckTrue(p <> nil);
      b := p^;
      CheckTrue(b.v = j);
      CheckTrue(a.Equals(b));
    end;
  end;
end;

procedure TsgRecordListTest._Delete;
var
  i: Integer;
  r: TTestRecord;
begin
  _Add0;
  CheckTrue(List.Count = ItemsCount);
  i := 99;
  r := List.Items[i]^;
  CheckTrue(r.v = 100);
  List.Delete(i);
  r := List.Items[i]^;
  CheckTrue(r.v = 101);
  CheckTrue(List.Count = ItemsCount - 1);
end;

procedure TsgRecordListTest._Exchange;
var
  a, b, c, d, r: TTestRecord;
  j: Integer;
  i: Integer;
begin
  a.Init(1, 1);
  b.Init(23, 2);
  c.Init(45, 3);
  d.Init(-45, 4);
  List.Add(@a);
  List.Add(@b);
  i := 1;
  List.Add(@c);
  List.Add(@d);
  j := 3;
  List.Add(@a);
  List.Add(@a);
  r := List.Items[i]^;
  CheckTrue(r.Equals(b));
  r := List.Items[j]^;
  CheckTrue(r.Equals(d));
  List.Exchange(i, j);
  r := List.Items[i]^;
  CheckTrue(r.Equals(d));
  r := List.Items[j]^;
  CheckTrue(r.Equals(b));
end;

procedure TsgRecordListTest._Extract;
var
  p, r: PTestRecord;
begin
  _Add0;
  CheckTrue(List.Count = ItemsCount);
  p := List.Items[20];
  r := List.Extract(p);
  CheckTrue(List.Count = ItemsCount - 1);
  CheckTrue(r = p);
end;

procedure TsgRecordListTest._IndexOf;
var
  i: Integer;
  p: PTestRecord;
begin
  _Add0;
  CheckTrue(List.Count = ItemsCount);
  p := List.Items[20];
  i := List.IndexOf(p);
  CheckTrue(i = 20);
end;

procedure TsgRecordListTest._Reverse;
var
  i: Integer;
  p: PTestRecord;
begin
  _Add0;
  CheckTrue(List.Count = ItemsCount);
  List.Reverse;
  for i := 0 to ItemsCount - 1 do
  begin
    p := List.Items[i];
    CheckTrue(p.v = ItemsCount - i);
  end;
end;

function Compare(Item1, Item2: Pointer): Integer;
begin
  Result := PTestRecord(Item1).v - PTestRecord(Item2).v;
end;

procedure TsgRecordListTest._Sort;
var
  i: Integer;
  p: PTestRecord;
begin
  _Add0;
  CheckTrue(List.Count = ItemsCount);
  List.Reverse;
  List.Sort(Compare);
  for i := 0 to ItemsCount - 1 do
  begin
    p := List.Items[i];
    CheckTrue(p.v = i + 1);
  end;
end;

{$EndRegion}

{$Region 'TsgLinkedListTest'}

procedure FreePerson(ptr: Pointer);
var
  it: TsgLinkedList<TPerson>.TIterator;
begin
  it := TsgLinkedList<TPerson>.TIterator(ptr);
  it.Value^ := Default(TPerson);
end;

procedure TsgLinkedListTest.SetUp;
begin
  List.Init(FreePerson);
  log.Init;
end;

procedure TsgLinkedListTest.TearDown;
begin
  List.Free;
  log.Free;
end;

procedure TsgLinkedListTest.DumpList;
var
  it: TsgLinkedList<TPerson>.TIterator;
begin
  it := List.Front;
  while not it.Eol do
  begin
    log.print('Person id=', [it.Value.id, ', "', it.Value.name, '"']);
    it.Next;
  end;
end;

procedure TsgLinkedListTest._Clear;
var
  p: TPerson;
  i: Integer;
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'p1';
  List.PushBack(p);
  CheckTrue(List.Count = 1);
  p.id := 2;
  p.name := 'p2';
  List.PushBack(p);
  CheckTrue(List.Count = 2);
  p.id := 3;
  p.name := 'p3';
  List.PushBack(p);
  CheckTrue(List.Count = 3);
  List.Clear;
  CheckTrue(List.Count = 0);
  for i := 1 to ItemsCount do
  begin
    p.id := i;
    p.name := 'p' + IntToStr(i);
    if Odd(i) then
      List.PushBack(p)
    else
      List.PushFront(p);
    CheckTrue(List.Count = i);
  end;
end;

procedure TsgLinkedListTest._Empty;
var
  p: TPerson;
begin
  CheckTrue(List.Empty);
  p.id := 1;
  p.name := 'Smith';
  List.PushFront(p);
  CheckFalse(List.Empty);
end;

procedure TsgLinkedListTest._Count;
var
  p: TPerson;
  i: Integer;
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  CheckTrue(List.Count = 1);
  for i := 1 to 5 do
    List.PushBack(p);
  CheckTrue(List.Count = 6);
end;

procedure TsgLinkedListTest._Front;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol and it.Bol);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  it := List.Front;
  CheckTrue(not it.Eol and not it.Bol);
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  CheckTrue(not it.Eol and not it.Bol);
end;

procedure TsgLinkedListTest._Back;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Back;
  CheckTrue(it.Eol and it.Bol);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  it := List.Back;
  CheckTrue(not it.Eol and not it.Bol);
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushBack(p);
  it := List.Back;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  CheckTrue(not it.Eol and not it.Bol);
end;

procedure TsgLinkedListTest._PushFront;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol and it.Bol);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(not it.Eol and not it.Bol);
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
end;

procedure TsgLinkedListTest._PushBack;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol and it.Bol);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  it := List.Front;
  CheckTrue(not it.Eol and not it.Bol);
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushBack(p);
  it := List.Back;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushBack(p);
  it := List.Back;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
end;

procedure TsgLinkedListTest._Insert;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol and it.Bol);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.Insert(it, p);
  it := List.Back;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
end;

procedure TsgLinkedListTest._PopFront;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  List.PopFront;
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  List.PopFront;
  CheckTrue(List.Count = 2);
  it := List.Front;
  CheckTrue(it.Value.id = 2);
  CheckTrue(it.Value.name = 'Leo');
  List.PopFront;
  CheckTrue(List.Count = 1);
  it := List.Front;
  CheckTrue(it.Value.id = 1);
  CheckTrue(it.Value.name = 'Nick');
  List.PopFront;
  CheckTrue(List.Empty);
end;

procedure TsgLinkedListTest._PopBack;
var
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  List.PopBack;
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  List.PopBack;
  CheckTrue(List.Count = 2);
  it := List.Back;
  CheckTrue(it.Value.id = 2);
  CheckTrue(it.Value.name = 'Leo');
  List.PopBack;
  CheckTrue(List.Count = 1);
  it := List.Back;
  CheckTrue(it.Value.id = 3);
  CheckTrue(it.Value.name = 'Neo');
  List.PopBack;
  CheckTrue(List.Empty);
end;

procedure TsgLinkedListTest._Reverse;
const
  N = 400;
var
  i: Integer;
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
  pp: PPerson;
  s: string;
begin
  CheckTrue(List.Count = 0);
  for i := 0 to N do
  begin
    p.id := i;
    p.name := IntToStr(i);
    List.PushBack(p);
  end;

  i := 0;
  for pp in List do
  begin
    CheckTrue(pp.id = i);
    s := IntToStr(i);
    CheckTrue(pp.name = s);
    Inc(i);
  end;
  CheckTrue(i = N + 1);

  it := List.Front;
  for i := 0 to N do
  begin
    CheckTrue(it.Value.id = i);
    CheckTrue(it.Value.name = IntToStr(i));
    it.Next;
  end;
  List.Reverse;
  it := List.Front;
  for i := 0 to N do
  begin
    CheckTrue(it.Value.id = N - i);
    CheckTrue(it.Value.name = IntToStr(N - i));
    it.Next;
  end;
  it := List.Back;
  for i := 0 to N do
  begin
    CheckTrue(it.Value.id = i);
    CheckTrue(it.Value.name = IntToStr(i));
    it.Prev;
  end;
end;

procedure TsgLinkedListTest._Sort;
const
  N = 500;
var
  i, d: Integer;
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  for i := 0 to N do
  begin
    d := Random(100000);
    p.id := d;
    p.name := 'S' + IntToStr(d);
    List.PushFront(p);
  end;
  DumpList;
  log.SaveToFile('sort1.txt');
  List.Sort(PersonIdCompare);
  it := List.Front;
  for i := 0 to N do
  begin
    if i = 0 then
     d := it.Value.id
    else
    begin
      CheckTrue(it.Value.id >= d);
      d := it.Value.id;
    end;
    it.Next;
  end;
  DumpList;
  log.SaveToFile('sort2.txt');
end;

procedure TsgLinkedListTest._Eol;
var
  i: Integer;
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol);
  for i := 0 to 9 do
  begin
    p.id := i;
    p.name := IntToStr(i);
    List.PushBack(p);
  end;
  it := List.Front;
  i := 0;
  while not it.Eol do
  begin
    CheckTrue(it.Value.id = i);
    CheckTrue(it.Value.name = IntToStr(i));
    it.Next;
    Inc(i);
  end;
  CheckTrue(i = 10);
end;

procedure TsgLinkedListTest._Bol;
var
  i: Integer;
  it: TsgLinkedList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol);
  for i := 0 to 9 do
  begin
    p.id := i;
    p.name := IntToStr(i);
    List.PushFront(p);
  end;
  it := List.Back;
  i := 0;
  while not it.Bol do
  begin
    CheckTrue(it.Value.id = i);
    CheckTrue(it.Value.name = IntToStr(i));
    it.Prev;
    Inc(i);
  end;
  CheckTrue(i = 10);
end;

{$EndRegion}

{$Region 'TestTsgHashMap'}

function VectorHash(v: Pointer): Cardinal;
begin
  Result := PVector(v).Hash;
end;

function VectorEquals(a, b: Pointer): Boolean;
begin
  Result := PVector(a).Equals(PVector(b)^);
end;

procedure TestTsgHashMap.SetUp;
begin
  FPairProc.Init<TVector, Integer>(VectorHash, VectorEquals, nil);
  FMap := TsgHashMap<TVector, Integer>.From(300, FPairProc);
end;

procedure TestTsgHashMap.TearDown;
begin
  FMap.Free;
end;

procedure TestTsgHashMap.GenPair(i: Integer; var pair: THashMapPair);
begin
  case i mod 5 of
    0: pair.Key := TVector.From(i, i + 1, i * 2);
    1: pair.Key := TVector.From(-i, i - 1, i);
    2: pair.Key := TVector.From(i + 20, i, -i);
    3: pair.Key := TVector.From(-i - 20, -i, i);
    4: pair.Key := TVector.From(i, i, i);
  end;
  pair.Value := i;
end;

procedure TestTsgHashMap.TestInsert;
var
  i: Integer;
  pair, r: THashMapPair;
  it: TsgHashMapIterator<TVector, Integer>;
begin
  for i := 0 to 10000 do
  begin
    // ���������
    GenPair(i, pair);
    FMap.Insert(pair);
    // ����
    it := FMap.Find(pair.Key);
    CheckTrue(it <> FMap.Ends);
    r.Key := it.GetKey^;
    r.Value := it.GetValue^;
    CheckTrue(r.Key.Equals(pair.Key));
    CheckTrue(r.Value = i);
  end;
end;

procedure TestTsgHashMap.TestFind;
var
  i, j: Integer;
  it: TsgHashMapIterator<TVector, Integer>;
  pos: TVector;
begin
  TestInsert;
  i := 500;
  pos := TVector.From(i, i + 1, i * 2);
  it := FMap.Find(pos);
  CheckTrue(it <> FMap.Ends);
  j := it.GetValue^;
  CheckTrue(i = j);
end;

procedure TestTsgHashMap.TestIterator;
var
  i: Integer;
  pair, r: THashMapPair;
  it: TIter;
begin
  TestInsert;
  it := FMap.Begins;
  i := 0;
  while it <> FMap.Ends do
  begin
    r.Key := it.GetKey^;
    r.Value := it.GetValue^;
    GenPair(i, pair);
    CheckTrue(SameValue(pair.Key.X, r.Key.X));
    CheckTrue(SameValue(pair.Key.Y, r.Key.Y));
    CheckTrue(SameValue(pair.Key.Z, r.Key.Z));
    CheckTrue(pair.Value = r.Value);
    it.Next;
    Inc(i);
  end;
end;

{$EndRegion}

{$Region 'TestTsgMap'}

procedure ClearNode(P: Pointer);
var
  Ptr: TsgMapIterator<TPerson, Integer>.PNode;
begin
  Ptr := TsgMapIterator<TPerson, Integer>.PNode(P);
  Ptr.k.Clear;
end;

procedure TestTsgMap.SetUp;
begin
  FMap := TsgMap<TPerson, Integer>.From(PersonCompare, ClearNode);
end;

procedure TestTsgMap.TearDown;
begin
  FMap.Free;
end;

procedure TestTsgMap.TestFind;
var
  i: Integer;
  it: TsgMapIterator<TPerson, Integer>;
  v: TsgMap<TPerson, Integer>.PItem;
  pair, r: TMapPair;
  person: TPerson;
begin
  for i := 1 to 50 do
  begin
    person.name := TPerson.GenName(i);
    pair.Key := person;
    pair.Value := i;
    FMap.Insert(pair);
    if i = 1 then
    begin
      v := FMap.Get(person);
      Check(v^ = 1);
      it := FMap.Find(person);
      CheckTrue(it <> FMap.Ends);
      r.Key := it.GetKey^;
      r.Value := it.GetValue^;
      CheckTrue(r.Key.name = person.name);
      CheckTrue(r.Value = 1);
    end;
  end;
  person.name := TPerson.GenName(20);
  it := FMap.Find(person);
  CheckTrue(it <> FMap.Ends);
  r.Key := it.GetKey^;
  r.Value := it.GetValue^;
  CheckTrue(r.Key.name = person.name);
  CheckTrue(r.Value = 20);
  it := FMap.Find(TPerson.From('lflghjf'));
  CheckTrue(it = FMap.Ends);
end;

procedure TestTsgMap.CheckNode(p: TsgMapIterator<TPerson, Integer>.PNode);
var
  r: TMapPair;
begin
  r := p.pair;
  Check(r.Value = nn);
  Inc(nn)
end;

procedure TestTsgMap.TestIterator;
var
  i: Integer;
  it: TsgMapIterator<TPerson, Integer>;
  pair, r: TMapPair;
  id: string;
begin
  for i := 1 to 50 do
  begin
    id := TPerson.GenName(i);
    pair.Key := TPerson.From(id);
    pair.Value := i;
    FMap.Insert(pair);
    nn := 1;
    FMap.Inorder(CheckNode);
  end;
  it := FMap.Begins;
  r.Key := it.GetKey^;
  r.Value := it.GetValue^;
  for i := 1 to 50 do
  begin
    it.Next;
    r.Key := it.GetKey^;
    r.Value := it.GetValue^;
    id := TPerson.GenName(i);
    CheckTrue(r.Key.name = id);
    CheckTrue(r.Value = i);
  end;
end;

{$EndRegion}

{$Region 'TestTsgSet'}

procedure ClearSetNode(P: Pointer);
var
  Ptr: TsgSetIterator<TPerson>.PNode;
begin
  Ptr := TsgSetIterator<TPerson>.PNode(P);
  Ptr.k.Clear;
end;

procedure TestTsgSet.SetUp;
begin
  FSet.Init(PersonCompare, ClearSetNode);
end;

procedure TestTsgSet.TearDown;
begin
  FSet.Free;
end;

procedure TestTsgSet.TestFind;
var
  i: Integer;
  it: TsgSetIterator<TPerson>;
  k, r: TPerson;
  id: string;
begin
  for i := 1 to 50 do
  begin
    k.name := TPerson.GenName(i);
    FSet.Insert(k);
  end;
  id := TPerson.GenName(20);
  it := FSet.Find(TPerson.From(id));
  CheckTrue(it <> FSet.Ends);
  r := it.GetKey^;
  CheckTrue(r.name = id);
  it := FSet.Find(TPerson.From('bviut'));
  CheckTrue(it = FSet.Ends);
end;

procedure TestTsgSet.CheckSetNode(p: TsgSetIterator<TPerson>.PNode);
var
  r: TPerson;
  id: string;
begin
  r := p.k;
  id := TPerson.GenName(snn);
  Check(r.name = id);
  Inc(snn)
end;

procedure TestTsgSet.TestIterator;
var
  i: Integer;
  it: TsgSetIterator<TPerson>;
  k, r: TPerson;
  id: string;
begin
  for i := 1 to 50 do
  begin
    id := TPerson.GenName(i);
    k := TPerson.From(id);
    FSet.Insert(k);
    snn := 1;
    FSet.Inorder(CheckSetNode);
  end;
  it := FSet.Begins;
  r := it.GetKey^;

  for i := 1 to 50 do
  begin
    it.Next;
    r := it.GetKey^;
    id := TPerson.GenName(i);
    CheckTrue(r.name = id);
  end;
end;

{$EndRegion}

{$Region 'TVector'}

constructor TVector.From(x, y, z: Double);
begin
  Self.x := x;
  Self.y := y;
  Self.z := z;
end;

function TVector.Plus(const v: TVector): TVector;
begin
  Result.x := x + v.x;
  Result.y := y + v.y;
  Result.z := z + v.z;
end;

function TVector.MagSquared: Double;
begin
  Result := x * x + y * y + z * z;
end;

function TVector.Minus(const v: TVector): TVector;
begin
  Result.x := x - v.x;
  Result.y := y - v.y;
  Result.z := z - v.z;
end;

function TVector.Equals(const v: TVector; tol: Double): Boolean;
var
  dv: TVector;
begin
  dv := Self.Minus(v);
  if Abs(dv.x) > tol then exit(False);
  if Abs(dv.y) > tol then exit(False);
  if Abs(dv.z) > tol then exit(False);
  Result := dv.MagSquared < Sqr(tol);
end;

function TVector.Hash: NativeInt;
const
  Eps = LengthEps * 4;
var
  Size, xs, ys, zs: NativeInt;
begin
  Size := Trunc(Power(High(NativeInt), 1.0 / 3.0)) - 1;
  x := Abs(x) / Eps;
  y := Abs(y) / Eps;
  z := Abs(z) / Eps;
  xs := Trunc(FMod(x, Size));
  ys := Trunc(FMod(y, Size));
  zs := Trunc(FMod(z, Size));
  Result := (zs * Size + ys) * Size + xs;
end;

{$EndRegion}

{$Region 'TIntId'}

procedure TIntId.SetId(const id: Integer);
begin
  FId := id;
end;

destructor TIntId.Destroy;
begin
  FId := Maxint;
  inherited;
end;

function TIntId.GetId: Integer;
begin
  Result := FId;
end;

{$EndRegion}

initialization
  // Oz.SGL.Heap
  RegisterTest(THeapPoolTest.Suite);
  RegisterTest(TsgItemTest.Suite);

  // Oz.SGL.Collections
  RegisterTest(TestTsgList.Suite);
  RegisterTest(TsgRecordListTest.Suite);
  RegisterTest(TsgLinkedListTest.Suite);
  RegisterTest(TestTsgMap.Suite);
  RegisterTest(TestTsgSet.Suite);

end.
