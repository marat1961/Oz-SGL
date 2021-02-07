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

unit Oz.SGL.Hash;

interface

{$Region 'Uses'}

uses
  System.SysUtils, System.TypInfo, Oz.SGL.Heap;

{$EndRegion}

{$T+}

{$Region 'THashData'}

type

  THashKind = (hkMultiplicative, hkSHA1, hkSHA2, hkSHA5, hkMD5);

  TsgHash  = record
  type
    TUpdateProc = procedure(const key: PByte; Size: Cardinal);
    THashProc = function(const key: PByte; Size: Cardinal): Cardinal;
  private
    FDigest: Cardinal;
    FUpdate: TUpdateProc;
    FHash: THashProc;
  public
    class function From(kind: THashKind): TsgHash; static;
    procedure Reset(kind: THashKind);

    class function HashMultiplicative(const key: PByte; Size: Cardinal): Cardinal; static;
    class function ELFHash(const digest: Cardinal; const key: PByte;
      const Size: Integer): Cardinal; static;

    // Update the Hash with the provided bytes
    procedure Update(const key; Size: Cardinal); overload;
    procedure Update(const key: TBytes; Size: Cardinal = 0); overload; inline;
    procedure Update(const key: string); overload; inline;
    // Hash function
    property Hash: THashProc read FHash;
  end;

{$EndRegion}

{$Region 'TsgHasher: GetHash and Equals operation'}

  PsgHasher = ^TsgHasher;
  TsgHasher = record
  private
    FComparer: Pointer;
  public
    class function From(m: TsgItemMeta): TsgHasher; static;
    function Equals(a, b: Pointer): Boolean;
    function GetHash(k: Pointer): Integer;
  end;

{$EndRegion}

implementation

type
  TPS1 = string[1];
  TPS2 = string[2];
  TPS3 = string[3];

  TInfoFlags = set of (ifVariableSize, ifSelector);
  PTabInfo = ^TTabInfo;
  TTabInfo = record
    Flags: TInfoFlags;
    Data: Pointer;
  end;

  PComparer = ^TComparer;
  TComparer = record
    Equals: TEqualsFunc;
    Hash: THashProc;
  end;
  TSelectProc = function(info: PTypeInfo; size: Integer): PComparer;

function EqualsByte(a, b: Pointer): Boolean;
begin

end;

function EqualsInt16(a, b: Pointer): Boolean;
begin

end;

function EqualsInt32(a, b: Pointer): Boolean;
begin

end;

function EqualsInt64(a, b: Pointer): Boolean;
begin

end;

function EqualsSingle(a, b: Pointer): Boolean;
begin

end;

function EqualsDouble(a, b: Pointer): Boolean;
begin

end;

function EqualsCurrency(a, b: Pointer): Boolean;
begin

end;

function EqualsExtended(a, b: Pointer): Boolean;
begin

end;

function EqualsString(a, b: Pointer): Boolean;
begin

end;


function HashByte(const key: PByte): Cardinal;
begin

end;

function HashInt16(const key: PByte): Cardinal;
begin

end;

function HashInt32(const key: PByte): Cardinal;
begin

end;

function HashInt64(const key: PByte): Cardinal;
begin

end;

function HashSingle(const key: PByte): Cardinal;
begin

end;

function HashDouble(const key: PByte): Cardinal;
begin

end;

function HashExtended(const key: PByte): Cardinal;
begin

end;

function HashCurrency(const key: PByte): Cardinal;
begin

end;

function HashString(const key: PByte): Cardinal;
begin

end;

const
  // Integer
  EntryByte: TComparer = (Equals: EqualsByte; Hash: HashByte);
  EntryInt16: TComparer = (Equals: EqualsInt16; Hash: HashInt16);
  EntryInt32: TComparer = (Equals: EqualsInt32; Hash: HashInt32);
  EntryInt64: TComparer = (Equals: EqualsInt64; Hash: HashInt64);
  // Real
  EntryR4: TComparer = (Equals: EqualsSingle; Hash: HashSingle);
  EntryR8: TComparer = (Equals: EqualsDouble; Hash: HashDouble);
  EntryR10: TComparer = (Equals: EqualsExtended; Hash: HashExtended);
  EntryRC8: TComparer = (Equals: EqualsCurrency; Hash: HashCurrency);
  // String
  EntryString: TComparer = (Equals: EqualsString; Hash: HashString);

  EntryClass: TComparer = (Equals: nil; Hash: nil);
  EntryMethod: TComparer = (Equals: nil; Hash: nil);
  EntryLString: TComparer = (Equals: nil; Hash: nil);
  EntryWString: TComparer = (Equals: nil; Hash: nil);
  EntryVariant: TComparer = (Equals: nil; Hash: nil);
  EntryRecord: TComparer = (Equals: nil; Hash: nil);
  EntryPointer: TComparer = (Equals: nil; Hash: nil);
  EntryI8: TComparer = (Equals: nil; Hash: nil);
  EntryUString: TComparer = (Equals: nil; Hash: nil);

function SelectBinary(info: PTypeInfo; size: Integer): PComparer;
begin
  case size of
    1: Result := @EntryByte;
    2: Result := @EntryInt16;
    4: Result := @EntryInt32;
    8: Result := @EntryInt64;
    else
    begin
      System.Error(reRangeError);
      exit(nil);
    end;
  end;
end;

function SelectInteger(info: PTypeInfo; size: Integer): PComparer;
begin
  case GetTypeData(info)^.OrdType of
    otSByte, otUByte: Result := @EntryByte;
    otSWord, otUWord: Result := @EntryInt16;
    otSLong, otULong: Result := @EntryInt32;
  else
    System.Error(reRangeError);
    exit(nil);
  end;
end;

function SelectFloat(info: PTypeInfo; size: Integer): PComparer;
begin
  case GetTypeData(info)^.FloatType of
    ftSingle: Result := @EntryR4;
    ftDouble: Result := @EntryR8;
    ftExtended: Result := @EntryR10;
    ftCurr: Result := @EntryRC8;
  else
    System.Error(reRangeError);
    exit(nil);
  end;
end;

function SelectDynArray(info: PTypeInfo; size: Integer): PComparer;
begin
end;

const
  VTab: array [TTypeKind] of TTabInfo = (
    // tkUnknown
    (Flags: [ifSelector]; Data: @SelectBinary),
    // tkInteger
    (Flags: [ifSelector]; Data: @SelectInteger),
    // tkChar
    (Flags: [ifSelector]; Data: @SelectBinary),
    // tkEnumeration
    (Flags: [ifSelector]; Data: @SelectInteger),
    // tkFloat
    (Flags: [ifSelector]; Data: @SelectFloat),
    // tkString
    (Flags: []; Data: @EntryString),
    // tkSet
    (Flags: [ifSelector]; Data: @SelectBinary),
    // tkClass
    (Flags: []; Data: @EntryClass),
    // tkMethod
    (Flags: []; Data: @EntryMethod),
    // tkWChar
    (Flags: [ifSelector]; Data: @SelectBinary),
    // tkLString
    (Flags: []; Data: @EntryLString),
    // tkWString
    (Flags: []; Data: @EntryWString),
    // tkVariant
    (Flags: []; Data: @EntryVariant),
    // tkArray
    (Flags: [ifSelector]; Data: @SelectBinary),
    // tkRecord
    (Flags: [ifSelector]; Data: @EntryRecord),
    // tkInterface
    (Flags: []; Data: @EntryPointer),
    // tkInt64
    (Flags: []; Data: @EntryI8),
    // tkDynArray
    (Flags: [ifSelector]; Data: @SelectDynArray),
    // tkUString
    (Flags: []; Data: @EntryUString),
    // tkClassRef
    (Flags: []; Data: @EntryPointer),
    // tkPointer
    (Flags: []; Data: @EntryPointer),
    // tkProcedure
    (Flags: []; Data: @EntryPointer),
    // tkMRecord
    (Flags: [ifSelector]; Data: @EntryRecord));

{$Region 'TsgHash'}

class function TsgHash.From(kind: THashKind): TsgHash;
begin
  Result.Reset(kind);
end;

procedure TsgHash.Reset(kind: THashKind);
begin
  case kind of
    THashKind.hkMultiplicative:
      begin
        FHash := TsgHash.HashMultiplicative;
      end;
  end;
end;

procedure TsgHash.Update(const key; Size: Cardinal);
begin
  FUpdate(PByte(@key), Size);
end;

procedure TsgHash.Update(const key: TBytes; Size: Cardinal);
var
  L: Cardinal;
begin
  L := Size;
  if L = 0 then
    L := Length(key);
  FUpdate(PByte(key), L);
end;

procedure TsgHash.Update(const key: string);
begin
  Update(TEncoding.UTF8.GetBytes(key));
end;

class function TsgHash.HashMultiplicative(const key: PByte;
  Size: Cardinal): Cardinal;
var
  i, hash: Cardinal;
  p: PByte;
begin
  hash := 5381;
  p := key;
  for i := 1 to Size do
  begin
    hash := 33 * hash + p^;
    Inc(p);
  end;
  Result := hash;
end;

class function TsgHash.ELFHash(const digest: Cardinal; const key: PByte;
  const Size: Integer): Cardinal;
var
  i: Integer;
  p: PByte;
  t: Cardinal;
begin
  Result := digest;
  p := key;
  for i := 1 to Size do
  begin
    Result := (Result shl 4) + p^;
    Inc(p);
    t := Result and $F0000000;
    if t <> 0 then
      Result := Result xor (t shr 24);
    Result := Result and (not t);
  end;
end;

{$EndRegion}

{$Region 'TsgHasher'}

class function TsgHasher.From(m: TsgItemMeta): TsgHasher;
var
  pio: PTabInfo;
begin
  if m.TypeInfo = nil then
    raise EsgError.Create('Invalid parameter');
  pio := @VTab[PTypeInfo(m.TypeInfo)^.Kind];
  if ifSelector in pio^.Flags then
    Result.FComparer := TSelectProc(pio^.Data)(m.TypeInfo, m.ItemSize)
  else if pio^.Data <> nil then
    Result.FComparer := PComparer(pio^.Data)
  else
    raise EsgError.Create('TsgHasher: Type is not supported');
end;

function TsgHasher.Equals(a, b: Pointer): Boolean;
begin
  Result := PComparer(FComparer).Equals(a, b);
end;

function TsgHasher.GetHash(k: Pointer): Integer;
begin
  Result := PComparer(FComparer).Hash(k);
end;

{$EndRegion}

end.

