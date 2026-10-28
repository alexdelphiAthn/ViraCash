{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasProforma                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación por periodo de proformas VE, facturas fiscales TA y           }
{    facturas TV de lo traspasado que la tienda destino ya ha vendido.         }
{******************************************************************************}
unit inMtoFacturasProforma;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.DateUtils,
  System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxButtons, cxRadioGroup, cxCheckBox, cxPC, dxSkinsCore,
  dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataFacturasProforma, inLibFacturasProformaIntf,
  inLibOpcionesDocumentoIntf,
  inLibMargenVinculadas, inMtoGen;

type
  TfrmMtoFacturasProforma = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados   : Boolean;
    dmmFacturasProforma : TdmFacturasProforma;
    pnlFacturacion      : TPanel;
    dteDesde            : TcxDateEdit;
    dteHasta            : TcxDateEdit;
    cbbEmpresaOrigen    : TcxLookupComboBox;
    cbbEmpresaDestino   : TcxLookupComboBox;
    lblDesde            : TcxLabel;
    lblHasta            : TcxLabel;
    lblEmpresaOrigen    : TcxLabel;
    lblEmpresaDestino   : TcxLabel;
    rgModalidad         : TcxRadioGroup;
    chkCargarVales      : TcxCheckBox;
    btnGenerar          : TcxButton;
    btnRefrescar        : TcxButton;
    btnImprimir         : TcxButton;
    btnConvertir        : TcxButton;
    btnCuadreInternas   : TcxButton;
    lblExplicacion      : TcxLabel;
    function EscalarDpi(AValor: Integer): Integer;
    function CrearEtiqueta(const ATexto: string; AIzq, ATop: Integer):
      TcxLabel;
    function CrearBotonBarraDerecha(const ACaption: string; ATop: Integer;
      AOnClick: TNotifyEvent): TcxButton;
    procedure CrearColumnas;
    procedure MostrarEstadoProforma(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var ATexto: string);
    procedure ActualizarEstadoEmpresaDestino;
    procedure AjustarDesplegablesEmpresa;
    procedure EmpresaOrigenCambiada(Sender: TObject);
    function CrearColumna(const ACampo, ATitulo: string;
      AAncho: Integer): TcxGridDBColumn;
    function EscalaMargenMinimoTraspasos: TEscalaMargenMinimo;
    function ObtenerModalidad: TModalidadFacturacionCaja;
    function PrepararSolicitud: TSolicitudFacturacionCaja;
    function ConfirmarGeneracion(
      AModalidad: TModalidadFacturacionCaja): Boolean;
    function ConfirmarRevisionPeriodo(
      const ARevision: TRevisionPeriodoFacturacionCaja): Boolean;
    function TextoResultado(
      const AResultado: TResultadoFacturacionCaja): string;
    procedure MostrarResultado(
      const AResultado: TResultadoFacturacionCaja);
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
    function ValorarTraspasos(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja;
      out AValoracion: TValoracionTraspasos): Boolean;
    procedure EjecutarGeneracion(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja;
      const AValoracion: TValoracionTraspasos);
    function TipoFacturaOpcionesDocumento: TTipoOpcionesDocumento;
    function SolicitarOpcionesFacturasTraspaso(
      var ASolicitud: TSolicitudFacturacionCaja): Boolean;
    function ConfigurarConversionVales(
      const APropuesta: TOpcionesDocumento
    ): TConfiguracionOpcionesDocumento;
    procedure ConvertirProformaVales(AIdProforma: Int64);
    procedure ImprimirSeleccion;
    procedure RefrescarHistorial;
    procedure btnGenerarClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnConvertirClick(Sender: TObject);
    procedure btnCuadreInternasClick(Sender: TObject);
    procedure rgModalidadPropertiesEditValueChanged(Sender: TObject);
  protected
    procedure CrearControlesDinamicos;
  public
    destructor Destroy; override;
    procedure TrasErrorPrecargaAsync(const AError: string); override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure AplicarTraduccionActual; override;
  end;

resourcestring
  SAyudaEmisoraTraspasoVendido =
    'TV: emite la empresa de origen por lo vendido en destino. ' +
    'La propuesta de vales la emite la empresa con saldo a favor.';
  SPreguntaGenerarProformaVenta =
    'Se generará una proforma interna no fiscal para VENTA CONTADO. ' +
    'No declarará IVA ni VeriFactu. ¿Desea continuar?';
  SPreguntaGenerarFacturaTraspaso =
    'Se generarán borradores de facturas normales por los traspasos TA. ' +
    'El IVA y VeriFactu se declararán al consolidarlos en Venta mayor. ' +
    '¿Desea continuar?';
  SPreguntaGenerarFacturaTraspasoVendido =
    'Se generarán borradores de facturas normales sólo por las unidades ' +
    'traspasadas que la tienda destino ya ha vendido dentro del periodo. ' +
    'Lo devuelto en la tienda se resta de lo facturado. ¿Desea continuar?';
  SPreguntaGenerarProformaVales =
    'Se creará una propuesta no fiscal entre las dos empresas. Los vales ' +
    'recogidos por la empresa A y emitidos por B suman; los recogidos por ' +
    'B y emitidos por A restan.';
  SPreguntaConvertirProformaVales =
    'Se creará un borrador de factura normal por el saldo neto de esta ' +
    'propuesta. Revise su tratamiento fiscal antes de consolidarlo. ' +
    '¿Desea continuar?';
  SInfoSeleccionarProformaVales =
    'Seleccione una propuesta de vales para convertirla.';
  SInfoFacturaValesGenerada =
    'Borrador de factura normal creado: %s.';
  SInfoSinOperacionesFacturacionCaja =
    'No hay operaciones ni ajustes pendientes para el periodo indicado.';
  SInfoResultadoFacturacionCaja =
    'Documentos generados: %d. Operaciones incluidas: %d. Ajustes: %d.';
  SInfoSeleccionarProformaCaja =
    'Debe seleccionar una proforma de venta para imprimirla.';
  SInfoImprimirFacturaTraspaso =
    'Las facturas de traspasos TA se imprimen desde Venta mayor.';
  SInfoPeriodoFacturacionCajaSinDocumento =
    'El registro de periodo seleccionado no tiene un documento imprimible.';
  SErrorReferenciaProformaCajaInvalida =
    'No se ha podido identificar la proforma seleccionada.';
  SErrorCargaHistorialFacturasProforma =
    'No se ha podido cargar el historial de documentos y periodos: ' +
    'la lista vacía no significa que no haya nada facturado.' +
    sLineBreak + sLineBreak + '%s';
  SErrorEsquemaFacturasProforma =
    'Falta aplicar a la base de datos, en este orden:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak + 'Error de la consulta: %s';
  SAvisoPeriodoFacturacionCajaDuplicado =
    'Ya existe un registro con el mismo periodo, ámbito empresarial ' +
    'y modalidad.';
  SAvisoPeriodoFacturacionCajaSolapado =
    'El periodo indicado se solapa con otro registro de facturación.';
  SInfoIdempotenciaFacturacionCaja =
    'Las operaciones e ítems ya vinculados no volverán a facturarse.';
  SPreguntaContinuarPeriodoFacturacionCaja =
    '¿Desea revisar igualmente las operaciones pendientes y continuar?';
  STituloValoracionTraspasos =
    'Valoración de los traspasos a facturar';
  STextoValoracionTraspasos =
    'Los traspasos no pueden facturarse al precio de compra. Elige la base ' +
    '(PMP de la empresa emisora o precio de última compra), indica el ' +
    'porcentaje y simula: las líneas marcadas se facturarán al precio ' +
    'simulado y el resto a su precio base. Si cancelas no se genera ' +
    'ninguna factura.';
  SCaptionGenerarConPreciosValorados =
    'Generar facturas con estos precios';
  SCaptionUnidadesValoracionTraspasos = 'Unidades';
  SCaptionPrecioBaseValoracionTraspasos = 'PMP empresa';
  SCaptionPrecioValoradoValoracionTraspasos = 'Precio valorado';
  STituloInformeValoracionTraspasos =
    'Valoración simulada de traspasos';
  SFormatoIdentificacionValoracionTraspasos =
    'Traspasos de %s a %s del %s al %s';
  SInfoValoracionTraspasosCancelada =
    'Generación cancelada: no se ha facturado ningún traspaso.';
  STituloValoracionTraspasosVendidos =
    'Valoración de lo traspasado y vendido';
  STextoValoracionTraspasosVendidos =
    'Cada línea son las unidades que la tienda destino ha vendido de un ' +
    'traspaso y que todavía no se le han facturado. Elige la base (PMP de ' +
    'la empresa emisora o precio de última compra), indica el porcentaje y ' +
    'simula: las líneas marcadas se facturarán al precio simulado y el ' +
    'resto a su precio base. Si cancelas no se genera ninguna factura.';
  SCaptionUnidadesValoracionTraspasosVendidos = 'Uds. vendidas';
  STituloInformeValoracionTraspasosVendidos =
    'Valoración simulada de lo traspasado y vendido';
  SFormatoIdentificacionValoracionTraspasosVendidos =
    'Traspasado y vendido de %s en %s del %s al %s';

const
  cParamMargenMinimoTraspasos = 'appMargenMinimoTraspasos';

implementation

uses
  inLibMensajesVcl,
  inLibFacturasProforma, inMtoModalImpFacturasProforma,
  inMtoModalOpcionesDocumento, inLibMsgOpcionesDocumento,
  UniDataOpcionesDocumentoRepositorio,
  inLibFormatoMonetario, System.Math, dxCoreGraphics,
  inLibFacturasProformaValoracion,
  inLibInformeSimulacionValoracion,
  inMtoModalRevalorizacionInventario,
  inLibComprasSesionesIntf, inMtoModalDocsCreados,
  inMtoFacturasConsolidacionVcl, UniDataDestinoFacturaRepositorio,
  inMtoModalMensajeTexto, inLibMsgFacturas, UniDataFacturaRecibidaInterna;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoFacturasProforma.AplicarTraduccionActual;
var
  I: Integer;
begin
  inherited;
  if FControlesCreados then
  begin
    lblDesde.Caption := SProformaDesde;
    lblHasta.Caption := SProformaHasta;
    rgModalidad.Caption := SProformaModalidad;
    rgModalidad.Properties.Items[0].Caption := SProformaModoVentas;
    rgModalidad.Properties.Items[1].Caption := SProformaModoTraspasos;
    rgModalidad.Properties.Items[2].Caption := SProformaModoVendidos;
    chkCargarVales.Caption := SProformaCargarVales;
    btnGenerar.Caption := SProformaGenerar;
    btnRefrescar.Caption := SProformaRefrescar;
    btnImprimir.Caption := SProformaImprimir;
    btnConvertir.Caption := SProformaConvertir;
    btnCuadreInternas.Caption := SCaptionBotonCuadreFacturasInternas;
    ActualizarEstadoEmpresaDestino;
    for I := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
      cxGrdDBTabPrin.Columns[I].Caption := TituloColumnaProforma(
        cxGrdDBTabPrin.Columns[I].DataBinding.FieldName);
  end;
end;

procedure TfrmMtoFacturasProforma.FormCreate(Sender: TObject);
begin
  CrearControlesDinamicos;
  inherited;
  AplicarTraduccionActual;
end;

destructor TfrmMtoFacturasProforma.Destroy;
begin
  if Assigned(cbbEmpresaOrigen) then
    cbbEmpresaOrigen.Properties.ListSource := nil;
  if Assigned(cbbEmpresaDestino) then
    cbbEmpresaDestino.Properties.ListSource := nil;
  inherited;
end;

procedure TfrmMtoFacturasProforma.CrearControlesDinamicos;
var
  dHoy: TDateTime;
begin
  if not FControlesCreados then
  begin
    pnlFacturacion := TPanel.Create(Self);
    pnlFacturacion.Name := 'pnlFacturacion';
    pnlFacturacion.Caption := '';
    pnlFacturacion.Parent := tsLista;
    pnlFacturacion.Align := alTop;
    pnlFacturacion.Height := EscalarDpi(296);
    pnlFacturacion.BevelOuter := bvNone;
    pnlFacturacion.ParentBackground := True;
    pnlFacturacion.ParentColor := True;
    lblDesde := CrearEtiqueta(SProformaDesde, 12, 14);
    dteDesde := TcxDateEdit.Create(Self);
    dteDesde.Parent := pnlFacturacion;
    dteDesde.Left := EscalarDpi(64);
    dteDesde.Top := EscalarDpi(10);
    dteDesde.Width := EscalarDpi(118);
    lblHasta := CrearEtiqueta(SProformaHasta, 198, 14);
    dteHasta := TcxDateEdit.Create(Self);
    dteHasta.Parent := pnlFacturacion;
    dteHasta.Left := EscalarDpi(250);
    dteHasta.Top := EscalarDpi(10);
    dteHasta.Width := EscalarDpi(118);
    lblEmpresaOrigen := TcxLabel.Create(Self);
    lblEmpresaOrigen.Parent := pnlFacturacion;
    lblEmpresaOrigen.Left := EscalarDpi(388);
    lblEmpresaOrigen.Top := EscalarDpi(14);
    lblEmpresaOrigen.Caption := SProformaEmpresaOrigen;
    lblEmpresaOrigen.Transparent := True;
    cbbEmpresaOrigen := TcxLookupComboBox.Create(Self);
    cbbEmpresaOrigen.Parent := pnlFacturacion;
    cbbEmpresaOrigen.Left := EscalarDpi(506);
    cbbEmpresaOrigen.Top := EscalarDpi(10);
    cbbEmpresaOrigen.Width := EscalarDpi(330);
    cbbEmpresaOrigen.Properties.DropDownListStyle := lsFixedList;
    cbbEmpresaOrigen.Properties.KeyFieldNames := 'CODIGO_EMP_EMP';
    cbbEmpresaOrigen.Properties.ListFieldNames := 'RAZON_SOCIAL_EMP';
    cbbEmpresaOrigen.Properties.ListOptions.ShowHeader := False;
    lblEmpresaDestino := TcxLabel.Create(Self);
    lblEmpresaDestino.Parent := pnlFacturacion;
    lblEmpresaDestino.Left := EscalarDpi(388);
    lblEmpresaDestino.Top := EscalarDpi(52);
    lblEmpresaDestino.Caption := SProformaEmpresaDestino;
    lblEmpresaDestino.Transparent := True;
    cbbEmpresaDestino := TcxLookupComboBox.Create(Self);
    cbbEmpresaDestino.Parent := pnlFacturacion;
    cbbEmpresaDestino.Left := EscalarDpi(506);
    cbbEmpresaDestino.Top := EscalarDpi(48);
    cbbEmpresaDestino.Width := EscalarDpi(330);
    cbbEmpresaDestino.Properties.DropDownListStyle := lsFixedList;
    cbbEmpresaDestino.Properties.KeyFieldNames := 'CODIGO_EMP_EMP';
    cbbEmpresaDestino.Properties.ListFieldNames := 'RAZON_SOCIAL_EMP';
    cbbEmpresaDestino.Properties.ListOptions.ShowHeader := False;
    rgModalidad := TcxRadioGroup.Create(Self);
    rgModalidad.Name := 'rgModalidad';
    rgModalidad.Parent := pnlFacturacion;
    rgModalidad.Left := EscalarDpi(12);
    rgModalidad.Top := EscalarDpi(85);
    rgModalidad.Width := EscalarDpi(824);
    rgModalidad.Height := EscalarDpi(96);
    rgModalidad.Transparent := True;
    rgModalidad.LookAndFeel.NativeStyle := False;
    rgModalidad.Caption := SProformaModalidad;
    rgModalidad.Properties.Columns := 1;
    rgModalidad.Properties.Items.Add.Caption :=
      SProformaModoVentas;
    rgModalidad.Properties.Items.Add.Caption :=
      SProformaModoTraspasos;
    rgModalidad.Properties.Items.Add.Caption :=
      SProformaModoVendidos;
    rgModalidad.ItemIndex := 0;
    rgModalidad.Properties.OnEditValueChanged :=
      rgModalidadPropertiesEditValueChanged;
    chkCargarVales := TcxCheckBox.Create(Self);
    chkCargarVales.Parent := pnlFacturacion;
    chkCargarVales.Left := EscalarDpi(12);
    chkCargarVales.Top := EscalarDpi(185);
    chkCargarVales.Width := EscalarDpi(210);
    // Sin fondo propio ni estilo nativo, para que lo pinte el skin.
    chkCargarVales.Transparent := True;
    chkCargarVales.Style.LookAndFeel.NativeStyle := False;
    chkCargarVales.Caption := SProformaCargarVales;
    chkCargarVales.Checked := False;
    chkCargarVales.Properties.OnEditValueChanged :=
      rgModalidadPropertiesEditValueChanged;
    // Acciones en la barra derecha, como en Arqueos y Operaciones: a la
    // derecha del panel (Left 856) no se veian sin maximizar la ventana.
    btnGenerar := CrearBotonBarraDerecha(
      SProformaGenerar, 120, btnGenerarClick);
    btnRefrescar := CrearBotonBarraDerecha(
      SProformaRefrescar, 166, btnRefrescarClick);
    btnImprimir := CrearBotonBarraDerecha(
      SProformaImprimir, 212, btnImprimirClick);
    btnConvertir := CrearBotonBarraDerecha(
      SProformaConvertir, 258, btnConvertirClick);
    btnCuadreInternas := CrearBotonBarraDerecha(
      SCaptionBotonCuadreFacturasInternas, 304, btnCuadreInternasClick);
    lblExplicacion := TcxLabel.Create(Self);
    lblExplicacion.Parent := pnlFacturacion;
    lblExplicacion.Left := EscalarDpi(12);
    lblExplicacion.Top := EscalarDpi(218);
    lblExplicacion.AutoSize := False;
    lblExplicacion.Width := EscalarDpi(824);
    lblExplicacion.Height := EscalarDpi(66);
    lblExplicacion.Properties.WordWrap := True;
    lblExplicacion.Caption :=
      SProformaAyuda;
    lblExplicacion.Transparent := True;
    dHoy := Date;
    dteDesde.Date := EncodeDate(
      YearOf(dHoy), ((MonthOf(dHoy) - 1) div 3) * 3 + 1, 1);
    dteHasta.Date := dHoy;
    ActualizarEstadoEmpresaDestino;
    FControlesCreados := True;
  end;
end;

function TfrmMtoFacturasProforma.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoFacturasProforma.CrearBotonBarraDerecha(
  const ACaption: string; ATop: Integer;
  AOnClick: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Self);
  Result.Parent := pButtonRightBar;
  Result.Left := 1;
  Result.Top := EscalarDpi(ATop);
  Result.Width := pButtonRightBar.ClientWidth - 2;
  Result.Height := EscalarDpi(42);
  Result.WordWrap := True;
  Result.Caption := ACaption;
  Result.OnClick := AOnClick;
end;

function TfrmMtoFacturasProforma.CrearEtiqueta(
  const ATexto: string; AIzq, ATop: Integer): TcxLabel;
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent := pnlFacturacion;
  lbl.Left := EscalarDpi(AIzq);
  lbl.Top := EscalarDpi(ATop);
  lbl.Caption := ATexto;
  lbl.Transparent := True;
  Result := lbl;
end;

function TfrmMtoFacturasProforma.CrearColumna(
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := cxGrdDBTabPrin.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
  if (ACampo = 'ESTADO_DOCUMENTO') or (ACampo = 'ESTADO_PERIODO') then
    Result.OnGetDisplayText := MostrarEstadoProforma;
end;

procedure TfrmMtoFacturasProforma.MostrarEstadoProforma(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var ATexto: string);
begin
  ATexto := TextoValorDocumento(TcxGridDBColumn(Sender).
    DataBinding.FieldName, ATexto);
end;

procedure TfrmMtoFacturasProforma.CrearColumnas;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna('TIPO_DOCUMENTO', SProformaColTipo, 55);
    CrearColumna('ID_PERIODO', SProformaColIdPeriodo, 80);
    CrearColumna('ESTADO_PERIODO', SProformaColEstadoPeriodo, 110);
    CrearColumna('SERIE_DOCUMENTO', SProformaColSerie, 80);
    CrearColumna('NUMERO_DOCUMENTO', SProformaColNumero, 100);
    CrearColumna('FECHA_DOCUMENTO', SProformaColFecha, 90);
    CrearColumna('FECHA_DESDE', SProformaColDesde, 100);
    CrearColumna('FECHA_HASTA', SProformaColHasta, 100);
    CrearColumna('EMPRESA_ORIGEN', SProformaEmpresaOrigen, 210);
    CrearColumna('EMPRESA_DESTINO', SProformaEmpresaDestino, 210);
    CrearColumna('ESTADO_DOCUMENTO', SProformaColEstado, 100);
    CrearColumna('CANTIDAD_OPERACIONES', SProformaColOperaciones, 90);
    CrearColumna('CANTIDAD_AJUSTES', SProformaColAjustes, 75);
    FormatearColumnaMonetaria(
      CrearColumna('TOTAL_BASE', SProformaColBase, 100));
    FormatearColumnaMonetaria(
      CrearColumna('TOTAL_IMPUESTOS', SProformaColImpuestos, 100));
    FormatearColumnaMonetaria(
      CrearColumna('TOTAL_DOCUMENTO', SProformaColTotal, 110));
  end;
end;

procedure TfrmMtoFacturasProforma.ActualizarEstadoEmpresaDestino;
begin
  cbbEmpresaDestino.Enabled :=
    ObtenerModalidad in
      [mfcTraspaso, mfcTraspasoVendido, mfcValesRecogidos];
  if not cbbEmpresaDestino.Enabled then
    cbbEmpresaDestino.EditValue := Null;
  chkCargarVales.Enabled := ObtenerModalidad = mfcTraspasoVendido;
  if chkCargarVales.Enabled and chkCargarVales.Checked then
  begin
    lblEmpresaOrigen.Caption := SProformaEmpresaOrigen;
    lblEmpresaDestino.Caption := SProformaEmpresaDestino;
    lblExplicacion.Caption :=
      SAyudaEmisoraTraspasoVendido + sLineBreak + SProformaAyudaVales;
  end
  else
  begin
    lblEmpresaOrigen.Caption := SProformaEmpresaOrigen;
    lblEmpresaDestino.Caption := SProformaEmpresaDestino;
    lblExplicacion.Caption :=
      SProformaAyuda;
  end;
  AjustarDesplegablesEmpresa;
end;

procedure TfrmMtoFacturasProforma.AjustarDesplegablesEmpresa;
const
  // A 96 ppp: posición original de los desplegables y hueco tras el
  // rótulo.
  IZQUIERDA_DESPLEGABLE = 506;
  HUECO_ROTULO = 8;
var
  iRotulo: Integer;
  iIzquierda: Integer;
  iDerecha: Integer;
begin
  // Un rótulo traducido largo (ca-ES «Empresa destinació») no debe quedar
  // tapado: el desplegable se corre sin pasar del borde derecho
  // (FZ-ISSUE-739).
  iRotulo := Max(
    cxTextWidth(lblEmpresaOrigen.Style.GetVisibleFont,
      lblEmpresaOrigen.Caption),
    cxTextWidth(lblEmpresaDestino.Style.GetVisibleFont,
      lblEmpresaDestino.Caption));
  iDerecha := cbbEmpresaOrigen.Left + cbbEmpresaOrigen.Width;
  iIzquierda := Max(EscalarDpi(IZQUIERDA_DESPLEGABLE),
    lblEmpresaOrigen.Left + iRotulo + EscalarDpi(HUECO_ROTULO));
  cbbEmpresaOrigen.Left := iIzquierda;
  cbbEmpresaOrigen.Width := iDerecha - iIzquierda;
  cbbEmpresaDestino.Left := iIzquierda;
  cbbEmpresaDestino.Width := iDerecha - iIzquierda;
end;

procedure TfrmMtoFacturasProforma.EmpresaOrigenCambiada(Sender: TObject);
begin
  if Assigned(dmmFacturasProforma) then
  begin
    if VarToStr(cbbEmpresaDestino.EditValue) =
       VarToStr(cbbEmpresaOrigen.EditValue) then
      cbbEmpresaDestino.EditValue := Null;
    dmmFacturasProforma.AbrirEmpresasDestino(
      VarToStr(cbbEmpresaOrigen.EditValue));
  end;
end;

procedure TfrmMtoFacturasProforma.CrearTablaPrincipal;
begin
  inherited;
  dmmFacturasProforma := tdmDataModule as TdmFacturasProforma;
  // El selector debe estar disponible aunque falle la carga del historial.
  dmmFacturasProforma.AbrirEmpresas;
  pkFieldName := 'CLAVE_DOCUMENTO';
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  tsFicha.TabVisible := False;
  nvNavegador.Visible := False;
  cbbEmpresaOrigen.Properties.ListSource :=
    dmmFacturasProforma.dsEmpresas;
  cbbEmpresaDestino.Properties.ListSource :=
    dmmFacturasProforma.dsEmpresasDestino;
  cbbEmpresaOrigen.EditValue := UbicacionSesion.Empresa;
  cbbEmpresaDestino.EditValue := Null;
  cbbEmpresaOrigen.Properties.OnEditValueChanged := EmpresaOrigenCambiada;
  EmpresaOrigenCambiada(nil);
  ActualizarEstadoEmpresaDestino;
  CrearColumnas;
end;

// Margen mínimo exigible al facturar a una empresa vinculada. El
// parámetro admite un porcentaje único ('25') o tramos por meses de
// antigüedad del género ('0:25;6:15;12:5'), porque la moda de temporadas
// pasadas vale menos también entre mayoristas.
function TfrmMtoFacturasProforma.EscalaMargenMinimoTraspasos:
  TEscalaMargenMinimo;
begin
  Result := AnalizarEscalaMargenMinimo(
    ParametrosApp.GetString(cParamMargenMinimoTraspasos, ''));
end;

function TfrmMtoFacturasProforma.ObtenerModalidad:
  TModalidadFacturacionCaja;
begin
  Result := mfcVenta;
  if rgModalidad.ItemIndex = 1 then
    Result := mfcTraspaso
  else if rgModalidad.ItemIndex = 2 then
    Result := mfcTraspasoVendido;
end;

function TfrmMtoFacturasProforma.PrepararSolicitud:
  TSolicitudFacturacionCaja;
begin
  Result.FechaDesde := Trunc(dteDesde.Date);
  Result.FechaHasta := Trunc(dteHasta.Date);
  Result.CodigoEmpresaOrigen :=
    Trim(VarToStr(cbbEmpresaOrigen.EditValue));
  Result.CodigoEmpresaDestino :=
    Trim(VarToStr(cbbEmpresaDestino.EditValue));
  Result.Usuario := Trim(IdentidadSesion.Usuario);
end;

procedure TfrmMtoFacturasProforma.
  rgModalidadPropertiesEditValueChanged(Sender: TObject);
begin
  ActualizarEstadoEmpresaDestino;
end;

function TfrmMtoFacturasProforma.ConfirmarGeneracion(
  AModalidad: TModalidadFacturacionCaja): Boolean;
var
  sPregunta: string;
begin
  sPregunta := SPreguntaGenerarProformaVenta;
  if AModalidad = mfcTraspaso then
    sPregunta := SPreguntaGenerarFacturaTraspaso
  else if AModalidad = mfcTraspasoVendido then
    sPregunta := SPreguntaGenerarFacturaTraspasoVendido;
  if (AModalidad = mfcTraspasoVendido) and
     chkCargarVales.Checked then
    sPregunta := sPregunta + sLineBreak + sLineBreak +
      SPreguntaGenerarProformaVales;
  Result := MessageDlg_fza(
    sPregunta, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

function TfrmMtoFacturasProforma.ConfirmarRevisionPeriodo(
  const ARevision: TRevisionPeriodoFacturacionCaja): Boolean;
var
  sAviso: string;
begin
  Result := True;
  if ARevision.EsDuplicado or ARevision.EsSolapado then
  begin
    sAviso := '';
    if ARevision.EsDuplicado then
      sAviso := SAvisoPeriodoFacturacionCajaDuplicado;
    if ARevision.EsSolapado then
    begin
      if sAviso <> '' then
        sAviso := sAviso + sLineBreak;
      sAviso := sAviso + SAvisoPeriodoFacturacionCajaSolapado;
    end;
    if Trim(ARevision.Descripcion) <> '' then
      sAviso := sAviso + sLineBreak + Trim(ARevision.Descripcion);
    sAviso := sAviso + sLineBreak + sLineBreak +
      SInfoIdempotenciaFacturacionCaja + sLineBreak +
      SPreguntaContinuarPeriodoFacturacionCaja;
    Result := MessageDlg_fza(
      sAviso, mtWarning, [mbYes, mbNo], 0) = mrYes;
  end;
end;

function TfrmMtoFacturasProforma.TextoResultado(
  const AResultado: TResultadoFacturacionCaja): string;
begin
  Result := Trim(AResultado.Descripcion);
  if Result = '' then
  begin
    if (AResultado.CantidadDocumentos = 0) and
       (AResultado.CantidadOperaciones = 0) and
       (AResultado.CantidadAjustes = 0) then
      Result := SInfoSinOperacionesFacturacionCaja
    else
      Result := Format(
        SInfoResultadoFacturacionCaja,
        [AResultado.CantidadDocumentos,
         AResultado.CantidadOperaciones,
         AResultado.CantidadAjustes]);
  end;
end;

function TfrmMtoFacturasProforma.RevisarPeriodo(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TRevisionPeriodoFacturacionCaja;
var
  oServicio: TFacturadorOperacionesCaja;
begin
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio(ParametrosApp));
  try
    Result := oServicio.RevisarPeriodo(AModalidad, ASolicitud);
  finally
    FreeAndNil(oServicio);
  end;
end;

function TfrmMtoFacturasProforma.ValorarTraspasos(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja;
  out AValoracion: TValoracionTraspasos): Boolean;
var
  oLineas   : TLineasTraspasoPendientes;
  oOpciones : TOpcionesRevalorizacionInventario;
  oResultado: TResultadoRevalorizacionInventario;
  oServicio : TFacturadorOperacionesCaja;
  sFormato  : string;
begin
  AValoracion := nil;
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio(ParametrosApp));
  try
    Screen.Cursor := crHourGlass;
    try
      oLineas := oServicio.ObtenerLineasAValorar(AModalidad, ASolicitud);
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    FreeAndNil(oServicio);
  end;
  // Sin líneas pendientes la generación sigue y avisa de que no hay nada
  // que facturar; el periodo vacío no se guarda (FZ-ISSUE-026).
  Result := Length(oLineas) = 0;
  if not Result then
  begin
    oOpciones := Default(TOpcionesRevalorizacionInventario);
    oOpciones.Titulo := STituloValoracionTraspasos;
    oOpciones.Explicacion := STextoValoracionTraspasos;
    oOpciones.CaptionAceptar := SCaptionGenerarConPreciosValorados;
    oOpciones.CaptionUnidades := SCaptionUnidadesValoracionTraspasos;
    oOpciones.CaptionPrecioActual := SCaptionPrecioBaseValoracionTraspasos;
    oOpciones.CaptionPrecioSimulado :=
      SCaptionPrecioValoradoValoracionTraspasos;
    oOpciones.TituloInforme := STituloInformeValoracionTraspasos;
    oOpciones.CaptionPrecioMedioInforme :=
      SCaptionColPrecioMedioEmpresaInformeValoracion;
    oOpciones.OcultarUnidadesFinales := True;
    oOpciones.PreseleccionarTodas := True;
    oOpciones.MostrarMargenMinimo := True;
    oOpciones.EscalaMargenMinimo := EscalaMargenMinimoTraspasos;
    oOpciones.ImportesACentimos := True;
    sFormato := SFormatoIdentificacionValoracionTraspasos;
    if AModalidad = mfcTraspasoVendido then
    begin
      oOpciones.Titulo := STituloValoracionTraspasosVendidos;
      oOpciones.Explicacion := STextoValoracionTraspasosVendidos;
      oOpciones.CaptionUnidades :=
        SCaptionUnidadesValoracionTraspasosVendidos;
      oOpciones.TituloInforme := STituloInformeValoracionTraspasosVendidos;
      sFormato := SFormatoIdentificacionValoracionTraspasosVendidos;
    end;
    oResultado := TfrmModalRevalorizacionInventario.Ejecutar(
      Self,
      ConvertirLineasTraspasoARevalorizacion(oLineas),
      Format(sFormato,
        [ASolicitud.CodigoEmpresaOrigen,
         ASolicitud.CodigoEmpresaDestino,
         FormatDateTime('dd/mm/yyyy', ASolicitud.FechaDesde),
         FormatDateTime('dd/mm/yyyy', ASolicitud.FechaHasta)]),
      oOpciones);
    Result := oResultado.Aceptado;
    if Result then
      AValoracion := ConstruirValoracionTraspasos(
        oLineas, oResultado.Simulacion)
    else
      ShowMessage_fza(SInfoValoracionTraspasosCancelada);
  end;
end;

procedure TfrmMtoFacturasProforma.EjecutarGeneracion(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja;
  const AValoracion: TValoracionTraspasos);
var
  oResultado: TResultadoFacturacionCaja;
  oResultadoVales: TResultadoFacturacionCaja;
  oServicio : TFacturadorOperacionesCaja;
begin
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio(ParametrosApp));
  try
    oResultado := oServicio.Ejecutar(AModalidad, ASolicitud, AValoracion);
    if (AModalidad = mfcTraspasoVendido) and
       chkCargarVales.Checked then
    begin
      try
        oResultadoVales := oServicio.Ejecutar(
          mfcValesRecogidos, ASolicitud);
      except
        on E: Exception do
        begin
          RefrescarHistorial;
          raise Exception.Create(
            TextoResultado(oResultado) + sLineBreak +
            'La carga de vales no se completó: ' + E.Message);
        end;
      end;
      if oResultadoVales.CantidadDocumentos > 0 then
        oResultado.Descripcion := TextoResultado(oResultado) +
          sLineBreak + oResultadoVales.Descripcion;
    end;
    RefrescarHistorial;
    MostrarResultado(oResultado);
  finally
    FreeAndNil(oServicio);
  end;
end;

// Las facturas TA/TV salen en "Documentos creados" con Ir al documento;
// el resto (proformas de venta, propuestas de vales) sólo con el aviso.
procedure TfrmMtoFacturasProforma.MostrarResultado(
  const AResultado: TResultadoFacturacionCaja);
var
  aDocumentos: TDocumentosMaterializados;
  oSeleccionado: TDocumentoMaterializado;
  i: Integer;
begin
  if Length(AResultado.Facturas) = 0 then
  begin
    ShowMessage_fza(TextoResultado(AResultado));
    Exit;
  end;
  SetLength(aDocumentos, Length(AResultado.Facturas));
  for i := 0 to High(AResultado.Facturas) do
  begin
    aDocumentos[i].Tipo := SNombreFacturaCreada;
    aDocumentos[i].Serie := AResultado.Facturas[i].Serie;
    aDocumentos[i].Numero := AResultado.Facturas[i].Numero;
    aDocumentos[i].Almacen := AResultado.Facturas[i].Almacen;
  end;
  if TfrmModalDocsCreados.Seleccionar(Self, aDocumentos, oSeleccionado,
       TextoResultado(AResultado)) then
    AbrirFacturaCreadaVcl(Self.Owner,
      CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
      oSeleccionado.Serie, oSeleccionado.Numero, False);
end;

function TfrmMtoFacturasProforma.TipoFacturaOpcionesDocumento:
  TTipoOpcionesDocumento;
begin
  Result := Default(TTipoOpcionesDocumento);
  Result.Codigo := 'FC';
  Result.Subtipo := 'NORMAL';
  Result.Nombre := SNombreFacturaVentaOpcionesDocumento;
end;

// Fecha, forma de pago y serie de las facturas TA/TV. Puede salir una
// factura por almacén: la serie vacía deja la de cada almacén y el número
// sale siempre del contador.
function TfrmMtoFacturasProforma.SolicitarOpcionesFacturasTraspaso(
  var ASolicitud: TSolicitudFacturacionCaja): Boolean;
var
  oConfig: TConfiguracionOpcionesDocumento;
  oOpciones: TOpcionesDocumento;
begin
  oConfig := Default(TConfiguracionOpcionesDocumento);
  oConfig.Titulo := STituloFacturasTraspasoOpcionesDocumento;
  oConfig.Tipos := [TipoFacturaOpcionesDocumento];
  oConfig.Propuesta.Empresa := ASolicitud.CodigoEmpresaOrigen;
  oConfig.Propuesta.Tipo := 'FC';
  oConfig.Propuesta.Fecha := ASolicitud.FechaHasta;
  oConfig.Propuesta.FormaPago := FORMA_PAGO_FACTURA_CAJA;
  oConfig.Visibles := [codEmpresa, codSerie, codNumero, codFecha,
    codFormaPago];
  oConfig.Fijos := [codEmpresa];
  oConfig.SerieOpcional := True;
  Result := TfrmModalOpcionesDocumento.Solicitar(Self,
    CrearLectorOpcionesDocumentoUniDAC(ConexionPrincipal), oConfig,
    oOpciones);
  if Result then
  begin
    ASolicitud.SerieFactura := oOpciones.Serie;
    ASolicitud.FechaFactura := oOpciones.Fecha;
    ASolicitud.FormaPago := oOpciones.FormaPago;
  end;
end;

procedure TfrmMtoFacturasProforma.btnGenerarClick(Sender: TObject);
var
  eModalidad : TModalidadFacturacionCaja;
  oRevision  : TRevisionPeriodoFacturacionCaja;
  oSolicitud : TSolicitudFacturacionCaja;
  oValoracion: TValoracionTraspasos;
begin
  eModalidad := ObtenerModalidad;
  oSolicitud := PrepararSolicitud;
  btnGenerar.Enabled := False;
  try
    try
      oRevision := RevisarPeriodo(eModalidad, oSolicitud);
      if ConfirmarRevisionPeriodo(oRevision) and
         ConfirmarGeneracion(eModalidad) then
      begin
        oValoracion := nil;
        // Los traspasos se valoran (margen sobre PMP o última compra) en el
        // mismo modal que inventarios antes de facturarlos; en TV lo que se
        // valora son las unidades ya vendidas en la tienda destino.
        if not (eModalidad in [mfcTraspaso, mfcTraspasoVendido]) or
           (ValorarTraspasos(eModalidad, oSolicitud, oValoracion) and
            SolicitarOpcionesFacturasTraspaso(oSolicitud)) then
          EjecutarGeneracion(eModalidad, oSolicitud, oValoracion);
      end;
    except
      on E: Exception do
        ShowMessage_fza(E.Message);
    end;
  finally
    btnGenerar.Enabled := True;
  end;
end;

// Si la carga inicial falló la consulta sigue cerrada y Refresh no haría
// nada: se vuelve a abrir, y un nuevo fallo vuelve a avisar.
procedure TfrmMtoFacturasProforma.RefrescarHistorial;
begin
  if Assigned(dmmFacturasProforma) then
  begin
    if dmmFacturasProforma.unqryTablaG.Active then
      dmmFacturasProforma.RefrescarDocumentos
    else
      AbrirTablaPrincipal(False);
  end;
end;

procedure TfrmMtoFacturasProforma.TrasErrorPrecargaAsync(
  const AError: string);
var
  sPendientes: string;
begin
  inherited;
  sPendientes := '';
  if Assigned(dmmFacturasProforma) then
    try
      sPendientes := dmmFacturasProforma.ScriptsEsquemaPendientes;
    except
      on E: Exception do
        RegistroLog.RegistrarError(
          '[ScriptsEsquemaPendientes] ' + Self.Name + ': ' + E.Message);
    end;
  if sPendientes <> '' then
    ShowMessage_fza(Format(SErrorEsquemaFacturasProforma,
      [sPendientes, AError]))
  else
    ShowMessage_fza(Format(SErrorCargaHistorialFacturasProforma,
      [AError]));
end;

// FZ-ISSUE-358: emitidas frente a recibidas entre las empresas del grupo,
// en las fechas del periodo de la pantalla.
// FZ-ISSUE-389: si falta alguna recibida, ofrece registrarla aquí mismo y
// vuelve a mostrar el cuadre.
procedure TfrmMtoFacturasProforma.btnCuadreInternasClick(Sender: TObject);
var
  aLineas   : TLineasCuadreFacturasInternas;
  iSin      : Integer;
  sResultado: string;
  oCuadre: TfrmModalMensajeTexto;
  oRegistrar: TcxButton;
  iAccion: Integer;
begin
  try
    aLineas := CargarCuadreFacturasInternas(ConexionPrincipal,
      dteDesde.Date, dteHasta.Date);
    iSin := ContarSinRecibida(aLineas);
    oCuadre := TfrmModalMensajeTexto.Create(Self);
    try
      oCuadre.Caption := STituloCuadreFacturasInternas;
      oCuadre.mTexto.Text := TextoCuadreFacturasInternas(
        aLineas, dteDesde.Date, dteHasta.Date);
      if iSin > 0 then
      begin
        oCuadre.Constraints.MinWidth := oCuadre.Width;
        oRegistrar := TcxButton.Create(oCuadre);
        oRegistrar.Parent := oCuadre.pnlBotones;
        oRegistrar.SetBounds(12 * oCuadre.CurrentPPI div 96,
          oCuadre.btnCerrar.Top, 290 * oCuadre.CurrentPPI div 96,
          oCuadre.btnCerrar.Height);
        oRegistrar.Caption := SCaptionRegistrarRecibidasPendientes;
        oRegistrar.ModalResult := mrYes;
      end;
      iAccion := oCuadre.ShowModal;
    finally
      oCuadre.Free;
    end;
    if (iAccion = mrYes) and (iSin > 0) and
       (MessageDlg_fza(Format(SPreguntaRegistrarRecibidasPendientes,
          [iSin]), mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    begin
      sResultado := RegistrarRecibidasPendientes(ConexionPrincipal,
        aLineas, Trim(IdentidadSesion.Usuario));
      aLineas := CargarCuadreFacturasInternas(ConexionPrincipal,
        dteDesde.Date, dteHasta.Date);
      TfrmModalMensajeTexto.Mostrar(Self,
        STituloRecibidasRegistradas,
        sResultado + sLineBreak + sLineBreak +
        TextoCuadreFacturasInternas(aLineas, dteDesde.Date,
          dteHasta.Date));
    end;
  except
    on E: Exception do
      ShowMessage_fza(E.Message);
  end;
end;

procedure TfrmMtoFacturasProforma.btnRefrescarClick(Sender: TObject);
begin
  try
    RefrescarHistorial;
  except
    on E: Exception do
      ShowMessage_fza(Format(SErrorCargaHistorialFacturasProforma,
        [E.Message]));
  end;
end;

procedure TfrmMtoFacturasProforma.ImprimirSeleccion;
var
  iIdProforma: Int64;
  sClave     : string;
  sTipo      : string;
begin
  if (not Assigned(dsTablaG.DataSet)) or dsTablaG.DataSet.IsEmpty then
    ShowMessage_fza(SInfoSeleccionarProformaCaja)
  else
  begin
    sClave := dsTablaG.DataSet.FieldByName(
      'CLAVE_DOCUMENTO').AsString;
    sTipo := dsTablaG.DataSet.FieldByName(
      'TIPO_DOCUMENTO').AsString;
    if SameText(Copy(sClave, 1, 4), 'PER-') then
      ShowMessage_fza(SInfoPeriodoFacturacionCajaSinDocumento)
    else if not (SameText(sTipo, 'VE') or
                 SameText(sTipo, 'VR')) then
      ShowMessage_fza(SInfoImprimirFacturaTraspaso)
    else
    begin
      iIdProforma := StrToInt64Def(Copy(sClave, 4, MaxInt), 0);
      if iIdProforma > 0 then
        TfrmPrintFacturasProforma.Mostrar(Self, iIdProforma)
      else
        ShowMessage_fza(SErrorReferenciaProformaCajaInvalida);
    end;
  end;
end;

procedure TfrmMtoFacturasProforma.btnImprimirClick(Sender: TObject);
begin
  ImprimirSeleccion;
end;

function TfrmMtoFacturasProforma.ConfigurarConversionVales(
  const APropuesta: TOpcionesDocumento): TConfiguracionOpcionesDocumento;
begin
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := STituloConvertirProformaValesOpcionesDocumento;
  Result.Tipos := [TipoFacturaOpcionesDocumento];
  Result.Propuesta := APropuesta;
  // Dejar que el diálogo proponga la serie NORMAL filtrada.
  Result.Propuesta.Serie := '';
  // Emite la empresa con saldo a favor: no se elige.
  Result.Visibles := [codEmpresa, codSerie, codNumero, codFecha,
    codFormaPago];
  Result.Fijos := [codEmpresa];
  Result.PermiteNumeroManual := True;
end;

procedure TfrmMtoFacturasProforma.ConvertirProformaVales(
  AIdProforma: Int64);
var
  oServicio: TFacturadorOperacionesCaja;
  oOpciones: TOpcionesDocumento;
  sFactura: string;
begin
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio(ParametrosApp));
  try
    if TfrmModalOpcionesDocumento.Solicitar(Self,
         CrearLectorOpcionesDocumentoUniDAC(ConexionPrincipal),
         ConfigurarConversionVales(
           oServicio.PrepararConversionProformaVales(AIdProforma)),
         oOpciones) then
    begin
      sFactura := oServicio.ConvertirProformaVales(AIdProforma, oOpciones,
        Trim(IdentidadSesion.Usuario));
      RefrescarHistorial;
      ShowMessage_fza(Format(SInfoFacturaValesGenerada, [sFactura]));
    end;
  finally
    FreeAndNil(oServicio);
  end;
end;

procedure TfrmMtoFacturasProforma.btnConvertirClick(Sender: TObject);
var
  sClave: string;
begin
  if (not Assigned(dsTablaG.DataSet)) or dsTablaG.DataSet.IsEmpty then
    ShowMessage_fza(SInfoSeleccionarProformaVales)
  else
  begin
    sClave := dsTablaG.DataSet.FieldByName(
      'CLAVE_DOCUMENTO').AsString;
    if not SameText(Copy(sClave, 1, 3), 'VR-') then
      ShowMessage_fza(SInfoSeleccionarProformaVales)
    else if MessageDlg_fza(SPreguntaConvertirProformaVales,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      try
        ConvertirProformaVales(StrToInt64Def(Copy(sClave, 4, MaxInt), 0));
      except
        on E: Exception do
          ShowMessage_fza(E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasProforma.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

initialization
  RegistrarPantalla(TfrmMtoFacturasProforma);
  ForceReferenceToClass(TfrmMtoFacturasProforma);
end.
