{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasVistaVcl                                        }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta operaciones visuales mínimas de factura mediante callbacks.       }
{******************************************************************************}
unit inMtoFacturasVistaVcl;

interface

uses
  System.Classes,
  inLibFacturasAplicacionIntf;

type
  TConfirmarFacturaVcl = reference to function(
    const APregunta: string): Boolean;
  TMensajeFacturaVcl = reference to procedure(
    const AMensaje: string);
  TAccionFacturaVcl = reference to procedure;
  TArchivarFacturaVcl = reference to procedure(
    const ASerie, ANumero: string);
  TAplicarEstadoFacturaVcl = reference to procedure(
    const AEstado: TEstadoVisualFactura);
  TAplicarModoEntradaFacturaVcl = reference to procedure(
    AModo: TModoEntradaFactura);
  TDetalleFacturaVcl = (
    dfvNinguno,
    dfvCobros,
    dfvConsolidacion,
    dfvRegistro,
    dfvMovimientos);
  TContextoDetalleFacturaVcl = record
    Detalle: TDetalleFacturaVcl;
    EsVentaMayor: Boolean;
    AsegurarEfectos: TAccionFacturaVcl;
    AsegurarRecibos: TAccionFacturaVcl;
    AsegurarConsolidacion: TAccionFacturaVcl;
    AsegurarRegistro: TAccionFacturaVcl;
    AsegurarMovimientos: TAccionFacturaVcl;
  end;
  TOperacionesVistaFacturaVcl = record
    Confirmar: TConfirmarFacturaVcl;
    MostrarInformacion: TMensajeFacturaVcl;
    MostrarError: TMensajeFacturaVcl;
    RefrescarFactura: TAccionFacturaVcl;
    RefrescarMovimientos: TAccionFacturaVcl;
    ArchivarFactura: TArchivarFacturaVcl;
    AplicarEstado: TAplicarEstadoFacturaVcl;
    AplicarModoEntrada: TAplicarModoEntradaFacturaVcl;
  end;

function CrearVistaFacturaVcl(
  const AOperaciones: TOperacionesVistaFacturaVcl
): IVistaFactura;
function ProcesarTeclaCambioModoFacturaVcl(
  var ATecla: Word;
  AShift: TShiftState;
  AHabilitado: Boolean;
  const AGestor: IGestorModoEntradaFactura;
  const AAntesDeCambiar: TAccionFacturaVcl
): Boolean;
procedure ActivarDetalleFacturaVcl(
  const AContexto: TContextoDetalleFacturaVcl);

implementation

uses
  Winapi.Windows;

type
  TVistaFacturaVcl = class(TInterfacedObject, IVistaFactura)
  private
    FOperaciones: TOperacionesVistaFacturaVcl;
  public
    constructor Create(
      const AOperaciones: TOperacionesVistaFacturaVcl);
    function Confirmar(const APregunta: string): Boolean;
    procedure MostrarInformacion(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure RefrescarFactura;
    procedure RefrescarMovimientos;
    procedure ArchivarFactura(const ASerie, ANumero: string);
    procedure AplicarEstado(const AEstado: TEstadoVisualFactura);
    procedure AplicarModoEntrada(AModo: TModoEntradaFactura);
  end;

constructor TVistaFacturaVcl.Create(
  const AOperaciones: TOperacionesVistaFacturaVcl);
begin
  inherited Create;
  FOperaciones := AOperaciones;
end;

function TVistaFacturaVcl.Confirmar(
  const APregunta: string): Boolean;
begin
  Result := Assigned(FOperaciones.Confirmar) and
    FOperaciones.Confirmar(APregunta);
end;

procedure TVistaFacturaVcl.MostrarInformacion(
  const AMensaje: string);
begin
  if Assigned(FOperaciones.MostrarInformacion) then
    FOperaciones.MostrarInformacion(AMensaje);
end;

procedure TVistaFacturaVcl.MostrarError(
  const AMensaje: string);
begin
  if Assigned(FOperaciones.MostrarError) then
    FOperaciones.MostrarError(AMensaje);
end;

procedure TVistaFacturaVcl.RefrescarFactura;
begin
  if Assigned(FOperaciones.RefrescarFactura) then
    FOperaciones.RefrescarFactura();
end;

procedure TVistaFacturaVcl.RefrescarMovimientos;
begin
  if Assigned(FOperaciones.RefrescarMovimientos) then
    FOperaciones.RefrescarMovimientos();
end;

procedure TVistaFacturaVcl.ArchivarFactura(
  const ASerie, ANumero: string);
begin
  if Assigned(FOperaciones.ArchivarFactura) then
    FOperaciones.ArchivarFactura(ASerie, ANumero);
end;

procedure TVistaFacturaVcl.AplicarEstado(
  const AEstado: TEstadoVisualFactura);
begin
  if Assigned(FOperaciones.AplicarEstado) then
    FOperaciones.AplicarEstado(AEstado);
end;

procedure TVistaFacturaVcl.AplicarModoEntrada(
  AModo: TModoEntradaFactura);
begin
  if Assigned(FOperaciones.AplicarModoEntrada) then
    FOperaciones.AplicarModoEntrada(AModo);
end;

function CrearVistaFacturaVcl(
  const AOperaciones: TOperacionesVistaFacturaVcl
): IVistaFactura;
begin
  Result := TVistaFacturaVcl.Create(AOperaciones);
end;

function ProcesarTeclaCambioModoFacturaVcl(
  var ATecla: Word;
  AShift: TShiftState;
  AHabilitado: Boolean;
  const AGestor: IGestorModoEntradaFactura;
  const AAntesDeCambiar: TAccionFacturaVcl
): Boolean;
begin
  Result := (ATecla = VK_F1) and
    (AShift = []) and
    AHabilitado and
    Assigned(AGestor);
  if Result then
  begin
    ATecla := 0;
    // Graba la linea en edicion; si no es valida, el modo no cambia.
    if Assigned(AAntesDeCambiar) then
      AAntesDeCambiar();
    AGestor.SeleccionarSiguiente;
  end;
end;

procedure ActivarDetalleFacturaVcl(
  const AContexto: TContextoDetalleFacturaVcl);
begin
  case AContexto.Detalle of
    dfvCobros:
    begin
      if AContexto.EsVentaMayor then
      begin
        if Assigned(AContexto.AsegurarEfectos) then
          AContexto.AsegurarEfectos();
      end
      else if Assigned(AContexto.AsegurarRecibos) then
        AContexto.AsegurarRecibos();
    end;
    dfvConsolidacion:
      if Assigned(AContexto.AsegurarConsolidacion) then
        AContexto.AsegurarConsolidacion();
    dfvRegistro:
      if Assigned(AContexto.AsegurarRegistro) then
        AContexto.AsegurarRegistro();
    dfvMovimientos:
      if Assigned(AContexto.AsegurarMovimientos) then
        AContexto.AsegurarMovimientos();
  end;
end;

end.
