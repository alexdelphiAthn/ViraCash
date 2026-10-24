{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEnvioErroresEmpresaRepositorio                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Obtiene los datos de empresa que acompañan a una incidencia de soporte.  }
{******************************************************************************}
unit UniDataEnvioErroresEmpresaRepositorio;

interface

uses
  Uni,
  inLibEnvioErroresIntf;

function CrearRepositorioDatosEmpresaError(
  AConexion: TUniConnection
): IRepositorioDatosEmpresaError;

implementation

uses
  System.SysUtils;

type
  TRepositorioDatosEmpresaErrorUniDAC = class(
    TInterfacedObject,
    IRepositorioDatosEmpresaError)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Obtener(
      const ACodigoEmpresa: string): TDatosEmpresaError;
  end;

constructor TRepositorioDatosEmpresaErrorUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioDatosEmpresaErrorUniDAC.Obtener(
  const ACodigoEmpresa: string): TDatosEmpresaError;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TDatosEmpresaError);
  if Trim(ACodigoEmpresa) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT RAZON_SOCIAL_EMP, NIF_EMP, ' +
        '       NUMERO_INSTALACION_EMP, CODIGO_SIF_INSTALACION_EMP, ' +
        '       VERSION_INSTALACION_EMP, DIRECCION1_EMP, ' +
        '       DIRECCION2_EMP, CODIGO_POSTAL_EMP, POBLACION_EMP, ' +
        '       PROVINCIA_EMP, MOVIL_EMP ' +
        '  FROM fza_empresas ' +
        ' WHERE CODIGO_EMP_EMP = :EMPRESA ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
      oConsulta.Open;
      if not oConsulta.Eof then
      begin
        Result.RazonSocial := Trim(
          oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString);
        Result.Nif := Trim(
          oConsulta.FieldByName('NIF_EMP').AsString);
        Result.NumeroInstalacionSif := Trim(
          oConsulta.FieldByName('NUMERO_INSTALACION_EMP').AsString);
        Result.CodigoSif := Trim(
          oConsulta.FieldByName(
            'CODIGO_SIF_INSTALACION_EMP').AsString);
        Result.VersionSif := Trim(
          oConsulta.FieldByName('VERSION_INSTALACION_EMP').AsString);
        Result.Direccion1 := Trim(
          oConsulta.FieldByName('DIRECCION1_EMP').AsString);
        Result.Direccion2 := Trim(
          oConsulta.FieldByName('DIRECCION2_EMP').AsString);
        Result.CodigoPostal := Trim(
          oConsulta.FieldByName('CODIGO_POSTAL_EMP').AsString);
        Result.Poblacion := Trim(
          oConsulta.FieldByName('POBLACION_EMP').AsString);
        Result.Provincia := Trim(
          oConsulta.FieldByName('PROVINCIA_EMP').AsString);
        Result.Telefono := Trim(
          oConsulta.FieldByName('MOVIL_EMP').AsString);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearRepositorioDatosEmpresaError(
  AConexion: TUniConnection
): IRepositorioDatosEmpresaError;
begin
  Result := TRepositorioDatosEmpresaErrorUniDAC.Create(AConexion);
end;

end.
