{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaConsultasRepositorio                               }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas UniDAC utilizadas por la operativa de caja.                     }
{******************************************************************************}
unit UniDataCajaConsultasRepositorio;

interface

uses
  inLibFormatoDocumentoLecturasIntf,
  Data.DB, Uni,
  inLibCatalogoSqlIntf,
  inLibCajaVentaIntf;

type
  TConsultaCaja = class(
    TInterfacedObject,
    IResultadoConsultaCaja)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;
  TRepositorioConsultasCaja = class(
    TInterfacedObject,
    IRepositorioConsultasCaja,
    IRepositorioArticulosCaja,
    IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function EjecutarConsulta(
      const ADefinicion: TDefinicionSql;
      const ASql: string): IResultadoConsultaCaja;
    function EjecutarConsultarStock(
      const ASql, ACodigoArticulo: string):
      IResultadoConsultaCaja;
    function EjecutarBuscarEmpleado(
      const ASql, ATexto: string;
      out AEmpleado: TEmpleadoCaja): Boolean;
    function EjecutarObtenerCliente(
      const ASql, ACodigo: string;
      out ACliente: TClienteCaja): Boolean;
    function EjecutarConsultarCabeceraFactura(
      const ASql, ASerie, ANumero: string):
      IResultadoConsultaCaja;
    function EjecutarConsultarLineasFactura(
      const ASql, ASerie, ANumero: string):
      IResultadoConsultaCaja;
    function EjecutarConsultarFacturaPorCodigoBarras(
      const ASql, ACodigoBarras: string):
      IResultadoConsultaCaja;
    function EjecutarConsultarFacturaPorOperacion(
      const ASql, AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      IResultadoConsultaCaja;
    function EjecutarConsultarVentasOrigenSku(
      const ASql, ASku, AEmpresa: string):
      IResultadoConsultaCaja;
    function EjecutarConsultarArticulos(
      const ASql, ATarifa, ATexto: string;
      AFechaTarifa: TDateTime;
      AUsarTexto: Boolean): IResultadoConsultaCaja;
    function EjecutarListarNombresAtributosArticulo(
      const ASql, AArticulo: string): TNombresAtributosCaja;
  public
    function LeerFormatoEmpresa(const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(const ASerie, ANumero: string): string;
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    function ConsultarStock(
      const ACodigoArticulo: string): IResultadoConsultaCaja;
    function ConsultarClientes: IResultadoConsultaCaja;
    function ConsultarTarifas: IResultadoConsultaCaja;
    function ConsultarEmpleados: IResultadoConsultaCaja;
    function BuscarEmpleado(
      const ATexto: string;
      out AEmpleado: TEmpleadoCaja): Boolean;
    function ObtenerCliente(
      const ACodigo: string;
      out ACliente: TClienteCaja): Boolean;
    function ConsultarCabeceraFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
    function ConsultarLineasFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
    function ConsultarFacturaPorCodigoBarras(
      const ACodigoBarras: string): IResultadoConsultaCaja;
    function ConsultarFacturaPorOperacion(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string): IResultadoConsultaCaja;
    function ConsultarVentasOrigenSku(
      const ASku, AEmpresa: string): IResultadoConsultaCaja;
    function ConsultarArticulosIncremental(
      const ATarifa, ATexto: string;
      AFechaTarifa: TDateTime): IResultadoConsultaCaja;
    function ConsultarArticulosBusqueda(
      const ATarifa: string;
      AFechaTarifa: TDateTime): IResultadoConsultaCaja;
    function ListarNombresAtributosArticulo(
      const AArticulo: string): TNombresAtributosCaja;
  end;

function CrearRepositorioArticulosCajaUniDAC(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql = nil;
  const AIncidenciasSql: IRegistroIncidenciasSql = nil
): IRepositorioArticulosCaja;

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion,
  UniDataStockConsultaRepositorio;

function TRepositorioConsultasCaja.ConsultarTarifas:
  IResultadoConsultaCaja;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT CODIGO_TAR_ARTTAR AS CODIGO_TAR, ' +
      'NOMBRE_TAR_TAR AS NOMBRE_TAR, ESIMP_INCL_TAR, ' +
      'ESACTIVO_ARTTAR AS ESACTIVO_TAR FROM fza_tarifas ' +
      'ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
    Consulta.Open;
    Result := TConsultaCaja.Create(Consulta);
    Consulta := nil;
  finally
    Consulta.Free;
  end;
end;

const
  SQL_CONSULTAR_STOCK =
    'CALL PRC_GET_CAJA_STOCK_PIVOTADO(:ARTICULO)';
  SQL_CONSULTAR_CLIENTES =
    'SELECT CODIGO_CLI_CLI AS `Código`, ' +
    'RAZON_SOCIAL_CLI AS `Razón Social`, ' +
    'NIF_CLI AS `NIF Cliente`, ' +
    'MOVIL_CLI AS `Teléfono Cliente`, ' +
    'ESPERMITE_DEUDA_CLI AS `Cuenta Crédito`, ' +
    'TOTAL_LIMITE_CREDITO_CLI AS `Límite Crédito`, ' +
    'TOTAL_DEUDA_CLI AS `Deuda Usada` ' +
    'FROM fza_clientes ' +
    'WHERE ESACTIVO_CLI = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_CLI';
  SQL_CONSULTAR_EMPLEADOS =
    'SELECT CODIGO_EMPL AS `Código de Empleado`, ' +
    'DIMINUTIVO_TICKET_EMPL AS `Nombre de Empleado` ' +
    'FROM fza_empleados ' +
    'WHERE ESACTIVO_EMPL = ''S'' ' +
    'AND CODIGO_EMPL IS NOT NULL ' +
    'ORDER BY CODIGO_EMPL';
  SQL_BUSCAR_EMPLEADO =
    'SELECT CODIGO_EMPL, DIMINUTIVO_TICKET_EMPL ' +
    'FROM fza_empleados ' +
    'WHERE ESACTIVO_EMPL = ''S'' ' +
    'AND CODIGO_EMPL IS NOT NULL ' +
    'AND (CODIGO_EMPL LIKE :TOKEN ' +
    'OR DIMINUTIVO_TICKET_EMPL LIKE :TOKEN) ' +
    'ORDER BY (CONCAT(''%'', CODIGO_EMPL, ''%'') = :TOKEN) DESC, ' +
    'CODIGO_EMPL ASC LIMIT 1';
  SQL_OBTENER_CLIENTE =
    'SELECT RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, EMAIL_CLI, ' +
    'DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, ' +
    'PROVINCIA_CLI, CODIGO_POSTAL_CLI, CODIGO_PAI_CLI, ' +
    'NOMBRE_PAI_CLI, ESIVA_RECARGO_CLI, ' +
    'CODIGO_OFICINA_CONTABLE_CLI, CODIGO_ORGANO_GESTOR_CLI, ' +
    'CODIGO_UNIDAD_TRAMITADORA_CLI, ESIVA_EXENTO_CLI, ' +
    'ESREGIMENESPECIALAGRICOLA_CLI, ESRETENCIONES_CLI, ' +
    'ESINTRACOMUNITARIO_CLI, CODIGO_FP_CLI, ' +
    'TARIFA_ARTICULO_CLI, ESPERMITE_DEUDA_CLI, ESVARIOS_CLI ' +
    'FROM fza_clientes WHERE CODIGO_CLI_CLI = :CODIGO';
  SQL_CONSULTAR_CABECERA_FACTURA =
    'SELECT * FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE ' +
    'AND NUMERO_FAC = :NUMERO';
  // CANTIDAD_DEVUELTA_VENTA (FZ-ISSUE-392): unidades del SKU de la línea
  // ya devueltas de esta venta; la devolución solo carga lo pendiente.
  // Es SQLCantidadDevueltaVenta de UniDataRectificativasSql para
  // (L.SERIE_FAC_FACLIN, L.NUMERO_FAC_FACLIN, L.CODIGO_UNIDAD_FACLIN).
  SQL_CONSULTAR_LINEAS_FACTURA =
    'SELECT L.*, ' +
    '(SELECT COALESCE(-SUM(dl.CANTIDAD_FACLIN), 0) ' +
    ' FROM fza_caja_operaciones dv ' +
    ' JOIN fza_facturas df ' +
    '   ON df.SERIE_FAC = dv.SERIE_FAC_OPCAJA ' +
    '  AND df.NUMERO_FAC = dv.NUMERO_FAC_OPCAJA ' +
    ' JOIN fza_facturas_lineas dl ' +
    '   ON dl.SERIE_FAC_FACLIN = df.SERIE_FAC ' +
    '  AND dl.NUMERO_FAC_FACLIN = df.NUMERO_FAC ' +
    ' WHERE dv.SERIE_REF_ORIGEN_OPCAJA = L.SERIE_FAC_FACLIN ' +
    '   AND dv.NUMERO_REF_ORIGEN_OPCAJA = L.NUMERO_FAC_FACLIN ' +
    '   AND dv.TIPO_OPERACION_OPCAJA = ''DV'' ' +
    '   AND dl.CODIGO_UNIDAD_FACLIN = L.CODIGO_UNIDAD_FACLIN ' +
    '   AND dl.CANTIDAD_FACLIN < 0 ' +
    '   AND COALESCE(df.FASE_FAC, '''') NOT IN (''CANCELADA'', ' +
    '     ''SIN_VERIF_ANULADA'', ''VERIFACTU_ANULADA'', ' +
    '     ''NOVERIFACTU_ANULADA'')) AS CANTIDAD_DEVUELTA_VENTA ' +
    'FROM fza_facturas_lineas L ' +
    'WHERE L.SERIE_FAC_FACLIN = :SERIE ' +
    'AND L.NUMERO_FAC_FACLIN = :NUMERO ' +
    'ORDER BY L.LINEA_FACLIN';
  SQL_CONSULTAR_FACTURA_COD_BARRAS =
    'SELECT SERIE_FAC, NUMERO_FAC, TIPO_FAC, FECHA_FAC, ' +
    'CODIGO_EMP_FAC, CODIGO_ALM_FAC, CODIGO_CAJA_FAC, ' +
    'NUMERO_OPERACION_FAC, TOTAL_LIQUIDO_FAC, INSTANTE_ALTA ' +
    'FROM fza_facturas ' +
    'WHERE CODIGO_BARRAS_FAC = :CODIGO';
  SQL_CONSULTAR_FACTURA_OPERACION =
    'SELECT SERIE_FAC, NUMERO_FAC, TIPO_FAC, FECHA_FAC, ' +
    'CODIGO_EMP_FAC, CODIGO_ALM_FAC, CODIGO_CAJA_FAC, ' +
    'NUMERO_OPERACION_FAC, TOTAL_LIQUIDO_FAC, INSTANTE_ALTA ' +
    'FROM fza_facturas ' +
    'WHERE CODIGO_EMP_FAC = :EMP ' +
    'AND CODIGO_ALM_FAC = :ALM ' +
    'AND CODIGO_CAJA_FAC = :CAJA ' +
    // El cajero teclea el número sin los ceros del contador
    'AND TRIM(LEADING ''0'' FROM NUMERO_OPERACION_FAC) = ' +
    'TRIM(LEADING ''0'' FROM :OPERACION)';
  SQL_CONSULTAR_VENTAS_ORIGEN_SKU =
    'SELECT f.SERIE_FAC, f.NUMERO_FAC, f.TIPO_FAC, ' +
    'f.INSTANTE_ALTA, f.CODIGO_EMP_FAC, f.CODIGO_ALM_FAC, ' +
    'f.CODIGO_CAJA_FAC, f.NUMERO_OPERACION_FAC, ' +
    'f.TOTAL_LIQUIDO_FAC, l.CANTIDAD_FACLIN, l.TOTAL_FACLIN ' +
    'FROM fza_facturas_lineas l ' +
    'JOIN fza_facturas f ON f.SERIE_FAC = l.SERIE_FAC_FACLIN ' +
    'AND f.NUMERO_FAC = l.NUMERO_FAC_FACLIN ' +
    'WHERE l.CODIGO_UNIDAD_FACLIN = :SKU ' +
    'AND f.CODIGO_EMP_FAC = :EMP ' +
    'AND l.CANTIDAD_FACLIN > 0 ' +
    'AND COALESCE(f.TIPO_FAC, ''NORMAL'') <> ''RECTIFICATIVA'' ' +
    'AND f.FECHA_FAC >= (CURDATE() - INTERVAL 12 MONTH) ' +
    'ORDER BY f.INSTANTE_ALTA DESC ' +
    'LIMIT 200';
  SQL_CONSULTAR_ARTICULOS_INCREMENTAL =
    'SELECT v.CODIGO_ART_ART AS INPUT_BUSQUEDA, ' +
    'v.CODIGO_ART_ART AS CODIGO_PADRE, v.DESCRIPCION_ART, ' +
    'v.RAZON_SOCIAL_PROVEEDOR, v.REF_PROVEEDOR, ' +
    'pv.PV AS TEMPORADA ' +
    'FROM vi_art_busquedas v ' +
    'LEFT JOIN fza_articulos_propiedades ap ' +
    'ON ap.CODIGO_ART_ART = v.CODIGO_ART_ART ' +
    'AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    'LEFT JOIN fza_propiedades_valores pv ' +
    'ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP ' +
    'WHERE (v.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'OR v.CODIGO_TAR_ARTTAR IS NULL) ' +
    'AND (v.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR v.FECHA_DESDE_ARTTAR <= :FECHA_TARIFA) ' +
    'AND (v.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR v.FECHA_HASTA_ARTTAR >= :FECHA_TARIFA) ' +
    'AND v.CODIGO_ART_ART LIKE :TOKEN ' +
    'ORDER BY v.CODIGO_ART_ART LIMIT 20';
  SQL_CONSULTAR_ARTICULOS_BUSQUEDA =
    'SELECT v.CODIGO_ART_ART, v.DESCRIPCION_ART, ' +
    'v.DESCRIPCION_FAM, pv.PV AS TEMPORADA, ' +
    'v.RAZON_SOCIAL_PROVEEDOR, v.REF_PROVEEDOR, ' +
    'v.CODIGO_TAR_ARTTAR, v.NOMBRE_TAR_TAR, ' +
    'v.PRECIO_FINAL_ARTTAR, v.FECHA_DESDE_ARTTAR, ' +
    'v.FECHA_HASTA_ARTTAR ' +
    'FROM vi_art_busquedas v ' +
    'LEFT JOIN fza_articulos_propiedades ap ' +
    'ON ap.CODIGO_ART_ART = v.CODIGO_ART_ART ' +
    'AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    'AND ap.CODIGO_UNIDAD_ARTPROP = '''' ' +
    'LEFT JOIN fza_propiedades_valores pv ' +
    'ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP ' +
    'WHERE (v.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'OR v.CODIGO_TAR_ARTTAR IS NULL) ' +
    'AND (v.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR v.FECHA_DESDE_ARTTAR <= :FECHA_TARIFA) ' +
    'AND (v.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR v.FECHA_HASTA_ARTTAR >= :FECHA_TARIFA) ' +
    'ORDER BY v.CODIGO_ART_ART';
  SQL_LISTAR_NOMBRES_ATRIBUTOS_ARTICULO =
    'SELECT vat.NOMBRE_VA AS NOMBRE_ATRIBUTO ' +
    'FROM fza_articulos a ' +
    'JOIN fza_variaciones_atributos vat ' +
    'ON vat.ID_VAR_VA = a.TIPO_VARIACION_ART ' +
    'WHERE a.CODIGO_ART_ART = :ARTICULO ' +
    'ORDER BY vat.ORDEN_VA LIMIT 5';

function DefinicionConsultarStock: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarStock',
    SQL_CONSULTAR_STOCK,
    'ARTICULO',
    'Codigo,Almacen',
    tssCall,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarClientes: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarClientes',
    SQL_CONSULTAR_CLIENTES,
    '',
    'Código,Razón Social,NIF Cliente,Teléfono Cliente,' +
    'Cuenta Crédito,Límite Crédito,Deuda Usada',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarEmpleados: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarEmpleados',
    SQL_CONSULTAR_EMPLEADOS,
    '',
    'Código de Empleado,Nombre de Empleado',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionBuscarEmpleado: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'BuscarEmpleado',
    SQL_BUSCAR_EMPLEADO,
    'TOKEN',
    'CODIGO_EMPL,DIMINUTIVO_TICKET_EMPL',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionObtenerCliente: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ObtenerCliente',
    SQL_OBTENER_CLIENTE,
    'CODIGO',
    'RAZON_SOCIAL_CLI,NIF_CLI,MOVIL_CLI,EMAIL_CLI,' +
    'DIRECCION1_CLI,DIRECCION2_CLI,POBLACION_CLI,' +
    'PROVINCIA_CLI,CODIGO_POSTAL_CLI,CODIGO_PAI_CLI,' +
    'NOMBRE_PAI_CLI,ESIVA_RECARGO_CLI,' +
    'CODIGO_OFICINA_CONTABLE_CLI,CODIGO_ORGANO_GESTOR_CLI,' +
    'CODIGO_UNIDAD_TRAMITADORA_CLI,ESIVA_EXENTO_CLI,' +
    'ESREGIMENESPECIALAGRICOLA_CLI,ESRETENCIONES_CLI,' +
    'ESINTRACOMUNITARIO_CLI,CODIGO_FP_CLI,' +
    'TARIFA_ARTICULO_CLI,ESPERMITE_DEUDA_CLI,ESVARIOS_CLI',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarCabeceraFactura: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarCabeceraFactura',
    SQL_CONSULTAR_CABECERA_FACTURA,
    'SERIE,NUMERO',
    'CODIGO_CLI_FAC',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarLineasFactura: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarLineasFactura',
    SQL_CONSULTAR_LINEAS_FACTURA,
    'SERIE,NUMERO',
    'CANTIDAD_FACLIN',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarFacturaPorCodigoBarras: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarFacturaPorCodigoBarras',
    SQL_CONSULTAR_FACTURA_COD_BARRAS,
    'CODIGO',
    'SERIE_FAC,NUMERO_FAC,CODIGO_EMP_FAC,CODIGO_ALM_FAC',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarFacturaPorOperacion: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarFacturaPorOperacion',
    SQL_CONSULTAR_FACTURA_OPERACION,
    'EMP,ALM,CAJA,OPERACION',
    'SERIE_FAC,NUMERO_FAC,CODIGO_EMP_FAC,CODIGO_ALM_FAC',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarVentasOrigenSku: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarVentasOrigenSku',
    SQL_CONSULTAR_VENTAS_ORIGEN_SKU,
    'SKU,EMP',
    'SERIE_FAC,NUMERO_FAC,CODIGO_ALM_FAC,INSTANTE_ALTA',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarArticulosIncremental: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarArticulosIncremental',
    SQL_CONSULTAR_ARTICULOS_INCREMENTAL,
    'TARIFA,FECHA_TARIFA,TOKEN',
    'INPUT_BUSQUEDA,CODIGO_PADRE,DESCRIPCION_ART',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionConsultarArticulosBusqueda: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ConsultarArticulosBusqueda',
    SQL_CONSULTAR_ARTICULOS_BUSQUEDA,
    'TARIFA,FECHA_TARIFA',
    'CODIGO_ART_ART,DESCRIPCION_ART,DESCRIPCION_FAM',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionListarNombresAtributosArticulo: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioConsultasCaja',
    'ListarNombresAtributosArticulo',
    SQL_LISTAR_NOMBRES_ATRIBUTOS_ARTICULO,
    'ARTICULO',
    'NOMBRE_ATRIBUTO',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

constructor TConsultaCaja.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TConsultaCaja.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TConsultaCaja.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

function TRepositorioConsultasCaja.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoEmpresa(ACodigoEmpresa);
end;

function TRepositorioConsultasCaja.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoFactura(ASerie, ANumero);
end;

constructor TRepositorioConsultasCaja.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioConsultasCaja.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 13);
  Result[0] := DefinicionConsultarStock;
  Result[1] := DefinicionConsultarClientes;
  Result[2] := DefinicionConsultarEmpleados;
  Result[3] := DefinicionBuscarEmpleado;
  Result[4] := DefinicionObtenerCliente;
  Result[5] := DefinicionConsultarCabeceraFactura;
  Result[6] := DefinicionConsultarLineasFactura;
  Result[7] := DefinicionConsultarFacturaPorCodigoBarras;
  Result[8] := DefinicionConsultarFacturaPorOperacion;
  Result[9] := DefinicionConsultarVentasOrigenSku;
  Result[10] := DefinicionConsultarArticulosIncremental;
  Result[11] := DefinicionConsultarArticulosBusqueda;
  Result[12] := DefinicionListarNombresAtributosArticulo;
end;

function TRepositorioConsultasCaja.EjecutarConsulta(
  const ADefinicion: TDefinicionSql;
  const ASql: string): IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      ADefinicion,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.EjecutarConsultarStock(
  const ASql, ACodigoArticulo: string):
  IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if not AbrirConsultaStockPorPestanas(
      oConsulta, ACodigoArticulo, False) then
    begin
      oConsulta.SQL.Text := ASql;
      oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
      oConsulta.Open;
    end;
    ValidarCamposResultadoSql(
      DefinicionConsultarStock,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.EjecutarBuscarEmpleado(
  const ASql, ATexto: string;
  out AEmpleado: TEmpleadoCaja): Boolean;
var
  oConsulta: TUniQuery;
  sToken: string;
begin
  AEmpleado := Default(TEmpleadoCaja);
  sToken := Trim(ATexto);
  Result := sToken <> '';
  if Result then
  begin
    sToken := '%' + sToken + '%';
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := ASql;
      oConsulta.ParamByName('TOKEN').AsString := sToken;
      oConsulta.Open;
      ValidarCamposResultadoSql(
        DefinicionBuscarEmpleado,
        oConsulta);
      Result := not oConsulta.IsEmpty;
      if Result then
      begin
        AEmpleado.Codigo :=
          oConsulta.FieldByName('CODIGO_EMPL').AsString;
        AEmpleado.Nombre :=
          oConsulta.FieldByName(
            'DIMINUTIVO_TICKET_EMPL').AsString;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioConsultasCaja.EjecutarObtenerCliente(
  const ASql, ACodigo: string;
  out ACliente: TClienteCaja): Boolean;
var
  oConsulta: TUniQuery;
begin
  ACliente := Default(TClienteCaja);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionObtenerCliente,
      oConsulta);
    Result := not oConsulta.IsEmpty;
    if Result then
    begin
      ACliente.Codigo := ACodigo;
      ACliente.RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      ACliente.Nif :=
        oConsulta.FieldByName('NIF_CLI').AsString;
      ACliente.Movil :=
        oConsulta.FieldByName('MOVIL_CLI').AsString;
      ACliente.Email :=
        oConsulta.FieldByName('EMAIL_CLI').AsString;
      ACliente.Direccion1 :=
        oConsulta.FieldByName('DIRECCION1_CLI').AsString;
      ACliente.Direccion2 :=
        oConsulta.FieldByName('DIRECCION2_CLI').AsString;
      ACliente.Poblacion :=
        oConsulta.FieldByName('POBLACION_CLI').AsString;
      ACliente.Provincia :=
        oConsulta.FieldByName('PROVINCIA_CLI').AsString;
      ACliente.CodigoPostal :=
        oConsulta.FieldByName('CODIGO_POSTAL_CLI').AsString;
      ACliente.CodigoPais :=
        oConsulta.FieldByName('CODIGO_PAI_CLI').AsString;
      ACliente.NombrePais :=
        oConsulta.FieldByName('NOMBRE_PAI_CLI').AsString;
      ACliente.EsIvaRecargo :=
        oConsulta.FieldByName('ESIVA_RECARGO_CLI').AsString;
      ACliente.CodigoOficinaContable :=
        oConsulta.FieldByName(
          'CODIGO_OFICINA_CONTABLE_CLI').AsString;
      ACliente.CodigoOrganoGestor :=
        oConsulta.FieldByName(
          'CODIGO_ORGANO_GESTOR_CLI').AsString;
      ACliente.CodigoUnidadTramitadora :=
        oConsulta.FieldByName(
          'CODIGO_UNIDAD_TRAMITADORA_CLI').AsString;
      ACliente.EsIvaExento :=
        oConsulta.FieldByName('ESIVA_EXENTO_CLI').AsString;
      ACliente.EsRegimenEspecialAgricola :=
        oConsulta.FieldByName(
          'ESREGIMENESPECIALAGRICOLA_CLI').AsString;
      ACliente.EsRetenciones :=
        oConsulta.FieldByName('ESRETENCIONES_CLI').AsString;
      ACliente.EsIntracomunitario :=
        oConsulta.FieldByName(
          'ESINTRACOMUNITARIO_CLI').AsString;
      ACliente.CodigoFormaPago :=
        oConsulta.FieldByName('CODIGO_FP_CLI').AsString;
      ACliente.TarifaArticulo :=
        oConsulta.FieldByName(
          'TARIFA_ARTICULO_CLI').AsString;
      ACliente.EsPermiteDeuda :=
        oConsulta.FieldByName(
          'ESPERMITE_DEUDA_CLI').AsString;
      ACliente.EsClienteVarios :=
        oConsulta.FieldByName('ESVARIOS_CLI').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.
  EjecutarConsultarCabeceraFactura(
  const ASql, ASerie, ANumero: string):
  IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionConsultarCabeceraFactura,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.
  EjecutarConsultarLineasFactura(
  const ASql, ASerie, ANumero: string):
  IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionConsultarLineasFactura,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.ConsultarStock(
  const ACodigoArticulo: string): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarStock;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarStock(
        ASql,
        ACodigoArticulo);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarClientes:
  IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarClientes;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsulta(
        oDefinicion,
        ASql);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarEmpleados:
  IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarEmpleados;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsulta(
        oDefinicion,
        ASql);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.BuscarEmpleado(
  const ATexto: string;
  out AEmpleado: TEmpleadoCaja): Boolean;
var
  bEncontrado: Boolean;
  oDefinicion: TDefinicionSql;
  oEmpleado: TEmpleadoCaja;
begin
  bEncontrado := False;
  oEmpleado := Default(TEmpleadoCaja);
  oDefinicion := DefinicionBuscarEmpleado;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      bEncontrado := EjecutarBuscarEmpleado(
        ASql,
        ATexto,
        oEmpleado);
    end,
    FIncidenciasSql);
  AEmpleado := oEmpleado;
  Result := bEncontrado;
end;

function TRepositorioConsultasCaja.ObtenerCliente(
  const ACodigo: string;
  out ACliente: TClienteCaja): Boolean;
var
  bEncontrado: Boolean;
  oCliente: TClienteCaja;
  oDefinicion: TDefinicionSql;
begin
  bEncontrado := False;
  oCliente := Default(TClienteCaja);
  oDefinicion := DefinicionObtenerCliente;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      bEncontrado := EjecutarObtenerCliente(
        ASql,
        ACodigo,
        oCliente);
    end,
    FIncidenciasSql);
  ACliente := oCliente;
  Result := bEncontrado;
end;

function TRepositorioConsultasCaja.ConsultarCabeceraFactura(
  const ASerie, ANumero: string): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarCabeceraFactura;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarCabeceraFactura(
        ASql,
        ASerie,
        ANumero);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarLineasFactura(
  const ASerie, ANumero: string): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarLineasFactura;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarLineasFactura(
        ASql,
        ASerie,
        ANumero);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.
  EjecutarConsultarFacturaPorCodigoBarras(
  const ASql, ACodigoBarras: string):
  IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('CODIGO').AsString := ACodigoBarras;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionConsultarFacturaPorCodigoBarras,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.
  EjecutarConsultarFacturaPorOperacion(
  const ASql, AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string):
  IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ACaja;
    oConsulta.ParamByName('OPERACION').AsString :=
      ANumeroOperacion;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionConsultarFacturaPorOperacion,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.
  EjecutarConsultarVentasOrigenSku(
  const ASql, ASku, AEmpresa: string):
  IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('SKU').AsString := ASku;
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionConsultarVentasOrigenSku,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.EjecutarConsultarArticulos(
  const ASql, ATarifa, ATexto: string;
  AFechaTarifa: TDateTime;
  AUsarTexto: Boolean): IResultadoConsultaCaja;
var
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  if AUsarTexto then
  begin
    oDefinicion := DefinicionConsultarArticulosIncremental;
  end
  else
  begin
    oDefinicion := DefinicionConsultarArticulosBusqueda;
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('TARIFA').AsString := ATarifa;
    oConsulta.ParamByName('FECHA_TARIFA').AsDate := AFechaTarifa;
    if AUsarTexto then
    begin
      oConsulta.ParamByName('TOKEN').AsString := '%' + ATexto + '%';
    end;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      oDefinicion,
      oConsulta);
    Result := TConsultaCaja.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.
  EjecutarListarNombresAtributosArticulo(
  const ASql, AArticulo: string): TNombresAtributosCaja;
var
  iNombre: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
    oConsulta.Open;
    ValidarCamposResultadoSql(
      DefinicionListarNombresAtributosArticulo,
      oConsulta);
    while not oConsulta.Eof do
    begin
      iNombre := Length(Result);
      SetLength(Result, iNombre + 1);
      Result[iNombre] :=
        oConsulta.FieldByName('NOMBRE_ATRIBUTO').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultasCaja.ConsultarFacturaPorCodigoBarras(
  const ACodigoBarras: string): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarFacturaPorCodigoBarras;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarFacturaPorCodigoBarras(
        ASql,
        ACodigoBarras);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarFacturaPorOperacion(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarFacturaPorOperacion;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarFacturaPorOperacion(
        ASql,
        AEmpresa,
        AAlmacen,
        ACaja,
        ANumeroOperacion);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarVentasOrigenSku(
  const ASku, AEmpresa: string): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarVentasOrigenSku;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarVentasOrigenSku(
        ASql,
        ASku,
        AEmpresa);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarArticulosIncremental(
  const ATarifa, ATexto: string;
  AFechaTarifa: TDateTime): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarArticulosIncremental;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarArticulos(
        ASql,
        ATarifa,
        ATexto,
        AFechaTarifa,
        True);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ConsultarArticulosBusqueda(
  const ATarifa: string;
  AFechaTarifa: TDateTime): IResultadoConsultaCaja;
var
  oDefinicion: TDefinicionSql;
  oResultado: IResultadoConsultaCaja;
begin
  oDefinicion := DefinicionConsultarArticulosBusqueda;
  oResultado := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oResultado := EjecutarConsultarArticulos(
        ASql,
        ATarifa,
        '',
        AFechaTarifa,
        False);
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioConsultasCaja.ListarNombresAtributosArticulo(
  const AArticulo: string): TNombresAtributosCaja;
var
  aNombres: TNombresAtributosCaja;
  oDefinicion: TDefinicionSql;
begin
  SetLength(aNombres, 0);
  oDefinicion := DefinicionListarNombresAtributosArticulo;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      aNombres := EjecutarListarNombresAtributosArticulo(
        ASql,
        AArticulo);
    end,
    FIncidenciasSql);
  Result := aNombres;
end;

function CrearRepositorioArticulosCajaUniDAC(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql
): IRepositorioArticulosCaja;
begin
  Result := TRepositorioConsultasCaja.Create(
    AConexion,
    ACatalogoSql,
    AIncidenciasSql);
end;

end.
