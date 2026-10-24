{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasLecturas                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa las lecturas auxiliares del cálculo de facturas.               }
{******************************************************************************}
unit UniDataFacturasLecturas;

interface

uses
  Uni, inLibFacturasLecturasIntf;

function CrearRepositorioLecturasFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioLecturasFactura;

implementation

uses
  System.SysUtils, Data.DB;

type
  TRepositorioLecturasFacturaUniDAC = class(
    TInterfacedObject,
    IRepositorioLecturasFactura)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function ArticuloDebeMostrarSku(
      const ACodigoArticulo: string): Boolean;
    function ContarLineas(
      const ASerie, ANumero: string): Integer;
    function BuscarConfiguracionIva(
      const AGrupo: string;
      AFecha: TDateTime): TDataSet;
    function BuscarPorcentajeRetencion(
      const ACodigoEmpresa: string;
      AFecha: TDateTime): Currency;
    function BuscarDatosIvaAgricola(
      const ACodigoEmpresa: string;
      AFecha: TDateTime): TDataSet;
    function BuscarClienteConTarifa(
      const ACodigoCliente: string): TDataSet;
    function BuscarEmpresa(
      const ACodigoEmpresa: string): TDataSet;
  end;

constructor TRepositorioLecturasFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioLecturasFacturaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioLecturasFacturaUniDAC.ArticuloDebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := True;
  if ACodigoArticulo <> '' then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT A.ESVARIACION_ART, ' +
        '       (SELECT COUNT(*) FROM fza_articulos_skus S ' +
        '         WHERE S.CODIGO_ART_SKU = A.CODIGO_ART_ART ' +
        '           AND S.ESACTIVO_SKU = ''S'') AS NSKU ' +
        '  FROM fza_articulos A ' +
        ' WHERE A.CODIGO_ART_ART = :art ' +
        ' LIMIT 1';
      Consulta.ParamByName('art').AsString := ACodigoArticulo;
      Consulta.Open;
      Result := Consulta.IsEmpty or
        (Consulta.FieldByName('ESVARIACION_ART').AsString = 'S') or
        (Consulta.FieldByName('NSKU').AsInteger > 1);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TRepositorioLecturasFacturaUniDAC.ContarLineas(
  const ASerie, ANumero: string): Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :numero ' +
      '   AND SERIE_FAC_FACLIN = :serie';
    Consulta.ParamByName('numero').AsString := ANumero;
    Consulta.ParamByName('serie').AsString := ASerie;
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioLecturasFacturaUniDAC.BuscarConfiguracionIva(
  const AGrupo: string;
  AFecha: TDateTime): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT * FROM vi_ivas ' +
      ' WHERE IVA_IVAGRP = :grupo ' +
      '   AND FECHA_DESDE_IVA <= :fecha ' +
      '   AND (FECHA_HASTA_IVA >= :fecha OR FECHA_HASTA_IVA IS NULL)';
    Consulta.ParamByName('grupo').AsString := AGrupo;
    Consulta.ParamByName('fecha').AsDateTime := AFecha;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioLecturasFacturaUniDAC.BuscarPorcentajeRetencion(
  const ACodigoEmpresa: string;
  AFecha: TDateTime): Currency;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT PORCENTAJE_EMPRET ' +
      '  FROM fza_empresas_retenciones ' +
      ' WHERE CODIGO_EMP_EMPRET = :EMP ' +
      '   AND FECHA_DESDE_EMPRET <= :FECHA ' +
      '   AND (FECHA_HASTA_EMPRET >= :FECHA ' +
      '        OR FECHA_HASTA_EMPRET IS NULL) ' +
      ' ORDER BY FECHA_DESDE_EMPRET DESC LIMIT 1';
    Consulta.ParamByName('EMP').AsString := ACodigoEmpresa;
    Consulta.ParamByName('FECHA').AsDateTime := AFecha;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.Fields[0].AsCurrency;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioLecturasFacturaUniDAC.BuscarDatosIvaAgricola(
  const ACodigoEmpresa: string;
  AFecha: TDateTime): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT IVA_IVAGRP, CODIGO_IVA, ' +
      '       PORCENTAJE_NORMAL_IVA, PORCENTAJE_EXENTO_IVA, ' +
      '       PORCENTAJE_REDUCIDO_IVA, ' +
      '       PORCENTAJE_SUPERREDUCIDO_IVA ' +
      '  FROM vi_ivas_empresa ' +
      ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = ''S'' ' +
      '   AND CODIGO_EMP_EMP = :EMP ' +
      '   AND FECHA_DESDE_IVA <= :FECHA ' +
      '   AND (FECHA_HASTA_IVA IS NULL ' +
      '        OR FECHA_HASTA_IVA >= :FECHA)';
    Consulta.ParamByName('EMP').AsString := ACodigoEmpresa;
    Consulta.ParamByName('FECHA').AsDateTime := AFecha;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioLecturasFacturaUniDAC.BuscarClienteConTarifa(
  const ACodigoCliente: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      '    SELECT * ' +
      '      FROM fza_clientes ' +
      ' LEFT JOIN fza_tarifas ' +
      '        ON fza_clientes.TARIFA_ARTICULO_CLI = ' +
      '           fza_tarifas.CODIGO_TAR_ARTTAR ' +
      '     WHERE CODIGO_CLI_CLI = :cliente';
    Consulta.ParamByName('cliente').AsString := ACodigoCliente;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioLecturasFacturaUniDAC.BuscarEmpresa(
  const ACodigoEmpresa: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_empresas ' +
      ' WHERE CODIGO_EMP_EMP = :empresa';
    Consulta.ParamByName('empresa').AsString := ACodigoEmpresa;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioLecturasFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioLecturasFactura;
begin
  Result := TRepositorioLecturasFacturaUniDAC.Create(AConexion);
end;

end.
