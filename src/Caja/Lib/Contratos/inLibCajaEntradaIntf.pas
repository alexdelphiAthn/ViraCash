{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaEntradaIntf                                          }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de entrada de artículos de caja sin dependencias visuales.     }
{******************************************************************************}
unit inLibCajaEntradaIntf;

interface

uses
  inLibArticulosValidadorIntf, inLibTrazabilidad;

type
  IVistaEntradaCaja = interface
    ['{71358C32-91A4-4F6B-A6DD-632B54A9C878}']
    procedure MostrarError(const AMensaje: string);
    procedure EnfocarVendedor;
    procedure PrepararLectura;
    procedure RefrescarConsolidacion;
    procedure PrepararSiguiente;
  end;
  IOperacionesEntradaCaja = interface
    ['{0BF2715C-D462-4497-92B8-967134BD55CD}']
    function Disponible: Boolean;
    function VendedorAsignado: Boolean;
    function PermitirSku(const ACodigoSku: string): Boolean;
    procedure PrepararLinea;
    function ConsolidarSku(const ACodigoSku: string): Boolean;
    procedure AplicarCodigo(
      const ACodigo, ACodigoSku, ACodigoArticulo: string);
    procedure Iniciar;
    procedure Finalizar;
  end;
  // F-LOTEC-015: lote o serie del artículo leído en caja (solo con los
  // interruptores; sin él, la entrada es la de siempre).
  ITrazabilidadEntradaCaja = interface
    ['{5B0C8E57-9F1D-4F7A-8B2D-6A1E3C9D4F21}']
    // False: no se da de alta (cancelado o rechazado, ya avisado). Sin
    // asignaciones, la línea va sin lote como siempre.
    function Decidir(const AResolucion: TArtResolucionEntrada;
      out AAsignaciones: TArray<TAsignacionLote>): Boolean;
    // Suma a otra línea del mismo SKU y lote (nunca a una serie).
    function Consolidar(const ACodigoSku: string;
      const AAsignacion: TAsignacionLote): Boolean;
    // Deja el lote o la serie en la línea recién dada de alta.
    procedure EscribirLote(const AAsignacion: TAsignacionLote);
  end;
  IAplicacionEntradaCaja = interface
    ['{C7776D8B-602D-42E9-BCB3-43D6A78EE0E6}']
    procedure Procesar(const ACodigo: string);
  end;

implementation

end.
