{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaImpresorVenta                                        }
{    Tipo:       Adaptador visual                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador VCL para imprimir tickets y facturas de una venta de caja.      }
{******************************************************************************}
unit inMtoCajaImpresorVenta;

interface

uses
  System.Classes, Uni, inLibParametrosIntf, inLibPermisosIntf,
  inLibCajaTipos, inLibCajaVentaIntf, inLibTicketsCajaIntf,
  inLibUnidadesMedida, inLibPreviewTicket, inLibGenerarTicketIntf;

type
  TImpresorVentaVcl = class(TInterfacedObject, IImpresorVenta)
  private
    FPropietario: TComponent;
    FParametrosApp: IParametrosAplicacion;
    FConexion: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    FPermisos: IPermisosAplicacion;
    FRepositorioTicketsCaja: IRepositorioTicketsVentaCaja;
    FUnidadesMedida: TUnidadesMedida;
    FPreviewTicket: IPreviewTicket;
    FLecturasImpresionTicket: ILecturasImpresionTicket;
    procedure ImprimirFacturaA4(
      const ASerie, ANumero: string);
    // Ticket con el formato FastReport del parámetro vgerFormatoTicket,
    // impreso como imagen. False si no hay formato o no se pudo emitir
    // (el llamador imprime entonces el ticket de texto).
    function ImprimirTicketFastReport(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings): Boolean;
  public
    constructor Create(
      APropietario: TComponent;
      const AParametrosApp: IParametrosAplicacion;
      AConexion: TUniConnection;
      const AParametrosCaja: IParametrosCaja;
      const APermisos: IPermisosAplicacion;
      const ARepositorioTicketsCaja: IRepositorioTicketsVentaCaja;
      AUnidades: TUnidadesMedida;
      const APreviewTicket: IPreviewTicket);
    procedure Imprimir(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
    procedure GenerarPdfRespaldo(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
  end;

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMensajesVcl,
  System.SysUtils, System.UITypes, Data.DB, Vcl.Forms, Vcl.Dialogs,
  UniDataFacturas, inMtoModalImpFac,
  inLibCorreoTickets,
  inLibGenerarTicket, inLibGenerarTicketBD, inLibGenerarTicketCaja,
  inLibDir, inLibFacturasComposicion,
  // Raiz de composicion de este servicio: los adaptadores UniData* se
  // construyen aqui y se inyectan en la factoria de dominio.
  UniDataFacturasRepositorio,
  UniDataFacturasLecturas,
  UniDataFacturasOperaciones,
  UniDataArticulosResolverRepositorio,
  UniDataVerifactuColaRepositorio,
  UniDataGenerarTicketRepositorio,
  inLibCajaParam, inLibFTicket, inLibTicketImagenFR,
  inLibTicketLotes, Datasnap.DBClient,
  inMtoCajaFormatosTicket;

constructor TImpresorVentaVcl.Create(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const ARepositorioTicketsCaja: IRepositorioTicketsVentaCaja;
  AUnidades: TUnidadesMedida;
  const APreviewTicket: IPreviewTicket);
begin
  inherited Create;
  FPropietario := APropietario;
  FParametrosApp := AParametrosApp;
  FConexion := AConexion;
  FParametrosCaja := AParametrosCaja;
  FPermisos := APermisos;
  FRepositorioTicketsCaja := ARepositorioTicketsCaja;
  FUnidadesMedida := AUnidades;
  FPreviewTicket := APreviewTicket;
  FLecturasImpresionTicket := CrearLecturasImpresionTicket(FConexion);
end;

function TImpresorVentaVcl.ImprimirTicketFastReport(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings): Boolean;
begin
  Result := ASolicitud.DatosCobro.FRequiereFactura and
    CrearTicketFormatoCaja(
      FConexion, FParametrosCaja, FPreviewTicket).Imprimir(
        ASolicitud.SerieFactura,
        ASolicitud.NumeroFactura,
        FParametrosCaja.ImpresoraCaja,
        ARutasPdf);
end;

procedure TImpresorVentaVcl.ImprimirFacturaA4(
  const ASerie, ANumero: string);
var
  DatosFactura: TdmFacturas;
  Formulario: TfrmPrintFac;
  sEmailFactura: string;
  sEmailRespuesta: string;
  sNombreEmpresa: string;
  sReferencia: string;
  sRutaPdf: string;
begin
  Formulario := nil;
  DatosFactura := CrearDatosImpresionFactura(
    FPropietario, FConexion, FParametrosCaja);
  try
    Formulario := TfrmPrintFac.Create(Application);
    Formulario.edtSerie.Text := ASerie;
    Formulario.edtNroFac.Text := ANumero;
    Formulario.ConfigurarDataModule(DatosFactura);
    Formulario.preparar_consulta;
    sEmailFactura := '';
    sEmailRespuesta := '';
    sNombreEmpresa := '';
    if DatosFactura.unqryFacPrint.Active and
       not DatosFactura.unqryFacPrint.IsEmpty then
    begin
      sEmailFactura := Trim(
        DatosFactura.unqryFacPrint.FieldByName(
          'EMAIL_CLIENTE_FAC').AsString);
      sNombreEmpresa := Trim(
        DatosFactura.unqryFacPrint.FieldByName(
          'RAZON_SOCIAL_EMPRESA_FAC').AsString);
      sEmailRespuesta := Trim(
        DatosFactura.unqryFacPrint.FieldByName(
          'EMAIL_EMPRESA_FAC').AsString);
    end;
    sReferencia := FormatearReferenciaFactura(FConexion, ASerie, ANumero);
    Formulario.ConfigurarCorreo(
      sEmailFactura,
      function(
        const ARutaPdf, AEmail: string;
        out AMensaje: string): Boolean
      var
        oRutas: TStringList;
      begin
        oRutas := TStringList.Create;
        try
          oRutas.Add(ARutaPdf);
          Result := EnviarDocumentosPorCorreo(
            FParametrosApp,
            tdcFactura,
            sReferencia,
            sNombreEmpresa,
            AEmail,
            sEmailRespuesta,
            oRutas,
            nil,
            AMensaje);
        finally
          oRutas.Free;
        end;
      end);
    Formulario.ShowModal;
    if not FileExists(Formulario.UltimaRutaPdf) then
    begin
      sRutaPdf := GetUserFolderTickets + 'Factura_' +
        FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.pdf';
      Formulario.ExportarPdfActual(sRutaPdf);
    end;
  finally
    FreeAndNil(Formulario);
    FreeAndNil(DatosFactura);
  end;
end;

procedure TImpresorVentaVcl.Imprimir(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings);
var
  ResultadoApertura: TResultadoAperturaCajon;
begin
  case ASolicitud.TipoImpresion of
    tiConTicket:
      if not ImprimirTicketFastReport(ASolicitud, ARutasPdf) then
      begin
        ImprimirT(
          FParametrosApp,
          FPreviewTicket,
          FUnidadesMedida,
          FConexion,
          FLecturasImpresionTicket,
          ASolicitud.CodigoEmpresa,
          ASolicitud.CodigoAlmacen,
          ASolicitud.CodigoCaja,
          ASolicitud.NumeroOperacion,
          ASolicitud.DatosCobro,
          FParametrosCaja.ImpresoraCaja,
          False,
          ASolicitud.FechaOperacion,
          ARutasPdf,
          FParametrosCaja.GetBool(
            'vgerImprimirCodBarrasTicket', False),
          FParametrosCaja.GetBool(PARAMETRO_IMPRIMIR_LOTES_TICKET, True));
      end;
    tiFactura:
      begin
        ImprimirFacturaA4(
          ASolicitud.SerieFactura,
          ASolicitud.NumeroFactura);
      end;
    tiTicketRegalo:
      begin
        ImprimirT(
          FParametrosApp,
          FPreviewTicket,
          FUnidadesMedida,
          FConexion,
          FLecturasImpresionTicket,
          ASolicitud.CodigoEmpresa,
          ASolicitud.CodigoAlmacen,
          ASolicitud.CodigoCaja,
          ASolicitud.NumeroOperacion,
          ASolicitud.DatosCobro,
          FParametrosCaja.ImpresoraCaja,
          True,
          ASolicitud.FechaOperacion,
          nil,
          FParametrosCaja.GetBool(
            'vgerImprimirCodBarrasTicket', False),
          FParametrosCaja.GetBool(PARAMETRO_IMPRIMIR_LOTES_TICKET, True));
        ImprimirT(
          FParametrosApp,
          FPreviewTicket,
          FUnidadesMedida,
          FConexion,
          FLecturasImpresionTicket,
          ASolicitud.CodigoEmpresa,
          ASolicitud.CodigoAlmacen,
          ASolicitud.CodigoCaja,
          ASolicitud.NumeroOperacion,
          ASolicitud.DatosCobro,
          FParametrosCaja.ImpresoraCaja,
          False,
          ASolicitud.FechaOperacion,
          ARutasPdf,
          FParametrosCaja.GetBool(
            'vgerImprimirCodBarrasTicket', False),
          FParametrosCaja.GetBool(PARAMETRO_IMPRIMIR_LOTES_TICKET, True));
      end;
    tiSinTicket:
      // FZ-ISSUE-395: la apertura acompaña al cobro, así que no depende
      // del permiso de abrir el cajón sin venta, y solo se intenta si
      // algún pago es de una forma de pago que abre el cajón.
      if (not Assigned(ASolicitud.DatosCobro)) or
         ASolicitud.DatosCobro.AlgunPagoAbreCajon then
      begin
        ResultadoApertura := AbrirCajonTrasVenta(FParametrosCaja);
        if not ResultadoApertura.Correcto then
        begin
          MessageDlg_fza(
            ResultadoApertura.Mensaje,
            mtWarning,
            [mbOK],
            0);
        end;
      end;
  end;
end;

procedure TImpresorVentaVcl.GenerarPdfRespaldo(
  const ASolicitud: TSolicitudImpresionVenta;
  ARutasPdf: TStrings);
begin
  ImprimirTicketDesdeBD(
    FParametrosApp,
    FPreviewTicket,
    FUnidadesMedida,
    FRepositorioTicketsCaja,
    ASolicitud.CodigoEmpresa,
    ASolicitud.CodigoAlmacen,
    ASolicitud.CodigoCaja,
    ASolicitud.NumeroOperacion,
    'DEBUG',
    ARutasPdf,
    True,
    FParametrosCaja.GetBool(
      'vgerImprimirCodBarrasTicket', False),
    FParametrosCaja.GetBool(PARAMETRO_IMPRIMIR_LOTES_TICKET, True));
end;

end.
