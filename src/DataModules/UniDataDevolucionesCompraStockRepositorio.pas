unit UniDataDevolucionesCompraStockRepositorio;

{
  Caso de uso para preparar la devolucion de todo el stock disponible
  de un articulo y color. Centraliza validacion, SQL y transaccion.
}

interface

uses
  Uni,
  inLibDevolucionesCompraStock;

function CrearPersistenciaStockDevolucionCompra(
  AConexion: TUniConnection): IPersistenciaStockDevolucionCompra;

implementation

uses
  System.SysUtils,
  Data.DB,
  DBAccess;

type
  TServicioStockDevolucionCompra = class
  private
    FConexion: TUniConnection;
    FParametros: TParametrosStockDevolucionCompra;
    FConsulta: TUniQuery;
    function SQLJoinColorLinea: string;
    function SQLCondicionGrupo: string;
    function SQLStockDisponible: string;
    procedure AsignarParametrosGrupo;
    procedure AsignarParametrosStock;
    function ArticuloTieneColores: Boolean;
    function ContarStockDisponible: Integer;
    function ObtenerLineaBase: Integer;
    procedure BorrarGrupo;
    function InsertarLineasStock(ALineaBase: Integer): Integer;
  public
    constructor Create(AConexion: TUniConnection;
      const AParametros: TParametrosStockDevolucionCompra);
    destructor Destroy; override;
    function ConsultarEstado: TEstadoStockDevolucionCompra;
    function Ejecutar(out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
  end;
  TPersistenciaStockDevolucionCompra = class(
    TInterfacedObject,
    IPersistenciaStockDevolucionCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
  end;

constructor TServicioStockDevolucionCompra.Create(
  AConexion: TUniConnection;
  const AParametros: TParametrosStockDevolucionCompra);
begin
  inherited Create;
  FConexion := AConexion;
  FParametros := AParametros;
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := FConexion;
end;

destructor TServicioStockDevolucionCompra.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TServicioStockDevolucionCompra.SQLJoinColorLinea: string;
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

function TServicioStockDevolucionCompra.SQLCondicionGrupo: string;
begin
  Result :=
    ' WHERE L.SERIE_DEVC_DEVCLIN = :serie ' +
    '   AND L.NUMERO_DEVC_DEVCLIN = :numero ' +
    '   AND L.CODIGO_ART_DEVCLIN = :art ';
  if FParametros.IdColor > 0 then
    Result := Result + '   AND COALESCE(AVC.ID_AV, 0) = :color_av '
  else
    Result := Result + '   AND COALESCE(AVC.ID_AV, 0) = 0 ';
end;

function TServicioStockDevolucionCompra.SQLStockDisponible: string;
begin
  Result :=
    'SELECT COALESCE(SK.CODIGO_ART_SKU, ' +
    '                STK.CODIGO_UNIDAD_STK) AS ART, ' +
    '       STK.CODIGO_UNIDAD_STK AS SKU_STOCK, ' +
    '       SUM(COALESCE(STK.CANTIDAD_STK, 0)) AS CANTIDAD, ' +
    '       LEFT(MAX(COALESCE(AP.REF_PROVEEDOR_AP, '''')), 100) ' +
    '         AS REF_PRV, ' +
    '       MAX(COALESCE(ACA.ID_AC, 0)) AS ID_AC, ' +
    '       LEFT(MAX(COALESCE(ART.CODIGO_FAM_ART, '''')), 20) ' +
    '         AS CODIGO_FAM, ' +
    '       LEFT(MAX(COALESCE(NULLIF(FAM.DESCRIPCION_FAM, ''''), ' +
    '                         FAM.NOMBRE_FAM_FAM, ' +
    '                         ART.CODIGO_FAM_ART, '''')), 200) ' +
    '         AS NOMBRE_FAM, ' +
    '       LEFT(MAX(COALESCE(ART.DESCRIPCION_ART, '''')), 100) ' +
    '         AS DESCRIPCION_ART, ' +
    '       LEFT(MAX(COALESCE(ART.TIPO_CANTIDAD_ART, ''Uds'')), 20) ' +
    '         AS TIPO_CANTIDAD_ART, ' +
    '       MAX(CASE WHEN UPPER(COALESCE(ART.TIPO_IVA_ART, ''N'')) ' +
    '                    IN (''N'', ''R'', ''S'', ''E'') ' +
    '                THEN UPPER(ART.TIPO_IVA_ART) ' +
    '                ELSE ''N'' END) AS TIPO_IVA_ART, ' +
    '       MAX(COALESCE(SKUC.PRECIO_ULT_COMPRA_SKUC, ' +
    '                    AP.PRECIO_ULT_COMPRA_AP, 0)) AS PRECIO_COMPRA, ' +
    '       MIN(COALESCE(ART.ORDEN_ART, 999999)) AS ORDEN_ART ' +
    '  FROM fza_articulos_stockactual STK ' +
    '  LEFT JOIN fza_articulos_skus SK ' +
    '    ON SK.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK ' +
    '  JOIN fza_articulos ART ' +
    '    ON ART.CODIGO_ART_ART = COALESCE(SK.CODIGO_ART_SKU, ' +
    '                                     STK.CODIGO_UNIDAD_STK) ' +
    '  JOIN fza_articulos_proveedores AP ' +
    '    ON AP.CODIGO_ART_AP = ART.CODIGO_ART_ART ' +
    '   AND AP.CODIGO_PRV_AP = :prv ' +
    '  LEFT JOIN fza_articulos_skus_costes SKUC ' +
    '    ON SKUC.CODIGO_UNIDAD_SKU_SKUC = STK.CODIGO_UNIDAD_STK ' +
    '  LEFT JOIN fza_atributos_sku CO ' +
    '    ON CO.CODIGO_UNIDAD_SKU_SA = STK.CODIGO_UNIDAD_STK ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVC0 ' +
    '                WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
    '                  AND AVC0.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')) ' +
    '  LEFT JOIN fza_atributos_valores AVC ' +
    '    ON AVC.ID_AV = CO.ID_AV_SA ' +
    '   AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
    '  LEFT JOIN fza_articulos_familias FAM ' +
    '    ON FAM.CODIGO_FAM_FAM = ART.CODIGO_FAM_ART ' +
    '  LEFT JOIN ( ' +
    '        SELECT CODIGO_ART_ACA, MIN(ID_AC_ACA) AS ID_AC ' +
    '          FROM fza_articulos_conjuntos_asign ' +
    '         WHERE ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
    'AR452.CODIGO_ART_ART = CODIGO_ART_ACA) AND EJ452.EJE_VA = ''P'') ' +
    '         GROUP BY CODIGO_ART_ACA ' +
    '       ) ACA ' +
    '    ON ACA.CODIGO_ART_ACA = ART.CODIGO_ART_ART ' +
    ' WHERE STK.CODIGO_ALM_STK = :alm ' +
    '   AND COALESCE(SK.CODIGO_ART_SKU, ' +
    '                STK.CODIGO_UNIDAD_STK) = :art ' +
    '   AND COALESCE(ART.ESACTIVO_ART, ''S'') = ''S'' ' +
    '   AND (SK.CODIGO_UNIDAD_SKU IS NULL ' +
    '        OR COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'') ' +
    '   AND ((:color_av > 0 ' +
    '         AND COALESCE(AVC.ID_AV, 0) = :color_av) ' +
    '        OR (:color_av = 0 AND COALESCE(AVC.ID_AV, 0) = 0)) ' +
    ' GROUP BY COALESCE(SK.CODIGO_ART_SKU, STK.CODIGO_UNIDAD_STK), ' +
    '          STK.CODIGO_UNIDAD_STK ' +
    'HAVING SUM(COALESCE(STK.CANTIDAD_STK, 0)) > 0';
end;

procedure TServicioStockDevolucionCompra.AsignarParametrosGrupo;
begin
  FConsulta.ParamByName('serie').AsString := FParametros.Serie;
  FConsulta.ParamByName('numero').AsString := FParametros.Numero;
  FConsulta.ParamByName('art').AsString := FParametros.CodigoArticulo;
  if FParametros.IdColor > 0 then
    FConsulta.ParamByName('color_av').AsInteger := FParametros.IdColor;
end;

procedure TServicioStockDevolucionCompra.AsignarParametrosStock;
begin
  FConsulta.ParamByName('prv').AsString := FParametros.CodigoProveedor;
  FConsulta.ParamByName('alm').AsString := FParametros.CodigoAlmacen;
  FConsulta.ParamByName('art').AsString := FParametros.CodigoArticulo;
  FConsulta.ParamByName('color_av').AsInteger := FParametros.IdColor;
end;

function TServicioStockDevolucionCompra.ArticuloTieneColores: Boolean;
begin
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'SELECT 1 ' +
    '  FROM fza_articulos_skus SK ' +
    '  JOIN fza_atributos_sku SA ' +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '  JOIN fza_atributos_valores AV ' +
    '    ON AV.ID_AV = SA.ID_AV_SA ' +
    '   AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
    ' WHERE SK.CODIGO_ART_SKU = :art ' +
    ' LIMIT 1';
  FConsulta.ParamByName('art').AsString := FParametros.CodigoArticulo;
  FConsulta.Open;
  Result := not FConsulta.IsEmpty;
  FConsulta.Close;
end;

function TServicioStockDevolucionCompra.ContarStockDisponible: Integer;
begin
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'SELECT COUNT(*) AS N FROM (' + SQLStockDisponible + ') X';
  AsignarParametrosStock;
  FConsulta.Open;
  Result := FConsulta.FieldByName('N').AsInteger;
  FConsulta.Close;
end;

function TServicioStockDevolucionCompra.ObtenerLineaBase: Integer;
begin
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'SELECT COALESCE(MAX(CAST(NULLIF(LINEA_DEVCLIN, '''') ' +
    '       AS UNSIGNED)), 0) AS LINEA_BASE ' +
    '  FROM fza_devoluciones_compra_lineas ' +
    ' WHERE SERIE_DEVC_DEVCLIN = :serie ' +
    '   AND NUMERO_DEVC_DEVCLIN = :numero';
  FConsulta.ParamByName('serie').AsString := FParametros.Serie;
  FConsulta.ParamByName('numero').AsString := FParametros.Numero;
  FConsulta.Open;
  Result := FConsulta.FieldByName('LINEA_BASE').AsInteger;
  FConsulta.Close;
end;

procedure TServicioStockDevolucionCompra.BorrarGrupo;
begin
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'DELETE C ' +
    '  FROM fza_devoluciones_compra_celdas C ' +
    '  JOIN fza_devoluciones_compra_lineas L ' +
    '    ON C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
    '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
    '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
    '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
    SQLJoinColorLinea +
    SQLCondicionGrupo;
  AsignarParametrosGrupo;
  FConsulta.ExecSQL;
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'DELETE L ' +
    '  FROM fza_devoluciones_compra_lineas L ' +
    SQLJoinColorLinea +
    SQLCondicionGrupo;
  AsignarParametrosGrupo;
  FConsulta.ExecSQL;
end;

function TServicioStockDevolucionCompra.InsertarLineasStock(
  ALineaBase: Integer): Integer;
begin
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'INSERT INTO fza_devoluciones_compra_lineas ( ' +
    '  NUMERO_DEVC_DEVCLIN, SERIE_DEVC_DEVCLIN, LINEA_DEVCLIN, ' +
    '  CODIGO_ART_DEVCLIN, CODIGO_UNIDAD_DEVCLIN, REF_PRV_DEVCLIN, ' +
    '  ID_AC_PIVOT_DEVCLIN, CODIGO_FAM_DEVCLIN, NOMBRE_FAM_DEVCLIN, ' +
    '  DESCRIPCION_ARTICULO_DEVCLIN, TIPO_CANTIDAD_ARTICULO_DEVCLIN, ' +
    '  CANTIDAD_DEVCLIN, TOTAL_UNIDADES_DEVCLIN, ' +
    '  TIPO_IVA_ARTICULO_DEVCLIN, PORCENTAJE_IVA_DEVCLIN, ' +
    '  PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN, ' +
    '  PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN, TOTAL_DEVCLIN, ' +
    '  CODIGO_ALMACEN_DEVCLIN, ESFACTURADA_DEVCLIN, ' +
    '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :numero, :serie, ' +
    '       LPAD(:linea_base + (ROW_NUMBER() OVER (ORDER BY ' +
    '                                Y.ORDEN_ART, Y.ART, Y.SKU_STOCK) ' +
    '                                * 10), 4, ''0''), ' +
    '       Y.ART, Y.SKU_STOCK, Y.REF_PRV, NULLIF(Y.ID_AC, 0), ' +
    '       Y.CODIGO_FAM, Y.NOMBRE_FAM, Y.DESCRIPCION_ART, ' +
    '       Y.TIPO_CANTIDAD_ART, Y.CANTIDAD, Y.CANTIDAD, ' +
    '       Y.TIPO_IVA_ART, Y.PORCENTAJE_IVA, Y.PRECIO_COMPRA, ' +
    '       Y.PRECIO_COMPRA * (1 + Y.PORCENTAJE_IVA / 100), ' +
    '       Y.CANTIDAD * Y.PRECIO_COMPRA, :almacen_linea, ''N'', ' +
    '       NOW(), NOW(), :usuario_alta, :usuario_modif ' +
    '  FROM ( ' +
    '        SELECT X.*, ' +
    '               CASE X.TIPO_IVA_ART ' +
    '                 WHEN ''R'' THEN :iva_r ' +
    '                 WHEN ''S'' THEN :iva_s ' +
    '                 WHEN ''E'' THEN :iva_e ' +
    '                 ELSE :iva_n END AS PORCENTAJE_IVA ' +
    '          FROM (' + SQLStockDisponible + ') X ' +
    '       ) Y ' +
    ' ORDER BY Y.ORDEN_ART, Y.ART, Y.SKU_STOCK';
  FConsulta.ParamByName('serie').AsString := FParametros.Serie;
  FConsulta.ParamByName('numero').AsString := FParametros.Numero;
  FConsulta.ParamByName('linea_base').AsInteger := ALineaBase;
  FConsulta.ParamByName('almacen_linea').AsString :=
    FParametros.CodigoAlmacen;
  FConsulta.ParamByName('usuario_alta').AsString := FParametros.Usuario;
  FConsulta.ParamByName('usuario_modif').AsString := FParametros.Usuario;
  FConsulta.ParamByName('iva_n').AsFloat := FParametros.IvaNormal;
  FConsulta.ParamByName('iva_r').AsFloat := FParametros.IvaReducido;
  FConsulta.ParamByName('iva_s').AsFloat := FParametros.IvaSuperreducido;
  FConsulta.ParamByName('iva_e').AsFloat := FParametros.IvaExento;
  AsignarParametrosStock;
  FConsulta.ExecSQL;
  Result := FConsulta.RowsAffected;
end;

function TServicioStockDevolucionCompra.ConsultarEstado:
  TEstadoStockDevolucionCompra;
begin
  if (FParametros.CodigoProveedor = '') or
     (FParametros.CodigoProveedor = '0') then
    Result := esdcProveedorNoIndicado
  else if FParametros.CodigoAlmacen = '' then
    Result := esdcAlmacenNoIndicado
  else if FParametros.CodigoArticulo = '' then
    Result := esdcArticuloNoIndicado
  else if (FParametros.IdColor = 0) and ArticuloTieneColores then
    Result := esdcRequiereColor
  else if ContarStockDisponible = 0 then
    Result := esdcSinStock
  else
    Result := esdcDisponible;
end;

function TServicioStockDevolucionCompra.Ejecutar(
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
var
  bTxOwned: Boolean;
  iLineaBase: Integer;
begin
  Result := False;
  ALineas := 0;
  bTxOwned := not FConexion.InTransaction;
  if bTxOwned then
    FConexion.StartTransaction;
  try
    AEstado := ConsultarEstado;
    if AEstado = esdcDisponible then
    begin
      BorrarGrupo;
      iLineaBase := ObtenerLineaBase;
      ALineas := InsertarLineasStock(iLineaBase);
      Result := ALineas > 0;
      if not Result then
        AEstado := esdcSinStock;
    end;
    if Result then
    begin
      if bTxOwned and FConexion.InTransaction then
        FConexion.Commit;
    end
    else if bTxOwned and FConexion.InTransaction then
      FConexion.Rollback;
  except
    if bTxOwned and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

constructor TPersistenciaStockDevolucionCompra.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TPersistenciaStockDevolucionCompra.ConsultarEstado(
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
var
  Servicio: TServicioStockDevolucionCompra;
begin
  Servicio := TServicioStockDevolucionCompra.Create(
    FConexion, AParametros);
  try
    Result := Servicio.ConsultarEstado;
  finally
    FreeAndNil(Servicio);
  end;
end;

function TPersistenciaStockDevolucionCompra.DevolverTodoStock(
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
var
  Servicio: TServicioStockDevolucionCompra;
begin
  Servicio := TServicioStockDevolucionCompra.Create(
    FConexion, AParametros);
  try
    Result := Servicio.Ejecutar(ALineas, AEstado);
  finally
    FreeAndNil(Servicio);
  end;
end;

function CrearPersistenciaStockDevolucionCompra(
  AConexion: TUniConnection): IPersistenciaStockDevolucionCompra;
begin
  Result := TPersistenciaStockDevolucionCompra.Create(AConexion);
end;

end.
