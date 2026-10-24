{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosValidadorRepositorio                          }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validador de entrada de artículo en caja y documentos.                    }
{    Resuelve código de artículo, SKU, código de barras o referencia de        }
{    proveedor.                                                                }
{******************************************************************************}
unit UniDataArticulosValidadorRepositorio;

{
  Unidad: inLibArticulosValidadorIntf
  Descripción:
    Resuelve una cadena introducida por el usuario (caja, pedidos, albaranes,
    facturas, inventarios, movimientos de almacén, etiquetado, etc.) hasta el
    par canónico (CODIGO_ART_ART, CODIGO_UNIDAD_SKU). Acepta como entrada:

      • Código de artículo  → fza_articulos.CODIGO_ART_ART
      • Código de SKU       → fza_articulos_skus.CODIGO_UNIDAD_SKU
      • Código de barras    → fza_codigos_barras.CODIGO_BARRAS_CB
      • Modelo de proveedor → fza_articulos_proveedores.REF_PROVEEDOR_AP

    Apoyo: vista `vi_caja_busqueda_unificada` (definida en BBDD), que ya
    combina los cuatro orígenes.

  Política sobre artículos con SKUs:
    Si la coincidencia es contra el padre y el padre tiene SKUs activos, la
    librería marca RequiereSku = True y NO selecciona SKU por su cuenta.
    El llamante debe pedir el SKU al usuario (selector talla/color, etc.)
    y volver a llamar con el SKU explícito (o pasarlo a inLibArticulosResolver
    directamente), apoyándose en `inLibArticulosAtributosIntf` para construir
    los desplegables con los valores posibles.

  Uso típico:

      val := TArticulosValidador.Create(AConexion);
      try
        r := val.Resolver(InputUsuario);
        if not r.Encontrado then
          InformarResultado(r.Mensaje)
        else if r.RequiereSku then
          // pedir SKU al usuario y volver a resolver
        else
        begin
          // r.CodigoArticulo, r.CodigoSku, r.TipoCoincidencia
        end;
      finally
        FreeAndNil(val);
      end;
}

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.Variants,
  Data.DB, DBAccess, Uni, inLibArticulosValidadorIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioArticulosValidador = class(
    TInterfacedObject,
    IArticulosValidador)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    procedure RellenarDatosArticulo(var R: TArtResolucionEntrada);
    function  ContarCoincidencias(const sEntrada: string;
                                  ASoloCodigoBarras: Boolean = False): Integer;
    procedure RellenarProveedorMatch(var R: TArtResolucionEntrada;
                                     const sEntrada: string);
    procedure RellenarLoteCoincidencia(var R: TArtResolucionEntrada;
                                       const sEntrada: string);
    function ResolverTexto(const AEntradaOriginal, AEntrada: string;
                           ASoloCodigoBarras: Boolean): TArtResolucionEntrada;
    function ResolverGs1(const AEntradaOriginal, AEntrada: string;
                         ASoloCodigoBarras: Boolean;
                         const ANoEncontrado: TArtResolucionEntrada):
                                                       TArtResolucionEntrada;
    // Nucleo de resolucion. ASoloCodigoBarras restringe la busqueda a la
    // fila EAN de la vista unificada (lectura con pistola).
    function ResolverInterno(const AEntrada: string;
                             ASoloCodigoBarras: Boolean): TArtResolucionEntrada;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function Resolver(const AEntrada: string): TArtResolucionEntrada;
    // Resuelve buscando UNICAMENTE en codigos de barras (TIPO_COINCIDENCIA
    // = 'EAN'). Pensado para la lectura con pistola en caja: ignora codigos
    // de articulo, SKU y modelos de proveedor aunque coincidan.
    function ResolverCodigoBarras(const AEntrada: string):
                                                       TArtResolucionEntrada;
    function ResolverConSku(const AEntrada, ACodigoSkuPreferido: string):
                                                       TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
  end;

// Normaliza campos de linea que admiten entrada libre: articulo, SKU,
// codigo de barras o referencia de proveedor. Si hay SKU resuelto, deja
// guardado el par canonico CODIGO_ART / CODIGO_UNIDAD.
procedure NormalizarArticuloSkuEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku: string;
  const ACampoCodigoBarras: string = '');

// FZ-ISSUE-430: la línea de un artículo con tallas o colores no se graba
// sin su SKU completo (EValidacionBBDD, aviso normal). Tras normalizar.
// No mira la línea editada sin cambiar artículo ni unidad, ni la pivotada
// (tallas en horizontal: ACampoPivote > 0), que reparte por celdas.
procedure ExigirSkuCompletoEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku: string;
  const ACampoPivote: string = '');

// FZ-ISSUE-520: True si ACodigoSku existe en fza_articulos_skus y está
// dado de baja (ESACTIVO_SKU = 'N'). Un código que no es SKU da False.
function SkuDadoDeBaja(AConexion: TUniConnection;
  const ACodigoSku: string): Boolean;

// FZ-ISSUE-520: la línea nueva, o la que cambia de artículo o unidad, no
// se graba con un SKU dado de baja (EValidacionBBDD con AMensaje, que
// recibe el SKU como %s). Las líneas ya grabadas sin cambios no se miran.
procedure ExigirSkuActivoEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku,
  AMensaje: string);

// Recorre el dataset de lineas de un documento (campos por convencion
// CODIGO_ART_ / CODIGO_UNIDAD_ / LINEA_ + sufijo de tabla) y devuelve
// los numeros de linea con articulo que exige SKU (tiene algun SKU
// activo, misma politica que RequiereSku) y sin SKU asignado, separados
// por comas. Cadena vacia si el documento esta completo.
function LineasSinSkuRequerido(AConexion: TUniConnection;
  ALineas: TDataSet; const ASufijo: string): string; overload;
function LineasSinSkuRequerido(
  const AValidador: IArticulosValidador;
  ALineas: TDataSet;
  const ASufijo: string): string; overload;

implementation

uses
  inLibMsgArticulos, inLibErroresBBDD,
  inLibGs1, inLibLecturaGs1Pendiente,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

const
  SQL_CONTAR_COINCIDENCIAS =
    'SELECT COUNT(*) AS N FROM vi_caja_busqueda_unificada ' +
    'WHERE INPUT_BUSQUEDA = :inp ' +
    'AND (:solo = ''N'' OR TIPO_COINCIDENCIA ' +
    'COLLATE utf8mb4_spanish_ci IN (''EAN'' COLLATE utf8mb4_spanish_ci, ' +
    '''SERIE'' COLLATE utf8mb4_spanish_ci, ' +
    '''LOTE'' COLLATE utf8mb4_spanish_ci))';
  SQL_DATOS_ARTICULO =
    'SELECT a.ESACTIVO_ART, a.ESVARIACION_ART, ' +
    'a.TIPO_VARIACION_ART, ' +
    '(SELECT COUNT(*) FROM fza_variaciones_atributos va ' +
    'WHERE va.ID_VAR_VA = a.TIPO_VARIACION_ART) AS NUM_ATR_REQ ' +
    'FROM fza_articulos a WHERE a.CODIGO_ART_ART = :art';
  SQL_SKUS_ACTIVOS =
    'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
    'WHERE CODIGO_ART_SKU = :art AND ESACTIVO_SKU = ''S''';
  SQL_VALIDAR_SKU_ARTICULO =
    'SELECT ESACTIVO_SKU FROM fza_articulos_skus ' +
    'WHERE CODIGO_UNIDAD_SKU = :sku AND CODIGO_ART_SKU = :art';
  SQL_PROVEEDOR_MATCH =
    'SELECT CODIGO_PRV_AP FROM fza_articulos_proveedores ' +
    'WHERE CODIGO_ART_AP = :art AND REF_PROVEEDOR_AP = :ref ' +
    'ORDER BY CASE ESPROVEEDORPRINCIPAL_AP ' +
    'WHEN ''S'' THEN 0 ELSE 1 END LIMIT 1';
  SQL_RESOLVER_ENTRADA =
    'SELECT TIPO_COINCIDENCIA, CODIGO_PADRE, CODIGO_SKU, ' +
    'DESCRIPCION_ART, TIPO_ART, INPUT_BUSQUEDA ' +
    'FROM vi_caja_busqueda_unificada ' +
    'WHERE INPUT_BUSQUEDA = :inp ' +
    'AND (:solo = ''N'' OR TIPO_COINCIDENCIA ' +
    'COLLATE utf8mb4_spanish_ci IN (''EAN'' COLLATE utf8mb4_spanish_ci, ' +
    '''SERIE'' COLLATE utf8mb4_spanish_ci, ' +
    '''LOTE'' COLLATE utf8mb4_spanish_ci)) ' +
    'ORDER BY CASE WHEN TIPO_COINCIDENCIA ' +
    'COLLATE utf8mb4_spanish_ci = ''SKU'' ' +
    'COLLATE utf8mb4_spanish_ci THEN 1 ' +
    'WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ''CODIGO'' ' +
    'COLLATE utf8mb4_spanish_ci THEN 2 ' +
    'WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ''EAN'' ' +
    'COLLATE utf8mb4_spanish_ci THEN 3 ' +
    'WHEN TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci = ''MODELO_PROV'' ' +
    'COLLATE utf8mb4_spanish_ci THEN 4 ELSE 5 END LIMIT 1';
  // F-LOTEC: lote o serie del código por unidad o lote (script 776).
  SQL_LOTE_COINCIDENCIA =
    'SELECT TIPO_COINCIDENCIA, LOTE_BUSQUEDA, FECHA_CADUCIDAD_BUSQUEDA ' +
    'FROM vi_caja_busqueda_unificada ' +
    'WHERE INPUT_BUSQUEDA = :inp ' +
    'AND TIPO_COINCIDENCIA COLLATE utf8mb4_spanish_ci IN ' +
    '(''SERIE'' COLLATE utf8mb4_spanish_ci, ' +
    '''LOTE'' COLLATE utf8mb4_spanish_ci) LIMIT 1';
  SQL_SKU_DADO_DE_BAJA =
    'SELECT 1 AS DE_BAJA FROM fza_articulos_skus ' +
    'WHERE CODIGO_UNIDAD_SKU = :sku AND ESACTIVO_SKU = ''N'' LIMIT 1';
  SQL_TIENE_SKU_ACTIVO =
    'SELECT 1 AS TIENE_SKU FROM fza_articulos_skus ' +
    'WHERE CODIGO_ART_SKU = :art ' +
    'AND COALESCE(ESACTIVO_SKU, ''S'') = ''S'' LIMIT 1';

function DefinicionSql(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioArticulosValidador',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function NormalizarEntradaLector(const AEntrada: string): string;
begin
  Result := Trim(AEntrada);
  Result := StringReplace(Result, #2, '', [rfReplaceAll]);
  Result := StringReplace(Result, #3, '', [rfReplaceAll]);
  if StartsText('STX', Result) then
    Delete(Result, 1, 3);
  if EndsText('ETX', Result) then
    Delete(Result, Length(Result) - 2, 3);
  Result := Trim(Result);
end;

function ValorCampoNormalizacion(ADataSet: TDataSet;
  const ACampo: string): string;
var
  Campo: TField;
begin
  Result := '';
  if Assigned(ADataSet) and (ACampo <> '') then
  begin
    Campo := ADataSet.FindField(ACampo);
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsString;
  end;
end;

function CampoNormalizacionCambiado(ADataSet: TDataSet;
  const ACampo: string): Boolean;
var
  Campo: TField;
begin
  Result := False;
  if Assigned(ADataSet) and (ACampo <> '') and (ADataSet.State = dsEdit) then
  begin
    Campo := ADataSet.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString) <> Trim(VarToStr(Campo.OldValue));
  end;
end;

function DebeNormalizarArticuloSku(ADataSet: TDataSet;
  const ACampoArticulo, ACampoSku, ACampoCodigoBarras: string): Boolean;
begin
  Result := True;
  if Assigned(ADataSet) and (ADataSet.State = dsEdit) then
    Result := CampoNormalizacionCambiado(ADataSet, ACampoArticulo) or
              CampoNormalizacionCambiado(ADataSet, ACampoSku) or
              CampoNormalizacionCambiado(ADataSet, ACampoCodigoBarras);
end;

procedure PonerCampoNormalizacion(ADataSet: TDataSet;
  const ACampo, AValor: string);
var
  Campo: TField;
begin
  if Assigned(ADataSet) and (ACampo <> '') then
  begin
    Campo := ADataSet.FindField(ACampo);
    if (Campo <> nil) and (not Campo.ReadOnly) and
       (Campo.AsString <> AValor) then
    begin
      if not (ADataSet.State in dsEditModes) then
        ADataSet.Edit;
      Campo.AsString := AValor;
    end;
  end;
end;

procedure ResolverEntradaNormalizacion(
  const AValidador: IArticulosValidador;
  const AEntrada: string; out AResolucion: TArtResolucionEntrada);
begin
  AResolucion.Clear;
  if NormalizarEntradaLector(AEntrada) <> '' then
    AResolucion := AValidador.Resolver(AEntrada);
end;

procedure NormalizarArticuloSkuEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku: string;
  const ACampoCodigoBarras: string);
var
  Validador: IArticulosValidador;
  RArt: TArtResolucionEntrada;
  RSku: TArtResolucionEntrada;
  RBarras: TArtResolucionEntrada;
  RElegida: TArtResolucionEntrada;
  sArticulo: string;
  sSku: string;
  sBarras: string;
  bElegida: Boolean;
begin
  if (AConexion <> nil) and Assigned(ADataSet) and ADataSet.Active then
  begin
    if DebeNormalizarArticuloSku(ADataSet, ACampoArticulo, ACampoSku,
                                 ACampoCodigoBarras) then
    begin
      sArticulo := Trim(ValorCampoNormalizacion(ADataSet, ACampoArticulo));
      sSku := Trim(ValorCampoNormalizacion(ADataSet, ACampoSku));
      sBarras := Trim(ValorCampoNormalizacion(ADataSet, ACampoCodigoBarras));
      if (sArticulo <> '') or (sSku <> '') or (sBarras <> '') then
      begin
        Validador := TRepositorioArticulosValidador.Create(AConexion);
        ResolverEntradaNormalizacion(Validador, sArticulo, RArt);
        ResolverEntradaNormalizacion(Validador, sSku, RSku);
        ResolverEntradaNormalizacion(Validador, sBarras, RBarras);
        Validador := nil;
        RElegida.Clear;
        bElegida := False;
        if RArt.Encontrado and (RArt.Tipo <> atcCodigoArt) then
        begin
          RElegida := RArt;
          bElegida := True;
        end
        else if RSku.Encontrado and
                ((not RArt.Encontrado) or
                 SameText(RSku.CodigoArticulo, RArt.CodigoArticulo)) then
        begin
          RElegida := RSku;
          bElegida := True;
        end
        else if RBarras.Encontrado and
                ((not RArt.Encontrado) or
                 SameText(RBarras.CodigoArticulo, RArt.CodigoArticulo)) then
        begin
          RElegida := RBarras;
          bElegida := True;
        end
        else if RArt.Encontrado then
        begin
          RElegida := RArt;
          bElegida := True;
        end;
        if bElegida then
        begin
          PonerCampoNormalizacion(ADataSet, ACampoArticulo,
                                  RElegida.CodigoArticulo);
          if (RElegida.CodigoSku <> '') and (not RElegida.RequiereSku) then
            PonerCampoNormalizacion(ADataSet, ACampoSku, RElegida.CodigoSku)
          else if RArt.Encontrado and RSku.Encontrado and
                  (not SameText(RArt.CodigoArticulo,
                                RSku.CodigoArticulo)) then
            PonerCampoNormalizacion(ADataSet, ACampoSku, '')
          // FZ-ISSUE-430: el código del modelo no vale como SKU de un
          // artículo que exige elegir talla o color.
          else if RElegida.RequiereSku and
                  SameText(sSku, RElegida.CodigoArticulo) then
            PonerCampoNormalizacion(ADataSet, ACampoSku, '');
          if RElegida.CodigoBarrasMatch <> '' then
            PonerCampoNormalizacion(ADataSet, ACampoCodigoBarras,
                                    RElegida.CodigoBarrasMatch);
        end;
      end;
    end;
  end;
end;

function LineaPivotadaNormalizacion(ADataSet: TDataSet;
  const ACampoPivote: string): Boolean;
var
  Campo: TField;
begin
  Result := False;
  if ACampoPivote <> '' then
  begin
    Campo := ADataSet.FindField(ACampoPivote);
    Result := (Campo <> nil) and (not Campo.IsNull) and
      (Campo.AsInteger > 0);
  end;
end;

procedure ExigirSkuCompletoEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku: string;
  const ACampoPivote: string);
var
  Validador: IArticulosValidador;
  RUnidad: TArtResolucionEntrada;
  sArticulo: string;
  sSku: string;
  bCompleta: Boolean;
begin
  if (AConexion <> nil) and Assigned(ADataSet) and ADataSet.Active and
     DebeNormalizarArticuloSku(ADataSet, ACampoArticulo, ACampoSku, '') and
     (not LineaPivotadaNormalizacion(ADataSet, ACampoPivote)) then
  begin
    sArticulo := Trim(ValorCampoNormalizacion(ADataSet, ACampoArticulo));
    sSku := Trim(ValorCampoNormalizacion(ADataSet, ACampoSku));
    if sArticulo <> '' then
    begin
      Validador := TRepositorioArticulosValidador.Create(AConexion);
      // Sin SKU activos (artículo simple o línea libre) no hay que elegir.
      bCompleta := not Validador.TieneSkuActivo(sArticulo);
      if (not bCompleta) and (sSku <> '') then
      begin
        RUnidad := Validador.Resolver(sSku);
        bCompleta := RUnidad.Encontrado and (not RUnidad.RequiereSku) and
          SameText(Trim(RUnidad.CodigoArticulo), sArticulo) and
          SameText(Trim(RUnidad.CodigoSku), sSku);
      end;
      Validador := nil;
      if not bCompleta then
        raise EValidacionBBDD.CreateFmt(SAvisoArticuloRequiereSku,
          [sArticulo]);
    end;
  end;
end;

function SkuDadoDeBaja(AConexion: TUniConnection;
  const ACodigoSku: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if (AConexion <> nil) and (Trim(ACodigoSku) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text := SQL_SKU_DADO_DE_BAJA;
      q.ParamByName('sku').AsString := Trim(ACodigoSku);
      q.Open;
      Result := not q.IsEmpty;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure ExigirSkuActivoEnDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoArticulo, ACampoSku,
  AMensaje: string);
var
  sSku: string;
begin
  if (AConexion <> nil) and Assigned(ADataSet) and ADataSet.Active and
     DebeNormalizarArticuloSku(ADataSet, ACampoArticulo, ACampoSku, '') then
  begin
    sSku := Trim(ValorCampoNormalizacion(ADataSet, ACampoSku));
    if SkuDadoDeBaja(AConexion, sSku) then
      raise EValidacionBBDD.CreateFmt(AMensaje, [sSku]);
  end;
end;

{ TRepositorioArticulosValidador }

constructor TRepositorioArticulosValidador.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioArticulosValidador.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 8);
  Result[0] := DefinicionSql(
    'ContarCoincidencias',
    SQL_CONTAR_COINCIDENCIAS,
    'inp,solo',
    'N');
  Result[1] := DefinicionSql(
    'ObtenerDatosArticulo',
    SQL_DATOS_ARTICULO,
    'art',
    'ESACTIVO_ART,ESVARIACION_ART,TIPO_VARIACION_ART,NUM_ATR_REQ');
  Result[2] := DefinicionSql(
    'ListarSkusActivos',
    SQL_SKUS_ACTIVOS,
    'art',
    'CODIGO_UNIDAD_SKU');
  Result[3] := DefinicionSql(
    'ValidarSkuArticulo',
    SQL_VALIDAR_SKU_ARTICULO,
    'sku,art',
    'ESACTIVO_SKU');
  Result[4] := DefinicionSql(
    'ObtenerProveedorMatch',
    SQL_PROVEEDOR_MATCH,
    'art,ref',
    'CODIGO_PRV_AP');
  Result[5] := DefinicionSql(
    'ResolverEntrada',
    SQL_RESOLVER_ENTRADA,
    'inp,solo',
    'TIPO_COINCIDENCIA,CODIGO_PADRE,CODIGO_SKU,' +
    'DESCRIPCION_ART,TIPO_ART,INPUT_BUSQUEDA');
  Result[6] := DefinicionSql(
    'TieneSkuActivo',
    SQL_TIENE_SKU_ACTIVO,
    'art',
    'TIENE_SKU');
  Result[7] := DefinicionSql(
    'ObtenerLoteCoincidencia',
    SQL_LOTE_COINCIDENCIA,
    'inp',
    'TIPO_COINCIDENCIA,LOTE_BUSQUEDA,FECHA_CADUCIDAD_BUSQUEDA');
end;

function TRepositorioArticulosValidador.ContarCoincidencias(
  const sEntrada: string; ASoloCodigoBarras: Boolean): Integer;
var
  q: TUniQuery;
  oDefinicion: TDefinicionSql;
  sSoloCodigoBarras: string;
begin
  if ASoloCodigoBarras then
    sSoloCodigoBarras := 'S'
  else
    sSoloCodigoBarras := 'N';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    oDefinicion := DefinicionesSql[0];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        q.ParamByName('inp').AsString := sEntrada;
        q.ParamByName('solo').AsString := sSoloCodigoBarras;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    Result := q.FieldByName('N').AsInteger;
  finally
    FreeAndNil(q);
  end;
end;

procedure TRepositorioArticulosValidador.RellenarDatosArticulo(
  var R: TArtResolucionEntrada);
var
  q: TUniQuery;
  iNumSkus: Integer;
  iOtrosSkus: Integer;
  oDefinicion: TDefinicionSql;
  sCodigoArticulo: string;
  sCodigoSku: string;
  sUnico: string;
  DatosEncontrados: Boolean;
begin
  if R.CodigoArticulo <> '' then
  begin
  sCodigoArticulo := R.CodigoArticulo;
  DatosEncontrados := False;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    oDefinicion := DefinicionesSql[1];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        q.ParamByName('art').AsString := sCodigoArticulo;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    if q.IsEmpty then
    begin
      R.Encontrado := False;
      R.Mensaje := Format(SErrorArticuloNoExiste, [R.CodigoArticulo]);
    end
    else
    begin
      R.EsActivoArticulo := q.FieldByName('ESACTIVO_ART').AsString = 'S';
      R.EsVariacion      := q.FieldByName('ESVARIACION_ART').AsString = 'S';
      R.NumAtributosReq  := q.FieldByName('NUM_ATR_REQ').AsInteger;
      DatosEncontrados := True;
    end;
  finally
    FreeAndNil(q);
  end;
  if DatosEncontrados then
  begin
  // Contamos SKUs activos del artículo. Si hay sólo uno (caso típico de
  // servicios y artículos sin variación: SKU autocreado con mismo código),
  // lo resolvemos automáticamente y NO marcamos RequiereSku.
  iNumSkus := 0;
  iOtrosSkus := 0;
  sUnico := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    oDefinicion := DefinicionesSql[2];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        q.ParamByName('art').AsString := sCodigoArticulo;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    while not q.Eof do
    begin
      Inc(iNumSkus);
      if iNumSkus = 1 then sUnico :=
        q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      if not SameText(
           Trim(q.FieldByName('CODIGO_UNIDAD_SKU').AsString),
           Trim(sCodigoArticulo)) then
        Inc(iOtrosSkus);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
  R.TieneSku := iNumSkus > 0;
  if (iNumSkus = 1) and (R.CodigoSku = '') then
    R.CodigoSku := sUnico;

  // Validar que CodigoSku, si vino, pertenece al artículo
  if R.CodigoSku <> '' then
  begin
    sCodigoSku := R.CodigoSku;
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      oDefinicion := DefinicionesSql[3];
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        FCatalogoSql,
        procedure(const ASql: string)
        begin
          q.Close;
          q.SQL.Text := ASql;
          q.ParamByName('sku').AsString := sCodigoSku;
          q.ParamByName('art').AsString := sCodigoArticulo;
          q.Open;
          ValidarCamposResultadoSql(
            oDefinicion,
            q);
        end,
        FIncidenciasSql);
      if q.IsEmpty then
      begin
        // SKU no pertenece al artículo: lo desligamos
        R.CodigoSku := '';
        R.SkuActivo := False;
      end
      else
        R.SkuActivo := q.FieldByName('ESACTIVO_SKU').AsString = 'S';
    finally
      FreeAndNil(q);
    end;
  end;

  // FZ-ISSUE-430: el SKU con el mismo código que el artículo es el del
  // modelo. Si el artículo tiene además otros SKU activos (tallas,
  // colores), teclear el modelo no elige unidad: se exige el SKU. Antes
  // la línea se grababa con el código del modelo y movía su stock.
  if (R.CodigoSku <> '') and (iOtrosSkus > 0) and
     SameText(Trim(R.CodigoSku), Trim(sCodigoArticulo)) then
    R.CodigoSku := '';

  // Política: si el artículo tiene SKUs y todavía no hay uno → exige SKU.
  // (Si arriba autorresolvimos al único SKU, R.CodigoSku ya no estará vacío.)
  R.RequiereSku := R.TieneSku and (R.CodigoSku = '');
  end;
  end;
end;

procedure TRepositorioArticulosValidador.RellenarProveedorMatch(
  var R: TArtResolucionEntrada; const sEntrada: string);
var
  q: TUniQuery;
  oDefinicion: TDefinicionSql;
  sCodigoArticulo: string;
begin
  sCodigoArticulo := R.CodigoArticulo;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    oDefinicion := DefinicionesSql[4];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        q.ParamByName('art').AsString := sCodigoArticulo;
        q.ParamByName('ref').AsString := sEntrada;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    if not q.IsEmpty then
      R.CodigoProveedorMatch := q.FieldByName('CODIGO_PRV_AP').AsString;
  finally
    FreeAndNil(q);
  end;
end;

function TRepositorioArticulosValidador.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := ResolverInterno(AEntrada, False);
end;

function TRepositorioArticulosValidador.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := ResolverInterno(AEntrada, True);
end;

function TRepositorioArticulosValidador.ResolverInterno(
  const AEntrada: string;
  ASoloCodigoBarras: Boolean): TArtResolucionEntrada;
var
  sEnt: string;
begin
  sEnt := NormalizarEntradaLector(AEntrada);
  Result := ResolverTexto(AEntrada, sEnt, ASoloCodigoBarras);
  // F-LOTEC (decision 9): un GS1-128 / DataMatrix que no es un codigo
  // conocido tal cual se busca por su GTIN y aporta lote, serie y
  // caducidad. Lo que ya se resolvia antes no cambia.
  if (not Result.Encontrado) and (sEnt <> '') and EsLecturaGs1(sEnt) then
    Result := ResolverGs1(AEntrada, sEnt, ASoloCodigoBarras, Result);
end;

function TRepositorioArticulosValidador.ResolverGs1(
  const AEntradaOriginal, AEntrada: string;
  ASoloCodigoBarras: Boolean;
  const ANoEncontrado: TArtResolucionEntrada): TArtResolucionEntrada;
var
  rGs1: TResultadoGs1;
begin
  Result := ANoEncontrado;
  rGs1 := InterpretarGs1(AEntrada);
  if rGs1.EsValido and (rGs1.Datos.Gtin <> '') then
  begin
    Result := ResolverTexto(AEntradaOriginal,
      GtinACodigoComercial(rGs1.Datos.Gtin), ASoloCodigoBarras);
    if Result.Encontrado then
    begin
      Result.EsGs1 := True;
      Result.Lote := rGs1.Datos.Lote;
      Result.Serie := rGs1.Datos.Serie;
      Result.FechaCaducidad := rGs1.Datos.FechaCaducidad;
      // Para la línea que se dé de alta por la rejilla (sin la trama del
      // lector), que solo aplica el artículo.
      AnotarLecturaGs1(Result.CodigoSku, Result.Lote, Result.Serie,
        Result.FechaCaducidad);
    end
    else
      Result := ANoEncontrado;
  end;
end;

procedure TRepositorioArticulosValidador.RellenarLoteCoincidencia(
  var R: TArtResolucionEntrada; const sEntrada: string);
var
  q: TUniQuery;
  oDefinicion: TDefinicionSql;
  sEntradaLote: string;
  sLote: string;
begin
  sEntradaLote := sEntrada;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    oDefinicion := DefinicionesSql[7];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        q.ParamByName('inp').AsString := sEntradaLote;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    if not q.IsEmpty then
    begin
      sLote := q.FieldByName('LOTE_BUSQUEDA').AsString;
      if R.Tipo = atcSerie then
        R.Serie := sLote
      else
        R.Lote := sLote;
      if not q.FieldByName('FECHA_CADUCIDAD_BUSQUEDA').IsNull then
        R.FechaCaducidad := Trunc(
          q.FieldByName('FECHA_CADUCIDAD_BUSQUEDA').AsDateTime);
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TRepositorioArticulosValidador.ResolverTexto(
  const AEntradaOriginal, AEntrada: string;
  ASoloCodigoBarras: Boolean): TArtResolucionEntrada;
var
  q: TUniQuery;
  oDefinicion: TDefinicionSql;
  sEnt: string;
  sSoloCodigoBarras: string;
  sTipo: string;
  CoincidenciaEncontrada: Boolean;
begin
  Result.Clear;
  Result.EntradaOriginal := AEntradaOriginal;
  sEnt := AEntrada;
  if sEnt = '' then
    Result.Mensaje := SErrorEntradaArticuloVacia;
  if sEnt <> '' then
  begin
  CoincidenciaEncontrada := False;
  if ASoloCodigoBarras then
    sSoloCodigoBarras := 'S'
  else
    sSoloCodigoBarras := 'N';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    oDefinicion := DefinicionesSql[5];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        q.ParamByName('inp').AsString := sEnt;
        q.ParamByName('solo').AsString := sSoloCodigoBarras;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    if q.IsEmpty then
    begin
      if ASoloCodigoBarras then
        Result.Mensaje := Format(SErrorCodigoBarrasNoEncontrado, [sEnt])
      else
        Result.Mensaje := Format(SErrorArticuloEntradaNoEncontrado, [sEnt]);
    end
    else
    begin
      Result.CodigoArticulo      := q.FieldByName('CODIGO_PADRE').AsString;
      Result.CodigoSku           := q.FieldByName('CODIGO_SKU').AsString;
      Result.DescripcionArticulo := q.FieldByName('DESCRIPCION_ART').AsString;
      Result.TipoArticulo        := q.FieldByName('TIPO_ART').AsString;
      sTipo := q.FieldByName('TIPO_COINCIDENCIA').AsString;
      CoincidenciaEncontrada := True;
    end;
  finally
    FreeAndNil(q);
  end;
  if CoincidenciaEncontrada then
  begin
  if      sTipo = 'CODIGO'      then Result.Tipo := atcCodigoArt
  else if sTipo = 'SKU'         then Result.Tipo := atcCodigoSku
  else if sTipo = 'EAN'         then Result.Tipo := atcCodigoBarras
  else if sTipo = 'MODELO_PROV' then Result.Tipo := atcRefProveedor
  else if sTipo = 'SERIE'       then Result.Tipo := atcSerie
  else if sTipo = 'LOTE'        then Result.Tipo := atcLote
  else                               Result.Tipo := atcDesconocido;

  case Result.Tipo of
    atcCodigoBarras, atcSerie, atcLote:
      Result.CodigoBarrasMatch := sEnt;
    atcRefProveedor: Result.RefProveedorMatch := sEnt;
  end;
  if Result.Tipo in [atcSerie, atcLote] then
  begin
    RellenarLoteCoincidencia(Result, sEnt);
    AnotarLecturaGs1(Result.CodigoSku, Result.Lote, Result.Serie,
      Result.FechaCaducidad);
  end;

  if Result.Tipo = atcCodigoBarras then
    DescartarLecturaGs1;

  Result.Encontrado       := Result.CodigoArticulo <> '';
  Result.NumCoincidencias := ContarCoincidencias(sEnt, ASoloCodigoBarras);

  RellenarDatosArticulo(Result);

  if Result.Tipo = atcRefProveedor then
    RellenarProveedorMatch(Result, sEnt);

  if Result.Encontrado and Result.RequiereSku then
    Result.Mensaje := Format(SAvisoArticuloRequiereSku,
                             [Result.CodigoArticulo])
  else if Result.Encontrado and (not Result.TieneSku) then
  begin
    // Localizado y activo pero sin ninguna unidad (SKU) activa que vender:
    // p. ej. variación sin tallas/colores. Motivo exacto, no "no encontrado".
    if Result.EsVariacion then
      Result.Mensaje := Format(SErrorArticuloVariacionSinSkusActivos,
                               [Result.CodigoArticulo])
    else
      Result.Mensaje := Format(SErrorArticuloSinSkusActivos,
                               [Result.CodigoArticulo]);
  end;
  end;
  end;
end;

function TRepositorioArticulosValidador.ResolverConSku(
  const AEntrada,
  ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := Resolver(AEntrada);
  if Result.Encontrado and (ACodigoSkuPreferido <> '') and
     ((Result.CodigoSku = '') or Result.RequiereSku) then
  begin
    // Probar a ligar el SKU sugerido por el llamante
    Result.CodigoSku := ACodigoSkuPreferido;
    Result.RequiereSku := False;
    RellenarDatosArticulo(Result);
    if Result.RequiereSku then
      Result.Mensaje := Format(SErrorSkuNoPerteneceArticulo,
        [ACodigoSkuPreferido, Result.CodigoArticulo]);
  end;
end;

function TRepositorioArticulosValidador.EsValido(
  const AEntrada: string): Boolean;
var
  R: TArtResolucionEntrada;
begin
  R := Resolver(AEntrada);
  Result := R.Encontrado and (not R.RequiereSku);
end;

function TRepositorioArticulosValidador.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
var
  q: TUniQuery;
  oDefinicion: TDefinicionSql;
begin
  Result := False;
  if ACodigoArticulo <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      oDefinicion := DefinicionesSql[6];
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        FCatalogoSql,
        procedure(const ASql: string)
        begin
          q.Close;
          q.SQL.Text := ASql;
          q.ParamByName('art').AsString := ACodigoArticulo;
          q.Open;
          ValidarCamposResultadoSql(
            oDefinicion,
            q);
        end,
        FIncidenciasSql);
      Result := not q.IsEmpty;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function LineasSinSkuRequerido(
  const AValidador: IArticulosValidador;
  ALineas: TDataSet;
  const ASufijo: string): string;
var
  slCache: TStringList;
  Bm: TBookmark;
  sArt, sTiene: string;
  fldArt, fldSku, fldLinea: TField;
begin
  Result := '';
  if Assigned(AValidador) and
     (ALineas <> nil) and
     ALineas.Active then
  begin
    fldArt   := ALineas.FindField('CODIGO_ART_' + ASufijo);
    fldSku   := ALineas.FindField('CODIGO_UNIDAD_' + ASufijo);
    fldLinea := ALineas.FindField('LINEA_' + ASufijo);
    if (fldArt <> nil) and (fldSku <> nil) and (fldLinea <> nil) and
       (not ALineas.IsEmpty) then
    begin
      slCache := TStringList.Create;
      Bm := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof do
        begin
          sArt := Trim(fldArt.AsString);
          if (sArt <> '') and (Trim(fldSku.AsString) = '') then
          begin
            // Cache por articulo: las lineas repiten articulo y evita
            // una consulta por linea.
            sTiene := slCache.Values[sArt];
            if sTiene = '' then
            begin
              if AValidador.TieneSkuActivo(sArt) then
                sTiene := 'S';
              if sTiene = '' then
                sTiene := 'N';
              slCache.Values[sArt] := sTiene;
            end;
            if sTiene = 'S' then
            begin
              if Result <> '' then
                Result := Result + ', ';
              Result := Result + fldLinea.AsString;
            end;
          end;
          ALineas.Next;
        end;
        if ALineas.BookmarkValid(Bm) then
          ALineas.GotoBookmark(Bm);
      finally
        ALineas.EnableControls;
        ALineas.FreeBookmark(Bm);
        FreeAndNil(slCache);
      end;
    end;
  end;
end;

function LineasSinSkuRequerido(
  AConexion: TUniConnection;
  ALineas: TDataSet;
  const ASufijo: string): string;
var
  oValidador: IArticulosValidador;
begin
  Result := '';
  if Assigned(AConexion) then
  begin
    oValidador :=
      TRepositorioArticulosValidador.Create(AConexion);
    Result := LineasSinSkuRequerido(
      oValidador,
      ALineas,
      ASufijo);
    oValidador := nil;
  end;
end;

end.
