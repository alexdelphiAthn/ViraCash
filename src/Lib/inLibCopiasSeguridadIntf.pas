{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCopiasSeguridadIntf                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos para crear y restaurar copias de seguridad.                     }
{******************************************************************************}
unit inLibCopiasSeguridadIntf;

interface

uses
  System.Classes;

type
  TModoProteccionCopia = (
    mpcTextoPlano,
    mpcZip,
    mpcCifrada
  );
  TModosProteccionCopia = set of TModoProteccionCopia;
  TResultadoCopiaSeguridad = (
    rcsCompletada,
    rcsCancelada,
    rcsFallida
  );
  TProgresoCopiaSeguridadEvent = procedure(
    const AEtapa: string;
    APaso, ATotal: Integer;
    AFilaGlobal, AFilasGlobalTotal: Integer
  ) of object;
  TFinalizarCopiaSeguridadEvent = procedure(
    AResultado: TResultadoCopiaSeguridad;
    const AError: string;
    ALogBuffer: TStringList
  ) of object;
  IRepositorioCopiasSeguridad = interface
    ['{690064B6-D994-4687-9A4F-75C6CF917E46}']
    function ModoCreacion: TModoProteccionCopia;
    function ExtensionCreacion: string;
    function PuedeRestaurar(const ARutaFichero: string): Boolean;
    function RequiereContrasena(
      const ARutaFichero: string
    ): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    function CrearCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string
    ): TResultadoCopiaSeguridad;
    function CrearCopiaProtegida(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string
    ): TResultadoCopiaSeguridad;
  end;
  IServicioCopiasSeguridad = IRepositorioCopiasSeguridad;

implementation

end.
