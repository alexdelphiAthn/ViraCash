{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridArticulos                                            }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Controladora reutilizable de la operativa de entrada de articulos en un   }
{    grid (cxGridDBTableView + cds): columna de articulo (teclear/escanear +   }
{    buscar), columnas dinamicas de atributos (talla/color) como desplegables, }
{    resolucion via inLibArticulosValidadorIntf, valores via              }
{    inLibArticulosAtributosIntf, generacion del SKU y consolidacion.     }
{                                                                              }
{    La misma logica que el grid de ventas de inMtoCajaOpe, pero desacoplada   }
{    por nombres de campo (TCamposGridArt) para que la usen varios grids       }
{    (caja, traspasos, ...). Cada pantalla anade sus columnas propias (precio  }
{    en venta, coste/stock en traspaso) sobre el mismo View.                   }
{                                                                              }
{    El selector puede ser combo fijo con filtrado o la paleta tradicional,    }
{    segun la configuracion del consumidor.                                    }
{******************************************************************************}
unit inLibGridArticulos;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Types,
  System.StrUtils, System.Generics.Collections, Data.DB, Uni, Vcl.Controls,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  cxControls, cxGraphics, cxEdit, cxTextEdit, cxButtonEdit, cxDropDownEdit,
  cxGrid,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibArticulosValidadorIntf, inLibArticulosAtributosIntf,
  inLibAtributosPaleta,
  inLibContextoSesionIntf, inLibGenBusq, inLibLogIntf,
  inLibModoTallasIntf, inLibGridArticulosPersistenciaIntf,
  inLibGridArticulosBusqueda;

function MaximoAtributosVisiblesGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  AMinimoAtributos: Integer = 0): Integer;
// True si puede saberse, con los valores ya cargados en la rejilla (sin
// mover ni cancelar el dataset), si otra fila distinta de la enfocada tiene
// ese SKU; el resultado va en AEncontrada. False si la rejilla no tiene
// columna para ACampo o trabaja en GridMode.
function OtraLineaConSkuEnRejilla(
  AVista: TcxGridDBTableView;
  const ACampo, ASku: string;
  out AEncontrada: Boolean): Boolean;
procedure SincronizarVisibilidadAtributosGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  const AColumnasAtributo: array of TcxGridDBColumn;
  AMinimoAtributos: Integer = 0;
  AMaximoAtributos: Integer = 5);

type
  // Nombres de los campos del cds que usa la controladora. Cada host los
  // rellena con los suyos (en traspaso: CODIGO_ART, CODIGO_UNIDAD, ...).
  TCamposGridArt = record
    CodigoArt: string;
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: string;
    NumAtributos: string;
    AttrValor: array[1..5] of string;
    AttrNombre: array[1..5] of string;
  end;

  // Se dispara al resolver una entrada. ACompleto = el SKU esta cerrado
  // (articulo sin variacion, o con todos los atributos elegidos). El host
  // aprovecha para rellenar sus columnas (coste, stock, precio...).
  TArtResueltoEvent = procedure(const ACodArt, ASku, ADescripcion: string;
                                ACompleto: Boolean) of object;

  TGridArticulosLineas = class
  private
    FConn: TUniConnection;
    FContextoSesion: IContextoSesionAplicacion;
    FRegistroLog: IRegistroLog;
    FView: TcxGridDBTableView;
    FCds: TDataSet;
    FCampos: TCamposGridArt;
    FColArticulo: TcxGridDBColumn;
    FColNumeroAtributos: TcxGridDBColumn;
    FColAtributo: array[1..5] of TcxGridDBColumn;
    FUsarCombosAtributos: Boolean;
    FMostrarCodigoPadre: Boolean;
    FOpcionesAtributo: array[1..5] of TArray<string>;
    FArticuloOpcionesAtributo: array[1..5] of string;
    FGlifoSwatch: TGlifoSwatchCombo;
    FValidador: IArticulosValidador;
    FLookup: IArticulosAtributosLookup;
    FBusqueda: TBusquedaGridArticulos;
    FAcumularRepetidos: Boolean;
    FOnResuelto: TArtResueltoEvent;
    FOnSalirSitioOriginal: TNotifyEvent;
    FOnKeyDownOriginal: TKeyEvent;
    // Aviso al host al entrar/salir de un editor in-place del grid.
    // Pensados para Desactivar/RestaurarEnterAsTabTemporal (TfrmBase):
    // sin esto el TJvEnterAsTab convierte el Enter en Tab y no llega ni
    // a la celda de articulo ni a los combos de atributo.
    FOnEntrarEdicion: TNotifyEvent;
    FOnSalirEdicion: TNotifyEvent;
    FEnterAsTabSolicitado: Boolean;
    // Timer single-shot para abrir la paleta al entrar en una celda de
    // atributo vacia (listbox incrustado, como la caja). Diferimos la
    // apertura fuera del OnEnter: el editor in-place del cxGrid aun no ha
    // terminado de parentar y ClientToScreen lanzaria EInvalidOperation.
    FTimerPopup: TTimer;
    FTimerConfirmacion: TTimer;
    FTimerEnterAsTab: TTimer;
    FTimerAvanceArticulo: TTimer;
    FTimerVisibilidad: TTimer;
    FOrdenPopupPend: Integer;
    FConfirmacionPendiente: Boolean;
    FOrdenConfirmacionPendiente: Integer;
    FValorConfirmacionPendiente: string;
    FMaximoAtributosVisibles: Integer;
    FNombresAtributosGenericos: Boolean;
    // Sigue activo durante SafePassFocus: DevExpress devuelve el foco al
    // grid antes de ejecutar OnCloseUp.
    FComboAtributoEnCurso: Boolean;
    // Evita que el OnEnter reprograme el selector mientras lo estamos
    // abriendo desde el temporizador.
    FAbriendoSelector: Boolean;
    // Almacen cuyo stock se muestra en el buscador de SKU (lo fija el host;
    // en traspaso, el almacen origen). Vacio = no muestra stock.
    FAlmacenStock: string;
    // El documento admite lineas de articulos fuera del catalogo: una
    // entrada no encontrada se acepta como codigo libre (sin SKU, sin
    // atributos, no mueve stock) en vez de descartarse. Lo activan las
    // facturas de venta mayor; caja y traspasos lo dejan a False.
    FAceptarNoCatalogo: Boolean;
    // FZ-ISSUE-341: lote o serie de la lectura (ver TConfigColumnasSku).
    FOnLoteLeido: TArtLoteLeidoEvent;
    // Las columnas conservan su ancho y el grid se desplaza en
    // horizontal en vez de repartir el ancho entre ellas
    // (ColumnAutoWidth). Lo activa inventarios; caja y traspasos
    // mantienen el reparto.
    FDesplazamientoHorizontal: Boolean;
    FAfterOpenOriginal: TDataSetNotifyEvent;
    FAfterPostOriginal: TDataSetNotifyEvent;
    FAfterScrollOriginal: TDataSetNotifyEvent;
    FAfterDeleteOriginal: TDataSetNotifyEvent;
    FAfterCancelOriginal: TDataSetNotifyEvent;
    FAfterRefreshOriginal: TDataSetNotifyEvent;
    FEventosDataSetInstalados: Boolean;
    FEventoSalirSitioInstalado: Boolean;
    FEventoKeyDownInstalado: Boolean;
    procedure InstalarEventoSalidaSitio;
    procedure RestaurarEventoSalidaSitio;
    procedure InstalarEventoTeclado;
    procedure RestaurarEventoTeclado;
    procedure SolicitarDesactivarEnterAsTab(Sender: TObject);
    procedure LiberarEnterAsTab(Sender: TObject);
    function FocoDentroDeVista: Boolean;
    procedure SitioGridSalir(Sender: TObject);
    procedure EditorSalir(Sender: TObject);
    // Restaura el EnterAsTab al SALIR de las columnas de la
    // controladora: el OnExit del editor in-place no es fiable con
    // AlwaysShowEditor (el host del banco de pruebas lo usa).
    procedure ViewFocusedItemChanged(Sender: TcxCustomGridTableView;
                                     APrevFocusedItem,
                                  AFocusedItem: TcxCustomGridTableItem);
    procedure SetAlmacenStock(const AValue: string);
    procedure SetMaximoAtributosVisibles(AValue: Integer);
    // Si el documento YA tiene una linea con ese SKU cerrado, suma 1
    // a su cantidad y devuelve True (la lectura queda consumida sin
    // crear otra linea igual). La linea en blanco no casa porque su
    // CODIGO_UNIDAD esta vacio.
    function AcumularLineaExistente(const ACodArt, ASku,
                                    ADesc: string): Boolean;
    procedure CrearColumnaArticulo;
    procedure CrearColumnaNumeroAtributos;
    procedure CrearColumnaUnidadOculta;
    procedure CrearColumnasAtributo;
    function EscalarAncho(AAncho: Integer): Integer;
    procedure AjustarAnchoColumnaAtributo(AColumna: TcxGridDBColumn;
      AConPaleta: Boolean);
    procedure RefrescarVisibilidadAtributos(
      AMinimoAtributos: Integer = 0);
    procedure ArmarRefrescoVisibilidad;
    procedure TimerVisibilidadTimer(Sender: TObject);
    procedure InstalarEventosDataSet;
    procedure RestaurarEventosDataSet;
    procedure DataSetAfterOpen(DataSet: TDataSet);
    procedure DataSetAfterPost(DataSet: TDataSet);
    procedure DataSetAfterScroll(DataSet: TDataSet);
    procedure DataSetAfterDelete(DataSet: TDataSet);
    procedure DataSetAfterCancel(DataSet: TDataSet);
    procedure DataSetAfterRefresh(DataSet: TDataSet);
    procedure ViewInitEdit(Sender: TcxCustomGridTableView;
                           AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure ViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    procedure ConfigurarEditorAtributo(AOrden: Integer;
      AEdit: TcxCustomEdit);
    procedure AtributoCustomDrawCell(Sender: TcxCustomGridTableView;
                           ACanvas: TcxCanvas;
                           AViewInfo: TcxGridTableDataCellViewInfo;
                           var ADone: Boolean);
    procedure AtributoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure AtributoEnter(Sender: TObject);
    procedure AtributoComboInitPopup(Sender: TObject);
    procedure AtributoComboPopup(Sender: TObject);
    procedure AtributoComboDrawItem(AControl: TcxCustomComboBox;
      ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
      AState: TOwnerDrawState);
    procedure AtributoComboClosePopup(AControl: TcxControl;
      AReason: TcxEditCloseUpReason);
    procedure AtributoComboCloseUp(Sender: TObject);
    procedure TimerPopupTimer(Sender: TObject);
    procedure TimerConfirmacionTimer(Sender: TObject);
    procedure TimerEnterAsTabTimer(Sender: TObject);
    procedure TimerAvanceArticuloTimer(Sender: TObject);
    procedure CargarOpcionesCombo(AOrden: Integer;
      const AArticulo: string);
    procedure CopiarOpcionesCombo(AOrden: Integer; AItems: TStrings);
    function BuscarValorCombo(AOrden: Integer; const AValor: string;
      out AValorCanonico: string): Boolean;
    function ObtenerOrdenEditorCombo(AControl: TcxControl): Integer;
    function ResolverColorEditor(AEditor: TcxComboBox;
      const ATexto: string; out AInfo: TInfoBasico): Boolean;
    function ObtenerInfoColorCombo(AOrden: Integer; const ATexto: string;
      out AInfo: TInfoBasico): Boolean;
    procedure ProgramarConfirmacionCombo(AOrden: Integer;
      const AValor: string);
    procedure CancelarAperturaSelector;
    procedure CancelarConfirmacionCombo;
    function ProgramarAvanceDesdeArticulo: Boolean;
    procedure ConfirmarAtributoComboPendiente;
    procedure AbrirSelectorOrden(AOrden: Integer);
    procedure AbrirComboOrden(AOrden: Integer);
    procedure AbrirPaletaOrden(AOrden: Integer);
    // True si hay valores; si no, avisa solo cuando el atributo aplica al
    // articulo de la linea (FZ-ISSUE-260).
    function HayValoresAtributo(AOrden, ANumValores: Integer): Boolean;
    // Tras elegir un atributo, si quedan atributos sin rellenar enfoca el
    // siguiente y abre su selector (no deja pasar a la siguiente fila con el
    // SKU a medias). Devuelve True si quedaba alguno pendiente.
    function AvanzarSiguienteAtributo: Boolean;
    // True si la linea actual aun tiene color/talla por elegir (NUM_ATRIBUTOS
    // > 0 y algun ATTRn_VALOR vacio).
    // Tras resolver un articulo decide el foco como la caja: si faltan
    // atributos salta al primero y abre su selector; si el SKU ya esta cerrado
    // deja el editor de articulo listo para la siguiente entrada.
    procedure AvanzarTrasResolver;
    procedure DespuesResolverBusqueda;
    procedure AplicarSkuYAvisar;
    function ColumnaPorTag(ATag: Integer): TcxGridDBColumn;
    function GenerarSku: string;
    procedure ActualizarColumnasAtributo(const ACodArt: string);
    procedure AutoCompletarAtributosUnicos(const ACodArt: string);
    procedure RellenarAtributosDesdeSku(const ACodArt, ASku: string);
    function CdsEditando: Boolean;
    procedure LogSes(const ATexto: string);
  public
    constructor Create(AConn: TUniConnection;
      AView: TcxGridDBTableView; ACds: TDataSet;
      const ACampos: TCamposGridArt;
      const AContextoSesion: IContextoSesionAplicacion;
      const ABusquedaVisual: IBusquedaVisual;
      const ABusquedaSkus: IBusquedaSkusTallas;
      const AConsultaArticulos: IConsultaArticulosGrid;
      const AValidador: IArticulosValidador = nil;
      const ALookup: IArticulosAtributosLookup = nil;
      const ARegistroLog: IRegistroLog = nil;
      AMostrarCodigoPadre: Boolean = False);
    destructor Destroy; override;
    // Crea la columna de articulo + las 5 columnas de atributo y engancha el
    // OnInitEdit del View. El host anade sus columnas DESPUES sobre el View.
    procedure Construir;
    // Desengancha eventos y temporizadores antes de que el host destruya las
    // columnas con ClearItems. Es idempotente y el modo no se reutiliza.
    procedure Desmontar;
    // Deja el editor de la celda de articulo ABIERTO, listo para teclear o
    // escanear. Imprescindible para el lector: si la celda no esta ya en
    // edicion, la primera tecla abre el editor y las siguientes (muy rapidas)
    // se pierden -> solo se leeria la primera cifra.
    procedure MostrarEditorArticulo;
    // Resuelve una entrada (codigo de articulo, SKU, codigo de barras o ref
    // de proveedor) y rellena la linea. Devuelve False si no se encontro.
    function ResolverEntrada(const AEntrada: string): Boolean;
    // ResolverEntrada de una lectura de lector: un SKU que ya esta en otra
    // linea suma 1 a esa linea en vez de escribir la actual (FZ-232).
    function ResolverLectura(const AEntrada: string): Boolean;
    // F3 contextual del host: abre la busqueda completa en Articulo o la
    // selector si el foco esta en una columna de Color/Talla.
    procedure BuscarContextual;
    // Hace visibles las columnas de color/talla de un articulo ya cargado.
    procedure MostrarColumnasAtributosArticulo(const ACodArt: string);
    property OnResuelto: TArtResueltoEvent read FOnResuelto write FOnResuelto;
    // Entrada/salida de edicion in-place (ver comentario de los campos).
    property OnEntrarEdicion: TNotifyEvent read FOnEntrarEdicion
                                           write FOnEntrarEdicion;
    property OnSalirEdicion: TNotifyEvent read FOnSalirEdicion
                                          write FOnSalirEdicion;
    // Almacen para la columna de stock del buscador de SKU (origen). Al
    // cambiarlo se recarga el desplegable de busqueda incremental.
    property AlmacenStock: string read FAlmacenStock write SetAlmacenStock;
    // Admitir codigos fuera de catalogo como linea libre (ver campo).
    property AceptarNoCatalogo: Boolean read FAceptarNoCatalogo
                                        write FAceptarNoCatalogo;
    property OnLoteLeido: TArtLoteLeidoEvent read FOnLoteLeido
                                             write FOnLoteLeido;
    // Conservar anchos y desplazar en horizontal (ver campo).
    property DesplazamientoHorizontal: Boolean
      read FDesplazamientoHorizontal write FDesplazamientoHorizontal;
    // Permite activar el selector combo sin cambiar los consumidores que
    // todavia usan la paleta tradicional.
    property UsarCombosAtributos: Boolean read FUsarCombosAtributos
      write FUsarCombosAtributos;
    // Permite que una pantalla limite la presentacion sin alterar el SKU.
    property MaximoAtributosVisibles: Integer
      read FMaximoAtributosVisibles write SetMaximoAtributosVisibles;
    property NombresAtributosGenericos: Boolean
      read FNombresAtributosGenericos write FNombresAtributosGenericos;
  end;

implementation

uses
  cxGeometry, dxDPIAwareUtils,
  inLibMensajesVcl,
  inLibMsgArticulos,
  inLibSelectorAtributoLinea, inLibLineaSku;

const
  // Anchos a 96 ppp de las columnas de atributo. La de paleta (color) lleva
  // el cuadradito delante del texto y valores largos (AZUL_CIELO); el minimo
  // impide que ColumnAutoWidth la estreche al repartir el ancho del grid.
  ANCHO_COL_ATRIBUTO = 90;
  ANCHO_MIN_COL_ATRIBUTO = 20;
  ANCHO_COL_ATRIBUTO_PALETA = 130;
  ANCHO_MIN_COL_ATRIBUTO_PALETA = 110;

type
  // Acceso al OnExit protegido del sitio y de los editores del cxGrid.
  THackWinCtrl = class(TWinControl);

function MetodosIguales(const AEventoUno,
  AEventoDos: TMethod): Boolean;
begin
  Result := (AEventoUno.Code = AEventoDos.Code) and
            (AEventoUno.Data = AEventoDos.Data);
end;

function EventosDataSetIguales(const AEventoUno,
  AEventoDos: TDataSetNotifyEvent): Boolean;
begin
  Result := MetodosIguales(
    TMethod(AEventoUno), TMethod(AEventoDos));
end;

function OtraLineaConSkuEnRejilla(
  AVista: TcxGridDBTableView;
  const ACampo, ASku: string;
  out AEncontrada: Boolean): Boolean;
var
  oColumna: TcxGridDBColumn;
  iRegistro: Integer;
  iActual: Integer;
begin
  AEncontrada := False;
  oColumna := nil;
  if (AVista <> nil) and (ACampo <> '') and (Trim(ASku) <> '') and
     (not AVista.DataController.DataModeController.GridMode) then
    oColumna := AVista.GetColumnByFieldName(ACampo);
  Result := oColumna <> nil;
  if Result then
  begin
    iActual := AVista.DataController.FocusedRecordIndex;
    iRegistro := 0;
    while (iRegistro < AVista.DataController.RecordCount) and
          (not AEncontrada) do
    begin
      AEncontrada := (iRegistro <> iActual) and SameText(
        Trim(VarToStr(AVista.DataController.Values[
          iRegistro, oColumna.Index])),
        Trim(ASku));
      Inc(iRegistro);
    end;
  end;
end;

function MaximoAtributosVisiblesGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  AMinimoAtributos: Integer): Integer;
var
  iAtributos: Integer;
  iRegistro: Integer;
begin
  Result := AMinimoAtributos;
  if Result < 0 then
    Result := 0;
  if Assigned(AVista) and Assigned(AColumnaNumeroAtributos) then
  begin
    for iRegistro := 0 to AVista.DataController.RecordCount - 1 do
    begin
      if TryStrToInt(Trim(VarToStr(
           AVista.DataController.Values[iRegistro,
             AColumnaNumeroAtributos.Index])), iAtributos) and
         (iAtributos > Result) then
        Result := iAtributos;
    end;
  end;
end;

procedure SincronizarVisibilidadAtributosGrid(
  AVista: TcxGridDBTableView;
  AColumnaNumeroAtributos: TcxGridDBColumn;
  const AColumnasAtributo: array of TcxGridDBColumn;
  AMinimoAtributos: Integer;
  AMaximoAtributos: Integer);
var
  iColumna: Integer;
  iMaximo: Integer;
begin
  if Assigned(AVista) then
  begin
    iMaximo := MaximoAtributosVisiblesGrid(
      AVista, AColumnaNumeroAtributos, AMinimoAtributos);
    if AMaximoAtributos < 0 then
      iMaximo := 0
    else if iMaximo > AMaximoAtributos then
      iMaximo := AMaximoAtributos;
    AVista.BeginUpdate;
    try
      for iColumna := Low(AColumnasAtributo) to
        High(AColumnasAtributo) do
        if Assigned(AColumnasAtributo[iColumna]) then
          AColumnasAtributo[iColumna].Visible :=
            iColumna - Low(AColumnasAtributo) + 1 <= iMaximo;
    finally
      AVista.EndUpdate;
    end;
  end;
end;

constructor TGridArticulosLineas.Create(
  AConn: TUniConnection; AView: TcxGridDBTableView;
  ACds: TDataSet;
  const ACampos: TCamposGridArt;
  const AContextoSesion: IContextoSesionAplicacion;
  const ABusquedaVisual: IBusquedaVisual;
  const ABusquedaSkus: IBusquedaSkusTallas;
  const AConsultaArticulos: IConsultaArticulosGrid;
  const AValidador: IArticulosValidador;
  const ALookup: IArticulosAtributosLookup;
  const ARegistroLog: IRegistroLog;
  AMostrarCodigoPadre: Boolean);
begin
  inherited Create;
  FConn := AConn;
  FGlifoSwatch := TGlifoSwatchCombo.Create(ResolverColorEditor, nil);
  FContextoSesion := AContextoSesion;
  FRegistroLog := ARegistroLog;
  FMostrarCodigoPadre := AMostrarCodigoPadre;
  FView := AView;
  FCds := ACds;
  FCampos := ACampos;
  FValidador := AValidador;
  if not Assigned(FValidador) then
    raise Exception.Create(SErrorValidadorArticulosNoInyectado);
  FLookup := ALookup;
  if not Assigned(FLookup) then
    raise Exception.Create(SErrorLookupAtributosNoInyectado);
  FOrdenPopupPend := 0;
  FMaximoAtributosVisibles := 5;
  FTimerPopup := TTimer.Create(nil);
  FTimerPopup.Enabled := False;
  FTimerPopup.Interval := 1;
  FTimerPopup.OnTimer := TimerPopupTimer;
  FTimerConfirmacion := TTimer.Create(nil);
  FTimerConfirmacion.Enabled := False;
  FTimerConfirmacion.Interval := 1;
  FTimerConfirmacion.OnTimer := TimerConfirmacionTimer;
  FTimerEnterAsTab := TTimer.Create(nil);
  FTimerEnterAsTab.Enabled := False;
  FTimerEnterAsTab.Interval := 1;
  FTimerEnterAsTab.OnTimer := TimerEnterAsTabTimer;
  FTimerAvanceArticulo := TTimer.Create(nil);
  FTimerAvanceArticulo.Enabled := False;
  FTimerAvanceArticulo.Interval := 1;
  FTimerAvanceArticulo.OnTimer := TimerAvanceArticuloTimer;
  FTimerVisibilidad := TTimer.Create(nil);
  FTimerVisibilidad.Enabled := False;
  FTimerVisibilidad.Interval := 1;
  FTimerVisibilidad.OnTimer := TimerVisibilidadTimer;
  FBusqueda := TBusquedaGridArticulos.Create(
    FView, FCds, FCampos.CodigoArt, ABusquedaVisual,
    ABusquedaSkus, AConsultaArticulos, FRegistroLog,
    ResolverEntrada, DespuesResolverBusqueda,
    AbrirSelectorOrden, LogSes, AMostrarCodigoPadre);
end;

procedure TGridArticulosLineas.LogSes(const ATexto: string);
begin
  if Assigned(FContextoSesion) then
    FContextoSesion.LogSesion(ATexto);
end;

destructor TGridArticulosLineas.Destroy;
begin
  Desmontar;
  FreeAndNil(FGlifoSwatch);
  FreeAndNil(FTimerVisibilidad);
  FreeAndNil(FTimerAvanceArticulo);
  FreeAndNil(FTimerEnterAsTab);
  FreeAndNil(FTimerConfirmacion);
  FreeAndNil(FTimerPopup);
  FValidador := nil;
  FLookup := nil;
  inherited;
end;

function TGridArticulosLineas.CdsEditando: Boolean;
begin
  Result := FCds.Active and (FCds.State in [dsEdit, dsInsert]);
end;

procedure TGridArticulosLineas.InstalarEventoSalidaSitio;
begin
  if FUsarCombosAtributos and not FEventoSalirSitioInstalado and
     Assigned(FView) and Assigned(FView.Site) then
  begin
    FOnSalirSitioOriginal := THackWinCtrl(FView.Site).OnExit;
    THackWinCtrl(FView.Site).OnExit := SitioGridSalir;
    FEventoSalirSitioInstalado := True;
  end;
end;

procedure TGridArticulosLineas.RestaurarEventoSalidaSitio;
var
  EventoSalir: TNotifyEvent;
begin
  if FEventoSalirSitioInstalado then
  begin
    if Assigned(FView) and Assigned(FView.Site) then
    begin
      EventoSalir := SitioGridSalir;
      if MetodosIguales(
           TMethod(THackWinCtrl(FView.Site).OnExit),
           TMethod(EventoSalir)) then
        THackWinCtrl(FView.Site).OnExit := FOnSalirSitioOriginal;
    end;
    FOnSalirSitioOriginal := nil;
    FEventoSalirSitioInstalado := False;
  end;
end;

procedure TGridArticulosLineas.InstalarEventoTeclado;
begin
  if FUsarCombosAtributos and not FEventoKeyDownInstalado and
     Assigned(FView) then
  begin
    FOnKeyDownOriginal := FView.OnKeyDown;
    FView.OnKeyDown := ViewKeyDown;
    FEventoKeyDownInstalado := True;
  end;
end;

procedure TGridArticulosLineas.RestaurarEventoTeclado;
var
  EventoTeclado: TKeyEvent;
begin
  if FEventoKeyDownInstalado then
  begin
    if Assigned(FView) then
    begin
      EventoTeclado := ViewKeyDown;
      if MetodosIguales(
           TMethod(FView.OnKeyDown), TMethod(EventoTeclado)) then
        FView.OnKeyDown := FOnKeyDownOriginal;
    end;
    FOnKeyDownOriginal := nil;
    FEventoKeyDownInstalado := False;
  end;
end;

procedure TGridArticulosLineas.EditorSalir(Sender: TObject);
begin
  LiberarEnterAsTab(Sender);
end;

procedure TGridArticulosLineas.SolicitarDesactivarEnterAsTab(
  Sender: TObject);
begin
  if Assigned(FOnEntrarEdicion) then
  begin
    FOnEntrarEdicion(Sender);
    FEnterAsTabSolicitado := True;
  end;
end;

procedure TGridArticulosLineas.LiberarEnterAsTab(Sender: TObject);
begin
  // Con la lista desplegada el Enter lo consume el propio editor: la
  // solicitud sigue viva hasta que se cierre.
  if FEnterAsTabSolicitado and
     not ((Sender is TcxCustomDropDownEdit) and
          TcxCustomDropDownEdit(Sender).DroppedDown) then
  begin
    FEnterAsTabSolicitado := False;
    if Assigned(FOnSalirEdicion) then
      FOnSalirEdicion(Sender);
  end;
end;

function TGridArticulosLineas.FocoDentroDeVista: Boolean;
var
  ControlActivo: TWinControl;
  Editor: TcxCustomEdit;
begin
  Result := FComboAtributoEnCurso;
  ControlActivo := Screen.ActiveControl;
  Editor := nil;
  if Assigned(FView) and
     Assigned(FView.Controller.EditingController) and
     FView.Controller.EditingController.IsEditing then
    Editor := FView.Controller.EditingController.Edit;
  if Assigned(FView) then
    Result := Result or FView.IsControlFocused;
  if not Result and Assigned(FView) and Assigned(FView.Site) and
     Assigned(ControlActivo) then
    Result := (ControlActivo = FView.Site) or
      FView.Site.ContainsControl(ControlActivo);
  if not Result and Assigned(Editor) then
  begin
    Result := Editor.IsFocused or (ControlActivo = Editor);
    if not Result and Assigned(ControlActivo) then
      Result := Editor.ContainsControl(ControlActivo);
    if not Result and (Editor is TcxCustomDropDownEdit) then
      Result := TcxCustomDropDownEdit(Editor).DroppedDown;
  end;
end;

procedure TGridArticulosLineas.SitioGridSalir(Sender: TObject);
begin
  if Assigned(FTimerEnterAsTab) then
  begin
    FTimerEnterAsTab.Enabled := False;
    FTimerEnterAsTab.Enabled := True;
  end
  else
    LiberarEnterAsTab(Sender);
  if Assigned(FOnSalirSitioOriginal) then
    FOnSalirSitioOriginal(Sender);
end;

procedure TGridArticulosLineas.ViewFocusedItemChanged(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
var
  Orden: Integer;
begin
  if APrevFocusedItem <> AFocusedItem then
    CancelarAperturaSelector;
  Orden := 0;
  if Assigned(AFocusedItem) then
    Orden := AFocusedItem.Tag;
  // Al navegar con Intro no siempre llega a dispararse el OnEnter del editor
  // in-place: DevExpress cambia primero la celda y crea el editor despues. La
  // celda enfocada es el punto fiable para programar la apertura del combo.
  if FUsarCombosAtributos and (Orden >= 1) and (Orden <= 5) and
     Assigned(FCds) and FCds.Active and not FCds.IsEmpty and
     (Trim(FCds.FieldByName(FCampos.CodigoArt).AsString) <> '') and
     (Trim(FCds.FieldByName(FCampos.AttrValor[Orden]).AsString) = '') then
  begin
    FOrdenPopupPend := Orden;
    FTimerPopup.Enabled := False;
    FTimerPopup.Enabled := True;
  end;
  // El EnterAsTab solo permanece desactivado mientras el foco esta en
  // una columna de la controladora (articulo o atributos).
  if not FUsarCombosAtributos and
     (APrevFocusedItem <> nil) and
     ((APrevFocusedItem = FColArticulo) or
      ((APrevFocusedItem.Tag >= 1) and
       (APrevFocusedItem.Tag <= 5))) then
    LiberarEnterAsTab(Sender);
end;

procedure TGridArticulosLineas.ArmarRefrescoVisibilidad;
begin
  if Assigned(FTimerVisibilidad) then
  begin
    FTimerVisibilidad.Enabled := False;
    FTimerVisibilidad.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.TimerVisibilidadTimer(Sender: TObject);
begin
  FTimerVisibilidad.Enabled := False;
  RefrescarVisibilidadAtributos;
end;

procedure TGridArticulosLineas.DataSetAfterOpen(DataSet: TDataSet);
begin
  CancelarAperturaSelector;
  CancelarConfirmacionCombo;
  if Assigned(FAfterOpenOriginal) then
    FAfterOpenOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterPost(DataSet: TDataSet);
begin
  CancelarAperturaSelector;
  CancelarConfirmacionCombo;
  if Assigned(FAfterPostOriginal) then
    FAfterPostOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterScroll(DataSet: TDataSet);
begin
  CancelarAperturaSelector;
  CancelarConfirmacionCombo;
  if Assigned(FAfterScrollOriginal) then
    FAfterScrollOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterDelete(DataSet: TDataSet);
begin
  CancelarAperturaSelector;
  CancelarConfirmacionCombo;
  if Assigned(FAfterDeleteOriginal) then
    FAfterDeleteOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterCancel(DataSet: TDataSet);
begin
  CancelarAperturaSelector;
  CancelarConfirmacionCombo;
  if Assigned(FAfterCancelOriginal) then
    FAfterCancelOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.DataSetAfterRefresh(DataSet: TDataSet);
begin
  CancelarAperturaSelector;
  CancelarConfirmacionCombo;
  if Assigned(FAfterRefreshOriginal) then
    FAfterRefreshOriginal(DataSet);
  ArmarRefrescoVisibilidad;
end;

procedure TGridArticulosLineas.InstalarEventosDataSet;
begin
  if Assigned(FCds) and not FEventosDataSetInstalados then
  begin
    FAfterOpenOriginal := FCds.AfterOpen;
    FAfterPostOriginal := FCds.AfterPost;
    FAfterScrollOriginal := FCds.AfterScroll;
    FAfterDeleteOriginal := FCds.AfterDelete;
    FAfterCancelOriginal := FCds.AfterCancel;
    FAfterRefreshOriginal := FCds.AfterRefresh;
    FCds.AfterOpen := DataSetAfterOpen;
    FCds.AfterPost := DataSetAfterPost;
    FCds.AfterScroll := DataSetAfterScroll;
    FCds.AfterDelete := DataSetAfterDelete;
    FCds.AfterCancel := DataSetAfterCancel;
    FCds.AfterRefresh := DataSetAfterRefresh;
    FEventosDataSetInstalados := True;
  end;
end;

procedure TGridArticulosLineas.RestaurarEventosDataSet;
var
  oEvento: TDataSetNotifyEvent;
begin
  if Assigned(FCds) and FEventosDataSetInstalados then
  begin
    oEvento := DataSetAfterOpen;
    if EventosDataSetIguales(FCds.AfterOpen, oEvento) then
      FCds.AfterOpen := FAfterOpenOriginal;
    oEvento := DataSetAfterPost;
    if EventosDataSetIguales(FCds.AfterPost, oEvento) then
      FCds.AfterPost := FAfterPostOriginal;
    oEvento := DataSetAfterScroll;
    if EventosDataSetIguales(FCds.AfterScroll, oEvento) then
      FCds.AfterScroll := FAfterScrollOriginal;
    oEvento := DataSetAfterDelete;
    if EventosDataSetIguales(FCds.AfterDelete, oEvento) then
      FCds.AfterDelete := FAfterDeleteOriginal;
    oEvento := DataSetAfterCancel;
    if EventosDataSetIguales(FCds.AfterCancel, oEvento) then
      FCds.AfterCancel := FAfterCancelOriginal;
    oEvento := DataSetAfterRefresh;
    if EventosDataSetIguales(FCds.AfterRefresh, oEvento) then
      FCds.AfterRefresh := FAfterRefreshOriginal;
    FAfterOpenOriginal := nil;
    FAfterPostOriginal := nil;
    FAfterScrollOriginal := nil;
    FAfterDeleteOriginal := nil;
    FAfterCancelOriginal := nil;
    FAfterRefreshOriginal := nil;
    FEventosDataSetInstalados := False;
  end;
end;

procedure TGridArticulosLineas.Desmontar;
var
  iAtributo: Integer;
  oEditKeyDown: TcxGridEditKeyEvent;
  oFocusedItemChanged: TcxGridFocusedItemChangedEvent;
  oGetProperties: TcxGridGetPropertiesEvent;
  oInitEdit: TcxGridInitEditEvent;
begin
  CancelarAperturaSelector;
  if Assigned(FTimerEnterAsTab) then
    FTimerEnterAsTab.Enabled := False;
  if Assigned(FTimerVisibilidad) then
    FTimerVisibilidad.Enabled := False;
  CancelarConfirmacionCombo;
  RestaurarEventoTeclado;
  if Assigned(FView) then
  begin
    if Assigned(FView.Controller.EditingController) and
       FView.Controller.EditingController.IsEditing then
    begin
      try
        FView.Controller.EditingController.HideEdit(False);
      except
        on E: Exception do
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarAviso(
              'GridArticulos.Desmontar: HideEdit ignorado: ' +
              E.Message);
      end;
    end;
    oInitEdit := ViewInitEdit;
    if MetodosIguales(
         TMethod(FView.OnInitEdit), TMethod(oInitEdit)) then
      FView.OnInitEdit := nil;
    oFocusedItemChanged := ViewFocusedItemChanged;
    if MetodosIguales(TMethod(FView.OnFocusedItemChanged),
         TMethod(oFocusedItemChanged)) then
      FView.OnFocusedItemChanged := nil;
    if Assigned(FBusqueda) then
    begin
      oEditKeyDown := ViewEditKeyDown;
      if MetodosIguales(TMethod(FView.OnEditKeyDown),
           TMethod(oEditKeyDown)) then
        FView.OnEditKeyDown := nil;
    end;
  end;
  FComboAtributoEnCurso := False;
  if Assigned(FColArticulo) then
  begin
    if Assigned(FBusqueda) then
    begin
      oGetProperties := FBusqueda.ArticuloGetProperties;
      if MetodosIguales(TMethod(FColArticulo.OnGetProperties),
           TMethod(oGetProperties)) then
        FColArticulo.OnGetProperties := nil;
    end;
    if FColArticulo.Properties is TcxButtonEditProperties then
    begin
      TcxButtonEditProperties(
        FColArticulo.Properties).OnButtonClick := nil;
      TcxButtonEditProperties(
        FColArticulo.Properties).OnValidate := nil;
    end;
  end;
  for iAtributo := Low(FColAtributo) to High(FColAtributo) do
  begin
    if Assigned(FColAtributo[iAtributo]) then
    begin
      FColAtributo[iAtributo].OnCustomDrawCell := nil;
      if FColAtributo[iAtributo].Properties is
         TcxButtonEditProperties then
        TcxButtonEditProperties(
          FColAtributo[iAtributo].Properties).OnButtonClick := nil
      else if FColAtributo[iAtributo].Properties is
              TcxComboBoxProperties then
      begin
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnClosePopup := nil;
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnDrawItem := nil;
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnInitPopup := nil;
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnPopup := nil;
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnCloseUp := nil;
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnChange := nil;
        TcxComboBoxProperties(
          FColAtributo[iAtributo].Properties).OnButtonClick := nil;
      end;
      SetLength(FOpcionesAtributo[iAtributo], 0);
      FArticuloOpcionesAtributo[iAtributo] := '';
    end;
  end;
  // HideEdit puede cerrar el popup y volver a programar una confirmacion.
  CancelarConfirmacionCombo;
  if Assigned(FTimerEnterAsTab) then
    FTimerEnterAsTab.Enabled := False;
  LiberarEnterAsTab(nil);
  RestaurarEventoSalidaSitio;
  RestaurarEventosDataSet;
  FreeAndNil(FBusqueda);
  FColArticulo := nil;
  FColNumeroAtributos := nil;
  for iAtributo := Low(FColAtributo) to High(FColAtributo) do
    FColAtributo[iAtributo] := nil;
  FCds := nil;
  FView := nil;
  FOnResuelto := nil;
  FOnEntrarEdicion := nil;
  FOnSalirEdicion := nil;
end;

procedure TGridArticulosLineas.RefrescarVisibilidadAtributos(
  AMinimoAtributos: Integer);
var
  i: Integer;
begin
  SincronizarVisibilidadAtributosGrid(
    FView,
    FColNumeroAtributos,
    FColAtributo,
    AMinimoAtributos,
    FMaximoAtributosVisibles);
  for i := 1 to 5 do
    if FColAtributo[i] <> nil then
    begin
      if FNombresAtributosGenericos then
        FColAtributo[i].Caption := Format(SCaptionAtributoN, [i]);
      AjustarAnchoColumnaAtributo(
        FColAtributo[i],
        EsAtributoConPaleta(FConn, FColAtributo[i].Caption));
    end;
end;

procedure TGridArticulosLineas.SetMaximoAtributosVisibles(
  AValue: Integer);
begin
  if AValue < 0 then
    FMaximoAtributosVisibles := 0
  else if AValue > 5 then
    FMaximoAtributosVisibles := 5
  else
    FMaximoAtributosVisibles := AValue;
  RefrescarVisibilidadAtributos;
end;

procedure TGridArticulosLineas.Construir;
begin
  FView.BeginUpdate;
  try
    FView.ClearItems;
    CrearColumnaArticulo;
    CrearColumnaNumeroAtributos;
    CrearColumnaUnidadOculta;
    CrearColumnasAtributo;
  finally
    FView.EndUpdate;
  end;
  RefrescarVisibilidadAtributos;
  InstalarEventosDataSet;
  // Al entrar en una celda de atributo vacia, abre el selector configurado
  // automaticamente. Se engancha en OnInitEdit.
  FView.OnInitEdit := ViewInitEdit;
  // OnEditKeyDown del grid: resuelve el codigo en la celda al pulsar Enter
  // (lector Codigo+CR o tecleo manual). Es el evento fiable para la celda.
  FView.OnEditKeyDown := ViewEditKeyDown;
  // Un articulo ya resuelto usa un ButtonEdit de solo lectura y puede no
  // tener editor activo. Su Enter se captura en la vista para continuar por
  // el primer atributo pendiente.
  InstalarEventoTeclado;
  // Restauracion del EnterAsTab al abandonar las columnas propias.
  FView.OnFocusedItemChanged := ViewFocusedItemChanged;
  InstalarEventoSalidaSitio;
  // Flujo tipo Excel: Enter pasa a la siguiente celda y al llegar al final
  // de la fila salta a la siguiente. NO usamos NewItemRow: la linea nueva se
  // anyade sola al completar un SKU (lo hace el host en OnResuelto).
  FView.OptionsBehavior.GoToNextCellOnEnter := True;
  FView.OptionsBehavior.FocusFirstCellOnNewRecord := True;
  // Mismos parametros de comportamiento/vista que el grid de ventas de
  // inMtoCajaOpe (tvLineasOpe): el ciclo de foco vuelve a la primera celda de
  // la fila siguiente, las columnas reparten el ancho del grid y se muestra un
  // aviso cuando no hay articulos. Con DesplazamientoHorizontal las
  // columnas conservan su ancho y el grid se desplaza a la derecha.
  FView.OptionsBehavior.FocusCellOnCycle := True;
  FView.OptionsView.ColumnAutoWidth := not FDesplazamientoHorizontal;
  FView.OptionsView.NoDataToDisplayInfoText :=
    SCaptionSinArticulos;
  // Navegador pequeño embebido: navegar + añadir al final + borrar.
  FView.Navigator.Visible := True;
  FView.Navigator.Buttons.First.Visible := True;
  FView.Navigator.Buttons.Prior.Visible := True;
  FView.Navigator.Buttons.Next.Visible := True;
  FView.Navigator.Buttons.Last.Visible := True;
  FView.Navigator.Buttons.Insert.Visible := False;
  FView.Navigator.Buttons.Append.Visible := True;
  FView.Navigator.Buttons.Delete.Visible := True;
  FView.Navigator.Buttons.PriorPage.Visible := False;
  FView.Navigator.Buttons.NextPage.Visible := False;
  FView.Navigator.Buttons.Edit.Visible := False;
  FView.Navigator.Buttons.Post.Visible := False;
  FView.Navigator.Buttons.Cancel.Visible := False;
  FView.Navigator.Buttons.Refresh.Visible := False;
  FView.Navigator.Buttons.SaveBookmark.Visible := False;
  FView.Navigator.Buttons.GotoBookmark.Visible := False;
  FView.Navigator.Buttons.Filter.Visible := False;
end;

procedure TGridArticulosLineas.MostrarColumnasAtributosArticulo(
  const ACodArt: string);
begin
  if Trim(ACodArt) <> '' then
    ActualizarColumnasAtributo(ACodArt);
end;

// Cuando el cxGrid crea el editor in-place de una celda, configura la entrada
// de articulo o el selector de atributo sin tocar las Properties temporales
// del editor.
procedure TGridArticulosLineas.ViewInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  InstalarEventoSalidaSitio;
  // Al abrir un editor de las columnas de esta controladora (articulo o
  // atributo), avisa al host para que desactive su EnterAsTab. La salida
  // del sitio restaura el estado; con paleta tambien lo hace cada columna.
  if (AItem = FColArticulo) or
     ((AItem <> nil) and (AItem.Tag >= 1) and (AItem.Tag <= 5)) then
  begin
    SolicitarDesactivarEnterAsTab(AEdit);
    if not FUsarCombosAtributos then
      THackWinCtrl(AEdit).OnExit := EditorSalir;
  end;
  // Celda de articulo: enganchamos OnKeyPress para capturar el lector de
  // codigo de barras (STX...ETX) y resolver al recibir ETX.
  if (AItem = FColArticulo) and (AEdit is TcxCustomTextEdit) then
  begin
    LogSes('GridArt.InitEdit articulo: editor=' + AEdit.ClassName);
    FBusqueda.ConfigurarEditorArticulo(TcxCustomTextEdit(AEdit));
    // Sugerencias en vivo: al teclear se rearma el debounce que abre el
    // desplegable filtrado (igual que inMtoCajaOpe). El lector (STX/ETX)
    // consume sus teclas en ArticuloKeyPress, asi que no dispara el OnChange.
  end
  else if (AItem <> nil) and (AItem.Tag >= 1) and
          (AItem.Tag <= 5) then
    ConfigurarEditorAtributo(AItem.Tag, AEdit);
end;

procedure TGridArticulosLineas.ViewKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) and
     FUsarCombosAtributos and Assigned(FView) and
     (FView.Controller.FocusedColumn = FColArticulo) and
     ProgramarAvanceDesdeArticulo then
    Key := 0;
  if (Key <> 0) and Assigned(FOnKeyDownOriginal) then
    FOnKeyDownOriginal(Sender, Key, Shift);
end;

procedure TGridArticulosLineas.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  EsDesplegableAbierto: Boolean;
begin
  EsDesplegableAbierto := (AEdit is TcxCustomDropDownEdit) and
    TcxCustomDropDownEdit(AEdit).DroppedDown;
  if (Key = VK_RETURN) and (Shift = []) and
     FUsarCombosAtributos and (AItem = FColArticulo) and
     Assigned(AEdit) and not EsDesplegableAbierto and
     ProgramarAvanceDesdeArticulo then
    Key := 0
  else
    FBusqueda.ViewEditKeyDown(Sender, AItem, AEdit, Key, Shift);
end;

procedure TGridArticulosLineas.ConfigurarEditorAtributo(
  AOrden: Integer; AEdit: TcxCustomEdit);
var
  Articulo: string;
  Boton: TcxButtonEdit;
  Combo: TcxComboBox;
  ValorActual: string;
begin
  Articulo := '';
  ValorActual := '';
  if FCds.Active and not FCds.IsEmpty then
  begin
    Articulo := FCds.FieldByName(FCampos.CodigoArt).AsString;
    ValorActual := FCds.FieldByName(
      FCampos.AttrValor[AOrden]).AsString;
  end;
  if AEdit is TcxComboBox then
  begin
    Combo := TcxComboBox(AEdit);
    Combo.Tag := AOrden;
    // OnInitEdit llega con el editor ya clonado: se carga su lista activa,
    // sin modificar las Properties compartidas de la columna.
    CargarOpcionesCombo(AOrden, Articulo);
    CopiarOpcionesCombo(AOrden, Combo.ActiveProperties.Items);
    Combo.SelectAll;
    FGlifoSwatch.PrepararEditor(Combo, ValorActual);
    if (Articulo <> '') and (Trim(ValorActual) = '') then
      Combo.OnEnter := AtributoEnter
    else
      Combo.OnEnter := nil;
  end
  else if AEdit is TcxButtonEdit then
  begin
    Boton := TcxButtonEdit(AEdit);
    Boton.Tag := AOrden;
    if FCds.Active and not FCds.IsEmpty and
       (Trim(ValorActual) = '') then
      Boton.OnEnter := AtributoEnter
    else
      Boton.OnEnter := nil;
  end;
end;

// OnEnter single-shot de una celda de atributo vacia: difiere la apertura de
// su selector para que el editor in-place termine de parentar.
procedure TGridArticulosLineas.AtributoEnter(Sender: TObject);
var
  Orden: Integer;
begin
  Orden := 0;
  if Sender is TcxComboBox then
  begin
    Orden := TcxComboBox(Sender).Tag;
    TcxComboBox(Sender).OnEnter := nil;
  end
  else if Sender is TcxButtonEdit then
  begin
    Orden := TcxButtonEdit(Sender).Tag;
    TcxButtonEdit(Sender).OnEnter := nil;
  end;
  if not FAbriendoSelector and (Orden >= 1) and (Orden <= 5) then
  begin
    FOrdenPopupPend := Orden;
    FTimerPopup.Enabled := False;
    FTimerPopup.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.TimerPopupTimer(Sender: TObject);
var
  Columna: TcxGridColumn;
  iOrden: Integer;
begin
  FTimerPopup.Enabled := False;
  iOrden := FOrdenPopupPend;
  FOrdenPopupPend := 0;
  Columna := nil;
  if Assigned(FView) then
    Columna := FView.Controller.FocusedColumn;
  if (iOrden >= 1) and (iOrden <= 5) and
     Assigned(FView) and FocoDentroDeVista and
     Assigned(Columna) and (Columna.Tag = iOrden) then
    AbrirSelectorOrden(iOrden);
end;

procedure TGridArticulosLineas.AtributoComboInitPopup(Sender: TObject);
var
  Articulo: string;
  Combo: TcxCustomComboBox;
  Orden: Integer;
begin
  Orden := 0;
  if Sender is TcxControl then
    Orden := ObtenerOrdenEditorCombo(TcxControl(Sender));
  if (Orden >= 1) and (Orden <= 5) and Assigned(FCds) and
     FCds.Active and not FCds.IsEmpty then
  begin
    Articulo := FCds.FieldByName(FCampos.CodigoArt).AsString;
    if not SameText(
         FArticuloOpcionesAtributo[Orden], Trim(Articulo)) then
      CargarOpcionesCombo(Orden, Articulo);
    if Sender is TcxCustomComboBox then
    begin
      Combo := TcxCustomComboBox(Sender);
      CopiarOpcionesCombo(Orden, Combo.ActiveProperties.Items);
    end;
  end;
end;

procedure TGridArticulosLineas.AtributoComboPopup(Sender: TObject);
begin
  FComboAtributoEnCurso := True;
  SolicitarDesactivarEnterAsTab(Sender);
end;

procedure TGridArticulosLineas.CargarOpcionesCombo(
  AOrden: Integer; const AArticulo: string);
var
  ArticuloNormalizado: string;
  Avs: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  if (AOrden >= Low(FOpcionesAtributo)) and
     (AOrden <= High(FOpcionesAtributo)) then
  begin
    ArticuloNormalizado := Trim(AArticulo);
    if not SameText(
         FArticuloOpcionesAtributo[AOrden], ArticuloNormalizado) then
    begin
      SetLength(FOpcionesAtributo[AOrden], 0);
      if ArticuloNormalizado <> '' then
      begin
        Avs := FLookup.ObtenerAvsEnSkus(
          ArticuloNormalizado, AOrden);
        SetLength(FOpcionesAtributo[AOrden], Length(Avs));
        for i := 0 to High(Avs) do
          FOpcionesAtributo[AOrden][i] := Avs[i].Valor;
      end;
      FArticuloOpcionesAtributo[AOrden] := ArticuloNormalizado;
    end;
  end;
end;

procedure TGridArticulosLineas.CopiarOpcionesCombo(
  AOrden: Integer; AItems: TStrings);
var
  i: Integer;
begin
  if (AOrden >= Low(FOpcionesAtributo)) and
     (AOrden <= High(FOpcionesAtributo)) and (AItems <> nil) then
  begin
    AItems.BeginUpdate;
    try
      AItems.Clear;
      for i := 0 to High(FOpcionesAtributo[AOrden]) do
        AItems.Add(FOpcionesAtributo[AOrden][i]);
    finally
      AItems.EndUpdate;
    end;
  end;
end;

function TGridArticulosLineas.BuscarValorCombo(
  AOrden: Integer; const AValor: string;
  out AValorCanonico: string): Boolean;
var
  i: Integer;
  ValorBuscado: string;
begin
  Result := False;
  AValorCanonico := '';
  ValorBuscado := Trim(AValor);
  i := 0;
  if (AOrden >= Low(FOpcionesAtributo)) and
     (AOrden <= High(FOpcionesAtributo)) then
  begin
    while (i <= High(FOpcionesAtributo[AOrden])) and not Result do
    begin
      Result := SameText(
        Trim(FOpcionesAtributo[AOrden][i]), ValorBuscado);
      if Result then
        AValorCanonico := FOpcionesAtributo[AOrden][i]
      else
        Inc(i);
    end;
  end;
end;

function TGridArticulosLineas.ObtenerOrdenEditorCombo(
  AControl: TcxControl): Integer;
var
  Columna: TcxGridColumn;
begin
  Result := 0;
  if AControl <> nil then
    Result := AControl.Tag;
  if ((Result < Low(FOpcionesAtributo)) or
      (Result > High(FOpcionesAtributo))) and Assigned(FView) then
  begin
    Columna := FView.Controller.FocusedColumn;
    if Columna <> nil then
      Result := Columna.Tag;
  end;
end;

function TGridArticulosLineas.ObtenerInfoColorCombo(
  AOrden: Integer; const ATexto: string;
  out AInfo: TInfoBasico): Boolean;
var
  Articulo: string;
  IdValorAtributo: string;
  Mapa: TDictionary<string, string>;
  NombreAtributo: string;
begin
  Result := False;
  AInfo := Default(TInfoBasico);
  if (AOrden >= Low(FOpcionesAtributo)) and
     (AOrden <= High(FOpcionesAtributo)) and Assigned(FCds) and
     FCds.Active and not FCds.IsEmpty then
  begin
    Articulo := FCds.FieldByName(FCampos.CodigoArt).AsString;
    NombreAtributo := FCds.FieldByName(
      FCampos.AttrNombre[AOrden]).AsString;
    if (Trim(NombreAtributo) = '') and
       Assigned(FColAtributo[AOrden]) then
      NombreAtributo := FColAtributo[AOrden].Caption;
    IdValorAtributo := '';
    Mapa := ObtenerMapaAtributosGlobal(FConn);
    if Mapa <> nil then
      Mapa.TryGetValue(
        UpperCase(Trim(NombreAtributo)), IdValorAtributo);
    // Igual que la celda (PintarCeldaSwatchAtributoSiAplica): primero
    // la asignacion del articulo y, si no la hay, la paleta global del
    // atributo. Sin este segundo paso los basicos usados tal cual
    // (NEGRO, MARRON...) salian sin cuadradito en la lista.
    Result := (Trim(IdValorAtributo) <> '') and
      (ObtenerInfoBasicoArticulo(
         FConn, Articulo, IdValorAtributo, ATexto, AInfo) or
       ObtenerInfoBasico(FConn, IdValorAtributo, ATexto, AInfo));
  end;
end;

function TGridArticulosLineas.ResolverColorEditor(
  AEditor: TcxComboBox; const ATexto: string;
  out AInfo: TInfoBasico): Boolean;
begin
  Result := ObtenerInfoColorCombo(
    ObtenerOrdenEditorCombo(AEditor), ATexto, AInfo);
end;

procedure TGridArticulosLineas.AtributoComboDrawItem(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas;
  AIndex: Integer; const ARect: TRect; AState: TOwnerDrawState);
var
  HayColor: Boolean;
  Info: TInfoBasico;
  Texto: string;
begin
  // Con lsEditFixedList este evento solo pinta la lista. Solo se busca
  // color para el editor en linea: las celdas sin editar las resuelve
  // el OnCustomDrawCell del host con su fila.
  if (AControl <> nil) and (ACanvas <> nil) and
     (AIndex >= 0) and
     (AIndex < AControl.ActiveProperties.Items.Count) then
  begin
    Texto := AControl.ActiveProperties.Items[AIndex];
    Info := Default(TInfoBasico);
    HayColor := Assigned(FView) and
      (FView.Controller.EditingController.Edit = AControl) and
      ObtenerInfoColorCombo(
        ObtenerOrdenEditorCombo(AControl), Texto, Info);
    PintarOpcionComboConSwatch(
      ACanvas, ARect, AState, Texto, HayColor, Info);
  end;
end;

procedure TGridArticulosLineas.AtributoComboClosePopup(
  AControl: TcxControl; AReason: TcxEditCloseUpReason);
var
  Confirmar: Boolean;
  Orden: Integer;
  ValorActual: string;
  ValorCanonico: string;
begin
  if (AControl is TcxCustomComboBox) and
     (AReason in [crClose, crEnter]) then
  begin
    Orden := ObtenerOrdenEditorCombo(AControl);
    if BuscarValorCombo(
         Orden,
         TcxCustomComboBox(AControl).Text,
         ValorCanonico) then
    begin
      Confirmar := AReason = crEnter;
      if (AReason = crClose) and Assigned(FCds) and
         FCds.Active and not FCds.IsEmpty then
      begin
        ValorActual := FCds.FieldByName(
          FCampos.AttrValor[Orden]).AsString;
        Confirmar := not SameText(
          Trim(ValorActual), Trim(ValorCanonico));
      end;
      if Confirmar then
        ProgramarConfirmacionCombo(Orden, ValorCanonico);
    end;
  end;
  // El texto ya refleja la opcion elegida en la lista.
  FGlifoSwatch.ActualizarEditor(AControl);
end;

procedure TGridArticulosLineas.AtributoComboCloseUp(Sender: TObject);
begin
  FComboAtributoEnCurso := False;
  if Assigned(FTimerEnterAsTab) then
  begin
    FTimerEnterAsTab.Enabled := False;
    FTimerEnterAsTab.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.ProgramarConfirmacionCombo(
  AOrden: Integer; const AValor: string);
begin
  if not FConfirmacionPendiente and Assigned(FTimerConfirmacion) then
  begin
    FOrdenConfirmacionPendiente := AOrden;
    FValorConfirmacionPendiente := AValor;
    FConfirmacionPendiente := True;
    FTimerConfirmacion.Enabled := False;
    FTimerConfirmacion.Enabled := True;
  end;
end;

procedure TGridArticulosLineas.CancelarAperturaSelector;
begin
  if Assigned(FTimerPopup) then
    FTimerPopup.Enabled := False;
  if Assigned(FTimerAvanceArticulo) then
    FTimerAvanceArticulo.Enabled := False;
  FOrdenPopupPend := 0;
end;

procedure TGridArticulosLineas.CancelarConfirmacionCombo;
begin
  if Assigned(FTimerConfirmacion) then
    FTimerConfirmacion.Enabled := False;
  FConfirmacionPendiente := False;
  FOrdenConfirmacionPendiente := 0;
  FValorConfirmacionPendiente := '';
end;

function TGridArticulosLineas.ProgramarAvanceDesdeArticulo: Boolean;
var
  iOrden: Integer;
  iTotal: Integer;
  sArticulo: string;
begin
  Result := False;
  if Assigned(FTimerAvanceArticulo) and Assigned(FCds) and
     FCds.Active and not FCds.IsEmpty and
     (Trim(FCds.FieldByName(FCampos.CodigoArt).AsString) <> '') then
  begin
    sArticulo := Trim(
      FCds.FieldByName(FCampos.CodigoArt).AsString);
    iTotal := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
    iOrden := 1;
    while (iOrden <= iTotal) and (iOrden <= 5) and not Result do
    begin
      Result := Trim(FCds.FieldByName(
        FCampos.AttrValor[iOrden]).AsString) = '';
      Inc(iOrden);
    end;
    if not Result and (iTotal <= 0) then
      Result :=
        (Trim(FCds.FieldByName(FCampos.Descripcion).AsString) <> '') or
        (Trim(FCds.FieldByName(FCampos.CodigoUnidad).AsString) =
         sArticulo);
    if Result then
    begin
      FTimerAvanceArticulo.Enabled := False;
      FTimerAvanceArticulo.Enabled := True;
    end;
  end;
end;

procedure TGridArticulosLineas.TimerConfirmacionTimer(Sender: TObject);
begin
  FTimerConfirmacion.Enabled := False;
  ConfirmarAtributoComboPendiente;
end;

procedure TGridArticulosLineas.TimerEnterAsTabTimer(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  FTimerEnterAsTab.Enabled := False;
  Editor := nil;
  if Assigned(FView) and
     Assigned(FView.Controller.EditingController) and
     FView.Controller.EditingController.IsEditing then
    Editor := FView.Controller.EditingController.Edit;
  if FocoDentroDeVista then
  begin
    if Assigned(Editor) then
      SolicitarDesactivarEnterAsTab(Editor)
    else if Assigned(FView) then
      SolicitarDesactivarEnterAsTab(FView.Site);
  end
  else
  begin
    CancelarAperturaSelector;
    LiberarEnterAsTab(nil);
  end;
end;

procedure TGridArticulosLineas.TimerAvanceArticuloTimer(Sender: TObject);
var
  sArticulo: string;
begin
  FTimerAvanceArticulo.Enabled := False;
  if FocoDentroDeVista and Assigned(FView) and Assigned(FCds) and
     FCds.Active and not FCds.IsEmpty then
  begin
    if Assigned(FView.Controller.EditingController) and
       FView.Controller.EditingController.IsEditing then
    begin
      try
        FView.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarAviso(
              'GridArticulos.AvanceArticulo: HideEdit ignorado: ' +
              E.Message);
      end;
    end;
    if FocoDentroDeVista then
    begin
      sArticulo := Trim(
        FCds.FieldByName(FCampos.CodigoArt).AsString);
      if (sArticulo <> '') and
         (FCds.FieldByName(FCampos.NumAtributos).AsInteger <= 0) then
      begin
        if not CdsEditando then
          FCds.Edit;
        ActualizarColumnasAtributo(sArticulo);
      end;
      if not AvanzarSiguienteAtributo then
        FView.Controller.FocusNextCell(True, False, True, False);
    end;
  end;
end;

procedure TGridArticulosLineas.ConfirmarAtributoComboPendiente;
var
  Orden: Integer;
  Valor: string;
begin
  if FConfirmacionPendiente then
  begin
    Orden := FOrdenConfirmacionPendiente;
    Valor := FValorConfirmacionPendiente;
    FConfirmacionPendiente := False;
    FOrdenConfirmacionPendiente := 0;
    FValorConfirmacionPendiente := '';
    if (Orden >= 1) and (Orden <= 5) and Assigned(FCds) and
       FCds.Active and not FCds.IsEmpty then
    begin
      if FCds.State = dsBrowse then
        FCds.Edit;
      if FCds.State in [dsEdit, dsInsert] then
      begin
        FCds.FieldByName(FCampos.AttrValor[Orden]).AsString := Valor;
        if Assigned(FView) and
           Assigned(FView.Controller.EditingController) and
           FView.Controller.EditingController.IsEditing then
          FView.Controller.EditingController.HideEdit(False);
        AplicarSkuYAvisar;
        if not AvanzarSiguienteAtributo then
          MostrarEditorArticulo;
      end;
    end;
  end;
end;

procedure TGridArticulosLineas.CrearColumnaArticulo;
var
  Propiedades: TcxButtonEditProperties;
  Boton: TcxEditButton;
begin
  FColArticulo := FView.CreateColumn;
  if FMostrarCodigoPadre then
    FColArticulo.Caption := SCaptionColArticulo
  else
    FColArticulo.Caption := SCaptionColArticuloSku;
  FColArticulo.DataBinding.FieldName := FCampos.CodigoArt;
  FColArticulo.Width := 220;
  FColArticulo.PropertiesClass := TcxButtonEditProperties;
  Propiedades := TcxButtonEditProperties(FColArticulo.Properties);
  Propiedades.Buttons.Clear;
  Boton := Propiedades.Buttons.Add;
  Boton.Default := True;
  Boton.Kind := bkEllipsis;
  // Las lineas ya resueltas no se editan encima: se borra la linea o se usa
  // el boton. Las lineas nuevas usan el combo editable por OnGetProperties.
  Propiedades.ReadOnly := True;
  Propiedades.OnValidate := FBusqueda.ArticuloValidate;
  // El boton (ellipsis) abre el buscador de SKU.
  Propiedades.OnButtonClick := FBusqueda.ArticuloButtonClick;
  // Editor por registro: si la celda esta vacia y enfocada, se usa el
  // ExtLookupComboBox con busqueda incremental; si no, el ButtonEdit de
  // arriba. Mismo patron que inMtoCajaOpe.tvArticuloGetProperties.
  FBusqueda.ConfigurarColumna(FColArticulo);
end;

procedure TGridArticulosLineas.SetAlmacenStock(const AValue: string);
begin
  if FAlmacenStock <> AValue then
  begin
    FAlmacenStock := AValue;
    FBusqueda.SetAlmacenStock(AValue);
  end;
end;

procedure TGridArticulosLineas.MostrarEditorArticulo;
begin
  if not FComboAtributoEnCurso then
    FBusqueda.MostrarEditorArticulo;
end;

procedure TGridArticulosLineas.BuscarContextual;
var
  Columna: TcxGridColumn;
begin
  Columna := FView.Controller.FocusedColumn;
  if Assigned(Columna) and (Columna.Tag >= 1) and
     (Columna.Tag <= 5) then
    AbrirSelectorOrden(Columna.Tag)
  else
    FBusqueda.BuscarArticulo;
end;

// Tras resolver un articulo decide el foco igual que la caja: si la linea aun
// necesita color/talla, salta a la primera columna pendiente y abre su
// selector; si el SKU ya quedo cerrado, deja el editor de articulo listo.
procedure TGridArticulosLineas.AvanzarTrasResolver;
var
  bPendiente: Boolean;
  iOrden, iTotal: Integer;
begin
  bPendiente := False;
  iOrden := 1;
  iTotal := 0;
  if FCds.Active and not FCds.IsEmpty then
    iTotal := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  while (iOrden <= iTotal) and not bPendiente do
  begin
    bPendiente := Trim(FCds.FieldByName(
      FCampos.AttrValor[iOrden]).AsString) = '';
    Inc(iOrden);
  end;
  if bPendiente then
    AvanzarSiguienteAtributo
  else
    MostrarEditorArticulo;
end;

procedure TGridArticulosLineas.DespuesResolverBusqueda;
begin
  if not FUsarCombosAtributos then
    LiberarEnterAsTab(nil);
  AvanzarTrasResolver;
end;

procedure TGridArticulosLineas.CrearColumnaNumeroAtributos;
begin
  FColNumeroAtributos := FView.CreateColumn;
  FColNumeroAtributos.Name := 'colNumeroAtributosDyn';
  FColNumeroAtributos.DataBinding.FieldName := FCampos.NumAtributos;
  FColNumeroAtributos.Visible := False;
  FColNumeroAtributos.VisibleForCustomization := False;
  FColNumeroAtributos.Options.Editing := False;
end;

// Columna oculta del SKU: con ella AcumularLineaExistente sabe, sin tocar
// el dataset, si otra linea ya tiene el SKU tecleado.
procedure TGridArticulosLineas.CrearColumnaUnidadOculta;
var
  oColumna: TcxGridDBColumn;
begin
  if (FCampos.CodigoUnidad <> '') and
     (FCds.FindField(FCampos.CodigoUnidad) <> nil) then
  begin
    oColumna := FView.CreateColumn;
    oColumna.Name := 'colUnidadDyn';
    oColumna.DataBinding.FieldName := FCampos.CodigoUnidad;
    oColumna.Visible := False;
    oColumna.VisibleForCustomization := False;
    oColumna.Options.Editing := False;
  end;
end;

procedure TGridArticulosLineas.CrearColumnasAtributo;
var
  i: Integer;
  Boton: TcxEditButton;
  Col: TcxGridDBColumn;
  PropiedadesBoton: TcxButtonEditProperties;
  PropiedadesCombo: TcxComboBoxProperties;
begin
  for i := 1 to 5 do
  begin
    Col := FView.CreateColumn;
    Col.Name := 'colAtributoDyn' + IntToStr(i);
    Col.Tag := i;
    Col.DataBinding.FieldName := FCampos.AttrValor[i];
    Col.Caption := '-';
    Col.Visible := False;
    Col.MinWidth := EscalarAncho(ANCHO_MIN_COL_ATRIBUTO);
    Col.Width := EscalarAncho(ANCHO_COL_ATRIBUTO);
    if FUsarCombosAtributos then
    begin
      Col.PropertiesClass := TcxComboBoxProperties;
      PropiedadesCombo := TcxComboBoxProperties(Col.Properties);
      // Seleccion cerrada: el texto escrito sirve solo para filtrar. El
      // cuadradito en edicion lo pone el boton-glifo (TGlifoSwatchCombo).
      PropiedadesCombo.DropDownListStyle := lsEditFixedList;
      PropiedadesCombo.DropDownRows := 15;
      PropiedadesCombo.ImmediateDropDownWhenKeyPressed := True;
      PropiedadesCombo.ImmediatePost := False;
      PropiedadesCombo.IncrementalFiltering := True;
      // Sin ifoUseContainsOperator: "4" muestra los valores que empiezan
      // por 4 y conserva el orden configurado del tallaje.
      PropiedadesCombo.IncrementalFilteringOptions :=
        [ifoHighlightSearchText];
      PropiedadesCombo.PostPopupValueOnTab := False;
      PropiedadesCombo.Sorted := False;
      PropiedadesCombo.OnClosePopup := AtributoComboClosePopup;
      PropiedadesCombo.OnDrawItem := AtributoComboDrawItem;
      // OnPopup marca el intervalo real visible y reafirma EnterAsTab.
      // Al cerrar se revisa en diferido si el grid sigue activo.
      PropiedadesCombo.OnInitPopup := AtributoComboInitPopup;
      PropiedadesCombo.OnPopup := AtributoComboPopup;
      PropiedadesCombo.OnCloseUp := AtributoComboCloseUp;
      FGlifoSwatch.ConfigurarBoton(PropiedadesCombo);
    end
    else
    begin
      Col.PropertiesClass := TcxButtonEditProperties;
      PropiedadesBoton := TcxButtonEditProperties(Col.Properties);
      PropiedadesBoton.ReadOnly := True;
      PropiedadesBoton.Buttons.Clear;
      Boton := PropiedadesBoton.Buttons.Add;
      Boton.Default := True;
      Boton.Kind := bkEllipsis;
      PropiedadesBoton.OnButtonClick := AtributoButtonClick;
    end;
    // Pinta el cuadradito de color en la celda (como caja/inventario).
    Col.OnCustomDrawCell := AtributoCustomDrawCell;
    FColAtributo[i] := Col;
  end;
end;

// El grid ya esta escalado a su PPI: el ancho asignado en codigo no lo escala
// DevExpress, asi que se convierte desde 96 ppp.
function TGridArticulosLineas.EscalarAncho(AAncho: Integer): Integer;
var
  Escala: TdxScaleFactor;
begin
  Escala := dxGetScaleFactor(FView.Control);
  Result := Escala.Apply(AAncho);
end;

// El host (facturas, pedidos...) pone el nombre del atributo en la cabecera
// por su cuenta, asi que se decide por la cabecera actual. El minimo hace de
// marca: solo se toca el ancho cuando la columna cambia de tipo, y se respeta
// el que el usuario le haya dado despues.
procedure TGridArticulosLineas.AjustarAnchoColumnaAtributo(
  AColumna: TcxGridDBColumn; AConPaleta: Boolean);
var
  iAncho, iMinimo: Integer;
begin
  iAncho := EscalarAncho(ANCHO_COL_ATRIBUTO);
  iMinimo := EscalarAncho(ANCHO_MIN_COL_ATRIBUTO);
  if AConPaleta then
  begin
    iAncho := EscalarAncho(ANCHO_COL_ATRIBUTO_PALETA);
    iMinimo := EscalarAncho(ANCHO_MIN_COL_ATRIBUTO_PALETA);
  end;
  if AColumna.MinWidth <> iMinimo then
  begin
    AColumna.MinWidth := iMinimo;
    AColumna.Width := iAncho;
  end;
end;

// Pinta el swatch de color en la celda de atributo si el valor casa con la
// paleta basica. Usa el helper "todo en uno" de inLibAtributosPaleta.
procedure TGridArticulosLineas.AtributoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  ColArticulo: TcxGridDBColumn;
  sArticulo, sTexto: string;
begin
  sArticulo := '';
  sTexto := '';
  if (AViewInfo <> nil) and (AViewInfo.GridRecord <> nil) then
  begin
    ColArticulo := FView.GetColumnByFieldName(FCampos.CodigoArt);
    if ColArticulo <> nil then
      sArticulo := VarToStr(
        AViewInfo.GridRecord.Values[ColArticulo.Index]);
    sTexto := AViewInfo.Text;
  end;
  if PintarCeldaSwatchArticuloSiAplica(
       FConn, ACanvas, AViewInfo, sArticulo, sTexto, nil) then
    ADone := True;
end;

function TGridArticulosLineas.ColumnaPorTag(ATag: Integer): TcxGridDBColumn;
begin
  if (ATag >= 1) and (ATag <= 5) then
    Result := FColAtributo[ATag]
  else
    Result := nil;
end;

function TGridArticulosLineas.GenerarSku: string;
var
  i, n: Integer;
  sValor: string;
begin
  Result := FCds.FieldByName(FCampos.CodigoArt).AsString;
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  for i := 1 to n do
  begin
    sValor := FCds.FieldByName(FCampos.AttrValor[i]).AsString;
    if sValor <> '' then
      Result := Result + '/' + sValor;
  end;
end;

// Actualiza la variacion de la linea y sincroniza la visibilidad con el
// maximo de atributos usado por TODO el documento. Una linea simple no puede
// ocultar las columnas que necesitan otras lineas.
procedure TGridArticulosLineas.ActualizarColumnasAtributo(
  const ACodArt: string);
var
  Atribs: TArray<TArticuloAtributo>;
  i: Integer;
  Col: TcxGridDBColumn;
begin
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  if CdsEditando then
    FCds.FieldByName(FCampos.NumAtributos).AsInteger := Length(Atribs);
  FView.BeginUpdate;
  try
    for i := 1 to 5 do
    begin
      Col := ColumnaPorTag(i);
      if Col <> nil then
      begin
        if i <= Length(Atribs) then
        begin
          if FUsarCombosAtributos then
            CargarOpcionesCombo(i, ACodArt);
          Col.Caption := Atribs[i - 1].NombreAtributo;
          if FUsarCombosAtributos then
            FGlifoSwatch.MostrarBoton(
              Col.Properties,
              EsAtributoConPaleta(FConn, Atribs[i - 1].NombreAtributo));
          Col.Options.Editing := True;
          if CdsEditando then
            FCds.FieldByName(FCampos.AttrNombre[i]).AsString :=
              Atribs[i - 1].NombreAtributo;
        end
        else
        begin
          if FUsarCombosAtributos then
          begin
            CargarOpcionesCombo(i, '');
            FGlifoSwatch.MostrarBoton(Col.Properties, False);
          end;
          if CdsEditando then
          begin
            FCds.FieldByName(FCampos.AttrNombre[i]).AsString := '';
            FCds.FieldByName(FCampos.AttrValor[i]).AsString := '';
          end;
        end;
      end;
    end;
  finally
    FView.EndUpdate;
  end;
  RefrescarVisibilidadAtributos(Length(Atribs));
end;

// Si algun atributo (talla/color) tiene un unico valor en los SKUs del
// articulo, lo fija solo; si con eso quedan todos resueltos, cierra el SKU y
// avisa al host (igual que la caja resuelve un articulo de una sola variante).
procedure TGridArticulosLineas.AutoCompletarAtributosUnicos(
  const ACodArt: string);
var
  i, n: Integer;
  Avs: TArray<TArticuloAtributoValor>;
  sSku: string;
  bTodos: Boolean;
begin
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  if n > 0 then
  begin
    bTodos := True;
    for i := 1 to n do
    begin
      if FCds.FieldByName(FCampos.AttrValor[i]).AsString = '' then
      begin
        if FUsarCombosAtributos and SameText(
             FArticuloOpcionesAtributo[i], Trim(ACodArt)) then
        begin
          if Length(FOpcionesAtributo[i]) = 1 then
            FCds.FieldByName(FCampos.AttrValor[i]).AsString :=
              FOpcionesAtributo[i][0]
          else
            bTodos := False;
        end
        else
        begin
          Avs := FLookup.ObtenerAvsEnSkus(ACodArt, i);
          if Length(Avs) = 1 then
            FCds.FieldByName(FCampos.AttrValor[i]).AsString :=
              Avs[0].Valor
          else
            bTodos := False;
        end;
      end;
    end;
    if bTodos then
    begin
      sSku := GenerarSku;
      FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku;
      if Assigned(FOnResuelto) then
        FOnResuelto(ACodArt, sSku,
          FCds.FieldByName(FCampos.Descripcion).AsString, True);
    end;
  end;
end;

// El SKU es CODIGO_ART/val1/val2...; vuelca val1..valN en ATTRn_VALOR para que
// las columnas de talla/color muestren los valores de un SKU ya cerrado.
procedure TGridArticulosLineas.RellenarAtributosDesdeSku(const ACodArt,
  ASku: string);
var
  aValores: TArray<string>;
  i: Integer;
begin
  aValores := ValoresLegiblesLineaSku(ACodArt, ASku, FLookup);
  for i := 0 to High(aValores) do
  begin
    if i < 5 then
      FCds.FieldByName(FCampos.AttrValor[i + 1]).AsString := aValores[i];
  end;
end;

function TGridArticulosLineas.ResolverEntrada(const AEntrada: string): Boolean;
var
  R: TArtResolucionEntrada;
  sCodArt, sSku, sDesc, sEntrada: string;
  bCompleto: Boolean;
  i: Integer;
begin
  Result := False;
  // Quita STX/ETX/CR/LF que mete el lector de codigo de barras.
  sEntrada := FBusqueda.LimpiarEntrada(AEntrada);
  if sEntrada <> '' then
  begin
    R := FValidador.Resolver(sEntrada);
    if not R.Encontrado then
    begin
      // Codigo fuera de catalogo: se admite como linea libre si procede.
      if FAceptarNoCatalogo then
      begin
        if not CdsEditando then
          FCds.Edit;
        FCds.FieldByName(FCampos.CodigoArt).AsString := sEntrada;
        FCds.FieldByName(FCampos.CodigoUnidad).AsString := '';
        FCds.FieldByName(FCampos.Descripcion).AsString := '';
        ActualizarColumnasAtributo(sEntrada);
        if Assigned(FOnResuelto) then
          FOnResuelto(sEntrada, '', '', True);
        Result := True;
      end;
    end
    else
    begin
      sCodArt := R.CodigoArticulo;
      sSku := R.CodigoSku;
      sDesc := R.DescripcionArticulo;
      bCompleto := (sSku <> '') and (not R.RequiereSku);
      if bCompleto and
         not (R.TraeLote and Assigned(FOnLoteLeido)) and
         AcumularLineaExistente(sCodArt, sSku, sDesc) then
        Result := True
      else
      begin
        if not CdsEditando then
          FCds.Edit;
        if not SameText(
          Trim(FCds.FieldByName(FCampos.CodigoArt).AsString),
          sCodArt) then
        begin
          for i := 1 to 5 do
            FCds.FieldByName(FCampos.AttrValor[i]).AsString := '';
        end;
        FCds.FieldByName(FCampos.CodigoArt).AsString := sCodArt;
        FCds.FieldByName(FCampos.Descripcion).AsString := sDesc;
        ActualizarColumnasAtributo(sCodArt);
        if bCompleto then
        begin
          FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku;
          RellenarAtributosDesdeSku(sCodArt, sSku);
          if Assigned(FOnResuelto) then
            FOnResuelto(sCodArt, sSku, sDesc, True);
        end
        else
        begin
          FCds.FieldByName(FCampos.CodigoUnidad).AsString := sCodArt;
          AutoCompletarAtributosUnicos(sCodArt);
        end;
        // Articulo sin SKUs: la unidad es el propio articulo.
        if R.TraeLote and Assigned(FOnLoteLeido) and
           (bCompleto or ((sSku = '') and (not R.RequiereSku))) then
          FOnLoteLeido(sCodArt,
            FCds.FieldByName(FCampos.CodigoUnidad).AsString, R);
        Result := True;
      end;
    end;
  end;
end;

function TGridArticulosLineas.ResolverLectura(
  const AEntrada: string): Boolean;
begin
  FAcumularRepetidos := True;
  try
    Result := ResolverEntrada(AEntrada);
  finally
    FAcumularRepetidos := False;
  end;
end;

function TGridArticulosLineas.AcumularLineaExistente(const ACodArt,
  ASku, ADesc: string): Boolean;
var
  bEncontrada: Boolean;
begin
  Result := False;
  // FZ-ISSUE-232: solo una lectura de lector acumula; lo tecleado escribe
  // la linea en curso (varias lineas del mismo articulo son validas).
  if (FAcumularRepetidos or
      (Assigned(FBusqueda) and FBusqueda.ResolviendoLectura)) and
  // Si se sabe que ninguna otra linea tiene el SKU no se cancela la linea
  // en curso: con la de "+" en insercion, el Cancel la borraba y el SKU se
  // escribia en la linea anterior (FZ-ISSUE-011).
     (FCampos.Cantidad <> '') and
     (FCds.FindField(FCampos.Cantidad) <> nil) and
     ((not OtraLineaConSkuEnRejilla(
        FView, FCampos.CodigoUnidad, ASku, bEncontrada)) or
      bEncontrada) then
  begin
    // Soltar la edicion de la linea actual (en blanco o a medias)
    // antes de mover el cursor a la linea destino.
    if CdsEditando then
      FCds.Cancel;
    if FCds.Locate(FCampos.CodigoUnidad, ASku, [loCaseInsensitive]) then
    begin
      FCds.Edit;
      FCds.FieldByName(FCampos.Cantidad).AsFloat :=
        FCds.FieldByName(FCampos.Cantidad).AsFloat + 1;
      FCds.Post;
      if Assigned(FOnResuelto) then
        FOnResuelto(ACodArt, ASku, ADesc, True);
      Result := True;
    end;
  end;
end;

procedure TGridArticulosLineas.AplicarSkuYAvisar;
var
  sSku, sCodArt, sDesc: string;
  n: Integer;
  bCompleto: Boolean;
begin
  sCodArt := FCds.FieldByName(FCampos.CodigoArt).AsString;
  sDesc := FCds.FieldByName(FCampos.Descripcion).AsString;
  sSku := GenerarSku;
  FCds.FieldByName(FCampos.CodigoUnidad).AsString := sSku;
  // Completo cuando el SKU lleva tantos '/' como atributos requeridos.
  n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
  bCompleto := (n > 0) and
    (Length(sSku) - Length(StringReplace(sSku, '/', '', [rfReplaceAll])) >= n);
  if Assigned(FOnResuelto) then
    FOnResuelto(sCodArt, sSku, sDesc, bCompleto);
end;

// Click en el boton de una columna de atributo: abre el selector configurado.
procedure TGridArticulosLineas.AtributoButtonClick(Sender: TObject;
                                                   AButtonIndex: Integer);
var
  Col: TcxGridColumn;
begin
  Col := FView.Controller.FocusedColumn;
  if (Col <> nil) and (Col.Tag >= 1) and (Col.Tag <= 5) then
    AbrirSelectorOrden(Col.Tag);
end;

procedure TGridArticulosLineas.AbrirSelectorOrden(AOrden: Integer);
begin
  if FUsarCombosAtributos then
    AbrirComboOrden(AOrden)
  else
    AbrirPaletaOrden(AOrden);
end;

procedure TGridArticulosLineas.AbrirComboOrden(AOrden: Integer);
var
  Articulo: string;
  Columna: TcxGridDBColumn;
  Combo: TcxComboBox;
  Editor: TcxCustomEdit;
begin
  if (AOrden >= 1) and (AOrden <= 5) and
     FCds.Active and not FCds.IsEmpty then
  begin
    Articulo := FCds.FieldByName(FCampos.CodigoArt).AsString;
    Columna := ColumnaPorTag(AOrden);
    if (Columna <> nil) and
       (Columna.Properties is TcxComboBoxProperties) then
      CargarOpcionesCombo(AOrden, Articulo)
    else
      SetLength(FOpcionesAtributo[AOrden], 0);
    if HayValoresAtributo(AOrden, Length(FOpcionesAtributo[AOrden])) then
    begin
      FAbriendoSelector := True;
      try
        if FView.Controller.FocusedColumn <> Columna then
          FView.Controller.FocusedColumn := Columna;
        if not FView.Controller.EditingController.IsEditing then
        begin
          try
            FView.Controller.EditingController.ShowEdit;
          except
            on E: Exception do
              if Assigned(FRegistroLog) then
                FRegistroLog.RegistrarAviso(
                  'GridArticulos.AbrirComboOrden: ShowEdit ignorado: ' +
                  E.Message);
          end;
        end;
        Editor := nil;
        if FView.Controller.EditingController.IsEditing then
          Editor := FView.Controller.EditingController.Edit;
        if Editor is TcxComboBox then
        begin
          Combo := TcxComboBox(Editor);
          Combo.Tag := AOrden;
          SolicitarDesactivarEnterAsTab(Combo);
          if not Combo.DroppedDown then
          begin
            try
              Combo.DroppedDown := True;
            except
              on E: Exception do
                if Assigned(FRegistroLog) then
                  FRegistroLog.RegistrarAviso(
                    'GridArticulos.AbrirComboOrden: popup ignorado: ' +
                    E.Message);
            end;
          end;
        end;
      finally
        FAbriendoSelector := False;
      end;
    end;
  end;
end;

function TGridArticulosLineas.HayValoresAtributo(
  AOrden, ANumValores: Integer): Boolean;
var
  Acceso: TAccesoSelectorAtributo;
  Campo: TField;
  Columna: TcxGridDBColumn;
  iNumAtributos: Integer;
  sNombre: string;
begin
  iNumAtributos := 0;
  Campo := FCds.FindField(FCampos.NumAtributos);
  if Campo <> nil then
    iNumAtributos := Campo.AsInteger;
  Acceso := AccesoSelectorAtributo(iNumAtributos, AOrden, ANumValores);
  Result := Acceso = asaAbrir;
  if AvisarAtributoSinValores(Acceso) then
  begin
    sNombre := '';
    Campo := FCds.FindField(FCampos.AttrNombre[AOrden]);
    if Campo <> nil then
      sNombre := Campo.AsString;
    Columna := ColumnaPorTag(AOrden);
    if (Trim(sNombre) = '') and (Columna <> nil) then
      sNombre := Columna.Caption;
    ShowMessage_fza(MensajeAtributoSinValores(
      FCds.FieldByName(FCampos.CodigoArt).AsString, sNombre));
  end;
end;

// Abre la paleta (listbox de swatches) con los AV validos del atributo AOrden
// del articulo de la linea y aplica el elegido. La usan tanto el click en el
// boton (ellipsis) como la apertura automatica al entrar en la celda vacia.
procedure TGridArticulosLineas.AbrirPaletaOrden(AOrden: Integer);
var
  Edit: TcxCustomEdit;
  Col: TcxGridDBColumn;
  i, ScrX, ScrY, WidHint: Integer;
  sArtPadre, sAvActual, sNombreAtb, sIdVa, sAvNuevo: string;
  Avs: TArray<TArticuloAtributoValor>;
  AvsStr: TArray<string>;
  Mapa: TDictionary<string, string>;
begin
  if (AOrden >= 1) and (AOrden <= 5) and
     FCds.Active and not FCds.IsEmpty then
  begin
    sArtPadre := FCds.FieldByName(FCampos.CodigoArt).AsString;
    sAvActual := FCds.FieldByName(FCampos.AttrValor[AOrden]).AsString;
    sNombreAtb := FCds.FieldByName(FCampos.AttrNombre[AOrden]).AsString;
    Avs := FLookup.ObtenerAvsEnSkus(sArtPadre, AOrden);
    if HayValoresAtributo(AOrden, Length(Avs)) then
    begin
      SetLength(AvsStr, Length(Avs));
      for i := 0 to High(Avs) do
        AvsStr[i] := Avs[i].Valor;
      sIdVa := '';
      Mapa := ObtenerMapaAtributosGlobal(FConn);
      if Mapa <> nil then
        Mapa.TryGetValue(UpperCase(Trim(sNombreAtb)), sIdVa);
      FAbriendoSelector := True;
      try
        Col := ColumnaPorTag(AOrden);
        if (Col <> nil) and (FView.Controller.FocusedColumn <> Col) then
          FView.Controller.FocusedColumn := Col;
        if not FView.Controller.EditingController.IsEditing then
        begin
          try
            FView.Controller.EditingController.ShowEdit;
          except
            on E: Exception do
            begin
              if Assigned(FRegistroLog) then
                FRegistroLog.RegistrarAviso(
                  'GridArticulos.AbrirPaletaOrden: ShowEdit ignorado: ' +
                  E.Message);
            end;
          end;
        end;
        ScrX := -1;
        ScrY := -1;
        WidHint := 120;
        Edit := nil;
        if FView.Controller.EditingController.IsEditing then
          Edit := FView.Controller.EditingController.Edit;
        if (Edit <> nil) and Edit.HasParent then
        begin
          try
            ScrX := Edit.ClientToScreen(Point(0, Edit.Height)).X;
            ScrY := Edit.ClientToScreen(Point(0, Edit.Height)).Y;
            WidHint := Edit.Width;
          except
            on E: EInvalidOperation do
            begin
              ScrX := -1;
              ScrY := -1;
              WidHint := 120;
            end;
          end;
        end;
        if SeleccionarAvConPaleta(
          FConn, sIdVa, AvsStr, sAvActual, sAvNuevo,
          ScrX, ScrY, WidHint, sArtPadre) then
        begin
          if FCds.State = dsBrowse then
            FCds.Edit;
          if FCds.State in [dsEdit, dsInsert] then
          begin
            FCds.FieldByName(FCampos.AttrValor[AOrden]).AsString :=
              sAvNuevo;
            AplicarSkuYAvisar;
            if not AvanzarSiguienteAtributo then
              MostrarEditorArticulo;
          end;
        end;
      finally
        FAbriendoSelector := False;
      end;
    end;
  end;
end;

function TGridArticulosLineas.AvanzarSiguienteAtributo: Boolean;
var
  i, n: Integer;
  Col: TcxGridDBColumn;
begin
  Result := False;
  if FCds.Active and not FCds.IsEmpty then
  begin
    n := FCds.FieldByName(FCampos.NumAtributos).AsInteger;
    for i := 1 to n do
    begin
      if Trim(FCds.FieldByName(FCampos.AttrValor[i]).AsString) = '' then
      begin
        Col := ColumnaPorTag(i);
        if Col <> nil then
        begin
          if not Col.Visible then
            Col.Visible := True;
          FView.Controller.FocusedColumn := Col;
          FOrdenPopupPend := i;
          FTimerPopup.Enabled := False;
          FTimerPopup.Enabled := True;
          Result := True;
        end;
        Break;
      end;
    end;
  end;
end;

end.
