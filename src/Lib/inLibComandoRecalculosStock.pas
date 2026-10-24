{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComandoRecalculosStock                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reconoce y valida el comando no interactivo de recálculo de stock.        }
{******************************************************************************}
unit inLibComandoRecalculosStock;

interface

uses
  System.SysUtils;

const
  MAXIMO_GRUPOS_RECALCULO_POR_LOTE = 100;
  PAUSA_RECALCULO_MILISEGUNDOS = 100;
  SEGUNDOS_LEASE_RECALCULO = 900;
  SEGUNDOS_REINTENTO_RECALCULO = 300;

type
  TErrorComandoRecalculosStock = (
    ecrsNinguno,
    ecrsSintaxis
  );
  TSolicitudComandoRecalculosStock = record
    EsComando: Boolean;
    EsValida: Boolean;
    Error: TErrorComandoRecalculosStock;
    MaximoGruposPorLote: Integer;
    PausaMilisegundos: Integer;
    SegundosLease: Integer;
    SegundosReintento: Integer;
  end;

function EsComandoRecalculosStock(
  const AParametros: TArray<string>
): Boolean;
function EsSintaxisComandoRecalculosStockValida(
  const AParametros: TArray<string>
): Boolean;
function InterpretarComandoRecalculosStock(
  const AParametros: TArray<string>
): TSolicitudComandoRecalculosStock;

implementation

uses
  inLibLineaComandos;

const
  CONMUTADOR_RECALCULAR_MOVIMIENTOS = '/recalcular_mov';

function EsParametroComandoRecalculosStock(
  const AParametro: string): Boolean;
begin
  Result := SameText(
    Trim(AParametro),
    CONMUTADOR_RECALCULAR_MOVIMIENTOS);
end;

function IndiceComandoRecalculosStock(
  const AParametros: TArray<string>): Integer;
begin
  Result := -1;
  if (Length(AParametros) > 0) and
     EsParametroComandoRecalculosStock(AParametros[0]) then
  begin
    Result := 0;
  end
  else if (Length(AParametros) > 1) and
          EsParametroComandoRecalculosStock(AParametros[1]) then
  begin
    Result := 1;
  end;
end;

function EsComandoRecalculosStock(
  const AParametros: TArray<string>): Boolean;
begin
  Result := IndiceComandoRecalculosStock(AParametros) >= 0;
end;

function EsSintaxisComandoRecalculosStockValida(
  const AParametros: TArray<string>): Boolean;
begin
  Result := (Length(AParametros) = 2) and
            EsParametroPerfilValido(AParametros[0]) and
            EsParametroComandoRecalculosStock(AParametros[1]);
end;

function InterpretarComandoRecalculosStock(
  const AParametros: TArray<string>
): TSolicitudComandoRecalculosStock;
begin
  Result := Default(TSolicitudComandoRecalculosStock);
  Result.EsComando := EsComandoRecalculosStock(AParametros);
  Result.MaximoGruposPorLote := MAXIMO_GRUPOS_RECALCULO_POR_LOTE;
  Result.PausaMilisegundos := PAUSA_RECALCULO_MILISEGUNDOS;
  Result.SegundosLease := SEGUNDOS_LEASE_RECALCULO;
  Result.SegundosReintento := SEGUNDOS_REINTENTO_RECALCULO;
  if Result.EsComando then
  begin
    Result.EsValida :=
      EsSintaxisComandoRecalculosStockValida(AParametros);
    if not Result.EsValida then
      Result.Error := ecrsSintaxis;
  end;
end;

end.
