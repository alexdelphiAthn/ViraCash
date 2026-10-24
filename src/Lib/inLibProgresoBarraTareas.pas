{******************************************************************************}
{                                                                              }
{  Módulo:       inLibProgresoBarraTareas                                      }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Progreso en el botón de la barra de tareas de Windows (ITaskbarList3),    }
{    para seguir una operación larga con el programa minimizado.               }
{******************************************************************************}
unit inLibProgresoBarraTareas;

interface

uses
  Winapi.Windows,
  Winapi.ShlObj;

type
  // Todo es opcional: si Windows no ofrece la interfaz, no hace nada.
  // AVentana es la que tiene el botón en la barra de tareas (con
  // MainFormOnTaskbar, el formulario principal).
  TProgresoBarraTareas = class
  private
    FLista: ITaskbarList3;
    FVentana: HWND;
  public
    constructor Create(AVentana: HWND);
    // Barra en marcha sin porcentaje: aún no se sabe cuánto queda.
    procedure Indeterminado;
    procedure Valor(AHecho, ATotal: UInt64);
    procedure Quitar;
  end;

implementation

uses
  Winapi.ActiveX;

constructor TProgresoBarraTareas.Create(AVentana: HWND);
var
  oLista: ITaskbarList3;
begin
  inherited Create;
  FVentana := AVentana;
  if Succeeded(CoCreateInstance(
       CLSID_TaskbarList,
       nil,
       CLSCTX_INPROC_SERVER,
       ITaskbarList3,
       oLista)) and
     Succeeded(oLista.HrInit) then
    FLista := oLista;
end;

procedure TProgresoBarraTareas.Indeterminado;
begin
  if Assigned(FLista) then
    FLista.SetProgressState(FVentana, TBPF_INDETERMINATE);
end;

procedure TProgresoBarraTareas.Valor(AHecho, ATotal: UInt64);
begin
  if Assigned(FLista) and (ATotal > 0) then
  begin
    if AHecho > ATotal then
      AHecho := ATotal;
    FLista.SetProgressState(FVentana, TBPF_NORMAL);
    FLista.SetProgressValue(FVentana, AHecho, ATotal);
  end;
end;

procedure TProgresoBarraTareas.Quitar;
begin
  if Assigned(FLista) then
    FLista.SetProgressState(FVentana, TBPF_NOPROGRESS);
end;

end.
