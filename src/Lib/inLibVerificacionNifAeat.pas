{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerificacionNifAeat                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Transporte HTTPS del servicio VNifV2 de la AEAT con el certificado de     }
{    la empresa, sobre la capa de envío VERI*FACTU. FZ-ISSUE-131.              }
{******************************************************************************}
unit inLibVerificacionNifAeat;

interface

uses
  inLibVerificacionNifIntf;

const
  // Endpoint de producción del WSDL VNifV2 (www10 es el alternativo).
  cUrlVerificacionNifAeat =
    'https://www1.agenciatributaria.gob.es/wlpl/BURT-JDIT/ws/VNifV2SOAP';

function CrearTransporteVerificacionNifAeat(
  const AUrl: string): ITransporteVerificacionNif;

implementation

uses
  System.SysUtils,
  inLibVerifactuEnvio;

type
  TTransporteVerificacionNifAeat = class(
    TInterfacedObject,
    ITransporteVerificacionNif)
  private
    FUrl: string;
  public
    constructor Create(const AUrl: string);
    function Enviar(
      const APeticion: string;
      const ACertificado: TCertificadoVerificacionNif;
      out AStatus: Integer): string;
  end;

constructor TTransporteVerificacionNifAeat.Create(const AUrl: string);
begin
  inherited Create;
  FUrl := Trim(AUrl);
  if FUrl = '' then
    FUrl := cUrlVerificacionNifAeat;
end;

function TTransporteVerificacionNifAeat.Enviar(
  const APeticion: string;
  const ACertificado: TCertificadoVerificacionNif;
  out AStatus: Integer): string;
begin
  EnviarSoapAeatConCertificado(
    FUrl,
    APeticion,
    ACertificado.Serie,
    ACertificado.Titular,
    AStatus,
    Result);
end;

function CrearTransporteVerificacionNifAeat(
  const AUrl: string): ITransporteVerificacionNif;
begin
  Result := TTransporteVerificacionNifAeat.Create(AUrl);
end;

end.
