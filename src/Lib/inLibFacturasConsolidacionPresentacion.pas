{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasConsolidacionPresentacion                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara la presentación de la validación previa a consolidar facturas.    }
{******************************************************************************}
unit inLibFacturasConsolidacionPresentacion;

interface

uses
  inLibFacturasServiciosIntf;

type
  TPreparacionConsolidacionFactura = record
    EsValida: Boolean;
    MensajeError: string;
    PreguntaConfirmacion: string;
  end;

function PrepararConsolidacionFactura(
  const AValidacion: TResultadoOperacionFactura;
  const ASerie, ANumero: string
): TPreparacionConsolidacionFactura;

implementation

uses
  inLibFormatoDocumento,
  System.SysUtils, inLibMsgFacturas;

function PrepararConsolidacionFactura(
  const AValidacion: TResultadoOperacionFactura;
  const ASerie, ANumero: string
): TPreparacionConsolidacionFactura;
begin
  Result := Default(TPreparacionConsolidacionFactura);
  if not AValidacion.Exito then
  begin
    Result.MensajeError := AValidacion.Mensaje;
  end
  else
  begin
    Result.EsValida := True;
    Result.PreguntaConfirmacion := FormatearMensajeDocumentos(
      AValidacion.FormatoDocumento,
      SPreguntaLanzarBorradorFiscal,
      [ASerie, ANumero]);
  end;
end;

end.
