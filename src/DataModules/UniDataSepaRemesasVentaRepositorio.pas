{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataSepaRemesasVentaRepositorio                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de lectura y validación de remesas SEPA.                 }
{******************************************************************************}
unit UniDataSepaRemesasVentaRepositorio;

interface

uses
  Uni, inLibSepaRemesasVentaLecturasIntf;

function CrearSepaRemesasVentaLecturas(
  AConexion: TUniConnection): ISepaRemesasVentaLecturas;

implementation

uses
  System.SysUtils, Data.DB, inLibIBAN, inLibMsgVentas,
  inLibSepaRemesasVenta;

type
  TSepaRemesasVentaLecturas = class(
    TInterfacedObject,
    ISepaRemesasVentaLecturas)
  private
    FConexion: TUniConnection;
    function CrearConsulta: TUniQuery;
    function CrearConcepto(AEfecto: TDataSet): string;
    function CrearIdCobro(AEfecto: TDataSet): string;
    function SoloAlfanumerico(const AValor: string): string;
    function LeerFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
    function LeerTexto(ADataSet: TDataSet; const ACampo: string): string;
    function NormalizarIban(const AIban, AContexto: string): string;
    procedure CargarBanco(var ARemesa: TRemesaSepaVentaValidada;
      const ACodigoEmpresa: string);
    procedure CargarCabecera(var ARemesa: TRemesaSepaVentaValidada;
      const ASerie, ANumero: string; out ACodigoEmpresa: string);
    procedure CargarEfectos(var ARemesa: TRemesaSepaVentaValidada;
      const ASerie, ANumero: string);
  public
    constructor Create(AConexion: TUniConnection);
    function CargarRemesaValidada(const ASerie,
      ANumero: string): TRemesaSepaVentaValidada;
  end;

function CrearSepaRemesasVentaLecturas(
  AConexion: TUniConnection): ISepaRemesasVentaLecturas;
begin
  Result := nil;
  if Assigned(AConexion) then
    Result := TSepaRemesasVentaLecturas.Create(AConexion);
end;

constructor TSepaRemesasVentaLecturas.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TSepaRemesasVentaLecturas.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TSepaRemesasVentaLecturas.LeerTexto(
  ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) and (not oCampo.IsNull) then
    Result := Trim(oCampo.AsString);
end;

function TSepaRemesasVentaLecturas.LeerFecha(
  ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) and (not oCampo.IsNull) then
    Result := oCampo.AsDateTime;
end;

function TSepaRemesasVentaLecturas.NormalizarIban(
  const AIban, AContexto: string): string;
begin
  Result := UpperCase(TIBAN.FormatearElectronico(AIban));
  if Result = '' then
    raise Exception.CreateFmt(SErrorContextoSinIban, [AContexto]);
  if not TIBAN.ValidarIBAN(Result) then
    raise Exception.CreateFmt(SErrorContextoIbanNoValido,
      [AContexto, Result]);
end;

function TSepaRemesasVentaLecturas.CrearIdCobro(
  AEfecto: TDataSet): string;
begin
  Result := 'REMV-' +
    SoloAlfanumerico(LeerTexto(AEfecto, 'SERIE_FAC_EFV')) + '-' +
    SoloAlfanumerico(LeerTexto(AEfecto, 'NUMERO_FAC_EFV')) + '-' +
    AEfecto.FieldByName('NUMERO_EFV').AsString;
end;

function TSepaRemesasVentaLecturas.SoloAlfanumerico(
  const AValor: string): string;
var
  cCaracter: Char;
  sValor: string;
begin
  Result := '';
  sValor := UpperCase(Trim(AValor));
  for cCaracter in sValor do
  begin
    if CharInSet(cCaracter, ['A'..'Z', '0'..'9']) then
      Result := Result + cCaracter;
  end;
end;

function TSepaRemesasVentaLecturas.CrearConcepto(
  AEfecto: TDataSet): string;
begin
  Result := LeerTexto(AEfecto, 'REFERENCIA_DOCUMENTO_EFV');
  if Result = '' then
    Result := 'Factura ' + LeerTexto(AEfecto, 'SERIE_FAC_EFV') + '/' +
      LeerTexto(AEfecto, 'NUMERO_FAC_EFV') + ' efecto ' +
      AEfecto.FieldByName('NUMERO_EFV').AsString;
end;

procedure TSepaRemesasVentaLecturas.CargarCabecera(
  var ARemesa: TRemesaSepaVentaValidada;
  const ASerie, ANumero: string; out ACodigoEmpresa: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT r.FECHA_CARGO_REMV, r.IBAN_REMV, ' +
      '       r.CODIGO_EMP_REMV, r.TIPO_SECUENCIA_SEPA_REMV, ' +
      '       emp.RAZON_SOCIAL_EMP ' +
      '  FROM fza_remesas_venta r ' +
      '  LEFT JOIN fza_empresas emp ' +
      '    ON emp.CODIGO_EMP_EMP = r.CODIGO_EMP_REMV ' +
      ' WHERE r.SERIE_REMV = :SERIE ' +
      '   AND r.NUMERO_REMV = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorRemesaVentaNoEncontrada);
    ACodigoEmpresa := LeerTexto(oConsulta, 'CODIGO_EMP_REMV');
    ARemesa.NombreEmpresa := LeerTexto(oConsulta, 'RAZON_SOCIAL_EMP');
    if ARemesa.NombreEmpresa = '' then
      ARemesa.NombreEmpresa := ACodigoEmpresa;
    ARemesa.IbanEmpresa := NormalizarIban(
      LeerTexto(oConsulta, 'IBAN_REMV'), STextoBancoCobroRemesa);
    ARemesa.FechaCargo := LeerFecha(oConsulta, 'FECHA_CARGO_REMV');
    if ARemesa.FechaCargo <= 0 then
      raise Exception.Create(SErrorRemesaSinFechaCobro);
    ARemesa.TipoSecuencia := UpperCase(
      LeerTexto(oConsulta, 'TIPO_SECUENCIA_SEPA_REMV'));
    if ARemesa.TipoSecuencia = '' then
      ARemesa.TipoSecuencia := 'RCUR';
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TSepaRemesasVentaLecturas.CargarBanco(
  var ARemesa: TRemesaSepaVentaValidada;
  const ACodigoEmpresa: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT COALESCE(NULLIF(eb.BIC_EMPBAN, ''''), ' +
      '                NULLIF(b.BIC_BAN, ''''), '''') AS BIC, ' +
      '       COALESCE(NULLIF(' +
      '         eb.CODIGO_ACREEDOR_SEPA_EMPBAN, ''''), '''') ' +
      '         AS CODIGO_ACREEDOR ' +
      '  FROM fza_empresas_bancos eb ' +
      '  LEFT JOIN fza_bancos b ' +
      '    ON b.CODIGO_BAN = eb.CODIGO_BAN_EMPBAN ' +
      ' WHERE eb.CODIGO_EMP_EMPBAN = :EMPRESA ' +
      '   AND eb.IBAN_EMPBAN = :IBAN ' +
      ' LIMIT 1';
    oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    oConsulta.ParamByName('IBAN').AsString := ARemesa.IbanEmpresa;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorBancoCobroRemesaNoEncontrado);
    ARemesa.BicEmpresa := UpperCase(LeerTexto(oConsulta, 'BIC'));
    ARemesa.CodigoAcreedor := UpperCase(
      LeerTexto(oConsulta, 'CODIGO_ACREEDOR'));
    if ARemesa.CodigoAcreedor = '' then
      raise Exception.Create(SErrorBancoCobroSinCodigoAcreedorSepa);
    if not CodigoAcreedorSepaValido(ARemesa.CodigoAcreedor) then
      raise Exception.CreateFmt(SErrorCodigoAcreedorSepaNoValido,
        [ARemesa.CodigoAcreedor]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TSepaRemesasVentaLecturas.CargarEfectos(
  var ARemesa: TRemesaSepaVentaValidada;
  const ASerie, ANumero: string);
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT e.SERIE_FAC_EFV, e.NUMERO_FAC_EFV, e.NUMERO_EFV, ' +
      '       COALESCE(NULLIF(e.RAZON_SOCIAL_CLI_EFV, ''''), ' +
      '         cli.RAZON_SOCIAL_CLI, e.CODIGO_CLI_EFV) AS NOMBRE_CLI, ' +
      '       COALESCE(NULLIF(e.IBAN_EFV, ''''), ' +
      '         cli.IBAN_CLI) AS IBAN_CLI, cli.ID_MANDATO_SEPA_CLI, ' +
      '       cli.FECHA_FIRMA_MANDATO_SEPA_CLI, ' +
      '       COALESCE(e.IMPORTE_PENDIENTE_EFV, ' +
      '         e.IMPORTE_EFV, 0) AS IMPORTE, ' +
      '       e.REFERENCIA_DOCUMENTO_EFV ' +
      '  FROM fza_efectos_venta e ' +
      '  LEFT JOIN fza_clientes cli ' +
      '    ON cli.CODIGO_CLI_CLI = e.CODIGO_CLI_EFV ' +
      ' WHERE e.SERIE_REMV_EFV = :SERIE ' +
      '   AND e.NUMERO_REMV_EFV = :NUMERO ' +
      '   AND COALESCE(e.IMPORTE_PENDIENTE_EFV, ' +
      '     e.IMPORTE_EFV, 0) > 0 ' +
      ' ORDER BY e.FECHA_VENCIMIENTO_EFV, e.SERIE_FAC_EFV, ' +
      '          e.NUMERO_FAC_EFV, e.NUMERO_EFV';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(ARemesa.Efectos);
      SetLength(ARemesa.Efectos, iIndice + 1);
      ARemesa.Efectos[iIndice].NombreCliente :=
        LeerTexto(oConsulta, 'NOMBRE_CLI');
      if ARemesa.Efectos[iIndice].NombreCliente = '' then
        raise Exception.Create(SErrorEfectoSinNombreCliente);
      ARemesa.Efectos[iIndice].IbanCliente := NormalizarIban(
        LeerTexto(oConsulta, 'IBAN_CLI'),
        Format(STextoClienteSepa,
          [ARemesa.Efectos[iIndice].NombreCliente]));
      ARemesa.Efectos[iIndice].IdMandato :=
        LeerTexto(oConsulta, 'ID_MANDATO_SEPA_CLI');
      if ARemesa.Efectos[iIndice].IdMandato = '' then
        raise Exception.CreateFmt(SErrorClienteSinMandatoSepa,
          [ARemesa.Efectos[iIndice].NombreCliente]);
      ARemesa.Efectos[iIndice].FechaFirmaMandato :=
        LeerFecha(oConsulta, 'FECHA_FIRMA_MANDATO_SEPA_CLI');
      if ARemesa.Efectos[iIndice].FechaFirmaMandato <= 0 then
        raise Exception.CreateFmt(
          SErrorClienteSinFechaFirmaMandatoSepa,
          [ARemesa.Efectos[iIndice].NombreCliente]);
      ARemesa.Efectos[iIndice].IdCobro := CrearIdCobro(oConsulta);
      ARemesa.Efectos[iIndice].Importe :=
        oConsulta.FieldByName('IMPORTE').AsCurrency;
      ARemesa.Efectos[iIndice].Concepto := CrearConcepto(oConsulta);
      oConsulta.Next;
    end;
    if Length(ARemesa.Efectos) = 0 then
      raise Exception.Create(SErrorRemesaVentaSinEfectosPendientes);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TSepaRemesasVentaLecturas.CargarRemesaValidada(
  const ASerie, ANumero: string): TRemesaSepaVentaValidada;
var
  sCodigoEmpresa: string;
begin
  Result := Default(TRemesaSepaVentaValidada);
  CargarCabecera(Result, ASerie, ANumero, sCodigoEmpresa);
  CargarBanco(Result, sCodigoEmpresa);
  CargarEfectos(Result, ASerie, ANumero);
  Result.IdOrdenante := 'REMV-' + SoloAlfanumerico(ASerie) + '-' +
    SoloAlfanumerico(ANumero);
end;

end.
