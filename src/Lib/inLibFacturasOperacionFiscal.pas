{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasOperacionFiscal                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara operaciones fiscales y construye su solicitud de emisión.         }
{******************************************************************************}
unit inLibFacturasOperacionFiscal;

interface

uses
  inLibEmisionFiscalIntf;

type
  TContextoOperacionFiscalFactura = record
    FormatoDocumento: string;
    Serie: string;
    Numero: string;
    TipoFactura: string;
    TipoOperacion: string;
    Accion: string;
    Usuario: string;
    Consolidada: Boolean;
    Fase: string;
  end;
  TPreparacionOperacionFiscalFactura = record
    EsValida: Boolean;
    MensajeError: string;
    PreguntaConfirmacion: string;
  end;

function PrepararOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura
): TPreparacionOperacionFiscalFactura;
function CrearSolicitudOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura
): TSolicitudEmisionFiscal;

implementation

uses
  inLibFormatoDocumento,
  System.SysUtils, inLibMsgFacturas;

function PrepararOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura
): TPreparacionOperacionFiscalFactura;
begin
  Result := Default(TPreparacionOperacionFiscalFactura);
  if Trim(AContexto.Numero) = '' then
  begin
    Result.MensajeError := SErrorBorradorListaNoSeleccionado;
  end
  else if not AContexto.Consolidada then
  begin
    Result.MensajeError := FormatearMensajeDocumentos(
      AContexto.FormatoDocumento,
      SErrorBorradorNoCerradoAccionFiscal,
      [AContexto.Serie,
      AContexto.Numero,
      LowerCase(AContexto.Accion)]);
  end
  else if SameText(Trim(AContexto.Fase), 'SUBSANACION') then
  begin
    // La subsanación en curso se registra o cancela antes de anular o
    // rectificar: el registro fiscal no cambia dos veces a la vez.
    Result.MensajeError := FormatearMensajeDocumentos(
      AContexto.FormatoDocumento,
      SErrorAccionFiscalEnSubsanacion,
      [AContexto.Serie,
      AContexto.Numero,
      LowerCase(AContexto.Accion)]);
  end
  else
  begin
    Result.EsValida := True;
    Result.PreguntaConfirmacion := FormatearMensajeDocumentos(
      AContexto.FormatoDocumento,
      SPreguntaAccionFiscalBorrador,
      [AContexto.Accion,
      AContexto.Serie,
      AContexto.Numero]);
  end;
end;

function CrearSolicitudOperacionFiscalFactura(
  const AContexto: TContextoOperacionFiscalFactura
): TSolicitudEmisionFiscal;
begin
  Result := TSolicitudEmisionFiscal.ParaOperacion(
    AContexto.Serie,
    AContexto.Numero,
    AContexto.Usuario,
    AContexto.TipoOperacion,
    AContexto.Accion,
    SameText(AContexto.TipoOperacion, 'ANULACION'));
end;

end.
