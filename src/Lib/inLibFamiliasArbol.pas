{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFamiliasArbol                                            }
{    Tipo:       Modelo                                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  Descripción:                                                                }
{    Familias de artículo como jerarquía padre→subfamilias y utilidades        }
{    para llevar la selección como lista CSV de códigos.                       }
{******************************************************************************}
unit inLibFamiliasArbol;

interface

type
  // Familia de artículo dentro de la jerarquía. CodigoPadre vacío (o no
  // presente en la lista) deja la familia colgando de la raíz.
  TFamiliaArbol = record
    Codigo: string;
    Nombre: string;
    CodigoPadre: string;
  end;

  TFamiliasArbol = TArray<TFamiliaArbol>;

// Trocea la lista CSV de códigos de familia; ignora huecos y espacios.
function CodigosFamiliaDesdeCsv(const ACsv: string): TArray<string>;
// Une los códigos en una lista CSV conservando el orden recibido.
function CsvDesdeCodigosFamilia(const ACodigos: TArray<string>): string;
// Cuántos códigos trae la lista CSV (0 = sin filtro, o sea todas).
function ContarCodigosFamilia(const ACsv: string): Integer;

implementation

uses
  System.SysUtils, System.StrUtils;

function CodigosFamiliaDesdeCsv(const ACsv: string): TArray<string>;
var
  iTotal: Integer;
  sCodigo: string;
  sTrozo: string;
begin
  SetLength(Result, 0);
  iTotal := 0;
  for sTrozo in SplitString(ACsv, ',') do
  begin
    sCodigo := Trim(sTrozo);
    if sCodigo <> '' then
    begin
      SetLength(Result, iTotal + 1);
      Result[iTotal] := sCodigo;
      Inc(iTotal);
    end;
  end;
end;

function CsvDesdeCodigosFamilia(const ACodigos: TArray<string>): string;
var
  sCodigo: string;
begin
  Result := '';
  for sCodigo in ACodigos do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + sCodigo;
  end;
end;

function ContarCodigosFamilia(const ACsv: string): Integer;
begin
  Result := Length(CodigosFamiliaDesdeCsv(ACsv));
end;

end.
