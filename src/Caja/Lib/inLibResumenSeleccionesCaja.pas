{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResumenSeleccionesCaja                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Describe en el resumen de selecciones las ubicaciones (empresa / almacén  }
{    / caja) que de verdad consulta un listado de caja.                        }
{******************************************************************************}
unit inLibResumenSeleccionesCaja;

interface

uses
  inLibInformesCajaPersistenciaIntf, inLibResumenSeleccionesInforme;

// Cada ubicación como "empresa/almacén/caja" (códigos).
procedure AnadirUbicacionesInformeCaja(
  AResumen: TResumenSeleccionesInforme;
  const AEtiqueta: string;
  const AUbicaciones: TUbicacionesInformeCaja);

implementation

uses
  System.Classes, System.SysUtils;

procedure AnadirUbicacionesInformeCaja(
  AResumen: TResumenSeleccionesInforme;
  const AEtiqueta: string;
  const AUbicaciones: TUbicacionesInformeCaja);
var
  oTextos: TStringList;
  oUbicacion: TUbicacionInformeCaja;
begin
  oTextos := TStringList.Create;
  try
    for oUbicacion in AUbicaciones do
      oTextos.Add(
        oUbicacion.Empresa + '/' + oUbicacion.Almacen + '/' +
        oUbicacion.Caja);
    AResumen.AnadirLista(AEtiqueta, oTextos);
  finally
    FreeAndNil(oTextos);
  end;
end;

end.
