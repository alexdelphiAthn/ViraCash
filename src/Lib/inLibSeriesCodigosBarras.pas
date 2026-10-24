{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSeriesCodigosBarras                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Números de serie (F-LOTEC): validación, código de barras por unidad en    }
{    Code128 con la propia serie (el EAN-13 interno queda para el SKU),        }
{    lectura de la serie desde un GS1 (IA 21), IMEI y preparación de una      }
{    lista de series leídas con pistola o pegadas.                             }
{******************************************************************************}
unit inLibSeriesCodigosBarras;

interface

const
  // Valores de TIPO_CODIGO_CB para códigos por unidad o lote.
  TIPO_CODIGO_BARRAS_CODE128 = 'CODE128';
  TIPO_CODIGO_BARRAS_GS1128 = 'GS1128';
  LONGITUD_IMEI = 15;

type
  TValidacionSerie = (
    vsCorrecta,
    vsVacia,
    vsDemasiadoLarga,
    vsCaracterNoCodificable
  );

  TCodigoBarrasUnidad = record
    Codigo: string;
    Tipo: string;
  end;

  // Resultado de trocear lo leído o pegado en el alta de series.
  TSeriesPreparadas = record
    // Únicas y en el orden de lectura.
    Series: TArray<string>;
    // Repetidas dentro del propio texto (una vez cada una).
    Duplicadas: TArray<string>;
    // Las que no caben en LOTE_* o no se pueden imprimir en Code128.
    Invalidas: TArray<string>;
    function EsCorrecta: Boolean;
  end;

function ValidarSerie(const ASerie: string): TValidacionSerie;
function CodigoBarrasUnidad(
  const ASerie: string;
  out ACodigo: TCodigoBarrasUnidad): TValidacionSerie;
// La serie de una lectura: el IA 21 si es GS1 y lo trae; si no, la lectura.
function SerieDesdeLectura(const ALectura: string): string;
function EsImeiValido(const ASerie: string): Boolean;
function PrepararSeries(const ATexto: string): TSeriesPreparadas;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibGs1, inLibTrazabilidad;

const
  SEPARADORES_SERIES: array[0..5] of string = (
    #13#10, #10, #13, #9, ';', ',');
  // Code128 (juegos B y C) codifica el ASCII imprimible.
  PRIMER_CARACTER_CODE128 = #32;
  ULTIMO_CARACTER_CODE128 = #126;

function TSeriesPreparadas.EsCorrecta: Boolean;
begin
  Result := (Length(Series) > 0) and (Length(Duplicadas) = 0) and
            (Length(Invalidas) = 0);
end;

function ValidarSerie(const ASerie: string): TValidacionSerie;
var
  cCaracter: Char;
  sSerie: string;
begin
  sSerie := NormalizarLote(ASerie);
  if sSerie = '' then
    Result := vsVacia
  else if Length(sSerie) > LONGITUD_MAXIMA_LOTE then
    Result := vsDemasiadoLarga
  else
  begin
    Result := vsCorrecta;
    for cCaracter in sSerie do
    begin
      if (cCaracter < PRIMER_CARACTER_CODE128) or
         (cCaracter > ULTIMO_CARACTER_CODE128) then
        Result := vsCaracterNoCodificable;
    end;
  end;
end;

function CodigoBarrasUnidad(
  const ASerie: string;
  out ACodigo: TCodigoBarrasUnidad): TValidacionSerie;
begin
  // Decisión del 06/10/2026: el código de la unidad es la propia serie en
  // Code128 (el IMEI de la caja se lee igual que la etiqueta).
  ACodigo := Default(TCodigoBarrasUnidad);
  Result := ValidarSerie(ASerie);
  if Result = vsCorrecta then
  begin
    ACodigo.Codigo := NormalizarLote(ASerie);
    ACodigo.Tipo := TIPO_CODIGO_BARRAS_CODE128;
  end;
end;

function SerieDesdeLectura(const ALectura: string): string;
var
  rGs1: TResultadoGs1;
begin
  Result := NormalizarLote(ALectura);
  if EsLecturaGs1(ALectura) then
  begin
    rGs1 := InterpretarGs1(ALectura);
    if rGs1.EsValido and (rGs1.Datos.Serie <> '') then
      Result := rGs1.Datos.Serie;
  end;
end;

function EsImeiValido(const ASerie: string): Boolean;
var
  cCaracter: Char;
  iDigito: Integer;
  iIndice: Integer;
  iSuma: Integer;
begin
  // 15 dígitos con control de Luhn: avisa de una lectura incompleta o de un
  // número tecleado mal. No se exige: no toda serie es un IMEI.
  Result := Length(ASerie) = LONGITUD_IMEI;
  for cCaracter in ASerie do
  begin
    if not CharInSet(cCaracter, ['0'..'9']) then
      Result := False;
  end;
  if Result then
  begin
    iSuma := 0;
    for iIndice := 1 to LONGITUD_IMEI do
    begin
      iDigito := Ord(ASerie[iIndice]) - Ord('0');
      if not Odd(iIndice) then
      begin
        iDigito := iDigito * 2;
        if iDigito > 9 then
          iDigito := iDigito - 9;
      end;
      iSuma := iSuma + iDigito;
    end;
    Result := iSuma mod 10 = 0;
  end;
end;

function PrepararSeries(const ATexto: string): TSeriesPreparadas;
var
  aTrozos: TArray<string>;
  oDuplicadas: TDictionary<string, Boolean>;
  oVistas: TDictionary<string, Boolean>;
  sClave: string;
  sSerie: string;
  sTrozo: string;
begin
  // La serie es única en toda la base y MariaDB compara sin distinguir
  // mayúsculas: «ab1» y «AB1» son la misma.
  Result := Default(TSeriesPreparadas);
  aTrozos := ATexto.Split(SEPARADORES_SERIES,
                          TStringSplitOptions.ExcludeEmpty);
  oVistas := TDictionary<string, Boolean>.Create;
  oDuplicadas := TDictionary<string, Boolean>.Create;
  try
    for sTrozo in aTrozos do
    begin
      // Una línea con solo espacios no cuenta.
      sSerie := SerieDesdeLectura(sTrozo);
      sClave := UpperCase(sSerie);
      if sSerie <> '' then
      begin
        if ValidarSerie(sSerie) <> vsCorrecta then
          Result.Invalidas := Result.Invalidas + [sSerie]
        else if not oVistas.ContainsKey(sClave) then
        begin
          oVistas.Add(sClave, True);
          Result.Series := Result.Series + [sSerie];
        end
        else if not oDuplicadas.ContainsKey(sClave) then
        begin
          oDuplicadas.Add(sClave, True);
          Result.Duplicadas := Result.Duplicadas + [sSerie];
        end;
      end;
    end;
  finally
    FreeAndNil(oDuplicadas);
    FreeAndNil(oVistas);
  end;
end;

end.
