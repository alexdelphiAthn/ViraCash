{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesEvidencias                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit inLibReparacionesEvidencias;

interface

type
  TEvidenciaReparacion = record
    Nombre: string;
    Fase: string;
    Comentario: string;
    Instante: string;
    Archivo: string;
  end;

function LeerEvidenciasReparacion(const ACarpeta: string):
  TArray<TEvidenciaReparacion>;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON,
  System.Generics.Collections, System.Generics.Defaults;

function LeerEvidencia(const ARuta, ACarpeta: string): TEvidenciaReparacion;
var
  oJson: TJSONValue;
  oDatos: TJSONObject;
begin
  Result := Default(TEvidenciaReparacion);
  oJson := TJSONObject.ParseJSONValue(TFile.ReadAllText(ARuta,
    TEncoding.UTF8));
  try
    if not Assigned(oJson) then
      raise EArgumentException.Create('Recibo de evidencia inválido.');
    oDatos := oJson.GetValue<TJSONObject>('datos');
    Result.Nombre := oDatos.GetValue<string>('nombre');
    Result.Fase := oDatos.GetValue<string>('fase');
    Result.Comentario := oDatos.GetValue<string>('comentario', '');
    Result.Instante := oDatos.GetValue<string>('recibida_utc');
    if not oDatos.GetValue<Boolean>('solo_comentario', False) then
    begin
      if (ExtractFileName(Result.Nombre) <> Result.Nombre) or
         (Pos('..', Result.Nombre) > 0) or (Pos(':', Result.Nombre) > 0) then
        raise EArgumentException.Create('Nombre de evidencia inválido.');
      Result.Archivo := TPath.Combine(ACarpeta, Result.Nombre + '_real.png');
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function LeerEvidenciasReparacion(const ACarpeta: string):
  TArray<TEvidenciaReparacion>;
var
  sRuta: string;
begin
  Result := nil;
  if TDirectory.Exists(ACarpeta) then
    for sRuta in TDirectory.GetFiles(ACarpeta, 'captura_*.json') do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LeerEvidencia(sRuta, ACarpeta);
    end;
  TArray.Sort<TEvidenciaReparacion>(Result,
    TComparer<TEvidenciaReparacion>.Construct(
      function(const AIzquierda, ADerecha: TEvidenciaReparacion): Integer
      begin
        Result := CompareStr(AIzquierda.Instante + AIzquierda.Nombre,
          ADerecha.Instante + ADerecha.Nombre);
      end));
end;

end.
