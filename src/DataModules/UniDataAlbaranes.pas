{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranes                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de albaranes.                                                 }
{    Queries de cabecera y líneas, generación de facturas y movimientos de     }
{    stock asociados.                                                          }
{******************************************************************************}
unit UniDataAlbaranes;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inLibLotesLineaDocumento,
  frxClass, frxDBSet, frCoreClasses,
  inLibAlbaranesVentaPresentacionMovimientos,
  inLibOpcionesDocumentoIntf;

type
  // FZ-ISSUE-233: la linea vende AIncremento mas de lo que tenia y en el
  // almacen hay ADisponible (< AIncremento). El host avisa o bloquea
  // (lanzando una excepcion, que cancela el Post).
  TComprobacionStockLineaEvent = procedure(const ASku, AAlmacen: string;
    AIncremento, ADisponible: Double) of object;

  TdmAlbaranes = class(TdmBase)
    unqryAlbaranesLineas: TUniQuery;
    dsAlbaranesLineas:    TDataSource;
    unqryEmpDataAlb:      TUniQuery;
    unqryCliDataAlb:      TUniQuery;
    unqryArtDataLinAlb:   TUniQuery;
    unqrySkusAlb:         TUniQuery;
    unqryFacturas:        TUniQuery;
    dsFacturas:           TDataSource;
    unqryMovimientosAlb:  TUniQuery;
    dsMovimientosAlb:     TDataSource;
    unqryFormasPago:      TUniQuery;
    dsFormasPago:         TDataSource;
    unqryVendedores:      TUniQuery;
    dsVendedores:         TDataSource;
    unqryAlmacenesAlb:    TUniQuery;
    dsAlmacenesAlb:       TDataSource;
    unqryTarifas:         TUniQuery;
    dsTarifas:            TDataSource;
    unstrdprcGetContadorAlbaran: TUniStoredProc;
    unstrdprcCrearFacturaInicio: TUniStoredProc;
    unstrdprcCrearFacturaLinea:  TUniStoredProc;
    unstrdprcCrearFacturaFin:    TUniStoredProc;
    unstrdprcInsertarMovAlb:     TUniStoredProc;
    fxdsPrintAlb:    TfrxDBDataset;
    fxdstPrintLinAlb:TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
  public
    // Contrato ColumnSKUcxGrid: rellena ATTR1..5_VALOR_ALBLIN y
    // NUM_ATRIBUTOS_ALBLIN troceando el SKU (CODIGO_UNIDAD_ALBLIN) de
    // cada linea. Idempotente POR COMPARACION: solo edita las lineas
    // cuyos ATTR no coinciden con el troceo (leccion de pedidos).
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoAlbaran;
    procedure CalcularTotalesAlbaran;
    // Numero total de prendas (suma CANTIDAD_ALBLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasAlbaran: Double;
    procedure CopiarEmpresaaAlbaran(DataSet: TDataSet);
    procedure CopiarClienteaAlbaran(DataSet: TDataSet);
    function BuscarEmpresa(const ACodigo: string): Boolean;
    function BuscarAlmacen(const ACodigo: string): Boolean;
    function BuscarCliente(const ACodigo: string): Boolean;
    function ClienteExiste(const ACodigo: string): Boolean;
    procedure OpenTables;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure ActualizarImpuestosTarifaCabecera(
      const ACodigoTarifa: string);
    // Override: abre las queries detalle del Mto de Albaranes tras
    // unqryTablaG. Invocada desde TfrmMtoGen.AbrirTablaPrincipalAsync
    // en el callback main thread. OpenTables delega aqui.
    procedure AbrirDetalles; override;

    // Genera factura del albarán cargado en pantalla con las líneas indicadas.
    // Si aLineas es nil, se facturan todas las líneas no facturadas del
    // albarán.
    // AOpciones: serie (vacia = la del albaran), numero (vacio =
    // contador), fecha y forma de pago (vacia = la del albaran) del
    // dialogo comun de creacion de documentos.
    function CrearFacturaDesdeAlbaran(out sNumeroFac, sSerieFac: string;
                                      aLineas: TList<string>;
                                      const AOpciones: TOpcionesDocumento
                                      ): Boolean;

    // Procesa una lista de albaranes (formato 'SERIE|NUMERO') y genera
    // factura(s).
    // Si bAgruparPorCliente es True, agrupa los albaranes del mismo cliente
    // en una única factura. Devuelve número de facturas generadas.
    function FacturarAlbaranesLista(aListaAlbaranes: TStrings;
                                    bAgruparPorCliente: Boolean;
                                    const AOpciones: TOpcionesDocumento
                                    ): Integer;

    // Genera los movimientos de salida de stock asociados a las líneas del
    // albarán cargado. Idempotente: prepara almacén/SKU/línea antes de
    // regenerar y salta líneas que no puedan mover stock.
    // Devuelve el número de movimientos creados.
    function GenerarMovimientosSalida: Integer;
    // F-LOTEC-016: lote y serie de las líneas (solo con interruptores).
    procedure ConfigurarLotesLineas(const AConfig: TConfiguracionLotesLineas);
    function DocumentoLotes: TDocumentoLineaLote;
    // Botón de la columna Lote: vuelve a elegir el de la línea actual.
    procedure ElegirLoteLinea;
  private
    FCalculandoTotales: Boolean;
    FAplicandoDescuento: Boolean;
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal ni
    // la sincronizacion de movimientos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    FOnComprobarStockLinea: TComprobacionStockLineaEvent;
    FLotesLineas: TLotesLineasDocumento;
    procedure LineasAlbaranDataChange(Sender: TObject; Field: TField);
    procedure RecalcularFacturaCreada(const ASerie, ANumero: string);
    function StockDisponibleLineaVenta(const AArticulo, ASku,
      AAlmacen: string; out ADisponible: Double): Boolean;
    procedure ComprobarStockLinea(DataSet: TDataSet);
    // Conexion por la que salen la transaccion, los bloqueos y las
    // lecturas de la operacion: la misma que usan los datasets.
    function ConexionEscritura: TUniConnection;
    procedure EjecutarCrearFacturaInicio(const ANumeroAlbaran,
      ASerieAlbaran: string; const AOpciones: TOpcionesDocumento;
      out ANumeroFactura, ASerieFactura: string);
    procedure EjecutarCrearFacturaLinea(const ANumeroFactura,
      ASerieFactura, ANumeroAlbaran, ASerieAlbaran,
      ALineaAlbaran: string);
    procedure EjecutarCrearFacturaFin(const ANumeroFactura,
      ASerieFactura, ANumeroAlbaran, ASerieAlbaran: string);
    procedure ProcesarCabeceraPosteada;
    procedure ProcesarLineasPosteadas;
    procedure NegarMovimientosFacturaDesdeAlbaran(const ASerie,
                                                  ANumero: string);
    function CrearDocumentoMovimientosSalida:
      TDocumentoMovimientosAlbaranVenta;
    procedure AsignarNumeroLineaAlbaran(DataSet: TDataSet);
    procedure NormalizarCamposOpcionalesLinea(DataSet: TDataSet);
    procedure SincronizarAlmacenLinea(DataSet: TDataSet);
    procedure SincronizarAlmacenLineasCabecera;
    procedure ValidarAlmacenCabecera;
    procedure ValidarClienteCabecera;
    procedure RefrescarDatosMovimientosSalida;
    procedure SincronizarMovimientosSalida;
    // Propone la serie AV de fza_empresas_series de la empresa emisora
    // en documentos nuevos sin numerar (al cambiar la empresa en el alta)
    procedure ProponerSerieEmpresa(const AEmpresa: string);
  public
    property OnComprobarStockLinea: TComprobacionStockLineaEvent
      read FOnComprobarStockLinea write FOnComprobarStockLinea;
  end;

implementation

uses
  inLibLineaSku,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataVendedoresRepositorio,
  System.Diagnostics, System.Variants,
  UniDataAperturaConsultas,
  System.UITypes, inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio, inLibData,
  UniDataAlmacenesEmpresaRepositorio,
  inLibMsgArticulos, inLibMsgFacturas, inLibMsgVentas,
  inLibPrestaShopColaSenal, UniDataClientesRepositorio,
  inLibSqlSeguro, inLibDocumento, inLibDocumentoIntf,
  UniDataAlbaranesVentaMovimientos, UniDataFacturasRecalculoTotales,
  UniDataDescuentosVenta,
  inLibErroresBBDD;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function EstrategiaAlbaranVenta: IEstrategiaDocumento;
begin
  Result := CrearEstrategiaDocumento(
    CrearConfiguracionDocumento(tdAlbaran, sdVenta));
end;

const
  // Columnas REALES de fza_albaranes. La cabecera se lee de
  // vi_albaranes (que anade NOMBRE_ALM_ALB por join y NO es
  // insertable): los DML se generan contra la tabla, como hace
  // pedidos con fza_pedidos en su dfm.
  COLUMNAS_ALBARAN: array[0..93] of string = (
    'PORCENTAJE_DTO_COMERCIAL_ALB',
    'TOTAL_DTO_COMERCIAL_ALB',
    'PORCENTAJE_DTO_FINANCIERO_ALB',
    'TOTAL_DTO_FINANCIERO_ALB',
    'NUMERO_ALB', 'SERIE_ALB', 'FECHA_ALB',
    'INSTANTE_MOVIMIENTO_ALB', 'ESCONSOLIDADO_ALB',
    'ESTADO_ALB', 'NUMERO_PED_ALB', 'SERIE_PED_ALB', 'NUMERO_FAC_ALB',
    'SERIE_FAC_ALB', 'CODIGO_EMP_ALB', 'CODIGO_ALM_ALB',
    'RAZON_SOCIAL_EMPRESA_ALB', 'NIF_EMPRESA_ALB', 'MOVIL_EMPRESA_ALB',
    'EMAIL_EMPRESA_ALB', 'DIRECCION1_EMPRESA_ALB',
    'DIRECCION2_EMPRESA_ALB', 'POBLACION_EMPRESA_ALB',
    'PROVINCIA_EMPRESA_ALB', 'CODIGO_PAI_EMPRESA_ALB',
    'NOMBRE_PAI_EMPRESA_ALB', 'CODIGO_POSTAL_EMPRESA_ALB',
    'GRUPO_ZONA_IVA_EMPRESA_ALB', 'ESRETENCIONES_EMPRESA_ALB',
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_ALB', 'CODIGO_CLI_ALB',
    'RAZON_SOCIAL_CLIENTE_ALB', 'NIF_CLIENTE_ALB', 'MOVIL_CLIENTE_ALB',
    'EMAIL_CLIENTE_ALB', 'DIRECCION1_CLIENTE_ALB',
    'DIRECCION2_CLIENTE_ALB', 'POBLACION_CLIENTE_ALB',
    'PROVINCIA_CLIENTE_ALB', 'CODIGO_POSTAL_CLIENTE_ALB',
    'CODIGO_PAI_CLIENTE_ALB', 'NOMBRE_PAI_CLIENTE_ALB',
    'NOMBRE_CLI_ENVIO_ALB', 'MOVIL_CLIENTE_ENVIO_ALB',
    'DIRECCION1_CLIENTE_ENVIO_ALB', 'DIRECCION2_CLIENTE_ENVIO_ALB',
    'POBLACION_CLIENTE_ENVIO_ALB', 'PROVINCIA_CLIENTE_ENVIO_ALB',
    'CODIGO_POSTAL_CLIENTE_ENVIO_ALB', 'CODIGO_PAI_CLIENTE_ENVIO_ALB',
    'NOMBRE_PAI_CLIENTE_ENVIO_ALB', 'TRANSPORTISTA_ALB',
    'CODIGO_IVA_ALB', 'ESIVA_RECARGO_CLIENTE_ALB',
    'ESIVA_EXENTO_CLIENTE_ALB', 'ESINTRACOMUNITARIO_CLIENTE_ALB',
    'ESRETENCIONES_CLIENTE_ALB', 'ESREGIMENESPECIALAGRICOLA_CLIENTE_ALB',
    'TARIFA_ARTICULO_CLIENTE_ALB', 'ESIMP_INCL_TARIFA_CLIENTE_ALB',
    'ESAPLICA_RE_ZONA_IVA_ALB',
    'PORCENTAJE_REN_ALB',
    'TOTAL_REN_ALB',
    'PORCENTAJE_RER_ALB',
    'TOTAL_RER_ALB',
    'PORCENTAJE_RES_ALB',
    'TOTAL_RES_ALB',
    'PORCENTAJE_REE_ALB',
    'TOTAL_REE_ALB',
    'TOTAL_BASEI_IVAN_ALB',
    'TOTAL_BASEI_IVAR_ALB',
    'TOTAL_BASEI_IVAS_ALB',
    'TOTAL_BASEI_IVAE_ALB',
    'PORCENTAJE_IVAN_ALB', 'TOTAL_IVAN_ALB', 'PORCENTAJE_IVAR_ALB',
    'TOTAL_IVAR_ALB', 'PORCENTAJE_IVAS_ALB', 'TOTAL_IVAS_ALB',
    'PORCENTAJE_IVAE_ALB', 'TOTAL_IVAE_ALB', 'TOTAL_BASES_ALB',
    'TOTAL_IMPUESTOS_ALB', 'PORCENTAJE_RETENCION_ALB',
    'TOTAL_RETENCION_ALB', 'TOTAL_LIQUIDO_ALB', 'FORMA_PAGO_ALB',
    'CONTADOR_LINEAS_ALB', 'COMENTARIOS_ALB', 'OBSERVACIONES_ALB',
    'INSTANTE_MODIF', 'INSTANTE_ALTA', 'USUARIO_ALTA', 'USUARIO_MODIF'
  );

// INSERT INTO fza_albaranes con todas las columnas de la tabla.
function SqlInsertAlbaran: string;
var
  i: Integer;
  sColumnaSql: string;
  sCols, sVals: string;
begin
  sCols := '';
  sVals := '';
  for i := Low(COLUMNAS_ALBARAN) to High(COLUMNAS_ALBARAN) do
  begin
    if i > Low(COLUMNAS_ALBARAN) then
    begin
      sCols := sCols + ', ';
      sVals := sVals + ', ';
    end;
    sColumnaSql := DelimitarIdentificadorSql(
      COLUMNAS_ALBARAN[i],
      COLUMNAS_ALBARAN);
    sCols := sCols + sColumnaSql;
    sVals := sVals + ':' + COLUMNAS_ALBARAN[i];
  end;
  Result := 'INSERT INTO fza_albaranes (' + sCols + ') VALUES (' +
            sVals + ')';
end;

// UPDATE de fza_albaranes por clave primaria (NUMERO+SERIE).
function SqlUpdateAlbaran: string;
var
  i: Integer;
  sColumnaSql: string;
  sSet: string;
begin
  sSet := '';
  for i := Low(COLUMNAS_ALBARAN) to High(COLUMNAS_ALBARAN) do
  begin
    if i > Low(COLUMNAS_ALBARAN) then
      sSet := sSet + ', ';
    sColumnaSql := DelimitarIdentificadorSql(
      COLUMNAS_ALBARAN[i],
      COLUMNAS_ALBARAN);
    sSet := sSet + sColumnaSql + ' = :' + COLUMNAS_ALBARAN[i];
  end;
  Result := 'UPDATE fza_albaranes SET ' + sSet +
            ' WHERE NUMERO_ALB = :Old_NUMERO_ALB' +
            '   AND SERIE_ALB = :Old_SERIE_ALB';
end;

procedure PrepararConsultasFacturacionAlbaranes(
  AConexion: TUniConnection;
  AClientes, ALineas: TUniQuery);
begin
  AClientes.Connection := AConexion;
  ALineas.Connection := AConexion;
  AClientes.SQL.Text :=
    'SELECT CODIGO_CLI_ALB FROM fza_albaranes ' +
    ' WHERE NUMERO_ALB = :pNUM AND SERIE_ALB = :pSER';
  ALineas.SQL.Text :=
    'SELECT LINEA_ALBLIN FROM fza_albaranes_lineas ' +
    ' WHERE NUMERO_ALB_ALBLIN = :pNUM AND SERIE_ALB_ALBLIN = :pSER ' +
    '   AND IFNULL(ESFACTURADA_ALBLIN, ''N'') <> ''S'' ' +
    ' ORDER BY LINEA_ALBLIN';
end;

function DescomponerReferenciaAlbaran(
  const AReferencia: string;
  out ASerie, ANumero: string): Boolean;
var
  Separador: Integer;
begin
  Separador := Pos('|', AReferencia);
  Result := Separador > 0;
  if Result then
  begin
    ASerie := Copy(AReferencia, 1, Separador - 1);
    ANumero := Copy(AReferencia, Separador + 1, MaxInt);
  end;
end;

function ConsultarClienteAlbaran(
  AConsulta: TUniQuery;
  const ANumero, ASerie: string;
  out ACliente: string): Boolean;
begin
  AConsulta.Close;
  AConsulta.ParamByName('pNUM').AsString := ANumero;
  AConsulta.ParamByName('pSER').AsString := ASerie;
  AConsulta.Open;
  Result := not AConsulta.Eof;
  if Result then
    ACliente := AConsulta.FieldByName('CODIGO_CLI_ALB').AsString;
  AConsulta.Close;
end;

procedure AbrirLineasPendientesAlbaran(
  AConsulta: TUniQuery;
  const ANumero, ASerie: string);
begin
  AConsulta.Close;
  AConsulta.ParamByName('pNUM').AsString := ANumero;
  AConsulta.ParamByName('pSER').AsString := ASerie;
  AConsulta.Open;
end;

procedure TdmAlbaranes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // FZ-ISSUE-154: el borrado de la cabecera, todo o nada.
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  unqryTablaG.Connection                 := ConexionPrincipal;
  unqryTablaG.KeyFields                  := 'NUMERO_ALB;SERIE_ALB';
  unqryTablaG.SQLDelete.Text             :=
    'DELETE FROM fza_albaranes ' + sLineBreak +
    'WHERE NUMERO_ALB = :Old_NUMERO_ALB ' + sLineBreak +
    '  AND SERIE_ALB = :Old_SERIE_ALB';
  // La cabecera se lee de vi_albaranes (join a almacenes): la vista NO
  // es insertable y los DML generados por UniDAC contra ella fallan
  // ('target table vi_albaranes ... not insertable-into') al crear un
  // albaran nuevo desde el form. Se escriben contra la tabla real.
  unqryTablaG.SQLInsert.Text             := SqlInsertAlbaran;
  unqryTablaG.SQLUpdate.Text             := SqlUpdateAlbaran;
  unqryTablaG.SQLRefresh.Text            :=
    'SELECT V.* ' +
    '  FROM vi_albaranes V ' +
    ' WHERE V.NUMERO_ALB = :NUMERO_ALB ' +
    '   AND V.SERIE_ALB = :SERIE_ALB';
  unqryAlbaranesLineas.Connection        := ConexionPrincipal;
  dsAlbaranesLineas.OnDataChange         := LineasAlbaranDataChange;
  unqryEmpDataAlb.Connection             := ConexionPrincipal;
  unqryCliDataAlb.Connection             := ConexionPrincipal;
  unqryArtDataLinAlb.Connection          := ConexionPrincipal;
  unqrySkusAlb.Connection                := ConexionPrincipal;
  unqryFacturas.Connection               := ConexionPrincipal;
  unqryMovimientosAlb.Connection         := ConexionPrincipal;
  unqryFormasPago.Connection             := ConexionPrincipal;
  unqryVendedores := CrearConsultaVendedores(Self, ConexionPrincipal);
  dsVendedores := TDataSource.Create(Self);
  dsVendedores.DataSet := unqryVendedores;
  unqryAlmacenesAlb.Connection           := ConexionPrincipal;
  unqryTarifas.Connection                := ConexionPrincipal;
  unstrdprcGetContadorAlbaran.Connection := ConexionPrincipal;
  unstrdprcCrearFacturaInicio.Connection := ConexionPrincipal;
  unstrdprcCrearFacturaLinea.Connection  := ConexionPrincipal;
  unstrdprcCrearFacturaFin.Connection    := ConexionPrincipal;
  unstrdprcInsertarMovAlb.Connection     := ConexionPrincipal;
  VigilarTotalMaximoLinea(unqryAlbaranesLineas, 'TOTAL_ALBLIN');
end;

procedure TdmAlbaranes.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FLotesLineas);
  if Assigned(unqryAlbaranesLineas) and unqryAlbaranesLineas.Active then
    unqryAlbaranesLineas.Close;
  if Assigned(unqryFacturas) and unqryFacturas.Active then
    unqryFacturas.Close;
  if Assigned(unqryMovimientosAlb) and unqryMovimientosAlb.Active then
    unqryMovimientosAlb.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryVendedores) and unqryVendedores.Active then
    unqryVendedores.Close;
  if Assigned(unqryAlmacenesAlb) and unqryAlmacenesAlb.Active then
    unqryAlmacenesAlb.Close;
  if Assigned(unqryTarifas) and unqryTarifas.Active then
    unqryTarifas.Close;
  inherited;
end;

procedure TdmAlbaranes.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmAlbaranes.AbrirDetalles;
const
  TAG = 'Albaranes.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  RefrescarAlmacenes(UbicacionSesion.Empresa);
  AbrirConsultaConTiempo(
    unqryAlbaranesLineas, TAG, 'unqryAlbaranesLineas', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFacturas, TAG, 'unqryFacturas', RegistroLog);
  AbrirConsultaConTiempo(
    unqryMovimientosAlb, TAG, 'unqryMovimientosAlb', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFormasPago, TAG, 'unqryFormasPago', RegistroLog);
  AbrirConsultaConTiempo(
    unqryVendedores, TAG, 'unqryVendedores', RegistroLog);
  AbrirConsultaConTiempo(
    unqryTarifas, TAG, 'unqryTarifas', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAlbaranes.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesAlb.Active) or
     (not SameText(unqryAlmacenesAlb.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesAlb.Close;
    unqryAlmacenesAlb.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesAlb.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_ALB', 'CODIGO_ALM_ALB');
end;

procedure TdmAlbaranes.unqryTablaGAfterInsert(DataSet: TDataSet);
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
  FieldByName('NUMERO_ALB').AsString := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='AV'
    // (mismo criterio que compras); fallback historico 'A1'
    sSerie := ObtenerSerieDefecto(
      ConexionEscritura,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdAlbaran, sdVenta).TipoContador);
    if sSerie = '' then
      sSerie := 'A1';
    if FindField('SERIE_ALB') <> nil then
      FieldByName('SERIE_ALB').AsString := sSerie;
    FieldByName('INSTANTE_MOVIMIENTO_ALB').AsDateTime := Now;
    FieldByName('FECHA_ALB').AsDateTime :=
      Trunc(FieldByName('INSTANTE_MOVIMIENTO_ALB').AsDateTime);
    if FindField('ESTADO_ALB') <> nil then
      FieldByName('ESTADO_ALB').AsString := 'ABIERTO';
    if FindField('ESCONSOLIDADO_ALB') <> nil then
      FieldByName('ESCONSOLIDADO_ALB').AsString := 'N';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_ALB').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_ALB').AsString := '0';
    if FindField('CODIGO_ALM_ALB') <> nil then
      FieldByName('CODIGO_ALM_ALB').AsString := UbicacionSesion.Almacen;
    // Vacío, no «0»: lo tecleado se pegaba detrás (FZ-ISSUE-301)
    FieldByName('CODIGO_CLI_ALB').Clear;
    FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').Clear;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_ALB').Clear;
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
  if FindField('CODIGO_ALM_ALB') <> nil then
    FieldByName('CODIGO_ALM_ALB').AsString := UbicacionSesion.Almacen;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_ALB').AsString);
end;

procedure TdmAlbaranes.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  SincronizarInstanteMovimientoDocumento(
    DataSet, 'FECHA_ALB', 'INSTANTE_MOVIMIENTO_ALB');
  ValidarAlmacenCabecera;
  ValidarClienteCabecera;
  if (unqryTablaG.FieldByName('NUMERO_ALB').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALB').AsString = '') then
    GetCodigoAutoAlbaran;
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'ALB');
  CalcularTotalesAlbaran;
end;

procedure TdmAlbaranes.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  // El vendedor no va en COLUMNAS_ALBARAN: se guarda aparte, si la base
  // trae la columna.
  GuardarVendedorRegistro(ConexionEscritura, DataSet, 'fza_albaranes',
    'CODIGO_VENDEDOR_ALB', ['NUMERO_ALB', 'SERIE_ALB']);
  ProcesarCabeceraPosteada;
end;

procedure TdmAlbaranes.unqryTablaGBeforeDelete(DataSet: TDataSet);
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
  sSerie  := DataSet.FieldByName('SERIE_ALB').AsString;
  sNumero := DataSet.FieldByName('NUMERO_ALB').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes ' +
      ' WHERE SERIE_ALB  = :s ' +
      '   AND NUMERO_ALB = :n ' +
      '   AND (COALESCE(NUMERO_FAC_ALB, '''') <> '''' ' +
      '    OR COALESCE(SERIE_FAC_ALB, '''') <> '''' ' +
      '    OR COALESCE(ESTADO_ALB, '''') = ''FACTURADO'')';
    AsignarDocumento;
    q.Open;
    iBloqueos := q.FieldByName('N').AsInteger;
    q.Close;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_albaranes_lineas ' +
        ' WHERE SERIE_ALB_ALBLIN  = :s ' +
        '   AND NUMERO_ALB_ALBLIN = :n ' +
        '   AND (COALESCE(ESFACTURADA_ALBLIN, ''N'') = ''S'' ' +
        '    OR COALESCE(NUMERO_FAC_ALBLIN, '''') <> '''' ' +
        '    OR COALESCE(SERIE_FAC_ALBLIN, '''') <> '''')';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos > 0 then
    begin
      NotificarAdvertencia(SAvisoAlbaranFacturado);
      Abort;
    end;
    if not SolicitarConfirmacion(
      Format(SPreguntaBorrarAlbaran,
        [sSerie, sNumero])) then
    begin
      Abort;
    end;
    IniciarBorradoTransaccional;
    try
      q.SQL.Text := 'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
      q.ParamByName('t').AsString :=
        EstrategiaAlbaranVenta.TipoDocumentoMovimientoStock;
      AsignarDocumento;
      q.ExecSQL;
      q.SQL.Text :=
        'DELETE FROM fza_albaranes_lineas ' +
        ' WHERE SERIE_ALB_ALBLIN  = :s ' +
        '   AND NUMERO_ALB_ALBLIN = :n';
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

// Defaults de las columnas del contrato ColumnSKUcxGrid en una linea
// recien insertada (ver comentario en AfterInsert).
procedure InicializarColumnasSkuLinea(ADataSet: TDataSet);
var
  i: Integer;
begin
  if ADataSet.FindField('NUM_ATRIBUTOS_ALBLIN') <> nil then
    ADataSet.FieldByName('NUM_ATRIBUTOS_ALBLIN').AsInteger := 0;
  if ADataSet.FindField('ID_AC_PIVOT_ALBLIN') <> nil then
    ADataSet.FieldByName('ID_AC_PIVOT_ALBLIN').AsInteger := 0;
  for i := 1 to 5 do
  begin
    if ADataSet.FindField('ATTR' + IntToStr(i) + '_VALOR_ALBLIN') <> nil
    then
      ADataSet.FieldByName(
        'ATTR' + IntToStr(i) + '_VALOR_ALBLIN').AsString := '';
    if ADataSet.FindField('ATTR' + IntToStr(i) + '_NOMBRE_ALBLIN') <> nil
    then
      ADataSet.FieldByName(
        'ATTR' + IntToStr(i) + '_NOMBRE_ALBLIN').AsString := '';
  end;
end;

// Linea sin identificar el articulo: ni codigo ni SKU.
function LineaAlbaranVacia(ADataSet: TDataSet): Boolean;
  function CampoVacio(const ANombre: string): Boolean;
  var
    Campo: TField;
  begin
    Result := True;
    Campo := ADataSet.FindField(ANombre);
    if Campo <> nil then
      Result := Trim(Campo.AsString) = '';
  end;
begin
  Result := CampoVacio('CODIGO_ART_ALBLIN') and
            CampoVacio('CODIGO_UNIDAD_ALBLIN');
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FindField(ANombre);
  end;
begin
  inherited;
  // Sin numero hasta grabar: el BeforePost asigna el definitivo con
  // el contador de lineas. Un 0000 parecia un error (FZ-ISSUE-224).
  FieldByName('LINEA_ALBLIN').Clear;
    FieldByName('NUMERO_ALB_ALBLIN').AsString :=
                                  unqryTablaG.FieldByName(
                                    'NUMERO_ALB').AsString;
    FieldByName('SERIE_ALB_ALBLIN').AsString  :=
                                  unqryTablaG.FieldByName('SERIE_ALB').AsString;
    if (FindField('CODIGO_ALMACEN_ALBLIN') <> nil) and
       (unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil) then
      FieldByName('CODIGO_ALMACEN_ALBLIN').AsString :=
        unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString;
    FieldByName('CANTIDAD_ALBLIN').AsFloat := 1;
    if FindField('ESFACTURADA_ALBLIN') <> nil then
      FieldByName('ESFACTURADA_ALBLIN').AsString := 'N';
    if FindField('CODIGO_TAR_ALBLIN') <> nil then
      FieldByName('CODIGO_TAR_ALBLIN').AsString :=
        unqryTablaG.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    if FindField('ESIMP_INCL_TARIFA_ALBLIN') <> nil then
      FieldByName('ESIMP_INCL_TARIFA_ALBLIN').AsString :=
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_ALB').AsString;
    // Columnas del contrato ColumnSKUcxGrid: NOT NULL en BBDD con
    // DEFAULT de servidor que el cliente no conoce; sin inicializarlas
    // el Post lanza "must have a value" (leccion de pedidos).
    InicializarColumnasSkuLinea(unqryAlbaranesLineas);
    if FindField('USUARIO_ALTA') <> nil then
      FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_ALTA') <> nil then
      FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
  if FindField('INSTANTE_MODIF') <> nil then
    FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmAlbaranes.NormalizarCamposOpcionalesLinea(DataSet: TDataSet);
var
  q: TUniQuery;
  sArticulo: string;
  bTrazable: Boolean;
  bVariacion: Boolean;
  iSkus: Integer;
begin
  sArticulo := '';
  bTrazable := False;
  bVariacion := False;
  iSkus := 0;
  if (DataSet <> nil) and DataSet.Active and
     (DataSet.FindField('CODIGO_ART_ALBLIN') <> nil) then
    sArticulo := Trim(DataSet.FieldByName('CODIGO_ART_ALBLIN').AsString);
  if sArticulo <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
        'SELECT a.ESTRAZABLE_ART, a.ESVARIACION_ART, ' +
        '       (SELECT COUNT(*) ' +
        '          FROM fza_articulos_skus sk ' +
        '         WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
        '           AND COALESCE(sk.ESACTIVO_SKU, ''S'') = ''S'') AS NUM_SKUS '
          +
        '  FROM fza_articulos a ' +
        ' WHERE a.CODIGO_ART_ART = :art';
      q.ParamByName('art').AsString := sArticulo;
      q.Open;
      if not q.IsEmpty then
      begin
        bTrazable := q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
        bVariacion := q.FieldByName('ESVARIACION_ART').AsString = 'S';
        iSkus := q.FieldByName('NUM_SKUS').AsInteger;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
  if not bTrazable then
  begin
    if DataSet.FindField('LOTE_ALBLIN') <> nil then
      DataSet.FieldByName('LOTE_ALBLIN').Clear;
    if DataSet.FindField('FECHA_CADUCIDAD_ALBLIN') <> nil then
      DataSet.FieldByName('FECHA_CADUCIDAD_ALBLIN').Clear;
  end;
  if (not bVariacion) and (iSkus <= 1) and
     (DataSet.FindField('DESCRIPCION_VARIACION_ALBLIN') <> nil) then
    DataSet.FieldByName('DESCRIPCION_VARIACION_ALBLIN').Clear;
  if (iSkus = 0) and
     (DataSet.FindField('CODIGO_UNIDAD_ALBLIN') <> nil) then
    DataSet.FieldByName('CODIGO_UNIDAD_ALBLIN').Clear;
end;

procedure TdmAlbaranes.SincronizarAlmacenLinea(DataSet: TDataSet);
var
  sAlmacen: string;
begin
  if (DataSet <> nil) and (DataSet.FindField('CODIGO_ALMACEN_ALBLIN') <> nil)
     and
     (unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil) then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
    DataSet.FieldByName('CODIGO_ALMACEN_ALBLIN').AsString := sAlmacen;
  end;
end;

procedure TdmAlbaranes.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString) = '') then
  begin
    NotificarAdvertencia(SAvisoAlmacenSalidaAlbaranObligatorio);
    Abort;
  end;
end;

// Todo albarán se factura: sin cliente (vacío o «0») o con uno inexistente
// no graba (FZ-ISSUE-301). Solo al crearlo o al cambiar el cliente, para
// que los albaranes antiguos con «0» sigan recalculando totales.
procedure TdmAlbaranes.ValidarClienteCabecera;
var
  oCampo: TField;
  sCliente: string;
  bValidar: Boolean;
begin
  sCliente := '';
  oCampo := unqryTablaG.FindField('CODIGO_CLI_ALB');
  bValidar := oCampo <> nil;
  if bValidar then
  begin
    sCliente := Trim(oCampo.AsString);
    bValidar := (unqryTablaG.State <> dsEdit) or
      (sCliente <> Trim(VarToStr(oCampo.OldValue)));
  end;
  if bValidar and ((sCliente = '') or (sCliente = '0')) then
  begin
    NotificarAdvertencia(SAvisoClienteAlbaranObligatorio);
    Abort;
  end;
  if bValidar and not ClienteExiste(sCliente) then
  begin
    NotificarAdvertencia(Format(SAvisoClienteAlbaranNoExiste, [sCliente]));
    Abort;
  end;
end;

procedure TdmAlbaranes.SincronizarAlmacenLineasCabecera;
var
  q: TUniQuery;
  sAlmacen: string;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
    if (sAlmacen <> '') and (sNumero <> '') and (sNumero <> '0') and
       (sSerie <> '') then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := unqryTablaG.Connection;
        q.SQL.Text :=
          'UPDATE fza_albaranes_lineas ' +
          '   SET CODIGO_ALMACEN_ALBLIN = :alm ' +
          ' WHERE NUMERO_ALB_ALBLIN = :num ' +
          '   AND SERIE_ALB_ALBLIN  = :ser ' +
          '   AND COALESCE(CODIGO_ALMACEN_ALBLIN, '''') <> :alm';
        q.ParamByName('alm').AsString := sAlmacen;
        q.ParamByName('num').AsString := sNumero;
        q.ParamByName('ser').AsString := sSerie;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
      if unqryAlbaranesLineas.Active then
      begin
        if unqryAlbaranesLineas.State in dsEditModes then
          SincronizarAlmacenLinea(unqryAlbaranesLineas)
        else
        begin
          unqryAlbaranesLineas.Close;
          unqryAlbaranesLineas.Open;
        end;
      end;
    end;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
var
  sSku, sArt: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FindField(ANombre);
  end;
begin
  inherited;
  // Desempaquetado ATTR en curso: post descriptivo, sin logica fiscal.
  if not FDesempaquetandoAtributos then
  begin
  // Guarda ColumnSKUcxGrid (leccion de pedidos, bucle 07/07/2026): un
  // Post de linea sin articulo ni SKU no debe llegar a BBDD ni
  // consumir contador de lineas.
  // FZ-ISSUE-422: es una validacion esperada (aviso normal), no un
  // fallo del programa con pila y envio al soporte.
  if LineaAlbaranVacia(DataSet) then
    raise EValidacionBBDD.Create(SErrorLineaAlbaranSinArticulo);
  AsignarNumeroLineaAlbaran(DataSet);
  SincronizarAlmacenLinea(DataSet);
  // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
  NormalizarArticuloSkuEnDataSet(ConexionEscritura,
      unqryAlbaranesLineas, 'CODIGO_ART_ALBLIN',
      'CODIGO_UNIDAD_ALBLIN');
  ExigirSkuCompletoEnDataSet(ConexionEscritura, unqryAlbaranesLineas,
    'CODIGO_ART_ALBLIN', 'CODIGO_UNIDAD_ALBLIN', 'ID_AC_PIVOT_ALBLIN');
  ComprobarStockLinea(DataSet);
    NormalizarCamposOpcionalesLinea(DataSet);
    // F-LOTEC-016: antes de los totales (una serie deja la línea en 1).
    if Assigned(FLotesLineas) then
      FLotesLineas.AntesDePostLinea(unqryAlbaranesLineas, DocumentoLotes);
    if (FindField('CANTIDAD_ALBLIN') <> nil) and
       (FindField('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN') <> nil) and
       (FindField('TOTAL_ALBLIN') <> nil) then
      PrepararLineaFiscalVenta(CrearLecturasImpuestos(ConexionEscritura),
        unqryTablaG,
        unqryAlbaranesLineas, 'ALB', 'ALBLIN', 'TOTAL_ALBLIN');

    // Si el usuario ha tecleado un SKU pero no el artículo, lo deducimos
    // consultando fza_articulos_skus.
    if (FindField('CODIGO_UNIDAD_ALBLIN') <> nil) and
       (FindField('CODIGO_ART_ALBLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_ALBLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlb.Close;
        unqrySkusAlb.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlb.Open;
        if not unqrySkusAlb.Eof then
          FieldByName('CODIGO_ART_ALBLIN').AsString :=
                                  unqrySkusAlb.FieldByName(
                                    'CODIGO_ART_SKU').AsString;
        unqrySkusAlb.Close;
      end;
    end;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  if DataSet.State = dsInsert then
  begin
    if (FindField('USUARIO_ALTA') <> nil) and
       (FieldByName('USUARIO_ALTA').AsString = '') then
      FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    if (FindField('INSTANTE_ALTA') <> nil) and
       FieldByName('INSTANTE_ALTA').IsNull then
      FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
  end;
end;

procedure TdmAlbaranes.AsignarNumeroLineaAlbaran(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_ALBLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_ALBLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
          LIN_ALBARANES, sSerie, sNumero,
          sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraAlbaranSinGrabar);
      if DataSet.FindField('NUMERO_ALB_ALBLIN') <> nil then
        DataSet.FieldByName('NUMERO_ALB_ALBLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_ALB_ALBLIN') <> nil then
        DataSet.FieldByName('SERIE_ALB_ALBLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionEscritura),
        CONT_ALBARANES, LIN_ALBARANES, sSerie, sNumero);
      // El helper ya persiste CONTADOR_LINEAS_ALB en BBDD dentro de su
      // propia transaccion. NO se toca unqryTablaG (leccion de
      // pedidos: el Edit dejaba la cabecera en edicion sin postear y
      // encadenaba re-Posts de cabecera + recargas del detalle). La
      // copia en memoria desfasada es inocua: el helper toma siempre
      // MAX(LINEA_ALBLIN) como suelo.
      if iNuevaLinea = 0 then
        raise Exception.Create(Format(SErrorAsignarLineaAlbaran,
                                      [sSerie, sNumero]));
      DataSet.FieldByName('LINEA_ALBLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmAlbaranes.DesempaquetarAtributosLineas;
begin
  if unqryAlbaranesLineas.Active and
     (not unqryAlbaranesLineas.IsEmpty) and
     (unqryAlbaranesLineas.FindField('ATTR1_VALOR_ALBLIN') <> nil) then
  begin
    // Evita recálculos fiscales y movimientos durante los Post descriptivos.
    FDesempaquetandoAtributos := True;
    try
      DesempaquetarAtributosLineasSku(unqryAlbaranesLineas, 'ALBLIN');
    finally
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  if Assigned(FLotesLineas) and not FDesempaquetandoAtributos then
    FLotesLineas.DespuesDePostLinea;
  if not FDesempaquetandoAtributos then
    ProcesarLineasPosteadas;
end;

procedure TdmAlbaranes.ConfigurarLotesLineas(
  const AConfig: TConfiguracionLotesLineas);
begin
  FreeAndNil(FLotesLineas);
  if AConfig.Activacion.AlgunModoActivo then
    FLotesLineas := TLotesLineasDocumento.Create(AConfig);
end;

function TdmAlbaranes.DocumentoLotes: TDocumentoLineaLote;
begin
  Result.TipoDocumento := 'AV';
  Result.Serie := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
  Result.Numero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
  Result.CodigoAlmacen :=
    Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
end;

procedure TdmAlbaranes.ElegirLoteLinea;
begin
  if Assigned(FLotesLineas) and unqryAlbaranesLineas.Active and
     not unqryAlbaranesLineas.IsEmpty then
    FLotesLineas.ElegirLote(unqryAlbaranesLineas, DocumentoLotes);
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
begin
  inherited;
  ProcesarLineasPosteadas;
end;

function TdmAlbaranes.TotalPrendasAlbaran: Double;
begin
  Result := TotalPrendasLineasVenta(unqryAlbaranesLineas,
    'TIPO_IVA_ARTICULO_ALBLIN');
end;

procedure TdmAlbaranes.GetCodigoAutoAlbaran;
var
  iNumero: Int64;
  sNumero: string;
begin
  unstrdprcGetContadorAlbaran.Params.Clear;
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorAlbaran.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_ALB').AsString;
  unstrdprcGetContadorAlbaran.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdAlbaran, sdVenta).TipoContador;
  unstrdprcGetContadorAlbaran.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorAlbaran.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString;
  EjecutarContadorDocumento(unstrdprcGetContadorAlbaran);
  sNumero := Trim(
    unstrdprcGetContadorAlbaran.ParamByName('pcont').AsString);
  if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
     (iNumero <= 0) then
    raise Exception.Create(Format(SErrorContadorAlbaran,
      [unqryTablaG.FieldByName('SERIE_ALB').AsString,
       unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString]));
  unqryTablaG.FieldByName('NUMERO_ALB').AsString := sNumero;
end;

// Stock del SKU en el almacen; False si el articulo no mueve stock
// (SERVICIO, mismo criterio que UniDataAlbaranesVentaMovimientos).
function TdmAlbaranes.StockDisponibleLineaVenta(const AArticulo, ASku,
  AAlmacen: string; out ADisponible: Double): Boolean;
var
  q: TUniQuery;
begin
  ADisponible := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionEscritura;
    q.SQL.Text :=
      'SELECT COALESCE((SELECT UPPER(TRIM(A.TIPO_ART)) ' +
      '                   FROM fza_articulos A ' +
      '                  WHERE A.CODIGO_ART_ART = :ART), ' +
      '                ''ESTANDAR'') AS TIPO, ' +
      '       COALESCE((SELECT SUM(S.CANTIDAD_STK) ' +
      '                   FROM fza_articulos_stockactual S ' +
      '                  WHERE S.CODIGO_UNIDAD_STK = :SKU ' +
      '                    AND S.CODIGO_ALM_STK = :ALM), 0) ' +
      '         AS DISPONIBLE';
    q.ParamByName('ART').AsString := AArticulo;
    q.ParamByName('SKU').AsString := ASku;
    q.ParamByName('ALM').AsString := AAlmacen;
    q.Open;
    Result := q.FieldByName('TIPO').AsString <> 'SERVICIO';
    ADisponible := q.FieldByName('DISPONIBLE').AsFloat;
  finally
    q.Free;
  end;
end;

// FZ-ISSUE-233: solo cuenta lo que la linea vende de mas respecto a lo
// que ya tenia grabado (ese stock ya esta descontado).
procedure TdmAlbaranes.ComprobarStockLinea(DataSet: TDataSet);
var
  sArticulo, sSku, sAlmacen: string;
  rIncremento, rDisponible: Double;
  oCantidad, oSku, oAlmacen: TField;
begin
  oCantidad := DataSet.FindField('CANTIDAD_ALBLIN');
  oSku := DataSet.FindField('CODIGO_UNIDAD_ALBLIN');
  oAlmacen := DataSet.FindField('CODIGO_ALMACEN_ALBLIN');
  if Assigned(FOnComprobarStockLinea) and (oCantidad <> nil) and
     (oSku <> nil) and (oAlmacen <> nil) then
  begin
    sArticulo := DataSet.FieldByName('CODIGO_ART_ALBLIN').AsString;
    sSku := Trim(oSku.AsString);
    sAlmacen := Trim(oAlmacen.AsString);
    rIncremento := oCantidad.AsFloat;
    if (DataSet.State = dsEdit) and
       SameText(VarToStr(oSku.OldValue), oSku.AsString) and
       SameText(VarToStr(oAlmacen.OldValue), oAlmacen.AsString) and
       not VarIsNull(oCantidad.OldValue) then
      rIncremento := rIncremento - oCantidad.OldValue;
    if (sSku <> '') and (sAlmacen <> '') and (rIncremento > 0.0000001) and
       StockDisponibleLineaVenta(sArticulo, sSku, sAlmacen,
         rDisponible) and
       (rIncremento > rDisponible + 0.0000001) then
      FOnComprobarStockLinea(sSku, sAlmacen, rIncremento, rDisponible);
  end;
end;

// FZ-ISSUE-202: el Total de la linea se refresca al aceptar la cantidad o
// el precio, no solo al grabar (2,50 m x 9,90 seguia mostrando 9,90).
procedure TdmAlbaranes.LineasAlbaranDataChange(Sender: TObject;
  Field: TField);
begin
  if not FAplicandoDescuento then
  begin
    FAplicandoDescuento := True;
    try
      AplicarDescuentoLineaVenta(Field, 'ALBLIN');
      if (not FDesempaquetandoAtributos) and
         EsCampoImporteLineaVenta(Field, 'ALBLIN') then
        RecalcularTotalLineaVenta(unqryAlbaranesLineas, 'ALBLIN',
          'TOTAL_ALBLIN');
    finally
      FAplicandoDescuento := False;
    end;
  end;
end;

procedure TdmAlbaranes.CalcularTotalesAlbaran;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(
        CrearLecturasImpuestos(unqryTablaG.Connection), unqryTablaG,
        unqryAlbaranesLineas, 'ALB', 'TOTAL_ALBLIN',
        'TIPO_IVA_ARTICULO_ALBLIN', 'PORCENTAJE_IVA_ALBLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

function TdmAlbaranes.CrearDocumentoMovimientosSalida:
  TDocumentoMovimientosAlbaranVenta;
var
  Estrategia: IEstrategiaDocumento;
begin
  Result := Default(TDocumentoMovimientosAlbaranVenta);
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    Estrategia := EstrategiaAlbaranVenta;
    Result.Serie := Trim(
      unqryTablaG.FieldByName('SERIE_ALB').AsString);
    Result.Numero := Trim(
      unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    Result.Empresa := unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString;
    Result.Cliente := unqryTablaG.FieldByName('CODIGO_CLI_ALB').AsString;
    Result.Usuario := IdentidadSesion.Usuario;
    Result.TipoDocumento := Estrategia.TipoDocumentoMovimientoStock;
    Result.TipoMovimiento := Estrategia.TipoMovimientoStock;
    Result.InstanteMovimiento := Now;
    if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
      Result.Almacen := Trim(
        unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
    if not unqryTablaG.FieldByName('INSTANTE_MOVIMIENTO_ALB').IsNull then
      Result.InstanteMovimiento := unqryTablaG.FieldByName(
        'INSTANTE_MOVIMIENTO_ALB').AsDateTime
    else if not unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      Result.InstanteMovimiento :=
        unqryTablaG.FieldByName('FECHA_ALB').AsDateTime;
  end;
end;

procedure TdmAlbaranes.RefrescarDatosMovimientosSalida;
begin
  if unqryAlbaranesLineas.Active and
     (not (unqryAlbaranesLineas.State in dsEditModes)) then
  begin
    unqryAlbaranesLineas.Close;
    unqryAlbaranesLineas.Open;
  end;
  if unqryMovimientosAlb.Active then
  begin
    unqryMovimientosAlb.Close;
    unqryMovimientosAlb.Open;
  end;
end;

procedure TdmAlbaranes.SincronizarMovimientosSalida;
var
  Documento: TDocumentoMovimientosAlbaranVenta;
  Operacion: IOperacionMovimientosAlbaranVenta;
begin
  Documento := CrearDocumentoMovimientosSalida;
  if Documento.PuedeSincronizar then
  begin
    Operacion := CrearOperacionMovimientosAlbaranVenta(
      CrearPersistenciaMovimientosAlbaranVentaUniDAC(
        unqryTablaG.Connection,
        unstrdprcInsertarMovAlb,
        RegistroLog),
      CrearUnidadTrabajoMovimientosAlbaranVentaUniDAC(
        unqryTablaG.Connection));
    Operacion.Sincronizar(Documento);
    RefrescarDatosMovimientosSalida;
  end;
end;

function TdmAlbaranes.ConexionEscritura: TUniConnection;
begin
  // Cada ventana de mantenimiento crea su propia conexion y reasigna a
  // ella los datasets (TdmBase.ReasignarConexion). La transaccion, los
  // SELECT ... FOR UPDATE y las lecturas de la operacion tienen que ir
  // por esa misma conexion: si salen por ConexionPrincipal, el UPDATE
  // del dataset acaba esperando un bloqueo que retiene el propio
  // programa desde otra conexion (MariaDB 1205, lock wait timeout).
  Result := nil;
  if Assigned(unqryTablaG) then
    Result := unqryTablaG.Connection;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
end;

procedure TdmAlbaranes.ProcesarCabeceraPosteada;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not ConexionEscritura.InTransaction;
  if bTransaccionPropia then
    ConexionEscritura.StartTransaction;
  try
    SincronizarAlmacenLineasCabecera;
    SincronizarMovimientosSalida;
    if bTransaccionPropia and ConexionEscritura.InTransaction then
    begin
      ConexionEscritura.Commit;
      SolicitarProcesadoPrestaShop;
    end;
  except
    if bTransaccionPropia and ConexionEscritura.InTransaction then
      ConexionEscritura.Rollback;
    raise;
  end;
end;

procedure TdmAlbaranes.ProcesarLineasPosteadas;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not ConexionEscritura.InTransaction;
  if bTransaccionPropia then
    ConexionEscritura.StartTransaction;
  try
    CalcularTotalesAlbaran;
    // Si el calculo cambia la cabecera, su AfterPost sincroniza los
    // movimientos dentro de esta misma transaccion. Evita reconstruirlos
    // de nuevo al volver al flujo de la linea.
    if unqryTablaG.State in dsEditModes then
      unqryTablaG.Post
    else
      SincronizarMovimientosSalida;
    if bTransaccionPropia and ConexionEscritura.InTransaction then
    begin
      ConexionEscritura.Commit;
      SolicitarProcesadoPrestaShop;
    end;
  except
    if bTransaccionPropia and ConexionEscritura.InTransaction then
      ConexionEscritura.Rollback;
    raise;
  end;
end;

function TdmAlbaranes.BuscarEmpresa(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMP_EMP = :empresa';
      q.ParamByName('empresa').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        // CopiarEmpresaaAlbaran ya repropone la serie de la empresa
        CopiarEmpresaaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmAlbaranes.BuscarAlmacen(const ACodigo: string): Boolean;
var
  qAlm: TUniQuery;
  qEmp: TUniQuery;
  sCodigo: string;
  sEmpresa: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if sCodigo <> '' then
  begin
    qAlm := TUniQuery.Create(nil);
    qEmp := TUniQuery.Create(nil);
    try
      qAlm.Connection := unqryTablaG.Connection;
      qAlm.SQL.Text :=
        'SELECT CODIGO_ALM_ALM, CODIGO_EMP_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_ALM_ALM = :alm ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S''';
      qAlm.ParamByName('alm').AsString := sCodigo;
      qAlm.Open;
      if not qAlm.IsEmpty then
      begin
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString := sCodigo;
        sEmpresa := qAlm.FieldByName('CODIGO_EMP_ALM').AsString;
        qEmp.Connection := unqryTablaG.Connection;
        qEmp.SQL.Text :=
          'SELECT * ' +
          '  FROM fza_empresas ' +
          ' WHERE CODIGO_EMP_EMP = :empresa';
        qEmp.ParamByName('empresa').AsString := sEmpresa;
        qEmp.Open;
        if not qEmp.IsEmpty then
          CopiarEmpresaaAlbaran(qEmp);
        if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString := sCodigo;
        Result := True;
      end;
    finally
      FreeAndNil(qEmp);
      FreeAndNil(qAlm);
    end;
  end;
end;

procedure TdmAlbaranes.ProponerSerieEmpresa(const AEmpresa: string);
var
  sSerie: string;
  sNumero: string;
begin
  if (unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    // Solo documentos nuevos sin numerar: un documento ya numerado
    // conserva su serie aunque se retoque la empresa
    if (sNumero = '') or (sNumero = '0') then
    begin
      sSerie := ObtenerSerieDefecto(
        ConexionEscritura,
        AEmpresa,
        CrearConfiguracionDocumento(
          tdAlbaran, sdVenta).TipoContador);
      if sSerie <> '' then
        unqryTablaG.FieldByName('SERIE_ALB').AsString := sSerie;
    end;
  end;
end;

function TdmAlbaranes.BuscarCliente(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_clientes ' +
                    ' WHERE CODIGO_CLI_CLI = :cliente';
      q.ParamByName('cliente').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarClienteaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmAlbaranes.ClienteExiste(const ACodigo: string): Boolean;
begin
  Result := ExisteClienteCodigo(unqryTablaG.Connection, ACodigo);
end;

procedure TdmAlbaranes.CopiarEmpresaaAlbaran(DataSet: TDataSet);
var
  sAlmacen: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_EMP_ALB').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_ALB').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_ALB').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_ALB').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_ALB').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_ALB').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_ALB').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_ALB').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_ALB').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_ALB').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_ALB').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_ALB').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_ALB').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
    // El motor fiscal decide la retencion con estos indicadores.
    FindField('ESRETENCIONES_EMPRESA_ALB').AsString  :=
      DataSet.FindField('ESRETENCIONES_EMP').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_EMPRESA_ALB').AsString :=
      DataSet.FindField('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
  if FindField('CODIGO_ALM_ALB') <> nil then
  begin
    RefrescarAlmacenes(DataSet.FindField('CODIGO_EMP_EMP').AsString);
    sAlmacen := Trim(FieldByName('CODIGO_ALM_ALB').AsString);
    if (sAlmacen <> '') and
       unqryAlmacenesAlb.Locate('CODIGO_ALM_ALM', sAlmacen, []) then
      FieldByName('CODIGO_ALM_ALB').AsString := sAlmacen
    else if (Trim(UbicacionSesion.Almacen) <> '') and
            unqryAlmacenesAlb.Locate('CODIGO_ALM_ALM',
                                     UbicacionSesion.Almacen,
                                     []) then
      FieldByName('CODIGO_ALM_ALB').AsString := UbicacionSesion.Almacen
    else
      FieldByName('CODIGO_ALM_ALB').Clear;
  end;
  // La serie acompana a la empresa emisora (fza_empresas_series).
  // Cubre las dos rutas: codigo tecleado (BuscarEmpresa) y modal.
  ProponerSerieEmpresa(DataSet.FindField('CODIGO_EMP_EMP').AsString);
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'ALB');
end;

procedure TdmAlbaranes.ActualizarImpuestosTarifaCabecera(
  const ACodigoTarifa: string);
var
  sTarifa: string;
begin
  sTarifa := Trim(ACodigoTarifa);
  if unqryTablaG.Active and (unqryTablaG.State in dsEditModes) then
  begin
    if sTarifa = '' then
      unqryTablaG.FieldByName(
        'ESIMP_INCL_TARIFA_CLIENTE_ALB').Clear
    else
    begin
      if not unqryTarifas.Active then
        unqryTarifas.Open;
      if unqryTarifas.Locate('CODIGO_TAR_ARTTAR', sTarifa, []) then
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_ALB').AsString :=
          unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString
      else
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_ALB').Clear;
    end;
  end;
end;

procedure TdmAlbaranes.CopiarClienteaAlbaran(DataSet: TDataSet);
var
  sTarifa: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_CLI_ALB').AsString          :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_ALB').AsString:=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_ALB').AsString         :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_ALB').AsString       :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_ALB').AsString       :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_ALB').AsString  :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_ALB').AsString  :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_ALB').AsString   :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_ALB').AsString   :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_ALB').AsString :=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_ALB').AsString  :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_ALB').AsString  :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_ALB').AsString:=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_ALB').AsString:=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_ALB').AsString :=
                            DataSet.FindField(
                              'ESINTRACOMUNITARIO_CLI').AsString;
    FindField('ESRETENCIONES_CLIENTE_ALB').AsString :=
      DataSet.FindField('ESRETENCIONES_CLI').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_CLIENTE_ALB').AsString :=
      DataSet.FindField('ESREGIMENESPECIALAGRICOLA_CLI').AsString;
    sTarifa := Trim(DataSet.FindField('TARIFA_ARTICULO_CLI').AsString);
    if sTarifa = '' then
      sTarifa := ParametrosCaja.TarifaDefecto;
  FindField('TARIFA_ARTICULO_CLIENTE_ALB').AsString := sTarifa;
  ActualizarImpuestosTarifaCabecera(sTarifa);
  ProponerVendedorCliente(DataSet, unqryTablaG, 'CODIGO_VENDEDOR_ALB');
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'ALB');
end;

procedure TdmAlbaranes.NegarMovimientosFacturaDesdeAlbaran(
  const ASerie, ANumero: string);
var
  qryFactura: TUniQuery;
begin
  qryFactura := TUniQuery.Create(nil);
  try
    qryFactura.Connection := ConexionEscritura;
    qryFactura.SQL.Text :=
      'UPDATE fza_facturas ' +
      '   SET ESMUEVE_STOCK_FAC = ''N'', ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :pUSUARIO ' +
      ' WHERE SERIE_FAC = :pSERIE ' +
      '   AND NUMERO_FAC = :pNUMERO';
    qryFactura.ParamByName('pUSUARIO').AsString := IdentidadSesion.Usuario;
    qryFactura.ParamByName('pSERIE').AsString := ASerie;
    qryFactura.ParamByName('pNUMERO').AsString := ANumero;
    qryFactura.ExecSQL;
  finally
    FreeAndNil(qryFactura);
  end;
end;


procedure TdmAlbaranes.EjecutarCrearFacturaInicio(
  const ANumeroAlbaran, ASerieAlbaran: string;
  const AOpciones: TOpcionesDocumento;
  out ANumeroFactura, ASerieFactura: string);
var
  oProc: TUniStoredProc;
  oParams: TParams;
begin
  oProc := unstrdprcCrearFacturaInicio;
  oProc.StoredProcName := 'PRC_ALB_CREAR_FACTURA_INICIO_OPCIONES';
  oParams := oProc.Params;
  oParams.Clear;
  oParams.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_ALB', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_FAC_NUEVA', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_MANUAL', ptInput);
  oParams.CreateParam(ftDate, 'p_FECHA', ptInput);
  oParams.CreateParam(ftString, 'p_FORMA_PAGO', ptInput);
  oParams.CreateParam(ftString, 'p_USUARIO', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_FAC', ptOutput);
  oParams.CreateParam(ftString, 'p_SERIE_FAC', ptOutput);
  oProc.ParamByName('p_NUMERO_ALB').AsString := ANumeroAlbaran;
  oProc.ParamByName('p_SERIE_ALB').AsString := ASerieAlbaran;
  oProc.ParamByName('p_SERIE_FAC_NUEVA').AsString := AOpciones.Serie;
  oProc.ParamByName('p_NUMERO_MANUAL').AsString := AOpciones.Numero;
  if AOpciones.Fecha > 0 then
    oProc.ParamByName('p_FECHA').AsDate := AOpciones.Fecha
  else
    oProc.ParamByName('p_FECHA').Clear;
  oProc.ParamByName('p_FORMA_PAGO').AsString := AOpciones.FormaPago;
  oProc.ParamByName('p_USUARIO').AsString := IdentidadSesion.Usuario;
  oProc.ExecProc;
  ANumeroFactura := oProc.ParamByName('p_NUMERO_FAC').AsString;
  ASerieFactura := oProc.ParamByName('p_SERIE_FAC').AsString;
end;

procedure TdmAlbaranes.EjecutarCrearFacturaLinea(
  const ANumeroFactura, ASerieFactura, ANumeroAlbaran,
  ASerieAlbaran, ALineaAlbaran: string);
begin
  unstrdprcCrearFacturaLinea.Params.Clear;
  unstrdprcCrearFacturaLinea.Params.CreateParam(
    ftString, 'p_NUMERO_FAC', ptInput);
  unstrdprcCrearFacturaLinea.Params.CreateParam(
    ftString, 'p_SERIE_FAC', ptInput);
  unstrdprcCrearFacturaLinea.Params.CreateParam(
    ftString, 'p_NUMERO_ALB', ptInput);
  unstrdprcCrearFacturaLinea.Params.CreateParam(
    ftString, 'p_SERIE_ALB', ptInput);
  unstrdprcCrearFacturaLinea.Params.CreateParam(
    ftString, 'p_LINEA_ALB', ptInput);
  unstrdprcCrearFacturaLinea.Params.CreateParam(
    ftString, 'p_USUARIO', ptInput);
  unstrdprcCrearFacturaLinea.ParamByName('p_NUMERO_FAC').AsString :=
    ANumeroFactura;
  unstrdprcCrearFacturaLinea.ParamByName('p_SERIE_FAC').AsString :=
    ASerieFactura;
  unstrdprcCrearFacturaLinea.ParamByName('p_NUMERO_ALB').AsString :=
    ANumeroAlbaran;
  unstrdprcCrearFacturaLinea.ParamByName('p_SERIE_ALB').AsString :=
    ASerieAlbaran;
  unstrdprcCrearFacturaLinea.ParamByName('p_LINEA_ALB').AsString :=
    ALineaAlbaran;
  unstrdprcCrearFacturaLinea.ParamByName('p_USUARIO').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcCrearFacturaLinea.ExecProc;
end;

// FZ-ISSUE-242: los procedimientos copian los importes del albaran tal
// cual (37,125 de un albaran anterior al redondeo a centimos). La factura,
// documento fiscal, se recalcula con el motor de facturas dentro de la
// misma transaccion: lineas a centimos, IVA por tipo, base de linea.
procedure TdmAlbaranes.RecalcularFacturaCreada(const ASerie,
  ANumero: string);
var
  sMensaje: string;
begin
  CopiarDescuentosAlbaranBorrador(ConexionEscritura, ASerie, ANumero);
  if not RecalcularTotalesFacturaVenta(ConexionEscritura, ASerie, ANumero,
       sMensaje) then
    raise Exception.CreateFmt(SErrorRecalculoFacturaDesdeAlbaran,
      [ASerie, ANumero, sMensaje]);
end;

procedure TdmAlbaranes.EjecutarCrearFacturaFin(
  const ANumeroFactura, ASerieFactura, ANumeroAlbaran,
  ASerieAlbaran: string);
begin
  unstrdprcCrearFacturaFin.Params.Clear;
  unstrdprcCrearFacturaFin.Params.CreateParam(
    ftString, 'p_NUMERO_FAC', ptInput);
  unstrdprcCrearFacturaFin.Params.CreateParam(
    ftString, 'p_SERIE_FAC', ptInput);
  unstrdprcCrearFacturaFin.Params.CreateParam(
    ftString, 'p_NUMERO_ALB', ptInput);
  unstrdprcCrearFacturaFin.Params.CreateParam(
    ftString, 'p_SERIE_ALB', ptInput);
  unstrdprcCrearFacturaFin.Params.CreateParam(
    ftString, 'p_USUARIO', ptInput);
  unstrdprcCrearFacturaFin.ParamByName('p_NUMERO_FAC').AsString :=
    ANumeroFactura;
  unstrdprcCrearFacturaFin.ParamByName('p_SERIE_FAC').AsString :=
    ASerieFactura;
  unstrdprcCrearFacturaFin.ParamByName('p_NUMERO_ALB').AsString :=
    ANumeroAlbaran;
  unstrdprcCrearFacturaFin.ParamByName('p_SERIE_ALB').AsString :=
    ASerieAlbaran;
  unstrdprcCrearFacturaFin.ParamByName('p_USUARIO').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcCrearFacturaFin.ExecProc;
end;

function TdmAlbaranes.CrearFacturaDesdeAlbaran(out sNumeroFac,
                                               sSerieFac: string;
                                               aLineas: TList<string>;
                                               const AOpciones:
                                                 TOpcionesDocumento
                                               ): Boolean;
var
  i: Integer;
  sNumeroAlb, sSerieAlb, sLinea: string;
  ds: TDataSet;
  bUsarTodas: Boolean;
  bTransPropia: Boolean;
begin
  sNumeroFac := '';
  sSerieFac  := '';
  sNumeroAlb := unqryTablaG.FieldByName('NUMERO_ALB').AsString;
  sSerieAlb  := unqryTablaG.FieldByName('SERIE_ALB').AsString;
  bUsarTodas := (aLineas = nil) or (aLineas.Count = 0);

  bTransPropia := not ConexionEscritura.InTransaction;
  if bTransPropia then
    ConexionEscritura.StartTransaction;
  try

  // 1) Cabecera de la factura
  EjecutarCrearFacturaInicio(
    sNumeroAlb, sSerieAlb, AOpciones, sNumeroFac, sSerieFac);
  NegarMovimientosFacturaDesdeAlbaran(sSerieFac, sNumeroFac);

  // 2) Líneas: las indicadas, o todas las pendientes si no se pasa lista.
  if bUsarTodas then
  begin
    ds := unqryAlbaranesLineas;
    ds.DisableControls;
    try
      ds.First;
      while not ds.Eof do
      begin
        if (ds.FindField('ESFACTURADA_ALBLIN') = nil) or
           (ds.FieldByName('ESFACTURADA_ALBLIN').AsString <> 'S') then
          EjecutarCrearFacturaLinea(
            sNumeroFac,
            sSerieFac,
            sNumeroAlb,
            sSerieAlb,
            ds.FieldByName('LINEA_ALBLIN').AsString);
        ds.Next;
      end;
    finally
      ds.EnableControls;
    end;
  end
  else
  begin
    for i := 0 to aLineas.Count - 1 do
    begin
      sLinea := aLineas[i];
      if sLinea <> '' then
        EjecutarCrearFacturaLinea(
          sNumeroFac,
          sSerieFac,
          sNumeroAlb,
          sSerieAlb,
          sLinea);
    end;
  end;

  // 3) Recalcular totales y estado del albarán.
  EjecutarCrearFacturaFin(
    sNumeroFac, sSerieFac, sNumeroAlb, sSerieAlb);
  RecalcularFacturaCreada(sSerieFac, sNumeroFac);

    if bTransPropia and ConexionEscritura.InTransaction then
      ConexionEscritura.Commit;
  except
    if bTransPropia and ConexionEscritura.InTransaction then
      ConexionEscritura.Rollback;
    raise;
  end;

  // 4) Refrescar la pantalla.
  unqryAlbaranesLineas.Close; unqryAlbaranesLineas.Open;
  if unqryFacturas.Active then
  begin
    unqryFacturas.Close;
    unqryFacturas.Open;
  end;
  unqryTablaG.RefreshRecord;
  Result := True;
end;

function TdmAlbaranes.FacturarAlbaranesLista(
  aListaAlbaranes: TStrings;
  bAgruparPorCliente: Boolean;
  const AOpciones: TOpcionesDocumento): Integer;
var
  i: Integer;
  sSer, sNum, sCliActual, sCliAlb: string;
  sNumFac, sSerFac, sNumFacActual, sSerFacActual: string;
  qCli, qLin: TUniQuery;
  bTransPropia: Boolean;
begin
  Result := 0;
  if (aListaAlbaranes <> nil) and (aListaAlbaranes.Count > 0) then
  begin
    qCli := TUniQuery.Create(nil);
    qLin := TUniQuery.Create(nil);
    try
      PrepararConsultasFacturacionAlbaranes(
        ConexionEscritura, qCli, qLin);
      bTransPropia := not ConexionEscritura.InTransaction;
      if bTransPropia then
        ConexionEscritura.StartTransaction;
      try
        sCliActual := '';
        sNumFacActual := '';
        sSerFacActual := '';
        for i := 0 to aListaAlbaranes.Count - 1 do
        begin
          if DescomponerReferenciaAlbaran(
               aListaAlbaranes[i], sSer, sNum) and
             ConsultarClienteAlbaran(qCli, sNum, sSer, sCliAlb) then
          begin
            if (not bAgruparPorCliente) or
               (sNumFacActual = '') or
               (sCliAlb <> sCliActual) then
            begin
              EjecutarCrearFacturaInicio(
                sNum, sSer, AOpciones, sNumFac, sSerFac);
              NegarMovimientosFacturaDesdeAlbaran(sSerFac, sNumFac);
              sNumFacActual := sNumFac;
              sSerFacActual := sSerFac;
              sCliActual := sCliAlb;
              Inc(Result);
            end
            else
            begin
              sNumFac := sNumFacActual;
              sSerFac := sSerFacActual;
            end;
            AbrirLineasPendientesAlbaran(qLin, sNum, sSer);
            while not qLin.Eof do
            begin
              EjecutarCrearFacturaLinea(
                sNumFac, sSerFac, sNum, sSer,
                qLin.FieldByName('LINEA_ALBLIN').AsString);
              qLin.Next;
            end;
            qLin.Close;
            EjecutarCrearFacturaFin(sNumFac, sSerFac, sNum, sSer);
            // Agrupando por cliente, la factura se recalcula tras cada
            // albaran añadido: la ultima vez queda con todas sus lineas.
            RecalcularFacturaCreada(sSerFac, sNumFac);
          end;
        end;
        if bTransPropia and ConexionEscritura.InTransaction then
          ConexionEscritura.Commit;
      except
        if bTransPropia and ConexionEscritura.InTransaction then
          ConexionEscritura.Rollback;
        raise;
      end;
    finally
      FreeAndNil(qCli);
      FreeAndNil(qLin);
    end;
    if unqryTablaG.Active then
      unqryTablaG.Refresh;
    if unqryAlbaranesLineas.Active then
    begin
      unqryAlbaranesLineas.Close;
      unqryAlbaranesLineas.Open;
    end;
    if unqryFacturas.Active then
    begin
      unqryFacturas.Close;
      unqryFacturas.Open;
    end;
  end;
end;

function TdmAlbaranes.GenerarMovimientosSalida: Integer;
var
  Documento: TDocumentoMovimientosAlbaranVenta;
  Operacion: IOperacionMovimientosAlbaranVenta;
begin
  Result := 0;
  Documento := CrearDocumentoMovimientosSalida;
  if Documento.TieneIdentidad then
  begin
    Operacion := CrearOperacionMovimientosAlbaranVenta(
      CrearPersistenciaMovimientosAlbaranVentaUniDAC(
        unqryTablaG.Connection,
        unstrdprcInsertarMovAlb,
        RegistroLog),
      CrearUnidadTrabajoMovimientosAlbaranVentaUniDAC(
        unqryTablaG.Connection));
    Result := Operacion.GenerarFaltantes(Documento);
    RefrescarDatosMovimientosSalida;
  end;
end;

initialization
  RegistrarDataModule(TdmAlbaranes);
end.
