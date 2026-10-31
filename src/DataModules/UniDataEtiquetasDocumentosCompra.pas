{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEtiquetasDocumentosCompra                              }
{    Tipo:       Acceso a datos                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Etiquetas de un documento de compra (albarán, devolución a proveedor,     }
{    factura/borrador): una etiqueta por unidad del documento, como las de     }
{    pedido (FZ-ISSUE-093/098). Las unidades salen de las celdas por           }
{    almacén de cada línea o, si no tiene, de la propia línea; el almacén      }
{    efectivo es el de la celda, el de la línea o el de la cabecera. Los       }
{    almacenes marcados en el modal filtran esas líneas (no el stock).         }
{    Las lecturas van por la conexión de la ventana del documento: ve las      }
{    líneas recién grabadas en su transacción.                                 }
{******************************************************************************}
unit UniDataEtiquetasDocumentosCompra;

interface

uses
  System.Classes, Uni, cxListView, inLibEtiquetasImpresion,
  inLibEtiquetasLotes;

type
  TDocumentoCompraEtiquetas = (dceAlbaran, dceDevolucion, dceFactura);

  // Sus dos métodos públicos de carga encajan en los callbacks de
  // TfrmPrintEtiqArt (CargarAlmacenesExterno / CrearDataSetExterno).
  TEtiquetasDocumentoCompra = class
  private
    FConexion: TUniConnection;
    FTipo: TDocumentoCompraEtiquetas;
    FSerie: string;
    FNumero: string;
    function Tabla: string;
    function Sufijo: string;
    function SqlUnidades: string;
    function AlmacenesSql(const AAlmacenesCsv: string): string;
    procedure CargarCantidades(const AAlmacenesCsv: string;
      ACantidades: TCantidadesEtiquetas);
    function PrepararLotes(ADmArt: TObject;
      const AAlmacenesCsv: string): TLotesEtiquetas;
    procedure CompletarTiposLote(var ALotes: TLotesEtiquetas);
  protected
    // Lotes y series de las líneas con sus copias (FZ-ISSUE-300: protegido
    // para la prueba de integración EtiquetasCompraLotesIntegracion).
    function CargarLotes(const AAlmacenesCsv: string): TLotesEtiquetas;
  public
    constructor Create(AConexion: TUniConnection;
      ATipo: TDocumentoCompraEtiquetas; const ASerie, ANumero: string);
    // Almacenes efectivos de las líneas, todos marcados.
    procedure CargarAlmacenes(ALV: TcxListView);
    // Crea cdsEtiquetasArt de ADmArt (TdmArticulos) con una fila por unidad.
    procedure CrearDataSet(ADmArt: TObject;
      const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
    // Repite la expansión tras repoblar cdsEtiquetasArt (guías aplicadas).
    procedure ExpandirDataSet(ADmArt: TObject; const AAlmacenesCsv: string);
  end;

implementation

uses
  UniDataCodigosBarrasLote,
  System.SysUtils, Vcl.ComCtrls, UniDataArticulos;

constructor TEtiquetasDocumentoCompra.Create(AConexion: TUniConnection;
  ATipo: TDocumentoCompraEtiquetas; const ASerie, ANumero: string);
begin
  inherited Create;
  FConexion := AConexion;
  FTipo := ATipo;
  FSerie := ASerie;
  FNumero := ANumero;
end;

function TEtiquetasDocumentoCompra.Tabla: string;
begin
  case FTipo of
    dceDevolucion:
      Result := 'fza_devoluciones_compra';
    dceFactura:
      Result := 'fza_facturas_compra';
  else
    Result := 'fza_albaranes_compra';
  end;
end;

function TEtiquetasDocumentoCompra.Sufijo: string;
begin
  case FTipo of
    dceDevolucion:
      Result := 'DEVC';
    dceFactura:
      Result := 'FACC';
  else
    Result := 'ALBC';
  end;
end;

// SKU, CANTIDAD y ALMACEN de cada celda o línea sin celdas del documento
// (:s, :n). Las celdas cruzan con la línea en numérico ('10' = '0010'),
// como los movimientos de stock del albarán.
// FZ-ISSUE-786: si la unidad del artículo admite decimales (metros, kilos)
// la celda o línea da una sola etiqueta (SIGN), no una por metro; unidad
// vacía o desconocida cuenta como Uds, como TOTAL_PRENDAS_ALBC.
function TEtiquetasDocumentoCompra.SqlUnidades: string;
var
  sCab: string;
  sCel: string;
  sLin: string;
  sUnidad: string;
begin
  sCab := Sufijo;
  sLin := sCab + 'LIN';
  sCel := sCab + 'CEL';
  sUnidad :=
    '  LEFT JOIN fza_unidades_medida U ' +
    '    ON U.CODIGO_UNIMED = L.TIPO_CANTIDAD_ARTICULO_' + sLin + ' ';
  Result :=
    'SELECT L.CODIGO_UNIDAD_' + sLin + ' AS SKU, ' +
    '       CASE WHEN COALESCE(U.DECIMALES_UNIMED, 0) = 0 ' +
    '            THEN C.CANTIDAD_' + sCel +
    '            ELSE SIGN(C.CANTIDAD_' + sCel + ') END AS CANTIDAD, ' +
    '       COALESCE(L.LOTE_' + sLin + ', '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_' + sLin + ' AS CADUCIDAD, ' +
    '       COALESCE(NULLIF(C.CODIGO_ALM_' + sCel + ', ''''), ' +
    '                NULLIF(L.CODIGO_ALMACEN_' + sLin + ', ''''), ' +
    '                NULLIF(D.CODIGO_ALM_' + sCab + ', '''')) AS ALMACEN ' +
    '  FROM ' + Tabla + '_lineas L ' +
    '  JOIN ' + Tabla + ' D ' +
    '    ON D.SERIE_' + sCab + ' = L.SERIE_' + sCab + '_' + sLin +
    '   AND D.NUMERO_' + sCab + ' = L.NUMERO_' + sCab + '_' + sLin +
    '  JOIN ' + Tabla + '_celdas C ' +
    '    ON C.SERIE_' + sCab + '_' + sCel + ' = L.SERIE_' + sCab + '_' +
    sLin +
    '   AND C.NUMERO_' + sCab + '_' + sCel + ' = L.NUMERO_' + sCab + '_' +
    sLin +
    '   AND CAST(C.LINEA_' + sCab + '_' + sCel + ' AS UNSIGNED) = ' +
    '       CAST(L.LINEA_' + sLin + ' AS UNSIGNED) ' +
    sUnidad +
    ' WHERE L.SERIE_' + sCab + '_' + sLin + ' = :s ' +
    '   AND L.NUMERO_' + sCab + '_' + sLin + ' = :n ' +
    'UNION ALL ' +
    'SELECT L.CODIGO_UNIDAD_' + sLin + ', ' +
    '       CASE WHEN COALESCE(U.DECIMALES_UNIMED, 0) = 0 ' +
    '            THEN L.CANTIDAD_' + sLin +
    '            ELSE SIGN(L.CANTIDAD_' + sLin + ') END, ' +
    '       COALESCE(L.LOTE_' + sLin + ', ''''), ' +
    '       L.FECHA_CADUCIDAD_' + sLin + ', ' +
    '       COALESCE(NULLIF(L.CODIGO_ALMACEN_' + sLin + ', ''''), ' +
    '                NULLIF(D.CODIGO_ALM_' + sCab + ', '''')) ' +
    '  FROM ' + Tabla + '_lineas L ' +
    '  JOIN ' + Tabla + ' D ' +
    '    ON D.SERIE_' + sCab + ' = L.SERIE_' + sCab + '_' + sLin +
    '   AND D.NUMERO_' + sCab + ' = L.NUMERO_' + sCab + '_' + sLin +
    sUnidad +
    ' WHERE L.SERIE_' + sCab + '_' + sLin + ' = :s ' +
    '   AND L.NUMERO_' + sCab + '_' + sLin + ' = :n ' +
    '   AND NOT EXISTS ( ' +
    '         SELECT 1 FROM ' + Tabla + '_celdas C0 ' +
    '          WHERE C0.SERIE_' + sCab + '_' + sCel + ' = L.SERIE_' +
    sCab + '_' + sLin +
    '            AND C0.NUMERO_' + sCab + '_' + sCel + ' = L.NUMERO_' +
    sCab + '_' + sLin +
    '            AND CAST(C0.LINEA_' + sCab + '_' + sCel +
    ' AS UNSIGNED) = CAST(L.LINEA_' + sLin + ' AS UNSIGNED)) ';
end;

// Los códigos vienen del listado de almacenes del propio documento; se
// entrecomillan igualmente.
function TEtiquetasDocumentoCompra.AlmacenesSql(
  const AAlmacenesCsv: string): string;
var
  oCodigos: TStringList;
  iCodigo: Integer;
begin
  Result := '';
  oCodigos := TStringList.Create;
  try
    oCodigos.StrictDelimiter := True;
    oCodigos.Delimiter := ',';
    oCodigos.DelimitedText := AAlmacenesCsv;
    for iCodigo := 0 to oCodigos.Count - 1 do
    begin
      if Trim(oCodigos[iCodigo]) <> '' then
      begin
        if Result <> '' then
          Result := Result + ',';
        Result := Result + QuotedStr(Trim(oCodigos[iCodigo]));
      end;
    end;
  finally
    FreeAndNil(oCodigos);
  end;
end;

procedure TEtiquetasDocumentoCompra.CargarCantidades(
  const AAlmacenesCsv: string; ACantidades: TCantidadesEtiquetas);
var
  oConsulta: TUniQuery;
  sAlmacenes: string;
  iCantidad: Integer;
begin
  ACantidades.Clear;
  sAlmacenes := AlmacenesSql(AAlmacenesCsv);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT X.SKU, SUM(X.CANTIDAD) AS CANTIDAD ' +
      '  FROM (' + SqlUnidades + ') X ' +
      ' WHERE COALESCE(X.SKU, '''') <> '''' ';
    // Sin almacenes marcados: todas las líneas, como en pedidos.
    if sAlmacenes <> '' then
      oConsulta.SQL.Add('   AND X.ALMACEN IN (' + sAlmacenes + ') ');
    oConsulta.SQL.Add(
      ' GROUP BY X.SKU ' +
      'HAVING SUM(X.CANTIDAD) > 0');
    oConsulta.ParamByName('s').AsString := FSerie;
    oConsulta.ParamByName('n').AsString := FNumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iCantidad := Trunc(oConsulta.FieldByName('CANTIDAD').AsFloat);
      if iCantidad > 0 then
        ACantidades.AddOrSetValue(
          oConsulta.FieldByName('SKU').AsString, iCantidad);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TEtiquetasDocumentoCompra.CargarAlmacenes(ALV: TcxListView);
var
  oConsulta: TUniQuery;
  oElemento: TListItem;
begin
  ALV.Items.BeginUpdate;
  try
    ALV.Items.Clear;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT X.ALMACEN AS COD, ' +
        '       COALESCE(MAX(A.NOMBRE_ALM_ALM), X.ALMACEN) AS NOM ' +
        '  FROM (' + SqlUnidades + ') X ' +
        '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = X.ALMACEN ' +
        ' WHERE COALESCE(X.ALMACEN, '''') <> '''' ' +
        '   AND COALESCE(X.SKU, '''') <> '''' ' +
        ' GROUP BY X.ALMACEN ' +
        ' ORDER BY X.ALMACEN';
      oConsulta.ParamByName('s').AsString := FSerie;
      oConsulta.ParamByName('n').AsString := FNumero;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oElemento := ALV.Items.Add;
        oElemento.Caption := oConsulta.FieldByName('COD').AsString;
        oElemento.SubItems.Add(oConsulta.FieldByName('NOM').AsString);
        oElemento.Checked := True;
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  finally
    ALV.Items.EndUpdate;
  end;
end;

procedure TEtiquetasDocumentoCompra.CrearDataSet(ADmArt: TObject;
  const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
var
  oDmArt: TdmArticulos;
  oCantidades: TCantidadesEtiquetas;
  sSkus: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    oCantidades := TCantidadesEtiquetas.Create;
    try
      CargarCantidades(AAlmacenesCsv, oCantidades);
      sSkus := SkusEtiquetasCsv(oCantidades);
      // Sin almacenes en la consulta base: con ellos expandiría por stock.
      if sSkus <> '' then
      begin
        oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, '', AFecha, sSkus);
        ExpandirEtiquetasConLotes(oDmArt.cdsEtiquetasArt, oCantidades,
          PrepararLotes(ADmArt, AAlmacenesCsv));
      end
      else
        oDmArt.CrearDataSetEtiquetasArt('DUMMY_SIN_LINEAS', ACodTarifa,
          '', AFecha);
    finally
      FreeAndNil(oCantidades);
    end;
  end;
end;

// F-LOTEC-022: unidades de cada lote o serie de las líneas (las líneas
// sin lote no salen: sus etiquetas son las de siempre).
function TEtiquetasDocumentoCompra.CargarLotes(
  const AAlmacenesCsv: string): TLotesEtiquetas;
var
  oConsulta: TUniQuery;
  sAlmacenes: string;
  Lote: TLoteEtiqueta;
begin
  Result := nil;
  sAlmacenes := AlmacenesSql(AAlmacenesCsv);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT X.SKU, X.LOTE, MAX(X.CADUCIDAD) AS CADUCIDAD, ' +
      '       SUM(X.CANTIDAD) AS CANTIDAD ' +
      '  FROM (' + SqlUnidades + ') X ' +
      ' WHERE COALESCE(X.SKU, '''') <> '''' AND X.LOTE <> '''' ';
    if sAlmacenes <> '' then
      oConsulta.SQL.Add('   AND X.ALMACEN IN (' + sAlmacenes + ') ');
    oConsulta.SQL.Add(' GROUP BY X.SKU, X.LOTE ' +
      'HAVING SUM(X.CANTIDAD) > 0 ORDER BY X.SKU, X.LOTE');
    oConsulta.ParamByName('s').AsString := FSerie;
    oConsulta.ParamByName('n').AsString := FNumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Lote := Default(TLoteEtiqueta);
      Lote.Sku := oConsulta.FieldByName('SKU').AsString;
      Lote.Lote := oConsulta.FieldByName('LOTE').AsString;
      Lote.Caducidad := oConsulta.FieldByName('CADUCIDAD').AsDateTime;
      Lote.Copias := Trunc(oConsulta.FieldByName('CANTIDAD').AsFloat);
      Result := Result + [Lote];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if Length(Result) > 0 then
    CompletarTiposLote(Result);
end;

// Solo hay lotes en las líneas con trazabilidad (catálogo de F-LOTEC-003).
procedure TEtiquetasDocumentoCompra.CompletarTiposLote(
  var ALotes: TLotesEtiquetas);
var
  oConsulta: TUniQuery;
  iLote: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT TIPO_LOT FROM fza_articulos_lotes ' +
      ' WHERE CODIGO_UNIDAD_LOT = :SKU AND LOTE_LOT = :LOTE';
    for iLote := 0 to High(ALotes) do
    begin
      oConsulta.Close;
      oConsulta.ParamByName('SKU').AsString := ALotes[iLote].Sku;
      oConsulta.ParamByName('LOTE').AsString := ALotes[iLote].Lote;
      oConsulta.Open;
      ALotes[iLote].TipoLote := oConsulta.FieldByName('TIPO_LOT').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TEtiquetasDocumentoCompra.ExpandirDataSet(ADmArt: TObject;
  const AAlmacenesCsv: string);
var
  oCantidades: TCantidadesEtiquetas;
begin
  if ADmArt is TdmArticulos then
  begin
    oCantidades := TCantidadesEtiquetas.Create;
    try
      CargarCantidades(AAlmacenesCsv, oCantidades);
      ExpandirEtiquetasConLotes(
        TdmArticulos(ADmArt).cdsEtiquetasArt, oCantidades,
        PrepararLotes(ADmArt, AAlmacenesCsv));
    finally
      FreeAndNil(oCantidades);
    end;
  end;
end;

function TEtiquetasDocumentoCompra.PrepararLotes(ADmArt: TObject;
  const AAlmacenesCsv: string): TLotesEtiquetas;
begin
  Result := CargarLotes(AAlmacenesCsv);
  // La conexión del documento ve sus cambios pendientes de confirmar.
  CompletarCodigosEtiquetasLotes(FConexion,
    TdmArticulos(ADmArt).IdentidadSesion.Usuario,
    TdmArticulos(ADmArt).ParametrosApp, Result);
end;

end.
