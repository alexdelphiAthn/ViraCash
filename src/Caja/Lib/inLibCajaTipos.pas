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
