{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataValidacionDocumentoRepositorio                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC para las lecturas de validación de documentos.           }
{******************************************************************************}
unit UniDataValidacionDocumentoRepositorio;

interface

uses
  Uni, inLibValidacionDocumentoLecturasIntf;

function CrearValidacionDocumentoLecturas(
  AConexion: TUniConnection): IValidacionDocumentoLecturas;

implementation

uses
  System.SysUtils, inLibDocumentoIntf;

type
  TValidacionDocumentoLecturas = class(
    TInterfacedObject,
    IValidacionDocumentoLecturas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarArticulosSinSistemaTallas(
      const AConfiguracion: TConfiguracionDocumento;
      const ASerie, ANumero: string): TArray<string>;
  end;

function CrearValidacionDocumentoLecturas(
  AConexion: TUniConnection): IValidacionDocumentoLecturas;
begin
  Result := nil;
  if Assigned(AConexion) then
    Result := TValidacionDocumentoLecturas.Create(AConexion);
end;

constructor TValidacionDocumentoLecturas.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TValidacionDocumentoLecturas.ListarArticulosSinSistemaTallas(
  const AConfiguracion: TConfiguracionDocumento;
  const ASerie, ANumero: string): TArray<string>;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT L.' + AConfiguracion.CampoArticuloLinea +
      ' AS ART ' +
      '  FROM ' + AConfiguracion.TablaLineas + ' L ' +
      ' WHERE L.' + AConfiguracion.CampoSerieLinea + ' = :serie ' +
      '   AND L.' + AConfiguracion.CampoNumeroLinea + ' = :numero ' +
      '   AND COALESCE(TRIM(L.' +
      AConfiguracion.CampoArticuloLinea + '), '''') <> '''' ' +
      '   AND (L.' + AConfiguracion.CampoPivoteLinea + ' IS NULL ' +
      '        OR L.' + AConfiguracion.CampoPivoteLinea + ' = 0) ' +
      ' ORDER BY ART';
    oConsulta.ParamByName('serie').AsString := ASerie;
    oConsulta.ParamByName('numero').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice] := oConsulta.FieldByName('ART').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
