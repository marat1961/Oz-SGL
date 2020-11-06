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

unit Oz.SGL.HandleManager;

interface

{$Region 'Uses'}

uses
  System.SysUtils, System.Math;

{$EndRegion}

{$T+}

{$Region 'TsgHandle: Handle uniquely identify some other part of data'}

type

  TsgHandle = record
  private
    v: Cardinal;
  public
    constructor From(index, counter, typ: Cardinal);
    // The index field.
    function Index: Cardinal; inline;
    // The counter field.
    function Counter: Cardinal; inline;
    // The type field.
    function Typ: Cardinal; inline;
  end;

{$EndRegion}

{$Region 'TsgHandleManager: Handle uniquely identify some other part of data'}

  TsgHandleManager = class
  const
    MaxEntries = 4096; // 2^12
  type
    // A pointer to the data and a other bookkeeping fields
    TsgHandleEntry = record
    private
      v: Cardinal;
      function GetActive: Boolean;
      function GetCounter: Cardinal;
      function GetEndOfList: Boolean;
      function GetNextFreeIndex: Cardinal;
      procedure Setactive(const Value: Boolean);
      procedure Setcounter(const Value: Cardinal);
      procedure SetendOfList(const Value: Boolean);
      procedure SetnextFreeIndex(const Value: Cardinal);
    public
      entry: Pointer;
      constructor From(nextFreeIndex: Cardinal);
      procedure Init;
      property nextFreeIndex: Cardinal read GetnextFreeIndex write SetNextFreeIndex;
      property counter: Cardinal read GetCounter write SetCounter;
      property active: Boolean read GetActive write SetActive;
      property endOfList: Boolean read GetEndOfList write SetEndOfList;
     end;
  private
    FEntries: array [0 .. MaxEntries - 1] of TsgHandleEntry;
    FActiveEntryCount: Integer;
    FFirstFreeEntry: Cardinal;
  public
    constructor Create;
    procedure Reset;
    function Add(p: Pointer; typ: Cardinal): TsgHandle;
    procedure Update(handle: TsgHandle; p: Pointer);
    procedure Remove(handle: TsgHandle);
    function Get(handle: TsgHandle): Pointer; overload;
    function Get(handle: TsgHandle; var obj): Boolean; overload;
    function GetAs<T>(handle: TsgHandle; var obj: T): Boolean;
    function GetCount: Integer;
  end;

{$EndRegion}

implementation

{$Region 'TsgHandle'}

constructor TsgHandle.From(index, counter, typ: Cardinal);
begin
  v := (typ shl 26) or (counter shl 14) or index;
end;

function TsgHandle.Index: Cardinal;
begin
  Result := v and $3FFF;
end;

function TsgHandle.Counter: Cardinal;
begin
  Result := (v shr 14) and $FFF;
end;

function TsgHandle.Typ: Cardinal;
begin
  Result := (v shr 26) and $3F;
end;

{$EndRegion}

{$Region 'TsgHandleManager.TsgHandleEntry'}

constructor TsgHandleManager.TsgHandleEntry.From(nextFreeIndex: Cardinal);
begin

end;

procedure TsgHandleManager.TsgHandleEntry.Init;
begin
  endOfList := True;
end;

function TsgHandleManager.TsgHandleEntry.GetActive: Boolean;
begin

end;

function TsgHandleManager.TsgHandleEntry.GetCounter: Cardinal;
begin

end;

function TsgHandleManager.TsgHandleEntry.GetEndOfList: Boolean;
begin

end;

function TsgHandleManager.TsgHandleEntry.GetNextFreeIndex: Cardinal;
begin

end;

procedure TsgHandleManager.TsgHandleEntry.Setactive(const Value: Boolean);
begin

end;

procedure TsgHandleManager.TsgHandleEntry.Setcounter(const Value: Cardinal);
begin

end;

procedure TsgHandleManager.TsgHandleEntry.SetendOfList(const Value: Boolean);
begin

end;

procedure TsgHandleManager.TsgHandleEntry.SetnextFreeIndex(
  const Value: Cardinal);
begin

end;

{$EndRegion}

{$Region 'TsgHandleManager'}

constructor TsgHandleManager.Create;
begin
  Reset;
end;

procedure TsgHandleManager.Reset;
var
  i: Integer;
begin
  FActiveEntryCount := 0;
  FFirstFreeEntry := 0;
  for i := 0 to MaxEntries - 1 do
    FEntries[i] := TsgHandleEntry.From(i + 1);
  FEntries[MaxEntries - 1].Init;
end;

function TsgHandleManager.Add(p: Pointer; typ: Cardinal): TsgHandle;
begin

end;

function TsgHandleManager.Get(handle: TsgHandle): Pointer;
begin

end;

function TsgHandleManager.Get(handle: TsgHandle; var obj): Boolean;
begin

end;

function TsgHandleManager.GetAs<T>(handle: TsgHandle; var obj: T): Boolean;
begin

end;

function TsgHandleManager.GetCount: Integer;
begin

end;

procedure TsgHandleManager.Remove(handle: TsgHandle);
begin

end;

procedure TsgHandleManager.Update(handle: TsgHandle; p: Pointer);
begin

end;

{$EndRegion}

end.

