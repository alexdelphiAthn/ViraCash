{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasIncidenciaFiscal                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decide entre subsanar el registro y emitir una rectificativa R4.          }
{******************************************************************************}
unit inLibFacturasIncidenciaFiscal;

interface

uses
  inLibParametrosIntf,
  inLibEmisionFiscalIntf,
  inLibFacturasIncidenciaFiscalIntf,
  inLibFacturasPersistenciaIntf,
  inLibVerifactuColaIntf,
  inLibVerifactuSubsanacionIntf;

const
  cEstadoVerifactuAceptadoErrores = 'VERIFACTU_ACEPT_ERR';
  // FASE_FAC que deja la cola cuando la AEAT no registra el alta
  // (rechazo por datos o reintentos agotados)
  cFaseFacturaRechazadaAeat = 'VERIFACTU_ERROR';

function PuedeResolverIncidenciaFiscal(
  const AEstadoRegistro, AEstadoSubsanacion: string;
  AEsVentaMayor: Boolean): Boolean;
// True si la factura de venta mayor está en VERIFACTU_ERROR: la vía es
// devolverla a BORRADOR, corregirla y relanzarla (FZ-ISSUE-135)
function EsFacturaRechazadaAeat(
  const AFaseFactura, ATipoFactura: string): Boolean;
// True si el rechazo señala el bloque Destinatario (p. ej. 1239)
function EsRechazoAeatDestinatario(const ADescripcion: string): Boolean;
// Código y descripción del rechazo para mostrarlos al usuario
function DescribirRechazoAeat(
  const ACodigoError, ADescripcionError: string): string;
function CrearServicioIncidenciaFiscalFactura(
  const ARepositorio: IRepositorioIncidenciaFiscalFactura;
  const ACola: IServicioVerifactuCola;
  const ASubsanacion: IServicioVerifactuSubsanacion;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const AUnidadTrabajo: IUnidadTrabajoFacturas
): IServicioIncidenciaFiscalFactura;

implementation

uses
  inLibFormatoDocumento, inLibFormatoDocumentoLecturasIntf,
  System.SysUtils,
  System.StrUtils,
  inLibMsgVerifactu;

type
  TServicioIncidenciaFiscalFactura = class(
    TInterfacedObject,
    IServicioIncidenciaFiscalFactura)
  private
    FRepositorio: IRepositorioIncidenciaFiscalFactura;
    FCola: IServicioVerifactuCola;
    FSubsanacion: IServicioVerifactuSubsanacion;
    FEmision: IServicioEmisionFiscal;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FUsuario: string;
    FUnidadTrabajo: IUnidadTrabajoFacturas;
    function Validar(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const ADatos: TDatosIncidenciaFiscal): string;
    function ResolverSubsanacion(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
    function ResolverRectificativa(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
  public
    constructor Create(
      const ARepositorio: IRepositorioIncidenciaFiscalFactura;
      const ACola: IServicioVerifactuCola;
      const ASubsanacion: IServicioVerifactuSubsanacion;
      const AEmision: IServicioEmisionFiscal;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario: string;
      const AUnidadTrabajo: IUnidadTrabajoFacturas);
    function CargarIncidencia(
      const ASerie, ANumero: string): TDatosIncidenciaFiscal;
    function CargarCliente(
      const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
    function Resolver(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
  end;

function EstadoSubsanacionActivo(const AEstado: string): Boolean;
begin
  Result := SameText(AEstado, 'PENDIENTE') or
    SameText(AEstado, 'PROCESANDO') or
    SameText(AEstado, 'ENVIADA');
end;

function PuedeResolverIncidenciaFiscal(
  const AEstadoRegistro, AEstadoSubsanacion: string;
  AEsVentaMayor: Boolean): Boolean;
begin
  Result := AEsVentaMayor and
    SameText(AEstadoRegistro, cEstadoVerifactuAceptadoErrores) and
    (not EstadoSubsanacionActivo(AEstadoSubsanacion));
end;

function EsFacturaRechazadaAeat(
  const AFaseFactura, ATipoFactura: string): Boolean;
begin
  Result := SameText(Trim(ATipoFactura), 'NORMAL') and
    SameText(Trim(AFaseFactura), cFaseFacturaRechazadaAeat);
end;

function EsRechazoAeatDestinatario(const ADescripcion: string): Boolean;
begin
  Result := ContainsText(ADescripcion, 'Destinatario');
end;

function DescribirRechazoAeat(
  const ACodigoError, ADescripcionError: string): string;
var
  sCodigo: string;
begin
  Result := Trim(ADescripcionError);
  sCodigo := Trim(ACodigoError);
  if Result = '' then
    Result := SInfoMotivoRechazoAeatDesconocido
  else if (sCodigo <> '') and (Pos(sCodigo, Result) = 0) then
    Result := '[' + sCodigo + '] ' + Result;
end;

function CrearServicioIncidenciaFiscalFactura(
  const ARepositorio: IRepositorioIncidenciaFiscalFactura;
  const ACola: IServicioVerifactuCola;
  const ASubsanacion: IServicioVerifactuSubsanacion;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const AUnidadTrabajo: IUnidadTrabajoFacturas
): IServicioIncidenciaFiscalFactura;
begin
  Result := TServicioIncidenciaFiscalFactura.Create(
    ARepositorio,
    ACola,
    ASubsanacion,
    AEmision,
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    AUnidadTrabajo);
end;

constructor TServicioIncidenciaFiscalFactura.Create(
  const ARepositorio: IRepositorioIncidenciaFiscalFactura;
  const ACola: IServicioVerifactuCola;
  const ASubsanacion: IServicioVerifactuSubsanacion;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const AUnidadTrabajo: IUnidadTrabajoFacturas);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(ACola) then
    raise EArgumentNilException.Create('ACola');
  if not Assigned(ASubsanacion) then
    raise EArgumentNilException.Create('ASubsanacion');
  if not Assigned(AEmision) then
    raise EArgumentNilException.Create('AEmision');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  inherited Create;
  FRepositorio := ARepositorio;
  FCola := ACola;
  FSubsanacion := ASubsanacion;
  FEmision := AEmision;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FUsuario := AUsuario;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TServicioIncidenciaFiscalFactura.CargarIncidencia(
  const ASerie, ANumero: string): TDatosIncidenciaFiscal;
begin
  Result := FRepositorio.CargarIncidencia(ASerie, ANumero);
end;

function TServicioIncidenciaFiscalFactura.CargarCliente(
  const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
begin
  Result := FRepositorio.CargarCliente(ACodigoCliente);
end;

function TServicioIncidenciaFiscalFactura.Validar(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
  const ADatos: TDatosIncidenciaFiscal): string;
begin
  Result := '';
  if (Trim(ASolicitud.Serie) = '') or
     (Trim(ASolicitud.Numero) = '') then
    Result := SErrorIncidenciaFacturaNoSeleccionada
  else if not SameText(ADatos.TipoFactura, 'NORMAL') then
    Result := SErrorIncidenciaSoloVentaMayor
  else if not SameText(
    ADatos.EstadoRegistro, cEstadoVerifactuAceptadoErrores) then
    Result := SErrorIncidenciaNoAceptadaConErrores
  else if EstadoSubsanacionActivo(ADatos.EstadoSubsanacion) then
    Result := SErrorIncidenciaSubsanacionActiva
  else if Trim(ASolicitud.Motivo) = '' then
    Result := SErrorIncidenciaMotivoObligatorio
  else if ASolicitud.TipoResolucion = trifRectificarFactura then
  begin
    if Trim(ASolicitud.CodigoClienteCorrecto) = '' then
      Result := SErrorIncidenciaClienteObligatorio
    else if Trim(ASolicitud.SerieRectificativa) = '' then
      Result := SErrorIncidenciaSerieRectificativaObligatoria
    else if ASolicitud.FechaRectificativa <= 0 then
      Result := SErrorIncidenciaFechaRectificativaObligatoria;
  end;
end;

function TServicioIncidenciaFiscalFactura.ResolverSubsanacion(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
  TResultadoResolucionIncidenciaFiscal;
begin
  Result := Default(TResultadoResolucionIncidenciaFiscal);
  FSubsanacion.Encolar(
    FParametrosApp,
    FParametrosCaja,
    FUsuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.Motivo);
  Result.EsCorrecto := True;
  Result.Mensaje := SInfoIncidenciaSubsanacionEncolada;
end;

// Duplicado, datos de la R4, vínculo y emisión en una sola transacción:
// si algo falla no queda un duplicado sin marcar como RECTIFICATIVA que
// ComprobarRectificativaNoCreada dejaría repetir (FZ-ISSUE-148).
function TServicioIncidenciaFiscalFactura.ResolverRectificativa(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
  TResultadoResolucionIncidenciaFiscal;
var
  sNumero: string;
  sFormatoDocumento: string;
begin
  Result := Default(TResultadoResolucionIncidenciaFiscal);
  sNumero := '';
  sFormatoDocumento := FormatoDocumentoFacturaDelProveedor(FRepositorio,
    ASolicitud.Serie, ASolicitud.Numero);
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      sNumero := FRepositorio.CrearRectificativaR4(
        ASolicitud,
        FUsuario);
      FCola.EncolarRectificativa(
        FParametrosApp,
        FParametrosCaja,
        FEmision,
        FUsuario,
        ASolicitud.Serie,
        ASolicitud.Numero,
        ASolicitud.SerieRectificativa,
        sNumero,
        'S',
        False);
    end);
  Result.NumeroRectificativa := sNumero;
  Result.SerieRectificativa := ASolicitud.SerieRectificativa;
  Result.EsCorrecto := True;
  Result.Mensaje := FormatearMensajeDocumentos(
    sFormatoDocumento,
    SInfoIncidenciaRectificativaCreada,
    [Result.SerieRectificativa, Result.NumeroRectificativa]);
end;

function TServicioIncidenciaFiscalFactura.Resolver(
  const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
  TResultadoResolucionIncidenciaFiscal;
var
  Datos: TDatosIncidenciaFiscal;
  sError: string;
begin
  Result := Default(TResultadoResolucionIncidenciaFiscal);
  Datos := FRepositorio.CargarIncidencia(
    ASolicitud.Serie,
    ASolicitud.Numero);
  sError := Validar(ASolicitud, Datos);
  if sError <> '' then
    Result.Mensaje := sError
  else if ASolicitud.TipoResolucion = trifSubsanarRegistro then
    Result := ResolverSubsanacion(ASolicitud)
  else
    Result := ResolverRectificativa(ASolicitud);
end;

end.
