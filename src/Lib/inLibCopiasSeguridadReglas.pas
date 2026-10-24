{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCopiasSeguridadReglas                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Política de protección y restauración según el grupo del usuario.         }
{******************************************************************************}
unit inLibCopiasSeguridadReglas;

interface

uses
  inLibCopiasSeguridadIntf;

type
  TPoliticaCopiasSeguridad = class sealed
  public
    class function ModoCreacion(
      AEsAdministrador: Boolean
    ): TModoProteccionCopia; static;
    class function ExtensionCreacion(
      AEsAdministrador: Boolean
    ): string; static;
    class function ExtensionModo(
      AModo: TModoProteccionCopia
    ): string; static;
    class function ModosCreacion(
      AEsAdministrador: Boolean
    ): TModosProteccionCopia; static;
    class function PuedeCrear(
      AEsAdministrador: Boolean;
      AModo: TModoProteccionCopia
    ): Boolean; static;
    class function IntentarObtenerModo(
      const ARutaFichero: string;
      out AModo: TModoProteccionCopia
    ): Boolean; static;
    class function EsCopiaCifrada(
      const ARutaFichero: string
    ): Boolean; static;
    class function PuedeRestaurar(
      AEsAdministrador: Boolean;
      const ARutaFichero: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TPoliticaCopiasSeguridad.ModoCreacion(
  AEsAdministrador: Boolean): TModoProteccionCopia;
begin
  if AEsAdministrador then
    Result := mpcTextoPlano
  else
    Result := mpcCifrada;
end;

class function TPoliticaCopiasSeguridad.ExtensionCreacion(
  AEsAdministrador: Boolean): string;
begin
  Result := ExtensionModo(ModoCreacion(AEsAdministrador));
end;

class function TPoliticaCopiasSeguridad.ExtensionModo(
  AModo: TModoProteccionCopia): string;
begin
  case AModo of
    mpcTextoPlano:
      Result := '.sql';
    mpcZip:
      Result := '.zip';
    mpcCifrada:
      Result := '.crypt';
  end;
end;

class function TPoliticaCopiasSeguridad.ModosCreacion(
  AEsAdministrador: Boolean): TModosProteccionCopia;
begin
  if AEsAdministrador then
  begin
    Result := [mpcTextoPlano, mpcZip, mpcCifrada];
  end
  else
    Result := [mpcCifrada];
end;

class function TPoliticaCopiasSeguridad.PuedeCrear(
  AEsAdministrador: Boolean;
  AModo: TModoProteccionCopia): Boolean;
begin
  Result := AModo in ModosCreacion(AEsAdministrador);
end;

class function TPoliticaCopiasSeguridad.IntentarObtenerModo(
  const ARutaFichero: string;
  out AModo: TModoProteccionCopia): Boolean;
var
  sExtension: string;
begin
  sExtension := ExtractFileExt(ARutaFichero);
  Result := SameText(sExtension, '.sql') or
            SameText(sExtension, '.zip') or
            SameText(sExtension, '.crypt');
  if SameText(sExtension, '.sql') then
    AModo := mpcTextoPlano
  else if SameText(sExtension, '.zip') then
    AModo := mpcZip
  else
    AModo := mpcCifrada;
end;

class function TPoliticaCopiasSeguridad.EsCopiaCifrada(
  const ARutaFichero: string): Boolean;
begin
  Result := SameText(
    ExtractFileExt(ARutaFichero),
    '.crypt');
end;

class function TPoliticaCopiasSeguridad.PuedeRestaurar(
  AEsAdministrador: Boolean;
  const ARutaFichero: string): Boolean;
var
  sExtension: string;
begin
  sExtension := ExtractFileExt(ARutaFichero);
  Result := EsCopiaCifrada(ARutaFichero);
  if AEsAdministrador and
     (SameText(sExtension, '.sql') or
      SameText(sExtension, '.zip')) then
    Result := True;
end;

end.
