{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasLecturasIntf                                     }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto para las lecturas auxiliares del cálculo de facturas.              }
{******************************************************************************}
unit inLibFacturasLecturasIntf;

interface

uses
  Data.DB;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IRepositorioLecturasFactura = interface
    ['{AE25B853-78B7-43D6-8989-1DBFC93368ED}']
    function ArticuloDebeMostrarSku(
      const ACodigoArticulo: string): Boolean;
    function ContarLineas(
      const ASerie, ANumero: string): Integer;
    function BuscarConfiguracionIva(
      const AGrupo: string;
      AFecha: TDateTime): TDataSet;
    function BuscarPorcentajeRetencion(
      const ACodigoEmpresa: string;
      AFecha: TDateTime): Currency;
    function BuscarDatosIvaAgricola(
      const ACodigoEmpresa: string;
      AFecha: TDateTime): TDataSet;
    function BuscarClienteConTarifa(
      const ACodigoCliente: string): TDataSet;
    function BuscarEmpresa(
      const ACodigoEmpresa: string): TDataSet;
  end;

implementation
end.
