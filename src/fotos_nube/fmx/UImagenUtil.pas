{******************************************************************************}
{                                                                              }
{  Módulo:       UImagenUtil                                                   }
{    Tipo:       Librería (FMX, multiplataforma)                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de imagen para la app de fotos. Reduce el lado mayor de un     }
{    TBitmap a un máximo configurado (por defecto 1000 px) conservando la      }
{    proporción y guarda el resultado en JPG en un fichero temporal listo      }
{    para subir al webservice.                                                 }
{******************************************************************************}
unit UImagenUtil;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.IOUtils,
  FMX.Graphics;

// Devuelve un TBitmap nuevo reducido para que su lado mayor no supere
// AMax píxeles, conservando proporción. Si la imagen ya cabe (o AMax no
// es válido) devuelve una copia sin reescalar. El llamante libera el
// resultado.
function RedimensionarMax(const AOrigen: TBitmap; AMax: Integer): TBitmap;

// Reduce AOrigen al máximo indicado, lo guarda como JPG en una ruta
// temporal única y devuelve dicha ruta.
function GuardarJpgReducido(const AOrigen: TBitmap; AMax: Integer): string;

implementation

function RedimensionarMax(const AOrigen: TBitmap; AMax: Integer): TBitmap;
var
  Escala: Single;
  NuevoAncho: Integer;
  NuevoAlto: Integer;
begin
  // Sin reescalado: copia tal cual.
  if (AMax <= 0) or
     ((AOrigen.Width <= AMax) and (AOrigen.Height <= AMax)) then
  begin
    Result := TBitmap.Create;
    Result.Assign(AOrigen);
  end
  else
  begin
    // Escalamos respecto del lado mayor para respetar el tope.
    if AOrigen.Width >= AOrigen.Height then
      Escala := AMax / AOrigen.Width
    else
      Escala := AMax / AOrigen.Height;
    NuevoAncho := Round(AOrigen.Width * Escala);
    NuevoAlto := Round(AOrigen.Height * Escala);
    if NuevoAncho < 1 then
      NuevoAncho := 1;
    if NuevoAlto < 1 then
      NuevoAlto := 1;
    Result := TBitmap.Create(NuevoAncho, NuevoAlto);
    Result.Canvas.BeginScene;
    try
      Result.Canvas.DrawBitmap(AOrigen,
        RectF(0, 0, AOrigen.Width, AOrigen.Height),
        RectF(0, 0, NuevoAncho, NuevoAlto), 1, True);
    finally
      Result.Canvas.EndScene;
    end;
  end;
end;

function GuardarJpgReducido(const AOrigen: TBitmap; AMax: Integer): string;
var
  Reducida: TBitmap;
  Nombre: string;
begin
  Reducida := RedimensionarMax(AOrigen, AMax);
  try
    // Nombre único por marca de tiempo (incluye milisegundos).
    Nombre := 'foto_' + FormatDateTime('yyyymmdd_hhnnsszzz', Now) + '.jpg';
    Result := TPath.Combine(TPath.GetTempPath, Nombre);
    // La extensión .jpg selecciona el códec JPEG en FMX.
    Reducida.SaveToFile(Result);
  finally
    Reducida.Free;
  end;
end;

end.
