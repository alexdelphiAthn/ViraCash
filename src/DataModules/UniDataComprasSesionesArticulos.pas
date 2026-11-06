{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesArticulos                              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de artículos y SKU de una sesión de compra.                  }
{******************************************************************************}
unit UniDataComprasSesionesArticulos;

interface

uses
  Uni,
  inLibFotos,
  inLibComprasSesionesLecturasIntf,
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesiones;

function ResolverCodigoSku(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArt: string;
  AIdAvPivot, AIdAvFila: Integer;
  AIdAvPestana: Integer = 0): string;
// AConexion es la de la unidad de trabajo de la materialización: si
// falla el documento, el alta de artículos, SKU y EAN se deshace con
// ella (FZ-ISSUE-142). AOpcionesTarifa dice qué hacer con los artículos
// que ya tienen precio en la tarifa (FZ-ISSUE-638).
procedure MaterializarArticulosSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AUsuario: string;
  const AOpcionesTarifa: TOpcionesTarifaSesion);

procedure MigrarFotosArticulosSesion(
  ADM: TdmComprasSesiones;
  AFotos: TFotosArticulos;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AUsuario: string);

implementation
uses
  System.SysUtils,
  Data.DB, DBAccess,
  inLibEAN13,
  UniDataComprasSesionesPropiedades,
  UniDataCodigosBarrasSesion,
  UniDataValoresAutomaticosRepositorio,
  UniDataComprasSesionesColores,
  UniDataPrestaShopEncolado,
  UniDataAtributosSkuEnlace, inLibGeneracionSkus,
  UniDataComprasSesionesTarifas,
  inLibComprasSesionesPreciosTalla,
  inLibMsgCompras;

type
  // Coste y PVP de los SKU de un artículo mientras se materializan sus
  // líneas; al final dan su patrón de tarifa (FZ-ISSUE-638).
  TPreciosArticuloSesion = record
    CodigoArticulo: string;
    // Coste neto y PVP de su primera línea con PVP.
    Referencia: TFilaPrecioTarifa;
    Precios: TPreciosSkuSesion;
  end;
  TPreciosArticulosSesion = TArray<TPreciosArticuloSesion>;
function GenerarEAN13Local(
                           AConexion: TUniConnection;
                           const ALecturas:
                           ILecturasArticulosMaterializacion;
                           const APrefijo: string): string;
var
  sPref   : string;
  iLenSeq : Integer;
  iNext   : Int64;
  iReserva: Int64;
  sBase   : string;
  cCheck  : Char;
begin
  sPref := APrefijo;
  // Default '21' = GS1 in-store / uso interno.
  // Si la empresa tiene su propio prefijo GS1, ponerlo en
  // PREFIJO_EAN_SES de la cabecera de la sesion.
  if sPref = '' then
    sPref := '21';
  iLenSeq := 12 - Length(sPref);
  if iLenSeq <= 0 then
    raise Exception.Create(Format(SErrorPrefijoEanSesionLargo, [sPref]));
  iNext := ALecturas.ObtenerSiguienteSecuenciaEan(
    sPref,
    iLenSeq);
  iReserva := SiguienteSecuenciaBarrasSesion(AConexion, sPref);
  if iReserva > iNext then
    iNext := iReserva;
  sBase  := sPref + Format('%.*d', [iLenSeq, iNext]);
  cCheck := inLibEAN13.CalcularDigitoEAN13(sBase);
  Result := sBase + cCheck;
end;
// ---------------------------------------------------------------------------
// Auxiliares internas
// ---------------------------------------------------------------------------
procedure InsertarArticulo(AConn: TUniConnection;
                           ADM: TdmComprasSesiones;
                           const AUsuario, ASerieSes, ANumSes: string;
                           ALinea: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos ' +
      '  (CODIGO_ART_ART, ESACTIVO_ART, TIPO_ART, DESCRIPCION_ART, ' +
      '   CODIGO_FAM_ART, TIPO_IVA_ART, TIPO_CANTIDAD_ART, ESVARIACION_ART, ' +
      '   ESTRAZABLE_ART, TIPO_VARIACION_ART, TIPO_TRAZABILIDAD_ART, ' +
      '   ESCADUCIDAD_ART, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT COALESCE(L.CODIGO_ART_REUSAR_SESLIN, ' +
      'L.CODIGO_ART_TENTATIVO_SESLIN), ' +
      '       ''S'', L.TIPO_ART_SESLIN, ' +
      // La opcion evita copiar origenes y conserva el texto de la linea.
      '       CASE WHEN S.ESDESCRIPCION_BLANCO_SES = ''S'' ' +
      '            THEN COALESCE(L.DESCRIPCION_SESLIN, '''') ' +
      '            WHEN IFNULL(S.ESCOPIAR_DESCRIPCION_FAM_SES, ''S'') = ' +
      '                      ''S'' ' +
      // FZ-ISSUE-438: la descripción de la línea manda; la de la familia
      // solo se copia cuando la línea viene sin descripción.
      '            THEN COALESCE(NULLIF(TRIM(L.DESCRIPCION_SESLIN), ''''), ' +
      '                          NULLIF(F.DESCRIPCION_FAM, ''''), ' +
      '                          L.DESCRIPCION_SESLIN) ' +
      '            ELSE L.DESCRIPCION_SESLIN END, ' +
      '       COALESCE(NULLIF(L.CODIGO_FAM_SESLIN, ''''), S.CODIGO_FAM_SES), ' +
      '       CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
      '            THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
      '                          NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '            ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
      '       END, ' +
      '       L.TIPO_CANTIDAD_SESLIN, ' +
      '       CASE WHEN L.TIPO_LINEA_SESLIN = ''MATRIZ'' THEN ''S'' ELSE ' +
      '''N'' END, ' +
      // La familia efectiva de cada línea decide también en las matrices.
      '       CASE WHEN F.TIPO_TRAZABILIDAD_FAM IN ' +
      '            (''LOTE'', ''LOTE_CADUCIDAD'', ''SERIE'') ' +
      '            OR L.ESTRAZABLE_SESLIN = ''S'' ' +
      '            THEN ''S'' ELSE ''N'' END, ' +
      '       CASE WHEN L.TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
      '            THEN COALESCE(L.CODIGO_VAR_SESLIN, S.CODIGO_VAR_SES) ' +
      '            ELSE NULL END, ' +
      '       CASE F.TIPO_TRAZABILIDAD_FAM ' +
      '            WHEN ''LOTE'' THEN ''LOTE'' ' +
      '            WHEN ''LOTE_CADUCIDAD'' THEN ''LOTE'' ' +
      '            WHEN ''SERIE'' THEN ''SERIE'' ' +
      '            ELSE CASE WHEN L.ESTRAZABLE_SESLIN = ''S'' ' +
      '                      THEN ''LOTE'' ELSE ''NINGUNA'' END END, ' +
      '       CASE WHEN F.TIPO_TRAZABILIDAD_FAM = ''LOTE_CADUCIDAD'' ' +
      '            THEN ''S'' ELSE ''N'' END, ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_articulos_familias F ' +
      '         ON F.CODIGO_FAM_FAM = ' +
      '            COALESCE(NULLIF(L.CODIGO_FAM_SESLIN, ''''), ' +
      '                     S.CODIGO_FAM_SES) ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN IS NULL)';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure InsertarConjuntosAtributos(AConn: TUniConnection;
                                     const ASerieSes, ANumSes,
                                           ACodigoArt, AUsuario: string;
                                     ALinea: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // Pivot. COALESCE en cascada para ID_VA_ACA:
    //   1) L.ID_VA_PIVOT_SESLIN (si el usuario lo seteo en la linea)
    //   2) S.ID_VA_PIVOT_SES    (si lo seteo en la cabecera)
    //   3) AC_P.ID_VA_AC        (del propio conjunto elegido por ID_AC)
    // Sin el fallback (3) las sesiones del flujo muestrario (combo
    // 'Sistema tallas' que solo guarda ID_AC_PIVOT_SESLIN) acababan con
    // ID_VA_ACA NULL -> INSERT IGNORE silenciaba el error NOT NULL y el
    // articulo se quedaba sin conjuntos asignados (Color/Talla "Sin
    // conjunto" en la ficha) y por tanto sin SKUs.
    // Un articulo reusado sin tallaje no hereda el de la cabecera: sus
    // tallas son las de sus SKU (FZ-ISSUE-140).
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ESGENERACION_AUTO_ACA, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :art, ' +
      '       COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES), ' +
      '       COALESCE(L.ID_VA_PIVOT_SESLIN, S.ID_VA_PIVOT_SES, ' +
      '                AC_P.ID_VA_AC), ' +
      '       ''S'', NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_atributos_conjuntos AC_P ' +
      '         ON AC_P.ID_AC = ' +
      '            COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES) ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l ' +
      '   AND COALESCE(L.ID_AC_PIVOT_SESLIN, S.ID_AC_PIVOT_SES) IS NOT NULL ' +
      '   AND (L.ID_AC_PIVOT_SESLIN IS NOT NULL ' +
      '        OR IFNULL(L.ACCION_DUPLICADO_SESLIN, '''') <> ''REUSAR'')';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
    // Fila — mismo fallback en cascada.
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ESGENERACION_AUTO_ACA, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :art, ' +
      '       COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES), ' +
      '       COALESCE(L.ID_VA_FILA_SESLIN, S.ID_VA_FILA_SES, ' +
      '                AC_F.ID_VA_AC), ' +
      '       ''S'', NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
      '                              AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
      '  LEFT JOIN fza_atributos_conjuntos AC_F ' +
      '         ON AC_F.ID_AC = ' +
      '            COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES) ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN = :l ' +
      '   AND COALESCE(L.ID_AC_FILA_SESLIN, S.ID_AC_FILA_SES) IS NOT NULL';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure InsertarPropiedadesFijas(AConn: TUniConnection;
                                   const ASerieSes, ANumSes, ACodigoArt,
                                         AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_propiedades ' +
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
      '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT :art, P.CODIGO_PROP_SESPROP, P.ID_PV_DEFECTO_SESPROP, ' +
      '       P.VALOR_DEFECTO_SESPROP, NOW(), :u ' +
      '  FROM fza_compras_sesiones_props P ' +
      ' WHERE P.SERIE_SES_SESPROP = :s AND P.NUMERO_SES_SESPROP = :n ' +
      '   AND P.ESFIJO_SESPROP = ''S''';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumSes;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ParamByName('u').AsString  := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Devuelve el prefijo de COLOR (los dos primeros segmentos, ART/COLOR) de
// un CODIGO_UNIDAD_SKU, EXACTAMENTE como lo calcula la vista
// vi_articulos_propiedades_efectivas (SUBSTRING_INDEX(sku,'/',2)). Sirve
// para fijar la temporada a nivel color en la propagacion de la sesion.
// Devuelve '' si el SKU no llega a dos '/' (no tiene nivel color: el SKU
// es ART/TALLA y la temporada se queda a nivel articulo).
function PrefijoColorSku(const ASku: string): string;
var
  i, nBarras, posSegunda: Integer;
begin
  nBarras    := 0;
  posSegunda := 0;
  for i := 1 to Length(ASku) do
  begin
    if (ASku[i] = '/') and (posSegunda = 0) then
    begin
      Inc(nBarras);
      if nBarras = 2 then
        posSegunda := i;
    end;
  end;
  if posSegunda > 0 then
    Result := Copy(ASku, 1, posSegunda - 1)
  else
    Result := '';
end;

function CargarColorLineaSku(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, ASerieSesion, ANumeroSesion,
    AUsuario: string;
  ALinea: Integer;
  out AValorColor: string;
  out AIdColorBasico: Integer): Integer;
var
  oColor: TColorLineaMaterializacion;
begin
  oColor := ALecturas.ObtenerColorLinea(
    ASerieSesion,
    ANumeroSesion,
    ALinea);
  Result := ResolverIdAvColorLinea(
    AConn,
    ALecturas,
    ACodigoArticulo,
    oColor.Texto,
    oColor.CodigoBasico,
    AUsuario,
    AValorColor,
    AIdColorBasico);
end;

procedure AsociarColorBasicoArticulo(
  AQuery: TUniQuery;
  const ACodigoArticulo, AUsuario: string;
  AIdColor, AIdColorBasico: Integer);
begin
  if (AIdColor > 0) and (AIdColorBasico > 0) then
  begin
    AQuery.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_atributos_basicos ' +
      '  (CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:art, :av, :atb, NOW(), :u, NOW(), :u)';
    AQuery.ParamByName('art').AsString := ACodigoArticulo;
    AQuery.ParamByName('av').AsInteger := AIdColor;
    AQuery.ParamByName('atb').AsInteger := AIdColorBasico;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

// El SKU nace con el tipo de variación de su línea o de la sesión, no con
// 'TC' fijo: una sesión de «Aroma y medida» crea SKU AM (FZ-ISSUE-420).
procedure InsertarSkuMaterializado(
  AQuery: TUniQuery;
  const ACodigoSku, ACodigoArticulo, ACodigoVariacion, AUsuario: string);
begin
  AQuery.SQL.Text :=
    'INSERT IGNORE INTO fza_articulos_skus ' +
    '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
    '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:sku, :art, :var, ''S'', NOW(), :u, NOW(), :u)';
  AQuery.ParamByName('sku').AsString := ACodigoSku;
  AQuery.ParamByName('art').AsString := ACodigoArticulo;
  AQuery.ParamByName('var').AsString := ACodigoVariacion;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;

procedure InsertarAtributoSkuMaterializado(
  AQuery: TUniQuery;
  const ACodigoSku, AUsuario: string;
  AIdValor: Integer);
begin
  // Al reutilizar un articulo existente el color de la linea puede resolverse
  // a otro ID_AV con el mismo texto que el del SKU: no se le anade.
  EnlazarValorAtributoSku(
    AQuery,
    ACodigoSku,
    AIdValor,
    AUsuario);
end;

procedure InsertarTemporadaColorSku(
  AQuery: TUniQuery;
  const ACodigoArticulo, ACodigoSku, AUsuario: string;
  AIdPropiedadTemporada: Integer);
var
  sPrefijoColor: string;
begin
  sPrefijoColor := PrefijoColorSku(ACodigoSku);
  if (AIdPropiedadTemporada > 0) and
     (sPrefijoColor <> '') then
  begin
    AQuery.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_propiedades ' +
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ' +
      '   CODIGO_UNIDAD_ARTPROP, ID_PV_ARTPROP, ' +
      '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:art, ''TEMPORADA'', :uni, :pv, NULL, NOW(), :u)';
    AQuery.ParamByName('art').AsString := ACodigoArticulo;
    AQuery.ParamByName('uni').AsString := sPrefijoColor;
    AQuery.ParamByName('pv').AsInteger :=
      AIdPropiedadTemporada;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

procedure AsegurarEan13Sku(
  const ALecturas: ILecturasArticulosMaterializacion;
  AQuery: TUniQuery;
  const ACodigoSku, APrefijoEan, AUsuario: string);
var
  sEan13: string;
begin
  if not SkuTieneCodigoBarras(AQuery.Connection, ACodigoSku) then
  begin
    sEan13 := GenerarEAN13Local(AQuery.Connection, ALecturas, APrefijoEan);
    AQuery.SQL.Text :=
      'INSERT INTO fza_codigos_barras ' +
      '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
      '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:cb, :sku, ''EAN13'', ''S'', ' +
      '        NOW(), :u, NOW(), :u)';
    AQuery.ParamByName('cb').AsString := sEan13;
    AQuery.ParamByName('sku').AsString := ACodigoSku;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

// Devuelve el SKU con su coste y su PVP para el patrón de tarifa.
// La copa (pestañas) va entre la fila y la talla: ART/COLOR/COPA/TALLA,
// para que el último tramo siga siendo siempre el de las columnas.
function ProcesarSkuSesion(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ASku: TSkuSesionMaterializacion;
  AOperacion: TUniQuery;
  const ACodigoArticulo, ACodigoVariacion, AUsuario, APrefijoEan,
        AValorColor, AValorPestana, ACodigoBarras: string;
  AIdColor, AIdPestana, AIdPropiedadTemporada: Integer): TPrecioSkuSesion;
var
  sCodigoSku: string;
  sValorPivot: string;
  sValorFila: string;
  sTramoPestana: string;
  iIdPivot: Integer;
  iIdFila: Integer;
begin
  sTramoPestana := '';
  if AIdPestana > 0 then
    sTramoPestana := NormalizarValorCodigoSku(AValorPestana) + '/';
  sValorPivot := NormalizarValorCodigoSku(ASku.ValorPivot);
  sValorFila := NormalizarValorCodigoSku(ASku.ValorFila);
  iIdPivot := ASku.IdAvPivot;
  iIdFila := ASku.IdAvFila;
  if (iIdFila = 0) and (AIdColor > 0) then
  begin
    iIdFila := AIdColor;
    sValorFila := AValorColor;
  end;
  if sValorFila = '' then
    sCodigoSku := ACodigoArticulo + '/' + sTramoPestana + sValorPivot
  else
    sCodigoSku := ACodigoArticulo + '/' + sValorFila + '/' +
      sTramoPestana + sValorPivot;
  InsertarSkuMaterializado(
    AOperacion, sCodigoSku, ACodigoArticulo, ACodigoVariacion, AUsuario);
  InsertarAtributoSkuMaterializado(
    AOperacion, sCodigoSku, AUsuario, iIdFila);
  InsertarAtributoSkuMaterializado(
    AOperacion, sCodigoSku, AUsuario, iIdPivot);
  InsertarAtributoSkuMaterializado(
    AOperacion, sCodigoSku, AUsuario, AIdPestana);
  InsertarTemporadaColorSku(
    AOperacion, ACodigoArticulo, sCodigoSku, AUsuario,
    AIdPropiedadTemporada);
  if ACodigoBarras <> '' then
    AsociarBarrasSkuSesion(AOperacion.Connection, ACodigoBarras,
      sCodigoSku, AUsuario)
  else
    AsegurarEan13Sku(
      ALecturas, AOperacion, sCodigoSku, APrefijoEan, AUsuario);
  Result.CodigoSku := sCodigoSku;
  Result.ClaveColor := '';
  if sValorFila <> '' then
    Result.ClaveColor := ACodigoArticulo + '/' + sValorFila;
  Result.Talla := Trim(ASku.ValorPivot);
  Result.Coste := ASku.Coste;
  Result.Pvp := ASku.Pvp;
end;

procedure AsegurarSkuBaseSesion(AConexion: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoArticulo, APrefijoEan, AUsuario, ACodigoBarras: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    InsertarSkuMaterializado(oConsulta, ACodigoArticulo,
      ACodigoArticulo, '-', AUsuario);
    if ACodigoBarras <> '' then
      AsociarBarrasSkuSesion(AConexion, ACodigoBarras,
        ACodigoArticulo, AUsuario)
    else
      AsegurarEan13Sku(ALecturas, oConsulta, ACodigoArticulo,
        APrefijoEan, AUsuario);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure InsertarSkusYBarras(AConn: TUniConnection;
                              const ALecturas:
                              ILecturasArticulosMaterializacion;
                              const ASerieSes, ANumSes, ACodigoArt,
                                    ACodigoVariacion,
                                    AUsuario, APrefijoEAN: string;
                              ALinea: Integer;
                              AIdPvTemporada: Integer;
                              var APrecios: TPreciosSkuSesion);
var
  oSkus: TSkusSesionMaterializacion;
  oPrecio: TPrecioSkuSesion;
  qOperacion: TUniQuery;
  sValorColor: string;
  sValorPestana: string;
  iIdColor: Integer;
  iIdColorBasico: Integer;
  iIdPestana: Integer;
  iSku: Integer;
begin
  iIdColor := CargarColorLineaSku(
    AConn, ALecturas, ACodigoArt, ASerieSes, ANumSes, AUsuario, ALinea,
    sValorColor, iIdColorBasico);
  iIdPestana := ResolverIdAvPestanaLinea(AConn, ACodigoArt,
    ALecturas.ObtenerColorLinea(ASerieSes, ANumSes, ALinea).PestanaTexto,
    AUsuario, sValorPestana);
  oSkus := ALecturas.ConsultarSkusSesion(
    ASerieSes,
    ANumSes,
    ALinea);
  qOperacion := TUniQuery.Create(nil);
  try
    qOperacion.Connection := AConn;
    AsociarColorBasicoArticulo(
      qOperacion, ACodigoArt, AUsuario, iIdColor,
      iIdColorBasico);
    for iSku := 0 to High(oSkus) do
    begin
      oPrecio := ProcesarSkuSesion(
        ALecturas, oSkus[iSku], qOperacion, ACodigoArt, ACodigoVariacion,
        AUsuario, APrefijoEAN, sValorColor, sValorPestana,
        LeerCodigoBarrasCelda(AConn, ASerieSes, ANumSes, ALinea,
          oSkus[iSku].IdFila, oSkus[iSku].IdAvPivot), iIdColor,
        iIdPestana, AIdPvTemporada);
      // Sin PVP el SKU no entra en el patrón: hereda la tarifa.
      if oPrecio.Pvp > 0 then
        APrecios := APrecios + [oPrecio];
    end;
  finally
    FreeAndNil(qOperacion);
  end;
end;

procedure UpsertArticuloProveedor(AConn: TUniConnection;
                                  const ALecturas:
                                  ILecturasArticulosMaterializacion;
                                  const ACodigoArt, ACodigoPrv,
                                        ARefPrv, AUsuario: string;
                                  APrecio: Double);
var
  q: TUniQuery;
  bHayPrincipal: Boolean;
  sEsPrincipal: string;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // 1. Si el articulo ya tiene OTRO proveedor marcado como principal,
    //    el nuevo no se lo roba: se inserta con ESPRINCIPAL='N'. Si la
    //    fila ya existe (mismo prv+art) el flag no se toca en el UPDATE.
    bHayPrincipal :=
      ALecturas.ExisteProveedorPrincipalDistinto(
        ACodigoArt,
        ACodigoPrv);
    if bHayPrincipal then
      sEsPrincipal := 'N'
    else
      sEsPrincipal := 'S';

    q.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_proveedores ' +
      '  (CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
      '   PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ESPROVEEDORPRINCIPAL_AP, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:prv, :art, :ref, :pre, NOW(), :prin, NOW(), :u, NOW(), :u) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_AP = :pre, FECHA_VALIDEZ_AP = NOW(), ' +
      '  REF_PROVEEDOR_AP = :ref, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
    q.ParamByName('prv').AsString  := ACodigoPrv;
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('ref').AsString  := ARefPrv;
    q.ParamByName('pre').AsFloat   := APrecio;
    q.ParamByName('prin').AsString := sEsPrincipal;
    q.ParamByName('u').AsString    := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// que reusos (ACCION=REUSAR) que ya tienen TEMPORADA distinta no se
// pisen.
procedure InsertarTemporadaCabecera(AConn: TUniConnection;
                                     const ACodigoArt, AUsuario: string;
                                     AIdPvTemporada: Integer);
var
  q: TUniQuery;
begin
  if AIdPvTemporada > 0 then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'INSERT IGNORE INTO fza_articulos_propiedades ' +
        '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
        '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'VALUES (:art, ''TEMPORADA'', :pv, NULL, NOW(), :u)';
      q.ParamByName('art').AsString := ACodigoArt;
      q.ParamByName('pv').AsInteger := AIdPvTemporada;
      q.ParamByName('u').AsString   := AUsuario;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  end;
end;

// El SKU de varias líneas cuenta una vez: la primera.
procedure AcumularPreciosArticulo(var AArticulos: TPreciosArticulosSesion;
  const ACodigoArticulo: string; ACoste, APvp: Double;
  const APrecios: TPreciosSkuSesion);
var
  iArticulo: Integer;
  iBusqueda: Integer;
  oPrecio: TPrecioSkuSesion;
  bRepetido: Boolean;
begin
  iArticulo := -1;
  for iBusqueda := 0 to High(AArticulos) do
    if SameText(AArticulos[iBusqueda].CodigoArticulo, ACodigoArticulo) then
      iArticulo := iBusqueda;
  if iArticulo = -1 then
  begin
    iArticulo := Length(AArticulos);
    SetLength(AArticulos, iArticulo + 1);
    AArticulos[iArticulo].CodigoArticulo := ACodigoArticulo;
    AArticulos[iArticulo].Referencia.Clave := '';
    AArticulos[iArticulo].Referencia.Coste := ACoste;
    AArticulos[iArticulo].Referencia.Pvp := APvp;
    AArticulos[iArticulo].Precios := nil;
  end
  else if AArticulos[iArticulo].Referencia.Pvp <= 0 then
  begin
    AArticulos[iArticulo].Referencia.Coste := ACoste;
    AArticulos[iArticulo].Referencia.Pvp := APvp;
  end;
  for oPrecio in APrecios do
  begin
    bRepetido := False;
    for iBusqueda := 0 to High(AArticulos[iArticulo].Precios) do
      bRepetido := bRepetido or SameText(
        AArticulos[iArticulo].Precios[iBusqueda].CodigoSku,
        oPrecio.CodigoSku);
    if not bRepetido then
      AArticulos[iArticulo].Precios :=
        AArticulos[iArticulo].Precios + [oPrecio];
  end;
end;

// El último coste del proveedor es el coste general del patrón: es el que
// propone el pedido a los SKU sin coste propio (FZ-ISSUE-634).
procedure ActualizarCosteProveedorPatron(AConn: TUniConnection;
  const ACodigoArt, ACodigoPrv, AUsuario: string; ACoste: Double);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_articulos_proveedores ' +
      '   SET PRECIO_ULT_COMPRA_AP = :pre, INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :u ' +
      ' WHERE CODIGO_PRV_AP = :prv AND CODIGO_ART_AP = :art';
    q.ParamByName('pre').AsFloat := ACoste;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('prv').AsString := ACodigoPrv;
    q.ParamByName('art').AsString := ACodigoArt;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Filas mínimas de la tarifa de cada artículo: la general y, si el coste
// o el PVP cambian por talla o color, las de talla, color o SKU que hagan
// falta (FZ-ISSUE-638). Sustituye a la fila general por línea y a la de
// cada SKU con varios PVP (FZ-ISSUE-415).
procedure GrabarTarifasArticulosSesion(AConn: TUniConnection;
  const AArticulos: TPreciosArticulosSesion;
  const ACodigoTar, ACodigoPrv, AUsuario: string;
  const AOpciones: TOpcionesTarifaSesion);
var
  oArticulo: TPreciosArticuloSesion;
  oOpciones: TOpcionesTarifaSesion;
  oVigentes: TFilasPrecioTarifa;
  oFilas: TFilasPrecioTarifa;
begin
  if Trim(ACodigoTar) <> '' then
    for oArticulo in AArticulos do
    begin
      oOpciones := AOpciones;
      oVigentes := LeerFilasVigentesTarifa(AConn, oArticulo.CodigoArticulo,
        ACodigoTar, FechaVigenciaTarifaSesion(oOpciones));
      // Un artículo sin precio vigente estrena su tarifa hoy.
      if Length(oVigentes) = 0 then
        oOpciones.Modo := mteModificar;
      oFilas := CalcularFilasPrecioTarifa(oArticulo.CodigoArticulo,
        oArticulo.Precios, oArticulo.Referencia, oVigentes);
      if oFilas[0].Pvp > 0 then
      begin
        GrabarFilasPrecioTarifa(AConn, oArticulo.CodigoArticulo, ACodigoTar,
          AUsuario, oFilas, oOpciones);
        EncolarPrecioPrestaShop(AConn, oArticulo.CodigoArticulo, AUsuario);
      end;
      if Length(oArticulo.Precios) > 0 then
        ActualizarCosteProveedorPatron(AConn, oArticulo.CodigoArticulo,
          ACodigoPrv, AUsuario, oFilas[0].Coste);
    end;
end;

// Resuelve el CODIGO_UNIDAD_SKU para un articulo + ID_AV pivot
// (talla), opcional ID_AV fila (color) y opcional ID_AV de pestañas
// (copa; hasta que la línea de la sesión la lleve vale 0), en el orden
// estandar
// fza_articulos_skus + fza_atributos_sku. Devuelve '' si no se
// encuentra (puede pasar para articulos REUSAR cuyo SKU no existe
// todavia con ese par de atributos: en ese caso el llamante puede
// crearlo o saltarse el movimiento).
function ResolverCodigoSku(
                            const ALecturas:
                            ILecturasArticulosMaterializacion;
                            const ACodigoArt: string;
                            AIdAvPivot, AIdAvFila: Integer;
                            AIdAvPestana: Integer): string;
begin
  Result := ALecturas.ResolverCodigoSku(
    ACodigoArt,
    AIdAvPivot,
    AIdAvFila,
    AIdAvPestana);
end;

// Crea la cabecera del albaran de compra en fza_albaranes_compra y sus
// lineas (una por SKU + almacen con cantidad > 0). Devuelve el
// NUMERO_ALBC generado. Denormaliza datos de empresa y proveedor desde
// fza_empresas y fza_proveedores (mismo patron que albaranes de venta).
// La cabecera CODIGO_ALM_ALBC arranca con el almacen de la sesion;
// cada linea lleva su propio CODIGO_ALMACEN_ALBCLIN (puede diferir si
// la celda venia con almacen explicito).

// Tipo de variación con el que nacen los SKU de la línea: el suyo (un
// artículo reusado trae el de su ficha) o el de la cabecera. Sin ninguno
// la sesión es anterior al selector de variación y hay que elegirlo.
function VariacionSkuLinea(
  const ALinea: TLineaArticuloMaterializacion;
  const AVariacionSesion, ASerieSesion, ANumeroSesion: string): string;
begin
  Result := Trim(ALinea.CodigoVariacion);
  if Result = '' then
    Result := Trim(AVariacionSesion);
  if (Result = '') and (ALinea.TipoLinea = 'MATRIZ') then
    raise Exception.CreateFmt(SErrorVariacionSesionMaterializar,
      [ASerieSesion, ANumeroSesion]);
end;

procedure CrearArticulosNuevosSesion(
  AConexion: TUniConnection; ADM: TdmComprasSesiones;
  const ALineas: TLineasArticuloMaterializacion;
  const AUsuario, ASerie, ANumero: string);
var
  Linea: TLineaArticuloMaterializacion;
begin
  for Linea in ALineas do
    if Linea.AccionDuplicado <> 'REUSAR' then
      InsertarArticulo(AConexion, ADM, AUsuario, ASerie, ANumero,
        Linea.Linea);
end;

procedure MaterializarArticulosSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AUsuario: string;
  const AOpcionesTarifa: TOpcionesTarifaSesion);
var
  oLineas: TLineasArticuloMaterializacion;
  oArticulos: TPreciosArticulosSesion;
  oPreciosLinea: TPreciosSkuSesion;
  sCodigoArt: string;
  sCodigoProveedor: string;
  sCodigoTarifa: string;
  sNumeroSesion: string;
  sPrefijoEan: string;
  sSerieSesion: string;
  sVariacionSesion: string;
  iIdPropiedadTemporada, iIdTemporadaLinea: Integer;
  iIndice: Integer;
  iLin: Integer;
  rPrecio: Double;
begin
  sSerieSesion :=
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumeroSesion :=
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sCodigoProveedor :=
    ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
  sPrefijoEan :=
    ADM.unqryTablaG.FieldByName('PREFIJO_EAN_SES').AsString;
  sCodigoTarifa :=
    ADM.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString;
  sVariacionSesion :=
    ADM.unqryTablaG.FieldByName('CODIGO_VAR_SES').AsString;
  iIdPropiedadTemporada := 0;
  if not ADM.unqryTablaG.FieldByName(
    'ID_PV_TEMPORADA_SES').IsNull then
    iIdPropiedadTemporada :=
      ADM.unqryTablaG.FieldByName(
        'ID_PV_TEMPORADA_SES').AsInteger;
  oLineas := ALecturas.ConsultarLineasArticulos(
    sSerieSesion,
    sNumeroSesion);
  CrearArticulosNuevosSesion(AConexion, ADM, oLineas, AUsuario,
    sSerieSesion, sNumeroSesion);
  oArticulos := nil;
  for iIndice := 0 to High(oLineas) do
  begin
    iLin := oLineas[iIndice].Linea;
    rPrecio := oLineas[iIndice].PrecioCosteProveedor;
    oPreciosLinea := nil;
    if oLineas[iIndice].AccionDuplicado = 'REUSAR' then
      sCodigoArt := oLineas[iIndice].CodigoArticuloReusar
    else
      sCodigoArt := oLineas[iIndice].CodigoArticuloTentativo;
    iIdTemporadaLinea := TemporadaPropiedadesLineaSesion(
      AConexion, sSerieSesion, sNumeroSesion, iLin,
      iIdPropiedadTemporada);
    if oLineas[iIndice].TipoLinea = 'MATRIZ' then
    begin
      InsertarConjuntosAtributos(
        AConexion,
        sSerieSesion,
        sNumeroSesion,
        sCodigoArt,
        AUsuario,
        iLin);
      InsertarSkusYBarras(
        AConexion,
        ALecturas,
        sSerieSesion,
        sNumeroSesion,
        sCodigoArt,
        VariacionSkuLinea(oLineas[iIndice], sVariacionSesion,
          sSerieSesion, sNumeroSesion),
        AUsuario,
        sPrefijoEan,
        iLin,
        iIdTemporadaLinea,
        oPreciosLinea);
    end
    else if oLineas[iIndice].TipoLinea = 'ESCALAR' then
    begin
      // Sin variación: SKU único, con el mismo código del artículo.
      // Usa la conexión de materialización para participar en su rollback.
      AsegurarSkuBaseSesion(AConexion, ALecturas, sCodigoArt,
        sPrefijoEan, AUsuario,
        LeerCodigoBarrasCelda(AConexion, sSerieSesion, sNumeroSesion,
          iLin, 0, 0));
    end;
    InsertarPropiedadesFijas(
      AConexion,
      sSerieSesion,
      sNumeroSesion,
      sCodigoArt,
      AUsuario);
    InsertarTemporadaCabecera(
      AConexion,
      sCodigoArt,
      AUsuario,
      iIdTemporadaLinea);
    MaterializarPropiedadesLineaSesion(AConexion, sSerieSesion,
      sNumeroSesion, iLin, sCodigoArt, AUsuario);
    if oLineas[iIndice].TipoLinea <> 'SERVICIO' then
    begin
      UpsertArticuloProveedor(
        AConexion,
        ALecturas,
        sCodigoArt,
        sCodigoProveedor,
        oLineas[iIndice].ReferenciaProveedor,
        AUsuario,
        rPrecio);
      AcumularPreciosArticulo(oArticulos, sCodigoArt, rPrecio,
        oLineas[iIndice].PrecioVenta, oPreciosLinea);
    end;
  end;
  GrabarTarifasArticulosSesion(AConexion, oArticulos, sCodigoTarifa,
    sCodigoProveedor, AUsuario, AOpcionesTarifa);
end;

procedure MigrarFotosArticulosSesion(
  ADM: TdmComprasSesiones;
  AFotos: TFotosArticulos;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AUsuario: string);
var
  oLineas: TLineasArticuloMaterializacion;
  sSerieSesion: string;
  sNumeroSesion: string;
  sCodigoArt: string;
  iIndice: Integer;
begin
  if Assigned(AFotos) then
  begin
    sSerieSesion := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    sNumeroSesion := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    oLineas := ALecturas.ConsultarLineasArticulos(
      sSerieSesion, sNumeroSesion);
    for iIndice := 0 to High(oLineas) do
    begin
      if oLineas[iIndice].AccionDuplicado = 'REUSAR' then
        sCodigoArt := oLineas[iIndice].CodigoArticuloReusar
      else
        sCodigoArt := oLineas[iIndice].CodigoArticuloTentativo;
      AFotos.Sesion.Migrar(sSerieSesion, sNumeroSesion,
        oLineas[iIndice].Linea, sCodigoArt, AUsuario);
    end;
  end;
end;

end.
