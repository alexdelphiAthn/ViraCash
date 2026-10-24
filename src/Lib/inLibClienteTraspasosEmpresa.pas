{******************************************************************************}
{                                                                              }
{  Módulo:       inLibClienteTraspasosEmpresa                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas del cliente al que se emiten las facturas internas entre           }
{    empresas (TPV > Facturas proforma, modalidades TA y TV): su código y si   }
{    se le practican retenciones de IRPF al crearlo. Sin VCL ni SQL.           }
{******************************************************************************}
unit inLibClienteTraspasosEmpresa;

interface

type
  // Datos de la empresa destino con los que se da de alta su cliente.
  TDatosClienteTraspasosEmpresa = record
    CodigoEmpresa     : string;
    RazonSocial       : string;
    Nif               : string;
    Movil             : string;
    Email             : string;
    Direccion1        : string;
    Direccion2        : string;
    CodigoPostal      : string;
    Poblacion         : string;
    Provincia         : string;
    CodigoPais        : string;
    NombrePais        : string;
    EsRegimenAgricola : Boolean;
    // FZ-ISSUE-354: empresa destino en recargo de equivalencia
    // (ESIVA_RECARGO_COMPRAS_EMP): su cliente nace con recargo.
    EsRecargoEquivalencia: Boolean;
  end;

// 'E_' + código de la empresa.
function CodigoClienteTraspasosEmpresa(const ACodigoEmpresa: string): string;

implementation

uses
  System.SysUtils;

const
  PREFIJO_CLIENTE_TRASPASOS = 'E_';

function CodigoClienteTraspasosEmpresa(const ACodigoEmpresa: string): string;
begin
  Result := PREFIJO_CLIENTE_TRASPASOS + Trim(ACodigoEmpresa);
end;

end.
