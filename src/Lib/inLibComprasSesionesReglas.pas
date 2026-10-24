{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesReglas                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de compra reutilizables que no dependen de formularios ni del      }
{    módulo de datos de sesiones.                                              }
{******************************************************************************}
unit inLibComprasSesionesReglas;

interface

uses
  inLibComprasSesionesIntf;

function SanearColorSku(const ATexto: string): string;
function ResolverCodigoColorBasico(
  const ALiteral: string;
  const ACodigos, ANombres: array of string;
  out ACodigo: string): Boolean;
// Números que deben recibir las líneas para quedar de 10 en 10 ordenadas
// por artículo, color y línea; las que aún no tienen código van al final.
// Devuelve todas las líneas, o nada si ya están así. AReservados son
// números que no se pueden reutilizar (FZ-ISSUE-416).
function RenumeracionLineasSesion(
  const ALineas: TArray<TLineaOrdenSesion>;
  const AReservados: TArray<Integer>): TCambiosLineaSesion;
function LineaTrasRenumerar(const ACambios: TCambiosLineaSesion;
  ALinea: Integer): Integer;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  inLibGeneracionSkus;

function SanearColorSku(const ATexto: string): string;
begin
  Result := NormalizarValorCodigoSku(ATexto);
end;

function ClaveComparacionColor(const ATexto: string): string;
const
  Acentuadas = 'ÁÀÂÄÃÅÉÈÊËÍÌÎÏÓÒÔÖÕÚÙÛÜÑÇ';
  Simples = 'AAAAAAEEEEIIIIOOOOOUUUUNC';
var
  Caracter, Comparado: Char;
  Posicion: Integer;
begin
  Result := '';
  for Caracter in AnsiUpperCase(Trim(ATexto)) do
  begin
    Comparado := Caracter;
    Posicion := Pos(Caracter, Acentuadas);
    if Posicion > 0 then
      Comparado := Simples[Posicion];
    if CharInSet(Comparado, ['A'..'Z', '0'..'9']) then
      Result := Result + Comparado;
  end;
end;

function ResolverCodigoColorBasico(
  const ALiteral: string;
  const ACodigos, ANombres: array of string;
  out ACodigo: string): Boolean;
var
  i: Integer;
  LiteralNormalizado: string;
begin
  ACodigo := '';
  LiteralNormalizado := ClaveComparacionColor(ALiteral);
  if LiteralNormalizado <> '' then
  begin
    // El código prima sobre el nombre; entre nombres repetidos se
    // propone el código menor, con independencia del orden de carga.
    for i := 0 to High(ACodigos) do
      if (LiteralNormalizado = ClaveComparacionColor(ACodigos[i])) and
         ((ACodigo = '') or (CompareText(ACodigos[i], ACodigo) < 0)) then
        ACodigo := ACodigos[i];
    if ACodigo = '' then
      for i := 0 to High(ACodigos) do
        if (i <= High(ANombres)) and
           (LiteralNormalizado = ClaveComparacionColor(ANombres[i])) and
           ((ACodigo = '') or (CompareText(ACodigos[i], ACodigo) < 0)) then
          ACodigo := ACodigos[i];
  end;
  Result := ACodigo <> '';
end;

function CompararLineasOrdenSesion(
  const AIzquierda, ADerecha: TLineaOrdenSesion): Integer;
var
  bSinIzquierda, bSinDerecha: Boolean;
begin
  bSinIzquierda := Trim(AIzquierda.Articulo) = '';
  bSinDerecha := Trim(ADerecha.Articulo) = '';
  if bSinIzquierda <> bSinDerecha then
    Result := Ord(bSinIzquierda) - Ord(bSinDerecha)
  else
  begin
    Result := CompareText(Trim(AIzquierda.Articulo),
      Trim(ADerecha.Articulo));
    if (Result = 0) and (not bSinIzquierda) then
      Result := CompareText(Trim(AIzquierda.Color), Trim(ADerecha.Color));
    if Result = 0 then
      Result := AIzquierda.Linea - ADerecha.Linea;
  end;
end;

function RenumeracionLineasSesion(
  const ALineas: TArray<TLineaOrdenSesion>;
  const AReservados: TArray<Integer>): TCambiosLineaSesion;
var
  aOrdenadas: TArray<TLineaOrdenSesion>;
  i, iNumero: Integer;
  bCambia: Boolean;
  function ContieneEntero(const AValores: TArray<Integer>; AValor: Integer): Boolean;
  var
    i: Integer;
  begin
    for i := 0 to High(AValores) do
      if AValores[i] = AValor then
        Exit(True);
    Result := False;
  end;
begin
  aOrdenadas := Copy(ALineas);
  TArray.Sort<TLineaOrdenSesion>(aOrdenadas,
    TComparer<TLineaOrdenSesion>.Construct(CompararLineasOrdenSesion));
  SetLength(Result, Length(aOrdenadas));
  bCambia := False;
  iNumero := 0;
  for i := 0 to High(aOrdenadas) do
  begin
    repeat
      Inc(iNumero, 10);
    until not ContieneEntero(AReservados, iNumero);
    Result[i].Antes := aOrdenadas[i].Linea;
    Result[i].Despues := iNumero;
    bCambia := bCambia or (Result[i].Antes <> Result[i].Despues);
  end;
  if not bCambia then
    Result := nil;
end;

function LineaTrasRenumerar(const ACambios: TCambiosLineaSesion;
  ALinea: Integer): Integer;
var
  oCambio: TCambioLineaSesion;
begin
  Result := ALinea;
  for oCambio in ACambios do
  begin
    if oCambio.Antes = ALinea then
      Result := oCambio.Despues;
  end;
end;

end.
