{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaCierreVentaVcl                                       }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina el diálogo VCL de cobro y entrega la solicitud al caso de uso.   }
{******************************************************************************}
unit inMtoCajaCierreVentaVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Uni,
  inLibFacturas, inLibFacturasLecturasIntf,
  inLibLogIntf,
  inLibCajaTipos, inLibCajaVentaIntf,
  inLibCajaPantallaInyeccion, inLibCajaSubsanacionIntf,
  inMtoCajaFaseCobro, inLibPermisosIntf, inLibArqueoPersistencia;

type
  TConfirmarMotivoDevolucionCaja = function: Boolean of object;
  TLeerMotivoDevolucionCaja = reference to function: string;
  TActualizarRelojCierreCaja = procedure of object;
  TEnfocarAtributoCierreCaja = procedure(AOrden: Integer) of object;
  TLeerFechaCierreCaja = reference to function: TDateTime;
  TPresentarResultadoCierreCaja = procedure(
    const AResultado: TResultadoCierreVenta;
    AEnviarEmail: Boolean;
    const AEmailEnvio: string) of object;
  TContextoCierreVentaCajaVcl = record
    PresupuestoEmpresa: string;
    PresupuestoSerie: string;
    PresupuestoNumero: string;
    Propietario: TComponent;
    Conexion: TUniConnection;
    Permisos: IPermisosAplicacion;
    RepositorioFacturas: IRepositorioLecturasFactura;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    RepartidorDescuento: IRepartidorDescuento;
    CasoUso: ICasoUsoCierreVentaCaja;
    RegistroLog: IRegistroLog;
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    TipoRectificativa: TTipoRectificativaCaja;
    TratamientoMovimientos: TTratamientoMovimientosRectificativa;
    SerieRectificada: string;
    NumeroRectificado: string;
    LeerMotivoDevolucion: TLeerMotivoDevolucionCaja;
    SerieOrigenDevolucion: string;
    NumeroOrigenDevolucion: string;
    EmpresaOrigenDevolucion: string;
    AlmacenOrigenDevolucion: string;
    ConfirmarMotivoDevolucion: TConfirmarMotivoDevolucionCaja;
    EnfocarAtributoPendiente: TEnfocarAtributoCierreCaja;
    ActualizarReloj: TActualizarRelojCierreCaja;
    LeerFecha: TLeerFechaCierreCaja;
    PresentarResultado: TPresentarResultadoCierreCaja;
    ValidarLotes: TProc;
    ValidarStock: TProc;
    DependenciasFaseCobro: TDependenciasFaseCobro;
  end;
  TCoordinadorCierreVentaCajaVcl = class
  private
    class function PedirContactoReparacion(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro): Boolean; static;
    class function GrabarVenta(
      const AContexto: TContextoCierreVentaCajaVcl;
      const ASolicitud: TSolicitudCierreVenta;
      out AResultado: TResultadoCierreVenta): Boolean; static;
    class procedure ConfigurarFaseCobro(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro;
      ATotales: TFacturaTotales); static;
    class procedure AplicarDescuento(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro;
      ATotales: TFacturaTotales); static;
    class function PrepararFaseCobro(
      const AContexto: TContextoCierreVentaCajaVcl;
      out AFormulario: TfrmMtoCajaFaseCobro;
      out ATotales: TFacturaTotales): Boolean; static;
    class function ConstruirSolicitud(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro
    ): TSolicitudCierreVenta; static;
  public
    // True si el usuario confirmo el cobro (se haya grabado o no ticket);
    // False si lo cancelo o no habia nada que cobrar.
    class function Ejecutar(
      const AContexto: TContextoCierreVentaCajaVcl): Boolean; static;
    // Pantalla de Cobro en modo subsanación: devuelve el descuento global
    // y los cobros nuevos sin grabar nada. AImprimirTicket es False cuando
    // el usuario subsana con F11 (sin ticket). AHayLineasFijas (abonos a
    // cuenta de depósitos) impide el descuento global, como en la venta.
    class function EjecutarCobroSubsanacion(
      const AContexto: TContextoCierreVentaCajaVcl;
      const APagos: TPagosSubsanacionCaja;
      AHayLineasFijas: Boolean;
      out ADescuentoGlobal: Currency;
      out APagosNuevos: TPagosSubsanacionCaja;
      out AImprimirTicket: Boolean): Boolean; static;
  end;
  TOrigenDevolucionCajaVcl = record
    Serie: string;
    Numero: string;
    Empresa: string;
    Almacen: string;
  end;

function PedirMotivoDevolucionCajaVcl(
  AOwner: TComponent;
  ALineas: TDataSet;
  var AMotivo: string): Boolean;
function ConfirmarCambioArqueoVentaVcl(AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion;
  const ASerie, ANumero: string; ANuevoTotal: Currency;
  AModo: TModoCambioArqueoVenta;
  out AConfirmados: TArray<string>): Boolean;
function SeleccionarTicketDevolucionCajaVcl(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const AEmpresa, AAlmacen, ACaja: string;
  out ASeleccion: TOrigenDevolucionCajaVcl;
  const AEsApartado: TFunc<string, string, Boolean> = nil;
  const AAlCapturarVentaApp: TProc = nil): Boolean;
function SeleccionarVentaOrigenCajaVcl(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const ASku, AEmpresa: string;
  out ASeleccion: TOrigenDevolucionCajaVcl): Boolean;

implementation

uses
  UniDataModeloPreparacionVentaTpv,
  inLibTpvMvcIntf, inLibControladorVentaTpv,
  UniDataReparacionesVentaTpv, inLibMsgReparaciones,
  inMtoCajaPrendasReparacionVcl,
  inLibCorreoValidacion,
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMsgComun,
  System.UITypes, Vcl.Dialogs,
  inLibErroresBBDD, inLibMensajesVcl, inLibMsgCaja,
  inLibCajaVentaOperacion, inLibCajaDescuentos,
  inMtoModalMotivoDevolucion, inMtoModalDevolucionTicket,
  inMtoModalSeleccionVentaOrigen, UniDataArqueoPersistencia;

type
  // Adaptador de la sesión visual: posee el diálogo y los totales.
  // El controlador recibe operaciones mínimas, nunca el formulario.
  TSesionCierreVentaCajaVcl = class
  private
    FContexto: TContextoCierreVentaCajaVcl;
    FFormulario: TfrmMtoCajaFaseCobro;
    FTotales: TFacturaTotales;
    FSolicitud: TSolicitudCierreVenta;
    FResultado: TResultadoCierreVenta;
    procedure EnfocarAtributo(AOrden: Integer);
    function PrepararCobro: Boolean;
    procedure AplicarCobro;
    function ConfirmarArqueo: Boolean;
    function Grabar: TResultadoGrabacionTpv;
    procedure PresentarResultado;
  public
    constructor Create(const AContexto: TContextoCierreVentaCajaVcl);
    destructor Destroy; override;
    function Ejecutar: Boolean;
  end;

constructor TSesionCierreVentaCajaVcl.Create(
  const AContexto: TContextoCierreVentaCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

destructor TSesionCierreVentaCajaVcl.Destroy;
begin
  FreeAndNil(FFormulario);
  FreeAndNil(FTotales);
  inherited;
end;

procedure TSesionCierreVentaCajaVcl.EnfocarAtributo(AOrden: Integer);
begin
  if Assigned(FContexto.EnfocarAtributoPendiente) then
    FContexto.EnfocarAtributoPendiente(AOrden);
end;

function TSesionCierreVentaCajaVcl.PrepararCobro: Boolean;
begin
  Result := TCoordinadorCierreVentaCajaVcl.PrepararFaseCobro(
    FContexto, FFormulario, FTotales);
end;

procedure TSesionCierreVentaCajaVcl.AplicarCobro;
begin
  TCoordinadorCierreVentaCajaVcl.AplicarDescuento(
    FContexto, FFormulario, FTotales);
  FSolicitud := TCoordinadorCierreVentaCajaVcl.ConstruirSolicitud(
    FContexto, FFormulario);
end;

function TSesionCierreVentaCajaVcl.ConfirmarArqueo: Boolean;
var
  oModo: TModoCambioArqueoVenta;
begin
  Result := True;
  if FContexto.NumeroRectificado <> '' then
  begin
    oModo := mcavDiferencias;
    if FContexto.TipoRectificativa = trcSustitutiva then
      oModo := mcavSustitutiva;
    Result := ConfirmarCambioArqueoVentaVcl(
      FContexto.Conexion, FContexto.Permisos,
      FContexto.SerieRectificada, FContexto.NumeroRectificado,
      FContexto.Cabecera.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency,
      oModo, FSolicitud.Grabacion.ArqueosConfirmados);
  end;
end;

function TSesionCierreVentaCajaVcl.Grabar: TResultadoGrabacionTpv;
begin
  Result.IntentoCompletado := TCoordinadorCierreVentaCajaVcl.GrabarVenta(
    FContexto, FSolicitud, FResultado);
  Result.Grabada := FResultado.Grabada;
end;

procedure TSesionCierreVentaCajaVcl.PresentarResultado;
begin
  FContexto.PresentarResultado(FResultado,
    FFormulario.EnviarEmail, FFormulario.EmailEnvio);
end;

function TSesionCierreVentaCajaVcl.Ejecutar: Boolean;
var
  oModelo: IModeloPreparacionVentaTpv;
  oInteraccion: TInteraccionCierreVentaTpv;
begin
  oModelo := TModeloPreparacionVentaTpv.Create(FContexto.Lineas,
    FContexto.ValidarStock, FContexto.ValidarLotes);
  oInteraccion.EnfocarAtributo := EnfocarAtributo;
  oInteraccion.PrepararCobro := PrepararCobro;
  oInteraccion.AplicarCobro := AplicarCobro;
  oInteraccion.ConfirmarArqueo := ConfirmarArqueo;
  oInteraccion.Grabar := Grabar;
  oInteraccion.PresentarResultado := PresentarResultado;
  Result := TControladorVentaTpv.CerrarVenta(oModelo, oInteraccion);
end;

function ConfirmarCambioArqueoVentaVcl(AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion;
  const ASerie, ANumero: string; ANuevoTotal: Currency;
  AModo: TModoCambioArqueoVenta;
  out AConfirmados: TArray<string>): Boolean;
begin
  AConfirmados := ConsultarArqueosCambioVenta(AConexion,
    ASerie, ANumero, ANuevoTotal, AModo);
  Result := Length(AConfirmados) = 0;
  if not Result then
  begin
    if not EsRootParaCambiarArqueo(APermisos) then
      ShowMessage_fza(SArqueoVentaRequiereRoot)
    else
      Result := MessageDlg_fza(Format(SArqueoVentaConfirmar,
        [string.Join(', ', AConfirmados)]), mtWarning,
        [mbYes, mbNo], 0, mbNo) = mrYes;
  end;
  if not Result then
    AConfirmados := nil;
end;

function SeleccionarTicketDevolucionCajaVcl(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const AEmpresa, AAlmacen, ACaja: string;
  out ASeleccion: TOrigenDevolucionCajaVcl;
  const AEsApartado: TFunc<string, string, Boolean>;
  const AAlCapturarVentaApp: TProc): Boolean;
var
  SeleccionModal: TTicketDevolucionSeleccionado;
begin
  ASeleccion := Default(TOrigenDevolucionCajaVcl);
  Result := TfrmModalDevolucionTicket.Ejecutar(
    AOwner,
    ARepositorio,
    AEmpresa,
    AAlmacen,
    ACaja,
    SeleccionModal,
    AEsApartado,
    AAlCapturarVentaApp);
  if Result then
  begin
    ASeleccion.Serie := SeleccionModal.Serie;
    ASeleccion.Numero := SeleccionModal.Numero;
    ASeleccion.Empresa := SeleccionModal.Empresa;
    ASeleccion.Almacen := SeleccionModal.Almacen;
  end;
end;

function SeleccionarVentaOrigenCajaVcl(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const ASku, AEmpresa: string;
  out ASeleccion: TOrigenDevolucionCajaVcl): Boolean;
var
  SeleccionModal: TVentaOrigenSeleccionada;
begin
  ASeleccion := Default(TOrigenDevolucionCajaVcl);
  Result := TfrmModalSeleccionVentaOrigen.Ejecutar(
    AOwner,
    ARepositorio,
    ASku,
    AEmpresa,
    SeleccionModal);
  if Result then
  begin
    ASeleccion.Serie := SeleccionModal.Serie;
    ASeleccion.Numero := SeleccionModal.Numero;
    ASeleccion.Empresa := SeleccionModal.Empresa;
    ASeleccion.Almacen := SeleccionModal.Almacen;
  end;
end;

function PedirMotivoDevolucionCajaVcl(
  AOwner: TComponent;
  ALineas: TDataSet;
  var AMotivo: string): Boolean;
var
  Motivo: string;
begin
  Result := True;
  if HayLineasNegativasVenta(ALineas) and
     (Trim(AMotivo) = '') then
  begin
    if TfrmModalMotivoDevolucion.Ejecutar(AOwner, Motivo) then
      AMotivo := Motivo
    else
      Result := False;
  end;
end;

class procedure TCoordinadorCierreVentaCajaVcl.ConfigurarFaseCobro(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro;
  ATotales: TFacturaTotales);
var
  oEntrada: TEntradaFaseCobro;
begin
  oEntrada := Default(TEntradaFaseCobro);
  oEntrada.CodigoEmpresa := AContexto.CodigoEmpresa;
  oEntrada.CodigoAlmacen := AContexto.CodigoAlmacen;
  oEntrada.CodigoCaja := AContexto.CodigoCaja;
  oEntrada.Fecha := AContexto.LeerFecha();
  oEntrada.CodigoCliente :=
    AContexto.Cabecera.FieldByName('CODIGO_CLI_FAC').AsString;
  oEntrada.EmailCliente :=
    AContexto.Cabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString;
  oEntrada.NifCliente :=
    AContexto.Cabecera.FieldByName('NIF_CLIENTE_FAC').AsString;
  oEntrada.CodigoPaisCliente :=
    AContexto.Cabecera.FieldByName(
      'CODIGO_PAI_CLIENTE_FAC').AsString;
  oEntrada.NombrePaisCliente :=
    AContexto.Cabecera.FieldByName(
      'NOMBRE_PAI_CLIENTE_FAC').AsString;
  oEntrada.HayLineasDeposito :=
    HayLineasDepositoVenta(AContexto.Lineas);
  if AContexto.NumeroRectificado <> '' then
    oEntrada.RectificaA :=
      FormatearReferenciaFactura(AContexto.Conexion,
      AContexto.SerieRectificada, AContexto.NumeroRectificado);
  if Trim(AContexto.NumeroOrigenDevolucion) <> '' then
  begin
    oEntrada.EmpresaOrigen := AContexto.EmpresaOrigenDevolucion;
    oEntrada.SerieOrigen := AContexto.SerieOrigenDevolucion;
    oEntrada.NumeroOrigen := AContexto.NumeroOrigenDevolucion;
  end
  else if Trim(AContexto.NumeroRectificado) <> '' then
  begin
    oEntrada.EmpresaOrigen := AContexto.CodigoEmpresa;
    oEntrada.SerieOrigen := AContexto.SerieRectificada;
    oEntrada.NumeroOrigen := AContexto.NumeroRectificado;
  end;
  if Trim(oEntrada.EmpresaOrigen) = '' then
    oEntrada.EmpresaOrigen := AContexto.CodigoEmpresa;
  AFormulario.Configurar(oEntrada);
  AFormulario.CargarDatosDesdeFactura(ATotales);
end;

class procedure TCoordinadorCierreVentaCajaVcl.AplicarDescuento(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro;
  ATotales: TFacturaTotales);
begin
  if AFormulario.DatosCobro.ImporteDescuentoGlobal > 0 then
  begin
    AplicarRepartoDescuentoDataSet(
      AContexto.RepartidorDescuento,
      AContexto.Lineas,
      AFormulario.DatosCobro.ImporteDescuentoGlobal);
    ATotales.ProcesarFacturaCompleta;
  end;
end;

function ValidarContactoReparacion(const AValores: array of string): Boolean;
begin
  Result := (Trim(AValores[0]) <> '') and
    (Length(Trim(AValores[0])) <= 200) and (Trim(AValores[1]) <> '') and
    (Length(Trim(AValores[1])) <= 40);
  if not Result then
    ShowMessage_fza(SErrorContactoReparacion)
  else
  begin
    Result := (Trim(AValores[2]) = '') or
      ((Length(Trim(AValores[2])) <= 200) and
       EmailDocumentoValido(Trim(AValores[2])));
    if not Result then
      ShowMessage_fza(SErrorCorreoContactoReparacion);
  end;
end;

class function TCoordinadorCierreVentaCajaVcl.PedirContactoReparacion(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro): Boolean;
var
  oReparaciones: TReparacionesVentaTpv;
  Valores: array[0..2] of string;
begin
  Result := True;
  if AContexto.TipoRectificativa = trcNinguna then
  begin
    oReparaciones := TReparacionesVentaTpv.Create(AContexto.Conexion);
    try
      if oReparaciones.HayServicios(AContexto.Lineas) then
      begin
        Valores[0] := AContexto.Cabecera.FieldByName(
          'RAZON_SOCIAL_CLIENTE_FAC').AsString;
        Valores[1] := AContexto.Cabecera.FieldByName(
          'MOVIL_CLIENTE_FAC').AsString;
        Valores[2] := AContexto.Cabecera.FieldByName(
          'EMAIL_CLIENTE_FAC').AsString;
        // FZ-ISSUE-787: con el cliente tecleado en la caja el nombre
        // llegaba vacío; se propone el de su ficha.
        oReparaciones.CompletarContactoCliente(
          AContexto.Cabecera.FieldByName('CODIGO_CLI_FAC').AsString,
          Valores[0], Valores[1], Valores[2]);
        Result := InputQuery_fza(STituloContactoReparacion,
          [SNombreContactoReparacion, STelefonoContactoReparacion,
           SCorreoContactoReparacion], Valores,
          function(const AValores: array of string): Boolean
          begin
            Result := ValidarContactoReparacion(AValores);
          end);
        if Result then
          Result := ElegirPrendasReparacion(AContexto.Propietario,
            AContexto.Conexion,AContexto.Lineas,AContexto.CodigoEmpresa,
            AContexto.CodigoAlmacen,
            AContexto.Cabecera.FieldByName('CODIGO_CLI_FAC').AsString,
            AFormulario.DatosCobro.PrendasReparacion);
        if Result then
        begin
          AFormulario.DatosCobro.NombreReparacion := Trim(Valores[0]);
          AFormulario.DatosCobro.TelefonoReparacion := Trim(Valores[1]);
          AFormulario.DatosCobro.EmailReparacion := Trim(Valores[2]);
        end;
      end;
    finally
      FreeAndNil(oReparaciones);
    end;
  end;
end;

class function TCoordinadorCierreVentaCajaVcl.PrepararFaseCobro(
  const AContexto: TContextoCierreVentaCajaVcl;
  out AFormulario: TfrmMtoCajaFaseCobro;
  out ATotales: TFacturaTotales): Boolean;
begin
  AFormulario := nil;
  ATotales := nil;
  AContexto.ActualizarReloj;
  EscribirFechaCabeceraVenta(AContexto.Cabecera, AContexto.LeerFecha());
  Result := AContexto.ConfirmarMotivoDevolucion;
  if Result and HayLineasGratuitasCaja(AContexto.Lineas) then
  begin
    Result := MessageDlg_fza(SConfirmarLineasGratuitasCaja,
      mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
  end;
  if Result then
  begin
    ATotales := TFacturaTotales.Create(
      AContexto.Conexion,
      AContexto.RepositorioFacturas,
      AContexto.Cabecera,
      AContexto.Lineas,
      nil,
      AContexto.RegistroLog);
    ATotales.ProcesarFacturaCompleta;
    AFormulario := TfrmMtoCajaFaseCobro.Create(
      AContexto.Propietario,
      AContexto.DependenciasFaseCobro);
    ConfigurarFaseCobro(AContexto, AFormulario, ATotales);
    Result := PedirContactoReparacion(AContexto, AFormulario);
    if Result then
      Result := AFormulario.ShowModal = mrOk;
    if not Result then
      AFormulario.DeshacerTotalesFactura;
  end;
end;

class function TCoordinadorCierreVentaCajaVcl.ConstruirSolicitud(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro
): TSolicitudCierreVenta;
var
  dtFecha: TDateTime;
  oCobro: TResultadoFaseCobro;
  oDocumento: TDocumentoCierreVenta;
begin
  oCobro := AFormulario.ObtenerResultado;
  oDocumento := ResolverDocumentoCierreVenta(
    oCobro.TipoImpresion = tiFactura,
    oCobro.SerieDocumento,
    oCobro.SerieFactura,
    oCobro.FechaFactura,
    AContexto.NumeroRectificado <> '');
  AContexto.ActualizarReloj;
  dtFecha := AContexto.LeerFecha();
  EscribirFechaCabeceraVenta(AContexto.Cabecera, dtFecha);
  Result := Default(TSolicitudCierreVenta);
  Result.Grabacion.PresupuestoEmpresa := AContexto.PresupuestoEmpresa;
  Result.Grabacion.PresupuestoSerie := AContexto.PresupuestoSerie;
  Result.Grabacion.PresupuestoNumero := AContexto.PresupuestoNumero;
  Result.TipoImpresion := oCobro.TipoImpresion;
  Result.Grabacion.CodigoEmpresa := AContexto.CodigoEmpresa;
  Result.Grabacion.CodigoAlmacen := AContexto.CodigoAlmacen;
  Result.Grabacion.CodigoCaja := AContexto.CodigoCaja;
  Result.Grabacion.SerieDocumento := oDocumento.Serie;
  Result.Grabacion.TipoFactura := oDocumento.TipoFactura;
  Result.Grabacion.FechaFactura := oDocumento.FechaFactura;
  Result.Grabacion.FechaOperacion := dtFecha;
  Result.Grabacion.NumeroManual := oCobro.NumeroManual;
  Result.Grabacion.TipoRectificativa :=
    AContexto.TipoRectificativa;
  Result.Grabacion.SerieRectificada := AContexto.SerieRectificada;
  Result.Grabacion.NumeroRectificado := AContexto.NumeroRectificado;
  Result.Grabacion.TratamientoMovimientos :=
    AContexto.TratamientoMovimientos;
  Result.Grabacion.MotivoDevolucion :=
    AContexto.LeerMotivoDevolucion();
  Result.Grabacion.SerieOrigenDevolucion :=
    AContexto.SerieOrigenDevolucion;
  Result.Grabacion.NumeroOrigenDevolucion :=
    AContexto.NumeroOrigenDevolucion;
  Result.Grabacion.EmpresaOrigenDevolucion :=
    AContexto.EmpresaOrigenDevolucion;
  Result.Grabacion.AlmacenOrigenDevolucion :=
    AContexto.AlmacenOrigenDevolucion;
  Result.Grabacion.DatosCobro := oCobro.DatosCobro;
end;

class function TCoordinadorCierreVentaCajaVcl.EjecutarCobroSubsanacion(
  const AContexto: TContextoCierreVentaCajaVcl;
  const APagos: TPagosSubsanacionCaja;
  AHayLineasFijas: Boolean;
  out ADescuentoGlobal: Currency;
  out APagosNuevos: TPagosSubsanacionCaja;
  out AImprimirTicket: Boolean): Boolean;
var
  oFormulario: TfrmMtoCajaFaseCobro;
  oTotales: TFacturaTotales;
begin
  ADescuentoGlobal := 0;
  APagosNuevos := nil;
  AImprimirTicket := True;
  oFormulario := nil;
  oTotales := TFacturaTotales.Create(
    AContexto.Conexion,
    AContexto.RepositorioFacturas,
    AContexto.Cabecera,
    AContexto.Lineas,
    nil,
    AContexto.RegistroLog);
  try
    oTotales.ProcesarFacturaCompleta;
    oFormulario := TfrmMtoCajaFaseCobro.Create(
      AContexto.Propietario,
      AContexto.DependenciasFaseCobro);
    ConfigurarFaseCobro(AContexto, oFormulario, oTotales);
    oFormulario.ConfigurarSubsanacion(APagos, AHayLineasFijas);
    Result := oFormulario.ShowModal = mrOk;
    if Result then
    begin
      ADescuentoGlobal := oFormulario.DatosCobro.ImporteDescuentoGlobal;
      APagosNuevos := oFormulario.PagosSubsanacion;
      AImprimirTicket := oFormulario.TipoImpresion <> tiSinTicket;
    end;
  finally
    FreeAndNil(oFormulario);
    FreeAndNil(oTotales);
  end;
end;

class function TCoordinadorCierreVentaCajaVcl.GrabarVenta(
  const AContexto: TContextoCierreVentaCajaVcl;
  const ASolicitud: TSolicitudCierreVenta;
  out AResultado: TResultadoCierreVenta): Boolean;
var
  bRepetir: Boolean;
  oResultado: TResultadoCierreVenta;
begin
  Result := False;
  oResultado := Default(TResultadoCierreVenta);
  repeat
    bRepetir := False;
    try
      Result := EjecutarConReintentoBloqueoBBDD(
        procedure
        begin
          if Assigned(AContexto.ValidarLotes) then
            AContexto.ValidarLotes();
          oResultado := AContexto.CasoUso.Ejecutar(ASolicitud);
        end,
        function: Boolean
        begin
          Result := MessageDlg_fza(Format(
            SAvisoSerieOcupada,
            [ASolicitud.Grabacion.SerieDocumento]),
            mtWarning, [mbRetry, mbCancel], 0, mbRetry) = mrRetry;
        end);
    except
      on E: EGrabacionVentaCaja do
      begin
        AContexto.RegistroLog.RegistrarError(E.Message);
        if E.PermiteReintentar then
          bRepetir := MessageDlg_fza(E.Message,
            mtWarning, [mbRetry, mbCancel], 0, mbCancel) = mrRetry
        else
          MessageDlg_fza(E.Message, mtWarning, [mbOK], 0);
      end;
    end;
  until not bRepetir;
  AResultado := oResultado;
end;

class function TCoordinadorCierreVentaCajaVcl.Ejecutar(
  const AContexto: TContextoCierreVentaCajaVcl): Boolean;
var
  oSesion: TSesionCierreVentaCajaVcl;
begin
  oSesion := TSesionCierreVentaCajaVcl.Create(AContexto);
  try
    Result := oSesion.Ejecutar;
  finally
    FreeAndNil(oSesion);
  end;
end;

end.
