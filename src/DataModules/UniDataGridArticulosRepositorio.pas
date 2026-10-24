{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGridArticulosRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta de artículos del buscador completo del grid reutilizable.        }
{******************************************************************************}
unit UniDataGridArticulosRepositorio;

interface

uses
  Uni,
  inLibGridArticulosPersistenciaIntf,
  inLibModoTallasIntf;

function CrearConsultaArticulosGridUniDAC(
  AConexion: TUniConnection): IConsultaArticulosGrid;
function CrearBusquedaArticulosPadreGridUniDAC(
  AConexion: TUniConnection): IBusquedaSkusTallas;

implementation

uses
  System.SysUtils, System.Classes, Data.DB;

const
  // FZ-ISSUE-234: la columna Stock no puede salir de una consulta vieja.
  // Solo se reutiliza dentro de la misma interaccion (teclas seguidas).
  MS_VIGENCIA_BUSQUEDA_STOCK = 2000;

  SQL_ARTICULOS_GRID =
    'SELECT a.CODIGO_ART_ART AS ARTICULO,' +
    '       a.DESCRIPCION_ART AS DESCRIPCION,' +
    '       COALESCE(NULLIF(f.DESCRIPCION_FAM, ''''),' +
    '                NULLIF(f.NOMBRE_FAM_FAM, ''''),' +
    '                a.CODIGO_FAM_ART, '''') AS FAMILIA,' +
    '       COALESCE(pv.PV, artprop.VALOR_LIBRE_ARTPROP, '''')' +
    '         AS TEMPORADA,' +
    '       COALESCE((SELECT COALESCE(' +
    '                            NULLIF(p.RAZON_SOCIAL_PRV, ''''),' +
    '                            NULLIF(p.NOMBRE_PRV, ''''),' +
    '                            ap_prv.CODIGO_PRV_AP)' +
    '                   FROM fza_articulos_proveedores ap_prv' +
    '                   LEFT JOIN fza_proveedores p' +
    '                     ON p.CODIGO_PRV_PRV = ap_prv.CODIGO_PRV_AP' +
    '                  WHERE ap_prv.CODIGO_ART_AP = a.CODIGO_ART_ART' +
    '                    AND ap_prv.ESPROVEEDORPRINCIPAL_AP = ''S''' +
    '                  ORDER BY ap_prv.CODIGO_PRV_AP' +
    '                  LIMIT 1), '''') AS PROVEEDOR,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL), '''')' +
    '         AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                   JOIN fza_articulos_skus sk' +
    '                     ON sk.CODIGO_UNIDAD_SKU = st.CODIGO_UNIDAD_STK' +
    '                  WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM fza_articulos a' +
    '  LEFT JOIN fza_articulos_familias f' +
    '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART' +
    '  LEFT JOIN fza_articulos_propiedades artprop' +
    '    ON artprop.CODIGO_ART_ART = a.CODIGO_ART_ART' +
    '   AND artprop.CODIGO_PROP_ARTPROP = ''TEMPORADA''' +
    '   AND artprop.CODIGO_UNIDAD_ARTPROP = ''''' +
    '  LEFT JOIN fza_propiedades_valores pv' +
    '    ON pv.ID_PV_ARTPROP = artprop.ID_PV_ARTPROP' +
    ' WHERE a.ESACTIVO_ART = ''S'' AND a.TIPO_ART = ''ESTANDAR''' +
    ' ORDER BY STOCK DESC, a.CODIGO_ART_ART';

  // El lookup compartido espera los alias SKU e INPUT_BUSQUEDA. Aqui ambos
  // contienen el codigo padre: nunca se devuelve una fila por variante.
  SQL_BUSQUEDA_PADRES_CABECERA =
    'SELECT x.ARTICULO AS SKU,' +
    '       x.ARTICULO AS INPUT_BUSQUEDA,' +
    '       x.DESCRIPCION,' +
    '       CAST(COALESCE((SELECT GROUP_CONCAT(' +
    '                             DISTINCT cb.CODIGO_BARRAS_CB' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_codigos_barras cb' +
    '                   JOIN fza_articulos_skus sk_cb' +
    '                     ON sk_cb.CODIGO_UNIDAD_SKU =' +
    '                        cb.CODIGO_UNIDAD_CB' +
    '                  WHERE sk_cb.CODIGO_ART_SKU = x.ARTICULO),' +
    '                  '''') AS CHAR(120)) AS CODBARRAS,' +
    '       CAST(COALESCE((SELECT GROUP_CONCAT(' +
    '                             DISTINCT ap.REF_PROVEEDOR_AP' +
    '                                     SEPARATOR '' '')' +
    '                   FROM fza_articulos_proveedores ap' +
    '                  WHERE ap.CODIGO_ART_AP = x.ARTICULO' +
    '                    AND ap.REF_PROVEEDOR_AP IS NOT NULL),' +
    '                  '''') AS CHAR(120)) AS REFPRV,' +
    '       COALESCE((SELECT SUM(st.CANTIDAD_STK)' +
    '                   FROM fza_articulos_stockactual st' +
    '                   JOIN fza_articulos_skus sk_st' +
    '                     ON sk_st.CODIGO_UNIDAD_SKU =' +
    '                        st.CODIGO_UNIDAD_STK' +
    '                  WHERE sk_st.CODIGO_ART_SKU = x.ARTICULO' +
    '                    AND st.CODIGO_ALM_STK = :ALM), 0) AS STOCK' +
    '  FROM (SELECT a.CODIGO_ART_ART AS ARTICULO,' +
    '               a.DESCRIPCION_ART AS DESCRIPCION' +
    '          FROM fza_articulos a' +
    '         WHERE a.ESACTIVO_ART = ''S''' +
    '           AND a.TIPO_ART = ''ESTANDAR''';
  SQL_BUSQUEDA_PADRES_FILTRO =
    '           AND a.CODIGO_ART_ART LIKE :TPREF';
  SQL_BUSQUEDA_PADRES_ORDEN =
    '         ORDER BY a.CODIGO_ART_ART LIMIT 100) x' +
    ' ORDER BY STOCK DESC, x.ARTICULO LIMIT 100';

type
  TConsultaArticulosGridUniDAC = class(
    TInterfacedObject,
    IConsultaArticulosGrid)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function DataSet: TDataSet;
    procedure Aplicar(const AAlmacenStock: string);
  end;

  TBusquedaArticulosPadreGridUniDAC = class(
    TInterfacedObject,
    IBusquedaSkusTallas)
  private
    FConsulta: TUniQuery;
    FUltimoAlmacen: string;
    FUltimoFiltro: string;
    FUltimaCarga: UInt64;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function Dataset: TDataSet;
    procedure Aplicar(const ATexto, AAlmacenStock: string);
    procedure Invalidar;
  end;

constructor TConsultaArticulosGridUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := AConexion;
  FConsulta.SQL.Text := SQL_ARTICULOS_GRID;
end;

destructor TConsultaArticulosGridUniDAC.Destroy;
begin
  FConsulta.Free;
  inherited;
end;

function TConsultaArticulosGridUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

procedure TConsultaArticulosGridUniDAC.Aplicar(
  const AAlmacenStock: string);
  procedure EtiquetarCampo(
    const ANombreCampo, AEtiqueta: string);
  var
    Campo: TField;
  begin
    Campo := FConsulta.FindField(ANombreCampo);
    if Campo <> nil then
      Campo.DisplayLabel := AEtiqueta;
  end;
begin
  FConsulta.Close;
  FConsulta.ParamByName('ALM').AsString := Trim(AAlmacenStock);
  FConsulta.Open;
  EtiquetarCampo('ARTICULO', 'Código');
  EtiquetarCampo('DESCRIPCION', 'Descripción');
  EtiquetarCampo('FAMILIA', 'Familia');
  EtiquetarCampo('TEMPORADA', 'Temporada');
  EtiquetarCampo('PROVEEDOR', 'Proveedor');
  EtiquetarCampo('REFPRV', 'Ref. proveedor');
  EtiquetarCampo('STOCK', 'Stock');
end;

function CrearConsultaArticulosGridUniDAC(
  AConexion: TUniConnection): IConsultaArticulosGrid;
begin
  Result := TConsultaArticulosGridUniDAC.Create(AConexion);
end;

constructor TBusquedaArticulosPadreGridUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := AConexion;
  FUltimoAlmacen := #1;
  FUltimoFiltro := #1;
end;

destructor TBusquedaArticulosPadreGridUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TBusquedaArticulosPadreGridUniDAC.Dataset: TDataSet;
begin
  Result := FConsulta;
end;

procedure TBusquedaArticulosPadreGridUniDAC.Aplicar(
  const ATexto, AAlmacenStock: string);
var
  sAlmacen: string;
  sFiltro: string;
begin
  sAlmacen := Trim(AAlmacenStock);
  sFiltro := Trim(ATexto);
  if not (FConsulta.Active and SameText(FUltimoFiltro, sFiltro) and
          SameText(FUltimoAlmacen, sAlmacen) and
          (TThread.GetTickCount64 - FUltimaCarga <
           MS_VIGENCIA_BUSQUEDA_STOCK)) then
  begin
    FConsulta.Close;
    FConsulta.SQL.Text := SQL_BUSQUEDA_PADRES_CABECERA;
    if sFiltro <> '' then
      FConsulta.SQL.Add(SQL_BUSQUEDA_PADRES_FILTRO);
    FConsulta.SQL.Add(SQL_BUSQUEDA_PADRES_ORDEN);
    if sFiltro <> '' then
      FConsulta.ParamByName('TPREF').AsString := sFiltro + '%';
    FConsulta.ParamByName('ALM').AsString := sAlmacen;
    FConsulta.Open;
    FUltimoFiltro := sFiltro;
    FUltimoAlmacen := sAlmacen;
    FUltimaCarga := TThread.GetTickCount64;
  end;
end;

procedure TBusquedaArticulosPadreGridUniDAC.Invalidar;
begin
  FUltimoAlmacen := #1;
  FUltimoFiltro := #1;
  if FConsulta.Active then
    FConsulta.Close;
end;

function CrearBusquedaArticulosPadreGridUniDAC(
  AConexion: TUniConnection): IBusquedaSkusTallas;
begin
  Result := TBusquedaArticulosPadreGridUniDAC.Create(AConexion);
end;

end.
