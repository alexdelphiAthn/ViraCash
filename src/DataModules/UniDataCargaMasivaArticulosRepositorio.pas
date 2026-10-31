{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataCargaMasivaArticulosRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas y transacciones de la carga masiva de articulos.                }
{******************************************************************************}
unit UniDataCargaMasivaArticulosRepositorio;

interface

uses
  Uni, inLibCargaMasivaArticulosPersistenciaIntf;

function ConstruirSqlPreviewCargaMasivaDocumentoTrabajo(
  const AFiltros: TFiltrosCargaMasivaArticulos): string;
function ConstruirSqlSkuCargaDocumentoTrabajo: string;

function CrearServicioCargaMasivaArticulosUniDAC(
  AConexion: TUniConnection): TServiciosCargaMasivaArticulos;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  Data.DB, inLibCargaMasivaArticulosReglas, UniDataRectificativasSql,
  UniDataPrestaShopEncolado, inLibPrestaShopColaSenal,
  UniDataDocumentosTrabajoCargaOrigenSql;

resourcestring
  // FZ-ISSUE-306: un inventario de solo negativos no se mezcla con cargas
  // normales (su recuento y su regularización son distintos).
  SErrorInventarioSoloNegativosSinScript =
    'Falta el script 20261007_inventario_solo_negativos.sql: sin él la ' +
    'regularización no respetaría la carga de solo negativos.';
  SErrorInventarioConLineasNormales =
    'Este inventario ya tiene líneas de una carga normal. Carga los ' +
    'negativos en un inventario nuevo.';
  SErrorInventarioDeSoloNegativos =
    'Este inventario es de solo negativos. Haz la carga normal en un ' +
    'inventario nuevo.';

const
  // FZ-ISSUE-306: marca del inventario de solo negativos (script 794).
  SQL_EXISTE_MARCA_SOLO_NEGATIVOS =
    'SELECT COUNT(*) AS N FROM information_schema.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ''fza_inventarios'' ' +
    'AND COLUMN_NAME = ''ESSOLONEGATIVOS_INV''';
  SQL_LEER_MARCA_SOLO_NEGATIVOS =
    'SELECT IFNULL(ESSOLONEGATIVOS_INV, ''N'') AS MARCA ' +
    'FROM fza_inventarios WHERE CODIGO_EMP_INV = :EMP ' +
    'AND CODIGO_ALM_INV = :ALM AND SERIE_INV = :SER AND NUMERO_INV = :NRO';
  SQL_MARCAR_SOLO_NEGATIVOS =
    'UPDATE fza_inventarios SET ESSOLONEGATIVOS_INV = ''S'', ' +
    'USUARIO_MODIF = :USR, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_EMP_INV = :EMP AND CODIGO_ALM_INV = :ALM ' +
    'AND SERIE_INV = :SER AND NUMERO_INV = :NRO';
  SQL_FAMILIAS =
    'SELECT CODIGO_FAM_FAM, ' +
    'COALESCE(CODIGO_PADRE_FAM, '''') AS CODIGO_PADRE, ' +
    'NOMBRE_FAM_FAM, DESCRIPCION_FAM FROM fza_articulos_familias ' +
    'WHERE ESACTIVO_FAM = ''S'' ORDER BY ' +
    'COALESCE(CODIGO_PADRE_FAM, ''''), ORDEN_FAM, NOMBRE_FAM_FAM';
  SQL_PROVEEDORES =
    'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV, NIF_PRV ' +
    'FROM fza_proveedores WHERE ESACTIVO_PRV = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_PRV';
  SQL_PROPIEDADES =
    'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP FROM fza_propiedades ' +
    'WHERE ESACTIVO_PROP = ''S'' AND TIPO_VALOR_PROP = ''LISTA'' ' +
    'ORDER BY NOMBRE_PROP_PROP';
  SQL_VALORES_PROPIEDAD_TODOS =
    'SELECT v.ID_PV_ARTPROP, v.ID_PROP_PV, p.NOMBRE_PROP_PROP, v.PV ' +
    'FROM fza_propiedades_valores v JOIN fza_propiedades p ' +
    'ON p.CODIGO_PROP_ARTPROP = v.ID_PROP_PV ' +
    'WHERE v.ESACTIVO_PV = ''S'' AND p.TIPO_VALOR_PROP = ''LISTA'' ' +
    'ORDER BY p.NOMBRE_PROP_PROP, v.PV';
  SQL_VALORES_PROPIEDAD =
    'SELECT v.ID_PV_ARTPROP, v.ID_PROP_PV, p.NOMBRE_PROP_PROP, v.PV ' +
    'FROM fza_propiedades_valores v JOIN fza_propiedades p ' +
    'ON p.CODIGO_PROP_ARTPROP = v.ID_PROP_PV ' +
    'WHERE v.ESACTIVO_PV = ''S'' AND v.ID_PROP_PV = :PROP ORDER BY v.PV';
  SQL_ALMACENES =
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM FROM fza_almacenes ' +
    'WHERE ESACTIVO_ALM = ''S'' AND (TIPO_USO_ALM IN ' +
    '(''ESTANDAR'', ''ESTANDARD'', ''DEPOSITO'') OR TIPO_USO_ALM IS NULL) ' +
    'ORDER BY ORDEN_ALM, NOMBRE_ALM_ALM';
  SQL_TARIFAS =
    'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR FROM fza_tarifas ' +
    'WHERE ESACTIVO_ARTTAR = ''S'' ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
  SQL_INSERTAR_TARIFA =
    'INSERT INTO fza_articulos_tarifas (' +
    'CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
    'ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
    'PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, FECHA_DESDE_ARTTAR, ' +
    'FECHA_HASTA_ARTTAR, USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (:ART, '''', :TARIFA, ''S'', :SALIDA, :FINAL, :DTO, :PDTO, ' +
    ':DESDE, :HASTA, :USR, :USR2, NOW())';
  SQL_PROXIMA_LINEA_INVENTARIO =
    'SELECT COALESCE(MAX(CAST(LINEA_INVLIN AS UNSIGNED)), 0) + 1 AS PROX ' +
    'FROM fza_inventarios_lineas WHERE CODIGO_EMP_INVLIN = :EMP ' +
    'AND CODIGO_ALM_INVLIN = :ALM AND SERIE_INV_INVLIN = :SER ' +
    'AND NUMERO_INV_INVLIN = :NRO';
  // Una fila por SKU y lote con stock en el almacén del inventario (como
  // las cargas de UniDataInventarios); el SKU sin stock sale una vez, sin
  // lote (FZ-ISSUE-276). Con SOLO_CON_STOCK = 1 solo entran los SKU y
  // lotes con stock > 0 (FZ-ISSUE-622).
  SQL_SKUS_ARTICULO =
    'SELECT x.SKU, x.DESC_ART, COALESCE(stk.LOTE_STK, '''') AS LOTE, ' +
    'lot.FECHA_CADUCIDAD_LOT AS CADUCIDAD, ' +
    'COALESCE(stk.CANTIDAD_STK, 0) AS CANTIDAD, ' +
    'COALESCE(stk.PRECIO_MEDIO_STK, 0) AS PMP FROM (' +
    'SELECT sk.CODIGO_UNIDAD_SKU AS SKU, a.DESCRIPCION_ART AS DESC_ART ' +
    'FROM fza_articulos_skus sk JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = sk.CODIGO_ART_SKU ' +
    'WHERE sk.CODIGO_ART_SKU = :ART UNION ' +
    'SELECT a.CODIGO_ART_ART AS SKU, a.DESCRIPCION_ART AS DESC_ART ' +
    'FROM fza_articulos a WHERE a.CODIGO_ART_ART = :ART2 ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_articulos_skus sk2 ' +
    'WHERE sk2.CODIGO_ART_SKU = a.CODIGO_ART_ART)) x ' +
    'LEFT JOIN fza_articulos_stockactual stk ' +
    'ON stk.CODIGO_UNIDAD_STK = x.SKU AND stk.CODIGO_ALM_STK = :ALM ' +
    'LEFT JOIN fza_articulos_lotes lot ' +
    'ON lot.CODIGO_UNIDAD_LOT = stk.CODIGO_UNIDAD_STK ' +
    'AND lot.LOTE_LOT = stk.LOTE_STK ' +
    'WHERE (:SOLO_NEGATIVOS = 0 OR stk.CANTIDAD_STK < 0) ' +
    'AND (:SOLO_CON_STOCK = 0 OR stk.CANTIDAD_STK > 0) ' +
    'ORDER BY x.SKU, LOTE';
  SQL_INSERTAR_LINEA_INVENTARIO =
    'INSERT INTO fza_inventarios_lineas (' +
    'CODIGO_EMP_INVLIN, CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, ' +
    'NUMERO_INV_INVLIN, LINEA_INVLIN, CODIGO_ART_INVLIN, ' +
    'CODIGO_UNIDAD_INVLIN, LOTE_INVLIN, FECHA_CADUCIDAD_INVLIN, ' +
    'DESCRIPCION_ARTICULO_INVLIN, ' +
    'CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN, ' +
    'CANTIDAD_DIFERENCIA_INVLIN, PRECIO_MEDIO_INVLIN, ' +
    'PRECIO_MEDIO_NUEVO_INVLIN, TOTAL_COSTE_DIFERENCIA_INVLIN, ' +
    'USUARIO_ALTA, USUARIO_MODIF, FECHA_RECUENTO_INVLIN, ' +
    'INSTANTE_ALTA) SELECT CODIGO_EMP_INV, CODIGO_ALM_INV, ' +
    'SERIE_INV, NUMERO_INV, :LINEA, :ART, ' +
    ':SKU, :LOTE, :CADUCIDAD, :DESCRIPCION, :TEORICA, 0, ' +
    ':DIFERENCIA, :PMP, :PMP_NUEVO, :COSTE_DIFERENCIA, :USR, :USR2, ' +
    'LEAST(FECHA_INV, NOW()), NOW() FROM fza_inventarios ' +
    'WHERE CODIGO_EMP_INV = :EMP AND CODIGO_ALM_INV = :ALM ' +
    'AND SERIE_INV = :SER AND NUMERO_INV = :NRO';
  SQL_PROXIMA_LINEA_DOCUMENTO =
    'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS PROX ' +
    'FROM fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID_DTR';
  SQL_SKU_DOCUMENTO =
    'SELECT s.CODIGO_ALM_STK AS ALM, s.CODIGO_UNIDAD_STK AS SKU, ' +
    's.LOTE_STK, s.FECHA_CADUCIDAD_STK, s.CANTIDAD_STK, ' +
    'a.DESCRIPCION_ART AS DESC_ART, ' +
    'COALESCE({DESCRIPCION_SKU}, '''') AS DESC_SKU ' +
    'FROM fza_articulos_stockactual s LEFT JOIN fza_articulos_skus sk ' +
    'ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = COALESCE(sk.CODIGO_ART_SKU, ' +
    's.CODIGO_UNIDAD_STK) WHERE COALESCE(sk.CODIGO_ART_SKU, ' +
    's.CODIGO_UNIDAD_STK) = :ART ' +
    'AND s.CODIGO_UNIDAD_STK = :SKU';
  SQL_INSERTAR_LINEA_DOCUMENTO =
    'INSERT INTO fza_documentos_trabajo_lineas (' +
    'ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    'CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    'DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    'CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    'ORIGEN_DTL, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:ID_DTR, :LINEA, :ART, :SKU, :ALM, :LOTE, :CADUCIDAD, ' +
    ':DESC_ART, :DESC_SKU, :CANTIDAD_STOCK, :CANTIDAD, NOW(), ' +
    ':ORIGEN, NOW(), :USR, :USR2)';
  SQL_INSERTAR_SESION_TARIFA =
    'INSERT INTO fza_tarifas_cambios_lineas (' +
    'CODIGO_TARC_TARCLIN, CODIGO_ART_TARCLIN, ' +
    'CODIGO_UNIDAD_SKU_TARCLIN, CODIGO_TAR_ORIGEN_TARCLIN, ' +
    'CODIGO_TAR_DESTINO_TARCLIN, PRECIO_ORIGEN_TARCLIN, ' +
    'PRECIO_COSTE_TARCLIN, PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN, PRECIO_DTO_ACTUAL_TARCLIN, ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN, PRECIO_NUEVO_TARCLIN, ' +
    'PRECIO_FINAL_NUEVO_TARCLIN, PRECIO_DTO_NUEVO_TARCLIN, ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN, ESAPLICAR_TARCLIN, ESTADO_TARCLIN, ' +
    'USUARIO_ALTA, USUARIO_MODIF) VALUES (:TARC, :ART, :SKU, :TAR_ORIG, ' +
    ':TAR_DEST, :P_ORIG, :P_COSTE, :P_SAL_ACT, :P_FIN_ACT, :P_DTO_ACT, ' +
    ':P_PDTO_ACT, :P_NUEVO, :P_FIN_NUEVO, 0, 0, ''S'', ''PENDIENTE'', ' +
    ':USUARIO, :USUARIO) ON DUPLICATE KEY UPDATE ' +
    'PRECIO_ORIGEN_TARCLIN = VALUES(PRECIO_ORIGEN_TARCLIN), ' +
    'PRECIO_COSTE_TARCLIN = VALUES(PRECIO_COSTE_TARCLIN), ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN = VALUES(PRECIO_SALIDA_ACTUAL_TARCLIN), ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN = VALUES(PRECIO_FINAL_ACTUAL_TARCLIN), ' +
    'PRECIO_DTO_ACTUAL_TARCLIN = VALUES(PRECIO_DTO_ACTUAL_TARCLIN), ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN = ' +
    'VALUES(PORCENTAJE_DTO_ACTUAL_TARCLIN), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF), INSTANTE_MODIF = NOW()';

type
  TConsultaCargaMasivaArticulosUniDAC = class(
    TInterfacedObject,
    IConsultaCargaMasivaArticulos)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TServicioCargaMasivaArticulosUniDAC = class(
    TInterfacedObject,
    IConsultasCargaMasivaArticulos,
    IInsercionesCargaMasivaArticulos)
  private
    FConexion: TUniConnection;
    function CrearConsulta(const ASql: string): TUniQuery;
    function EnvolverConsulta(AConsulta: TUniQuery):
      IConsultaCargaMasivaArticulos;
    function StrArrToCsvSql(const AValores: TArray<string>): string;
    function IntArrToCsvSql(const AValores: TArray<Integer>): string;
    function ColumnasExtra(
      const AContexto: TContextoCargaMasivaArticulos): string;
    function ExpresionYaCargado(
      const AContexto: TContextoCargaMasivaArticulos): string;
    function CondicionExcluirCargados(
      const AContexto: TContextoCargaMasivaArticulos): string;
    function CondicionAlmacenesSql(
      const ACampo, AAlmacenes: string): string;
    procedure AnadirOrigenPreviewDocumento(
      ASql: TStrings;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AAlmacenesStock, AAlmacenesVenta: string);
    procedure AnadirFiltroStockPreviewDocumento(
      ASql: TStrings;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AAlmacenesStock: string);
    procedure AnadirFiltroFamiliasPreviewDocumento(
      ASql: TStrings;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AFamilias: string);
    procedure AnadirFiltrosCatalogoPreviewDocumento(
      ASql: TStrings;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AProveedores, APropiedades: string);
    procedure AnadirFiltroVentasPreviewDocumento(
      ASql: TStrings;
      const AFiltros: TFiltrosCargaMasivaArticulos);
    procedure AnadirFiltroStockAlmacenVentaPreviewDocumento(
      ASql: TStrings;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AAlmacenesVenta: string);
    function ConstruirSqlPreviewDocumento(
      const AFiltros: TFiltrosCargaMasivaArticulos): string;
    function ConstruirSqlPreviewArticulos(
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos): string;
    function ConstruirSqlPreview(
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos): string;
    procedure VincularParametrosPreview(
      AConsulta: TUniQuery;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos);
    function AjustarPrecio(
      APrecio: Double;
      const AParametros: TParametrosInsercionTarifa): Double;
    procedure CalcularPreciosTarifa(
      APrecioSalidaOrigen: Double;
      APrecioFinalOrigen: Double;
      const AParametros: TParametrosInsercionTarifa;
      out APrecioSalida: Double;
      out APrecioFinal: Double;
      out APorcentajeDescuento: Double);
    function ProximaLineaInventario(
      const AParametros: TParametrosInsercionInventario): Integer;
    function EsInventarioSoloNegativos(
      const AParametros: TParametrosInsercionInventario;
      out AExisteMarca: Boolean): Boolean;
    procedure ComprobarModoInventario(
      const AParametros: TParametrosInsercionInventario;
      AConLineas: Boolean);
    procedure MarcarInventarioSoloNegativos(
      const AParametros: TParametrosInsercionInventario);
    procedure AsignarLoteInventario(AInsercion, AFila: TUniQuery);
    procedure InsertarSkusInventario(
      AInsercion: TUniQuery;
      const ACodigoArticulo: string;
      const AParametros: TParametrosInsercionInventario;
      var ALineaActual: Integer;
      var ANumeroLineas: Integer);
    function ProximaLineaDocumento(AIdDocumento: Int64): Integer;
    procedure InsertarSkuDocumento(
      AInsercion: TUniQuery;
      const ACodigoArticulo: string;
      const ACodigoSku: string;
      const AParametros: TParametrosInsercionDocumentoTrabajo;
      var ALineaActual: Integer;
      var ANumeroLineas: Integer);
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarFamilias: IConsultaCargaMasivaArticulos;
    function ConsultarProveedores: IConsultaCargaMasivaArticulos;
    function ConsultarValoresPropiedad(
      const ACodigoPropiedad: string): IConsultaCargaMasivaArticulos;
    function ListarPropiedades: TPropiedadesCargaMasiva;
    function ListarAlmacenes: TAlmacenesCargaMasiva;
    function ListarTarifas: TTarifasCargaMasiva;
    function Previsualizar(
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos
    ): IConsultaCargaMasivaArticulos;
    function InsertarTarifa(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionTarifa
    ): TResultadoInsercionCargaMasiva;
    function InsertarInventario(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionInventario
    ): TResultadoInsercionCargaMasiva;
    function InsertarDocumentoTrabajo(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionDocumentoTrabajo
    ): TResultadoInsercionCargaMasiva;
    function InsertarSesionTarifa(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionSesionTarifa
    ): TResultadoInsercionCargaMasiva;
  end;

function ConstruirSqlSkuCargaDocumentoTrabajo: string;
begin
  Result := StringReplace(SQL_SKU_DOCUMENTO, '{DESCRIPCION_SKU}',
    SqlDescripcionSkuDocumentoTrabajo('s.CODIGO_UNIDAD_STK'),
    [rfReplaceAll]);
end;

constructor TConsultaCargaMasivaArticulosUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaCargaMasivaArticulosUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaCargaMasivaArticulosUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TServicioCargaMasivaArticulosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TServicioCargaMasivaArticulosUniDAC.CrearConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TServicioCargaMasivaArticulosUniDAC.EnvolverConsulta(
  AConsulta: TUniQuery): IConsultaCargaMasivaArticulos;
begin
  Result := TConsultaCargaMasivaArticulosUniDAC.Create(AConsulta);
end;

function TServicioCargaMasivaArticulosUniDAC.ConsultarFamilias:
  IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_FAMILIAS);
  try
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConsultarProveedores:
  IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_PROVEEDORES);
  try
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConsultarValoresPropiedad(
  const ACodigoPropiedad: string): IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  if ACodigoPropiedad = '' then
  begin
    oConsulta := CrearConsulta(SQL_VALORES_PROPIEDAD_TODOS);
  end
  else
  begin
    oConsulta := CrearConsulta(SQL_VALORES_PROPIEDAD);
    oConsulta.ParamByName('PROP').AsString := ACodigoPropiedad;
  end;
  try
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ListarPropiedades:
  TPropiedadesCargaMasiva;
var
  iPosicion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_PROPIEDADES);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iPosicion := Length(Result);
      SetLength(Result, iPosicion + 1);
      Result[iPosicion].Codigo :=
        oConsulta.FieldByName('CODIGO_PROP_ARTPROP').AsString;
      Result[iPosicion].Nombre :=
        oConsulta.FieldByName('NOMBRE_PROP_PROP').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ListarAlmacenes:
  TAlmacenesCargaMasiva;
var
  iPosicion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_ALMACENES);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iPosicion := Length(Result);
      SetLength(Result, iPosicion + 1);
      Result[iPosicion].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iPosicion].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ListarTarifas:
  TTarifasCargaMasiva;
var
  iPosicion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_TARIFAS);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iPosicion := Length(Result);
      SetLength(Result, iPosicion + 1);
      Result[iPosicion].Codigo :=
        oConsulta.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      Result[iPosicion].Nombre :=
        oConsulta.FieldByName('NOMBRE_TAR_TAR').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.StrArrToCsvSql(
  const AValores: TArray<string>): string;
var
  iPosicion: Integer;
begin
  Result := '';
  for iPosicion := 0 to High(AValores) do
  begin
    if Result <> '' then
    begin
      Result := Result + ',';
    end;
    Result := Result + QuotedStr(AValores[iPosicion]);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.IntArrToCsvSql(
  const AValores: TArray<Integer>): string;
var
  iPosicion: Integer;
begin
  Result := '';
  for iPosicion := 0 to High(AValores) do
  begin
    if Result <> '' then
    begin
      Result := Result + ',';
    end;
    Result := Result + IntToStr(AValores[iPosicion]);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ColumnasExtra(
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcTarifa:
      begin
        if AContexto.CodigoTarifaOrigen <> '' then
        begin
          Result :=
            '(SELECT t.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas t ' +
            'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
            'AND t.CODIGO_TAR_ARTTAR = :P_TARIFA_ORIG_S ' +
            'AND t.ESACTIVO_ARTTAR = ''S'' ' +
            'ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1) ' +
            'AS PRECIO_SALIDA_ORIG, ' +
            '(SELECT t.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas t ' +
            'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
            'AND t.CODIGO_TAR_ARTTAR = :P_TARIFA_ORIG_F ' +
            'AND t.ESACTIVO_ARTTAR = ''S'' ' +
            'ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1) ' +
            'AS PRECIO_FINAL_ORIG,';
        end
        else
        begin
          Result := '0 AS PRECIO_SALIDA_ORIG, 0 AS PRECIO_FINAL_ORIG,';
        end;
      end;
    mcInventario:
      begin
        Result :=
          '(SELECT COUNT(DISTINCT s.CODIGO_UNIDAD_STK) ' +
          'FROM fza_articulos_stockactual s LEFT JOIN fza_articulos_skus sk ' +
          'ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK ' +
          'WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK) = ' +
          'a.CODIGO_ART_ART AND s.CODIGO_ALM_STK = :P_INV_ALMACEN ' +
          'AND ((:P_INV_SOLO_NEGATIVOS = 0 AND s.CANTIDAD_STK > 0) ' +
          'OR (:P_INV_SOLO_NEGATIVOS = 1 AND s.CANTIDAD_STK < 0))) ' +
          'AS NUM_SKUS_CON_STOCK, ' +
          '(SELECT AVG(s.PRECIO_MEDIO_STK) ' +
          'FROM fza_articulos_stockactual s LEFT JOIN fza_articulos_skus sk ' +
          'ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK ' +
          'WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK) = ' +
          'a.CODIGO_ART_ART AND s.CODIGO_ALM_STK = :P_INV_ALMACEN_PMP ' +
          'AND s.PRECIO_MEDIO_STK > 0) AS PMP_ACTUAL,';
      end;
    mcSesionTarifa:
      begin
        Result :=
          'U.SKU AS CODIGO_UNIDAD_SKU, ' +
          '(SELECT TOG.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas TOG ' +
          'WHERE TOG.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TOG.CODIGO_UNIDAD_ARTTAR, '''') IN (U.SKU, '''') ' +
          'AND TOG.CODIGO_TAR_ARTTAR = :P_TAR_ORIG ' +
          'AND TOG.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY (COALESCE(TOG.CODIGO_UNIDAD_ARTTAR, '''') = U.SKU) ' +
          'DESC, TOG.FECHA_DESDE_ARTTAR DESC, ' +
          'TOG.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_ORIGEN, ' +
          '(SELECT TDE.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas TDE ' +
          'WHERE TDE.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDE.CODIGO_UNIDAD_ARTTAR, '''') = U.SKU ' +
          'AND TDE.CODIGO_TAR_ARTTAR = :P_TAR_DEST_SAL ' +
          'AND TDE.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDE.FECHA_DESDE_ARTTAR DESC, ' +
          'TDE.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_SALIDA_ACT, ' +
          '(SELECT TDF.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas TDF ' +
          'WHERE TDF.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDF.CODIGO_UNIDAD_ARTTAR, '''') = U.SKU ' +
          'AND TDF.CODIGO_TAR_ARTTAR = :P_TAR_DEST_FIN ' +
          'AND TDF.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDF.FECHA_DESDE_ARTTAR DESC, ' +
          'TDF.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_FINAL_ACT, ' +
          '(SELECT TDD.PRECIO_DTO_ARTTAR FROM fza_articulos_tarifas TDD ' +
          'WHERE TDD.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDD.CODIGO_UNIDAD_ARTTAR, '''') = U.SKU ' +
          'AND TDD.CODIGO_TAR_ARTTAR = :P_TAR_DEST_DTO ' +
          'AND TDD.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDD.FECHA_DESDE_ARTTAR DESC, ' +
          'TDD.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_DTO_ACT, ' +
          '(SELECT TDP.PORCENTAJE_DTO_ARTTAR ' +
          'FROM fza_articulos_tarifas TDP ' +
          'WHERE TDP.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDP.CODIGO_UNIDAD_ARTTAR, '''') = U.SKU ' +
          'AND TDP.CODIGO_TAR_ARTTAR = :P_TAR_DEST_PDTO ' +
          'AND TDP.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDP.FECHA_DESDE_ARTTAR DESC, ' +
          'TDP.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PORC_DTO_ACT, ' +
          'COALESCE((SELECT C.PRECIO_ULT_COMPRA_SKUC ' +
          'FROM fza_articulos_skus_costes C ' +
          'WHERE C.CODIGO_UNIDAD_SKU_SKUC = NULLIF(U.SKU, '''') LIMIT 1), ' +
          '(SELECT T.PRECIO_COSTE_ARTTAR FROM fza_articulos_tarifas T ' +
          'WHERE T.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND T.CODIGO_UNIDAD_ARTTAR = NULLIF(U.SKU, '''') ' +
          'AND T.CODIGO_TAR_ARTTAR = :P_TAR_ORIG ' +
          'AND T.ESACTIVO_ARTTAR = ''S'' ' +
          'AND (T.FECHA_DESDE_ARTTAR IS NULL OR ' +
          'T.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
          'AND (T.FECHA_HASTA_ARTTAR IS NULL OR ' +
          'T.FECHA_HASTA_ARTTAR >= CURDATE()) ' +
          'ORDER BY T.FECHA_DESDE_ARTTAR DESC, ' +
          'T.CODIGO_UNICO_ARTTAR DESC LIMIT 1), ' +
          '(SELECT AP.PRECIO_ULT_COMPRA_AP ' +
          'FROM fza_articulos_proveedores AP ' +
          'WHERE AP.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
          'ORDER BY AP.ESPROVEEDORPRINCIPAL_AP = ''S'' DESC, ' +
          'AP.FECHA_VALIDEZ_AP DESC, AP.CODIGO_PRV_AP LIMIT 1)) ' +
          'AS PRECIO_COSTE,';
      end;
  else
    Result := '';
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ExpresionYaCargado(
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcTarifa:
      Result :=
        'CASE WHEN EXISTS (SELECT 1 FROM fza_articulos_tarifas ta ' +
        'WHERE ta.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
        'AND ta.CODIGO_TAR_ARTTAR = :P_TARIFA_CHK) ' +
        'THEN ''S'' ELSE ''N'' END';
    mcInventario:
      Result :=
        'CASE WHEN EXISTS (SELECT 1 FROM fza_inventarios_lineas il ' +
        'WHERE il.CODIGO_EMP_INVLIN = :P_INV_EMP_C ' +
        'AND il.CODIGO_ALM_INVLIN = :P_INV_ALM_C ' +
        'AND il.SERIE_INV_INVLIN = :P_INV_SER_C ' +
        'AND il.NUMERO_INV_INVLIN = :P_INV_NRO_C ' +
        'AND il.CODIGO_ART_INVLIN = a.CODIGO_ART_ART) ' +
        'THEN ''S'' ELSE ''N'' END';
    mcDocumentoTrabajo:
      Result :=
        'CASE WHEN EXISTS (SELECT 1 FROM fza_documentos_trabajo_lineas dl ' +
        'WHERE dl.ID_DTR_DTL = :P_DTR_CHK ' +
        'AND dl.CODIGO_ART_DTL = a.CODIGO_ART_ART) ' +
        'THEN ''S'' ELSE ''N'' END';
  else
    Result :=
      'CASE WHEN EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas SL ' +
      'WHERE SL.CODIGO_TARC_TARCLIN = :P_TARC_CHK ' +
      'AND SL.CODIGO_ART_TARCLIN = a.CODIGO_ART_ART ' +
      'AND SL.CODIGO_UNIDAD_SKU_TARCLIN = U.SKU) ' +
      'THEN ''S'' ELSE ''N'' END';
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.CondicionExcluirCargados(
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcTarifa:
      Result :=
        'NOT EXISTS (SELECT 1 FROM fza_articulos_tarifas tx ' +
        'WHERE tx.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
        'AND tx.CODIGO_TAR_ARTTAR = :P_TARIFA_EXCL)';
    mcInventario:
      Result :=
        'NOT EXISTS (SELECT 1 FROM fza_inventarios_lineas ilx ' +
        'WHERE ilx.CODIGO_EMP_INVLIN = :P_INV_EMP_X ' +
        'AND ilx.CODIGO_ALM_INVLIN = :P_INV_ALM_X ' +
        'AND ilx.SERIE_INV_INVLIN = :P_INV_SER_X ' +
        'AND ilx.NUMERO_INV_INVLIN = :P_INV_NRO_X ' +
        'AND ilx.CODIGO_ART_INVLIN = a.CODIGO_ART_ART)';
    mcDocumentoTrabajo:
      Result :=
        'NOT EXISTS (SELECT 1 FROM fza_documentos_trabajo_lineas dlx ' +
        'WHERE dlx.ID_DTR_DTL = :P_DTR_EXCL ' +
        'AND dlx.CODIGO_ART_DTL = a.CODIGO_ART_ART)';
  else
    Result :=
      'NOT EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas SLX ' +
      'WHERE SLX.CODIGO_TARC_TARCLIN = :P_TARC_EXCL ' +
      'AND SLX.CODIGO_ART_TARCLIN = a.CODIGO_ART_ART ' +
      'AND SLX.CODIGO_UNIDAD_SKU_TARCLIN = U.SKU)';
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.CondicionAlmacenesSql(
  const ACampo, AAlmacenes: string): string;
begin
  if AAlmacenes = '' then
  begin
    Result := '1 = 0';
  end
  else
  begin
    Result := ACampo + ' IN (' + AAlmacenes + ')';
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.
  AnadirOrigenPreviewDocumento(
    ASql: TStrings;
    const AFiltros: TFiltrosCargaMasivaArticulos;
    const AAlmacenesStock, AAlmacenesVenta: string);
var
  sCampoAlmacenVenta: string;
  sSkuVenta: string;
begin
  sCampoAlmacenVenta :=
    'COALESCE(NULLIF(TRIM(FL.CODIGO_ALM_FACLIN), ''''), ' +
    'FC.CODIGO_ALM_FAC)';
  sSkuVenta :=
    'COALESCE(NULLIF(TRIM(FL.CODIGO_UNIDAD_FACLIN), ''''), ' +
    'FL.CODIGO_ART_FACLIN)';
  ASql.Add('SELECT A.CODIGO_ART_ART, U.CODIGO_UNIDAD_SKU,');
  ASql.Add('A.DESCRIPCION_ART, A.CODIGO_FAM_ART, F.NOMBRE_FAM_FAM,');
  // FZ-ISSUE-324: decimales del stock según la unidad
  ASql.Add('A.TIPO_CANTIDAD_ART,');
  ASql.Add('(SELECT GROUP_CONCAT(AP.CODIGO_PRV_AP)');
  ASql.Add('FROM fza_articulos_proveedores AP');
  ASql.Add('WHERE AP.CODIGO_ART_AP = A.CODIGO_ART_ART) AS PROVEEDORES,');
  ASql.Add('COALESCE((SELECT SUM(ST.CANTIDAD_STK)');
  ASql.Add('FROM fza_articulos_stockactual ST');
  ASql.Add('WHERE ST.CODIGO_UNIDAD_STK = U.CODIGO_UNIDAD_SKU');
  ASql.Add('AND ' + CondicionAlmacenesSql(
    'ST.CODIGO_ALM_STK', AAlmacenesStock) + '), 0) AS STOCK_TOTAL,');
  if AFiltros.FiltrarVentas then
  begin
    ASql.Add('COALESCE(V.NUM_VENTAS, 0) AS NUM_VENTAS,');
  end
  else
  begin
    ASql.Add('0 AS NUM_VENTAS,');
  end;
  ASql.Add('CASE WHEN EXISTS (SELECT 1');
  ASql.Add('FROM fza_documentos_trabajo_lineas DL');
  ASql.Add('WHERE DL.ID_DTR_DTL = :P_DTR_CHK');
  ASql.Add('AND DL.CODIGO_UNIDAD_DTL = U.CODIGO_UNIDAD_SKU)');
  ASql.Add('THEN ''S'' ELSE ''N'' END AS YA_CARGADO');
  ASql.Add('FROM (SELECT DISTINCT');
  ASql.Add('COALESCE(SK0.CODIGO_ART_SKU, S0.CODIGO_UNIDAD_STK)');
  ASql.Add('AS CODIGO_ART_ART, S0.CODIGO_UNIDAD_STK AS CODIGO_UNIDAD_SKU,');
  ASql.Add('COALESCE(SK0.ESACTIVO_SKU, ''S'') AS ESACTIVO_SKU,');
  ASql.Add('CASE WHEN SK0.CODIGO_UNIDAD_SKU IS NULL');
  ASql.Add('THEN ''N'' ELSE ''S'' END AS TIENE_MAESTRO_SKU');
  ASql.Add('FROM fza_articulos_stockactual S0');
  ASql.Add('LEFT JOIN fza_articulos_skus SK0');
  ASql.Add('ON SK0.CODIGO_UNIDAD_SKU = S0.CODIGO_UNIDAD_STK');
  ASql.Add('WHERE ' + CondicionAlmacenesSql(
    'S0.CODIGO_ALM_STK', AAlmacenesStock) + ') U');
  ASql.Add('JOIN fza_articulos A');
  ASql.Add('ON A.CODIGO_ART_ART = U.CODIGO_ART_ART');
  ASql.Add('LEFT JOIN fza_articulos_familias F');
  ASql.Add('ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART');
  if AFiltros.FiltrarVentas then
  begin
    ASql.Add('LEFT JOIN (SELECT FL.CODIGO_ART_FACLIN AS CODIGO_ART,');
    ASql.Add(sSkuVenta + ' AS CODIGO_UNIDAD_SKU, COUNT(*) AS NUM_VENTAS');
    ASql.Add('FROM fza_facturas_lineas FL JOIN fza_facturas FC');
    ASql.Add('ON FC.NUMERO_FAC = FL.NUMERO_FAC_FACLIN');
    ASql.Add('AND FC.SERIE_FAC = FL.SERIE_FAC_FACLIN');
    ASql.Add('WHERE FC.FECHA_FAC >= :P_VTA_DESDE');
    ASql.Add('AND FC.FECHA_FAC < :P_VTA_HASTA');
    ASql.Add('AND COALESCE(FC.FASE_FAC, '''') <> ''CANCELADA''');
    ASql.Add('AND FL.CANTIDAD_FACLIN > 0');
    ASql.Add(SQLExcluirVentaRetirada(
      'FC.CODIGO_EMP_FAC', 'FC.SERIE_FAC', 'FC.NUMERO_FAC'));
    ASql.Add('AND ' + CondicionAlmacenesSql(
      sCampoAlmacenVenta, AAlmacenesVenta));
    ASql.Add('GROUP BY FL.CODIGO_ART_FACLIN, ' + sSkuVenta + ') V');
    ASql.Add('ON V.CODIGO_ART = A.CODIGO_ART_ART');
    ASql.Add('AND V.CODIGO_UNIDAD_SKU = U.CODIGO_UNIDAD_SKU');
  end;
  ASql.Add('WHERE 1 = 1');
end;

procedure TServicioCargaMasivaArticulosUniDAC.
  AnadirFiltroStockPreviewDocumento(
    ASql: TStrings;
    const AFiltros: TFiltrosCargaMasivaArticulos;
    const AAlmacenesStock: string);
begin
  ASql.Add('AND COALESCE((SELECT SUM(SR.CANTIDAD_STK)');
  ASql.Add('FROM fza_articulos_stockactual SR');
  ASql.Add('WHERE SR.CODIGO_UNIDAD_STK = U.CODIGO_UNIDAD_SKU');
  ASql.Add('AND ' + CondicionAlmacenesSql(
    'SR.CODIGO_ALM_STK', AAlmacenesStock) + '), 0) > ' +
    ':P_RESERVA_STOCK_ORIGEN');
  if AFiltros.SoloConStock then
  begin
    case AFiltros.StockCombinacion of
      scCualquiera:
        begin
          ASql.Add('AND EXISTS (SELECT 1');
          ASql.Add('FROM fza_articulos_stockactual SX');
          ASql.Add('WHERE SX.CODIGO_UNIDAD_STK = U.CODIGO_UNIDAD_SKU');
          ASql.Add('AND SX.CANTIDAD_STK > 0');
          ASql.Add('AND ' + CondicionAlmacenesSql(
            'SX.CODIGO_ALM_STK', AAlmacenesStock) + ')');
        end;
      scTodos:
        begin
          ASql.Add('AND (SELECT COUNT(DISTINCT SX.CODIGO_ALM_STK)');
          ASql.Add('FROM fza_articulos_stockactual SX');
          ASql.Add('WHERE SX.CODIGO_UNIDAD_STK = U.CODIGO_UNIDAD_SKU');
          ASql.Add('AND SX.CANTIDAD_STK > 0');
          ASql.Add('AND ' + CondicionAlmacenesSql(
            'SX.CODIGO_ALM_STK', AAlmacenesStock) + ') = ' +
            IntToStr(Length(AFiltros.CodigosAlmacen)));
        end;
      scSumaPositiva:
        begin
          ASql.Add('AND COALESCE((SELECT SUM(SX.CANTIDAD_STK)');
          ASql.Add('FROM fza_articulos_stockactual SX');
          ASql.Add('WHERE SX.CODIGO_UNIDAD_STK = U.CODIGO_UNIDAD_SKU');
          ASql.Add('AND ' + CondicionAlmacenesSql(
            'SX.CODIGO_ALM_STK', AAlmacenesStock) + '), 0) > 0');
        end;
    end;
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.
  AnadirFiltroStockAlmacenVentaPreviewDocumento(
    ASql: TStrings;
    const AFiltros: TFiltrosCargaMasivaArticulos;
    const AAlmacenesVenta: string);
begin
  if AFiltros.FiltrarStockAlmacenVenta then
  begin
    ASql.Add('AND COALESCE((SELECT SUM(SD.CANTIDAD_STK)');
    ASql.Add('FROM fza_articulos_stockactual SD');
    ASql.Add('WHERE SD.CODIGO_UNIDAD_STK = U.CODIGO_UNIDAD_SKU');
    ASql.Add('AND ' + CondicionAlmacenesSql(
      'SD.CODIGO_ALM_STK', AAlmacenesVenta) + '), 0) <= ' +
      ':P_STOCK_MAXIMO_ALMACEN_VENTA');
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.
  AnadirFiltroFamiliasPreviewDocumento(
    ASql: TStrings;
    const AFiltros: TFiltrosCargaMasivaArticulos;
    const AFamilias: string);
begin
  if AFamilias <> '' then
  begin
    if AFiltros.PropagarFamilias then
    begin
      ASql.Add('AND A.CODIGO_FAM_ART IN (WITH RECURSIVE ARBOL AS (');
      ASql.Add('SELECT CODIGO_FAM_FAM, CODIGO_PADRE_FAM');
      ASql.Add('FROM fza_articulos_familias');
      ASql.Add('WHERE CODIGO_FAM_FAM IN (' + AFamilias + ') UNION ALL');
      ASql.Add('SELECT H.CODIGO_FAM_FAM, H.CODIGO_PADRE_FAM');
      ASql.Add('FROM fza_articulos_familias H JOIN ARBOL A2');
      ASql.Add('ON H.CODIGO_PADRE_FAM = A2.CODIGO_FAM_FAM)');
      ASql.Add('SELECT CODIGO_FAM_FAM FROM ARBOL)');
    end
    else
    begin
      ASql.Add('AND A.CODIGO_FAM_ART IN (' + AFamilias + ')');
    end;
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.
  AnadirFiltrosCatalogoPreviewDocumento(
    ASql: TStrings;
    const AFiltros: TFiltrosCargaMasivaArticulos;
    const AProveedores, APropiedades: string);
begin
  if AProveedores <> '' then
  begin
    ASql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_proveedores APX');
    ASql.Add('WHERE APX.CODIGO_ART_AP = A.CODIGO_ART_ART');
    ASql.Add('AND APX.CODIGO_PRV_AP IN (' + AProveedores + ')');
    if AFiltros.SoloProveedorPrincipal then
    begin
      ASql.Add('AND APX.ESPROVEEDORPRINCIPAL_AP = ''S''');
    end;
    ASql.Add(')');
  end;
  if APropiedades <> '' then
  begin
    ASql.Add('AND (EXISTS (SELECT 1');
    ASql.Add('FROM fza_propiedades_valores PVS');
    ASql.Add('LEFT JOIN fza_articulos_propiedades PPS');
    ASql.Add('ON PPS.CODIGO_ART_ART = A.CODIGO_ART_ART');
    ASql.Add('AND PPS.CODIGO_PROP_ARTPROP = PVS.ID_PROP_PV');
    ASql.Add('AND PPS.CODIGO_UNIDAD_ARTPROP = CASE');
    ASql.Add('WHEN U.TIENE_MAESTRO_SKU = ''S''');
    ASql.Add('THEN U.CODIGO_UNIDAD_SKU ELSE NULL END');
    ASql.Add('LEFT JOIN fza_articulos_propiedades PPC');
    ASql.Add('ON PPC.CODIGO_ART_ART = A.CODIGO_ART_ART');
    ASql.Add('AND PPC.CODIGO_PROP_ARTPROP = PVS.ID_PROP_PV');
    ASql.Add('AND PPC.CODIGO_UNIDAD_ARTPROP = CASE');
    ASql.Add('WHEN U.TIENE_MAESTRO_SKU = ''S'' AND');
    ASql.Add('CHAR_LENGTH(U.CODIGO_UNIDAD_SKU) - CHAR_LENGTH(');
    ASql.Add('REPLACE(U.CODIGO_UNIDAD_SKU, ''/'', '''')) >= 2');
    ASql.Add('THEN SUBSTRING_INDEX(U.CODIGO_UNIDAD_SKU, ''/'', 2)');
    ASql.Add('ELSE NULL END');
    ASql.Add('LEFT JOIN fza_articulos_propiedades PPA');
    ASql.Add('ON PPA.CODIGO_ART_ART = A.CODIGO_ART_ART');
    ASql.Add('AND PPA.CODIGO_PROP_ARTPROP = PVS.ID_PROP_PV');
    ASql.Add('AND PPA.CODIGO_UNIDAD_ARTPROP = ''''');
    ASql.Add('WHERE PVS.ID_PV_ARTPROP IN (' + APropiedades + ')');
    ASql.Add('AND PVS.ID_PV_ARTPROP = COALESCE(');
    ASql.Add('PPS.ID_PV_ARTPROP, PPC.ID_PV_ARTPROP,');
    ASql.Add('PPA.ID_PV_ARTPROP)))');
  end;
  if AFiltros.AplicarFechaAlta then
  begin
    ASql.Add('AND A.INSTANTE_ALTA >= :P_ALTA_DESDE');
    ASql.Add('AND A.INSTANTE_ALTA < :P_ALTA_HASTA');
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.
  AnadirFiltroVentasPreviewDocumento(
    ASql: TStrings;
    const AFiltros: TFiltrosCargaMasivaArticulos);
begin
  if AFiltros.FiltrarVentas then
  begin
    if AFiltros.ConVentas then
    begin
      ASql.Add('AND COALESCE(V.NUM_VENTAS, 0) >= :P_NUM_MIN_VTAS');
    end
    else
    begin
      ASql.Add('AND COALESCE(V.NUM_VENTAS, 0) = 0');
    end;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConstruirSqlPreviewDocumento(
  const AFiltros: TFiltrosCargaMasivaArticulos): string;
var
  oSql: TStringList;
  sAlmacenesStock: string;
  sAlmacenesVenta: string;
  sFamilias: string;
  sPropiedades: string;
  sProveedores: string;
begin
  sAlmacenesStock := StrArrToCsvSql(AFiltros.CodigosAlmacen);
  sAlmacenesVenta := StrArrToCsvSql(AFiltros.CodigosAlmacenVenta);
  sFamilias := StrArrToCsvSql(AFiltros.CodigosFamilia);
  sPropiedades := IntArrToCsvSql(AFiltros.IdsValorPropiedad);
  sProveedores := StrArrToCsvSql(AFiltros.CodigosProveedor);
  oSql := TStringList.Create;
  try
    AnadirOrigenPreviewDocumento(
      oSql, AFiltros, sAlmacenesStock, sAlmacenesVenta);
    if AFiltros.SoloActivos then
    begin
      oSql.Add('AND A.ESACTIVO_ART = ''S''');
      oSql.Add('AND U.ESACTIVO_SKU = ''S''');
    end;
    if AFiltros.ExcluirYaCargados then
    begin
      oSql.Add('AND NOT EXISTS (SELECT 1');
      oSql.Add('FROM fza_documentos_trabajo_lineas DLX');
      oSql.Add('WHERE DLX.ID_DTR_DTL = :P_DTR_EXCL');
      oSql.Add('AND DLX.CODIGO_UNIDAD_DTL = U.CODIGO_UNIDAD_SKU)');
    end;
    AnadirFiltroStockPreviewDocumento(
      oSql, AFiltros, sAlmacenesStock);
    AnadirFiltroFamiliasPreviewDocumento(oSql, AFiltros, sFamilias);
    AnadirFiltrosCatalogoPreviewDocumento(
      oSql, AFiltros, sProveedores, sPropiedades);
    AnadirFiltroVentasPreviewDocumento(oSql, AFiltros);
    AnadirFiltroStockAlmacenVentaPreviewDocumento(
      oSql, AFiltros, sAlmacenesVenta);
    oSql.Add('ORDER BY A.CODIGO_FAM_ART, A.CODIGO_ART_ART,');
    oSql.Add('U.CODIGO_UNIDAD_SKU');
    Result := oSql.Text;
  finally
    FreeAndNil(oSql);
  end;
end;

procedure AnadirOrigenPreviewArticulos(
  ASql: TStrings;
  const AAlmacenes, AColumnasExtra, AYaCargado, AUniones: string);
begin
  ASql.Add('SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART,');
  ASql.Add('a.CODIGO_FAM_ART, f.NOMBRE_FAM_FAM,');
  // FZ-ISSUE-324: decimales del stock según la unidad
  ASql.Add('a.TIPO_CANTIDAD_ART,');
  ASql.Add('(SELECT GROUP_CONCAT(ap.CODIGO_PRV_AP)');
  ASql.Add('FROM fza_articulos_proveedores ap');
  ASql.Add('WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART) AS PROVEEDORES,');
  ASql.Add('COALESCE((SELECT SUM(s.CANTIDAD_STK)');
  ASql.Add('FROM fza_articulos_stockactual s');
  ASql.Add('LEFT JOIN fza_articulos_skus sk');
  ASql.Add('ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK');
  ASql.Add('WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK)');
  ASql.Add('= a.CODIGO_ART_ART');
  if AAlmacenes <> '' then
    ASql.Add('AND s.CODIGO_ALM_STK IN (' + AAlmacenes + ')');
  ASql.Add('), 0) AS STOCK_TOTAL,');
  if AColumnasExtra <> '' then
    ASql.Add(AColumnasExtra);
  ASql.Add(AYaCargado + ' AS YA_CARGADO');
  ASql.Add('FROM fza_articulos a LEFT JOIN fza_articulos_familias f');
  ASql.Add('ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART');
  if AUniones <> '' then
  begin
    ASql.Add(AUniones);
  end;
  ASql.Add('WHERE 1 = 1');
end;

procedure AnadirFiltroStockPreviewArticulos(
  ASql: TStrings;
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AAlmacenes: string);
begin
  if AFiltros.SoloConStock and (AAlmacenes <> '') then
  begin
    case AFiltros.StockCombinacion of
      scCualquiera:
        begin
          ASql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_stockactual s2');
          ASql.Add('LEFT JOIN fza_articulos_skus sk2');
          ASql.Add('ON sk2.CODIGO_UNIDAD_SKU = s2.CODIGO_UNIDAD_STK');
          ASql.Add('WHERE COALESCE(sk2.CODIGO_ART_SKU,');
          ASql.Add('s2.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
          ASql.Add('AND s2.CANTIDAD_STK > 0');
          ASql.Add('AND s2.CODIGO_ALM_STK IN (' + AAlmacenes + '))');
        end;
      scTodos:
        begin
          ASql.Add('AND (SELECT COUNT(DISTINCT s2.CODIGO_ALM_STK)');
          ASql.Add('FROM fza_articulos_stockactual s2');
          ASql.Add('LEFT JOIN fza_articulos_skus sk2');
          ASql.Add('ON sk2.CODIGO_UNIDAD_SKU = s2.CODIGO_UNIDAD_STK');
          ASql.Add('WHERE COALESCE(sk2.CODIGO_ART_SKU,');
          ASql.Add('s2.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
          ASql.Add('AND s2.CANTIDAD_STK > 0');
          ASql.Add('AND s2.CODIGO_ALM_STK IN (' + AAlmacenes + ')) = ' +
            IntToStr(Length(AFiltros.CodigosAlmacen)));
        end;
      scSumaPositiva:
        begin
          ASql.Add('AND COALESCE((SELECT SUM(s2.CANTIDAD_STK)');
          ASql.Add('FROM fza_articulos_stockactual s2');
          ASql.Add('LEFT JOIN fza_articulos_skus sk2');
          ASql.Add('ON sk2.CODIGO_UNIDAD_SKU = s2.CODIGO_UNIDAD_STK');
          ASql.Add('WHERE COALESCE(sk2.CODIGO_ART_SKU,');
          ASql.Add('s2.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
          ASql.Add('AND s2.CODIGO_ALM_STK IN (' + AAlmacenes + ')), 0) > 0');
        end;
    end;
  end;
end;

procedure AnadirFiltroFamiliasPreviewArticulos(
  ASql: TStrings;
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AFamilias: string);
begin
  if AFamilias <> '' then
  begin
    if AFiltros.PropagarFamilias then
    begin
      ASql.Add('AND a.CODIGO_FAM_ART IN (WITH RECURSIVE arbol AS (');
      ASql.Add('SELECT CODIGO_FAM_FAM, CODIGO_PADRE_FAM');
      ASql.Add('FROM fza_articulos_familias');
      ASql.Add('WHERE CODIGO_FAM_FAM IN (' + AFamilias + ') UNION ALL');
      ASql.Add('SELECT h.CODIGO_FAM_FAM, h.CODIGO_PADRE_FAM');
      ASql.Add('FROM fza_articulos_familias h JOIN arbol a2');
      ASql.Add('ON h.CODIGO_PADRE_FAM = a2.CODIGO_FAM_FAM)');
      ASql.Add('SELECT CODIGO_FAM_FAM FROM arbol)');
    end
    else
      ASql.Add('AND a.CODIGO_FAM_ART IN (' + AFamilias + ')');
  end;
end;

procedure AnadirFiltrosCatalogoPreviewArticulos(
  ASql: TStrings;
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AProveedores, APropiedades: string);
begin
  if AProveedores <> '' then
  begin
    ASql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_proveedores apx');
    ASql.Add('WHERE apx.CODIGO_ART_AP = a.CODIGO_ART_ART');
    ASql.Add('AND apx.CODIGO_PRV_AP IN (' + AProveedores + ')');
    if AFiltros.SoloProveedorPrincipal then
      ASql.Add('AND apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
    ASql.Add(')');
  end;
  if APropiedades <> '' then
  begin
    ASql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_propiedades pp');
    ASql.Add('WHERE pp.CODIGO_ART_ART = a.CODIGO_ART_ART');
    ASql.Add('AND pp.ID_PV_ARTPROP IN (' + APropiedades + '))');
  end;
  if AFiltros.AplicarFechaAlta then
  begin
    ASql.Add('AND a.INSTANTE_ALTA >= :P_ALTA_DESDE');
    ASql.Add('AND a.INSTANTE_ALTA < :P_ALTA_HASTA');
  end;
end;

procedure AnadirFiltroVentasPreviewArticulos(
  ASql: TStrings;
  const AFiltros: TFiltrosCargaMasivaArticulos);
begin
  if AFiltros.FiltrarVentas then
  begin
    if AFiltros.ConVentas then
    begin
      ASql.Add('AND (SELECT COUNT(*) FROM fza_facturas_lineas fl');
      ASql.Add(
        'JOIN fza_facturas fc ON fc.NUMERO_FAC = fl.NUMERO_FAC_FACLIN');
      ASql.Add('AND fc.SERIE_FAC = fl.SERIE_FAC_FACLIN');
      ASql.Add('WHERE fl.CODIGO_ART_FACLIN = a.CODIGO_ART_ART');
      ASql.Add('AND fc.FECHA_FAC >= :P_VTA_DESDE');
      ASql.Add('AND fc.FECHA_FAC < :P_VTA_HASTA)');
      ASql.Add('>= :P_NUM_MIN_VTAS');
    end
    else
    begin
      ASql.Add('AND NOT EXISTS (SELECT 1 FROM fza_facturas_lineas fl');
      ASql.Add(
        'JOIN fza_facturas fc ON fc.NUMERO_FAC = fl.NUMERO_FAC_FACLIN');
      ASql.Add('AND fc.SERIE_FAC = fl.SERIE_FAC_FACLIN');
      ASql.Add('WHERE fl.CODIGO_ART_FACLIN = a.CODIGO_ART_ART');
      ASql.Add('AND fc.FECHA_FAC >= :P_VTA_DESDE');
      ASql.Add('AND fc.FECHA_FAC < :P_VTA_HASTA)');
    end;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConstruirSqlPreviewArticulos(
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos): string;
var
  oSql: TStringList;
  sAlmacenes: string;
  sFamilias: string;
  sProveedores: string;
  sPropiedades: string;
  sUniones: string;
begin
  sAlmacenes := StrArrToCsvSql(AFiltros.CodigosAlmacen);
  sFamilias := StrArrToCsvSql(AFiltros.CodigosFamilia);
  sProveedores := StrArrToCsvSql(AFiltros.CodigosProveedor);
  sPropiedades := IntArrToCsvSql(AFiltros.IdsValorPropiedad);
  sUniones := '';
  if AContexto.Modo = mcSesionTarifa then
  begin
    // Una fila general y las claves propias de origen y destino. Una
    // tarifa destino vacía debe conservar las tallas y SKU del origen.
    // UNION elimina repeticiones de un SKU con varios periodos de precio.
    sUniones :=
      'JOIN (SELECT CODIGO_ART_ART AS ARTICULO, ' +
      ''''' AS SKU FROM fza_articulos UNION ' +
      'SELECT CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR ' +
      'FROM fza_articulos_tarifas ' +
      'WHERE CODIGO_TAR_ARTTAR IN (:P_TAR_DEST_SKU, :P_TAR_ORIG_SKU) ' +
      'AND ESACTIVO_ARTTAR = ''S'' ' +
      'AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') <> '''') U ' +
      'ON U.ARTICULO = a.CODIGO_ART_ART';
  end;
  oSql := TStringList.Create;
  try
    AnadirOrigenPreviewArticulos(
      oSql, sAlmacenes, ColumnasExtra(AContexto),
      ExpresionYaCargado(AContexto), sUniones);
    if AFiltros.SoloActivos then
      oSql.Add('AND a.ESACTIVO_ART = ''S''');
    if AFiltros.ExcluirYaCargados then
      oSql.Add('AND ' + CondicionExcluirCargados(AContexto));
    if (AContexto.Modo = mcInventario) and AFiltros.SoloNegativos then
    begin
      oSql.Add('AND EXISTS (SELECT 1');
      oSql.Add('FROM fza_articulos_stockactual sn');
      oSql.Add('LEFT JOIN fza_articulos_skus skn');
      oSql.Add('ON skn.CODIGO_UNIDAD_SKU = sn.CODIGO_UNIDAD_STK');
      oSql.Add('WHERE COALESCE(skn.CODIGO_ART_SKU,');
      oSql.Add('sn.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
      oSql.Add('AND sn.CODIGO_ALM_STK = :P_INV_ALMACEN');
      oSql.Add('AND sn.CANTIDAD_STK < 0)');
    end
    else
      AnadirFiltroStockPreviewArticulos(oSql, AFiltros, sAlmacenes);
    AnadirFiltroFamiliasPreviewArticulos(oSql, AFiltros, sFamilias);
    AnadirFiltrosCatalogoPreviewArticulos(
      oSql, AFiltros, sProveedores, sPropiedades);
    AnadirFiltroVentasPreviewArticulos(oSql, AFiltros);
    if AContexto.Modo = mcSesionTarifa then
    begin
      oSql.Add('ORDER BY a.CODIGO_FAM_ART, a.CODIGO_ART_ART, U.SKU');
    end
    else
    begin
      oSql.Add('ORDER BY a.CODIGO_FAM_ART, a.CODIGO_ART_ART');
    end;
    Result := oSql.Text;
  finally
    FreeAndNil(oSql);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConstruirSqlPreview(
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcDocumentoTrabajo:
      Result := ConstruirSqlPreviewDocumento(AFiltros);
  else
    Result := ConstruirSqlPreviewArticulos(AFiltros, AContexto);
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.VincularParametrosPreview(
  AConsulta: TUniQuery;
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos);

  procedure Cadena(const ANombre, AValor: string);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsString := AValor;
    end;
  end;

  procedure Entero(const ANombre: string; AValor: Integer);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsInteger := AValor;
    end;
  end;

  procedure EnteroGrande(const ANombre: string; AValor: Int64);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsLargeInt := AValor;
    end;
  end;

  procedure Decimal(const ANombre: string; AValor: Double);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsFloat := AValor;
    end;
  end;

begin
  if Assigned(AConsulta.Params.FindParam('P_ALTA_DESDE')) then
  begin
    AConsulta.ParamByName('P_ALTA_DESDE').AsDateTime :=
      AFiltros.FechaAltaDesde;
    AConsulta.ParamByName('P_ALTA_HASTA').AsDateTime :=
      AFiltros.FechaAltaHasta + 1;
  end;
  if Assigned(AConsulta.Params.FindParam('P_VTA_DESDE')) then
  begin
    AConsulta.ParamByName('P_VTA_DESDE').AsDateTime := AFiltros.VentaDesde;
    AConsulta.ParamByName('P_VTA_HASTA').AsDateTime :=
      AFiltros.VentaHasta + 1;
  end;
  Entero('P_NUM_MIN_VTAS', AFiltros.NumeroMinimoVentas);
  Decimal('P_RESERVA_STOCK_ORIGEN', AFiltros.ReservaStockOrigen);
  Decimal(
    'P_STOCK_MAXIMO_ALMACEN_VENTA',
    AFiltros.StockMaximoAlmacenVenta);
  Cadena('P_TARIFA_CHK', AContexto.CodigoTarifa);
  Cadena('P_TARIFA_EXCL', AContexto.CodigoTarifa);
  Cadena('P_TARIFA_ORIG_S', AContexto.CodigoTarifaOrigen);
  Cadena('P_TARIFA_ORIG_F', AContexto.CodigoTarifaOrigen);
  Entero('P_INV_SOLO_NEGATIVOS', Ord(AFiltros.SoloNegativos));
  Cadena('P_INV_ALMACEN', AContexto.AlmacenInventario);
  Cadena('P_INV_ALMACEN_PMP', AContexto.AlmacenInventario);
  Cadena('P_INV_EMP_C', AContexto.EmpresaInventario);
  Cadena('P_INV_ALM_C', AContexto.AlmacenInventario);
  Cadena('P_INV_SER_C', AContexto.SerieInventario);
  Cadena('P_INV_NRO_C', AContexto.NumeroInventario);
  Cadena('P_INV_EMP_X', AContexto.EmpresaInventario);
  Cadena('P_INV_ALM_X', AContexto.AlmacenInventario);
  Cadena('P_INV_SER_X', AContexto.SerieInventario);
  Cadena('P_INV_NRO_X', AContexto.NumeroInventario);
  EnteroGrande('P_DTR_CHK', AContexto.IdDocumentoTrabajo);
  EnteroGrande('P_DTR_EXCL', AContexto.IdDocumentoTrabajo);
  Entero('P_TARC_CHK', AContexto.CodigoSesionTarifa);
  Entero('P_TARC_EXCL', AContexto.CodigoSesionTarifa);
  Cadena('P_TAR_ORIG', AContexto.TarifaOrigenSesion);
  Cadena('P_TAR_ORIG_SKU', AContexto.TarifaOrigenSesion);
  Cadena('P_TAR_DEST_SKU', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_SAL', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_FIN', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_DTO', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_PDTO', AContexto.TarifaDestinoSesion);
end;

function TServicioCargaMasivaArticulosUniDAC.Previsualizar(
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos):
  IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(ConstruirSqlPreview(AFiltros, AContexto));
  try
    VincularParametrosPreview(oConsulta, AFiltros, AContexto);
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.AjustarPrecio(
  APrecio: Double;
  const AParametros: TParametrosInsercionTarifa): Double;
var
  dValor: Double;
begin
  Result := APrecio;
  if AParametros.AjustarPrecio and (APrecio > 0) and
     (AParametros.MultiploAjuste > 0) then
  begin
    dValor := Ceil(APrecio / AParametros.MultiploAjuste) *
      AParametros.MultiploAjuste - AParametros.RestarAjuste;
    if dValor < 0 then
    begin
      dValor := 0;
    end;
    Result := Round(dValor * 100) / 100;
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.CalcularPreciosTarifa(
  APrecioSalidaOrigen: Double;
  APrecioFinalOrigen: Double;
  const AParametros: TParametrosInsercionTarifa;
  out APrecioSalida: Double;
  out APrecioFinal: Double;
  out APorcentajeDescuento: Double);
var
  dBaseSalida: Double;
begin
  APorcentajeDescuento := AParametros.PorcentajeDescuento;
  if APrecioSalidaOrigen > 0 then
  begin
    dBaseSalida := APrecioSalidaOrigen;
  end
  else
  begin
    dBaseSalida := APrecioFinalOrigen;
  end;
  APrecioSalida := dBaseSalida;
  if APorcentajeDescuento > 0 then
  begin
    APrecioFinal := dBaseSalida * (1 - APorcentajeDescuento / 100);
  end
  else
  begin
    APrecioFinal := dBaseSalida;
  end;
  if AParametros.AjustarPrecio then
  begin
    if AParametros.AlcanceAjuste in [aaSoloSalida, aaAmbos] then
    begin
      APrecioSalida := AjustarPrecio(APrecioSalida, AParametros);
    end;
    if AParametros.AlcanceAjuste in [aaSoloFinal, aaAmbos] then
    begin
      APrecioFinal := AjustarPrecio(APrecioFinal, AParametros);
    end;
    if (APrecioSalida > 0) and (APrecioSalida <> APrecioFinal) then
    begin
      APorcentajeDescuento := (1 - APrecioFinal / APrecioSalida) * 100;
    end
    else if APrecioSalida = APrecioFinal then
    begin
      APorcentajeDescuento := 0;
    end;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarTarifa(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionTarifa):
  TResultadoInsercionCargaMasiva;
var
  dDescuento: Double;
  dDescuentoEuros: Double;
  dFinal: Double;
  dOrigenFinal: Double;
  dOrigenSalida: Double;
  dSalida: Double;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
  iCodigo: Integer;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_TARIFA);
  try
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          dOrigenSalida := oDatos.FieldByName('PRECIO_SALIDA_ORIG').AsFloat;
          dOrigenFinal := oDatos.FieldByName('PRECIO_FINAL_ORIG').AsFloat;
          CalcularPreciosTarifa(
            dOrigenSalida,
            dOrigenFinal,
            AParametros,
            dSalida,
            dFinal,
            dDescuento);
          if (dOrigenSalida = 0) and (dOrigenFinal = 0) then
          begin
            dSalida := 0;
            dFinal := 0;
            dDescuento := AParametros.PorcentajeDescuento;
          end;
          dDescuentoEuros := dSalida - dFinal;
          if dDescuentoEuros < 0 then
          begin
            dDescuentoEuros := 0;
          end;
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          oInsercion.ParamByName('ART').AsString := sArticulo;
          oInsercion.ParamByName('TARIFA').AsString := AParametros.CodigoTarifa;
          oInsercion.ParamByName('SALIDA').AsFloat := dSalida;
          oInsercion.ParamByName('FINAL').AsFloat := dFinal;
          oInsercion.ParamByName('DTO').AsFloat := dDescuentoEuros;
          oInsercion.ParamByName('PDTO').AsFloat := dDescuento;
          oInsercion.ParamByName('DESDE').AsDateTime := AParametros.FechaDesde;
          if AParametros.UsaFechaHasta then
          begin
            oInsercion.ParamByName('HASTA').AsDateTime :=
              AParametros.FechaHasta;
          end
          else
          begin
            oInsercion.ParamByName('HASTA').Clear;
          end;
          oInsercion.ParamByName('USR').AsString := AParametros.Usuario;
          oInsercion.ParamByName('USR2').AsString := AParametros.Usuario;
          oInsercion.Execute;
          oCodigos.Add(sArticulo);
        end;
        oDatos.Next;
      end;
      for iCodigo := 0 to oCodigos.Count - 1 do
        EncolarPrecioPrestaShop(
          FConexion,
          oCodigos[iCodigo],
          AParametros.Usuario);
      FConexion.Commit;
      Result.NumeroLineas := oCodigos.Count;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
    if oCodigos.Count > 0 then
      SolicitarProcesadoPrestaShop;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ProximaLineaInventario(
  const AParametros: TParametrosInsercionInventario): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_PROXIMA_LINEA_INVENTARIO);
  try
    oConsulta.ParamByName('EMP').AsString := AParametros.Empresa;
    oConsulta.ParamByName('ALM').AsString := AParametros.Almacen;
    oConsulta.ParamByName('SER').AsString := AParametros.Serie;
    oConsulta.ParamByName('NRO').AsString := AParametros.Numero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('PROX').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// FZ-ISSUE-306: True si el inventario lleva la marca de solo negativos.
// AExisteMarca es False si falta la columna (script 794 sin aplicar).
function TServicioCargaMasivaArticulosUniDAC.EsInventarioSoloNegativos(
  const AParametros: TParametrosInsercionInventario;
  out AExisteMarca: Boolean): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  oConsulta := CrearConsulta(SQL_EXISTE_MARCA_SOLO_NEGATIVOS);
  try
    oConsulta.Open;
    AExisteMarca := oConsulta.FieldByName('N').AsInteger > 0;
    if AExisteMarca then
    begin
      oConsulta.Close;
      oConsulta.SQL.Text := SQL_LEER_MARCA_SOLO_NEGATIVOS;
      oConsulta.ParamByName('EMP').AsString := AParametros.Empresa;
      oConsulta.ParamByName('ALM').AsString := AParametros.Almacen;
      oConsulta.ParamByName('SER').AsString := AParametros.Serie;
      oConsulta.ParamByName('NRO').AsString := AParametros.Numero;
      oConsulta.Open;
      Result := (not oConsulta.IsEmpty) and
        (oConsulta.FieldByName('MARCA').AsString = 'S');
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Una carga de negativos solo en un inventario vacío o ya de negativos, y
// una normal nunca en uno de negativos.
procedure TServicioCargaMasivaArticulosUniDAC.ComprobarModoInventario(
  const AParametros: TParametrosInsercionInventario;
  AConLineas: Boolean);
var
  bExisteMarca: Boolean;
  bSoloNegativos: Boolean;
begin
  bSoloNegativos := EsInventarioSoloNegativos(AParametros, bExisteMarca);
  if AParametros.SoloNegativos and not bExisteMarca then
    raise Exception.Create(SErrorInventarioSoloNegativosSinScript);
  if AParametros.SoloNegativos and AConLineas and not bSoloNegativos then
    raise Exception.Create(SErrorInventarioConLineasNormales);
  if (not AParametros.SoloNegativos) and bSoloNegativos then
    raise Exception.Create(SErrorInventarioDeSoloNegativos);
end;

procedure TServicioCargaMasivaArticulosUniDAC.MarcarInventarioSoloNegativos(
  const AParametros: TParametrosInsercionInventario);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_MARCAR_SOLO_NEGATIVOS);
  try
    oConsulta.ParamByName('USR').AsString := AParametros.Usuario;
    oConsulta.ParamByName('EMP').AsString := AParametros.Empresa;
    oConsulta.ParamByName('ALM').AsString := AParametros.Almacen;
    oConsulta.ParamByName('SER').AsString := AParametros.Serie;
    oConsulta.ParamByName('NRO').AsString := AParametros.Numero;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Lote y caducidad de la fila de stock ('' y NULL si el SKU no tiene).
procedure TServicioCargaMasivaArticulosUniDAC.AsignarLoteInventario(
  AInsercion, AFila: TUniQuery);
begin
  AInsercion.ParamByName('LOTE').AsString :=
    AFila.FieldByName('LOTE').AsString;
  AInsercion.ParamByName('CADUCIDAD').DataType := ftDate;
  if AFila.FieldByName('CADUCIDAD').IsNull then
    AInsercion.ParamByName('CADUCIDAD').Clear
  else
    AInsercion.ParamByName('CADUCIDAD').AsDate :=
      AFila.FieldByName('CADUCIDAD').AsDateTime;
end;

procedure TServicioCargaMasivaArticulosUniDAC.InsertarSkusInventario(
  AInsercion: TUniQuery;
  const ACodigoArticulo: string;
  const AParametros: TParametrosInsercionInventario;
  var ALineaActual: Integer;
  var ANumeroLineas: Integer);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_SKUS_ARTICULO);
  try
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.ParamByName('ART2').AsString := ACodigoArticulo;
    oConsulta.ParamByName('ALM').AsString := AParametros.Almacen;
    oConsulta.ParamByName('SOLO_NEGATIVOS').AsInteger :=
      Ord(AParametros.SoloNegativos);
    oConsulta.ParamByName('SOLO_CON_STOCK').AsInteger :=
      Ord(AParametros.SoloConStock);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      AInsercion.ParamByName('LINEA').AsString :=
        Format('%.4d', [ALineaActual]);
      AInsercion.ParamByName('ART').AsString := ACodigoArticulo;
      AInsercion.ParamByName('SKU').AsString :=
        oConsulta.FieldByName('SKU').AsString;
      AInsercion.ParamByName('TEORICA').AsFloat := 0;
      AInsercion.ParamByName('DIFERENCIA').AsFloat := 0;
      AInsercion.ParamByName('PMP').AsFloat := 0;
      AInsercion.ParamByName('PMP_NUEVO').AsFloat := 0;
      AInsercion.ParamByName('COSTE_DIFERENCIA').AsFloat := 0;
      if AParametros.SoloNegativos then
      begin
        AInsercion.ParamByName('TEORICA').AsFloat :=
          oConsulta.FieldByName('CANTIDAD').AsFloat;
        AInsercion.ParamByName('DIFERENCIA').AsFloat :=
          -oConsulta.FieldByName('CANTIDAD').AsFloat;
        AInsercion.ParamByName('PMP').AsFloat :=
          oConsulta.FieldByName('PMP').AsFloat;
        AInsercion.ParamByName('PMP_NUEVO').AsFloat :=
          oConsulta.FieldByName('PMP').AsFloat;
        // FZ-ISSUE-306: como PRC_FZA_INVENTARIOS_CALCULAR_LINEAS, física
        // (0) por PMP menos teórica por PMP, a céntimos.
        AInsercion.ParamByName('COSTE_DIFERENCIA').AsFloat :=
          SimpleRoundTo(-oConsulta.FieldByName('CANTIDAD').AsFloat *
            oConsulta.FieldByName('PMP').AsFloat, -2);
      end;
      AsignarLoteInventario(AInsercion, oConsulta);
      AInsercion.ParamByName('DESCRIPCION').AsString :=
        oConsulta.FieldByName('DESC_ART').AsString;
      AInsercion.ParamByName('USR').AsString := AParametros.Usuario;
      AInsercion.ParamByName('USR2').AsString := AParametros.Usuario;
      AInsercion.Execute;
      Inc(ALineaActual);
      Inc(ANumeroLineas);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarInventario(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionInventario):
  TResultadoInsercionCargaMasiva;
var
  iLineaActual: Integer;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  iLineaActual := ProximaLineaInventario(AParametros);
  ComprobarModoInventario(AParametros, iLineaActual > 1);
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_LINEA_INVENTARIO);
  try
    oInsercion.ParamByName('EMP').AsString := AParametros.Empresa;
    oInsercion.ParamByName('ALM').AsString := AParametros.Almacen;
    oInsercion.ParamByName('SER').AsString := AParametros.Serie;
    oInsercion.ParamByName('NRO').AsString := AParametros.Numero;
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      if AParametros.SoloNegativos then
        MarcarInventarioSoloNegativos(AParametros);
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          InsertarSkusInventario(
            oInsercion,
            sArticulo,
            AParametros,
            iLineaActual,
            Result.NumeroLineas);
          oCodigos.Add(sArticulo);
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ProximaLineaDocumento(
  AIdDocumento: Int64): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 1;
  oConsulta := CrearConsulta(SQL_PROXIMA_LINEA_DOCUMENTO);
  try
    oConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('PROX').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.InsertarSkuDocumento(
  AInsercion: TUniQuery;
  const ACodigoArticulo: string;
  const ACodigoSku: string;
  const AParametros: TParametrosInsercionDocumentoTrabajo;
  var ALineaActual: Integer;
  var ANumeroLineas: Integer);
var
  dCantidadLinea: Double;
  dCantidadPendiente: Double;
  dStockFila: Double;
  dStockTotal: Double;
  oConsulta: TUniQuery;
  sSql: string;
begin
  sSql := ConstruirSqlSkuCargaDocumentoTrabajo;
  if Length(AParametros.CodigosAlmacen) > 0 then
  begin
    sSql := sSql + ' AND s.CODIGO_ALM_STK IN (' +
      StrArrToCsvSql(AParametros.CodigosAlmacen) + ')';
  end;
  sSql := sSql +
    ' ORDER BY s.CODIGO_ALM_STK, s.CODIGO_UNIDAD_STK, s.LOTE_STK';
  oConsulta := CrearConsulta(sSql);
  try
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    dStockTotal := 0;
    while not oConsulta.Eof do
    begin
      dStockTotal := dStockTotal +
        oConsulta.FieldByName('CANTIDAD_STK').AsFloat;
      oConsulta.Next;
    end;
    dCantidadPendiente := CalcularCantidadServirSku(
      dStockTotal,
      AParametros.ReservaStockOrigen,
      AParametros.MaximoServirPorSku);
    oConsulta.First;
    while (not oConsulta.Eof) and (dCantidadPendiente > 0) do
    begin
      dStockFila := Max(
        0.0,
        oConsulta.FieldByName('CANTIDAD_STK').AsFloat);
      dCantidadLinea := Min(dStockFila, dCantidadPendiente);
      if dCantidadLinea > 0 then
      begin
        AInsercion.ParamByName('ID_DTR').AsLargeInt :=
          AParametros.IdDocumento;
        AInsercion.ParamByName('LINEA').AsString :=
          Format('%.8d', [ALineaActual]);
        AInsercion.ParamByName('ART').AsString := ACodigoArticulo;
        AInsercion.ParamByName('SKU').AsString :=
          oConsulta.FieldByName('SKU').AsString;
        AInsercion.ParamByName('ALM').AsString :=
          oConsulta.FieldByName('ALM').AsString;
        AInsercion.ParamByName('LOTE').AsString :=
          oConsulta.FieldByName('LOTE_STK').AsString;
        if oConsulta.FieldByName('FECHA_CADUCIDAD_STK').IsNull then
        begin
          AInsercion.ParamByName('CADUCIDAD').Clear;
        end
        else
        begin
          AInsercion.ParamByName('CADUCIDAD').AsDate :=
            oConsulta.FieldByName('FECHA_CADUCIDAD_STK').AsDateTime;
        end;
        AInsercion.ParamByName('DESC_ART').AsString :=
          oConsulta.FieldByName('DESC_ART').AsString;
        AInsercion.ParamByName('DESC_SKU').AsString :=
          oConsulta.FieldByName('DESC_SKU').AsString;
        AInsercion.ParamByName('CANTIDAD_STOCK').AsFloat := dStockFila;
        AInsercion.ParamByName('CANTIDAD').AsFloat := dCantidadLinea;
        AInsercion.ParamByName('ORIGEN').AsString := 'FILTROS';
        AInsercion.ParamByName('USR').AsString := AParametros.Usuario;
        AInsercion.ParamByName('USR2').AsString := AParametros.Usuario;
        AInsercion.Execute;
        dCantidadPendiente := dCantidadPendiente - dCantidadLinea;
        Inc(ALineaActual);
        Inc(ANumeroLineas);
      end;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarDocumentoTrabajo(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionDocumentoTrabajo):
  TResultadoInsercionCargaMasiva;
var
  iAntes: Integer;
  iLineaActual: Integer;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
  sSku: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  iLineaActual := ProximaLineaDocumento(AParametros.IdDocumento);
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_LINEA_DOCUMENTO);
  try
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          sSku := oDatos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          iAntes := Result.NumeroLineas;
          InsertarSkuDocumento(
            oInsercion,
            sArticulo,
            sSku,
            AParametros,
            iLineaActual,
            Result.NumeroLineas);
          if Result.NumeroLineas > iAntes then
          begin
            oCodigos.Add(sSku);
          end;
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarSesionTarifa(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionSesionTarifa):
  TResultadoInsercionCargaMasiva;
var
  dOrigen: Double;
  oCodigos: TDictionary<string, Boolean>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  oCodigos := TDictionary<string, Boolean>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_SESION_TARIFA);
  try
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          dOrigen := oDatos.FieldByName('PRECIO_ORIGEN').AsFloat;
          oInsercion.ParamByName('TARC').AsInteger := AParametros.CodigoSesion;
          oInsercion.ParamByName('ART').AsString := sArticulo;
          oInsercion.ParamByName('SKU').AsString :=
            oDatos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          oInsercion.ParamByName('TAR_ORIG').AsString :=
            AParametros.TarifaOrigen;
          oInsercion.ParamByName('TAR_DEST').AsString :=
            AParametros.TarifaDestino;
          oInsercion.ParamByName('P_ORIG').AsFloat := dOrigen;
          oInsercion.ParamByName('P_COSTE').AsFloat :=
            oDatos.FieldByName('PRECIO_COSTE').AsFloat;
          oInsercion.ParamByName('P_SAL_ACT').AsFloat :=
            oDatos.FieldByName('PRECIO_SALIDA_ACT').AsFloat;
          oInsercion.ParamByName('P_FIN_ACT').AsFloat :=
            oDatos.FieldByName('PRECIO_FINAL_ACT').AsFloat;
          oInsercion.ParamByName('P_DTO_ACT').AsFloat :=
            oDatos.FieldByName('PRECIO_DTO_ACT').AsFloat;
          oInsercion.ParamByName('P_PDTO_ACT').AsFloat :=
            oDatos.FieldByName('PORC_DTO_ACT').AsFloat;
          oInsercion.ParamByName('P_NUEVO').AsFloat := dOrigen;
          oInsercion.ParamByName('P_FIN_NUEVO').AsFloat := dOrigen;
          oInsercion.ParamByName('USUARIO').AsString := AParametros.Usuario;
          oInsercion.Execute;
          oCodigos.AddOrSetValue(sArticulo, True);
          Inc(Result.NumeroLineas);
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.Keys.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function ConstruirSqlPreviewCargaMasivaDocumentoTrabajo(
  const AFiltros: TFiltrosCargaMasivaArticulos): string;
var
  oServicio: TServicioCargaMasivaArticulosUniDAC;
begin
  oServicio := TServicioCargaMasivaArticulosUniDAC.Create(nil);
  try
    Result := oServicio.ConstruirSqlPreviewDocumento(AFiltros);
  finally
    FreeAndNil(oServicio);
  end;
end;

function CrearServicioCargaMasivaArticulosUniDAC(
  AConexion: TUniConnection): TServiciosCargaMasivaArticulos;
var
  oServicio: TServicioCargaMasivaArticulosUniDAC;
begin
  oServicio := TServicioCargaMasivaArticulosUniDAC.Create(AConexion);
  Result.Consultas := oServicio;
  Result.Inserciones := oServicio;
end;

end.
