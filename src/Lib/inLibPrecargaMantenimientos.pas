{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPrecargaMantenimientos                                   }
{    Tipo:       Libreria de dominio                                           }
{ Version:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Criterio comun de precarga inicial y reconocimiento de periodos anuales.  }
{******************************************************************************}
unit inLibPrecargaMantenimientos;

interface

uses
  inLibVentanaEmbebidaIntf;

const
  UMBRAL_PRECARGA_MANTENIMIENTOS = 50000;

function DebeComprobarPrecargaInicial(
  ARol: TRolAperturaMantenimiento;
  APreparada: Boolean): Boolean;
function SuperaUmbralPrecarga(ARegistros: Integer): Boolean;
// Componentes numericos completos: 2026.A1 y A1.2026. No interpreta
// digitos dentro de codigos ni elige entre dos anos diferentes.
function AnyoEnSerie(const ASerie: string): Integer;
// Ausencia y "todas" no son equivalentes: [] es una eleccion establecida.
function LeerSeleccionPrecarga(const ATexto: string;
  out ASeleccion: TArray<string>): Boolean;
function SerializarSeleccionPrecarga(
  const ASeleccion: TArray<string>): string;

implementation

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  inLibMsgCompras;

function DebeComprobarPrecargaInicial(
  ARol: TRolAperturaMantenimiento;
  APreparada: Boolean): Boolean;
begin
  Result := (ARol = ramPrimeraLista) and not APreparada;
end;

function SuperaUmbralPrecarga(ARegistros: Integer): Boolean;
begin
  Result := ARegistros > UMBRAL_PRECARGA_MANTENIMIENTOS;
end;

function EsComponenteAnual(const AParte: string): Boolean;
var
  c: Char;
begin
  Result := Length(AParte) = 4;
  for c in AParte do
    Result := Result and CharInSet(c, ['0'..'9']);
end;

function AnyoEnSerie(const ASerie: string): Integer;
var
  sParte: string;
  iAnyo: Integer;
  bAmbiguo: Boolean;
begin
  Result := 0;
  bAmbiguo := False;
  for sParte in ASerie.Split(['.', '-', '_', '/', ' ', #9]) do
  begin
    if EsComponenteAnual(sParte) and TryStrToInt(sParte, iAnyo) and
       (iAnyo >= 1900) and (iAnyo <= 2199) then
    begin
      if (Result <> 0) and (Result <> iAnyo) then
        bAmbiguo := True;
      Result := iAnyo;
    end;
  end;
  if bAmbiguo then
    Result := 0;
end;

function LeerSeleccionPrecarga(const ATexto: string;
  out ASeleccion: TArray<string>): Boolean;
var
  oValor: TJSONValue;
  oLista: TJSONArray;
  i: Integer;
begin
  ASeleccion := nil;
  Result := Trim(ATexto) <> '';
  if Result then
  begin
    oValor := TJSONObject.ParseJSONValue(ATexto);
    try
      if not (oValor is TJSONArray) then
        raise EConvertError.Create(SErrorPreferenciaPrecargaNoValida);
      oLista := TJSONArray(oValor);
      SetLength(ASeleccion, oLista.Count);
      for i := 0 to oLista.Count - 1 do
      begin
        if not (oLista.Items[i] is TJSONString) then
          raise EConvertError.Create(SErrorPreferenciaPrecargaNoValida);
        ASeleccion[i] := oLista.Items[i].Value;
      end;
    finally
      FreeAndNil(oValor);
    end;
  end;
end;

function SerializarSeleccionPrecarga(
  const ASeleccion: TArray<string>): string;
var
  oLista: TJSONArray;
  sValor: string;
begin
  oLista := TJSONArray.Create;
  try
    for sValor in ASeleccion do
      oLista.Add(sValor);
    Result := oLista.ToJSON;
  finally
    FreeAndNil(oLista);
  end;
end;

end.
