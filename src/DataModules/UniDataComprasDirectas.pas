{******************************************************************************}
{  Módulo:       UniDataComprasDirectas                                        }
{    Tipo:       Persistencia                                                  }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{******************************************************************************}
unit UniDataComprasDirectas;

interface

uses
  System.Classes, Data.DB, Uni, inLibParametrosIntf, inLibComprasDirectas;

procedure CargarSeriesModalidadCompra(AConexion: TUniConnection;
  const AEmpresa: string; AModalidad: TModalidadCompraDirecta;
  AElementos: TStrings; const AProveedor: string = '');
procedure ProponerSerieCompraDirecta(AConexion: TUniConnection;
  ACabecera: TDataSet; const AUsuario: string);
procedure ValidarCompraDirecta(AConexion: TUniConnection;
  ACabecera: TDataSet; const AEmpresaLocal: string;
  const AParametros: IParametrosAplicacion);
procedure AplicarCompensacionCompraDirecta(ACabecera: TDataSet);

implementation

uses
  inLibMsgCompras, System.SysUtils, System.Variants,
  UniDataSeriesEmpresaRepositorio, inLibSeriesEmpresaPersistenciaIntf;

const
  fmodalidad = 'MODALIDAD_FACC';
  fempresa = 'CODIGO_EMP_FACC';
  fserie = 'SERIE_FACC';
  fnumero = 'NUMERO_FACC';
  fcompensacion = 'TOTAL_COMPENSACION_FACC';
  fporcentaje = 'PORCENTAJE_COMPENSACION_FACC';
  SQL_SERIES_COMPRA =
    'SELECT V.EMPSER FROM vi_empresas_series V ' +
    'JOIN fza_empresas_series S ' +
    'ON S.CODIGO_SERIE_EMPSER = V.CODIGO_SERIE_EMPSER ' +
    'WHERE V.CODIGO_EMP_EMPSER = :EMPRESA AND V.TIPO_DOC_EMPSER = ''FP'' ' +
    'AND ((:SUBTIPO = '''' AND COALESCE(V.SUBTIPO_EMPSER, '''') ' +
    'NOT IN (''AUTOFAC'', ''REAGP'')) OR V.SUBTIPO_EMPSER = :SUBTIPO) ' +
    'AND (V.FECHA_DESDE_EMPSER IS NULL OR V.FECHA_DESDE_EMPSER <= :FECHA) ' +
    'AND (V.FECHA_HASTA_EMPSER IS NULL OR V.FECHA_HASTA_EMPSER >= :FECHA) ' +
    'AND (:SUBTIPO <> ''AUTOFAC'' OR S.CODIGO_PRV_EMPSER = :PROVEEDOR) ' +
    'GROUP BY V.EMPSER ORDER BY MAX(V.ESDEFECTO_EMPSER) DESC, V.EMPSER';


function SubtipoCompra(AModalidad: TModalidadCompraDirecta): string;
begin
  Result := '';
  if AModalidad <> mcdOrdinaria then
    Result := CodigoModalidadCompra(AModalidad);
end;

procedure CargarSeriesModalidadCompra(AConexion: TUniConnection;
  const AEmpresa: string; AModalidad: TModalidadCompraDirecta;
  AElementos: TStrings; const AProveedor: string);
var
  oConsulta: TUniQuery;
begin
  AElementos.Clear;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_SERIES_COMPRA;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('SUBTIPO').AsString := SubtipoCompra(AModalidad);
    oConsulta.ParamByName('FECHA').AsDate := Date;
    oConsulta.ParamByName('PROVEEDOR').AsString := AProveedor;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      AElementos.Add(oConsulta.FieldByName('EMPSER').AsString);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure ProponerSerieCompraDirecta(AConexion: TUniConnection;
  ACabecera: TDataSet; const AUsuario: string);
var
  oSeries: TStringList;
  oRepositorio: IRepositorioSeriesEmpresa;
  oModalidad: TModalidadCompraDirecta;
  sEmpresa, sSerie, sProveedor: string;
begin
  oModalidad := ModalidadCompra(ACabecera.FieldByName(fmodalidad).AsString);
  // El número se reserva en BeforePost. Después es inmutable.
  if (oModalidad <> mcdOrdinaria) and
     (StrToInt64Def(ACabecera.FieldByName(fnumero).AsString, 0) = 0) and
     (Trim(ACabecera.FieldByName('CODIGO_PRV_FACC').AsString) <> '') and
     (ACabecera.FieldByName('CODIGO_PRV_FACC').AsString <> '0') then
  begin
    sEmpresa := ACabecera.FieldByName(fempresa).AsString;
    sProveedor := ACabecera.FieldByName('CODIGO_PRV_FACC').AsString;
    oSeries := TStringList.Create;
    try
      CargarSeriesModalidadCompra(AConexion, sEmpresa, oModalidad,
        oSeries, sProveedor);
      if oSeries.Count = 0 then
      begin
        sSerie := SerieCompraDirectaDefecto(sEmpresa, sProveedor, oModalidad);
        oRepositorio := CrearRepositorioSeriesEmpresaUniDAC(AConexion);
        if oRepositorio.EmpresaQueUsaSerie(sEmpresa, sSerie, '') <> '' then
          raise Exception.CreateFmt(SSerieCompraCompartida, [sSerie]);
        oRepositorio.CrearSerieSiFalta(sEmpresa, '', '', sSerie, 'FP',
          SubtipoCompra(oModalidad), AUsuario);
        if oModalidad = mcdAutofactura then
          AConexion.ExecSQL('UPDATE fza_empresas_series ' +
            'SET CODIGO_PRV_EMPSER = :PROVEEDOR ' +
            'WHERE CODIGO_EMP_EMPSER = :EMPRESA AND EMPSER = :SERIE ' +
            'AND TIPO_DOC_EMPSER = ''FP'' AND SUBTIPO_EMPSER = ''AUTOFAC'' ' +
            'AND COALESCE(CODIGO_PRV_EMPSER, '''') = ''''',
            [sProveedor, sEmpresa, sSerie]);
        CargarSeriesModalidadCompra(AConexion, sEmpresa, oModalidad,
        oSeries, sProveedor);
      end;
      if oSeries.Count = 0 then
        raise Exception.CreateFmt(SSerieCompraDirectaInvalida,
          [SubtipoCompra(oModalidad)]);
      if oSeries.IndexOf(ACabecera.FieldByName(fserie).AsString) < 0 then
        ACabecera.FieldByName(fserie).AsString := oSeries[0];
    finally
      FreeAndNil(oSeries);
    end;
  end;
end;

procedure ValidarIdentidadNumerada(ACabecera: TDataSet);
var
  sCampo: string;
  oCampo: TField;
begin
  if (ACabecera.State = dsEdit) and
     (StrToInt64Def(VarToStr(
       ACabecera.FieldByName(fnumero).OldValue), 0) > 0) then
    for sCampo in TArray<string>.Create(fmodalidad, fempresa,
      fserie, fnumero, 'CODIGO_PRV_FACC') do
    begin
      oCampo := ACabecera.FieldByName(sCampo);
      if VarToStr(oCampo.OldValue) <> oCampo.AsString then
        raise Exception.Create(SModalidadNumerada);
    end;
end;

procedure ValidarReservaSerie(AConexion: TUniConnection;
  ACabecera: TDataSet; AModalidad: TModalidadCompraDirecta);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM vi_empresas_series V JOIN fza_empresas_series S ' +
      'ON S.CODIGO_SERIE_EMPSER = V.CODIGO_SERIE_EMPSER ' +
      'WHERE V.EMPSER = :SERIE ' +
      'AND V.TIPO_DOC_EMPSER = ''FP'' AND ' +
      '(V.CODIGO_EMP_EMPSER <> :EMPRESA OR ' +
      '(CASE WHEN V.SUBTIPO_EMPSER IN (''AUTOFAC'', ''REAGP'') ' +
      'THEN V.SUBTIPO_EMPSER ELSE '''' END) <> :SUBTIPO OR ' +
      '(:SUBTIPO = ''AUTOFAC'' AND ' +
      'COALESCE(S.CODIGO_PRV_EMPSER, '''') <> :PROVEEDOR)) LIMIT 1';
    oConsulta.ParamByName('SERIE').AsString :=
      ACabecera.FieldByName(fserie).AsString;
    oConsulta.ParamByName('EMPRESA').AsString :=
      ACabecera.FieldByName(fempresa).AsString;
    oConsulta.ParamByName('SUBTIPO').AsString := SubtipoCompra(AModalidad);
    oConsulta.ParamByName('PROVEEDOR').AsString :=
      ACabecera.FieldByName('CODIGO_PRV_FACC').AsString;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise Exception.CreateFmt(SSerieCompraCompartida,
        [ACabecera.FieldByName(fserie).AsString]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure ValidarSerieCompra(AConexion: TUniConnection;
  ACabecera: TDataSet; AModalidad: TModalidadCompraDirecta);
var
  oConsulta: TUniQuery;
  oSeries: TStringList;
begin
  ValidarReservaSerie(AConexion, ACabecera, AModalidad);
  oSeries := TStringList.Create;
  oConsulta := TUniQuery.Create(nil);
  try
    // Los documentos históricos conservan su serie aunque deje de estar
    // vigente. Una nueva reserva exige una serie vigente del subtipo.
    if (AModalidad <> mcdOrdinaria) and
       (StrToInt64Def(ACabecera.FieldByName(fnumero).AsString, 0) = 0) and
     (Trim(ACabecera.FieldByName('CODIGO_PRV_FACC').AsString) <> '') and
     (ACabecera.FieldByName('CODIGO_PRV_FACC').AsString <> '0') then
    begin
      CargarSeriesModalidadCompra(AConexion,
        ACabecera.FieldByName(fempresa).AsString, AModalidad, oSeries,
        ACabecera.FieldByName('CODIGO_PRV_FACC').AsString);
      if oSeries.IndexOf(ACabecera.FieldByName(fserie).AsString) < 0 then
        raise Exception.CreateFmt(SSerieCompraDirectaInvalida,
          [SubtipoCompra(AModalidad)]);
    end;
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_facturas_compra WHERE SERIE_FACC = :SERIE ' +
      'AND (MODALIDAD_FACC <> :MODALIDAD OR CODIGO_EMP_FACC <> :EMPRESA ' +
      'OR (:MODALIDAD = ''AUTOFAC'' AND CODIGO_PRV_FACC <> :PROVEEDOR)) ' +
      'LIMIT 1';
    oConsulta.ParamByName('SERIE').AsString :=
      ACabecera.FieldByName(fserie).AsString;
    oConsulta.ParamByName('MODALIDAD').AsString :=
      CodigoModalidadCompra(AModalidad);
    oConsulta.ParamByName('EMPRESA').AsString :=
      ACabecera.FieldByName(fempresa).AsString;
    oConsulta.ParamByName('PROVEEDOR').AsString :=
      ACabecera.FieldByName('CODIGO_PRV_FACC').AsString;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise Exception.CreateFmt(SSerieCompraCompartida,
        [ACabecera.FieldByName(fserie).AsString]);
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oSeries);
  end;
end;

procedure ValidarProveedorHabilitado(AConexion: TUniConnection;
  ACabecera: TDataSet);
var
  oProveedor: TUniQuery;
begin
    oProveedor := TUniQuery.Create(nil);
    try
      oProveedor.Connection := AConexion;
      oProveedor.SQL.Text :=
        'SELECT ESFACTURACION_DIRECTA_PRV FROM fza_proveedores ' +
        'WHERE CODIGO_PRV_PRV = :PROVEEDOR';
      oProveedor.ParamByName('PROVEEDOR').AsString :=
        ACabecera.FieldByName('CODIGO_PRV_FACC').AsString;
      oProveedor.Open;
      if oProveedor.IsEmpty or
         (oProveedor.FieldByName('ESFACTURACION_DIRECTA_PRV').AsString <> 'S')
      then
        raise Exception.Create(SProveedorNoDirecto);
    finally
      FreeAndNil(oProveedor);
    end;
end;

procedure ValidarCompraDirecta(AConexion: TUniConnection;
  ACabecera: TDataSet; const AEmpresaLocal: string;
  const AParametros: IParametrosAplicacion);
var
  oModalidad: TModalidadCompraDirecta;
  bNuevoTratamiento: Boolean;
begin
  oModalidad := ModalidadCompra(ACabecera.FieldByName(fmodalidad).AsString);
  if oModalidad <> mcdOrdinaria then
  begin
    ValidarIdentidadNumerada(ACabecera);
    ValidarProveedorHabilitado(AConexion, ACabecera);
    if ACabecera.FieldByName(fempresa).AsString <> AEmpresaLocal then
      raise Exception.Create(SEmpresaCompraDirecta);
    bNuevoTratamiento := (ACabecera.State = dsInsert) or
      (VarToStr(ACabecera.FieldByName(fmodalidad).OldValue) <> 'REAGP');
    if (oModalidad = mcdReagp) and bNuevoTratamiento and
       ((not Assigned(AParametros)) or
        (not AParametros.GetBool('appUsarReagp', False))) then
      raise Exception.Create(SReagpNoHabilitado);
    if (oModalidad = mcdAutofactura) and
       (ACabecera.FieldByName('ESACUERDO_AUTOFAC_FACC').AsString <> 'S') then
      raise Exception.Create(SAcuerdoAutofactura);
    if (Trim(ACabecera.FieldByName('CODIGO_PRV_FACC').AsString) = '') or
       (ACabecera.FieldByName('CODIGO_PRV_FACC').AsString = '0') then
      raise Exception.Create(SDatosFiscalesCompra);
    if (oModalidad = mcdReagp) and
       (ACabecera.FieldByName(fporcentaje).AsCurrency <= 0) then
      raise Exception.Create(SCompensacionObligatoria);
  end;
  ValidarSerieCompra(AConexion, ACabecera, oModalidad);
end;

procedure AplicarCompensacionCompraDirecta(ACabecera: TDataSet);
var
  dImporte: Currency;
begin
  if ACabecera.State in dsEditModes then
  begin
    dImporte := 0;
    if ModalidadCompra(ACabecera.FieldByName(fmodalidad).AsString) =
       mcdReagp then
      dImporte := CalcularCompensacionAgricola(
        ACabecera.FieldByName('TOTAL_BASES_FACC').AsCurrency,
        ACabecera.FieldByName(fporcentaje).AsCurrency);
    ACabecera.FieldByName(fcompensacion).AsCurrency := dImporte;
    if ModalidadCompra(ACabecera.FieldByName(fmodalidad).AsString) =
       mcdReagp then
    begin
      ACabecera.FieldByName('TOTAL_FACC').AsCurrency :=
        ACabecera.FieldByName('TOTAL_BASES_FACC').AsCurrency + dImporte;
      ACabecera.FieldByName('TOTAL_LIQUIDO_FACC').AsCurrency :=
        ACabecera.FieldByName('TOTAL_FACC').AsCurrency -
        ACabecera.FieldByName('TOTAL_RETENCION_FACC').AsCurrency -
        ACabecera.FieldByName('TOTAL_DTO_FINANCIERO_FACC').AsCurrency;
    end;
  end;
end;

end.
