{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMovimientosAlmacenRecalculo                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerta única al recálculo cronológico de stock y PMP.                     }
{******************************************************************************}
unit UniDataMovimientosAlmacenRecalculo;

interface

uses
  Uni;

procedure RecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string);
procedure FecharYRecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime);
procedure FecharYEncolarMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime;
  const AMotivo, AUsuario: string);
procedure EncolarORecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero, AMotivo, AUsuario: string);
procedure RecalcularMovimientosOperacion(
  AConexion: TUniConnection;
  const AAlmacenDocumento, ACaja, AOperacion: string);
function EncolarMovimientosRecalculo(
  AConexion: TUniConnection;
  const ANumerosMovimiento: array of string;
  const AMotivo, AUsuario: string): Boolean;
function MovimientosCajaRequierenRecalculo(
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string;
  const ANumerosMovimiento: array of string): Boolean;
procedure RecalcularMovimiento(
  AConexion: TUniConnection;
  const ANumeroMovimiento: string);

implementation

uses
  System.SysUtils,
  Data.DB,
  DBAccess,
  inLibErroresBBDD;

const
  CInterbloqueoMotor = 1213;

// Un interbloqueo deshace la transaccion entera en el motor: tragarlo y
// seguir dejaria el resto de la operacion en autocommit, aunque UniDAC
// siga creyendo que hay transaccion (FZ-ISSUE-146).
function ErrorAnulaTransaccion(AConexion: TUniConnection;
  E: Exception): Boolean;
begin
  Result := AConexion.InTransaction and
    (((E is EBloqueoBBDDTemporal) and
      (EBloqueoBBDDTemporal(E).Codigo = CInterbloqueoMotor)) or
     ((E is EDAError) and
      (EDAError(E).ErrorCode = CInterbloqueoMotor)));
end;

function ProcedimientoDisponible(
  AConexion: TUniConnection;
  const ANombre: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL ' +
      '  FROM information_schema.ROUTINES ' +
      ' WHERE ROUTINE_SCHEMA = DATABASE() ' +
      '   AND ROUTINE_TYPE = ''PROCEDURE'' ' +
      '   AND ROUTINE_NAME = :NOMBRE';
    Consulta.ParamByName('NOMBRE').AsString := ANombre;
    Consulta.Open;
    Result := Consulta.FieldByName('TOTAL').AsInteger > 0;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearListaParametros(
  const APrefijo: string;
  ACantidad: Integer): string;
var
  Indice: Integer;
begin
  Result := '';
  for Indice := 0 to ACantidad - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + ':' + APrefijo + IntToStr(Indice);
  end;
end;

procedure AsignarNumerosMovimiento(
  AConsulta: TUniQuery;
  const APrefijo: string;
  const ANumerosMovimiento: array of string);
var
  Indice: Integer;
begin
  for Indice := Low(ANumerosMovimiento) to High(ANumerosMovimiento) do
    AConsulta.ParamByName(
      APrefijo + IntToStr(Indice)).AsString :=
        Trim(ANumerosMovimiento[Indice]);
end;

function NumerosMovimientoValidos(
  const ANumerosMovimiento: array of string): Boolean;
var
  Indice: Integer;
  IndiceAnterior: Integer;
begin
  Result := Length(ANumerosMovimiento) > 0;
  Indice := Low(ANumerosMovimiento);
  while Result and (Indice <= High(ANumerosMovimiento)) do
  begin
    Result := Trim(ANumerosMovimiento[Indice]) <> '';
    IndiceAnterior := Low(ANumerosMovimiento);
    while Result and (IndiceAnterior < Indice) do
    begin
      Result := not SameText(
        Trim(ANumerosMovimiento[IndiceAnterior]),
        Trim(ANumerosMovimiento[Indice]));
      Inc(IndiceAnterior);
    end;
    Inc(Indice);
  end;
end;

function MovimientosNoSonVentasLocales(
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string;
  const ANumerosMovimiento: array of string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL, ' +
      '       IFNULL(SUM(CASE WHEN ' +
      '         m.ESACTIVO_MOV = ''S'' ' +
      '         AND m.TIPO_DOC_MOV = ''VE'' ' +
      '         AND m.TIPO_MOV = ''S'' ' +
      '         AND IFNULL(m.CANTIDAD_MOV, 0) > 0 ' +
      '         AND m.FECHA_MOV IS NOT NULL ' +
      '         AND m.INSTANTE_ALTA IS NOT NULL ' +
      '         AND IFNULL(m.CODIGO_EMP_MOV, '''') = :EMPRESA ' +
      '         AND IFNULL(m.CODIGO_ALM_MOV, '''') = :ALMACEN ' +
      '         AND IFNULL(m.CODIGO_ALM_DOC_MOV, '''') = :ALMACEN ' +
      '         AND IFNULL(m.CODIGO_CAJA_DOC_MOV, '''') = :CAJA ' +
      '         AND IFNULL(m.NUMERO_OPERACION_DOC_MOV, '''') = ' +
      '             :OPERACION ' +
      '         AND IFNULL(m.CODIGO_ALM_CONTRA_MOV, '''') = '''' ' +
      '         AND IFNULL(m.CODIGO_UNIDAD_MOV, '''') <> '''' ' +
      '       THEN 0 ELSE 1 END), 0) AS INSEGUROS ' +
      '  FROM fza_movimientos_almacen m ' +
      ' WHERE m.NUMERO_MOV IN (' +
      CrearListaParametros('MOV', Length(ANumerosMovimiento)) + ')';
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('CAJA').AsString := ACaja;
    Consulta.ParamByName('OPERACION').AsString := AOperacion;
    AsignarNumerosMovimiento(
      Consulta, 'MOV', ANumerosMovimiento);
    Consulta.Open;
    Result :=
      (Consulta.FieldByName('TOTAL').AsInteger <>
       Length(ANumerosMovimiento)) or
      (Consulta.FieldByName('INSEGUROS').AsInteger > 0);
  finally
    FreeAndNil(Consulta);
  end;
end;

function HayMovimientosPosteriores(
  AConexion: TUniConnection;
  const ANumerosMovimiento: array of string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT 1 AS REQUIERE ' +
      '  FROM fza_movimientos_almacen nuevo ' +
      '  JOIN fza_movimientos_almacen posterior ' +
      '    ON posterior.CODIGO_ALM_MOV = nuevo.CODIGO_ALM_MOV ' +
      '   AND posterior.CODIGO_UNIDAD_MOV = ' +
      '       nuevo.CODIGO_UNIDAD_MOV ' +
      '   AND posterior.ESACTIVO_MOV = ''S'' ' +
      '   AND posterior.NUMERO_MOV NOT IN (' +
      CrearListaParametros('OTRO', Length(ANumerosMovimiento)) + ') ' +
      ' WHERE nuevo.NUMERO_MOV IN (' +
      CrearListaParametros('NUEVO', Length(ANumerosMovimiento)) + ') ' +
      '   AND ( ' +
      '     IFNULL(posterior.FECHA_MOV, ' +
      '       ''1000-01-01 00:00:00'') > ' +
      '     IFNULL(nuevo.FECHA_MOV, ''1000-01-01 00:00:00'') ' +
      '     OR (IFNULL(posterior.FECHA_MOV, ' +
      '           ''1000-01-01 00:00:00'') = ' +
      '         IFNULL(nuevo.FECHA_MOV, ''1000-01-01 00:00:00'') ' +
      '       AND IFNULL(posterior.INSTANTE_ALTA, ' +
      '           ''1000-01-01 00:00:00'') > ' +
      '         IFNULL(nuevo.INSTANTE_ALTA, ' +
      '           ''1000-01-01 00:00:00'')) ' +
      '     OR (IFNULL(posterior.FECHA_MOV, ' +
      '           ''1000-01-01 00:00:00'') = ' +
      '         IFNULL(nuevo.FECHA_MOV, ''1000-01-01 00:00:00'') ' +
      '       AND IFNULL(posterior.INSTANTE_ALTA, ' +
      '           ''1000-01-01 00:00:00'') = ' +
      '         IFNULL(nuevo.INSTANTE_ALTA, ' +
      '           ''1000-01-01 00:00:00'') ' +
      '       AND posterior.NUMERO_MOV > nuevo.NUMERO_MOV) ' +
      '   ) ' +
      ' LIMIT 1';
    AsignarNumerosMovimiento(
      Consulta, 'OTRO', ANumerosMovimiento);
    AsignarNumerosMovimiento(
      Consulta, 'NUEVO', ANumerosMovimiento);
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

function StockNoPermiteOmitirRecalculo(
  AConexion: TUniConnection;
  const ANumerosMovimiento: array of string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT 1 AS REQUIERE ' +
      '  FROM ( ' +
      '    SELECT DISTINCT m.CODIGO_ALM_MOV AS ALMACEN, ' +
      '           m.CODIGO_UNIDAD_MOV AS SKU ' +
      '      FROM fza_movimientos_almacen m ' +
      '     WHERE m.NUMERO_MOV IN (' +
      CrearListaParametros('STOCK', Length(ANumerosMovimiento)) + ') ' +
      '  ) claves ' +
      '  LEFT JOIN fza_articulos_stockactual stock ' +
      '    ON stock.CODIGO_ALM_STK = claves.ALMACEN ' +
      '   AND stock.CODIGO_UNIDAD_STK = claves.SKU ' +
      ' GROUP BY claves.ALMACEN, claves.SKU ' +
      'HAVING COUNT(stock.CODIGO_ALM_STK) <> 1 ' +
      '    OR MAX(IF(IFNULL(stock.LOTE_STK, '''') = '''', 0, 1)) <> 0 ' +
      '    OR MIN(stock.CANTIDAD_STK) IS NULL ' +
      '    OR MIN(stock.CANTIDAD_STK) < 0 ' +
      ' LIMIT 1';
    AsignarNumerosMovimiento(
      Consulta, 'STOCK', ANumerosMovimiento);
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CosteVentaDesalineado(
  AConexion: TUniConnection;
  const ANumerosMovimiento: array of string): Boolean;
var
  Consulta: TUniQuery;
begin
  // El alta ya ha copiado stockactual al movimiento: contrastar con el
  // anterior ajeno a esta operación, antes de aceptar esa semilla de PMP.
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT 1 AS REQUIERE FROM fza_movimientos_almacen M ' +
      ' WHERE M.NUMERO_MOV IN (' +
      CrearListaParametros('NUEVO', Length(ANumerosMovimiento)) + ') ' +
      ' AND NOT (ROUND(M.PRECIO_MEDIO_MOV, 4) <=> (' +
      '   SELECT ROUND(P.PRECIO_MEDIO_MOV, 4) ' +
      '     FROM fza_movimientos_almacen P ' +
      '    WHERE P.CODIGO_ALM_MOV = M.CODIGO_ALM_MOV ' +
      '      AND P.CODIGO_UNIDAD_MOV = M.CODIGO_UNIDAD_MOV ' +
      '      AND P.ESACTIVO_MOV = ''S'' ' +
      '      AND P.NUMERO_MOV NOT IN (' +
      CrearListaParametros('OTRO', Length(ANumerosMovimiento)) + ') ' +
      '    ORDER BY P.FECHA_MOV DESC, P.INSTANTE_ALTA DESC, ' +
      '             P.NUMERO_MOV DESC LIMIT 1)) LIMIT 1';
    AsignarNumerosMovimiento(Consulta, 'NUEVO', ANumerosMovimiento);
    AsignarNumerosMovimiento(Consulta, 'OTRO', ANumerosMovimiento);
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

function MovimientosCajaRequierenRecalculo(
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string;
  const ANumerosMovimiento: array of string): Boolean;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := Length(ANumerosMovimiento) > 0;
  if Result then
  begin
    Result :=
      (not AConexion.InTransaction) or
      (Trim(AEmpresa) = '') or
      (Trim(AAlmacen) = '') or
      (Trim(ACaja) = '') or
      (Trim(AOperacion) = '') or
      (not NumerosMovimientoValidos(ANumerosMovimiento));
    if not Result then
      Result := MovimientosNoSonVentasLocales(
        AConexion, AEmpresa, AAlmacen, ACaja, AOperacion,
        ANumerosMovimiento);
    if not Result then
      Result := HayMovimientosPosteriores(
        AConexion, ANumerosMovimiento);
    if not Result then
      Result := StockNoPermiteOmitirRecalculo(
        AConexion, ANumerosMovimiento);
    if not Result then
      Result := CosteVentaDesalineado(AConexion, ANumerosMovimiento);
  end;
end;

procedure FecharMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime);
var
  Consulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'UPDATE fza_movimientos_almacen ' +
      '   SET FECHA_MOV = :FECHA ' +
      ' WHERE TIPO_DOC_MOV = :TIPO ' +
      '   AND SERIE_DOC_MOV = :SERIE ' +
      '   AND NUMERO_DOC_MOV = :NUMERO';
    Consulta.ParamByName('FECHA').AsDateTime := AFecha;
    Consulta.ParamByName('TIPO').AsString := ATipo;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

function RecalculosDiferidosActivosUsuario(
  AConexion: TUniConnection;
  const AUsuario: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  if Trim(AUsuario) <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT P.VALUE_USUPER ' +
        '  FROM fza_usuarios U ' +
        '  JOIN fza_usuarios_perfiles P ' +
        '    ON P.USUARIO_GRUPO_USUPER IN ' +
        '       (U.USUARIO_USU, U.GRUPO_USU, ''Todos'') ' +
        ' WHERE U.USUARIO_USU = :USUARIO ' +
        '   AND P.KEY_USUPER = ''frmMtoCajaParam'' ' +
        '   AND P.SUBKEY_USUPER = ' +
        '       ''vgerAplazarRecalculoMovimientos'' ' +
        '   AND P.TYPE_BLOB_USUPER IS NULL ' +
        ' ORDER BY CASE P.USUARIO_GRUPO_USUPER ' +
        '            WHEN U.USUARIO_USU THEN 1 ' +
        '            WHEN U.GRUPO_USU THEN 2 ' +
        '            ELSE 3 ' +
        '          END ' +
        ' LIMIT 1';
      Consulta.ParamByName('USUARIO').AsString := AUsuario;
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        Result := SameText(
          Trim(Consulta.FieldByName('VALUE_USUPER').AsString),
          'True') or
          (Trim(Consulta.FieldByName('VALUE_USUPER').AsString) = '1');
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function EncolarDocumentoRecalculo(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero, AMotivo, AUsuario: string): Boolean;
var
  Procedimiento: TUniStoredProc;
begin
  Result := AConexion.InTransaction and
    ProcedimientoDisponible(
      AConexion,
      'PRC_FZA_MOVIMIENTOS_RECALCULO_ENCOLAR_DOCUMENTO');
  if Result then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULO_ENCOLAR_DOCUMENTO';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_TIPO', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_MOTIVO', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
      Procedimiento.ParamByName('p_TIPO').AsString := ATipo;
      Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
      Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
      Procedimiento.ParamByName('p_MOTIVO').AsString := AMotivo;
      Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
      try
        Procedimiento.ExecProc;
      except
        // Igual que en el encolado por movimiento: si la cola falla se
        // recalcula sincronamente en vez de dejar el stock desfasado.
        on E: Exception do
        begin
          if ErrorAnulaTransaccion(AConexion, E) then
            raise;
          Result := False;
        end;
      end;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

procedure FecharYEncolarMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime;
  const AMotivo, AUsuario: string);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FecharMovimientosDocumento(
    AConexion, ATipo, ASerie, ANumero, AFecha);
  EncolarORecalcularMovimientosDocumento(
    AConexion, ATipo, ASerie, ANumero, AMotivo, AUsuario);
end;

procedure EncolarORecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero, AMotivo, AUsuario: string);
var
  Encolado: Boolean;
begin
  // Con "Aplazar recálculos de stock" el documento va a la cola del lote;
  // sin él, o si la cola falla, se recalcula aquí mismo.
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Encolado := False;
  if RecalculosDiferidosActivosUsuario(AConexion, AUsuario) then
  begin
    Encolado := EncolarDocumentoRecalculo(
      AConexion, ATipo, ASerie, ANumero, AMotivo, AUsuario);
  end;
  if not Encolado then
  begin
    RecalcularMovimientosDocumento(
      AConexion, ATipo, ASerie, ANumero);
  end;
end;

procedure FecharYRecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FecharMovimientosDocumento(
    AConexion, ATipo, ASerie, ANumero, AFecha);
  RecalcularMovimientosDocumento(AConexion, ATipo, ASerie, ANumero);
end;

function EncolarMovimientosRecalculo(
  AConexion: TUniConnection;
  const ANumerosMovimiento: array of string;
  const AMotivo, AUsuario: string): Boolean;
var
  Indice: Integer;
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := AConexion.InTransaction and
    (Length(ANumerosMovimiento) > 0) and
    ProcedimientoDisponible(
      AConexion,
      'PRC_FZA_MOVIMIENTOS_RECALCULO_ENCOLAR');
  for Indice := Low(ANumerosMovimiento) to High(ANumerosMovimiento) do
  begin
    if Trim(ANumerosMovimiento[Indice]) = '' then
      raise EArgumentException.Create('ANumerosMovimiento');
  end;
  if Result then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULO_ENCOLAR';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(
        ftString, 'p_NUMERO_MOV', ptInput);
      Procedimiento.Params.CreateParam(
        ftString, 'p_MOTIVO', ptInput);
      Procedimiento.Params.CreateParam(
        ftString, 'p_USUARIO', ptInput);
      try
        for Indice := Low(ANumerosMovimiento) to
                      High(ANumerosMovimiento) do
        begin
          Procedimiento.ParamByName('p_NUMERO_MOV').AsString :=
            ANumerosMovimiento[Indice];
          Procedimiento.ParamByName('p_MOTIVO').AsString := AMotivo;
          Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
          Procedimiento.ExecProc;
        end;
      except
        // Decision explicita ante un fallo de la cola: aplazar es solo
        // una optimizacion, asi que se devuelve False y el llamante
        // recalcula aqui mismo. Nunca se deja pasar la operacion sin
        // recalcular: eso dejaria las existencias desfasadas en
        // silencio. Si el recalculo sincrono tambien falla, su
        // excepcion sube y bloquea la operacion.
        on E: Exception do
        begin
          if ErrorAnulaTransaccion(AConexion, E) then
            raise;
          Result := False;
        end;
      end;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

procedure RecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string);
var
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if ProcedimientoDisponible(
    AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_DOCUMENTO') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_DOCUMENTO';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_TIPO', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      Procedimiento.ParamByName('p_TIPO').AsString := ATipo;
      Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
      Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

procedure RecalcularMovimientosOperacion(
  AConexion: TUniConnection;
  const AAlmacenDocumento, ACaja, AOperacion: string);
var
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(AOperacion) = '' then
    raise EArgumentException.Create('AOperacion');
  // El numero de operacion es un contador de cada tienda y caja y se
  // repite entre tiendas: por numero solo, la venta recalcularia tambien
  // los articulos de las operaciones homonimas de las demas. Sin almacen
  // o caja, o en una base sin el procedimiento, se recalcula por numero.
  if (Trim(AAlmacenDocumento) <> '') and (Trim(ACaja) <> '') and
     ProcedimientoDisponible(
       AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION_CAJA') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION_CAJA';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(
        ftString, 'p_ALMACEN_DOCUMENTO', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_CAJA', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_OPERACION', ptInput);
      Procedimiento.ParamByName('p_ALMACEN_DOCUMENTO').AsString :=
        AAlmacenDocumento;
      Procedimiento.ParamByName('p_CAJA').AsString := ACaja;
      Procedimiento.ParamByName('p_OPERACION').AsString := AOperacion;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end
  else if ProcedimientoDisponible(
    AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_OPERACION', ptInput);
      Procedimiento.ParamByName('p_OPERACION').AsString := AOperacion;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

procedure RecalcularMovimiento(
  AConexion: TUniConnection;
  const ANumeroMovimiento: string);
var
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(ANumeroMovimiento) = '' then
    raise EArgumentException.Create('ANumeroMovimiento');
  if ProcedimientoDisponible(
    AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_MOVIMIENTO') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_MOVIMIENTO';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      Procedimiento.ParamByName('p_NUMERO').AsString := ANumeroMovimiento;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

end.
