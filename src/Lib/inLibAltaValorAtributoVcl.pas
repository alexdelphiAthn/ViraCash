{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAltaValorAtributoVcl                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Diálogos para dar de alta un valor de atributo (color, talla...) que no   }
{    está en el catálogo: pide su orden en una ventana compacta y confirma el  }
{    alta avisando de que ese orden será global.                               }
{******************************************************************************}
unit inLibAltaValorAtributoVcl;

interface

// Pide el orden del valor AValor, que no está en el catálogo, y confirma
// darlo de alta. False si se cancela cualquiera de los dos pasos: entonces
// no hay que crear nada y AOrden no tiene significado.
function PedirAltaValorAtributo(const AValor: string;
  AOrdenSugerido: Integer; out AOrden: Integer): Boolean;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs,
  inLibMensajesVcl, inLibMsgArticulos;

function EsOrdenValorValido(const AValores: array of string): Boolean;
begin
  // Se valida sin cerrar el diálogo: lo tecleado no se pierde.
  Result := StrToIntDef(Trim(AValores[0]), -1) >= 0;
  if not Result then
    ShowMessage_fza(SErrorOrdenValorSkuNoValido);
end;

function PedirOrdenValor(const AValor: string; AOrdenSugerido: Integer;
  out AOrden: Integer): Boolean;
var
  aValores: TArray<string>;
begin
  AOrden := AOrdenSugerido;
  aValores := [IntToStr(AOrdenSugerido)];
  // Pregunta corta a propósito: InputQuery ensancha la ventana hasta casi
  // el doble de su pregunta más larga. El aviso va en la confirmación.
  Result := InputQuery_fza(
    Format(STituloNuevoValorAtributo, [AValor]),
    [SEtiquetaOrdenValorSku],
    aValores,
    EsOrdenValorValido);
  if Result then
    AOrden := StrToInt(Trim(aValores[0]));
end;

function ConfirmarOrdenGlobal(const AValor: string;
  AOrden: Integer): Boolean;
begin
  Result := MessageDlg_fza(
    Format(SNotaOrdenGlobalValorSku, [AOrden]) + sLineBreak + sLineBreak +
    Format(SPreguntaAltaValorAtributo, [AValor]),
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes;
end;

function PedirAltaValorAtributo(const AValor: string;
  AOrdenSugerido: Integer; out AOrden: Integer): Boolean;
begin
  Result := PedirOrdenValor(AValor, AOrdenSugerido, AOrden) and
    ConfirmarOrdenGlobal(AValor, AOrden);
end;

end.
