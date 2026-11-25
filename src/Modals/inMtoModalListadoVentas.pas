{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalListadoVentas                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       26/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Listado en grid de lineas de factura de venta. Incluye filtros de fecha,  }
{    familia, proveedor y temporada, con precarga del mes en curso.         }
{******************************************************************************}
unit inMtoModalListadoVentas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Data.DB,
  inMtoFrmBase, cxClasses, cxLocalization, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxButtons, cxCheckBox, cxCurrencyEdit,
  JvComponentBase, JvEnterTab, inLibListadoVentasPersistenciaIntf,
  inLibDocumentosTrabajo, inLibArticulosResolverIntf;

const
  WM_CARGA_INICIAL_LISTADO_VENTAS = WM_APP + 652;

type
  TfrmModalListadoVentas = class(TfrmBase)
    procedure FormCreate(Sender: TObject);
  private
    // Campos primero (E2169).
    pnlFiltros:            TPanel;
    pnlBotones:            TPanel;
    lblDesde:              TcxLabel;
    lblHasta:              TcxLabel;
    lblFamilia:            TcxLabel;
    lblProveedor:          TcxLabel;
    lblTemporada:          TcxLabel;
    lblInfo:               TcxLabel;
    lblPrimeraVenta:       TcxLabel;
    lblUltimaVenta:        TcxLabel;
    dteDesde:              TcxDateEdit;
    dteHasta:              TcxDateEdit;
    cbbFamilia:            TcxComboBox;
    cbbProveedor:          TcxComboBox;
    cbbTemporada:          TcxComboBox;
    chkSoloConsolidadas:   TcxCheckBox;
    btnBuscar:             TcxButton;
    btnExcel:              TcxButton;
    btnSalir:              TcxButton;
    cxgrdVentas:           TcxGrid;
    tvVentas:              TcxGridDBTableView;
    lvVentas:              TcxGridLevel;
    FRepositorio:          IRepositorioListadoVentas;
    FConsulta:             IConsultaListadoVentas;
    FDatos:                TDataSet;
    dsVentas:              TDataSource;
    pmVentas:              TPopupMenu;
    miAgregarDocumento:    TMenuItem;
    FDocumentosTrabajo:    TRepositoriosDocumentosTrabajo;
    FResolverArticulos:    IArticulosResolver;
    FInicioProgramado:     Boolean;
    FBuscando:             Boolean;
    procedure CrearInterfaz;
    procedure CrearFiltros;
    procedure ConfigurarEntradaFecha(AEditor: TcxDateEdit);
    procedure SeleccionarFecha(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ValidarEntradaFecha(Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    function LeerFecha(AEditor: TcxDateEdit;
      const AMensajeVacio: string): TDateTime;
    procedure CrearGrid;
    procedure CrearColumnas;
    procedure CrearMenuContextual;
    procedure CargarCombos;
    procedure CargarCombo(ACombo: TcxComboBox;
                          const AOpciones: TOpcionesListadoVentas);
    procedure CargarListado;
    procedure CargarListadoInicial(var AMensaje: TMessage);
      message WM_CARGA_INICIAL_LISTADO_VENTAS;
    procedure EjecutarConsulta(const AFiltro: TFiltroListadoVentas);
    procedure ActualizarResumenListado;
    procedure btnBuscarClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure pmVentasPopup(Sender: TObject);
    procedure miAgregarDocumentoClick(Sender: TObject);
    function  CodigoCombo(ACombo: TcxComboBox): string;
    function  NuevaColumna(const ACampo,
                                 ACaption: string;
                           AAncho: Integer): TcxGridDBColumn;
    procedure ConfigurarMoneda(ACol: TcxGridDBColumn);
    procedure ConfigurarNumero(ACol: TcxGridDBColumn);
    procedure MostrarFotoArticuloActivo;
  protected
    procedure DoShow; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    function CloseQuery: Boolean; override;
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
  end;

implementation

uses
  inLibMensajesVcl,
  System.Diagnostics, System.Threading, inLibDevExp, inLibFotos,
  inLibVentanaEspera,
  inLibDocumentosTrabajoPresentacion,
  inMtoFotoArticulo,
  inLibMsgComun, inLibMsgVentas, inLibMsgArticulos,
  inLibTraducciones,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion;

{$R *.dfm}


procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmModalListadoVentas.FormCreate(Sender: TObject);
var
  oContexto: TContextoListadoVentasPantalla;
begin
  inherited;
  Self.Position := poScreenCenter;
  KeyPreview := True;
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    ParametrosCaja,
    CrearServiciosSqlVentasPantalla(
      Self.Name,
      PerfilesLectura,
      PerfilesEscritura,
      RegistroLog),
    oContexto);
  FRepositorio := oContexto.Listado;
  FDocumentosTrabajo := oContexto.DocumentosTrabajo;
  FResolverArticulos := oContexto.ResolverArticulos;
  dsVentas := TDataSource.Create(Self);
  CrearInterfaz;
  AplicarTraducciones(Self, Self);
  CargarCombos;
end;

procedure TfrmModalListadoVentas.DoShow;
begin
  inherited;
  if not FInicioProgramado then
  begin
    FInicioProgramado := True;
    PostMessage(Handle, WM_CARGA_INICIAL_LISTADO_VENTAS, 0, 0);
  end;
end;

procedure TfrmModalListadoVentas.CargarListadoInicial(var AMensaje: TMessage);
begin
  if Visible and not FBuscando then
    CargarListado;
end;

function TfrmModalListadoVentas.CloseQuery: Boolean;
begin
  Result := not FBuscando;
  if Result then
    Result := inherited CloseQuery;
end;

procedure TfrmModalListadoVentas.CrearInterfaz;
begin
  Caption := STituloVentasFacturadas;
  CrearFiltros;
  CrearGrid;
  pnlBotones := TPanel.Create(Self);
  pnlBotones.Parent := Self;
  pnlBotones.Align := alBottom;
  pnlBotones.Height := 46;
  pnlBotones.BevelOuter := bvNone;
  lblInfo := TcxLabel.Create(Self);
  lblInfo.Parent := pnlBotones;
  lblInfo.Left := 12;
  lblInfo.Top := 12;
  lblInfo.Width := 170;
  lblInfo.Transparent := True;
  lblPrimeraVenta := TcxLabel.Create(Self);
  lblPrimeraVenta.Parent := pnlBotones;
  lblPrimeraVenta.Left := 194;
  lblPrimeraVenta.Top := 12;
  lblPrimeraVenta.Width := 220;
  lblPrimeraVenta.Transparent := True;
  lblUltimaVenta := TcxLabel.Create(Self);
  lblUltimaVenta.Parent := pnlBotones;
  lblUltimaVenta.Left := 426;
  lblUltimaVenta.Top := 12;
  lblUltimaVenta.Width := 220;
  lblUltimaVenta.Transparent := True;
  btnExcel := TcxButton.Create(Self);
  btnExcel.Parent := pnlBotones;
  btnExcel.Left := 888;
  btnExcel.Top := 8;
  btnExcel.Width := 130;
  btnExcel.Height := 30;
  btnExcel.Caption := SCaptionExportarExcel;
  btnExcel.Anchors := [akTop, akRight];
  btnExcel.OnClick := btnExcelClick;
  btnSalir := TcxButton.Create(Self);
  btnSalir.Parent := pnlBotones;
  btnSalir.Left := 1030;
  btnSalir.Top := 8;
  btnSalir.Width := 130;
  btnSalir.Height := 30;
  btnSalir.Caption := SCaptionSalir;
  btnSalir.Anchors := [akTop, akRight];
  btnSalir.OnClick := btnSalirClick;
end;

procedure TfrmModalListadoVentas.CrearFiltros;
begin
  pnlFiltros := TPanel.Create(Self);
  pnlFiltros.Parent := Self;
  pnlFiltros.Align := alTop;
  pnlFiltros.Height := 92;
  pnlFiltros.BevelOuter := bvNone;
  lblDesde := TcxLabel.Create(Self);
  lblDesde.Parent := pnlFiltros;
  lblDesde.Left := 12;
  lblDesde.Top := 10;
  lblDesde.Caption := SCaptionDesde;
  lblDesde.Transparent := True;
  dteDesde := TcxDateEdit.Create(Self);
  dteDesde.Parent := pnlFiltros;
  dteDesde.Left := 12;
  dteDesde.Top := 32;
  dteDesde.Width := 112;
  dteDesde.Date := StartOfTheMonth(Date);
  ConfigurarEntradaFecha(dteDesde);
  lblHasta := TcxLabel.Create(Self);
  lblHasta.Parent := pnlFiltros;
  lblHasta.Left := 136;
  lblHasta.Top := 10;
  lblHasta.Caption := SCaptionHasta;
  lblHasta.Transparent := True;
  dteHasta := TcxDateEdit.Create(Self);
  dteHasta.Parent := pnlFiltros;
  dteHasta.Left := 136;
  dteHasta.Top := 32;
  dteHasta.Width := 112;
  dteHasta.Date := Date;
  ConfigurarEntradaFecha(dteHasta);
  lblFamilia := TcxLabel.Create(Self);
  lblFamilia.Parent := pnlFiltros;
  lblFamilia.Left := 268;
  lblFamilia.Top := 10;
  lblFamilia.Caption := SCaptionFamilia;
  lblFamilia.Transparent := True;
  cbbFamilia := TcxComboBox.Create(Self);
  cbbFamilia.Parent := pnlFiltros;
  cbbFamilia.Left := 268;
  cbbFamilia.Top := 32;
  cbbFamilia.Width := 220;
  cbbFamilia.Properties.DropDownListStyle := lsFixedList;
  lblProveedor := TcxLabel.Create(Self);
  lblProveedor.Parent := pnlFiltros;
  lblProveedor.Left := 500;
  lblProveedor.Top := 10;
  lblProveedor.Caption := SCaptionProveedor;
  lblProveedor.Transparent := True;
  cbbProveedor := TcxComboBox.Create(Self);
  cbbProveedor.Parent := pnlFiltros;
  cbbProveedor.Left := 500;
  cbbProveedor.Top := 32;
  cbbProveedor.Width := 250;
  cbbProveedor.Properties.DropDownListStyle := lsFixedList;
  lblTemporada := TcxLabel.Create(Self);
  lblTemporada.Parent := pnlFiltros;
  lblTemporada.Left := 762;
  lblTemporada.Top := 10;
  lblTemporada.Caption := SCaptionTemporada;
  lblTemporada.Transparent := True;
  cbbTemporada := TcxComboBox.Create(Self);
  cbbTemporada.Parent := pnlFiltros;
  cbbTemporada.Left := 762;
  cbbTemporada.Top := 32;
  cbbTemporada.Width := 170;
  cbbTemporada.Properties.DropDownListStyle := lsFixedList;
  chkSoloConsolidadas := TcxCheckBox.Create(Self);
  chkSoloConsolidadas.Parent := pnlFiltros;
  chkSoloConsolidadas.Left := 944;
  chkSoloConsolidadas.Top := 32;
  chkSoloConsolidadas.Width := 130;
  chkSoloConsolidadas.Caption := SCaptionSoloEmitidas;
  chkSoloConsolidadas.Checked := True;
  btnBuscar := TcxButton.Create(Self);
  btnBuscar.Parent := pnlFiltros;
  btnBuscar.Left := 1082;
  btnBuscar.Top := 30;
  btnBuscar.Width := 82;
  btnBuscar.Height := 28;
  btnBuscar.Caption := SCaptionBuscar;
  btnBuscar.Anchors := [akTop, akRight];
  btnBuscar.OnClick := btnBuscarClick;
end;

procedure TfrmModalListadoVentas.ConfigurarEntradaFecha(AEditor: TcxDateEdit);
begin
  AEditor.Properties.InputKind := ikStandard;
  AEditor.Properties.AutoSelect := True;
  AEditor.Properties.DateOnError := deNoChange;
  AEditor.Properties.SaveTime := False;
  AEditor.Properties.MinDate := EncodeDate(1900, 1, 1);
  AEditor.Properties.MaxDate := EncodeDate(9999, 12, 31);
  AEditor.Properties.OnValidate := ValidarEntradaFecha;
  AEditor.OnMouseUp := SeleccionarFecha;
end;

procedure TfrmModalListadoVentas.SeleccionarFecha(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (Shift = []) then
    TcxDateEdit(Sender).SelectAll;
end;

procedure TfrmModalListadoVentas.ValidarEntradaFecha(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sTexto: string;
  dFecha: TDateTime;
begin
  sTexto := Trim(TcxDateEdit(Sender).Text);
  if sTexto <> '' then
  begin
    Error := not TryStrToDate(sTexto, dFecha) or
      (dFecha < EncodeDate(1900, 1, 1));
    ErrorText := SErrorFechaFiltroInformeNoValida;
    if not Error then
      DisplayValue := DateToStr(dFecha);
  end;
end;

function TfrmModalListadoVentas.LeerFecha(AEditor: TcxDateEdit;
  const AMensajeVacio: string): TDateTime;
begin
  AEditor.ValidateEdit(True);
  AEditor.PostEditValue;
  Result := DateOf(AEditor.Date);
  if Result <= 0 then
  begin
    AEditor.SetFocus;
    raise EcxEditValidationError.Create(AMensajeVacio);
  end;
end;

procedure TfrmModalListadoVentas.CrearGrid;
begin
  cxgrdVentas := TcxGrid.Create(Self);
  cxgrdVentas.Parent := Self;
  cxgrdVentas.Align := alClient;
  tvVentas :=
    cxgrdVentas.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  tvVentas.Name := 'tvListadoVentas';
  tvVentas.DataController.DataSource := dsVentas;
  tvVentas.OptionsData.Appending := False;
  tvVentas.OptionsData.Deleting := False;
  tvVentas.OptionsData.Editing := False;
  tvVentas.OptionsData.Inserting := False;
  tvVentas.OptionsSelection.CellSelect := True;
  tvVentas.OptionsView.GroupByBox := True;
  tvVentas.OptionsView.NoDataToDisplayInfoText := SCaptionSinVentas;
  lvVentas := cxgrdVentas.Levels.Add;
  lvVentas.GridView := tvVentas;
  CrearColumnas;
  CrearMenuContextual;
end;

procedure TfrmModalListadoVentas.CrearMenuContextual;
begin
  pmVentas := TPopupMenu.Create(Self);
  pmVentas.OnPopup := pmVentasPopup;
  miAgregarDocumento := TMenuItem.Create(pmVentas);
  miAgregarDocumento.Caption := SCaptionAnadirDocumentoTrabajo;
  miAgregarDocumento.OnClick := miAgregarDocumentoClick;
  pmVentas.Items.Add(miAgregarDocumento);
  cxgrdVentas.PopupMenu := pmVentas;
end;

procedure TfrmModalListadoVentas.CrearColumnas;
var
  col: TcxGridDBColumn;
begin
  NuevaColumna('FECHA_FAC', SCaptionListadoVentasFecha, 86);
  NuevaColumna('DOCUMENTO_FAC', SCaptionListadoVentasDocumento, 112);
  NuevaColumna('TIPO_FAC', SCaptionListadoVentasTipo, 96);
  NuevaColumna('FASE_FAC', SCaptionListadoVentasFaseDocumento, 145);
  NuevaColumna('ESCONSOLIDADA_FAC', SCaptionListadoVentasEmitida, 68);
  NuevaColumna('CODIGO_ALM_FACLIN', SCaptionListadoVentasAlmacen, 80);
  NuevaColumna('CODIGO_CLI_FAC', SCaptionListadoVentasCliente, 86);
  NuevaColumna('RAZON_SOCIAL_CLIENTE_FAC',
    SCaptionListadoVentasRazonCliente, 190);
  NuevaColumna('CODIGO_VENDEDOR', SCaptionListadoVentasCodigoVendedor, 80);
  NuevaColumna('NOMBRE_VENDEDOR', SCaptionListadoVentasVendedor, 140);
  NuevaColumna('LINEA_FACLIN', SCaptionListadoVentasLinea, 62);
  NuevaColumna('CODIGO_ART_FACLIN', SCaptionListadoVentasArticulo, 96);
  NuevaColumna('CODIGO_UNIDAD_FACLIN', SCaptionListadoVentasSku, 140);
  NuevaColumna('DESCRIPCION_ARTICULO_FACLIN',
    SCaptionListadoVentasDescripcion, 230);
  NuevaColumna('DESCRIPCION_VARIACION_FACLIN',
    SCaptionListadoVentasVariacion, 120);
  NuevaColumna('REF_PROVEEDOR', SCaptionListadoVentasModelo, 120);
  NuevaColumna('CODIGO_FAM_FACLIN', SCaptionListadoVentasCodigoFamilia, 90);
  NuevaColumna('NOMBRE_FAM_FACLIN', SCaptionListadoVentasFamilia, 150);
  NuevaColumna('CODIGO_PRV_FACLIN', SCaptionListadoVentasCodigoProveedor, 80);
  NuevaColumna('RAZON_SOCIAL_PROVEEDOR_FACLIN',
    SCaptionListadoVentasProveedor, 170);
  NuevaColumna('TEMPORADA_ART', SCaptionListadoVentasTemporada, 130);
  col := NuevaColumna('CANTIDAD_FACLIN', SCaptionListadoVentasCantidad, 82);
  ConfigurarNumero(col);
  col := NuevaColumna('PRECIO_SALIDA_FACLIN',
    SCaptionListadoVentasPrecioSalida, 96);
  ConfigurarMoneda(col);
  col := NuevaColumna('PORCENTAJE_DTO_FACLIN',
    SCaptionListadoVentasDescuento, 72);
  ConfigurarNumero(col);
  col := NuevaColumna('PRECIO_VENTA_SIVA_ARTICULO_FACLIN',
    SCaptionListadoVentasPvpSinIva, 94);
  ConfigurarMoneda(col);
  col := NuevaColumna('PRECIO_VENTA_CIVA_ARTICULO_FACLIN',
    SCaptionListadoVentasPvpConIva, 94);
  ConfigurarMoneda(col);
  col := NuevaColumna('TOTAL_FAC_SIVA_FACLIN',
    SCaptionListadoVentasTotalSinIva, 96);
  ConfigurarMoneda(col);
  col := NuevaColumna('TOTAL_FACLIN', SCaptionListadoVentasTotalConIva, 96);
  ConfigurarMoneda(col);
end;

function TfrmModalListadoVentas.NuevaColumna(const ACampo,
  ACaption: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := tvVentas.CreateColumn;
  Result.Caption := ACaption;
  Result.DataBinding.FieldName := ACampo;
  Result.Width := AAncho;
  Result.Options.Editing := False;
end;

procedure TfrmModalListadoVentas.ConfigurarMoneda(ACol: TcxGridDBColumn);
var
  props: TcxCurrencyEditProperties;
begin
  if ACol <> nil then
  begin
    ACol.PropertiesClass := TcxCurrencyEditProperties;
    props := TcxCurrencyEditProperties(ACol.Properties);
    props.DisplayFormat := '#,##0.00;-#,##0.00;0.00';
    props.UseDisplayFormatWhenEditing := True;
  end;
end;

procedure TfrmModalListadoVentas.ConfigurarNumero(ACol: TcxGridDBColumn);
var
  props: TcxCurrencyEditProperties;
begin
  if ACol <> nil then
  begin
    ACol.PropertiesClass := TcxCurrencyEditProperties;
    props := TcxCurrencyEditProperties(ACol.Properties);
    props.DisplayFormat := '#,##0.##;-#,##0.##;0';
    props.UseDisplayFormatWhenEditing := True;
  end;
end;

procedure TfrmModalListadoVentas.CargarCombos;
begin
  CargarCombo(cbbFamilia, FRepositorio.ListarFamilias);
  CargarCombo(cbbProveedor, FRepositorio.ListarProveedores);
  CargarCombo(cbbTemporada, FRepositorio.ListarTemporadas);
end;

procedure TfrmModalListadoVentas.CargarCombo(ACombo: TcxComboBox;
  const AOpciones: TOpcionesListadoVentas);
var
  Opcion: TOpcionListadoVentas;
begin
  if ACombo <> nil then
  begin
    ACombo.Properties.Items.BeginUpdate;
    try
      ACombo.Properties.Items.Clear;
      ACombo.Properties.Items.Add(SItemTodosFiltrosListadoVentas);
      for Opcion in AOpciones do
      begin
        if (Opcion.Nombre <> '') and
           (Opcion.Nombre <> Opcion.Codigo) then
          ACombo.Properties.Items.Add(
            Opcion.Codigo + ' - ' + Opcion.Nombre)
        else
          ACombo.Properties.Items.Add(Opcion.Codigo);
      end;
    finally
      ACombo.Properties.Items.EndUpdate;
    end;
    ACombo.ItemIndex := 0;
  end;
end;

procedure TfrmModalListadoVentas.CargarListado;
var
  Filtro: TFiltroListadoVentas;
  dHasta: TDateTime;
begin
  Filtro := Default(TFiltroListadoVentas);
  Filtro.FechaDesde := LeerFecha(dteDesde, SErrorFechaInicioDocumentoNoIndicada);
  dHasta := LeerFecha(dteHasta, SErrorFechaFinDocumentoNoIndicada);
  if dHasta < Filtro.FechaDesde then
  begin
    dteHasta.SetFocus;
    raise EcxEditValidationError.Create(SErrorRangoFechasDocumentoNoValido);
  end;
  Filtro.FechaHastaExclusiva := dHasta + 1;
  if (YearOf(Filtro.FechaDesde) = 9999) or
     (Filtro.FechaHastaExclusiva <= IncYear(Filtro.FechaDesde)) or
     (MessageDlg_fza(Self, Format(SPreguntaListadoVentasRangoAnual,
        [DateToStr(Filtro.FechaDesde), DateToStr(dHasta)]),
        mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes) then
  begin
    Filtro.Empresa := UbicacionSesion.Empresa;
    Filtro.Familia := CodigoCombo(cbbFamilia);
    Filtro.Proveedor := CodigoCombo(cbbProveedor);
    Filtro.Temporada := CodigoCombo(cbbTemporada);
    Filtro.SoloConsolidadas := chkSoloConsolidadas.Checked;
    EjecutarConsulta(Filtro);
  end;
end;

procedure TfrmModalListadoVentas.EjecutarConsulta(
  const AFiltro: TFiltroListadoVentas);
var
  oConsulta: IConsultaListadoVentas;
  oVentana: IVentanaEspera;
  oTarea: ITask;
  sError: string;
  sw: TStopwatch;
  CursorAnterior: TCursor;
begin
  oConsulta := FRepositorio.PrepararConsulta(AFiltro);
  oVentana := CrearVentanaProcesoSegundoPlano(
    BoundsRect, CurrentPPI, STituloVentasFacturadas);
  FBuscando := True;
  sw := TStopwatch.StartNew;
  CursorAnterior := Screen.Cursor;
  try
    oVentana.Mostrar(SCaptionBuscandoVentas);
    oVentana.PermitirCancelar(True);
    oTarea := TTask.Run(
      procedure
      begin
        try
          oConsulta.Abrir;
        except
          on E: Exception do
            sError := E.Message;
        end;
      end);
    try
      EsperarTareaAtendiendoMensajes(oTarea,
        procedure
        begin
          if oVentana.Cancelado then
            oConsulta.Cancelar;
        end);
    finally
      EsperarTareaAtendiendoMensajes(oTarea);
    end;
    if not oVentana.Cancelado then
    begin
      if sError <> '' then
      begin
        RegistroLog.RegistrarError('ListadoVentas.CargarListado: ' + sError);
        raise Exception.Create(sError);
      end;
      oVentana.PermitirCancelar(False);
      Screen.Cursor := crHourGlass;
      dsVentas.DataSet := nil;
      FConsulta := oConsulta;
      FDatos := FConsulta.DataSet;
      dsVentas.DataSet := FDatos;
      ActualizarResumenListado;
      RegistroLog.RegistrarRendimiento('ListadoVentas.CargarListado',
        Format('filas=%d', [FDatos.RecordCount]), sw.ElapsedMilliseconds);
    end;
  finally
    Screen.Cursor := CursorAnterior;
    FBuscando := False;
    oVentana.Ocultar;
  end;
end;

procedure TfrmModalListadoVentas.ActualizarResumenListado;
var
  dPrimeraVenta: TDateTime;
  dUltimaVenta: TDateTime;
begin
  lblInfo.Caption := Format(SCaptionLineasCargadas,
                            [FDatos.RecordCount]);
  lblPrimeraVenta.Caption := SCaptionPrimeraVentaVacia;
  lblUltimaVenta.Caption := SCaptionUltimaVentaVacia;
  if not FDatos.IsEmpty then
  begin
    FDatos.DisableControls;
    try
      FDatos.First;
      dUltimaVenta := FDatos.FieldByName('FECHA_FAC').AsDateTime;
      FDatos.Last;
      dPrimeraVenta := FDatos.FieldByName('FECHA_FAC').AsDateTime;
      FDatos.First;
    finally
      FDatos.EnableControls;
    end;
    lblPrimeraVenta.Caption := Format(SCaptionPrimeraVenta,
      [FormatDateTime('dd/mm/yyyy', dPrimeraVenta)]);
    lblUltimaVenta.Caption := Format(SCaptionUltimaVenta,
      [FormatDateTime('dd/mm/yyyy', dUltimaVenta)]);
  end;
end;

procedure TfrmModalListadoVentas.btnBuscarClick(Sender: TObject);
begin
  if not FBuscando then
    CargarListado;
end;

procedure TfrmModalListadoVentas.btnExcelClick(Sender: TObject);
begin
  if Assigned(FDatos) and FDatos.Active then
    ExportarExcel(ParametrosApp, cxgrdVentas, 'Listado_ventas');
end;

procedure TfrmModalListadoVentas.btnSalirClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalListadoVentas.pmVentasPopup(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  ResolverArtSkuStock(sArt, sSku);
  miAgregarDocumento.Enabled := Trim(sArt) <> '';
end;

procedure TfrmModalListadoVentas.miAgregarDocumentoClick(Sender: TObject);
begin
  try
    AgregarArticuloActivoADocumentoTrabajo(Self, ConexionPrincipal,
      FDocumentosTrabajo,
      CrearInteraccionDocumentosTrabajoVcl,
      BusquedaVisual, ContextoSesion, ParametrosCaja, ResolverArtSkuStock,
      FResolverArticulos);
  except
    on E: Exception do
      MessageDlg_fza(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmModalListadoVentas.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = Ord('F')) and (ssCtrl in Shift) and
     not (ssShift in Shift) and not (ssAlt in Shift) then
  begin
    MostrarFotoArticuloActivo;
    Key := 0;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmModalListadoVentas.MostrarFotoArticuloActivo;
var
  FormularioFoto: TfrmFotoArticulo;
  sArt: string;
  sSku: string;
begin
  FormularioFoto := FotoFlotanteActual;
  if (FormularioFoto <> nil) and FormularioFoto.Visible then
    FormularioFoto.Hide
  else
  begin
    ResolverArtSkuStock(sArt, sSku);
    if sArt <> '' then
    begin
      MostrarFotoFlotante(Self, sArt, sSku);
      FormularioFoto := FotoFlotanteActual;
      if FormularioFoto <> nil then
        FormularioFoto.VincularDataSources([dsVentas],
                                           ResolverArtSkuStock);
    end;
  end;
end;

procedure TfrmModalListadoVentas.ResolverArtSkuStock(out ACodArt,
  ACodSku: string);
begin
  inLibFotos.LeerArtSkuDeDataSet(FDatos, ACodArt, ACodSku);
end;

function TfrmModalListadoVentas.CodigoCombo(ACombo: TcxComboBox): string;
var
  iPos: Integer;
  sTexto: string;
begin
  Result := '';
  if (ACombo <> nil) and (ACombo.ItemIndex > 0) then
  begin
    sTexto := Trim(ACombo.Text);
    iPos := Pos(' - ', sTexto);
    if iPos > 0 then
      Result := Copy(sTexto, 1, iPos - 1)
    else
      Result := sTexto;
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalListadoVentas);

end.
