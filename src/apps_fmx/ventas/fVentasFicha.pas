{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasFicha                                                  }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ficha de una línea de venta. En el listado no caben las diez columnas     }
{    con un tamaño legible en un móvil, así que el detalle completo se ve      }
{    aquí al tocar la fila. La UI se construye por código (sin .fmx).          }
{******************************************************************************}
unit fVentasFicha;

interface

uses
  System.Classes, System.UITypes,
  FMX.Forms, FMX.Controls, FMX.Objects, FMX.StdCtrls,
  VentasModelo, VentasTicket;

type
  TfrmFicha = class(TForm)
  private
    FContenido: TControl;
    FFoto: TImage;
    FBotonTicket: TButton;
    FEstadoTicket: TLabel;
    FLinea: TLineaVenta;
    FCancelacionTicket: ICancelacionTicketVenta;
    procedure AgregarDato(const AEtiqueta, AValor: string);
    procedure AgregarSeparador;
    procedure ConstruirBotones;
    procedure Construir(const ALinea: TLineaVenta;
      const ARutaFoto: string);
    procedure CancelarTicket;
    procedure FinalizarTicket(const AResultado: TResultadoTicketVenta);
    procedure IniciarTicket;
    procedure OnTicketClick(Sender: TObject);
    procedure OnFichaCerrar(Sender: TObject; var AAccion: TCloseAction);
    procedure OnCerrarClick(Sender: TObject);
  public
    destructor Destroy; override;
    class procedure Mostrar(AOwner: TComponent;
      const ALinea: TLineaVenta; const ARutaFoto: string);
  end;

implementation

uses
  System.SysUtils, System.Types, System.IOUtils,
  System.Threading, FMX.Types, FMX.Layouts, FMX.Graphics,
  VentasApi, VentasConfig, VentasVisor, TraduccionMovil;

const
  cEtiquetaSku = 'SKU';
  cEtiquetaPvp = 'PVP';

// Textos en español; Tr los traduce al idioma del dispositivo (TextosVentas).
const
  STituloDetalleVenta = 'Detalle de la venta';
  SBotonCerrarDetalleVenta = 'Cerrar';
  SEtiquetaFechaHora = 'Fecha y hora';
  SEtiquetaArticulo = 'Artículo';
  SEtiquetaColor = 'Color';
  SEtiquetaFamilia = 'Familia';
  SEtiquetaTemporada = 'Temporada';
  SEtiquetaProveedor = 'Proveedor';
  SEtiquetaCantidad = 'Cantidad';
  SEtiquetaPrecioCoste = 'Precio coste';
  SEtiquetaDescuento = 'Descuento';
  SEtiquetaPrecioVenta = 'Precio venta';
  SEtiquetaCosteTotal = 'Coste total';
  SEtiquetaTotalLinea = 'Total línea';
  SEtiquetaDocumento = 'Documento';
  SDetalleDocumentoLinea = '%s  línea %s';
  SEtiquetaEmpresa = 'Empresa';
  SEtiquetaEstado = 'Estado';
  SEstadoVentaAnulada = 'VENTA ANULADA';
  SBotonVerTicket = 'Ver ticket';
  SDescargandoTicket = 'Descargando ticket…';
  STicketNoIniciado = 'No se pudo iniciar la descarga del ticket.';

destructor TfrmFicha.Destroy;
begin
  CancelarTicket;
  inherited;
end;

function Moneda(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.00', AValor, FormatoIdioma) + ' €';
end;

function Cantidad(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.###', AValor, FormatoIdioma);
end;

{ Cada dato es una fila alineada arriba, así que se añaden en el mismo orden
  en que se quieren ver: la primera que se crea queda la primera. }
procedure TfrmFicha.AgregarDato(const AEtiqueta, AValor: string);
var
  lblEtiqueta: TLabel;
  lblValor: TLabel;
  layFila: TLayout;
begin
  layFila := TLayout.Create(Self);
  layFila.Parent := FContenido;
  layFila.Align := TAlignLayout.Top;
  layFila.Height := 34;
  layFila.Margins.Bottom := 2;
  lblEtiqueta := TLabel.Create(Self);
  lblEtiqueta.Parent := layFila;
  lblEtiqueta.Align := TAlignLayout.Left;
  lblEtiqueta.Width := 130;
  lblEtiqueta.Text := AEtiqueta;
  lblEtiqueta.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblEtiqueta.StyledSettings :=
    lblEtiqueta.StyledSettings - [TStyledSetting.FontColor];
  lblValor := TLabel.Create(Self);
  lblValor.Parent := layFila;
  lblValor.Align := TAlignLayout.Client;
  lblValor.Text := AValor;
  lblValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblValor.StyledSettings :=
    lblValor.StyledSettings - [TStyledSetting.Style];
end;

procedure TfrmFicha.AgregarSeparador;
var
  linSep: TLine;
begin
  linSep := TLine.Create(Self);
  linSep.Parent := FContenido;
  linSep.Align := TAlignLayout.Top;
  linSep.Height := 9;
  linSep.LineType := TLineType.Top;
  linSep.Margins.Bottom := 6;
end;

procedure TfrmFicha.ConstruirBotones;
var
  btnCerrar: TButton;
begin
  btnCerrar := TButton.Create(Self);
  btnCerrar.Parent := Self;
  btnCerrar.Align := TAlignLayout.Bottom;
  btnCerrar.Height := 52;
  btnCerrar.Margins.Rect := RectF(12, 8, 12, 12);
  btnCerrar.Text := Tr(SBotonCerrarDetalleVenta);
  btnCerrar.OnClick := OnCerrarClick;
  FBotonTicket := TButton.Create(Self);
  FBotonTicket.Parent := Self;
  FBotonTicket.Align := TAlignLayout.Bottom;
  FBotonTicket.Height := 48;
  FBotonTicket.Margins.Rect := RectF(12, 4, 12, 0);
  FBotonTicket.Text := Tr(SBotonVerTicket);
  FBotonTicket.OnClick := OnTicketClick;
  FEstadoTicket := TLabel.Create(Self);
  FEstadoTicket.Parent := Self;
  FEstadoTicket.Align := TAlignLayout.Bottom;
  FEstadoTicket.Height := 54;
  FEstadoTicket.Margins.Rect := RectF(12, 4, 12, 0);
  FEstadoTicket.WordWrap := True;
  FEstadoTicket.Visible := False;
end;

procedure TfrmFicha.Construir(const ALinea: TLineaVenta;
  const ARutaFoto: string);
var
  bHayFoto: Boolean;
  lblTitulo: TLabel;
  scbDatos: TVertScrollBox;
begin
  FLinea := ALinea;
  Self.Caption := Tr(STituloDetalleVenta);
  Self.OnClose := OnFichaCerrar;
  ConstruirBotones;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 52;
  lblTitulo.Margins.Rect := RectF(12, 10, 12, 0);
  lblTitulo.Text := ALinea.TituloLinea;
  lblTitulo.TextSettings.Font.Size := 19;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  lblTitulo.WordWrap := True;
  FFoto := TImage.Create(Self);
  FFoto.Parent := Self;
  FFoto.Align := TAlignLayout.Top;
  FFoto.Height := 190;
  FFoto.Margins.Rect := RectF(12, 6, 12, 6);
  FFoto.WrapMode := TImageWrapMode.Fit;
  bHayFoto := False;
  if (ARutaFoto <> '') and TFile.Exists(ARutaFoto) then
  begin
    // La caché la escribe otro hilo: un PNG corrupto no debe tumbar la ficha.
    try
      FFoto.Bitmap.LoadFromFile(ARutaFoto);
      bHayFoto := True;
    except
      bHayFoto := False;
    end;
  end;
  if not bHayFoto then
    FFoto.Height := 0;
  scbDatos := TVertScrollBox.Create(Self);
  scbDatos.Parent := Self;
  scbDatos.Align := TAlignLayout.Client;
  scbDatos.Margins.Rect := RectF(12, 0, 12, 0);
  FContenido := scbDatos;
  AgregarDato(Tr(SEtiquetaFechaHora),
    FechaVisible(ALinea.Fecha) + '  ' + ALinea.Hora);
  AgregarDato(Tr(SEtiquetaArticulo), ALinea.Articulo);
  AgregarDato(cEtiquetaSku, ALinea.Sku);
  AgregarDato(Tr(SEtiquetaColor), ALinea.Color);
  AgregarDato(Tr(SEtiquetaFamilia), ALinea.Familia);
  AgregarDato(Tr(SEtiquetaTemporada), ALinea.Temporada);
  AgregarDato(Tr(SEtiquetaProveedor), ALinea.Proveedor);
  AgregarSeparador;
  AgregarDato(Tr(SEtiquetaCantidad), Cantidad(ALinea.Cantidad));
  AgregarDato(Tr(SEtiquetaPrecioCoste), Moneda(ALinea.PrecioCoste));
  AgregarDato(Tr(cEtiquetaPvp), Moneda(ALinea.Pvp));
  AgregarDato(Tr(SEtiquetaDescuento),
    FormatFloat('#,##0.##', ALinea.PorcentajeDescuento, FormatoIdioma) +
    ' %   (' + Moneda(ALinea.ImporteDescuento) + ')');
  AgregarDato(Tr(SEtiquetaPrecioVenta), Moneda(ALinea.PrecioVenta));
  AgregarDato(Tr(SEtiquetaCosteTotal), Moneda(ALinea.TotalCoste));
  AgregarDato(Tr(SEtiquetaTotalLinea), Moneda(ALinea.TotalLinea));
  AgregarSeparador;
  AgregarDato(Tr(SEtiquetaDocumento),
    TrF(SDetalleDocumentoLinea, [ALinea.Documento, ALinea.Linea]));
  AgregarDato(Tr(SEtiquetaEmpresa), ALinea.Empresa);
  if ALinea.Anulada then
    AgregarDato(Tr(SEtiquetaEstado), Tr(SEstadoVentaAnulada));
end;

procedure TfrmFicha.OnCerrarClick(Sender: TObject);
begin
  CancelarTicket;
  ModalResult := mrOk;
end;

procedure TfrmFicha.OnFichaCerrar(Sender: TObject;
  var AAccion: TCloseAction);
begin
  CancelarTicket;
end;

procedure TfrmFicha.CancelarTicket;
begin
  if Assigned(FCancelacionTicket) then
    FCancelacionTicket.Cancelar;
end;

procedure TfrmFicha.FinalizarTicket(
  const AResultado: TResultadoTicketVenta);
var
  sError: string;
begin
  FBotonTicket.Enabled := True;
  FBotonTicket.Text := Tr(SBotonVerTicket);
  sError := AResultado.Error;
  if sError = '' then
    AbrirTicketVenta(AResultado.Contenido, sError);
  FEstadoTicket.Text := sError;
  FEstadoTicket.Visible := sError <> '';
end;

procedure TfrmFicha.IniciarTicket;
var
  oCancelacion: ICancelacionTicketVenta;
  oPeticion: TPeticionTicketVenta;
begin
  CancelarTicket;
  oCancelacion := TCancelacionTicketVenta.Create;
  FCancelacionTicket := oCancelacion;
  oPeticion.Empresa := FLinea.Empresa;
  oPeticion.Serie := FLinea.Serie;
  oPeticion.Numero := FLinea.Numero;
  oPeticion.UrlBase := oConfig.UrlBase;
  oPeticion.Token := oConfig.Token;
  FBotonTicket.Enabled := False;
  FBotonTicket.Text := Tr(SDescargandoTicket);
  FEstadoTicket.Visible := False;
  TTask.Run(
    procedure
    var
      oApi: TVentasApi;
      oResultado: TResultadoTicketVenta;
    begin
      oApi := TVentasApi.Create;
      try
        oResultado := oApi.DescargarTicket(oPeticion, oCancelacion);
      finally
        FreeAndNil(oApi);
      end;
      TThread.Queue(nil,
        procedure
        begin
          // La cancelación sobrevive a la ficha; no se accede al formulario
          // después de cerrarlo ni se abre un PDF de una petición anterior.
          if not oCancelacion.EstaCancelado then
            FinalizarTicket(oResultado);
        end);
    end);
end;

procedure TfrmFicha.OnTicketClick(Sender: TObject);
begin
  try
    IniciarTicket;
  except
    on E: Exception do
    begin
      FBotonTicket.Enabled := True;
      FBotonTicket.Text := Tr(SBotonVerTicket);
      FEstadoTicket.Text := Tr(STicketNoIniciado);
      FEstadoTicket.Visible := True;
    end;
  end;
end;

class procedure TfrmFicha.Mostrar(AOwner: TComponent;
  const ALinea: TLineaVenta; const ARutaFoto: string);
var
  frm: TfrmFicha;
begin
  frm := TfrmFicha.CreateNew(AOwner);
  try
    frm.Construir(ALinea, ARutaFoto);
  except
    FreeAndNil(frm);
    raise;
  end;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      // Se libera fuera del propio callback: FMX sigue tocando el
      // formulario cuando este vuelve.
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
    end);
end;

end.
