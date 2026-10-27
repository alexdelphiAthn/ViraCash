{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaSubsanacionIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Corrección de importes y cobro conservando la identidad de la operación.  }
{******************************************************************************}
unit inLibCajaSubsanacionIntf;

interface

uses
  inLibCajaSubsanacion;

type
  TClaveOperacionSubsanacionCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
    SerieFactura: string;
    NumeroFactura: string;
  end;

  // Cobro vigente o nuevo, neto de cambio, en euros. Divisas y
  // criptomonedas conservan además el importe en su moneda. Los vales
  // (FormaPago VALE, Referencia = código, negativo si se emitió) no se
  // pueden cambiar: la solicitud debe llevarlos tal cual.
  TPagoSubsanacionCaja = record
    FormaPago: string;
    Referencia: string;
    Importe: Currency;
    CodigoDivisa: string;
    RedBlockchain: string;
    FactorCambio: Double;
    ImporteDivisa: Double;
  end;
  TPagosSubsanacionCaja = TArray<TPagoSubsanacionCaja>;

  TOperacionSubsanacionCaja = record
    Clave: TClaveOperacionSubsanacionCaja;
    FechaFactura: TDateTime;
    Lineas: TLineasSubsanacionCaja;
    Total: Currency;
    Pagos: TPagosSubsanacionCaja;
    Version: string;
  end;

  TSolicitudSubsanacionCaja = record
    Original: TOperacionSubsanacionCaja;
    // Las mismas líneas de Original con unidades, precios e importes
    // corregidos: no se añaden ni se quitan líneas.
    Lineas: TLineasSubsanacionCaja;
    // Si difieren de Original.Pagos se compensan los vigentes y se dan de
    // alta estos, como en la corrección de forma de pago.
    Pagos: TPagosSubsanacionCaja;
    Motivo: string;
    ArqueosConfirmados: TArray<string>;
  end;

  TResultadoSubsanacionCaja = record
    Clave: TClaveOperacionSubsanacionCaja;
    Total: Currency;
    EncoladaVerifactu: Boolean;
    RegistradaNoVerifactu: Boolean;
  end;

  IServicioSubsanacionCaja = interface
    ['{FBC3BA3E-6AFA-4C39-A596-0C742E67A808}']
    function Cargar(const AClave: TClaveOperacionSubsanacionCaja):
      TOperacionSubsanacionCaja;
    // El usuario puede subsanar (permiso de modificar cobros de caja).
    function Permitida: Boolean;
    function Guardar(const ASolicitud: TSolicitudSubsanacionCaja):
      TResultadoSubsanacionCaja;
  end;

implementation

end.
