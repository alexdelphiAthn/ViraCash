{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalDistribucionTiendas                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Distribución de la mercancía de un documento de trabajo entre tiendas.    }
{    Maestro por artículo y color; detalle con un cuadrante almacenes por      }
{    tallas que enseña las existencias en un color y el reparto en otro. Se    }
{    teclea lo que recibe cada tienda (sale del origen que más tenga o del     }
{    fijado) o se arrastra con Mayúsculas de un almacén a otro. El reparto     }
{    se guarda como propuestas de traspaso, que aquí mismo se imprimen y se    }
{    confirman. Las reglas viven en inLibDistribucionTiendas.                  }
{******************************************************************************}
unit inMtoModalDistribucionTiendas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxDropDownEdit,
  cxLabel, cxButtons, cxClasses, cxLocalization, cxPC, cxSplitter,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxCurrencyEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGrid, dxSkinsCore, dxSkinscxPCPainter, dxDateRanges,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoModalAceptCancel,
  inLibDistribucionTiendasIntf, inLibDistribucionTiendas,
  inLibFotoMiniaturaMtoVcl;

const
  WM_REFRESCAR_CUADRANTE_DISTRIBUCION = WM_APP + 310;
  WM_AVISOS_INICIALES_DISTRIBUCION = WM_APP + 311;

type
  TConfiguracionDistribucionTiendas = record
    IdDocumento: Int64;
    Servicios: TServiciosDistribucionTiendas;
    Usuario: string;
    PuedeImprimir: Boolean;
  end;

  TResultadoDistribucionTiendas = record
    // Se guardó el reparto o se resolvió alguna propuesta.
    HuboCambios: Boolean;
  end;

  TArrastreDistribucion = record
    Activo: Boolean;
    Almacen: string;
    Sku: string;
  end;

  TfrmModalDistribucionTiendas = class(TfrmModalAceptCancel)
    pnlOpciones: TPanel;
    lblOrigen: TcxLabel;
    cbbOrigen: TcxComboBox;
    lblMinimo: TcxLabel;
    edtMinimoOrigen: TcxSpinEdit;
    btnPrioridades: TcxButton;
    btnRepartoAutomatico: TcxButton;
    btnVaciar: TcxButton;
    lblAviso: TcxLabel;
    pcDistribucion: TcxPageControl;
    tsReparto: TcxTabSheet;
    tsPropuestas: TcxTabSheet;
    cxgrdGrupos: TcxGrid;
    tvGrupos: TcxGridTableView;
    glGrupos: TcxGridLevel;
    splDetalle: TcxSplitter;
    pnlDetalle: TPanel;
    cxgrdReparto: TcxGrid;
    tvReparto: TcxGridTableView;
    glReparto: TcxGridLevel;
    pnlLeyenda: TPanel;
    lblLeyendaExistencias: TcxLabel;
    lblLeyendaReparto: TcxLabel;
    lblLeyendaSalida: TcxLabel;
    lblLeyendaAyuda: TcxLabel;
    pnlAccionesPropuestas: TPanel;
    btnImprimirPropuestas: TcxButton;
    btnConfirmarPropuesta: TcxButton;
    btnConfirmarTodas: TcxButton;
    btnEliminarPropuesta: TcxButton;
    cxgrdPropuestas: TcxGrid;
    tvPropuestas: TcxGridTableView;
    glPropuestas: TcxGridLevel;
    btnGuardar: TcxButton;
    procedure cbbOrigenPropertiesChange(Sender: TObject);
    procedure edtMinimoOrigenPropertiesChange(Sender: TObject);
    procedure btnPrioridadesClick(Sender: TObject);
    procedure btnRepartoAutomaticoClick(Sender: TObject);
    procedure btnVaciarClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnImprimirPropuestasClick(Sender: TObject);
    procedure btnConfirmarPropuestaClick(Sender: TObject);
    procedure btnConfirmarTodasClick(Sender: TObject);
    procedure btnEliminarPropuestaClick(Sender: TObject);
    procedure cxgrdRepartoEnter(Sender: TObject);
    procedure cxgrdRepartoExit(Sender: TObject);
  private
    FConfiguracion: TConfiguracionDistribucionTiendas;
    FDocumento: TDocumentoDistribucion;
    FModelo: TDistribucionTiendas;
    FGrupos: TGruposDistribucion;
    FColumnas: TColumnasDistribucion;
    FAlmacenesFila: TArray<string>;
    FOrigenesCombo: TArray<string>;
    FPropuestas: TPropuestasTraspaso;
    FArrastre: TArrastreDistribucion;
    FActualizando: Boolean;
    FHuboCambios: Boolean;
    FColorReparto: TColor;
    FColorSalida: TColor;
    FParametrosAutomaticos: TParametrosRepartoAutomatico;
    FMiniaturaFoto: TMiniaturaFotoMto;
    procedure ConfigurarVistas;
    procedure CrearPanelFoto;
    procedure ResolverArtSkuGrupo(out ACodArt, ACodSku: string);
    procedure AbrirFotoGrupo(Sender: TObject);
    procedure ElegirColores;
    function CrearColumna(
      AVista: TcxGridTableView;
      const ATitulo: string;
      AAncho: Integer;
      ANumerica: Boolean): TcxGridColumn;
    procedure CrearColumnasGrupos;
    procedure CrearColumnasPropuestas;
    procedure CargarDocumento;
    procedure CargarComboOrigen;
    procedure CargarGrupos;
    procedure ActualizarTotalesGrupos;
    procedure CargarPropuestas;
    function GrupoEnfocado: Integer;
    function PropuestaEnfocada(
      out APropuesta: TPropuestaTraspaso): Boolean;
    procedure ReconstruirCuadrante;
    procedure VolcarCuadrante;
    function ValorCelda(const AAlmacen, ASku: string): Variant;
    function EsOrigenDelGrupo(const AAlmacen: string): Boolean;
    function OrigenesDelReparto: TArray<string>;
    function AlmacenesDelGrupo: TAlmacenesDistribucion;
    function CeldaEditable(const AAlmacen, ASku: string): Boolean;
    function DetalleExistenciasOrigen(const ASku: string): string;
    function SkusDelGrupoEnfocado: TArray<string>;
    procedure RefrescarStocks(const ASkus: TArray<string>);
    procedure EditarPrioridades;
    function SkuDeColumna(AItem: TcxCustomGridTableItem): string;
    function CeldaDeHit(
      X, Y: Integer; out AAlmacen, ASku: string): Boolean;
    procedure MostrarAviso(const ATexto: string);
    procedure MostrarAvisoAsignacion(
      const AAlmacen, ASku: string;
      const AResultado: TResultadoAsignacion);
    procedure AplicarOpcionesOrigen;
    function GuardarCambios: Boolean;
    function GuardarSiHaceFalta: Boolean;
    procedure ConfirmarPropuestas(
      const APropuestas: TPropuestasTraspaso);
    function PropuestasPendientes: TPropuestasTraspaso;
    procedure LeerPreferencias;
    procedure GuardarPreferencias;
    procedure GruposFocoCambiado(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure RepartoEditando(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem;
      var AAllow: Boolean);
    procedure RepartoRegistroCambiado(
      ADataController: TcxCustomDataController;
      ARecordIndex, AItemIndex: Integer);
    procedure RepartoDibujarCelda(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure RepartoMouseDown(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RepartoDragOver(
      Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure RepartoDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure WMRefrescarCuadrante(var Msg: TMessage);
      message WM_REFRESCAR_CUADRANTE_DISTRIBUCION;
    procedure WMAvisosIniciales(var Msg: TMessage);
      message WM_AVISOS_INICIALES_DISTRIBUCION;
  protected
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    destructor Destroy; override;
    class function Ejecutar(
      AOwner: TComponent;
      const AConfiguracion: TConfiguracionDistribucionTiendas
    ): TResultadoDistribucionTiendas;
    function CloseQuery: Boolean; override;
  end;

implementation

{$R *.dfm}

uses
  System.Math, System.UITypes,
  inLibMensajesVcl, inLibUser,
  inLibInformePropuestasTraspaso,
  inLibMsgDistribucionTiendas,
  inMtoModalRepartoAutomatico,
  inMtoModalPrioridadesDistribucion,
  inMtoModalImpPropuestasTraspaso,
  inMtoModalFotoArticulo,
  UniDataDistribucionTiendasRepositorio;

const
  TAG_COLUMNA_FIJA = -1;
  TAG_COLUMNA_TOTAL = -2;
  FILA_POR_REPARTIR = 0;
  // Almacén, nombre y prioridad; después van las tallas.
  COLUMNAS_FIJAS_REPARTO = 3;
  COL_REPARTO_PRIORIDAD = 2;
  COL_GRUPO_REPARTIDAS = 4;
  COL_GRUPO_POR_REPARTIR = 5;
  FORMATO_UNIDADES = '0.###';
  PERFIL_DISTRIBUCION = 'frmModalDistribucionTiendas';
  PERFIL_MINIMO_ORIGEN = 'MinimoEnOrigen';
  PERFIL_MAXIMO_DESTINO = 'MaximoPorDestino';
  PERFIL_STOCK_OBJETIVO = 'StockObjetivo';
  PERFIL_CRITERIO = 'Criterio';
  MARGEN_TEXTO_CELDA = 4;

function ValorNumerico(const AValor: Variant): Double;
begin
  if VarIsNull(AValor) or VarIsEmpty(AValor) then
    Result := 0
  else
    Result := AValor;
end;

function TextoUnidades(AUnidades: Double): string;
begin
  Result := FormatFloat(FORMATO_UNIDADES, AUnidades);
end;

// ===========================================================================
//   Ciclo de vida
// ===========================================================================

class function TfrmModalDistribucionTiendas.Ejecutar(
  AOwner: TComponent;
  const AConfiguracion: TConfiguracionDistribucionTiendas
): TResultadoDistribucionTiendas;
var
  oFormulario: TfrmModalDistribucionTiendas;
begin
  AConfiguracion.Servicios.Validar;
  Result := Default(TResultadoDistribucionTiendas);
  oFormulario := TfrmModalDistribucionTiendas.Create(AOwner);
  // El ancestro se libera solo al cerrar (caFree); aquí se libera a mano
  // para poder leer antes el resultado.
  oFormulario.OnClose := nil;
  try
    oFormulario.FConfiguracion := AConfiguracion;
    oFormulario.LeerPreferencias;
    oFormulario.CargarDocumento;
    if Length(oFormulario.FGrupos) = 0 then
      ShowMessage_fza(SInfoDistribucionSinLineas)
    else
      oFormulario.ShowModal;
    Result.HuboCambios := oFormulario.FHuboCambios;
  finally
    FreeAndNil(oFormulario);
  end;
end;

destructor TfrmModalDistribucionTiendas.Destroy;
begin
  FreeAndNil(FModelo);
  FConfiguracion.Servicios.Repositorio := nil;
  FConfiguracion.Servicios.Confirmador := nil;
  inherited Destroy;
end;

// Los textos se fijan tras la traducción del formulario base, que si no
// deja el título con el de su ancestro.
procedure TfrmModalDistribucionTiendas.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloDistribucionTiendas;
  btnAceptar.Caption := SCaptionGuardarCerrarDistribucion;
  btnCancelar.Caption := SCaptionCerrarDistribucion;
  lblAviso.Style.Font.Style := [fsBold];
  lblLeyendaReparto.Style.Font.Style := [fsBold];
  lblLeyendaSalida.Style.Font.Style := [fsBold];
  ElegirColores;
  ConfigurarVistas;
  CrearPanelFoto;
end;

// Panel a la derecha de la rejilla de artículos con la foto del
// artículo-color enfocado; al pulsarla (o con Ctrl+F) se abre el visor.
procedure TfrmModalDistribucionTiendas.CrearPanelFoto;
const
  ANCHO_PANEL_FOTO = 240;
var
  oAccion: TAction;
  oAcciones: TActionList;
  oPanelFoto: TPanel;
  oPanelGrupos: TPanel;
begin
  if Assigned(FotosArticulos) then
  begin
    oPanelGrupos := TPanel.Create(Self);
    oPanelGrupos.Parent := tsReparto;
    oPanelGrupos.BevelOuter := bvNone;
    oPanelGrupos.SetBounds(0, 0, cxgrdGrupos.Width, cxgrdGrupos.Height);
    oPanelGrupos.Align := alTop;
    cxgrdGrupos.Parent := oPanelGrupos;
    cxgrdGrupos.Align := alClient;
    splDetalle.Control := oPanelGrupos;
    oPanelFoto := TPanel.Create(Self);
    oPanelFoto.Parent := oPanelGrupos;
    oPanelFoto.BevelOuter := bvNone;
    oPanelFoto.Width := MulDiv(ANCHO_PANEL_FOTO, CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    oPanelFoto.Align := alRight;
    oPanelFoto.AlignWithMargins := True;
    FMiniaturaFoto := TMiniaturaFotoMto.CreateEnPanel(Self, oPanelFoto,
      FotosArticulos, ResolverArtSkuGrupo, AbrirFotoGrupo);
    oAcciones := TActionList.Create(Self);
    oAccion := TAction.Create(Self);
    oAccion.ActionList := oAcciones;
    oAccion.ShortCut := ShortCut(Ord('F'), [ssCtrl]);
    oAccion.OnExecute := AbrirFotoGrupo;
  end;
end;

// La foto del artículo-color: su primer SKU resuelve por prefijos a la
// del color (o a la del artículo si el color no tiene).
procedure TfrmModalDistribucionTiendas.ResolverArtSkuGrupo(
  out ACodArt, ACodSku: string);
var
  aSkus: TArray<string>;
begin
  ACodArt := '';
  ACodSku := '';
  if Length(FGrupos) > 0 then
  begin
    ACodArt := FGrupos[GrupoEnfocado].CodigoArticulo;
    aSkus := SkusDelGrupoEnfocado;
    if Length(aSkus) > 0 then
      ACodSku := aSkus[0];
  end;
end;

procedure TfrmModalDistribucionTiendas.AbrirFotoGrupo(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  ResolverArtSkuGrupo(sArt, sSku);
  if sArt <> '' then
    TfrmModalFotoArticulo.Ejecutar(Self, sArt, sSku);
end;

procedure TfrmModalDistribucionTiendas.DoShow;
begin
  inherited DoShow;
  pcDistribucion.ActivePage := tsReparto;
  if cxgrdReparto.CanFocus then
    cxgrdReparto.SetFocus;
  PostMessage(Handle, WM_AVISOS_INICIALES_DISTRIBUCION, 0, 0);
end;

// En diferido: con la ventana ya pintada debajo de los avisos.
procedure TfrmModalDistribucionTiendas.WMAvisosIniciales(
  var Msg: TMessage);
begin
  if FModelo.UnidadesRecortadasAlCargar > 0 then
    ShowMessage_fza(Format(SAvisoDistribucionRecortada, [
      TextoUnidades(FModelo.UnidadesRecortadasAlCargar)]));
  if not FModelo.HayDestinos and
     (MessageDlg_fza(SPreguntaDistribucionSinDestinos, mtConfirmation,
        [mbYes, mbNo], 0) = mrYes) then
    EditarPrioridades;
end;

// El reparto y lo que sale del origen necesitan contraste con el fondo
// del skin: tonos claros sobre fondo oscuro y oscuros sobre fondo claro.
procedure TfrmModalDistribucionTiendas.ElegirColores;
var
  iFondo: Integer;
  bFondoOscuro: Boolean;
begin
  iFondo := ColorToRGB(
    RootLookAndFeel.Painter.DefaultContentColor);
  bFondoOscuro :=
    (GetRValue(iFondo) * 299 + GetGValue(iFondo) * 587 +
     GetBValue(iFondo) * 114) < 128000;
  if bFondoOscuro then
  begin
    FColorReparto := TColor($0080FF80);
    FColorSalida := TColor($0060B0FF);
  end
  else
  begin
    FColorReparto := TColor($00007A00);
    FColorSalida := TColor($000050C8);
  end;
  lblLeyendaReparto.Style.TextColor := FColorReparto;
  lblLeyendaSalida.Style.TextColor := FColorSalida;
end;

procedure TfrmModalDistribucionTiendas.ConfigurarVistas;
begin
  CrearColumnasGrupos;
  CrearColumnasPropuestas;
  tvGrupos.OnFocusedRecordChanged := GruposFocoCambiado;
  tvReparto.OnEditing := RepartoEditando;
  tvReparto.OnCustomDrawCell := RepartoDibujarCelda;
  tvReparto.OnMouseDown := RepartoMouseDown;
  tvReparto.OnDragOver := RepartoDragOver;
  tvReparto.OnDragDrop := RepartoDragDrop;
  tvReparto.DataController.OnRecordChanged := RepartoRegistroCambiado;
end;

function TfrmModalDistribucionTiendas.CrearColumna(
  AVista: TcxGridTableView;
  const ATitulo: string;
  AAncho: Integer;
  ANumerica: Boolean): TcxGridColumn;
begin
  Result := AVista.CreateColumn;
  Result.Caption := ATitulo;
  Result.Width := ScaleValue(AAncho);
  Result.Options.Editing := False;
  Result.Options.Sorting := False;
  Result.Options.Filtering := False;
  Result.Tag := TAG_COLUMNA_FIJA;
  if ANumerica then
  begin
    Result.DataBinding.ValueTypeClass := TcxFloatValueType;
    Result.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(Result.Properties).DisplayFormat :=
      '#,##0.###;-#,##0.###;#';
    TcxCurrencyEditProperties(Result.Properties).EditFormat :=
      FORMATO_UNIDADES;
    TcxCurrencyEditProperties(Result.Properties).DecimalPlaces := 3;
    TcxCurrencyEditProperties(Result.Properties).Alignment.Horz := taCenter;
    Result.HeaderAlignmentHorz := taCenter;
  end
  else
    Result.DataBinding.ValueTypeClass := TcxStringValueType;
end;

procedure TfrmModalDistribucionTiendas.CrearColumnasGrupos;
begin
  tvGrupos.ClearItems;
  CrearColumna(tvGrupos, SCaptionColArticuloDistribucion, 130, False);
  CrearColumna(tvGrupos, SCaptionColDescripcionDistribucion, 380, False);
  CrearColumna(tvGrupos, SCaptionColColorDistribucion, 170, False);
  CrearColumna(tvGrupos, SCaptionColUnidadesDistribucion, 110, True);
  CrearColumna(tvGrupos, SCaptionColRepartidasDistribucion, 110, True);
  CrearColumna(tvGrupos, SCaptionColPorRepartirDistribucion, 110, True);
end;

procedure TfrmModalDistribucionTiendas.CrearColumnasPropuestas;
begin
  tvPropuestas.ClearItems;
  CrearColumna(tvPropuestas, SCaptionColNumeroPropuesta, 100, False);
  CrearColumna(tvPropuestas, SCaptionColOrigenPropuesta, 240, False);
  CrearColumna(tvPropuestas, SCaptionColDestinoPropuesta, 240, False);
  CrearColumna(tvPropuestas, SCaptionColUnidadesPropuesta, 100, True);
  CrearColumna(tvPropuestas, SCaptionColEstadoPropuesta, 130, False);
  CrearColumna(tvPropuestas, SCaptionColTraspasoPropuesta, 190, False);
  CrearColumna(tvPropuestas, SCaptionColMotivoPropuesta, 260, False);
end;

// ===========================================================================
//   Preferencias del usuario
// ===========================================================================

procedure TfrmModalDistribucionTiendas.LeerPreferencias;
var
  Perfil: TProfileDicc;
begin
  Perfil := nil;
  FParametrosAutomaticos := Default(TParametrosRepartoAutomatico);
  try
    GetFormUserProfile(
      Perfil, PERFIL_DISTRIBUCION, IdentidadSesion.Usuario,
      IdentidadSesion.Grupo, PerfilesLectura);
    FActualizando := True;
    try
      edtMinimoOrigen.Value := StrToFloatDef(
        GetPerfilValueDef(Perfil, PERFIL_MINIMO_ORIGEN, '0'), 0,
        TFormatSettings.Invariant);
    finally
      FActualizando := False;
    end;
    FParametrosAutomaticos.MaximoPorDestino := StrToFloatDef(
      GetPerfilValueDef(Perfil, PERFIL_MAXIMO_DESTINO, '0'), 0,
      TFormatSettings.Invariant);
    FParametrosAutomaticos.StockObjetivo := StrToFloatDef(
      GetPerfilValueDef(Perfil, PERFIL_STOCK_OBJETIVO, '0'), 0,
      TFormatSettings.Invariant);
    if GetPerfilValueDef(Perfil, PERFIL_CRITERIO, '0') = '1' then
      FParametrosAutomaticos.Criterio := craMenorStock;
  finally
    FreeAndNil(Perfil);
  end;
end;

procedure TfrmModalDistribucionTiendas.GuardarPreferencias;

  procedure Grabar(const AClave: string; AValor: Double);
  begin
    PerfilesEscritura.GrabarPerfil(
      IdentidadSesion.Usuario, PERFIL_DISTRIBUCION, AClave,
      FloatToStr(AValor, TFormatSettings.Invariant));
  end;

begin
  if Assigned(PerfilesEscritura) then
  begin
    Grabar(PERFIL_MINIMO_ORIGEN, ValorNumerico(edtMinimoOrigen.Value));
    Grabar(PERFIL_MAXIMO_DESTINO,
      FParametrosAutomaticos.MaximoPorDestino);
    Grabar(PERFIL_STOCK_OBJETIVO, FParametrosAutomaticos.StockObjetivo);
    Grabar(PERFIL_CRITERIO, Ord(FParametrosAutomaticos.Criterio));
  end;
end;

// ===========================================================================
//   Carga
// ===========================================================================

procedure TfrmModalDistribucionTiendas.CargarDocumento;
begin
  FDocumento := FConfiguracion.Servicios.Repositorio.CargarDocumento(
    FConfiguracion.IdDocumento);
  FreeAndNil(FModelo);
  FModelo := TDistribucionTiendas.Create(FDocumento);
  Caption := Format(
    STituloDistribucionTiendasDocumento, [FDocumento.Titulo]);
  CargarComboOrigen;
  AplicarOpcionesOrigen;
  CargarGrupos;
  CargarPropuestas;
end;

procedure TfrmModalDistribucionTiendas.CargarComboOrigen;
var
  Origenes: TAlmacenesDistribucion;
  i: Integer;
begin
  // Con un solo origen se enseña ese almacén: "automático" solo tiene
  // sentido cuando hay varios entre los que elegir.
  Origenes := FModelo.AlmacenesOrigen;
  FOrigenesCombo := nil;
  FActualizando := True;
  cbbOrigen.Properties.Items.BeginUpdate;
  try
    cbbOrigen.Properties.Items.Clear;
    if Length(Origenes) <> 1 then
    begin
      FOrigenesCombo := FOrigenesCombo + [''];
      cbbOrigen.Properties.Items.Add(SCaptionOrigenAutomaticoDistribucion);
    end;
    for i := 0 to High(Origenes) do
    begin
      FOrigenesCombo := FOrigenesCombo + [Origenes[i].Codigo];
      cbbOrigen.Properties.Items.Add(TextoAlmacenPropuesta(
        Origenes[i].Codigo, Origenes[i].Nombre));
    end;
    cbbOrigen.ItemIndex := 0;
  finally
    cbbOrigen.Properties.Items.EndUpdate;
    FActualizando := False;
  end;
end;

procedure TfrmModalDistribucionTiendas.CargarGrupos;
var
  i: Integer;
  iEnfocado: Integer;
begin
  iEnfocado := GrupoEnfocado;
  FGrupos := FModelo.Grupos;
  FActualizando := True;
  tvGrupos.BeginUpdate;
  try
    tvGrupos.DataController.RecordCount := Length(FGrupos);
    for i := 0 to High(FGrupos) do
    begin
      tvGrupos.DataController.Values[i, 0] := FGrupos[i].CodigoArticulo;
      tvGrupos.DataController.Values[i, 1] :=
        FGrupos[i].DescripcionArticulo;
      tvGrupos.DataController.Values[i, 2] := FGrupos[i].Color;
      tvGrupos.DataController.Values[i, 3] := FGrupos[i].UnidadesDocumento;
    end;
  finally
    tvGrupos.EndUpdate;
    FActualizando := False;
  end;
  ActualizarTotalesGrupos;
  if Length(FGrupos) > 0 then
  begin
    tvGrupos.Controller.FocusedRecordIndex :=
      EnsureRange(iEnfocado, 0, High(FGrupos));
    ReconstruirCuadrante;
  end;
  // El mismo índice puede ser ahora otro grupo sin cambio de foco.
  if Assigned(FMiniaturaFoto) then
    FMiniaturaFoto.Actualizar;
end;

procedure TfrmModalDistribucionTiendas.ActualizarTotalesGrupos;
var
  i: Integer;
begin
  FGrupos := FModelo.Grupos;
  FActualizando := True;
  tvGrupos.BeginUpdate;
  try
    for i := 0 to High(FGrupos) do
    begin
      if i < tvGrupos.DataController.RecordCount then
      begin
        tvGrupos.DataController.Values[i, COL_GRUPO_REPARTIDAS] :=
          FGrupos[i].UnidadesRepartidas;
        tvGrupos.DataController.Values[i, COL_GRUPO_POR_REPARTIR] :=
          FGrupos[i].UnidadesPorRepartir;
      end;
    end;
  finally
    tvGrupos.EndUpdate;
    FActualizando := False;
  end;
end;

procedure TfrmModalDistribucionTiendas.CargarPropuestas;
var
  i: Integer;
begin
  FPropuestas :=
    FConfiguracion.Servicios.Repositorio.ListarPropuestasDocumento(
      FConfiguracion.IdDocumento);
  tvPropuestas.BeginUpdate;
  try
    tvPropuestas.DataController.RecordCount := Length(FPropuestas);
    for i := 0 to High(FPropuestas) do
    begin
      tvPropuestas.DataController.Values[i, 0] :=
        IntToStr(FPropuestas[i].IdPropuesta);
      tvPropuestas.DataController.Values[i, 1] := TextoAlmacenPropuesta(
        FPropuestas[i].AlmacenOrigen,
        FPropuestas[i].NombreAlmacenOrigen);
      tvPropuestas.DataController.Values[i, 2] := TextoAlmacenPropuesta(
        FPropuestas[i].AlmacenDestino,
        FPropuestas[i].NombreAlmacenDestino);
      tvPropuestas.DataController.Values[i, 3] :=
        FPropuestas[i].TotalUnidades;
      tvPropuestas.DataController.Values[i, 4] :=
        TextoEstadoPropuestaTraspaso(FPropuestas[i]);
      tvPropuestas.DataController.Values[i, 5] :=
        TextoTraspasoPropuesta(FPropuestas[i]);
      tvPropuestas.DataController.Values[i, 6] :=
        FPropuestas[i].MotivoRechazo;
    end;
  finally
    tvPropuestas.EndUpdate;
  end;
end;

function TfrmModalDistribucionTiendas.GrupoEnfocado: Integer;
begin
  Result := tvGrupos.Controller.FocusedRecordIndex;
  if (Result < 0) or (Result > High(FGrupos)) then
    Result := 0;
end;

function TfrmModalDistribucionTiendas.PropuestaEnfocada(
  out APropuesta: TPropuestaTraspaso): Boolean;
var
  iRegistro: Integer;
begin
  APropuesta := Default(TPropuestaTraspaso);
  iRegistro := -1;
  if tvPropuestas.Controller.FocusedRecord <> nil then
    iRegistro := tvPropuestas.Controller.FocusedRecord.RecordIndex;
  Result := (iRegistro >= 0) and (iRegistro <= High(FPropuestas));
  if Result then
    APropuesta := FPropuestas[iRegistro]
  else
    ShowMessage_fza(SInfoSeleccionarPropuesta);
end;

// ===========================================================================
//   Cuadrante almacenes x tallas
// ===========================================================================

procedure TfrmModalDistribucionTiendas.GruposFocoCambiado(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  if not FActualizando and (AFocusedRecord <> nil) then
  begin
    MostrarAviso('');
    RefrescarStocks(SkusDelGrupoEnfocado);
    ReconstruirCuadrante;
    if Assigned(FMiniaturaFoto) then
      FMiniaturaFoto.Actualizar;
  end;
end;

function TfrmModalDistribucionTiendas.SkusDelGrupoEnfocado:
  TArray<string>;
var
  Columnas: TColumnasDistribucion;
  i: Integer;
begin
  Result := nil;
  if Length(FGrupos) > 0 then
  begin
    Columnas := FModelo.Columnas(
      FGrupos[GrupoEnfocado].CodigoArticulo, FGrupos[GrupoEnfocado].Color);
    SetLength(Result, Length(Columnas));
    for i := 0 to High(Columnas) do
      Result[i] := Columnas[i].CodigoSku;
  end;
end;

// Las existencias se releen al cambiar de artículo-color (y antes del
// reparto automático): mientras se reparte, las tiendas siguen vendiendo.
// Sin SKU se releen las de todo el documento.
procedure TfrmModalDistribucionTiendas.RefrescarStocks(
  const ASkus: TArray<string>);
var
  dRetiradas: Double;
begin
  dRetiradas := FModelo.RefrescarStocks(
    ASkus,
    FConfiguracion.Servicios.Repositorio.LeerStocks(
      FConfiguracion.IdDocumento, ASkus));
  if dRetiradas > 0 then
    MostrarAviso(Format(SAvisoDistribucionStockRefrescado, [
      TextoUnidades(dRetiradas)]));
end;

// Las columnas son las tallas del artículo-color enfocado: se rehacen al
// cambiar de fila en el maestro. La primera fila es lo que al documento le
// queda por repartir; las demás, un almacén cada una.
procedure TfrmModalDistribucionTiendas.ReconstruirCuadrante;
var
  Almacenes: TAlmacenesDistribucion;
  Columna: TcxGridColumn;
  i: Integer;
  sTitulo: string;
begin
  if Length(FGrupos) > 0 then
  begin
    FColumnas := FModelo.Columnas(
      FGrupos[GrupoEnfocado].CodigoArticulo, FGrupos[GrupoEnfocado].Color);
    Almacenes := AlmacenesDelGrupo;
    FActualizando := True;
    tvReparto.BeginUpdate;
    try
      tvReparto.DataController.RecordCount := 0;
      tvReparto.ClearItems;
      CrearColumna(tvReparto, SCaptionColAlmacenDistribucion, 90, False);
      CrearColumna(
        tvReparto, SCaptionColNombreAlmacenDistribucion, 220, False);
      CrearColumna(
        tvReparto, SCaptionColPrioridadDistribucion, 84, False);
      for i := 0 to High(FColumnas) do
      begin
        sTitulo := FColumnas[i].Talla;
        if Trim(sTitulo) = '' then
          sTitulo := SCaptionColSinTallaDistribucion;
        Columna := CrearColumna(tvReparto, sTitulo, 92, True);
        Columna.Options.Editing := True;
        Columna.Tag := i;
      end;
      CrearColumna(tvReparto, SCaptionColTotalDistribucion, 100, True).Tag :=
        TAG_COLUMNA_TOTAL;
      for i := 0 to COLUMNAS_FIJAS_REPARTO - 1 do
        tvReparto.Columns[i].Options.Focusing := False;
      tvReparto.Columns[COL_REPARTO_PRIORIDAD].HeaderAlignmentHorz :=
        taCenter;
      tvReparto.Columns[COL_REPARTO_PRIORIDAD].PropertiesClass :=
        TcxTextEditProperties;
      TcxTextEditProperties(
        tvReparto.Columns[COL_REPARTO_PRIORIDAD].Properties).Alignment.
        Horz := taCenter;
      SetLength(FAlmacenesFila, Length(Almacenes) + 1);
      FAlmacenesFila[FILA_POR_REPARTIR] := '';
      tvReparto.DataController.RecordCount := Length(FAlmacenesFila);
      tvReparto.DataController.Values[FILA_POR_REPARTIR, 1] :=
        STextoFilaPorRepartirDistribucion;
      for i := 0 to High(Almacenes) do
      begin
        FAlmacenesFila[i + 1] := Almacenes[i].Codigo;
        tvReparto.DataController.Values[i + 1, 0] := Almacenes[i].Codigo;
        tvReparto.DataController.Values[i + 1, 1] := Almacenes[i].Nombre;
        if EsOrigenDelGrupo(Almacenes[i].Codigo) then
          tvReparto.DataController.Values[i + 1, COL_REPARTO_PRIORIDAD] :=
            STextoOrigenCuadranteDistribucion
        else if FModelo.RecibeTraspasos(Almacenes[i].Codigo) then
          tvReparto.DataController.Values[i + 1, COL_REPARTO_PRIORIDAD] :=
            IntToStr(Almacenes[i].Prioridad);
      end;
    finally
      tvReparto.EndUpdate;
      FActualizando := False;
    end;
    VolcarCuadrante;
  end;
end;

// Origen de alguna talla del artículo-color enfocado (FColumnas).
function TfrmModalDistribucionTiendas.EsOrigenDelGrupo(
  const AAlmacen: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(FColumnas) do
  begin
    if FModelo.EsOrigen(AAlmacen, FColumnas[i].CodigoSku) then
      Result := True;
  end;
end;

// Las filas del cuadrante con el origen arriba, justo debajo de lo que
// queda por repartir: de ahí sale la mercancía.
function TfrmModalDistribucionTiendas.AlmacenesDelGrupo:
  TAlmacenesDistribucion;
var
  Todos: TAlmacenesDistribucion;
  i, iSiguiente: Integer;
  bOrigenes: Boolean;
begin
  Todos := FModelo.AlmacenesDelCuadrante;
  SetLength(Result, Length(Todos));
  iSiguiente := 0;
  for bOrigenes := True downto False do
  begin
    for i := 0 to High(Todos) do
    begin
      if EsOrigenDelGrupo(Todos[i].Codigo) = bOrigenes then
      begin
        Result[iSiguiente] := Todos[i];
        Inc(iSiguiente);
      end;
    end;
  end;
end;

// Valor de la celda: lo que recibe una tienda (positivo), lo que sale de
// un origen (negativo) o lo que queda por repartir en la primera fila.
function TfrmModalDistribucionTiendas.ValorCelda(
  const AAlmacen, ASku: string): Variant;
var
  dValor: Double;
begin
  if AAlmacen = '' then
    dValor := FModelo.UnidadesPorRepartir(ASku)
  else if FModelo.EsOrigen(AAlmacen, ASku) then
    dValor := FModelo.UnidadesEnAlmacen(AAlmacen, ASku) -
      FModelo.UnidadesDocumento(AAlmacen, ASku)
  else
    dValor := FModelo.UnidadesEnAlmacen(AAlmacen, ASku);
  if SameValue(dValor, 0, TOLERANCIA_UNIDADES_DISTRIBUCION) then
    Result := Null
  else
    Result := dValor;
end;

procedure TfrmModalDistribucionTiendas.VolcarCuadrante;
var
  iFila, iColumna: Integer;
  dTotal: Double;
  vValor: Variant;
begin
  FActualizando := True;
  tvReparto.BeginUpdate;
  try
    for iFila := 0 to High(FAlmacenesFila) do
    begin
      dTotal := 0;
      for iColumna := 0 to High(FColumnas) do
      begin
        vValor := ValorCelda(
          FAlmacenesFila[iFila], FColumnas[iColumna].CodigoSku);
        tvReparto.DataController.Values[
          iFila, iColumna + COLUMNAS_FIJAS_REPARTO] := vValor;
        dTotal := dTotal + ValorNumerico(vValor);
      end;
      if SameValue(dTotal, 0, TOLERANCIA_UNIDADES_DISTRIBUCION) then
        tvReparto.DataController.Values[
          iFila, Length(FColumnas) + COLUMNAS_FIJAS_REPARTO] := Null
      else
        tvReparto.DataController.Values[
          iFila, Length(FColumnas) + COLUMNAS_FIJAS_REPARTO] := dTotal;
    end;
  finally
    tvReparto.EndUpdate;
    FActualizando := False;
  end;
  ActualizarTotalesGrupos;
  btnGuardar.Enabled := FModelo.Modificado;
end;

function TfrmModalDistribucionTiendas.SkuDeColumna(
  AItem: TcxCustomGridTableItem): string;
begin
  Result := '';
  if (AItem <> nil) and (AItem.Tag >= 0) and
     (AItem.Tag <= High(FColumnas)) then
    Result := FColumnas[AItem.Tag].CodigoSku;
end;

// Se teclea en las tiendas con número de prioridad; en un almacén que lo
// ha perdido, solo para rebajar lo que ya llevaba.
function TfrmModalDistribucionTiendas.CeldaEditable(
  const AAlmacen, ASku: string): Boolean;
begin
  Result := not FModelo.EsOrigen(AAlmacen, ASku) and
    (FModelo.RecibeTraspasos(AAlmacen) or
     (FModelo.UnidadesEnAlmacen(AAlmacen, ASku) > 0));
end;

// Solo se teclea en las tiendas: el origen enseña lo que le sale y la
// primera fila, lo que queda por repartir.
procedure TfrmModalDistribucionTiendas.RepartoEditando(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  iRegistro: Integer;
  sSku: string;
begin
  AAllow := False;
  sSku := SkuDeColumna(AItem);
  if (sSku <> '') and (Sender.Controller.FocusedRecord <> nil) then
  begin
    iRegistro := Sender.Controller.FocusedRecord.RecordIndex;
    AAllow := (iRegistro > FILA_POR_REPARTIR) and
      (iRegistro <= High(FAlmacenesFila)) and
      CeldaEditable(FAlmacenesFila[iRegistro], sSku);
    if not AAllow and (iRegistro > FILA_POR_REPARTIR) and
       (iRegistro <= High(FAlmacenesFila)) then
    begin
      if FModelo.EsOrigen(FAlmacenesFila[iRegistro], sSku) then
        MostrarAviso(SAvisoDistribucionEsOrigen)
      else
        MostrarAviso(Format(SAvisoDistribucionNoRecibeTraspasos, [
          FAlmacenesFila[iRegistro]]));
    end;
  end;
end;

// En modo no enlazado el valor tecleado llega aquí en cuanto se sale de
// la celda. El resto del cuadrante (origen, totales) se refresca en
// diferido para no escribir en la rejilla en mitad de su notificación.
procedure TfrmModalDistribucionTiendas.RepartoRegistroCambiado(
  ADataController: TcxCustomDataController;
  ARecordIndex, AItemIndex: Integer);
var
  sSku: string;
  Resultado: TResultadoAsignacion;
begin
  if not FActualizando and
     (ARecordIndex > FILA_POR_REPARTIR) and
     (ARecordIndex <= High(FAlmacenesFila)) and
     (AItemIndex >= 0) and (AItemIndex < tvReparto.ItemCount) then
  begin
    sSku := SkuDeColumna(tvReparto.Items[AItemIndex]);
    if sSku <> '' then
    begin
      Resultado := FModelo.FijarUnidadesDestino(
        FAlmacenesFila[ARecordIndex], sSku,
        ValorNumerico(ADataController.Values[ARecordIndex, AItemIndex]));
      MostrarAvisoAsignacion(
        FAlmacenesFila[ARecordIndex], sSku, Resultado);
      PostMessage(Handle, WM_REFRESCAR_CUADRANTE_DISTRIBUCION, 0, 0);
    end;
  end;
end;

procedure TfrmModalDistribucionTiendas.WMRefrescarCuadrante(
  var Msg: TMessage);
begin
  VolcarCuadrante;
end;

// Existencias en el color normal del skin y, si lo hay, el reparto en el
// suyo: lo que recibe la tienda con "+" y lo que sale del origen con "-".
procedure TfrmModalDistribucionTiendas.RepartoDibujarCelda(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  iRegistro, iColumna: Integer;
  iAlineaExistencias, iAlineaReparto: Integer;
  dExistencias, dReparto: Double;
  bExistencias, bReparto: Boolean;
  rTexto: TRect;
  sReparto: string;
begin
  ADone := False;
  iRegistro := AViewInfo.GridRecord.RecordIndex;
  if (AViewInfo.Item.Tag <> TAG_COLUMNA_FIJA) and
     (iRegistro >= 0) and (iRegistro <= High(FAlmacenesFila)) then
  begin
    dReparto := ValorNumerico(AViewInfo.GridRecord.Values[
      AViewInfo.Item.Index]);
    dExistencias := 0;
    if iRegistro > FILA_POR_REPARTIR then
    begin
      if AViewInfo.Item.Tag >= 0 then
        dExistencias := FModelo.Stock(
          FAlmacenesFila[iRegistro], SkuDeColumna(AViewInfo.Item))
      else
        for iColumna := 0 to High(FColumnas) do
          dExistencias := dExistencias + FModelo.Stock(
            FAlmacenesFila[iRegistro], FColumnas[iColumna].CodigoSku);
    end;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AViewInfo.Params.Color;
    ACanvas.FillRect(AViewInfo.Bounds);
    rTexto := AViewInfo.Bounds;
    InflateRect(rTexto, -ScaleValue(MARGEN_TEXTO_CELDA), 0);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    ACanvas.Font.Color := AViewInfo.Params.TextColor;
    // Con las dos cifras, existencias a la izquierda y reparto a la
    // derecha; con una sola, centrada.
    bExistencias :=
      not SameValue(dExistencias, 0, TOLERANCIA_UNIDADES_DISTRIBUCION);
    bReparto := not SameValue(dReparto, 0, TOLERANCIA_UNIDADES_DISTRIBUCION);
    if bExistencias and bReparto then
    begin
      iAlineaExistencias := cxAlignLeft;
      iAlineaReparto := cxAlignRight;
    end
    else
    begin
      iAlineaExistencias := cxAlignHCenter;
      iAlineaReparto := cxAlignHCenter;
    end;
    if bExistencias then
      ACanvas.DrawTexT(TextoUnidades(dExistencias), rTexto,
        iAlineaExistencias or cxAlignVCenter or cxSingleLine);
    if bReparto then
    begin
      sReparto := TextoUnidades(dReparto);
      if (dReparto > 0) and (iRegistro > FILA_POR_REPARTIR) then
        sReparto := '+' + sReparto;
      ACanvas.Font.Style := [fsBold];
      if not AViewInfo.Selected then
      begin
        if dReparto < 0 then
          ACanvas.Font.Color := FColorSalida
        else
          ACanvas.Font.Color := FColorReparto;
      end;
      ACanvas.DrawTexT(sReparto, rTexto,
        iAlineaReparto or cxAlignVCenter or cxSingleLine);
    end;
    ACanvas.Brush.Style := bsSolid;
    ADone := True;
  end;
end;

// ===========================================================================
//   Arrastrar y soltar con Mayúsculas
// ===========================================================================

function TfrmModalDistribucionTiendas.CeldaDeHit(
  X, Y: Integer; out AAlmacen, ASku: string): Boolean;
var
  oHit: TcxCustomGridHitTest;
  iRegistro: Integer;
begin
  AAlmacen := '';
  ASku := '';
  Result := False;
  oHit := tvReparto.GetHitTest(X, Y);
  if oHit is TcxGridRecordCellHitTest then
  begin
    iRegistro :=
      TcxGridRecordCellHitTest(oHit).GridRecord.RecordIndex;
    if (iRegistro > FILA_POR_REPARTIR) and
       (iRegistro <= High(FAlmacenesFila)) then
    begin
      AAlmacen := FAlmacenesFila[iRegistro];
      ASku := SkuDeColumna(TcxGridRecordCellHitTest(oHit).Item);
      Result := True;
    end;
  end;
end;

procedure TfrmModalDistribucionTiendas.RepartoMouseDown(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  sAlmacen, sSku: string;
begin
  FArrastre := Default(TArrastreDistribucion);
  if (Button = mbLeft) and (ssShift in Shift) and
     CeldaDeHit(X, Y, sAlmacen, sSku) and (sSku <> '') then
  begin
    if FModelo.UnidadesMovibles(sAlmacen, sSku) > 0 then
    begin
      FArrastre.Activo := True;
      FArrastre.Almacen := sAlmacen;
      FArrastre.Sku := sSku;
      tvReparto.Site.BeginDrag(False);
    end
    else
      MostrarAviso(SAvisoDistribucionNadaQueArrastrar);
  end;
end;

// Vale cualquier celda de la fila de destino: la talla es la de origen.
procedure TfrmModalDistribucionTiendas.RepartoDragOver(
  Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var
  sAlmacen, sSku: string;
begin
  Accept := FArrastre.Activo and CeldaDeHit(X, Y, sAlmacen, sSku) and
    not SameText(sAlmacen, FArrastre.Almacen) and
    (FModelo.EsOrigen(sAlmacen, FArrastre.Sku) or
     FModelo.RecibeTraspasos(sAlmacen));
end;

// Una unidad por arrastre; con Control, todo lo que se pueda mover.
procedure TfrmModalDistribucionTiendas.RepartoDragDrop(
  Sender, Source: TObject; X, Y: Integer);
var
  sAlmacen, sSku: string;
  dCantidad, dMovido: Double;
begin
  if FArrastre.Activo and CeldaDeHit(X, Y, sAlmacen, sSku) then
  begin
    dCantidad := 1;
    if GetKeyState(VK_CONTROL) < 0 then
      dCantidad := FModelo.UnidadesMovibles(
        FArrastre.Almacen, FArrastre.Sku);
    dMovido := FModelo.MoverUnidades(
      FArrastre.Almacen, sAlmacen, FArrastre.Sku, dCantidad);
    if dMovido > 0 then
      MostrarAviso(Format(SInfoDistribucionArrastrado, [
        TextoUnidades(dMovido), FArrastre.Almacen, sAlmacen]))
    else
      MostrarAviso(SAvisoDistribucionArrastreNoValido);
    VolcarCuadrante;
  end;
  FArrastre := Default(TArrastreDistribucion);
end;

// ===========================================================================
//   Opciones de origen y reparto automático
// ===========================================================================

procedure TfrmModalDistribucionTiendas.MostrarAviso(const ATexto: string);
begin
  lblAviso.Caption := ATexto;
end;

procedure TfrmModalDistribucionTiendas.MostrarAvisoAsignacion(
  const AAlmacen, ASku: string;
  const AResultado: TResultadoAsignacion);
begin
  case AResultado.Motivo of
    mapSinUnidades:
      MostrarAviso(Format(SAvisoDistribucionSinUnidades, [
        TextoUnidades(AResultado.CantidadAplicada)]));
    mapSinExistencias:
      MostrarAviso(Format(SAvisoDistribucionSinExistencias, [
        DetalleExistenciasOrigen(ASku),
        TextoUnidades(FModelo.Opciones.MinimoEnOrigen),
        TextoUnidades(AResultado.CantidadAplicada)]));
    mapSueloConfirmado:
      MostrarAviso(Format(SAvisoDistribucionSueloConfirmado, [
        TextoUnidades(FModelo.UnidadesConfirmadas(AAlmacen, ASku))]));
    mapEsOrigen:
      MostrarAviso(SAvisoDistribucionEsOrigen);
    mapNoRecibeTraspasos:
      MostrarAviso(Format(SAvisoDistribucionNoRecibeTraspasos, [
        AAlmacen]));
  else
    MostrarAviso('');
  end;
end;

// Por qué no se puede repartir más: lo que tiene cada origen de esa talla
// y lo que ya sale de él.
function TfrmModalDistribucionTiendas.DetalleExistenciasOrigen(
  const ASku: string): string;
var
  Origenes: TAlmacenesDistribucion;
  i: Integer;
  dExistencias: Double;
begin
  Result := '';
  Origenes := FModelo.AlmacenesOrigen;
  for i := 0 to High(Origenes) do
  begin
    if FModelo.EsOrigen(Origenes[i].Codigo, ASku) then
    begin
      dExistencias := FModelo.Stock(Origenes[i].Codigo, ASku);
      if Result <> '' then
        Result := Result + '; ';
      Result := Result + Format(SFormatoExistenciasOrigenDistribucion, [
        Origenes[i].Codigo, TextoUnidades(dExistencias),
        TextoUnidades(dExistencias -
          FModelo.StockProyectado(Origenes[i].Codigo, ASku))]);
    end;
  end;
end;

procedure TfrmModalDistribucionTiendas.AplicarOpcionesOrigen;
var
  Opciones: TOpcionesOrigenDistribucion;
begin
  if Assigned(FModelo) then
  begin
    Opciones := Default(TOpcionesOrigenDistribucion);
    if (cbbOrigen.ItemIndex >= 0) and
       (cbbOrigen.ItemIndex <= High(FOrigenesCombo)) then
      Opciones.AlmacenFijado := FOrigenesCombo[cbbOrigen.ItemIndex];
    Opciones.MinimoEnOrigen :=
      Max(ValorNumerico(edtMinimoOrigen.Value), 0);
    FModelo.Opciones := Opciones;
  end;
end;

procedure TfrmModalDistribucionTiendas.cbbOrigenPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if not FActualizando then
    AplicarOpcionesOrigen;
end;

procedure TfrmModalDistribucionTiendas.edtMinimoOrigenPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if not FActualizando then
    AplicarOpcionesOrigen;
end;

// El origen fijado en el combo; en automático, todos los del documento.
function TfrmModalDistribucionTiendas.OrigenesDelReparto: TArray<string>;
var
  Origenes: TAlmacenesDistribucion;
  i: Integer;
begin
  AplicarOpcionesOrigen;
  if Trim(FModelo.Opciones.AlmacenFijado) <> '' then
    Result := [FModelo.Opciones.AlmacenFijado]
  else
  begin
    Origenes := FModelo.AlmacenesOrigen;
    SetLength(Result, Length(Origenes));
    for i := 0 to High(Origenes) do
      Result[i] := Origenes[i].Codigo;
  end;
end;

procedure TfrmModalDistribucionTiendas.btnRepartoAutomaticoClick(
  Sender: TObject);
var
  Resultado: TResultadoRepartoAutomatico;
  dRepartido: Double;
begin
  inherited;
  if not FModelo.HayDestinos and
     (MessageDlg_fza(SPreguntaDistribucionSinDestinos, mtConfirmation,
        [mbYes, mbNo], 0) = mrYes) then
    EditarPrioridades;
  Resultado := Default(TResultadoRepartoAutomatico);
  if FModelo.HayDestinos then
    Resultado := TfrmModalRepartoAutomatico.Ejecutar(
      Self, FModelo.AlmacenesQueReciben, OrigenesDelReparto,
      FParametrosAutomaticos);
  if Resultado.Aceptado then
  begin
    FParametrosAutomaticos := Resultado.Parametros;
    AplicarOpcionesOrigen;
    RefrescarStocks(nil);
    dRepartido := FModelo.RepartirAutomaticamente(FParametrosAutomaticos);
    VolcarCuadrante;
    if dRepartido > 0 then
      MostrarAviso(Format(SInfoRepartoAutomaticoHecho, [
        TextoUnidades(dRepartido)]))
    else
      ShowMessage_fza(SInfoRepartoAutomaticoNada);
  end;
end;

// Los números son del almacén, no del documento: se guardan al aceptar.
procedure TfrmModalDistribucionTiendas.EditarPrioridades;
var
  Resultado: TResultadoPrioridadesDistribucion;
  i: Integer;
begin
  if tvReparto.Controller.IsEditing then
    tvReparto.Controller.EditingController.HideEdit(True);
  Resultado := TfrmModalPrioridadesDistribucion.Ejecutar(
    Self, FModelo.AlmacenesDestinoPosible);
  if Resultado.Aceptado then
  begin
    FConfiguracion.Servicios.Repositorio.GuardarPrioridadesAlmacenes(
      Resultado.Prioridades, FConfiguracion.Usuario);
    for i := 0 to High(Resultado.Prioridades) do
      FModelo.FijarPrioridad(
        Resultado.Prioridades[i].CodigoAlmacen,
        Resultado.Prioridades[i].Prioridad);
    ReconstruirCuadrante;
    MostrarAviso('');
  end;
end;

procedure TfrmModalDistribucionTiendas.btnPrioridadesClick(
  Sender: TObject);
begin
  inherited;
  EditarPrioridades;
end;

procedure TfrmModalDistribucionTiendas.btnVaciarClick(Sender: TObject);
begin
  inherited;
  if MessageDlg_fza(SPreguntaVaciarDistribucion, mtConfirmation,
       [mbYes, mbNo], 0) = mrYes then
  begin
    FModelo.QuitarPendientes;
    VolcarCuadrante;
    MostrarAviso('');
  end;
end;

procedure TfrmModalDistribucionTiendas.cxgrdRepartoEnter(Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Sender);
end;

procedure TfrmModalDistribucionTiendas.cxgrdRepartoExit(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
end;

// ===========================================================================
//   Guardar, imprimir y confirmar
// ===========================================================================

function TfrmModalDistribucionTiendas.GuardarCambios: Boolean;
begin
  Result := False;
  if tvReparto.Controller.IsEditing then
    tvReparto.Controller.EditingController.HideEdit(True);
  try
    FConfiguracion.Servicios.Repositorio.GuardarPropuestas(
      FConfiguracion.IdDocumento,
      FDocumento.FirmaResueltas,
      FModelo.Asignaciones,
      FConfiguracion.Usuario);
    FModelo.MarcarGuardado;
    FHuboCambios := True;
    Result := True;
    CargarPropuestas;
    btnGuardar.Enabled := False;
    MostrarAviso(Format(SInfoDistribucionGuardada, [
      Length(PropuestasPendientes)]));
  except
    on E: EDistribucionTiendasDesactualizada do
      ShowMessage_fza(E.Message);
  end;
end;

function TfrmModalDistribucionTiendas.GuardarSiHaceFalta: Boolean;
begin
  if tvReparto.Controller.IsEditing then
    tvReparto.Controller.EditingController.HideEdit(True);
  Result := not FModelo.Modificado or GuardarCambios;
end;

procedure TfrmModalDistribucionTiendas.btnGuardarClick(Sender: TObject);
begin
  inherited;
  GuardarCambios;
end;

function TfrmModalDistribucionTiendas.PropuestasPendientes:
  TPropuestasTraspaso;
var
  i, iPendientes: Integer;
begin
  SetLength(Result, Length(FPropuestas));
  iPendientes := 0;
  for i := 0 to High(FPropuestas) do
  begin
    if FPropuestas[i].EstaPendiente then
    begin
      Result[iPendientes] := FPropuestas[i];
      Inc(iPendientes);
    end;
  end;
  SetLength(Result, iPendientes);
end;

// El repaso es de lo pendiente; si ya no queda nada pendiente se imprime
// todo el historial del documento.
procedure TfrmModalDistribucionTiendas.btnImprimirPropuestasClick(
  Sender: TObject);
var
  Hojas: THojasInformePropuestasTraspaso;
begin
  inherited;
  if GuardarSiHaceFalta then
  begin
    Hojas := ComponerInformePropuestasTraspaso(PropuestasPendientes);
    if Length(Hojas) = 0 then
      Hojas := ComponerInformePropuestasTraspaso(FPropuestas);
    if Length(Hojas) = 0 then
      ShowMessage_fza(SInfoNoHayPropuestasPendientes)
    else
      TfrmPrintPropuestasTraspaso.Mostrar(
        Self, Hojas, FConfiguracion.IdDocumento);
  end;
end;

// Cada propuesta es un traspaso con su propia transacción: si una no se
// puede confirmar (sin existencias, sin caja) las demás siguen adelante.
procedure TfrmModalDistribucionTiendas.ConfirmarPropuestas(
  const APropuestas: TPropuestasTraspaso);
var
  i, iConfirmadas: Integer;
  Resultado: TResultadoConfirmacionPropuesta;
  sIncidencias: string;
begin
  iConfirmadas := 0;
  sIncidencias := '';
  Screen.Cursor := crHourGlass;
  try
    for i := 0 to High(APropuestas) do
    begin
      Resultado := FConfiguracion.Servicios.Confirmador.Confirmar(
        APropuestas[i].IdPropuesta, Now);
      if Resultado.Confirmada then
        Inc(iConfirmadas)
      else
        sIncidencias := sIncidencias + sLineBreak + Format(
          SErrorPropuestaNoConfirmada,
          [APropuestas[i].IdPropuesta, Resultado.Mensaje]);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  if iConfirmadas > 0 then
    FHuboCambios := True;
  CargarDocumento;
  ShowMessage_fza(Format(SInfoPropuestasConfirmadas, [
    iConfirmadas, Length(APropuestas)]) + sIncidencias);
end;

procedure TfrmModalDistribucionTiendas.btnConfirmarPropuestaClick(
  Sender: TObject);
var
  Propuesta: TPropuestaTraspaso;
begin
  inherited;
  if GuardarSiHaceFalta and PropuestaEnfocada(Propuesta) then
  begin
    if not Propuesta.EstaPendiente then
      ShowMessage_fza(Format(
        SInfoPropuestaYaNoPendiente, [Propuesta.IdPropuesta]))
    else if MessageDlg_fza(
      Format(SPreguntaConfirmarPropuesta, [
        Propuesta.IdPropuesta,
        TextoUnidades(Propuesta.TotalUnidades),
        Propuesta.AlmacenOrigen,
        Propuesta.AlmacenDestino]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ConfirmarPropuestas(TPropuestasTraspaso.Create(Propuesta));
  end;
end;

procedure TfrmModalDistribucionTiendas.btnConfirmarTodasClick(
  Sender: TObject);
var
  Pendientes: TPropuestasTraspaso;
begin
  inherited;
  if GuardarSiHaceFalta then
  begin
    Pendientes := PropuestasPendientes;
    if Length(Pendientes) = 0 then
      ShowMessage_fza(SInfoNoHayPropuestasPendientes)
    else if MessageDlg_fza(
      Format(SPreguntaConfirmarTodasPropuestas, [Length(Pendientes)]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ConfirmarPropuestas(Pendientes);
  end;
end;

procedure TfrmModalDistribucionTiendas.btnEliminarPropuestaClick(
  Sender: TObject);
var
  Propuesta: TPropuestaTraspaso;
begin
  inherited;
  if GuardarSiHaceFalta and PropuestaEnfocada(Propuesta) then
  begin
    if not Propuesta.EstaPendiente then
      ShowMessage_fza(Format(
        SInfoPropuestaYaNoPendiente, [Propuesta.IdPropuesta]))
    else if MessageDlg_fza(
      Format(SPreguntaEliminarPropuesta, [Propuesta.IdPropuesta]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if FConfiguracion.Servicios.Repositorio.EliminarPropuestaPendiente(
           Propuesta.IdPropuesta) then
        FHuboCambios := True;
      CargarDocumento;
    end;
  end;
end;

// sFicha lo fija el ancestro: 'S' con Guardar y cerrar o F12 y 'N' con
// Cerrar o ESC. Con cambios sin guardar, cerrar pregunta antes.
function TfrmModalDistribucionTiendas.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and Assigned(FModelo) then
  begin
    if tvReparto.Controller.IsEditing then
      tvReparto.Controller.EditingController.HideEdit(True);
    if sFicha = 'S' then
      Result := GuardarSiHaceFalta
    else if FModelo.Modificado then
    begin
      case MessageDlg_fza(SPreguntaGuardarDistribucion, mtConfirmation,
             [mbYes, mbNo, mbCancel], 0) of
        mrYes:
          Result := GuardarCambios;
        mrNo:
          Result := True;
      else
        Result := False;
      end;
    end;
    if Result then
      GuardarPreferencias;
  end;
end;

end.
