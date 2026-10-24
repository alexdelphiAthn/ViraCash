unit UFR3SQLDumpPatcher;

{
  Parcheador OFFLINE de reports FastReport (.fr3) almacenados como BLOB
  dentro de un dump SQL generado por el Backup Engine de ViraCash.

  Tabla:    fza_usuarios_perfiles
  PK:       (USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER)
  Columna:  VALUE_BLOB_USUPER  (XML plano UTF-8, NO comprimido)

  Filtro de filas:  KEY_USUPER IN ('frmPrintFac','frmPrintRecFac').

  -------------------------------------------------------------------------
  Formato esperado del dump (Providers_MySQL_Helpers.ValueToSQL)
  -------------------------------------------------------------------------
   - Identificadores con backticks: `tabla`, `columna`
   - Strings con QuotedStr y escape solo de '\' como '\\'  (no \n, \r, \t)
   - BLOBs SIEMPRE como literal hex: 0x3C3F786D6C...
   - Modo "una INSERT por fila"   o
     modo extended  INSERT INTO `t` (cols) VALUES (...),(...),... ;

  Ambos modos están soportados: el parser localiza cabecera y trocea
  filas (...) respetando literales y paréntesis dentro de strings.

  -------------------------------------------------------------------------
  Pipeline
  -------------------------------------------------------------------------
   1) Parsear cabecera del INSERT y resolver índices de las 4 columnas
      relevantes:  USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER,
                   VALUE_BLOB_USUPER
      Si VALUE_BLOB_USUPER no aparece en la lista de columnas, se omite
      el statement.
   2) Trocear cada VALUES (...) y, si KEY_USUPER pasa el filtro:
         - Decodificar el hex 0x... -> bytes
         - Decodificar bytes UTF-8 -> string
         - Aplicar plan de renombrado con CaseAwareReplace
         - Re-codificar UTF-8 -> bytes -> hex
         - Sustituir SOLO el campo del BLOB en la fila
   3) Re-emitir el statement reconstruido al archivo de salida.
   4) El archivo de entrada NUNCA se modifica.
}

interface

uses
  System.Classes, System.SysUtils, System.IOUtils,
  System.RegularExpressions, System.Generics.Collections,
  UProjectScanner;  // TPlanPair, TPlanPairList y CaseAwareReplace

type
  TFR3DumpRowFix = record
    UsuarioGrupo: string;
    KeyName:     string;
    SubKey:      string;
    BytesBefore: Integer;
    BytesAfter:  Integer;
    Replacements: Integer;
    EncodingHex: Boolean;
    ErrorMsg:    string;
  end;

  TFR3DumpRowFixList = TList<TFR3DumpRowFix>;

  TInsertHeader = record
    HeaderText:    string;
    Columns:       TArray<string>;
    GroupIndex:    Integer;
    KeyIndex:      Integer;
    SubKeyIndex:   Integer;
    BlobIndex:     Integer;
    Valid:         Boolean;
  end;

  TFR3DumpPatcher = class
  private
    FPlan:        TPlanPairList;
    FOnLog:       TProc<string>;
    FKeyFilter:   TStringList;
    FRowsTotal:   Integer;
    FRowsChanged: Integer;
    FRowsErr:     Integer;
    FFixes:       TFR3DumpRowFixList;

    procedure Log(const S: string);

    function  ParseInsertHeader(const Stmt: string;
                                out HeaderEndPos: Integer): TInsertHeader;
    function  ProcessInsertStatement(const Stmt: string): string;
    function  ProcessOneRow(const RowText: string;
                            const Header: TInsertHeader): string;

    function  ApplyPlanToText(const AText: string;
                              out ATotalReplacements: Integer): string;

    function  HexLiteralToBytes(const HexLit: string): TBytes;
    function  BytesToHexLiteral(const Buf: TBytes): string;

    function  ReadFileWithEncoding(const FileName: string;
                                   out Encoding: TEncoding;
                                   out HasBOM: Boolean): string;
    procedure WriteFileWithEncoding(const FileName, Content: string;
                                    Encoding: TEncoding; HasBOM: Boolean);
  public
    constructor Create;
    destructor  Destroy; override;

    procedure SetRenamePlan(APlan: TPlanPairList);
    procedure SetKeyFilter(const KeysCsv: string);

    {
      Procesa el archivo de entrada y escribe el resultado en el archivo
      de salida. NO toca el archivo de entrada.
      Si OutputFile coincide con InputFile, lanza excepción.
      Devuelve True si la salida tiene cambios respecto a la entrada.
    }
    function ProcessDumpFile(const InputFile, OutputFile: string;
                             AOutFixes: TFR3DumpRowFixList = nil): Boolean;

    property OnLog: TProc<string> read FOnLog write FOnLog;
  end;

implementation

uses
  System.Math, System.StrUtils;

{ TFR3DumpPatcher }

constructor TFR3DumpPatcher.Create;
begin
  inherited Create;
  FKeyFilter := TStringList.Create;
  FKeyFilter.CaseSensitive := False;
  FKeyFilter.Sorted        := True;
  FKeyFilter.Duplicates    := dupIgnore;
  SetKeyFilter('frmPrintFac,frmPrintRecFac');
end;

destructor TFR3DumpPatcher.Destroy;
begin
  FKeyFilter.Free;
  inherited;
end;

procedure TFR3DumpPatcher.Log(const S: string);
begin
  if Assigned(FOnLog) then FOnLog(S);
end;

procedure TFR3DumpPatcher.SetRenamePlan(APlan: TPlanPairList);
begin
  FPlan := APlan;
end;

procedure TFR3DumpPatcher.SetKeyFilter(const KeysCsv: string);
var
  S: string;
  Parts: TArray<string>;
  i: Integer;
begin
  FKeyFilter.Clear;
  Parts := KeysCsv.Split([',']);
  for i := 0 to High(Parts) do
  begin
    S := Trim(Parts[i]);
    if S <> '' then
      FKeyFilter.Add(S);
  end;
end;

{ ======================================================================
  Codificación hex
  ====================================================================== }

function TFR3DumpPatcher.HexLiteralToBytes(const HexLit: string): TBytes;
var
  Hex: string;
  i, n: Integer;
begin
  Hex := Trim(HexLit);
  if Hex.StartsWith('0x', True) then
    Hex := Copy(Hex, 3, MaxInt)
  else if (Length(Hex) >= 3) and (Hex[1] in ['x','X']) and
          (Hex[2] = '''') and (Hex[Length(Hex)] = '''') then
    Hex := Copy(Hex, 3, Length(Hex) - 3);

  if (Length(Hex) mod 2) <> 0 then
    raise Exception.Create('Literal hex con longitud impar: ' +
      Copy(HexLit, 1, 30) + '...');

  n := Length(Hex) div 2;
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := StrToInt('$' + Copy(Hex, i * 2 + 1, 2));
end;

function TFR3DumpPatcher.BytesToHexLiteral(const Buf: TBytes): string;
const
  Digits: array[0..15] of Char = '0123456789ABCDEF';
var
  SB: TStringBuilder;
  i: Integer;
  B: Byte;
begin
  SB := TStringBuilder.Create(Length(Buf) * 2 + 2);
  try
    SB.Append('0x');
    for i := 0 to High(Buf) do
    begin
      B := Buf[i];
      SB.Append(Digits[B shr 4]);
      SB.Append(Digits[B and $F]);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

{ ======================================================================
  Plan de renombrado
  ====================================================================== }

function TFR3DumpPatcher.ApplyPlanToText(const AText: string;
  out ATotalReplacements: Integer): string;
var
  Pair: TPlanPair;
  PartialCount: Integer;
begin
  Result := AText;
  ATotalReplacements := 0;

  if FPlan = nil then Exit;

  for Pair in FPlan do
  begin
    Result := CaseAwareReplace(Result, Pair.OldName, Pair.NewName, PartialCount);
    Inc(ATotalReplacements, PartialCount);
  end;
end;

{ ======================================================================
  ParseInsertHeader
  ====================================================================== }

function TFR3DumpPatcher.ParseInsertHeader(const Stmt: string;
  out HeaderEndPos: Integer): TInsertHeader;
var
  L, Pos_, ParenStart, ParenEnd, ValuesPos, Depth: Integer;
  C: Char;
  Quoted, Esc: Boolean;
  Cols, Col: string;
  Parts: TArray<string>;
  i: Integer;

  function StripBackticks(const S: string): string;
  begin
    Result := Trim(S);
    if (Length(Result) >= 2) and (Result[1] = '`') and
       (Result[Length(Result)] = '`') then
      Result := Copy(Result, 2, Length(Result) - 2);
  end;

begin
  FillChar(Result, SizeOf(Result), 0);
  Result.GroupIndex  := -1;
  Result.KeyIndex    := -1;
  Result.SubKeyIndex := -1;
  Result.BlobIndex   := -1;
  HeaderEndPos       := -1;

  L := Length(Stmt);

  // Buscar el primer '(' fuera de literal
  Pos_   := 1;
  Quoted := False;
  Esc    := False;
  ParenStart := -1;
  while Pos_ <= L do
  begin
    C := Stmt[Pos_];
    if Esc then Esc := False
    else if Quoted then
    begin
      if C = '\' then Esc := True
      else if C = '''' then
      begin
        if (Pos_ < L) and (Stmt[Pos_ + 1] = '''') then
          Inc(Pos_)
        else
          Quoted := False;
      end;
    end
    else
    begin
      if C = '''' then Quoted := True
      else if C = '(' then
      begin
        ParenStart := Pos_;
        Break;
      end;
    end;
    Inc(Pos_);
  end;

  if ParenStart < 0 then Exit;

  // Buscar el ')' que cierra esta apertura
  Pos_     := ParenStart + 1;
  Quoted   := False;
  Esc      := False;
  ParenEnd := -1;
  Depth    := 1;
  while Pos_ <= L do
  begin
    C := Stmt[Pos_];
    if Esc then Esc := False
    else if Quoted then
    begin
      if C = '\' then Esc := True
      else if C = '''' then
      begin
        if (Pos_ < L) and (Stmt[Pos_ + 1] = '''') then
          Inc(Pos_)
        else
          Quoted := False;
      end;
    end
    else
    begin
      if C = '''' then Quoted := True
      else if C = '(' then Inc(Depth)
      else if C = ')' then
      begin
        Dec(Depth);
        if Depth = 0 then
        begin
          ParenEnd := Pos_;
          Break;
        end;
      end;
    end;
    Inc(Pos_);
  end;

  if ParenEnd < 0 then Exit;

  Cols := Trim(Copy(Stmt, ParenStart + 1, ParenEnd - ParenStart - 1));
  Parts := Cols.Split([',']);
  SetLength(Result.Columns, Length(Parts));
  for i := 0 to High(Parts) do
  begin
    Col := StripBackticks(Parts[i]);
    Result.Columns[i] := Col;
    if SameText(Col, 'USUARIO_GRUPO_USUPER') then Result.GroupIndex  := i
    else if SameText(Col, 'KEY_USUPER')        then Result.KeyIndex    := i
    else if SameText(Col, 'SUBKEY_USUPER')     then Result.SubKeyIndex := i
    else if SameText(Col, 'VALUE_BLOB_USUPER') then Result.BlobIndex   := i;
  end;

  Result.Valid :=
    (Result.GroupIndex  >= 0) and
    (Result.KeyIndex    >= 0) and
    (Result.SubKeyIndex >= 0) and
    (Result.BlobIndex   >= 0);

  // Saltar "VALUES" (case-insensitive) tras el ')'
  Pos_   := ParenEnd + 1;
  Quoted := False;
  Esc    := False;
  ValuesPos := -1;
  while Pos_ <= L - 5 do
  begin
    C := Stmt[Pos_];
    if Esc then Esc := False
    else if Quoted then
    begin
      if C = '\' then Esc := True
      else if C = '''' then Quoted := False;
    end
    else
    begin
      if C = '''' then Quoted := True
      else if (UpCase(C) = 'V') and
              (CompareText(Copy(Stmt, Pos_, 6), 'VALUES') = 0) then
      begin
        ValuesPos := Pos_;
        Break;
      end;
    end;
    Inc(Pos_);
  end;

  if ValuesPos < 0 then
  begin
    Result.Valid := False;
    Exit;
  end;

  Result.HeaderText := Trim(Copy(Stmt, 1, ValuesPos + 5));
  HeaderEndPos      := ValuesPos + 6;
end;

{ ======================================================================
  ProcessOneRow
  ====================================================================== }

function TFR3DumpPatcher.ProcessOneRow(const RowText: string;
  const Header: TInsertHeader): string;
var
  S: string;
  Pos_, L, FieldStart: Integer;
  C: Char;
  Fields: TArray<string>;
  Quoted, Esc: Boolean;

  procedure AddField(AStart, AEnd: Integer);
  var
    F: string;
  begin
    F := Trim(Copy(S, AStart, AEnd - AStart + 1));
    SetLength(Fields, Length(Fields) + 1);
    Fields[High(Fields)] := F;
  end;

  function StripSqlQuotes(const Q: string): string;
  begin
    if (Length(Q) >= 2) and (Q[1] = '''') and (Q[Length(Q)] = '''') then
      Result := Copy(Q, 2, Length(Q) - 2)
    else
      Result := Q;
  end;

  function MysqlUnescapeSimple(const S2: string): string;
  // Tu Backup Engine usa QuotedStr (que dobla comillas como '') y solo
  // escapa '\' como '\\'. No usa \n, \r, \t. El unescape es solo eso.
  var
    SB: TStringBuilder;
    i, LL: Integer;
    Ch: Char;
  begin
    SB := TStringBuilder.Create(Length(S2));
    try
      i := 1; LL := Length(S2);
      while i <= LL do
      begin
        Ch := S2[i];
        if (Ch = '''') and (i < LL) and (S2[i + 1] = '''') then
        begin
          SB.Append('''');
          Inc(i, 2);
        end
        else if (Ch = '\') and (i < LL) and (S2[i + 1] = '\') then
        begin
          SB.Append('\');
          Inc(i, 2);
        end
        else
        begin
          SB.Append(Ch);
          Inc(i);
        end;
      end;
      Result := SB.ToString;
    finally
      SB.Free;
    end;
  end;

var
  PK1, PK2, PK3: string;
  KeyClean: string;
  BlobRaw: string;
  BlobBytes: TBytes;
  XmlText: string;
  NewXml: string;
  Replacements: Integer;
  NewBlobLit: string;
  NewRow: string;
  Fix: TFR3DumpRowFix;
begin
  Result := RowText;
  S := RowText;
  L := Length(S);

  if (L < 2) or (S[1] <> '(') or (S[L] <> ')') then Exit;

  Pos_       := 2;
  FieldStart := 2;
  Quoted     := False;
  Esc        := False;
  Fields     := nil;

  while Pos_ <= L - 1 do
  begin
    C := S[Pos_];

    if Esc then
      Esc := False
    else if Quoted then
    begin
      if C = '\' then
        Esc := True
      else if C = '''' then
      begin
        if (Pos_ < L - 1) and (S[Pos_ + 1] = '''') then
          Inc(Pos_)
        else
          Quoted := False;
      end;
    end
    else
    begin
      if C = '''' then
        Quoted := True
      else if C = ',' then
      begin
        AddField(FieldStart, Pos_ - 1);
        FieldStart := Pos_ + 1;
      end;
    end;

    Inc(Pos_);
  end;
  AddField(FieldStart, L - 1);

  if Length(Fields) <> Length(Header.Columns) then
  begin
    Log(Format('  [WARN] Fila con %d campos para %d columnas; se omite.',
      [Length(Fields), Length(Header.Columns)]));
    Exit;
  end;

  PK1 := MysqlUnescapeSimple(StripSqlQuotes(Fields[Header.GroupIndex]));
  PK2 := MysqlUnescapeSimple(StripSqlQuotes(Fields[Header.KeyIndex]));
  PK3 := MysqlUnescapeSimple(StripSqlQuotes(Fields[Header.SubKeyIndex]));

  KeyClean := PK2;
  if (FKeyFilter.Count > 0) and (FKeyFilter.IndexOf(KeyClean) < 0) then
    Exit;

  Inc(FRowsTotal);

  BlobRaw := Fields[Header.BlobIndex];

  if SameText(BlobRaw, 'NULL') or (BlobRaw = '') then Exit;

  if not (BlobRaw.StartsWith('0x', True) or BlobRaw.StartsWith('X''', True)
         or BlobRaw.StartsWith('x''', True)) then
  begin
    Log(Format('  [%s/%s/%s] BLOB no está en formato hex. NO se toca.',
      [PK1, PK2, PK3]));
    Exit;
  end;

  try
    BlobBytes := HexLiteralToBytes(BlobRaw);

    if (Length(BlobBytes) < 5) or (BlobBytes[0] <> $3C) then
    begin
      Log(Format('  [%s/%s/%s] BLOB no parece XML (primer byte 0x%s). NO se toca.',
        [PK1, PK2, PK3, IntToHex(BlobBytes[0], 2)]));
      Exit;
    end;

    XmlText := TEncoding.UTF8.GetString(BlobBytes);
    NewXml  := ApplyPlanToText(XmlText, Replacements);

    FillChar(Fix, SizeOf(Fix), 0);
    Fix.UsuarioGrupo := PK1;
    Fix.KeyName      := PK2;
    Fix.SubKey       := PK3;
    Fix.BytesBefore  := Length(BlobBytes);
    Fix.EncodingHex  := True;

    if Replacements = 0 then
    begin
      Fix.BytesAfter := Fix.BytesBefore;
      if FFixes <> nil then FFixes.Add(Fix);
      Log(Format('  [%s/%s/%s] sin cambios', [PK1, PK2, PK3]));
      Exit;
    end;

    BlobBytes  := TEncoding.UTF8.GetBytes(NewXml);
    NewBlobLit := BytesToHexLiteral(BlobBytes);

    Fix.BytesAfter   := Length(BlobBytes);
    Fix.Replacements := Replacements;
    if FFixes <> nil then FFixes.Add(Fix);

    Inc(FRowsChanged);
    Log(Format('  [%s/%s/%s] %d reemplazos  %d->%d bytes',
      [PK1, PK2, PK3, Replacements, Fix.BytesBefore, Fix.BytesAfter]));

    Fields[Header.BlobIndex] := NewBlobLit;
    NewRow := '(' + String.Join(',', Fields) + ')';
    Result := NewRow;
  except
    on E: Exception do
    begin
      Inc(FRowsErr);
      Fix.ErrorMsg := E.Message;
      if FFixes <> nil then FFixes.Add(Fix);
      Log(Format('[ERROR] [%s/%s/%s]: %s', [PK1, PK2, PK3, E.Message]));
    end;
  end;
end;

{ ======================================================================
  ProcessInsertStatement
  ====================================================================== }

function TFR3DumpPatcher.ProcessInsertStatement(const Stmt: string): string;
var
  Header: TInsertHeader;
  HeaderEndPos: Integer;
  Body: string;
  Pos_, L, RowStart, ParenDepth, LastRowEnd: Integer;
  C: Char;
  Quoted, Esc: Boolean;
  Rows: TArray<string>;
  Tails: TArray<string>;
  i: Integer;
  Row, NewRow: string;
  RowsBuilder: TStringBuilder;
  FoundChange: Boolean;
  StmtTail: string;
begin
  Result := Stmt;

  Header := ParseInsertHeader(Stmt, HeaderEndPos);
  if not Header.Valid then Exit;

  Body := Copy(Stmt, HeaderEndPos, MaxInt);
  L := Length(Body);

  Pos_       := 1;
  Quoted     := False;
  Esc        := False;
  ParenDepth := 0;
  RowStart   := -1;
  Rows       := nil;
  Tails      := nil;
  LastRowEnd := 0;

  while Pos_ <= L do
  begin
    C := Body[Pos_];

    if Esc then Esc := False
    else if Quoted then
    begin
      if C = '\' then Esc := True
      else if C = '''' then
      begin
        if (Pos_ < L) and (Body[Pos_ + 1] = '''') then
          Inc(Pos_)
        else
          Quoted := False;
      end;
    end
    else
    begin
      if C = '''' then Quoted := True
      else if C = '(' then
      begin
        if ParenDepth = 0 then RowStart := Pos_;
        Inc(ParenDepth);
      end
      else if C = ')' then
      begin
        Dec(ParenDepth);
        if (ParenDepth = 0) and (RowStart > 0) then
        begin
          if Length(Rows) = 0 then
          begin
            SetLength(Tails, 1);
            Tails[0] := Copy(Body, 1, RowStart - 1);
          end
          else
          begin
            SetLength(Tails, Length(Tails) + 1);
            Tails[High(Tails)] := Copy(Body, LastRowEnd + 1,
                                       RowStart - LastRowEnd - 1);
          end;
          SetLength(Rows, Length(Rows) + 1);
          Rows[High(Rows)] := Copy(Body, RowStart, Pos_ - RowStart + 1);
          LastRowEnd := Pos_;
        end;
      end;
    end;
    Inc(Pos_);
  end;

  if Length(Rows) = 0 then Exit;

  StmtTail := Copy(Body, LastRowEnd + 1, MaxInt);

  FoundChange := False;
  for i := 0 to High(Rows) do
  begin
    Row := Rows[i];
    NewRow := ProcessOneRow(Row, Header);
    if NewRow <> Row then
    begin
      Rows[i] := NewRow;
      FoundChange := True;
    end;
  end;

  if not FoundChange then Exit;

  RowsBuilder := TStringBuilder.Create(Length(Stmt) + 64);
  try
    RowsBuilder.Append(Header.HeaderText);
    for i := 0 to High(Rows) do
    begin
      RowsBuilder.Append(Tails[i]);
      RowsBuilder.Append(Rows[i]);
    end;
    RowsBuilder.Append(StmtTail);
    Result := RowsBuilder.ToString;
  finally
    RowsBuilder.Free;
  end;
end;

{ ======================================================================
  Lectura/escritura
  ====================================================================== }

function TFR3DumpPatcher.ReadFileWithEncoding(const FileName: string;
  out Encoding: TEncoding; out HasBOM: Boolean): string;
var
  Bytes: TBytes;
  BOMSize: Integer;
begin
  Bytes := TFile.ReadAllBytes(FileName);
  HasBOM   := False;
  BOMSize  := 0;
  Encoding := nil;

  if (Length(Bytes) >= 3) and
     (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
  begin
    Encoding := TEncoding.UTF8; HasBOM := True; BOMSize := 3;
  end
  else if (Length(Bytes) >= 2) and (Bytes[0] = $FF) and (Bytes[1] = $FE) then
  begin
    Encoding := TEncoding.Unicode; HasBOM := True; BOMSize := 2;
  end
  else if (Length(Bytes) >= 2) and (Bytes[0] = $FE) and (Bytes[1] = $FF) then
  begin
    Encoding := TEncoding.BigEndianUnicode; HasBOM := True; BOMSize := 2;
  end
  else
    Encoding := TEncoding.UTF8;

  if HasBOM then
    Result := Encoding.GetString(Bytes, BOMSize, Length(Bytes) - BOMSize)
  else
    Result := Encoding.GetString(Bytes);
end;

procedure TFR3DumpPatcher.WriteFileWithEncoding(const FileName, Content: string;
  Encoding: TEncoding; HasBOM: Boolean);
var
  Bytes, Preamble, NewBuf: TBytes;
begin
  Bytes := Encoding.GetBytes(Content);
  if HasBOM then
  begin
    Preamble := Encoding.GetPreamble;
    if Length(Preamble) > 0 then
    begin
      SetLength(NewBuf, Length(Preamble) + Length(Bytes));
      Move(Preamble[0], NewBuf[0], Length(Preamble));
      if Length(Bytes) > 0 then
        Move(Bytes[0], NewBuf[Length(Preamble)], Length(Bytes));
      Bytes := NewBuf;
    end;
  end;
  TFile.WriteAllBytes(FileName, Bytes);
end;

{ ======================================================================
  ProcessDumpFile
  ====================================================================== }

function TFR3DumpPatcher.ProcessDumpFile(const InputFile, OutputFile: string;
  AOutFixes: TFR3DumpRowFixList): Boolean;
var
  Source, Modified: string;
  Encoding: TEncoding;
  HasBOM:   Boolean;
  Re:       TRegEx;
  Mt:       TMatch;
  SB:       TStringBuilder;
  LastEnd, StmtStart, StmtEnd, Pos_, L, ParenDepth: Integer;
  Quoted, Esc: Boolean;
  C: Char;
  Stmt, NewStmt: string;
const
  PATTERN = 'INSERT\s+INTO\s+`?fza_usuarios_perfiles`?\s';
begin
  Result := False;

  if SameFileName(InputFile, OutputFile) then
    raise Exception.Create('OutputFile no puede ser igual a InputFile.');

  if FPlan = nil then
  begin
    Log('[ERROR] No hay plan de renombrado cargado.');
    Exit;
  end;

  if not FileExists(InputFile) then
  begin
    Log(Format('[ERROR] No existe %s', [InputFile]));
    Exit;
  end;

  FFixes       := AOutFixes;
  if FFixes <> nil then FFixes.Clear;
  FRowsTotal   := 0;
  FRowsChanged := 0;
  FRowsErr     := 0;

  Log(Format('Leyendo %s ...', [InputFile]));
  Source := ReadFileWithEncoding(InputFile, Encoding, HasBOM);
  Log(Format('Tamaño: %d caracteres. Encoding: %s. BOM: %s.',
    [Length(Source), Encoding.EncodingName, BoolToStr(HasBOM, True)]));

  Re := TRegEx.Create(PATTERN, [roIgnoreCase]);
  SB := TStringBuilder.Create(Length(Source));
  try
    LastEnd := 1;
    Mt := Re.Match(Source);
    while Mt.Success do
    begin
      StmtStart := Mt.Index;
      SB.Append(Copy(Source, LastEnd, StmtStart - LastEnd));

      Pos_       := StmtStart;
      L          := Length(Source);
      Quoted     := False;
      Esc        := False;
      ParenDepth := 0;
      StmtEnd    := -1;
      while Pos_ <= L do
      begin
        C := Source[Pos_];
        if Esc then Esc := False
        else if Quoted then
        begin
          if C = '\' then Esc := True
          else if C = '''' then
          begin
            if (Pos_ < L) and (Source[Pos_ + 1] = '''') then
              Inc(Pos_)
            else
              Quoted := False;
          end;
        end
        else
        begin
          if C = '''' then Quoted := True
          else if C = '(' then Inc(ParenDepth)
          else if C = ')' then Dec(ParenDepth)
          else if (C = ';') and (ParenDepth = 0) then
          begin
            StmtEnd := Pos_;
            Break;
          end;
        end;
        Inc(Pos_);
      end;

      if StmtEnd < 0 then
      begin
        Log('[ERROR] INSERT sin '';''. Abortando.');
        SB.Append(Copy(Source, StmtStart, MaxInt));
        LastEnd := L + 1;
        Break;
      end;

      Stmt := Copy(Source, StmtStart, StmtEnd - StmtStart + 1);
      Log(Format('INSERT INTO fza_usuarios_perfiles (longitud %d)', [Length(Stmt)]));
      NewStmt := ProcessInsertStatement(Stmt);
      if NewStmt <> Stmt then Result := True;
      SB.Append(NewStmt);
      LastEnd := StmtEnd + 1;

      Mt := Re.Match(Source, LastEnd);
    end;

    SB.Append(Copy(Source, LastEnd, MaxInt));
    Modified := SB.ToString;
  finally
    SB.Free;
  end;

  Log(Format('Resumen: %d filas procesadas, %d con cambios, %d errores.',
    [FRowsTotal, FRowsChanged, FRowsErr]));

  // Siempre escribimos el archivo de salida (con o sin cambios) para
  // que el usuario tenga un dump consistente que importar.
  WriteFileWithEncoding(OutputFile, Modified, Encoding, HasBOM);
  Log(Format('Escrito: %s', [OutputFile]));
end;

end.
