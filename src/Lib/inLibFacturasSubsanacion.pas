{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasSubsanacion                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio de subsanación del registro fiscal de una factura de venta       }
{    mayor; las reglas puras están en inLibFacturasSubsanacionReglas. Iniciar  }
{    deja la factura en fase SUBSANACION (editable con identidad y estructura  }
{    de líneas fijas); Registrar la devuelve a su fase de registro y encola el }
{    alta con Subsanacion = S (o la firma en NO VERI*FACTU) con los datos      }
{    corregidos, en una sola transacción.                                      }
{******************************************************************************}
unit inLibFacturasSubsanacion;

interface

uses
  inLibFacturasPersistenciaIntf,
  inLibFacturasServiciosIntf,
  inLibFacturasSubsanacionIntf,
  inLibLogIntf,
  inLibParametrosIntf,
  inLibVerifactuColaIntf,
  inLibVerifactuSubsanacionIntf,
  inLibVerifactuTipos;

// ACola, AMovimientos y AConsolidacion regeneran los movimientos de
// stock al registrar: las cantidades corregidas tienen que verse en el
// almacén igual que al consolidar.
function CrearServicioSubsanacionFactura(
  const ARepositorio: IRepositorioSubsanacionFactura;
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ACorreccion: IServicioVerifactuCorreccionRegistro;
  const ACola: IServicioVerifactuCola;
  const AMovimientos: IServicioMovimientosFactura;
  const AConsolidacion: IRepositorioConsolidacionFactura;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog): IServicioSubsanacionFactura;

implementation

uses
  inLibFormatoDocumento,
  System.SysUtils, System.StrUtils, System.Generics.Collections,
  inLibFacturasSubsanacionComparacion,
  inLibFacturasSubsanacionReglas, inLibMsgFacturas,
  inLibPrestaShopColaSenal, inLibVerifactu;

type
  TServicioSubsanacionFactura = class(
    TInterfacedObject,
    IServicioSubsanacionFactura)
  private
    FRepositorio: IRepositorioSubsanacionFactura;
    FUnidadTrabajo: IUnidadTrabajoFacturas;
    FCorreccion: IServicioVerifactuCorreccionRegistro;
    FCola: IServicioVerifactuCola;
    FMovimientos: IServicioMovimientosFactura;
    FConsolidacion: IRepositorioConsolidacionFactura;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FUsuario: string;
    FRegistroLog: IRegistroLog;
    // Instante en que esta sesión abrió cada factura a subsanación.
    FInicios: TDictionary<string, TDateTime>;
    function Clave(const ASerie, ANumero: string): string;
    function Modo: TModoVerifactu;
    procedure RegistrarInformacion(const AMensaje: string);
    function RegenerarMovimientos(
      const ASerie, ANumero: string): Integer;
  public
    constructor Create(
      const ARepositorio: IRepositorioSubsanacionFactura;
      const AUnidadTrabajo: IUnidadTrabajoFacturas;
      const ACorreccion: IServicioVerifactuCorreccionRegistro;
      const ACola: IServicioVerifactuCola;
      const AMovimientos: IServicioMovimientosFactura;
      const AConsolidacion: IRepositorioConsolidacionFactura;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    function Cargar(
      const ASerie, ANumero: string): TDatosSubsanacionFactura;
    function ValidarInicio(
      const ASerie, ANumero: string): TResultadoOperacionFactura;
    procedure Iniciar(const ASerie, ANumero: string);
    function HayCambiosDesdeInicio(
      const ASerie, ANumero: string): Boolean;
    function DiferenciasConRegistro(
      const ASerie, ANumero: string): string;
    function Registrar(
      const ASerie, ANumero, AMotivo: string
    ): TResultadoSubsanacionFactura;
    procedure Cancelar(const ASerie, ANumero: string);
  end;

{ TServicioSubsanacionFactura }

constructor TServicioSubsanacionFactura.Create(
  const ARepositorio: IRepositorioSubsanacionFactura;
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ACorreccion: IServicioVerifactuCorreccionRegistro;
  const ACola: IServicioVerifactuCola;
  const AMovimientos: IServicioMovimientosFactura;
  const AConsolidacion: IRepositorioConsolidacionFactura;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  if not Assigned(ACorreccion) then
    raise EArgumentNilException.Create('ACorreccion');
  if not Assigned(ACola) then
    raise EArgumentNilException.Create('ACola');
  if not Assigned(AMovimientos) then
    raise EArgumentNilException.Create('AMovimientos');
  if not Assigned(AConsolidacion) then
    raise EArgumentNilException.Create('AConsolidacion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create;
  FRepositorio := ARepositorio;
  FUnidadTrabajo := AUnidadTrabajo;
  FCorreccion := ACorreccion;
  FCola := ACola;
  FMovimientos := AMovimientos;
  FConsolidacion := AConsolidacion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FUsuario := AUsuario;
  FRegistroLog := ARegistroLog;
  FInicios := TDictionary<string, TDateTime>.Create;
end;

destructor TServicioSubsanacionFactura.Destroy;
begin
  FreeAndNil(FInicios);
  inherited;
end;

function TServicioSubsanacionFactura.Clave(
  const ASerie, ANumero: string): string;
begin
  Result := UpperCase(Trim(ASerie)) + '\' + UpperCase(Trim(ANumero));
end;

function TServicioSubsanacionFactura.Modo: TModoVerifactu;
begin
  Result := ModoVerifactu(FParametrosApp);
end;

procedure TServicioSubsanacionFactura.RegistrarInformacion(
  const AMensaje: string);
begin
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarInformacion(AMensaje);
end;

function TServicioSubsanacionFactura.RegenerarMovimientos(
  const ASerie, ANumero: string): Integer;
var
  oDatos: TDatosFacturaConsolidacion;
  oSolicitud: TSolicitudMovimientosFactura;
begin
  Result := 0;
  // Las cantidades corregidas tienen que verse en el stock: se retiran
  // los movimientos emitidos y se generan de nuevo con las líneas
  // actuales, con la misma regla que la consolidación.
  oDatos := FConsolidacion.CargarDatosConsolidacion(ASerie, ANumero, False);
  if oDatos.Encontrada and
     FacturaDebeGenerarMovimientos(oDatos.TipoFactura, oDatos.MueveStock) then
  begin
    FCola.BorrarMovimientosFactura(ASerie, ANumero);
    oSolicitud := Default(TSolicitudMovimientosFactura);
    oSolicitud.Serie := ASerie;
    oSolicitud.Numero := ANumero;
    oSolicitud.Empresa := oDatos.Empresa;
    oSolicitud.Cliente := oDatos.Cliente;
    oSolicitud.Caja := oDatos.Caja;
    oSolicitud.NumeroOperacion := oDatos.NumeroOperacion;
    oSolicitud.Fecha := oDatos.Fecha;
    oSolicitud.Usuario := FUsuario;
    Result := FMovimientos.GenerarSalidas(oSolicitud);
  end;
end;

function TServicioSubsanacionFactura.Cargar(
  const ASerie, ANumero: string): TDatosSubsanacionFactura;
begin
  Result := FRepositorio.Cargar(ASerie, ANumero, False);
end;

function TServicioSubsanacionFactura.ValidarInicio(
  const ASerie, ANumero: string): TResultadoOperacionFactura;
begin
  Result := EvaluarInicioSubsanacionFactura(
    FRepositorio.Cargar(ASerie, ANumero, False),
    Modo);
end;

procedure TServicioSubsanacionFactura.Iniciar(
  const ASerie, ANumero: string);
var
  oDatos: TDatosSubsanacionFactura;
  oValidacion: TResultadoOperacionFactura;
  dInicio: TDateTime;
begin
  dInicio := 0;
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      oDatos := FRepositorio.Cargar(ASerie, ANumero, True);
      oValidacion := EvaluarInicioSubsanacionFactura(oDatos, Modo);
      if not oValidacion.Exito then
        raise ESubsanacionFactura.Create(oValidacion.Mensaje);
      dInicio := FRepositorio.CambiarFase(
        ASerie, ANumero, cFaseFacturaSubsanacion, FUsuario);
    end);
  FInicios.AddOrSetValue(Clave(ASerie, ANumero), dInicio);
  RegistrarInformacion(FormatearMensajeDocumentos(
    oDatos.FormatoDocumento,
    'Subsanación iniciada en la factura %s\%s (fase %s)',
    [ASerie, ANumero, cFaseFacturaSubsanacion]));
end;

function TServicioSubsanacionFactura.HayCambiosDesdeInicio(
  const ASerie, ANumero: string): Boolean;
var
  dInicio: TDateTime;
  oDatos: TDatosSubsanacionFactura;
begin
  Result := False;
  if FInicios.TryGetValue(Clave(ASerie, ANumero), dInicio) then
  begin
    // Cualquier grabación (cabecera, líneas o recálculo) estampa la
    // auditoría de la cabecera después del inicio.
    oDatos := FRepositorio.Cargar(ASerie, ANumero, False);
    Result := oDatos.Encontrada and
      (oDatos.InstanteModificacion - dInicio > 0.5 / SecsPerDay);
  end;
end;

function TServicioSubsanacionFactura.DiferenciasConRegistro(
  const ASerie, ANumero: string): string;
begin
  Result := inLibFacturasSubsanacionComparacion.DiferenciasConRegistro(
    FRepositorio.CargarComparacionRegistro(ASerie, ANumero));
end;

function TServicioSubsanacionFactura.Registrar(
  const ASerie, ANumero, AMotivo: string
): TResultadoSubsanacionFactura;
var
  oDatos: TDatosSubsanacionFactura;
  oValidacion: TResultadoOperacionFactura;
  oResultado: TResultadoSubsanacionFactura;
  sMotivo: string;
  iMovimientos: Integer;
begin
  sMotivo := Trim(AMotivo);
  oResultado := Default(TResultadoSubsanacionFactura);
  iMovimientos := 0;
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      oDatos := FRepositorio.Cargar(ASerie, ANumero, True);
      oValidacion := EvaluarRegistroSubsanacionFactura(oDatos, sMotivo);
      if not oValidacion.Exito then
        raise ESubsanacionFactura.Create(oValidacion.Mensaje);
      // La factura recupera su fase de registro antes de encolar: el
      // hilo Verifactu la confirma cuando la AEAT acepta y NO VERI*FACTU
      // la firma aquí mismo. Si algo falla, la transacción deshace todo
      // y la factura sigue en SUBSANACION.
      FRepositorio.CambiarFase(ASerie, ANumero,
        FaseTrasSubsanacionFactura(oDatos.EstadoRegistro), FUsuario);
      FCorreccion.EncolarCorreccionRegistro(
        FParametrosApp, FParametrosCaja, FUsuario, ASerie, ANumero,
        sMotivo);
      iMovimientos := RegenerarMovimientos(ASerie, ANumero);
    end);
  FInicios.Remove(Clave(ASerie, ANumero));
  if iMovimientos > 0 then
    SolicitarProcesadoPrestaShop;
  oResultado.Serie := ASerie;
  oResultado.Numero := ANumero;
  oResultado.EncoladaVerifactu := Modo in [mvVerifactu, mvSii];
  oResultado.RegistradaNoVerifactu := Modo = mvNoVerifactu;
  if oResultado.EncoladaVerifactu then
    oResultado.Mensaje := FormatearMensajeDocumentos(
      oDatos.FormatoDocumento,
      SInfoSubsanacionFacturaEncolada,
      [ASerie, ANumero])
  else
    oResultado.Mensaje := FormatearMensajeDocumentos(
      oDatos.FormatoDocumento,
      SInfoSubsanacionFacturaNoVerifactu,
      [ASerie, ANumero]);
  RegistrarInformacion(FormatearMensajeDocumentos(
    oDatos.FormatoDocumento,
    'Subsanación registrada en la factura %s\%s (%s). Motivo: %s',
    [ASerie, ANumero, ModoVerifactuTexto(FParametrosApp), sMotivo]));
  Result := oResultado;
end;

procedure TServicioSubsanacionFactura.Cancelar(
  const ASerie, ANumero: string);
var
  oDatos: TDatosSubsanacionFactura;
  sDiferencias: string;
begin
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      oDatos := FRepositorio.Cargar(ASerie, ANumero, True);
      if not oDatos.Encontrada then
        raise ESubsanacionFactura.Create(
          SErrorBorradorListaNoSeleccionado);
      if not SameText(Trim(oDatos.Fase), cFaseFacturaSubsanacion) then
        raise ESubsanacionFactura.Create(FormatearMensajeDocumentos(
          oDatos.FormatoDocumento,
          SErrorSubsanacionNoIniciada, [ASerie, ANumero]));
      // FZ-ISSUE-133: volver a la fase de registro con otros importes o
      // destinatario dejaría la factura incoherente con la AEAT.
      sDiferencias := DiferenciasConRegistro(ASerie, ANumero);
      if sDiferencias <> '' then
        raise ESubsanacionFactura.Create(FormatearMensajeDocumentos(
          oDatos.FormatoDocumento,
          SErrorCancelarSubsanacionConCambios,
          [ASerie, ANumero, sDiferencias]));
      FRepositorio.CambiarFase(ASerie, ANumero,
        FaseTrasSubsanacionFactura(oDatos.EstadoRegistro), FUsuario);
    end);
  FInicios.Remove(Clave(ASerie, ANumero));
  RegistrarInformacion(FormatearMensajeDocumentos(
    oDatos.FormatoDocumento,
    'Subsanación cancelada en la factura %s\%s sin registrar',
    [ASerie, ANumero]));
end;

function CrearServicioSubsanacionFactura(
  const ARepositorio: IRepositorioSubsanacionFactura;
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ACorreccion: IServicioVerifactuCorreccionRegistro;
  const ACola: IServicioVerifactuCola;
  const AMovimientos: IServicioMovimientosFactura;
  const AConsolidacion: IRepositorioConsolidacionFactura;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog): IServicioSubsanacionFactura;
begin
  Result := TServicioSubsanacionFactura.Create(
    ARepositorio,
    AUnidadTrabajo,
    ACorreccion,
    ACola,
    AMovimientos,
    AConsolidacion,
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    ARegistroLog);
end;

end.
