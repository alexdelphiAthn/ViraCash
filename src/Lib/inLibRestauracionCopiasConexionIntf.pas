{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRestauracionCopiasConexionIntf                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de restauración para la configuración previa al acceso.         }
{******************************************************************************}
unit inLibRestauracionCopiasConexionIntf;

interface

uses
  System.Classes,
  inLibCopiasSeguridadIntf;

type
  TSolicitudRestauracionConexion = record
    Host: string;
    Puerto: Integer;
    BaseDatos: string;
    Usuario: string;
    ContrasenaConexion: string;
    RutaFichero: string;
    ContrasenaCopia: string;
    AdministradorAutenticado: Boolean;
  end;
  TPrepararWorkerRestauracionEvent = procedure(
    AWorker: TThread) of object;
  IRepositorioRestauracionConexion = interface
    ['{EA952E10-9CDB-41E9-81E2-A68A4B6DBA05}']
    procedure Iniciar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
  end;
  ICasoUsoRestauracionConexion = interface
    ['{9B6E835C-C32E-471E-8B7C-93CAC7886D8D}']
    procedure Ejecutar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
  end;

implementation

end.
