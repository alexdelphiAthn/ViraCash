{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCargaEfectosRemesaPersistenciaIntf                     }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de persistencia para cargar efectos en remesas de compra o venta. }
{******************************************************************************}
unit inLibCargaEfectosRemesaPersistenciaIntf;

interface

uses
  System.SysUtils, Data.DB;

type
  TTipoCargaEfectosRemesa = (
    tcerCompra,
    tcerVenta
  );

  IConsultaEfectosRemesa = interface
    ['{4E26BBF8-DC46-466B-B89D-0A201FE36B9E}']
    function DataSet: TDataSet;
  end;

  TRemesaAbierta = record
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
  end;

  TRemesasAbiertas = TArray<TRemesaAbierta>;

  TEfectoParaRemesar = record
    SerieFactura: string;
    NumeroFactura: string;
    NumeroEfecto: Integer;
  end;

  TEfectosParaRemesar = TArray<TEfectoParaRemesar>;

  TResultadoCreacionRemesa = record
    Creada: Boolean;
    Serie: string;
    Numero: string;
  end;

  TResultadoCargaEfectosRemesa = record
    Procesados: Integer;
    Omitidos: Integer;
  end;

  IRepositorioCargaEfectosRemesa = interface
    ['{2CA208EA-FDBA-4FF3-B5F4-32082BE82BF4}']
    function ConsultarEmpresas: IConsultaEfectosRemesa;
    function ConsultarEfectosPendientes(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa: string;
      AFechaHasta: TDateTime): IConsultaEfectosRemesa;
    function ListarRemesasAbiertas(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa: string): TRemesasAbiertas;
    function CrearRemesa(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa, AUsuario: string): TResultadoCreacionRemesa;
    function AnyadirEfectos(
      ATipo: TTipoCargaEfectosRemesa;
      const ASerieRemesa, ANumeroRemesa: string;
      const AEfectos: TEfectosParaRemesar;
      const AUsuario: string): TResultadoCargaEfectosRemesa;
    // Crea la remesa y le carga los efectos en una sola transacción.
    function CrearRemesaConEfectos(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa: string;
      const AEfectos: TEfectosParaRemesar;
      const AUsuario: string;
      out ACreacion: TResultadoCreacionRemesa): TResultadoCargaEfectosRemesa;
  end;

implementation

end.
