{******************************************************************************}
{  Módulo:       inLibTicketDesgloseIva                                        }
{    Tipo:       Librería                                                      }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Desglose de IVA del ticket de venta por tipo (normal,          }
{               reducido, superreducido y exento). Los dos generadores de      }
{               ticket solo pintaban el normal y el reducido (FZ-ISSUE-335).   }
{******************************************************************************}
unit inLibTicketDesgloseIva;

interface

uses
  inLibFTicket;

type
  TTipoIvaTicket = (titNormal, titReducido, titSuperreducido, titExento);

  TImportesIvaTicket = record
    Base: Currency;
    Cuota: Currency;
    Porcentaje: Double;
    // FZ-ISSUE-375: recargo de equivalencia del tramo (0 si no hay).
    Recargo: Currency;
    PorcentajeRecargo: Double;
  end;

  TTramoIvaTicket = record
    Tipo: TTipoIvaTicket;
    Importes: TImportesIvaTicket;
  end;

function ImportesIvaTicket(ABase, ACuota: Currency;
  APorcentaje: Double; ARecargo: Currency = 0;
  APorcentajeRecargo: Double = 0): TImportesIvaTicket;

// Tramos con importe, en el orden normal, reducido, superreducido y exento.
// Cuenta la base aunque no haya cuota (exento) y los importes negativos
// (rectificativas).
function TramosIvaTicket(
  const ANormal, AReducido, ASuperreducido,
  AExento: TImportesIvaTicket): TArray<TTramoIvaTicket>;

function EtiquetaBaseTramoIva(ATipo: TTipoIvaTicket): string;

procedure EscribirDesgloseIvaTicket(ATicket: TTicketTermico;
  const ATramos: TArray<TTramoIvaTicket>);

implementation

uses
  System.SysUtils, inLibMsgTickets;

const
  IMPORTE_DESPRECIABLE = 0.001;

function ImportesIvaTicket(ABase, ACuota: Currency;
  APorcentaje: Double; ARecargo: Currency;
  APorcentajeRecargo: Double): TImportesIvaTicket;
begin
  Result.Base := ABase;
  Result.Cuota := ACuota;
  Result.Porcentaje := APorcentaje;
  Result.Recargo := ARecargo;
  Result.PorcentajeRecargo := APorcentajeRecargo;
end;

function TieneImporte(const AImportes: TImportesIvaTicket): Boolean;
begin
  Result := (Abs(AImportes.Base) > IMPORTE_DESPRECIABLE) or
            (Abs(AImportes.Cuota) > IMPORTE_DESPRECIABLE) or
            (Abs(AImportes.Recargo) > IMPORTE_DESPRECIABLE);
end;

function TramosIvaTicket(
  const ANormal, AReducido, ASuperreducido,
  AExento: TImportesIvaTicket): TArray<TTramoIvaTicket>;
var
  aImportes: array[TTipoIvaTicket] of TImportesIvaTicket;
  oTipo: TTipoIvaTicket;
  rTramo: TTramoIvaTicket;
begin
  aImportes[titNormal] := ANormal;
  aImportes[titReducido] := AReducido;
  aImportes[titSuperreducido] := ASuperreducido;
  aImportes[titExento] := AExento;
  Result := [];
  for oTipo := Low(TTipoIvaTicket) to High(TTipoIvaTicket) do
    if TieneImporte(aImportes[oTipo]) then
    begin
      rTramo.Tipo := oTipo;
      rTramo.Importes := aImportes[oTipo];
      Result := Result + [rTramo];
    end;
end;

function EtiquetaBaseTramoIva(ATipo: TTipoIvaTicket): string;
begin
  case ATipo of
    titReducido:
      Result := STicketBaseImponibleReducida;
    titSuperreducido:
      Result := STicketBaseImponibleSuperreducida;
    titExento:
      Result := STicketBaseImponibleExenta;
  else
    Result := STicketBaseImponible;
  end;
end;

function TextoImporte(AImporte: Currency): string;
begin
  Result := FormatFloat('#,##0.00', AImporte) + ' €';
end;

procedure EscribirDesgloseIvaTicket(ATicket: TTicketTermico;
  const ATramos: TArray<TTramoIvaTicket>);
var
  rTramo: TTramoIvaTicket;
begin
  for rTramo in ATramos do
  begin
    ATicket.TextoColumnas(EtiquetaBaseTramoIva(rTramo.Tipo),
      TextoImporte(rTramo.Importes.Base));
    // El exento no lleva cuota: solo su base.
    if (rTramo.Tipo <> titExento) or
       (Abs(rTramo.Importes.Cuota) > IMPORTE_DESPRECIABLE) then
      ATicket.TextoColumnas(
        Format(STicketTotalIvaFormato, [rTramo.Importes.Porcentaje]),
        TextoImporte(rTramo.Importes.Cuota));
    // FZ-ISSUE-375: factura completa a un cliente en recargo.
    if Abs(rTramo.Importes.Recargo) > IMPORTE_DESPRECIABLE then
      ATicket.TextoColumnas(
        Format(STicketTotalRecargoFormato,
          [FormatFloat('0.##', rTramo.Importes.PorcentajeRecargo)]),
        TextoImporte(rTramo.Importes.Recargo));
  end;
end;

end.
