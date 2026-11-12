{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPedidosCompraRecepcionVcl                                }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presentacion completa de la recepcion de pedidos de compra: cantidades,  }
{    creacion de albaranes, avisos y estilo de recepciones vencidas.           }
{******************************************************************************}
unit inMtoPedidosCompraRecepcionVcl;

interface

uses
  System.Classes,
  Data.DB, Uni, inLibLogIntf,
  cxCurrencyEdit,
  cxGridCustomTableView,
  cxGridDBTableView,
  cxStyles,
  inLibGridPivoteCompra,
  inLibComprasPantallaIntf,
  inLibPedidosCompraIntf;

type
  TAccionRecepcionPedidoCompraVcl = procedure of object;

  TConfigRecepcionPedidoCompraVcl = record
    Conexion: TUniConnection;
    RegistroLog: IRegistroLog;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Albaranes: TDataSet;
    PropietarioPantallas: TComponent;
    Usuario: string;
    Consultas: IConsultasPedidoCompraPantalla;
    Recepcion: IRecepcionPedidoCompra;
    Vista: TcxGridDBTableView;
    ColumnaVertical: TcxGridDBColumn;
    Pivote: TGridPivoteCompra;
    TotalAAlbaranar: TcxCurrencyEdit;
    BestFit: TAccionRecepcionPedidoCompraVcl;
  end;

  IRecepcionPedidoCompraVcl = interface
    ['{0AA9359D-AC2A-45DD-A904-D387BF3DC3B1}']
    procedure ActualizarTotal(AUsarCampoCantidades: Boolean);
    procedure AplicarEstiloLista(
      Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord;
      AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure RecibirFilaEntera(AUsarCampoCantidades: Boolean);
    procedure RecibirTodo(AUsarCampoCantidades: Boolean);
    procedure LimitarVertical(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure LimitarCampo(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure CrearAlbaran(AUsarCampoCantidades: Boolean);
  end;

function CrearRecepcionPedidoCompraVcl(
  const AConfig: TConfigRecepcionPedidoCompraVcl):
  IRecepcionPedidoCompraVcl;

implementation

uses
  UniDataPedidosCompraPendientes, inLibTipoCantidad, inLibMensajesVcl,
  System.SysUtils,
  System.UITypes,
  System.Variants,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  inLibMsgCompras, UniDataNumeracionDocumentos,
  inLibPedidosCompraPresentacionCantidades,
  inLibPedidosCompraPresentacionRecepcion,
  inLibShowMto,
  inLibTrazabilidad, inLibLotesPersistenciaIntf, inLibLotesVisualIntf,
  inLibPedidosCompraRecepcionLotes, inLibArticuloLotesVcl,
  inLibMsgTrazabilidad, UniDataLotesRepositorio,
  UniDataPedidosCompraRecepcionLotes, inMtoModalSeleccionLote,
  inMtoModalDocsCreados,
  inMtoModalSelAlmacenPedido;

type
  IControladorRecepcionPedidoCompraVcl = interface
    ['{FF9D62EF-CDAF-4DBE-A19D-28EE7865FEC6}']
    procedure Ejecutar(AUsarCampoCantidades: Boolean);
  end;

  TConfigControladorRecepcionPedidoCompraVcl = record
    Conexion: TUniConnection;
    RegistroLog: IRegistroLog;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Albaranes: TDataSet;
    PropietarioPantallas: TComponent;
    Usuario: string;
    Consultas: IConsultasPedidoCompraPantalla;
    Recepcion: IRecepcionPedidoCompra;
    Cantidades: ISeleccionCantidadesRecepcionPedidoCompra;
  end;

  TVisualizacionRecepcionPedidoCompraVcl = class(
    TInterfacedObject, IVisualizacionRecepcionPedidoCompra)
  private
    FConexion: TUniConnection;
    FRegistroLog: IRegistroLog;
    FUsuario: string;
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FAlbaranes: TDataSet;
    FPropietarioPantallas: TComponent;
    procedure RefrescarDatos;
    procedure MostrarDocumentoCreado(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
      const AResultado: TResultadoRecepcionPedidoCompra);
  public
    constructor Create(
      const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
    function Solicitar(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
      Boolean;
    procedure MostrarAviso(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure PresentarRecepcion(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
      const AResultado: TResultadoRecepcionPedidoCompra);
  end;

  // FZ-ISSUE-434: pide el lote y la caducidad (o las series) de una celda
  // que se va a recibir, con los mismos diálogos del alta manual de lotes.
  TPeticionLotesRecepcionVcl = class(
    TInterfacedObject, IPeticionLotesRecepcionVisual)
  private
    FSelector: ISelectorLotesVisual;
    function PedirLote(var APeticion: TPeticionLoteRecepcion): Boolean;
    function PedirSeries(var APeticion: TPeticionLoteRecepcion): Boolean;
  public
    constructor Create(const ASelector: ISelectorLotesVisual);
    function Pedir(var APeticion: TPeticionLoteRecepcion): Boolean;
  end;

  TControladorRecepcionPedidoCompraVcl = class(
    TInterfacedObject, IControladorRecepcionPedidoCompraVcl)
  private
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FUsuario: string;
    FConsultas: IConsultasPedidoCompraPantalla;
    FFlujo: TFlujoPresentacionRecepcionPedidoCompra;
    function CrearEntrada(
      AUsarCampoCantidades: Boolean):
      TEntradaPresentacionRecepcionPedidoCompra;
  public
    constructor Create(
      const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
    destructor Destroy; override;
    procedure Ejecutar(AUsarCampoCantidades: Boolean);
  end;

  TRecepcionPedidoCompraVcl = class(
    TInterfacedObject, IRecepcionPedidoCompraVcl)
  private
    FCantidades: ISeleccionCantidadesRecepcionPedidoCompra;
    FControlador: IControladorRecepcionPedidoCompraVcl;
    FPivote: TGridPivoteCompra;
    FTotalAAlbaranar: TcxCurrencyEdit;
    FBestFit: TAccionRecepcionPedidoCompraVcl;
    FEstiloVencida: TcxStyle;
  public
    constructor Create(const AConfig: TConfigRecepcionPedidoCompraVcl);
    destructor Destroy; override;
    procedure ActualizarTotal(AUsarCampoCantidades: Boolean);
    procedure AplicarEstiloLista(
      Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord;
      AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure RecibirFilaEntera(AUsarCampoCantidades: Boolean);
    procedure RecibirTodo(AUsarCampoCantidades: Boolean);
    procedure LimitarVertical(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure LimitarCampo(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure CrearAlbaran(AUsarCampoCantidades: Boolean);
  end;

function CrearRecepcionPedidoCompraVcl(
  const AConfig: TConfigRecepcionPedidoCompraVcl):
  IRecepcionPedidoCompraVcl;
begin
  Result := TRecepcionPedidoCompraVcl.Create(AConfig);
end;

constructor TVisualizacionRecepcionPedidoCompraVcl.Create(
  const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
begin
  inherited Create;
  FConexion := AConfig.Conexion;
  FRegistroLog := AConfig.RegistroLog;
  FUsuario := AConfig.Usuario;
  FCabecera := AConfig.Cabecera;
  FLineas := AConfig.Lineas;
  FAlbaranes := AConfig.Albaranes;
  FPropietarioPantallas := AConfig.PropietarioPantallas;
end;

function TVisualizacionRecepcionPedidoCompraVcl.Solicitar(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra): Boolean;
var
  sFormaPago: string;
begin
  sFormaPago := '';
  if Assigned(FCabecera.FindField('FORMA_PAGO_PEDC')) then
    sFormaPago := FCabecera.FieldByName('FORMA_PAGO_PEDC').AsString;
  Result := TfrmModalSelAlmacenPedido.Solicitar(Application, AEntrada,
    sFormaPago, ASolicitud) and (Trim(ASolicitud.CodigoAlmacen) <> '');
  if Result and (not ASolicitud.Incorporar) then
    PrepararNumeracionDocumento(FConexion, dnAlbaranCompra,
      AEntrada.CodigoEmpresa, ASolicitud.SerieAlbaran, AEntrada.Usuario,
      ASolicitud.AlbaranNuevo.NumeroManual, FRegistroLog,
      function(AMensaje: string): Boolean
      begin
        Result := MessageDlg_fza(AMensaje, mtConfirmation,
          [mbYes, mbNo], 0) = mrYes;
      end);
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.MostrarAviso(
  const AMensaje: string);
begin
  MessageDlg_fza(AMensaje, mtWarning, [mbOk], 0);
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.MostrarError(
  const AMensaje: string);
begin
  MessageDlg_fza(
    Format(SErrorCrearAlbaranDesdePedidoCompra, [AMensaje]),
    mtError, [mbOk], 0);
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.RefrescarDatos;
begin
  FCabecera.Refresh;
  FLineas.Close;
  FLineas.Open;
  if FAlbaranes.Active then
    FAlbaranes.Close;
  FAlbaranes.Open;
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.MostrarDocumentoCreado(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
  const AResultado: TResultadoRecepcionPedidoCompra);
var
  Formulario: TfrmModalDocsCreados;
begin
  Formulario := TfrmModalDocsCreados.Create(Application);
  Formulario.OnClose := nil;
  try
    Formulario.lblTitulo.Caption := Format(
      'Albarán creado desde el pedido %s/%s',
      [AEntrada.SeriePedido, AEntrada.NumeroPedido]);
    Formulario.Agregar(
      'Albarán', AResultado.SerieAlbaran,
      AResultado.NumeroAlbaran, ASolicitud.CodigoAlmacen);
    Formulario.ShowModal;
    if Formulario.Confirmado then
      ShowMto(
        FPropietarioPantallas,
        'AlbaranesCompra',
        AResultado.SerieAlbaran + ',' + AResultado.NumeroAlbaran);
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.PresentarRecepcion(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
  const AResultado: TResultadoRecepcionPedidoCompra);
begin
  RefrescarDatos;
  // FZ-ISSUE-930: con cantidades marcadas para otro almacén se avisa y
  // no se ofrece cancelar lo pendiente, que las incluiría.
  if AResultado.CantidadMarcadaOtrosAlmacenes > 0 then
    MostrarAviso(Format(SAvisoPedidoCompraMarcadoOtrosAlmacenes,
      [FormatFloat('0.###', AResultado.CantidadMarcadaOtrosAlmacenes),
       AResultado.AlmacenMarcadoSiguiente]))
  else if SameText(FCabecera.FieldByName('ESTADO_PEDC').AsString,
       'PARCIAL') then
    if MessageDlg_fza('El pedido tiene cantidades pendientes de recibir. ' +
         '¿Desea cancelar lo pendiente y dar por terminada la recepción? ' +
         'Se conservarán las cantidades recibidas y sus albaranes.',
         mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes then
    begin
      CancelarRestoPedidoCompra(FConexion, AEntrada.SeriePedido,
        AEntrada.NumeroPedido, FUsuario);
      RefrescarDatos;
    end;
  MostrarDocumentoCreado(AEntrada, ASolicitud, AResultado);
end;

constructor TPeticionLotesRecepcionVcl.Create(
  const ASelector: ISelectorLotesVisual);
begin
  inherited Create;
  FSelector := ASelector;
end;

function TPeticionLotesRecepcionVcl.PedirLote(
  var APeticion: TPeticionLoteRecepcion): Boolean;
var
  aValores: TArray<string>;
  bExigeCaducidad: Boolean;
  dtFecha: TDate;
  sPreguntaCaducidad: string;
  sMascaraCantidad: string;
begin
  aValores := [APeticion.Lote, ''];
  if APeticion.FechaCaducidad <> SIN_FECHA then
    aValores[1] := DateToStr(APeticion.FechaCaducidad);
  bExigeCaducidad := APeticion.ExigeCaducidad;
  sPreguntaCaducidad := SPreguntaCaducidadAltaManual;
  if bExigeCaducidad then
    sPreguntaCaducidad := SPreguntaCaducidadObligatoriaAltaManual;
  sMascaraCantidad := '0.000';
  if EsTipoCantidadPredeterminado(APeticion.TipoCantidad) then
    sMascaraCantidad := '0.###';
  Result := InputQuery_fza(
    Format(STituloLoteRecepcionPedido, [APeticion.CodigoSku,
      CantidadConTipo(FormatFloat(sMascaraCantidad, APeticion.Cantidad),
        APeticion.TipoCantidad)]),
    [SPreguntaLoteRecepcionPedido, sPreguntaCaducidad], aValores,
    function(const AValores: array of string): Boolean
    var
      sError: string;
    begin
      sError := ValidarAltaManualLote(AValores[0], AValores[1],
        bExigeCaducidad, dtFecha);
      Result := sError = '';
      if not Result then
        ShowMessage_fza(sError);
    end);
  if Result then
  begin
    APeticion.Lote := Trim(aValores[0]);
    ValidarAltaManualLote(aValores[0], aValores[1], bExigeCaducidad,
      APeticion.FechaCaducidad);
  end;
end;

function TPeticionLotesRecepcionVcl.PedirSeries(
  var APeticion: TPeticionLoteRecepcion): Boolean;
var
  rParametros: TParametrosAltaSeries;
  rSeries: TResultadoAltaSeries;
begin
  rParametros := Default(TParametrosAltaSeries);
  rParametros.CodigoSku := APeticion.CodigoSku;
  rParametros.DescripcionArticulo := APeticion.Descripcion;
  if Frac(APeticion.Cantidad) = 0 then
    rParametros.Cantidad := Trunc(APeticion.Cantidad);
  rSeries := FSelector.CapturarSeries(rParametros);
  Result := rSeries.Aceptado;
  if Result then
    APeticion.Series := rSeries.Series;
end;

function TPeticionLotesRecepcionVcl.Pedir(
  var APeticion: TPeticionLoteRecepcion): Boolean;
begin
  if APeticion.Modo = mtSerie then
    Result := PedirSeries(APeticion)
  else
    Result := PedirLote(APeticion);
end;

function CrearCompletadoLotesRecepcionVcl(
  const AConfig: TConfigControladorRecepcionPedidoCompraVcl):
  ICompletadoLotesRecepcionPedidoCompra;
var
  oLectura: ILecturaTrazabilidadArticulo;
  oSelector: ISelectorLotesVisual;
  rActivacion: TActivacionTrazabilidad;
begin
  // Con los interruptores apagados no se crea nada: la recepción no cambia.
  Result := nil;
  rActivacion := ActivacionVigente;
  if rActivacion.AlgunModoActivo and Assigned(AConfig.Conexion) then
  begin
    oLectura := CrearLecturaTrazabilidadArticuloUniDAC(AConfig.Conexion);
    oSelector := CrearSelectorLotesVisual(AConfig.PropietarioPantallas,
      CrearRepositorioLotesUniDAC(AConfig.Conexion));
    Result := CrearCompletadoLotesRecepcionPedidoCompra(
      CrearLecturaLineasRecepcionPedidoCompraUniDAC(AConfig.Conexion),
      rActivacion, oLectura, TPeticionLotesRecepcionVcl.Create(oSelector));
  end;
end;

constructor TControladorRecepcionPedidoCompraVcl.Create(
  const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
var
  Visualizacion: IVisualizacionRecepcionPedidoCompra;
begin
  inherited Create;
  FCabecera := AConfig.Cabecera;
  FLineas := AConfig.Lineas;
  FUsuario := AConfig.Usuario;
  FConsultas := AConfig.Consultas;
  Visualizacion := TVisualizacionRecepcionPedidoCompraVcl.Create(AConfig);
  FFlujo := TFlujoPresentacionRecepcionPedidoCompra.Create(
    AConfig.Recepcion,
    AConfig.Cantidades,
    Visualizacion,
    CrearCompletadoLotesRecepcionVcl(AConfig));
end;

destructor TControladorRecepcionPedidoCompraVcl.Destroy;
begin
  FreeAndNil(FFlujo);
  FConsultas := nil;
  inherited;
end;

function TControladorRecepcionPedidoCompraVcl.CrearEntrada(
  AUsarCampoCantidades: Boolean):
  TEntradaPresentacionRecepcionPedidoCompra;
begin
  if FCabecera.State in dsEditModes then
    FCabecera.Post;
  if FLineas.State in dsEditModes then
    FLineas.Post;
  Result := Default(TEntradaPresentacionRecepcionPedidoCompra);
  Result.SeriePedido := FCabecera.FieldByName('SERIE_PEDC').AsString;
  Result.NumeroPedido := FCabecera.FieldByName('NUMERO_PEDC').AsString;
  Result.CodigoEmpresa :=
    FCabecera.FieldByName('CODIGO_EMP_PEDC').AsString;
  Result.ReferenciaProveedor :=
    FCabecera.FieldByName('REF_PROVEEDOR_PEDC').AsString;
  Result.IdPvTemporada :=
    FCabecera.FieldByName('ID_PV_TEMPORADA_PEDC').AsInteger;
  Result.Usuario := FUsuario;
  Result.AlmacenAlternativo :=
    FConsultas.AlmacenEfectivoPrimeraLinea(
      Result.SeriePedido,
      Result.NumeroPedido);
  Result.UsarCampoCantidades := AUsarCampoCantidades;
end;

procedure TControladorRecepcionPedidoCompraVcl.Ejecutar(
  AUsarCampoCantidades: Boolean);
var
  Entrada: TEntradaPresentacionRecepcionPedidoCompra;
begin
  if FCabecera.IsEmpty then
    ShowMessage_fza(SErrorPedidoCompraNoActivoCrearAlbaran)
  else
  begin
    Entrada := CrearEntrada(AUsarCampoCantidades);
    FFlujo.Ejecutar(Entrada);
  end;
end;

constructor TRecepcionPedidoCompraVcl.Create(
  const AConfig: TConfigRecepcionPedidoCompraVcl);
var
  ConfigCantidades: TConfigCantidadesRecepcionPedidoCompra;
  ConfigControlador: TConfigControladorRecepcionPedidoCompraVcl;
begin
  inherited Create;
  FPivote := AConfig.Pivote;
  FTotalAAlbaranar := AConfig.TotalAAlbaranar;
  FBestFit := AConfig.BestFit;
  FEstiloVencida := TcxStyle.Create(nil);
  FEstiloVencida.AssignedValues := [svTextColor];
  FEstiloVencida.TextColor := clRed;
  ConfigCantidades := Default(TConfigCantidadesRecepcionPedidoCompra);
  ConfigCantidades.Cabecera := AConfig.Cabecera;
  ConfigCantidades.Lineas := AConfig.Lineas;
  ConfigCantidades.Vista := AConfig.Vista;
  ConfigCantidades.ColumnaVertical := AConfig.ColumnaVertical;
  ConfigCantidades.Pivote := AConfig.Pivote;
  FCantidades := TCantidadesRecepcionPedidoCompra.Create(ConfigCantidades);
  ConfigControlador :=
    Default(TConfigControladorRecepcionPedidoCompraVcl);
  ConfigControlador.Conexion := AConfig.Conexion;
  ConfigControlador.RegistroLog := AConfig.RegistroLog;
  ConfigControlador.Cabecera := AConfig.Cabecera;
  ConfigControlador.Lineas := AConfig.Lineas;
  ConfigControlador.Albaranes := AConfig.Albaranes;
  ConfigControlador.PropietarioPantallas := AConfig.PropietarioPantallas;
  ConfigControlador.Usuario := AConfig.Usuario;
  ConfigControlador.Consultas := AConfig.Consultas;
  ConfigControlador.Recepcion := AConfig.Recepcion;
  ConfigControlador.Cantidades := FCantidades;
  FControlador := TControladorRecepcionPedidoCompraVcl.Create(
    ConfigControlador);
end;

destructor TRecepcionPedidoCompraVcl.Destroy;
begin
  FControlador := nil;
  FCantidades := nil;
  FreeAndNil(FEstiloVencida);
  inherited;
end;

procedure TRecepcionPedidoCompraVcl.ActualizarTotal(
  AUsarCampoCantidades: Boolean);
begin
  if Assigned(FTotalAAlbaranar) and Assigned(FCantidades) then
    FTotalAAlbaranar.EditValue :=
      FCantidades.Total(AUsarCampoCantidades);
end;

procedure TRecepcionPedidoCompraVcl.AplicarEstiloLista(
  Sender: TcxCustomGridTableView;
  ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem;
  var AStyle: TcxStyle);
var
  ColFecha: TcxGridDBColumn;
  ColPendiente: TcxGridDBColumn;
  ValorFecha: Variant;
  ValorPendiente: Variant;
  Fecha: TDateTime;
  Pendiente: Double;
begin
  if (ARecord <> nil) and (Sender is TcxGridDBTableView) then
  begin
    ColFecha := TcxGridDBTableView(Sender).GetColumnByFieldName(
      'FECHA_TOPE_RECEPCION_PEDC');
    ColPendiente := TcxGridDBTableView(Sender).GetColumnByFieldName(
      'CANTIDAD_PENDIENTE_RECEPCION_PEDC');
    if Assigned(ColFecha) and Assigned(ColPendiente) then
    begin
      ValorFecha := ARecord.Values[ColFecha.Index];
      ValorPendiente := ARecord.Values[ColPendiente.Index];
      if not (VarIsNull(ValorFecha) or VarIsEmpty(ValorFecha) or
              VarIsNull(ValorPendiente) or
              VarIsEmpty(ValorPendiente)) then
      begin
        Fecha := VarToDateTime(ValorFecha);
        if VarIsNumeric(ValorPendiente) then
          Pendiente := ValorPendiente
        else
          Pendiente := StrToFloatDef(VarToStr(ValorPendiente), 0);
        if (Pendiente > 0) and (Trunc(Fecha) < Date) then
          AStyle := FEstiloVencida;
      end;
    end;
  end;
end;

procedure TRecepcionPedidoCompraVcl.RecibirFilaEntera(
  AUsarCampoCantidades: Boolean);
var
  Celdas: Integer;
begin
  if Assigned(FCantidades) then
  begin
    if not AUsarCampoCantidades and Assigned(FPivote) and
       FPivote.Activo and FPivote.Expandido then
      Celdas := FPivote.RecibirFilaEntera
    else
      Celdas := FCantidades.RellenarFila(AUsarCampoCantidades);
    ActualizarTotal(AUsarCampoCantidades);
    if Celdas = 0 then
      MessageDlg_fza(SInfoTallasPendientesRecibirNoDisponibles,
        mtInformation, [mbOk], 0);
  end;
end;

procedure TRecepcionPedidoCompraVcl.RecibirTodo(
  AUsarCampoCantidades: Boolean);
var
  Rellenadas: Integer;
begin
  if Assigned(FCantidades) then
  begin
    Rellenadas := FCantidades.RellenarTodo(AUsarCampoCantidades);
    if Assigned(FPivote) and FPivote.Activo and Assigned(FBestFit) then
      FBestFit;
    ActualizarTotal(AUsarCampoCantidades);
    if Rellenadas = 0 then
      MessageDlg_fza(SInfoPedidoCompraSinPendientesRecibir,
        mtInformation, [mbOk], 0);
  end;
end;

procedure TRecepcionPedidoCompraVcl.LimitarVertical(
  Sender: TObject; AUsarCampoCantidades: Boolean);
begin
  if Assigned(FCantidades) then
    FCantidades.LimitarVertical(Sender);
  ActualizarTotal(AUsarCampoCantidades);
end;

procedure TRecepcionPedidoCompraVcl.LimitarCampo(
  Sender: TObject; AUsarCampoCantidades: Boolean);
begin
  if Assigned(FCantidades) then
    FCantidades.LimitarCampo(Sender);
  ActualizarTotal(AUsarCampoCantidades);
end;

procedure TRecepcionPedidoCompraVcl.CrearAlbaran(
  AUsarCampoCantidades: Boolean);
begin
  if Assigned(FControlador) then
    FControlador.Ejecutar(AUsarCampoCantidades);
  ActualizarTotal(AUsarCampoCantidades);
end;

end.
