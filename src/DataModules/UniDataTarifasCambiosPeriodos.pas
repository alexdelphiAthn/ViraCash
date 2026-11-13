{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTarifasCambiosPeriodos                                 }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Periodos (etapas de rebajas) de las sesiones de cambio de tarifa          }
{    (FZ-ISSUE-944). Todos los periodos comparten los artículos de la          }
{    sesión: cada uno tiene su copia de las líneas con sus propios precios.    }
{    Las líneas que llegan sin periodo (carga de artículos, documentos de      }
{    trabajo) se reparten en todos los periodos al sincronizar.                }
{******************************************************************************}
unit UniDataTarifasCambiosPeriodos;

interface

uses
  Uni,
  inLibTarifasCambiosPeriodos;

function CargarVigenciasPeriodosTarifa(AConexion: TUniConnection;
  ASesion: Integer): TVigenciasPeriodoTarifa;

// Crea el periodo con los parámetros del último periodo (o de la cabecera
// si es el primero). El primero se queda con las líneas que ya tenía la
// sesión. Devuelve el ID del periodo nuevo.
function InsertarPeriodoTarifa(AConexion: TUniConnection; ASesion: Integer;
  const AVigencia: TVigenciaPeriodoTarifa;
  const ANombre, AUsuario: string): Integer;

// Retira el periodo y sus líneas. Si era el último, sus líneas vuelven a la
// sesión sin periodos y la sesión deja de ser por periodos.
procedure EliminarPeriodoTarifa(AConexion: TUniConnection;
  ASesion, APeriodo: Integer; const AUsuario: string);

// Reparte en todos los periodos los artículos de la sesión que les falten y
// retira las líneas sin periodo. Devuelve True si cambió alguna línea.
function SincronizarLineasPeriodosTarifa(AConexion: TUniConnection;
  ASesion: Integer; const AUsuario: string): Boolean;

procedure MarcarPeriodosTarifaAplicados(AConexion: TUniConnection;
  ASesion: Integer; const AUsuario: string);

procedure MarcarPeriodoTarifaBorrador(AConexion: TUniConnection;
  APeriodo: Integer; const AUsuario: string);

implementation

uses
  System.SysUtils, System.Variants;

const
  SQL_VIGENCIAS_PERIODOS =
    'SELECT P.ID_TARCP, P.NUMERO_TARCP, P.FECHA_DESDE_TARCP, ' +
    'P.FECHA_HASTA_TARCP FROM fza_tarifas_cambios_periodos P ' +
    'WHERE P.CODIGO_TARC_TARCP = :SESION ORDER BY P.NUMERO_TARCP';
  // Los parámetros salen del último periodo; sin periodos, de la cabecera.
  SQL_INSERTAR_PERIODO =
    'INSERT INTO fza_tarifas_cambios_periodos (CODIGO_TARC_TARCP, ' +
    'NUMERO_TARCP, NOMBRE_TARCP, FECHA_DESDE_TARCP, FECHA_HASTA_TARCP, ' +
    'CAMPO_ORIGEN_TARCP, CAMPO_DESTINO_TARCP, TIPO_APLICACION_TARCP, ' +
    'VALOR_APLICACION_TARCP, VALOR_REDONDEO_TARCP, ' +
    'VALOR_MENOS_AJUSTE_TARCP, ESREDONDEAR_ARRIBA_TARCP, ESTADO_TARCP, ' +
    'INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT C.CODIGO_TARC, :NUMERO, :NOMBRE, :DESDE, :HASTA, ' +
    'COALESCE(U.CAMPO_ORIGEN_TARCP, C.CAMPO_ORIGEN_TARC), ' +
    'COALESCE(U.CAMPO_DESTINO_TARCP, C.CAMPO_DESTINO_TARC), ' +
    'COALESCE(U.TIPO_APLICACION_TARCP, C.TIPO_APLICACION_TARC), ' +
    'COALESCE(U.VALOR_APLICACION_TARCP, C.VALOR_APLICACION_TARC), ' +
    'COALESCE(U.VALOR_REDONDEO_TARCP, C.VALOR_REDONDEO_TARC), ' +
    'COALESCE(U.VALOR_MENOS_AJUSTE_TARCP, C.VALOR_MENOS_AJUSTE_TARC), ' +
    'COALESCE(U.ESREDONDEAR_ARRIBA_TARCP, C.ESREDONDEAR_ARRIBA_TARC), ' +
    '''BORRADOR'', NOW(), :USUARIO ' +
    'FROM fza_tarifas_cambios C ' +
    'LEFT JOIN fza_tarifas_cambios_periodos U ' +
    'ON U.CODIGO_TARC_TARCP = C.CODIGO_TARC ' +
    'AND U.NUMERO_TARCP = (SELECT MAX(M.NUMERO_TARCP) ' +
    'FROM fza_tarifas_cambios_periodos M ' +
    'WHERE M.CODIGO_TARC_TARCP = C.CODIGO_TARC) ' +
    'WHERE C.CODIGO_TARC = :SESION';
  SQL_ULTIMO_ID = 'SELECT LAST_INSERT_ID() AS ID';
  SQL_LINEAS_A_PRIMER_PERIODO =
    'UPDATE fza_tarifas_cambios_lineas SET ID_TARCP_TARCLIN = :PERIODO, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC_TARCLIN = :SESION AND ID_TARCP_TARCLIN = 0';
  SQL_LINEAS_SIN_PERIODO =
    'UPDATE fza_tarifas_cambios_lineas SET ID_TARCP_TARCLIN = 0, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC_TARCLIN = :SESION AND ID_TARCP_TARCLIN = :PERIODO';
  SQL_BORRAR_LINEAS_PERIODO =
    'DELETE FROM fza_tarifas_cambios_lineas ' +
    'WHERE CODIGO_TARC_TARCLIN = :SESION AND ID_TARCP_TARCLIN = :PERIODO';
  SQL_BORRAR_PERIODO =
    'DELETE FROM fza_tarifas_cambios_periodos ' +
    'WHERE CODIGO_TARC_TARCP = :SESION AND ID_TARCP = :PERIODO';
  SQL_MARCA_SESION =
    'UPDATE fza_tarifas_cambios SET ESPOR_PERIODOS_TARC = :MARCA, ' +
    'ESTADO_TARC = ''BORRADOR'', USUARIO_MODIF = :USUARIO, ' +
    'INSTANTE_MODIF = NOW() WHERE CODIGO_TARC = :SESION';
  // Una carga posterior (sin periodo) trae precios de partida recientes:
  // se llevan a las líneas de los periodos del mismo artículo/SKU.
  SQL_PARTIDA_DESDE_SIN_PERIODO =
    'UPDATE fza_tarifas_cambios_lineas L ' +
    'JOIN fza_tarifas_cambios_lineas N ' +
    'ON N.CODIGO_TARC_TARCLIN = L.CODIGO_TARC_TARCLIN ' +
    'AND N.ID_TARCP_TARCLIN = 0 ' +
    'AND N.CODIGO_ART_TARCLIN = L.CODIGO_ART_TARCLIN ' +
    'AND N.CODIGO_UNIDAD_SKU_TARCLIN = L.CODIGO_UNIDAD_SKU_TARCLIN ' +
    'SET L.PRECIO_ORIGEN_TARCLIN = N.PRECIO_ORIGEN_TARCLIN, ' +
    'L.PRECIO_COSTE_TARCLIN = N.PRECIO_COSTE_TARCLIN, ' +
    'L.PRECIO_SALIDA_ACTUAL_TARCLIN = N.PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    'L.PRECIO_FINAL_ACTUAL_TARCLIN = N.PRECIO_FINAL_ACTUAL_TARCLIN, ' +
    'L.PRECIO_DTO_ACTUAL_TARCLIN = N.PRECIO_DTO_ACTUAL_TARCLIN, ' +
    'L.PORCENTAJE_DTO_ACTUAL_TARCLIN = N.PORCENTAJE_DTO_ACTUAL_TARCLIN, ' +
    'L.USUARIO_MODIF = :USUARIO, L.INSTANTE_MODIF = NOW() ' +
    'WHERE L.CODIGO_TARC_TARCLIN = :SESION AND L.ID_TARCP_TARCLIN <> 0';
  // Cada periodo recibe una copia de los artículos que le faltan, con los
  // precios de partida y sin precio nuevo: hay que calcular el periodo.
  SQL_COPIAR_ARTICULOS_A_PERIODOS =
    'INSERT INTO fza_tarifas_cambios_lineas (CODIGO_TARC_TARCLIN, ' +
    'ID_TARCP_TARCLIN, CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CODIGO_TAR_ORIGEN_TARCLIN, CODIGO_TAR_DESTINO_TARCLIN, ' +
    'PRECIO_ORIGEN_TARCLIN, PRECIO_COSTE_TARCLIN, ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN, PRECIO_FINAL_ACTUAL_TARCLIN, ' +
    'PRECIO_DTO_ACTUAL_TARCLIN, PORCENTAJE_DTO_ACTUAL_TARCLIN, ' +
    'ESAPLICAR_TARCLIN, ESTADO_TARCLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT P.CODIGO_TARC_TARCP, P.ID_TARCP, O.CODIGO_ART_TARCLIN, ' +
    'O.CODIGO_UNIDAD_SKU_TARCLIN, O.CODIGO_TAR_ORIGEN_TARCLIN, ' +
    'O.CODIGO_TAR_DESTINO_TARCLIN, O.PRECIO_ORIGEN_TARCLIN, ' +
    'O.PRECIO_COSTE_TARCLIN, O.PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    'O.PRECIO_FINAL_ACTUAL_TARCLIN, O.PRECIO_DTO_ACTUAL_TARCLIN, ' +
    'O.PORCENTAJE_DTO_ACTUAL_TARCLIN, O.ESAPLICAR_TARCLIN, ' +
    '''PENDIENTE'', NOW(), :USUARIO ' +
    'FROM fza_tarifas_cambios_periodos P ' +
    'JOIN fza_tarifas_cambios_lineas O ' +
    'ON O.CODIGO_TARC_TARCLIN = P.CODIGO_TARC_TARCP ' +
    'AND O.ID_TARCLIN = (SELECT MIN(M.ID_TARCLIN) ' +
    'FROM fza_tarifas_cambios_lineas M ' +
    'WHERE M.CODIGO_TARC_TARCLIN = O.CODIGO_TARC_TARCLIN ' +
    'AND M.CODIGO_ART_TARCLIN = O.CODIGO_ART_TARCLIN ' +
    'AND M.CODIGO_UNIDAD_SKU_TARCLIN = O.CODIGO_UNIDAD_SKU_TARCLIN) ' +
    'WHERE P.CODIGO_TARC_TARCP = :SESION ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas E ' +
    'WHERE E.CODIGO_TARC_TARCLIN = P.CODIGO_TARC_TARCP ' +
    'AND E.ID_TARCP_TARCLIN = P.ID_TARCP ' +
    'AND E.CODIGO_ART_TARCLIN = O.CODIGO_ART_TARCLIN ' +
    'AND E.CODIGO_UNIDAD_SKU_TARCLIN = O.CODIGO_UNIDAD_SKU_TARCLIN) ' +
    'ORDER BY P.NUMERO_TARCP, O.ID_TARCLIN';
  SQL_BORRAR_LINEAS_SIN_PERIODO =
    'DELETE FROM fza_tarifas_cambios_lineas ' +
    'WHERE CODIGO_TARC_TARCLIN = :SESION AND ID_TARCP_TARCLIN = 0 ' +
    'AND EXISTS (SELECT 1 FROM fza_tarifas_cambios_periodos P ' +
    'WHERE P.CODIGO_TARC_TARCP = :SESION_P)';
  SQL_PERIODOS_APLICADOS =
    'UPDATE fza_tarifas_cambios_periodos SET ESTADO_TARCP = ''APLICADA'', ' +
    'INSTANTE_APLICACION_TARCP = NOW(), USUARIO_APLICACION_TARCP = ' +
    ':USUARIO, USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC_TARCP = :SESION';
  SQL_PERIODO_BORRADOR =
    'UPDATE fza_tarifas_cambios_periodos SET ESTADO_TARCP = ''BORRADOR'', ' +
    'INSTANTE_APLICACION_TARCP = NULL, USUARIO_APLICACION_TARCP = NULL, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE ID_TARCP = :PERIODO';

function CrearConsulta(AConexion: TUniConnection;
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := AConexion;
  Result.SQL.Text := ASql;
end;

// Ejecuta ASql con los parámetros por nombre y devuelve las filas afectadas.
function Ejecutar(AConexion: TUniConnection; const ASql: string;
  const ANombres: array of string; const AValores: array of Variant): Integer;
var
  Consulta: TUniQuery;
  I: Integer;
begin
  Consulta := CrearConsulta(AConexion, ASql);
  try
    for I := 0 to High(ANombres) do
      Consulta.ParamByName(ANombres[I]).Value := AValores[I];
    Consulta.Execute;
    Result := Consulta.RowsAffected;
  finally
    FreeAndNil(Consulta);
  end;
end;

// Una operación de varios pasos es atómica: si el llamador no tiene
// transacción abierta, se abre aquí y se confirma o revierte entera.
procedure EnTransaccion(AConexion: TUniConnection; AProc: TProc);
var
  EsTransaccionPropia: Boolean;
begin
  EsTransaccionPropia := not AConexion.InTransaction;
  if EsTransaccionPropia then
    AConexion.StartTransaction;
  try
    AProc();
    if EsTransaccionPropia then
      AConexion.Commit;
  except
    if EsTransaccionPropia and AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

function CargarVigenciasPeriodosTarifa(AConexion: TUniConnection;
  ASesion: Integer): TVigenciasPeriodoTarifa;
var
  Consulta: TUniQuery;
  Vigencia: TVigenciaPeriodoTarifa;
begin
  Result := nil;
  Consulta := CrearConsulta(AConexion, SQL_VIGENCIAS_PERIODOS);
  try
    Consulta.ParamByName('SESION').AsInteger := ASesion;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Vigencia.Id := Consulta.FieldByName('ID_TARCP').AsInteger;
      Vigencia.Numero := Consulta.FieldByName('NUMERO_TARCP').AsInteger;
      Vigencia.Desde := Consulta.FieldByName('FECHA_DESDE_TARCP').AsDateTime;
      Vigencia.Hasta := Consulta.FieldByName('FECHA_HASTA_TARCP').AsDateTime;
      Result := Result + [Vigencia];
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function UltimoIdInsertado(AConexion: TUniConnection): Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := CrearConsulta(AConexion, SQL_ULTIMO_ID);
  try
    Consulta.Open;
    Result := Consulta.FieldByName('ID').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function InsertarPeriodoTarifa(AConexion: TUniConnection; ASesion: Integer;
  const AVigencia: TVigenciaPeriodoTarifa;
  const ANombre, AUsuario: string): Integer;
var
  EsPrimero: Boolean;
  iPeriodo: Integer;
begin
  EsPrimero := Length(CargarVigenciasPeriodosTarifa(AConexion, ASesion)) = 0;
  iPeriodo := 0;
  EnTransaccion(AConexion,
    procedure
    begin
      Ejecutar(AConexion, SQL_INSERTAR_PERIODO,
        ['NUMERO', 'NOMBRE', 'DESDE', 'HASTA', 'USUARIO', 'SESION'],
        [AVigencia.Numero, ANombre, AVigencia.Desde, AVigencia.Hasta,
         AUsuario, ASesion]);
      iPeriodo := UltimoIdInsertado(AConexion);
      if EsPrimero then
        Ejecutar(AConexion, SQL_LINEAS_A_PRIMER_PERIODO,
          ['PERIODO', 'USUARIO', 'SESION'], [iPeriodo, AUsuario, ASesion]);
      Ejecutar(AConexion, SQL_MARCA_SESION, ['MARCA', 'USUARIO', 'SESION'],
        ['S', AUsuario, ASesion]);
      SincronizarLineasPeriodosTarifa(AConexion, ASesion, AUsuario);
    end);
  Result := iPeriodo;
end;

procedure EliminarPeriodoTarifa(AConexion: TUniConnection;
  ASesion, APeriodo: Integer; const AUsuario: string);
var
  EsUltimo: Boolean;
begin
  EsUltimo := Length(CargarVigenciasPeriodosTarifa(AConexion, ASesion)) <= 1;
  EnTransaccion(AConexion,
    procedure
    begin
      if EsUltimo then
      begin
        Ejecutar(AConexion, SQL_LINEAS_SIN_PERIODO,
          ['USUARIO', 'SESION', 'PERIODO'], [AUsuario, ASesion, APeriodo]);
        Ejecutar(AConexion, SQL_MARCA_SESION,
          ['MARCA', 'USUARIO', 'SESION'], ['N', AUsuario, ASesion]);
      end
      else
        Ejecutar(AConexion, SQL_BORRAR_LINEAS_PERIODO,
          ['SESION', 'PERIODO'], [ASesion, APeriodo]);
      Ejecutar(AConexion, SQL_BORRAR_PERIODO, ['SESION', 'PERIODO'],
        [ASesion, APeriodo]);
    end);
end;

function SincronizarLineasPeriodosTarifa(AConexion: TUniConnection;
  ASesion: Integer; const AUsuario: string): Boolean;
var
  iCambios: Integer;
begin
  iCambios := 0;
  EnTransaccion(AConexion,
    procedure
    begin
      Inc(iCambios, Ejecutar(AConexion, SQL_PARTIDA_DESDE_SIN_PERIODO,
        ['USUARIO', 'SESION'], [AUsuario, ASesion]));
      Inc(iCambios, Ejecutar(AConexion, SQL_COPIAR_ARTICULOS_A_PERIODOS,
        ['USUARIO', 'SESION'], [AUsuario, ASesion]));
      Inc(iCambios, Ejecutar(AConexion, SQL_BORRAR_LINEAS_SIN_PERIODO,
        ['SESION', 'SESION_P'], [ASesion, ASesion]));
    end);
  Result := iCambios > 0;
end;

procedure MarcarPeriodosTarifaAplicados(AConexion: TUniConnection;
  ASesion: Integer; const AUsuario: string);
begin
  Ejecutar(AConexion, SQL_PERIODOS_APLICADOS, ['USUARIO', 'SESION'],
    [AUsuario, ASesion]);
end;

procedure MarcarPeriodoTarifaBorrador(AConexion: TUniConnection;
  APeriodo: Integer; const AUsuario: string);
begin
  Ejecutar(AConexion, SQL_PERIODO_BORRADOR, ['USUARIO', 'PERIODO'],
    [AUsuario, APeriodo]);
end;

end.
