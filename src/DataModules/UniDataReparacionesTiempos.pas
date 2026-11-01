{******************************************************************************}
{  Módulo: UniDataReparacionesTiempos. Tipo: Persistencia                      }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Sesiones reales, pausa y corrección auditada por operario.     }
{******************************************************************************}
unit UniDataReparacionesTiempos;

interface

uses
  Uni, UniDataReparacionesCircuitoBase, inLibReparacionesCircuito;

type
  TRepositorioTiemposOrden = class(TRepositorioCircuitoOrden)
  private
    procedure ExigirOperario(const ACodigo: string);
    procedure ExigirSinSolape(const AParte: TParteTiempoOrden);
    function InsertarParte(AOrden: Int64;
      const AParte: TParteTiempoOrden): Int64;
    procedure AnularParte(AOrden: Int64; const AParte: TParteTiempoOrden);
  public
    function Registrar(AOrden: Int64;
      const AParte: TParteTiempoOrden): Int64;
    procedure Pausar(AOrden, AParte: Int64);
  end;

implementation

uses
  System.SysUtils, Data.DB, inLibReparaciones, inLibMsgReparacionesCircuito;

procedure TRepositorioTiemposOrden.ExigirOperario(const ACodigo: string);
var
  oConsulta: TUniQuery;
begin
  // Serializa sesiones del operario incluso entre órdenes diferentes.
  oConsulta := Consulta('SELECT CODIGO_EMPL FROM fza_empleados ' +
    'WHERE CODIGO_EMPL=:CODIGO AND ESACTIVO_EMPL=''S'' FOR UPDATE');
  try
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SCircuitoTiempoInvalido);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioTiemposOrden.ExigirSinSolape(
  const AParte: TParteTiempoOrden);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT ID_RCT FROM fza_reparaciones_tiempos ' +
    'WHERE CODIGO_EMPL_RCT=:OPERARIO AND ESANULADO_RCT=''N'' ' +
    'AND ID_RCT<>:ID AND INSTANTE_INICIO_RCT<COALESCE(:FIN,' +
    '''9999-12-31 23:59:59'') AND COALESCE(INSTANTE_FIN_RCT,' +
    '''9999-12-31 23:59:59'')>:INICIO LIMIT 1 FOR UPDATE');
  try
    oConsulta.ParamByName('OPERARIO').AsString := AParte.Operario;
    oConsulta.ParamByName('ID').AsLargeInt := AParte.Id;
    oConsulta.ParamByName('INICIO').AsDateTime := AParte.Inicio;
    oConsulta.ParamByName('FIN').DataType := ftDateTime;
    if AParte.Fin > 0 then
      oConsulta.ParamByName('FIN').AsDateTime := AParte.Fin
    else
      oConsulta.ParamByName('FIN').Clear;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EArgumentException.Create(SCircuitoTiempoSolapado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioTiemposOrden.InsertarParte(AOrden: Int64;
  const AParte: TParteTiempoOrden): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_reparaciones_tiempos ' +
    '(ID_GAR_RCT,ID_GARLIN_RCT,CODIGO_EMPL_RCT,TAREA_RCT,' +
    'INSTANTE_INICIO_RCT,INSTANTE_FIN_RCT,MOTIVO_RCT,USUARIO_ALTA) ' +
    'VALUES (:ORDEN,:LINEA,:OPERARIO,:TAREA,:INICIO,:FIN,:MOTIVO,:USUARIO)');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := AParte.Linea;
    oConsulta.ParamByName('OPERARIO').AsString := AParte.Operario;
    oConsulta.ParamByName('TAREA').AsString := AParte.Tarea;
    oConsulta.ParamByName('INICIO').AsDateTime := AParte.Inicio;
    oConsulta.ParamByName('FIN').DataType := ftDateTime;
    if AParte.Fin > 0 then
      oConsulta.ParamByName('FIN').AsDateTime := AParte.Fin
    else
      oConsulta.ParamByName('FIN').Clear;
    oConsulta.ParamByName('MOTIVO').AsString := AParte.Motivo;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID()';
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioTiemposOrden.AnularParte(AOrden: Int64;
  const AParte: TParteTiempoOrden);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('UPDATE fza_reparaciones_tiempos ' +
    'SET ESANULADO_RCT=''S'', MOTIVO_RCT=:MOTIVO,' +
    'INSTANTE_MODIF=NOW(),USUARIO_MODIF=:USUARIO ' +
    'WHERE ID_RCT=:ID AND ID_GAR_RCT=:ORDEN ' +
    'AND ID_GARLIN_RCT=:LINEA AND ESANULADO_RCT=''N''');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AParte.Id;
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('LINEA').AsLargeInt := AParte.Linea;
    oConsulta.ParamByName('MOTIVO').AsString := AParte.Motivo;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EArgumentException.Create(SCircuitoConflicto);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioTiemposOrden.Registrar(AOrden: Int64;
  const AParte: TParteTiempoOrden): Int64;
var
  iId: Int64;
begin
  ValidarTiempoOrden(AParte);
  iId := 0;
  Transaccion(
    procedure
    var
      oLinea: TUniQuery;
    begin
      ExigirOperario(AParte.Operario);
      oLinea := BloquearLinea(AOrden, AParte.Linea,
        LINEA_REPARACION_MANO_OBRA);
      try
        ExigirSinSolape(AParte);
        if AParte.Id > 0 then
          AnularParte(AOrden, AParte);
        iId := InsertarParte(AOrden, AParte);
        Historial(AOrden, AParte.Linea, 'TIEMPO',
          Format('%d -> %d. %s', [AParte.Id, iId, AParte.Motivo]));
      finally
        FreeAndNil(oLinea);
      end;
    end);
  Result := iId;
end;

procedure TRepositorioTiemposOrden.Pausar(AOrden, AParte: Int64);
begin
  Transaccion(
    procedure
    var
      oConsulta: TUniQuery;
    begin
      BloquearOrden(AOrden);
      oConsulta := Consulta('UPDATE fza_reparaciones_tiempos ' +
        'SET INSTANTE_FIN_RCT=NOW(),INSTANTE_MODIF=NOW(),' +
        'USUARIO_MODIF=:USUARIO WHERE ID_RCT=:ID AND ID_GAR_RCT=:ORDEN ' +
        'AND ESANULADO_RCT=''N'' AND INSTANTE_FIN_RCT IS NULL ' +
        'AND INSTANTE_INICIO_RCT<NOW()');
      try
        oConsulta.ParamByName('ID').AsLargeInt := AParte;
        oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
        oConsulta.ParamByName('USUARIO').AsString := FUsuario;
        oConsulta.Execute;
        if oConsulta.RowsAffected <> 1 then
          raise EArgumentException.Create(SCircuitoConflicto);
        Historial(AOrden, 0, 'PAUSA', IntToStr(AParte));
      finally
        FreeAndNil(oConsulta);
      end;
    end);
end;

end.
