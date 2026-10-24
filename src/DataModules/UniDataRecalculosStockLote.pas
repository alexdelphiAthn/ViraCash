{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRecalculosStockLote                                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ejecuta por lotes la cola persistente de recálculos de stock.             }
{******************************************************************************}
unit UniDataRecalculosStockLote;

interface

uses
  Uni;

type
  TConfiguracionLoteRecalculosStock = record
    MaximoGrupos: Integer;
    PausaMilisegundos: Integer;
    SegundosLease: Integer;
    SegundosReintento: Integer;
    Usuario: string;
  end;
  TResultadoLoteRecalculosStock = record
    CantidadLotes: Integer;
    CantidadGruposProcesados: Integer;
    CantidadGruposError: Integer;
    CantidadSinProcesar: Integer;
    CantidadPendientes: Integer;
    CantidadProcesando: Integer;
    CantidadErrores: Integer;
  end;
  TNotificacionLoteRecalculosStock = reference to procedure(
    const AParcial: TResultadoLoteRecalculosStock);

function ProcesarColaRecalculosStock(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionLoteRecalculosStock;
  const ANotificacion: TNotificacionLoteRecalculosStock = nil
): TResultadoLoteRecalculosStock;

implementation

uses
  Data.DB,
  System.SysUtils;

const
  PROCEDIMIENTO_PROCESAR_LOTE =
    'PRC_FZA_MOVIMIENTOS_RECALCULO_PROCESAR_LOTE';

function HayRecalculosElegibles(
  AConexion: TUniConnection): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT EXISTS(' +
      '  SELECT 1 ' +
      '    FROM fza_movimientos_recalculos_pendientes Q ' +
      '   WHERE Q.ESPROCESADO_MOVREC = ''N'' ' +
      '     AND ((Q.ESTADO_MOVREC IN (''PENDIENTE'', ''ERROR'') ' +
      '       AND (Q.INSTANTE_PROXIMO_INTENTO_MOVREC IS NULL OR ' +
      '            Q.INSTANTE_PROXIMO_INTENTO_MOVREC <= NOW()) ' +
      '       AND NOT EXISTS (' +
      '         SELECT 1 ' +
      '           FROM fza_movimientos_recalculos_pendientes B ' +
      '          WHERE B.CODIGO_ALM_MOVREC = Q.CODIGO_ALM_MOVREC ' +
      '            AND B.CODIGO_UNIDAD_MOVREC = ' +
      '                Q.CODIGO_UNIDAD_MOVREC ' +
      '            AND B.ESTADO_MOVREC = ''PROCESANDO'' ' +
      '            AND B.ESPROCESADO_MOVREC = ''N'' ' +
      '            AND B.INSTANTE_LIMITE_RECLAMACION_MOVREC > NOW())) ' +
      '       OR (Q.ESTADO_MOVREC = ''PROCESANDO'' ' +
      '         AND (Q.INSTANTE_LIMITE_RECLAMACION_MOVREC IS NULL OR ' +
      '              Q.INSTANTE_LIMITE_RECLAMACION_MOVREC <= NOW())))' +
      ') AS HAY_RECALCULOS';
    oConsulta.Open;
    Result := oConsulta.FieldByName('HAY_RECALCULOS').AsInteger <> 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EjecutarLoteRecalculosStock(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionLoteRecalculosStock;
  out AGruposProcesados: Integer;
  out AGruposError: Integer);
var
  oProcedimiento: TUniStoredProc;
begin
  AGruposProcesados := 0;
  AGruposError := 0;
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := AConexion;
    oProcedimiento.StoredProcName := PROCEDIMIENTO_PROCESAR_LOTE;
    oProcedimiento.Params.Clear;
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_MAX_GRUPOS', ptInput);
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_PAUSA_MILISEGUNDOS', ptInput);
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_SEGUNDOS_LEASE', ptInput);
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_SEGUNDOS_REINTENTO', ptInput);
    oProcedimiento.Params.CreateParam(
      ftString, 'p_USUARIO', ptInput);
    oProcedimiento.ParamByName('p_MAX_GRUPOS').AsInteger :=
      AConfiguracion.MaximoGrupos;
    oProcedimiento.ParamByName('p_PAUSA_MILISEGUNDOS').AsInteger :=
      AConfiguracion.PausaMilisegundos;
    oProcedimiento.ParamByName('p_SEGUNDOS_LEASE').AsInteger :=
      AConfiguracion.SegundosLease;
    oProcedimiento.ParamByName('p_SEGUNDOS_REINTENTO').AsInteger :=
      AConfiguracion.SegundosReintento;
    oProcedimiento.ParamByName('p_USUARIO').AsString :=
      AConfiguracion.Usuario;
    // El procedimiento termina con un SELECT de resumen del lote.
    oProcedimiento.Open;
    if not oProcedimiento.IsEmpty then
    begin
      AGruposProcesados :=
        oProcedimiento.FieldByName('GRUPOS_PROCESADOS').AsInteger;
      AGruposError :=
        oProcedimiento.FieldByName('GRUPOS_ERROR').AsInteger;
    end;
    oProcedimiento.Close;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure LeerResumenRecalculosStock(
  AConexion: TUniConnection;
  var AResultado: TResultadoLoteRecalculosStock);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT ' +
      '  CAST(COUNT(*) AS SIGNED) AS SIN_PROCESAR, ' +
      '  CAST(COALESCE(SUM(CASE WHEN ESTADO_MOVREC = ''PENDIENTE'' ' +
      '    THEN 1 ELSE 0 END), 0) AS SIGNED) AS PENDIENTES, ' +
      '  CAST(COALESCE(SUM(CASE WHEN ESTADO_MOVREC = ''PROCESANDO'' ' +
      '    THEN 1 ELSE 0 END), 0) AS SIGNED) AS PROCESANDO, ' +
      '  CAST(COALESCE(SUM(CASE WHEN ESTADO_MOVREC = ''ERROR'' ' +
      '    THEN 1 ELSE 0 END), 0) AS SIGNED) AS ERRORES ' +
      'FROM fza_movimientos_recalculos_pendientes ' +
      'WHERE ESPROCESADO_MOVREC = ''N''';
    oConsulta.Open;
    AResultado.CantidadSinProcesar :=
      oConsulta.FieldByName('SIN_PROCESAR').AsInteger;
    AResultado.CantidadPendientes :=
      oConsulta.FieldByName('PENDIENTES').AsInteger;
    AResultado.CantidadProcesando :=
      oConsulta.FieldByName('PROCESANDO').AsInteger;
    AResultado.CantidadErrores :=
      oConsulta.FieldByName('ERRORES').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function ProcesarColaRecalculosStock(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionLoteRecalculosStock;
  const ANotificacion: TNotificacionLoteRecalculosStock
): TResultadoLoteRecalculosStock;
var
  bHayRecalculos: Boolean;
  iGruposError: Integer;
  iGruposProcesados: Integer;
begin
  Result := Default(TResultadoLoteRecalculosStock);
  bHayRecalculos := HayRecalculosElegibles(AConexion);
  while bHayRecalculos do
  begin
    EjecutarLoteRecalculosStock(
      AConexion,
      AConfiguracion,
      iGruposProcesados,
      iGruposError);
    Inc(Result.CantidadLotes);
    Inc(Result.CantidadGruposProcesados, iGruposProcesados);
    Inc(Result.CantidadGruposError, iGruposError);
    LeerResumenRecalculosStock(AConexion, Result);
    if Assigned(ANotificacion) then
      ANotificacion(Result);
    // Un lote que no reclama ningun grupo no debe repetirse en bucle:
    // el resumen final informara de lo que quede sin procesar.
    bHayRecalculos :=
      (iGruposProcesados + iGruposError > 0) and
      HayRecalculosElegibles(AConexion);
  end;
  LeerResumenRecalculosStock(AConexion, Result);
end;

end.
