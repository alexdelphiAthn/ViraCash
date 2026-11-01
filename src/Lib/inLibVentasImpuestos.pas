{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVentasImpuestos                                          }
{    Tipo:       Libreria (sin formulario)                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       26/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Calculo fiscal comun de documentos de venta. Agrupa bases e impuestos     }
{    por tipo de IVA y respeta los campos disponibles en cada documento.       }
{******************************************************************************}
unit inLibVentasImpuestos;

interface

uses
  System.SysUtils, Data.DB, inLibImpuestosLecturasIntf;

procedure AplicarPorcentajesIvaVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);

function PorcentajeIvaDocumentoVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera, ATipoIva: string): Double;

procedure PrepararLineaFiscalVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);

// Total de la linea en edicion con lo que ya tiene (cantidad, precio
// maestro segun ESIMP_INCL_TARIFA y % de IVA de la linea), sin consultas:
// para refrescarlo al cambiar la cantidad o el precio antes de grabar.
// El calculo fiscal completo sigue en PrepararLineaFiscalVenta.
procedure RecalcularTotalLineaVenta(ALinea: TDataSet;
  const ASufijoLinea, ACampoTotalLinea: string);

// True si AField es uno de los campos de la linea de venta de los que
// depende su total (cantidad, precios, impuestos incluidos).
function EsCampoImporteLineaVenta(AField: TField;
  const ASufijoLinea: string): Boolean;

procedure AplicarDescuentoLineaVenta(AField: TField;
  const ASufijoLinea: string);

procedure CalcularTotalesDocumentoVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);

// Numero total de prendas del documento: suma CANTIDAD_<sufijo linea> de
// todas las lineas reales (ignora el filtro visual del pivote de tallas).
// No requiere que exista un campo TOTAL_PRENDAS_xxx en la cabecera; el
// formulario lo muestra directamente en un label de la pestana Totales.
function TotalPrendasLineasVenta(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string): Double;

implementation

uses
  System.Variants, inLibImpuestosComun, inLibMotorFiscalVenta,
  inLibRedondeo, inLibMsgVentas;

const
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE : array[0..3] of string = ('REN', 'RER', 'RES', 'REE');



function CampoFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := Date;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsDateTime;
  end;
end;





function EsSi(ADataSet: TDataSet; const ACampo: string): Boolean;
begin
  Result := UpperCase(Trim(CampoString(ADataSet, ACampo))) = 'S';
end;






// FZ-ISSUE-205: base de la linea a centimos. Con IVA incluido manda el
// PVP: primero el total con IVA de la linea y de el la base.
function CalcularBaseLineaVenta(ACantidad, APrecioSiva, APrecioCiva,
  APorcentajeIva: Double; AImpuestosIncluidos: Boolean): Double;
var
  rFactorIva: Double;
begin
  if AImpuestosIncluidos then
  begin
    Result := RedondearACentimos(ACantidad * APrecioCiva);
    rFactorIva := 1 + APorcentajeIva / 100;
    if rFactorIva <> 0 then
      Result := RedondearACentimos(Result / rFactorIva);
  end
  else
    Result := RedondearACentimos(ACantidad * APrecioSiva);
end;

function CampoLineaCambiado(ALinea: TDataSet;
  const ACampo: string): Boolean;
var
  oCampo: TField;
begin
  oCampo := ALinea.FindField(ACampo);
  Result := (oCampo <> nil) and
    not VarSameValue(oCampo.OldValue, oCampo.Value);
end;

// El calculo de totales reparte el centimo de las lineas con IVA incluido
// (CalcularTotalesDocumentoVenta): si al volver a grabar la linea solo
// difiere en ese centimo y no cambio nada de lo que fija su importe, se
// conserva el ajuste en vez de deshacerlo.
function ConservarBaseAjustada(ALinea: TDataSet;
  const ASufijoLinea, ACampoTotalLinea: string;
  ABaseCalculada: Double): Double;
var
  oTotal: TField;
begin
  Result := ABaseCalculada;
  oTotal := ALinea.FindField(ACampoTotalLinea);
  if (ALinea.State = dsEdit) and (oTotal <> nil) and
     (not oTotal.IsNull) and
     (Abs(oTotal.AsFloat - ABaseCalculada) <= 0.0101) and
     not CampoLineaCambiado(ALinea, 'CANTIDAD_' + ASufijoLinea) and
     not CampoLineaCambiado(ALinea,
       'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea) and
     not CampoLineaCambiado(ALinea,
       'ESIMP_INCL_TARIFA_' + ASufijoLinea) then
    Result := oTotal.AsFloat;
end;

function LeerPorcentajeRetencionEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string; AFecha: TDateTime): Double;
begin
  Result := 0;
  if Assigned(ALecturas) and (Trim(ACodigoEmp) <> '') and
     (Trim(ACodigoEmp) <> '0') then
    Result := ALecturas.LeerRetencionEmpresa(ACodigoEmp, AFecha);
end;



function PorcentajeReCabecera(ACabecera: TDataSet;
  const ASufijoCabecera, ATipoIva: string): Double;
var
  iIndice: Integer;
begin
  iIndice := IndiceTipoIva(ATipoIva);
  Result := CampoFloat(ACabecera,
    'PORCENTAJE_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera);
end;

function PorcentajeIvaDocumentoVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera, ATipoIva: string): Double;
var
  bEncontrado: Boolean;
  iIndice: Integer;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  Result := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera, ATipoIva);
  iIndice := IndiceTipoIva(ATipoIva);
  bEncontrado := False;
  sCodigoIva := Trim(CampoString(ACabecera,
    'CODIGO_IVA_' + ASufijoCabecera));
  if (sCodigoIva <> '') and (sCodigoIva <> '0') then
    bEncontrado := LeerPorcentajesIvaPorCodigo(ALecturas, sCodigoIva,
      rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE);
  if not bEncontrado then
  begin
    sEmpresa := CampoString(ACabecera,
      'CODIGO_EMP_' + ASufijoCabecera);
    bEncontrado := LeerPorcentajesIvaPorEmpresa(ALecturas, sEmpresa,
      sCodigoIva, rIvaN, rIvaR, rIvaS, rIvaE,
      rRecN, rRecR, rRecS, rRecE);
  end;
  if bEncontrado then
  begin
    if iIndice = 0 then
      Result := rIvaN
    else if iIndice = 1 then
      Result := rIvaR
    else if iIndice = 2 then
      Result := rIvaS
    else
      Result := rIvaE;
  end;
end;


function ClienteExento(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := EsSi(ACabecera, 'ESIVA_EXENTO_CLIENTE_' + ASufijoCabecera) or
            EsSi(ACabecera,
                 'ESINTRACOMUNITARIO_CLIENTE_' + ASufijoCabecera);
end;

function AplicaRecargoVenta(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := EsSi(ACabecera, 'ESIVA_RECARGO_CLIENTE_' + ASufijoCabecera);
  if CampoString(ACabecera,
     'ESAPLICA_RE_ZONA_IVA_' + ASufijoCabecera) = 'N' then
    Result := False;
end;

function TieneDatosClienteRetencion(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
var
  sNif, sRazon, sDireccion: string;
begin
  sNif := Trim(CampoString(ACabecera,
    'NIF_CLIENTE_' + ASufijoCabecera));
  sRazon := Trim(CampoString(ACabecera,
    'RAZON_SOCIAL_CLIENTE_' + ASufijoCabecera));
  if sRazon = '' then
    sRazon := Trim(CampoString(ACabecera,
      'RAZON_SOCIAL_CLIENTE_FISCAL_' + ASufijoCabecera));
  sDireccion := Trim(CampoString(ACabecera,
    'DIRECCION1_CLIENTE_' + ASufijoCabecera));
  if sDireccion = '' then
    sDireccion := Trim(CampoString(ACabecera,
      'DIRECCION1_CLIENTE_FISCAL_' + ASufijoCabecera));
  Result := (sNif <> '') and (sRazon <> '') and (sDireccion <> '');
end;

function CrearConfiguracionMotorFiscalVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string):
  TConfiguracionMotorFiscalVenta;
var
  bAplicaCliente, bAplicaEmpresa, bActivoFijo, bAgricolaEmpresa: Boolean;
  rPorRetencion: Double;
  sEmpresa: string;
  dFecha: TDateTime;
begin
  Result := Default(TConfiguracionMotorFiscalVenta);
  // FZ-ISSUE-205: a centimos, IVA por tipo y, con IVA incluido, manda el
  // PVP (mismo criterio que las facturas: el documento fiscal cuadra).
  Result.RedondearPorLinea := True;
  // Presupuestos y pedidos conservan las bases redondeadas de sus lineas.
  Result.CalcularIvaIncluidoPorDiferencia :=
    not (SameText(ASufijoCabecera, 'PRE') or
      SameText(ASufijoCabecera, 'PED'));
  Result.AplicaRecargo :=
    AplicaRecargoVenta(ACabecera, ASufijoCabecera);
  Result.ClienteConDatosFiscales := True;
  Result.RetencionIncluyeImpuestos := EsSi(ACabecera,
    'ESIRPF_IMP_INCL_ZONA_IVA_' + ASufijoCabecera);
  bAplicaCliente := EsSi(ACabecera,
    'ESRETENCIONES_CLIENTE_' + ASufijoCabecera);
  bAplicaEmpresa := EsSi(ACabecera,
    'ESRETENCIONES_EMPRESA_' + ASufijoCabecera);
  bActivoFijo := EsSi(ACabecera,
    'ESVENTA_ACTIVO_FIJO_' + ASufijoCabecera);
  bAgricolaEmpresa := EsSi(ACabecera,
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_' + ASufijoCabecera);
  rPorRetencion := CampoFloat(ACabecera,
    'PORCENTAJE_RETENCION_' + ASufijoCabecera);
  Result.AplicaRetencion :=
    bAplicaCliente and
    bAplicaEmpresa and
    TieneDatosClienteRetencion(ACabecera, ASufijoCabecera) and
    not (bActivoFijo and bAgricolaEmpresa);
  if Result.AplicaRetencion and (rPorRetencion = 0) then
  begin
    sEmpresa := CampoString(ACabecera,
      'CODIGO_EMP_' + ASufijoCabecera);
    dFecha := CampoFecha(ACabecera, 'FECHA_' + ASufijoCabecera);
    rPorRetencion := LeerPorcentajeRetencionEmpresa(ALecturas,
      sEmpresa, dFecha);
    PonerFloat(ACabecera,
      'PORCENTAJE_RETENCION_' + ASufijoCabecera, rPorRetencion);
  end
  else if bActivoFijo and bAgricolaEmpresa then
    PonerFloat(ACabecera,
      'PORCENTAJE_RETENCION_' + ASufijoCabecera, 0);
  Result.PorcentajeRetencion := rPorRetencion;
  Result.PorcentajeDtoComercial := CampoFloat(ACabecera,
    'PORCENTAJE_DTO_COMERCIAL_' + ASufijoCabecera);
  Result.PorcentajeDtoFinanciero := CampoFloat(ACabecera,
    'PORCENTAJE_DTO_FINANCIERO_' + ASufijoCabecera);
end;

procedure AplicarZonaRecargoVenta(const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera, ACodigoIva: string);
var
  sAplicaRecargo: string;
begin
  sAplicaRecargo := 'N';
  if ALecturas.LeerAplicaRecargoZona(ACodigoIva) then
    sAplicaRecargo := 'S';
  PonerString(ACabecera, 'ESAPLICA_RE_ZONA_IVA_' + ASufijoCabecera,
    sAplicaRecargo);
end;

procedure AplicarPorcentajesIvaVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  bEncontrado: Boolean;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  if Assigned(ACabecera) then
  begin
    sCodigoIva := Trim(CampoString(ACabecera,
      'CODIGO_IVA_' + ASufijoCabecera));
    bEncontrado := False;
    if (sCodigoIva <> '') and (sCodigoIva <> '0') then
      bEncontrado := LeerPorcentajesIvaPorCodigo(
        ALecturas, sCodigoIva,
        rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE);
    if not bEncontrado then
    begin
      sEmpresa := CampoString(ACabecera,
        'CODIGO_EMP_' + ASufijoCabecera);
      bEncontrado := LeerPorcentajesIvaPorEmpresa(
        ALecturas, sEmpresa,
        sCodigoIva, rIvaN, rIvaR, rIvaS, rIvaE,
        rRecN, rRecR, rRecS, rRecE);
    end;
    if bEncontrado then
    begin
      AplicarZonaRecargoVenta(ALecturas, ACabecera, ASufijoCabecera,
        sCodigoIva);
      PonerString(ACabecera, 'CODIGO_IVA_' + ASufijoCabecera,
                  sCodigoIva);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAN_' + ASufijoCabecera,
                 rIvaN);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAR_' + ASufijoCabecera,
                 rIvaR);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAS_' + ASufijoCabecera,
                 rIvaS);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAE_' + ASufijoCabecera,
                 rIvaE);
      PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera,
                 rRecN);
      PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera,
                 rRecR);
      PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera,
                 rRecS);
      PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera,
                 rRecE);
    end;
  end;
end;

procedure PrepararLineaFiscalVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);
var
  rCantidad, rFactorIva, rPorIva, rPrecioCiva, rPrecioSiva, rBase: Double;
  bImpuestosIncluidos: Boolean;
  sArticulo, sCampoTipo, sTipoArt, sTipoIva: string;
begin
  if Assigned(ACabecera) and Assigned(ALinea) and ALinea.Active then
  begin
    sCampoTipo := 'TIPO_IVA_ARTICULO_' + ASufijoLinea;
    sArticulo := CampoString(ALinea, 'CODIGO_ART_' + ASufijoLinea);
    sTipoIva := NormalizarTipoIva(CampoString(ALinea, sCampoTipo));
    if ClienteExento(ACabecera, ASufijoCabecera) then
      sTipoIva := 'E'
    else
    begin
      sTipoArt := ObtenerTipoIvaArticulo(ALecturas, sArticulo);
      if sTipoArt <> '' then
        sTipoIva := sTipoArt;
    end;
    rPorIva := PorcentajeIvaDocumentoVenta(ALecturas, ACabecera,
      ASufijoCabecera, sTipoIva);
    if ClienteExento(ACabecera, ASufijoCabecera) then
      rPorIva := 0;
    rCantidad := CampoFloat(ALinea, 'CANTIDAD_' + ASufijoLinea);
    rFactorIva := 1 + rPorIva / 100;
    bImpuestosIncluidos := EsSi(ALinea,
      'ESIMP_INCL_TARIFA_' + ASufijoLinea);
    if bImpuestosIncluidos then
    begin
      // El PVP de una tarifa con impuestos es el precio maestro.
      rPrecioCiva := CampoFloat(ALinea,
        'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea);
      rPrecioSiva := rPrecioCiva;
      if rFactorIva <> 0 then
        rPrecioSiva := rPrecioCiva / rFactorIva;
    end
    else
    begin
      // En una tarifa sin impuestos la base es el precio maestro.
      rPrecioSiva := CampoFloat(ALinea,
        'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea);
      rPrecioCiva := rPrecioSiva * rFactorIva;
    end;
    if not (ALinea.State in dsEditModes) then
      ALinea.Edit;
    PonerString(ALinea, sCampoTipo, sTipoIva);
    PonerFloat(ALinea, 'PORCENTAJE_IVA_' + ASufijoLinea, rPorIva);
    PonerFloat(ALinea, 'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea,
      rPrecioSiva);
    PonerFloat(ALinea, 'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea,
      rPrecioCiva);
    rBase := CalcularBaseLineaVenta(rCantidad, rPrecioSiva, rPrecioCiva,
      rPorIva, bImpuestosIncluidos);
    if bImpuestosIncluidos then
      rBase := ConservarBaseAjustada(ALinea, ASufijoLinea,
        ACampoTotalLinea, rBase);
    PonerFloat(ALinea, ACampoTotalLinea, rBase);
  end;
end;

procedure RecalcularTotalLineaVenta(ALinea: TDataSet;
  const ASufijoLinea, ACampoTotalLinea: string);
begin
  if Assigned(ALinea) and (ALinea.State in dsEditModes) and
     (ALinea.FindField(ACampoTotalLinea) <> nil) then
    PonerFloat(ALinea, ACampoTotalLinea, CalcularBaseLineaVenta(
      CampoFloat(ALinea, 'CANTIDAD_' + ASufijoLinea),
      CampoFloat(ALinea, 'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea),
      CampoFloat(ALinea, 'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea),
      CampoFloat(ALinea, 'PORCENTAJE_IVA_' + ASufijoLinea),
      EsSi(ALinea, 'ESIMP_INCL_TARIFA_' + ASufijoLinea)));
end;

function EsCampoImporteLineaVenta(AField: TField;
  const ASufijoLinea: string): Boolean;
begin
  Result := (AField <> nil) and
    (SameText(AField.FieldName, 'CANTIDAD_' + ASufijoLinea) or
     SameText(AField.FieldName,
       'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea) or
     SameText(AField.FieldName,
       'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea) or
     SameText(AField.FieldName, 'ESIMP_INCL_TARIFA_' + ASufijoLinea));
end;

procedure SincronizarOrigenDescuentoVenta(AField: TField;
  const ASufijoLinea: string);
var
  Linea: TDataSet;
  Salida, Neto: Double;
begin
  if (AField <> nil) and (AField.DataSet.State in dsEditModes) and
     (AField.DataSet.FindField('PRECIO_SALIDA_' + ASufijoLinea) <> nil) then
  begin
    Linea := AField.DataSet;
    if (AField.FieldName = 'CODIGO_ART_' + ASufijoLinea) or
       (AField.FieldName = 'CODIGO_UNIDAD_' + ASufijoLinea) then
    begin
      Linea.FieldByName('PRECIO_SALIDA_' + ASufijoLinea).Clear;
      PonerFloat(Linea, 'PORCENTAJE_DTO_' + ASufijoLinea, 0);
      PonerFloat(Linea, 'PRECIO_DTO_' + ASufijoLinea, 0);
    end
    else if (AField.FieldName =
      'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea) or
      (AField.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea) then
    begin
      Neto := AField.AsFloat;
      Salida := CampoFloat(Linea, 'PRECIO_SALIDA_' + ASufijoLinea);
      // Mientras se resuelve una referencia, la tarifa fija el precio base.
      if Linea.FieldByName('PRECIO_SALIDA_' + ASufijoLinea).IsNull then
        PonerFloat(Linea, 'PRECIO_DTO_' + ASufijoLinea, 0)
      else if ((AField.FieldName =
          'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea) and
          EsSi(Linea, 'ESIMP_INCL_TARIFA_' + ASufijoLinea)) or
        ((AField.FieldName =
          'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea) and
          not EsSi(Linea, 'ESIMP_INCL_TARIFA_' + ASufijoLinea)) then
      begin
        PonerFloat(Linea, 'PRECIO_DTO_' + ASufijoLinea, Salida - Neto);
        if Salida <> 0 then
          PonerFloat(Linea, 'PORCENTAJE_DTO_' + ASufijoLinea,
            (Salida - Neto) / Salida * 100);
      end;
    end;
  end;
end;

procedure AplicarDescuentoLineaVenta(AField: TField;
  const ASufijoLinea: string);
var
  Linea: TDataSet;
  Salida, Porcentaje, Descuento, Neto, Factor: Double;
  CampoMaestro: string;
begin
  SincronizarOrigenDescuentoVenta(AField, ASufijoLinea);
  if (AField <> nil) and (AField.DataSet.State in dsEditModes) and
     ((AField.FieldName = 'PORCENTAJE_DTO_' + ASufijoLinea) or
      (AField.FieldName = 'PRECIO_DTO_' + ASufijoLinea) or
      (AField.FieldName = 'PRECIO_SALIDA_' + ASufijoLinea)) then
  begin
    Linea := AField.DataSet;
    CampoMaestro := 'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea;
    if EsSi(Linea, 'ESIMP_INCL_TARIFA_' + ASufijoLinea) then
      CampoMaestro := 'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea;
    if Linea.FieldByName('PRECIO_SALIDA_' + ASufijoLinea).IsNull then
      PonerFloat(Linea, 'PRECIO_SALIDA_' + ASufijoLinea,
        CampoFloat(Linea, CampoMaestro));
    Salida := CampoFloat(Linea, 'PRECIO_SALIDA_' + ASufijoLinea);
    Porcentaje := CampoFloat(Linea, 'PORCENTAJE_DTO_' + ASufijoLinea);
    Descuento := CampoFloat(Linea, 'PRECIO_DTO_' + ASufijoLinea);
    if AField.FieldName = 'PRECIO_DTO_' + ASufijoLinea then
    begin
      Porcentaje := 0;
      if Salida <> 0 then
        Porcentaje := Descuento / Salida * 100;
    end
    else
      Descuento := Salida * Porcentaje / 100;
    if (Porcentaje < 0) or (Porcentaje > 100) then
      raise EArgumentException.Create(SErrorPorcentajeDescuentoVenta);
    Neto := Salida - Descuento;
    PonerFloat(Linea, 'PORCENTAJE_DTO_' + ASufijoLinea, Porcentaje);
    PonerFloat(Linea, 'PRECIO_DTO_' + ASufijoLinea, Descuento);
    Factor := 1 + CampoFloat(Linea, 'PORCENTAJE_IVA_' + ASufijoLinea) / 100;
    PonerFloat(Linea, CampoMaestro, Neto);
    if EsSi(Linea, 'ESIMP_INCL_TARIFA_' + ASufijoLinea) then
      PonerFloat(Linea, 'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea,
        Neto / Factor)
    else
      PonerFloat(Linea, 'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea,
        Neto * Factor);
    RecalcularTotalLineaVenta(Linea, ASufijoLinea, 'TOTAL_' + ASufijoLinea);
  end;
end;

procedure AgregarLineaMotorFiscalVenta(
  var ALineas: TLineasMotorFiscalVenta;
  const ATipoIva: string;
  ABase, APorcentajeIva, APorcentajeRecargo: Double;
  AImpuestosIncluidos: Boolean; ATotalConIva: Double);
var
  Indice: Integer;
begin
  Indice := Length(ALineas);
  SetLength(ALineas, Indice + 1);
  ALineas[Indice] := Default(TLineaMotorFiscalVenta);
  ALineas[Indice].TipoIva := ATipoIva;
  ALineas[Indice].Base := ABase;
  ALineas[Indice].ImpuestosIncluidos := AImpuestosIncluidos;
  if AImpuestosIncluidos then
    ALineas[Indice].TotalConIva := ATotalConIva
  else
    ALineas[Indice].TotalConIva :=
      ABase + (ABase * APorcentajeIva / 100);
  ALineas[Indice].PorcentajeIva := APorcentajeIva;
  ALineas[Indice].PorcentajeRecargo := APorcentajeRecargo;
  ALineas[Indice].Bruto := ABase;
end;

function CargarLineasMotorFiscalVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea,
  ACampoPorcentajeIvaLinea: string): TLineasMotorFiscalVenta;
var
  bk: TBookmark;
  rPorIva, rPorRe, rTotal, rTotalConIva: Double;
  sArticulo, sSufijoLinea, sTipoArt, sTipoIva, sTipoLinea: string;
  bClienteExento, bFiltroActivo, bIncluidos: Boolean;
begin
  SetLength(Result, 0);
  sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
  bClienteExento := ClienteExento(ACabecera, ASufijoCabecera);
  bk := ALineas.GetBookmark;
  bFiltroActivo := ALineas.Filtered;
  try
    ALineas.DisableControls;
    if bFiltroActivo then
      ALineas.Filtered := False;
    ALineas.First;
    while not ALineas.Eof do
    begin
      sTipoLinea := CampoString(ALineas, ACampoTipoIvaLinea);
      sTipoIva := NormalizarTipoIva(sTipoLinea);
      if bClienteExento then
        sTipoIva := 'E'
      else if sSufijoLinea <> '' then
      begin
        sArticulo := CampoString(ALineas,
          'CODIGO_ART_' + sSufijoLinea);
        sTipoArt := ObtenerTipoIvaArticulo(ALecturas, sArticulo);
        if sTipoArt <> '' then
          sTipoIva := sTipoArt;
      end;
      rTotal := CampoFloat(ALineas, ACampoTotalLinea);
      rPorIva := CampoFloat(ALineas, ACampoPorcentajeIvaLinea);
      if rPorIva = 0 then
        rPorIva := PorcentajeIvaCabecera(ACabecera,
          ASufijoCabecera, sTipoIva);
      if bClienteExento then
        rPorIva := 0;
      rPorRe := PorcentajeReCabecera(ACabecera,
        ASufijoCabecera, sTipoIva);
      // Con IVA incluido manda el PVP: el motor desglosa la suma.
      bIncluidos := (sSufijoLinea <> '') and
        EsSi(ALineas, 'ESIMP_INCL_TARIFA_' + sSufijoLinea);
      rTotalConIva := 0;
      if bIncluidos then
        rTotalConIva := RedondearACentimos(
          CampoFloat(ALineas, 'CANTIDAD_' + sSufijoLinea) *
          CampoFloat(ALineas,
            'PRECIO_VENTA_CIVA_ARTICULO_' + sSufijoLinea));
      AgregarLineaMotorFiscalVenta(Result, sTipoIva,
        rTotal, rPorIva, rPorRe, bIncluidos, rTotalConIva);
      ALineas.Next;
    end;
  finally
    if bFiltroActivo then
      ALineas.Filtered := True;
    if ALineas.BookmarkValid(bk) then
      ALineas.GotoBookmark(bk);
    ALineas.FreeBookmark(bk);
    ALineas.EnableControls;
  end;
end;

procedure EscribirTotalesTipoIvaVenta(ACabecera: TDataSet;
  const ASufijoCabecera: string; AIndice: Integer;
  const AResultado: TResultadoTipoIvaVenta);
begin
  PonerFloat(ACabecera,
    'TOTAL_BASEI_' + CODIGOS_IVA[AIndice] + '_' + ASufijoCabecera,
    AResultado.Base);
  PonerFloat(ACabecera,
    'TOTAL_' + CODIGOS_IVA[AIndice] + '_' + ASufijoCabecera,
    AResultado.ImporteIva);
  PonerFloat(ACabecera,
    'TOTAL_' + CODIGOS_RE[AIndice] + '_' + ASufijoCabecera,
    AResultado.ImporteRecargo);
end;

procedure EscribirResultadoMotorFiscalVenta(ACabecera: TDataSet;
  const ASufijoCabecera: string;
  const AResultado: TResultadoMotorFiscalVenta);
begin
  EscribirTotalesTipoIvaVenta(ACabecera,
    ASufijoCabecera, 0, AResultado.Normal);
  EscribirTotalesTipoIvaVenta(ACabecera,
    ASufijoCabecera, 1, AResultado.Reducido);
  EscribirTotalesTipoIvaVenta(ACabecera,
    ASufijoCabecera, 2, AResultado.SuperReducido);
  EscribirTotalesTipoIvaVenta(ACabecera,
    ASufijoCabecera, 3, AResultado.Exento);
  PonerFloat(ACabecera, 'TOTAL_DTO_COMERCIAL_' + ASufijoCabecera,
    AResultado.TotalDtoComercial);
  PonerFloat(ACabecera, 'TOTAL_DTO_FINANCIERO_' + ASufijoCabecera,
    AResultado.TotalDtoFinanciero);
  PonerFloat(ACabecera, 'TOTAL_BRUTO_' + ASufijoCabecera,
    AResultado.TotalBruto);
  PonerFloat(ACabecera, 'TOTAL_BASES_' + ASufijoCabecera,
    AResultado.TotalBases);
  PonerFloat(ACabecera, 'TOTAL_IMPUESTOS_' + ASufijoCabecera,
    AResultado.TotalImpuestos);
  PonerFloat(ACabecera, 'TOTAL_RETENCION_' + ASufijoCabecera,
    AResultado.TotalRetencion);
  PonerFloat(ACabecera, 'TOTAL_' + ASufijoCabecera,
    AResultado.TotalConImpuestos);
  PonerFloat(ACabecera, 'TOTAL_LIQUIDO_' + ASufijoCabecera,
    AResultado.TotalLiquido);
end;

// FZ-ISSUE-205: cada linea guarda la base que le asigna el motor (a
// centimos y, con IVA incluido, con el centimo de ajuste del tipo), para
// que las lineas sumen exactamente la base del pie. Mismo orden de
// recorrido que CargarLineasMotorFiscalVenta. Solo escribe las que
// cambian; con una linea en edicion no se recorre.
procedure AjustarBasesLineasVenta(ALineas: TDataSet;
  const ACampoTotalLinea: string; const ABases: TArray<Double>);
var
  bk: TBookmark;
  Indice: Integer;
  bFiltroActivo: Boolean;
begin
  if (ALineas.State = dsBrowse) and
     (ALineas.FindField(ACampoTotalLinea) <> nil) then
  begin
    bk := ALineas.GetBookmark;
    bFiltroActivo := ALineas.Filtered;
    try
      ALineas.DisableControls;
      if bFiltroActivo then
        ALineas.Filtered := False;
      ALineas.First;
      Indice := 0;
      while (not ALineas.Eof) and (Indice <= High(ABases)) do
      begin
        if CampoFloatDifiere(ALineas, ACampoTotalLinea,
             ABases[Indice]) then
        begin
          ALineas.Edit;
          ALineas.FieldByName(ACampoTotalLinea).AsFloat := ABases[Indice];
          ALineas.Post;
        end;
        Inc(Indice);
        ALineas.Next;
      end;
    finally
      if bFiltroActivo then
        ALineas.Filtered := True;
      if ALineas.BookmarkValid(bk) then
        ALineas.GotoBookmark(bk);
      ALineas.FreeBookmark(bk);
      ALineas.EnableControls;
    end;
  end;
end;

procedure CalcularTotalesDocumentoVenta(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);
var
  Configuracion: TConfiguracionMotorFiscalVenta;
  LineasMotor: TLineasMotorFiscalVenta;
  Resultado: TResultadoMotorFiscalVenta;
begin
  if Assigned(ACabecera) and Assigned(ALineas) and ALineas.Active then
  begin
    AplicarPorcentajesIvaVenta(
      ALecturas, ACabecera, ASufijoCabecera);
    Configuracion := CrearConfiguracionMotorFiscalVenta(
      ALecturas, ACabecera, ASufijoCabecera);
    LineasMotor := CargarLineasMotorFiscalVenta(ALecturas,
      ACabecera, ALineas, ASufijoCabecera, ACampoTotalLinea,
      ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea);
    Resultado := CalcularTotalesMotorFiscalVenta(
      LineasMotor, Configuracion);
    EscribirResultadoMotorFiscalVenta(
      ACabecera, ASufijoCabecera, Resultado);
    AjustarBasesLineasVenta(ALineas, ACampoTotalLinea,
      Resultado.BasesLinea);
  end;
end;

function TotalPrendasLineasVenta(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string): Double;
var
  bk: TBookmark;
  sSufijoLinea: string;
  bFiltroActivo: Boolean;
begin
  Result := 0;
  if Assigned(ALineas) and ALineas.Active and
     (not (ALineas.State in dsEditModes)) then
  begin
  // Con una linea en insercion/edicion NO se recorre: el First haria
  // CheckBrowseMode y cancelaria la linea a medio insertar, dejando
  // que el AfterInsert siguiera con el dataset ya en browse ('Dataset
  // not in edit or insert mode' al anadir linea, 09/07/26). El total
  // se refresca en el siguiente AfterPost.
  sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
  if sSufijoLinea <> '' then
  begin
  bk := ALineas.GetBookmark;
  bFiltroActivo := ALineas.Filtered;
  try
    ALineas.DisableControls;
    // El pivote de tallas filtra visualmente las lineas representantes.
    // El total de prendas debe sumar siempre todas las lineas reales.
    if bFiltroActivo then
      ALineas.Filtered := False;
    ALineas.First;
    while not ALineas.Eof do
    begin
      Result := Result + CampoFloat(ALineas, 'CANTIDAD_' + sSufijoLinea);
      ALineas.Next;
    end;
  finally
    if bFiltroActivo then
      ALineas.Filtered := True;
    if ALineas.BookmarkValid(bk) then
      ALineas.GotoBookmark(bk);
    ALineas.FreeBookmark(bk);
    ALineas.EnableControls;
  end;
  end;
  end;
end;

end.
