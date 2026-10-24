{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionPrecedencia                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ordena los scripts que faltan respetando su precedencia: ninguno se       }
{    aplica antes que los que declara en «-- @requiere:».                      }
{******************************************************************************}
unit inLibActualizacionPrecedencia;

interface

uses
  inLibActualizacionIntf,
  inLibActualizacionScriptsLectura;

// Ningún script queda delante de un requisito que también falte; los que ya
// están aplicados no cuentan. Entre los que se pueden aplicar, primero el
// de menor orden_aplicacion y, a igualdad, por nombre (el criterio de
// siempre). Un ciclo no debería llegar (el Publicador y el servicio lo
// rechazan); si llegara, lo que quede va al final en su orden de siempre.
function OrdenarScriptsPorPrecedencia(
  const AFaltantes: TArray<TScriptFaltante>;
  const AManifiesto: TManifiestoActualizacion): TArray<TScriptFaltante>;

implementation

uses
  System.SysUtils;

function RequisitosDe(
  const AManifiesto: TManifiestoActualizacion;
  const ANombre: string): TArray<string>;
var
  Script: TScriptActualizacion;
begin
  Result := nil;
  if AManifiesto.BuscarScript(ANombre, Script) then
    Result := Script.Requiere;
end;

function VaAntes(const AUno, AOtro: TScriptFaltante): Boolean;
begin
  Result := (AUno.Orden < AOtro.Orden) or
    ((AUno.Orden = AOtro.Orden) and (CompareText(AUno.Nombre,
      AOtro.Nombre) < 0));
end;

// Algún requisito de AIndice sigue sin colocar.
function EsperaRequisito(
  const AFaltantes: TArray<TScriptFaltante>;
  const ARequisitos: TArray<TArray<string>>;
  const AColocados: TArray<Boolean>;
  AIndice: Integer): Boolean;
var
  iOtro: Integer;
  sRequisito: string;
begin
  Result := False;
  for sRequisito in ARequisitos[AIndice] do
  begin
    for iOtro := Low(AFaltantes) to High(AFaltantes) do
    begin
      if not AColocados[iOtro] and (iOtro <> AIndice) and
         SameText(AFaltantes[iOtro].Nombre, sRequisito) then
        Result := True;
    end;
  end;
end;

// El siguiente que se puede aplicar, o -1. Con ARespetar a False (ciclo),
// el siguiente en el orden de siempre.
function Siguiente(
  const AFaltantes: TArray<TScriptFaltante>;
  const ARequisitos: TArray<TArray<string>>;
  const AColocados: TArray<Boolean>;
  ARespetar: Boolean): Integer;
var
  iIndice: Integer;
begin
  Result := -1;
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
  begin
    if not AColocados[iIndice] and
       (not ARespetar or
        not EsperaRequisito(AFaltantes, ARequisitos, AColocados, iIndice)) and
       ((Result < 0) or VaAntes(AFaltantes[iIndice], AFaltantes[Result])) then
      Result := iIndice;
  end;
end;

function OrdenarScriptsPorPrecedencia(
  const AFaltantes: TArray<TScriptFaltante>;
  const AManifiesto: TManifiestoActualizacion): TArray<TScriptFaltante>;
var
  aColocados: TArray<Boolean>;
  aRequisitos: TArray<TArray<string>>;
  iElegido: Integer;
  iIndice: Integer;
begin
  Result := nil;
  SetLength(aColocados, Length(AFaltantes));
  SetLength(aRequisitos, Length(AFaltantes));
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
    aRequisitos[iIndice] := RequisitosDe(
      AManifiesto,
      AFaltantes[iIndice].Nombre);
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
  begin
    iElegido := Siguiente(AFaltantes, aRequisitos, aColocados, True);
    if iElegido < 0 then
      iElegido := Siguiente(AFaltantes, aRequisitos, aColocados, False);
    aColocados[iElegido] := True;
    Result := Result + [AFaltantes[iElegido]];
  end;
end;

end.
