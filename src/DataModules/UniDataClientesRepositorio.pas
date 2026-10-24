{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataClientesRepositorio                                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para operaciones propias de clientes.                }
{******************************************************************************}
unit UniDataClientesRepositorio;

interface

uses
  Uni, inLibClientesPersistenciaIntf;

function CrearRepositorioClientesUniDAC(
  AConexion: TUniConnection): IRepositorioClientes;
// True si el código está en fza_clientes. Vacío y «0» (sin cliente) no.
function ExisteClienteCodigo(AConexion: TUniConnection;
  const ACodigo: string): Boolean;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_CONTAR_DOCUMENTOS =
    'SELECT (SELECT COUNT(*) FROM fza_facturas ' +
    'WHERE CODIGO_CLI_FAC = :pCli) ' +
    '+ (SELECT COUNT(*) FROM fza_albaranes ' +
    'WHERE CODIGO_CLI_ALB = :pCli) AS N';
  SQL_EXISTE_CLIENTE =
    'SELECT 1 FROM fza_clientes WHERE CODIGO_CLI_CLI = :pCli LIMIT 1';

type
  TRepositorioClientesUniDAC = class(
    TInterfacedObject,
    IRepositorioClientes)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ContarDocumentos(const ACodigoCliente: string): Integer;
  end;

constructor TRepositorioClientesUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioClientesUniDAC.ContarDocumentos(
  const ACodigoCliente: string): Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_CONTAR_DOCUMENTOS;
    Consulta.ParamByName('pCli').AsString := ACodigoCliente;
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioClientesUniDAC(
  AConexion: TUniConnection): IRepositorioClientes;
begin
  Result := TRepositorioClientesUniDAC.Create(AConexion);
end;

function ExisteClienteCodigo(AConexion: TUniConnection;
  const ACodigo: string): Boolean;
var
  Consulta: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text := SQL_EXISTE_CLIENTE;
      Consulta.ParamByName('pCli').AsString := sCodigo;
      Consulta.Open;
      Result := not Consulta.IsEmpty;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

end.
