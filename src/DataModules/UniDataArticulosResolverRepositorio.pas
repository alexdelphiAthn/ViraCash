{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosResolverRepositorio                           }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resolución consolidada de datos de artículo y tarifa.                     }
{    Devuelve precios, IVA, último coste y PMP para un artículo o SKU.         }
{******************************************************************************}
unit UniDataArticulosResolverRepositorio;

{
  Unidad: inLibArticulosResolver
  Descripción:
    Capa común que, dado un (CODIGO_ART_ART, CODIGO_UNIDAD_SKU, CODIGO_TAR,
    fecha) ya canónicos, devuelve los datos consolidados del artículo:

      • Datos generales (descripción, familia, IVA, tipo, variación, …).
      • Tarifa solicitada y tarifa por defecto: PRECIO_SALIDA, PRECIO_FINAL,
        PRECIO_DTO, % DTO, % MARGEN, ajustes (múltiplo / menos), si es IVA
        incluido y si la fila está vigente en la fecha pedida.
      • Último precio de compra (proveedor principal o uno concreto).
      • Precio medio ponderado (PMP) por almacén o ponderado entre todos.

    El parseo de la entrada del usuario (artículo / SKU / código de barras /
    modelo de proveedor) se hace en `inLibArticulosValidadorIntf`. Las opciones
    de atributos y propiedades en `inLibArticulosAtributosIntf`. Esta unit
    sólo trabaja con códigos ya canónicos.

  Política sobre artículos con SKUs:
    • Si el artículo tiene >1 SKU activo y el llamante no pasa SKU,
      `ResolverDatos` devuelve Encontrado=False y Mensaje pidiendo SKU. El
      llamante debe seleccionarlo (apoyándose en `inLibArticulosAtributosIntf`
      para mostrar talla/color) y volver a llamar.
    • Si el artículo tiene 1 sólo SKU activo (servicios y artículos sin
      variación: SKU autocreado con el mismo código del artículo), se
      autoresuelve a ese SKU.
    • Si no tiene ningún SKU activo, se trabaja a nivel de padre.

  Limitación conocida sobre fecha:
    `vi_articulos_tarifas` filtra internamente con CURDATE(), por lo que
    sólo expone las filas vigentes hoy. La librería evalúa el flag Vigente
    contra la fecha pedida, pero si necesitas un precio histórico o futuro
    cuya FECHA_HASTA ya está vencida hoy, la vista no devolverá registro.
    En ese caso conviene consultar directamente `fza_articulos_tarifas`.

  Origen:
    fza_articulos              fza_articulos_skus
    vi_articulos_tarifas       (alimenta el bloque de precio + tarifa)
    fza_tarifas                (tarifa por defecto del cliente / sistema)
    fza_articulos_proveedores  (último coste)
    fza_articulos_stockactual  (PMP por almacén / ponderado)
    fza_ivas_tipos             (% iva del artículo, si se pidiera)
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, Uni, inLibParametrosIntf,
  inLibArticulosResolverIntf, inLibCatalogoSqlIntf;

type
  TRepositorioArticulosResolver = class(
    TInterfacedObject,
    IArticulosResolver)
  private
    FConexion: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    procedure RellenarPrecioDesdeQry(
      q: TUniQuery;
      var P: TArticuloPrecio;
      const AFecha: TDateTime);
    function TarifaDefault: string;
    function ContarSkusActivos(
      const ACodigoArt: string;
      out AUnicoSku: string): Integer;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosCaja: IParametrosCaja;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function ResolverDatos(
      const ACodigoArt, ACodigoSku: string;
      const ACodigoTarifa: string = '';
      const AFecha: TDateTime = 0;
      const ACodigoAlmacen: string = '';
      const ACodigoProveedor: string = ''): TArticuloDatos;
    function ResolverPrecio(
      const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
      const AFecha: TDateTime): TArticuloPrecio;
    function ResolverUltimoCoste(
      const ACodigoArt: string;
      const ACodigoProveedor: string = '';
      const ACodigoSku: string = ''): TArticuloCoste;
    function ResolverPMP(
      const ACodigoSku: string;
      const ACodigoAlmacen: string = ''): TArticuloPMP;
    function ListarSkus(
      const ACodigoArt: string;
      AIncluirInactivos: Boolean = False):
      TArray<TArticuloSkuItem>;
    function DescuentoTarifaVigente(
      const ACodigoTarifa: string;
      const AFecha: TDateTime): Boolean;
    function DescuentoTarifaAplicable(
      const ACodigoTarifa, ACodigoArt, ACodigoSku: string;
      const AFecha: TDateTime): Boolean;
  end;

implementation

uses
  UniDataTarifasPrecioSql,
  inLibMsgArticulos,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

const
  SQL_DESCUENTO_TARIFA =
    'SELECT FECHA_DESDE_DTO_TAR, FECHA_HASTA_DTO_TAR ' +
    'FROM fza_tarifas ' +
    'WHERE CODIGO_TAR_ARTTAR = :tar LIMIT 1';
  SQL_CONDICION_DESCUENTO_TARIFA =
    'SELECT c.MODO_TARDCO, c.CODIGO_PROP_TARDCO, ' +
    'c.POLITICA_SIN_VALOR_TARDCO, ' +
    'p.TIPO_VALOR_PROP, p.ESACTIVO_PROP, ' +
    'pe.ID_PV_ARTPROP AS ID_PV_EFECTIVO, ' +
    'CASE WHEN v.ID_PV_TARDVA IS NULL THEN ''N'' ELSE ''S'' END ' +
    'AS VALOR_SELECCIONADO, ' +
    '(SELECT COUNT(*) FROM fza_tarifas_descuento_valores vc ' +
    'WHERE vc.CODIGO_TAR_TARDVA = c.CODIGO_TAR_TARDCO) ' +
    'AS NUM_VALORES_CONDICION, ' +
    '(SELECT COUNT(*) FROM fza_tarifas_descuento_valores vc ' +
    'JOIN fza_propiedades_valores pvc ' +
    'ON pvc.ID_PV_ARTPROP = vc.ID_PV_TARDVA ' +
    'AND pvc.ID_PROP_PV = c.CODIGO_PROP_TARDCO ' +
    'AND pvc.ESACTIVO_PV = ''S'' ' +
    'WHERE vc.CODIGO_TAR_TARDVA = c.CODIGO_TAR_TARDCO) ' +
    'AS NUM_VALORES_VALIDOS ' +
    'FROM fza_tarifas_descuento_condiciones c ' +
    'LEFT JOIN fza_propiedades p ' +
    'ON p.CODIGO_PROP_ARTPROP = c.CODIGO_PROP_TARDCO ' +
    'LEFT JOIN vi_articulos_propiedades_efectivas e ' +
    'ON e.CODIGO_ART = :art ' +
    'AND e.CODIGO_UNIDAD_SKU = :sku ' +
    'AND e.CODIGO_PROP_ARTPROP = c.CODIGO_PROP_TARDCO ' +
    'LEFT JOIN fza_articulos_propiedades pa ' +
    'ON :sku = '''' ' +
    'AND pa.CODIGO_ART_ART = :art ' +
    'AND pa.CODIGO_UNIDAD_ARTPROP = '''' ' +
    'AND pa.CODIGO_PROP_ARTPROP = c.CODIGO_PROP_TARDCO ' +
    'LEFT JOIN fza_propiedades_valores pe ' +
    'ON pe.ID_PV_ARTPROP = ' +
    'COALESCE(e.ID_PV_ARTPROP, pa.ID_PV_ARTPROP) ' +
    'AND pe.ID_PROP_PV = c.CODIGO_PROP_TARDCO ' +
    'AND pe.ESACTIVO_PV = ''S'' ' +
    'LEFT JOIN fza_tarifas_descuento_valores v ' +
    'ON v.CODIGO_TAR_TARDVA = c.CODIGO_TAR_TARDCO ' +
    'AND v.ID_PV_TARDVA = pe.ID_PV_ARTPROP ' +
    'WHERE c.CODIGO_TAR_TARDCO = :tar LIMIT 1';
  SQL_CONTAR_SKUS_ACTIVOS =
    'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
    'WHERE CODIGO_ART_SKU = :art AND ESACTIVO_SKU = ''S''';
  // La selección común contempla SKU, artículo/*/talla, color y padre.
  SQL_RESOLVER_PRECIO =
    'SELECT t.CODIGO_TAR_ARTTAR, tar.NOMBRE_TAR_TAR, ' +
    'CASE WHEN COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') <> '''' ' +
    'THEN ''ESPECIFICO_SKU'' ELSE ''HEREDADO_PADRE'' END ' +
    'AS ORIGEN_PRECIO, t.PRECIO_SALIDA_ARTTAR, ' +
    't.PRECIO_FINAL_ARTTAR, t.PRECIO_DTO_ARTTAR, ' +
    't.PORCENTAJE_DTO_ARTTAR, ' +
    'COALESCE(t.PORCENTAJE_MARGEN_ARTTAR, ' +
    'tar.PORCENTAJE_MARGEN_TAR) AS PORCENTAJE_MARGEN_EFECTIVO, ' +
    'COALESCE(t.VALOR_MULTIPLO_AJUSTE_ARTTAR, ' +
    'tar.VALOR_MULTIPLO_AJUSTE_TAR) ' +
    'AS VALOR_MULTIPLO_AJUSTE_EFECTIVO, ' +
    'COALESCE(t.VALOR_MENOS_AJUSTE_ARTTAR, ' +
    'tar.VALOR_MENOS_AJUSTE_TAR) ' +
    'AS VALOR_MENOS_AJUSTE_EFECTIVO, tar.ESIMP_INCL_TAR, ' +
    't.FECHA_DESDE_ARTTAR, t.FECHA_HASTA_ARTTAR ' +
    'FROM fza_articulos_tarifas t ' +
    'JOIN fza_tarifas tar ' +
    'ON tar.CODIGO_TAR_ARTTAR = t.CODIGO_TAR_ARTTAR ' +
    'WHERE t.CODIGO_UNICO_ARTTAR = ({PRECIO_TARIFA})';
  SQL_COSTE_SKU =
    'SELECT PRECIO_ULT_COMPRA_SKUC, FECHA_ULT_COMPRA_SKUC ' +
    'FROM fza_articulos_skus_costes ' +
    'WHERE CODIGO_UNIDAD_SKU_SKUC = :sku LIMIT 1';
  SQL_COSTE_PROVEEDOR =
    'SELECT ap.CODIGO_PRV_AP, p.RAZON_SOCIAL_PRV, ' +
    'ap.REF_PROVEEDOR_AP, ap.PRECIO_ULT_COMPRA_AP, ' +
    'ap.FECHA_VALIDEZ_AP, ap.ESPROVEEDORPRINCIPAL_AP ' +
    'FROM fza_articulos_proveedores ap ' +
    'LEFT JOIN fza_proveedores p ' +
    'ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    'WHERE ap.CODIGO_ART_AP = :art ' +
    'AND ap.CODIGO_PRV_AP = :prv LIMIT 1';
  SQL_COSTE_PRINCIPAL =
    'SELECT ap.CODIGO_PRV_AP, p.RAZON_SOCIAL_PRV, ' +
    'ap.REF_PROVEEDOR_AP, ap.PRECIO_ULT_COMPRA_AP, ' +
    'ap.FECHA_VALIDEZ_AP, ap.ESPROVEEDORPRINCIPAL_AP ' +
    'FROM fza_articulos_proveedores ap ' +
    'LEFT JOIN fza_proveedores p ' +
    'ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    'WHERE ap.CODIGO_ART_AP = :art ' +
    'ORDER BY CASE ap.ESPROVEEDORPRINCIPAL_AP ' +
    'WHEN ''S'' THEN 0 ELSE 1 END, ' +
    'ap.FECHA_VALIDEZ_AP DESC LIMIT 1';
  SQL_PMP_ALMACEN =
    'SELECT SUM(CANTIDAD_STK) AS QTY, ' +
    'SUM(VALOR_TOTAL_STK) AS VAL, ' +
    'COUNT(DISTINCT CODIGO_ALM_STK) AS NA ' +
    'FROM fza_articulos_stockactual ' +
    'WHERE CODIGO_UNIDAD_STK = :sku ' +
    'AND CODIGO_ALM_STK = :alm';
  SQL_PMP_TOTAL =
    'SELECT SUM(CANTIDAD_STK) AS QTY, ' +
    'SUM(VALOR_TOTAL_STK) AS VAL, ' +
    'COUNT(DISTINCT CODIGO_ALM_STK) AS NA ' +
    'FROM fza_articulos_stockactual ' +
    'WHERE CODIGO_UNIDAD_STK = :sku';
  SQL_DATOS_ARTICULO =
    'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.TIPO_ART, ' +
    'a.TIPO_CANTIDAD_ART, a.ESACTIVO_ART, a.ESVARIACION_ART, ' +
    'a.ESTRAZABLE_ART, a.CODIGO_FAM_ART, a.TIPO_IVA_ART, ' +
    'a.TIPO_VARIACION_ART, ' +
    // FZ-ISSUE-432: las líneas guardan el nombre de la familia; su
    // descripción (observaciones) solo si no tiene nombre.
    'COALESCE(NULLIF(TRIM(fam.NOMBRE_FAM_FAM), ''''), ' +
    'fam.DESCRIPCION_FAM) AS DESCRIPCION_FAM, ' +
    'sk.CODIGO_UNIDAD_SKU, sk.ESACTIVO_SKU, ' +
    '(SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV ' +
    'SEPARATOR '' / '') FROM fza_atributos_sku sa ' +
    'JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    'WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU) ' +
    'AS DESCRIPCION_SKU, ' +
    '(SELECT COUNT(DISTINCT va.ID_ATB_VA) ' +
    'FROM fza_articulos_skus s2 ' +
    'JOIN fza_variaciones_atributos va ' +
    'ON va.ID_VAR_VA = s2.CODIGO_VAR_SKU ' +
    'WHERE s2.CODIGO_ART_SKU = a.CODIGO_ART_ART) AS NUM_ATR_REQ, ' +
    'iv.CODIGO_ABREVIATURA_IVA_IVATIP ' +
    'FROM fza_articulos a ' +
    'LEFT JOIN fza_articulos_skus sk ' +
    'ON sk.CODIGO_UNIDAD_SKU = :sku ' +
    'AND sk.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
    'LEFT JOIN fza_articulos_familias fam ' +
    'ON fam.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
    'LEFT JOIN fza_ivas_tipos iv ' +
    'ON iv.CODIGO_ABREVIATURA_IVA_IVATIP = a.TIPO_IVA_ART ' +
    'WHERE a.CODIGO_ART_ART = :art LIMIT 1';
  SQL_LISTAR_SKUS =
    'SELECT sk.CODIGO_UNIDAD_SKU, sk.ESACTIVO_SKU, ' +
    '(SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV ' +
    'SEPARATOR '' / '') FROM fza_atributos_sku sa ' +
    'JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    'WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU) ' +
    'AS DESCRIPCION_SKU FROM fza_articulos_skus sk ' +
    'WHERE sk.CODIGO_ART_SKU = :art ' +
    'AND (:incluir = ''S'' OR sk.ESACTIVO_SKU = ''S'') ' +
    'ORDER BY sk.CODIGO_UNIDAD_SKU';

function DefinicionSql(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioArticulosResolver',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

constructor TRepositorioArticulosResolver.Create(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create;
  FConexion := AConexion;
  FParametrosCaja := AParametrosCaja;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioArticulosResolver.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 11);
  Result[0] := DefinicionSql(
    'DescuentoTarifaVigente',
    SQL_DESCUENTO_TARIFA,
    'tar',
    'FECHA_DESDE_DTO_TAR,FECHA_HASTA_DTO_TAR');
  Result[1] := DefinicionSql(
    'ContarSkusActivos',
    SQL_CONTAR_SKUS_ACTIVOS,
    'art',
    'CODIGO_UNIDAD_SKU');
  Result[2] := DefinicionSql(
    'ResolverPrecioConTalla',
    StringReplace(SQL_RESOLVER_PRECIO, '{PRECIO_TARIFA}',
      SqlSeleccionPrecioTarifa(':art', ':sku', ':tar', ':fec'),
      [rfReplaceAll]),
    'art,sku,tar,fec',
    'CODIGO_TAR_ARTTAR,NOMBRE_TAR_TAR,ORIGEN_PRECIO,' +
    'PRECIO_SALIDA_ARTTAR,PRECIO_FINAL_ARTTAR,' +
    'PRECIO_DTO_ARTTAR,PORCENTAJE_DTO_ARTTAR,' +
    'PORCENTAJE_MARGEN_EFECTIVO,' +
    'VALOR_MULTIPLO_AJUSTE_EFECTIVO,' +
    'VALOR_MENOS_AJUSTE_EFECTIVO,ESIMP_INCL_TAR,' +
    'FECHA_DESDE_ARTTAR,FECHA_HASTA_ARTTAR');
  Result[3] := DefinicionSql(
    'ObtenerCosteSku',
    SQL_COSTE_SKU,
    'sku',
    'PRECIO_ULT_COMPRA_SKUC,FECHA_ULT_COMPRA_SKUC');
  Result[4] := DefinicionSql(
    'ObtenerCosteProveedor',
    SQL_COSTE_PROVEEDOR,
    'art,prv',
    'CODIGO_PRV_AP,RAZON_SOCIAL_PRV,REF_PROVEEDOR_AP,' +
    'PRECIO_ULT_COMPRA_AP,FECHA_VALIDEZ_AP,' +
    'ESPROVEEDORPRINCIPAL_AP');
  Result[5] := DefinicionSql(
    'ObtenerCostePrincipal',
    SQL_COSTE_PRINCIPAL,
    'art',
    'CODIGO_PRV_AP,RAZON_SOCIAL_PRV,REF_PROVEEDOR_AP,' +
    'PRECIO_ULT_COMPRA_AP,FECHA_VALIDEZ_AP,' +
    'ESPROVEEDORPRINCIPAL_AP');
  Result[6] := DefinicionSql(
    'ResolverPmpAlmacen',
    SQL_PMP_ALMACEN,
    'sku,alm',
    'QTY,VAL,NA');
  Result[7] := DefinicionSql(
    'ResolverPmpTotal',
    SQL_PMP_TOTAL,
    'sku',
    'QTY,VAL,NA');
  Result[8] := DefinicionSql(
    'ObtenerDatosArticulo',
    SQL_DATOS_ARTICULO,
    'sku,art',
    'CODIGO_ART_ART,DESCRIPCION_ART,TIPO_ART,' +
    'TIPO_CANTIDAD_ART,ESACTIVO_ART,ESVARIACION_ART,' +
    'ESTRAZABLE_ART,CODIGO_FAM_ART,TIPO_IVA_ART,' +
    'TIPO_VARIACION_ART,DESCRIPCION_FAM,' +
    'CODIGO_UNIDAD_SKU,ESACTIVO_SKU,DESCRIPCION_SKU,' +
    'NUM_ATR_REQ');
  Result[9] := DefinicionSql(
    'ListarSkus',
    SQL_LISTAR_SKUS,
    'art,incluir',
    'CODIGO_UNIDAD_SKU,ESACTIVO_SKU,DESCRIPCION_SKU');
  Result[10] := DefinicionSql(
    'DescuentoTarifaAplicable',
    SQL_CONDICION_DESCUENTO_TARIFA,
    'art,sku,tar',
    'MODO_TARDCO,CODIGO_PROP_TARDCO,POLITICA_SIN_VALOR_TARDCO,' +
    'TIPO_VALOR_PROP,' +
    'ESACTIVO_PROP,ID_PV_EFECTIVO,VALOR_SELECCIONADO,' +
    'NUM_VALORES_CONDICION,NUM_VALORES_VALIDOS');
end;

function TRepositorioArticulosResolver.DescuentoTarifaVigente(
  const ACodigoTarifa: string;
  const AFecha: TDateTime): Boolean;
var
  dDesde: TDateTime;
  dHasta: TDateTime;
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  Result := True;
  if Assigned(FConexion) and
     (ACodigoTarifa <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oDefinicion := DefinicionesSql[0];
      try
        EjecutarLecturaSqlConFallback(
          oDefinicion,
          FCatalogoSql,
          procedure(const ASql: string)
          begin
            oConsulta.Close;
            oConsulta.SQL.Text := ASql;
            oConsulta.ParamByName('tar').AsString :=
              ACodigoTarifa;
            oConsulta.Open;
            ValidarCamposResultadoSql(
              oDefinicion,
              oConsulta);
          end,
          FIncidenciasSql);
        if not oConsulta.IsEmpty then
        begin
          dDesde := 0;
          dHasta := 0;
          if not oConsulta.FieldByName(
                   'FECHA_DESDE_DTO_TAR').IsNull then
            dDesde := oConsulta.FieldByName(
              'FECHA_DESDE_DTO_TAR').AsDateTime;
          if not oConsulta.FieldByName(
                   'FECHA_HASTA_DTO_TAR').IsNull then
            dHasta := oConsulta.FieldByName(
              'FECHA_HASTA_DTO_TAR').AsDateTime;
          Result := DescuentoEnVentana(
            AFecha,
            dDesde,
            dHasta);
        end;
      except
        on E: Exception do
        begin
          if Assigned(FIncidenciasSql) then
            FIncidenciasSql.Registrar(
              ClavePerfilSql(oDefinicion),
              E.Message);
          Result := False;
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioArticulosResolver.DescuentoTarifaAplicable(
  const ACodigoTarifa, ACodigoArt, ACodigoSku: string;
  const AFecha: TDateTime): Boolean;
var
  bTieneValor: Boolean;
  bValorSeleccionado: Boolean;
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
  sModo: string;
begin
  Result := Assigned(FConexion) and (ACodigoTarifa <> '');
  if Result then
    Result := DescuentoTarifaVigente(ACodigoTarifa, AFecha);
  if Result then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oDefinicion := DefinicionesSql[10];
      try
        EjecutarLecturaSqlConFallback(
          oDefinicion,
          FCatalogoSql,
          procedure(const ASql: string)
          begin
            oConsulta.Close;
            oConsulta.SQL.Text := ASql;
            oConsulta.ParamByName('tar').AsString :=
              ACodigoTarifa;
            oConsulta.ParamByName('art').AsString :=
              ACodigoArt;
            oConsulta.ParamByName('sku').AsString :=
              ACodigoSku;
            oConsulta.Open;
            ValidarCamposResultadoSql(
              oDefinicion,
              oConsulta);
          end,
          FIncidenciasSql);

        // Sin cabecera de condicion se conserva el comportamiento historico.
        // TODOS tampoco necesita propiedad ni valores asociados.
        if not oConsulta.IsEmpty then
        begin
          sModo := UpperCase(Trim(oConsulta.FieldByName(
            'MODO_TARDCO').AsString));
          if sModo = 'TODOS' then
            Result := True
          else
          begin
            // Una condicion mal configurada o sin valor efectivo nunca abre
            // el descuento. La propiedad debe seguir activa y ser de lista.
            Result :=
              ((sModo = 'SOLO_SI') or
               (sModo = 'TODOS_EXCEPTO')) and
              (Trim(oConsulta.FieldByName(
                'CODIGO_PROP_TARDCO').AsString) <> '') and
              SameText(oConsulta.FieldByName(
                'POLITICA_SIN_VALOR_TARDCO').AsString,
                'NO_APLICAR') and
              (oConsulta.FieldByName('ESACTIVO_PROP').AsString = 'S') and
              SameText(oConsulta.FieldByName(
                'TIPO_VALOR_PROP').AsString, 'LISTA') and
              (oConsulta.FieldByName(
                'NUM_VALORES_CONDICION').AsInteger > 0) and
              (oConsulta.FieldByName(
                'NUM_VALORES_VALIDOS').AsInteger =
               oConsulta.FieldByName(
                'NUM_VALORES_CONDICION').AsInteger);
            bTieneValor := not oConsulta.FieldByName(
              'ID_PV_EFECTIVO').IsNull;
            Result := Result and bTieneValor;
            if Result then
            begin
              bValorSeleccionado :=
                oConsulta.FieldByName(
                  'VALOR_SELECCIONADO').AsString = 'S';
              if sModo = 'SOLO_SI' then
                Result := bValorSeleccionado
              else if sModo = 'TODOS_EXCEPTO' then
                Result := not bValorSeleccionado
              else
                Result := False;
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          // Con una lectura incompleta no se puede demostrar que el articulo
          // cumple la regla; por seguridad comercial, no se descuenta.
          if Assigned(FIncidenciasSql) then
            FIncidenciasSql.Registrar(
              ClavePerfilSql(oDefinicion),
              E.Message);
          Result := False;
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioArticulosResolver.TarifaDefault: string;
begin
  Result := FParametrosCaja.TarifaDefecto;
end;

function TRepositorioArticulosResolver.ContarSkusActivos(
  const ACodigoArt: string;
  out AUnicoSku: string): Integer;
var
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  Result := 0;
  AUnicoSku := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oDefinicion := DefinicionesSql[1];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oConsulta.Close;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArt;
        oConsulta.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oConsulta);
      end,
      FIncidenciasSql);
    while not oConsulta.Eof do
    begin
      Inc(Result);
      if Result = 1 then
        AUnicoSku := oConsulta.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString;
      oConsulta.Next;
    end;
    if Result > 1 then
      AUnicoSku := '';
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioArticulosResolver.RellenarPrecioDesdeQry(
  q: TUniQuery;
  var P: TArticuloPrecio; const AFecha: TDateTime);
var
  sOrigen: string;
  dHasta : TDateTime;
begin
  P.TieneRegistro    := True;
  P.CodigoTarifa     := q.FieldByName('CODIGO_TAR_ARTTAR').AsString;
  P.NombreTarifa     := q.FieldByName('NOMBRE_TAR_TAR').AsString;
  P.PrecioSalida     := q.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
  P.PrecioFinal      := q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
  P.PrecioDto        := q.FieldByName('PRECIO_DTO_ARTTAR').AsFloat;
  P.PorcentajeDto    := q.FieldByName('PORCENTAJE_DTO_ARTTAR').AsFloat;
  P.PorcentajeMargen := q.FieldByName('PORCENTAJE_MARGEN_EFECTIVO').AsFloat;
  P.ValorMultiploAjuste :=
                       q.FieldByName('VALOR_MULTIPLO_AJUSTE_EFECTIVO').AsFloat;
  P.ValorMenosAjuste := q.FieldByName('VALOR_MENOS_AJUSTE_EFECTIVO').AsFloat;
  P.EsImpIncl        := q.FieldByName('ESIMP_INCL_TAR').AsString = 'S';
  P.EsTarifaDefault  := SameText(q.FieldByName('CODIGO_TAR_ARTTAR').AsString,
                                 TarifaDefault);
  if not q.FieldByName('FECHA_DESDE_ARTTAR').IsNull then
    P.FechaDesde     := q.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime;
  if not q.FieldByName('FECHA_HASTA_ARTTAR').IsNull then
    P.FechaHasta     := q.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime;

  sOrigen := q.FieldByName('ORIGEN_PRECIO').AsString;
  if      sOrigen = 'ESPECIFICO_SKU' then P.Origen := aopEspecificoSku
  else if sOrigen = 'HEREDADO_PADRE' then P.Origen := aopHeredadoPadre
  else                                    P.Origen := aopSinPrecio;

  if AFecha = 0 then dHasta := Now else dHasta := AFecha;
  P.Vigente :=
    ((P.FechaDesde = 0) or (P.FechaDesde <= dHasta)) and
    ((P.FechaHasta = 0) or (P.FechaHasta >= dHasta));
end;

function TRepositorioArticulosResolver.ResolverPrecio(
  const ACodigoArt, ACodigoSku,
  ACodigoTarifa: string; const AFecha: TDateTime): TArticuloPrecio;
var
  dFecha: TDateTime;
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  Result.Clear;
  if ACodigoArt <> '' then
  begin
  Result.CodigoTarifa := ACodigoTarifa;
  if AFecha = 0 then
    dFecha := Now
  else
    dFecha := AFecha;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oDefinicion := DefinicionesSql[2];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oConsulta.Close;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArt;
        oConsulta.ParamByName('sku').AsString :=
          ACodigoSku;
        oConsulta.ParamByName('tar').AsString :=
          ACodigoTarifa;
        oConsulta.ParamByName('fec').AsDateTime :=
          dFecha;
        oConsulta.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oConsulta);
      end,
      FIncidenciasSql);
    if not oConsulta.IsEmpty then
      RellenarPrecioDesdeQry(
        oConsulta,
        Result,
        AFecha);
  finally
    FreeAndNil(oConsulta);
  end;
  // La aplicacion del descuento combina la ventana de la tarifa con su
  // condicion por propiedad efectiva del articulo/SKU. Sin condicion se
  // conserva el comportamiento historico basado sólo en la fecha.
  if Result.TieneRegistro and
     ((Result.PorcentajeDto <> 0) or (Result.PrecioDto <> 0)) then
  begin
    if not DescuentoTarifaAplicable(
             Result.CodigoTarifa,
             ACodigoArt,
             ACodigoSku,
             dFecha) then
    begin
      Result.PrecioFinal        := Result.PrecioSalida;
      Result.PrecioDto          := 0;
      Result.PorcentajeDto      := 0;
      Result.DescuentoAplicable := False;
    end;
  end;
  end;
end;

function TRepositorioArticulosResolver.ResolverUltimoCoste(
  const ACodigoArt: string;
  const ACodigoProveedor: string;
  const ACodigoSku: string): TArticuloCoste;
var
  bCosteSkuEncontrado: Boolean;
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  Result.Clear;
  if ACodigoArt <> '' then
  begin
    bCosteSkuEncontrado := False;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      if ACodigoSku <> '' then
      begin
        oDefinicion := DefinicionesSql[3];
        EjecutarLecturaSqlConFallback(
          oDefinicion,
          FCatalogoSql,
          procedure(const ASql: string)
          begin
            oConsulta.Close;
            oConsulta.SQL.Text := ASql;
            oConsulta.ParamByName('sku').AsString :=
              ACodigoSku;
            oConsulta.Open;
            ValidarCamposResultadoSql(
              oDefinicion,
              oConsulta);
          end,
          FIncidenciasSql);
        if not oConsulta.IsEmpty then
        begin
          if not oConsulta.FieldByName(
                   'PRECIO_ULT_COMPRA_SKUC').IsNull then
            Result.PrecioUltCompra := oConsulta.FieldByName(
              'PRECIO_ULT_COMPRA_SKUC').AsFloat;
          if not oConsulta.FieldByName(
                   'FECHA_ULT_COMPRA_SKUC').IsNull then
            Result.FechaValidezCompra := oConsulta.FieldByName(
              'FECHA_ULT_COMPRA_SKUC').AsDateTime;
          Result.Encontrado := True;
          bCosteSkuEncontrado := True;
        end;
      end;
      if not bCosteSkuEncontrado then
      begin
        if ACodigoProveedor <> '' then
          oDefinicion := DefinicionesSql[4]
        else
          oDefinicion := DefinicionesSql[5];
        EjecutarLecturaSqlConFallback(
          oDefinicion,
          FCatalogoSql,
          procedure(const ASql: string)
          begin
            oConsulta.Close;
            oConsulta.SQL.Text := ASql;
            oConsulta.ParamByName('art').AsString :=
              ACodigoArt;
            if ACodigoProveedor <> '' then
              oConsulta.ParamByName('prv').AsString :=
                ACodigoProveedor;
            oConsulta.Open;
            ValidarCamposResultadoSql(
              oDefinicion,
              oConsulta);
          end,
          FIncidenciasSql);
        if not oConsulta.IsEmpty then
        begin
          Result.CodigoProveedor := oConsulta.FieldByName(
            'CODIGO_PRV_AP').AsString;
          Result.RazonSocialProveedor := oConsulta.FieldByName(
            'RAZON_SOCIAL_PRV').AsString;
          Result.RefProveedor := oConsulta.FieldByName(
            'REF_PROVEEDOR_AP').AsString;
          if not oConsulta.FieldByName(
                   'PRECIO_ULT_COMPRA_AP').IsNull then
            Result.PrecioUltCompra := oConsulta.FieldByName(
              'PRECIO_ULT_COMPRA_AP').AsFloat;
          if not oConsulta.FieldByName(
                   'FECHA_VALIDEZ_AP').IsNull then
            Result.FechaValidezCompra := oConsulta.FieldByName(
              'FECHA_VALIDEZ_AP').AsDateTime;
          Result.EsProveedorPrincipal :=
            oConsulta.FieldByName(
              'ESPROVEEDORPRINCIPAL_AP').AsString = 'S';
          Result.Encontrado := True;
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioArticulosResolver.ResolverPMP(
  const ACodigoSku: string;
  const ACodigoAlmacen: string): TArticuloPMP;
var
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  Result.Clear;
  if ACodigoSku <> '' then
  begin
    Result.AlmacenConsultado := ACodigoAlmacen;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      if ACodigoAlmacen <> '' then
        oDefinicion := DefinicionesSql[6]
      else
        oDefinicion := DefinicionesSql[7];
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        FCatalogoSql,
        procedure(const ASql: string)
        begin
          oConsulta.Close;
          oConsulta.SQL.Text := ASql;
          oConsulta.ParamByName('sku').AsString :=
            ACodigoSku;
          if ACodigoAlmacen <> '' then
            oConsulta.ParamByName('alm').AsString :=
              ACodigoAlmacen;
          oConsulta.Open;
          ValidarCamposResultadoSql(
            oDefinicion,
            oConsulta);
        end,
        FIncidenciasSql);
      if not oConsulta.IsEmpty then
      begin
        if not oConsulta.FieldByName('QTY').IsNull then
          Result.CantidadTotal :=
            oConsulta.FieldByName('QTY').AsFloat;
        if not oConsulta.FieldByName('VAL').IsNull then
          Result.ValorTotal :=
            oConsulta.FieldByName('VAL').AsFloat;
        Result.NumAlmacenes :=
          oConsulta.FieldByName('NA').AsInteger;
        if Result.CantidadTotal > 0 then
          Result.PrecioMedio :=
            Result.ValorTotal / Result.CantidadTotal;
        Result.Encontrado :=
          Result.NumAlmacenes > 0;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioArticulosResolver.ResolverDatos(
  const ACodigoArt, ACodigoSku: string;
  const ACodigoTarifa: string; const AFecha: TDateTime;
  const ACodigoAlmacen: string;
  const ACodigoProveedor: string): TArticuloDatos;
var
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
  iNumSkus: Integer;
  sSku: string;
  sTarDef: string;
  sTarifa: string;
  sUnico: string;
begin
  Result.Clear;
  if ACodigoArt = '' then
    Result.Mensaje := SErrorCodigoArticuloResolverObligatorio;
  if ACodigoArt <> '' then
  begin
  iNumSkus := ContarSkusActivos(ACodigoArt, sUnico);
  sSku     := ACodigoSku;

  // Si el artículo tiene SKUs y el llamante no pasó uno: si hay un único
  // SKU activo (servicios / artículos sin variación), lo resolvemos solos;
  // si hay >1, marcamos RequiereSku — los datos básicos (descripción,
  // familia, IVA…) se llenan igual para que la UI pueda mostrarlos
  // mientras pide la talla/color, pero precio/PMP/coste se dejan a 0.
  if (sSku = '') and (iNumSkus = 1) then
    sSku := sUnico
  else if (sSku = '') and (iNumSkus > 1) then
    Result.RequiereSku := True;

  // Datos básicos del artículo + SKU si lo hay
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oDefinicion := DefinicionesSql[8];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oConsulta.Close;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArt;
        oConsulta.ParamByName('sku').AsString :=
          sSku;
        oConsulta.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oConsulta);
      end,
      FIncidenciasSql);
    if oConsulta.IsEmpty then
      Result.Mensaje := Format(SErrorArticuloResolverNoExiste, [ACodigoArt]);
    if not oConsulta.IsEmpty then
    begin
    Result.CodigoArticulo := oConsulta.FieldByName(
      'CODIGO_ART_ART').AsString;
    Result.CodigoSku := oConsulta.FieldByName(
      'CODIGO_UNIDAD_SKU').AsString;
    Result.DescripcionArticulo := oConsulta.FieldByName(
      'DESCRIPCION_ART').AsString;
    Result.DescripcionSku := oConsulta.FieldByName(
      'DESCRIPCION_SKU').AsString;
    Result.TipoArticulo := oConsulta.FieldByName(
      'TIPO_ART').AsString;
    Result.TipoCantidad := oConsulta.FieldByName(
      'TIPO_CANTIDAD_ART').AsString;
    Result.EsActivoArticulo := oConsulta.FieldByName(
      'ESACTIVO_ART').AsString = 'S';
    Result.EsActivoSku := oConsulta.FieldByName(
      'ESACTIVO_SKU').AsString = 'S';
    Result.EsVariacion := oConsulta.FieldByName(
      'ESVARIACION_ART').AsString = 'S';
    Result.EsTrazable := oConsulta.FieldByName(
      'ESTRAZABLE_ART').AsString = 'S';
    Result.NumAtributosReq := oConsulta.FieldByName(
      'NUM_ATR_REQ').AsInteger;
    Result.CodigoFamilia := oConsulta.FieldByName(
      'CODIGO_FAM_ART').AsString;
    Result.DescripcionFamilia := oConsulta.FieldByName(
      'DESCRIPCION_FAM').AsString;
    Result.TipoIVA := oConsulta.FieldByName(
      'TIPO_IVA_ART').AsString;
    Result.TipoVariacion := oConsulta.FieldByName(
      'TIPO_VARIACION_ART').AsString;
    Result.TieneSku            := iNumSkus > 0;
    end;
  finally
    FreeAndNil(oConsulta);
  end;

  Result.Encontrado := Result.CodigoArticulo <> '';
  if Result.Encontrado then
  begin
    // Si hay varios SKU, el llamante pedirá talla/color y volverá
    if Result.RequiereSku then
      Result.Mensaje := Format(SAvisoArticuloResolverRequiereSku,
                               [ACodigoArt])
    else
    begin
      // Tarifa solicitada
      sTarifa := ACodigoTarifa;
      if sTarifa = '' then
        sTarifa := TarifaDefault;
      if sTarifa <> '' then
        Result.PrecioPedido := ResolverPrecio(
          ACodigoArt, sSku, sTarifa, AFecha);
      // Tarifa por defecto del sistema (si difiere)
      sTarDef := TarifaDefault;
      if (sTarDef <> '') and (sTarDef <> sTarifa) then
        Result.PrecioTarifaDefault :=
          ResolverPrecio(ACodigoArt, sSku, sTarDef, AFecha)
      else
        Result.PrecioTarifaDefault := Result.PrecioPedido;
      // Coste y PMP
      Result.UltimoCoste := ResolverUltimoCoste(
        ACodigoArt, ACodigoProveedor, Result.CodigoSku);
      if Result.CodigoSku <> '' then
        Result.PMP := ResolverPMP(Result.CodigoSku, ACodigoAlmacen);
    end;
  end;
  end;
end;

function TRepositorioArticulosResolver.ListarSkus(
  const ACodigoArt: string;
  AIncluirInactivos: Boolean): TArray<TArticuloSkuItem>;
var
  Item: TArticuloSkuItem;
  Lst: TList<TArticuloSkuItem>;
  oConsulta: TUniQuery;
  oDefinicion: TDefinicionSql;
  sIncluir: string;
begin
  Result := nil;
  if ACodigoArt <> '' then
  begin
    if AIncluirInactivos then
      sIncluir := 'S'
    else
      sIncluir := 'N';
    Lst := TList<TArticuloSkuItem>.Create;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oDefinicion := DefinicionesSql[9];
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        FCatalogoSql,
        procedure(const ASql: string)
        begin
          oConsulta.Close;
          oConsulta.SQL.Text := ASql;
          oConsulta.ParamByName('art').AsString :=
            ACodigoArt;
          oConsulta.ParamByName('incluir').AsString :=
            sIncluir;
          oConsulta.Open;
          ValidarCamposResultadoSql(
            oDefinicion,
            oConsulta);
        end,
        FIncidenciasSql);
      while not oConsulta.Eof do
      begin
        Item := Default(TArticuloSkuItem);
        Item.CodigoSku := oConsulta.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString;
        Item.DescripcionSku := oConsulta.FieldByName(
          'DESCRIPCION_SKU').AsString;
        Item.EsActivo := oConsulta.FieldByName(
          'ESACTIVO_SKU').AsString = 'S';
        Lst.Add(Item);
        oConsulta.Next;
      end;
      Result := Lst.ToArray;
    finally
      FreeAndNil(oConsulta);
      FreeAndNil(Lst);
    end;
  end;
end;

end.

