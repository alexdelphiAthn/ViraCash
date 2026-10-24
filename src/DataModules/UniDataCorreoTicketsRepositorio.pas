{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCorreoTicketsRepositorio                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de datos validados para correo de operaciones.           }
{******************************************************************************}
unit UniDataCorreoTicketsRepositorio;

interface

uses
  Uni, inLibCorreoTicketsLecturasIntf;

function CrearCorreoTicketsLecturas(
  AConexion: TUniConnection): ICorreoTicketsLecturas;

implementation

uses
  System.SysUtils, inLibCorreoTickets;

type
  TCorreoTicketsLecturas = class(
    TInterfacedObject,
    ICorreoTicketsLecturas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CargarDatosOperacion(const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string): TDatosCorreoOperacion;
    function NombreEmpresa(const AEmpresa: string): string;
  end;

function CrearCorreoTicketsLecturas(
  AConexion: TUniConnection): ICorreoTicketsLecturas;
begin
  Result := TCorreoTicketsLecturas.Create(AConexion);
end;

constructor TCorreoTicketsLecturas.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TCorreoTicketsLecturas.CargarDatosOperacion(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string): TDatosCorreoOperacion;
var
  oConsulta: TUniQuery;
  sTipos: string;
begin
  Result := Default(TDatosCorreoOperacion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS NUM_FILAS,' +
      '       MAX(COALESCE(NULLIF(f.CODIGO_CLI_FAC, ''''),' +
      '                    NULLIF(o.CODIGO_CLI_OPCAJA, ''''))) ' +
      '         AS CODIGO_CLIENTE,' +
      '       MAX(cli.EMAIL_CLI) AS EMAIL_CLIENTE,' +
      '       MAX(emp.RAZON_SOCIAL_EMP) AS NOMBRE_EMPRESA,' +
      '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA ' +
      '         SEPARATOR '','') AS TIPOS_OPERACION,' +
      '       SUM(CASE WHEN f.NUMERO_FAC IS NULL THEN 0 ELSE 1 END) ' +
      '         AS NUM_FACTURAS,' +
      '       (SELECT COUNT(*) FROM fza_caja_depositos_view d' +
      '         WHERE d.CODIGO_EMPRESA_OP = :EMP' +
      '           AND d.CODIGO_ALMACEN_OP = :ALM' +
      '           AND d.CODIGO_CAJA_OP = :CAJA' +
      '           AND d.NUMERO_OPERACION_OP = :OPERACION) ' +
      '         AS NUM_DEPOSITOS' +
      '  FROM fza_caja_operaciones o' +
      '  LEFT JOIN fza_facturas f' +
      '    ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA' +
      '   AND ((TRIM(COALESCE(o.SERIE_FAC_OPCAJA, '''')) <> ''''' +
      '         AND TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, '''')) <> ''''' +
      '         AND f.SERIE_FAC = o.SERIE_FAC_OPCAJA' +
      '         AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA)' +
      '     OR ((TRIM(COALESCE(o.SERIE_FAC_OPCAJA, '''')) = ''''' +
      '          OR TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, '''')) = '''')' +
      '         AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA' +
      '         AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA' +
      '         AND f.NUMERO_OPERACION_FAC = ' +
      '             o.NUMERO_OPERACION_OPCAJA))' +
      '  LEFT JOIN fza_clientes cli' +
      '    ON cli.CODIGO_CLI_CLI = COALESCE(NULLIF(' +
      '      f.CODIGO_CLI_FAC, ''''), o.CODIGO_CLI_OPCAJA)' +
      '  LEFT JOIN fza_empresas emp' +
      '    ON emp.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA' +
      ' WHERE o.CODIGO_EMP_OPCAJA = :EMP' +
      '   AND o.CODIGO_ALM_OPCAJA = :ALM' +
      '   AND o.CODIGO_CAJA_OPCAJA = :CAJA' +
      '   AND o.NUMERO_OPERACION_OPCAJA = :OPERACION';
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ACaja;
    oConsulta.ParamByName('OPERACION').AsString := ANumeroOperacion;
    oConsulta.Open;
    Result.Encontrada :=
      oConsulta.FieldByName('NUM_FILAS').AsInteger > 0;
    if Result.Encontrada then
    begin
      Result.CodigoCliente :=
        oConsulta.FieldByName('CODIGO_CLIENTE').AsString;
      Result.EmailCliente := Trim(
        oConsulta.FieldByName('EMAIL_CLIENTE').AsString);
      Result.NombreEmpresa := Trim(
        oConsulta.FieldByName('NOMBRE_EMPRESA').AsString);
      Result.TieneFactura :=
        oConsulta.FieldByName('NUM_FACTURAS').AsInteger > 0;
      Result.TieneDepositos :=
        oConsulta.FieldByName('NUM_DEPOSITOS').AsInteger > 0;
      sTipos := ',' +
        oConsulta.FieldByName('TIPOS_OPERACION').AsString + ',';
      Result.EsOperacionCaja := (Pos(',EC,', sTipos) > 0) or
        (Pos(',GC,', sTipos) > 0);
      Result.EsTraspaso := (Pos(',TR,', sTipos) > 0) or
        (Pos(',TA,', sTipos) > 0);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCorreoTicketsLecturas.NombreEmpresa(
  const AEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT RAZON_SOCIAL_EMP FROM fza_empresas' +
      ' WHERE CODIGO_EMP_EMP = :EMP';
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.Open;
    if not oConsulta.Eof then
      Result := Trim(oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
