{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasRectificativa                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas y servicio para rectificar o duplicar una factura de venta         }
{    mayor: por diferencias (abono, I) o por sustitución (S), con tipo         }
{    VERI*FACTU R1..R5, motivo y tratamiento de los movimientos de stock.      }
{    El vínculo fiscal con la original lo hace la cola Verifactu.              }
{******************************************************************************}
unit inLibFacturasRectificativa;

interface

uses
  inLibEmisionFiscalIntf,
  inLibFacturasPersistenciaIntf,
  inLibFacturasRectificativaIntf,
  inLibFacturasServiciosIntf,
  inLibParametrosIntf,
  inLibVerifactuColaIntf;

type
  TTipoFacturaVerifactuRectificativa = record
    Codigo: string;
    Nombre: string;
  end;
  TTiposFacturaVerifactuRectificativa =
    TArray<TTipoFacturaVerifactuRectificativa>;

function OrigenRectificativaEsSimplificado(
  const ATipoFactura: string): Boolean;
// R1..R4 rectifican facturas completas; R5, simplificadas.
function TiposFacturaVerifactuRectificativa(
  AOriginalSimplificada: Boolean): TTiposFacturaVerifactuRectificativa;
function TipoFacturaVerifactuRectificativaDefecto(
  AOriginalSimplificada: Boolean): string;
function TipoFacturaVerifactuRectificativaValido(
  const ATipo: string;
  AOriginalSimplificada: Boolean): Boolean;
function OperacionRectificativaEsFiscal(
  AOperacion: TOperacionRectificativaFactura): Boolean;
function CodigoTipoRectificativaFactura(
  AOperacion: TOperacionRectificativaFactura): string;
function FaseAdmiteRectificativa(
  const AFase: string;
  AConsolidada: Boolean): Boolean;
function EvaluarOrigenRectificativa(
  const ADatos: TDatosOrigenRectificativa): TResultadoOperacionFactura;
function EvaluarSolicitudRectificativa(
  const ASolicitud: TSolicitudRectificativaFactura;
  const ADatos: TDatosOrigenRectificativa): TResultadoOperacionFactura;
function CrearServicioRectificativaFactura(
  const ARepositorio: IRepositorioRectificativaFactura;
  const ACola: IServicioVerifactuCola;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const AUnidadTrabajo: IUnidadTrabajoFacturas
): IServicioRectificativaFactura;

implementation

uses
  inLibFormatoDocumento, inLibFormatoDocumentoLecturasIntf,
  System.SysUtils, System.StrUtils,
  inLibMsgFacturas, inLibMsgOpcionesDocumento, inLibVerifactu;

type
  TServicioRectificativaFactura = class(
    TInterfacedObject,
    IServicioRectificativaFactura)
  private
    FRepositorio: IRepositorioRectificativaFactura;
    FCola: IServicioVerifactuCola;
    FEmision: IServicioEmisionFiscal;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FUsuario: string;
    FUnidadTrabajo: IUnidadTrabajoFacturas;
    function CrearVinculo(
      const ASolicitud: TSolicitudRectificativaFactura;
      const ANumero: string): TSolicitudVinculoRectificativa;
    procedure EmitirDuplicado(
      const ASolicitud: TSolicitudRectificativaFactura;
      const ANumero: string);
    function MensajeResultado(
      const ASolicitud: TSolicitudRectificativaFactura;
      const ANumero, AFormatoDocumento: string): string;
  public
    constructor Create(
      const ARepositorio: IRepositorioRectificativaFactura;
      const ACola: IServicioVerifactuCola;
      const AEmision: IServicioEmisionFiscal;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario: string;
      const AUnidadTrabajo: IUnidadTrabajoFacturas);
    function CargarOrigen(
      const ASerie, ANumero: string): TDatosOrigenRectificativa;
    function Validar(
      const ASolicitud: TSolicitudRectificativaFactura
    ): TResultadoOperacionFactura;
    function Crear(
      const ASolicitud: TSolicitudRectificativaFactura
    ): TResultadoRectificativaFactura;
    procedure CompletarEmision(
      const ASerie, ANumero, AUsuario: string);
  end;

function NuevoTipoFacturaVerifactu(
  const ACodigo, ANombre: string): TTipoFacturaVerifactuRectificativa;
begin
  Result.Codigo := ACodigo;
  Result.Nombre := ANombre;
end;

function OrigenRectificativaEsSimplificado(
  const ATipoFactura: string): Boolean;
begin
  Result := SameText(Trim(ATipoFactura), 'SIMPLIFICADA');
end;

function TiposFacturaVerifactuRectificativa(
  AOriginalSimplificada: Boolean): TTiposFacturaVerifactuRectificativa;
begin
  if AOriginalSimplificada then
    Result := [NuevoTipoFacturaVerifactu('R5', SNombreTipoVerifactuR5)]
  else
    Result := [
      NuevoTipoFacturaVerifactu('R1', SNombreTipoVerifactuR1),
      NuevoTipoFacturaVerifactu('R2', SNombreTipoVerifactuR2),
      NuevoTipoFacturaVerifactu('R3', SNombreTipoVerifactuR3),
      NuevoTipoFacturaVerifactu('R4', SNombreTipoVerifactuR4)];
end;

function TipoFacturaVerifactuRectificativaDefecto(
  AOriginalSimplificada: Boolean): string;
begin
  if AOriginalSimplificada then
    Result := 'R5'
  else
    Result := 'R1';
end;

function TipoFacturaVerifactuRectificativaValido(
  const ATipo: string;
  AOriginalSimplificada: Boolean): Boolean;
var
  oTipo: TTipoFacturaVerifactuRectificativa;
begin
  Result := False;
  for oTipo in TiposFacturaVerifactuRectificativa(AOriginalSimplificada) do
    Result := Result or SameText(oTipo.Codigo, Trim(ATipo));
end;

function OperacionRectificativaEsFiscal(
  AOperacion: TOperacionRectificativaFactura): Boolean;
begin
  Result := AOperacion in [orfDiferencias, orfSustitucion];
end;

function CodigoTipoRectificativaFactura(
  AOperacion: TOperacionRectificativaFactura): string;
begin
  case AOperacion of
    orfDiferencias:
      Result := 'I';
    orfSustitucion:
      Result := 'S';
  else
    Result := '';
  end;
end;

function FaseAdmiteRectificativa(
  const AFase: string;
  AConsolidada: Boolean): Boolean;
var
  sFase: string;
begin
  sFase := Trim(AFase);
  // Sólo se rectifica una factura emitida. La pendiente de la cola se
  // admite porque el hilo la envía antes que a su rectificativa, y una
  // ya rectificada por diferencias puede recibir otro abono parcial.
  Result := MatchText(sFase,
    [cFaseFacturaVerifactuOk, cFaseFacturaVerifactuPendiente,
     cFaseFacturaNoVerifactuOk, cFaseFacturaSinVerifactu,
     cFaseFacturaRectificada]) or
    ((sFase = '') and AConsolidada);
end;

function EvaluarOrigenRectificativa(
  const ADatos: TDatosOrigenRectificativa): TResultadoOperacionFactura;
begin
  if not ADatos.Encontrada then
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado)
  else if SameText(Trim(ADatos.TipoFactura), 'RECTIFICATIVA') then
    Result := TResultadoOperacionFactura.Error(
      SErrorRectificarRectificativa)
  else if not FaseAdmiteRectificativa(ADatos.Fase, ADatos.Consolidada) then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorRectificarFaseNoEmitida,
      [ADatos.Serie, ADatos.Numero, ADatos.Fase]))
  else if ADatos.TieneRectificativaPendiente then
    Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
      ADatos.FormatoDocumento,
      SErrorRectificativaPendienteExistente,
      [ADatos.Serie, ADatos.Numero]))
  else
    Result := TResultadoOperacionFactura.Correcto;
end;

function EvaluarSolicitudRectificativa(
  const ASolicitud: TSolicitudRectificativaFactura;
  const ADatos: TDatosOrigenRectificativa): TResultadoOperacionFactura;
var
  bFiscal: Boolean;
begin
  bFiscal := OperacionRectificativaEsFiscal(ASolicitud.Operacion);
  if not ADatos.Encontrada then
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado)
  else if bFiscal then
    Result := EvaluarOrigenRectificativa(ADatos)
  else
    Result := TResultadoOperacionFactura.Correcto;
  if Result.Exito then
  begin
    if Trim(ASolicitud.Serie) = '' then
      Result := TResultadoOperacionFactura.Error(
        SErrorRectificativaSerieObligatoria)
    else if ASolicitud.Fecha <= 0 then
      Result := TResultadoOperacionFactura.Error(
        SErrorRectificativaFechaObligatoria)
    else if bFiscal and (Trim(ASolicitud.Motivo) = '') then
      Result := TResultadoOperacionFactura.Error(
        SErrorRectificativaMotivoObligatorio)
    else if bFiscal and
            (not TipoFacturaVerifactuRectificativaValido(
              ASolicitud.TipoFacturaVerifactu,
              OrigenRectificativaEsSimplificado(ADatos.TipoFactura))) then
      Result := TResultadoOperacionFactura.Error(FormatearMensajeDocumentos(
        ADatos.FormatoDocumento,
        SErrorRectificativaTipoVerifactuInvalido,
        [Trim(ASolicitud.TipoFacturaVerifactu),
        ADatos.Serie, ADatos.Numero]));
  end;
end;

{ TServicioRectificativaFactura }

constructor TServicioRectificativaFactura.Create(
  const ARepositorio: IRepositorioRectificativaFactura;
  const ACola: IServicioVerifactuCola;
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
  FEmision := AEmision;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FUsuario := AUsuario;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TServicioRectificativaFactura.CargarOrigen(
  const ASerie, ANumero: string): TDatosOrigenRectificativa;
begin
  Result := FRepositorio.CargarOrigen(ASerie, ANumero);
end;

function TServicioRectificativaFactura.Validar(
  const ASolicitud: TSolicitudRectificativaFactura
): TResultadoOperacionFactura;
begin
  Result := EvaluarSolicitudRectificativa(
    ASolicitud,
    FRepositorio.CargarOrigen(
      ASolicitud.SerieOriginal,
      ASolicitud.NumeroOriginal));
end;

function TServicioRectificativaFactura.CrearVinculo(
  const ASolicitud: TSolicitudRectificativaFactura;
  const ANumero: string): TSolicitudVinculoRectificativa;
begin
  Result := Default(TSolicitudVinculoRectificativa);
  Result.Usuario := FUsuario;
  Result.SerieOriginal := ASolicitud.SerieOriginal;
  Result.NumeroOriginal := ASolicitud.NumeroOriginal;
  Result.SerieRectificativa := ASolicitud.Serie;
  Result.NumeroRectificativa := ANumero;
  Result.TipoRectificativa :=
    CodigoTipoRectificativaFactura(ASolicitud.Operacion);
  Result.TipoFacturaVerifactu := Trim(ASolicitud.TipoFacturaVerifactu);
  Result.Motivo := Trim(ASolicitud.Motivo);
  Result.ReemplazarMovimientosOriginales :=
    ASolicitud.Movimientos = mrfReemplazarOriginales;
  Result.EmitirAhora := ASolicitud.EmitirAlCrear;
  if ASolicitud.EmitirAlCrear then
    Result.DescripcionEvento :=
      'Rectificativa de ' + FormatearDocumento(
        FormatoDocumentoFacturaDelProveedor(FRepositorio,
        ASolicitud.SerieOriginal, ASolicitud.NumeroOriginal),
        ASolicitud.SerieOriginal, ASolicitud.NumeroOriginal) +
      ' tipo ' + Result.TipoRectificativa +
      ' emitida al crearla desde Facturas';
end;

procedure TServicioRectificativaFactura.EmitirDuplicado(
  const ASolicitud: TSolicitudRectificativaFactura;
  const ANumero: string);
var
  oSolicitud: TSolicitudEmisionFiscal;
begin
  oSolicitud := TSolicitudEmisionFiscal.ParaAlta(
    ASolicitud.Serie,
    ANumero,
    FUsuario,
    'Duplicado de ' + FormatearDocumento(
      FormatoDocumentoFacturaDelProveedor(FRepositorio,
        ASolicitud.SerieOriginal, ASolicitud.NumeroOriginal),
      ASolicitud.SerieOriginal, ASolicitud.NumeroOriginal) +
    ' emitido al crearlo desde Facturas');
  FEmision.Emitir(oSolicitud);
end;

function TServicioRectificativaFactura.MensajeResultado(
  const ASolicitud: TSolicitudRectificativaFactura;
  const ANumero, AFormatoDocumento: string): string;
begin
  if OperacionRectificativaEsFiscal(ASolicitud.Operacion) then
  begin
    if ASolicitud.EmitirAlCrear then
      Result := FormatearMensajeDocumentos(
        AFormatoDocumento,
        SInfoRectificativaCreadaEmitida,
        [ASolicitud.Serie, ANumero, ModoVerifactuTexto(FParametrosApp)])
    else
      Result := FormatearMensajeDocumentos(
        AFormatoDocumento,
        SInfoRectificativaCreadaBorrador,
        [ASolicitud.Serie, ANumero]);
  end
  else if ASolicitud.EmitirAlCrear then
    Result := FormatearMensajeDocumentos(
      AFormatoDocumento,
      SInfoDuplicadoCreadoEmitido,
      [ASolicitud.Serie, ANumero, ModoVerifactuTexto(FParametrosApp)])
  else
    Result := Format(SInfoBorradorCreadoOpcionesDocumento,
      [ASolicitud.Serie, ANumero]);
end;

function TServicioRectificativaFactura.Crear(
  const ASolicitud: TSolicitudRectificativaFactura
): TResultadoRectificativaFactura;
var
  oDatos: TDatosOrigenRectificativa;
  oValidacion: TResultadoOperacionFactura;
  sNumero: string;
begin
  Result := Default(TResultadoRectificativaFactura);
  oDatos := FRepositorio.CargarOrigen(
    ASolicitud.SerieOriginal,
    ASolicitud.NumeroOriginal);
  oValidacion := EvaluarSolicitudRectificativa(ASolicitud, oDatos);
  if not oValidacion.Exito then
    raise ERectificativaFactura.Create(oValidacion.Mensaje);
  // Copia (SP de abono o duplicado), forma de pago, vínculo fiscal y
  // emisión en una sola transacción: un fallo no deja un borrador a
  // medias con el número FC consumido (FZ-ISSUE-148). Los SP y la cola
  // solo abren transacción propia si no hay una abierta (FZ-ISSUE-143).
  sNumero := '';
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      sNumero := FRepositorio.CrearBorrador(
        ASolicitud,
        FUsuario,
        oDatos.CodigoEmpresa);
      if OperacionRectificativaEsFiscal(ASolicitud.Operacion) then
        FCola.VincularRectificativa(
          FParametrosApp,
          FParametrosCaja,
          FEmision,
          CrearVinculo(ASolicitud, sNumero))
      else if ASolicitud.EmitirAlCrear then
        EmitirDuplicado(ASolicitud, sNumero);
    end);
  Result.Serie := ASolicitud.Serie;
  Result.Numero := sNumero;
  Result.Emitida := ASolicitud.EmitirAlCrear;
  Result.Mensaje := MensajeResultado(
    ASolicitud, sNumero, oDatos.FormatoDocumento);
end;

procedure TServicioRectificativaFactura.CompletarEmision(
  const ASerie, ANumero, AUsuario: string);
begin
  FCola.CompletarRectificativa(
    FParametrosApp,
    FParametrosCaja,
    AUsuario,
    ASerie,
    ANumero);
end;

function CrearServicioRectificativaFactura(
  const ARepositorio: IRepositorioRectificativaFactura;
  const ACola: IServicioVerifactuCola;
  const AEmision: IServicioEmisionFiscal;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const AUnidadTrabajo: IUnidadTrabajoFacturas
): IServicioRectificativaFactura;
begin
  Result := TServicioRectificativaFactura.Create(
    ARepositorio,
    ACola,
    AEmision,
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    AUnidadTrabajo);
end;

end.
