{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTipoCantidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       15/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Única regla para decidir si el tipo de cantidad de una línea aporta       }
{    información. Cuando son unidades sueltas no aporta nada y se oculta;      }
{    kilos, sacos, packs o cualquier otra unidad sí se muestran.               }
{                                                                              }
{    La usan la columna de las rejillas de documentos y el pivote de           }
{    ventas, que antes llevaban cada uno su copia de la misma lista.           }
{                                                                              }
{    El valor lo teclea quien da de alta el artículo, así que se compara       }
{    normalizado: sin espacios ni puntos finales y sin distinguir             }
{    mayúsculas. Así 'Uds.', 'uds' y 'UDS' cuentan como lo mismo.              }
{******************************************************************************}
unit inLibTipoCantidad;

interface

uses Data.DB;

// Quita espacios y puntos finales: 'Uds.' y 'Uds' son el mismo valor.
function NormalizarTipoCantidad(const AValor: string): string;
// True si es la cantidad corriente en unidades, que no merece mostrarse.
function EsTipoCantidadPredeterminado(const AValor: string): Boolean;
// Cantidad ya formateada seguida de su tipo si no es el corriente:
// '2,35' + 'm' = '2,35 m'; '3' + 'Uds.' = '3'.
function CantidadConTipo(const ACantidad, ATipo: string): string;

// Agrupa cantidades compatibles sin sumar unidades con masa o volumen.
function ResumenCantidadesPorTipo(ALineas: TDataSet;
  const ACampoCantidad, ACampoTipo: string): string;

implementation

uses
  System.SysUtils, System.Generics.Collections;

function ResumenCantidadesPorTipo(ALineas: TDataSet;
  const ACampoCantidad, ACampoTipo: string): string;
var
  Cantidades: TDictionary<string, Double>;
  Marca: TBookmark;
  Tipo: string;
  Cantidad: Double;
begin
  Result := '';
  Cantidades := TDictionary<string, Double>.Create;
  Marca := ALineas.Bookmark;
  ALineas.DisableControls;
  try
    ALineas.First;
    while not ALineas.Eof do
    begin
      Tipo := '';
      if ALineas.FindField(ACampoTipo) <> nil then
        Tipo := LowerCase(NormalizarTipoCantidad(
          ALineas.FieldByName(ACampoTipo).AsString));
      if EsTipoCantidadPredeterminado(Tipo) then
        Tipo := 'uds';
      if not Cantidades.TryGetValue(Tipo, Cantidad) then
        Cantidad := 0;
      Cantidades.AddOrSetValue(Tipo, Cantidad +
        ALineas.FieldByName(ACampoCantidad).AsFloat);
      ALineas.Next;
    end;
    for Tipo in Cantidades.Keys do
    begin
      if Result <> '' then
        Result := Result + ' + ';
      Result := Result + FormatFloat('0.###', Cantidades[Tipo]) +
        ' ' + Tipo;
    end;
  finally
    if ALineas.BookmarkValid(Marca) then
      ALineas.Bookmark := Marca;
    ALineas.EnableControls;
    Cantidades.Free;
  end;
end;

const
  // Formas con las que se escribe "unidades" en la ficha del artículo.
  // Se comparan ya normalizadas y sin distinguir mayúsculas.
  TIPOS_CANTIDAD_CORRIENTES: array[0..7] of string = (
    'U',
    'UD',
    'UDS',
    'UNI',
    'UNID',
    'UNIDAD',
    'UNIDADES',
    'CANTIDAD');

function NormalizarTipoCantidad(const AValor: string): string;
var
  iFin: Integer;
begin
  Result := Trim(AValor);
  iFin := Length(Result);
  while (iFin > 0) and
        CharInSet(Result[iFin], ['.', ' ']) do
    Dec(iFin);
  SetLength(Result, iFin);
end;

function EsTipoCantidadPredeterminado(const AValor: string): Boolean;
var
  i: Integer;
  sValor: string;
begin
  sValor := NormalizarTipoCantidad(AValor);
  Result := sValor = '';
  for i := Low(TIPOS_CANTIDAD_CORRIENTES) to
           High(TIPOS_CANTIDAD_CORRIENTES) do
  begin
    if SameText(sValor, TIPOS_CANTIDAD_CORRIENTES[i]) then
      Result := True;
  end;
end;

function CantidadConTipo(const ACantidad, ATipo: string): string;
begin
  if EsTipoCantidadPredeterminado(ATipo) then
    Result := ACantidad
  else
    Result := ACantidad + ' ' + NormalizarTipoCantidad(ATipo);
end;

end.
