{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPestanasEje                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Modelo de las pestañas del eje S de un tipo de variación (la copa):       }
{    «Todas» y una por valor, con su total. Sin VCL: lo pinta                  }
{    inLibPestanasEjeVcl y lo usan Ctrl+U y, más adelante, las rejillas de     }
{    tallas de compras, ventas y TPV (tercera dimensión, fase 3).              }
{******************************************************************************}
unit inLibPestanasEje;

interface

type
  TValorPestanaEje = record
    // Valor del atributo (B, C...); es lo que filtra la rejilla.
    Codigo: string;
    Total: Double;
  end;
  TValoresPestanaEje = TArray<TValorPestanaEje>;

  TModeloPestanasEje = record
    // Nombre del atributo de pestañas en el tipo de variación (Copa).
    NombreEje: string;
    Valores: TValoresPestanaEje;
    // False cuando el total no tiene sentido (estado «Todo a la vez»).
    HayTotales: Boolean;
  end;

const
  // Índice 0 = «Todas»; el valor i está en el índice i + 1.
  INDICE_PESTANA_TODAS = 0;

// Sin valores no hay pestañas: «Tallas y colores» se ve como siempre.
function HayPestanasEje(const AModelo: TModeloPestanasEje): Boolean;
function TotalPestanasEje(const AModelo: TModeloPestanasEje): Double;
// Textos de las pestañas en orden: «Todas (35)», «A (3)», «B (10)»...
function TextosPestanasEje(const AModelo: TModeloPestanasEje):
  TArray<string>;
// '' para «Todas» o un índice fuera de rango.
function CodigoPestanaEje(const AModelo: TModeloPestanasEje;
  AIndice: Integer): string;
// Índice del valor; «Todas» si ya no existe (otro artículo o sin stock).
function IndicePestanaEje(const AModelo: TModeloPestanasEje;
  const ACodigo: string): Integer;
function FormatearTotalPestanaEje(ATotal: Double): string;
// Rótulo de una fila de rejilla: «CARNE · B»; sin copa, solo el color.
function TextoFilaConPestana(const AColor, APestana: string): string;
// Pestañas de las líneas de un documento: una por valor que aparezca en
// AValoresLineas (vacío = sin copa, solo cuenta en «Todas»), con la suma
// de AUnidadesLineas, en el orden de AOrden y después los que no estén.
function ModeloPestanasDeLineas(const ANombreEje: string;
  const AOrden, AValoresLineas: TArray<string>;
  const AUnidadesLineas: TArray<Double>): TModeloPestanasEje;

implementation

uses
  System.SysUtils,
  inLibMsgArticulos;

function HayPestanasEje(const AModelo: TModeloPestanasEje): Boolean;
begin
  Result := Length(AModelo.Valores) > 0;
end;

function TotalPestanasEje(const AModelo: TModeloPestanasEje): Double;
var
  oValor: TValorPestanaEje;
begin
  Result := 0;
  for oValor in AModelo.Valores do
    Result := Result + oValor.Total;
end;

// Unidades enteras sin decimales; metros u otras unidades con los que
// tengan, hasta tres.
function FormatearTotalPestanaEje(ATotal: Double): string;
begin
  Result := FormatFloat('0.###', ATotal);
end;

function TextoConTotal(const ATexto: string; ATotal: Double;
  AHayTotales: Boolean): string;
begin
  Result := ATexto;
  if AHayTotales then
    Result := Format('%s (%s)', [ATexto, FormatearTotalPestanaEje(ATotal)]);
end;

function TextosPestanasEje(const AModelo: TModeloPestanasEje):
  TArray<string>;
var
  iIndice: Integer;
begin
  Result := nil;
  if HayPestanasEje(AModelo) then
  begin
    SetLength(Result, Length(AModelo.Valores) + 1);
    Result[INDICE_PESTANA_TODAS] := TextoConTotal(SPestanaEjeTodas,
      TotalPestanasEje(AModelo), AModelo.HayTotales);
    for iIndice := 0 to High(AModelo.Valores) do
      Result[iIndice + 1] := TextoConTotal(AModelo.Valores[iIndice].Codigo,
        AModelo.Valores[iIndice].Total, AModelo.HayTotales);
  end;
end;

function CodigoPestanaEje(const AModelo: TModeloPestanasEje;
  AIndice: Integer): string;
begin
  Result := '';
  if (AIndice > INDICE_PESTANA_TODAS) and
     (AIndice <= Length(AModelo.Valores)) then
    Result := AModelo.Valores[AIndice - 1].Codigo;
end;

function IndicePestanaEje(const AModelo: TModeloPestanasEje;
  const ACodigo: string): Integer;
var
  iIndice: Integer;
begin
  Result := INDICE_PESTANA_TODAS;
  if ACodigo <> '' then
    for iIndice := 0 to High(AModelo.Valores) do
      if SameText(AModelo.Valores[iIndice].Codigo, ACodigo) then
        Result := iIndice + 1;
end;

function TextoFilaConPestana(const AColor, APestana: string): string;
begin
  Result := AColor;
  if Trim(APestana) <> '' then
  begin
    if Trim(AColor) = '' then
      Result := Trim(APestana)
    else
      Result := AColor + ' ' + #$00B7 + ' ' + Trim(APestana);
  end;
end;

function IndiceValor(const AValores: TValoresPestanaEje;
  const ACodigo: string): Integer;
var
  iIndice: Integer;
begin
  Result := -1;
  for iIndice := 0 to High(AValores) do
    if SameText(AValores[iIndice].Codigo, ACodigo) then
      Result := iIndice;
end;

function ModeloPestanasDeLineas(const ANombreEje: string;
  const AOrden, AValoresLineas: TArray<string>;
  const AUnidadesLineas: TArray<Double>): TModeloPestanasEje;
var
  aPresentes: TValoresPestanaEje;
  oValor: TValorPestanaEje;
  sCodigo: string;
  iIndice: Integer;
  iPosicion: Integer;
begin
  Result := Default(TModeloPestanasEje);
  Result.NombreEje := ANombreEje;
  Result.HayTotales := True;
  aPresentes := nil;
  for iIndice := 0 to High(AValoresLineas) do
  begin
    sCodigo := Trim(AValoresLineas[iIndice]);
    if sCodigo <> '' then
    begin
      iPosicion := IndiceValor(aPresentes, sCodigo);
      if iPosicion < 0 then
      begin
        oValor.Codigo := sCodigo;
        oValor.Total := 0;
        aPresentes := aPresentes + [oValor];
        iPosicion := High(aPresentes);
      end;
      if iIndice <= High(AUnidadesLineas) then
        aPresentes[iPosicion].Total := aPresentes[iPosicion].Total +
          AUnidadesLineas[iIndice];
    end;
  end;
  for sCodigo in AOrden do
  begin
    iPosicion := IndiceValor(aPresentes, Trim(sCodigo));
    if iPosicion >= 0 then
    begin
      Result.Valores := Result.Valores + [aPresentes[iPosicion]];
      Delete(aPresentes, iPosicion, 1);
    end;
  end;
  Result.Valores := Result.Valores + aPresentes;
end;

end.
