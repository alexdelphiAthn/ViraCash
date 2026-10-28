{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataSepaRemesasCompraRepositorio                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de lectura y validación de remesas de pago para el      }
{    fichero de transferencias SEPA (pain.001).                               }
{******************************************************************************}
unit UniDataSepaRemesasCompraRepositorio;

interface

uses
  Uni, inLibSepaRemesasCompraLecturasIntf;

function CrearSepaRemesasCompraLecturas(
  AConexion: TUniConnection): ISepaRemesasCompraLecturas;

implementation

uses
  System.SysUtils, Data.DB, inLibIBAN, inLibMsgCompras,
  inLibDocumentoFiscal, inLibSepaRemesasCompra;

type
  TSepaRemesasCompraLecturas = class(
    TInterfacedObject,
    ISepaRemesasCompraLecturas)
  private
    FConexion: TUniConnection;
    function CrearConsulta: TUniQuery;
    function CrearConcepto(AEfecto: TDataSet): string;
    function LeerFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
    function LeerTexto(ADataSet: TDataSet; const ACampo: string): string;
    function NormalizarIban(const AIban, AContexto: string): string;
    procedure AnadirAviso(var ARemesa: TRemesaSepaCompraValidada;
      const AAviso: string);
    procedure CargarBanco(var ARemesa: TRemesaSepaCompraValidada;
      const ACodigoEmpresa: string);
    procedure CargarCabecera(var ARemesa: TRemesaSepaCompraValidada;
      const ASerie, ANumero: string; out ACodigoEmpresa: string);
    procedure CargarEfectos(var ARemesa: TRemesaSepaCompraValidada;
      const ASerie, ANumero: string);
    procedure CargarIbanBeneficiario(var ARemesa: TRemesaSepaCompraValidada;
      var AEfecto: TEfectoSepaCompraValidado; AConsulta: TDataSet);
  public
    constructor Create(AConexion: TUniConnection);
    function LeerFicheroGenerado(const ASerie,
      ANumero: string): TFicheroSepaRemesaCompra;
    function CargarRemesaValidada(const ASerie, ANumero: string;
      AFormato: TFormatoSepaTransferencia;
      AInstante: TDateTime): TRemesaSepaCompraValidada;
  end;

function CrearSepaRemesasCompraLecturas(
  AConexion: TUniConnection): ISepaRemesasCompraLecturas;
begin
  Result := nil;
  if Assigned(AConexion) then
    Result := TSepaRemesasCompraLecturas.Create(AConexion);
end;

constructor TSepaRemesasCompraLecturas.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TSepaRemesasCompraLecturas.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TSepaRemesasCompraLecturas.LeerTexto(
  ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) and (not oCampo.IsNull) then
    Result := Trim(oCampo.AsString);
end;

function TSepaRemesasCompraLecturas.LeerFecha(
  ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) and (not oCampo.IsNull) then
    Result := oCampo.AsDateTime;
end;

function TSepaRemesasCompraLecturas.NormalizarIban(
  const AIban, AContexto: string): string;
begin
  Result := UpperCase(TIBAN.FormatearElectronico(AIban));
  if Result = '' then
    raise Exception.CreateFmt(SErrorRemesaCompraSepaSinIbanBeneficiario,
      [AContexto]);
  if not TIBAN.ValidarIBAN(Result) then
    raise Exception.CreateFmt(SErrorRemesaCompraSepaIbanNoValido,
      [AContexto, Result]);
end;

procedure TSepaRemesasCompraLecturas.AnadirAviso(
  var ARemesa: TRemesaSepaCompraValidada; const AAviso: string);
begin
  ARemesa.Avisos := ARemesa.Avisos + [AAviso];
end;

function TSepaRemesasCompraLecturas.CrearConcepto(
  AEfecto: TDataSet): string;
var
  sDocumento: string;
begin
  sDocumento := LeerTexto(AEfecto, 'DOC_EXTERNO_EFEC');
  if sDocumento = '' then
    sDocumento := LeerTexto(AEfecto, 'REFERENCIA_DOCUMENTO_EFEC');
  if sDocumento = '' then
    sDocumento := LeerTexto(AEfecto, 'SERIE_FACC_EFEC') + '/' +
      LeerTexto(AEfecto, 'NUMERO_FACC_EFEC');
  Result := Format(STextoConceptoTransferenciaRemesaCompra,
    [sDocumento, AEfecto.FieldByName('NUMERO_EFEC').AsInteger]);
end;

function TSepaRemesasCompraLecturas.LeerFicheroGenerado(
  const ASerie, ANumero: string): TFicheroSepaRemesaCompra;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TFicheroSepaRemesaCompra);
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT ESTADO_REMC, ID_MENSAJE_SEPA_REMC, FORMATO_SEPA_REMC, ' +
      '       ARCHIVO_REMC, INSTANTE_FICHERO_SEPA_REMC ' +
      '  FROM fza_remesas_compra ' +
      ' WHERE SERIE_REMC = :SERIE ' +
      '   AND NUMERO_REMC = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorRemesaCompraNoSeleccionada);
    Result.Estado := UpperCase(LeerTexto(oConsulta, 'ESTADO_REMC'));
    Result.IdMensaje := LeerTexto(oConsulta, 'ID_MENSAJE_SEPA_REMC');
    Result.Formato := LeerTexto(oConsulta, 'FORMATO_SEPA_REMC');
    Result.Archivo := LeerTexto(oConsulta, 'ARCHIVO_REMC');
    Result.Instante := LeerFecha(oConsulta, 'INSTANTE_FICHERO_SEPA_REMC');
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TSepaRemesasCompraLecturas.CargarCabecera(
  var ARemesa: TRemesaSepaCompraValidada;
  const ASerie, ANumero: string; out ACodigoEmpresa: string);
var
  oConsulta: TUniQuery;
  sNif: string;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT r.FECHA_CARGO_REMC, r.IBAN_REMC, r.CODIGO_EMP_REMC, ' +
      '       emp.RAZON_SOCIAL_EMP, emp.NIF_EMP ' +
      '  FROM fza_remesas_compra r ' +
      '  LEFT JOIN fza_empresas emp ' +
      '    ON emp.CODIGO_EMP_EMP = r.CODIGO_EMP_REMC ' +
      ' WHERE r.SERIE_REMC = :SERIE ' +
      '   AND r.NUMERO_REMC = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorRemesaCompraNoSeleccionada);
    ACodigoEmpresa := LeerTexto(oConsulta, 'CODIGO_EMP_REMC');
    ARemesa.NombreEmpresa := LeerTexto(oConsulta, 'RAZON_SOCIAL_EMP');
    if ARemesa.NombreEmpresa = '' then
      ARemesa.NombreEmpresa := ACodigoEmpresa;
    if LeerTexto(oConsulta, 'IBAN_REMC') = '' then
      raise Exception.Create(SErrorRemesaCompraSepaSinBancoPago);
    ARemesa.IbanEmpresa := NormalizarIban(
      LeerTexto(oConsulta, 'IBAN_REMC'), STextoBancoPagoRemesaSepa);
    ARemesa.FechaEjecucion := LeerFecha(oConsulta, 'FECHA_CARGO_REMC');
    // Identificador del ordenante del cuaderno 34: NIF + sufijo 000.
    sNif := LimpiarDocumentoFiscal(LeerTexto(oConsulta, 'NIF_EMP'));
    ARemesa.IdOrdenante := '';
    if sNif <> '' then
      ARemesa.IdOrdenante := sNif + '000';
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TSepaRemesasCompraLecturas.CargarBanco(
  var ARemesa: TRemesaSepaCompraValidada;
  const ACodigoEmpresa: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT COALESCE(NULLIF(eb.BIC_EMPBAN, ''''), ' +
      '                NULLIF(b.BIC_BAN, ''''), '''') AS BIC ' +
      '  FROM fza_empresas_bancos eb ' +
      '  LEFT JOIN fza_bancos b ' +
      '    ON b.CODIGO_BAN = eb.CODIGO_BAN_EMPBAN ' +
      ' WHERE eb.CODIGO_EMP_EMPBAN = :EMPRESA ' +
      '   AND REPLACE(eb.IBAN_EMPBAN, '' '', '''') = :IBAN ' +
      ' LIMIT 1';
    oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    oConsulta.ParamByName('IBAN').AsString := ARemesa.IbanEmpresa;
    oConsulta.Open;
    // Sin BIC el fichero lleva NOTPROVIDED: basta el IBAN en SEPA.
    ARemesa.BicEmpresa := '';
    if not oConsulta.IsEmpty then
      ARemesa.BicEmpresa := UpperCase(LeerTexto(oConsulta, 'BIC'));
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Primero el IBAN del efecto (copiado de la factura al emitirla) y, si
// está vacío, el de la ficha; si ambos existen y difieren, se avisa.
procedure TSepaRemesasCompraLecturas.CargarIbanBeneficiario(
  var ARemesa: TRemesaSepaCompraValidada;
  var AEfecto: TEfectoSepaCompraValidado; AConsulta: TDataSet);
var
  sIbanEfecto: string;
  sIbanFicha: string;
begin
  sIbanEfecto := UpperCase(TIBAN.FormatearElectronico(
    LeerTexto(AConsulta, 'IBAN_EFEC')));
  sIbanFicha := UpperCase(TIBAN.FormatearElectronico(
    LeerTexto(AConsulta, 'IBAN_PRV')));
  if sIbanEfecto <> '' then
  begin
    AEfecto.IbanBeneficiario := NormalizarIban(sIbanEfecto,
      AEfecto.NombreBeneficiario);
    if (sIbanFicha <> '') and (sIbanFicha <> sIbanEfecto) then
      AnadirAviso(ARemesa, Format(SAvisoRemesaCompraSepaIbanDistinto,
        [AEfecto.NombreBeneficiario, AEfecto.IdPago, sIbanEfecto,
         sIbanFicha]));
  end
  else
    AEfecto.IbanBeneficiario := NormalizarIban(sIbanFicha,
      AEfecto.NombreBeneficiario);
end;

procedure TSepaRemesasCompraLecturas.CargarEfectos(
  var ARemesa: TRemesaSepaCompraValidada;
  const ASerie, ANumero: string);
var
  iIndice: Integer;
  oConsulta: TUniQuery;
  rEfecto: TEfectoSepaCompraValidado;
begin
  oConsulta := CrearConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT e.SERIE_FACC_EFEC, e.NUMERO_FACC_EFEC, e.NUMERO_EFEC, ' +
      '       COALESCE(NULLIF(e.RAZON_SOCIAL_PRV_EFEC, ''''), ' +
      '         NULLIF(prv.RAZON_SOCIAL_PRV, ''''), prv.NOMBRE_PRV, ' +
      '         e.CODIGO_PRV_EFEC) AS NOMBRE_PRV, ' +
      '       e.IBAN_EFEC, prv.IBAN_PRV, ' +
      '       COALESCE(e.IMPORTE_PENDIENTE_EFEC, 0) AS IMPORTE, ' +
      '       e.DOC_EXTERNO_EFEC, e.REFERENCIA_DOCUMENTO_EFEC ' +
      '  FROM fza_efectos_compra e ' +
      '  LEFT JOIN fza_proveedores prv ' +
      '    ON prv.CODIGO_PRV_PRV = e.CODIGO_PRV_EFEC ' +
      ' WHERE e.SERIE_REMC_EFEC = :SERIE ' +
      '   AND e.NUMERO_REMC_EFEC = :NUMERO ' +
      '   AND COALESCE(e.IMPORTE_PENDIENTE_EFEC, 0) > 0 ' +
      ' ORDER BY e.FECHA_VENCIMIENTO_EFEC, e.SERIE_FACC_EFEC, ' +
      '          e.NUMERO_FACC_EFEC, e.NUMERO_EFEC';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rEfecto := Default(TEfectoSepaCompraValidado);
      rEfecto.IdPago := CrearIdPagoSepaRemesaCompra(
        LeerTexto(oConsulta, 'SERIE_FACC_EFEC'),
        LeerTexto(oConsulta, 'NUMERO_FACC_EFEC'),
        oConsulta.FieldByName('NUMERO_EFEC').AsInteger);
      rEfecto.NombreBeneficiario := LeerTexto(oConsulta, 'NOMBRE_PRV');
      if rEfecto.NombreBeneficiario = '' then
        raise Exception.CreateFmt(SErrorRemesaCompraSepaSinBeneficiario,
          [rEfecto.IdPago]);
      CargarIbanBeneficiario(ARemesa, rEfecto, oConsulta);
      rEfecto.Importe := oConsulta.FieldByName('IMPORTE').AsCurrency;
      rEfecto.Concepto := CrearConcepto(oConsulta);
      iIndice := Length(ARemesa.Efectos);
      SetLength(ARemesa.Efectos, iIndice + 1);
      ARemesa.Efectos[iIndice] := rEfecto;
      oConsulta.Next;
    end;
    if Length(ARemesa.Efectos) = 0 then
      raise Exception.Create(SErrorRemesaCompraSepaSinEfectos);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TSepaRemesasCompraLecturas.CargarRemesaValidada(
  const ASerie, ANumero: string; AFormato: TFormatoSepaTransferencia;
  AInstante: TDateTime): TRemesaSepaCompraValidada;
var
  rFichero: TFicheroSepaRemesaCompra;
  sCodigoEmpresa: string;
begin
  Result := Default(TRemesaSepaCompraValidada);
  rFichero := LeerFicheroGenerado(ASerie, ANumero);
  Result.IdMensaje := rFichero.IdMensaje;
  if Result.IdMensaje = '' then
    Result.IdMensaje := CrearIdMensajeSepaRemesaCompra(ASerie, ANumero,
      AInstante);
  Result.Formato := AFormato;
  Result.Instante := AInstante;
  Result.DesfaseUtcMinutos := DesfaseUtcLocalMinutos(AInstante);
  CargarCabecera(Result, ASerie, ANumero, sCodigoEmpresa);
  CargarBanco(Result, sCodigoEmpresa);
  CargarEfectos(Result, ASerie, ANumero);
end;

end.
