{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEfectosCalculo                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                               }
{    Cálculo puro compartido para validar y referenciar fusiones de efectos.  }
{******************************************************************************}
unit inLibEfectosCalculo;

interface

type
  TResumenFusionEfectos = record
    CantidadValidos: Integer;
    CantidadEmpresas: Integer;
    CantidadTerceros: Integer;
    ImportePendiente: Double;
  end;
  TEstadoFusionEfectos = (
    efeValida,
    efeCantidadInvalida,
    efeOrigenInvalido,
    efeSinImportePendiente
  );
  TCalculoFusionEfectos = class
  public
    class function Validar(
      const AResumen: TResumenFusionEfectos;
      ACantidadEsperada: Integer): TEstadoFusionEfectos; static;
    class function CrearReferencia(
      const ASerie, ANumero: string;
      ANumeroEfecto: Integer): string; static;
  end;

implementation

uses
  System.SysUtils;

class function TCalculoFusionEfectos.Validar(
  const AResumen: TResumenFusionEfectos;
  ACantidadEsperada: Integer): TEstadoFusionEfectos;
begin
  Result := efeValida;
  if AResumen.CantidadValidos <> ACantidadEsperada then
    Result := efeCantidadInvalida
  else if (AResumen.CantidadEmpresas <> 1) or
          (AResumen.CantidadTerceros <> 1) then
    Result := efeOrigenInvalido
  else if AResumen.ImportePendiente <= 0.0001 then
    Result := efeSinImportePendiente;
end;

class function TCalculoFusionEfectos.CrearReferencia(
  const ASerie, ANumero: string;
  ANumeroEfecto: Integer): string;
begin
  Result := Format(
    'CONC %s/%s/%d',
    [ASerie, ANumero, ANumeroEfecto]);
end;

end.
