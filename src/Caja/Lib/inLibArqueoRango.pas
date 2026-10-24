{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoRango                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Dominio puro del rango de fechas del arqueo de caja (FZ-ISSUE-408). Los   }
{    cierres se hacen por turno: el rango propuesto empieza donde terminó el   }
{    último cierre del día, y quien no puede cambiar la fecha de caja sí       }
{    puede cambiar la hora, pero no el día.                                    }
{******************************************************************************}
unit inLibArqueoRango;

interface

// «Desde» que se propone al abrir el arqueo: el segundo siguiente al
// último cierre si queda dentro del rango; si no, el «desde» recibido.
function DesdePropuestoArqueo(ADesde, AHasta: TDateTime;
  AHayCierre: Boolean; AUltimoCierre: TDateTime): TDateTime;
// El día fijado con la hora del valor tecleado.
function FijarDiaArqueo(ADiaFijo, AValor: TDateTime): TDateTime;
// El valor tecleado se sale del día fijado.
function CambiaDiaArqueo(ADiaFijo, AValor: TDateTime): Boolean;

implementation

uses
  System.DateUtils;

function DesdePropuestoArqueo(ADesde, AHasta: TDateTime;
  AHayCierre: Boolean; AUltimoCierre: TDateTime): TDateTime;
var
  dSiguiente: TDateTime;
begin
  Result := ADesde;
  if AHayCierre then
  begin
    dSiguiente := IncSecond(AUltimoCierre);
    if (CompareDateTime(dSiguiente, ADesde) > 0) and
       (CompareDateTime(dSiguiente, AHasta) < 0) then
      Result := dSiguiente;
  end;
end;

function FijarDiaArqueo(ADiaFijo, AValor: TDateTime): TDateTime;
begin
  Result := DateOf(ADiaFijo) + TimeOf(AValor);
end;

function CambiaDiaArqueo(ADiaFijo, AValor: TDateTime): Boolean;
begin
  Result := not SameDate(ADiaFijo, AValor);
end;

end.
