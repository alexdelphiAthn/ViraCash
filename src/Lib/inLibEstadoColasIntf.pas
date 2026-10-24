{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEstadoColasIntf                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Instantáneas de actividad de las colas, sin dependencias visuales.        }
{******************************************************************************}
unit inLibEstadoColasIntf;

interface

const
  cParametroColasHorasIncidencias = 'appColasHorasIncidencias';
  cHorasIncidenciasColasDefecto = 48;

type
  TTipoColaEstado = (tceWs, tceHacienda, tcePrestaShop);
  TActividadCola = (acCorrecta, acOcupada, acIncidencia);
  TEstadoCola = record
    Activa: Boolean;
    Actividad: TActividadCola;
    Instante: TDateTime;
    HorasIncidencias: Integer;
    UltimoEvento: string;
    Incidencia: string;
  end;
  TEstadosColas = array[TTipoColaEstado] of TEstadoCola;
  TConsultarEstadosColas = reference to function: TEstadosColas;

  IEstadoCola = interface
    ['{B1AE696E-0939-48FD-A05A-00B80FA62D8A}']
    procedure IniciarCiclo;
    procedure Publicar(AActividad: TActividadCola; const AEvento: string);
    procedure FinalizarCiclo(const AIncidenciaPendiente: string;
      AHorasIncidencias: Integer = cHorasIncidenciasColasDefecto);
    function Leer: TEstadoCola;
  end;

implementation

end.
