{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDestinoEnvioRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del selector de destino de documentos.                }
{******************************************************************************}
unit UniDataDestinoEnvioRepositorio;

interface

uses
  Uni, inLibDestinoEnvioPersistenciaIntf;

function CrearRepositorioDestinoEnvioUniDAC(
  AConexion: TUniConnection): IRepositorioDestinoEnvio;

implementation

uses
  System.SysUtils;

const
  SQL_LISTAR_ALMACENES =
    'SELECT CODIGO_ALM_ALM FROM fza_almacenes ' +
    'WHERE (:EMP = '''' OR CODIGO_EMP_ALM = :EMP) ' +
    'ORDER BY CODIGO_ALM_ALM';
  SQL_LISTAR_SERIES =
    'SELECT EMPSER FROM vi_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP ' +
    'AND TIPO_DOC_EMPSER = :TIPO ' +
    'AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= NOW()) ' +
    'AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= NOW()) ' +
    'ORDER BY ESDEFECTO_EMPSER DESC, EMPSER';

type
  TRepositorioDestinoEnvioUniDAC = class(
    TInterfacedObject,
    IRepositorioDestinoEnvio)
  private
    FConexion: TUniConnection;
    function ListarValores(
      const ASql: string;
      const ACampo: string;
      const AEmpresa: string;
      const ATipoDocumento: string = ''): TValoresDestinoEnvio;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarAlmacenes(
      const AEmpresa: string): TValoresDestinoEnvio;
    function ListarSeries(
      const AEmpresa: string;
      const ATipoDocumento: string): TValoresDestinoEnvio;
  end;

constructor TRepositorioDestinoEnvioUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDestinoEnvioUniDAC.ListarValores(
  const ASql: string;
  const ACampo: string;
  const AEmpresa: string;
  const ATipoDocumento: string): TValoresDestinoEnvio;
var
  iValor: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    if ATipoDocumento <> '' then
    begin
      oConsulta.ParamByName('TIPO').AsString := ATipoDocumento;
    end;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iValor := Length(Result);
      SetLength(Result, iValor + 1);
      Result[iValor] := oConsulta.FieldByName(ACampo).AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDestinoEnvioUniDAC.ListarAlmacenes(
  const AEmpresa: string): TValoresDestinoEnvio;
begin
  Result := ListarValores(
    SQL_LISTAR_ALMACENES,
    'CODIGO_ALM_ALM',
    AEmpresa);
end;

function TRepositorioDestinoEnvioUniDAC.ListarSeries(
  const AEmpresa: string;
  const ATipoDocumento: string): TValoresDestinoEnvio;
begin
  Result := ListarValores(
    SQL_LISTAR_SERIES,
    'EMPSER',
    AEmpresa,
    ATipoDocumento);
end;

function CrearRepositorioDestinoEnvioUniDAC(
  AConexion: TUniConnection): IRepositorioDestinoEnvio;
begin
  Result := TRepositorioDestinoEnvioUniDAC.Create(AConexion);
end;

end.
