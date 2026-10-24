{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasAplicacion                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa las capacidades de aplicación independientes de facturas.     }
{******************************************************************************}
unit inLibFacturasAplicacion;

interface

uses
  inLibEmisionFiscalIntf,
  inLibFacturasAplicacionIntf,
  inLibFacturasServiciosIntf;

function CrearAplicacionConsolidacionFactura(
  const ACasoUso: ICasoUsoConsolidacionFactura;
  const AVista: IVistaFactura
): IAplicacionConsolidacionFactura;
function CrearAplicacionOperacionFiscalFactura(
  const AServicio: IServicioEmisionFiscal;
  const AVista: IVistaFactura
): IAplicacionOperacionFiscalFactura;
function CrearAplicacionCobrosFactura(
  const AServicio: IServicioEfectosFactura
): IAplicacionCobrosFactura;
function CrearPresentadorEstadoFactura(
  const AVista: IVistaFactura
): IPresentadorEstadoFactura;
function CrearGestorModoEntradaFactura(
  const AVista: IVistaFactura;
  AModoInicial: TModoEntradaFactura
): IGestorModoEntradaFactura;

implementation

uses
  System.SysUtils,
  inLibFacturasConsolidacionPresentacion,
  inLibFacturasOperacionFiscal;

type
  TAplicacionConsolidacionFactura = class(
    TInterfacedObject,
    IAplicacionConsolidacionFactura)
  private
    FCasoUso: ICasoUsoConsolidacionFactura;
    FVista: IVistaFactura;
  public
    constructor Create(
      const ACasoUso: ICasoUsoConsolidacionFactura;
      const AVista: IVistaFactura);
    procedure Ejecutar(
      const ASerie, ANumero, AUsuario: string);
  end;
  TAplicacionOperacionFiscalFactura = class(
    TInterfacedObject,
    IAplicacionOperacionFiscalFactura)
  private
    FServicio: IServicioEmisionFiscal;
    FVista: IVistaFactura;
  public
    constructor Create(
      const AServicio: IServicioEmisionFiscal;
      const AVista: IVistaFactura);
    procedure Ejecutar(
      const AContexto: TContextoOperacionFiscalFactura);
  end;
  TAplicacionCobrosFactura = class(
    TInterfacedObject,
    IAplicacionCobrosFactura)
  private
    FServicio: IServicioEfectosFactura;
  public
    constructor Create(
      const AServicio: IServicioEfectosFactura);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASolicitud: TSolicitudGeneracionCobrosFactura): Integer;
    function Registrar(
      const ASolicitud: TSolicitudRegistroCobroFactura): Integer;
    function CambiarEstado(
      const ASolicitud: TSolicitudEstadoCobroFactura): Boolean;
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
  end;
  TPresentadorEstadoFactura = class(
    TInterfacedObject,
    IPresentadorEstadoFactura)
  private
    FVista: IVistaFactura;
  public
    constructor Create(const AVista: IVistaFactura);
    procedure Presentar(
      const ASolicitud: TSolicitudEstadoFactura);
  end;
  TGestorModoEntradaFactura = class(
    TInterfacedObject,
    IGestorModoEntradaFactura)
  private
    FModo: TModoEntradaFactura;
    FVista: IVistaFactura;
  public
    constructor Create(
      const AVista: IVistaFactura;
      AModoInicial: TModoEntradaFactura);
    function ModoActual: TModoEntradaFactura;
    procedure Seleccionar(AModo: TModoEntradaFactura);
    procedure SeleccionarSiguiente;
    procedure Reaplicar;
  end;

constructor TAplicacionConsolidacionFactura.Create(
  const ACasoUso: ICasoUsoConsolidacionFactura;
  const AVista: IVistaFactura);
begin
  if not Assigned(ACasoUso) then
    raise EArgumentNilException.Create('ACasoUso');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FCasoUso := ACasoUso;
  FVista := AVista;
end;

procedure TAplicacionConsolidacionFactura.Ejecutar(
  const ASerie, ANumero, AUsuario: string);
var
  Preparacion: TPreparacionConsolidacionFactura;
  Resultado: TResultadoConsolidacionFactura;
  Validacion: TResultadoOperacionFactura;
begin
  Validacion := FCasoUso.Validar(ASerie, ANumero);
  Preparacion := PrepararConsolidacionFactura(
    Validacion,
    ASerie,
    ANumero);
  if not Preparacion.EsValida then
  begin
    FVista.MostrarError(Preparacion.MensajeError);
  end
  else if FVista.Confirmar(Preparacion.PreguntaConfirmacion) then
  begin
    try
      Resultado := FCasoUso.Consolidar(
        ASerie,
        ANumero,
        AUsuario);
      FVista.RefrescarFactura;
      FVista.RefrescarMovimientos;
      FVista.ArchivarFactura(ASerie, ANumero);
      if Resultado.MensajeRecibida = '' then
        FVista.MostrarInformacion(Resultado.MensajeFiscal)
      else
        FVista.MostrarInformacion(Trim(Resultado.MensajeFiscal +
          sLineBreak + sLineBreak + Resultado.MensajeRecibida));
    except
      on E: EConsolidacionFactura do
        FVista.MostrarError(E.Message);
    end;
  end;
end;

constructor TAplicacionOperacionFiscalFactura.Create(
  const AServicio: IServicioEmisionFiscal;
  const AVista: IVistaFactura);
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FServicio := AServicio;
  FVista := AVista;
end;

procedure TAplicacionOperacionFiscalFactura.Ejecutar(
  const AContexto: TContextoOperacionFiscalFactura);
var
  Preparacion: TPreparacionOperacionFiscalFactura;
  Resultado: TResultadoEmisionFiscal;
begin
  Preparacion := PrepararOperacionFiscalFactura(AContexto);
  if not Preparacion.EsValida then
  begin
    FVista.MostrarError(Preparacion.MensajeError);
  end
  else if FVista.Confirmar(Preparacion.PreguntaConfirmacion) then
  begin
    Resultado := FServicio.Emitir(
      CrearSolicitudOperacionFiscalFactura(AContexto));
    FVista.MostrarInformacion(Resultado.Mensaje);
    FVista.RefrescarFactura;
  end;
end;

constructor TAplicacionCobrosFactura.Create(
  const AServicio: IServicioEfectosFactura);
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  inherited Create;
  FServicio := AServicio;
end;

function TAplicacionCobrosFactura.BancoDefectoCliente(
  const ACodigoCliente: string): string;
begin
  Result := FServicio.BancoDefectoCliente(ACodigoCliente);
end;

function TAplicacionCobrosFactura.Generar(
  const ASolicitud: TSolicitudGeneracionCobrosFactura): Integer;
begin
  Result := FServicio.Generar(
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.Usuario,
    ASolicitud.CodigoBanco,
    ASolicitud.Iban);
end;

function TAplicacionCobrosFactura.Registrar(
  const ASolicitud: TSolicitudRegistroCobroFactura): Integer;
begin
  Result := FServicio.RegistrarCobro(
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.Usuario,
    ASolicitud.NumeroEfecto,
    ASolicitud.Fecha,
    ASolicitud.Importe,
    ASolicitud.Tipo,
    ASolicitud.Referencia);
end;

function TAplicacionCobrosFactura.CambiarEstado(
  const ASolicitud: TSolicitudEstadoCobroFactura): Boolean;
begin
  Result := FServicio.CambiarEstado(
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.Usuario,
    ASolicitud.NumeroEfecto,
    ASolicitud.Estado);
end;

procedure TAplicacionCobrosFactura.EstamparBancoRecibos(
  const ASerie, ANumero, ACodigoBanco, AIban: string);
begin
  FServicio.EstamparBancoRecibos(
    ASerie,
    ANumero,
    ACodigoBanco,
    AIban);
end;

constructor TPresentadorEstadoFactura.Create(
  const AVista: IVistaFactura);
begin
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FVista := AVista;
end;

procedure TPresentadorEstadoFactura.Presentar(
  const ASolicitud: TSolicitudEstadoFactura);
var
  EsBorradorPendiente: Boolean;
  Estado: TEstadoVisualFactura;
begin
  Estado := Default(TEstadoVisualFactura);
  EsBorradorPendiente :=
    ((ASolicitud.Fase = '') or
     SameText(ASolicitud.Fase, 'BORRADOR')) and
    (not ASolicitud.Consolidada);
  // En SUBSANACION la factura emitida se abre a corrección: se edita
  // (sin cambiar número, fecha ni emisor) y no se consolida ni imprime
  // hasta registrar o cancelar la subsanación.
  Estado.Subsanando := SameText(ASolicitud.Fase, 'SUBSANACION');
  Estado.Editable := EsBorradorPendiente or Estado.Subsanando;
  if ASolicitud.SinVerifactu and
     ((ASolicitud.Fase = '') or
      SameText(ASolicitud.Fase, 'BORRADOR') or
      SameText(ASolicitud.Fase, 'SIN_VERIFACTU')) then
  begin
    Estado.Editable := True;
  end;
  if ASolicitud.EstadoDatos = edfInsertando then
    Estado.Editable := True;
  Estado.ActualizarAcciones :=
    ASolicitud.EstadoDatos = edfConsultando;
  Estado.PuedeConsolidar :=
    EsBorradorPendiente and
    (ASolicitud.EstadoDatos <> edfSinDatos);
  if ASolicitud.SinVerifactu then
    Estado.PuedeImprimir := ASolicitud.EstadoDatos <> edfSinDatos
  else
    Estado.PuedeImprimir := not Estado.Editable;
  FVista.AplicarEstado(Estado);
end;

constructor TGestorModoEntradaFactura.Create(
  const AVista: IVistaFactura;
  AModoInicial: TModoEntradaFactura);
begin
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FVista := AVista;
  FModo := AModoInicial;
end;

function TGestorModoEntradaFactura.ModoActual: TModoEntradaFactura;
begin
  Result := FModo;
end;

procedure TGestorModoEntradaFactura.Seleccionar(
  AModo: TModoEntradaFactura);
begin
  if FModo <> AModo then
  begin
    FModo := AModo;
    FVista.AplicarModoEntrada(FModo);
  end;
end;

procedure TGestorModoEntradaFactura.SeleccionarSiguiente;
begin
  case FModo of
    mefAutomatico:
      Seleccionar(mefSku);
    mefSku:
      Seleccionar(mefTallas);
    mefTallas:
      Seleccionar(mefAutomatico);
  end;
end;

procedure TGestorModoEntradaFactura.Reaplicar;
begin
  FVista.AplicarModoEntrada(FModo);
end;

function CrearAplicacionConsolidacionFactura(
  const ACasoUso: ICasoUsoConsolidacionFactura;
  const AVista: IVistaFactura
): IAplicacionConsolidacionFactura;
begin
  Result := TAplicacionConsolidacionFactura.Create(
    ACasoUso,
    AVista);
end;

function CrearAplicacionOperacionFiscalFactura(
  const AServicio: IServicioEmisionFiscal;
  const AVista: IVistaFactura
): IAplicacionOperacionFiscalFactura;
begin
  Result := TAplicacionOperacionFiscalFactura.Create(
    AServicio,
    AVista);
end;

function CrearAplicacionCobrosFactura(
  const AServicio: IServicioEfectosFactura
): IAplicacionCobrosFactura;
begin
  Result := TAplicacionCobrosFactura.Create(AServicio);
end;

function CrearPresentadorEstadoFactura(
  const AVista: IVistaFactura
): IPresentadorEstadoFactura;
begin
  Result := TPresentadorEstadoFactura.Create(AVista);
end;

function CrearGestorModoEntradaFactura(
  const AVista: IVistaFactura;
  AModoInicial: TModoEntradaFactura
): IGestorModoEntradaFactura;
begin
  Result := TGestorModoEntradaFactura.Create(
    AVista,
    AModoInicial);
end;

end.
