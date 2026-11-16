{******************************************************************************}
{                                                                              }
{  Módulo: inLibControladorVentaTpv                                            }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 14/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Coordina venta, confirmación de cobro y salida.                }
{                                                                              }
{******************************************************************************}

unit inLibControladorVentaTpv;

interface

uses
  inLibCajaTipos, inLibTpvMvcIntf;

type
  TControladorVentaTpv = class
  private
    class function PrepararCredito(AEsClienteVarios: Boolean;
      const AInteraccion: TInteraccionCreditoTpv): Boolean; static;
  public
    class function RechazoFactura(const AEstado: TEstadoFacturaTpv):
      TRechazoFacturaTpv; static;
    class procedure ConfirmarFactura(const AEstado: TEstadoFacturaTpv;
      const AInteraccion: TInteraccionFacturaTpv); static;
    class function RechazoCredito(const AEstado: TEstadoCreditoTpv):
      TRechazoCreditoTpv; static;
    class procedure DejarEnCuenta(const AEstado: TEstadoCreditoTpv;
      const AInteraccion: TInteraccionCreditoTpv); static;
    class function CerrarVenta(
      const AModelo: IModeloPreparacionVentaTpv;
      const AInteraccion: TInteraccionCierreVentaTpv): Boolean; static;
    class procedure ConfirmarCobro(ATipo: TTipoImpresionVenta;
      AEsSubsanacion: Boolean;
      const AInteraccion: TInteraccionConfirmacionCobroTpv); static;
    class function IntentarSalir(const AEstado: TEstadoSalidaTpv;
      const AInteraccion: TInteraccionSalidaTpv): Boolean; static;
  end;

implementation

uses
  inLibMsgCaja,
  System.SysUtils, inLibDocumentoFiscal;

class function TControladorVentaTpv.RechazoFactura(
  const AEstado: TEstadoFacturaTpv): TRechazoFacturaTpv;
begin
  Result := rfNinguno;
  if AEstado.EsSubsanacion then
    Result := rfSubsanacion
  else if AEstado.RectificaA <> '' then
    Result := rfRectificativa
  else if (Trim(AEstado.CodigoCliente) = '') or
          (Trim(AEstado.CodigoCliente) = '0') then
    Result := rfSinCliente
  else if Trim(AEstado.NifCliente) = '' then
    Result := rfSinNif
  else if PaisEsEspana(AEstado.CodigoPais, AEstado.NombrePais) and
          not DocumentoFiscalValido(AEstado.NifCliente) then
    Result := rfDocumentoInvalido;
end;

class procedure TControladorVentaTpv.ConfirmarFactura(
  const AEstado: TEstadoFacturaTpv;
  const AInteraccion: TInteraccionFacturaTpv);
var
  oRechazo: TRechazoFacturaTpv;
begin
  if not Assigned(AInteraccion.Avisar) or
     not Assigned(AInteraccion.ValidarCobro) or
     not Assigned(AInteraccion.RecalcularComoFactura) or
     not Assigned(AInteraccion.SolicitarDocumento) or
     not Assigned(AInteraccion.Aceptar) then
    raise EArgumentException.Create(STextoInteraccionDeFacturaIncompletaCaja);
  oRechazo := RechazoFactura(AEstado);
  if oRechazo = rfNinguno then
  begin
    if AInteraccion.ValidarCobro() and
       AInteraccion.RecalcularComoFactura() and
       AInteraccion.SolicitarDocumento() then
      AInteraccion.Aceptar();
  end
  else if oRechazo <> rfSubsanacion then
    AInteraccion.Avisar(oRechazo);
end;

class function TControladorVentaTpv.RechazoCredito(
  const AEstado: TEstadoCreditoTpv): TRechazoCreditoTpv;
begin
  Result := rcNinguno;
  if AEstado.EsSubsanacion then
    Result := rcSubsanacion
  else if not AEstado.PuedeDejarEnCuenta then
    Result := rcNoPermitido
  else if (AEstado.ImportePendiente <= 0) and
          not AEstado.EsDevolucion and (AEstado.ImporteTotal > 0) then
    Result := rcSinPendiente
  else if AEstado.EsClienteVarios and (AEstado.ImporteEntregado <= 0) then
    Result := rcSinEntrega;
end;

class function TControladorVentaTpv.PrepararCredito(
  AEsClienteVarios: Boolean;
  const AInteraccion: TInteraccionCreditoTpv): Boolean;
begin
  Result := AInteraccion.ValidarDeposito();
  if Result and AEsClienteVarios then
    Result := AInteraccion.PedirContacto();
  if not Result then
    AInteraccion.ActualizarVista();
end;

class procedure TControladorVentaTpv.DejarEnCuenta(
  const AEstado: TEstadoCreditoTpv;
  const AInteraccion: TInteraccionCreditoTpv);
var
  oRechazo: TRechazoCreditoTpv;
begin
  if not Assigned(AInteraccion.Avisar) or
     not Assigned(AInteraccion.ValidarDeposito) or
     not Assigned(AInteraccion.PedirContacto) or
     not Assigned(AInteraccion.EstablecerCredito) or
     not Assigned(AInteraccion.ActualizarVista) or
     not Assigned(AInteraccion.ConfirmarConTicket) then
    raise EArgumentException.Create(STextoInteraccionDeCreditoIncompletaCaja);
  oRechazo := RechazoCredito(AEstado);
  if oRechazo = rcNinguno then
  begin
    if PrepararCredito(AEstado.EsClienteVarios, AInteraccion) and
       AInteraccion.EstablecerCredito() then
    begin
      AInteraccion.ActualizarVista();
      AInteraccion.ConfirmarConTicket();
    end;
  end
  else if oRechazo <> rcSubsanacion then
    AInteraccion.Avisar(oRechazo);
end;

class function TControladorVentaTpv.CerrarVenta(
  const AModelo: IModeloPreparacionVentaTpv;
  const AInteraccion: TInteraccionCierreVentaTpv): Boolean;
var
  iPendiente: Integer;
  oResultado: TResultadoGrabacionTpv;
begin
  if AModelo = nil then
    raise EArgumentNilException.Create('AModelo');
  if not Assigned(AInteraccion.PrepararCobro) or
     not Assigned(AInteraccion.AplicarCobro) or
     not Assigned(AInteraccion.ConfirmarArqueo) or
     not Assigned(AInteraccion.Grabar) or
     not Assigned(AInteraccion.PresentarResultado) then
    raise EArgumentException.Create(STextoInteraccionDeCierreIncompletaCaja);
  Result := False;
  oResultado := Default(TResultadoGrabacionTpv);
  iPendiente := AModelo.LocalizarAtributoPendiente;
  if (iPendiente > 0) and Assigned(AInteraccion.EnfocarAtributo) then
    AInteraccion.EnfocarAtributo(iPendiente);
  try
    if (iPendiente = 0) and AModelo.ApartarDepositos and
       AModelo.PrepararLineas and AInteraccion.PrepararCobro() then
    begin
      AInteraccion.AplicarCobro();
      if AInteraccion.ConfirmarArqueo() then
      begin
        oResultado := AInteraccion.Grabar();
        Result := oResultado.IntentoCompletado;
      end;
      // Una venta confirmada no se restaura aunque falle su presentación.
      if oResultado.Grabada then
        AInteraccion.PresentarResultado();
    end;
  finally
    if not oResultado.Grabada then
      AModelo.RestaurarDepositos;
  end;
end;

class procedure TControladorVentaTpv.ConfirmarCobro(
  ATipo: TTipoImpresionVenta; AEsSubsanacion: Boolean;
  const AInteraccion: TInteraccionConfirmacionCobroTpv);
var
  bAceptado: Boolean;
begin
  if not Assigned(AInteraccion.ValidarCobro) or
     not Assigned(AInteraccion.ValidarSubsanacion) or
     not Assigned(AInteraccion.RecalcularComoTicket) or
     not Assigned(AInteraccion.AutorizarEmision) or
     not Assigned(AInteraccion.Aceptar) then
    raise EArgumentException.Create(STextoInteraccionDeCobroIncompletaCaja);
  // La factura completa conserva su selección propia de serie y fecha.
  if (ATipo in [tiConTicket, tiSinTicket, tiTicketRegalo]) and
     not (AEsSubsanacion and (ATipo = tiTicketRegalo)) then
  begin
    bAceptado := AInteraccion.ValidarCobro();
    if bAceptado then
    begin
      if AEsSubsanacion then
        bAceptado := AInteraccion.ValidarSubsanacion()
      else
        bAceptado := AInteraccion.RecalcularComoTicket() and
          AInteraccion.AutorizarEmision();
    end;
    if bAceptado then
      AInteraccion.Aceptar(ATipo);
  end;
end;

class function TControladorVentaTpv.IntentarSalir(
  const AEstado: TEstadoSalidaTpv;
  const AInteraccion: TInteraccionSalidaTpv): Boolean;
begin
  if not Assigned(AInteraccion.CerrarSubsanacion) or
     not Assigned(AInteraccion.Mostrar) or
     not Assigned(AInteraccion.ConfirmarAbandono) or
     not Assigned(AInteraccion.CancelarEdicion) or
     not Assigned(AInteraccion.Cerrar) then
    raise EArgumentException.Create(STextoInteraccionDeSalidaIncompletaCaja);
  Result := True;
  if AEstado.EsSubsanacion then
    Result := AInteraccion.CerrarSubsanacion()
  else if not AEstado.EnDestruccion then
  begin
    if AEstado.HayLineas then
    begin
      if not AEstado.EsVisible then
        AInteraccion.Mostrar();
      Result := AInteraccion.ConfirmarAbandono();
      if Result then
        AInteraccion.CancelarEdicion();
    end;
    if Result then
      AInteraccion.Cerrar();
  end;
end;

end.
