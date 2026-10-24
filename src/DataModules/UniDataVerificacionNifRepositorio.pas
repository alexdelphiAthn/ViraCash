{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerificacionNifRepositorio                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia de la verificación de NIF en la AEAT: certificado de la      }
{    empresa y resultado guardado en el cliente. Compone el servicio con el    }
{    transporte de la AEAT. FZ-ISSUE-131.                                      }
{******************************************************************************}
unit UniDataVerificacionNifRepositorio;

interface

uses
  Uni, inLibVerificacionNifIntf;

// AConexion: la de la ventana que verifica, para no bloquearse con su
// propia edición del cliente.
function CrearRepositorioVerificacionNifUniDAC(
  AConexion: TUniConnection): IRepositorioVerificacionNif;
function CrearServicioVerificacionNifAeat(
  AConexion: TUniConnection;
  const AUrl: string): IServicioVerificacionNif;
// ISO alfa-2 de fza_paises ('' si no existe): país del NIF-IVA en VIES.
function LeerCodigoAlpha2PaisVerificacion(
  AConexion: TUniConnection;
  const ACodigoPais: string): string;
// Resultado de la consulta ROI (VIES) en el cliente.
procedure GuardarResultadoVerificacionCliente(
  AConexion: TUniConnection;
  const ACodigoCliente, AResultado: string);

implementation

uses
  System.SysUtils, Data.DB,
  inLibVerificacionNif, inLibVerificacionNifAeat;

type
  TRepositorioVerificacionNifUniDAC = class(
    TInterfacedObject,
    IRepositorioVerificacionNif)
  private
    FConexion: TUniConnection;
    function ColumnasResultadoAplicadas: Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function LeerCertificadoEmpresa(
      const ACodigoEmpresa: string): TCertificadoVerificacionNif;
    procedure GuardarResultadoCliente(
      const ACodigoCliente, AResultado: string);
  end;

constructor TRepositorioVerificacionNifUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioVerificacionNifUniDAC.LeerCertificadoEmpresa(
  const ACodigoEmpresa: string): TCertificadoVerificacionNif;
var
  Qry: TUniQuery;
begin
  Result := Default(TCertificadoVerificacionNif);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'SELECT E.CODIGO_CERTIFICADO_EMP, ' +
      '       E.TITULAR_CERTIFICADO_EMP ' +
      '  FROM fza_empresas E ' +
      ' WHERE E.CODIGO_EMP_EMP = :EMPRESA';
    Qry.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.Serie :=
        Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
      Result.Titular :=
        Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

// Las columnas llegan con 20261002_clientes_verificacion_nif.sql.
function TRepositorioVerificacionNifUniDAC.ColumnasResultadoAplicadas:
  Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM INFORMATION_SCHEMA.COLUMNS C ' +
      ' WHERE C.TABLE_SCHEMA = DATABASE() ' +
      '   AND C.TABLE_NAME = ''fza_clientes'' ' +
      '   AND C.COLUMN_NAME IN (''RESULTADO_VERIFICACION_NIF_CLI'', ' +
      '                         ''INSTANTE_VERIFICACION_NIF_CLI'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 2;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioVerificacionNifUniDAC.GuardarResultadoCliente(
  const ACodigoCliente, AResultado: string);
var
  Qry: TUniQuery;
begin
  if ColumnasResultadoAplicadas then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        'UPDATE fza_clientes ' +
        '   SET RESULTADO_VERIFICACION_NIF_CLI = :RESULTADO, ' +
        '       INSTANTE_VERIFICACION_NIF_CLI = NOW() ' +
        ' WHERE CODIGO_CLI_CLI = :CLIENTE';
      Qry.ParamByName('RESULTADO').AsString := Copy(AResultado, 1, 60);
      Qry.ParamByName('CLIENTE').AsString := ACodigoCliente;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function CrearRepositorioVerificacionNifUniDAC(
  AConexion: TUniConnection): IRepositorioVerificacionNif;
begin
  Result := TRepositorioVerificacionNifUniDAC.Create(AConexion);
end;

function CrearServicioVerificacionNifAeat(
  AConexion: TUniConnection;
  const AUrl: string): IServicioVerificacionNif;
begin
  Result := CrearServicioVerificacionNif(
    CrearRepositorioVerificacionNifUniDAC(AConexion),
    CrearTransporteVerificacionNifAeat(AUrl));
end;

function LeerCodigoAlpha2PaisVerificacion(
  AConexion: TUniConnection;
  const ACodigoPais: string): string;
var
  Qry: TUniQuery;
begin
  Result := '';
  if Trim(ACodigoPais) <> '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConexion;
      Qry.SQL.Text :=
        'SELECT P.COD_ALPHA2_PAI ' +
        '  FROM fza_paises P ' +
        'WHERE P.CODIGO_PAI_PAI = TRIM(:PAIS) ' +
        'OR P.COD_ALPHA2_PAI = UPPER(TRIM(:PAIS))';
      Qry.ParamByName('PAIS').AsString := Trim(ACodigoPais);
      Qry.Open;
      if not Qry.IsEmpty then
        Result := Trim(Qry.FieldByName('COD_ALPHA2_PAI').AsString);
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure GuardarResultadoVerificacionCliente(
  AConexion: TUniConnection;
  const ACodigoCliente, AResultado: string);
begin
  if (Trim(ACodigoCliente) <> '') and (AResultado <> '') then
    CrearRepositorioVerificacionNifUniDAC(AConexion).
      GuardarResultadoCliente(Trim(ACodigoCliente), AResultado);
end;

end.
