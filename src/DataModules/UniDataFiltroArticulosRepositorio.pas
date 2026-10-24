{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFiltroArticulosRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del catalogo usado para acotar articulos.             }
{******************************************************************************}
unit UniDataFiltroArticulosRepositorio;

interface

uses
  Uni, inLibFiltroArticulosPersistenciaIntf;

function CrearRepositorioFiltroArticulosUniDAC(
  AConexion: TUniConnection): IRepositorioFiltroArticulos;

implementation

uses
  System.SysUtils;

const
  SQL_LISTAR_TEMPORADAS =
    'SELECT PV FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = ''TEMPORADA'' AND ESACTIVO_PV = ''S'' ' +
    'ORDER BY PV';
  SQL_LISTAR_PROVEEDORES =
    'SELECT CODIGO_PRV_PRV, ' +
    'COALESCE(NULLIF(RAZON_SOCIAL_PRV, ''''), NOMBRE_PRV, ' +
    'CODIGO_PRV_PRV) AS NOM FROM fza_proveedores ' +
    'WHERE ESACTIVO_PRV = ''S'' ORDER BY NOM, CODIGO_PRV_PRV';

type
  TRepositorioFiltroArticulosUniDAC = class(
    TInterfacedObject,
    IRepositorioFiltroArticulos)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarTemporadas: TTemporadasFiltroArticulos;
    function ListarProveedores: TProveedoresFiltroArticulos;
  end;

constructor TRepositorioFiltroArticulosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFiltroArticulosUniDAC.ListarTemporadas:
  TTemporadasFiltroArticulos;
var
  iTemporada: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_TEMPORADAS;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iTemporada := Length(Result);
      SetLength(Result, iTemporada + 1);
      Result[iTemporada] := oConsulta.FieldByName('PV').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFiltroArticulosUniDAC.ListarProveedores:
  TProveedoresFiltroArticulos;
var
  iProveedor: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_PROVEEDORES;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iProveedor := Length(Result);
      SetLength(Result, iProveedor + 1);
      Result[iProveedor].Codigo :=
        oConsulta.FieldByName('CODIGO_PRV_PRV').AsString;
      Result[iProveedor].Nombre :=
        oConsulta.FieldByName('NOM').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioFiltroArticulosUniDAC(
  AConexion: TUniConnection): IRepositorioFiltroArticulos;
begin
  Result := TRepositorioFiltroArticulosUniDAC.Create(AConexion);
end;

end.
