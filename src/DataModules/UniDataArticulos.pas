{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulos                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de artículos.                                                 }
{    Queries de fza_articulos, tarifas, proveedores, variaciones, SKUs y stock.}
{******************************************************************************}
unit UniDataArticulos;

interface

uses
  inLibEtiquetasLotes,
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, cxListView, Vcl.Forms,
  Vcl.ComCtrls, Winapi.Windows, system.strUtils, cxGridDBTableView,
  cxCustomData, cxFilter,
  System.Variants, vcl.Controls, Datasnap.Provider, Datasnap.DBClient,
  System.Generics.Collections,
  frxClass, frxDBSet, frCoreClasses, System.UITypes,
  inLibPrestaShopColaIntf, inLibArticulosGuardadoIntf,
  inLibComprasSesionesCodigoArticulo;

type
  TDecisionDesactivacionWebArticulo = (
    ddwSoloDejarDeSincronizar,
    ddwDesactivarEnPrestaShop,
    ddwCancelar);

  TConfirmarDesactivacionWebArticuloEvent = function(
    const ACodigoArticulo, ADescripcionArticulo: string):
    TDecisionDesactivacionWebArticulo of object;

  ECodigoArticuloDuplicado = class(EDatabaseError);
  ECodigoBarrasRepetido = class(EDatabaseError);

  // FZ-ISSUE-172: código de barras que ya tiene otro SKU.
  TCodigoBarrasRepetido = record
    CodigoBarras: string;
    Sku: string;
    Articulo: string;
    Descripcion: string;
  end;
  // La pantalla avisa y decide si abre el artículo; el Post se aborta
  // siempre. Sin manejador (procesos sin pantalla) se lanza el error.
  TAvisarCodigoBarrasRepetido = reference to procedure(
    const AExistente: TCodigoBarrasRepetido);
  // FZ-ISSUE-307: código GS1 (fuera del rango interno 20-29) dado de alta
  // a mano. Solo se avisa: el Post sigue.
  TAvisarCodigoBarrasGs1 = reference to procedure(const ACodigo: string);

  TdmArticulos = class(TdmBase)
    unqryFamiliaArticulos: TUniQuery;
    dsFamiliaArticulos: TDataSource;
    unqryTarifasArticulos: TUniQuery;
    dsTarifasArticulos: TDataSource;
    unqryProveedoresArticulos: TUniQuery;
    dsProveedoresArticulos: TDataSource;
    unqryUltimasComprasProveedor: TUniQuery;
    dsUltimasComprasProveedor: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    unqryProveedores: TUniQuery;
    dsProveedores: TDataSource;
    unqryTiposIVA: TUniQuery;
    dsTiposIVA: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    unqryVariaciones: TUniQuery;
    dsVariaciones: TDataSource;
    unqryVariacionesArticulos: TUniQuery;
    dsVariacionesArticulos: TDataSource;
    unqrySkus: TUniQuery;
    dsSkus: TDataSource;
    unqryStockArticulos: TUniQuery;
    dsStockArticulos: TDataSource;
    unqryMovimientosArticulos: TUniQuery;
    dsMovimientosArticulos: TDataSource;
    unqryDetallesAtributos: TUniQuery;
    dsDetallesAtributos: TDataSource;
    unqryAtributosBasicosLookup: TUniQuery;
    dsAtributosBasicosLookup: TDataSource;
    unqryUnidadesMedidaLookup: TUniQuery;
    dsUnidadesMedidaLookup: TDataSource;
    unqryArtPrint: TUniQuery;
    dtstprvEtiquetasArt: TDataSetProvider;
    cdsEtiquetasArt: TClientDataSet;
    dsEtiquetasArt: TDataSource;
    fxdsEtiquetasArt: TfrxDBDataset;
    unqryAlmacenesPrint: TUniQuery;
    unqryTarifasPrint: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosAfterPost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforeDelete(DataSet: TDataSet);
    procedure unqryTarifasArticulosAfterDelete(DataSet: TDataSet);
    procedure unqryStockArticulosAfterScroll(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
    procedure unqryVariacionesArticulosNewRecord(DataSet: TDataSet);
    procedure unqryVariacionesArticulosAfterOpen(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
    procedure unqrySkusBeforePost(DataSet: TDataSet);
    procedure unqrySkusBeforeDelete(DataSet: TDataSet);
    procedure unqrySkusAfterPost(DataSet: TDataSet);
    procedure unqrySkusAfterDelete(DataSet: TDataSet);
    procedure unqryDetallesAtributosBeforePost(DataSet: TDataSet);
  private
    // Vista de stock del Mto de Articulos, empujada por el form via
    // AsignarVistaStock (el DM ya no la busca con GetOwnerForm).
    FAntesAbrirServicio: TDataSetNotifyEvent;
    FDespuesAbrirServicio: TDataSetNotifyEvent;
    FVistaStock: TcxGridDBTableView;
    FCodigoArticuloBorrado: string;
    FCodigoArticuloTarifaAnteriorPrestaShop: string;
    FCodigoArticuloTarifaBorrada: string;
    FCodigoArticuloSkuBorrado: string;
    FValoresFormulaAlta: TValoresFormulaCodigoArticuloSesion;
    FOnPrepararAlta: TNotifyEvent;
    FEncolarPrecioTarifaPrestaShop: Boolean;
    FPermitirCambiarMarcaWeb: Boolean;
    FAccionVisibilidadPendiente: TAccionVisibilidadPrestaShop;
    FAccionVisibilidadAplazada: TAccionVisibilidadPrestaShop;
    FAplazarVisibilidadPrestaShop: Boolean;
    FCambioMarcaWebPreparado: Boolean;
    FLimpiarColeccionesAlGrabar: Boolean;
    FCodigoArticuloCambioWebPreparado: string;
    FCodigoArticuloVisibilidadAplazada: string;
    FHayVisibilidadPrestaShopAplazada: Boolean;
    FMarcaWebAnteriorPreparada: Boolean;
    FMarcaWebNuevaPreparada: Boolean;
    FQuedaEnWebVisibilidadAplazada: Boolean;
    FOnConfirmarDesactivacionWeb:
      TConfirmarDesactivacionWebArticuloEvent;
    procedure AbrirMarcaReparacion(DataSet: TDataSet);
    procedure ActivarMarcaReparacion(DataSet: TDataSet);
    procedure FamiliaAltaCambiada(Sender: TField);
    procedure GuardarProveedorSolicitadoAlta;
    procedure AsegurarSkuBase(const ACodArt: string);
    function CodigoArticuloDuplicado(ADataSet: TDataSet): Boolean;
    function CampoTarifaArticuloPrestaShopCambiado(
      DataSet: TDataSet): Boolean;
    procedure CapturarOEncolarVisibilidadPrestaShop(
      const ACodigoArticulo: string;
      AAccion: TAccionVisibilidadPrestaShop);
    function CambioMarcaWebPreparadoCoincide(
      const ACodigoArticulo: string;
      AEstabaMarcado, AQuedaMarcado: Boolean): Boolean;
    function LeerCambioMarcaWeb(
      out ACodigoArticulo, ADescripcionArticulo: string;
      out AEstabaMarcado, AQuedaMarcado: Boolean): Boolean;
    function EsTarifaPrestaShop(
      AConexion: TUniConnection;
      const ACodigoActual, ACodigoAnterior: string): Boolean;
    procedure PrepararAccionCambioMarcaWeb(
      const ACodigoArticulo, ADescripcionArticulo: string;
      AEstabaMarcado, AQuedaMarcado: Boolean);
    procedure ValidarCambioMarcaWeb(ADataSet: TDataSet);
    procedure QuitarEscribiblesVista;
    procedure ActualizarSkuActivo(const aSku, aActivo: string);
    procedure UpsertCosteSku(const aSku: string;
                             aPrecioField, aFechaField: TField);
    procedure EliminarCosteSku(const aSku: string);
    procedure ReconstruirColumnasStock(AVista: TcxGridDBTableView);
    procedure AplicarAnchosColumnasStock(AVista: TcxGridDBTableView);
    procedure AplicarDecimalesStock;
    procedure ConfigurarFiltroStock(AVista: TcxGridDBTableView);
    function PrepararClaveTarifa: Integer;
    procedure AplicarEstadoTarifaPorPrecio;
    procedure ValidarPeriodoTarifa(APk: Integer);
    procedure SanearDescuentoTarifa;
    procedure ValidarCompraTarifa;
    procedure IncorporarProveedorTarifa;

  public
    procedure PoblarCdsEtiquetasArtDesdeUniQuery;
    procedure ExpandirEtiquetasPorStock(const aFldStock: string);
    // Activa ('S') o desactiva ('N') en bloque todos los SKU del articulo que
    // comparten un mismo color (atributo 'CO'). La llama la ficha SKU desde el
    // menu/boton de color. Devuelve cuantos SKU forman el grupo de color.
    function ActualizarSkusColorActivo(const aCodArt, aColor,
                                       aActivo: string): Integer;
    // Tras generar SKU: recarga las fichas de SKU y de variaciones y deja
    // la primera sobre el primero de los recién creados.
    procedure RecargarSkusGenerados(const ASkusCreados: TArray<string>);
    // Override: abre las queries detalle y lookups del Mto de Articulos
    // (tarifas, proveedores, lineas-factura, variaciones, skus, stock,
    // movimientos, atributos basicos, ivas, familias). Lo invoca
    // TfrmMtoGen.AbrirTablaPrincipalAsync DENTRO del thread del Open de
    // unqryTablaG. Antes de este refactor los Opens vivian en
    // DataModuleCreate y bloqueaban la UI 17-21 segundos al abrir el tab.
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm. El
    // TdmArticulos temporal del boton 'Pegatinas' nunca recibe estas
    // llamadas, igual que antes el GetOwnerForm le devolvia nil.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AsignarVistaStock(AVista: TcxGridDBTableView);
    procedure AsignarPermisoCambioMarcaWeb(APermitido: Boolean);
    procedure AsignarConfirmacionDesactivacionWeb(
      AConfirmacion: TConfirmarDesactivacionWebArticuloEvent);
    procedure IniciarAplazamientoVisibilidadPrestaShop;
    procedure ConfirmarVisibilidadPrestaShopAplazada;
    procedure FinalizarVisibilidadPrestaShopAplazada(
      AExito: Boolean;
      const AMensajeError: string);
    procedure DescartarVisibilidadPrestaShopAplazada;
    procedure PrepararCambioMarcaWeb;
    procedure LimpiarCambioMarcaWebPreparado;
    procedure AbrirDetalles; override;
    procedure CargarUltimasComprasProveedor;
    // En main thread tras AbrirDetalles: reactiva los TDataSource que
    // se desactivaron durante el thread y dispara manualmente el
    // AfterScroll del stock (que tambien se silencio).
    procedure ReactivarControlesTrasAbrir; override;
    // Carga perezosa de tarifas. La vista vi_articulos_tarifas tarda
    // ~6 segundos en abrir por culpa de subqueries DEPENDENT y un
    // DERIVED full-scan. La quitamos de AbrirDetalles y la abrimos
    // solo cuando el usuario hace click en la sub-pestaña Tarifas
    // (ver TfrmMtoArticulos.PcDetailChange).
    procedure AsegurarTarifasAbiertas;
    procedure PrepararCodigosEtiquetasLotes(var ALotes: TLotesEtiquetas);
    function FormulaCodigoArticulo: string;
    procedure AsignarDatosCodigoAlta(const AModelo, AProveedor: string);
    procedure ValidarProveedorCodigoAlta(const ACodigoProveedor: string);
    property OnPrepararAlta: TNotifyEvent
      read FOnPrepararAlta write FOnPrepararAlta;
    procedure GetCodigoAutoArticulo;
    procedure ValidarCodigoArticuloDisponible;
    procedure ValidarDatosArticulo;
    // F-LOTEC-011: modo de trazabilidad del artículo.
    function HayStockConLote(const ACodigoArticulo: string): Boolean;
    procedure PrepararTrazabilidadArticulo;
    function HaySkusConVariacion(const ACodigoArticulo: string): Boolean;
    procedure PrepararCambioTipoVariacion;
    procedure LimpiarColeccionesArticulo(const ACodigoArticulo: string);
    procedure ProponerTrazabilidadAlta;
  public
    // FZ-ISSUE-172.
    OnCodigoBarrasRepetido: TAvisarCodigoBarrasRepetido;
    OnCodigoBarrasGs1: TAvisarCodigoBarrasGs1;
    OnValidacionDatosArticulo: TNotificarValidacionArticulo;
    function CodigoArticuloExiste(const ACodigo: string): Boolean;
    // Siguiente código libre para un código repetido: si acaba en cifras,
    // las siguientes con el mismo prefijo y ancho; si no, el que daría el
    // contador 'AR' sin consumirlo. '' si no encuentra ninguno.
    function ProponerCodigoArticuloLibre(const ACodigo: string): string;
    function BuscarCodigoBarrasRepetido(const ACodigoBarras: string;
      AIdExcluido: Integer; out AExistente: TCodigoBarrasRepetido): Boolean;
    procedure GuardarArticulo;
    function ArticuloTieneProvPrin(const AArticulo: string;
      const AProveedorExcluido: string = ''): Boolean;
    procedure CopiarProveedoraArticulo(dtProveedores:TDataset);
    procedure FillTarifas(lst:TcxListView);
    function ReconstruirStock: string;
    function ObtenerPrecioTarifaPadre(const aCodArt,
                                            aCodTarifa: string): Double;
    // El modal de etiquetas se nutre de estas tres rutinas: dos para
    // poblar tarifa y almacenes, y la tercera para construir el dataset
    // que consume el FastReport.
    procedure CargarTarifasEtiquetas(items: TStrings; codigos: TStrings;
                                     var aIdxDefault: Integer);
    procedure CargarAlmacenesEtiquetas(lst: TcxListView);
    procedure CrearDataSetEtiquetasArt(const aCodigoArt,
                                             aCodTarifa,
                                             aAlmacenesCsv: string;
                                             aFechaTarifa: TDateTime;
                                             const aSkusCsv: string = '');
  end;

implementation

uses
  UniDataArticulosPropiedadesRepositorio,
  UniDataReparacionesArticuloServicio, inLibMsgReparaciones,
  UniDataCodigosBarrasLote,
  inLibArticulosGuardado,
  inLibMsgCompras,
  inLibTrazabilidadAlta, UniDataFamilias,
  UniDataTarifasPrecioSql, UniDataPrecioUnidad,
  UniDataTarifasPeriodicidadRepositorio, inLibTarifasPeriodicidad,

  System.Diagnostics,
  UniDataAperturaConsultas,
  inLibCadenas, inLibDatasets,
  inLibLogIntf,
  inLibPrestaShopColaSenal,
  UniDataPrestaShopEncolado,
  UniDataValoresAutomaticosRepositorio,
  inLibCodigosSinBarra,
  inLibMsgArticulos, inLibErroresBBDD,
  inLibTraspasosPendientesTexto,
  inLibTrazabilidad, inLibMsgTrazabilidad, inLibEAN13,
  UniDataStockConsultaRepositorio, inLibStockConsultaPersistenciaIntf;

const
  // FZ-ISSUE-444: SKU con variacion (el SKU base lleva el codigo del
  // articulo) y colecciones asignadas a los ejes del articulo.
  SQL_SKUS_CON_VARIACION_ARTICULO =
    'SELECT 1 AS HAY FROM fza_articulos_skus ' +
    'WHERE CODIGO_ART_SKU = :art AND CODIGO_UNIDAD_SKU <> :art LIMIT 1';
  SQL_BORRAR_COLECCIONES_ARTICULO =
    'DELETE FROM fza_articulos_conjuntos_asign ' +
    'WHERE CODIGO_ART_ACA = :art';
  // F-LOTEC-011: filas de stock por lote o serie de cualquier SKU.
  SQL_STOCK_CON_LOTE_ARTICULO =
    'SELECT 1 AS HAY FROM fza_articulos_stockactual s ' +
    'JOIN fza_articulos_skus k ' +
    'ON k.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK ' +
    'WHERE k.CODIGO_ART_SKU = :art AND s.LOTE_STK <> '''' ' +
    'AND s.CANTIDAD_STK <> 0 LIMIT 1';

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

resourcestring
  SErrorBorrarSkuArticuloWeb =
    'No se puede borrar un SKU de un artículo En web. ' +
    'Desmarque Activo para enviar stock cero a PrestaShop';

const
  SQL_INCORPORAR_PROVEEDOR_TARIFA =
    'INSERT INTO fza_articulos_proveedores ' +
    '(CODIGO_ART_AP, CODIGO_PRV_AP, ESPROVEEDORPRINCIPAL_AP, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ARTICULO, P.CODIGO_PRV_PRV, ' +
    'CASE WHEN EXISTS (SELECT 1 FROM fza_articulos_proveedores AP ' +
    'WHERE AP.CODIGO_ART_AP = :ARTICULO) THEN ''N'' ELSE ''S'' END, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO FROM fza_proveedores P ' +
    'WHERE P.CODIGO_PRV_PRV = :PROVEEDOR ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_articulos_proveedores AP ' +
    'WHERE AP.CODIGO_ART_AP = :ARTICULO ' +
    'AND AP.CODIGO_PRV_AP = P.CODIGO_PRV_PRV) ' +
    'ON DUPLICATE KEY UPDATE CODIGO_PRV_AP = VALUES(CODIGO_PRV_AP)';
  SQL_ULTIMAS_COMPRAS_PROVEEDOR =
    'SELECT C.CODIGO_PRV_ARTTAR, C.RAZON_SOCIAL_PRV, ' +
    'C.CODIGO_UNIDAD_ARTTAR, C.PRECIO_COSTE_ARTTAR, ' +
    'C.FECHA_ULT_COMPRA_ARTTAR FROM (' +
    'SELECT T.CODIGO_PRV_ARTTAR, P.RAZON_SOCIAL_PRV, ' +
    'S.CODIGO_UNIDAD_SKU AS CODIGO_UNIDAD_ARTTAR, ' +
    'T.PRECIO_COSTE_ARTTAR, T.FECHA_ULT_COMPRA_ARTTAR, ' +
    'ROW_NUMBER() OVER (PARTITION BY T.CODIGO_PRV_ARTTAR, ' +
    'S.CODIGO_UNIDAD_SKU ' +
    'ORDER BY T.FECHA_ULT_COMPRA_ARTTAR DESC, ' +
    'T.INSTANTE_MODIF DESC, T.CODIGO_UNICO_ARTTAR DESC) AS ORDEN_COMPRA ' +
    'FROM fza_articulos_tarifas T ' +
    'JOIN fza_articulos_skus S ON S.CODIGO_ART_SKU = T.CODIGO_ART_ARTTAR ' +
    'AND (COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'OR T.CODIGO_UNIDAD_ARTTAR = S.CODIGO_UNIDAD_SKU ' +
    'OR (COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') <> '''' ' +
    'AND LOCATE(''/*/'', T.CODIGO_UNIDAD_ARTTAR) = 0 ' +
    'AND LEFT(S.CODIGO_UNIDAD_SKU, ' +
    'CHAR_LENGTH(T.CODIGO_UNIDAD_ARTTAR) + 1) ' +
    '= CONCAT(T.CODIGO_UNIDAD_ARTTAR, ''/'')) ' +
    'OR EXISTS (SELECT 1 FROM fza_atributos_sku ATS ' +
    'JOIN fza_atributos_valores TAL ON TAL.ID_AV = ATS.ID_AV_SA ' +
    'AND TAL.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'S.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
    'WHERE ATS.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU ' +
    'AND T.CODIGO_UNIDAD_ARTTAR = ' +
    'CONCAT(T.CODIGO_ART_ARTTAR, ''/*/'', TAL.AV))) ' +
    'LEFT JOIN fza_proveedores P ' +
    'ON P.CODIGO_PRV_PRV = T.CODIGO_PRV_ARTTAR ' +
    'WHERE T.CODIGO_ART_ARTTAR = :ARTICULO ' +
    'AND COALESCE(T.CODIGO_PRV_ARTTAR, '''') <> '''' ' +
    'AND T.PRECIO_COSTE_ARTTAR IS NOT NULL) C ' +
    'WHERE C.ORDEN_COMPRA = 1 ' +
    'ORDER BY C.CODIGO_PRV_ARTTAR, C.CODIGO_UNIDAD_ARTTAR';
  // FZ-ISSUE-426: la compra no escribe en la tarifa; el panel une a los
  // costes tecleados en las tarifas el último albarán de compra de cada
  // proveedor y SKU (neto de descuento comercial y sin impuestos).
  SQL_ULTIMAS_COMPRAS_ALBARAN =
    'SELECT A.CODIGO_PRV_ALBC AS CODIGO_PRV_ARTTAR, P.RAZON_SOCIAL_PRV, ' +
    'L.CODIGO_UNIDAD_ALBCLIN AS CODIGO_UNIDAD_ARTTAR, ' +
    'CAST((L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '(1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100)) * ' +
    'CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
    'GREATEST(0, 1 - CASE ' +
    'WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 ' +
    'THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / A.TOTAL_BRUTO_ALBC ' +
    'ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100 END) ' +
    'ELSE GREATEST(0, 1 - ' +
    'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) END ' +
    'AS DECIMAL(19,6)) AS PRECIO_COSTE_ARTTAR, ' +
    'A.FECHA_ALBC AS FECHA_ULT_COMPRA_ARTTAR, 0 AS ORIGEN, ' +
    'CONCAT(A.SERIE_ALBC, ''/'', A.NUMERO_ALBC, ''/'', L.LINEA_ALBCLIN) ' +
    'AS DESEMPATE ' +
    'FROM fza_albaranes_compra_lineas L ' +
    'JOIN fza_albaranes_compra A ON A.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
    'AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
    'LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = A.CODIGO_PRV_ALBC ' +
    'WHERE L.CODIGO_ART_ALBCLIN = :ARTICULO ' +
    'AND COALESCE(A.CODIGO_PRV_ALBC, '''') <> '''' ' +
    'AND COALESCE(TRIM(L.CODIGO_UNIDAD_ALBCLIN), '''') <> '''' ' +
    'AND IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
    'AND IFNULL((L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '(1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100)), 0) > 0';
  SQL_ULTIMO_COSTE_PROVEEDOR_INI =
    'SELECT C.CODIGO_PRV_ARTTAR, C.RAZON_SOCIAL_PRV, ' +
    'C.CODIGO_UNIDAD_ARTTAR, C.PRECIO_COSTE_ARTTAR, ' +
    'C.FECHA_ULT_COMPRA_ARTTAR FROM (' +
    'SELECT U.*, ROW_NUMBER() OVER (PARTITION BY U.CODIGO_PRV_ARTTAR, ' +
    'U.CODIGO_UNIDAD_ARTTAR ORDER BY U.FECHA_ULT_COMPRA_ARTTAR DESC, ' +
    'U.ORIGEN, U.DESEMPATE DESC) AS ORDEN_FINAL FROM (' +
    'SELECT T.*, 1 AS ORIGEN, '''' AS DESEMPATE FROM (';
  SQL_ULTIMO_COSTE_PROVEEDOR_MED =
    ') T UNION ALL ';
  SQL_ULTIMO_COSTE_PROVEEDOR_FIN =
    ') U) C WHERE C.ORDEN_FINAL = 1 ' +
    'ORDER BY C.CODIGO_PRV_ARTTAR, C.CODIGO_UNIDAD_ARTTAR';
  // Construimos manualmente la lista IN (...) con los codigos elegidos.
  // Los codigos vienen de fza_almacenes (validados al cargar el checklist),
  // asi que no llegan de entrada de usuario libre.
  cSqlDescuentoVigenteEtiquetas =
    '((tar.FECHA_DESDE_DTO_TAR IS NULL OR ' +
    'tar.FECHA_DESDE_DTO_TAR <= :FECHA_APLICACION) AND ' +
    '(tar.FECHA_HASTA_DTO_TAR IS NULL OR ' +
    'tar.FECHA_HASTA_DTO_TAR = ''0000-00-00'' OR ' +
    'tar.FECHA_HASTA_DTO_TAR >= :FECHA_APLICACION))';
  cSqlEtiquetasArt =
    'SELECT eti.*, art.TIPO_CANTIDAD_ART, ' +
    '       {CAMPOS_PRECIO_UNIDAD} ' +
    '       prc.PRECIO_SALIDA_ARTTAR, ' +
    '       CASE WHEN {DESCUENTO_VIGENTE} ' +
    '            THEN prc.PRECIO_FINAL_ARTTAR ' +
    '            ELSE prc.PRECIO_SALIDA_ARTTAR END ' +
    '         AS PRECIO_FINAL_ARTTAR, ' +
    '       CASE WHEN {DESCUENTO_VIGENTE} ' +
    '            THEN prc.PRECIO_DTO_ARTTAR ELSE 0 END ' +
    '         AS PRECIO_DTO_ARTTAR, ' +
    '       CASE WHEN {DESCUENTO_VIGENTE} ' +
    '            THEN prc.PORCENTAJE_DTO_ARTTAR ELSE 0 END ' +
    '         AS PORCENTAJE_DTO_ARTTAR, ' +
    '       CASE WHEN COALESCE(prc.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '            THEN ''PADRE'' ELSE ''ESPECIFICO_SKU'' END ' +
    '         AS ORIGEN_PRECIO,' +
    '       :CODIGO_TAR_ARTTAR AS CODIGO_TAR_ARTTAR,'                         +
    '       tar.NOMBRE_TAR_TAR     AS NOMBRE_TAR_TAR,'                        +
    '       tar.ESIMP_INCL_TAR     AS ESIMP_INCL_TAR,'                        +
    '       :FECHA_APLICACION      AS FECHA_APLICACION,'                      +
    '       COALESCE(stk.STOCK_FILTRADO, 0) AS STOCK_FILTRADO,'               +
    // F-LOTEC-022: lote y caducidad de la etiqueta (por lote o unidad).
    '       CAST('''' AS CHAR(50)) AS LOTE_ETI,'                              +
    '       CAST('''' AS CHAR(10)) AS CADUCIDAD_ETI,'                         +
    // FZ-ISSUE-603: «Lote L1 cad. 24/10/26», «S/N …» o la temporada.
    '       CAST('''' AS CHAR(80)) AS TEXTO_LOTE_ETI'                         +
    '  FROM vi_articulos_skus_etiquetas eti ' +
    '  JOIN fza_articulos art ON art.CODIGO_ART_ART = eti.CODIGO_ART_ART ' +
    '  LEFT JOIN fza_tarifas tar'                                             +
    '    ON tar.CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR'                       +
    '  LEFT JOIN fza_articulos_tarifas prc'                                   +
    '    ON prc.CODIGO_UNICO_ARTTAR = ({PRECIO_TARIFA}) ' +
    '  LEFT JOIN ('                                                           +
    '       SELECT CODIGO_UNIDAD_STK,'                                        +
    '              SUM(CANTIDAD_STK) AS STOCK_FILTRADO'                       +
    '         FROM fza_articulos_stockactual'                                 +
    '        %ALMACEN_FILTER%'                                                +
    '        GROUP BY CODIGO_UNIDAD_STK'                                      +
    '       ) stk'                                                            +
    '    ON stk.CODIGO_UNIDAD_STK = eti.CODIGO_UNIDAD_SKU'                    +
    ' WHERE (:CODIGO_ART_ART = ''''  OR eti.CODIGO_ART_ART = :CODIGO_ART_ART)'+
    '   %SKU_FILTER%'                                                         +
    '   AND eti.ESACTIVO_SKU = ''S'''                                         +
    '   AND eti.ESACTIVO_ART = ''S'''                                         +
    // Tallas por la guia (orden del articulo, del sistema de tallas
    // asignado o del valor), no alfabeticas (FZ-ISSUE-101).
    ' ORDER BY eti.CODIGO_ART_ART, eti.ATR_CO, ' +
    '   COALESCE((SELECT MIN(COALESCE(aab.ORDEN_AAB, acd.ORDEN_ACD, ' +
    '                                 av.ORDEN_AV)) ' +
    '               FROM fza_atributos_sku sa ' +
    '               JOIN fza_atributos_valores av ' +
    '                 ON av.ID_AV = sa.ID_AV_SA ' +
    '                AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
    'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    '(SELECT AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 ' +
    'WHERE AR452.CODIGO_ART_ART = eti.CODIGO_ART_ART) AND ' +
    'EJ452.EJE_VA = ''P'') ' +
    '               LEFT JOIN fza_articulos_atributos_basicos aab ' +
    '                 ON aab.CODIGO_ART_AAB = eti.CODIGO_ART_ART ' +
    '                AND aab.ID_AV_AAB = av.ID_AV ' +
    '               LEFT JOIN fza_articulos_conjuntos_asign aca ' +
    '                 ON aca.CODIGO_ART_ACA = eti.CODIGO_ART_ART ' +
    '                AND aca.ID_VA_ACA = av.ID_VA_AV ' +
    '               LEFT JOIN fza_atributos_conjuntos_det acd ' +
    '                 ON acd.ID_AC_ACD = aca.ID_AC_ACA ' +
    '                AND acd.ID_AV_ACD = av.ID_AV ' +
    '              WHERE sa.CODIGO_UNIDAD_SKU_SA = eti.CODIGO_UNIDAD_SKU), ' +
    '            2147483647), ' +
    '   eti.CODIGO_UNIDAD_SKU';
  cSqlHexEtiquetas =
    'SELECT sa.CODIGO_UNIDAD_SKU_SA AS CODIGO_UNIDAD_SKU,' +
    '       atb.HEX_ATB             AS HEX_ATR_CO,' +
    '       atb.NOMBRE_ATB          AS NOMBRE_ATB_CO,' +
    '       COALESCE(NULLIF(atb.DESCRIPCION_ATB, ''''),' +
    '                atb.NOMBRE_ATB) AS DESCRIPCION_ATB_CO ' +
    '  FROM fza_atributos_sku sa' +
    '  JOIN fza_articulos_skus sk' +
    '    ON sk.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA' +
    '  JOIN fza_atributos_valores av' +
    '    ON av.ID_AV     = sa.ID_AV_SA' +
    '   AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')' +
    '  JOIN fza_articulos_atributos_basicos aab' +
    '    ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU' +
    '   AND aab.ID_AV_AAB     = av.ID_AV' +
    '  JOIN fza_atributos_basicos atb' +
    '    ON atb.ID_ATB = aab.ID_ATB_AAB';

function TipoSeguroCdsEtiquetas(ATipo: TFieldType): TFieldType;
begin
  case ATipo of
    ftString, ftFixedChar:
      Result := ftString;
    ftWideString, ftFixedWideChar:
      Result := ftWideString;
    ftBoolean:
      Result := ftBoolean;
    ftShortint, ftByte, ftSmallint:
      Result := ftSmallint;
    ftWord, ftInteger, ftAutoInc:
      Result := ftInteger;
    ftLongWord, ftLargeint:
      Result := ftLargeint;
    ftSingle, ftFloat, ftExtended:
      Result := ftFloat;
    ftCurrency:
      Result := ftCurrency;
    ftBCD, ftFMTBcd:
      Result := ftFMTBcd;
    ftDate:
      Result := ftDate;
    ftTime:
      Result := ftTime;
    ftDateTime, ftTimeStamp, ftTimeStampOffset:
      Result := ftDateTime;
    ftMemo, ftWideMemo, ftFmtMemo:
      Result := ftWideString;
    ftBlob, ftGraphic, ftBytes, ftVarBytes:
      Result := ftBlob;
    ftGuid:
      Result := ftGuid;
  else
    Result := ftWideString;
  end;
end;

type
  // Color basico del SKU (fza_atributos_basicos) para las etiquetas: el
  // salto SKU -> valor -> basico del articulo no se puede hacer con una
  // guia de impresion, asi que lo anyadimos aqui junto al HEX.
  TColorBasicoEtiqueta = record
    Hex: string;
    Nombre: string;
    Descripcion: string;
  end;

const
  cCamposColorBasicoEtiquetas: array[0..2] of string =
    ('HEX_ATR_CO', 'NOMBRE_ATB_CO', 'DESCRIPCION_ATB_CO');
  cTamanyosColorBasicoEtiquetas: array[0..2] of Integer = (7, 100, 255);

function CargarMapaHexEtiquetas(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog
): TDictionary<string, TColorBasicoEtiqueta>;
var
  oConsulta: TUniQuery;
  sCodigoSku: string;
  rColor: TColorBasicoEtiqueta;
begin
  Result := TDictionary<string, TColorBasicoEtiqueta>.Create;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := cSqlHexEtiquetas;
    try
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        sCodigoSku := oConsulta.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString;
        if sCodigoSku <> '' then
        begin
          rColor.Hex := oConsulta.FieldByName('HEX_ATR_CO').AsString;
          rColor.Nombre := oConsulta.FieldByName('NOMBRE_ATB_CO').AsString;
          rColor.Descripcion :=
            oConsulta.FieldByName('DESCRIPCION_ATB_CO').AsString;
          Result.AddOrSetValue(sCodigoSku, rColor);
        end;
        oConsulta.Next;
      end;
      oConsulta.Close;
    except
      on E: Exception do
      begin
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarAviso(
            'EtiquetasArt: mapa de colores HEX no disponible: ' +
            E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure CopiarFilasEtiquetas(
  AOrigen: TDataSet;
  ADestino: TClientDataSet;
  AIndiceCodigoSku: Integer;
  AMapaHex: TDictionary<string, TColorBasicoEtiqueta>);
var
  i: Integer;
  sCodigoSku: string;
  rColor: TColorBasicoEtiqueta;
begin
  if AOrigen.Active and not AOrigen.IsEmpty then
  begin
    ADestino.DisableControls;
    try
      AOrigen.First;
      while not AOrigen.Eof do
      begin
        ADestino.Append;
        for i := 0 to AOrigen.FieldCount - 1 do
          ADestino.Fields[i].Value := AOrigen.Fields[i].Value;
        if AIndiceCodigoSku >= 0 then
        begin
          sCodigoSku := AOrigen.Fields[AIndiceCodigoSku].AsString;
          if (sCodigoSku <> '') and
             AMapaHex.TryGetValue(sCodigoSku, rColor) then
          begin
            ADestino.FieldByName('HEX_ATR_CO').AsString := rColor.Hex;
            ADestino.FieldByName('NOMBRE_ATB_CO').AsString := rColor.Nombre;
            ADestino.FieldByName('DESCRIPCION_ATB_CO').AsString :=
              rColor.Descripcion;
          end;
        end;
        ADestino.Post;
        AOrigen.Next;
      end;
    finally
      ADestino.EnableControls;
    end;
  end;
end;

function TdmArticulos.ArticuloTieneProvPrin(const AArticulo: string;
  const AProveedorExcluido: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := unqryProveedoresArticulos.Connection;
    Consulta.SQL.Text :=
      'SELECT 1 FROM fza_articulos_proveedores ' +
      'WHERE CODIGO_ART_AP = :ARTICULO ' +
      'AND ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
      'AND CODIGO_PRV_AP <> :EXCLUIDO LIMIT 1';
    Consulta.ParamByName('ARTICULO').AsString := AArticulo;
    Consulta.ParamByName('EXCLUIDO').AsString := AProveedorExcluido;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    Consulta.Free;
  end;
end;

procedure TdmArticulos.ActualizarSkuActivo(const aSku, aActivo: string);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_articulos_skus '   +
      '   SET ESACTIVO_SKU = :ACT, ' +
      '       USUARIO_MODIF = :USR ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    qry.ParamByName('ACT').AsString := aActivo;
    qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
    qry.ParamByName('SKU').AsString := aSku;
    qry.ExecSQL;
    EncolarCambioPrestaShop(
      qry.Connection,
      '',
      aSku,
      True,
      True,
      IdentidadSesion.Usuario);
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.RecargarSkusGenerados(
  const ASkusCreados: TArray<string>);
begin
  unqrySkus.Close;
  unqrySkus.Open;
  unqryVariacionesArticulos.Close;
  unqryVariacionesArticulos.Open;
  if Length(ASkusCreados) > 0 then
    unqrySkus.Locate('CODIGO_UNIDAD_SKU', ASkusCreados[0], []);
end;

function TdmArticulos.ActualizarSkusColorActivo(const aCodArt, aColor,
  aActivo: string): Integer;
// Activa ('S') o desactiva ('N') en bloque todos los SKU del articulo cuyo
// color (atributo 'CO' resuelto por vi_atributos_sku_basico) coincide con
// aColor. Se hace en DOS pasos -- SELECT de los codigos de SKU + UPDATE por
// codigo -- y no en una sola sentencia con subconsulta, porque la vista lee de
// fza_articulos_skus y no se puede leer+actualizar la misma tabla a la vez
// (error 1093 de MariaDB; el truco de la tabla derivada no es fiable con
// derived_merge). Devuelve cuantos SKU forman el grupo de color.
var
  qrySel, qryUpd: TUniQuery;
begin
  Result := 0;
  qrySel := TUniQuery.Create(nil);
  qryUpd := TUniQuery.Create(nil);
  try
    qrySel.Connection := ConexionPrincipal;
    qrySel.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_SKU '                                  +
      '  FROM vi_atributos_sku_basico '                                     +
      ' WHERE CODIGO_ART_SKU = :ART '                                       +
      '   AND ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
      'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
      'AR452.CODIGO_ART_ART = :ART) AND EJ452.EJE_VA = ''F'') ' +
      '   AND VALOR_AV       = :COLOR';
    qrySel.ParamByName('ART').AsString   := aCodArt;
    qrySel.ParamByName('COLOR').AsString := aColor;
    qrySel.Open;
    qryUpd.Connection := ConexionPrincipal;
    qryUpd.SQL.Text :=
      'UPDATE fza_articulos_skus '   +
      '   SET ESACTIVO_SKU  = :ACT, '+
      '       USUARIO_MODIF = :USR ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    while not qrySel.Eof do
    begin
      qryUpd.ParamByName('ACT').AsString := aActivo;
      qryUpd.ParamByName('USR').AsString := IdentidadSesion.Usuario;
      qryUpd.ParamByName('SKU').AsString :=
        qrySel.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      qryUpd.ExecSQL;
      Inc(Result);
      qrySel.Next;
    end;
    if Result > 0 then
      EncolarArticuloPrestaShop(
        qryUpd.Connection,
        aCodArt,
        IdentidadSesion.Usuario);
  finally
    FreeAndNil(qryUpd);
    FreeAndNil(qrySel);
  end;
end;

procedure TdmArticulos.unqryVariacionesArticulosAfterOpen(
  DataSet: TDataSet);
begin
  // El stock es un agregado de consulta, ajeno al alta del código de barras.
  DataSet.FieldByName('STOCK_TOTAL').Required := False;
  DataSet.FieldByName('STOCK_TOTAL').ReadOnly := True;
end;

procedure TdmArticulos.unqryVariacionesArticulosNewRecord(
  DataSet: TDataSet);
begin
  DataSet.FieldByName('TIPO_CODIGO_CB').AsString := 'EAN13';
  DataSet.FieldByName('ESPRINCIPAL_CB').AsString := 'N';
  if unqrySkus.Active and not unqrySkus.IsEmpty then
    DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString :=
      unqrySkus.FieldByName('CODIGO_UNIDAD_SKU').AsString;
end;

procedure TdmArticulos.unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
var
  fldCB, fldAct, fldSku: TField;
  sSku: string;
  bChangedActivo: Boolean;
  ConsultaSku: TUniQuery;
begin
  inherited;

  // La vista contiene columnas obligatorias del SKU que no se insertan
  // en códigos de barras. Resolverlas para la unidad elegida.
  if DataSet.State = dsInsert then
  begin
    ConsultaSku := TUniQuery.Create(nil);
    try
      ConsultaSku.Connection := unqryVariacionesArticulos.Connection;
      ConsultaSku.SQL.Text :=
        'SELECT CODIGO_VAR_SKU, ESACTIVO_SKU FROM fza_articulos_skus ' +
        'WHERE CODIGO_UNIDAD_SKU = :SKU AND CODIGO_ART_SKU = :ART';
      ConsultaSku.ParamByName('SKU').AsString :=
        DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      ConsultaSku.ParamByName('ART').AsString :=
        unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
      ConsultaSku.Open;
      if ConsultaSku.IsEmpty then
        raise EValidacionBBDD.Create(SErrorCodigoSkuCodigoBarrasObligatorio);
      DataSet.FieldByName('CODIGO_VAR_SKU').AsString :=
        ConsultaSku.FieldByName('CODIGO_VAR_SKU').AsString;
      DataSet.FieldByName('ESACTIVO_SKU').AsString :=
        ConsultaSku.FieldByName('ESACTIVO_SKU').AsString;
    finally
      ConsultaSku.Free;
    end;
  end;
  fldCB  := DataSet.FindField('CODIGO_BARRAS_CB');
  fldAct := DataSet.FindField('ESACTIVO_SKU');
  fldSku := DataSet.FindField('CODIGO_UNIDAD_SKU');
  if (fldCB <> nil) and not fldCB.ReadOnly then
    fldCB.AsString := Trim(fldCB.AsString);
  // FZ-ISSUE-172: un código de barras no puede tenerlo otro SKU. Se
  // comprueba antes de grabar nada de la fila.
  if (fldCB <> nil) and (Trim(fldCB.AsString) <> '') and
     ((DataSet.State = dsInsert) or
      (VarToStr(fldCB.OldValue) <> fldCB.AsString)) then
  begin
    var fldId := DataSet.FindField('ID_CB');
    var iId := 0;
    if (fldId <> nil) and not fldId.IsNull then
      iId := fldId.AsInteger;
    var oExistente: TCodigoBarrasRepetido;
    if BuscarCodigoBarrasRepetido(fldCB.AsString, iId, oExistente) then
    begin
      if not Assigned(OnCodigoBarrasRepetido) then
        raise ECodigoBarrasRepetido.CreateFmt(SErrorCodigoBarrasRepetido,
          [oExistente.CodigoBarras, oExistente.Sku, oExistente.Articulo,
           oExistente.Descripcion]);
      OnCodigoBarrasRepetido(oExistente);
      Abort;
    end;
    // FZ-ISSUE-307: los GTIN de GS1 han de solicitarse; los internos que
    // genera ViraCash (21...) no avisan
    if Assigned(OnCodigoBarrasGs1) and EsCodigoGs1Asignado(fldCB.AsString) then
      OnCodigoBarrasGs1(fldCB.AsString);
  end;
  if fldSku <> nil then
  begin
    sSku := fldSku.AsString;
    if DataSet.State = dsInsert then
    begin
      if Trim(sSku) = '' then
        raise ERangeError.Create(SErrorCodigoSkuCodigoBarrasObligatorio);
      if fldCB = nil then
        raise ERangeError.Create(SErrorCampoCodigoBarrasAusente);
      ActualizarAuditoria(DataSet);
    end
    else if DataSet.State = dsEdit then
    begin
      ActualizarAuditoria(DataSet);
      bChangedActivo := (fldAct <> nil) and
        (VarToStr(fldAct.OldValue) <> fldAct.AsString);
      // ESACTIVO_SKU pertenece a fza_articulos_skus.
      if bChangedActivo then
        ActualizarSkuActivo(sSku, fldAct.AsString);
    end;
  end;
end;

procedure TdmArticulos.unqrySkusBeforePost(DataSet: TDataSet);
var
  fldPrecio, fldFecha: TField;
begin
  inherited;
  if DataSet.State = dsInsert then
  begin
    if Trim(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString) = '' then
      raise ERangeError.Create(SErrorCodigoSkuObligatorio);
    // Article code se hereda del master/detail, pero por seguridad lo
    // forzamos al artículo activo si está vacío.
    if Trim(DataSet.FieldByName('CODIGO_ART_SKU').AsString) = '' then
      DataSet.FieldByName('CODIGO_ART_SKU').AsString :=
                              unqryTablaG.FieldByName(
                                'CODIGO_ART_ART').AsString;
  end;
  ActualizarAuditoria(DataSet);

  // El SQLInsert / SQLUpdate del framework sólo escribe en fza_articulos_skus.
  // El coste y la fecha de última compra viven en fza_articulos_skus_costes:
  // los volcamos aquí mediante UPSERT.
  fldPrecio := DataSet.FindField('PRECIO_ULT_COMPRA_SKUC');
  fldFecha  := DataSet.FindField('FECHA_ULT_COMPRA_SKUC');
  if (fldPrecio <> nil) or (fldFecha <> nil) then
    UpsertCosteSku(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString,
                   fldPrecio, fldFecha);
end;

procedure TdmArticulos.unqrySkusBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  if SameText(
    unqryTablaG.FieldByName('ESWEB_ART').AsString,
    'S') then
    raise EDatabaseError.Create(SErrorBorrarSkuArticuloWeb);
  FCodigoArticuloSkuBorrado := Trim(
    DataSet.FieldByName('CODIGO_ART_SKU').AsString);
  // Sin FK declarada, la fila de coste quedaría huérfana al borrar el SKU:
  // la limpiamos antes de que el framework dispare el DELETE sobre
  // fza_articulos_skus.
  EliminarCosteSku(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString);
end;

procedure TdmArticulos.unqrySkusAfterPost(DataSet: TDataSet);
begin
  EncolarArticuloPrestaShop(
    unqrySkus.Connection,
    DataSet.FieldByName('CODIGO_ART_SKU').AsString,
    IdentidadSesion.Usuario);
end;

procedure TdmArticulos.unqrySkusAfterDelete(DataSet: TDataSet);
begin
  EncolarArticuloPrestaShop(
    unqrySkus.Connection,
    FCodigoArticuloSkuBorrado,
    IdentidadSesion.Usuario);
  FCodigoArticuloSkuBorrado := '';
end;

procedure TdmArticulos.unqryDetallesAtributosBeforePost(DataSet: TDataSet);
begin
  // La rejilla del detalle de atributos se nutre de una vista de sólo
  // lectura. Las ediciones reales (cambio de atributo básico, HEX nuevo)
  // se persisten desde el formulario con UPDATE directos sobre las tablas
  // implicadas: aquí abortamos el Post estándar del framework para evitar
  // el error "Cannot insert into JOIN".
  inherited;
  Abort;
end;

procedure TdmArticulos.UpsertCosteSku(const aSku: string;
                                     aPrecioField, aFechaField: TField);
var
  qry: TUniQuery;
begin
  if Trim(aSku) <> '' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'INSERT INTO fza_articulos_skus_costes ' +
        '       (CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, ' +
        '        FECHA_ULT_COMPRA_SKUC, ' +
        '        INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:SKU, :PRECIO, :FECHA, ' +
        '        CURRENT_TIMESTAMP, :USR, :USR) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '   PRECIO_ULT_COMPRA_SKUC = VALUES(PRECIO_ULT_COMPRA_SKUC), ' +
        '   FECHA_ULT_COMPRA_SKUC  = VALUES(FECHA_ULT_COMPRA_SKUC), ' +
        '   USUARIO_MODIF          = VALUES(USUARIO_MODIF)';
      qry.ParamByName('SKU').AsString := aSku;
      if (aPrecioField <> nil) and not aPrecioField.IsNull then
        qry.ParamByName('PRECIO').AsFloat := aPrecioField.AsFloat
      else
        qry.ParamByName('PRECIO').Clear;
      if (aFechaField <> nil) and not aFechaField.IsNull then
        qry.ParamByName('FECHA').AsDateTime := aFechaField.AsDateTime
      else
        qry.ParamByName('FECHA').Clear;
      qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TdmArticulos.EliminarCosteSku(const aSku: string);
var
  qry: TUniQuery;
begin
  if Trim(aSku) <> '' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'DELETE FROM fza_articulos_skus_costes ' +
        ' WHERE CODIGO_UNIDAD_SKU_SKUC = :SKU';
      qry.ParamByName('SKU').AsString := aSku;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TdmArticulos.unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
var
  fldId: TField;
begin
  inherited;
  // Defensivo por si la vista volviera a permitir filas sin ID_CB:
  // sin ID_CB no hay nada que borrar en fza_codigos_barras.
  fldId := DataSet.FindField('ID_CB');
  if (fldId = nil) or fldId.IsNull then
    raise ERangeError.Create(SErrorFilaCodigoBarrasInexistente);
end;

procedure TdmArticulos.unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
var
  ProveedorExcluido: string;
begin
  inherited;
  // El modelo/referencia del proveedor entra en el codigo de articulo.
  QuitarBarraSkuCampo(DataSet, 'REF_PROVEEDOR');
  if DataSet.FieldByName('ESPROVEEDORPRINCIPAL').AsString = 'S' then
  begin
    ProveedorExcluido := '';
    // Al editar se excluye solo la fila original del mismo articulo.
    // Una fila insertada nunca debe ocultar un principal ya existente.
    if (DataSet.State = dsEdit) and
       (VarToStr(DataSet.FieldByName('CODIGO_ART_ART').OldValue) =
        DataSet.FieldByName('CODIGO_ART_ART').AsString) then
      ProveedorExcluido :=
        VarToStr(DataSet.FieldByName('CODIGO_PRV_PRV').OldValue);
    if ArticuloTieneProvPrin(
      DataSet.FieldByName('CODIGO_ART_ART').AsString,
      ProveedorExcluido) then
      raise EValidacionBBDD.CreateFmt(SErrorProveedorPrincipalArticulo,
        [DataSet.FieldByName('CODIGO_ART_ART').AsString]);
  end;
  ActualizarAuditoria(DataSet);
end;

procedure TdmArticulos.ReconstruirColumnasStock(
  AVista: TcxGridDBTableView);
begin
  AVista.BeginUpdate;
  try
    AVista.ClearItems;
    AVista.DataController.CreateAllItems;
  finally
    AVista.EndUpdate;
  end;
end;

procedure TdmArticulos.AplicarAnchosColumnasStock(
  AVista: TcxGridDBTableView);
const
  ANCHO_ALMACEN = 180;
  ANCHO_COLOR = 90;
  ANCHO_TOTAL = 80;
  ANCHO_TALLA = 55;
  ANCHO_PENDIENTE = 145;
var
  Columna: TcxGridDBColumn;
  NombreCampo: string;
  Indice: Integer;
begin
  for Indice := 0 to AVista.ColumnCount - 1 do
  begin
    Columna := AVista.Columns[Indice] as TcxGridDBColumn;
    NombreCampo := Columna.DataBinding.FieldName;
    Columna.Caption := RotuloColumnaStock(NombreCampo, Columna.Caption);
    if StartsText(PREFIJO_VENTAS_CELDA_STOCK, NombreCampo) or
       StartsText(PREFIJO_RECIBIR_CELDA_STOCK, NombreCampo) then
    begin
      Columna.Visible := False;
      Columna.VisibleForCustomization := False;
    end
    else if SameText(NombreCampo, 'Almacen') then
      Columna.Width := ANCHO_ALMACEN
    else if SameText(NombreCampo, 'Color') then
      Columna.Width := ANCHO_COLOR
    else if SameText(NombreCampo, 'Total') then
      Columna.Width := MulDiv(ANCHO_TOTAL + 30,
        AVista.Control.CurrentPPI, USER_DEFAULT_SCREEN_DPI)
    // FZ-ISSUE-251: pendiente de traspaso y disponible (script 770); el
    // codigo del almacen solo sirve para el detalle del doble clic.
    else if EsColumnaPendienteTraspasoStock(NombreCampo) or
            SameText(NombreCampo, 'Pte. recibir compra') then
      Columna.Width := ANCHO_PENDIENTE
    else if SameText(NombreCampo, CAMPO_STOCK_CODIGO_ALMACEN) then
    begin
      Columna.Visible := False;
      Columna.VisibleForCustomization := False;
    end
    else
      Columna.Width := MulDiv(ANCHO_TALLA + 45,
        AVista.Control.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  end;
end;

// FZ-ISSUE-298: la rejilla de stock es de un solo artículo; sus cantidades
// (tallas, total, pendientes) con los decimales de su unidad (0,60 m).
procedure TdmArticulos.AplicarDecimalesStock;
var
  sMascara: string;
  Indice: Integer;
begin
  if Assigned(UnidadesMedida) then
  begin
    sMascara := '#,##' + UnidadesMedida.Mascara(
      unqryTablaG.FieldByName('TIPO_CANTIDAD_ART').AsString);
    for Indice := 0 to unqryStockArticulos.FieldCount - 1 do
      if unqryStockArticulos.Fields[Indice] is TNumericField then
        TNumericField(unqryStockArticulos.Fields[Indice]).DisplayFormat :=
          sMascara;
  end;
end;

procedure TdmArticulos.ConfigurarFiltroStock(
  AVista: TcxGridDBTableView);
var
  Columna: TcxGridDBColumn;
  ColumnaGrupo: TcxGridDBColumn;
  ColumnaTotal: TcxGridDBColumn;
  Pendientes: TArray<TcxGridDBColumn>;
  Ceros: TcxFilterCriteriaItemList;
  OcultarCeros: Boolean;
  NombreCampo: string;
  Indice: Integer;
begin
  ColumnaGrupo := nil;
  ColumnaTotal := nil;
  Pendientes := nil;
  for Indice := 0 to AVista.ColumnCount - 1 do
  begin
    Columna := AVista.Columns[Indice] as TcxGridDBColumn;
    NombreCampo := Columna.DataBinding.FieldName;
    if SameText(NombreCampo, 'Total') or
       SameText(NombreCampo, 'Stock Total') then
      ColumnaTotal := Columna
    else if SameText(NombreCampo, CAMPO_STOCK_PTE_TRASPASAR) or
            SameText(NombreCampo, CAMPO_STOCK_PTE_RECIBIR_TRASPASO) or
            SameText(NombreCampo, 'Pte. recibir compra') then
      Pendientes := Pendientes + [Columna]
    else if StartsText(PREFIJO_VENTAS_CELDA_STOCK, NombreCampo) or
            StartsText(PREFIJO_RECIBIR_CELDA_STOCK, NombreCampo) then
      Pendientes := Pendientes + [Columna]
    else if Columna.Visible and
            not SameText(NombreCampo, 'Almacen') and
            not SameText(NombreCampo, CAMPO_STOCK_CODIGO_ALMACEN) and
            (Columna.DataBinding.Field <> nil) and
            (Columna.DataBinding.Field.DataType in
              [ftString, ftWideString, ftMemo, ftWideMemo]) then
      ColumnaGrupo := Columna;
  end;
  OcultarCeros := Assigned(ParametrosApp) and
    ParametrosApp.GetBool('appStockOcultarCeros', True);
  AVista.DataController.Filter.BeginUpdate;
  try
    AVista.DataController.Filter.Root.Clear;
    AVista.DataController.Filter.Root.BoolOperatorKind := fboAnd;
    if ColumnaGrupo <> nil then
      AVista.DataController.Filter.Root.AddItem(
        ColumnaGrupo as TObject, foNotEqual, '-', '-');
    // FZ-ISSUE-251: una fila sin stock pero con traspasos pendientes se ve.
    if OcultarCeros and (ColumnaTotal <> nil) then
    begin
      Ceros := AVista.DataController.Filter.Root.AddItemList(fboOr);
      Ceros.AddItem(ColumnaTotal as TObject, foNotEqual, 0, '0');
      for Columna in Pendientes do
        Ceros.AddItem(Columna as TObject, foNotEqual, 0, '0');
    end;
  finally
    AVista.DataController.Filter.EndUpdate;
  end;
  AVista.DataController.Filter.Active :=
    (ColumnaGrupo <> nil) or (OcultarCeros and (ColumnaTotal <> nil));
end;

procedure TdmArticulos.unqryStockArticulosAfterScroll(DataSet: TDataSet);
var
  tvArticulosStock: TcxGridDBTableView;
  sArt: string;
  swTotal, swTramo: TStopwatch;
  msSP, msRebuild, msAnchos: Int64;
begin
  inherited;
  if (not DataSet.ControlsDisabled) and DataSet.Active and
     (not DataSet.IsEmpty) then
  begin
    swTotal := TStopwatch.StartNew;
    msSP := 0;
    msRebuild := 0;
    msAnchos := 0;
    unqryStockArticulos.Close;
    sArt := unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    tvArticulosStock := FVistaStock;
    if tvArticulosStock <> nil then
    begin
      if sArt <> '' then
      begin
        swTramo := TStopwatch.StartNew;
        if not AbrirConsultaStockPorPestanas(
          unqryStockArticulos, sArt, True, True) then
        begin
          unqryStockArticulos.SQL.Text :=
            'CALL PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ(:CODIGO_ART_ART)';
          unqryStockArticulos.ParamByName('CODIGO_ART_ART').AsString := sArt;
          unqryStockArticulos.Open;
        end;
        msSP := swTramo.ElapsedMilliseconds;

        ReconstruirColumnasStock(tvArticulosStock);
        if unqryStockArticulos.Active and
           (tvArticulosStock.ColumnCount > 0) then
        begin
          AplicarAnchosColumnasStock(tvArticulosStock);
          AplicarDecimalesStock;
          ConfigurarFiltroStock(tvArticulosStock);
        end;
      end;
      RegistroLog.RegistrarRendimiento('Articulos.StockAfterScroll',
        Format('art=%s | SP=%d ms | RebuildItems=%d ms | ' +
          'Anchos=%d ms | cols=%d',
          [sArt, msSP, msRebuild, msAnchos,
           tvArticulosStock.ColumnCount]),
        swTotal.ElapsedMilliseconds);
    end;
  end;
end;

procedure TdmArticulos.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FCodigoArticuloBorrado := Trim(
    DataSet.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TdmArticulos.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  qryBorrarLineas := TUniQuery.Create(Self);
  qryBorrarLineas.Connection := ConexionPrincipal;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_articulos_proveedores ' +
    ' WHERE CODIGO_ART_AP = :Articulo ;';
  qryBorrarLineas.Params.ParamByName('Articulo').AsString :=
    FCodigoArticuloBorrado;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_articulos_tarifas ' +
    ' WHERE CODIGO_ART_ARTTAR = :Articulo ;';
  qryBorrarLineas.Params.ParamByName('Articulo').AsString :=
    FCodigoArticuloBorrado;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.Free;
  OmitirArticuloPrestaShop(
    unqryTablaG.Connection,
    FCodigoArticuloBorrado,
    IdentidadSesion.Usuario);
  FCodigoArticuloBorrado := '';
//  end;
end;

procedure TdmArticulos.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  oCampoWeb: TField;
begin
  inherited;
  UniDataValoresAutomaticosRepositorio.AplicarValoresPorDefecto(
    ConexionPrincipal, unqryTablaG, 'fza_articulos');
  // El '0' de valores automáticos significa «código del contador al
  // grabar». En pantalla salía «0» y lo tecleado quedaba «0QA-...»: el
  // código se deja vacío y vacío también es automático (FZ-ISSUE-225).
  if Trim(unqryTablaG.FindField('CODIGO_ART_ART').AsString) = '0' then
    unqryTablaG.FindField('CODIGO_ART_ART').Clear;
  // La marca web es opt-in: un artículo nuevo nunca debe publicarse por
  // accidente ni enviar NULL aunque aún no exista un valor configurable.
  unqryTablaG.FieldByName('ESSERVICIO_REPARACION_ART').AsString := 'N';
  oCampoWeb := unqryTablaG.FindField('ESWEB_ART');
  if Assigned(oCampoWeb) and (Trim(oCampoWeb.AsString) = '') then
    oCampoWeb.AsString := 'N';
  unqryTablaG.FieldByName('CODIGO_FAM_ART').OnChange :=
    FamiliaAltaCambiada;
  unqryTablaG.FindField('CODIGO_FAM_ART').AsString :=
                                   ObtenerValorPorDefecto(
                                     ConexionPrincipal,
                                     'vi_articulos_familias_list',
                                                   'CODIGO_FAM_FAM',
                                                   'ESDEFAULT_FAM');
  // Por defecto los articulos van en Unidades (sin decimales). Solo los que
  // se cambien a metros/kilos... mostraran decimales segun la unidad.
  if Trim(unqryTablaG.FindField('TIPO_CANTIDAD_ART').AsString) = '' then
    unqryTablaG.FindField('TIPO_CANTIDAD_ART').AsString := 'Uds';
  ProponerTrazabilidadAlta;
end;

// Cambiar de familia durante el alta actualiza la propuesta en pantalla.
procedure TdmArticulos.FamiliaAltaCambiada(Sender: TField);
begin
  if unqryTablaG.State = dsInsert then
    ProponerTrazabilidadAlta;
end;

// La familia solo propone el modo: el usuario puede elegir otro en el alta
// igual que al editar (FZ-ISSUE-316).
procedure TdmArticulos.ProponerTrazabilidadAlta;
var
  Alta: TTrazabilidadAlta;
begin
  if unqryTablaG.State = dsInsert then
  begin
    Alta := LeerTrazabilidadFamilia(unqryTablaG.Connection,
      unqryTablaG.FieldByName('CODIGO_FAM_ART').AsString);
    unqryTablaG.FieldByName('TIPO_TRAZABILIDAD_ART').AsString :=
      Alta.ValorModo;
    unqryTablaG.FieldByName('ESCADUCIDAD_ART').AsString :=
      Alta.ValorCaducidad;
    unqryTablaG.FieldByName('ESTRAZABLE_ART').AsString :=
      Alta.ValorEsTrazable;
  end;
end;

procedure TdmArticulos.unqryTablaGAfterPost(DataSet: TDataSet);
var
  bQuedaEnWeb: Boolean;
  sArt: string;
begin
  try
    inherited;
    if FLimpiarColeccionesAlGrabar then
    begin
      FLimpiarColeccionesAlGrabar := False;
      LimpiarColeccionesArticulo(
        Trim(unqryTablaG.FieldByName('CODIGO_ART_ART').AsString));
    end;
    // Articulo simple (sin variaciones): garantizar una unidad/SKU base con
    // CODIGO_UNIDAD_SKU = CODIGO_ART_ART para que pueda llevar stock y
    // aparezca en la consulta (Ctrl+U), movimientos, etc. sin crear SKUs a
    // mano.
    if SameText(unqryTablaG.FindField('ESVARIACION_ART').AsString, 'N') then
    begin
      sArt := Trim(unqryTablaG.FindField('CODIGO_ART_ART').AsString);
      if sArt <> '' then
        AsegurarSkuBase(sArt);
    end;
    sArt := Trim(unqryTablaG.FindField('CODIGO_ART_ART').AsString);
    bQuedaEnWeb := SameText(
      unqryTablaG.FindField('ESWEB_ART').AsString,
      'S');
    if FCambioMarcaWebPreparado and
       (FMarcaWebAnteriorPreparada <>
        FMarcaWebNuevaPreparada) then
      CapturarOEncolarVisibilidadPrestaShop(
        sArt,
        FAccionVisibilidadPendiente)
    else if FAplazarVisibilidadPrestaShop then
    begin
      FCodigoArticuloVisibilidadAplazada := sArt;
      FQuedaEnWebVisibilidadAplazada := bQuedaEnWeb;
    end
    else if bQuedaEnWeb then
      EncolarArticuloPrestaShop(
        unqryTablaG.Connection,
        sArt,
        IdentidadSesion.Usuario)
    else
      OmitirArticuloPrestaShop(
        unqryTablaG.Connection,
        sArt,
        IdentidadSesion.Usuario);
  finally
    LimpiarCambioMarcaWebPreparado;
  end;
end;

procedure TdmArticulos.AsegurarSkuBase(const ACodArt: string);
var
  qry: TUniQuery;
begin
  // Crea el SKU base solo si el articulo aun no tiene NINGUN SKU. El marcador
  // de "sin variacion" en CODIGO_VAR_SKU es '-' (convencion ya usada en la
  // BBDD, p.ej. el SKU 'BOLSO-PIEL'). Idempotente: NOT EXISTS + INSERT IGNORE.
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :cod, :art, ''-'', ''S'', CURRENT_TIMESTAMP, :usr, :usr ' +
      '  FROM DUAL ' +
      ' WHERE NOT EXISTS (SELECT 1 FROM fza_articulos_skus ' +
      '                    WHERE CODIGO_ART_SKU = :art2)';
    qry.ParamByName('cod').AsString  := ACodArt;
    qry.ParamByName('art').AsString  := ACodArt;
    qry.ParamByName('art2').AsString := ACodArt;
    qry.ParamByName('usr').AsString  := IdentidadSesion.Usuario;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.CopiarProveedoraArticulo(dtProveedores: TDataset);
begin
  if unqryProveedoresArticulos.State = dsBrowse then
    unqryProveedoresArticulos.Insert;
  unqryProveedoresArticulos.FindField('CODIGO_PRV_PRV').AsString :=
    dtProveedores.FindField('CODIGO_PRV_PRV').AsString;
  unqryProveedoresArticulos.FindField('RAZON_SOCIAL_PRV').AsString :=
    dtProveedores.FindField('RAZON_SOCIAL_PRV').AsString;
  if unqryProveedoresArticulos.RecordCount = 0 then
    unqryProveedoresArticulos.FindField(
      'ESPROVEEDORPRINCIPAL').AsString := 'S'
  else
    unqryProveedoresArticulos.FindField(
      'ESPROVEEDORPRINCIPAL').AsString := 'N';
  unqryProveedoresArticulos.Post;
end;

procedure TdmArticulos.AbrirMarcaReparacion(DataSet: TDataSet);
begin
  if Assigned(FAntesAbrirServicio) then
    FAntesAbrirServicio(DataSet);
  unqryTablaG.SQL.Text := SqlArticulosConMarcaReparacion(
    unqryTablaG.Connection, unqryTablaG.SQL.Text);
end;

procedure TdmArticulos.ActivarMarcaReparacion(DataSet: TDataSet);
begin
  if Assigned(FDespuesAbrirServicio) then
    FDespuesAbrirServicio(DataSet);
  DataSet.FieldByName('ESSERVICIO_REPARACION_ART').ReadOnly := False;
end;

procedure TdmArticulos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FAntesAbrirServicio := unqryTablaG.BeforeOpen;
  FDespuesAbrirServicio := unqryTablaG.AfterOpen;
  unqryTablaG.BeforeOpen := AbrirMarcaReparacion;
  unqryTablaG.AfterOpen := ActivarMarcaReparacion;
  // Solo asignamos Connection y MasterSource. Los Open se han movido a
  // AbrirDetalles (que invoca TfrmMtoGen.AbrirTablaPrincipalAsync en thread)
  // para no congelar la UI durante la creacion del data module.
  unqryFamiliaArticulos.Connection := ConexionPrincipal;
  unqryPerfiles.Connection := ConexionPrincipal;
  unqryTarifasArticulos.Connection := ConexionPrincipal;
  unqryProveedoresArticulos.Connection := ConexionPrincipal;
  unqryUltimasComprasProveedor.Connection := ConexionPrincipal;
  unqryLinFacturasArticulos.Connection := ConexionPrincipal;
  unqryProveedores.Connection := ConexionPrincipal;
  unqryTiposIVA.Connection := ConexionPrincipal;
  unqryTarifas.Connection := ConexionPrincipal;
  unqryVariacionesArticulos.Connection := ConexionPrincipal;
  unqrySkus.Connection := ConexionPrincipal;
  unqryStockArticulos.Connection := ConexionPrincipal;
  unqryMovimientosArticulos.Connection := ConexionPrincipal;
  unqryDetallesAtributos.Connection := ConexionPrincipal;
  unqryAtributosBasicosLookup.Connection := ConexionPrincipal;
  unqryUnidadesMedidaLookup.Connection := ConexionPrincipal;
  // El detalle de atributos sigue al SKU activo (master) para mostrar sólo
  // las filas del SKU posicionado en la rejilla superior.
  unqryDetallesAtributos.MasterSource := dsSkus;
end;

procedure TdmArticulos.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryVariacionesArticulos.MasterSource := ADataSource;
  unqrySkus.MasterSource := ADataSource;
  unqryLinFacturasArticulos.MasterSource := ADataSource;
  unqryTarifasArticulos.MasterSource := ADataSource;
  unqryProveedoresArticulos.MasterSource := ADataSource;
  unqryMovimientosArticulos.MasterSource := ADataSource;
end;

procedure TdmArticulos.AsignarVistaStock(AVista: TcxGridDBTableView);
begin
  FVistaStock := AVista;
end;

procedure TdmArticulos.AbrirDetalles;
const
  TAG = 'Articulos.AbrirDetalles';
var
  sw: TStopwatch;
  saveAfterScroll: TDataSetNotifyEvent;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // unqryStockArticulos.AfterScroll dispara unqryStockArticulosAfterScroll
  // que ya se ha ejecutado durante CrearTablaPrincipal (linea 1798 de
  // inMtoArticulos.pas). Si lo dejamos activo aqui, al abrir
  // unqryStockArticulos el AfterScroll se dispara otra vez y re-ejecuta
  // el SP + rebuild del grid. Lo silenciamos para evitar el duplicado;
  // lo restauramos al final.
  saveAfterScroll := unqryStockArticulos.AfterScroll;
  unqryStockArticulos.AfterScroll := nil;
  try
    AbrirConsultaConTiempo(
      unqryTiposIVA, TAG, 'unqryTiposIVA', RegistroLog);
    AbrirConsultaConTiempo(
      unqryFamiliaArticulos, TAG, 'unqryFamiliaArticulos', RegistroLog);
    AbrirConsultaConTiempo(
      unqryVariaciones, TAG, 'unqryVariaciones', RegistroLog);
    AbrirConsultaConTiempo(
      unqryAtributosBasicosLookup, TAG, 'unqryAtributosBasicosLookup',
      RegistroLog);
    AbrirConsultaConTiempo(
      unqryUnidadesMedidaLookup, TAG, 'unqryUnidadesMedidaLookup',
      RegistroLog);
    // unqryTarifasArticulos NO se abre aqui: la vista tarda ~6s
    // (subqueries DEPENDENT, ver EXPLAIN). Se abre solo cuando el
    // usuario va a la pestaña tsTarifas, via AsegurarTarifasAbiertas.
    AbrirConsultaConTiempo(
      unqryProveedoresArticulos, TAG, 'unqryProveedoresArticulos',
      RegistroLog);
    AbrirConsultaConTiempo(
      unqryLinFacturasArticulos, TAG, 'unqryLinFacturasArticulos',
      RegistroLog);
    AbrirConsultaConTiempo(
      unqryVariacionesArticulos, TAG, 'unqryVariacionesArticulos',
      RegistroLog);
    AbrirConsultaConTiempo(
      unqrySkus, TAG, 'unqrySkus', RegistroLog);
    AbrirConsultaConTiempo(
      unqryStockArticulos, TAG, 'unqryStockArticulos', RegistroLog);
    AbrirConsultaConTiempo(
      unqryMovimientosArticulos, TAG, 'unqryMovimientosArticulos',
      RegistroLog);
    AbrirConsultaConTiempo(
      unqryDetallesAtributos, TAG, 'unqryDetallesAtributos', RegistroLog);
  finally
    unqryStockArticulos.AfterScroll := saveAfterScroll;
  end;
  // QuitarEscribiblesVista necesita unqryTarifasArticulos abierto; ahora
  // que la abrimos perezosamente, esa rutina se llama desde
  // AsegurarTarifasAbiertas tras el primer Open.
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmArticulos.ReactivarControlesTrasAbrir;
begin
  inherited;
  // Ya no hay TDataSource desactivados ni AfterScroll silenciado:
  // AbrirDetalles corre en main thread y no necesita la proteccion
  // contra DevExpress non-thread-safe. Metodo vacio por compatibilidad.
end;

procedure TdmArticulos.AsegurarTarifasAbiertas;
var
  sw: TStopwatch;
begin
  if not unqryTarifasArticulos.Active then
  begin
    sw := TStopwatch.StartNew;
    try
      unqryTarifasArticulos.Open;
      QuitarEscribiblesVista;
      RegistroLog.RegistrarRendimiento(
        'Articulos.Lazy', 'unqryTarifasArticulos OK',
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Articulos.Lazy',
          'unqryTarifasArticulos ERROR=' + E.Message,
          sw.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmArticulos.CargarUltimasComprasProveedor;
begin
  unqryUltimasComprasProveedor.Close;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    unqryUltimasComprasProveedor.SQL.Text :=
      SQL_ULTIMO_COSTE_PROVEEDOR_INI + SQL_ULTIMAS_COMPRAS_PROVEEDOR +
      SQL_ULTIMO_COSTE_PROVEEDOR_MED + SQL_ULTIMAS_COMPRAS_ALBARAN +
      SQL_ULTIMO_COSTE_PROVEEDOR_FIN;
    unqryUltimasComprasProveedor.ParamByName('ARTICULO').AsString :=
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    unqryUltimasComprasProveedor.Open;
  end;
end;

procedure TdmArticulos.QuitarEscribiblesVista;
const
  // Únicas columnas que pertenecen realmente a fza_articulos_tarifas
  CamposEscribibles: array[0..17] of string = (
    'CODIGO_ART_ARTTAR',  'CODIGO_UNICO_ARTTAR',  'CODIGO_UNIDAD_ARTTAR',
    'CODIGO_TAR_ARTTAR',  'ESACTIVO_ARTTAR',
    'PRECIO_COSTE_ARTTAR', 'FECHA_ULT_COMPRA_ARTTAR',
    'CODIGO_PRV_ARTTAR',
    'PRECIO_SALIDA_ARTTAR','PRECIO_FINAL_ARTTAR','PRECIO_DTO_ARTTAR',
    'PORCENTAJE_DTO_ARTTAR',
    'FECHA_DESDE_ARTTAR', 'FECHA_HASTA_ARTTAR',
    'INSTANTE_MODIF', 'INSTANTE_ALTA', 'USUARIO_ALTA', 'USUARIO_MODIF'
  );

  function EsEscribible(const NombreCampo: string): Boolean;
  var s: string;
  begin
    Result := False;
    for s in CamposEscribibles do
    begin
      if SameText(s, NombreCampo) then
        Result := True;
    end;
  end;

var
  i: Integer;
begin
  inherited;
  if not unqryTarifasArticulos.Active then
    unqryTarifasArticulos.Open;
  for i := 0 to unqryTarifasArticulos.Fields.Count - 1 do
    if not EsEscribible(unqryTarifasArticulos.Fields[i].FieldName) then
      unqryTarifasArticulos.Fields[i].Required := False;
end;

procedure TdmArticulos.FillTarifas(lst: TcxListView);
var
  Itm: TListItem;
begin
  lst.Clear;
  if ContainsText(unqryTarifas.SQL.Text, ':CODIGO_ART_ART') then
    unqryTarifas.ParamByName('CODIGO_ART_ART').AsString :=
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  unqryTarifas.Open;
  unqryTarifas.First;
  while not unqryTarifas.Eof do
  begin
    Itm := lst.Items.Add;
    Itm.Caption :=
      unqryTarifas.FindField('CODIGO_TAR_ARTTAR').AsString;
    Itm.SubItems.Add(
      unqryTarifas.FindField('NOMBRE_TAR_TAR').AsString);
    if SameText(
      unqryTarifas.FindField('CODIGO_TAR_ARTTAR').AsString,
      ParametrosCaja.TarifaDefecto) then
      Itm.Checked := True;
    unqryTarifas.Next;
  end;
  unqryTarifas.Close;
end;

function TdmArticulos.FormulaCodigoArticulo: string;
begin
  Result := FORMULA_CODIGO_ARTICULO_SESION_DEFECTO;
  if Assigned(ParametrosApp) then
    Result := ParametrosApp.GetString(CLAVE_FORMULA_CODIGO_ARTICULO_SESION);
  Result := TFormulaCodigoArticuloSesion.Normalizar(Result);
end;

procedure TdmArticulos.AsignarDatosCodigoAlta(
  const AModelo, AProveedor: string);
begin
  FValoresFormulaAlta.ModeloProv := Trim(AModelo);
  FValoresFormulaAlta.CodProv := Trim(AProveedor);
end;

procedure TdmArticulos.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  FValoresFormulaAlta := Default(TValoresFormulaCodigoArticuloSesion);
  // El dialogo puede cancelar antes de que exista la nueva cabecera.
  try
    if Assigned(FOnPrepararAlta) then
      FOnPrepararAlta(Self);
  except
    on E: EFormulaCodigoArticuloSesion do
      raise EValidacionBBDD.Create(E.Message);
  end;
  inherited;
end;

procedure TdmArticulos.GetCodigoAutoArticulo;
const
  MAX_SALTOS_CONTADOR = 1000;
var
  sCodigo, sFormula, sCodigoFamilia: string;
  Valores: TValoresFormulaCodigoArticuloSesion;
  iSaltos: Integer;
  UsaContador, UsaArticulo: Boolean;
  Ocupado: Boolean;
begin
  if (unqryTablaG.State = dsInsert) and
     ((Trim(unqryTablaG.FieldByName('CODIGO_ART_ART').AsString) = '') or
      (Trim(unqryTablaG.FieldByName('CODIGO_ART_ART').AsString) = '0')) then
  begin
    sFormula := FormulaCodigoArticulo;
    Valores := FValoresFormulaAlta;
    Valores.CodFamilia := Trim(
      unqryTablaG.FieldByName('CODIGO_FAM_ART').AsString);
    try
      UsaContador := TFormulaCodigoArticuloSesion.UsaContadorFamilia(
        sFormula);
      UsaArticulo := TFormulaCodigoArticuloSesion.UsaContadorArticulo(
        sFormula);
      // Validar los datos antes de consumir ningun contador.
      if UsaContador then
        Valores.ContadorFamilia := 'PENDIENTE';
      if UsaArticulo then
        Valores.CodArt := 'PENDIENTE';
      if not TFormulaCodigoArticuloSesion.PuedeEvaluar(sFormula, Valores) then
        raise EValidacionBBDD.Create(SErrorFormulaCodigoArticuloDatos);
      iSaltos := 0;
      repeat
        if UsaContador then
        begin
          if not ResolverCodigoArticuloFamilia(unqryTablaG.Connection,
            Valores.CodFamilia, IdentidadSesion.Usuario, sCodigoFamilia) then
            raise EValidacionBBDD.CreateFmt(
              SErrorFamiliaSesionSinContador, [Valores.CodFamilia]);
          Valores.ContadorFamilia := Copy(sCodigoFamilia,
            Length(Valores.CodFamilia) + 1, MaxInt);
        end;
        if UsaArticulo then
          Valores.CodArt := ObtenerSiguienteContador(
            unqryTablaG.Connection, 'AR', IdentidadSesion.Usuario);
        sCodigo := TFormulaCodigoArticuloSesion.Evaluar(sFormula, Valores);
        sCodigo := StringReplace(sCodigo, '/', '-', [rfReplaceAll]);
        Ocupado := CodigoArticuloExiste(sCodigo);
        Inc(iSaltos);
      until not Ocupado or not (UsaContador or UsaArticulo) or
            (iSaltos >= MAX_SALTOS_CONTADOR);
      if Ocupado then
        raise EValidacionBBDD.CreateFmt(
          SErrorCodigoArticuloDuplicado, [sCodigo]);
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString := sCodigo;
    except
      on E: EFormulaCodigoArticuloSesion do
        raise EValidacionBBDD.Create(E.Message);
    end;
  end;
  if unqryTablaG.FindField('ORDEN_ART').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_ART').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'AO',
                                                   IdentidadSesion.Usuario);
  end;
end;

function TdmArticulos.CodigoArticuloDuplicado(
  ADataSet: TDataSet): Boolean;
var
  CodigoActual: string;
  CodigoAnterior: string;
  Consulta: TUniQuery;
begin
  Result := False;
  if ADataSet.State in [dsInsert, dsEdit] then
  begin
    CodigoActual := ADataSet.FieldByName('CODIGO_ART_ART').AsString;
    if Pos('/', CodigoActual) > 0 then
      CodigoActual := SinBarraSku(CodigoActual);
    CodigoAnterior := '';
    if ADataSet.State = dsEdit then
      CodigoAnterior := VarToStr(
        ADataSet.FieldByName('CODIGO_ART_ART').OldValue);
    if (CodigoActual <> '') and (CodigoActual <> '0') and
       ((ADataSet.State = dsInsert) or
        (CodigoActual <> CodigoAnterior)) then
    begin
      Consulta := TUniQuery.Create(nil);
      try
        Consulta.Connection := unqryTablaG.Connection;
        Consulta.SQL.Text :=
          'SELECT CODIGO_ART_ART FROM fza_articulos ' +
          'WHERE CODIGO_ART_ART = :CODIGO_ART_ART LIMIT 1';
        Consulta.ParamByName('CODIGO_ART_ART').AsString := CodigoActual;
        Consulta.Open;
        Result := not Consulta.IsEmpty;
      finally
        Consulta.Free;
      end;
    end;
  end;
end;

function TdmArticulos.CodigoArticuloExiste(const ACodigo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := unqryTablaG.Connection;
    Consulta.SQL.Text :=
      'SELECT CODIGO_ART_ART FROM fza_articulos ' +
      'WHERE CODIGO_ART_ART = :CODIGO_ART_ART LIMIT 1';
    Consulta.ParamByName('CODIGO_ART_ART').AsString := ACodigo;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    Consulta.Free;
  end;
end;

function TdmArticulos.ProponerCodigoArticuloLibre(
  const ACodigo: string): string;
const
  MAX_CANDIDATOS = 1000;
var
  Consulta: TUniQuery;
  iCifras, iDigitos, i: Integer;
  iNumero: Int64;
  sPrefijo, sCandidato: string;
begin
  Result := '';
  iCifras := 0;
  while (iCifras < Length(ACodigo)) and
        CharInSet(ACodigo[Length(ACodigo) - iCifras], ['0'..'9']) do
    Inc(iCifras);
  if (iCifras > 0) and (iCifras <= 18) then
  begin
    sPrefijo := Copy(ACodigo, 1, Length(ACodigo) - iCifras);
    iNumero := StrToInt64(Copy(ACodigo, Length(ACodigo) - iCifras + 1,
      iCifras)) + 1;
    iDigitos := iCifras;
  end
  else
  begin
    // Sin cifras finales: lo que daría el alta automática.
    sPrefijo := '';
    iNumero := 0;
    iDigitos := 0;
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := unqryTablaG.Connection;
      Consulta.SQL.Text :=
        'SELECT GREATEST(CON, 1) AS CON, NUM_DIGITOS_CON ' +
        '  FROM fza_contadores ' +
        ' WHERE TIPO_DOC_CON = ''AR'' ' +
        '   AND EMPRESA_CON = ''-'' ' +
        '   AND DEFAULT_CON = ''S'' ' +
        '   AND ESACTIVO_CON = ''S'' ' +
        ' ORDER BY SERIE_CON ' +
        ' LIMIT 1';
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        iNumero := Consulta.FieldByName('CON').AsLargeInt;
        iDigitos := Consulta.FieldByName('NUM_DIGITOS_CON').AsInteger;
      end;
    finally
      Consulta.Free;
    end;
    if iNumero = 0 then
      Exit;
  end;
  for i := 1 to MAX_CANDIDATOS do
  begin
    sCandidato := IntToStr(iNumero);
    if Length(sCandidato) < iDigitos then
      sCandidato := StringOfChar('0', iDigitos - Length(sCandidato)) +
        sCandidato;
    sCandidato := sPrefijo + sCandidato;
    if not CodigoArticuloExiste(sCandidato) then
      Exit(sCandidato);
    Inc(iNumero);
  end;
end;

function TdmArticulos.BuscarCodigoBarrasRepetido(
  const ACodigoBarras: string; AIdExcluido: Integer;
  out AExistente: TCodigoBarrasRepetido): Boolean;
var
  Consulta: TUniQuery;
begin
  AExistente := Default(TCodigoBarrasRepetido);
  Result := False;
  if Trim(ACodigoBarras) = '' then
    Exit;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := unqryVariacionesArticulos.Connection;
    // IDX_BARRAS_CB cubre la búsqueda.
    Consulta.SQL.Text :=
      'SELECT CB.CODIGO_UNIDAD_CB, SKU.CODIGO_ART_SKU, ART.DESCRIPCION_ART ' +
      '  FROM fza_codigos_barras CB ' +
      '  LEFT JOIN fza_articulos_skus SKU ' +
      '    ON SKU.CODIGO_UNIDAD_SKU = CB.CODIGO_UNIDAD_CB ' +
      '  LEFT JOIN fza_articulos ART ' +
      '    ON ART.CODIGO_ART_ART = SKU.CODIGO_ART_SKU ' +
      ' WHERE CB.CODIGO_BARRAS_CB = :CODIGO_BARRAS ' +
      '   AND CB.ID_CB <> :ID_CB ' +
      ' LIMIT 1';
    Consulta.ParamByName('CODIGO_BARRAS').AsString := Trim(ACodigoBarras);
    Consulta.ParamByName('ID_CB').AsInteger := AIdExcluido;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
    if Result then
    begin
      AExistente.CodigoBarras := Trim(ACodigoBarras);
      AExistente.Sku := Consulta.FieldByName('CODIGO_UNIDAD_CB').AsString;
      AExistente.Articulo := Consulta.FieldByName('CODIGO_ART_SKU').AsString;
      AExistente.Descripcion :=
        Consulta.FieldByName('DESCRIPCION_ART').AsString;
    end;
  finally
    Consulta.Free;
  end;
end;

procedure TdmArticulos.ValidarCodigoArticuloDisponible;
begin
  if CodigoArticuloDuplicado(unqryTablaG) then
    raise ECodigoArticuloDuplicado.CreateFmt(
      SErrorCodigoArticuloDuplicado,
      [SinBarraSku(unqryTablaG.FieldByName('CODIGO_ART_ART').AsString)]);
end;

procedure TdmArticulos.GuardarProveedorSolicitadoAlta;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := unqryTablaG.Connection;
    Consulta.SQL.Text :=
      'INSERT INTO fza_articulos_proveedores ' +
      '(CODIGO_ART_AP, CODIGO_PRV_AP, REF_PROVEEDOR_AP, ' +
      ' ESPROVEEDORPRINCIPAL_AP, INSTANTE_ALTA, INSTANTE_MODIF, ' +
      ' USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :ARTICULO, :PROVEEDOR, :MODELO, ' +
      'CASE WHEN EXISTS (SELECT 1 FROM fza_articulos_proveedores AP ' +
      ' WHERE AP.CODIGO_ART_AP = :ARTICULO ' +
      ' AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'') ' +
      'THEN ''N'' ELSE ''S'' END, NOW(), NOW(), :USUARIO, :USUARIO ' +
      'FROM fza_proveedores P WHERE P.CODIGO_PRV_PRV = :PROVEEDOR ' +
      'ON DUPLICATE KEY UPDATE ' +
      'REF_PROVEEDOR_AP = CASE WHEN :MODELO <> '''' THEN :MODELO ' +
      ' ELSE REF_PROVEEDOR_AP END, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO';
    Consulta.ParamByName('ARTICULO').AsString :=
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    Consulta.ParamByName('PROVEEDOR').AsString := FValoresFormulaAlta.CodProv;
    Consulta.ParamByName('MODELO').AsString :=
      SinBarraSku(FValoresFormulaAlta.ModeloProv);
    Consulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    Consulta.ExecSQL;
    if Assigned(unqryProveedoresArticulos) and
       unqryProveedoresArticulos.Active then
    begin
      unqryProveedoresArticulos.Close;
      unqryProveedoresArticulos.Open;
    end;
  finally
    Consulta.Free;
  end;
end;

procedure TdmArticulos.ValidarProveedorCodigoAlta(
  const ACodigoProveedor: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := unqryTablaG.Connection;
    Consulta.SQL.Text := 'SELECT CODIGO_PRV_PRV FROM fza_proveedores ' +
      'WHERE CODIGO_PRV_PRV = :PROVEEDOR';
    Consulta.ParamByName('PROVEEDOR').AsString := Trim(ACodigoProveedor);
    Consulta.Open;
    if Consulta.IsEmpty then
      raise EValidacionBBDD.CreateFmt(
        SErrorProveedorAltaArticuloInexistente, [Trim(ACodigoProveedor)]);
  finally
    Consulta.Free;
  end;
end;

procedure TdmArticulos.GuardarArticulo;
var
  VincularProveedor, TransaccionPropia: Boolean;
  Ediciones: TEdicionesDataSetsPendientes;
begin
  VincularProveedor := (unqryTablaG.State = dsInsert) and
    (FValoresFormulaAlta.CodProv <> '');
  TransaccionPropia := VincularProveedor and
    not unqryTablaG.Connection.InTransaction;
  if VincularProveedor then
    Ediciones := CapturarEdicionesDataSets(Self);
  try
    if TransaccionPropia then
      unqryTablaG.Connection.StartTransaction;
    if VincularProveedor then
      ValidarProveedorCodigoAlta(FValoresFormulaAlta.CodProv);
    unqryTablaG.Post;
    if VincularProveedor then
      GuardarProveedorSolicitadoAlta;
    if TransaccionPropia then
      unqryTablaG.Connection.Commit;
  except
    if TransaccionPropia then
    begin
      if unqryTablaG.Connection.InTransaction then
        unqryTablaG.Connection.Rollback;
      if unqryTablaG.State = dsBrowse then
        RestaurarEdicionesDataSets(Ediciones);
    end;
    ValidarCodigoArticuloDisponible;
    raise;
  end;
end;

procedure TdmArticulos.ValidarDatosArticulo;
begin
  if unqryTablaG.State in [dsInsert, dsEdit] then
    ValidarDatosBasicosArticulo(
      unqryTablaG.FieldByName('DESCRIPCION_ART').AsString,
      unqryTablaG.FieldByName('CODIGO_FAM_ART').AsString,
      PerfilesLectura,
      (unqryTablaG.State = dsInsert) or
      (Trim(VarToStr(unqryTablaG.FieldByName(
        'CODIGO_FAM_ART').OldValue)) <> ''));
end;

function TdmArticulos.HayStockConLote(
  const ACodigoArticulo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := SQL_STOCK_CON_LOTE_ARTICULO;
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmArticulos.HaySkusConVariacion(
  const ACodigoArticulo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := SQL_SKUS_CON_VARIACION_ARTICULO;
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// FZ-ISSUE-444: el tipo de variacion se puede corregir mientras el
// articulo no tenga SKU generados; sus colecciones eran del tipo
// anterior y se quitan al grabar.
procedure TdmArticulos.PrepararCambioTipoVariacion;
var
  sAnterior: string;
  sCodigo: string;
  sNuevo: string;
begin
  FLimpiarColeccionesAlGrabar := False;
  if unqryTablaG.State = dsEdit then
  begin
    sAnterior := Trim(VarToStr(unqryTablaG.FieldByName(
      'TIPO_VARIACION_ART').OldValue));
    sNuevo := Trim(unqryTablaG.FieldByName(
      'TIPO_VARIACION_ART').AsString);
    if (sAnterior <> '') and (sAnterior <> sNuevo) then
    begin
      sCodigo := Trim(VarToStr(unqryTablaG.FieldByName(
        'CODIGO_ART_ART').OldValue));
      if HaySkusConVariacion(sCodigo) then
        raise EValidacionBBDD.Create(
          SErrorCambiarTipoVariacionConSkus);
      FLimpiarColeccionesAlGrabar := True;
    end;
  end;
end;

procedure TdmArticulos.LimpiarColeccionesArticulo(
  const ACodigoArticulo: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := SQL_BORRAR_COLECCIONES_ARTICULO;
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// F-LOTEC-011: ESTRAZABLE_ART sigue al modo (los lectores antiguos la
// usan) y no se sale de un modo con existencias por lote o serie.
procedure TdmArticulos.PrepararTrazabilidadArticulo;
var
  oCampoModo: TField;
  oModoAnterior: TModoTrazabilidad;
  oModoNuevo: TModoTrazabilidad;
  sCodigo: string;
begin
  oCampoModo := unqryTablaG.FieldByName('TIPO_TRAZABILIDAD_ART');
  if Trim(oCampoModo.AsString) = '' then
    oCampoModo.AsString := MODO_TRAZABILIDAD_NINGUNA;
  oModoNuevo := ModoDesdeCadena(oCampoModo.AsString);
  oModoAnterior := oModoNuevo;
  if unqryTablaG.State = dsEdit then
    oModoAnterior := ModoDesdeCadena(VarToStr(oCampoModo.OldValue));
  sCodigo := VarToStr(unqryTablaG.FieldByName('CODIGO_ART_ART').OldValue);
  if (oModoAnterior <> oModoNuevo) and (oModoAnterior <> mtNinguna) and
     not PuedeCambiarModo(oModoAnterior, oModoNuevo,
                          HayStockConLote(sCodigo)) then
    raise EValidacionDatosArticulo.Create(cvaTrazabilidad,
      Format(SErrorCambioModoConStockLote,
             [sCodigo, TextoModoTrazabilidad(oModoAnterior),
              TextoModoTrazabilidad(oModoNuevo)]));
  unqryTablaG.FieldByName('ESTRAZABLE_ART').AsString :=
    ValorEsTrazable(oModoNuevo);
  // La caducidad obligatoria solo tiene sentido en LOTE.
  if (oModoNuevo <> mtLote) or
     (Trim(unqryTablaG.FieldByName('ESCADUCIDAD_ART').AsString) = '') then
    unqryTablaG.FieldByName('ESCADUCIDAD_ART').AsString := 'N';
end;

procedure TdmArticulos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  try
    ValidarDatosArticulo;
    if (DataSet.FieldByName('ESSERVICIO_REPARACION_ART').AsString = 'S')
       and (DataSet.FieldByName('TIPO_ART').AsString <> 'SERVICIO') then
      raise EValidacionBBDD.Create(SErrorMarcaArticuloReparacion);
    PrepararTrazabilidadArticulo;
    PrepararCambioTipoVariacion;
  except
    on E: EValidacionDatosArticulo do
    begin
      if Assigned(OnValidacionDatosArticulo) then
      begin
        OnValidacionDatosArticulo(E.Message, E.Campo);
        Abort;
      end
      else
        raise;
    end;
  end;
  PrepararCambioMarcaWeb;
  try
    inherited;
    // La barra separa atributos del SKU; se normaliza solo tras validar.
    QuitarBarraSkuCampo(DataSet, 'CODIGO_ART_ART');
    GetCodigoAutoArticulo;
    ValidarCodigoArticuloDisponible;
  except
    LimpiarCambioMarcaWebPreparado;
    raise;
  end;
end;

procedure TdmArticulos.AsignarPermisoCambioMarcaWeb(APermitido: Boolean);
begin
  FPermitirCambiarMarcaWeb := APermitido;
end;

procedure TdmArticulos.AsignarConfirmacionDesactivacionWeb(
  AConfirmacion: TConfirmarDesactivacionWebArticuloEvent);
begin
  FOnConfirmarDesactivacionWeb := AConfirmacion;
end;

procedure TdmArticulos.CapturarOEncolarVisibilidadPrestaShop(
  const ACodigoArticulo: string;
  AAccion: TAccionVisibilidadPrestaShop);
begin
  if FAplazarVisibilidadPrestaShop then
  begin
    FCodigoArticuloVisibilidadAplazada := ACodigoArticulo;
    FAccionVisibilidadAplazada := AAccion;
    FHayVisibilidadPrestaShopAplazada := True;
    FQuedaEnWebVisibilidadAplazada := SameText(
      unqryTablaG.FindField('ESWEB_ART').AsString,
      'S');
  end
  else
    EncolarVisibilidadPrestaShop(
      unqryTablaG.Connection,
      ACodigoArticulo,
      AAccion,
      IdentidadSesion.Usuario);
end;

procedure TdmArticulos.FinalizarVisibilidadPrestaShopAplazada(
  AExito: Boolean;
  const AMensajeError: string);
var
  Accion: TAccionVisibilidadPrestaShop;
begin
  try
    if FCodigoArticuloVisibilidadAplazada <> '' then
    begin
      Accion := avpNinguna;
      if FHayVisibilidadPrestaShopAplazada then
        Accion := FAccionVisibilidadAplazada;
      if AExito then
      begin
        if FHayVisibilidadPrestaShopAplazada then
          EncolarVisibilidadPrestaShop(
            unqryTablaG.Connection,
            FCodigoArticuloVisibilidadAplazada,
            Accion,
            IdentidadSesion.Usuario)
        else if not ReanudarPublicacionAplazadaPrestaShop(
          unqryTablaG.Connection,
          FCodigoArticuloVisibilidadAplazada,
          IdentidadSesion.Usuario) then
        begin
          if FQuedaEnWebVisibilidadAplazada then
            EncolarArticuloPrestaShop(
              unqryTablaG.Connection,
              FCodigoArticuloVisibilidadAplazada,
              IdentidadSesion.Usuario)
          else
            OmitirArticuloPrestaShop(
              unqryTablaG.Connection,
              FCodigoArticuloVisibilidadAplazada,
              IdentidadSesion.Usuario);
        end;
      end
      else if FQuedaEnWebVisibilidadAplazada then
        RegistrarPublicacionAplazadaPrestaShop(
          unqryTablaG.Connection,
          FCodigoArticuloVisibilidadAplazada,
          Accion,
          FHayVisibilidadPrestaShopAplazada,
          AMensajeError,
          IdentidadSesion.Usuario)
      else
        EncolarVisibilidadPrestaShop(
          unqryTablaG.Connection,
          FCodigoArticuloVisibilidadAplazada,
          Accion,
          IdentidadSesion.Usuario);
    end;
  finally
    DescartarVisibilidadPrestaShopAplazada;
  end;
end;

procedure TdmArticulos.IniciarAplazamientoVisibilidadPrestaShop;
begin
  DescartarVisibilidadPrestaShopAplazada;
  FAplazarVisibilidadPrestaShop := True;
end;

procedure TdmArticulos.ConfirmarVisibilidadPrestaShopAplazada;
begin
  try
    if FHayVisibilidadPrestaShopAplazada then
      EncolarVisibilidadPrestaShop(
        unqryTablaG.Connection,
        FCodigoArticuloVisibilidadAplazada,
        FAccionVisibilidadAplazada,
        IdentidadSesion.Usuario);
  finally
    DescartarVisibilidadPrestaShopAplazada;
  end;
end;

procedure TdmArticulos.DescartarVisibilidadPrestaShopAplazada;
begin
  FAccionVisibilidadAplazada := avpNinguna;
  FAplazarVisibilidadPrestaShop := False;
  FCodigoArticuloVisibilidadAplazada := '';
  FHayVisibilidadPrestaShopAplazada := False;
  FQuedaEnWebVisibilidadAplazada := False;
end;

procedure TdmArticulos.LimpiarCambioMarcaWebPreparado;
begin
  FAccionVisibilidadPendiente := avpNinguna;
  FCambioMarcaWebPreparado := False;
  FCodigoArticuloCambioWebPreparado := '';
  FMarcaWebAnteriorPreparada := False;
  FMarcaWebNuevaPreparada := False;
end;

function TdmArticulos.CambioMarcaWebPreparadoCoincide(
  const ACodigoArticulo: string;
  AEstabaMarcado, AQuedaMarcado: Boolean): Boolean;
begin
  Result := FCambioMarcaWebPreparado and
    SameText(
      FCodigoArticuloCambioWebPreparado,
      ACodigoArticulo) and
    (FMarcaWebAnteriorPreparada = AEstabaMarcado) and
    (FMarcaWebNuevaPreparada = AQuedaMarcado);
end;

function TdmArticulos.LeerCambioMarcaWeb(
  out ACodigoArticulo, ADescripcionArticulo: string;
  out AEstabaMarcado, AQuedaMarcado: Boolean): Boolean;
var
  CampoCodigo: TField;
  CampoDescripcion: TField;
  CampoWeb: TField;
begin
  ACodigoArticulo := '';
  ADescripcionArticulo := '';
  AEstabaMarcado := False;
  AQuedaMarcado := False;
  Result := unqryTablaG.State in [dsInsert, dsEdit];
  if Result then
  begin
    CampoWeb := unqryTablaG.FindField('ESWEB_ART');
    Result := Assigned(CampoWeb);
    if Result then
    begin
      AQuedaMarcado := SameText(Trim(CampoWeb.AsString), 'S');
      if unqryTablaG.State = dsEdit then
        AEstabaMarcado := SameText(
          Trim(VarToStr(CampoWeb.OldValue)),
          'S');
      CampoCodigo := unqryTablaG.FindField('CODIGO_ART_ART');
      if Assigned(CampoCodigo) then
        ACodigoArticulo := Trim(CampoCodigo.AsString);
      CampoDescripcion := unqryTablaG.FindField('DESCRIPCION_ART');
      if Assigned(CampoDescripcion) then
        ADescripcionArticulo := Trim(CampoDescripcion.AsString);
    end;
  end;
end;

procedure TdmArticulos.PrepararAccionCambioMarcaWeb(
  const ACodigoArticulo, ADescripcionArticulo: string;
  AEstabaMarcado, AQuedaMarcado: Boolean);
var
  Decision: TDecisionDesactivacionWebArticulo;
begin
  FMarcaWebAnteriorPreparada := AEstabaMarcado;
  FMarcaWebNuevaPreparada := AQuedaMarcado;
  FCodigoArticuloCambioWebPreparado := ACodigoArticulo;
  FAccionVisibilidadPendiente := avpNinguna;
  if AEstabaMarcado and (not AQuedaMarcado) then
  begin
    Decision := ddwSoloDejarDeSincronizar;
    if Assigned(FOnConfirmarDesactivacionWeb) then
      Decision := FOnConfirmarDesactivacionWeb(
        ACodigoArticulo,
        ADescripcionArticulo);
    case Decision of
      ddwDesactivarEnPrestaShop:
        FAccionVisibilidadPendiente := avpDesactivar;
      ddwCancelar:
        begin
          LimpiarCambioMarcaWebPreparado;
          Abort;
        end;
    end;
  end
  else if (not AEstabaMarcado) and AQuedaMarcado and
          Assigned(ParametrosApp) and
          ParametrosApp.GetBool(
            'appPrestaShopActivarArticulosAlMarcarWeb',
            False) then
    FAccionVisibilidadPendiente := avpActivar;
  FCambioMarcaWebPreparado := True;
end;

procedure TdmArticulos.PrepararCambioMarcaWeb;
var
  CodigoArticulo: string;
  DescripcionArticulo: string;
  EstabaMarcado: Boolean;
  QuedaMarcado: Boolean;
begin
  if LeerCambioMarcaWeb(
    CodigoArticulo,
    DescripcionArticulo,
    EstabaMarcado,
    QuedaMarcado) then
  begin
    if not CambioMarcaWebPreparadoCoincide(
      CodigoArticulo,
      EstabaMarcado,
      QuedaMarcado) then
    begin
      LimpiarCambioMarcaWebPreparado;
      ValidarCambioMarcaWeb(unqryTablaG);
      PrepararAccionCambioMarcaWeb(
        CodigoArticulo,
        DescripcionArticulo,
        EstabaMarcado,
        QuedaMarcado);
    end;
  end
  else
    LimpiarCambioMarcaWebPreparado;
end;

procedure TdmArticulos.ValidarCambioMarcaWeb(ADataSet: TDataSet);
var
  Campo: TField;
  Cambio: Boolean;
  EstabaMarcado: Boolean;
  QuedaMarcado: Boolean;
begin
  Campo := ADataSet.FindField('ESWEB_ART');
  if Assigned(Campo) then
  begin
    QuedaMarcado := SameText(Trim(Campo.AsString), 'S');
    Cambio := False;
    if ADataSet.State = dsInsert then
      Cambio := QuedaMarcado
    else if ADataSet.State = dsEdit then
    begin
      EstabaMarcado := SameText(
        Trim(VarToStr(Campo.OldValue)),
        'S');
      Cambio := EstabaMarcado <> QuedaMarcado;
    end;
    if Cambio and
       (not FPermitirCambiarMarcaWeb) then
      raise EDatabaseError.Create(
        SErrorPermisoCambiarMarcaWebArticulo);
  end;
end;

function TdmArticulos.PrepararClaveTarifa: Integer;
begin
  if unqryTarifasArticulos.State = dsInsert then
  begin
    unqryTarifasArticulos.FieldByName(
      'CODIGO_UNICO_ARTTAR').Required := False;
    unqryTarifasArticulos.FieldByName(
      'CODIGO_UNICO_ARTTAR').AutoGenerateValue := arAutoInc;
    Result := -1;
  end
  else
    Result := unqryTarifasArticulos.FieldByName(
      'CODIGO_UNICO_ARTTAR').AsInteger;
end;

procedure TdmArticulos.AplicarEstadoTarifaPorPrecio;
var
  PrecioAnterior: Double;
  PrecioNuevo: Double;
  EstaActiva: string;
  ValorAnterior: Variant;
begin
  PrecioNuevo := unqryTarifasArticulos.FieldByName(
    'PRECIO_SALIDA_ARTTAR').AsFloat;
  EstaActiva := unqryTarifasArticulos.FieldByName(
    'ESACTIVO_ARTTAR').AsString;
  if unqryTarifasArticulos.State = dsInsert then
  begin
    if PrecioNuevo = 0 then
      unqryTarifasArticulos.FieldByName(
        'ESACTIVO_ARTTAR').AsString := 'N';
  end
  else if unqryTarifasArticulos.State = dsEdit then
  begin
    ValorAnterior := unqryTarifasArticulos.FieldByName(
      'PRECIO_SALIDA_ARTTAR').OldValue;
    if VarIsNull(ValorAnterior) or VarIsEmpty(ValorAnterior) then
      PrecioAnterior := 0
    else
      PrecioAnterior := ValorAnterior;
    if (PrecioAnterior > 0) and (PrecioNuevo = 0) and
       (EstaActiva = 'S') and
       SolicitarConfirmacion(SPreguntaDesactivarTarifaSinPrecio) then
      unqryTarifasArticulos.FieldByName(
        'ESACTIVO_ARTTAR').AsString := 'N';
    if (PrecioAnterior = 0) and (PrecioNuevo > 0) and
       (EstaActiva = 'N') and
       SolicitarConfirmacion(SPreguntaActivarTarifaConPrecio) then
      unqryTarifasArticulos.FieldByName(
        'ESACTIVO_ARTTAR').AsString := 'S';
  end;
end;

procedure TdmArticulos.ValidarPeriodoTarifa(APk: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := ConexionPrincipal;
    Consulta.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_articulos_tarifas ' +
      ' WHERE CODIGO_ART_ARTTAR = :CODIGO_ART_ART' +
      '   AND CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR' +
      '   AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = :CODIGO_UNIDAD' +
      '   AND CODIGO_UNICO_ARTTAR <> :PK';
    Consulta.ParamByName('CODIGO_ART_ART').AsString :=
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    Consulta.ParamByName('CODIGO_TAR_ARTTAR').AsString :=
      unqryTarifasArticulos.FieldByName('CODIGO_TAR_ARTTAR').AsString;
    Consulta.ParamByName('CODIGO_UNIDAD').AsString :=
      unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
    Consulta.ParamByName('PK').AsInteger := APk;
    Consulta.Open;
    if not ExistePeriodoUnico(
      Consulta,
      unqryTarifasArticulos.FieldByName('FECHA_DESDE_ARTTAR'),
      unqryTarifasArticulos.FieldByName('FECHA_HASTA_ARTTAR')) then
    begin
      NotificarError(Format(
        SErrorTarifaFechasConcurrentes,
        [unqryTarifasArticulos.FieldByName(
          'CODIGO_UNIDAD_ARTTAR').AsString]));
      Abort;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TdmArticulos.ValidarCompraTarifa;
var
  oConsulta: TUniQuery;
  sProveedor: string;
begin
  if unqryTarifasArticulos.FieldByName(
       'PRECIO_COSTE_ARTTAR').AsFloat < 0 then
    raise EDatabaseError.Create(SErrorCosteTarifaNegativo);
  sProveedor := Trim(unqryTarifasArticulos.FieldByName(
    'CODIGO_PRV_ARTTAR').AsString);
  if sProveedor = '' then
    unqryTarifasArticulos.FieldByName('CODIGO_PRV_ARTTAR').Clear
  else
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_PRV_PRV FROM fza_proveedores ' +
        'WHERE CODIGO_PRV_PRV = :PROVEEDOR';
      oConsulta.ParamByName('PROVEEDOR').AsString := sProveedor;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EDatabaseError.Create(SErrorProveedorTarifaInexistente);
      unqryTarifasArticulos.FieldByName('CODIGO_PRV_ARTTAR').AsString :=
        oConsulta.FieldByName('CODIGO_PRV_PRV').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TdmArticulos.SanearDescuentoTarifa;
begin
  if (unqryTarifasArticulos.FieldByName(
        'PRECIO_FINAL_ARTTAR').AsFloat >
      unqryTarifasArticulos.FieldByName(
        'PRECIO_SALIDA_ARTTAR').AsFloat) or
     (unqryTarifasArticulos.FieldByName(
        'PRECIO_DTO_ARTTAR').AsFloat < 0) or
     (unqryTarifasArticulos.FieldByName(
        'PORCENTAJE_DTO_ARTTAR').AsFloat < 0) then
  begin
    unqryTarifasArticulos.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat :=
      unqryTarifasArticulos.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
    unqryTarifasArticulos.FieldByName('PRECIO_DTO_ARTTAR').AsFloat := 0;
    unqryTarifasArticulos.FieldByName(
      'PORCENTAJE_DTO_ARTTAR').AsFloat := 0;
  end;
end;

function TdmArticulos.CampoTarifaArticuloPrestaShopCambiado(
  DataSet: TDataSet): Boolean;

  function Cambio(const ACampo: string): Boolean;
  begin
    Result := not SameText(
      VarToStr(DataSet.FieldByName(ACampo).OldValue),
      VarToStr(DataSet.FieldByName(ACampo).Value));
  end;

begin
  Result := DataSet.State = dsInsert;
  if DataSet.State = dsEdit then
    Result :=
      Cambio('CODIGO_ART_ARTTAR') or
      Cambio('CODIGO_UNIDAD_ARTTAR') or
      Cambio('CODIGO_TAR_ARTTAR') or
      Cambio('ESACTIVO_ARTTAR') or
      Cambio('PRECIO_SALIDA_ARTTAR') or
      Cambio('PRECIO_FINAL_ARTTAR') or
      Cambio('PRECIO_DTO_ARTTAR') or
      Cambio('PORCENTAJE_DTO_ARTTAR') or
      Cambio('FECHA_DESDE_ARTTAR') or
      Cambio('FECHA_HASTA_ARTTAR');
end;

function TdmArticulos.EsTarifaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoActual, ACodigoAnterior: string): Boolean;
var
  sTarifaPrestaShop: string;
begin
  sTarifaPrestaShop := LeerCodigoTarifaPrestaShop(
    AConexion,
    IdentidadSesion.Usuario);
  Result := SameText(Trim(ACodigoActual), sTarifaPrestaShop) or
    SameText(Trim(ACodigoAnterior), sTarifaPrestaShop);
end;

procedure TdmArticulos.unqryTarifasArticulosBeforePost(DataSet: TDataSet);
var
  Clave: Integer;
  sTarifaAnterior: string;
begin
  FCodigoArticuloTarifaAnteriorPrestaShop := '';
  FEncolarPrecioTarifaPrestaShop := False;
  inherited;
  ValidarCompraTarifa;
  Clave := PrepararClaveTarifa;
  AplicarEstadoTarifaPorPrecio;
  ValidarPeriodoTarifa(Clave);
  SanearDescuentoTarifa;
  if unqryTarifasArticulos.State in [dsInsert, dsEdit] then
    ActualizarAuditoria(DataSet);
  sTarifaAnterior := '';
  if DataSet.State = dsEdit then
  begin
    FCodigoArticuloTarifaAnteriorPrestaShop := Trim(VarToStr(
      DataSet.FieldByName('CODIGO_ART_ARTTAR').OldValue));
    sTarifaAnterior := VarToStr(
      DataSet.FieldByName('CODIGO_TAR_ARTTAR').OldValue);
  end;
  FEncolarPrecioTarifaPrestaShop :=
    CampoTarifaArticuloPrestaShopCambiado(DataSet) and
    EsTarifaPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString,
      sTarifaAnterior);
end;

procedure TdmArticulos.unqryTarifasArticulosAfterPost(DataSet: TDataSet);
var
  sArticuloActual: string;
begin
  try
    IncorporarProveedorTarifa;
    if FEncolarPrecioTarifaPrestaShop then
    begin
      sArticuloActual := Trim(
        DataSet.FieldByName('CODIGO_ART_ARTTAR').AsString);
      EncolarPrecioPrestaShop(
        TUniQuery(DataSet).Connection,
        sArticuloActual,
        IdentidadSesion.Usuario);
      if (FCodigoArticuloTarifaAnteriorPrestaShop <> '') and
         (not SameText(
           FCodigoArticuloTarifaAnteriorPrestaShop,
           sArticuloActual)) then
        EncolarPrecioPrestaShop(
          TUniQuery(DataSet).Connection,
          FCodigoArticuloTarifaAnteriorPrestaShop,
          IdentidadSesion.Usuario);
    end;
  finally
    FCodigoArticuloTarifaAnteriorPrestaShop := '';
    FEncolarPrecioTarifaPrestaShop := False;
  end;
end;

procedure TdmArticulos.IncorporarProveedorTarifa;
var
  oConsulta: TUniQuery;
  sProveedor: string;
begin
  sProveedor := Trim(unqryTarifasArticulos.FieldByName(
    'CODIGO_PRV_ARTTAR').AsString);
  if sProveedor <> '' then
  begin
    if unqryProveedoresArticulos.Active then
      unqryProveedoresArticulos.CheckBrowseMode;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := unqryTarifasArticulos.Connection;
      oConsulta.SQL.Text := SQL_INCORPORAR_PROVEEDOR_TARIFA;
      oConsulta.ParamByName('ARTICULO').AsString :=
        unqryTarifasArticulos.FieldByName('CODIGO_ART_ARTTAR').AsString;
      oConsulta.ParamByName('PROVEEDOR').AsString := sProveedor;
      oConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      oConsulta.Execute;
      if (oConsulta.RowsAffected > 0) and
         unqryProveedoresArticulos.Active then
      begin
        unqryProveedoresArticulos.Close;
        unqryProveedoresArticulos.Open;
        unqryProveedoresArticulos.Locate('CODIGO_PRV_PRV', sProveedor, []);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TdmArticulos.unqryTarifasArticulosBeforeDelete(
  DataSet: TDataSet);
begin
  inherited;
  FCodigoArticuloTarifaBorrada := '';
  if EsTarifaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString,
    '') then
    FCodigoArticuloTarifaBorrada := Trim(
      DataSet.FieldByName('CODIGO_ART_ARTTAR').AsString);
end;

procedure TdmArticulos.unqryTarifasArticulosAfterDelete(
  DataSet: TDataSet);
begin
  try
    if FCodigoArticuloTarifaBorrada <> '' then
      EncolarPrecioPrestaShop(
        TUniQuery(DataSet).Connection,
        FCodigoArticuloTarifaBorrada,
        IdentidadSesion.Usuario);
  finally
    FCodigoArticuloTarifaBorrada := '';
  end;
end;

function TdmArticulos.ReconstruirStock: string;
var
  unqrySol: TUniQuery;
begin
  Result := '';
  unqrySol := TUniQuery.Create(nil);
  try
    unqrySol.Connection := ConexionPrincipal;
    unqrySol.SQL.Text := 'CALL PRC_RECALCULAR_STOCK()';
    unqrySol.Open;
    if not unqrySol.IsEmpty then
      Result := unqrySol.FieldByName('MENSAJE').AsString;
    unqrySol.Close;
    if (not ConexionPrincipal.InTransaction) and
       (not StartsText('ERROR', Result)) then
      SolicitarProcesadoPrestaShop;
  finally
    FreeAndNil(unqrySol);
  end;
end;

function TdmArticulos.ObtenerPrecioTarifaPadre(
  const aCodArt, aCodTarifa: string): Double;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    // Fila padre = misma tarifa, mismo artículo, sin SKU específico,
    // activa y vigente en la fecha actual.
    qry.SQL.Text :=
      'SELECT PRECIO_SALIDA_ARTTAR '                                       +
      '  FROM fza_articulos_tarifas '                                      +
      ' WHERE CODIGO_ART_ARTTAR = :ART '                                   +
      '   AND CODIGO_TAR_ARTTAR = :TAR '                                   +
      '   AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = '''' '                +
      '   AND ESACTIVO_ARTTAR = ''S'' '                                    +
      '   AND (FECHA_DESDE_ARTTAR IS NULL OR FECHA_DESDE_ARTTAR <= ' +
      'CURRENT_DATE) ' +
      '   AND (FECHA_HASTA_ARTTAR IS NULL OR FECHA_HASTA_ARTTAR >= ' +
      'CURRENT_DATE) ' +
      ' ORDER BY FECHA_DESDE_ARTTAR DESC '                                 +
      ' LIMIT 1';
    qry.ParamByName('ART').AsString := aCodArt;
    qry.ParamByName('TAR').AsString := aCodTarifa;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.CargarTarifasEtiquetas(items: TStrings;
                                              codigos: TStrings;
                                              var aIdxDefault: Integer);
var
  i: Integer;
begin
  items.Clear;
  codigos.Clear;
  aIdxDefault := -1;
  unqryTarifasPrint.Close;
  unqryTarifasPrint.Open;
  unqryTarifasPrint.First;
  i := 0;
  while not unqryTarifasPrint.Eof do
  begin
    items.Add(unqryTarifasPrint.FieldByName('NOMBRE_TAR_TAR').AsString);
    codigos.Add(unqryTarifasPrint.FieldByName('CODIGO_TAR_ARTTAR').AsString);
    if (aIdxDefault = -1) and
       SameText(unqryTarifasPrint.FieldByName('CODIGO_TAR_ARTTAR').AsString,
                ParametrosCaja.TarifaDefecto) then
      aIdxDefault := i;
    Inc(i);
    unqryTarifasPrint.Next;
  end;
  unqryTarifasPrint.Close;
  if (aIdxDefault = -1) and (items.Count > 0) then
    aIdxDefault := 0;
end;

procedure TdmArticulos.CargarAlmacenesEtiquetas(lst: TcxListView);
var
  Itm: TListItem;
begin
  lst.Clear;
  unqryAlmacenesPrint.Close;
  unqryAlmacenesPrint.Open;
  unqryAlmacenesPrint.First;
  while not unqryAlmacenesPrint.Eof do
  begin
    Itm := lst.Items.Add;
    Itm.Caption :=
                unqryAlmacenesPrint.FieldByName('CODIGO_ALM_ALM').AsString;
    Itm.SubItems.Add(
                unqryAlmacenesPrint.FieldByName('NOMBRE_ALM_ALM').AsString);
    unqryAlmacenesPrint.Next;
  end;
  unqryAlmacenesPrint.Close;
end;

procedure TdmArticulos.CrearDataSetEtiquetasArt(const aCodigoArt,
                                                      aCodTarifa,
                                                      aAlmacenesCsv: string;
                                                      aFechaTarifa: TDateTime;
                                                      const aSkusCsv: string);
var
  sSql, sFiltroAlm, FiltroPeriodicidad: string;
  Periodicidad: IRepositorioPeriodicidadTarifa;
  i: Integer;
  lstCod: TStringList;
begin
  // Limpia los codigos: solo aceptamos lo que el usuario haya marcado en el
  // checklist (que viene de fza_almacenes). Si la lista esta vacia, no
  // aplicamos filtro de almacen para no excluir cualquier stock.
  sFiltroAlm := '';
  if Trim(aAlmacenesCsv) <> '' then
  begin
    lstCod := TStringList.Create;
    try
      lstCod.StrictDelimiter := True;
      lstCod.Delimiter       := ',';
      lstCod.DelimitedText   := aAlmacenesCsv;
      // Construimos la lista IN. Como los codigos pueden contener apostrofos,
      // los duplicamos para evitar SQL injection aunque el origen sea
      // controlado.
      sFiltroAlm := '';
      for i := 0 to lstCod.Count - 1 do
      begin
        if Trim(lstCod[i]) <> '' then
        begin
          if sFiltroAlm <> '' then
            sFiltroAlm := sFiltroAlm + ',';
          sFiltroAlm := sFiltroAlm + QuotedStr(Trim(lstCod[i]));
        end;
      end;
    finally
      FreeAndNil(lstCod);
    end;
    if sFiltroAlm <> '' then
      sFiltroAlm := 'WHERE CODIGO_ALM_STK IN (' + sFiltroAlm + ')';
  end;

  sSql := StringReplace(cSqlEtiquetasArt, '{PRECIO_TARIFA}',
    SqlSeleccionPrecioTarifa('eti.CODIGO_ART_ART',
      'eti.CODIGO_UNIDAD_SKU', ':CODIGO_TAR_ARTTAR',
      ':FECHA_APLICACION'), [rfReplaceAll]);
  sSql := StringReplace(sSql, '{CAMPOS_PRECIO_UNIDAD}',
    SqlCamposPrecioUnidadEtiqueta, [rfReplaceAll]);
  FiltroPeriodicidad := '1 = 1';
  Periodicidad := CrearRepositorioPeriodicidadTarifa(
    unqryArtPrint.Connection);
  if Periodicidad.Disponible then
    FiltroPeriodicidad := SqlPeriodicidadTarifa(
      'tar.CODIGO_TAR_ARTTAR', ':FECHA_APLICACION');
  sSql := StringReplace(sSql, '{DESCUENTO_VIGENTE}',
    '(' + cSqlDescuentoVigenteEtiquetas + ' AND ' +
    FiltroPeriodicidad + ')', [rfReplaceAll]);
  sSql := StringReplace(sSql,
                        '%ALMACEN_FILTER%',
                        sFiltroAlm,
                        [rfReplaceAll]);
  // Filtro opcional por SKUs concretos (lo usa el modal de pegatinas de
  // albaranes / pedidos para reducir la query a los SKUs del documento).
  // El parser de SQL exige una lista literal — la construimos a partir
  // del CSV de entrada (codigos vienen de fza_albaranes_compra_lineas).
  if Trim(aSkusCsv) <> '' then
    sSql := StringReplace(sSql, '%SKU_FILTER%',
              'AND eti.CODIGO_UNIDAD_SKU IN (' + aSkusCsv + ')',
              [rfReplaceAll])
  else
    sSql := StringReplace(sSql, '%SKU_FILTER%', '', [rfReplaceAll]);

  unqryArtPrint.Close;
  unqryArtPrint.SQL.Text := sSql;
  unqryArtPrint.ParamByName('CODIGO_ART_ART').AsString    := aCodigoArt;
  unqryArtPrint.ParamByName('CODIGO_TAR_ARTTAR').AsString := aCodTarifa;
  unqryArtPrint.ParamByName('FECHA_APLICACION').AsDate    := aFechaTarifa;
  unqryArtPrint.Open;

  // Construimos el cdsEtiquetasArt copiando manualmente desde unqryArtPrint,
  // sin pasar por dtstprvEtiquetasArt. La ruta provider -> Data variant ->
  // cds lanzaba intermitentemente 'Missing data provider or data packet'
  // (TDataSetProvider con TUniQuery + JOINs complejos devolvia Variant
  // null), y a la vez nos da margen para anyadir el campo HEX_ATR_CO en
  // la misma pasada.
  PoblarCdsEtiquetasArtDesdeUniQuery;

  // Cuando el usuario marca almacenes, una etiqueta por unidad de stock:
  // se elimina cualquier SKU sin existencia en los almacenes elegidos y se
  // replica cada fila restante tantas veces como unidades tenga. Sin
  // almacenes marcados conservamos una sola etiqueta por SKU (el campo
  // STOCK_FILTRADO entonces refleja la suma global, que no es lo que el
  // usuario quiere para etiquetar).
  if Trim(aAlmacenesCsv) <> '' then
    ExpandirEtiquetasPorStock('STOCK_FILTRADO');

  cdsEtiquetasArt.First;
end;

procedure TdmArticulos.ExpandirEtiquetasPorStock(const aFldStock: string);
var
  i, j, k, iStock, iStockIdx, iOriginales: Integer;
  Filas: array of array of Variant;
begin
  if cdsEtiquetasArt.Active and (not cdsEtiquetasArt.IsEmpty) and
     (cdsEtiquetasArt.FindField(aFldStock) <> nil) then
  begin
    iStockIdx := cdsEtiquetasArt.FieldByName(aFldStock).Index;
    cdsEtiquetasArt.DisableControls;
    cdsEtiquetasArt.DisableConstraints;
    // Los campos del proveedor se hacen escribibles para reconstruirlos.
    for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
    begin
      cdsEtiquetasArt.Fields[j].ReadOnly := False;
      cdsEtiquetasArt.Fields[j].Required := False;
    end;
    try
      // Se vuelcan los originales y se replica cada fila por su stock.
      iOriginales := cdsEtiquetasArt.RecordCount;
      SetLength(Filas, iOriginales);
      cdsEtiquetasArt.First;
      for i := 0 to iOriginales - 1 do
      begin
        SetLength(Filas[i], cdsEtiquetasArt.FieldCount);
        for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
          Filas[i][j] := cdsEtiquetasArt.Fields[j].Value;
        cdsEtiquetasArt.Next;
      end;
      cdsEtiquetasArt.EmptyDataSet;
      for i := 0 to iOriginales - 1 do
      begin
        if not VarIsNull(Filas[i][iStockIdx]) then
        begin
          iStock := Trunc(Double(Filas[i][iStockIdx]));
          if iStock > 0 then
          begin
            for k := 1 to iStock do
            begin
              cdsEtiquetasArt.Append;
              for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
                cdsEtiquetasArt.Fields[j].Value := Filas[i][j];
              cdsEtiquetasArt.Post;
            end;
          end;
        end;
      end;
    finally
      cdsEtiquetasArt.EnableControls;
    end;
  end;
end;

procedure TdmArticulos.PoblarCdsEtiquetasArtDesdeUniQuery;
var
  oHexMap: TDictionary<string, TColorBasicoEtiqueta>;
  fldDef: TFieldDef;
  fdOrig: TFieldDef;
  sDiag: string;
  iCodSkuIdxOrig: Integer;
  k: Integer;
begin
  oHexMap := CargarMapaHexEtiquetas(
    unqryArtPrint.Connection,
    RegistroLog);
  try
    // 2) Reconstruir el cds desde cero copiando el esquema de unqryArtPrint
    //    + HEX_ATR_CO. Evita el TDataSetProvider, que con esta combinacion
    //    UniDAC + JOINs devuelve un Variant Null y dispara
    //    'Missing data provider or data packet' al activar el cds.
    cdsEtiquetasArt.Close;
    cdsEtiquetasArt.FieldDefs.Clear;
    if unqryArtPrint.Active then
    begin
      unqryArtPrint.FieldDefs.Update;
      // Copiamos FieldDef a FieldDef (en vez de FieldDefs.Assign) para poder
      // reconducir cada tipo al subconjunto que admite CreateDataSet. Las
      // columnas calculadas desde parametros (p.ej. :CODIGO_TAR_ARTTAR) y
      // algunos tipos de MariaDB llegan como tipos que el motor MIDAS no
      // soporta, y CreateDataSet abortaba con 'Invalid field type'.
      for k := 0 to unqryArtPrint.FieldDefs.Count - 1 do
      begin
        fdOrig            := unqryArtPrint.FieldDefs[k];
        fldDef            := cdsEtiquetasArt.FieldDefs.AddFieldDef;
        fldDef.Name       := fdOrig.Name;
        fldDef.DataType   := TipoSeguroCdsEtiquetas(fdOrig.DataType);
        fldDef.Required   := False;
        fldDef.Attributes := [];
        case fldDef.DataType of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
          begin
            // Texto largo (GROUP_CONCAT/TEXT) -> tamanyo holgado. Para el
            // resto usamos el del origen, pero acotado: las columnas de
            // parametros vacios vuelven con tamanyo 0 o desmesurado, y un
            // ftWideString gigante tambien hace fallar CreateDataSet.
            if fdOrig.DataType in [ftMemo, ftWideMemo, ftFmtMemo] then
              fldDef.Size := 8192
            else if (fdOrig.Size > 0) and (fdOrig.Size <= 8192) then
              fldDef.Size := fdOrig.Size
            else
              fldDef.Size := 255;
          end;
          ftFMTBcd:
          begin
            if fdOrig.Precision > 0 then
              fldDef.Precision := fdOrig.Precision
            else
              fldDef.Precision := 18;
            if (fdOrig.Size > 0) and (fdOrig.Size <= fldDef.Precision) then
              fldDef.Size := fdOrig.Size
            else
              fldDef.Size := 4;
          end;
        end;
      end;
    end;
    iCodSkuIdxOrig := cdsEtiquetasArt.FieldDefs.IndexOf('CODIGO_UNIDAD_SKU');
    for k := Low(cCamposColorBasicoEtiquetas) to
             High(cCamposColorBasicoEtiquetas) do
      if cdsEtiquetasArt.FieldDefs.IndexOf(
           cCamposColorBasicoEtiquetas[k]) < 0 then
      begin
        fldDef          := cdsEtiquetasArt.FieldDefs.AddFieldDef;
        fldDef.Name     := cCamposColorBasicoEtiquetas[k];
        fldDef.DataType := ftWideString;
        fldDef.Size     := cTamanyosColorBasicoEtiquetas[k];
      end;
    AgregarCamposPropiedadesEtiqueta(
      unqryArtPrint.Connection, cdsEtiquetasArt);
    // Red de seguridad: si pese al saneo MIDAS aun rechaza algun tipo,
    // dejamos constancia del esquema exacto en el log y reconstruimos todo
    // como texto para que el disenyador / impresion abran igualmente.
    try
      cdsEtiquetasArt.CreateDataSet;
    except
      on E: Exception do
      begin
        cdsEtiquetasArt.Close;
        sDiag := '';
        for k := 0 to cdsEtiquetasArt.FieldDefs.Count - 1 do
          sDiag := sDiag + cdsEtiquetasArt.FieldDefs[k].Name + ':' +
                   IntToStr(Ord(cdsEtiquetasArt.FieldDefs[k].DataType)) +
                   '(' + IntToStr(cdsEtiquetasArt.FieldDefs[k].Size) + ') ';
        if RegistroLog <> nil then
          RegistroLog.RegistrarError(
            'PoblarCdsEtiquetasArt: CreateDataSet fallo (' +
                       E.Message + '). Esquema: ' + sDiag);
        for k := 0 to cdsEtiquetasArt.FieldDefs.Count - 1 do
        begin
          cdsEtiquetasArt.FieldDefs[k].DataType := ftWideString;
          cdsEtiquetasArt.FieldDefs[k].Size     := 255;
        end;
        cdsEtiquetasArt.CreateDataSet;
      end;
    end;
    cdsEtiquetasArt.LogChanges := False;
    for k := 0 to cdsEtiquetasArt.FieldCount - 1 do
    begin
      cdsEtiquetasArt.Fields[k].ReadOnly := False;
      cdsEtiquetasArt.Fields[k].Required := False;
    end;

    CopiarFilasEtiquetas(
      unqryArtPrint,
      cdsEtiquetasArt,
      iCodSkuIdxOrig,
      oHexMap);
    // Aquí y no en quien llama: los modales de etiquetas repueblan el
    // dataset al aplicar guías y perdían el texto del precio por unidad.
    PrepararPreciosUnidadEtiquetas(cdsEtiquetasArt);
    CompletarPropiedadesEtiquetas(
      unqryArtPrint.Connection, cdsEtiquetasArt);
  finally
    FreeAndNil(oHexMap);
  end;
end;

procedure TdmArticulos.PrepararCodigosEtiquetasLotes(
  var ALotes: TLotesEtiquetas);
begin
  CompletarCodigosEtiquetasLotes(ConexionPrincipal, IdentidadSesion.Usuario,
    ParametrosApp, ALotes);
end;

initialization
  RegistrarDataModule(TdmArticulos);
  ForceReferenceToClass(TdmArticulos);

end.
