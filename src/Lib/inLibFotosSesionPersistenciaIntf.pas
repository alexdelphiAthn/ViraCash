{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosSesionPersistenciaIntf                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia para fotografías temporales de sesiones.          }
{******************************************************************************}
unit inLibFotosSesionPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TMetadatosFotoSesion = record
    CodigoArticuloTentativo: string;
    CodigoUnidad: string;
    Nombre: string;
    Extension: string;
  end;
  TMetadatosFotoSesionLote = record
    Linea: Integer;
    CodigoArticuloTentativo: string;
    CodigoUnidad: string;
    Nombre: string;
    Extension: string;
  end;
  TMetadatosFotosSesionLote = TArray<TMetadatosFotoSesionLote>;
  IRepositorioSesionFotos = interface
    ['{9639253C-FB16-4B89-AE95-9B90C33DA476}']
    function BuscarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoSesion): Boolean;
    procedure GuardarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
        AExtension, AUsuario: string);
    procedure GuardarFotosSesionLote(
      const ASerieSesion, ANumeroSesion: string;
      const AMetadatos: TMetadatosFotosSesionLote;
      const AUsuario: string);
    procedure EliminarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string);
    function BuscarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer): TArray<TMetadatosFotoSesion>;
    procedure GuardarFotoMigrada(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
        AUsuario: string);
    procedure EliminarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer);
  end;

implementation

end.
