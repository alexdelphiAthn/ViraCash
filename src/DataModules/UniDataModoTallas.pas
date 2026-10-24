{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataModoTallas                                             }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC del modo de entrada de tallas: tabla de celdas,          }
{    conjuntos de atributos, almacenes y búsqueda incremental de SKUs. Todo    }
{    el SQL del modo vive aquí; no decide reglas ni toca controles.            }
{******************************************************************************}
unit UniDataModoTallas;

interface

uses
  System.SysUtils, Data.DB, Uni,
  inLibModoTallasIntf;

type
  TPersistenciaModoTallasUniDAC = class(TInterfacedObject,
                                        IPersistenciaModeloTallas,
                                        IPersistenciaRederivacionTallas,
                                        IPersistenciaDesmontajeTallas,
                                        IPersistenciaEntradaTallas,
                                        IPersistenciaPresentacionTallas,
                                        IPersistenciaGridTallasInline)
  private
    FConexion: TUniConnection;
    FCfg: TConfigPersistenciaTallas;
    function NuevaConsulta: TUniQuery;
    function Serie: string;
    function Numero: string;
    function WhereNumero(const APrefijo: string): string;
    function ColsInsertNumero: string;
    function ValsInsertNumero: string;
    procedure ParamNumero(AConsulta: TUniQuery);
    function WhereDocExtra: string;
    function ColsInsertDocExtra: string;
    function ValsInsertDocExtra: string;
    procedure ParamsDocExtra(AConsulta: TUniQuery);
    procedure ParamsDocumento(AConsulta: TUniQuery);
    function SqlUpsertCelda(AConAlmacen: Boolean): string;
    function SqlSelectCeldas(const AAlias: string): string;
    function ListaIds(const AIdsValores: TArray<Integer>): string;
    function LeerCeldas(AConsulta: TUniQuery;
      ACabeceraLinea: Boolean): TArray<TCeldaTallas>;
    procedure UpsertCelda(AConsulta: TUniQuery; ALinea, AFila,
      AIdAv: Integer; ACantidad: Double; const AAlmacen: string);
  public
    constructor Create(AConexion: TUniConnection;
      const ACfg: TConfigPersistenciaTallas);
    function ConsultarTotalesPorLinea: TArray<TTotalLineaTallas>;
    function ConsultarCeldasDocumento: TArray<TCeldaTallas>;
    function ConsultarCeldasLinea(ALinea: Integer): TArray<TCeldaTallas>;
    function ConsultarPosicionesConjunto(
      AIdConjunto: Integer;
      const AArticulo: string = ''): TArray<TPosicionConjuntoTallas>;
    procedure FijarCantidadCelda(ALinea, AIdAv: Integer;
      ACantidad: Double; const AAlmacen: string);
    function LineaTieneCeldas(ALinea: Integer): Boolean;
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACantidad: Double;
      const AAlmacen: string);
    procedure MoverCeldasALinea(AOrigen, ADestino: Integer);
    function MigrarCeldasFormato(ADistribuido: Boolean;
      const AAlmacenDefecto: string): Integer;
    procedure BorrarCeldasDocumento;
    function BuscarConjuntoParaAvs(
      const AIdsValores: TArray<Integer>): Integer;
    function ConjuntoCubreAvs(AIdConjunto: Integer;
      const AIdsValores: TArray<Integer>): Boolean;
    function PrimerAlmacenEstandar: string;
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  TBusquedaSkusTallasUniDAC = class(TInterfacedObject,
                                    IBusquedaSkusTallas)
  private
    FConsulta: TUniQuery;
    FUltimoFiltro: string;
    FUltimaCarga: UInt64;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function Dataset: TDataSet;
    procedure Aplicar(const ATexto, AAlmacenStock: string);
    procedure Invalidar;
  end;

function CrearPersistenciaModoTallas(
  AConexion: TUniConnection;
  const ACfg: TConfigPersistenciaTallas): TServiciosPersistenciaModoTallas;
function CrearBusquedaSkusTallas(
  AConexion: TUniConnection): IBusquedaSkusTallas;
function CrearPersistenciaGridTallasInline(
  AConexion: TUniConnection;
  const ACfg: TConfigPersistenciaTallas): IPersistenciaGridTallasInline;

implementation

uses
  System.Classes;

const
  // Consulta UNION de inLibGridArticulos: prefijo en SKU (que empieza
  // por el codigo de articulo), codigo de barras y referencia / modelo
  // de proveedor, y contenido en la descripcion. Barras, referencias y
  // stock se calculan solo para las <=100 filas devueltas.
  SQL_BUSQ_CABECERA =
    'SELECT x.SKU,' +
    '       x.SKU AS INPUT_BUSQUEDA,' +
    '       x.DESCRIPCION,' +
    // CAST explicito: sin el, el metadato de longitud que MariaDB
    // declara para el subquery GROUP_CONCAT se queda corto y UniDAC
    // trunca los codigos (EAN13 recortados a 11 caracteres).
    '       CAST(COALESCE((SELECT GROUP_CONCAT(' +
    '                             DISTINCT cb.CODIGO_BARRAS_CB' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_codigos_barras cb' +
    '                  WHERE cb.CODIGO_UNIDAD_CB = x.SKU), '''')' +
    '            AS CHAR(120)) AS CODBARRAS,' +
    '       CAST(COALESCE((SELECT GROUP_CONCAT(' +
    '                             DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = x.ART' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL), '''')' +
    '            AS CHAR(120)) AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                  WHERE st.CODIGO_UNIDAD_STK = x.SKU' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM ';
  SQL_BUSQ_SIN_FILTRO =
    '(SELECT s.CODIGO_UNIDAD_SKU AS SKU, s.CODIGO_ART_SKU AS ART,' +
    '        a.DESCRIPCION_ART AS DESCRIPCION' +
    '   FROM fza_articulos_skus s' +
    '   JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '  WHERE s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '    AND a.TIPO_ART = ''ESTANDAR''' +
    '  ORDER BY s.CODIGO_UNIDAD_SKU LIMIT 100) x';
  SQL_BUSQ_CON_FILTRO =
    '((SELECT s.CODIGO_UNIDAD_SKU AS SKU, s.CODIGO_ART_SKU AS ART,' +
    '         a.DESCRIPCION_ART AS DESCRIPCION' +
    '    FROM fza_articulos_skus s' +
    '    JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '   WHERE s.CODIGO_UNIDAD_SKU LIKE :TPREF' +
    '     AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '     AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_articulos a' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '    WHERE a.DESCRIPCION_ART LIKE :TDESC' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_codigos_barras cb' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB' +
    '     JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '    WHERE cb.CODIGO_BARRAS_CB LIKE :TPREF' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    '  UNION' +
    '  (SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, a.DESCRIPCION_ART' +
    '     FROM fza_articulos_proveedores ap' +
    '     JOIN fza_articulos_skus s' +
    '       ON s.CODIGO_ART_SKU = ap.CODIGO_ART_AP' +
    '     JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU' +
    '    WHERE ap.REF_PROVEEDOR_AP LIKE :TPREF' +
    '      AND s.ESACTIVO_SKU = ''S'' AND a.ESACTIVO_ART = ''S''' +
    '      AND a.TIPO_ART = ''ESTANDAR'' LIMIT 100)' +
    ' ) x';
  SQL_BUSQ_ORDEN = ' ORDER BY STOCK DESC, x.SKU LIMIT 100';

constructor TPersistenciaModoTallasUniDAC.Create(
  AConexion: TUniConnection; const ACfg: TConfigPersistenciaTallas);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FCfg := ACfg;
end;

function TPersistenciaModoTallasUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TPersistenciaModoTallasUniDAC.Serie: string;
begin
  Result := FCfg.Master.FieldByName(FCfg.CampoSerieMaster).AsString;
end;

function TPersistenciaModoTallasUniDAC.Numero: string;
begin
  Result := '';
  if FCfg.CampoNumeroMaster <> '' then
    Result := FCfg.Master.FieldByName(FCfg.CampoNumeroMaster).AsString;
end;

function TPersistenciaModoTallasUniDAC.WhereNumero(
  const APrefijo: string): string;
begin
  // APrefijo: alias de la tabla de celdas ('c.' en el des-pivote).
  Result := '';
  if FCfg.CampoNumeroCel <> '' then
    Result := ' AND ' + APrefijo + FCfg.CampoNumeroCel + ' = :n';
end;

function TPersistenciaModoTallasUniDAC.ColsInsertNumero: string;
begin
  Result := '';
  if FCfg.CampoNumeroCel <> '' then
    Result := FCfg.CampoNumeroCel + ', ';
end;

function TPersistenciaModoTallasUniDAC.ValsInsertNumero: string;
begin
  Result := '';
  if FCfg.CampoNumeroCel <> '' then
    Result := ':n, ';
end;

procedure TPersistenciaModoTallasUniDAC.ParamNumero(
  AConsulta: TUniQuery);
begin
  if FCfg.CampoNumeroCel <> '' then
    AConsulta.ParamByName('n').AsString := Numero;
end;

function TPersistenciaModoTallasUniDAC.WhereDocExtra: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(FCfg.CamposDocExtraCel) do
    Result := Result + ' AND ' + FCfg.CamposDocExtraCel[i] +
              ' = :x' + IntToStr(i) + ' ';
end;

function TPersistenciaModoTallasUniDAC.ColsInsertDocExtra: string;
var
  i: Integer;
begin
  // 'CAMPO, ' por cada clave extra, para intercalar tras SERIE/NUMERO
  // en la lista de columnas del INSERT.
  Result := '';
  for i := 0 to High(FCfg.CamposDocExtraCel) do
    Result := Result + FCfg.CamposDocExtraCel[i] + ', ';
end;

function TPersistenciaModoTallasUniDAC.ValsInsertDocExtra: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(FCfg.CamposDocExtraCel) do
    Result := Result + ':x' + IntToStr(i) + ', ';
end;

procedure TPersistenciaModoTallasUniDAC.ParamsDocExtra(
  AConsulta: TUniQuery);
var
  i: Integer;
begin
  if FCfg.Master <> nil then
    for i := 0 to High(FCfg.CamposDocExtraMaster) do
      AConsulta.ParamByName('x' + IntToStr(i)).AsString :=
        FCfg.Master.FieldByName(
          FCfg.CamposDocExtraMaster[i]).AsString;
end;

procedure TPersistenciaModoTallasUniDAC.ParamsDocumento(
  AConsulta: TUniQuery);
begin
  AConsulta.ParamByName('s').AsString := Serie;
  ParamNumero(AConsulta);
  ParamsDocExtra(AConsulta);
end;

function TPersistenciaModoTallasUniDAC.ListaIds(
  const AIdsValores: TArray<Integer>): string;
var
  i: Integer;
begin
  // Lista IN de enteros construida en memoria (IdValor es Integer).
  Result := '';
  for i := 0 to High(AIdsValores) do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(AIdsValores[i]);
  end;
end;

function TPersistenciaModoTallasUniDAC.ConsultarTotalesPorLinea
  : TArray<TTotalLineaTallas>;
var
  Consulta: TUniQuery;
  iTotal: Integer;
begin
  Result := nil;
  iTotal := 0;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT ' + FCfg.CampoLineaCel + ' AS LIN,' +
      ' COALESCE(SUM(' + FCfg.CampoCantidadCel + '), 0) AS TOTAL' +
      ' FROM ' + FCfg.TablaCeldas +
      ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
      WhereNumero('') +
      WhereDocExtra +
      ' GROUP BY ' + FCfg.CampoLineaCel;
    ParamsDocumento(Consulta);
    Consulta.Open;
    while not Consulta.Eof do
    begin
      SetLength(Result, iTotal + 1);
      Result[iTotal].Linea := Consulta.FieldByName('LIN').AsInteger;
      Result[iTotal].Total := Consulta.FieldByName('TOTAL').AsFloat;
      Inc(iTotal);
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TPersistenciaModoTallasUniDAC.SqlSelectCeldas(
  const AAlias: string): string;
var
  sPrefijo, sAlmacen, sGrupoAlmacen: string;
begin
  sPrefijo := '';
  if AAlias <> '' then
    sPrefijo := AAlias + '.';
  if FCfg.CampoAlmacenCel <> '' then
  begin
    sAlmacen := ' ' + sPrefijo + FCfg.CampoAlmacenCel + ' AS ALMC,';
    sGrupoAlmacen := ', ' + sPrefijo + FCfg.CampoAlmacenCel;
  end
  else
  begin
    sAlmacen := ' '''' AS ALMC,';
    sGrupoAlmacen := '';
  end;
  Result :=
    'SELECT ' + sPrefijo + FCfg.CampoLineaCel + ' AS LIN,' +
    sAlmacen +
    ' AV.AV AS VALOR,' +
    ' SUM(' + sPrefijo + FCfg.CampoCantidadCel + ') AS CANT' +
    ' FROM ' + FCfg.TablaCeldas + ' ' + AAlias +
    ' JOIN fza_atributos_valores AV' +
    '   ON AV.ID_AV = ' + sPrefijo + FCfg.CampoAvPivotCel +
    ' WHERE ' + sPrefijo + FCfg.CampoSerieCel + ' = :s' +
    WhereNumero(sPrefijo) +
    WhereDocExtra;
  Result := Result +
    ' GROUP BY ' + sPrefijo + FCfg.CampoLineaCel + sGrupoAlmacen +
    ', AV.AV';
end;

function TPersistenciaModoTallasUniDAC.LeerCeldas(AConsulta: TUniQuery;
  ACabeceraLinea: Boolean): TArray<TCeldaTallas>;
var
  iTotal: Integer;
begin
  Result := nil;
  iTotal := 0;
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    SetLength(Result, iTotal + 1);
    if ACabeceraLinea then
      Result[iTotal].Linea := AConsulta.FieldByName('LIN').AsInteger;
    Result[iTotal].Almacen :=
      Trim(AConsulta.FieldByName('ALMC').AsString);
    if AConsulta.FindField('IDAV') <> nil then
      Result[iTotal].IdAv := AConsulta.FieldByName('IDAV').AsInteger;
    if AConsulta.FindField('VALOR') <> nil then
      Result[iTotal].ValorTalla :=
        Trim(AConsulta.FieldByName('VALOR').AsString);
    Result[iTotal].Cantidad := AConsulta.FieldByName('CANT').AsFloat;
    Inc(iTotal);
    AConsulta.Next;
  end;
end;

function TPersistenciaModoTallasUniDAC.ConsultarCeldasDocumento
  : TArray<TCeldaTallas>;
var
  Consulta: TUniQuery;
  sOrden: string;
begin
  Consulta := NuevaConsulta;
  try
    if FCfg.CampoAlmacenCel <> '' then
      sOrden := ' ORDER BY LIN, ALMC, VALOR'
    else
      sOrden := ' ORDER BY LIN, VALOR';
    Consulta.SQL.Text := SqlSelectCeldas('c') +
      ' HAVING SUM(c.' + FCfg.CampoCantidadCel + ') > 0' + sOrden;
    ParamsDocumento(Consulta);
    Result := LeerCeldas(Consulta, True);
  finally
    FreeAndNil(Consulta);
  end;
end;

function TPersistenciaModoTallasUniDAC.ConsultarCeldasLinea(
  ALinea: Integer): TArray<TCeldaTallas>;
var
  Consulta: TUniQuery;
  sAlmacen, sGrupoAlmacen: string;
begin
  Consulta := NuevaConsulta;
  try
    if FCfg.CampoAlmacenCel <> '' then
    begin
      sAlmacen := ' ' + FCfg.CampoAlmacenCel + ' AS ALMC,';
      sGrupoAlmacen := ', ' + FCfg.CampoAlmacenCel;
    end
    else
    begin
      sAlmacen := ' '''' AS ALMC,';
      sGrupoAlmacen := '';
    end;
    Consulta.SQL.Text :=
      'SELECT ' + FCfg.CampoAvPivotCel + ' AS IDAV,' +
      sAlmacen +
      ' SUM(' + FCfg.CampoCantidadCel + ') AS CANT' +
      ' FROM ' + FCfg.TablaCeldas +
      ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
      WhereNumero('') +
      WhereDocExtra +
      ' AND ' + FCfg.CampoLineaCel + ' = :l' +
      ' GROUP BY ' + FCfg.CampoAvPivotCel + sGrupoAlmacen;
    ParamsDocumento(Consulta);
    Consulta.ParamByName('l').AsInteger := ALinea;
    Result := LeerCeldas(Consulta, False);
  finally
    FreeAndNil(Consulta);
  end;
end;

function TPersistenciaModoTallasUniDAC.ConsultarPosicionesConjunto(
  AIdConjunto: Integer;
  const AArticulo: string): TArray<TPosicionConjuntoTallas>;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  if (AIdConjunto > 0) or (AArticulo <> '') then
  begin
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT ID_AV_ACD, VALOR FROM (' +
        'SELECT ACD.ID_AV_ACD, AV.AV AS VALOR, ' +
        '       0 AS BLOQUE, ACD.ORDEN_ACD AS ORDEN ' +
        '  FROM fza_atributos_conjuntos_det ACD ' +
        '  JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = ACD.ID_AV_ACD ' +
        ' WHERE ACD.ID_AC_ACD = :p ' +
        ' UNION ALL ' +
        'SELECT DISTINCT AV.ID_AV, AV.AV, 1, AV.ORDEN_AV ' +
        '  FROM fza_articulos_skus SK ' +
        '  JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        ' WHERE SK.CODIGO_ART_SKU = :art AND AV.ID_VA_AV = (SELECT ' +
        'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
        'EJ452.ID_VAR_VA = SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
        '   AND NOT EXISTS (SELECT 1 ' +
        '     FROM fza_atributos_conjuntos_det D ' +
        '     WHERE D.ID_AC_ACD = :p AND D.ID_AV_ACD = AV.ID_AV)' +
        ') T ORDER BY BLOQUE, ORDEN, VALOR, ID_AV_ACD';
      oConsulta.ParamByName('p').AsInteger := AIdConjunto;
      oConsulta.ParamByName('art').AsString := AArticulo;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        iIndice := Length(Result);
        SetLength(Result, iIndice + 1);
        Result[iIndice].IdAv :=
          oConsulta.FieldByName('ID_AV_ACD').AsInteger;
        Result[iIndice].Valor :=
          oConsulta.FieldByName('VALOR').AsString;
        oConsulta.Next;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

procedure TPersistenciaModoTallasUniDAC.FijarCantidadCelda(
  ALinea, AIdAv: Integer; ACantidad: Double;
  const AAlmacen: string);
var
  oConsulta: TUniQuery;
  sAlmacen: string;
begin
  // ID_AV 0 = unidades de un articulo sin tallas (sesiones de compra).
  if (ALinea > 0) and (AIdAv >= 0) then
  begin
    oConsulta := NuevaConsulta;
    try
      sAlmacen := '';
      if FCfg.CampoAlmacenCel <> '' then
        sAlmacen := ' AND ' + FCfg.CampoAlmacenCel + ' = :a';
      if ACantidad <= 0 then
        oConsulta.SQL.Text :=
          'DELETE FROM ' + FCfg.TablaCeldas +
          ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
          WhereNumero('') + WhereDocExtra +
          ' AND ' + FCfg.CampoLineaCel + ' = :l' +
          ' AND ' + FCfg.CampoFilaCel + ' = :f' +
          ' AND ' + FCfg.CampoAvPivotCel + ' = :p' + sAlmacen
      else
      begin
        oConsulta.SQL.Text := SqlUpsertCelda(
          FCfg.CampoAlmacenCel <> '');
        oConsulta.SQL.Text := StringReplace(
          oConsulta.SQL.Text,
          FCfg.CampoCantidadCel + ' = ' +
          FCfg.CampoCantidadCel + ' + :c',
          FCfg.CampoCantidadCel + ' = :c', []);
        oConsulta.ParamByName('c').AsFloat := ACantidad;
        oConsulta.ParamByName('u').AsString := FCfg.Usuario;
      end;
      ParamsDocumento(oConsulta);
      oConsulta.ParamByName('l').AsInteger := ALinea;
      oConsulta.ParamByName('f').AsInteger := FCfg.IdFilaFijo;
      oConsulta.ParamByName('p').AsInteger := AIdAv;
      if FCfg.CampoAlmacenCel <> '' then
        oConsulta.ParamByName('a').AsString := AAlmacen;
      oConsulta.ExecSQL;
    finally
      oConsulta.Free;
    end;
  end;
end;

function TPersistenciaModoTallasUniDAC.LineaTieneCeldas(
  ALinea: Integer): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  if ALinea > 0 then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT 1 FROM ' + FCfg.TablaCeldas +
        ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
        WhereNumero('') +
        WhereDocExtra +
        ' AND ' + FCfg.CampoLineaCel + ' = :l' +
        ' LIMIT 1';
      ParamsDocumento(Consulta);
      Consulta.ParamByName('l').AsInteger := ALinea;
      Consulta.Open;
      Result := not Consulta.Eof;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TPersistenciaModoTallasUniDAC.SqlUpsertCelda(
  AConAlmacen: Boolean): string;
var
  sColAlmacen, sValAlmacen: string;
begin
  // Upsert ATOMICO (cantidad = cantidad + :c), respetando el almacen de
  // la celda cuando el documento lo usa (formato distribuido). Nada de
  // INSERT..SELECT sobre la misma tabla: el ON DUPLICATE sobre la
  // columna cantidad resulta ambiguo en MariaDB (#23000).
  sColAlmacen := '';
  sValAlmacen := '';
  if AConAlmacen then
  begin
    sColAlmacen := FCfg.CampoAlmacenCel + ', ';
    sValAlmacen := ':a, ';
  end;
  Result :=
    'INSERT INTO ' + FCfg.TablaCeldas + ' (' +
    FCfg.CampoSerieCel + ', ' +
    ColsInsertNumero +
    ColsInsertDocExtra +
    FCfg.CampoLineaCel + ', ' +
    FCfg.CampoFilaCel + ', ' +
    sColAlmacen +
    FCfg.CampoAvPivotCel + ', ' +
    FCfg.CampoCantidadCel + ',' +
    ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF,' +
    ' USUARIO_MODIF)' +
    ' VALUES (:s, ' + ValsInsertNumero + ValsInsertDocExtra +
    ':l, :f, ' + sValAlmacen + ':p, :c,' +
    ' NOW(), :u, NOW(), :u)' +
    ' ON DUPLICATE KEY UPDATE ' +
    FCfg.CampoCantidadCel + ' = ' +
    FCfg.CampoCantidadCel + ' + :c,' +
    ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
end;

procedure TPersistenciaModoTallasUniDAC.UpsertCelda(
  AConsulta: TUniQuery; ALinea, AFila, AIdAv: Integer;
  ACantidad: Double; const AAlmacen: string);
begin
  ParamsDocumento(AConsulta);
  AConsulta.ParamByName('l').AsInteger := ALinea;
  AConsulta.ParamByName('f').AsInteger := AFila;
  if FCfg.CampoAlmacenCel <> '' then
    AConsulta.ParamByName('a').AsString := AAlmacen;
  AConsulta.ParamByName('p').AsInteger := AIdAv;
  AConsulta.ParamByName('c').AsFloat := ACantidad;
  AConsulta.ParamByName('u').AsString := FCfg.Usuario;
  AConsulta.ExecSQL;
end;

procedure TPersistenciaModoTallasUniDAC.SumarEnCelda(
  ALinea, AIdAv: Integer; ACantidad: Double; const AAlmacen: string);
var
  Consulta: TUniQuery;
begin
  if (ALinea > 0) and (AIdAv > 0) then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        SqlUpsertCelda(FCfg.CampoAlmacenCel <> '');
      UpsertCelda(Consulta, ALinea, FCfg.IdFilaFijo, AIdAv, ACantidad,
                  AAlmacen);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TPersistenciaModoTallasUniDAC.MoverCeldasALinea(
  AOrigen, ADestino: Integer);
var
  Celdas: TArray<TCeldaTallas>;
  Consulta: TUniQuery;
  i: Integer;
begin
  // Fusion de una duplicada que YA tiene celdas: mueve sus celdas a la
  // linea maestra (upsert sumando por talla y almacen) y las borra del
  // origen. Mover su CANTIDAD en su lugar duplicaria.
  if (AOrigen > 0) and (ADestino > 0) and (AOrigen <> ADestino) then
  begin
    Celdas := ConsultarCeldasLinea(AOrigen);
    for i := 0 to High(Celdas) do
      SumarEnCelda(ADestino, Celdas[i].IdAv, Celdas[i].Cantidad,
                   Celdas[i].Almacen);
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'DELETE FROM ' + FCfg.TablaCeldas +
        ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
        WhereNumero('') +
        WhereDocExtra +
        ' AND ' + FCfg.CampoLineaCel + ' = :l';
      ParamsDocumento(Consulta);
      Consulta.ParamByName('l').AsInteger := AOrigen;
      Consulta.ExecSQL;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TPersistenciaModoTallasUniDAC.MigrarCeldasFormato(
  ADistribuido: Boolean; const AAlmacenDefecto: string): Integer;
var
  Consulta, Escritura: TUniQuery;
  sFiltroAlmacen, sAlmacenDestino: string;
begin
  // Al construir, unifica el origen de las cantidades segun el formato:
  // con distribuido, las celdas SIN almacen (tecleadas en modo normal)
  // migran al almacen por defecto del documento; sin distribuido, las
  // celdas por almacen se colapsan a almacen ''. Siempre fusionando
  // cantidades si la celda destino ya existe.
  Result := 0;
  if FCfg.CampoAlmacenCel <> '' then
  begin
    if ADistribuido then
    begin
      sFiltroAlmacen := ' AND ' + FCfg.CampoAlmacenCel + ' = ''''';
      sAlmacenDestino := AAlmacenDefecto;
    end
    else
    begin
      sFiltroAlmacen := ' AND ' + FCfg.CampoAlmacenCel + ' <> ''''';
      sAlmacenDestino := '';
    end;
    Consulta := NuevaConsulta;
    Escritura := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT ' + FCfg.CampoLineaCel + ' AS LIN, ' +
        FCfg.CampoFilaCel + ' AS FILA, ' +
        FCfg.CampoAvPivotCel + ' AS IDAV, ' +
        'SUM(' + FCfg.CampoCantidadCel + ') AS CANT' +
        ' FROM ' + FCfg.TablaCeldas +
        ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
        WhereNumero('') +
        sFiltroAlmacen +
        WhereDocExtra +
        ' GROUP BY ' + FCfg.CampoLineaCel + ', ' +
        FCfg.CampoFilaCel + ', ' + FCfg.CampoAvPivotCel;
      ParamsDocumento(Consulta);
      Consulta.Open;
      Escritura.SQL.Text := SqlUpsertCelda(True);
      while not Consulta.Eof do
      begin
        UpsertCelda(Escritura,
          Consulta.FieldByName('LIN').AsInteger,
          Consulta.FieldByName('FILA').AsInteger,
          Consulta.FieldByName('IDAV').AsInteger,
          Consulta.FieldByName('CANT').AsFloat,
          sAlmacenDestino);
        Inc(Result);
        Consulta.Next;
      end;
      Consulta.Close;
      if Result > 0 then
      begin
        // Origen migrado: fuera las celdas del formato anterior.
        Escritura.SQL.Text :=
          'DELETE FROM ' + FCfg.TablaCeldas +
          ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
          WhereNumero('') +
          sFiltroAlmacen +
          WhereDocExtra;
        ParamsDocumento(Escritura);
        Escritura.ExecSQL;
      end;
    finally
      FreeAndNil(Escritura);
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TPersistenciaModoTallasUniDAC.BorrarCeldasDocumento;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'DELETE FROM ' + FCfg.TablaCeldas +
      ' WHERE ' + FCfg.CampoSerieCel + ' = :s' +
      WhereNumero('') +
      WhereDocExtra;
    ParamsDocumento(Consulta);
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TPersistenciaModoTallasUniDAC.BuscarConjuntoParaAvs(
  const AIdsValores: TArray<Integer>): Integer;
var
  Consulta: TUniQuery;
  sIds: string;
begin
  // Fallback de pivote: conjunto global MAS PEQUENYO que contiene todos
  // los AVs de talla del articulo. 0 si ninguno cubre.
  Result := 0;
  if Length(AIdsValores) > 0 then
  begin
    sIds := ListaIds(AIdsValores);
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT d.ID_AC_ACD AS ID_AC' +
        '  FROM fza_atributos_conjuntos_det d' +
        ' WHERE d.ID_AV_ACD IN (' + sIds + ')' +
        ' GROUP BY d.ID_AC_ACD' +
        ' HAVING COUNT(DISTINCT d.ID_AV_ACD) = ' +
                IntToStr(Length(AIdsValores)) +
        ' ORDER BY (SELECT COUNT(*)' +
        '             FROM fza_atributos_conjuntos_det t' +
        '            WHERE t.ID_AC_ACD = d.ID_AC_ACD)' +
        ' LIMIT 1';
      Consulta.Open;
      if not Consulta.Eof then
        Result := Consulta.Fields[0].AsInteger;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TPersistenciaModoTallasUniDAC.ConjuntoCubreAvs(
  AIdConjunto: Integer; const AIdsValores: TArray<Integer>): Boolean;
var
  Consulta: TUniQuery;
  sIds: string;
begin
  // True si el conjunto AIdConjunto contiene TODOS los AVs indicados.
  Result := True;
  if (AIdConjunto > 0) and (Length(AIdsValores) > 0) then
  begin
    sIds := ListaIds(AIdsValores);
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT COUNT(DISTINCT d.ID_AV_ACD) AS N' +
        '  FROM fza_atributos_conjuntos_det d' +
        ' WHERE d.ID_AC_ACD = ' + IntToStr(AIdConjunto) +
        '   AND d.ID_AV_ACD IN (' + sIds + ')';
      Consulta.Open;
      Result := Consulta.Fields[0].AsInteger = Length(AIdsValores);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TPersistenciaModoTallasUniDAC.PrimerAlmacenEstandar: string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    // Mismo criterio de almacenes que el distribuidor.
    Consulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM FROM fza_almacenes' +
      ' WHERE ESACTIVO_ALM = ''S''' +
      '   AND TIPO_USO_ALM IN (''ESTANDAR'', ''ESTANDARD'')' +
      ' ORDER BY CODIGO_ALM_ALM LIMIT 1';
    Consulta.Open;
    if not Consulta.Eof then
      Result := Consulta.Fields[0].AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TPersistenciaModoTallasUniDAC.EnTransaccion: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TPersistenciaModoTallasUniDAC.IniciarTransaccion;
begin
  FConexion.StartTransaction;
end;

procedure TPersistenciaModoTallasUniDAC.ConfirmarTransaccion;
begin
  FConexion.Commit;
end;

procedure TPersistenciaModoTallasUniDAC.RevertirTransaccion;
begin
  FConexion.Rollback;
end;

constructor TBusquedaSkusTallasUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := AConexion;
end;

destructor TBusquedaSkusTallasUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TBusquedaSkusTallasUniDAC.Dataset: TDataSet;
begin
  Result := FConsulta;
end;

procedure TBusquedaSkusTallasUniDAC.Invalidar;
begin
  // El stock del desplegable depende del almacen: se invalida el
  // dataset y la proxima busqueda reconsulta.
  FUltimoFiltro := #1;
  if FConsulta.Active then
    FConsulta.Close;
end;

procedure TBusquedaSkusTallasUniDAC.Aplicar(
  const ATexto, AAlmacenStock: string);
begin
  // FZ-ISSUE-234: el Stock del desplegable caduca (2 s), no se reutiliza
  // una consulta de hace una hora con el stock de entonces.
  if not (FConsulta.Active and (FUltimoFiltro = ATexto) and
          (TThread.GetTickCount64 - FUltimaCarga < 2000)) then
  begin
    if FConsulta.Active then
      FConsulta.Close;
    if ATexto = '' then
      FConsulta.SQL.Text :=
        SQL_BUSQ_CABECERA + SQL_BUSQ_SIN_FILTRO + SQL_BUSQ_ORDEN
    else
    begin
      FConsulta.SQL.Text :=
        SQL_BUSQ_CABECERA + SQL_BUSQ_CON_FILTRO + SQL_BUSQ_ORDEN;
      FConsulta.ParamByName('TPREF').AsString := ATexto + '%';
      FConsulta.ParamByName('TDESC').AsString := '%' + ATexto + '%';
    end;
    FConsulta.ParamByName('ALM').AsString := Trim(AAlmacenStock);
    FConsulta.Open;
    FUltimoFiltro := ATexto;
    FUltimaCarga := TThread.GetTickCount64;
  end;
end;

function CrearPersistenciaModoTallas(
  AConexion: TUniConnection;
  const ACfg: TConfigPersistenciaTallas): TServiciosPersistenciaModoTallas;
var
  Persistencia: TPersistenciaModoTallasUniDAC;
begin
  Result := Default(TServiciosPersistenciaModoTallas);
  Persistencia := TPersistenciaModoTallasUniDAC.Create(AConexion, ACfg);
  Result.Modelo := Persistencia;
  Result.Rederivacion := Persistencia;
  Result.Desmontaje := Persistencia;
  Result.Entrada := Persistencia;
  Result.Presentacion := Persistencia;
  Result.GridInline := Persistencia;
end;

function CrearBusquedaSkusTallas(
  AConexion: TUniConnection): IBusquedaSkusTallas;
begin
  Result := TBusquedaSkusTallasUniDAC.Create(AConexion);
end;

function CrearPersistenciaGridTallasInline(
  AConexion: TUniConnection;
  const ACfg: TConfigPersistenciaTallas): IPersistenciaGridTallasInline;
var
  oServicios: TServiciosPersistenciaModoTallas;
begin
  oServicios := CrearPersistenciaModoTallas(AConexion, ACfg);
  Result := oServicios.GridInline;
end;

end.
