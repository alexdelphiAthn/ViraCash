{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaEntradaVcl                                           }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta operaciones concretas de entrada de caja mediante callbacks.      }
{******************************************************************************}
unit inMtoCajaEntradaVcl;

interface

uses
  inLibCajaEntradaIntf;

type
  TConsultaEntradaCajaVcl = reference to function: Boolean;
  TConsultaSkuEntradaCajaVcl = reference to function(
    const ACodigoSku: string): Boolean;
  TAccionEntradaCajaVcl = reference to procedure;
  TMensajeEntradaCajaVcl = reference to procedure(
    const AMensaje: string);
  TAplicarCodigoEntradaCajaVcl = reference to procedure(
    const ACodigo, ACodigoSku, ACodigoArticulo: string);
  TOperacionesEntradaCajaVcl = record
    Disponible: TConsultaEntradaCajaVcl;
    VendedorAsignado: TConsultaEntradaCajaVcl;
    PermitirSku: TConsultaSkuEntradaCajaVcl;
    PrepararLinea: TAccionEntradaCajaVcl;
    ConsolidarSku: TConsultaSkuEntradaCajaVcl;
    AplicarCodigo: TAplicarCodigoEntradaCajaVcl;
    Iniciar: TAccionEntradaCajaVcl;
    Finalizar: TAccionEntradaCajaVcl;
    MostrarError: TMensajeEntradaCajaVcl;
    EnfocarVendedor: TAccionEntradaCajaVcl;
    PrepararLectura: TAccionEntradaCajaVcl;
    RefrescarConsolidacion: TAccionEntradaCajaVcl;
    PrepararSiguiente: TAccionEntradaCajaVcl;
  end;

procedure CrearPuertosEntradaCajaVcl(
  const AOperaciones: TOperacionesEntradaCajaVcl;
  out APuertoOperaciones: IOperacionesEntradaCaja;
  out AVista: IVistaEntradaCaja);

implementation

type
  TAdaptadorEntradaCajaVcl = class(
    TInterfacedObject,
    IOperacionesEntradaCaja,
    IVistaEntradaCaja)
  private
    FOperaciones: TOperacionesEntradaCajaVcl;
  public
    constructor Create(
      const AOperaciones: TOperacionesEntradaCajaVcl);
    function Disponible: Boolean;
    function VendedorAsignado: Boolean;
    function PermitirSku(const ACodigoSku: string): Boolean;
    procedure PrepararLinea;
    function ConsolidarSku(const ACodigoSku: string): Boolean;
    procedure AplicarCodigo(
      const ACodigo, ACodigoSku, ACodigoArticulo: string);
    procedure Iniciar;
    procedure Finalizar;
    procedure MostrarError(const AMensaje: string);
    procedure EnfocarVendedor;
    procedure PrepararLectura;
    procedure RefrescarConsolidacion;
    procedure PrepararSiguiente;
  end;

constructor TAdaptadorEntradaCajaVcl.Create(
  const AOperaciones: TOperacionesEntradaCajaVcl);
begin
  inherited Create;
  FOperaciones := AOperaciones;
end;

function TAdaptadorEntradaCajaVcl.Disponible: Boolean;
begin
  Result := Assigned(FOperaciones.Disponible) and
    FOperaciones.Disponible();
end;

function TAdaptadorEntradaCajaVcl.VendedorAsignado: Boolean;
begin
  Result := Assigned(FOperaciones.VendedorAsignado) and
    FOperaciones.VendedorAsignado();
end;

function TAdaptadorEntradaCajaVcl.PermitirSku(
  const ACodigoSku: string): Boolean;
begin
  Result := Assigned(FOperaciones.PermitirSku) and
    FOperaciones.PermitirSku(ACodigoSku);
end;

procedure TAdaptadorEntradaCajaVcl.PrepararLinea;
begin
  if Assigned(FOperaciones.PrepararLinea) then
    FOperaciones.PrepararLinea();
end;

function TAdaptadorEntradaCajaVcl.ConsolidarSku(
  const ACodigoSku: string): Boolean;
begin
  Result := Assigned(FOperaciones.ConsolidarSku) and
    FOperaciones.ConsolidarSku(ACodigoSku);
end;

procedure TAdaptadorEntradaCajaVcl.AplicarCodigo(
  const ACodigo, ACodigoSku, ACodigoArticulo: string);
begin
  if Assigned(FOperaciones.AplicarCodigo) then
    FOperaciones.AplicarCodigo(
      ACodigo,
      ACodigoSku,
      ACodigoArticulo);
end;

procedure TAdaptadorEntradaCajaVcl.Iniciar;
begin
  if Assigned(FOperaciones.Iniciar) then
    FOperaciones.Iniciar();
end;

procedure TAdaptadorEntradaCajaVcl.Finalizar;
begin
  if Assigned(FOperaciones.Finalizar) then
    FOperaciones.Finalizar();
end;

procedure TAdaptadorEntradaCajaVcl.MostrarError(
  const AMensaje: string);
begin
  if Assigned(FOperaciones.MostrarError) then
    FOperaciones.MostrarError(AMensaje);
end;

procedure TAdaptadorEntradaCajaVcl.EnfocarVendedor;
begin
  if Assigned(FOperaciones.EnfocarVendedor) then
    FOperaciones.EnfocarVendedor();
end;

procedure TAdaptadorEntradaCajaVcl.PrepararLectura;
begin
  if Assigned(FOperaciones.PrepararLectura) then
    FOperaciones.PrepararLectura();
end;

procedure TAdaptadorEntradaCajaVcl.RefrescarConsolidacion;
begin
  if Assigned(FOperaciones.RefrescarConsolidacion) then
    FOperaciones.RefrescarConsolidacion();
end;

procedure TAdaptadorEntradaCajaVcl.PrepararSiguiente;
begin
  if Assigned(FOperaciones.PrepararSiguiente) then
    FOperaciones.PrepararSiguiente();
end;

procedure CrearPuertosEntradaCajaVcl(
  const AOperaciones: TOperacionesEntradaCajaVcl;
  out APuertoOperaciones: IOperacionesEntradaCaja;
  out AVista: IVistaEntradaCaja);
var
  Adaptador: TAdaptadorEntradaCajaVcl;
begin
  Adaptador := TAdaptadorEntradaCajaVcl.Create(AOperaciones);
  APuertoOperaciones := Adaptador;
  AVista := Adaptador;
end;

end.
