{******************************************************************************}
{                                                                              }
{  Módulo:       UFmt80                                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Motor de reformateo de código Pascal a 80 columnas. Expone una única      }
{    función `ReformatearPas` que toma un fichero .pas y devuelve la lista     }
{    de líneas resultante.                                                     }
{                                                                              }
{    Reglas aplicadas (la primera que reduce la línea a ≤80 col gana):         }
{      1. Línea entera `// comentario` -> reflujo en varias líneas //          }
{      2. Comentario `// ...` al final de línea de código -> mover encima      }
{      3. Lista que termina en ',' o ';' (uses, params, ids) -> partir en      }
{         comas                                                                }
{      4. Llamada/declaración con paréntesis -> alinear args bajo el '('       }
{      5. String literal larga -> partir en espacios concatenando con ' +'     }
{                                                                              }
{    Compilable con Delphi (UnicodeString) y FPC `{$mode Delphi}{$H+}`         }
{    (AnsiString). El cálculo de anchura cuenta caracteres UTF-8, no bytes.    }
{******************************************************************************}

unit UFmt80;

{$IFDEF FPC}
  {$mode Delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

const
  ANCHO_MAX = 80;

type
  TTokKind = (tkCode, tkString, tkLComment, tkBComment, tkDirective);

  TToken = record
    Kind            : TTokKind;
    BStart, BEnd    : Integer;  // índices 1-based, BEnd inclusivo
  end;

  TTokens  = array of TToken;
  TIntArr  = array of Integer;

  TParenCand = record
    A, C, P: Integer;  // apertura, cierre (-1 si abierto), profundidad
  end;
  TParenCands = array of TParenCand;

{ Cuenta caracteres UTF-8 (no bytes) }
function AnchoVisible(const S: AnsiString): Integer;

{ Devuelve la indentación inicial (espacios + tabs) }
function ObtenerIndentacion(const Linea: AnsiString): AnsiString;

{ Tokenizador para una sola línea }
function Tokenizar(const Linea: AnsiString): TTokens;

{ Reformatea una sola línea. Si Result.Count > 1, hubo wrap;
  si Result.Count = 1 con el mismo texto, no se pudo o no hace falta. }
function ReformatearLinea(const Linea: AnsiString): TStringList;

{ Reformatea un fichero entero. ALineas se modifica in-place. Devuelve el
  número de líneas que fueron transformadas. }
function ReformatearLineas(ALineas: TStringList): Integer;

{ Lee fichero, detecta BOM y EOL, llama a ReformatearLineas, reescribe.
  Devuelve (NumCambios, NumPendientesQueSiguenPasadas80). }
procedure ReformatearPas(const ARutaFichero: AnsiString;
                         out ACambios, APendientes: Integer;
                         ASoloSimulacion: Boolean = False);

implementation

uses
  StrUtils;

{ ============================================================================ }
{  Utilidades                                                                  }
{ ============================================================================ }

function AnchoVisible(const S: AnsiString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    if (Byte(S[i]) and $C0) <> $80 then
      Inc(Result);
end;


function ObtenerIndentacion(const Linea: AnsiString): AnsiString;
var
  i: Integer;
begin
  i := 1;
  while (i <= Length(Linea)) and ((Linea[i] = ' ') or (Linea[i] = #9)) do
    Inc(i);
  Result := Copy(Linea, 1, i - 1);
end;


function TerminaEn(const S, Suffix: AnsiString): Boolean;
begin
  Result := (Length(Suffix) <= Length(S))
        and (Copy(S, Length(S) - Length(Suffix) + 1, Length(Suffix)) = Suffix);
end;


function TrimDerecha(const S: AnsiString): AnsiString;
var
  i: Integer;
begin
  i := Length(S);
  while (i > 0) and ((S[i] = ' ') or (S[i] = #9)) do
    Dec(i);
  Result := Copy(S, 1, i);
end;


{ ============================================================================ }
{  Tokenizador                                                                 }
{ ============================================================================ }

function Tokenizar(const Linea: AnsiString): TTokens;
var
  i, j, n, codigoInicio: Integer;

  procedure DescargarCodigo(FinEn: Integer);
  begin
    if codigoInicio > 0 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].Kind   := tkCode;
      Result[High(Result)].BStart := codigoInicio;
      Result[High(Result)].BEnd   := FinEn;
      codigoInicio := 0;
    end;
  end;

  procedure AnadirTok(K: TTokKind; A, B: Integer);
  begin
    DescargarCodigo(A - 1);
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Kind   := K;
    Result[High(Result)].BStart := A;
    Result[High(Result)].BEnd   := B;
  end;

begin
  Result       := nil;
  codigoInicio := 0;
  n := Length(Linea);
  i := 1;
  while i <= n do
  begin
    if Linea[i] = '''' then
    begin
      j := i + 1;
      while j <= n do
      begin
        if Linea[j] = '''' then
        begin
          if (j < n) and (Linea[j + 1] = '''') then
            Inc(j, 2)
          else
          begin
            Inc(j);
            Break;
          end;
        end
        else
          Inc(j);
      end;
      AnadirTok(tkString, i, j - 1);
      i := j;
      Continue;
    end;

    if (Linea[i] = '/') and (i < n) and (Linea[i + 1] = '/') then
    begin
      AnadirTok(tkLComment, i, n);
      i := n + 1;
      Continue;
    end;

    if Linea[i] = '{' then
    begin
      j := PosEx('}', Linea, i + 1);
      if j = 0 then
        j := n;
      if (i < n) and (Linea[i + 1] = '$') then
        AnadirTok(tkDirective, i, j)
      else
        AnadirTok(tkBComment, i, j);
      i := j + 1;
      Continue;
    end;

    if (Linea[i] = '(') and (i < n) and (Linea[i + 1] = '*') then
    begin
      j := PosEx('*)', Linea, i + 2);
      if j = 0 then
        j := n - 1;
      AnadirTok(tkBComment, i, j + 1);
      i := j + 2;
      Continue;
    end;

    if codigoInicio = 0 then
      codigoInicio := i;
    Inc(i);
  end;
  DescargarCodigo(n);
end;


{ Devuelve un array de posiciones (1-based) de las comas a profundidad cero
  (fuera de strings, paréntesis, corchetes y comentarios). Si AIncluyePyC
  vale True, también las ';' top-level (útil para parámetros de función). }
function SeparadoresNivelCero(const S: AnsiString;
                              AIncluyePyC: Boolean): TIntArr;
var
  i, n, profP, profB: Integer;
  enStr: Boolean;
  j: Integer;
begin
  Result := nil;
  n := Length(S);
  i := 1;
  enStr := False;
  profP := 0;
  profB := 0;
  while i <= n do
  begin
    if enStr then
    begin
      if S[i] = '''' then
      begin
        if (i < n) and (S[i + 1] = '''') then
        begin
          Inc(i, 2);
          Continue;
        end;
        enStr := False;
      end;
      Inc(i);
      Continue;
    end;
    if S[i] = '''' then begin enStr := True; Inc(i); Continue; end;
    if (S[i] = '/') and (i < n) and (S[i + 1] = '/') then Break;
    if S[i] = '{' then
    begin
      j := PosEx('}', S, i + 1);
      if j = 0 then i := n + 1 else i := j + 1;
      Continue;
    end;
    if (S[i] = '(') and (i < n) and (S[i + 1] = '*') then
    begin
      j := PosEx('*)', S, i + 2);
      if j = 0 then i := n + 1 else i := j + 2;
      Continue;
    end;
    case S[i] of
      '(': Inc(profP);
      ')': Dec(profP);
      '[': Inc(profB);
      ']': Dec(profB);
      ',':
        if (profP = 0) and (profB = 0) then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := i;
        end;
      ';':
        if AIncluyePyC and (profP = 0) and (profB = 0) then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := i;
        end;
    end;
    Inc(i);
  end;
end;


function ComasNivelCero(const S: AnsiString): TIntArr;
begin
  Result := SeparadoresNivelCero(S, False);
end;


{ ============================================================================ }
{  Regla 1: línea entera // ... -> reflujo                                     }
{ ============================================================================ }

function WrapComentarioLinea(const Linea: AnsiString): TStringList;
var
  indent, body, prefijo, espacio, cur, cand: AnsiString;
  texto, palabra: AnsiString;
  partes: TStringList;
  i: Integer;
  disponible: Integer;
  cabecera: AnsiString;
begin
  Result := nil;
  indent := ObtenerIndentacion(Linea);
  body   := Copy(Linea, Length(indent) + 1, MaxInt);
  if Copy(body, 1, 2) <> '//' then Exit;
  prefijo := '//';
  texto := Copy(body, 3, MaxInt);
  espacio := '';
  if (Length(texto) > 0) and (texto[1] = ' ') then
  begin
    espacio := ' ';
    Delete(texto, 1, 1);
  end;
  cabecera := indent + prefijo + espacio;
  disponible := ANCHO_MAX - AnchoVisible(cabecera);
  if disponible < 20 then Exit;

  partes := TStringList.Create;
  partes.StrictDelimiter := True;
  partes.Delimiter := ' ';
  partes.DelimitedText := texto;
  // partes ahora contiene las palabras

  Result := TStringList.Create;
  cur := '';
  for i := 0 to partes.Count - 1 do
  begin
    palabra := AnsiString(partes[i]);
    if palabra = '' then Continue;
    if cur = '' then cand := palabra else cand := cur + ' ' + palabra;
    if AnchoVisible(cand) <= disponible then
      cur := cand
    else
    begin
      if cur <> '' then Result.Add(string(cabecera + cur));
      if AnchoVisible(palabra) > disponible then
      begin
        Result.Add(string(cabecera + palabra));
        cur := '';
      end
      else
        cur := palabra;
    end;
  end;
  if cur <> '' then Result.Add(string(cabecera + cur));
  partes.Free;

  // Si todas las líneas caben, vale; si no, anular
  for i := 0 to Result.Count - 1 do
    if AnchoVisible(AnsiString(Result[i])) > ANCHO_MAX then
    begin
      Result.Free;
      Result := nil;
      Exit;
    end;
end;


{ ============================================================================ }
{  Regla 2: separar comentario inline al final                                 }
{ ============================================================================ }

function WrapDespegarComentarioInline(const Linea: AnsiString): TStringList;
var
  toks: TTokens;
  i, comentInicio: Integer;
  tieneCodigo: Boolean;
  codePart, commentPart, indent: AnsiString;
  sub: TStringList;
begin
  Result := nil;
  toks := Tokenizar(Linea);
  if Length(toks) < 2 then Exit;
  if toks[High(toks)].Kind <> tkLComment then Exit;
  tieneCodigo := False;
  for i := 0 to High(toks) - 1 do
    if (toks[i].Kind = tkCode)
       and (Trim(Copy(Linea, toks[i].BStart,
                      toks[i].BEnd - toks[i].BStart + 1)) <> '') then
    begin
      tieneCodigo := True;
      Break;
    end;
  if not tieneCodigo then Exit;
  comentInicio := toks[High(toks)].BStart;
  codePart    := TrimDerecha(Copy(Linea, 1, comentInicio - 1));
  commentPart := Copy(Linea, comentInicio, MaxInt);
  indent      := ObtenerIndentacion(Linea);

  // Si el comentario solo es excesivo, intentamos reflujo + dejar code
  if AnchoVisible(indent + Trim(commentPart)) > ANCHO_MAX then
  begin
    sub := WrapComentarioLinea(indent + Trim(commentPart));
    if Assigned(sub) then
    begin
      Result := sub;
      Result.Add(string(codePart));
      Exit;
    end;
    Exit;
  end;
  // El comentario cabe; lo separamos. La parte de código quizá siga >80,
  // pero el orquestador recursa para repararla.
  Result := TStringList.Create;
  Result.Add(string(indent + Trim(commentPart)));
  Result.Add(string(codePart));
end;


{ ============================================================================ }
{  Regla 3: listas (uses, params, ids) terminadas en ',' o ';'                 }
{ ============================================================================ }

function ProbarWrapListaComas(const Linea: AnsiString;
                              const AComas: TIntArr): TStringList;
var
  indent: AnsiString;
  cortes: TIntArr;
  start, limite, mejor: Integer;
  i, prev, cut: Integer;
  seg, resto: AnsiString;
  bodyLen, indentLen: Integer;
begin
  Result := nil;
  if Length(AComas) = 0 then Exit;

  indent := ObtenerIndentacion(Linea);
  indentLen := AnchoVisible(indent);
  if indentLen = 0 then Exit;

  SetLength(cortes, 0);
  start := Length(indent) + 1;
  while True do
  begin
    bodyLen := ANCHO_MAX - indentLen;
    limite := start + bodyLen - 1;
    mejor := -1;
    for i := 0 to High(AComas) do
      if (AComas[i] > start) and (AComas[i] <= limite) then
        if AComas[i] > mejor then mejor := AComas[i];
    if mejor < 0 then Exit;
    SetLength(cortes, Length(cortes) + 1);
    cortes[High(cortes)] := mejor;
    if mejor = AComas[High(AComas)] then Break;
    start := mejor + 1;
    while (start <= Length(Linea)) and (Linea[start] = ' ') do Inc(start);
  end;

  Result := TStringList.Create;
  prev := 1;
  for i := 0 to High(cortes) do
  begin
    cut := cortes[i];
    seg := TrimDerecha(Copy(Linea, prev, cut - prev + 1));
    if prev = 1 then
      Result.Add(string(seg))
    else
      Result.Add(string(indent + TrimLeft(seg)));
    prev := cut + 1;
    while (prev <= Length(Linea)) and (Linea[prev] = ' ') do Inc(prev);
  end;
  resto := TrimDerecha(Copy(Linea, prev, MaxInt));
  if resto <> '' then
    Result.Add(string(indent + TrimLeft(resto)));

  for i := 0 to Result.Count - 1 do
    if AnchoVisible(AnsiString(Result[i])) > ANCHO_MAX then
    begin
      Result.Free;
      Result := nil;
      Exit;
    end;
end;


function WrapListaConComas(const Linea: AnsiString): TStringList;
var
  comas: TIntArr;
begin
  Result := nil;
  if (Length(Linea) = 0) or
     ((Linea[Length(Linea)] <> ',') and (Linea[Length(Linea)] <> ';')) then
    Exit;
  if Linea[Length(Linea)] = ';' then
    comas := SeparadoresNivelCero(Linea, True)
  else
    comas := SeparadoresNivelCero(Linea, False);
  Result := ProbarWrapListaComas(Linea, comas);
end;


function WrapComasGeneral(const Linea: AnsiString): TStringList;
{ Acepta cualquier línea con comas top-level (independientemente de cómo
  termine). Útil para líneas de continuación con comas. }
var
  comas: TIntArr;
begin
  comas := SeparadoresNivelCero(Linea, False);
  Result := ProbarWrapListaComas(Linea, comas);
end;


{ ============================================================================ }
{  Regla 4: paréntesis - alinear args bajo el '('                              }
{ ============================================================================ }

procedure ParenAbiertosMejores(const Linea: AnsiString;
                                out PosAbre, PosCierra: Integer);
var
  i, n: Integer;
  enStr: Boolean;
  prof: Integer;
  pila: TIntArr;
  candidatos: TParenCands;
  j, k: Integer;
  mejor, mejorIdx: Integer;
  inner: AnsiString;
  cmsLocal: TIntArr;
begin
  PosAbre := -1; PosCierra := -1;
  n := Length(Linea); i := 1; enStr := False; prof := 0;
  SetLength(pila, 0); SetLength(candidatos, 0);
  while i <= n do
  begin
    if enStr then
    begin
      if Linea[i] = '''' then
      begin
        if (i < n) and (Linea[i + 1] = '''') then
        begin
          Inc(i, 2);
          Continue;
        end;
        enStr := False;
      end;
      Inc(i); Continue;
    end;
    if Linea[i] = '''' then begin enStr := True; Inc(i); Continue; end;
    if (Linea[i] = '/') and (i < n) and (Linea[i + 1] = '/') then Break;
    if Linea[i] = '{' then
    begin
      j := PosEx('}', Linea, i + 1);
      if j = 0 then i := n + 1 else i := j + 1;
      Continue;
    end;
    if (Linea[i] = '(') and (i < n) and (Linea[i + 1] = '*') then
    begin
      j := PosEx('*)', Linea, i + 2);
      if j = 0 then i := n + 1 else i := j + 2;
      Continue;
    end;
    if Linea[i] = '(' then
    begin
      SetLength(pila, Length(pila) + 1);
      pila[High(pila)] := i;
      Inc(prof);
    end
    else if Linea[i] = ')' then
    begin
      if Length(pila) > 0 then
      begin
        SetLength(candidatos, Length(candidatos) + 1);
        candidatos[High(candidatos)].A := pila[High(pila)];
        candidatos[High(candidatos)].C := i;
        candidatos[High(candidatos)].P := prof;
        SetLength(pila, Length(pila) - 1);
      end;
      Dec(prof);
    end;
    Inc(i);
  end;
  // si quedan paréntesis abiertos sin cerrar, también son candidatos
  for k := 0 to High(pila) do
  begin
    SetLength(candidatos, Length(candidatos) + 1);
    candidatos[High(candidatos)].A := pila[k];
    candidatos[High(candidatos)].C := -1;
    candidatos[High(candidatos)].P := 1;
  end;

  // preferimos el de menor profundidad cuyo interior tenga comas top-level
  mejor := MaxInt; mejorIdx := -1;
  for k := 0 to High(candidatos) do
    if candidatos[k].P < mejor then
    begin
      if candidatos[k].C > 0 then
        inner := Copy(Linea, candidatos[k].A + 1,
                      candidatos[k].C - candidatos[k].A - 1)
      else
        inner := Copy(Linea, candidatos[k].A + 1, MaxInt);
      cmsLocal := SeparadoresNivelCero(inner, True);
      if Length(cmsLocal) > 0 then
      begin
        mejor := candidatos[k].P;
        mejorIdx := k;
      end;
    end;
  if (mejorIdx < 0) and (Length(candidatos) > 0) then
    mejorIdx := 0;
  if mejorIdx >= 0 then
  begin
    PosAbre := candidatos[mejorIdx].A;
    PosCierra := candidatos[mejorIdx].C;
  end;
end;


function ProbarWrapParen(const Linea: AnsiString;
                         AlineadoCol: Integer): TStringList;
var
  posA, posC: Integer;
  indent, head, body, tail, primera, cand, cont: AnsiString;
  comas: TIntArr;
  partes: TStringList;
  prev, i, c: Integer;
  ult: AnsiString;
begin
  Result := nil;
  ParenAbiertosMejores(Linea, posA, posC);
  if posA < 0 then Exit;
  indent := ObtenerIndentacion(Linea);

  head := Copy(Linea, 1, posA);
  if posC > 0 then
  begin
    body := Copy(Linea, posA + 1, posC - posA - 1);
    tail := Copy(Linea, posC, MaxInt);
  end
  else
  begin
    body := Copy(Linea, posA + 1, MaxInt);
    tail := '';
  end;
  comas := SeparadoresNivelCero(body, True);
  if Length(comas) = 0 then Exit;

  partes := TStringList.Create;
  prev := 1;
  for i := 0 to High(comas) do
  begin
    partes.Add(string(Trim(Copy(body, prev, comas[i] - prev + 1))));
    prev := comas[i] + 1;
  end;
  ult := Trim(Copy(body, prev, MaxInt));
  if ult <> '' then partes.Add(string(ult));
  if partes.Count = 0 then begin partes.Free; Exit; end;

  cont := AnsiString(StringOfChar(' ', AlineadoCol));
  Result := TStringList.Create;
  primera := head + AnsiString(partes[0]);
  if AnchoVisible(primera) > ANCHO_MAX then
  begin
    Result.Free; Result := nil; partes.Free; Exit;
  end;
  Result.Add(string(primera));
  for i := 1 to partes.Count - 1 do
  begin
    cand := cont + AnsiString(partes[i]);
    if AnchoVisible(cand) > ANCHO_MAX then
    begin
      Result.Free; Result := nil; partes.Free; Exit;
    end;
    Result.Add(string(cand));
  end;
  partes.Free;

  if tail <> '' then
  begin
    cand := AnsiString(Result[Result.Count - 1]) + tail;
    if AnchoVisible(cand) <= ANCHO_MAX then
      Result[Result.Count - 1] := string(cand)
    else
    begin
      Result.Add(string(indent + TrimLeft(tail)));
      for c := 0 to Result.Count - 1 do
        if AnchoVisible(AnsiString(Result[c])) > ANCHO_MAX then
        begin
          Result.Free; Result := nil; Exit;
        end;
    end;
  end;
end;


function WrapParen(const Linea: AnsiString): TStringList;
var
  posA, posC: Integer;
  indent: AnsiString;
  col: Integer;
begin
  ParenAbiertosMejores(Linea, posA, posC);
  if posA < 0 then begin Result := nil; Exit; end;
  indent := ObtenerIndentacion(Linea);

  // 1ª opción: alineado bajo el '('
  col := posA;
  if col <= 60 then
  begin
    Result := ProbarWrapParen(Linea, col);
    if Assigned(Result) then Exit;
  end;

  // 2ª opción: continuación a indent + 2
  col := Length(indent) + 2;
  Result := ProbarWrapParen(Linea, col);
end;


function ProbarWrapParenBlando(const Linea: AnsiString;
                                AlineadoCol: Integer): TStringList;
{ Versión "blanda" de WrapParen: admite que las continuaciones excedan 80
  col; el orquestador recurre sobre ellas. Sólo exige que la primera línea
  quepa. }
var
  posA, posC: Integer;
  indent, head, body, tail, primera, cand, cont: AnsiString;
  comas: TIntArr;
  partes: TStringList;
  prev, i: Integer;
  ult: AnsiString;
begin
  Result := nil;
  ParenAbiertosMejores(Linea, posA, posC);
  if posA < 0 then Exit;
  indent := ObtenerIndentacion(Linea);

  head := Copy(Linea, 1, posA);
  if posC > 0 then
  begin
    body := Copy(Linea, posA + 1, posC - posA - 1);
    tail := Copy(Linea, posC, MaxInt);
  end
  else
  begin
    body := Copy(Linea, posA + 1, MaxInt);
    tail := '';
  end;
  comas := SeparadoresNivelCero(body, True);
  if Length(comas) = 0 then Exit;

  partes := TStringList.Create;
  prev := 1;
  for i := 0 to High(comas) do
  begin
    partes.Add(string(Trim(Copy(body, prev, comas[i] - prev + 1))));
    prev := comas[i] + 1;
  end;
  ult := Trim(Copy(body, prev, MaxInt));
  if ult <> '' then partes.Add(string(ult));
  if partes.Count = 0 then begin partes.Free; Exit; end;

  cont := AnsiString(StringOfChar(' ', AlineadoCol));
  Result := TStringList.Create;
  primera := head + AnsiString(partes[0]);
  if AnchoVisible(primera) > ANCHO_MAX then
  begin
    Result.Free; Result := nil; partes.Free; Exit;
  end;
  Result.Add(string(primera));
  for i := 1 to partes.Count - 1 do
  begin
    cand := cont + AnsiString(partes[i]);
    Result.Add(string(cand));
  end;
  partes.Free;

  if tail <> '' then
    Result[Result.Count - 1] :=
      string(AnsiString(Result[Result.Count - 1]) + tail);
end;


function WrapParenBlando(const Linea: AnsiString): TStringList;
var
  posA, posC: Integer;
  indent: AnsiString;
  col: Integer;
begin
  ParenAbiertosMejores(Linea, posA, posC);
  if posA < 0 then begin Result := nil; Exit; end;
  indent := ObtenerIndentacion(Linea);
  col := posA;
  if col <= 60 then
  begin
    Result := ProbarWrapParenBlando(Linea, col);
    if Assigned(Result) then Exit;
  end;
  col := Length(indent) + 2;
  Result := ProbarWrapParenBlando(Linea, col);
end;


{ ============================================================================ }
{  Regla 5: string literal larga - partir en espacios con ' +'                 }
{ ============================================================================ }

function WrapStringLarga(const Linea: AnsiString): TStringList;
var
  toks: TTokens;
  i, idxTarget, sStart, sEnd: Integer;
  best: Integer;
  inner, pre, post, contInd: AnsiString;
  partes: TStringList;
  cur, parteHead: AnsiString;
  firstAvail, contAvail: Integer;
  cut, k: Integer;
  ultima: AnsiString;
begin
  Result := nil;
  toks := Tokenizar(Linea);
  idxTarget := -1; best := 0;
  for i := 0 to High(toks) do
    if toks[i].Kind = tkString then
      if (toks[i].BEnd - toks[i].BStart) > best then
      begin
        best := toks[i].BEnd - toks[i].BStart;
        idxTarget := i;
      end;
  if idxTarget < 0 then Exit;
  sStart := toks[idxTarget].BStart;
  sEnd   := toks[idxTarget].BEnd;
  // contenido interior (sin comillas exteriores)
  inner := Copy(Linea, sStart + 1, sEnd - sStart - 1);

  pre := Copy(Linea, 1, sStart - 1);
  post := Copy(Linea, sEnd + 1, MaxInt);

  // disponible para el contenido en la primera línea:
  //   pre + '...' + ' +'
  firstAvail := ANCHO_MAX - AnchoVisible(pre) - 2 - 2;
  if firstAvail < 10 then Exit;
  contInd := AnsiString(StringOfChar(' ', AnchoVisible(pre)));
  contAvail := ANCHO_MAX - AnchoVisible(contInd) - 2 - 2;
  if contAvail < 10 then Exit;

  partes := TStringList.Create;
  cur := inner;
  if AnchoVisible(cur) <= firstAvail then
  begin
    partes.Add(string(cur));
  end
  else
  begin
    // primera ventana
    cut := 0;
    // buscamos el último espacio cuya posición de char <= firstAvail
    k := 0; i := 1;
    while i <= Length(cur) do
    begin
      if (Byte(cur[i]) and $C0) <> $80 then Inc(k);
      if k > firstAvail then Break;
      if cur[i] = ' ' then cut := i;
      Inc(i);
    end;
    if cut <= 0 then
    begin
      partes.Free; Exit;
    end;
    partes.Add(string(Copy(cur, 1, cut)));
    cur := Copy(cur, cut + 1, MaxInt);
    while AnchoVisible(cur) > contAvail do
    begin
      cut := 0; k := 0; i := 1;
      while i <= Length(cur) do
      begin
        if (Byte(cur[i]) and $C0) <> $80 then Inc(k);
        if k > contAvail then Break;
        if cur[i] = ' ' then cut := i;
        Inc(i);
      end;
      if cut <= 0 then
      begin
        partes.Free; Exit;
      end;
      partes.Add(string(Copy(cur, 1, cut)));
      cur := Copy(cur, cut + 1, MaxInt);
    end;
    if Length(cur) > 0 then partes.Add(string(cur));
  end;

  if partes.Count <= 1 then
  begin
    partes.Free; Exit;
  end;

  Result := TStringList.Create;
  parteHead := pre + '''' + AnsiString(partes[0]) + ''' +';
  Result.Add(string(parteHead));
  for i := 1 to partes.Count - 2 do
    Result.Add(string(contInd + '''' + AnsiString(partes[i]) + ''' +'));
  ultima := contInd + '''' + AnsiString(partes[partes.Count - 1]) + ''''
            + post;
  Result.Add(string(ultima));
  partes.Free;

  for i := 0 to Result.Count - 1 do
    if AnchoVisible(AnsiString(Result[i])) > ANCHO_MAX then
    begin
      Result.Free; Result := nil; Exit;
    end;
end;


{ ============================================================================ }
{  Regla 6: colapsar espacios redundantes fuera de strings/comentarios         }
{ ============================================================================ }

function WrapColapsarEspacios(const Linea: AnsiString): TStringList;
var
  indent, sal: AnsiString;
  i, n: Integer;
  enStr, enBCom: Boolean;
  ultimoEspacio: Boolean;
  c: AnsiChar;
begin
  Result := nil;
  indent := ObtenerIndentacion(Linea);
  sal := indent;
  ultimoEspacio := True;
  n := Length(Linea);
  i := Length(indent) + 1;
  enStr := False;
  enBCom := False;
  while i <= n do
  begin
    c := Linea[i];
    if enBCom then
    begin
      sal := sal + c;
      if c = '}' then enBCom := False;
      Inc(i); ultimoEspacio := False; Continue;
    end;
    if enStr then
    begin
      sal := sal + c;
      if c = '''' then
      begin
        if (i < n) and (Linea[i + 1] = '''') then
        begin
          sal := sal + Linea[i + 1];
          Inc(i, 2); ultimoEspacio := False; Continue;
        end;
        enStr := False;
      end;
      Inc(i); ultimoEspacio := False; Continue;
    end;
    if (c = '/') and (i < n) and (Linea[i + 1] = '/') then
    begin
      sal := sal + Copy(Linea, i, n - i + 1);
      i := n + 1;
      Break;
    end;
    if c = '''' then
    begin
      sal := sal + c; enStr := True; ultimoEspacio := False;
      Inc(i); Continue;
    end;
    if c = '{' then
    begin
      sal := sal + c; enBCom := True; ultimoEspacio := False;
      Inc(i); Continue;
    end;
    if c = ' ' then
    begin
      if not ultimoEspacio then
      begin
        sal := sal + ' ';
        ultimoEspacio := True;
      end;
      Inc(i); Continue;
    end;
    sal := sal + c;
    ultimoEspacio := False;
    Inc(i);
  end;
  // Recortar espacios finales
  while (Length(sal) > 0) and (sal[Length(sal)] = ' ') do
    SetLength(sal, Length(sal) - 1);
  if (sal <> Linea) and (AnchoVisible(sal) <= ANCHO_MAX) then
  begin
    Result := TStringList.Create;
    Result.Add(string(sal));
  end;
end;


{ ============================================================================ }
{  Regla 7: paréntesis sin separadores -> arg en línea aparte                  }
{ ============================================================================ }

function ProbarAbreParenSinSeparadores(const Linea: AnsiString;
                                        ASoloSiCabe: Boolean): TStringList;
var
  posA, posC: Integer;
  indent, head, body, tail: AnsiString;
  cuerpoIndent: AnsiString;
begin
  Result := nil;
  ParenAbiertosMejores(Linea, posA, posC);
  if posA < 0 then Exit;
  indent := ObtenerIndentacion(Linea);
  head := Copy(Linea, 1, posA);
  if posC > 0 then
  begin
    body := Trim(Copy(Linea, posA + 1, posC - posA - 1));
    tail := Copy(Linea, posC, MaxInt);
  end
  else
  begin
    body := Trim(Copy(Linea, posA + 1, MaxInt));
    tail := '';
  end;
  if body = '' then Exit;
  if AnchoVisible(head) > ANCHO_MAX then Exit;
  cuerpoIndent := indent + '  ';
  if ASoloSiCabe
     and (AnchoVisible(cuerpoIndent + body + tail) > ANCHO_MAX) then
    Exit;
  Result := TStringList.Create;
  Result.Add(string(head));
  Result.Add(string(cuerpoIndent + body + tail));
end;


function WrapAbreParenSinSeparadores(const Linea: AnsiString): TStringList;
begin
  Result := ProbarAbreParenSinSeparadores(Linea, True);
end;


function WrapAbreParenSinSeparadoresBlando(
  const Linea: AnsiString): TStringList;
begin
  Result := ProbarAbreParenSinSeparadores(Linea, False);
end;


{ ============================================================================ }
{  Regla 8: asignación - wrap en ':='                                          }
{ ============================================================================ }

function EncontrarAsignacionTopLevel(const Linea: AnsiString): Integer;
var
  i, n, profP, profB, j: Integer;
  enStr: Boolean;
begin
  Result := 0;
  n := Length(Linea);
  i := 1;
  enStr := False;
  profP := 0;
  profB := 0;
  while i <= n do
  begin
    if enStr then
    begin
      if Linea[i] = '''' then
      begin
        if (i < n) and (Linea[i + 1] = '''') then
        begin
          Inc(i, 2);
          Continue;
        end;
        enStr := False;
      end;
      Inc(i);
      Continue;
    end;
    if Linea[i] = '''' then begin enStr := True; Inc(i); Continue; end;
    if (Linea[i] = '/') and (i < n) and (Linea[i + 1] = '/') then Break;
    if Linea[i] = '{' then
    begin
      j := PosEx('}', Linea, i + 1);
      if j = 0 then i := n + 1 else i := j + 1;
      Continue;
    end;
    case Linea[i] of
      '(': Inc(profP);
      ')': Dec(profP);
      '[': Inc(profB);
      ']': Dec(profB);
      ':':
        if (profP = 0) and (profB = 0) and (i < n)
           and (Linea[i + 1] = '=') then
        begin
          Result := i;
          Exit;
        end;
    end;
    Inc(i);
  end;
end;


function WrapAsignacion(const Linea: AnsiString): TStringList;
var
  pos: Integer;
  indent, lhs, rhs: AnsiString;
begin
  Result := nil;
  pos := EncontrarAsignacionTopLevel(Linea);
  if pos <= 0 then Exit;
  indent := ObtenerIndentacion(Linea);
  lhs := TrimDerecha(Copy(Linea, 1, pos + 1));  // hasta ':=' inclusive
  rhs := Trim(Copy(Linea, pos + 2, MaxInt));
  if rhs = '' then Exit;
  if AnchoVisible(lhs) > ANCHO_MAX then Exit;
  if AnchoVisible(indent + '  ' + rhs) > ANCHO_MAX then Exit;
  Result := TStringList.Create;
  Result.Add(string(lhs));
  Result.Add(string(indent + '  ' + rhs));
end;


{ ============================================================================ }
{  Regla 9: operador '+' top-level                                             }
{ ============================================================================ }

function PosicionesMasTopLevel(const Linea: AnsiString): TIntArr;
var
  i, n, profP, profB, j: Integer;
  enStr: Boolean;
begin
  Result := nil;
  n := Length(Linea);
  i := 1;
  enStr := False;
  profP := 0;
  profB := 0;
  while i <= n do
  begin
    if enStr then
    begin
      if Linea[i] = '''' then
      begin
        if (i < n) and (Linea[i + 1] = '''') then
        begin
          Inc(i, 2);
          Continue;
        end;
        enStr := False;
      end;
      Inc(i);
      Continue;
    end;
    if Linea[i] = '''' then begin enStr := True; Inc(i); Continue; end;
    if (Linea[i] = '/') and (i < n) and (Linea[i + 1] = '/') then Break;
    if Linea[i] = '{' then
    begin
      j := PosEx('}', Linea, i + 1);
      if j = 0 then i := n + 1 else i := j + 1;
      Continue;
    end;
    case Linea[i] of
      '(': Inc(profP);
      ')': Dec(profP);
      '[': Inc(profB);
      ']': Dec(profB);
      '+':
        if (profP = 0) and (profB = 0) then
        begin
          // ignorar '+' al inicio (unary) cuando va precedido por operador
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := i;
        end;
    end;
    Inc(i);
  end;
end;


function EsCaracterPalabra(c: AnsiChar): Boolean;
begin
  Result := ((c >= 'A') and (c <= 'Z')) or ((c >= 'a') and (c <= 'z'))
            or ((c >= '0') and (c <= '9')) or (c = '_');
end;


function PalabraEn(const S: AnsiString; APos: Integer;
                   const APalabra: AnsiString): Boolean;
var
  i: Integer;
  lp: Integer;
begin
  Result := False;
  lp := Length(APalabra);
  if APos + lp - 1 > Length(S) then Exit;
  if LowerCase(string(Copy(S, APos, lp))) <> string(APalabra) then Exit;
  if (APos > 1) and EsCaracterPalabra(S[APos - 1]) then Exit;
  if (APos + lp <= Length(S)) and EsCaracterPalabra(S[APos + lp]) then Exit;
  Result := True;
end;


function PosicionesAndOrTopLevel(const Linea: AnsiString): TIntArr;
var
  i, n, profP, profB, j: Integer;
  enStr: Boolean;
begin
  Result := nil;
  n := Length(Linea);
  i := 1;
  enStr := False;
  profP := 0;
  profB := 0;
  while i <= n do
  begin
    if enStr then
    begin
      if Linea[i] = '''' then
      begin
        if (i < n) and (Linea[i + 1] = '''') then
        begin
          Inc(i, 2);
          Continue;
        end;
        enStr := False;
      end;
      Inc(i);
      Continue;
    end;
    if Linea[i] = '''' then begin enStr := True; Inc(i); Continue; end;
    if (Linea[i] = '/') and (i < n) and (Linea[i + 1] = '/') then Break;
    if Linea[i] = '{' then
    begin
      j := PosEx('}', Linea, i + 1);
      if j = 0 then i := n + 1 else i := j + 1;
      Continue;
    end;
    case Linea[i] of
      '(': begin Inc(profP); Inc(i); Continue; end;
      ')': begin Dec(profP); Inc(i); Continue; end;
      '[': begin Inc(profB); Inc(i); Continue; end;
      ']': begin Dec(profB); Inc(i); Continue; end;
    end;
    if (profP = 0) and (profB = 0) then
    begin
      if PalabraEn(Linea, i, 'and') then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := i;
        Inc(i, 3);
        Continue;
      end;
      if PalabraEn(Linea, i, 'or') then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := i;
        Inc(i, 2);
        Continue;
      end;
    end;
    Inc(i);
  end;
end;


function WrapBooleano(const Linea: AnsiString): TStringList;
var
  positions: TIntArr;
  indent, primera, resto: AnsiString;
  cont: AnsiString;
  i, mejor: Integer;
  prefijo: AnsiString;
begin
  Result := nil;
  positions := PosicionesAndOrTopLevel(Linea);
  if Length(positions) = 0 then Exit;
  indent := ObtenerIndentacion(Linea);
  cont := indent + '   ';  // 3 espacios extra para alinearse tras 'if '
  mejor := -1;
  for i := 0 to High(positions) do
  begin
    prefijo := TrimDerecha(Copy(Linea, 1, positions[i] - 1));
    if AnchoVisible(prefijo) <= ANCHO_MAX then
      if positions[i] > mejor then mejor := positions[i];
  end;
  if mejor < 0 then Exit;
  primera := TrimDerecha(Copy(Linea, 1, mejor - 1));
  resto := Copy(Linea, mejor, MaxInt);
  Result := TStringList.Create;
  Result.Add(string(primera));
  Result.Add(string(cont + resto));
end;


function WrapMas(const Linea: AnsiString): TStringList;
var
  positions: TIntArr;
  indent, primera, resto: AnsiString;
  cont: AnsiString;
  i, mejor, limite, start: Integer;
  contLen: Integer;
begin
  Result := nil;
  positions := PosicionesMasTopLevel(Linea);
  if Length(positions) = 0 then Exit;
  indent := ObtenerIndentacion(Linea);
  cont := indent + '  ';
  contLen := AnchoVisible(cont);
  // queremos partir antes del operador, dejando '+' al principio del
  // continuación. Buscamos el '+' más a la derecha cuya posición
  // dejaría la primera línea <= ANCHO_MAX.
  mejor := -1;
  for i := 0 to High(positions) do
    if AnchoVisible(TrimDerecha(Copy(Linea, 1, positions[i] - 1)))
       <= ANCHO_MAX then
      if positions[i] > mejor then mejor := positions[i];
  if mejor < 0 then Exit;
  primera := TrimDerecha(Copy(Linea, 1, mejor - 1));
  resto := Copy(Linea, mejor, MaxInt);
  if AnchoVisible(cont + resto) > ANCHO_MAX then
  begin
    // intentar partir el resto recursivamente con esta misma regla
    // (varios '+' encadenados)
    Result := TStringList.Create;
    Result.Add(string(primera));
    // recursión sencilla: una sola partida más
    Result.Add(string(cont + resto));
    if AnchoVisible(AnsiString(Result[Result.Count - 1])) > ANCHO_MAX then
    begin
      Result.Free; Result := nil; Exit;
    end;
    Exit;
  end;
  Result := TStringList.Create;
  Result.Add(string(primera));
  Result.Add(string(cont + resto));
end;


{ ============================================================================ }
{  Orquestador de reglas                                                       }
{ ============================================================================ }

function ReformatearLineaUnica(const Linea: AnsiString): TStringList;
begin
  Result := WrapComentarioLinea(Linea);
  if Assigned(Result) then Exit;

  Result := WrapDespegarComentarioInline(Linea);
  if Assigned(Result) then Exit;

  Result := WrapColapsarEspacios(Linea);
  if Assigned(Result) then Exit;

  Result := WrapListaConComas(Linea);
  if Assigned(Result) then Exit;

  Result := WrapParen(Linea);
  if Assigned(Result) then Exit;

  Result := WrapBooleano(Linea);
  if Assigned(Result) then Exit;

  Result := WrapAsignacion(Linea);
  if Assigned(Result) then Exit;

  Result := WrapMas(Linea);
  if Assigned(Result) then Exit;

  Result := WrapAbreParenSinSeparadores(Linea);
  if Assigned(Result) then Exit;

  Result := WrapComasGeneral(Linea);
  if Assigned(Result) then Exit;

  // Último recurso: wraps "blandos" (admite continuaciones que recursan)
  Result := WrapParenBlando(Linea);
  if Assigned(Result) then Exit;

  Result := WrapAbreParenSinSeparadoresBlando(Linea);
  if Assigned(Result) then Exit;

  Result := WrapStringLarga(Linea);
  if Assigned(Result) then Exit;

  Result := nil;
end;


function ReformatearLinea(const Linea: AnsiString): TStringList;
const
  PROF_MAX = 6;
var
  cola: TStringList;

  procedure RecursarHasta80(LineasOut: TStringList; Profundidad: Integer);
  var
    i, j: Integer;
    actual: AnsiString;
    sub: TStringList;
  begin
    if Profundidad >= PROF_MAX then Exit;
    i := 0;
    while i < LineasOut.Count do
    begin
      actual := AnsiString(LineasOut[i]);
      if AnchoVisible(actual) > ANCHO_MAX then
      begin
        sub := ReformatearLineaUnica(actual);
        if Assigned(sub) then
        begin
          LineasOut.Delete(i);
          for j := sub.Count - 1 downto 0 do
            LineasOut.Insert(i, sub[j]);
          // recursar sobre los nuevos
          RecursarHasta80(LineasOut, Profundidad + 1);
          sub.Free;
          Inc(i, 1);  // skip
          Continue;
        end;
      end;
      Inc(i);
    end;
  end;

begin
  Result := ReformatearLineaUnica(Linea);
  if not Assigned(Result) then Exit;
  cola := Result;
  RecursarHasta80(cola, 1);
end;


function ReformatearLineas(ALineas: TStringList): Integer;
var
  salida: TStringList;
  i, j: Integer;
  linea: AnsiString;
  resWrap: TStringList;
begin
  Result := 0;
  salida := TStringList.Create;
  try
    for i := 0 to ALineas.Count - 1 do
    begin
      linea := AnsiString(ALineas[i]);
      if AnchoVisible(linea) <= ANCHO_MAX then
      begin
        salida.Add(string(linea));
        Continue;
      end;
      resWrap := ReformatearLinea(linea);
      if Assigned(resWrap) then
      begin
        for j := 0 to resWrap.Count - 1 do
          salida.Add(resWrap[j]);
        resWrap.Free;
        Inc(Result);
      end
      else
        salida.Add(string(linea));
    end;
    ALineas.Assign(salida);
  finally
    salida.Free;
  end;
end;


{ ============================================================================ }
{  E/S de fichero: BOM, EOL, codificación                                      }
{ ============================================================================ }

{ Divide texto en líneas manualmente, sin EOLs en el contenido. Detecta el
  estilo de fin de línea predominante (CRLF/LF) y si hay EOL final. }
procedure DividirLineas(const Texto: AnsiString;
                        Lineas: TStringList;
                        out UsarCRLF, EOLFinal: Boolean);
var
  i, n, ini: Integer;
  cntCRLF, cntLF: Integer;
begin
  Lineas.Clear;
  n := Length(Texto);
  cntCRLF := 0;
  cntLF := 0;
  i := 1;
  ini := 1;
  while i <= n do
  begin
    if Texto[i] = #10 then
    begin
      if (i > 1) and (Texto[i - 1] = #13) then
      begin
        Lineas.Add(string(Copy(Texto, ini, i - 1 - ini)));
        Inc(cntCRLF);
      end
      else
      begin
        Lineas.Add(string(Copy(Texto, ini, i - ini)));
        Inc(cntLF);
      end;
      ini := i + 1;
    end;
    Inc(i);
  end;
  if ini <= n then
  begin
    Lineas.Add(string(Copy(Texto, ini, n - ini + 1)));
    EOLFinal := False;
  end
  else
    EOLFinal := True;
  UsarCRLF := cntCRLF >= cntLF;
end;


function UnirLineas(Lineas: TStringList;
                    UsarCRLF, EOLFinal: Boolean): AnsiString;
var
  i: Integer;
  eol: AnsiString;
  sb: AnsiString;
begin
  if UsarCRLF then eol := AnsiString(#13#10) else eol := AnsiString(#10);
  sb := '';
  for i := 0 to Lineas.Count - 1 do
  begin
    sb := sb + AnsiString(Lineas[i]);
    if (i < Lineas.Count - 1) or EOLFinal then
      sb := sb + eol;
  end;
  Result := sb;
end;


procedure ReformatearPas(const ARutaFichero: AnsiString;
                         out ACambios, APendientes: Integer;
                         ASoloSimulacion: Boolean = False);
var
  fs: TFileStream;
  bytes: TBytes;
  texto: AnsiString;
  bom: AnsiString;
  usarCRLF, eolFinal: Boolean;
  lineas: TStringList;
  i: Integer;
  resultadoBytes: TBytes;
  salidaTexto: AnsiString;
begin
  ACambios := 0;
  APendientes := 0;
  fs := TFileStream.Create(string(ARutaFichero),
                           fmOpenRead or fmShareDenyNone);
  try
    SetLength(bytes, fs.Size);
    if fs.Size > 0 then fs.ReadBuffer(bytes[0], fs.Size);
  finally
    fs.Free;
  end;
  bom := '';
  if (Length(bytes) >= 3)
     and (bytes[0] = $EF) and (bytes[1] = $BB) and (bytes[2] = $BF) then
  begin
    bom := AnsiString(#$EF#$BB#$BF);
    SetLength(texto, Length(bytes) - 3);
    if Length(texto) > 0 then Move(bytes[3], texto[1], Length(texto));
  end
  else
  begin
    SetLength(texto, Length(bytes));
    if Length(texto) > 0 then Move(bytes[0], texto[1], Length(texto));
  end;

  lineas := TStringList.Create;
  try
    DividirLineas(texto, lineas, usarCRLF, eolFinal);

    ACambios := ReformatearLineas(lineas);

    for i := 0 to lineas.Count - 1 do
      if AnchoVisible(AnsiString(lineas[i])) > ANCHO_MAX then
        Inc(APendientes);

    if ASoloSimulacion then Exit;
    if ACambios = 0 then Exit;

    salidaTexto := UnirLineas(lineas, usarCRLF, eolFinal);

    SetLength(resultadoBytes, Length(bom) + Length(salidaTexto));
    if Length(bom) > 0 then
      Move(bom[1], resultadoBytes[0], Length(bom));
    if Length(salidaTexto) > 0 then
      Move(salidaTexto[1], resultadoBytes[Length(bom)],
           Length(salidaTexto));

    fs := TFileStream.Create(string(ARutaFichero),
                             fmCreate or fmShareDenyWrite);
    try
      if Length(resultadoBytes) > 0 then
        fs.WriteBuffer(resultadoBytes[0], Length(resultadoBytes));
    finally
      fs.Free;
    end;
  finally
    lineas.Free;
  end;
end;

end.
