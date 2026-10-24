{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionVersion                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compara versiones de la aplicación como 1.0.15.202606260100.alpha.        }
{******************************************************************************}
unit inLibActualizacionVersion;

interface

type
  // Qué toca hacer tras preguntarle al servicio por la última versión.
  TCaminoComprobacionActualizacion = (
    // El servicio todavía no ha publicado nada.
    ccaSinVersiones,
    // Lo publicado es más nuevo: se instala.
    ccaInstalarVersion,
    // No hay nada que instalar (la misma versión, o la de aquí va por
    // delante): queda mirar si la base de datos tiene todos los scripts.
    ccaSoloScripts);

// Devuelve -1, 0 o 1. Los tramos numéricos se comparan como números; un
// tramo de texto (alpha, beta) marca preestreno y queda por debajo de la
// misma versión sin él. Replica el comparador del webservice.
function CompararVersionesAplicacion(
  const AIzquierda, ADerecha: string): Integer;
function VersionAplicacionEsMayor(
  const ACandidata, AReferencia: string): Boolean;
function VersionAplicacionValida(const AVersion: string): Boolean;
// Decide con qué sigue la comprobación de actualizaciones. Sin versión
// nueva que instalar no se acaba aquí: los scripts de esquema pueden
// faltar igualmente, y así se pueden aplicar sin esperar a otra versión.
function CaminoComprobacionActualizacion(
  AHayVersion: Boolean;
  const AVersionPublicada, AVersionInstalada: string):
  TCaminoComprobacionActualizacion;

implementation

uses
  System.Character,
  System.SysUtils;

function TramoEsNumerico(const ATramo: string): Boolean;
var
  iIndice: Integer;
begin
  Result := ATramo <> '';
  for iIndice := Low(ATramo) to High(ATramo) do
  begin
    if Result and not ATramo[iIndice].IsDigit then
      Result := False;
  end;
end;

function TramoComoNumero(const ATramo: string): UInt64;
var
  iIndice: Integer;
begin
  // Los tramos de fecha ocupan doce cifras: no caben en un entero de 32.
  Result := 0;
  for iIndice := Low(ATramo) to High(ATramo) do
  begin
    if Result > (High(UInt64) - 9) div 10 then
      Result := High(UInt64)
    else
      Result := Result * 10 + UInt64(Ord(ATramo[iIndice]) - Ord('0'));
  end;
end;

function CompararTramos(const AIzquierda, ADerecha: string): Integer;
var
  bDerechaNumerica: Boolean;
  bIzquierdaNumerica: Boolean;
  iDerecha: UInt64;
  iIzquierda: UInt64;
begin
  bIzquierdaNumerica := TramoEsNumerico(AIzquierda);
  bDerechaNumerica := TramoEsNumerico(ADerecha);
  if bIzquierdaNumerica and bDerechaNumerica then
  begin
    iIzquierda := TramoComoNumero(AIzquierda);
    iDerecha := TramoComoNumero(ADerecha);
    if iIzquierda < iDerecha then
      Result := -1
    else if iIzquierda > iDerecha then
      Result := 1
    else
      Result := 0;
  end
  else if bIzquierdaNumerica <> bDerechaNumerica then
  begin
    if bIzquierdaNumerica then
      Result := 1
    else
      Result := -1;
  end
  else
    Result := CompareStr(AIzquierda, ADerecha);
  if Result < 0 then
    Result := -1
  else if Result > 0 then
    Result := 1;
end;

function CompararTramoAusente(const APresente: string): Integer;
begin
  // Falta un tramo a un lado: 1.0 es menor que 1.0.1 pero mayor que
  // 1.0.alpha, porque el tramo de texto es un preestreno.
  if TramoEsNumerico(APresente) then
    Result := -1
  else
    Result := 1;
end;

function CompararVersionesAplicacion(
  const AIzquierda, ADerecha: string): Integer;
var
  aTramosDer: TArray<string>;
  aTramosIzq: TArray<string>;
  iIndice: Integer;
  iTotal: Integer;
begin
  // Delphi no distingue mayúsculas: los locales no pueden llamarse como
  // los parámetros AIzquierda y ADerecha.
  aTramosIzq := LowerCase(Trim(AIzquierda)).Split(['.']);
  aTramosDer := LowerCase(Trim(ADerecha)).Split(['.']);
  iTotal := Length(aTramosIzq);
  if Length(aTramosDer) > iTotal then
    iTotal := Length(aTramosDer);
  Result := 0;
  iIndice := 0;
  while (Result = 0) and (iIndice < iTotal) do
  begin
    if iIndice >= Length(aTramosIzq) then
      Result := CompararTramoAusente(aTramosDer[iIndice])
    else if iIndice >= Length(aTramosDer) then
      Result := -CompararTramoAusente(aTramosIzq[iIndice])
    else
      Result := CompararTramos(aTramosIzq[iIndice], aTramosDer[iIndice]);
    Inc(iIndice);
  end;
end;

function VersionAplicacionEsMayor(
  const ACandidata, AReferencia: string): Boolean;
begin
  Result := (Trim(ACandidata) <> '') and
    ((Trim(AReferencia) = '') or
     (CompararVersionesAplicacion(ACandidata, AReferencia) > 0));
end;

function CaminoComprobacionActualizacion(
  AHayVersion: Boolean;
  const AVersionPublicada, AVersionInstalada: string):
  TCaminoComprobacionActualizacion;
begin
  if not AHayVersion or (Trim(AVersionPublicada) = '') then
    Result := ccaSinVersiones
  else if VersionAplicacionEsMayor(AVersionPublicada, AVersionInstalada) then
    Result := ccaInstalarVersion
  else
    Result := ccaSoloScripts;
end;

function VersionAplicacionValida(const AVersion: string): Boolean;
var
  cCaracter: Char;
  sVersion: string;
begin
  sVersion := Trim(AVersion);
  Result := (sVersion <> '') and
    (Length(sVersion) <= 60) and
    (Pos('..', sVersion) = 0) and
    sVersion[Low(sVersion)].IsLetterOrDigit;
  for cCaracter in sVersion do
  begin
    if Result and not (cCaracter.IsLetterOrDigit or
       (cCaracter = '.') or (cCaracter = '_') or (cCaracter = '-')) then
      Result := False;
  end;
end;

end.
