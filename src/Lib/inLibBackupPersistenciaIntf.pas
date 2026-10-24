{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBackupPersistenciaIntf                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos mínimos de persistencia para crear y restaurar copias.          }
{******************************************************************************}
unit inLibBackupPersistenciaIntf;

interface

uses
  Core_Interfaces, Backup.Types;

type
  IPersistenciaCopiaBackup = interface
    ['{C91CB83F-0B7C-41F8-A1DA-2EF04B85BCE2}']
    procedure Preparar;
    function ObtenerServiciosLectura: TServiciosLecturaBBDD;
    function ObtenerServiciosSql: TServiciosSqlBBDD;
    function ObtenerFiltroTraducciones: string;
  end;

  IPersistenciaRestauracionBackup = interface
    ['{DD7F4D01-76A4-4692-A517-6A0B75156504}']
    // El DDL de MariaDB puede confirmar implícitamente: no hay rollback.
    procedure PrepararDestino;
    procedure EjecutarSentencia(const ASentencia: string);
    procedure NormalizarBaseDatos;
    function ObtenerTablasConColacionNoValida: TArray<string>;
    procedure NormalizarTabla(const ANombreTabla: string);
    procedure ValidarEstructura;
  end;

  IFabricaPersistenciaBackup = interface
    ['{58E89EB2-6A75-4675-8072-05911F527DA7}']
    function CrearCopia(
      const AConfiguracion: TConfiguracionConexionBackup):
      IPersistenciaCopiaBackup;
    function CrearRestauracion(
      const AConfiguracion: TConfiguracionConexionBackup):
      IPersistenciaRestauracionBackup;
  end;

implementation

end.
