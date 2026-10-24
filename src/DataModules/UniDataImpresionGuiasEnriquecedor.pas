{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataImpresionGuiasEnriquecedor                             }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Enriquece consultas de informes con las tablas externas de sus guias.     }
{******************************************************************************}
unit UniDataImpresionGuiasEnriquecedor;

interface

uses
  System.Classes, Data.DB, Uni, inLibInformesGuiasCache,
  inLibImpresionPersistenciaIntf;

type
  TEnriquecedorGuiasImpresionUniDAC = class(
    TInterfacedObject,
    IEnriquecedorGuiasImpresion)
  private
    FConexion: TUniConnection;
    function NormalizarSql(const ASql: string): string;
    procedure CopiarParametros(AOrigen, ADestino: TUniQuery);
    function ObtenerCampos(
      AConsulta: TUniQuery;
      const ASql: string
    ): TStringList;
    function ObtenerColumnas(const ATabla: string): TStringList;
    function ConstruirSeleccion(
      AColumnas, ACampos: TStringList
    ): string;
    function ConstruirRelacion(
      const AMaestros, ADetalles: string
    ): string;
  public
    constructor Create(AConexion: TUniConnection);
    function Enriquecer(
      ADataSet: TDataSet;
      const AGuia: TInformeGuiaItem;
      out AError: string
    ): IRestauracionDatasetInforme;
  end;

implementation

uses
  System.SysUtils, DBAccess;

type
  TRestauracionDatasetInformeUniDAC = class(
    TInterfacedObject,
    IRestauracionDatasetInforme)
  private
    FConsulta: TUniQuery;
    FSqlOriginal: string;
    FRestaurado: Boolean;
  public
    constructor Create(
      AConsulta: TUniQuery;
      const ASqlOriginal: string);
    destructor Destroy; override;
    procedure Restaurar;
  end;

constructor TRestauracionDatasetInformeUniDAC.Create(
  AConsulta: TUniQuery;
  const ASqlOriginal: string);
begin
  inherited Create;
  FConsulta := AConsulta;
  FSqlOriginal := ASqlOriginal;
  FRestaurado := False;
end;

destructor TRestauracionDatasetInformeUniDAC.Destroy;
begin
  Restaurar;
  inherited;
end;

procedure TRestauracionDatasetInformeUniDAC.Restaurar;
var
  bEstabaAbierta: Boolean;
begin
  if not FRestaurado and Assigned(FConsulta) then
  begin
    bEstabaAbierta := FConsulta.Active;
    FConsulta.Close;
    FConsulta.SQL.Text := FSqlOriginal;
    if bEstabaAbierta then
    begin
      FConsulta.Open;
    end;
    FRestaurado := True;
  end;
end;

constructor TEnriquecedorGuiasImpresionUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TEnriquecedorGuiasImpresionUniDAC.NormalizarSql(
  const ASql: string
): string;
begin
  Result := TrimRight(ASql);
  while (Result <> '') and (Result[Length(Result)] = ';') do
  begin
    SetLength(Result, Length(Result) - 1);
    Result := TrimRight(Result);
  end;
end;

procedure TEnriquecedorGuiasImpresionUniDAC.CopiarParametros(
  AOrigen, ADestino: TUniQuery);
var
  iIndice: Integer;
  oOrigen: TUniParam;
begin
  for iIndice := 0 to ADestino.Params.Count - 1 do
  begin
    oOrigen := AOrigen.Params.FindParam(
      ADestino.Params[iIndice].Name);
    if Assigned(oOrigen) then
    begin
      ADestino.Params[iIndice].Value := oOrigen.Value;
    end
    else
    begin
      ADestino.Params[iIndice].Clear;
    end;
  end;
end;

function TEnriquecedorGuiasImpresionUniDAC.ObtenerCampos(
  AConsulta: TUniQuery;
  const ASql: string
): TStringList;
var
  oConsultaCampos: TUniQuery;
  iCampo: Integer;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  oConsultaCampos := TUniQuery.Create(nil);
  try
    try
      oConsultaCampos.Connection := FConexion;
      oConsultaCampos.SQL.Text :=
        'SELECT * FROM (' + ASql + ') X_GUIAS WHERE 1 = 0';
      CopiarParametros(AConsulta, oConsultaCampos);
      oConsultaCampos.Open;
      for iCampo := 0 to oConsultaCampos.FieldCount - 1 do
      begin
        Result.Add(oConsultaCampos.Fields[iCampo].FieldName);
      end;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    FreeAndNil(oConsultaCampos);
  end;
end;

function TEnriquecedorGuiasImpresionUniDAC.ObtenerColumnas(
  const ATabla: string
): TStringList;
var
  oConsulta: TUniQuery;
begin
  Result := TStringList.Create;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT COLUMN_NAME ' +
        '  FROM information_schema.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = :TABLA ' +
        ' ORDER BY ORDINAL_POSITION';
      oConsulta.ParamByName('TABLA').AsString := ATabla;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        Result.Add(oConsulta.FieldByName('COLUMN_NAME').AsString);
        oConsulta.Next;
      end;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TEnriquecedorGuiasImpresionUniDAC.ConstruirSeleccion(
  AColumnas, ACampos: TStringList
): string;
var
  iColumna: Integer;
  iSufijo: Integer;
  sColumna: string;
  sAlias: string;
begin
  Result := '';
  for iColumna := 0 to AColumnas.Count - 1 do
  begin
    sColumna := AColumnas[iColumna];
    sAlias := sColumna;
    if ACampos.IndexOf(sAlias) >= 0 then
    begin
      iSufijo := 1;
      while ACampos.IndexOf(sColumna + IntToStr(iSufijo)) >= 0 do
      begin
        Inc(iSufijo);
      end;
      sAlias := sColumna + IntToStr(iSufijo);
    end;
    ACampos.Add(sAlias);
    if Result <> '' then
    begin
      Result := Result + ', ';
    end;
    Result := Result + 'EXT_GUIA.' + sColumna + ' AS ' + sAlias;
  end;
end;

function TEnriquecedorGuiasImpresionUniDAC.ConstruirRelacion(
  const AMaestros, ADetalles: string
): string;
var
  oMaestros: TStringList;
  oDetalles: TStringList;
  iCampo: Integer;
  iPares: Integer;
begin
  Result := '';
  oMaestros := TStringList.Create;
  oDetalles := TStringList.Create;
  try
    oMaestros.StrictDelimiter := True;
    oMaestros.Delimiter := ';';
    oMaestros.DelimitedText := AMaestros;
    oDetalles.StrictDelimiter := True;
    oDetalles.Delimiter := ';';
    oDetalles.DelimitedText := ADetalles;
    iPares := oMaestros.Count;
    if oDetalles.Count < iPares then
    begin
      iPares := oDetalles.Count;
    end;
    for iCampo := 0 to iPares - 1 do
    begin
      if (Trim(oMaestros[iCampo]) <> '') and
         (Trim(oDetalles[iCampo]) <> '') then
      begin
        if Result <> '' then
        begin
          Result := Result + ' AND ';
        end;
        Result := Result +
          'EXT_GUIA.' + Trim(oDetalles[iCampo]) +
          ' = M_GUIA.' + Trim(oMaestros[iCampo]);
      end;
    end;
  finally
    FreeAndNil(oDetalles);
    FreeAndNil(oMaestros);
  end;
end;

function TEnriquecedorGuiasImpresionUniDAC.Enriquecer(
  ADataSet: TDataSet;
  const AGuia: TInformeGuiaItem;
  out AError: string
): IRestauracionDatasetInforme;
var
  oConsulta: TUniQuery;
  oCampos: TStringList;
  oColumnas: TStringList;
  sOriginal: string;
  sBase: string;
  sSeleccion: string;
  sRelacion: string;
begin
  Result := nil;
  AError := '';
  if not (ADataSet is TUniQuery) then
  begin
    AError := 'el dataset master no es una consulta UniDAC';
  end
  else
  begin
    oConsulta := TUniQuery(ADataSet);
    sOriginal := oConsulta.SQL.Text;
    sBase := NormalizarSql(sOriginal);
    if sBase = '' then
    begin
      AError := 'la consulta master no contiene SQL';
    end
    else
    begin
      oCampos := nil;
      oColumnas := nil;
      try
        oCampos := ObtenerCampos(oConsulta, sBase);
        oColumnas := ObtenerColumnas(AGuia.Tabla);
        sSeleccion := ConstruirSeleccion(oColumnas, oCampos);
        sRelacion := ConstruirRelacion(
          AGuia.MasterFields,
          AGuia.DetailFields);
        if (sSeleccion = '') or (sRelacion = '') then
        begin
          AError := 'la guia no define columnas o relaciones validas';
        end
        else
        begin
          oConsulta.Close;
          oConsulta.SQL.Text :=
            'SELECT M_GUIA.*, ' + sSeleccion + ' ' +
            'FROM (' + sBase + ') M_GUIA ' +
            'LEFT JOIN ' + AGuia.Tabla +
            ' EXT_GUIA ON ' + sRelacion;
          oConsulta.Open;
          Result := TRestauracionDatasetInformeUniDAC.Create(
            oConsulta,
            sOriginal);
        end;
      except
        on E: Exception do
        begin
          AError := E.Message;
          oConsulta.Close;
          oConsulta.SQL.Text := sOriginal;
        end;
      end;
      FreeAndNil(oColumnas);
      FreeAndNil(oCampos);
    end;
  end;
end;

end.
