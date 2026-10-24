{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDevolucionesCompraRepositorio                          }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas UniDAC auxiliares de devoluciones de compra.                    }
{******************************************************************************}
unit UniDataDevolucionesCompraRepositorio;

interface

uses
  Uni, inLibDevolucionesCompraPersistenciaIntf;

function CrearServiciosPersistenciaDevolucionCompraUniDAC(
  AConexion: TUniConnection
): TServiciosPersistenciaDevolucionCompra;

implementation

uses
  System.SysUtils, Data.DB, DBAccess,
  UniDataDevolucionesCompraStockRepositorio;

type
  TRepositorioDatosDevolucionCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioDatosDevolucionCompra)
  private
    FConexion: TUniConnection;
    function SqlJoinColorLinea: string;
    function SqlCondicionGrupo(AIdColor: Integer): string;
    procedure AsignarGrupo(
      AConsulta: TUniQuery;
      const AGrupo: TGrupoColorDevolucionCompra);
  public
    constructor Create(AConexion: TUniConnection);
    function CodigoSkuRepresentanteColor(
      const ACodigoArticulo, AColor: string;
      AIdConjuntoPivot: Integer
    ): string;
    function ListarColoresArticulo(
      const ACodigoArticulo: string
    ): TColoresArticuloDevolucionCompra;
    function ObtenerColorLinea(
      const ASerie, ANumero, ALinea: string;
      out AIdColor: Integer
    ): Boolean;
    function BorrarGrupoColor(
      const AGrupo: TGrupoColorDevolucionCompra
    ): Integer;
    function ResolverConjuntoPivotArticulo(
      const ACodigoArticulo: string
    ): Integer;
    function ModeloProveedorArticulo(
      const ACodigoArticulo, ACodigoProveedor: string
    ): string;
    function EsCodigoArticuloExacto(
      const ACodigo: string
    ): Boolean;
  end;

constructor TRepositorioDatosDevolucionCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDatosDevolucionCompraUniDAC.SqlJoinColorLinea:
  string;
begin
  Result :=
    '  LEFT JOIN fza_atributos_sku SAC ' +
    '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_DEVCLIN ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
    '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
    '                  AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
    'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    '(SELECT SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 ' +
    'WHERE SK452.CODIGO_UNIDAD_SKU = SAC.CODIGO_UNIDAD_SKU_SA) ' +
    'AND EJ452.EJE_VA = ''F'')) ' +
    '  LEFT JOIN fza_atributos_valores AVC ' +
    '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
    '   AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 WHERE ' +
    'SK452.CODIGO_UNIDAD_SKU = SAC.CODIGO_UNIDAD_SKU_SA) AND ' +
    'EJ452.EJE_VA = ''F'') ';
end;

function TRepositorioDatosDevolucionCompraUniDAC.SqlCondicionGrupo(
  AIdColor: Integer
): string;
begin
  Result :=
    ' WHERE L.SERIE_DEVC_DEVCLIN = :SERIE ' +
    '   AND L.NUMERO_DEVC_DEVCLIN = :NUMERO ' +
    '   AND L.CODIGO_ART_DEVCLIN = :ARTICULO ';
  if AIdColor > 0 then
  begin
    Result := Result +
      '   AND COALESCE(AVC.ID_AV, 0) = :COLOR ';
  end
  else
  begin
    Result := Result +
      '   AND COALESCE(AVC.ID_AV, 0) = 0 ';
  end;
end;

procedure TRepositorioDatosDevolucionCompraUniDAC.AsignarGrupo(
  AConsulta: TUniQuery;
  const AGrupo: TGrupoColorDevolucionCompra);
begin
  AConsulta.ParamByName('SERIE').AsString := AGrupo.Serie;
  AConsulta.ParamByName('NUMERO').AsString := AGrupo.Numero;
  AConsulta.ParamByName('ARTICULO').AsString := AGrupo.CodigoArticulo;
  if AGrupo.IdColor > 0 then
  begin
    AConsulta.ParamByName('COLOR').AsInteger := AGrupo.IdColor;
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.
  CodigoSkuRepresentanteColor(
    const ACodigoArticulo, AColor: string;
    AIdConjuntoPivot: Integer
  ): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (ACodigoArticulo <> '') and (AColor <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT X.SKU ' +
        '  FROM ( ' +
        '        SELECT SK.CODIGO_UNIDAD_SKU AS SKU, ' +
        '               COALESCE(NULLIF(AVC.AV, ''''), ' +
        '                 CASE WHEN EXISTS (SELECT 1 FROM ' +
      'VI_VARIACIONES_EJES E WHERE E.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND E.EJE_VA = ''F'') ' +
        '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
        '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
        '                      ELSE '''' END, '''') AS COLOR_TXT, ' +
        '               CASE WHEN :ID_CONJUNTO <= 0 THEN 0 ' +
        '                    WHEN TAL.ID_AV_SA IS NULL THEN 0 ' +
        '                    WHEN ACD.ID_AV_ACD IS NOT NULL THEN 0 ' +
        '                    ELSE 1 END AS PENALIZA, ' +
        '               COALESCE(ACD.ORDEN_ACD, 999999) AS ORDEN_TALLA ' +
        '          FROM fza_articulos_skus SK ' +
        '          LEFT JOIN fza_atributos_sku CO ' +
        '            ON CO.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '           AND EXISTS (' +
        '             SELECT 1 FROM fza_atributos_valores AVC0 ' +
        '              WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
        '                AND AVC0.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')) ' +
        '          LEFT JOIN fza_atributos_valores AVC ' +
        '            ON AVC.ID_AV = CO.ID_AV_SA ' +
        '           AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
        'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
        '          LEFT JOIN fza_atributos_sku TAL ' +
        '            ON TAL.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '           AND EXISTS (' +
        '             SELECT 1 FROM fza_atributos_valores AVT ' +
        '              WHERE AVT.ID_AV = TAL.ID_AV_SA ' +
        '                AND AVT.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'')) ' +
        '          LEFT JOIN fza_atributos_conjuntos_det ACD ' +
        '            ON ACD.ID_AC_ACD = :ID_CONJUNTO ' +
        '           AND ACD.ID_AV_ACD = TAL.ID_AV_SA ' +
        '         WHERE SK.CODIGO_ART_SKU = :ARTICULO ' +
        '           AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        '       ) X ' +
        ' WHERE X.COLOR_TXT = :COLOR ' +
        ' ORDER BY X.PENALIZA, X.ORDEN_TALLA, X.SKU ' +
        ' LIMIT 1';
      oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
      oConsulta.ParamByName('COLOR').AsString := AColor;
      oConsulta.ParamByName('ID_CONJUNTO').AsInteger :=
        AIdConjuntoPivot;
      oConsulta.Open;
      if not oConsulta.Eof then
      begin
        Result := Trim(oConsulta.FieldByName('SKU').AsString);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.ListarColoresArticulo(
  const ACodigoArticulo: string
): TColoresArticuloDevolucionCompra;
var
  oConsulta: TUniQuery;
  iColor: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT X.COLOR_TXT, MIN(X.COLOR_COD) AS COLOR_COD ' +
      '  FROM ( ' +
      '        SELECT COALESCE(NULLIF(AVC.AV, ''''), ' +
      '                 CASE WHEN EXISTS (SELECT 1 FROM ' +
      'VI_VARIACIONES_EJES E WHERE E.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND E.EJE_VA = ''F'') ' +
      '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
      '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
      '                      ELSE '''' END, '''') AS COLOR_TXT, ' +
      '               COALESCE(ATBC.CODIGO_ATB, ' +
      '                 CASE WHEN EXISTS (SELECT 1 FROM ' +
      'VI_VARIACIONES_EJES E WHERE E.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND E.EJE_VA = ''F'') ' +
      '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
      '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
      '                      ELSE '''' END, '''') AS COLOR_COD ' +
      '          FROM fza_articulos_skus SK ' +
      '          LEFT JOIN fza_atributos_sku CO ' +
      '            ON CO.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
      '           AND EXISTS (' +
      '             SELECT 1 FROM fza_atributos_valores AVC0 ' +
      '              WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
      '                AND AVC0.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
      'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')) ' +
      '          LEFT JOIN fza_atributos_valores AVC ' +
      '            ON AVC.ID_AV = CO.ID_AV_SA ' +
      '           AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
      '          LEFT JOIN fza_atributos_basicos ATBC ' +
      '            ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
      '         WHERE SK.CODIGO_ART_SKU = :ARTICULO ' +
      '           AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
      '       ) X ' +
      ' WHERE X.COLOR_TXT <> '''' ' +
      ' GROUP BY X.COLOR_TXT ' +
      ' ORDER BY X.COLOR_TXT';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iColor := 0;
    while not oConsulta.Eof do
    begin
      Result[iColor].Texto := Trim(
        oConsulta.FieldByName('COLOR_TXT').AsString);
      Result[iColor].Codigo := Trim(
        oConsulta.FieldByName('COLOR_COD').AsString);
      Inc(iColor);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.ObtenerColorLinea(
  const ASerie, ANumero, ALinea: string;
  out AIdColor: Integer
): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AIdColor := 0;
  if (ASerie <> '') and (ANumero <> '') and (ALinea <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(AVC.ID_AV, 0) AS COLOR_AV ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        SqlJoinColorLinea +
        ' WHERE L.SERIE_DEVC_DEVCLIN = :SERIE ' +
        '   AND L.NUMERO_DEVC_DEVCLIN = :NUMERO ' +
        '   AND L.LINEA_DEVCLIN = :LINEA';
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('LINEA').AsString := ALinea;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        AIdColor := oConsulta.FieldByName('COLOR_AV').AsInteger;
        Result := True;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.BorrarGrupoColor(
  const AGrupo: TGrupoColorDevolucionCompra
): Integer;
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
    begin
      FConexion.StartTransaction;
    end;
    try
      oConsulta.SQL.Text :=
        'DELETE C ' +
        '  FROM fza_devoluciones_compra_celdas C ' +
        '  JOIN fza_devoluciones_compra_lineas L ' +
        '    ON C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
        '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
        '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
        '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
        SqlJoinColorLinea +
        SqlCondicionGrupo(AGrupo.IdColor);
      AsignarGrupo(oConsulta, AGrupo);
      oConsulta.ExecSQL;
      oConsulta.SQL.Text :=
        'DELETE L ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        SqlJoinColorLinea +
        SqlCondicionGrupo(AGrupo.IdColor);
      AsignarGrupo(oConsulta, AGrupo);
      oConsulta.ExecSQL;
      Result := oConsulta.RowsAffected;
      if bTransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Commit;
      end;
    except
      if bTransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.
  ResolverConjuntoPivotArticulo(
    const ACodigoArticulo: string
  ): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ACA.ID_AC_ACA ' +
      '  FROM fza_articulos_conjuntos_asign ACA ' +
      ' WHERE ACA.CODIGO_ART_ACA = :ARTICULO ' +
      '   AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
      'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
      'AR452.CODIGO_ART_ART = :ARTICULO) AND EJ452.EJE_VA = ''P'') ' +
      ' ORDER BY ACA.ID_VA_ACA ' +
      ' LIMIT 1';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.ModeloProveedorArticulo(
  const ACodigoArticulo, ACodigoProveedor: string
): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT AP.REF_PROVEEDOR_AP ' +
      '  FROM fza_articulos_proveedores AP ' +
      ' WHERE AP.CODIGO_ART_AP = :ARTICULO ' +
      '   AND COALESCE(TRIM(AP.REF_PROVEEDOR_AP), '''') <> '''' ' +
      ' ORDER BY CASE WHEN AP.CODIGO_PRV_AP = :PROVEEDOR ' +
      '               THEN 0 ELSE 1 END, ' +
      '          CASE AP.ESPROVEEDORPRINCIPAL_AP ' +
      '               WHEN ''S'' THEN 0 ELSE 1 END, ' +
      '          AP.FECHA_VALIDEZ_AP DESC, AP.CODIGO_PRV_AP ' +
      ' LIMIT 1';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('PROVEEDOR').AsString := ACodigoProveedor;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('REF_PROVEEDOR_AP').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.EsCodigoArticuloExacto(
  const ACodigo: string
): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Trim(ACodigo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :ARTICULO ' +
        ' LIMIT 1';
      oConsulta.ParamByName('ARTICULO').AsString := Trim(ACodigo);
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearServiciosPersistenciaDevolucionCompraUniDAC(
  AConexion: TUniConnection
): TServiciosPersistenciaDevolucionCompra;
begin
  Result.Datos := TRepositorioDatosDevolucionCompraUniDAC.Create(
    AConexion);
  Result.Stock := CrearPersistenciaStockDevolucionCompra(AConexion);
end;

end.
