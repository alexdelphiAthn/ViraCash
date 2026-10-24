{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImpuestosLecturasIntf                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de lecturas fiscales requeridas por los documentos.              }
{******************************************************************************}
unit inLibImpuestosLecturasIntf;

interface

type
  TPorcentajesImpuestos = record
    CodigoIva: string;
    IvaNormal: Double;
    IvaReducido: Double;
    IvaSuperReducido: Double;
    IvaExento: Double;
    RecargoNormal: Double;
    RecargoReducido: Double;
    RecargoSuperReducido: Double;
    RecargoExento: Double;
  end;

  ILecturasImpuestos = interface
    ['{AB02FA61-5269-4D54-A5AC-3CD4A60B623D}']
    function LeerPorCodigo(const ACodigoIva: string;
      out APorcentajes: TPorcentajesImpuestos): Boolean;
    function LeerPorEmpresa(const ACodigoEmpresa: string;
      out APorcentajes: TPorcentajesImpuestos): Boolean;
    function LeerPorEmpresaEnFecha(const ACodigoEmpresa: string;
      AFecha: TDateTime;
      out APorcentajes: TPorcentajesImpuestos): Boolean;
    function LeerAplicaRecargoZona(const ACodigoIva: string): Boolean;
    function LeerTipoIvaArticulo(
      const ACodigoArticulo: string): string;
    function LeerRecargoComprasEmpresa(
      const ACodigoEmpresa: string): Boolean;
    function LeerExentoIntracomunitarioProveedor(
      const ACodigoProveedor: string): Boolean;
    function LeerRetencionEmpresa(const ACodigoEmpresa: string;
      AFecha: TDateTime): Double;
  end;

implementation

end.
