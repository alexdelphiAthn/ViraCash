{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsColaHistorialIntf                                }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Contrato append-only de los intentos HTTP de la cola de ventas WS.        }
{******************************************************************************}
unit inLibVentasWsColaHistorialIntf;

interface

uses
  System.SysUtils, inLibColasHistorialIntf;

type
  { El cliente entrega texto ya saneado: sin credenciales, binarios ni
    rutas locales. El adaptador aplica los límites del contrato común. }
  TIntentoVentasWsCola = record
    IdCola: Int64;
    IdEvento: string;
    NumeroIntento: Integer;
    IdPeticion: string;
    MetodoHttp: string;
    RecursoHttp: string;
    EstadoHttp: Integer;
    Peticion: string;
    Respuesta: string;
    Resultado: TResultadoComunicacionCola;
    Mensaje: string;
    DuracionMs: Int64;
    InstanteInicio: TDateTime;
    InstanteFin: TDateTime;
    Usuario: string;
  end;

  IRegistradorIntentosVentasWsCola = interface
    ['{5C8484BD-4894-4985-91E3-4C3A623F7F90}']
    function IntentarRegistrar(
      const AIntento: TIntentoVentasWsCola;
      out AMensajeError: string): Boolean;
  end;

implementation

end.
