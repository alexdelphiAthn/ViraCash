{******************************************************************************}
{                                                                              }
{  Módulo:       inLibOperacionesAplicacionIntf                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos del coordinador de operaciones largas y su presentación.       }
{******************************************************************************}
unit inLibOperacionesAplicacionIntf;

interface

uses
  System.Classes,
  inLibCopiasSeguridadIntf;

type
  TTipoOperacionAplicacion = (
    toaCopiaSeguridad,
    toaRestauracion
  );
  IPresentacionOperacionesAplicacion = interface
    ['{F5BA7B56-C5B6-4DB5-B217-05027A18A01A}']
    procedure MostrarOperacion;
    procedure ActualizarProgreso(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure MostrarCancelando;
    procedure FinalizarOperacion(
      ATipo: TTipoOperacionAplicacion;
      AResultado: TResultadoCopiaSeguridad;
      const AError: string;
      ALogBuffer: TStringList);
  end;
  ICasoUsoCopiasSeguridad = interface
    ['{180674F0-5585-45F4-B285-7050C5F0CFE5}']
    function EnCurso: Boolean;
    function ModoCreacionCopia: TModoProteccionCopia;
    function ExtensionCreacionCopia: string;
    function PuedeRestaurar(const ARutaFichero: string): Boolean;
    function RequiereContrasena(const ARutaFichero: string): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string);
    function CrearCopia(
      const ARutaFichero, AContrasena: string): Boolean;
    function CancelacionSolicitada: Boolean;
    function SolicitarCancelacion: Boolean;
  end;
  ICoordinadorOperacionesAplicacion = ICasoUsoCopiasSeguridad;

implementation

end.
