{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEjesVariacion                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ejes de los atributos de un tipo de variación: fila (F), pestañas (S)     }
{    y pivote (P). Misma regla que VI_VARIACIONES_EJES                         }
{    (20261023_variaciones_eje_pestana.sql) y validación del eje declarado     }
{    en fza_variaciones_atributos.EJE_VA antes de grabarlo.                    }
{******************************************************************************}
unit inLibEjesVariacion;

interface

const
  EJE_VARIACION_FILA = 'F';
  EJE_VARIACION_PIVOTE = 'P';
  EJE_VARIACION_PESTANA = 'S';

type
  TEjeVariacion = (evSinEje, evFila, evPestana, evPivote);

  // Atributo de un tipo de variación tal como está en
  // fza_variaciones_atributos. Orden nulo se pasa como 0; EjeDeclarado
  // vacío significa «por posición».
  TAtributoEjeVariacion = record
    Id: string;
    Orden: Integer;
    EjeDeclarado: string;
  end;
  TAtributosEjeVariacion = TArray<TAtributoEjeVariacion>;

  TValidacionEjeVariacion = (vevValido, vevValorNoAdmitido,
    vevPestanaEnExtremo, vevPestanaRepetida);

  TResultadoValidacionEjes = record
    Resultado: TValidacionEjeVariacion;
    // Atributo que incumple la regla; vacío si es válido.
    IdAtributo: string;
  end;

function CodigoEjeVariacion(AEje: TEjeVariacion): string;
// Eje de cada atributo, en el mismo orden que AAtributos. El último por
// orden (y código) es el pivote; el primero, la fila; de los intermedios,
// el primero con EJE_VA = 'S' es el de pestañas y el resto no tiene eje.
function CalcularEjesVariacion(
  const AAtributos: TAtributosEjeVariacion): TArray<TEjeVariacion>;
// Solo admite 'S' o vacío. Pestañas solo en un atributo intermedio y en
// uno solo por tipo de variación. Las variaciones sin ningún eje
// declarado son siempre válidas. AValidarPosicion=False permite dar de
// alta los atributos en orden; el guardado completo valida los extremos.
function ValidarEjesVariacion(
  const AAtributos: TAtributosEjeVariacion;
  AValidarPosicion: Boolean = True): TResultadoValidacionEjes;
// Aviso para el usuario; vacío si la validación es correcta.
function MensajeValidacionEjesVariacion(
  const AResultado: TResultadoValidacionEjes): string;

implementation

uses
  System.SysUtils,
  inLibMsgArticulos,
  System.Generics.Collections,
  System.Generics.Defaults;

function CodigoEjeVariacion(AEje: TEjeVariacion): string;
begin
  case AEje of
    evFila:
      Result := EJE_VARIACION_FILA;
    evPestana:
      Result := EJE_VARIACION_PESTANA;
    evPivote:
      Result := EJE_VARIACION_PIVOTE;
  else
    Result := '';
  end;
end;

function EjeDeclaradoNormalizado(
  const AAtributo: TAtributoEjeVariacion): string;
begin
  Result := UpperCase(Trim(AAtributo.EjeDeclarado));
end;

// Índices de AAtributos ordenados como la vista: ORDEN_VA y, a igualdad,
// el código del atributo sin distinguir mayúsculas.
function IndicesPorOrden(
  const AAtributos: TAtributosEjeVariacion): TArray<Integer>;
var
  iIndice: Integer;
  aCopia: TAtributosEjeVariacion;
begin
  aCopia := AAtributos;
  SetLength(Result, Length(AAtributos));
  for iIndice := 0 to High(Result) do
    Result[iIndice] := iIndice;
  TArray.Sort<Integer>(Result, TComparer<Integer>.Construct(
    function(const AIzquierda, ADerecha: Integer): Integer
    begin
      if aCopia[AIzquierda].Orden < aCopia[ADerecha].Orden then
        Result := -1
      else if aCopia[AIzquierda].Orden > aCopia[ADerecha].Orden then
        Result := 1
      else
        Result := CompareText(aCopia[AIzquierda].Id,
          aCopia[ADerecha].Id);
    end));
end;

function CalcularEjesVariacion(
  const AAtributos: TAtributosEjeVariacion): TArray<TEjeVariacion>;
var
  aOrden: TArray<Integer>;
  iPosicion: Integer;
  bPestanaAsignada: Boolean;
begin
  SetLength(Result, Length(AAtributos));
  aOrden := IndicesPorOrden(AAtributos);
  bPestanaAsignada := False;
  for iPosicion := 0 to High(aOrden) do
  begin
    if iPosicion = High(aOrden) then
      Result[aOrden[iPosicion]] := evPivote
    else if iPosicion = 0 then
      Result[aOrden[iPosicion]] := evFila
    else if (not bPestanaAsignada) and
            (EjeDeclaradoNormalizado(AAtributos[aOrden[iPosicion]]) =
             EJE_VARIACION_PESTANA) then
    begin
      Result[aOrden[iPosicion]] := evPestana;
      bPestanaAsignada := True;
    end
    else
      Result[aOrden[iPosicion]] := evSinEje;
  end;
end;

function ResultadoValidacion(AResultado: TValidacionEjeVariacion;
  const AIdAtributo: string): TResultadoValidacionEjes;
begin
  Result.Resultado := AResultado;
  Result.IdAtributo := AIdAtributo;
end;

function ValidarEjeEnPosicion(const AAtributos: TAtributosEjeVariacion;
  const AOrden: TArray<Integer>; APosicion: Integer;
  var ATienePestana: Boolean;
  AValidarPosicion: Boolean): TValidacionEjeVariacion;
var
  sEje: string;
begin
  Result := vevValido;
  sEje := EjeDeclaradoNormalizado(AAtributos[AOrden[APosicion]]);
  if sEje = EJE_VARIACION_PESTANA then
  begin
    if AValidarPosicion and
       ((APosicion = 0) or (APosicion = High(AOrden))) then
      Result := vevPestanaEnExtremo
    else if ATienePestana then
      Result := vevPestanaRepetida;
    ATienePestana := True;
  end
  else if sEje <> '' then
    Result := vevValorNoAdmitido;
end;

function ValidarEjesVariacion(
  const AAtributos: TAtributosEjeVariacion;
  AValidarPosicion: Boolean): TResultadoValidacionEjes;
var
  aOrden: TArray<Integer>;
  iPosicion: Integer;
  bTienePestana: Boolean;
  eResultado: TValidacionEjeVariacion;
begin
  Result := ResultadoValidacion(vevValido, '');
  aOrden := IndicesPorOrden(AAtributos);
  bTienePestana := False;
  iPosicion := 0;
  while (Result.Resultado = vevValido) and (iPosicion <= High(aOrden)) do
  begin
    eResultado := ValidarEjeEnPosicion(AAtributos, aOrden, iPosicion,
      bTienePestana, AValidarPosicion);
    if eResultado <> vevValido then
      Result := ResultadoValidacion(eResultado,
        AAtributos[aOrden[iPosicion]].Id);
    Inc(iPosicion);
  end;
end;

function MensajeValidacionEjesVariacion(
  const AResultado: TResultadoValidacionEjes): string;
begin
  case AResultado.Resultado of
    vevValorNoAdmitido:
      Result := Format(SErrorEjeVariacionNoAdmitido, [AResultado.IdAtributo]);
    vevPestanaEnExtremo:
      Result := Format(SErrorPestanasVariacionEnExtremo,
        [AResultado.IdAtributo]);
    vevPestanaRepetida:
      Result := Format(SErrorPestanasVariacionRepetidas,
        [AResultado.IdAtributo]);
  else
    Result := '';
  end;
end;

end.
