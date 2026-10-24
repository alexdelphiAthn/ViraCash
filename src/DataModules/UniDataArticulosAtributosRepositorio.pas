{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosAtributosRepositorio                          }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lookup de atributos y propiedades de artículos.                           }
{    Devuelve los valores posibles para construir selectores de variación.     }
{******************************************************************************}
unit UniDataArticulosAtributosRepositorio;

{
  Unidad: inLibArticulosAtributosIntf
  Descripción:
    Devuelve, para un código de artículo, los atributos de variación
    (color/talla/temporada/...) y las propiedades estructuradas
    (material, marca, género, ...) con los **valores posibles ordenados**
    para que cualquier formulario pueda construir desplegables coherentes
    sin duplicar SQL.

    La lectura es por código de artículo (padre). Si el artículo aún no
    tiene SKU resuelto, devolverá igualmente la lista de opciones de cada
    atributo: el llamante (caja, factura, pedido, albarán, etiquetas) las
    usa para mostrar el selector y, una vez elegido, llama a
    `inLibArticulosResolver` con el SKU concreto.

  Origen de datos:
    • fza_variaciones_atributos
    • fza_articulos_conjuntos_asign  (qué conjunto cubre cada atributo)
    • fza_atributos_conjuntos / fza_atributos_conjuntos_det
    • fza_atributos_valores          (valores y orden global)
    • fza_articulos_propiedades / fza_propiedades / fza_propiedades_valores

  Si el artículo no tiene conjunto asignado para un atributo concreto, el
  método devuelve los valores activos de ese atributo (fallback) para que
  los selectores no queden vacíos.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, Uni, inLibArticulosAtributosIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioArticulosAtributos = class(
    TInterfacedObject,
    IArticulosAtributosLookup)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function TipoDesdeCadena(const s: string): TTipoValorPropiedad;
    procedure CargarValoresAtributo(
      const AIdAtributo: string;
      const AIdConjunto: Integer;
      out AValores: TArray<TArticuloAtributoValor>);
    procedure CargarValoresPropiedad(
      const ACodigoPropiedad: string;
      out AValores: TArray<TArticuloAtributoValor>);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    // Atributos de variación del artículo. Devuelve las opciones que el
    // usuario puede elegir (talla, color, ...). Si el artículo NO tiene
    // tipo de variación, devuelve un array vacío.
    function ObtenerAtributos(const ACodigoArticulo: string)
                                          : TArray<TArticuloAtributo>;

    // Propiedades del artículo + valores posibles (si son LISTA).
    function ObtenerPropiedades(const ACodigoArticulo: string)
                                          : TArray<TArticuloPropiedad>;

    // Lee los valores concretos asignados a un SKU
    // (Color=ROJO, Talla=M, ...). Útil para construir descripciones legibles
    // o para que el llamante sepa qué tiene resuelto.
    function ObtenerAtributosDeSku(const ACodigoSku: string)
                                          : TArray<TArticuloAtributoValor>;

    // Valores de un atributo (orden visual 1..N) que el articulo YA TIENE
    // referenciados en alguno de sus SKUs. A diferencia de
    // ObtenerAtributos.Valores (que devuelve todas las opciones posibles
    // del conjunto asignado), este metodo restringe a los AV que ya
    // forman parte de algun SKU del articulo — util para dropdowns donde
    // la linea editada debe cuadrar contra un SKU existente (caso tipico:
    // celda Talla / Color en una linea de inventario / albaran).
    // Ordenado por ORDEN_AV (con desempate alfabetico por AV).
    function ObtenerAvsEnSkus(const ACodigoArticulo: string;
                              AOrdenAtributo: Integer)
                              : TArray<TArticuloAtributoValor>;
  end;

implementation

uses
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

const
  SQL_VALORES_ATRIBUTO_CONJUNTO =
    'SELECT av.ID_AV, av.AV, av.DESCRIPCION_AV, ' +
    'COALESCE(acd.ORDEN_ACD, av.ORDEN_AV) AS ORDEN_FINAL, ' +
    'av.ESACTIVO_AV FROM fza_atributos_conjuntos_det acd ' +
    'JOIN fza_atributos_valores av ON av.ID_AV = acd.ID_AV_ACD ' +
    'WHERE acd.ID_AC_ACD = :conj AND av.ID_VA_AV = :atr ' +
    'AND av.ESACTIVO_AV = ''S'' ORDER BY ORDEN_FINAL, av.AV';
  SQL_VALORES_ATRIBUTO_ACTIVOS =
    'SELECT ID_AV, AV, DESCRIPCION_AV, ORDEN_AV AS ORDEN_FINAL, ' +
    'ESACTIVO_AV FROM fza_atributos_valores ' +
    'WHERE ID_VA_AV = :atr AND ESACTIVO_AV = ''S'' ' +
    'ORDER BY ORDEN_FINAL, AV';
  SQL_VALORES_PROPIEDAD =
    'SELECT ID_PV_ARTPROP, PV FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = :prop AND ESACTIVO_PV = ''S'' ORDER BY PV';
  SQL_ATRIBUTOS_ARTICULO =
    'SELECT va.ID_ATB_VA, ' +
    'COALESCE(va.NOMBRE_VA, va.ID_ATB_VA) AS NOMBRE_ATR, ' +
    'va.ORDEN_VA, aca.ID_AC_ACA, ac.NOMBRE_AC ' +
    'FROM fza_articulos a JOIN fza_variaciones_atributos va ' +
    'ON va.ID_VAR_VA = a.TIPO_VARIACION_ART ' +
    'LEFT JOIN fza_articulos_conjuntos_asign aca ' +
    'ON aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    'AND aca.ID_VA_ACA = va.ID_ATB_VA ' +
    'LEFT JOIN fza_atributos_conjuntos ac ' +
    'ON ac.ID_AC = aca.ID_AC_ACA ' +
    'WHERE a.CODIGO_ART_ART = :art ' +
    'AND a.ESVARIACION_ART = ''S'' ' +
    'ORDER BY COALESCE(va.ORDEN_VA, 0), va.ID_ATB_VA';
  SQL_PROPIEDADES_ARTICULO =
    'SELECT p.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_PROP, ' +
    'p.TIPO_VALOR_PROP, ap.ID_PV_ARTPROP, ' +
    'ap.VALOR_LIBRE_ARTPROP, ' +
    'COALESCE(fa.ESREQUERIDO_FA, ''N'') AS ESREQUERIDO_FA, ' +
    'COALESCE(fa.ORDEN_MOSTRAR_FA, 999) AS ORDEN_MOSTRAR_FA ' +
    'FROM fza_articulos_propiedades ap JOIN fza_propiedades p ' +
    'ON p.CODIGO_PROP_ARTPROP = ap.CODIGO_PROP_ARTPROP ' +
    'LEFT JOIN fza_articulos art ' +
    'ON art.CODIGO_ART_ART = ap.CODIGO_ART_ART ' +
    'LEFT JOIN fza_familias_atributos fa ' +
    'ON fa.CODIGO_PROP_ARTPROP = ap.CODIGO_PROP_ARTPROP ' +
    'AND fa.CODIGO_FAM_FAM = art.CODIGO_FAM_ART ' +
    'WHERE ap.CODIGO_ART_ART = :art ' +
    'AND ap.CODIGO_UNIDAD_ARTPROP = '''' ' +
    'AND p.ESACTIVO_PROP = ''S'' ' +
    'ORDER BY ORDEN_MOSTRAR_FA, p.NOMBRE_PROP_PROP';
  SQL_ATRIBUTOS_SKU =
    'SELECT av.ID_AV, av.AV, av.DESCRIPCION_AV, av.ORDEN_AV, ' +
    'av.ESACTIVO_AV, va.ORDEN_VA FROM fza_atributos_sku sa ' +
    'JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    'LEFT JOIN fza_articulos_skus sk ' +
    'ON sk.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA ' +
    'LEFT JOIN fza_variaciones_atributos va ' +
    'ON va.ID_VAR_VA = sk.CODIGO_VAR_SKU ' +
    'AND va.ID_ATB_VA = av.ID_VA_AV ' +
    'WHERE sa.CODIGO_UNIDAD_SKU_SA = :sku ' +
    'ORDER BY va.ORDEN_VA, av.ORDEN_AV';
  SQL_AVS_EN_SKUS =
    'SELECT MIN(av.ID_AV) AS ID_AV, av.AV, ' +
    'MAX(av.DESCRIPCION_AV) AS DESCRIPCION_AV, ' +
    'MIN(COALESCE(aab.ORDEN_AAB, av.ORDEN_AV)) AS ORDEN_AV, ' +
    'MAX(av.ESACTIVO_AV) AS ESACTIVO_AV ' +
    'FROM fza_atributos_valores av ' +
    'JOIN vi_atributos_nombres N ON av.ID_VA_AV = N.ID_ATRIBUTO ' +
    'JOIN fza_atributos_sku REL ON av.ID_AV = REL.ID_AV_SA ' +
    'JOIN fza_articulos_skus S ' +
    'ON REL.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU ' +
    'AND S.CODIGO_ART_SKU = N.CODIGO_ART_PADRE_ARTVIN ' +
    'LEFT JOIN fza_articulos_atributos_basicos aab ' +
    'ON aab.CODIGO_ART_AAB = S.CODIGO_ART_SKU ' +
    'AND aab.ID_AV_AAB = av.ID_AV ' +
    'WHERE N.CODIGO_ART_PADRE_ARTVIN = :padre ' +
    'AND N.ORDEN_VISUAL_ATRIBUTO = :orden ' +
    'GROUP BY av.AV ORDER BY ORDEN_AV, av.AV';

function DefinicionSql(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioArticulosAtributos',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

constructor TRepositorioArticulosAtributos.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioArticulosAtributos.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 7);
  Result[0] := DefinicionSql(
    'ValoresAtributoConjunto',
    SQL_VALORES_ATRIBUTO_CONJUNTO,
    'conj,atr',
    'ID_AV,AV,DESCRIPCION_AV,ORDEN_FINAL,ESACTIVO_AV');
  Result[1] := DefinicionSql(
    'ValoresAtributoActivos',
    SQL_VALORES_ATRIBUTO_ACTIVOS,
    'atr',
    'ID_AV,AV,DESCRIPCION_AV,ORDEN_FINAL,ESACTIVO_AV');
  Result[2] := DefinicionSql(
    'ValoresPropiedad',
    SQL_VALORES_PROPIEDAD,
    'prop',
    'ID_PV_ARTPROP,PV');
  Result[3] := DefinicionSql(
    'ObtenerAtributos',
    SQL_ATRIBUTOS_ARTICULO,
    'art',
    'ID_ATB_VA,NOMBRE_ATR,ORDEN_VA,ID_AC_ACA,NOMBRE_AC');
  Result[4] := DefinicionSql(
    'ObtenerPropiedades',
    SQL_PROPIEDADES_ARTICULO,
    'art',
    'CODIGO_PROP_ARTPROP,NOMBRE_PROP_PROP,TIPO_VALOR_PROP,' +
    'ID_PV_ARTPROP,VALOR_LIBRE_ARTPROP,ESREQUERIDO_FA,' +
    'ORDEN_MOSTRAR_FA');
  Result[5] := DefinicionSql(
    'ObtenerAtributosDeSku',
    SQL_ATRIBUTOS_SKU,
    'sku',
    'ID_AV,AV,DESCRIPCION_AV,ORDEN_AV,ESACTIVO_AV,ORDEN_VA');
  Result[6] := DefinicionSql(
    'ObtenerAvsEnSkus',
    SQL_AVS_EN_SKUS,
    'padre,orden',
    'ID_AV,AV,DESCRIPCION_AV,ORDEN_AV,ESACTIVO_AV');
end;

function TRepositorioArticulosAtributos.TipoDesdeCadena(
  const s: string): TTipoValorPropiedad;
begin
  if      s = 'LISTA'    then Result := tvpLista
  else if s = 'NUMERO'   then Result := tvpNumero
  else if s = 'BOOLEANO' then Result := tvpBooleano
  else                        Result := tvpTextoLibre;
end;

procedure TRepositorioArticulosAtributos.CargarValoresAtributo(
  const AIdAtributo: string; const AIdConjunto: Integer;
  out AValores: TArray<TArticuloAtributoValor>);
var
  q: TUniQuery;
  Lst: TList<TArticuloAtributoValor>;
  V: TArticuloAtributoValor;
  oDefinicion: TDefinicionSql;
begin
  Lst := TList<TArticuloAtributoValor>.Create;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    if AIdConjunto > 0 then
      oDefinicion := DefinicionesSql[0]
    else
      oDefinicion := DefinicionesSql[1];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        q.Close;
        q.SQL.Text := ASql;
        if AIdConjunto > 0 then
          q.ParamByName('conj').AsInteger := AIdConjunto;
        q.ParamByName('atr').AsString := AIdAtributo;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    while not q.Eof do
    begin
      V := Default(TArticuloAtributoValor);
      V.IdValor     := q.FieldByName('ID_AV').AsInteger;
      V.Valor       := q.FieldByName('AV').AsString;
      V.Descripcion := q.FieldByName('DESCRIPCION_AV').AsString;
      V.Orden       := q.FieldByName('ORDEN_FINAL').AsInteger;
      V.EsActivo    := q.FieldByName('ESACTIVO_AV').AsString = 'S';
      Lst.Add(V);
      q.Next;
    end;
    AValores := Lst.ToArray;
  finally
    FreeAndNil(q);
    FreeAndNil(Lst);
  end;
end;

procedure TRepositorioArticulosAtributos.CargarValoresPropiedad(
  const ACodigoPropiedad: string;
  out AValores: TArray<TArticuloAtributoValor>);
var
  q: TUniQuery;
  Lst: TList<TArticuloAtributoValor>;
  V: TArticuloAtributoValor;
  oDefinicion: TDefinicionSql;
begin
  Lst := TList<TArticuloAtributoValor>.Create;
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
        q.ParamByName('prop').AsString := ACodigoPropiedad;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    while not q.Eof do
    begin
      V := Default(TArticuloAtributoValor);
      V.IdValor  := q.FieldByName('ID_PV_ARTPROP').AsInteger;
      V.Valor    := q.FieldByName('PV').AsString;
      V.EsActivo := True;
      Lst.Add(V);
      q.Next;
    end;
    AValores := Lst.ToArray;
  finally
    FreeAndNil(q);
    FreeAndNil(Lst);
  end;
end;

function TRepositorioArticulosAtributos.ObtenerAtributos(
  const ACodigoArticulo: string): TArray<TArticuloAtributo>;
var
  q: TUniQuery;
  Lst: TList<TArticuloAtributo>;
  A: TArticuloAtributo;
  i: Integer;
  oDefinicion: TDefinicionSql;
begin
  Result := nil;
  if ACodigoArticulo <> '' then
  begin
    Lst := TList<TArticuloAtributo>.Create;
    try
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
            q.ParamByName('art').AsString := ACodigoArticulo;
            q.Open;
            ValidarCamposResultadoSql(
              oDefinicion,
              q);
          end,
          FIncidenciasSql);
        while not q.Eof do
        begin
          A := Default(TArticuloAtributo);
          A.IdAtributo     := q.FieldByName('ID_ATB_VA').AsString;
          A.NombreAtributo := q.FieldByName('NOMBRE_ATR').AsString;
          A.OrdenAtributo  := q.FieldByName('ORDEN_VA').AsInteger;
          A.IdConjunto     := q.FieldByName('ID_AC_ACA').AsInteger;
          A.NombreConjunto := q.FieldByName('NOMBRE_AC').AsString;
          Lst.Add(A);
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;

      for i := 0 to Lst.Count - 1 do
      begin
        A := Lst[i];
        CargarValoresAtributo(A.IdAtributo, A.IdConjunto, A.Valores);
        Lst[i] := A;
      end;
      Result := Lst.ToArray;
    finally
      FreeAndNil(Lst);
    end;
  end;
end;

function TRepositorioArticulosAtributos.ObtenerPropiedades(
  const ACodigoArticulo: string): TArray<TArticuloPropiedad>;
var
  q: TUniQuery;
  Lst: TList<TArticuloPropiedad>;
  P: TArticuloPropiedad;
  i: Integer;
  oDefinicion: TDefinicionSql;
begin
  Result := nil;
  if ACodigoArticulo <> '' then
  begin
    Lst := TList<TArticuloPropiedad>.Create;
    try
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
            q.ParamByName('art').AsString := ACodigoArticulo;
            q.Open;
            ValidarCamposResultadoSql(
              oDefinicion,
              q);
          end,
          FIncidenciasSql);
        while not q.Eof do
        begin
          P := Default(TArticuloPropiedad);
          P.Codigo := q.FieldByName('CODIGO_PROP_ARTPROP').AsString;
          P.Nombre := q.FieldByName('NOMBRE_PROP_PROP').AsString;
          P.TipoValor := TipoDesdeCadena(
            q.FieldByName('TIPO_VALOR_PROP').AsString);
          P.EsRequerido :=
            q.FieldByName('ESREQUERIDO_FA').AsString = 'S';
          P.Orden := q.FieldByName('ORDEN_MOSTRAR_FA').AsInteger;
          P.IdValorAsignado :=
            q.FieldByName('ID_PV_ARTPROP').AsInteger;
          P.ValorLibreAsignado :=
            q.FieldByName('VALOR_LIBRE_ARTPROP').AsString;
          Lst.Add(P);
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;

      for i := 0 to Lst.Count - 1 do
      begin
        P := Lst[i];
        if P.TipoValor = tvpLista then
          CargarValoresPropiedad(P.Codigo, P.Valores);
        Lst[i] := P;
      end;
      Result := Lst.ToArray;
    finally
      FreeAndNil(Lst);
    end;
  end;
end;

function TRepositorioArticulosAtributos.ObtenerAtributosDeSku(
  const ACodigoSku: string): TArray<TArticuloAtributoValor>;
var
  q: TUniQuery;
  Lst: TList<TArticuloAtributoValor>;
  V: TArticuloAtributoValor;
  oDefinicion: TDefinicionSql;
begin
  Result := nil;
  if ACodigoSku <> '' then
  begin
  Lst := TList<TArticuloAtributoValor>.Create;
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
        q.ParamByName('sku').AsString := ACodigoSku;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    while not q.Eof do
    begin
      V := Default(TArticuloAtributoValor);
      V.IdValor     := q.FieldByName('ID_AV').AsInteger;
      V.Valor       := q.FieldByName('AV').AsString;
      V.Descripcion := q.FieldByName('DESCRIPCION_AV').AsString;
      V.Orden       := q.FieldByName('ORDEN_VA').AsInteger;
      V.EsActivo    := q.FieldByName('ESACTIVO_AV').AsString = 'S';
      Lst.Add(V);
      q.Next;
    end;
    Result := Lst.ToArray;
  finally
    FreeAndNil(q);
    FreeAndNil(Lst);
  end;
  end;
end;

function TRepositorioArticulosAtributos.ObtenerAvsEnSkus(
  const ACodigoArticulo: string; AOrdenAtributo: Integer)
  : TArray<TArticuloAtributoValor>;
var
  q: TUniQuery;
  Lst: TList<TArticuloAtributoValor>;
  V: TArticuloAtributoValor;
  oDefinicion: TDefinicionSql;
begin
  // GROUP BY av.AV (no DISTINCT por ID_AV) para deduplicar nombres
  // repetidos en fza_atributos_valores. Caso real: dos AV distintos con
  // 'NEGRO' como nombre — DISTINCT los conserva como filas separadas
  // (IDs distintos), y el dropdown sale con 'NEGRO' por duplicado.
  // Mismo patron que usa inMtoModalGenerarSKUs.
  //   - MIN(ID_AV)   : ID canonico (el mas antiguo, normalmente el real).
  //   - MIN(ORDEN_AAB): orden propio del articulo migrado de ocarttal.Orden.
  //   - ORDEN_AV: fallback para datos no legacy o filas antiguas sin orden.
  // ORDER BY ORDEN_AV conserva, por ejemplo, S,M,L,XL aunque el orden global
  // de esos mismos nombres sea distinto en otros sistemas de tallas.
  Lst := TList<TArticuloAtributoValor>.Create;
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
        q.ParamByName('padre').AsString := ACodigoArticulo;
        q.ParamByName('orden').AsInteger := AOrdenAtributo;
        q.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          q);
      end,
      FIncidenciasSql);
    while not q.Eof do
    begin
      V := Default(TArticuloAtributoValor);
      V.IdValor     := q.FieldByName('ID_AV').AsInteger;
      V.Valor       := q.FieldByName('AV').AsString;
      V.Descripcion := q.FieldByName('DESCRIPCION_AV').AsString;
      V.Orden       := q.FieldByName('ORDEN_AV').AsInteger;
      V.EsActivo    := q.FieldByName('ESACTIVO_AV').AsString = 'S';
      Lst.Add(V);
      q.Next;
    end;
    Result := Lst.ToArray;
  finally
    FreeAndNil(q);
    FreeAndNil(Lst);
  end;
end;

end.
