{******************************************************************************}
{                                                                              }
{                       Módulo: UniDataInformeDocumento                        }
{                                Versión: 1.2.0                                }
{                              Fecha: 01/10/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataInformeDocumento;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Uni, frxDBSet, inLibDocumentoIntf;

type
  TDatosInformeDocumento = class(TComponent)
  private
    FCabecera: TUniQuery;
    FLineas: TUniQuery;
    FImpuestos: TUniQuery;
    FDatosCabecera: TfrxDBDataset;
    FDatosLineas: TfrxDBDataset;
    FDatosImpuestos: TfrxDBDataset;
    procedure ConfigurarCabecera(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarLineas(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarImpuestos(const AConfig: TConfiguracionDocumento);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Abrir(AConexion: TUniConnection;
      const AConfig: TConfiguracionDocumento;
      const ASerie, ANumero: string);
    property Cabecera: TfrxDBDataset read FDatosCabecera;
    property Lineas: TfrxDBDataset read FDatosLineas;
    // Desglose por tipo de IVA: solo los tipos con base o cuota.
    property Impuestos: TfrxDBDataset read FDatosImpuestos;
  end;

implementation

uses
  System.SysUtils, Data.DB;

const
  SALTO_SQL = 'CHAR(13,10)';

constructor TDatosInformeDocumento.Create(AOwner: TComponent);
begin
  inherited;
  FCabecera := TUniQuery.Create(Self);
  FCabecera.ReadOnly := True;
  FLineas := TUniQuery.Create(Self);
  FLineas.ReadOnly := True;
  FImpuestos := TUniQuery.Create(Self);
  FImpuestos.ReadOnly := True;
  FDatosCabecera := TfrxDBDataset.Create(Self);
  FDatosCabecera.UserName := 'Cabecera';
  FDatosCabecera.DataSet := FCabecera;
  FDatosLineas := TfrxDBDataset.Create(Self);
  FDatosLineas.UserName := 'Lineas';
  FDatosLineas.DataSet := FLineas;
  FDatosImpuestos := TfrxDBDataset.Create(Self);
  FDatosImpuestos.UserName := 'Impuestos';
  FDatosImpuestos.DataSet := FImpuestos;
end;

// Texto vacio como NULL, para que CONCAT_WS se salte el dato.
function SinVacio(const AExpresion: string): string;
begin
  Result := 'NULLIF(TRIM(' + AExpresion + '), '''')';
end;

// Bloque de direccion en varias lineas (sin huecos por datos vacios):
// direccion, CP y poblacion, provincia y pais, contacto y NIF.
function BloqueDireccion(const ASujeto, ANif, ASufijo: string): string;
  function Campo(const ANombre: string): string;
  begin
    Result := ANombre + '_' + ASujeto + ASufijo;
  end;
begin
  Result := 'COALESCE(CONCAT_WS(' + SALTO_SQL + ', ' +
    SinVacio('CONCAT_WS('' '', ' + Campo('DIRECCION1') + ', ' +
      Campo('DIRECCION2') + ')') + ', ' +
    SinVacio('CONCAT_WS('' '', ' + Campo('CODIGO_POSTAL') + ', ' +
      Campo('POBLACION') + ')') + ', ' +
    SinVacio('CONCAT_WS('' - '', ' + SinVacio(Campo('PROVINCIA')) +
      ', ' + SinVacio(Campo('NOMBRE_PAI')) + ')') + ', ' +
    SinVacio('CONCAT_WS('' · '', ' + SinVacio(Campo('MOVIL')) + ', ' +
      SinVacio(Campo('EMAIL')) + ')') + ', ' +
    'CONCAT(' + QuotedStr(SInformeNifDocumento) + ', ' +
      SinVacio('NIF_' + ANif + ASufijo) + ')), '''')';
end;

function SumaImpuesto(const APrefijo, ASufijo: string): string;
const
  TIPOS = 'NRSE';
var
  iTipo: Integer;
begin
  Result := '';
  for iTipo := 1 to Length(TIPOS) do
  begin
    if Result <> '' then
      Result := Result + ' + ';
    Result := Result + 'COALESCE(' + APrefijo + TIPOS[iTipo] +
      ASufijo + ', 0)';
  end;
end;

function HayRecargo(const ASufijo: string): string;
const
  TIPOS = 'NRSE';
var
  iTipo: Integer;
begin
  Result := '';
  for iTipo := 1 to Length(TIPOS) do
  begin
    if Result <> '' then
      Result := Result + ' OR ';
    Result := Result + 'COALESCE(TOTAL_RE' + TIPOS[iTipo] +
      ASufijo + ', 0) <> 0';
  end;
end;

procedure TDatosInformeDocumento.ConfigurarCabecera(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sTercero, sNif, sValidez, sFormaPago, sNotas: string;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sTercero := 'CLIENTE';
  if AConfig.Sentido = sdCompra then
    sTercero := 'PRV';
  sNif := sTercero;
  if (AConfig.TipoDocumento = tdPedido) and
     (AConfig.Sentido = sdVenta) then
    sTercero := 'CLIENTE_FISCAL';
  // Solo el presupuesto tiene fecha de validez.
  sValidez := '''''';
  if AConfig.TipoDocumento = tdPresupuesto then
    sValidez := 'COALESCE(CONCAT(' + QuotedStr(SInformeValidezDocumento) +
      ', DATE_FORMAT(FECHA_VALIDEZ' + sSufijo + ', ''%d/%m/%Y'')), '''')';
  sFormaPago := 'COALESCE((SELECT FP.DESCRIPCION_FORMA_PAGO_FP ' +
    'FROM fza_formas_pago FP WHERE FP.CODIGO_FP_FP = FORMA_PAGO' +
    sSufijo + '), FORMA_PAGO' + sSufijo + ', '''')';
  sNotas := 'COALESCE(CONCAT_WS(' + SALTO_SQL + ', ' +
    SinVacio('COMENTARIOS' + sSufijo) + ', ' +
    SinVacio('OBSERVACIONES' + sSufijo) + '), '''')';
  // Los alias anteriores se conservan: los formatos personalizados que
  // el usuario haya guardado siguen encontrando sus campos.
  FCabecera.SQL.Text :=
    'SELECT SERIE' + sSufijo + ' AS SERIE, NUMERO' + sSufijo +
    ' AS NUMERO, FECHA' + sSufijo + ' AS FECHA, ' +
    'RAZON_SOCIAL_EMPRESA' + sSufijo + ' AS EMPRESA, ' +
    'NIF_EMPRESA' + sSufijo + ' AS NIF_EMPRESA, ' +
    'DIRECCION1_EMPRESA' + sSufijo + ' AS DIRECCION_EMPRESA, ' +
    'POBLACION_EMPRESA' + sSufijo + ' AS POBLACION_EMPRESA, ' +
    BloqueDireccion('EMPRESA', 'EMPRESA', sSufijo) +
    ' AS BLOQUE_EMPRESA, ' +
    'RAZON_SOCIAL_' + sTercero + sSufijo + ' AS TERCERO, ' +
    'NIF_' + sNif + sSufijo + ' AS NIF_TERCERO, ' +
    'DIRECCION1_' + sTercero + sSufijo + ' AS DIRECCION_TERCERO, ' +
    'POBLACION_' + sTercero + sSufijo + ' AS POBLACION_TERCERO, ' +
    BloqueDireccion(sTercero, sNif, sSufijo) + ' AS BLOQUE_TERCERO, ' +
    'TOTAL_BASES' + sSufijo + ' AS BASES, TOTAL_IMPUESTOS' + sSufijo +
    ' AS IMPUESTOS, ' +
    SumaImpuesto('TOTAL_IVA', sSufijo) + ' AS TOTAL_IVA, ' +
    SumaImpuesto('TOTAL_RE', sSufijo) + ' AS RECARGO, (' +
    HayRecargo(sSufijo) + ') AS TIENE_RECARGO, ' +
    'TOTAL_RETENCION' + sSufijo + ' AS RETENCION, ' +
    'COALESCE(PORCENTAJE_RETENCION' + sSufijo +
    ', 0) AS PORCENTAJE_RETENCION, ' +
    'TOTAL_LIQUIDO' + sSufijo + ' AS TOTAL, COMENTARIOS' + sSufijo +
    ' AS COMENTARIOS, OBSERVACIONES' + sSufijo + ' AS OBSERVACIONES, ' +
    sNotas + ' AS NOTAS, ' +
    'FORMA_PAGO' + sSufijo + ' AS FORMA_PAGO, ' +
    sFormaPago + ' AS FORMA_PAGO_DESCRIPCION, ' +
    sValidez + ' AS VALIDEZ FROM ' +
    AConfig.TablaCabecera + ' WHERE SERIE' + sSufijo + ' = :SERIE ' +
    'AND NUMERO' + sSufijo + ' = :NUMERO';
end;

function PrecioLinea(const AConfig: TConfiguracionDocumento): string;
begin
  Result := 'PRECIO_VENTA_SIVA_ARTICULO';
  if AConfig.Sentido = sdCompra then
    Result := 'PRECIO_COMPRA_SIVA_ARTICULO';
  Result := Result + '_' + AConfig.PrefijoLineas;
end;

// FROM ... WHERE de las celdas de talla (pivote) con cantidad de la
// linea L, con los valores de atributo en V.
function CeldasLinea(const AConfig: TConfiguracionDocumento): string;
var
  sCelda, sLineaCelda: string;
begin
  sCelda := AConfig.PrefijoCabecera + 'CEL';
  sLineaCelda := 'LINEA_' + sCelda;
  if AConfig.Sentido = sdCompra then
    sLineaCelda := 'LINEA_' + AConfig.PrefijoCabecera + '_' + sCelda;
  Result := ' FROM ' + AConfig.TablaCabecera + '_celdas C ' +
    'JOIN fza_atributos_valores V ON V.ID_AV = C.ID_AV_PIVOT_' +
    sCelda + ' WHERE C.SERIE_' + AConfig.PrefijoCabecera + '_' +
    sCelda + ' = L.' + AConfig.CampoSerieLinea +
    ' AND C.NUMERO_' + AConfig.PrefijoCabecera + '_' + sCelda +
    ' = L.' + AConfig.CampoNumeroLinea + ' AND C.' + sLineaCelda +
    ' = L.LINEA_' + AConfig.PrefijoLineas + ' AND C.CANTIDAD_' +
    sCelda + ' <> 0';
end;

// Cantidad con el formato del resto del documento: sin decimales si es
// entera y, si no, hasta dos con el separador decimal del equipo.
function CantidadCelda(const AConfig: TConfiguracionDocumento): string;
begin
  Result := 'REPLACE(TRIM(TRAILING ''.'' FROM TRIM(TRAILING ''0'' FROM ' +
    'CAST(ROUND(C.CANTIDAD_' + AConfig.PrefijoCabecera +
    'CEL, 2) AS CHAR))), ''.'', ' +
    QuotedStr(FormatSettings.DecimalSeparator) + ')';
end;

// Linea con varias tallas en celdas (rejilla de tallas en horizontal).
// Con una sola celda la talla ya va en el SKU de la linea.
function VariasTallas(const AConfig: TConfiguracionDocumento): string;
begin
  Result := '((SELECT COUNT(*)' + CeldasLinea(AConfig) + ') > 1)';
end;

// FZ-ISSUE-102: si el valor de atributo AAtributo es el color del SKU de
// la linea, el nombre de su color basico (como vi_atributos_sku_basico:
// articulo > conjunto > global) en vez del codigo (p. ej. "0908"); si no
// es un color o no tiene basico, el propio valor.
function NombreColorAtributo(const AConfig: TConfiguracionDocumento;
  const AAtributo: string): string;
begin
  Result := 'COALESCE((SELECT NULLIF(TRIM(VB.NOMBRE_ATB), '''') ' +
    'FROM vi_atributos_sku_basico VB WHERE VB.CODIGO_UNIDAD_SKU = ' +
    'L.CODIGO_UNIDAD_' + AConfig.PrefijoLineas + ' AND VB.ID_VA_AV = ' +
    '(SELECT E.ID_ATB_VA FROM VI_VARIACIONES_EJES E ' +
    'JOIN fza_articulos_skus SK ON SK.CODIGO_VAR_SKU = E.ID_VAR_VA ' +
    'WHERE SK.CODIGO_UNIDAD_SKU = VB.CODIGO_UNIDAD_SKU ' +
    'AND E.EJE_VA = ''F'') AND VB.VALOR_AV = ' +
    AAtributo + ' LIMIT 1), ' +
    AAtributo + ')';
end;

// Variante en el orden de atributos de la variacion (ATTR1..ATTR5, p. ej.
// color / talla). En una linea con varias tallas se omite el valor que
// es una de esas tallas: va en el desglose.
function VarianteLinea(const AConfig: TConfiguracionDocumento): string;
var
  sAtributo: string;
  iAtributo: Integer;
begin
  Result := 'CONCAT_WS('' / ''';
  for iAtributo := 1 to 5 do
  begin
    sAtributo := 'L.ATTR' + IntToStr(iAtributo) + '_VALOR_' +
      AConfig.PrefijoLineas;
    Result := Result + ', CASE WHEN ' + VariasTallas(AConfig) +
      ' AND EXISTS (SELECT 1' + CeldasLinea(AConfig) + ' AND V.AV = ' +
      sAtributo + ') THEN NULL ELSE NULLIF(TRIM(' +
      NombreColorAtributo(AConfig, sAtributo) + '), '''') END';
  end;
  Result := Result + ')';
  if AConfig.PrefijoLineas <> 'PEDLIN' then
    Result := 'COALESCE(NULLIF(' + Result + ', ''''), NULLIF(TRIM(' +
      'L.DESCRIPCION_VARIACION_' + AConfig.PrefijoLineas + '), ''''))';
end;

procedure TDatosInformeDocumento.ConfigurarLineas(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sPrecio, sVariante, sTallas, sDetalle: string;
begin
  sSufijo := '_' + AConfig.PrefijoLineas;
  sPrecio := PrecioLinea(AConfig);
  sVariante := VarianteLinea(AConfig);
  // Desglose por talla solo si la linea lleva varias; con una, la talla
  // es la del SKU y el desglose repetiria (o contradiria) la variante.
  sTallas := '(CASE WHEN ' + VariasTallas(AConfig) +
    ' THEN (SELECT GROUP_CONCAT(CONCAT(V.AV, '': '', ' +
    CantidadCelda(AConfig) + ') ORDER BY V.ORDEN_AV, V.AV ' +
    'SEPARATOR '' / '')' + CeldasLinea(AConfig) + ') END)';
  // Descripcion y, debajo, variante y tallas solo si las hay.
  sDetalle := 'CONCAT_WS(' + SALTO_SQL + ', COALESCE(' +
    SinVacio('DESCRIPCION_ARTICULO' + sSufijo) + ', CODIGO_ART' +
    sSufijo + ', ''''), ' + SinVacio('CONCAT_WS('' · '', ' +
    SinVacio(sVariante) + ', ' + SinVacio(sTallas) + ')') + ')';
  FLineas.SQL.Text :=
    'SELECT LINEA' + sSufijo + ' AS LINEA, CODIGO_ART' + sSufijo +
    ' AS ARTICULO, CODIGO_UNIDAD' + sSufijo + ' AS SKU, ' +
    'DESCRIPCION_ARTICULO' + sSufijo + ' AS DESCRIPCION, ' +
    sVariante + ' AS VARIACION, ' + sTallas + ' AS TALLAS, ' +
    sDetalle + ' AS DETALLE, ' +
    'COALESCE(TIPO_CANTIDAD_ARTICULO' + sSufijo + ', '''') AS UNIDAD, ' +
    'CANTIDAD' + sSufijo + ' AS CANTIDAD, ' + sPrecio +
    ' AS PRECIO, PORCENTAJE_IVA' + sSufijo + ' AS IVA, ' +
    'ROUND(CANTIDAD' + sSufijo + ' * ' + sPrecio +
    ', 2) AS TOTAL FROM ' + AConfig.TablaLineas + ' L' +
    ' WHERE ' + AConfig.CampoSerieLinea + ' = :SERIE AND ' +
    AConfig.CampoNumeroLinea + ' = :NUMERO ORDER BY LINEA' + sSufijo;
end;

procedure TDatosInformeDocumento.ConfigurarImpuestos(
  const AConfig: TConfiguracionDocumento);
const
  TIPOS: array[0..3] of Char = ('N', 'R', 'S', 'E');
var
  sSufijo, sSufijoLin, sBase, sNombre, sSql: string;
  iTipo: Integer;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sSufijoLin := '_' + AConfig.PrefijoLineas;
  sSql := '';
  for iTipo := 0 to High(TIPOS) do
  begin
    case TIPOS[iTipo] of
      'N': sNombre := SInformeIvaNormalDocumento;
      'R': sNombre := SInformeIvaReducidoDocumento;
      'S': sNombre := SInformeIvaSuperreducidoDocumento;
    else
      sNombre := SInformeIvaExentoDocumento;
    end;
    // Usar el desglose guardado; líneas solo para documentos antiguos
    // cuyos campos nuevos aún no se hayan calculado.
    sBase := '(SELECT COALESCE(SUM(ROUND(L.CANTIDAD' + sSufijoLin +
      ' * L.' + PrecioLinea(AConfig) + ', 2)), 0) FROM ' +
      AConfig.TablaLineas + ' L WHERE L.' + AConfig.CampoSerieLinea +
      ' = :SERIE AND L.' + AConfig.CampoNumeroLinea + ' = :NUMERO ' +
      'AND COALESCE(NULLIF(L.TIPO_IVA_ARTICULO' + sSufijoLin +
      ', ''''), ''N'') = ''' + TIPOS[iTipo] + ''')';
    if sSql <> '' then
      sSql := sSql + ' UNION ALL ';
    sSql := sSql + 'SELECT ' + IntToStr(iTipo) + ' AS ORDEN, ' +
      QuotedStr(sNombre) + ' AS NOMBRE, COALESCE(PORCENTAJE_IVA' +
      TIPOS[iTipo] + sSufijo + ', 0) AS PORCENTAJE, COALESCE(TOTAL_BASEI_IVA' +
      TIPOS[iTipo] + sSufijo + ', ' + sBase + ')' +
      ' AS BASE, COALESCE(PORCENTAJE_RE' + TIPOS[iTipo] + sSufijo +
      ', 0) AS PORCENTAJE_RE, COALESCE(TOTAL_RE' + TIPOS[iTipo] +
      sSufijo + ', 0) AS CUOTA_RE, COALESCE(TOTAL_IVA' +
      TIPOS[iTipo] + sSufijo +
      ', 0) AS CUOTA FROM ' + AConfig.TablaCabecera +
      ' WHERE SERIE' + sSufijo + ' = :SERIE AND NUMERO' + sSufijo +
      ' = :NUMERO';
  end;
  FImpuestos.SQL.Text :=
    'SELECT NOMBRE, PORCENTAJE, BASE, CUOTA, PORCENTAJE_RE, CUOTA_RE ' +
    'FROM (' + sSql + ') T WHERE BASE <> 0 OR CUOTA <> 0 ' +
    'OR CUOTA_RE <> 0 ORDER BY ORDEN';
end;

procedure TDatosInformeDocumento.Abrir(AConexion: TUniConnection;
  const AConfig: TConfiguracionDocumento;
  const ASerie, ANumero: string);
var
  Consultas: TArray<TUniQuery>;
  oConsulta: TUniQuery;
begin
  FCabecera.Close;
  FLineas.Close;
  FImpuestos.Close;
  ConfigurarCabecera(AConfig);
  ConfigurarLineas(AConfig);
  ConfigurarImpuestos(AConfig);
  Consultas := TArray<TUniQuery>.Create(FCabecera, FLineas, FImpuestos);
  for oConsulta in Consultas do
  begin
    oConsulta.Connection := AConexion;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
  end;
  FCabecera.Open;
  if FCabecera.IsEmpty then
    raise Exception.Create(SErrorDocumentoImpresionNoExiste);
  FLineas.Open;
  FImpuestos.Open;
end;

end.
