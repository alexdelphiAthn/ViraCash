{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataSeleccionBancoEmpresaRepositorio                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Lectura UniDAC de las cuentas bancarias activas de una empresa.          }
{******************************************************************************}
unit UniDataSeleccionBancoEmpresaRepositorio;

interface

uses
  Uni, inLibSeleccionBancoEmpresaPersistenciaIntf;

function CrearRepositorioSeleccionBancoEmpresaUniDAC(
  AConexion: TUniConnection): IRepositorioSeleccionBancoEmpresa;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_CUENTAS_COBRO =
    'SELECT * FROM vi_empresas_bancos ' +
    'WHERE CODIGO_EMP_EMPBAN = :emp ' +
    'AND COALESCE(ESACTIVO_EMPBAN, ''S'') = ''S'' ' +
    'ORDER BY ESDEFECTO_COBRO_EMPBAN DESC, NOMBRE_EMPBAN';
  SQL_CUENTAS_PAGO =
    'SELECT * FROM vi_empresas_bancos ' +
    'WHERE CODIGO_EMP_EMPBAN = :emp ' +
    'AND COALESCE(ESACTIVO_EMPBAN, ''S'') = ''S'' ' +
    'ORDER BY ESDEFECTO_PAGO_EMPBAN DESC, NOMBRE_EMPBAN';

type
  TConsultaBancosEmpresaUniDAC = class(
    TInterfacedObject,
    IConsultaBancosEmpresa)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioSeleccionBancoEmpresaUniDAC = class(
    TInterfacedObject,
    IRepositorioSeleccionBancoEmpresa)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarCuentas(
      const ACodigoEmpresa: string;
      AUso: TUsoBancoEmpresa): IConsultaBancosEmpresa;
  end;

constructor TConsultaBancosEmpresaUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaBancosEmpresaUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaBancosEmpresaUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioSeleccionBancoEmpresaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioSeleccionBancoEmpresaUniDAC.ConsultarCuentas(
  const ACodigoEmpresa: string;
  AUso: TUsoBancoEmpresa): IConsultaBancosEmpresa;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    if AUso = ubePago then
      Consulta.SQL.Text := SQL_CUENTAS_PAGO
    else
      Consulta.SQL.Text := SQL_CUENTAS_COBRO;
    Consulta.ParamByName('emp').AsString := ACodigoEmpresa;
    Consulta.Open;
    Result := TConsultaBancosEmpresaUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function CrearRepositorioSeleccionBancoEmpresaUniDAC(
  AConexion: TUniConnection): IRepositorioSeleccionBancoEmpresa;
begin
  Result := TRepositorioSeleccionBancoEmpresaUniDAC.Create(AConexion);
end;

end.
