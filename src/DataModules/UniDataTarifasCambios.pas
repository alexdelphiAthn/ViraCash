{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTarifasCambios                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de sesiones de cambios de tarifa.                             }
{    Calcula lineas pendientes y aplica los precios a fza_articulos_tarifas.   }
{******************************************************************************}
unit UniDataTarifasCambios;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Math, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibTarifasCambiosExcel, inLibTarifasCambiosPeriodos;

type
  TNivelDescomposicionTarifa = (ndtColor, ndtTalla);

  TdmTarifasCambios = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FAjustandoPrecios: Boolean;
    FReferenciasCoste: TDictionary<string, Double>;
    function  CampoCabecera(const ACampo: string): TField;
    function  LeerFloatLinea(const ACampo: string): Double;
    function  PrecioBaseLinea(const ACampoOrigen: string): Double;
    function  CalcularImporte(AImporteBase: Double;
                              const ATipoAplicacion: string;
                              AValorAplicacion: Double): Double;
    function  RedondearImporte(AImporte: Double;
                               AValorRedondeo: Double;
                               AValorMenos: Double;
                               EsRedondearArriba: Boolean): Double;
    procedure ConfigurarConsultasAplicacion(
      AConsultaBusca, AConsultaMarca, AConsultaUnico: TUniQuery);
    function AplicarLineaTarifa(ALinea: TDataSet;
      AConsultaBusca, AConsultaExec, AConsultaMarca,
      AConsultaUnico: TUniQuery;
      out AEncoloPrestaShop: Boolean): Boolean;
    function SesionActual: Integer;
    function SesionAplicada: Boolean;
    procedure ConfigurarConsultaPeriodos;
    procedure unqryPeriodosBeforePost(DataSet: TDataSet);
    procedure RefrescarTrasCambioPeriodos(APeriodo: Integer);
    procedure MarcarSesionAplicada(AConsulta: TUniQuery);
    procedure ConfigurarQueries;
    procedure ConfigurarConsultaTarifasArticulo;
    procedure CambiarParametroLineas(const AParametro, AValor: string);
    procedure GrabarLineaPendiente;
    procedure BloquearSesionEditable(AConsulta: TUniQuery; ASesion: Integer);
    procedure AsignarParametrosLineaExcel(AConsulta: TUniQuery;
      const ALinea: TLineaSesionTarifaExcel);
    procedure CompletarDescuentoLineaExcel(AConsulta: TUniQuery;
      const ALinea: TLineaSesionTarifaExcel);
    procedure unqryLineasAfterOpen(DataSet: TDataSet);
    procedure unqryLineasBeforeDelete(DataSet: TDataSet);
    procedure CabeceraAntesDeBorrar(DataSet: TDataSet);
    procedure CampoPrecioNuevoChange(Sender: TField);
    function  RedondearConCabecera(AImporte: Double): Double;
    function  SalidaParaDescuento: Double;
    function SalidaReferenciaLinea: Double;
    procedure unqryLineasBeforePost(DataSet: TDataSet);
    procedure CalcularDescuento(ASalida, APorcentaje: Double;
      out AFinal, ADto, APorcentajeReal: Double);
    procedure GrabarDescuentos(const APorLinea: TDictionary<Integer, Double>);
    procedure AplicarPorcentajesExcel(const ALineas: TLineasSesionTarifaExcel);
  public
    unqryLineas  : TUniQuery;
    dsLineas     : TDataSource;
    unqryTarifas : TUniQuery;
    dsTarifas    : TDataSource;
    // Periodos (etapas de rebajas) de la sesión activa. FZ-ISSUE-944.
    unqryPeriodos: TUniQuery;
    dsPeriodos   : TDataSource;
    unqryTarifasArticulo: TUniQuery;
    dsTarifasArticulo: TDataSource;
    unqryAlmacenesStock: TUniQuery;
    function TienePreciosPorVariante(const AArticulo: string;
      AFecha: TDateTime): Boolean;
    procedure AbrirTarifasArticulo;
    procedure AbrirAlmacenesStock;
    procedure FiltrarStockAlmacenes(const ACodigos: string);
    procedure SeleccionarTarifaAnterior(const ACodigo: string);
    function CosteReferenciaTarifa(const AArticulo, AUnidad: string): Double;
    function  EsSesionPorPeriodos: Boolean;
    function  IdPeriodoActual: Integer;
    function  ParametrosCalculoActual: TParametrosCalculoTarifa;
    procedure FiltrarLineasPeriodo;
    function  AnadirPeriodo: Integer;
    procedure EliminarPeriodoActual;
    function  SincronizarPeriodos: Boolean;
    function  TotalLineasSesion: Integer;
    function RutaFamiliaLineaActual: string;
    procedure RellenarPreciosPartida;
    function ActualizarCostesLineas(const AIds: TArray<Integer>): Integer;
    function EliminarLineasSesion(const AIds: TArray<Integer>): Integer;
    procedure DescomponerLinea(AId: Integer; ANivel: TNivelDescomposicionTarifa);
    procedure ImportarLineasExcel(const ALineas: TLineasSesionTarifaExcel;
      out ANuevas, AActualizadas: Integer);
    procedure AbrirDetalles; override;
    procedure AplicarDescuentoLote(const AIdsLinea: TArray<Integer>;
      APorcentaje: Double);
    // FZ-ISSUE-944: lineas de periodo (rebajas) con la salida cambiada.
    function  LineasPeriodoConSalidaCambiada: Integer;
    // SKU de la sesion para etiquetar, entre comillas y separados por comas.
    function  SkusEtiquetasSesionCsv(AUnoPorArticulo: Boolean): string;
    // Se llama al grabar una linea de periodo con la salida cambiada; si
    // devuelve False se deshace el cambio.
    var OnConfirmarCambioSalidaRebajas: TFunc<Boolean>;
    function RecalcularSesionActual(const AIdsLinea: TArray<Integer>;
      out AMensaje: string): Integer;
    function  AplicarSesionActual(out AMensaje: string): Integer;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  System.Variants, inLibUser, inLibMsgArticulos, UniDataPrestaShopEncolado,
  inLibErroresBBDD,
  inLibPrestaShopColaSenal, inLibRedondeo, UniDataTarifasCambiosPeriodos,
  UniDataTarifasTramos, UniDataMargenRepositorio, inLibMargenPersistenciaIntf,
  UniDataSeleccionFamiliaRepositorio, UniDataTarifasPrecioSql;

{$R *.dfm}

resourcestring
  SErrorTarifasCambiosSinSesionActiva =
    'No hay ninguna sesion activa.';
  SErrorTarifasCambiosSesionSinLineas =
    'La sesion no tiene lineas.';
  SErrorTarifasCambiosSesionAplicada =
    'La sesion ya esta aplicada.';

const
  fstockactual = 'STOCK_ACTUAL';
  // El stock y los movimientos se agregan con el mismo alcance del precio.
  SQL_FILTRO_SKU_LINEA =
    ' AND (L.CODIGO_UNIDAD_SKU_TARCLIN IN ('''', L.CODIGO_ART_TARCLIN) ' +
    ' OR L.CODIGO_UNIDAD_SKU_TARCLIN = SKU.CODIGO_UNIDAD_SKU ' +
    ' OR L.CODIGO_UNIDAD_SKU_TARCLIN = ' +
    ' SUBSTRING_INDEX(SKU.CODIGO_UNIDAD_SKU, ''/'', 2) ' +
    ' OR (LOCATE(''/*/'', L.CODIGO_UNIDAD_SKU_TARCLIN) > 0 AND EXISTS (' +
    ' SELECT 1 FROM fza_atributos_sku ATS ' + SQL_ATRIBUTO_TALLA +
    ' WHERE ATS.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
    ' AND L.CODIGO_UNIDAD_SKU_TARCLIN = ' + SQL_UNIDAD_TALLA + '))) ';
  SQL_UNIDADES_COLOR =
    'SELECT DISTINCT SUBSTRING_INDEX(SKU.CODIGO_UNIDAD_SKU, ''/'', 2) ' +
    'AS UNIDAD FROM fza_articulos_skus SKU ' +
    'JOIN vi_variaciones_ejes EJE ON EJE.ID_VAR_VA = SKU.CODIGO_VAR_SKU ' +
    'AND EJE.EJE_VA = ''F'' ' +
    'WHERE SKU.CODIGO_ART_SKU = :ART AND SKU.ESACTIVO_SKU = ''S'' ' +
    'AND LEFT(SKU.CODIGO_UNIDAD_SKU, CHAR_LENGTH(:ART) + 1) ' +
    '= CONCAT(:ART, ''/'') AND SUBSTRING_INDEX(SUBSTRING_INDEX(' +
    'SKU.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) NOT IN ('''', ''*'')';
  SQL_UNIDADES_TALLA =
    'SELECT DISTINCT ' + SQL_UNIDAD_TALLA + ' AS UNIDAD ' +
    'FROM fza_articulos_skus SKU JOIN fza_atributos_sku ATS ' +
    'ON ATS.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
    SQL_ATRIBUTO_TALLA +
    'WHERE SKU.CODIGO_ART_SKU = :ART AND SKU.ESACTIVO_SKU = ''S'' ' +
    'AND TAL.AV NOT IN ('''', ''*'')';
  SQL_TOTAL_STOCK =
    'COALESCE((SELECT SUM(STK.CANTIDAD_STK) ' +
    '         FROM fza_articulos_stockactual STK ' +
    '         JOIN fza_articulos_skus SKU ' +
    '           ON SKU.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK ' +
    '        WHERE SKU.CODIGO_ART_SKU = L.CODIGO_ART_TARCLIN ' +
    '          AND (:ALMACENES_STOCK = '''' OR ' +
    '            FIND_IN_SET(STK.CODIGO_ALM_STK, :ALMACENES_STOCK) > 0) ' +
    SQL_FILTRO_SKU_LINEA + '), 0) AS STOCK_ACTUAL ';
  // Una cantidad negativa invierte el sentido efectivo del movimiento.
  SQL_TOTAL_MOVIMIENTOS =
    'COALESCE((SELECT SUM(CASE WHEN M.TIPO_MOV = %s THEN ' +
    ' GREATEST(M.CANTIDAD_MOV, 0) ELSE GREATEST(-M.CANTIDAD_MOV, 0) END) ' +
    ' FROM fza_articulos_skus SKU JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_UNIDAD_MOV = SKU.CODIGO_UNIDAD_SKU ' +
    ' WHERE SKU.CODIGO_ART_SKU = L.CODIGO_ART_TARCLIN ' +
    ' AND M.ESACTIVO_MOV = ''S'' AND M.TIPO_MOV IN (''E'', ''S'') ' +
    ' AND (:ALMACENES_STOCK = '''' OR ' +
    ' FIND_IN_SET(M.CODIGO_ALM_MOV, :ALMACENES_STOCK) > 0) ' +
    SQL_FILTRO_SKU_LINEA + '), 0) AS %s ';

  // Referencia de la tarifa destino, aunque haya vencido. Las filas
  // futuras no son un precio anterior. Sin coincidencia se conserva NULL.
  SQL_FINAL_ANTERIOR =
    '(SELECT T.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = L.CODIGO_ART_TARCLIN ' +
    // Una linea general consulta tambien sus variantes importadas. Para
    // un SKU concreto se permite su tarifa exacta, de color o general.
    'AND (COALESCE(L.CODIGO_UNIDAD_SKU_TARCLIN, '''') = '''' ' +
    'OR COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'OR T.CODIGO_UNIDAD_ARTTAR = L.CODIGO_UNIDAD_SKU_TARCLIN ' +
    'OR (LOCATE(''/*/'', T.CODIGO_UNIDAD_ARTTAR) = 0 ' +
    'AND LEFT(L.CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CHAR_LENGTH(T.CODIGO_UNIDAD_ARTTAR) + 1) ' +
    '= CONCAT(T.CODIGO_UNIDAD_ARTTAR, ''/''))) ' +
    'AND T.CODIGO_TAR_ARTTAR = COALESCE(NULLIF(:TARIFA_ANTERIOR, ''''), ' +
    'C.CODIGO_TAR_DESTINO_TARC) ' +
    'AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'AND (T.FECHA_DESDE_ARTTAR IS NULL OR ' +
    'T.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, ' +
    'COALESCE(T.INSTANTE_MODIF, T.INSTANTE_ALTA) DESC, ' +
    'T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1) AS PRECIO_FINAL_ANTERIOR_TARCLIN, ';

  // Precio vigente de una tarifa para el articulo/SKU de la linea L.
  SQL_PRECIO_TARIFA_LINEA =
    '(SELECT T.%s FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = L.CODIGO_ART_TARCLIN ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = ' +
    'L.CODIGO_UNIDAD_SKU_TARCLIN ' +
    'AND T.CODIGO_TAR_ARTTAR = :%s AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY ((T.FECHA_DESDE_ARTTAR IS NULL OR ' +
    'T.FECHA_DESDE_ARTTAR <= CURDATE()) AND ' +
    '(T.FECHA_HASTA_ARTTAR IS NULL OR T.FECHA_HASTA_ARTTAR >= CURDATE())) ' +
    'DESC, T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1)';
  // Tarifa de la linea distinta de la de la cabecera.
  SQL_CAMBIO_TARIFA_ORIGEN =
    'NOT (L.CODIGO_TAR_ORIGEN_TARCLIN <=> :TAR_ORIG)';
  SQL_CAMBIO_TARIFA_DESTINO =
    'NOT (L.CODIGO_TAR_DESTINO_TARCLIN <=> :TAR_DEST)';
  // Ultimo precio de compra: proveedor principal o, si no hay, cualquiera.
  SQL_COSTE_LINEA =
    'COALESCE((SELECT C.PRECIO_ULT_COMPRA_SKUC ' +
    'FROM fza_articulos_skus_costes C ' +
    'WHERE C.CODIGO_UNIDAD_SKU_SKUC = ' +
    'NULLIF(L.CODIGO_UNIDAD_SKU_TARCLIN, '''') LIMIT 1), ' +
    '(SELECT T.PRECIO_COSTE_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = L.CODIGO_ART_TARCLIN ' +
    // La fila general (SKU vacío) toma la tarifa general del artículo: con
    // NULLIF nunca casaba y caía al último precio de compra de cualquier
    // medida (FZ-ISSUE-786).
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = ' +
    'COALESCE(L.CODIGO_UNIDAD_SKU_TARCLIN, '''') ' +
    'AND T.CODIGO_TAR_ARTTAR = :TAR_ORIG AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'AND (T.FECHA_DESDE_ARTTAR IS NULL OR ' +
    'T.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'AND (T.FECHA_HASTA_ARTTAR IS NULL OR ' +
    'T.FECHA_HASTA_ARTTAR >= CURDATE()) ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1), ' +
    '(SELECT AP.PRECIO_ULT_COMPRA_AP FROM fza_articulos_proveedores AP ' +
    'WHERE AP.CODIGO_ART_AP = L.CODIGO_ART_TARCLIN ' +
    'ORDER BY AP.ESPROVEEDORPRINCIPAL_AP = ''S'' DESC, ' +
    'AP.FECHA_VALIDEZ_AP DESC, AP.CODIGO_PRV_AP LIMIT 1))';
  // Salida nueva de partida para un descuento: la calculada, si no la
  // actual de la tarifa destino y, si tampoco, la de origen.
  SQL_BASE_SALIDA_NUEVA =
    'COALESCE(NULLIF(PRECIO_NUEVO_TARCLIN, 0), ' +
    'NULLIF(PRECIO_SALIDA_ACTUAL_TARCLIN, 0), PRECIO_ORIGEN_TARCLIN)';
  // Descuento a partir del precio final ya grabado en la linea. En un
  // UPDATE de una tabla las asignaciones usan los valores ya asignados.
  SQL_DESCUENTO_FINAL =
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'PRECIO_NUEVO_TARCLIN = ' + SQL_BASE_SALIDA_NUEVA + ', ' +
    'PRECIO_DTO_NUEVO_TARCLIN = GREATEST(PRECIO_NUEVO_TARCLIN - ' +
    '  PRECIO_FINAL_NUEVO_TARCLIN, 0), ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN = CASE WHEN PRECIO_NUEVO_TARCLIN > 0 ' +
    '  THEN ROUND(PRECIO_DTO_NUEVO_TARCLIN / PRECIO_NUEVO_TARCLIN * 100, 2) ' +
    '  ELSE 0 END, ' +
    'ESTADO_TARCLIN = ''PENDIENTE'', MENSAJE_TARCLIN = NULL, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() WHERE %s';
  // El Excel se carga en el periodo que se ve (0 = sesion sin periodos).
  SQL_FILTRO_ARTICULO_LINEA =
    'CODIGO_TARC_TARCLIN = :TARC AND ID_TARCP_TARCLIN = :TARCP ' +
    'AND CODIGO_ART_TARCLIN = :ART AND CODIGO_UNIDAD_SKU_TARCLIN = :SKU';
  // Lineas con el mismo articulo/SKU que las elegidas, en todos los
  // periodos: los periodos comparten articulos (FZ-ISSUE-944).
  SQL_MISMO_ARTICULO_LINEA =
    'JOIN fza_tarifas_cambios_lineas S ' +
    'ON S.CODIGO_TARC_TARCLIN = L.CODIGO_TARC_TARCLIN ' +
    'AND S.CODIGO_ART_TARCLIN = L.CODIGO_ART_TARCLIN ' +
    'AND S.CODIGO_UNIDAD_SKU_TARCLIN = L.CODIGO_UNIDAD_SKU_TARCLIN ';
  SQL_PERIODOS =
    'SELECT P.ID_TARCP, P.CODIGO_TARC_TARCP, P.NUMERO_TARCP, ' +
    '       P.NOMBRE_TARCP, P.FECHA_DESDE_TARCP, P.FECHA_HASTA_TARCP, ' +
    '       P.CAMPO_ORIGEN_TARCP, P.CAMPO_DESTINO_TARCP, ' +
    '       P.TIPO_APLICACION_TARCP, P.VALOR_APLICACION_TARCP, ' +
    '       P.VALOR_REDONDEO_TARCP, P.VALOR_MENOS_AJUSTE_TARCP, ' +
    '       P.ESREDONDEAR_ARRIBA_TARCP, P.ESTADO_TARCP, P.USUARIO_MODIF ' +
    '  FROM fza_tarifas_cambios_periodos P ' +
    ' ORDER BY P.NUMERO_TARCP';
  // Editar un periodo obliga a recalcularlo: vuelve a borrador.
  SQL_ACTUALIZAR_PERIODO =
    'UPDATE fza_tarifas_cambios_periodos SET ' +
    '  NOMBRE_TARCP = :NOMBRE_TARCP, ' +
    '  FECHA_DESDE_TARCP = :FECHA_DESDE_TARCP, ' +
    '  FECHA_HASTA_TARCP = :FECHA_HASTA_TARCP, ' +
    '  CAMPO_ORIGEN_TARCP = :CAMPO_ORIGEN_TARCP, ' +
    '  CAMPO_DESTINO_TARCP = :CAMPO_DESTINO_TARCP, ' +
    '  TIPO_APLICACION_TARCP = :TIPO_APLICACION_TARCP, ' +
    '  VALOR_APLICACION_TARCP = :VALOR_APLICACION_TARCP, ' +
    '  VALOR_REDONDEO_TARCP = :VALOR_REDONDEO_TARCP, ' +
    '  VALOR_MENOS_AJUSTE_TARCP = :VALOR_MENOS_AJUSTE_TARCP, ' +
    '  ESREDONDEAR_ARRIBA_TARCP = :ESREDONDEAR_ARRIBA_TARCP, ' +
    '  ESTADO_TARCP = ''BORRADOR'', ' +
    '  USUARIO_MODIF = :USUARIO_MODIF, ' +
    '  INSTANTE_MODIF = NOW() ' +
    'WHERE ID_TARCP = :Old_ID_TARCP';
  // Todas las lineas de la sesion, con las fechas de su periodo: aplicar no
  // depende del periodo que se este viendo.
  SQL_LINEAS_APLICAR =
    'SELECT L.ID_TARCLIN, L.ID_TARCP_TARCLIN, L.ESAPLICAR_TARCLIN, ' +
    '       L.CODIGO_ART_TARCLIN, L.CODIGO_UNIDAD_SKU_TARCLIN, ' +
    '       L.CODIGO_TAR_DESTINO_TARCLIN, L.PRECIO_NUEVO_TARCLIN, ' +
    '       L.PRECIO_FINAL_NUEVO_TARCLIN, L.PRECIO_DTO_NUEVO_TARCLIN, ' +
    '       L.PORCENTAJE_DTO_NUEVO_TARCLIN, ' +
    '       L.PRECIO_SALIDA_ACTUAL_TARCLIN, L.PRECIO_ORIGEN_TARCLIN, ' +
    '       P.FECHA_DESDE_TARCP, P.FECHA_HASTA_TARCP ' +
    '  FROM fza_tarifas_cambios_lineas L ' +
    '  LEFT JOIN fza_tarifas_cambios_periodos P ' +
    '    ON P.ID_TARCP = L.ID_TARCP_TARCLIN ' +
    ' WHERE L.CODIGO_TARC_TARCLIN = :SESION ' +
    // Aplicar los niveles generales antes que sus precios específicos.
    ' ORDER BY CASE WHEN L.CODIGO_UNIDAD_SKU_TARCLIN = '''' THEN 0 ' +
    'WHEN LOCATE(''/*/'', L.CODIGO_UNIDAD_SKU_TARCLIN) > 0 THEN 2 ' +
    'WHEN L.CODIGO_UNIDAD_SKU_TARCLIN = SUBSTRING_INDEX(' +
    'L.CODIGO_UNIDAD_SKU_TARCLIN, ''/'', 2) THEN 1 ELSE 3 END, ' +
    'L.ID_TARCLIN';

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmTarifasCambios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryLineas := TUniQuery.Create(Self);
  dsLineas := TDataSource.Create(Self);
  dsLineas.DataSet := unqryLineas;
  unqryTarifas := TUniQuery.Create(Self);
  dsTarifas := TDataSource.Create(Self);
  dsTarifas.DataSet := unqryTarifas;
  unqryPeriodos := TUniQuery.Create(Self);
  dsPeriodos := TDataSource.Create(Self);
  dsPeriodos.DataSet := unqryPeriodos;
  unqryTarifasArticulo := TUniQuery.Create(Self);
  unqryAlmacenesStock := TUniQuery.Create(Self);
  dsTarifasArticulo := TDataSource.Create(Self);
  dsTarifasArticulo.DataSet := unqryTarifasArticulo;
  FReferenciasCoste := TDictionary<string, Double>.Create;
  ConfigurarQueries;
end;

procedure TdmTarifasCambios.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  FreeAndNil(FReferenciasCoste);
  if Assigned(unqryTarifasArticulo) then
  begin
    unqryTarifasArticulo.Close;
    unqryTarifasArticulo.MasterSource := nil;
  end;
  if Assigned(dsTarifasArticulo) then
    dsTarifasArticulo.DataSet := nil;
  if Assigned(dsLineas) then
    dsLineas.DataSet := nil;
  if Assigned(dsTarifas) then
    dsTarifas.DataSet := nil;
  if Assigned(dsPeriodos) then
    dsPeriodos.DataSet := nil;
  if Assigned(unqryPeriodos) then
  begin
    if unqryPeriodos.Active then
      unqryPeriodos.Close;
    unqryPeriodos.MasterSource := nil;
    unqryPeriodos.MasterFields := '';
    unqryPeriodos.DetailFields := '';
  end;
  if Assigned(unqryLineas) then
  begin
    if unqryLineas.Active then
      unqryLineas.Close;
    unqryLineas.MasterSource := nil;
    unqryLineas.MasterFields := '';
    unqryLineas.DetailFields := '';
  end;
  if Assigned(unqryTarifas) then
  begin
    if unqryTarifas.Active then
      unqryTarifas.Close;
  end;
  inherited;
end;

procedure TdmTarifasCambios.ConfigurarQueries;
begin
  unqryTablaG.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_tarifas_cambios ' +
    ' ORDER BY CODIGO_TARC DESC';
  unqryTablaG.KeyFields := 'CODIGO_TARC';
  unqryTablaG.AfterInsert := unqryTablaGAfterInsert;
  unqryTablaG.BeforePost := unqryTablaGBeforePost;
  unqryTablaG.BeforeDelete := CabeceraAntesDeBorrar;
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  unqryLineas.SQL.Text :=
    'SELECT L.*, A.DESCRIPCION_ART, A.CODIGO_FAM_ART, ' +
    '       A.TIPO_CANTIDAD_ART, ' +
    '       F.NOMBRE_FAM_FAM, P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, ' +
    ' COALESCE((SELECT COALESCE(PV.PV, T.VALOR_LIBRE_ARTPROP) ' +
    ' FROM fza_articulos_propiedades T ' +
    ' LEFT JOIN fza_propiedades_valores PV ' +
    ' ON PV.ID_PV_ARTPROP = T.ID_PV_ARTPROP ' +
    ' WHERE T.CODIGO_ART_ART = L.CODIGO_ART_TARCLIN ' +
    ' AND T.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    ' AND T.CODIGO_UNIDAD_ARTPROP IN (L.CODIGO_UNIDAD_SKU_TARCLIN, ' +
    ' SUBSTRING_INDEX(L.CODIGO_UNIDAD_SKU_TARCLIN, ''/'', 2), '''') ' +
    ' AND COALESCE(PV.PV, T.VALOR_LIBRE_ARTPROP, '''') <> '''' ' +
    ' ORDER BY FIELD(T.CODIGO_UNIDAD_ARTPROP, L.CODIGO_UNIDAD_SKU_TARCLIN, ' +
    ' SUBSTRING_INDEX(L.CODIGO_UNIDAD_SKU_TARCLIN, ''/'', 2), '''') ' +
    ' LIMIT 1), '''') AS TEMPORADA_ART, ' +
    SQL_FINAL_ANTERIOR +
    SQL_TOTAL_STOCK + ', ' +
    Format(SQL_TOTAL_MOVIMIENTOS, ['''E''', 'ENTRADAS']) + ', ' +
    Format(SQL_TOTAL_MOVIMIENTOS, ['''S''', 'SALIDAS']) +
    '  FROM fza_tarifas_cambios_lineas L ' +
    '  JOIN fza_tarifas_cambios C ' +
    '    ON C.CODIGO_TARC = L.CODIGO_TARC_TARCLIN ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TARCLIN ' +
    '  LEFT JOIN fza_articulos_familias F ' +
    '    ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_articulos_proveedores AP ' +
    '    ON AP.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '   AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '  LEFT JOIN fza_proveedores P ' +
    '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
    ' ORDER BY L.ID_TARCLIN';
  unqryLineas.KeyFields := 'ID_TARCLIN';
  unqryLineas.ParamByName('ALMACENES_STOCK').AsString := '';
  unqryLineas.ParamByName('TARIFA_ANTERIOR').AsString := '';
  unqryLineas.AfterOpen := unqryLineasAfterOpen;
  unqryLineas.BeforeDelete := unqryLineasBeforeDelete;
  unqryLineas.BeforePost := unqryLineasBeforePost;
  unqryLineas.SQLDelete.Text :=
    'DELETE FROM fza_tarifas_cambios_lineas ' +
    'WHERE ID_TARCLIN = :Old_ID_TARCLIN ' +
    'AND CODIGO_TARC_TARCLIN = :Old_CODIGO_TARC_TARCLIN';
  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    '  CODIGO_ART_TARCLIN = :CODIGO_ART_TARCLIN, ' +
    '  CODIGO_UNIDAD_SKU_TARCLIN = :CODIGO_UNIDAD_SKU_TARCLIN, ' +
    '  CODIGO_TAR_ORIGEN_TARCLIN = :CODIGO_TAR_ORIGEN_TARCLIN, ' +
    '  CODIGO_TAR_DESTINO_TARCLIN = :CODIGO_TAR_DESTINO_TARCLIN, ' +
    '  ESAPLICAR_TARCLIN = :ESAPLICAR_TARCLIN, ' +
    '  PRECIO_ORIGEN_TARCLIN = :PRECIO_ORIGEN_TARCLIN, ' +
    '  PRECIO_COSTE_TARCLIN = :PRECIO_COSTE_TARCLIN, ' +
    '  PRECIO_SALIDA_ACTUAL_TARCLIN = :PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    '  PRECIO_FINAL_ACTUAL_TARCLIN = :PRECIO_FINAL_ACTUAL_TARCLIN, ' +
    '  PRECIO_DTO_ACTUAL_TARCLIN = :PRECIO_DTO_ACTUAL_TARCLIN, ' +
    '  PORCENTAJE_DTO_ACTUAL_TARCLIN = :PORCENTAJE_DTO_ACTUAL_TARCLIN, ' +
    '  PRECIO_NUEVO_TARCLIN = :PRECIO_NUEVO_TARCLIN, ' +
    '  PRECIO_FINAL_NUEVO_TARCLIN = :PRECIO_FINAL_NUEVO_TARCLIN, ' +
    '  PRECIO_DTO_NUEVO_TARCLIN = :PRECIO_DTO_NUEVO_TARCLIN, ' +
    '  PORCENTAJE_DTO_NUEVO_TARCLIN = :PORCENTAJE_DTO_NUEVO_TARCLIN, ' +
    '  ESTADO_TARCLIN = :ESTADO_TARCLIN, ' +
    '  MENSAJE_TARCLIN = :MENSAJE_TARCLIN, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF, ' +
    '  INSTANTE_MODIF = NOW() ' +
    'WHERE ID_TARCLIN = :Old_ID_TARCLIN';
  unqryTarifas.SQL.Text :=
    'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR ' +
    '  FROM fza_tarifas ' +
    ' WHERE ESACTIVO_ARTTAR = ''S'' ' +
    ' ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
  ConfigurarConsultaPeriodos;
  ConfigurarConsultaTarifasArticulo;
end;

procedure TdmTarifasCambios.ConfigurarConsultaTarifasArticulo;
begin
  unqryTarifasArticulo.SQL.Text :=
    'SELECT T.CODIGO_UNICO_ARTTAR, T.CODIGO_ART_ARTTAR, ' +
    'T.CODIGO_UNIDAD_ARTTAR, T.CODIGO_TAR_ARTTAR, N.NOMBRE_TAR_TAR, ' +
    'T.ESACTIVO_ARTTAR, N.ESIMP_INCL_TAR, T.PRECIO_COSTE_ARTTAR, ' +
    'T.PRECIO_SALIDA_ARTTAR, T.PRECIO_DTO_ARTTAR, ' +
    'T.PORCENTAJE_DTO_ARTTAR, T.PRECIO_FINAL_ARTTAR, ' +
    'T.FECHA_DESDE_ARTTAR, T.FECHA_HASTA_ARTTAR ' +
    'FROM fza_articulos_tarifas T ' +
    'LEFT JOIN fza_tarifas N ' +
    'ON N.CODIGO_TAR_ARTTAR = T.CODIGO_TAR_ARTTAR ' +
    'ORDER BY T.CODIGO_TAR_ARTTAR, T.CODIGO_UNIDAD_ARTTAR, ' +
    'T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC';
  unqryTarifasArticulo.ReadOnly := True;
  unqryTarifasArticulo.MasterFields := 'CODIGO_ART_TARCLIN';
  unqryTarifasArticulo.DetailFields := 'CODIGO_ART_ARTTAR';
  unqryTarifasArticulo.MasterSource := dsLineas;
end;

procedure TdmTarifasCambios.AbrirTarifasArticulo;
begin
  FReferenciasCoste.Clear;
  unqryTarifasArticulo.Connection := unqryTablaG.Connection;
  if unqryTarifasArticulo.Active then
    unqryTarifasArticulo.Refresh
  else
    unqryTarifasArticulo.Open;
end;

function TdmTarifasCambios.CosteReferenciaTarifa(
  const AArticulo, AUnidad: string): Double;
var
  Clave: string;
  Repositorio: IRepositorioMargen;
begin
  Clave := AArticulo + #31 + AUnidad;
  if not FReferenciasCoste.TryGetValue(Clave, Result) then
  begin
    Repositorio := CrearRepositorioMargenUniDAC(unqryTablaG.Connection);
    Result := Repositorio.UltimaCompra(AArticulo, AUnidad).Coste;
    FReferenciasCoste.Add(Clave, Result);
  end;
end;

procedure TdmTarifasCambios.AbrirAlmacenesStock;
begin
  unqryAlmacenesStock.Close;
  unqryAlmacenesStock.Connection := unqryTablaG.Connection;
  unqryAlmacenesStock.SQL.Text :=
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM FROM fza_almacenes ' +
    'ORDER BY NOMBRE_ALM_ALM, CODIGO_ALM_ALM';
  unqryAlmacenesStock.ReadOnly := True;
  unqryAlmacenesStock.Open;
end;

procedure TdmTarifasCambios.FiltrarStockAlmacenes(const ACodigos: string);
begin
  CambiarParametroLineas('ALMACENES_STOCK', ACodigos);
end;

procedure TdmTarifasCambios.SeleccionarTarifaAnterior(const ACodigo: string);
begin
  CambiarParametroLineas('TARIFA_ANTERIOR', ACodigo);
end;

procedure TdmTarifasCambios.CambiarParametroLineas(
  const AParametro, AValor: string);
var
  IdLinea: Integer;
  EsAbierta: Boolean;
begin
  EsAbierta := unqryLineas.Active;
  if EsAbierta then
    GrabarLineaPendiente;
  IdLinea := 0;
  if EsAbierta and not unqryLineas.IsEmpty then
    IdLinea := unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
  unqryLineas.DisableControls;
  try
    unqryLineas.Close;
    unqryLineas.ParamByName(AParametro).AsString := AValor;
    if EsAbierta then
      unqryLineas.Open;
    if IdLinea <> 0 then
      unqryLineas.Locate('ID_TARCLIN', IdLinea, []);
  finally
    unqryLineas.EnableControls;
  end;
end;

procedure TdmTarifasCambios.ConfigurarConsultaPeriodos;
begin
  unqryPeriodos.SQL.Text := SQL_PERIODOS;
  unqryPeriodos.KeyFields := 'ID_TARCP';
  unqryPeriodos.SQLUpdate.Text := SQL_ACTUALIZAR_PERIODO;
  unqryPeriodos.BeforePost := unqryPeriodosBeforePost;
end;

procedure TdmTarifasCambios.AbrirDetalles;
begin
  inherited;
  if not unqryTarifas.Active then
    unqryTarifas.Open;
  if not unqryPeriodos.Active then
    unqryPeriodos.Open;
  if not unqryLineas.Active then
    unqryLineas.Open;
  FiltrarLineasPeriodo;
end;

// ===========================================================================
//   Periodos (etapas de rebajas). FZ-ISSUE-944.
// ===========================================================================

function TdmTarifasCambios.SesionActual: Integer;
begin
  Result := 0;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    Result := unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
end;

function TdmTarifasCambios.SesionAplicada: Boolean;
begin
  Result := (SesionActual <> 0) and SameText(
    unqryTablaG.FieldByName('ESTADO_TARC').AsString, 'APLICADA');
end;

function TdmTarifasCambios.EsSesionPorPeriodos: Boolean;
var
  Marca: TField;
begin
  Marca := nil;
  if SesionActual <> 0 then
    Marca := unqryTablaG.FindField('ESPOR_PERIODOS_TARC');
  Result := Assigned(Marca) and SameText(Marca.AsString, 'S');
end;

function TdmTarifasCambios.IdPeriodoActual: Integer;
begin
  Result := 0;
  if EsSesionPorPeriodos and unqryPeriodos.Active and
     (not unqryPeriodos.IsEmpty) then
    Result := unqryPeriodos.FieldByName('ID_TARCP').AsInteger;
end;

// Con periodos manda el periodo que se ve; sin ellos, la cabecera.
function TdmTarifasCambios.ParametrosCalculoActual: TParametrosCalculoTarifa;
var
  Origen: TDataSet;
  sSufijo: string;
begin
  Origen := unqryTablaG;
  sSufijo := '_TARC';
  if IdPeriodoActual <> 0 then
  begin
    Origen := unqryPeriodos;
    sSufijo := '_TARCP';
  end;
  Result.CampoOrigen := Origen.FieldByName('CAMPO_ORIGEN' + sSufijo).AsString;
  Result.CampoDestino :=
    Origen.FieldByName('CAMPO_DESTINO' + sSufijo).AsString;
  Result.TipoAplicacion :=
    Origen.FieldByName('TIPO_APLICACION' + sSufijo).AsString;
  Result.ValorAplicacion :=
    Origen.FieldByName('VALOR_APLICACION' + sSufijo).AsFloat;
  Result.ValorRedondeo :=
    Origen.FieldByName('VALOR_REDONDEO' + sSufijo).AsFloat;
  Result.ValorMenos :=
    Origen.FieldByName('VALOR_MENOS_AJUSTE' + sSufijo).AsFloat;
  Result.EsRedondearArriba := SameText(
    Origen.FieldByName('ESREDONDEAR_ARRIBA' + sSufijo).AsString, 'S');
end;

// Las lineas solo muestran el periodo elegido en la rejilla de periodos.
procedure TdmTarifasCambios.FiltrarLineasPeriodo;
var
  iPeriodo: Integer;
begin
  iPeriodo := IdPeriodoActual;
  unqryLineas.Filter := Format('ID_TARCP_TARCLIN = %d', [iPeriodo]);
  unqryLineas.Filtered := iPeriodo <> 0;
end;

procedure RestaurarFechasPeriodo(DataSet: TDataSet);
var
  Campo: string;
begin
  for Campo in ['FECHA_DESDE_TARCP', 'FECHA_HASTA_TARCP'] do
    if not VarIsNull(DataSet.FieldByName(Campo).OldValue) then
      DataSet.FieldByName(Campo).Value :=
        DataSet.FieldByName(Campo).OldValue;
end;

procedure TdmTarifasCambios.unqryPeriodosBeforePost(DataSet: TDataSet);
var
  sError: string;
  Vigencia: TVigenciaPeriodoTarifa;
begin
  if SesionAplicada then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSesionAplicada);
  Vigencia.Id := DataSet.FieldByName('ID_TARCP').AsInteger;
  Vigencia.Numero := DataSet.FieldByName('NUMERO_TARCP').AsInteger;
  Vigencia.Desde := DataSet.FieldByName('FECHA_DESDE_TARCP').AsDateTime;
  Vigencia.Hasta := DataSet.FieldByName('FECHA_HASTA_TARCP').AsDateTime;
  sError := ErrorVigenciaPeriodoTarifa(Vigencia,
    CargarVigenciasPeriodosTarifa(
      unqryTablaG.Connection as TUniConnection, SesionActual));
  // Revalidación 944: un periodo no válido vuelve a sus fechas grabadas,
  // para que la rejilla no quede atascada en edición. EValidacionBBDD se
  // muestra como aviso, sin el diálogo de error inesperado.
  if sError <> '' then
  begin
    RestaurarFechasPeriodo(DataSet);
    raise EValidacionBBDD.Create(sError);
  end;
  if Trim(DataSet.FieldByName('NOMBRE_TARCP').AsString) = '' then
    DataSet.FieldByName('NOMBRE_TARCP').AsString :=
      Format(SNombrePeriodoTarifaDefecto, [Vigencia.Numero]);
  DataSet.FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
end;

procedure TdmTarifasCambios.RefrescarTrasCambioPeriodos(APeriodo: Integer);
begin
  unqryTablaG.Refresh;
  unqryPeriodos.Refresh;
  if APeriodo <> 0 then
    unqryPeriodos.Locate('ID_TARCP', APeriodo, []);
  FiltrarLineasPeriodo;
  unqryLineas.Refresh;
end;

// El primer periodo se queda con las lineas de la sesion; los siguientes
// reciben una copia de sus articulos sin precio nuevo.
function TdmTarifasCambios.AnadirPeriodo: Integer;
var
  dDesdeSesion: TDateTime;
  Vigencia: TVigenciaPeriodoTarifa;
  oConexion: TUniConnection;
begin
  if SesionActual = 0 then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSinSesionActiva);
  if SesionAplicada then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSesionAplicada);
  GrabarLineaPendiente;
  if unqryPeriodos.Active and (unqryPeriodos.State in dsEditModes) then
    unqryPeriodos.Post;
  oConexion := unqryTablaG.Connection as TUniConnection;
  dDesdeSesion := 0;
  if not unqryTablaG.FieldByName('FECHA_DESDE_TARC').IsNull then
    dDesdeSesion := unqryTablaG.FieldByName('FECHA_DESDE_TARC').AsDateTime;
  Vigencia := VigenciaPropuestaPeriodoTarifa(
    CargarVigenciasPeriodosTarifa(oConexion, SesionActual),
    dDesdeSesion, Date);
  Result := InsertarPeriodoTarifa(oConexion, SesionActual, Vigencia,
    Format(SNombrePeriodoTarifaDefecto, [Vigencia.Numero]),
    IdentidadSesion.Usuario);
  RefrescarTrasCambioPeriodos(Result);
end;

procedure TdmTarifasCambios.EliminarPeriodoActual;
var
  iPeriodo: Integer;
begin
  iPeriodo := IdPeriodoActual;
  if iPeriodo = 0 then
    raise EValidacionBBDD.Create(SErrorPeriodoTarifaNoSeleccionado);
  if SesionAplicada then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSesionAplicada);
  GrabarLineaPendiente;
  if unqryPeriodos.State in dsEditModes then
    unqryPeriodos.Cancel;
  EliminarPeriodoTarifa(unqryTablaG.Connection as TUniConnection,
    SesionActual, iPeriodo, IdentidadSesion.Usuario);
  RefrescarTrasCambioPeriodos(0);
end;

// Reparte en los periodos las lineas llegadas sin periodo (carga de
// articulos, documentos de trabajo). True si cambio alguna linea.
function TdmTarifasCambios.SincronizarPeriodos: Boolean;
begin
  Result := False;
  if EsSesionPorPeriodos and not SesionAplicada then
  begin
    GrabarLineaPendiente;
    Result := SincronizarLineasPeriodosTarifa(
      unqryTablaG.Connection as TUniConnection, SesionActual,
      IdentidadSesion.Usuario);
    if Result and unqryLineas.Active then
      unqryLineas.Refresh;
  end;
end;

function TdmTarifasCambios.TotalLineasSesion: Integer;
var
  qry: TUniQuery;
begin
  Result := 0;
  if SesionActual <> 0 then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD FROM fza_tarifas_cambios_lineas ' +
        'WHERE CODIGO_TARC_TARCLIN = :CODIGO';
      qry.ParamByName('CODIGO').AsInteger := SesionActual;
      qry.Open;
      Result := qry.FieldByName('CANTIDAD').AsInteger;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

function TdmTarifasCambios.RutaFamiliaLineaActual: string;
begin
  Result := '';
  if unqryLineas.Active and not unqryLineas.IsEmpty then
    Result := LeerRutaFamiliaUniDAC(unqryLineas.Connection,
      unqryLineas.FieldByName('CODIGO_FAM_ART').AsString);
end;

// Los campos son dinamicos: se recrean en cada apertura del detalle.
procedure TdmTarifasCambios.unqryLineasAfterOpen(DataSet: TDataSet);
begin
  DataSet.FieldByName('CODIGO_PRV_PRV').ReadOnly := True;
  DataSet.FieldByName('CODIGO_PRV_PRV').ProviderFlags := [];
  DataSet.FieldByName('TEMPORADA_ART').ReadOnly := True;
  DataSet.FieldByName('TEMPORADA_ART').ProviderFlags := [];
  DataSet.FieldByName('ENTRADAS').ReadOnly := True;
  DataSet.FieldByName('ENTRADAS').ProviderFlags := [];
  DataSet.FieldByName('SALIDAS').ReadOnly := True;
  DataSet.FieldByName('SALIDAS').ProviderFlags := [];
  DataSet.FieldByName(fstockactual).ReadOnly := True;
  DataSet.FieldByName(fstockactual).ProviderFlags := [];
  DataSet.FieldByName('PRECIO_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
  DataSet.FieldByName('PRECIO_FINAL_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
  DataSet.FieldByName('PRECIO_DTO_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
  DataSet.FieldByName('PORCENTAJE_DTO_NUEVO_TARCLIN').OnChange :=
    CampoPrecioNuevoChange;
end;

// Edicion a mano de una linea, con el criterio comun:
// - % escrito o salida cambiada: el final sale del % con el redondeo de la
//   cabecera (como la formula y el descuento en lote);
// - final o importe de descuento escritos: se respetan tal cual.
// El % que queda es siempre el real (descuento / salida).
procedure TdmTarifasCambios.CampoPrecioNuevoChange(Sender: TField);
var
  dDto: Double;
  dFinal: Double;
  dPorc: Double;
  dSalida: Double;
  Lineas: TDataSet;
begin
  if not FAjustandoPrecios then
  begin
    FAjustandoPrecios := True;
    try
      Lineas := Sender.DataSet;
      dSalida := SalidaParaDescuento;
      if (dSalida > 0) and
         (LeerFloatLinea('PRECIO_NUEVO_TARCLIN') <= 0) then
        Lineas.FieldByName('PRECIO_NUEVO_TARCLIN').AsFloat := dSalida;
      dFinal := LeerFloatLinea('PRECIO_FINAL_NUEVO_TARCLIN');
      dDto := LeerFloatLinea('PRECIO_DTO_NUEVO_TARCLIN');
      if Sender.FieldName = 'PRECIO_DTO_NUEVO_TARCLIN' then
        dFinal := Max(dSalida - dDto, 0)
      else if Sender.FieldName <> 'PRECIO_FINAL_NUEVO_TARCLIN' then
        CalcularDescuento(dSalida,
          LeerFloatLinea('PORCENTAJE_DTO_NUEVO_TARCLIN'),
          dFinal, dDto, dPorc);
      dDto := Max(dSalida - dFinal, 0);
      dPorc := 0;
      if dSalida > 0 then
        dPorc := Round(dDto / dSalida * 100 * 100) / 100;
      if Sender.FieldName <> 'PRECIO_FINAL_NUEVO_TARCLIN' then
        Lineas.FieldByName('PRECIO_FINAL_NUEVO_TARCLIN').AsFloat := dFinal;
      if Sender.FieldName <> 'PRECIO_DTO_NUEVO_TARCLIN' then
        Lineas.FieldByName('PRECIO_DTO_NUEVO_TARCLIN').AsFloat := dDto;
      Lineas.FieldByName('PORCENTAJE_DTO_NUEVO_TARCLIN').AsFloat := dPorc;
      Lineas.FieldByName('ESTADO_TARCLIN').AsString := 'PENDIENTE';
    finally
      FAjustandoPrecios := False;
    end;
  end;
end;

procedure TdmTarifasCambios.AplicarDescuentoLote(
  const AIdsLinea: TArray<Integer>; APorcentaje: Double);
var
  iLinea: Integer;
  PorLinea: TDictionary<Integer, Double>;
begin
  GrabarLineaPendiente;
  PorLinea := TDictionary<Integer, Double>.Create;
  try
    for iLinea := 0 to High(AIdsLinea) do
      PorLinea.AddOrSetValue(AIdsLinea[iLinea], APorcentaje);
    GrabarDescuentos(PorLinea);
  finally
    FreeAndNil(PorLinea);
  end;
end;

// Lineas a aplicar que aun no tienen salida o final nuevo: aplicarlas
// dejaria el articulo a precio 0 en la tarifa destino.
// Salida de referencia de una linea: la actual de la tarifa destino o, si no
// tiene precio, la de origen (la misma que usa SalidaReferenciaLinea).
const
  SQL_SALIDA_REFERENCIA =
    'COALESCE(NULLIF(PRECIO_SALIDA_ACTUAL_TARCLIN, 0), PRECIO_ORIGEN_TARCLIN)';

// FZ-ISSUE-944: SKU de las lineas de la sesion (todas las variantes si la
// linea es del articulo), sin repetir entre periodos. Con AUnoPorArticulo,
// uno por articulo para no reetiquetar todo el stock.
function TdmTarifasCambios.SkusEtiquetasSesionCsv(
  AUnoPorArticulo: Boolean): string;
const
  SQL_SKU_LINEA =
    'COALESCE(NULLIF(L.CODIGO_UNIDAD_SKU_TARCLIN, ''''), S.CODIGO_UNIDAD_SKU)';
var
  qry: TUniQuery;
begin
  Result := '';
  GrabarLineaPendiente;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      if AUnoPorArticulo then
        qry.SQL.Text := 'SELECT MIN(' + SQL_SKU_LINEA + ') AS SKU '
      else
        qry.SQL.Text := 'SELECT DISTINCT ' + SQL_SKU_LINEA + ' AS SKU ';
      qry.SQL.Add(
        'FROM fza_tarifas_cambios_lineas L ' +
        'LEFT JOIN fza_articulos_skus S ' +
        '  ON S.CODIGO_ART_SKU = L.CODIGO_ART_TARCLIN ' +
        ' AND COALESCE(L.CODIGO_UNIDAD_SKU_TARCLIN, '''') = '''' ' +
        ' AND S.ESACTIVO_SKU = ''S'' ' +
        'WHERE L.CODIGO_TARC_TARCLIN = :CODIGO ' +
        '  AND L.ESAPLICAR_TARCLIN = ''S''');
      if AUnoPorArticulo then
        qry.SQL.Add('GROUP BY L.CODIGO_ART_TARCLIN');
      qry.ParamByName('CODIGO').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      qry.Open;
      while not qry.Eof do
      begin
        if not qry.FieldByName('SKU').IsNull then
        begin
          if Result <> '' then
            Result := Result + ',';
          Result := Result + QuotedStr(qry.FieldByName('SKU').AsString);
        end;
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

function TdmTarifasCambios.LineasPeriodoConSalidaCambiada: Integer;
var
  qry: TUniQuery;
begin
  Result := 0;
  GrabarLineaPendiente;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT COUNT(*) AS CANTIDAD FROM fza_tarifas_cambios_lineas ' +
        'WHERE CODIGO_TARC_TARCLIN = :CODIGO AND ESAPLICAR_TARCLIN = ''S'' ' +
        'AND ID_TARCP_TARCLIN <> 0 AND ' + SQL_SALIDA_REFERENCIA + ' > 0 ' +
        'AND ABS(COALESCE(PRECIO_NUEVO_TARCLIN, 0) - ' +
        SQL_SALIDA_REFERENCIA + ') >= 0.005';
      qry.ParamByName('CODIGO').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      qry.Open;
      Result := qry.FieldByName('CANTIDAD').AsInteger;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

// FZ-ISSUE-944: en rebajas cambiar la salida va contra la ley de consumo.
// Se permite, pero se pide confirmacion; si no, se deshace.
procedure TdmTarifasCambios.unqryLineasBeforePost(DataSet: TDataSet);
var
  Salida: TField;
  Campo: string;
begin
  Salida := DataSet.FieldByName('PRECIO_NUEVO_TARCLIN');
  if (DataSet.State = dsEdit) and
     (DataSet.FieldByName('ID_TARCP_TARCLIN').AsInteger <> 0) and
     Assigned(OnConfirmarCambioSalidaRebajas) and
     (not VarIsNull(Salida.OldValue)) and
     (Abs(Salida.AsFloat - Double(Salida.OldValue)) >= 0.005) then
    if not OnConfirmarCambioSalidaRebajas() then
    begin
      // Se deshace entero: al cambiar la salida la linea recalcula el
      // descuento y el final, que tambien vuelven a como estaban.
      for Campo in ['PRECIO_NUEVO_TARCLIN', 'PRECIO_DTO_NUEVO_TARCLIN',
        'PORCENTAJE_DTO_NUEVO_TARCLIN', 'PRECIO_FINAL_NUEVO_TARCLIN'] do
        DataSet.FieldByName(Campo).Value :=
          DataSet.FieldByName(Campo).OldValue;
    end;
end;

// Un precio de SKU, talla o color impide probar sin concretar la variante.
function TdmTarifasCambios.TienePreciosPorVariante(
  const AArticulo: string; AFecha: TDateTime): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := unqryTablaG.Connection;
    Consulta.SQL.Text :=
      'SELECT 1 FROM fza_articulos_tarifas P ' +
      'JOIN fza_tarifas T ' +
      'ON T.CODIGO_TAR_ARTTAR = P.CODIGO_TAR_ARTTAR ' +
      'AND T.ESACTIVO_ARTTAR = ''S'' ' +
      'WHERE P.CODIGO_ART_ARTTAR = :ARTICULO ' +
      'AND COALESCE(P.CODIGO_UNIDAD_ARTTAR, '''') <> '''' ' +
      'AND P.ESACTIVO_ARTTAR = ''S'' ' +
      'AND (P.FECHA_DESDE_ARTTAR IS NULL ' +
      'OR P.FECHA_DESDE_ARTTAR <= :FECHA) ' +
      'AND (P.FECHA_HASTA_ARTTAR IS NULL ' +
      'OR P.FECHA_HASTA_ARTTAR >= :FECHA) LIMIT 1';
    Consulta.ParamByName('ARTICULO').AsString := AArticulo;
    Consulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

// FZ-ISSUE-786: el nombre queda vacío para que lo tecleado no se añada al
// propuesto; si no se escribe ninguno, BeforePost pone el de por defecto.
procedure TdmTarifasCambios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('FECHA_TARC').AsDateTime := Date;
  DataSet.FieldByName('ESTADO_TARC').AsString := 'BORRADOR';
  DataSet.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString := 'PVP';
  DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString := 'PVP';
  DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString := 'PRECIO_ORIGEN';
  DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString := 'AMBOS';
  DataSet.FieldByName('TIPO_APLICACION_TARC').AsString := 'COPIAR';
  DataSet.FieldByName('VALOR_APLICACION_TARC').AsFloat := 0;
  DataSet.FieldByName('VALOR_REDONDEO_TARC').AsFloat := 0.01;
  DataSet.FieldByName('VALOR_MENOS_AJUSTE_TARC').AsFloat := 0;
  DataSet.FieldByName('ESREDONDEAR_ARRIBA_TARC').AsString := 'S';
  DataSet.FieldByName('FECHA_DESDE_TARC').AsDateTime := Date;
  // FZ-ISSUE-944: el campo es obligatorio en el dataset; sin él, «Añadir
  // periodo» sobre una sesión aún sin grabar fallaba al grabar la cabecera.
  // Nace sin periodos; el primer periodo lo pasa a 'S'.
  if Assigned(DataSet.FindField('ESPOR_PERIODOS_TARC')) then
    DataSet.FieldByName('ESPOR_PERIODOS_TARC').AsString := 'N';
end;

procedure TdmTarifasCambios.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(DataSet.FieldByName('NOMBRE_TARC').AsString) = '' then
    DataSet.FieldByName('NOMBRE_TARC').AsString :=
      Format(SNombreSesionCambioTarifaDefecto,
        [FormatDateTime('dd/mm/yyyy hh:nn', Now)]);
  if Trim(DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString) = '' then
    raise Exception.Create(SErrorTarifaDestinoObligatoria);
  if Trim(DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString) = '' then
    DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString := 'PRECIO_ORIGEN';
  if Trim(DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString) = '' then
    DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString := 'AMBOS';
  if Trim(DataSet.FieldByName('TIPO_APLICACION_TARC').AsString) = '' then
    DataSet.FieldByName('TIPO_APLICACION_TARC').AsString := 'COPIAR';
end;

function TdmTarifasCambios.CampoCabecera(const ACampo: string): TField;
begin
  Result := nil;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    Result := unqryTablaG.FieldByName(ACampo);
end;

function TdmTarifasCambios.LeerFloatLinea(const ACampo: string): Double;
begin
  Result := 0;
  if not unqryLineas.FieldByName(ACampo).IsNull then
    Result := unqryLineas.FieldByName(ACampo).AsFloat;
end;

function TdmTarifasCambios.PrecioBaseLinea(
  const ACampoOrigen: string): Double;
begin
  if SameText(ACampoOrigen, 'PRECIO_COSTE') then
    Result := LeerFloatLinea('PRECIO_COSTE_TARCLIN')
  else if SameText(ACampoOrigen, 'PRECIO_DESTINO_ACTUAL') then
    Result := LeerFloatLinea('PRECIO_FINAL_ACTUAL_TARCLIN')
  else if SameText(ACampoOrigen, 'PRECIO_FINAL_ANTERIOR') then
    Result := LeerFloatLinea('PRECIO_FINAL_ANTERIOR_TARCLIN')
  else
    Result := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
end;

function TdmTarifasCambios.CalcularImporte(AImporteBase: Double;
  const ATipoAplicacion: string; AValorAplicacion: Double): Double;
begin
  if SameText(ATipoAplicacion, 'INCREMENTO_LINEAL') then
    Result := AImporteBase + AValorAplicacion
  else if SameText(ATipoAplicacion, 'INCREMENTO_PORCENTUAL') then
    Result := AImporteBase + (AImporteBase * AValorAplicacion / 100)
  else if SameText(ATipoAplicacion, 'PRECIO_FIJO') then
    Result := AValorAplicacion
  else
    Result := AImporteBase;
end;

function TdmTarifasCambios.RedondearImporte(AImporte: Double;
  AValorRedondeo: Double; AValorMenos: Double;
  EsRedondearArriba: Boolean): Double;
begin
  Result := AImporte;
  if AValorRedondeo > 0 then
  begin
    if EsRedondearArriba then
      Result := Ceil(Result / AValorRedondeo) * AValorRedondeo
    else
      Result := RedondearAMultiplo(Result, AValorRedondeo);
  end;
  Result := Result - AValorMenos;
  if Result < 0 then
    Result := 0;
  Result := RedondearACentimos(Result);
end;

// Criterio unico: todo precio que sale de un porcentaje (formula, descuento
// en lote, % del Excel o % escrito en la rejilla) se redondea igual.
// Con periodos, el redondeo es el del periodo que se ve (FZ-ISSUE-944).
function TdmTarifasCambios.RedondearConCabecera(AImporte: Double): Double;
var
  Parametros: TParametrosCalculoTarifa;
begin
  Parametros := ParametrosCalculoActual;
  Result := RedondearImporte(AImporte, Parametros.ValorRedondeo,
    Parametros.ValorMenos, Parametros.EsRedondearArriba);
end;

// Salida de partida de la linea actual: la nueva ya calculada; si no hay,
// la actual de la tarifa destino y, si tampoco, la de la tarifa origen.
function TdmTarifasCambios.SalidaParaDescuento: Double;
begin
  Result := LeerFloatLinea('PRECIO_NUEVO_TARCLIN');
  if Result <= 0 then
    Result := LeerFloatLinea('PRECIO_SALIDA_ACTUAL_TARCLIN');
  if Result <= 0 then
    Result := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
end;

// FZ-ISSUE-944: salida que no se toca en una rebaja: la actual de la tarifa
// destino o, si no tiene precio, la de origen.
function TdmTarifasCambios.SalidaReferenciaLinea: Double;
begin
  Result := LeerFloatLinea('PRECIO_SALIDA_ACTUAL_TARCLIN');
  if Result <= 0 then
    Result := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
end;

procedure TdmTarifasCambios.CalcularDescuento(ASalida, APorcentaje: Double;
  out AFinal, ADto, APorcentajeReal: Double);
begin
  AFinal := ASalida;
  if APorcentaje > 0 then
    AFinal := RedondearConCabecera(ASalida * (1 - APorcentaje / 100));
  ADto := Max(ASalida - AFinal, 0);
  APorcentajeReal := 0;
  if ASalida > 0 then
    APorcentajeReal := Round(ADto / ASalida * 100 * 100) / 100;
end;

// Graba el descuento de las lineas indicadas (ID -> % pedido). La salida no
// cambia; el % grabado es el real tras redondear.
procedure TdmTarifasCambios.GrabarDescuentos(
  const APorLinea: TDictionary<Integer, Double>);
var
  dDto: Double;
  dFinal: Double;
  dPorcentaje: Double;
  dPorcentajeReal: Double;
  dSalida: Double;
  EsTransaccionPropia: Boolean;
  oConexion: TUniConnection;
  qry: TUniQuery;
begin
  if APorLinea.Count > 0 then
  begin
    oConexion := unqryTablaG.Connection as TUniConnection;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConexion;
      qry.SQL.Text :=
        'UPDATE fza_tarifas_cambios_lineas SET ' +
        'PRECIO_NUEVO_TARCLIN = :SALIDA, ' +
        'PRECIO_FINAL_NUEVO_TARCLIN = :FINAL, ' +
        'PRECIO_DTO_NUEVO_TARCLIN = :DTO, ' +
        'PORCENTAJE_DTO_NUEVO_TARCLIN = :PORC, ' +
        'ESTADO_TARCLIN = ''PENDIENTE'', MENSAJE_TARCLIN = NULL, ' +
        'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
        'WHERE ID_TARCLIN = :ID';
      EsTransaccionPropia := not oConexion.InTransaction;
      if EsTransaccionPropia then
        oConexion.StartTransaction;
      unqryLineas.DisableControls;
      try
        try
          unqryLineas.First;
          while not unqryLineas.Eof do
          begin
            if APorLinea.TryGetValue(
                 unqryLineas.FieldByName('ID_TARCLIN').AsInteger,
                 dPorcentaje) then
            begin
              dSalida := SalidaParaDescuento;
              CalcularDescuento(dSalida, dPorcentaje, dFinal, dDto,
                dPorcentajeReal);
              qry.ParamByName('SALIDA').AsFloat := dSalida;
              qry.ParamByName('FINAL').AsFloat := dFinal;
              qry.ParamByName('DTO').AsFloat := dDto;
              qry.ParamByName('PORC').AsFloat := dPorcentajeReal;
              qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
              qry.ParamByName('ID').AsInteger :=
                unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
              qry.Execute;
            end;
            unqryLineas.Next;
          end;
          if EsTransaccionPropia then
            oConexion.Commit;
        except
          if EsTransaccionPropia and oConexion.InTransaction then
            oConexion.Rollback;
          raise;
        end;
      finally
        unqryLineas.EnableControls;
      end;
    finally
      FreeAndNil(qry);
    end;
    unqryLineas.Refresh;
  end;
end;

procedure TdmTarifasCambios.GrabarLineaPendiente;
begin
  if unqryLineas.Active and (unqryLineas.State in dsEditModes) then
    unqryLineas.Post;
end;

// Completa los precios de partida de las lineas de la sesion activa, vengan
// de la carga de articulos, de un documento de trabajo o de un Excel:
// - lo que este vacio se lee de la tarifa o del proveedor;
// - si la cabecera cambio de tarifa origen/destino, se releen los precios
//   que dependen de ella y la linea pasa a esa tarifa;
// - el coste escrito a mano no se pisa.
// En un UPDATE de una sola tabla MySQL evalua las asignaciones en orden: los
// codigos de tarifa de la linea se actualizan al final, tras comparar. Por
// eso no hay JOIN con la cabecera: sus tarifas llegan como parametros.
function TdmTarifasCambios.EliminarLineasSesion(
  const AIds: TArray<Integer>): Integer;
var
  Consulta: TUniQuery;
  Parametros: TStringList;
  I: Integer;
begin
  Result := 0;
  if not unqryTablaG.Active or unqryTablaG.IsEmpty then
    raise Exception.Create(SErrorTarifasCambiosSinSesionActiva);
  if SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
    'APLICADA') then
    raise Exception.Create(SErrorTarifasCambiosSesionAplicada);
  if Length(AIds) > 0 then
  begin
    GrabarLineaPendiente;
    Consulta := TUniQuery.Create(nil);
    Parametros := TStringList.Create;
    try
      for I := 0 to High(AIds) do
        Parametros.Add(':ID' + IntToStr(I));
      Consulta.Connection := unqryTablaG.Connection;
      // Quitar un articulo lo quita de todos los periodos (FZ-ISSUE-944).
      Consulta.SQL.Text :=
        'DELETE L FROM fza_tarifas_cambios_lineas L ' +
        SQL_MISMO_ARTICULO_LINEA +
        'JOIN fza_tarifas_cambios C ON C.CODIGO_TARC=' +
        'L.CODIGO_TARC_TARCLIN WHERE C.CODIGO_TARC=:SESION ' +
        'AND C.ESTADO_TARC <> ''APLICADA'' AND S.ID_TARCLIN IN (' +
        Parametros.CommaText + ')';
      Consulta.ParamByName('SESION').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      for I := 0 to High(AIds) do
        Consulta.ParamByName('ID' + IntToStr(I)).AsInteger := AIds[I];
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      unqryLineas.Refresh;
    finally
      Parametros.Free;
      Consulta.Free;
    end;
  end;
end;

procedure TdmTarifasCambios.BloquearSesionEditable(AConsulta: TUniQuery;
  ASesion: Integer);
begin
  AConsulta.SQL.Text :=
    'SELECT ESTADO_TARC FROM fza_tarifas_cambios ' +
    'WHERE CODIGO_TARC = :SESION FOR UPDATE';
  AConsulta.ParamByName('SESION').AsInteger := ASesion;
  AConsulta.Open;
  if AConsulta.IsEmpty then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSinSesionActiva);
  if SameText(AConsulta.Fields[0].AsString, 'APLICADA') then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSesionAplicada);
  AConsulta.Close;
end;

procedure TdmTarifasCambios.DescomponerLinea(AId: Integer;
  ANivel: TNivelDescomposicionTarifa);
const
  SQL_LINEA_GENERAL =
    'L.CODIGO_TARC_TARCLIN = :SESION AND L.CODIGO_ART_TARCLIN = :ART ' +
    'AND L.CODIGO_UNIDAD_SKU_TARCLIN = :ORIGINAL';
  SQL_INSERTAR_VARIANTES =
    'INSERT INTO fza_tarifas_cambios_lineas (CODIGO_TARC_TARCLIN, ' +
    'ID_TARCP_TARCLIN, CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CODIGO_TAR_ORIGEN_TARCLIN, CODIGO_TAR_DESTINO_TARCLIN, ' +
    'PRECIO_ORIGEN_TARCLIN, PRECIO_COSTE_TARCLIN, ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN, PRECIO_FINAL_ACTUAL_TARCLIN, ' +
    'PRECIO_DTO_ACTUAL_TARCLIN, PORCENTAJE_DTO_ACTUAL_TARCLIN, ' +
    'PRECIO_NUEVO_TARCLIN, PRECIO_FINAL_NUEVO_TARCLIN, ' +
    'PRECIO_DTO_NUEVO_TARCLIN, PORCENTAJE_DTO_NUEVO_TARCLIN, ' +
    'ESAPLICAR_TARCLIN, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT L.CODIGO_TARC_TARCLIN, L.ID_TARCP_TARCLIN, ' +
    'L.CODIGO_ART_TARCLIN, V.UNIDAD, L.CODIGO_TAR_ORIGEN_TARCLIN, ' +
    'L.CODIGO_TAR_DESTINO_TARCLIN, ' +
    'COALESCE(O.PRECIO_SALIDA_ARTTAR, L.PRECIO_ORIGEN_TARCLIN), ' +
    'L.PRECIO_COSTE_TARCLIN, ' +
    'COALESCE(D.PRECIO_SALIDA_ARTTAR, L.PRECIO_SALIDA_ACTUAL_TARCLIN), ' +
    'COALESCE(D.PRECIO_FINAL_ARTTAR, L.PRECIO_FINAL_ACTUAL_TARCLIN), ' +
    'CASE WHEN D.CODIGO_UNICO_ARTTAR IS NULL THEN L.PRECIO_DTO_ACTUAL_TARCLIN ' +
    'ELSE COALESCE(D.PRECIO_DTO_ARTTAR, 0) END, ' +
    'CASE WHEN D.CODIGO_UNICO_ARTTAR IS NULL ' +
    'THEN L.PORCENTAJE_DTO_ACTUAL_TARCLIN ' +
    'ELSE COALESCE(D.PORCENTAJE_DTO_ARTTAR, 0) END, ' +
    'L.PRECIO_NUEVO_TARCLIN, L.PRECIO_FINAL_NUEVO_TARCLIN, ' +
    'L.PRECIO_DTO_NUEVO_TARCLIN, L.PORCENTAJE_DTO_NUEVO_TARCLIN, ' +
    'L.ESAPLICAR_TARCLIN, :USUARIO, :USUARIO ' +
    'FROM fza_tarifas_cambios_lineas L CROSS JOIN (%s) V ' +
    'LEFT JOIN fza_articulos_tarifas O ON O.CODIGO_UNICO_ARTTAR = (%s) ' +
    'AND O.CODIGO_UNIDAD_ARTTAR = V.UNIDAD ' +
    'LEFT JOIN fza_articulos_tarifas D ON D.CODIGO_UNICO_ARTTAR = (%s) ' +
    'AND D.CODIGO_UNIDAD_ARTTAR = V.UNIDAD ' +
    'WHERE ' + SQL_LINEA_GENERAL +
    ' AND NOT EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas X ' +
    'WHERE X.CODIGO_TARC_TARCLIN = L.CODIGO_TARC_TARCLIN ' +
    'AND X.ID_TARCP_TARCLIN = L.ID_TARCP_TARCLIN ' +
    'AND X.CODIGO_ART_TARCLIN = L.CODIGO_ART_TARCLIN ' +
    'AND X.CODIGO_UNIDAD_SKU_TARCLIN = V.UNIDAD)';
var
  Consulta: TUniQuery;
  Conexion: TUniConnection;
  Sesion: Integer;
  Articulo, Unidad, SqlVariantes, MensajeSinVariantes: string;
  TransaccionPropia: Boolean;
begin
  Sesion := SesionActual;
  if Sesion = 0 then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSinSesionActiva);
  if SesionAplicada then
    raise EValidacionBBDD.Create(SErrorTarifasCambiosSesionAplicada);
  GrabarLineaPendiente;
  if ANivel = ndtColor then
  begin
    SqlVariantes := SQL_UNIDADES_COLOR;
    MensajeSinVariantes := SErrorDescomponerTarifaSinColores;
  end
  else
  begin
    SqlVariantes := SQL_UNIDADES_TALLA;
    MensajeSinVariantes := SErrorDescomponerTarifaSinTallas;
  end;

  Conexion := unqryTablaG.Connection as TUniConnection;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := Conexion;
    TransaccionPropia := not Conexion.InTransaction;
    if TransaccionPropia then
      Conexion.StartTransaction
    else
      Conexion.ExecSQL('SAVEPOINT descomponer_linea_tarifa', []);
    try
      BloquearSesionEditable(Consulta, Sesion);
      Consulta.SQL.Text :=
        'SELECT CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN ' +
        'FROM fza_tarifas_cambios_lineas WHERE ID_TARCLIN = :ID ' +
        'AND CODIGO_TARC_TARCLIN = :SESION FOR UPDATE';
      Consulta.ParamByName('ID').AsInteger := AId;
      Consulta.ParamByName('SESION').AsInteger := Sesion;
      Consulta.Open;
      if Consulta.IsEmpty then
        raise EValidacionBBDD.Create(SErrorDescomponerTarifaSeleccioneLinea);
      Articulo := Consulta.FieldByName('CODIGO_ART_TARCLIN').AsString;
      Unidad := Consulta.FieldByName('CODIGO_UNIDAD_SKU_TARCLIN').AsString;
      if (Unidad <> '') and not SameText(Unidad, Articulo) then
        raise EValidacionBBDD.Create(SErrorDescomponerTarifaLineaNoGeneral);
      Consulta.Close;

      Consulta.SQL.Text := SqlVariantes + ' LIMIT 1';
      Consulta.ParamByName('ART').AsString := Articulo;
      Consulta.Open;
      if Consulta.IsEmpty then
        raise EValidacionBBDD.Create(MensajeSinVariantes);
      Consulta.Close;

      // Cada periodo aporta sus propios precios y conserva las variantes
      // que ya estaban preparadas en la sesión.
      Consulta.SQL.Text := Format(SQL_INSERTAR_VARIANTES, [SqlVariantes,
        SqlSeleccionPrecioTarifa('L.CODIGO_ART_TARCLIN', 'V.UNIDAD',
          'L.CODIGO_TAR_ORIGEN_TARCLIN', 'CURDATE()'),
        SqlSeleccionPrecioTarifa('L.CODIGO_ART_TARCLIN', 'V.UNIDAD',
          'L.CODIGO_TAR_DESTINO_TARCLIN', 'CURDATE()')]);
      Consulta.ParamByName('SESION').AsInteger := Sesion;
      Consulta.ParamByName('ART').AsString := Articulo;
      Consulta.ParamByName('ORIGINAL').AsString := Unidad;
      Consulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      Consulta.Execute;

      Consulta.SQL.Text := 'DELETE L FROM fza_tarifas_cambios_lineas L ' +
        'WHERE ' + SQL_LINEA_GENERAL;
      Consulta.ParamByName('SESION').AsInteger := Sesion;
      Consulta.ParamByName('ART').AsString := Articulo;
      Consulta.ParamByName('ORIGINAL').AsString := Unidad;
      Consulta.Execute;
      if TransaccionPropia then
        Conexion.Commit
      else
        Conexion.ExecSQL('RELEASE SAVEPOINT descomponer_linea_tarifa', []);
    except
      if Conexion.InTransaction then
        if TransaccionPropia then
          Conexion.Rollback
        else
        begin
          Conexion.ExecSQL(
            'ROLLBACK TO SAVEPOINT descomponer_linea_tarifa', []);
          Conexion.ExecSQL(
            'RELEASE SAVEPOINT descomponer_linea_tarifa', []);
        end;
      raise;
    end;
  finally
    Consulta.Free;
  end;
  unqryLineas.Refresh;
end;

function TdmTarifasCambios.ActualizarCostesLineas(
  const AIds: TArray<Integer>): Integer;
var
  Consulta: TUniQuery;
  Parametros: TStringList;
  I: Integer;
begin
  Result := 0;
  if not unqryTablaG.Active or unqryTablaG.IsEmpty then
    raise Exception.Create(SErrorTarifasCambiosSinSesionActiva);
  if SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
    'APLICADA') then
    raise Exception.Create(SErrorTarifasCambiosSesionAplicada);
  if Length(AIds) > 0 then
  begin
    GrabarLineaPendiente;
    Parametros := TStringList.Create;
    Consulta := TUniQuery.Create(nil);
    try
      for I := 0 to High(AIds) do
        Parametros.Add(':ID' + IntToStr(I));
      Consulta.Connection := unqryTablaG.Connection;
      // El coste es del articulo: se actualiza en todos los periodos.
      Consulta.SQL.Text :=
        'UPDATE fza_tarifas_cambios_lineas L ' +
        SQL_MISMO_ARTICULO_LINEA + 'SET ' +
        'L.PRECIO_COSTE_TARCLIN = ' + SQL_COSTE_LINEA + ', ' +
        'L.USUARIO_MODIF = :USUARIO, L.INSTANTE_MODIF = NOW() ' +
        'WHERE L.CODIGO_TARC_TARCLIN = :SESION AND S.ID_TARCLIN IN (' +
        Parametros.CommaText + ')';
      Consulta.ParamByName('SESION').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      Consulta.ParamByName('TAR_ORIG').AsString :=
        unqryTablaG.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString;
      Consulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      for I := 0 to High(AIds) do
        Consulta.ParamByName('ID' + IntToStr(I)).AsInteger := AIds[I];
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      unqryLineas.Refresh;
    finally
      Consulta.Free;
      Parametros.Free;
    end;
  end;
end;

procedure TdmTarifasCambios.CabeceraAntesDeBorrar(DataSet: TDataSet);
var
  Consulta: TUniQuery;
begin
  IniciarBorradoTransaccional;
  try
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := unqryTablaG.Connection;
      Consulta.SQL.Text :=
        'DELETE FROM fza_tarifas_cambios_lineas ' +
        'WHERE CODIGO_TARC_TARCLIN = :SESION';
      Consulta.ParamByName('SESION').AsInteger :=
        DataSet.FieldByName('CODIGO_TARC').AsInteger;
      Consulta.Execute;
      Consulta.SQL.Text :=
        'DELETE FROM fza_tarifas_cambios_periodos ' +
        'WHERE CODIGO_TARC_TARCP = :SESION';
      Consulta.ParamByName('SESION').AsInteger :=
        DataSet.FieldByName('CODIGO_TARC').AsInteger;
      Consulta.Execute;
    finally
      Consulta.Free;
    end;
  except
    RevertirBorradoTransaccional;
    raise;
  end;
end;

procedure TdmTarifasCambios.unqryLineasBeforeDelete(DataSet: TDataSet);
begin
  if unqryTablaG.Active and not unqryTablaG.IsEmpty and
    SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString, 'APLICADA') then
    raise Exception.Create(SErrorTarifasCambiosSesionAplicada);
end;

procedure TdmTarifasCambios.RellenarPreciosPartida;
var
  qry: TUniQuery;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (not SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
                   'APLICADA')) then
  begin
    GrabarLineaPendiente;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      qry.SQL.Text :=
        'UPDATE fza_tarifas_cambios_lineas L SET ' +
        'L.PRECIO_ORIGEN_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_ORIGEN_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_ORIGEN + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_SALIDA_ARTTAR', 'TAR_ORIG']) +
        '  ELSE L.PRECIO_ORIGEN_TARCLIN END, ' +
        'L.PRECIO_SALIDA_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_SALIDA_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_SALIDA_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PRECIO_SALIDA_ACTUAL_TARCLIN END, ' +
        'L.PRECIO_FINAL_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_FINAL_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_FINAL_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PRECIO_FINAL_ACTUAL_TARCLIN END, ' +
        'L.PRECIO_DTO_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PRECIO_DTO_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PRECIO_DTO_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PRECIO_DTO_ACTUAL_TARCLIN END, ' +
        'L.PORCENTAJE_DTO_ACTUAL_TARCLIN = CASE WHEN ' +
        '  L.PORCENTAJE_DTO_ACTUAL_TARCLIN IS NULL OR ' +
        SQL_CAMBIO_TARIFA_DESTINO + ' THEN ' +
        Format(SQL_PRECIO_TARIFA_LINEA,
          ['PORCENTAJE_DTO_ARTTAR', 'TAR_DEST']) +
        '  ELSE L.PORCENTAJE_DTO_ACTUAL_TARCLIN END, ' +
        'L.PRECIO_COSTE_TARCLIN = COALESCE(L.PRECIO_COSTE_TARCLIN, ' +
        SQL_COSTE_LINEA + '), ' +
        'L.CODIGO_TAR_ORIGEN_TARCLIN = :TAR_ORIG, ' +
        'L.CODIGO_TAR_DESTINO_TARCLIN = :TAR_DEST ' +
        'WHERE L.CODIGO_TARC_TARCLIN = :CODIGO';
      qry.ParamByName('CODIGO').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      qry.ParamByName('TAR_ORIG').AsString :=
        unqryTablaG.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString;
      qry.ParamByName('TAR_DEST').AsString :=
        unqryTablaG.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString;
      qry.Execute;
      if unqryLineas.Active then
        unqryLineas.Refresh;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

const
  // Una celda vacia del Excel llega como NULL y conserva el valor actual.
  SQL_ACTUALIZAR_LINEA_EXCEL =
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'ESAPLICAR_TARCLIN = COALESCE(:APLICAR, ESAPLICAR_TARCLIN), ' +
    'PRECIO_ORIGEN_TARCLIN = COALESCE(:P0, PRECIO_ORIGEN_TARCLIN), ' +
    'PRECIO_COSTE_TARCLIN = COALESCE(:P1, PRECIO_COSTE_TARCLIN), ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN = ' +
    '  COALESCE(:P2, PRECIO_SALIDA_ACTUAL_TARCLIN), ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN = ' +
    '  COALESCE(:P3, PRECIO_FINAL_ACTUAL_TARCLIN), ' +
    'PRECIO_DTO_ACTUAL_TARCLIN = COALESCE(:P4, PRECIO_DTO_ACTUAL_TARCLIN), ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN = ' +
    '  COALESCE(:P5, PORCENTAJE_DTO_ACTUAL_TARCLIN), ' +
    'PRECIO_NUEVO_TARCLIN = COALESCE(:P6, PRECIO_NUEVO_TARCLIN), ' +
    'PRECIO_FINAL_NUEVO_TARCLIN = ' +
    '  COALESCE(:P7, PRECIO_FINAL_NUEVO_TARCLIN), ' +
    'PRECIO_DTO_NUEVO_TARCLIN = COALESCE(:P8, PRECIO_DTO_NUEVO_TARCLIN), ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN = ' +
    '  COALESCE(:P9, PORCENTAJE_DTO_NUEVO_TARCLIN), ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() WHERE ' +
    SQL_FILTRO_ARTICULO_LINEA;
  SQL_INSERTAR_LINEA_EXCEL =
    'INSERT INTO fza_tarifas_cambios_lineas (CODIGO_TARC_TARCLIN, ' +
    'ID_TARCP_TARCLIN, CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CODIGO_TAR_ORIGEN_TARCLIN, CODIGO_TAR_DESTINO_TARCLIN, ' +
    'ESAPLICAR_TARCLIN, ESTADO_TARCLIN, PRECIO_ORIGEN_TARCLIN, ' +
    'PRECIO_COSTE_TARCLIN, PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN, PRECIO_DTO_ACTUAL_TARCLIN, ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN, PRECIO_NUEVO_TARCLIN, ' +
    'PRECIO_FINAL_NUEVO_TARCLIN, PRECIO_DTO_NUEVO_TARCLIN, ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT C.CODIGO_TARC, :TARCP, :ART, :SKU, C.CODIGO_TAR_ORIGEN_TARC, ' +
    'C.CODIGO_TAR_DESTINO_TARC, COALESCE(:APLICAR, ''S''), ''PENDIENTE'', ' +
    ':P0, :P1, :P2, :P3, :P4, :P5, :P6, :P7, :P8, :P9, NOW(), :USUARIO ' +
    'FROM fza_tarifas_cambios C WHERE C.CODIGO_TARC = :TARC';
  SQL_EXISTE_LINEA_EXCEL =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_tarifas_cambios_lineas WHERE ' +
    SQL_FILTRO_ARTICULO_LINEA;

procedure TdmTarifasCambios.AsignarParametrosLineaExcel(AConsulta: TUniQuery;
  const ALinea: TLineaSesionTarifaExcel);
var
  Importe: TImporteSesionTarifa;
  Parametro: TUniParam;
begin
  AConsulta.ParamByName('TARC').AsInteger :=
    unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
  AConsulta.ParamByName('TARCP').AsInteger := IdPeriodoActual;
  AConsulta.ParamByName('ART').AsString := ALinea.Articulo;
  AConsulta.ParamByName('SKU').AsString := ALinea.Sku;
  AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  Parametro := AConsulta.ParamByName('APLICAR');
  Parametro.DataType := ftString;
  if ALinea.Aplicar = '' then
    Parametro.Clear
  else
    Parametro.AsString := ALinea.Aplicar;
  for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
  begin
    Parametro := AConsulta.ParamByName('P' + IntToStr(Ord(Importe)));
    Parametro.DataType := ftFloat;
    if ALinea.TieneImporte[Importe] then
      Parametro.AsFloat := ALinea.Importes[Importe]
    else
      Parametro.Clear;
  end;
end;

function EsDescuentoPorPorcentajeExcel(
  const ALinea: TLineaSesionTarifaExcel): Boolean;
begin
  Result := ALinea.TieneImporte[istPorcDtoNuevo] and
    (not ALinea.TieneImporte[istFinalNueva]);
end;

function ClaveArticuloSku(const AArticulo, ASku: string): string;
begin
  Result := AArticulo + #9 + ASku;
end;

// Si el Excel trae solo el final se calculan el importe y el % sin
// redondear: el final lo ha fijado el usuario. Si trae solo el %, se trata
// despues con el criterio comun (GrabarDescuentos) una vez cargadas las
// lineas y sus precios de partida.
procedure TdmTarifasCambios.CompletarDescuentoLineaExcel(AConsulta: TUniQuery;
  const ALinea: TLineaSesionTarifaExcel);
begin
  if ALinea.TieneImporte[istFinalNueva] and
     (not ALinea.TieneImporte[istPorcDtoNuevo]) and
     (not ALinea.TieneImporte[istDtoNuevo]) then
  begin
    AConsulta.SQL.Text :=
      Format(SQL_DESCUENTO_FINAL, [SQL_FILTRO_ARTICULO_LINEA]);
    AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    AConsulta.ParamByName('TARC').AsInteger :=
      unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
    AConsulta.ParamByName('TARCP').AsInteger := IdPeriodoActual;
    AConsulta.ParamByName('ART').AsString := ALinea.Articulo;
    AConsulta.ParamByName('SKU').AsString := ALinea.Sku;
    AConsulta.Execute;
  end;
end;

procedure TdmTarifasCambios.ImportarLineasExcel(
  const ALineas: TLineasSesionTarifaExcel;
  out ANuevas, AActualizadas: Integer);
var
  EsTransaccionPropia: Boolean;
  iLinea: Integer;
  oConexion: TUniConnection;
  qryActualizar: TUniQuery;
  qryDescuento: TUniQuery;
  qryExiste: TUniQuery;
  qryInsertar: TUniQuery;
begin
  ANuevas := 0;
  AActualizadas := 0;
  GrabarLineaPendiente;
  oConexion := unqryTablaG.Connection as TUniConnection;
  qryActualizar := TUniQuery.Create(nil);
  qryDescuento := TUniQuery.Create(nil);
  qryExiste := TUniQuery.Create(nil);
  qryInsertar := TUniQuery.Create(nil);
  try
    qryDescuento.Connection := oConexion;
    qryExiste.Connection := oConexion;
    qryExiste.SQL.Text := SQL_EXISTE_LINEA_EXCEL;
    qryActualizar.Connection := oConexion;
    qryActualizar.SQL.Text := SQL_ACTUALIZAR_LINEA_EXCEL;
    qryInsertar.Connection := oConexion;
    qryInsertar.SQL.Text := SQL_INSERTAR_LINEA_EXCEL;
    EsTransaccionPropia := not oConexion.InTransaction;
    if EsTransaccionPropia then
      oConexion.StartTransaction;
    try
      for iLinea := 0 to High(ALineas) do
      begin
        qryExiste.Close;
        qryExiste.ParamByName('TARC').AsInteger :=
          unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
        qryExiste.ParamByName('TARCP').AsInteger := IdPeriodoActual;
        qryExiste.ParamByName('ART').AsString := ALineas[iLinea].Articulo;
        qryExiste.ParamByName('SKU').AsString := ALineas[iLinea].Sku;
        qryExiste.Open;
        if qryExiste.FieldByName('CANTIDAD').AsInteger > 0 then
        begin
          AsignarParametrosLineaExcel(qryActualizar, ALineas[iLinea]);
          qryActualizar.Execute;
          Inc(AActualizadas);
        end
        else
        begin
          AsignarParametrosLineaExcel(qryInsertar, ALineas[iLinea]);
          qryInsertar.Execute;
          Inc(ANuevas);
        end;
        CompletarDescuentoLineaExcel(qryDescuento, ALineas[iLinea]);
      end;
      if EsTransaccionPropia then
        oConexion.Commit;
    except
      if EsTransaccionPropia and oConexion.InTransaction then
        oConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qryInsertar);
    FreeAndNil(qryExiste);
    FreeAndNil(qryDescuento);
    FreeAndNil(qryActualizar);
  end;
  RellenarPreciosPartida;
  AplicarPorcentajesExcel(ALineas);
  // Los articulos nuevos del Excel pasan a los demas periodos.
  SincronizarPeriodos;
end;

// Filas del Excel con solo "% dto nuevo": se calculan con el criterio comun
// de redondeo sobre la salida de cada linea ya cargada.
procedure TdmTarifasCambios.AplicarPorcentajesExcel(
  const ALineas: TLineasSesionTarifaExcel);
var
  dPorcentaje: Double;
  iLinea: Integer;
  PorClave: TDictionary<string, Double>;
  PorLinea: TDictionary<Integer, Double>;
begin
  PorClave := TDictionary<string, Double>.Create;
  PorLinea := TDictionary<Integer, Double>.Create;
  try
    for iLinea := 0 to High(ALineas) do
      if EsDescuentoPorPorcentajeExcel(ALineas[iLinea]) then
        PorClave.AddOrSetValue(
          ClaveArticuloSku(ALineas[iLinea].Articulo, ALineas[iLinea].Sku),
          ALineas[iLinea].Importes[istPorcDtoNuevo]);
    if PorClave.Count > 0 then
    begin
      unqryLineas.DisableControls;
      try
        unqryLineas.First;
        while not unqryLineas.Eof do
        begin
          if PorClave.TryGetValue(ClaveArticuloSku(
               unqryLineas.FieldByName('CODIGO_ART_TARCLIN').AsString,
               unqryLineas.FieldByName('CODIGO_UNIDAD_SKU_TARCLIN').AsString),
               dPorcentaje) then
            PorLinea.AddOrSetValue(
              unqryLineas.FieldByName('ID_TARCLIN').AsInteger, dPorcentaje);
          unqryLineas.Next;
        end;
      finally
        unqryLineas.EnableControls;
      end;
      GrabarDescuentos(PorLinea);
    end;
  finally
    FreeAndNil(PorLinea);
    FreeAndNil(PorClave);
  end;
end;

function TdmTarifasCambios.RecalcularSesionActual(
  const AIdsLinea: TArray<Integer>; out AMensaje: string): Integer;
var
  qry               : TUniQuery;
  Seleccion: TDictionary<Integer, Boolean>;
  iId: Integer;
  iSinFinalAnterior: Integer;
  EsSeleccionada: Boolean;
  EsSinFinalAnterior: Boolean;
  sCampoOrigen      : string;
  sCampoDestino     : string;
  sTipoAplicacion   : string;
  dValorAplicacion  : Double;
  dValorRedondeo    : Double;
  dValorMenos       : Double;
  dBase             : Double;
  dNuevo            : Double;
  dSalida           : Double;
  dFinal            : Double;
  dDto              : Double;
  dPorcDto          : Double;
  EsRedondearArriba : Boolean;
  EsPeriodoLinea    : Boolean;
  dReferencia       : Double;
  Parametros        : TParametrosCalculoTarifa;
begin
  Result := 0;
  AMensaje := '';
  if (not unqryTablaG.Active) or unqryTablaG.IsEmpty then
    AMensaje := SErrorTarifasCambiosSinSesionActiva
  else if (not unqryLineas.Active) or unqryLineas.IsEmpty then
    AMensaje := SErrorTarifasCambiosSesionSinLineas
  else if Length(AIdsLinea) = 0 then
    AMensaje := SErrorSeleccionVaciaSesionTarifa
  else
  begin
    SincronizarPeriodos;
    RellenarPreciosPartida;
    Parametros := ParametrosCalculoActual;
    sCampoOrigen := Parametros.CampoOrigen;
    sCampoDestino := Parametros.CampoDestino;
    sTipoAplicacion := Parametros.TipoAplicacion;
    dValorAplicacion := Parametros.ValorAplicacion;
    dValorRedondeo := Parametros.ValorRedondeo;
    dValorMenos := Parametros.ValorMenos;
    EsRedondearArriba := Parametros.EsRedondearArriba;
    Seleccion := TDictionary<Integer, Boolean>.Create;
    iSinFinalAnterior := 0;
    try
      for iId in AIdsLinea do
        Seleccion.AddOrSetValue(iId, True);
      qry := TUniQuery.Create(nil);
      try
        qry.Connection := unqryTablaG.Connection;
        qry.SQL.Text :=
          'UPDATE fza_tarifas_cambios_lineas SET ' +
          '  PRECIO_NUEVO_TARCLIN = :SALIDA, ' +
          '  PRECIO_FINAL_NUEVO_TARCLIN = :FINAL, ' +
          '  PRECIO_DTO_NUEVO_TARCLIN = :DTO, ' +
          '  PORCENTAJE_DTO_NUEVO_TARCLIN = :PORC_DTO, ' +
          '  ESTADO_TARCLIN = ''PENDIENTE'', ' +
          '  MENSAJE_TARCLIN = NULL, ' +
          '  USUARIO_MODIF = :USUARIO, ' +
          '  INSTANTE_MODIF = NOW() ' +
          'WHERE ID_TARCLIN = :ID';
        unqryLineas.DisableControls;
        try
          unqryLineas.First;
          while not unqryLineas.Eof do
          begin
            EsSeleccionada := Seleccion.ContainsKey(
              unqryLineas.FieldByName('ID_TARCLIN').AsInteger);
            EsSinFinalAnterior :=
              SameText(sCampoOrigen, 'PRECIO_FINAL_ANTERIOR') and
              not SameText(sTipoAplicacion, 'PRECIO_FIJO') and
              unqryLineas.FieldByName(
                'PRECIO_FINAL_ANTERIOR_TARCLIN').IsNull;
            if EsSeleccionada and EsSinFinalAnterior then
              Inc(iSinFinalAnterior);
            if EsSeleccionada and not EsSinFinalAnterior then
            begin
              dBase := PrecioBaseLinea(sCampoOrigen);
              dNuevo := CalcularImporte(dBase, sTipoAplicacion,
                                        dValorAplicacion);
              dNuevo := RedondearImporte(dNuevo, dValorRedondeo,
                                         dValorMenos, EsRedondearArriba);
              dSalida := dNuevo;
              dFinal := dNuevo;
              dDto := 0;
              dPorcDto := 0;
              // FZ-ISSUE-944: en rebajas (lineas de un periodo) la salida no
              // puede cambiar (ley de consumo): el precio va como descuento.
              // Fuera de rebajas, una bajada tambien se hace como descuento;
              // la salida solo cambia si sube o si se elige Precio de salida.
              dReferencia := SalidaReferenciaLinea;
              EsPeriodoLinea :=
                unqryLineas.FieldByName('ID_TARCP_TARCLIN').AsInteger <> 0;
              if EsPeriodoLinea or SameText(sCampoDestino, 'PRECIO_FINAL') or
                ((not SameText(sCampoDestino, 'PRECIO_SALIDA')) and
                 (dReferencia > 0) and (dNuevo < dReferencia)) then
              begin
                dSalida := dReferencia;
                if dSalida <= 0 then
                  dSalida := dNuevo;
                dFinal := dNuevo;
                // En rebajas el precio final nunca supera la salida.
                if EsPeriodoLinea and (dFinal > dSalida) then
                  dFinal := dSalida;
                dDto := dSalida - dFinal;
                if dDto < 0 then
                  dDto := 0;
              end
              else
              begin
                // Conservar la rebaja preparada en la sesión, también
                // después de «Descuento en lote» o de importar Excel.
                dPorcDto := LeerFloatLinea(
                  'PORCENTAJE_DTO_NUEVO_TARCLIN');
                CalcularDescuento(dSalida, dPorcDto,
                  dFinal, dDto, dPorcDto);
              end;
              if (dSalida > 0) and (dDto > 0) then
                dPorcDto := dDto / dSalida * 100;
              qry.ParamByName('SALIDA').AsFloat := dSalida;
              qry.ParamByName('FINAL').AsFloat := dFinal;
              qry.ParamByName('DTO').AsFloat := dDto;
              qry.ParamByName('PORC_DTO').AsFloat := dPorcDto;
              qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
              qry.ParamByName('ID').AsInteger :=
                unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
              qry.Execute;
              Inc(Result);
            end;
            unqryLineas.Next;
          end;
        finally
          unqryLineas.EnableControls;
        end;
        qry.SQL.Text :=
          'UPDATE fza_tarifas_cambios SET ' +
          '  ESTADO_TARC = ''BORRADOR'', ' +
          '  INSTANTE_APLICACION_TARC = NULL, ' +
          '  USUARIO_APLICACION_TARC = NULL, ' +
          '  USUARIO_MODIF = :USUARIO, ' +
          '  INSTANTE_MODIF = NOW() ' +
          'WHERE CODIGO_TARC = :CODIGO';
        qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
        qry.ParamByName('CODIGO').AsInteger :=
          unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
        qry.Execute;
        if IdPeriodoActual <> 0 then
          MarcarPeriodoTarifaBorrador(
            unqryTablaG.Connection as TUniConnection, IdPeriodoActual,
            IdentidadSesion.Usuario);
        RefrescarTrasCambioPeriodos(IdPeriodoActual);
        if iSinFinalAnterior > 0 then
          AMensaje := Format(SInfoCalculoSinFinalAnterior,
            [Result, iSinFinalAnterior]);
      finally
        FreeAndNil(qry);
      end;
    finally
      FreeAndNil(Seleccion);
    end;
  end;
end;

procedure TdmTarifasCambios.ConfigurarConsultasAplicacion(
  AConsultaBusca, AConsultaMarca, AConsultaUnico: TUniQuery);
begin
  // FZ-ISSUE-944: la fila de precio la decide TTramosPrecioTarifa.
  AConsultaBusca.SQL.Clear;
  AConsultaMarca.SQL.Text :=
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'ESTADO_TARCLIN = :ESTADO, MENSAJE_TARCLIN = :MENSAJE, ' +
    'CODIGO_UNICO_ARTTAR_TARCLIN = NULLIF(:UNICO, 0), ' +
    'INSTANTE_APLICACION_TARCLIN = IF(:UNICO = 0, NULL, NOW()), ' +
    'USUARIO_MODIF = :USUARIO, ' +
    'INSTANTE_MODIF = NOW() WHERE ID_TARCLIN = :ID';
  AConsultaUnico.SQL.Text :=
    'SELECT LAST_INSERT_ID() AS CODIGO_UNICO_ARTTAR';
end;

function FloatCampo(ADataSet: TDataSet; const ACampo: string): Double;
begin
  Result := 0;
  if not ADataSet.FieldByName(ACampo).IsNull then
    Result := ADataSet.FieldByName(ACampo).AsFloat;
end;

function TdmTarifasCambios.AplicarLineaTarifa(ALinea: TDataSet;
  AConsultaBusca, AConsultaExec, AConsultaMarca,
  AConsultaUnico: TUniQuery;
  out AEncoloPrestaShop: Boolean): Boolean;
var
  bTieneHasta: Boolean;
  dDesde: TDateTime;
  dHasta: TDateTime;
  oTramos: TTramosPrecioTarifa;
  Precios: TPreciosTramoTarifa;
  iUnico: Integer;
  sArticulo: string;
  sSku: string;
  sTarifa: string;
begin
  Result := False;
  AEncoloPrestaShop := False;
  if SameText(ALinea.FieldByName('ESAPLICAR_TARCLIN').AsString, 'S') then
  begin
    sArticulo := ALinea.FieldByName('CODIGO_ART_TARCLIN').AsString;
    sSku := ALinea.FieldByName('CODIGO_UNIDAD_SKU_TARCLIN').AsString;
    sTarifa := ALinea.FieldByName('CODIGO_TAR_DESTINO_TARCLIN').AsString;
    // FZ-ISSUE-944: en una misma tarifa, artículo y SKU no puede haber dos
    // precios vigentes el mismo día. El periodo aparta el precio base de
    // sus fechas; un precio sin periodo rellena los huecos entre periodos.
    Precios.Salida := FloatCampo(ALinea, 'PRECIO_NUEVO_TARCLIN');
    Precios.Final := FloatCampo(ALinea, 'PRECIO_FINAL_NUEVO_TARCLIN');
    Precios.Dto := FloatCampo(ALinea, 'PRECIO_DTO_NUEVO_TARCLIN');
    Precios.PorcentajeDto := FloatCampo(ALinea,
      'PORCENTAJE_DTO_NUEVO_TARCLIN');
    oTramos := TTramosPrecioTarifa.Create(
      AConsultaExec.Connection as TUniConnection, IdentidadSesion.Usuario,
      sArticulo, sSku, sTarifa);
    try
      if ALinea.FieldByName('ID_TARCP_TARCLIN').AsInteger <> 0 then
      begin
        // En rebajas cambiar la salida va contra la ley de consumo: se avisa
        // al editarla y al aplicar (LineasPeriodoConSalidaCambiada), pero
        // se respeta lo que decida el usuario.
        iUnico := oTramos.AplicarPeriodo(
          ALinea.FieldByName('FECHA_DESDE_TARCP').AsDateTime,
          ALinea.FieldByName('FECHA_HASTA_TARCP').AsDateTime, Precios);
      end
      else
      begin
        dDesde := Date;
        if not CampoCabecera('FECHA_DESDE_TARC').IsNull then
          dDesde := CampoCabecera('FECHA_DESDE_TARC').AsDateTime;
        bTieneHasta := not CampoCabecera('FECHA_HASTA_TARC').IsNull;
        dHasta := 0;
        if bTieneHasta then
          dHasta := CampoCabecera('FECHA_HASTA_TARC').AsDateTime;
        iUnico := oTramos.AplicarBase(dDesde, bTieneHasta, dHasta, Precios);
      end;
    finally
      oTramos.Free;
    end;
    Result := iUnico <> 0;
    if Result then
    begin
      AConsultaMarca.ParamByName('ESTADO').AsString := 'APLICADA';
      AConsultaMarca.ParamByName('MENSAJE').AsString := 'Aplicada';
    end
    else
    begin
      AConsultaMarca.ParamByName('ESTADO').AsString := 'SIN CAMBIOS';
      AConsultaMarca.ParamByName('MENSAJE').AsString :=
        SInfoLineaTarifaSinCambios;
    end;
    AConsultaMarca.ParamByName('UNICO').AsInteger := iUnico;
    AConsultaMarca.ParamByName('USUARIO').AsString :=
      IdentidadSesion.Usuario;
    AConsultaMarca.ParamByName('ID').AsInteger :=
      ALinea.FieldByName('ID_TARCLIN').AsInteger;
    AConsultaMarca.Execute;
    if Result and SameText(
      Trim(sTarifa),
      LeerCodigoTarifaPrestaShop(
        AConsultaExec.Connection,
        IdentidadSesion.Usuario)) then
    begin
      EncolarPrecioPrestaShop(
        AConsultaExec.Connection,
        sArticulo,
        IdentidadSesion.Usuario);
      AEncoloPrestaShop := True;
    end;
  end;
end;

procedure TdmTarifasCambios.MarcarSesionAplicada(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_tarifas_cambios SET ESTADO_TARC = ''APLICADA'', ' +
    'INSTANTE_APLICACION_TARC = NOW(), USUARIO_APLICACION_TARC = ' +
    ':USUARIO, USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC = :CODIGO';
  AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  AConsulta.ParamByName('CODIGO').AsInteger :=
    unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
  AConsulta.Execute;
end;

// Aplica todas las lineas de la sesion, de todos sus periodos, en una sola
// transaccion. Los periodos se validan antes: sin solapes ni fechas al reves.
function TdmTarifasCambios.AplicarSesionActual(
  out AMensaje: string): Integer;
var
  EncoloLineaPrestaShop: Boolean;
  EsTransaccionPropia: Boolean;
  HayEncoladoPrestaShop: Boolean;
  TransaccionConfirmada: Boolean;
  oConexion: TUniConnection;
  qryBusca: TUniQuery;
  qryExec: TUniQuery;
  qryLineas: TUniQuery;
  qryMarca: TUniQuery;
  qryUnico: TUniQuery;
begin
  Result := 0;
  AMensaje := '';
  if (not unqryTablaG.Active) or unqryTablaG.IsEmpty then
    AMensaje := SErrorTarifasCambiosSinSesionActiva
  else if SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
    'APLICADA') then
    AMensaje := SErrorTarifasCambiosSesionAplicada
  else if (not unqryLineas.Active) or unqryLineas.IsEmpty then
    AMensaje := SErrorTarifasCambiosSesionSinLineas
  else if EsSesionPorPeriodos then
    AMensaje := ErrorVigenciasPeriodosTarifa(CargarVigenciasPeriodosTarifa(
      unqryTablaG.Connection as TUniConnection, SesionActual));
  if AMensaje = '' then
  begin
    SincronizarPeriodos;
    qryBusca := nil;
    qryExec := nil;
    qryLineas := nil;
    qryMarca := nil;
    qryUnico := nil;
    try
      qryBusca := TUniQuery.Create(nil);
      qryExec := TUniQuery.Create(nil);
      qryLineas := TUniQuery.Create(nil);
      qryMarca := TUniQuery.Create(nil);
      qryUnico := TUniQuery.Create(nil);
      oConexion := unqryTablaG.Connection as TUniConnection;
      qryBusca.Connection := oConexion;
      qryExec.Connection := oConexion;
      qryLineas.Connection := oConexion;
      qryMarca.Connection := oConexion;
      qryUnico.Connection := oConexion;
      ConfigurarConsultasAplicacion(qryBusca, qryMarca, qryUnico);
      qryLineas.SQL.Text := SQL_LINEAS_APLICAR;
      qryLineas.ParamByName('SESION').AsInteger := SesionActual;
      EsTransaccionPropia := not oConexion.InTransaction;
      HayEncoladoPrestaShop := False;
      TransaccionConfirmada := False;
      if EsTransaccionPropia then
        oConexion.StartTransaction;
      try
        BloquearSesionEditable(qryExec, SesionActual);
        qryLineas.Open;
        while not qryLineas.Eof do
        begin
          if AplicarLineaTarifa(qryLineas,
            qryBusca, qryExec, qryMarca, qryUnico,
            EncoloLineaPrestaShop) then
            Inc(Result);
          HayEncoladoPrestaShop :=
            HayEncoladoPrestaShop or EncoloLineaPrestaShop;
          qryLineas.Next;
        end;
        MarcarSesionAplicada(qryExec);
        MarcarPeriodosTarifaAplicados(oConexion, SesionActual,
          IdentidadSesion.Usuario);
        if EsTransaccionPropia then
        begin
          oConexion.Commit;
          TransaccionConfirmada := True;
        end;
      except
        on E: Exception do
        begin
          if EsTransaccionPropia and oConexion.InTransaction then
            oConexion.Rollback;
          if EsTransaccionPropia then
          begin
            AMensaje := E.Message;
            Result := 0;
          end
          else
            raise;
        end;
      end;
      if TransaccionConfirmada and HayEncoladoPrestaShop then
        SolicitarProcesadoPrestaShop;
      RefrescarTrasCambioPeriodos(IdPeriodoActual);
    finally
      FreeAndNil(qryUnico);
      FreeAndNil(qryMarca);
      FreeAndNil(qryLineas);
      FreeAndNil(qryExec);
      FreeAndNil(qryBusca);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmTarifasCambios);
  ForceReferenceToClass(TdmTarifasCambios);
end.
