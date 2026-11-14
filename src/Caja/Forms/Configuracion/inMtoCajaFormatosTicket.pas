{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaFormatosTicket                                       }
{    Tipo:       Adaptador visual                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formatos FastReport del ticket de caja: data module de impresión de       }
{    facturas listo para usar y edición de los formatos 'Ticket...' desde      }
{    Parámetros de caja, igual que el botón Editar de imprimir factura pero    }
{    con el selector limitado a los formatos de ticket.                        }
{******************************************************************************}
unit inMtoCajaFormatosTicket;

interface

uses
  System.Classes, Uni, UniDataFacturas, inLibParametrosIntf,
  inLibPreviewTicket, inLibReimpresionOperacionCaja;

type
  // Ticket con el formato FastReport del parámetro vgerFormatoTicket,
  // impreso como imagen. Lo usan el cobro y la reimpresión.
  TTicketFormatoCajaVcl = class(TInterfacedObject, ITicketFormatoCaja)
  private
    FConexion: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    FPreview: IPreviewTicket;
    function Formato: string;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosCaja: IParametrosCaja;
      const APreview: IPreviewTicket);
    function TieneFormato: Boolean;
    function Imprimir(
      const ASerie, ANumero, ANombreImpresora: string;
      ARutasPdf: TStrings): Boolean;
  end;

function CrearTicketFormatoCaja(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APreview: IPreviewTicket): ITicketFormatoCaja;

function CrearDatosImpresionFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja): TdmFacturas;

procedure EditarFormatosTicket(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja);

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Forms, Vcl.Dialogs,
  Datasnap.DBClient,
  inMtoModalImpFac, inLibCajaParam, inLibFacturasComposicion,
  inLibMensajesVcl, inLibFTicket, inLibTicketImagenFR, inLibTicketLotes,
  inLibDir,
  inLibGenerarTicketIntf, UniDataGenerarTicketRepositorio,
  UniDataFacturasRepositorio,
  UniDataFacturasLecturas,
  UniDataFacturasOperaciones,
  UniDataArticulosResolverRepositorio,
  UniDataVerifactuColaRepositorio;

resourcestring
  SFormatoTicketNoEncontrado =
    'No se encuentra el formato de ticket "%s".';
  SFormatoTicketSinPaginas =
    'El formato de ticket "%s" no ha generado ninguna página.';
  SAvisoTicketFastReport =
    'No se pudo imprimir el ticket con el formato "%s": %s' + sLineBreak +
    'Se imprime el ticket de texto.';

function CrearTicketFormatoCaja(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APreview: IPreviewTicket): ITicketFormatoCaja;
begin
  Result := TTicketFormatoCajaVcl.Create(
    AConexion, AParametrosCaja, APreview);
end;

constructor TTicketFormatoCajaVcl.Create(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APreview: IPreviewTicket);
begin
  inherited Create;
  FConexion := AConexion;
  FParametrosCaja := AParametrosCaja;
  FPreview := APreview;
end;

function TTicketFormatoCajaVcl.Formato: string;
begin
  Result := '';
  if Assigned(FParametrosCaja) then
    Result := Trim(FParametrosCaja.GetString(cParametroFormatoTicket, ''));
end;

function TTicketFormatoCajaVcl.TieneFormato: Boolean;
begin
  Result := Formato <> '';
end;

function TTicketFormatoCajaVcl.Imprimir(
  const ASerie, ANumero, ANombreImpresora: string;
  ARutasPdf: TStrings): Boolean;
var
  DatosFactura: TdmFacturas;
  Formulario: TfrmPrintFac;
  Ticket: TTicketTermico;
  LineasTicket: TClientDataSet;
  oLecturas: ILecturasImpresionTicket;
  sCodigoBarras: string;
  sFormato: string;
  sRutaPdf: string;
begin
  Result := False;
  sFormato := Formato;
  if (sFormato <> '') and (Trim(ANumero) <> '') then
  begin
    Formulario := nil;
    DatosFactura := nil;
    LineasTicket := nil;
    try
      try
        DatosFactura := CrearDatosImpresionFactura(
          nil, FConexion, FParametrosCaja);
        Formulario := TfrmPrintFac.Create(Application);
        Formulario.edtSerie.Text := ASerie;
        Formulario.edtNroFac.Text := ANumero;
        Formulario.ConfigurarDataModule(DatosFactura);
        Formulario.preparar_consulta;
        if not Formulario.SeleccionarFormatoSinDialogo(sFormato) then
          raise Exception.CreateFmt(SFormatoTicketNoEncontrado, [sFormato]);
        LineasTicket := PrepararLineasTicket(
          DatosFactura.unqryLinFacPrint,
          FParametrosCaja.GetBool(PARAMETRO_IMPRIMIR_LOTES_TICKET, True));
        DatosFactura.fxdstPrintLinFac.DataSet := LineasTicket;
        DatosFactura.fxdstPrintLinFac.ResetFieldDefs;
        // AfterReportLoaded rellena 'qrverifactu' solo con Verifactu activo.
        if not Formulario.PrepararPaginasSinImprimir then
          raise Exception.CreateFmt(SFormatoTicketSinPaginas, [sFormato]);
        sCodigoBarras := '';
        if FParametrosCaja.GetBool('vgerImprimirCodBarrasTicket', False) then
        begin
          oLecturas := CrearLecturasImpresionTicket(FConexion);
          sCodigoBarras := oLecturas.ObtenerCodigoBarras(ASerie, ANumero);
        end;
        Ticket := TTicketTermico.Create(ANombreImpresora);
        try
          Ticket.Inicializar;
          if not ComponerTicketDesdeInforme(
            Formulario.frxrprt1, Ticket, True, sCodigoBarras) then
            raise Exception.CreateFmt(SFormatoTicketSinPaginas, [sFormato]);
          sRutaPdf := GetUserFolderTickets + 'Ticket_' +
            FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
          // Impresora DEBUG o vacía: vista previa en lugar de impresión.
          ImprimirOPrevisualizarTicket(FPreview, Ticket,
            Ticket.ObtenerComandos, sRutaPdf, ANombreImpresora);
          if (ARutasPdf <> nil) and FileExists(sRutaPdf) then
            ARutasPdf.Add(sRutaPdf);
          Result := True;
        finally
          FreeAndNil(Ticket);
        end;
      except
        on E: Exception do
          MessageDlg_fza(
            Format(SAvisoTicketFastReport, [sFormato, E.Message]),
            mtWarning, [mbOK], 0);
      end;
    finally
      FreeAndNil(Formulario);
      FreeAndNil(DatosFactura);
      FreeAndNil(LineasTicket);
    end;
  end;
end;

function CrearDatosImpresionFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja): TdmFacturas;
begin
  Result := TdmFacturas.Create(AOwner);
  try
    Result.ConfigurarServicios(
      CrearServiciosFactura(
        AConexion,
        TRepositorioFacturas.Create(AConexion),
        CrearRepositorioLecturasFacturaUniDAC(AConexion),
        CrearPersistenciaFacturasUniDAC(AConexion),
        TRepositorioArticulosResolver.Create(
          AConexion,
          AParametrosCaja),
        CrearServicioVerifactuColaUniDAC(AConexion)));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure EditarFormatosTicket(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja);
var
  DatosFactura: TdmFacturas;
  Formulario: TfrmPrintFac;
begin
  Formulario := nil;
  DatosFactura := CrearDatosImpresionFactura(nil, AConexion, AParametrosCaja);
  try
    Formulario := TfrmPrintFac.Create(Application);
    Formulario.PrefijoFormatos := cPrefijoFormatoTicket;
    Formulario.ConfigurarDataModule(DatosFactura);
    // Mismo flujo que el botón Editar: campos extra, selector y diseñador.
    Formulario.btnEditarClick(Formulario.btnEditar);
  finally
    FreeAndNil(Formulario);
    FreeAndNil(DatosFactura);
  end;
end;

end.
