{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosGuardadoVcl                                     }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta callbacks concretos al puerto de guardado sin recibir el form.     }
{******************************************************************************}
unit inMtoArticulosGuardadoVcl;

interface

uses
  inLibArticulosGuardadoIntf;

type
  TValidarPropiedadesArticulo = reference to function: string;
  TGuardarCapacidadArticulo = reference to function(
    out AMensajeError: string): Boolean;
  TGuardarEdicionesArticulo = reference to procedure;

  TCallbacksGuardadoArticulo = record
    ValidarPropiedades: TValidarPropiedadesArticulo;
    GuardarPropiedades: TGuardarCapacidadArticulo;
    GuardarEdicionesPendientes: TGuardarEdicionesArticulo;
    GuardarVariaciones: TGuardarCapacidadArticulo;
  end;

  TAdaptadorGuardadoArticuloVcl = class(
    TInterfacedObject,
    IOperacionesGuardadoArticulo)
  private
    FCallbacks: TCallbacksGuardadoArticulo;
  public
    constructor Create(const ACallbacks: TCallbacksGuardadoArticulo);
    function ValidarPropiedades: string;
    function GuardarPropiedades(out AMensajeError: string): Boolean;
    procedure GuardarEdicionesPendientes;
    function GuardarVariaciones(out AMensajeError: string): Boolean;
  end;

implementation

constructor TAdaptadorGuardadoArticuloVcl.Create(
  const ACallbacks: TCallbacksGuardadoArticulo);
begin
  inherited Create;
  FCallbacks := ACallbacks;
end;

function TAdaptadorGuardadoArticuloVcl.ValidarPropiedades: string;
begin
  Result := FCallbacks.ValidarPropiedades();
end;

function TAdaptadorGuardadoArticuloVcl.GuardarPropiedades(
  out AMensajeError: string): Boolean;
begin
  Result := FCallbacks.GuardarPropiedades(AMensajeError);
end;

procedure TAdaptadorGuardadoArticuloVcl.GuardarEdicionesPendientes;
begin
  FCallbacks.GuardarEdicionesPendientes();
end;

function TAdaptadorGuardadoArticuloVcl.GuardarVariaciones(
  out AMensajeError: string): Boolean;
begin
  Result := FCallbacks.GuardarVariaciones(AMensajeError);
end;

end.
