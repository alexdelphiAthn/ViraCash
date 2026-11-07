{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCodigosBarrasSesion                                    }
{  Versión:      1.0.0                                                         }
{  Fecha:        06/11/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Códigos de barras de fabricante en sesiones de compra.        }
{******************************************************************************}
unit UniDataCodigosBarrasSesion;

interface

uses
  Uni, inLibCodigosBarrasSesion;

function LeerBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string): TCombinacionesBarrasSesion;
procedure GuardarBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario: string;
  const AValores, AAnteriores: TCombinacionesBarrasSesion);
function GenerarBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario, APrefijo: string): Integer;
function LeerCodigoBarrasCelda(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea, AFila, APivot: Integer): string;
procedure AsociarBarrasSkuSesion(AConexion: TUniConnection;
  const ACodigo, ASku, AUsuario: string);
procedure BorrarBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer = -1);
function SkuTieneCodigoBarras(AConexion: TUniConnection;
  const ASku: string): Boolean;
function BarrasSesionDisponibles(AConexion: TUniConnection): Boolean;
function SiguienteSecuenciaBarrasSesion(AConexion: TUniConnection;
  const APrefijo: string): Int64;

implementation

uses
  System.SysUtils, Data.DB, inLibEAN13, inLibMsgBarrasSesion,
  inLibGeneracionSkus;

const
  SQL_COMBINACIONES =
    'SELECT L.LINEA_SESLIN AS LINEA, ' +
    ' CASE WHEN L.TIPO_LINEA_SESLIN = ''ESCALAR'' THEN 0 ' +
    ' ELSE COALESCE(C.ID_FILA_SES_SESCEL, 0) END AS FILA, ' +
    ' CASE WHEN L.TIPO_LINEA_SESLIN = ''ESCALAR'' THEN 0 ' +
    ' ELSE COALESCE(C.ID_AV_PIVOT_SESCEL, 0) END AS PIVOT, ' +
    ' CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' THEN ' +
    ' L.CODIGO_ART_REUSAR_SESLIN ELSE ' +
    ' L.CODIGO_ART_TENTATIVO_SESLIN END AS ARTICULO, ' +
    ' L.DESCRIPCION_SESLIN AS DESCRIPCION, ' +
    ' COALESCE(L.REF_PRV_SESLIN, '''') AS MODELO_PROVEEDOR, ' +
    ' COALESCE(NULLIF((SELECT GROUP_CONCAT(V.AV ORDER BY V.ID_AV ' +
    ' SEPARATOR ''/'') FROM fza_compras_sesiones_lineas_filas_atr F ' +
    ' JOIN fza_atributos_valores V ON V.ID_AV = F.ID_AV_SESFILAT ' +
    ' WHERE F.SERIE_SES_SESFILAT = L.SERIE_SES_SESLIN ' +
    ' AND F.NUMERO_SES_SESFILAT = L.NUMERO_SES_SESLIN ' +
    ' AND F.LINEA_SES_SESFILAT = L.LINEA_SESLIN ' +
    ' AND F.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL), ''''), ' +
    ' L.COLOR_TEXTO_SESLIN, '''') AS COLOR, ' +
    ' COALESCE(L.PESTANA_TEXTO_SESLIN, '''') AS PESTANA, ' +
    ' COALESCE(VP.AV, '''') AS TALLA, ' +
    ' COALESCE(B.CODIGO_BARRAS_SESCB, '''') AS CODIGO ' +
    ' FROM fza_compras_sesiones_lineas L ' +
    ' LEFT JOIN fza_compras_sesiones_celdas C ' +
    ' ON C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN ' +
    ' AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN ' +
    ' AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
    ' AND L.TIPO_LINEA_SESLIN <> ''ESCALAR'' ' +
    ' LEFT JOIN fza_atributos_valores VP ' +
    ' ON VP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
    ' LEFT JOIN fza_compras_sesiones_codigos_barras B ' +
    ' ON B.SERIE_SES_SESCB = L.SERIE_SES_SESLIN ' +
    ' AND B.NUMERO_SES_SESCB = L.NUMERO_SES_SESLIN ' +
    ' AND B.LINEA_SES_SESCB = L.LINEA_SESLIN ' +
    ' AND B.ID_FILA_SES_SESCB = COALESCE(C.ID_FILA_SES_SESCEL, 0) ' +
    ' AND B.ID_AV_PIVOT_SESCB = COALESCE(C.ID_AV_PIVOT_SESCEL, 0) ' +
    ' WHERE L.SERIE_SES_SESLIN = :SERIE ' +
    ' AND L.NUMERO_SES_SESLIN = :NUMERO ' +
    ' AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    ' AND (L.TIPO_LINEA_SESLIN = ''ESCALAR'' ' +
    ' OR C.ID_AV_PIVOT_SESCEL IS NOT NULL) ' +
    ' GROUP BY L.LINEA_SESLIN, FILA, PIVOT, ARTICULO, DESCRIPCION, ' +
    ' COLOR, PESTANA, TALLA, CODIGO, MODELO_PROVEEDOR ' +
    ' ORDER BY L.LINEA_SESLIN, FILA, PIVOT';

procedure ParametrosSesion(AConsulta: TUniQuery;
  const ASerie, ANumero: string);
begin
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
end;

procedure CompletarBarrasCatalogo(q: TUniQuery;
  var AValores: TCombinacionesBarrasSesion); forward;

function LeerBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string): TCombinacionesBarrasSesion;
var
  q: TUniQuery;
  i: Integer;
begin
  Result := nil;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text := SQL_COMBINACIONES;
    ParametrosSesion(q, ASerie, ANumero);
    q.Open;
    while not q.Eof do
    begin
      i := Length(Result);
      SetLength(Result, i + 1);
      Result[i].Linea := q.FieldByName('LINEA').AsInteger;
      Result[i].IdFila := q.FieldByName('FILA').AsInteger;
      Result[i].IdPivot := q.FieldByName('PIVOT').AsInteger;
      Result[i].Articulo := q.FieldByName('ARTICULO').AsString;
      Result[i].ModeloProveedor :=
        q.FieldByName('MODELO_PROVEEDOR').AsString;
      Result[i].Descripcion := q.FieldByName('DESCRIPCION').AsString;
      Result[i].Color := q.FieldByName('COLOR').AsString;
      Result[i].Pestana := q.FieldByName('PESTANA').AsString;
      Result[i].Talla := q.FieldByName('TALLA').AsString;
      Result[i].Codigo := q.FieldByName('CODIGO').AsString;
      q.Next;
    end;
    q.Close;
    CompletarBarrasCatalogo(q, Result);
  finally
    FreeAndNil(q);
  end;
end;

procedure BloquearSesion(q: TUniQuery; const ASerie, ANumero: string);
begin
  q.SQL.Text := 'SELECT ESTADO_SES FROM fza_compras_sesiones ' +
    'WHERE SERIE_SES = :SERIE AND NUMERO_SES = :NUMERO FOR UPDATE';
  ParametrosSesion(q, ASerie, ANumero);
  q.Open;
  if q.IsEmpty or (q.Fields[0].AsString = 'CERRADA') then
    raise Exception.Create(SBarrasCerrada);
  q.Close;
end;

procedure ValidarCombinaciones(const AActuales,
  AValores: TCombinacionesBarrasSesion);
var
  i, j: Integer;
begin
  if Length(AActuales) <> Length(AValores) then
    raise Exception.Create(SBarrasCambios);
  for i := 0 to High(AValores) do
  begin
    if (AActuales[i].Linea <> AValores[i].Linea) or
      (AActuales[i].IdFila <> AValores[i].IdFila) or
      (AActuales[i].IdPivot <> AValores[i].IdPivot) or
      (AActuales[i].Articulo <> AValores[i].Articulo) or
      (AActuales[i].ModeloProveedor <> AValores[i].ModeloProveedor) or
      (AActuales[i].Color <> AValores[i].Color) or
      (AActuales[i].Pestana <> AValores[i].Pestana) or
      (AActuales[i].Talla <> AValores[i].Talla) then
      raise Exception.Create(SBarrasCambios);
    ValidarCodigoBarrasSesion(AValores[i].Codigo);
    if AValores[i].Codigo <> '' then
      for j := 0 to i - 1 do
        if SameText(AValores[i].Codigo, AValores[j].Codigo) then
          raise Exception.CreateFmt(SBarrasDuplicado, [AValores[i].Codigo]);
  end;
end;

procedure EscribirBarras(q: TUniQuery;
  const ASerie, ANumero, AUsuario: string;
  const AValor: TCombinacionBarrasSesion);
begin
  q.SQL.Text := 'INSERT INTO fza_compras_sesiones_codigos_barras ' +
    '(SERIE_SES_SESCB, NUMERO_SES_SESCB, LINEA_SES_SESCB, ' +
    'ID_FILA_SES_SESCB, ID_AV_PIVOT_SESCB, CODIGO_BARRAS_SESCB, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:SERIE, :NUMERO, :LINEA, :FILA, :PIVOT, :CODIGO, ' +
    'NOW(), :USUARIO, NOW(), :USUARIO)';
  ParametrosSesion(q, ASerie, ANumero);
  q.ParamByName('LINEA').AsInteger := AValor.Linea;
  q.ParamByName('FILA').AsInteger := AValor.IdFila;
  q.ParamByName('PIVOT').AsInteger := AValor.IdPivot;
  q.ParamByName('CODIGO').AsString := AValor.Codigo;
  q.ParamByName('USUARIO').AsString := AUsuario;
  q.ExecSQL;
end;

function SkuCombinacion(const v: TCombinacionBarrasSesion): string;
begin
  Result := v.Articulo;
  if v.Color <> '' then
    Result := Result + '/' + NormalizarValorCodigoSku(v.Color);
  if v.Pestana <> '' then
    Result := Result + '/' + NormalizarValorCodigoSku(v.Pestana);
  if v.Talla <> '' then
    Result := Result + '/' + NormalizarValorCodigoSku(v.Talla);
end;

procedure CompletarBarrasCatalogo(q: TUniQuery;
  var AValores: TCombinacionesBarrasSesion);
var
  i: Integer;
  sParametros: string;
begin
  sParametros := '';
  for i := 0 to High(AValores) do
    if AValores[i].Codigo = '' then
    begin
      if sParametros <> '' then
        sParametros := sParametros + ',';
      sParametros := sParametros + ':S' + IntToStr(i);
    end;
  if sParametros <> '' then
  begin
    q.SQL.Text := 'SELECT CODIGO_UNIDAD_CB, CODIGO_BARRAS_CB ' +
      'FROM fza_codigos_barras WHERE CODIGO_UNIDAD_CB IN (' +
      sParametros + ') ORDER BY ESPRINCIPAL_CB DESC, ID_CB';
    for i := 0 to High(AValores) do
      if AValores[i].Codigo = '' then
        q.ParamByName('S' + IntToStr(i)).AsString :=
          SkuCombinacion(AValores[i]);
    q.Open;
    while not q.Eof do
    begin
      for i := 0 to High(AValores) do
        if (AValores[i].Codigo = '') and
          SameText(SkuCombinacion(AValores[i]), q.Fields[0].AsString) then
          AValores[i].Codigo := q.Fields[1].AsString;
      q.Next;
    end;
    q.Close;
  end;
end;

procedure ValidarCatalogo(q: TUniQuery;
  const AValores: TCombinacionesBarrasSesion);
var
  i: Integer;
  sParametros, sCodigo, sSku: string;
begin
  sParametros := '';
  for i := 0 to High(AValores) do
    if AValores[i].Codigo <> '' then
    begin
      if sParametros <> '' then
        sParametros := sParametros + ',';
      sParametros := sParametros + ':C' + IntToStr(i);
    end;
  if sParametros <> '' then
  begin
    q.SQL.Text := 'SELECT CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB ' +
      'FROM fza_codigos_barras WHERE CODIGO_BARRAS_CB IN (' +
      sParametros + ')';
    for i := 0 to High(AValores) do
      if AValores[i].Codigo <> '' then
        q.ParamByName('C' + IntToStr(i)).AsString := AValores[i].Codigo;
    q.Open;
    while not q.Eof do
    begin
      sCodigo := q.Fields[0].AsString;
      sSku := q.Fields[1].AsString;
      for i := 0 to High(AValores) do
        if SameText(AValores[i].Codigo, sCodigo) and
          not SameText(SkuCombinacion(AValores[i]), sSku) then
          raise Exception.CreateFmt(SBarrasConflicto, [sCodigo, sSku]);
      q.Next;
    end;
    q.Close;
  end;
end;

procedure BorrarBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
var
  q: TUniQuery;
begin
  if BarrasSesionDisponibles(AConexion) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text := 'DELETE FROM fza_compras_sesiones_codigos_barras ' +
        'WHERE SERIE_SES_SESCB = :SERIE AND NUMERO_SES_SESCB = :NUMERO';
      if ALinea >= 0 then
        q.SQL.Add('AND LINEA_SES_SESCB = :LINEA');
      ParametrosSesion(q, ASerie, ANumero);
      if ALinea >= 0 then
        q.ParamByName('LINEA').AsInteger := ALinea;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure GuardarBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario: string;
  const AValores, AAnteriores: TCombinacionesBarrasSesion);
var
  q: TUniQuery;
  bPropia: Boolean;
  v: TCombinacionBarrasSesion;
  aActuales: TCombinacionesBarrasSesion;
  i: Integer;
begin
  if not BarrasSesionDisponibles(AConexion) then
    raise Exception.Create(SBarrasMigracion);
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    bPropia := not AConexion.InTransaction;
    if bPropia then
      AConexion.StartTransaction;
    try
      BloquearSesion(q, ASerie, ANumero);
      aActuales := LeerBarrasSesion(AConexion, ASerie, ANumero);
      ValidarCombinaciones(aActuales, AValores);
      ValidarCombinaciones(aActuales, AAnteriores);
      for i := 0 to High(aActuales) do
        if aActuales[i].Codigo <> AAnteriores[i].Codigo then
          raise Exception.Create(SBarrasCambios);
      ValidarCatalogo(q, AValores);
      q.SQL.Text := 'DELETE FROM fza_compras_sesiones_codigos_barras ' +
        'WHERE SERIE_SES_SESCB = :SERIE AND NUMERO_SES_SESCB = :NUMERO';
      ParametrosSesion(q, ASerie, ANumero);
      q.ExecSQL;
      for v in AValores do
        if v.Codigo <> '' then
          EscribirBarras(q, ASerie, ANumero, AUsuario, v);
      if bPropia then
        AConexion.Commit;
    except
      if bPropia then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function SiguienteEan(q: TUniQuery; const APrefijo: string): Int64;
begin
  q.SQL.Text := 'SELECT COALESCE(MAX(N), 0) + 1 AS SIGUIENTE FROM (' +
    'SELECT CAST(SUBSTRING(CODIGO_BARRAS_CB, :INICIO, :LONGITUD) ' +
    'AS UNSIGNED) AS N FROM fza_codigos_barras ' +
    'WHERE CODIGO_BARRAS_CB LIKE :PATRON ' +
    'AND LENGTH(CODIGO_BARRAS_CB) = 13 UNION ALL ' +
    'SELECT CAST(SUBSTRING(CODIGO_BARRAS_SESCB, :INICIO, :LONGITUD) ' +
    'AS UNSIGNED) AS N FROM fza_compras_sesiones_codigos_barras ' +
    'WHERE CODIGO_BARRAS_SESCB LIKE :PATRON ' +
    'AND LENGTH(CODIGO_BARRAS_SESCB) = 13) SECUENCIAS';
  q.ParamByName('INICIO').AsInteger := Length(APrefijo) + 1;
  q.ParamByName('LONGITUD').AsInteger := 12 - Length(APrefijo);
  q.ParamByName('PATRON').AsString := APrefijo + '%';
  q.Open;
  Result := q.Fields[0].AsLargeInt;
  q.Close;
end;

function GenerarBarrasSesion(AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario, APrefijo: string): Integer;
var
  q: TUniQuery;
  aValores: TCombinacionesBarrasSesion;
  aAnteriores: TCombinacionesBarrasSesion;
  sPrefijo, sBase: string;
  c: Char;
  n: Int64;
  i: Integer;
begin
  sPrefijo := Trim(APrefijo);
  if sPrefijo = '' then
    sPrefijo := '21';
  if Length(sPrefijo) > 11 then
    raise Exception.Create(SBarrasPrefijo);
  for c in sPrefijo do
    if not CharInSet(c, ['0'..'9']) then
      raise Exception.Create(SBarrasPrefijo);
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text := 'SELECT GET_LOCK(''VIRACASH_BARRAS_SESION'', 10)';
    q.Open;
    if q.Fields[0].AsInteger <> 1 then
      raise Exception.Create(SBarrasBloqueo);
    q.Close;
    try
      aValores := LeerBarrasSesion(AConexion, ASerie, ANumero);
      aAnteriores := Copy(aValores);
      n := SiguienteEan(q, sPrefijo);
      Result := 0;
      for i := 0 to High(aValores) do
        if aValores[i].Codigo = '' then
        begin
          sBase := sPrefijo + Format('%.*d', [12 - Length(sPrefijo), n]);
          if Length(sBase) <> 12 then
            raise Exception.Create(SBarrasPrefijo);
          aValores[i].Codigo := sBase + CalcularDigitoEAN13(sBase);
          Inc(n);
          Inc(Result);
        end;
      GuardarBarrasSesion(AConexion, ASerie, ANumero, AUsuario,
        aValores, aAnteriores);
    finally
      q.Close;
      q.SQL.Text := 'SELECT RELEASE_LOCK(''VIRACASH_BARRAS_SESION'')';
      q.Open;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function LeerCodigoBarrasCelda(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea, AFila, APivot: Integer): string;
var
  q: TUniQuery;
begin
  Result := '';
  if BarrasSesionDisponibles(AConexion) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text := 'SELECT CODIGO_BARRAS_SESCB ' +
        'FROM fza_compras_sesiones_codigos_barras ' +
        'WHERE SERIE_SES_SESCB = :SERIE AND NUMERO_SES_SESCB = :NUMERO ' +
        'AND LINEA_SES_SESCB = :LINEA AND ID_FILA_SES_SESCB = :FILA ' +
        'AND ID_AV_PIVOT_SESCB = :PIVOT';
      ParametrosSesion(q, ASerie, ANumero);
      q.ParamByName('LINEA').AsInteger := ALinea;
      q.ParamByName('FILA').AsInteger := AFila;
      q.ParamByName('PIVOT').AsInteger := APivot;
      q.Open;
      Result := '';
      if not q.IsEmpty then
        Result := q.Fields[0].AsString;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure AsociarBarrasSkuSesion(AConexion: TUniConnection;
  const ACodigo, ASku, AUsuario: string);
var
  q: TUniQuery;
  bExiste: Boolean;
begin
  ValidarCodigoBarrasSesion(ACodigo);
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text := 'SELECT CODIGO_UNIDAD_CB FROM fza_codigos_barras ' +
      'WHERE CODIGO_BARRAS_CB = :CODIGO FOR UPDATE';
    q.ParamByName('CODIGO').AsString := ACodigo;
    q.Open;
    bExiste := not q.IsEmpty;
    if not q.IsEmpty and not SameText(q.Fields[0].AsString, ASku) then
      raise Exception.CreateFmt(SBarrasConflicto,
        [ACodigo, q.Fields[0].AsString]);
    q.Close;
    q.SQL.Text := 'UPDATE fza_codigos_barras SET ESPRINCIPAL_CB = ''N'' ' +
      'WHERE CODIGO_UNIDAD_CB = :SKU AND ESPRINCIPAL_CB = ''S''';
    q.ParamByName('SKU').AsString := ASku;
    q.ExecSQL;
    if bExiste then
    begin
      q.SQL.Text := 'UPDATE fza_codigos_barras ' +
        'SET ESPRINCIPAL_CB = ''S'', INSTANTE_MODIF = NOW(), ' +
        'USUARIO_MODIF = :USUARIO WHERE CODIGO_BARRAS_CB = :CODIGO ' +
        'AND CODIGO_UNIDAD_CB = :SKU';
      q.ParamByName('CODIGO').AsString := ACodigo;
      q.ParamByName('SKU').AsString := ASku;
      q.ParamByName('USUARIO').AsString := AUsuario;
      q.ExecSQL;
    end
    else
    begin
      q.SQL.Text := 'INSERT INTO fza_codigos_barras ' +
        '(CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
        'ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
        'INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:CODIGO, :SKU, :TIPO, ''S'', NOW(), :USUARIO, ' +
        'NOW(), :USUARIO)';
      q.ParamByName('CODIGO').AsString := ACodigo;
      q.ParamByName('SKU').AsString := ASku;
      q.ParamByName('TIPO').AsString := TipoCodigoBarrasSesion(ACodigo);
      q.ParamByName('USUARIO').AsString := AUsuario;
      q.ExecSQL;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function SkuTieneCodigoBarras(AConexion: TUniConnection;
  const ASku: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text := 'SELECT CODIGO_BARRAS_CB FROM fza_codigos_barras ' +
      'WHERE CODIGO_UNIDAD_CB = :SKU LIMIT 1';
    q.ParamByName('SKU').AsString := ASku;
    q.Open;
    Result := not q.IsEmpty;
  finally
    FreeAndNil(q);
  end;
end;

function BarrasSesionDisponibles(AConexion: TUniConnection): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text := 'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_compras_sesiones_codigos_barras'' LIMIT 1';
    q.Open;
    Result := not q.IsEmpty;
  finally
    FreeAndNil(q);
  end;
end;

function SiguienteSecuenciaBarrasSesion(AConexion: TUniConnection;
  const APrefijo: string): Int64;
var
  q: TUniQuery;
begin
  Result := 0;
  if BarrasSesionDisponibles(AConexion) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      Result := SiguienteEan(q, APrefijo);
    finally
      FreeAndNil(q);
    end;
  end;
end;

end.
