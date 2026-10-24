{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataBusquedaDatosRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de la busqueda avanzada de articulos y SKU.           }
{******************************************************************************}
unit UniDataBusquedaDatosRepositorio;

interface

uses
  Uni, inLibBusquedaDatosPersistenciaIntf, inLibFamiliasArbol;

function CrearRepositorioBusquedaDatosUniDAC(
  AConexion: TUniConnection): IRepositorioBusquedaDatos;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_LISTAR_FAMILIAS =
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    'COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, ' +
    'CODIGO_FAM_FAM) AS NOM, ' +
    'COALESCE(CODIGO_PADRE_FAM, '''') AS PADRE ' +
    'FROM fza_articulos_familias ' +
    'WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    'ORDER BY ORDEN_FAM, CODIGO_FAM_FAM';
  SQL_LISTAR_PROVEEDORES =
    'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV ' +
    'FROM fza_proveedores ' +
    'WHERE IFNULL(ESACTIVO_PRV, ''S'') = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV';
  SQL_LISTAR_TEMPORADAS =
    'SELECT PV AS COD, PV AS NOM ' +
    'FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    'AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    'ORDER BY PV';
  SQL_LISTAR_COLORES_PALETA =
    'SELECT NOMBRE_ATB FROM fza_atributos_basicos ' +
    'WHERE ID_VA_ATB = ''CO'' AND ESACTIVO_ATB = ''S'' ' +
    'AND HEX_ATB REGEXP ''^#?[0-9A-Fa-f]{6}$'' ' +
    'ORDER BY ORDEN_ATB, CODIGO_ATB';
  SQL_BUSCAR_HEX_COLOR =
    'SELECT HEX_ATB FROM fza_atributos_basicos ' +
    'WHERE ID_VA_ATB = ''CO'' AND ESACTIVO_ATB = ''S'' ' +
    'AND HEX_ATB IS NOT NULL ' +
    'AND (UPPER(CODIGO_ATB) = :VALOR ' +
    'OR UPPER(REPLACE(CODIGO_ATB, ''_'', '' '')) = :VALOR ' +
    'OR UPPER(NOMBRE_ATB) = :VALOR ' +
    'OR UPPER(DESCRIPCION_ATB) = :VALOR) ' +
    'ORDER BY ORDEN_ATB, CODIGO_ATB LIMIT 1';
  SQL_BUSQUEDA_ANTES_DISTANCIA =
    'SELECT eti.CODIGO_ART_ART, eti.CODIGO_UNIDAD_SKU, ' +
    'eti.DESCRIPCION_ART, eti.ATR_CO, ' +
    'pal.CODIGO_ATB AS CODIGO_COLOR_BASICO, ' +
    'pal.NOMBRE_ATB AS COLOR_BASICO, ' +
    'pal.HEX_ATB AS HEX_COLOR_BASICO, ';
  SQL_BUSQUEDA_DESPUES_DISTANCIA =
    ', eti.ATR_TAL, ' +
    'COALESCE(stk.CANTIDAD_STOCK, 0) AS CANTIDAD_STOCK, ' +
    'COALESCE(stk.CANTIDAD_STOCK_ALMACEN, 0) ' +
    'AS CANTIDAD_STOCK_ALMACEN, stk.ALMACENES_STOCK, ' +
    'eti.CODIGO_BARRAS_CB, eti.CODIGO_FAM_ART, ' +
    'eti.NOMBRE_FAM_FAM, eti.CODIGO_PRV_PRV, ' +
    'eti.RAZON_SOCIAL_PRV, eti.REF_PROVEEDOR, ' +
    'eti.PROP_TEMPORADA, eti.PROP_MARCA, eti.PROP_MATERIAL, ' +
    'eti.PROP_GENERO, eti.ATRIBUTOS_TXT, eti.PROPIEDADES_TXT, ' +
    'eti.ESACTIVO_ART, eti.ESACTIVO_SKU ' +
    'FROM vi_articulos_skus_etiquetas eti ' +
    'LEFT JOIN (SELECT sa.CODIGO_UNIDAD_SKU_SA ' +
    'AS CODIGO_UNIDAD_SKU, atb.CODIGO_ATB, atb.NOMBRE_ATB, ' +
    'atb.DESCRIPCION_ATB, atb.HEX_ATB ' +
    'FROM fza_atributos_sku sa ' +
    'JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    'AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 WHERE ' +
    'SK452.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA) AND ' +
    'EJ452.EJE_VA = ''F'') ' +
    'JOIN fza_articulos_skus sku ' +
    'ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA ' +
    'LEFT JOIN fza_articulos_atributos_basicos aab ' +
    'ON aab.CODIGO_ART_AAB = sku.CODIGO_ART_SKU ' +
    'AND aab.ID_AV_AAB = av.ID_AV ' +
    'LEFT JOIN fza_articulos_conjuntos_asign aca ' +
    'ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU ' +
    'AND aca.ID_VA_ACA = av.ID_VA_AV ' +
    'LEFT JOIN fza_atributos_conjuntos_det acd ' +
    'ON acd.ID_AC_ACD = aca.ID_AC_ACA ' +
    'AND acd.ID_AV_ACD = av.ID_AV ' +
    'LEFT JOIN fza_atributos_basicos atb ON atb.ID_ATB = CASE ' +
    'WHEN aab.CODIGO_ART_AAB IS NOT NULL THEN aab.ID_ATB_AAB ' +
    'WHEN acd.ID_ATB_ACD IS NOT NULL THEN acd.ID_ATB_ACD ' +
    'ELSE av.ID_ATB_AV END) pal ' +
    'ON pal.CODIGO_UNIDAD_SKU = eti.CODIGO_UNIDAD_SKU ' +
    'LEFT JOIN (SELECT CODIGO_UNIDAD_STK, ' +
    'SUM(CANTIDAD_STK) AS CANTIDAD_STOCK, ' +
    'SUM(CASE WHEN CODIGO_ALM_STK = :ALMACEN_DOC ' +
    'THEN CANTIDAD_STK ELSE 0 END) AS CANTIDAD_STOCK_ALMACEN, ' +
    'GROUP_CONCAT(DISTINCT CODIGO_ALM_STK ' +
    'ORDER BY CODIGO_ALM_STK SEPARATOR '', '') AS ALMACENES_STOCK ' +
    'FROM fza_articulos_stockactual ' +
    'GROUP BY CODIGO_UNIDAD_STK) stk ' +
    'ON stk.CODIGO_UNIDAD_STK = eti.CODIGO_UNIDAD_SKU ' +
    'WHERE 1 = 1';

type
  TResultadoBusquedaDatosUniDAC = class(
    TInterfacedObject,
    IResultadoBusquedaDatos)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioBusquedaDatosUniDAC = class(
    TInterfacedObject,
    IRepositorioBusquedaDatos)
  private
    FConexion: TUniConnection;
    function ListarOpciones(
      const ASql: string): TOpcionesBusquedaDatos;
    function NombreParametroFamilia(AIndice: Integer): string;
    function ExpresionCampo(ACampo: Integer): string;
    function ConstruirDistanciaColor: string;
    procedure PrepararConsultaBase(
      AConsulta: TUniQuery;
      AProximidad: Boolean);
    procedure AplicarFiltrosDisponibilidad(
      AConsulta: TUniQuery;
      const ACriterios: TCriteriosBusquedaDatos);
    procedure AplicarFiltrosCatalogo(
      AConsulta: TUniQuery;
      const ACriterios: TCriteriosBusquedaDatos);
    procedure AplicarFiltroValor(
      AConsulta: TUniQuery;
      const ACriterios: TCriteriosBusquedaDatos;
      AProximidad: Boolean;
      var AValor: string;
      out AParametro: string);
    procedure AplicarOrdenYLimite(
      AConsulta: TUniQuery;
      AProximidad: Boolean;
      ALimite: Integer);
    procedure AsignarParametrosBusqueda(
      AConsulta: TUniQuery;
      const ACriterios: TCriteriosBusquedaDatos;
      AProximidad: Boolean;
      const AValor, AParametro: string);
  public
    constructor Create(AConexion: TUniConnection);
    function ListarFamiliasArbol: TFamiliasArbol;
    function ConsultarProveedores: IResultadoBusquedaDatos;
    function ListarTemporadas: TOpcionesBusquedaDatos;
    function ListarColoresPaleta: TCadenasBusquedaDatos;
    function BuscarHexColor(
      const AValor: string): string;
    function PrepararBusqueda(
      const ACriterios: TCriteriosBusquedaDatos
    ): IResultadoBusquedaDatos;
  end;

constructor TResultadoBusquedaDatosUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoBusquedaDatosUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoBusquedaDatosUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioBusquedaDatosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioBusquedaDatosUniDAC.ListarOpciones(
  const ASql: string): TOpcionesBusquedaDatos;
var
  iOpcion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iOpcion := Length(Result);
      SetLength(Result, iOpcion + 1);
      Result[iOpcion].Codigo := oConsulta.FieldByName('COD').AsString;
      Result[iOpcion].Nombre := oConsulta.FieldByName('NOM').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioBusquedaDatosUniDAC.ListarFamiliasArbol:
  TFamiliasArbol;
var
  iFamilia: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_FAMILIAS;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFamilia := Length(Result);
      SetLength(Result, iFamilia + 1);
      Result[iFamilia].Codigo :=
        oConsulta.FieldByName('COD').AsString;
      Result[iFamilia].Nombre :=
        oConsulta.FieldByName('NOM').AsString;
      Result[iFamilia].CodigoPadre :=
        oConsulta.FieldByName('PADRE').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Un parametro por familia elegida: el IN con parametros deja que el
// indice de CODIGO_FAM_ART siga sirviendo.
function TRepositorioBusquedaDatosUniDAC.NombreParametroFamilia(
  AIndice: Integer): string;
begin
  Result := 'FAMILIA' + IntToStr(AIndice);
end;

function TRepositorioBusquedaDatosUniDAC.ConsultarProveedores:
  IResultadoBusquedaDatos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.ReadOnly := True;
    oConsulta.SQL.Text := SQL_LISTAR_PROVEEDORES;
    oConsulta.Open;
    Result := TResultadoBusquedaDatosUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioBusquedaDatosUniDAC.ListarTemporadas:
  TOpcionesBusquedaDatos;
begin
  Result := ListarOpciones(SQL_LISTAR_TEMPORADAS);
end;

function TRepositorioBusquedaDatosUniDAC.ListarColoresPaleta:
  TCadenasBusquedaDatos;
var
  iColor: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_COLORES_PALETA;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iColor := Length(Result);
      SetLength(Result, iColor + 1);
      Result[iColor] := oConsulta.FieldByName('NOMBRE_ATB').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioBusquedaDatosUniDAC.BuscarHexColor(
  const AValor: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSCAR_HEX_COLOR;
    oConsulta.ParamByName('VALOR').AsString := UpperCase(Trim(AValor));
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('HEX_ATB').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioBusquedaDatosUniDAC.ExpresionCampo(
  ACampo: Integer): string;
begin
  case ACampo of
    CAMPO_ARTICULO:
      Result := 'eti.CODIGO_ART_ART';
    CAMPO_SKU:
      Result := 'eti.CODIGO_UNIDAD_SKU';
    CAMPO_DESCRIPCION:
      Result := 'eti.DESCRIPCION_ART';
    CAMPO_TALLA:
      Result := 'eti.ATR_TAL';
    CAMPO_COLOR:
      Result := 'eti.ATR_CO';
    CAMPO_COLOR_BASICO:
      Result :=
        'CONCAT_WS('' '', pal.CODIGO_ATB, pal.NOMBRE_ATB, ' +
        'pal.DESCRIPCION_ATB, pal.HEX_ATB)';
    CAMPO_CODIGO_BARRAS:
      Result := 'eti.CODIGO_BARRAS_CB';
    CAMPO_FAMILIA:
      Result :=
        'CONCAT_WS('' '', eti.CODIGO_FAM_ART, eti.NOMBRE_FAM_FAM)';
    CAMPO_PROVEEDOR:
      Result :=
        'CONCAT_WS('' '', eti.CODIGO_PRV_PRV, ' +
        'eti.RAZON_SOCIAL_PRV)';
    CAMPO_REF_PROVEEDOR:
      Result := 'eti.REF_PROVEEDOR';
    CAMPO_TEMPORADA:
      Result := 'eti.PROP_TEMPORADA';
    CAMPO_ALMACEN:
      Result := 'stk.ALMACENES_STOCK';
    CAMPO_PROPIEDADES:
      Result :=
        'CONCAT_WS('' '', eti.ATRIBUTOS_TXT, ' +
        'eti.PROPIEDADES_TXT)';
    else
      Result :=
        'CONCAT_WS('' '', eti.CODIGO_ART_ART, ' +
        'eti.CODIGO_UNIDAD_SKU, eti.DESCRIPCION_ART, eti.ATR_CO, ' +
        'eti.ATR_TAL, eti.CODIGO_BARRAS_CB, eti.CODIGO_FAM_ART, ' +
        'eti.NOMBRE_FAM_FAM, eti.CODIGO_PRV_PRV, ' +
        'eti.RAZON_SOCIAL_PRV, eti.REF_PROVEEDOR, ' +
        'eti.PROP_TEMPORADA, eti.ATRIBUTOS_TXT, ' +
        'eti.PROPIEDADES_TXT, stk.ALMACENES_STOCK, ' +
        'pal.CODIGO_ATB, pal.NOMBRE_ATB, pal.HEX_ATB)';
  end;
end;

function TRepositorioBusquedaDatosUniDAC.ConstruirDistanciaColor: string;
var
  sAzul: string;
  sRojo: string;
  sVerde: string;
begin
  sRojo :=
    'CONV(SUBSTRING(REPLACE(pal.HEX_ATB, ''#'', ''''), 1, 2), 16, 10)';
  sVerde :=
    'CONV(SUBSTRING(REPLACE(pal.HEX_ATB, ''#'', ''''), 3, 2), 16, 10)';
  sAzul :=
    'CONV(SUBSTRING(REPLACE(pal.HEX_ATB, ''#'', ''''), 5, 2), 16, 10)';
  Result := 'ROUND(SQRT(POW(' + sRojo +
    ' - :ROJO, 2) + POW(' + sVerde +
    ' - :VERDE, 2) + POW(' + sAzul +
    ' - :AZUL, 2)), 2)';
end;

procedure TRepositorioBusquedaDatosUniDAC.PrepararConsultaBase(
  AConsulta: TUniQuery;
  AProximidad: Boolean);
begin
  AConsulta.Connection := FConexion;
  AConsulta.ReadOnly := True;
  if AProximidad then
  begin
    AConsulta.SQL.Text := SQL_BUSQUEDA_ANTES_DISTANCIA +
      ConstruirDistanciaColor + ' AS DISTANCIA_COLOR' +
      SQL_BUSQUEDA_DESPUES_DISTANCIA;
  end
  else
  begin
    AConsulta.SQL.Text := SQL_BUSQUEDA_ANTES_DISTANCIA +
      'CAST(NULL AS DECIMAL(10, 2)) AS DISTANCIA_COLOR' +
      SQL_BUSQUEDA_DESPUES_DISTANCIA;
  end;
end;

procedure TRepositorioBusquedaDatosUniDAC.AplicarFiltrosDisponibilidad(
  AConsulta: TUniQuery;
  const ACriterios: TCriteriosBusquedaDatos);
begin
  if ACriterios.Estado = 0 then
  begin
    AConsulta.SQL.Add('AND eti.ESACTIVO_ART = ''S''');
    AConsulta.SQL.Add('AND eti.ESACTIVO_SKU = ''S''');
  end
  else if ACriterios.Estado = 2 then
  begin
    AConsulta.SQL.Add(
      'AND (COALESCE(eti.ESACTIVO_ART, ''N'') <> ''S''');
    AConsulta.SQL.Add(
      'OR COALESCE(eti.ESACTIVO_SKU, ''N'') <> ''S'')');
  end;
  if ACriterios.Stock = 1 then
    AConsulta.SQL.Add('AND COALESCE(stk.CANTIDAD_STOCK, 0) > 0')
  else if ACriterios.Stock = 2 then
    AConsulta.SQL.Add('AND COALESCE(stk.CANTIDAD_STOCK, 0) <= 0');
end;

procedure TRepositorioBusquedaDatosUniDAC.AplicarFiltrosCatalogo(
  AConsulta: TUniQuery;
  const ACriterios: TCriteriosBusquedaDatos);
var
  iFamilia: Integer;
  sLista: string;
  aFamilias: TArray<string>;
begin
  aFamilias := CodigosFamiliaDesdeCsv(ACriterios.Familias);
  if Length(aFamilias) > 0 then
  begin
    sLista := '';
    for iFamilia := 0 to Length(aFamilias) - 1 do
    begin
      if sLista <> '' then
        sLista := sLista + ', ';
      sLista := sLista + ':' + NombreParametroFamilia(iFamilia);
    end;
    AConsulta.SQL.Add(
      'AND eti.CODIGO_FAM_ART IN (' + sLista + ')');
  end;
  if ACriterios.Proveedor <> '' then
    AConsulta.SQL.Add('AND eti.CODIGO_PRV_PRV = :PROVEEDOR');
  if ACriterios.Temporada <> '' then
    AConsulta.SQL.Add('AND eti.PROP_TEMPORADA = :TEMPORADA');
end;

procedure TRepositorioBusquedaDatosUniDAC.AplicarFiltroValor(
  AConsulta: TUniQuery;
  const ACriterios: TCriteriosBusquedaDatos;
  AProximidad: Boolean;
  var AValor: string;
  out AParametro: string);
var
  sCampo: string;
begin
  AParametro := AValor;
  if AProximidad then
  begin
    AConsulta.SQL.Add(
      'AND pal.HEX_ATB REGEXP ''^#?[0-9A-Fa-f]{6}$''');
  end
  else if AValor <> '' then
  begin
    sCampo := ExpresionCampo(ACriterios.Campo);
    if ACriterios.DistinguirMayusculas then
      sCampo := 'BINARY COALESCE(' + sCampo + ', '''')'
    else
    begin
      sCampo := 'UPPER(COALESCE(' + sCampo + ', ''''))';
      AValor := UpperCase(AValor);
    end;
    AParametro := AValor;
    case ACriterios.Coincidencia of
      0:
        begin
          AConsulta.SQL.Add('AND ' + sCampo + ' LIKE :BUSQUEDA');
          AParametro := '%' + AValor + '%';
        end;
      1:
        begin
          AConsulta.SQL.Add('AND ' + sCampo + ' LIKE :BUSQUEDA');
          AParametro := AValor + '%';
        end;
      2:
        AConsulta.SQL.Add('AND ' + sCampo + ' = :BUSQUEDA');
      3:
        begin
          AConsulta.SQL.Add('AND ' + sCampo + ' LIKE :BUSQUEDA');
          AParametro := '%' + AValor;
        end;
      4:
        begin
          AConsulta.SQL.Add('AND ' + sCampo + ' NOT LIKE :BUSQUEDA');
          AParametro := '%' + AValor + '%';
        end;
    end;
  end;
end;

procedure TRepositorioBusquedaDatosUniDAC.AplicarOrdenYLimite(
  AConsulta: TUniQuery;
  AProximidad: Boolean;
  ALimite: Integer);
begin
  if AProximidad then
  begin
    AConsulta.SQL.Add(
      'ORDER BY DISTANCIA_COLOR, eti.CODIGO_ART_ART,');
    AConsulta.SQL.Add('eti.CODIGO_UNIDAD_SKU');
  end
  else
  begin
    AConsulta.SQL.Add(
      'ORDER BY eti.CODIGO_ART_ART, eti.ATR_CO, eti.ATR_TAL,');
    AConsulta.SQL.Add('eti.CODIGO_UNIDAD_SKU');
  end;
  AConsulta.SQL.Add('LIMIT ' + IntToStr(ALimite));
end;

procedure TRepositorioBusquedaDatosUniDAC.AsignarParametrosBusqueda(
  AConsulta: TUniQuery;
  const ACriterios: TCriteriosBusquedaDatos;
  AProximidad: Boolean;
  const AValor, AParametro: string);
var
  iFamilia: Integer;
  aFamilias: TArray<string>;
begin
  AConsulta.ParamByName('ALMACEN_DOC').AsString := ACriterios.Almacen;
  aFamilias := CodigosFamiliaDesdeCsv(ACriterios.Familias);
  for iFamilia := 0 to Length(aFamilias) - 1 do
  begin
    AConsulta.ParamByName(
      NombreParametroFamilia(iFamilia)).AsString := aFamilias[iFamilia];
  end;
  if ACriterios.Proveedor <> '' then
    AConsulta.ParamByName('PROVEEDOR').AsString := ACriterios.Proveedor;
  if ACriterios.Temporada <> '' then
    AConsulta.ParamByName('TEMPORADA').AsString := ACriterios.Temporada;
  if AProximidad then
  begin
    AConsulta.ParamByName('ROJO').AsInteger := ACriterios.Rojo;
    AConsulta.ParamByName('VERDE').AsInteger := ACriterios.Verde;
    AConsulta.ParamByName('AZUL').AsInteger := ACriterios.Azul;
  end
  else if AValor <> '' then
    AConsulta.ParamByName('BUSQUEDA').AsString := AParametro;
end;

function TRepositorioBusquedaDatosUniDAC.PrepararBusqueda(
  const ACriterios: TCriteriosBusquedaDatos
): IResultadoBusquedaDatos;
var
  bProximidad: Boolean;
  oConsulta: TUniQuery;
  sParametro: string;
  sValor: string;
begin
  bProximidad := ACriterios.Campo = CAMPO_PROXIMIDAD_COLOR;
  sValor := Trim(ACriterios.Valor);
  oConsulta := TUniQuery.Create(nil);
  try
    PrepararConsultaBase(oConsulta, bProximidad);
    AplicarFiltrosDisponibilidad(oConsulta, ACriterios);
    AplicarFiltrosCatalogo(oConsulta, ACriterios);
    AplicarFiltroValor(
      oConsulta,
      ACriterios,
      bProximidad,
      sValor,
      sParametro);
    AplicarOrdenYLimite(oConsulta, bProximidad, ACriterios.Limite);
    AsignarParametrosBusqueda(
      oConsulta,
      ACriterios,
      bProximidad,
      sValor,
      sParametro);
    Result := TResultadoBusquedaDatosUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioBusquedaDatosUniDAC(
  AConexion: TUniConnection): IRepositorioBusquedaDatos;
begin
  Result := TRepositorioBusquedaDatosUniDAC.Create(AConexion);
end;

end.
