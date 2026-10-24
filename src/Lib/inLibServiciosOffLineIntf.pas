{******************************************************************************}
{                                                                              }
{  Módulo:       inLibServiciosOffLineIntf                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de los servicios off line programados fuera de hora.            }
{******************************************************************************}
unit inLibServiciosOffLineIntf;

interface

type
  TServicioOffLine = (
    soCopiaSeguridad,
    soPreciosMedios
  );
  // Con contraseña la tarea arranca sin sesión y con acceso a la red;
  // S4U también arranca sin sesión, pero sin credenciales de red y solo
  // se puede registrar desde un proceso elevado.
  TModoAccesoServicioOffLine = (
    masContrasena,
    masS4U
  );
  // Datos de la instalación que ejecutará la tarea programada.
  TEntornoServiciosOffLine = record
    RutaEjecutable: string;
    PerfilIni: string;
    Usuario: string;
    CarpetaCopiasPredeterminada: string;
  end;
  TCredencialServiciosOffLine = record
    Usuario: string;
    Contrasena: string;
  end;
  TConfiguracionServicioOffLine = record
    Servicio: TServicioOffLine;
    Hora: Integer;
    Minuto: Integer;
    Carpeta: string;
    NombreFichero: string;
  end;
  TEstadoServicioOffLine = record
    Existe: Boolean;
    Habilitada: Boolean;
    EsDeEstaInstalacion: Boolean;
    RequiereSesionIniciada: Boolean;
    Configuracion: TConfiguracionServicioOffLine;
    Cuenta: string;
    Ejecutable: string;
    Sentencia: string;
    ProximaEjecucion: string;
    Error: string;
  end;
  TResultadoServicioOffLine = record
    Ok: Boolean;
    Mensaje: string;
  end;
  IProgramadorServiciosOffLine = interface
    ['{2E0C7F41-6E1D-4C63-9B4C-1A5B0D7E9C31}']
    function Consultar(
      AServicio: TServicioOffLine;
      const AEntorno: TEntornoServiciosOffLine
    ): TEstadoServicioOffLine;
    function Instalar(
      const AConfiguracion: TConfiguracionServicioOffLine;
      const AEntorno: TEntornoServiciosOffLine;
      const ACredencial: TCredencialServiciosOffLine
    ): TResultadoServicioOffLine;
    function Desinstalar(
      AServicio: TServicioOffLine;
      const AEntorno: TEntornoServiciosOffLine
    ): TResultadoServicioOffLine;
  end;

implementation

end.
