{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDocsProveedor                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas UniDAC auxiliares del listado de documentos de proveedor.        }
{******************************************************************************}
unit UniDataDocsProveedor;

interface

uses
  Uni;

function ListarSeriesDocumentosCompra(
  AConexion: TUniConnection): TArray<string>;

implementation

uses
  System.Generics.Collections, System.SysUtils,
  UniDataDocsProveedorSql;

function ListarSeriesDocumentosCompra(
  AConexion: TUniConnection): TArray<string>;
var
  oConsulta: TUniQuery;
  oSeries: TList<string>;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  oSeries := TList<string>.Create;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SqlSeriesDocumentosCompra;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oSeries.Add(oConsulta.FieldByName('COD').AsString);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    Result := oSeries.ToArray;
  finally
    FreeAndNil(oSeries);
  end;
end;

end.
