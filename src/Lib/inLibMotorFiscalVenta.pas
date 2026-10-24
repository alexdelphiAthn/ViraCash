{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMotorFiscalVenta                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Núcleo puro para calcular bases, impuestos y retenciones de venta.        }
{******************************************************************************}
unit inLibMotorFiscalVenta;

interface

uses
  System.SysUtils;

type
  TLineaMotorFiscalVenta = record
    TipoIva: string;
    Base: Double;
    TotalConIva: Double;
    PorcentajeIva: Double;
    PorcentajeRecargo: Double;
    Bruto: Double;
    Descuento: Double;
    Cantidad: Double;
    ImpuestosIncluidos: Boolean;
  end;

  TLineasMotorFiscalVenta = TArray<TLineaMotorFiscalVenta>;

  TConfiguracionMotorFiscalVenta = record
    // Importes a centimos (FZ-ISSUE-205, decision del usuario 05/10/2026):
    // cada linea aporta su base redondeada y la cuota de IVA y de recargo
    // se calcula UNA vez por tipo sobre la suma de esas bases. Con IVA
    // incluido manda el PVP (ver CalcularIvaIncluidoPorDiferencia).
    RedondearPorLinea: Boolean;
    CalcularIvaIncluidoPorDiferencia: Boolean;
    AplicaRecargo: Boolean;
    AplicaRetencion: Boolean;
    EsFacturaSimplificada: Boolean;
    ClienteConDatosFiscales: Boolean;
    RetencionIncluyeImpuestos: Boolean;
    PorcentajeRetencion: Double;
    PorcentajeDtoComercial: Double;
    PorcentajeDtoFinanciero: Double;
  end;

  TResultadoTipoIvaVenta = record
    Base: Double;
    PorcentajeIva: Double;
    ImporteIva: Double;
    PorcentajeRecargo: Double;
    ImporteRecargo: Double;
    // Líneas con impuestos incluidos: se desglosan al cerrar el tipo.
    TotalConIvaIncluido: Double;
    BaseLineasIvaIncluido: Double;
    // Base desglosada del total con IVA incluido del tipo.
    BaseIvaIncluido: Double;
    // Bases de las lineas sin impuestos incluidos (cuota por tipo).
    BaseLineasSinIncluir: Double;
  end;

  TResultadoMotorFiscalVenta = record
    Normal: TResultadoTipoIvaVenta;
    Reducido: TResultadoTipoIvaVenta;
    SuperReducido: TResultadoTipoIvaVenta;
    Exento: TResultadoTipoIvaVenta;
    TotalBases: Double;
    TotalIva: Double;
    TotalRecargo: Double;
    TotalImpuestos: Double;
    TotalRetencion: Double;
    TotalConImpuestos: Double;
    TotalLiquido: Double;
    TotalBruto: Double;
    TotalDescuentos: Double;
    TotalDtoComercial: Double;
    TotalDtoFinanciero: Double;
    TotalCantidades: Double;
    TieneImportesNegativos: Boolean;
    // Base final de cada linea (mismo orden que la entrada). Con
    // RedondearPorLinea, a centimos y, en las lineas con IVA incluido,
    // ajustada para que sumen la base desglosada de su tipo: el centimo
    // de diferencia va a la linea de mayor importe.
    BasesLinea: TArray<Double>;
  end;

function CalcularTotalesMotorFiscalVenta(
  const ALineas: TLineasMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta):
  TResultadoMotorFiscalVenta;

implementation

uses
  inLibRedondeo, inLibMsgVentas;

function NormalizarTipoIvaMotor(const ATipoIva: string): string;
begin
  if SameText(Trim(ATipoIva), 'R') then
    Result := 'R'
  else if SameText(Trim(ATipoIva), 'S') then
    Result := 'S'
  else if SameText(Trim(ATipoIva), 'E') then
    Result := 'E'
  else
    Result := 'N';
end;

function RedondearImporteMotor(
  AImporte: Double;
  ARedondear: Boolean): Double;
begin
  Result := AImporte;
  // FZ-ISSUE-207: SimpleRoundTo dejaba 545,925 en 545,92 (Double).
  if ARedondear then
    Result := RedondearACentimos(AImporte);
end;

procedure AcumularTipoIva(
  var AResultado: TResultadoTipoIvaVenta;
  const ALinea: TLineaMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  Base: Double;
  ImporteIva: Double;
  ImporteRecargo: Double;
  TotalConIva: Double;
  PuedeAplicarRecargo: Boolean;
begin
  Base := RedondearImporteMotor(
    ALinea.Base, AConfiguracion.RedondearPorLinea);
  TotalConIva := RedondearImporteMotor(
    ALinea.TotalConIva, AConfiguracion.RedondearPorLinea);
  if ALinea.ImpuestosIncluidos and
     AConfiguracion.CalcularIvaIncluidoPorDiferencia then
  begin
    // La cuota sale de desglosar el total del tipo (DesglosarIvaIncluido);
    // restar línea a línea bases ya redondeadas descuadra base x tipo.
    ImporteIva := 0;
    AResultado.TotalConIvaIncluido :=
      AResultado.TotalConIvaIncluido + TotalConIva;
    AResultado.BaseLineasIvaIncluido :=
      AResultado.BaseLineasIvaIncluido + Base;
  end
  else if AConfiguracion.RedondearPorLinea then
  begin
    // La cuota se calcula por tipo en CalcularResumen.
    ImporteIva := 0;
    AResultado.BaseLineasSinIncluir :=
      AResultado.BaseLineasSinIncluir + Base;
  end
  else
    ImporteIva := Base * ALinea.PorcentajeIva / 100;
  PuedeAplicarRecargo :=
    AConfiguracion.AplicaRecargo and
    not AConfiguracion.EsFacturaSimplificada and
    AConfiguracion.ClienteConDatosFiscales;
  ImporteRecargo := 0;
  // Con RedondearPorLinea el recargo tambien va por tipo (CalcularResumen).
  if PuedeAplicarRecargo and not AConfiguracion.RedondearPorLinea then
    ImporteRecargo :=
      Base * ALinea.PorcentajeRecargo / 100;
  AResultado.Base := AResultado.Base + Base;
  AResultado.PorcentajeIva := ALinea.PorcentajeIva;
  AResultado.ImporteIva := AResultado.ImporteIva + ImporteIva;
  AResultado.PorcentajeRecargo := ALinea.PorcentajeRecargo;
  AResultado.ImporteRecargo :=
    AResultado.ImporteRecargo + ImporteRecargo;
end;

procedure AcumularLinea(
  var AResultado: TResultadoMotorFiscalVenta;
  const ALinea: TLineaMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  TipoIva: string;
begin
  TipoIva := NormalizarTipoIvaMotor(ALinea.TipoIva);
  if TipoIva = 'R' then
    AcumularTipoIva(AResultado.Reducido, ALinea, AConfiguracion)
  else if TipoIva = 'S' then
    AcumularTipoIva(AResultado.SuperReducido, ALinea, AConfiguracion)
  else if TipoIva = 'E' then
    AcumularTipoIva(AResultado.Exento, ALinea, AConfiguracion)
  else
    AcumularTipoIva(AResultado.Normal, ALinea, AConfiguracion);
  AResultado.TotalBruto := AResultado.TotalBruto + ALinea.Bruto;
  AResultado.TotalDescuentos :=
    AResultado.TotalDescuentos + ALinea.Descuento;
  AResultado.TotalCantidades :=
    AResultado.TotalCantidades + ALinea.Cantidad;
  if (ALinea.Base < 0) or (ALinea.Cantidad < 0) then
    AResultado.TieneImportesNegativos := True;
end;

procedure DesglosarIvaIncluido(
  var AResultado: TResultadoTipoIvaVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  Base: Double;
begin
  if (AResultado.TotalConIvaIncluido <> 0) or
     (AResultado.BaseLineasIvaIncluido <> 0) then
  begin
    // 4.600,00 al 21 %: base 3.801,65 y cuota 798,35 (no 3.801,66 +
    // 798,34 sumando las bases redondeadas de cada línea).
    Base := RedondearImporteMotor(
      AResultado.TotalConIvaIncluido /
        (1 + AResultado.PorcentajeIva / 100),
      AConfiguracion.RedondearPorLinea);
    AResultado.BaseIvaIncluido := Base;
    AResultado.Base :=
      AResultado.Base - AResultado.BaseLineasIvaIncluido + Base;
    AResultado.ImporteIva :=
      AResultado.ImporteIva +
      RedondearImporteMotor(
        AResultado.TotalConIvaIncluido - Base,
        AConfiguracion.RedondearPorLinea);
  end;
end;

// FZ-ISSUE-205: cuota de IVA de las lineas sin impuestos incluidos y
// recargo de todo el tipo, una sola vez sobre la base del tipo.
procedure CerrarCuotasTipo(
  var AResultado: TResultadoTipoIvaVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  PuedeAplicarRecargo: Boolean;
begin
  AResultado.ImporteIva := AResultado.ImporteIva +
    RedondearImporteMotor(
      AResultado.BaseLineasSinIncluir * AResultado.PorcentajeIva / 100,
      True);
  PuedeAplicarRecargo :=
    AConfiguracion.AplicaRecargo and
    not AConfiguracion.EsFacturaSimplificada and
    AConfiguracion.ClienteConDatosFiscales;
  if PuedeAplicarRecargo then
    AResultado.ImporteRecargo := RedondearImporteMotor(
      AResultado.Base * AResultado.PorcentajeRecargo / 100, True);
end;

procedure CalcularResumen(
  var AResultado: TResultadoMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  BaseRetencion: Double;
  PuedeAplicarRetencion: Boolean;
begin
  DesglosarIvaIncluido(AResultado.Normal, AConfiguracion);
  DesglosarIvaIncluido(AResultado.Reducido, AConfiguracion);
  DesglosarIvaIncluido(AResultado.SuperReducido, AConfiguracion);
  DesglosarIvaIncluido(AResultado.Exento, AConfiguracion);
  if AConfiguracion.RedondearPorLinea then
  begin
    CerrarCuotasTipo(AResultado.Normal, AConfiguracion);
    CerrarCuotasTipo(AResultado.Reducido, AConfiguracion);
    CerrarCuotasTipo(AResultado.SuperReducido, AConfiguracion);
    CerrarCuotasTipo(AResultado.Exento, AConfiguracion);
  end;
  AResultado.TotalBases :=
    AResultado.Normal.Base +
    AResultado.Reducido.Base +
    AResultado.SuperReducido.Base +
    AResultado.Exento.Base;
  AResultado.TotalIva :=
    AResultado.Normal.ImporteIva +
    AResultado.Reducido.ImporteIva +
    AResultado.SuperReducido.ImporteIva +
    AResultado.Exento.ImporteIva;
  AResultado.TotalRecargo :=
    AResultado.Normal.ImporteRecargo +
    AResultado.Reducido.ImporteRecargo +
    AResultado.SuperReducido.ImporteRecargo +
    AResultado.Exento.ImporteRecargo;
  AResultado.TotalImpuestos :=
    AResultado.TotalIva + AResultado.TotalRecargo;
  PuedeAplicarRetencion :=
    AConfiguracion.AplicaRetencion and
    not AConfiguracion.EsFacturaSimplificada and
    AConfiguracion.ClienteConDatosFiscales;
  if PuedeAplicarRetencion then
  begin
    BaseRetencion := AResultado.TotalBases;
    if AConfiguracion.RetencionIncluyeImpuestos then
      BaseRetencion :=
        BaseRetencion + AResultado.TotalImpuestos;
    // Una sola vez sobre el total, como las cuotas: 215,34 al 15 % son
    // 32,30 y no 32,301 (el líquido arrastraría la milésima).
    AResultado.TotalRetencion := RedondearImporteMotor(
      BaseRetencion * AConfiguracion.PorcentajeRetencion / 100,
      AConfiguracion.RedondearPorLinea);
  end;
  AResultado.TotalConImpuestos :=
    AResultado.TotalBases + AResultado.TotalImpuestos;
  AResultado.TotalLiquido :=
    AResultado.TotalConImpuestos - AResultado.TotalRetencion;
end;

function ResultadoTipoMotor(
  const AResultado: TResultadoMotorFiscalVenta;
  const ATipoIva: string): TResultadoTipoIvaVenta;
var
  TipoIva: string;
begin
  TipoIva := NormalizarTipoIvaMotor(ATipoIva);
  if TipoIva = 'R' then
    Result := AResultado.Reducido
  else if TipoIva = 'S' then
    Result := AResultado.SuperReducido
  else if TipoIva = 'E' then
    Result := AResultado.Exento
  else
    Result := AResultado.Normal;
end;

// Las lineas con IVA incluido de un tipo suman exactamente la base
// desglosada del tipo: la diferencia de redondeo va a la de mayor importe.
procedure AjustarBasesIvaIncluido(
  var AResultado: TResultadoMotorFiscalVenta;
  const ALineas: TLineasMotorFiscalVenta;
  const ATipoIva: string);
var
  Indice, IndiceMayor: Integer;
  Suma, Diferencia: Double;
  Tipo: TResultadoTipoIvaVenta;
begin
  Suma := 0;
  IndiceMayor := -1;
  for Indice := Low(ALineas) to High(ALineas) do
  begin
    if ALineas[Indice].ImpuestosIncluidos and
       (NormalizarTipoIvaMotor(ALineas[Indice].TipoIva) = ATipoIva) then
    begin
      Suma := Suma + AResultado.BasesLinea[Indice];
      if (IndiceMayor < 0) or
         (Abs(AResultado.BasesLinea[Indice]) >
          Abs(AResultado.BasesLinea[IndiceMayor])) then
        IndiceMayor := Indice;
    end;
  end;
  Tipo := ResultadoTipoMotor(AResultado, ATipoIva);
  Diferencia := RedondearImporteMotor(Tipo.BaseIvaIncluido - Suma, True);
  if (IndiceMayor >= 0) and (Abs(Diferencia) >= 0.005) then
    AResultado.BasesLinea[IndiceMayor] := RedondearImporteMotor(
      AResultado.BasesLinea[IndiceMayor] + Diferencia, True);
end;

procedure CalcularBasesLinea(
  var AResultado: TResultadoMotorFiscalVenta;
  const ALineas: TLineasMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  Indice: Integer;
begin
  SetLength(AResultado.BasesLinea, Length(ALineas));
  for Indice := Low(ALineas) to High(ALineas) do
    AResultado.BasesLinea[Indice] := RedondearImporteMotor(
      ALineas[Indice].Base, AConfiguracion.RedondearPorLinea);
  if AConfiguracion.RedondearPorLinea and
     AConfiguracion.CalcularIvaIncluidoPorDiferencia then
  begin
    AjustarBasesIvaIncluido(AResultado, ALineas, 'N');
    AjustarBasesIvaIncluido(AResultado, ALineas, 'R');
    AjustarBasesIvaIncluido(AResultado, ALineas, 'S');
    AjustarBasesIvaIncluido(AResultado, ALineas, 'E');
  end;
end;

procedure ReducirLineasDocumento(var ALineas: TLineasMotorFiscalVenta;
  APorcentaje: Double);
var
  Indice: Integer;
  Factor: Double;
begin
  if (APorcentaje < 0) or (APorcentaje > 100) then
    raise EArgumentException.Create(SErrorPorcentajeDescuentoVenta);
  Factor := 1 - APorcentaje / 100;
  for Indice := Low(ALineas) to High(ALineas) do
  begin
    ALineas[Indice].Base := ALineas[Indice].Base * Factor;
    ALineas[Indice].TotalConIva := ALineas[Indice].TotalConIva * Factor;
  end;
end;

procedure AplicarDescuentosDocumento(
  var AResultado: TResultadoMotorFiscalVenta;
  const ALineas: TLineasMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta);
var
  Lineas: TLineasMotorFiscalVenta;
  Configuracion: TConfiguracionMotorFiscalVenta;
  Original, Comercial: TResultadoMotorFiscalVenta;
begin
  Original := AResultado;
  Lineas := Copy(ALineas);
  Configuracion := AConfiguracion;
  Configuracion.PorcentajeDtoComercial := 0;
  Configuracion.PorcentajeDtoFinanciero := 0;
  ReducirLineasDocumento(Lineas, AConfiguracion.PorcentajeDtoComercial);
  Comercial := CalcularTotalesMotorFiscalVenta(Lineas, Configuracion);
  ReducirLineasDocumento(Lineas, AConfiguracion.PorcentajeDtoFinanciero);
  AResultado := CalcularTotalesMotorFiscalVenta(Lineas, Configuracion);
  AResultado.TotalDtoComercial := RedondearACentimos(
    Original.TotalBases - Comercial.TotalBases);
  AResultado.TotalDtoFinanciero := RedondearACentimos(
    Comercial.TotalBases - AResultado.TotalBases);
  // Los descuentos de cabecera no se vuelven a aplicar a las lineas.
  AResultado.BasesLinea := Original.BasesLinea;
  AResultado.TotalBruto := Original.TotalBruto;
  AResultado.TotalDescuentos := Original.TotalDescuentos;
end;

function CalcularTotalesMotorFiscalVenta(
  const ALineas: TLineasMotorFiscalVenta;
  const AConfiguracion: TConfiguracionMotorFiscalVenta):
  TResultadoMotorFiscalVenta;
var
  Indice: Integer;
begin
  Result := Default(TResultadoMotorFiscalVenta);
  for Indice := Low(ALineas) to High(ALineas) do
    AcumularLinea(Result, ALineas[Indice], AConfiguracion);
  CalcularResumen(Result, AConfiguracion);
  CalcularBasesLinea(Result, ALineas, AConfiguracion);
  if (AConfiguracion.PorcentajeDtoComercial <> 0) or
     (AConfiguracion.PorcentajeDtoFinanciero <> 0) then
    AplicarDescuentosDocumento(Result, ALineas, AConfiguracion);
end;

end.
