{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlValidacion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación estática de SQL configurable y sus parámetros UniDAC.          }
{******************************************************************************}
unit inLibCatalogoSqlValidacion;

interface

uses
  inLibCatalogoSqlIntf,
  inLibConexionPerfilIntf;

function ValidarSql(
  const ADefinicion: TDefinicionSql;
  const ASql: string): TResultadoValidacionSql; overload;
function ValidarSql(
  const ADefinicion: TDefinicionSql;
  const ASql: string;
  AMotor: TMotorBBDD): TResultadoValidacionSql; overload;
function ValidarDefinicionSql(
  const ADefinicion: TDefinicionSql): TResultadoValidacionSql;
function CalcularHuellaSql(const ASql: string): string;

implementation

uses
  System.SysUtils, System.Classes, System.Hash;

function EsInicioIdentificador(ACaracter: Char): Boolean;
begin
  Result := CharInSet(
    ACaracter, ['A'..'Z', 'a'..'z', '_']);
end;

function EsCaracterIdentificador(ACaracter: Char): Boolean;
begin
  Result := EsInicioIdentificador(ACaracter) or
    CharInSet(ACaracter, ['0'..'9']);
end;

function TextoSinLiterales(const ASql: string): string;
var
  bEnLiteral: Boolean;
  iIndice: Integer;
begin
  Result := ASql;
  bEnLiteral := False;
  iIndice := 1;
  while iIndice <= Length(Result) do
  begin
    if Result[iIndice] = '''' then
    begin
      if bEnLiteral and
         (iIndice < Length(Result)) and
         (Result[iIndice + 1] = '''') then
      begin
        Result[iIndice] := ' ';
        Result[iIndice + 1] := ' ';
        Inc(iIndice);
      end
      else
      begin
        bEnLiteral := not bEnLiteral;
        Result[iIndice] := ' ';
      end;
    end
    else if bEnLiteral then
      Result[iIndice] := ' ';
    Inc(iIndice);
  end;
end;

function ExtraerParametros(const ASql: string): TStringList;
var
  iFin: Integer;
  iInicio: Integer;
  iIndice: Integer;
  sSinLiterales: string;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  Result.Sorted := True;
  sSinLiterales := TextoSinLiterales(ASql);
  iIndice := 1;
  while iIndice <= Length(sSinLiterales) do
  begin
    if (sSinLiterales[iIndice] = ':') and
       ((iIndice = 1) or
        (sSinLiterales[iIndice - 1] <> ':')) and
       (iIndice < Length(sSinLiterales)) and
       EsInicioIdentificador(sSinLiterales[iIndice + 1]) then
    begin
      iInicio := iIndice + 1;
      iFin := iInicio;
      while (iFin <= Length(sSinLiterales)) and
            EsCaracterIdentificador(sSinLiterales[iFin]) do
        Inc(iFin);
      Result.Add(
        LowerCase(Copy(sSinLiterales, iInicio, iFin - iInicio)));
      iIndice := iFin;
    end
    else
      Inc(iIndice);
  end;
end;

function ParametrosEsperados(
  const AParametros: string): TStringList;
var
  iIndice: Integer;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  Result.StrictDelimiter := True;
  Result.Delimiter := ',';
  Result.DelimitedText := LowerCase(AParametros);
  for iIndice := Result.Count - 1 downto 0 do
  begin
    Result[iIndice] := Trim(Result[iIndice]);
    if Result[iIndice] = '' then
      Result.Delete(iIndice);
  end;
  Result.Sorted := True;
end;

function NombreTipoSentencia(
  ATipo: TTipoSentenciaSql): string;
begin
  case ATipo of
    tssSelect:
      Result := 'SELECT';
    tssInsert:
      Result := 'INSERT';
    tssUpdate:
      Result := 'UPDATE';
    tssDelete:
      Result := 'DELETE';
    tssCall:
      Result := 'CALL';
  else
    Result := '';
  end;
end;

function PrimerToken(const ASql: string): string;
var
  iFin: Integer;
  iInicio: Integer;
  sTexto: string;
begin
  Result := '';
  sTexto := TrimLeft(ASql);
  iInicio := 1;
  iFin := iInicio;
  while (iFin <= Length(sTexto)) and
        EsCaracterIdentificador(sTexto[iFin]) do
    Inc(iFin);
  if iFin > iInicio then
    Result := UpperCase(
      Copy(sTexto, iInicio, iFin - iInicio));
end;

function ContienePalabra(
  const ATexto, APalabra: string): Boolean;
var
  iFin: Integer;
  iInicio: Integer;
  sTexto: string;
begin
  Result := False;
  sTexto := UpperCase(TextoSinLiterales(ATexto));
  iInicio := 1;
  while (iInicio <= Length(sTexto)) and (not Result) do
  begin
    while (iInicio <= Length(sTexto)) and
          (not EsInicioIdentificador(sTexto[iInicio])) do
      Inc(iInicio);
    iFin := iInicio;
    while (iFin <= Length(sTexto)) and
          EsCaracterIdentificador(sTexto[iFin]) do
      Inc(iFin);
    if iFin > iInicio then
      Result := Copy(
        sTexto, iInicio, iFin - iInicio) = APalabra;
    iInicio := iFin + 1;
  end;
end;

function PosicionPalabraNivelCero(
  const ATexto, APalabra: string): Integer;
var
  iFin: Integer;
  iIndice: Integer;
  iNivel: Integer;
  sTexto: string;
  sToken: string;
begin
  Result := 0;
  sTexto := UpperCase(TextoSinLiterales(ATexto));
  iIndice := 1;
  iNivel := 0;
  while (iIndice <= Length(sTexto)) and
        (Result = 0) do
  begin
    if sTexto[iIndice] = '(' then
    begin
      Inc(iNivel);
      Inc(iIndice);
    end
    else if sTexto[iIndice] = ')' then
    begin
      if iNivel > 0 then
        Dec(iNivel);
      Inc(iIndice);
    end
    else if EsInicioIdentificador(sTexto[iIndice]) then
    begin
      iFin := iIndice;
      while (iFin <= Length(sTexto)) and
            EsCaracterIdentificador(sTexto[iFin]) do
        Inc(iFin);
      sToken := Copy(
        sTexto, iIndice, iFin - iIndice);
      if (iNivel = 0) and
         (sToken = UpperCase(APalabra)) then
        Result := iIndice;
      iIndice := iFin;
    end
    else
      Inc(iIndice);
  end;
end;

function EsSelectConCte(const ASql: string): Boolean;
begin
  Result := (PrimerToken(ASql) = 'WITH') and
    (PosicionPalabraNivelCero(ASql, 'SELECT') > 0);
end;

function EsNombreCampoSimple(
  const ACampo: string): Boolean;
var
  iIndice: Integer;
begin
  Result := Trim(ACampo) <> '';
  iIndice := 1;
  while Result and
        (iIndice <= Length(ACampo)) do
  begin
    Result := EsCaracterIdentificador(
      ACampo[iIndice]);
    Inc(iIndice);
  end;
end;

function SeleccionaTodosLosCampos(
  const ASeleccion: string): Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  iIndice := PosicionPalabraNivelCero(
    ASeleccion,
    'SELECT');
  if iIndice > 0 then
  begin
    Inc(iIndice, Length('SELECT'));
    while (iIndice <= Length(ASeleccion)) and
          CharInSet(
            ASeleccion[iIndice],
            [#9, #10, #13, ' ']) do
      Inc(iIndice);
    Result := (iIndice <= Length(ASeleccion)) and
      (ASeleccion[iIndice] = '*');
  end;
end;

function ContieneCampoResultado(
  const ASeleccion, ACampo: string): Boolean;
begin
  if EsNombreCampoSimple(ACampo) then
    Result := ContienePalabra(
      ASeleccion,
      UpperCase(ACampo))
  else
    Result := Pos(
      UpperCase(Trim(ACampo)),
      UpperCase(ASeleccion)) > 0;
end;

function ValidarCamposResultado(
  const ADefinicion: TDefinicionSql;
  const ASql: string;
  out AMensaje: string): Boolean;
var
  iCampo: Integer;
  iDesde: Integer;
  oCampos: TStringList;
  oFaltantes: TStringList;
  sSeleccion: string;
begin
  Result := True;
  AMensaje := '';
  if (ADefinicion.TipoSentencia = tssSelect) and
     (Trim(ADefinicion.CamposResultado) <> '') then
  begin
    sSeleccion := TextoSinLiterales(ASql);
    iDesde := PosicionPalabraNivelCero(
      sSeleccion, 'FROM');
    if iDesde > 0 then
      sSeleccion := Copy(
        sSeleccion, 1, iDesde - 1);
    if not SeleccionaTodosLosCampos(sSeleccion) then
    begin
      oCampos := ParametrosEsperados(
        ADefinicion.CamposResultado);
      oFaltantes := TStringList.Create;
      try
        for iCampo := 0 to oCampos.Count - 1 do
        begin
          if not ContieneCampoResultado(
            sSeleccion,
            oCampos[iCampo]) then
            oFaltantes.Add(oCampos[iCampo]);
        end;
        Result := oFaltantes.Count = 0;
        if not Result then
          AMensaje := Format(
            'Campos de salida obligatorios ausentes [%s].',
            [oFaltantes.CommaText]);
      finally
        FreeAndNil(oFaltantes);
        FreeAndNil(oCampos);
      end;
    end;
  end;
end;

function TieneVariasSentencias(const ASql: string): Boolean;
var
  sTexto: string;
begin
  sTexto := TrimRight(TextoSinLiterales(ASql));
  if (sTexto <> '') and
     (sTexto[Length(sTexto)] = ';') then
    Delete(sTexto, Length(sTexto), 1);
  Result := Pos(';', sTexto) > 0;
end;

function ListasIguales(
  APrimera, ASegunda: TStringList): Boolean;
var
  iIndice: Integer;
begin
  Result := APrimera.Count = ASegunda.Count;
  iIndice := 0;
  while Result and (iIndice < APrimera.Count) do
  begin
    Result := SameText(
      APrimera[iIndice], ASegunda[iIndice]);
    Inc(iIndice);
  end;
end;

function CalcularHuellaSql(const ASql: string): string;
begin
  Result := THashSHA2.GetHashString(ASql);
end;

function ValidarSql(
  const ADefinicion: TDefinicionSql;
  const ASql: string): TResultadoValidacionSql;
begin
  Result := ValidarSql(
    ADefinicion,
    ASql,
    mbMariaDB);
end;

function ValidarSql(
  const ADefinicion: TDefinicionSql;
  const ASql: string;
  AMotor: TMotorBBDD): TResultadoValidacionSql;
var
  oEsperados: TStringList;
  oEncontrados: TStringList;
  sMensajeCampos: string;
  sPrimerToken: string;
  sTipoEsperado: string;
begin
  Result.EsValido := False;
  Result.Mensaje := '';
  Result.Huella := CalcularHuellaSql(ASql);
  if Trim(ASql) = '' then
    Result.Mensaje := 'El SQL está vacío.'
  else if TieneVariasSentencias(ASql) then
    Result.Mensaje := 'Solo se admite una sentencia SQL.'
  else if ContienePalabra(ASql, 'DROP') or
          ContienePalabra(ASql, 'ALTER') or
          ContienePalabra(ASql, 'TRUNCATE') then
    Result.Mensaje := 'El SQL contiene una operación DDL no permitida.'
  else
  begin
    sTipoEsperado := NombreTipoSentencia(
      ADefinicion.TipoSentencia);
    sPrimerToken := PrimerToken(ASql);
    if (ADefinicion.TipoSentencia = tssCall) and
       (AMotor = mbSQLServer) then
      sTipoEsperado := 'EXEC';
    if (sPrimerToken <> sTipoEsperado) and
       not ((ADefinicion.TipoSentencia = tssSelect) and
            EsSelectConCte(ASql)) and
       not ((ADefinicion.TipoSentencia = tssCall) and
            (AMotor = mbSQLServer) and
            (sPrimerToken = 'EXECUTE')) then
      Result.Mensaje := Format(
        'Se esperaba una sentencia %s.', [sTipoEsperado])
    else
    begin
      oEsperados := ParametrosEsperados(
        ADefinicion.Parametros);
      oEncontrados := ExtraerParametros(ASql);
      try
        if ListasIguales(oEsperados, oEncontrados) then
        begin
          Result.EsValido := ValidarCamposResultado(
            ADefinicion,
            ASql,
            sMensajeCampos);
          if not Result.EsValido then
            Result.Mensaje := sMensajeCampos;
        end
        else
          Result.Mensaje := Format(
            'Parámetros esperados [%s], encontrados [%s].',
            [oEsperados.CommaText, oEncontrados.CommaText]);
      finally
        FreeAndNil(oEncontrados);
        FreeAndNil(oEsperados);
      end;
    end;
  end;
end;

function ValidarDefinicionSql(
  const ADefinicion: TDefinicionSql): TResultadoValidacionSql;
var
  eMotor: TMotorBBDD;
begin
  Result.EsValido := False;
  Result.Mensaje := '';
  Result.Huella := CalcularHuellaSql(
    ADefinicion.SqlBase);
  if Trim(ADefinicion.Repositorio) = '' then
    Result.Mensaje := 'El repositorio de la definición está vacío.'
  else if Trim(ADefinicion.Operacion) = '' then
    Result.Mensaje := 'La operación de la definición está vacía.'
  else if ADefinicion.Version <= 0 then
    Result.Mensaje := 'La versión de la definición debe ser mayor que cero.'
  else if ((ADefinicion.TipoSentencia = tssSelect) or
           (ADefinicion.Politica =
            pesPerfilLecturaConFallback)) and
          (Trim(ADefinicion.CamposResultado) = '') then
    Result.Mensaje :=
      'Una lectura debe declarar sus campos de salida obligatorios.'
  else if (ADefinicion.Politica =
           pesPerfilLecturaConFallback) and
          (not (ADefinicion.TipoSentencia in
            [tssSelect, tssCall])) then
    Result.Mensaje :=
      'La política de lectura con fallback solo admite consultas ' +
      'o procedimientos que devuelvan datos.'
  else if (ADefinicion.Politica =
           pesPerfilEscrituraTransaccional) and
          (ADefinicion.TipoSentencia = tssSelect) then
    Result.Mensaje :=
      'Una lectura no puede usar la política de escritura transaccional.'
  else
  begin
    Result := ValidarSql(
      ADefinicion,
      ADefinicion.SqlBase,
      mbMariaDB);
    if Result.EsValido then
      for eMotor := Succ(mbMariaDB) to High(TMotorBBDD) do
        if Result.EsValido and
           TieneVarianteSqlMotor(ADefinicion, eMotor) then
        begin
          Result := ValidarSql(
            ADefinicion,
            ObtenerSqlBaseMotor(ADefinicion, eMotor),
            eMotor);
        end;
  end;
end;

end.
