{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataGeneracionSkusRepositorio                             }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para configurar atributos y generar SKU.              }
{******************************************************************************}
unit UniDataGeneracionSkusRepositorio;

interface

uses
  Uni, inLibGeneracionSkusPersistenciaIntf;

function CrearRepositorioGeneracionSkusUniDAC(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;

implementation

uses
  System.SysUtils, Data.DB,
  inLibCodigosSinBarra, UniDataAtributosSkuEnlace,
  inLibPrestaShopColaSenal,
  UniDataPrestaShopEncolado;

const
  SQL_MAESTRO =
    'SELECT aca.CODIGO_ART_ACA, aca.ID_VA_ACA AS ID_ATB_VA, ' +
    'va.ID_VAR_VA, COALESCE(va.NOMBRE_VA, aca.ID_VA_ACA) ' +
    'AS NOMBRE_ATRIBUTO, va.ORDEN_VA, aca.ORDEN_ACA ' +
    'FROM fza_articulos_conjuntos_asign aca ' +
    'JOIN fza_variaciones_atributos va ' +
    'ON va.ID_ATB_VA = aca.ID_VA_ACA AND va.ID_VAR_VA = :var ' +
    'WHERE aca.CODIGO_ART_ACA = :art ' +
    'ORDER BY aca.ORDEN_ACA, va.ORDEN_VA';
  // Valores de cada dimensión: los del conjunto asignado al artículo más
  // los que ya usa algún SKU suyo, sin repetir nombre.
  //   - ID_AC: si el nombre tiene varios ID, manda el que ya usan los SKU
  //     del artículo para que los SKU nuevos no mezclen dos ID del mismo
  //     color o talla.
  //   - ORDEN_AV: el orden del conjunto prevalece sobre el global; antes
  //     ganaba el global (MIN) y las tallas de un conjunto salían todas a 0.
  SQL_DETALLE =
    'SELECT ID_ATB_VA, ' +
    'COALESCE(MIN(CASE WHEN EN_SKU = 1 THEN ID_AC END), MAX(ID_AC)) ' +
    'AS ID_AC, NOMBRE_AC, ' +
    'COALESCE(MIN(ORDEN_CONJUNTO), MIN(ORDEN_GLOBAL)) AS ORDEN_AV, ' +
    '0 AS ASIGNADO FROM (' +
    'SELECT atr.ID_ATB_VA, val.ID_AV AS ID_AC, val.AV AS NOMBRE_AC, ' +
    'det.ORDEN_ACD AS ORDEN_CONJUNTO, val.ORDEN_AV AS ORDEN_GLOBAL, ' +
    '0 AS EN_SKU ' +
    'FROM fza_variaciones_atributos atr ' +
    'JOIN fza_articulos_conjuntos_asign asign ' +
    'ON asign.ID_VA_ACA = atr.ID_ATB_VA ' +
    'AND asign.CODIGO_ART_ACA = :Articulo ' +
    'JOIN fza_atributos_conjuntos_det det ' +
    'ON det.ID_AC_ACD = asign.ID_AC_ACA ' +
    'JOIN fza_atributos_valores val ON val.ID_AV = det.ID_AV_ACD ' +
    'WHERE atr.ID_VAR_VA = :Variacion UNION ' +
    'SELECT atr.ID_ATB_VA, val.ID_AV AS ID_AC, val.AV AS NOMBRE_AC, ' +
    'det.ORDEN_ACD AS ORDEN_CONJUNTO, val.ORDEN_AV AS ORDEN_GLOBAL, ' +
    '1 AS EN_SKU ' +
    'FROM fza_variaciones_atributos atr ' +
    'JOIN fza_atributos_valores val ON val.ID_VA_AV = atr.ID_ATB_VA ' +
    'JOIN fza_atributos_sku asku ON asku.ID_AV_SA = val.ID_AV ' +
    'JOIN fza_articulos_skus skus ' +
    'ON skus.CODIGO_UNIDAD_SKU = asku.CODIGO_UNIDAD_SKU_SA ' +
    'AND skus.CODIGO_ART_SKU = :Articulo ' +
    'LEFT JOIN fza_articulos_conjuntos_asign asign ' +
    'ON asign.CODIGO_ART_ACA = skus.CODIGO_ART_SKU ' +
    'AND asign.ID_VA_ACA = atr.ID_ATB_VA ' +
    'LEFT JOIN fza_atributos_conjuntos_det det ' +
    'ON det.ID_AC_ACD = asign.ID_AC_ACA AND det.ID_AV_ACD = val.ID_AV ' +
    'WHERE atr.ID_VAR_VA = :Variacion) AS combinados ' +
    'GROUP BY ID_ATB_VA, NOMBRE_AC ORDER BY ORDEN_AV, NOMBRE_AC';
  SQL_ASEGURAR_FILAS =
    'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
    '(CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
    'ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) ' +
    'SELECT :art, 0, va.ID_ATB_VA, va.ORDEN_VA, ''S'', ' +
    'CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'' ' +
    'FROM fza_variaciones_atributos va WHERE va.ID_VAR_VA = :var';
  SQL_NORMALIZAR_ORDEN_FILAS =
    'UPDATE fza_articulos_conjuntos_asign aca ' +
    'JOIN fza_variaciones_atributos va ' +
    'ON va.ID_ATB_VA = aca.ID_VA_ACA AND va.ID_VAR_VA = :var ' +
    'SET aca.ORDEN_ACA = va.ORDEN_VA ' +
    'WHERE aca.CODIGO_ART_ACA = :art AND aca.ORDEN_ACA = 0';
  SQL_OBTENER_CONJUNTO =
    'SELECT aca.ID_AC_ACA, ac.NOMBRE_AC ' +
    'FROM fza_articulos_conjuntos_asign aca ' +
    'LEFT JOIN fza_atributos_conjuntos ac ON ac.ID_AC = aca.ID_AC_ACA ' +
    'WHERE aca.CODIGO_ART_ACA = :Articulo ' +
    'AND aca.ID_VA_ACA = :Atributo';
  // FZ-ISSUE-449: la coleccion depende solo de su atributo; ya no tiene
  // tipo de variacion (ID_VAR_AC queda sin uso).
  SQL_LISTAR_CONJUNTOS =
    'SELECT ID_AC, NOMBRE_AC FROM fza_atributos_conjuntos ' +
    'WHERE ID_VA_AC = :Atributo AND ESACTIVO_AC = ''S'' ' +
    'ORDER BY NOMBRE_AC';
  // La fila existe siempre: PrepararDatos la asegura con ID_AC_ACA = 0.
  SQL_ASIGNAR_CONJUNTO =
    'UPDATE fza_articulos_conjuntos_asign ' +
    'SET ID_AC_ACA = :Conj, USUARIO_MODIF = ''SISTEMA'' ' +
    'WHERE CODIGO_ART_ACA = :Articulo AND ID_VA_ACA = :Atributo';
  SQL_VALORES_CONJUNTO =
    'SELECT val.ID_AV, val.AV, ' +
    'COALESCE(det.ORDEN_ACD, val.ORDEN_AV) AS ORDEN ' +
    'FROM fza_atributos_conjuntos_det det ' +
    'JOIN fza_atributos_valores val ON val.ID_AV = det.ID_AV_ACD ' +
    'WHERE det.ID_AC_ACD = :Conj ORDER BY ORDEN, val.AV';
  SQL_SIGUIENTE_ORDEN_CONJUNTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_ACD), 0) / 10) + 1) * 10 ' +
    'AS SIGUIENTE_ORDEN FROM fza_atributos_conjuntos_det ' +
    'WHERE ID_AC_ACD = :IdConjunto';
  SQL_SIGUIENTE_ORDEN_ATRIBUTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_AV), 0) / 10) + 1) * 10 ' +
    'AS SIGUIENTE_ORDEN FROM fza_atributos_valores ' +
    'WHERE ID_VA_AV = :IdAtributo';
  // Con nombres repetidos manda el ID más antiguo, que es el canónico.
  SQL_BUSCAR_VALOR =
    'SELECT ID_AV, AV FROM fza_atributos_valores ' +
    'WHERE ID_VA_AV = :IdVa AND UPPER(TRIM(AV)) = UPPER(TRIM(:Valor)) ' +
    'ORDER BY ID_AV';
  SQL_CODIGOS_SKU =
    'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
    'WHERE CODIGO_ART_SKU = :Articulo ORDER BY CODIGO_UNIDAD_SKU';
  SQL_GUARDAR_VALOR_CONJUNTO =
    'INSERT IGNORE INTO fza_atributos_conjuntos_det (ID_AC_ACD, ' +
    'ID_AV_ACD, ORDEN_ACD, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:Conj, :Val, :Orden, CURRENT_TIMESTAMP, ' +
    '''SISTEMA'', ''SISTEMA'')';
  SQL_GUARDAR_SKU =
    'INSERT IGNORE INTO fza_articulos_skus ' +
    '(CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
    'ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :art, :var, ''S'', CURRENT_TIMESTAMP, ' +
    '''SISTEMA'', ''SISTEMA'')';
  SQL_GUARDAR_ATRIBUTO_SKU =
    'INSERT IGNORE INTO fza_atributos_sku ' +
    '(CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:cod, :val, CURRENT_TIMESTAMP, ' +
    '''SISTEMA'', ''SISTEMA'')';
  SQL_GUARDAR_ORDEN_ATRIBUTO =
    'INSERT INTO fza_articulos_conjuntos_asign ' +
    '(CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
    'ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:art, 0, :atr, :ord, ''S'', ' +
    'CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'') ' +
    'ON DUPLICATE KEY UPDATE ORDEN_ACA = VALUES(ORDEN_ACA), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_GUARDAR_ORDEN_VALOR =
    'UPDATE fza_atributos_valores SET ORDEN_AV = :orden ' +
    'WHERE ID_AV = :id';
  SQL_GUARDAR_ORDEN_VALOR_CONJUNTO =
    'UPDATE fza_atributos_conjuntos_det SET ORDEN_ACD = :orden ' +
    'WHERE ID_AV_ACD = :id';

type
  TDatosGeneracionSkusUniDAC = class(
    TInterfacedObject,
    IDatosGeneracionSkus)
  private
    FConexion: TUniConnection;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    FMaestro: TUniQuery;
    FDetalle: TUniQuery;
    FOrigenMaestro: TDataSource;
    procedure Abrir;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACodigoArticulo: string;
      const ATipoVariacion: string);
    destructor Destroy; override;
    function Maestro: TDataSet;
    function Detalle: TDataSet;
    procedure RecargarMaestro;
  end;

  TRepositorioGeneracionSkusUniDAC = class(
    TInterfacedObject,
    IRepositorioGeneracionSkus)
  private
    FConexion: TUniConnection;
    procedure AsegurarFilas(
      const ACodigoArticulo: string;
      const ATipoVariacion: string);
    function InsertarSku(
      const ACodigoSku, ACodigoArticulo, ATipoVariacion: string): Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function PrepararDatos(
      const ACodigoArticulo: string;
      const ATipoVariacion: string
    ): IDatosGeneracionSkus;
    function ObtenerConjuntoAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string
    ): TConjuntoAtributoSku;
    function ListarConjuntosAtributo(
      const AIdAtributo: string;
      const ATipoVariacion: string): TArray<TConjuntoAtributoSku>;
    procedure AsignarConjuntoArticulo(
      const ACodigoArticulo, AIdAtributo: string;
      AIdConjunto: Integer);
    function ListarValoresConjunto(
      AIdConjunto: Integer): TArray<TValorConjuntoSku>;
    function CalcularSiguienteOrdenValor(
      const AIdAtributo: string;
      AIdConjunto: Integer
    ): Integer;
    function BuscarValor(
      const AIdAtributo, ANombre: string): TValorAtributoSku;
    function AsegurarValor(
      const AIdAtributo, ANombre: string;
      AOrden: Integer): TValorAtributoSku;
    procedure GuardarValorEnConjunto(
      AIdConjunto: Integer;
      AIdValor: Integer;
      AOrden: Integer);
    function ObtenerCodigosSku(
      const ACodigoArticulo: string): TArray<string>;
    function GuardarSku(
      const ACodigoSku, ACodigoArticulo, ATipoVariacion: string;
      const AIdsValores: TArray<Integer>): Boolean;
    procedure GuardarOrdenAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string;
      AOrden: Integer);
    procedure GuardarOrdenValor(
      AIdValor: Integer;
      AOrden: Integer);
  end;

constructor TDatosGeneracionSkusUniDAC.Create(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  const ATipoVariacion: string);
begin
  inherited Create;
  FConexion := AConexion;
  FCodigoArticulo := ACodigoArticulo;
  FTipoVariacion := ATipoVariacion;
  FMaestro := TUniQuery.Create(nil);
  FMaestro.Connection := FConexion;
  FMaestro.SQL.Text := SQL_MAESTRO;
  FOrigenMaestro := TDataSource.Create(nil);
  FOrigenMaestro.DataSet := FMaestro;
  FDetalle := TUniQuery.Create(nil);
  FDetalle.Connection := FConexion;
  FDetalle.SQL.Text := SQL_DETALLE;
  FDetalle.Options.LocalMasterDetail := True;
  FDetalle.CachedUpdates := True;
  FDetalle.MasterSource := FOrigenMaestro;
  FDetalle.MasterFields := 'ID_ATB_VA';
  // Sin DetailFields UniDAC enlaza por parámetros del SQL y aquí no hay
  // ninguno con nombre de campo del maestro: el detalle salía sin filtrar,
  // con tallas y colores mezclados bajo cualquier dimensión.
  FDetalle.DetailFields := 'ID_ATB_VA';
  Abrir;
end;

destructor TDatosGeneracionSkusUniDAC.Destroy;
begin
  FreeAndNil(FDetalle);
  FreeAndNil(FOrigenMaestro);
  FreeAndNil(FMaestro);
  inherited;
end;

function TDatosGeneracionSkusUniDAC.Maestro: TDataSet;
begin
  Result := FMaestro;
end;

function TDatosGeneracionSkusUniDAC.Detalle: TDataSet;
begin
  Result := FDetalle;
end;

procedure TDatosGeneracionSkusUniDAC.RecargarMaestro;
begin
  // Solo el maestro. El detalle guarda en memoria las casillas marcadas y
  // los valores añadidos para esta vez: reabrirlo los perdería.
  FMaestro.Refresh;
end;

procedure TDatosGeneracionSkusUniDAC.Abrir;
begin
  FMaestro.ParamByName('var').AsString := FTipoVariacion;
  FMaestro.ParamByName('art').AsString := FCodigoArticulo;
  FMaestro.Open;
  FDetalle.ParamByName('Articulo').AsString := FCodigoArticulo;
  FDetalle.ParamByName('Variacion').AsString := FTipoVariacion;
  FDetalle.Open;
  FDetalle.FieldByName('ASIGNADO').ReadOnly := False;
  FDetalle.FieldByName('ID_ATB_VA').ReadOnly := False;
  FDetalle.FieldByName('ID_AC').ReadOnly := False;
  FDetalle.FieldByName('NOMBRE_AC').ReadOnly := False;
  FDetalle.FieldByName('ORDEN_AV').ReadOnly := False;
end;

constructor TRepositorioGeneracionSkusUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioGeneracionSkusUniDAC.AsegurarFilas(
  const ACodigoArticulo: string;
  const ATipoVariacion: string);
begin
  FConexion.ExecSQL(
    SQL_ASEGURAR_FILAS,
    [ACodigoArticulo, ATipoVariacion]);
  FConexion.ExecSQL(
    SQL_NORMALIZAR_ORDEN_FILAS,
    [ATipoVariacion, ACodigoArticulo]);
end;

function TRepositorioGeneracionSkusUniDAC.PrepararDatos(
  const ACodigoArticulo: string;
  const ATipoVariacion: string): IDatosGeneracionSkus;
begin
  AsegurarFilas(ACodigoArticulo, ATipoVariacion);
  Result := TDatosGeneracionSkusUniDAC.Create(
    FConexion,
    ACodigoArticulo,
    ATipoVariacion);
end;

function TRepositorioGeneracionSkusUniDAC.ObtenerConjuntoAtributo(
  const ACodigoArticulo: string;
  const AIdAtributo: string): TConjuntoAtributoSku;
var
  oConsulta: TUniQuery;
begin
  Result.Id := 0;
  Result.Nombre := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_OBTENER_CONJUNTO;
    oConsulta.ParamByName('Articulo').AsString := ACodigoArticulo;
    oConsulta.ParamByName('Atributo').AsString := AIdAtributo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Id := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
      Result.Nombre := oConsulta.FieldByName('NOMBRE_AC').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.ListarConjuntosAtributo(
  const AIdAtributo: string;
  const ATipoVariacion: string): TArray<TConjuntoAtributoSku>;
var
  oConsulta: TUniQuery;
  oConjunto: TConjuntoAtributoSku;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // ATipoVariacion ya no filtra (FZ-ISSUE-449).
    oConsulta.SQL.Text := SQL_LISTAR_CONJUNTOS;
    oConsulta.ParamByName('Atributo').AsString := AIdAtributo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oConjunto.Id := oConsulta.FieldByName('ID_AC').AsInteger;
      oConjunto.Nombre := oConsulta.FieldByName('NOMBRE_AC').AsString;
      Result := Result + [oConjunto];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioGeneracionSkusUniDAC.AsignarConjuntoArticulo(
  const ACodigoArticulo, AIdAtributo: string;
  AIdConjunto: Integer);
begin
  FConexion.ExecSQL(
    SQL_ASIGNAR_CONJUNTO,
    [AIdConjunto, ACodigoArticulo, AIdAtributo]);
end;

function TRepositorioGeneracionSkusUniDAC.ListarValoresConjunto(
  AIdConjunto: Integer): TArray<TValorConjuntoSku>;
var
  oConsulta: TUniQuery;
  oValor: TValorConjuntoSku;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_VALORES_CONJUNTO;
    oConsulta.ParamByName('Conj').AsInteger := AIdConjunto;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oValor.Id := oConsulta.FieldByName('ID_AV').AsInteger;
      oValor.Nombre := oConsulta.FieldByName('AV').AsString;
      oValor.Orden := oConsulta.FieldByName('ORDEN').AsInteger;
      Result := Result + [oValor];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.CalcularSiguienteOrdenValor(
  const AIdAtributo: string;
  AIdConjunto: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 10;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if AIdConjunto > 0 then
    begin
      oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_CONJUNTO;
      oConsulta.ParamByName('IdConjunto').AsInteger := AIdConjunto;
    end
    else
    begin
      oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_ATRIBUTO;
      oConsulta.ParamByName('IdAtributo').AsString := AIdAtributo;
    end;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('SIGUIENTE_ORDEN').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.BuscarValor(
  const AIdAtributo, ANombre: string): TValorAtributoSku;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TValorAtributoSku);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSCAR_VALOR;
    oConsulta.ParamByName('IdVa').AsString := AIdAtributo;
    oConsulta.ParamByName('Valor').AsString := SinBarraSku(ANombre);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Id := oConsulta.FieldByName('ID_AV').AsInteger;
      Result.Nombre := oConsulta.FieldByName('AV').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.AsegurarValor(
  const AIdAtributo, ANombre: string;
  AOrden: Integer): TValorAtributoSku;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TValorAtributoSku);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    Result.Id := AsegurarValorAtributoNormalizado(oConsulta,
      AIdAtributo, ANombre, '', 'SISTEMA', AOrden, 0);
    oConsulta.SQL.Text :=
      'SELECT AV FROM fza_atributos_valores WHERE ID_AV = :ID';
    oConsulta.ParamByName('ID').AsInteger := Result.Id;
    oConsulta.Open;
    Result.Nombre := oConsulta.FieldByName('AV').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarValorEnConjunto(
  AIdConjunto: Integer;
  AIdValor: Integer;
  AOrden: Integer);
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_VALOR_CONJUNTO,
    [AIdConjunto, AIdValor, AOrden]);
end;

function TRepositorioGeneracionSkusUniDAC.ObtenerCodigosSku(
  const ACodigoArticulo: string): TArray<string>;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CODIGOS_SKU;
    oConsulta.ParamByName('Articulo').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result +
        [oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.InsertarSku(
  const ACodigoSku, ACodigoArticulo, ATipoVariacion: string): Boolean;
var
  oAlta: TUniQuery;
begin
  oAlta := TUniQuery.Create(nil);
  try
    oAlta.Connection := FConexion;
    oAlta.SQL.Text := SQL_GUARDAR_SKU;
    oAlta.ParamByName('cod').AsString := ACodigoSku;
    oAlta.ParamByName('art').AsString := ACodigoArticulo;
    oAlta.ParamByName('var').AsString := ATipoVariacion;
    oAlta.Execute;
    Result := oAlta.RowsAffected > 0;
  finally
    FreeAndNil(oAlta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.GuardarSku(
  const ACodigoSku, ACodigoArticulo, ATipoVariacion: string;
  const AIdsValores: TArray<Integer>): Boolean;
var
  iIdValor: Integer;
  bTransaccionPropia: Boolean;
begin
  // El SKU se crea entero (fila, atributos y aviso a la tienda) o no se
  // crea: uno a medias quedaría sin color ni talla y, al existir ya, un
  // reintento lo daría por bueno. Si el SKU ya existía no se le añaden
  // atributos: podría acabar con dos colores o dos tallas.
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := InsertarSku(ACodigoSku, ACodigoArticulo, ATipoVariacion);
    if Result then
    begin
      for iIdValor in AIdsValores do
        FConexion.ExecSQL(
          SQL_GUARDAR_ATRIBUTO_SKU,
          [ACodigoSku, iIdValor]);
      EncolarArticuloPrestaShop(
        FConexion,
        ACodigoArticulo,
        'SISTEMA');
    end;
    if bTransaccionPropia then
      FConexion.Commit;
  except
    if bTransaccionPropia then
      FConexion.Rollback;
    raise;
  end;
  // La cola solo avisa por sí misma fuera de transacción.
  if Result and bTransaccionPropia then
    SolicitarProcesadoPrestaShop;
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarOrdenAtributo(
  const ACodigoArticulo: string;
  const AIdAtributo: string;
  AOrden: Integer);
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_ORDEN_ATRIBUTO,
    [ACodigoArticulo, AIdAtributo, AOrden]);
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarOrdenValor(
  AIdValor: Integer;
  AOrden: Integer);
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_ORDEN_VALOR,
    [AOrden, AIdValor]);
  FConexion.ExecSQL(
    SQL_GUARDAR_ORDEN_VALOR_CONJUNTO,
    [AOrden, AIdValor]);
end;

function CrearRepositorioGeneracionSkusUniDAC(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;
begin
  Result := TRepositorioGeneracionSkusUniDAC.Create(AConexion);
end;

end.
