{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRetiradaLotes                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Validación e identidad de órdenes de retirada de lotes.       }
{******************************************************************************}
unit inLibRetiradaLotes;

interface

uses
  inLibRetiradaLotesIntf;

function ValidarOrdenRetirada(const AOrden: TOrdenRetiradaLotes): string;
function MismaSolicitudRetirada(const A, B: TOrdenRetiradaLotes): Boolean;
function TextoMotivoRetirada(AMotivo: TMotivoRetiradaLote): string;
function CrearIdRetirada: string;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  inLibMsgRetiradaLotes;

function CrearIdRetirada: string;
var
  oId: TGUID;
begin
  CreateGUID(oId);
  Result := Copy(GUIDToString(oId), 2, 36);
end;

function TextoMotivoRetirada(AMotivo: TMotivoRetiradaLote): string;
begin
  case AMotivo of
    mrlCaducidad: Result := SMotivoCaducidadRetirada;
    mrlProximaCaducidad: Result := SMotivoProximaCaducidadRetirada;
    mrlAlerta: Result := SMotivoAlertaRetirada;
    mrlMerma: Result := SMotivoMermaRetirada;
  else
    Result := SMotivoOtroRetirada;
  end;
end;


function ValidarLinea(const ALinea: TLineaRetiradaLote): string;
begin
  Result := '';
  if (Trim(ALinea.CodigoSku) = '') or (Trim(ALinea.Lote) = '') or
     (Trim(ALinea.CodigoAlmacen) = '') or IsNan(ALinea.Cantidad) or
     IsInfinite(ALinea.Cantidad) or (ALinea.Cantidad < 0.000001) then
    Result := SErrorRetiradaLinea;
end;

function ValidarOrdenRetirada(const AOrden: TOrdenRetiradaLotes): string;
var
  oClaves: TDictionary<string, Boolean>;
  rLinea: TLineaRetiradaLote;
  sClave: string;
begin
  Result := '';
  if (Trim(AOrden.Empresa) = '') or (Trim(AOrden.Usuario) = '') or
     (Trim(AOrden.Empleado) = '') then
    Result := SErrorRetiradaIdentidad
  else if Length(AOrden.Lineas) = 0 then
    Result := SErrorRetiradaSinLineas;
  oClaves := TDictionary<string, Boolean>.Create;
  try
    for rLinea in AOrden.Lineas do
      if Result = '' then
      begin
        Result := ValidarLinea(rLinea);
        sClave := UpperCase(rLinea.CodigoAlmacen + '|' +
          rLinea.CodigoSku + '|' + rLinea.Lote);
        if oClaves.ContainsKey(sClave) then
          Result := SErrorRetiradaDuplicada
        else
          oClaves.Add(sClave, True);
        if (Trim(AOrden.AlmacenDestino) = '') or
           SameText(AOrden.AlmacenDestino, rLinea.CodigoAlmacen) then
          Result := SErrorRetiradaDestino;
      end;
  finally
    FreeAndNil(oClaves);
  end;
end;

function MismaSolicitudRetirada(const A, B: TOrdenRetiradaLotes): Boolean;
var
  iLinea: Integer;
begin
  Result := SameText(A.Empresa, B.Empresa) and
    SameText(A.Usuario, B.Usuario) and
    SameText(A.Empleado, B.Empleado) and
    (A.Motivo = B.Motivo) and
    (A.EsUrgente = B.EsUrgente) and
    SameText(A.AlmacenDestino, B.AlmacenDestino) and
    (Length(A.Lineas) = Length(B.Lineas));
  if Result then
    for iLinea := 0 to High(A.Lineas) do
      Result := Result and
        SameText(A.Lineas[iLinea].CodigoSku, B.Lineas[iLinea].CodigoSku) and
        SameText(A.Lineas[iLinea].Lote, B.Lineas[iLinea].Lote) and
        SameText(A.Lineas[iLinea].CodigoAlmacen,
          B.Lineas[iLinea].CodigoAlmacen) and
        SameValue(A.Lineas[iLinea].Cantidad, B.Lineas[iLinea].Cantidad,
          0.0000001);
end;

end.
