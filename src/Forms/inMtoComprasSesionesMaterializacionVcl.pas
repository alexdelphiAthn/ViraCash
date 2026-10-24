{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesMaterializacionVcl                        }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta callbacks visuales y de datos a los puertos de materializacion.    }
{    Recibe solo las operaciones necesarias y nunca el formulario completo.    }
{******************************************************************************}
unit inMtoComprasSesionesMaterializacionVcl;

interface

uses
  inLibComprasSesionesAplicacionIntf,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPreciosTalla;

type
  TLeerEstadoMaterializacionSesion = reference to function:
    TEstadoSesionCreacion;
  TGuardarEdicionMaterializacionSesion = reference to procedure;
  TNormalizarDuplicadosMaterializacionSesion = reference to function(
    const AEstado: TEstadoSesionCreacion): Integer;
  TValidarMaterializacionSesion = reference to function(
    out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
  TCalcularDefectosMaterializacionSesion = reference to function(
    const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
  TActualizarCabeceraMaterializacionSesion = reference to procedure(
    const AAjustes: TAjustesCreacionElegidos);
  TMaterializarCompraSesion = reference to function(
    const AAjustes: TAjustesCreacionElegidos;
    out AResultado: TResultadoMaterializacionSesion): Boolean;
  TRefrescarMaterializacionSesion = reference to procedure;
  TRegistrarMaterializacionSesion = reference to procedure(
    const ATexto: string);
  TMostrarBloqueoMaterializacionSesion = reference to procedure(
    AMotivo: TMotivoBloqueoCreacion);
  TInformarDuplicadosMaterializacionSesion = reference to procedure(
    ACantidad: Integer);
  TMostrarIncidenciasMaterializacionSesion = reference to procedure(
    const AIncidencias: TIncidenciasMaterializacionSesion);
  TSolicitarAjustesMaterializacionSesion = reference to function(
    const AEstado: TEstadoSesionCreacion;
    const ADefectos: TDefectosDialogoCreacion;
    out AAjustes: TAjustesCreacionElegidos): Boolean;
  TMostrarResultadoMaterializacionSesion = reference to procedure(
    const AResultado: TResultadoMaterializacionSesion);
  TMostrarErrorMaterializacionSesion = reference to procedure(
    const AMensaje: string);
  TSeriesSinPropiaMaterializacionSesion = reference to function(
    const AEstado: TEstadoSesionCreacion;
    const AAjustes: TAjustesCreacionElegidos): TSeriesAlmacenesSinPropia;
  TConfirmarSeriesSinPropiaMaterializacionSesion = reference to function(
    const ASeries: TSeriesAlmacenesSinPropia): Boolean;
  TCalcularPreciosTarifaMaterializacionSesion = reference to function(
    const AAjustes: TAjustesCreacionElegidos): TArticulosPreciosTarifa;
  TConfirmarPreciosTarifaMaterializacionSesion = reference to function(
    const ATarifa: string; const APrecios: TArticulosPreciosTarifa;
    var AOpciones: TOpcionesTarifaSesion): Boolean;

  TCallbacksMaterializacionCompraSesion = record
    LeerEstado: TLeerEstadoMaterializacionSesion;
    GuardarEdicion: TGuardarEdicionMaterializacionSesion;
    NormalizarDuplicados: TNormalizarDuplicadosMaterializacionSesion;
    Validar: TValidarMaterializacionSesion;
    CalcularDefectos: TCalcularDefectosMaterializacionSesion;
    ActualizarCabecera: TActualizarCabeceraMaterializacionSesion;
    Materializar: TMaterializarCompraSesion;
    Refrescar: TRefrescarMaterializacionSesion;
    Registrar: TRegistrarMaterializacionSesion;
    MostrarBloqueo: TMostrarBloqueoMaterializacionSesion;
    InformarDuplicados: TInformarDuplicadosMaterializacionSesion;
    MostrarIncidencias: TMostrarIncidenciasMaterializacionSesion;
    SolicitarAjustes: TSolicitarAjustesMaterializacionSesion;
    MostrarResultado: TMostrarResultadoMaterializacionSesion;
    MostrarError: TMostrarErrorMaterializacionSesion;
    MostrarAviso: TMostrarErrorMaterializacionSesion;
    SeriesSinPropia: TSeriesSinPropiaMaterializacionSesion;
    ConfirmarSeriesSinPropia: TConfirmarSeriesSinPropiaMaterializacionSesion;
    CalcularPreciosTarifa: TCalcularPreciosTarifaMaterializacionSesion;
    ConfirmarPreciosTarifa: TConfirmarPreciosTarifaMaterializacionSesion;
  end;

  TAdaptadorMaterializacionCompraSesionVcl = class(
    TInterfacedObject,
    IOperacionesMaterializacionCompraSesion,
    IVistaMaterializacionCompraSesion)
  private
    FCallbacks: TCallbacksMaterializacionCompraSesion;
  public
    constructor Create(
      const ACallbacks: TCallbacksMaterializacionCompraSesion);
    function LeerEstado: TEstadoSesionCreacion;
    procedure GuardarEdicion;
    function NormalizarDuplicados(
      const AEstado: TEstadoSesionCreacion): Integer;
    function Validar(
      out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
    function CalcularDefectos(
      const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
    procedure ActualizarCabecera(
      const AAjustes: TAjustesCreacionElegidos);
    function SeriesSinPropia(
      const AEstado: TEstadoSesionCreacion;
      const AAjustes: TAjustesCreacionElegidos): TSeriesAlmacenesSinPropia;
    function Materializar(
      const AAjustes: TAjustesCreacionElegidos;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    procedure Refrescar;
    function CalcularPreciosTarifa(
      const AAjustes: TAjustesCreacionElegidos): TArticulosPreciosTarifa;
    procedure Registrar(const ATexto: string);
    procedure MostrarBloqueo(AMotivo: TMotivoBloqueoCreacion);
    procedure InformarDuplicados(ACantidad: Integer);
    procedure MostrarIncidencias(
      const AIncidencias: TIncidenciasMaterializacionSesion);
    function SolicitarAjustes(
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean;
    function ConfirmarSeriesSinPropia(
      const ASeries: TSeriesAlmacenesSinPropia): Boolean;
    procedure MostrarResultado(
      const AResultado: TResultadoMaterializacionSesion);
    procedure MostrarError(const AMensaje: string);
    procedure MostrarAviso(const AMensaje: string);
    function ConfirmarPreciosTarifa(const ATarifa: string;
      const APrecios: TArticulosPreciosTarifa;
      var AOpciones: TOpcionesTarifaSesion): Boolean;
  end;

implementation

constructor TAdaptadorMaterializacionCompraSesionVcl.Create(
  const ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  inherited Create;
  FCallbacks := ACallbacks;
end;

function TAdaptadorMaterializacionCompraSesionVcl.LeerEstado:
  TEstadoSesionCreacion;
begin
  Result := FCallbacks.LeerEstado();
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.GuardarEdicion;
begin
  FCallbacks.GuardarEdicion();
end;

function TAdaptadorMaterializacionCompraSesionVcl.NormalizarDuplicados(
  const AEstado: TEstadoSesionCreacion): Integer;
begin
  Result := FCallbacks.NormalizarDuplicados(AEstado);
end;

function TAdaptadorMaterializacionCompraSesionVcl.Validar(
  out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
begin
  Result := FCallbacks.Validar(AIncidencias);
end;

function TAdaptadorMaterializacionCompraSesionVcl.CalcularDefectos(
  const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
begin
  Result := FCallbacks.CalcularDefectos(AEstado);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.ActualizarCabecera(
  const AAjustes: TAjustesCreacionElegidos);
begin
  FCallbacks.ActualizarCabecera(AAjustes);
end;

function TAdaptadorMaterializacionCompraSesionVcl.SeriesSinPropia(
  const AEstado: TEstadoSesionCreacion;
  const AAjustes: TAjustesCreacionElegidos): TSeriesAlmacenesSinPropia;
begin
  Result := nil;
  if Assigned(FCallbacks.SeriesSinPropia) then
    Result := FCallbacks.SeriesSinPropia(AEstado, AAjustes);
end;

function TAdaptadorMaterializacionCompraSesionVcl.ConfirmarSeriesSinPropia(
  const ASeries: TSeriesAlmacenesSinPropia): Boolean;
begin
  Result := True;
  if Assigned(FCallbacks.ConfirmarSeriesSinPropia) then
    Result := FCallbacks.ConfirmarSeriesSinPropia(ASeries);
end;

function TAdaptadorMaterializacionCompraSesionVcl.Materializar(
  const AAjustes: TAjustesCreacionElegidos;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
begin
  Result := FCallbacks.Materializar(AAjustes, AResultado);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.Refrescar;
begin
  FCallbacks.Refrescar();
end;

function TAdaptadorMaterializacionCompraSesionVcl.CalcularPreciosTarifa(
  const AAjustes: TAjustesCreacionElegidos): TArticulosPreciosTarifa;
begin
  Result := nil;
  if Assigned(FCallbacks.CalcularPreciosTarifa) then
    Result := FCallbacks.CalcularPreciosTarifa(AAjustes);
end;

function TAdaptadorMaterializacionCompraSesionVcl.ConfirmarPreciosTarifa(
  const ATarifa: string; const APrecios: TArticulosPreciosTarifa;
  var AOpciones: TOpcionesTarifaSesion): Boolean;
begin
  Result := True;
  if Assigned(FCallbacks.ConfirmarPreciosTarifa) then
    Result := FCallbacks.ConfirmarPreciosTarifa(ATarifa, APrecios,
      AOpciones);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.Registrar(
  const ATexto: string);
begin
  FCallbacks.Registrar(ATexto);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.MostrarBloqueo(
  AMotivo: TMotivoBloqueoCreacion);
begin
  FCallbacks.MostrarBloqueo(AMotivo);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.InformarDuplicados(
  ACantidad: Integer);
begin
  FCallbacks.InformarDuplicados(ACantidad);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.MostrarIncidencias(
  const AIncidencias: TIncidenciasMaterializacionSesion);
begin
  FCallbacks.MostrarIncidencias(AIncidencias);
end;

function TAdaptadorMaterializacionCompraSesionVcl.SolicitarAjustes(
  const AEstado: TEstadoSesionCreacion;
  const ADefectos: TDefectosDialogoCreacion;
  out AAjustes: TAjustesCreacionElegidos): Boolean;
begin
  Result := FCallbacks.SolicitarAjustes(
    AEstado,
    ADefectos,
    AAjustes);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.MostrarResultado(
  const AResultado: TResultadoMaterializacionSesion);
begin
  FCallbacks.MostrarResultado(AResultado);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.MostrarError(
  const AMensaje: string);
begin
  FCallbacks.MostrarError(AMensaje);
end;

procedure TAdaptadorMaterializacionCompraSesionVcl.MostrarAviso(
  const AMensaje: string);
begin
  if Assigned(FCallbacks.MostrarAviso) then
    FCallbacks.MostrarAviso(AMensaje)
  else
    FCallbacks.MostrarError(AMensaje);
end;

end.
