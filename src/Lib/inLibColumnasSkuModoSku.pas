{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoSku                                       }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: implementacion de IModoEntradaGrid en modo SKU    }
{    (articulo/color/talla en UNA columna). Una unica columna bound a          }
{    CODIGO_UNIDAD con:                                                        }
{                                                                              }
{      - Busqueda incremental por CODIGO_UNIDAD_SKU: ExtLookupComboBox en      }
{        runtime + consulta en servidor (top-100 por prefijo) + debounce,      }
{        mismo patron que inLibGridArticulos.CrearLookupBusqueda.              }
{      - Si la entrada resuelve a un padre con variaciones, avisa de que       }
{        debe indicarse un SKU completo. La paleta de atributos pertenece      }
{        exclusivamente al modo detallado.                                    }
{      - Swatch de color en la celda del SKU via PintarCeldaSwatchSiAplica     }
{        (prueba con el ultimo segmento tras '/').                             }
{******************************************************************************}
unit inLibColumnasSkuModoSku;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Types, Data.DB, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, cxGraphics, cxEdit,
  cxTextEdit,
  cxDropDownEdit, cxEditRepositoryItems, cxDBExtLookupComboBox, cxGrid,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxNavigator,
  inLibColumnasSkuIntf, inLibArticulosValidadorIntf,
  inLibModoTallasIntf;

type
  TModoEntradaSku = class(TInterfacedObject, IModoEntradaGrid,
    ILecturaModoEntrada)
  private
    FConfig: TConfigColumnasSku;
    FColSku: TcxGridDBColumn;
    FOnResuelto: TSkuResueltoEvent;
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    FAlmacenStock: string;
    // Desplegable de busqueda incremental por CODIGO_UNIDAD_SKU: query +
    // datasource + view en su repositorio + item de edicion combo. Todo en
    // runtime (la lib no tiene .dfm), como inLibGridArticulos.
    FBusqueda: IBusquedaSkusTallas;
    FBusqDs: TDataSource;
    FBusqRepo: TcxGridViewRepository;
    FBusqView: TcxGridDBTableView;
    FBusqColSku: TcxGridDBColumn;
    // Columna OCULTA duplicada del SKU que actua de ListFieldItem del
    // combo, con todo el buscado/filtrado desactivado: el lookup no
    // tiene donde morder y no autocompleta ni deja la lista "pegada"
    // (patron inMtoCajaOpe: dbtvBusqINPUT_BUSQUEDA).
    FBusqColInput: TcxGridDBColumn;
    FEditRepo: TcxEditRepository;
    FRepCombo: TcxEditRepositoryExtLookupComboBoxItem;
    // Debounce del tecleo (como el tmrBusq de inMtoCajaOpe) y resolucion
    // diferida (no tocar el cds mientras el editor in-place se cierra).
    FTimerBusq: TTimer;
    FTimerResolve: TTimer;
    FSkuPend: string;
    FUltimoFiltro: string;
    FAvanzarTrasResolucion: Boolean;
    FAcumularRepetidos: Boolean;
    // FZ-ISSUE-350: trama STX..ETX del lector recogida en la celda de SKU
    // (los documentos sin TLectorDocumento, como inventarios).
    FEnScanner: Boolean;
    FScanBuffer: string;
    FLecturaPendiente: Boolean;
    // OnExit del editor in-place de la celda de SKU: avisa al host para
    // restaurar el EnterAsTab que desactivo al entrar.
    procedure EditorSalir(Sender: TObject);
    // Restaura el EnterAsTab al SALIR de la columna del combo: el
    // OnExit del editor in-place no es fiable con AlwaysShowEditor.
    procedure FocoItemCambiado(Sender: TcxCustomGridTableView;
                               APrevFocusedItem,
                               AFocusedItem: TcxCustomGridTableItem);
    procedure CrearLookupBusqueda;
    // Consulta en servidor el top-100 de SKUs cuyo CODIGO_UNIDAD_SKU
    // empieza por ATexto ('' = primeros 100 por codigo).
    procedure AbrirBusquedaFiltrada(const ATexto: string);
    // Limpia el filtro interno del desplegable (IncSearching + Filter
    // del DataController): sin esto la lista se queda "pegada" a la
    // fila autocompletada aunque la query traiga mas filas. Mismo
    // mecanismo que inMtoCajaOpe.tmrBusqTimer.
    procedure LimpiarFiltroDesplegable;
    // Si el documento YA tiene una linea con ese SKU, suma 1 a su
    // cantidad y devuelve True (la lectura queda consumida sin crear
    // otra linea igual).
    function AcumularLineaExistente(const ACodArt, ASku,
                                    ADesc: string): Boolean;
    procedure ComboBusqInitPopup(Sender: TObject);
    procedure ComboBusqCloseUp(Sender: TObject);
    procedure SkuChange(Sender: TObject);
    procedure TimerBusqTimer(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    // Editor por registro (mismo patron que el desglose): el combo de
    // busqueda incremental SOLO en la celda vacia y enfocada; con SKU
    // ya resuelto, texto plano — un ExtLookup pintaria VACIO cualquier
    // valor que no este en su lista top-100.
    procedure SkuGetProperties(Sender: TcxCustomGridTableItem;
                               ARecord: TcxCustomGridRecord;
                             var AProperties: TcxCustomEditProperties);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem;
                           AEdit: TcxCustomEdit);
    procedure RecogerTramaLector(var Key: Char);
    procedure ViewEditKeyPress(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Char);
    procedure ViewKeyPress(Sender: TObject; var Key: Char);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
                              AItem: TcxCustomGridTableItem;
                              AEdit: TcxCustomEdit; var Key: Word;
                              Shift: TShiftState);
    procedure SkuCustomDrawCell(Sender: TcxCustomGridTableView;
                                ACanvas: TcxCanvas;
                                AViewInfo: TcxGridTableDataCellViewInfo;
                                var ADone: Boolean);
    procedure SkuGetDisplayText(Sender: TcxCustomGridTableItem;
                                ARecord: TcxCustomGridRecord;
                                var AText: string);
    function ValorRecord(ARecord: TcxCustomGridRecord;
                         const ACampo: string): string;
    function SkuTextoRecord(ARecord: TcxCustomGridRecord): string;
    procedure DispararResolucion(const AEntrada: string);
    function LimpiarEntrada(const AEntrada: string): string;
    procedure PonerCampo(const ANombre, AValor: string);
    procedure EscribirLinea(const ACodArt, ASku, ADescripcion: string);
    procedure DesengancharVista;
  public
    constructor Create(const AConfig: TConfigColumnasSku);
    destructor Destroy; override;
    procedure Construir(
      AOnResuelto: TSkuResueltoEvent;
      AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
    procedure Desmontar;
    procedure MostrarEditor;
    procedure BuscarArticulo;
    function ResolverEntrada(const AEntrada: string): Boolean;
    function ResolverLectura(const AEntrada: string): Boolean;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibGridArticulos,
  inLibLineaSku, inLibMsgArticulos;

type
  // Acceso a OnEnter/OnExit (protegidos en TWinControl) de los editores
  // in-place, sin depender de que cada clase cx los re-publique.
  THackWinControl = class(TWinControl);

constructor TModoEntradaSku.Create(const AConfig: TConfigColumnasSku);
begin
  inherited Create;
  FConfig := AConfig;
  FAlmacenStock := AConfig.AlmacenStock;
  if not Assigned(AConfig.Servicios.Busqueda) then
    raise EArgumentNilException.Create('Servicios.Busqueda');
  if not Assigned(AConfig.Servicios.Paleta) then
    raise EArgumentNilException.Create('Servicios.Paleta');
  FBusqueda := AConfig.Servicios.Busqueda.CrearBusqueda;
  FTimerBusq := TTimer.Create(nil);
  FTimerBusq.Enabled := False;
  FTimerBusq.Interval := 350;
  FTimerBusq.OnTimer := TimerBusqTimer;
  FTimerResolve := TTimer.Create(nil);
  FTimerResolve.Enabled := False;
  FTimerResolve.Interval := 1;
  FTimerResolve.OnTimer := TimerResolveTimer;
  FAvanzarTrasResolucion := False;
end;

destructor TModoEntradaSku.Destroy;
begin
  // Desenganchar los eventos del REPOSITORIO antes de liberar nada:
  // liberar FBusqRepo dispara SetView(nil) en las properties del
  // combo, el editor cacheado del grid sincroniza su texto, salta su
  // Change y SkuChange tocaria FTimerBusq ya liberado (AV nil+$50).
  if FRepCombo <> nil then
  begin
    FRepCombo.Properties.OnChange := nil;
    FRepCombo.Properties.OnInitPopup := nil;
    FRepCombo.Properties.OnCloseUp := nil;
  end;
  FreeAndNil(FTimerResolve);
  FreeAndNil(FTimerBusq);
  FreeAndNil(FEditRepo);
  FreeAndNil(FBusqRepo);
  FreeAndNil(FBusqDs);
  FBusqueda := nil;
  inherited;
end;

procedure TModoEntradaSku.EditorSalir(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaSku.FocoItemCambiado(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  // El EnterAsTab solo esta desactivado MIENTRAS la celda del combo
  // tiene el foco; al pasar a otra columna se restaura.
  if (APrevFocusedItem = FColSku) and
     Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

procedure TModoEntradaSku.Desmontar;
begin
  // Sin estado externo que convertir: las lineas del cds YA son la
  // representacion por SKU.
  DesengancharVista;
end;

// FZ-ISSUE-791: los eventos que Construir puso en la vista siguen ahí al
// pasar a otro modo (Tallas horiz.); con el modo ya liberado, Enter en la
// rejilla llamaba a ViewKeyPress de un objeto muerto. Solo se quitan los
// que siguen apuntando a este modo: el siguiente pudo poner los suyos.
// No se llama desde el destructor: al cerrar la ficha la vista puede
// estar ya destruida.
procedure TModoEntradaSku.DesengancharVista;
  function EsMio(const AMetodo: TMethod): Boolean;
  begin
    Result := AMetodo.Data = Pointer(Self);
  end;
begin
  if FConfig.View <> nil then
  begin
    if EsMio(TMethod(FConfig.View.OnInitEdit)) then
      FConfig.View.OnInitEdit := nil;
    if EsMio(TMethod(FConfig.View.OnEditKeyDown)) then
      FConfig.View.OnEditKeyDown := nil;
    if EsMio(TMethod(FConfig.View.OnEditKeyPress)) then
      FConfig.View.OnEditKeyPress := nil;
    if EsMio(TMethod(FConfig.View.OnKeyPress)) then
      FConfig.View.OnKeyPress := nil;
    if EsMio(TMethod(FConfig.View.OnFocusedItemChanged)) then
      FConfig.View.OnFocusedItemChanged := nil;
  end;
end;

procedure TModoEntradaSku.Construir(
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
var
  i: Integer;
  procedure CrearColumnaOculta(const ACampo: string);
  var
    Col: TcxGridDBColumn;
  begin
    if (ACampo <> '') and (FConfig.Cds <> nil) and
       (FConfig.Cds.FindField(ACampo) <> nil) then
    begin
      Col := FConfig.View.CreateColumn;
      Col.DataBinding.FieldName := ACampo;
      Col.Visible := False;
      Col.VisibleForCustomization := False;
    end;
  end;
begin
  FOnResuelto := AOnResuelto;
  FOnEntrarEdicion := AOnEntrarEdicion;
  FOnSalirEdicion := AOnSalirEdicion;
  // El desplegable debe existir antes de crear la columna que lo usa.
  CrearLookupBusqueda;
  FConfig.View.BeginUpdate;
  try
    FConfig.View.ClearItems;
    FColSku := FConfig.View.CreateColumn;
    FColSku.Caption := SCaptionColSkuArtColorTalla;
    FColSku.DataBinding.FieldName := FConfig.Campos.CodigoUnidad;
    FColSku.Width := 260;
    FColSku.OnGetProperties := SkuGetProperties;
    // Swatch del color en la celda (ultimo segmento tras '/'), mismo
    // helper que caja e inventarios.
    FColSku.OnCustomDrawCell := SkuCustomDrawCell;
    // Articulos sin variaciones no tienen SKU: fallback al articulo.
    FColSku.OnGetDisplayText := SkuGetDisplayText;
    CrearColumnaOculta(FConfig.Campos.CodigoArt);
    for i := 1 to 5 do
      CrearColumnaOculta(FConfig.Campos.AttrValor[i]);
  finally
    FConfig.View.EndUpdate;
  end;
  FConfig.View.OnInitEdit := ViewInitEdit;
  // Enter en la celda de SKU resuelve la entrada (tecleo o lector
  // Codigo+CR). Es el evento fiable para la celda del grid.
  FConfig.View.OnEditKeyDown := ViewEditKeyDown;
  // FZ-ISSUE-350: trama del lector en la celda de SKU, en edicion o no.
  FConfig.View.OnEditKeyPress := ViewEditKeyPress;
  FConfig.View.OnKeyPress := ViewKeyPress;
  FConfig.View.OnFocusedItemChanged := FocoItemCambiado;
  FConfig.View.OptionsBehavior.GoToNextCellOnEnter := True;
  FConfig.View.OptionsBehavior.FocusFirstCellOnNewRecord := True;
  // Con DesplazamientoHorizontal las columnas conservan su ancho y el
  // grid se desplaza a la derecha en vez de repartir el ancho.
  FConfig.View.OptionsView.ColumnAutoWidth :=
    not FConfig.DesplazamientoHorizontal;
  FConfig.View.OptionsView.NoDataToDisplayInfoText :=
    SCaptionSinArticulos;
  FConfig.View.Navigator.Visible := True;
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
end;

procedure TModoEntradaSku.CrearLookupBusqueda;
var
  Columna: TcxGridDBColumn;
  Propiedades: TcxExtLookupComboBoxProperties;
begin
  // 1. Query del desplegable. Filtrado EN SERVIDOR: cada tecleo (con
  //    debounce) consulta el top-100 cuyo CODIGO_UNIDAD_SKU empieza por lo
  //    tecleado. Precargar el catalogo entero es inviable con cientos de
  //    miles de SKU (vease inLibGridArticulos.CrearLookupBusqueda).
  FBusqDs := TDataSource.Create(nil);
  FBusqDs.DataSet := FBusqueda.Dataset;
  // 2. View del desplegable, en su repositorio (no en pantalla).
  FBusqRepo := TcxGridViewRepository.Create(nil);
  FBusqView := FBusqRepo.CreateItem(TcxGridDBTableView)
                 as TcxGridDBTableView;
  FBusqView.DataController.DataSource := FBusqDs;
  FBusqView.DataController.KeyFieldNames := 'SKU';
  FBusqView.DataController.DataModeController.GridMode := True;
  // Sin sincronizar el cursor del dataset con la fila enfocada del
  // desplegable (como dbtvBusq de caja).
  FBusqView.DataController.DataModeController.SyncMode := False;
  FBusqView.OptionsView.GroupByBox := False;
  FBusqView.OptionsSelection.CellSelect := False;
  FBusqView.OptionsBehavior.IncSearch := False;
  FBusqColSku := FBusqView.CreateColumn;
  FBusqColSku.Caption := SCaptionColSku;
  FBusqColSku.DataBinding.FieldName := 'SKU';
  FBusqColSku.Width := 220;
  FBusqColInput := FBusqView.CreateColumn;
  FBusqColInput.DataBinding.FieldName := 'INPUT_BUSQUEDA';
  FBusqColInput.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(FBusqColInput.Properties).IncrementalSearch :=
    False;
  FBusqColInput.Visible := False;
  FBusqColInput.Options.Filtering := False;
  FBusqColInput.Options.FilteringPopup := False;
  FBusqColInput.Options.IncSearch := False;
  FBusqColInput.Options.Grouping := False;
  Columna := FBusqView.CreateColumn;
  Columna.Caption := 'Descripción';
  Columna.DataBinding.FieldName := 'DESCRIPCION';
  Columna.Width := 240;
  Columna := FBusqView.CreateColumn;
  Columna.Caption := 'Stock';
  Columna.DataBinding.FieldName := 'STOCK';
  Columna.Width := 60;
  // 3. Item de edicion ExtLookupComboBox sobre ese view.
  FEditRepo := TcxEditRepository.Create(nil);
  FRepCombo := FEditRepo.CreateItem(TcxEditRepositoryExtLookupComboBoxItem)
                 as TcxEditRepositoryExtLookupComboBoxItem;
  Propiedades := FRepCombo.Properties;
  Propiedades.View := FBusqView;
  Propiedades.KeyFieldNames := 'SKU';
  Propiedades.ListFieldItem := FBusqColInput;
  Propiedades.DropDownListStyle := lsEditList;
  Propiedades.AutoSearchOnPopup := False;
  // El dataset ya trae solo coincidencias (filtro en servidor); el
  // filtro incremental cliente se desactiva.
  Propiedades.IncrementalFiltering := False;
  Propiedades.DropDownRows := 15;
  Propiedades.DropDownAutoWidth := True;
  // No abrir al teclear: el desplegable se abre por debounce o F4;
  // si se abriera, las teclas irian al edit del dropdown.
  Propiedades.ImmediateDropDownWhenKeyPressed := False;
  Propiedades.OnInitPopup := ComboBusqInitPopup;
  Propiedades.OnCloseUp := ComboBusqCloseUp;
  // En el repositorio: con AlwaysShowEditor, el hook por editor de
  // InitEdit cae en un clon muerto de las properties.
  Propiedades.OnChange := SkuChange;
end;

procedure TModoEntradaSku.AbrirBusquedaFiltrada(const ATexto: string);
begin
  if Assigned(FBusqueda) then
  begin
    // Siempre: aunque la query ya este abierta con el mismo filtro,
    // el desplegable puede tener filtro interno pegado (autocompletado).
    LimpiarFiltroDesplegable;
    // Reabre solo si cambia el texto o el dataset esta invalidado
    // (cambio de almacen / primera vez).
    if not (FBusqueda.Dataset.Active and (FUltimoFiltro = ATexto)) then
    begin
      Screen.Cursor := crHourGlass;
      FBusqView.BeginUpdate;
      try
        // Desenganchar la vista mientras se recambia la query evita
        // que reaplique su filtro sobre el dataset a medio abrir.
        FBusqView.DataController.DataSource := nil;
        FBusqueda.Aplicar(ATexto, FAlmacenStock);
        FUltimoFiltro := ATexto;
        FBusqView.DataController.DataSource := FBusqDs;
        FBusqView.DataController.Refresh;
      finally
        FBusqView.EndUpdate;
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TModoEntradaSku.LimpiarFiltroDesplegable;
begin
  if FBusqView <> nil then
  begin
    FBusqView.BeginUpdate;
    try
      FBusqView.Controller.IncSearchingText := '';
      FBusqView.DataController.Filter.Clear;
      FBusqView.DataController.Filter.Active := False;
      FBusqView.DataController.Filter.AutoDataSetFilter := False;
      // RESET imprescindible: sin Refresh la vista sigue mostrando el
      // conjunto filtrado viejo aunque el filtro ya este vacio (caja
      // lo hace en repComboBoxPropertiesInitPopup).
      FBusqView.DataController.Refresh;
    finally
      FBusqView.EndUpdate;
    end;
  end;
end;

// Despliegue del combo (F4 / boton / debounce): consulta con el texto que
// haya en el editor ('' = top-100 por codigo).
procedure TModoEntradaSku.ComboBusqInitPopup(Sender: TObject);
var
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  sTexto := '';
  if Sender is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(Sender);
    // Si el combo autocompleto, lo tecleado es lo previo a la seleccion.
    sTexto := Combo.Text;
    if Combo.SelLength > 0 then
      sTexto := Copy(sTexto, 1, Combo.SelStart);
    sTexto := Trim(sTexto);
  end;
  // Con el desplegable abierto el Enter debe llegar al combo, no ser Tab.
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
  AbrirBusquedaFiltrada(sTexto);
end;

// Al cerrar el desplegable con seleccion: resuelve el SKU elegido de forma
// diferida (timer 1ms) para no tocar el cds mientras el editor se cierra.
procedure TModoEntradaSku.ComboBusqCloseUp(Sender: TObject);
var
  Edit: TcxCustomEdit;
  sEntrada: string;
begin
  LimpiarFiltroDesplegable;
  // NO se restaura aqui el EnterAsTab: el foco sigue en la celda de
  // SKU y el siguiente Enter debe llegar al grid (mismo arreglo que
  // inLibGridArticulos). Restauran EditorSalir / FocoItemCambiado.
  if Sender is TcxCustomEdit then
  begin
    Edit := TcxCustomEdit(Sender);
    sEntrada := Trim(VarToStr(Edit.EditValue));
    // Codigo tecleado SIN coincidencias en el desplegable: EditValue
    // queda vacio (el lookup solo lo rellena al elegir de la lista) y
    // la entrada vive en el texto libre del combo. Sin este rescate,
    // cerrar el desplegable vacio descartaba el codigo en silencio y
    // los articulos fuera de catalogo no se podian teclear.
    if (sEntrada = '') and (Edit is TcxCustomTextEdit) and
       Assigned(FBusqueda) and FBusqueda.Dataset.Active and
       FBusqueda.Dataset.IsEmpty then
      sEntrada := Trim(TcxCustomTextEdit(Edit).Text);
    DispararResolucion(sEntrada);
  end;
end;

// OnChange del editor de la celda de SKU: rearma el debounce que abrira el
// desplegable filtrado por lo tecleado.
procedure TModoEntradaSku.SkuChange(Sender: TObject);
begin
  // Guarda: el Change puede saltar en plena destruccion del modo.
  if FTimerBusq <> nil then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end;
end;

// Al saltar el debounce consulta lo tecleado y abre el desplegable. Minimo
// 2 caracteres: el prefijo de SKU acota rapido (empieza por el articulo).
procedure TModoEntradaSku.TimerBusqTimer(Sender: TObject);
var
  Edit: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  FTimerBusq.Enabled := False;
  if FConfig.View.Controller.EditingController.IsEditing then
  begin
    Edit := FConfig.View.Controller.EditingController.Edit;
    if Edit is TcxExtLookupComboBox then
    begin
      Combo := TcxExtLookupComboBox(Edit);
      // Text, no EditingValue (el texto libre no llega alli); y si el
      // combo autocompleto, lo tecleado es lo previo a la seleccion.
      sTexto := Combo.Text;
      if Combo.SelLength > 0 then
        sTexto := Copy(sTexto, 1, Combo.SelStart);
      sTexto := Trim(sTexto);
      if Length(sTexto) >= 2 then
      begin
        AbrirBusquedaFiltrada(sTexto);
        if not Combo.DroppedDown then
          Combo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TModoEntradaSku.SkuGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vVal: Variant;
  bVacia, bEnfocada: Boolean;
begin
  if (ARecord <> nil) and (FRepCombo <> nil) then
  begin
    vVal := ARecord.Values[Sender.Index];
    bVacia := VarIsNull(vVal) or (Trim(VarToStr(vVal)) = '');
    bEnfocada :=
      (FConfig.View.Controller.FocusedRecord = ARecord) and
      (FConfig.View.Controller.FocusedItem = Sender);
    if bVacia and bEnfocada then
      AProperties := FRepCombo.Properties;
  end;
end;

procedure TModoEntradaSku.ViewInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  if AItem = FColSku then
  begin
    // Sugerencias en vivo al teclear en la celda de SKU (debounce).
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange := SkuChange;
    // EnterAsTab fuera mientras se edita la celda: el host engancha
    // Desactivar/Restaurar en OnEntrarEdicion / OnSalirEdicion.
    if Assigned(FOnEntrarEdicion) then
      FOnEntrarEdicion(AEdit);
    THackWinControl(AEdit).OnExit := EditorSalir;
  end;
end;

procedure TModoEntradaSku.ViewEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  sEntrada: string;
begin
  // F3 en la celda de SKU: despliega la busqueda incremental filtrada
  // por lo tecleado (mismo gesto de lookup que el resto de ViraCash).
  if (AItem = FColSku) and (Key = VK_F3) then
  begin
    Key := 0;
    if AEdit is TcxCustomDropDownEdit then
      TcxCustomDropDownEdit(AEdit).DroppedDown := True;
  end
  // Teclas de texto en la celda de SKU: rearman el debounce de la
  // busqueda incremental. El OnChange del lookup NO es fiable (deja
  // de disparar tras el primer autocompletado); el KeyDown del grid
  // llega SIEMPRE, tecla a tecla.
  else if (AItem = FColSku) and (not FEnScanner) and
          ((Key = VK_BACK) or (Key = VK_DELETE) or
           ((Key >= Ord('0')) and
            not ((Key >= VK_F1) and (Key <= VK_F24)))) then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end
  else if (AItem = FColSku) and
          ((Key = VK_RETURN) or (Key = VK_TAB)) then
  begin
    // Si el desplegable esta abierto lo cerramos (selecciona la fila)
    // para que el Enter no quede consumido en el dropdown.
    if (AEdit is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      sEntrada := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      sEntrada := Trim(VarToStr(AEdit.EditValue));
    if sEntrada <> '' then
    begin
      // El Enter se consume (la resolucion recoloca el foco); el Tab
      // sigue su curso y avanza de celda con la entrada ya en curso.
      if Key = VK_RETURN then
      begin
        FAvanzarTrasResolucion :=
          FConfig.AvanzarConEnterTrasResolver;
        Key := 0;
      end;
      DispararResolucion(sEntrada);
    end;
  end;
end;

// Articulo sin variaciones: no tiene SKU (CODIGO_UNIDAD vacio) y la
// celda quedaba en blanco, dejando la linea sin identificar en el modo
// SKU. Se muestra el codigo de articulo como texto de la celda.
procedure TModoEntradaSku.SkuGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if (Trim(AText) = '') and (ARecord <> nil) then
    AText := ValorRecord(ARecord, FConfig.Campos.CodigoArt);
end;

procedure TModoEntradaSku.SkuCustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  R: TRect;
  sArticulo, sTexto: string;
begin
  sTexto := SkuTextoRecord(AViewInfo.GridRecord);
  if sTexto = '' then
    sTexto := AViewInfo.Text;
  sArticulo := ValorRecord(AViewInfo.GridRecord,
                           FConfig.Campos.CodigoArt);
  if FConfig.Servicios.Paleta.PintarCeldaArticulo(
       ACanvas, AViewInfo, sArticulo, sTexto) then
    ADone := True;
  if (not ADone) and (sTexto <> '') and (sTexto <> AViewInfo.Text) then
  begin
    ACanvas.Brush.Color := AViewInfo.Params.Color;
    ACanvas.FillRect(AViewInfo.Bounds);
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    ACanvas.Font.Color := AViewInfo.Params.TextColor;
    R := AViewInfo.Bounds;
    Inc(R.Left, 4);
    ACanvas.Brush.Style := bsClear;
    // TcxCanvas.DrawText lleva banderas cx*, no DT_* de Windows.
    ACanvas.DrawText(sTexto, R,
      cxSingleLine or cxAlignVCenter or cxAlignLeft or cxShowEndEllipsis);
    ACanvas.Brush.Style := bsSolid;
    ADone := True;
  end;
end;

function TModoEntradaSku.ValorRecord(ARecord: TcxCustomGridRecord;
  const ACampo: string): string;
var
  Col: TcxGridColumn;
  vValor: Variant;
begin
  Result := '';
  if (ARecord <> nil) and (FConfig.View <> nil) and (ACampo <> '') then
  begin
    try
      Col := FConfig.View.GetColumnByFieldName(ACampo);
    except
      Col := nil;
    end;
    if Col <> nil then
    begin
      try
        vValor := ARecord.Values[Col.Index];
        if not (VarIsNull(vValor) or VarIsEmpty(vValor) or
                VarIsClear(vValor)) then
          Result := Trim(VarToStr(vValor));
      except
        Result := '';
      end;
    end;
  end;
end;

function TModoEntradaSku.SkuTextoRecord(
  ARecord: TcxCustomGridRecord): string;
var
  i: Integer;
  sArt, sUnidad, sValor: string;
  bTieneAtributos: Boolean;
begin
  sUnidad := ValorRecord(ARecord, FConfig.Campos.CodigoUnidad);
  Result := sUnidad;
  if Pos('/', Result) <= 0 then
  begin
    sArt := ValorRecord(ARecord, FConfig.Campos.CodigoArt);
    if sArt = '' then
      sArt := sUnidad;
    bTieneAtributos := False;
    if sArt <> '' then
    begin
      Result := sArt;
      for i := 1 to 5 do
      begin
        sValor := ValorRecord(ARecord, FConfig.Campos.AttrValor[i]);
        if sValor <> '' then
        begin
          Result := Result + '/' + sValor;
          bTieneAtributos := True;
        end;
      end;
      if not bTieneAtributos then
        Result := sUnidad;
    end;
  end;
end;

// FZ-ISSUE-350: STX abre la trama, ETX la cierra y la resuelve como
// lectura (acumula repetidos como en el resto de documentos). Los
// caracteres de la trama no llegan a la celda ni a la busqueda incremental.
procedure TModoEntradaSku.RecogerTramaLector(var Key: Char);
begin
  if Key = #2 then
  begin
    FEnScanner := True;
    FScanBuffer := '';
    FTimerBusq.Enabled := False;
    Key := #0;
  end
  else if FEnScanner then
  begin
    if Key = #3 then
    begin
      FEnScanner := False;
      FTimerBusq.Enabled := False;
      FLecturaPendiente := True;
      DispararResolucion(FScanBuffer);
      FScanBuffer := '';
    end
    else
      FScanBuffer := FScanBuffer + Key;
    Key := #0;
  end;
end;

procedure TModoEntradaSku.ViewEditKeyPress(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Char);
begin
  if AItem = FColSku then
    RecogerTramaLector(Key);
end;

// Celda de SKU enfocada sin editor abierto: la trama no debe abrir el
// editor con sus caracteres.
procedure TModoEntradaSku.ViewKeyPress(Sender: TObject; var Key: Char);
begin
  if (FColSku <> nil) and (FConfig.View.Controller.FocusedItem = FColSku) then
    RecogerTramaLector(Key);
end;

procedure TModoEntradaSku.DispararResolucion(const AEntrada: string);
begin
  FSkuPend := Trim(AEntrada);
  if FSkuPend <> '' then
  begin
    FTimerResolve.Enabled := False;
    FTimerResolve.Enabled := True;
  end;
end;

procedure TModoEntradaSku.TimerResolveTimer(Sender: TObject);
var
  sEntrada: string;
  bAvanzar, bLectura: Boolean;
begin
  FTimerResolve.Enabled := False;
  sEntrada := FSkuPend;
  FSkuPend := '';
  bAvanzar := FAvanzarTrasResolucion;
  FAvanzarTrasResolucion := False;
  bLectura := FLecturaPendiente;
  FLecturaPendiente := False;
  if sEntrada <> '' then
  begin
    if (bLectura and ResolverLectura(sEntrada)) or
       ((not bLectura) and ResolverEntrada(sEntrada)) then
    begin
      // Cierra el editor para que la celda muestre el SKU resuelto
      // (descarta el texto crudo tecleado/escaneado).
      if FConfig.View.Controller.EditingController.IsEditing then
        try
          FConfig.View.Controller.EditingController.HideEdit(False);
        except
          on E: EInvalidOperation do
            // Ruido del editor inplace; queda constancia en el log.
            if Assigned(FConfig.RegistroLog) then
              FConfig.RegistroLog.RegistrarAviso(
              'ModoSku.TimerResolve: HideEdit ignorado: ' +
              E.Message);
        end;
      // Resuelto: restaura el EnterAsTab (si el foco vuelve a la
      // celda del combo, InitEdit lo desactiva de nuevo).
      if Assigned(FOnSalirEdicion) then
        FOnSalirEdicion(nil);
      // Inventarios usa navegacion Excel: el Enter debe continuar por
      // la siguiente celda. Los demas documentos conservan el editor de
      // SKU abierto para la entrada repetida con lector.
      if bAvanzar then
      begin
        if not FConfig.View.Controller.FocusNextCell(
             True, True, False) then
          MostrarEditor;
      end
      else
        MostrarEditor;
    end;
  end;
end;

procedure TModoEntradaSku.MostrarEditor;
begin
  // Deja el editor de SKU abierto: si la celda no esta en edicion, la
  // primera tecla del lector abre el editor y las siguientes se pierden.
  if (FConfig.View <> nil) and (FColSku <> nil) then
  begin
    FColSku.Focused := True;
    try
      FConfig.View.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        // Ruido del editor inplace; queda constancia en el log.
        if Assigned(FConfig.RegistroLog) then
          FConfig.RegistroLog.RegistrarAviso(
          'ModoSku.MostrarEditor: ShowEdit ignorado: ' + E.Message);
    end;
  end;
end;

procedure TModoEntradaSku.BuscarArticulo;
var
  Editor: TcxCustomEdit;
begin
  MostrarEditor;
  if FConfig.View.Controller.EditingController.IsEditing then
  begin
    Editor := FConfig.View.Controller.EditingController.Edit;
    if Editor is TcxCustomDropDownEdit then
    begin
      AbrirBusquedaFiltrada('');
      TcxCustomDropDownEdit(Editor).DroppedDown := True;
    end;
  end;
end;

function TModoEntradaSku.LimpiarEntrada(const AEntrada: string): string;
var
  i: Integer;
  c: Char;
begin
  // Quita STX(#2)/ETX(#3)/CR/LF que mete el lector de codigo de barras.
  Result := '';
  for i := 1 to Length(AEntrada) do
  begin
    c := AEntrada[i];
    if (c <> #2) and (c <> #3) and (c <> #13) and (c <> #10) then
      Result := Result + c;
  end;
  Result := Trim(Result);
end;

procedure TModoEntradaSku.PonerCampo(const ANombre, AValor: string);
var
  Campo: TField;
begin
  // Solo escribe si el documento definio el campo y existe en el cds.
  if ANombre <> '' then
  begin
    Campo := FConfig.Cds.FindField(ANombre);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;
end;

procedure TModoEntradaSku.EscribirLinea(const ACodArt, ASku,
                                        ADescripcion: string);
begin
  if not (FConfig.Cds.State in [dsEdit, dsInsert]) then
    FConfig.Cds.Edit;
  // Articulo, SKU y atributos requeridos forman una sola escritura.
  // El Post del host puede ejecutarse en cuanto se cierre el editor.
  SincronizarCamposLineaSku(FConfig.Cds, FConfig.Campos,
    ACodArt, ASku, FConfig.LookupAtributos);
  PonerCampo(FConfig.Campos.Descripcion, ADescripcion);
end;

function TModoEntradaSku.ResolverEntrada(const AEntrada: string): Boolean;
var
  Val: IArticulosValidador;
  R: TArtResolucionEntrada;
  sEntrada, sSku: string;
begin
  Result := False;
  sEntrada := LimpiarEntrada(AEntrada);
  if sEntrada <> '' then
  begin
    Val := FConfig.ValidadorArticulos;
    if not Assigned(Val) then
      raise Exception.Create(SErrorValidadorArticulosNoInyectado);
    try
      R := Val.Resolver(sEntrada);
    finally
      Val := nil;
    end;
    if R.Encontrado then
    begin
      sSku := R.CodigoSku;
      if R.RequiereSku then
      begin
        // El modo SKU solo acepta una unidad completa; los selectores de
        // talla y color pertenecen al modo detallado.
        sSku := '';
        if R.Mensaje <> '' then
          ShowMessage_fza(R.Mensaje)
        else
          ShowMessage_fza(Format(SAvisoArticuloRequiereSku,
            [R.CodigoArticulo]));
      end
      else if sSku = '' then
        // Articulo sin SKUs: la unidad es el propio codigo de articulo.
        sSku := R.CodigoArticulo;
      if sSku <> '' then
      begin
        // SKU repetido (p.ej. segunda lectura de pistola): acumular
        // cantidad en la linea que ya lo tiene, no duplicar linea. Con
        // lote leido y documento que lo guarda, cada lote en su linea.
        if not (R.TraeLote and Assigned(FConfig.OnLoteLeido)) and
           AcumularLineaExistente(R.CodigoArticulo, sSku,
                                  R.DescripcionArticulo) then
          Result := True
        else
        begin
          EscribirLinea(R.CodigoArticulo, sSku, R.DescripcionArticulo);
          if Assigned(FOnResuelto) then
            FOnResuelto(R.CodigoArticulo, sSku, R.DescripcionArticulo,
                        True);
          if R.TraeLote and Assigned(FConfig.OnLoteLeido) then
            FConfig.OnLoteLeido(R.CodigoArticulo, sSku, R);
          Result := True;
        end;
      end;
    end
    else if FConfig.AceptarNoCatalogo then
    begin
      // Codigo fuera de catalogo: el documento lo admite como linea
      // libre (sin SKU: no mueve stock). El host completa fiscalidad,
      // descripcion y precios en su OnResuelto.
      EscribirLinea(sEntrada, '', '');
      if Assigned(FOnResuelto) then
        FOnResuelto(sEntrada, '', '', True);
      Result := True;
    end;
  end;
end;

function TModoEntradaSku.ResolverLectura(const AEntrada: string): Boolean;
begin
  FAcumularRepetidos := True;
  try
    Result := ResolverEntrada(AEntrada);
  finally
    FAcumularRepetidos := False;
  end;
end;

function TModoEntradaSku.AcumularLineaExistente(const ACodArt, ASku,
  ADesc: string): Boolean;
var
  ds: TDataSet;
  bEncontrada: Boolean;
begin
  Result := False;
  ds := FConfig.Cds;
  // FZ-ISSUE-232: solo una lectura de lector acumula.
  if FAcumularRepetidos and
  // Si se sabe que ninguna otra linea tiene el SKU no se cancela la linea
  // en curso: con la de "+" en insercion, el Cancel la borraba y el SKU se
  // escribia en la linea anterior (FZ-ISSUE-011).
     (FConfig.Campos.Cantidad <> '') and
     (ds.FindField(FConfig.Campos.Cantidad) <> nil) and
     ((not OtraLineaConSkuEnRejilla(FConfig.View,
        FConfig.Campos.CodigoUnidad, ASku, bEncontrada)) or
      bEncontrada) then
  begin
    // Soltar la edicion de la linea actual (en blanco o a medias)
    // antes de mover el cursor a la linea destino.
    if ds.State in [dsEdit, dsInsert] then
      ds.Cancel;
    if ds.Locate(FConfig.Campos.CodigoUnidad, ASku,
                 [loCaseInsensitive]) then
    begin
      ds.Edit;
      SincronizarCamposLineaSku(ds, FConfig.Campos,
        ACodArt, ASku, FConfig.LookupAtributos);
      ds.FieldByName(FConfig.Campos.Cantidad).AsFloat :=
        ds.FieldByName(FConfig.Campos.Cantidad).AsFloat + 1;
      ds.Post;
      if Assigned(FOnResuelto) then
        FOnResuelto(ACodArt, ASku, ADesc, True);
      Result := True;
    end;
  end;
end;

end.
