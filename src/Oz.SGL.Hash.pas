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
  System.SysUtils, Oz.SGL.Heap;

{$EndRegion}

{$T+}

{$Region 'THashData'}

type

  THashKind = (hkMultiplicative, hkSHA1, hkSHA2, hkSHA5, hkMD5);

  TsgHash  = record
  type
    TUpdateProc = procedure(const key: PByte; Size: Cardinal);
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

implementation

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

end.
