{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasAplicacionIntf                                  }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos por capacidad para orquestar facturas sin depender de VCL.     }
{******************************************************************************}
unit inLibFacturasAplicacionIntf;

interface

uses
  System.SysUtils,
  inLibFacturasOperacionFiscal;

type
  TEstadoDatosFactura = (
    edfSinDatos,
    edfInsertando,
    edfEditando,
    edfConsultando);
  TSolicitudEstadoFactura = record
    Fase: string;
    Consolidada: Boolean;
    SinVerifactu: Boolean;
    EstadoDatos: TEstadoDatosFactura;
  end;
  TEstadoVisualFactura = record
    Editable: Boolean;
    ActualizarAcciones: Boolean;
    PuedeConsolidar: Boolean;
    PuedeImprimir: Boolean;
    // Fase SUBSANACION: editable con identidad (número, fecha, emisor)
    // y estructura de líneas fijas.
    Subsanando: Boolean;
  end;
  TModoEntradaFactura = (
    mefAutomatico,
    mefSku,
    mefTallas);
  TSolicitudGeneracionCobrosFactura = record
    Serie: string;
    Numero: string;
    Usuario: string;
    CodigoBanco: string;
    Iban: string;
  end;
  TSolicitudRegistroCobroFactura = record
    Serie: string;
    Numero: string;
    Usuario: string;
    NumeroEfecto: Integer;
    Fecha: TDateTime;
    Importe: Double;
    Tipo: string;
    Referencia: string;
  end;
  TSolicitudEstadoCobroFactura = record
    Serie: string;
    Numero: string;
    Usuario: string;
    NumeroEfecto: Integer;
    Estado: string;
  end;
  IVistaFactura = interface
    ['{DF3AC783-43AF-4B61-A5AF-9B4E18F78B8A}']
    function Confirmar(const APregunta: string): Boolean;
    procedure MostrarInformacion(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure RefrescarFactura;
    procedure RefrescarMovimientos;
    procedure ArchivarFactura(const ASerie, ANumero: string);
    procedure AplicarEstado(const AEstado: TEstadoVisualFactura);
    procedure AplicarModoEntrada(AModo: TModoEntradaFactura);
  end;
  IAplicacionConsolidacionFactura = interface
    ['{FF2734BD-6264-4DB8-A6ED-2785395E72B8}']
    procedure Ejecutar(
      const ASerie, ANumero, AUsuario: string);
  end;
  IAplicacionOperacionFiscalFactura = interface
    ['{B8D5A231-0F97-4A9A-BEEA-76E45756FD05}']
    procedure Ejecutar(
      const AContexto: TContextoOperacionFiscalFactura);
  end;
  IAplicacionCobrosFactura = interface
    ['{CCBA2B0D-E5B6-42F7-83ED-F4FC211CBF41}']
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASolicitud: TSolicitudGeneracionCobrosFactura): Integer;
    function Registrar(
      const ASolicitud: TSolicitudRegistroCobroFactura): Integer;
    function CambiarEstado(
      const ASolicitud: TSolicitudEstadoCobroFactura): Boolean;
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
  end;
  IPresentadorEstadoFactura = interface
    ['{ECF6570A-F7A1-45D3-965D-C1D5FB273A7E}']
    procedure Presentar(
      const ASolicitud: TSolicitudEstadoFactura);
  end;
  IGestorModoEntradaFactura = interface
    ['{4E8634BF-A1CD-4429-B06E-C1CF0841ED98}']
    function ModoActual: TModoEntradaFactura;
    procedure Seleccionar(AModo: TModoEntradaFactura);
    procedure SeleccionarSiguiente;
    procedure Reaplicar;
  end;

implementation

end.
