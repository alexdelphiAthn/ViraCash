{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResolucionSku                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Regla única para elegir el SKU de una celda (artículo, fila y talla)      }
{    entre los candidatos que devuelve la BBDD (tercera dimensión, fase 2).    }
{    Si el tipo de variación tiene pestañas (copa) y encajan varios SKU,       }
{    la celda es ambigua y no se elige ninguno: nunca una copa cualquiera.     }
{******************************************************************************}
unit inLibResolucionSku;

interface

uses
  inLibErroresBBDD;

type
  // Un SKU que encaja con los atributos pedidos. TienePestanas indica que
  // su tipo de variación tiene eje de pestañas (VI_VARIACIONES_EJES 'S').
  TCandidatoSku = record
    Sku: string;
    TienePestanas: Boolean;
  end;
  TCandidatosSku = TArray<TCandidatoSku>;

  TEstadoResolucionSku = (ersNoEncontrado, ersEncontrado, ersAmbiguo);

  TResolucionSku = record
    Estado: TEstadoResolucionSku;
    // SKU elegido; vacío si no hay o es ambiguo.
    Sku: string;
    // Con ersAmbiguo, los dos primeros candidatos para el aviso.
    Candidatos: TArray<string>;
  end;

  // Celda que encaja con varios SKU de un tipo con pestañas: falta el
  // valor de las pestañas (la copa). Se muestra como aviso de validación.
  ESkuAmbiguo = class(EValidacionBBDD);
  // Alta de un SKU de un tipo con pestañas sin el valor de las pestañas.
  ESkuSinValorPestana = class(EValidacionBBDD);

const
  // Las consultas de candidatos piden dos filas: basta para saber si hay
  // más de una.
  MAX_CANDIDATOS_SKU = 2;

// Sin candidatos: no encontrado. Uno: ese. Varios: ambiguo si alguno es
// de un tipo con pestañas; si no, el primero, como antes de la tercera
// dimensión (duplicados heredados de «Tallas y colores»).
function ResolverCandidatosSku(
  const ACandidatos: TCandidatosSku): TResolucionSku;
// Devuelve el SKU elegido o lanza ESkuAmbiguo con el artículo.
function SkuResueltoOError(const AResolucion: TResolucionSku;
  const AArticulo: string): string;
// Lanza ESkuSinValorPestana si el tipo tiene pestañas y falta su valor.
procedure ComprobarValorPestanaAlta(ATienePestanas: Boolean;
  AIdValorPestana: Integer; const ASku: string);

implementation

uses
  System.SysUtils,
  inLibMsgArticulos;

function ResolverCandidatosSku(
  const ACandidatos: TCandidatosSku): TResolucionSku;
var
  oCandidato: TCandidatoSku;
  bConPestanas: Boolean;
begin
  Result := Default(TResolucionSku);
  bConPestanas := False;
  for oCandidato in ACandidatos do
    bConPestanas := bConPestanas or oCandidato.TienePestanas;
  if Length(ACandidatos) = 0 then
    Result.Estado := ersNoEncontrado
  else if (Length(ACandidatos) > 1) and bConPestanas then
  begin
    Result.Estado := ersAmbiguo;
    Result.Candidatos := [ACandidatos[0].Sku, ACandidatos[1].Sku];
  end
  else
  begin
    Result.Estado := ersEncontrado;
    Result.Sku := ACandidatos[0].Sku;
  end;
end;

function SkuResueltoOError(const AResolucion: TResolucionSku;
  const AArticulo: string): string;
begin
  if AResolucion.Estado = ersAmbiguo then
    raise ESkuAmbiguo.CreateFmt(SErrorSkuAmbiguoPestanas,
      [AArticulo, AResolucion.Candidatos[0], AResolucion.Candidatos[1]]);
  Result := AResolucion.Sku;
end;

procedure ComprobarValorPestanaAlta(ATienePestanas: Boolean;
  AIdValorPestana: Integer; const ASku: string);
begin
  if ATienePestanas and (AIdValorPestana <= 0) then
    raise ESkuSinValorPestana.CreateFmt(SErrorSkuSinValorPestana, [ASku]);
end;

end.
