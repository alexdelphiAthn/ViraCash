{******************************************************************************}
{                                                                              }
{  Módulo: inLibControladorMantenimiento                                       }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 14/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Coordina edición y cierre sin UI ni SQL.                       }
{                                                                              }
{******************************************************************************}

unit inLibControladorMantenimiento;

interface

uses
  inLibMantenimientoMvcIntf;

type
  TControladorMantenimiento = class
  private
    FModelo: IModeloMantenimiento;
    FInteraccion: TInteraccionMantenimiento;
  public
    constructor Create(const AModelo: IModeloMantenimiento;
      const AInteraccion: TInteraccionMantenimiento);
    function PuedeInsertar: Boolean;
    function PuedeEditar: Boolean;
    function PuedeEliminar: Boolean;
    function PuedeRefrescar: Boolean;
    function PuedeGrabar: Boolean;
    procedure Editar;
    procedure Eliminar;
    procedure Refrescar;
    function ConsultarCierre: Boolean;
  end;

implementation

uses
  System.SysUtils,
  inLibPermisosIntf;

constructor TControladorMantenimiento.Create(
  const AModelo: IModeloMantenimiento;
  const AInteraccion: TInteraccionMantenimiento);
begin
  inherited Create;
  if AModelo = nil then
    raise EArgumentNilException.Create('AModelo');
  if not Assigned(AInteraccion.PermitirAccion) then
    raise EArgumentNilException.Create('PermitirAccion');
  if not Assigned(AInteraccion.ConfirmarCierre) then
    raise EArgumentNilException.Create('ConfirmarCierre');
  if not Assigned(AInteraccion.Guardar) then
    raise EArgumentNilException.Create('Guardar');
  FModelo := AModelo;
  FInteraccion := AInteraccion;
end;

function TControladorMantenimiento.PuedeInsertar: Boolean;
begin
  Result := (FModelo.ConsultarEstado.Modo <> mmInactivo) and
    FInteraccion.PermitirAccion(apmInsertar);
end;

function TControladorMantenimiento.PuedeEditar: Boolean;
begin
  Result := (FModelo.ConsultarEstado.Modo <> mmInactivo) and
    FInteraccion.PermitirAccion(apmModificar);
end;

function TControladorMantenimiento.PuedeEliminar: Boolean;
var
  oEstado: TEstadoMantenimiento;
begin
  oEstado := FModelo.ConsultarEstado;
  Result := (oEstado.Modo <> mmInactivo) and
    not oEstado.EstaVacio and FInteraccion.PermitirAccion(apmBorrar);
end;

function TControladorMantenimiento.PuedeRefrescar: Boolean;
begin
  Result := FModelo.ConsultarEstado.Modo = mmConsulta;
end;

function TControladorMantenimiento.PuedeGrabar: Boolean;
begin
  Result := False;
  case FModelo.ConsultarEstado.Modo of
    mmAlta:
      Result := FInteraccion.PermitirAccion(apmInsertar);
    mmModificacion:
      Result := FInteraccion.PermitirAccion(apmModificar);
    mmConsulta:
      Result := FModelo.HayCambiosPendientes and
        FInteraccion.PermitirAccion(apmModificar);
  end;
end;

procedure TControladorMantenimiento.Editar;
begin
  if PuedeEditar then
    FModelo.Editar;
end;

procedure TControladorMantenimiento.Eliminar;
begin
  // Delete conserva los eventos del guardián de borrado del modelo.
  if PuedeEliminar then
    FModelo.Eliminar;
end;

procedure TControladorMantenimiento.Refrescar;
begin
  if PuedeRefrescar then
    FModelo.Refrescar;
end;

function TControladorMantenimiento.ConsultarCierre: Boolean;
begin
  Result := True;
  if FModelo.HayCambiosPendientes then
  begin
    case FInteraccion.ConfirmarCierre() of
      dcGuardar:
      begin
        FInteraccion.Guardar();
        Result := not FModelo.HayCambiosPendientes;
      end;
      dcDescartar:
        FModelo.Cancelar;
      dcCancelar:
        Result := False;
    end;
  end;
end;

end.
