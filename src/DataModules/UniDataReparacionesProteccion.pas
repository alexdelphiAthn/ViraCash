{******************************************************************************}
{  Módulo: UniDataReparacionesProteccion. Tipo: Persistencia                   }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Protege los documentos y conceptos con ejecución registrada.   }
{******************************************************************************}
unit UniDataReparacionesProteccion;
interface
uses Uni;
procedure ExigirDocumentoOrdenEditable(AConexion: TUniConnection;
  const ASerie, ANumero: string; AProveedor: Boolean);
procedure ExigirLineaOrdenEditable(AConexion: TUniConnection; ALinea: Int64);
procedure ExigirLineaOrdenSinSesiones(AConexion: TUniConnection; ALinea: Int64);
procedure ExigirOrdenAnulable(AConexion: TUniConnection; AOrden: Int64);
implementation
uses System.SysUtils, Data.DB, inLibMsgReparacionesCircuito;

procedure ExigirDocumentoOrdenEditable(AConexion: TUniConnection;
  const ASerie, ANumero: string; AProveedor: Boolean);
var
  oConsulta: TUniQuery;
  sTipo: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA=DATABASE() ' +
      'AND TABLE_NAME=''fza_reparaciones_imputaciones''';
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      sTipo := 'TIPO_RCI IN (''CL'',''AS'')';
      if AProveedor then
        sTipo := 'TIPO_RCI=''PR''';
      oConsulta.Close;
      oConsulta.SQL.Text := 'SELECT 1 FROM fza_reparaciones_imputaciones ' +
        'WHERE SERIE_RCI=:SERIE AND NUMERO_RCI=:NUMERO AND ' +
        sTipo + ' LIMIT 1';
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        raise EArgumentException.Create(SCircuitoDocumentado);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TieneCircuito(AConexion: TUniConnection): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA=DATABASE() ' +
      'AND TABLE_NAME=''fza_reparaciones_entregas''';
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure ExigirLineaOrdenEditable(AConexion: TUniConnection; ALinea: Int64);
var
  oConsulta: TUniQuery;
begin
  if TieneCircuito(AConexion) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT 1 FROM fza_reparaciones_tiempos ' +
        'WHERE ID_GARLIN_RCT=:LINEA UNION ALL SELECT 1 ' +
        'FROM fza_reparaciones_materiales WHERE ID_GARLIN_RCM=:LINEA ' +
        'UNION ALL SELECT 1 FROM fza_reparaciones_imputaciones ' +
        'WHERE ID_GARLIN_RCI=:LINEA UNION ALL SELECT 1 ' +
        'FROM fza_reparaciones_entregas WHERE ID_GARLIN_RCE=:LINEA LIMIT 1';
      oConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        raise EArgumentException.Create(SCircuitoDocumentado);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure ExigirLineaOrdenSinSesiones(AConexion: TUniConnection; ALinea: Int64);
var
  oConsulta: TUniQuery;
begin
  if TieneCircuito(AConexion) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT 1 FROM fza_reparaciones_tiempos ' +
        'WHERE ID_GARLIN_RCT=:LINEA AND ESANULADO_RCT=''N'' ' +
        'AND INSTANTE_FIN_RCT IS NULL LIMIT 1';
      oConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        raise EArgumentException.Create(SCircuitoPendiente);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;
procedure ExigirOrdenAnulable(AConexion: TUniConnection; AOrden: Int64);
var
  oConsulta: TUniQuery;
begin
  if TieneCircuito(AConexion) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT ID_GAR ' +
        'FROM fza_garantias_reclamaciones WHERE ID_GAR=:ORDEN FOR UPDATE';
      oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
      oConsulta.Open;
      oConsulta.Close;
      oConsulta.SQL.Text := 'SELECT 1 FROM fza_reparaciones_imputaciones ' +
        'WHERE ID_GAR_RCI=:ORDEN UNION ALL SELECT 1 ' +
        'FROM fza_reparaciones_tiempos WHERE ID_GAR_RCT=:ORDEN ' +
        'AND ESANULADO_RCT=''N'' AND INSTANTE_FIN_RCT IS NULL ' +
        'UNION ALL SELECT 1 FROM fza_reparaciones_entregas ' +
        'WHERE ID_GAR_RCE=:ORDEN ' +
        'AND CANTIDAD_ENVIADA_RCE>CANTIDAD_RECIBIDA_RCE ' +
        'UNION ALL SELECT 1 FROM fza_reparaciones_materiales M ' +
        'JOIN fza_garantias_lineas L ON L.ID_GARLIN=M.ID_GARLIN_RCM ' +
        'WHERE L.ID_GAR_GARLIN=:ORDEN ' +
        'AND M.CANTIDAD_UTILIZADA_RCM>M.CANTIDAD_DEVUELTA_RCM LIMIT 1';
      oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        raise EArgumentException.Create(SCircuitoPendiente);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;
end.
