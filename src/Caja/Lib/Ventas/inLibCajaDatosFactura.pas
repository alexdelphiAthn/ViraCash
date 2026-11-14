{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaDatosFactura                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Datos de factura compartidos por caja, impresión y persistencia.          }
{******************************************************************************}
unit inLibCajaDatosFactura;

interface

uses
  Data.DB;

type
  TDatosCabeceraFactura = record
    Fecha: TDateTime;
    TipoFactura: string;
    CodigoCliente: string;
    RazonSocialEmp: string;
    NifEmp: string;
    MovilEmp: string;
    EmailEmp: string;
    Direccion1Emp: string;
    Direccion2Emp: string;
    PoblacionEmp: string;
    ProvinciaEmp: string;
    CPostalEmp: string;
    CodigoPaisEmp: string;
    NombrePaisEmp: string;
    EsRetencionesEmp: string;
    GrupoZonaIvaEmp: string;
    RazonSocialCli: string;
    NifCli: string;
    MovilCli: string;
    EmailCli: string;
    Direccion1Cli: string;
    Direccion2Cli: string;
    PoblacionCli: string;
    ProvinciaCli: string;
    CPostalCli: string;
    CodigoPaisCli: string;
    NombrePaisCli: string;
    CodigoOficinaContable: string;
    CodigoOrganoGestor: string;
    CodigoUnidadTramitadora: string;
    CodigoIva: string;
    Tarifa: string;
    EsIvaRecargo: string;
    EsIvaExento: string;
    EsImpInclTarifa: string;
    PorcIvaN: Currency;
    TotalIvaN: Currency;
    PorcReN: Currency;
    TotalReN: Currency;
    BaseIN: Currency;
    PorcIvaR: Currency;
    TotalIvaR: Currency;
    PorcReR: Currency;
    TotalReR: Currency;
    BaseIR: Currency;
    PorcIvaS: Currency;
    TotalIvaS: Currency;
    PorcReS: Currency;
    TotalReS: Currency;
    BaseIS: Currency;
    PorcIvaE: Currency;
    TotalIvaE: Currency;
    PorcReE: Currency;
    TotalReE: Currency;
    BaseIE: Currency;
    TotalBases: Currency;
    TotalImpuestos: Currency;
    TotalRetencion: Currency;
    PorcRetencion: Currency;
    TotalLiquido: Currency;
    FormaPago: string;
    Comentarios: string;
  end;

  // FZ-ISSUE-200: factura a la que se refiere una rectificativa o
  // sustitutiva de caja, con el motivo anotado en la devolucion.
  TReferenciaRectificacionTicket = record
    Encontrada: Boolean;
    TipoRelacion: string;
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
    Motivo: string;
  end;

// Importe con IVA anterior al descuento, redondeado por linea.
function ImporteBrutoLineaTicket(ALinea: TDataSet): Currency;

function LeerCabeceraFactura(
  ADataSet: TDataSet): TDatosCabeceraFactura;

function FormatearTituloFacturaCaja(const ATipo, ADocumento: string): string;

// Lineas del ticket (maximo AAnchoLinea caracteres) que identifican la
// factura rectificada o sustituida. Vacio si no hay referencia.
function LineasReferenciaRectificacion(
  const AReferencia: TReferenciaRectificacionTicket;
  const AFormatoDocumento: string;
  AAnchoLinea: Integer): TArray<string>;

// FZ-ISSUE-369: las líneas de caja suman el total con IVA; la factura
// completa a un cliente en recargo o con retención cobra además el recargo
// y descuenta la retención. La diferencia pasa a la venta (AVentas) o, si
// no hay venta, a la devolución (ADevoluciones, en positivo), para que el
// importe de la operación sea el líquido cobrado.
procedure RepartirAjusteRecargoRetencion(
  const ACabecera: TDatosCabeceraFactura;
  var AVentas, ADevoluciones: Currency);

implementation

uses
  System.SysUtils, System.Math, inLibMsgTickets, inLibFormatoDocumento;

procedure AnadirTextoPartido(var ALineas: TArray<string>;
  const ATexto: string; AAnchoLinea: Integer);
var
  sResto: string;
begin
  sResto := Trim(ATexto);
  while sResto <> '' do
  begin
    ALineas := ALineas + [Copy(sResto, 1, AAnchoLinea)];
    sResto := Trim(Copy(sResto, AAnchoLinea + 1, MaxInt));
  end;
end;

function LineasReferenciaRectificacion(
  const AReferencia: TReferenciaRectificacionTicket;
  const AFormatoDocumento: string;
  AAnchoLinea: Integer): TArray<string>;
var
  sDocumento: string;
  sPlantilla: string;
begin
  Result := nil;
  if AReferencia.Encontrada and (Trim(AReferencia.Serie) <> '') and
     (Trim(AReferencia.Numero) <> '') then
  begin
    sDocumento := FormatearDocumento(
      AFormatoDocumento, AReferencia.Serie, AReferencia.Numero);
    sPlantilla := STicketRectificaA;
    if SameText(Trim(AReferencia.TipoRelacion), 'SUSTITUYE') then
      sPlantilla := STicketSustituyeA;
    AnadirTextoPartido(
      Result, Format(sPlantilla, [sDocumento]), AAnchoLinea);
    if AReferencia.Fecha <> 0 then
      AnadirTextoPartido(
        Result,
        Format(STicketFechaFacturaOriginal,
          [FormatDateTime('dd/mm/yyyy', AReferencia.Fecha)]),
        AAnchoLinea);
  end;
end;

procedure RepartirAjusteRecargoRetencion(
  const ACabecera: TDatosCabeceraFactura;
  var AVentas, ADevoluciones: Currency);
var
  cAjuste: Currency;
begin
  cAjuste := ACabecera.TotalReN + ACabecera.TotalReR + ACabecera.TotalReS +
    ACabecera.TotalReE - ACabecera.TotalRetencion;
  if AVentas > 0 then
    AVentas := AVentas + cAjuste
  else if ADevoluciones > 0 then
    ADevoluciones := ADevoluciones - cAjuste;
end;

function FormatearTituloFacturaCaja(const ATipo, ADocumento: string): string;
var
  Plantilla: string;
begin
  Plantilla := STicketFacturaSimplificadaNumero;
  if SameText(Trim(ATipo), 'RECTIFICATIVA') then
    Plantilla := STicketFacturaRectificativaNumero
  else if SameText(Trim(ATipo), 'NORMAL') then
    Plantilla := STicketFacturaNumero;
  Result := Format(Plantilla, [ADocumento]);
end;

function ImporteBrutoLineaTicket(ALinea: TDataSet): Currency;
var
  cBruto: Currency;
begin
  Result := ALinea.FieldByName('TOTAL_FACLIN').AsCurrency;
  if (ALinea.FindField('PRECIO_SALIDA_FACLIN') <> nil) and
     (ALinea.FindField('PRECIO_DTO_FACLIN') <> nil) and
     (ALinea.FieldByName('PRECIO_DTO_FACLIN').AsCurrency <> 0) then
  begin
    cBruto := ALinea.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency *
      ALinea.FieldByName('CANTIDAD_FACLIN').AsFloat;
    if (ALinea.FindField('ESIMP_INCL_TARIFA_FACLIN') <> nil) and
       SameText(ALinea.FieldByName(
         'ESIMP_INCL_TARIFA_FACLIN').AsString, 'N') then
      cBruto := cBruto * (1 + ALinea.FieldByName(
        'PORCENTAJE_IVA_FACLIN').AsFloat / 100);
    Result := SimpleRoundTo(cBruto, -2);
  end;
end;

function LeerCabeceraFactura(
  ADataSet: TDataSet): TDatosCabeceraFactura;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := ADataSet.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := ADataSet.FindField(ANombre);
  end;
begin
  Result := Default(TDatosCabeceraFactura);
  if FindField('TIPO_FAC') <> nil then
    Result.TipoFactura := FieldByName('TIPO_FAC').AsString;
  Result.Fecha := FieldByName('FECHA_FAC').AsDateTime;
    Result.CodigoCliente := Trim(
      FieldByName('CODIGO_CLI_FAC').AsString);
    if Result.CodigoCliente = '' then
      Result.CodigoCliente := '0';
    Result.RazonSocialEmp :=
      FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString;
    Result.NifEmp := FieldByName('NIF_EMPRESA_FAC').AsString;
    Result.MovilEmp := FieldByName('MOVIL_EMPRESA_FAC').AsString;
    Result.EmailEmp := FieldByName('EMAIL_EMPRESA_FAC').AsString;
    Result.Direccion1Emp :=
      FieldByName('DIRECCION1_EMPRESA_FAC').AsString;
    Result.Direccion2Emp :=
      FieldByName('DIRECCION2_EMPRESA_FAC').AsString;
    Result.PoblacionEmp :=
      FieldByName('POBLACION_EMPRESA_FAC').AsString;
    Result.ProvinciaEmp :=
      FieldByName('PROVINCIA_EMPRESA_FAC').AsString;
    Result.CPostalEmp :=
      FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString;
    Result.CodigoPaisEmp :=
      FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString;
    Result.NombrePaisEmp :=
      FieldByName('NOMBRE_PAI_EMPRESA_FAC').AsString;
    Result.EsRetencionesEmp :=
      FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString;
    Result.GrupoZonaIvaEmp :=
      FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
    Result.RazonSocialCli :=
      FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString;
    Result.NifCli := FieldByName('NIF_CLIENTE_FAC').AsString;
    Result.MovilCli := FieldByName('MOVIL_CLIENTE_FAC').AsString;
    Result.EmailCli := FieldByName('EMAIL_CLIENTE_FAC').AsString;
    Result.Direccion1Cli :=
      FieldByName('DIRECCION1_CLIENTE_FAC').AsString;
    Result.Direccion2Cli :=
      FieldByName('DIRECCION2_CLIENTE_FAC').AsString;
    Result.PoblacionCli :=
      FieldByName('POBLACION_CLIENTE_FAC').AsString;
    Result.ProvinciaCli :=
      FieldByName('PROVINCIA_CLIENTE_FAC').AsString;
    Result.CPostalCli :=
      FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString;
    Result.CodigoPaisCli :=
      FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString;
    Result.NombrePaisCli :=
      FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString;
    if FindField('CODIGO_OFICINA_CONTABLE_FAC') <> nil then
      Result.CodigoOficinaContable :=
        FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString;
    if FindField('CODIGO_ORGANO_GESTOR_FAC') <> nil then
      Result.CodigoOrganoGestor :=
        FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString;
    if FindField('CODIGO_UNIDAD_TRAMITADORA_FAC') <> nil then
      Result.CodigoUnidadTramitadora :=
        FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString;
    Result.CodigoIva := FieldByName('CODIGO_IVA_FAC').AsString;
    Result.Tarifa :=
      FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    Result.EsIvaRecargo :=
      FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString;
    Result.EsIvaExento :=
      FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString;
    Result.EsImpInclTarifa :=
      FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
    Result.PorcIvaN :=
      FieldByName('PORCENTAJE_IVAN_FAC').AsCurrency;
    Result.TotalIvaN := FieldByName('TOTAL_IVAN_FAC').AsCurrency;
    Result.PorcReN := FieldByName('PORCENTAJE_REN_FAC').AsCurrency;
    Result.TotalReN := FieldByName('TOTAL_REN_FAC').AsCurrency;
    Result.BaseIN := FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency;
    Result.PorcIvaR :=
      FieldByName('PORCENTAJE_IVAR_FAC').AsCurrency;
    Result.TotalIvaR := FieldByName('TOTAL_IVAR_FAC').AsCurrency;
    Result.PorcReR := FieldByName('PORCENTAJE_RER_FAC').AsCurrency;
    Result.TotalReR := FieldByName('TOTAL_RER_FAC').AsCurrency;
    Result.BaseIR := FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency;
    Result.PorcIvaS :=
      FieldByName('PORCENTAJE_IVAS_FAC').AsCurrency;
    Result.TotalIvaS := FieldByName('TOTAL_IVAS_FAC').AsCurrency;
    Result.PorcReS := FieldByName('PORCENTAJE_RES_FAC').AsCurrency;
    Result.TotalReS := FieldByName('TOTAL_RES_FAC').AsCurrency;
    Result.BaseIS := FieldByName('TOTAL_BASEI_IVAS_FAC').AsCurrency;
    Result.PorcIvaE :=
      FieldByName('PORCENTAJE_IVAE_FAC').AsCurrency;
    Result.TotalIvaE := FieldByName('TOTAL_IVAE_FAC').AsCurrency;
    Result.PorcReE := FieldByName('PORCENTAJE_REE_FAC').AsCurrency;
    Result.TotalReE := FieldByName('TOTAL_REE_FAC').AsCurrency;
    Result.BaseIE := FieldByName('TOTAL_BASEI_IVAE_FAC').AsCurrency;
    Result.TotalBases := FieldByName('TOTAL_BASES_FAC').AsCurrency;
    Result.TotalImpuestos :=
      FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
    Result.TotalRetencion :=
      FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
    Result.PorcRetencion :=
      FieldByName('PORCENTAJE_RETENCION_FAC').AsCurrency;
    Result.TotalLiquido :=
      FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
  Result.FormaPago := FieldByName('FORMA_PAGO_FAC').AsString;
  Result.Comentarios := FieldByName('COMENTARIOS_FAC').AsString;
end;

end.
