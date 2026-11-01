{******************************************************************************}
{  Módulo: UniDataReparacionesCircuitoBase. Tipo: Persistencia                 }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Transacciones, bloqueos y auditoría de la ejecución de órdenes.}
{******************************************************************************}
unit UniDataReparacionesCircuitoBase;

interface

uses
  System.SysUtils, Uni;

type
  TRepositorioCircuitoOrden = class
  protected
    FConexion: TUniConnection;
    FUsuario: string;
    function Consulta(const ASql: string): TUniQuery;
    procedure Transaccion(const AAccion: TProc);
    procedure BloquearOrden(AOrden: Int64; AAbierta: Boolean = True);
    function BloquearLinea(AOrden, ALinea: Int64;
      const ATipo: string = ''; AAbierta: Boolean = True): TUniQuery;
    procedure Historial(AOrden, ALinea: Int64;
      const AAccion, ADetalle: string);
    procedure ExigirSinDocumentos(AOrden: Int64);
  public
    constructor Create(AConexion: TUniConnection; const AUsuario: string);
  end;

implementation

uses
  Data.DB, inLibMsgReparacionesCircuito;

constructor TRepositorioCircuitoOrden.Create(AConexion: TUniConnection;
  const AUsuario: string);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FUsuario := AUsuario;
end;

function TRepositorioCircuitoOrden.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

procedure TRepositorioCircuitoOrden.Transaccion(const AAccion: TProc);
var
  bPropia: Boolean;
begin
  bPropia := not FConexion.InTransaction;
  if bPropia then
    FConexion.StartTransaction;
  try
    AAccion();
    if bPropia then
      FConexion.Commit;
  except
    if bPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TRepositorioCircuitoOrden.BloquearOrden(AOrden: Int64;
  AAbierta: Boolean);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT ESTADO_GAR, FECHA_ENTREGA_CLI_GAR ' +
    'FROM fza_garantias_reclamaciones WHERE ID_GAR=:ID FOR UPDATE');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AOrden;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SCircuitoConflicto);
    if oConsulta.FieldByName('ESTADO_GAR').AsString = 'ANULADA' then
      raise EArgumentException.Create(SCircuitoConflicto);
    if AAbierta and
       ((not oConsulta.FieldByName('FECHA_ENTREGA_CLI_GAR').IsNull) or
        ((oConsulta.FieldByName('ESTADO_GAR').AsString <> 'ABIERTA') and
         (oConsulta.FieldByName('ESTADO_GAR').AsString <> 'EN_SAT'))) then
      raise EArgumentException.Create(SCircuitoConflicto);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCircuitoOrden.BloquearLinea(AOrden, ALinea: Int64;
  const ATipo: string; AAbierta: Boolean): TUniQuery;
begin
  BloquearOrden(AOrden, AAbierta);
  Result := Consulta('SELECT ID_GARLIN, TIPO_LINEA_GARLIN, ' +
    'CODIGO_UNIDAD_GARLIN, CODIGO_PRV_GARLIN, DESCRIPCION_GARLIN, ' +
    'PRECIO_COSTE_GARLIN, PRECIO_CLIENTE_GARLIN, CANTIDAD_GARLIN, ' +
    'FECHA_FIN_GARLIN FROM fza_garantias_lineas ' +
    'WHERE ID_GARLIN=:LINEA AND ID_GAR_GARLIN=:ORDEN FOR UPDATE');
  try
    Result.ParamByName('ORDEN').AsLargeInt := AOrden;
    Result.ParamByName('LINEA').AsLargeInt := ALinea;
    Result.Open;
    if Result.IsEmpty or ((ATipo <> '') and
       (Result.FieldByName('TIPO_LINEA_GARLIN').AsString <> ATipo)) then
      raise EArgumentException.Create(SCircuitoConflicto);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TRepositorioCircuitoOrden.Historial(AOrden, ALinea: Int64;
  const AAccion, ADetalle: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_historial ' +
    '(ID_GAR_RCH,ID_GARLIN_RCH,ACCION_RCH,DETALLE_RCH,USUARIO_ALTA) ' +
    'VALUES (:ORDEN,NULLIF(:LINEA,0),:ACCION,:DETALLE,:USUARIO)');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
    oConsulta.ParamByName('ACCION').AsString := AAccion;
    oConsulta.ParamByName('DETALLE').AsString := ADetalle;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCircuitoOrden.ExigirSinDocumentos(AOrden: Int64);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM fza_reparaciones_imputaciones ' +
    'WHERE ID_GAR_RCI=:ID AND TIPO_RCI IN (''CL'',''AS'') LIMIT 1');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AOrden;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EArgumentException.Create(SCircuitoDocumentado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
