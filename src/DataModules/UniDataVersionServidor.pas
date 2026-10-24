{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVersionServidor                                        }
{    Tipo:       Consulta UniDAC                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Versión del servidor de la base de datos (SELECT VERSION()), para         }
{    contrastarla con el parámetro appMotorBaseDatos antes de actualizar.      }
{******************************************************************************}
unit UniDataVersionServidor;

interface

uses
  Uni;

function ConsultarVersionServidorUniDAC(AConexion: TUniConnection): string;

implementation

uses
  System.SysUtils;

function ConsultarVersionServidorUniDAC(AConexion: TUniConnection): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT VERSION() AS VERSION_SERVIDOR';
    oConsulta.Open;
    if not oConsulta.Eof then
      Result := Trim(oConsulta.FieldByName('VERSION_SERVIDOR').AsString);
  finally
    oConsulta.Free;
  end;
end;

end.
