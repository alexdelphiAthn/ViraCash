{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesCompra                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de albaranes de COMPRA.                                       }
{    Espejo simplificado de UniDataAlbaranes adaptado a documentos de          }
{    compra (proveedor en lugar de cliente, precio de compra en lugar          }
{    de venta). Sincroniza movimientos de stock AC desde la cabecera y         }
{    lineas actuales del documento.                                            }
{******************************************************************************}
unit UniDataAlbaranesCompra;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  UniDataGen, UniDataArticulos, inLibUser, inLibLotesLineaDocumento;

type
  TdmAlbaranesCompra = class(TdmBase)
    unqryAlbaranesCompraLineas: TUniQuery;
    dsAlbaranesCompraLineas:    TDataSource;
    unqryEmpDataAlbc:           TUniQuery;
    unqryPrvDataAlbc:           TUniQuery;
    dsPrvDataAlbc:              TDataSource;
    unqryArtDataLinAlbc:        TUniQuery;
    unqrySkusAlbc:              TUniQuery;
    unqryMovimientosProveedor:  TUniQuery;
    dsMovimientosProveedor:     TDataSource;
    unqryFormasPago:            TUniQuery;
    dsFormasPago:               TDataSource;
    unqryAlmacenesAlbc:         TUniQuery;
    dsAlmacenesAlbc:            TDataSource;
    unstrdprcGetContadorAlbc:   TUniStoredProc;
    // Definicion de atributos del articulo padre (para columnas
    // dinamicas ATTR1..ATTR5 en modo "atributo por columna").
    unqryDefArticuloAlbc:       TUniQuery;
    unqryTemporadasAlbc:        TUniQuery;
    dsTemporadasAlbc:           TDataSource;
    // Datasets para impresion del albaran via FastReport. Mismo patron
    // que TdmComprasSesiones (unqry*Print -> ds*Print -> fxds*). El
    // .fr3 embebido en el modal inMtoModalImpAlbCompra.dfm los
    // referencia por UserName ('Albaran', 'LineasAlbaran').
    unqryCabAlbcPrint:          TUniQuery;
    dsCabAlbcPrint:             TDataSource;
    fxdsCabAlbc:                TfrxDBDataset;
    unqryLinAlbcPrint:          TUniQuery;
    dsLinAlbcPrint:             TDataSource;
    fxdsLinAlbc:                TfrxDBDataset;
    unqryGuiasAlbcPrint:        TUniQuery;
    dsGuiasAlbcPrint:           TDataSource;
    fxdsGuiasAlbc:              TfrxDBDataset;
    // Lineas "planas" (una fila por SKU sin pivotar por talla) para el
    // formato vertical estilo factura.
    unqryLinAlbcSkuPrint:       TUniQuery;
    dsLinAlbcSkuPrint:          TDataSource;
    fxdsLinAlbcSku:             TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterOpen(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterPost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterDelete(DataSet: TDataSet);
  private
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal ni
    // la sincronizacion de movimientos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    FSerieRecepcionSinConfirmar: string;
    FNumeroRecepcionSinConfirmar: string;
    // >0 mientras el modo de entrada expande/consolida lineas en bloque
    // (una linea por SKU): totales y movimientos se posponen a
    // FinalizarReorganizacionLineas para no regenerarlos por linea.
    FReorganizandoLineas: Integer;
    FReorganizacionPendiente: Boolean;
    // F-LOTEC-013: lote o serie de las líneas (nil = sin
    // trazabilidad, como siempre).
    FLotesLineas: TLotesLineasDocumento;
    procedure CancelarLineaVaciaDiferida;
    procedure AsignarNumeroLineaAlbaranCompra(DataSet: TDataSet);
    procedure ConfigurarSqlCabecera;
    function HayLineasMovimiento(const ASerie, ANumero: string): Boolean;
    function LineaTieneCeldasPivote(DataSet: TDataSet): Boolean;
    function ObtenerSkusAlbaranCsv(const ASerie, ANumero: string): string;
    procedure RefrescarMovimientosProveedor;
    procedure CopiarEmpresaaAlbaranCompra(DataSet: TDataSet);
    procedure ValidarAlmacenCabecera;
  public
    procedure LineaCircuitoBeforeDelete(DataSet: TDataSet);
    destructor Destroy; override;
    // F-LOTEC-013: lo llama el formulario con los interruptores leídos.
    procedure ConfigurarLotesLineas(const AConfig: TConfiguracionLotesLineas);
    // Documento actual para el lote de las líneas (tipo AC).
    function DocumentoLotes: TDocumentoLineaLote;
    procedure GetCodigoAutoAlbaranCompra;
    procedure CalcularTotalesAlbaranCompra;
    procedure SincronizarMovimientos;
    function HayRecepcionSinConfirmar: Boolean;
    function TieneEntradasStock: Boolean;
    procedure ConfirmarRecepcion;
    // Bracket de reorganizacion masiva de lineas (construccion del modo
    // de entrada): entre Iniciar y Finalizar los posts de linea no
    // recalculan totales ni revierten/regeneran movimientos; se hace
    // UNA vez al Finalizar si hubo posts.
    procedure IniciarReorganizacionLineas;
    procedure FinalizarReorganizacionLineas;
    function EnReorganizacionLineas: Boolean;
    // Contrato ColumnSKUcxGrid: desglosa el SKU ART/COLOR/TALLA en las
    // columnas reales ATTR1..5_VALOR_ALBCLIN + NUM_ATRIBUTOS_ALBCLIN
    // (idempotente por comparacion, mismo criterio que pedidos compra).
    procedure DesempaquetarAtributosLineas;
    function BuscarEmpresa(const ACodigo: string): Boolean;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure EstablecerMovimientosProveedorVisible(AVisible: Boolean);
    // Abre unqryCabAlbcPrint y unqryLinAlbcPrint con los parametros
    // del albaran a imprimir. Mismo nombre/firma que en sesiones.
    procedure PrepararPrint(const ASerie, ANumero: string);
    // Version SKU (lineas planas, sin pivote talla) para el modal
    // vertical estilo factura.
    procedure PrepararPrintSku(const ASerie, ANumero: string);
    // Carga en el listview los almacenes distintos que aparecen en las
    // lineas del albaran (usado por el modal de pegatinas).
    procedure CargarAlmacenesDelAlbaran(const ASerie, ANumero: string;
                                         ALV: TObject);
    // Crea el dataset cdsEtiquetasArt del DM articulos filtrado a los
    // SKUs del albaran. Reutiliza la query base de etiquetas anyadiendo
    // un WHERE por SKU IN (SELECT ... FROM albaranes_compra_lineas).
    procedure CrearDataSetEtiquetasAlb(ADmArt: TObject;
                                        const ASerie, ANumero,
                                              ACodTarifa, AAlmacenesCsv: string;
                                        AFecha: TDateTime);
    procedure OpenTables;
    // Override: abre las queries detalle tras unqryTablaG. Llamada
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync.
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
  UniDataProveedoresTexto,
  UniDataReparacionesProteccion,
  UniDataCodigosBarrasLote,
  inLibLineaSku,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inLibContadorLineas, inLibDatasets,
  UniDataContadorLineasRepositorio,
  System.Diagnostics, System.UITypes,
  UniDataAperturaConsultas,
  inLibAlbaranesCompraMovimientos,
  inLibPrestaShopColaSenal,
  UniDataAlbaranesCompraMovimientos,
  UniDataPedidosCompraAlbaranComun,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibData, UniDataAlmacenesEmpresaRepositorio,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibMsgArticulos, inLibMsgCompras, inLibMsgVentas,
  inLibDocumento, inLibDocumentoIntf,
  UniDataDatosProveedorDocumento;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TdmAlbaranesCompra.ConexionEscritura: TUniConnection;
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

procedure TdmAlbaranesCompra.ConfigurarSqlCabecera;
const
  CAMPOS_ALBC: array[0..80] of string = (
    'NUMERO_ALBC',
    'SERIE_ALBC',
    'FECHA_ALBC',
    'INSTANTE_MOVIMIENTO_ALBC',
    'ESTADO_ALBC',
    'NUMERO_PED_ALBC',
    'SERIE_PED_ALBC',
    'NUMERO_FAC_ALBC',
    'SERIE_FAC_ALBC',
    'CODIGO_EMP_ALBC',
    'RAZON_SOCIAL_EMPRESA_ALBC',
    'NIF_EMPRESA_ALBC',
    'MOVIL_EMPRESA_ALBC',
    'EMAIL_EMPRESA_ALBC',
    'DIRECCION1_EMPRESA_ALBC',
    'DIRECCION2_EMPRESA_ALBC',
    'POBLACION_EMPRESA_ALBC',
    'PROVINCIA_EMPRESA_ALBC',
    'CODIGO_PAI_EMPRESA_ALBC',
    'NOMBRE_PAI_EMPRESA_ALBC',
    'CODIGO_POSTAL_EMPRESA_ALBC',
    'CODIGO_PRV_ALBC',
    'RAZON_SOCIAL_PRV_ALBC',
    'NIF_PRV_ALBC',
    'MOVIL_PRV_ALBC',
    'EMAIL_PRV_ALBC',
    'DIRECCION1_PRV_ALBC',
    'DIRECCION2_PRV_ALBC',
    'POBLACION_PRV_ALBC',
    'PROVINCIA_PRV_ALBC',
    'CODIGO_PAI_PRV_ALBC',
    'NOMBRE_PAI_PRV_ALBC',
    'CODIGO_POSTAL_PRV_ALBC',
    'REF_PROVEEDOR_ALBC',
    'CODIGO_ALM_ALBC',
    'TRANSPORTISTA_ALBC',
    'CODIGO_IVA_ALBC',
    'ESIVA_RECARGO_COMPRAS_ALBC',
    'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC',
    'PORCENTAJE_IVAN_ALBC',
    'TOTAL_BASEI_IVAN_ALBC',
    'TOTAL_IVAN_ALBC',
    'PORCENTAJE_REN_ALBC',
    'TOTAL_REN_ALBC',
    'PORCENTAJE_IVAR_ALBC',
    'TOTAL_BASEI_IVAR_ALBC',
    'TOTAL_IVAR_ALBC',
    'PORCENTAJE_RER_ALBC',
    'TOTAL_RER_ALBC',
    'PORCENTAJE_IVAS_ALBC',
    'TOTAL_BASEI_IVAS_ALBC',
    'TOTAL_IVAS_ALBC',
    'PORCENTAJE_RES_ALBC',
    'TOTAL_RES_ALBC',
    'PORCENTAJE_IVAE_ALBC',
    'TOTAL_BASEI_IVAE_ALBC',
    'TOTAL_IVAE_ALBC',
    'PORCENTAJE_REE_ALBC',
    'TOTAL_REE_ALBC',
    'TOTAL_BRUTO_ALBC',
    'PORCENTAJE_DTO_COMERCIAL_ALBC',
    'TOTAL_DTO_COMERCIAL_ALBC',
    'PORCENTAJE_DTO_FINANCIERO_ALBC',
    'TOTAL_DTO_FINANCIERO_ALBC',
    'TOTAL_BASES_ALBC',
    'TOTAL_IMPUESTOS_ALBC',
    'PORCENTAJE_RETENCION_ALBC',
    'TOTAL_RETENCION_ALBC',
    'TOTAL_LIQUIDO_ALBC',
    'FORMA_PAGO_ALBC',
    'ID_PV_TEMPORADA_ALBC',
    'CONTADOR_LINEAS_ALBC',
    'COMENTARIOS_ALBC',
    'OBSERVACIONES_ALBC',
    'ESPIVOTE_HORIZONTAL_ALBC',
    'CODIGO_TAR_ALBC',
    'ESDEPOSITO_ALBC',
    'INSTANTE_MODIF',
    'INSTANTE_ALTA',
    'USUARIO_ALTA',
    'USUARIO_MODIF');
var
  i: Integer;
  sSet: string;
  sCols: string;
  sVals: string;

  procedure AgregarCampoUpdate(const ACampo: string);
  begin
    if sSet = '' then
      sSet := '       ' + ACampo + ' = :' + ACampo
    else
      sSet := sSet + ',' + sLineBreak +
        '       ' + ACampo + ' = :' + ACampo;
  end;

  procedure AgregarCampoInsert(const ACampo: string);
  begin
    if sCols = '' then
    begin
      sCols := ACampo;
      sVals := ':' + ACampo;
    end
    else
    begin
      sCols := sCols + ', ' + ACampo;
      sVals := sVals + ', :' + ACampo;
    end;
  end;

begin
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_albaranes_compra ' + sLineBreak +
    'WHERE NUMERO_ALBC = :Old_NUMERO_ALBC ' + sLineBreak +
    '  AND SERIE_ALBC = :Old_SERIE_ALBC';
  sSet := '';
  for i := Low(CAMPOS_ALBC) to High(CAMPOS_ALBC) do
    if not SameText(CAMPOS_ALBC[i], 'CONTADOR_LINEAS_ALBC') then
      AgregarCampoUpdate(CAMPOS_ALBC[i]);
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_albaranes_compra ' + sLineBreak +
    '   SET ' + sLineBreak +
    sSet + sLineBreak +
    ' WHERE NUMERO_ALBC = :Old_NUMERO_ALBC ' + sLineBreak +
    '   AND SERIE_ALBC = :Old_SERIE_ALBC';
  // SQLInsert explicito contra la tabla base: vi_albaranes_compra tiene
  // columnas calculadas y no es insertable-into (MySQL 1471). Mismo
  // patron que el SQLInsert de pedidos de compra.
  sCols := '';
  sVals := '';
  for i := Low(CAMPOS_ALBC) to High(CAMPOS_ALBC) do
    AgregarCampoInsert(CAMPOS_ALBC[i]);
  unqryTablaG.SQLInsert.Text :=
    'INSERT INTO fza_albaranes_compra (' + sCols + ') ' + sLineBreak +
    'VALUES (' + sVals + ')';
  // INSTANTE_MOVIMIENTO_ALBC llega en V.* (vi_albaranes_compra lo incluye
  // desde 20261005_compras_prendas_solo_unidades.sql); pedirlo además a la
  // tabla duplicaba la columna (MariaDB 1060).
  unqryTablaG.SQLRefresh.Text :=
    'SELECT V.* ' + sLineBreak +
    '  FROM vi_albaranes_compra V ' + sLineBreak +
    ' WHERE V.NUMERO_ALBC = :NUMERO_ALBC ' + sLineBreak +
    '   AND V.SERIE_ALBC = :SERIE_ALBC';
end;

procedure TdmAlbaranesCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryAlbaranesCompraLineas.BeforeDelete := LineaCircuitoBeforeDelete;
  // FZ-ISSUE-154: el borrado de la cabecera, todo o nada.
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  unqryTablaG.Connection                := ConexionPrincipal;
  unqryTablaG.KeyFields                 := 'NUMERO_ALBC;SERIE_ALBC';
  ConfigurarSqlCabecera;
  unqryAlbaranesCompraLineas.Connection := ConexionPrincipal;
  unqryEmpDataAlbc.Connection           := ConexionPrincipal;
  unqryPrvDataAlbc.Connection           := ConexionPrincipal;
  // Lookup completo de proveedores (NOMBRE_PRV + RAZON_SOCIAL_PRV) para
  // el rotulo resuelto de la cabecera y para el combo de busqueda
  // incremental por codigo (cbbCODIGO_PRV_ALBC). Se abre una vez y se
  // recorre con Locate; no depende del proveedor del albaran en pantalla.
  unqryPrvDataAlbc.SQL.Text := SqlLookupProveedoresPorCodigo;
  unqryPrvDataAlbc.Open;
  unqryArtDataLinAlbc.Connection        := ConexionPrincipal;
  unqrySkusAlbc.Connection              := ConexionPrincipal;
  unqryMovimientosProveedor.Connection  := ConexionPrincipal;
  unqryFormasPago.Connection            := ConexionPrincipal;
  unqryAlmacenesAlbc.Connection         := ConexionPrincipal;
  unstrdprcGetContadorAlbc.Connection   := ConexionPrincipal;
  unqryDefArticuloAlbc.Connection       := ConexionPrincipal;
  unqryTemporadasAlbc.Connection        := ConexionPrincipal;
  unqryTemporadasAlbc.Open;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_albaranes_compra_lineas
  // entera y filtrar en cliente.
  VigilarTotalMaximoLinea(unqryAlbaranesCompraLineas, 'TOTAL_ALBCLIN');
end;

procedure TdmAlbaranesCompra.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryAlbaranesCompraLineas.MasterSource := ADataSource;
  unqryMovimientosProveedor.MasterSource := ADataSource;
end;

procedure TdmAlbaranesCompra.DataModuleDestroy(Sender: TObject);
begin
  TThread.RemoveQueuedEvents(CancelarLineaVaciaDiferida);
  if Assigned(unqryAlbaranesCompraLineas) and
     unqryAlbaranesCompraLineas.Active then
    unqryAlbaranesCompraLineas.Close;
  if Assigned(unqryMovimientosProveedor) and
     unqryMovimientosProveedor.Active then
    unqryMovimientosProveedor.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryAlmacenesAlbc) and unqryAlmacenesAlbc.Active then
    unqryAlmacenesAlbc.Close;
  inherited;
end;

procedure TdmAlbaranesCompra.OpenTables;
begin
  // Delegamos en AbrirDetalles para unificar logging y cronometro.
  AbrirDetalles;
end;

procedure TdmAlbaranesCompra.RefrescarAlmacenes(
  const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesAlbc.Active) or
     (not SameText(unqryAlmacenesAlbc.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesAlbc.Close;
    unqryAlmacenesAlbc.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesAlbc.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_ALBC', 'CODIGO_ALM_ALBC');
end;

procedure TdmAlbaranesCompra.AbrirDetalles;
const
  TAG = 'AlbaranesCompra.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  RefrescarAlmacenes(UbicacionSesion.Empresa);
  AbrirConsultaConTiempo(
    unqryAlbaranesCompraLineas, TAG, 'unqryAlbaranesCompraLineas',
    RegistroLog);
  AbrirConsultaConTiempo(
    unqryFormasPago, TAG, 'unqryFormasPago', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAlbaranesCompra.CancelarLineaVaciaDiferida;
var
  oArticulo, oSku: TField;
begin
  if not (csDestroying in ComponentState) and
     Assigned(unqryAlbaranesCompraLineas) and
     unqryAlbaranesCompraLineas.Active and
     (unqryAlbaranesCompraLineas.State in dsEditModes) then
  begin
    oArticulo := unqryAlbaranesCompraLineas.FindField(
      'CODIGO_ART_ALBCLIN');
    oSku := unqryAlbaranesCompraLineas.FindField(
      'CODIGO_UNIDAD_ALBCLIN');
    if (oArticulo <> nil) and (oSku <> nil) and
       (Trim(oArticulo.AsString) = '') and
       (Trim(oSku.AsString) = '') then
      unqryAlbaranesCompraLineas.Cancel;
  end;
end;

procedure TdmAlbaranesCompra.EstablecerMovimientosProveedorVisible(
  AVisible: Boolean);
const
  TAG = 'AlbaranesCompra.MovimientosProveedor';
var
  bDocumentoValido: Boolean;
begin
  bDocumentoValido := False;
  if AVisible then
  begin
    if unqryTablaG.Active then
    begin
      if not unqryTablaG.IsEmpty then
        bDocumentoValido :=
          (Trim(unqryTablaG.FieldByName('SERIE_ALBC').AsString) <> '') and
          (Trim(unqryTablaG.FieldByName('NUMERO_ALBC').AsString) <> '');
    end;
  end;
  if bDocumentoValido then
  begin
    if not unqryMovimientosProveedor.Active then
      AbrirConsultaConTiempo(
        unqryMovimientosProveedor, TAG, 'unqryMovimientosProveedor',
        RegistroLog);
  end
  else if unqryMovimientosProveedor.Active then
    unqryMovimientosProveedor.Close;
end;

procedure TdmAlbaranesCompra.unqryTablaGAfterOpen(DataSet: TDataSet);
var
  oCampoInstante: TField;
begin
  // El instante llega en vi_albaranes_compra (garantizado por
  // 20261006_vi_albaranes_compra_instante.sql) y la vista lo marca como
  // solo lectura. Los DML explicitos si lo guardan en la tabla base.
  oCampoInstante := DataSet.FindField('INSTANTE_MOVIMIENTO_ALBC');
  if oCampoInstante <> nil then
    oCampoInstante.ReadOnly := False;
end;

procedure TdmAlbaranesCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
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
  FieldByName('NUMERO_ALBC').AsString := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='AB'
    sSerie := ObtenerSerieDefecto(
      ConexionEscritura,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdAlbaran, sdCompra).TipoContador,
      UbicacionSesion.Almacen);
    if FindField('SERIE_ALBC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_ALBC').AsString := sSerie
      else
        FieldByName('SERIE_ALBC').AsString := 'C1';
    end;
    // UniDAC no recarga el detalle mientras el maestro esta en dsInsert.
    // Reabrirlo con numero 0 evita mostrar las lineas del albaran anterior.
    if unqryAlbaranesCompraLineas.Active then
    begin
      unqryAlbaranesCompraLineas.Close;
      unqryAlbaranesCompraLineas.Open;
    end;
    FieldByName('INSTANTE_MOVIMIENTO_ALBC').AsDateTime := Now;
    FieldByName('FECHA_ALBC').AsDateTime :=
      Trunc(FieldByName('INSTANTE_MOVIMIENTO_ALBC').AsDateTime);
    if FindField('ESTADO_ALBC') <> nil then
      FieldByName('ESTADO_ALBC').AsString := 'ABIERTO';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_ALBC').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_ALBC').AsString := '0';
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
    if FindField('CODIGO_ALM_ALBC') <> nil then
      FieldByName('CODIGO_ALM_ALBC').AsString := UbicacionSesion.Almacen;
    FieldByName('CODIGO_PRV_ALBC').AsString := '0';
    if FindField('ESPIVOTE_HORIZONTAL_ALBC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString := 'N';
    // Por defecto el albaran NO es deposito; se marca a mano en
    // cabecera. FindField: tolera BBDD sin la migracion aplicada
    // (albaran_compra_deposito.sql).
    if FindField('ESDEPOSITO_ALBC') <> nil then
      FieldByName('ESDEPOSITO_ALBC').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_ALBC') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_ALBC').AsString := 'N';
    AplicarRecargoComprasEmpresa(
      CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
      'CODIGO_EMP_ALBC', 'ESIVA_RECARGO_COMPRAS_ALBC');
  AplicarPorcentajesIvaCompra(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
    'ALBC');
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_ALBC').AsString);
end;

function TdmAlbaranesCompra.BuscarEmpresa(const ACodigo: string): Boolean;
var
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    if not unqryEmpDataAlbc.Active then
      unqryEmpDataAlbc.Open;
    if unqryEmpDataAlbc.Locate('CODIGO_EMP_EMP', sCodigo, []) then
    begin
      CopiarEmpresaaAlbaranCompra(unqryEmpDataAlbc);
      Result := True;
    end;
  end;
end;

procedure TdmAlbaranesCompra.CopiarEmpresaaAlbaranCompra(DataSet: TDataSet);
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_EMP_ALBC').AsString :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_ALBC').AsString :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_ALBC').AsString :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_ALBC').AsString :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_ALBC').AsString :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_ALBC').AsString :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_ALBC').AsString :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_ALBC').AsString :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_ALBC').AsString :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_ALBC').AsString :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_ALBC').AsString :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
  FindField('CODIGO_POSTAL_EMPRESA_ALBC').AsString :=
    DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
end;

procedure TdmAlbaranesCompra.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_ALBC') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALBC').AsString) = '') then
  begin
    NotificarAdvertencia(
      SAvisoAlmacenDestinoAlbaranCompraObligatorio);
    Abort;
  end;
end;

procedure TdmAlbaranesCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  i: Integer;
begin
  inherited;
  if DataSet.State = dsEdit then
    ExigirDocumentoOrdenEditable(ConexionEscritura,
      DataSet.FieldByName('SERIE_ALBC').AsString,
      DataSet.FieldByName('NUMERO_ALBC').AsString, True);
  SincronizarInstanteMovimientoDocumento(
    DataSet, 'FECHA_ALBC', 'INSTANTE_MOVIMIENTO_ALBC');
  // Cinturon: los campos NOT NULL con default en BBDD (p. ej.
  // ESPIVOTE_HORIZONTAL_ALBC) llegan como Required a UniDAC y bloquean
  // el Post del alta manual con "must have a value". Mismo criterio
  // que Inventarios / Pedidos de compra.
  for i := 0 to DataSet.FieldCount - 1 do
    DataSet.Fields[i].Required := False;
  // En alta manual el pivote arranca vertical; se activa tras elegir
  // una linea con sistema de tallas.
  if (DataSet.FindField('ESPIVOTE_HORIZONTAL_ALBC') <> nil) and
     (Trim(DataSet.FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString) = '')
  then
    DataSet.FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString := 'N';
  // FZ-ISSUE-249: datos del proveedor en la cabecera, como los de empresa.
  CopiarDatosProveedorDocumento(DataSet, 'ALBC');
  ValidarAlmacenCabecera;
  if (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '') then
    GetCodigoAutoAlbaranCompra;
  AplicarPorcentajesIvaCompra(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
    'ALBC');
  CalcularTotalesAlbaranCompra;
end;

// Tras persistir la cabecera, reconstruimos los movimientos AC desde el
// documento actual. Cualquier excepcion se propaga al usuario (el Post
// original ya quedo aplicado, por lo que debe revisar y reintentar).
procedure TdmAlbaranesCompra.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  SincronizarMovimientos;
end;

procedure TdmAlbaranesCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  q: TUniQuery;
  sSerie: string;
  sNumero: string;
  iBloqueos: Integer;

  procedure AsignarDocumento;
  begin
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNumero;
  end;

begin
  inherited;
  ExigirDocumentoOrdenEditable(ConexionEscritura,
    DataSet.FieldByName('SERIE_ALBC').AsString,
    DataSet.FieldByName('NUMERO_ALBC').AsString, True);
  sSerie  := DataSet.FieldByName('SERIE_ALBC').AsString;
  sNumero := DataSet.FieldByName('NUMERO_ALBC').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes_compra ' +
      ' WHERE SERIE_ALBC  = :s ' +
      '   AND NUMERO_ALBC = :n ' +
      '   AND (COALESCE(NUMERO_FAC_ALBC, '''') <> '''' ' +
      '    OR COALESCE(SERIE_FAC_ALBC, '''') <> '''')';
    AsignarDocumento;
    q.Open;
    iBloqueos := q.FieldByName('N').AsInteger;
    q.Close;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_albaranes_compra_lineas ' +
        ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
        '   AND NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND (COALESCE(ESFACTURADA_ALBCLIN, ''N'') = ''S'' ' +
        '    OR COALESCE(NUMERO_FAC_ALBCLIN, '''') <> '''' ' +
        '    OR COALESCE(SERIE_FAC_ALBCLIN, '''') <> '''')';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_facturas_compra_lineas ' +
        ' WHERE SERIE_ALBC_FACCLIN  = :s ' +
        '   AND NUMERO_ALBC_FACCLIN = :n';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos > 0 then
    begin
      NotificarAdvertencia(SAvisoAlbaranCompraFacturado);
      Abort;
    end;
    if not SolicitarConfirmacion(
      Format(SPreguntaBorrarAlbaranCompra,
        [sSerie, sNumero])) then
    begin
      Abort;
    end;
    IniciarBorradoTransaccional;
    try
      inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
        CrearMovimientosAlbaranCompraUniDAC(unqryTablaG.Connection),
        sSerie, sNumero, IdentidadSesion.Usuario);
      q.SQL.Text :=
        'DELETE FROM fza_albaranes_compra_celdas ' +
        ' WHERE SERIE_ALBC_ALBCCEL  = :s ' +
        '   AND NUMERO_ALBC_ALBCCEL = :n';
      AsignarDocumento;
      q.ExecSQL;
      q.SQL.Text :=
        'DELETE FROM fza_albaranes_compra_lineas ' +
        ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
        '   AND NUMERO_ALBC_ALBCLIN = :n';
      AsignarDocumento;
      q.ExecSQL;
    except
      RevertirBorradoTransaccional;
      raise;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesCompraLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesCompraLineas.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('NUMERO_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
    FieldByName('SERIE_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    // Sin numero hasta grabar: el BeforePost asigna el definitivo con
    // el contador de lineas. Un 0000 parecia un error (FZ-ISSUE-224).
    FieldByName('LINEA_ALBCLIN').Clear;
    FieldByName('CANTIDAD_ALBCLIN').AsFloat := 1;
    FieldByName('PORCENTAJE_DTO_ALBCLIN').AsFloat := 0;
    if FindField('ESFACTURADA_ALBCLIN') <> nil then
      FieldByName('ESFACTURADA_ALBCLIN').AsString := 'N';
    // Auditoria estandar: las 4 columnas del libro de estilo bbdd §3.7
    // son NOT NULL sin default; hay que rellenarlas en alta. En BeforePost
    // tambien sobrescribimos USUARIO_MODIF para que refleje la ultima edicion.
    FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
  FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

// True si la linea tiene celdas del pivote antiguo (linea consolidada):
// su TOTAL_UNIDADES guarda el agregado por tallas y no debe machacarse
// con CANTIDAD. Las lineas del modelo contrato no tienen celdas.
function TdmAlbaranesCompra.LineaTieneCeldasPivote(
                                             DataSet: TDataSet): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT 1 ' +
      '  FROM fza_albaranes_compra_celdas ' +
      ' WHERE SERIE_ALBC_ALBCCEL  = :s ' +
      '   AND NUMERO_ALBC_ALBCCEL = :n ' +
      '   AND LINEA_ALBC_ALBCCEL  = :l ' +
      ' LIMIT 1';
    q.ParamByName('s').AsString :=
      DataSet.FieldByName('SERIE_ALBC_ALBCLIN').AsString;
    q.ParamByName('n').AsString :=
      DataSet.FieldByName('NUMERO_ALBC_ALBCLIN').AsString;
    q.ParamByName('l').AsString :=
      DataSet.FieldByName('LINEA_ALBCLIN').AsString;
    q.Open;
    Result := not q.Eof;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesCompraLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesCompraLineas.FindField(ANombre);
  end;
begin
  inherited;
  ExigirDocumentoOrdenEditable(ConexionEscritura,
    DataSet.FieldByName('SERIE_ALBC_ALBCLIN').AsString,
    DataSet.FieldByName('NUMERO_ALBC_ALBCLIN').AsString, True);
  // Desempaquetado ATTR en curso: post descriptivo, sin logica fiscal.
  if not FDesempaquetandoAtributos then
  begin
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, el Post
  // fallaria con 'Field LINEA_ALBCLIN must have a value'. Cancel diferido +
  // Abort la descarta sin molestar al usuario. Mismo patron que Sesiones.
  if (Trim(unqryAlbaranesCompraLineas.FieldByName(
             'CODIGO_ART_ALBCLIN').AsString) = '') and
     (Trim(unqryAlbaranesCompraLineas.FieldByName(
             'CODIGO_UNIDAD_ALBCLIN').AsString) = '') then
  begin
    TThread.RemoveQueuedEvents(CancelarLineaVaciaDiferida);
    TThread.ForceQueue(nil, CancelarLineaVaciaDiferida);
    Abort;
  end;
  if ((Trim(unqryAlbaranesCompraLineas.FieldByName(
              'CODIGO_ART_ALBCLIN').AsString) <> '') or
      (Trim(unqryAlbaranesCompraLineas.FieldByName(
              'CODIGO_UNIDAD_ALBCLIN').AsString) <> '')) and
     ((Trim(unqryTablaG.FieldByName(
              'CODIGO_PRV_ALBC').AsString) = '') or
      (Trim(unqryTablaG.FieldByName(
              'CODIGO_PRV_ALBC').AsString) = '0')) then
  begin
    NotificarAdvertencia(
      SErrorProveedorNoSeleccionadoBuscarArticulos);
    Abort;
  end;
  AsignarNumeroLineaAlbaranCompra(DataSet);
  // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
  NormalizarArticuloSkuEnDataSet(ConexionEscritura,
      unqryAlbaranesCompraLineas, 'CODIGO_ART_ALBCLIN',
      'CODIGO_UNIDAD_ALBCLIN');
  // FZ-ISSUE-520: un SKU dado de baja no recibe existencias.
  ExigirSkuActivoEnDataSet(ConexionEscritura, unqryAlbaranesCompraLineas,
    'CODIGO_ART_ALBCLIN', 'CODIGO_UNIDAD_ALBCLIN', SErrorSkuCompraNoActivo);
    // F-LOTEC-013: antes de los totales (una serie deja la línea en 1).
    if Assigned(FLotesLineas) then
      FLotesLineas.AntesDePostLinea(unqryAlbaranesCompraLineas,
        DocumentoLotes);
    // Modelo contrato (una linea por SKU): TOTAL_UNIDADES acompana a
    // CANTIDAD. La vista de cabecera lo prefiere al contar prendas y se
    // quedaba con el valor antiguo al editar cantidades en el pivote.
    // Tambien aplica a lineas sin SKU (escalares); solo se respeta el
    // agregado de las consolidadas del pivote antiguo (con celdas).
    // Despues de los lotes: repartir series deja la linea en 1 y antes
    // se quedaba con la cantidad original (FZ-ISSUE-320).
    if (DataSet.FindField('TOTAL_UNIDADES_ALBCLIN') <> nil) and
       (DataSet.FindField('CANTIDAD_ALBCLIN') <> nil) then
    begin
      if (Trim(DataSet.FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString) <> '')
         or (not LineaTieneCeldasPivote(DataSet)) then
        DataSet.FieldByName('TOTAL_UNIDADES_ALBCLIN').AsFloat :=
          DataSet.FieldByName('CANTIDAD_ALBCLIN').AsFloat;
    end;
    // Refrescamos auditoria en cada Post (edicion / alta nueva).
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString   := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
    // En alta (State=dsInsert) tambien los campos *_ALTA por si
    // AfterInsert no los puso (p.ej. inserciones programaticas).
    if (DataSet.State = dsInsert) then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
      if (FindField('INSTANTE_ALTA') <> nil) and
         FieldByName('INSTANTE_ALTA').IsNull then
        FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    end;

    // Si el usuario tecleo un SKU pero no el articulo, lo deducimos
    // consultando fza_articulos_skus (mismo patron que en venta).
    if (FindField('CODIGO_UNIDAD_ALBCLIN') <> nil) and
       (FindField('CODIGO_ART_ALBCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_ALBCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlbc.Close;
        unqrySkusAlbc.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlbc.Open;
        if not unqrySkusAlbc.Eof then
          FieldByName('CODIGO_ART_ALBCLIN').AsString :=
            unqrySkusAlbc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusAlbc.Close;
      end;
    end;
  PrepararLineaFiscalCompra(CrearLecturasImpuestos(ConexionEscritura),
    unqryTablaG,
    unqryAlbaranesCompraLineas, 'ALBC', 'ALBCLIN', 'TOTAL_ALBCLIN');
  end;
end;

procedure TdmAlbaranesCompra.AsignarNumeroLineaAlbaranCompra(
                                                       DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_ALBCLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_ALBCLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALBC').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_ALBC').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
          LIN_ALBARANES_COMPRA, sSerie,
          sNumero, sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraAlbaranSinGrabar);
      if DataSet.FindField('NUMERO_ALBC_ALBCLIN') <> nil then
        DataSet.FieldByName('NUMERO_ALBC_ALBCLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_ALBC_ALBCLIN') <> nil then
        DataSet.FieldByName('SERIE_ALBC_ALBCLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionEscritura),
        CONT_ALBARANES_COMPRA, LIN_ALBARANES_COMPRA, sSerie, sNumero);
      if iNuevaLinea = 0 then
      begin
        iNuevaLinea := StrToIntDef(
          unqryTablaG.FieldByName('CONTADOR_LINEAS_ALBC').AsString, 0) + 10;
      end;
      AsignarCampoTextoSiEditable(
        unqryTablaG,
        'CONTADOR_LINEAS_ALBC',
        Format('%.8d', [iNuevaLinea]));
      DataSet.FieldByName('LINEA_ALBCLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

destructor TdmAlbaranesCompra.Destroy;
begin
  FreeAndNil(FLotesLineas);
  inherited;
end;

procedure TdmAlbaranesCompra.ConfigurarLotesLineas(
  const AConfig: TConfiguracionLotesLineas);
begin
  FreeAndNil(FLotesLineas);
  if AConfig.Activacion.AlgunModoActivo then
    FLotesLineas := TLotesLineasDocumento.Create(AConfig);
end;

function TdmAlbaranesCompra.DocumentoLotes: TDocumentoLineaLote;
begin
  Result.TipoDocumento := 'AC';
  Result.Serie := Trim(unqryTablaG.FieldByName('SERIE_ALBC').AsString);
  Result.Numero := Trim(unqryTablaG.FieldByName('NUMERO_ALBC').AsString);
  Result.CodigoAlmacen :=
    Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALBC').AsString);
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  // Antes de copiar lotes pendientes: el cursor cambiará de línea.
  GenerarCodigoLoteLinea(TUniQuery(DataSet).Connection, DataSet,
    'ALBCLIN', IdentidadSesion.Usuario, ParametrosApp);
  if Assigned(FLotesLineas) then
    FLotesLineas.DespuesDePostLinea;
  CalcularTotalesAlbaranCompra;
  // Si los totales han dejado la cabecera en edicion, su Post ejecutara
  // unqryTablaGAfterPost y reconstruira los movimientos una sola vez. Si
  // los importes no han cambiado (p. ej. cambia un SKU manteniendo cantidad
  // y precio), la cabecera sigue en Browse y hay que sincronizar aqui.
  if unqryTablaG.State in dsEditModes then
    unqryTablaG.Post
  else
    SincronizarMovimientos;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterDelete(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaranCompra;
  if unqryTablaG.State in dsEditModes then
    unqryTablaG.Post
  else
    SincronizarMovimientos;
end;

procedure TdmAlbaranesCompra.GetCodigoAutoAlbaranCompra;
var
  iNumero: Int64;
  sNumero: string;
begin
  unstrdprcGetContadorAlbc.Params.Clear;
  unstrdprcGetContadorAlbc.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorAlbc.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorAlbc.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorAlbc.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorAlbc.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorAlbc.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  unstrdprcGetContadorAlbc.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdAlbaran, sdCompra).TipoContador;
  unstrdprcGetContadorAlbc.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorAlbc.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString;
  EjecutarContadorDocumento(unstrdprcGetContadorAlbc);
  sNumero := Trim(
    unstrdprcGetContadorAlbc.ParamByName('pcont').AsString);
  if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
     (iNumero <= 0) then
    raise Exception.Create(Format(SErrorContadorAlbaranCompra,
      [unqryTablaG.FieldByName('SERIE_ALBC').AsString,
       unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString]));
  unqryTablaG.FieldByName('NUMERO_ALBC').AsString := sNumero;
end;

procedure TdmAlbaranesCompra.CalcularTotalesAlbaranCompra;
var
  oCampoPrendas: TField;
  rPrendas: Double;
begin
  // Los posts del desempaquetado ATTR no alteran importes: saltar el
  // recalculo por linea (cascada de consultas de IVA al navegar).
  if not FDesempaquetandoAtributos then
  begin
    // Reorganizacion en bloque en curso: un unico recalculo al Finalizar.
    if FReorganizandoLineas > 0 then
      FReorganizacionPendiente := True
    else
    begin
      CalcularTotalesDocumentoCompra(
        CrearLecturasImpuestos(unqryTablaG.Connection), unqryTablaG,
        unqryAlbaranesCompraLineas, 'ALBC', 'TOTAL_ALBCLIN',
        'TIPO_IVA_ARTICULO_ALBCLIN', 'PORCENTAJE_IVA_ALBCLIN');
      // La vista calcula prendas al abrir; aqui se actualizan en cliente.
      oCampoPrendas := unqryTablaG.FindField('TOTAL_PRENDAS_ALBC');
      if oCampoPrendas <> nil then
      begin
        rPrendas := TotalPrendasLineasCompra(unqryAlbaranesCompraLineas,
          'TIPO_IVA_ARTICULO_ALBCLIN', 'TOTAL_UNIDADES_ALBCLIN',
          UnidadesMedida);
        if oCampoPrendas.IsNull or
           (Abs(oCampoPrendas.AsFloat - rPrendas) > 0.000001) then
        begin
          if not (unqryTablaG.State in [dsEdit, dsInsert]) then
            unqryTablaG.Edit;
          oCampoPrendas.AsFloat := rPrendas;
        end;
      end;
    end;
  end;
end;

function TdmAlbaranesCompra.HayLineasMovimiento(const ASerie,
  ANumero: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
      '   AND NUMERO_ALBC_ALBCLIN = :n ' +
      '   AND IFNULL(CANTIDAD_ALBCLIN, 0) <> 0';
    q.ParamByName('s').AsString := ASerie;
    q.ParamByName('n').AsString := ANumero;
    q.Open;
    Result := q.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranesCompra.RefrescarMovimientosProveedor;
begin
  if unqryMovimientosProveedor.Active then
  begin
    unqryMovimientosProveedor.Close;
    unqryMovimientosProveedor.Open;
  end;
end;

procedure TdmAlbaranesCompra.SincronizarMovimientos;
var
  bTransaccionPropia: Boolean;
  sNumero: string;
  sSerie: string;
begin
  // Los posts del desempaquetado ATTR no tocan cantidades ni SKUs:
  // saltar el borrado/recreacion de movimientos y recalculo de PMP.
  if not FDesempaquetandoAtributos then
  begin
    // La reorganizacion pospone la regeneracion completa de movimientos.
    if FReorganizandoLineas > 0 then
      FReorganizacionPendiente := True
    else if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    begin
      sSerie := Trim(unqryTablaG.FieldByName('SERIE_ALBC').AsString);
      sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALBC').AsString);
      if (sSerie <> '') and (sNumero <> '') and (sNumero <> '0') then
      begin
        bTransaccionPropia := not unqryTablaG.Connection.InTransaction;
        if bTransaccionPropia then
          unqryTablaG.Connection.StartTransaction;
        try
          if not BloquearAlbaranCompra(
            unqryTablaG.Connection, sSerie, sNumero) then
            raise Exception.Create(SErrorAlbaranCompraNoActivo);
          inLibAlbaranesCompraMovimientos.
            RevertirMovimientosDesdeAlbaranCompra(
            CrearMovimientosAlbaranCompraUniDAC(unqryTablaG.Connection),
            sSerie, sNumero, IdentidadSesion.Usuario);
          if HayLineasMovimiento(sSerie, sNumero) then
            inLibAlbaranesCompraMovimientos.
              GenerarMovimientosDesdeAlbaranCompra(
                CrearMovimientosAlbaranCompraUniDAC(
                  unqryTablaG.Connection),
                sSerie, sNumero, IdentidadSesion.Usuario);
          if bTransaccionPropia then
            unqryTablaG.Connection.Commit;
        except
          if bTransaccionPropia and
             unqryTablaG.Connection.InTransaction then
            unqryTablaG.Connection.Rollback;
          raise;
        end;
        FSerieRecepcionSinConfirmar := sSerie;
        FNumeroRecepcionSinConfirmar := sNumero;
        RefrescarMovimientosProveedor;
        if not unqryTablaG.Connection.InTransaction then
          SolicitarProcesadoPrestaShop;
      end;
    end;
  end;
end;

function TdmAlbaranesCompra.HayRecepcionSinConfirmar: Boolean;
begin
  Result := unqryTablaG.Active and not unqryTablaG.IsEmpty and
    (FSerieRecepcionSinConfirmar <> '') and
    (FNumeroRecepcionSinConfirmar <> '') and
    (unqryTablaG.FieldByName('SERIE_ALBC').AsString =
      FSerieRecepcionSinConfirmar) and
    (unqryTablaG.FieldByName('NUMERO_ALBC').AsString =
      FNumeroRecepcionSinConfirmar);
end;

procedure TdmAlbaranesCompra.ConfirmarRecepcion;
begin
  FSerieRecepcionSinConfirmar := '';
  FNumeroRecepcionSinConfirmar := '';
end;

function TdmAlbaranesCompra.TieneEntradasStock: Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_movimientos_almacen ' +
      'WHERE TIPO_DOC_MOV = :TIPO AND SERIE_DOC_MOV = :SERIE ' +
      'AND NUMERO_DOC_MOV = :NUMERO AND ESACTIVO_MOV = ''S'' ' +
      'AND TIPO_MOV = ''E'' AND CANTIDAD_MOV <> 0 LIMIT 1';
    oConsulta.ParamByName('TIPO').AsString := 'AC';
    oConsulta.ParamByName('SERIE').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    oConsulta.ParamByName('NUMERO').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmAlbaranesCompra.IniciarReorganizacionLineas;
begin
  Inc(FReorganizandoLineas);
end;

procedure TdmAlbaranesCompra.FinalizarReorganizacionLineas;
begin
  if FReorganizandoLineas > 0 then
    Dec(FReorganizandoLineas);
  if FReorganizandoLineas = 0 then
  begin
    // La reorganizacion escribe lineas y celdas por SQL directo: sin
    // reabrir el detalle, el grid y el pivote publican datos rancios
    // (tallas vacias hasta reconstruir el modo con F1). Antes lo
    // "arreglaban" las reaperturas en cascada del master-detail.
    if unqryAlbaranesCompraLineas.Active then
    begin
      unqryAlbaranesCompraLineas.Close;
      unqryAlbaranesCompraLineas.Open;
    end;
    // Si hubo posts pospuestos, recalcular totales y movimientos UNA
    // sola vez (ya con datos frescos).
    if FReorganizacionPendiente then
    begin
      FReorganizacionPendiente := False;
      CalcularTotalesAlbaranCompra;
      if unqryTablaG.State in dsEditModes then
        unqryTablaG.Post
      else
        SincronizarMovimientos;
    end;
  end;
end;

function TdmAlbaranesCompra.EnReorganizacionLineas: Boolean;
begin
  Result := FReorganizandoLineas > 0;
end;

procedure TdmAlbaranesCompra.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabAlbcPrint.Close;
  unqryCabAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryCabAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryCabAlbcPrint.Open;
  unqryLinAlbcPrint.Close;
  unqryLinAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryLinAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryLinAlbcPrint.Open;
  unqryGuiasAlbcPrint.Close;
  unqryGuiasAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryGuiasAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryGuiasAlbcPrint.Open;
end;

procedure TdmAlbaranesCompra.CargarAlmacenesDelAlbaran(
                                      const ASerie, ANumero: string;
                                      ALV: TObject);
var
  oQry  : TUniQuery;
  oLv   : TcxListView;
  oItem : TListItem;
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
          'SELECT DISTINCT L.CODIGO_ALMACEN_ALBCLIN AS COD, ' +
          '       COALESCE(A.NOMBRE_ALM_ALM, ' +
          'L.CODIGO_ALMACEN_ALBCLIN) AS NOM ' +
          '  FROM fza_albaranes_compra_lineas L ' +
          '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = ' +
          'L.CODIGO_ALMACEN_ALBCLIN ' +
          ' WHERE L.SERIE_ALBC_ALBCLIN = :s ' +
          'AND L.NUMERO_ALBC_ALBCLIN = :n ' +
          '   AND COALESCE(L.CODIGO_ALMACEN_ALBCLIN, '''') <> '''' ' +
          ' ORDER BY COD';
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

procedure TdmAlbaranesCompra.CrearDataSetEtiquetasAlb(ADmArt: TObject;
                                  const ASerie, ANumero,
                                        ACodTarifa, AAlmacenesCsv: string;
                                  AFecha: TDateTime);
var
  oDmArt  : TdmArticulos;
  sSkus   : string;
begin
  // Reutilizamos el dataset / lookup de etiquetas del DM de articulos
  // (cdsEtiquetasArt, unqryArtPrint, fxdsEtiquetasArt) para que el
  // mismo .fr3 sirva en ambos modales. La query base filtra YA en
  // servidor por SKU IN (...) — la version anterior cargaba todos y
  // filtraba en cliente, tardaba 10 s sobre una BBDD con muchos SKUs.
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    sSkus  := ObtenerSkusAlbaranCsv(ASerie, ANumero);
    if sSkus <> '' then
    begin
      oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, AAlmacenesCsv,
        AFecha, sSkus);
    end;
  end;
end;

function TdmAlbaranesCompra.ObtenerSkusAlbaranCsv(
                                  const ASerie, ANumero: string): string;
var
  oQry : TUniQuery;
begin
  // Devuelve una lista de SKUs lista para inyectar en un IN (...) SQL:
  // ''SKU1'',''SKU2'',... — cada uno entrecomillado y escapado.
  Result := '';
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := ConexionEscritura;
    oQry.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_ALBCLIN ' +
      '  FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN = :s AND NUMERO_ALBC_ALBCLIN = :n ' +
      '   AND COALESCE(CODIGO_UNIDAD_ALBCLIN, '''') <> ''''';
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmAlbaranesCompra.PrepararPrintSku(const ASerie, ANumero: string);
begin
  unqryCabAlbcPrint.Close;
  unqryCabAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryCabAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryCabAlbcPrint.Open;
  unqryLinAlbcSkuPrint.Close;
  unqryLinAlbcSkuPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryLinAlbcSkuPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryLinAlbcSkuPrint.Open;
end;

// Contrato ColumnSKUcxGrid: desglosa el SKU (ART/COLOR/TALLA) en las
// columnas reales ATTR1..5_VALOR_ALBCLIN + NUM_ATRIBUTOS_ALBCLIN.
// Idempotente POR COMPARACION (mismo criterio que pedidos de compra):
// solo edita la linea si algun ATTR o el numero de atributos difiere.
procedure TdmAlbaranesCompra.DesempaquetarAtributosLineas;
begin
  if unqryAlbaranesCompraLineas.Active and
     (not unqryAlbaranesCompraLineas.IsEmpty) and
     (unqryAlbaranesCompraLineas.FindField('ATTR1_VALOR_ALBCLIN') <> nil) and
     (unqryAlbaranesCompraLineas.FindField('NUM_ATRIBUTOS_ALBCLIN') <> nil) and
     (not unqryAlbaranesCompraLineas.ReadOnly) then
  begin
    // Evita recálculos fiscales y movimientos durante los Post descriptivos.
    FDesempaquetandoAtributos := True;
    try
      DesempaquetarAtributosLineasSku(unqryAlbaranesCompraLineas, 'ALBCLIN');
    finally
      FDesempaquetandoAtributos := False;
    end;
  end;
end;


procedure TdmAlbaranesCompra.LineaCircuitoBeforeDelete(DataSet: TDataSet);
begin
  ExigirDocumentoOrdenEditable(ConexionEscritura,
    DataSet.FieldByName('SERIE_ALBC_ALBCLIN').AsString,
    DataSet.FieldByName('NUMERO_ALBC_ALBCLIN').AsString, True);
end;

initialization
  RegistrarDataModule(TdmAlbaranesCompra);
end.
