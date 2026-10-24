{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResumenSeleccionesHoja                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Escribe el resumen de selecciones de un listado en una hoja de cálculo,   }
{    una línea por fila bajo el título, antes de los datos. Así las            }
{    fórmulas y las imágenes del exportador se calculan ya desplazadas.        }
{******************************************************************************}
unit inLibResumenSeleccionesHoja;

interface

uses
  inLibHojaCalculoIntf;

// Escribe ALineas desde AFila en AColumna (la del título de la hoja; la
// primera línea en negrita) y deja una fila en blanco detrás. Devuelve
// la fila donde sigue el exportador; sin líneas, AFila sin cambios.
function EscribirResumenSeleccionesHoja(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  AFila, AColumna: Integer;
  const ALineas: TArray<string>): Integer;

implementation

const
  TAMANO_FUENTE_RESUMEN = 9;

function EscribirResumenSeleccionesHoja(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  AFila, AColumna: Integer;
  const ALineas: TArray<string>): Integer;
var
  i: Integer;
begin
  Result := AFila;
  for i := 0 to High(ALineas) do
  begin
    AEscritor.Escribir(Result, AColumna, ALineas[i]);
    AFormateador.TamanoFuente(Result, AColumna, TAMANO_FUENTE_RESUMEN);
    AFormateador.Negrita(Result, AColumna, i = 0);
    Inc(Result);
  end;
  if Length(ALineas) > 0 then
    Inc(Result);
end;

end.
