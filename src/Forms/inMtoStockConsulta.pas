{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (ventana independiente)                            }
{ Version:       0.8.1                                                         }
{   Fecha:       09/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Consulta de stock invocable con Ctrl+U desde cualquier mantenimiento      }
{    que herede de TfrmMtoGen. Al abrirse pre-carga el articulo / SKU activo   }
{    via TfrmMtoGen.ResolverArtSkuActivo.                                      }
{                                                                              }
{    Layout (estilo OdaGest+):                                                 }
{      - Cabecera (pnlCabecera): boton de busqueda de articulo + descripcion   }
{        + bloque de info (temporada, tarifas, proveedores) + foto.            }
{      - Filtros (pnlFiltros): combo "Estado del stock" + modo.                }
{      - Cuerpo (pnlBody): split horizontal con un TSplitter.                  }
{        * pnlIzq (alLeft, 280px): pcFiltros con las pestanas de colores y     }
{          almacenes (seleccion multiple).                                     }
{        * pnlDer (alClient): pcVistas con las pestanas de pivote (por         }
{          almacenes / por colores) y las de fotos relacionadas, mas el        }
{          TcxGrid compartido.                                                 }
{                                                                              }
{    v0.8.1: el Enter del lector (cierre de rafaga o CR tras ETX) entra por    }
{    OnShortCut, antes que jvEnterTab y que el boton con foco.                 }
{    v0.8: el formulario queda como capa de vista. El estado explicito vive    }
{    en TEstadoVistaStockConsulta y el comportamiento en presentadores:        }
{    entrada por texto y codigo de barras, historial, coincidencias, fotos     }
{    relacionadas, estados/leyenda y rejilla pivote. Los adaptadores de        }
{    persistencia se resuelven una sola vez en la composicion de la pantalla   }
{    (inMtoStockConsultaPresentacionComposicion) y ningun evento vuelve a      }
{    descubrir repositorios.                                                   }
{    v0.7: boton "Op de Caja" para consultar en un modal las operaciones DE,   }
{    DV y VE del SKU seleccionado en una celda de talla.                       }
{    v0.6: letrero de propiedades por color (nivel COLOR / SKU).               }
{    v0.5: estado "Todo a la vez" y colores por estado.                        }
{******************************************************************************}
unit inMtoStockConsulta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus, Vcl.Imaging.pngimage, Vcl.AppEvnts,
  Data.DB,
  cxClasses, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxButtonEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCheckBox, cxListBox, cxCustomData, cxStyles,
  cxCurrencyEdit,
  cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxGraphics, cxLocalization,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxScrollbarAnnotations,
  dxDateRanges, cxMemo, cxControls, dxCoreGraphics, cxCustomListBox,
  cxRadioGroup, cxSplitter, inLibLectorScanner, inLibDocumentosTrabajo,
  inLibFotos,
  inMtoFrmBase, inLibPermisosIntf,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaPresentacionPropiedades,
  inLibStockConsultaPresentacionVista,
  inMtoStockConsultaPresentacionArticuloVcl,
  inMtoStockConsultaPresentacionComposicion,
  inMtoStockConsultaPresentacionFiltrosVcl,
  inMtoStockConsultaPresentacionFotosVcl,
  inMtoStockConsultaPresentacionPivoteVcl,
  inLibPestanasEjeVcl;

const
  NOMBRE_PANTALLA_STOCK_CONSULTA = 'frmStockConsulta';
  // Detector por velocidad de tecleo (codigo de barras + CR, sin STX/ETX).

type
  TfrmStockConsulta = class(TfrmBase)
    pnlCabecera   : TPanel;
      btnOperacionesCaja: TcxButton;
      btnMovimientos: TcxButton;
      lblArt        : TcxLabel;
      btnArt        : TcxButtonEdit;
      lblDescr      : TcxLabel;
      mInfoCabecera : TcxMemo;
      lblLetreroTemp: TcxLabel;
      imgFoto       : TImage;
    pnlFiltros    : TPanel;
      lblEstado     : TcxLabel;
      cbbEstado     : TcxComboBox;
    pnlBody       : TPanel;
    pnlIzq        : TPanel;
    pcFiltros     : TcxPageControl;
    tsColores     : TcxTabSheet;
    lblColores    : TcxLabel;
    lstColores    : TcxListBox;
    tsAlmacenes   : TcxTabSheet;
    lblAlmacenes  : TcxLabel;
    lstAlmacenes  : TcxListBox;
    splVert       : TcxSplitter;
    pnlDer        : TPanel;
    pcVistas      : TcxPageControl;
    tsPorAlmacen  : TcxTabSheet;
    tsPorColor    : TcxTabSheet;
    grdStock      : TcxGrid;
    tvStock       : TcxGridDBTableView;
    glStock       : TcxGridLevel;
    pnlLeyenda    : TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure btnArtPropertiesButtonClick(Sender: TObject;
              AButtonIndex: Integer);
    procedure btnArtPropertiesEditValueChanged(Sender: TObject);
    procedure btnOperacionesCajaClick(Sender: TObject);
    procedure btnMovimientosClick(Sender: TObject);
    procedure btnPorLoteClick(Sender: TObject);
    procedure CrearBotonPorLote;
    procedure cbbEstadoPropertiesEditValueChanged(Sender: TObject);
    procedure lstAlmacenesClick(Sender: TObject);
    procedure lstColoresClick(Sender: TObject);
    procedure pcVistasChange(Sender: TObject);
    procedure tvStockCellDblClick(Sender: TcxCustomGridTableView;
              ACellViewInfo: TcxGridTableDataCellViewInfo;
              AButton: TMouseButton; AShift: TShiftState;
              var AHandled: Boolean);
  private
    FVista: TEstadoVistaStockConsulta;
    FEstados: TPresentadorEstadosStock;
    FPivote: TPresentadorPivoteStock;
    // Pestañas de copa (eje S) sobre la rejilla; ocultas con «Tallas y
    // colores».
    FPestanas: TControlPestanasEje;
    FFotos: TPresentadorFotosRelacionadasStock;
    FHistorial: TPresentadorHistorialStock;
    FCoincidencias: TPresentadorCoincidenciasStock;
    FPropsPorColor: TPropiedadesPorColorStock;
    FFiltrosLista: TPresentadorFiltrosListaStock;
    FPopMenuStock: TPopupMenu;
    FMenuAgregarDoc: TMenuItem;
    FEventosLector: TApplicationEvents;
    btnPorLote: TcxButton;
    procedure MensajeLector(var Msg: TMsg; var Handled: Boolean);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure LectorCodigoLeido(Sender: TObject;
              const ACodigo: string);
    procedure MenuAgregarDocClick(Sender: TObject);
    procedure CrearPresentadores;
    procedure GuardarModoUsuario;
    function  ModoDesglosadoDeUsuario: Boolean;
    procedure CargarPropsPorColor;
    procedure ActualizarLetreroColor;
    procedure AjustarFotoCabecera;
    procedure CargarFoto(const ACodUnidad: string);
    procedure CargarInfoCabecera;
    function  BuscarArticulo: string;
    function  ResolverCodigoSkuDocumentoTrabajo(
              const AColor, ATalla: string;
              out ACodigoSku, AMensaje: string): Boolean;
    function  ResolverSkuCeldaOperacionesCaja(
              out ACodigoSku, AMensaje: string): Boolean;
    function  EstadoFilaEnfocada: TEstadoStock;
    procedure MostrarTraspasosPendientes;
    procedure RecargarConsulta;
    procedure MostrarError(const AMsg: string);
    procedure btnArtKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure btnArtExit(Sender: TObject);
    procedure ResolverTextoArticulo(AMostrarError: Boolean);
    procedure OmitirTabEnArticulo(Sender: TObject; AControl: TWinControl;
              var AProcesado: Boolean);
  protected
    FDependencias: TContextoDependenciasStockConsulta;
    procedure CrearMenuStock;
    function ResolverCeldaDocumentoTrabajo(
      out ALinea: TDocTrabajoLineaOrigen;
      out AMensaje: string): Boolean; virtual;
    procedure AgregarLineaADocumentoTrabajo(
      const ALinea: TDocTrabajoLineaOrigen); virtual;
    procedure AvisarCeldaDocumentoTrabajo(const AMensaje: string); virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
  end;

/// Abre (o trae al frente) la consulta de stock con el (articulo, sku)
/// indicado. Mismo patron que inMtoFotoArticulo.MostrarFotoFlotante.
procedure MostrarStockConsulta(const ACodArt, ACodSku: string);
procedure DesvincularPerfilesStockConsulta;

implementation

uses
  inLibMensajesVcl,
  System.StrUtils,
  inLibGenBusq, inLibUser,
  inLibRegistroPantallas,
  inLibPerfilesUsuarioIntf,
  inLibStockCeldaDocumento,
  inLibStockConsultaInfo,
  inLibStockConsultaEntrada,
  inLibStockConsultaPresentacionPivote,
  inMtoStockConsultaEntradaVcl,
  inMtoModalOperacionesCajaSku, inMtoModalMovimientosSku,
  inLibMsgArticulos, inLibMsgCaja,
  inLibMsgComun, inLibMsgVentas, inLibMsgFacturas,
  inLibDocumentosTrabajoPresentacion,
  inLibVentanaBarraTareas,
  inLibStockConsultaPresentacionEstados,
  inLibTraspasosPendientesTexto, UniDataTraspasosPendientesConsulta,
  inMtoModalMensajeTexto,
  inLibShowMto, inLibTrazabilidad, inLibMsgLotesConsultas,
  inMtoLotesCaducidades;

{$R *.dfm}

resourcestring
  STituloBuscarArticulosStock = 'Búsqueda de Artículos';
  SCaptionCodigoBusquedaStock = 'Código';
  SCaptionDescripcionBusquedaStock = 'Descripción';
  SCaptionFamiliaBusquedaStock = 'Familia';
  SCaptionTemporadaBusquedaStock = 'Temporada';
  SCaptionProveedorBusquedaStock = 'Proveedor';
  SCaptionReferenciaProveedorBusquedaStock = 'Ref. proveedor';
  SCaptionPvpBusquedaStock = 'PVP';

const
  // Identificador de aplicacion propio: boton separado en la barra de
  // tareas, con el icono de la consulta, aunque la barra combine botones.
  GRUPO_BARRA_TAREAS_STOCK = 'ViraCash.Stock';
  ICONO_CONSULTA_STOCK = 'MNUCONSULTASTOCKS';
  PERFIL_STOCK_CONSULTA = NOMBRE_PANTALLA_STOCK_CONSULTA;
  PERFIL_MODO_DESGLOSADO = 'ModoDesglosado';
  LAYOUT_BUSQUEDA_ARTICULOS = 'frmMtoArtStockSearch';

// Traduce el motivo de bloqueo de la celda a su mensaje. Las reglas viven
// en inLibStockCeldaDocumento; aqui solo se les pone texto.
function MensajeCeldaStock(AMotivo: TMotivoCeldaDocumento): string;
begin
  case AMotivo of
    mcdSinArticulo:
      Result := SErrorArticuloStockNoSeleccionadoDocumento;
    mcdEstadoNoExistencias:
      Result := SErrorEstadoStockNoEsExistencias;
    mcdSinFila:
      Result := SErrorCeldaStockNoSeleccionada;
    mcdSinColumnaCantidad:
      Result := SErrorCeldaCantidadStockNoSeleccionada;
    mcdFilaNoExistencias:
      Result := SErrorFilaExistenciasStockNoSeleccionada;
    mcdColumnaNoValida:
      Result := SErrorColumnaStockDocumentoNoSeleccionada;
    mcdGrupoNoLeido:
      Result := SErrorGrupoFilaStockNoLeido;
    mcdAlmacenNoUnico:
      Result := SErrorAlmacenStockNoUnico;
    mcdColorNoUnico:
      Result := SErrorColorStockUnidadNoUnico;
  else
    Result := '';
  end;
end;

// ---------------------------------------------------------------------------
//  Funcion publica de apertura
// ---------------------------------------------------------------------------
function BuscarStockConsulta: TfrmStockConsulta;
var
  iFormulario: Integer;
begin
  Result := nil;
  for iFormulario := 0 to Screen.FormCount - 1 do
  begin
    if (Screen.Forms[iFormulario] is TfrmStockConsulta) and
       not (csDestroying in
         Screen.Forms[iFormulario].ComponentState) then
    begin
      Result := TfrmStockConsulta(Screen.Forms[iFormulario]);
    end;
  end;
end;

procedure MostrarStockConsulta(const ACodArt, ACodSku: string);
var
  Formulario: TfrmStockConsulta;
begin
  Formulario := BuscarStockConsulta;
  if Formulario = nil then
    Formulario := CrearPantallaInyectada(
      TfrmStockConsulta,
      Application) as TfrmStockConsulta;
  Formulario.SetArticuloSku(ACodArt, ACodSku);
  if Formulario.WindowState = wsMinimized then
    Formulario.WindowState := wsMaximized;
  // Mostrar CON foco para que ESC cierre la ventana sin tener que pinchar
  // antes. Antes se mostraba con SW_SHOWNOACTIVATE y devolvia el foco a la
  // ventana anterior, lo que dejaba la consulta imposible de cerrar con ESC.
  Formulario.Visible := True;
  // Windows quita WS_VISIBLE a una ventana cuando se minimiza el
  // programa, sin avisar a la VCL: la propiedad Visible se queda en
  // True y la ventana no volveria a aparecer nunca (se ve su imagen
  // muerta en pantalla y no responde). Se fuerza a mano.
  if not IsWindowVisible(Formulario.Handle) then
    ShowWindow(Formulario.Handle, SW_SHOW);
  Formulario.BringToFront;
  SetForegroundWindow(Formulario.Handle);
  if Formulario.btnArt.CanFocus then
    Formulario.btnArt.SetFocus;
end;

procedure DesvincularPerfilesStockConsulta;
var
  Formulario: TfrmStockConsulta;
begin
  Formulario := BuscarStockConsulta;
  if Formulario <> nil then
    Formulario.AsignarPerfilesUsuario(
      CrearServiciosPerfilesUsuario(nil, nil, nil));
end;

// ---------------------------------------------------------------------------
//  Ciclo de vida
// ---------------------------------------------------------------------------
// Ventana independiente, como la del TPV: boton e icono propios en la
// barra de tareas (WS_EX_APPWINDOW) y sin propietario, de modo que
// sobrevive al minimizar el programa y se alterna con ella desde la
// barra. A cambio, al volver a la ventana principal queda detras: se
// recupera por su boton.
procedure TfrmStockConsulta.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle   := Params.ExStyle or WS_EX_APPWINDOW;
  Params.WndParent := 0;
end;

procedure TfrmStockConsulta.CreateWnd;
var
  hIcono: HICON;
begin
  inherited;
  AsignarGrupoBarraTareas(Handle, GRUPO_BARRA_TAREAS_STOCK);
  // Tambien en la propiedad del formulario: la VCL reenvia WM_SETICON
  // con el icono del formulario cada vez que toca el marco, y sin esto
  // la ventana volveria al icono de la aplicacion.
  if Icon.Handle = 0 then
  begin
    hIcono := IconoDesdeRecursoPng(ICONO_CONSULTA_STOCK + '_32');
    if hIcono <> 0 then
      Icon.Handle := hIcono;
  end;
  AsignarIconoVentanaDesdePng(Handle, ICONO_CONSULTA_STOCK);
end;

procedure TfrmStockConsulta.DestroyWnd;
begin
  // La propiedad debe quitarse antes de destruir la ventana.
  QuitarGrupoBarraTareas(Handle);
  LiberarIconoVentana(Handle);
  inherited;
end;

procedure TfrmStockConsulta.FormCreate(Sender: TObject);
begin
  inherited;
  FDependencias.Validar;
  Self.Position := poDesigned;
  Self.WindowState := wsMaximized;
  // ESC cierra la ventana; KeyPreview para capturarlo aunque el foco este
  // en el grid o el combo. Tambien sirve al hook del lector de codigo de
  // barras (FormKeyPress / FormKeyDown), que captura la lectura venga de
  // donde venga el foco. OnShortCut entrega al lector el Enter que cierra
  // la lectura ANTES de que jvEnterTab lo convierta en Tab o de que el boton
  // con foco lo tome como clic (FormShortCut).
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
  Self.OnKeyPress := FormKeyPress;
  Self.OnShortCut := FormShortCut;
  Self.OnResize := FormResize;
  // Coste (ultimo precio de compra del proveedor) solo para quien tenga
  // permiso: TienePermiso devuelve True siempre a admin; al resto, oculto
  // por defecto salvo permiso explicito 'caja.verCoste'.
  FVista.Limpiar;
  FVista.VerCoste := Assigned(Permisos) and
                     Permisos.TienePermiso(
                       PERMISO_CAJA_VER_COSTE,
                       paDenegar);
  // Detector del lector. Modo "consumir": las teclas de la rafaga no llegan
  // a btnArt (evita disparar SetArticuloSku en cada tecla del escaneo).
  FDependencias.Lector := TLectorScanner.Create;
  FDependencias.Lector.ConsumirRafaga := True;
  FDependencias.Lector.OnCodigoLeido := LectorCodigoLeido;
  FEventosLector := TApplicationEvents.Create(Self);
  FEventosLector.OnMessage := MensajeLector;
  CrearPresentadores;
  FFiltrosLista.CargarAlmacenes;
  AjustarFotoCabecera;
  CrearBotonPorLote;
end;

// F-LOTEC-018: con trazabilidad, el stock del artículo por lote, serie
// o temporada se ve en «Lotes y caducidades» (junto a Movimientos).
procedure TfrmStockConsulta.CrearBotonPorLote;
begin
  if Assigned(ParametrosApp) and
     TActivacionTrazabilidad.Leer(ParametrosApp).AlgunModoActivo then
  begin
    btnPorLote := TcxButton.Create(Self);
    btnPorLote.Parent := btnMovimientos.Parent;
    btnPorLote.SetBounds(
      btnMovimientos.Left + btnMovimientos.Width +
        (btnMovimientos.Left - btnOperacionesCaja.Left -
         btnOperacionesCaja.Width),
      btnMovimientos.Top, btnMovimientos.Width, btnMovimientos.Height);
    btnPorLote.Caption := SCaptionStockPorLote;
    btnPorLote.OnClick := btnPorLoteClick;
  end;
end;

// Compone los colaboradores de la pantalla en el orden que exige la vista:
// primero la rejilla y la entrada, despues las pestanas de fotos y por
// ultimo el selector de estado, que ya dispara la primera recarga.
procedure TfrmStockConsulta.CrearPresentadores;
var
  Callbacks: TCallbacksVistaEntradaStock;
begin
  FFiltrosLista := TPresentadorFiltrosListaStock.Create(
    lstAlmacenes,
    lstColores,
    FDependencias.Catalogos);
  FPivote := TPresentadorPivoteStock.Create(
    Self, tvStock, FDependencias.Pivote, ConexionPrincipal);
  FPestanas := TControlPestanasEje.Create(Self, pnlDer,
    procedure(const ACodigo: string)
    begin
      RecargarConsulta;
    end);
  // Debajo de las pestañas Por almacén / Por color y encima de la rejilla.
  FPestanas.Control.Top := pcVistas.Top + pcVistas.Height;
  Callbacks := Default(TCallbacksVistaEntradaStock);
  Callbacks.AplicarArticulo :=
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      SetArticuloSku(ACodigoArticulo, ACodigoSku);
    end;
  Callbacks.MostrarCoincidencias :=
    procedure(const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string)
    begin
      FCoincidencias.Mostrar(
        ACoincidencias,
        Format(SHintCoincidenciasPara, [AEntrada]));
    end;
  Callbacks.MostrarTextoNoEncontrado :=
    procedure(const AEntrada: string)
    begin
      MostrarError(Format(
        SErrorEntradaStockNoEncontrada, [AEntrada]));
    end;
  Callbacks.MostrarCodigoBarrasNoEncontrado :=
    procedure(const ACodigo: string)
    begin
      MostrarError(Format(
        SErrorCodigoBarrasStockNoEncontrado, [ACodigo]));
    end;
  FDependencias.Entrada := CrearAplicacionEntradaStock(
    CrearRepositorioEntradaStock(FDependencias.Catalogos),
    FDependencias.Validador,
    CrearVistaEntradaStock(Callbacks));
  FPropsPorColor := TPropiedadesPorColorStock.Create;
  FHistorial := TPresentadorHistorialStock.Create(
    Self, pnlCabecera, btnArt,
    SHintArticuloAnterior, SHintArticuloSiguiente,
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      SetArticuloSku(ACodigoArticulo, ACodigoSku);
    end);
  FCoincidencias := TPresentadorCoincidenciasStock.Create(
    Self, pnlCabecera, btnArt,
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      FVista.ResolviendoEntrada := True;
      try
        FCoincidencias.Ocultar;
        SetArticuloSku(ACodigoArticulo, ACodigoSku);
      finally
        FVista.ResolviendoEntrada := False;
      end;
    end,
    function: Boolean
    begin
      Result := FVista.AdmiteSeleccionCoincidencia;
    end);
  btnArt.OnKeyDown := btnArtKeyDown;
  btnArt.OnExit := btnArtExit;
  jvntrstb1.OnHandleEnter := OmitirTabEnArticulo;
  // Letrero de aviso: oculto por defecto, rojo y en negrita para que "cante"
  // las propiedades propias del color (color/SKU) al pincharlo.
  lblLetreroTemp.Transparent      := False;
  lblLetreroTemp.Style.Color      := $003C3CD8;  // rojo (BGR)
  lblLetreroTemp.Style.TextColor  := clWhite;
  lblLetreroTemp.Style.Font.Style := [fsBold];
  lblLetreroTemp.Style.Font.Color := clWhite;
  lblLetreroTemp.Visible          := False;
  CrearMenuStock;
  FFotos := TPresentadorFotosRelacionadasStock.Create(
    Self, pcVistas, pnlDer, grdStock,
    SCaptionFotosMismaFamilia, SCaptionFotosMismoProveedor,
    SCaptionFotosMismaTemporada,
    FDependencias.Catalogos, FotosArticulos,
    procedure(const ACodigoArticulo: string)
    begin
      if Trim(ACodigoArticulo) <> '' then
        SetArticuloSku(ACodigoArticulo, '');
    end);
  FEstados := TPresentadorEstadosStock.Create(
    Self, cbbEstado, pnlFiltros, pnlLeyenda, cbbEstado,
    SCaptionModoSimplificado, SCaptionModoDesglosado,
    procedure
    begin
      RecargarConsulta;
    end,
    procedure
    begin
      GuardarModoUsuario;
    end);
  FEstados.AplicarModo(ModoDesglosadoDeUsuario);
  FEstados.MarcarModoEnRadios;
  FEstados.AplicarColorEstadoActual;
  pcVistas.ActivePage := tsPorAlmacen;
  pcFiltros.ActivePage := tsColores;
end;

procedure TfrmStockConsulta.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FEventosLector);
  if FPivote <> nil then
    FPivote.Limpiar;
  FreeAndNil(FFotos);
  FreeAndNil(FPestanas);
  FreeAndNil(FPivote);
  FreeAndNil(FEstados);
  FreeAndNil(FHistorial);
  FreeAndNil(FCoincidencias);
  FreeAndNil(FPropsPorColor);
  FreeAndNil(FFiltrosLista);
  FDependencias.Liberar;
end;

procedure TfrmStockConsulta.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TfrmStockConsulta.FormResize(Sender: TObject);
begin
  AjustarFotoCabecera;
end;

// ESC oculta la ventana flotante. KeyPreview=True (FormCreate) garantiza que
// el form vea la tecla aunque el foco este en el grid, el combo o un check.
procedure TfrmStockConsulta.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // El detector cierra la lectura por velocidad (rafaga + Enter rapido) y
  // consume el VK_RETURN si procede.
  FDependencias.Lector.KeyDown(Key, Shift);
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    if not FCoincidencias.CerrarConEscape then
      Close;
  end;
end;

// Hook del lector a nivel de formulario: delegamos en TLectorScanner, que
// detecta la trama STX/ETX y la rafaga por velocidad. El codigo leido llega
// luego por OnCodigoLeido (LectorCodigoLeido).
procedure TfrmStockConsulta.FormKeyPress(Sender: TObject; var Key: Char);
begin
  FDependencias.Lector.KeyPress(Key);
end;

procedure TfrmStockConsulta.MensajeLector(var Msg: TMsg;
  var Handled: Boolean);
begin
  if not Handled then
    Handled := FDependencias.Lector.MensajeTrama(Msg, Self);
end;

// OnShortCut se dispara en CN_KEYDOWN, antes que CM_DIALOGKEY (jvEnterTab de
// TfrmBase convierte Enter en Tab) y que el boton con foco (Enter = clic).
// Sin esto, con el foco en btnArt o en "Op de Caja", el Enter
// que cierra una rafaga del lector o el CR que envia tras ETX no llegaba a
// FormKeyDown: la lectura se perdia o pulsaba el boton.
procedure TfrmStockConsulta.FormShortCut(var Msg: TWMKey;
  var Handled: Boolean);
begin
  if FDependencias.Lector.AtajoTeclado(Msg) then
    Handled := True;
end;

// Resuelve el codigo SOLO contra codigos de barras y carga el articulo/SKU
// en la consulta, igual que al teclear o buscar un articulo.
procedure TfrmStockConsulta.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  if Assigned(FDependencias.Entrada) then
  begin
    FVista.ResolviendoEntrada := True;
    try
      FCoincidencias.Ocultar;
      FDependencias.Entrada.ProcesarCodigoBarras(ACodigo);
    finally
      FVista.ResolviendoEntrada := False;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Entrada de articulo por texto
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.OmitirTabEnArticulo(Sender: TObject;
  AControl: TWinControl; var AProcesado: Boolean);
begin
  AProcesado := AProcesado or btnArt.ContainsControl(AControl);
end;

procedure TfrmStockConsulta.btnArtKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    ResolverTextoArticulo(True);
  end;
end;

procedure TfrmStockConsulta.btnArtExit(Sender: TObject);
begin
  ResolverTextoArticulo(False);
end;

procedure TfrmStockConsulta.ResolverTextoArticulo(AMostrarError: Boolean);
begin
  if FVista.AdmiteResolverEntrada and Assigned(FDependencias.Entrada) and
    (not FDependencias.Lector.LecturaPendiente) then
  begin
    FVista.ResolviendoEntrada := True;
    try
      FDependencias.Entrada.ProcesarTexto(
        btnArt.Text,
        FVista.CodigoArticulo,
        AMostrarError);
    finally
      FVista.ResolviendoEntrada := False;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Menu contextual: agregar la celda a un documento de trabajo
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CrearMenuStock;
begin
  // No resolver el SKU en OnPopup: una consulta puede cambiar la
  // ventana activa y cancelar el menú nativo antes de procesar el clic.
  // La acción queda accesible para explicar también los bloqueos.
  FPopMenuStock := TPopupMenu.Create(Self);
  FMenuAgregarDoc := TMenuItem.Create(FPopMenuStock);
  FMenuAgregarDoc.Caption := SCaptionAgregarDocumentoTrabajo;
  FMenuAgregarDoc.OnClick := MenuAgregarDocClick;
  FPopMenuStock.Items.Add(FMenuAgregarDoc);
  grdStock.PopupMenu := FPopMenuStock;
end;

procedure TfrmStockConsulta.MenuAgregarDocClick(Sender: TObject);
var
  Linea: TDocTrabajoLineaOrigen;
  sMensaje: string;
begin
  if ResolverCeldaDocumentoTrabajo(Linea, sMensaje) then
  begin
    try
      AgregarLineaADocumentoTrabajo(Linea);
    except
      on E: Exception do
        MostrarError(E.Message);
    end;
  end
  else
  begin
    AvisarCeldaDocumentoTrabajo(sMensaje);
  end;
end;

procedure TfrmStockConsulta.AgregarLineaADocumentoTrabajo(
  const ALinea: TDocTrabajoLineaOrigen);
begin
  AgregarUnidadADocumentoTrabajo(
    Self,
    ConexionPrincipal,
    FDependencias.DocumentosTrabajo,
    CrearInteraccionDocumentosTrabajoVcl,
    BusquedaVisual,
    ContextoSesion,
    ParametrosCaja,
    ALinea,
    FDependencias.ResolverArticulos);
end;

procedure TfrmStockConsulta.AvisarCeldaDocumentoTrabajo(
  const AMensaje: string);
begin
  MessageBox_fza(AMensaje, STituloDocumentoTrabajo,
    MB_OK or MB_ICONINFORMATION);
end;

// Con pestañas de copa, en «Todas» la celda suma varias copas: se pide
// elegir una antes de buscar el SKU.
function TfrmStockConsulta.ResolverCodigoSkuDocumentoTrabajo(
  const AColor, ATalla: string; out ACodigoSku, AMensaje: string): Boolean;
var
  iCoincidencias: Integer;
begin
  Result := False;
  ACodigoSku := '';
  AMensaje := '';
  if FPestanas.HayPestanas and (FPestanas.CodigoSeleccionado = '') then
    AMensaje := Format(SAvisoElegirPestanaStock,
      [AnsiLowerCase(FPestanas.NombreEje)])
  else
  begin
    iCoincidencias := FDependencias.Catalogos.ResolverSku(
      FVista.CodigoArticulo,
      AColor,
      FPestanas.CodigoSeleccionado,
      ATalla,
      ACodigoSku);
    if iCoincidencias = 1 then
      Result := True
    else if iCoincidencias = 0 then
      AMensaje := SErrorSkuCeldaStockNoEncontrado
    else
      AMensaje := SErrorCeldaStockVariosSkus;
  end;
end;

function TfrmStockConsulta.ResolverCeldaDocumentoTrabajo(
  out ALinea: TDocTrabajoLineaOrigen; out AMensaje: string): Boolean;
var
  Estado: TEstadoCeldaStock;
  Celda: TCeldaDocumentoResuelta;
  Linea: TLineaCeldaStock;
  dCantidad: Double;
  bHayCantidad: Boolean;
  sSku: string;
begin
  Result := False;
  ALinea.Clear;
  // Aqui solo se lee el grid; las decisiones (guardas, talla, almacen
  // y color) viven en inLibStockCeldaDocumento.
  Estado := Default(TEstadoCeldaStock);
  Estado.CodigoArticulo := FVista.CodigoArticulo;
  Estado.EstadoEsExistencias := FEstados.EstadoActual = esExistencias;
  Estado.HayColoresEnLista := lstColores.Items.Count > 0;
  Estado.AlmacenesSeleccionados :=
    FFiltrosLista.AlmacenesSeleccionados;
  Estado.ColoresSeleccionados :=
    FFiltrosLista.ColoresSeleccionados;
  FPivote.LeerCeldaEnfocada(Estado);
  Celda := ResolverCeldaStockParaDocumento(Estado);
  AMensaje := MensajeCeldaStock(Celda.Motivo);
  if AMensaje = '' then
  begin
    if ResolverCodigoSkuDocumentoTrabajo(Celda.Color, Celda.Talla,
                                         sSku, AMensaje) then
    begin
      bHayCantidad := FPivote.CantidadEnfocada(dCantidad);
      Linea := ComponerLineaCeldaStock(
        FVista.CodigoArticulo, Celda.Almacen, sSku,
        Trim(Celda.Color + ' ' + FPestanas.CodigoSeleccionado),
        Celda.Talla, dCantidad, not bHayCantidad);
      ALinea.CodigoArticulo := Linea.CodigoArticulo;
      ALinea.CodigoSku := Linea.CodigoSku;
      ALinea.CodigoAlmacen := Linea.CodigoAlmacen;
      ALinea.DescripcionSku := Linea.DescripcionSku;
      ALinea.Origen := Linea.Origen;
      ALinea.CantidadStock := Linea.CantidadStock;
      ALinea.Cantidad := Linea.Cantidad;
      Result := True;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Operaciones de caja del SKU de la celda enfocada
// ---------------------------------------------------------------------------
function TfrmStockConsulta.ResolverSkuCeldaOperacionesCaja(
  out ACodigoSku, AMensaje: string): Boolean;
var
  Colores: TArray<string>;
  sColor: string;
  sGrupo: string;
  sTalla: string;
begin
  Result := False;
  ACodigoSku := '';
  AMensaje := '';
  sColor := '';
  sTalla := '';
  sGrupo := '';
  if not FVista.HayArticulo then
    AMensaje := SErrorArticuloStockNoSeleccionadoOperaciones
  else if not FPivote.HayFilaEnfocada then
    AMensaje := SErrorCeldaTallaStockNoSeleccionada
  else if not FPivote.HayColumnaEnfocada then
    AMensaje := SErrorCeldaTallaStockNoSeleccionada
  else if not FPivote.TallaEnfocada(sTalla) then
    AMensaje := SErrorColumnaTallaStockNoSeleccionada
  else if not FPivote.GrupoEnfocado(sGrupo) then
    AMensaje := SErrorFilaStockNoIdentificada;
  if AMensaje = '' then
  begin
    if FPivote.EsModoColor then
      sColor := sGrupo
    else
    begin
      // En vista por almacenes la celda solo identifica un SKU si el
      // filtro de colores deja uno solo, o si el articulo no tiene color.
      Colores := FFiltrosLista.ColoresSeleccionados;
      if Length(Colores) = 1 then
        sColor := Colores[0]
      else if (Length(Colores) = 0) and
              (lstColores.Items.Count = 0) then
        sColor := ''
      else
        AMensaje := SErrorColorStockNoUnico;
    end;
  end;
  if AMensaje = '' then
  begin
    Result := ResolverCodigoSkuDocumentoTrabajo(
                sColor, sTalla, ACodigoSku, AMensaje);
    if (not Result) and
       SameText(AMensaje, SErrorCeldaStockVariosSkus) then
      AMensaje := SErrorTallaStockVariosSkus;
  end;
end;

procedure TfrmStockConsulta.btnOperacionesCajaClick(Sender: TObject);
var
  sCodigoSku: string;
  sMensaje: string;
begin
  if ResolverSkuCeldaOperacionesCaja(sCodigoSku, sMensaje) then
    TfrmModalOperacionesCajaSku.Ejecutar(
      Self,
      ConexionPrincipal,
      FDependencias.OperacionesCaja,
      sCodigoSku,
      lblDescr.Caption)
  else
    MessageBox_fza(
      PChar(sMensaje),
      PChar(STituloOperacionesCajaStock),
      MB_OK or MB_ICONINFORMATION);
end;

procedure TfrmStockConsulta.btnPorLoteClick(Sender: TObject);
var
  sArticulo: string;
begin
  sArticulo := FVista.CodigoArticulo;
  // FZ-ISSUE-601: la consulta flotante no es anfitriona de pantallas;
  // la abre el principal, como en las demás ventanas flotantes.
  ShowMto(Application.MainForm, 'LotesCaducidades', '',
    procedure(AFormulario: TForm)
    begin
      if AFormulario is TfrmMtoLotesCaducidades then
        TfrmMtoLotesCaducidades(AFormulario).FiltrarArticulo(sArticulo);
    end);
end;

procedure TfrmStockConsulta.btnMovimientosClick(Sender: TObject);
var
  sCodigoSku: string;
  sMensaje: string;
begin
  if ResolverSkuCeldaOperacionesCaja(sCodigoSku, sMensaje) then
  begin
    if TfrmModalMovimientosSku.Ejecutar(
         Self,
         FDependencias.Movimientos,
         sCodigoSku,
         lblDescr.Caption) then
      RecargarConsulta;
  end
  else
    MessageBox_fza(
      PChar(sMensaje),
      PChar(STituloMovimientosAlmacen),
      MB_OK or MB_ICONINFORMATION);
end;

procedure TfrmStockConsulta.tvStockCellDblClick(
  Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo;
  AButton: TMouseButton; AShift: TShiftState;
  var AHandled: Boolean);
var
  Columna: TcxGridDBColumn;
  sTalla: string;
begin
  if (AButton = mbLeft) and (FPivote <> nil) and
     (ACellViewInfo <> nil) and
     (ACellViewInfo.Item is TcxGridDBColumn) then
  begin
    Columna := TcxGridDBColumn(ACellViewInfo.Item);
    // FZ-ISSUE-251: en las filas de pendiente de traspaso o disponible, el
    // doble clic enseña los documentos pendientes.
    if EstadoFilaEnfocada in
       [esPdteTraspasar, esPdteRecTraspaso, esDisponible] then
    begin
      tvStock.Controller.FocusedColumn := Columna;
      MostrarTraspasosPendientes;
      AHandled := True;
    end
    else if TallaDeColumnaPivoteStock(
         Columna.DataBinding.FieldName,
         FPivote.Tallas,
         sTalla) then
    begin
      // El primer clic ya enfoca la fila; fijamos tambien la columna para que
      // el doble clic siga exactamente el mismo camino que el boton.
      tvStock.Controller.FocusedColumn := Columna;
      btnMovimientosClick(Sender);
      AHandled := True;
    end;
  end;
end;

// Estado de la fila enfocada: el elegido o, con «Todos los estados», el
// de la propia fila (ESTADO_NUM).
function TfrmStockConsulta.EstadoFilaEnfocada: TEstadoStock;
var
  oCampo: TField;
begin
  Result := FEstados.EstadoActual;
  if (Result = esTodoAlaVez) and
     (tvStock.DataController.DataSet <> nil) then
  begin
    oCampo := tvStock.DataController.DataSet.FindField(
      CAMPO_ESTADO_PIVOTE_STOCK);
    if (oCampo <> nil) and EsEstadoStockValido(oCampo.AsInteger) then
      Result := TEstadoStock(oCampo.AsInteger);
  end;
end;

// FZ-ISSUE-251: documentos pendientes del articulo; por almacen si la vista
// es por almacenes y por SKU si la celda identifica uno.
procedure TfrmStockConsulta.MostrarTraspasosPendientes;
var
  sAlmacen, sGrupo, sSku, sMensaje, sAmbito: string;
begin
  if not FVista.HayArticulo then
    Exit;
  sAlmacen := '';
  if (not FPivote.EsModoColor) and FPivote.GrupoEnfocado(sGrupo) then
    sAlmacen := sGrupo;
  if not ResolverSkuCeldaOperacionesCaja(sSku, sMensaje) then
    sSku := '';
  sAmbito := FVista.CodigoArticulo;
  if sSku <> '' then
    sAmbito := sSku;
  TfrmModalMensajeTexto.Mostrar(Self, STituloTraspasosPendientesStock,
    TextoTraspasosPendientes(
      ConsultarTraspasosPendientes(ConexionPrincipal,
        FVista.CodigoArticulo, sAlmacen, sSku),
      sAmbito, sAlmacen));
end;

// Muestra un mensaje de error de la consulta. El dialogo pertenece a
// esta ventana, asi que sale sobre ella sin taparlo todo.
procedure TfrmStockConsulta.MostrarError(const AMsg: string);
begin
  MessageBox_fza(PChar(AMsg), PChar(STituloConsultaStock),
    MB_OK or MB_ICONERROR);
end;

// ---------------------------------------------------------------------------
//  Perfil de usuario: modo simplificado / desglosado
// ---------------------------------------------------------------------------
function TfrmStockConsulta.ModoDesglosadoDeUsuario: Boolean;
var
  Perfil: TProfileDicc;
begin
  Perfil := nil;
  try
    GetFormUserProfile(Perfil, PERFIL_STOCK_CONSULTA,
                       IdentidadSesion.Usuario,
                       IdentidadSesion.Grupo,
                       PerfilesLectura);
    Result := SameText(
      GetPerfilValueDef(Perfil, PERFIL_MODO_DESGLOSADO, 'N'), 'S');
  finally
    if Perfil <> nil then
      FreeAndNil(Perfil);
  end;
end;

procedure TfrmStockConsulta.GuardarModoUsuario;
begin
  if Assigned(PerfilesEscritura) then
    PerfilesEscritura.GrabarPerfil(
      IdentidadSesion.Usuario,
      PERFIL_STOCK_CONSULTA,
      PERFIL_MODO_DESGLOSADO,
      IfThen(FEstados.ModoDesglosado, 'S', 'N'));
end;

// ---------------------------------------------------------------------------
//  Propiedades propias por color (nivel COLOR / SKU)
// ---------------------------------------------------------------------------
// Las propiedades admiten nivel COLOR y SKU (propiedades_por_unidad.md). El
// filtrado y el formato viven en inLibStockConsultaPresentacionPropiedades;
// aqui solo se traduce el dataset a registros de dominio.
procedure TfrmStockConsulta.CargarPropsPorColor;
var
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
  Propiedad: TPropiedadColorStock;
begin
  FPropsPorColor.Limpiar;
  if FVista.HayArticulo then
  begin
    Resultado := FDependencias.Catalogos.ConsultarPropiedadesPorColor(
      FVista.CodigoArticulo);
    Datos := Resultado.DataSet;
    try
      while not Datos.Eof do
      begin
        Propiedad := Default(TPropiedadColorStock);
        Propiedad.Color := Datos.FieldByName('COLOR').AsString;
        Propiedad.Nombre := Datos.FieldByName('NOMBRE').AsString;
        Propiedad.Nivel := Datos.FieldByName('NIVEL').AsString;
        Propiedad.TipoValor := Datos.FieldByName('TIPO').AsString;
        Propiedad.ValorLista := Datos.FieldByName('PVTXT').AsString;
        Propiedad.ValorLibre := Datos.FieldByName('VLIBRE').AsString;
        Propiedad.ValorListaArticulo :=
          Datos.FieldByName('PVA').AsString;
        Propiedad.ValorLibreArticulo :=
          Datos.FieldByName('VLIBRE_ART').AsString;
        FPropsPorColor.Agregar(Propiedad);
        Datos.Next;
      end;
    finally
      Resultado := nil;
    end;
  end;
end;

// Recompone el letrero para el color sobre el que se acaba de pinchar: si
// tiene propiedades propias distintas a las del articulo, las "canta"; si
// no, oculta el letrero.
procedure TfrmStockConsulta.ActualizarLetreroColor;
var
  iSeleccion: Integer;
  sColor: string;
begin
  if (FPropsPorColor <> nil) and (lblLetreroTemp <> nil) then
  begin
    sColor := '';
    iSeleccion := lstColores.ItemIndex;
    if (iSeleccion >= 0) and (iSeleccion < lstColores.Items.Count) then
      sColor := lstColores.Items[iSeleccion];
    if (sColor <> '') and FPropsPorColor.TieneColor(sColor) then
    begin
      lblLetreroTemp.Caption := LetreroPropiedadesColorStock(
        sColor, FPropsPorColor.TextoDe(sColor));
      lblLetreroTemp.Visible := True;
    end
    else
    begin
      lblLetreroTemp.Caption := '';
      lblLetreroTemp.Visible := False;
    end;
    AjustarFotoCabecera;
  end;
end;

// ---------------------------------------------------------------------------
//  Carga de articulo / SKU + foto + info de cabecera
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.SetArticuloSku(const ACodArt, ACodSku: string);
var
  sDescripcion: string;
  Dimension: TDimensionFotos;
  bArticuloEncontrado: Boolean;
begin
  FVista.FijarArticulo(ACodArt, ACodSku);
  FVista.ActualizandoArticulo := True;
  try
    btnArt.Text := ACodArt;
  finally
    FVista.ActualizandoArticulo := False;
  end;
  FCoincidencias.Ocultar;
  FFotos.FijarArticulo(ACodArt);
  bArticuloEncontrado := False;
  // Cambiar de articulo con una pestana de fotos activa devuelve la vista
  // al pivote, que es lo que el usuario espera ver del articulo nuevo.
  if FFotos.DimensionActiva(Dimension) then
  begin
    FVista.SilenciandoCambioVista := True;
    try
      pcVistas.ActivePage := tsPorAlmacen;
    finally
      FVista.SilenciandoCambioVista := False;
    end;
  end;
  lblDescr.Caption := '';
  if FVista.HayArticulo then
  begin
    bArticuloEncontrado :=
      FDependencias.Catalogos.ObtenerDescripcionArticulo(
        ACodArt, sDescripcion);
    if bArticuloEncontrado then
      lblDescr.Caption := sDescripcion;
  end;
  // Errores de carga (foto / cabecera / colores) por encima de la ventana.
  try
    CargarFoto(FVista.CodigoSku);
    CargarInfoCabecera;
    FFiltrosLista.CargarColores(
      FVista.CodigoArticulo,
      FVista.CodigoSku);
    CargarPropsPorColor;
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
  // El letrero arranca oculto: solo "canta" cuando el usuario pincha un color.
  lblLetreroTemp.Caption := '';
  lblLetreroTemp.Visible := False;
  AjustarFotoCabecera;
  if bArticuloEncontrado then
    FHistorial.Registrar(ACodArt);
  FHistorial.ActualizarBotones;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.AjustarFotoCabecera;
const
  MARGEN_FOTO       = 8;
  PORCENTAJE_INICIO = 55;
  ANCHO_TEXTO_MIN   = 480;
  ANCHO_FOTO_MIN    = 180;
var
  iIzquierda    : Integer;
  iAlto         : Integer;
  iLimiteInferior: Integer;
  iMargen       : Integer;
  iAnchoTextoMin: Integer;
  iAnchoFotoMin : Integer;
begin
  iMargen := MulDiv(MARGEN_FOTO, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iAnchoTextoMin := MulDiv(ANCHO_TEXTO_MIN, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iAnchoFotoMin := MulDiv(ANCHO_FOTO_MIN, CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  iIzquierda := pnlCabecera.ClientWidth * PORCENTAJE_INICIO div 100;
  if iIzquierda < iAnchoTextoMin then
    iIzquierda := iAnchoTextoMin;
  if iIzquierda > pnlCabecera.ClientWidth - iAnchoFotoMin then
    iIzquierda := pnlCabecera.ClientWidth - iAnchoFotoMin;
  iLimiteInferior := pnlCabecera.ClientHeight - iMargen;
  if lblLetreroTemp.Visible then
    Dec(iLimiteInferior, lblLetreroTemp.Height);

  // El texto largo se desplaza dentro del memo, sin invadir los filtros
  // ni quitar espacio a la rejilla al cambiar de articulo.
  iAlto := iLimiteInferior - mInfoCabecera.Top;
  if iAlto < 0 then
    iAlto := 0;
  mInfoCabecera.SetBounds(mInfoCabecera.Left, mInfoCabecera.Top,
    iIzquierda - mInfoCabecera.Left - iMargen, iAlto);
  iAlto := iLimiteInferior - iMargen;
  imgFoto.SetBounds(iIzquierda,
                    iMargen,
                    pnlCabecera.ClientWidth - iIzquierda - iMargen,
                    iAlto);
end;

// En la consulta de stock la foto dispone de una zona amplia: se carga
// siempre la copia a resolucion real y se ajusta proporcionalmente.
procedure TfrmStockConsulta.CargarFoto(const ACodUnidad: string);
var
  Info: TFotoInfo;
  sRuta: string;
  Png: TPngImage;
begin
  imgFoto.Picture.Assign(nil);
  if FVista.HayArticulo then
  begin
    Info := FotosArticulos.Resolver(FVista.CodigoArticulo, ACodUnidad);
    sRuta := FotosArticulos.RutaFoto(Info, frReal);
    if sRuta <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.LoadFromFile(sRuta);
        imgFoto.Picture.Assign(Png);
      finally
        FreeAndNil(Png);
      end;
    end;
  end;
end;

// Bloque de info de la cabecera (propiedades + tarifas vigentes +
// proveedores). El formato lo decide inLibStockConsultaInfo.
procedure TfrmStockConsulta.CargarInfoCabecera;
begin
  mInfoCabecera.Lines.Clear;
  if FVista.HayArticulo then
    mInfoCabecera.Lines.Text := FormatearInfoCabeceraStock(
      FDependencias.InfoCabecera.Cargar(FVista.CodigoArticulo),
      ParametrosCaja.TarifaDefecto,
      FVista.VerCoste);
  mInfoCabecera.SelStart := 0;
end;

// ---------------------------------------------------------------------------
//  Recarga del pivote
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.RecargarConsulta;
var
  bPorColor: Boolean;
  Dimension: TDimensionFotos;
  Solicitud: TSolicitudPivoteStock;
  Tallas: TArray<TInfoColumna>;
begin
  FPivote.Limpiar;
  if FFotos.DimensionActiva(Dimension) then
  begin
    FFotos.MostrarVista(True);
    try
      FFotos.CargarSiProcede;
    except
      on E: Exception do
        MostrarError(E.Message);
    end;
  end
  else
  begin
    FFotos.MostrarVista(False);
    bPorColor := pcVistas.ActivePage = tsPorColor;
    // Cursor de espera: el pivote en modo "Todos los estados" puede tardar y
    // bloquea el hilo de UI; al menos el usuario ve que esta trabajando.
    Screen.Cursor := crHourGlass;
    try
      try
        SetLength(Tallas, 0);
        if FVista.HayArticulo then
          Tallas := FPivote.ListarTallas(
            FVista.CodigoArticulo,
            FFiltrosLista.ColoresSeleccionados);
        FPivote.ReconstruirColumnas(
          Tallas, bPorColor, FEstados.EstadoActual);
        Solicitud := ComponerSolicitudPivoteStock(
          FVista.CodigoArticulo,
          FEstados.EstadoActual,
          FEstados.ModoDesglosado,
          bPorColor,
          Assigned(ParametrosApp) and
            ParametrosApp.GetBool('appStockOcultarCeros', True),
          FFiltrosLista.AlmacenesSeleccionados,
          FFiltrosLista.ColoresSeleccionados);
        if FVista.HayArticulo then
          FPestanas.Mostrar(FDependencias.Pivote.ConsultarPestanas(
            Solicitud))
        else
          FPestanas.Ocultar;
        Solicitud.Pestana := FPestanas.CodigoSeleccionado;
        FPivote.Consultar(Solicitud, Tallas);
      except
        on E: Exception do
        begin
          // El error sale por encima de la ventana (le pertenece).
          FPivote.Limpiar;
          MostrarError(E.Message);
        end;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Busqueda de articulos (popup del boton "...")
// ---------------------------------------------------------------------------
// Lanza el buscador visual inyectado con las columnas Codigo / Descripcion /
// Familia / Temporada / Proveedor ppal. / PVP. Layout persistido bajo el
// Name 'frmMtoArtStockSearch' (independiente del de caja).
function TfrmStockConsulta.BuscarArticulo: string;
  procedure ConfigCampo(ACampo: TField; const ATitulo, AFormato: string);
  begin
    if ACampo <> nil then
    begin
      if ATitulo <> '' then
        ACampo.DisplayLabel := ATitulo;
      if AFormato <> '' then
      begin
        if ACampo is TFloatField then
          TFloatField(ACampo).DisplayFormat := AFormato
        else if ACampo is TBCDField then
          TBCDField(ACampo).DisplayFormat := AFormato
        else if ACampo is TFMTBCDField then
          TFMTBCDField(ACampo).DisplayFormat := AFormato;
      end;
    end;
  end;
var
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
begin
  Result := '';
  Resultado := FDependencias.Catalogos.BuscarArticulos(
    ParametrosCaja.TarifaDefecto);
  Datos := Resultado.DataSet;
  try
    ConfigCampo(Datos.FindField('CODIGO_ART_ART'),
      SCaptionCodigoBusquedaStock, '');
    ConfigCampo(Datos.FindField('DESCRIPCION_ART'),
      SCaptionDescripcionBusquedaStock, '');
    ConfigCampo(Datos.FindField('DESCRIPCION_FAM'),
      SCaptionFamiliaBusquedaStock, '');
    ConfigCampo(Datos.FindField('TEMPORADA'),
      SCaptionTemporadaBusquedaStock, '');
    ConfigCampo(Datos.FindField('PROVEEDOR'),
      SCaptionProveedorBusquedaStock, '');
    ConfigCampo(Datos.FindField('REF_PROVEEDOR'),
      SCaptionReferenciaProveedorBusquedaStock, '');
    ConfigCampo(Datos.FindField('PRECIO_PVP'),
      SCaptionPvpBusquedaStock, '#,##0.00 €');
    if BusquedaVisual.EjecutarBusquedaDataSet(
      STituloBuscarArticulosStock,
      Datos,
      LAYOUT_BUSQUEDA_ARTICULOS) then
      Result := Datos.FieldByName('CODIGO_ART_ART').AsString;
  finally
    Resultado := nil;
  end;
end;

// ---------------------------------------------------------------------------
//  Eventos de la vista
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.btnArtPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  sCodigo: string;
begin
  sCodigo := BuscarArticulo;
  if sCodigo <> '' then
    SetArticuloSku(sCodigo, '');
end;

procedure TfrmStockConsulta.btnArtPropertiesEditValueChanged(
  Sender: TObject);
begin
  if FVista.AdmiteCambioTextoArticulo and (Trim(btnArt.Text) = '') then
    SetArticuloSku('', '');
end;

procedure TfrmStockConsulta.cbbEstadoPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEstados.AplicarColorEstadoActual;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.lstAlmacenesClick(Sender: TObject);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.lstColoresClick(Sender: TObject);
var
  iColor: Integer;
  sCodUnidad: string;
begin
  ActualizarLetreroColor;
  sCodUnidad := FVista.CodigoSku;
  iColor := lstColores.ItemIndex;
  // La clave ARTICULO/COLOR permite resolver primero la foto propia del
  // color y recurrir a la foto general del articulo cuando no exista.
  if (iColor >= 0) and (iColor < lstColores.Items.Count) and
     lstColores.Selected[iColor] then
    sCodUnidad := FVista.ClaveUnidadColor(lstColores.Items[iColor]);
  try
    CargarFoto(sCodUnidad);
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.pcVistasChange(Sender: TObject);
begin
  if FVista.AdmiteCambioVista then
  begin
    FFotos.ReiniciarDimensionActiva;
    RecargarConsulta;
  end;
end;

end.
