{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPerfilesMtoPersistenciaIntf                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de persistencia para los perfiles de mantenimientos.            }
{******************************************************************************}
unit inLibPerfilesMtoPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  IPersistenciaPerfilesMto = interface
    ['{D54CB404-A5E1-4EE4-823F-E6C7601CAC24}']
    procedure GuardarAtomico(const AGuardado: TProc);
    procedure AbrirPerfiles(
      const AFormulario, ADataModule: string);
  end;

resourcestring
  SErrorPersistenciaPerfilesNoConfigurada =
    'La persistencia de perfiles no está configurada.';

implementation

end.
