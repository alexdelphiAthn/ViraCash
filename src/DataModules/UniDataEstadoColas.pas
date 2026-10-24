{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEstadoColas                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lectura de incidencias pendientes desde las conexiones de las colas.      }
{******************************************************************************}
unit UniDataEstadoColas;

interface

uses
  Uni, inLibEstadoColasIntf;

function LeerIncidenciaCola(AConexion: TUniConnection;
  ATipo: TTipoColaEstado; AHorasIncidencias: Integer;
  const AInstalacion: string = '';
  ATienda: Integer = 0): string;

implementation

uses
  System.SysUtils, Data.DB, inLibMsgIntegraciones;

function SqlIncidenciaCola(ATipo: TTipoColaEstado): string;
begin
  case ATipo of
    tceWs:
      Result :=
        'SELECT ID_VWSC AS ID, MENSAJE_ERROR_VWSC AS MENSAJE, ' +
        'INSTANTE_MODIF FROM fza_ventas_ws_cola ' +
        'WHERE (ESTADO_VWSC = ''ERROR'' OR ' +
        '(ESTADO_VWSC IN (''PENDIENTE'', ''PROCESANDO'') AND ' +
        'COALESCE(MENSAJE_ERROR_VWSC, '''') <> '''')) ';
    tceHacienda:
      Result :=
        'SELECT C.ID_VFCOLA AS ID, C.MENSAJE_ERROR_VFCOLA AS MENSAJE, ' +
        'C.INSTANTE_MODIF FROM fza_verifactu_cola C ' +
        'WHERE (C.ESTADO_VFCOLA = ''ERROR'' OR ' +
        '(C.ESTADO_VFCOLA IN (''PENDIENTE'', ''PROCESANDO'') AND ' +
        'COALESCE(C.MENSAJE_ERROR_VFCOLA, '''') <> '''') OR ' +
        '(C.ESTADO_VFCOLA = ''ENVIADA'' AND EXISTS (' +
        'SELECT 1 FROM fza_facturas_consolidaciones F ' +
        'WHERE F.SERIE_FAC_FACCON = C.SERIE_FAC_VFCOLA ' +
        'AND F.NUMERO_FAC_FACCON = C.NUMERO_FAC_VFCOLA ' +
        'AND F.ESTADO_FACCON = ''VERIFACTU_ACEPT_ERR''))) ';
    tcePrestaShop:
      Result :=
        'SELECT ID_PSCOLA AS ID, MENSAJE_ERROR_PSCOLA AS MENSAJE, ' +
        'INSTANTE_MODIF FROM fza_prestashop_cola ' +
        'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
        'AND ID_TIENDA_PSCOLA = :TIENDA ' +
        'AND (ESTADO_PSCOLA = ''ERROR'' OR ' +
        '(ESTADO_PSCOLA IN (''PENDIENTE'', ''PROCESANDO'', ' +
        '''PENDIENTE_VISIBILIDAD'', ''PROCESANDO_VISIBILIDAD'') AND ' +
        'COALESCE(MENSAJE_ERROR_PSCOLA, '''') <> '''')) ';
  end;
  // El indicador refleja actividad reciente de todas las colas.
  // Se usa el reloj de la BBDD, igual que al guardar INSTANTE_MODIF.
  Result := Result +
    'AND INSTANTE_MODIF >= DATE_SUB(NOW(), INTERVAL :HORAS HOUR) ' +
    'ORDER BY INSTANTE_MODIF DESC, ID DESC LIMIT 1';
end;

function LeerIncidenciaCola(AConexion: TUniConnection;
  ATipo: TTipoColaEstado; AHorasIncidencias: Integer;
  const AInstalacion: string;
  ATienda: Integer): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SqlIncidenciaCola(ATipo);
    oConsulta.ParamByName('HORAS').AsInteger := AHorasIncidencias;
    if ATipo = tcePrestaShop then
    begin
      oConsulta.ParamByName('INSTALACION').AsString := AInstalacion;
      oConsulta.ParamByName('TIENDA').AsInteger := ATienda;
    end;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := Format(SColaIncidenciaGuardada, [
        DateTimeToStr(oConsulta.FieldByName('INSTANTE_MODIF').AsDateTime),
        oConsulta.FieldByName('ID').AsString,
        oConsulta.FieldByName('MENSAJE').AsString]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
