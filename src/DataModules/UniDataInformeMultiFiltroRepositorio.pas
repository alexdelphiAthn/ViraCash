{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataInformeMultiFiltroRepositorio                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Lecturas UniDAC de los filtros compartidos por informes multiples.       }
{******************************************************************************}
unit UniDataInformeMultiFiltroRepositorio;

interface

uses
  Uni, inLibInformeMultiFiltroPersistenciaIntf;

function CrearRepositorioInformeMultiFiltroUniDAC(
  AConexion: TUniConnection): IRepositorioInformeMultiFiltro;

implementation

uses
  System.SysUtils;

const
  SQL_ALMACENES =
    'SELECT CODIGO_ALM_ALM AS COD, NOMBRE_ALM_ALM AS NOM ' +
    'FROM fza_almacenes ' +
    'WHERE ESACTIVO_ALM = ''S'' ' +
    'ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
  SQL_FAMILIAS =
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    'COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, ' +
    'CODIGO_FAM_FAM) AS NOM, ' +
    'COALESCE(CODIGO_PADRE_FAM, '''') AS PADRE ' +
    'FROM fza_articulos_familias ' +
    'WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    'ORDER BY ORDEN_FAM, CODIGO_FAM_FAM';
  SQL_PROVEEDORES_ARTICULOS =
    'SELECT p.CODIGO_PRV_PRV AS COD, p.RAZON_SOCIAL_PRV AS NOM ' +
    'FROM fza_proveedores p ' +
    'WHERE EXISTS (SELECT 1 FROM fza_articulos_proveedores ap ' +
    'WHERE ap.CODIGO_PRV_AP = p.CODIGO_PRV_PRV) ' +
    'ORDER BY p.RAZON_SOCIAL_PRV, p.CODIGO_PRV_PRV';
  SQL_PROVEEDORES_EFECTOS_PAGO =
    'SELECT e.CODIGO_PRV_EFEC AS COD, ' +
    'COALESCE(NULLIF(MAX(e.RAZON_SOCIAL_PRV_EFEC), ''''), ' +
    'e.CODIGO_PRV_EFEC) AS NOM ' +
    'FROM fza_efectos_compra e ' +
    'WHERE COALESCE(e.CODIGO_PRV_EFEC, '''') <> '''' ' +
    'GROUP BY e.CODIGO_PRV_EFEC ' +
    'ORDER BY NOM, e.CODIGO_PRV_EFEC';
  SQL_PROVEEDORES_DOCUMENTOS =
    'SELECT P.CODIGO_PRV_PRV AS COD, P.RAZON_SOCIAL_PRV AS NOM ' +
    'FROM fza_proveedores P ' +
    'WHERE EXISTS (SELECT 1 FROM fza_pedidos_compra D ' +
    'WHERE D.CODIGO_PRV_PEDC = P.CODIGO_PRV_PRV) ' +
    'OR EXISTS (SELECT 1 FROM fza_albaranes_compra D ' +
    'WHERE D.CODIGO_PRV_ALBC = P.CODIGO_PRV_PRV) ' +
    'OR EXISTS (SELECT 1 FROM fza_facturas_compra D ' +
    'WHERE D.CODIGO_PRV_FACC = P.CODIGO_PRV_PRV) ' +
    'OR EXISTS (SELECT 1 FROM fza_devoluciones_compra D ' +
    'WHERE D.CODIGO_PRV_DEVC = P.CODIGO_PRV_PRV) ' +
    'ORDER BY P.RAZON_SOCIAL_PRV, P.CODIGO_PRV_PRV';
  SQL_TEMPORADAS =
    'SELECT PV AS COD, PV AS NOM ' +
    'FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    'AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    'ORDER BY PV';
  SQL_ARTICULOS =
    'SELECT CODIGO_ART_ART AS COD, DESCRIPCION_ART AS NOM ' +
    'FROM fza_articulos ' +
    'WHERE ESACTIVO_ART = ''S'' ' +
    'ORDER BY CODIGO_ART_ART';

type
  TRepositorioInformeMultiFiltroUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeMultiFiltro)
  private
    FConexion: TUniConnection;
    function LeerOpciones(
      AConsulta: TUniQuery): TOpcionesInformeMultiFiltro;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarAlmacenes: TOpcionesInformeMultiFiltro;
    function ListarFamilias: TFamiliasInformeMultiFiltro;
    function ListarProveedores(
      AOrigen: TOrigenProveedoresInformeMultiFiltro
    ): TOpcionesInformeMultiFiltro;
    function ListarTemporadas: TOpcionesInformeMultiFiltro;
    function ListarArticulos: TOpcionesInformeMultiFiltro;
  end;

constructor TRepositorioInformeMultiFiltroUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeMultiFiltroUniDAC.LeerOpciones(
  AConsulta: TUniQuery): TOpcionesInformeMultiFiltro;
var
  iOpcion: Integer;
begin
  SetLength(Result, 0);
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    iOpcion := Length(Result);
    SetLength(Result, iOpcion + 1);
    Result[iOpcion].Codigo := AConsulta.FieldByName('COD').AsString;
    Result[iOpcion].Nombre := AConsulta.FieldByName('NOM').AsString;
    AConsulta.Next;
  end;
end;

function TRepositorioInformeMultiFiltroUniDAC.ListarAlmacenes:
  TOpcionesInformeMultiFiltro;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ALMACENES;
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeMultiFiltroUniDAC.ListarFamilias:
  TFamiliasInformeMultiFiltro;
var
  iFamilia: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_FAMILIAS;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFamilia := Length(Result);
      SetLength(Result, iFamilia + 1);
      Result[iFamilia].Codigo := oConsulta.FieldByName('COD').AsString;
      Result[iFamilia].Nombre := oConsulta.FieldByName('NOM').AsString;
      Result[iFamilia].CodigoPadre :=
        oConsulta.FieldByName('PADRE').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeMultiFiltroUniDAC.ListarProveedores(
  AOrigen: TOrigenProveedoresInformeMultiFiltro
): TOpcionesInformeMultiFiltro;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    case AOrigen of
      opmfEfectosPago:
        oConsulta.SQL.Text := SQL_PROVEEDORES_EFECTOS_PAGO;
      opmfDocumentosProveedor:
        oConsulta.SQL.Text := SQL_PROVEEDORES_DOCUMENTOS;
    else
      oConsulta.SQL.Text := SQL_PROVEEDORES_ARTICULOS;
    end;
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeMultiFiltroUniDAC.ListarTemporadas:
  TOpcionesInformeMultiFiltro;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_TEMPORADAS;
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeMultiFiltroUniDAC.ListarArticulos:
  TOpcionesInformeMultiFiltro;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ARTICULOS;
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioInformeMultiFiltroUniDAC(
  AConexion: TUniConnection): IRepositorioInformeMultiFiltro;
begin
  Result := TRepositorioInformeMultiFiltroUniDAC.Create(AConexion);
end;

end.
