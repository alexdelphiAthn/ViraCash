{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTarifasCambiosPeriodos                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reglas de los periodos (etapas de rebajas) de una sesión de cambio de     }
{    tarifa: fechas válidas, sin solapes entre periodos de la misma sesión,    }
{    y fechas propuestas para un periodo nuevo (FZ-ISSUE-944). No conoce       }
{    formularios ni UniDAC.                                                    }
{******************************************************************************}
unit inLibTarifasCambiosPeriodos;

interface

type
  // Parámetros de cálculo de una sesión sin periodos o de un periodo.
  TParametrosCalculoTarifa = record
    CampoOrigen: string;
    CampoDestino: string;
    TipoAplicacion: string;
    ValorAplicacion: Double;
    ValorRedondeo: Double;
    ValorMenos: Double;
    EsRedondearArriba: Boolean;
  end;

  TVigenciaPeriodoTarifa = record
    Id: Integer;
    Numero: Integer;
    Desde: TDateTime;
    Hasta: TDateTime;
  end;
  TVigenciasPeriodoTarifa = TArray<TVigenciaPeriodoTarifa>;

const
  // Duración propuesta para un periodo nuevo; el usuario la cambia en la
  // rejilla.
  DIAS_PERIODO_TARIFA_PROPUESTO = 14;

// Dos periodos se solapan si comparten algún día (fechas inclusivas).
function PeriodosTarifaSeSolapan(
  const A, B: TVigenciaPeriodoTarifa): Boolean;

// '' si APeriodo tiene fechas válidas y no se solapa con ninguno de AOtros.
// Se ignora el de AOtros con el mismo Id (el propio periodo ya grabado).
function ErrorVigenciaPeriodoTarifa(const APeriodo: TVigenciaPeriodoTarifa;
  const AOtros: TVigenciasPeriodoTarifa): string;

// Primer error del conjunto de periodos de una sesión; '' si son válidos.
function ErrorVigenciasPeriodosTarifa(
  const APeriodos: TVigenciasPeriodoTarifa): string;

// Periodo nuevo: el número siguiente y las fechas a continuación del último.
// Sin periodos empieza en ADesdeSesion o, si está vacía, en AHoy.
function VigenciaPropuestaPeriodoTarifa(
  const AExistentes: TVigenciasPeriodoTarifa;
  ADesdeSesion, AHoy: TDateTime): TVigenciaPeriodoTarifa;

implementation

uses
  System.SysUtils, System.DateUtils,
  inLibMsgArticulos;

function PeriodosTarifaSeSolapan(
  const A, B: TVigenciaPeriodoTarifa): Boolean;
begin
  Result := (DateOf(A.Desde) <= DateOf(B.Hasta)) and
    (DateOf(B.Desde) <= DateOf(A.Hasta));
end;

function ErrorFechasPeriodoTarifa(
  const APeriodo: TVigenciaPeriodoTarifa): string;
begin
  Result := '';
  if (APeriodo.Desde = 0) or (APeriodo.Hasta = 0) then
    Result := Format(SErrorPeriodoTarifaSinFechas, [APeriodo.Numero])
  else if DateOf(APeriodo.Hasta) < DateOf(APeriodo.Desde) then
    Result := Format(SErrorPeriodoTarifaFechasInvertidas,
      [APeriodo.Numero, DateToStr(APeriodo.Hasta),
       DateToStr(APeriodo.Desde)]);
end;

function ErrorVigenciaPeriodoTarifa(const APeriodo: TVigenciaPeriodoTarifa;
  const AOtros: TVigenciasPeriodoTarifa): string;
var
  Otro: TVigenciaPeriodoTarifa;
begin
  Result := ErrorFechasPeriodoTarifa(APeriodo);
  for Otro in AOtros do
    if (Result = '') and (Otro.Id <> APeriodo.Id) and
       (ErrorFechasPeriodoTarifa(Otro) = '') and
       PeriodosTarifaSeSolapan(APeriodo, Otro) then
      Result := Format(SErrorPeriodoTarifaSolapado,
        [APeriodo.Numero, DateToStr(APeriodo.Desde),
         DateToStr(APeriodo.Hasta), Otro.Numero, DateToStr(Otro.Desde),
         DateToStr(Otro.Hasta)]);
end;

function ErrorVigenciasPeriodosTarifa(
  const APeriodos: TVigenciasPeriodoTarifa): string;
var
  Periodo: TVigenciaPeriodoTarifa;
begin
  Result := '';
  for Periodo in APeriodos do
    if Result = '' then
      Result := ErrorVigenciaPeriodoTarifa(Periodo, APeriodos);
end;

function VigenciaPropuestaPeriodoTarifa(
  const AExistentes: TVigenciasPeriodoTarifa;
  ADesdeSesion, AHoy: TDateTime): TVigenciaPeriodoTarifa;
var
  Periodo: TVigenciaPeriodoTarifa;
  UltimoHasta: TDateTime;
begin
  Result := Default(TVigenciaPeriodoTarifa);
  Result.Numero := 1;
  UltimoHasta := 0;
  for Periodo in AExistentes do
  begin
    if Periodo.Numero >= Result.Numero then
      Result.Numero := Periodo.Numero + 1;
    if DateOf(Periodo.Hasta) > UltimoHasta then
      UltimoHasta := DateOf(Periodo.Hasta);
  end;
  if UltimoHasta > 0 then
    Result.Desde := IncDay(UltimoHasta, 1)
  else if ADesdeSesion > 0 then
    Result.Desde := DateOf(ADesdeSesion)
  else
    Result.Desde := DateOf(AHoy);
  Result.Hasta := IncDay(Result.Desde, DIAS_PERIODO_TARIFA_PROPUESTO - 1);
end;

end.
