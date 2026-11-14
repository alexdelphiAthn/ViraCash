{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTransitoEmpresas                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Qué empresa entrega la mercancía de un almacén de tránsito y si cada      }
{    tramo es un traspaso (TR), un traspaso entre empresas (TA) o una          }
{    pérdida (TP). FZ-ISSUE-717: en un tránsito compartido la mercancía en     }
{    ruta sigue siendo de la empresa que la cargó.                             }
{******************************************************************************}
unit inLibTransitoEmpresas;

interface

const
  TIPO_DOC_TRASPASO = 'TR';
  TIPO_DOC_TRASPASO_EMPRESAS = 'TA';
  // La pérdida en transporte sale del tránsito con un tipo de documento
  // propio: no es un traspaso (no entra en ningún almacén) ni un
  // inventario, y así se distingue en los movimientos.
  TIPO_DOC_PERDIDA_TRANSITO = 'TP';

type
  // Tránsito al que llega la carga: su empresa y si es compartido.
  TTransitoEmpresa = record
    Empresa: string;
    EsCompartido: Boolean;
  end;

  // Documento que saca mercancía del tránsito. EmpresaEntrega es la dueña
  // de lo que sale; EmpresaOperacion lleva la operación de caja y
  // EmpresaContraOperacion su contrapartida: en una TA, la que entrega y la
  // que recibe, como en un traspaso directo entre empresas.
  TSalidaTransitoEmpresas = record
    EmpresaEntrega: string;
    TipoDocumento: string;
    EmpresaOperacion: string;
    EmpresaContraOperacion: string;
  end;

// Empresa en la que entra la carga en el tránsito. Un tránsito compartido
// o sin empresa la guarda a nombre de la empresa que carga.
function EmpresaEntradaTransito(const AEmpresaCarga: string;
  const ATransito: TTransitoEmpresa): string;

// TR si la carga queda en la misma empresa que la carga; TA si no.
function TipoDocumentoCargaTransito(const AEmpresaCarga: string;
  const ATransito: TTransitoEmpresa): string;

// Salida del tránsito hacia la caja de AEmpresaCaja. AEsPerdida: no entra
// en ningún almacén. AEmpresaCarga es la empresa que hizo la carga.
function ResolverSalidaTransito(const AEmpresaCarga, AEmpresaCaja: string;
  const ATransito: TTransitoEmpresa;
  AEsPerdida: Boolean): TSalidaTransitoEmpresas;

implementation

uses
  System.SysUtils;

function EmpresaEntradaTransito(const AEmpresaCarga: string;
  const ATransito: TTransitoEmpresa): string;
begin
  if ATransito.EsCompartido or (Trim(ATransito.Empresa) = '') then
    Result := AEmpresaCarga
  else
    Result := ATransito.Empresa;
end;

function TipoDocumentoCargaTransito(const AEmpresaCarga: string;
  const ATransito: TTransitoEmpresa): string;
begin
  if SameText(EmpresaEntradaTransito(AEmpresaCarga, ATransito),
       AEmpresaCarga) then
    Result := TIPO_DOC_TRASPASO
  else
    Result := TIPO_DOC_TRASPASO_EMPRESAS;
end;

function EmpresaDuenaTransito(const AEmpresaCarga, AEmpresaCaja: string;
  const ATransito: TTransitoEmpresa): string;
begin
  if ATransito.EsCompartido then
    Result := AEmpresaCarga
  else
    Result := ATransito.Empresa;
  if Trim(Result) = '' then
    Result := AEmpresaCaja;
end;

function ResolverSalidaTransito(const AEmpresaCarga, AEmpresaCaja: string;
  const ATransito: TTransitoEmpresa;
  AEsPerdida: Boolean): TSalidaTransitoEmpresas;
begin
  Result := Default(TSalidaTransitoEmpresas);
  Result.EmpresaEntrega := EmpresaDuenaTransito(AEmpresaCarga, AEmpresaCaja,
    ATransito);
  Result.EmpresaOperacion := AEmpresaCaja;
  Result.EmpresaContraOperacion := Result.EmpresaEntrega;
  if AEsPerdida then
    Result.TipoDocumento := TIPO_DOC_PERDIDA_TRANSITO
  else if SameText(Result.EmpresaEntrega, AEmpresaCaja) then
    Result.TipoDocumento := TIPO_DOC_TRASPASO
  else
  begin
    // Facturas proforma busca la TA en la empresa que entrega, con su
    // salida de stock: la operación es suya aunque la grabe otra caja.
    Result.TipoDocumento := TIPO_DOC_TRASPASO_EMPRESAS;
    Result.EmpresaOperacion := Result.EmpresaEntrega;
    Result.EmpresaContraOperacion := AEmpresaCaja;
  end;
end;

end.
