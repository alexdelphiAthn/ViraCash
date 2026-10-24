{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTrazabilidadAlta                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    FZ-ISSUE-304: trazabilidad obligatoria de los artículos nuevos según      }
{    la familia, sin parámetros de alta ni valores del proveedor.             }
{******************************************************************************}
unit inLibTrazabilidadAlta;

interface

uses
  inLibTrazabilidad;

const
  TRAZABILIDAD_FAMILIA_NINGUNA = 'NINGUNA';
  TRAZABILIDAD_FAMILIA_LOTE = 'LOTE';
  TRAZABILIDAD_FAMILIA_LOTE_CADUCIDAD = 'LOTE_CADUCIDAD';
  TRAZABILIDAD_FAMILIA_SERIE = 'SERIE';

type
  TTrazabilidadAlta = record
    Modo: TModoTrazabilidad;
    ExigeCaducidad: Boolean;
    function ValorModo: string;
    function ValorCaducidad: string;
    function ValorEsTrazable: string;
    function Coincide(const AModo: string; ACaducidad: Boolean): Boolean;
  end;

// Vacío o NULL en la familia equivale a sin trazabilidad.
function TrazabilidadAltaFamilia(
  const ATipoFamilia: string): TTrazabilidadAlta;

// La caducidad depende de lotes.
function TiposTrazabilidadFamiliaDisponibles(
  const AActivacion: TActivacionTrazabilidad): TArray<string>;

implementation

uses
  System.SysUtils, inLibMsgTrazabilidad;

function TiposTrazabilidadFamiliaDisponibles(
  const AActivacion: TActivacionTrazabilidad): TArray<string>;
var
  iTipos: Integer;
begin
  SetLength(Result, 4);
  Result[0] := TRAZABILIDAD_FAMILIA_NINGUNA;
  iTipos := 1;
  if AActivacion.Lotes then
  begin
    Result[iTipos] := TRAZABILIDAD_FAMILIA_LOTE;
    Inc(iTipos);
    Result[iTipos] := TRAZABILIDAD_FAMILIA_LOTE_CADUCIDAD;
    Inc(iTipos);
  end;
  if AActivacion.Series then
  begin
    Result[iTipos] := TRAZABILIDAD_FAMILIA_SERIE;
    Inc(iTipos);
  end;
  SetLength(Result, iTipos);
end;

function TTrazabilidadAlta.ValorModo: string;
begin
  Result := ModoACadena(Modo);
end;

function TTrazabilidadAlta.ValorCaducidad: string;
begin
  if ExigeCaducidad then
    Result := 'S'
  else
    Result := 'N';
end;

function TTrazabilidadAlta.ValorEsTrazable: string;
begin
  Result := inLibTrazabilidad.ValorEsTrazable(Modo);
end;

function TTrazabilidadAlta.Coincide(const AModo: string;
  ACaducidad: Boolean): Boolean;
begin
  Result := SameText(Trim(AModo), ValorModo) and
    (ACaducidad = ExigeCaducidad);
end;

function TrazabilidadAltaFamilia(
  const ATipoFamilia: string): TTrazabilidadAlta;
var
  sTipo: string;
begin
  Result := Default(TTrazabilidadAlta);
  Result.Modo := mtNinguna;
  sTipo := UpperCase(Trim(ATipoFamilia));
  if (sTipo = TRAZABILIDAD_FAMILIA_LOTE) or
     (sTipo = TRAZABILIDAD_FAMILIA_LOTE_CADUCIDAD) then
    Result.Modo := mtLote
  else if sTipo = TRAZABILIDAD_FAMILIA_SERIE then
    Result.Modo := mtSerie
  else if (sTipo <> '') and (sTipo <> TRAZABILIDAD_FAMILIA_NINGUNA) then
    raise EArgumentException.CreateFmt(SErrorTrazabilidadFamiliaInvalida,
      [ATipoFamilia]);
  Result.ExigeCaducidad := sTipo = TRAZABILIDAD_FAMILIA_LOTE_CADUCIDAD;
end;

end.
