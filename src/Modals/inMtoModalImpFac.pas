{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpFac                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de facturas.                                           }
{    Hereda del modal generico de impresion y prepara la consulta.             }
{******************************************************************************}
unit inMtoModalImpFac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxClass,
  frxExportBaseDialog, frxExportPDF, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls,
  cxControls, cxContainer, cxEdit, Vcl.ComCtrls, dxCore, cxDateUtils,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxRadioGroup, cxGroupBox, cxLabel,
  cxTextEdit, UniDataFacturas, DB, frxExportXLSX, MemDS,
  DBAccess, Uni, frxDesgn, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  dxSkinsCore, dxSkinBlue, JvComponentBase, JvEnterTab, dxSkinBasic,
  dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue,   dxSpreadSheet, dxSpreadSheetCore,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxHashUtils, inLibDevExcel, System.Actions, Vcl.ActnList,
  frLocalization, frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, frxSmartMemo,
  inLibInformeFacturaPersistenciaIntf, inLibComandoImprimirFacturas,
  cxCheckBox;

type
  TEnviarCorreoFactura = reference to function(
    const ARutaPdf, AEmail: string;
    out AMensaje: string): Boolean;
  TEjecutarLoteFacturas = reference to function(
    const AReferencias: TReferenciasComandoFactura;
    const AFormato: string;
    AEnviarEmail: Boolean): Boolean;
//  TObtenerLoteFacturas = reference to function:
//    TReferenciasComandoFactura;
    TObtenerLoteFacturas = TObtenerReferenciasComandoFactura;
const
  WM_INICIAR_ENVIO_EMAIL_FACTURA = WM_APP + $461;

type
  TfrmPrintFac = class(TfrmPrint)
    edtNroFac: TcxTextEdit;
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbProcesarFiltrados: TcxRadioButton;
    chkEnviarEmail: TcxCheckBox;
    procedure rbProcesarFiltradosClick(Sender: TObject);
    procedure rbActualClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject); override;
    procedure btnImprimirClick(Sender: TObject); override;
    procedure btnExcelClick(Sender: TObject);
    procedure chkEnviarEmailPropertiesEditValueChanged(Sender: TObject);
  private
    FPreparadorInforme: IPreparadorInformeFactura;
    FObtenerReferenciasFiltradas: TObtenerLoteFacturas;
    FExportarLotePdf: TEjecutarLoteFacturas;
    FImprimirLote: TEjecutarLoteFacturas;
    FEmailInicial: string;
    FEmailEnvio: string;
    FEnviarCorreo: TEnviarCorreoFactura;
    FActualizandoEmail: Boolean;
    FEnvioEmailPendiente: Boolean;
    FProcesandoEnvioEmail: Boolean;
    procedure AplicarModoSeleccionado;
    procedure ActualizarDisponibilidadCorreo;
    procedure BloquearAccionesCorreo;
    procedure DesmarcarEnvioEmail;
    function SolicitarEmailIndividual: Boolean;
    function ValidarConfiguracionCorreo: Boolean;
    procedure IniciarEnvioEmail;
    procedure EjecutarEnvioEmailConfigurado;
    procedure EnviarPdfPorCorreo(const ARutaPdf: string);
    procedure EnviarCorreoIndividualPreparado;
    procedure WMIniciarEnvioEmailFactura(
      var Message: TMessage); message WM_INICIAR_ENVIO_EMAIL_FACTURA;
    function PrepararLote(
      const AAccion: TEjecutarLoteFacturas;
      AEnviarEmail: Boolean): Boolean;
    function IntentarObtenerReferenciasLote(
      out AReferencias: TReferenciasComandoFactura): Boolean;
    procedure AjustarSujetosFactura(ABanda: TfrxBand);
    procedure AplicarFormaPagoReport(AReport: TfrxReport);
  protected
    procedure PrepararDatosEdicion; override;
    procedure AvisarAntesDeConsulta; override;
    function TraducirContenidoInforme: Boolean; override;
    procedure PdfExportado(const ARuta: string); override;
    procedure ReportBeforePrintFactura(
      Component: TfrxReportComponent);
  public
    class procedure ArchivarFacturaConsolidada(
      ADataModule: TdmFacturas;
      const ASerie, ANumero: string); static;
    procedure preparar_consulta; override;
    procedure AvisarReferenciasAusentes(const ASerie, ANumero: string);
    procedure AfterReportLoaded; override;
    procedure ConfigurarDataModule(ADataModule: TdmFacturas);
    procedure ConfigurarNombrePDF;
    procedure ConfigurarLote(
      APuedeUsarActual: Boolean;
      const AObtenerFiltradas: TObtenerLoteFacturas;
      const AExportarPdf, AImprimir: TEjecutarLoteFacturas);
    procedure ConfigurarCorreo(
      const AEmailInicial: string;
      const AEnviarCorreo: TEnviarCorreoFactura);
    function ObtenerNombreFactura(ADataSet: TDataSet): string;
    procedure AplicarSkuDescripcionReport(AReport: TfrxReport);
  public
    dmFac: TdmFacturas;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inMtoPreviewExcel, inLibFacturaExcel, inLibVerifactu,
  inLibFormatoDocumento, inLibVentasWsCola, inLibFacturaPdfBlob,
  inLibDir, inLibFacturasPersistenciaIntf,
  UniDataFacturasOperaciones, UniDataVentasWsCola,
  UniDataInformeFacturaRepositorio, inLibMsgFacturas,
  inLibCorreoTickets, inLibCorreoDocumentoVcl, inLibInformeDocumento,
  UniDataTicketFacturaImpresion, UniDataFacturasConfiguracion,
  inLibTrazabilidad, inLibMsgTrazabilidad;

resourcestring
  SErrorServicioCorreoFacturaNoDisponible =
    'No está disponible el servicio de envío de facturas por correo.';
  SInfoFacturaEnviadaCorreo =
    'Factura enviada por correo electrónico a %s.';
  SErrorFacturaNoEnviadaCorreo =
    'No se pudo enviar la factura por correo electrónico.';
  SErrorPdfTemporalCorreoFactura =
    'No se pudo generar el PDF temporal para enviar la factura por ' +
    'correo electrónico.';

{ TfrmPrintFac }

procedure TfrmPrintFac.ConfigurarDataModule(ADataModule: TdmFacturas);
begin
  dmFac := ADataModule;
  if dmFac <> nil then
  begin
    // 'Ticket' y 'Pagos Ticket' para los formatos de ticket (factura
    // simplificada impresa desde el TPV); antes del rebind para publicarlos.
    AsegurarDatosTicketImpresion(dmFac,
      TUniConnection(dmFac.unqryFacPrint.Connection));
    // Se enlaza tambien la plantilla origen antes de cualquier AssignAll.
    // Asi, tanto el formato predeterminado como los formatos guardados se
    // cargan dentro del ambito local del data module de esta instancia.
    RebindReportDataSetsByDataModule(frxReportOrigen, dmFac);
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  end;
end;

procedure TfrmPrintFac.ConfigurarCorreo(
  const AEmailInicial: string;
  const AEnviarCorreo: TEnviarCorreoFactura);
begin
  FEmailInicial := Trim(AEmailInicial);
  FEmailEnvio := '';
  FEnviarCorreo := AEnviarCorreo;
  ActualizarDisponibilidadCorreo;
end;

procedure TfrmPrintFac.ActualizarDisponibilidadCorreo;
var
  bCorreoLoteDisponible: Boolean;
  bCorreoModoDisponible: Boolean;
begin
  bCorreoLoteDisponible :=
    Assigned(FObtenerReferenciasFiltradas) and
    Assigned(FExportarLotePdf);
  chkEnviarEmail.Visible :=
    Assigned(FEnviarCorreo) or bCorreoLoteDisponible;
  if rbActual.Checked then
    bCorreoModoDisponible := Assigned(FEnviarCorreo)
  else
    bCorreoModoDisponible := bCorreoLoteDisponible;
  chkEnviarEmail.Enabled := bCorreoModoDisponible;
  if not bCorreoModoDisponible then
    DesmarcarEnvioEmail;
end;

procedure TfrmPrintFac.DesmarcarEnvioEmail;
begin
  FEmailEnvio := '';
  FActualizandoEmail := True;
  try
    chkEnviarEmail.Checked := False;
  finally
    FActualizandoEmail := False;
  end;
end;

procedure TfrmPrintFac.BloquearAccionesCorreo;
begin
  chkEnviarEmail.Enabled := False;
  btnPDF.Enabled := False;
  btnImprimir.Enabled := False;
  btnVistaPreliminar.Enabled := False;
  btnEditar.Enabled := False;
  btnExcel.Enabled := False;
end;

function TfrmPrintFac.SolicitarEmailIndividual: Boolean;
var
  sEmail: string;
begin
  Result := SolicitarEmailDocumento(
    Self,
    TituloEnvioDocumentoCorreo(NombreDocumentoCorreo(tdcFactura)),
    FEmailInicial,
    sEmail);
  if Result then
    FEmailEnvio := sEmail
  else
    DesmarcarEnvioEmail;
end;

procedure TfrmPrintFac.chkEnviarEmailPropertiesEditValueChanged(
  Sender: TObject);
begin
  if not FActualizandoEmail then
  begin
    if not chkEnviarEmail.Checked then
    begin
      FEnvioEmailPendiente := False;
      FEmailEnvio := ''
    end
    else if not FEnvioEmailPendiente and not FProcesandoEnvioEmail then
    begin
      FEnvioEmailPendiente := True;
      BloquearAccionesCorreo;
      if not Winapi.Windows.PostMessage(
        Handle,
        WM_INICIAR_ENVIO_EMAIL_FACTURA,
        0,
        0) then
      begin
        FEnvioEmailPendiente := False;
        DesmarcarEnvioEmail;
        AplicarModoSeleccionado;
      end;
    end;
  end;
end;

procedure TfrmPrintFac.WMIniciarEnvioEmailFactura(
  var Message: TMessage);
begin
  FEnvioEmailPendiente := False;
  if chkEnviarEmail.Checked then
    IniciarEnvioEmail
  else
    AplicarModoSeleccionado;
  Message.Result := 0;
end;

function TfrmPrintFac.ValidarConfiguracionCorreo: Boolean;
var
  sMensaje: string;
begin
  Result := CorreoTicketsConfigurado(ParametrosApp, sMensaje);
  if not Result then
    ShowMessage_fza(sMensaje)
  else if rbActual.Checked and not Assigned(FEnviarCorreo) then
  begin
    ShowMessage_fza(SErrorServicioCorreoFacturaNoDisponible);
    Result := False;
  end;
end;

procedure TfrmPrintFac.IniciarEnvioEmail;
begin
  if chkEnviarEmail.Checked and not FProcesandoEnvioEmail then
  begin
    FProcesandoEnvioEmail := True;
    BloquearAccionesCorreo;
    try
      try
        if ValidarConfiguracionCorreo then
          EjecutarEnvioEmailConfigurado;
      except
        on E: Exception do
          MessageDlg_fza(
            SErrorFacturaNoEnviadaCorreo + sLineBreak +
            E.ClassName + ': ' + E.Message,
            mtError,
            [mbOK],
            0);
      end;
    finally
      // La casilla actúa como iniciador, no como opción pendiente. También
      // se limpia tras error o cancelación para que reintentar sea marcarla.
      DesmarcarEnvioEmail;
      FProcesandoEnvioEmail := False;
      AplicarModoSeleccionado;
    end;
  end;
end;

procedure TfrmPrintFac.EjecutarEnvioEmailConfigurado;
begin
  if rbProcesarFiltrados.Checked then
  begin
    // En lote se reutiliza el flujo PDF completo: selección recordada de
    // formato, carpeta, envío por factura y TXT final. El destinatario
    // procede de cada snapshot y nunca se solicita un correo común.
    if PrepararLote(FExportarLotePdf, True) then
      ModalResult := mrOk;
  end
  else
  begin
    // Mismo comienzo que el botón PDF, pero el fichero es temporal: el
    // usuario elige la plantilla y después confirma el destinatario.
    AvisarAntesDeConsulta;
    preparar_consulta;
    Consultar_Formularios;
    if FormatoElegido <> '' then
    begin
      if SolicitarEmailIndividual then
        EnviarCorreoIndividualPreparado;
    end;
  end;
end;

procedure TfrmPrintFac.EnviarPdfPorCorreo(const ARutaPdf: string);
var
  bEnviado: Boolean;
  bPuedeEnviar: Boolean;
  sMensaje: string;
begin
  bPuedeEnviar := chkEnviarEmail.Checked and rbActual.Checked and
    Assigned(FEnviarCorreo) and (Trim(ARutaPdf) <> '');
  if bPuedeEnviar then
  begin
    bEnviado := False;
    sMensaje := '';
    try
      bEnviado := FEnviarCorreo(
        ARutaPdf,
        FEmailEnvio,
        sMensaje);
    except
      on E: Exception do
        sMensaje := E.ClassName + ': ' + E.Message;
    end;
    if bEnviado then
    begin
      if Trim(sMensaje) = '' then
        sMensaje := Format(SInfoFacturaEnviadaCorreo, [FEmailEnvio]);
      MessageDlg_fza(sMensaje, mtInformation, [mbOK], 0);
    end
    else
    begin
      if Trim(sMensaje) = '' then
        sMensaje := SErrorFacturaNoEnviadaCorreo
      else
        sMensaje := SErrorFacturaNoEnviadaCorreo + sLineBreak + sMensaje;
      MessageDlg_fza(sMensaje, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmPrintFac.EnviarCorreoIndividualPreparado;
var
  sRutaPdf: string;
begin
  sRutaPdf := CrearRutaPdfTemporalCorreo(
    tdcFactura,
    edtSerie.Text,
    edtNroFac.Text);
  try
    try
      if ExportarPdfPreparado(sRutaPdf, False) then
        EnviarPdfPorCorreo(sRutaPdf)
      else
        MessageDlg_fza(
          SErrorPdfTemporalCorreoFactura,
          mtError,
          [mbOK],
          0);
    except
      on E: Exception do
        MessageDlg_fza(
          SErrorPdfTemporalCorreoFactura + sLineBreak +
          E.ClassName + ': ' + E.Message,
          mtError,
          [mbOK],
          0);
    end;
  finally
    EliminarPdfTemporalCorreo(sRutaPdf, RegistroLog);
  end;
end;

function TfrmPrintFac.TraducirContenidoInforme: Boolean;
begin
  // Las facturas de venta son documentos fiscales para el mercado español.
  Result := False;
end;

class procedure TfrmPrintFac.ArchivarFacturaConsolidada(
  ADataModule: TdmFacturas;
  const ASerie, ANumero: string);
var
  Formulario: TfrmPrintFac;
  sRutaPdf: string;
begin
  Formulario := TfrmPrintFac.Create(Application);
  try
    Formulario.edtSerie.Text := ASerie;
    Formulario.edtNroFac.Text := ANumero;
    Formulario.dmFac := ADataModule;
    Formulario.Consultar_Formularios;
    sRutaPdf := GetUserFolderTickets + 'Factura_' +
      FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.pdf';
    if Formulario.ExportarPdfActual(sRutaPdf) then
      System.SysUtils.DeleteFile(sRutaPdf);
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmPrintFac.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  NombreSugerido: string;
begin
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    NombreSugerido := ObtenerNombreFactura(dmFac.unqryTablaG);
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName := NombreSugerido;
    try
      ExportarFacturaADevExpress(
        ParametrosApp, RegistroLog, ConexionPrincipal,
        fPreview.dxSpreadSheet1,
        dmFac.unqryTablaG,
        dmFac.unqryLinFac);
    finally
      Screen.Cursor := crDefault;
    end;
    fPreview.ShowModal;
  finally
    FreeAndNil(fPreview);
  end;
end;

procedure TfrmPrintFac.AfterReportLoaded;
var
  oGrupoOperacion: TfrxComponent;
  oObjetoQR: TfrxComponent;
  oBandaQR: TfrxComponent;
  sFaseQR: string;
  sEstadoQR: string;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  oGrupoOperacion := frxrprt1.FindObject('GroupHeaderOperacionCaja');
  if oGrupoOperacion is TfrxGroupHeader then
  begin
    // Un formato guardado puede conservar una definicion antigua del
    // dataset. Evitamos que FastReport evalue un campo inexistente y solo
    // activamos la agrupacion cuando la consulta abierta expone el ID.
    TfrxGroupHeader(oGrupoOperacion).Condition := '0';
    TfrxGroupHeader(oGrupoOperacion).Visible := False;
    if (dmFac <> nil) and dmFac.unqryLinFacPrint.Active and
       (dmFac.unqryLinFacPrint.FindField(
          'ID_OPERACION_CAJA_FACTURA') <> nil) then
    begin
      TfrxGroupHeader(oGrupoOperacion).Condition :=
        'Lineas Facturas."ID_OPERACION_CAJA_FACTURA"';
      TfrxGroupHeader(oGrupoOperacion).Visible := True;
    end;
  end;
  AplicarSkuDescripcionReport(frxrprt1);
  AplicarFormaPagoReport(frxrprt1);
  AjustarFormatoBasesFactura(frxrprt1);
  // El QR debe estar en la banda de datos para aparecer en la página
  // preparada por FastReport, incluso con un formato guardado antiguo.
  if (dmFac <> nil) and dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    PrepararImpresionFacturaVerifactu(ParametrosApp, frxrprt1,
      dmFac.unqryFacPrint);
    sFaseQR := '(sin campo)';
    if dmFac.unqryFacPrint.FindField('FASE_FAC') <> nil then
      sFaseQR := dmFac.unqryFacPrint.FieldByName('FASE_FAC').AsString;
    oObjetoQR := frxrprt1.FindObject('qrverifactu');
    if not (oObjetoQR is TfrxPictureView) then
      oObjetoQR := frxrprt1.FindObject('qr');
    oBandaQR := frxrprt1.FindObject('MasterData1');
    sEstadoQR := 'ausente';
    if oObjetoQR is TfrxPictureView then
    begin
      sEstadoQR := 'presente, padre=' + oObjetoQR.Parent.ClassName +
        ', visible=' + BoolToStr(oObjetoQR.Visible, True) +
        ', imagen=' + BoolToStr(
          TfrxPictureView(oObjetoQR).Picture.Graphic <> nil, True);
    end;
    RegistroLog.RegistrarInformacion(
      'FacturaQR/plantilla: fase=' + sFaseQR +
      ', longitud URL=' + IntToStr(Length(
        ObtenerUrlQRFactura(ParametrosApp, dmFac.unqryFacPrint))) +
      ', QR=' + sEstadoQR +
      ', banda=' + BoolToStr(
        (oBandaQR <> nil) and oBandaQR.Visible, True));
  end;
  frxrprt1.OnBeforePrint := ReportBeforePrintFactura;
end;

procedure TfrmPrintFac.ReportBeforePrintFactura(
  Component: TfrxReportComponent);
var
  oCampo: TField;
begin
  ReportBeforePrintConQR(Component);
  if Component is TfrxBand then
    AjustarSujetosFactura(TfrxBand(Component));
  if (Component is TfrxMasterData) and
     SameText(Component.Name, 'MasterData1') then
    RegistroLog.RegistrarInformacion(
      'FacturaQR/impresión: banda MasterData1 procesada');
  if (Component <> nil) and
     SameText(Component.Name, 'GroupHeaderOperacionCaja') then
  begin
    Component.Visible := False;
    if (dmFac <> nil) and dmFac.unqryLinFacPrint.Active then
    begin
      oCampo := dmFac.unqryLinFacPrint.FindField('ESFACTURA_TA_CAJA');
      if oCampo <> nil then
        Component.Visible := SameText(oCampo.AsString, 'S');
    end;
  end;
end;

// Una factura simplificada sin cliente no imprime la caja del receptor
// ni un 'NIF:' suelto; sin forma de pago no imprime 'Forma de Pago:'.
// Los objetos se reconocen por su texto, para que valga tambien con los
// formatos guardados. La banda (cabecera o pie de pagina) recibe el
// evento aunque sus objetos sueltos no.
procedure TfrmPrintFac.AjustarSujetosFactura(ABanda: TfrxBand);
var
  iObjeto: Integer;
  oMemo: TfrxMemoView;
  oRazon: TfrxMemoView;
  oDatos: TDataSet;
  sTexto: string;
  bHayNif: Boolean;
  bHayReceptor: Boolean;
  bHayFormaPago: Boolean;
begin
  oDatos := nil;
  if dmFac <> nil then
    oDatos := dmFac.unqryFacPrint;
  if (oDatos <> nil) and oDatos.Active and (not oDatos.IsEmpty) and
     (oDatos.FindField('NIF_CLIENTE_FAC') <> nil) and
     (oDatos.FindField('RAZON_SOCIAL_CLIENTE_FAC') <> nil) then
  begin
    bHayNif := Trim(oDatos.FieldByName('NIF_CLIENTE_FAC').AsString) <> '';
    bHayReceptor := bHayNif or (Trim(oDatos.FieldByName(
      'RAZON_SOCIAL_CLIENTE_FAC').AsString) <> '');
    bHayFormaPago := True;
    if oDatos.FindField('FORMA_PAGO_IMPRESION') <> nil then
      bHayFormaPago := Trim(oDatos.FieldByName(
        'FORMA_PAGO_IMPRESION').AsString) <> '';
    oRazon := nil;
    for iObjeto := 0 to ABanda.Objects.Count - 1 do
    begin
      if TObject(ABanda.Objects[iObjeto]) is TfrxMemoView then
      begin
        oMemo := TfrxMemoView(ABanda.Objects[iObjeto]);
        sTexto := oMemo.Text;
        if Pos('"RAZON_SOCIAL_CLIENTE_FAC"', sTexto) > 0 then
          oRazon := oMemo
        else if Pos('"NIF_CLIENTE_FAC"', sTexto) > 0 then
          oMemo.Visible := bHayNif
        else if SameText(Trim(sTexto), 'Receptor') then
          oMemo.Visible := bHayReceptor
        else if Pos('"FORMA_PAGO_IMPRESION"', sTexto) > 0 then
          oMemo.Visible := bHayFormaPago;
      end;
    end;
    // La caja: memo vacio con marco que contiene la razon social.
    if oRazon <> nil then
    begin
      for iObjeto := 0 to ABanda.Objects.Count - 1 do
      begin
        if TObject(ABanda.Objects[iObjeto]) is TfrxMemoView then
        begin
          oMemo := TfrxMemoView(ABanda.Objects[iObjeto]);
          if (Trim(oMemo.Text) = '') and (ftTop in oMemo.Frame.Typ) and
             (oMemo.Left <= oRazon.Left) and
             (oMemo.Left + oMemo.Width >= oRazon.Left) and
             (oMemo.Top <= oRazon.Top) and
             (oMemo.Top + oMemo.Height >= oRazon.Top) then
            oMemo.Visible := bHayReceptor;
        end;
      end;
    end;
  end;
end;

// Formatos guardados antes de FORMA_PAGO_IMPRESION: la forma de pago del
// documento o, si no tiene (simplificada de caja), la del cobro.
procedure TfrmPrintFac.AplicarFormaPagoReport(AReport: TfrxReport);
var
  oComponente: TfrxComponent;
  oMemo: TfrxMemoView;
begin
  if AReport <> nil then
  begin
    oComponente := AReport.FindObject('FormaPago');
    if oComponente is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(oComponente);
      oMemo.Memo.Text := StringReplace(oMemo.Memo.Text,
        '"DESCRIPCION_FORMA_PAGO_FP"', '"FORMA_PAGO_IMPRESION"',
        [rfReplaceAll]);
    end;
  end;
end;

procedure TfrmPrintFac.AplicarSkuDescripcionReport(AReport: TfrxReport);
var
  oComponente: TfrxComponent;
  oMemo: TfrxMemoView;
begin
  if (AReport <> nil) and (dmFac <> nil) then
  begin
    oComponente :=
      AReport.FindObject('LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA');
    if oComponente is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(oComponente);
      oMemo.DataField := 'DESCRIPCION_PRINT_FACLIN';
      oMemo.DataSet := dmFac.fxdstPrintLinFac;
      oMemo.DataSetName := 'Lineas Facturas';
      oMemo.Memo.Text := '[Lineas Facturas."DESCRIPCION_PRINT_FACLIN"]';
    end;
  end;
end;

procedure TfrmPrintFac.ConfigurarNombrePDF;
begin
  frxpdfxprtPedWeb.FileName := '';
  if (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    frxpdfxprtPedWeb.FileName :=
      ObtenerNombreFactura(dmFac.unqryFacPrint);
  end;
end;

procedure TfrmPrintFac.ConfigurarLote(
  APuedeUsarActual: Boolean;
  const AObtenerFiltradas: TObtenerLoteFacturas;
  const AExportarPdf, AImprimir: TEjecutarLoteFacturas);
begin
  FObtenerReferenciasFiltradas := AObtenerFiltradas;
  FExportarLotePdf := AExportarPdf;
  FImprimirLote := AImprimir;
  rbActual.Enabled := APuedeUsarActual;
  rbProcesarFiltrados.Enabled := Assigned(FObtenerReferenciasFiltradas);
  if rbActual.Enabled then
    rbActual.Checked := True
  else if rbProcesarFiltrados.Enabled then
    rbProcesarFiltrados.Checked := True;
  ActualizarDisponibilidadCorreo;
  AplicarModoSeleccionado;
end;

procedure TfrmPrintFac.AplicarModoSeleccionado;
var
  bActual: Boolean;
begin
  bActual := rbActual.Checked;
  btnPDF.Enabled := True;
  btnImprimir.Enabled := True;
  btnVistaPreliminar.Enabled := bActual;
  btnEditar.Enabled := bActual;
  btnExcel.Enabled := bActual;
  ActualizarDisponibilidadCorreo;
  if not bActual then
    FEmailEnvio := '';
end;

function TfrmPrintFac.IntentarObtenerReferenciasLote(
  out AReferencias: TReferenciasComandoFactura): Boolean;
begin
  AReferencias := nil;
  try
    if Assigned(FObtenerReferenciasFiltradas) then
      AReferencias := FObtenerReferenciasFiltradas();
    Result := True;
  except
    on E: Exception do
    begin
      ShowMessage_fza(E.Message);
      Result := False;
    end;
  end;
end;

function TfrmPrintFac.PrepararLote(
  const AAccion: TEjecutarLoteFacturas;
  AEnviarEmail: Boolean): Boolean;
var
  bPreparado: Boolean;
  oReferencias: TReferenciasComandoFactura;
  Referencia: TReferenciaComandoFactura;
begin
  oReferencias := nil;
  bPreparado := Assigned(AAccion);
  if not bPreparado then
    ShowMessage_fza(SErrorServicioLoteImpresionFacturas);
  if bPreparado then
  begin
    Consultar_Formularios;
    bPreparado := FormatoElegido <> '';
  end;
  if bPreparado then
    bPreparado := IntentarObtenerReferenciasLote(oReferencias);
  if bPreparado then
  begin
    bPreparado := Length(oReferencias) <> 0;
    if not bPreparado then
      ShowMessage_fza(SErrorFacturasFiltradasVacias);
  end;
  Result := bPreparado;
  if bPreparado then
  begin
    for Referencia in oReferencias do
      AvisarReferenciasAusentes(Referencia.Serie, Referencia.Numero);
    Result := AAccion(
      oReferencias,
      FormatoElegido,
      AEnviarEmail);
  end;
end;

procedure TfrmPrintFac.btnPDFClick(Sender: TObject);
begin
  if rbProcesarFiltrados.Checked then
  begin
    if PrepararLote(FExportarLotePdf, False) then
      ModalResult := mrOk;
  end
  else
    inherited btnPDFClick(Sender);
end;

procedure TfrmPrintFac.btnImprimirClick(Sender: TObject);
begin
  if rbProcesarFiltrados.Checked then
  begin
    if PrepararLote(FImprimirLote, False) then
      ModalResult := mrOk;
  end
  else
    inherited btnImprimirClick(Sender);
end;

procedure TfrmPrintFac.PdfExportado(const ARuta: string);
var
  sSerie:  string;
  sNumero: string;
  sFase:   string;
  bLanzada: Boolean;
  oRepositorioPdf: IRepositorioPdfFactura;
begin
  inherited;
  if (Trim(ARuta) <> '') and (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    sSerie  := dmFac.unqryFacPrint.FieldByName('SERIE_FAC').AsString;
    sNumero := dmFac.unqryFacPrint.FieldByName('NUMERO_FAC').AsString;
    TVentasWsCola.AdjuntarFacturaPdfSeguro(
      ParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(ConexionPrincipal),
      IdentidadSesion.Usuario,
      sSerie, sNumero, ARuta, RegistroLog);
    // Archivado en fza_facturas.PDF_FAC: solo el PDF de UNA factura
    // (rbActual; un rango de fechas mezcla varias en un fichero) y solo
    // si ya salio de borrador (en modo SIN se imprimen borradores)
    sFase := dmFac.unqryFacPrint.FieldByName('FASE_FAC').AsString;
    bLanzada :=
      (dmFac.unqryFacPrint.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S')
      or ((sFase <> '') and (not SameText(sFase, 'BORRADOR')));
    if rbActual.Checked and bLanzada then
    begin
      oRepositorioPdf :=
        CrearPersistenciaFacturasUniDAC(ConexionPrincipal).Pdf;
      GuardarPdfFacturaEnBlob(oRepositorioPdf, ContextoSesion,
        sSerie, sNumero, ARuta, FormatoElegido, RegistroLog);
    end;
  end;
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet): string;
var
  iCaracter: Integer;
  RazonSocialCorta: string;
  sDocumento: string;
  sFecha: string;
  TotalFormateado: string;
begin
  RazonSocialCorta := Copy(ADataSet.FieldByName(
                                'RAZON_SOCIAL_CLIENTE_FAC').AsString, 1, 12);
  RazonSocialCorta := StringReplace(RazonSocialCorta, ' ', '', [rfReplaceAll]);
  if not ADataSet.FieldByName('FECHA_FAC').IsNull then
    sFecha := FormatDateTime('dd_mm', ADataSet.FieldByName(
                                                    'FECHA_FAC').AsDateTime)
  else
    sFecha := '00_00';
  TotalFormateado := FormatFloat('0.00', ADataSet.FieldByName(
                                              'TOTAL_LIQUIDO_FAC').AsFloat);
  TotalFormateado := StringReplace(TotalFormateado, ',', '_', [rfReplaceAll]);
  TotalFormateado := StringReplace(TotalFormateado, '.', '_', [rfReplaceAll]);
  sDocumento := FormatearDocumentoDataSet(
    ADataSet,
    'SERIE_FAC',
    'NUMERO_FAC');
  sDocumento := StringReplace(sDocumento, '\', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '/', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '.', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, ':', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '*', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '?', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '[', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, ']', '_', [rfReplaceAll]);
  Result := sFecha + '_' + sDocumento + '_' + RazonSocialCorta + '_' +
                          TotalFormateado;
  iCaracter := 1;
  while iCaracter <= Length(Result) do
  begin
    if CharInSet(Result[iCaracter],
      [#0..#31, '<', '>', ':', '"', '/', '\', '|', '?', '*']) then
    begin
      Result[iCaracter] := '_';
    end;
    Inc(iCaracter);
  end;
end;

procedure TfrmPrintFac.PrepararDatosEdicion;
begin
  AvisarAntesDeConsulta;
  preparar_consulta;
end;

procedure TfrmPrintFac.AvisarAntesDeConsulta;
begin
  AvisarReferenciasAusentes(edtSerie.Text, edtNroFac.Text);
end;

procedure TfrmPrintFac.AvisarReferenciasAusentes(
  const ASerie, ANumero: string);
var
  Referencias: TReferenciasFacturaAusentes;
  Mensaje: string;
begin
  try
    Referencias := ConsultarReferenciasFacturaAusentes(
      dmFac.unqryFacPrint.Connection, ASerie, ANumero);
    Mensaje := Referencias.Mensaje;
  except
    on E: Exception do
    begin
      Mensaje := Format(SErrorConsultarReferenciasFactura, [E.Message]);
      RegistroLog.RegistrarError(Mensaje);
    end;
  end;
  if Mensaje <> '' then
  begin
    // Ninguna ventana de progreso debe cubrir el aviso modal.
    OcultarEspera;
    ShowMessage_fza(ASerie + '/' + ANumero + sLineBreak + Mensaje);
  end;
end;

procedure TfrmPrintFac.preparar_consulta;
var
  criterios: TCriteriosInformeFactura;
begin
  criterios := Default(TCriteriosInformeFactura);
  criterios.FacturaActual := True;
  criterios.Serie := edtSerie.Text;
  criterios.Numero := edtNroFac.Text;
  // F-LOTEC-016: el lote o la serie se imprimen con los interruptores.
  if Assigned(ParametrosApp) and
     TActivacionTrazabilidad.Leer(ParametrosApp).AlgunModoActivo then
  begin
    criterios.EtiquetaLote := SEtiquetaImpresionLote;
    criterios.EtiquetaSerie := SEtiquetaImpresionSerie;
    criterios.EtiquetaCaducidad := SEtiquetaImpresionCaducidad;
  end;
  if FPreparadorInforme = nil then
    FPreparadorInforme := CrearPreparadorInformeFacturaUniDAC(
      dmFac.unqryFacPrint,
      dmFac.unqryLinFacPrint);
  FPreparadorInforme.Preparar(criterios);
  AbrirDatosTicketImpresion(dmFac, edtSerie.Text, edtNroFac.Text);
  // FieldDefs era una fotografia de diseno. La consulta de impresion
  // incorpora campos calculados, por lo que FastReport debe reconstruir
  // su catalogo desde los TField reales despues de cada apertura.
  dmFac.fxdstPrintLinFac.ResetFieldDefs;
  dmFac.fxdsPrintFac.UpdateBounds;
  dmFac.fxdstPrintLinFac.UpdateBounds;
  ConfigurarNombrePDF;
end;

procedure TfrmPrintFac.rbActualClick(Sender: TObject);
begin
  AplicarModoSeleccionado;
end;

procedure TfrmPrintFac.rbProcesarFiltradosClick(Sender: TObject);
begin
  AplicarModoSeleccionado;
end;

end.
