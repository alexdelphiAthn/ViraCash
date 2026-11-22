{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaTipos                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tipos compartidos del dominio de caja sin dependencias de UI ni datos.    }
{******************************************************************************}
unit inLibCajaTipos;

interface

const
  // FZ-ISSUE-1130: motivo de devolución del par dañado (lista fija de
  // inMtoModalMotivoDevolucion). Sus unidades no vuelven al stock
  // vendible: entran en el almacén de taras del almacén de la caja.
  MOTIVO_DEVOLUCION_DEFECTUOSO = 'Artículo defectuoso';

type
  TTipoRectificativaCaja = (
    trcNinguna,
    trcDiferencias,
    trcSustitutiva);
  TTratamientoMovimientosRectificativa = (
    tmrMantenerOriginales,
    tmrReemplazarOriginales);
  TTipoImpresionVenta = (
    tiConTicket,
    tiSinTicket,
    tiTicketRegalo,
    tiFactura);

implementation

end.
