{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasPresentadorLineasVcl                             }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presenta el detalle de líneas de factura: SKU, precios y recálculo.       }
{******************************************************************************}
unit inMtoFacturasPresentadorLineasVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Uni,
  cxCheckBox, cxDBEdit, cxEdit, cxGridCustomTableView,
  cxGridDBTableView, cxLabel, cxPC,
  UniDataFacturas,
  inLibArticulosResolverIntf,
  inLibFacturasLecturasIntf,
  inLibFacturasLineasEdicion,
  inLibFacturasPresentadorDetalle,
  inLibGenBusq,
  inLibGridPivoteVenta,
  inLibLogIntf,
  inLibParametrosIntf;

type
  TConsultaEstadoLineasFactura = reference to function: Boolean;
  TFabricaResolverLineasFactura = reference to function: IArticulosResolver;
  // Columnas del detalle que gobierna la lógica de negocio. Se reasignan
  // cada vez que el contrato de entrada reconstruye la presentación.
  TColumnasDetalleFacturaVcl = record
    Articulo: TcxGridDBColumn;
    Sku: TcxGridDBColumn;
    CodigoFamilia: TcxGridDBColumn;
    NombreFamilia: TcxGridDBColumn;
    EsProveedorPrincipal: TcxGridDBColumn;
    CodigoProveedor: TcxGridDBColumn;
    RazonSocialProveedor: TcxGridDBColumn;
    PrecioUltimaCompra: TcxGridDBColumn;
    PrecioSinIva: TcxGridDBColumn;
    PrecioConIva: TcxGridDBColumn;
    TotalSinIva: TcxGridDBColumn;
    TotalConIva: TcxGridDBColumn;
  end;
  TContextoLineasFacturaVcl = record
    Vista: TcxGridDBTableView;
    Cabecera: TDataSource;
    DataModule: TdmFacturas;
    Conexion: TUniConnection;
    Lecturas: IRepositorioLecturasFactura;
    RegistroLog: IRegistroLog;
    ParametrosApp: IParametrosAplicacion;
    BusquedaVisual: IBusquedaVisual;
    CrearResolver: TFabricaResolverLineasFactura;
    EtiquetaPrendas: TcxLabel;
    PestanaLineas: TcxTabSheet;
    // El formulario sigue siendo dueño del modo de entrada; el detalle
    // solo consulta su estado para decidir de quién es la columna SKU.
    ContratoActivo: TConsultaEstadoLineasFactura;
    Construyendo: TConsultaEstadoLineasFactura;
    DesactivarEnterAsTab: TNotifyEvent;
    RestaurarEnterAsTab: TNotifyEvent;
  end;
  TPresentadorLineasFacturaVcl = class
  private
    FContexto: TContextoLineasFacturaVcl;
    FColumnas: TColumnasDetalleFacturaVcl;
    FDetalle: TPresentadorDetalleFactura;
    FEditor: TEditorLineasFactura;
    FEnterSkuActivo: Boolean;
    FEnterSkuAnterior: Boolean;
    FActualizandoPrendas: Boolean;
    // OnEditing propio del modo de entrada (SKU, desglose, tallas), al
    // que se antepone el filtro de subsanación.
    FEdicionModo: TcxGridEditingEvent;
    function ContratoActivo: Boolean;
    function Construyendo: Boolean;
    function Situacion: TSituacionDetalleFactura;
    procedure EnfocarEditorSku;
  public
    constructor Create(const AContexto: TContextoLineasFacturaVcl);
    destructor Destroy; override;
    // Estado del detalle
    procedure ActualizarColumnas(
      const AColumnas: TColumnasDetalleFacturaVcl);
    procedure ActualizarEditor(AEditor: TEditorLineasFactura);
    function MostrarSkuArticulo(const ACodigoArticulo: string): Boolean;
    procedure ReaplicarVisibilidad;
    procedure SincronizarColumnaSku;
    procedure OcultarColumnasCatalogo;
    procedure MostrarColumnaSku(AVisible: Boolean);
    function SkuVisible: Boolean;
    function TotalLineas: Integer;
    function ArticuloLinea(AIndice: Integer): string;
    procedure ActualizarTotalPrendas;
    // Edición de líneas
    procedure ActivarSkuLinea(
      const ACodigoArticulo: string; AEnfocar: Boolean);
    procedure AplicarArticulo(const AEntrada: string);
    // Lectura de pistola en la presentacion clasica (sin modo de entrada):
    // True si el editor aplico la entrada a la linea actual.
    function AplicarEntradaLectura(const AEntrada: string): Boolean;
    procedure AplicarLineaNoCatalogo(const ACodigoArticulo: string);
    procedure AplicarArticuloDesdeEditor(Sender: TObject);
    procedure BuscarArticuloLinea;
    procedure ConsolidarSku(Sender: TObject);
    function PrecioSku(
      const ACodigoArticulo, ACodigoSku: string): Double;
    procedure Recalcular(Sender: TObject);
    procedure AplicarEdicionPrecios(Sender: TObject);
    function AsegurarCabeceraPersistida: Boolean;
    procedure AsegurarPrimeraLinea;
    // Manejadores de eventos del grid
    procedure DesactivarEnterSku(Sender: TObject);
    procedure RestaurarEnterSku(Sender: TObject);
    procedure SalirEditorSku(Sender: TObject);
    procedure TextoSkuLinea(
      Sender: TcxCustomGridTableItem;
      ARecordIndex: Integer;
      var AText: string);
    procedure PermitirEdicion(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem;
      var AAllow: Boolean);
    // Modos de entrada no clásicos: conserva su OnEditing y le aplica
    // la misma regla de subsanación que PermitirEdicion.
    procedure EnvolverEdicionModo(AVista: TcxCustomGridTableView);
    procedure PermitirEdicionModo(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem;
      var AAllow: Boolean);
    procedure IniciarEdicion(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem;
      AEdit: TcxCustomEdit);
    procedure TeclaEnEdicion(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem;
      AEdit: TcxCustomEdit;
      var Key: Word;
      Shift: TShiftState);
    procedure PrepararPopupSku(Sender: TObject);
    procedure CerrarPopupSku(Sender: TObject);
    procedure CambioEnLineas(Sender: TObject; Field: TField);
    // Contrato de entrada ColumnSKUcxGrid
    procedure ModoEntradaResuelto(
      const ACodigoArticulo, ASku, ADescripcion: string;
      ACompleto: Boolean);
    procedure PivoteCrearLineaSku(const ACodigoSku: string);
    procedure PivoteBandaCambiada(ABanda: TBandaPivoteVenta);
  end;

implementation

uses
  inLibMensajesVcl,
  System.Variants, Vcl.Dialogs, cxDropDownEdit, cxTextEdit,
  inLibDevExp,
  inLibFacturas,
  inLibFacturasSubsanacionReglas,
  inLibMsgFacturas,
  inLibPresentacionDocumento,
  inLibVerifactu;

resourcestring
  STituloBuscarArticulosLineasBorradoresFactura =
    'Búsqueda de Artículos en Lineas de Borradores';

type
  // Adaptadores de puerto: el presentador núcleo solo ve estas dos
  // interfaces estrechas, nunca la rejilla ni el formulario.
  TColumnasDetalleFacturaAdaptador = class(TInterfacedObject,
    IColumnasDetalleFactura)
  private
    FPresentador: TPresentadorLineasFacturaVcl;
  public
    constructor Create(APresentador: TPresentadorLineasFacturaVcl);
    procedure OcultarColumnasCatalogo;
    procedure MostrarColumnaSku(AVisible: Boolean);
    function SkuVisible: Boolean;
    function TotalLineas: Integer;
    function ArticuloLinea(AIndice: Integer): string;
  end;
  TReglaSkuFacturaAdaptador = class(TInterfacedObject, IReglaSkuFactura)
  private
    FPresentador: TPresentadorLineasFacturaVcl;
  public
    constructor Create(APresentador: TPresentadorLineasFacturaVcl);
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
  end;

constructor TColumnasDetalleFacturaAdaptador.Create(
  APresentador: TPresentadorLineasFacturaVcl);
begin
  inherited Create;
  FPresentador := APresentador;
end;

procedure TColumnasDetalleFacturaAdaptador.OcultarColumnasCatalogo;
begin
  FPresentador.OcultarColumnasCatalogo;
end;

procedure TColumnasDetalleFacturaAdaptador.MostrarColumnaSku(
  AVisible: Boolean);
begin
  FPresentador.MostrarColumnaSku(AVisible);
end;

function TColumnasDetalleFacturaAdaptador.SkuVisible: Boolean;
begin
  Result := FPresentador.SkuVisible;
end;

function TColumnasDetalleFacturaAdaptador.TotalLineas: Integer;
begin
  Result := FPresentador.TotalLineas;
end;

function TColumnasDetalleFacturaAdaptador.ArticuloLinea(
  AIndice: Integer): string;
begin
  Result := FPresentador.ArticuloLinea(AIndice);
end;

constructor TReglaSkuFacturaAdaptador.Create(
  APresentador: TPresentadorLineasFacturaVcl);
begin
  inherited Create;
  FPresentador := APresentador;
end;

function TReglaSkuFacturaAdaptador.DebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FPresentador.MostrarSkuArticulo(ACodigoArticulo);
end;

constructor TPresentadorLineasFacturaVcl.Create(
  const AContexto: TContextoLineasFacturaVcl);
begin
  inherited Create;
  FContexto := AContexto;
  FColumnas := Default(TColumnasDetalleFacturaVcl);
  FDetalle := TPresentadorDetalleFactura.Create(
    TColumnasDetalleFacturaAdaptador.Create(Self),
    TReglaSkuFacturaAdaptador.Create(Self));
end;

destructor TPresentadorLineasFacturaVcl.Destroy;
begin
  FreeAndNil(FDetalle);
  inherited;
end;

function TPresentadorLineasFacturaVcl.ContratoActivo: Boolean;
begin
  Result := Assigned(FContexto.ContratoActivo) and
    FContexto.ContratoActivo();
end;

function TPresentadorLineasFacturaVcl.Construyendo: Boolean;
begin
  Result := Assigned(FContexto.Construyendo) and
    FContexto.Construyendo();
end;

function TPresentadorLineasFacturaVcl.Situacion: TSituacionDetalleFactura;
begin
  Result := CrearSituacionDetalleFactura(
    ContratoActivo,
    Construyendo);
end;

procedure TPresentadorLineasFacturaVcl.ActualizarColumnas(
  const AColumnas: TColumnasDetalleFacturaVcl);
begin
  FColumnas := AColumnas;
end;

procedure TPresentadorLineasFacturaVcl.ActualizarEditor(
  AEditor: TEditorLineasFactura);
begin
  FEditor := AEditor;
end;

function TPresentadorLineasFacturaVcl.MostrarSkuArticulo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := Assigned(FEditor) and FEditor.DebeMostrarSku(ACodigoArticulo);
end;

procedure TPresentadorLineasFacturaVcl.OcultarColumnasCatalogo;
begin
  if Assigned(FColumnas.CodigoFamilia) then
    FColumnas.CodigoFamilia.Visible := False;
  if Assigned(FColumnas.NombreFamilia) then
    FColumnas.NombreFamilia.Visible := False;
  if Assigned(FColumnas.EsProveedorPrincipal) then
    FColumnas.EsProveedorPrincipal.Visible := False;
  if Assigned(FColumnas.CodigoProveedor) then
    FColumnas.CodigoProveedor.Visible := False;
  if Assigned(FColumnas.RazonSocialProveedor) then
    FColumnas.RazonSocialProveedor.Visible := False;
  if Assigned(FColumnas.PrecioUltimaCompra) then
    FColumnas.PrecioUltimaCompra.Visible := False;
end;

procedure TPresentadorLineasFacturaVcl.MostrarColumnaSku(
  AVisible: Boolean);
begin
  if Assigned(FColumnas.Sku) then
    FColumnas.Sku.Visible := AVisible;
end;

function TPresentadorLineasFacturaVcl.SkuVisible: Boolean;
begin
  Result := Assigned(FColumnas.Sku) and FColumnas.Sku.Visible;
end;

function TPresentadorLineasFacturaVcl.TotalLineas: Integer;
begin
  Result := 0;
  if Assigned(FContexto.Vista) then
    Result := FContexto.Vista.DataController.RecordCount;
end;

function TPresentadorLineasFacturaVcl.ArticuloLinea(
  AIndice: Integer): string;
begin
  Result := '';
  if Assigned(FContexto.Vista) and Assigned(FColumnas.Articulo) then
    Result := VarToStr(FContexto.Vista.DataController.GetValue(
      AIndice, FColumnas.Articulo.Index));
end;

procedure TPresentadorLineasFacturaVcl.ReaplicarVisibilidad;
begin
  FDetalle.Reaplicar(Situacion);
end;

procedure TPresentadorLineasFacturaVcl.SincronizarColumnaSku;
begin
  FDetalle.SincronizarColumnaSku(Situacion);
end;

procedure TPresentadorLineasFacturaVcl.ActualizarTotalPrendas;
begin
  // Total de prendas calculado en Delphi; no persiste en BBDD.
  if (not FActualizandoPrendas) and Assigned(FContexto.EtiquetaPrendas) then
  begin
    FActualizandoPrendas := True;
    try
      if Assigned(FContexto.DataModule) then
        FContexto.EtiquetaPrendas.Caption := TextoTotalPrendasDocumento(
          FContexto.DataModule.unqryTablaG,
          FContexto.DataModule.TotalPrendasFactura)
      else
        FContexto.EtiquetaPrendas.Caption := '0';
    finally
      FActualizandoPrendas := False;
    end;
  end;
end;

procedure TPresentadorLineasFacturaVcl.EnfocarEditorSku;
begin
  TThread.ForceQueue(nil,
    procedure
    var
      Edit: TcxCustomEdit;
    begin
      DesactivarEnterSku(FContexto.Vista);
      FContexto.Vista.Controller.FocusedColumn := FColumnas.Sku;
      FContexto.Vista.Controller.EditingController.ShowEdit;
      Edit := FContexto.Vista.Controller.EditingController.Edit;
      if Edit is TcxComboBox then
        (Edit as TcxComboBox).DroppedDown := True;
    end);
end;

procedure TPresentadorLineasFacturaVcl.ActivarSkuLinea(
  const ACodigoArticulo: string; AEnfocar: Boolean);
var
  oCampoSku: TField;
begin
  // Con un modo del contrato construido, la columna SKU es del modo (o no
  // existe): la eleccion de color/talla la resuelve su paleta.
  if (not ContratoActivo) and MostrarSkuArticulo(ACodigoArticulo) and
     Assigned(FColumnas.Sku) then
  begin
    FColumnas.Sku.Visible := True;
    if AEnfocar and Assigned(FContexto.DataModule) and
       FContexto.DataModule.unqryLinFac.Active and
       (FContexto.DataModule.unqryLinFac.State in [dsInsert, dsEdit]) then
    begin
      oCampoSku := FContexto.DataModule.unqryLinFac.FindField(
        'CODIGO_UNIDAD_FACLIN');
      if (oCampoSku <> nil) and (Trim(oCampoSku.AsString) = '') then
        EnfocarEditorSku;
    end;
  end;
end;

procedure TPresentadorLineasFacturaVcl.AplicarArticulo(
  const AEntrada: string);
begin
  if Assigned(FEditor) then
    FEditor.AplicarEntrada(AEntrada);
end;

function TPresentadorLineasFacturaVcl.AplicarEntradaLectura(
  const AEntrada: string): Boolean;
begin
  Result := Assigned(FEditor) and FEditor.AplicarEntrada(AEntrada).Aplicado;
end;

procedure TPresentadorLineasFacturaVcl.AplicarLineaNoCatalogo(
  const ACodigoArticulo: string);
begin
  if Assigned(FEditor) then
    FEditor.AplicarLineaNoCatalogo(ACodigoArticulo);
end;

procedure TPresentadorLineasFacturaVcl.AplicarArticuloDesdeEditor(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
  sEntrada: string;
  Resultado: TResultadoEdicionLineaFactura;
begin
  if Assigned(FEditor) and (Sender is TcxCustomEdit) then
  begin
    Edit := TcxCustomEdit(Sender);
    sEntrada := Trim(VarToStr(Edit.EditingValue));
    if sEntrada <> '' then
    begin
      Resultado := FEditor.AplicarDesdeEditor(sEntrada);
      if Resultado.Aplicado then
      begin
        ActivarSkuLinea(Resultado.CodigoArticulo, Resultado.RequiereSku);
        if Resultado.RecalcularDesdeEditor then
          Recalcular(Sender);
      end;
    end;
  end;
end;

procedure TPresentadorLineasFacturaVcl.BuscarArticuloLinea;
begin
  if SinVerifactuActivo(FContexto.ParametrosApp) or
     (FContexto.DataModule.unqryTablaG.FieldByName(
        fescon).AsString <> 'S') then
  begin
    FContexto.DataModule.unqryArtDataLinFac.ParamByName(
      'TARIFA').AsString := FContexto.DataModule.unqryTablaG.FindField(
        'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    FContexto.DataModule.unqryArtDataLinFac.ParamByName(
      'FECHA_FAC').AsDateTime := FContexto.DataModule.unqryTablaG.
        FindField('FECHA_FAC').AsDateTime;
    if FContexto.BusquedaVisual.EjecutarBusqueda(
         FContexto.Conexion,
         STituloBuscarArticulosLineasBorradoresFactura,
         FContexto.DataModule.unqryArtDataLinFac,
         'frmMtoArtFacSearch') then
    begin
      FContexto.DataModule.CopiarArticuloaLinea(
        FContexto.DataModule.unqryArtDataLinFac);
      ActivarSkuLinea(
        FContexto.DataModule.unqryLinFac.FieldByName(
          'CODIGO_ART_FACLIN').AsString,
        True);
    end;
  end;
end;

procedure TPresentadorLineasFacturaVcl.ConsolidarSku(Sender: TObject);
var
  sCodigoSku: string;
  Editor: TcxCustomEdit;
  Resultado: TResultadoEdicionLineaFactura;
begin
  if Assigned(FEditor) and (Sender is TcxCustomEdit) then
  begin
    Editor := TcxCustomEdit(Sender);
    sCodigoSku := Trim(VarToStr(Editor.EditingValue));
    if (sCodigoSku = '') and (Editor is TcxCustomTextEdit) then
      sCodigoSku := Trim(TcxCustomTextEdit(Editor).Text);
    if sCodigoSku = '' then
      sCodigoSku := Trim(VarToStr(Editor.EditValue));
    Resultado := FEditor.AplicarEntrada(sCodigoSku);
    if Resultado.Aplicado and (Resultado.CodigoSku <> '') and
       (VarToStr(Editor.EditValue) <> Resultado.CodigoSku) then
      Editor.EditValue := Resultado.CodigoSku;
    if Resultado.Aplicado then
      ActivarSkuLinea(Resultado.CodigoArticulo, False);
  end;
end;

function TPresentadorLineasFacturaVcl.PrecioSku(
  const ACodigoArticulo, ACodigoSku: string): Double;
begin
  Result := 0;
  if Assigned(FEditor) then
    Result := FEditor.PrecioSku(ACodigoArticulo, ACodigoSku);
end;

procedure TPresentadorLineasFacturaVcl.Recalcular(Sender: TObject);
begin
  // El editor inplace del cxGrid puede llegar sin Parent durante las
  // transiciones de celda; mismo patron defensivo que en inMtoCajaOpe.
  try
    GridRecalc(FContexto.Conexion, FContexto.Lecturas, Sender,
               FContexto.Vista,
               FContexto.DataModule.unqryLinFac,
               FContexto.DataModule.unqryTablaG,
               nil,
               arfSoloLinea);
    FContexto.DataModule.MarcarRecalculoFacturaPendiente;
  except
    on E: EInvalidOperation do
      FContexto.RegistroLog.RegistrarAviso(
        'FacturasLineas.Recalcular: EInvalidOperation ignorada: ' +
        E.Message);
  end;
end;

procedure TPresentadorLineasFacturaVcl.AplicarEdicionPrecios(
  Sender: TObject);
var
  dsLineas: TDataSource;
begin
  if Assigned(FContexto.DataModule) then
  begin
    dsLineas := FContexto.DataModule.dsLinFac;
    if dsLineas.State in [dsEdit, dsInsert, dsBrowse] then
    begin
      // Factura con impuestos incluidos: solo es editable el c/IVA.
      if SameText(dsLineas.DataSet.FieldByName(fimpcl).AsString, 'S') then
      begin
        FColumnas.PrecioSinIva.Properties.ReadOnly := True;
        FColumnas.PrecioConIva.Properties.ReadOnly := False;
        FColumnas.TotalSinIva.Visible := False;
        FColumnas.TotalConIva.Visible := True;
      end
      else
      begin
        FColumnas.PrecioConIva.Properties.ReadOnly := True;
        FColumnas.PrecioSinIva.Properties.ReadOnly := False;
        FColumnas.TotalSinIva.Visible := True;
        FColumnas.TotalConIva.Visible := False;
      end;
    end;
  end;
end;

function TPresentadorLineasFacturaVcl.AsegurarCabeceraPersistida: Boolean;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
begin
  Result := False;
  if Assigned(FContexto.DataModule) then
  begin
    dsCab := FContexto.DataModule.unqryTablaG;
    dsLin := FContexto.DataModule.unqryLinFac;
    if (dsCab <> nil) and dsCab.Active and
       ((not dsCab.IsEmpty) or (dsCab.State in dsEditModes)) then
    begin
      Result := True;
      if dsCab.State in dsEditModes then
      begin
        try
          dsCab.Post;
        except
          on E: Exception do
          begin
            Result := False;
            ShowMessage_fza(Format(SErrorCompletarDatosBorrador, [E.Message]));
          end;
        end;
      end;
      if Result and Assigned(dsLin) and dsLin.Active and
         (not (dsLin.State in dsEditModes)) then
      begin
        dsLin.Close;
        dsLin.Open;
      end;
    end;
  end;
end;

procedure TPresentadorLineasFacturaVcl.AsegurarPrimeraLinea;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
  sFase: string;
  bSeguir: Boolean;
begin
  bSeguir := Assigned(FContexto.DataModule);
  dsCab := nil;
  dsLin := nil;
  if bSeguir then
  begin
    dsCab := FContexto.DataModule.unqryTablaG;
    dsLin := FContexto.DataModule.unqryLinFac;
    bSeguir := (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
      ((not dsCab.IsEmpty) or (dsCab.State in dsEditModes));
  end;
  if bSeguir then
    bSeguir := AsegurarCabeceraPersistida;
  if bSeguir then
  begin
    sNumero := Trim(dsCab.FieldByName('NUMERO_FAC').AsString);
    sSerie := Trim(dsCab.FieldByName('SERIE_FAC').AsString);
    bSeguir := (sNumero <> '') and (sNumero <> '0') and (sSerie <> '');
  end;
  if bSeguir then
  begin
    sFase := '';
    if dsCab.FindField('FASE_FAC') <> nil then
      sFase := Trim(dsCab.FieldByName('FASE_FAC').AsString);
    // Solo un borrador ya persistido admite la linea automatica.
    bSeguir := ((sFase = '') or SameText(sFase, 'BORRADOR')) and
      (not (dsCab.State in dsEditModes));
  end;
  if bSeguir then
  begin
    if not dsLin.Active then
      dsLin.Open;
    if dsLin.IsEmpty and (not (dsLin.State in dsEditModes)) then
      dsLin.Append;
  end;
end;

procedure TPresentadorLineasFacturaVcl.DesactivarEnterSku(Sender: TObject);
begin
  if not FEnterSkuActivo then
  begin
    FEnterSkuAnterior :=
      FContexto.Vista.OptionsBehavior.GoToNextCellOnEnter;
    FEnterSkuActivo := True;
  end;
  FContexto.Vista.OptionsBehavior.GoToNextCellOnEnter := False;
  if Assigned(FContexto.DesactivarEnterAsTab) then
    FContexto.DesactivarEnterAsTab(Sender);
end;

procedure TPresentadorLineasFacturaVcl.RestaurarEnterSku(Sender: TObject);
begin
  if FEnterSkuActivo then
  begin
    FContexto.Vista.OptionsBehavior.GoToNextCellOnEnter :=
      FEnterSkuAnterior;
    FEnterSkuActivo := False;
  end;
  if Assigned(FContexto.RestaurarEnterAsTab) then
    FContexto.RestaurarEnterAsTab(Sender);
end;

procedure TPresentadorLineasFacturaVcl.SalirEditorSku(Sender: TObject);
begin
  ConsolidarSku(Sender);
  RestaurarEnterSku(Sender);
end;

procedure TPresentadorLineasFacturaVcl.TextoSkuLinea(
  Sender: TcxCustomGridTableItem;
  ARecordIndex: Integer;
  var AText: string);
begin
  // Se vacia el texto del SKU en las lineas cuyo articulo no es de
  // variacion ni es nuevo. El valor sigue en el dataset.
  if not MostrarSkuArticulo(ArticuloLinea(ARecordIndex)) then
    AText := '';
end;

function CabeceraEnSubsanacion(ACabecera: TDataSource): Boolean;
begin
  Result := Assigned(ACabecera) and (ACabecera.DataSet <> nil) and
    ACabecera.DataSet.Active and
    (ACabecera.DataSet.FindField(ffasefac) <> nil) and
    SameText(Trim(ACabecera.DataSet.FieldByName(ffasefac).AsString),
      cFaseFacturaSubsanacion);
end;

// Sólo las columnas ligadas a cantidad o precios; las del pivote de
// tallas (sin campo) y el resto quedan bloqueadas.
function ColumnaEditableEnSubsanacion(
  AItem: TcxCustomGridTableItem): Boolean;
begin
  Result := (AItem is TcxGridDBColumn) and
    CampoLineaEditableEnSubsanacion(
      TcxGridDBColumn(AItem).DataBinding.FieldName);
end;

procedure TPresentadorLineasFacturaVcl.PermitirEdicion(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  // El SKU solo es editable cuando procede mostrarlo.
  if (AItem = FColumnas.Sku) and Assigned(FContexto.DataModule) then
  begin
    AAllow := MostrarSkuArticulo(
      FContexto.DataModule.unqryLinFac.FieldByName(
        'CODIGO_ART_FACLIN').AsString);
    if AAllow then
      DesactivarEnterSku(Sender)
    else
      RestaurarEnterSku(Sender);
  end
  else
    RestaurarEnterSku(Sender);
  // En subsanación (registro ya aceptado) sólo se corrigen cantidades y
  // precios, como en Caja: la estructura de la línea queda fija.
  if AAllow and CabeceraEnSubsanacion(FContexto.Cabecera) then
    AAllow := ColumnaEditableEnSubsanacion(AItem);
end;

procedure TPresentadorLineasFacturaVcl.EnvolverEdicionModo(
  AVista: TcxCustomGridTableView);
begin
  FEdicionModo := AVista.OnEditing;
  AVista.OnEditing := PermitirEdicionModo;
end;

procedure TPresentadorLineasFacturaVcl.PermitirEdicionModo(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  if Assigned(FEdicionModo) then
    FEdicionModo(Sender, AItem, AAllow);
  // FZ-ISSUE-129: en subsanación sólo cantidades y precios, sea cual
  // sea el modo de entrada.
  if AAllow and CabeceraEnSubsanacion(FContexto.Cabecera) then
    AAllow := ColumnaEditableEnSubsanacion(AItem);
end;

procedure TPresentadorLineasFacturaVcl.IniciarEdicion(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  if AItem = FColumnas.Sku then
  begin
    AEdit.OnEnter := DesactivarEnterSku;
    AEdit.OnExit := SalirEditorSku;
    DesactivarEnterSku(AEdit);
  end;
end;

procedure TPresentadorLineasFacturaVcl.TeclaEnEdicion(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit;
  var Key: Word;
  Shift: TShiftState);
begin
  if AItem = FColumnas.Sku then
    DesactivarEnterSku(AEdit);
end;

procedure TPresentadorLineasFacturaVcl.PrepararPopupSku(Sender: TObject);
var
  Combo: TcxComboBox;
  Resolver: IArticulosResolver;
  Skus: TArray<TArticuloSkuItem>;
  Item: TArticuloSkuItem;
  sCodArt: string;
begin
  if Sender is TcxComboBox then
  begin
    Combo := Sender as TcxComboBox;
    DesactivarEnterSku(Sender);
    // El combo se rellena en cada apertura con los SKUs del articulo de
    // la fila activa; lsEditList admite ademas un valor tecleado.
    sCodArt := FContexto.DataModule.unqryLinFac.FindField(
      'CODIGO_ART_FACLIN').AsString;
    Combo.Properties.Items.BeginUpdate;
    try
      Combo.Properties.Items.Clear;
      if (sCodArt <> '') and Assigned(FContexto.CrearResolver) then
      begin
        Resolver := FContexto.CrearResolver();
        try
          Skus := Resolver.ListarSkus(sCodArt);
          for Item in Skus do
            Combo.Properties.Items.Add(Item.CodigoSku);
        finally
          Resolver := nil;
        end;
      end;
    finally
      Combo.Properties.Items.EndUpdate;
    end;
  end;
end;

procedure TPresentadorLineasFacturaVcl.CerrarPopupSku(Sender: TObject);
begin
  // CloseUp llega dentro de la misma tecla Enter que selecciona el item;
  // restaurar aqui convertiria esa tecla en Tab.
  ConsolidarSku(Sender);
  DesactivarEnterSku(Sender);
end;

procedure TPresentadorLineasFacturaVcl.CambioEnLineas(
  Sender: TObject; Field: TField);
begin
  // Field = nil: cambio de registro de linea, recarga del detalle o
  // alta/baja de linea. Se re-evalua la visibilidad del detalle.
  if Field = nil then
  begin
    ReaplicarVisibilidad;
    // Con la linea a medio insertar/editar no se recalcula el total de
    // prendas: se refresca en el DataChange del Post.
    if (FContexto.DataModule = nil) or
       (not (FContexto.DataModule.unqryLinFac.State in dsEditModes)) then
      ActualizarTotalPrendas;
  end;
end;

procedure TPresentadorLineasFacturaVcl.ModoEntradaResuelto(
  const ACodigoArticulo, ASku, ADescripcion: string;
  ACompleto: Boolean);
begin
  // El flujo fiscal clasico (tarifa del cliente, IVA, dtos, precios y
  // totales) se reaprovecha: AplicarArticulo acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticulo(ASku)
  else if ACompleto and (ACodigoArticulo <> '') then
    // ASku vacio con resolucion completa = codigo fuera de catalogo
    // aceptado por el modo (AceptarNoCatalogo): linea libre.
    AplicarLineaNoCatalogo(ACodigoArticulo);
end;

procedure TPresentadorLineasFacturaVcl.PivoteCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticulo(ACodigoSku);
end;

procedure TPresentadorLineasFacturaVcl.PivoteBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  if Assigned(FContexto.PestanaLineas) then
    FContexto.PestanaLineas.Caption :=
      SCaptionTabLineasBorradorTallasHoriz;
end;

end.
