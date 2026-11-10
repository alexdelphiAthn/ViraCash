{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasImpuestos                                         }
{    Tipo:       Libreria (sin formulario)                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Calculo fiscal comun de documentos de compra. El precio de compra de      }
{    linea se mantiene siempre sin IVA; la marca de recargo de equivalencia    }
{    solo afecta al desglose de impuestos y al coste/PMP de movimientos.       }
{******************************************************************************}
unit inLibComprasImpuestos;

interface

uses
  System.SysUtils, Data.DB, inLibImpuestosLecturasIntf,
  inLibUnidadesMedida;

function CalcularPrecioNetoCompra(APrecio, ADescuento: Double): Double;

function ObtenerRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string): string;

function ObtenerIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  const ACodigoPrv: string): string;

procedure AplicarRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);

// El recargo de equivalencia de compras lo decide la empresa (casilla solo
// lectura en pantalla): se toma de ESIVA_RECARGO_COMPRAS_EMP en el alta y
// al cambiar la empresa del documento. Un documento ya grabado conserva su
// marca aunque cambie la ficha de la empresa (no se revaloran historicos).
procedure SincronizarRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure AplicarIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoProveedor, ACampoExento: string);

procedure AplicarPorcentajesIvaCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure AplicarPorcentajesRecargoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure PrepararLineaFiscalCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);

procedure CalcularTotalesDocumentoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);

// Numero total de prendas del documento: suma CANTIDAD_<sufijo linea> de
// todas las lineas reales (ignora el filtro visual del pivote de tallas).
// Si se indica ACampoTotalUnidades, la linea aporta ese campo cuando no
// es NULL (misma regla COALESCE que las vistas de cabecera: respeta el
// agregado de las lineas consolidadas del pivote antiguo).
// No requiere que exista un campo TOTAL_PRENDAS_xxx en la cabecera; el
// formulario lo muestra directamente en un label de la pestana Totales.
// Con AUnidades solo cuentan las lineas cuya unidad
// (TIPO_CANTIDAD_ARTICULO_<sufijo linea>) no admite decimales: metros o
// kilos no son prendas (FZ-ISSUE-208; misma regla que las vistas).
function TotalPrendasLineasCompra(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string;
  const ACampoTotalUnidades: string = '';
  AUnidades: TUnidadesMedida = nil): Double;

implementation

uses
  System.Variants, inLibImpuestosComun, inLibMotorFiscalVenta,
  inLibRedondeo, inLibMsgCompras;

const
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE : array[0..3] of string = ('REN', 'RER', 'RES', 'REE');



function CalcularPrecioNetoCompra(APrecio, ADescuento: Double): Double;
begin
  if (ADescuento < 0) or (ADescuento > 100) then
    raise EArgumentOutOfRangeException.Create(SErrorDescuentoLineaCompra);
  Result := APrecio * (1 - ADescuento / 100);
end;

function DocumentoCompraSinIva(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := (UpperCase(Trim(CampoString(ACabecera,
    'ESIVA_EXENTO_INTRACOMUNITARIO_' + ASufijoCabecera))) = 'S') or
    ((ASufijoCabecera = 'FACC') and
     SameText(CampoString(ACabecera, 'MODALIDAD_FACC'), 'REAGP'));
end;












function PorcentajeIvaDocumentoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera, ATipoIva: string): Double;
var
  bEncontrado: Boolean;
  iIndice: Integer;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  if DocumentoCompraSinIva(ACabecera, ASufijoCabecera) then
    Result := 0
  else
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
end;


function ImporteDescuentoGlobalCompra(ACabecera: TDataSet;
  const ASufijoCabecera, AConcepto: string; ABase: Double): Double;
var
  rPorcentaje, rTotal: Double;
begin
  Result := 0;
  if ABase > 0 then
  begin
    rPorcentaje := CampoFloat(ACabecera,
      'PORCENTAJE_DTO_' + AConcepto + '_' + ASufijoCabecera);
    rTotal := CampoFloat(ACabecera,
      'TOTAL_DTO_' + AConcepto + '_' + ASufijoCabecera);
    if Abs(rPorcentaje) > 0.000001 then
      rTotal := ABase * rPorcentaje / 100;
    if rTotal < 0 then
      rTotal := 0;
    if rTotal > ABase then
      rTotal := ABase;
    Result := rTotal;
  end;
end;

function FactorDescuentoComercialCompra(ATotalBruto,
  ADescuentoComercial: Double): Double;
begin
  Result := 1;
  if ATotalBruto > 0 then
  begin
    Result := 1 - ADescuentoComercial / ATotalBruto;
    if Result < 0 then
      Result := 0;
  end;
end;

function ObtenerRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string): string;
begin
  Result := 'N';
  if Assigned(ALecturas) and
     ALecturas.LeerRecargoComprasEmpresa(ACodigoEmp) then
    Result := 'S';
end;

function ObtenerIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  const ACodigoPrv: string): string;
begin
  Result := 'N';
  if Assigned(ALecturas) and
     ALecturas.LeerExentoIntracomunitarioProveedor(ACodigoPrv) then
    Result := 'S';
end;

procedure AplicarRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);
var
  sEmpresa: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoRecargo) <> nil) then
  begin
    sEmpresa := CampoString(ACabecera, ACampoEmpresa);
    PonerString(ACabecera, ACampoRecargo,
                ObtenerRecargoComprasEmpresa(ALecturas, sEmpresa));
  end;
end;

procedure SincronizarRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  oEmpresa: TField;
  bAplicar: Boolean;
begin
  if Assigned(ACabecera) and ACabecera.Active then
  begin
    oEmpresa := ACabecera.FindField('CODIGO_EMP_' + ASufijoCabecera);
    bAplicar := ACabecera.State = dsInsert;
    if (not bAplicar) and (ACabecera.State = dsEdit) and
       (oEmpresa <> nil) then
      bAplicar := Trim(VarToStr(oEmpresa.OldValue)) <>
                  Trim(oEmpresa.AsString);
    if bAplicar then
      AplicarRecargoComprasEmpresa(ALecturas, ACabecera,
        'CODIGO_EMP_' + ASufijoCabecera,
        'ESIVA_RECARGO_COMPRAS_' + ASufijoCabecera);
  end;
end;

procedure AplicarIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoProveedor, ACampoExento: string);
var
  sProveedor: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoExento) <> nil) then
  begin
    sProveedor := CampoString(ACabecera, ACampoProveedor);
    PonerString(ACabecera, ACampoExento,
      ObtenerIvaExentoIntracomunitarioProveedor(
        ALecturas, sProveedor));
  end;
end;

procedure AplicarPorcentajesIvaCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  bEncontrado: Boolean;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  if Assigned(ACabecera) then
  begin
    if DocumentoCompraSinIva(ACabecera, ASufijoCabecera) then
    begin
      PonerFloat(ACabecera, 'PORCENTAJE_IVAN_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAR_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAS_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAE_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera,
                 0);
    end
    else
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
      end
      else
        AplicarPorcentajesRecargoCompra(
          ALecturas, ACabecera, ASufijoCabecera);
    end
  end;
end;

procedure LeerPorcentajesRecargo(
  const ALecturas: ILecturasImpuestos;
  const ACodigoIva: string; out ARecargoNormal, ARecargoReducido,
  ARecargoSuper, ARecargoExento: Double);
var
  rIvaExento: Double;
  rIvaNormal: Double;
  rIvaReducido: Double;
  rIvaSuper: Double;
begin
  ARecargoNormal  := 0;
  ARecargoReducido:= 0;
  ARecargoSuper   := 0;
  ARecargoExento  := 0;
  LeerPorcentajesIvaPorCodigo(ALecturas, ACodigoIva,
    rIvaNormal, rIvaReducido, rIvaSuper, rIvaExento,
    ARecargoNormal, ARecargoReducido, ARecargoSuper,
    ARecargoExento);
end;

procedure AplicarPorcentajesRecargoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva: string;
begin
  if Assigned(ACabecera) then
  begin
    if DocumentoCompraSinIva(ACabecera, ASufijoCabecera) then
    begin
      rRecN := 0;
      rRecR := 0;
      rRecS := 0;
      rRecE := 0;
    end
    else
    begin
      sCodigoIva := CampoString(ACabecera,
        'CODIGO_IVA_' + ASufijoCabecera);
      LeerPorcentajesRecargo(ALecturas, sCodigoIva,
        rRecN, rRecR, rRecS,
        rRecE);
    end;
    PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera, rRecN);
    PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera, rRecR);
    PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera, rRecS);
    PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera, rRecE);
  end;
end;

procedure PrepararLineaFiscalCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);
var
  rCantidad, rPorIva, rPrecioSiva: Double;
  sArticulo, sCampoTipo, sTipoArt, sTipoIva: string;
begin
  if Assigned(ACabecera) and Assigned(ALinea) and ALinea.Active then
  begin
    sCampoTipo := 'TIPO_IVA_ARTICULO_' + ASufijoLinea;
    sArticulo := CampoString(ALinea, 'CODIGO_ART_' + ASufijoLinea);
    sTipoIva := NormalizarTipoIva(CampoString(ALinea, sCampoTipo));
    if DocumentoCompraSinIva(ACabecera, ASufijoCabecera) then
      sTipoIva := 'E'
    else
    begin
      sTipoArt := ObtenerTipoIvaArticulo(ALecturas, sArticulo);
      if sTipoArt <> '' then
        sTipoIva := sTipoArt;
    end;
    // No editar la cabecera desde el BeforePost de la linea: UniDAC
    // fuerza CheckBrowseMode del detalle y reentra en este mismo Post.
    rPorIva := PorcentajeIvaDocumentoCompra(ALecturas, ACabecera,
      ASufijoCabecera, sTipoIva);
    rCantidad := CampoFloat(ALinea, 'CANTIDAD_' + ASufijoLinea);
    rPrecioSiva := CampoFloat(ALinea,
      'PRECIO_COMPRA_SIVA_ARTICULO_' + ASufijoLinea);
    // El descuento de línea precede a los descuentos de cabecera.
    if (ASufijoLinea = 'PEDCLIN') or (ASufijoLinea = 'ALBCLIN') then
      rPrecioSiva := CalcularPrecioNetoCompra(rPrecioSiva,
        ALinea.FieldByName('PORCENTAJE_DTO_' + ASufijoLinea).AsFloat);
    if not (ALinea.State in dsEditModes) then
      ALinea.Edit;
    PonerString(ALinea, sCampoTipo, sTipoIva);
    PonerFloat(ALinea, 'PORCENTAJE_IVA_' + ASufijoLinea, rPorIva);
    PonerFloat(ALinea, 'PRECIO_COMPRA_CIVA_ARTICULO_' + ASufijoLinea,
      rPrecioSiva * (1 + rPorIva / 100));
    // FZ-ISSUE-207: el importe de la linea se guarda a centimos, como en
    // la factura del proveedor (125,50 x 4,35 = 545,93, no 545,925).
    PonerFloat(ALinea, ACampoTotalLinea,
      RedondearACentimos(rCantidad * rPrecioSiva));
  end;
end;

procedure AgregarLineaMotorFiscalCompra(
  var ALineas: TLineasMotorFiscalVenta;
  const ATipoIva: string;
  ABase, ABruto, APorcentajeIva, APorcentajeRecargo: Double);
var
  iIndice: Integer;
begin
  iIndice := Length(ALineas);
  SetLength(ALineas, iIndice + 1);
  ALineas[iIndice] := Default(TLineaMotorFiscalVenta);
  ALineas[iIndice].TipoIva := ATipoIva;
  ALineas[iIndice].Base := ABase;
  ALineas[iIndice].TotalConIva :=
    ABase + (ABase * APorcentajeIva / 100);
  ALineas[iIndice].PorcentajeIva := APorcentajeIva;
  ALineas[iIndice].PorcentajeRecargo := APorcentajeRecargo;
  ALineas[iIndice].Bruto := ABruto;
  ALineas[iIndice].Descuento := ABruto - ABase;
end;

function ResultadoTipoIvaCompra(
  const AResultado: TResultadoMotorFiscalVenta;
  AIndice: Integer): TResultadoTipoIvaVenta;
begin
  Result := AResultado.Normal;
  if AIndice = 1 then
    Result := AResultado.Reducido
  else if AIndice = 2 then
    Result := AResultado.SuperReducido
  else if AIndice = 3 then
    Result := AResultado.Exento;
end;

procedure EscribirResultadoMotorFiscalCompra(
  ACabecera: TDataSet; const ASufijoCabecera: string;
  const AResultado: TResultadoMotorFiscalVenta;
  ADescuentoComercial, ADescuentoFinanciero: Double);
var
  iIndice: Integer;
  oTipo: TResultadoTipoIvaVenta;
begin
  for iIndice := 0 to 3 do
  begin
    oTipo := ResultadoTipoIvaCompra(AResultado, iIndice);
    PonerFloat(ACabecera,
      'TOTAL_BASEI_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera,
      oTipo.Base);
    PonerFloat(ACabecera,
      'TOTAL_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera,
      oTipo.ImporteIva);
    PonerFloat(ACabecera,
      'TOTAL_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera,
      oTipo.ImporteRecargo);
  end;
  PonerFloat(ACabecera, 'TOTAL_BRUTO_' + ASufijoCabecera,
    AResultado.TotalBruto);
  PonerFloat(ACabecera, 'TOTAL_DTO_COMERCIAL_' + ASufijoCabecera,
    ADescuentoComercial);
  PonerFloat(ACabecera, 'TOTAL_DTO_FINANCIERO_' + ASufijoCabecera,
    ADescuentoFinanciero);
  PonerFloat(ACabecera, 'TOTAL_BASES_' + ASufijoCabecera,
    AResultado.TotalBases);
  PonerFloat(ACabecera, 'TOTAL_IMPUESTOS_' + ASufijoCabecera,
    AResultado.TotalImpuestos);
  PonerFloat(ACabecera, 'TOTAL_RETENCION_' + ASufijoCabecera,
    AResultado.TotalRetencion);
  PonerFloat(ACabecera, 'TOTAL_' + ASufijoCabecera,
    AResultado.TotalConImpuestos);
  PonerFloat(ACabecera, 'TOTAL_LIQUIDO_' + ASufijoCabecera,
    AResultado.TotalLiquido - ADescuentoFinanciero);
end;

procedure AnularPorcentajesRecargoCompra(ACabecera: TDataSet;
  const ASufijoCabecera: string);
var
  sTramo: string;
begin
  for sTramo in TArray<string>.Create('N', 'R', 'S', 'E') do
    PonerFloat(ACabecera, 'PORCENTAJE_RE' + sTramo + '_' + ASufijoCabecera,
      0);
end;

procedure CalcularTotalesDocumentoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);
var
  aLineasMotor: TLineasMotorFiscalVenta;
  oConfiguracion: TConfiguracionMotorFiscalVenta;
  oResultado: TResultadoMotorFiscalVenta;
  oMarcador: TBookmark;
  iIndice: Integer;
  rTotal, rTotalBruto, rPorIva, rPorRe, rPorRet, rBruto,
  rDtoComercial, rDtoFinanciero, rFactorComercial: Double;
  sArticulo, sSufijoLinea, sTipoArt, sTipoIva, sTipoLinea: string;
  bAplicaRe: Boolean;
  bExento: Boolean;
  bFiltroActivo: Boolean;
begin
  SincronizarRecargoComprasEmpresa(ALecturas, ACabecera, ASufijoCabecera);
  if Assigned(ACabecera) and Assigned(ALineas) and ALineas.Active then
  begin
    SetLength(aLineasMotor, 0);
    rBruto := 0;
    AplicarPorcentajesIvaCompra(
      ALecturas, ACabecera, ASufijoCabecera);
    sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
    bExento := DocumentoCompraSinIva(ACabecera,
      ASufijoCabecera);
    bAplicaRe :=
      (not bExento) and
      (UpperCase(CampoString(ACabecera,
        'ESIVA_RECARGO_COMPRAS_' + ASufijoCabecera)) = 'S');
    // FZ-ISSUE-374: como en ventas, el grupo de IVA decide si hay recargo
    // (IGIC o IPSI no lo tienen); sin él, sus porcentajes quedan a 0 para
    // que tampoco entren en el coste.
    if bAplicaRe and Assigned(ALecturas) and
       not ALecturas.LeerAplicaRecargoZona(
         CampoString(ACabecera, 'CODIGO_IVA_' + ASufijoCabecera)) then
    begin
      bAplicaRe := False;
      AnularPorcentajesRecargoCompra(ACabecera, ASufijoCabecera);
    end;
    // Una línea recién insertada aún no tiene marcador: el recorrido la
    // grababa igualmente (First) y el cursor se quedaba en la última línea
    // del documento en vez de volver a ella (FZ-ISSUE-416).
    if ALineas.State = dsInsert then
      ALineas.Post;
    oMarcador := ALineas.GetBookmark;
    bFiltroActivo := ALineas.Filtered;
    try
      ALineas.DisableControls;
      // El pivote de tallas filtra visualmente las lineas representantes.
      // Los totales fiscales deben sumar siempre todas las lineas reales.
      if bFiltroActivo then
        ALineas.Filtered := False;
      ALineas.First;
      while not ALineas.Eof do
      begin
        rBruto := rBruto + CampoFloat(ALineas, ACampoTotalLinea);
        ALineas.Next;
      end;
      rDtoComercial := ImporteDescuentoGlobalCompra(ACabecera,
        ASufijoCabecera, 'COMERCIAL', rBruto);
      rFactorComercial := FactorDescuentoComercialCompra(rBruto,
        rDtoComercial);
      rDtoFinanciero := ImporteDescuentoGlobalCompra(ACabecera,
        ASufijoCabecera, 'FINANCIERO', rBruto - rDtoComercial);
      ALineas.First;
      while not ALineas.Eof do
      begin
        sTipoLinea := CampoString(ALineas, ACampoTipoIvaLinea);
        if Trim(sTipoLinea) = '' then
          sTipoLinea := CampoString(ACabecera,
            'TIPO_IVA_' + ASufijoCabecera);
        sTipoIva := NormalizarTipoIva(sTipoLinea);
        if bExento then
          sTipoIva := 'E'
        else if sSufijoLinea <> '' then
        begin
          sArticulo := CampoString(ALineas, 'CODIGO_ART_' + sSufijoLinea);
          sTipoArt := ObtenerTipoIvaArticulo(ALecturas, sArticulo);
          if sTipoArt <> '' then
            sTipoIva := sTipoArt;
        end;
        rTotalBruto := CampoFloat(ALineas, ACampoTotalLinea);
        rTotal := rTotalBruto * rFactorComercial;
        rPorIva := CampoFloat(ALineas, ACampoPorcentajeIvaLinea);
        if bExento then
          rPorIva := 0
        else if rPorIva = 0 then
          rPorIva := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera,
            sTipoIva);
        iIndice := IndiceTipoIva(sTipoIva);
        rPorRe := CampoFloat(ACabecera,
          'PORCENTAJE_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera);
        AgregarLineaMotorFiscalCompra(aLineasMotor, sTipoIva,
          rTotal, rTotalBruto, rPorIva, rPorRe);
        ALineas.Next;
      end;
    finally
      if bFiltroActivo then
        ALineas.Filtered := True;
      if ALineas.BookmarkValid(oMarcador) then
        ALineas.GotoBookmark(oMarcador);
      ALineas.FreeBookmark(oMarcador);
      ALineas.EnableControls;
    end;
    rPorRet := CampoFloat(ACabecera,
      'PORCENTAJE_RETENCION_' + ASufijoCabecera);
    oConfiguracion := Default(TConfiguracionMotorFiscalVenta);
    // Como en las facturas de venta: bases, cuotas y retencion a
    // centimos; sin ello el pie no sumaba (545,92 + 114,64 <> 660,57).
    oConfiguracion.RedondearPorLinea := True;
    oConfiguracion.AplicaRecargo := bAplicaRe;
    oConfiguracion.AplicaRetencion := Abs(rPorRet) > 0.000001;
    oConfiguracion.ClienteConDatosFiscales := True;
    oConfiguracion.PorcentajeRetencion := rPorRet;
    oResultado := CalcularTotalesMotorFiscalVenta(
      aLineasMotor, oConfiguracion);
    EscribirResultadoMotorFiscalCompra(ACabecera, ASufijoCabecera,
      oResultado, rDtoComercial, rDtoFinanciero);
  end;
end;

// Unidad sin decimales (Uds) o desconocida: la linea cuenta como prendas.
function LineaCuentaComoPrendas(ALineas: TDataSet;
  const ASufijoLinea: string; AUnidades: TUnidadesMedida): Boolean;
var
  oCampoUnidad: TField;
begin
  Result := True;
  if Assigned(AUnidades) then
  begin
    oCampoUnidad := ALineas.FindField(
      'TIPO_CANTIDAD_ARTICULO_' + ASufijoLinea);
    if oCampoUnidad <> nil then
      Result := AUnidades.Decimales(Trim(oCampoUnidad.AsString)) = 0;
  end;
end;

function TotalPrendasLineasCompra(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string;
  const ACampoTotalUnidades: string;
  AUnidades: TUnidadesMedida): Double;
var
  bk: TBookmark;
  oCampoUds: TField;
  rCantidadLinea: Double;
  sSufijoLinea: string;
  bFiltroActivo: Boolean;
begin
  Result := 0;
  if Assigned(ALineas) and ALineas.Active then
  begin
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
      rCantidadLinea := CampoFloat(ALineas, 'CANTIDAD_' + sSufijoLinea);
      // Regla COALESCE de la vista: TOTAL_UNIDADES manda si no es NULL.
      if ACampoTotalUnidades <> '' then
      begin
        oCampoUds := ALineas.FindField(ACampoTotalUnidades);
        if (oCampoUds <> nil) and (not oCampoUds.IsNull) then
          rCantidadLinea := oCampoUds.AsFloat;
      end;
      if LineaCuentaComoPrendas(ALineas, sSufijoLinea, AUnidades) then
        Result := Result + rCantidadLinea;
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
