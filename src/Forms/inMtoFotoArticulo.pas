{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFotoArticulo                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.2.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario flotante (no modal, top-most) que muestra la foto del          }
{    articulo o SKU activo en la pantalla que lo invoca con Ctrl+F.        }
{    Render por GDI (TImage + Vcl.Imaging.PngImage).                           }
{                                                                              }
{    UI compacta con una barra de iconos y un panel desplegable para           }
{    resolucion, sustitucion, giro, borrado y layout. Cada accion expone su    }
{    descripcion mediante Hint. F11 abre o cierra el panel.                    }
{                                                                              }
{    Alt+F12 guarda la geometria de la ventana (igual patron que               }
{    inMtoConsultaOpe), via TLayoutSaver. FormShow restaura.                   }
{                                                                              }
{    Para uso dentro de un formulario modal existe el wrapper                  }
{    `inMtoModalFotoArticulo.TfrmModalFotoArticulo`.                           }
{******************************************************************************}
unit inMtoFotoArticulo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.StrUtils, System.Generics.Collections, Data.DB,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Imaging.PngImage, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  inMtoFrmBase, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit, cxLabel,
  cxDropDownEdit, cxRadioGroup, cxGroupBox, cxButtons, cxSpinEdit,
  JvComponentBase, JvEnterTab,
  Vcl.Menus, cxControls, cxMaskEdit,
  inLibFotos, inLibFotosNube, inLibLayoutForm,
  System.UITypes;

type
  TResolverArtSkuProc =
    procedure(out ACodArt, ACodSku: string) of object;
  TResolverFotoSesionProc =
    procedure(out ASerieSesion, ANumeroSesion: string;
      out ALinea: Integer; out ACodArtTentativo,
      ACodUnidad: string) of object;

  // Avisa del cambio de registro activo de un DataSource del Mto sin
  // tocar su OnDataChange: la pantalla puede reasignarlo (facturas al
  // reconstruir el modo con F1) sin desenganchar la foto.
  TEnlaceFotoFlotante = class(TDataLink)
  private
    FAlCambiar: TDataChangeEvent;
    procedure Avisar;
  protected
    procedure DataSetChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(ADataSource: TDataSource;
      AAlCambiar: TDataChangeEvent);
  end;

  TfrmFotoArticulo = class(TfrmBase)
    pnlTop           : TPanel;
    btnToggle        : TcxButton;
    btnDescargarNube : TcxButton;
    lblOrigen        : TcxLabel;
    btnMarcarPredeterminada: TcxButton;
    btnFotoAnterior  : TcxButton;
    lblNumeroFoto    : TcxLabel;
    btnFotoSiguiente : TcxButton;
    btnAnadirFoto    : TcxButton;
    pnlControles     : TPanel;
    rgResolucion     : TcxRadioGroup;
    lblNivel         : TcxLabel;
    cbbNivelSku      : TcxComboBox;
    btnCambiarArt    : TcxButton;
    btnCambiarSku    : TcxButton;
    btnQuitar        : TcxButton;
    btnRotarIzq      : TcxButton;
    btnRotarDer      : TcxButton;
    btnLayout        : TcxButton;
    pnlImage         : TPanel;
    imgFoto          : TImage;
    pnlTransparencia : TPanel;
    lblTransparencia : TcxLabel;
    spnTransparencia : TcxSpinEdit;
    dlgAbrirFoto     : TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure rgResolucionPropertiesEditValueChanged(Sender: TObject);
    procedure btnToggleClick(Sender: TObject);
    procedure btnDescargarNubeClick(Sender: TObject);
    procedure btnCambiarArtClick(Sender: TObject);
    procedure btnCambiarSkuClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnRotarIzqClick(Sender: TObject);
    procedure btnRotarDerClick(Sender: TObject);
    procedure btnLayoutClick(Sender: TObject);
    procedure btnFotoAnteriorClick(Sender: TObject);
    procedure btnFotoSiguienteClick(Sender: TObject);
    procedure btnAnadirFotoClick(Sender: TObject);
    procedure btnMarcarPredeterminadaClick(Sender: TObject);
    procedure spnTransparenciaPropertiesEditValueChanged(Sender: TObject);
  private
    FCodigoArt              : string;
    FCodigoSku              : string;
    FUltimaInfo             : TFotoInfo;
    // Persistencia de geometria (igual patron que inMtoConsultaOpe).
    FLayoutLoader           : TLayoutLoader;
    // Auto-refresh: un enlace por DataSource del Mto invocante. Cuando
    // cambia el registro activo de cualquiera se recarga la foto via
    // FPadreResolver. Un DataSource liberado suelta su enlace solo.
    FHooksDataSource        : TObjectList<TEnlaceFotoFlotante>;
    FPadreResolver          : TResolverArtSkuProc;
    FPadreResolverSesion    : TResolverFotoSesionProc;
    FAlCambiarFotoSesion    : TNotifyEvent;
    FGpImagen               : TGPImage;
    FRutaFotoActual         : string;
    FModoSesion             : Boolean;
    FSerieSesion            : string;
    FNumeroSesion           : string;
    FLineaSesion            : Integer;
    FCodigoArtTentativoSesion: string;
    FCodigoUnidadSesion     : string;
    FFotoDefinitivaSesion   : Boolean;
    FFotosColeccion         : TArray<TFotoInfo>;
    FIndiceFoto             : Integer;
    FInicializacionCompleta : Boolean;
    procedure AplicarAspectoBotonesCompactos;
    procedure AjustarBarraSuperior;
    procedure AjustarPanelControles;
    procedure CargarFotoActual;
    procedure CargarColeccionArticulo(
      const ANombrePreferido: string;
      AOrdenPreferido, AIndiceAlternativo: Integer);
    procedure SeleccionarFoto(AIndice: Integer);
    procedure MarcarFotoActualPredeterminada;
    procedure ActualizarControlesGaleria;
    procedure ActualizarOrigenFotoArticulo;
    procedure ActualizarCaptionArticulo;
    procedure ActualizarCaptionActual;
    function  ResolucionElegida: TFotoResolucion;
    procedure RellenarNivelesSku;
    function  ClaveNivelSeleccionado: string;
    function  SeleccionarRutaPredeterminada(
      out ARutaFoto: string): Boolean;
    procedure AsegurarPredeterminadaArticulo(
      const ARutaFoto: string);
    procedure DesengancharDataChange;
    procedure OnPadreDataChange(Sender: TObject; Field: TField);
    procedure DescargarFotosDeNube;
    procedure IntegrarFotosNube(const AArchivos: TArray<string>);
    function FotoNubeYaIntegrada(const AArchivo, AClave: string): Boolean;
    procedure PintarFotoGDIPlus;
    procedure RestaurarGeometriaGuardada;
    procedure VincularDataSourcesInterno(
      const ADataSources: array of TDataSource);
    procedure NotificarCambioFotoSesion;
    procedure PrepararControlesArticulo;
    procedure PrepararControlesSesion(AExpandir: Boolean);
  protected
    procedure Resize; override;
    procedure ToggleControles;
    procedure AjustarBotonToggle;
    procedure GuardarLayout;
  public
    procedure AplicarTraduccionActual; override;
    /// Carga la foto del par (articulo, sku). Llamar tras Create o cuando
    /// se quiera refrescar (al cambiar el registro activo).
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
    /// Engancha la pantalla a uno o varios DataSources del Mto
    /// invocante para auto-refresh cuando cambie el registro activo
    /// en cualquiera de ellos. `AResolver` se invoca tras cada cambio
    /// para obtener el nuevo par (articulo, sku). Pasar un array vacio
    /// desengancha todo. Cada DataSource conserva su handler previo
    /// encadenado, asi no se pisa logica del Mto.
    procedure VincularDataSources(const ADataSources: array of TDataSource;
                                  AResolver: TResolverArtSkuProc);
    /// Atajo retro-compatible: equivale a VincularDataSources con un
    /// solo DataSource. Se mantiene por los call sites que aun usan
    /// la firma vieja.
    procedure VincularMtoPadre(ADataSource: TDataSource;
                               AResolver: TResolverArtSkuProc);
    /// Vuelve a preguntar el artículo / SKU si la foto sigue a AMto.
    /// Para pantallas en las que depende de la pestaña activa, que
    /// cambia sin mover ningún DataSource.
    procedure RefrescarDesdePadre(AMto: TObject);
    procedure DesvincularPadre(AMto: TObject);
    procedure SetSesion(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodArtTentativo,
      ACodUnidad: string);
    procedure VincularSesion(
      const ADataSources: array of TDataSource;
      AResolver: TResolverFotoSesionProc;
      AAlCambiarFoto: TNotifyEvent);
    function CoincideSesion(const ASerieSesion,
      ANumeroSesion: string; ALinea: Integer;
      const ACodUnidad: string): Boolean;
    property CodigoArt: string read FCodigoArt;
    property CodigoSku: string read FCodigoSku;
  end;

/// Atajo: abre `frmFotoArticulo` (lo crea si no existe) y carga el par
/// pasado. Si el formulario ya estaba abierto, lo refresca y lo trae al
/// frente. Llamar desde el handler de Ctrl+F de los Mtos.
function FotoFlotanteActual: TfrmFotoArticulo;
procedure MostrarFotoFlotante(AOwner: TComponent;
                               const ACodArt, ACodSku: string);
procedure MostrarFotoSesionFlotante(AOwner: TComponent;
  const ASerieSesion, ANumeroSesion: string; ALinea: Integer;
  const ACodArtTentativo, ACodUnidad: string);

implementation

uses
  System.Hash,
  System.Math,
  inLibMensajesVcl,
  inLibMsgArticulos, inLibMsgCompras, inLibMsgComun,
  inLibMsgFotos;

{$R *.dfm}

type
  TIconoFoto = (
    ifChevronAbajo,
    ifChevronArriba,
    ifDescargar,
    ifEstrellaVacia,
    ifEstrellaLlena,
    ifAnterior,
    ifSiguiente,
    ifAnadir,
    ifSustituirPredeterminada,
    ifSustituirNivel,
    ifSustituirLinea,
    ifRotarIzquierda,
    ifRotarDerecha,
    ifEliminar,
    ifGuardarLayout);

  TSelectorFotoVariacion = class(TForm)
  private
    FFotosArticulos: TFotosArticulos;
    FFotos         : TArray<TFotoInfo>;
    FIndice        : Integer;
    FImagen        : TImage;
    FContador      : TLabel;
    FAnterior      : TcxButton;
    FSiguiente     : TcxButton;
    FUsar          : TButton;
    procedure ActualizarFoto;
    procedure AnteriorClick(Sender: TObject);
    procedure SiguienteClick(Sender: TObject);
    procedure FotoDobleClick(Sender: TObject);
    procedure TeclaPulsada(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  public
    constructor Create(AOwner: TComponent;
      AFotosArticulos: TFotosArticulos;
      const AFotos: TArray<TFotoInfo>); reintroduce;
    function Ejecutar(out AFoto: TFotoInfo): Boolean;
  end;

const
  SSvgInicio =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">' +
    '<g fill="none" stroke="#505050" stroke-width="2" ' +
    'stroke-linecap="round" stroke-linejoin="round">';
  SSvgFin = '</g></svg>';

function CuerpoIconoFoto(AIcono: TIconoFoto): string;
begin
  case AIcono of
    ifChevronAbajo:
      Result := '<path d="M5 9l7 7 7-7"/>';
    ifChevronArriba:
      Result := '<path d="M5 15l7-7 7 7"/>';
    ifDescargar:
      Result :=
        '<path d="M12 3v12M7 10l5 5 5-5M5 20h14"/>';
    ifEstrellaVacia:
      Result :=
        '<path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-3' +
        '-5.6 3 1.1-6.2L3 9.6l6.2-.9z"/>';
    ifEstrellaLlena:
      Result :=
        '<path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-3' +
        '-5.6 3 1.1-6.2L3 9.6l6.2-.9z" fill="#505050"/>';
    ifAnterior:
      Result := '<path d="M15 5l-7 7 7 7"/>';
    ifSiguiente:
      Result := '<path d="M9 5l7 7-7 7"/>';
    ifAnadir:
      Result := '<path d="M12 4v16M4 12h16"/>';
    ifSustituirPredeterminada:
      Result :=
        '<path d="M7 2l1.5 3 3.3.5-2.4 2.3.6 3.2-3-1.6-3 1.6' +
        '.6-3.2-2.4-2.3 3.3-.5z" fill="#505050"/>' +
        '<path d="M14 7h6v6M20 7a8 8 0 0 1-8 13"/>';
    ifSustituirNivel:
      Result :=
        '<rect x="3" y="4" width="9" height="9"/>' +
        '<path d="M7.5 4v9M3 8.5h9M14 7h6v6' +
        'M20 7a8 8 0 0 1-8 13"/>';
    ifSustituirLinea:
      Result :=
        '<path d="M3 5h9M3 9h8M3 13h6M14 7h6v6' +
        'M20 7a8 8 0 0 1-8 13"/>';
    ifRotarIzquierda:
      Result :=
        '<path d="M4 4v6h6M4.5 10a8 8 0 1 1 2 7"/>';
    ifRotarDerecha:
      Result :=
        '<path d="M20 4v6h-6M19.5 10a8 8 0 1 0-2 7"/>';
    ifEliminar:
      Result :=
        '<path d="M4 7h16M9 7V4h6v3M6 7l1 14h10l1-14' +
        'M10 11v6M14 11v6"/>';
    ifGuardarLayout:
      Result :=
        '<path d="M4 3h13l3 3v15H4zM7 3v7h9V3M7 21v-7h10v7"/>';
  end;
end;

procedure AsignarIconoFoto(AButton: TcxButton; AIcono: TIconoFoto);
var
  Flujo: TStringStream;
begin
  AButton.Caption := '';
  Flujo := TStringStream.Create(
    SSvgInicio + CuerpoIconoFoto(AIcono) + SSvgFin,
    TEncoding.UTF8);
  try
    AButton.OptionsImage.Glyph.LoadFromStream(Flujo);
    AButton.OptionsImage.Glyph.SourceDPI := 96;
    AButton.OptionsImage.Glyph.SourceWidth := 14;
    AButton.OptionsImage.Glyph.SourceHeight := 14;
  finally
    Flujo.Free;
  end;
end;

function RutaFotoDisponible(AFotosArticulos: TFotosArticulos;
  const AInfo: TFotoInfo;
  AResolucionPreferida: TFotoResolucion): string;
begin
  Result := AFotosArticulos.RutaFoto(
    AInfo, AResolucionPreferida);
  if (Result = '') and (AResolucionPreferida <> frReal) then
    Result := AFotosArticulos.RutaFoto(AInfo, frReal);
  if (Result = '') and (AResolucionPreferida <> frPx600) then
    Result := AFotosArticulos.RutaFoto(AInfo, frPx600);
  if (Result = '') and (AResolucionPreferida <> frPx300) then
    Result := AFotosArticulos.RutaFoto(AInfo, frPx300);
end;

constructor TSelectorFotoVariacion.Create(AOwner: TComponent;
  AFotosArticulos: TFotosArticulos;
  const AFotos: TArray<TFotoInfo>);
var
  iPpi        : Integer;
  iMargen     : Integer;
  iAltoBoton  : Integer;
  oPanelTop   : TPanel;
  oPanelBottom: TPanel;
  oCancelar   : TButton;
begin
  inherited CreateNew(AOwner);
  FFotosArticulos := AFotosArticulos;
  FFotos := AFotos;
  FIndice := 0;
  iPpi := Screen.PixelsPerInch;
  iMargen := MulDiv(6, iPpi, USER_DEFAULT_SCREEN_DPI);
  iAltoBoton := MulDiv(26, iPpi, USER_DEFAULT_SCREEN_DPI);

  Caption := STituloSeleccionarFotoVariacion;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  KeyPreview := True;
  ShowHint := True;
  DoubleBuffered := True;
  ClientWidth := MulDiv(480, iPpi, USER_DEFAULT_SCREEN_DPI);
  ClientHeight := MulDiv(390, iPpi, USER_DEFAULT_SCREEN_DPI);
  OnKeyDown := TeclaPulsada;
  if AOwner is TCustomForm then
  begin
    PopupMode := pmExplicit;
    PopupParent := TCustomForm(AOwner);
    Font.Assign(TCustomForm(AOwner).Font);
  end;

  oPanelTop := TPanel.Create(Self);
  oPanelTop.Parent := Self;
  oPanelTop.Align := alTop;
  oPanelTop.BevelOuter := bvNone;
  oPanelTop.Height := iAltoBoton + (2 * iMargen);

  FAnterior := TcxButton.Create(Self);
  FAnterior.Parent := oPanelTop;
  FAnterior.SetBounds(iMargen, iMargen,
    iAltoBoton, iAltoBoton);
  FAnterior.Hint := SHintFotoAnterior;
  FAnterior.OnClick := AnteriorClick;
  AsignarIconoFoto(FAnterior, ifAnterior);

  FSiguiente := TcxButton.Create(Self);
  FSiguiente.Parent := oPanelTop;
  FSiguiente.SetBounds(iMargen + iAltoBoton + iMargen,
    iMargen, iAltoBoton, iAltoBoton);
  FSiguiente.Hint := SHintFotoSiguiente;
  FSiguiente.OnClick := SiguienteClick;
  AsignarIconoFoto(FSiguiente, ifSiguiente);

  FContador := TLabel.Create(Self);
  FContador.Parent := oPanelTop;
  FContador.AutoSize := False;
  FContador.Alignment := taCenter;
  FContador.Layout := tlCenter;
  FContador.Left := FSiguiente.Left + FSiguiente.Width + iMargen;
  FContador.Top := iMargen;
  FContador.Width := oPanelTop.ClientWidth -
    FContador.Left - iMargen;
  FContador.Height := iAltoBoton;
  FContador.Anchors := [akLeft, akTop, akRight];

  oPanelBottom := TPanel.Create(Self);
  oPanelBottom.Parent := Self;
  oPanelBottom.Align := alBottom;
  oPanelBottom.BevelOuter := bvNone;
  oPanelBottom.Height := MulDiv(
    42, iPpi, USER_DEFAULT_SCREEN_DPI);

  oCancelar := TButton.Create(Self);
  oCancelar.Parent := oPanelBottom;
  oCancelar.Caption := SCaptionCancelar;
  oCancelar.Cancel := True;
  oCancelar.ModalResult := mrCancel;
  oCancelar.Width := MulDiv(
    90, iPpi, USER_DEFAULT_SCREEN_DPI);
  oCancelar.Height := iAltoBoton;
  oCancelar.Left := oPanelBottom.ClientWidth -
    oCancelar.Width - iMargen;
  oCancelar.Top := iMargen;
  oCancelar.Anchors := [akTop, akRight];

  FUsar := TButton.Create(Self);
  FUsar.Parent := oPanelBottom;
  FUsar.Caption := SCaptionUsarFotoVariacion;
  FUsar.Default := True;
  FUsar.ModalResult := mrOk;
  FUsar.Width := MulDiv(
    132, iPpi, USER_DEFAULT_SCREEN_DPI);
  FUsar.Height := iAltoBoton;
  FUsar.Left := oCancelar.Left - FUsar.Width - iMargen;
  FUsar.Top := iMargen;
  FUsar.Anchors := [akTop, akRight];

  FImagen := TImage.Create(Self);
  FImagen.Parent := Self;
  FImagen.Align := alClient;
  FImagen.AlignWithMargins := True;
  FImagen.Margins.Left := iMargen;
  FImagen.Margins.Top := iMargen;
  FImagen.Margins.Right := iMargen;
  FImagen.Margins.Bottom := iMargen;
  FImagen.Stretch := True;
  FImagen.Proportional := True;
  FImagen.Center := True;
  FImagen.OnDblClick := FotoDobleClick;
  ActualizarFoto;
end;

procedure TSelectorFotoVariacion.ActualizarFoto;
var
  sRuta: string;
begin
  FImagen.Picture.Assign(nil);
  FUsar.Enabled := (FIndice >= 0) and
    (FIndice < Length(FFotos));
  if FUsar.Enabled then
  begin
    sRuta := RutaFotoDisponible(
      FFotosArticulos, FFotos[FIndice], frPx600);
    try
      FImagen.Picture.LoadFromFile(sRuta);
    except
      FImagen.Picture.Assign(nil);
      FUsar.Enabled := False;
    end;
    FContador.Caption := Format(
      SCaptionFotoVariacion,
      [FFotos[FIndice].ClaveResuelta,
       FFotos[FIndice].Orden,
       FIndice + 1,
       Length(FFotos)]);
  end;
  FAnterior.Enabled := Length(FFotos) > 1;
  FSiguiente.Enabled := FAnterior.Enabled;
end;

procedure TSelectorFotoVariacion.AnteriorClick(Sender: TObject);
begin
  if Length(FFotos) > 1 then
  begin
    if FIndice > 0 then
      Dec(FIndice)
    else
      FIndice := High(FFotos);
    ActualizarFoto;
  end;
end;

procedure TSelectorFotoVariacion.SiguienteClick(Sender: TObject);
begin
  if Length(FFotos) > 1 then
  begin
    if FIndice < High(FFotos) then
      Inc(FIndice)
    else
      FIndice := 0;
    ActualizarFoto;
  end;
end;

procedure TSelectorFotoVariacion.FotoDobleClick(Sender: TObject);
begin
  if FUsar.Enabled then
    ModalResult := mrOk;
end;

procedure TSelectorFotoVariacion.TeclaPulsada(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_LEFT then
  begin
    AnteriorClick(Self);
    Key := 0;
  end
  else if Key = VK_RIGHT then
  begin
    SiguienteClick(Self);
    Key := 0;
  end;
end;

function TSelectorFotoVariacion.Ejecutar(
  out AFoto: TFotoInfo): Boolean;
begin
  AFoto.Clear;
  Result := (Length(FFotos) > 0) and
    (ShowModal = mrOk) and FUsar.Enabled;
  if Result then
    AFoto := FFotos[FIndice];
end;

function FotoFlotanteActual: TfrmFotoArticulo;
var
  Componente: TComponent;
begin
  Componente := Application.FindComponent('frmFotoArticulo');
  if (Componente is TfrmFotoArticulo) and
     not (csDestroying in Componente.ComponentState) then
    Result := TfrmFotoArticulo(Componente)
  else
    Result := nil;
end;

procedure TfrmFotoArticulo.FormCreate(Sender: TObject);
var
  loaderRes: TLayoutLoader;
begin
  inherited;
  // poDesigned (no poScreenCenter) para que Left/Top guardados con
  // Alt+F12 no sean sobrescritos al mostrarse el form. Si no hay
  // layout guardado, FormShow centra manualmente.
  Self.Position    := poDesigned;
  Self.BorderStyle := bsSizeable;
  Self.BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  // KeyPreview procesa teclas cuando la flotante esta activa (tras
  // click directo del usuario). El auto-show usa SW_SHOWNOACTIVATE
  // para no robar el foco al Mto, pero una vez el usuario clicka un
  // boton o el combo, la ventana se activa normalmente y necesita
  // procesar F11 / Alt+F12.
  Self.KeyPreview  := True;
  // Restaura la resolución elegida guardada con el layout (default 'real').
  loaderRes := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  try
    if loaderRes.Disponible then
    begin
      rgResolucion.ItemIndex :=
        StrToIntDef(loaderRes.RestaurarValor('Resolucion', '2'), 2);
      spnTransparencia.Value := EnsureRange(StrToIntDef(
        loaderRes.RestaurarValor('Transparencia', '0'), 0), 0, 90);
    end
    else
      rgResolucion.ItemIndex := 2;
  finally
    loaderRes.Free;
  end;
  spnTransparenciaPropertiesEditValueChanged(spnTransparencia);
  FUltimaInfo.Clear;
  FHooksDataSource := TObjectList<TEnlaceFotoFlotante>.Create(True);
  FPadreResolver   := nil;
  FPadreResolverSesion := nil;
  FAlCambiarFotoSesion := nil;
  FGpImagen        := nil;
  FModoSesion      := False;
  FLineaSesion     := 0;
  FFotosColeccion  := nil;
  FIndiceFoto      := -1;
  // El bitmap GDI+ ya viene al tamaño del control; que TImage NO lo reescale
  // (si no, al cambiar el area -p.ej. colapsar el panel de controles- la foto
  // sale pequeña hasta el siguiente repintado).
  imgFoto.Stretch      := False;
  imgFoto.Proportional := False;
  imgFoto.Center       := False;
  rgResolucion.Style.Font.Size := 9;
  lblNumeroFoto.Style.Font.Size := 9;
  lblOrigen.Style.Font.Size := 9;
  lblNivel.Style.Font.Size := 9;
  cbbNivelSku.Style.Font.Size := 9;
  // Por defecto el panel de controles esta encogido.
  pnlControles.Visible := False;
  FInicializacionCompleta := True;
  AplicarAspectoBotonesCompactos;
  AjustarBarraSuperior;
  AjustarPanelControles;
end;

procedure TfrmFotoArticulo.FormShow(Sender: TObject);
begin
  inherited;
  RestaurarGeometriaGuardada;
  AjustarBarraSuperior;
  AjustarPanelControles;
  // En el PRIMER show, imgFoto aun no tiene su tamano final cuando se pinto la
  // foto (sale en blanco). Diferimos un repintado a cuando el layout cuaje.
  TThread.ForceQueue(nil,
    procedure
    var
      Formulario: TfrmFotoArticulo;
    begin
      Formulario := FotoFlotanteActual;
      if (Formulario <> nil) and
         Formulario.Visible then
        Formulario.PintarFotoGDIPlus;
    end);
end;

procedure TfrmFotoArticulo.AplicarTraduccionActual;
begin
  inherited;
  AplicarAspectoBotonesCompactos;
  ActualizarCaptionActual;
end;

procedure TfrmFotoArticulo.AplicarAspectoBotonesCompactos;
begin
  AsignarIconoFoto(btnDescargarNube, ifDescargar);
  AsignarIconoFoto(btnFotoAnterior, ifAnterior);
  AsignarIconoFoto(btnFotoSiguiente, ifSiguiente);
  AsignarIconoFoto(btnAnadirFoto, ifAnadir);
  AsignarIconoFoto(btnCambiarSku, ifSustituirNivel);
  AsignarIconoFoto(btnRotarIzq, ifRotarIzquierda);
  AsignarIconoFoto(btnRotarDer, ifRotarDerecha);
  AsignarIconoFoto(btnQuitar, ifEliminar);
  AsignarIconoFoto(btnLayout, ifGuardarLayout);
  if FModoSesion and not FFotoDefinitivaSesion then
    AsignarIconoFoto(btnCambiarArt, ifSustituirLinea)
  else
    AsignarIconoFoto(btnCambiarArt, ifSustituirPredeterminada);

  btnToggle.Hint := SHintMostrarControlesFoto;
  btnDescargarNube.Hint := SHintBajarFotosServidor;
  btnMarcarPredeterminada.Hint := SHintFotoPredeterminada;
  btnFotoAnterior.Hint := SHintFotoAnterior;
  btnFotoSiguiente.Hint := SHintFotoSiguiente;
  btnAnadirFoto.Hint := SHintAnadirFoto;
  rgResolucion.Caption := '';
  rgResolucion.Hint := SHintResolucionFoto;
  lblTransparencia.Caption := SCaptionTransparenciaFoto;
  spnTransparencia.Hint := SHintTransparenciaFoto;
  rgResolucion.ParentShowHint := False;
  rgResolucion.ShowHint := True;
  if FModoSesion and not FFotoDefinitivaSesion then
    btnCambiarArt.Hint := SHintCambiarFotoLinea
  else
    btnCambiarArt.Hint := SHintCambiarFotoArticulo;
  btnCambiarSku.Hint := SHintCambiarFotoNivel;
  btnRotarIzq.Hint := SHintRotarFotoIzquierda;
  btnRotarDer.Hint := SHintRotarFotoDerecha;
  btnQuitar.Hint := SHintQuitarFoto;
  btnLayout.Hint := SHintGuardarLayoutFoto;

  AjustarBotonToggle;
  if FUltimaInfo.Encontrada and (FUltimaInfo.Orden = 1) then
    AsignarIconoFoto(btnMarcarPredeterminada, ifEstrellaLlena)
  else
    AsignarIconoFoto(btnMarcarPredeterminada, ifEstrellaVacia);
end;

procedure TfrmFotoArticulo.AjustarBarraSuperior;
var
  iAltoBoton        : Integer;
  iAnchoBoton       : Integer;
  iAnchoContador    : Integer;
  iAnchoNecesario   : Integer;
  iIzquierda        : Integer;
  iIzquierdaGaleria : Integer;
  iMargen           : Integer;
  iSeparacion       : Integer;
begin
  iMargen := MulDiv(2, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSeparacion := iMargen;
  iAnchoBoton := MulDiv(22, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iAltoBoton := iAnchoBoton;
  iAnchoContador := MulDiv(24, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iAnchoNecesario := (6 * iAnchoBoton) + iAnchoContador +
    (6 * iSeparacion) + (2 * iMargen);
  if iAnchoNecesario > pnlTop.ClientWidth then
  begin
    iAnchoContador := MulDiv(22, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    iAnchoBoton := (pnlTop.ClientWidth - iAnchoContador -
      (6 * iSeparacion) - (2 * iMargen)) div 6;
    if iAnchoBoton < MulDiv(14, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI) then
      iAnchoBoton := MulDiv(14, CurrentPPI,
        USER_DEFAULT_SCREEN_DPI);
    if iAltoBoton > iAnchoBoton then
      iAltoBoton := iAnchoBoton;
  end;
  pnlTop.Height := iAltoBoton + (2 * iMargen);

  iIzquierda := iMargen;
  btnToggle.SetBounds(iIzquierda, iMargen,
    iAnchoBoton, iAltoBoton);
  Inc(iIzquierda, iAnchoBoton + iSeparacion);
  btnDescargarNube.SetBounds(iIzquierda, iMargen,
    iAnchoBoton, iAltoBoton);

  iIzquierdaGaleria := pnlTop.ClientWidth - iMargen -
    (4 * iAnchoBoton) - iAnchoContador -
    (4 * iSeparacion);
  btnMarcarPredeterminada.SetBounds(
    iIzquierdaGaleria, iMargen, iAnchoBoton, iAltoBoton);
  Inc(iIzquierdaGaleria, iAnchoBoton + iSeparacion);
  btnFotoAnterior.SetBounds(
    iIzquierdaGaleria, iMargen, iAnchoBoton, iAltoBoton);
  Inc(iIzquierdaGaleria, iAnchoBoton + iSeparacion);
  lblNumeroFoto.Left := iIzquierdaGaleria;
  lblNumeroFoto.Width := iAnchoContador;
  lblNumeroFoto.Top := (pnlTop.ClientHeight -
    lblNumeroFoto.Height) div 2;
  Inc(iIzquierdaGaleria, iAnchoContador + iSeparacion);
  btnFotoSiguiente.SetBounds(
    iIzquierdaGaleria, iMargen, iAnchoBoton, iAltoBoton);
  Inc(iIzquierdaGaleria, iAnchoBoton + iSeparacion);
  btnAnadirFoto.SetBounds(
    iIzquierdaGaleria, iMargen, iAnchoBoton, iAltoBoton);

  lblOrigen.Left := btnDescargarNube.Left +
    btnDescargarNube.Width + iSeparacion;
  lblOrigen.Top := (pnlTop.ClientHeight - lblOrigen.Height) div 2;
  iAnchoNecesario := btnMarcarPredeterminada.Left -
    lblOrigen.Left - iSeparacion;
  if iAnchoNecesario > 0 then
    lblOrigen.Width := iAnchoNecesario
  else
    lblOrigen.Width := 0;
end;

procedure TfrmFotoArticulo.AjustarPanelControles;
var
  aBotones        : array[0..5] of TcxButton;
  bNivelApilado   : Boolean;
  iAltoBoton      : Integer;
  iAnchoBoton     : Integer;
  iAnchoDisponible: Integer;
  iBoton          : Integer;
  iIzquierda      : Integer;
  iMargen         : Integer;
  iSeparacion     : Integer;
  iTopBotones     : Integer;
begin
  iMargen := MulDiv(2, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSeparacion := iMargen;
  iAnchoBoton := MulDiv(26, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iAltoBoton := MulDiv(24, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iAnchoDisponible := pnlControles.ClientWidth -
    (2 * iMargen) - (5 * iSeparacion);
  if (6 * iAnchoBoton) > iAnchoDisponible then
    iAnchoBoton := iAnchoDisponible div 6;
  if iAnchoBoton < MulDiv(18, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI) then
    iAnchoBoton := MulDiv(18, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);

  rgResolucion.Left := iMargen;
  rgResolucion.Top := iMargen div 2;
  rgResolucion.Height := MulDiv(24, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  bNivelApilado := cbbNivelSku.Visible and
    (pnlControles.ClientWidth < MulDiv(360, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI));
  if bNivelApilado then
  begin
    rgResolucion.Width := pnlControles.ClientWidth -
      (2 * iMargen);
    lblNivel.Left := iMargen;
    lblNivel.Top := MulDiv(28, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    cbbNivelSku.Left := MulDiv(48, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    cbbNivelSku.Top := MulDiv(26, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    cbbNivelSku.Width := pnlControles.ClientWidth -
      cbbNivelSku.Left - iMargen;
    if cbbNivelSku.Width < 0 then
      cbbNivelSku.Width := 0;
    iTopBotones := MulDiv(52, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    pnlControles.Height := MulDiv(78, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  end
  else
  begin
    rgResolucion.Width := MulDiv(194, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    if rgResolucion.Width > pnlControles.ClientWidth -
       (2 * iMargen) then
      rgResolucion.Width := pnlControles.ClientWidth -
        (2 * iMargen);
    lblNivel.Left := rgResolucion.Left + rgResolucion.Width +
      MulDiv(6, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
    lblNivel.Top := iMargen;
    cbbNivelSku.Left := lblNivel.Left +
      lblNivel.Width + iMargen;
    cbbNivelSku.Top := iMargen;
    cbbNivelSku.Width := pnlControles.ClientWidth -
      cbbNivelSku.Left - iMargen;
    if cbbNivelSku.Width < 0 then
      cbbNivelSku.Width := 0;
    iTopBotones := MulDiv(28, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    pnlControles.Height := MulDiv(54, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  end;

  aBotones[0] := btnCambiarArt;
  aBotones[1] := btnCambiarSku;
  aBotones[2] := btnRotarIzq;
  aBotones[3] := btnRotarDer;
  aBotones[4] := btnQuitar;
  aBotones[5] := btnLayout;
  iIzquierda := iMargen;
  for iBoton := 0 to High(aBotones) do
  begin
    aBotones[iBoton].SetBounds(
      iIzquierda, iTopBotones, iAnchoBoton, iAltoBoton);
    Inc(iIzquierda, iAnchoBoton + iSeparacion);
  end;
end;

procedure TfrmFotoArticulo.RestaurarGeometriaGuardada;
begin
  // Restaura geometria (Left/Top/Width/Height/WindowState) si el usuario la
  // guardo con Alt+F12. Se llama desde FormShow y desde MostrarFotoFlotante
  // (antes de mostrar) para que el tamaño se aplique de forma fiable aunque
  // la ventana se muestre con SW_SHOWNOACTIVATE. Si no hay layout, centra.
  if not Assigned(FLayoutLoader) then
    FLayoutLoader := TLayoutLoader.Create(
      Self.Name, ContextoSesion, PerfilesLectura);
  if FLayoutLoader.Disponible then
    FLayoutLoader.RestaurarGeometria(Self)
  else
  begin
    Self.Left := (Screen.Width  - Self.Width)  div 2;
    Self.Top  := (Screen.Height - Self.Height) div 2;
  end;
end;

procedure TfrmFotoArticulo.FormDestroy(Sender: TObject);
begin
  DesengancharDataChange;
  FreeAndNil(FGpImagen);
  FreeAndNil(FHooksDataSource);
  if Assigned(FLayoutLoader) then
    FreeAndNil(FLayoutLoader);
  // Vaciamos explicitamente los strings que vivian en la instancia.
  // En un mundo perfecto, el destructor del form ya los suelta cuando
  // libera sus propios campos; pero algunos detectores de leak (FastMM)
  // ven los strings interceptados antes de que la VCL libere el
  // componente padre y los reportan como huerfanos. Limpiarlos aqui
  // es belt-and-braces.
  if Assigned(cbbNivelSku) then
    cbbNivelSku.Properties.Items.Clear;
  if Assigned(lblOrigen) then lblOrigen.Caption := '';
  Self.Caption := '';
  FCodigoArt   := '';
  FCodigoSku   := '';
  FFotosColeccion := nil;
  FIndiceFoto := -1;
  FUltimaInfo.Clear;
  inherited;
end;

procedure TfrmFotoArticulo.FormClose(Sender: TObject;
                                     var Action: TCloseAction);
begin
  inherited;
  DesengancharDataChange;
  Action := caFree;
end;

procedure TfrmFotoArticulo.FormKeyDown(Sender: TObject; var Key: Word;
                                       Shift: TShiftState);
begin
  inherited;
  // Alt+F12 -> guardar geometria
  if (Key = VK_F12) and (ssAlt in Shift) and not (ssCtrl in Shift) then
  begin
    GuardarLayout;
    Key := 0;
  end
  // Ctrl+F12 -> resetear layout
  else if (Key = VK_F12) and (ssCtrl in Shift) and
     not (ssAlt in Shift) then
  begin
    ResetearLayout(
      Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
    Key := 0;
  end
  // F11 -> mostrar / ocultar panel de controles (alternativa al boton).
  else if Key = VK_F11 then
  begin
    ToggleControles;
    Key := 0;
  end;
end;

procedure TfrmFotoArticulo.GuardarLayout;
var
  saver: TLayoutSaver;
begin
  saver := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    saver.GuardarGeometria(Self);
    saver.GuardarValor('Resolucion', IntToStr(rgResolucion.ItemIndex));
    saver.GuardarValor('Transparencia',
      IntToStr(Round(spnTransparencia.Value)));
    saver.PreguntarYGrabar(STituloLayoutFotoArticulo);
  finally
    FreeAndNil(saver);
  end;
end;

procedure TfrmFotoArticulo.spnTransparenciaPropertiesEditValueChanged(
  Sender: TObject);
var
  iTransparencia: Integer;
begin
  if VarIsNumeric(spnTransparencia.EditValue) then
  begin
    iTransparencia := EnsureRange(Round(spnTransparencia.Value), 0, 90);
    AlphaBlendValue := MulDiv(100 - iTransparencia, 255, 100);
    AlphaBlend := iTransparencia > 0;
  end;
end;

// ---------------------------------------------------------------------
//   Panel de controles: estirar / encoger
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.ToggleControles;
begin
  pnlControles.Visible := not pnlControles.Visible;
  AjustarPanelControles;
  AjustarBotonToggle;
  // Reencajar la foto: al cambiar la visibilidad del panel, imgFoto cambia de
  // tamaño pero el Resize del form no salta (la ventana no cambia de tamaño).
  PintarFotoGDIPlus;
end;

procedure TfrmFotoArticulo.AjustarBotonToggle;
begin
  if pnlControles.Visible then
    AsignarIconoFoto(btnToggle, ifChevronArriba)
  else
    AsignarIconoFoto(btnToggle, ifChevronAbajo);
end;

procedure TfrmFotoArticulo.btnToggleClick(Sender: TObject);
begin
  inherited;
  ToggleControles;
end;

procedure TfrmFotoArticulo.btnDescargarNubeClick(Sender: TObject);
begin
  inherited;
  DescargarFotosDeNube;
end;

function TfrmFotoArticulo.FotoNubeYaIntegrada(const AArchivo,
  AClave: string): Boolean;
var
  rFoto: TFotoInfo;
  sRuta, sHash: string;
begin
  Result := False;
  sHash := THashSHA2.GetHashStringFromFile(AArchivo);
  for rFoto in FotosArticulos.ResolverColeccion(FCodigoArt, AClave) do
  begin
    sRuta := FotosArticulos.RutaFoto(rFoto, frReal);
    if (rFoto.ClaveResuelta = AClave) and FileExists(sRuta) then
      Result := Result or (sHash = THashSHA2.GetHashStringFromFile(sRuta));
  end;
end;

procedure TfrmFotoArticulo.IntegrarFotosNube(
  const AArchivos: TArray<string>);
var
  sClave, sColor, sArchivo: string;
  iBarra: Integer;
begin
  sClave := ClaveNivelSeleccionado;
  iBarra := LastDelimiter('/', sClave);
  sColor := '';
  if iBarra > 0 then
    sColor := Copy(sClave, iBarra + 1, MaxInt);
  for sArchivo in FiltrarFotosNube(AArchivos, FCodigoArt, sColor) do
    if not FotoNubeYaIntegrada(sArchivo, sClave) then
      FotosArticulos.Anadir(FCodigoArt, sClave, sArchivo,
        IdentidadSesion.Usuario);
end;

procedure TfrmFotoArticulo.DescargarFotosDeNube;
var
  archivos                   : TArray<string>;
  sMsg: string;
  bOK                        : Boolean;
begin
  // Añade todas las fotos del nivel seleccionado, sin sustituir la
  // principal ni duplicar imágenes que ya se descargaron.
  if FCodigoArt = '' then
    ShowMessage_fza(SErrorFotoArticuloNoActivoDescargar)
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      bOK := DescargarFotosArticulo(
        ParametrosApp,
        FCodigoArt,
        archivos,
        sMsg);
    finally
      Screen.Cursor := crDefault;
    end;
    if not bOK then
      ShowMessage_fza(Format(SErrorDescargarFotosArticulo,
                         [FCodigoArt, sMsg]))
    else
    begin
      try
        IntegrarFotosNube(archivos);
        SetArticuloSku(FCodigoArt, FCodigoSku);
      finally
        LimpiarDescargaTemporal(archivos);
      end;
      ShowMessage_fza(Format(SInfoFotosArticuloDescargadas,
                         [Length(archivos), FCodigoArt]));
    end;
  end;
end;

// ---------------------------------------------------------------------
//   Resolucion / carga / etiqueta
// ---------------------------------------------------------------------

function TfrmFotoArticulo.ResolucionElegida: TFotoResolucion;
begin
  case rgResolucion.ItemIndex of
    0: Result := frPx300;
    1: Result := frPx600;
    2: Result := frReal;
  else
    Result := frPx300;
  end;
end;

procedure TfrmFotoArticulo.SetArticuloSku(const ACodArt, ACodSku: string);
var
  bMismoContexto  : Boolean;
  sNombrePreferido: string;
begin
  // Una recarga del mismo artículo/SKU (por ejemplo, tras bajar fotos de
  // nube) no debe devolver al usuario a la primera foto. Al cambiar de
  // contexto, en cambio, la colección siempre empieza por la primera.
  bMismoContexto := (not FModoSesion) and
    SameText(FCodigoArt, ACodArt) and SameText(FCodigoSku, ACodSku);
  sNombrePreferido := '';
  if bMismoContexto and FUltimaInfo.Encontrada then
    sNombrePreferido := FUltimaInfo.NombreBase;
  FModoSesion := False;
  FFotoDefinitivaSesion := False;
  FPadreResolverSesion := nil;
  FAlCambiarFotoSesion := nil;
  FSerieSesion := '';
  FNumeroSesion := '';
  FLineaSesion := 0;
  FCodigoArtTentativoSesion := '';
  FCodigoUnidadSesion := '';
  FCodigoArt := ACodArt;
  FCodigoSku := ACodSku;
  PrepararControlesArticulo;
  RellenarNivelesSku;
  if bMismoContexto then
    CargarColeccionArticulo(sNombrePreferido, 0, 0)
  else
    CargarColeccionArticulo('', 0, 0);
end;

procedure TfrmFotoArticulo.CargarColeccionArticulo(
  const ANombrePreferido: string;
  AOrdenPreferido, AIndiceAlternativo: Integer);
var
  i      : Integer;
  iIndice: Integer;
begin
  FFotosColeccion := FotosArticulos.ResolverColeccion(
    FCodigoArt, FCodigoSku);
  iIndice := -1;

  // NombreBase identifica de forma inequívoca la foto que ya se estaba
  // mostrando. Orden sirve de respaldo tras rotarla, porque esa operación
  // cambia el nombre físico pero mantiene su posición en la colección.
  if ANombrePreferido <> '' then
    for i := 0 to High(FFotosColeccion) do
      if SameText(FFotosColeccion[i].NombreBase, ANombrePreferido) then
      begin
        iIndice := i;
        Break;
      end;
  if (iIndice < 0) and (AOrdenPreferido > 0) then
    for i := 0 to High(FFotosColeccion) do
      if FFotosColeccion[i].Orden = AOrdenPreferido then
      begin
        iIndice := i;
        Break;
      end;

  if Length(FFotosColeccion) = 0 then
    iIndice := -1
  else if iIndice < 0 then
  begin
    if AIndiceAlternativo < 0 then
      iIndice := 0
    else if AIndiceAlternativo > High(FFotosColeccion) then
      iIndice := High(FFotosColeccion)
    else
      iIndice := AIndiceAlternativo;
  end;
  SeleccionarFoto(iIndice);
end;

procedure TfrmFotoArticulo.SeleccionarFoto(AIndice: Integer);
begin
  if Length(FFotosColeccion) = 0 then
    FIndiceFoto := -1
  else if AIndice < 0 then
    FIndiceFoto := 0
  else if AIndice > High(FFotosColeccion) then
    FIndiceFoto := High(FFotosColeccion)
  else
    FIndiceFoto := AIndice;

  FUltimaInfo.Clear;
  if FIndiceFoto >= 0 then
    FUltimaInfo := FFotosColeccion[FIndiceFoto];
  ActualizarOrigenFotoArticulo;
  ActualizarControlesGaleria;
  CargarFotoActual;
end;

procedure TfrmFotoArticulo.ActualizarControlesGaleria;
var
  bCatalogo: Boolean;
begin
  bCatalogo := not FModoSesion;
  btnFotoAnterior.Visible := bCatalogo;
  lblNumeroFoto.Visible := bCatalogo;
  btnFotoSiguiente.Visible := bCatalogo;
  btnAnadirFoto.Visible := bCatalogo;
  btnMarcarPredeterminada.Visible := bCatalogo;

  btnFotoAnterior.Enabled := bCatalogo and (FIndiceFoto > 0);
  btnFotoSiguiente.Enabled := bCatalogo and (FIndiceFoto >= 0) and
    (FIndiceFoto < High(FFotosColeccion));
  btnAnadirFoto.Enabled := bCatalogo and (FCodigoArt <> '');
  btnMarcarPredeterminada.Enabled :=
    bCatalogo and FUltimaInfo.Encontrada and
    (FUltimaInfo.Orden > 1);
  if FUltimaInfo.Encontrada and (FUltimaInfo.Orden = 1) then
    AsignarIconoFoto(btnMarcarPredeterminada, ifEstrellaLlena)
  else
    AsignarIconoFoto(btnMarcarPredeterminada, ifEstrellaVacia);
  if FIndiceFoto >= 0 then
    lblNumeroFoto.Caption := Format('%d/%d',
      [FIndiceFoto + 1, Length(FFotosColeccion)])
  else
    lblNumeroFoto.Caption := '0/0';
  if bCatalogo then
    ActualizarCaptionArticulo;
end;

procedure TfrmFotoArticulo.ActualizarOrigenFotoArticulo;
begin
  case FUltimaInfo.Origen of
    foSku        : lblOrigen.Caption :=
      Format(SCaptionFotoDelSku, [FCodigoSku]);
    foSkuPrefijo : lblOrigen.Caption :=
      Format(SCaptionFotoHeredadaGrupo, [FUltimaInfo.ClaveResuelta]);
    foArticulo   : lblOrigen.Caption :=
      Format(SCaptionFotoHeredadaArticulo, [FCodigoArt]);
    foSinFoto    : lblOrigen.Caption :=
      Format(SCaptionSinFotoPara,
        [FCodigoArt, IfThen(FCodigoSku <> '', ' / ' + FCodigoSku, '')]);
  end;
end;

procedure TfrmFotoArticulo.ActualizarCaptionArticulo;
var
  sCodigo: string;
begin
  if FCodigoSku <> '' then
    sCodigo := FCodigoSku
  else
    sCodigo := FCodigoArt;
  if FIndiceFoto >= 0 then
    Self.Caption := Format(SCaptionGaleriaConFotos,
      [sCodigo, FIndiceFoto + 1, Length(FFotosColeccion)])
  else
    Self.Caption := Format(SCaptionGaleriaSinFotos, [sCodigo]);
end;

procedure TfrmFotoArticulo.ActualizarCaptionActual;
begin
  if FModoSesion then
    Self.Caption := Format(
      SCaptionFotoSesion,
      [FSerieSesion, FNumeroSesion, FLineaSesion,
       FCodigoArtTentativoSesion])
  else if (FCodigoArt <> '') or (FCodigoSku <> '') then
    ActualizarCaptionArticulo;
end;

procedure TfrmFotoArticulo.PrepararControlesArticulo;
begin
  btnDescargarNube.Visible := True;
  btnCambiarSku.Visible := True;
  btnMarcarPredeterminada.Visible := True;
  btnFotoAnterior.Visible := True;
  lblNumeroFoto.Visible := True;
  btnFotoSiguiente.Visible := True;
  btnAnadirFoto.Visible := True;
  AplicarAspectoBotonesCompactos;
end;

procedure TfrmFotoArticulo.PrepararControlesSesion(AExpandir: Boolean);
begin
  btnDescargarNube.Visible := False;
  btnFotoAnterior.Visible := False;
  lblNumeroFoto.Visible := False;
  btnFotoSiguiente.Visible := False;
  btnAnadirFoto.Visible := False;
  btnMarcarPredeterminada.Visible := False;
  btnCambiarSku.Visible := False;
  lblNivel.Visible := False;
  cbbNivelSku.Visible := False;
  if AExpandir and not pnlControles.Visible then
  begin
    pnlControles.Visible := True;
    AjustarBotonToggle;
  end;
  AplicarAspectoBotonesCompactos;
end;

procedure TfrmFotoArticulo.SetSesion(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodArtTentativo, ACodUnidad: string);
var
  bEntrandoModoSesion: Boolean;
begin
  bEntrandoModoSesion := not FModoSesion;
  FModoSesion := True;
  FPadreResolver := nil;
  FSerieSesion := ASerieSesion;
  FNumeroSesion := ANumeroSesion;
  FLineaSesion := ALinea;
  FCodigoArtTentativoSesion := ACodArtTentativo;
  FCodigoUnidadSesion := ACodUnidad;
  FCodigoArt := ACodArtTentativo;
  FCodigoSku := ACodUnidad;
  FFotosColeccion := nil;
  FIndiceFoto := -1;
  FUltimaInfo.Clear;
  if ACodArtTentativo <> '' then
    FUltimaInfo := FotosArticulos.Resolver(
      ACodArtTentativo, ACodUnidad);
  FFotoDefinitivaSesion := FUltimaInfo.Encontrada;
  if not FFotoDefinitivaSesion then
    FUltimaInfo := FotosArticulos.Sesion.Resolver(
      ASerieSesion, ANumeroSesion, ALinea, ACodUnidad);
  // Solo se despliegan al entrar inicialmente en el modo sesión. Las
  // resincronizaciones posteriores deben respetar la elección del usuario.
  PrepararControlesSesion(bEntrandoModoSesion);
  if FFotoDefinitivaSesion then
    lblOrigen.Caption := Format(
      SCaptionFotoHeredadaArticulo, [ACodArtTentativo])
  else if FUltimaInfo.Encontrada then
    lblOrigen.Caption := Format(
      SCaptionLineaFotoDetalle,
      [ALinea, ACodArtTentativo, SCaptionDestinoArticulo])
  else
    lblOrigen.Caption := Format(
      SCaptionLineaSinFotoProvisional, [ALinea]);
  ActualizarCaptionActual;
  CargarFotoActual;
end;

function TfrmFotoArticulo.CoincideSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer; const ACodUnidad: string): Boolean;
begin
  Result := FModoSesion and
    SameText(FSerieSesion, ASerieSesion) and
    SameText(FNumeroSesion, ANumeroSesion) and
    (FLineaSesion = ALinea) and
    SameText(FCodigoUnidadSesion, ACodUnidad);
end;

procedure TfrmFotoArticulo.RellenarNivelesSku;
// El combo se llena de mas especifico (SKU completo) a menos
// (1 atributo). El indice por defecto lo dicta `appNumAtributosFoto`:
// si vale N, se selecciona el nivel cuya clave incluye N segmentos
// despues del articulo; si N >= total de atributos del SKU, gana el
// SKU completo.
var
  prefijos      : TArray<string>;
  i             : Integer;
  iNumAtribsCfg : Integer;
  iSegmentos    : Integer;
  iIdxDefault   : Integer;
begin
  cbbNivelSku.Properties.Items.BeginUpdate;
  try
    cbbNivelSku.Properties.Items.Clear;
    if FCodigoSku = '' then
    begin
      lblNivel.Visible    := False;
      cbbNivelSku.Visible := False;
    end
    else
    begin
      lblNivel.Visible := True;
      cbbNivelSku.Visible := True;
      prefijos := GenerarPrefijosSku(FCodigoSku);
      for i := 0 to High(prefijos) do
        cbbNivelSku.Properties.Items.Add(prefijos[i]);
      if cbbNivelSku.Properties.Items.Count > 0 then
      begin
        iNumAtribsCfg := ParametrosApp.GetInt('appNumAtributosFoto', 1);
        iIdxDefault := 0;
        for i := 0 to cbbNivelSku.Properties.Items.Count - 1 do
        begin
          iSegmentos := 0;
          var sCl: string := cbbNivelSku.Properties.Items[i];
          for var c: Char in sCl do
            if c = '/' then
              Inc(iSegmentos);
          if iSegmentos = iNumAtribsCfg then
          begin
            iIdxDefault := i;
            Break;
          end;
        end;
        cbbNivelSku.ItemIndex := iIdxDefault;
      end;
    end;
  finally
    cbbNivelSku.Properties.Items.EndUpdate;
  end;
  AjustarPanelControles;
end;

function TfrmFotoArticulo.ClaveNivelSeleccionado: string;
begin
  // Aunque el panel de controles este colapsado, el combo conserva
  // su ItemIndex; usamos siempre el valor del combo si tiene items.
  if (cbbNivelSku.Properties.Items.Count > 0) and
     (cbbNivelSku.ItemIndex >= 0) then
    Result := cbbNivelSku.Properties.Items[cbbNivelSku.ItemIndex]
  else
    Result := FCodigoSku;
end;

function TfrmFotoArticulo.SeleccionarRutaPredeterminada(
  out ARutaFoto: string): Boolean;
var
  aDisponibles: TArray<TFotoInfo>;
  aVariaciones: TArray<TFotoInfo>;
  iFoto       : Integer;
  oSeleccion  : TFotoInfo;
  oSelector   : TSelectorFotoVariacion;
begin
  ARutaFoto := '';
  SetLength(aDisponibles, 0);
  aVariaciones := FotosArticulos.ResolverFotosVariaciones(
    FCodigoArt);
  for iFoto := 0 to High(aVariaciones) do
    if RutaFotoDisponible(
      FotosArticulos, aVariaciones[iFoto], frReal) <> '' then
      aDisponibles := aDisponibles + [aVariaciones[iFoto]];

  if Length(aDisponibles) > 0 then
  begin
    oSelector := TSelectorFotoVariacion.Create(
      Self, FotosArticulos, aDisponibles);
    try
      if oSelector.Ejecutar(oSeleccion) then
        ARutaFoto := RutaFotoDisponible(
          FotosArticulos, oSeleccion, frReal);
    finally
      FreeAndNil(oSelector);
    end;
  end
  else if dlgAbrirFoto.Execute then
    ARutaFoto := dlgAbrirFoto.FileName;
  Result := ARutaFoto <> '';
end;

procedure TfrmFotoArticulo.AsegurarPredeterminadaArticulo(
  const ARutaFoto: string);
var
  oActual: TFotoInfo;
begin
  oActual := FotosArticulos.Resolver(FCodigoArt, '');
  if (ARutaFoto <> '') and
     ((not oActual.Encontrada) or
      (oActual.Origen <> foArticulo)) then
    FotosArticulos.Guardar(
      FCodigoArt, '', ARutaFoto, IdentidadSesion.Usuario);
end;

procedure TfrmFotoArticulo.CargarFotoActual;
begin
  FreeAndNil(FGpImagen);
  FRutaFotoActual := '';
  imgFoto.Picture.Assign(nil);
  if FUltimaInfo.Encontrada then
  begin
    FRutaFotoActual := FotosArticulos.RutaFoto(
      FUltimaInfo, ResolucionElegida);
    if FRutaFotoActual <> '' then
    begin
      FGpImagen := TGPImage.Create(FRutaFotoActual);
      if (FGpImagen = nil) or (FGpImagen.GetLastStatus <> Ok) then
        FreeAndNil(FGpImagen)
      else
        PintarFotoGDIPlus;
    end;
  end;
end;

procedure TfrmFotoArticulo.PintarFotoGDIPlus;
var
  bmp    : TBitmap;
  gpGfx  : TGPGraphics;
  cw, ch, iw, ih, dw, dh, dx, dy: Integer;
  rEscala: Double;
begin
  if FGpImagen <> nil then
  begin
    cw := imgFoto.Width;
    ch := imgFoto.Height;
    iw := Integer(FGpImagen.GetWidth);
    ih := Integer(FGpImagen.GetHeight);
    if (cw >= 1) and (ch >= 1) and (iw >= 1) and (ih >= 1) then
    begin
  // Encaje proporcional dentro del control, centrado (sin recortar).
  if (cw / iw) <= (ch / ih) then
    rEscala := cw / iw
  else
    rEscala := ch / ih;
  dw := Round(iw * rEscala);
  if dw < 1 then
    dw := 1;
  dh := Round(ih * rEscala);
  if dh < 1 then
    dh := 1;
  dx := (cw - dw) div 2;
  dy := (ch - dh) div 2;
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.SetSize(cw, ch);
    bmp.Canvas.Brush.Color := clBtnFace;
    bmp.Canvas.FillRect(Rect(0, 0, cw, ch));
    gpGfx := TGPGraphics.Create(bmp.Canvas.Handle);
    try
      gpGfx.SetInterpolationMode(InterpolationModeHighQualityBicubic);
      gpGfx.SetPixelOffsetMode(PixelOffsetModeHighQuality);
      gpGfx.SetSmoothingMode(SmoothingModeHighQuality);
      gpGfx.DrawImage(FGpImagen, dx, dy, dw, dh);
    finally
      gpGfx.Free;
    end;
    imgFoto.Picture.Assign(bmp);
  finally
    bmp.Free;
  end;
    end;
  end;
end;

procedure TfrmFotoArticulo.Resize;
begin
  inherited;
  if FInicializacionCompleta then
  begin
    AjustarBarraSuperior;
    AjustarPanelControles;
  end;
  PintarFotoGDIPlus;
end;

procedure TfrmFotoArticulo.rgResolucionPropertiesEditValueChanged(
                                                          Sender: TObject);
begin
  inherited;
  CargarFotoActual;
end;

// ---------------------------------------------------------------------
//   Botones: cambiar / quitar / rotar
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.btnFotoAnteriorClick(Sender: TObject);
begin
  inherited;
  if (not FModoSesion) and (FIndiceFoto > 0) then
    SeleccionarFoto(FIndiceFoto - 1);
end;

procedure TfrmFotoArticulo.btnFotoSiguienteClick(Sender: TObject);
begin
  inherited;
  if (not FModoSesion) and (FIndiceFoto >= 0) and
     (FIndiceFoto < High(FFotosColeccion)) then
    SeleccionarFoto(FIndiceFoto + 1);
end;

procedure TfrmFotoArticulo.btnAnadirFotoClick(Sender: TObject);
var
  iIndiceAlternativo: Integer;
  oNueva              : TFotoInfo;
  sUnidad             : string;
begin
  inherited;
  if not FModoSesion then
  begin
    if FCodigoArt = '' then
      ShowMessage_fza(SErrorFotoArticuloNoActivo)
    else
    begin
      // Sin SKU, el alta pertenece siempre a la galería general del
      // artículo, incluso si la vista usa como fallback la primera foto de
      // una unidad. Con SKU se añade al nivel efectivo mostrado o, si aún no
      // hay fotos, al nivel elegido en el combo. La foto general del
      // artículo mostrada como respaldo no es un nivel del SKU: entonces
      // también manda el combo (FZ-ISSUE-111).
      if FCodigoSku = '' then
        sUnidad := ''
      else if FUltimaInfo.Encontrada and
              (FUltimaInfo.Origen <> foArticulo) then
        sUnidad := FUltimaInfo.ClaveResuelta
      else
        sUnidad := ClaveNivelSeleccionado;

      if dlgAbrirFoto.Execute then
      begin
        try
          iIndiceAlternativo := Length(FFotosColeccion);
          oNueva := FotosArticulos.Anadir(
            FCodigoArt,
            sUnidad,
            dlgAbrirFoto.FileName,
            IdentidadSesion.Usuario);
          CargarColeccionArticulo(
            oNueva.NombreBase, oNueva.Orden, iIndiceAlternativo);
          if (sUnidad <> '') and (oNueva.Orden = 1) then
            AsegurarPredeterminadaArticulo(
              dlgAbrirFoto.FileName);
        except
          on E: Exception do
            ShowMessage_fza(Format(SErrorGuardarFotoArticulo, [E.Message]));
        end;
      end;
    end;
  end;
end;

procedure TfrmFotoArticulo.btnMarcarPredeterminadaClick(
  Sender: TObject);
begin
  inherited;
  MarcarFotoActualPredeterminada;
end;

procedure TfrmFotoArticulo.MarcarFotoActualPredeterminada;
var
  oPredeterminada: TFotoInfo;
begin
  if (not FModoSesion) and FUltimaInfo.Encontrada and
     (FUltimaInfo.Orden > 1) then
  begin
    try
      oPredeterminada := FotosArticulos.MarcarPredeterminada(
        FUltimaInfo, IdentidadSesion.Usuario);
      CargarColeccionArticulo(
        oPredeterminada.NombreBase, 1, 0);
    except
      on E: Exception do
        ShowMessage_fza(Format(SErrorGuardarFotoArticulo, [E.Message]));
    end;
  end;
end;

procedure TfrmFotoArticulo.btnCambiarArtClick(Sender: TObject);
var
  bGuardada   : Boolean;
  bRutaElegida: Boolean;
  sRutaFoto   : string;
begin
  inherited;
  if FModoSesion and (FCodigoArtTentativoSesion = '') then
    ShowMessage_fza(SErrorLineaSesionSinCodigoArticulo)
  else if (not FModoSesion) and (FCodigoArt = '') then
    ShowMessage_fza(SErrorFotoArticuloNoActivo)
  else
  begin
    sRutaFoto := '';
    if FModoSesion then
    begin
      bRutaElegida := dlgAbrirFoto.Execute;
      if bRutaElegida then
        sRutaFoto := dlgAbrirFoto.FileName;
    end
    else
      bRutaElegida := SeleccionarRutaPredeterminada(sRutaFoto);
    if bRutaElegida then
    begin
      bGuardada := True;
      try
        if FModoSesion and FFotoDefinitivaSesion then
          FotosArticulos.Guardar(
            FCodigoArtTentativoSesion,
            FUltimaInfo.ClaveResuelta,
            sRutaFoto,
            IdentidadSesion.Usuario)
        else if FModoSesion then
          FotosArticulos.Sesion.Guardar(
            FSerieSesion,
            FNumeroSesion,
            FLineaSesion,
            FCodigoArtTentativoSesion,
            FCodigoUnidadSesion,
            sRutaFoto,
            IdentidadSesion.Usuario)
        else
          FotosArticulos.Guardar(
            FCodigoArt,
            '',
            sRutaFoto,
            IdentidadSesion.Usuario);
      except
        on E: Exception do
        begin
          bGuardada := False;
          ShowMessage_fza(Format(SErrorGuardarFotoArticulo, [E.Message]));
        end;
      end;
      if bGuardada then
      begin
        if FModoSesion then
        begin
          SetSesion(
            FSerieSesion,
            FNumeroSesion,
            FLineaSesion,
            FCodigoArtTentativoSesion,
            FCodigoUnidadSesion);
          NotificarCambioFotoSesion;
        end
        else
          SetArticuloSku(FCodigoArt, FCodigoSku);
      end;
    end;
  end;
end;

procedure TfrmFotoArticulo.btnCambiarSkuClick(Sender: TObject);
var
  sClave: string;
  bGuardada: Boolean;
begin
  inherited;
  sClave := '';
  if FCodigoSku = '' then
    ShowMessage_fza(SErrorFotoSkuNoActivo)
  else
  begin
    sClave := ClaveNivelSeleccionado;
    if sClave = '' then
      ShowMessage_fza(SErrorNivelAtributosFotoNoSeleccionado)
    else if dlgAbrirFoto.Execute then
    begin
      bGuardada := True;
      try
        FotosArticulos.Guardar(FCodigoArt, sClave, dlgAbrirFoto.FileName,
          IdentidadSesion.Usuario);
        AsegurarPredeterminadaArticulo(
          dlgAbrirFoto.FileName);
      except
        on E: Exception do
        begin
          bGuardada := False;
          ShowMessage_fza(Format(SErrorGuardarFotoArticulo, [E.Message]));
        end;
      end;
      if bGuardada then
        SetArticuloSku(FCodigoArt, FCodigoSku);
    end;
  end;
end;

procedure TfrmFotoArticulo.btnQuitarClick(Sender: TObject);
var
  iIndiceAnterior: Integer;
begin
  inherited;
  if FModoSesion and (FCodigoArtTentativoSesion = '') then
    ShowMessage_fza(SErrorLineaSesionSinCodigoArticulo)
  else if FUltimaInfo.Encontrada and
     (MessageDlg_fza(SPreguntaEliminarFotoActual, mtConfirmation,
      [mbYes, mbNo], 0) = mrYes) then
  begin
    if FModoSesion and FFotoDefinitivaSesion then
    begin
      FotosArticulos.Eliminar(
        FCodigoArtTentativoSesion,
        FUltimaInfo.ClaveResuelta);
      SetSesion(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FCodigoArtTentativoSesion,
        FCodigoUnidadSesion);
      NotificarCambioFotoSesion;
    end
    else if FModoSesion then
    begin
      FotosArticulos.Sesion.Eliminar(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FUltimaInfo.ClaveResuelta);
      SetSesion(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FCodigoArtTentativoSesion,
        FCodigoUnidadSesion);
      NotificarCambioFotoSesion;
    end
    else
    begin
      iIndiceAnterior := FIndiceFoto;
      FotosArticulos.Eliminar(FUltimaInfo);
      CargarColeccionArticulo('', 0, iIndiceAnterior);
    end;
  end;
end;

procedure TfrmFotoArticulo.btnRotarIzqClick(Sender: TObject);
var
  iIndiceAnterior: Integer;
  oRotada        : TFotoInfo;
begin
  inherited;
  if FModoSesion and (FCodigoArtTentativoSesion = '') then
    ShowMessage_fza(SErrorLineaSesionSinCodigoArticulo)
  else if FUltimaInfo.Encontrada then
  begin
    if FModoSesion and FFotoDefinitivaSesion then
    begin
      FotosArticulos.Rotar(
        FCodigoArtTentativoSesion,
        FUltimaInfo.ClaveResuelta,
        False,
        IdentidadSesion.Usuario);
      SetSesion(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FCodigoArtTentativoSesion,
        FCodigoUnidadSesion);
      NotificarCambioFotoSesion;
    end
    else if FModoSesion then
    begin
      FotosArticulos.Sesion.Rotar(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FUltimaInfo.ClaveResuelta,
        False,
        IdentidadSesion.Usuario);
      SetSesion(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FCodigoArtTentativoSesion,
        FCodigoUnidadSesion);
      NotificarCambioFotoSesion;
    end
    else
    begin
      iIndiceAnterior := FIndiceFoto;
      oRotada := FotosArticulos.Rotar(
        FUltimaInfo,
        False,
        IdentidadSesion.Usuario);
      CargarColeccionArticulo(
        oRotada.NombreBase, oRotada.Orden, iIndiceAnterior);
    end;
  end;
end;

procedure TfrmFotoArticulo.btnRotarDerClick(Sender: TObject);
var
  iIndiceAnterior: Integer;
  oRotada        : TFotoInfo;
begin
  inherited;
  if FModoSesion and (FCodigoArtTentativoSesion = '') then
    ShowMessage_fza(SErrorLineaSesionSinCodigoArticulo)
  else if FUltimaInfo.Encontrada then
  begin
    if FModoSesion and FFotoDefinitivaSesion then
    begin
      FotosArticulos.Rotar(
        FCodigoArtTentativoSesion,
        FUltimaInfo.ClaveResuelta,
        True,
        IdentidadSesion.Usuario);
      SetSesion(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FCodigoArtTentativoSesion,
        FCodigoUnidadSesion);
      NotificarCambioFotoSesion;
    end
    else if FModoSesion then
    begin
      FotosArticulos.Sesion.Rotar(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FUltimaInfo.ClaveResuelta,
        True,
        IdentidadSesion.Usuario);
      SetSesion(
        FSerieSesion,
        FNumeroSesion,
        FLineaSesion,
        FCodigoArtTentativoSesion,
        FCodigoUnidadSesion);
      NotificarCambioFotoSesion;
    end
    else
    begin
      iIndiceAnterior := FIndiceFoto;
      oRotada := FotosArticulos.Rotar(
        FUltimaInfo,
        True,
        IdentidadSesion.Usuario);
      CargarColeccionArticulo(
        oRotada.NombreBase, oRotada.Orden, iIndiceAnterior);
    end;
  end;
end;

procedure TfrmFotoArticulo.NotificarCambioFotoSesion;
begin
  if Assigned(FAlCambiarFotoSesion) then
    FAlCambiarFotoSesion(Self);
end;

procedure TfrmFotoArticulo.btnLayoutClick(Sender: TObject);
begin
  inherited;
  // Equivalente a Alt+F12. Como el auto-show no activa la ventana,
  // hasta que el usuario no clicke algo el shortcut no llega aqui;
  // este boton explicito siempre funciona.
  GuardarLayout;
end;

// ---------------------------------------------------------------------
//   Auto-refresh: hook al dsTablaG del Mto padre
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.VincularDataSources(
  const ADataSources: array of TDataSource;
  AResolver: TResolverArtSkuProc);
begin
  DesengancharDataChange;
  FPadreResolver := AResolver;
  VincularDataSourcesInterno(ADataSources);
end;

procedure TfrmFotoArticulo.VincularSesion(
  const ADataSources: array of TDataSource;
  AResolver: TResolverFotoSesionProc;
  AAlCambiarFoto: TNotifyEvent);
begin
  DesengancharDataChange;
  FPadreResolverSesion := AResolver;
  FAlCambiarFotoSesion := AAlCambiarFoto;
  VincularDataSourcesInterno(ADataSources);
end;

procedure TfrmFotoArticulo.VincularDataSourcesInterno(
  const ADataSources: array of TDataSource);
var
  ds: TDataSource;
begin
  if FHooksDataSource = nil then
    FHooksDataSource := TObjectList<TEnlaceFotoFlotante>.Create(True);
  for ds in ADataSources do
    if ds <> nil then
      FHooksDataSource.Add(
        TEnlaceFotoFlotante.Create(ds, OnPadreDataChange));
end;

procedure TfrmFotoArticulo.RefrescarDesdePadre(AMto: TObject);
var
  sArt: string;
  sSku: string;
begin
  if (not FModoSesion) and Assigned(FPadreResolver) and
     (TMethod(FPadreResolver).Data = Pointer(AMto)) then
  begin
    FPadreResolver(sArt, sSku);
    if (sArt <> FCodigoArt) or (sSku <> FCodigoSku) then
      SetArticuloSku(sArt, sSku);
  end;
end;

procedure TfrmFotoArticulo.DesvincularPadre(AMto: TObject);
begin
  if Assigned(FPadreResolver) and
     (TMethod(FPadreResolver).Data = Pointer(AMto)) then
    DesengancharDataChange;
end;

procedure TfrmFotoArticulo.VincularMtoPadre(
  ADataSource: TDataSource; AResolver: TResolverArtSkuProc);
begin
  // Atajo retro-compatible: delega en VincularDataSources con un solo
  // DataSource.
  VincularDataSources([ADataSource], AResolver);
end;

procedure TfrmFotoArticulo.DesengancharDataChange;
begin
  if Assigned(FHooksDataSource) then
    FHooksDataSource.Clear;
  FPadreResolver := nil;
  FPadreResolverSesion := nil;
  FAlCambiarFotoSesion := nil;
end;

{ TEnlaceFotoFlotante }

constructor TEnlaceFotoFlotante.Create(ADataSource: TDataSource;
  AAlCambiar: TDataChangeEvent);
begin
  inherited Create;
  FAlCambiar := AAlCambiar;
  DataSource := ADataSource;
end;

procedure TEnlaceFotoFlotante.Avisar;
begin
  if Assigned(FAlCambiar) then
    FAlCambiar(DataSource, nil);
end;

procedure TEnlaceFotoFlotante.DataSetChanged;
begin
  inherited;
  Avisar;
end;

procedure TEnlaceFotoFlotante.DataSetScrolled(Distance: Integer);
begin
  inherited;
  Avisar;
end;

procedure TEnlaceFotoFlotante.RecordChanged(Field: TField);
begin
  inherited;
  // Solo el cambio de registro, no cada campo editado.
  if Field = nil then
    Avisar;
end;

procedure TfrmFotoArticulo.OnPadreDataChange(Sender: TObject; Field: TField);
var
  sArt          : string;
  sSku          : string;
  sSerieSesion  : string;
  sNumeroSesion : string;
  sCodArtSesion : string;
  sUnidadSesion : string;
  iLineaSesion  : Integer;
begin
  // Solo refrescamos cuando cambia el registro activo (Field = nil),
  // no en cada cambio de columna.
  if (Field = nil) and FModoSesion and
     Assigned(FPadreResolverSesion) then
  begin
    FPadreResolverSesion(
      sSerieSesion,
      sNumeroSesion,
      iLineaSesion,
      sCodArtSesion,
      sUnidadSesion);
    if not CoincideSesion(
      sSerieSesion, sNumeroSesion, iLineaSesion, sUnidadSesion) or
      (sCodArtSesion <> FCodigoArtTentativoSesion) then
      SetSesion(
        sSerieSesion,
        sNumeroSesion,
        iLineaSesion,
        sCodArtSesion,
        sUnidadSesion);
  end
  else if (Field = nil) and Assigned(FPadreResolver) then
  begin
    FPadreResolver(sArt, sSku);
    if (sArt <> FCodigoArt) or (sSku <> FCodigoSku) then
      SetArticuloSku(sArt, sSku);
  end;
end;

procedure MostrarFotoFlotante(AOwner: TComponent;
                               const ACodArt, ACodSku: string);
var
  Formulario: TfrmFotoArticulo;
  hwndPrev: HWND;
begin
  // Capturamos el foreground window ANTES de mostrar la flotante,
  // asi podemos devolverle el foco despues (clave para que el Mto
  // no pierda el teclado cuando la ventana se auto-abre).
  hwndPrev := GetForegroundWindow;
  Formulario := FotoFlotanteActual;
  if Formulario = nil then
    // Owner = Application, no el Mto que llama: la pantalla sobrevive
    // a cierres de Mtos y se libera de forma ordenada al terminar la
    // app (de lo contrario quedan colgando los hooks y los strings
    // del combo + FUltimaInfo cuando el Mto se libera primero).
    Formulario := TfrmFotoArticulo.Create(Application);
  Formulario.SetArticuloSku(ACodArt, ACodSku);
  if not Formulario.Visible then
  begin
    // Restaurar tamaño/posición guardados ANTES de mostrar, de forma fiable
    // (sin depender de que OnShow dispare con SW_SHOWNOACTIVATE).
    Formulario.RestaurarGeometriaGuardada;
    // SW_SHOWNOACTIVATE: muestra la ventana SIN activarla. A
    // diferencia de TForm.Show (que termina llamando SetActiveWindow
    // y roba el teclado al Mto), aqui la flotante aparece encima por
    // pertenecer al Mto (PopupParent) pero el foco se queda en quien
    // lo tenia.
    // Sincronizamos Visible a mano porque ShowWindow no lo hace.
    ShowWindow(Formulario.Handle, SW_SHOWNOACTIVATE);
    Formulario.Visible := True;
  end;
  // Belt-and-braces: si por algun motivo el foreground cambio
  // (algunas combinaciones Windows/VCL activan igual), lo devolvemos.
  // Cuando el usuario clicka DIRECTAMENTE sobre la flotante (boton,
  // combo, radio), la activacion es normal: WM_MOUSEACTIVATE default
  // -> MA_ACTIVATE y los controles funcionan.
  if (hwndPrev <> 0) and IsWindow(hwndPrev) and
     (hwndPrev <> Formulario.Handle) and
     (GetForegroundWindow = Formulario.Handle) then
    SetForegroundWindow(hwndPrev);
end;

procedure MostrarFotoSesionFlotante(AOwner: TComponent;
  const ASerieSesion, ANumeroSesion: string; ALinea: Integer;
  const ACodArtTentativo, ACodUnidad: string);
var
  Formulario: TfrmFotoArticulo;
  hwndPrev: HWND;
begin
  hwndPrev := GetForegroundWindow;
  Formulario := FotoFlotanteActual;
  if Formulario = nil then
    Formulario := TfrmFotoArticulo.Create(Application);
  Formulario.SetSesion(
    ASerieSesion,
    ANumeroSesion,
    ALinea,
    ACodArtTentativo,
    ACodUnidad);
  if not Formulario.Visible then
  begin
    Formulario.RestaurarGeometriaGuardada;
    ShowWindow(Formulario.Handle, SW_SHOWNOACTIVATE);
    Formulario.Visible := True;
  end;
  if (hwndPrev <> 0) and IsWindow(hwndPrev) and
     (hwndPrev <> Formulario.Handle) and
     (GetForegroundWindow = Formulario.Handle) then
    SetForegroundWindow(hwndPrev);
end;

end.
