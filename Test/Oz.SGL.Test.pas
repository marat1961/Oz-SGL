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

type

{$Region 'TsgTestRecord'}

  TsgId = record
    v: Cardinal;
  end;

  PsgEntry = ^TsgEntry;
  TsgEntry = record
    tag: Integer;
    h: TsgId;
  end;

  PsgTestRecord = ^TsgTestRecord;
  TsgTestRecord = record
    e: TsgEntry;
    v: Integer;
    s: string;
    procedure Init(v, id: Integer);
    function Equals(const r: TsgTestRecord): Boolean;
  end;

{$EndRegion}

{$Region 'THeapPoolTest'}

  PListNode = ^TListNode;
  TListNode = record
    next: PListNode;
    n: Integer;
  end;

  THeapPoolTest = class(TTestCase)
  const
    ItemsCount = 20000;
  public
    HeapPool: THeapPool;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure _CreateRegion;
    procedure _CreateUnbrokenRegion;
  end;

{$EndRegion}

{$Region 'TsgRecordListTest'}

  TsgRecordListTest = class(TTestCase)
  const
    ItemsCount = 10000;
  public
    List: TsgRecordList<TsgTestRecord>;
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

  PPerson = ^TPerson;
  TPerson = record
    id: Cardinal;
    name: string;
  end;

  TsgLinkedListTest = class(TTestCase)
  const
    ItemsCount = 10000;
  public
    List: TsgLinkedList<TPerson>;
    procedure SetUp; override;
    procedure TearDown; override;
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
    procedure _Next;
    procedure _Prev;
    function _Eol: Boolean;
    function _Bol: Boolean;
  end;

{$EndRegion}

implementation

{$Region 'TsgTestRecord'}

procedure TsgTestRecord.Init(v, id: Integer);
begin
  e.tag := 0;
  e.h.v := id;
  Self.v := v;
end;

function TsgTestRecord.Equals(const r: TsgTestRecord): Boolean;
begin
  Result := (e.tag = r.e.tag) and (e.h.v = r.e.h.v) and (v = r.v);
end;

function TestRecordCompare(Left, Right: Pointer): Integer;
type
  PsgTestRecord = ^TsgTestRecord;
begin
  Result := PsgTestRecord(Left).v - PsgTestRecord(Right).v;
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

{$Region 'TsgRecordListTest'}

procedure TsgRecordListTest.SetUp;
begin
  List := TsgRecordList<TsgTestRecord>.From(nil);
end;

procedure TsgRecordListTest.TearDown;
begin
  List.Clear;
  ClearHeapPool;
end;

procedure TsgRecordListTest._Add0;
var
  i: Integer;
  a, b: PsgTestRecord;
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
end;

procedure TsgRecordListTest._Add;
var
  i, j: Integer;
  a, b: TsgTestRecord;
  p: PsgTestRecord;
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
  r: TsgTestRecord;
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
  a, b, c, d, r: TsgTestRecord;
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
  p, r: PsgTestRecord;
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
  p: PsgTestRecord;
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
  p: PsgTestRecord;
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
  Result := PsgTestRecord(Item1).v - PsgTestRecord(Item2).v;
end;

procedure TsgRecordListTest._Sort;
var
  i: Integer;
  p: PsgTestRecord;
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
  item: TsgLinkedList<TPerson>.PItem;
begin
  item := TsgLinkedList<TPerson>.PItem(ptr);
  item.Value := Default(TPerson);
end;

procedure TsgLinkedListTest.SetUp;
begin
  List.Init(FreePerson);
end;

procedure TsgLinkedListTest.TearDown;
begin
  List.Free;
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
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  CheckTrue(List.Count = 1);
end;

procedure TsgLinkedListTest._Front;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  item := List.Front;
  CheckTrue(item = nil);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
end;

procedure TsgLinkedListTest._Back;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  item := List.Back;
  CheckTrue(item = nil);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  item := List.Back;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushBack(p);
  item := List.Back;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
end;

procedure TsgLinkedListTest._PushFront;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  item := List.Front;
  CheckTrue(item = nil);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
end;

procedure TsgLinkedListTest._PushBack;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  item := List.Front;
  CheckTrue(item = nil);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushBack(p);
  item := List.Back;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushBack(p);
  item := List.Back;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
end;

procedure TsgLinkedListTest._Insert;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  item := List.Front;
  CheckTrue(item = nil);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.Insert(item, p);
  item := List.Back;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
end;

procedure TsgLinkedListTest._PopFront;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  List.PopFront;
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  List.PopFront;
  CheckTrue(List.Count = 2);
  item := List.Front;
  CheckTrue(item.Value.id = 2);
  CheckTrue(item.Value.name = 'Leo');
  List.PopFront;
  CheckTrue(List.Count = 1);
  item := List.Front;
  CheckTrue(item.Value.id = 1);
  CheckTrue(item.Value.name = 'Nick');
  List.PopFront;
  CheckTrue(List.Empty);
end;

procedure TsgLinkedListTest._PopBack;
var
  item: TsgLinkedList<TPerson>.PItem;
  p: TPerson;
begin
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushBack(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  List.PopBack;
  CheckTrue(List.Count = 0);
  p.id := 1;
  p.name := 'Nick';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item <> nil);
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 2;
  p.name := 'Leo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  p.id := 3;
  p.name := 'Neo';
  List.PushFront(p);
  item := List.Front;
  CheckTrue(item.Value.id = p.id);
  CheckTrue(item.Value.name = p.name);
  List.PopBack;
  CheckTrue(List.Count = 2);
  item := List.Back;
  CheckTrue(item.Value.id = 2);
  CheckTrue(item.Value.name = 'Leo');
  List.PopBack;
  CheckTrue(List.Count = 1);
  item := List.Back;
  CheckTrue(item.Value.id = 3);
  CheckTrue(item.Value.name = 'Neo');
  List.PopBack;
  CheckTrue(List.Empty);
end;

procedure TsgLinkedListTest._Reverse;
begin

end;

procedure TsgLinkedListTest._Sort;
begin

end;

procedure TsgLinkedListTest._Next;
begin

end;

procedure TsgLinkedListTest._Prev;
begin

end;

function TsgLinkedListTest._Eol: Boolean;
begin

end;

function TsgLinkedListTest._Bol: Boolean;
begin

end;

{$EndRegion}

initialization

  // Oz.SGL.Heap
  RegisterTest(THeapPoolTest.Suite);
  // Oz.SGL.Collections
  RegisterTest(TsgRecordListTest.Suite);
  RegisterTest(TsgLinkedListTest.Suite);

end.
