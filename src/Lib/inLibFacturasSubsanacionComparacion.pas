{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasSubsanacionComparacion                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Compara la factura grabada con el último registro de facturación         }
{    aceptado (REGISTRO_XML_FACCON): importe, cuota y destinatario, lo que     }
{    puede cambiar una subsanación. Una subsanación con diferencias no se      }
{    cancela: la factura quedaría en VERIFACTU_OK con datos que no casan con   }
{    su registro (FZ-ISSUE-133). Sin dependencias de datos ni de pantalla.     }
{******************************************************************************}
unit inLibFacturasSubsanacionComparacion;

interface

uses
  inLibFacturasSubsanacionIntf;

// False si no hay registro con importes con el que comparar.
function RegistroComparable(const ADatos: TDatosComparacionSubsanacion):
  Boolean;
// Texto con las diferencias («importe 96,80; registrado 108,90»...);
// vacío si la factura coincide con el registro o no es comparable.
function DiferenciasConRegistro(
  const ADatos: TDatosComparacionSubsanacion): string;

implementation

uses
  System.SysUtils, System.StrUtils,
  inLibMsgFacturas;

const
  cToleranciaImporte = 0.005;

function DesescaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
end;

// Contenido de la primera etiqueta <prefijo:Nombre> o <Nombre>; los
// valores del registro van escapados, así que acaban en el siguiente «<».
function ValorEtiqueta(const AXml, ANombreLocal: string): string;
var
  iInicio: Integer;
  iFin: Integer;
begin
  Result := '';
  iInicio := Pos(':' + ANombreLocal + '>', AXml);
  if iInicio = 0 then
    iInicio := Pos('<' + ANombreLocal + '>', AXml);
  if iInicio > 0 then
  begin
    iInicio := iInicio + Length(ANombreLocal) + 2;
    iFin := PosEx('<', AXml, iInicio);
    if iFin > 0 then
      Result := Trim(DesescaparXml(Copy(AXml, iInicio, iFin - iInicio)));
  end;
end;

// Bloque completo de una etiqueta contenedora (p. ej. Destinatarios).
function BloqueEtiqueta(const AXml, ANombreLocal: string): string;
var
  iInicio: Integer;
  iFin: Integer;
begin
  Result := '';
  iInicio := Pos(':' + ANombreLocal + '>', AXml);
  if iInicio > 0 then
  begin
    iFin := PosEx(':' + ANombreLocal + '>', AXml,
      iInicio + Length(ANombreLocal) + 2);
    if iFin > 0 then
      Result := Copy(AXml, iInicio, iFin - iInicio);
  end;
end;

function ImporteRegistro(const AXml, ANombreLocal: string;
  out AImporte: Currency): Boolean;
var
  dValor: Double;
begin
  Result := TryStrToFloat(ValorEtiqueta(AXml, ANombreLocal), dValor,
    TFormatSettings.Invariant);
  if Result then
    AImporte := dValor
  else
    AImporte := 0;
end;

function NormalizarNif(const ANif: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(ANif) do
    if CharInSet(UpCase(ANif[i]), ['A'..'Z', '0'..'9']) then
      Result := Result + UpCase(ANif[i]);
end;

function RegistroComparable(const ADatos: TDatosComparacionSubsanacion):
  Boolean;
var
  cImporte: Currency;
begin
  Result := ImporteRegistro(ADatos.RegistroXml, 'ImporteTotal', cImporte);
end;

procedure AnadirDiferencia(var ATexto: string; const ADiferencia: string);
begin
  if ATexto <> '' then
    ATexto := ATexto + '; ';
  ATexto := ATexto + ADiferencia;
end;

procedure CompararImporte(var ATexto: string; const AXml,
  AEtiqueta, AFormato: string; AActual: Currency);
var
  cRegistro: Currency;
begin
  if ImporteRegistro(AXml, AEtiqueta, cRegistro) and
     (Abs(AActual - cRegistro) >= cToleranciaImporte) then
    AnadirDiferencia(ATexto, Format(AFormato,
      [FormatFloat('#,##0.00', AActual), FormatFloat('#,##0.00', cRegistro)]));
end;

procedure CompararDestinatario(var ATexto: string;
  const ADatos: TDatosComparacionSubsanacion);
var
  sDestinatarios: string;
  sNif: string;
  sNombre: string;
begin
  sDestinatarios := BloqueEtiqueta(ADatos.RegistroXml, 'Destinatarios');
  sNif := ValorEtiqueta(sDestinatarios, 'NIF');
  sNombre := ValorEtiqueta(sDestinatarios, 'NombreRazon');
  // Un destinatario extranjero (IDOtro) no trae NIF: se compara el nombre.
  if ((sNif <> '') and
      (NormalizarNif(sNif) <> NormalizarNif(ADatos.NifCliente))) or
     ((sNombre <> '') and
      not SameText(sNombre, Trim(ADatos.NombreCliente))) then
    AnadirDiferencia(ATexto, Format(SDetalleSubsanacionDestinatario,
      [Trim(ADatos.NifCliente + ' ' + ADatos.NombreCliente),
       Trim(sNif + ' ' + sNombre)]));
end;

function DiferenciasConRegistro(
  const ADatos: TDatosComparacionSubsanacion): string;
begin
  Result := '';
  if RegistroComparable(ADatos) then
  begin
    CompararImporte(Result, ADatos.RegistroXml, 'ImporteTotal',
      SDetalleSubsanacionImporte, ADatos.ImporteTotal);
    CompararImporte(Result, ADatos.RegistroXml, 'CuotaTotal',
      SDetalleSubsanacionCuota, ADatos.CuotaTotal);
    CompararDestinatario(Result, ADatos);
  end;
end;

end.
