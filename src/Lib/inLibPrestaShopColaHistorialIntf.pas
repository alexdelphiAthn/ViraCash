{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopColaHistorialIntf                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Contrato append-only del historial HTTP de la cola de PrestaShop.         }
{******************************************************************************}
unit inLibPrestaShopColaHistorialIntf;

interface

uses
  System.SysUtils, inLibColasHistorialIntf;

type
  { El transporte entrega texto ya saneado: sin credenciales, binarios ni
    rutas locales. El adaptador aplica los límites del contrato común. }
  TEventoPrestaShopCola = record
    IdCola: Int64;
    IdReclamacion: string;
    VersionReclamada: Int64;
    NumeroIntento: Integer;
    OrdenOperacion: Integer;
    MetodoHttp: string;
    RecursoHttp: string;
    EstadoHttp: Integer;
    TextoEstado: string;
    Peticion: string;
    Respuesta: string;
    Resultado: TResultadoComunicacionCola;
    Mensaje: string;
    DuracionMs: Int64;
    InstanteInicio: TDateTime;
    InstanteFin: TDateTime;
    Usuario: string;
  end;

  IRegistradorEventosPrestaShopCola = interface
    ['{FEBB6B5A-CB0B-400E-A7D7-DF28B0220545}']
    function IntentarRegistrar(
      const AEvento: TEventoPrestaShopCola;
      out AMensajeError: string): Boolean;
  end;

implementation

end.
