{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFacturae                                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       15/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Generacion de eDoc Facturae 3.2.2 para facturas de venta mayor. Valida    }
{    datos minimos, firma XAdES con la politica Facturae y guarda el XML       }
{    firmado en fichero y en fza_facturas.XML_FAC.                             }
{******************************************************************************}
unit inLibFacturae;

interface

uses
  System.SysUtils, inLibContextoSesionIntf,
  inLibFacturaePersistenciaIntf;

type
  TFacturaeResultado = record
    Archivo: string;
    NumeroSerieCertificado: string;
    TitularCertificado: string;
    HuellaSha1Certificado: string;
  end;

function NombreArchivoFacturae(const ASerie, ANumero: string): string;
// NIF de persona física: DNI (empieza por dígito) o NIE (X, Y, Z).
function EsPersonaFisica(const ANif: string): Boolean;
function EmitirFacturae(const ARepositorio: IRepositorioFacturae;
                        const AContextoSesion:
                        IContextoSesionAplicacion;
                        const ASerie, ANumero, AArchivo: string):
                        TFacturaeResultado;

implementation

uses
  System.Classes, System.IOUtils, System.Math, System.StrUtils, Data.DB,
  inLibDocumentoFiscal, inLibXades, inLibMsgFacturas;

const
  cNsFacturae =
    'http://www.facturae.gob.es/formato/Versiones/Facturaev3_2_2.xml';
  cVersionFacturae = '3.2.2';
  cDir3RespaldoOficina = 'L01070184';
  cDir3RespaldoOrgano = 'L01070184';
  cDir3RespaldoUnidad = 'L01070184';

function Xml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function DecimalFacturae(AValor: Double;
                         ADecimales: Integer = 2): string;
var
  oFormato: TFormatSettings;
  sMascara: string;
begin
  oFormato := TFormatSettings.Create('en-US');
  if ADecimales = 6 then
    sMascara := '0.000000'
  else
    sMascara := '0.00';
  Result := FormatFloat(sMascara, AValor, oFormato);
end;

function CampoStr(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := Trim(oCampo.AsString);
end;

function CampoDir3Facturae(ADataSet: TDataSet; const ACampo,
                           ADefecto: string): string;
begin
  Result := CampoStr(ADataSet, ACampo);
  if (Result = '') and
     SameText(ACampo, 'CODIGO_OFICINA_CONTABLE_FAC') then
    Result := CampoStr(ADataSet, 'CODIGO_OFICINA_CONTABLE_CLI');
  if (Result = '') and
     SameText(ACampo, 'CODIGO_ORGANO_GESTOR_FAC') then
    Result := CampoStr(ADataSet, 'CODIGO_ORGANO_GESTOR_CLI');
  if (Result = '') and
     SameText(ACampo, 'CODIGO_UNIDAD_TRAMITADORA_FAC') then
    Result := CampoStr(ADataSet, 'CODIGO_UNIDAD_TRAMITADORA_CLI');
  if Result = '' then
    Result := ADefecto;
end;

function CampoPersonaFisicaFacturae(ADataSet: TDataSet;
                                    const ACampo: string): string;
begin
  Result := CampoStr(ADataSet, ACampo);
  if (Result = '') and
     SameText(ACampo, 'NOMBRE_PERSONA_CLIENTE_FAC') then
    Result := CampoStr(ADataSet, 'NOMBRE_PERSONA_CLIENTE_CLI');
  if (Result = '') and
     SameText(ACampo, 'APELLIDOS_PERSONA_CLIENTE_FAC') then
    Result := CampoStr(ADataSet, 'APELLIDOS_PERSONA_CLIENTE_CLI');
end;

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsFloat;
end;

function CampoFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsDateTime;
end;

function CodigoPagoFacturaeValido(const AValor: string): Boolean;
var
  iCodigo: Integer;
begin
  Result := TryStrToInt(AValor, iCodigo) and
            (Length(AValor) = 2) and
            (iCodigo >= 1) and
            (iCodigo <= 19);
end;

function NormalizarCodigoPagoFacturae(const AValor: string): string;
begin
  Result := Trim(AValor);
  if Result = '' then
    Result := '01'
  else
  begin
    if Length(Result) = 1 then
      Result := '0' + Result;
    if not CodigoPagoFacturaeValido(Result) then
      Result := '';
  end;
end;

procedure Linea(ASb: TStringBuilder; ANivel: Integer; const ATexto: string);
begin
  ASb.Append(StringOfChar(' ', ANivel * 2));
  ASb.AppendLine(ATexto);
end;

procedure Nodo(ASb: TStringBuilder; ANivel: Integer;
               const ANombre, AValor: string);
begin
  Linea(ASb, ANivel, '<' + ANombre + '>' + Xml(AValor) + '</' +
    ANombre + '>');
end;

function NormalizarNamespacesFacturae(const AXml: string): string;
begin
  Result := StringReplace(AXml, '<fe:', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '</fe:', '</', [rfReplaceAll]);
  Result := StringReplace(Result, '<Facturae xmlns:fe=',
    '<fe:Facturae xmlns:fe=', []);
  Result := StringReplace(Result, '</Facturae>', '</fe:Facturae>', []);
end;

function NormalizarNif(const AValor: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := UpCase(AValor[i]);
    if CharInSet(c, ['A'..'Z', '0'..'9']) then
      Result := Result + c;
  end;
end;

function CodigoPaisFacturae(const ACodigo, ANombre: string): string;
var
  sCodigo: string;
  sNombre: string;
begin
  sCodigo := UpperCase(Trim(ACodigo));
  sNombre := UpperCase(Trim(ANombre));
  if (sCodigo = '') or (sCodigo = 'ES') or (sCodigo = '724') or
     SameText(sNombre, 'ESPAÑA') or SameText(sNombre, 'ESPANA') then
    Result := 'ESP'
  else if Length(sCodigo) = 3 then
    Result := sCodigo
  else
    Result := 'ESP';
end;

function EsPersonaJuridica(const ANif: string): Boolean;
var
  sNif: string;
begin
  sNif := NormalizarNif(ANif);
  Result := False;
  if sNif <> '' then
    Result := CharInSet(sNif[1],
      ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'N',
       'P', 'Q', 'R', 'S', 'U', 'V', 'W']);
end;

function EsPersonaFisica(const ANif: string): Boolean;
var
  sNif: string;
begin
  sNif := NormalizarNif(ANif);
  Result := (sNif <> '') and
            CharInSet(sNif[1], ['0'..'9', 'X', 'Y', 'Z']);
end;

function NombreArchivoFacturae(const ASerie, ANumero: string): string;
var
  i: Integer;
  sBase: string;
  c: Char;
begin
  Result := 'eDoc_';
  sBase := ASerie + '_' + ANumero;
  for i := 1 to Length(sBase) do
  begin
    c := sBase[i];
    if CharInSet(c, ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + c
    else
      Result := Result + '_';
  end;
  Result := Result + '.xsig';
end;

function IdFacturaeSeguro(const ASerie, ANumero: string): string;
var
  i: Integer;
  sBase: string;
  c: Char;
begin
  Result := 'FZ-FACTURAE';
  sBase := ASerie + '-' + ANumero;
  for i := 1 to Length(sBase) do
  begin
    c := UpCase(sBase[i]);
    if CharInSet(c, ['A'..'Z', '0'..'9', '-']) then
      Result := Result + '-' + c;
  end;
end;

function BaseLinea(ALinea: TDataSet): Double;
var
  dBase: Double;
begin
  dBase := CampoFloat(ALinea, 'TOTAL_FAC_SIVA_FACLIN');
  if Abs(dBase) <= 0.000001 then
    dBase := CampoFloat(ALinea, 'CANTIDAD_FACLIN') *
      CampoFloat(ALinea, 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN');
  Result := dBase;
end;

function RecargoActivo(ACabecera: TDataSet; const ACampoTotal,
                       ACampoPorcentaje: string): Double;
begin
  Result := 0;
  if Abs(CampoFloat(ACabecera, ACampoTotal)) > 0.000001 then
    Result := CampoFloat(ACabecera, ACampoPorcentaje);
end;

function RecargoPorIva(ACabecera: TDataSet; APorcentajeIva: Double): Double;
begin
  Result := 0;
  if Abs(APorcentajeIva -
     CampoFloat(ACabecera, 'PORCENTAJE_IVAN_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_REN_FAC',
      'PORCENTAJE_REN_FAC')
  else if Abs(APorcentajeIva -
          CampoFloat(ACabecera, 'PORCENTAJE_IVAR_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_RER_FAC',
      'PORCENTAJE_RER_FAC')
  else if Abs(APorcentajeIva -
          CampoFloat(ACabecera, 'PORCENTAJE_IVAS_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_RES_FAC',
      'PORCENTAJE_RES_FAC')
  else if Abs(APorcentajeIva -
          CampoFloat(ACabecera, 'PORCENTAJE_IVAE_FAC')) < 0.0001 then
    Result := RecargoActivo(ACabecera, 'TOTAL_REE_FAC',
      'PORCENTAJE_REE_FAC');
end;

procedure AnadirDireccion(ASb: TStringBuilder; ANivel: Integer;
                          const APais, ADireccion, ACp, APoblacion,
                          AProvincia: string);
begin
  if APais = 'ESP' then
  begin
    Linea(ASb, ANivel, '<fe:AddressInSpain>');
    Nodo(ASb, ANivel + 1, 'fe:Address', ADireccion);
    Nodo(ASb, ANivel + 1, 'fe:PostCode', ACp);
    Nodo(ASb, ANivel + 1, 'fe:Town', APoblacion);
    Nodo(ASb, ANivel + 1, 'fe:Province', AProvincia);
    Nodo(ASb, ANivel + 1, 'fe:CountryCode', APais);
    Linea(ASb, ANivel, '</fe:AddressInSpain>');
  end
  else
  begin
    Linea(ASb, ANivel, '<fe:OverseasAddress>');
    Nodo(ASb, ANivel + 1, 'fe:Address', ADireccion);
    Nodo(ASb, ANivel + 1, 'fe:PostCodeAndTown',
      Trim(ACp + ' ' + APoblacion));
    Nodo(ASb, ANivel + 1, 'fe:Province', AProvincia);
    Nodo(ASb, ANivel + 1, 'fe:CountryCode', APais);
    Linea(ASb, ANivel, '</fe:OverseasAddress>');
  end;
end;

procedure AnadirCentroAdministrativo(ASb: TStringBuilder; const ACodigo,
                                     ARol, ANombre, APais, ADireccion, ACp,
                                     APoblacion, AProvincia: string);
begin
  Linea(ASb, 4, '<fe:AdministrativeCentre>');
  Nodo(ASb, 5, 'fe:CentreCode', ACodigo);
  Nodo(ASb, 5, 'fe:RoleTypeCode', ARol);
  Nodo(ASb, 5, 'fe:Name', ANombre);
  AnadirDireccion(ASb, 5, APais, ADireccion, ACp, APoblacion, AProvincia);
  Linea(ASb, 4, '</fe:AdministrativeCentre>');
end;

procedure AnadirCentrosAdministrativos(ASb: TStringBuilder;
                                       const AOficina, AOrgano, AUnidad,
                                       APais, ADireccion, ACp, APoblacion,
                                       AProvincia: string);
begin
  if (Trim(AOficina) <> '') and (Trim(AOrgano) <> '') and
     (Trim(AUnidad) <> '') then
  begin
    Linea(ASb, 3, '<fe:AdministrativeCentres>');
    AnadirCentroAdministrativo(ASb, AOficina, '01', 'Oficina contable',
      APais, ADireccion, ACp, APoblacion, AProvincia);
    AnadirCentroAdministrativo(ASb, AOrgano, '02', 'Organo gestor',
      APais, ADireccion, ACp, APoblacion, AProvincia);
    AnadirCentroAdministrativo(ASb, AUnidad, '03', 'Unidad tramitadora',
      APais, ADireccion, ACp, APoblacion, AProvincia);
    Linea(ASb, 3, '</fe:AdministrativeCentres>');
  end;
end;

procedure AnadirParte(ASb: TStringBuilder; const ANodo, ANif, ARazonSocial,
                      ANombrePersona, AApellidosPersona, ADireccion, ACp,
                      APoblacion, AProvincia, APais, AOficina, AOrgano,
                      AUnidad: string);
var
  sNombre: string;
  sApellidos: string;
  bJuridica: Boolean;
begin
  bJuridica := EsPersonaJuridica(ANif);
  Linea(ASb, 2, '<fe:' + ANodo + '>');
  Linea(ASb, 3, '<fe:TaxIdentification>');
  if bJuridica then
    Nodo(ASb, 4, 'fe:PersonTypeCode', 'J')
  else
    Nodo(ASb, 4, 'fe:PersonTypeCode', 'F');
  Nodo(ASb, 4, 'fe:ResidenceTypeCode', 'R');
  Nodo(ASb, 4, 'fe:TaxIdentificationNumber', NormalizarNif(ANif));
  Linea(ASb, 3, '</fe:TaxIdentification>');
  AnadirCentrosAdministrativos(ASb, AOficina, AOrgano, AUnidad, APais,
    ADireccion, ACp, APoblacion, AProvincia);
  if bJuridica then
  begin
    Linea(ASb, 3, '<fe:LegalEntity>');
    Nodo(ASb, 4, 'fe:CorporateName', ARazonSocial);
    AnadirDireccion(ASb, 4, APais, ADireccion, ACp, APoblacion, AProvincia);
    Linea(ASb, 3, '</fe:LegalEntity>');
  end
  else
  begin
    sNombre := Trim(ANombrePersona);
    sApellidos := Trim(AApellidosPersona);
    if sNombre = '' then
      sNombre := ARazonSocial;
    if sApellidos = '' then
      sApellidos := '.';
    Linea(ASb, 3, '<fe:Individual>');
    Nodo(ASb, 4, 'fe:Name', sNombre);
    Nodo(ASb, 4, 'fe:FirstSurname', sApellidos);
    AnadirDireccion(ASb, 4, APais, ADireccion, ACp, APoblacion, AProvincia);
    Linea(ASb, 3, '</fe:Individual>');
  end;
  Linea(ASb, 2, '</fe:' + ANodo + '>');
end;

procedure AnadirImpuesto(ASb: TStringBuilder; ANivel: Integer;
                         APorcentajeIva, ABase, AImporteIva,
                         APorcentajeRe, AImporteRe: Double);
begin
  Linea(ASb, ANivel, '<fe:Tax>');
  Nodo(ASb, ANivel + 1, 'fe:TaxTypeCode', '01');
  Nodo(ASb, ANivel + 1, 'fe:TaxRate',
    DecimalFacturae(APorcentajeIva));
  Linea(ASb, ANivel + 1, '<fe:TaxableBase>');
  Nodo(ASb, ANivel + 2, 'fe:TotalAmount', DecimalFacturae(ABase));
  Linea(ASb, ANivel + 1, '</fe:TaxableBase>');
  Linea(ASb, ANivel + 1, '<fe:TaxAmount>');
  Nodo(ASb, ANivel + 2, 'fe:TotalAmount',
    DecimalFacturae(AImporteIva));
  Linea(ASb, ANivel + 1, '</fe:TaxAmount>');
  if (Abs(APorcentajeRe) > 0.000001) and
     (Abs(AImporteRe) > 0.000001) then
  begin
    Nodo(ASb, ANivel + 1, 'fe:EquivalenceSurcharge',
      DecimalFacturae(APorcentajeRe));
    Linea(ASb, ANivel + 1, '<fe:EquivalenceSurchargeAmount>');
    Nodo(ASb, ANivel + 2, 'fe:TotalAmount',
      DecimalFacturae(AImporteRe));
    Linea(ASb, ANivel + 1, '</fe:EquivalenceSurchargeAmount>');
  end;
  Linea(ASb, ANivel, '</fe:Tax>');
end;

procedure AnadirImpuestoCabecera(ASb: TStringBuilder; ACabecera: TDataSet;
                                 const ACampoBase, ACampoPorIva,
                                 ACampoIva, ACampoPorRe,
                                 ACampoRe: string;
                                 var AContador: Integer);
var
  dBase: Double;
  dIva: Double;
  dRe: Double;
begin
  dBase := CampoFloat(ACabecera, ACampoBase);
  dIva := CampoFloat(ACabecera, ACampoIva);
  dRe := CampoFloat(ACabecera, ACampoRe);
  if (Abs(dBase) > 0.000001) or (Abs(dIva) > 0.000001) or
     (Abs(dRe) > 0.000001) then
  begin
    Inc(AContador);
    AnadirImpuesto(ASb, 5, CampoFloat(ACabecera, ACampoPorIva), dBase,
      dIva, CampoFloat(ACabecera, ACampoPorRe), dRe);
  end;
end;

procedure ValidarObligatorio(AErrores: TStrings; const ATexto,
                             AValor: string);
begin
  if Trim(AValor) = '' then
    AErrores.Add(Format(SErrorFacturaeFaltaCampo, [ATexto]));
end;

procedure ValidarParte(AErrores: TStrings; const ATexto, ANif, ARazon,
                       ADireccion, ACp, APoblacion, AProvincia,
                       APais: string);
begin
  ValidarObligatorio(AErrores, Format(STextoNifParteFacturae, [ATexto]),
    ANif);
  ValidarObligatorio(AErrores,
    Format(STextoRazonSocialParteFacturae, [ATexto]), ARazon);
  ValidarObligatorio(AErrores,
    Format(STextoDireccionParteFacturae, [ATexto]), ADireccion);
  ValidarObligatorio(AErrores,
    Format(STextoCodigoPostalParteFacturae, [ATexto]), ACp);
  ValidarObligatorio(AErrores,
    Format(STextoPoblacionParteFacturae, [ATexto]), APoblacion);
  ValidarObligatorio(AErrores,
    Format(STextoProvinciaParteFacturae, [ATexto]), AProvincia);
  if (APais = 'ESP') and (Trim(ANif) <> '') and
     (not DocumentoFiscalValido(ANif)) then
    AErrores.Add(Format(SErrorDocumentoFiscalParteFacturae,
      [MensajeDocumentoFiscalInvalido(ANif), ATexto]));
end;

procedure ValidarCodigoDir3(AErrores: TStrings; const ATexto,
                            ACodigo: string);
begin
  if Trim(ACodigo) = '' then
    AErrores.Add(Format(SErrorFaltaCodigoDir3Facturae, [ATexto]))
  else if Length(Trim(ACodigo)) > 10 then
    AErrores.Add(Format(SErrorCodigoDir3LargoFacturae, [ATexto]));
end;

procedure ValidarDir3Facturae(AErrores: TStrings; ACabecera: TDataSet);
begin
  ValidarCodigoDir3(AErrores, STextoOficinaContableFacturae,
    CampoDir3Facturae(ACabecera, 'CODIGO_OFICINA_CONTABLE_FAC',
      cDir3RespaldoOficina));
  ValidarCodigoDir3(AErrores, STextoOrganoGestorFacturae,
    CampoDir3Facturae(ACabecera, 'CODIGO_ORGANO_GESTOR_FAC',
      cDir3RespaldoOrgano));
  ValidarCodigoDir3(AErrores, STextoUnidadTramitadoraFacturae,
    CampoDir3Facturae(ACabecera, 'CODIGO_UNIDAD_TRAMITADORA_FAC',
      cDir3RespaldoUnidad));
end;

procedure ValidarPersonaFisicaFacturae(AErrores: TStrings;
                                       ACabecera: TDataSet);
begin
  if EsPersonaFisica(CampoStr(ACabecera, 'NIF_CLIENTE_FAC')) then
  begin
    if CampoPersonaFisicaFacturae(ACabecera,
       'NOMBRE_PERSONA_CLIENTE_FAC') = '' then
      AErrores.Add(SErrorNombrePersonaFisicaFacturae);
    if CampoPersonaFisicaFacturae(ACabecera,
       'APELLIDOS_PERSONA_CLIENTE_FAC') = '' then
      AErrores.Add(SErrorApellidosPersonaFisicaFacturae);
  end;
end;

procedure ValidarFormaPagoFacturae(AErrores: TStrings; ACabecera: TDataSet);
begin
  if NormalizarCodigoPagoFacturae(
     CampoStr(ACabecera, 'CODIGO_FACTURAE_FP')) = '' then
    AErrores.Add(SErrorCodigoPagoFacturaeInvalido);
end;

procedure ValidarFactura(ACabecera, ALineas: TDataSet);
var
  oErrores: TStringList;
  iLineas: Integer;
  dBaseLineas: Double;
  dBaseLinea: Double;
begin
  oErrores := TStringList.Create;
  try
    if ACabecera.IsEmpty then
      oErrores.Add(SErrorFacturaeNoExiste);
    if not SameText(CampoStr(ACabecera, 'TIPO_FAC'), 'NORMAL') then
      oErrores.Add(SErrorFacturaeTipoVentaInvalido);
    if CampoStr(ACabecera, 'ESCONSOLIDADA_FAC') <> 'S' then
      oErrores.Add(SErrorFacturaeNoConsolidada);
    if CampoFecha(ACabecera, 'FECHA_FAC') <= 0 then
      oErrores.Add(SErrorFacturaeFechaOficialFaltante);
    ValidarParte(oErrores, STextoEmpresaEmisoraFacturae,
      CampoStr(ACabecera, 'NIF_EMPRESA_FAC'),
      CampoStr(ACabecera, 'RAZON_SOCIAL_EMPRESA_FAC'),
      CampoStr(ACabecera, 'DIRECCION1_EMPRESA_FAC'),
      CampoStr(ACabecera, 'CODIGO_POSTAL_EMPRESA_FAC'),
      CampoStr(ACabecera, 'POBLACION_EMPRESA_FAC'),
      CampoStr(ACabecera, 'PROVINCIA_EMPRESA_FAC'),
      CodigoPaisFacturae(CampoStr(ACabecera, 'CODIGO_PAI_EMPRESA_FAC'),
                         CampoStr(ACabecera, 'NOMBRE_PAI_EMPRESA_FAC')));
    ValidarParte(oErrores, STextoClienteFacturae,
      CampoStr(ACabecera, 'NIF_CLIENTE_FAC'),
      CampoStr(ACabecera, 'RAZON_SOCIAL_CLIENTE_FAC'),
      CampoStr(ACabecera, 'DIRECCION1_CLIENTE_FAC'),
      CampoStr(ACabecera, 'CODIGO_POSTAL_CLIENTE_FAC'),
      CampoStr(ACabecera, 'POBLACION_CLIENTE_FAC'),
      CampoStr(ACabecera, 'PROVINCIA_CLIENTE_FAC'),
      CodigoPaisFacturae(CampoStr(ACabecera, 'CODIGO_PAI_CLIENTE_FAC'),
                         CampoStr(ACabecera, 'NOMBRE_PAI_CLIENTE_FAC')));
    ValidarDir3Facturae(oErrores, ACabecera);
    ValidarPersonaFisicaFacturae(oErrores, ACabecera);
    ValidarFormaPagoFacturae(oErrores, ACabecera);
    iLineas := 0;
    dBaseLineas := 0;
    ALineas.First;
    while not ALineas.Eof do
    begin
      Inc(iLineas);
      dBaseLinea := BaseLinea(ALineas);
      dBaseLineas := dBaseLineas + dBaseLinea;
      if Trim(CampoStr(ALineas, 'DESCRIPCION_ARTICULO_FACLIN')) = '' then
        oErrores.Add(Format(SErrorLineaFacturaeSinDescripcion,
          [CampoStr(ALineas, 'LINEA_FACLIN')]));
      if Abs(CampoFloat(ALineas, 'CANTIDAD_FACLIN')) <= 0.000001 then
        oErrores.Add(Format(SErrorLineaFacturaeCantidadCero,
          [CampoStr(ALineas, 'LINEA_FACLIN')]));
      ALineas.Next;
    end;
    if iLineas = 0 then
      oErrores.Add(SErrorFacturaeSinLineas);
    if Abs(dBaseLineas - CampoFloat(ACabecera, 'TOTAL_BASES_FAC')) > 0.05 then
      oErrores.Add(SErrorBasesFacturaeNoCuadran);
    if Abs(CampoFloat(ACabecera, 'TOTAL_BASES_FAC') +
       CampoFloat(ACabecera, 'TOTAL_IMPUESTOS_FAC') -
       CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC') -
       CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')) > 0.05 then
      oErrores.Add(SErrorTotalesFacturaeNoCuadran);
    ALineas.First;
    if oErrores.Count > 0 then
      raise Exception.Create(Format(SErrorEmitirFacturae,
        [oErrores.Text]));
  finally
    FreeAndNil(oErrores);
  end;
end;

procedure CargarCertificadoEmpresa(
  const ARepositorio: IRepositorioFacturae;
  const ACodigoEmpresa: string;
  out ASerial, ATitular: string);
begin
  ARepositorio.CargarCertificadoEmpresa(
    ACodigoEmpresa,
    ASerial,
    ATitular);
  if (ASerial = '') and (ATitular = '') then
    raise Exception.Create(SErrorCertificadoFacturaeNoConfigurado);
end;

procedure AnadirPaymentDetails(ASb: TStringBuilder; ACabecera: TDataSet);
  forward;

procedure AnadirCabeceraFicheroFacturae(
  ASb: TStringBuilder; ACabecera: TDataSet);
begin
  ASb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
  Linea(ASb, 0, '<fe:Facturae xmlns:fe="' + cNsFacturae + '">');
  Linea(ASb, 1, '<fe:FileHeader>');
  Nodo(ASb, 2, 'fe:SchemaVersion', cVersionFacturae);
  Nodo(ASb, 2, 'fe:Modality', 'I');
  Nodo(ASb, 2, 'fe:InvoiceIssuerType', 'EM');
  Linea(ASb, 2, '<fe:Batch>');
  Nodo(ASb, 3, 'fe:BatchIdentifier',
    NormalizarNif(CampoStr(ACabecera, 'NIF_EMPRESA_FAC')) + '-' +
    CampoStr(ACabecera, 'SERIE_FAC') + '-' +
    CampoStr(ACabecera, 'NUMERO_FAC'));
  Nodo(ASb, 3, 'fe:InvoicesCount', '1');
  Linea(ASb, 3, '<fe:TotalInvoicesAmount>');
  Nodo(ASb, 4, 'fe:TotalAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Linea(ASb, 3, '</fe:TotalInvoicesAmount>');
  Linea(ASb, 3, '<fe:TotalOutstandingAmount>');
  Nodo(ASb, 4, 'fe:TotalAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Linea(ASb, 3, '</fe:TotalOutstandingAmount>');
  Linea(ASb, 3, '<fe:TotalExecutableAmount>');
  Nodo(ASb, 4, 'fe:TotalAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Linea(ASb, 3, '</fe:TotalExecutableAmount>');
  Nodo(ASb, 3, 'fe:InvoiceCurrencyCode', 'EUR');
  Linea(ASb, 2, '</fe:Batch>');
  Linea(ASb, 1, '</fe:FileHeader>');
end;

procedure AnadirPartesFacturae(
  ASb: TStringBuilder; ACabecera: TDataSet);
var
  PaisEmpresa: string;
  PaisCliente: string;
begin
  PaisEmpresa := CodigoPaisFacturae(
    CampoStr(ACabecera, 'CODIGO_PAI_EMPRESA_FAC'),
    CampoStr(ACabecera, 'NOMBRE_PAI_EMPRESA_FAC'));
  PaisCliente := CodigoPaisFacturae(
    CampoStr(ACabecera, 'CODIGO_PAI_CLIENTE_FAC'),
    CampoStr(ACabecera, 'NOMBRE_PAI_CLIENTE_FAC'));
  Linea(ASb, 1, '<fe:Parties>');
  AnadirParte(ASb, 'SellerParty',
    CampoStr(ACabecera, 'NIF_EMPRESA_FAC'),
    CampoStr(ACabecera, 'RAZON_SOCIAL_EMPRESA_FAC'), '', '',
    CampoStr(ACabecera, 'DIRECCION1_EMPRESA_FAC'),
    CampoStr(ACabecera, 'CODIGO_POSTAL_EMPRESA_FAC'),
    CampoStr(ACabecera, 'POBLACION_EMPRESA_FAC'),
    CampoStr(ACabecera, 'PROVINCIA_EMPRESA_FAC'),
    PaisEmpresa, '', '', '');
  AnadirParte(ASb, 'BuyerParty',
    CampoStr(ACabecera, 'NIF_CLIENTE_FAC'),
    CampoStr(ACabecera, 'RAZON_SOCIAL_CLIENTE_FAC'),
    CampoPersonaFisicaFacturae(ACabecera, 'NOMBRE_PERSONA_CLIENTE_FAC'),
    CampoPersonaFisicaFacturae(ACabecera, 'APELLIDOS_PERSONA_CLIENTE_FAC'),
    CampoStr(ACabecera, 'DIRECCION1_CLIENTE_FAC'),
    CampoStr(ACabecera, 'CODIGO_POSTAL_CLIENTE_FAC'),
    CampoStr(ACabecera, 'POBLACION_CLIENTE_FAC'),
    CampoStr(ACabecera, 'PROVINCIA_CLIENTE_FAC'), PaisCliente,
    CampoDir3Facturae(ACabecera, 'CODIGO_OFICINA_CONTABLE_FAC',
      cDir3RespaldoOficina),
    CampoDir3Facturae(ACabecera, 'CODIGO_ORGANO_GESTOR_FAC',
      cDir3RespaldoOrgano),
    CampoDir3Facturae(ACabecera, 'CODIGO_UNIDAD_TRAMITADORA_FAC',
      cDir3RespaldoUnidad));
  Linea(ASb, 1, '</fe:Parties>');
end;

procedure AnadirCabeceraFacturaFacturae(
  ASb: TStringBuilder; ACabecera: TDataSet);
begin
  Linea(ASb, 3, '<fe:InvoiceHeader>');
  Nodo(ASb, 4, 'fe:InvoiceNumber', CampoStr(ACabecera, 'NUMERO_FAC'));
  Nodo(ASb, 4, 'fe:InvoiceSeriesCode', CampoStr(ACabecera, 'SERIE_FAC'));
  Nodo(ASb, 4, 'fe:InvoiceDocumentType', 'FC');
  Nodo(ASb, 4, 'fe:InvoiceClass', 'OO');
  Linea(ASb, 3, '</fe:InvoiceHeader>');
  Linea(ASb, 3, '<fe:InvoiceIssueData>');
  Nodo(ASb, 4, 'fe:IssueDate',
    FormatDateTime('yyyy-mm-dd', CampoFecha(ACabecera, 'FECHA_FAC')));
  Nodo(ASb, 4, 'fe:InvoiceCurrencyCode', 'EUR');
  Nodo(ASb, 4, 'fe:TaxCurrencyCode', 'EUR');
  Nodo(ASb, 4, 'fe:LanguageName', 'es');
  Linea(ASb, 3, '</fe:InvoiceIssueData>');
end;

procedure AnadirImpuestosFacturae(
  ASb: TStringBuilder; ACabecera: TDataSet);
var
  Impuestos: Integer;
begin
  Linea(ASb, 3, '<fe:TaxesOutputs>');
  Impuestos := 0;
  AnadirImpuestoCabecera(ASb, ACabecera, 'TOTAL_BASEI_IVAN_FAC',
    'PORCENTAJE_IVAN_FAC', 'TOTAL_IVAN_FAC', 'PORCENTAJE_REN_FAC',
    'TOTAL_REN_FAC', Impuestos);
  AnadirImpuestoCabecera(ASb, ACabecera, 'TOTAL_BASEI_IVAR_FAC',
    'PORCENTAJE_IVAR_FAC', 'TOTAL_IVAR_FAC', 'PORCENTAJE_RER_FAC',
    'TOTAL_RER_FAC', Impuestos);
  AnadirImpuestoCabecera(ASb, ACabecera, 'TOTAL_BASEI_IVAS_FAC',
    'PORCENTAJE_IVAS_FAC', 'TOTAL_IVAS_FAC', 'PORCENTAJE_RES_FAC',
    'TOTAL_RES_FAC', Impuestos);
  AnadirImpuestoCabecera(ASb, ACabecera, 'TOTAL_BASEI_IVAE_FAC',
    'PORCENTAJE_IVAE_FAC', 'TOTAL_IVAE_FAC', 'PORCENTAJE_REE_FAC',
    'TOTAL_REE_FAC', Impuestos);
  if Impuestos = 0 then
    AnadirImpuesto(ASb, 5, 0, CampoFloat(ACabecera, 'TOTAL_BASES_FAC'),
      0, 0, 0);
  Linea(ASb, 3, '</fe:TaxesOutputs>');
  if Abs(CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC')) > 0.000001 then
  begin
    Linea(ASb, 3, '<fe:TaxesWithheld>');
    Linea(ASb, 4, '<fe:Tax>');
    Nodo(ASb, 5, 'fe:TaxTypeCode', '04');
    Nodo(ASb, 5, 'fe:TaxRate',
      DecimalFacturae(CampoFloat(ACabecera, 'PORCENTAJE_RETENCION_FAC')));
    Linea(ASb, 5, '<fe:TaxableBase>');
    Nodo(ASb, 6, 'fe:TotalAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_BASES_FAC')));
    Linea(ASb, 5, '</fe:TaxableBase>');
    Linea(ASb, 5, '<fe:TaxAmount>');
    Nodo(ASb, 6, 'fe:TotalAmount',
      DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC')));
    Linea(ASb, 5, '</fe:TaxAmount>');
    Linea(ASb, 4, '</fe:Tax>');
    Linea(ASb, 3, '</fe:TaxesWithheld>');
  end;
end;

procedure AnadirTotalesFacturae(
  ASb: TStringBuilder; ACabecera: TDataSet);
begin
  Linea(ASb, 3, '<fe:InvoiceTotals>');
  Nodo(ASb, 4, 'fe:TotalGrossAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_BASES_FAC')));
  Nodo(ASb, 4, 'fe:TotalGrossAmountBeforeTaxes',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_BASES_FAC')));
  Nodo(ASb, 4, 'fe:TotalTaxOutputs',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_IMPUESTOS_FAC')));
  Nodo(ASb, 4, 'fe:TotalTaxesWithheld',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_RETENCION_FAC')));
  Nodo(ASb, 4, 'fe:InvoiceTotal',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Nodo(ASb, 4, 'fe:TotalOutstandingAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Nodo(ASb, 4, 'fe:TotalExecutableAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Linea(ASb, 3, '</fe:InvoiceTotals>');
end;

procedure AnadirLineasFacturae(
  ASb: TStringBuilder; ACabecera, ALineas: TDataSet);
var
  Base: Double;
  Iva: Double;
  Recargo: Double;
  PorcentajeIva: Double;
  PorcentajeRecargo: Double;
begin
  Linea(ASb, 3, '<fe:Items>');
  ALineas.First;
  while not ALineas.Eof do
  begin
    Base := BaseLinea(ALineas);
    PorcentajeIva := CampoFloat(ALineas, 'PORCENTAJE_IVA_FACLIN');
    PorcentajeRecargo := RecargoPorIva(ACabecera, PorcentajeIva);
    Iva := RoundTo(Base * PorcentajeIva / 100, -2);
    Recargo := RoundTo(Base * PorcentajeRecargo / 100, -2);
    Linea(ASb, 4, '<fe:InvoiceLine>');
    Nodo(ASb, 5, 'fe:ItemDescription',
      CampoStr(ALineas, 'DESCRIPCION_ARTICULO_FACLIN'));
    Nodo(ASb, 5, 'fe:Quantity',
      DecimalFacturae(CampoFloat(ALineas, 'CANTIDAD_FACLIN'), 6));
    Nodo(ASb, 5, 'fe:UnitOfMeasure', '01');
    Nodo(ASb, 5, 'fe:UnitPriceWithoutTax', DecimalFacturae(
      CampoFloat(ALineas, 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'), 6));
    Nodo(ASb, 5, 'fe:TotalCost', DecimalFacturae(Base));
    Nodo(ASb, 5, 'fe:GrossAmount', DecimalFacturae(Base));
    Linea(ASb, 5, '<fe:TaxesOutputs>');
    AnadirImpuesto(ASb, 6, PorcentajeIva, Base, Iva,
      PorcentajeRecargo, Recargo);
    Linea(ASb, 5, '</fe:TaxesOutputs>');
    Linea(ASb, 4, '</fe:InvoiceLine>');
    ALineas.Next;
  end;
  Linea(ASb, 3, '</fe:Items>');
end;

function ConstruirXmlFacturae(ACabecera, ALineas: TDataSet): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    AnadirCabeceraFicheroFacturae(SB, ACabecera);
    AnadirPartesFacturae(SB, ACabecera);
    Linea(SB, 1, '<fe:Invoices>');
    Linea(SB, 2, '<fe:Invoice>');
    AnadirCabeceraFacturaFacturae(SB, ACabecera);
    AnadirImpuestosFacturae(SB, ACabecera);
    AnadirTotalesFacturae(SB, ACabecera);
    AnadirLineasFacturae(SB, ACabecera, ALineas);
    AnadirPaymentDetails(SB, ACabecera);
    Linea(SB, 2, '</fe:Invoice>');
    Linea(SB, 1, '</fe:Invoices>');
    Linea(SB, 0, '</fe:Facturae>');
    Result := NormalizarNamespacesFacturae(SB.ToString);
  finally
    FreeAndNil(SB);
  end;
end;

procedure AnadirPaymentDetails(ASb: TStringBuilder; ACabecera: TDataSet);
var
  dFechaVencimiento: TDateTime;
  sCodigoPago: string;
begin
  dFechaVencimiento := CampoFecha(ACabecera, 'FECHA_FAC');
  sCodigoPago := NormalizarCodigoPagoFacturae(
    CampoStr(ACabecera, 'CODIGO_FACTURAE_FP'));
  if sCodigoPago = '' then
    sCodigoPago := '01';
  Linea(ASb, 3, '<fe:PaymentDetails>');
  Linea(ASb, 4, '<fe:Installment>');
  Nodo(ASb, 5, 'fe:InstallmentDueDate',
    FormatDateTime('yyyy-mm-dd', dFechaVencimiento));
  Nodo(ASb, 5, 'fe:InstallmentAmount',
    DecimalFacturae(CampoFloat(ACabecera, 'TOTAL_LIQUIDO_FAC')));
  Nodo(ASb, 5, 'fe:PaymentMeans', sCodigoPago);
  Linea(ASb, 4, '</fe:Installment>');
  Linea(ASb, 3, '</fe:PaymentDetails>');
end;

procedure GuardarXmlFactura(
  const ARepositorio: IRepositorioFacturae;
  const AContextoSesion: IContextoSesionAplicacion;
  const ASerie, ANumero, AXml: string);
begin
  ARepositorio.GuardarXml(
    ASerie,
    ANumero,
    AContextoSesion.Identidad.Usuario,
    AXml);
end;

function EmitirFacturae(const ARepositorio: IRepositorioFacturae;
                        const AContextoSesion:
                        IContextoSesionAplicacion;
                        const ASerie, ANumero, AArchivo: string):
                        TFacturaeResultado;
var
  QryCab: TDataSet;
  QryLin: TDataSet;
  DatosCert: TXadesDatosCertificado;
  Opciones: TXadesOpciones;
  sSerial: string;
  sTitular: string;
  sXmlBase: string;
  sXmlFirmado: string;
  sCarpeta: string;
begin
  if not Assigned(ARepositorio) then
    raise Exception.Create(SErrorConexionFacturaeNoDisponible);
  if Trim(AArchivo) = '' then
    raise Exception.Create(SErrorFicheroSalidaFacturaeNoIndicado);
  QryCab := nil;
  QryLin := nil;
  try
    QryCab := ARepositorio.BuscarCabecera(ASerie, ANumero);
    QryLin := ARepositorio.BuscarLineas(ASerie, ANumero);
    ValidarFactura(QryCab, QryLin);
    CargarCertificadoEmpresa(ARepositorio,
      CampoStr(QryCab, 'CODIGO_EMP_FAC'), sSerial, sTitular);
    sXmlBase := ConstruirXmlFacturae(QryCab, QryLin);
    Opciones := OpcionesXadesFacturae(IdFacturaeSeguro(ASerie, ANumero));
    sXmlFirmado := FirmarXmlXadesEnveloped(sXmlBase, sSerial, sTitular,
      Opciones, DatosCert);
    sCarpeta := ExtractFileDir(AArchivo);
    if (sCarpeta <> '') and (not TDirectory.Exists(sCarpeta)) then
      TDirectory.CreateDirectory(sCarpeta);
    TFile.WriteAllText(AArchivo, sXmlFirmado, TEncoding.UTF8);
    GuardarXmlFactura(ARepositorio, AContextoSesion, ASerie, ANumero,
      sXmlFirmado);
    Result.Archivo := AArchivo;
    Result.NumeroSerieCertificado := DatosCert.NumeroSerie;
    Result.TitularCertificado := DatosCert.Titular;
    Result.HuellaSha1Certificado := DatosCert.HuellaSha1;
  finally
    FreeAndNil(QryLin);
    FreeAndNil(QryCab);
  end;
end;

end.
