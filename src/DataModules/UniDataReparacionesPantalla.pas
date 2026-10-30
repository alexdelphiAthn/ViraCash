{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReparacionesPantalla                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Datos de la parte de reparaciones de «Reparaciones y garantías»: líneas   }
{    del expediente (detalle de la lista), liquidaciones, tipos de servicio    }
{    y modo de liquidación de los proveedores (editables) y hojas de entrega   }
{    y de liquidación. Las operaciones van por los contratos del repositorio. }
{******************************************************************************}
unit UniDataReparacionesPantalla;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibReparaciones, inLibReparacionesIntf, inLibReparacionesDocumentos;

type
  TDatosPantallaReparaciones = class(TComponent)
  private
    FConexion: TUniConnection;
    FUsuario: string;
    FCatalogo: ICatalogoReparaciones;
    FReparaciones: IRepositorioReparaciones;
    FLiquidaciones: ILiquidacionesReparaciones;
    FLineas: TUniQuery;
    FdsLineas: TDataSource;
    FListaLiquidaciones: TUniQuery;
    FdsLiquidaciones: TDataSource;
    FTipos: TUniQuery;
    FdsTipos: TDataSource;
    FExternos: TUniQuery;
    FdsExternos: TDataSource;
    function NuevaConsulta(const ASql: string): TUniQuery;
    function NuevoOrigen(ADatos: TDataSet): TDataSource;
    procedure TiposNewRecord(DataSet: TDataSet);
    procedure TiposBeforePost(DataSet: TDataSet);
    procedure TiposBeforeDelete(DataSet: TDataSet);
    function Tienda(const AAlmacen: string): TTiendaHojaReparacion;
    function LineasHoja(const AWhere: string;
      AId: Int64): TArray<TLineaHojaReparacion>;
  public
    constructor CreateDatos(AOwner: TComponent; AConexion: TUniConnection;
      const AUsuario: string);
    // Las líneas siguen al expediente de la lista (campo ID_GAR).
    procedure AsignarMaestro(ADatos: TDataSource);
    procedure RefrescarLineas;
    procedure RefrescarLiquidaciones;
    function Lineas: TDataSource;
    function Liquidaciones: TDataSource;
    function TiposEditables: TDataSource;
    function ExternosEditables: TDataSource;
    // Hoja de entrega de las líneas de un externo (AIds, una por línea).
    function HojaEntrega(const AIds: TArray<Int64>;
      const AAlmacen: string): THojaReparaciones;
    function HojaLiquidacion(ALiquidacion: Int64): THojaReparaciones;
    property Catalogo: ICatalogoReparaciones read FCatalogo;
    property Reparaciones: IRepositorioReparaciones read FReparaciones;
    property LiquidacionesRepositorio: ILiquidacionesReparaciones
      read FLiquidaciones;
  end;

implementation

uses
  System.SysUtils, inLibMsgReparaciones, inLibErroresBBDD,
  UniDataReparacionesRepositorio;

const
  SQL_LINEAS =
    'SELECT L.ID_GARLIN, L.ID_GAR_GARLIN, L.LINEA_GARLIN, ' +
    '       L.TIPO_LINEA_GARLIN, L.CODIGO_GARTIP_GARLIN, ' +
    '       L.DESCRIPCION_GARLIN, L.TIPO_EJECUTOR_GARLIN, ' +
    '       L.CODIGO_EMPL_GARLIN, L.CODIGO_PRV_GARLIN, ' +
    '       COALESCE(E.NOMBRE_EMPL, P.RAZON_SOCIAL_PRV, '''') AS EJECUTOR, ' +
    '       L.CODIGO_UNIDAD_GARLIN, L.CANTIDAD_GARLIN, ' +
    '       L.PRECIO_CLIENTE_GARLIN, L.PRECIO_COSTE_GARLIN, ' +
    '       L.CANTIDAD_GARLIN * L.PRECIO_CLIENTE_GARLIN AS IMPORTE_CLIENTE, ' +
    '       L.CANTIDAD_GARLIN * L.PRECIO_COSTE_GARLIN AS IMPORTE_COSTE, ' +
    '       L.FECHA_INICIO_GARLIN, L.FECHA_FIN_GARLIN, ' +
    '       L.ESINCIDENCIA_GARLIN, L.INCIDENCIA_GARLIN, ' +
    '       L.ID_GARLIQ_GARLIN, L.ID_GARLIQ_CARGO_GARLIN ' +
    '  FROM fza_garantias_lineas L ' +
    '  LEFT JOIN fza_empleados E ON E.CODIGO_EMPL = L.CODIGO_EMPL_GARLIN ' +
    '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = L.CODIGO_PRV_GARLIN ' +
    ' WHERE L.ID_GAR_GARLIN = :ID_GAR ' +
    ' ORDER BY L.LINEA_GARLIN';
  SQL_LIQUIDACIONES =
    'SELECT Q.ID_GARLIQ, Q.SENTIDO_GARLIQ, Q.CODIGO_EMP_GARLIQ, ' +
    '       Q.CODIGO_PRV_GARLIQ, COALESCE(P.RAZON_SOCIAL_PRV, '''') ' +
    '         AS RAZON_SOCIAL_PRV, Q.FECHA_GARLIQ, Q.FECHA_HASTA_GARLIQ, ' +
    '       Q.CANTIDAD_LINEAS_GARLIQ, Q.TOTAL_GARLIQ, Q.TIPO_DOC_GARLIQ, ' +
    '       Q.SERIE_DOC_GARLIQ, Q.NUMERO_DOC_GARLIQ, Q.FECHA_ABONO_GARLIQ, ' +
    '       Q.USUARIO_ALTA ' +
    '  FROM fza_garantias_liquidaciones Q ' +
    '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = Q.CODIGO_PRV_GARLIQ ' +
    ' ORDER BY Q.ID_GARLIQ DESC';
  SQL_TIPOS =
    'SELECT T.CODIGO_GARTIP, T.CATEGORIA_GARTIP, T.DESCRIPCION_GARTIP, ' +
    '       T.MODALIDAD_GARTIP, T.ESPRESUPUESTO_GARTIP, ' +
    '       T.PRECIO_CLIENTE_GARTIP, T.PRECIO_COSTE_GARTIP, ' +
    '       T.CANTIDAD_GARTIP, T.MODO_COBRO_GARTIP, T.DIAS_PLAZO_GARTIP, ' +
    '       T.CODIGO_ART_GARTIP, T.TIPO_EJECUTOR_GARTIP, ' +
    '       T.CODIGO_EMPL_GARTIP, T.CODIGO_PRV_GARTIP, T.ORDEN_GARTIP, ' +
    '       T.ESACTIVO_GARTIP, T.INSTANTE_ALTA, T.USUARIO_ALTA, ' +
    '       T.INSTANTE_MODIF, T.USUARIO_MODIF ' +
    '  FROM fza_garantias_tipos T ' +
    ' ORDER BY T.CATEGORIA_GARTIP, T.ORDEN_GARTIP, T.DESCRIPCION_GARTIP';
  // Los que ya trabajan como externos primero.
  SQL_EXTERNOS =
    'SELECT P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, ' +
    '       P.ESFACTURACION_DIRECTA_PRV, P.MODO_LIQUIDACION_SERVICIOS_PRV ' +
    '  FROM fza_proveedores P ' +
    ' WHERE P.ESACTIVO_PRV = ''S'' ' +
    ' ORDER BY (P.MODO_LIQUIDACION_SERVICIOS_PRV IS NOT NULL ' +
    '           OR P.ESFACTURACION_DIRECTA_PRV = ''S'') DESC, ' +
    '          P.RAZON_SOCIAL_PRV';

constructor TDatosPantallaReparaciones.CreateDatos(AOwner: TComponent;
  AConexion: TUniConnection; const AUsuario: string);
var
  oRepositorio: TRepositorioReparacionesUniDAC;
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FUsuario := AUsuario;
  oRepositorio := TRepositorioReparacionesUniDAC.Create(AConexion);
  FCatalogo := oRepositorio;
  FReparaciones := oRepositorio;
  FLiquidaciones := oRepositorio;
  FLineas := NuevaConsulta(SQL_LINEAS);
  FLineas.ReadOnly := True;
  FdsLineas := NuevoOrigen(FLineas);
end;

function TDatosPantallaReparaciones.NuevaConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(Self);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TDatosPantallaReparaciones.NuevoOrigen(
  ADatos: TDataSet): TDataSource;
begin
  Result := TDataSource.Create(Self);
  Result.DataSet := ADatos;
end;

procedure TDatosPantallaReparaciones.AsignarMaestro(ADatos: TDataSource);
begin
  FLineas.MasterSource := ADatos;
  FLineas.MasterFields := 'ID_GAR';
  FLineas.DetailFields := 'ID_GAR_GARLIN';
  // Abierta, sigue sola al expediente de la lista.
  if not FLineas.Active then
    FLineas.Open;
end;

procedure TDatosPantallaReparaciones.RefrescarLineas;
begin
  if FLineas.Active then
    FLineas.Refresh
  else if Assigned(FLineas.MasterSource) and
          Assigned(FLineas.MasterSource.DataSet) and
          FLineas.MasterSource.DataSet.Active then
    FLineas.Open;
end;

procedure TDatosPantallaReparaciones.RefrescarLiquidaciones;
begin
  if Assigned(FListaLiquidaciones) and FListaLiquidaciones.Active then
    FListaLiquidaciones.Refresh;
end;

function TDatosPantallaReparaciones.Lineas: TDataSource;
begin
  Result := FdsLineas;
end;

function TDatosPantallaReparaciones.Liquidaciones: TDataSource;
begin
  if not Assigned(FListaLiquidaciones) then
  begin
    FListaLiquidaciones := NuevaConsulta(SQL_LIQUIDACIONES);
    FListaLiquidaciones.ReadOnly := True;
    FdsLiquidaciones := NuevoOrigen(FListaLiquidaciones);
  end;
  if not FListaLiquidaciones.Active then
    FListaLiquidaciones.Open;
  Result := FdsLiquidaciones;
end;

function TDatosPantallaReparaciones.TiposEditables: TDataSource;
begin
  if not Assigned(FTipos) then
  begin
    FTipos := NuevaConsulta(SQL_TIPOS);
    FTipos.KeyFields := 'CODIGO_GARTIP';
    FTipos.UpdatingTable := 'fza_garantias_tipos';
    FTipos.OnNewRecord := TiposNewRecord;
    FTipos.BeforePost := TiposBeforePost;
    FTipos.BeforeDelete := TiposBeforeDelete;
    FdsTipos := NuevoOrigen(FTipos);
  end;
  if not FTipos.Active then
    FTipos.Open;
  Result := FdsTipos;
end;

// Los mismos valores por defecto que fza_garantias_tipos.
procedure TDatosPantallaReparaciones.TiposNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('CATEGORIA_GARTIP').AsString := 'GENERAL';
  DataSet.FieldByName('MODALIDAD_GARTIP').AsString :=
    MODALIDAD_REPARACION_PAGO;
  DataSet.FieldByName('ESPRESUPUESTO_GARTIP').AsString := 'N';
  DataSet.FieldByName('CANTIDAD_GARTIP').AsFloat := 1;
  DataSet.FieldByName('PRECIO_CLIENTE_GARTIP').AsCurrency := 0;
  DataSet.FieldByName('PRECIO_COSTE_GARTIP').AsCurrency := 0;
  DataSet.FieldByName('MODO_COBRO_GARTIP').AsString :=
    COBRO_REPARACION_RECOGIDA;
  DataSet.FieldByName('DIAS_PLAZO_GARTIP').AsInteger := 3;
  DataSet.FieldByName('ORDEN_GARTIP').AsInteger := 0;
  DataSet.FieldByName('ESACTIVO_GARTIP').AsString := 'S';
end;

procedure TDatosPantallaReparaciones.TiposBeforePost(DataSet: TDataSet);
var
  sError: string;
begin
  sError := '';
  if Trim(DataSet.FieldByName('CODIGO_GARTIP').AsString) = '' then
    sError := SErrorCodigoTipoServicio
  else if Trim(DataSet.FieldByName('DESCRIPCION_GARTIP').AsString) = '' then
    sError := SErrorDescripcionTipoServicio
  else if not EsModalidadReparacion(
    DataSet.FieldByName('MODALIDAD_GARTIP').AsString) then
    sError := SErrorModalidadReparacion
  else if not EsModoCobroReparacion(
    DataSet.FieldByName('MODO_COBRO_GARTIP').AsString) then
    sError := SErrorModoCobroReparacion;
  if sError <> '' then
    raise EValidacionBBDD.Create(sError);
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
  end
  else
  begin
    DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
  end;
end;

// Un tipo ya usado no se borra: se desactiva.
procedure TDatosPantallaReparaciones.TiposBeforeDelete(DataSet: TDataSet);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(
    'SELECT 1 FROM fza_garantias_reclamaciones G ' +
    ' WHERE G.CODIGO_GARTIP_GAR = :TIPO ' +
    'UNION ALL ' +
    'SELECT 1 FROM fza_garantias_lineas L ' +
    ' WHERE L.CODIGO_GARTIP_GARLIN = :TIPO LIMIT 1');
  try
    oConsulta.ParamByName('TIPO').AsString :=
      DataSet.FieldByName('CODIGO_GARTIP').AsString;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EValidacionBBDD.Create(SErrorTipoServicioUsado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosPantallaReparaciones.ExternosEditables: TDataSource;
begin
  if not Assigned(FExternos) then
  begin
    FExternos := NuevaConsulta(SQL_EXTERNOS);
    FExternos.KeyFields := 'CODIGO_PRV_PRV';
    FExternos.SQLUpdate.Text :=
      'UPDATE fza_proveedores ' +
      '   SET MODO_LIQUIDACION_SERVICIOS_PRV = ' +
      '       NULLIF(:MODO_LIQUIDACION_SERVICIOS_PRV, ''''), ' +
      '       INSTANTE_MODIF = NOW() ' +
      ' WHERE CODIGO_PRV_PRV = :Old_CODIGO_PRV_PRV';
    FdsExternos := NuevoOrigen(FExternos);
  end;
  if not FExternos.Active then
    FExternos.Open;
  Result := FdsExternos;
end;

function TDatosPantallaReparaciones.Tienda(
  const AAlmacen: string): TTiendaHojaReparacion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TTiendaHojaReparacion);
  oConsulta := NuevaConsulta(
    'SELECT E.RAZON_SOCIAL_EMP, E.NIF_EMP, M.NOMBRE_ALM_ALM, ' +
    '       COALESCE(NULLIF(M.DIRECCION_ALM, ''''), E.DIRECCION1_EMP) ' +
    '         AS DIRECCION, ' +
    '       CONCAT_WS('' '', M.CODIGO_POSTAL_ALM, M.POBLACION_ALM, ' +
    '                 M.PROVINCIA_ALM) AS POBLACION, M.TELEFONO_ALM ' +
    '  FROM fza_almacenes M ' +
    '  JOIN fza_empresas E ON E.CODIGO_EMP_EMP = M.CODIGO_EMP_ALM ' +
    ' WHERE M.CODIGO_ALM_ALM = :ALMACEN');
  try
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.Open;
    Result.Empresa := oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString;
    Result.Nif := oConsulta.FieldByName('NIF_EMP').AsString;
    Result.Tienda := oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
    Result.Direccion := oConsulta.FieldByName('DIRECCION').AsString;
    Result.Poblacion := oConsulta.FieldByName('POBLACION').AsString;
    Result.Telefono := oConsulta.FieldByName('TELEFONO_ALM').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosPantallaReparaciones.LineasHoja(const AWhere: string;
  AId: Int64): TArray<TLineaHojaReparacion>;
var
  oConsulta: TUniQuery;
  iLinea: Integer;
begin
  oConsulta := NuevaConsulta(
    'SELECT G.ID_GAR, L.FECHA_INICIO_GARLIN, L.FECHA_FIN_GARLIN, ' +
    '       TRIM(CONCAT_WS('' '', G.CODIGO_UNIDAD_GAR, G.LOTE_GAR, ' +
    '         G.DESCRIPCION_OBJETO_GAR, G.REFERENCIA_OBJETO_GAR)) AS OBJETO, ' +
    '       L.DESCRIPCION_GARLIN, G.DETALLES_GAR, ' +
    '       L.CANTIDAD_GARLIN * L.PRECIO_COSTE_GARLIN AS IMPORTE ' +
    '  FROM fza_garantias_lineas L ' +
    '  JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    AWhere + ' ORDER BY G.ID_GAR, L.LINEA_GARLIN');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iLinea + 1);
      Result[iLinea].Reparacion := oConsulta.FieldByName('ID_GAR').AsLargeInt;
      Result[iLinea].Fecha :=
        oConsulta.FieldByName('FECHA_FIN_GARLIN').AsDateTime;
      if oConsulta.FieldByName('FECHA_FIN_GARLIN').IsNull then
        Result[iLinea].Fecha :=
          oConsulta.FieldByName('FECHA_INICIO_GARLIN').AsDateTime;
      Result[iLinea].Objeto := oConsulta.FieldByName('OBJETO').AsString;
      Result[iLinea].Trabajo :=
        oConsulta.FieldByName('DESCRIPCION_GARLIN').AsString;
      Result[iLinea].Detalles := oConsulta.FieldByName('DETALLES_GAR').AsString;
      Result[iLinea].Importe := oConsulta.FieldByName('IMPORTE').AsCurrency;
      Inc(iLinea);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosPantallaReparaciones.HojaEntrega(const AIds: TArray<Int64>;
  const AAlmacen: string): THojaReparaciones;
var
  iId: Int64;
  oConsulta: TUniQuery;
begin
  Result := Default(THojaReparaciones);
  if Length(AIds) = 0 then
    raise EValidacionBBDD.Create(SErrorSinLineasHoja);
  Result.Tienda := Tienda(AAlmacen);
  Result.Titulo := STituloHojaEntregaExterno;
  Result.Fecha := Date;
  for iId in AIds do
    Result.Lineas := Result.Lineas + LineasHoja('WHERE L.ID_GARLIN = :ID',
      iId);
  oConsulta := NuevaConsulta('SELECT COALESCE(P.RAZON_SOCIAL_PRV, ' +
    'L.CODIGO_PRV_GARLIN) FROM fza_garantias_lineas L ' +
    'LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = L.CODIGO_PRV_GARLIN ' +
    'WHERE L.ID_GARLIN = :ID');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AIds[0];
    oConsulta.Open;
    Result.Proveedor := oConsulta.Fields[0].AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosPantallaReparaciones.HojaLiquidacion(
  ALiquidacion: Int64): THojaReparaciones;
var
  oConsulta: TUniQuery;
  bCargo: Boolean;
begin
  Result := Default(THojaReparaciones);
  oConsulta := NuevaConsulta('SELECT Q.SENTIDO_GARLIQ, Q.FECHA_GARLIQ, ' +
    'COALESCE(P.RAZON_SOCIAL_PRV, Q.CODIGO_PRV_GARLIQ) AS PROVEEDOR, ' +
    // La tienda de los trabajos liquidados (la del primero).
    '(SELECT G.CODIGO_ALM_GAR FROM fza_garantias_lineas L ' +
    '   JOIN fza_garantias_reclamaciones G ON G.ID_GAR = L.ID_GAR_GARLIN ' +
    '  WHERE L.ID_GARLIQ_GARLIN = Q.ID_GARLIQ ' +
    '     OR L.ID_GARLIQ_CARGO_GARLIN = Q.ID_GARLIQ ' +
    '  ORDER BY L.ID_GARLIN LIMIT 1) AS ALMACEN ' +
    'FROM fza_garantias_liquidaciones Q ' +
    'LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = Q.CODIGO_PRV_GARLIQ ' +
    'WHERE Q.ID_GARLIQ = :ID');
  try
    oConsulta.ParamByName('ID').AsLargeInt := ALiquidacion;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EValidacionBBDD.CreateFmt(SErrorLiquidacionNoExiste,
        [ALiquidacion]);
    bCargo := oConsulta.FieldByName('SENTIDO_GARLIQ').AsString =
      LIQUIDACION_REPARACION_CARGO;
    Result.Fecha := oConsulta.FieldByName('FECHA_GARLIQ').AsDateTime;
    Result.Proveedor := oConsulta.FieldByName('PROVEEDOR').AsString;
    Result.Tienda := Tienda(oConsulta.FieldByName('ALMACEN').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
  Result.Titulo := STituloHojaLiquidacionPago;
  Result.Lineas := LineasHoja('WHERE L.ID_GARLIQ_GARLIN = :ID',
    ALiquidacion);
  if bCargo then
  begin
    Result.Titulo := STituloHojaCargoFabricante;
    Result.Lineas := LineasHoja('WHERE L.ID_GARLIQ_CARGO_GARLIN = :ID',
      ALiquidacion);
  end;
  Result.Liquidacion := ALiquidacion;
  Result.EsImporte := True;
end;

end.
