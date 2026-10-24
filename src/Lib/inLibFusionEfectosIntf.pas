{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFusionEfectosIntf                                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos compartidos para fusionar efectos de compra y venta.            }
{******************************************************************************}
unit inLibFusionEfectosIntf;

interface

type
  TClaveFusionEfecto = record
    SerieFactura: string;
    NumeroFactura: string;
    NumeroEfecto: Integer;
  end;
  TClavesFusionEfectos = TArray<TClaveFusionEfecto>;
  TResultadoFusionEfectos = record
    Cantidad: Integer;
    Referencia: string;
  end;
  IRepositorioFusionEfectos = interface
    ['{26824E54-51A2-4F16-BBFA-C86996AB40E2}']
    function Fusionar(
      const AClaves: TClavesFusionEfectos
    ): TResultadoFusionEfectos;
  end;
  ICasoUsoFusionEfectos = interface
    ['{FF0341A8-9EFE-45D2-BE92-60F3C9C691AB}']
    function Ejecutar(
      const AClaves: TClavesFusionEfectos
    ): TResultadoFusionEfectos;
  end;

implementation

end.
