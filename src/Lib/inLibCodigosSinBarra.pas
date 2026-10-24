{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCodigosSinBarra                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    La barra '/' es el separador de atributos del SKU (ART/COLOR/TALLA), así  }
{    que no puede formar parte de un código de artículo, de un modelo o        }
{    referencia de proveedor ni de un valor de atributo (color, talla). En     }
{    vez de rechazarla se cambia por guión, igual que hace el migrador         }
{    (CodigoArticuloMigrado). Los datos legacy traían códigos como             }
{    '2354/A-158' y partían el desempaquetado de SKUs en toda la aplicación.   }
{                                                                              }
{******************************************************************************}
unit inLibCodigosSinBarra;

interface

uses
  Data.DB;

// Texto sin espacios laterales y con cada '/' cambiada por '-'.
function SinBarraSku(const ATexto: string): string;

// Aplica SinBarraSku al campo indicado del registro en edición, solo si
// existe y lleva alguna barra (no ensucia el registro si no hace falta).
procedure QuitarBarraSkuCampo(ADataSet: TDataSet; const ANombreCampo: string);

// Variantes con las que buscar un texto tecleado: el texto tal cual y, si
// lleva barra, también con guiones. Así un código legacy '2354/A-158'
// encuentra el artículo migrado '2354-A-158' y un SKU 'ART/ROJO/M' sigue
// buscándose con su separador.
function VariantesBusquedaSinBarra(const ATexto: string): TArray<string>;

implementation

uses
  System.SysUtils;

function SinBarraSku(const ATexto: string): string;
begin
  Result := StringReplace(Trim(ATexto), '/', '-', [rfReplaceAll]);
end;

procedure QuitarBarraSkuCampo(ADataSet: TDataSet; const ANombreCampo: string);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ANombreCampo);
  if (oCampo <> nil) and (Pos('/', oCampo.AsString) > 0) then
    oCampo.AsString := SinBarraSku(oCampo.AsString);
end;

function VariantesBusquedaSinBarra(const ATexto: string): TArray<string>;
var
  sSinBarra: string;
begin
  SetLength(Result, 1);
  Result[0] := ATexto;
  sSinBarra := StringReplace(ATexto, '/', '-', [rfReplaceAll]);
  if sSinBarra <> ATexto then
  begin
    SetLength(Result, 2);
    Result[1] := sSinBarra;
  end;
end;

end.
