{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasPresentacion                                   }
{    Tipo:       Librería (presentación)                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Colaborador visual del modo tallas: columnas, editores, foco, dibujo,     }
{    captions, temporizadores y apertura del distribuidor. Conoce VCL y        }
{    DevExpress; no contiene SQL ni decide reglas de negocio.                  }
{******************************************************************************}
unit inLibModoTallasPresentacion;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.StrUtils, Data.DB, Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics,
  cxGraphics, cxEdit, cxTextEdit, cxDropDownEdit, cxCurrencyEdit,
  cxDataStorage, cxGrid, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxNavigator,
  inLibColumnasSkuIntf, inLibGridTallasInline,
  inLibModoTallasIntf, inLibModoTallasBuscador,
  inLibDistribuidorTallas;

type
  TEstadoNavegadorModoTallas = record
    AlClickOriginal : TcxNavigatorButtonClickEvent;
    BotonesVisibles: array[0..NavigatorButtonCount - 1] of Boolean;
    VisibleOriginal: Boolean;
    AnadirOriginal : Boolean;
    Instalado      : Boolean;
  end;
  TPresentacionModoTallas = class
  private
    FConfig: TConfigColumnasSku;
    FCfgTallas: TGridTallasConfig;
    FGestor: TGestorGridTallas;
    FBuscador: TBuscadorSkusTallas;
    FLineas: ILineasPresentacionTallas;
    FPersistencia: IPersistenciaPresentacionTallas;
    FColArticulo: TcxGridDBColumn;
    // Columnas de atributos NO talla (color, temporada...).
    FColAtributo: array[1..5] of TcxGridDBColumn;
    // Resolucion diferida del Enter en la celda de articulo.
    FTimerResolve: TTimer;
    // Carga inicial de celdas DIFERIDA (timer 1ms): el host anyade sus
    // columnas DESPUES de Construir y crear columnas en el view resetea
    // los Values[] no-bound; cargando en el siguiente tick, todas las
    // columnas ya existen y las cantidades no se pierden.
    FTimerCarga: TTimer;
    // Recarga de celdas DIFERIDA (1ms): post y scroll repintan el grid
    // DESPUES de sus eventos; recargando en el siguiente tick, la
    // recarga siempre es lo ultimo y no la pisa ningun repintado.
    FTimerRecarga: TTimer;
    FEntradaPend: string;
    FRegistro: TRegistroTallas;
    FOnResolverEntrada: TEntradaElegidaTallas;
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    FNavegador: TEstadoNavegadorModoTallas;
    // Guardia de reentrada del modal distribuidor (OnEditing puede
    // dispararse varias veces mientras el modal se abre).
    FDistribAbierto: Boolean;
    procedure Registrar(const ATexto: string);
    procedure CrearColumnaArticulo;
    procedure CrearColumnasAtributo;
    procedure CrearColumnasTalla;
    procedure CrearColumnasOcultas;
    procedure EngancharEventosVista;
    procedure InstalarNavegador;
    procedure RestaurarNavegador;
    procedure NavegadorButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
    function EsAltaVaciaPendiente: Boolean;
    procedure EditorSalir(Sender: TObject);
    procedure VistaInitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure VistaEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    procedure VistaEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure ArticuloGetProperties(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure AtributoCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure CeldaTallaCambiada(Sender: TObject);
    procedure FocoLineaCambiado(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    // Restaura el EnterAsTab al SALIR de la columna del combo: el
    // OnExit del editor in-place no es fiable con AlwaysShowEditor.
    procedure FocoItemCambiado(Sender: TcxCustomGridTableView;
      APrevFocusedItem, AFocusedItem: TcxCustomGridTableItem);
    procedure TimerResolveTimer(Sender: TObject);
    procedure TimerCargaTimer(Sender: TObject);
    procedure TimerRecargaTimer(Sender: TObject);
    procedure EntradaElegida(const AEntrada: string);
    // El gestor rotula las columnas sobrantes con el generico
    // 'Talla N': aqui se dejan con un punto — solo se pinta la talla.
    procedure LimpiarCaptionsGenericas;
    procedure EnfocarColumnaPorCampo(const ACampo: string);
    procedure AbrirDistribuidorLinea;
    function CrearTemporizador(AIntervalo: Integer;
      AEvento: TNotifyEvent): TTimer;
  public
    constructor Create(const AConfig: TConfigColumnasSku;
      const ACfgTallas: TGridTallasConfig;
      const ALineas: ILineasPresentacionTallas;
      const APersistencia: IPersistenciaPresentacionTallas;
      const APersistenciaInline: IPersistenciaGridTallasInline;
      const ABusqueda: IBusquedaSkusTallas; ARegistro: TRegistroTallas);
    destructor Destroy; override;
    // Crea las columnas del modo y engancha los eventos de la vista.
    procedure Construir;
    // El gestor del pivote se crea con las columnas ya montadas.
    procedure CrearGestor;
    // Carga visual DIFERIDA: totales, reposicion y celdas, en ese orden.
    procedure ProgramarCargaInicial;
    procedure ArmarRecarga(Sender: TObject);
    procedure MostrarColumnasAtributo(
      const AValores, ANombres: TValoresAttrTallas);
    procedure MostrarEditor;
    procedure CerrarEditorTrasResolver;
    procedure EnfocarTrasResolver(AConTalla: Boolean);
    procedure RefrescarLineaActual(ALinea: Integer);
    procedure ValidarSistemaSeleccionado;
    procedure EstablecerAlmacenStock(const AValor: string);
    // En distribuido SIEMPRE hay almacen por defecto: si el documento
    // no lo trae, se toma el primer almacen activo estandar de
    // fza_almacenes (avisando); sin almacenes definidos -> excepcion.
    procedure AsegurarAlmacenDefecto;
    function AlmacenStock: string;
    property Gestor: TGestorGridTallas read FGestor;
    property OnResolverEntrada: TEntradaElegidaTallas
      read FOnResolverEntrada write FOnResolverEntrada;
    property OnEntrarEdicion: TNotifyEvent read FOnEntrarEdicion
                                           write FOnEntrarEdicion;
    property OnSalirEdicion: TNotifyEvent read FOnSalirEdicion
                                          write FOnSalirEdicion;
  end;

implementation

uses
  dxCoreGraphics, inLibMsgArticulos;

type
  // Acceso a OnExit (protegido en TWinControl) de los editores
  // in-place.
  THackWinControl = class(TWinControl)
  end;

constructor TPresentacionModoTallas.Create(
  const AConfig: TConfigColumnasSku;
  const ACfgTallas: TGridTallasConfig;
  const ALineas: ILineasPresentacionTallas;
  const APersistencia: IPersistenciaPresentacionTallas;
  const APersistenciaInline: IPersistenciaGridTallasInline;
  const ABusqueda: IBusquedaSkusTallas; ARegistro: TRegistroTallas);
begin
  inherited Create;
  FConfig := AConfig;
  FCfgTallas := ACfgTallas;
  FCfgTallas.Persistencia := APersistenciaInline;
  FLineas := ALineas;
  FPersistencia := APersistencia;
  FRegistro := ARegistro;
  FBuscador := TBuscadorSkusTallas.Create(ABusqueda, AConfig.View,
                                          ARegistro);
  FBuscador.OnEntradaElegida := EntradaElegida;
  FBuscador.EstablecerAlmacenStock(AConfig.AlmacenStock);
  FTimerResolve := CrearTemporizador(1, TimerResolveTimer);
  FTimerCarga := CrearTemporizador(1, TimerCargaTimer);
  FTimerRecarga := CrearTemporizador(1, TimerRecargaTimer);
end;

destructor TPresentacionModoTallas.Destroy;
begin
  RestaurarNavegador;
  FreeAndNil(FBuscador);
  FreeAndNil(FTimerRecarga);
  FreeAndNil(FTimerCarga);
  FreeAndNil(FTimerResolve);
  FreeAndNil(FGestor);
  FPersistencia := nil;
  FLineas := nil;
  inherited;
end;

function TPresentacionModoTallas.CrearTemporizador(AIntervalo: Integer;
  AEvento: TNotifyEvent): TTimer;
begin
  Result := TTimer.Create(nil);
  Result.Enabled := False;
  Result.Interval := AIntervalo;
  Result.OnTimer := AEvento;
end;

procedure TPresentacionModoTallas.Registrar(const ATexto: string);
begin
  if Assigned(FRegistro) then
    FRegistro(ATexto);
end;

procedure TPresentacionModoTallas.CrearColumnaArticulo;
begin
  // Columna de articulo (bound); la resolucion va por el validador.
  FColArticulo := FConfig.View.CreateColumn;
  FColArticulo.Caption := SCaptionColArticulo;
  FColArticulo.DataBinding.FieldName := FConfig.Campos.CodigoArt;
  FColArticulo.Width := 140;
  // Sugerencias incrementales en la celda vacia y enfocada.
  FColArticulo.OnGetProperties := ArticuloGetProperties;
end;

procedure TPresentacionModoTallas.CrearColumnasAtributo;
var
  i: Integer;
begin
  // Columnas de atributos no talla (color...), ocultas hasta usarse.
  // Tag negativo para no chocar con las posiciones de talla.
  for i := 1 to 5 do
  begin
    FColAtributo[i] := nil;
    if FConfig.Campos.AttrValor[i] <> '' then
    begin
      FColAtributo[i] := FConfig.View.CreateColumn;
      FColAtributo[i].Tag := -i;
      FColAtributo[i].Caption := '-';
      FColAtributo[i].Visible := False;
      FColAtributo[i].Width := 90;
      FColAtributo[i].Options.Editing := False;
      FColAtributo[i].DataBinding.FieldName :=
        FConfig.Campos.AttrValor[i];
      FColAtributo[i].OnCustomDrawCell := AtributoCustomDrawCell;
    end;
  end;
end;

procedure TPresentacionModoTallas.CrearColumnasTalla;
var
  i: Integer;
  Columna: TcxGridDBColumn;
  Propiedades: TcxCurrencyEditProperties;
begin
  // N columnas de talla no-bound: Tag = posicion 1..N del conjunto.
  // MISMO mecanismo que sesiones de compra (CrearColumnasTallas):
  // ValueTypeClass float — sin el, una columna no-bound de un view DB
  // DESCARTA lo tecleado — y editor Currency con formato entero.
  SetLength(FCfgTallas.ColumnasTallas, FCfgTallas.MaxColumnas);
  for i := 1 to FCfgTallas.MaxColumnas do
  begin
    Columna := FConfig.View.CreateColumn;
    Columna.Tag := i;
    Columna.Caption := '·';
    Columna.Width := 46;
    Columna.Visible := False;
    Columna.DataBinding.ValueTypeClass := TcxFloatValueType;
    Columna.PropertiesClass := TcxCurrencyEditProperties;
    Propiedades := TcxCurrencyEditProperties(Columna.Properties);
    Propiedades.DisplayFormat := '#,##0';
    Propiedades.OnEditValueChanged := CeldaTallaCambiada;
    FCfgTallas.ColumnasTallas[i - 1] := Columna;
  end;
end;

procedure TPresentacionModoTallas.CrearColumnasOcultas;
var
  Columna: TcxGridDBColumn;
begin
  // Columnas OCULTAS bound a LINEA e ID_AC_PIVOT: el gestor las lee del
  // DataController (GetColumnByFieldName) para cargar las celdas fila a
  // fila. Sin ellas, la carga se salta en silencio.
  Columna := FConfig.View.CreateColumn;
  Columna.DataBinding.FieldName := FCfgTallas.FieldLinea;
  Columna.Visible := False;
  Columna.Options.Editing := False;
  Columna := FConfig.View.CreateColumn;
  Columna.DataBinding.FieldName := FCfgTallas.FieldConjuntoPivot;
  Columna.Visible := False;
  Columna.Options.Editing := False;
end;

procedure TPresentacionModoTallas.EngancharEventosVista;
begin
  FConfig.View.OnInitEdit := VistaInitEdit;
  FConfig.View.OnEditKeyDown := VistaEditKeyDown;
  FConfig.View.OnFocusedRecordChanged := FocoLineaCambiado;
  FConfig.View.OnFocusedItemChanged := FocoItemCambiado;
  // Formato distribuido: la edicion inline de celdas de talla se
  // bloquea y las cantidades entran por el modal distribuidor. El
  // almacen por defecto es OBLIGATORIO en este formato.
  if FConfig.Distribuido then
  begin
    AsegurarAlmacenDefecto;
    FConfig.View.OnEditing := VistaEditing;
  end;
  FConfig.View.OptionsBehavior.GoToNextCellOnEnter := True;
  // El Tab (y el Enter convertido por EnterAsTab) avanza ENTRE CELDAS
  // del grid, no al siguiente control del form.
  FConfig.View.OptionsBehavior.FocusCellOnTab := True;
  FConfig.View.OptionsView.ColumnAutoWidth := False;
end;

procedure TPresentacionModoTallas.InstalarNavegador;
var
  i: Integer;
begin
  if (FConfig.View <> nil) and (not FNavegador.Instalado) then
  begin
    FNavegador.AlClickOriginal :=
      FConfig.View.Navigator.Buttons.OnButtonClick;
    FNavegador.VisibleOriginal := FConfig.View.Navigator.Visible;
    FNavegador.AnadirOriginal :=
      FConfig.View.OptionsData.Appending;
    for i := 0 to NavigatorButtonCount - 1 do
      FNavegador.BotonesVisibles[i] :=
        FConfig.View.Navigator.Buttons[i].Visible;
    FConfig.View.Navigator.Visible := True;
    FConfig.View.OptionsData.Appending := True;
    FConfig.View.Navigator.Buttons.First.Visible := True;
    FConfig.View.Navigator.Buttons.Prior.Visible := True;
    FConfig.View.Navigator.Buttons.Next.Visible := True;
    FConfig.View.Navigator.Buttons.Last.Visible := True;
    FConfig.View.Navigator.Buttons.Insert.Visible := False;
    FConfig.View.Navigator.Buttons.Append.Visible := True;
    FConfig.View.Navigator.Buttons.Delete.Visible := True;
    FConfig.View.Navigator.Buttons.PriorPage.Visible := False;
    FConfig.View.Navigator.Buttons.NextPage.Visible := False;
    FConfig.View.Navigator.Buttons.Edit.Visible := False;
    FConfig.View.Navigator.Buttons.Post.Visible := False;
    FConfig.View.Navigator.Buttons.Cancel.Visible := False;
    FConfig.View.Navigator.Buttons.Refresh.Visible := False;
    FConfig.View.Navigator.Buttons.SaveBookmark.Visible := False;
    FConfig.View.Navigator.Buttons.GotoBookmark.Visible := False;
    FConfig.View.Navigator.Buttons.Filter.Visible := False;
    FConfig.View.Navigator.Buttons.OnButtonClick :=
      NavegadorButtonClick;
    FNavegador.Instalado := True;
  end;
end;

procedure TPresentacionModoTallas.RestaurarNavegador;
var
  i: Integer;
begin
  if (FConfig.View <> nil) and FNavegador.Instalado then
  begin
    FConfig.View.Navigator.Buttons.OnButtonClick :=
      FNavegador.AlClickOriginal;
    FConfig.View.Navigator.Visible := FNavegador.VisibleOriginal;
    FConfig.View.OptionsData.Appending := FNavegador.AnadirOriginal;
    for i := 0 to NavigatorButtonCount - 1 do
      FConfig.View.Navigator.Buttons[i].Visible :=
        FNavegador.BotonesVisibles[i];
    FNavegador.Instalado := False;
  end;
end;

function TPresentacionModoTallas.EsAltaVaciaPendiente: Boolean;
var
  oDataSet: TDataSet;
  oCampo: TField;
begin
  Result := False;
  oDataSet := FConfig.Cds;
  if (oDataSet <> nil) and oDataSet.Active and
     (oDataSet.State = dsInsert) then
  begin
    Result := True;
    oCampo := oDataSet.FindField(FConfig.Campos.CodigoArt);
    if (oCampo <> nil) and (Trim(oCampo.AsString) <> '') then
      Result := False;
    oCampo := oDataSet.FindField(FConfig.Campos.CodigoUnidad);
    if (oCampo <> nil) and (Trim(oCampo.AsString) <> '') then
      Result := False;
  end;
end;

procedure TPresentacionModoTallas.NavegadorButtonClick(
  Sender: TObject; AButtonIndex: Integer; var ADone: Boolean);
begin
  if (AButtonIndex in [NBDI_INSERT, NBDI_APPEND]) and
     EsAltaVaciaPendiente then
  begin
    // Al entrar por primera vez el host ya ha creado la linea 0000.
    // Reutilizarla evita que el navegador intente postearla vacia y
    // que el BeforePost aborte la primera pulsacion de '+'.
    ADone := True;
    MostrarEditor;
  end
  else if Assigned(FNavegador.AlClickOriginal) then
    FNavegador.AlClickOriginal(Sender, AButtonIndex, ADone);
end;

procedure TPresentacionModoTallas.Construir;
begin
  // El desplegable de busqueda debe existir antes que su columna.
  FBuscador.Construir;
  FConfig.View.BeginUpdate;
  try
    FConfig.View.ClearItems;
    CrearColumnaArticulo;
    CrearColumnasAtributo;
    CrearColumnasTalla;
    CrearColumnasOcultas;
  finally
    FConfig.View.EndUpdate;
  end;
  EngancharEventosVista;
  InstalarNavegador;
end;

procedure TPresentacionModoTallas.CrearGestor;
begin
  FCfgTallas.Grid := FConfig.View;
  FGestor := TGestorGridTallas.Create(FCfgTallas);
end;

procedure TPresentacionModoTallas.AsegurarAlmacenDefecto;
begin
  if Trim(FConfig.AlmacenStock) = '' then
  begin
    FConfig.AlmacenStock := FPersistencia.PrimerAlmacenEstandar;
    if Trim(FConfig.AlmacenStock) = '' then
      raise Exception.Create(
        SErrorAlmacenDistribucionTallasNoDisponible);
    FBuscador.EstablecerAlmacenStock(FConfig.AlmacenStock);
    Registrar('ModoTallas: sin almacen por defecto; se asume "' +
              FConfig.AlmacenStock + '" (primer almacen activo)');
  end;
end;

procedure TPresentacionModoTallas.EstablecerAlmacenStock(
  const AValor: string);
begin
  FConfig.AlmacenStock := AValor;
  FBuscador.EstablecerAlmacenStock(AValor);
end;

function TPresentacionModoTallas.AlmacenStock: string;
begin
  Result := FConfig.AlmacenStock;
end;

procedure TPresentacionModoTallas.ProgramarCargaInicial;
begin
  // La carga visual (columnas visibles, cantidades y rotulos) se
  // DIFIERE un tick: el host anyade sus columnas tras Construir y eso
  // resetea los Values[] no-bound del DataController.
  FTimerCarga.Enabled := False;
  FTimerCarga.Enabled := True;
end;

procedure TPresentacionModoTallas.TimerCargaTimer(Sender: TObject);
begin
  FTimerCarga.Enabled := False;
  if FGestor <> nil then
  begin
    FGestor.RecalcularMaxColumnas;
    // Totales ANTES de cargar celdas: escribirlos mueve el cursor y
    // repinta filas, lo que limpiaria los Values[] no-bound.
    FLineas.RefrescarTotales(FPersistencia.ConsultarTotalesPorLinea);
    // Reposicionar TAMBIEN antes de cargar: el scroll del First resetea
    // los Values[] no-bound igual que el EnableControls. El foco tras
    // construir suele quedar en la linea en blanco (pivote 0) y los
    // rotulos se quedarian en el generico 'Talla N'.
    if FLineas.ConjuntoPivotActual = 0 then
      FLineas.IrAlPrimero;
    // La carga de celdas, SIEMPRE lo ultimo que toca el grid.
    FGestor.CargarCantidadesTodasLineas;
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
    // Conversion terminada: a partir de aqui el hook AfterPost recarga
    // las celdas tras cada Post del usuario.
    FLineas.TerminarProceso;
    FLineas.NotificarPostsSilenciados;
  end;
end;

procedure TPresentacionModoTallas.ArmarRecarga(Sender: TObject);
begin
  if FGestor <> nil then
  begin
    FTimerRecarga.Enabled := False;
    FTimerRecarga.Enabled := True;
  end;
end;

procedure TPresentacionModoTallas.TimerRecargaTimer(Sender: TObject);
begin
  FTimerRecarga.Enabled := False;
  if FGestor <> nil then
  begin
    FGestor.RecalcularMaxColumnas;
    FGestor.CargarCantidadesTodasLineas;
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
  end;
end;

procedure TPresentacionModoTallas.LimpiarCaptionsGenericas;
var
  i: Integer;
begin
  // Solo se pinta la TALLA en el caption: las columnas que exceden el
  // conjunto de la linea activa quedan con un punto neutro.
  for i := 0 to High(FCfgTallas.ColumnasTallas) do
  begin
    if (FCfgTallas.ColumnasTallas[i] <> nil) and
       StartsText('Talla ', FCfgTallas.ColumnasTallas[i].Caption) then
      FCfgTallas.ColumnasTallas[i].Caption := '·';
  end;
end;

procedure TPresentacionModoTallas.MostrarColumnasAtributo(
  const AValores, ANombres: TValoresAttrTallas);
var
  i, iAncho: Integer;
begin
  for i := 1 to 5 do
  begin
    if (FColAtributo[i] <> nil) and (ANombres[i] <> '') then
    begin
      FColAtributo[i].Caption := ANombres[i];
      FColAtributo[i].Visible := True;
      // Ancho SOLO creciente para que el valor quepa con su swatch.
      // BestFit no sirve aqui: mide sin el cuadrado del custom draw y
      // con el grid a medio pintar ENCOGE la columna. 44 = swatch (18)
      // + separacion (6) + margenes de celda (10) + aire (10).
      iAncho := cxTextWidth(TcxGrid(FConfig.View.Control).Font,
                            AValores[i]) + 44;
      if FColAtributo[i].Width < iAncho then
        FColAtributo[i].Width := iAncho;
    end;
  end;
end;

procedure TPresentacionModoTallas.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TPresentacionModoTallas.VistaInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  // EnterAsTab SOLO se desactiva en la celda de articulo (su Enter
  // resuelve la entrada). En las celdas de talla se deja ACTIVO: el
  // Enter actua como Tab y avanza de talla en talla mientras cada
  // salida de celda persiste su cantidad.
  if AItem = FColArticulo then
  begin
    if Assigned(FOnEntrarEdicion) then
      FOnEntrarEdicion(AEdit);
    THackWinControl(AEdit).OnExit := EditorSalir;
    // Sugerencias en vivo: cada tecleo rearma el debounce que abre el
    // desplegable filtrado (articulo/SKU/barras/ref proveedor).
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange :=
        FBuscador.ComboChange;
    Registrar('ModoTallas.InitEdit articulo: editor=' +
              AEdit.ClassName);
  end;
end;

procedure TPresentacionModoTallas.ArticuloGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vValor: Variant;
  bVacia, bEnfocada: Boolean;
begin
  // Combo de busqueda SOLO en celda de articulo vacia y enfocada; con
  // articulo resuelto, texto plano (patron del modo SKU).
  if (ARecord <> nil) and (FBuscador.Propiedades <> nil) then
  begin
    vValor := ARecord.Values[Sender.Index];
    bVacia := VarIsNull(vValor) or (Trim(VarToStr(vValor)) = '');
    bEnfocada :=
      (FConfig.View.Controller.FocusedRecord = ARecord) and
      (FConfig.View.Controller.FocusedItem = Sender);
    if bVacia and bEnfocada then
      AProperties := FBuscador.Propiedades;
  end;
end;

procedure TPresentacionModoTallas.VistaEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  sEntrada: string;
begin
  // F3 en la celda de articulo: despliega la busqueda incremental
  // filtrada por lo tecleado.
  if (AItem = FColArticulo) and (Key = VK_F3) then
  begin
    Key := 0;
    if AEdit is TcxCustomDropDownEdit then
      TcxCustomDropDownEdit(AEdit).DroppedDown := True;
  end
  // Teclas de texto en la celda de articulo: rearman el debounce de la
  // busqueda incremental. El OnChange del lookup NO es fiable (deja de
  // disparar tras el primer autocompletado); el KeyDown del grid llega
  // SIEMPRE, tecla a tecla.
  else if (AItem = FColArticulo) and
          ((Key = VK_BACK) or (Key = VK_DELETE) or
           ((Key >= Ord('0')) and
            not ((Key >= VK_F1) and (Key <= VK_F24)))) then
    FBuscador.Rearmar
  // Enter en la celda de articulo (tecleo o lector Codigo+CR).
  else if (AItem = FColArticulo) and (Key = VK_RETURN) then
  begin
    // Si el desplegable esta abierto, cerrarlo elige la fila y el Enter
    // no se queda consumido en el dropdown.
    if (AEdit is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      sEntrada := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      sEntrada := Trim(VarToStr(AEdit.EditValue));
    if sEntrada <> '' then
    begin
      Key := 0;
      Registrar('ModoTallas.EditKeyDown: Enter con "' + sEntrada + '"');
      EntradaElegida(sEntrada);
    end;
  end;
end;

procedure TPresentacionModoTallas.EntradaElegida(
  const AEntrada: string);
begin
  // Resolucion diferida (mismo timer que el Enter): consolida la linea
  // y suma la talla en su celda.
  FEntradaPend := AEntrada;
  FTimerResolve.Enabled := False;
  FTimerResolve.Enabled := True;
end;

procedure TPresentacionModoTallas.TimerResolveTimer(Sender: TObject);
var
  sEntrada: string;
begin
  FTimerResolve.Enabled := False;
  sEntrada := FEntradaPend;
  FEntradaPend := '';
  if (sEntrada <> '') and Assigned(FOnResolverEntrada) then
    FOnResolverEntrada(sEntrada);
end;

procedure TPresentacionModoTallas.CerrarEditorTrasResolver;
begin
  if FConfig.View.Controller.EditingController.IsEditing then
    try
      FConfig.View.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        // Ruido del editor inplace; queda constancia en el log.
        if Assigned(FConfig.RegistroLog) then
          FConfig.RegistroLog.RegistrarAviso(
          'ModoTallas.TimerResolve: HideEdit ignorado: ' + E.Message);
    end;
  // Resuelto y editor cerrado: se restaura el EnterAsTab (si el foco
  // vuelve a la celda del combo, InitEdit lo desactiva).
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(nil);
end;

procedure TPresentacionModoTallas.EnfocarTrasResolver(
  AConTalla: Boolean);
begin
  if AConTalla then
  begin
    // Lectura con talla (SKU/barras): la cantidad ya se sumo en su
    // celda. Volvemos a la linea en blanco (si la hay) y dejamos el
    // editor de articulo listo para encadenar lecturas.
    FLineas.IrALineaEnBlanco;
    MostrarEditor;
  end
  // Sin talla en la entrada: si la linea tiene sistema, foco a la
  // primera celda de talla; si no (servicios, gastos...), a la columna
  // de cantidad del documento.
  else if (FLineas.ConjuntoPivotActual > 0) and
          (Length(FCfgTallas.ColumnasTallas) > 0) and
          (FCfgTallas.ColumnasTallas[0] <> nil) and
          FCfgTallas.ColumnasTallas[0].Visible then
    FCfgTallas.ColumnasTallas[0].Focused := True
  else
    EnfocarColumnaPorCampo(FConfig.Campos.Cantidad);
end;

procedure TPresentacionModoTallas.EnfocarColumnaPorCampo(
  const ACampo: string);
var
  i: Integer;
  Columna: TcxGridDBColumn;
begin
  if ACampo <> '' then
    for i := 0 to FConfig.View.ColumnCount - 1 do
    begin
      Columna := FConfig.View.Columns[i];
      if SameText(Columna.DataBinding.FieldName, ACampo) then
        Columna.Focused := True;
    end;
end;

procedure TPresentacionModoTallas.MostrarEditor;
begin
  if (FConfig.View <> nil) and (FColArticulo <> nil) then
  begin
    FColArticulo.Focused := True;
    try
      FConfig.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        // Ruido del editor inplace; queda constancia en el log.
        if Assigned(FConfig.RegistroLog) then
          FConfig.RegistroLog.RegistrarAviso(
          'ModoTallas.MostrarEditor: ShowEdit ignorado: ' + E.Message);
    end;
  end;
end;

procedure TPresentacionModoTallas.VistaEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  // Celdas de talla en distribuido: sin edicion inline; el reparto por
  // almacen entra por el distribuidor. El grid muestra la SUMA (la
  // carga del gestor agrupa por talla sin filtrar almacen).
  if (AItem <> nil) and (AItem.Tag >= 1) and
     (AItem.Tag <= FCfgTallas.MaxColumnas) then
  begin
    AAllow := False;
    if not FDistribAbierto then
      AbrirDistribuidorLinea;
  end;
end;

procedure TPresentacionModoTallas.AbrirDistribuidorLinea;
var
  Parametros: TParametrosDistribuidorTallas;
  Master: TDataSet;
  iLinea, iConjunto: Integer;
begin
  iLinea := FLineas.NumeroLineaActual;
  iConjunto := FLineas.ConjuntoPivotActual;
  if (iLinea > 0) and (iConjunto > 0) and (FGestor <> nil) then
  begin
    FLineas.ConfirmarEdicionPendiente;
    Master := FCfgTallas.SourceMaster.DataSet;
    Parametros := Default(TParametrosDistribuidorTallas);
    Parametros.Conexion := FCfgTallas.Conexion;
    Parametros.Usuario := FCfgTallas.Usuario;
    Parametros.TablaCeldas := FCfgTallas.TablaCeldas;
    Parametros.CampoSerie := FCfgTallas.FieldSerieCel;
    Parametros.CampoNumero := FCfgTallas.FieldNumeroCel;
    Parametros.CampoLinea := FCfgTallas.FieldLineaCel;
    Parametros.CampoFila := FCfgTallas.FieldFilaCel;
    Parametros.CampoAlmacen := FCfgTallas.FieldAlmacenCel;
    Parametros.CampoAtributoValor := FCfgTallas.FieldAvPivotCel;
    Parametros.CampoCantidad := FCfgTallas.FieldCantidadCel;
    Parametros.Serie :=
      Master.FieldByName(FCfgTallas.FieldSerieMaster).AsString;
    Parametros.Numero :=
      Master.FieldByName(FCfgTallas.FieldNumeroMaster).AsString;
    Parametros.Linea := iLinea;
    Parametros.IdConjuntoPivot := iConjunto;
    Parametros.CodigoArticulo := FConfig.Cds.FieldByName(
      FConfig.Campos.CodigoArt).AsString;
    FDistribAbierto := True;
    try
      if FConfig.DistribuidorTallasVisual.Ejecutar(Parametros) then
        RefrescarLineaActual(iLinea);
    finally
      FDistribAbierto := False;
    end;
  end;
end;

procedure TPresentacionModoTallas.RefrescarLineaActual(
  ALinea: Integer);
var
  idxRegistro: Integer;
begin
  // Mismo orden que PersistirCeldaActiva: totales de la linea y recarga
  // de sus celdas, con la carga como ultimo toque.
  if FGestor <> nil then
  begin
    FGestor.RefrescarTotalesLineaActual;
    idxRegistro := FCfgTallas.Grid.Controller.FocusedRecordIndex;
    if idxRegistro >= 0 then
      FGestor.CargarCantidadesUnaLinea(idxRegistro, ALinea);
    if Assigned(FCfgTallas.Grid.Site) then
      FCfgTallas.Grid.Site.Invalidate;
  end;
end;

procedure TPresentacionModoTallas.ValidarSistemaSeleccionado;
begin
  // Tope de tallas (MAX_TALLAS_HORIZONTAL): si el sistema excede
  // MaxColumnas el gestor
  // avisa y limpia el pivot (no pasa a horizontal).
  if FGestor <> nil then
  begin
    if FGestor.ValidarSistemaSeleccionado then
    begin
      FGestor.RecalcularMaxColumnas;
      FGestor.ActualizarCaptionsLineaActiva;
    end;
  end;
end;

procedure TPresentacionModoTallas.CeldaTallaCambiada(Sender: TObject);
begin
  if FGestor <> nil then
    FGestor.PersistirCeldaActiva(Sender);
end;

procedure TPresentacionModoTallas.FocoItemCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  // El EnterAsTab solo esta desactivado MIENTRAS la celda del combo
  // (articulo) tiene el foco; al pasar a cualquier otra columna se
  // restaura y el Enter vuelve a cambiar de control.
  if (APrevFocusedItem = FColArticulo) and Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TPresentacionModoTallas.FocoLineaCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  if FGestor <> nil then
  begin
    FGestor.ActualizarCaptionsLineaActiva;
    LimpiarCaptionsGenericas;
  end;
end;

procedure TPresentacionModoTallas.AtributoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  ColumnaArticulo: TcxGridDBColumn;
  sArticulo, sTexto: string;
begin
  sArticulo := '';
  sTexto := '';
  if (AViewInfo <> nil) and (AViewInfo.GridRecord <> nil) then
  begin
    ColumnaArticulo := FConfig.View.GetColumnByFieldName(
      FConfig.Campos.CodigoArt);
    if ColumnaArticulo <> nil then
      sArticulo := VarToStr(
        AViewInfo.GridRecord.Values[ColumnaArticulo.Index]);
    sTexto := AViewInfo.Text;
  end;
  if Assigned(FConfig.Servicios.Paleta) and
     FConfig.Servicios.Paleta.PintarCeldaArticulo(
       ACanvas, AViewInfo, sArticulo, sTexto) then
    ADone := True;
end;

end.
