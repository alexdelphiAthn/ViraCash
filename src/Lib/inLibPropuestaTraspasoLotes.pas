{******************************************************************************}
{  Módulo:       inLibPropuestaTraspasoLotes                                   }
{    Tipo:       Librería                                                      }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Lotes y series de una línea de propuesta de traspaso al        }
{               confirmarla sin pantalla (FZ-ISSUE-323): salen del origen por  }
{               FEFO, como en una salida, y si no alcanza no se confirma.      }
{******************************************************************************}
unit inLibPropuestaTraspasoLotes;

interface

uses
  inLibTrazabilidad;

type
  TRepartoLotesPropuesta = record
    Correcto: Boolean;
    // Una por lote o por número de serie; sin trazabilidad, una sin lote.
    Asignaciones: TArray<TAsignacionLote>;
    // Unidades sin lote o serie con existencias en el origen.
    CantidadPendiente: Double;
    // Primer lote caducado que tocaría la salida (no se envía caducado).
    LoteCaducado: string;
  end;

function RepartirPropuestaPorLotes(AModo: TModoTrazabilidad;
  const ALotes: TLotesDisponibles; ACantidad: Double;
  AHoy: TDate): TRepartoLotesPropuesta;

implementation

uses
  System.SysUtils;

// La fila sin lote (stock de antes de activar los lotes) no es un lote
// identificado: SeleccionarFefo la ofrece para que el usuario la elija a
// mano, pero el reparto automático no debe tomarla. Si no, la línea salía
// con lote vacío y sin aviso (revalidación de FZ-ISSUE-336).
function LotesIdentificados(
  const ALotes: TLotesDisponibles): TLotesDisponibles;
var
  rLote: TLoteDisponible;
begin
  Result := [];
  for rLote in ALotes do
    if Trim(rLote.Lote) <> '' then
      Result := Result + [rLote];
end;

function RepartirPropuestaPorLotes(AModo: TModoTrazabilidad;
  const ALotes: TLotesDisponibles; ACantidad: Double;
  AHoy: TDate): TRepartoLotesPropuesta;
var
  rAsignacion: TAsignacionLote;
  rSeleccion: TSeleccionLotes;
begin
  Result := Default(TRepartoLotesPropuesta);
  if not RequiereLote(AModo) then
  begin
    rAsignacion := Default(TAsignacionLote);
    rAsignacion.Cantidad := ACantidad;
    Result.Asignaciones := [rAsignacion];
    Result.Correcto := True;
  end
  else
  begin
    rSeleccion := SeleccionarFefo(AModo, LotesIdentificados(ALotes),
      ACantidad, AHoy);
    Result.Asignaciones := rSeleccion.Asignaciones;
    Result.CantidadPendiente := rSeleccion.CantidadPendiente;
    for rAsignacion in rSeleccion.Asignaciones do
      if rAsignacion.EsCaducado and (Result.LoteCaducado = '') then
        Result.LoteCaducado := rAsignacion.Lote;
    Result.Correcto := rSeleccion.EsCompleta and
                       (Result.LoteCaducado = '');
  end;
end;

end.
