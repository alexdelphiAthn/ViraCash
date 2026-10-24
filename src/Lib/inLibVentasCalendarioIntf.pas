{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasCalendarioIntf                                     }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de lectura de las operaciones de caja agrupadas por día para       }
{    el calendario de ventas y su fábrica registrable.                         }
{******************************************************************************}
unit inLibVentasCalendarioIntf;

interface

type
  TVentasDiaResumen = record
    Fecha: TDateTime;
    TotalVentas: Integer;
    TotalCobrado: Currency;
  end;
  TVentasDiasResumen = TArray<TVentasDiaResumen>;
  IRepositorioVentasCalendario = interface
    ['{4F01BAAE-36DA-4F34-9B00-C534AA74A45B}']
    function CargarDiasConVentas(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaInicio, AFechaFin: TDateTime): TVentasDiasResumen;
  end;
implementation
end.
