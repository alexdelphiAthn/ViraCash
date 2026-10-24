unit uDJMSepa;
{
https://github.com/cocosistemas/Delphi-SEPA-XML-ES
Diego J.Muñoz. Freelance. Cocosistemas.com
}

interface

function uSEPA_CleanStr(sIn:string; iMaxLen : Integer = -1):string;

function uSEPA_GenerateUUID: String;

function uSEPA_FormatDateTimeXML(const d: TDateTime): String;

function uSEPA_FormatAmountXML(const d: Currency; const digits: Integer = 2): String;

function uSEPA_FormatDateXML(const d: TDateTime): String;

procedure uSEPA_writeAccountIdentification(var fTxt:TextFile; sIBAN:string);
procedure uSEPA_writeBICInfo(var fTxt:TextFile; sBIC:string);

implementation
uses SysUtils, Math;

function uSEPA_FormatDateXML(const d: TDateTime): String;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', d);
end;

function uSEPA_FormatAmountXML(const d: Currency; const digits: Integer = 2): String;
var
  OldDecimalSeparator: Char;
  {$if CompilerVersion>22}  //superiores a xe
  FS: TFormatSettings;
  {$ifend}
begin
  {$if CompilerVersion>22}
    FS := TFormatSettings.Create;
    OldDecimalSeparator := FS.DecimalSeparator;
    FS.DecimalSeparator := '.';
    Result := CurrToStrF(d, ffFixed, digits, FS);
  {$else}
    OldDecimalSeparator := DecimalSeparator;
    DecimalSeparator := '.';
    Result := CurrToStrF(d, ffFixed, digits);
  {$ifend}

  {$if CompilerVersion>22}
    FS.DecimalSeparator := OldDecimalSeparator;
  {$else}
    DecimalSeparator := OldDecimalSeparator;
  {$ifend}
end;

function uSEPA_FormatDateTimeXML(const d: TDateTime): String;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', d);
end;

function uSEPA_GenerateUUID: String;
var
  uid: TGuid;
  res: HResult;
begin
  res := CreateGuid(Uid);
  if res = S_OK then
  begin
    Result := GuidToString(uid);
    Result := StringReplace(Result, '-', '', [rfReplaceAll]);
    Result := StringReplace(Result, '{', '', [rfReplaceAll]);
    Result := StringReplace(Result, '}', '', [rfReplaceAll]);
  end
  else
    Result := IntToStr(RandomRange(10000, High(Integer)));  // fallback to simple random number
end;

function uSEPA_NormalizarChar(c: Char): Char;
begin
case Ord(c) of
  $00C0..$00C5:
    Result := 'A';
  $00E0..$00E5:
    Result := 'a';
  $00C8..$00CB:
    Result := 'E';
  $00E8..$00EB:
    Result := 'e';
  $00CC..$00CF:
    Result := 'I';
  $00EC..$00EF:
    Result := 'i';
  $00D2..$00D6, $00D8:
    Result := 'O';
  $00F2..$00F6, $00F8:
    Result := 'o';
  $00D9..$00DC:
    Result := 'U';
  $00F9..$00FC:
    Result := 'u';
  $00D1:
    Result := 'N';
  $00F1:
    Result := 'n';
  $00C7:
    Result := 'C';
  $00E7:
    Result := 'c';
  else
    Result := c;
  end;
end;

function uSEPA_CleanStr(sIn:string; iMaxLen : Integer = -1):string;
var
i    : integer;
sOut : string;
begin
sOut:=sIn;
// Normalizar acentos antes de aplicar el alfabeto SEPA.
for i := 1 to Length(sOut) do
  sOut[i] := uSEPA_NormalizarChar(sOut[i]);

// Recorrer el sOut para eliminar los caracteres no permitidos
for i := 1 to Length(sOut)
do begin
   if not(Ord(sOut[i]) in [65..90,97..122,48..57,47,45,63,58,40,41,46,44,39,43,32])
   then sOut[i] := ' ';
   end;
// Convertir a mayúsculas
//sOut := ansiuppercase(sOut);

// Codificar a Utf8
sOut := string(Utf8Encode(Trim(sOut)));
if (iMaxLen >= 0) and (Length(sOut) > iMaxLen)
then sOut := Copy(sOut, 1, iMaxLen);
Result:=sOut;
end;

procedure uSEPA_writeAccountIdentification;
begin
WriteLn(FTxt, '<Id><IBAN>'+uSEPA_CleanStr(sIBAN)+'</IBAN></Id>');
end;

procedure uSEPA_writeBICInfo;
begin
  if Trim(sBIC) = '' then
  begin
    WriteLn(FTxt, '<FinInstnId><Othr><Id>NOTPROVIDED</Id></Othr></FinInstnId>');
  end
  else
  begin
    WriteLn(FTxt, '<FinInstnId><BIC>'+uSEPA_CleanStr(sBIC)+'</BIC></FinInstnId>');
  end;
end;


end.
