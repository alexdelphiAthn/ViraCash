{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesDescargaPersistenciaIntf                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de persistencia para instalar traducciones validadas.            }
{******************************************************************************}
unit inLibTraduccionesDescargaPersistenciaIntf;

interface

type
  TProgresoDescargaTraduccion = procedure(
    const ATexto: string;
    APosicion: Integer) of object;

  TScriptInstalacionTraduccion = record
    Nombre: string;
    Contenido: string;
  end;

  IInstaladorTraduccionesPersistencia = interface
    ['{736C4D1B-AB84-46CF-A6A1-DB22A4FFCB7E}']
    procedure ComprobarDisponible;
    function DisponibleLocalmente(const AIdioma: string): Boolean;
    procedure Instalar(
      const AIdioma: string;
      const AScripts: TArray<TScriptInstalacionTraduccion>;
      AProgreso: TProgresoDescargaTraduccion);
  end;

implementation

end.
