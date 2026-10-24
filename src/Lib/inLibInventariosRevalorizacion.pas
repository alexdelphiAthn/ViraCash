{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventariosRevalorizacion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       11/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Calcula la simulación de apreciación o depreciación del PMP de las líneas }
{    de un inventario, sin VCL, datasets ni persistencia. La base del cálculo  }
{    es el PMP o el precio de última compra; cuando una línea no tiene última  }
{    compra se usa su PMP y se cuenta en el resumen.                           }
{******************************************************************************}
unit inLibInventariosRevalorizacion;

interface

type
  TTipoRevalorizacionInventario = (
    triApreciacion,
    triDepreciacion
  );

  TBaseRevalorizacionInventario = (
    briPrecioMedio,
    briUltimaCompra
  );

  TLineaBaseRevalorizacionInventario = record
    Linea: string;
    CodigoArticulo: string;
    CodigoUnidad: string;
    Descripcion: string;
    CantidadTeorica: Currency;
    CantidadFisica: Currency;
    PrecioMedioActual: Currency;
    PrecioMedioNuevoAnterior: Currency;
    EsPrecioMedioCorregido: Boolean;
    // Identificador opaco del llamador (p. ej. el número de movimiento);
    // no se muestra y permite enlazar la simulación con su origen.
    Clave: string;
    // Precio de la última compra del SKU o del artículo; 0 si no consta.
    PrecioUltimaCompra: Currency;
    // Meses desde la última compra del SKU: la moda pierde valor con la
    // temporada y el margen mínimo exigible baja por tramos.
    AntiguedadMeses: Integer;
    // Precio real sin IVA al que la tienda destino lo ha vendido; 0 si no
    // consta o si la modalidad no factura ventas.
    PrecioVentaDestino: Currency;
    // FZ-ISSUE-367: unidades vendidas a 0 € (regalo, promoción) o cuya
    // venta no tiene línea de factura. Sin tope: se facturan al precio
    // valorado y el modal lo avisa.
    VentaDestinoACero: Boolean;
    VentaDestinoSinLinea: Boolean;
  end;

  TLineasBaseRevalorizacionInventario =
    array of TLineaBaseRevalorizacionInventario;

  TLineaSimulacionRevalorizacionInventario = record
    Base: TLineaBaseRevalorizacionInventario;
    PrecioMedioNuevo: Currency;
    ValorAnterior: Currency;
    ValorNuevo: Currency;
    DiferenciaUnidades: Currency;
    DiferenciaValor: Currency;
    // Precio al que se aplicó el porcentaje.
    PrecioBase: Currency;
    // True si se pidió la última compra y la línea no la tiene (usa el PMP).
    SinUltimaCompra: Boolean;
  end;

  TLineasSimulacionRevalorizacionInventario =
    array of TLineaSimulacionRevalorizacionInventario;

  TResumenSimulacionRevalorizacionInventario = record
    NumeroLineas: Integer;
    LineasConDiferenciaUnidades: Integer;
    LineasConPrecioCorregido: Integer;
    LineasSinUltimaCompra: Integer;
    // Líneas con precio base 0 (sin PMP ni última compra): el
    // porcentaje no las revaloriza y su precio simulado queda en 0.
    LineasSinPrecioBase: Integer;
    CantidadTeorica: Currency;
    CantidadFisica: Currency;
    ValorAnterior: Currency;
    ValorNuevo: Currency;
    DiferenciaValor: Currency;
  end;

  TSimulacionRevalorizacionInventario = record
    Tipo: TTipoRevalorizacionInventario;
    Porcentaje: Currency;
    BaseCalculo: TBaseRevalorizacionInventario;
    Lineas: TLineasSimulacionRevalorizacionInventario;
    Resumen: TResumenSimulacionRevalorizacionInventario;
  end;

function PorcentajeRevalorizacionValido(
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Boolean;
function CalcularPrecioMedioRevalorizado(
  APrecioMedioActual: Currency;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Currency;
function PrecioBaseRevalorizacion(
  const ALinea: TLineaBaseRevalorizacionInventario;
  ABase: TBaseRevalorizacionInventario;
  out ASinUltimaCompra: Boolean): Currency;
function SimularRevalorizacionInventario(
  const ALineas: TLineasBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): TSimulacionRevalorizacionInventario; overload;
function SimularRevalorizacionInventario(
  const ALineas: TLineasBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency;
  ABase: TBaseRevalorizacionInventario):
  TSimulacionRevalorizacionInventario; overload;
// Rehace el resumen a partir de las líneas; hace falta cuando alguien
// ajusta un precio simulado después de calcular la simulación.
function ResumirLineasSimulacion(
  const ALineas: TLineasSimulacionRevalorizacionInventario):
  TResumenSimulacionRevalorizacionInventario;
implementation

uses
  inLibRedondeo,
  System.Math,
  System.SysUtils;

function PorcentajeRevalorizacionValido(
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Boolean;
begin
  Result := APorcentaje > 0;
  if ATipo = triDepreciacion then
    Result := Result and (APorcentaje <= 100);
end;

function CalcularPrecioMedioRevalorizado(
  APrecioMedioActual: Currency;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): Currency;
var
  Factor: Extended;
begin
  if not PorcentajeRevalorizacionValido(ATipo, APorcentaje) then
    raise EArgumentOutOfRangeException.Create('APorcentaje');
  Factor := 1;
  if ATipo = triApreciacion then
    Factor := Factor + (Extended(APorcentaje) / 100)
  else
    Factor := Factor - (Extended(APorcentaje) / 100);
  Result := Currency(RedondearDecimales(
    Extended(APrecioMedioActual) * Factor, 4));
end;

function PrecioBaseRevalorizacion(
  const ALinea: TLineaBaseRevalorizacionInventario;
  ABase: TBaseRevalorizacionInventario;
  out ASinUltimaCompra: Boolean): Currency;
begin
  ASinUltimaCompra := False;
  Result := ALinea.PrecioMedioActual;
  if ABase = briUltimaCompra then
  begin
    if ALinea.PrecioUltimaCompra > 0 then
      Result := ALinea.PrecioUltimaCompra
    else
      ASinUltimaCompra := True;
  end;
end;

function CrearLineaSimulada(
  const ALinea: TLineaBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency;
  ABase: TBaseRevalorizacionInventario):
  TLineaSimulacionRevalorizacionInventario;
var
  SinUltimaCompra: Boolean;
begin
  Result.Base := ALinea;
  Result.PrecioBase := PrecioBaseRevalorizacion(
    ALinea, ABase, SinUltimaCompra);
  Result.SinUltimaCompra := SinUltimaCompra;
  Result.PrecioMedioNuevo := CalcularPrecioMedioRevalorizado(
    Result.PrecioBase, ATipo, APorcentaje);
  Result.ValorAnterior :=
    ALinea.CantidadTeorica * ALinea.PrecioMedioActual;
  Result.ValorNuevo :=
    ALinea.CantidadFisica * Result.PrecioMedioNuevo;
  Result.DiferenciaUnidades :=
    ALinea.CantidadFisica - ALinea.CantidadTeorica;
  // A centimos, como la linea grabada (FZ-ISSUE-250): el resumen suma
  // estas diferencias y debe dar el total del inventario.
  Result.DiferenciaValor := RedondearACentimos(
    Result.ValorNuevo - Result.ValorAnterior);
end;

procedure AcumularLineaEnResumen(
  const ALinea: TLineaSimulacionRevalorizacionInventario;
  var AResumen: TResumenSimulacionRevalorizacionInventario);
begin
  Inc(AResumen.NumeroLineas);
  AResumen.CantidadTeorica :=
    AResumen.CantidadTeorica + ALinea.Base.CantidadTeorica;
  AResumen.CantidadFisica :=
    AResumen.CantidadFisica + ALinea.Base.CantidadFisica;
  AResumen.ValorAnterior :=
    AResumen.ValorAnterior + ALinea.ValorAnterior;
  AResumen.ValorNuevo := AResumen.ValorNuevo + ALinea.ValorNuevo;
  AResumen.DiferenciaValor :=
    AResumen.DiferenciaValor + ALinea.DiferenciaValor;
  if ALinea.DiferenciaUnidades <> 0 then
    Inc(AResumen.LineasConDiferenciaUnidades);
  if ALinea.Base.EsPrecioMedioCorregido then
    Inc(AResumen.LineasConPrecioCorregido);
  if ALinea.SinUltimaCompra then
    Inc(AResumen.LineasSinUltimaCompra);
  if ALinea.PrecioBase = 0 then
    Inc(AResumen.LineasSinPrecioBase);
end;

function ResumirLineasSimulacion(
  const ALineas: TLineasSimulacionRevalorizacionInventario):
  TResumenSimulacionRevalorizacionInventario;
var
  iLinea: Integer;
begin
  Result := Default(TResumenSimulacionRevalorizacionInventario);
  for iLinea := 0 to High(ALineas) do
  begin
    AcumularLineaEnResumen(ALineas[iLinea], Result);
  end;
end;

function SimularRevalorizacionInventario(
  const ALineas: TLineasBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency): TSimulacionRevalorizacionInventario;
begin
  Result := SimularRevalorizacionInventario(
    ALineas, ATipo, APorcentaje, briPrecioMedio);
end;

function SimularRevalorizacionInventario(
  const ALineas: TLineasBaseRevalorizacionInventario;
  ATipo: TTipoRevalorizacionInventario;
  APorcentaje: Currency;
  ABase: TBaseRevalorizacionInventario):
  TSimulacionRevalorizacionInventario;
var
  iLinea: Integer;
begin
  if not PorcentajeRevalorizacionValido(ATipo, APorcentaje) then
    raise EArgumentOutOfRangeException.Create('APorcentaje');
  Result := Default(TSimulacionRevalorizacionInventario);
  Result.Tipo := ATipo;
  Result.Porcentaje := APorcentaje;
  Result.BaseCalculo := ABase;
  SetLength(Result.Lineas, Length(ALineas));
  for iLinea := 0 to High(ALineas) do
  begin
    Result.Lineas[iLinea] := CrearLineaSimulada(
      ALineas[iLinea], ATipo, APorcentaje, ABase);
    AcumularLineaEnResumen(
      Result.Lineas[iLinea], Result.Resumen);
  end;
end;

end.
