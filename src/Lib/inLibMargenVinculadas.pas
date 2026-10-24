{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMargenVinculadas                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       27/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Margen mínimo exigible al facturar a una empresa vinculada. No hay un     }
{    porcentaje legal: el art. 18 LIS pide valor de mercado y el análisis de   }
{    comparabilidad tiene en cuenta el estado del género, así que el mínimo    }
{    baja por tramos de antigüedad (la moda de temporadas pasadas vale menos   }
{    también entre mayoristas).                                                }
{    Sin VCL, datasets ni persistencia.                                        }
{******************************************************************************}
unit inLibMargenVinculadas;

interface

uses
  inLibInventariosRevalorizacion;

type
  // Desde DesdeMeses de antigüedad se exige Porcentaje de margen sobre el
  // coste. Los tramos se guardan ordenados de menor a mayor antigüedad.
  TTramoMargenMinimo = record
    DesdeMeses: Integer;
    Porcentaje: Currency;
  end;

  TEscalaMargenMinimo = array of TTramoMargenMinimo;

// Lee la escala del parámetro: '25' es un único tramo del 25 % y
// '0:25;6:15;12:5;24:0' son cuatro tramos por meses de antigüedad. Lo que
// no se entienda se descarta; una escala vacía significa no exigir nada.
function AnalizarEscalaMargenMinimo(
  const ATexto: string): TEscalaMargenMinimo;
function TextoEscalaMargenMinimo(
  const AEscala: TEscalaMargenMinimo): string;
// Margen que corresponde a una antigüedad: el del tramo más alto que no la
// supera. Con AMargenForzado > 0 manda ese y la escala se ignora.
function MargenMinimoLinea(
  const AEscala: TEscalaMargenMinimo;
  AAntiguedadMeses: Integer;
  AMargenForzado: Currency): Currency;
// Antigüedad que se tiene en cuenta: cero si el coste ya viene devaluado
// de un inventario, porque entonces la rebaja ya está en el PMP y aplicar
// además el tramo la restaría dos veces.
function AntiguedadAplicable(
  AAntiguedadMeses: Integer;
  ACosteYaDevaluado: Boolean): Integer;
// Precio por debajo del cual una línea no llega a su margen mínimo sobre el
// PMP (el coste). Con PMP 0 no hay margen medible y devuelve 0.
function PrecioMinimoConMargen(
  APrecioMedioActual: Currency;
  AMargenMinimo: Currency): Currency;
// Líneas presentadas que se facturarían por debajo de su margen mínimo: las
// simuladas con su precio nuevo y las que no se marcaron, que se quedan en
// su precio base y por tanto sin margen. Se emparejan por Clave y, si está
// vacía, por línea y SKU.
function ContarLineasBajoMargenMinimo(
  const ALineas: TLineasBaseRevalorizacionInventario;
  const ASimulacion: TSimulacionRevalorizacionInventario;
  const AEscala: TEscalaMargenMinimo;
  AMargenForzado: Currency;
  ACosteYaDevaluado: Boolean = False): Integer;
// Techo: el traspaso no puede facturarse por encima del precio sin IVA al
// que la tienda lo vendió. Ningún distribuidor independiente compra por
// más de lo que va a cobrar, y si la prenda salió rebajada por debajo del
// coste, ese es su valor de mercado (con el deterioro documentado).
function PrecioConTopeVenta(
  APrecio: Currency;
  APrecioVentaDestino: Currency): Currency;
// Devuelve la simulación con los precios que superan la venta ajustados a
// ella y el resumen rehecho.
function AplicarTopeVentaSimulacion(
  const ASimulacion: TSimulacionRevalorizacionInventario
): TSimulacionRevalorizacionInventario;
function ContarLineasLimitadasPorVenta(
  const ASimulacion: TSimulacionRevalorizacionInventario): Integer;
// Redondea a céntimos el importe de cada línea y rehace el resumen, como
// hace la factura con la base de cada línea: tres ventas a 27,2125 +
// 27,2125 + 25,41 facturan 79,83, no los 79,84 de redondear la suma
// (FZ-ISSUE-025). Los precios unitarios conservan sus cuatro decimales.
function RedondearImportesSimulacionACentimos(
  const ASimulacion: TSimulacionRevalorizacionInventario
): TSimulacionRevalorizacionInventario;

implementation

uses
  System.Math,
  System.SysUtils,
  System.Generics.Collections,
  inLibRedondeo;

function LeerNumero(
  const ATexto: string;
  out AValor: Currency): Boolean;
var
  oFormato: TFormatSettings;
  sValor  : string;
  dValor  : Double;
begin
  oFormato := TFormatSettings.Invariant;
  sValor := StringReplace(Trim(ATexto), ',', '.', [rfReplaceAll]);
  Result := (sValor <> '') and TryStrToFloat(sValor, dValor, oFormato);
  if Result then
    AValor := dValor
  else
    AValor := 0;
end;

procedure AnadirTramo(
  var AEscala: TEscalaMargenMinimo;
  ADesdeMeses: Integer;
  APorcentaje: Currency);
var
  iTramo  : Integer;
  iDestino: Integer;
begin
  iDestino := Length(AEscala);
  for iTramo := 0 to High(AEscala) do
  begin
    if (AEscala[iTramo].DesdeMeses >= ADesdeMeses) and
       (iDestino = Length(AEscala)) then
      iDestino := iTramo;
  end;
  if (iDestino < Length(AEscala)) and
     (AEscala[iDestino].DesdeMeses = ADesdeMeses) then
    AEscala[iDestino].Porcentaje := APorcentaje
  else
  begin
    SetLength(AEscala, Length(AEscala) + 1);
    for iTramo := High(AEscala) downto iDestino + 1 do
    begin
      AEscala[iTramo] := AEscala[iTramo - 1];
    end;
    AEscala[iDestino].DesdeMeses := ADesdeMeses;
    AEscala[iDestino].Porcentaje := APorcentaje;
  end;
end;

function AnalizarEscalaMargenMinimo(
  const ATexto: string): TEscalaMargenMinimo;
var
  aPartes   : TArray<string>;
  iParte    : Integer;
  iSeparador: Integer;
  cMeses    : Currency;
  cMargen   : Currency;
  sParte    : string;
begin
  SetLength(Result, 0);
  aPartes := Trim(ATexto).Split([';', '|'], TStringSplitOptions.None);
  for iParte := 0 to High(aPartes) do
  begin
    sParte := Trim(aPartes[iParte]);
    if sParte <> '' then
    begin
      iSeparador := Pos(':', sParte);
      if iSeparador = 0 then
      begin
        if LeerNumero(sParte, cMargen) and (cMargen >= 0) then
          AnadirTramo(Result, 0, cMargen);
      end
      else if LeerNumero(Copy(sParte, 1, iSeparador - 1), cMeses) and
              LeerNumero(Copy(sParte, iSeparador + 1, MaxInt), cMargen) and
              (cMeses >= 0) and (cMargen >= 0) then
        AnadirTramo(Result, Trunc(cMeses), cMargen);
    end;
  end;
end;

function TextoEscalaMargenMinimo(
  const AEscala: TEscalaMargenMinimo): string;
var
  iTramo: Integer;
begin
  Result := '';
  for iTramo := 0 to High(AEscala) do
  begin
    if Result <> '' then
      Result := Result + '; ';
    Result := Result +
      IntToStr(AEscala[iTramo].DesdeMeses) + ':' +
      FormatFloat('0.##', AEscala[iTramo].Porcentaje);
  end;
end;

function MargenMinimoLinea(
  const AEscala: TEscalaMargenMinimo;
  AAntiguedadMeses: Integer;
  AMargenForzado: Currency): Currency;
var
  iTramo: Integer;
  iMeses: Integer;
begin
  Result := 0;
  if AMargenForzado > 0 then
    Result := AMargenForzado
  else
  begin
    iMeses := AAntiguedadMeses;
    if iMeses < 0 then
      iMeses := 0;
    for iTramo := 0 to High(AEscala) do
    begin
      if AEscala[iTramo].DesdeMeses <= iMeses then
        Result := AEscala[iTramo].Porcentaje;
    end;
  end;
end;

function AntiguedadAplicable(
  AAntiguedadMeses: Integer;
  ACosteYaDevaluado: Boolean): Integer;
begin
  if ACosteYaDevaluado then
    Result := 0
  else
    Result := AAntiguedadMeses;
end;

function PrecioMinimoConMargen(
  APrecioMedioActual: Currency;
  AMargenMinimo: Currency): Currency;
begin
  if (APrecioMedioActual <= 0) or (AMargenMinimo <= 0) then
    Result := 0
  else
    Result := Currency(RedondearDecimales(
      Extended(APrecioMedioActual) * (1 + (Extended(AMargenMinimo) / 100)),
      4));
end;

function PrecioConTopeVenta(
  APrecio: Currency;
  APrecioVentaDestino: Currency): Currency;
begin
  if (APrecioVentaDestino > 0) and (APrecio > APrecioVentaDestino) then
    Result := APrecioVentaDestino
  else
    Result := APrecio;
end;

function AplicarTopeVentaSimulacion(
  const ASimulacion: TSimulacionRevalorizacionInventario
): TSimulacionRevalorizacionInventario;
var
  iLinea : Integer;
  cPrecio: Currency;
begin
  Result := ASimulacion;
  SetLength(Result.Lineas, Length(ASimulacion.Lineas));
  for iLinea := 0 to High(ASimulacion.Lineas) do
  begin
    Result.Lineas[iLinea] := ASimulacion.Lineas[iLinea];
    cPrecio := PrecioConTopeVenta(
      Result.Lineas[iLinea].PrecioMedioNuevo,
      Result.Lineas[iLinea].Base.PrecioVentaDestino);
    if cPrecio <> Result.Lineas[iLinea].PrecioMedioNuevo then
    begin
      Result.Lineas[iLinea].PrecioMedioNuevo := cPrecio;
      Result.Lineas[iLinea].ValorNuevo :=
        Result.Lineas[iLinea].Base.CantidadFisica * cPrecio;
      Result.Lineas[iLinea].DiferenciaValor :=
        Result.Lineas[iLinea].ValorNuevo -
        Result.Lineas[iLinea].ValorAnterior;
    end;
  end;
  Result.Resumen := ResumirLineasSimulacion(Result.Lineas);
end;

function RedondearACentimosComoFactura(AImporte: Currency): Currency;
begin
  // Mismo cálculo que RedondearImporteMotor (inLibMotorFiscalVenta) sobre
  // la base de la línea: RedondearACentimos, asignado a Currency.
  Result := Currency(RedondearACentimos(Double(AImporte)));
end;

function RedondearImportesSimulacionACentimos(
  const ASimulacion: TSimulacionRevalorizacionInventario
): TSimulacionRevalorizacionInventario;
var
  iLinea: Integer;
begin
  Result := ASimulacion;
  SetLength(Result.Lineas, Length(ASimulacion.Lineas));
  for iLinea := 0 to High(ASimulacion.Lineas) do
  begin
    Result.Lineas[iLinea] := ASimulacion.Lineas[iLinea];
    Result.Lineas[iLinea].ValorAnterior := RedondearACentimosComoFactura(
      Result.Lineas[iLinea].ValorAnterior);
    Result.Lineas[iLinea].ValorNuevo := RedondearACentimosComoFactura(
      Result.Lineas[iLinea].ValorNuevo);
    Result.Lineas[iLinea].DiferenciaValor :=
      Result.Lineas[iLinea].ValorNuevo -
      Result.Lineas[iLinea].ValorAnterior;
  end;
  Result.Resumen := ResumirLineasSimulacion(Result.Lineas);
end;

function ContarLineasLimitadasPorVenta(
  const ASimulacion: TSimulacionRevalorizacionInventario): Integer;
var
  iLinea: Integer;
begin
  Result := 0;
  for iLinea := 0 to High(ASimulacion.Lineas) do
  begin
    if PrecioConTopeVenta(
         ASimulacion.Lineas[iLinea].PrecioMedioNuevo,
         ASimulacion.Lineas[iLinea].Base.PrecioVentaDestino) <>
       ASimulacion.Lineas[iLinea].PrecioMedioNuevo then
      Inc(Result);
  end;
end;

function ClaveLineaMargen(
  const ALinea: TLineaBaseRevalorizacionInventario): string;
begin
  Result := Trim(ALinea.Clave);
  if Result = '' then
    Result := Trim(ALinea.Linea) + '|' + Trim(ALinea.CodigoUnidad);
  Result := UpperCase(Result);
end;

function ContarLineasBajoMargenMinimo(
  const ALineas: TLineasBaseRevalorizacionInventario;
  const ASimulacion: TSimulacionRevalorizacionInventario;
  const AEscala: TEscalaMargenMinimo;
  AMargenForzado: Currency;
  ACosteYaDevaluado: Boolean = False): Integer;
var
  Simulados: TDictionary<string, Currency>;
  iLinea   : Integer;
  cPrecio  : Currency;
  cMinimo  : Currency;
begin
  Result := 0;
  Simulados := TDictionary<string, Currency>.Create;
  try
    for iLinea := 0 to High(ASimulacion.Lineas) do
    begin
      Simulados.AddOrSetValue(
        ClaveLineaMargen(ASimulacion.Lineas[iLinea].Base),
        ASimulacion.Lineas[iLinea].PrecioMedioNuevo);
    end;
    for iLinea := 0 to High(ALineas) do
    begin
      cMinimo := PrecioMinimoConMargen(
        ALineas[iLinea].PrecioMedioActual,
        MargenMinimoLinea(
          AEscala,
          AntiguedadAplicable(
            ALineas[iLinea].AntiguedadMeses, ACosteYaDevaluado),
          AMargenForzado));
      if cMinimo > 0 then
      begin
        if not Simulados.TryGetValue(
             ClaveLineaMargen(ALineas[iLinea]), cPrecio) then
          cPrecio := ALineas[iLinea].PrecioMedioActual;
        if cPrecio < cMinimo then
          Inc(Result);
      end;
    end;
  finally
    FreeAndNil(Simulados);
  end;
end;

end.
