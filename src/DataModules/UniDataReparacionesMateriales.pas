{******************************************************************************}
{  Módulo: UniDataReparacionesMateriales. Tipo: Persistencia                   }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Material empleado con referencia libre, sin control de stock.  }
{******************************************************************************}
unit UniDataReparacionesMateriales;
interface
uses Uni, UniDataReparacionesCircuitoBase, inLibReparacionesCircuito;
type
  TRepositorioMaterialesOrden = class(TRepositorioCircuitoOrden)
  private
    procedure Persistir(AOrden: Int64; const AMaterial: TMaterialOrden);
  public
    procedure Guardar(AOrden: Int64; const AMaterial: TMaterialOrden);
    function Material(AOrden, ALinea: Int64): TMaterialOrden;
  end;
implementation
uses System.SysUtils, Data.DB, inLibReparaciones, inLibMsgReparacionesCircuito;

function TRepositorioMaterialesOrden.Material(AOrden,
  ALinea: Int64): TMaterialOrden;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TMaterialOrden);
  Result.Linea := ALinea;
  Result.Unidad := 'uds';
  Result.Procedencia := 'ALMACEN';
  oConsulta := Consulta('SELECT PROCEDENCIA_RCM,UNIDAD_RCM,REFERENCIA_RCM,' +
    'CANTIDAD_PREVISTA_RCM,CANTIDAD_UTILIZADA_RCM,CANTIDAD_DEVUELTA_RCM,' +
    'REVISION_RCM FROM fza_reparaciones_materiales ' +
    'WHERE ID_GAR_RCM=:ORDEN AND ID_GARLIN_RCM=:LINEA');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := ALinea;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Procedencia := oConsulta.Fields[0].AsString;
      Result.Unidad := oConsulta.Fields[1].AsString;
      Result.Referencia := oConsulta.Fields[2].AsString;
      Result.Previsto := oConsulta.Fields[3].AsFloat;
      Result.Utilizado := oConsulta.Fields[4].AsFloat;
      Result.Devuelto := oConsulta.Fields[5].AsFloat;
      Result.Revision := oConsulta.Fields[6].AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMaterialesOrden.Persistir(AOrden: Int64;
  const AMaterial: TMaterialOrden);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_materiales ' +
    '(ID_GAR_RCM,ID_GARLIN_RCM,PROCEDENCIA_RCM,UNIDAD_RCM,REFERENCIA_RCM,' +
    'CANTIDAD_PREVISTA_RCM,CANTIDAD_UTILIZADA_RCM,CANTIDAD_DEVUELTA_RCM,' +
    'REVISION_RCM,USUARIO_ALTA) VALUES (:ORDEN,:LINEA,:PROCEDENCIA,' +
    ':UNIDAD,:REFERENCIA,:PREVISTO,:UTILIZADO,' +
    ':DEVUELTO,:REVISION+1,:USUARIO) ' +
    'ON DUPLICATE KEY UPDATE PROCEDENCIA_RCM=VALUES(PROCEDENCIA_RCM),' +
    'UNIDAD_RCM=VALUES(UNIDAD_RCM),REFERENCIA_RCM=VALUES(REFERENCIA_RCM),' +
    'CANTIDAD_PREVISTA_RCM=VALUES(CANTIDAD_PREVISTA_RCM),' +
    'CANTIDAD_UTILIZADA_RCM=VALUES(CANTIDAD_UTILIZADA_RCM),' +
    'CANTIDAD_DEVUELTA_RCM=VALUES(CANTIDAD_DEVUELTA_RCM),' +
    'REVISION_RCM=VALUES(REVISION_RCM),' +
    'INSTANTE_MODIF=NOW(),USUARIO_MODIF=VALUES(USUARIO_ALTA)');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := AMaterial.Linea;
    oConsulta.ParamByName('PROCEDENCIA').AsString := AMaterial.Procedencia;
    oConsulta.ParamByName('UNIDAD').AsString := AMaterial.Unidad;
    oConsulta.ParamByName('REFERENCIA').AsString := AMaterial.Referencia;
    oConsulta.ParamByName('PREVISTO').AsFloat := AMaterial.Previsto;
    oConsulta.ParamByName('UTILIZADO').AsFloat := AMaterial.Utilizado;
    oConsulta.ParamByName('DEVUELTO').AsFloat := AMaterial.Devuelto;
    oConsulta.ParamByName('REVISION').AsInteger := AMaterial.Revision;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMaterialesOrden.Guardar(AOrden: Int64;
  const AMaterial: TMaterialOrden);
begin
  ValidarMaterialOrden(AMaterial);
  Transaccion(
    procedure
    var
      rAnterior: TMaterialOrden;
      oLinea: TUniQuery;
    begin
      oLinea := BloquearLinea(AOrden, AMaterial.Linea,
        LINEA_REPARACION_MATERIAL);
      try
        rAnterior := Material(AOrden, AMaterial.Linea);
        if rAnterior.Revision <> AMaterial.Revision then
          raise EArgumentException.Create(SCircuitoConflicto);
        Persistir(AOrden, AMaterial);
        Historial(AOrden, AMaterial.Linea, 'MATERIAL',
          Format('R%d. Uso %g -> %g. Devolución %g -> %g. %s',
          [AMaterial.Revision, rAnterior.Utilizado, AMaterial.Utilizado,
           rAnterior.Devuelto, AMaterial.Devuelto, AMaterial.Referencia]));
      finally
        FreeAndNil(oLinea);
      end;
    end);
end;
end.
