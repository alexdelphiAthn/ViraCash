{******************************************************************************}
{  Módulo:       UniDataReposicionAutomatica                                  }
{    Tipo:       Persistencia UniDAC                                          }
{   Fecha:       18/11/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Reserva estable de partidas por recepción, sin convertir el artículo.      }
{******************************************************************************}
unit UniDataReposicionAutomatica;

interface

uses
  Data.DB, Uni, inLibParametrosIntf, inLibTrazabilidad;

type
  TRecepcionReposicion = record
    TipoDocumento: string;
    Serie: string;
    Numero: string;
    Sku: string;
    Temporada: string;
    Usuario: string;
  end;

function EsPartidaReposicion(AConexion: TUniConnection;
  const ASku, ALote: string): Boolean;
function EmpresaReposicionActiva(AConexion: TUniConnection;
  const AEmpresa: string): Boolean;
function HayPartidasReposicion(AConexion: TUniConnection): Boolean;
function ActivacionVisualReposicion(AConexion: TUniConnection;
  const AParametros: IParametros): TActivacionTrazabilidad;
function PrepararPartidaReposicion(AConexion: TUniConnection;
  const ARecepcion: TRecepcionReposicion): string;
procedure PrepararReposicionLinea(AConexion: TUniConnection;
  ALinea: TDataSet; const ASufijo, AUsuario: string;
  const AParametros: IParametros);
procedure PrepararReposicionMovimiento(AProcedimiento: TUniStoredProc;
  var ALote: string);

implementation

uses
  System.SysUtils, UniDataCodigosBarrasLote,
  UniDataAppParamRepositorio, inLibAppParamPersistenciaIntf;

function EsPartidaReposicion(AConexion: TUniConnection;
  const ASku, ALote: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if (Trim(ASku) <> '') and (Trim(ALote) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 FROM fza_articulos_lotes WHERE ' +
        'CODIGO_UNIDAD_LOT = :SKU AND LOTE_LOT = :LOTE ' +
        'AND ESREPOSICION_LOT = ''S''';
      oConsulta.ParamByName('SKU').AsString := ASku;
      oConsulta.ParamByName('LOTE').AsString := ALote;
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function EmpresaReposicionActiva(AConexion: TUniConnection;
  const AEmpresa: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM fza_empresas ' +
      'WHERE CODIGO_EMP_EMP = :EMPRESA AND ESLOTES_REPOSICION_EMP = ''S''';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function HayPartidasReposicion(AConexion: TUniConnection): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_empresas WHERE ESLOTES_REPOSICION_EMP = ''S'' ' +
      'UNION ALL SELECT 1 FROM fza_articulos_lotes ' +
      'WHERE ESREPOSICION_LOT = ''S'' LIMIT 1';
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function ActivacionVisualReposicion(AConexion: TUniConnection;
  const AParametros: IParametros): TActivacionTrazabilidad;
begin
  Result := TActivacionTrazabilidad.Leer(AParametros);
  if HayPartidasReposicion(AConexion) then
    Result.Lotes := True;
end;

function PrepararPartidaReposicion(AConexion: TUniConnection;
  const ARecepcion: TRecepcionReposicion): string;
var
  oReserva: TUniStoredProc;
  EsTransaccionPropia: Boolean;
begin
  oReserva := TUniStoredProc.Create(nil);
  EsTransaccionPropia := not AConexion.InTransaction;
  try
    oReserva.Connection := AConexion;
    oReserva.StoredProcName := 'PRC_FZA_REPOSICION_PREPARAR';
    oReserva.Params.CreateParam(ftString, 'p_TIPO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_SKU', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_TEMPORADA', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_LOTE', ptOutput);
    oReserva.ParamByName('p_TIPO').AsString := ARecepcion.TipoDocumento;
    oReserva.ParamByName('p_SERIE').AsString := ARecepcion.Serie;
    oReserva.ParamByName('p_NUMERO').AsString := ARecepcion.Numero;
    oReserva.ParamByName('p_SKU').AsString := ARecepcion.Sku;
    oReserva.ParamByName('p_TEMPORADA').AsString := ARecepcion.Temporada;
    oReserva.ParamByName('p_USUARIO').AsString := ARecepcion.Usuario;
    if EsTransaccionPropia then
      AConexion.StartTransaction;
    try
      oReserva.ExecProc;
      Result := oReserva.ParamByName('p_LOTE').AsString;
      if Result <> '' then
        AsegurarCodigoBarrasLote(AConexion, ARecepcion.Sku, Result,
          ARecepcion.Usuario);
      if EsTransaccionPropia then
        AConexion.Commit;
    except
      if EsTransaccionPropia and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oReserva);
  end;
end;

procedure PrepararReposicionLinea(AConexion: TUniConnection;
  ALinea: TDataSet; const ASufijo, AUsuario: string;
  const AParametros: IParametros);
var
  sCabecera, sTipo, sLote: string;
  Recepcion: TRecepcionReposicion;
begin
  sCabecera := '';
  sTipo := '';
  if ASufijo = 'ALBCLIN' then
  begin
    sCabecera := 'ALBC';
    sTipo := 'AC';
  end
  else if ASufijo = 'FACCLIN' then
  begin
    sCabecera := 'FACC';
    sTipo := 'FP';
  end;
  // La cabecera reserva una sola identidad, también al editar cantidades.
  if (sTipo <> '') and (ALinea.State in dsEditModes) and
     (ALinea.FieldByName('CANTIDAD_' + ASufijo).AsFloat > 0) then
  begin
    Recepcion := Default(TRecepcionReposicion);
    Recepcion.TipoDocumento := sTipo;
    Recepcion.Serie := ALinea.FieldByName(
      'SERIE_' + sCabecera + '_' + ASufijo).AsString;
    Recepcion.Numero := ALinea.FieldByName(
      'NUMERO_' + sCabecera + '_' + ASufijo).AsString;
    Recepcion.Sku :=
      ALinea.FieldByName('CODIGO_UNIDAD_' + ASufijo).AsString;
    Recepcion.Temporada := AParametros.GetString('appTemporadaDefecto');
    Recepcion.Usuario := AUsuario;
    sLote := PrepararPartidaReposicion(AConexion, Recepcion);
    if sLote <> '' then
      ALinea.FieldByName('LOTE_' + ASufijo).AsString := sLote;
  end;
end;

function TemporadaUsuario(AConexion: TUniConnection;
  const AUsuario: string): string;
var
  oConsulta: TUniQuery;
  sGrupo: string;
  Valores: TValoresPerfilAppParam;
  Valor: TValorPerfilAppParam;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT GRUPO_USU FROM fza_usuarios ' +
      'WHERE USUARIO_USU = :USUARIO';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Open;
    sGrupo := oConsulta.Fields[0].AsString;
  finally
    FreeAndNil(oConsulta);
  end;
  Result := '';
  Valores := CrearRepositorioAppParamUniDAC(AConexion).CargarValores(
    AUsuario, sGrupo, 'frmMtoAppParam');
  for Valor in Valores do
    if SameText(Valor.Subclave, 'appTemporadaDefecto') then
      Result := Valor.Valor;
end;

function EsRecepcionAutomatica(AProcedimiento: TUniStoredProc;
  const ATipo: string): Boolean;
var
  oConsulta: TUniQuery;
  sSufijo, sTabla: string;
begin
  sSufijo := 'ALBC';
  sTabla := 'fza_albaranes_compra';
  if ATipo = 'FP' then
  begin
    sSufijo := 'FACC';
    sTabla := 'fza_facturas_compra';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AProcedimiento.Connection;
    oConsulta.SQL.Text := 'SELECT 1 FROM ' + sTabla + ' D ' +
      'JOIN fza_empresas E ON E.CODIGO_EMP_EMP = D.CODIGO_EMP_' +
      sSufijo + ' WHERE D.SERIE_' + sSufijo + ' = :SERIE AND D.NUMERO_' +
      sSufijo + ' = :NUMERO AND D.ESREPOSICION_AUTO_' + sSufijo +
      ' = ''S'' AND E.ESLOTES_REPOSICION_EMP = ''S''';
    oConsulta.ParamByName('SERIE').AsString :=
      AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString;
    oConsulta.ParamByName('NUMERO').AsString :=
      AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure GrabarPartidaLineas(AProcedimiento: TUniStoredProc;
  const ALote, ATipo: string);
var
  sSufijo, sTabla: string;
  oConsulta: TUniQuery;
begin
  sSufijo := 'ALBC';
  sTabla := 'fza_albaranes_compra_lineas';
  if ATipo = 'FP' then
  begin
    sSufijo := 'FACC';
    sTabla := 'fza_facturas_compra_lineas';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AProcedimiento.Connection;
    oConsulta.SQL.Text := 'UPDATE ' + sTabla + ' SET LOTE_' +
      sSufijo + 'LIN = :LOTE WHERE SERIE_' + sSufijo + '_' +
      sSufijo + 'LIN = :SERIE AND NUMERO_' + sSufijo + '_' +
      sSufijo + 'LIN = :NUMERO AND CODIGO_UNIDAD_' + sSufijo +
      'LIN = :SKU AND COALESCE(LOTE_' + sSufijo + 'LIN, '''') = ''''';
    oConsulta.ParamByName('LOTE').AsString := ALote;
    oConsulta.ParamByName('SERIE').AsString :=
      AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString;
    oConsulta.ParamByName('NUMERO').AsString :=
      AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString;
    oConsulta.ParamByName('SKU').AsString :=
      AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure PrepararReposicionMovimiento(AProcedimiento: TUniStoredProc;
  var ALote: string);
var
  sTipo: string;
  Recepcion: TRecepcionReposicion;
begin
  sTipo := AProcedimiento.ParamByName('p_TIPO_DOC_MOV').AsString;
  if (Trim(ALote) = '') and ((sTipo = 'AC') or (sTipo = 'FP')) and
     (AProcedimiento.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString = 'E') and
     (AProcedimiento.ParamByName('p_CANTIDAD_MOV').AsFloat > 0) and
     EsRecepcionAutomatica(AProcedimiento, sTipo) then
  begin
    Recepcion := Default(TRecepcionReposicion);
    Recepcion.TipoDocumento := sTipo;
    Recepcion.Serie :=
      AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString;
    Recepcion.Numero :=
      AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString;
    Recepcion.Sku :=
      AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString;
    Recepcion.Usuario := AProcedimiento.ParamByName('p_USUARIO').AsString;
    Recepcion.Temporada := TemporadaUsuario(AProcedimiento.Connection,
      Recepcion.Usuario);
    ALote := PrepararPartidaReposicion(AProcedimiento.Connection, Recepcion);
    if ALote <> '' then
      GrabarPartidaLineas(AProcedimiento, ALote, sTipo);
  end;
end;

end.
