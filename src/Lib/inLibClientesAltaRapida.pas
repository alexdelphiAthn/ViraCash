{******************************************************************************}
{                                                                              }
{  Módulo:       inLibClientesAltaRapida                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Validación de los datos básicos del alta rápida de clientes.             }
{******************************************************************************}
unit inLibClientesAltaRapida;

interface

uses
  inLibClientesPersistenciaIntf, inLibPermisosIntf;

function ErrorDatosAltaRapidaCliente(
  const ADatos: TDatosAltaRapidaCliente): string;
function ErrorNifCliente(const ANif, ACodigoPais,
  ANombrePais: string): string;
function PuedeAltaRapidaCliente(
  const APermisos: IPermisosAplicacion): Boolean;

implementation

uses
  System.SysUtils, inLibDocumentoFiscal, inLibMsgVentas;

function ErrorNifCliente(const ANif, ACodigoPais,
  ANombrePais: string): string;
begin
  Result := '';
  if (Trim(ANif) <> '') and PaisEsEspana(ACodigoPais, ANombrePais) and
     not DocumentoFiscalValido(ANif) then
    Result := MensajeDocumentoFiscalInvalido(ANif);
end;

function ErrorDatosAltaRapidaCliente(
  const ADatos: TDatosAltaRapidaCliente): string;
begin
  Result := '';
  if Trim(ADatos.RazonSocial) = '' then
    Result := SErrorRazonSocialAltaRapidaCliente
  else if Trim(ADatos.Nif) = '' then
    Result := SErrorNifAltaRapidaCliente
  else if (Trim(ADatos.Pais.Codigo) = '') or
          (Trim(ADatos.Pais.Nombre) = '') then
    Result := SErrorPaisAltaRapidaCliente
  else if ADatos.ComprobarNif then
    Result := ErrorNifCliente(ADatos.Nif, ADatos.Pais.Codigo,
      ADatos.Pais.Nombre);
end;

function PuedeAltaRapidaCliente(
  const APermisos: IPermisosAplicacion): Boolean;
begin
  Result := Assigned(APermisos);
  if Result then
    Result := APermisos.TienePermiso(
      CodigoPermisoMto('Clientes', apmInsertar), paPermitir);
end;

end.
