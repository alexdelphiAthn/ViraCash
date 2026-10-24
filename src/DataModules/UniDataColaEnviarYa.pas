{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataColaEnviarYa                                           }
{    Tipo:       Librería (UniDAC)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Ejecuta el «Enviar ya» de una cola (FZ-ISSUE-310) con la sentencia de     }
{    inLibColaEnviarYa. Devuelve las filas que se han reactivado.              }
{******************************************************************************}
unit UniDataColaEnviarYa;

interface

uses
  Uni, inLibColaEnviarYa;

function EjecutarEnviarYaCola(AConexion: TUniConnection;
  const ADefinicion: TDefinicionColaEnviarYa; const AIds: TArray<Int64>;
  AMaxIntentos: Integer; const AUsuario: string): Integer;

implementation

uses
  System.SysUtils;

function EjecutarEnviarYaCola(AConexion: TUniConnection;
  const ADefinicion: TDefinicionColaEnviarYa; const AIds: TArray<Int64>;
  AMaxIntentos: Integer; const AUsuario: string): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  if Length(AIds) > 0 then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConexion;
      Qry.SQL.Text := SqlEnviarYa(ADefinicion, AIds);
      Qry.ParamByName('MAXINTENTOS').AsInteger := AMaxIntentos;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
      Qry.Execute;
      Result := Qry.RowsAffected;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

end.
