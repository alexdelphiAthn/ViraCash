{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraspasoTicketRepositorio                             }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas de solicitudes y traspasos utilizadas por los tickets de caja.  }
{******************************************************************************}
unit UniDataTraspasoTicketRepositorio;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni,
  inLibTraspasoTicketIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioTraspasoTicket = class(
    TInterfacedObject,
    IRepositorioTraspasoTicket)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function ObtenerSolicitud(
      const ANumero, ASerie: string):
      TSolicitudTraspasoTicket;
    function ListarLineasSolicitud(
      const ANumero, ASerie, AOrigen, ADestino: string):
      TArray<TLineaSolicitudTraspasoTicket>;
    function ObtenerStock(
      const AAlmacen, ASku: string): Double;
    function ObtenerTraspasoHistorico(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TTraspasoTicketHistorico;
    function ListarLineasTraspaso(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TArray<TLineaTraspasoTicket>;
    function ObtenerCargaTransito(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TCargaTransitoTicket;
  end;

implementation

uses
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

const
  SQL_SOLICITUD =
    'SELECT CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL, ' +
    'CODIGO_EMPLEADO_TRSOL, ESTADO_TRSOL, FECHA_TRSOL, ' +
    'COALESCE(TIPO_TRSOL, ''MANUAL'') AS TIPO_TRSOL, ' +
    'INSTANTE_VENTAS_DESDE_TRSOL, INSTANTE_VENTAS_HASTA_TRSOL ' +
    'FROM fza_traspasos_solicitudes ' +
    'WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  SQL_CODIGO_PROVEEDOR =
    'COALESCE(NULLIF(TRIM(L.CODIGO_PRV_TRSOLLIN), ''''), ' +
    'AP.CODIGO_PRV_AP, '''')';
  SQL_NOMBRE_PROVEEDOR =
    'COALESCE(NULLIF(TRIM(L.RAZON_SOCIAL_PRV_TRSOLLIN), ''''), ' +
    'NULLIF(TRIM(P.RAZON_SOCIAL_PRV), ''''), ' +
    'NULLIF(TRIM(L.CODIGO_PRV_TRSOLLIN), ''''), ' +
    'AP.CODIGO_PRV_AP, '''')';
  SQL_LINEAS_SOLICITUD =
    'SELECT L.CODIGO_UNIDAD_TRSOLLIN AS SKU, ' +
    'COALESCE(L.DESCRIPCION_ARTICULO_TRSOLLIN, '''') AS DESCRIPCION, ' +
    'L.CANTIDAD_PEDIDA_TRSOLLIN AS PED, ' +
    '(SELECT COALESCE(SUM(S.CANTIDAD_STK),0) ' +
    'FROM fza_articulos_stockactual S ' +
    'WHERE S.CODIGO_ALM_STK = :ORI ' +
    'AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_TRSOLLIN) AS STK_ORI, ' +
    '(SELECT COALESCE(SUM(S.CANTIDAD_STK),0) ' +
    'FROM fza_articulos_stockactual S ' +
    'WHERE S.CODIGO_ALM_STK = :DES ' +
    'AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_TRSOLLIN) AS STK_DES, ' +
    SQL_CODIGO_PROVEEDOR + ' AS CODIGO_PRV, ' +
    SQL_NOMBRE_PROVEEDOR + ' AS PROVEEDOR ' +
    'FROM fza_traspasos_solicitudes_lineas L ' +
    'INNER JOIN fza_traspasos_solicitudes C ' +
    'ON C.NUMERO_TRSOL = L.NUMERO_TRSOL_TRSOLLIN ' +
    'AND C.SERIE_TRSOL = L.SERIE_TRSOL_TRSOLLIN ' +
    'LEFT JOIN fza_articulos_proveedores AP ' +
    'ON AP.CODIGO_ART_AP = L.CODIGO_ART_TRSOLLIN ' +
    'AND AP.CODIGO_PRV_AP = COALESCE(' +
    'NULLIF(TRIM(L.CODIGO_PRV_TRSOLLIN), ''''), ' +
    '(SELECT APX.CODIGO_PRV_AP ' +
    'FROM fza_articulos_proveedores APX ' +
    'WHERE APX.CODIGO_ART_AP = L.CODIGO_ART_TRSOLLIN ' +
    'ORDER BY CASE ' +
    'WHEN APX.ESPROVEEDORPRINCIPAL_AP = ''S'' THEN 0 ELSE 1 END, ' +
    'APX.FECHA_VALIDEZ_AP DESC, APX.CODIGO_PRV_AP LIMIT 1)) ' +
    'LEFT JOIN fza_proveedores P ' +
    'ON P.CODIGO_PRV_PRV = COALESCE(' +
    'NULLIF(TRIM(L.CODIGO_PRV_TRSOLLIN), ''''), AP.CODIGO_PRV_AP) ' +
    'WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM ' +
    'AND L.SERIE_TRSOL_TRSOLLIN = :SER ' +
    'ORDER BY CASE WHEN ' +
    'COALESCE(C.TIPO_TRSOL, ''MANUAL'') = ''AUTO'' AND ' +
    SQL_CODIGO_PROVEEDOR + ' = '''' THEN 1 ELSE 0 END, ' +
    'CASE WHEN COALESCE(C.TIPO_TRSOL, ''MANUAL'') = ''AUTO'' THEN ' +
    SQL_CODIGO_PROVEEDOR + ' ELSE '''' END, ' +
    'CASE WHEN COALESCE(C.TIPO_TRSOL, ''MANUAL'') = ''AUTO'' THEN ' +
    'CASE WHEN ' + SQL_CODIGO_PROVEEDOR + ' = '''' THEN ' +
    SQL_NOMBRE_PROVEEDOR + ' ELSE '''' END ELSE '''' END, ' +
    'CASE WHEN COALESCE(C.TIPO_TRSOL, ''MANUAL'') = ''AUTO'' THEN ' +
    'L.CODIGO_ART_TRSOLLIN ELSE '''' END, ' +
    'CASE WHEN COALESCE(C.TIPO_TRSOL, ''MANUAL'') = ''AUTO'' THEN ' +
    'COALESCE(( ' +
    'SELECT MIN(COALESCE(AAB.ORDEN_AAB, ACD.ORDEN_ACD, ' +
    '                    AV.ORDEN_AV)) ' +
    'FROM fza_articulos_skus SK ' +
    'JOIN fza_atributos_sku SA ' +
    'ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    'JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    'AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
    'LEFT JOIN fza_articulos_atributos_basicos AAB ' +
    'ON AAB.CODIGO_ART_AAB = SK.CODIGO_ART_SKU ' +
    'AND AAB.ID_AV_AAB = AV.ID_AV ' +
    'LEFT JOIN fza_articulos_conjuntos_asign ACA ' +
    'ON ACA.CODIGO_ART_ACA = SK.CODIGO_ART_SKU ' +
    'AND ACA.ID_VA_ACA = AV.ID_VA_AV ' +
    'LEFT JOIN fza_atributos_conjuntos_det ACD ' +
    'ON ACD.ID_AC_ACD = ACA.ID_AC_ACA ' +
    'AND ACD.ID_AV_ACD = AV.ID_AV ' +
    'WHERE SK.CODIGO_UNIDAD_SKU = L.CODIGO_UNIDAD_TRSOLLIN ' +
    'AND SK.CODIGO_ART_SKU = L.CODIGO_ART_TRSOLLIN ' +
    '), 2147483647) ELSE 0 END, ' +
    'CASE WHEN COALESCE(C.TIPO_TRSOL, ''MANUAL'') = ''AUTO'' THEN ' +
    'L.CODIGO_UNIDAD_TRSOLLIN ELSE '''' END, L.LINEA_TRSOLLIN';
  SQL_STOCK =
    'SELECT COALESCE(SUM(S.CANTIDAD_STK),0) AS STOCK ' +
    'FROM fza_articulos_stockactual S ' +
    'WHERE S.CODIGO_ALM_STK = :ALM AND S.CODIGO_UNIDAD_STK = :SKU';
  SQL_TRASPASO_HISTORICO =
    'SELECT o.SERIE_FAC_OPCAJA, o.NUMERO_FAC_OPCAJA, ' +
    'o.CODIGO_ALM_OPCAJA, o.CODIGO_ALM_CONTRA_OPCAJA, ' +
    'o.CODIGO_EMPLEADO_OPCAJA, o.TIPO_OPERACION_OPCAJA, ' +
    'o.FECHA_OPERACION_OPCAJA, ' +
    'CASE WHEN o.TIPO_OPERACION_OPCAJA = ''TA'' AND EXISTS (' +
    'SELECT 1 FROM fza_movimientos_almacen m ' +
    'WHERE m.TIPO_MOV = ''S'' ' +
    'AND m.CODIGO_ALM_MOV = o.CODIGO_ALM_CONTRA_OPCAJA ' +
    'AND m.CODIGO_ALM_CONTRA_MOV = o.CODIGO_ALM_OPCAJA ' +
    'AND m.CODIGO_ALM_DOC_MOV = o.CODIGO_ALM_OPCAJA ' +
    'AND m.CODIGO_CAJA_DOC_MOV = o.CODIGO_CAJA_OPCAJA ' +
    'AND m.NUMERO_OPERACION_DOC_MOV = o.NUMERO_OPERACION_OPCAJA ' +
    'AND m.TIPO_DOC_MOV = o.TIPO_OPERACION_OPCAJA ' +
    'AND m.SERIE_DOC_MOV = o.SERIE_FAC_OPCAJA ' +
    'AND m.NUMERO_DOC_MOV = o.NUMERO_FAC_OPCAJA) ' +
    'THEN ''S'' ELSE ''N'' END AS ESRECEPCION, ' +
    'COALESCE(e.FORMATO_DOCUMENTO_EMP, ''Serie.NroDocumento'') ' +
    'AS FORMATO_DOCUMENTO_EMP FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_empresas e ' +
    'ON e.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :EMP ' +
    'AND o.CODIGO_ALM_OPCAJA = :ALM ' +
    'AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND o.NUMERO_OPERACION_OPCAJA = :NUMOP';
  SQL_LINEAS_TRASPASO =
    'SELECT m.CODIGO_UNIDAD_MOV, m.CANTIDAD_MOV, ' +
    'COALESCE(NULLIF(TRIM(m.DESCRIPCION_ARTICULO_MOV), ''''), ' +
    'a.DESCRIPCION_ART, '''') AS DESCRIPCION ' +
    'FROM fza_movimientos_almacen m ' +
    'LEFT JOIN fza_articulos a ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV ' +
    'WHERE m.CODIGO_ALM_DOC_MOV = :ALM ' +
    'AND m.CODIGO_CAJA_DOC_MOV = :CAJA ' +
    'AND m.NUMERO_OPERACION_DOC_MOV = :NUMOP AND m.TIPO_MOV = ''S'' ' +
    'AND EXISTS (SELECT 1 FROM fza_caja_operaciones o ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :EMP ' +
    'AND o.CODIGO_ALM_OPCAJA = m.CODIGO_ALM_DOC_MOV ' +
    'AND o.CODIGO_CAJA_OPCAJA = m.CODIGO_CAJA_DOC_MOV ' +
    'AND o.NUMERO_OPERACION_OPCAJA = m.NUMERO_OPERACION_DOC_MOV ' +
    'AND o.TIPO_OPERACION_OPCAJA = m.TIPO_DOC_MOV ' +
    'AND o.SERIE_FAC_OPCAJA = m.SERIE_DOC_MOV ' +
    'AND o.NUMERO_FAC_OPCAJA = m.NUMERO_DOC_MOV) ' +
    'ORDER BY m.LINEA_MOV';
  // La carga se identifica por la operacion que la grabo; la empresa
  // destino es la del almacen destino final.
  SQL_CARGA_TRANSITO =
    'SELECT t.CODIGO_ALM_DESTINO_TRTRA, ' +
    'COALESCE(d.NOMBRE_ALM_ALM, '''') AS NOMBRE_DESTINO, ' +
    't.CODIGO_EMP_TRTRA, ' +
    'COALESCE(eo.RAZON_SOCIAL_EMP, '''') AS NOMBRE_EMP_ORIGEN, ' +
    'COALESCE(d.CODIGO_EMP_ALM, '''') AS EMP_DESTINO, ' +
    'COALESCE(ed.RAZON_SOCIAL_EMP, '''') AS NOMBRE_EMP_DESTINO ' +
    'FROM fza_traspasos_transito t ' +
    'LEFT JOIN fza_almacenes d ' +
    'ON d.CODIGO_ALM_ALM = t.CODIGO_ALM_DESTINO_TRTRA ' +
    'LEFT JOIN fza_empresas eo ' +
    'ON eo.CODIGO_EMP_EMP = t.CODIGO_EMP_TRTRA ' +
    'LEFT JOIN fza_empresas ed ' +
    'ON ed.CODIGO_EMP_EMP = d.CODIGO_EMP_ALM ' +
    'WHERE t.CODIGO_EMP_TRTRA = :EMP ' +
    'AND t.CODIGO_ALM_ORIGEN_TRTRA = :ALM ' +
    'AND t.CODIGO_CAJA_CARGA_TRTRA = :CAJA ' +
    'AND t.NUMERO_OPERACION_CARGA_TRTRA = :NUMOP ' +
    'ORDER BY t.ID_TRTRA DESC LIMIT 1';

function DefinicionSql(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioTraspasoTicket',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

constructor TRepositorioTraspasoTicket.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioTraspasoTicket.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 6);
  Result[0] := DefinicionSql(
    'ObtenerSolicitud',
    SQL_SOLICITUD,
    'NUM,SER',
    'CODIGO_ALM_ORIGEN_TRSOL,CODIGO_ALM_DESTINO_TRSOL,' +
    'CODIGO_EMPLEADO_TRSOL,ESTADO_TRSOL,FECHA_TRSOL,TIPO_TRSOL,' +
    'INSTANTE_VENTAS_DESDE_TRSOL,INSTANTE_VENTAS_HASTA_TRSOL');
  Result[1] := DefinicionSql(
    'ListarLineasSolicitud',
    SQL_LINEAS_SOLICITUD,
    'ORI,DES,NUM,SER',
    'SKU,DESCRIPCION,PED,STK_ORI,STK_DES,CODIGO_PRV,PROVEEDOR');
  Result[2] := DefinicionSql(
    'ObtenerStock',
    SQL_STOCK,
    'ALM,SKU',
    'STOCK');
  Result[3] := DefinicionSql(
    'ObtenerTraspasoHistorico',
    SQL_TRASPASO_HISTORICO,
    'EMP,ALM,CAJA,NUMOP',
    'SERIE_FAC_OPCAJA,NUMERO_FAC_OPCAJA,CODIGO_ALM_OPCAJA,' +
    'CODIGO_ALM_CONTRA_OPCAJA,CODIGO_EMPLEADO_OPCAJA,' +
    'FORMATO_DOCUMENTO_EMP,TIPO_OPERACION_OPCAJA,ESRECEPCION,' +
    'FECHA_OPERACION_OPCAJA');
  Result[4] := DefinicionSql(
    'ListarLineasTraspaso',
    SQL_LINEAS_TRASPASO,
    'EMP,ALM,CAJA,NUMOP',
    'CODIGO_UNIDAD_MOV,CANTIDAD_MOV,DESCRIPCION');
  Result[5] := DefinicionSql(
    'ObtenerCargaTransito',
    SQL_CARGA_TRANSITO,
    'EMP,ALM,CAJA,NUMOP',
    'CODIGO_ALM_DESTINO_TRTRA,NOMBRE_DESTINO,CODIGO_EMP_TRTRA,' +
    'NOMBRE_EMP_ORIGEN,EMP_DESTINO,NOMBRE_EMP_DESTINO');
end;

function TRepositorioTraspasoTicket.ObtenerSolicitud(
  const ANumero, ASerie: string):
  TSolicitudTraspasoTicket;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := Default(TSolicitudTraspasoTicket);
  oDefinicion := DefinicionesSql[0];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('NUM').AsString := ANumero;
        oQuery.ParamByName('SER').AsString := ASerie;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result.Existe := not oQuery.IsEmpty;
    if Result.Existe then
    begin
      Result.Tipo :=
        oQuery.FieldByName('TIPO_TRSOL').AsString;
      Result.Origen :=
        oQuery.FieldByName('CODIGO_ALM_ORIGEN_TRSOL').AsString;
      Result.Destino :=
        oQuery.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString;
      Result.Empleado :=
        oQuery.FieldByName('CODIGO_EMPLEADO_TRSOL').AsString;
      Result.Estado :=
        oQuery.FieldByName('ESTADO_TRSOL').AsString;
      Result.Fecha :=
        oQuery.FieldByName('FECHA_TRSOL').AsDateTime;
      Result.InstanteVentasDesde :=
        oQuery.FieldByName('INSTANTE_VENTAS_DESDE_TRSOL').AsDateTime;
      Result.InstanteVentasHasta :=
        oQuery.FieldByName('INSTANTE_VENTAS_HASTA_TRSOL').AsDateTime;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTraspasoTicket.ListarLineasSolicitud(
  const ANumero, ASerie, AOrigen, ADestino: string):
  TArray<TLineaSolicitudTraspasoTicket>;
var
  oDefinicion: TDefinicionSql;
  oLinea: TLineaSolicitudTraspasoTicket;
  oLineas: TList<TLineaSolicitudTraspasoTicket>;
  oQuery: TUniQuery;
begin
  oLineas := TList<TLineaSolicitudTraspasoTicket>.Create;
  oQuery := TUniQuery.Create(nil);
  try
    oDefinicion := DefinicionesSql[1];
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('NUM').AsString := ANumero;
        oQuery.ParamByName('SER').AsString := ASerie;
        oQuery.ParamByName('ORI').AsString := AOrigen;
        oQuery.ParamByName('DES').AsString := ADestino;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    while not oQuery.Eof do
    begin
      oLinea := Default(TLineaSolicitudTraspasoTicket);
      oLinea.Sku := oQuery.FieldByName('SKU').AsString;
      oLinea.Descripcion :=
        oQuery.FieldByName('DESCRIPCION').AsString;
      oLinea.CantidadPedida :=
        oQuery.FieldByName('PED').AsFloat;
      oLinea.StockOrigen :=
        oQuery.FieldByName('STK_ORI').AsFloat;
      oLinea.StockDestino :=
        oQuery.FieldByName('STK_DES').AsFloat;
      oLinea.CodigoProveedor :=
        oQuery.FieldByName('CODIGO_PRV').AsString;
      oLinea.Proveedor :=
        oQuery.FieldByName('PROVEEDOR').AsString;
      oLineas.Add(oLinea);
      oQuery.Next;
    end;
    Result := oLineas.ToArray;
  finally
    FreeAndNil(oQuery);
    FreeAndNil(oLineas);
  end;
end;

function TRepositorioTraspasoTicket.ObtenerStock(
  const AAlmacen, ASku: string): Double;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := 0;
  oDefinicion := DefinicionesSql[2];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('SKU').AsString := ASku;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    if not oQuery.IsEmpty then
      Result := oQuery.FieldByName('STOCK').AsFloat;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTraspasoTicket.ObtenerTraspasoHistorico(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string):
  TTraspasoTicketHistorico;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := Default(TTraspasoTicketHistorico);
  oDefinicion := DefinicionesSql[3];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('EMP').AsString := AEmpresa;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('CAJA').AsString := ACaja;
        oQuery.ParamByName('NUMOP').AsString := ANumeroOperacion;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result.Existe := not oQuery.IsEmpty;
    if Result.Existe then
    begin
      Result.Fecha :=
        oQuery.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
      Result.TipoOperacion :=
        oQuery.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
      Result.Serie :=
        oQuery.FieldByName('SERIE_FAC_OPCAJA').AsString;
      Result.NumeroDocumento :=
        oQuery.FieldByName('NUMERO_FAC_OPCAJA').AsString;
      Result.FormatoDocumento :=
        oQuery.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
      if oQuery.FieldByName('ESRECEPCION').AsString = 'S' then
      begin
        Result.Origen :=
          oQuery.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString;
        Result.Destino :=
          oQuery.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      end
      else
      begin
        Result.Origen :=
          oQuery.FieldByName('CODIGO_ALM_OPCAJA').AsString;
        Result.Destino :=
          oQuery.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString;
      end;
      Result.Empleado :=
        oQuery.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTraspasoTicket.ListarLineasTraspaso(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string):
  TArray<TLineaTraspasoTicket>;
var
  oDefinicion: TDefinicionSql;
  oLinea: TLineaTraspasoTicket;
  oLineas: TList<TLineaTraspasoTicket>;
  oQuery: TUniQuery;
begin
  oLineas := TList<TLineaTraspasoTicket>.Create;
  oQuery := TUniQuery.Create(nil);
  try
    oDefinicion := DefinicionesSql[4];
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('EMP').AsString := AEmpresa;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('CAJA').AsString := ACaja;
        oQuery.ParamByName('NUMOP').AsString := ANumeroOperacion;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    while not oQuery.Eof do
    begin
      oLinea := Default(TLineaTraspasoTicket);
      oLinea.Sku :=
        oQuery.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      oLinea.Cantidad :=
        oQuery.FieldByName('CANTIDAD_MOV').AsFloat;
      oLinea.Descripcion :=
        oQuery.FieldByName('DESCRIPCION').AsString;
      oLineas.Add(oLinea);
      oQuery.Next;
    end;
    Result := oLineas.ToArray;
  finally
    FreeAndNil(oQuery);
    FreeAndNil(oLineas);
  end;
end;

function TRepositorioTraspasoTicket.ObtenerCargaTransito(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string):
  TCargaTransitoTicket;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := Default(TCargaTransitoTicket);
  oDefinicion := DefinicionesSql[5];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('EMP').AsString := AEmpresa;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('CAJA').AsString := ACaja;
        oQuery.ParamByName('NUMOP').AsString := ANumeroOperacion;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result.Existe := not oQuery.IsEmpty;
    if Result.Existe then
    begin
      Result.DestinoFinal :=
        oQuery.FieldByName('CODIGO_ALM_DESTINO_TRTRA').AsString;
      Result.NombreDestinoFinal :=
        oQuery.FieldByName('NOMBRE_DESTINO').AsString;
      Result.EmpresaOrigen :=
        oQuery.FieldByName('CODIGO_EMP_TRTRA').AsString;
      Result.NombreEmpresaOrigen :=
        oQuery.FieldByName('NOMBRE_EMP_ORIGEN').AsString;
      Result.EmpresaDestino :=
        oQuery.FieldByName('EMP_DESTINO').AsString;
      Result.NombreEmpresaDestino :=
        oQuery.FieldByName('NOMBRE_EMP_DESTINO').AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

end.
