{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSelectorAtributoLinea                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decide qué hacer al pedir los valores de un atributo en una línea de      }
{    documento, inventario o TPV (FZ-ISSUE-260): abrir el selector, avisar     }
{    de que el atributo no tiene valores o no hacer nada porque el artículo    }
{    no lleva ese atributo. Sin VCL ni base de datos.                          }
{******************************************************************************}
unit inLibSelectorAtributoLinea;

interface

type
  TAccesoSelectorAtributo = (
    // Hay valores: se abre el selector.
    asaAbrir,
    // El artículo de la línea no lleva atributos (o no hay artículo).
    asaSinAtributos,
    // El artículo lleva menos atributos que el orden de la columna.
    asaNoAplica,
    // El atributo aplica al artículo pero no tiene valores: se avisa.
    asaSinValores);

// Los valores mandan: si los hay se abre siempre, aunque el número de
// atributos de la línea aún no se haya calculado.
function AccesoSelectorAtributo(
  ANumAtributos, AOrden, ANumValores: Integer): TAccesoSelectorAtributo;

// Solo asaSinValores merece un aviso; el resto se ignora en silencio.
function AvisarAtributoSinValores(
  AAcceso: TAccesoSelectorAtributo): Boolean;

// Aviso con el artículo y el atributo; sin nombre de atributo, el genérico.
function MensajeAtributoSinValores(
  const AArticulo, ANombreAtributo: string): string;

implementation

uses
  System.SysUtils,
  inLibMsgArticulos;

function AccesoSelectorAtributo(
  ANumAtributos, AOrden, ANumValores: Integer): TAccesoSelectorAtributo;
begin
  if ANumValores > 0 then
    Result := asaAbrir
  else if ANumAtributos <= 0 then
    Result := asaSinAtributos
  else if AOrden > ANumAtributos then
    Result := asaNoAplica
  else
    Result := asaSinValores;
end;

function AvisarAtributoSinValores(
  AAcceso: TAccesoSelectorAtributo): Boolean;
begin
  Result := AAcceso = asaSinValores;
end;

function MensajeAtributoSinValores(
  const AArticulo, ANombreAtributo: string): string;
begin
  if (Trim(AArticulo) = '') or (Trim(ANombreAtributo) = '') then
    Result := SErrorValoresAtributoNoDefinidos
  else
    Result := Format(SErrorValoresAtributoArticuloNoDefinidos,
      [Trim(AArticulo), Trim(ANombreAtributo)]);
end;

end.
