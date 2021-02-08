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
  System.Generics.Defaults,
  System.Diagnostics,
  TestFramework,

  // Oz.SGL
  Oz.SGL.HandleManager,
  Oz.SGL.Heap,
  Oz.SGL.Hash,
  Oz.SGL.Collections;

{$EndRegion}

{$T+}

const
  ItemsCount = 3000;
  LengthEps = 1e-6;

type

{$Region 'TTestRecord'}

  t3 = record
    a, b, c: Byte;
  end;

  t7 = array [0..6] of Byte;

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

{$Region 'TsgHandleManagerTest'}

  TsgHandleManagerTest = class(TTestCase)
  private
    Visited, Count: Integer;
    procedure Visit(h: hCollection);
  public
    region: hRegion;
    m: TsgHandleManager;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestNode;
    procedure TestInvalidHandle;
    procedure TestCorrectPointer;
    procedure TestTwoPointers;
    procedure TestUpdateInvalidHandle;
    procedure TestUpdateExistingHandle;
    procedure TestPointerRemoved;
    procedure TestRemoveNonExist;
    procedure TestTooManyItemsAdded;
    procedure TestManyItemsAddedRemoveAdd;
    procedure TestSameSlotIsDifferent;
    procedure TestDeleteSameSlot;
    procedure TestDeleteDeletingSameSlot;
    procedure TestTraversal;
  end;

{$EndRegion}

{$Region 'TsgMemoryManagerTest'}

  TsgMemoryManagerTest = class(TTestCase)
  const
    N = 200;
  public
    mem: array [0 .. N - 1] of TsgFreeBlock;
    mm: TsgMemoryManager;
    TotalSize: Cardinal;
    StartHeap: PsgFreeBlock;
    p: PsgFreeBlock;
    p1, p2, p3, p4, p5, p6: Pointer;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAlloc;
    procedure TestDefragment;
    procedure TestFreeWithTop;
    procedure TestFreeWithBottom;
    procedure TestFreeWithBoth;
    procedure TestInvalidParameter;
    procedure TestRealloc;
    procedure TestRealloc2;
  end;

{$EndRegion}

{$Region 'TSysCtxTest'}

  TSysCtxTest = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateMeta;
    procedure TestCreateTeMeta;
  end;

{$EndRegion}

{$Region 'TUnbrokenRegionTest'}

  TUnbrokenRegionTest = class(TTestCase)
  type
    TUpdateProc = procedure(p: Pointer; value: Integer);
    TParam<T> = record
    var
      a, b, c: T;
      update: TUpdateProc;
      equals: TEqualsFunc;
      procedure Init(av, bv: T; u: TUpdateProc; eq: TEqualsFunc);
    end;
  public
    meta: PsgItemMeta;
    region: TUnbrokenRegion;
    item: TsgItem;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure Init<T>(var value: T);
    function Add<T>(const value: T): Integer;
    procedure Get<T>(idx: Integer; var value: T);
    procedure _CRUD<T>(var a, b: T; equals: TEqualsFunc);
    procedure _Clear<T>(var prm: TParam<T>);
    procedure _AssignItems<T>;
    procedure _FreeItems<T>;
    procedure _Checks<T>;
    procedure _Test<T>(var prm: TParam<T>);
  published
    procedure Test;
    procedure _Byte;
    procedure _Word;
    procedure _Integer;
    procedure _Int64;
    procedure _Size3;
    procedure _Size7;
    procedure _ManagedType;
    procedure _Variant;
    procedure _Object;
    procedure _Interface;
    procedure _DynArray;
    procedure _String;
    procedure _WideString;
    procedure _RawByteString;
  end;

{$EndRegion}

{$Region 'TSegmentedRegionTest'}

  TSegmentedRegionTest = class(TTestCase)
  public
    region: TSegmentedRegion;
    meta: PsgItemMeta;
    item: TsgItem;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure Init<T>(var value: T);
  published
  end;

{$EndRegion}

{$Region 'TsgItemTest'}

  TsgItemTest = class(TTestCase)
  public
    region: TMemoryRegion;
    meta: PsgItemMeta;
    item: TsgItem;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure InitItem<T>(var value: T);
  published
    procedure TestByte;
    procedure TestChar;
    procedure TestWord;
    procedure Test4;
    procedure Test8;
    procedure Test0;
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
    procedure _MemSegment;
    procedure _hMeta;
    procedure _CreateRegion;
    procedure _CreateUnbrokenRegion;
  end;

{$EndRegion}

{$Region 'TestTSharedRegion'}

  TestTSharedRegion = class(TTestCase)
  private
    Descr: TMemoryDescriptor;
    a, b, c, d, e: PTestRecord;
  public
    Meta: PsgItemMeta;
    Region: TSharedRegion;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAlloc;
    procedure TestFreeMem;
    procedure TestRealloc;
  end;

{$EndRegion}

{$Region 'TestTsgArray'}

  TestTsgArray = class(TTestCase)
  public
    Meta: PsgItemMeta;
    Region: TSharedRegion;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSetCount;
    procedure TestAdd;
    procedure TestDelete;
    procedure TestInsert;
    procedure TestRemove;
    procedure TestExchange;
    procedure TestSort;
    procedure TestReverse;
  end;

{$EndRegion}

{$Region 'TsgTupleMetaTest'}

  TsgTupleMetaTest = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure _TupleOffset;
    procedure _MakePair;
    procedure _MakeTrio;
    procedure _MakeQuad;
    procedure _Cat;
    procedure _Add;
    procedure _Insert;
  end;

{$EndRegion}

{$Region 'TsgTupleTest'}

  TsgTupleTest = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure _TupleOffset;
    procedure _Assign;
    procedure _AssignPart;
  end;

{$EndRegion}

{$Region 'TestTsgList'}

  TestTsgList = class(TTestCase)
  public
    List: TsgList<TTestRecord>;
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
    procedure _IndexOf;
    procedure _Sort;
    procedure _Reverse;
  end;

{$EndRegion}

{$Region 'TsgForwardListTest'}

  TsgForwardListTest = class(TTestCase)
  public
    List: TsgForwardList<TPerson>;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure DumpList;
  published
    procedure _Clear;
    procedure _Empty;
    procedure _Count;
    procedure _Front;
    procedure _PushFront;
    procedure _InsertAfter;
    procedure _PopFront;
    procedure _Reverse;
    procedure _Sort;
    procedure _Eol;
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

{$Region 'TsgHasherTest'}

  TsgHasherTest = class(TTestCase)
  strict private

  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestInt32;
    procedure TestString;
  end;

{$EndRegion}

{$Region 'TsgHashMapTest: Test methods for class TsgHashMap'}

type
  THashMapPair = TsgPair<TVector, Integer>;
  PHashMapPair = ^THashMapPair;
  TIter = TsgHashMapIterator<TVector, Integer>;

  TsgHashMapTest = class(TTestCase)
  strict private
    Map: TsgHashMap<TVector, Integer>;
    function Hash<TKey>(const Key: TKey): Integer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
    procedure GenPair(i: Integer; var pair: TsgPair<TVector, Integer>);
  published
    procedure TestTemporaryPair;
    procedure TestInsert;
    procedure TestInsertOrUpdate;
    procedure TestFind;
    procedure TestPairIterator;
    procedure TestKeyIterator;
    procedure TestValuesIterator;
  end;

{$EndRegion}

{$Region 'TsgMapTest'}

  // Test methods for class TsgMap
  TsgMapTest = class(TTestCase)
  type
    TMapPair = TsgPair<TPerson, Integer>;
    PMapPair = ^TMapPair;
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

{$Region 'TsgSetTest'}

  TsgSetTest = class(TTestCase)
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

function PersonIdCompare1(a, b: Pointer): Integer;
type
  PItem = TsgForwardList<TPerson>.PItem;
var
  pa, pb: PItem;
begin
  pa := PItem(a);
  pb := PItem(b);
  Result := pa.Value.id - pb.Value.id;
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

{$Region 'TsgHandleManagerTest'}

procedure TsgHandleManagerTest.SetUp;
begin
  inherited;
  region.v := 5;
  m.Init(region);
end;

procedure TsgHandleManagerTest.TearDown;
begin
  inherited;
end;

procedure TsgHandleManagerTest.TestNode;
var
  n: TsgHandleManager.TNode;
  i: Integer;
begin
  n.Init(7, 5);
  CheckTrue(n.next = 7);
  CheckTrue(n.prev = 5);
  CheckTrue(n.counter = 1);
  CheckTrue(n.active = False);
  n.active := True;
  CheckTrue(n.active = True);
  CheckTrue(n.next = 7);
  CheckTrue(n.prev = 5);
  CheckTrue(n.counter = 1);
  n.active := False;
  CheckTrue(n.active = False);
  for i := 0 to 127 do
  begin
    n.counter := i;
    CheckTrue(n.next = 7);
    CheckTrue(n.prev = 5);
    CheckTrue(n.counter = i);
    CheckTrue(n.active = False);
  end;
  n.counter := 127;
  for i := 0 to 4095 do
  begin
    n.next := i;
    CheckTrue(n.next = i);
    CheckTrue(n.prev = 5);
    CheckTrue(n.counter = 127);
    CheckTrue(n.active = False);
  end;
  for i := 0 to 4095 do
  begin
    n.prev := i;
    CheckTrue(n.next = 4095);
    CheckTrue(n.prev = i);
    CheckTrue(n.counter = 127);
    CheckTrue(n.active = False);
  end;
end;

procedure TsgHandleManagerTest.TestInvalidHandle;
var
  h: hCollection;
  p: Pointer;
begin
  CheckTrue(m.Count = 0);
  h := hCollection.From(123, 4, region);
  p := m.Get(h);
  CheckTrue(p = nil);
end;

procedure TsgHandleManagerTest.TestCorrectPointer;
var
  h: hCollection;
  p, r: Pointer;
begin
  p := @m;
  h := m.Add(p);
  r := m.Get(h);
  CheckTrue(p = r);
end;

procedure TsgHandleManagerTest.TestTwoPointers;
var
  h0, h1: hCollection;
  p0, p1, r: Pointer;
begin
  p0 := Pointer(456);
  p1 := Pointer(12783);
  h0 := m.Add(p0);
  h1 := m.Add(p1);
  r := m.Get(h0);
  CheckTrue(p0 = r);
  r := m.Get(h1);
  CheckTrue(p1 = r);
end;

procedure TsgHandleManagerTest.TestUpdateInvalidHandle;
var
  h, h1: hCollection;
  a, b: Pointer;
  ok: Boolean;
begin
  a := Pointer(3);
  h := m.Add(a);
  h1 := hCollection.From(h.index + 1, 0, region);
  ok := False;
  try
    b := Pointer(4);
    m.Update(h1, b);
  except
    ok := True;
  end;
  CheckTrue(ok);
end;

procedure TsgHandleManagerTest.TestUpdateExistingHandle;
var
  h: hCollection;
  a, b, r: Pointer;
begin
  a := Pointer(456);
  b := Pointer(12783);
  h := m.Add(a);
  m.Update(h, b);
  r := m.Get(h);
  CheckTrue(r <> nil);
  CheckTrue(r = b);
end;

procedure TsgHandleManagerTest.TestPointerRemoved;
var
  h0, h1: hCollection;
  p0, p1, r: Pointer;
begin
  p0 := Pointer(456);
  p1 := Pointer(12783);
  h0 := m.Add(p0);
  h1 := m.Add(p1);
  m.Remove(h0);
  r := m.Get(h0);
  CheckTrue(r = nil);
  r := m.Get(h1);
  CheckTrue(p1 = r);
end;

procedure TsgHandleManagerTest.TestRemoveNonExist;
var
  h, hne: hCollection;
  p: Pointer;
  ok: Boolean;
begin
  p := Pointer(456);
  h := m.Add(p);
  hne := hCollection.From(747, 6, region);
  ok := False;
  try
    m.Remove(hne);
  except
    ok := True;
  end;
  CheckTrue(ok);
end;

procedure TsgHandleManagerTest.TestTooManyItemsAdded;
var
  h: hCollection;
  p: Pointer;
  i: Integer;
  ok: Boolean;
begin
  p := Pointer(4526);
  for i := 0 to m.MaxNodes - 3 do
    h := m.Add(p);
  ok := False;
  try
    m.Add(p);
  except
    ok := True;
  end;
  CheckTrue(ok);
end;

procedure TsgHandleManagerTest.TestManyItemsAddedRemoveAdd;
var
  h: hCollection;
  p: Pointer;
  i: Integer;
begin
  p := Pointer(4526);
  for i := 0 to m.MaxNodes - 3 do
    h := m.Add(p);
  m.Remove(h);
  h := m.Add(p);
  CheckTrue(h.v <> 0);
end;

procedure TsgHandleManagerTest.TestSameSlotIsDifferent;
var
  h, nh: hCollection;
  p: Pointer;
  i: Integer;
begin
  p := Pointer(4526);
  for i := 0 to m.MaxNodes - 3 do
    h := m.Add(p);
  m.Remove(h);
  nh := m.Add(p);
  CheckTrue(h.Index = nh.Index);
  CheckTrue(h.counter <> nh.counter);
end;

procedure TsgHandleManagerTest.TestDeleteSameSlot;
var
  h: hCollection;
  p, r: Pointer;
  i: Integer;
begin
  p := Pointer(4526);
  h := m.Add(p);
  for i := 0 to m.MaxNodes - 4 do
    m.Add(p);
  m.Remove(h);
  m.Add(p);
  r := m.Get(h);
  CheckTrue(r = nil);
end;

procedure TsgHandleManagerTest.TestDeleteDeletingSameSlot;
var
  h: hCollection;
  p: Pointer;
  i: Integer;
  ok: Boolean;
begin
  p := Pointer(4526);
  h := m.Add(p);
  for i := 0 to m.MaxNodes - 4 do
    m.Add(p);
  m.Remove(h);
  m.Add(p);
  ok := False;
  try
    m.Remove(h);
  except
    ok := True;
  end;
  CheckTrue(ok);
end;

procedure TsgHandleManagerTest.Visit(h: hCollection);
var
  i: Integer;
  p: Pointer;
begin
  Inc(Self.Visited);
  p := m.Get(h);
  i := Integer(p);
  Inc(Self.Count, i);
end;

procedure TsgHandleManagerTest.TestTraversal;
var
  p: Pointer;
  i: Integer;
begin
  Self.Visited := 0;
  Self.Count := 0;
  i := 0;
  while m.Count < m.GuardNode - 1 do
  begin
    p := Pointer(m.Count);
    m.Add(p);
    Inc(i);
    CheckTrue(i = m.Count);
  end;
  m.Traversal(Visit);
end;

{$EndRegion}

{$Region 'TsgMemoryManagerTest'}

procedure TsgMemoryManagerTest.SetUp;
begin
  inherited;
  TotalSize := sizeof(TsgFreeBlock) * N;
  StartHeap := @mem[0];
  mm.Init(StartHeap, TotalSize);
end;

procedure TsgMemoryManagerTest.TearDown;
begin
  inherited;
end;

procedure TsgMemoryManagerTest.TestAlloc;
begin
  p1 := mm.Alloc(8);
  CheckTrue(p1 = StartHeap);
  CheckTrue(mm.Avail = PsgFreeBlock(PByte(StartHeap) + 8));
  CheckTrue(mm.Avail.Next = nil);
  CheckTrue(mm.Avail.Size = TotalSize - 8);

  p2 := mm.Alloc(32);
  CheckTrue(p2 = PsgFreeBlock(PByte(StartHeap) + 8));
  CheckTrue(mm.Avail = PsgFreeBlock(PByte(StartHeap) + 40));
  CheckTrue(mm.Avail.Next = nil);
  CheckTrue(mm.Avail.Size = TotalSize - 40);

  p3 := mm.Alloc(40);
  CheckTrue(p3 = PsgFreeBlock(PByte(StartHeap) + 40));
  CheckTrue(mm.Avail = PsgFreeBlock(PByte(StartHeap) + 80));
  CheckTrue(mm.Avail.Next = nil);
  CheckTrue(mm.Avail.Size = TotalSize - 80);

  p4 := mm.Alloc(16);
  CheckTrue(p4 = PsgFreeBlock(PByte(StartHeap) + 80));
  CheckTrue(mm.Avail = PsgFreeBlock(PByte(StartHeap) + 96));
  CheckTrue(mm.Avail.Next = nil);
  CheckTrue(mm.Avail.Size = TotalSize - 96);

  p5 := mm.Alloc(256);
  CheckTrue(p5 = PsgFreeBlock(PByte(StartHeap) + 96));
  CheckTrue(mm.Avail = PsgFreeBlock(PByte(StartHeap) + 352));
  CheckTrue(mm.Avail.Next = nil);
  CheckTrue(mm.Avail.Size = TotalSize - 352);

  p6 := mm.Alloc(64);
  CheckTrue(p6 = PsgFreeBlock(PByte(StartHeap) + 352));
  CheckTrue(mm.Avail = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(mm.Avail.Next = nil);
  CheckTrue(mm.Avail.Size = TotalSize - 416);
end;

procedure TsgMemoryManagerTest.TestDefragment;
begin
  TestAlloc;
  mm.Dealloc(p1, 8);
  mm.Dealloc(p3, 40);
  mm.Dealloc(p5, 256);
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 8);
  p := p.Next;
  CheckTrue(p = p3);
  CheckTrue(p.Size = 40);
  p := p.Next;
  CheckTrue(p = p5);
  CheckTrue(p.Size = 256);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);
end;

procedure TsgMemoryManagerTest.TestFreeWithTop;
begin
  TestAlloc;
  mm.Dealloc(p2, 32);
  CheckTrue(p2 = PsgFreeBlock(PByte(StartHeap) + 8));
  p := mm.Avail;
  CheckTrue(p = p2);
  CheckTrue(p.Size = 32);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);

  mm.Dealloc(p1, 8);
  CheckTrue(p1 = @Self.mem);
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 40);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);
end;

procedure TsgMemoryManagerTest.TestFreeWithBottom;
begin
  TestAlloc;
  mm.Dealloc(p2, 32);
  CheckTrue(p2 = PsgFreeBlock(PByte(StartHeap) + 8));
  p := mm.Avail;
  CheckTrue(p = p2);
  CheckTrue(p.Size = 32);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);

  mm.Dealloc(p3, 40);
  CheckTrue(p3 = PsgFreeBlock(PByte(StartHeap) + 40));
  p := mm.Avail;
  CheckTrue(p = p2);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);
end;

procedure TsgMemoryManagerTest.TestFreeWithBoth;
begin
  TestAlloc;
  mm.Dealloc(p1, 8);
  CheckTrue(p1 = @Self.mem);
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 8);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);

  mm.Dealloc(p3, 40);
  CheckTrue(p3 = PsgFreeBlock(PByte(StartHeap) + 40));
  p := mm.Avail;
  CheckTrue(p = p1);
  p := p.Next;
  CheckTrue(p = p3);
  CheckTrue(p.Size = 40);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);

  mm.Dealloc(p2, 32);
  CheckTrue(p2 = PsgFreeBlock(PByte(StartHeap) + 8));
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 80);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);
end;

procedure TsgMemoryManagerTest.TestInvalidParameter;
var
  ok: Boolean;
begin
  TestAlloc;
  ok := False;
  try
    mm.Dealloc(nil, 8);
  except
    ok := True;
  end;
  CheckTrue(ok);
  ok := False;
  try
    mm.Dealloc(@ok, 8);
  except
    ok := True;
  end;
  CheckTrue(ok);
  mm.Dealloc(p1, 8);
// If we try to return the same block of memory again, the program loops!
// mm.Dealloc(p1, 8);
end;

procedure TsgMemoryManagerTest.TestRealloc;
var
  pb: PByte;
  i: Integer;
begin
  p1 := mm.Alloc(8);
  CheckTrue(p1 = StartHeap);
  p := mm.Avail;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 8));
  CheckTrue(p.Size = 1592);
  CheckTrue(p.Next = nil);

  pb := p1;
  for i := 1 to 8 do
  begin
    pb^ := i;
    Inc(pb);
  end;
  p2 := mm.Realloc(p1, 8, 40);
  pb := p2;
  for i := 1 to 8 do
  begin
    CheckTrue(pb^ = i);
    Inc(pb);
  end;
  for i := 9 to 40 do
  begin
    CheckTrue(pb^ = 0);
    Inc(pb);
  end;
  CheckTrue(p1 = p2);
  p := mm.Avail;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 40));
  CheckTrue(p.Size = 1560);
  CheckTrue(p.Next = nil);

  p3 := mm.Alloc(8);
  CheckTrue(p1 = StartHeap);
  p := mm.Avail;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 48));
  CheckTrue(p.Size = 1552);
  CheckTrue(p.Next = nil);

  mm.Dealloc(p2, 40);
  CheckTrue(p2 = StartHeap);
  p := mm.Avail;
  CheckTrue(p = StartHeap);
  CheckTrue(p.Size = 40);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 48));
  CheckTrue(p.Size = 1552);
  CheckTrue(p.Next = nil);

  p4 := mm.Alloc(8);
  CheckTrue(p4 = StartHeap);
  p := mm.Avail;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 8));
  CheckTrue(p.Size = 32);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 48));
  CheckTrue(p.Size = 1552);
  CheckTrue(p.Next = nil);

  pb := p4;
  for i := 1 to 8 do
  begin
    pb^ := i;
    Inc(pb);
  end;
  p5 := mm.Realloc(p4, 8, 16);
  pb := p5;
  for i := 1 to 8 do
  begin
    CheckTrue(pb^ = i);
    Inc(pb);
  end;
  for i := 9 to 16 do
  begin
    CheckTrue(pb^ = 0);
    Inc(pb);
  end;
  CheckTrue(p5 = StartHeap);
  p := mm.Avail;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 16));
  CheckTrue(p.Size = 24);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 48));
  CheckTrue(p.Size = 1552);
  CheckTrue(p.Next = nil);

  // To avoid leaks, you must always return
  // the same amount of memory that was reserved.
  pb := p5;
  for i := 1 to 16 do
  begin
    pb^ := i;
    Inc(pb);
  end;
  p6 := mm.Realloc(p5, 16, 40);
  pb := p6;
  for i := 1 to 16 do
  begin
    CheckTrue(pb^ = i);
    Inc(pb);
  end;
  for i := 17 to 40 do
  begin
    CheckTrue(pb^ = 0);
    Inc(pb);
  end;
  CheckTrue(p6 = StartHeap);
  p := mm.Avail;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 48));
  CheckTrue(p.Size = 1552);
  CheckTrue(p.Next = nil);
end;

procedure TsgMemoryManagerTest.TestRealloc2;
var
  p7, p8: Pointer;
  pb: PByte;
  i: Integer;
begin
  TestAlloc;
  mm.Dealloc(p1, 8);
  CheckTrue(p1 = @Self.mem);
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 8);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);

  mm.Dealloc(p3, 40);
  CheckTrue(p3 = PsgFreeBlock(PByte(StartHeap) + 40));
  p := mm.Avail;
  CheckTrue(p = p1);
  p := p.Next;
  CheckTrue(p = p3);
  CheckTrue(p.Size = 40);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 416));
  CheckTrue(p.Size = 1184);
  CheckTrue(p.Next = nil);

  pb := p4;
  for i := 1 to 16 do
  begin
    pb^ := i;
    Inc(pb);
  end;
  p7 := mm.Realloc(p4, 16, 64);
  pb := p7;
  for i := 1 to 16 do
  begin
    CheckTrue(pb^ = i);
    Inc(pb);
  end;
  for i := 17 to 64 do
  begin
    CheckTrue(pb^ = 0);
    Inc(pb);
  end;
  CheckTrue(p7 = PsgFreeBlock(PByte(StartHeap) + 416));
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 8);
  p := p.Next;
  CheckTrue(p = p3);
  CheckTrue(p.Size = 56);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 480));
  CheckTrue(p.Size = 1120);
  CheckTrue(p.Next = nil);

  pb := p2;
  for i := 1 to 32 do
  begin
    pb^ := i;
    Inc(pb);
  end;
  p8 := mm.Realloc(p2, 32, 128);
  pb := p8;
  for i := 1 to 32 do
  begin
    CheckTrue(pb^ = i);
    Inc(pb);
  end;
  for i := 33 to 128 do
  begin
    CheckTrue(pb^ = 0);
    Inc(pb);
  end;
  CheckTrue(p8 = PsgFreeBlock(PByte(StartHeap) + 480));
  p := mm.Avail;
  CheckTrue(p = p1);
  CheckTrue(p.Size = 96);
  p := p.Next;
  CheckTrue(p = PsgFreeBlock(PByte(StartHeap) + 608));
  CheckTrue(p.Size = 992);
  CheckTrue(p.Next = nil);
end;

{$EndRegion}

{$Region 'TSysCtxTest'}

procedure TSysCtxTest.SetUp;
begin
end;

procedure TSysCtxTest.TearDown;
begin
end;

procedure TSysCtxTest.TestCreateMeta;
var
  value: Integer;
  meta: PsgItemMeta;
  region: TUnbrokenRegion;
  item: TsgItem;
begin
  value := 45;
  meta := SysCtx.CreateMeta<Integer>;
  region.Init(meta, 1024);
  item.Init(region.Region^, value);
end;

procedure TSysCtxTest.TestCreateTeMeta;
var
  i: Integer;
  List: TsgTupleMeta.TsgTeMetaList;
  a, b, c, d, meta: PsgTupleElementMeta;
begin
  SysCtx.CreateTeMetas(4, List);
  a := List.Add;
  a.Offset := 0;
  b := List.Add;
  a.Offset := 4;
  c := List.Add;
  a.Offset := 8;
  d := List.Add;
  a.Offset := 16;
  for i := 0 to 3 do
  begin
    meta := List.Items[i];

  end;
end;

{$EndRegion}

{$Region 'TUnbrokenRegionTest'}

procedure TUnbrokenRegionTest.TParam<T>.Init(av, bv: T;
  u: TUpdateProc; eq: TEqualsFunc);
begin
  a := av;
  b := bv;
  update := u;
  equals := eq;
end;

procedure TUnbrokenRegionTest.SetUp;
begin
end;

procedure TUnbrokenRegionTest.TearDown;
begin
  region.Free;
end;

procedure TUnbrokenRegionTest.Init<T>(var value: T);
begin
  meta := SysCtx.CreateMeta<T>;
  region.Init(meta, 1024);
  item.Init(region.Region^, value);
end;

procedure TUnbrokenRegionTest.Get<T>(idx: Integer; var value: T);
type
  PT = ^T;
var
  p: Pointer;
begin
  // read
  p := region.GetItemPtr(idx);
  value := PT(p)^;
end;

function TUnbrokenRegionTest.Add<T>(const value: T): Integer;
type
  PT = ^T;
var
  idx: Integer;
  r: Pointer;
begin
  // create
  idx := region.Count;
  region.AddItem;
  // read
  r := region.GetItemPtr(idx);
  // update
  PT(r)^ := value;
  Result := idx;
end;

procedure TUnbrokenRegionTest._CRUD<T>(var a, b: T; equals: TEqualsFunc);
type
  TMyArray = array [0..100000] of T;
  PMyArray = ^TMyArray;
var
  c: T;
  idx: Integer;
begin
  Init<T>(a);
  item.Assign(b);
  CheckTrue(equals(@a, @b));
  idx := Add<T>(a);
  Get<T>(idx, b);
  CheckTrue(equals(@a, @b));
  c := PMyArray(region.GetItemPtr(0))[idx];
  CheckTrue(equals(@a, @c));
end;

procedure TUnbrokenRegionTest._Clear<T>(var prm: TParam<T>);
var
  i, idx: Integer;
begin
  CheckTrue(region.Count = 1);
  region.Clear;
  for i := 0 to 0 do
  begin
    prm.update(@prm.a, i);
    idx := Add<T>(prm.a);
    Get<T>(idx, prm.b);
    CheckTrue(prm.equals(@prm.a, @prm.b));
  end;
  CheckTrue(region.Count = 1);
end;

procedure TUnbrokenRegionTest._AssignItems<T>;
begin

end;

procedure TUnbrokenRegionTest._Checks<T>;
begin

end;

procedure TUnbrokenRegionTest._FreeItems<T>;
begin

end;

procedure TUnbrokenRegionTest._Test<T>(var prm: TParam<T>);
begin
  _CRUD<T>(prm.a, prm.b, prm.equals);
  _Clear<T>(prm);
  region.Free;
end;

procedure ByteUpdate(p: Pointer; value: Integer);
type
  PT = ^Byte;
begin
  PT(p)^ := value;
end;

function ByteEquals(a, b: Pointer): Boolean;
type
  PT = ^Byte;
begin
  Result := PT(a)^ = PT(b)^;
end;

procedure TUnbrokenRegionTest._Byte;
var
  prm: TParam<Byte>;
begin
  prm.Init(5, 43, ByteUpdate, ByteEquals);
  _Test<Byte>(prm);
end;

procedure WordUpdate(p: Pointer; value: Integer);
type
  PT = ^Word;
begin
  PT(p)^ := value;
end;

function WordEquals(a, b: Pointer): Boolean;
type
  PT = ^Word;
begin
  Result := PT(a)^ = PT(b)^;
end;

procedure TUnbrokenRegionTest._Word;
var
  prm: TParam<Word>;
begin
  prm.Init(5, 43, WordUpdate, WordEquals);
  _Test<Word>(prm);
end;

procedure IntUpdate(p: Pointer; value: Integer);
type
  PT = ^Integer;
begin
  PT(p)^ := value;
end;

function IntEquals(a, b: Pointer): Boolean;
type
  PT = ^Integer;
begin
  Result := PT(a)^ = PT(b)^;
end;

procedure TUnbrokenRegionTest._Integer;
var
  prm: TParam<Integer>;
begin
  prm.Init(5, 43, IntUpdate, IntEquals);
  _Test<Integer>(prm);
end;

procedure Int64Update(p: Pointer; value: Integer);
type
  PT = ^Int64;
begin
  PT(p)^ := value;
end;

function Int64Equals(a, b: Pointer): Boolean;
type
  PT = ^Int64;
begin
  Result := PT(a)^ = PT(b)^;
end;

procedure TUnbrokenRegionTest._Int64;
var
  prm: TParam<Int64>;
begin
  prm.Init(5, 43, Int64Update, Int64Equals);
  _Test<Int64>(prm);
end;

procedure t3Update(p: Pointer; value: Integer);
type
  PT = ^t3;
begin
  with PT(p)^ do
  begin
    a := value + 5;
    b := value + 25;
    c := value;
  end;
end;

function t3Equals(a, b: Pointer): Boolean;
type
  PT = ^t3;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := (pa.a = pb.a) and (pa.b = pb.b) and (pa.c = pb.c);
end;

procedure TUnbrokenRegionTest._Size3;
var
  prm: TParam<t3>;
  a, b: t3;
begin
  a.a := 45; a.b := 49; a.c := 78;
  b.a := 5; b.b := 12; b.c := 3;
  prm.Init(a, b, t3Update, t3Equals);
  _Test<t3>(prm);
end;

procedure t7Update(p: Pointer; value: Integer);
type
  PT = ^t7;
var
  i: Integer;
  pv: PT;
begin
  pv := PT(p);
  for i := 0 to High(t7) do
    pv[i] := value + i;
end;

function t7Equals(a, b: Pointer): Boolean;
type
  PT = ^t7;
var
  pa, pb: PT;
  i: Integer;
begin
  pa := PT(a); pb := PT(b);
  for i := 0 to High(t7) do
    if pa[i] <>  pb[i] then exit(False);
  Result := True;
end;

procedure TUnbrokenRegionTest._Size7;
var
  prm: TParam<t7>;
  a, b: t7;
  i: Integer;
begin
  for i := 0 to High(t7) do
  begin
    a[i] := i + 5;
    b[i] := i + 77;
  end;
  prm.Init(a, b, t7Update, t7Equals);
  _Test<t7>(prm);
end;

procedure PersonUpdate(p: Pointer; value: Integer);
type
  PT = ^TPerson;
begin
  with PT(p)^ do
  begin
    id := value;
    name := IntToStr(value);
  end;
end;

function PersonEquals(a, b: Pointer): Boolean;
type
  PT = ^TPerson;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := (pa.id = pb.id) and (pa.name = pb.name);
end;

procedure TUnbrokenRegionTest._ManagedType;
var
  a, b: TPerson;
  prm: TParam<TPerson>;
begin
  a := TPerson.From('Peter');
  a.id := 1;
  b := TPerson.From('Nick');
  b.id := 43;
  prm.Init(a, b, PersonUpdate, PersonEquals);
  _Test<TPerson>(prm);
end;

procedure VariantUpdate(p: Pointer; value: Integer);
type
  PT = ^Variant;
begin
  PT(p)^ := IntToStr(value);
end;

function VariantEquals(a, b: Pointer): Boolean;
type
  PT = ^Variant;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := pa^ = pb^;
end;

procedure TUnbrokenRegionTest._Variant;
var
  a, b: Variant;
  prm: TParam<Variant>;
begin
  a := 'Peter';
  b := 12.45;
  prm.Init(a, b, VariantUpdate, VariantEquals);
  _Test<Variant>(prm);
end;

procedure ObjectUpdate(p: Pointer; value: Integer);
type
  PT = ^TIntId;
begin
  PT(p)^.Id := value;
end;

function ObjectEquals(a, b: Pointer): Boolean;
type
  PT = ^TIntId;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := pa.Id = pb.Id;
end;

procedure TUnbrokenRegionTest._Object;
var
  a, b: TIntId;
  prm: TParam<TIntId>;
begin
  a := TIntId.Create;
  a.Id := 75;
  b := TIntId.Create;
  b.Id := 43;
  prm.Init(a, b, ObjectUpdate, ObjectEquals);
  _Test<TIntId>(prm);
end;

procedure InterfaceUpdate(p: Pointer; value: Integer);
type
  PT = ^IIntId;
begin
  PT(p)^.Id := value;
end;

function InterfaceEquals(a, b: Pointer): Boolean;
type
  PT = ^IIntId;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := pa.Id = pb.Id;
end;

procedure TUnbrokenRegionTest._Interface;
var
  a, b: IIntId;
  prm: TParam<IIntId>;
begin
  a := TIntId.Create;
  a.Id := 75;
  b := TIntId.Create;
  b.Id := 43;
  prm.Init(a, b, InterfaceUpdate, InterfaceEquals);
  _Test<IIntId>(prm);
end;

type
  TDynArray = TArray<Integer>;

procedure DynArrayUpdate(p: Pointer; value: Integer);
type
  PT = ^TDynArray;
var
  i: Integer;
  pa: PT;
begin
  pa := PT(p);
  for i := 0 to High(pa^) do
    pa^[i] := value + i;
end;

function DynArrayEquals(a, b: Pointer): Boolean;
type
  PT = ^TDynArray;
var
  pa, pb: PT;
  i: Integer;
begin
  pa := PT(a); pb := PT(b);
  if Length(pa^) <> Length(pb^) then exit(False);
  for i := 0 to High(pa^) do
    if pa^[i] <> pb^[i] then exit(False);
  Result := True;
end;

procedure TUnbrokenRegionTest._DynArray;
var
  a, b: TDynArray;
  prm: TParam<TDynArray>;
begin
  a := [5, 75, 588];
  b := [43];
  prm.Init(a, b, DynArrayUpdate, DynArrayEquals);
  _Test<TDynArray>(prm);
end;

procedure StringUpdate(p: Pointer; value: Integer);
type
  PT = ^string;
begin
  PT(p)^ := IntToStr(value);
end;

function StringEquals(a, b: Pointer): Boolean;
type
  PT = ^string;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := pa^ = pb^;
end;

procedure TUnbrokenRegionTest._String;
var
  a, b: string;
  prm: TParam<string>;
begin
  a := 'string a';
  b := 'string b';
  prm.Init(a, b, StringUpdate, StringEquals);
  _Test<string>(prm);
end;

procedure TUnbrokenRegionTest.Test;
type
  TMyArray = array [0..100000] of string;
  PMyArray = ^TMyArray;
var
  a, b, c: string;
  idx: Integer;
begin
  Init<string>(a);
  idx := Add<string>(a);
  Get<string>(idx, b);
  CheckTrue(StringEquals(@a, @b));
  c := PMyArray(region.GetItemPtr(0))[idx];
  CheckTrue(StringEquals(@a, @c));
  CheckTrue(region.Count = 1);
  region.Clear;
  idx := Add<string>(a);
  CheckTrue(idx = 0);
  region.Free;
end;

procedure WideStringUpdate(p: Pointer; value: Integer);
type
  PT = ^WideString;
begin
  PT(p)^ := IntToStr(value);
end;

function WideStringEquals(a, b: Pointer): Boolean;
type
  PT = ^WideString;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := pa^ = pb^;
end;

procedure TUnbrokenRegionTest._WideString;
var
  a, b: WideString;
  prm: TParam<WideString>;
begin
  a := 'string a';
  b := 'string b';
  prm.Init(a, b, WideStringUpdate, WideStringEquals);
  _Test<WideString>(prm);
end;

procedure RawByteStringUpdate(p: Pointer; value: Integer);
type
  PT = ^RawByteString;
begin
  PT(p)^ := RawByteString(IntToStr(value));
end;

function RawByteStringEquals(a, b: Pointer): Boolean;
type
  PT = ^RawByteString;
var
  pa, pb: PT;
begin
  pa := PT(a); pb := PT(b);
  Result := pa^ = pb^;
end;

procedure TUnbrokenRegionTest._RawByteString;
var
  a, b: RawByteString;
  prm: TParam<RawByteString>;
begin
  a := 'string a';
  b := 'string b';
  prm.Init(a, b, RawByteStringUpdate, RawByteStringEquals);
  _Test<RawByteString>(prm);
end;

{$EndRegion}

{$Region 'TSegmentedRegionTest'}

procedure TSegmentedRegionTest.SetUp;
begin

end;

procedure TSegmentedRegionTest.TearDown;
begin

end;

procedure TSegmentedRegionTest.Init<T>(var value: T);
begin
  meta := SysCtx.CreateMeta<T>;
  region.Init(meta, 1024);
  item.Init(region.Region^, value);
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

procedure TsgItemTest.InitItem<T>(var value: T);
begin
  meta := SysCtx.CreateMeta<T>;
  region.Init(meta, 1024);
  item.Init(region, value);
end;

procedure TsgItemTest.TestByte;
var
  a, b: Byte;
begin
  a := 5;
  b := 43;
  InitItem<Byte>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.TestChar;
var
  a, b: Char;
begin
  a := 'Q';
  b := 'F';
  InitItem<Char>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.TestWord;
var
  a, b: Word;
begin
  a := 5;
  b := 43;
  InitItem<Word>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.Test4;
var
  a, b: Integer;
begin
  a := 5;
  b := 43;
  InitItem<Integer>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.Test8;
var
  a, b: Int64;
begin
  a := 5;
  b := 43;
  InitItem<Int64>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.Test0;
type
  t0 = record end;
var
  a: t0;
  ok: Boolean;
begin
  CheckTrue(sizeof(t0) = 0);
  ok := False;
  try
    InitItem<t0>(a);
  except
    ok := True;
  end;
  CheckTrue(ok);
end;

procedure TsgItemTest.TestOtherSize;
var
  a, b: t3;
begin
  CheckTrue(sizeof(t3) = 3);
  a.a := 12;
  a.b := 45;
  a.c := 78;
  b.a := 5;
  b.b := 145;
  b.c := 178;
  InitItem<t3>(a);
  item.Assign(b);
  CheckTrue(a.a = b.a);
  CheckTrue(a.b = b.b);
  CheckTrue(a.c = b.c);
end;

procedure TsgItemTest.TestItem;
var
  i: Integer;
  a, b: t7;
begin
  CheckTrue(sizeof(t7) = 7);
  for i := 0 to High(t7) do
  begin
    a[i] := 23;
    b[i] := i;
  end;
  InitItem<t7>(a);
  item.Assign(b);
  for i := 0 to High(t7) do
    CheckTrue(a[i]= b[i]);
end;

procedure TsgItemTest.TestManaged;
var
  a, b, c: TPerson;
begin
  // record with managed fields
  a := TPerson.From('Peter');
  a.id := 1;
  b := TPerson.From('Nick');
  b.id := 43;
  InitItem<TPerson>(a);
  System.CopyRecord(@c, @a, Meta.TypeInfo);
  CheckTrue(a.id = c.id);
  CheckTrue(a.name = c.name);
  item.Assign(b);
  CheckTrue(a.id = b.id);
  CheckTrue(a.name = b.name);
  item.Free;
  CheckTrue(a.name = '');
end;

procedure TsgItemTest.TestVariant;
var
  a, b: Variant;
begin
  // record with managed fields
  a := 'Peter';
  b := 12.45;
  InitItem<Variant>(a);
  item.Assign(b);
  CheckTrue(SameValue(a, 12.45));
  item.Free;
  CheckTrue(a = 0);
end;

procedure TsgItemTest.TestObject;
var
  a, b, x: TIntId;
begin
  a := TIntId.Create;
  a.Id := 75;
  b := TIntId.Create;
  b.Id := 43;
  InitItem<TIntId>(a);
  x := a;
  item.Assign(b);
  CheckTrue(a.Id = b.Id);
  x.Free;
  b.Free;
end;

procedure TsgItemTest.TestInterface;
var
  a, b: IIntId;
begin
  a := TIntId.Create;
  a.Id := 75;
  b := TIntId.Create;
  b.Id := 43;
  InitItem<IIntId>(a);
  item.Assign(b);
  CheckTrue(a.Id = b.Id);
end;

procedure TsgItemTest.TestWeakRef;
begin
  // WeakRef
end;

procedure TsgItemTest.TestDynArray;
var
  a, b: TArray<Integer>;
begin
  a := [5, 75, 588];
  b := [43];
  InitItem<TArray<Integer>>(a);
  item.Assign(b);
  CheckTrue(Length(a) = 1);
  CheckTrue(a[0] = 43);
end;

procedure TsgItemTest.TestString;
var
  a, b: string;
begin
  a := 'string a';
  b := 'string b';
  InitItem<string>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.TestWideString;
var
  a, b: WideString;
begin
  a := 'string a';
  b := 'string b';
  InitItem<WideString>(a);
  item.Assign(b);
  CheckTrue(a = b);
end;

procedure TsgItemTest.TestRawByteString;
var
  a, b: RawByteString;
begin
  a := 'string a';
  b := 'string b';
  InitItem<RawByteString>(a);
  item.Assign(b);
  CheckTrue(a = b);
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

procedure THeapPoolTest._MemSegment;
const
  MemSize = 1024 * 4;
var
  s, s1: PMemSegment;
  before, last, after: PInteger;
  bv, av, lv: Integer;

  procedure CheckOther;
  var
    p, hr: PByte;
    freeSise, heapSize, occupiedSize: NativeUInt;
  begin
    p := PByte(s);
    hr := s.GetHeapRef;
    Check(p + sizeof(TMemSegment) = hr);
    freeSise := s.GetFreeSize;
    heapSize := s.GetHeapSize;
    occupiedSize := s.GetOccupiedSize;
    Check(freeSise + occupiedSize = heapSize - sizeof(TMemSegment));
  end;

  procedure FillSegment;
  var
    cnt: Cardinal;
    iv: PInteger;
  begin
    cnt := s.GetFreeSize div 4;
    while cnt > 0 do
    begin
      Check(cnt = s.GetFreeSize div 4);
      iv := PInteger(s.Occupy(4));
      Check(iv <> nil);
      iv^ := 123456;
      if cnt > 1 then
      begin
        Check(s.GetFreeSize > 0);
        Check(last^ = lv);
      end
      else
      begin
        Check(s.GetFreeSize = 0);
        Check(last^ = 123456)
      end;
      Check(bv = before^);
      Check(av = after^);
      Dec(cnt);
      CheckOther;
    end;
  end;

  procedure CheckSegment(FreeSize, SegmentSize: Cardinal);
  var
    p, hr: PByte;
    iv: PInteger;
  begin
    p := PByte(s);
    before := PInteger(p - sizeof(Integer));
    after := PInteger(p + SegmentSize);
    last := PInteger(PByte(after) - sizeof(Integer));
    bv := before^;
    av := after^;
    lv := last^;
    CheckOther;

    hr := s.GetHeapRef;
    Check(hr = p + sizeof(TMemSegment));
    Check(s.GetFreeSize = freeSize);
    iv := PInteger(s.Occupy(4));
    Check(s.GetFreeSize = freeSize - 4);
    Check(iv^ = 0);
    CheckOther;
  end;

var
  n, FreeSize, HeapSize: Cardinal;
begin
  HeapSize := MemSize;
  TMemSegment.NewSegment(s, HeapSize);
  try
    FreeSize := HeapSize - sizeof(TMemSegment);
    CheckSegment(FreeSize, HeapSize);
    FillSegment;

    HeapSize := HeapSize + MemSize;
    TMemSegment.IncreaseHeapSize(s, HeapSize);
    CheckSegment(MemSize, HeapSize);
    FillSegment;

    for n := 0 to 3 do
    begin
      TMemSegment.NewSegment(s1, MemSize);
      try
        HeapSize := HeapSize + MemSize;
        TMemSegment.IncreaseHeapSize(s, HeapSize);
        CheckSegment(MemSize, HeapSize);
        FillSegment;
      finally
        FreeMem(s1);
      end;
    end;
  finally
    FreeMem(s);
  end;
end;

procedure THeapPoolTest._hMeta;
var
  size: Integer;
  h: hMeta;
begin
  size := sizeof(hMeta);
  CheckTrue(size = 4);
  h := hMeta.From(System.TTypeKind.tkMRecord, True, True);
  CheckTrue(h.TypeKind = System.TTypeKind.tkMRecord);
  CheckTrue(h.ManagedType);
  CheckTrue(h.HasWeakRef);
  CheckTrue(not h.RangeCheck);
  CheckTrue(not h.Notification);
  CheckTrue(not h.OwnedObject);
  CheckTrue(h.RemoveAction = TRemoveAction(0));
  CheckTrue(not h.Segmented);
  CheckTrue(h.SeedValue = 25117);
  CheckTrue(h.Valid);
  h.Segmented := True;
  CheckTrue(h.Segmented);
  h.RemoveAction := TRemoveAction.Other;
  CheckTrue(not h.OwnedObject);
  CheckTrue(h.RemoveAction = TRemoveAction.Other);
  CheckTrue(h.SeedValue = 25117);
end;

procedure THeapPoolTest._CreateRegion;
var
  i: Integer;
  r: PSegmentedRegion;
  head, newNode: PListNode;
  meta: PsgItemMeta;
begin
  meta := SysCtx.CreateMeta<TListNode>;
  r := HeapPool.CreateRegion(meta);
  try
    head := nil;
    for i := 1 to ItemsCount do
    begin
      newNode := r.Region.Alloc(sizeof(TListNode));
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
  r: PUnbrokenRegion;
  p, q, b: PListNode;
  a: TArray<NativeUInt>;
  pa, qa, a0, a1: NativeUInt;
  meta: PsgItemMeta;
begin
  meta := SysCtx.CreateMeta<TListNode>;
  r := HeapPool.CreateUnbrokenRegion(meta);
  try
    q := nil;
    for i := 0 to ItemsCount - 1 do
    begin
      p := PListNode(r.AddItem);
      b := PListNode(r.GetItemPtr(i));
      Check(p = b);
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
          b := PListNode(r.GetItemPtr(j));
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

{$Region 'TsgTupleMetaTest'}

procedure TsgTupleMetaTest.SetUp;
begin
  inherited;
end;

procedure TsgTupleMetaTest.TearDown;
begin
  inherited;
end;

procedure TsgTupleMetaTest._TupleOffset;
var
  te: TsgTupleElementMeta;
  offset: Cardinal;
  b1, b2: Byte;
  w1, w2: Word;
  d1, d2: Double;
  i1, i2: Integer;
  s1, s2: string;
  p1, p2: TPerson;
  bytes: array [0 .. 63] of Byte;
  ptr1, ptr2: Pointer;
  i: Integer;
begin
  // Byte
  te.Init<Byte>;
  CheckTrue(te.Meta.ItemSize = 1);
  CheckTrue(te.Meta.h.TypeKind = TTypeKind.tkInteger);
  offset := te.NextTupleOffset(False);
  CheckTrue(offset = 1);
  offset := te.NextTupleOffset(True);
  CheckTrue(offset = 4);
  CheckTrue(not Assigned(te.Free));
  CheckTrue(Assigned(te.Assign));
  b1 := 123; b2 := 75;
  te.Assign(te.Meta, @b1, @b2);
  CheckTrue(b1 = 75);

  // Word
  te.Init<Word>;
  CheckTrue(te.Meta.ItemSize = 2);
  CheckTrue(te.Meta.h.TypeKind = TTypeKind.tkInteger);
  offset := te.NextTupleOffset(False);
  CheckTrue(offset = 2);
  offset := te.NextTupleOffset(True);
  CheckTrue(offset = 4);
  CheckTrue(not Assigned(te.Free));
  CheckTrue(Assigned(te.Assign));
  w1 := 12349; w2 := 705;
  te.Assign(te.Meta, @w1, @w2);
  CheckTrue(w1 = 705);

  // Integer
  te.Init<Integer>;
  CheckTrue(te.Meta.ItemSize = 4);
  offset := te.NextTupleOffset(False);
  CheckTrue(offset = 4);
  offset := te.NextTupleOffset(True);
  CheckTrue(offset = 4);
  CheckTrue(not Assigned(te.Free));
  CheckTrue(Assigned(te.Assign));
  i1 := 12279349; i2 := 70564;
  te.Assign(te.Meta, @i1, @i2);
  CheckTrue(i1 = 70564);

  // Check the clearing and assignment of data not aligned to the word boundary.
  for i := 0 to 8 do
  begin
    ptr1 := @bytes[i];
    ptr2 := @bytes[i + 11];
    if Odd(NativeUInt(ptr1)) then
      break;
  end;
  te.Assign(te.Meta, ptr2, @i2);
  CheckTrue(Integer(ptr2^) = 70564);
  te.Assign(te.Meta, ptr1, ptr2);
  CheckTrue(Integer(ptr1^) = 70564);

  // Double
  te.Init<Double>;
  CheckTrue(te.Meta.ItemSize = 8);
  offset := te.NextTupleOffset(False);
  CheckTrue(offset = 8);
  offset := te.NextTupleOffset(True);
  CheckTrue(offset = 8);
  CheckTrue(not Assigned(te.Free));
  CheckTrue(Assigned(te.Assign));
  d1 := 12279349.34; d2 := 70564.567;
  te.Assign(te.Meta, @d1, @d2);
  CheckTrue(SameValue(d1, 70564.567));

  // Check the clearing and assignment of data not aligned to the word boundary.
  for i := 0 to 8 do
  begin
    ptr1 := @bytes[i];
    ptr2 := @bytes[i + 11];
    if Odd(NativeUInt(ptr1)) then
      break;
  end;
  te.Assign(te.Meta, ptr2, @d2);
  CheckTrue(SameValue(Double(ptr2^), 70564.567));
  te.Assign(te.Meta, ptr1, ptr2);
  CheckTrue(SameValue(Double(ptr1^), 70564.567));

  // string
  te.Init<string>;
  CheckTrue(te.Meta.ItemSize = 4);
  offset := te.NextTupleOffset(False);
  CheckTrue(offset = 4);
  offset := te.NextTupleOffset(True);
  CheckTrue(offset = 4);
  CheckTrue(Assigned(te.Free));
  CheckTrue(Assigned(te.Assign));
  s1 := '12279349'; s2 := '70564';
  te.Free(te.Meta, @s1);
  CheckTrue(s1 = '');
  te.Assign(te.Meta, @s1, @s2);
  CheckTrue(s1 = '70564');

  // TPerson
  te.Init<TPerson>;
  CheckTrue(te.Meta.ItemSize = 8);
  offset := te.NextTupleOffset(False);
  CheckTrue(offset = 8);
  offset := te.NextTupleOffset(True);
  CheckTrue(offset = 8);
  CheckTrue(Assigned(te.Free));
  CheckTrue(Assigned(te.Assign));
  p1 := TPerson.From('sd12279349');
  p1.id := 45;
  p2 := TPerson.From('er70564');
  p2.id := 545;
  te.Free(te.Meta, @p1);
  CheckTrue(p1.name = '');
  CheckTrue(p1.id = 45);
  te.Assign(te.Meta, @p1, @p2);
  CheckTrue(p1.name = 'er70564');
  CheckTrue(p1.id = 545);
end;

procedure TsgTupleMetaTest._MakePair;
var
  PairMeta, PairMetaAligned: TsgTupleMeta;
  te0, te1: PsgTupleElementMeta;
begin
  // create a pair without alignment
  PairMeta.MakePair<TVector, string>(nil, False);
  // check total size, element addresses and offsets
  te0 := PairMeta.Get(0);
  te1 := PairMeta.Get(1);
  CheckTrue(te0.Size = sizeof(TVector));
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = sizeof(string));
  CheckTrue(te1.Offset = 24);
  CheckTrue(PairMeta.Size = 28);
  // create a word-aligned pair
  PairMetaAligned.MakePair<TVector, string>(nil, True);
  // check total size, element addresses and offsets
  te0 := PairMetaAligned.Get(0);
  te1 := PairMetaAligned.Get(1);
  CheckTrue(te0.Size = sizeof(TVector));
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = sizeof(string));
  CheckTrue(te1.Offset = 24);
  CheckTrue(PairMeta.Size = 28);
end;

procedure TsgTupleMetaTest._MakeTrio;
var
  TrioMeta: TsgTupleMeta;
  te0, te1, te2: PsgTupleElementMeta;
begin
  // create a pair without alignment
  TrioMeta.MakeTrio<Pointer, TVector, Integer>(nil, True);
  // check total size, element addresses and offsets
  te0 := TrioMeta.Get(0);
  te1 := TrioMeta.Get(1);
  te2 := TrioMeta.Get(2);
  CheckTrue(te0.Size = 4);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 24);
  CheckTrue(te1.Offset = 4);
  CheckTrue(te2.Size = 4);
  CheckTrue(te2.Offset = 28);
  CheckTrue(TrioMeta.Size = 32);
end;

procedure TsgTupleMetaTest._MakeQuad;
var
  QuadMeta: TsgTupleMeta;
  te0, te1, te2, te3: PsgTupleElementMeta;
begin
  // create a pair without alignment
  QuadMeta.MakeQuad<Pointer, TVector, TPerson, Integer>(nil, True);
  // check total size, element addresses and offsets
  te0 := QuadMeta.Get(0);
  te1 := QuadMeta.Get(1);
  te2 := QuadMeta.Get(2);
  te3 := QuadMeta.Get(3);
  CheckTrue(te0.Size = 4);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 24);
  CheckTrue(te1.Offset = 4);
  CheckTrue(te2.Size = 8);
  CheckTrue(te2.Offset = 28);
  CheckTrue(te3.Size = 4);
  CheckTrue(te3.Offset = 36);
  CheckTrue(QuadMeta.Size = 40);
end;

procedure TsgTupleMetaTest._Cat;
var
  tupleMeta: TsgTupleMeta;
  Trio: TsgTupleMeta;
  te0, te1, te2, te3, te4: PsgTupleElementMeta;
begin
  tupleMeta.MakePair<TVector, string>(nil, True);
  Trio.MakeTrio<Pointer, TPerson, Integer>(nil, True);
  tupleMeta.Cat(Trio, nil, True);
  // check total size, element addresses and offsets
  te0 := tupleMeta.Get(0);
  te1 := tupleMeta.Get(1);
  te2 := tupleMeta.Get(2);
  te3 := tupleMeta.Get(3);
  te4 := tupleMeta.Get(4);
  CheckTrue(te0.Size = sizeof(TVector));
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = sizeof(string));
  CheckTrue(te1.Offset = 24);
  CheckTrue(te2.Size = sizeof(Pointer));
  CheckTrue(te2.Offset = 28);
  CheckTrue(te3.Size = sizeof(TPerson));
  CheckTrue(te3.Offset = 32);
  CheckTrue(te4.Size = sizeof(Integer));
  CheckTrue(te4.Offset = 40);
  CheckTrue(tupleMeta.Size = 44);
end;

procedure TsgTupleMetaTest._Add;
var
  tupleMeta: TsgTupleMeta;
  te0, te1, te2: PsgTupleElementMeta;
begin
  // create a pair without alignment
  tupleMeta.MakePair<TVector, string>(nil, True);
  CheckTrue(tupleMeta.Count = 2);
  // check total size, element addresses and offsets
  te0 := tupleMeta.Get(0);
  te1 := tupleMeta.Get(1);
  CheckTrue(te0.Size = 24);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 4);
  CheckTrue(te1.Offset = 24);
  CheckTrue(tupleMeta.Size = 28);
  tupleMeta.Add<Byte>(nil, True);
  te0 := tupleMeta.Get(0);
  te1 := tupleMeta.Get(1);
  te2 := tupleMeta.Get(2);
  CheckTrue(te0.Size = 24);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 4);
  CheckTrue(te1.Offset = 24);
  CheckTrue(te2.Size = 1);
  CheckTrue(te2.Offset = 28);
  CheckTrue(tupleMeta.Size = 32);
end;

procedure TsgTupleMetaTest._Insert;
var
  Tuple: TsgTupleMeta;
  te0, te1, te2: PsgTupleElementMeta;
begin
  // create a pair without alignment
  Tuple.MakePair<TVector, string>(nil, True);
  // check total size, element addresses and offsets
  te0 := Tuple.Get(0);
  te1 := Tuple.Get(1);
  CheckTrue(te0.Size = 24);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 4);
  CheckTrue(te1.Offset = 24);
  CheckTrue(Tuple.Size = 28);
  Tuple.Insert<Byte>(nil, True);
  te0 := Tuple.Get(0);
  te1 := Tuple.Get(1);
  te2 := Tuple.Get(2);
  CheckTrue(te0.Size = 1);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 24);
  CheckTrue(te1.Offset = 4);
  CheckTrue(te2.Size = 4);
  CheckTrue(te2.Offset = 28);
  CheckTrue(Tuple.Size = 32);
end;

{$EndRegion}

{$Region 'TsgTupleTest'}

procedure TsgTupleTest.SetUp;
begin
  inherited;
end;

procedure TsgTupleTest.TearDown;
begin
  inherited;
end;

procedure TsgTupleTest._TupleOffset;
begin

end;

procedure TsgTupleTest._Assign;
type
  TMyRecord = packed record
    p: Pointer;
    v: TVector;
    i: Integer;
  end;
var
  Trio: TsgTupleMeta;
  te0, te1, te2: PsgTupleElementMeta;
//  r: PMemoryRegion;
//  a, b: TMyRecord;
begin
  // create a pair without alignment
  Trio.MakeTrio<Pointer, TVector, Integer>(nil, False);
  // check total size, element addresses and offsets
  te0 := Trio.Get(0);
  te1 := Trio.Get(1);
  te2 := Trio.Get(2);
  CheckTrue(te0.Size = 4);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 24);
  CheckTrue(te1.Offset = 4);
  CheckTrue(te2.Size = 4);
  CheckTrue(te2.Offset = 28);
  CheckTrue(Trio.Size = 32);
  // get meta
//  r := Trio.MakeTupleRegion([]);
//  a.p := @Self;
//  a.v.x := 1.5;
//  a.v.y := 2;
//  a.v.z := 3;
//  a.i := 15;
//  r.Meta.AssignItem(@b, @a);
//  CheckTrue(b.p = a.p);
//  CheckTrue(SameValue(b.v.x, a.v.x));
//  CheckTrue(SameValue(b.v.y, a.v.y));
//  CheckTrue(SameValue(b.v.z, a.v.z));
//  CheckTrue(b.i = a.i);
end;

procedure TsgTupleTest._AssignPart;
type
  TMyRecord2 = packed record
    v: TVector;
    s: string;
    i: Integer;
  end;
var
  meta: TsgTupleMeta;
  te0, te1, te2: PsgTupleElementMeta;
//  rgn: PMemoryRegion;
//  a, b: TMyRecord2;
//  item: PsgItemMeta;
begin
  // create a pair without alignment
  meta.MakeTrio<TVector, string, Integer>(nil, False);

  // check total size, element addresses and offsets
  te0 := meta.Get(0);
  te1 := meta.Get(1);
  te2 := meta.Get(2);
  CheckTrue(te0.Size = 24);
  CheckTrue(te0.Offset = 0);
  CheckTrue(te1.Size = 4);
  CheckTrue(te1.Offset = 24);
  CheckTrue(te2.Size = 4);
  CheckTrue(te2.Offset = 28);
  CheckTrue(meta.Size = 32);

  // get meta
//  rgn := meta.MakeTupleRegion;
//  a.s := 'qwerty';
//  a.v.x := 1.5;
//  a.v.y := 2;
//  a.v.z := 3;
//  a.i := 15;
//  item := rgn.Meta;
//  item.AssignItem(@b, @a);
//  CheckTrue(b.s = a.s);
//  CheckTrue(SameValue(b.v.x, a.v.x));
//  CheckTrue(SameValue(b.v.y, a.v.y));
//  CheckTrue(SameValue(b.v.z, a.v.z));
//  CheckTrue(b.i = a.i);
end;

(*
procedure TsgTupleMetaTest._GoodAssignPart;
var
  meta: TsgTupleMeta;
  rgn: PMemoryRegion;
  tuple1, tuple2: TsgTuple;
  ptr: Pointer;
  pv: PVector;
  ps: PChar;
  pi: PInteger;
begin
  meta.MakeTrio<TVector, string, Integer>(nil, True);
  rgn := meta.MakeTupleRegion;
  tuple1 := rgn[5];
  tuple2 := rgn[7];
  tuple1.Assign(rgn[7]);
  ptr := tuple.tie(0);
  pi := tuple.tie<TVector>(0);
  ps := tuple.tie<string>(1);
  pv := tuple.tie<Integer>(2);
end;
*)

{$EndRegion}

{$Region 'TestTSharedRegion'}

procedure TestTSharedRegion.SetUp;
begin
  Meta := SysCtx.CreateMeta<TTestRecord>;
  Region.Init(Meta, 5000);
end;

procedure TestTSharedRegion.TearDown;
begin
  Region.Free;
end;

procedure TestTSharedRegion.TestAlloc;
begin
  Descr.Count := 5;
  Region.Alloc(Descr);
  CheckTrue(Descr.Items <> nil);
  CheckTrue(Descr.Count = 5);
  a := PTestRecord(Descr.Items);
  a.Init(45, 1);
  a.s := 'a';
  b := PTestRecord(PByte(a) + sizeof(TTestRecord));
  b.Init(46, 2);
  b.s := 'b';
  c := PTestRecord(PByte(b) + sizeof(TTestRecord));
  c.Init(47, 3);
  c.s := 'c';
  d := PTestRecord(PByte(c) + sizeof(TTestRecord));
  d.Init(48, 4);
  d.s := 'd';
  e := PTestRecord(PByte(d) + sizeof(TTestRecord));
  e.Init(49, 5);
  e.s := 'e';
end;

procedure TestTSharedRegion.TestFreeMem;
begin
  TestAlloc;
  Region.FreeMem(Descr);
end;

procedure TestTSharedRegion.TestRealloc;
begin
  TestAlloc;
  Region.Realloc(Descr, 20);
  CheckTrue(Descr.Items <> nil);
  CheckTrue(Descr.Count = 20);
end;

{$EndRegion}

{$Region 'TestTsgArray'}

procedure TestTsgArray.SetUp;
begin
  Meta := SysCtx.CreateMeta<TTestRecord>;
  Region.Init(Meta, 5000);
end;

procedure TestTsgArray.TearDown;
begin
  Region.Free;
end;

procedure TestTsgArray.TestSetCount;
var
  List: TsgArray<TTestRecord>;
  i: Integer;
  p: PTestRecord;
begin
  List.Init(@Region, 16);
  for i := 0 to 15 do
  begin
    p := List.Items[i];
    p.Init(i, i + 1);
    p.e.tag := i;
    p.s := IntToStr(i);
  end;
  List.Free;
end;

procedure TestTsgArray.TestAdd;
var
  List: TsgArray<TTestRecord>;
  i, j: Integer;
  a: TTestRecord;
  p: PTestRecord;
begin
  List.Init(@Region, ItemsCount);
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i + 1);
    a.e.tag := i;
    p := List.Add;
    p^ := a;
    CheckTrue(List.Count = Cardinal(i));

    p := List.Items[i - 1];
    CheckTrue(p.v = i);
    CheckTrue(a.Equals(p^));

    for j := 1 to i do
    begin
      a.Init(j, j + 1);
      a.e.tag := j;
      p := List.Items[j - 1];
      CheckTrue(p.v = j);
      CheckTrue(a.Equals(p^));
    end;
  end;
  List.Free;
end;

procedure TestTsgArray.TestDelete;
const
  N = 400;
var
  List1, List2: TsgArray<TTestRecord>;
  i: Integer;
  a: TTestRecord;
  p: PTestRecord;
begin
  List1.Init(@Region, N);
  List2.Init(@Region, N);
  for i := 1 to N do
  begin
    a.Init(i, i + 1);
    a.e.tag := i;

    p := List1.Add;
    p^ := a;
    CheckTrue(List1.Count = Cardinal(i));
    p := List1.Items[i - 1];
    CheckTrue(p.v = i);
    CheckTrue(a.Equals(p^));

    p := List2.Add;
    p^ := a;
    CheckTrue(List2.Count = Cardinal(i));
    p := List2.Items[i - 1];
    CheckTrue(p.v = i);
    CheckTrue(a.Equals(p^));

  end;
end;

procedure TestTsgArray.TestInsert;
var
  List: TsgArray<TTestRecord>;
  i: Integer;
  a: TTestRecord;
  p: PTestRecord;
begin
  List.Init(@Region, ItemsCount);
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i + 1);
    a.e.tag := i;
    p := List.Insert(0);
    p^ := a;
    CheckTrue(List.Count = Cardinal(i));

    p := List.Items[0];
    CheckTrue(p.v = i);
    CheckTrue(a.Equals(p^));
  end;
  List.Free;
end;

procedure TestTsgArray.TestRemove;
begin
end;

procedure TestTsgArray.TestExchange;
begin
end;

procedure TestTsgArray.TestSort;
begin
end;

procedure TestTsgArray.TestReverse;
begin
end;

{$EndRegion}

{$Region 'TestTsgList'}

procedure TestTsgList.SetUp;
begin
  List := TsgList<TTestRecord>.From(64);
end;

procedure TestTsgList.TearDown;
begin
  List.Free;
end;

procedure TestTsgList.TestAdd;
var
  i, j: Integer;
  a, b: TTestRecord;
  p: PTestRecord;
  e: TsgListHelper.TEnumerator;
begin
  for i := 1 to ItemsCount do
  begin
    a.Init(i, i + 1);
    a.e.tag := i;
    List.Add(a);
    CheckTrue(List.Count = i);
    // read and check the content
    b := List.Items[i - 1];
    if b.v <> i then
    CheckTrue(b.v = i);
    if not a.Equals(b) then
    CheckTrue(a.Equals(b));
    // check all previously added values
    for j := 1 to i do
    begin
      a.Init(j, j + 1);
      a.e.tag := j;
      b := List.Items[j - 1];
      if b.v <> j then
      CheckTrue(b.v = j);
      if not a.Equals(b) then
      CheckTrue(a.Equals(b));
    end;
  end;
  i := 0;
  e := List.GetEnumerator;
  while e.MoveNext do
  begin
    p := e.Current;
    Inc(i);
    if (p <> nil) and (p.e.tag <> i) then
    CheckTrue(p.e.tag = i);
  end;
  i := 0;
  for p in List do
  begin
    Inc(i);
    if (p <> nil) and (p.e.tag <> i) then
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
  // todo:
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
const
  Cnt = 200;
var
  Source: TsgList<TTestRecord>;
  v, r, n: TTestRecord;
  p: PTestRecord;
  i, k: Integer;
begin
  k := List.Count;
  CheckTrue(k = 0);
  v.Init(25, 1);
  v.s := '123';
  Source := TsgList<TTestRecord>.From(64);
  try
    Source.Add(v);
    for i := 1 to Cnt do
    begin
      n.Init(i, i * 2);
      n.s := IntToStr(i);
      Source.Add(n);
    end;
    System.CopyRecord(@r, @n, TypeInfo(TTestRecord));
    CheckTrue(r.Equals(n));
    k := List.Count;
    CheckTrue(k = 0);
    List.Assign(Source);
    CheckTrue(List.Count = Cnt + 1);
    p := Source.GetPtr(0);
    CheckTrue(p.s = '123');
    r := List.Items[0];
    CheckTrue(r.Equals(v));
    FinalizeRecord(@r, TypeInfo(TTestRecord));
  finally
    Source.Free;
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
  List.Free;
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
  b := List.Items[0];
  for a in List do
  begin
    if i = 0 then
      CheckTrue(b = a);
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

{$Region 'TsgForwardListTest'}

procedure FreePerson1(ptr: Pointer);
var
  it: TsgForwardList<TPerson>.TIterator;
begin
  it := TsgForwardList<TPerson>.TIterator(ptr);
  it.Value^ := Default(TPerson);
end;

procedure TsgForwardListTest.SetUp;
begin
  List.Init(FreePerson1);
  log.Init;
end;

procedure TsgForwardListTest.TearDown;
begin
  List.Free;
  log.Free;
end;

procedure TsgForwardListTest.DumpList;
var
  it: TsgForwardList<TPerson>.TIterator;
begin
  it := List.Front;
  while not it.Eol do
  begin
    log.print('Person id=', [it.Value.id, ', "', it.Value.name, '"']);
    it.Next;
  end;
end;

procedure TsgForwardListTest._Clear;
var
  p: TPerson;
  i, n: Integer;
begin
  n := sizeof(TsgForwardList<TPerson>.TItem);
  CheckTrue(n = sizeof(TCustomForwardList.TItem) + sizeof(TPerson));
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'p1';
  List.PushFront(p);
  CheckTrue(List.Count = 1);
  p.id := 2;
  p.name := 'p2';
  List.PushFront(p);
  CheckTrue(List.Count = 2);
  p.id := 3;
  p.name := 'p3';
  List.PushFront(p);
  CheckTrue(List.Count = 3);
  List.Clear;
  CheckTrue(List.Count = 0);
  for i := 1 to ItemsCount do
  begin
    p.id := i;
    p.name := 'p' + IntToStr(i);
    List.PushFront(p);
    CheckTrue(List.Count = i);
  end;
end;

procedure TsgForwardListTest._Empty;
var
  p: TPerson;
begin
  CheckTrue(List.Empty);
  p.id := 1;
  p.name := 'Smith';
  List.PushFront(p);
  CheckFalse(List.Empty);
end;

procedure TsgForwardListTest._Count;
var
  p: TPerson;
  i: Integer;
  it: TsgForwardList<TPerson>.TIterator;
  its: array [0..5] of TsgForwardList<TPerson>.TIterator;
  v: PPerson;
  n: Integer;
begin
  n := sizeof(TsgForwardList<TPerson>.TItem);
  CheckTrue(n = sizeof(TCustomForwardList.TItem) + sizeof(TPerson));
  CheckTrue(List.Count = 0);
  p.id := 0;
  p.name := 'Nick';
  it := List.PushFront;
  it.Value^ := p;
  CheckTrue(List.Count = 1);
  its[0] := it;
  for i := 1 to 5 do
  begin
    p.id := i;
    p.name := 'id_' + IntToStr(i);
    it := List.PushFront;
    it.Value^ := p;
    its[i] := it;
    v := it.Value;
    CheckTrue(v.id = p.id);
    CheckTrue(v.name = p.name);
  end;
  CheckTrue(List.Count = 6);
  it := List.Front;
  for i := 5 downto 0 do
  begin
    v := it.Value;
    CheckTrue(v.id = i);
    if i = 0 then
      CheckTrue(v.name = 'Nick')
    else
      CheckTrue(v.name = 'id_' + IntToStr(i));
    it.Next;
  end;
end;

procedure TsgForwardListTest._Front;
var
  it: TsgForwardList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(not it.Eol);
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  CheckTrue(not it.Eol);
end;

procedure TsgForwardListTest._PushFront;
var
  it: TsgForwardList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(not it.Eol);
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

procedure TsgForwardListTest._InsertAfter;
var
  it: TsgForwardList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  it := List.Front;
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  it := List.InsertAfter(it, p);
  CheckTrue(it.Value.id = p.id);
  CheckTrue(it.Value.name = p.name);
end;

procedure TsgForwardListTest._PopFront;
var
  it: TsgForwardList<TPerson>.TIterator;
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

procedure TsgForwardListTest._Reverse;
const
  N = 400;
var
  i: Integer;
  it: TsgForwardList<TPerson>.TIterator;
  p: TPerson;
  pp: PPerson;
  s: string;
begin
  CheckTrue(List.Count = 0);
  for i := 0 to N do
  begin
    p.id := i;
    p.name := IntToStr(i);
    if i = 0 then
      it := List.PushFront
    else
      it := List.InsertAfter(it);
    it.Value^ := p;
    CheckTrue(List.Count = i + 1);
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
end;

procedure TsgForwardListTest._Sort;
const
  N = 800;
var
  i, d: Integer;
  it: TsgForwardList<TPerson>.TIterator;
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
  List.Sort(PersonIdCompare1);
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

procedure TsgForwardListTest._Eol;
const
  N = 500;
var
  i: Integer;
  it: TsgForwardList<TPerson>.TIterator;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  it := List.Front;
  CheckTrue(it.Eol);
  for i := 0 to N do
  begin
    p.id := i;
    p.name := IntToStr(i);
    List.PushFront(p);
  end;
  it := List.Front;
  i := N;
  while not it.Eol do
  begin
    CheckTrue(it.Value.id = i);
    CheckTrue(it.Value.name = IntToStr(i));
    it.Next;
    Dec(i);
  end;
  CheckTrue(i = -1);
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
  i, n: Integer;
begin
  n := sizeof(TsgForwardList<TPerson>.TItem);
  CheckTrue(n = sizeof(TCustomForwardList.TItem) + sizeof(TPerson));
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

{$Region 'TsgHasherTest'}

procedure TsgHasherTest.SetUp;
begin
  inherited;

end;

procedure TsgHasherTest.TearDown;
begin
  inherited;

end;

procedure TsgHasherTest.TestInt32;
var
  hasher: TsgHasher;
  meta: TsgItemMeta;
  a, b, c: Integer;
begin
  meta.Init<Integer>;
  hasher := TsgHasher.From(meta);
  a := 123;
  b := 123;
  c := 456;
  Check(hasher.Equals(@a, @b));
  Check(not hasher.Equals(@a, @c));
  Check(hasher.GetHash(@b) <> 0);
  Check(hasher.GetHash(@c) <> 0);
end;

procedure TsgHasherTest.TestString;
var
  hasher: TsgHasher;
  meta: TsgItemMeta;
  a, b, c: string;
begin
  meta.Init<string>;
  hasher := TsgHasher.From(meta);
  a := '123';
  b := '123';
  Check(hasher.Equals(@a, @b));
  Check(not hasher.Equals(@a, @c));
  Check(hasher.GetHash(@b) <> 0);
  Check(hasher.GetHash(@c) <> 0);
end;

{$EndRegion}

{$Region 'TsgHashMapTest'}

function VectorHash(const Value: PByte): Cardinal;
begin
  Result := PVector(Value)^.Hash;
end;

function VectorEquals(A, B: Pointer): Boolean;
begin
  Result := TVector(A^).Equals(TVector(B^));
end;

var
  VectorHasher: TsgHasher;

procedure TsgHashMapTest.SetUp;
const
  Comparer: TComparer = (
    Equals: VectorEquals;
    Hash: VectorHash);
begin
  VectorHasher := TsgHasher.From(Comparer);
  Map := TsgHashMap<TVector, Integer>.From(300, @VectorHasher, nil);
end;

procedure TsgHashMapTest.TearDown;
begin
  Map.Free;
end;

function TsgHashMapTest.Hash<TKey>(const Key: TKey): Integer;
const
  PositiveMask = not Integer($80000000);
var
  FComparer: IEqualityComparer<TKey>;
begin
  Result := PositiveMask and ((PositiveMask and FComparer.GetHashCode(Key)) + 1);
end;

procedure TsgHashMapTest.GenPair(i: Integer; var pair: TsgPair<TVector, Integer>);
begin
  case i mod 5 of
    0: pair.Key := TVector.From(i, i + 0, 0);
    1: pair.Key := TVector.From(i, i + 1, i);
    2: pair.Key := TVector.From(i, i + 2, i * 2);
    3: pair.Key := TVector.From(i, i + 3, i * 3);
    4: pair.Key := TVector.From(i, i + 4, i * 4);
  end;
  pair.Value := i;
end;

procedure TsgHashMapTest.TestTemporaryPair;
var
  pair, a: TsgHashMap<TVector, Integer>.PPair;
begin
  pair := Map.GetTemporaryPair;
  GenPair(1, pair^);
  a := Map.Insert(pair^);
  CheckTrue(a <> nil);
  CheckTrue(pair.Key.Equals(a.Key));
  CheckTrue(pair.Value = a.Value);
end;

procedure TsgHashMapTest.TestInsert;
var
  i: Integer;
  pair, t, r: TsgPair<TVector, Integer>;
  a, b: TsgHashMap<TVector, Integer>.PPair;
begin
  for i := 0 to 10000 do
  begin
    // insert
    GenPair(i, pair);
    t := pair;
    a := Map.Insert(pair);
    CheckTrue(a <> nil);
    r.Key := a.Key;
    r.Value := a.Value;
    CheckTrue(r.Key.Equals(t.Key));
    CheckTrue(r.Value = i);

    // find
    b := Map.Find(pair.Key);
    CheckTrue(b <> nil);
    r.Key := b.Key;
    r.Value := b.Value;
    CheckTrue(r.Key.Equals(t.Key));
    CheckTrue(r.Value = i);
  end;
end;

procedure TsgHashMapTest.TestInsertOrUpdate;
var
  i: Integer;
  pair, t, r: TsgPair<TVector, Integer>;
  a, b: TsgHashMap<TVector, Integer>.PPair;
begin
  for i := 0 to 100 do
  begin
    // insert
    GenPair(i, pair);
    t := pair;
    a := Map.InsertOrAssign(pair);
    CheckTrue(a <> nil);
    r.Key := a.Key;
    r.Value := a.Value;
    CheckTrue(r.Key.Equals(t.Key));
    CheckTrue(r.Value = i);

    // find
    b := Map.Find(pair.Key);
    CheckTrue(b <> nil);
    r.Key := b.Key;
    r.Value := b.Value;
    CheckTrue(r.Key.Equals(t.Key));
    CheckTrue(r.Value = i);
  end;
  for i := 0 to 100 do
  begin
    // insert
    GenPair(i, pair);
    pair.Value := i + 100;
    t := pair;
    a := Map.InsertOrAssign(pair);
    CheckTrue(a <> nil);
    r.Key := a.Key;
    r.Value := a.Value;
    CheckTrue(r.Key.Equals(t.Key));
    CheckTrue(r.Value = i + 100);
  end;
end;

procedure TsgHashMapTest.TestFind;
var
  i, j: Integer;
  r: TsgHashMap<TVector, Integer>.PPair;
  pair: THashMapPair;
begin
  TestInsert;
  i := 500;
  GenPair(i, pair);
  r := Map.Find(pair.key);
  CheckTrue(r <> nil);
  j := r.Value;
  CheckTrue(i = j);
end;

procedure TsgHashMapTest.TestPairIterator;
var
  i: Integer;
  pair, t, r: THashMapPair;
  a, b, p: TsgHashMap<TVector, Integer>.PPair;
  it: TsgHashMapIterator<TVector, Integer>;
  key: TVector;
  value: Integer;
begin
  for i := 0 to 10000 do
  begin
    GenPair(i, pair);
    t := pair;
    a := Map.Insert(pair);
    CheckTrue(a <> nil);
    r.Key := a.Key;
    r.Value := a.Value;
    CheckTrue(r.Key.Equals(t.Key));
    CheckTrue(r.Value = i);
  end;
  i := 0;
  it := Map.Begins;
  while it <> Map.Ends do
  begin
    p := it.GetPair;
    key := it.GetKey^;
    value := it.GetValue^;
    CheckTrue(key.Equals(p.Key));
    CheckTrue(value = p.Value);
    it.Next;
    Inc(i);
  end;
  CheckTrue(10001 = i);
end;

procedure TsgHashMapTest.TestKeyIterator;
begin
end;

procedure TsgHashMapTest.TestValuesIterator;
begin
end;

{$EndRegion}

{$Region 'TsgMapTest'}

procedure ClearNode(P: Pointer);
var
  Ptr: TsgMapIterator<TPerson, Integer>.PNode;
begin
  Ptr := TsgMapIterator<TPerson, Integer>.PNode(P);
  Ptr.k.Clear;
end;

procedure TsgMapTest.SetUp;
begin
  FMap := TsgMap<TPerson, Integer>.From(PersonCompare, ClearNode);
end;

procedure TsgMapTest.TearDown;
begin
  FMap.Free;
end;

procedure TsgMapTest.TestFind;
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

procedure TsgMapTest.CheckNode(p: TsgMapIterator<TPerson, Integer>.PNode);
var
  r: TMapPair;
begin
  r := p.pair;
  Check(r.Value = nn);
  Inc(nn)
end;

procedure TsgMapTest.TestIterator;
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

{$Region 'TsgSetTest'}

procedure ClearSetNode(P: Pointer);
var
  Ptr: TsgSetIterator<TPerson>.PNode;
begin
  Ptr := TsgSetIterator<TPerson>.PNode(P);
  Ptr.k.Clear;
end;

procedure TsgSetTest.SetUp;
begin
  FSet.Init(PersonCompare, ClearSetNode);
end;

procedure TsgSetTest.TearDown;
begin
  FSet.Free;
end;

procedure TsgSetTest.TestFind;
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

procedure TsgSetTest.CheckSetNode(p: TsgSetIterator<TPerson>.PNode);
var
  r: TPerson;
  id: string;
begin
  r := p.k;
  id := TPerson.GenName(snn);
  Check(r.name = id);
  Inc(snn)
end;

procedure TsgSetTest.TestIterator;
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
  xs := Trunc(FMod(Abs(x) / Eps, Size));
  ys := Trunc(FMod(Abs(y) / Eps, Size));
  zs := Trunc(FMod(Abs(z) / Eps, Size));
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

  RegisterTest(TsgHasherTest.Suite);
  RegisterTest(TsgHashMapTest.Suite);

  RegisterTest(TsgRecordListTest.Suite);
  RegisterTest(TsgMapTest.Suite);
  RegisterTest(TsgSetTest.Suite);

  // Oz.SGL.HandleManager
  RegisterTest(TsgHandleManagerTest.Suite);

  // Oz.SGL.Heap
  RegisterTest(TsgMemoryManagerTest.Suite);
  RegisterTest(TsgItemTest.Suite);
  RegisterTest(THeapPoolTest.Suite);
  RegisterTest(TUnbrokenRegionTest.Suite);
  RegisterTest(TSegmentedRegionTest.Suite);
  RegisterTest(TestTSharedRegion.Suite);
  RegisterTest(TestTsgArray.Suite);
  RegisterTest(TSysCtxTest.Suite);

  // Oz.SGL.Collections
  RegisterTest(TsgTupleMetaTest.Suite);
  RegisterTest(TsgTupleTest.Suite);
  RegisterTest(TsgForwardListTest.Suite);
  RegisterTest(TestTsgList.Suite);
  RegisterTest(TsgLinkedListTest.Suite);

end.

