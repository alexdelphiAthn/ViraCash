{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataPrincipalCertificadosRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Lectura de certificados de empresa para los avisos de la pantalla         }
{    principal.                                                                }
{******************************************************************************}
unit UniDataPrincipalCertificadosRepositorio;

interface

uses
  Uni,
  inLibPrincipalCertificadosIntf;

function CrearRepositorioCertificadosEmpresasUniDAC(
  AConexion: TUniConnection): IRepositorioCertificadosEmpresas;

implementation

uses
  System.Classes,
  Data.DB;

type
  TRepositorioCertificadosEmpresasUniDAC = class(
    TInterfacedObject,
    IRepositorioCertificadosEmpresas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarActivos: TCertificadosEmpresasActivos;
  end;

const
  SQL_CERTIFICADOS_EMPRESAS_ACTIVAS =
    'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, ' +
    '       CODIGO_CERTIFICADO_EMP, TITULAR_CERTIFICADO_EMP, ' +
    '       FECHA_HASTA_CERTIFICADO_EMP ' +
    '  FROM fza_empresas ' +
    ' WHERE IFNULL(ESACTIVO_EMP, ''S'') = ''S'' ' +
    '   AND IFNULL(CODIGO_CERTIFICADO_EMP, '''') <> '''' ' +
    ' ORDER BY ORDEN_EMP, CODIGO_EMP_EMP';

constructor TRepositorioCertificadosEmpresasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioCertificadosEmpresasUniDAC.ListarActivos:
  TCertificadosEmpresasActivos;
var
  Consulta: TUniQuery;
  Certificado: TCertificadoEmpresaActivo;
  Indice: Integer;
begin
  SetLength(Result, 0);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_CERTIFICADOS_EMPRESAS_ACTIVAS;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Certificado.CodigoEmpresa :=
        Consulta.FieldByName('CODIGO_EMP_EMP').AsString;
      Certificado.Empresa :=
        Consulta.FieldByName('RAZON_SOCIAL_EMP').AsString;
      Certificado.Serie :=
        Consulta.FieldByName('CODIGO_CERTIFICADO_EMP').AsString;
      Certificado.Titular :=
        Consulta.FieldByName('TITULAR_CERTIFICADO_EMP').AsString;
      Certificado.TieneFechaHasta := not Consulta.FieldByName(
        'FECHA_HASTA_CERTIFICADO_EMP').IsNull;
      Certificado.FechaHasta := 0;
      if Certificado.TieneFechaHasta then
        Certificado.FechaHasta := Consulta.FieldByName(
          'FECHA_HASTA_CERTIFICADO_EMP').AsDateTime;
      Indice := Length(Result);
      SetLength(Result, Indice + 1);
      Result[Indice] := Certificado;
      Consulta.Next;
    end;
  finally
    Consulta.Free;
  end;
end;

function CrearRepositorioCertificadosEmpresasUniDAC(
  AConexion: TUniConnection): IRepositorioCertificadosEmpresas;
begin
  Result := TRepositorioCertificadosEmpresasUniDAC.Create(AConexion);
end;

end.
