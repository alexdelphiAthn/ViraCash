{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasPersistenciaIntf                                 }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos de persistencia de las operaciones de facturas de venta:          }
{    borrado, reapertura, consolidación, efectos, movimientos y PDF.           }
{******************************************************************************}
unit inLibFacturasPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TDatosFacturaReapertura = record
    Encontrada: Boolean;
    Consolidada: Boolean;
    Fase: string;
    EstadoCola: string;
  end;
  TDatosFacturaConsolidacion = record
    Encontrada: Boolean;
    Fase: string;
    TipoFactura: string;
    NifCliente: string;
    Empresa: string;
    Cliente: string;
    Caja: string;
    NumeroOperacion: string;
    Fecha: TDateTime;
    MueveStock: Boolean;
    NumeroLineas: Integer;
    // FZ-ISSUE-322: la coherencia fiscal se comprueba al consolidar con los
    // totales ya grabados.
    TipoOperacion: string;
    CodigoPaisCliente: string;
    TotalImpuestos: Currency;
  end;
  TLineaFacturaMovimiento = record
    Linea: string;
    Sku: string;
    Articulo: string;
    Almacen: string;
    Cantidad: Double;
    NumeroMovimiento: string;
    // F-LOTEC-016: lote o serie de la línea ('' sin lote); 0 = sin fecha.
    Lote: string;
    FechaCaducidad: TDate;
  end;
  TLineasFacturaMovimientos = TArray<TLineaFacturaMovimiento>;
  TInsercionMovimientoFactura = record
    NumeroMovimiento: string;
    TipoDocumento: string;
    TipoMovimiento: string;
    Serie: string;
    Numero: string;
    Linea: string;
    Empresa: string;
    Almacen: string;
    Sku: string;
    Articulo: string;
    Cantidad: Double;
    Fecha: TDateTime;
    Usuario: string;
    NumeroOperacion: string;
    Caja: string;
    Cliente: string;
    Lote: string;
    FechaCaducidad: TDate;
  end;
  IRepositorioBorradoFactura = interface
    ['{2CFE5841-408C-4180-9E1F-DCC23123B7F0}']
    function TieneEfectosCobrados(
      const ASerie, ANumero: string): Boolean;
    procedure DesvincularAlbaranes(
      const ASerie, ANumero, AUsuario: string);
    procedure BorrarEfectos(
      const ASerie, ANumero: string);
    procedure BorrarLineas(
      const ASerie, ANumero: string);
    procedure BorrarRecibos(
      const ASerie, ANumero: string);
  end;
  IRepositorioReaperturaFactura = interface
    ['{65F7FF54-9994-4D0D-8690-EFFC203FDB40}']
    function CargarDatosReapertura(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosFacturaReapertura;
    procedure AparcarAltaEnCola(
      const ASerie, ANumero, AUsuario: string);
    procedure MarcarComoBorrador(
      const ASerie, ANumero, AUsuario: string);
  end;
  IRepositorioConsolidacionFactura = interface
    ['{8F7ABBA4-4269-4C4E-AA67-98946E3EF730}']
    function CargarDatosConsolidacion(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosFacturaConsolidacion;
  end;
  IRepositorioEfectosFactura = interface
    ['{D52F6488-59E1-4A08-B7C9-C589811E5AA7}']
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function GenerarDesdeFactura(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
  end;
  IRepositorioMovimientosFactura = interface
    ['{5628E733-69F7-4547-9093-7EE24AF12385}']
    function CargarLineas(
      const ASerie, ANumero: string): TLineasFacturaMovimientos;
    function BuscarMovimientoExistente(
      const ATipoDocumento, ASerie, ANumero, ALinea: string): string;
    procedure InsertarMovimiento(
      const ADatos: TInsercionMovimientoFactura);
    procedure ActualizarLineaMovimiento(
      const ASerie, ANumero, ALinea, ANumeroMovimiento,
        AUsuario: string);
    procedure RecalcularDocumento(
      const ATipo, ASerie, ANumero: string);
  end;
  IRepositorioPdfFactura = interface
    ['{DF36BDC0-6E1D-4DBC-9D32-715DA126B32A}']
    function GuardarPdf(
      const ASerie, ANumero, ARutaPdf, AFormato,
        AUsuario: string): Boolean;
  end;
  IUnidadTrabajoFacturas = interface
    ['{43061F67-7E98-46F6-8232-E0641724D60A}']
    procedure Ejecutar(const ATrabajo: TProc);
  end;
  TPersistenciaFacturas = record
    UnidadTrabajo: IUnidadTrabajoFacturas;
    Borrado: IRepositorioBorradoFactura;
    Reapertura: IRepositorioReaperturaFactura;
    Consolidacion: IRepositorioConsolidacionFactura;
    Efectos: IRepositorioEfectosFactura;
    Movimientos: IRepositorioMovimientosFactura;
    Pdf: IRepositorioPdfFactura;
  end;
implementation
end.
