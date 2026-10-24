{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaPantallaHistoricosIntf                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de escritura atómica para los perfiles de históricos de Caja.  }
{******************************************************************************}
unit inLibCajaPantallaHistoricosIntf;

interface

uses
  inLibPerfilesUsuarioIntf;

type
  IUnidadTrabajoPerfilesCaja = interface
    ['{802D833B-296E-4719-929A-20B89B44D027}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

  IGrabadorPerfilesHistoricoCaja = interface
    ['{2B2D3262-8988-4BEC-BC4B-E69A5776843B}']
    procedure Grabar(const APerfiles: TPerfilList);
  end;

implementation

end.
