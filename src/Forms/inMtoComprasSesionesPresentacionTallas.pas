{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionTallas                        }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Edicion de tallas de la sesion de compra: columnas inline no-bound,       }
{    catalogo de sistemas de tallaje, combo de seleccion, pintado de celdas,   }
{    bloqueo de posiciones que no aplican y salto al distribuidor por almacen. }
{    El calculo y la persistencia de celdas siguen en TGestorGridTallas.       }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionTallas;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Variants,
  System.UITypes,
  System.Generics.Collections,
  Data.DB,
  Uni,
  Vcl.Controls,
  cxControls,
  cxGraphics,
  cxEdit,
  cxButtonEdit,
  cxCurrencyEdit,
  cxDBLookupComboBox,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibContextoSesionIntf,
  inLibDistribuidorPersistenciaIntf,
  inLibModoTallasIntf,
  inLibGridTallasInline, inLibUnidadesMedida,
  inLibComprasSesionesPresentacionIntf;

type
  TEntornoTallasSesion = record
    Conexion: TUniConnection;
    ContextoSesion: IContextoSesionAplicacion;
    Usuario: string;
    Unidades: TUnidadesMedida;
    Contenedor: TWinControl;
    Vista: TcxGridDBTableView;
    ColumnaSelector: TcxGridDBColumn;
    FuenteCabecera: TDataSource;
    MaxColumnas: Integer;
    FijarTallajeDefecto: TProc<Integer>;
    DefinirVariacionLinea: TProc<string>;
    ReiniciarCantidadesLinea: TProc<Integer>;
    RefrescarTotalesSesion: TProc;
    RepositorioDistribuidor: IRepositorioDistribuidor;
    // Opcional: catalogo de sistemas (ID_AC, NOMBRE_AC, PRIMERA, ULTIMA)
    // sin abrir, propiedad del coordinador. Sin asignar se consulta la
    // BBDD con Conexion.
    CrearCatalogoConjuntos: TFunc<TDataSet>;
    // Opcional: sin asignar se crea el adaptador de la conexion UniDAC.
    PersistenciaTallas: IPersistenciaGridTallasInline;
  end;

  TCoordinadorTallasSesion = class
  private
    FEntorno: TEntornoTallasSesion;
    FConjuntos: TDataSet;
    FFuenteConjuntos: TDataSource;
    FColumnas: TArray<TcxGridDBColumn>;
    FGestor: TGestorGridTallas;
    FPlanificadorRecarga: IPlanificadorDiferido;
    FRecargandoCantidades: Boolean;
    FDatosCambiadosAnterior: TNotifyEvent;
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FAplicandoSistema: Boolean;
    FTamanoLetraEditor: Integer;
    FValorAntesDesplegar: Variant;
    FNombresSistemas: TArray<string>;
    // Celda (linea, posicion) cuyo distribuidor acaba de cerrarse y
    // guarda de reentrada mientras el modal esta abierto.
    FDistribuidorAbierto: Boolean;
    FLineaDistribuida: Integer;
    FPosicionDistribuida: Integer;
    procedure DatosRejillaCambiados(Sender: TObject);
    procedure RecargarCantidadesTrasCambio;
    procedure AbrirCatalogoConjuntos;
    procedure CargarNombresSistemas;
    procedure ConfigurarComboSistema;
    procedure SistemaCambiado(ASender: TObject);
    procedure AlAbrirDesplegable(ASender: TObject);
    procedure AlCerrarDesplegable(ASender: TObject);
    procedure AlCerrarPopup(ASender: TcxControl;
      AMotivo: TcxEditCloseUpReason);
    procedure ReiniciarCantidadesSiCambia(AIdAnterior, AIdNuevo: Integer);
    procedure AjustarAnchoLista(AEditor: TcxCustomEdit);
    procedure CeldaTallaCambiada(ASender: TObject);
    procedure ValidarCantidadTalla(Sender: TObject;
      var DisplayValue: TcxEditValue; var ErrorText: TCaption;
      var Error: Boolean);
    function PuedeElegirSistema: Boolean;
    function HayLineaActiva: Boolean;
    function SistemaEnCelda(AEditor: TcxCustomEdit): Integer;
    function EsLineaReusada: Boolean;
    function EsLineaReusadaSinTallaje: Boolean;
    function DebeDesplegarSelector(AKey: Word; AShift: TShiftState;
      AEditor: TcxCustomEdit): Boolean;
    procedure AplicarSistemaDeLaCelda(AEditor: TcxCustomEdit);
    function BuscarSistemaPorTexto(const ATexto: string): Integer;
    procedure ConfirmarSistemaTecleado(AEditor: TcxCustomEdit);
    function ConfirmarSistemaConEnter(AEditor: TcxCustomEdit): Boolean;
    procedure ValidarSistemaTecleado(Sender: TObject;
      var DisplayValue: TcxEditValue; var ErrorText: TCaption;
      var Error: Boolean);
    procedure DesplegarSelector(AEditor: TcxCustomEdit);
    procedure AplicarSistemaElegido(ASender: TObject; AIdNuevo: Integer);
    procedure RefrescarColumnasSistema;
    function EsColumnaTalla(AItem: TObject; out APosicion: Integer): Boolean;
    function EsFormatoDistribuido: Boolean;
    function DispararBotonColumnaActiva: Boolean;
    function EditorActivo: TcxCustomEdit;
    function SombrearCeldaFueraDeConjunto(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      APosicion: Integer): Boolean;
  public
    constructor Create(const AEntorno: TEntornoTallasSesion);
    destructor Destroy; override;
    // Crea las columnas inline. Debe correr ANTES del inherited del
    // formulario: la apertura del detalle ya recalcula el maximo.
    procedure CrearColumnas;
    // Coloca el bloque de tallas justo detras de la columna selector.
    procedure ReindexarColumnas(AIndiceBase: Integer);
    // Cablea el gestor de tallas con los datasets de la sesion. Se
    // invoca cuando el data module ya esta disponible.
    procedure ConfigurarDatos(ACabecera: TDataSet; ALineas: TDataSet;
      AFuenteLineas: TDataSource);
    procedure AbrirDistribuidor(const ACodigoKit: string = '');
    // Acota la lista de sistemas a un tipo de variación; vacío = todos.
    procedure FiltrarPorVariacion(const ACodigoVariacion: string);
    procedure CambiarVariacionLinea(const ACodigo: string);
    procedure ValidarVariacionLinea(Sender: TObject;
      var DisplayValue: TcxEditValue; var ErrorText: TCaption;
      var Error: Boolean);
    // True si el sistema está en la lista que se ofrece ahora.
    function ContieneSistema(AIdConjunto: Integer): Boolean;
    // Teclas dentro del editor in-place. True = tecla consumida.
    function ProcesarTeclaEditor(AItem: TcxCustomGridTableItem;
      AEdit: TcxCustomEdit; var AKey: Word;
      AShift: TShiftState): Boolean;
    // Teclas a nivel de formulario (KeyPreview). True = consumida.
    function ProcesarTeclaFormulario(var AKey: Word;
      AShift: TShiftState): Boolean;
    // True si la celda ya queda pintada por este colaborador.
    function DibujarCelda(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
    procedure AjustarPermisoEdicion(AItem: TcxCustomGridTableItem;
      var AAllow: Boolean);
    property Gestor: TGestorGridTallas read FGestor;
    property Columnas: TArray<TcxGridDBColumn> read FColumnas;
  end;

implementation

uses
  System.Math, System.StrUtils, inLibMsgArticulos,
  inLibMensajesVcl,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Graphics,
  cxDataStorage,
  cxTextEdit,
  cxDropDownEdit,
  cxLookupDBGrid,
  inLibEnterComoTabDesplegables,
  inLibMsgCompras,
  inMtoModalDistribuidor,
  UniDataComprasSesionesPresentacionRepositorio,
  UniDataModoTallas, inLibErroresBBDD,
  inMtoComprasSesionesPresentacionPlanificador;

type
  // Acceso a CloseUp (protegido) para aceptar el elemento marcado.
  TDesplegableAcceso = class(TcxCustomDropDownEdit);

resourcestring
  SAvisoCambiarVariacionLinea =
    'Cambiar la variación borra las cantidades y los precios por talla ' +
    'de esta línea. ¿Continuar?';
  SCabeceraSistemaSelectorTallas = 'Sistema';
  SCabeceraDesdeSelectorTallas = 'Desde';
  SCabeceraHastaSelectorTallas = 'Hasta';

const
  // Ancho del desplegable del combo de sistema de tallaje.
  cAnchoSelectorTallas = 420;
  cAnchoColumnaRangoTallas = 70;
  cFilasSelectorTallas = 15;
  // Puntos que crece la letra de la lista respecto a la del grid.
  cAumentoLetraSelectorTallas = 2;
  // Gris claro de las posiciones que no aplican al conjunto de la fila.
  cColorCeldaInactiva = $00E8E8E8;

constructor TCoordinadorTallasSesion.Create(
  const AEntorno: TEntornoTallasSesion);
begin
  inherited Create;
  if not Assigned(AEntorno.Vista) then
    raise EArgumentNilException.Create('AEntorno.Vista');
  if AEntorno.MaxColumnas <= 0 then
    raise EArgumentException.Create('AEntorno.MaxColumnas');
  if not Assigned(AEntorno.ReiniciarCantidadesLinea) then
    raise EArgumentNilException.Create('AEntorno.ReiniciarCantidadesLinea');
  if not (AEntorno.ColumnaSelector.Properties is
          TcxLookupComboBoxProperties) then
    raise EArgumentException.Create('AEntorno.ColumnaSelector');
  FEntorno := AEntorno;
  AbrirCatalogoConjuntos;
  SetLength(FColumnas, FEntorno.MaxColumnas);
  ConfigurarComboSistema;
end;

destructor TCoordinadorTallasSesion.Destroy;
begin
  if Assigned(FPlanificadorRecarga) then
  begin
    if TMethod(FEntorno.Vista.DataController.OnDataChanged).Data =
       Pointer(Self) then
      FEntorno.Vista.DataController.OnDataChanged :=
        FDatosCambiadosAnterior;
    FPlanificadorRecarga := nil;
  end;
  // La columna vive en el DFM y sobrevive al coordinador: se suelta la
  // lista antes de liberar su origen de datos.
  TcxLookupComboBoxProperties(
    FEntorno.ColumnaSelector.Properties).ListSource := nil;
  FreeAndNil(FGestor);
  FreeAndNil(FFuenteConjuntos);
  FreeAndNil(FConjuntos);
  inherited Destroy;
end;

// El dataset notifica antes de que cxGrid termine de reconstruir sus
// registros. La recarga se pide al DataController, tras ese ultimo cambio.
procedure TCoordinadorTallasSesion.DatosRejillaCambiados(Sender: TObject);
begin
  if Assigned(FDatosCambiadosAnterior) then
    FDatosCambiadosAnterior(Sender);
  if not FRecargandoCantidades and Assigned(FGestor) then
    FPlanificadorRecarga.Rearmar;
end;

procedure TCoordinadorTallasSesion.RecargarCantidadesTrasCambio;
begin
  if Assigned(FGestor) then
  begin
    // Escribir Values[] tambien notifica OnDataChanged. No rearma otra
    // recarga: el repintado no debe formar un bucle ni grabar cantidades.
    FRecargandoCantidades := True;
    try
      FGestor.CargarCantidadesTodasLineas;
    finally
      FRecargandoCantidades := False;
    end;
  end;
end;

// Solo conjuntos del atributo pivot (ID_VA_AC = 'TAL'), con primera y
// ultima talla para mostrarlas como rango en la lista del combo.
procedure TCoordinadorTallasSesion.AbrirCatalogoConjuntos;
begin
  if Assigned(FEntorno.CrearCatalogoConjuntos) then
    FConjuntos := FEntorno.CrearCatalogoConjuntos()
  else
    FConjuntos := CrearConsultaConjuntosTallasUniDAC(FEntorno.Conexion);
  FConjuntos.Open;
  FFuenteConjuntos := TDataSource.Create(nil);
  FFuenteConjuntos.DataSet := FConjuntos;
  CargarNombresSistemas;
end;

// Nombres para medir el ancho de la lista al desplegarla.
procedure TCoordinadorTallasSesion.CargarNombresSistemas;
begin
  FNombresSistemas := nil;
  FConjuntos.First;
  while not FConjuntos.Eof do
  begin
    if Assigned(FConjuntos.FindField('CANTIDAD_TALLAS')) then
      FEntorno.MaxColumnas := Max(FEntorno.MaxColumnas,
        FConjuntos.FieldByName('CANTIDAD_TALLAS').AsInteger);
    FNombresSistemas := FNombresSistemas +
      [FConjuntos.FieldByName('NOMBRE_AC').AsString];
    FConjuntos.Next;
  end;
  FConjuntos.First;
end;

// La lista del combo solo ofrece colecciones del tipo de variación de la
// sesión (FZ-ISSUE-420): con «Aroma y medida» no salen los tallajes de
// ropa. Vacío, todas. Un catálogo inyectado sin ese parámetro no filtra.
procedure TCoordinadorTallasSesion.FiltrarPorVariacion(
  const ACodigoVariacion: string);
var
  oConsulta: TUniQuery;
  bAplicando: Boolean;
begin
  bAplicando := FAplicandoSistema;
  FAplicandoSistema := True;
  try
    if FConjuntos is TUniQuery then
    begin
      oConsulta := TUniQuery(FConjuntos);
      if (oConsulta.FindParam('CODIGO_VAR') <> nil) and
         (oConsulta.ParamByName('CODIGO_VAR').AsString <>
          Trim(ACodigoVariacion)) then
      begin
        oConsulta.Close;
        oConsulta.ParamByName('CODIGO_VAR').AsString :=
          Trim(ACodigoVariacion);
        oConsulta.Open;
        CargarNombresSistemas;
      end;
    end;
  finally
    FAplicandoSistema := bAplicando;
  end;
end;

function TCoordinadorTallasSesion.ContieneSistema(
  AIdConjunto: Integer): Boolean;
begin
  Result := (AIdConjunto > 0) and FConjuntos.Active and
    FConjuntos.Locate('ID_AC', AIdConjunto, []);
end;

// La columna esta ligada al ID_AC: el combo muestra NOMBRE_AC y
// despliega Sistema / Desde / Hasta. Busca por nombre y acepta codigo o ID.
procedure TCoordinadorTallasSesion.ConfigurarComboSistema;
var
  Propiedades: TcxLookupComboBoxProperties;
  Columna: TcxLookupDBGridColumn;
begin
  Propiedades := TcxLookupComboBoxProperties(
    FEntorno.ColumnaSelector.Properties);
  Propiedades.BeginUpdate;
  try
    Propiedades.ListSource := FFuenteConjuntos;
    Propiedades.KeyFieldNames := 'ID_AC';
    Propiedades.ListColumns.Clear;
    Columna := Propiedades.ListColumns.Add;
    Columna.FieldName := 'NOMBRE_AC';
    Columna.Caption := SCabeceraSistemaSelectorTallas;
    Columna.Width := cAnchoSelectorTallas -
      (2 * cAnchoColumnaRangoTallas);
    Columna := Propiedades.ListColumns.Add;
    Columna.FieldName := 'PRIMERA';
    Columna.Caption := SCabeceraDesdeSelectorTallas;
    Columna.Width := cAnchoColumnaRangoTallas;
    Columna.HeaderAlignment := taCenter;
    Columna := Propiedades.ListColumns.Add;
    Columna.FieldName := 'ULTIMA';
    Columna.Caption := SCabeceraHastaSelectorTallas;
    Columna.Width := cAnchoColumnaRangoTallas;
    Columna.HeaderAlignment := taCenter;
    Propiedades.ListFieldIndex := 0;
    Propiedades.ListOptions.ShowHeader := True;
    Propiedades.ListOptions.CaseInsensitive := True;
    Propiedades.DropDownListStyle := lsEditList;
    Propiedades.IncrementalFilteringOptions :=
      Propiedades.IncrementalFilteringOptions + [ifoUseContainsOperator];
    Propiedades.DropDownWidth := cAnchoSelectorTallas;
    Propiedades.DropDownRows := cFilasSelectorTallas;
    Propiedades.ImmediateDropDownWhenKeyPressed := True;
    Propiedades.ClearKey := VK_DELETE;
    Propiedades.OnEditValueChanged := SistemaCambiado;
    Propiedades.OnValidate := ValidarSistemaTecleado;
    Propiedades.OnInitPopup := AlAbrirDesplegable;
    Propiedades.OnCloseUp := AlCerrarDesplegable;
    Propiedades.OnClosePopup := AlCerrarPopup;
  finally
    Propiedades.EndUpdate;
  end;
end;

// La lista toma la letra del editor al desplegarse (justo despues de
// OnInitPopup): se agranda aqui y se devuelve al cerrar. Los
// TJvEnterAsTab los apaga el formulario mientras el grid tiene el foco.
procedure TCoordinadorTallasSesion.AlAbrirDesplegable(ASender: TObject);
var
  Editor: TcxCustomEdit;
begin
  if ASender is TcxCustomEdit then
  begin
    Editor := TcxCustomEdit(ASender);
    FValorAntesDesplegar := Editor.EditValue;
    FTamanoLetraEditor := Editor.Style.Font.Size;
    Editor.Style.Font.Size := FTamanoLetraEditor +
      cAumentoLetraSelectorTallas;
    AjustarAnchoLista(Editor);
  end;
end;

// La columna Sistema mide lo que el nombre mas largo con la letra ya
// agrandada: sin esto los nombres salian cortados.
procedure TCoordinadorTallasSesion.AjustarAnchoLista(
  AEditor: TcxCustomEdit);
const
  cMargenColumna = 24;
  cMargenLista = 28;
var
  Propiedades: TcxLookupComboBoxProperties;
  Medidor: TBitmap;
  sNombre: string;
  iAncho: Integer;
  iAnchoRango: Integer;
begin
  Propiedades := TcxLookupComboBoxProperties(
    FEntorno.ColumnaSelector.Properties);
  iAncho := 0;
  Medidor := TBitmap.Create;
  try
    Medidor.Canvas.Font.Assign(AEditor.Style.Font);
    for sNombre in FNombresSistemas do
    begin
      if Medidor.Canvas.TextWidth(sNombre) > iAncho then
        iAncho := Medidor.Canvas.TextWidth(sNombre);
    end;
    iAnchoRango := Medidor.Canvas.TextWidth('XXXXL') + cMargenColumna;
  finally
    Medidor.Free;
  end;
  if iAnchoRango < cAnchoColumnaRangoTallas then
    iAnchoRango := cAnchoColumnaRangoTallas;
  iAncho := iAncho + cMargenColumna;
  if Propiedades.ListColumns.Count = 3 then
  begin
    Propiedades.ListColumns[0].Width := iAncho;
    Propiedades.ListColumns[1].Width := iAnchoRango;
    Propiedades.ListColumns[2].Width := iAnchoRango;
  end;
  Propiedades.DropDownWidth := iAncho + (2 * iAnchoRango) + cMargenLista;
end;

procedure TCoordinadorTallasSesion.AlCerrarDesplegable(ASender: TObject);
begin
  if (ASender is TcxCustomEdit) and (FTamanoLetraEditor > 0) then
  begin
    TcxCustomEdit(ASender).Style.Font.Size := FTamanoLetraEditor;
    FTamanoLetraEditor := 0;
  end;
end;

// crCancel no restaura el texto de la busqueda incremental del lookup.
// Se repone antes de perder el foco, sin aplicar el candidato ni borrar
// cantidades. Enter y la seleccion con raton conservan su curso normal.
procedure TCoordinadorTallasSesion.AlCerrarPopup(ASender: TcxControl;
  AMotivo: TcxEditCloseUpReason);
begin
  if (AMotivo = crCancel) and (ASender is TcxCustomEdit) then
  begin
    FAplicandoSistema := True;
    try
      TcxCustomEdit(ASender).EditValue := FValorAntesDesplegar;
    finally
      FAplicandoSistema := False;
    end;
  end;
end;

procedure TCoordinadorTallasSesion.SistemaCambiado(ASender: TObject);
var
  vNuevo: Variant;
  iNuevo: Integer;
begin
  if (not FAplicandoSistema) and (ASender is TcxCustomEdit) then
  begin
    vNuevo := TcxCustomEdit(ASender).EditValue;
    iNuevo := 0;
    if VarIsNumeric(vNuevo) then
      iNuevo := vNuevo;
    if HayLineaActiva and
       ((iNuevo > 0) or (FLineas.FieldByName(
         'ID_AC_PIVOT_SESLIN').AsInteger > 0)) and
       ((VarIsNumeric(vNuevo) and (iNuevo > 0)) or
        ((VarIsNull(vNuevo) or VarIsEmpty(vNuevo) or
          (VarIsNumeric(vNuevo) and (iNuevo = 0))) and
         not ((ASender is TcxCustomDropDownEdit) and
           TcxCustomDropDownEdit(ASender).DroppedDown))) then
    begin
      FAplicandoSistema := True;
      try
        AplicarSistemaElegido(ASender, iNuevo);
      finally
        FAplicandoSistema := False;
      end;
    end;
  end;
end;

// Patron heredado de inMtoCajaOpe: BeginUpdate + CreateColumn y asignar
// Index al final. Predefinirlas en el DFM disparaba RLINK32.
procedure TCoordinadorTallasSesion.CrearColumnas;
var
  iColumna: Integer;
  Columna: TcxGridDBColumn;
  iIndiceBase: Integer;
begin
  iIndiceBase := FEntorno.ColumnaSelector.Index;
  FEntorno.Vista.BeginUpdate;
  try
    for iColumna := 0 to FEntorno.MaxColumnas - 1 do
    begin
      Columna := FEntorno.Vista.CreateColumn;
      Columna.Name := Format('dbcLinTalla%2.2d', [iColumna + 1]);
      Columna.Tag := iColumna + 1;
      Columna.Caption := '';
      Columna.Visible := False;
      Columna.Width := 50;
      Columna.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(Columna.Properties).DisplayFormat :=
        '#,##0.######';
      TcxCurrencyEditProperties(Columna.Properties).DecimalPlaces := 6;
      Columna.Properties.OnValidate := ValidarCantidadTalla;
      Columna.HeaderAlignmentHorz := taCenter;
      TcxCurrencyEditProperties(
        Columna.Properties).Alignment.Horz := taCenter;
      // ValueTypeClass no es serializable en DFM: solo runtime.
      Columna.DataBinding.ValueTypeClass := TcxFloatValueType;
      Columna.Index := iIndiceBase + iColumna + 1;
      FColumnas[iColumna] := Columna;
    end;
  finally
    FEntorno.Vista.EndUpdate;
  end;
end;

procedure TCoordinadorTallasSesion.ValidarCantidadTalla(Sender: TObject;
  var DisplayValue: TcxEditValue; var ErrorText: TCaption;
  var Error: Boolean);
var
  Unidad: TUnidadInfo;
  Cantidad: Double;
begin
  if not Error and Assigned(FEntorno.Unidades) and HayLineaActiva and
     not VarIsNull(DisplayValue) and not VarIsEmpty(DisplayValue) then
  begin
    Unidad := FEntorno.Unidades.Info(
      FLineas.FieldByName('TIPO_CANTIDAD_SESLIN').AsString);
    if Assigned(Unidad) and TryStrToFloat(VarToStr(DisplayValue),
         Cantidad) and
       (Abs(RoundTo(Cantidad, -Unidad.Decimales) - Cantidad) > 0.0000001)
    then
    begin
      Error := True;
      ErrorText := Format(SErrorCantidadDecimalesUnidad,
        [Unidad.Codigo, Unidad.Decimales]);
    end;
  end;
end;

procedure TCoordinadorTallasSesion.ReindexarColumnas(
  AIndiceBase: Integer);
var
  iColumna: Integer;
begin
  for iColumna := 0 to High(FColumnas) do
  begin
    if Assigned(FColumnas[iColumna]) then
      FColumnas[iColumna].Index := AIndiceBase + iColumna + 1;
  end;
end;

// Cablea el gestor reutilizable con los nombres de tabla y campos
// especificos de Sesiones de compra.
procedure TCoordinadorTallasSesion.ConfigurarDatos(ACabecera: TDataSet;
  ALineas: TDataSet; AFuenteLineas: TDataSource);
var
  Configuracion: TGridTallasConfig;
  ConexionDatos: TUniConnection;
  iColumna: Integer;
begin
  FCabecera := ACabecera;
  FLineas := ALineas;
  FreeAndNil(FGestor);
  Configuracion := Default(TGridTallasConfig);
  ConexionDatos := FEntorno.Conexion;
  if ALineas is TUniQuery then
    ConexionDatos := TUniQuery(ALineas).Connection;
  Configuracion.Conexion := ConexionDatos;
  Configuracion.ContextoSesion := FEntorno.ContextoSesion;
  Configuracion.Usuario := FEntorno.Usuario;
  Configuracion.Grid := FEntorno.Vista;
  Configuracion.SourceMaster := FEntorno.FuenteCabecera;
  Configuracion.SourceLineas := AFuenteLineas;
  Configuracion.ColumnasTallas := FColumnas;
  Configuracion.FieldSerieMaster := 'SERIE_SES';
  Configuracion.FieldNumeroMaster := 'NUMERO_SES';
  Configuracion.FieldLinea := 'LINEA_SESLIN';
  Configuracion.FieldArticulo := 'CODIGO_ART_REUSAR_SESLIN';
  Configuracion.FieldConjuntoPivot := 'ID_AC_PIVOT_SESLIN';
  Configuracion.FieldPrecioBase := 'PRECIO_COMPRA_SESLIN';
  Configuracion.FieldTotalUds := 'TOTAL_UNIDADES_SESLIN';
  Configuracion.FieldTotalLinea := 'TOTAL_LINEA_SESLIN';
  Configuracion.TablaCeldas := 'fza_compras_sesiones_celdas';
  Configuracion.FieldSerieCel := 'SERIE_SES_SESCEL';
  Configuracion.FieldNumeroCel := 'NUMERO_SES_SESCEL';
  Configuracion.FieldLineaCel := 'LINEA_SES_SESCEL';
  Configuracion.FieldFilaCel := 'ID_FILA_SES_SESCEL';
  Configuracion.FieldAvPivotCel := 'ID_AV_PIVOT_SESCEL';
  Configuracion.FieldCantidadCel := 'CANTIDAD_SESCEL';
  Configuracion.FieldAlmacenCel := 'CODIGO_ALM_SESCEL';
  Configuracion.IdFilaFijo := 1;
  Configuracion.MaxColumnas := FEntorno.MaxColumnas;
  Configuracion.ColumnaUnidadesSinTallaje := True;
  Configuracion.Persistencia := FEntorno.PersistenciaTallas;
  if not Assigned(Configuracion.Persistencia) then
    Configuracion.Persistencia := CrearPersistenciaGridTallasInline(
      ConexionDatos,
      CrearConfigPersistenciaTallasInline(Configuracion));
  FGestor := TGestorGridTallas.Create(Configuracion);
  if not Assigned(FPlanificadorRecarga) then
  begin
    FPlanificadorRecarga := TPlanificadorDiferidoTimer.Create(1,
      procedure
      begin
        RecargarCantidadesTrasCambio;
      end);
    FDatosCambiadosAnterior :=
      FEntorno.Vista.DataController.OnDataChanged;
    FEntorno.Vista.DataController.OnDataChanged := DatosRejillaCambiados;
  end;
  FPlanificadorRecarga.Rearmar;
  for iColumna := 0 to High(FColumnas) do
  begin
    if Assigned(FColumnas[iColumna]) then
      TcxCurrencyEditProperties(
        FColumnas[iColumna].Properties).OnEditValueChanged :=
        CeldaTallaCambiada;
  end;
end;

procedure TCoordinadorTallasSesion.CeldaTallaCambiada(ASender: TObject);
var
  Valor: TcxEditValue;
  Mensaje: TCaption;
  Error: Boolean;
begin
  Error := False;
  if ASender is TcxCustomEdit then
  begin
    Valor := TcxCustomEdit(ASender).EditValue;
    ValidarCantidadTalla(ASender, Valor, Mensaje, Error);
  end;
  if Assigned(FGestor) and not Error then
  begin
    FGestor.PersistirCeldaActiva(ASender);
    if Assigned(FEntorno.RefrescarTotalesSesion) then
      FEntorno.RefrescarTotalesSesion();
    // El refresco de totales repinta el grid y borra los Values[] no
    // ligados: hay que volver a publicar las cantidades.
    FGestor.CargarCantidadesTodasLineas;
  end;
end;

function TCoordinadorTallasSesion.EsFormatoDistribuido: Boolean;
begin
  Result := Assigned(FCabecera) and (not FCabecera.IsEmpty) and
            (FCabecera.FieldByName(
              'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
end;

function TCoordinadorTallasSesion.HayLineaActiva: Boolean;
begin
  Result := Assigned(FLineas) and FLineas.Active and
    ((FLineas.State in dsEditModes) or not FLineas.IsEmpty);
end;

function TCoordinadorTallasSesion.PuedeElegirSistema: Boolean;
begin
  Result := HayLineaActiva;
  if Result and EsLineaReusadaSinTallaje then
  begin
    MessageDlg_fza(Format(SAvisoArticuloSesionSinTallaje,
      [FLineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString]),
      mtInformation, [mbOk], 0);
    Result := False;
  end
  else if Result and EsLineaReusada then
  begin
    // Al reusar un modelo el sistema queda fijado al del articulo:
    // cambiarlo descuadraria los SKU ya creados.
    MessageDlg_fza(SErrorCambiarSistemaTallasModeloExistente,
               mtInformation, [mbOk], 0);
    Result := False;
  end;
end;

procedure TCoordinadorTallasSesion.AplicarSistemaElegido(
  ASender: TObject; AIdNuevo: Integer);
var
  iAnterior: Integer;
  bValido: Boolean;
begin
  iAnterior := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  if not (FLineas.State in [dsEdit, dsInsert]) then
    FLineas.Edit;
  if AIdNuevo > 0 then
  begin
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := AIdNuevo;
    FLineas.FieldByName('TIPO_LINEA_SESLIN').AsString := 'MATRIZ';
  end
  else
  begin
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').Clear;
    FLineas.FieldByName('TIPO_LINEA_SESLIN').AsString := 'ESCALAR';
    FLineas.FieldByName('CODIGO_VAR_SESLIN').Clear;
  end;
  bValido := not Assigned(FGestor) or FGestor.ValidarSistemaSeleccionado;
  if bValido then
  begin
    try
      ReiniciarCantidadesSiCambia(iAnterior, AIdNuevo);
    except
      FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := iAnterior;
      if ASender is TcxCustomEdit then
        TcxCustomEdit(ASender).EditValue := iAnterior;
      raise;
    end;
    // Solo una eleccion valida pasa a ser el defecto del documento.
    if Assigned(FEntorno.FijarTallajeDefecto) then
      FEntorno.FijarTallajeDefecto(AIdNuevo);
    RefrescarColumnasSistema;
    if (iAnterior <> AIdNuevo) and
       Assigned(FEntorno.RefrescarTotalesSesion) then
      FEntorno.RefrescarTotalesSesion();
  end
  else
  begin
    FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := iAnterior;
    if ASender is TcxCustomEdit then
      TcxCustomEdit(ASender).EditValue := iAnterior;
  end;
end;

procedure TCoordinadorTallasSesion.ValidarVariacionLinea(Sender: TObject;
  var DisplayValue: TcxEditValue; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  // El ImageCombo valida la descripcion visible; el valor es el codigo.
  sCodigo := VarToStr(TcxCustomEdit(Sender).EditValue);
  if not FAplicandoSistema and not Error and (sCodigo <> FLineas.FieldByName(
    'CODIGO_VAR_SESLIN').AsString) then
    CambiarVariacionLinea(sCodigo);
end;

procedure TCoordinadorTallasSesion.CambiarVariacionLinea(
  const ACodigo: string);
begin
  if EsLineaReusada then
    raise EValidacionBBDD.Create(
      SErrorCambiarSistemaTallasModeloExistente);
  if FLineas.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat > 0 then
    if MessageDlg_fza(SAvisoCambiarVariacionLinea,
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Abort;
  FAplicandoSistema := True;
  try
    FEntorno.ReiniciarCantidadesLinea(
      FLineas.FieldByName('LINEA_SESLIN').AsInteger);
    if not (FLineas.State in dsEditModes) then
      FLineas.Edit;
    FLineas.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := 0;
    FLineas.FieldByName('TOTAL_LINEA_SESLIN').AsFloat := 0;
    FEntorno.DefinirVariacionLinea(ACodigo);
    FiltrarPorVariacion(ACodigo);
    RefrescarColumnasSistema;
  finally
    FAplicandoSistema := False;
  end;
end;

procedure TCoordinadorTallasSesion.ReiniciarCantidadesSiCambia(
  AIdAnterior, AIdNuevo: Integer);
begin
  if AIdAnterior <> AIdNuevo then
  begin
    // Se borran todas las celdas de la linea, tambien las de tallas que
    // ya no son visibles y las repartidas entre varios almacenes.
    FEntorno.ReiniciarCantidadesLinea(
      FLineas.FieldByName('LINEA_SESLIN').AsInteger);
    FLineas.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := 0;
    FLineas.FieldByName('TOTAL_LINEA_SESLIN').AsFloat := 0;
  end;
end;

procedure TCoordinadorTallasSesion.RefrescarColumnasSistema;
var
  iLinea: Integer;
  iRegistro: Integer;
begin
  if Assigned(FGestor) then
  begin
    FGestor.RecalcularMaxColumnas;
    FGestor.ActualizarCaptionsLineaActiva;
    iLinea := FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    iRegistro := FEntorno.Vista.Controller.FocusedRecordIndex;
    if (iLinea > 0) and (iRegistro >= 0) then
    begin
      FEntorno.Vista.DataController.BeginUpdate;
      try
        FGestor.CargarCantidadesUnaLinea(iRegistro, iLinea);
      finally
        FEntorno.Vista.DataController.EndUpdate;
      end;
    end;
  end;
end;

// Sistema que muestra la celda: el del editor abierto (aun sin volcar
// al campo) o, si no hay editor, el de la linea.
function TCoordinadorTallasSesion.SistemaEnCelda(
  AEditor: TcxCustomEdit): Integer;
var
  vValor: Variant;
begin
  Result := 0;
  if AEditor <> nil then
  begin
    vValor := AEditor.EditValue;
    if (not VarIsNull(vValor)) and (not VarIsEmpty(vValor)) and
       VarIsNumeric(vValor) then
      Result := vValor;
  end;
  if (Result <= 0) and HayLineaActiva then
    Result := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
end;

function TCoordinadorTallasSesion.BuscarSistemaPorTexto(
  const ATexto: string): Integer;
var
  Marca: TBookmark;
  Nombre, Codigo, Texto: string;
  Coincidencias, Exacto, Separador, Numero, PorId: Integer;
  BuscarPrefijo: Boolean;
begin
  Result := 0;
  Coincidencias := 0;
  Exacto := 0;
  PorId := 0;
  Texto := Trim(ATexto);
  // Una cifra suelta no debe elegir un rango de tallas por su comienzo.
  BuscarPrefijo := not TryStrToInt(Texto, Numero);
  Marca := FConjuntos.GetBookmark;
  FConjuntos.DisableControls;
  try
    FConjuntos.First;
    while not FConjuntos.Eof do
    begin
      Nombre := FConjuntos.FieldByName('NOMBRE_AC').AsString;
      Codigo := Nombre;
      Separador := Pos(' - ', Nombre);
      if Separador > 0 then
        Codigo := Copy(Nombre, 1, Separador - 1);
      if SameText(Texto, Nombre) or SameText(Texto, Codigo) then
        Exacto := FConjuntos.FieldByName('ID_AC').AsInteger;
      if not BuscarPrefijo and
         (Numero = FConjuntos.FieldByName('ID_AC').AsInteger) then
        PorId := Numero;
      if BuscarPrefijo and (StartsText(Texto, Nombre) or
         ((Separador > 0) and
          StartsText(Texto, Copy(Nombre, Separador + 3, MaxInt)))) then
      begin
        Inc(Coincidencias);
        Result := FConjuntos.FieldByName('ID_AC').AsInteger;
      end;
      FConjuntos.Next;
    end;
    if Exacto > 0 then
      Result := Exacto
    else if PorId > 0 then
      Result := PorId
    else if Coincidencias <> 1 then
      Result := 0;
  finally
    if FConjuntos.BookmarkValid(Marca) then
      FConjuntos.GotoBookmark(Marca);
    FConjuntos.FreeBookmark(Marca);
    FConjuntos.EnableControls;
  end;
end;

procedure TCoordinadorTallasSesion.ValidarSistemaTecleado(Sender: TObject;
  var DisplayValue: TcxEditValue; var ErrorText: TCaption;
  var Error: Boolean);
var
  Texto: string;
  Sistema: Integer;
begin
  if not FAplicandoSistema and not EsLineaReusada then
  begin
    Texto := Trim(VarToStr(DisplayValue));
    if Texto <> '' then
    begin
      Sistema := BuscarSistemaPorTexto(Texto);
      Error := Sistema <= 0;
      if Error then
        ErrorText := Format(SErrorSistemaTallasTecleadoNoValido, [Texto])
      else
        DisplayValue := FConjuntos.Lookup('ID_AC', Sistema, 'NOMBRE_AC');
    end;
  end;
end;

procedure TCoordinadorTallasSesion.ConfirmarSistemaTecleado(
  AEditor: TcxCustomEdit);
var
  Sistema: Integer;
  Texto: string;
begin
  if Assigned(AEditor) and not FAplicandoSistema and
     not EsLineaReusada then
  begin
    Texto := Trim(TDesplegableAcceso(AEditor).Text);
    if Texto <> '' then
    begin
      Sistema := BuscarSistemaPorTexto(Texto);
      if Sistema <= 0 then
        raise EcxEditValidationError.CreateFmt(
          SErrorSistemaTallasTecleadoNoValido, [Texto]);
      FAplicandoSistema := True;
      try
        if AEditor is TcxCustomDropDownEdit then
          TDesplegableAcceso(AEditor).CloseUp(crEnter);
        AEditor.EditValue := Sistema;
        AplicarSistemaElegido(AEditor, Sistema);
      finally
        FAplicandoSistema := False;
      end;
    end;
  end;
end;

// Resolver antes de cerrar la lista: su candidato puede ser otro sistema.
// Sin texto nuevo, Enter conserva la eleccion hecha con las flechas.
function TCoordinadorTallasSesion.ConfirmarSistemaConEnter(
  AEditor: TcxCustomEdit): Boolean;
var
  Texto, NombreActual: string;
  Numero: Integer;
begin
  Result := False;
  if Assigned(AEditor) and not FAplicandoSistema and
     not EsLineaReusada then
  begin
    Texto := Trim(TDesplegableAcceso(AEditor).Text);
    NombreActual := VarToStr(FConjuntos.Lookup('ID_AC',
      AEditor.EditValue, 'NOMBRE_AC'));
    if (Texto <> '') and not SameText(Texto, NombreActual) then
    begin
      // Una descripcion parcial sigue permitiendo elegir en la lista.
      // Un numero debe existir; no se acepta un rango que lo contenga.
      if (BuscarSistemaPorTexto(Texto) > 0) or
         TryStrToInt(Texto, Numero) then
      begin
        ConfirmarSistemaTecleado(AEditor);
        Result := True;
      end;
    end;
  end;
end;

function TCoordinadorTallasSesion.EsLineaReusada: Boolean;
begin
  Result := HayLineaActiva and
            SameText(FLineas.FieldByName(
              'ACCION_DUPLICADO_SESLIN').AsString, 'REUSAR');
end;

// El sistema sale del articulo, y el articulo puede no tener tallaje.
function TCoordinadorTallasSesion.EsLineaReusadaSinTallaje: Boolean;
begin
  Result := EsLineaReusada and
            (FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger <= 0);
end;

// Ctrl+Enter despliega siempre; Enter solo si la celda aun no tiene
// sistema (con sistema, Enter lo aplica y sigue a la celda siguiente).
// En un modelo reusado no hay nada que elegir: Enter sigue su curso
// (antes se consumia y el aviso se repetia en bucle, FZ-ISSUE-138).
function TCoordinadorTallasSesion.DebeDesplegarSelector(AKey: Word;
  AShift: TShiftState; AEditor: TcxCustomEdit): Boolean;
begin
  Result := (AKey = VK_RETURN) and
            ((AShift = [ssCtrl]) or
             ((AShift = []) and (not EsLineaReusada) and
              (SistemaEnCelda(AEditor) <= 0)));
end;

// Enter sobre un sistema ya puesto (p. ej. el propuesto por defecto al
// crear la linea) crea sus columnas de tallas igual que elegirlo.
procedure TCoordinadorTallasSesion.AplicarSistemaDeLaCelda(
  AEditor: TcxCustomEdit);
var
  iSistema: Integer;
begin
  iSistema := SistemaEnCelda(AEditor);
  if (iSistema > 0) and (not FAplicandoSistema) and
     (not EsLineaReusada) and HayLineaActiva then
  begin
    FAplicandoSistema := True;
    try
      AplicarSistemaElegido(AEditor, iSistema);
    finally
      FAplicandoSistema := False;
    end;
  end;
end;

procedure TCoordinadorTallasSesion.DesplegarSelector(
  AEditor: TcxCustomEdit);
begin
  if FConjuntos.IsEmpty then
    MessageDlg_fza(SErrorSistemasTallasSesionNoDisponibles,
               mtInformation, [mbOk], 0)
  else if PuedeElegirSistema and
          (AEditor is TcxCustomDropDownEdit) then
  begin
    if AEditor.CanFocus and (not AEditor.Focused) then
      AEditor.SetFocus;
    TcxCustomDropDownEdit(AEditor).DroppedDown := True;
  end;
end;

// Formato distribuido: las cantidades viven por almacen, asi que la
// edicion inline se sustituye por el modal distribuidor.
procedure TCoordinadorTallasSesion.AbrirDistribuidor(
  const ACodigoKit: string);
var
  Modal: TfrmModalDistribuidor;
  iLinea: Integer;
  iConjunto: Integer;
begin
  iLinea := 0;
  iConjunto := 0;
  if HayLineaActiva then
  begin
    iLinea := FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    iConjunto := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  end;
  if (iLinea > 0) and (iConjunto > 0) then
  begin
    // Persistir la edicion pendiente para que el modal vea el estado
    // consistente de la linea (en particular ID_AC_PIVOT_SESLIN).
    if FLineas.State in [dsEdit, dsInsert] then
      FLineas.Post;
    Modal := TfrmModalDistribuidor.Create(
      Application,
      FEntorno.RepositorioDistribuidor);
    // Evitamos el caFree heredado para poder liberar a mano sin riesgo
    // de doble liberacion.
    Modal.OnClose := nil;
    try
      Modal.Preparar(FEntorno.Conexion, FEntorno.Usuario,
        FCabecera.FieldByName('SERIE_SES').AsString,
        FCabecera.FieldByName('NUMERO_SES').AsString,
        iLinea, iConjunto,
        Trim(FCabecera.FieldByName('CODIGO_PRV_SES').AsString),
        ACodigoKit,
        FLineas.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString);
      FDistribuidorAbierto := True;
      try
        Modal.ShowModal;
      finally
        FDistribuidorAbierto := False;
      end;
      if Modal.Confirmado then
      begin
        // ORDEN CRITICO: el Refresh resetea el DataController y borra
        // los Values[] no-bound, asi que la recarga de cantidades va
        // DESPUES del Refresh.
        if Assigned(FGestor) then
          FGestor.RefrescarTotalesLineaActual;
        FLineas.Refresh;
        if Assigned(FGestor) then
        begin
          FGestor.InvalidarCache;
          FGestor.CargarCantidadesTodasLineas;
        end;
        if Assigned(FEntorno.RefrescarTotalesSesion) then
          FEntorno.RefrescarTotalesSesion();
      end;
    finally
      FreeAndNil(Modal);
    end;
  end;
end;

function TCoordinadorTallasSesion.EsColumnaTalla(AItem: TObject;
  out APosicion: Integer): Boolean;
var
  Columna: TcxGridColumn;
begin
  Result := False;
  APosicion := 0;
  if AItem is TcxGridColumn then
  begin
    Columna := TcxGridColumn(AItem);
    if (Columna.Tag >= 1) and (Columna.Tag <= Length(FColumnas)) and
       (Columna = FColumnas[Columna.Tag - 1]) then
    begin
      APosicion := Columna.Tag;
      Result := True;
    end;
  end;
end;

// Cada fila puede tener un sistema distinto: las posiciones que exceden
// el conjunto de esa fila se sombrean. El bloqueo efectivo de edicion
// lo hace AjustarPermisoEdicion.
function TCoordinadorTallasSesion.SombrearCeldaFueraDeConjunto(
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  APosicion: Integer): Boolean;
var
  Posiciones: TArrPosConjunto;
begin
  Result := False;
  if Assigned(FGestor) then
  begin
    // Sin sistema solo queda, si el articulo no tiene tallas, la
    // columna de unidades.
    Posiciones := FGestor.GetPosicionesRegistro(
      AViewInfo.GridRecord.RecordIndex);
    Result := APosicion > Length(Posiciones);
    if Result then
    begin
      ACanvas.Brush.Color := cColorCeldaInactiva;
      ACanvas.FillRect(AViewInfo.Bounds);
    end;
  end;
end;

// El nombre del sistema lo pinta el propio combo desde su lista.
function TCoordinadorTallasSesion.DibujarCelda(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  iPosicion: Integer;
begin
  Result := False;
  if (AViewInfo.GridRecord <> nil) and
     EsColumnaTalla(AViewInfo.Item, iPosicion) then
    Result := SombrearCeldaFueraDeConjunto(ACanvas, AViewInfo, iPosicion);
end;

procedure TCoordinadorTallasSesion.AjustarPermisoEdicion(
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
var
  iPosicion: Integer;
  iConjunto: Integer;
  iLinea: Integer;
  Posiciones: TArrPosConjunto;
begin
  // Al reusar un modelo el sistema queda fijado al del articulo: el
  // combo no se abre (el aviso sale con Ctrl+Enter; Enter avanza).
  if (AItem = FEntorno.ColumnaSelector) and HayLineaActiva and
     SameText(FLineas.FieldByName(
       'ACCION_DUPLICADO_SESLIN').AsString, 'REUSAR') then
    AAllow := False
  else if EsColumnaTalla(AItem, iPosicion) and Assigned(FGestor) and
     HayLineaActiva then
  begin
    iConjunto := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    // Sin sistema la cantidad no tenia talla a la que ir y se perdia
    // (FZ-ISSUE-138): solo se edita la columna de unidades de un
    // articulo sin tallas; el resto queda bloqueado.
    Posiciones := FGestor.GetPosicionesConjunto(iConjunto);
    if (iConjunto <= 0) and not EsLineaReusada and
       not SameText(FLineas.FieldByName('TIPO_LINEA_SESLIN').AsString,
         'ESCALAR') then
      AAllow := False
    else if iPosicion > Length(Posiciones) then
      AAllow := False
    else if (iConjunto > 0) and EsFormatoDistribuido then
    begin
      // El grid principal muestra la SUMA por talla: el reparto por
      // almacen se hace en el distribuidor.
      AAllow := False;
      // Con AlwaysShowEditor el refresco tras Aceptar vuelve a pedir el
      // editor de la misma celda y el modal se reabria en bucle: no se
      // reabre hasta que el foco pase a otra celda.
      iLinea := FLineas.FieldByName('LINEA_SESLIN').AsInteger;
      if (not FDistribuidorAbierto) and
         ((iLinea <> FLineaDistribuida) or
          (iPosicion <> FPosicionDistribuida)) then
      begin
        FLineaDistribuida := iLinea;
        FPosicionDistribuida := iPosicion;
        AbrirDistribuidor;
      end;
      Exit;
    end;
  end;
  // Edicion en otra celda: el distribuidor vuelve a abrirse al regresar.
  if not FDistribuidorAbierto then
  begin
    FLineaDistribuida := 0;
    FPosicionDistribuida := 0;
  end;
end;

function TCoordinadorTallasSesion.EditorActivo: TcxCustomEdit;
begin
  Result := nil;
  if FEntorno.Vista.Controller.EditingController <> nil then
  begin
    FEntorno.Vista.Controller.EditingController.ShowEdit;
    Result := FEntorno.Vista.Controller.EditingController.Edit;
  end;
end;

// Ctrl+Enter sobre una columna 'editbutton' dispara el click de su
// primer boton, igual que pulsar el ellipsis.
function TCoordinadorTallasSesion.DispararBotonColumnaActiva: Boolean;
var
  Activo: TWinControl;
  Columna: TcxGridColumn;
  Propiedades: TcxButtonEditProperties;
begin
  Result := False;
  Columna := nil;
  Activo := Screen.ActiveControl;
  if (Activo <> nil) and
     ((Activo = FEntorno.Contenedor) or
      FEntorno.Contenedor.ContainsControl(Activo)) then
    Columna := FEntorno.Vista.Controller.FocusedColumn;
  if (Columna <> nil) and
     (Columna.Properties is TcxButtonEditProperties) then
  begin
    Propiedades := TcxButtonEditProperties(Columna.Properties);
    if (Propiedades.Buttons.Count > 0) and
       Assigned(Propiedades.OnButtonClick) then
    begin
      Propiedades.OnButtonClick(EditorActivo, 0);
      Result := True;
    end;
  end;
end;

function TCoordinadorTallasSesion.ProcesarTeclaEditor(
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var AKey: Word;
  AShift: TShiftState): Boolean;
var
  Propiedades: TcxButtonEditProperties;
begin
  Result := False;
  if (AItem = FEntorno.ColumnaSelector) and (AKey = VK_TAB) and
     ((AShift = []) or (AShift = [ssShift])) then
    ConfirmarSistemaTecleado(AEdit);
  // Dentro del grid el Enter llega antes al grid que al combo: pasaba a
  // la celda siguiente, ocultaba el editor y la lista se cerraba sin
  // elegir (con el raton si elegia). Con la lista abierta se acepta aqui
  // el sistema marcado y el grid no se mueve.
  if (AItem = FEntorno.ColumnaSelector) and (AKey = VK_RETURN) and
     (AShift = []) and ConfirmarSistemaConEnter(AEdit) then
  begin
    AKey := 0;
    Result := True;
  end
  else if (AItem = FEntorno.ColumnaSelector) and (AKey = VK_RETURN) and
     (AShift = []) and (AEdit is TcxCustomDropDownEdit) and
     TcxCustomDropDownEdit(AEdit).DroppedDown then
  begin
    TDesplegableAcceso(AEdit).CloseUp(crEnter);
    AplicarSistemaDeLaCelda(AEdit);
    AKey := 0;
    Result := True;
  end
  else if (AItem = FEntorno.ColumnaSelector) and
     DebeDesplegarSelector(AKey, AShift, AEdit) and
     (not EsDesplegableAbierto(AEdit)) then
  begin
    DesplegarSelector(AEdit);
    AKey := 0;
    Result := True;
  end
  // Red de seguridad por si el Ctrl+Enter llega ya dentro del editor.
  else if (AKey = VK_RETURN) and (AShift = [ssCtrl]) and
          (AItem is TcxGridColumn) and
          (TcxGridColumn(AItem).Properties is TcxButtonEditProperties) then
  begin
    Propiedades := TcxButtonEditProperties(
      TcxGridColumn(AItem).Properties);
    if (Propiedades.Buttons.Count > 0) and
       Assigned(Propiedades.OnButtonClick) then
    begin
      Propiedades.OnButtonClick(AEdit, 0);
      AKey := 0;
      Result := True;
    end;
  end;
end;

function TCoordinadorTallasSesion.ProcesarTeclaFormulario(var AKey: Word;
  AShift: TShiftState): Boolean;
var
  Activo: TWinControl;
  Columna: TcxGridColumn;
  Editor: TcxCustomEdit;
  bDesplegado: Boolean;
begin
  Result := False;
  Columna := nil;
  Activo := Screen.ActiveControl;
  if (Activo <> nil) and
     ((Activo = FEntorno.Contenedor) or
      FEntorno.Contenedor.ContainsControl(Activo)) then
    Columna := FEntorno.Vista.Controller.FocusedColumn;
  // Con la lista abierta el Enter es del combo (elige y cierra). El
  // control activo es el interno del combo: se mira tambien su padre.
  bDesplegado := EsDesplegableAbierto(Activo);
  Editor := nil;
  if (Columna = FEntorno.ColumnaSelector) and
     FEntorno.Vista.Controller.EditingController.IsEditing then
    Editor := FEntorno.Vista.Controller.EditingController.Edit;
  if (Columna = nil) and
     FEntorno.Vista.Controller.EditingController.IsEditing then
  begin
    Editor := FEntorno.Vista.Controller.EditingController.Edit;
    if (Editor is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(Editor).DroppedDown then
      Columna := FEntorno.Vista.Controller.FocusedColumn;
  end;
  if (Columna = FEntorno.ColumnaSelector) and (AKey = VK_TAB) and
     ((AShift = []) or (AShift = [ssShift])) then
    ConfirmarSistemaTecleado(Editor);
  if (Columna = FEntorno.ColumnaSelector) and (AKey = VK_RETURN) and
     (AShift = []) and ConfirmarSistemaConEnter(Editor) then
  begin
    AKey := 0;
    Result := True;
  end
  else if (Columna = FEntorno.ColumnaSelector) and (not bDesplegado) and
     DebeDesplegarSelector(AKey, AShift, Editor) then
  begin
    Editor := EditorActivo;
    DesplegarSelector(Editor);
    AKey := 0;
    Result := True;
  end
  // Enter con sistema: se aplican sus columnas y la tecla sigue su curso
  // (el grid pasa a la celda siguiente).
  else if (Columna = FEntorno.ColumnaSelector) and (not bDesplegado) and
          (AKey = VK_RETURN) and (AShift = []) then
    AplicarSistemaDeLaCelda(Editor)
  // Ctrl+Enter abre el selector de la columna editbutton enfocada antes
  // de que la navegacion Enter->Tab del grid mueva el foco.
  else if (AKey = VK_RETURN) and (AShift = [ssCtrl]) and
          DispararBotonColumnaActiva then
  begin
    AKey := 0;
    Result := True;
  end;
end;

end.
