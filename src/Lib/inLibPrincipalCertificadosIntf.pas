{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPrincipalCertificadosIntf                                }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Contrato de lectura de certificados de las empresas activas.              }
{******************************************************************************}
unit inLibPrincipalCertificadosIntf;

interface

uses
  System.SysUtils;

type
  TCertificadoEmpresaActivo = record
    CodigoEmpresa: string;
    Empresa: string;
    Serie: string;
    Titular: string;
    FechaHasta: TDateTime;
    TieneFechaHasta: Boolean;
  end;
  TCertificadosEmpresasActivos = TArray<TCertificadoEmpresaActivo>;

  IRepositorioCertificadosEmpresas = interface
    ['{1D1285D1-DC28-4E39-B2F3-B2223C16A049}']
    function ListarActivos: TCertificadosEmpresasActivos;
  end;

implementation

end.
