{******************************************************************************}
{                                                                              }
{  Módulo:       inLibNet                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de red.                                                        }
{    Formateo remoto de SQL mediante el servicio sqlformat.org.                }
{******************************************************************************}
unit inLibNet;

interface

function FormatSqlOnlineSqlformatOrg(sSQL: String): String;

implementation

uses  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
      System.Classes, System.Math, Vcl.Graphics,
      Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  IdHTTP, IdSSLOpenSSL, System.JSON, inLibMsgIntegraciones;

function FormatSqlOnlineSqlformatOrg(sSQL: String): String;
var
  HttpReq: TIdHTTP;
  SSLio: TIdSSLIOHandlerSocketOpenSSL;
  Parameters: TStringList;
  JsonResponseStr: String;
  JsonTmp: TJSONValue;
  sOs, sUserAgent:String;
begin
  HttpReq := TIdHTTP.Create;
  SSLio := TIdSSLIOHandlerSocketOpenSSL.Create;
  Parameters := TStringList.Create;
  JsonTmp := nil;
  try
    HttpReq.IOHandler := SSLio;
    SSLio.SSLOptions.SSLVersions := [sslvTLSv1_1, sslvTLSv1_2];
    HttpReq.Request.CharSet := 'utf-8';
    sOS := 'Windows NT ' + IntToStr(Win32MajorVersion) + '.' +
                          IntToStr(Win32MinorVersion);
    sUserAgent := 'HeidiSQL' + '/' + '12.3.0.6589' +
                  ' (' + sOS + '; ' + 'heidisql.exe' + ');';
    HttpReq.Request.UserAgent := sUserAgent;
    // Documentación de parámetros: https://sqlformat.org/api/
    Parameters.AddPair('sql', sSQL);
    Parameters.AddPair('reindent', '1');
    Parameters.AddPair('indent_width', '2');
    Parameters.AddPair('keyword_case', 'upper');
    JsonResponseStr := HttpReq.Post('https://sqlformat.org/api/v1/format',
                                    Parameters);
    if JsonResponseStr.IsEmpty then
      raise Exception.Create(SErrorRespuestaFormateadorSqlVacia);
    JsonTmp := TJSONObject.ParseJSONValue(JsonResponseStr);
    if (JsonTmp = nil) or (JsonTmp.FindValue('result') = nil) then
      raise Exception.Create(SErrorRespuestaFormateadorSqlInesperada);
    Result := JsonTmp.FindValue('result').Value;
  finally
    FreeAndNil(JsonTmp);
    FreeAndNil(Parameters);
    FreeAndNil(SSLio);
    FreeAndNil(HttpReq);
  end;
end;

end.
