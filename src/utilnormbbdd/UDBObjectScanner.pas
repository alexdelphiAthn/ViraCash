unit UDBObjectScanner;

{
  Busca ocurrencias de los nombres de columnas viejas en TODO el SQL del dump
  EXCEPTO dentro de los bloques CREATE TABLE (que ya fueron tratados por el
  TViraCashNormalizer principal).

  Encuentra:
   - Ocurrencias en INSERT INTO ... VALUES (...)
   - Ocurrencias en bloques CREATE PROCEDURE/FUNCTION/VIEW/TRIGGER si los hay
   - Ocurrencias en strings de SQL embebido en tablas de migración

  Genera un informe con (línea, contexto, columna_vieja → columna_nueva).
}

interface

uses
  System.Classes, System.SysUtils,
  System.Generics.Collections, System.Generics.Defaults,
  UProjectScanner;  // reusamos TPlanPair

type
  TSQLMatch = record
    LineNumber: Integer;
    LineText:   string;
    ColumnOld:  string;
    ColumnNew:  string;
    Context:    string;  // tipo de contexto: 'INSERT', 'PROCEDURE', 'OTHER'
  end;

  TSQLMatchList = TList<TSQLMatch>;

  TDBObjectScanner = class
  private
    FRenamePlan: TPlanPairList;
    FOnLog:      TProc<string>;
    procedure Log(const S: string);
    function  IsBoundary(C: Char): Boolean;
    function  StripCreateTableBlocks(const SQL: string): string;
    function  DetectContext(const Line: string): string;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure SetRenamePlan(APlan: TPlanPairList);
    procedure Scan(const SQLContent: string; AOutMatches: TSQLMatchList);
    function  BuildReplacementSQL(const SQLContent: string;
                                  out ChangedLines: Integer): string;

    property OnLog: TProc<string> read FOnLog write FOnLog;
  end;

implementation

uses
  System.RegularExpressions, System.StrUtils;

{ TDBObjectScanner }

constructor TDBObjectScanner.Create;
begin
  inherited Create;
  FRenamePlan := TPlanPairList.Create;
end;

destructor TDBObjectScanner.Destroy;
begin
  FRenamePlan.Free;
  inherited;
end;

procedure TDBObjectScanner.Log(const S: string);
begin
  if Assigned(FOnLog) then FOnLog(S);
end;

procedure TDBObjectScanner.SetRenamePlan(APlan: TPlanPairList);
var
  P: TPlanPair;
begin
  FRenamePlan.Clear;
  for P in APlan do
    if P.OldName <> P.NewName then
      FRenamePlan.Add(P);
  // Orden: nombres más largos primero
  FRenamePlan.Sort(TComparer<TPlanPair>.Construct(
    function(const L, R: TPlanPair): Integer
    begin
      Result := Length(R.OldName) - Length(L.OldName);
      if Result = 0 then Result := CompareStr(L.OldName, R.OldName);
    end));
end;

function TDBObjectScanner.IsBoundary(C: Char): Boolean;
begin
  Result := not (CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '_']));
end;

function TDBObjectScanner.StripCreateTableBlocks(const SQL: string): string;
{
  Devuelve el mismo SQL pero con cada bloque CREATE TABLE … ); reemplazado por
  marcadores de longitud equivalente, para preservar números de línea.
  Así, cuando luego buscamos columnas viejas, las que están dentro de un
  CREATE TABLE no las contamos (esas ya las cubre el script de ALTER COLUMN).
}
var
  Pat: TRegEx;
  M:   TMatch;
  SB:  TStringBuilder;
  Idx: Integer;
  Replacement: string;
begin
  Pat := TRegEx.Create('CREATE TABLE `[^`]+` \(.*?^\);',
    [roSingleLine, roMultiLine]);
  SB := TStringBuilder.Create(Length(SQL));
  try
    Idx := 1;
    for M in Pat.Matches(SQL) do
    begin
      // Trozo entre el final del último match y el inicio de éste
      if M.Index > Idx then
        SB.Append(Copy(SQL, Idx, M.Index - Idx));
      // Reemplazo: mismo nº de saltos de línea, pero contenido neutralizado
      Replacement := StringReplace(M.Value, M.Value, '', []);  // vacío
      // Pero conservamos los \n para no romper números de línea
      Replacement := DupeString(#10, Length(M.Value) - Length(StringReplace(M.Value, #10, '', [rfReplaceAll])));
      SB.Append(Replacement);
      Idx := M.Index + M.Length;
    end;
    if Idx <= Length(SQL) then
      SB.Append(Copy(SQL, Idx, Length(SQL) - Idx + 1));
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TDBObjectScanner.DetectContext(const Line: string): string;
var
  L: string;
begin
  L := UpperCase(Line.TrimLeft);
  if L.StartsWith('INSERT INTO') or (Pos('INSERT INTO', L) > 0) then
    Exit('INSERT')
  else if (Pos('CREATE PROCEDURE', L) > 0) or
          (Pos('CREATE FUNCTION', L) > 0) or
          (Pos('CREATE VIEW', L) > 0) or
          (Pos('CREATE TRIGGER', L) > 0) then
    Exit('PROCEDURE')
  else
    Exit('OTHER');
end;

procedure TDBObjectScanner.Scan(const SQLContent: string;
  AOutMatches: TSQLMatchList);
var
  Stripped: string;
  Lines:    TStringList;
  i, iPos:  Integer;
  Line:     string;
  Pair:     TPlanPair;
  Pre, Post: Char;
  M:        TSQLMatch;
  Total:    Integer;
  // Para detectar bloques de procedimiento (cuando el contexto va en líneas anteriores)
  CurrentContext: string;
begin
  AOutMatches.Clear;
  if FRenamePlan.Count = 0 then
  begin
    Log('[WARN] No hay plan de renombrado cargado.');
    Exit;
  end;

  Stripped := StripCreateTableBlocks(SQLContent);
  Lines := TStringList.Create;
  try
    Lines.Text := Stripped;
    Total := 0;
    CurrentContext := 'OTHER';

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];
      // Heurística simple: si la línea contiene marcadores de contexto, los
      // recordamos para las siguientes líneas (hasta encontrar ';').
      if Length(Trim(Line)) > 0 then
      begin
        if (Pos('INSERT INTO', UpperCase(Line)) > 0) then
          CurrentContext := 'INSERT'
        else if (Pos('CREATE PROCEDURE', UpperCase(Line)) > 0) or
                (Pos('CREATE FUNCTION', UpperCase(Line)) > 0) or
                (Pos('CREATE VIEW', UpperCase(Line)) > 0) or
                (Pos('CREATE TRIGGER', UpperCase(Line)) > 0) then
          CurrentContext := 'PROCEDURE';
      end;

      for Pair in FRenamePlan do
      begin
        iPos := 1;
        while iPos > 0 do
        begin
          iPos := PosEx(Pair.OldName, Line, iPos);
          if iPos = 0 then Break;
          if iPos = 1 then Pre := #0 else Pre := Line[iPos - 1];
          if iPos + Length(Pair.OldName) > Length(Line) then Post := #0
          else Post := Line[iPos + Length(Pair.OldName)];

          if ((Pre = #0) or IsBoundary(Pre)) and
             ((Post = #0) or IsBoundary(Post)) then
          begin
            M.LineNumber := i + 1;
            M.LineText   := Line;
            M.ColumnOld  := Pair.OldName;
            M.ColumnNew  := Pair.NewName;
            M.Context    := CurrentContext;
            AOutMatches.Add(M);
            Inc(Total);
          end;
          Inc(iPos, Length(Pair.OldName));
        end;
      end;
    end;
    Log(Format('Búsqueda en SQL completada: %d coincidencias fuera de CREATE TABLE.',
      [Total]));
  finally
    Lines.Free;
  end;
end;

function TDBObjectScanner.BuildReplacementSQL(const SQLContent: string;
  out ChangedLines: Integer): string;
{
  Genera una versión MODIFICADA del SQL de entrada con todos los reemplazos
  aplicados a TODO el contenido (incluyendo dentro de los CREATE TABLE).

  El resultado es un dump completo coherente que se puede importar de cero:
  los CREATE TABLE definirán las columnas con sus nombres nuevos y los INSERT
  INTO referenciarán esas mismas columnas nuevas.
}
var
  Working:  string;
  Pair:     TPlanPair;
  RegexPat: string;
begin
  Working := SQLContent;
  ChangedLines := 0;
  for Pair in FRenamePlan do
  begin
    RegexPat := '(?<![A-Za-z0-9_])' + TRegEx.Escape(Pair.OldName) +
                '(?![A-Za-z0-9_])';
    Inc(ChangedLines, TRegEx.Matches(Working, RegexPat).Count);
    Working := TRegEx.Replace(Working, RegexPat, Pair.NewName);
  end;
  Result := Working;
end;

end.
