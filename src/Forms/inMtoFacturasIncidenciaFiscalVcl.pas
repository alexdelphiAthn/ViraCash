{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasIncidenciaFiscalVcl                              }
{    Tipo:       Presentación VCL                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Integra la resolución de incidencias fiscales en Factura Venta Mayor.     }
{******************************************************************************}
unit inMtoFacturasIncidenciaFiscalVcl;
interface
uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  cxButtons,
  inLibFacturasIncidenciaFiscalIntf,
  inLibFacturasServiciosIntf;
type
  // Dependencias de la corrección guiada de un rechazo de la AEAT
  TCorreccionRechazoAeatVcl = record
    Reapertura: IServicioReaperturaBorrador;
    Usuario: string;
    // Lleva al usuario a la pestaña del cliente si el error es suyo
    IrADatosCliente: TProc;
  end;
procedure ActualizarBotonResolverIncidenciaVcl(
  ABoton: TcxButton;
  const ATipoFactura: string;
  AConsolidacion: TDataSet;
  AFacturas: TDataSet);
procedure ResolverIncidenciaVerifactuVcl(
  AOwner: TComponent;
  ABoton: TcxButton;
  AFacturas: TDataSet;
  const AServicio: IServicioIncidenciaFiscalFactura;
  const ACorreccion: TCorreccionRechazoAeatVcl);
implementation
uses
  inLibFormatoDocumento,
  inLibMensajesVcl,
  System.UITypes,
  Vcl.Dialogs,
  inLibFacturasIncidenciaFiscal,
  inLibMsgFacturas,
  inLibMsgVerifactu,
  inMtoModalResolverIncidenciaVerifactu;
function FaseFactura(AFacturas: TDataSet): string;
begin
  Result := '';
  if Assigned(AFacturas) and AFacturas.Active and
     (not AFacturas.IsEmpty) and
     Assigned(AFacturas.FindField('FASE_FAC')) then
    Result := AFacturas.FieldByName('FASE_FAC').AsString;
end;
procedure ActualizarBotonResolverIncidenciaVcl(
  ABoton: TcxButton;
  const ATipoFactura: string;
  AConsolidacion: TDataSet;
  AFacturas: TDataSet);
var
  sEstadoRegistro: string;
  sEstadoSubsanacion: string;
begin
  ABoton.Visible := EsFacturaRechazadaAeat(
    FaseFactura(AFacturas),
    ATipoFactura);
  if (not ABoton.Visible) and
     SameText(ATipoFactura, 'NORMAL') and
     Assigned(AConsolidacion) and
     AConsolidacion.Active and
     (not AConsolidacion.IsEmpty) then
  begin
    sEstadoRegistro := AConsolidacion.FieldByName(
      'ESTADO_FACCON').AsString;
    sEstadoSubsanacion := '';
    if Assigned(AConsolidacion.FindField(
       'ESTADO_SUBSANACION')) then
      sEstadoSubsanacion := AConsolidacion.FieldByName(
        'ESTADO_SUBSANACION').AsString;
    ABoton.Visible :=
      PuedeResolverIncidenciaFiscal(
        sEstadoRegistro,
        sEstadoSubsanacion,
        True);
  end;
end;
procedure CorregirRechazoAeatVcl(
  AFacturas: TDataSet;
  const AServicio: IServicioIncidenciaFiscalFactura;
  const ACorreccion: TCorreccionRechazoAeatVcl;
  const ASerie, ANumero: string);
var
  Datos: TDatosIncidenciaFiscal;
  Validacion: TResultadoOperacionFactura;
  bDestinatario: Boolean;
  sMensaje: string;
begin
  // La AEAT no tiene el registro: no hay nada que subsanar ni rectificar.
  // Se anula el envío y la factura vuelve a BORRADOR para relanzarla.
  Validacion := ACorreccion.Reapertura.Validar(ASerie, ANumero);
  if not Validacion.Exito then
    ShowMessage_fza(Validacion.Mensaje)
  else
  begin
    Datos := AServicio.CargarIncidencia(ASerie, ANumero);
    if MessageDlg_fza(
         FormatearMensajeDocumentos(
           Datos.FormatoDocumento,
           SPreguntaCorregirRechazoAeat, [ASerie, ANumero,
           DescribirRechazoAeat(Datos.CodigoError,
             Datos.DescripcionError)]),
         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      try
        ACorreccion.Reapertura.Reabrir(
          ASerie,
          ANumero,
          ACorreccion.Usuario);
        AFacturas.Refresh;
        bDestinatario := EsRechazoAeatDestinatario(
          Datos.DescripcionError);
        sMensaje := FormatearMensajeDocumentos(
          Datos.FormatoDocumento,
          SInfoBorradorReabierto, [ASerie, ANumero]);
        if bDestinatario then
          sMensaje := sMensaje + sLineBreak + sLineBreak +
            SInfoRechazoAeatDestinatario;
        sMensaje := sMensaje + sLineBreak + sLineBreak +
          SAvisoReimprimirRechazoAeat;
        ShowMessage_fza(sMensaje);
        if bDestinatario and Assigned(ACorreccion.IrADatosCliente) then
          ACorreccion.IrADatosCliente();
      except
        on E: EReaperturaBorrador do
          ShowMessage_fza(E.Message);
      end;
    end;
  end;
end;
procedure ResolverIncidenciaVerifactuVcl(
  AOwner: TComponent;
  ABoton: TcxButton;
  AFacturas: TDataSet;
  const AServicio: IServicioIncidenciaFiscalFactura;
  const ACorreccion: TCorreccionRechazoAeatVcl);
var
  Resultado: TResultadoResolucionIncidenciaFiscal;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(AFacturas) and AFacturas.Active and
     (not AFacturas.IsEmpty) then
  begin
    sSerie := AFacturas.FieldByName('SERIE_FAC').AsString;
    sNumero := AFacturas.FieldByName('NUMERO_FAC').AsString;
    if SameText(Trim(FaseFactura(AFacturas)),
                cFaseFacturaRechazadaAeat) then
      CorregirRechazoAeatVcl(AFacturas, AServicio, ACorreccion,
        sSerie, sNumero)
    else
    begin
      Resultado := TfrmModalResolverIncidenciaVerifactu.Ejecutar(
        AOwner,
        AServicio,
        sSerie,
        sNumero);
      if Resultado.EsCorrecto then
      begin
        ShowMessage_fza(Resultado.Mensaje);
        AFacturas.Refresh;
        ABoton.Visible := False;
      end;
    end;
  end;
end;
end.
