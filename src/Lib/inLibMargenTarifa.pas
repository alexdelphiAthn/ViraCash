{******************************************************************************}
{  Módulo:       inLibMargenTarifa                                             }
{    Tipo:       Librería                                                      }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Margen de un precio de tarifa respecto a su coste, como        }
{               margen sobre venta (sin impuestos) o como coeficiente          }
{               precio / coste, según appMargenTarifasCoeficiente              }
{               (FZ-ISSUE-315).                                                }
{******************************************************************************}
unit inLibMargenTarifa;

interface

type
  TModoMargenTarifa = (mmtMargenVenta, mmtCoeficiente);

const
  // Conservamos la clave para respetar los perfiles anteriores (True/False).
  PARAMETRO_MARGEN_TARIFAS_COEFICIENTE = 'appMargenTarifasCoeficiente';
  MODO_CALCULO_PRECIO_MARGEN = 'Margen';
  MODO_CALCULO_PRECIO_COEFICIENTE = 'Coeficiente';

function ModoCalculoPrecio(const AValor: string): TModoMargenTarifa;
function NombreModoCalculoPrecio(const AValor: string): string;

// 'N', 'R', 'S' o 'E' (fza_ivas_tipos); cualquier otro valor, 0.
function PorcentajeIvaPorTipo(const ATipoIva: string;
  AIvaNormal, AIvaReducido, AIvaSuperReducido, AIvaExento: Double): Double;

function PrecioSinImpuestos(APrecio, APorcentajeIva: Double;
  AImpuestosIncluidos: Boolean): Double;

// Margen sobre venta: (base - coste) / base x 100, con la base sin impuestos.
// Coeficiente: precio / coste, con el precio tal cual está en la tarifa.
// False si con esos datos no hay valor que mostrar.
function CalcularMargenTarifa(AModo: TModoMargenTarifa;
  ACoste, APrecio, APorcentajeIva: Double; AImpuestosIncluidos: Boolean;
  out AValor: Double): Boolean;

// Inversa de CalcularMargenTarifa: precio de tarifa (con impuestos si la
// tarifa los incluye) sin redondear. 0 si el valor no es válido.
function PrecioDesdeMargenTarifa(AModo: TModoMargenTarifa;
  ACoste, AValor, APorcentajeIva: Double;
  AImpuestosIncluidos: Boolean): Double;

function ValorMargenTarifaValido(AModo: TModoMargenTarifa;
  AValor: Double): Boolean;

function TextoMargenTarifa(AModo: TModoMargenTarifa; AValor: Double): string;
function PrecioConDescuentoTarifa(ASalida, APorcentaje: Double): Double;

implementation

uses
  System.SysUtils, inLibRedondeo;

function PrecioConDescuentoTarifa(ASalida, APorcentaje: Double): Double;
begin
  Result := ASalida;
  if APorcentaje <> 0 then
    Result := RedondearACentimos(ASalida * (1 - APorcentaje / 100));
end;

function ModoCalculoPrecio(const AValor: string): TModoMargenTarifa;
var
  Valor: string;
begin
  Valor := Trim(AValor);
  if SameText(Valor, MODO_CALCULO_PRECIO_COEFICIENTE) or
     SameText(Valor, 'True') or (Valor = '1') then
    Result := mmtCoeficiente
  else
    Result := mmtMargenVenta;
end;

function NombreModoCalculoPrecio(const AValor: string): string;
begin
  if ModoCalculoPrecio(AValor) = mmtCoeficiente then
    Result := MODO_CALCULO_PRECIO_COEFICIENTE
  else
    Result := MODO_CALCULO_PRECIO_MARGEN;
end;

function PorcentajeIvaPorTipo(const ATipoIva: string;
  AIvaNormal, AIvaReducido, AIvaSuperReducido, AIvaExento: Double): Double;
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipoIva));
  if sTipo = 'N' then
    Result := AIvaNormal
  else if sTipo = 'R' then
    Result := AIvaReducido
  else if sTipo = 'S' then
    Result := AIvaSuperReducido
  else if sTipo = 'E' then
    Result := AIvaExento
  else
    Result := 0;
end;

function PrecioSinImpuestos(APrecio, APorcentajeIva: Double;
  AImpuestosIncluidos: Boolean): Double;
begin
  Result := APrecio;
  if AImpuestosIncluidos and (APorcentajeIva > 0) then
    Result := APrecio / (1 + APorcentajeIva / 100);
end;

function CalcularMargenTarifa(AModo: TModoMargenTarifa;
  ACoste, APrecio, APorcentajeIva: Double; AImpuestosIncluidos: Boolean;
  out AValor: Double): Boolean;
var
  dBase: Double;
begin
  AValor := 0;
  Result := False;
  if ACoste > 0 then
  begin
    if AModo = mmtCoeficiente then
    begin
      AValor := APrecio / ACoste;
      Result := True;
    end
    else
    begin
      dBase := PrecioSinImpuestos(APrecio, APorcentajeIva,
        AImpuestosIncluidos);
      if dBase > 0 then
      begin
        AValor := (dBase - ACoste) / dBase * 100;
        Result := True;
      end;
    end;
  end;
end;

function ValorMargenTarifaValido(AModo: TModoMargenTarifa;
  AValor: Double): Boolean;
begin
  if AModo = mmtCoeficiente then
    Result := AValor > 0
  else
    // 0 % vende a coste; 100 % sobre venta exigiría un precio infinito.
    Result := (AValor >= 0) and (AValor < 100);
end;

function PrecioDesdeMargenTarifa(AModo: TModoMargenTarifa;
  ACoste, AValor, APorcentajeIva: Double;
  AImpuestosIncluidos: Boolean): Double;
begin
  Result := 0;
  if (ACoste > 0) and ValorMargenTarifaValido(AModo, AValor) then
  begin
    if AModo = mmtCoeficiente then
      Result := ACoste * AValor
    else
    begin
      Result := ACoste / (1 - AValor / 100);
      if AImpuestosIncluidos and (APorcentajeIva > 0) then
        Result := Result * (1 + APorcentajeIva / 100);
    end;
  end;
end;

function TextoMargenTarifa(AModo: TModoMargenTarifa; AValor: Double): string;
begin
  if AModo = mmtCoeficiente then
    Result := FormatFloat('0.00', AValor)
  else
    Result := FormatFloat('0.00" %"', AValor);
end;

end.
