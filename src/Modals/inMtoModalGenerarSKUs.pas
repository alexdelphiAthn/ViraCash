{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenerarSKUs                                         }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.1.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para generar SKUs combinando dimensiones y valores de atributos.    }
{    Arriba se elige la dimensión (color, talla...) y abajo se marcan sus      }
{    valores; devuelve los SKU que se han creado.                              }
{******************************************************************************}
unit inMtoModalGenerarSKUs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.StrUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalAceptCancel, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, System.Actions, Vcl.ActnList, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, Data.DB,
  cxControls, cxSplitter, cxStyles, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  cxCheckBox, System.UITypes, cxContainer, cxLabel, cxTextEdit, cxMaskEdit,
  cxDropDownEdit,
  inLibGeneracionSkus, inLibGeneracionSkusPersistenciaIntf;

type
  TResultadoGenerarSkus = record
    Aceptado: Boolean;
    SkusCreados: TArray<string>;
  end;

  TfrmMtoModalGenerarSKUS = class(TfrmModalAceptCancel)
    dsMaestro: TDataSource;
    dsDetalle: TDataSource;
    pnlBodyCab: TPanel;
    pnlBodyDetalle: TPanel;
    cxSplitter1: TcxSplitter;
    tvMaestro: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    cxGrid2: TcxGrid;
    tvDetalle: TcxGridDBTableView;
    cxGridLevel1: TcxGridLevel;
    tvMaestroID_ATRIBUTO_VA: TcxGridDBColumn;
    tvMaestroID_VA: TcxGridDBColumn;
    tvMaestroNOMBRE_ATRIBUTO: TcxGridDBColumn;
    tvMaestroORDEN_VA: TcxGridDBColumn;
    tvMaestroORDEN_ACA: TcxGridDBColumn;
    tvDetalleID_ATRIBUTO_AC: TcxGridDBColumn;
    tvDetalleID_CONJUNTO_AC: TcxGridDBColumn;
    tvDetalleNOMBRE_AC: TcxGridDBColumn;
    tvDetalleASIGNADO: TcxGridDBColumn;
    btnAddValue: TcxButton;
    tvDetalleID_ATRIBUTO_VA: TcxGridDBColumn;
    tvDetalleORDEN_AV: TcxGridDBColumn;
    actAnadirValor: TAction;
    pnlConjunto: TPanel;
    lblConjunto: TcxLabel;
    cbConjunto: TcxComboBox;
    btnMarcarTodas: TcxButton;
    procedure FormShow(Sender: TObject);
    procedure cbConjuntoPropertiesChange(Sender: TObject);
    procedure btnMarcarTodasClick(Sender: TObject);
    procedure btnAddValueClick(Sender: TObject);
    procedure tvMaestroDblClick(Sender: TObject);
    procedure tvDetalleCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure dsMaestroDataChange(Sender: TObject; Field: TField);
  private type
    // Respuestas que se van reuniendo antes de crear un valor. Nada se
    // escribe en la BBDD hasta tenerlas todas.
    TSolicitudValorSku = record
      IdAtributo: string;
      NombreAtributo: string;
      Nombre: string;
      Orden: Integer;
      Conjunto: TConjuntoAtributoSku;
      // Id = 0: el valor no existe todavía y estrenará el orden indicado.
      Existente: TValorAtributoSku;
      GuardarEnConjunto: Boolean;
    end;
  private
    FDimensionesInicializadas: TArray<string>;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    FRepositorio: IRepositorioGeneracionSkus;
    FDatos: IDatosGeneracionSkus;
    FMaestro: TDataSet;
    FDetalle: TDataSet;
    FResultado: TResultadoGenerarSkus;
    // Conjunto (tallaje, paleta...) asignado a la dimensión activa.
    FIdConjuntoActual: Integer;
    FCargandoConjuntos: Boolean;
    // Solo el propio modal añade filas al detalle; el Insert de la rejilla
    // o del navegador pasa por el diálogo de añadir valor.
    FAnadiendoFila: Boolean;
    procedure ConfigurarNavegador;
    procedure tvDetalleNavigatorButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
    procedure DetalleBeforeInsert(DataSet: TDataSet);
    procedure CargarConjuntosDimension;
    procedure MarcarValoresConjunto(
      const AValores: TArray<TValorConjuntoSku>);
    procedure PonerMarcaDimension(AMarca: Integer);
    function TodosMarcados: Boolean;
    function HayDimensionSeleccionada: Boolean;
    function HayValorSeleccionado: Boolean;
    procedure MostrarDimensionActual;
    procedure EnfocarDetalle;
    procedure GrabarEdicionesPendientes;
    procedure RecargarMaestro;
    procedure CambiarOrdenDimensionActual;
    procedure CambiarOrdenValorActual;
    function ConfirmarCambioOrdenGlobal: Boolean;
    procedure GuardarOrdenValorActual(AOrden: Integer);
    procedure AnadirValorDimensionActual;
    function EsValorNuevoValido(const AValores: array of string): Boolean;
    function PedirValorNuevo(var ASolicitud: TSolicitudValorSku): Boolean;
    function SituarEnValorListado(
      const ASolicitud: TSolicitudValorSku): Boolean;
    procedure MarcarValorActual(const ANombreAtributo: string);
    function TextoConfirmacionValor(
      const ASolicitud: TSolicitudValorSku;
      const APregunta: string): string;
    function ConfirmarDestinoValor(
      var ASolicitud: TSolicitudValorSku): Boolean;
    procedure CrearValorMarcado(const ASolicitud: TSolicitudValorSku);
    function RecogerDimensionesMarcadas: TArray<TDimensionSku>;
    function RecogerValoresMarcados(
      const AIdAtributo: string): TArray<TValorDimensionSku>;
    function ValidarDimensionesMarcadas(
      const ADimensiones: TArray<TDimensionSku>): Boolean;
    function ValidarLongitudCodigos(
      const APropuestos: TArray<TSkuPropuesto>): Boolean;
    function ConfirmarGeneracion(
      const ANuevos: TArray<TSkuPropuesto>;
      AYaExistentes: Integer): Boolean;
    function PrepararSkusNuevos(
      out ANuevos: TArray<TSkuPropuesto>): Boolean;
    procedure GenerarSkus(const ANuevos: TArray<TSkuPropuesto>);
    function GenerarSkusMarcados: Boolean;
  public
    function CloseQuery: Boolean; override;
    // Método para llamar a esta pantalla desde el formulario principal
    class function Ejecutar(
      AOwner: TComponent;
      const ACodigoArticulo, ATipoVariacion: string;
      const ARepositorio: IRepositorioGeneracionSkus
    ): TResultadoGenerarSkus;
  end;

implementation

{$R *.dfm}

uses
  inLibCodigosSinBarra, inLibMensajesVcl,
  inLibMsgArticulos, UniDataConfiguracionPantalla;

const
  // La confirmación enumera los SKU; a partir de aquí solo los cuenta.
  MAXIMO_SKUS_LISTADOS = 15;

class function TfrmMtoModalGenerarSKUS.Ejecutar(
  AOwner: TComponent;
  const ACodigoArticulo, ATipoVariacion: string;
  const ARepositorio: IRepositorioGeneracionSkus): TResultadoGenerarSkus;
var
  oFormulario: TfrmMtoModalGenerarSKUS;
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'generación de SKU');
  oFormulario := TfrmMtoModalGenerarSKUS.Create(AOwner);
  try
    oFormulario.FRepositorio := ARepositorio;
    oFormulario.FCodigoArticulo := ACodigoArticulo;
    oFormulario.FTipoVariacion := ATipoVariacion;
    oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmMtoModalGenerarSKUS.FormShow(Sender: TObject);
begin
  inherited;
  ValidarDependenciaConfiguracion(FRepositorio, 'generación de SKU');
  FDatos := FRepositorio.PrepararDatos(FCodigoArticulo, FTipoVariacion);
  FMaestro := FDatos.Maestro;
  FDetalle := FDatos.Detalle;
  dsMaestro.DataSet := FMaestro;
  dsDetalle.DataSet := FDetalle;
  tvMaestro.OnDblClick := tvMaestroDblClick;
  ConfigurarNavegador;
  MostrarDimensionActual;
  // Se empieza eligiendo la dimensión cuyos valores se quieren marcar.
  if cxGrid1.CanFocus then
    cxGrid1.SetFocus;
end;

// ===========================================================================
//   Dimensión activa y sus valores
// ===========================================================================

function TfrmMtoModalGenerarSKUS.HayDimensionSeleccionada: Boolean;
begin
  Result := Assigned(FMaestro) and FMaestro.Active and
    (not FMaestro.IsEmpty);
end;

function TfrmMtoModalGenerarSKUS.HayValorSeleccionado: Boolean;
begin
  Result := Assigned(FDetalle) and FDetalle.Active and
    (not FDetalle.IsEmpty) and
    (FDetalle.FieldByName('ID_AC').AsInteger > 0);
end;

procedure TfrmMtoModalGenerarSKUS.dsMaestroDataChange(Sender: TObject;
  Field: TField);
begin
  if Field = nil then
    MostrarDimensionActual;
end;

procedure TfrmMtoModalGenerarSKUS.MostrarDimensionActual;
begin
  // La cabecera de abajo dice de qué dimensión son los valores listados.
  if HayDimensionSeleccionada then
  begin
    tvDetalleNOMBRE_AC.Caption :=
      FMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
    CargarConjuntosDimension;
  end;
end;

// ===========================================================================
//   Navegador del detalle: "+" añade un valor y "-" lo quita de la lista
// ===========================================================================

procedure TfrmMtoModalGenerarSKUS.ConfigurarNavegador;
begin
  tvDetalle.Navigator.Buttons.PriorPage.Visible := False;
  tvDetalle.Navigator.Buttons.NextPage.Visible := False;
  tvDetalle.Navigator.Buttons.Append.Visible := False;
  tvDetalle.Navigator.Buttons.Edit.Visible := False;
  tvDetalle.Navigator.Buttons.Post.Visible := False;
  tvDetalle.Navigator.Buttons.Cancel.Visible := False;
  tvDetalle.Navigator.Buttons.Refresh.Visible := False;
  tvDetalle.Navigator.Buttons.SaveBookmark.Visible := False;
  tvDetalle.Navigator.Buttons.GotoBookmark.Visible := False;
  tvDetalle.Navigator.Buttons.Filter.Visible := False;
  tvDetalle.Navigator.Buttons.ConfirmDelete := False;
  tvDetalle.Navigator.Buttons.OnButtonClick := tvDetalleNavigatorButtonClick;
  FDetalle.BeforeInsert := DetalleBeforeInsert;
end;

procedure TfrmMtoModalGenerarSKUS.tvDetalleNavigatorButtonClick(
  Sender: TObject; AButtonIndex: Integer; var ADone: Boolean);
begin
  case AButtonIndex of
    NBDI_INSERT, NBDI_APPEND:
      begin
        ADone := True;
        btnAddValueClick(Sender);
      end;
    NBDI_DELETE:
      begin
        // Solo se quita de esta lista: el valor sigue existiendo y no se
        // genera su SKU. La lista vive en memoria y nunca se graba.
        ADone := True;
        GrabarEdicionesPendientes;
        if not FDetalle.IsEmpty then
          FDetalle.Delete;
      end;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.DetalleBeforeInsert(DataSet: TDataSet);
begin
  if not FAnadiendoFila then
    Abort;
end;

// ===========================================================================
//   Conjunto de la dimensión activa (tallaje, paleta...)
// ===========================================================================

procedure TfrmMtoModalGenerarSKUS.CargarConjuntosDimension;
var
  oActual: TConjuntoAtributoSku;
  oConjunto: TConjuntoAtributoSku;
  sIdAtributo: string;
  iIndice: Integer;
begin
  sIdAtributo := FMaestro.FieldByName('ID_ATB_VA').AsString;
  oActual := FRepositorio.ObtenerConjuntoAtributo(
    FCodigoArticulo, sIdAtributo);
  FCargandoConjuntos := True;
  try
    cbConjunto.Properties.Items.Clear;
    cbConjunto.Properties.Items.AddObject(SOpcionSinConjuntoSku, TObject(0));
    for oConjunto in FRepositorio.ListarConjuntosAtributo(
      sIdAtributo, FTipoVariacion) do
      cbConjunto.Properties.Items.AddObject(
        oConjunto.Nombre, TObject(NativeInt(oConjunto.Id)));
    cbConjunto.ItemIndex := 0;
    for iIndice := 1 to cbConjunto.Properties.Items.Count - 1 do
      if Integer(NativeInt(cbConjunto.Properties.Items.Objects[iIndice])) =
         oActual.Id then
        cbConjunto.ItemIndex := iIndice;
    // Un conjunto ya asignado pero desactivado se sigue enseñando.
    if (oActual.Id > 0) and (cbConjunto.ItemIndex = 0) then
      cbConjunto.ItemIndex := cbConjunto.Properties.Items.AddObject(
        oActual.Nombre, TObject(NativeInt(oActual.Id)));
    FIdConjuntoActual := oActual.Id;
  finally
    FCargandoConjuntos := False;
  end;
  // Solo al abrir cada dimensión: al volver se respetan los desmarcados.
  if IndexStr(sIdAtributo, FDimensionesInicializadas) < 0 then
  begin
    FDimensionesInicializadas := FDimensionesInicializadas + [sIdAtributo];
    if oActual.Id > 0 then
      MarcarValoresConjunto(
        FRepositorio.ListarValoresConjunto(oActual.Id));
  end;
end;

procedure TfrmMtoModalGenerarSKUS.cbConjuntoPropertiesChange(
  Sender: TObject);
var
  iIdConjunto: Integer;
begin
  if (not FCargandoConjuntos) and HayDimensionSeleccionada and
     (cbConjunto.ItemIndex >= 0) then
  begin
    iIdConjunto := Integer(NativeInt(
      cbConjunto.Properties.Items.Objects[cbConjunto.ItemIndex]));
    if iIdConjunto <> FIdConjuntoActual then
    begin
      GrabarEdicionesPendientes;
      // Queda asignado al artículo, como si se eligiera en su ficha.
      FRepositorio.AsignarConjuntoArticulo(
        FCodigoArticulo,
        FMaestro.FieldByName('ID_ATB_VA').AsString,
        iIdConjunto);
      FIdConjuntoActual := iIdConjunto;
      if iIdConjunto > 0 then
        MarcarValoresConjunto(
          FRepositorio.ListarValoresConjunto(iIdConjunto));
    end;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.MarcarValoresConjunto(
  const AValores: TArray<TValorConjuntoSku>);
var
  oValor: TValorConjuntoSku;
  sIdAtributo: string;
begin
  // Quedan marcados exactamente los valores del conjunto elegido: los que
  // faltan en la lista se añaden y los demás de la dimensión se desmarcan.
  sIdAtributo := FMaestro.FieldByName('ID_ATB_VA').AsString;
  tvDetalle.BeginUpdate;
  try
    PonerMarcaDimension(0);
    for oValor in AValores do
    begin
      if FDetalle.Locate('ID_AC', oValor.Id, []) or
         FDetalle.Locate('NOMBRE_AC', oValor.Nombre, [loCaseInsensitive]) then
      begin
        FDetalle.Edit;
        FDetalle.FieldByName('ASIGNADO').AsInteger := 1;
        FDetalle.Post;
      end
      else
      begin
        FAnadiendoFila := True;
        try
          FDetalle.Append;
          FDetalle.FieldByName('ID_ATB_VA').AsString := sIdAtributo;
          FDetalle.FieldByName('ID_AC').AsInteger := oValor.Id;
          FDetalle.FieldByName('NOMBRE_AC').AsString := oValor.Nombre;
          FDetalle.FieldByName('ORDEN_AV').AsInteger := oValor.Orden;
          FDetalle.FieldByName('ASIGNADO').AsInteger := 1;
          FDetalle.Post;
        finally
          FAnadiendoFila := False;
        end;
      end;
    end;
    FDetalle.First;
  finally
    tvDetalle.EndUpdate;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.PonerMarcaDimension(AMarca: Integer);
begin
  FDetalle.First;
  while not FDetalle.Eof do
  begin
    if FDetalle.FieldByName('ASIGNADO').AsInteger <> AMarca then
    begin
      FDetalle.Edit;
      FDetalle.FieldByName('ASIGNADO').AsInteger := AMarca;
      FDetalle.Post;
    end;
    FDetalle.Next;
  end;
end;

function TfrmMtoModalGenerarSKUS.TodosMarcados: Boolean;
begin
  Result := True;
  FDetalle.First;
  while Result and not FDetalle.Eof do
  begin
    Result := FDetalle.FieldByName('ASIGNADO').AsInteger = 1;
    FDetalle.Next;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.btnMarcarTodasClick(Sender: TObject);
begin
  if HayDimensionSeleccionada then
  begin
    GrabarEdicionesPendientes;
    tvDetalle.BeginUpdate;
    try
      // Con todas marcadas, el mismo botón las desmarca.
      if TodosMarcados then
        PonerMarcaDimension(0)
      else
        PonerMarcaDimension(1);
      FDetalle.First;
    finally
      tvDetalle.EndUpdate;
    end;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.EnfocarDetalle;
begin
  if cxGrid2.CanFocus then
    cxGrid2.SetFocus;
  tvDetalleASIGNADO.Focused := True;
end;

procedure TfrmMtoModalGenerarSKUS.GrabarEdicionesPendientes;
begin
  // Cerrar el editor vuelca la última casilla antes de mover el detalle.
  tvDetalle.Controller.EditingController.HideEdit(True);
  if tvDetalle.DataController.IsEditing then
    tvDetalle.DataController.Post;
  if FDetalle.State in [dsEdit, dsInsert] then
    FDetalle.Post;
end;

// ===========================================================================
//   Orden de dimensiones y de valores (doble clic)
// ===========================================================================

procedure TfrmMtoModalGenerarSKUS.RecargarMaestro;
var
  sIdAtributo: string;
begin
  sIdAtributo := FMaestro.FieldByName('ID_ATB_VA').AsString;
  FDatos.RecargarMaestro;
  // Se conserva la dimensión que el usuario estaba ordenando.
  FMaestro.Locate('ID_ATB_VA', sIdAtributo, []);
end;

procedure TfrmMtoModalGenerarSKUS.tvMaestroDblClick(Sender: TObject);
begin
  if HayDimensionSeleccionada then
    CambiarOrdenDimensionActual;
end;

procedure TfrmMtoModalGenerarSKUS.CambiarOrdenDimensionActual;
var
  sOrden: string;
  iOrden: Integer;
begin
  sOrden := FMaestro.FieldByName('ORDEN_ACA').AsString;
  if InputQuery_fza(
       STituloCambiarOrdenAtributoSku,
       Format(SEtiquetaOrdenDeSku,
         [FMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString]),
       sOrden) then
  begin
    iOrden := StrToIntDef(Trim(sOrden), -1);
    if iOrden <= 0 then
      ShowMessage_fza(SErrorOrdenAtributoSkuNoValido)
    else
    begin
      FRepositorio.GuardarOrdenAtributo(
        FCodigoArticulo,
        FMaestro.FieldByName('ID_ATB_VA').AsString,
        iOrden);
      RecargarMaestro;
    end;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.tvDetalleCellDblClick(
  Sender: TcxCustomGridTableView; ACellViewInfo: TcxGridTableDataCellViewInfo;
  AButton: TMouseButton; AShift: TShiftState; var AHandled: Boolean);
begin
  // Dos clics seguidos sobre la casilla solo la marcan y la desmarcan.
  if (ACellViewInfo.Item <> tvDetalleASIGNADO) and
     HayValorSeleccionado then
    CambiarOrdenValorActual;
end;

procedure TfrmMtoModalGenerarSKUS.CambiarOrdenValorActual;
var
  sOrden: string;
  iOrden: Integer;
begin
  sOrden := FDetalle.FieldByName('ORDEN_AV').AsString;
  if InputQuery_fza(
       STituloCambiarOrdenValorSku,
       Format(SEtiquetaOrdenDeSku,
         [FDetalle.FieldByName('NOMBRE_AC').AsString]),
       sOrden) then
  begin
    iOrden := StrToIntDef(Trim(sOrden), -1);
    if iOrden < 0 then
      ShowMessage_fza(SErrorOrdenValorSkuNoValido)
    else if ConfirmarCambioOrdenGlobal then
      GuardarOrdenValorActual(iOrden);
  end;
end;

function TfrmMtoModalGenerarSKUS.ConfirmarCambioOrdenGlobal: Boolean;
var
  sConjunto: string;
begin
  sConjunto := Trim(FRepositorio.ObtenerConjuntoAtributo(
    FCodigoArticulo,
    FDetalle.FieldByName('ID_ATB_VA').AsString).Nombre);
  Result := (sConjunto = '') or
    (MessageDlg_fza(
       Format(SPreguntaCambiarOrdenValorSkuGlobal, [sConjunto]),
       mtWarning,
       [mbYes, mbNo],
       0) = mrYes);
end;

procedure TfrmMtoModalGenerarSKUS.GuardarOrdenValorActual(AOrden: Integer);
begin
  FRepositorio.GuardarOrdenValor(
    FDetalle.FieldByName('ID_AC').AsInteger,
    AOrden);
  FDetalle.Edit;
  FDetalle.FieldByName('ORDEN_AV').AsInteger := AOrden;
  FDetalle.Post;
end;

// ===========================================================================
//   Añadir un valor a la dimensión activa (F3)
// ===========================================================================

procedure TfrmMtoModalGenerarSKUS.btnAddValueClick(Sender: TObject);
begin
  //F3 -> añadir un valor a la dimensión seleccionada arriba
  if HayDimensionSeleccionada then
    AnadirValorDimensionActual
  else
    ShowMessage_fza(SErrorDimensionSkuNoSeleccionada);
end;

procedure TfrmMtoModalGenerarSKUS.AnadirValorDimensionActual;
var
  oSolicitud: TSolicitudValorSku;
begin
  GrabarEdicionesPendientes;
  oSolicitud := Default(TSolicitudValorSku);
  oSolicitud.IdAtributo := FMaestro.FieldByName('ID_ATB_VA').AsString;
  oSolicitud.NombreAtributo :=
    FMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
  if PedirValorNuevo(oSolicitud) then
  begin
    oSolicitud.Existente := FRepositorio.BuscarValor(
      oSolicitud.IdAtributo,
      oSolicitud.Nombre);
    // Si ya está en la lista basta con marcarlo: no se crea ni se duplica.
    if SituarEnValorListado(oSolicitud) then
      MarcarValorActual(oSolicitud.NombreAtributo)
    else if ConfirmarDestinoValor(oSolicitud) then
      CrearValorMarcado(oSolicitud);
  end;
end;

function TfrmMtoModalGenerarSKUS.EsValorNuevoValido(
  const AValores: array of string): Boolean;
begin
  // Se valida sin cerrar el diálogo: lo tecleado no se pierde.
  Result := (SinBarraSku(AValores[0]) <> '') and
    (StrToIntDef(Trim(AValores[1]), -1) >= 0);
  if not Result then
    ShowMessage_fza(SErrorValorNuevoSkuNoValido);
end;

function TfrmMtoModalGenerarSKUS.PedirValorNuevo(
  var ASolicitud: TSolicitudValorSku): Boolean;
var
  aValores: TArray<string>;
begin
  ASolicitud.Conjunto := FRepositorio.ObtenerConjuntoAtributo(
    FCodigoArticulo,
    ASolicitud.IdAtributo);
  // Nombre y orden en un solo diálogo y con preguntas cortas: InputQuery
  // ensancha la ventana hasta casi el doble de su pregunta más larga.
  aValores := ['', IntToStr(FRepositorio.CalcularSiguienteOrdenValor(
    ASolicitud.IdAtributo,
    ASolicitud.Conjunto.Id))];
  Result := InputQuery_fza(
    Format(STituloAnadirValorDimensionSku, [ASolicitud.NombreAtributo]),
    [SEtiquetaNombreValorSku, SEtiquetaOrdenValorSku],
    aValores,
    EsValorNuevoValido);
  if Result then
  begin
    // El nombre formará parte del código del SKU: sin barras, como se guarda.
    ASolicitud.Nombre := SinBarraSku(aValores[0]);
    ASolicitud.Orden := StrToInt(Trim(aValores[1]));
  end;
end;

function TfrmMtoModalGenerarSKUS.SituarEnValorListado(
  const ASolicitud: TSolicitudValorSku): Boolean;
begin
  Result := FDetalle.Locate(
    'NOMBRE_AC', ASolicitud.Nombre, [loCaseInsensitive]);
  // La BBDD no distingue acentos: "marron" es el "MARRÓN" ya listado.
  if (not Result) and (ASolicitud.Existente.Id > 0) then
    Result :=
      FDetalle.Locate(
        'NOMBRE_AC', ASolicitud.Existente.Nombre, [loCaseInsensitive]) or
      FDetalle.Locate('ID_AC', ASolicitud.Existente.Id, []);
end;

procedure TfrmMtoModalGenerarSKUS.MarcarValorActual(
  const ANombreAtributo: string);
begin
  FDetalle.Edit;
  FDetalle.FieldByName('ASIGNADO').AsInteger := 1;
  FDetalle.Post;
  EnfocarDetalle;
  ShowMessage_fza(Format(SInfoValorSkuYaListado,
    [FDetalle.FieldByName('NOMBRE_AC').AsString, ANombreAtributo]));
end;

function TfrmMtoModalGenerarSKUS.TextoConfirmacionValor(
  const ASolicitud: TSolicitudValorSku;
  const APregunta: string): string;
begin
  Result := APregunta;
  // Un valor que ya existe conserva su orden global; solo el nuevo estrena
  // el indicado, y eso afecta a los demás artículos.
  if ASolicitud.Existente.Id = 0 then
    Result := Format(SNotaOrdenGlobalValorSku, [ASolicitud.Orden]) +
      sLineBreak + sLineBreak + Result;
end;

function TfrmMtoModalGenerarSKUS.ConfirmarDestinoValor(
  var ASolicitud: TSolicitudValorSku): Boolean;
var
  iRespuesta: Integer;
begin
  if ASolicitud.Conjunto.Id > 0 then
  begin
    iRespuesta := MessageDlg_fza(
      TextoConfirmacionValor(
        ASolicitud,
        Format(SPreguntaGuardarValorSkuGlobal,
          [ASolicitud.Nombre, ASolicitud.Conjunto.Nombre])),
      mtConfirmation,
      [mbYes, mbNo, mbCancel],
      0);
    ASolicitud.GuardarEnConjunto := iRespuesta = mrYes;
    Result := (iRespuesta = mrYes) or (iRespuesta = mrNo);
  end
  else
    Result := MessageDlg_fza(
      TextoConfirmacionValor(
        ASolicitud,
        Format(SPreguntaUsarValorSkuTemporal, [ASolicitud.Nombre])),
      mtConfirmation,
      [mbYes, mbNo],
      0) = mrYes;
end;

procedure TfrmMtoModalGenerarSKUS.CrearValorMarcado(
  const ASolicitud: TSolicitudValorSku);
var
  oValor: TValorAtributoSku;
begin
  oValor := FRepositorio.AsegurarValor(
    ASolicitud.IdAtributo,
    ASolicitud.Nombre,
    ASolicitud.Orden);
  if ASolicitud.GuardarEnConjunto then
    FRepositorio.GuardarValorEnConjunto(
      ASolicitud.Conjunto.Id,
      oValor.Id,
      ASolicitud.Orden);
  // La fila nace marcada y con el foco: es el valor que se va a combinar.
  FAnadiendoFila := True;
  try
    FDetalle.Append;
    FDetalle.FieldByName('ID_ATB_VA').AsString := ASolicitud.IdAtributo;
    FDetalle.FieldByName('ID_AC').AsInteger := oValor.Id;
    FDetalle.FieldByName('NOMBRE_AC').AsString := oValor.Nombre;
    FDetalle.FieldByName('ORDEN_AV').AsInteger := ASolicitud.Orden;
    FDetalle.FieldByName('ASIGNADO').AsInteger := 1;
    FDetalle.Post;
  finally
    FAnadiendoFila := False;
  end;
  EnfocarDetalle;
end;

// ===========================================================================
//   Generación de los SKU marcados (F12)
// ===========================================================================

function TfrmMtoModalGenerarSKUS.CloseQuery: Boolean;
begin
  // sFicha lo asigna el ancestro: 'S' tras Aceptar o F12 y 'N' al cancelar.
  // F12 entra por Action1 del ancestro, que llama a su propio
  // btnAceptarClick y no a uno redeclarado aquí: generando en el cierre,
  // el botón y la tecla hacen lo mismo.
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    // Si no se llega a generar, el diálogo sigue abierto y el próximo
    // cierre (ESC o el aspa) tiene que ser un cancelar.
    sFicha := 'N';
    Result := GenerarSkusMarcados;
  end;
end;

function TfrmMtoModalGenerarSKUS.GenerarSkusMarcados: Boolean;
var
  oNuevos: TArray<TSkuPropuesto>;
begin
  GrabarEdicionesPendientes;
  Result := PrepararSkusNuevos(oNuevos);
  if Result then
    GenerarSkus(oNuevos);
end;

function TfrmMtoModalGenerarSKUS.RecogerValoresMarcados(
  const AIdAtributo: string): TArray<TValorDimensionSku>;
var
  oValor: TValorDimensionSku;
begin
  Result := nil;
  FDetalle.First;
  while not FDetalle.Eof do
  begin
    // El enlace con el maestro ya filtra el detalle; comparar la dimensión
    // impide mezclar colores y tallas si ese enlace volviera a perderse.
    if (FDetalle.FieldByName('ASIGNADO').AsInteger = 1) and
       (FDetalle.FieldByName('ID_ATB_VA').AsString = AIdAtributo) then
    begin
      oValor.IdValor := FDetalle.FieldByName('ID_AC').AsInteger;
      oValor.Nombre := FDetalle.FieldByName('NOMBRE_AC').AsString;
      Result := Result + [oValor];
    end;
    FDetalle.Next;
  end;
end;

function TfrmMtoModalGenerarSKUS.RecogerDimensionesMarcadas:
  TArray<TDimensionSku>;
var
  oMarca: TBookmark;
  oDimension: TDimensionSku;
  bDetalleHabilitado: Boolean;
begin
  Result := nil;
  GrabarEdicionesPendientes;
  // Se bloquean las rejillas y no los datasets: DisableControls en el
  // maestro dejaría de avisar al detalle y este no cambiaría de dimensión.
  // BeginUpdate solo aplaza el repintado. La rejilla no debe recibir
  // cambios de dimensión con índices de edición de la dimensión anterior.
  // El maestro-detalle usa otro TDataSource y sigue filtrando los valores.
  bDetalleHabilitado := dsDetalle.Enabled;
  oMarca := FMaestro.GetBookmark;
  dsDetalle.Enabled := False;
  tvMaestro.BeginUpdate;
  tvDetalle.BeginUpdate;
  try
    FMaestro.First;
    while not FMaestro.Eof do
    begin
      oDimension.IdAtributo := FMaestro.FieldByName('ID_ATB_VA').AsString;
      oDimension.Nombre :=
        FMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
      oDimension.Valores := RecogerValoresMarcados(oDimension.IdAtributo);
      Result := Result + [oDimension];
      FMaestro.Next;
    end;
  finally
    try
      if FMaestro.BookmarkValid(oMarca) then
        FMaestro.GotoBookmark(oMarca);
    finally
      FMaestro.FreeBookmark(oMarca);
      tvDetalle.EndUpdate;
      tvMaestro.EndUpdate;
      dsDetalle.Enabled := bDetalleHabilitado;
    end;
  end;
end;

function TfrmMtoModalGenerarSKUS.ValidarDimensionesMarcadas(
  const ADimensiones: TArray<TDimensionSku>): Boolean;
var
  oSinValores: TArray<string>;
begin
  oSinValores := DimensionesSkuSinValores(ADimensiones);
  Result := False;
  if Length(ADimensiones) = 0 then
    ShowMessage_fza(SErrorDimensionesSkuNoDefinidas)
  else if Length(oSinValores) = Length(ADimensiones) then
    ShowMessage_fza(SErrorValoresSkuNoSeleccionados)
  else if Length(oSinValores) > 0 then
    ShowMessage_fza(Format(SErrorValoresDimensionesSkuIncompletos,
      [string.Join(', ', oSinValores)]))
  else
    Result := True;
end;

function TfrmMtoModalGenerarSKUS.ValidarLongitudCodigos(
  const APropuestos: TArray<TSkuPropuesto>): Boolean;
var
  oLargos: TArray<string>;
begin
  oLargos := CodigosSkuDemasiadoLargos(APropuestos);
  Result := Length(oLargos) = 0;
  if not Result then
    ShowMessage_fza(Format(SErrorCodigosSkuDemasiadoLargos,
      [LONGITUD_MAXIMA_CODIGO_SKU,
       ResumirCodigosSku(
         oLargos, MAXIMO_SKUS_LISTADOS, STextoRestoCodigosSku)]));
end;

function TfrmMtoModalGenerarSKUS.ConfirmarGeneracion(
  const ANuevos: TArray<TSkuPropuesto>;
  AYaExistentes: Integer): Boolean;
begin
  Result := False;
  if Length(ANuevos) = 0 then
    ShowMessage_fza(SInfoSkusMarcadosYaExisten)
  else
    Result := MessageDlg_fza(
      Format(SPreguntaGenerarSkus,
        [Length(ANuevos),
         ResumirCodigosSku(
           CodigosDeSkus(ANuevos),
           MAXIMO_SKUS_LISTADOS,
           STextoRestoCodigosSku),
         AYaExistentes]),
      mtConfirmation,
      [mbYes, mbNo],
      0) = mrYes;
end;

function TfrmMtoModalGenerarSKUS.PrepararSkusNuevos(
  out ANuevos: TArray<TSkuPropuesto>): Boolean;
var
  oDimensiones: TArray<TDimensionSku>;
  oTodos: TArray<TSkuPropuesto>;
begin
  ANuevos := nil;
  oTodos := nil;
  oDimensiones := RecogerDimensionesMarcadas;
  Result := ValidarDimensionesMarcadas(oDimensiones);
  if Result then
  begin
    oTodos := CombinarSkus(FCodigoArticulo, oDimensiones);
    Result := ValidarLongitudCodigos(oTodos);
  end;
  if Result then
  begin
    ANuevos := FiltrarSkusNuevos(
      oTodos,
      FRepositorio.ObtenerCodigosSku(FCodigoArticulo));
    Result := ConfirmarGeneracion(
      ANuevos,
      Length(oTodos) - Length(ANuevos));
  end;
end;

procedure TfrmMtoModalGenerarSKUS.GenerarSkus(
  const ANuevos: TArray<TSkuPropuesto>);
var
  oSku: TSkuPropuesto;
  iCreados: Integer;
begin
  iCreados := 0;
  for oSku in ANuevos do
  begin
    if FRepositorio.GuardarSku(
         oSku.Codigo,
         FCodigoArticulo,
         FTipoVariacion,
         oSku.IdsValores) then
    begin
      // Se acumulan: un intento anterior interrumpido también creó SKU.
      FResultado.SkusCreados := FResultado.SkusCreados + [oSku.Codigo];
      Inc(iCreados);
    end;
  end;
  FResultado.Aceptado := True;
  // Solo ocurre si otro puesto ha creado alguno mientras se confirmaba.
  if iCreados < Length(ANuevos) then
    ShowMessage_fza(Format(SAvisoSkusCreadosParcialmente,
      [iCreados, Length(ANuevos)]));
end;

end.
