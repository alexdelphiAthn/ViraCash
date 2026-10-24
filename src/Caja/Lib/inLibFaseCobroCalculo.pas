{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFaseCobroCalculo                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Calcula totales y distribuye cobros parciales sin depender de datasets.   }
{******************************************************************************}
unit inLibFaseCobroCalculo;

interface

type
  TEntradaTotalesCobro = record
    ImporteBruto: Currency;
    DescuentoLineal: Currency;
    UsarTotalFactura: Boolean;
    TotalFactura: Currency;
    PorcentajeDescuento: Currency;
    DescuentoPorImporte: Boolean;
    ImporteDescuentoFijado: Currency;
    ImporteDejarCuenta: Currency;
    ImporteValeEmitido: Currency;
    TotalEntregado: Currency;
    TotalValesRecogidos: Currency;
    TotalEntregadoConCambio: Currency;
    // Devolución: parte que debe devolverse en vale porque el ticket de
    // origen se pagó con vales (FZ-363)
    ImporteValeObligatorio: Currency;
    // FZ-ISSUE-379: rectificativa sustitutiva: líquido de la factura que
    // sustituye, ya cobrado; solo se cobra o devuelve la diferencia.
    ImporteYaCobrado: Currency;
  end;
  TResultadoTotalesCobro = record
    ImporteDescuentoGlobal: Currency;
    ImporteTotalPagar: Currency;
    ImporteEntregado: Currency;
    ImportePendiente: Currency;
    ImporteCambio: Currency;
    ImporteValeRecogido: Currency;
    ImporteValeEmitido: Currency;
    // Devolución: lo que las formas de pago devuelven por encima del
    // importe a devolver (FZ-359)
    ImporteDevueltoDeMas: Currency;
  end;
  TLineaCobroParcial = record
    IdDeposito: string;
    VieneDeDeposito: string;
    AccionDeposito: string;
    Descripcion: string;
    Total: Currency;
    // Unidades de la línea; el depósito las conserva aunque la línea de
    // abono pase a 1 unidad con el importe entregado.
    Cantidad: Double;
    AnticipoPrevio: Currency;
    PorcentajeIva: Currency;
    // Precio unitario de la prenda (PRECIO_VENTA_DEP del depósito)
    PrecioOriginal: Currency;
    PrecioSalida: Currency;
    PrecioConIva: Currency;
    PrecioSinIva: Currency;
    TotalSinIva: Currency;
    Modificada: Boolean;
    Eliminar: Boolean;
  end;
  TCalculadorFaseCobro = class
  private
    class function CalcularDescuento(
      ABase, APorcentaje: Currency): Currency; static;
    class procedure CalcularDevolucion(
      const AEntrada: TEntradaTotalesCobro;
      var AResultado: TResultadoTotalesCobro); static;
    class procedure CalcularVenta(
      const AEntrada: TEntradaTotalesCobro;
      var AResultado: TResultadoTotalesCobro); static;
  public
    class function CalcularDescuentoParaTotal(
      ABase, ATotal: Currency;
      out APorcentaje, ADescuento: Currency): Boolean; static;
    class function CalcularTotales(
      const AEntrada: TEntradaTotalesCobro): TResultadoTotalesCobro; static;
  end;
  TCalculadorCobroParcial = class
  private
    class function EsDepositoPendiente(
      const ALinea: TLineaCobroParcial): Boolean; static;
    class function EsPrendaNueva(
      const ALinea: TLineaCobroParcial): Boolean; static;
    class function PrecioUnitario(
      const ALinea: TLineaCobroParcial): Currency; static;
    class procedure MarcarAbonoParaEliminar(
      var ALineas: TArray<TLineaCobroParcial>;
      const AIdDeposito: string); static;
    class procedure ConvertirEnDeposito(
      var ALineas: TArray<TLineaCobroParcial>;
      AIndice: Integer;
      var ADineroDisponible: Currency); static;
    class procedure ProcesarDepositosPendientes(
      var ALineas: TArray<TLineaCobroParcial>;
      var ADineroDisponible: Currency); static;
    class procedure ProcesarPrendasNuevas(
      var ALineas: TArray<TLineaCobroParcial>;
      var ADineroDisponible: Currency); static;
    class function CalcularDineroDisponible(
      const ALineas: TArray<TLineaCobroParcial>;
      ADineroEntregado: Currency): Currency; static;
  public
    class procedure Transformar(
      var ALineas: TArray<TLineaCobroParcial>;
      ADineroEntregado: Currency); static;
  end;

const
  // Decimales del importe que entrega el cliente en otra moneda.
  DECIMALES_IMPORTE_DIVISA = 2;
  DECIMALES_IMPORTE_CRIPTO = 8;

/// Importe en divisa redondeado a sus decimales (2, o 8 en cripto).
function RedondearImporteDivisa(AImporte: Double;
  AEsCripto: Boolean): Double;

/// Euros que cubre un importe en divisa. Si es justo el que resulta del
/// pendiente con ese factor, devuelve el pendiente: redondear la divisa y
/// volver a dividir podría dar un céntimo de más o de menos (FZ-569).
function ImporteEurosDeImporteDivisa(AImporteDivisa, AFactor: Double;
  APendienteEuros: Currency; AEsCripto: Boolean): Currency;

implementation

uses
  inLibRedondeo,
  System.Math, System.SysUtils;

function RedondearImporteDivisa(AImporte: Double;
  AEsCripto: Boolean): Double;
begin
  if AEsCripto then
    Result := RedondearDecimales(AImporte, DECIMALES_IMPORTE_CRIPTO)
  else
    Result := RedondearDecimales(AImporte, DECIMALES_IMPORTE_DIVISA);
end;

function ImporteEurosDeImporteDivisa(AImporteDivisa, AFactor: Double;
  APendienteEuros: Currency; AEsCripto: Boolean): Currency;
var
  dEsperado: Double;
begin
  if AFactor <= 0 then
    Result := 0
  else
  begin
    dEsperado := RedondearImporteDivisa(APendienteEuros * AFactor,
      AEsCripto);
    if SameValue(AImporteDivisa, dEsperado) then
      Result := APendienteEuros
    else
      Result := RedondearDecimales(AImporteDivisa / AFactor, 2);
  end;
end;

class function TCalculadorFaseCobro.CalcularDescuento(
  ABase, APorcentaje: Currency): Currency;
begin
  if Abs(APorcentaje) > 0.001 then
    Result := RedondearDecimales(ABase * (APorcentaje / 100), 2)
  else
    Result := 0;
end;

class function TCalculadorFaseCobro.CalcularDescuentoParaTotal(
  ABase, ATotal: Currency;
  out APorcentaje, ADescuento: Currency): Boolean;
begin
  ABase := RedondearDecimales(ABase, 2);
  APorcentaje := 0;
  ADescuento := 0;
  Result := (ABase > 0) and (ATotal >= 0) and (ATotal <= ABase);
  if Result then
  begin
    ADescuento := ABase - RedondearDecimales(ATotal, 2);
    APorcentaje := (ADescuento / ABase) * 100;
  end;
end;

class procedure TCalculadorFaseCobro.CalcularDevolucion(
  const AEntrada: TEntradaTotalesCobro;
  var AResultado: TResultadoTotalesCobro);
var
  dDevueltoPorFormas: Currency;
  dImporteADevolver: Currency;
  dMaximoFormas: Currency;
  dRestante: Currency;
  dVale: Currency;
  dValeMinimo: Currency;
begin
  AResultado.ImporteEntregado := 0;
  AResultado.ImporteCambio := 0;
  dImporteADevolver := Abs(AResultado.ImporteTotalPagar);
  dValeMinimo := 0;
  if AEntrada.ImporteValeObligatorio > 0 then
    dValeMinimo := AEntrada.ImporteValeObligatorio;
  if dValeMinimo > dImporteADevolver then
    dValeMinimo := dImporteADevolver;
  dMaximoFormas := dImporteADevolver - dValeMinimo;
  dDevueltoPorFormas := 0;
  if AEntrada.TotalEntregado < -0.001 then
    dDevueltoPorFormas := Abs(AEntrada.TotalEntregado);
  if dDevueltoPorFormas > dMaximoFormas then
  begin
    AResultado.ImporteDevueltoDeMas := dDevueltoPorFormas - dMaximoFormas;
    dDevueltoPorFormas := dMaximoFormas;
  end;
  dRestante := dImporteADevolver - dDevueltoPorFormas;
  // El vale cubre al menos la parte obligatoria y nunca supera lo que
  // queda por devolver (FZ-359)
  dVale := AEntrada.ImporteValeEmitido;
  if dVale < dValeMinimo then
    dVale := dValeMinimo;
  if dVale > dRestante then
    dVale := dRestante;
  AResultado.ImporteValeEmitido := dVale;
  AResultado.ImportePendiente := dRestante - dVale;
end;

class procedure TCalculadorFaseCobro.CalcularVenta(
  const AEntrada: TEntradaTotalesCobro;
  var AResultado: TResultadoTotalesCobro);
var
  dCambioCalculado: Currency;
begin
  AResultado.ImporteEntregado :=
    AEntrada.TotalEntregado + AEntrada.TotalValesRecogidos;
  if AResultado.ImporteEntregado >=
     AResultado.ImporteTotalPagar - 0.001 then
  begin
    AResultado.ImportePendiente := 0;
    dCambioCalculado := AResultado.ImporteEntregado -
      AResultado.ImporteTotalPagar;
    if Abs(dCambioCalculado) < 0.01 then
      dCambioCalculado := 0;
    if dCambioCalculado > AEntrada.TotalEntregadoConCambio then
    begin
      AResultado.ImporteCambio := AEntrada.TotalEntregadoConCambio;
      AResultado.ImporteValeEmitido :=
        dCambioCalculado - AEntrada.TotalEntregadoConCambio;
    end
    else
    begin
      AResultado.ImporteCambio := dCambioCalculado;
      AResultado.ImporteValeEmitido := 0;
    end;
  end
  else
  begin
    AResultado.ImportePendiente := AResultado.ImporteTotalPagar -
      AResultado.ImporteEntregado - AEntrada.ImporteDejarCuenta;
    if Abs(AResultado.ImportePendiente) < 0.01 then
      AResultado.ImportePendiente := 0;
    AResultado.ImporteCambio := 0;
    AResultado.ImporteValeEmitido := 0;
  end;
end;

class function TCalculadorFaseCobro.CalcularTotales(
  const AEntrada: TEntradaTotalesCobro): TResultadoTotalesCobro;
var
  dBase: Currency;
begin
  Result := Default(TResultadoTotalesCobro);
  dBase := RedondearDecimales(
    AEntrada.ImporteBruto - AEntrada.DescuentoLineal, 2);
  if AEntrada.UsarTotalFactura then
    dBase := RedondearDecimales(AEntrada.TotalFactura, 2);
  if AEntrada.DescuentoPorImporte then
    Result.ImporteDescuentoGlobal := AEntrada.ImporteDescuentoFijado
  else
    Result.ImporteDescuentoGlobal := CalcularDescuento(
      dBase, AEntrada.PorcentajeDescuento);
  Result.ImporteTotalPagar := dBase - Result.ImporteDescuentoGlobal -
    AEntrada.ImporteYaCobrado;
  Result.ImporteValeRecogido := AEntrada.TotalValesRecogidos;
  Result.ImporteValeEmitido := AEntrada.ImporteValeEmitido;
  if Result.ImporteTotalPagar < -0.001 then
    CalcularDevolucion(AEntrada, Result)
  else
    CalcularVenta(AEntrada, Result);
end;

class function TCalculadorCobroParcial.EsDepositoPendiente(
  const ALinea: TLineaCobroParcial): Boolean;
begin
  Result := (ALinea.VieneDeDeposito = 'S') and
    (ALinea.AccionDeposito = 'COBRAR') and
    (ALinea.Total > 0);
end;

class function TCalculadorCobroParcial.EsPrendaNueva(
  const ALinea: TLineaCobroParcial): Boolean;
begin
  Result := (ALinea.VieneDeDeposito <> 'S') and
    (ALinea.VieneDeDeposito <> 'A') and
    ((ALinea.AccionDeposito = 'COBRAR') or
     (ALinea.AccionDeposito = '')) and
    (ALinea.Total > 0);
end;

class function TCalculadorCobroParcial.PrecioUnitario(
  const ALinea: TLineaCobroParcial): Currency;
begin
  // Sin unidades informadas la línea vale por una prenda
  if ALinea.Cantidad > 0 then
    Result := ALinea.Total / ALinea.Cantidad
  else
    Result := ALinea.Total;
end;

class procedure TCalculadorCobroParcial.MarcarAbonoParaEliminar(
  var ALineas: TArray<TLineaCobroParcial>;
  const AIdDeposito: string);
var
  bEncontrado: Boolean;
  i: Integer;
begin
  bEncontrado := False;
  i := 0;
  while (i <= High(ALineas)) and not bEncontrado do
  begin
    if (Trim(AIdDeposito) <> '') and
       (ALineas[i].VieneDeDeposito = 'A') and
       (ALineas[i].IdDeposito = AIdDeposito) then
    begin
      ALineas[i].Eliminar := True;
      bEncontrado := True;
    end;
    Inc(i);
  end;
end;

class procedure TCalculadorCobroParcial.ConvertirEnDeposito(
  var ALineas: TArray<TLineaCobroParcial>;
  AIndice: Integer;
  var ADineroDisponible: Currency);
var
  dDineroReal: Currency;
  dTotal: Currency;
begin
  dTotal := ALineas[AIndice].Total;
  dDineroReal := ADineroDisponible + ALineas[AIndice].AnticipoPrevio;
  if dDineroReal >= dTotal then
    ADineroDisponible := ADineroDisponible -
      (dTotal - ALineas[AIndice].AnticipoPrevio)
  else
  begin
    if ALineas[AIndice].VieneDeDeposito = 'S' then
      ALineas[AIndice].AccionDeposito := 'AUMENTAR_DEP'
    else
      ALineas[AIndice].AccionDeposito := 'NUEVO_DEP';
    if Pos('Abono ', ALineas[AIndice].Descripcion) <> 1 then
      ALineas[AIndice].Descripcion :=
        'Abono a cuenta ' + ALineas[AIndice].Descripcion;
    ALineas[AIndice].PrecioOriginal := PrecioUnitario(ALineas[AIndice]);
    ALineas[AIndice].PrecioSalida := ADineroDisponible;
    ALineas[AIndice].PrecioConIva := ADineroDisponible;
    if ALineas[AIndice].PorcentajeIva = 0 then
      ALineas[AIndice].PrecioSinIva := ADineroDisponible
    else
      ALineas[AIndice].PrecioSinIva := ADineroDisponible /
        (1 + (ALineas[AIndice].PorcentajeIva / 100));
    ALineas[AIndice].TotalSinIva := ALineas[AIndice].PrecioSinIva;
    ALineas[AIndice].Total := ADineroDisponible;
    ALineas[AIndice].Modificada := True;
    MarcarAbonoParaEliminar(ALineas, ALineas[AIndice].IdDeposito);
    ADineroDisponible := 0;
  end;
end;

class procedure TCalculadorCobroParcial.ProcesarDepositosPendientes(
  var ALineas: TArray<TLineaCobroParcial>;
  var ADineroDisponible: Currency);
var
  i: Integer;
begin
  for i := 0 to High(ALineas) do
  begin
    if EsDepositoPendiente(ALineas[i]) then
      ConvertirEnDeposito(ALineas, i, ADineroDisponible);
  end;
end;

class procedure TCalculadorCobroParcial.ProcesarPrendasNuevas(
  var ALineas: TArray<TLineaCobroParcial>;
  var ADineroDisponible: Currency);
var
  i: Integer;
begin
  for i := 0 to High(ALineas) do
  begin
    if EsPrendaNueva(ALineas[i]) then
    begin
      if ADineroDisponible > 0 then
        ConvertirEnDeposito(ALineas, i, ADineroDisponible)
      else
      begin
        ALineas[i].AccionDeposito := 'NUEVO_DEP';
        ALineas[i].PrecioOriginal := PrecioUnitario(ALineas[i]);
        ALineas[i].PrecioSalida := 0;
        ALineas[i].PrecioConIva := 0;
        ALineas[i].PrecioSinIva := 0;
        ALineas[i].TotalSinIva := 0;
        ALineas[i].Total := 0;
        ALineas[i].Modificada := True;
      end;
    end;
  end;
end;

class function TCalculadorCobroParcial.CalcularDineroDisponible(
  const ALineas: TArray<TLineaCobroParcial>;
  ADineroEntregado: Currency): Currency;
var
  i: Integer;
begin
  Result := ADineroEntregado;
  for i := 0 to High(ALineas) do
  begin
    if (ALineas[i].Total < 0) and
       (ALineas[i].VieneDeDeposito <> 'A') then
      Result := Result - ALineas[i].Total;
    if (ALineas[i].VieneDeDeposito = 'S') and
       (ALineas[i].AccionDeposito = 'CANCELAR') and
       (ALineas[i].AnticipoPrevio > 0) then
      Result := Result + ALineas[i].AnticipoPrevio;
  end;
end;

class procedure TCalculadorCobroParcial.Transformar(
  var ALineas: TArray<TLineaCobroParcial>;
  ADineroEntregado: Currency);
var
  dDineroDisponible: Currency;
begin
  dDineroDisponible := CalcularDineroDisponible(
    ALineas,
    ADineroEntregado);
  ProcesarDepositosPendientes(ALineas, dDineroDisponible);
  ProcesarPrendasNuevas(ALineas, dDineroDisponible);
end;

end.
