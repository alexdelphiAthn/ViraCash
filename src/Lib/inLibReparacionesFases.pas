{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesFases                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Fases configurables y texto del aviso al cliente.                         }
{******************************************************************************}
unit inLibReparacionesFases;

interface

type
  TFaseReparacionCatalogo = record
    Codigo: string;
    Descripcion: string;
  end;
  TCambioFaseReparacion = record
    Reparacion: Int64;
    Anterior: string;
    Nueva: string;
    Usuario: string;
    Observaciones: string;
  end;
  TAvisoFaseReparacion = record
    Historial: Int64;
    Reparacion: Int64;
    Referencia: string;
    Cliente: string;
    Email: string;
    Objeto: string;
    Fase: string;
    Instante: TDateTime;
  end;

const
  FASE_PENDIENTE_CLIENTE = 'EN_RECEPCION';
  FASE_ENTREGADA_CLIENTE = 'ENTREGADO';

function ValidarCambioFase(const ACambio: TCambioFaseReparacion): string;
function AsuntoAvisoFase(const AAviso: TAvisoFaseReparacion): string;
function TextoAvisoFase(const AAviso: TAvisoFaseReparacion): string;

implementation

uses
  System.SysUtils, inLibMsgReparaciones;

function ValidarCambioFase(const ACambio: TCambioFaseReparacion): string;
begin
  Result := '';
  if ACambio.Reparacion <= 0 then
    Result := SInfoSinReparacion
  else if Trim(ACambio.Nueva) = '' then
    Result := SFaseSeleccionar
  else if Trim(ACambio.Usuario) = '' then
    Result := SFaseUsuarioObligatorio;
end;

function AsuntoAvisoFase(const AAviso: TAvisoFaseReparacion): string;
begin
  if AAviso.Referencia = '' then
    Result := Format(SFaseAsuntoCorreo, [AAviso.Reparacion, AAviso.Fase])
  else
    Result := Format(StringReplace(SFaseAsuntoCorreo, '%d', '%s', []),
      [AAviso.Referencia, AAviso.Fase]);
end;

function TextoAvisoFase(const AAviso: TAvisoFaseReparacion): string;
begin
  if AAviso.Referencia = '' then
    Result := Format(SFaseTextoCorreo, [AAviso.Cliente, AAviso.Reparacion,
      AAviso.Objeto, AAviso.Fase,
      FormatDateTime('dd/mm/yyyy hh:nn:ss', AAviso.Instante)])
  else
    Result := Format(StringReplace(SFaseTextoCorreo, '%d', '%s', []),
      [AAviso.Cliente, AAviso.Referencia, AAviso.Objeto, AAviso.Fase,
      FormatDateTime('dd/mm/yyyy hh:nn:ss', AAviso.Instante)]);
end;

end.
