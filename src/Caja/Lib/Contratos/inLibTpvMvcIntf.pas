{******************************************************************************}
{                                                                              }
{  Módulo: inLibTpvMvcIntf                                                     }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 14/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Contratos del flujo de venta y cobro del TPV.                  }
{                                                                              }
{******************************************************************************}

unit inLibTpvMvcIntf;

interface

uses
  System.SysUtils, inLibCajaTipos;

type
  IModeloPreparacionVentaTpv = interface
    ['{9FCD4BE1-278B-4973-BDA6-4213C53B2449}']
    function LocalizarAtributoPendiente: Integer;
    function ApartarDepositos: Boolean;
    function PrepararLineas: Boolean;
    procedure RestaurarDepositos;
  end;

  TResultadoGrabacionTpv = record
    IntentoCompletado: Boolean;
    Grabada: Boolean;
  end;

  // Referencias prestadas a la sesión visual, válidas durante Ejecutar.
  TInteraccionCierreVentaTpv = record
    EnfocarAtributo: TProc<Integer>;
    PrepararCobro: TFunc<Boolean>;
    AplicarCobro: TProc;
    ConfirmarArqueo: TFunc<Boolean>;
    Grabar: TFunc<TResultadoGrabacionTpv>;
    PresentarResultado: TProc;
  end;

  TInteraccionConfirmacionCobroTpv = record
    ValidarCobro: TFunc<Boolean>;
    ValidarSubsanacion: TFunc<Boolean>;
    RecalcularComoTicket: TFunc<Boolean>;
    AutorizarEmision: TFunc<Boolean>;
    Aceptar: TProc<TTipoImpresionVenta>;
  end;

  TEstadoFacturaTpv = record
    EsSubsanacion: Boolean;
    RectificaA: string;
    ImporteTotal: Currency;
    CodigoCliente: string;
    NifCliente: string;
    CodigoPais: string;
    NombrePais: string;
  end;

  TRechazoFacturaTpv = (rfNinguno, rfSubsanacion, rfRectificativa,
    rfSinCliente, rfSinNif, rfDocumentoInvalido, rfTotalNoPositivo);

  TInteraccionFacturaTpv = record
    Avisar: TProc<TRechazoFacturaTpv>;
    ValidarCobro: TFunc<Boolean>;
    RecalcularComoFactura: TFunc<Boolean>;
    SolicitarDocumento: TFunc<Boolean>;
    Aceptar: TProc;
  end;

  TEstadoCreditoTpv = record
    EsSubsanacion: Boolean;
    PuedeDejarEnCuenta: Boolean;
    EsClienteVarios: Boolean;
    ImportePendiente: Currency;
    ImporteTotal: Currency;
    ImporteEntregado: Currency;
    ImporteDevolucion: Currency;
    ImporteExcesoSinCambio: Currency;
  end;

  TRechazoCreditoTpv = (rcNinguno, rcSubsanacion, rcNoPermitido,
    rcSinPendiente, rcSinEntrega, rcTotalNoPositivo,
    rcExcesoSinCambio, rcExcesoEntregado);

  TInteraccionCreditoTpv = record
    Avisar: TProc<TRechazoCreditoTpv>;
    ConfirmarAplicacionDevolucion: TFunc<Currency, Currency, Boolean>;
    ValidarDeposito: TFunc<Boolean>;
    PedirContacto: TFunc<Boolean>;
    EstablecerCredito: TFunc<Boolean>;
    ActualizarVista: TProc;
    ConfirmarConTicket: TProc;
  end;

  TEstadoSalidaTpv = record
    EsSubsanacion: Boolean;
    EnDestruccion: Boolean;
    HayLineas: Boolean;
    EsVisible: Boolean;
  end;

  TInteraccionSalidaTpv = record
    CerrarSubsanacion: TFunc<Boolean>;
    Mostrar: TProc;
    ConfirmarAbandono: TFunc<Boolean>;
    CancelarEdicion: TProc;
    Cerrar: TProc;
  end;

implementation

end.
