{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFotosRepositorio                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone los adaptadores UniDAC segregados del subsistema de fotos.        }
{******************************************************************************}
unit UniDataFotosRepositorio;

interface

uses
  Uni, inLibFotosPersistenciaIntf;

function CrearRepositorioFotosUniDAC(
  AConexion: TUniConnection): TRepositoriosFotos;

implementation

uses
  UniDataFotosConsultaRepositorio,
  UniDataFotosEdicionRepositorio,
  UniDataFotosSesionRepositorio;

function CrearRepositorioFotosUniDAC(
  AConexion: TUniConnection): TRepositoriosFotos;
begin
  Result := Default(TRepositoriosFotos);
  Result.Consulta := CrearRepositorioConsultaFotosUniDAC(AConexion);
  Result.Edicion := CrearRepositorioEdicionFotosUniDAC(AConexion);
  Result.Sesion := CrearRepositorioSesionFotosUniDAC(AConexion);
end;

end.
