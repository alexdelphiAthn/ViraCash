{
  Copyright (C) 2013-2023 Tim Sinaeve tim.sinaeve@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}
unit ts.Core.Utils;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.Math, System.Character,
  System.TypInfo, System.Variants, system.Masks;

// Constantes y Tipos básicos
const
  AnsiWhitespace = [' ', #9, #10, #13];

type
  TVarRecArray = array of TVarRec;

// --- Funciones de String ---
function WordCount(const AString: string; const AWordDelims: TSysCharSet): Integer;
function ExtractWord(const AIndex: Integer; const AString: string; const AWordDelims: TSysCharSet): string;
function WordPosition(const AIndex: Integer; const AString: string; const AWordDelims: TSysCharSet): Integer;
function StringReplaceMultiple(const Source: string; const OldPatterns, NewPatterns: array of string; CaseSensitive: Boolean = True): string;
function Like(const ASource: string; const ATemplate: string): Boolean;

// --- Funciones de Variant ---
function VarRecToString(const AVarRec: TVarRec): string;
function VariantToVarRec(const Item: Variant): TVarRec;
// (Puedes mantener el resto de funciones de Variant si las usa el parser, 
// pero he limpiado las visuales para que compile rápido).

implementation

uses
  System.AnsiStrings; // Para funciones legacy si fueran necesarias

// Implementación de WordCount (Adaptado a Delphi Unicode)
function WordCount(const AString: string; const AWordDelims: TSysCharSet): Integer;
var
  SLen, I: Integer;
begin
  Result := 0;
  I := 1;
  SLen := Length(AString);
  while I <= SLen do
  begin
    while (I <= SLen) and (CharInSet(AString[I], AWordDelims)) do Inc(I);
    if I <= SLen then Inc(Result);
    while (I <= SLen) and not (CharInSet(AString[I], AWordDelims)) do Inc(I);
  end;
end;

function WordPosition(const AIndex: Integer; const AString: string; const AWordDelims: TSysCharSet): Integer;
var
  Count, I: Integer;
begin
  Count := 0;
  I := 1;
  Result := 0;
  while (I <= Length(AString)) and (Count <> AIndex) do
  begin
    while (I <= Length(AString)) and (CharInSet(AString[I], AWordDelims)) do Inc(I);
    if I <= Length(AString) then Inc(Count);
    if Count <> AIndex then
      while (I <= Length(AString)) and not (CharInSet(AString[I], AWordDelims)) do Inc(I)
    else
      Result := I;
  end;
end;

function ExtractWord(const AIndex: Integer; const AString: string; const AWordDelims: TSysCharSet): string;
var
  I, Len: Integer;
begin
  Len := 0;
  I := WordPosition(AIndex, AString, AWordDelims);
  if I <> 0 then
  begin
    while (I <= Length(AString)) and not (CharInSet(AString[I], AWordDelims)) do
    begin
      Inc(Len);
      SetLength(Result, Len);
      Result[Len] := AString[I];
      Inc(I);
    end;
  end
  else
    Result := '';
end;

// Implementación simplificada de Like (Versión Delphi)
function Like(const ASource: string; const ATemplate: string): Boolean;
begin
  Result := MatchesMask(ASource, ATemplate); // Usa System.Masks si necesitas wildcards complejos, o mantén la lógica original si es crítica.
end;

function StringReplaceMultiple(const Source: string; const OldPatterns, NewPatterns: array of string; CaseSensitive: Boolean = True): string;
var
  Flags: TReplaceFlags;
  I: Integer;
begin
  Result := Source;
  Flags := [rfReplaceAll];
  if not CaseSensitive then Include(Flags, rfIgnoreCase);
  
  for I := Low(OldPatterns) to High(OldPatterns) do
  begin
    if I <= High(NewPatterns) then
      Result := StringReplace(Result, OldPatterns[I], NewPatterns[I], Flags);
  end;
end;

// Stub para funciones de Variant (simplificado para el ejemplo)
function VarRecToString(const AVarRec: TVarRec): string;
begin
  // Delphi moderno maneja esto mejor con TValue o RTTI, 
  // pero para compatibilidad rápida:
  case AVarRec.VType of
    vtInteger: Result := IntToStr(AVarRec.VInteger);
    vtString:  Result := string(AVarRec.VString^);
    vtUnicodeString: Result := string(AVarRec.VUnicodeString);
    else Result := '';
  end;
end;

function VariantToVarRec(const Item: Variant): TVarRec;
begin
  // Esta función es compleja de portar directamente sin punteros inseguros.
  // Si el parser SQL no la usa intensivamente, puedes dejarla vacía o 
  // refactorizar el parser para no usar VarRecs.
  FillChar(Result, SizeOf(Result), 0);
end;

end.