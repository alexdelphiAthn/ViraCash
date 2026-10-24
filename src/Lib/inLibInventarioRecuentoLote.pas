{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventarioRecuentoLote                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Recuento de inventario por lote (F-LOTEC-014). Las listas de recuento     }
{    (móvil, CSV, Excel) son «SKU=valor»; el valor admite ahora                }
{    «CANTIDAD;LOTE;CADUCIDAD» (caducidad aaaa-mm-dd o dd/mm/aaaa). Sin lote   }
{    el valor sigue siendo solo la cantidad, como antes.                       }
{******************************************************************************}
unit inLibInventarioRecuentoLote;

interface

const
  SEPARADOR_VALOR_RECUENTO = ';';

type
  TValorRecuentoLote = record
    Cantidad: Double;
    TieneCantidad: Boolean;
    Lote: string;
    FechaCaducidad: TDateTime;   // 0 = sin caducidad
  end;

  TCantidadRecuentoLote = record
    Sku: string;
    Lote: string;
    Cantidad: Double;
    FechaCaducidad: TDateTime;
  end;
  TCantidadesRecuentoLote = TArray<TCantidadRecuentoLote>;

// Valor de una entrada de la lista: «CANTIDAD[;LOTE[;CADUCIDAD]]». Sin
// cantidad legible, TieneCantidad = False (el que llama decide, como antes,
// que es una unidad). Una caducidad ilegible se deja a 0.
function LeerValorRecuentoLote(const AValor: string): TValorRecuentoLote;

// Valor para la lista: solo la cantidad si no hay lote.
function ValorRecuentoLote(ACantidad: Double; const ALote: string;
  AFechaCaducidad: TDateTime): string;

// Caducidad de un recuento: 'aaaa-mm-dd' (servidor, GS1, ISO) o
// 'dd/mm/aaaa' (Excel, teclado). Vacía = True con AFecha = 0.
function TryLeerFechaCaducidadRecuento(const ATexto: string;
  out AFecha: TDateTime): Boolean;

function MismoLoteRecuento(const ALote1, ALote2: string): Boolean;

// Suma ACantidad a la entrada (SKU, lote) o la añade al final, en el
// orden de llegada. La caducidad es la última no vacía.
procedure AcumularRecuentoLote(var ACantidades: TCantidadesRecuentoLote;
  const ASku, ALote: string; ACantidad: Double; AFechaCaducidad: TDateTime);

implementation

uses
  System.SysUtils, System.DateUtils;

function TryLeerFechaCaducidadRecuento(const ATexto: string;
  out AFecha: TDateTime): Boolean;
var
  oFormato: TFormatSettings;
  sTexto: string;
begin
  AFecha := 0;
  sTexto := Trim(ATexto);
  Result := sTexto = '';
  if not Result then
  begin
    // 'aaaa-mm-dd hh:nn:ss' o 'aaaa-mm-ddThh...': basta la fecha.
    if (Length(sTexto) > 10) and (Pos('-', sTexto) = 5) then
      sTexto := Copy(sTexto, 1, 10);
    oFormato := TFormatSettings.Create;
    oFormato.DateSeparator := '-';
    oFormato.ShortDateFormat := 'yyyy-mm-dd';
    Result := (Pos('-', sTexto) = 5) and
      TryStrToDate(sTexto, AFecha, oFormato);
    if not Result then
    begin
      oFormato.DateSeparator := '/';
      oFormato.ShortDateFormat := 'dd/mm/yyyy';
      Result := TryStrToDate(sTexto, AFecha, oFormato);
    end;
    if Result then
      AFecha := DateOf(AFecha)
    else
      AFecha := 0;
  end;
end;

function LeerValorRecuentoLote(const AValor: string): TValorRecuentoLote;
var
  aPartes: TArray<string>;
  dFecha: TDateTime;
begin
  Result := Default(TValorRecuentoLote);
  aPartes := AValor.Split([SEPARADOR_VALOR_RECUENTO]);
  if Length(aPartes) > 0 then
    Result.TieneCantidad := TryStrToFloat(Trim(aPartes[0]), Result.Cantidad);
  if not Result.TieneCantidad then
    Result.Cantidad := 0;
  if Length(aPartes) > 1 then
    Result.Lote := Trim(aPartes[1]);
  if (Length(aPartes) > 2) and
     TryLeerFechaCaducidadRecuento(aPartes[2], dFecha) then
    Result.FechaCaducidad := dFecha;
end;

function ValorRecuentoLote(ACantidad: Double; const ALote: string;
  AFechaCaducidad: TDateTime): string;
begin
  Result := FloatToStr(ACantidad);
  if Trim(ALote) <> '' then
  begin
    Result := Result + SEPARADOR_VALOR_RECUENTO + Trim(ALote);
    if AFechaCaducidad > 0 then
      Result := Result + SEPARADOR_VALOR_RECUENTO +
        FormatDateTime('yyyy"-"mm"-"dd', AFechaCaducidad);
  end;
end;

function MismoLoteRecuento(const ALote1, ALote2: string): Boolean;
begin
  Result := SameText(Trim(ALote1), Trim(ALote2));
end;

procedure AcumularRecuentoLote(var ACantidades: TCantidadesRecuentoLote;
  const ASku, ALote: string; ACantidad: Double; AFechaCaducidad: TDateTime);
var
  iEntrada: Integer;
  iEncontrada: Integer;
begin
  iEncontrada := -1;
  for iEntrada := 0 to High(ACantidades) do
    if (iEncontrada < 0) and
       SameText(ACantidades[iEntrada].Sku, Trim(ASku)) and
       MismoLoteRecuento(ACantidades[iEntrada].Lote, ALote) then
      iEncontrada := iEntrada;
  if iEncontrada < 0 then
  begin
    iEncontrada := Length(ACantidades);
    SetLength(ACantidades, iEncontrada + 1);
    ACantidades[iEncontrada] := Default(TCantidadRecuentoLote);
    ACantidades[iEncontrada].Sku := Trim(ASku);
    ACantidades[iEncontrada].Lote := Trim(ALote);
  end;
  ACantidades[iEncontrada].Cantidad :=
    ACantidades[iEncontrada].Cantidad + ACantidad;
  if AFechaCaducidad > 0 then
    ACantidades[iEncontrada].FechaCaducidad := AFechaCaducidad;
end;

end.
