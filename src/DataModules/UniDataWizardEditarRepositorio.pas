unit UniDataWizardEditarRepositorio;

interface

uses
  Uni, inLibWizardEditarPersistenciaIntf;

function CrearRepositorioWizardEditarUniDAC(
  AConexion: TUniConnection): IRepositorioWizardEditar;

implementation

uses
  System.Classes, System.SysUtils, System.Variants, Data.DB;

type
  TResultadoGuiasWizardEditarUniDAC = class(
    TInterfacedObject,
    IResultadoGuiasWizardEditar)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioWizardEditarUniDAC = class(
    TInterfacedObject,
    IRepositorioWizardEditar)
  private
    FConexion: TUniConnection;
    procedure RellenarParametrosDummy(AConsulta: TUniQuery);
    function CamposActivos(ADataSet: TDataSet): TCadenasWizardEditar;
    function ExtraerTablaFromSql(const ASql: string): string;
    function ListarCamposSql(const ASql: string): TCadenasWizardEditar;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarFormatos(
      const AInforme, AUsuario, AGrupo, ATodos: string): TCadenasWizardEditar;
    function PrepararGuias(
      const AInforme: string): IResultadoGuiasWizardEditar;
    function ListarTablas: TCadenasWizardEditar;
    function ListarCamposTabla(
      const ATabla: string): TCamposTablaWizardEditar;
    function ResolverCamposDataSet(
      ADataSet: TDataSet): TCadenasWizardEditar;
  end;

constructor TResultadoGuiasWizardEditarUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoGuiasWizardEditarUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited Destroy;
end;

function TResultadoGuiasWizardEditarUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioWizardEditarUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioWizardEditarUniDAC.ListarFormatos(
  const AInforme, AUsuario, AGrupo, ATodos: string): TCadenasWizardEditar;
var
  iFormato: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT VALUE_USUPER FROM fza_usuarios_perfiles ' +
      'WHERE KEY_USUPER = :KEY AND SUBKEY_USUPER <> '''' ' +
      'AND VALUE_USUPER NOT LIKE ''Predet:%'' ' +
      'AND (USUARIO_GRUPO_USUPER = :USU ' +
      'OR USUARIO_GRUPO_USUPER = :GRP ' +
      'OR USUARIO_GRUPO_USUPER = :ALL) ' +
      'ORDER BY VALUE_USUPER';
    oConsulta.ParamByName('KEY').AsString := AInforme;
    oConsulta.ParamByName('USU').AsString := AUsuario;
    oConsulta.ParamByName('GRP').AsString := AGrupo;
    oConsulta.ParamByName('ALL').AsString := ATodos;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFormato := Length(Result);
      SetLength(Result, iFormato + 1);
      Result[iFormato] := oConsulta.FieldByName('VALUE_USUPER').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioWizardEditarUniDAC.PrepararGuias(
  const AInforme: string): IResultadoGuiasWizardEditar;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT * FROM fza_informes_guias ' +
      'WHERE INFORME_INFGUI = :INF ' +
      'ORDER BY FORMATO_INFGUI, ORDEN_INFGUI, CODIGO_INFGUI';
    oConsulta.ParamByName('INF').AsString := AInforme;
    oConsulta.Open;
    Result := TResultadoGuiasWizardEditarUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TRepositorioWizardEditarUniDAC.ListarTablas: TCadenasWizardEditar;
var
  iTabla: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT TABLE_NAME FROM information_schema.TABLES ' +
      'WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iTabla := Length(Result);
      SetLength(Result, iTabla + 1);
      Result[iTabla] := oConsulta.FieldByName('TABLE_NAME').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioWizardEditarUniDAC.ListarCamposTabla(
  const ATabla: string): TCamposTablaWizardEditar;
var
  iCampo: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COLUMN_NAME, COLUMN_KEY FROM information_schema.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :TAB ' +
      'ORDER BY ORDINAL_POSITION';
    oConsulta.ParamByName('TAB').AsString := ATabla;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iCampo := Length(Result);
      SetLength(Result, iCampo + 1);
      Result[iCampo].Nombre :=
        oConsulta.FieldByName('COLUMN_NAME').AsString;
      Result[iCampo].EsClavePrimaria := SameText(
        oConsulta.FieldByName('COLUMN_KEY').AsString,
        'PRI');
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioWizardEditarUniDAC.RellenarParametrosDummy(
  AConsulta: TUniQuery);
var
  i: Integer;
begin
  for i := 0 to AConsulta.Params.Count - 1 do
  begin
    case AConsulta.Params[i].DataType of
      ftDate, ftDateTime, ftTime, ftTimeStamp:
        AConsulta.Params[i].AsDateTime := Date;
      ftInteger, ftSmallint, ftWord, ftLargeint, ftAutoInc:
        AConsulta.Params[i].AsInteger := 0;
      ftFloat, ftCurrency, ftBCD, ftFMTBcd:
        AConsulta.Params[i].AsFloat := 0;
      ftString, ftWideString, ftFixedChar, ftFixedWideChar,
        ftMemo, ftWideMemo:
        AConsulta.Params[i].AsString := '';
    else
      AConsulta.Params[i].Clear;
    end;
  end;
end;

function TRepositorioWizardEditarUniDAC.CamposActivos(
  ADataSet: TDataSet): TCadenasWizardEditar;
var
  i: Integer;
begin
  SetLength(Result, ADataSet.FieldCount);
  for i := 0 to ADataSet.FieldCount - 1 do
    Result[i] := ADataSet.Fields[i].FieldName;
end;

function TRepositorioWizardEditarUniDAC.ExtraerTablaFromSql(
  const ASql: string): string;
var
  i: Integer;
  iFin: Integer;
  iFrom: Integer;
  iInicio: Integer;
  sMinusculas: string;
begin
  Result := '';
  sMinusculas := LowerCase(ASql);
  iFrom := Pos('from ', sMinusculas);
  if iFrom > 0 then
  begin
    iInicio := iFrom + Length('from ');
    while (iInicio <= Length(sMinusculas)) and
          CharInSet(sMinusculas[iInicio], [' ', #9, #10, #13]) do
      Inc(iInicio);
    if (iInicio <= Length(sMinusculas)) and
       (sMinusculas[iInicio] <> '(') then
    begin
      iFin := iInicio;
      while (iFin <= Length(sMinusculas)) and
            CharInSet(sMinusculas[iFin],
              ['a'..'z', '0'..'9', '_', '`', '.']) do
      begin
        Inc(iFin);
      end;
      Result := Copy(ASql, iInicio, iFin - iInicio);
      i := LastDelimiter('.', Result);
      if i > 0 then
        Result := Copy(Result, i + 1, MaxInt);
      Result := StringReplace(Result, '`', '', [rfReplaceAll]);
    end;
  end;
end;

function TRepositorioWizardEditarUniDAC.ListarCamposSql(
  const ASql: string): TCadenasWizardEditar;
var
  camposTabla: TCamposTablaWizardEditar;
  i: Integer;
  sTabla: string;
begin
  SetLength(Result, 0);
  sTabla := ExtraerTablaFromSql(ASql);
  if sTabla <> '' then
  begin
    camposTabla := ListarCamposTabla(sTabla);
    SetLength(Result, Length(camposTabla));
    for i := 0 to Length(camposTabla) - 1 do
      Result[i] := camposTabla[i].Nombre;
  end;
end;

function TRepositorioWizardEditarUniDAC.ResolverCamposDataSet(
  ADataSet: TDataSet): TCadenasWizardEditar;
var
  bAbierto: Boolean;
  i: Integer;
  oConsulta: TUniQuery;
  oTemporal: TUniQuery;
  sSql: string;
  valores: TArray<Variant>;
begin
  SetLength(Result, 0);
  if ADataSet <> nil then
  begin
    bAbierto := ADataSet.Active;
    oConsulta := nil;
    if ADataSet is TUniQuery then
      oConsulta := TUniQuery(ADataSet);
    try
      if (not bAbierto) and (oConsulta <> nil) then
      begin
        SetLength(valores, oConsulta.Params.Count);
        for i := 0 to oConsulta.Params.Count - 1 do
          valores[i] := oConsulta.Params[i].Value;
        RellenarParametrosDummy(oConsulta);
        try
          oConsulta.Open;
        except
          on E: Exception do
            SetLength(Result, 0);
        end;
      end;
      if ADataSet.Active then
        Result := CamposActivos(ADataSet);
    finally
      if (not bAbierto) and ADataSet.Active then
        ADataSet.Close;
      if (oConsulta <> nil) and (Length(valores) > 0) then
        for i := 0 to oConsulta.Params.Count - 1 do
          oConsulta.Params[i].Value := valores[i];
    end;
    if (Length(Result) = 0) and (oConsulta <> nil) then
      Result := ListarCamposSql(oConsulta.SQL.Text);
    if (Length(Result) = 0) and (oConsulta <> nil) then
    begin
      sSql := TrimRight(oConsulta.SQL.Text);
      while (sSql <> '') and (sSql[Length(sSql)] = ';') do
        Delete(sSql, Length(sSql), 1);
      if sSql <> '' then
      begin
        oTemporal := TUniQuery.Create(nil);
        try
          oTemporal.Connection := FConexion;
          oTemporal.SQL.Text :=
            'SELECT * FROM (' + sSql + ') X_FZA_GUIAS WHERE 1=0';
          RellenarParametrosDummy(oTemporal);
          try
            oTemporal.Open;
            Result := CamposActivos(oTemporal);
          except
            on E: Exception do
              SetLength(Result, 0);
          end;
        finally
          FreeAndNil(oTemporal);
        end;
      end;
    end;
  end;
end;

function CrearRepositorioWizardEditarUniDAC(
  AConexion: TUniConnection): IRepositorioWizardEditar;
begin
  Result := TRepositorioWizardEditarUniDAC.Create(AConexion);
end;

end.
