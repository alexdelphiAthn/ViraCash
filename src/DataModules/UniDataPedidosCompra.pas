{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataPedidosCompra                                          }
{    Tipo:       Data Module                                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Data module de pedidos de COMPRA.                                         }
{    Espejo simplificado de UniDataAlbaranesCompra. Diferencias clave:         }
{      - Numeracion con TIPO_DOC = 'PC' (vs 'AB' de albaranes).                }
{      - AfterPost de cabecera dispara GenerarPdteRecibirDesdePedido para      }
{        sincronizar fza_articulos_pdte_recibir con las lineas actuales.      }
{      - BeforeDelete de linea retira su pendiente exacto; AfterDelete        }
{        recalcula totales y regenera desde el estado persistido del pedido.  }
{      - NO genera movimientos de stock — el pedido es compromiso, no         }
{        entrada fisica. Los movs los genera el albaran cuando se cree        }
{        desde el pedido via inLibPedidosCompra.CrearAlbaranDesdePedido.      }
{******************************************************************************}
unit UniDataPedidosCompra;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Data.DB, Datasnap.DBClient, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser;

type
  TFilasEtiquetasPedido = TArray<TArray<Variant>>;

  TdmPedidosCompra = class(TdmBase)
    unqryPedidosCompraLineas: TUniQuery;
    dsPedidosCompraLineas:    TDataSource;
    unqryEmpDataPedc:         TUniQuery;
    unqryPrvDataPedc:         TUniQuery;
    dsPrvDataPedc:            TDataSource;
    unqrySkusPedc:            TUniQuery;
    unstrdprcGetContadorPedc: TUniStoredProc;
    unqryDefArticuloPedc:     TUniQuery;
    unqryTemporadasPedc:      TUniQuery;
    dsTemporadasPedc:         TDataSource;
    unqryAlbaranesPedc:       TUniQuery;
    dsAlbaranesPedc:          TDataSource;
    unqryFormasPago:          TUniQuery;
    dsFormasPago:             TDataSource;
    unqryAlmacenesPedc:       TUniQuery;
    dsAlmacenesPedc:          TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasAfterPost(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasAfterDelete(DataSet: TDataSet);
  private
    FCalculandoTotales: Boolean;
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal
    // (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    // >0 mientras el modo de entrada expande/consolida lineas en bloque
    // (una linea por SKU): totales y pendientes de recibir se posponen
    // a FinalizarReorganizacionLineas para no regenerarlos por linea.
    FReorganizandoLineas: Integer;
    FReorganizacionPendiente: Boolean;
    procedure CancelarLineaVaciaDiferida;
    procedure AsignarNumeroLineaPedidoCompra(DataSet: TDataSet);
    procedure RefrescarResumenPedidoCompra;
    procedure ConfigurarSqlCabecera;
    // Construye el SQLInsert contra fza_pedidos_compra: la vista
    // vi_pedidos_compra tiene columnas calculadas y no es insertable
    procedure ConfigurarSqlInsertCabecera;
    function ObtenerAlmacenesSql(const AAlmacenesCsv: string): string;
    function ObtenerSkusPedidoCsv(const ASerie, ANumero,
                                  AAlmacenesCsv: string): string;
    procedure ConfigurarConsultaCantidadCeldas(
      AConsulta: TUniQuery;
      const AAlmacenes: string);
    procedure AnadirConsultaCantidadLineas(
      AConsulta: TUniQuery;
      const AAlmacenes: string);
    procedure CargarCantidadesEtiquetas(
      const ASerie, ANumero, AAlmacenesCsv: string;
      ACantidades: TDictionary<string, Integer>);
    procedure PrepararCamposEtiquetas(
      ADataSet: TClientDataSet;
      out AIndiceSku, AIndiceStock: Integer);
    function CapturarFilasEtiquetas(
      ADataSet: TClientDataSet): TFilasEtiquetasPedido;
    procedure InsertarCopiasEtiquetas(
      ADataSet: TClientDataSet;
      const AFilas: TFilasEtiquetasPedido;
      AIndiceSku, AIndiceStock: Integer;
      ACantidades: TDictionary<string, Integer>);
    procedure ExpandirDataSetEtiquetas(
      ADataSet: TClientDataSet;
      ACantidades: TDictionary<string, Integer>);
    procedure CopiarEmpresaaPedidoCompra(DataSet: TDataSet);
    procedure ValidarAlmacenCabecera;
  public
    procedure GetCodigoAutoPedidoCompra;
    procedure CalcularTotalesPedidoCompra;
    // Unidades distintas de las lineas del pedido actual (FZ-ISSUE-235).
    function UnidadesLineasPedido: TArray<string>;
    // Bracket de reorganizacion masiva de lineas (construccion del modo
    // de entrada): entre Iniciar y Finalizar los posts de linea no
    // recalculan totales ni regeneran fza_articulos_pdte_recibir; se
    // hace UNA vez al Finalizar si hubo posts.
    procedure IniciarReorganizacionLineas;
    procedure FinalizarReorganizacionLineas;
    function EnReorganizacionLineas: Boolean;
    // Retira restos de la antigua entrada inline. Una celda sin su linea
    // maestra hacia fallar la invariante al cambiar de modo (6 -> 0 uds.).
    procedure LimpiarCeldasHuerfanasPedidoCompraActual;
    // True si el pedido enfocado tiene lineas con SKU sin celdas de
    // pivote: necesitan la primera fusion del modo tallas inline.
    function HayLineasSinPivotar: Boolean;
    // Cierra el bracket SIN recalculos ni reapertura del detalle (para
    // el teardown de FormDestroy, con el form muriendo). Devuelve True
    // si quedaron posts pospuestos (la expansion cambio lineas).
    function AbortarReorganizacionLineas: Boolean;
    // Regenera fza_articulos_pdte_recibir del pedido enfocado (borra y
    // reinserta): la expansion del teardown cambia la composicion de
    // lineas y los pendientes deben reflejarla.
    procedure SincronizarPdteRecibir;
    // Contrato ColumnSKUcxGrid: trocea CODIGO_UNIDAD_PEDCLIN en las
    // columnas reales ATTR1..5_VALOR_PEDCLIN + NUM_ATRIBUTOS_PEDCLIN
    // para el modo Desglose/Tallas. Idempotente por comparacion. No
    // hace nada si pedidos_compra_columnas_sku.sql no esta aplicado.
    procedure DesempaquetarAtributosLineas;
    function BuscarEmpresa(const ACodigo: string): Boolean;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure CargarAlmacenesDelPedido(const ASerie, ANumero: string;
                                       ALV: TObject);
    procedure CrearDataSetEtiquetasPed(ADmArt: TObject;
                                        const ASerie, ANumero,
                                              ACodTarifa,
                                              AAlmacenesCsv: string;
                                        AFecha: TDateTime);
    procedure ExpandirEtiquetasPorCantidadPed(ADmArt: TObject;
                                               const ASerie, ANumero,
                                                     AAlmacenesCsv: string);
    procedure OpenTables;
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
  private
    // Conexion por la que salen la transaccion, los bloqueos y las
    // lecturas de la operacion: la misma que usan los datasets.
    function ConexionEscritura: TUniConnection;
  end;

implementation

uses
  inLibLineaSku,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inLibContadorLineas, inLibDatasets,
  UniDataContadorLineasRepositorio,
  System.Diagnostics, System.UITypes,
  ComCtrls, cxListView,
  inLibPedidosCompra,
  UniDataPedidosCompraPendientes,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibData, UniDataAlmacenesEmpresaRepositorio,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  UniDataArticulos,
  inLibMsgCompras, inLibMsgVentas, inLibErroresBBDD,
  inLibDocumento, inLibDocumentoIntf,
  UniDataDatosProveedorDocumento;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ValidarAlmacenLineaPedidoCompra(ADataSet: TDataSet;
  AConexion: TUniConnection); forward;

function TdmPedidosCompra.ConexionEscritura: TUniConnection;
begin
  // Cada ventana de mantenimiento crea su propia conexion y reasigna a
  // ella los datasets (TdmBase.ReasignarConexion). La transaccion, los
  // SELECT ... FOR UPDATE y las lecturas de la operacion tienen que ir
  // por esa misma conexion: si salen por la conexion compartida, el
  // UPDATE del dataset acaba esperando un bloqueo que retiene el propio
  // programa desde otra conexion (MariaDB 1205, lock wait timeout).
  Result := nil;
  if Assigned(unqryTablaG) then
    Result := unqryTablaG.Connection;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
end;

procedure TdmPedidosCompra.ConfigurarSqlInsertCabecera;
const
  // Mismas columnas de fza_pedidos_compra que usa el SQLUpdate
  CAMPOS: string =
    'NUMERO_PEDC;SERIE_PEDC;FECHA_PEDC;FECHA_PREVISTA_PEDC;' +
    'FECHA_TOPE_RECEPCION_PEDC;ESTADO_PEDC;CODIGO_EMP_PEDC;' +
    'RAZON_SOCIAL_EMPRESA_PEDC;NIF_EMPRESA_PEDC;MOVIL_EMPRESA_PEDC;' +
    'EMAIL_EMPRESA_PEDC;DIRECCION1_EMPRESA_PEDC;DIRECCION2_EMPRESA_PEDC;' +
    'POBLACION_EMPRESA_PEDC;PROVINCIA_EMPRESA_PEDC;' +
    'CODIGO_PAI_EMPRESA_PEDC;NOMBRE_PAI_EMPRESA_PEDC;' +
    'CODIGO_POSTAL_EMPRESA_PEDC;CODIGO_PRV_PEDC;RAZON_SOCIAL_PRV_PEDC;' +
    'NIF_PRV_PEDC;MOVIL_PRV_PEDC;EMAIL_PRV_PEDC;DIRECCION1_PRV_PEDC;' +
    'DIRECCION2_PRV_PEDC;POBLACION_PRV_PEDC;PROVINCIA_PRV_PEDC;' +
    'CODIGO_PAI_PRV_PEDC;NOMBRE_PAI_PRV_PEDC;CODIGO_POSTAL_PRV_PEDC;' +
    'REF_PROVEEDOR_PEDC;CODIGO_ALM_PEDC;TRANSPORTISTA_PEDC;' +
    'CODIGO_IVA_PEDC;ESIVA_RECARGO_COMPRAS_PEDC;' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC;PORCENTAJE_IVAN_PEDC;' +
    'TOTAL_BASEI_IVAN_PEDC;TOTAL_IVAN_PEDC;PORCENTAJE_REN_PEDC;' +
    'TOTAL_REN_PEDC;PORCENTAJE_IVAR_PEDC;TOTAL_BASEI_IVAR_PEDC;' +
    'TOTAL_IVAR_PEDC;PORCENTAJE_RER_PEDC;TOTAL_RER_PEDC;' +
    'PORCENTAJE_IVAS_PEDC;TOTAL_BASEI_IVAS_PEDC;TOTAL_IVAS_PEDC;' +
    'PORCENTAJE_RES_PEDC;TOTAL_RES_PEDC;PORCENTAJE_IVAE_PEDC;' +
    'TOTAL_BASEI_IVAE_PEDC;TOTAL_IVAE_PEDC;PORCENTAJE_REE_PEDC;' +
    'TOTAL_REE_PEDC;TOTAL_BRUTO_PEDC;PORCENTAJE_DTO_COMERCIAL_PEDC;' +
    'TOTAL_DTO_COMERCIAL_PEDC;PORCENTAJE_DTO_FINANCIERO_PEDC;' +
    'TOTAL_DTO_FINANCIERO_PEDC;TOTAL_BASES_PEDC;TOTAL_IMPUESTOS_PEDC;' +
    'PORCENTAJE_RETENCION_PEDC;TOTAL_RETENCION_PEDC;TOTAL_LIQUIDO_PEDC;' +
    'FORMA_PAGO_PEDC;CONTADOR_LINEAS_PEDC;COMENTARIOS_PEDC;' +
    'OBSERVACIONES_PEDC;ESPIVOTE_HORIZONTAL_PEDC;INSTANTE_MODIF;' +
    'INSTANTE_ALTA;USUARIO_ALTA;USUARIO_MODIF;ID_PV_TEMPORADA_PEDC';
var
  lst: TStringList;
  sCols: string;
  sVals: string;
  i: Integer;
begin
  lst := TStringList.Create;
  try
    lst.Delimiter := ';';
    lst.StrictDelimiter := True;
    lst.DelimitedText := CAMPOS;
    sCols := '';
    sVals := '';
    for i := 0 to lst.Count - 1 do
    begin
      if sCols <> '' then
      begin
        sCols := sCols + ', ';
        sVals := sVals + ', ';
      end;
      sCols := sCols + lst[i];
      sVals := sVals + ':' + lst[i];
    end;
    unqryTablaG.SQLInsert.Text :=
      'INSERT INTO fza_pedidos_compra (' + sCols + ') ' + sLineBreak +
      'VALUES (' + sVals + ')';
  finally
    FreeAndNil(lst);
  end;
end;

procedure TdmPedidosCompra.ConfigurarSqlCabecera;
begin
  ConfigurarSqlInsertCabecera;
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_pedidos_compra ' + sLineBreak +
    'WHERE NUMERO_PEDC = :Old_NUMERO_PEDC ' + sLineBreak +
    '  AND SERIE_PEDC = :Old_SERIE_PEDC';
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_pedidos_compra ' + sLineBreak +
    '   SET NUMERO_PEDC = :NUMERO_PEDC, ' + sLineBreak +
    '       SERIE_PEDC = :SERIE_PEDC, ' + sLineBreak +
    '       FECHA_PEDC = :FECHA_PEDC, ' + sLineBreak +
    '       FECHA_PREVISTA_PEDC = :FECHA_PREVISTA_PEDC, ' + sLineBreak +
    '       FECHA_TOPE_RECEPCION_PEDC = :FECHA_TOPE_RECEPCION_PEDC, ' +
      sLineBreak +
    '       ESTADO_PEDC = :ESTADO_PEDC, ' + sLineBreak +
    '       CODIGO_EMP_PEDC = :CODIGO_EMP_PEDC, ' + sLineBreak +
    '       RAZON_SOCIAL_EMPRESA_PEDC = :RAZON_SOCIAL_EMPRESA_PEDC, ' +
      sLineBreak +
    '       NIF_EMPRESA_PEDC = :NIF_EMPRESA_PEDC, ' + sLineBreak +
    '       MOVIL_EMPRESA_PEDC = :MOVIL_EMPRESA_PEDC, ' + sLineBreak +
    '       EMAIL_EMPRESA_PEDC = :EMAIL_EMPRESA_PEDC, ' + sLineBreak +
    '       DIRECCION1_EMPRESA_PEDC = :DIRECCION1_EMPRESA_PEDC, ' +
      sLineBreak +
    '       DIRECCION2_EMPRESA_PEDC = :DIRECCION2_EMPRESA_PEDC, ' +
      sLineBreak +
    '       POBLACION_EMPRESA_PEDC = :POBLACION_EMPRESA_PEDC, ' + sLineBreak +
    '       PROVINCIA_EMPRESA_PEDC = :PROVINCIA_EMPRESA_PEDC, ' +
      sLineBreak +
    '       CODIGO_PAI_EMPRESA_PEDC = :CODIGO_PAI_EMPRESA_PEDC, ' +
      sLineBreak +
    '       NOMBRE_PAI_EMPRESA_PEDC = :NOMBRE_PAI_EMPRESA_PEDC, ' +
      sLineBreak +
    '       CODIGO_POSTAL_EMPRESA_PEDC = :CODIGO_POSTAL_EMPRESA_PEDC, ' +
      sLineBreak +
    '       CODIGO_PRV_PEDC = :CODIGO_PRV_PEDC, ' + sLineBreak +
    '       RAZON_SOCIAL_PRV_PEDC = :RAZON_SOCIAL_PRV_PEDC, ' + sLineBreak +
    '       NIF_PRV_PEDC = :NIF_PRV_PEDC, ' + sLineBreak +
    '       MOVIL_PRV_PEDC = :MOVIL_PRV_PEDC, ' + sLineBreak +
    '       EMAIL_PRV_PEDC = :EMAIL_PRV_PEDC, ' + sLineBreak +
    '       DIRECCION1_PRV_PEDC = :DIRECCION1_PRV_PEDC, ' + sLineBreak +
    '       DIRECCION2_PRV_PEDC = :DIRECCION2_PRV_PEDC, ' + sLineBreak +
    '       POBLACION_PRV_PEDC = :POBLACION_PRV_PEDC, ' + sLineBreak +
    '       PROVINCIA_PRV_PEDC = :PROVINCIA_PRV_PEDC, ' + sLineBreak +
    '       CODIGO_PAI_PRV_PEDC = :CODIGO_PAI_PRV_PEDC, ' + sLineBreak +
    '       NOMBRE_PAI_PRV_PEDC = :NOMBRE_PAI_PRV_PEDC, ' + sLineBreak +
    '       CODIGO_POSTAL_PRV_PEDC = :CODIGO_POSTAL_PRV_PEDC, ' +
      sLineBreak +
    '       REF_PROVEEDOR_PEDC = :REF_PROVEEDOR_PEDC, ' + sLineBreak +
    '       CODIGO_ALM_PEDC = :CODIGO_ALM_PEDC, ' + sLineBreak +
    '       TRANSPORTISTA_PEDC = :TRANSPORTISTA_PEDC, ' + sLineBreak +
    '       CODIGO_IVA_PEDC = :CODIGO_IVA_PEDC, ' + sLineBreak +
    '       ESIVA_RECARGO_COMPRAS_PEDC = :ESIVA_RECARGO_COMPRAS_PEDC, ' +
      sLineBreak +
    '       ESIVA_EXENTO_INTRACOMUNITARIO_PEDC = ' +
      ':ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAN_PEDC = :PORCENTAJE_IVAN_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAN_PEDC = :TOTAL_BASEI_IVAN_PEDC, ' + sLineBreak +
    '       TOTAL_IVAN_PEDC = :TOTAL_IVAN_PEDC, ' + sLineBreak +
    '       PORCENTAJE_REN_PEDC = :PORCENTAJE_REN_PEDC, ' + sLineBreak +
    '       TOTAL_REN_PEDC = :TOTAL_REN_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAR_PEDC = :PORCENTAJE_IVAR_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAR_PEDC = :TOTAL_BASEI_IVAR_PEDC, ' + sLineBreak +
    '       TOTAL_IVAR_PEDC = :TOTAL_IVAR_PEDC, ' + sLineBreak +
    '       PORCENTAJE_RER_PEDC = :PORCENTAJE_RER_PEDC, ' + sLineBreak +
    '       TOTAL_RER_PEDC = :TOTAL_RER_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAS_PEDC = :PORCENTAJE_IVAS_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAS_PEDC = :TOTAL_BASEI_IVAS_PEDC, ' + sLineBreak +
    '       TOTAL_IVAS_PEDC = :TOTAL_IVAS_PEDC, ' + sLineBreak +
    '       PORCENTAJE_RES_PEDC = :PORCENTAJE_RES_PEDC, ' + sLineBreak +
    '       TOTAL_RES_PEDC = :TOTAL_RES_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAE_PEDC = :PORCENTAJE_IVAE_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAE_PEDC = :TOTAL_BASEI_IVAE_PEDC, ' + sLineBreak +
    '       TOTAL_IVAE_PEDC = :TOTAL_IVAE_PEDC, ' + sLineBreak +
    '       PORCENTAJE_REE_PEDC = :PORCENTAJE_REE_PEDC, ' + sLineBreak +
    '       TOTAL_REE_PEDC = :TOTAL_REE_PEDC, ' + sLineBreak +
    '       TOTAL_BRUTO_PEDC = :TOTAL_BRUTO_PEDC, ' + sLineBreak +
    '       PORCENTAJE_DTO_COMERCIAL_PEDC = ' +
      ':PORCENTAJE_DTO_COMERCIAL_PEDC, ' + sLineBreak +
    '       TOTAL_DTO_COMERCIAL_PEDC = :TOTAL_DTO_COMERCIAL_PEDC, ' +
      sLineBreak +
    '       PORCENTAJE_DTO_FINANCIERO_PEDC = ' +
      ':PORCENTAJE_DTO_FINANCIERO_PEDC, ' + sLineBreak +
    '       TOTAL_DTO_FINANCIERO_PEDC = :TOTAL_DTO_FINANCIERO_PEDC, ' +
      sLineBreak +
    '       TOTAL_BASES_PEDC = :TOTAL_BASES_PEDC, ' + sLineBreak +
    '       TOTAL_IMPUESTOS_PEDC = :TOTAL_IMPUESTOS_PEDC, ' + sLineBreak +
    '       PORCENTAJE_RETENCION_PEDC = :PORCENTAJE_RETENCION_PEDC, ' +
      sLineBreak +
    '       TOTAL_RETENCION_PEDC = :TOTAL_RETENCION_PEDC, ' + sLineBreak +
    '       TOTAL_LIQUIDO_PEDC = :TOTAL_LIQUIDO_PEDC, ' + sLineBreak +
    '       FORMA_PAGO_PEDC = :FORMA_PAGO_PEDC, ' + sLineBreak +
    '       COMENTARIOS_PEDC = :COMENTARIOS_PEDC, ' + sLineBreak +
    '       OBSERVACIONES_PEDC = :OBSERVACIONES_PEDC, ' + sLineBreak +
    '       ESPIVOTE_HORIZONTAL_PEDC = :ESPIVOTE_HORIZONTAL_PEDC, ' +
      sLineBreak +
    '       INSTANTE_MODIF = :INSTANTE_MODIF, ' + sLineBreak +
    '       INSTANTE_ALTA = :INSTANTE_ALTA, ' + sLineBreak +
    '       USUARIO_ALTA = :USUARIO_ALTA, ' + sLineBreak +
    '       USUARIO_MODIF = :USUARIO_MODIF, ' + sLineBreak +
    '       ID_PV_TEMPORADA_PEDC = :ID_PV_TEMPORADA_PEDC ' + sLineBreak +
    ' WHERE NUMERO_PEDC = :Old_NUMERO_PEDC ' + sLineBreak +
    '   AND SERIE_PEDC = :Old_SERIE_PEDC';
  unqryTablaG.SQLRefresh.Text :=
    'SELECT * ' + sLineBreak +
    '  FROM vi_pedidos_compra ' + sLineBreak +
    ' WHERE NUMERO_PEDC = :NUMERO_PEDC ' + sLineBreak +
    '   AND SERIE_PEDC = :SERIE_PEDC';
end;

procedure TdmPedidosCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // FZ-ISSUE-154: el borrado de la cabecera, todo o nada.
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  unqryTablaG.Connection              := ConexionPrincipal;
  unqryTablaG.KeyFields               := 'NUMERO_PEDC;SERIE_PEDC';
  ConfigurarSqlCabecera;
  unqryPedidosCompraLineas.Connection := ConexionPrincipal;
  unqryEmpDataPedc.Connection         := ConexionPrincipal;
  unqryPrvDataPedc.Connection         := ConexionPrincipal;
  // Lookup completo de proveedores (NOMBRE_PRV + RAZON_SOCIAL_PRV) para
  // el rotulo resuelto de la cabecera y para el combo de busqueda
  // incremental por codigo (cbbCODIGO_PRV_PEDC). Se abre una vez y se
  // recorre con Locate; no depende del proveedor del pedido en pantalla.
  unqryPrvDataPedc.Open;
  unqrySkusPedc.Connection            := ConexionPrincipal;
  unstrdprcGetContadorPedc.Connection := ConexionPrincipal;
  unqryDefArticuloPedc.Connection     := ConexionPrincipal;
  unqryTemporadasPedc.Connection      := ConexionPrincipal;
  unqryTemporadasPedc.Open;
  unqryFormasPago.Connection          := ConexionPrincipal;
  unqryAlmacenesPedc.Connection       := ConexionPrincipal;
  unqryAlbaranesPedc.Connection := ConexionPrincipal;
  VigilarTotalMaximoLinea(unqryPedidosCompraLineas, 'TOTAL_PEDCLIN');
end;

procedure TdmPedidosCompra.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryPedidosCompraLineas.MasterSource := ADataSource;
  // Albaranes de compra creados desde este pedido (master-detail por
  // NUMERO_PED_ALBC / SERIE_PED_ALBC). Solo lectura, para la pestania.
  unqryAlbaranesPedc.MasterSource := ADataSource;
end;

procedure TdmPedidosCompra.DataModuleDestroy(Sender: TObject);
begin
  TThread.RemoveQueuedEvents(CancelarLineaVaciaDiferida);
  if Assigned(unqryPedidosCompraLineas) and
     unqryPedidosCompraLineas.Active then
    unqryPedidosCompraLineas.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryAlmacenesPedc) and unqryAlmacenesPedc.Active then
    unqryAlmacenesPedc.Close;
  inherited;
end;

procedure TdmPedidosCompra.CancelarLineaVaciaDiferida;
var
  oArticulo, oSku: TField;
begin
  if not (csDestroying in ComponentState) and
     Assigned(unqryPedidosCompraLineas) and
     unqryPedidosCompraLineas.Active and
     (unqryPedidosCompraLineas.State in dsEditModes) then
  begin
    oArticulo := unqryPedidosCompraLineas.FindField(
      'CODIGO_ART_PEDCLIN');
    oSku := unqryPedidosCompraLineas.FindField(
      'CODIGO_UNIDAD_PEDCLIN');
    if (oArticulo <> nil) and (oSku <> nil) and
       (Trim(oArticulo.AsString) = '') and
       (Trim(oSku.AsString) = '') then
      unqryPedidosCompraLineas.Cancel;
  end;
end;

procedure TdmPedidosCompra.OpenTables;
begin
  AbrirDetalles;
end;

procedure TdmPedidosCompra.RefrescarAlmacenes(
  const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesPedc.Active) or
     (not SameText(unqryAlmacenesPedc.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesPedc.Close;
    unqryAlmacenesPedc.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesPedc.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_PEDC', 'CODIGO_ALM_PEDC');
end;

procedure TdmPedidosCompra.AbrirDetalles;
const
  TAG = 'PedidosCompra.AbrirDetalles';
var
  sw, swQ: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  if not unqryPedidosCompraLineas.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryPedidosCompraLineas.Open;
      RegistroLog.RegistrarRendimiento(TAG, 'unqryPedidosCompraLineas OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento(TAG,
          'unqryPedidosCompraLineas ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  if not unqryAlbaranesPedc.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryAlbaranesPedc.Open;
      RegistroLog.RegistrarRendimiento(TAG, 'unqryAlbaranesPedc OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento(TAG,
          'unqryAlbaranesPedc ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  if not unqryFormasPago.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryFormasPago.Open;
      RegistroLog.RegistrarRendimiento(TAG, 'unqryFormasPago OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento(TAG,
          'unqryFormasPago ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  if not unqryAlmacenesPedc.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryAlmacenesPedc.Open;
      RegistroLog.RegistrarRendimiento(TAG, 'unqryAlmacenesPedc OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento(TAG,
          'unqryAlmacenesPedc ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmPedidosCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('NUMERO_PEDC').AsString := '0';
    sSerie := ObtenerSerieDefecto(
      ConexionEscritura,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdPedido, sdCompra).TipoContador);
    if FindField('SERIE_PEDC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_PEDC').AsString := sSerie
      else
        FieldByName('SERIE_PEDC').AsString := 'C1';
    end;
    FieldByName('FECHA_PEDC').AsDateTime := Date;
    if FindField('ESTADO_PEDC') <> nil then
      FieldByName('ESTADO_PEDC').AsString := 'ABIERTO';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_PEDC').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_PEDC').AsString := '0';
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
    if FindField('CODIGO_ALM_PEDC') <> nil then
      FieldByName('CODIGO_ALM_PEDC').AsString := UbicacionSesion.Almacen;
    FieldByName('CODIGO_PRV_PEDC').AsString := '0';
    if FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_PEDC') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_PEDC').AsString := 'N';
    AplicarRecargoComprasEmpresa(
      CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
      'CODIGO_EMP_PEDC', 'ESIVA_RECARGO_COMPRAS_PEDC');
  AplicarPorcentajesIvaCompra(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
    'PEDC');
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_PEDC').AsString);
end;

function TdmPedidosCompra.BuscarEmpresa(const ACodigo: string): Boolean;
var
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    if not unqryEmpDataPedc.Active then
      unqryEmpDataPedc.Open;
    if unqryEmpDataPedc.Locate('CODIGO_EMP_EMP', sCodigo, []) then
    begin
      CopiarEmpresaaPedidoCompra(unqryEmpDataPedc);
      Result := True;
    end;
  end;
end;

procedure TdmPedidosCompra.CopiarEmpresaaPedidoCompra(DataSet: TDataSet);
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_EMP_PEDC').AsString :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_PEDC').AsString :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_PEDC').AsString :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_PEDC').AsString :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_PEDC').AsString :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_PEDC').AsString :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_PEDC').AsString :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_PEDC').AsString :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
  FindField('CODIGO_POSTAL_EMPRESA_PEDC').AsString :=
    DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
end;

procedure TdmPedidosCompra.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_PEDC') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString) = '') then
  begin
    NotificarAdvertencia(
      SAvisoAlmacenDestinoPedidoCompraObligatorio);
    Abort;
  end;
end;

procedure TdmPedidosCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  i: Integer;
begin
  inherited;
  // Los campos calculados de vi_pedidos_compra (CANTIDAD_PEDIDA_PEDC,
  // TOTAL_LINEAS_PEDC...) llegan NOT NULL sin default y UniDAC los marca
  // Required: en el alta manual bloquean el Post con "must have a value".
  // No pertenecen a fza_pedidos_compra, asi que se apagan aqui (mismo
  // cinturon que usa Inventarios en su BeforePost).
  for i := 0 to DataSet.FieldCount - 1 do
    DataSet.Fields[i].Required := False;
  // En alta manual el pivote arranca vertical; se activa tras elegir
  // una linea con sistema de tallas.
  if (DataSet.FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil) and
     (Trim(DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString) = '') then
    DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString := 'N';
  // FZ-ISSUE-249: datos del proveedor en la cabecera, como los de empresa.
  CopiarDatosProveedorDocumento(DataSet, 'PEDC');
  ValidarAlmacenCabecera;
  if (unqryTablaG.FieldByName('NUMERO_PEDC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PEDC').AsString = '') then
    GetCodigoAutoPedidoCompra;
  AplicarPorcentajesIvaCompra(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
    'PEDC');
  CalcularTotalesPedidoCompra;
end;

procedure TdmPedidosCompra.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  // Sincronizar pendientes de recibir: borra y reinserta todas las
  // filas del pedido en fza_articulos_pdte_recibir. Aqui ya tenemos
  // la cabecera persistida en BBDD asi que la lectura de las lineas
  // ve el estado real.
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  if (sSerie <> '') and (sNumero <> '') then
  begin
    // Reorganizacion en bloque en curso: se pospone al Finalizar.
    if FReorganizandoLineas > 0 then
      FReorganizacionPendiente := True
    else
      CrearPendientesPedidoCompraUniDAC(
        ConexionEscritura).GenerarPdteRecibirDesdePedido(
          sSerie, sNumero, IdentidadSesion.Usuario);
  end;
end;

procedure TdmPedidosCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  sSerie, sNumero: string;
  q: TUniQuery;
begin
  inherited;
  // Limpiar pendientes de recibir antes de borrar la cabecera para no
  // dejar filas huerfanas. Las lineas las borra el ON DELETE CASCADE
  // (no aplica aqui: no hay FK) — bueno, simplemente las lineas se
  // pueden quedar tambien huerfanas. Las borramos a mano.
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  if (sSerie <> '') and (sNumero <> '') then
  begin
    if not SolicitarConfirmacion(
      Format(SPreguntaBorrarPedidoCompra,
        [sSerie, sNumero])) then
    begin
      Abort;
    end;
    IniciarBorradoTransaccional;
    try
      CrearPendientesPedidoCompraUniDAC(
        ConexionEscritura).BorrarPdteRecibirDesdePedido(
          sSerie, sNumero);
      // Borrar lineas asociadas para evitar registros huerfanos.
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionEscritura;
        q.SQL.Text :=
          'DELETE FROM fza_pedidos_compra_lineas ' +
          ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
          '   AND NUMERO_PEDC_PEDCLIN = :n';
        q.ParamByName('s').AsString := sSerie;
        q.ParamByName('n').AsString := sNumero;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
    except
      RevertirBorradoTransaccional;
      raise;
    end;
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
var
  i: Integer;
  oCampo: TField;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryPedidosCompraLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryPedidosCompraLineas.FindField(ANombre);
  end;
  procedure InicializarTexto(const ANombreCampo: string);
  begin
    oCampo := FindField(ANombreCampo);
    if Assigned(oCampo) and oCampo.IsNull then
      oCampo.AsString := '';
  end;
begin
  inherited;
  FieldByName('NUMERO_PEDC_PEDCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
    FieldByName('SERIE_PEDC_PEDCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    // Sin numero hasta grabar: el BeforePost asigna el definitivo con
    // el contador de lineas. Un 0000 parecia un error (FZ-ISSUE-224).
    FieldByName('LINEA_PEDCLIN').Clear;
    FieldByName('CANTIDAD_PEDCLIN').AsFloat := 1;
    FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat := 0;
    // NOT NULL DEFAULT 0 en BBDD pero UniDAC la marca Required: sin
    // inicializarla, el Post de una linea nueva casca con "Field
    // CANTIDAD_A_RECIBIR_PEDCLIN must have a value" (p.ej. el post
    // forzado del detalle al grabar la cabecera al salir).
    if FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil then
      FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat := 0;
    // Por defecto la linea hereda el almacen de la cabecera; el usuario
    // puede sobreescribirlo si quiere mezclar lineas de varios almacenes.
    if FindField('CODIGO_ALMACEN_PEDCLIN') <> nil then
      FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString :=
        unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
    // La base de datos tiene defaults, pero UniDAC comprueba Required
    // antes de enviarlos. Inicializarlos evita el Post incompleto al elegir
    // articulo/color desde el grid horizontal.
    oCampo := FindField('NUM_ATRIBUTOS_PEDCLIN');
    if Assigned(oCampo) and oCampo.IsNull then
      oCampo.AsInteger := 0;
    for i := 1 to 5 do
    begin
      InicializarTexto('ATTR' + IntToStr(i) + '_VALOR_PEDCLIN');
      InicializarTexto('ATTR' + IntToStr(i) + '_NOMBRE_PEDCLIN');
    end;
    FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
  FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryPedidosCompraLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryPedidosCompraLineas.FindField(ANombre);
  end;
begin
  inherited;
  // Desempaquetado ATTR en curso: post descriptivo, sin logica fiscal.
  if not FDesempaquetandoAtributos then
  begin
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, se
  // descarta con Cancel diferido + Abort en vez de grabar una linea basura
  // (y disparar en AfterPost un pendiente-de-recibir bogus). Mismo patron
  // que albaranes / sesiones de compra.
  if (Trim(unqryPedidosCompraLineas.FieldByName(
             'CODIGO_ART_PEDCLIN').AsString) = '') and
     (Trim(unqryPedidosCompraLineas.FieldByName(
             'CODIGO_UNIDAD_PEDCLIN').AsString) = '') then
  begin
    TThread.RemoveQueuedEvents(CancelarLineaVaciaDiferida);
    TThread.ForceQueue(nil, CancelarLineaVaciaDiferida);
    Abort;
  end;
  AsignarNumeroLineaPedidoCompra(DataSet);
  // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
  NormalizarArticuloSkuEnDataSet(ConexionEscritura,
      unqryPedidosCompraLineas, 'CODIGO_ART_PEDCLIN',
      'CODIGO_UNIDAD_PEDCLIN');
  // FZ-ISSUE-520: no se pide un SKU dado de baja.
  ExigirSkuActivoEnDataSet(ConexionEscritura, unqryPedidosCompraLineas,
    'CODIGO_ART_PEDCLIN', 'CODIGO_UNIDAD_PEDCLIN', SErrorSkuCompraNoActivo);
    if (FindField('CANTIDAD_PEDCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN') <> nil) and
       (FindField('TOTAL_PEDCLIN') <> nil) then
      FieldByName('TOTAL_PEDCLIN').AsFloat :=
        FieldByName('CANTIDAD_PEDCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString   := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
    if (DataSet.State = dsInsert) then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
      if (FindField('INSTANTE_ALTA') <> nil) and
         FieldByName('INSTANTE_ALTA').IsNull then
        FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    end;
    // Si tecleo SKU pero no articulo, lo deducimos via fza_articulos_skus.
    if (FindField('CODIGO_UNIDAD_PEDCLIN') <> nil) and
       (FindField('CODIGO_ART_PEDCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_PEDCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusPedc.Close;
        unqrySkusPedc.ParamByName('pSKU').AsString := sSku;
        unqrySkusPedc.Open;
        if not unqrySkusPedc.Eof then
          FieldByName('CODIGO_ART_PEDCLIN').AsString :=
            unqrySkusPedc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusPedc.Close;
      end;
    end;
  ValidarAlmacenLineaPedidoCompra(DataSet, ConexionEscritura);
  PrepararLineaFiscalCompra(CrearLecturasImpuestos(ConexionEscritura),
    unqryTablaG,
    unqryPedidosCompraLineas, 'PEDC', 'PEDCLIN', 'TOTAL_PEDCLIN');
  end;
end;

// La recepcion da la entrada en el almacen de la linea: un codigo
// inexistente (texto libre, '1,005') no puede grabarse (FZ-ISSUE-239).
procedure ValidarAlmacenLineaPedidoCompra(ADataSet: TDataSet;
  AConexion: TUniConnection);
var
  oCampo: TField;
  oConsulta: TUniQuery;
  sAlmacen: string;
begin
  oCampo := ADataSet.FindField('CODIGO_ALMACEN_PEDCLIN');
  if oCampo <> nil then
    sAlmacen := Trim(oCampo.AsString)
  else
    sAlmacen := '';
  if sAlmacen <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 FROM fza_almacenes WHERE CODIGO_ALM_ALM = :ALM';
      oConsulta.ParamByName('ALM').AsString := sAlmacen;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EValidacionBBDD.CreateFmt(
          SErrorAlmacenLineaPedidoCompraNoExiste,
          [ADataSet.FieldByName('LINEA_PEDCLIN').AsString, sAlmacen]);
    finally
      oConsulta.Free;
    end;
  end;
end;

procedure TdmPedidosCompra.AsignarNumeroLineaPedidoCompra(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_PEDCLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_PEDCLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PEDC').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_PEDC').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
          LIN_PEDIDOS_COMPRA, sSerie,
          sNumero, sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraPedidoSinGrabar);
      if DataSet.FindField('NUMERO_PEDC_PEDCLIN') <> nil then
        DataSet.FieldByName('NUMERO_PEDC_PEDCLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_PEDC_PEDCLIN') <> nil then
        DataSet.FieldByName('SERIE_PEDC_PEDCLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionEscritura),
        CONT_PEDIDOS_COMPRA, LIN_PEDIDOS_COMPRA, sSerie, sNumero);
      if iNuevaLinea = 0 then
      begin
        iNuevaLinea := StrToIntDef(
          unqryTablaG.FieldByName('CONTADOR_LINEAS_PEDC').AsString, 0) + 10;
      end;
      AsignarCampoTextoSiEditable(
        unqryTablaG,
        'CONTADOR_LINEAS_PEDC',
        Format('%.8d', [iNuevaLinea]));
      DataSet.FieldByName('LINEA_PEDCLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasAfterPost(
                                                       DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  CalcularTotalesPedidoCompra;
  // Si los totales han ensuciado la cabecera, su Post pasa por AfterPost y
  // regenera los pendientes una sola vez. Si sigue en Browse, el cambio de
  // linea puede afectar cantidades/SKU sin variar importes y se regenera
  // directamente. La reorganizacion masiva conserva su aplazamiento.
  if unqryTablaG.State in dsEditModes then
    unqryTablaG.Post
  else
  begin
    sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
    if (sSerie <> '') and (sNumero <> '') then
    begin
      if FReorganizandoLineas > 0 then
        FReorganizacionPendiente := True
      else
        CrearPendientesPedidoCompraUniDAC(
          ConexionEscritura).GenerarPdteRecibirDesdePedido(
            sSerie, sNumero, IdentidadSesion.Usuario);
    end;
  end;
  if FReorganizandoLineas = 0 then
    RefrescarResumenPedidoCompra;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasBeforeDelete(
                                                       DataSet: TDataSet);
var
  oQry: TUniQuery;
  sSerie, sNumero, sLinea: string;
begin
  inherited;
  // Retirar antes del Delete la fila exacta, cuando todavia estan
  // disponibles las claves de la linea. AfterDelete recalcula la cabecera
  // y regenera el conjunto desde el pedido ya persistido.
  sSerie := unqryPedidosCompraLineas.FieldByName(
    'SERIE_PEDC_PEDCLIN').AsString;
  sNumero := unqryPedidosCompraLineas.FieldByName(
    'NUMERO_PEDC_PEDCLIN').AsString;
  sLinea := unqryPedidosCompraLineas.FieldByName(
    'LINEA_PEDCLIN').AsString;
  if (sSerie <> '') and (sNumero <> '') then
  begin
    // No existe FK con borrado en cascada. Si quedan PEDCCEL huerfanas,
    // el desmontaje cuenta sus unidades pero no puede reconstruirlas.
    oQry := TUniQuery.Create(nil);
    try
      oQry.Connection := ConexionEscritura;
      oQry.SQL.Text :=
        'DELETE FROM fza_pedidos_compra_celdas ' +
        ' WHERE SERIE_PEDC_PEDCCEL = :s ' +
        '   AND NUMERO_PEDC_PEDCCEL = :n ' +
        '   AND CAST(LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
        '       CAST(:l AS UNSIGNED)';
      oQry.ParamByName('s').AsString := sSerie;
      oQry.ParamByName('n').AsString := sNumero;
      oQry.ParamByName('l').AsString := sLinea;
      oQry.ExecSQL;
    finally
      FreeAndNil(oQry);
    end;
    CrearPendientesPedidoCompraUniDAC(
      ConexionEscritura).BorrarPdteRecibirDesdePedido(
        sSerie, sNumero, sLinea);
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasAfterDelete(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesPedidoCompra;
  if unqryTablaG.State in dsEditModes then
    unqryTablaG.Post
  else if FReorganizandoLineas > 0 then
    FReorganizacionPendiente := True
  else
    SincronizarPdteRecibir;
  if FReorganizandoLineas = 0 then
    RefrescarResumenPedidoCompra;
end;

procedure TdmPedidosCompra.RefrescarResumenPedidoCompra;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.State = dsBrowse) and
     (unqryTablaG.SQLRefresh.Count > 0) then
    unqryTablaG.RefreshRecord;
end;

procedure TdmPedidosCompra.LimpiarCeldasHuerfanasPedidoCompraActual;
var
  oQry: TUniQuery;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.State = dsBrowse) then
  begin
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_PEDC').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PEDC').AsString);
    if (sSerie <> '') and (sNumero <> '') then
    begin
      oQry := TUniQuery.Create(nil);
      try
        oQry.Connection := ConexionEscritura;
        oQry.SQL.Text :=
          'DELETE C ' +
          '  FROM fza_pedidos_compra_celdas C ' +
          '  LEFT JOIN fza_pedidos_compra_lineas L ' +
          '    ON L.SERIE_PEDC_PEDCLIN = C.SERIE_PEDC_PEDCCEL ' +
          '   AND L.NUMERO_PEDC_PEDCLIN = C.NUMERO_PEDC_PEDCCEL ' +
          '   AND CAST(L.LINEA_PEDCLIN AS UNSIGNED) = ' +
          '       CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) ' +
          ' WHERE C.SERIE_PEDC_PEDCCEL = :s ' +
          '   AND C.NUMERO_PEDC_PEDCCEL = :n ' +
          '   AND L.LINEA_PEDCLIN IS NULL';
        oQry.ParamByName('s').AsString := sSerie;
        oQry.ParamByName('n').AsString := sNumero;
        oQry.ExecSQL;
      finally
        FreeAndNil(oQry);
      end;
    end;
  end;
end;

function TdmPedidosCompra.ObtenerAlmacenesSql(
                                            const AAlmacenesCsv: string):
                                            string;
var
  i: Integer;
  lstCod: TStringList;
  sCod: string;
begin
  Result := '';
  if Trim(AAlmacenesCsv) <> '' then
  begin
    lstCod := TStringList.Create;
    try
      lstCod.StrictDelimiter := True;
      lstCod.Delimiter       := ',';
      lstCod.DelimitedText   := AAlmacenesCsv;
      for i := 0 to lstCod.Count - 1 do
      begin
        sCod := Trim(lstCod[i]);
        if sCod <> '' then
        begin
          if Result <> '' then
            Result := Result + ',';
          Result := Result + QuotedStr(sCod);
        end;
      end;
    finally
      FreeAndNil(lstCod);
    end;
  end;
end;

procedure TdmPedidosCompra.CargarAlmacenesDelPedido(
                                      const ASerie, ANumero: string;
                                      ALV: TObject);
const
  cAlmacenEf =
    'COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''), ' +
    '         NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
var
  oQry: TUniQuery;
  oLv: TcxListView;
  oItem: TListItem;
begin
  if ALV is TcxListView then
  begin
    oLv := TcxListView(ALV);
    oLv.Items.BeginUpdate;
    try
      oLv.Items.Clear;
      oQry := TUniQuery.Create(nil);
      try
        oQry.Connection := ConexionEscritura;
        oQry.SQL.Text :=
          'SELECT X.COD, COALESCE(A.NOMBRE_ALM_ALM, X.COD) AS NOM ' +
          '  FROM ( ' +
          '        SELECT DISTINCT ' + cAlmacenEf + ' AS COD ' +
          '          FROM fza_pedidos_compra_lineas L ' +
          '          JOIN fza_pedidos_compra P ' +
          '            ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
          '           AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
          // Las lineas de celda se comparan como numeros.
          '          LEFT JOIN fza_pedidos_compra_celdas C ' +
          '            ON C.SERIE_PEDC_PEDCCEL = ' +
          'L.SERIE_PEDC_PEDCLIN ' +
          '           AND C.NUMERO_PEDC_PEDCCEL = ' +
          'L.NUMERO_PEDC_PEDCLIN ' +
          '           AND CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
          '               CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
          '         WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
          '           AND L.NUMERO_PEDC_PEDCLIN = :n ' +
          '       ) X ' +
          '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = X.COD ' +
          ' WHERE COALESCE(X.COD, '''') <> '''' ' +
          ' ORDER BY X.COD';
        oQry.ParamByName('s').AsString := ASerie;
        oQry.ParamByName('n').AsString := ANumero;
        oQry.Open;
        while not oQry.Eof do
        begin
          oItem := oLv.Items.Add;
          oItem.Caption := oQry.FieldByName('COD').AsString;
          oItem.SubItems.Add(oQry.FieldByName('NOM').AsString);
          oItem.Checked := True;
          oQry.Next;
        end;
      finally
        FreeAndNil(oQry);
      end;
    finally
      oLv.Items.EndUpdate;
    end;
  end;
end;

function TdmPedidosCompra.ObtenerSkusPedidoCsv(const ASerie, ANumero,
                                               AAlmacenesCsv: string):
                                               string;
const
  cAlmacenEf =
    'COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''), ' +
    '         NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
var
  oQry: TUniQuery;
  sAlmacenes: string;
begin
  Result := '';
  sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := ConexionEscritura;
    oQry.SQL.Text :=
      'SELECT DISTINCT L.CODIGO_UNIDAD_PEDCLIN ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      // Cruce de LINEA en numerico: celda '10' vs linea '0010'.
      '  LEFT JOIN fza_pedidos_compra_celdas C ' +
      '    ON C.SERIE_PEDC_PEDCCEL = L.SERIE_PEDC_PEDCLIN ' +
      '   AND C.NUMERO_PEDC_PEDCCEL = L.NUMERO_PEDC_PEDCLIN ' +
      '   AND CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
      '       CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> ''''';
    if sAlmacenes <> '' then
      oQry.SQL.Add('   AND ' + cAlmacenEf + ' IN (' + sAlmacenes + ')');
    oQry.SQL.Add(' ORDER BY L.CODIGO_UNIDAD_PEDCLIN');
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmPedidosCompra.ConfigurarConsultaCantidadCeldas(
  AConsulta: TUniQuery;
  const AAlmacenes: string);
const
  cAlmacenCel =
    'COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''), ' +
    '         NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
begin
  AConsulta.SQL.Text :=
    'SELECT X.SKU, SUM(X.CANTIDAD) AS CANTIDAD ' +
    '  FROM ( ' +
    '        SELECT L.CODIGO_UNIDAD_PEDCLIN AS SKU, ' +
    '               COALESCE(C.CANTIDAD_PEDCCEL, 0) AS CANTIDAD ' +
    '          FROM fza_pedidos_compra_lineas L ' +
    '          JOIN fza_pedidos_compra P ' +
    '            ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
    '           AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
    '          JOIN fza_pedidos_compra_celdas C ' +
    '            ON C.SERIE_PEDC_PEDCCEL = L.SERIE_PEDC_PEDCLIN ' +
    '           AND C.NUMERO_PEDC_PEDCCEL = L.NUMERO_PEDC_PEDCLIN ' +
    '           AND CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
    '               CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
    '         WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
    '           AND L.NUMERO_PEDC_PEDCLIN = :n ' +
    '           AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> '''' ' +
    '           AND COALESCE(C.CANTIDAD_PEDCCEL, 0) > 0 ';
  if AAlmacenes <> '' then
    AConsulta.SQL.Add('           AND ' + cAlmacenCel +
      ' IN (' + AAlmacenes + ')');
end;

procedure TdmPedidosCompra.AnadirConsultaCantidadLineas(
  AConsulta: TUniQuery;
  const AAlmacenes: string);
const
  cAlmacenLin =
    'COALESCE(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
begin
  AConsulta.SQL.Add(
    '        UNION ALL ' +
    '        SELECT L.CODIGO_UNIDAD_PEDCLIN AS SKU, ' +
    '               COALESCE(L.CANTIDAD_PEDCLIN, 0) AS CANTIDAD ' +
    '          FROM fza_pedidos_compra_lineas L ' +
    '          JOIN fza_pedidos_compra P ' +
    '            ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
    '           AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
    '         WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
    '           AND L.NUMERO_PEDC_PEDCLIN = :n ' +
    '           AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> '''' ' +
    '           AND COALESCE(L.CANTIDAD_PEDCLIN, 0) > 0 ' +
    '           AND NOT EXISTS ( ' +
    '             SELECT 1 ' +
    '               FROM fza_pedidos_compra_celdas C0 ' +
    '              WHERE C0.SERIE_PEDC_PEDCCEL = ' +
    '                    L.SERIE_PEDC_PEDCLIN ' +
    '                AND C0.NUMERO_PEDC_PEDCCEL = ' +
    '                    L.NUMERO_PEDC_PEDCLIN ' +
    '                AND CAST(C0.LINEA_PEDC_PEDCCEL AS UNSIGNED) ' +
    '                    = CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
    '           ) ');
  if AAlmacenes <> '' then
    AConsulta.SQL.Add('           AND ' + cAlmacenLin +
      ' IN (' + AAlmacenes + ')');
  AConsulta.SQL.Add(
    '       ) X ' +
    ' GROUP BY X.SKU');
end;

procedure TdmPedidosCompra.CargarCantidadesEtiquetas(
  const ASerie, ANumero, AAlmacenesCsv: string;
  ACantidades: TDictionary<string, Integer>);
var
  oConsulta: TUniQuery;
  iCantidad: Integer;
  sAlmacenes: string;
  sSku: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionEscritura;
    sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
    ConfigurarConsultaCantidadCeldas(oConsulta, sAlmacenes);
    AnadirConsultaCantidadLineas(oConsulta, sAlmacenes);
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iCantidad := Trunc(oConsulta.FieldByName('CANTIDAD').AsFloat);
      sSku := oConsulta.FieldByName('SKU').AsString;
      if (sSku <> '') and (iCantidad > 0) then
        ACantidades.AddOrSetValue(sSku, iCantidad);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmPedidosCompra.PrepararCamposEtiquetas(
  ADataSet: TClientDataSet;
  out AIndiceSku, AIndiceStock: Integer);
var
  iCampo: Integer;
begin
  AIndiceSku := ADataSet.FieldByName('CODIGO_UNIDAD_SKU').Index;
  AIndiceStock := -1;
  if ADataSet.FindField('STOCK_FILTRADO') <> nil then
    AIndiceStock := ADataSet.FieldByName('STOCK_FILTRADO').Index;
  for iCampo := 0 to ADataSet.FieldCount - 1 do
  begin
    ADataSet.Fields[iCampo].ReadOnly := False;
    ADataSet.Fields[iCampo].Required := False;
  end;
end;

function TdmPedidosCompra.CapturarFilasEtiquetas(
  ADataSet: TClientDataSet): TFilasEtiquetasPedido;
var
  iCampo: Integer;
  iFila: Integer;
begin
  SetLength(Result, ADataSet.RecordCount);
  ADataSet.First;
  for iFila := 0 to High(Result) do
  begin
    SetLength(Result[iFila], ADataSet.FieldCount);
    for iCampo := 0 to ADataSet.FieldCount - 1 do
      Result[iFila][iCampo] := ADataSet.Fields[iCampo].Value;
    ADataSet.Next;
  end;
end;

procedure TdmPedidosCompra.InsertarCopiasEtiquetas(
  ADataSet: TClientDataSet;
  const AFilas: TFilasEtiquetasPedido;
  AIndiceSku, AIndiceStock: Integer;
  ACantidades: TDictionary<string, Integer>);
var
  iCampo: Integer;
  iCopia: Integer;
  iCantidad: Integer;
  iFila: Integer;
  sSku: string;
begin
  ADataSet.EmptyDataSet;
  for iFila := 0 to High(AFilas) do
  begin
    sSku := VarToStr(AFilas[iFila][AIndiceSku]);
    if ACantidades.TryGetValue(sSku, iCantidad) then
    begin
      for iCopia := 1 to iCantidad do
      begin
        ADataSet.Append;
        for iCampo := 0 to ADataSet.FieldCount - 1 do
          ADataSet.Fields[iCampo].Value := AFilas[iFila][iCampo];
        if AIndiceStock >= 0 then
          ADataSet.Fields[AIndiceStock].AsInteger := iCantidad;
        ADataSet.Post;
      end;
    end;
  end;
end;

procedure TdmPedidosCompra.ExpandirDataSetEtiquetas(
  ADataSet: TClientDataSet;
  ACantidades: TDictionary<string, Integer>);
var
  oFilas: TFilasEtiquetasPedido;
  iIndiceSku: Integer;
  iIndiceStock: Integer;
begin
  if ADataSet.IsEmpty or
     (ADataSet.FindField('CODIGO_UNIDAD_SKU') = nil) then
    ADataSet.EmptyDataSet
  else
  begin
    ADataSet.DisableControls;
    ADataSet.DisableConstraints;
    try
      PrepararCamposEtiquetas(ADataSet, iIndiceSku, iIndiceStock);
      oFilas := CapturarFilasEtiquetas(ADataSet);
      InsertarCopiasEtiquetas(ADataSet, oFilas, iIndiceSku,
        iIndiceStock, ACantidades);
    finally
      ADataSet.EnableConstraints;
      ADataSet.EnableControls;
    end;
  end;
end;

procedure TdmPedidosCompra.ExpandirEtiquetasPorCantidadPed(
  ADmArt: TObject;
  const ASerie, ANumero, AAlmacenesCsv: string);
var
  oCantidades: TDictionary<string, Integer>;
  oDmArt: TdmArticulos;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    oCantidades := TDictionary<string, Integer>.Create;
    try
      CargarCantidadesEtiquetas(ASerie, ANumero, AAlmacenesCsv,
        oCantidades);
      if oDmArt.cdsEtiquetasArt.Active then
        ExpandirDataSetEtiquetas(oDmArt.cdsEtiquetasArt, oCantidades);
    finally
      FreeAndNil(oCantidades);
    end;
  end;
end;
procedure TdmPedidosCompra.CrearDataSetEtiquetasPed(ADmArt: TObject;
                                  const ASerie, ANumero,
                                        ACodTarifa, AAlmacenesCsv: string;
                                  AFecha: TDateTime);
var
  oDmArt: TdmArticulos;
  sSkus: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    sSkus := ObtenerSkusPedidoCsv(ASerie, ANumero, AAlmacenesCsv);
    if sSkus <> '' then
    begin
      oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, '', AFecha, sSkus);
      ExpandirEtiquetasPorCantidadPed(oDmArt, ASerie, ANumero,
                                       AAlmacenesCsv);
    end
    else
      oDmArt.CrearDataSetEtiquetasArt('DUMMY_SIN_LINEAS',
                                      ACodTarifa, '', AFecha);
  end;
end;

procedure TdmPedidosCompra.GetCodigoAutoPedidoCompra;
var
  iNumero: Int64;
  sNumero: string;
begin
  unstrdprcGetContadorPedc.Params.Clear;
  unstrdprcGetContadorPedc.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorPedc.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorPedc.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorPedc.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorPedc.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorPedc.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  unstrdprcGetContadorPedc.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdPedido, sdCompra).TipoContador;
  unstrdprcGetContadorPedc.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorPedc.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString;
  EjecutarContadorDocumento(unstrdprcGetContadorPedc);
  sNumero := Trim(
    unstrdprcGetContadorPedc.ParamByName('pcont').AsString);
  if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
     (iNumero <= 0) then
    raise Exception.Create(Format(SErrorContadorPedidoCompra,
      [unqryTablaG.FieldByName('SERIE_PEDC').AsString,
       unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString]));
  unqryTablaG.FieldByName('NUMERO_PEDC').AsString := sNumero;
end;

procedure TdmPedidosCompra.DesempaquetarAtributosLineas;
begin
  if unqryPedidosCompraLineas.Active and
     (not unqryPedidosCompraLineas.IsEmpty) and
     (unqryPedidosCompraLineas.FindField('ATTR1_VALOR_PEDCLIN') <> nil) and
     (unqryPedidosCompraLineas.FindField('NUM_ATRIBUTOS_PEDCLIN') <> nil) and
     (not unqryPedidosCompraLineas.ReadOnly) then
  begin
    // Evita recálculos fiscales y movimientos durante los Post descriptivos.
    FDesempaquetandoAtributos := True;
    try
      DesempaquetarAtributosLineasSku(unqryPedidosCompraLineas, 'PEDCLIN');
    finally
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

function TdmPedidosCompra.UnidadesLineasPedido: TArray<string>;
var
  q: TUniQuery;
begin
  SetLength(Result, 0);
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      q.SQL.Text :=
        'SELECT DISTINCT TIPO_CANTIDAD_ARTICULO_PEDCLIN AS UNIDAD ' +
        '  FROM fza_pedidos_compra_lineas ' +
        ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
        '   AND NUMERO_PEDC_PEDCLIN = :n';
      q.ParamByName('s').AsString :=
        unqryTablaG.FieldByName('SERIE_PEDC').AsString;
      q.ParamByName('n').AsString :=
        unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
      q.Open;
      while not q.Eof do
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := q.FieldByName('UNIDAD').AsString;
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmPedidosCompra.CalcularTotalesPedidoCompra;
var
  oCampoPrendas: TField;
  rPrendas: Double;
begin
  // Los posts del desempaquetado ATTR no alteran importes: saltar el
  // recalculo por linea (cascada de consultas de IVA al navegar).
  if not FDesempaquetandoAtributos then
  begin
    // La reorganizacion pospone un unico recalculo hasta finalizar.
    if FReorganizandoLineas > 0 then
      FReorganizacionPendiente := True
    else if not FCalculandoTotales then
    begin
      FCalculandoTotales := True;
      try
        CalcularTotalesDocumentoCompra(
          CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
          unqryPedidosCompraLineas, 'PEDC', 'TOTAL_PEDCLIN',
          'TIPO_IVA_ARTICULO_PEDCLIN', 'PORCENTAJE_IVA_PEDCLIN');
        // La vista calcula prendas al abrir; se actualizan en cliente.
        oCampoPrendas := unqryTablaG.FindField('TOTAL_PRENDAS_PEDC');
        if oCampoPrendas <> nil then
        begin
          rPrendas := TotalPrendasLineasCompra(unqryPedidosCompraLineas,
            'TIPO_IVA_ARTICULO_PEDCLIN', '', UnidadesMedida);
          if oCampoPrendas.IsNull or
             (Abs(oCampoPrendas.AsFloat - rPrendas) > 0.000001) then
          begin
            if not (unqryTablaG.State in [dsEdit, dsInsert]) then
              unqryTablaG.Edit;
            oCampoPrendas.AsFloat := rPrendas;
          end;
        end;
      finally
        FCalculandoTotales := False;
      end;
    end;
  end;
end;

procedure TdmPedidosCompra.IniciarReorganizacionLineas;
begin
  Inc(FReorganizandoLineas);
end;

procedure TdmPedidosCompra.FinalizarReorganizacionLineas;
var
  sSerie, sNumero: string;
begin
  if FReorganizandoLineas > 0 then
    Dec(FReorganizandoLineas);
  if FReorganizandoLineas = 0 then
  begin
    // La reorganizacion escribe lineas y celdas por SQL directo: sin
    // reabrir el detalle, el grid y el pivote publican datos rancios
    // (tallas vacias hasta reconstruir el modo con F1). Antes lo
    // "arreglaban" las reaperturas en cascada del master-detail.
    if unqryPedidosCompraLineas.Active then
    begin
      unqryPedidosCompraLineas.Close;
      unqryPedidosCompraLineas.Open;
    end;
    // Si hubo posts pospuestos, recalcular totales y regenerar los
    // pendientes de recibir UNA sola vez (ya con datos frescos).
    if FReorganizacionPendiente then
    begin
      FReorganizacionPendiente := False;
      CalcularTotalesPedidoCompra;
      if unqryTablaG.State in dsEditModes then
        unqryTablaG.Post
      else
      begin
        sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
        sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
        if (sSerie <> '') and (sNumero <> '') then
          CrearPendientesPedidoCompraUniDAC(
            ConexionEscritura).GenerarPdteRecibirDesdePedido(
              sSerie, sNumero, IdentidadSesion.Usuario);
      end;
    end;
    RefrescarResumenPedidoCompra;
  end;
end;

function TdmPedidosCompra.EnReorganizacionLineas: Boolean;
begin
  Result := FReorganizandoLineas > 0;
end;

function TdmPedidosCompra.AbortarReorganizacionLineas: Boolean;
begin
  if FReorganizandoLineas > 0 then
    Dec(FReorganizandoLineas);
  Result := FReorganizacionPendiente;
  FReorganizacionPendiente := False;
end;

procedure TdmPedidosCompra.SincronizarPdteRecibir;
var
  sSerie, sNumero: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
    if (sSerie <> '') and (sNumero <> '') then
      CrearPendientesPedidoCompraUniDAC(
        ConexionEscritura).GenerarPdteRecibirDesdePedido(
          sSerie, sNumero, IdentidadSesion.Usuario);
  end;
end;

function TdmPedidosCompra.HayLineasSinPivotar: Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      // El cruce de LINEA va en NUMERICO: la celda guarda '10' (el
      // parametro entra como entero) y la linea '0010'; como texto
      // nunca casaban, TODA linea con SKU contaba como sin pivotar y
      // cada entrada al grid reconstruia el documento entero
      // (expansion + fusion: tormenta de SQL por click, 10/07/26).
      // Solo cuentan articulos CON variacion: uno sin tallas jamas
      // tendra celdas y forzaria la reconstruccion eterna.
      q.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_pedidos_compra_lineas L ' +
        '  JOIN fza_articulos A ' +
        '    ON A.CODIGO_ART_ART = L.CODIGO_ART_PEDCLIN ' +
        ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
        '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
        '   AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> '''' ' +
        '   AND IFNULL(A.ESVARIACION_ART, ''N'') = ''S'' ' +
        '   AND NOT EXISTS (SELECT 1 ' +
        '                     FROM fza_pedidos_compra_celdas C ' +
        '                    WHERE C.SERIE_PEDC_PEDCCEL  = ' +
        '                          L.SERIE_PEDC_PEDCLIN ' +
        '                      AND C.NUMERO_PEDC_PEDCCEL = ' +
        '                          L.NUMERO_PEDC_PEDCLIN ' +
        '                      AND CAST(C.LINEA_PEDC_PEDCCEL ' +
        '                               AS UNSIGNED) = ' +
        '                          CAST(L.LINEA_PEDCLIN AS UNSIGNED)) ' +
        ' LIMIT 1';
      q.ParamByName('s').AsString :=
        unqryTablaG.FieldByName('SERIE_PEDC').AsString;
      q.ParamByName('n').AsString :=
        unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
      q.Open;
      Result := not q.Eof;
    finally
      FreeAndNil(q);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmPedidosCompra);
end.
