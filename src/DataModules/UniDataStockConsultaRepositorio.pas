{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataStockConsultaRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas UniDAC y composición del pivote de stock.                      }
{******************************************************************************}
unit UniDataStockConsultaRepositorio;

interface

uses
  Uni, inLibStockConsultaPersistenciaIntf;

function ConstruirSqlListarTallasStock(
  const AColores: TArray<string>;
  AIdConjunto: Integer): string;
// Abre el detalle por almacén, color y eje S si el artículo tiene pestañas.
// False: el llamador mantiene su consulta habitual de dos dimensiones.
function AbrirConsultaStockPorPestanas(AConsulta: TUniQuery;
  const ACodigo: string; AConPendientes: Boolean): Boolean;
function CrearServiciosStockConsultaUniDAC(
  AConexion: TUniConnection): TServiciosStockConsulta;

implementation

uses
  System.SysUtils, System.StrUtils, System.Generics.Collections, Data.DB,
  inLibPestanasEje;

type
  TResultadoConsultaStockUniDAC = class(
    TInterfacedObject,
    IResultadoConsultaStock)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;
  TRepositorioStockConsultaUniDAC = class(
    TInterfacedObject,
    ILectorCatalogosStockConsulta,
    IRepositorioPivoteStock)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function ResultadoConsulta(
      AConsulta: TUniQuery): IResultadoConsultaStock;
    function ListaSql(const AValores: TArray<string>): string;
    function FiltroDimension(ADimension: TDimensionFotos): string;
    function CampoCantidadStock(AEstado: TEstadoStock): string;
    function EstadoBaseSelectFor(
      const ASolicitud: TSolicitudPivoteStock;
      AEstado: TEstadoStock): string;
    function EstadoBaseSelect(
      const ASolicitud: TSolicitudPivoteStock): string;
    function ConstruirSqlPivote(
      const ASolicitud: TSolicitudPivoteStock;
      const ATallas: TArray<TInfoColumna>): string;
    function FiltroPestanaBase(
      const ASolicitud: TSolicitudPivoteStock): string;
    function ConstruirSqlPestanas(
      const ASolicitud: TSolicitudPivoteStock): string;
  public
    constructor Create(AConexion: TUniConnection);
    function ResolverTextoArticulo(
      const AEntrada: string): IResultadoConsultaStock;
    function ResolverSku(
      const ACodigoArticulo, AColor, APestana, ATalla: string;
      out ACodigoSku: string): Integer;
    function ConsultarAlmacenes: IResultadoConsultaStock;
    function ConsultarColores(
      const ACodigoArticulo, ACodigoSku: string): IResultadoConsultaStock;
    function ConsultarPropiedadesPorColor(
      const ACodigoArticulo: string): IResultadoConsultaStock;
    function ObtenerDescripcionArticulo(
      const ACodigoArticulo: string;
      out ADescripcion: string): Boolean;
    function ConsultarFotosRelacionadas(
      const ASolicitud: TSolicitudFotosRelacionadasStock
    ): IResultadoConsultaStock;
    function BuscarArticulos(
      const ACodigoTarifa: string): IResultadoConsultaStock;
    function ListarTallas(
      const ACodigoArticulo: string;
      const AColores: TArray<string>): TArray<TInfoColumna>;
    function Consultar(
      const ASolicitud: TSolicitudPivoteStock;
      const ATallas: TArray<TInfoColumna>): IResultadoConsultaStock;
    function ConsultarPestanas(
      const ASolicitud: TSolicitudPivoteStock): TModeloPestanasEje;
  end;

constructor TResultadoConsultaStockUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoConsultaStockUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoConsultaStockUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioStockConsultaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioStockConsultaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioStockConsultaUniDAC.ResultadoConsulta(
  AConsulta: TUniQuery): IResultadoConsultaStock;
begin
  Result := TResultadoConsultaStockUniDAC.Create(AConsulta);
end;

function TRepositorioStockConsultaUniDAC.ListaSql(
  const AValores: TArray<string>): string;
var
  i: Integer;
begin
  if Length(AValores) = 0 then
    Result := 'NULL'
  else
  begin
    Result := '';
    for i := 0 to High(AValores) do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + QuotedStr(AValores[i]);
    end;
  end;
end;

function ConstruirSqlListarTallasStock(
  const AColores: TArray<string>;
  AIdConjunto: Integer): string;
var
  i: Integer;
  sColores, sSistema, sFiltroColor: string;
begin
  sColores := '';
  for i := 0 to High(AColores) do
  begin
    if sColores <> '' then
      sColores := sColores + ',';
    sColores := sColores + QuotedStr(AColores[i]);
  end;
  sFiltroColor := '';
  if sColores <> '' then
    sFiltroColor :=
      ' AND EXISTS (SELECT 1 FROM fza_atributos_sku SAC ' +
      '   JOIN fza_atributos_valores AVC ON AVC.ID_AV = SAC.ID_AV_SA ' +
      '   WHERE SAC.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '     AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') AND AVC.AV IN (' +
      sColores + ')) ';
  sSistema := '';
  if AIdConjunto > 0 then
    sSistema :=
      'SELECT AV.AV, 0 AS BLOQUE, ' +
      '       COALESCE(AAB.ORDEN_AAB, ACD.ORDEN_ACD, ' +
      '                AV.ORDEN_AV) AS ORDEN_TALLA ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      '  LEFT JOIN fza_articulos_atributos_basicos AAB ' +
      '    ON AAB.CODIGO_ART_AAB = :ARTICULO ' +
      '   AND AAB.ID_AV_AAB = AV.ID_AV ' +
      ' WHERE ACD.ID_AC_ACD = :CONJUNTO ' +
      ' AND EXISTS (SELECT 1 FROM fza_articulos_skus SKU ' +
      '   JOIN fza_atributos_sku SAT ' +
      '     ON SAT.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '   WHERE SKU.CODIGO_ART_SKU = :ARTICULO ' +
      '     AND SAT.ID_AV_SA = ACD.ID_AV_ACD ' + sFiltroColor +
      ') UNION ALL ';
  // Solo tallas con SKU, aunque no tengan stock. El conjunto conserva
  // su orden y las tallas reales ajenas a el se anaden al final (848).
  Result :=
    'SELECT AV, MIN(BLOQUE) AS BLOQUE, ' +
    '       MIN(ORDEN_TALLA) AS ORDEN_TALLA FROM (' + sSistema +
    'SELECT AVT.AV, 1 AS BLOQUE, ' +
    '       COALESCE(AAB.ORDEN_AAB, AVT.ORDEN_AV) AS ORDEN_TALLA ' +
    '  FROM fza_articulos_skus SKU ' +
    '  JOIN fza_atributos_sku SAT ' +
    '    ON SAT.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
    '  JOIN fza_atributos_valores AVT ON AVT.ID_AV = SAT.ID_AV_SA ' +
    '  LEFT JOIN fza_articulos_atributos_basicos AAB ' +
    '    ON AAB.CODIGO_ART_AAB = SKU.CODIGO_ART_SKU ' +
    '   AND AAB.ID_AV_AAB = AVT.ID_AV ' +
    ' WHERE SKU.CODIGO_ART_SKU = :ARTICULO ' +
    '   AND AVT.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' + sFiltroColor;
  if AIdConjunto > 0 then
    Result := Result +
      ' AND NOT EXISTS (SELECT 1 FROM fza_atributos_conjuntos_det D ' +
      '   WHERE D.ID_AC_ACD = :CONJUNTO AND D.ID_AV_ACD = AVT.ID_AV) ';
  Result := Result +
    ') T GROUP BY AV ORDER BY BLOQUE, ORDEN_TALLA, AV';
end;

function TRepositorioStockConsultaUniDAC.ResolverTextoArticulo(
  const AEntrada: string): IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT DISTINCT X.TIPO_COINCIDENCIA, X.CODIGO_PADRE, ' +
      '       X.CODIGO_SKU, X.DESCRIPCION_ART, ' +
      '       COALESCE(AP.REF_PROVEEDOR_AP, '''') AS REF_PROVEEDOR, ' +
      '       COALESCE(P.RAZON_SOCIAL_PRV, '''') AS PROVEEDOR ' +
      '  FROM vi_caja_busqueda_unificada X ' +
      '  LEFT JOIN fza_articulos_proveedores AP ' +
      '    ON X.TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ' +
      '       ''MODELO_PROV'' COLLATE utf8mb4_spanish_ci ' +
      '   AND AP.CODIGO_ART_AP = X.CODIGO_PADRE ' +
      '   AND AP.REF_PROVEEDOR_AP COLLATE utf8mb4_spanish_ci = ' +
      '       X.INPUT_BUSQUEDA COLLATE utf8mb4_spanish_ci ' +
      '  LEFT JOIN fza_proveedores P ' +
      '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
      ' WHERE X.INPUT_BUSQUEDA COLLATE utf8mb4_spanish_ci = :ENTRADA ' +
      ' ORDER BY CASE ' +
      '            WHEN X.TIPO_COINCIDENCIA ' +
      '                 COLLATE utf8mb4_spanish_ci = ' +
      '                 ''SKU'' COLLATE utf8mb4_spanish_ci THEN 1 ' +
      '            WHEN X.TIPO_COINCIDENCIA ' +
      '                 COLLATE utf8mb4_spanish_ci = ' +
      '                 ''CODIGO'' COLLATE utf8mb4_spanish_ci THEN 2 ' +
      '            WHEN X.TIPO_COINCIDENCIA ' +
      '                 COLLATE utf8mb4_spanish_ci = ' +
      '                 ''EAN'' COLLATE utf8mb4_spanish_ci THEN 3 ' +
      '            WHEN X.TIPO_COINCIDENCIA ' +
      '                 COLLATE utf8mb4_spanish_ci = ' +
      '                 ''MODELO_PROV'' COLLATE utf8mb4_spanish_ci ' +
      '                 THEN 4 ' +
      '            ELSE 5 END, X.CODIGO_PADRE, X.CODIGO_SKU';
    oConsulta.ParamByName('ENTRADA').AsString := AEntrada;
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.ResolverSku(
  const ACodigoArticulo, AColor, APestana, ATalla: string;
  out ACodigoSku: string): Integer;
var
  oConsulta: TUniQuery;
  sSql: string;
begin
  Result := 0;
  ACodigoSku := '';
  oConsulta := NuevaConsulta;
  try
    sSql :=
      'SELECT sk.CODIGO_UNIDAD_SKU ' +
      '  FROM fza_articulos_skus sk ' +
      ' WHERE sk.CODIGO_ART_SKU = :ARTICULO ' +
      '   AND sk.ESACTIVO_SKU = ''S'' ';
    if Trim(AColor) <> '' then
      sSql := sSql +
        '   AND EXISTS (SELECT 1 ' +
        '                 FROM fza_atributos_sku sa ' +
        '                 JOIN fza_atributos_valores av ' +
        '                   ON av.ID_AV = sa.ID_AV_SA ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
        '                  AND av.AV = :COLOR) ';
    if Trim(APestana) <> '' then
      sSql := sSql +
        '   AND EXISTS (SELECT 1 ' +
        '                 FROM fza_atributos_sku sa ' +
        '                 JOIN fza_atributos_valores av ' +
        '                   ON av.ID_AV = sa.ID_AV_SA ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''S'') ' +
        '                  AND av.AV = :PESTANA) ';
    if Trim(ATalla) <> '' then
      sSql := sSql +
        '   AND EXISTS (SELECT 1 ' +
        '                 FROM fza_atributos_sku sa ' +
        '                 JOIN fza_atributos_valores av ' +
        '                   ON av.ID_AV = sa.ID_AV_SA ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
        '                  AND av.AV = :TALLA) ';
    oConsulta.SQL.Text := sSql + ' ORDER BY sk.CODIGO_UNIDAD_SKU';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    if Trim(AColor) <> '' then
      oConsulta.ParamByName('COLOR').AsString := AColor;
    if Trim(APestana) <> '' then
      oConsulta.ParamByName('PESTANA').AsString := APestana;
    if Trim(ATalla) <> '' then
      oConsulta.ParamByName('TALLA').AsString := ATalla;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Inc(Result);
      if Result = 1 then
        ACodigoSku := oConsulta.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.ConsultarAlmacenes:
  IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, TIPO_USO_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.ConsultarColores(
  const ACodigoArticulo, ACodigoSku: string): IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV, ' +
      '       MAX(CASE WHEN SKU.CODIGO_UNIDAD_SKU = :SKU ' +
      '                THEN 1 ELSE 0 END) AS ES_COLOR_SKU, ' +
      '       MAX(COALESCE(ATB.HEX_ATB, '''')) AS HEX ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_atributos_sku SA ' +
      '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      '  LEFT JOIN fza_atributos_basicos ATB ' +
      '    ON ATB.ID_ATB = AV.ID_ATB_AV ' +
      ' WHERE SKU.CODIGO_ART_SKU = :ARTICULO ' +
      '   AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
      ' GROUP BY AV.AV ' +
      ' ORDER BY MIN(AV.ORDEN_AV), AV.AV';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.ConsultarPropiedadesPorColor(
  const ACodigoArticulo: string): IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT COLORS.COLOR_AV AS COLOR, ' +
      '       P.NOMBRE_PROP_PROP AS NOMBRE, ' +
      '       P.TIPO_VALOR_PROP AS TIPO, ' +
      '       PV.PV AS PVTXT, ' +
      '       AP.VALOR_LIBRE_ARTPROP AS VLIBRE, ' +
      '       CASE WHEN AP.CODIGO_UNIDAD_ARTPROP LIKE ''%/%/%'' ' +
      '            THEN ''SKU'' ELSE ''COLOR'' END AS NIVEL, ' +
      '       PVA.PV AS PVA, ' +
      '       APA.VALOR_LIBRE_ARTPROP AS VLIBRE_ART ' +
      '  FROM fza_articulos_propiedades AP ' +
      '  JOIN fza_propiedades P ' +
      '    ON P.CODIGO_PROP_ARTPROP = AP.CODIGO_PROP_ARTPROP ' +
      '  LEFT JOIN fza_propiedades_valores PV ' +
      '    ON PV.ID_PV_ARTPROP = AP.ID_PV_ARTPROP ' +
      '  JOIN (SELECT DISTINCT ' +
      '               SUBSTRING_INDEX(SKU.CODIGO_UNIDAD_SKU, ''/'', 2) ' +
      '                 AS PREFIJO, AV.AV AS COLOR_AV ' +
      '          FROM fza_articulos_skus SKU ' +
      '          JOIN fza_atributos_sku SA ' +
      '            ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '          JOIN fza_atributos_valores AV ' +
      '            ON AV.ID_AV = SA.ID_AV_SA ' +
      '           AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
      '         WHERE SKU.CODIGO_ART_SKU = ' +
      QuotedStr(ACodigoArticulo) + ') COLORS ' +
      '    ON COLORS.PREFIJO = SUBSTRING_INDEX(' +
      '       AP.CODIGO_UNIDAD_ARTPROP, ''/'', 2) ' +
      '  LEFT JOIN fza_articulos_propiedades APA ' +
      '    ON APA.CODIGO_ART_ART = AP.CODIGO_ART_ART ' +
      '   AND APA.CODIGO_PROP_ARTPROP = AP.CODIGO_PROP_ARTPROP ' +
      '   AND APA.CODIGO_UNIDAD_ARTPROP = '''' ' +
      '  LEFT JOIN fza_propiedades_valores PVA ' +
      '    ON PVA.ID_PV_ARTPROP = APA.ID_PV_ARTPROP ' +
      ' WHERE AP.CODIGO_ART_ART = ' + QuotedStr(ACodigoArticulo) +
      '   AND AP.CODIGO_UNIDAD_ARTPROP <> '''' ' +
      '   AND IFNULL(P.ESACTIVO_PROP, ''S'') = ''S'' ' +
      ' ORDER BY COLORS.COLOR_AV, P.NOMBRE_PROP_PROP';
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.ObtenerDescripcionArticulo(
  const ACodigoArticulo: string;
  out ADescripcion: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  ADescripcion := '';
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT DESCRIPCION_ART ' +
      '  FROM fza_articulos ' +
      ' WHERE CODIGO_ART_ART = :ARTICULO';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
      ADescripcion := oConsulta.FieldByName('DESCRIPCION_ART').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.FiltroDimension(
  ADimension: TDimensionFotos): string;
begin
  case ADimension of
    dfFamilia:
      Result :=
        '   AND LENGTH(TRIM(BASE.CODIGO_FAM_ART)) > 0 ' +
        '   AND A.CODIGO_FAM_ART = BASE.CODIGO_FAM_ART';
    dfProveedor:
      Result :=
        '   AND EXISTS (SELECT 1 ' +
        '                 FROM fza_articulos_proveedores BP ' +
        '                 JOIN fza_articulos_proveedores AP ' +
        '                   ON AP.CODIGO_PRV_AP = BP.CODIGO_PRV_AP ' +
        '                WHERE BP.CODIGO_ART_AP = BASE.CODIGO_ART_ART ' +
        '                  AND AP.CODIGO_ART_AP = A.CODIGO_ART_ART)';
  else
    Result :=
      '   AND EXISTS (SELECT 1 ' +
      '                 FROM fza_articulos_propiedades BTP ' +
      '                 JOIN fza_articulos_propiedades ATP ' +
      '                   ON ATP.CODIGO_PROP_ARTPROP = ' +
      '                      BTP.CODIGO_PROP_ARTPROP ' +
      '                  AND ATP.CODIGO_UNIDAD_ARTPROP = '''' ' +
      '                  AND ATP.CODIGO_ART_ART = A.CODIGO_ART_ART ' +
      '                  AND ((BTP.ID_PV_ARTPROP IS NOT NULL ' +
      '                        AND ATP.ID_PV_ARTPROP = BTP.ID_PV_ARTPROP) ' +
      '                       OR (LENGTH(TRIM(IFNULL(' +
      '                           BTP.VALOR_LIBRE_ARTPROP, ''''))) > 0 ' +
      '                           AND ATP.VALOR_LIBRE_ARTPROP = ' +
      '                               BTP.VALOR_LIBRE_ARTPROP)) ' +
      '                WHERE BTP.CODIGO_ART_ART = BASE.CODIGO_ART_ART ' +
      '                  AND BTP.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
      '                  AND BTP.CODIGO_UNIDAD_ARTPROP = '''')';
  end;
end;

function TRepositorioStockConsultaUniDAC.ConsultarFotosRelacionadas(
  const ASolicitud: TSolicitudFotosRelacionadasStock
  ): IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
  dim: TDimensionFotos;
  filtros: TDimensionesFotos;
begin
  oConsulta := NuevaConsulta;
  try
    filtros := ASolicitud.Filtros + [ASolicitud.Dimension];
    oConsulta.SQL.Clear;
    oConsulta.SQL.Add('SELECT A.CODIGO_ART_ART,');
    oConsulta.SQL.Add('       A.DESCRIPCION_ART,');
    oConsulta.SQL.Add('       COALESCE((');
    oConsulta.SQL.Add('         SELECT GROUP_CONCAT(DISTINCT AV.AV');
    oConsulta.SQL.Add('                ORDER BY AV.ORDEN_AV, AV.AV');
    oConsulta.SQL.Add('                SEPARATOR '', '')');
    oConsulta.SQL.Add('           FROM fza_articulos_skus SKU');
    oConsulta.SQL.Add('           JOIN fza_articulos_stockactual STK');
    oConsulta.SQL.Add('             ON STK.CODIGO_UNIDAD_STK =');
    oConsulta.SQL.Add('                SKU.CODIGO_UNIDAD_SKU');
    oConsulta.SQL.Add('            AND STK.CANTIDAD_STK > 0');
    oConsulta.SQL.Add('           JOIN fza_atributos_sku SA');
    oConsulta.SQL.Add('             ON SA.CODIGO_UNIDAD_SKU_SA =');
    oConsulta.SQL.Add('                SKU.CODIGO_UNIDAD_SKU');
    oConsulta.SQL.Add('           JOIN fza_atributos_valores AV');
    oConsulta.SQL.Add('             ON AV.ID_AV = SA.ID_AV_SA');
    oConsulta.SQL.Add('          WHERE SKU.CODIGO_ART_SKU =');
    oConsulta.SQL.Add('                A.CODIGO_ART_ART');
    oConsulta.SQL.Add('            AND SKU.ESACTIVO_SKU = ''S''');
    oConsulta.SQL.Add(
      '            AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')), '''') AS COLORES,');
    oConsulta.SQL.Add('       COALESCE((');
    oConsulta.SQL.Add('         SELECT GROUP_CONCAT(DISTINCT AV.AV');
    oConsulta.SQL.Add('                ORDER BY AV.ORDEN_AV, AV.AV');
    oConsulta.SQL.Add('                SEPARATOR '', '')');
    oConsulta.SQL.Add('           FROM fza_articulos_skus SKU');
    oConsulta.SQL.Add('           JOIN fza_articulos_stockactual STK');
    oConsulta.SQL.Add('             ON STK.CODIGO_UNIDAD_STK =');
    oConsulta.SQL.Add('                SKU.CODIGO_UNIDAD_SKU');
    oConsulta.SQL.Add('            AND STK.CANTIDAD_STK > 0');
    oConsulta.SQL.Add('           JOIN fza_atributos_sku SA');
    oConsulta.SQL.Add('             ON SA.CODIGO_UNIDAD_SKU_SA =');
    oConsulta.SQL.Add('                SKU.CODIGO_UNIDAD_SKU');
    oConsulta.SQL.Add('           JOIN fza_atributos_valores AV');
    oConsulta.SQL.Add('             ON AV.ID_AV = SA.ID_AV_SA');
    oConsulta.SQL.Add('          WHERE SKU.CODIGO_ART_SKU =');
    oConsulta.SQL.Add('                A.CODIGO_ART_ART');
    oConsulta.SQL.Add('            AND SKU.ESACTIVO_SKU = ''S''');
    oConsulta.SQL.Add(
      '            AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'')), '''') AS TALLAS');
    oConsulta.SQL.Add('  FROM fza_articulos BASE');
    oConsulta.SQL.Add('  JOIN fza_articulos A');
    oConsulta.SQL.Add('    ON A.CODIGO_ART_ART <> BASE.CODIGO_ART_ART');
    oConsulta.SQL.Add(' WHERE BASE.CODIGO_ART_ART = :ARTICULO');
    oConsulta.SQL.Add('   AND A.ESACTIVO_ART = ''S''');
    for dim := Low(TDimensionFotos) to High(TDimensionFotos) do
    begin
      if dim in filtros then
        oConsulta.SQL.Add(FiltroDimension(dim));
    end;
    oConsulta.SQL.Add('   AND EXISTS (');
    oConsulta.SQL.Add('       SELECT 1');
    oConsulta.SQL.Add('         FROM fza_articulos_skus SKU');
    oConsulta.SQL.Add('         JOIN fza_articulos_stockactual STK');
    oConsulta.SQL.Add('           ON STK.CODIGO_UNIDAD_STK =');
    oConsulta.SQL.Add('              SKU.CODIGO_UNIDAD_SKU');
    oConsulta.SQL.Add('          AND STK.CANTIDAD_STK > 0');
    oConsulta.SQL.Add('        WHERE SKU.CODIGO_ART_SKU = A.CODIGO_ART_ART');
    oConsulta.SQL.Add('          AND SKU.ESACTIVO_SKU = ''S'')');
    oConsulta.SQL.Add(' ORDER BY A.DESCRIPCION_ART, A.CODIGO_ART_ART');
    oConsulta.ParamByName('ARTICULO').AsString :=
      ASolicitud.CodigoArticulo;
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.BuscarArticulos(
  const ACodigoTarifa: string): IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, ' +
      '       f.DESCRIPCION_FAM, pv.PV AS TEMPORADA, ' +
      '       p.RAZON_SOCIAL_PRV AS PROVEEDOR, ' +
      '       COALESCE((SELECT GROUP_CONCAT(DISTINCT ' +
      '                         ap2.REF_PROVEEDOR_AP ' +
      '                         ORDER BY ap2.REF_PROVEEDOR_AP ' +
      '                         SEPARATOR '' '') ' +
      '                   FROM fza_articulos_proveedores ap2 ' +
      '                  WHERE ap2.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
      '                    AND ap2.REF_PROVEEDOR_AP IS NOT NULL ' +
      '                    AND ap2.REF_PROVEEDOR_AP <> ''''), '''') ' +
      '         AS REF_PROVEEDOR, ' +
      '       (SELECT t.PRECIO_FINAL_ARTTAR ' +
      '          FROM fza_articulos_tarifas t ' +
      '          JOIN fza_tarifas tt ' +
      '            ON tt.CODIGO_TAR_ARTTAR = t.CODIGO_TAR_ARTTAR ' +
      '         WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
      '           AND IFNULL(t.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
      '           AND t.ESACTIVO_ARTTAR = ''S'' ' +
      '           AND tt.CODIGO_TAR_ARTTAR = :TARIFA ' +
      '         LIMIT 1) AS PRECIO_PVP ' +
      '  FROM fza_articulos a ' +
      '  LEFT JOIN fza_articulos_familias f ' +
      '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
      '  LEFT JOIN fza_articulos_propiedades ap ' +
      '    ON ap.CODIGO_ART_ART = a.CODIGO_ART_ART ' +
      '   AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
      '   AND ap.CODIGO_UNIDAD_ARTPROP = '''' ' +
      '  LEFT JOIN fza_propiedades_valores pv ' +
      '    ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP ' +
      '  LEFT JOIN fza_articulos_proveedores aprv ' +
      '    ON aprv.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
      '   AND aprv.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
      '  LEFT JOIN fza_proveedores p ' +
      '    ON p.CODIGO_PRV_PRV = aprv.CODIGO_PRV_AP ' +
      ' WHERE a.ESACTIVO_ART = ''S'' ' +
      ' ORDER BY a.CODIGO_ART_ART';
    oConsulta.ParamByName('TARIFA').AsString := ACodigoTarifa;
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioStockConsultaUniDAC.ListarTallas(
  const ACodigoArticulo: string;
  const AColores: TArray<string>): TArray<TInfoColumna>;
var
  iAcPivot: Integer;
  inf: TInfoColumna;
  oConsulta: TUniQuery;
  oLista: TList<TInfoColumna>;
begin
  oLista := TList<TInfoColumna>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT ID_AC_ACA ' +
      '  FROM fza_articulos_conjuntos_asign ' +
      ' WHERE CODIGO_ART_ACA = :ARTICULO ' +
      '   AND ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
      'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
      'AR452.CODIGO_ART_ART = :ARTICULO) AND EJ452.EJE_VA = ''P'') ' +
      ' ORDER BY ID_VA_ACA LIMIT 1';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    iAcPivot := 0;
    if not oConsulta.IsEmpty then
      iAcPivot := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
    oConsulta.Close;
    oConsulta.SQL.Text :=
      ConstruirSqlListarTallasStock(AColores, iAcPivot);
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    if iAcPivot > 0 then
      oConsulta.ParamByName('CONJUNTO').AsInteger := iAcPivot;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      inf := Default(TInfoColumna);
      inf.Codigo := oConsulta.FieldByName('AV').AsString;
      inf.Texto := inf.Codigo;
      inf.Hex := '';
      inf.EsColor := False;
      oLista.Add(inf);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oLista);
  end;
end;

function TRepositorioStockConsultaUniDAC.CampoCantidadStock(
  AEstado: TEstadoStock): string;
begin
  case AEstado of
    esExistencias:
      Result := 'STK.CANTIDAD_STK';
    esEntradas:
      Result :=
        'STK.CANTIDAD_ENT_COMPRA_STK + STK.CANTIDAD_ENT_TRASPASO_STK + ' +
        'STK.CANTIDAD_ENT_DEPOSITO_STK + STK.CANTIDAD_ENT_REGULAR_STK + ' +
        'STK.CANTIDAD_ENT_ALBENTRADA_STK';
    esSalidas:
      Result :=
        'STK.CANTIDAD_SAL_TRASPASO_STK + STK.CANTIDAD_SAL_DEPOSITO_STK + ' +
        'STK.CANTIDAD_SAL_VENTA_STK + STK.CANTIDAD_SAL_ALBVENTA_STK';
    esVentas:
      Result := 'STK.CANTIDAD_SAL_VENTA_STK';
    esRegularizadas:
      Result := 'STK.CANTIDAD_ENT_REGULAR_STK';
    esEntradaTraspaso:
      Result := 'STK.CANTIDAD_ENT_TRASPASO_STK';
    esSalidaTraspaso:
      Result := 'STK.CANTIDAD_SAL_TRASPASO_STK';
    esEntradaCompra:
      Result := 'STK.CANTIDAD_ENT_COMPRA_STK';
    esEntradaDeposito:
      Result := 'STK.CANTIDAD_ENT_DEPOSITO_STK';
    esSalidaDeposito:
      Result := 'STK.CANTIDAD_SAL_DEPOSITO_STK';
    esSalidaAlbVenta:
      Result := 'STK.CANTIDAD_SAL_ALBVENTA_STK';
    esEntradaAlbEntrada:
      Result := 'STK.CANTIDAD_ENT_ALBENTRADA_STK';
    esPdteServir:
      Result := 'STK.CANTIDAD_PTE_SERVIR_STK';
  else
    Result := '0';
  end;
end;

function TRepositorioStockConsultaUniDAC.EstadoBaseSelectFor(
  const ASolicitud: TSolicitudPivoteStock;
  AEstado: TEstadoStock): string;
const
  CSelSku =
    'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
    '       MAX(ATR.COLOR_AV) AS COLOR_AV, ' +
    '       MAX(ATR.TALLA_AV) AS TALLA_AV, ' +
    '       MAX(ATR.PESTANA_AV) AS PESTANA_AV, ';
var
  sAlmacenes: string;
  sAtributos: string;
  sCampo: string;
  sEstado: string;
begin
  sAlmacenes := ListaSql(ASolicitud.Almacenes);
  sEstado := IntToStr(Ord(AEstado));
  sAtributos :=
    '  LEFT JOIN (SELECT SKU2.CODIGO_UNIDAD_SKU, ' +
    '          MAX(CASE WHEN AV2.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = SKU2.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
    '                   THEN AV2.AV END) AS COLOR_AV, ' +
    '          MAX(CASE WHEN AV2.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = SKU2.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
    '                   THEN AV2.AV END) AS TALLA_AV, ' +
    '          MAX(CASE WHEN AV2.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = SKU2.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''S'') ' +
    '                   THEN AV2.AV END) AS PESTANA_AV ' +
    '     FROM fza_articulos_skus SKU2 ' +
    '     LEFT JOIN fza_atributos_sku SA2 ' +
    '       ON SA2.CODIGO_UNIDAD_SKU_SA = SKU2.CODIGO_UNIDAD_SKU ' +
    '     LEFT JOIN fza_atributos_valores AV2 ' +
    '       ON AV2.ID_AV = SA2.ID_AV_SA ' +
    '    WHERE SKU2.CODIGO_ART_SKU = ' +
    QuotedStr(ASolicitud.CodigoArticulo) +
    '    GROUP BY SKU2.CODIGO_UNIDAD_SKU) ATR ' +
    '    ON ATR.CODIGO_UNIDAD_SKU = SKU.CODIGO_UNIDAD_SKU ';
  if AEstado = esPdteRecibir then
    Result := CSelSku +
      '       PDR.CODIGO_ALM_PDR AS ALM, ' +
      '       SUM(PDR.CANTIDAD_PDR) AS CANTIDAD, ' +
      '       ' + sEstado + ' AS ESTADO_NUM ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_articulos_pdte_recibir PDR ' +
      '    ON PDR.CODIGO_UNIDAD_PDR = SKU.CODIGO_UNIDAD_SKU ' +
      sAtributos +
      ' WHERE SKU.CODIGO_ART_SKU = ' +
      QuotedStr(ASolicitud.CodigoArticulo) +
      '   AND PDR.CODIGO_ALM_PDR IN (' + sAlmacenes + ') ' +
      ' GROUP BY SKU.CODIGO_UNIDAD_SKU, PDR.CODIGO_ALM_PDR'
  else if AEstado in [esPdteTraspasar, esPdteRecTraspaso] then
  begin
    // FZ-ISSUE-251: vi_articulos_pdte_traspaso (script 766).
    if AEstado = esPdteTraspasar then
      sCampo := 'V.CANTIDAD_PTE_TRASPASAR'
    else
      sCampo := 'V.CANTIDAD_PTE_RECTRASPASAR';
    Result := CSelSku +
      '       V.CODIGO_ALM_ALM AS ALM, ' +
      '       SUM(' + sCampo + ') AS CANTIDAD, ' +
      '       ' + sEstado + ' AS ESTADO_NUM ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN vi_articulos_pdte_traspaso V ' +
      '    ON V.CODIGO_UNIDAD_SKU = SKU.CODIGO_UNIDAD_SKU ' +
      sAtributos +
      ' WHERE SKU.CODIGO_ART_SKU = ' +
      QuotedStr(ASolicitud.CodigoArticulo) +
      '   AND V.CODIGO_ALM_ALM IN (' + sAlmacenes + ') ' +
      ' GROUP BY SKU.CODIGO_UNIDAD_SKU, V.CODIGO_ALM_ALM';
  end
  else if AEstado = esDisponible then
    Result := CSelSku +
      '       STK.CODIGO_ALM_STK AS ALM, ' +
      '       SUM(STK.CANTIDAD_STK - ' +
      '           COALESCE(V.CANTIDAD_PTE_TRASPASAR, 0)) AS CANTIDAD, ' +
      '       ' + sEstado + ' AS ESTADO_NUM ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_articulos_stockactual STK ' +
      '    ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU ' +
      '  LEFT JOIN vi_articulos_pdte_traspaso V ' +
      '    ON V.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK ' +
      '   AND V.CODIGO_ALM_ALM = STK.CODIGO_ALM_STK ' +
      sAtributos +
      ' WHERE SKU.CODIGO_ART_SKU = ' +
      QuotedStr(ASolicitud.CodigoArticulo) +
      '   AND STK.CODIGO_ALM_STK IN (' + sAlmacenes + ') ' +
      ' GROUP BY SKU.CODIGO_UNIDAD_SKU, STK.CODIGO_ALM_STK'
  else if (AEstado = esPrestadas) or (AEstado = esTodoAlaVez) then
    Result :=
      'SELECT '''' AS CODIGO_UNIDAD_SKU, NULL AS COLOR_AV, ' +
      '       NULL AS TALLA_AV, NULL AS PESTANA_AV, '''' AS ALM, ' +
      '       0 AS CANTIDAD, ' +
      '       ' + sEstado + ' AS ESTADO_NUM ' +
      '  FROM dual WHERE 0'
  else
  begin
    sCampo := CampoCantidadStock(AEstado);
    Result := CSelSku +
      '       STK.CODIGO_ALM_STK AS ALM, ' +
      '       SUM(' + sCampo + ') AS CANTIDAD, ' +
      '       ' + sEstado + ' AS ESTADO_NUM ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_articulos_stockactual STK ' +
      '    ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU ' +
      sAtributos +
      ' WHERE SKU.CODIGO_ART_SKU = ' +
      QuotedStr(ASolicitud.CodigoArticulo) +
      '   AND STK.CODIGO_ALM_STK IN (' + sAlmacenes + ') ' +
      ' GROUP BY SKU.CODIGO_UNIDAD_SKU, STK.CODIGO_ALM_STK';
  end;
end;

function TRepositorioStockConsultaUniDAC.EstadoBaseSelect(
  const ASolicitud: TSolicitudPivoteStock): string;
const
  ESTADOS_TODO_SIMPLE: array[0..7] of TEstadoStock = (
    esExistencias, esEntradas, esSalidas,
    esPdteServir, esPdteRecibir,
    esPdteTraspasar, esPdteRecTraspaso, esDisponible);
  ESTADOS_TODO_FULL: array[0..15] of TEstadoStock = (
    esExistencias,
    esPdteServir, esPdteRecibir,
    esPdteTraspasar, esPdteRecTraspaso, esDisponible,
    esEntradaCompra,
    esEntradaTraspaso, esSalidaTraspaso,
    esEntradaDeposito, esSalidaDeposito,
    esVentas, esRegularizadas,
    esSalidaAlbVenta, esEntradaAlbEntrada,
    esPrestadas);
var
  est: TEstadoStock;
  i: Integer;
begin
  if ASolicitud.Estado <> esTodoAlaVez then
    Result := EstadoBaseSelectFor(ASolicitud, ASolicitud.Estado)
  else
  begin
    Result := '';
    if ASolicitud.ModoDesglosado then
    begin
      for i := Low(ESTADOS_TODO_FULL) to High(ESTADOS_TODO_FULL) do
      begin
        est := ESTADOS_TODO_FULL[i];
        if Result <> '' then
          Result := Result + ' UNION ALL ';
        Result := Result +
          '(' + EstadoBaseSelectFor(ASolicitud, est) + ')';
      end;
    end
    else
    begin
      for i := Low(ESTADOS_TODO_SIMPLE) to High(ESTADOS_TODO_SIMPLE) do
      begin
        est := ESTADOS_TODO_SIMPLE[i];
        if Result <> '' then
          Result := Result + ' UNION ALL ';
        Result := Result +
          '(' + EstadoBaseSelectFor(ASolicitud, est) + ')';
      end;
    end;
  end;
end;

function TRepositorioStockConsultaUniDAC.ConstruirSqlPivote(
  const ASolicitud: TSolicitudPivoteStock;
  const ATallas: TArray<TInfoColumna>): string;
var
  bEsTodo: Boolean;
  i: Integer;
  sBase: string;
  sColumnas: string;
  sExtraGrupo: string;
  sExtraOrden: string;
  sExtraSelect: string;
  sFiltroColores: string;
  sFiltroPestana: string;
  sGrupo: string;
  sHaving: string;
  sJoin: string;
  sOrden: string;
  sOrigen: string;
  sWhere: string;
begin
  sBase := EstadoBaseSelect(ASolicitud);
  bEsTodo := ASolicitud.Estado = esTodoAlaVez;
  sColumnas := '';
  for i := 0 to High(ATallas) do
  begin
    sColumnas := sColumnas + Format(
      ', SUM(CASE WHEN B.TALLA_AV = %s ' +
      'THEN B.CANTIDAD ELSE 0 END) AS T%d',
      [QuotedStr(ATallas[i].Codigo), i]);
  end;
  sFiltroColores := ListaSql(ASolicitud.Colores);
  sFiltroPestana := FiltroPestanaBase(ASolicitud);
  sHaving := '';
  if ASolicitud.OcultarCeros then
  begin
    // El total puede ser cero aunque haya cantidades compensadas entre
    // tallas (por ejemplo, S=-3 y L=3). En ese caso la fila contiene stock
    // significativo y no debe ocultarse.
    sHaving := ' HAVING (COALESCE(SUM(B.CANTIDAD), 0) <> 0';
    for i := 0 to High(ATallas) do
      sHaving := sHaving + Format(
        ' OR COALESCE(SUM(CASE WHEN B.TALLA_AV = %s ' +
        'THEN B.CANTIDAD ELSE 0 END), 0) <> 0',
        [QuotedStr(ATallas[i].Codigo)]);
    sHaving := sHaving + ') ';
  end;
  if bEsTodo then
  begin
    sExtraSelect := ', B.ESTADO_NUM AS ESTADO_NUM';
    sExtraGrupo := ', B.ESTADO_NUM';
    sExtraOrden := ', B.ESTADO_NUM';
  end
  else
  begin
    sExtraSelect := '';
    sExtraGrupo := '';
    sExtraOrden := '';
  end;
  if ASolicitud.PorColor then
  begin
    sOrigen :=
      '(SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV, ' +
      '        MIN(AV.ID_ATB_AV) AS ID_ATB_AV ' +
      '   FROM fza_articulos_skus SKU ' +
      '   JOIN fza_atributos_sku SA ' +
      '     ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '   JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      '  WHERE SKU.CODIGO_ART_SKU = ' +
      QuotedStr(ASolicitud.CodigoArticulo) +
      '    AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')' +
      '    AND AV.AV IN (' + sFiltroColores + ') ' +
      '  GROUP BY AV.AV) C';
    sJoin :=
      ' LEFT JOIN fza_atributos_basicos ATB ' +
      '   ON ATB.ID_ATB = C.ID_ATB_AV ' +
      ' LEFT JOIN (' + sBase + ') B ON B.COLOR_AV = C.AV' +
      sFiltroPestana;
    if bEsTodo then
      sWhere := ' WHERE B.ESTADO_NUM IS NOT NULL '
    else
      sWhere := '';
    sGrupo :=
      ' GROUP BY C.AV, ATB.HEX_ATB, C.ORDEN_AV' + sExtraGrupo;
    sOrden := ' ORDER BY C.ORDEN_AV, C.AV' + sExtraOrden;
    Result :=
      'SELECT C.AV AS GRUPO, COALESCE(ATB.HEX_ATB, '''') AS HEX, ' +
      '       C.ORDEN_AV AS ORDEN' + sExtraSelect + sColumnas +
      ', SUM(B.CANTIDAD) AS TOTAL ' +
      '  FROM ' + sOrigen + sJoin + sWhere + sGrupo + sHaving + sOrden;
  end
  else if Length(ASolicitud.Almacenes) = 0 then
    Result :=
      'SELECT '''' AS GRUPO, '''' AS HEX, 0 AS ORDEN' +
      IfThen(bEsTodo, ', 0 AS ESTADO_NUM', '') +
      sColumnas + ', 0 AS TOTAL FROM dual WHERE 0'
  else
    Result :=
      'SELECT ALM.CODIGO_ALM_ALM AS GRUPO, '''' AS HEX, ' +
      '       ALM.ORDEN_ALM AS ORDEN' + sExtraSelect + sColumnas +
      ', SUM(B.CANTIDAD) AS TOTAL ' +
      '  FROM fza_almacenes ALM ' +
      '  LEFT JOIN (' + sBase + ') B ' +
      '    ON B.ALM = ALM.CODIGO_ALM_ALM ' +
      '   AND (B.COLOR_AV IN (' + sFiltroColores + ') ' +
      '        OR B.COLOR_AV IS NULL) ' + sFiltroPestana +
      ' WHERE ALM.CODIGO_ALM_ALM IN (' +
      ListaSql(ASolicitud.Almacenes) + ') ' +
      IfThen(bEsTodo, '   AND B.ESTADO_NUM IS NOT NULL ', '') +
      ' GROUP BY ALM.CODIGO_ALM_ALM, ALM.ORDEN_ALM' +
      sExtraGrupo + ' ' + sHaving +
      ' ORDER BY ALM.ORDEN_ALM, ALM.CODIGO_ALM_ALM' + sExtraOrden;
end;

function TRepositorioStockConsultaUniDAC.Consultar(
  const ASolicitud: TSolicitudPivoteStock;
  const ATallas: TArray<TInfoColumna>): IResultadoConsultaStock;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    if Trim(ASolicitud.CodigoArticulo) = '' then
      oConsulta.SQL.Text :=
        'SELECT '''' AS GRUPO, '''' AS HEX, 0 AS ORDEN, ' +
        '       0 AS TOTAL FROM dual WHERE 0'
    else
      oConsulta.SQL.Text := ConstruirSqlPivote(ASolicitud, ATallas);
    oConsulta.Open;
    Result := ResultadoConsulta(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Con una pestaña elegida (la copa) solo cuentan los SKU de ese valor.
function TRepositorioStockConsultaUniDAC.FiltroPestanaBase(
  const ASolicitud: TSolicitudPivoteStock): string;
begin
  Result := '';
  if ASolicitud.Pestana <> '' then
    Result := ' AND B.PESTANA_AV = ' + QuotedStr(ASolicitud.Pestana) + ' ';
end;

// Valores de pestañas que tienen los SKU del artículo, con el total del
// estado en los almacenes y colores elegidos. NOMBRE_EJE es el rótulo del
// atributo en el tipo de variación (Copa).
function TRepositorioStockConsultaUniDAC.ConstruirSqlPestanas(
  const ASolicitud: TSolicitudPivoteStock): string;
begin
  Result :=
    'SELECT P.AV, P.ORDEN_AV, P.NOMBRE_EJE, ' +
    '       COALESCE(SUM(B.CANTIDAD), 0) AS TOTAL ' +
    '  FROM (SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV, ' +
    '               MAX(COALESCE(NULLIF(VA.NOMBRE_VA, ''''), ' +
    '                            AV.ID_VA_AV)) AS NOMBRE_EJE ' +
    '          FROM fza_articulos_skus SKU ' +
    '          JOIN fza_atributos_sku SA ' +
    '            ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
    '          JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    '          JOIN VI_VARIACIONES_EJES EJS ' +
    '            ON EJS.ID_VAR_VA = SKU.CODIGO_VAR_SKU ' +
    '           AND EJS.ID_ATB_VA = AV.ID_VA_AV ' +
    '           AND EJS.EJE_VA = ''S'' ' +
    '          LEFT JOIN fza_variaciones_atributos VA ' +
    '            ON VA.ID_VAR_VA = EJS.ID_VAR_VA ' +
    '           AND VA.ID_ATB_VA = EJS.ID_ATB_VA ' +
    '         WHERE SKU.CODIGO_ART_SKU = ' +
    QuotedStr(ASolicitud.CodigoArticulo) +
    '         GROUP BY AV.AV) P ' +
    '  LEFT JOIN (' + EstadoBaseSelect(ASolicitud) + ') B ' +
    '    ON B.PESTANA_AV = P.AV ' +
    '   AND (B.COLOR_AV IN (' + ListaSql(ASolicitud.Colores) + ') ' +
    '        OR B.COLOR_AV IS NULL) ' +
    ' GROUP BY P.AV, P.ORDEN_AV, P.NOMBRE_EJE ' +
    ' ORDER BY P.ORDEN_AV, P.AV';
end;

function TRepositorioStockConsultaUniDAC.ConsultarPestanas(
  const ASolicitud: TSolicitudPivoteStock): TModeloPestanasEje;
var
  oConsulta: TUniQuery;
  oValor: TValorPestanaEje;
begin
  Result := Default(TModeloPestanasEje);
  Result.HayTotales := ASolicitud.Estado <> esTodoAlaVez;
  if Trim(ASolicitud.CodigoArticulo) <> '' then
  begin
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text := ConstruirSqlPestanas(ASolicitud);
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oValor.Codigo := oConsulta.FieldByName('AV').AsString;
        oValor.Total := oConsulta.FieldByName('TOTAL').AsFloat;
        Result.NombreEje := oConsulta.FieldByName('NOMBRE_EJE').AsString;
        Result.Valores := Result.Valores + [oValor];
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function LeerArticuloStockConPestanas(AConsulta: TUniQuery;
  const ACodigo: string; out AArticulo, ANombre: string): Boolean;
begin
  AConsulta.SQL.Text :=
    'SELECT A.CODIGO_ART_ART, VA.NOMBRE_VA ' +
    'FROM fza_articulos A ' +
    'LEFT JOIN VI_VARIACIONES_EJES EJ ' +
    'ON EJ.ID_VAR_VA = A.TIPO_VARIACION_ART AND EJ.EJE_VA = ''S'' ' +
    'LEFT JOIN fza_variaciones_atributos VA ON VA.ID_VAR_VA = EJ.ID_VAR_VA ' +
    'AND VA.ID_ATB_VA = EJ.ID_ATB_VA ' +
    'WHERE A.CODIGO_ART_ART = :CODIGO OR EXISTS ' +
    '(SELECT 1 FROM fza_articulos_skus SK ' +
    'WHERE SK.CODIGO_ART_SKU = A.CODIGO_ART_ART ' +
    'AND SK.CODIGO_UNIDAD_SKU = :CODIGO) LIMIT 1';
  AConsulta.ParamByName('CODIGO').AsString := ACodigo;
  AConsulta.Open;
  Result := not AConsulta.IsEmpty;
  if Result then
  begin
    AArticulo := AConsulta.FieldByName('CODIGO_ART_ART').AsString;
    ANombre := AConsulta.FieldByName('NOMBRE_VA').AsString;
  end;
  AConsulta.Close;
end;

function LeerColorSkuStock(AConsulta: TUniQuery;
  const ACodigo: string): string;
begin
  AConsulta.SQL.Text :=
    'SELECT AV.AV FROM fza_articulos_skus SK ' +
    'JOIN fza_atributos_sku SA ' +
    'ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    'JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    'JOIN VI_VARIACIONES_EJES EJ ON EJ.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
    'AND EJ.ID_ATB_VA = AV.ID_VA_AV AND EJ.EJE_VA = ''F'' ' +
    'WHERE SK.CODIGO_UNIDAD_SKU = :CODIGO LIMIT 1';
  AConsulta.ParamByName('CODIGO').AsString := ACodigo;
  AConsulta.Open;
  Result := AConsulta.FieldByName('AV').AsString;
  AConsulta.Close;
end;

function ColumnasPendientesStockPestanas: string;
begin
  Result := Format(
      ', SUM(CASE WHEN B.ESTADO_NUM = %d THEN B.CANTIDAD ELSE 0 END) ' +
      'AS `Pte. traspasar`, ' +
      'SUM(CASE WHEN B.ESTADO_NUM = %d THEN B.CANTIDAD ELSE 0 END) ' +
      'AS `Pte. recibir trasp.`, ' +
      'SUM(CASE WHEN B.ESTADO_NUM = %d THEN B.CANTIDAD ELSE 0 END) ' +
      'AS `Pte. recibir compra`, ' +
      'SUM(CASE WHEN B.ESTADO_NUM = %d THEN B.CANTIDAD ' +
      'WHEN B.ESTADO_NUM = %d THEN -B.CANTIDAD ELSE 0 END) ' +
      'AS Disponible, ALM.CODIGO_ALM_ALM AS CODIGO_ALM_STOCK',
      [Ord(esPdteTraspasar), Ord(esPdteRecTraspaso),
       Ord(esPdteRecibir), Ord(esExistencias), Ord(esPdteTraspasar)]);
end;

function SqlDetalleStockConPestanas(
  ARepositorio: TRepositorioStockConsultaUniDAC;
  const ASolicitud: TSolicitudPivoteStock;
  const ATallas: TArray<TInfoColumna>; AConPendientes: Boolean): string;
var
  sBase, sColumnas, sCodigo, sFiltro, sHaving: string;
  rTalla: TInfoColumna;
begin
  sBase := ARepositorio.EstadoBaseSelectFor(ASolicitud, esExistencias);
  if AConPendientes then
    sBase := sBase + ' UNION ALL ' +
      ARepositorio.EstadoBaseSelectFor(ASolicitud, esPdteTraspasar) +
      ' UNION ALL ' +
      ARepositorio.EstadoBaseSelectFor(ASolicitud, esPdteRecTraspaso) +
      ' UNION ALL ' +
      ARepositorio.EstadoBaseSelectFor(ASolicitud, esPdteRecibir);
  sColumnas := '';
  for rTalla in ATallas do
    sColumnas := sColumnas + Format(
      ', COALESCE(SUM(CASE WHEN B.ESTADO_NUM = %d ' +
      'AND B.TALLA_AV = %s THEN B.CANTIDAD ELSE 0 END), 0) AS `%s`',
      [Ord(esExistencias), QuotedStr(rTalla.Codigo),
       StringReplace(rTalla.Texto, '`', '``', [rfReplaceAll])]);
  sCodigo := 'ALM.NOMBRE_ALM_ALM AS Almacen, ' +
    'COALESCE(D.COLOR_AV, '''') AS Color';
  if not AConPendientes then
    sCodigo := 'CONCAT(' + QuotedStr(ASolicitud.CodigoArticulo) +
      ', CASE WHEN D.COLOR_AV <> '''' THEN CONCAT(''/'', D.COLOR_AV) ' +
      'ELSE '''' END) AS Codigo, ALM.NOMBRE_ALM_ALM AS Almacen';
  sFiltro := '';
  if Length(ASolicitud.Colores) > 0 then
    sFiltro := ' AND D.COLOR_AV IN (' +
      ARepositorio.ListaSql(ASolicitud.Colores) + ')';
  sHaving := '';
  if not AConPendientes then
    sHaving := ' HAVING MAX(ABS(B.CANTIDAD)) <> 0';
  Result := 'SELECT ' + sCodigo +
    ', D.PESTANA_AV AS COPA' + sColumnas +
    Format(', COALESCE(SUM(CASE WHEN B.ESTADO_NUM = %d ' +
      'THEN B.CANTIDAD ELSE 0 END), 0) AS Total', [Ord(esExistencias)]);
  if AConPendientes then
    Result := Result + ColumnasPendientesStockPestanas;
  Result := Result + ' FROM fza_almacenes ALM ' +
    'CROSS JOIN (SELECT DISTINCT COLOR_AV, PESTANA_AV FROM (' +
    sBase + ') E) D LEFT JOIN (' + sBase + ') B ' +
    'ON B.ALM = ALM.CODIGO_ALM_ALM ' +
    'AND B.COLOR_AV <=> D.COLOR_AV AND B.PESTANA_AV <=> D.PESTANA_AV ' +
    'WHERE ALM.CODIGO_ALM_ALM IN (' +
    ARepositorio.ListaSql(ASolicitud.Almacenes) + ')' + sFiltro +
    ' GROUP BY ALM.CODIGO_ALM_ALM, ALM.NOMBRE_ALM_ALM, ' +
    'D.COLOR_AV, D.PESTANA_AV' + sHaving +
    ' ORDER BY ALM.NOMBRE_ALM_ALM, D.COLOR_AV, D.PESTANA_AV';
end;

function AbrirConsultaStockPorPestanas(AConsulta: TUniQuery;
  const ACodigo: string; AConPendientes: Boolean): Boolean;
var
  oLectura: TUniQuery;
  oRepositorio: TRepositorioStockConsultaUniDAC;
  oAlmacenes: IResultadoConsultaStock;
  rSolicitud: TSolicitudPivoteStock;
  aTallas: TArray<TInfoColumna>;
  sNombre, sArticulo, sColor: string;
begin
  oLectura := TUniQuery.Create(nil);
  oRepositorio := TRepositorioStockConsultaUniDAC.Create(
    AConsulta.Connection);
  try
    oLectura.Connection := AConsulta.Connection;
    Result := LeerArticuloStockConPestanas(
      oLectura, ACodigo, sArticulo, sNombre);
    Result := Result and (AConPendientes or (sNombre <> ''));
    if Result then
    begin
      rSolicitud := Default(TSolicitudPivoteStock);
      rSolicitud.CodigoArticulo := sArticulo;
      sColor := LeerColorSkuStock(oLectura, ACodigo);
      if sColor <> '' then
        rSolicitud.Colores := [sColor];
      oAlmacenes := oRepositorio.ConsultarAlmacenes;
      while not oAlmacenes.DataSet.Eof do
      begin
        rSolicitud.Almacenes := rSolicitud.Almacenes +
          [oAlmacenes.DataSet.FieldByName('CODIGO_ALM_ALM').AsString];
        oAlmacenes.DataSet.Next;
      end;
      aTallas := oRepositorio.ListarTallas(sArticulo, rSolicitud.Colores);
      AConsulta.Close;
      AConsulta.SQL.Text := SqlDetalleStockConPestanas(
        oRepositorio, rSolicitud, aTallas, AConPendientes);
      AConsulta.Open;
      AConsulta.FieldByName('COPA').DisplayLabel := sNombre;
      AConsulta.FieldByName('COPA').Visible := sNombre <> '';
    end;
  finally
    oAlmacenes := nil;
    FreeAndNil(oRepositorio);
    FreeAndNil(oLectura);
  end;
end;

function CrearServiciosStockConsultaUniDAC(
  AConexion: TUniConnection): TServiciosStockConsulta;
var
  oRepositorio: TRepositorioStockConsultaUniDAC;
begin
  oRepositorio := TRepositorioStockConsultaUniDAC.Create(AConexion);
  Result.Catalogos := oRepositorio;
  Result.Pivote := oRepositorio;
end;

end.
