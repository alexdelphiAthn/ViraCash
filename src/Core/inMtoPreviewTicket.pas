{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPreviewTicket                                            }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Previsualizador de tickets ESC/POS con exportación a PDF.                 }
{    Interpreta los comandos de la impresora y renderiza el ticket en pantalla.}
{******************************************************************************}
unit inMtoPreviewTicket;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Math, DelphiZXingQRCode, inLibFTicket,
  inLibPreviewTicket;
type
  TFormVisualizador = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Panel1: TPanel;
    btnCerrar: TButton;
    btnImprimir: TButton;
    btnPDF: TButton;
    btnPNG: TButton;
    SaveDialog1: TSaveDialog;
    btnImprimirTicket: TButton;
    btnEnviarCorreo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
    procedure btnPNGClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnImprimirTicketClick(Sender: TObject);
    procedure btnEnviarCorreoClick(Sender: TObject);
  private
    FCanvas: TCanvas;
    FEnvioCorreo: IEnvioCorreoTicket;
    FCurrentY: Integer;
    FFuenteActual: Integer; // 0=A(12x24), 1=B(9x17), 2=C(7x14)
    FNegrita: Boolean;
    FSubrayado: Boolean;
    FAlineacion: Integer; // 0=Izq, 1=Centro, 2=Derecha
    FTamanoAncho: Integer; // Multiplicador ancho (1-8)
    FTamanoAlto: Integer; // Multiplicador alto (1-8)
    FInverso: Boolean;
    FQRTexto: string;
    FQRTamanoModulo: Integer;
    FQRNivelError: Integer;
    FBarcodeAltura: Integer;
    FBarcodeHriDebajo: Boolean;
    FRenderMetafile: Boolean;
    procedure ReiniciarEstadoTicket;
    procedure InicializarPapel(AAlto: Integer);
    procedure AsegurarAltoPapel(AAltoNecesario: Integer);
    procedure RecortarPapel(AAltoFinal: Integer);
    procedure AjustarVentanaAContenido;
    procedure ColocarBotones;
    function AnchoClienteNecesario: Integer;
    function ReferenciaCorreo: string;
    procedure ProcesarComandosESCPOS(const Comandos: string);
    function LeerByteComando(const AComandos: string;
      var AIndice: Integer): Byte;
    function LeerWordComando(const AComandos: string;
      var AIndice: Integer): Word;
    procedure VaciarBufferTexto(var ABuffer: string);
    procedure ReiniciarFormatoTexto;
    procedure DibujarLineaCorte;
    procedure ProcesarComandoESC(const AComandos: string;
      var AIndice: Integer; var ABuffer: string);
    procedure ProcesarCodigoBarras(const AComandos: string;
      var AIndice: Integer; var ABuffer: string);
    procedure ProcesarComandoQR(const AComandos: string;
      var AIndice: Integer; var ABuffer: string);
    procedure ProcesarImagenRasterGS(const AComandos: string;
      var AIndice: Integer; var ABuffer: string);
    procedure ProcesarComandoGS(const AComandos: string;
      var AIndice: Integer; var ABuffer: string);
    procedure ImprimirTexto(const Texto: string);
    procedure ImprimirImagenRaster(const Datos: string; Ancho, Alto: Integer);
    procedure NuevaLinea;
    procedure AjustarFuente;
    function ObtenerAltoLinea: Integer;
    procedure DibujarQRCode;
    procedure DibujarEAN13(const ADigitos: string);

  public
    FComandos: string;
    FRutaPDFReal: string;
    procedure ExportarAPDF(const Comandos: string; const RutaArchivo: string);
    procedure CargarYMostrar(const Comandos: string);
    procedure GuardarPNG(const ARuta: string);
    procedure ImprimirEnImpresora;
    // Sin servicio de correo el boton de email no se muestra.
    procedure AsignarEnvioCorreo(const AEnvioCorreo: IEnvioCorreoTicket);
  end;

procedure VisualizarTicket(const Comandos: string);
procedure ImprimirOPrevisualizarTicket(ATicket: TTicketTermico;
                                       const AComandos, ARutaPDF,
                                             ANombreImpresora: string;
                                       ASoloPDF: Boolean = False;
                                       const AEnvioCorreo:
                                         IEnvioCorreoTicket = nil);
function CrearPreviewTicketMto(
  const AEnvioCorreo: IEnvioCorreoTicket = nil): IPreviewTicket;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  SynPdf, inLibDir, Vcl.Imaging.PngImage, Vcl.Printers, System.IOUtils,
  System.UITypes, System.StrUtils, inLibMsgComun,
  inLibMsgFacturas, inLibTraducciones;

resourcestring
  SFiltroArchivoPdfTicket =
    'PDF|*.pdf';
  SFiltroArchivoPngTicket =
    'PNG|*.png';
  SNombreArchivoTicket =
    'Ticket_%s';

type
  TPreviewTicketMto = class(TInterfacedObject, IPreviewTicket)
  private
    FEnvioCorreo: IEnvioCorreoTicket;
  public
    constructor Create(const AEnvioCorreo: IEnvioCorreoTicket);
    procedure Ejecutar(ATicket: TTicketTermico;
                       const AComandos, ARutaPDF,
                             ANombreImpresora: string;
                       ASoloPDF: Boolean);
  end;

const
  ANCHO_PAPEL_MM = 80;
  DPI = 203;
  ANCHO_PAPEL_PIXELS = 576; // Área imprimible del papel de 80 mm
  PUNTOS_POR_PULGADA = 72;
  MARGEN_PIXELS = 8;
  // Tamaños de fuentes en pixels (aproximado)
  FUENTE_A_ANCHO = 12;
  FUENTE_A_ALTO = 24;
  FUENTE_B_ANCHO = 9;
  FUENTE_B_ALTO = 17;
  FUENTE_C_ANCHO = 7;
  FUENTE_C_ALTO = 14;
  ALTO_PAPEL_INICIAL = 2000;
  MARGEN_PAPEL_FINAL = 50;
  MARGEN_CRECIMIENTO_PAPEL = 500;
  ALTO_MINIMO_PREVIEW = 320;
  SEPARACION_BOTONES = 6;

function CrearPreviewTicketMto(
  const AEnvioCorreo: IEnvioCorreoTicket): IPreviewTicket;
begin
  Result := TPreviewTicketMto.Create(AEnvioCorreo);
end;

constructor TPreviewTicketMto.Create(
  const AEnvioCorreo: IEnvioCorreoTicket);
begin
  inherited Create;
  FEnvioCorreo := AEnvioCorreo;
end;

procedure TPreviewTicketMto.Ejecutar(
  ATicket: TTicketTermico; const AComandos, ARutaPDF,
  ANombreImpresora: string; ASoloPDF: Boolean);
begin
  ImprimirOPrevisualizarTicket(
    ATicket, AComandos, ARutaPDF, ANombreImpresora, ASoloPDF,
    FEnvioCorreo);
end;

procedure TFormVisualizador.ReiniciarEstadoTicket;
begin
  FCurrentY := MARGEN_PIXELS;
  FFuenteActual := 0;
  FNegrita := False;
  FSubrayado := False;
  FAlineacion := 0;
  FTamanoAncho := 1;
  FTamanoAlto := 1;
  FInverso := False;
  FQRTexto := '';
  FQRTamanoModulo := 8;
  FQRNivelError := 48;
  FBarcodeAltura := 80;
  FBarcodeHriDebajo := True;
end;

procedure TFormVisualizador.InicializarPapel(AAlto: Integer);
begin
  if AAlto < ALTO_MINIMO_PREVIEW then
    AAlto := ALTO_MINIMO_PREVIEW;
  Image1.Picture.Bitmap.PixelFormat := pf24bit;
  Image1.Picture.Bitmap.Width := ANCHO_PAPEL_PIXELS;
  Image1.Picture.Bitmap.Height := AAlto;
  Image1.Width := ANCHO_PAPEL_PIXELS;
  Image1.Height := AAlto;
  FCanvas := Image1.Picture.Bitmap.Canvas;
  FCanvas.Brush.Style := bsSolid;
  FCanvas.Brush.Color := clWhite;
  FCanvas.FillRect(Rect(0, 0, ANCHO_PAPEL_PIXELS, AAlto));
  FCanvas.Brush.Style := bsClear;
end;

procedure TFormVisualizador.AsegurarAltoPapel(AAltoNecesario: Integer);
var
  iNuevoAlto: Integer;
  oBitmapActual: TBitmap;
begin
  if (not FRenderMetafile) and
     (AAltoNecesario > Image1.Picture.Bitmap.Height) then
  begin
    iNuevoAlto := Max(AAltoNecesario + MARGEN_CRECIMIENTO_PAPEL,
                      Image1.Picture.Bitmap.Height * 2);
    oBitmapActual := TBitmap.Create;
    try
      oBitmapActual.Assign(Image1.Picture.Bitmap);
      Image1.Picture.Bitmap.PixelFormat := pf24bit;
      Image1.Picture.Bitmap.Width := ANCHO_PAPEL_PIXELS;
      Image1.Picture.Bitmap.Height := iNuevoAlto;
      FCanvas := Image1.Picture.Bitmap.Canvas;
      FCanvas.Brush.Style := bsSolid;
      FCanvas.Brush.Color := clWhite;
      FCanvas.FillRect(Rect(0, 0, ANCHO_PAPEL_PIXELS, iNuevoAlto));
      FCanvas.Draw(0, 0, oBitmapActual);
      FCanvas.Brush.Style := bsClear;
      Image1.Height := iNuevoAlto;
    finally
      FreeAndNil(oBitmapActual);
    end;
  end;
end;

procedure TFormVisualizador.RecortarPapel(AAltoFinal: Integer);
var
  oBitmapFinal: TBitmap;
begin
  if AAltoFinal < ALTO_MINIMO_PREVIEW then
    AAltoFinal := ALTO_MINIMO_PREVIEW;
  AsegurarAltoPapel(AAltoFinal);
  oBitmapFinal := TBitmap.Create;
  try
    oBitmapFinal.PixelFormat := pf24bit;
    oBitmapFinal.Width := ANCHO_PAPEL_PIXELS;
    oBitmapFinal.Height := AAltoFinal;
    oBitmapFinal.Canvas.Brush.Style := bsSolid;
    oBitmapFinal.Canvas.Brush.Color := clWhite;
    oBitmapFinal.Canvas.FillRect(Rect(0, 0, ANCHO_PAPEL_PIXELS,
                                      AAltoFinal));
    oBitmapFinal.Canvas.Draw(0, 0, Image1.Picture.Bitmap);
    Image1.Picture.Bitmap.Assign(oBitmapFinal);
  finally
    FreeAndNil(oBitmapFinal);
  end;
  FCanvas := Image1.Picture.Bitmap.Canvas;
  Image1.Width := ANCHO_PAPEL_PIXELS;
  Image1.Height := AAltoFinal;
end;

procedure TFormVisualizador.AjustarVentanaAContenido;
var
  iAltoDisponible: Integer;
  iAltoDeseado: Integer;
begin
  iAltoDisponible := Screen.WorkAreaHeight - 120;
  iAltoDeseado := Image1.Height + Panel1.Height + 16;
  if iAltoDeseado > iAltoDisponible then
    iAltoDeseado := iAltoDisponible;
  if iAltoDeseado < ALTO_MINIMO_PREVIEW + Panel1.Height then
    iAltoDeseado := ALTO_MINIMO_PREVIEW + Panel1.Height;
  ClientHeight := iAltoDeseado;
  ClientWidth := AnchoClienteNecesario;
  Left := Screen.WorkAreaLeft + (Screen.WorkAreaWidth - Width) div 2;
  Top := Screen.WorkAreaTop + (Screen.WorkAreaHeight - Height) div 2;
end;

// Los botones van seguidos y la ventana se ensancha hasta que caben todos;
// el papel necesita ademas la barra de desplazamiento vertical.
procedure TFormVisualizador.ColocarBotones;
var
  i: Integer;
  iLeft: Integer;
  AnchoTexto: Integer;
  aBotones: TArray<TButton>;
begin
  aBotones := [btnImprimir, btnPDF, btnPNG, btnImprimirTicket,
    btnEnviarCorreo, btnCerrar];
  iLeft := ScaleValue(SEPARACION_BOTONES);
  for i := 0 to High(aBotones) do
    if aBotones[i].Visible then
    begin
      Canvas.Font.Assign(aBotones[i].Font);
      AnchoTexto := Canvas.TextWidth(aBotones[i].Caption) + ScaleValue(24);
      if aBotones[i].Width < AnchoTexto then
        aBotones[i].Width := AnchoTexto;
      aBotones[i].Left := iLeft;
      iLeft := iLeft + aBotones[i].Width + ScaleValue(SEPARACION_BOTONES);
    end;
end;

function TFormVisualizador.AnchoClienteNecesario: Integer;
begin
  ColocarBotones;
  Result := Max(
    btnCerrar.Left + btnCerrar.Width + ScaleValue(SEPARACION_BOTONES),
    Image1.Left * 2 + ANCHO_PAPEL_PIXELS +
      GetSystemMetrics(SM_CXVSCROLL) + ScrollBox1.Width -
      ScrollBox1.ClientWidth);
end;

procedure TFormVisualizador.AsignarEnvioCorreo(
  const AEnvioCorreo: IEnvioCorreoTicket);
begin
  FEnvioCorreo := AEnvioCorreo;
  btnEnviarCorreo.Visible := Assigned(FEnvioCorreo);
  ClientWidth := AnchoClienteNecesario;
end;

// Nombre del adjunto: el del PDF del ticket si lo hay (sin el prefijo
// "Ticket_", que el correo ya pone), si no la fecha y hora.
function TFormVisualizador.ReferenciaCorreo: string;
const
  PREFIJO_TICKET = 'Ticket_';
begin
  Result := ChangeFileExt(ExtractFileName(FRutaPDFReal), '');
  if StartsText(PREFIJO_TICKET, Result) then
    Delete(Result, 1, Length(PREFIJO_TICKET));
  if Trim(Result) = '' then
    Result := FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now);
end;

procedure TFormVisualizador.btnEnviarCorreoClick(Sender: TObject);
begin
  if not Assigned(FEnvioCorreo) then
    Exit;
  if FComandos = '' then
    ShowMessage_fza(SAvisoSinComandosESCPOSPDF)
  else
    FEnvioCorreo.Enviar(
      Self,
      ReferenciaCorreo,
      procedure(ARuta: string)
      begin
        ExportarAPDF(FComandos, ARuta);
      end);
end;

procedure TFormVisualizador.ExportarAPDF(const Comandos: string;
                                         const RutaArchivo: string);
var
  Pdf: TPdfDocument;
  AlturaReal: Integer;
  AltoContenidoPDF: Integer;
  AnchoContenidoPDF: Integer;
  AnchoPaginaPDF: Integer;
  MargenHorizontalPDF: Integer;
  CajaContenidoPDF: TPdfBox;
begin
  AlturaReal := Image1.Picture.Bitmap.Height;
  // SynPDF usa puntos (1/72 de pulgada), no píxeles. Mantener la misma
  // conversión en ambos ejes evita deformar y recortar el ticket guardado.
  AnchoPaginaPDF := PdfCoord(ANCHO_PAPEL_MM);
  AnchoContenidoPDF := MulDiv(
    ANCHO_PAPEL_PIXELS, PUNTOS_POR_PULGADA, DPI);
  AltoContenidoPDF := MulDiv(
    AlturaReal, PUNTOS_POR_PULGADA, DPI);
  MargenHorizontalPDF :=
    (AnchoPaginaPDF - AnchoContenidoPDF) div 2;
  Pdf := TPdfDocument.Create;
  try
    Pdf.DefaultPaperSize := psUserDefined;
    Pdf.DefaultPageWidth := AnchoPaginaPDF;
    Pdf.DefaultPageHeight := AltoContenidoPDF;
    Pdf.AddPage;
    // El bitmap ya está renderizado a los 203 ppp de la impresora térmica.
    // Insertarlo con coordenadas PDF evita que el DPI de Windows vuelva a
    // escalar el contenido respecto a la página fija de 80 mm.
    Pdf.ForceJPEGCompression := 0;
    CajaContenidoPDF := PdfBox(
      MargenHorizontalPDF, 0, AnchoContenidoPDF, AltoContenidoPDF);
    Pdf.CreateOrGetImage(Image1.Picture.Bitmap, @CajaContenidoPDF);
    Pdf.SaveToFile(RutaArchivo);
  finally
    FreeAndNil(Pdf);
  end;
end;

procedure VisualizarTicket(const Comandos: string);
var
  Form: TFormVisualizador;
begin
  Form := TFormVisualizador.Create(nil);
  try
    Form.FComandos := Comandos;
    Form.CargarYMostrar(Comandos);
    // Generar PDF antes del ShowModal (funciona siempre en este punto)
//    Form.FRutaPDFTemporal := GetUserFolderTickets + '_preview_tmp.pdf';
//    Form.ExportarAPDF(Comandos, Form.FRutaPDFTemporal);
    Form.ShowModal;
  finally
    FreeAndNil(Form);
  end;
end;

procedure ImprimirOPrevisualizarTicket(ATicket: TTicketTermico;
                                       const AComandos, ARutaPDF,
                                             ANombreImpresora: string;
                                       ASoloPDF: Boolean;
                                       const AEnvioCorreo:
                                         IEnvioCorreoTicket);
var
  oPreview: TFormVisualizador;
  sErrorImpresion: string;
  EsMostrarPreview: Boolean;
begin
  sErrorImpresion := '';
  EsMostrarPreview := (not ASoloPDF) and
                      (SameText(Trim(ANombreImpresora), 'DEBUG') or
                       (Trim(ANombreImpresora) = ''));
  if (not ASoloPDF) and (not EsMostrarPreview) then
  begin
    try
      ATicket.Imprimir;
    except
      on E: Exception do
      begin
        sErrorImpresion := E.Message;
        EsMostrarPreview := True;
      end;
    end;
  end;
  oPreview := TFormVisualizador.Create(nil);
  try
    oPreview.Hide;
    oPreview.AsignarEnvioCorreo(AEnvioCorreo);
    oPreview.FRutaPDFReal := ARutaPDF;
    oPreview.CargarYMostrar(AComandos);
    oPreview.ExportarAPDF(AComandos, ARutaPDF);
    if EsMostrarPreview then
    begin
      if sErrorImpresion <> '' then
      begin
        MessageDlg_fza(Format(SErrorEnviarTicketImpresora,
                          [ANombreImpresora, sErrorImpresion]),
                   mtWarning, [mbOk], 0);
      end;
      oPreview.ShowModal;
    end;
  finally
    FreeAndNil(oPreview);
  end;
end;

procedure TFormVisualizador.DibujarQRCode;
var
  QRCode: TDelphiZXIngQRCode;
  Row, Column: Integer;
  Scale: Integer;
  QRBitmap: TBitmap;
  x, y: Integer;
  StartX: Integer;
  QRWidth, QRHeight: Integer;
begin
  if FQRTexto <> '' then
  begin
    QRCode := TDelphiZXIngQRCode.Create;
    QRBitmap := TBitmap.Create;
    try
      // Nivel ESC/POS: 48=L, 49=M, 50=Q, 51=H.
      case FQRNivelError of
        49:
          QRCode.ErrorCorrectionLevel := qreM;
        50:
          QRCode.ErrorCorrectionLevel := qreQ;
        51:
          QRCode.ErrorCorrectionLevel := qreH;
      else
        QRCode.ErrorCorrectionLevel := qreL;
      end;
      QRCode.Encoding := TQRCodeEncoding(qrUTF8NoBOM);
      QRCode.QuietZone := 1;
      QRCode.Data := FQRTexto;
      // Escala basada en el tamaño del módulo.
      Scale := FQRTamanoModulo div 2;
      if Scale < 2 then
        Scale := 2;
      QRBitmap.Width := QRCode.Columns * Scale;
      QRBitmap.Height := QRCode.Rows * Scale;
      QRBitmap.PixelFormat := pf24bit;
      QRBitmap.Canvas.Brush.Color := clWhite;
      QRBitmap.Canvas.FillRect(Rect(0, 0, QRBitmap.Width, QRBitmap.Height));
      QRBitmap.Canvas.Brush.Color := clBlack;
      for Row := 0 to QRCode.Rows - 1 do
      begin
        for Column := 0 to QRCode.Columns - 1 do
        begin
          if QRCode.IsBlack[Row, Column] then
          begin
            x := Column * Scale;
            y := Row * Scale;
            QRBitmap.Canvas.FillRect(Rect(x, y, x + Scale, y + Scale));
          end;
        end;
      end;
      QRWidth := QRBitmap.Width;
      QRHeight := QRBitmap.Height;
      case FAlineacion of
        1:
          StartX := (ANCHO_PAPEL_PIXELS - QRWidth) div 2;
        2:
          StartX := ANCHO_PAPEL_PIXELS - QRWidth - MARGEN_PIXELS;
      else
        StartX := MARGEN_PIXELS;
      end;
      AsegurarAltoPapel(FCurrentY + QRHeight + MARGEN_PAPEL_FINAL);
      FCanvas.Draw(StartX, FCurrentY, QRBitmap);
      FCurrentY := FCurrentY + QRHeight;
    finally
      FreeAndNil(QRBitmap);
      FreeAndNil(QRCode);
    end;
  end;
end;

procedure TFormVisualizador.DibujarEAN13(const ADigitos: string);
const
  // Codificación estándar EAN-13: patrones L y G de 7 módulos por dígito.
  // El patrón R es el complemento bit a bit del L.
  PATRON_L: array[0..9] of string = (
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011');
  PATRON_G: array[0..9] of string = (
    '0100111', '0110011', '0011011', '0100001', '0011101',
    '0111001', '0000101', '0010001', '0001001', '0010111');
  // Paridad L/G de los 6 dígitos izquierdos según el primer dígito
  PARIDAD: array[0..9] of string = (
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
    'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL');
  ESCALA_MODULO = 4; // píxeles por módulo: 95 módulos -> 380 px
var
  sModulos, sParidad, sPatron: string;
  bValido: Boolean;
  iDigito, i, j, x: Integer;
  iAncho, iAlto, iAltoHri, iStartX: Integer;
begin
  // Solo dígitos y longitud 13; si no, se ignora (igual que la impresora)
  bValido := Length(ADigitos) = 13;
  for i := 1 to Length(ADigitos) do
    if not CharInSet(ADigitos[i], ['0'..'9']) then
      bValido := False;
  if bValido then
  begin
    // Componer los 95 módulos: guarda 101 + 6 dígitos L/G + 01010 +
    // 6 dígitos R + guarda 101
    sParidad := PARIDAD[Ord(ADigitos[1]) - Ord('0')];
    sModulos := '101';
    for i := 2 to 7 do
    begin
      iDigito := Ord(ADigitos[i]) - Ord('0');
      if sParidad[i - 1] = 'L' then
        sPatron := PATRON_L[iDigito]
      else
        sPatron := PATRON_G[iDigito];
      sModulos := sModulos + sPatron;
    end;
    sModulos := sModulos + '01010';
    for i := 8 to 13 do
    begin
      iDigito := Ord(ADigitos[i]) - Ord('0');
      sPatron := PATRON_L[iDigito];
      for j := 1 to Length(sPatron) do
        if sPatron[j] = '0' then
          sPatron[j] := '1'
        else
          sPatron[j] := '0';
      sModulos := sModulos + sPatron;
    end;
    sModulos := sModulos + '101';
    iAncho := Length(sModulos) * ESCALA_MODULO;
    iAlto := FBarcodeAltura;
    iAltoHri := 0;
    if FBarcodeHriDebajo then
      iAltoHri := 22;
    case FAlineacion of
      1:
        iStartX := (ANCHO_PAPEL_PIXELS - iAncho) div 2;
      2:
        iStartX := ANCHO_PAPEL_PIXELS - iAncho - MARGEN_PIXELS;
    else
      iStartX := MARGEN_PIXELS;
    end;
    if iStartX < 0 then
      iStartX := 0;
    AsegurarAltoPapel(FCurrentY + iAlto + iAltoHri + MARGEN_PAPEL_FINAL);
    FCanvas.Brush.Color := clBlack;
    FCanvas.Brush.Style := bsSolid;
    for i := 1 to Length(sModulos) do
    begin
      if sModulos[i] = '1' then
      begin
        x := iStartX + (i - 1) * ESCALA_MODULO;
        FCanvas.FillRect(
          Rect(x, FCurrentY, x + ESCALA_MODULO, FCurrentY + iAlto));
      end;
    end;
    FCurrentY := FCurrentY + iAlto;
    if FBarcodeHriDebajo then
    begin
      FCanvas.Brush.Style := bsClear;
      FCanvas.Font.Name := 'Courier New';
      FCanvas.Font.Size := 9;
      FCanvas.Font.Style := [];
      FCanvas.Font.Color := clBlack;
      FCanvas.TextOut(
        iStartX + (iAncho - FCanvas.TextWidth(ADigitos)) div 2,
        FCurrentY + 2,
        ADigitos);
      FCanvas.Brush.Style := bsSolid;
      FCanvas.Brush.Color := clWhite;
      FCurrentY := FCurrentY + iAltoHri;
    end;
  end;
end;

procedure TFormVisualizador.ImprimirImagenRaster(const Datos: string;
                                                 Ancho, Alto: Integer);
var
  X, Y: Integer;
  ByteIndex, BitIndex: Integer;
  StartX: Integer;
begin
  AsegurarAltoPapel(FCurrentY + Alto + MARGEN_PAPEL_FINAL);
  if Length(Datos) = 0 then
  begin
    FCurrentY := FCurrentY + Alto;
  end
  else
  begin
    // Calcular posición X según alineación
    case FAlineacion of
      1: StartX := (ANCHO_PAPEL_PIXELS - Ancho) div 2; // Centro
      2: StartX := ANCHO_PAPEL_PIXELS - Ancho - MARGEN_PIXELS; // Derecha
    else
      StartX := MARGEN_PIXELS; // Izquierda
    end;
    // Asegurarnos de no salirnos de los límites
    if StartX < 0 then
      StartX := 0;
    if StartX + Ancho > ANCHO_PAPEL_PIXELS then
      Ancho := ANCHO_PAPEL_PIXELS - StartX;
    for Y := 0 to Alto - 1 do
    begin
      for X := 0 to Ancho - 1 do
      begin
        ByteIndex := (X div 8) + 1;
        BitIndex := 7 - (X mod 8);
        if (ByteIndex <= Length(Datos)) and (ByteIndex > 0) then
        begin
          if ((Ord(Datos[ByteIndex]) and (1 shl BitIndex)) <> 0) then
          begin
            if (StartX + X < ANCHO_PAPEL_PIXELS) and
               (FCurrentY + Y < Image1.Picture.Bitmap.Height) then
              FCanvas.Pixels[StartX + X, FCurrentY + Y] := clBlack;
          end;
        end;
      end;
    end;
    FCurrentY := FCurrentY + Alto;
  end;
end;

procedure TFormVisualizador.FormCreate(Sender: TObject);
begin
  KeyPreview := True;
  btnEnviarCorreo.Visible := False;
  Self.ClientWidth := AnchoClienteNecesario;
  FRenderMetafile := False;
  InicializarPapel(ALTO_PAPEL_INICIAL);
  ReiniciarEstadoTicket;
  AplicarTraducciones(Self, Application.MainForm);
  ClientWidth := AnchoClienteNecesario;
end;

procedure TFormVisualizador.FormDestroy(Sender: TObject);
begin
  // Limpieza automática
end;

procedure TFormVisualizador.CargarYMostrar(const Comandos: string);
begin
  FComandos := Comandos;
  InicializarPapel(ALTO_PAPEL_INICIAL);
  ReiniciarEstadoTicket;
  ProcesarComandosESCPOS(Comandos);
  RecortarPapel(FCurrentY + MARGEN_PAPEL_FINAL);
  AjustarVentanaAContenido;
end;

function TFormVisualizador.LeerByteComando(
  const AComandos: string; var AIndice: Integer): Byte;
begin
  Inc(AIndice);
  Result := 0;
  if AIndice <= Length(AComandos) then
    Result := Ord(AComandos[AIndice]);
end;

function TFormVisualizador.LeerWordComando(
  const AComandos: string; var AIndice: Integer): Word;
var
  bAlto, bBajo: Byte;
begin
  bBajo := LeerByteComando(AComandos, AIndice);
  bAlto := LeerByteComando(AComandos, AIndice);
  Result := bBajo + (bAlto shl 8);
end;

procedure TFormVisualizador.VaciarBufferTexto(var ABuffer: string);
begin
  if ABuffer <> '' then
  begin
    ImprimirTexto(ABuffer);
    ABuffer := '';
  end;
end;

procedure TFormVisualizador.ReiniciarFormatoTexto;
begin
  FFuenteActual := 0;
  FNegrita := False;
  FSubrayado := False;
  FAlineacion := 0;
  FTamanoAncho := 1;
  FTamanoAlto := 1;
  FInverso := False;
end;

procedure TFormVisualizador.DibujarLineaCorte;
begin
  AsegurarAltoPapel(FCurrentY + 20 + MARGEN_PAPEL_FINAL);
  FCanvas.Pen.Color := clGray;
  FCanvas.Pen.Style := psDash;
  FCanvas.MoveTo(0, FCurrentY + 10);
  FCanvas.LineTo(ANCHO_PAPEL_PIXELS, FCurrentY + 10);
  FCurrentY := FCurrentY + 20;
end;

procedure TFormVisualizador.ProcesarComandoESC(
  const AComandos: string; var AIndice: Integer;
  var ABuffer: string);
var
  i, iAncho, iBytesPorLinea, iLineas: Integer;
  sDatosImagen: string;
begin
  Inc(AIndice);
  if AIndice <= Length(AComandos) then
  begin
    case AComandos[AIndice] of
      '@':
        ReiniciarFormatoTexto;
      'M', 'm':
        begin
          FFuenteActual := LeerByteComando(AComandos, AIndice);
          if FFuenteActual > 2 then
            FFuenteActual := 1;
        end;
      'E':
        FNegrita := LeerByteComando(AComandos, AIndice) <> 0;
      '-':
        FSubrayado := LeerByteComando(AComandos, AIndice) <> 0;
      'a':
        begin
          FAlineacion := LeerByteComando(AComandos, AIndice);
          if FAlineacion > 2 then
            FAlineacion := 0;
        end;
      'd':
        begin
          VaciarBufferTexto(ABuffer);
          iLineas := LeerByteComando(AComandos, AIndice);
          FCurrentY := FCurrentY + iLineas * ObtenerAltoLinea;
        end;
      '*':
        begin
          VaciarBufferTexto(ABuffer);
          LeerByteComando(AComandos, AIndice);
          iAncho := LeerWordComando(AComandos, AIndice);
          iBytesPorLinea := (iAncho + 7) div 8;
          sDatosImagen := '';
          for i := 1 to iBytesPorLinea do
            sDatosImagen := sDatosImagen +
              Char(LeerByteComando(AComandos, AIndice));
          ImprimirImagenRaster(sDatosImagen, iAncho, 1);
        end;
      'i':
        DibujarLineaCorte;
      'p':
        Inc(AIndice, 3);
    end;
  end;
end;

procedure TFormVisualizador.ProcesarCodigoBarras(
  const AComandos: string; var AIndice: Integer;
  var ABuffer: string);
var
  bDato, bFormato, bLongitud: Byte;
  i: Integer;
  sDatos: string;
begin
  bFormato := LeerByteComando(AComandos, AIndice);
  sDatos := '';
  if bFormato <= 6 then
  begin
    bDato := LeerByteComando(AComandos, AIndice);
    while (bDato <> 0) and (AIndice <= Length(AComandos)) do
    begin
      sDatos := sDatos + Char(bDato);
      bDato := LeerByteComando(AComandos, AIndice);
    end;
  end
  else
  begin
    bLongitud := LeerByteComando(AComandos, AIndice);
    for i := 1 to bLongitud do
      sDatos := sDatos + Char(LeerByteComando(AComandos, AIndice));
  end;
  VaciarBufferTexto(ABuffer);
  if (bFormato = 2) or (bFormato = 67) then
    DibujarEAN13(sDatos);
end;

procedure TFormVisualizador.ProcesarComandoQR(
  const AComandos: string; var AIndice: Integer;
  var ABuffer: string);
var
  bCodigo, bParteAlta, bParteBaja: Byte;
  bEsQR: Boolean;
  i, iLongitud: Integer;
begin
  Inc(AIndice);
  if AIndice <= Length(AComandos) then
  begin
    bEsQR := AComandos[AIndice] = 'k';
    bParteBaja := LeerByteComando(AComandos, AIndice);
    bParteAlta := LeerByteComando(AComandos, AIndice);
    iLongitud := bParteBaja + bParteAlta * 256;
    if bEsQR then
    begin
      LeerByteComando(AComandos, AIndice);
      bCodigo := LeerByteComando(AComandos, AIndice);
      case bCodigo of
        65:
          for i := 1 to iLongitud - 2 do
            LeerByteComando(AComandos, AIndice);
        67:
          begin
            FQRTamanoModulo := LeerByteComando(AComandos, AIndice);
            for i := 1 to iLongitud - 3 do
              LeerByteComando(AComandos, AIndice);
          end;
        69:
          begin
            FQRNivelError := LeerByteComando(AComandos, AIndice);
            for i := 1 to iLongitud - 3 do
              LeerByteComando(AComandos, AIndice);
          end;
        80:
          begin
            LeerByteComando(AComandos, AIndice);
            FQRTexto := '';
            for i := 1 to iLongitud - 3 do
              FQRTexto := FQRTexto +
                Char(LeerByteComando(AComandos, AIndice));
          end;
        81:
          begin
            for i := 1 to iLongitud - 2 do
              LeerByteComando(AComandos, AIndice);
            VaciarBufferTexto(ABuffer);
            DibujarQRCode;
            FQRTexto := '';
          end;
      else
        for i := 1 to iLongitud - 2 do
          LeerByteComando(AComandos, AIndice);
      end;
    end
    else
      for i := 1 to iLongitud do
        LeerByteComando(AComandos, AIndice);
  end;
end;

procedure TFormVisualizador.ProcesarImagenRasterGS(
  const AComandos: string; var AIndice: Integer;
  var ABuffer: string);
var
  i, iAlto, iAnchoBytes, iAnchoPixels: Integer;
  iBit, iByte, iInicioX, x, y: Integer;
  sDatos: string;
begin
  Inc(AIndice);
  if (AIndice <= Length(AComandos)) and
     (AComandos[AIndice] = '0') then
  begin
    LeerByteComando(AComandos, AIndice);
    iAnchoBytes := LeerWordComando(AComandos, AIndice);
    iAlto := LeerWordComando(AComandos, AIndice);
    VaciarBufferTexto(ABuffer);
    sDatos := '';
    for i := 1 to iAnchoBytes * iAlto do
      sDatos := sDatos + Char(LeerByteComando(AComandos, AIndice));
    iAnchoPixels := iAnchoBytes * 8;
    case FAlineacion of
      1:
        iInicioX := (ANCHO_PAPEL_PIXELS - iAnchoPixels) div 2;
      2:
        iInicioX := ANCHO_PAPEL_PIXELS - iAnchoPixels - MARGEN_PIXELS;
    else
      iInicioX := MARGEN_PIXELS;
    end;
    AsegurarAltoPapel(FCurrentY + iAlto + MARGEN_PAPEL_FINAL);
    for y := 0 to iAlto - 1 do
    begin
      for x := 0 to iAnchoPixels - 1 do
      begin
        iByte := y * iAnchoBytes + x div 8;
        iBit := 7 - x mod 8;
        if (iByte < Length(sDatos)) and
           ((Ord(sDatos[iByte + 1]) and (1 shl iBit)) <> 0) then
          FCanvas.Pixels[iInicioX + x, FCurrentY + y] := clBlack;
      end;
    end;
    FCurrentY := FCurrentY + iAlto;
  end;
end;

procedure TFormVisualizador.ProcesarComandoGS(
  const AComandos: string; var AIndice: Integer;
  var ABuffer: string);
var
  bPosicion, bValor: Byte;
begin
  Inc(AIndice);
  if AIndice <= Length(AComandos) then
  begin
    case AComandos[AIndice] of
      '!':
        begin
          bValor := LeerByteComando(AComandos, AIndice);
          FTamanoAncho := (bValor and $0F) + 1;
          FTamanoAlto := ((bValor shr 4) and $07) + 1;
          if FTamanoAncho > 8 then
            FTamanoAncho := 1;
          if FTamanoAlto > 8 then
            FTamanoAlto := 1;
        end;
      'B':
        FInverso := LeerByteComando(AComandos, AIndice) <> 0;
      'h':
        FBarcodeAltura := LeerByteComando(AComandos, AIndice);
      'w', 'f':
        LeerByteComando(AComandos, AIndice);
      'H':
        begin
          bPosicion := LeerByteComando(AComandos, AIndice);
          FBarcodeHriDebajo := (bPosicion = 2) or (bPosicion = 50);
        end;
      'k':
        ProcesarCodigoBarras(AComandos, AIndice, ABuffer);
      '(':
        ProcesarComandoQR(AComandos, AIndice, ABuffer);
      'v':
        ProcesarImagenRasterGS(AComandos, AIndice, ABuffer);
    end;
  end;
end;

procedure TFormVisualizador.ProcesarComandosESCPOS(
  const Comandos: string);
var
  i: Integer;
  sBuffer: string;
begin
  i := 1;
  sBuffer := '';
  while i <= Length(Comandos) do
  begin
    case Comandos[i] of
      #27:
        ProcesarComandoESC(Comandos, i, sBuffer);
      #29:
        ProcesarComandoGS(Comandos, i, sBuffer);
      #10:
        begin
          VaciarBufferTexto(sBuffer);
          NuevaLinea;
        end;
      #13:
        begin
          // El retorno de carro no altera el cursor del preview.
        end;
      #9:
        sBuffer := sBuffer + '    ';
    else
      if Ord(Comandos[i]) >= 32 then
        sBuffer := sBuffer + Comandos[i];
    end;
    Inc(i);
  end;
  VaciarBufferTexto(sBuffer);
end;

procedure TFormVisualizador.AjustarFuente;
var
  LogFont: TLogFont;
  AlturaPixels: Integer;
begin
  // 1. Determinar altura en PIXELES reales (no puntos)
  // Fuente A suele ser 24px alto, B 17px alto
  case FFuenteActual of
    0: AlturaPixels := 24; // Fuente A (12x24)
    1: AlturaPixels := 17; // Fuente B (9x17)
    2: AlturaPixels := 14; // Fuente C
  else
    AlturaPixels := 17;
  end;
  // Aplicar multiplicadores de tamaño ESC/POS
  AlturaPixels := AlturaPixels * FTamanoAlto;
  // 2. Obtener la estructura LogFont actual del Canvas
  if GetObject(FCanvas.Font.Handle, SizeOf(TLogFont), @LogFont) = 0 then
  begin
    // Fallback si falla, llenamos lo básico
    FillChar(LogFont, SizeOf(LogFont), 0);
    StrPCopy(LogFont.lfFaceName, 'Courier New');
  end;
  // 3. Configuración CRÍTICA para nitidez
  LogFont.lfHeight := -AlturaPixels;
  LogFont.lfWidth  := 0;
  // Fuerza a NO usar suavizado (bordes duros, como la impresora térmica)
  LogFont.lfQuality := NONANTIALIASED_QUALITY;
  // Peso de la fuente (Negrita)
  if FNegrita then
    LogFont.lfWeight := FW_BOLD
  else
    LogFont.lfWeight := FW_NORMAL;
  // Subrayado
  if FSubrayado then
    LogFont.lfUnderline := 1
  else
    LogFont.lfUnderline := 0;
  // Nombre de la fuente (Courier New o Consolas van bien para monoespaciado)
  StrPCopy(LogFont.lfFaceName, 'Consolas');
  // 4. Asignar la nueva fuente al Canvas
  FCanvas.Font.Handle := CreateFontIndirect(LogFont);
  FCanvas.Font.Color := clBlack;
  FCanvas.Brush.Style := bsClear;
end;

function TFormVisualizador.ObtenerAltoLinea: Integer;
begin
  case FFuenteActual of
    0: Result := FUENTE_A_ALTO;
    1: Result := FUENTE_B_ALTO;
    2: Result := FUENTE_C_ALTO;
  else
    Result := FUENTE_B_ALTO;
  end;
  Result := Result * FTamanoAlto;
end;

procedure TFormVisualizador.ImprimirTexto(const Texto: string);
var
  X: Integer;
  TextoWidth: Integer;
begin
  if Texto <> '' then
  begin
    AsegurarAltoPapel(FCurrentY + ObtenerAltoLinea +
                      MARGEN_PAPEL_FINAL);
    AjustarFuente;
    // Windows nos dice el ancho real exacto de la frase
    TextoWidth := FCanvas.TextWidth(Texto);
    case FAlineacion of
      0: X := MARGEN_PIXELS;
      1: X := (ANCHO_PAPEL_PIXELS - TextoWidth) div 2;
      2: X := ANCHO_PAPEL_PIXELS - TextoWidth - MARGEN_PIXELS;
    else
      X := MARGEN_PIXELS;
    end;
    if FInverso then
    begin
      FCanvas.Brush.Style := bsSolid;
      FCanvas.Brush.Color := clBlack;
      FCanvas.Font.Color := clWhite;
    end
    else
    begin
      FCanvas.Brush.Style := bsClear;
      FCanvas.Font.Color := clBlack;
    end;
    FCanvas.TextOut(X, FCurrentY, Texto);
    FCanvas.Brush.Style := bsClear;
  end;
end;

procedure TFormVisualizador.NuevaLinea;
begin
  FCurrentY := FCurrentY + ObtenerAltoLinea;
end;

procedure TFormVisualizador.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
    VK_F6:
      btnPNGClick(nil);
    VK_F7:
      btnPDFClick(nil);
    VK_F8:
      btnImprimirClick(nil);
    VK_F5:
      btnImprimirTicketClick(nil);
    VK_F4:
      if btnEnviarCorreo.Visible then
        btnEnviarCorreoClick(nil);
  end;
  Key := 0;
end;

procedure TFormVisualizador.GuardarPNG(const ARuta: string);
var
  png: TPngImage;
begin
  png := TPngImage.Create;
  try
    png.Assign(Image1.Picture.Bitmap);
    png.SaveToFile(ARuta);
  finally
    FreeAndNil(png);
  end;
end;

procedure TFormVisualizador.ImprimirEnImpresora;
var
  pd: TPrintDialog;
  bmp: TBitmap;
  AnchoImp, AltoImp: Integer;
  MargenIzq, MargenSup: Integer;
  DPI_X, DPI_Y: Integer;
begin
  // Copiar imagen a pf24bit y enviar a impresora con diálogo
  pd := TPrintDialog.Create(Self);
  try
    if pd.Execute then
    begin
      bmp := TBitmap.Create;
      try
        bmp.PixelFormat := pf24bit;
        bmp.Width := Image1.Picture.Bitmap.Width;
        bmp.Height := FCurrentY + 10;
        bmp.Canvas.Brush.Color := clWhite;
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        bmp.Canvas.Draw(0, 0, Image1.Picture.Bitmap);

        Printer.BeginDoc;
        try
          // 1. Obtener los puntos por pulgada (DPI) de la impresora
          // seleccionada
          DPI_X := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
          DPI_Y := GetDeviceCaps(Printer.Handle, LOGPIXELSY);

          // 2. Calcular los márgenes (1 cm). 1 pulgada = 2.54 cm
          MargenIzq := Round((1.0 / 2.54) * DPI_X);
          MargenSup := Round((1.0 / 2.54) * DPI_Y);

          // 3. Calcular el ancho y alto a imprimir
          AnchoImp := Printer.PageWidth div 2;
          AltoImp := MulDiv(bmp.Height, AnchoImp, bmp.Width);

          // 4. Dibujar desplazando el rectángulo inicial a las coordenadas del
          // margen
          Printer.Canvas.StretchDraw(
            Rect(MargenIzq,
                 MargenSup,
                 MargenIzq + AnchoImp,
                 MargenSup + AltoImp),
            bmp);
        finally
          Printer.EndDoc;
        end;
      finally
        FreeAndNil(bmp);
      end;
    end;
  finally
    FreeAndNil(pd);
  end;
end;

procedure TFormVisualizador.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TFormVisualizador.btnImprimirClick(Sender: TObject);
begin
  ImprimirEnImpresora;
end;

procedure TFormVisualizador.btnImprimirTicketClick(Sender: TObject);
var
  pd: TPrintDialog;
  NombreImpresoraElegida: string;
  ImprimirTicket: Boolean;
begin
  ImprimirTicket := False;
  if FComandos = '' then
    ShowMessage_fza(SAvisoSinComandosESCPOSImpresora);
  if FComandos <> '' then
  begin
    // 1. Mostrar diálogo para elegir la impresora
    pd := TPrintDialog.Create(Self);
    try
      ImprimirTicket := pd.Execute;
      if ImprimirTicket then
        NombreImpresoraElegida := Printer.Printers[Printer.PrinterIndex];
    finally
      FreeAndNil(pd);
    end;
  end;
  if ImprimirTicket then
  begin
    // 2. Usar la librería para enviar el ticket de forma nativa
    try
      EnviarComandoRAW(NombreImpresoraElegida, FComandos);
      ShowMessage_fza(Format(SInfoTicketEnviadoImpresora,
                         [NombreImpresoraElegida]));
    except
      on E: Exception do
        ShowMessage_fza(Format(SErrorImprimir, [E.Message]));
    end;
  end;
end;

procedure TFormVisualizador.btnPDFClick(Sender: TObject);
var
  sSrc: string;
  sDestino: string;
  sNombrePDF: string;
  bOrigenDisponible: Boolean;
  bPDFGuardado: Boolean;
begin
  sSrc := FRutaPDFReal;
  bOrigenDisponible := (sSrc <> '') and FileExists(sSrc);
  SaveDialog1.Filter := SFiltroArchivoPdfTicket;
  SaveDialog1.DefaultExt := 'pdf';
  if sSrc <> '' then
    sNombrePDF := ExtractFileName(sSrc)
  else
    sNombrePDF := Format(
      SNombreArchivoTicket,
      [FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now)]) + '.pdf';
  SaveDialog1.FileName := sNombrePDF;
  if SaveDialog1.Execute then
  begin
    sDestino := SaveDialog1.FileName;
    bPDFGuardado := False;
    if bOrigenDisponible then
    begin
      if not SameText(ExpandFileName(sSrc), ExpandFileName(sDestino)) then
        TFile.Copy(sSrc, sDestino, True);
      bPDFGuardado := True;
    end
    else if FComandos <> '' then
    begin
      if sSrc <> '' then
      begin
        if ExtractFilePath(sSrc) <> '' then
          ForceDirectories(ExtractFilePath(sSrc));
        ExportarAPDF(FComandos, sSrc);
        bOrigenDisponible := FileExists(sSrc);
      end;
      if bOrigenDisponible then
      begin
        if not SameText(ExpandFileName(sSrc), ExpandFileName(sDestino)) then
          TFile.Copy(sSrc, sDestino, True);
      end
      else
      begin
        ExportarAPDF(FComandos, sDestino);
        FRutaPDFReal := sDestino;
      end;
      bPDFGuardado := True;
    end
    else
      ShowMessage_fza(SAvisoSinComandosESCPOSPDF);
    if bPDFGuardado then
      ShowMessage_fza(Format(SInfoPDFGuardado, [sDestino]));
  end;
end;

procedure TFormVisualizador.btnPNGClick(Sender: TObject);
begin
  SaveDialog1.Filter := SFiltroArchivoPngTicket;
  SaveDialog1.DefaultExt := 'png';
  SaveDialog1.FileName := Format(
    SNombreArchivoTicket,
    [FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now)]) + '.png';
  if SaveDialog1.Execute then
  begin
    GuardarPNG(SaveDialog1.FileName);
    ShowMessage_fza(Format(SInfoPNGGuardado, [SaveDialog1.FileName]));
  end;
end;

end.
