{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTotalMaximoLinea                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Total máximo por línea de documento (FZ-ISSUE-255). Decide si el total    }
{    de una línea de venta, compra o TPV necesita confirmación porque ha       }
{    subido por encima del máximo de la empresa. 0 = sin límite.               }
{******************************************************************************}
unit inLibTotalMaximoLinea;

interface

type
  TConfirmacionTotalLinea = reference to function(
    const AMensaje: string): Boolean;

const
  // FZ-ISSUE-255/331: sin máximo de la empresa, el del artículo.
  FACTOR_TOTAL_MAXIMO_AUTOMATICO = 100;

// Máximo de la empresa si lo fija (> 0); si no, la tarifa más alta del
// artículo por FACTOR_TOTAL_MAXIMO_AUTOMATICO; sin tarifa, 0 (sin límite).
function ResolverTotalMaximoLinea(
  AMaximoEmpresa, APrecioTarifaMasAlta: Currency): Currency;
function SuperaTotalMaximoLinea(ATotal, AMaximo: Currency): Boolean;
function HaSubidoTotalLinea(ATotalAnterior, ATotalNuevo: Currency): Boolean;
function DebeConfirmarTotalLinea(
  ATotalAnterior, ATotalNuevo, AMaximo: Currency): Boolean;
function ConfirmarTotalLinea(
  ATotalAnterior, ATotalNuevo, AMaximo: Currency;
  const AConfirmar: TConfirmacionTotalLinea): Boolean;

implementation

uses
  System.SysUtils,
  inLibMsgComun;

const
  MascaraImporteTotalLinea = '#,##0.00';

function ResolverTotalMaximoLinea(
  AMaximoEmpresa, APrecioTarifaMasAlta: Currency): Currency;
begin
  if AMaximoEmpresa > 0 then
    Result := AMaximoEmpresa
  else if APrecioTarifaMasAlta > 0 then
    Result := APrecioTarifaMasAlta * FACTOR_TOTAL_MAXIMO_AUTOMATICO
  else
    Result := 0;
end;

function SuperaTotalMaximoLinea(ATotal, AMaximo: Currency): Boolean;
begin
  Result := (AMaximo > 0) and (Abs(ATotal) > AMaximo);
end;

// Las devoluciones (total negativo) se miden en valor absoluto.
function HaSubidoTotalLinea(ATotalAnterior, ATotalNuevo: Currency): Boolean;
begin
  Result := Abs(ATotalNuevo) > Abs(ATotalAnterior);
end;

// Solo cuando el total sube: una línea ya grabada por encima del máximo no
// vuelve a preguntar al cambiarle la descripción o al aplicarle un
// descuento.
function DebeConfirmarTotalLinea(
  ATotalAnterior, ATotalNuevo, AMaximo: Currency): Boolean;
begin
  Result := SuperaTotalMaximoLinea(ATotalNuevo, AMaximo) and
            HaSubidoTotalLinea(ATotalAnterior, ATotalNuevo);
end;

function ConfirmarTotalLinea(
  ATotalAnterior, ATotalNuevo, AMaximo: Currency;
  const AConfirmar: TConfirmacionTotalLinea): Boolean;
begin
  Result := not DebeConfirmarTotalLinea(ATotalAnterior, ATotalNuevo,
                                        AMaximo);
  if not Result then
  begin
    if not Assigned(AConfirmar) then
      raise Exception.Create(SErrorConfirmacionTotalLineaNoConfigurada);
    Result := AConfirmar(Format(SPreguntaTotalMaximoLinea,
      [FormatFloat(MascaraImporteTotalLinea, ATotalNuevo),
       FormatFloat(MascaraImporteTotalLinea, AMaximo)]));
  end;
end;

end.
