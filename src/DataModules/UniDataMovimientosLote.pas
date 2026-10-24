{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMovimientosLote                                        }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Movimientos de almacén con lote (F-LOTEC-013): los generadores           }
{    preparan PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT como siempre y, solo si la    }
{    fila lleva lote o serie, se ejecuta ..._INSERT_LOTE (script 779) con      }
{    los mismos valores más el lote y la caducidad. Sin lote, todo igual.      }
{    F-LOTEC-016: el lote solo cuenta si el modo efectivo del artículo lo      }
{    pide con los interruptores vigentes (un lote antiguo en texto libre con   }
{    todo apagado no parte el stock).                                          }
{******************************************************************************}
unit UniDataMovimientosLote;

interface

uses
  Uni, Data.DB, inLibTrazabilidad;

// ASinLote: el procedimiento de siempre ya relleno. AConLote: uno vacío que
// se prepara la primera vez con los parámetros de ASinLote (lo libera el
// llamante). Fecha 0 = sin caducidad.
procedure EjecutarMovimientoConLote(ASinLote, AConLote: TUniStoredProc;
  const ALote: string; AFechaCaducidad: TDate); overload;
procedure EjecutarMovimientoConLote(ASinLote, AConLote: TUniStoredProc;
  const ALote: string; AFechaCaducidad: TDate;
  const AActivacion: TActivacionTrazabilidad); overload;
// Columna FECHA_CADUCIDAD de la consulta de origen (0 si es NULL).
function FechaCaducidadMovimiento(AConsulta: TDataSet): TDate;

implementation

uses
  System.SysUtils, System.Classes;

const
  PROC_INSERT_LOTE = 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT_LOTE';

function FechaCaducidadMovimiento(AConsulta: TDataSet): TDate;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := AConsulta.FieldByName('FECHA_CADUCIDAD');
  if not oCampo.IsNull then
    Result := Trunc(oCampo.AsDateTime);
end;

procedure PrepararConLote(ASinLote, AConLote: TUniStoredProc);
var
  iParametro: Integer;
begin
  AConLote.Connection := ASinLote.Connection;
  AConLote.StoredProcName := PROC_INSERT_LOTE;
  AConLote.Params.Clear;
  for iParametro := 0 to ASinLote.Params.Count - 1 do
    AConLote.Params.CreateParam(ASinLote.Params[iParametro].DataType,
      ASinLote.Params[iParametro].Name, ptInput);
  AConLote.Params.CreateParam(ftString, 'p_LOTE_MOV', ptInput);
  AConLote.Params.CreateParam(ftDate, 'p_FECHA_CADUCIDAD_MOV', ptInput);
end;

function TextoParametro(AProcedimiento: TUniStoredProc;
  const ANombre: string): string;
var
  oParametro: TParam;
begin
  Result := '';
  oParametro := AProcedimiento.Params.FindParam(ANombre);
  if Assigned(oParametro) then
    Result := oParametro.AsString;
end;

function LoteAplicable(AProcedimiento: TUniStoredProc;
  const ALote: string; const AActivacion: TActivacionTrazabilidad): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if (Trim(ALote) <> '') and AActivacion.AlgunModoActivo then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AProcedimiento.Connection;
      oConsulta.SQL.Text :=
        'SELECT MAX(A.TIPO_TRAZABILIDAD_ART) AS MODO ' +
        '  FROM fza_articulos A ' +
        ' WHERE A.CODIGO_ART_ART = :ART ' +
        '    OR A.CODIGO_ART_ART = (SELECT MAX(K.CODIGO_ART_SKU) ' +
        '                             FROM fza_articulos_skus K ' +
        '                            WHERE K.CODIGO_UNIDAD_SKU = :SKU)';
      oConsulta.ParamByName('ART').AsString :=
        TextoParametro(AProcedimiento, 'p_CODARTICULO');
      oConsulta.ParamByName('SKU').AsString :=
        TextoParametro(AProcedimiento, 'p_CODIGO_UNIDAD_MOV');
      oConsulta.Open;
      Result := RequiereLote(AActivacion.ModoEfectivo(
        ModoDesdeCadena(oConsulta.FieldByName('MODO').AsString)));
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure EjecutarMovimientoConLote(ASinLote, AConLote: TUniStoredProc;
  const ALote: string; AFechaCaducidad: TDate);
begin
  EjecutarMovimientoConLote(ASinLote, AConLote, ALote,
    AFechaCaducidad, ActivacionVigente);
end;

procedure EjecutarMovimientoConLote(ASinLote, AConLote: TUniStoredProc;
  const ALote: string; AFechaCaducidad: TDate;
  const AActivacion: TActivacionTrazabilidad);
var
  iParametro: Integer;
begin
  if not LoteAplicable(ASinLote, ALote, AActivacion) then
    ASinLote.ExecProc
  else
  begin
    if AConLote.Params.Count <> ASinLote.Params.Count + 2 then
      PrepararConLote(ASinLote, AConLote);
    for iParametro := 0 to ASinLote.Params.Count - 1 do
    begin
      if ASinLote.Params[iParametro].IsNull then
        AConLote.Params[iParametro].Clear
      else
        AConLote.Params[iParametro].Value :=
          ASinLote.Params[iParametro].Value;
    end;
    AConLote.ParamByName('p_LOTE_MOV').AsString := Trim(ALote);
    if AFechaCaducidad = 0 then
      AConLote.ParamByName('p_FECHA_CADUCIDAD_MOV').Clear
    else
      AConLote.ParamByName('p_FECHA_CADUCIDAD_MOV').AsDate := AFechaCaducidad;
    AConLote.ExecProc;
  end;
end;

end.
