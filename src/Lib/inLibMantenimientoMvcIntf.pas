{******************************************************************************}
{                                                                              }
{  Módulo: inLibMantenimientoMvcIntf                                           }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 14/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Contratos MVC del mantenimiento.                               }
{                                                                              }
{******************************************************************************}

unit inLibMantenimientoMvcIntf;

interface

uses
  inLibPermisosIntf;

type
  TModoMantenimiento = (
    mmInactivo, mmConsulta, mmAlta, mmModificacion, mmOtro);

  TEstadoMantenimiento = record
    Modo: TModoMantenimiento;
    EstaVacio: Boolean;
  end;

  TDecisionCierreMantenimiento = (dcGuardar, dcDescartar, dcCancelar);

  IModeloMantenimiento = interface
    ['{7D3BC1A8-B243-4457-A82E-C1D130294EDB}']
    function ConsultarEstado: TEstadoMantenimiento;
    function HayCambiosPendientes: Boolean;
    procedure Editar;
    procedure Eliminar;
    procedure Refrescar;
    procedure Cancelar;
  end;

  TPermitirAccionMantenimiento = function(
    AAccion: TAccionPermisoMto): Boolean of object;
  TConfirmarCierreMantenimiento = function:
    TDecisionCierreMantenimiento of object;
  TGuardarMantenimiento = procedure of object;

  // La vista posee el controlador y vive más que estos callbacks.
  TInteraccionMantenimiento = record
    PermitirAccion: TPermitirAccionMantenimiento;
    ConfirmarCierre: TConfirmarCierreMantenimiento;
    Guardar: TGuardarMantenimiento;
  end;

implementation

end.
