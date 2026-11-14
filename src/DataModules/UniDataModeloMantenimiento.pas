{******************************************************************************}
{                                                                              }
{  Módulo: UniDataModeloMantenimiento                                          }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 14/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Adapta datasets al modelo del mantenimiento.                   }
{                                                                              }
{******************************************************************************}

unit UniDataModeloMantenimiento;

interface

uses
  System.Classes, System.SysUtils, Data.DB,
  inLibMantenimientoMvcIntf;

type
  // No posee el DataSource ni el módulo; la vista los mantiene vivos.
  // El módulo se resuelve al usarlo: puede crearse después del formulario.
  TModeloMantenimientoDatasets = class(TInterfacedObject,
    IModeloMantenimiento)
  private
    FOrigen: TDataSource;
    FObtenerModulo: TFunc<TDataModule>;
  public
    constructor Create(AOrigen: TDataSource;
      const AObtenerModulo: TFunc<TDataModule>);
    function ConsultarEstado: TEstadoMantenimiento;
    function HayCambiosPendientes: Boolean;
    procedure Editar;
    procedure Eliminar;
    procedure Refrescar;
    procedure Cancelar;
  end;

implementation

uses
  inLibDatasets;

constructor TModeloMantenimientoDatasets.Create(AOrigen: TDataSource;
  const AObtenerModulo: TFunc<TDataModule>);
begin
  inherited Create;
  if AOrigen = nil then
    raise EArgumentNilException.Create('AOrigen');
  if not Assigned(AObtenerModulo) then
    raise EArgumentNilException.Create('AObtenerModulo');
  FOrigen := AOrigen;
  FObtenerModulo := AObtenerModulo;
end;

function TModeloMantenimientoDatasets.ConsultarEstado:
  TEstadoMantenimiento;
begin
  Result := Default(TEstadoMantenimiento);
  Result.Modo := mmInactivo;
  Result.EstaVacio := True;
  if Assigned(FOrigen.DataSet) and FOrigen.DataSet.Active then
  begin
    Result.EstaVacio := FOrigen.DataSet.IsEmpty;
    case FOrigen.State of
      dsBrowse:
        Result.Modo := mmConsulta;
      dsInsert:
        Result.Modo := mmAlta;
      dsEdit:
        Result.Modo := mmModificacion;
    else
      Result.Modo := mmOtro;
    end;
  end;
end;

function TModeloMantenimientoDatasets.HayCambiosPendientes: Boolean;
var
  oModulo: TDataModule;
begin
  Result := DataSetTieneCambiosPendientes(FOrigen.DataSet);
  if not Result then
  begin
    oModulo := FObtenerModulo();
    if Assigned(oModulo) then
      Result := CheckOpenDatasets(oModulo, True);
  end;
end;

procedure TModeloMantenimientoDatasets.Editar;
begin
  FOrigen.DataSet.Edit;
end;

procedure TModeloMantenimientoDatasets.Eliminar;
begin
  FOrigen.DataSet.Delete;
end;

procedure TModeloMantenimientoDatasets.Refrescar;
begin
  FOrigen.DataSet.Refresh;
end;

procedure TModeloMantenimientoDatasets.Cancelar;
begin
  CancelarDatasets(FObtenerModulo(), FOrigen.DataSet);
end;

end.
