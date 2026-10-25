{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionPedidoOriginal                }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.1.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presenta las paginas TIFF del pedido original asociado a una sesion.      }
{    Encapsula carga, navegacion, zoom y arrastre sin conocer el formulario.   }
{                                                                              }
{    Zoom fijo: el boton Fijar zoom decide que pasa al cargar otro pedido.     }
{    Suelto (modo ajuste) cada carga encaja la pagina en el contenedor;        }
{    pulsado se respeta el zoom elegido. Acercar, alejar, zoom real y la       }
{    rueda fijan el zoom y dejan el boton pulsado; Ajustar ventana encaja      }
{    la pagina actual sin tocar el estado del boton.                           }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionPedidoOriginal;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  cxButtons,
  cxLabel;

type
  TObtenerSesionPedidoOriginal = reference to function(
    out ASerie, ANumero: string): Boolean;

  // Que se conserva al repintar la pagina activa:
  //   vpoAjustar        encaja la pagina en el contenedor (modo ajuste)
  //   vpoConservarZoom  mantiene el zoom fijado y vuelve al inicio del scroll
  //   vpoConservarVista mantiene zoom y desplazamiento (cambio de pagina)
  TVistaPedidoOriginal = (vpoAjustar, vpoConservarZoom, vpoConservarVista);

  TEntornoVisorPedidoOriginalSesion = record
    Contenedor: TScrollBox;
    Imagen: TImage;
    EtiquetaPagina: TcxLabel;
    BotonAnterior: TcxButton;
    BotonSiguiente: TcxButton;
    BotonAlejar: TcxButton;
    BotonAcercar: TcxButton;
    BotonAjustar: TcxButton;
    BotonZoomReal: TcxButton;
    BotonFijarZoom: TcxButton;
    ObtenerDirectorio: TFunc<string>;
    ObtenerSesion: TObtenerSesionPedidoOriginal;
  end;

  TVisorPedidoOriginalSesion = class
  private
    FEntorno: TEntornoVisorPedidoOriginalSesion;
    FPaginas: TArray<string>;
    FIndicePagina: Integer;
    FZoom: Double;
    FModoAjuste: Boolean;
    FActualizandoBoton: Boolean;
    FImagenOriginal: TPicture;
    FArrastrando: Boolean;
    FEventosConectados: Boolean;
    FInicioArrastre: TPoint;
    FInicioScroll: TPoint;
    procedure ConectarEventos;
    procedure ConfigurarBarra;
    procedure DesconectarEventos;
    procedure MostrarPagina(AVista: TVistaPedidoOriginal);
    procedure AplicarZoom(AZoom: Double);
    procedure FijarZoom(AZoom: Double);
    procedure EstablecerModoAjuste(AModoAjuste: Boolean);
    procedure Ajustar;
    procedure CambiarPagina(ADesplazamiento: Integer);
    procedure PaginaAnteriorClick(Sender: TObject);
    procedure PaginaSiguienteClick(Sender: TObject);
    procedure AlejarClick(Sender: TObject);
    procedure AcercarClick(Sender: TObject);
    procedure AjustarClick(Sender: TObject);
    procedure ZoomRealClick(Sender: TObject);
    procedure FijarZoomClick(Sender: TObject);
    procedure ImagenMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImagenMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ImagenMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ContenedorMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  public
    constructor Create(const AEntorno: TEntornoVisorPedidoOriginalSesion);
    destructor Destroy; override;
    procedure Cargar;
    procedure CargarSiVacio;
    function CantidadPaginas: Integer;
  end;

function LimitarZoomPedidoOriginal(AZoom: Double): Double;
function ResolverIndicePedidoOriginal(AIndiceActual, ADesplazamiento,
  ACantidadPaginas: Integer): Integer;
function ResolverVistaCargaPedidoOriginal(
  AModoAjuste: Boolean): TVistaPedidoOriginal;

implementation

uses
  inLibArchivosPedidoSesion, inLibMsgCompras, cxEdit;

function LimitarZoomPedidoOriginal(AZoom: Double): Double;
begin
  Result := AZoom;
  if Result < 0.10 then
    Result := 0.10;
  if Result > 5 then
    Result := 5;
end;

function ResolverIndicePedidoOriginal(AIndiceActual, ADesplazamiento,
  ACantidadPaginas: Integer): Integer;
var
  iCandidato: Integer;
begin
  Result := AIndiceActual;
  iCandidato := AIndiceActual + ADesplazamiento;
  if (iCandidato >= 0) and (iCandidato < ACantidadPaginas) then
    Result := iCandidato;
end;

function ResolverVistaCargaPedidoOriginal(
  AModoAjuste: Boolean): TVistaPedidoOriginal;
begin
  // Cargar un pedido distinto solo reencaja la imagen si nadie ha fijado
  // un zoom. Con zoom fijado se respeta el del usuario y se empieza a ver
  // el documento por su esquina superior izquierda.
  if AModoAjuste then
    Result := vpoAjustar
  else
    Result := vpoConservarZoom;
end;

procedure ValidarEntornoVisorPedidoOriginal(
  const AEntorno: TEntornoVisorPedidoOriginalSesion);
begin
  if not Assigned(AEntorno.Contenedor) then
    raise EArgumentNilException.Create('AEntorno.Contenedor');
  if not Assigned(AEntorno.Imagen) then
    raise EArgumentNilException.Create('AEntorno.Imagen');
  if not Assigned(AEntorno.EtiquetaPagina) then
    raise EArgumentNilException.Create('AEntorno.EtiquetaPagina');
  if not Assigned(AEntorno.BotonAnterior) then
    raise EArgumentNilException.Create('AEntorno.BotonAnterior');
  if not Assigned(AEntorno.BotonSiguiente) then
    raise EArgumentNilException.Create('AEntorno.BotonSiguiente');
  if not Assigned(AEntorno.BotonAlejar) then
    raise EArgumentNilException.Create('AEntorno.BotonAlejar');
  if not Assigned(AEntorno.BotonAcercar) then
    raise EArgumentNilException.Create('AEntorno.BotonAcercar');
  if not Assigned(AEntorno.BotonAjustar) then
    raise EArgumentNilException.Create('AEntorno.BotonAjustar');
  if not Assigned(AEntorno.BotonZoomReal) then
    raise EArgumentNilException.Create('AEntorno.BotonZoomReal');
  if not Assigned(AEntorno.BotonFijarZoom) then
    raise EArgumentNilException.Create('AEntorno.BotonFijarZoom');
  if not Assigned(AEntorno.ObtenerDirectorio) then
    raise EArgumentNilException.Create('AEntorno.ObtenerDirectorio');
  if not Assigned(AEntorno.ObtenerSesion) then
    raise EArgumentNilException.Create('AEntorno.ObtenerSesion');
end;

constructor TVisorPedidoOriginalSesion.Create(
  const AEntorno: TEntornoVisorPedidoOriginalSesion);
begin
  inherited Create;
  ValidarEntornoVisorPedidoOriginal(AEntorno);
  FEntorno := AEntorno;
  ConfigurarBarra;
  FImagenOriginal := TPicture.Create;
  FZoom := 1;
  ConectarEventos;
  EstablecerModoAjuste(True);
end;

destructor TVisorPedidoOriginalSesion.Destroy;
begin
  DesconectarEventos;
  FreeAndNil(FImagenOriginal);
  inherited Destroy;
end;

procedure TVisorPedidoOriginalSesion.ConectarEventos;
begin
  FEntorno.BotonAnterior.OnClick := PaginaAnteriorClick;
  FEntorno.BotonSiguiente.OnClick := PaginaSiguienteClick;
  FEntorno.BotonAlejar.OnClick := AlejarClick;
  FEntorno.BotonAcercar.OnClick := AcercarClick;
  FEntorno.BotonAjustar.OnClick := AjustarClick;
  FEntorno.BotonZoomReal.OnClick := ZoomRealClick;
  FEntorno.BotonFijarZoom.OnClick := FijarZoomClick;
  FEntorno.Imagen.OnMouseDown := ImagenMouseDown;
  FEntorno.Imagen.OnMouseMove := ImagenMouseMove;
  FEntorno.Imagen.OnMouseUp := ImagenMouseUp;
  FEntorno.Contenedor.OnMouseWheel := ContenedorMouseWheel;
  FEventosConectados := True;
end;

procedure TVisorPedidoOriginalSesion.ConfigurarBarra;
var
  Boton: TcxButton;
begin
  // Align recalcula el espacio cuando idioma, tema o DPI cambian el ancho.
  for Boton in TArray<TcxButton>.Create(FEntorno.BotonAnterior,
    FEntorno.BotonSiguiente, FEntorno.BotonAlejar, FEntorno.BotonAcercar,
    FEntorno.BotonAjustar, FEntorno.BotonZoomReal,
    FEntorno.BotonFijarZoom) do
  begin
    Boton.AlignWithMargins := True;
    Boton.Margins.SetBounds(4, 3, 0, 3);
    Boton.Align := alLeft;
  end;
  FEntorno.EtiquetaPagina.AutoSize := False;
  FEntorno.EtiquetaPagina.AlignWithMargins := True;
  FEntorno.EtiquetaPagina.Margins.SetBounds(8, 3, 4, 3);
  FEntorno.EtiquetaPagina.Properties.WordWrap := False;
  FEntorno.EtiquetaPagina.Properties.Alignment.Vert := taVCenter;
  FEntorno.EtiquetaPagina.Align := alClient;
end;

procedure TVisorPedidoOriginalSesion.DesconectarEventos;
begin
  if FEventosConectados then
  begin
    FEntorno.BotonAnterior.OnClick := nil;
    FEntorno.BotonSiguiente.OnClick := nil;
    FEntorno.BotonAlejar.OnClick := nil;
    FEntorno.BotonAcercar.OnClick := nil;
    FEntorno.BotonAjustar.OnClick := nil;
    FEntorno.BotonZoomReal.OnClick := nil;
    FEntorno.BotonFijarZoom.OnClick := nil;
    FEntorno.Imagen.OnMouseDown := nil;
    FEntorno.Imagen.OnMouseMove := nil;
    FEntorno.Imagen.OnMouseUp := nil;
    FEntorno.Contenedor.OnMouseWheel := nil;
    FEventosConectados := False;
  end;
end;

procedure TVisorPedidoOriginalSesion.Cargar;
var
  sNumero: string;
  sSerie: string;
begin
  FPaginas := nil;
  FIndicePagina := 0;
  FImagenOriginal.Assign(nil);
  FEntorno.Imagen.Picture.Assign(nil);
  if FEntorno.ObtenerSesion(sSerie, sNumero) then
    FPaginas := ListarPaginasPedidoSesion(
      FEntorno.ObtenerDirectorio(),
      sSerie,
      sNumero);
  MostrarPagina(ResolverVistaCargaPedidoOriginal(FModoAjuste));
end;

procedure TVisorPedidoOriginalSesion.CargarSiVacio;
begin
  if Length(FPaginas) = 0 then
    Cargar;
end;

function TVisorPedidoOriginalSesion.CantidadPaginas: Integer;
begin
  Result := Length(FPaginas);
end;

procedure TVisorPedidoOriginalSesion.MostrarPagina(
  AVista: TVistaPedidoOriginal);
var
  iScrollHorizontal: Integer;
  iScrollVertical: Integer;
  oImagen: TWICImage;
  rZoomAnterior: Double;
  sFichero: string;
begin
  rZoomAnterior := FZoom;
  iScrollHorizontal := FEntorno.Contenedor.HorzScrollBar.Position;
  iScrollVertical := FEntorno.Contenedor.VertScrollBar.Position;
  FEntorno.Imagen.Picture.Assign(nil);
  FImagenOriginal.Assign(nil);
  if (FIndicePagina >= 0) and
     (FIndicePagina <= High(FPaginas)) then
  begin
    sFichero := FPaginas[FIndicePagina];
    if FileExists(sFichero) then
    begin
      oImagen := TWICImage.Create;
      try
        oImagen.LoadFromFile(sFichero);
        FImagenOriginal.Assign(oImagen);
        FEntorno.Imagen.Picture.Assign(FImagenOriginal);
      finally
        oImagen.Free;
      end;
      case AVista of
        vpoConservarVista:
          begin
            AplicarZoom(rZoomAnterior);
            FEntorno.Contenedor.HorzScrollBar.Position := iScrollHorizontal;
            FEntorno.Contenedor.VertScrollBar.Position := iScrollVertical;
          end;
        vpoConservarZoom:
          begin
            AplicarZoom(rZoomAnterior);
            FEntorno.Contenedor.HorzScrollBar.Position := 0;
            FEntorno.Contenedor.VertScrollBar.Position := 0;
          end;
      else
        Ajustar;
      end;
    end;
  end;
  if Length(FPaginas) = 0 then
    FEntorno.EtiquetaPagina.Caption := SCaptionSinPaginasPedidoOriginal
  else
    FEntorno.EtiquetaPagina.Caption := Format(
      SCaptionPaginaPedidoOriginal,
      [FIndicePagina + 1, Length(FPaginas), FZoom * 100]);
  FEntorno.BotonAnterior.Enabled := FIndicePagina > 0;
  FEntorno.BotonSiguiente.Enabled :=
    FIndicePagina < High(FPaginas);
end;

procedure TVisorPedidoOriginalSesion.AplicarZoom(AZoom: Double);
begin
  FZoom := LimitarZoomPedidoOriginal(AZoom);
  if Assigned(FImagenOriginal.Graphic) and
     (not FImagenOriginal.Graphic.Empty) then
  begin
    FEntorno.Imagen.Width := Round(FImagenOriginal.Width * FZoom);
    FEntorno.Imagen.Height := Round(FImagenOriginal.Height * FZoom);
    if FEntorno.Imagen.Width < FEntorno.Contenedor.ClientWidth then
      FEntorno.Imagen.Left :=
        (FEntorno.Contenedor.ClientWidth - FEntorno.Imagen.Width) div 2
    else
      FEntorno.Imagen.Left := 0;
    if FEntorno.Imagen.Height < FEntorno.Contenedor.ClientHeight then
      FEntorno.Imagen.Top :=
        (FEntorno.Contenedor.ClientHeight - FEntorno.Imagen.Height) div 2
    else
      FEntorno.Imagen.Top := 0;
    FEntorno.EtiquetaPagina.Caption := Format(
      SCaptionPaginaPedidoOriginal,
      [FIndicePagina + 1, Length(FPaginas), FZoom * 100]);
  end;
end;

procedure TVisorPedidoOriginalSesion.EstablecerModoAjuste(
  AModoAjuste: Boolean);
begin
  // El boton es el reflejo del modo: siempre se escribe desde aqui, tanto
  // si el cambio viene de pulsarlo como si viene de tocar el zoom. El
  // testigo evita reentrar si escribir Down acabara disparando OnClick.
  if FActualizandoBoton then
    Exit;
  FActualizandoBoton := True;
  try
    FModoAjuste := AModoAjuste;
    FEntorno.BotonFijarZoom.SpeedButtonOptions.Down := not FModoAjuste;
  finally
    FActualizandoBoton := False;
  end;
end;

procedure TVisorPedidoOriginalSesion.FijarZoom(AZoom: Double);
begin
  // Zoom elegido por el usuario: se abandona el modo ajuste para que las
  // siguientes cargas (cambio de sesion o reimportacion) lo respeten.
  EstablecerModoAjuste(False);
  AplicarZoom(AZoom);
end;

procedure TVisorPedidoOriginalSesion.Ajustar;
var
  rAlto: Double;
  rAncho: Double;
  rZoom: Double;
begin
  if Assigned(FImagenOriginal.Graphic) and
     (FImagenOriginal.Width > 0) and
     (FImagenOriginal.Height > 0) then
  begin
    rAncho := (FEntorno.Contenedor.ClientWidth - 16) /
      FImagenOriginal.Width;
    rAlto := (FEntorno.Contenedor.ClientHeight - 16) /
      FImagenOriginal.Height;
    rZoom := rAncho;
    if rAlto < rZoom then
      rZoom := rAlto;
    AplicarZoom(rZoom);
  end;
end;

procedure TVisorPedidoOriginalSesion.CambiarPagina(
  ADesplazamiento: Integer);
var
  iNueva: Integer;
begin
  iNueva := ResolverIndicePedidoOriginal(
    FIndicePagina,
    ADesplazamiento,
    Length(FPaginas));
  if iNueva <> FIndicePagina then
  begin
    FIndicePagina := iNueva;
    MostrarPagina(vpoConservarVista);
  end;
end;

procedure TVisorPedidoOriginalSesion.PaginaAnteriorClick(Sender: TObject);
begin
  CambiarPagina(-1);
end;

procedure TVisorPedidoOriginalSesion.PaginaSiguienteClick(Sender: TObject);
begin
  CambiarPagina(1);
end;

procedure TVisorPedidoOriginalSesion.AlejarClick(Sender: TObject);
begin
  FijarZoom(FZoom / 1.20);
end;

procedure TVisorPedidoOriginalSesion.AcercarClick(Sender: TObject);
begin
  FijarZoom(FZoom * 1.20);
end;

procedure TVisorPedidoOriginalSesion.AjustarClick(Sender: TObject);
begin
  // Encaja la pagina que se esta viendo sin decidir por el usuario que
  // pasara con la siguiente: eso lo manda el boton Fijar zoom. Con el
  // zoom fijado, el zoom recien encajado es el que se conserva.
  Ajustar;
end;

procedure TVisorPedidoOriginalSesion.ZoomRealClick(Sender: TObject);
begin
  FijarZoom(1);
end;

procedure TVisorPedidoOriginalSesion.FijarZoomClick(Sender: TObject);
begin
  // El boton llega aqui ya conmutado por su GroupIndex; se reescribe su
  // estado desde EstablecerModoAjuste para no depender de ese detalle.
  EstablecerModoAjuste(not FModoAjuste);
  if FModoAjuste then
    Ajustar;
end;

procedure TVisorPedidoOriginalSesion.ImagenMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FArrastrando := True;
    FInicioArrastre := FEntorno.Imagen.ClientToScreen(Point(X, Y));
    FInicioScroll := Point(
      FEntorno.Contenedor.HorzScrollBar.Position,
      FEntorno.Contenedor.VertScrollBar.Position);
    FEntorno.Imagen.Cursor := crSizeAll;
  end;
end;

procedure TVisorPedidoOriginalSesion.ImagenMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  PuntoActual: TPoint;
begin
  if FArrastrando and (ssLeft in Shift) then
  begin
    PuntoActual := FEntorno.Imagen.ClientToScreen(Point(X, Y));
    FEntorno.Contenedor.HorzScrollBar.Position :=
      FInicioScroll.X - (PuntoActual.X - FInicioArrastre.X);
    FEntorno.Contenedor.VertScrollBar.Position :=
      FInicioScroll.Y - (PuntoActual.Y - FInicioArrastre.Y);
  end
  else if FArrastrando then
    FArrastrando := False;
end;

procedure TVisorPedidoOriginalSesion.ImagenMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FArrastrando := False;
    FEntorno.Imagen.Cursor := crHandPoint;
  end;
end;

procedure TVisorPedidoOriginalSesion.ContenedorMouseWheel(
  Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta > 0 then
    FijarZoom(FZoom * 1.10)
  else if WheelDelta < 0 then
    FijarZoom(FZoom / 1.10);
  Handled := True;
end;

end.
