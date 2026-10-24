{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoTicketIntf                                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Read models necesarios para presentar e imprimir arqueos de Caja.         }
{******************************************************************************}
unit inLibArqueoTicketIntf;

interface

uses
  inLibArqueoIntf;

type
  TEmpresaArqueoTicket = record
    Encontrada: Boolean;
    RazonSocial: string;
    Nif: string;
    Direccion: string;
    CodigoPostal: string;
    Poblacion: string;
    Provincia: string;
  end;

  TContadoresArqueoTicket = record
    Encontrado: Boolean;
    PrimeraOperacion: string;
    UltimaOperacion: string;
    Unidades: Currency;
  end;

  TDevolucionFormaPagoArqueo = record
    FormaPago: string;
    Importe: Currency;
  end;

  TResumenSeccionArqueo = record
    Familia: string;
    Unidades: Double;
    Neto: Currency;
  end;

  TResumenTemporadaArqueo = record
    Temporada: string;
    Unidades: Double;
    Neto: Currency;
  end;

  TResumenEmpleadoArqueo = record
    Empleado: string;
    Operaciones: Integer;
    Neto: Currency;
  end;

  TResumenFormaPagoArqueo = record
    Codigo: string;
    Descripcion: string;
    Unidades: Integer;
    Importe: Currency;
  end;

  TResumenSerieArqueo = record
    Serie: string;
    Base: Currency;
    Cuota: Currency;
    Total: Currency;
  end;

  TRangoHistoricoArqueo = record
    Encontrado: Boolean;
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDate;
    FechaHasta: TDate;
  end;

  TRecuentoHistoricoArqueo = record
    CodigoFormaPago: string;
    Descripcion: string;
    EsCajon: string;
    Sistema: Currency;
    Recuento: Currency;
    Diferencia: Currency;
  end;

  TCierreHistoricoArqueo = record
    Encontrado: Boolean;
    Arqueo: TArqueoCaja;
    TotalSistema: Currency;
    TotalRecuento: Currency;
    Diferencia: Currency;
    Retirada: Currency;
    EfectivoDejado: Currency;
    ConceptoRetirada: string;
    DesgloseBilletes: string;
    Observaciones: string;
    Vendedor: string;
    Lineas: TArray<TRecuentoHistoricoArqueo>;
  end;

  IRepositorioArqueoTicket = interface
    ['{79A7E2A4-A67A-4EF9-B167-526106C40A10}']
    function ObtenerEmpresa(
      const AEmpresa: string): TEmpresaArqueoTicket;
    function ObtenerContadores(
      const AArqueo: TArqueoCaja): TContadoresArqueoTicket;
    function ListarDevolucionesPorFormaPago(
      const AArqueo: TArqueoCaja):
      TArray<TDevolucionFormaPagoArqueo>;
    function ListarResumenSeccion(
      const AArqueo: TArqueoCaja;
      ANiveles: Integer;
      AIncluirDevoluciones: Boolean): TArray<TResumenSeccionArqueo>;
    function ListarResumenTemporada(
      const AArqueo: TArqueoCaja):
      TArray<TResumenTemporadaArqueo>;
    function ListarResumenEmpleado(
      const AArqueo: TArqueoCaja):
      TArray<TResumenEmpleadoArqueo>;
    function ListarResumenFormaPago(
      const AArqueo: TArqueoCaja):
      TArray<TResumenFormaPagoArqueo>;
    function ListarResumenSerie(
      const AArqueo: TArqueoCaja):
      TArray<TResumenSerieArqueo>;
    function ObtenerRangoHistorico(
      const AEmpresa, AAlmacen, ACaja, ACodigoArqueo: string):
      TRangoHistoricoArqueo;
    function ObtenerCierreHistorico(
      const AEmpresa, AAlmacen, ACaja, ACodigoArqueo: string):
      TCierreHistoricoArqueo;
  end;

implementation

end.
