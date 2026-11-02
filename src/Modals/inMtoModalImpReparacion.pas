{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpReparacion                                       }
{    Tipo:       Formulario (Print)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Preimpresión, vista previa, PDF y correo de documentos de reparación.     }
{******************************************************************************}
unit inMtoModalImpReparacion;

interface

uses
  System.Classes, cxDropDownEdit, frxClass, inMtoModalGenImp,
  inLibGarantiasResguardo, inLibCorreoTickets,
  inLibReparacionesPlantillas, inLibReparacionesDocumentos;

type
  TfrmPrintReparacion = class(TfrmPrint)
  private
    FDatos: TResguardoGarantia;
    FHoja: THojaReparaciones;
    FEsHoja: Boolean;
    FTipo: TDocumentoReparacion;
    FFormato: TcxComboBox;
    FPlantilla: TDatosPlantillaReparacion;
    function Formato: TFormatoResguardoGarantia;
    procedure CrearOpciones;
    procedure AntesImprimir(AComponente: TfrxReportComponent);
    procedure VistaPreviaClick(Sender: TObject);
    function PrepararTicket: Boolean;
    procedure SalidaTicket(const ARuta: string; ASoloPdf: Boolean);
  protected
    procedure PrepararDatosEdicion; override;
    procedure EnviarCorreoDocumento(ATipo: TTipoDocumentoCorreo;
      const ASerie, ANumero: string); override;
  public
    procedure ConfigurarHoja(const AHoja: THojaReparaciones);
    procedure Configurar(const ADatos: TResguardoGarantia;
      ATipo: TDocumentoReparacion);
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    procedure btnImprimirClick(Sender: TObject); override;
    procedure btnPDFClick(Sender: TObject); override;
    function ExportarPdfPreparado(const ARuta: string;
      ANotificarExportacion: Boolean = True): Boolean; override;
    class procedure EjecutarHoja(AOwner: TComponent;
      const AHoja: THojaReparaciones);
    class procedure Ejecutar(AOwner: TComponent;
      const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion);
  end;

implementation

uses
  System.SysUtils, Vcl.Controls, Vcl.Dialogs, cxLabel,
  inLibMsgReparaciones, inLibCorreoDocumentoIntf,
  inLibCorreoDocumentoVcl, inLibDir, inLibFTicket, inLibTicketTextoFR;

{$R *.dfm}

class procedure TfrmPrintReparacion.Ejecutar(AOwner: TComponent;
  const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion);
var
  oFormulario: TfrmPrintReparacion;
begin
  oFormulario := TfrmPrintReparacion.Create(AOwner);
  try
    oFormulario.Configurar(ADatos, ATipo);
    oFormulario.ShowModal;
  finally
    oFormulario.Free;
  end;
end;

class procedure TfrmPrintReparacion.EjecutarHoja(AOwner: TComponent;
  const AHoja: THojaReparaciones);
var
  oFormulario: TfrmPrintReparacion;
begin
  oFormulario := TfrmPrintReparacion.Create(AOwner);
  try
    oFormulario.ConfigurarHoja(AHoja);
    oFormulario.ShowModal;
  finally
    oFormulario.Free;
  end;
end;

procedure TfrmPrintReparacion.ConfigurarHoja(
  const AHoja: THojaReparaciones);
var
  rDatos: TResguardoGarantia;
begin
  rDatos := Default(TResguardoGarantia);
  rDatos.Empresa := AHoja.Tienda.Empresa;
  rDatos.Numero := AHoja.Liquidacion;
  if (rDatos.Numero = 0) and (Length(AHoja.Lineas) > 0) then
    rDatos.Numero := AHoja.Lineas[0].Reparacion;
  FEsHoja := True;
  FHoja := AHoja;
  Configurar(rDatos, drRecepcion);
  Caption := AHoja.Titulo;
end;

procedure TfrmPrintReparacion.Configurar(const ADatos: TResguardoGarantia;
  ATipo: TDocumentoReparacion);
begin
  FDatos := ADatos;
  FTipo := ATipo;
  Caption := TituloDocumentoReparacion(ATipo);
  if not Assigned(FPlantilla) then
    FPlantilla := TDatosPlantillaReparacion.Create(Self);
  if not Assigned(FFormato) then
    CrearOpciones;
  // El servicio admite documentos de entrega con título personalizado.
  // La consulta comercial se sustituye por los datos de la reparación.
  ConfigurarDocumentoCorreo(tdcAlbaran, 'REP', IntToStr(ADatos.Numero));
end;

procedure TfrmPrintReparacion.CrearOpciones;
var
  oRotulo: TcxLabel;
begin
  ClientWidth := ScaleValue(510);
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := Self;
  oRotulo.Transparent := True;
  oRotulo.Caption := RotuloReferenciaGarantia(FDatos, SImpresoReferencia);
  oRotulo.SetBounds(ScaleValue(16), ScaleValue(16), ScaleValue(320),
    ScaleValue(24));
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := Self;
  oRotulo.Transparent := True;
  oRotulo.Caption := SImpresoFormato;
  oRotulo.SetBounds(ScaleValue(16), ScaleValue(54), ScaleValue(280),
    ScaleValue(24));
  FFormato := TcxComboBox.Create(Self);
  FFormato.Parent := Self;
  FFormato.SetBounds(ScaleValue(16), ScaleValue(80), ScaleValue(300),
    ScaleValue(26));
  FFormato.Properties.DropDownListStyle := lsFixedList;
  FFormato.Properties.Items.Add('A4');
  FFormato.Properties.Items.Add(SImpresoTicket);
  if FTipo in [drFabricante, drCliente] then
    FFormato.Properties.Items.Add(SImpresoEtiqueta);
  FFormato.ItemIndex := 0;
  if FTipo in [drFabricante, drCliente] then
    FFormato.ItemIndex := 2;
  btnEditar.Visible := True;
  btnExcel.Visible := FEsHoja;
  btnVistaPreliminar.OnClick := VistaPreviaClick;
end;

function TfrmPrintReparacion.Formato: TFormatoResguardoGarantia;
begin
  Result := frgA4;
  if FFormato.ItemIndex = 1 then
    Result := frgTicket
  else if FFormato.ItemIndex = 2 then
    Result := frgEtiqueta;
end;

procedure TfrmPrintReparacion.preparar_consulta;
begin
  // Los formatos de cada documento y tamaño tienen su propio catálogo.
  if FEsHoja then
  begin
    Name := 'frmPrintHojaReparaciones' + IntToStr(Ord(FHoja.EsImporte)) +
      '_' + IntToStr(Ord(Formato));
    if Formato = frgTicket then
      FPlantilla.PrepararHoja(frxrprt1, FHoja, fhrTicket)
    else
      FPlantilla.PrepararHoja(frxrprt1, FHoja, fhrA4);
  end
  else
  begin
    Name := 'frmPrintReparacion' + IntToStr(Ord(FTipo)) +
      '_' + IntToStr(Ord(Formato));
    FPlantilla.Preparar(frxrprt1, FDatos, FTipo, Formato);
  end;
  frxrprt1.PreviewOptions.Buttons := frxrprt1.PreviewOptions.Buttons -
    [pbEdit, pbLoad];
  // El ticket se imprime desde el botón del modal por el circuito ESC/POS.
  if Formato = frgTicket then
    frxrprt1.PreviewOptions.Buttons := frxrprt1.PreviewOptions.Buttons -
      [pbPrint];
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintReparacion.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintReparacion.AfterReportLoaded;
begin
  inherited;
  FPlantilla.Enlazar(frxrprt1);
  frxrprt1.OnBeforePrint := AntesImprimir;
end;

procedure TfrmPrintReparacion.AntesImprimir(
  AComponente: TfrxReportComponent);
begin
  ReportBeforePrintConQR(AComponente);
  FPlantilla.AntesImprimir(AComponente);
end;

procedure TfrmPrintReparacion.btnImprimirClick(Sender: TObject);
begin
  if Formato = frgTicket then
  begin
    preparar_consulta;
    Consultar_Formularios;
    if FormatoElegido <> '' then
    begin
      AfterReportLoaded;
      ImprimirResguardoGarantiaTicket(frxrprt1, PreviewTicket,
        ParametrosCaja.ImpresoraCaja, GetUserFolderTickets +
        'Reparacion_' + IntToStr(FDatos.Numero) + '_' +
        FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '.pdf');
    end;
  end
  else
    inherited;
end;

function TfrmPrintReparacion.PrepararTicket: Boolean;
begin
  preparar_consulta;
  Consultar_Formularios;
  Result := FormatoElegido <> '';
  if Result then
    Result := PrepararPaginasSinImprimir;
end;

procedure TfrmPrintReparacion.SalidaTicket(const ARuta: string;
  ASoloPdf: Boolean);
var
  oTicket: TTicketTermico;
begin
  oTicket := TTicketTermico.Create(ParametrosCaja.ImpresoraCaja);
  try
    ComponerTicketTextoDesdeInforme(frxrprt1, oTicket);
    // DEBUG muestra la vista previa aunque exista impresora configurada.
    PreviewTicket.Ejecutar(oTicket, oTicket.ObtenerComandos, ARuta,
      'DEBUG', ASoloPdf);
  finally
    oTicket.Free;
  end;
end;

procedure TfrmPrintReparacion.VistaPreviaClick(Sender: TObject);
begin
  if Formato = frgTicket then
  begin
    if PrepararTicket then
      SalidaTicket(GetUserFolderTickets + 'Reparacion_' +
        IntToStr(FDatos.Numero) + '_' +
        FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '.pdf', False);
  end
  else
    btnVistaPreliminarClick(Sender);
end;

procedure TfrmPrintReparacion.btnPDFClick(Sender: TObject);
var
  oGuardar: TSaveDialog;
begin
  if Formato = frgTicket then
  begin
    if PrepararTicket then
    begin
      oGuardar := TSaveDialog.Create(Self);
      try
        oGuardar.Filter := 'PDF|*.pdf';
        oGuardar.DefaultExt := 'pdf';
        oGuardar.Options := [ofOverwritePrompt, ofPathMustExist];
        oGuardar.InitialDir := ParametrosApp.GetPath('appDirPDF');
        oGuardar.FileName := 'Reparacion_' + IntToStr(FDatos.Numero) + '.pdf';
        if oGuardar.Execute then
        begin
          SalidaTicket(oGuardar.FileName, True);
          PdfExportado(oGuardar.FileName);
        end;
      finally
        oGuardar.Free;
      end;
    end;
  end
  else
    inherited;
end;

function TfrmPrintReparacion.ExportarPdfPreparado(const ARuta: string;
  ANotificarExportacion: Boolean): Boolean;
begin
  if Formato = frgTicket then
  begin
    Result := (FormatoElegido <> '') and PrepararPaginasSinImprimir;
    if Result then
    begin
      SalidaTicket(ARuta, True);
      Result := FileExists(ARuta);
      if Result and ANotificarExportacion then
        PdfExportado(ARuta);
    end;
  end
  else
    Result := inherited ExportarPdfPreparado(ARuta, ANotificarExportacion);
end;

procedure TfrmPrintReparacion.EnviarCorreoDocumento(
  ATipo: TTipoDocumentoCorreo; const ASerie, ANumero: string);
const
  NOMBRES: array[TDocumentoReparacion] of string = (
    'Recepcion', 'Etiqueta_fabricante', 'Etiqueta_cliente', 'Albaran');
var
  rCorreo: TDatosCorreoDocumento;
  sEmail, sInicial: string;
begin
  preparar_consulta;
  Consultar_Formularios;
  sInicial := FDatos.EmailCliente;
  if FTipo = drFabricante then
    sInicial := FDatos.EmailFabricante;
  if (FormatoElegido <> '') and SolicitarEmailDocumento(Self,
    TituloEnvioDocumentoCorreo(Caption), sInicial, sEmail) then
  begin
    rCorreo := Default(TDatosCorreoDocumento);
    rCorreo.Encontrado := True;
    rCorreo.NombreDocumento := Caption;
    rCorreo.NombreEmpresa := FDatos.Empresa;
    rCorreo.EmailEmpresa := FDatos.EmailEmpresa;
    rCorreo.FormatoDocumento := '';
    EnviarCorreoDocumentoPreparado(ATipo, ASerie, ANumero, Caption,
      sEmail, rCorreo, NOMBRES[FTipo] + '_REP_' + ANumero + '.pdf');
  end;
end;

end.
