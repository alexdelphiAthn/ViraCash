{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColumnasDocumento                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Creación, visibilidad y captions comunes de las columnas visuales de     }
{    talla y atributo usadas por los documentos de compra, incluida la carga  }
{    de nombres de atributo y la configuración compartida del gestor y el     }
{    pivote de tallas, el desmontaje y construcción del modo, su configuración}
{    base, las columnas host, el pivote por bandas, los atributos globales,  }
{    los hooks de ciclo de vida, la navegación, el modo y la foto activa.   }
{******************************************************************************}
unit inLibColumnasDocumento;

interface

uses
  System.Classes, Vcl.Forms, Data.DB, Uni, cxEdit,
  cxGridCustomTableView, cxGridDBTableView, inLibContextoSesionIntf,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibGridPivoteCompra,
  inLibGridPivoteVenta, inLibAnfitrionDatosIntf, inLibLogIntf,
  inLibUnidadesMedida;

type
  TConfigPivoteDocumentoCompra = record
    Conexion: TUniConnection;
    ContextoSesion: IContextoSesionAplicacion;
    RegistroLog: IRegistroLog;
    Usuario: string;
    Vista: TcxGridDBTableView;
    SourceMaster: TDataSource;
    SourceLineas: TDataSource;
    ConsultaLineas: TUniQuery;
    ColumnasTallas: TArray<TcxGridDBColumn>;
    ColColorPivot: TcxGridDBColumn;
    ColColorProveedorPivot: TcxGridDBColumn;
    PrefijoCabecera: string;
    PrefijoLinea: string;
    PrefijoCelda: string;
    NombreTablaDocumento: string;
    AplicarContextoPivote: Boolean;
    TieneCantidadRecibida: Boolean;
    CampoColorTexto: string;
  end;

  TColumnasHostDocumentoCompra = record
    ColLinea: TcxGridDBColumn;
    ColCantidad: TcxGridDBColumn;
    ColTipoCantidad: TcxGridDBColumn;
    ColPrecioCompra: TcxGridDBColumn;
    ColAlmacen: TcxGridDBColumn;
    // Solo en el modo bandas (mcsTallasHorPed): total de unidades.
    ColTotalUds: TcxGridDBColumn;
  end;

  TConjuntoModosColumnasSku = set of TModoColumnasSku;

  TAccionDocumento = procedure of object;

procedure CrearColumnasTallasDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  AAncho: Integer; var AColumnas: array of TcxGridDBColumn);
procedure CrearColumnasAtributosDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  var AColumnas: array of TcxGridDBColumn;
  AOnGetDataText: TcxGridGetDataTextEvent = nil);
procedure DesmontarModoEntradaDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid;
  const ARegistroLog: IRegistroLog = nil);
procedure PrepararReconstruccionModoDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid;
  var AColumnasTallas: array of TcxGridDBColumn;
  var AColumnasAtributos: array of TcxGridDBColumn;
  var AColColorPivot: TcxGridDBColumn);
function ConstruirModoEntradaDocumento(
  const AModoEntrada: IModoEntradaGrid;
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent;
  AModoSeleccionado: TModoColumnasSku;
  const AModosDegradables: TConjuntoModosColumnasSku;
  const AContextoLog: string;
  const ARegistroLog: IRegistroLog = nil): Boolean;
procedure ConfigurarColumnaBotonDocumento(
  AColumna: TcxGridDBColumn;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent = nil);
function ConfigurarColumnaBusquedaDocumento(
  AVista: TcxGridDBTableView; const ACampo: string;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent = nil): TcxGridDBColumn;
function CrearColumnaColorPivoteDocumento(
  AVista: TcxGridDBTableView; const ANombre: string;
  AAncho: Integer): TcxGridDBColumn;
procedure LiberarModoYGestoresDocumento(
  var AModoEntrada: IModoEntradaGrid;
  var APivote: TGridPivoteCompra;
  var AGestorTallas: TGestorGridTallas;
  const ARegistroLog: IRegistroLog = nil);
procedure ActualizarModoEntradaAlNavegarDocumento(
  AField: TField; ALineas: TDataSet; AMaster: TDataSource;
  AConstruido: Boolean; AModo: TModoColumnasSku;
  AReconstruirTallas: Boolean;
  AConstruir, ADesempaquetar: TAccionDocumento);
procedure ReconstruirModoEntradaEnAltaDocumento(
  AField: TField; ALineas: TDataSet; AMaster: TDataSource;
  AConstruido: Boolean; var AModo: TModoColumnasSku;
  var AAltaReconstruida: Boolean; AConstruir: TAccionDocumento);
procedure ActualizarFocoLineaDocumento(
  AGestorTallas: TGestorGridTallas;
  APivote: TGridPivoteCompra; AMostrarAtributos: Boolean;
  ACargarAtributos: TAccionDocumento);
procedure ConfigurarEdicionExcelLineasDocumento(
  AVista: TcxGridDBTableView);
procedure EntrarGridLineasDocumento(
  AFormulario: TForm; AConstruido, AReconstruir: Boolean;
  var AModoEntrada: IModoEntradaGrid;
  AAsegurarLinea, AConstruir: TAccionDocumento;
  AMostrarEditorEntrada: Boolean = True);
// Graba la línea en edición de AVista antes de cambiar de modo: el
// desmontaje cancela lo pendiente. Una línea nueva sin artículo se
// descarta; si la validación falla se propaga la excepción y el modo
// no cambia.
procedure ConfirmarLineaDocumento(AVista: TcxGridDBTableView);
// Botón «Añadir línea»: deja una línea en blanco con el editor de entrada
// abierto. La que ya esté en blanco en inserción se reutiliza: otro Append
// la postearía contra la guarda de línea sin artículo. En tallas
// horizontales el alta la abre el pivote sobre su vista.
procedure AnadirLineaDocumento(ALineas: TDataSet;
  const AModoEntrada: IModoEntradaGrid);
// Botón «Borrar línea»: pide confirmación con APregunta y borra la línea
// actual. En tallas horizontales la fila es un grupo con una línea real
// por talla y se borran todas a través del pivote.
procedure BorrarLineaDocumento(ALineas: TDataSet;
  const AModoEntrada: IModoEntradaGrid; const APregunta: string);
function CambiarModoEntradaDocumento(
  var AModo: TModoColumnasSku; ANuevoModo: TModoColumnasSku;
  AVista: TcxGridDBTableView; AConstruir: TAccionDocumento): Boolean;
function ProcesarTeclaCambioModoDocumento(
  var ATecla: Word; AShift: TShiftState; AHabilitado: Boolean;
  var AModo: TModoColumnasSku;
  const ACiclo: array of TModoColumnasSku;
  AVista: TcxGridDBTableView; AConstruir: TAccionDocumento): Boolean;
procedure PersistirPreferenciaPivoteDocumento(
  ADataSet: TDataSet; const ACampo: string; AActivo: Boolean);
procedure ResolverArtSkuActivoDocumento(
  AVista: TcxGridDBTableView; out ACodArt, ACodSku: string);
function DataSourcesParaFotoDocumento(
  ACabecera: TDataSource; AVista: TcxGridDBTableView):
  TArray<TDataSource>;
procedure ConfigurarTablaPrincipalDocumento(
  const AAnfitrion: IAnfitrionDatosDocumento; ACabecera: TDataSource;
  AVistaLineas: TcxGridDBTableView; ASourceLineas: TDataSource;
  const AConsultasDetalle: array of TUniQuery;
  var AClavePrincipal: string; const AClave: string);
function CrearConfigColumnasSkuDocumento(
  const AServicios: TServiciosColumnasSku;
  const AContextoSesion: IContextoSesionAplicacion;
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  AModo: TModoColumnasSku; const AAlmacenStock,
  APrefijoLinea: string): TConfigColumnasSku;
function CrearColumnaHostDocumento(
  AVista: TcxGridDBTableView; const ACaption, ACampo: string;
  AAncho: Integer; AEditable: Boolean): TcxGridDBColumn;
procedure AjustarAnchosTallasPedidoCompra(
  AVista: TcxGridDBTableView; AMaxTallas: Integer);
function CrearColumnaDescuentoCompra(AVista: TcxGridDBTableView;
  const ASufijo: string): TcxGridDBColumn;

function CrearColumnasHostDocumentoCompra(
  AVista: TcxGridDBTableView; AModo: TModoColumnasSku;
  const APrefijoLinea: string): TColumnasHostDocumentoCompra;
procedure RotularColumnasHostDocumentoCompra(
  AVista: TcxGridDBTableView; AModo: TModoColumnasSku;
  const APrefijoLinea: string);
// FZ-ISSUE-211: cantidad, tallas y total de unidades con los decimales de
// la unidad de cada fila. En el modo bandas (sin ColCantidad) la columna
// de unidad queda oculta: el Tipo ya dice «Pedido - m».
procedure VincularCantidadesHostDocumentoCompra(
  const AColumnas: TColumnasHostDocumentoCompra;
  const ATallas: array of TcxGridDBColumn;
  AUnidades: TUnidadesMedida);
// La celda Almacén de la línea solo admite almacenes de la lista (los de
// la empresa del documento, los mismos del combo de la cabecera).
procedure ConvertirColumnaAlmacenEnLista(AColumna: TcxGridDBColumn;
  AAlmacenes: TDataSource);
function CrearConfigPivoteBandasDocumentoCompra(
  AConexion: TUniConnection; const AUsuario: string;
  ASourceMaster, ASourceLineas: TDataSource;
  const APrefijoCabecera, APrefijoLinea,
  ACampoPrecioBase: string;
  AMaxColumnas: Integer): TGridPivoteVentaConfig;
procedure EstablecerVisibilidadColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn; AVisible: Boolean);
function CaptionModoLineasDocumento(const ACaptionBase,
  ACaptionSinConstruir: string; AConstruido: Boolean;
  AModo: TModoColumnasSku; AUsaBandasSeparadas: Boolean): string;
procedure RestablecerCaptionsAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn);
procedure AplicarNombresAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn;
  const ANombres: array of string);
procedure AplicarNombresAtributosGlobalesDocumento(
  AVista: TcxGridDBTableView; const ANombres: array of string);
procedure CargarCaptionsAtributosDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  const AColumnas: array of TcxGridDBColumn);
// FZ-ISSUE-436: la columna del eje de fila del pivote («Color») toma el
// nombre del primer atributo del artículo de la línea activa (Aroma...).
// Solo consulta si la columna se ve y el artículo cambia (AArticuloLeido
// lo recuerda quien llama).
procedure ActualizarCaptionEjeFilaDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  AColumna: TcxGridDBColumn; var AArticuloLeido: string);
function CopiarColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn):
  TArray<TcxGridDBColumn>;
function CrearConfigTallasDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra): TGridTallasConfig;
function CrearConfigPivoteDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra;
  AGestor: TGestorGridTallas): TGridPivoteCompraConfig;
procedure ConfigurarEventosTallasDocumento(
  const AColumnas: array of TcxGridDBColumn;
  AOnEditValueChanged: TNotifyEvent;
  AOnValidate: TcxEditValidateEvent);

implementation

uses
  System.SysUtils, System.StrUtils, System.Math, System.UITypes,
  Winapi.Windows, Vcl.Graphics, Vcl.Dialogs, inLibMensajesVcl,
  cxDataStorage, cxButtonEdit, cxDropDownEdit, cxLookupEdit,
  cxDBLookupComboBox, cxLookupDBGrid,
  cxGraphics, dxCoreGraphics, inLibAtributosPaleta,
  cxCurrencyEdit, inLibFotos, inLibMsgArticulos,
  inLibMsgComun, inLibMsgCompras, inLibMsgVentas, inLibMsgTrazabilidad,
  inLibFormatoMonetario, inLibGridCantidad, inLibGridPivoteVentaVista;

function MedirTextoAnchoPedidoCompra(AColumna: TcxGridDBColumn;
  AEnCabecera: Boolean; const ATexto: string): Integer;
var
  Parametros: TcxViewParams;
  Linea: string;
begin
  if AEnCabecera then
    AColumna.Styles.GetHeaderParams(Parametros)
  else
    AColumna.Styles.GetContentParams(nil, Parametros);
  Result := 0;
  for Linea in ATexto.Split([#13, #10]) do
    Result := Max(Result, cxTextWidth(Parametros.Font, Linea));
end;

procedure AjustarAnchoColumnaTallasPedidoCompra(
  AVista: TcxGridDBTableView; AColumna: TcxGridDBColumn;
  AMinimo, AMaximo, AMargen, APpi: Integer);
var
  Ancho, AnchoTexto, Registro: Integer;
begin
  Ancho := MulDiv(AMinimo, APpi, USER_DEFAULT_SCREEN_DPI);
  AnchoTexto := MedirTextoAnchoPedidoCompra(AColumna, True,
    AColumna.Caption) + MulDiv(24, APpi, USER_DEFAULT_SCREEN_DPI);
  Ancho := Max(Ancho, AnchoTexto);
  for Registro := 0 to AVista.DataController.RecordCount - 1 do
  begin
    AnchoTexto := MedirTextoAnchoPedidoCompra(AColumna, False,
      AVista.DataController.DisplayTexts[Registro, AColumna.Index]) +
      MulDiv(AMargen, APpi, USER_DEFAULT_SCREEN_DPI);
    Ancho := Max(Ancho, AnchoTexto);
  end;
  Ancho := Min(Ancho,
    MulDiv(AMaximo, APpi, USER_DEFAULT_SCREEN_DPI));
  if AColumna.BestFitMaxWidth > 0 then
    Ancho := Min(Ancho, AColumna.BestFitMaxWidth);
  // Solo crece al presentar: no reinicia anchos/perfiles del usuario.
  // MinWidth queda nativo: cambiarlo antes de ChangeScale puede hacer
  // que DevExpress escale Width dos veces al subir de DPI.
  if AColumna.Width < Ancho then
    AColumna.Width := Ancho;
end;

procedure AjustarAnchosTallasPedidoCompra(
  AVista: TcxGridDBTableView; AMaxTallas: Integer);
var
  Columna: TcxGridDBColumn;
  Indice, Ppi, Minimo, Maximo, Margen: Integer;
begin
  if Assigned(AVista) then
  begin
    Ppi := USER_DEFAULT_SCREEN_DPI;
    if Assigned(AVista.Site) then
      Ppi := AVista.Site.CurrentPPI;
    AVista.BeginUpdate;
    try
      for Indice := 0 to AVista.ColumnCount - 1 do
      begin
        Columna := AVista.Columns[Indice];
        Minimo := 0;
        Maximo := 320;
        Margen := 24;
        if (Columna.Tag >= 1) and (Columna.Tag <= AMaxTallas) and
           (Columna.DataBinding.FieldName = '') then
        begin
          Minimo := 60;
          Maximo := 120;
        end
        else if (Columna.Tag >= -5) and (Columna.Tag <= -1) then
        begin
          Minimo := 125;
          Margen := ANCHO_SWATCH_PX;
        end
        else if SameText(Columna.DataBinding.FieldName,
          'CODIGO_ART_PEDCLIN') then
          Minimo := 160;
        if (Minimo > 0) and
           TcxCustomGridTableItemAccess.CanHorzSize(Columna) then
          AjustarAnchoColumnaTallasPedidoCompra(
            AVista, Columna, Minimo, Maximo, Margen, Ppi);
      end;
    finally
      AVista.EndUpdate;
    end;
  end;
end;

procedure CrearColumnasTallasDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  AAncho: Integer; var AColumnas: array of TcxGridDBColumn);
var
  iIndice: Integer;
  oColumna: TcxGridDBColumn;
  oPropiedades: TcxCurrencyEditProperties;
begin
  if Assigned(AVista) then
  begin
    for iIndice := Low(AColumnas) to High(AColumnas) do
    begin
      oColumna := AVista.CreateColumn;
      oColumna.Name := APrefijoNombre + Format('%.2d', [iIndice + 1]);
      oColumna.Caption := '';
      oColumna.Width := AAncho;
      oColumna.Tag := iIndice + 1;
      oColumna.Visible := False;
      oColumna.DataBinding.ValueTypeClass := TcxFloatValueType;
      oColumna.PropertiesClass := TcxCurrencyEditProperties;
      // La cantidad va a la derecha: el nombre de la talla, encima.
      oColumna.HeaderAlignmentHorz := taRightJustify;
      oPropiedades := TcxCurrencyEditProperties(oColumna.Properties);
      // Sin campo detrás el editor alinearía a la izquierda.
      oPropiedades.Alignment.Horz := taRightJustify;
      oPropiedades.DisplayFormat := '#,##0';
      AColumnas[iIndice] := oColumna;
    end;
  end;
end;

procedure CrearColumnasAtributosDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  var AColumnas: array of TcxGridDBColumn;
  AOnGetDataText: TcxGridGetDataTextEvent);
var
  iIndice: Integer;
  oColumna: TcxGridDBColumn;
begin
  if Assigned(AVista) then
  begin
    for iIndice := Low(AColumnas) to High(AColumnas) do
    begin
      oColumna := AVista.CreateColumn;
      oColumna.Name := APrefijoNombre + Format('%.2d', [iIndice + 1]);
      oColumna.Caption := '';
      oColumna.Width := 90;
      oColumna.Tag := -(iIndice + 1);
      oColumna.Visible := False;
      oColumna.Options.Editing := False;
      if Assigned(AOnGetDataText) then
        oColumna.OnGetDataText := AOnGetDataText;
      AColumnas[iIndice] := oColumna;
    end;
  end;
end;

procedure DesmontarModoEntradaDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid;
  const ARegistroLog: IRegistroLog);
begin
  if Assigned(AVista) then
  begin
    if AVista.Controller.EditingController.IsEditing then
      try
        AVista.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          // Ruido del editor inplace durante el desmontaje.
          if Assigned(ARegistroLog) then
            ARegistroLog.RegistrarAviso(
              'DesmontarModoEntradaDocumento: HideEdit ignorado: ' +
              E.Message);
      end;
  end;
  if Assigned(ADataSet) and (ADataSet.State in dsEditModes) then
    ADataSet.Cancel;
  if Assigned(AModoEntrada) then
    AModoEntrada.Desmontar;
  if Assigned(AVista) then
  begin
    AVista.OnInitEdit := nil;
    AVista.OnEditKeyDown := nil;
    // FZ-ISSUE-791: el modo SKU también engancha estas dos (FZ-ISSUE-350);
    // sin quitarlas, Enter en el modo siguiente llamaba al modo liberado.
    AVista.OnEditKeyPress := nil;
    AVista.OnKeyPress := nil;
    AVista.OnEditing := nil;
    AVista.OnFocusedRecordChanged := nil;
    AVista.OnFocusedItemChanged := nil;
    AVista.OnCustomDrawCell := nil;
    AVista.ClearItems;
  end;
  AModoEntrada := nil;
end;

procedure PrepararReconstruccionModoDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid;
  var AColumnasTallas: array of TcxGridDBColumn;
  var AColumnasAtributos: array of TcxGridDBColumn;
  var AColColorPivot: TcxGridDBColumn);
var
  iIndice: Integer;
begin
  DesmontarModoEntradaDocumento(AVista, ADataSet, AModoEntrada);
  for iIndice := Low(AColumnasTallas) to High(AColumnasTallas) do
    AColumnasTallas[iIndice] := nil;
  for iIndice := Low(AColumnasAtributos) to
    High(AColumnasAtributos) do
    AColumnasAtributos[iIndice] := nil;
  AColColorPivot := nil;
end;

function ConstruirModoEntradaDocumento(
  const AModoEntrada: IModoEntradaGrid;
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent;
  AModoSeleccionado: TModoColumnasSku;
  const AModosDegradables: TConjuntoModosColumnasSku;
  const AContextoLog: string;
  const ARegistroLog: IRegistroLog): Boolean;
begin
  Result := True;
  try
    AModoEntrada.Construir(
      AOnResuelto, AOnEntrarEdicion, AOnSalirEdicion);
  except
    on E: Exception do
    begin
      if AModoSeleccionado in AModosDegradables then
      begin
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarError(
            AContextoLog +
            ': fallo construyendo tallas horizontal, ' +
            'se degrada a SKU: ' + E.Message);
        Result := False;
      end
      else
        raise;
    end;
  end;
end;

procedure ConfigurarColumnaBotonDocumento(
  AColumna: TcxGridDBColumn;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent);
var
  oBoton: TcxEditButton;
  oPropiedades: TcxButtonEditProperties;
begin
  if Assigned(AColumna) then
  begin
    AColumna.PropertiesClass := TcxButtonEditProperties;
    AColumna.Options.ShowEditButtons := isebAlways;
    oPropiedades := TcxButtonEditProperties(AColumna.Properties);
    oPropiedades.Buttons.Clear;
    oBoton := oPropiedades.Buttons.Add;
    oBoton.Default := True;
    oBoton.Kind := bkEllipsis;
    oPropiedades.OnButtonClick := AOnButtonClick;
    oPropiedades.OnValidate := AOnValidate;
  end;
end;

function ConfigurarColumnaBusquedaDocumento(
  AVista: TcxGridDBTableView; const ACampo: string;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent): TcxGridDBColumn;
begin
  Result := nil;
  if Assigned(AVista) then
    Result := AVista.GetColumnByFieldName(ACampo);
  ConfigurarColumnaBotonDocumento(
    Result, AOnButtonClick, AOnValidate);
end;

function CrearColumnaColorPivoteDocumento(
  AVista: TcxGridDBTableView; const ANombre: string;
  AAncho: Integer): TcxGridDBColumn;
begin
  Result := nil;
  if Assigned(AVista) then
  begin
    Result := AVista.CreateColumn;
    Result.Name := ANombre;
    Result.Caption := SCaptionColColor;
    Result.Width := AAncho;
    Result.Visible := False;
    Result.Options.Editing := True;
  end;
end;

procedure LiberarModoYGestoresDocumento(
  var AModoEntrada: IModoEntradaGrid;
  var APivote: TGridPivoteCompra;
  var AGestorTallas: TGestorGridTallas;
  const ARegistroLog: IRegistroLog);
begin
  if Assigned(AModoEntrada) then
  begin
    try
      AModoEntrada.Desmontar;
    except
      // El cierre no debe quedar bloqueado por un desmontaje parcial.
      on E: Exception do
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarAviso(
            'LiberarModoYGestoresDocumento: Desmontar fallo: ' +
            E.Message);
    end;
    AModoEntrada := nil;
  end;
  FreeAndNil(APivote);
  FreeAndNil(AGestorTallas);
end;

procedure ActualizarModoEntradaAlNavegarDocumento(
  AField: TField; ALineas: TDataSet; AMaster: TDataSource;
  AConstruido: Boolean; AModo: TModoColumnasSku;
  AReconstruirTallas: Boolean;
  AConstruir, ADesempaquetar: TAccionDocumento);
var
  bMasterEditable: Boolean;
begin
  bMasterEditable := Assigned(AMaster) and
    (AMaster.State in dsEditModes);
  if (AField = nil) and Assigned(ALineas) and ALineas.Active and
     (not bMasterEditable) then
  begin
    if (not AConstruido) or
       (AReconstruirTallas and (AModo = mcsTallasHorPed)) then
    begin
      if Assigned(AConstruir) then
        AConstruir;
    end
    else if (AModo = mcsAuto) and Assigned(ADesempaquetar) then
      ADesempaquetar;
  end;
end;

// Alta de cabecera en tallas horizontal: la vista pinta una copia en
// memoria de las lineas y seguia mostrando las del documento anterior
// hasta grabar (FZ-ISSUE-035, como FZ-ISSUE-032 en pedidos). Reconstruye
// una sola vez por alta: el detalle ya llega vacio y la reconstruccion
// no escribe nada. Al salir del alta el indicador se rearma.
// Un alta se teclea en Desglose (peticion del usuario, FZ-ISSUE-238): las
// bandas Pedido / A recibir / Pendiente son para consultar y recibir. El
// modo se queda en Desglose hasta que el usuario lo cambie con F1.
procedure ReconstruirModoEntradaEnAltaDocumento(
  AField: TField; ALineas: TDataSet; AMaster: TDataSource;
  AConstruido: Boolean; var AModo: TModoColumnasSku;
  var AAltaReconstruida: Boolean; AConstruir: TAccionDocumento);
begin
  if not (Assigned(AMaster) and (AMaster.State = dsInsert)) then
    AAltaReconstruida := False
  else if (AField = nil) and (not AAltaReconstruida) and AConstruido and
     (AModo = mcsTallasHorPed) and Assigned(ALineas) and
     ALineas.Active and Assigned(AConstruir) then
  begin
    // Antes de construir: la reconstruccion no debe volver a entrar.
    AAltaReconstruida := True;
    AModo := mcsAuto;
    AConstruir;
  end;
end;

procedure ActualizarFocoLineaDocumento(
  AGestorTallas: TGestorGridTallas;
  APivote: TGridPivoteCompra; AMostrarAtributos: Boolean;
  ACargarAtributos: TAccionDocumento);
begin
  if Assigned(AGestorTallas) and Assigned(APivote) and
     APivote.Activo then
    AGestorTallas.ActualizarCaptionsLineaActiva;
  if AMostrarAtributos and Assigned(ACargarAtributos) then
    ACargarAtributos;
end;

procedure ConfigurarEdicionExcelLineasDocumento(
  AVista: TcxGridDBTableView);
begin
  if AVista <> nil then
  begin
    AVista.OptionsBehavior.AlwaysShowEditor := True;
    AVista.OptionsBehavior.ImmediateEditor := True;
    AVista.OptionsBehavior.IncSearch := False;
    AVista.OptionsBehavior.IncSearchItem := nil;
    AVista.OptionsBehavior.FocusCellOnCycle := True;
    AVista.OptionsBehavior.FocusCellOnTab := True;
    AVista.OptionsBehavior.GoToNextCellOnEnter := True;
    AVista.OptionsSelection.CellSelect := True;
  end;
end;

procedure EntrarGridLineasDocumento(
  AFormulario: TForm; AConstruido, AReconstruir: Boolean;
  var AModoEntrada: IModoEntradaGrid;
  AAsegurarLinea, AConstruir: TAccionDocumento;
  AMostrarEditorEntrada: Boolean);
begin
  inLibGridTallasInline.ActivarEnterComoTab(
    AFormulario, False);
  if Assigned(AAsegurarLinea) then
    AAsegurarLinea;
  if (not AConstruido) or AReconstruir then
  begin
    if Assigned(AConstruir) then
      AConstruir;
    if Assigned(AAsegurarLinea) then
      AAsegurarLinea;
  end;
  if AMostrarEditorEntrada and Assigned(AModoEntrada) then
    AModoEntrada.MostrarEditor;
end;

// Línea sin identificar el artículo: ni código de artículo, ni SKU, ni
// código de barras. Sin esos campos decide si se ha tocado.
function LineaDocumentoSinArticulo(ADataSet: TDataSet): Boolean;
var
  oCampo: TField;
  bHayCampos: Boolean;
begin
  Result := True;
  bHayCampos := False;
  for oCampo in ADataSet.Fields do
  begin
    if StartsText('CODIGO_ART_', oCampo.FieldName) or
       StartsText('CODIGO_UNIDAD_', oCampo.FieldName) or
       StartsText('CODBAR_', oCampo.FieldName) then
    begin
      bHayCampos := True;
      if Trim(oCampo.AsString) <> '' then
        Result := False;
    end;
  end;
  if not bHayCampos then
    Result := not ADataSet.Modified;
end;

procedure ConfirmarLineaDocumento(AVista: TcxGridDBTableView);
var
  oDataSet: TDataSet;
begin
  if Assigned(AVista) then
  begin
    // Vuelca al campo lo tecleado en el editor inplace.
    if AVista.Controller.EditingController.IsEditing then
      AVista.Controller.EditingController.HideEdit(True);
    oDataSet := AVista.DataController.DataSet;
    if Assigned(oDataSet) and (oDataSet.State in dsEditModes) then
    begin
      if (oDataSet.State = dsInsert) and
         LineaDocumentoSinArticulo(oDataSet) then
        oDataSet.Cancel
      else if oDataSet.Modified then
        oDataSet.Post
      else
        oDataSet.Cancel;
    end;
  end;
end;

procedure AnadirLineaDocumento(ALineas: TDataSet;
  const AModoEntrada: IModoEntradaGrid);
var
  oPivote: IPivoteVentaAnadirLinea;
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    if Supports(AModoEntrada, IPivoteVentaAnadirLinea, oPivote) then
      oPivote.AnadirLineaNueva
    else
    begin
      if (ALineas.State <> dsInsert) or
         (not LineaDocumentoSinArticulo(ALineas)) then
        ALineas.Append;
      if Assigned(AModoEntrada) then
        AModoEntrada.MostrarEditor;
    end;
  end;
end;

procedure BorrarLineaDocumento(ALineas: TDataSet;
  const AModoEntrada: IModoEntradaGrid; const APregunta: string);
var
  oPivote: IPivoteVentaBorrarGrupo;
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    if Supports(AModoEntrada, IPivoteVentaBorrarGrupo, oPivote) then
    begin
      if MessageDlg_fza(SPreguntaEliminarLineaTallasVenta,
           mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        oPivote.BorrarGrupoActual;
    end
    else if (ALineas.State = dsInsert) and
            LineaDocumentoSinArticulo(ALineas) then
      // Línea en blanco sin grabar: no hay nada que confirmar.
      ALineas.Cancel
    else if (not ALineas.IsEmpty) and
            (MessageDlg_fza(APregunta, mtConfirmation, [mbYes, mbNo],
               0) = mrYes) then
      ALineas.Delete;
  end;
end;

function CambiarModoEntradaDocumento(
  var AModo: TModoColumnasSku; ANuevoModo: TModoColumnasSku;
  AVista: TcxGridDBTableView; AConstruir: TAccionDocumento): Boolean;
begin
  Result := AModo <> ANuevoModo;
  if Result then
  begin
    ConfirmarLineaDocumento(AVista);
    AModo := ANuevoModo;
    if Assigned(AConstruir) then
      AConstruir;
  end;
end;

function ProcesarTeclaCambioModoDocumento(
  var ATecla: Word; AShift: TShiftState; AHabilitado: Boolean;
  var AModo: TModoColumnasSku;
  const ACiclo: array of TModoColumnasSku;
  AVista: TcxGridDBTableView; AConstruir: TAccionDocumento): Boolean;
var
  iIndice: Integer;
  ModoNuevo: TModoColumnasSku;
begin
  Result := (ATecla = VK_F1) and (AShift = []) and AHabilitado and
    (Length(ACiclo) > 0);
  if Result then
  begin
    ModoNuevo := ACiclo[0];
    for iIndice := Low(ACiclo) to High(ACiclo) do
    begin
      if AModo = ACiclo[iIndice] then
      begin
        if iIndice < High(ACiclo) then
          ModoNuevo := ACiclo[iIndice + 1];
      end;
    end;
    ATecla := 0;
    CambiarModoEntradaDocumento(AModo, ModoNuevo, AVista, AConstruir);
  end;
end;

procedure PersistirPreferenciaPivoteDocumento(
  ADataSet: TDataSet; const ACampo: string; AActivo: Boolean);
var
  oCampo: TField;
  sValor: string;
begin
  oCampo := nil;
  if Assigned(ADataSet) then
  begin
    if ADataSet.Active and (not ADataSet.IsEmpty) then
      oCampo := ADataSet.FindField(ACampo);
  end;
  if Assigned(oCampo) then
  begin
    if not (ADataSet.State in dsEditModes) then
      ADataSet.Edit;
    sValor := 'N';
    if AActivo then
      sValor := 'S';
    oCampo.AsString := sValor;
    ADataSet.Post;
  end;
end;

// DataSource de las líneas reales de la rejilla. En «Tallas horiz.» la
// rejilla muestra una copia en memoria, pero el pivote deja las líneas
// reales en la línea enfocada: la foto (miniatura y Ctrl+F) se engancha
// a ellas y no se pierde al cambiar de modo con F1.
function FuenteLineasFotoDocumento(
  AVista: TcxGridDBTableView): TDataSource;
begin
  Result := nil;
  if Assigned(AVista) then
    Result := AVista.DataController.DataSource;
  if (Result is TDataSourceVistaPivote) and
     Assigned(TDataSourceVistaPivote(Result).Original) then
    Result := TDataSourceVistaPivote(Result).Original;
end;

procedure ResolverArtSkuActivoDocumento(
  AVista: TcxGridDBTableView; out ACodArt, ACodSku: string);
var
  oDataSource: TDataSource;
begin
  ACodArt := '';
  ACodSku := '';
  oDataSource := FuenteLineasFotoDocumento(AVista);
  if Assigned(oDataSource) then
    inLibFotos.LeerArtSkuDeDataSet(
      oDataSource.DataSet, ACodArt, ACodSku);
end;

function DataSourcesParaFotoDocumento(
  ACabecera: TDataSource; AVista: TcxGridDBTableView):
  TArray<TDataSource>;
var
  oDetalle: TDataSource;
begin
  oDetalle := FuenteLineasFotoDocumento(AVista);
  if Assigned(oDetalle) then
    Result := [ACabecera, oDetalle]
  else
    Result := [ACabecera];
end;

procedure ConfigurarTablaPrincipalDocumento(
  const AAnfitrion: IAnfitrionDatosDocumento; ACabecera: TDataSource;
  AVistaLineas: TcxGridDBTableView; ASourceLineas: TDataSource;
  const AConsultasDetalle: array of TUniQuery;
  var AClavePrincipal: string; const AClave: string);
var
  iIndice: Integer;
begin
  if Assigned(AAnfitrion) and Assigned(ACabecera) then
  begin
    ACabecera.DataSet := AAnfitrion.ObtenerTablaPrincipal;
    AAnfitrion.AsignarMaestroCabecera(ACabecera);
  end;
  if Assigned(AVistaLineas) then
    AVistaLineas.DataController.DataSource := ASourceLineas;
  for iIndice := Low(AConsultasDetalle) to
    High(AConsultasDetalle) do
  begin
    if Assigned(AConsultasDetalle[iIndice]) then
      AConsultasDetalle[iIndice].MasterSource := ACabecera;
  end;
  if AClave <> '' then
    AClavePrincipal := AClave;
end;

function CrearConfigColumnasSkuDocumento(
  const AServicios: TServiciosColumnasSku;
  const AContextoSesion: IContextoSesionAplicacion;
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  AModo: TModoColumnasSku; const AAlmacenStock,
  APrefijoLinea: string): TConfigColumnasSku;
var
  iIndice: Integer;
begin
  Result := Default(TConfigColumnasSku);
  Result.Servicios := AServicios;
  Result.ContextoSesion := AContextoSesion;
  Result.View := AVista;
  Result.Cds := ADataSet;
  Result.Modo := AModo;
  Result.AlmacenStock := AAlmacenStock;
  Result.Distribuido := False;
  Result.Campos.CodigoArt := 'CODIGO_ART_' + APrefijoLinea;
  Result.Campos.CodigoUnidad := 'CODIGO_UNIDAD_' + APrefijoLinea;
  Result.Campos.Descripcion :=
    'DESCRIPCION_ARTICULO_' + APrefijoLinea;
  Result.Campos.Cantidad := 'CANTIDAD_' + APrefijoLinea;
  Result.Campos.Almacen := 'CODIGO_ALMACEN_' + APrefijoLinea;
  Result.Campos.NumAtributos :=
    'NUM_ATRIBUTOS_' + APrefijoLinea;
  for iIndice := 1 to 5 do
  begin
    Result.Campos.AttrValor[iIndice] := 'ATTR' +
      IntToStr(iIndice) + '_VALOR_' + APrefijoLinea;
    Result.Campos.AttrNombre[iIndice] := 'ATTR' +
      IntToStr(iIndice) + '_NOMBRE_' + APrefijoLinea;
  end;
end;

function CrearColumnaHostDocumento(
  AVista: TcxGridDBTableView; const ACaption, ACampo: string;
  AAncho: Integer; AEditable: Boolean): TcxGridDBColumn;
begin
  Result := nil;
  if Assigned(AVista) then
  begin
    Result := AVista.CreateColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
end;

function CrearColumnaDescuentoCompra(AVista: TcxGridDBTableView;
  const ASufijo: string): TcxGridDBColumn;
begin
  Result := CrearColumnaHostDocumento(AVista,
    SCaptionDescuentoLineaCompra, 'PORCENTAJE_DTO_' + ASufijo, 75, True);
  Result.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(Result.Properties).MinValue := 0;
  TcxCurrencyEditProperties(Result.Properties).MaxValue := 100;
  TcxCurrencyEditProperties(Result.Properties).DisplayFormat := '0.00 "%"';
end;

function CrearColumnasHostDocumentoCompra(
  AVista: TcxGridDBTableView; AModo: TModoColumnasSku;
  const APrefijoLinea: string): TColumnasHostDocumentoCompra;
begin
  Result := Default(TColumnasHostDocumentoCompra);
  Result.ColLinea := CrearColumnaHostDocumento(
    AVista, SCaptionColumnaPedidoLinea,
    'LINEA_' + APrefijoLinea, 60, False);
  CrearColumnaHostDocumento(AVista, SCaptionColumnaPedidoModeloProveedor,
    'REF_PRV_' + APrefijoLinea, 130, True);
  CrearColumnaHostDocumento(AVista, SCaptionColumnaPedidoDescripcion,
    'DESCRIPCION_ARTICULO_' + APrefijoLinea, 260, False);
  if AModo <> mcsTallasHorPed then
    Result.ColCantidad := CrearColumnaHostDocumento(
      AVista, SCaptionColCantidad,
      'CANTIDAD_' + APrefijoLinea, 80, True);
  // FZ-ISSUE-211: tambien en el modo bandas, para formatear las
  // cantidades con los decimales de la unidad de cada fila.
  Result.ColTipoCantidad := CrearColumnaHostDocumento(
    AVista, '', 'TIPO_CANTIDAD_ARTICULO_' + APrefijoLinea,
    90, False);
  Result.ColPrecioCompra := CrearColumnaHostDocumento(
    AVista, SCaptionColumnaPedidoPrecioCompra,
    'PRECIO_COMPRA_SIVA_ARTICULO_' + APrefijoLinea, 130, True);
  FormatearColumnaMonetaria(Result.ColPrecioCompra);
  if APrefijoLinea = 'ALBCLIN' then
    CrearColumnaDescuentoCompra(AVista, APrefijoLinea);
  CrearColumnaHostDocumento(AVista, SCaptionColumnaPedidoPorcentajeIva,
    'PORCENTAJE_IVA_' + APrefijoLinea, 70, True);
  if AModo = mcsTallasHorPed then
    Result.ColTotalUds := CrearColumnaHostDocumento(AVista,
      SCaptionColumnaCompraTotalUnidades,
      'TOTAL_' + APrefijoLinea, 100, False)
  else
    FormatearColumnaMonetaria(
      CrearColumnaHostDocumento(AVista, SCaptionColumnaPedidoTotal,
        'TOTAL_' + APrefijoLinea, 100, False));
  Result.ColAlmacen := CrearColumnaHostDocumento(AVista,
    SCaptionColumnaPedidoAlmacen,
    'CODIGO_ALMACEN_' + APrefijoLinea, 90, True);
  if Assigned(Result.ColLinea) then
    Result.ColLinea.Index := 0;
end;

procedure RotularColumnasHostDocumentoCompra(
  AVista: TcxGridDBTableView; AModo: TModoColumnasSku;
  const APrefijoLinea: string);
  procedure Rotular(const ACampo, ATexto: string);
  var
    oColumna: TcxGridDBColumn;
  begin
    if Assigned(AVista) then
    begin
      oColumna := AVista.GetColumnByFieldName(ACampo + APrefijoLinea);
      if Assigned(oColumna) then
        oColumna.Caption := ATexto;
    end;
  end;
begin
  Rotular('LINEA_', SCaptionColumnaPedidoLinea);
  Rotular('REF_PRV_', SCaptionColumnaPedidoModeloProveedor);
  Rotular('DESCRIPCION_ARTICULO_', SCaptionColumnaPedidoDescripcion);
  Rotular('CANTIDAD_', SCaptionColCantidad);
  Rotular('PRECIO_COMPRA_SIVA_ARTICULO_', SCaptionColumnaPedidoPrecioCompra);
  Rotular('PORCENTAJE_DTO_', SCaptionDescuentoLineaCompra);
  Rotular('PORCENTAJE_IVA_', SCaptionColumnaPedidoPorcentajeIva);
  if AModo = mcsTallasHorPed then
    Rotular('TOTAL_', SCaptionColumnaCompraTotalUnidades)
  else
    Rotular('TOTAL_', SCaptionColumnaPedidoTotal);
  Rotular('CODIGO_ALMACEN_', SCaptionColumnaPedidoAlmacen);
  Rotular('CODIGO_ART_', SCaptionColArticulo);
  if AModo = mcsSku then
    Rotular('CODIGO_UNIDAD_', SCaptionColSkuArtColorTalla)
  else
    Rotular('CODIGO_UNIDAD_', SCaptionColSku);
  Rotular('LOTE_', SCaptionColumnaLoteSerie);
  Rotular('FECHA_CADUCIDAD_', SCaptionColumnaCaducidad);
end;

procedure VincularCantidadesHostDocumentoCompra(
  const AColumnas: TColumnasHostDocumentoCompra;
  const ATallas: array of TcxGridDBColumn;
  AUnidades: TUnidadesMedida);
var
  bMostrarUnidad: Boolean;
begin
  bMostrarUnidad := AColumnas.ColCantidad <> nil;
  VincularCantidadGrid(AColumnas.ColCantidad, AColumnas.ColTipoCantidad,
    AUnidades, bMostrarUnidad);
  VincularCantidadesGrid(ATallas, AColumnas.ColTipoCantidad, AUnidades,
    bMostrarUnidad);
  VincularCantidadGrid(AColumnas.ColTotalUds, AColumnas.ColTipoCantidad,
    AUnidades, bMostrarUnidad);
end;

// Texto libre generaba stock en almacenes inexistentes (FZ-ISSUE-108).
procedure ConvertirColumnaAlmacenEnLista(AColumna: TcxGridDBColumn;
  AAlmacenes: TDataSource);
var
  Propiedades: TcxLookupComboBoxProperties;
  Columna: TcxLookupDBGridColumn;
begin
  if Assigned(AColumna) and Assigned(AAlmacenes) then
  begin
    AColumna.PropertiesClass := TcxLookupComboBoxProperties;
    Propiedades := TcxLookupComboBoxProperties(AColumna.Properties);
    Propiedades.BeginUpdate;
    try
      Propiedades.ListSource := AAlmacenes;
      Propiedades.KeyFieldNames := 'CODIGO_ALM_ALM';
      Propiedades.ListColumns.Clear;
      Columna := Propiedades.ListColumns.Add;
      Columna.FieldName := 'CODIGO_ALM_ALM';
      Columna.Caption := SCaptionColumnaCodigoAlmacen;
      Columna.Width := 60;
      Columna := Propiedades.ListColumns.Add;
      Columna.FieldName := 'NOMBRE_ALM_ALM';
      Columna.Caption := SCaptionColumnaNombreAlmacen;
      Columna.Width := 160;
      Propiedades.ListFieldIndex := 0;
      Propiedades.DropDownListStyle := lsFixedList;
      Propiedades.DropDownAutoSize := True;
      Propiedades.DropDownRows := 15;
      Propiedades.ImmediatePost := True;
    finally
      Propiedades.EndUpdate;
    end;
  end;
end;

function CrearConfigPivoteBandasDocumentoCompra(
  AConexion: TUniConnection; const AUsuario: string;
  ASourceMaster, ASourceLineas: TDataSource;
  const APrefijoCabecera, APrefijoLinea,
  ACampoPrecioBase: string;
  AMaxColumnas: Integer): TGridPivoteVentaConfig;
begin
  Result := Default(TGridPivoteVentaConfig);
  Result.Conexion := AConexion;
  Result.Usuario := AUsuario;
  Result.SourceMaster := ASourceMaster;
  Result.SourceLineas := ASourceLineas;
  Result.FieldSerieMaster := 'SERIE_' + APrefijoCabecera;
  Result.FieldNumeroMaster := 'NUMERO_' + APrefijoCabecera;
  Result.FieldLinea := 'LINEA_' + APrefijoLinea;
  Result.FieldArt := 'CODIGO_ART_' + APrefijoLinea;
  Result.FieldSku := 'CODIGO_UNIDAD_' + APrefijoLinea;
  Result.FieldDescripcion :=
    'DESCRIPCION_ARTICULO_' + APrefijoLinea;
  Result.FieldTipoCantidad :=
    'TIPO_CANTIDAD_ARTICULO_' + APrefijoLinea;
  Result.FieldCantidadPedida := 'CANTIDAD_' + APrefijoLinea;
  Result.FieldPrecioBase := ACampoPrecioBase;
  Result.FieldAlmacen := 'CODIGO_ALMACEN_' + APrefijoLinea;
  Result.FieldAlmacenMaster :=
    'CODIGO_ALM_' + APrefijoCabecera;
  Result.MaxColumnas := AMaxColumnas;
end;

procedure EstablecerVisibilidadColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn; AVisible: Boolean);
var
  iIndice: Integer;
begin
  for iIndice := Low(AColumnas) to High(AColumnas) do
    if Assigned(AColumnas[iIndice]) then
      AColumnas[iIndice].Visible := AVisible;
end;

function CaptionModoLineasDocumento(const ACaptionBase,
  ACaptionSinConstruir: string; AConstruido: Boolean;
  AModo: TModoColumnasSku; AUsaBandasSeparadas: Boolean): string;
begin
  Result := ACaptionSinConstruir;
  if AConstruido then
  begin
    Result := Format(SCaptionTabModoDesglose, [ACaptionBase]);
    if AModo = mcsSku then
      Result := Format(SCaptionTabModoSku, [ACaptionBase])
    else if AModo = mcsTallasHorPed then
    begin
      if AUsaBandasSeparadas then
        Result := Format(SCaptionTabModoTallasHorizBandas,
                         [ACaptionBase])
      else
        Result := Format(SCaptionTabModoTallasHoriz, [ACaptionBase]);
    end
    else if AUsaBandasSeparadas and (AModo = mcsTallasInline) then
      Result := Format(SCaptionTabModoTallasHoriz, [ACaptionBase]);
  end;
end;

procedure RestablecerCaptionsAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn);
var
  iIndice: Integer;
begin
  for iIndice := Low(AColumnas) to High(AColumnas) do
    if Assigned(AColumnas[iIndice]) then
      AColumnas[iIndice].Caption :=
        Format(SCaptionAtributoN, [iIndice + 1]);
end;

procedure AplicarNombresAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn;
  const ANombres: array of string);
var
  iIndice: Integer;
begin
  iIndice := 0;
  while (iIndice <= High(AColumnas)) and
        (iIndice <= High(ANombres)) do
  begin
    if Assigned(AColumnas[iIndice]) then
      AColumnas[iIndice].Caption := ANombres[iIndice];
    Inc(iIndice);
  end;
end;

procedure AplicarNombresAtributosGlobalesDocumento(
  AVista: TcxGridDBTableView; const ANombres: array of string);
var
  iColumna: Integer;
  iNombre: Integer;
  iOrden: Integer;
  oColumna: TcxGridDBColumn;
begin
  if Assigned(AVista) then
  begin
    iNombre := Low(ANombres);
    iOrden := 1;
    while iNombre <= High(ANombres) do
    begin
      for iColumna := 0 to AVista.ColumnCount - 1 do
      begin
        oColumna := AVista.Columns[iColumna];
        if oColumna.Tag = iOrden then
          oColumna.Caption := ANombres[iNombre];
      end;
      Inc(iNombre);
      Inc(iOrden);
    end;
  end;
end;

function LeerNombresAtributosDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  ACantidadMaxima: Integer): TArray<string>;
var
  iIndice: Integer;
  sArticulo: string;
begin
  SetLength(Result, 0);
  if Assigned(AConsulta) and Assigned(ALineas) and ALineas.Active and
     not ALineas.IsEmpty then
  begin
    sArticulo := ALineas.FieldByName(ACampoArticulo).AsString;
    if sArticulo <> '' then
    begin
      AConsulta.Close;
      try
        AConsulta.ParamByName('ARTICULO').AsString := sArticulo;
        AConsulta.Open;
        iIndice := 0;
        while (not AConsulta.Eof) and
              (iIndice < ACantidadMaxima) do
        begin
          SetLength(Result, iIndice + 1);
          Result[iIndice] :=
            AConsulta.FieldByName('NOMBRE_ATRIBUTO').AsString;
          Inc(iIndice);
          AConsulta.Next;
        end;
      finally
        AConsulta.Close;
      end;
    end;
  end;
end;

procedure CargarCaptionsAtributosDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  const AColumnas: array of TcxGridDBColumn);
var
  aNombres: TArray<string>;
begin
  if Assigned(AConsulta) then
  begin
    RestablecerCaptionsAtributosDocumento(AColumnas);
    aNombres := LeerNombresAtributosDocumento(AConsulta, ALineas,
      ACampoArticulo, Length(AColumnas));
    AplicarNombresAtributosDocumento(AColumnas, aNombres);
  end;
end;

procedure ActualizarCaptionEjeFilaDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  AColumna: TcxGridDBColumn; var AArticuloLeido: string);
var
  aNombres: TArray<string>;
  sArticulo: string;
begin
  if Assigned(AConsulta) and Assigned(AColumna) and AColumna.Visible and
     Assigned(ALineas) and ALineas.Active and (not ALineas.IsEmpty) then
  begin
    sArticulo := ALineas.FieldByName(ACampoArticulo).AsString;
    if (sArticulo <> '') and (sArticulo <> AArticuloLeido) then
    begin
      AArticuloLeido := sArticulo;
      aNombres := LeerNombresAtributosDocumento(AConsulta, ALineas,
        ACampoArticulo, 1);
      if (Length(aNombres) > 0) and (Trim(aNombres[0]) <> '') then
        AColumna.Caption := aNombres[0]
      else
        AColumna.Caption := SCaptionColColor;
    end;
  end;
end;

function CopiarColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn):
  TArray<TcxGridDBColumn>;
var
  iIndice: Integer;
begin
  SetLength(Result, Length(AColumnas));
  for iIndice := Low(AColumnas) to High(AColumnas) do
    Result[iIndice] := AColumnas[iIndice];
end;

function CrearConfigTallasDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra): TGridTallasConfig;
begin
  Result := Default(TGridTallasConfig);
  Result.Conexion := AConfig.Conexion;
  Result.ContextoSesion := AConfig.ContextoSesion;
  Result.Usuario := AConfig.Usuario;
  Result.Grid := AConfig.Vista;
  Result.SourceMaster := AConfig.SourceMaster;
  Result.SourceLineas := AConfig.SourceLineas;
  Result.ColumnasTallas := AConfig.ColumnasTallas;
  Result.FieldSerieMaster := 'SERIE_' + AConfig.PrefijoCabecera;
  Result.FieldNumeroMaster := 'NUMERO_' + AConfig.PrefijoCabecera;
  Result.FieldLinea := 'LINEA_' + AConfig.PrefijoLinea;
  Result.FieldArticulo := 'CODIGO_ART_' + AConfig.PrefijoLinea;
  Result.FieldConjuntoPivot := 'ID_AC_PIVOT_' + AConfig.PrefijoLinea;
  Result.FieldPrecioBase :=
    'PRECIO_COMPRA_SIVA_ARTICULO_' + AConfig.PrefijoLinea;
  Result.FieldTotalUds := 'TOTAL_UNIDADES_' + AConfig.PrefijoLinea;
  Result.FieldTotalLinea := 'TOTAL_' + AConfig.PrefijoLinea;
  Result.TablaCeldas := 'fza_' + AConfig.NombreTablaDocumento +
    '_compra_celdas';
  Result.FieldSerieCel := 'SERIE_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldNumeroCel := 'NUMERO_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldLineaCel := 'LINEA_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldFilaCel := 'ID_FILA_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldAvPivotCel := 'ID_AV_PIVOT_' + AConfig.PrefijoCelda;
  Result.FieldCantidadCel := 'CANTIDAD_' + AConfig.PrefijoCelda;
  Result.FieldAlmacenCel := 'CODIGO_ALM_' + AConfig.PrefijoCelda;
  Result.IdFilaFijo := 1;
  Result.MaxColumnas := Length(AConfig.ColumnasTallas);
end;

function CrearConfigPivoteDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra;
  AGestor: TGestorGridTallas): TGridPivoteCompraConfig;
var
  iCantidadCampos: Integer;
begin
  Result := Default(TGridPivoteCompraConfig);
  Result.Conexion := AConfig.Conexion;
  Result.RegistroLog := AConfig.RegistroLog;
  if AConfig.AplicarContextoPivote then
    Result.ContextoSesion := AConfig.ContextoSesion;
  Result.Grid := AConfig.Vista;
  Result.SourceMaster := AConfig.SourceMaster;
  Result.SourceLineas := AConfig.ConsultaLineas;
  Result.Gestor := AGestor;
  Result.ColColorPivot := AConfig.ColColorPivot;
  Result.ColColorProveedorPivot := AConfig.ColColorProveedorPivot;
  Result.ColumnasTallas := AConfig.ColumnasTallas;
  Result.MaxColumnasTallas := Length(AConfig.ColumnasTallas);
  Result.TablaLineas := 'fza_' + AConfig.NombreTablaDocumento +
    '_compra_lineas';
  Result.FieldSerieMaster := 'SERIE_' + AConfig.PrefijoCabecera;
  Result.FieldNumeroMaster := 'NUMERO_' + AConfig.PrefijoCabecera;
  Result.FieldSerieLin := 'SERIE_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoLinea;
  Result.FieldNumeroLin := 'NUMERO_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoLinea;
  Result.FieldLinea := 'LINEA_' + AConfig.PrefijoLinea;
  Result.FieldArt := 'CODIGO_ART_' + AConfig.PrefijoLinea;
  Result.FieldSku := 'CODIGO_UNIDAD_' + AConfig.PrefijoLinea;
  Result.FieldCantidad := 'CANTIDAD_' + AConfig.PrefijoLinea;
  Result.FieldPrecioBase :=
    'PRECIO_COMPRA_SIVA_ARTICULO_' + AConfig.PrefijoLinea;
  Result.FieldTotalUds := 'TOTAL_UNIDADES_' + AConfig.PrefijoLinea;
  Result.FieldTotalLinea := 'TOTAL_' + AConfig.PrefijoLinea;
  if AConfig.TieneCantidadRecibida then
    Result.FieldCantidadRecibida :=
      'CANTIDAD_RECIBIDA_' + AConfig.PrefijoLinea;
  Result.FieldIdAcPivot := 'ID_AC_PIVOT_' + AConfig.PrefijoLinea;
  Result.FieldAlmacen := 'CODIGO_ALMACEN_' + AConfig.PrefijoLinea;
  Result.FieldAlmacenMaster := 'CODIGO_ALM_' + AConfig.PrefijoCabecera;
  Result.FieldColorTexto := AConfig.CampoColorTexto;
  iCantidadCampos := 3;
  if AConfig.TieneCantidadRecibida then
    iCantidadCampos := 4;
  SetLength(Result.CamposOcultosEnPivote, iCantidadCampos);
  Result.CamposOcultosEnPivote[0] :=
    'CODIGO_UNIDAD_' + AConfig.PrefijoLinea;
  Result.CamposOcultosEnPivote[1] :=
    'CANTIDAD_' + AConfig.PrefijoLinea;
  if AConfig.TieneCantidadRecibida then
  begin
    Result.CamposOcultosEnPivote[2] :=
      'CANTIDAD_RECIBIDA_' + AConfig.PrefijoLinea;
    Result.CamposOcultosEnPivote[3] :=
      'TOTAL_' + AConfig.PrefijoLinea;
  end
  else
    Result.CamposOcultosEnPivote[2] :=
      'TOTAL_' + AConfig.PrefijoLinea;
end;

procedure ConfigurarEventosTallasDocumento(
  const AColumnas: array of TcxGridDBColumn;
  AOnEditValueChanged: TNotifyEvent;
  AOnValidate: TcxEditValidateEvent);
var
  iIndice: Integer;
  oPropiedades: TcxCurrencyEditProperties;
begin
  for iIndice := Low(AColumnas) to High(AColumnas) do
  begin
    if Assigned(AColumnas[iIndice]) and
       (AColumnas[iIndice].Properties is
        TcxCurrencyEditProperties) then
    begin
      oPropiedades :=
        TcxCurrencyEditProperties(AColumnas[iIndice].Properties);
      oPropiedades.OnEditValueChanged := AOnEditValueChanged;
      oPropiedades.OnValidate := AOnValidate;
    end;
  end;
end;

end.
