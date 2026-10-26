{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasCompra                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de facturas de compra. La factura genera asiento, pero no     }
{    mueve stock: la entrada ya se produjo al cerrar el albaran de compra.     }
{    Su codigo de contador y serie se obtiene de la configuracion documental.  }
{******************************************************************************}
unit UniDataFacturasCompra;

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
  // FZ-ISSUE-168: otra factura del mismo proveedor con el mismo documento.
  TFacturaCompraRepetida = record
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
  end;
  TDecisionFacturaCompraRepetida = (dfrRegistrar, dfrAbrirExistente,
    dfrCancelar);
  // La pantalla decide; sin manejador (procesos sin interfaz) se registra.
  TConfirmarFacturaCompraRepetida = reference to function(
    const ADocumento, AProveedor: string;
    const AExistente: TFacturaCompraRepetida): TDecisionFacturaCompraRepetida;

  TdmFacturasCompra = class(TdmBase)
    unqryFacturasCompraLineas: TUniQuery;
    dsFacturasCompraLineas:    TDataSource;
    unqryEfectos:              TUniQuery;
    dsEfectos:                 TDataSource;
    unqryEmpDataFacc:           TUniQuery;
    unqryPrvDataFacc:           TUniQuery;
    dsPrvDataFacc:              TDataSource;
    unqryArtDataLinFacc:        TUniQuery;
    unqrySkusFacc:              TUniQuery;
    unqryFormasPago:            TUniQuery;
    dsFormasPago:               TDataSource;
    unqryAlmacenesFacc:         TUniQuery;
    dsAlmacenesFacc:            TDataSource;
    unstrdprcGetContadorFacc:   TUniStoredProc;
    // Definicion de atributos del articulo padre (para columnas
    // dinamicas ATTR1..ATTR5 en modo "atributo por columna").
    unqryDefArticuloFacc:       TUniQuery;
    // Datasets para impresion del factura via FastReport. Mismo patron
    // que TdmComprasSesiones (unqry*Print -> ds*Print -> fxds*). El
    // .fr3 embebido en el modal inMtoModalImpFacCompra.dfm los
    // referencia por UserName ('Factura', 'LineasFactura').
    unqryCabFaccPrint:          TUniQuery;
    dsCabFaccPrint:             TDataSource;
    fxdsCabFacc:                TfrxDBDataset;
    unqryLinFaccPrint:          TUniQuery;
    dsLinFaccPrint:             TDataSource;
    fxdsLinFacc:                TfrxDBDataset;
    unqryGuiasFaccPrint:        TUniQuery;
    dsGuiasFaccPrint:           TDataSource;
    fxdsGuiasFacc:              TfrxDBDataset;
    // Lineas "planas" (una fila por SKU sin pivotar por talla) para el
    // formato vertical estilo factura.
    unqryLinFaccSkuPrint:       TUniQuery;
    dsLinFaccSkuPrint:          TDataSource;
    fxdsLinFaccSku:             TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasBeforeDelete(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasAfterPost(DataSet: TDataSet);
  private
    // Transicion de estado detectada en BeforePost. La aplicamos en
    // AfterPost para que la cabecera ya este guardada en BBDD cuando
    // generamos/revertimos los movimientos. Valores: 'CERRAR' (mov.
    // salida nueva), 'ABRIR' (revertir mov. existentes) o ''.
    FTransicionEstadoFacc: string;
    FEsCompraDirecta: Boolean;
    FProveedoresDirectosBusqueda: TUniQuery;
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal ni
    // la sincronizacion de movimientos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    // F-LOTEC-013: lote de las líneas (nil = como siempre).
    FLotesLineas: TLotesLineasDocumento;
    procedure AsignarCompraDirecta(AValor: Boolean);
    procedure CancelarLineaVaciaDiferida;
    procedure AsignarNumeroLineaFacturaCompra(DataSet: TDataSet);
    function ObtenerSkusFacturaCsv(const ASerie, ANumero: string): string;
    procedure ComprobarDocumentoExternoRepetido(DataSet: TDataSet);
  public
    // FZ-ISSUE-168: la pantalla pregunta si la factura del proveedor ya
    // estaba registrada. Si decide abrir la existente, el Post se aborta y
    // FacturaRepetidaAAbrir indica cuál.
    OnFacturaRepetida: TConfirmarFacturaCompraRepetida;
    FacturaRepetidaAAbrir: TFacturaCompraRepetida;
    destructor Destroy; override;
    procedure ConfigurarLotesLineas(
      const AConfig: TConfiguracionLotesLineas);
    // Documento actual para el lote de las líneas (tipo FP).
    function DocumentoLotes: TDocumentoLineaLote;
    function BuscarFacturaCompraRepetida(
      const AProveedor, ADocumento, ASerieExcluida, ANumeroExcluido: string;
      out AExistente: TFacturaCompraRepetida): Boolean;
    function DatosBusquedaProveedoresDirectos: TDataSet;
    procedure CargarSeriesCompra(AElementos: TStrings);
    procedure ActualizarModalidadCompra;
    property EsCompraDirecta: Boolean read FEsCompraDirecta
      write AsignarCompraDirecta;
    procedure GetCodigoAutoFacturaCompra;
    procedure CalcularTotalesFacturaCompra;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    // Numero total de prendas (suma CANTIDAD_FACCLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasFactura: Double;
    // Contrato ColumnSKUcxGrid: desglosa el SKU ART/COLOR/TALLA en las
    // columnas reales ATTR1..5_VALOR_FACCLIN + NUM_ATRIBUTOS_FACCLIN
    // (idempotente por comparacion, mismo criterio que albaranes compra).
    procedure DesempaquetarAtributosLineas;
    // Genera los efectos de pago de la factura activa segun su forma de pago
    // (PRC_EFEC_GENERAR_DESDE_FACTURA) y refresca la rejilla. Devuelve nº de
    // efectos generados, 0 si nada, -1 sin factura activa / error. Si se pasa
    // ACodEmpban estampa la cuenta de la empresa (cargo) en los efectos.
    function GenerarEfectos(const ACodEmpban: string = '';
                            const AIbanEmp: string = ''): Integer;
    // Cuenta de la empresa (cargo) por defecto del proveedor
    // (CODIGO_EMPBAN_PRV)
    // para pre-seleccionarla en el modal de seleccion de banco. '' si no tiene.
    function GetBancoDefectoProveedor(const ACodigoPrv: string): string;
    // Forma de pago por defecto del proveedor (CODIGO_FP_PRV). '' si no tiene.
    function GetFormaPagoDefectoProveedor(const ACodigoPrv: string): string;
    // Carga en la cabecera (FORMA_PAGO_FACC) la forma de pago del proveedor.
    // Se llama al cargar/cambiar el proveedor en la factura.
    procedure CargarFormaPagoProveedor(const ACodigoPrv: string);
    // Concilia un pago sobre un efecto y refresca la rejilla. Si es parcial,
    // la BBDD divide el efecto en pagado y pendiente.
    function RegistrarPagoEfecto(ANumEfecto: Integer; AFecha: TDateTime;
      AImporte: Double; const ATipo, AReferencia: string): Integer;
    // Abre unqryCabFaccPrint y unqryLinFaccPrint con los parametros
    // del factura a imprimir. Mismo nombre/firma que en sesiones.
    procedure PrepararPrint(const ASerie, ANumero: string);
    // Version SKU (lineas planas, sin pivote talla) para el modal
    // vertical estilo factura.
    procedure PrepararPrintSku(const ASerie, ANumero: string);
    // Carga en el listview los almacenes distintos que aparecen en las
    // lineas del factura (usado por el modal de pegatinas).
    procedure CargarAlmacenesDelFactura(const ASerie, ANumero: string;
                                         ALV: TObject);
    // Crea el dataset cdsEtiquetasArt del DM articulos filtrado a los
    // SKUs del factura. Reutiliza la query base de etiquetas anyadiendo
    // un WHERE por SKU IN (SELECT ... FROM facturas_compra_lineas).
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
  UniDataCodigosBarrasLote,
  inLibLineaSku,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inLibContadorLineas, inLibDatasets,
  UniDataContadorLineasRepositorio,
  System.Diagnostics, System.UITypes,
  UniDataAperturaConsultas,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibData, UniDataAlmacenesEmpresaRepositorio,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibMsgCompras, inLibDocumento, inLibDocumentoIntf,
  UniDataDatosProveedorDocumento, UniDataComprasDirectas,
  inLibComprasDirectas, UniDataComprasDirectasFiscal;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TdmFacturasCompra.ConexionEscritura: TUniConnection;
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

procedure TdmFacturasCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // FZ-ISSUE-154: el borrado de la cabecera, todo o nada.
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  unqryTablaG.Connection                := ConexionPrincipal;
  unqryTablaG.KeyFields                 := 'NUMERO_FACC;SERIE_FACC';
  unqryTablaG.SQLDelete.Text            :=
    'DELETE FROM fza_facturas_compra ' + sLineBreak +
    'WHERE NUMERO_FACC = :Old_NUMERO_FACC ' + sLineBreak +
    '  AND SERIE_FACC = :Old_SERIE_FACC';
  unqryFacturasCompraLineas.Connection := ConexionPrincipal;
  unqryEmpDataFacc.Connection           := ConexionPrincipal;
  unqryPrvDataFacc.Connection           := ConexionPrincipal;
  // Lookup completo de proveedores (NOMBRE_PRV + RAZON_SOCIAL_PRV) para
  // el rotulo resuelto de la cabecera y para el combo de busqueda
  // incremental por codigo (cbbCODIGO_PRV_FACC). Se abre una vez y se
  // recorre con Locate; no depende del proveedor de la factura en
  // pantalla.
  unqryPrvDataFacc.Open;
  unqryArtDataLinFacc.Connection        := ConexionPrincipal;
  unqrySkusFacc.Connection              := ConexionPrincipal;
  unqryFormasPago.Connection            := ConexionPrincipal;
  unqryAlmacenesFacc.Connection         := ConexionPrincipal;
  unstrdprcGetContadorFacc.Connection   := ConexionPrincipal;
  unqryDefArticuloFacc.Connection       := ConexionPrincipal;
  unqryEfectos.Connection := ConexionPrincipal;
  unqryFacturasCompraLineas.BeforeDelete :=
    unqryFacturasCompraLineasBeforeDelete;
  VigilarTotalMaximoLinea(unqryFacturasCompraLineas, 'TOTAL_FACCLIN');
end;

// Master-detail server-side: el WHERE del SQL toma los valores de
// dsTablaG (master), evitando descargar fza_facturas_compra_lineas
// entera y filtrar en cliente.
procedure TdmFacturasCompra.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryFacturasCompraLineas.MasterSource := ADataSource;
  unqryEfectos.MasterSource := ADataSource;
end;

procedure TdmFacturasCompra.DataModuleDestroy(Sender: TObject);
begin
  TThread.RemoveQueuedEvents(CancelarLineaVaciaDiferida);
  if Assigned(unqryFacturasCompraLineas) and
     unqryFacturasCompraLineas.Active then
    unqryFacturasCompraLineas.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryAlmacenesFacc) and unqryAlmacenesFacc.Active then
    unqryAlmacenesFacc.Close;
  inherited;
end;

procedure TdmFacturasCompra.CancelarLineaVaciaDiferida;
var
  oArticulo, oSku: TField;
begin
  if not (csDestroying in ComponentState) and
     Assigned(unqryFacturasCompraLineas) and
     unqryFacturasCompraLineas.Active and
     (unqryFacturasCompraLineas.State in dsEditModes) then
  begin
    oArticulo := unqryFacturasCompraLineas.FindField(
      'CODIGO_ART_FACCLIN');
    oSku := unqryFacturasCompraLineas.FindField(
      'CODIGO_UNIDAD_FACCLIN');
    if (oArticulo <> nil) and (oSku <> nil) and
       (Trim(oArticulo.AsString) = '') and
       (Trim(oSku.AsString) = '') then
      unqryFacturasCompraLineas.Cancel;
  end;
end;

procedure TdmFacturasCompra.OpenTables;
begin
  // Delegamos en AbrirDetalles para unificar logging y cronometro.
  AbrirDetalles;
end;

procedure TdmFacturasCompra.AbrirDetalles;
const
  TAG = 'FacturasCompra.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  RefrescarAlmacenes('');
  AbrirConsultaConTiempo(
    unqryFacturasCompraLineas, TAG, 'unqryFacturasCompraLineas',
    RegistroLog);
  AbrirConsultaConTiempo(
    unqryEfectos, TAG, 'unqryEfectos', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFormasPago, TAG, 'unqryFormasPago', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmFacturasCompra.RefrescarAlmacenes(
  const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_FACC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesFacc.Active) or
     (not SameText(unqryAlmacenesFacc.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesFacc.Close;
    unqryAlmacenesFacc.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesFacc.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_FACC', 'CODIGO_ALM_FACC');
end;

function TdmFacturasCompra.GenerarEfectos(const ACodEmpban: string = '';
                                          const AIbanEmp: string = ''): Integer;
var
  sp: TUniStoredProc;
  qStamp: TUniQuery;
  sSerie, sNumero: string;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    // El SP lee de BBDD: aseguramos la cabecera grabada antes de generar.
    if unqryTablaG.State in [dsEdit, dsInsert] then
    begin
      CalcularTotalesFacturaCompra;
      unqryTablaG.Post;
    end;
    sSerie  := unqryTablaG.FieldByName('SERIE_FACC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_FACC').AsString;
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection     := ConexionEscritura;
      sp.StoredProcName := 'PRC_EFEC_GENERAR_DESDE_FACTURA';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString,  'p_SERIE',     ptInput);
      sp.Params.CreateParam(ftString,  'p_NUMERO',    ptInput);
      sp.Params.CreateParam(ftString,  'p_USUARIO',   ptInput);
      sp.Params.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
      sp.ParamByName('p_SERIE').AsString   := sSerie;
      sp.ParamByName('p_NUMERO').AsString  := sNumero;
      sp.ParamByName('p_USUARIO').AsString := IdentidadSesion.Usuario;
      sp.ExecProc;
      Result := sp.ParamByName('p_RESULTADO').AsInteger;
    finally
      FreeAndNil(sp);
    end;
    // Estampar la cuenta de la empresa (cargo) elegida en los efectos.
    if (Result > 0) and (ACodEmpban <> '') then
    begin
      qStamp := TUniQuery.Create(nil);
      try
        qStamp.Connection := ConexionEscritura;
        qStamp.SQL.Text :=
          'UPDATE fza_efectos_compra ' +
          '   SET CODIGO_EMPBAN_EFEC = :banco, ' +
          '       IBAN_EMP_EFEC      = :iban ' +
          ' WHERE SERIE_FACC_EFEC  = :serie ' +
          '   AND NUMERO_FACC_EFEC = :numero';
        qStamp.ParamByName('banco').AsString  := ACodEmpban;
        qStamp.ParamByName('iban').AsString   := AIbanEmp;
        qStamp.ParamByName('serie').AsString  := sSerie;
        qStamp.ParamByName('numero').AsString := sNumero;
        qStamp.ExecSQL;
      finally
        FreeAndNil(qStamp);
      end;
    end;
    // Refrescar la rejilla de efectos.
    if Assigned(unqryEfectos) then
    begin
      unqryEfectos.Close;
      unqryEfectos.Open;
    end;
  end;
end;

function TdmFacturasCompra.GetBancoDefectoProveedor(
  const ACodigoPrv: string): string;
var
  q: TUniQuery;
begin
  Result := '';
  if ACodigoPrv <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      q.SQL.Text := 'SELECT CODIGO_EMPBAN_PRV ' +
                    '  FROM fza_proveedores ' +
                    ' WHERE CODIGO_PRV_PRV = :prv';
      q.ParamByName('prv').AsString := ACodigoPrv;
      q.Open;
      if not q.IsEmpty then
        Result := q.FieldByName('CODIGO_EMPBAN_PRV').AsString;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmFacturasCompra.GetFormaPagoDefectoProveedor(
  const ACodigoPrv: string): string;
var
  q: TUniQuery;
begin
  Result := '';
  if (ACodigoPrv <> '') and (ACodigoPrv <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      q.SQL.Text := 'SELECT CODIGO_FP_PRV ' +
                    '  FROM fza_proveedores ' +
                    ' WHERE CODIGO_PRV_PRV = :prv';
      q.ParamByName('prv').AsString := ACodigoPrv;
      q.Open;
      if not q.IsEmpty then
        Result := q.FieldByName('CODIGO_FP_PRV').AsString;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmFacturasCompra.CargarFormaPagoProveedor(const ACodigoPrv: string);
var
  sFp: string;
begin
  if unqryTablaG.State in [dsEdit, dsInsert] then
  begin
    if unqryTablaG.FindField('ESIVA_EXENTO_INTRACOMUNITARIO_FACC') <> nil then
      unqryTablaG.FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_FACC').AsString :=
        ObtenerIvaExentoIntracomunitarioProveedor(
          CrearLecturasImpuestos(ConexionEscritura), ACodigoPrv);
    if (ACodigoPrv <> '') and (ACodigoPrv <> '0') then
    begin
      sFp := GetFormaPagoDefectoProveedor(ACodigoPrv);
      if sFp <> '' then
        unqryTablaG.FieldByName('FORMA_PAGO_FACC').AsString := sFp;
    end;
    CalcularTotalesFacturaCompra;
  end;
end;

function TdmFacturasCompra.RegistrarPagoEfecto(ANumEfecto: Integer;
  AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  sp: TUniStoredProc;
  sSerie, sNumero: string;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    sSerie  := unqryTablaG.FieldByName('SERIE_FACC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_FACC').AsString;
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection     := ConexionEscritura;
      sp.StoredProcName := 'PRC_EFEC_CONCILIAR_PAGO';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString,  'p_SERIE',      ptInput);
      sp.Params.CreateParam(ftString,  'p_NUMERO',     ptInput);
      sp.Params.CreateParam(ftInteger, 'p_NUM_EFEC',   ptInput);
      sp.Params.CreateParam(ftDate,    'p_FECHA',      ptInput);
      sp.Params.CreateParam(ftFloat,   'p_IMPORTE',    ptInput);
      sp.Params.CreateParam(ftString,  'p_TIPO',       ptInput);
      sp.Params.CreateParam(ftString,  'p_REFERENCIA', ptInput);
      sp.Params.CreateParam(ftString,  'p_ENTIDAD',    ptInput);
      sp.Params.CreateParam(ftString,  'p_USUARIO',    ptInput);
      sp.Params.CreateParam(ftInteger, 'p_RESULTADO',  ptOutput);
      sp.ParamByName('p_SERIE').AsString      := sSerie;
      sp.ParamByName('p_NUMERO').AsString     := sNumero;
      sp.ParamByName('p_NUM_EFEC').AsInteger  := ANumEfecto;
      sp.ParamByName('p_FECHA').AsDateTime    := AFecha;
      sp.ParamByName('p_IMPORTE').AsFloat     := AImporte;
      sp.ParamByName('p_TIPO').AsString       := ATipo;
      sp.ParamByName('p_REFERENCIA').AsString := AReferencia;
      sp.ParamByName('p_ENTIDAD').AsString    := '';
      sp.ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
      sp.ExecProc;
      Result := sp.ParamByName('p_RESULTADO').AsInteger;
    finally
      FreeAndNil(sp);
    end;
    if Assigned(unqryEfectos) then
    begin
      unqryEfectos.Close;
      unqryEfectos.Open;
    end;
  end;
end;

procedure TdmFacturasCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
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
  FieldByName('ESREPRESENTACION_FISCAL_FACC').AsString := 'N';
  FieldByName('FECHA_REGISTRO_CONTABLE_FACC').AsDateTime := Date;
  FieldByName('MODALIDAD_FACC').AsString := 'ORDINARIA';
  FieldByName('PORCENTAJE_COMPENSACION_FACC').AsCurrency := 0;
  FieldByName('TOTAL_COMPENSACION_FACC').AsCurrency := 0;
  FieldByName('ESACUERDO_AUTOFAC_FACC').AsString := 'N';
  if FEsCompraDirecta then
    FieldByName('MODALIDAD_FACC').AsString := 'AUTOFAC';
  FieldByName('NUMERO_FACC').AsString := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='FP'
    sSerie := ObtenerSerieDefecto(
      ConexionEscritura,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdFactura, sdCompra).TipoContador);
    if FindField('SERIE_FACC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_FACC').AsString := sSerie
      else
        FieldByName('SERIE_FACC').AsString := 'C1';
    end;
    FieldByName('FECHA_FACC').AsDateTime := Date;
    if FindField('ESTADO_FACC') <> nil then
      FieldByName('ESTADO_FACC').AsString := 'ABIERTA';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_FACC').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_FACC').AsString := '0';
    FieldByName('CODIGO_PRV_FACC').AsString := '0';
    if FindField('ESPIVOTE_HORIZONTAL_FACC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_FACC') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_FACC').AsString := 'N';
    AplicarRecargoComprasEmpresa(
      CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
      'CODIGO_EMP_FACC', 'ESIVA_RECARGO_COMPRAS_FACC');
    AplicarPorcentajesIvaCompra(
      CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
      'FACC');
  if FEsCompraDirecta then
    ProponerSerieCompraDirecta(ConexionEscritura, unqryTablaG,
      IdentidadSesion.Usuario);
  RefrescarAlmacenes(FieldByName('CODIGO_EMP_FACC').AsString);
  FTransicionEstadoFacc := '';
end;

procedure TdmFacturasCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  fEstado: TField;
  oContador: TField;
  sEstadoNuevo, sEstadoAnterior: string;
  qChk: TUniQuery;
begin
  // El repositorio de numeracion es el unico escritor del contador.
  // Excluirlo del DML automatico impide que un Post de cabecera lo rebaje.
  oContador := DataSet.FindField('CONTADOR_LINEAS_FACC');
  if oContador <> nil then
  begin
    oContador.Required := False;
    oContador.ProviderFlags := [];
  end;
  inherited;
  ExigirCompraSinRegistroFiscal(ConexionEscritura,
    DataSet.FieldByName('SERIE_FACC').AsString,
    DataSet.FieldByName('NUMERO_FACC').AsString);
  // Antes de numerar: si se cancela no se consume el contador.
  ComprobarDocumentoExternoRepetido(DataSet);
  if (DataSet.FindField('ESPIVOTE_HORIZONTAL_FACC') <> nil) and
     (Trim(DataSet.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString) = '')
  then
    DataSet.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString := 'N';
  // FZ-ISSUE-249: datos del proveedor en la cabecera, como los de empresa.
  CopiarDatosProveedorDocumento(DataSet, 'FACC');
  if FEsCompraDirecta then
    ProponerSerieCompraDirecta(ConexionEscritura, DataSet,
      IdentidadSesion.Usuario);
  ValidarCompraDirecta(ConexionEscritura, DataSet,
    UbicacionSesion.Empresa, ParametrosApp);
  if (unqryTablaG.FieldByName('NUMERO_FACC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_FACC').AsString = '') then
    GetCodigoAutoFacturaCompra;
  AplicarPorcentajesIvaCompra(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
    'FACC');
  CalcularTotalesFacturaCompra;
  // Deteccion de transicion de ESTADO_FACC. Solo aplica en modo Edit
  // (en Insert la factura nace ABIERTA y los movimientos los genera
  // un Edit posterior). Comparamos OldValue vs
  // valor actual; UniDAC garantiza que OldValue refleja el snapshot
  // previo al Edit. Guardamos la transicion para aplicarla en
  // AfterPost cuando la cabecera ya este persistida.
  FTransicionEstadoFacc := '';
  if unqryTablaG.State = dsEdit then
  begin
    fEstado := unqryTablaG.FindField('ESTADO_FACC');
    if fEstado <> nil then
    begin
      sEstadoNuevo := UpperCase(Trim(fEstado.AsString));
      sEstadoAnterior := UpperCase(Trim(VarToStr(fEstado.OldValue)));
      if sEstadoNuevo <> sEstadoAnterior then
      begin
        if (sEstadoAnterior = 'ABIERTA') and
           (sEstadoNuevo = 'CERRADA') then
          FTransicionEstadoFacc := 'CERRAR'
        else if (sEstadoAnterior = 'CERRADA') and
                (sEstadoNuevo = 'ABIERTA') then
          FTransicionEstadoFacc := 'ABRIR';
        // El cierre exige al menos una linea con cantidad positiva.
        if FTransicionEstadoFacc = 'CERRAR' then
        begin
          qChk := TUniQuery.Create(nil);
          try
            qChk.Connection := ConexionEscritura;
            qChk.SQL.Text :=
              'SELECT COUNT(*) AS N FROM fza_facturas_compra_lineas ' +
              ' WHERE SERIE_FACC_FACCLIN  = :s ' +
              '   AND NUMERO_FACC_FACCLIN = :n ' +
              '   AND IFNULL(CANTIDAD_FACCLIN, 0) > 0';
            qChk.ParamByName('s').AsString :=
              unqryTablaG.FieldByName('SERIE_FACC').AsString;
            qChk.ParamByName('n').AsString :=
              unqryTablaG.FieldByName('NUMERO_FACC').AsString;
            qChk.Open;
            if qChk.FieldByName('N').AsInteger = 0 then
              raise Exception.Create(SErrorCerrarFacturaCompraSinLineas);
          finally
            FreeAndNil(qChk);
          end;
        end;
      end;
    end;
  end;
end;

const
  // FZ-ISSUE-168: número de documento del proveedor comparable.
  SQL_NORMALIZAR_DOCUMENTO_INI =
    'UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(';
  SQL_NORMALIZAR_DOCUMENTO_FIN =
    ', '' '', ''''), ''-'', ''''), ''/'', ''''), ''.'', ''''), ''_'', ''''))';

function TdmFacturasCompra.BuscarFacturaCompraRepetida(
  const AProveedor, ADocumento, ASerieExcluida, ANumeroExcluido: string;
  out AExistente: TFacturaCompraRepetida): Boolean;
var
  qChk: TUniQuery;
begin
  AExistente := Default(TFacturaCompraRepetida);
  Result := False;
  if (Trim(AProveedor) = '') or (Trim(ADocumento) = '') then
    Exit;
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := ConexionEscritura;
    // Sin distinguir mayúsculas, espacios ni separadores (- / . _):
    // «FV-2026 / 77» = «fv2026/77».
    // Documento: DOC_EXTERNO_FACC o, vacío, REF_PROVEEDOR_FACC. El filtro
    // por proveedor usa IDX_FACC_DOC_EXTERNO / IDX_FACC_PROVEEDOR_FECHA.
    qChk.SQL.Text :=
      'SELECT SERIE_FACC, NUMERO_FACC, FECHA_FACC ' +
      '  FROM fza_facturas_compra ' +
      ' WHERE CODIGO_PRV_FACC = :prv ' +
      '   AND ' + SQL_NORMALIZAR_DOCUMENTO_INI +
      '       COALESCE(NULLIF(TRIM(DOC_EXTERNO_FACC), ''''), ' +
      '                REF_PROVEEDOR_FACC)' + SQL_NORMALIZAR_DOCUMENTO_FIN +
      '     = ' + SQL_NORMALIZAR_DOCUMENTO_INI + ':doc' +
      SQL_NORMALIZAR_DOCUMENTO_FIN +
      '   AND NOT (SERIE_FACC = :serie AND NUMERO_FACC = :numero) ' +
      ' ORDER BY FECHA_FACC ' +
      ' LIMIT 1';
    qChk.ParamByName('prv').AsString := AProveedor;
    qChk.ParamByName('doc').AsString := ADocumento;
    qChk.ParamByName('serie').AsString := ASerieExcluida;
    qChk.ParamByName('numero').AsString := ANumeroExcluido;
    qChk.Open;
    Result := not qChk.IsEmpty;
    if Result then
    begin
      AExistente.Serie := qChk.FieldByName('SERIE_FACC').AsString;
      AExistente.Numero := qChk.FieldByName('NUMERO_FACC').AsString;
      AExistente.Fecha := qChk.FieldByName('FECHA_FACC').AsDateTime;
    end;
  finally
    FreeAndNil(qChk);
  end;
end;

// FZ-ISSUE-168: solo cuando la factura es nueva o cambian el proveedor o el
// documento, para no preguntar en cada grabación posterior. El documento del
// proveedor es DOC_EXTERNO_FACC o, si está vacío, REF_PROVEEDOR_FACC (lo que
// se teclea en «Ref. proveedor»); mismo criterio que UniDataDocsProveedorSql.
function DocumentoProveedorFactura(ADoc, ARef: TField): string;
begin
  Result := '';
  if ADoc <> nil then
    Result := Trim(ADoc.AsString);
  if (Result = '') and (ARef <> nil) then
    Result := Trim(ARef.AsString);
end;

function DocumentoProveedorAnterior(ADoc, ARef: TField): string;
begin
  Result := '';
  if ADoc <> nil then
    Result := Trim(VarToStr(ADoc.OldValue));
  if (Result = '') and (ARef <> nil) then
    Result := Trim(VarToStr(ARef.OldValue));
end;

procedure TdmFacturasCompra.ComprobarDocumentoExternoRepetido(
  DataSet: TDataSet);
var
  fPrv, fDoc, fRef: TField;
  sDocumento: string;
  oExistente: TFacturaCompraRepetida;
  eDecision: TDecisionFacturaCompraRepetida;
begin
  if not Assigned(OnFacturaRepetida) then
    Exit;
  fPrv := DataSet.FindField('CODIGO_PRV_FACC');
  fDoc := DataSet.FindField('DOC_EXTERNO_FACC');
  fRef := DataSet.FindField('REF_PROVEEDOR_FACC');
  sDocumento := DocumentoProveedorFactura(fDoc, fRef);
  if (fPrv = nil) or (sDocumento = '') then
    Exit;
  if (DataSet.State = dsEdit) and
     (VarToStr(fPrv.OldValue) = fPrv.AsString) and
     (DocumentoProveedorAnterior(fDoc, fRef) = sDocumento) then
    Exit;
  if not BuscarFacturaCompraRepetida(fPrv.AsString, sDocumento,
    DataSet.FieldByName('SERIE_FACC').AsString,
    DataSet.FieldByName('NUMERO_FACC').AsString, oExistente) then
    Exit;
  // Un Post posterior sin cambio de proveedor/documento ya se excluye
  // arriba. Un Grabar cancelado o fallido debe preguntar de nuevo.
  eDecision := OnFacturaRepetida(sDocumento, fPrv.AsString, oExistente);
  case eDecision of
    dfrAbrirExistente:
      begin
        FacturaRepetidaAAbrir := oExistente;
        Abort;
      end;
    dfrCancelar:
      Abort;
  end;
end;

// Tras persistir la cabecera, aplicamos la transicion de estado
// detectada en BeforePost: generar movimientos al cerrar o revertir
// los movimientos al reabrir. Cualquier excepcion se propaga al
// usuario (el Post original ya quedo aplicado, por lo que la factura
// guardara su nuevo estado aunque los movimientos fallen — el usuario
// debe revisar y reintentar o revertir manualmente).
procedure TdmFacturasCompra.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  // La factura de compra NO mueve stock (lo hizo el albaran). El cambio de
  // estado solo refleja el ciclo administrativo de la factura.
  FTransicionEstadoFacc := '';
end;

procedure TdmFacturasCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
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
  ExigirCompraSinRegistroFiscal(ConexionEscritura,
    DataSet.FieldByName('SERIE_FACC').AsString,
    DataSet.FieldByName('NUMERO_FACC').AsString);
  sSerie  := DataSet.FieldByName('SERIE_FACC').AsString;
  sNumero := DataSet.FieldByName('NUMERO_FACC').AsString;
  if (sSerie <> '') and (sNumero <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_efectos_compra E ' +
        ' WHERE E.SERIE_FACC_EFEC  = :s ' +
        '   AND E.NUMERO_FACC_EFEC = :n ' +
        '   AND (COALESCE(E.IMPORTE_PAGADO_EFEC, 0) <> 0 ' +
        '    OR COALESCE(E.ESCONCILIADO_EFEC, ''N'') = ''S'' ' +
        '    OR COALESCE(E.SERIE_REMC_EFEC, '''') <> '''' ' +
        '    OR COALESCE(E.NUMERO_REMC_EFEC, '''') <> '''' ' +
        '    OR COALESCE(E.ESTADO_EFEC, '''') IN ' +
        '       (''PAGADO'', ''REMESADO'', ''DEVUELTO'', ' +
        '        ''CONCILIADO''))';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
      if iBloqueos > 0 then
        raise Exception.Create(SErrorBorrarFacturaCompraEfectosPagados);
      if not SolicitarConfirmacion(
        Format(SPreguntaBorrarFacturaCompra,
          [sSerie, sNumero])) then
      begin
        Abort;
      end;
      IniciarBorradoTransaccional;
      try
        q.SQL.Text :=
          'UPDATE fza_albaranes_compra_lineas ' +
          '   SET ESFACTURADA_ALBCLIN = ''N'', ' +
          '       NUMERO_FAC_ALBCLIN  = NULL, ' +
          '       SERIE_FAC_ALBCLIN   = NULL, ' +
          '       LINEA_FAC_ALBCLIN   = NULL, ' +
          '       USUARIO_MODIF       = :u ' +
          ' WHERE SERIE_FAC_ALBCLIN   = :s ' +
          '   AND NUMERO_FAC_ALBCLIN  = :n';
        AsignarDocumento;
        q.ParamByName('u').AsString := IdentidadSesion.Usuario;
        q.ExecSQL;
        q.SQL.Text :=
          'UPDATE fza_albaranes_compra ' +
          '   SET ESTADO_ALBC     = ''CERRADO'', ' +
          '       NUMERO_FAC_ALBC = NULL, ' +
          '       SERIE_FAC_ALBC  = NULL, ' +
          '       USUARIO_MODIF   = :u ' +
          ' WHERE SERIE_FAC_ALBC  = :s ' +
          '   AND NUMERO_FAC_ALBC = :n';
        AsignarDocumento;
        q.ParamByName('u').AsString := IdentidadSesion.Usuario;
        q.ExecSQL;
        q.SQL.Text :=
          'DELETE FROM fza_facturas_compra_celdas ' +
          ' WHERE SERIE_FACC_FACCCEL  = :s ' +
          '   AND NUMERO_FACC_FACCCEL = :n';
        AsignarDocumento;
        q.ExecSQL;
        q.SQL.Text :=
          'DELETE FROM fza_facturas_compra_lineas ' +
          ' WHERE SERIE_FACC_FACCLIN  = :s ' +
          '   AND NUMERO_FACC_FACCLIN = :n';
        AsignarDocumento;
        q.ExecSQL;
        q.SQL.Text :=
          'DELETE FROM fza_efectos_compra ' +
          ' WHERE SERIE_FACC_EFEC  = :s ' +
          '   AND NUMERO_FACC_EFEC = :n';
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
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryFacturasCompraLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryFacturasCompraLineas.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('NUMERO_FACC_FACCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_FACC').AsString;
    FieldByName('SERIE_FACC_FACCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_FACC').AsString;
    // Sin numero hasta grabar: el BeforePost asigna el definitivo con
    // el contador de lineas. Un 0000 parecia un error (FZ-ISSUE-224).
    FieldByName('LINEA_FACCLIN').Clear;
    FieldByName('CANTIDAD_FACCLIN').AsFloat := 1;
    if FindField('ESFACTURADA_FACCLIN') <> nil then
      FieldByName('ESFACTURADA_FACCLIN').AsString := 'N';
    // Auditoria estandar: las 4 columnas del libro de estilo bbdd §3.7
    // son NOT NULL sin default; hay que rellenarlas en alta. En BeforePost
    // tambien sobrescribimos USUARIO_MODIF para que refleje la ultima edicion.
    FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
  FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasBeforeDelete(
  DataSet: TDataSet);
begin
  ExigirCompraSinRegistroFiscal(ConexionEscritura,
    DataSet.FieldByName('SERIE_FACC_FACCLIN').AsString,
    DataSet.FieldByName('NUMERO_FACC_FACCLIN').AsString);
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryFacturasCompraLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryFacturasCompraLineas.FindField(ANombre);
  end;
begin
  inherited;
  ExigirCompraSinRegistroFiscal(ConexionEscritura,
    DataSet.FieldByName('SERIE_FACC_FACCLIN').AsString,
    DataSet.FieldByName('NUMERO_FACC_FACCLIN').AsString);
  // Desempaquetado ATTR en curso: post descriptivo, sin logica fiscal.
  if not FDesempaquetandoAtributos then
  begin
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, el Post
  // fallaria con 'Field LINEA_FACCLIN must have a value'. Cancel diferido +
  // Abort la descarta sin molestar al usuario. Mismo patron que Sesiones.
  if (Trim(unqryFacturasCompraLineas.FieldByName(
             'CODIGO_ART_FACCLIN').AsString) = '') and
     (Trim(unqryFacturasCompraLineas.FieldByName(
             'CODIGO_UNIDAD_FACCLIN').AsString) = '') then
  begin
    TThread.RemoveQueuedEvents(CancelarLineaVaciaDiferida);
    TThread.ForceQueue(nil, CancelarLineaVaciaDiferida);
    Abort;
  end;
  AsignarNumeroLineaFacturaCompra(DataSet);
  // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
  NormalizarArticuloSkuEnDataSet(ConexionEscritura,
      unqryFacturasCompraLineas, 'CODIGO_ART_FACCLIN',
      'CODIGO_UNIDAD_FACCLIN');
  // FZ-ISSUE-520: un SKU dado de baja no recibe existencias.
  ExigirSkuActivoEnDataSet(ConexionEscritura, unqryFacturasCompraLineas,
    'CODIGO_ART_FACCLIN', 'CODIGO_UNIDAD_FACCLIN', SErrorSkuCompraNoActivo);
  // F-LOTEC-013: antes de los totales (una serie deja la línea
  // en 1).
  if Assigned(FLotesLineas) then
    FLotesLineas.AntesDePostLinea(unqryFacturasCompraLineas, DocumentoLotes);
    if (FindField('CANTIDAD_FACCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN') <> nil) and
       (FindField('TOTAL_FACCLIN') <> nil) then
      FieldByName('TOTAL_FACCLIN').AsFloat :=
        FieldByName('CANTIDAD_FACCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN').AsFloat;
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
    if (FindField('CODIGO_UNIDAD_FACCLIN') <> nil) and
       (FindField('CODIGO_ART_FACCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_FACCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_FACCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusFacc.Close;
        unqrySkusFacc.ParamByName('pSKU').AsString := sSku;
        unqrySkusFacc.Open;
        if not unqrySkusFacc.Eof then
          FieldByName('CODIGO_ART_FACCLIN').AsString :=
            unqrySkusFacc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusFacc.Close;
      end;
    end;
  PrepararLineaFiscalCompra(CrearLecturasImpuestos(ConexionEscritura),
    unqryTablaG,
    unqryFacturasCompraLineas, 'FACC', 'FACCLIN', 'TOTAL_FACCLIN');
  end;
end;

procedure TdmFacturasCompra.AsignarNumeroLineaFacturaCompra(
                                                       DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_FACCLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_FACCLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_FACC').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_FACC').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
          LIN_FACTURAS_COMPRA, sSerie,
          sNumero, sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraFacturaCompraSinGrabar);
      if DataSet.FindField('NUMERO_FACC_FACCLIN') <> nil then
        DataSet.FieldByName('NUMERO_FACC_FACCLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_FACC_FACCLIN') <> nil then
        DataSet.FieldByName('SERIE_FACC_FACCLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionEscritura),
        CONT_FACTURAS_COMPRA, LIN_FACTURAS_COMPRA, sSerie, sNumero);
      if iNuevaLinea = 0 then
      begin
        iNuevaLinea := StrToIntDef(
          unqryTablaG.FieldByName('CONTADOR_LINEAS_FACC').AsString, 0) + 10;
      end;
      AsignarCampoTextoSiEditable(
        unqryTablaG,
        'CONTADOR_LINEAS_FACC',
        Format('%.8d', [iNuevaLinea]));
      DataSet.FieldByName('LINEA_FACCLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

destructor TdmFacturasCompra.Destroy;
begin
  FreeAndNil(FLotesLineas);
  inherited;
end;

procedure TdmFacturasCompra.ConfigurarLotesLineas(
  const AConfig: TConfiguracionLotesLineas);
begin
  FreeAndNil(FLotesLineas);
  if AConfig.Activacion.AlgunModoActivo then
    FLotesLineas := TLotesLineasDocumento.Create(AConfig);
end;

function TdmFacturasCompra.DocumentoLotes: TDocumentoLineaLote;
begin
  Result.TipoDocumento := 'FP';
  Result.Serie := Trim(unqryTablaG.FieldByName('SERIE_FACC').AsString);
  Result.Numero :=
    Trim(unqryTablaG.FieldByName('NUMERO_FACC').AsString);
  Result.CodigoAlmacen :=
    Trim(unqryTablaG.FieldByName('CODIGO_ALM_FACC').AsString);
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  // Antes de copiar lotes pendientes: el cursor cambiará de línea.
  GenerarCodigoLoteLinea(TUniQuery(DataSet).Connection, DataSet,
    'FACCLIN', IdentidadSesion.Usuario, ParametrosApp);
  if Assigned(FLotesLineas) then
    FLotesLineas.DespuesDePostLinea;
  CalcularTotalesFacturaCompra;
end;

procedure TdmFacturasCompra.GetCodigoAutoFacturaCompra;
var
  iNumero: Int64;
  sNumero: string;
begin
  unstrdprcGetContadorFacc.Params.Clear;
  unstrdprcGetContadorFacc.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorFacc.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorFacc.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorFacc.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorFacc.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorFacc.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_FACC').AsString;
  unstrdprcGetContadorFacc.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdFactura, sdCompra).TipoContador;
  unstrdprcGetContadorFacc.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorFacc.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_FACC').AsString;
  EjecutarContadorDocumento(unstrdprcGetContadorFacc);
  sNumero := Trim(
    unstrdprcGetContadorFacc.ParamByName('pcont').AsString);
  if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
     (iNumero <= 0) then
    raise Exception.Create(Format(SErrorContadorFacturaCompra,
      [unqryTablaG.FieldByName('SERIE_FACC').AsString,
       unqryTablaG.FieldByName('CODIGO_EMP_FACC').AsString]));
  unqryTablaG.FieldByName('NUMERO_FACC').AsString := sNumero;
end;

procedure TdmFacturasCompra.AsignarCompraDirecta(AValor: Boolean);
begin
  FEsCompraDirecta := AValor;
  if AValor then
  begin
    unqryPrvDataFacc.Filter := 'ESFACTURACION_DIRECTA_PRV = ''S''';
    unqryPrvDataFacc.Filtered := True;
  end;
end;

function TdmFacturasCompra.DatosBusquedaProveedoresDirectos: TDataSet;
begin
  if not Assigned(FProveedoresDirectosBusqueda) then
  begin
    FProveedoresDirectosBusqueda := TUniQuery.Create(Self);
    FProveedoresDirectosBusqueda.Connection := ConexionEscritura;
    FProveedoresDirectosBusqueda.SQL.Text :=
      'SELECT CODIGO_PRV_PRV, NOMBRE_PRV, RAZON_SOCIAL_PRV, NIF_PRV, ' +
      'MOVIL_PRV, EMAIL_PRV FROM fza_proveedores ' +
      'WHERE ESFACTURACION_DIRECTA_PRV = ''S'' ' +
      'AND COALESCE(ESACTIVO_PRV, ''S'') = ''S'' ' +
      'ORDER BY RAZON_SOCIAL_PRV';
  end;
  FProveedoresDirectosBusqueda.Close;
  FProveedoresDirectosBusqueda.Open;
  Result := FProveedoresDirectosBusqueda;
end;

procedure TdmFacturasCompra.CargarSeriesCompra(AElementos: TStrings);
begin
  CargarSeriesModalidadCompra(ConexionEscritura,
    unqryTablaG.FieldByName('CODIGO_EMP_FACC').AsString,
    ModalidadCompra(unqryTablaG.FieldByName('MODALIDAD_FACC').AsString),
    AElementos, unqryTablaG.FieldByName('CODIGO_PRV_FACC').AsString);
end;

procedure TdmFacturasCompra.ActualizarModalidadCompra;
begin
  if unqryTablaG.State in dsEditModes then
  begin
    ProponerSerieCompraDirecta(ConexionEscritura, unqryTablaG,
      IdentidadSesion.Usuario);
    CalcularTotalesFacturaCompra;
  end;
end;

procedure TdmFacturasCompra.CalcularTotalesFacturaCompra;
begin
  // Los posts del desempaquetado ATTR no alteran importes: saltar el
  // recalculo por linea (cascada de consultas de IVA al navegar).
  if not FDesempaquetandoAtributos then
  begin
    CalcularTotalesDocumentoCompra(
      CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
      unqryFacturasCompraLineas, 'FACC', 'TOTAL_FACCLIN',
      'TIPO_IVA_ARTICULO_FACCLIN', 'PORCENTAJE_IVA_FACCLIN');
    AplicarCompensacionCompraDirecta(unqryTablaG);
  end;
end;

function TdmFacturasCompra.TotalPrendasFactura: Double;
begin
  Result := TotalPrendasLineasCompra(unqryFacturasCompraLineas,
    'TIPO_IVA_ARTICULO_FACCLIN', '', UnidadesMedida);
end;

procedure TdmFacturasCompra.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabFaccPrint.Close;
  unqryCabFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryCabFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryCabFaccPrint.Open;
  unqryLinFaccPrint.Close;
  unqryLinFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryLinFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryLinFaccPrint.Open;
  unqryGuiasFaccPrint.Close;
  unqryGuiasFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryGuiasFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryGuiasFaccPrint.Open;
end;

procedure TdmFacturasCompra.CargarAlmacenesDelFactura(
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
          'SELECT DISTINCT L.CODIGO_ALMACEN_FACCLIN AS COD, ' +
          '       COALESCE(A.NOMBRE_ALM_ALM, ' +
          'L.CODIGO_ALMACEN_FACCLIN) AS NOM ' +
          '  FROM fza_facturas_compra_lineas L ' +
          '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = ' +
          'L.CODIGO_ALMACEN_FACCLIN ' +
          ' WHERE L.SERIE_FACC_FACCLIN = :s ' +
          'AND L.NUMERO_FACC_FACCLIN = :n ' +
          '   AND COALESCE(L.CODIGO_ALMACEN_FACCLIN, '''') <> '''' ' +
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

procedure TdmFacturasCompra.CrearDataSetEtiquetasAlb(ADmArt: TObject;
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
    sSkus  := ObtenerSkusFacturaCsv(ASerie, ANumero);
    if sSkus <> '' then
    begin
      oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, AAlmacenesCsv,
        AFecha, sSkus);
    end;
  end;
end;

function TdmFacturasCompra.ObtenerSkusFacturaCsv(
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
      'SELECT DISTINCT CODIGO_UNIDAD_FACCLIN ' +
      '  FROM fza_facturas_compra_lineas ' +
      ' WHERE SERIE_FACC_FACCLIN = :s AND NUMERO_FACC_FACCLIN = :n ' +
      '   AND COALESCE(CODIGO_UNIDAD_FACCLIN, '''') <> ''''';
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_FACCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmFacturasCompra.PrepararPrintSku(const ASerie, ANumero: string);
begin
  unqryCabFaccPrint.Close;
  unqryCabFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryCabFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryCabFaccPrint.Open;
  unqryLinFaccSkuPrint.Close;
  unqryLinFaccSkuPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryLinFaccSkuPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryLinFaccSkuPrint.Open;
end;

// Contrato ColumnSKUcxGrid: desglosa el SKU (ART/COLOR/TALLA) en las
// columnas reales ATTR1..5_VALOR_FACCLIN + NUM_ATRIBUTOS_FACCLIN.
// Idempotente POR COMPARACION (mismo criterio que albaranes de compra):
// solo edita la linea si algun ATTR o el numero de atributos difiere.
procedure TdmFacturasCompra.DesempaquetarAtributosLineas;
begin
  if unqryFacturasCompraLineas.Active and
     (not unqryFacturasCompraLineas.IsEmpty) and
     (unqryFacturasCompraLineas.FindField('ATTR1_VALOR_FACCLIN') <> nil) and
     (unqryFacturasCompraLineas.FindField(
        'NUM_ATRIBUTOS_FACCLIN') <> nil) and
     (not unqryFacturasCompraLineas.ReadOnly) then
  begin
    // Evita recálculos fiscales y movimientos durante los Post descriptivos.
    FDesempaquetandoAtributos := True;
    try
      DesempaquetarAtributosLineasSku(unqryFacturasCompraLineas, 'FACCLIN');
    finally
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmFacturasCompra);
end.
