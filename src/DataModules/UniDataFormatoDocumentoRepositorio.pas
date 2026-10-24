{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFormatoDocumentoRepositorio                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC del formato de documentos y expresiones SQL asociadas.   }
{******************************************************************************}
unit UniDataFormatoDocumentoRepositorio;

interface

uses
  Uni, inLibFormatoDocumentoLecturasIntf;

function CrearFormatoDocumentoLecturas(
  AConexion: TUniConnection): IFormatoDocumentoLecturas;
function FormatearReferenciaFactura(AConexion: TUniConnection;
  const ASerie, ANumero: string): string;
function ExpresionSqlFormatoDocumento(const AFormato, ASerie,
  ANumero: string): string;

implementation

uses
  System.SysUtils, Data.DB, inLibFormatoDocumento;

const
  TOKENS_NUMERO_SQL: array[0..20] of string = (
    'NroDocumento', 'nrodocumento', 'NRODOCUMENTO',
    'NumeroDocumento', 'numerodocumento', 'NUMERODOCUMENTO',
    'NúmeroDocumento', 'númerodocumento', 'NÚMERODOCUMENTO',
    'NroFactura', 'nrofactura', 'NROFACTURA',
    'NroDoc', 'nrodoc', 'NRODOC',
    'Numero', 'numero', 'NUMERO',
    'Número', 'número', 'NÚMERO');
  TOKENS_SERIE_SQL: array[0..2] of string = (
    'Serie', 'serie', 'SERIE');
  TOKENS_FORMATO_SQL: array[0..7] of string = (
    'serie', 'nrodocumento', 'numerodocumento',
    'númerodocumento', 'nrofactura', 'nrodoc',
    'numero', 'número');

type
  TFormatoDocumentoLecturas = class(
    TInterfacedObject,
    IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function LeerFormatoEmpresa(
      const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(
      const ASerie, ANumero: string): string;
  end;

function CrearFormatoDocumentoLecturas(
  AConexion: TUniConnection): IFormatoDocumentoLecturas;
begin
  Result := TFormatoDocumentoLecturas.Create(AConexion);
end;

function FormatearReferenciaFactura(AConexion: TUniConnection;
  const ASerie, ANumero: string): string;
begin
  Result := FormatearDocumento(
    CrearFormatoDocumentoLecturas(AConexion).LeerFormatoFactura(
      ASerie, ANumero), ASerie, ANumero);
end;

constructor TFormatoDocumentoLecturas.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TFormatoDocumentoLecturas.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := FORMATO_DOCUMENTO_DEFECTO;
  if Trim(ACodigoEmpresa) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT FORMATO_DOCUMENTO_EMP ' +
          '  FROM fza_empresas ' +
          ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
        oConsulta.ParamByName('CODIGO_EMP').AsString := ACodigoEmpresa;
        oConsulta.Open;
        if not oConsulta.Eof and
           (Trim(oConsulta.FieldByName(
             'FORMATO_DOCUMENTO_EMP').AsString) <> '') then
          Result := oConsulta.FieldByName(
            'FORMATO_DOCUMENTO_EMP').AsString;
      except
        Result := FORMATO_DOCUMENTO_DEFECTO;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TFormatoDocumentoLecturas.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := FORMATO_DOCUMENTO_DEFECTO;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT e.FORMATO_DOCUMENTO_EMP ' +
      'FROM fza_facturas f ' +
      'JOIN fza_empresas e ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
      'WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
  finally
    oConsulta.Free;
  end;
end;

function SqlTextoLimpio(const AExpresion: string): string;
begin
  Result := 'TRIM(COALESCE(' + AExpresion + ', ' + QuotedStr('') + '))';
end;

function SqlFormatoDefecto(const AFormato: string): string;
begin
  Result := 'COALESCE(NULLIF(' + SqlTextoLimpio(AFormato) + ', ' +
    QuotedStr('') + '), ' + QuotedStr(FORMATO_DOCUMENTO_DEFECTO) + ')';
end;

function SqlReemplazarToken(const AExpresion, AToken,
  AValor: string): string;
begin
  Result := 'REPLACE(' + AExpresion + ', ' + QuotedStr(AToken) + ', ' +
    AValor + ')';
end;

function SqlCondicionTokensFormato(const AFormato: string): string;
var
  iIndice: Integer;
begin
  Result := '';
  iIndice := Low(TOKENS_FORMATO_SQL);
  while iIndice <= High(TOKENS_FORMATO_SQL) do
  begin
    if Result <> '' then
      Result := Result + ' OR ';
    Result := Result + 'INSTR(LOWER(' + AFormato + '), ' +
      QuotedStr(TOKENS_FORMATO_SQL[iIndice]) + ') > 0';
    Inc(iIndice);
  end;
end;

function ExpresionSqlFormatoDocumento(const AFormato, ASerie,
  ANumero: string): string;
var
  iIndice: Integer;
  sCondicionTokens: string;
  sFormato: string;
  sNumero: string;
  sResultado: string;
  sSerie: string;
begin
  sSerie := SqlTextoLimpio(ASerie);
  sNumero := SqlTextoLimpio(ANumero);
  sFormato := SqlFormatoDefecto(AFormato);
  sCondicionTokens := SqlCondicionTokensFormato(sFormato);
  sResultado := sFormato;
  iIndice := Low(TOKENS_NUMERO_SQL);
  while iIndice <= High(TOKENS_NUMERO_SQL) do
  begin
    sResultado := SqlReemplazarToken(sResultado,
      TOKENS_NUMERO_SQL[iIndice], sNumero);
    Inc(iIndice);
  end;
  iIndice := Low(TOKENS_SERIE_SQL);
  while iIndice <= High(TOKENS_SERIE_SQL) do
  begin
    sResultado := SqlReemplazarToken(sResultado,
      TOKENS_SERIE_SQL[iIndice], sSerie);
    Inc(iIndice);
  end;
  Result := 'CASE WHEN ' + sSerie + ' = ' + QuotedStr('') + ' THEN ' +
    sNumero + ' WHEN ' + sNumero + ' = ' + QuotedStr('') + ' THEN ' +
    sSerie + ' WHEN NOT (' + sCondicionTokens + ') THEN CONCAT(' +
    sSerie + ', ' + QuotedStr('.') + ', ' + sNumero + ') ELSE ' +
    sResultado + ' END';
end;

end.
