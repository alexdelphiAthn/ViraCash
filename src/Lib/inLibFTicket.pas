{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFTicket                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Composición y envío de tickets a impresoras térmicas ESC/POS.             }
{    Soporta fuentes, alineación, imágenes, corte de papel y apertura de cajón.}
{******************************************************************************}
unit inLibFTicket;

interface
uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,      // TBitmap de VCL
  Winapi.WinSpool;   // QUITAR Winapi.Windows de aquí
const
  N_CHAR_LIN = 42;
type
  TFuenteTermica = (ftRasterA, ftRasterB, ftRasterC);
  TAlineacion = (alIzquierda, alCentro, alDerecha);
  TTicketTermico = class
  private
    FComandos: TStringBuilder;
    FNombreImpresora: string;
    function ObtenerComandoFuente(AFuente: TFuenteTermica): string;
    function ObtenerComandoAlineacion(AAlineacion: TAlineacion): string;
  public
    constructor Create(const ANombreImpresora: string);
    destructor Destroy; override;
    procedure Inicializar;
    procedure ConfigurarEspanol;
    function ObtenerComandos: string;
    procedure SeleccionarFuente(AFuente: TFuenteTermica);
    procedure Alinear(AAlineacion: TAlineacion);
    procedure Negrita(AActivar: Boolean);
    procedure Subrayado(AActivar: Boolean);
    procedure TamanoDoble(AAncho, AAlto: Boolean);
    procedure EscribirLinea(const ATexto: string);
    procedure EscribirTexto(const ATexto: string);
    procedure SaltarLineas(ACantidad: Integer);
    procedure LineaSeparadora(ACaracter: Char = '-');
    procedure ImprimirImagen(ABitmap: Vcl.Graphics.TBitmap;
                             AEscala: Integer = 3);
    // Imagen ya escalada al ancho de la impresora (576 puntos en 80 mm):
    // umbral a monocromo por ScanLine y envío en bloques GS v 0 para no
    // superar el búfer de las impresoras térmicas.
    procedure ImprimirImagenRaster(ABitmap: Vcl.Graphics.TBitmap);
    procedure CortarPapel(AParcial: Boolean = False);
    procedure AvanzarYCortarPapel(
      ACantidadLineas: Integer = 9;
      AParcial: Boolean = False);
    procedure AbrirCajon;

    procedure TextoColumnas(const AIzq,
                            ADer: string;
                            AAncho: Integer=N_CHAR_LIN);
    procedure Imprimir;
    procedure Limpiar;
    procedure ImprimirQRNativo(const ATexto: string;
                               ATamanoModulo: Integer = 8;
                               ANivelError: Integer = 48);
    procedure ImprimirEAN13Nativo(const ACodigo: string;
                                  AAltura: Integer = 80);
    property NombreImpresora: string read FNombreImpresora
                                     write FNombreImpresora;
  end;

  procedure EnviarComandoRAW(const ANombreImpresora: string;
                             const ADatos: string);

  // Columna izquierda de una línea de artículo: código relleno a 26 y
  // cantidad. Si la cantidad lleva tipo ('2,35 m') y no cabe junto a
  // ADerecha en N_CHAR_LIN, recorta el relleno del código.
  function ColumnaArticuloTicket(const ACodigo, ACantidad,
    ADerecha: string): string;
  function TextoDescuentoTicket(APrecioSalida, APorcentaje,
    AImporte: Double): string;

implementation

uses
  Winapi.Windows, inLibMsgFacturas, inLibMsgTickets;

const
  ESC = #27;
  GS = #29;
  // Página de códigos 858 - Soporta español
  CMD_CODEPAGE_858 = ESC + 't' + #19;
  CMD_INICIALIZAR = ESC + '@';
  CMD_FUENTE_A = ESC + 'M' + #0;
  CMD_FUENTE_B = ESC + 'M' + #1;
  CMD_FUENTE_C = ESC + 'M' + #2;
  CMD_NEGRITA_ON = ESC + 'E' + #1;
  CMD_NEGRITA_OFF = ESC + 'E' + #0;
  CMD_SUBRAYADO_ON = ESC + '-' + #1;
  CMD_SUBRAYADO_OFF = ESC + '-' + #0;
  CMD_IZQUIERDA = ESC + 'a' + #0;
  CMD_CENTRO = ESC + 'a' + #1;
  CMD_DERECHA = ESC + 'a' + #2;
  CMD_TAMANO_NORMAL = GS + '!' + #0;
  CMD_CORTE_TOTAL = ESC + 'i';
  CMD_CORTE_PARCIAL = ESC + 'm';
  CMD_ABRIR_CAJON = ESC + 'p' + #0 + #50 + #250;

procedure TTicketTermico.ImprimirQRNativo(const ATexto: string;
                                          ATamanoModulo: Integer = 8;
                                          ANivelError: Integer = 48);
var
  pL, pH: Byte;
  DataLength: Integer;
begin
  DataLength := Length(ATexto) + 3;
  pL := DataLength mod 256;
  pH := DataLength div 256;
  Alinear(alCentro);
  // Usar #XX en lugar de GS + '(k' + Chr()...
  FComandos.Append(#29#40#107#4#0#49#65#50#0);
  FComandos.Append(#29#40#107#3#0#49#67 + Chr(ATamanoModulo));
  FComandos.Append(#29#40#107#3#0#49#69 + Chr(ANivelError));
  FComandos.Append(#29#40#107 + Chr(pL) + Chr(pH) + #49#80#48 + ATexto);
  FComandos.Append(#29#40#107#3#0#49#81#48);
  FComandos.Append(#13#10);
  Alinear(alIzquierda);
end;

procedure TTicketTermico.ImprimirEAN13Nativo(const ACodigo: string;
                                             AAltura: Integer = 80);
var
  sDigitos: string;
begin
  // EAN-13 nativo (GS k formato B, m=67). Se envían los 13 dígitos con el
  // dígito de control ya calculado; el HRI se imprime debajo (GS H 2).
  sDigitos := Trim(ACodigo);
  if Length(sDigitos) = 13 then
  begin
    Alinear(alCentro);
    FComandos.Append(GS + 'h' + Chr(AAltura));   // altura en puntos
    FComandos.Append(GS + 'w' + #2);             // ancho de módulo
    FComandos.Append(GS + 'H' + #2);             // HRI debajo del código
    FComandos.Append(GS + 'f' + #0);             // fuente HRI A
    FComandos.Append(GS + 'k' + #67 +
                     Chr(Length(sDigitos)) + sDigitos);
    FComandos.Append(#13#10);
    Alinear(alIzquierda);
  end;
end;

constructor TTicketTermico.Create(const ANombreImpresora: string);
begin
  inherited Create;
  FNombreImpresora := ANombreImpresora;
  FComandos := TStringBuilder.Create;
end;

destructor TTicketTermico.Destroy;
begin
  FreeAndNil(FComandos);
  inherited;
end;

procedure TTicketTermico.Inicializar;
begin
  FComandos.Append(CMD_INICIALIZAR);
  ConfigurarEspanol;
end;

function TTicketTermico.ObtenerComandoFuente(AFuente: TFuenteTermica): string;
begin
  case AFuente of
    ftRasterA: Result := CMD_FUENTE_A;
    ftRasterB: Result := CMD_FUENTE_B;
    ftRasterC: Result := CMD_FUENTE_C;
  else
    Result := CMD_FUENTE_A;
  end;
end;

function TTicketTermico.ObtenerComandos: string;
begin
  Result := FComandos.ToString;
end;

function TTicketTermico.ObtenerComandoAlineacion(
  AAlineacion: TAlineacion): string;
begin
  case AAlineacion of
    alIzquierda: Result := CMD_IZQUIERDA;
    alCentro: Result := CMD_CENTRO;
    alDerecha: Result := CMD_DERECHA;
  else
    Result := CMD_IZQUIERDA;
  end;
end;
procedure TTicketTermico.SeleccionarFuente(AFuente: TFuenteTermica);
begin
  FComandos.Append(ObtenerComandoFuente(AFuente));
end;

procedure TTicketTermico.Alinear(AAlineacion: TAlineacion);
begin
  FComandos.Append(ObtenerComandoAlineacion(AAlineacion));
end;

procedure TTicketTermico.Negrita(AActivar: Boolean);
begin
  if AActivar then
    FComandos.Append(CMD_NEGRITA_ON)
  else
    FComandos.Append(CMD_NEGRITA_OFF);
end;

procedure TTicketTermico.Subrayado(AActivar: Boolean);
begin
  if AActivar then
    FComandos.Append(CMD_SUBRAYADO_ON)
  else
    FComandos.Append(CMD_SUBRAYADO_OFF);
end;
procedure TTicketTermico.TamanoDoble(AAncho, AAlto: Boolean);
var
  Valor: Byte;
begin
  Valor := 0;
  if AAncho then
    Valor := Valor or $20;
  if AAlto then
    Valor := Valor or $10;
  FComandos.Append(GS + '!' + Chr(Valor));
end;

procedure TTicketTermico.EscribirLinea(const ATexto: string);
begin
  FComandos.Append(ATexto + #13#10);
end;

procedure TTicketTermico.EscribirTexto(const ATexto: string);
begin
  FComandos.Append(ATexto);
end;

procedure TTicketTermico.SaltarLineas(ACantidad: Integer);
begin
  FComandos.Append(ESC + 'd' + Chr(ACantidad));
end;

procedure TTicketTermico.LineaSeparadora(ACaracter: Char);
begin
  EscribirLinea(StringOfChar(ACaracter, N_CHAR_LIN));
end;

function ColumnaArticuloTicket(const ACodigo, ACantidad,
  ADerecha: string): string;
var
  iRecortar: Integer;
  iRelleno: Integer;
  sCodigo: string;
begin
  sCodigo := Format('%-26s', [Copy(ACodigo, 1, 26)]);
  iRecortar := Length(sCodigo) + Length(ACantidad) + 1 +
    Length(ADerecha) - N_CHAR_LIN;
  // Siempre queda al menos un espacio entre código y cantidad.
  iRelleno := Length(sCodigo) - Length(TrimRight(sCodigo)) - 1;
  if iRecortar > iRelleno then
    iRecortar := iRelleno;
  if iRecortar > 0 then
    SetLength(sCodigo, Length(sCodigo) - iRecortar);
  Result := sCodigo + ACantidad;
end;

function TextoDescuentoTicket(APrecioSalida, APorcentaje,
  AImporte: Double): string;
var
  Descuento: string;
begin
  Result := '';
  if (APorcentaje > 0) or (AImporte > 0) then
  begin
    if APorcentaje > 0 then
      Descuento := FormatFloat('0.##', APorcentaje) + '%'
    else
      Descuento := FormatFloat('#,##0.00', AImporte) + ' €';
    Result := Format(STicketSalidaDescuento,
      [FormatFloat('#,##0.00', APrecioSalida), Descuento]);
  end;
end;

function AnchoColumnasTextoTicket(const ATexto: string): Integer;
var
  Caracter: Char;
begin
  Result := 0;
  for Caracter in ATexto do
  begin
    // Los ideogramas y signos de ancho completo ocupan dos columnas.
    if ((Caracter >= #$2E80) and (Caracter <= #$A4CF)) or
       ((Caracter >= #$AC00) and (Caracter <= #$D7A3)) or
       ((Caracter >= #$F900) and (Caracter <= #$FAFF)) or
       ((Caracter >= #$FE10) and (Caracter <= #$FE19)) or
       ((Caracter >= #$FE30) and (Caracter <= #$FE6F)) or
       ((Caracter >= #$FF01) and (Caracter <= #$FF60)) or
       ((Caracter >= #$FFE0) and (Caracter <= #$FFE6)) then
      Inc(Result, 2)
    else
      Inc(Result);
  end;
end;

procedure TTicketTermico.TextoColumnas(const AIzq,
                                       ADer: string;
                                       AAncho: Integer = N_CHAR_LIN);
var
  Espacios: Integer;
begin
  Espacios := AAncho - AnchoColumnasTextoTicket(AIzq) -
    AnchoColumnasTextoTicket(ADer);
  if Espacios < 1 then
    Espacios := 1;
  EscribirLinea(AIzq + StringOfChar(' ', Espacios) + ADer);
end;

procedure TTicketTermico.ImprimirImagen(ABitmap: Vcl.Graphics.TBitmap;
                                        AEscala: Integer = 3);
var
  x, y: Integer;
  BitmapMono, BitmapEscalado: Vcl.Graphics.TBitmap;
  Color: TColor;
  BytesAncho: Integer;
  DatosImagen: TBytes;
  ByteIndex: Integer;
  xSrc, ySrc: Integer;
begin
  BitmapEscalado := Vcl.Graphics.TBitmap.Create;
  BitmapMono := Vcl.Graphics.TBitmap.Create;
  try
    // Escalar el bitmap original
    BitmapEscalado.Width := ABitmap.Width * AEscala;
    BitmapEscalado.Height := ABitmap.Height * AEscala;
    // Escalar píxel por píxel para mantener nitidez
    for y := 0 to BitmapEscalado.Height - 1 do
    begin
      ySrc := y div AEscala;
      for x := 0 to BitmapEscalado.Width - 1 do
      begin
        xSrc := x div AEscala;
        BitmapEscalado.Canvas.Pixels[x, y] := ABitmap.Canvas.Pixels[xSrc, ySrc];
      end;
    end;
    // Convertir a monocromo
    BitmapMono.Monochrome := True;
    BitmapMono.Width := BitmapEscalado.Width;
    BitmapMono.Height := BitmapEscalado.Height;
    BitmapMono.Canvas.Draw(0, 0, BitmapEscalado);
    BytesAncho := (BitmapMono.Width + 7) div 8;
    SetLength(DatosImagen, BytesAncho * BitmapMono.Height);
    // Convertir imagen a bytes
    for y := 0 to BitmapMono.Height - 1 do
    begin
      for x := 0 to BitmapMono.Width - 1 do
      begin
        Color := BitmapMono.Canvas.Pixels[x, y];
        if (Color and $FFFFFF) < $808080 then
        begin
          ByteIndex := y * BytesAncho + (x div 8);
          DatosImagen[ByteIndex] := DatosImagen[ByteIndex]
             or (128 shr (x mod 8));
        end;
      end;
    end;
    Alinear(alCentro);
    FComandos.Append(GS + 'v0' + Chr(0) +
                     Chr(Lo(BytesAncho)) + Chr(Hi(BytesAncho)) +
                     Chr(Lo(BitmapMono.Height)) + Chr(Hi(BitmapMono.Height)));
    for ByteIndex := 0 to High(DatosImagen) do
      FComandos.Append(Chr(DatosImagen[ByteIndex]));
    FComandos.Append(#13#10);
  finally
    FreeAndNil(BitmapMono);
    FreeAndNil(BitmapEscalado);
  end;
  Alinear(alIzquierda);
end;

procedure TTicketTermico.ImprimirImagenRaster(ABitmap: Vcl.Graphics.TBitmap);
const
  cFilasPorBloque = 256;
var
  oBitmap24: Vcl.Graphics.TBitmap;
  pFila: PByte;
  aDatos: TBytes;
  iBytesAncho, iFilaInicio, iFilas, x, y, iIndice: Integer;
begin
  if (ABitmap = nil) or (ABitmap.Width = 0) or (ABitmap.Height = 0) then
    Exit;
  oBitmap24 := Vcl.Graphics.TBitmap.Create;
  try
    oBitmap24.PixelFormat := pf24bit;
    oBitmap24.SetSize(ABitmap.Width, ABitmap.Height);
    oBitmap24.Canvas.Draw(0, 0, ABitmap);
    iBytesAncho := (oBitmap24.Width + 7) div 8;
    Alinear(alCentro);
    iFilaInicio := 0;
    while iFilaInicio < oBitmap24.Height do
    begin
      iFilas := oBitmap24.Height - iFilaInicio;
      if iFilas > cFilasPorBloque then
        iFilas := cFilasPorBloque;
      SetLength(aDatos, iBytesAncho * iFilas);
      FillChar(aDatos[0], Length(aDatos), 0);
      for y := 0 to iFilas - 1 do
      begin
        pFila := oBitmap24.ScanLine[iFilaInicio + y];
        for x := 0 to oBitmap24.Width - 1 do
        begin
          // BGR: punto negro si la luminancia es menor que la mitad.
          if (pFila[0] * 114 + pFila[1] * 587 + pFila[2] * 299) <
             128 * 1000 then
          begin
            iIndice := y * iBytesAncho + (x div 8);
            aDatos[iIndice] := aDatos[iIndice] or (128 shr (x mod 8));
          end;
          Inc(pFila, 3);
        end;
      end;
      FComandos.Append(GS + 'v0' + Chr(0) +
                       Chr(Lo(iBytesAncho)) + Chr(Hi(iBytesAncho)) +
                       Chr(Lo(iFilas)) + Chr(Hi(iFilas)));
      for iIndice := 0 to High(aDatos) do
        FComandos.Append(Chr(aDatos[iIndice]));
      Inc(iFilaInicio, iFilas);
    end;
  finally
    FreeAndNil(oBitmap24);
  end;
  Alinear(alIzquierda);
end;

procedure TTicketTermico.ConfigurarEspanol;
begin
  FComandos.Append(CMD_CODEPAGE_858);
end;

procedure TTicketTermico.CortarPapel(AParcial: Boolean);
begin
  if AParcial then
    FComandos.Append(CMD_CORTE_PARCIAL)
  else
    FComandos.Append(CMD_CORTE_TOTAL);
end;

procedure TTicketTermico.AvanzarYCortarPapel(
  ACantidadLineas: Integer;
  AParcial: Boolean);
begin
  if ACantidadLineas > 0 then
    SaltarLineas(ACantidadLineas);
  CortarPapel(AParcial);
end;

procedure TTicketTermico.AbrirCajon;
begin
  FComandos.Append(CMD_ABRIR_CAJON);
end;

procedure TTicketTermico.Imprimir;
begin
  EnviarComandoRAW(FNombreImpresora, FComandos.ToString);
end;

procedure TTicketTermico.Limpiar;
begin
  FComandos.Clear;
end;

procedure GuardarDepuracionEscPos(const ADatos: string);
var
  Archivo: TextFile;
  Ruta: string;
  Indice: Integer;
begin
  Ruta := ExtractFilePath(ParamStr(0)) + 'ticket_escpos_debug_' +
    ParamStr(1) + '_' + ParamStr(2) + '_' + ParamStr(3) + '.txt';
  AssignFile(Archivo, Ruta);
  Rewrite(Archivo);
  try
    WriteLn(Archivo, '=== COMANDOS ESC/POS - DEBUG ===');
    WriteLn(Archivo, 'Longitud total: ' +
      IntToStr(Length(ADatos)) + ' bytes');
    WriteLn(Archivo, '');
    WriteLn(Archivo, '=== DUMP HEXADECIMAL ===');
    for Indice := 1 to Length(ADatos) do
    begin
      Write(Archivo, IntToHex(Ord(ADatos[Indice]), 2) + ' ');
      if Indice mod 16 = 0 then
        WriteLn(Archivo);
    end;
    WriteLn(Archivo, '');
    WriteLn(Archivo, '');
    WriteLn(Archivo, '=== CONTENIDO LEGIBLE ===');
    for Indice := 1 to Length(ADatos) do
    begin
      case ADatos[Indice] of
        #27: Write(Archivo, '<ESC>');
        #29: Write(Archivo, '<GS>');
        #10: WriteLn(Archivo, '<LF>');
        #13: Write(Archivo, '<CR>');
        #0..#8, #11..#12, #14..#26, #28, #30..#31:
          Write(Archivo, '<' + IntToHex(Ord(ADatos[Indice]), 2) + '>');
      else
        Write(Archivo, ADatos[Indice]);
      end;
    end;
    WriteLn(Archivo, '');
    WriteLn(Archivo, '=== FIN DEBUG ===');
  finally
    CloseFile(Archivo);
  end;
end;

function CodificarEscPosCp858(const ADatos: string): TBytes;
var
  Codificacion: TEncoding;
  Indice, iBytes, k: Integer;
begin
  Codificacion := TEncoding.GetEncoding(858);
  try
    Result := Codificacion.GetBytes(ADatos);
  finally
    FreeAndNil(Codificacion);
  end;
  // CP858 es de un byte por carácter: Result[i] corresponde a ADatos[i + 1].
  Indice := 0;
  while Indice < Length(Result) - 4 do
  begin
    if (Result[Indice] = $1D) and
       (Result[Indice + 1] = $76) and
       (Result[Indice + 2] = $30) and
       (Indice + 7 < Length(Result)) then
    begin
      // GS v 0 m xL xH yL yH + datos: binario, no texto. Se copian los
      // bytes originales para que la página de códigos no los altere.
      iBytes := (Ord(ADatos[Indice + 5]) + Ord(ADatos[Indice + 6]) * 256) *
                (Ord(ADatos[Indice + 7]) + Ord(ADatos[Indice + 8]) * 256);
      k := 3;
      while (k <= 7 + iBytes) and (Indice + k < Length(Result)) do
      begin
        Result[Indice + k] := Byte(Ord(ADatos[Indice + k + 1]));
        Inc(k);
      end;
      Inc(Indice, 8 + iBytes);
    end
    else if (Result[Indice] = $1D) and
       (Result[Indice + 1] = $28) and
       (Result[Indice + 2] = $6B) then
    begin
      if Indice + 4 < Length(ADatos) then
      begin
        Result[Indice + 3] := Ord(ADatos[Indice + 4]);
        Result[Indice + 4] := Ord(ADatos[Indice + 5]);
      end;
      Inc(Indice, 5);
    end
    else
      Inc(Indice);
  end;
end;

procedure EnviarDatosRawImpresora(
  const ANombreImpresora, ADatos: string);
var
  Impresora: THandle;
  Documento: TDocInfo1;
  BytesEscritos: DWORD;
  DatosRaw: TBytes;
begin
  if not OpenPrinter(PChar(ANombreImpresora), Impresora, nil) then
    raise Exception.CreateFmt(
      SErrorAbrirImpresoraTicket, [ANombreImpresora]);
  try
    Documento.pDocName := 'Ticket ViraCash';
    Documento.pOutputFile := nil;
    Documento.pDatatype := 'RAW';
    if StartDocPrinter(Impresora, 1, @Documento) = 0 then
      raise Exception.Create(SErrorIniciarDocumentoImpresora);
    try
      if StartPagePrinter(Impresora) then
      begin
        try
          DatosRaw := CodificarEscPosCp858(ADatos);
          if not WritePrinter(Impresora, @DatosRaw[0],
            Length(DatosRaw), BytesEscritos) then
            raise Exception.Create(SErrorEscribirImpresora);
        finally
          EndPagePrinter(Impresora);
        end;
      end;
      EndDocPrinter(Impresora);
    except
      on E: Exception do
      begin
        EndDocPrinter(Impresora);
        raise;
      end;
    end;
  finally
    ClosePrinter(Impresora);
  end;
end;

procedure EnviarComandoRAW(const ANombreImpresora: string;
                           const ADatos: string);
begin
  if (ANombreImpresora = 'DEBUG') or (ANombreImpresora = '') then
    GuardarDepuracionEscPos(ADatos)
  else
    EnviarDatosRawImpresora(ANombreImpresora, ADatos);
end;

end.
