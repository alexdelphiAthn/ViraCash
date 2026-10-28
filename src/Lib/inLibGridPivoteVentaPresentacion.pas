{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteVentaPresentacion                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presentación del pivote de venta (fascículo V4 del anexo SRP):            }
{    TClientDataSet temporal, columnas DevExpress, dibujo, edición, foco,      }
{    temporizador de recarga e instalación/restauración de eventos del         }
{    dataset. Conoce VCL y DevExpress; recibe el modelo y callbacks            }
{    tipados. No contiene SQL ni recalcula reglas del pivote.                  }
{******************************************************************************}
unit inLibGridPivoteVentaPresentacion;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types,
  System.Variants,
  System.UITypes, Data.DB, Uni,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls,
  cxGraphics, cxEdit, cxTextEdit, cxButtonEdit, cxCurrencyEdit,
  cxNavigator,
  cxDataStorage, cxFilter, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView,
  inLibColumnasSkuIntf,
  inLibPivoteVentaCalculo, inLibPivoteVentaIntf,
  inLibPivoteVentaModelo, inLibGridPivoteVentaVista,
  inLibUnidadesMedida, inLibPestanasEjeVcl;

type
  // Configuración visual del pivote: vista, datasets y campos del host.
  TConfigPresentacionPivoteVenta = record
    Conexion          : TUniConnection;
    View              : TcxGridDBTableView;
    SourceLineas      : TDataSource;
    CdsFallback       : TDataSet;
    CampoArticuloHost : string;
    FieldLinea        : string;
    FieldArt          : string;
    FieldSku          : string;
    FieldTotalUdsGrupo: string;
    FieldImporteLinea : string;
    FieldPrecioBase   : string;
    MaxColumnas       : Integer;
    BandaUnica        : Boolean;
    UnidadesMedida    : TUnidadesMedida;
  end;
  // Callbacks tipados hacia el coordinador: la presentación no decide
  // reglas ni persiste cantidades.
  TCallbacksPresentacionPivoteVenta = record
    AlRecargar             : TNotifyEvent;
    // False = cantidad rechazada (total máximo por línea, FZ-ISSUE-255).
    AlEditarCantidad       : function(AClave: Int64; AValor: Double;
                               ABanda: TBandaPivoteVenta): Boolean
                               of object;
    AlResolverEntradaEditor: function(const AEntrada: string;
                               out ATextoLinea: string;
                               out ACancelada: Boolean)
                               : Boolean of object;
    AlBuscarArticulo       : function: Boolean of object;
    AlBorrarGrupo          : function(ALineaBase: Integer)
                               : Integer of object;
    AlLineaFocada          : procedure(ALineaBase: Integer) of object;
    // Nombre del atributo del eje de fila del artículo («Aroma»); vacío
    // = «Color» (FZ-ISSUE-436).
    AlRotuloEjeFila        : function(const AArticulo: string): string
                               of object;
    // Columna propia del documento (precio, IVA, almacen...) editada
    // sobre la fila de un grupo: el valor va a todas sus lineas reales.
    AlEditarCampoHost      : procedure(ALineaBase: Integer;
                               const ACampo: string;
                               const AValor: Variant) of object;
    AlEntrarEdicion        : TNotifyEvent;
    AlSalirEdicion         : TNotifyEvent;
    AlLogInfo              : TLogPivoteVentaEvent;
    AlLogWarning           : TLogPivoteVentaEvent;
  end;
  // Eventos originales del dataset del host, para restaurarlos.
  TEventosDataSetPivote = record
    OnFilterOrig  : TFilterRecordEvent;
    AfterOpenOrig : TDataSetNotifyEvent;
    AfterPostOrig : TDataSetNotifyEvent;
    AfterScrollOrig: TDataSetNotifyEvent;
    FilteredOrig  : Boolean;
    Instalados    : Boolean;
  end;
  TEstadoNavegadorPivote = record
    AlClickOriginal   : TcxNavigatorButtonClickEvent;
    BotonesVisibles  : array[0..NavigatorButtonCount - 1] of Boolean;
    VisibleOriginal  : Boolean;
    ConfirmarOriginal: Boolean;
    ConfirmarGridOriginal: Boolean;
    AnadirOriginal   : Boolean;
    CicloCeldaOriginal: Boolean;
    TabCeldaOriginal : Boolean;
    EnterCeldaOriginal: Boolean;
    Instalado        : Boolean;
  end;
  TPresentacionPivoteVenta = class
  private
    FCfg                : TConfigPresentacionPivoteVenta;
    FCall               : TCallbacksPresentacionPivoteVenta;
    FModelo             : TModeloPivoteVenta;
    FColLineaVista      : TcxGridDBColumn;
    FColArticulo        : TcxGridDBColumn;
    FPropiedadesCantidad: TcxCurrencyEditProperties;
    FColColor           : TcxGridDBColumn;
    FColPestana         : TcxGridDBColumn;
    FPestanas           : TControlPestanasEje;
    FColTipoCantidad    : TcxGridDBColumn;
    FColumnasTallas     : TArray<TcxGridDBColumn>;
    FVista              : TVistaPivoteVenta;
    FEventosDs          : TEventosDataSetPivote;
    FNavegador           : TEstadoNavegadorPivote;
    FActualizandoGrid   : Boolean;
    FRecargaSuspendida  : Boolean;
    FEdicionSuspendida  : Boolean;
    // Tras Montar, la primera publicación vuelve al inicio para que el
    // scroll heredado no oculte filas pivotadas.
    FScrollInicialPendiente: Boolean;
    FAnchosInicialesPendientes: Boolean;
    FTimerRecarga       : TTimer;
    // Artículo cuyo atributo titula FColColor (FZ-ISSUE-436).
    FArticuloEjeFila    : string;
    procedure RefrescarPestanas;
    procedure CambiarPestana(const ACodigo: string);
    function CdsLineas: TDataSet;
    procedure TimerRecargaTimer(Sender: TObject);
    procedure InstalarEventosDataSet;
    procedure RestaurarEventosDataSet;
    procedure InstalarNavegador;
    procedure RestaurarNavegador;
    procedure NavegadorButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
    procedure CdsAfterOpen(DataSet: TDataSet);
    procedure CdsAfterPost(DataSet: TDataSet);
    procedure CdsAfterScroll(DataSet: TDataSet);
    procedure CrearColumnas;
    function EscalarAncho(AAncho: Integer): Integer;
    procedure PrepararAnchoColumna(AColumna: TcxGridColumn;
      AAncho: Integer);
    function TextoCeldaDibujada(ARegistro: Integer;
      AColumna: TcxGridColumn): string;
    procedure AjustarAnchoDibujo(AColumna: TcxGridColumn;
      AMargen: Integer; ANegrita: Boolean);
    procedure AjustarAnchosIniciales;
    procedure AplicarVisibilidadColor(
      AMostrarProvisional: Boolean = False);
    procedure AplicarVisibilidadTallas;
    procedure AplicarVisibilidadTipoCantidad;
    procedure ColocarBloqueColumnas;
    procedure ActualizarCaptionsLineaActiva;
    procedure ActualizarCaptionEjeFila(const AArticulo: string);
    function LineaDesdeRecord(ARecord: TcxCustomGridRecord): Integer;
    function EsColumnaTalla(AItem: TcxCustomGridTableItem): Boolean;
    function EsCampoHostEditable(const ACampo: string): Boolean;
    procedure VistaCampoEditado(ALineaVista: Integer; AField: TField);
    function TallaAvDesdeColumna(ALineaBase: Integer;
                                 ACol: TcxGridColumn;
                                 out AIdAv: Integer): Boolean;
    function BuscarColumnaTallaDesde(ALineaBase,
      AIndiceInicial: Integer; out ACol: TcxGridColumn): Boolean;
    function BuscarRecordPorLineaVista(ALineaVista: Integer;
                                       out ARecordIndex: Integer)
                                       : Boolean;
    function ValorEditor(ASender: TObject;
                         AValorFallback: Variant): Double;
    procedure ViewEditing(Sender: TcxCustomGridTableView;
                          AItem: TcxCustomGridTableItem;
                          var AAllow: Boolean);
    procedure EditorSalir(Sender: TObject);
    procedure PropiedadesCantidadEdicion(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                              AItem: TcxCustomGridTableItem;
                              AEdit: TcxCustomEdit; var Key: Word;
                              Shift: TShiftState);
    function GestionarEnterAAlbaranar(Sender: TcxCustomGridTableView;
                                      AItem: TcxCustomGridTableItem)
                                      : Boolean;
    procedure ViewFocusedRecordChanged(Sender: TcxCustomGridTableView;
                APrevFocusedRecord,
                AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure CustomDrawCell(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    function TallaFueraDeRotulo(ALineaBase: Integer;
                                ACol: TcxGridColumn): string;
    procedure PintarCeldaTallaCantidad(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                AValor: Double; ABanda: TBandaPivoteVenta;
                AMostrarCero: Boolean; const ATalla, AUnidad: string);
    function TextoCantidadCelda(AValor: Double;
                const AUnidad: string): string;
    procedure PintarCeldaTipoCantidad(ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo);
    procedure ArticuloButtonClick(Sender: TObject;
                                  AButtonIndex: Integer);
    function EsArticuloDeFilaFocada(const AEntrada: string): Boolean;
    procedure ArticuloValidate(Sender: TObject;
                               var DisplayValue: Variant;
                               var ErrorText: TCaption;
                               var Error: Boolean);
    procedure CeldaTallaValidate(Sender: TObject;
                                 var DisplayValue: Variant;
                                 var ErrorText: TCaption;
                                 var Error: Boolean);
  public
    constructor Create(const ACfg: TConfigPresentacionPivoteVenta;
                       const ACallbacks
                         : TCallbacksPresentacionPivoteVenta;
                       AModelo: TModeloPivoteVenta);
    destructor Destroy; override;
    procedure Montar;
    procedure Desmontar;
    procedure ArmarRecarga;
    // Reconstruye la vista temporal y publica el estado del modelo.
    procedure PublicarTodo;
    procedure PublicarCantidadesPivot;
    // Enfoca la columna de artículo y abre su editor; devuelve si el
    // editor quedó realmente en edición.
    function EnfocarEditorArticulo: Boolean;
    // Abre la fila en blanco de alta con el editor de artículo: el mismo
    // camino que el botón de añadir del navegador.
    procedure IniciarAltaLinea;
    procedure FinalizarAlta;
    // Hay un alta abierta con «Añadir línea» que aún no se ha resuelto.
    function AltaPendiente: Boolean;
    procedure MostrarArticuloProvisional(const AArticulo: string);
    procedure MostrarColorProvisional(AVisible: Boolean);
    function ObtenerAnclajeColor(
      out AAnclaje: TAnclajeSelectorAtributo): Boolean;
    // Línea base del grupo con foco (0 si no hay grupo bajo el foco).
    function LineaBaseFocada: Integer;
    function EsInsercionVacia(ADs: TDataSet): Boolean;
    procedure RefrescarSite;
    property RecargaSuspendida: Boolean read FRecargaSuspendida
                                        write FRecargaSuspendida;
    property EdicionSuspendida: Boolean read FEdicionSuspendida
                                        write FEdicionSuspendida;
  end;

implementation

uses
  inLibAtributosPaleta, inLibMsgArticulos, inLibDevExp, inLibPestanasEje;

function EventosDataSetPivoteIguales(const AEventoUno,
  AEventoDos: TDataSetNotifyEvent): Boolean;
begin
  Result := (TMethod(AEventoUno).Code = TMethod(AEventoDos).Code) and
            (TMethod(AEventoUno).Data = TMethod(AEventoDos).Data);
end;

const
  ANCHO_COLUMNA_TALLA_TRES_CANT = 62;

type
  THackWinControl = class(TWinControl);

constructor TPresentacionPivoteVenta.Create(
  const ACfg: TConfigPresentacionPivoteVenta;
  const ACallbacks: TCallbacksPresentacionPivoteVenta;
  AModelo: TModeloPivoteVenta);
var
  oCfgVista: TConfigVistaPivoteVenta;
begin
  inherited Create;
  FCfg := ACfg;
  FCall := ACallbacks;
  FModelo := AModelo;
  if FCfg.MaxColumnas <= 0 then
    FCfg.MaxColumnas := MAX_TALLAS_HORIZONTAL;
  oCfgVista := Default(TConfigVistaPivoteVenta);
  oCfgVista.View := FCfg.View;
  oCfgVista.SourceLineas := FCfg.SourceLineas;
  oCfgVista.CdsFallback := FCfg.CdsFallback;
  oCfgVista.FieldLinea := FCfg.FieldLinea;
  oCfgVista.FieldArt := FCfg.FieldArt;
  oCfgVista.FieldSku := FCfg.FieldSku;
  oCfgVista.FieldTotalUdsGrupo := FCfg.FieldTotalUdsGrupo;
  oCfgVista.FieldImporteLinea := FCfg.FieldImporteLinea;
  oCfgVista.FieldPrecioBase := FCfg.FieldPrecioBase;
  oCfgVista.BandaUnica := FCfg.BandaUnica;
  oCfgVista.AlLogWarning := FCall.AlLogWarning;
  // El delete redirigido de la vista rearma la recarga diferida.
  FVista := TVistaPivoteVenta.Create(oCfgVista, AModelo,
    FCall.AlBorrarGrupo, ArmarRecarga);
  FVista.AlCampoEditado := VistaCampoEditado;
  FTimerRecarga := TTimer.Create(nil);
  FTimerRecarga.Enabled := False;
  FTimerRecarga.Interval := 1;
  FTimerRecarga.OnTimer := TimerRecargaTimer;
end;

destructor TPresentacionPivoteVenta.Destroy;
begin
  // Mismo orden que Desmontar: primero los eventos del dataset, luego
  // la vista (el cambio de DataSource dispara First/AfterScroll).
  RestaurarNavegador;
  RestaurarEventosDataSet;
  FreeAndNil(FPestanas);
  FreeAndNil(FVista);
  FreeAndNil(FTimerRecarga);
  FreeAndNil(FPropiedadesCantidad);
  inherited;
end;

function TPresentacionPivoteVenta.CdsLineas: TDataSet;
begin
  Result := nil;
  if FCfg.SourceLineas <> nil then
    Result := FCfg.SourceLineas.DataSet;
  if Result = nil then
    Result := FCfg.CdsFallback;
end;

procedure TPresentacionPivoteVenta.Montar;
begin
  FScrollInicialPendiente := True;
  FAnchosInicialesPendientes := True;
  // SKU y desglose pueden dejarlo activo: las tallas necesitan scroll,
  // no comprimir todas las columnas para encajarlas en el ancho del grid.
  FCfg.View.OptionsView.ColumnAutoWidth := False;
  CrearColumnas;
  FVista.Preparar;
  FCfg.View.OnEditing := ViewEditing;
  FCfg.View.OnInitEdit := ViewInitEdit;
  FCfg.View.OnEditKeyDown := ViewEditKeyDown;
  FCfg.View.OnFocusedRecordChanged := ViewFocusedRecordChanged;
  FCfg.View.OnCustomDrawCell := CustomDrawCell;
  InstalarNavegador;
  InstalarEventosDataSet;
  ArmarRecarga;
end;

procedure TPresentacionPivoteVenta.Desmontar;
begin
  if FCfg.View <> nil then
  begin
    FCfg.View.OnEditing := nil;
    FCfg.View.OnInitEdit := nil;
    FCfg.View.OnEditKeyDown := nil;
    FCfg.View.OnFocusedRecordChanged := nil;
    FCfg.View.OnCustomDrawCell := nil;
  end;
  if FPestanas <> nil then
    FPestanas.Ocultar;
  RestaurarNavegador;
  // Eventos del dataset ANTES de restaurar la vista: el cambio de
  // DataSource recarga el grid (First -> AfterScroll) y con
  // CdsAfterScroll aún enganchado se leía un grid a medio cargar
  // (EListError al pasar a otro modo, 08/07/26).
  RestaurarEventosDataSet;
  FVista.Restaurar;
end;

procedure TPresentacionPivoteVenta.ArmarRecarga;
begin
  if FTimerRecarga <> nil then
  begin
    FTimerRecarga.Enabled := False;
    FTimerRecarga.Enabled := True;
  end;
end;

procedure TPresentacionPivoteVenta.TimerRecargaTimer(Sender: TObject);
begin
  FTimerRecarga.Enabled := False;
  if Assigned(FCall.AlRecargar) then
    FCall.AlRecargar(Self);
end;

procedure TPresentacionPivoteVenta.InstalarEventosDataSet;
var
  oDs: TDataSet;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and (not FEventosDs.Instalados) then
  begin
    FEventosDs.OnFilterOrig := oDs.OnFilterRecord;
    FEventosDs.FilteredOrig := oDs.Filtered;
    FEventosDs.AfterOpenOrig := oDs.AfterOpen;
    FEventosDs.AfterPostOrig := oDs.AfterPost;
    FEventosDs.AfterScrollOrig := oDs.AfterScroll;
    oDs.AfterOpen := CdsAfterOpen;
    oDs.AfterPost := CdsAfterPost;
    oDs.AfterScroll := CdsAfterScroll;
    FEventosDs.Instalados := True;
  end;
end;

procedure TPresentacionPivoteVenta.RestaurarEventosDataSet;
var
  oDs: TDataSet;
  oEvento: TDataSetNotifyEvent;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and FEventosDs.Instalados then
  begin
    // Primero desenganchar los hooks y LUEGO restaurar Filtered: el
    // cambio de filtro refresca el dataset y dispara AfterScroll, que
    // no debe caer ya en los handlers del pivote.
    oEvento := CdsAfterOpen;
    if EventosDataSetPivoteIguales(oDs.AfterOpen, oEvento) then
      oDs.AfterOpen := FEventosDs.AfterOpenOrig;
    oEvento := CdsAfterPost;
    if EventosDataSetPivoteIguales(oDs.AfterPost, oEvento) then
      oDs.AfterPost := FEventosDs.AfterPostOrig;
    oEvento := CdsAfterScroll;
    if EventosDataSetPivoteIguales(oDs.AfterScroll, oEvento) then
      oDs.AfterScroll := FEventosDs.AfterScrollOrig;
    FEventosDs.Instalados := False;
    oDs.Filtered := FEventosDs.FilteredOrig;
  end;
end;

procedure TPresentacionPivoteVenta.InstalarNavegador;
var
  i: Integer;
begin
  if (FCfg.View <> nil) and (not FNavegador.Instalado) then
  begin
    FNavegador.AlClickOriginal :=
      FCfg.View.Navigator.Buttons.OnButtonClick;
    FNavegador.VisibleOriginal := FCfg.View.Navigator.Visible;
    FNavegador.ConfirmarOriginal :=
      FCfg.View.Navigator.Buttons.ConfirmDelete;
    // El grid tiene otra confirmacion de borrado independiente de la
    // del navegador. VistaBeforeDelete ya confirma los grupos reales.
    FNavegador.ConfirmarGridOriginal :=
      FCfg.View.OptionsData.DeletingConfirmation;
    FNavegador.AnadirOriginal := FCfg.View.OptionsData.Appending;
    FNavegador.CicloCeldaOriginal :=
      FCfg.View.OptionsBehavior.FocusCellOnCycle;
    FNavegador.TabCeldaOriginal :=
      FCfg.View.OptionsBehavior.FocusCellOnTab;
    FNavegador.EnterCeldaOriginal :=
      FCfg.View.OptionsBehavior.GoToNextCellOnEnter;
    for i := 0 to NavigatorButtonCount - 1 do
      FNavegador.BotonesVisibles[i] :=
        FCfg.View.Navigator.Buttons[i].Visible;
    FCfg.View.Navigator.Visible := True;
    FCfg.View.Navigator.Buttons.ConfirmDelete := False;
    FCfg.View.OptionsData.DeletingConfirmation := False;
    FCfg.View.OptionsData.Appending := True;
    FCfg.View.OptionsBehavior.FocusCellOnCycle := True;
    FCfg.View.OptionsBehavior.FocusCellOnTab := True;
    FCfg.View.OptionsBehavior.GoToNextCellOnEnter := True;
    FCfg.View.Navigator.Buttons.First.Visible := True;
    FCfg.View.Navigator.Buttons.Prior.Visible := True;
    FCfg.View.Navigator.Buttons.Next.Visible := True;
    FCfg.View.Navigator.Buttons.Last.Visible := True;
    FCfg.View.Navigator.Buttons.Insert.Visible := False;
    FCfg.View.Navigator.Buttons.Append.Visible := True;
    FCfg.View.Navigator.Buttons.Delete.Visible := True;
    FCfg.View.Navigator.Buttons.PriorPage.Visible := False;
    FCfg.View.Navigator.Buttons.NextPage.Visible := False;
    FCfg.View.Navigator.Buttons.Edit.Visible := False;
    FCfg.View.Navigator.Buttons.Post.Visible := False;
    FCfg.View.Navigator.Buttons.Cancel.Visible := False;
    FCfg.View.Navigator.Buttons.Refresh.Visible := False;
    FCfg.View.Navigator.Buttons.SaveBookmark.Visible := False;
    FCfg.View.Navigator.Buttons.GotoBookmark.Visible := False;
    FCfg.View.Navigator.Buttons.Filter.Visible := False;
    FCfg.View.Navigator.Buttons.OnButtonClick :=
      NavegadorButtonClick;
    FNavegador.Instalado := True;
  end;
end;

procedure TPresentacionPivoteVenta.RestaurarNavegador;
var
  i: Integer;
begin
  if (FCfg.View <> nil) and FNavegador.Instalado then
  begin
    FCfg.View.Navigator.Buttons.OnButtonClick :=
      FNavegador.AlClickOriginal;
    FCfg.View.Navigator.Visible := FNavegador.VisibleOriginal;
    FCfg.View.Navigator.Buttons.ConfirmDelete :=
      FNavegador.ConfirmarOriginal;
    FCfg.View.OptionsData.DeletingConfirmation :=
      FNavegador.ConfirmarGridOriginal;
    FCfg.View.OptionsData.Appending := FNavegador.AnadirOriginal;
    FCfg.View.OptionsBehavior.FocusCellOnCycle :=
      FNavegador.CicloCeldaOriginal;
    FCfg.View.OptionsBehavior.FocusCellOnTab :=
      FNavegador.TabCeldaOriginal;
    FCfg.View.OptionsBehavior.GoToNextCellOnEnter :=
      FNavegador.EnterCeldaOriginal;
    for i := 0 to NavigatorButtonCount - 1 do
      FCfg.View.Navigator.Buttons[i].Visible :=
        FNavegador.BotonesVisibles[i];
    FNavegador.Instalado := False;
  end;
end;

procedure TPresentacionPivoteVenta.NavegadorButtonClick(
  Sender: TObject; AButtonIndex: Integer; var ADone: Boolean);
begin
  if Assigned(FNavegador.AlClickOriginal) then
    FNavegador.AlClickOriginal(Sender, AButtonIndex, ADone);
  if (not ADone) and
     (AButtonIndex in [NBDI_INSERT, NBDI_APPEND]) then
  begin
    ADone := True;
    IniciarAltaLinea;
  end;
end;

procedure TPresentacionPivoteVenta.IniciarAltaLinea;
var
  oDs: TDataSet;
begin
  oDs := CdsLineas;
  if FVista.EsInsercionVacia(oDs) then
    oDs.Cancel;
  FVista.IniciarAlta;
  EnfocarEditorArticulo;
end;

procedure TPresentacionPivoteVenta.CdsAfterOpen(DataSet: TDataSet);
begin
  if Assigned(FEventosDs.AfterOpenOrig) then
    FEventosDs.AfterOpenOrig(DataSet);
  if not FRecargaSuspendida then
    ArmarRecarga;
end;

procedure TPresentacionPivoteVenta.CdsAfterPost(DataSet: TDataSet);
begin
  if Assigned(FEventosDs.AfterPostOrig) then
    FEventosDs.AfterPostOrig(DataSet);
  if not FRecargaSuspendida then
    ArmarRecarga;
end;

procedure TPresentacionPivoteVenta.CdsAfterScroll(DataSet: TDataSet);
begin
  if Assigned(FEventosDs.AfterScrollOrig) then
    FEventosDs.AfterScrollOrig(DataSet);
  ActualizarCaptionsLineaActiva;
end;

procedure TPresentacionPivoteVenta.CrearColumnas;
var
  i: Integer;
  oCol: TcxGridDBColumn;
  PropiedadesArticulo: TcxButtonEditProperties;
  BotonArticulo: TcxEditButton;
begin
  FCfg.View.BeginUpdate;
  try
    FColLineaVista := FCfg.View.CreateColumn;
    FColLineaVista.DataBinding.FieldName := CAMPO_LINEA_VISTA_PIVOTE;
    FColLineaVista.Visible := False;
    FColLineaVista.VisibleForCustomization := False;
    FColArticulo := FCfg.View.CreateColumn;
    FColArticulo.Caption := SCaptionColArticulo;
    FColArticulo.DataBinding.FieldName := FCfg.CampoArticuloHost;
    PrepararAnchoColumna(FColArticulo, 160);
    FColArticulo.Options.Editing := True;
    FColArticulo.PropertiesClass := TcxButtonEditProperties;
    PropiedadesArticulo := TcxButtonEditProperties(FColArticulo.Properties);
    PropiedadesArticulo.Buttons.Clear;
    BotonArticulo := PropiedadesArticulo.Buttons.Add;
    BotonArticulo.Default := True;
    BotonArticulo.Kind := bkEllipsis;
    PropiedadesArticulo.OnButtonClick := ArticuloButtonClick;
    PropiedadesArticulo.OnValidate := ArticuloValidate;
    FColColor := FCfg.View.CreateColumn;
    FColColor.Caption := SCaptionColColor;
    PrepararAnchoColumna(FColColor, 125);
    FColColor.Options.Editing := False;
    FColColor.DataBinding.ValueTypeClass := TcxStringValueType;
    FColPestana := FCfg.View.CreateColumn;
    FColPestana.Caption := 'Copa';
    FColPestana.DataBinding.FieldName := CAMPO_PESTANA_VISTA_PIVOTE;
    PrepararAnchoColumna(FColPestana, 75);
    FColPestana.Options.Editing := False;
    FColPestana.Visible := False;
    FColTipoCantidad := FCfg.View.CreateColumn;
    if FCfg.BandaUnica then
      FColTipoCantidad.Caption := SCaptionColTipoCantidad
    else
      FColTipoCantidad.Caption := SCaptionColTipoFila;
    PrepararAnchoColumna(FColTipoCantidad, 105);
    FColTipoCantidad.Options.Editing := False;
    FColTipoCantidad.DataBinding.ValueTypeClass := TcxStringValueType;
    SetLength(FColumnasTallas, FCfg.MaxColumnas);
    for i := 1 to FCfg.MaxColumnas do
    begin
      oCol := FCfg.View.CreateColumn;
      oCol.Tag := i;
      oCol.Caption := '·';
      PrepararAnchoColumna(oCol, ANCHO_COLUMNA_TALLA_TRES_CANT);
      oCol.Visible := False;
      oCol.DataBinding.ValueTypeClass := TcxFloatValueType;
      oCol.PropertiesClass := TcxCurrencyEditProperties;
      // La cantidad va a la derecha: el nombre de la talla, encima.
      oCol.HeaderAlignmentHorz := taRightJustify;
      TcxCurrencyEditProperties(oCol.Properties).DisplayFormat :=
        '#,##0.##';
      TcxCurrencyEditProperties(oCol.Properties).
        UseDisplayFormatWhenEditing := True;
      oCol.OnGetPropertiesForEdit := PropiedadesCantidadEdicion;
      TcxCurrencyEditProperties(oCol.Properties).OnValidate :=
        CeldaTallaValidate;
      FColumnasTallas[i - 1] := oCol;
    end;
  finally
    FCfg.View.EndUpdate;
  end;
end;

function TPresentacionPivoteVenta.EscalarAncho(AAncho: Integer): Integer;
var
  iPpi: Integer;
begin
  iPpi := USER_DEFAULT_SCREEN_DPI;
  if Assigned(FCfg.View.Control) then
    iPpi := FCfg.View.Control.CurrentPPI;
  Result := MulDiv(AAncho, iPpi, USER_DEFAULT_SCREEN_DPI);
end;

procedure TPresentacionPivoteVenta.PrepararAnchoColumna(
  AColumna: TcxGridColumn; AAncho: Integer);
begin
  AColumna.MinWidth := EscalarAncho(AAncho);
  AColumna.Width := AColumna.MinWidth;
end;

function TPresentacionPivoteVenta.TextoCeldaDibujada(
  ARegistro: Integer; AColumna: TcxGridColumn): string;
var
  iLineaVista: Integer;
  oGrupo: TGrupoPivoteVenta;
begin
  Result := FCfg.View.DataController.DisplayTexts[ARegistro,
    AColumna.Index];
  // El dibujo del color usa el codigo si no hay descripcion.
  if (AColumna = FColColor) and (Result = '') then
  begin
    iLineaVista := StrToIntDef(VarToStr(
      FCfg.View.DataController.Values[ARegistro,
        FColLineaVista.Index]), 0);
    if FModelo.Grupo(FModelo.ObtenerLineaBase(iLineaVista), oGrupo) then
      Result := oGrupo.ColorCodigo;
  end;
end;

procedure TPresentacionPivoteVenta.AjustarAnchoDibujo(
  AColumna: TcxGridColumn; AMargen: Integer; ANegrita: Boolean);
var
  oMedicion: TBitmap;
  rParametros: TcxViewParams;
  iRegistro, iAncho, iTexto: Integer;
begin
  if AColumna.ActuallyVisible and
     TcxCustomGridTableItemAccess.CanHorzSize(AColumna) then
  begin
    oMedicion := TBitmap.Create;
    try
      AColumna.Styles.GetContentParams(nil, rParametros);
      oMedicion.Canvas.Font.Assign(rParametros.Font);
      if ANegrita then
        oMedicion.Canvas.Font.Style := [fsBold];
      iAncho := AColumna.Width;
      for iRegistro := 0 to FCfg.View.DataController.RecordCount - 1 do
      begin
        iTexto := oMedicion.Canvas.TextWidth(
          TextoCeldaDibujada(iRegistro, AColumna)) + EscalarAncho(AMargen);
        if iTexto > iAncho then
          iAncho := iTexto;
      end;
      if (AColumna.BestFitMaxWidth > 0) and
         (iAncho > AColumna.BestFitMaxWidth) then
        iAncho := AColumna.BestFitMaxWidth;
      AColumna.Width := iAncho;
    finally
      FreeAndNil(oMedicion);
    end;
  end;
end;

procedure TPresentacionPivoteVenta.AjustarAnchosIniciales;
var
  iColumna: Integer;
begin
  // La fila ficticia de un documento vacio no consume el primer ajuste.
  // Las columnas host se crean despues de Montar; medir al publicar evita
  // hacerlo contra la vista vacia y no pisa anchos manuales al dar foco.
  if FAnchosInicialesPendientes and (FModelo.LineasVista.Count > 0) then
  begin
    FAnchosInicialesPendientes := False;
    FCfg.View.BeginUpdate;
    try
      AplicarBestFitConMargen(FCfg.View);
      AjustarAnchoDibujo(FColColor, ANCHO_SWATCH_PX, False);
      AjustarAnchoDibujo(FColTipoCantidad, 24, True);
      for iColumna := 0 to High(FColumnasTallas) do
        AjustarAnchoDibujo(FColumnasTallas[iColumna], 24, True);
    finally
      FCfg.View.EndUpdate;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.AplicarVisibilidadTipoCantidad;
begin
  if FColTipoCantidad <> nil then
  begin
    if FCfg.BandaUnica then
      FColTipoCantidad.Visible := FModelo.HayTipoCantidadEspecial
    else
      FColTipoCantidad.Visible := True;
    FColTipoCantidad.VisibleForCustomization :=
      FColTipoCantidad.Visible;
  end;
end;

procedure TPresentacionPivoteVenta.AplicarVisibilidadColor(
  AMostrarProvisional: Boolean);
begin
  if FColColor <> nil then
  begin
    FColColor.Visible := FModelo.HayColor or AMostrarProvisional;
    FColColor.VisibleForCustomization := FColColor.Visible;
  end;
end;

procedure TPresentacionPivoteVenta.AplicarVisibilidadTallas;
var
  i, iMax: Integer;
begin
  iMax := FModelo.MaxPosicionesVisibles(FCfg.MaxColumnas);
  for i := 0 to High(FColumnasTallas) do
  begin
    FColumnasTallas[i].Visible := i < iMax;
    if not FColumnasTallas[i].Visible then
      FColumnasTallas[i].Caption := '·';
  end;
  ActualizarCaptionsLineaActiva;
end;

procedure TPresentacionPivoteVenta.ColocarBloqueColumnas;
var
  i, iBase, iDestino: Integer;
  bColocado: Boolean;
begin
  // El bloque de entrada del pivote va SIEMPRE delante de las columnas
  // del documento, justo detrás del Nro de línea del host (Index 0).
  // Idempotente: corrige recolocaciones externas (perfiles, 09/07/26).
  if (FCfg.View <> nil) and (FColLineaVista <> nil) and
     (FColArticulo <> nil) and (FColColor <> nil) and
     (FColTipoCantidad <> nil) then
  begin
    iBase := 1;
    if FCfg.View.ColumnCount <= 1 then
      iBase := 0;
    bColocado := (FColLineaVista.Index = iBase) and
                 (FColArticulo.Index = iBase + 1) and
                 (FColColor.Index = iBase + 2) and
                 (FColPestana.Index = iBase + 3) and
                 (FColTipoCantidad.Index = iBase + 4);
    if bColocado then
    begin
      for i := 0 to High(FColumnasTallas) do
        if (FColumnasTallas[i] <> nil) and
           (FColumnasTallas[i].Index <> iBase + 5 + i) then
          bColocado := False;
    end;
    if not bColocado then
    begin
      FCfg.View.BeginUpdate;
      try
        // Asignación en orden de destino ascendente: cada Index
        // inserta la columna en su posición final.
        iDestino := iBase;
        FColLineaVista.Index := iDestino;
        Inc(iDestino);
        FColArticulo.Index := iDestino;
        Inc(iDestino);
        FColColor.Index := iDestino;
        Inc(iDestino);
        FColPestana.Index := iDestino;
        Inc(iDestino);
        FColTipoCantidad.Index := iDestino;
        Inc(iDestino);
        for i := 0 to High(FColumnasTallas) do
        begin
          if FColumnasTallas[i] <> nil then
          begin
            FColumnasTallas[i].Index := iDestino;
            Inc(iDestino);
          end;
        end;
      finally
        FCfg.View.EndUpdate;
      end;
    end;
  end;
end;

// FZ-ISSUE-436: la columna del eje de fila se titula con el atributo del
// artículo de la línea enfocada («Aroma»), no siempre «Color». Solo
// consulta cuando la columna se ve y cambia el artículo.
procedure TPresentacionPivoteVenta.ActualizarCaptionEjeFila(
  const AArticulo: string);
var
  sRotulo: string;
begin
  if (FColColor <> nil) and FColColor.Visible and (AArticulo <> '') and
     (AArticulo <> FArticuloEjeFila) and
     Assigned(FCall.AlRotuloEjeFila) then
  begin
    FArticuloEjeFila := AArticulo;
    sRotulo := Trim(FCall.AlRotuloEjeFila(AArticulo));
    if sRotulo = '' then
      sRotulo := SCaptionColColor;
    if FColColor.Caption <> sRotulo then
      FColColor.Caption := sRotulo;
  end;
end;

procedure TPresentacionPivoteVenta.ActualizarCaptionsLineaActiva;
var
  oGrupo: TGrupoPivoteVenta;
  aPosiciones: TValoresTallaPivoteVenta;
  iLinea, iLineaVista, i: Integer;
  sRotulo: string;
  bCambio: Boolean;
begin
  if Assigned(FColTipoCantidad) then
    if FCfg.BandaUnica then
      FColTipoCantidad.Caption := SCaptionColTipoCantidad
    else
      FColTipoCantidad.Caption := SCaptionColTipoFila;
  iLineaVista := 0;
  if (FCfg.View <> nil) and (FCfg.View.Controller <> nil) then
    iLineaVista := LineaDesdeRecord(FCfg.View.Controller.FocusedRecord);
  iLinea := FModelo.ObtenerLineaBase(iLineaVista);
  aPosiciones := nil;
  oGrupo := Default(TGrupoPivoteVenta);
  if iLinea > 0 then
    FModelo.Grupo(iLinea, oGrupo);
  // <> 0 y no > 0: los conjuntos VIRTUALES llevan id negativo y sus
  // captions se resuelven desde la misma caché que los reales.
  if oGrupo.IdAc <> 0 then
    aPosiciones := FModelo.PosicionesConjunto(oGrupo.IdAc);
  ActualizarCaptionEjeFila(oGrupo.Articulo);
  bCambio := False;
  for i := 0 to High(FColumnasTallas) do
  begin
    if FColumnasTallas[i].Visible then
    begin
      if i < Length(aPosiciones) then
        sRotulo := aPosiciones[i].Valor
      else if (i = 0) and oGrupo.SinTalla then
        sRotulo := SCaptionColCantidad
      else
        sRotulo := '·';
      if FColumnasTallas[i].Caption <> sRotulo then
      begin
        FColumnasTallas[i].Caption := sRotulo;
        bCambio := True;
      end;
    end;
  end;
  // Las celdas de otro tallaje pintan su talla comparandola con el
  // rotulo (FZ-ISSUE-109): con rotulos nuevos se repintan todas.
  if bCambio then
    RefrescarSite;
end;

procedure TPresentacionPivoteVenta.PublicarCantidadesPivot;
var
  oColLinea: TcxGridColumn;
  oGrupo: TGrupoPivoteVenta;
  aPosiciones: TValoresTallaPivoteVenta;
  vLinea: Variant;
  iLinea, iLineaVista, recIdx, i: Integer;
  iClave: Int64;
  rCant: Double;
  oBanda: TBandaPivoteVenta;
begin
  if (FCfg.View <> nil) and (not FActualizandoGrid) then
  begin
    oColLinea :=
      FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
    if oColLinea = nil then
      oColLinea := FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
    if oColLinea <> nil then
    begin
      FActualizandoGrid := True;
      FCfg.View.DataController.BeginUpdate;
      try
        for recIdx := 0 to
          FCfg.View.DataController.RecordCount - 1 do
        begin
          vLinea := FCfg.View.DataController.Values[recIdx,
                                                    oColLinea.Index];
          iLineaVista := StrToIntDef(VarToStr(vLinea), 0);
          iLinea := FModelo.ObtenerLineaBase(iLineaVista);
          if iLinea > 0 then
          begin
            oBanda := FModelo.BandaDesdeLinea(iLineaVista);
            FCfg.View.DataController.Values[recIdx,
              FColTipoCantidad.Index] :=
                FModelo.TextoTipoCantidad(iLinea, oBanda);
            for i := 0 to High(FColumnasTallas) do
            begin
              if FColumnasTallas[i].Visible then
                FCfg.View.DataController.Values[recIdx,
                  FColumnasTallas[i].Index] := Null;
            end;
            if FModelo.Grupo(iLinea, oGrupo) then
            begin
              FCfg.View.DataController.Values[recIdx,
                FColColor.Index] := oGrupo.ColorTexto;
              if oGrupo.SinTalla then
              begin
                iClave := ClaveCeldaPivoteVenta(iLinea,
                  ID_AV_SIN_TALLA_PIVOTE);
                rCant := FModelo.ValorCantidadBanda(iClave, oBanda);
                if rCant <> 0 then
                  FCfg.View.DataController.Values[recIdx,
                    FColumnasTallas[0].Index] := rCant
                else
                  FCfg.View.DataController.Values[recIdx,
                    FColumnasTallas[0].Index] := Null;
              end
              else if oGrupo.IdAc <> 0 then
              begin
                aPosiciones :=
                  FModelo.PosicionesConjunto(oGrupo.IdAc);
                for i := 0 to High(aPosiciones) do
                begin
                  if i < Length(FColumnasTallas) then
                  begin
                    iClave := ClaveCeldaPivoteVenta(iLinea,
                      aPosiciones[i].IdAv);
                    rCant := FModelo.ValorCantidadBanda(iClave,
                                                        oBanda);
                    if rCant <> 0 then
                      FCfg.View.DataController.Values[recIdx,
                        FColumnasTallas[i].Index] := rCant
                    else
                      FCfg.View.DataController.Values[recIdx,
                        FColumnasTallas[i].Index] := Null;
                  end;
                end;
              end;
            end;
          end;
        end;
      finally
        FCfg.View.DataController.EndUpdate;
        FActualizandoGrid := False;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.RefrescarPestanas;
var
  aValores: TArray<string>;
  aUnidades: TArray<Double>;
  iLinea: Integer;
  oGrupo: TGrupoPivoteVenta;
  oRejilla: TWinControl;
begin
  if (FPestanas = nil) and (FCfg.View.Control <> nil) then
  begin
    oRejilla := FCfg.View.Control;
    FPestanas := TControlPestanasEje.Create(oRejilla.Owner,
      oRejilla.Parent, CambiarPestana);
    FPestanas.Control.Top := oRejilla.Top - 1;
  end;
  aValores := nil;
  aUnidades := nil;
  for iLinea in FModelo.LineasVista do
    if (FModelo.BandaDesdeLinea(iLinea) = bpvPedida) and
       FModelo.Grupo(FModelo.ObtenerLineaBase(iLinea), oGrupo) then
    begin
      aValores := aValores + [oGrupo.PestanaTexto];
      aUnidades := aUnidades + [oGrupo.UdsGrupo];
    end;
  if FPestanas <> nil then
  begin
    FPestanas.Mostrar(ModeloPestanasDeLineas('Copa', nil,
      aValores, aUnidades));
    FColPestana.Visible := FPestanas.HayPestanas;
    FColPestana.VisibleForCustomization := FColPestana.Visible;
    CambiarPestana(FPestanas.CodigoSeleccionado);
  end;
end;

procedure TPresentacionPivoteVenta.CambiarPestana(const ACodigo: string);
begin
  FCfg.View.DataController.Filter.BeginUpdate;
  try
    FCfg.View.DataController.Filter.RemoveItemByItemLink(FColPestana);
    if ACodigo <> '' then
    begin
      FCfg.View.DataController.Filter.Root.AddItem(FColPestana,
        foEqual, ACodigo, ACodigo);
      FCfg.View.DataController.Filter.Active := True;
    end;
  finally
    FCfg.View.DataController.Filter.EndUpdate;
  end;
  PublicarCantidadesPivot;
end;

procedure TPresentacionPivoteVenta.PublicarTodo;
var
  iRegistro: Integer;
begin
  FVista.Reconstruir;
  RefrescarPestanas;
  AplicarVisibilidadColor;
  AplicarVisibilidadTipoCantidad;
  AplicarVisibilidadTallas;
  ColocarBloqueColumnas;
  PublicarCantidadesPivot;
  // Traza de diagnóstico: si el CDS de la vista tiene más filas de las
  // que el grid publica, un filtro se está comiendo filas del view.
  if Assigned(FCall.AlLogInfo) and (FCfg.View <> nil) then
    FCall.AlLogInfo(Format(
      'PivVenta.Publicar: filasVista=%d filasGrid=%d filtroView="%s"',
      [FVista.FilasVista,
       FCfg.View.DataController.RecordCount,
       FCfg.View.DataController.Filter.FilterText]));
  // Primera publicación tras Montar: arrancar viendo el grid desde la
  // primera fila (el scroll heredado ocultaba filas pivotadas).
  if FScrollInicialPendiente and (FCfg.View <> nil) and
     (FCfg.View.DataController.RecordCount > 0) then
  begin
    FScrollInicialPendiente := False;
    FCfg.View.DataController.FocusedRecordIndex := 0;
    FCfg.View.Controller.TopRecordIndex := 0;
  end;
  if FVista.AltaPendiente and
     BuscarRecordPorLineaVista(0, iRegistro) then
    FCfg.View.DataController.FocusedRecordIndex := iRegistro;
  ActualizarCaptionsLineaActiva;
  AjustarAnchosIniciales;
end;

function TPresentacionPivoteVenta.EnfocarEditorArticulo: Boolean;
var
  iRegistro: Integer;
  bEditorVisible: Boolean;
begin
  Result := False;
  if (FCfg.View <> nil) and (FColArticulo <> nil) then
  begin
    if BuscarRecordPorLineaVista(0, iRegistro) then
      FCfg.View.DataController.FocusedRecordIndex := iRegistro
    else if (FCfg.View.DataController.FocusedRecordIndex < 0) and
            (FCfg.View.DataController.RecordCount > 0) then
      FCfg.View.DataController.FocusedRecordIndex := 0;
    bEditorVisible := Assigned(FCfg.View.Site) and
      FCfg.View.Site.HandleAllocated and
      IsWindowVisible(FCfg.View.Site.Handle);
    if bEditorVisible and FCfg.View.Site.CanFocus then
      FCfg.View.Site.SetFocus;
    FColArticulo.Focused := True;
    FCfg.View.Controller.FocusedItem := FColArticulo;
    if bEditorVisible then
    begin
      try
        FCfg.View.Controller.EditingController.ShowEdit;
      except
        on E: EInvalidOperation do
          // Ruido del editor inplace; queda constancia en el log.
          FCall.AlLogWarning(
            'PivotePresentacion.EnfocarEditorArticulo: ShowEdit ' +
            'ignorado: ' + E.Message);
      end;
    end;
    Result := FCfg.View.Controller.EditingController.IsEditing;
  end;
end;

procedure TPresentacionPivoteVenta.FinalizarAlta;
begin
  FVista.FinalizarAlta;
end;

function TPresentacionPivoteVenta.AltaPendiente: Boolean;
begin
  Result := FVista.AltaPendiente;
end;

procedure TPresentacionPivoteVenta.MostrarArticuloProvisional(
  const AArticulo: string);
var
  oEditor: TcxCustomEdit;
begin
  if (FCfg.View <> nil) and
     FCfg.View.Controller.EditingController.IsEditing then
  begin
    oEditor := FCfg.View.Controller.EditingController.Edit;
    if oEditor <> nil then
    begin
      oEditor.EditValue := AArticulo;
      oEditor.Repaint;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.MostrarColorProvisional(
  AVisible: Boolean);
begin
  AplicarVisibilidadColor(AVisible);
end;

function TPresentacionPivoteVenta.ObtenerAnclajeColor(
  out AAnclaje: TAnclajeSelectorAtributo): Boolean;
var
  oCelda: TcxGridTableDataCellViewInfo;
  oEditor: TcxCustomEdit;
  oPunto: TPoint;
begin
  AAnclaje := Default(TAnclajeSelectorAtributo);
  Result := False;
  if (FCfg.View <> nil) and (FColColor <> nil) and
     Assigned(FCfg.View.Site) and FCfg.View.Site.HandleAllocated then
  begin
    oCelda := FColColor.FocusedCellViewInfo;
    if oCelda <> nil then
    begin
      oPunto := FCfg.View.Site.ClientToScreen(
        Point(oCelda.Bounds.Left, oCelda.Bounds.Bottom));
      AAnclaje.IzquierdaPantalla := oPunto.X;
      AAnclaje.ArribaPantalla := oPunto.Y;
      AAnclaje.Ancho := oCelda.Bounds.Right - oCelda.Bounds.Left;
      Result := AAnclaje.Ancho > 0;
    end;
    if (not Result) and
       FCfg.View.Controller.EditingController.IsEditing then
    begin
      oEditor := FCfg.View.Controller.EditingController.Edit;
      if (oEditor <> nil) and oEditor.HasParent and
         oEditor.HandleAllocated then
      begin
        oPunto := oEditor.ClientToScreen(
          Point(oEditor.Width, oEditor.Height));
        AAnclaje.IzquierdaPantalla := oPunto.X;
        AAnclaje.ArribaPantalla := oPunto.Y;
        AAnclaje.Ancho := FColColor.Width;
        Result := AAnclaje.Ancho > 0;
      end;
    end;
  end;
  AAnclaje.Valido := Result;
end;

function TPresentacionPivoteVenta.EsInsercionVacia(
  ADs: TDataSet): Boolean;
begin
  Result := FVista.EsInsercionVacia(ADs);
end;

function TPresentacionPivoteVenta.LineaBaseFocada: Integer;
begin
  Result := 0;
  if (FCfg.View <> nil) and (FCfg.View.Controller <> nil) then
    Result := FModelo.ObtenerLineaBase(
      LineaDesdeRecord(FCfg.View.Controller.FocusedRecord));
end;

procedure TPresentacionPivoteVenta.RefrescarSite;
begin
  if (FCfg.View <> nil) and Assigned(FCfg.View.Site) then
    FCfg.View.Site.Invalidate;
end;

function TPresentacionPivoteVenta.LineaDesdeRecord(
  ARecord: TcxCustomGridRecord): Integer;
var
  oColLinea: TcxGridColumn;
  vLinea: Variant;
begin
  Result := 0;
  if (ARecord <> nil) and (FCfg.View <> nil) then
  begin
    try
      oColLinea :=
        FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
      if oColLinea = nil then
        oColLinea := FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
    except
      oColLinea := nil;
    end;
    if oColLinea <> nil then
    begin
      try
        vLinea := ARecord.Values[oColLinea.Index];
        Result := StrToIntDef(VarToStr(vLinea), 0);
      except
        Result := 0;
      end;
    end;
  end;
end;

function TPresentacionPivoteVenta.EsColumnaTalla(
  AItem: TcxCustomGridTableItem): Boolean;
begin
  Result := (AItem <> nil) and (AItem.Tag >= 1) and
            (AItem.Tag <= Length(FColumnasTallas)) and
            (FColumnasTallas[AItem.Tag - 1] = AItem);
end;

// Columna editable que el documento añadió tras Montar. La identidad
// de la línea (número, artículo, SKU) y el total de unidades del grupo
// los gestiona el propio pivote.
function TPresentacionPivoteVenta.EsCampoHostEditable(
  const ACampo: string): Boolean;
var
  oCol: TcxGridDBColumn;
begin
  Result := False;
  if (FCfg.View <> nil) and (ACampo <> '') and
     (not SameText(ACampo, FCfg.FieldLinea)) and
     (not SameText(ACampo, FCfg.FieldArt)) and
     (not SameText(ACampo, FCfg.FieldSku)) and
     (not SameText(ACampo, FCfg.CampoArticuloHost)) and
     (not SameText(ACampo, FCfg.FieldTotalUdsGrupo)) and
     (not SameText(ACampo, FCfg.FieldImporteLinea)) then
  begin
    oCol := FCfg.View.GetColumnByFieldName(ACampo);
    Result := (oCol <> nil) and (oCol <> FColLineaVista) and
              (oCol <> FColArticulo) and oCol.Options.Editing;
  end;
end;

procedure TPresentacionPivoteVenta.VistaCampoEditado(ALineaVista: Integer;
  AField: TField);
var
  iLineaBase: Integer;
begin
  if (not (FActualizandoGrid or FEdicionSuspendida)) and
     Assigned(FCall.AlEditarCampoHost) and
     EsCampoHostEditable(AField.FieldName) then
  begin
    iLineaBase := FModelo.ObtenerLineaBase(ALineaVista);
    if iLineaBase > 0 then
      FCall.AlEditarCampoHost(iLineaBase, AField.FieldName,
                              AField.Value);
  end;
end;

function TPresentacionPivoteVenta.TallaAvDesdeColumna(ALineaBase: Integer;
  ACol: TcxGridColumn; out AIdAv: Integer): Boolean;
begin
  // Recibe la linea BASE, no la de vista: resolverla otra vez confundia
  // la base 100 con la vista de la linea 10 (10 * 10) y la celda de la
  // linea 0100 se pintaba con las tallas de otro grupo (FZ-ISSUE-109).
  Result := False;
  AIdAv := 0;
  if (ACol <> nil) and EsColumnaTalla(ACol) then
    Result := FModelo.TallaAvEnPosicion(ALineaBase, ACol.Tag, AIdAv);
end;

function TPresentacionPivoteVenta.BuscarColumnaTallaDesde(ALineaBase,
  AIndiceInicial: Integer; out ACol: TcxGridColumn): Boolean;
var
  i, iIdAv: Integer;
begin
  Result := False;
  ACol := nil;
  i := AIndiceInicial;
  if i < 0 then
    i := 0;
  while (not Result) and (i <= High(FColumnasTallas)) do
  begin
    if (FColumnasTallas[i] <> nil) and FColumnasTallas[i].Visible and
       FModelo.TallaAvEnPosicion(ALineaBase,
                                 FColumnasTallas[i].Tag, iIdAv) then
    begin
      ACol := FColumnasTallas[i];
      Result := True;
    end;
    Inc(i);
  end;
end;

function TPresentacionPivoteVenta.BuscarRecordPorLineaVista(
  ALineaVista: Integer; out ARecordIndex: Integer): Boolean;
var
  oColLinea: TcxGridColumn;
  i, iLinea: Integer;
  vLinea: Variant;
begin
  Result := False;
  ARecordIndex := -1;
  oColLinea := nil;
  if FCfg.View <> nil then
  begin
    oColLinea :=
      FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
    if oColLinea = nil then
      oColLinea := FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
  end;
  if oColLinea <> nil then
  begin
    i := 0;
    while (not Result) and
          (i < FCfg.View.DataController.RecordCount) do
    begin
      vLinea := FCfg.View.DataController.Values[i, oColLinea.Index];
      iLinea := StrToIntDef(VarToStr(vLinea), 0);
      if iLinea = ALineaVista then
      begin
        ARecordIndex := i;
        Result := True;
      end;
      Inc(i);
    end;
  end;
end;

function TPresentacionPivoteVenta.ValorEditor(ASender: TObject;
  AValorFallback: Variant): Double;
var
  vValor: Variant;
begin
  Result := 0;
  vValor := AValorFallback;
  if (VarIsNull(vValor) or VarIsEmpty(vValor) or
      VarIsClear(vValor)) and (ASender is TcxCustomEdit) then
    vValor := TcxCustomEdit(ASender).EditingValue;
  if (VarIsNull(vValor) or VarIsEmpty(vValor) or
      VarIsClear(vValor)) and (ASender is TcxCustomEdit) then
    vValor := TcxCustomEdit(ASender).EditValue;
  if not (VarIsNull(vValor) or VarIsEmpty(vValor) or
          VarIsClear(vValor)) then
  begin
    if VarIsNumeric(vValor) then
      Result := vValor
    else
      Result := StrToFloatDef(VarToStr(vValor), 0);
  end;
end;

procedure TPresentacionPivoteVenta.ViewEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  iLinea, iIdAv: Integer;
begin
  if EsColumnaTalla(AItem) then
  begin
    iLinea := LineaDesdeRecord(Sender.Controller.FocusedRecord);
    AAllow := TallaAvDesdeColumna(FModelo.ObtenerLineaBase(iLinea),
                                  TcxGridColumn(AItem), iIdAv);
  end
  else if AItem = FColArticulo then
  begin
    iLinea := LineaDesdeRecord(Sender.Controller.FocusedRecord);
    AAllow := (iLinea = 0) or
              (FModelo.BandaDesdeLinea(iLinea) = bpvPedida);
  end;
end;

procedure TPresentacionPivoteVenta.PropiedadesCantidadEdicion(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  oGrupo: TGrupoPivoteVenta;
  oPropiedades: TcxCurrencyEditProperties;
  iLineaBase, iDecimales: Integer;
begin
  if (ARecord <> nil) and
     (AProperties is TcxCurrencyEditProperties) then
  begin
    iLineaBase := FModelo.ObtenerLineaBase(LineaDesdeRecord(ARecord));
    oGrupo := Default(TGrupoPivoteVenta);
    FModelo.Grupo(iLineaBase, oGrupo);
    iDecimales := 3;
    if Assigned(FCfg.UnidadesMedida) then
      iDecimales := FCfg.UnidadesMedida.Decimales(oGrupo.TipoCantidad);
    // No modificar la columna durante GetPropertiesForEdit: el cambio
    // notifica a la rejilla y puede destruir el editor que está abriendo.
    if FPropiedadesCantidad = nil then
      FPropiedadesCantidad := TcxCurrencyEditProperties.Create(nil);
    FPropiedadesCantidad.Assign(Sender.Properties);
    oPropiedades := FPropiedadesCantidad;
    oPropiedades.DecimalPlaces := iDecimales;
    oPropiedades.DisplayFormat := '#,##0';
    if iDecimales > 0 then
      oPropiedades.DisplayFormat := '#,##0.' +
        StringOfChar('0', iDecimales);
    AProperties := oPropiedades;
  end;
end;

procedure TPresentacionPivoteVenta.EditorSalir(Sender: TObject);
begin
  if Assigned(FCall.AlSalirEdicion) then
    FCall.AlSalirEdicion(Sender);
end;

procedure TPresentacionPivoteVenta.ViewInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  oRec: TcxCustomGridRecord;
  iLinea, iLineaBase, iIdAv: Integer;
  iClave: Int64;
  oBanda: TBandaPivoteVenta;
  rValor: Double;
begin
  if Assigned(FCall.AlEntrarEdicion) then
    FCall.AlEntrarEdicion(AEdit);
  if EsColumnaTalla(AItem) and (Sender <> nil) and (AEdit <> nil) then
  begin
    oRec := Sender.Controller.FocusedRecord;
    iLinea := LineaDesdeRecord(oRec);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    oBanda := FModelo.BandaDesdeLinea(iLinea);
    if FModelo.TallaAvEnPosicion(iLineaBase,
         TcxGridColumn(AItem).Tag, iIdAv) then
    begin
      iClave := ClaveCeldaPivoteVenta(iLineaBase, iIdAv);
      rValor := FModelo.ValorCantidadBanda(iClave, oBanda);
      if Abs(rValor) > 0.000001 then
        AEdit.EditValue := rValor
      else
        AEdit.EditValue := Null;
    end;
  end;
  if AEdit is TWinControl then
    THackWinControl(AEdit).OnExit := EditorSalir;
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

procedure TPresentacionPivoteVenta.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  sEntrada: string;
begin
  if (AItem = FColArticulo) and
     ((Key = VK_F3) or
      ((Key = VK_RETURN) and (ssCtrl in Shift))) then
  begin
    Key := 0;
    ArticuloButtonClick(AEdit, 0);
  end
  else if (Key = VK_RETURN) and
          GestionarEnterAAlbaranar(Sender, AItem) then
    Key := 0
  else if (Key = VK_RETURN) and (AItem = FColArticulo) then
  begin
    sEntrada := Trim(VarToStr(AEdit.EditingValue));
    if sEntrada <> '' then
      Sender.Controller.EditingController.HideEdit(True);
    Key := 0;
  end;
end;

function TPresentacionPivoteVenta.GestionarEnterAAlbaranar(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem): Boolean;
var
  oColDest, oColLinea: TcxGridColumn;
  oRec: TcxCustomGridRecord;
  iLinea, iLineaBase, iLineaVistaDest, iTagDest: Integer;
  iRecAct, iRecDest, iRec, iLineaVista, iLineaBaseDest: Integer;
  vLinea: Variant;
  bHayDestino: Boolean;
begin
  Result := False;
  bHayDestino := False;
  iLineaVistaDest := 0;
  iTagDest := 0;
  if (Sender <> nil) and EsColumnaTalla(AItem) then
  begin
    oRec := Sender.Controller.FocusedRecord;
    iLinea := LineaDesdeRecord(oRec);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    if (iLineaBase > 0) and
       (FModelo.BandaDesdeLinea(iLinea) = bpvEntregada) then
    begin
      Result := True;
      if BuscarColumnaTallaDesde(iLineaBase,
           TcxGridColumn(AItem).Tag, oColDest) then
      begin
        iLineaVistaDest := iLinea;
        iTagDest := oColDest.Tag;
        bHayDestino := True;
      end
      else
      begin
        oColLinea :=
          FCfg.View.GetColumnByFieldName(CAMPO_LINEA_VISTA_PIVOTE);
        if oColLinea = nil then
          oColLinea :=
            FCfg.View.GetColumnByFieldName(FCfg.FieldLinea);
        if oColLinea <> nil then
        begin
          iRecAct := Sender.DataController.FocusedRecordIndex;
          iRec := iRecAct + 1;
          while (not bHayDestino) and
                (iRec < Sender.DataController.RecordCount) do
          begin
            vLinea := Sender.DataController.Values[iRec,
                                                   oColLinea.Index];
            iLineaVista := StrToIntDef(VarToStr(vLinea), 0);
            iLineaBaseDest := FModelo.ObtenerLineaBase(iLineaVista);
            if (iLineaBaseDest > 0) and
               (FModelo.BandaDesdeLinea(iLineaVista) =
                bpvEntregada) and
               BuscarColumnaTallaDesde(iLineaBaseDest, 0,
                                       oColDest) then
            begin
              iLineaVistaDest := iLineaVista;
              iTagDest := oColDest.Tag;
              bHayDestino := True;
            end;
            Inc(iRec);
          end;
        end;
      end;
      if Sender.Controller.EditingController.IsEditing then
        Sender.Controller.EditingController.HideEdit(True);
      if bHayDestino and
         BuscarRecordPorLineaVista(iLineaVistaDest, iRecDest) then
      begin
        Sender.DataController.FocusedRecordIndex := iRecDest;
        if (iTagDest > 0) and
           (iTagDest <= Length(FColumnasTallas)) then
        begin
          Sender.Controller.FocusedItem :=
            FColumnasTallas[iTagDest - 1];
          try
            Sender.Controller.EditingController.ShowEdit;
          except
            on E: EInvalidOperation do
              // Ruido del editor inplace; queda en el log.
              FCall.AlLogWarning(
                'PivotePresentacion.GestionarEnterAAlbaranar: ' +
                'ShowEdit ignorado: ' + E.Message);
          end;
        end;
      end;
    end;
  end;
end;

procedure TPresentacionPivoteVenta.ViewFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
var
  iLineaVista: Integer;
begin
  if not FActualizandoGrid then
  begin
    iLineaVista := LineaDesdeRecord(AFocusedRecord);
    if Assigned(FCall.AlLineaFocada) then
      FCall.AlLineaFocada(FModelo.ObtenerLineaBase(iLineaVista));
  end;
  ActualizarCaptionsLineaActiva;
end;

procedure TPresentacionPivoteVenta.CustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  oCol: TcxGridColumn;
  oGrupo: TGrupoPivoteVenta;
  oCelda: TCeldaPivoteVenta;
  iLinea, iLineaBase, iIdAv: Integer;
  iClave: Int64;
  rValor: Double;
  oBanda: TBandaPivoteVenta;
  sValorColor: string;
begin
  ADone := False;
  if (AViewInfo.Item is TcxGridColumn) and
     (AViewInfo.GridRecord <> nil) then
  begin
    oCol := TcxGridColumn(AViewInfo.Item);
    iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    if oCol = FColTipoCantidad then
    begin
      PintarCeldaTipoCantidad(ACanvas, AViewInfo);
      ADone := True;
    end
    else if oCol = FColColor then
    begin
      FModelo.Grupo(iLineaBase, oGrupo);
      sValorColor := oGrupo.ColorTexto;
      if sValorColor = '' then
        sValorColor := oGrupo.ColorCodigo;
      if PintarCeldaSwatchArticuloSiAplica(
           FCfg.Conexion, ACanvas, AViewInfo, oGrupo.Articulo,
           sValorColor, nil) then
        ADone := True;
    end
    else if EsColumnaTalla(oCol) then
    begin
      if TallaAvDesdeColumna(iLineaBase, oCol, iIdAv) then
      begin
        oBanda := FModelo.BandaDesdeLinea(iLinea);
        iClave := ClaveCeldaPivoteVenta(iLineaBase, iIdAv);
        rValor := FModelo.ValorCantidadBanda(iClave, oBanda);
        FModelo.Celda(iClave, oCelda);
        FModelo.Grupo(iLineaBase, oGrupo);
        PintarCeldaTallaCantidad(ACanvas, AViewInfo, rValor, oBanda,
                                 oCelda.Pedida > 0,
                                 TallaFueraDeRotulo(iLineaBase, oCol),
                                 oGrupo.TipoCantidad);
        ADone := True;
      end
      else
      begin
        ACanvas.Brush.Color := $00E8E8E8;
        ACanvas.FillRect(AViewInfo.Bounds);
        ADone := True;
      end;
    end;
  end;
end;

function TPresentacionPivoteVenta.TallaFueraDeRotulo(ALineaBase: Integer;
  ACol: TcxGridColumn): string;
var
  oGrupo: TGrupoPivoteVenta;
  aPosiciones: TValoresTallaPivoteVenta;
begin
  // Los rotulos de las columnas siguen a la linea con el foco. Una fila
  // de otro tallaje devuelve su propia talla en esa posicion para
  // pintarla dentro de la celda (FZ-ISSUE-109); '' si coincide.
  Result := '';
  if (ACol <> nil) and (ACol.Tag >= 1) and
     FModelo.Grupo(ALineaBase, oGrupo) and
     (not oGrupo.SinTalla) and (oGrupo.IdAc <> 0) then
  begin
    aPosiciones := FModelo.PosicionesConjunto(oGrupo.IdAc);
    if (ACol.Tag <= Length(aPosiciones)) and
       (aPosiciones[ACol.Tag - 1].Valor <> ACol.Caption) then
      Result := aPosiciones[ACol.Tag - 1].Valor;
  end;
end;

// FZ-ISSUE-211: con la unidad conocida, siempre sus decimales (125,50 m;
// 0,00 en las bandas de servicio); si no, formato general.
function TPresentacionPivoteVenta.TextoCantidadCelda(AValor: Double;
  const AUnidad: string): string;
var
  iDecimales: Integer;
begin
  if Assigned(FCfg.UnidadesMedida) and
     (FCfg.UnidadesMedida.Info(AUnidad) <> nil) then
  begin
    iDecimales := FCfg.UnidadesMedida.Decimales(AUnidad);
    if iDecimales > 0 then
      Result := FormatFloat('#,##0.' + StringOfChar('0', iDecimales),
        AValor)
    else
      Result := FormatFloat('#,##0', AValor);
  end
  else
    Result := FormatFloat('#,##0.##', AValor);
end;

procedure TPresentacionPivoteVenta.PintarCeldaTallaCantidad(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  AValor: Double; ABanda: TBandaPivoteVenta; AMostrarCero: Boolean;
  const ATalla, AUnidad: string);
var
  oRectTexto: TRect;
  sTexto: string;
  cColorTexto: TColor;
begin
  if Abs(AValor) > 0.000001 then
    sTexto := TextoCantidadCelda(AValor, AUnidad)
  else if (ABanda <> bpvPedida) and AMostrarCero then
    sTexto := TextoCantidadCelda(0, AUnidad)
  else
    sTexto := '';
  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(AViewInfo.Bounds);
  ACanvas.Font.Assign(AViewInfo.Params.Font);
  if AViewInfo.GridRecord.Selected then
    ACanvas.Font.Color := AViewInfo.Params.TextColor
  else
  begin
    case ABanda of
      bpvEntregada:
        ACanvas.Font.Color := clGreen;
      bpvPendiente:
        ACanvas.Font.Color := clBlue;
    else
      ACanvas.Font.Color := clWindowText;
    end;
  end;
  if ABanda <> bpvPedida then
    ACanvas.Font.Style := [fsBold];
  oRectTexto := AViewInfo.Bounds;
  InflateRect(oRectTexto, -4, 0);
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(sTexto), Length(sTexto), oRectTexto,
           DT_RIGHT or DT_VCENTER or DT_SINGLELINE);
  if ATalla <> '' then
  begin
    // Talla propia de la fila, pequena y atenuada a la izquierda.
    cColorTexto := ACanvas.Font.Color;
    ACanvas.Font.Style := [];
    ACanvas.Font.Size := ACanvas.Font.Size - 2;
    if not AViewInfo.GridRecord.Selected then
      ACanvas.Font.Color := clGrayText;
    DrawText(ACanvas.Handle, PChar(ATalla), Length(ATalla), oRectTexto,
             DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    ACanvas.Font.Color := cColorTexto;
  end;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TPresentacionPivoteVenta.PintarCeldaTipoCantidad(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo);
var
  oBounds, oRectTexto: TRect;
  iFontHeight: Integer;
  cFontColor: TColor;
  fsFontStyle: TFontStyles;
  iLinea: Integer;
  oBanda: TBandaPivoteVenta;
  sTexto: string;
begin
  iLinea := LineaDesdeRecord(AViewInfo.GridRecord);
  oBanda := FModelo.BandaDesdeLinea(iLinea);
  sTexto := FModelo.TextoTipoCantidad(
    FModelo.ObtenerLineaBase(iLinea), oBanda);
  case oBanda of
    bpvEntregada:
      ACanvas.Brush.Color := $00E0FFE0;
    bpvPendiente:
      ACanvas.Brush.Color := $00C4E1FF;
  else
    ACanvas.Brush.Color := $00F6F1E8;
  end;
  ACanvas.FillRect(AViewInfo.Bounds);
  oBounds := AViewInfo.Bounds;
  oRectTexto := Rect(oBounds.Left + 4, oBounds.Top,
                     oBounds.Right - 2, oBounds.Bottom);
  InflateRect(oRectTexto, 0, -1);
  iFontHeight := ACanvas.Font.Height;
  cFontColor := ACanvas.Font.Color;
  fsFontStyle := ACanvas.Font.Style;
  try
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Style := [fsBold];
    case oBanda of
      bpvEntregada:
        ACanvas.Font.Color := clGreen;
      bpvPendiente:
        ACanvas.Font.Color := clBlue;
    else
      ACanvas.Font.Color := clWindowText;
    end;
    DrawText(ACanvas.Handle, PChar(sTexto), Length(sTexto),
             oRectTexto, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  finally
    ACanvas.Font.Height := iFontHeight;
    ACanvas.Font.Color := cFontColor;
    ACanvas.Font.Style := fsFontStyle;
  end;
  ACanvas.Brush.Style := bsSolid;
end;

procedure TPresentacionPivoteVenta.ArticuloButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(FCall.AlBuscarArticulo) then
  begin
    if FCall.AlBuscarArticulo() and
       FCfg.View.Controller.EditingController.IsEditing then
      try
        FCfg.View.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          // Ruido del editor inplace; queda en el log.
          FCall.AlLogWarning(
            'PivotePresentacion.ArticuloButtonClick: HideEdit ' +
            'ignorado: ' + E.Message);
      end;
  end;
end;

// El editor vuelve a validar al perder el foco o al pulsar «Añadir
// línea» con el texto ya resuelto. Resolverlo de nuevo sumaba una
// unidad a la línea del SKU (lógica de lector) y la grababa
// (FZ-ISSUE-070). Solo una fila de grupo con ese mismo artículo cuenta
// como sin cambios; en la fila de alta el lector sigue sumando.
function TPresentacionPivoteVenta.EsArticuloDeFilaFocada(
  const AEntrada: string): Boolean;
var
  oRec: TcxCustomGridRecord;
begin
  Result := False;
  if (FCfg.View <> nil) and (FColArticulo <> nil) then
  begin
    oRec := FCfg.View.Controller.FocusedRecord;
    if (oRec <> nil) and (LineaDesdeRecord(oRec) <> 0) then
      Result := SameText(AEntrada,
        Trim(VarToStr(oRec.Values[FColArticulo.Index])));
  end;
end;

procedure TPresentacionPivoteVenta.ArticuloValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sEntrada, sTextoLinea: string;
  bCancelada: Boolean;
begin
  if not (Error or FActualizandoGrid or FEdicionSuspendida) then
  begin
    sEntrada := Trim(VarToStr(DisplayValue));
    if (sEntrada <> '') and
       (not EsArticuloDeFilaFocada(sEntrada)) and
       Assigned(FCall.AlResolverEntradaEditor) then
    begin
      Error := not FCall.AlResolverEntradaEditor(sEntrada,
                 sTextoLinea, bCancelada);
      if Error and bCancelada then
      begin
        // Selector de un atributo no pivotado cancelado por el usuario:
        // descartar la entrada sin rotular "no encontrado".
        Error := False;
        DisplayValue := sTextoLinea;
      end
      else if not Error then
        DisplayValue := sTextoLinea;
    end;
    if Error then
      ErrorText := SErrorArticuloSkuNoEncontradoSinDetalle;
  end;
end;

procedure TPresentacionPivoteVenta.CeldaTallaValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  oRec: TcxCustomGridRecord;
  oCol: TcxGridColumn;
  iLinea, iLineaBase, iIdAv: Integer;
  oBanda: TBandaPivoteVenta;
  vAnterior: Variant;
begin
  if not (Error or FActualizandoGrid or FEdicionSuspendida) then
  begin
    oRec := FCfg.View.Controller.FocusedRecord;
    if FCfg.View.Controller.FocusedItem is TcxGridColumn then
      oCol := TcxGridColumn(FCfg.View.Controller.FocusedItem)
    else
      oCol := nil;
    iLinea := LineaDesdeRecord(oRec);
    iLineaBase := FModelo.ObtenerLineaBase(iLinea);
    oBanda := FModelo.BandaDesdeLinea(iLinea);
    if (oCol <> nil) and (oRec <> nil) and
       FModelo.TallaAvEnPosicion(iLineaBase, oCol.Tag, iIdAv) and
       Assigned(FCall.AlEditarCantidad) then
    begin
      // En OnValidate el registro aún tiene el valor anterior: si la
      // cantidad se rechaza, el editor lo recupera (FZ-ISSUE-255).
      vAnterior := oRec.Values[oCol.Index];
      if not FCall.AlEditarCantidad(
               ClaveCeldaPivoteVenta(iLineaBase, iIdAv),
               ValorEditor(Sender, DisplayValue), oBanda) then
      begin
        // El editor valida un texto: una celda que estaba vacía se
        // recupera como texto vacío, no como nulo (FZ-ISSUE-413: el nulo
        // daba EVariantTypeCastError al cerrar el editor).
        if VarIsNull(vAnterior) or VarIsEmpty(vAnterior) then
          DisplayValue := ''
        else
          DisplayValue := vAnterior;
      end;
    end;
  end;
end;

end.
