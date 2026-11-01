{******************************************************************************}
{                                                                              }
{  Módulo:       PruebaSincronizacionListas                                    }
{    Tipo:       Programa de consola (prueba)                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ejecuta el sincronizador de listas de regalos de ViraCash (las mismas     }
{    unidades que la pantalla) contra una BBDD y una tienda de laboratorio.   }
{    Lo usa pruebas\e2e_sincronizador_delphi.py.                               }
{    Uso: PruebaSincronizacionListas <puerto> <bbdd> <empresa> <url_api>       }
{         <clave>                                                              }
{******************************************************************************}
program PruebaSincronizacionListas;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Uni,
  MySQLUniProvider,
  inLibListasRegalos,
  inLibListasRegalosPrestaShop,
  inLibListasRegalosSincronizacion,
  UniDataListasRegalosSincronizacion;

function Conectar(APuerto: Integer; const ABBDD: string): TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  Result.ProviderName := 'MySQL';
  Result.Server := '127.0.0.1';
  Result.Port := APuerto;
  Result.Username := 'root';
  Result.Database := ABBDD;
  Result.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
  Result.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
  Result.LoginPrompt := False;
  Result.Connect;
end;

procedure Ejecutar;
var
  oConexion: TUniConnection;
  oSincronizador: TSincronizadorListasRegalos;
  oInforme: TInformeSincronizacionListas;
  sLinea: string;
begin
  oConexion := Conectar(StrToInt(ParamStr(1)), ParamStr(2));
  try
    oSincronizador := TSincronizadorListasRegalos.Create(
      CrearRepositorioSincronizacionListas(oConexion, 'PRUEBA-DELPHI'),
      CrearApiListasRegalos(RaizTiendaPrestaShop(ParamStr(4)), ParamStr(5)));
    try
      oInforme := oSincronizador.Ejecutar(ParamStr(3),
        OrigenListasPrestaShop(ParamStr(4)));
    finally
      oSincronizador.Free;
    end;
    Writeln(Format('PUBLICADAS=%d REGISTRADOS=%d RECHAZADOS=%d',
      [oInforme.Publicadas, oInforme.Registrados, oInforme.Rechazados]));
    for sLinea in oInforme.Detalle do
      Writeln(sLinea);
  finally
    oConexion.Free;
  end;
end;

begin
  try
    if ParamCount <> 5 then
      raise EArgumentException.Create(
        'Uso: PruebaSincronizacionListas <puerto> <bbdd> <empresa> ' +
        '<url_api> <clave>');
    Ejecutar;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
