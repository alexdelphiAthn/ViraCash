{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuNoVerifactuExport                             }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa las lecturas para exportar registros NO VERI*FACTU.            }
{******************************************************************************}
unit UniDataVerifactuNoVerifactuExport;

interface

uses
  Uni, inLibVerifactuNoVerifactuExportIntf;

function CrearRepositorioExportacionNoVerifactuUniDAC(
  AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;

implementation

uses
  System.SysUtils, Data.DB;

type
  TRepositorioExportacionNoVerifactuUniDAC = class(
    TInterfacedObject,
    IRepositorioExportacionNoVerifactu)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function ColumnasFirmaEventosDisponibles: Boolean;
    function ColumnasFirmaFacturacionDisponibles: Boolean;
    function ContarEventosSinFirma: Integer;
    function ContarFacturasSinFirma: Integer;
    function BuscarEventos: TDataSet;
    function BuscarFacturacion: TDataSet;
  end;

constructor TRepositorioExportacionNoVerifactuUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioExportacionNoVerifactuUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioExportacionNoVerifactuUniDAC.
  ColumnasFirmaEventosDisponibles: Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_verifactu_eventos'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_LOG'', ' +
      '       ''FIRMA_XADES_LOG'', ''SERIE_CERTIFICADO_LOG'', ' +
      '       ''TITULAR_CERTIFICADO_LOG'', ''HUELLA_CERTIFICADO_LOG'')';
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioExportacionNoVerifactuUniDAC.
  ColumnasFirmaFacturacionDisponibles: Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_facturas_consolidaciones'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_FACCON'', ' +
      '       ''FIRMA_DIGITAL_FACCON'', ''SERIE_CERTIFICADO_FACCON'', ' +
      '       ''TITULAR_CERTIFICADO_FACCON'', ' +
      '       ''HUELLA_CERTIFICADO_FACCON'')';
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioExportacionNoVerifactuUniDAC.
  ContarEventosSinFirma: Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM fza_verifactu_eventos ' +
      ' WHERE IFNULL(REGISTRO_XML_LOG, '''') = '''' ' +
      '    OR IFNULL(FIRMA_DIGITAL_LOG, '''') = '''' ' +
      '    OR IFNULL(FIRMA_XADES_LOG, '''') = '''' ' +
      '    OR IFNULL(SERIE_CERTIFICADO_LOG, '''') = '''' ' +
      '    OR IFNULL(TITULAR_CERTIFICADO_LOG, '''') = '''' ' +
      '    OR IFNULL(HUELLA_CERTIFICADO_LOG, '''') = '''' ';
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioExportacionNoVerifactuUniDAC.
  ContarFacturasSinFirma: Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM fza_facturas_consolidaciones ' +
      ' WHERE IFNULL(REGISTRO_XML_FACCON, '''') = '''' ' +
      '    OR IFNULL(FIRMA_DIGITAL_FACCON, '''') = '''' ' +
      '    OR IFNULL(SERIE_CERTIFICADO_FACCON, '''') = '''' ' +
      '    OR IFNULL(TITULAR_CERTIFICADO_FACCON, '''') = '''' ' +
      '    OR IFNULL(HUELLA_CERTIFICADO_FACCON, '''') = '''' ';
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioExportacionNoVerifactuUniDAC.BuscarEventos:
  TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT ID_LOG, TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, ' +
      '        VERSION_LOG, DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, ' +
      '        HASH_ANTERIOR_LOG, HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, ' +
      '        SERIE_FAC_LOG, NUMERO_FAC_LOG, REGISTRO_XML_LOG, ' +
      '        FIRMA_XADES_LOG, SERIE_CERTIFICADO_LOG, ' +
      '        TITULAR_CERTIFICADO_LOG, HUELLA_CERTIFICADO_LOG ' +
      ' FROM fza_verifactu_eventos ' +
      ' ORDER BY ID_LOG';
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioExportacionNoVerifactuUniDAC.BuscarFacturacion:
  TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT fc.ID_FACCON, fc.SERIE_FAC_FACCON, ' +
      '        fc.NUMERO_FAC_FACCON, ' +
      '        fc.REQUEST_ID_CONSOLIDACION_FACCON, ' +
      '        fc.QUEUE_ID_CONSOLIDACION_FACCON, ' +
      '        fc.QUEUE_ID_CANCEL_FACCON, ' +
      '        fc.ISSUER_IRS_ID_CONSOLIDACION_FACCON, ' +
      '        fc.ISSUED_TIME_FACCON, fc.CHAIN_NUMBER_FACCON, ' +
      '        fc.CHAIN_HASH_FACCON, fc.FECHA_PROCESAMIENTO_FACCON, ' +
      '        fc.ESTADO_FACCON, fc.PETICION_COMPLETA_FACCON, ' +
      '        fc.REGISTRO_XML_FACCON, fc.FIRMA_DIGITAL_FACCON, ' +
      '        fc.SERIE_CERTIFICADO_FACCON, ' +
      '        fc.TITULAR_CERTIFICADO_FACCON, ' +
      '        fc.HUELLA_CERTIFICADO_FACCON, ' +
      '        f.FECHA_FAC, f.TIPO_FAC, f.NIF_EMPRESA_FAC, ' +
      '        f.RAZON_SOCIAL_EMPRESA_FAC, f.NIF_CLIENTE_FAC, ' +
      '        f.RAZON_SOCIAL_CLIENTE_FAC, f.TOTAL_LIQUIDO_FAC, ' +
      '        f.TOTAL_IMPUESTOS_FAC ' +
      ' FROM fza_facturas_consolidaciones fc ' +
      ' LEFT JOIN fza_facturas f ' +
      '        ON f.SERIE_FAC = fc.SERIE_FAC_FACCON ' +
      '       AND f.NUMERO_FAC = fc.NUMERO_FAC_FACCON ' +
      ' ORDER BY fc.ID_FACCON';
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioExportacionNoVerifactuUniDAC(
  AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;
begin
  Result := TRepositorioExportacionNoVerifactuUniDAC.Create(AConexion);
end;

end.
