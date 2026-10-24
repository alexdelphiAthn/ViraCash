{******************************************************************************}
{                                                                              }
{  Modulo:       inLibRedondeo                                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Redondeo decimal "medio alejandose del cero" sobre Double. SimpleRoundTo  }
{    trabaja con la representacion binaria y deja 545,925 en 545,92 y 1,005    }
{    en 1,00 (545,92499... y 1,00499... en Double). FZ-ISSUE-205 y 207.        }
{******************************************************************************}
unit inLibRedondeo;

interface

// Redondea AValor a ADecimales decimales, mitad alejandose del cero, como
// se redondearia el numero decimal escrito (545,925 -> 545,93).
function RedondearDecimales(AValor: Double; ADecimales: Integer): Double;

// Importe a centimos: RedondearDecimales(AImporte, 2).
function RedondearACentimos(AImporte: Double): Double;

// Multiplo mas cercano, con el mismo criterio decimal en las mitades.
function RedondearAMultiplo(AImporte, AMultiplo: Double): Double;

implementation

uses
  System.Math;

function RedondearDecimales(AValor: Double; ADecimales: Integer): Double;
var
  rPotencia, rEscalado: Double;
begin
  rPotencia := IntPower(10, ADecimales);
  rEscalado := Abs(AValor) * rPotencia;
  // Tolerancia relativa: absorbe el error de representacion y de la
  // multiplicacion (unos pocos ulp) sin alterar valores claramente
  // por debajo de la mitad. Int y no Floor: Floor devuelve Integer de 32
  // bits y desbordaba desde 21.474.836,47 EUR (FZ-ISSUE-248); rEscalado
  // nunca es negativo, asi que truncar es lo mismo que el suelo.
  Result := Sign(AValor) *
    Int(rEscalado + 0.5 + Max(1E-9, rEscalado * 1E-12)) / rPotencia;
end;

function RedondearACentimos(AImporte: Double): Double;
begin
  Result := RedondearDecimales(AImporte, 2);
end;

function RedondearAMultiplo(AImporte, AMultiplo: Double): Double;
begin
  Result := AImporte;
  if AMultiplo > 0 then
    Result := RedondearDecimales(AImporte / AMultiplo, 0) * AMultiplo;
end;

end.
