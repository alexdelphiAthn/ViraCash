{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpMovVentasArt                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Movimientos de ventas por artículos y fechas"     }
{    (ranking de ventas, FastReport). Sin agrupaciones muestra el artículo.    }
{    Con niveles sin ART, el último es el detalle agregado y los anteriores   }
{    son grupos exteriores. Si se marca ART conserva su desglose. Incluye las }
{    entradas y venta del periodo y los márgenes. Se apoya en                 }
{    el SP PRC_GET_MOV_VENTAS_ART (ver                                         }
{    DESARROLLOS EN CURSO/movimientos_ventas_articulos.sql).                   }
{                                                                              }
{    Hereda de TfrmPrintMultiFiltro: reutiliza las pestañas de filtros         }
{    múltiples (almacenes / familias / proveedores / temporadas / artículos /  }
{    fechas) y la de agrupaciones. Añade "Inicio compras", la selección de     }
{    impuestos y la ordenación, además de la plantilla y la consulta.          }
{******************************************************************************}
unit inMtoModalImpMovVentasArt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxRadioGroup,
  cxCheckListBox, cxCheckBox, cxCustomListBox,
  cxClasses, dxSkinsForm, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab, cxLocalization,
  inMtoPreviewExcel,
  inLibInformeMovimientosVentasArticuloPersistenciaIntf,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintMovVentasArt = class(TfrmPrintMultiFiltro)
    fxdsMovVentas: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FConexionMovimientos: TUniConnection;
    FRepositorioMovimientos:
      IRepositorioInformeMovimientosVentasArticulo;
    FResultadoMovimientos: IResultadoInformeMovimientosVentasArticulo;
    FNivelDetalleAgrupacion: Integer;
    FResumenAgrupado: Boolean;
    FchkIniCompras: TcxCheckBox;   // activa la fecha inicial de las entradas
    // fecha desde la que se suman albaranes y, en modo local, traspasos
    FdteIniCompras: TcxDateEdit;
    FchkEntradasGlobales: TcxCheckBox;
    // True cuando el usuario ha cambiado la casilla a mano; mientras no,
    // sigue la seleccion de almacenes (FZ-ISSUE-935).
    FEntradasGlobalesManual: Boolean;
    FAjustandoEntradasGlobales: Boolean;
    FchkSoloVentas: TcxCheckBox;   // 'solo artículos con ventas' en el periodo
    FchkConImpuestos: TcxCheckBox;
    FclbOrden: TcxCheckListBox;
    FrgSentidoOrden: TcxRadioGroup;
    // Crea el control de "Inicio compras" sobre la pestaña de fechas.
    procedure CrearControlesPropios;
    procedure CrearControlesOrdenacion;
    procedure CrearAccesosRanking;
    procedure AplicarRanking(Sender: TObject);
    procedure chkIniComprasChange(Sender: TObject);
    procedure chkEntradasGlobalesChange(Sender: TObject);
    procedure AjustarEntradasGlobales;
    procedure OrdenClickCheck(Sender: TObject; AIndex: Integer;
      APrevState, ANewState: TcxCheckBoxState);
    function OrdenSeleccionado(out AOrden: TOrdenMovVentasArt): Boolean;
    // Exportación a Excel propia (sustituye al export FastReport del base).
    procedure ExportarExcelMovVentas(Sender: TObject);
    // Genera la hoja por lotes refrescando el detalle de la espera.
    procedure GenerarHojaExcelMovVentas(APreview: TfrmMtoPreviewExcel);
    procedure MostrarPreviewExcel(APreview: TfrmMtoPreviewExcel);
    // Handler de OnBeforePrint: fotos + ocultar bandas de grupo inactivas.
    procedure ReportBeforePrint(Component: TfrxReportComponent);
    procedure CompletarSubtotales;
    procedure ActualizarFormulasPorcentajes;
    procedure IncluirDetalleOcultoEnAcumulados;
    procedure PrepararMovimientosEnSegundoPlano(
      const ACriterios: TCriteriosInformeMovimientosVentasArticulo);
    // Adapta el detalle a procedimientos antiguos sin color o talla.
    procedure ConfigurarDetalleArticuloAtributos;
    // Precarga en bloque las fotos de los artículos del resultado (1 consulta).
    procedure PrecargarFotosArticulos;
    // Ruta de la miniatura de un artículo para el Excel ('' sin foto).
    function RutaFotoArticulo(const ACodigoArticulo: string): string;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure AlmacenesCambiados; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    procedure DoShow; override;
    // Añade al detalle de la espera el artículo que se está volcando.
    function DetalleProgresoInforme: string; override;
  public
    destructor Destroy; override;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgInformesCliente,
  System.Math, System.StrUtils, System.Threading,
  inLibMovVentasArtExcel, inLibMsgVentas,
  inLibMsgComun, inLibConexionesIntf,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx, dxSpreadSheet,
  inLibFotos, inLibFotosTipos, inLibVentanaEspera,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  UniDataInformeMovimientosVentasArticuloRepositorio,
  inLibResumenSeleccionesVcl;

const
  // Registros por lote al generar la hoja de cálculo; entre lotes se
  // refresca el detalle de la ventana de espera.
  FILAS_POR_LOTE_EXCEL = 200;

{ TfrmPrintMovVentasArt }

function TfrmPrintMovVentasArt.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas,
             frArticulos];
end;

procedure TfrmPrintMovVentasArt.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    Caption := STituloMovimientosVentasFacturadas;
    Hint := SAlcanceVentasFacturadasInforme;
    ShowHint := True;
    CrearControlesPropios;
    // El botón Excel del base exporta el FastReport a XLSX (farragoso); lo
    // redirigimos a una exportación limpia con el mismo layout que el informe.
    btnExcel.OnClick := ExportarExcelMovVentas;
    FInicializado := True;
  end;
end;

procedure TfrmPrintMovVentasArt.CrearControlesPropios;
begin
  if TabFechas <> nil then
  begin
    // Por defecto el ranking mira las ventas del AÑO en curso (no del mes):
    // las entradas son de siempre, así que un periodo corto deja casi todo a
    // cero. El base pone el 1 del mes; aquí lo ampliamos al 1 de enero.
    if DteDesde <> nil then
      DteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
    // "Inicio compras" limita la fecha desde la que se suman las entradas.
    // Desmarcado conserva todo el histórico de entradas.
    FchkIniCompras := TcxCheckBox.Create(Self);
    FchkIniCompras.Parent    := TabFechas;
    FchkIniCompras.Left      := 220;
    FchkIniCompras.Top       := 16;
    FchkIniCompras.Width     := 210;
    FchkIniCompras.Caption   := SCaptionFiltrarInicioCompras;
    FchkIniCompras.Properties.OnEditValueChanged := chkIniComprasChange;
    FdteIniCompras := TcxDateEdit.Create(Self);
    FdteIniCompras.Parent  := TabFechas;
    FdteIniCompras.Left    := 220;
    FdteIniCompras.Top     := 40;
    FdteIniCompras.Width   := 160;
    FdteIniCompras.Date    := EncodeDate(YearOf(Date), 1, 1);
    FdteIniCompras.Enabled := False;
    // Global: albaranes AC/AE de toda la empresa. Local: albaranes y
    // traspasos de entrada de los almacenes seleccionados.
    FchkEntradasGlobales := TcxCheckBox.Create(Self);
    FchkEntradasGlobales.Parent := TabFechas;
    FchkEntradasGlobales.Left := FchkIniCompras.Left;
    FchkEntradasGlobales.Top := 72;
    FchkEntradasGlobales.Width := 210;
    FchkEntradasGlobales.Caption :=
      SCaptionEntradasGlobalesMovimientosVentas;
    FchkEntradasGlobales.Checked := True;
    FchkEntradasGlobales.Properties.OnEditValueChanged :=
      chkEntradasGlobalesChange;
    // "Solo artículos con ventas": oculta los que solo tienen entradas (lo
    // típico de un ranking de ventas). Arranca DESMARCADO = salen todos.
    FchkSoloVentas := TcxCheckBox.Create(Self);
    FchkSoloVentas.Parent  := TabFechas;
    FchkSoloVentas.Left    := FchkEntradasGlobales.Left;
    FchkSoloVentas.Top     := FchkEntradasGlobales.Top +
      FchkEntradasGlobales.Height + 8;
    FchkSoloVentas.Width   := 210;
    FchkSoloVentas.Caption := SCaptionSoloArticulosConVentas;
    FchkConImpuestos := TcxCheckBox.Create(Self);
    FchkConImpuestos.Parent := TabFechas;
    FchkConImpuestos.Left := FchkSoloVentas.Left;
    FchkConImpuestos.Top :=
      FchkSoloVentas.Top + FchkSoloVentas.Height + 8;
    FchkConImpuestos.Width := 210;
    FchkConImpuestos.Caption := SCaptionConImpuestosMovimientosVentas;
    // Por defecto con impuestos solo si la empresa está en recargo de
    // equivalencia (el IVA es coste y el PVP se mira con IVA); si no, sin
    // impuestos. El usuario puede cambiarlo. Solo el importe de venta sigue
    // al check; PVP y precio de salida van siempre con IVA.
    FchkConImpuestos.Checked :=
      ObtenerRecargoComprasEmpresa(
        CrearLecturasImpuestos(ConexionPrincipal),
        UbicacionSesion.Empresa) = 'S';
  end;
  CrearControlesOrdenacion;
  // Agrupaciones reordenables, incluidos los desgloses por color y talla.
  // + spin de nivel de familia (igual que el balance de almacén).
  CrearTabAgrupacion(STituloAgrupacionesMovimientosVentasArticulo,
    ['ALM', 'PRV', 'FAM', 'TMP', 'ART', 'COL', 'COP', 'TAL'],
    [SCaptionAlmacenAgrupacionMovimientosVentas,
     SCaptionProveedorAgrupacionMovimientosVentas,
     SCaptionFamiliaAgrupacionMovimientosVentas,
     SCaptionTemporadaAgrupacionMovimientosVentas,
     SCaptionArticuloAgrupacionMovimientosVentas,
     SCaptionColorAgrupacionMovimientosVentas,
     SCaptionCopaAgrupacionMovimientosVentas,
     SCaptionTallaAgrupacionMovimientosVentas], True);
  CrearAccesosRanking;
end;

procedure TfrmPrintMovVentasArt.CrearAccesosRanking;
var
  oBoton: TcxButton;
begin
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := TabFechas;
  oBoton.SetBounds(620, 16, 260, 30);
  oBoton.Caption := SInformeRankingProveedor;
  oBoton.Tag := 0;
  oBoton.OnClick := AplicarRanking;
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := TabFechas;
  oBoton.SetBounds(620, 56, 260, 30);
  oBoton.Caption := SInformeRankingFamilia;
  oBoton.Tag := 1;
  oBoton.OnClick := AplicarRanking;
end;

procedure TfrmPrintMovVentasArt.AplicarRanking(Sender: TObject);
var
  i: Integer;
begin
  if TComponent(Sender).Tag = 0 then
    SeleccionarAgrupaciones(['PRV'])
  else
    SeleccionarAgrupaciones(['FAM']);
  FchkIniCompras.Checked := True;
  FdteIniCompras.Date := DteDesde.Date;
  // El ranking vuelve al criterio por defecto segun los almacenes elegidos.
  FEntradasGlobalesManual := False;
  AjustarEntradasGlobales;
  // Incluye grupos con entradas y ninguna venta, como el modelo del cliente.
  FchkSoloVentas.Checked := False;
  for i := 0 to FclbOrden.Items.Count - 1 do
    FclbOrden.Items[i].Checked := False;
  FclbOrden.Items[Ord(omvaUnidadesVenta)].Checked := True;
  FrgSentidoOrden.ItemIndex := 0;
end;

procedure TfrmPrintMovVentasArt.CrearControlesOrdenacion;
var
  lblPeriodo: TcxLabel;
  oItem: TcxCheckListBoxItem;
begin
  FclbOrden := CrearTabChecklist(STituloOrdenacionMovimientosVentas,
    SCaptionSeleccioneOrdenMovimientosVentas);
  FclbOrden.Align := alNone;
  FclbOrden.SetBounds(16, 40, 360, 330);
  FclbOrden.EditValueFormat := cvfIndices;
  FclbOrden.IntegralHeight := False;
  FclbOrden.AllowGrayed := False;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenArticuloDescripcionMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenUnidadesEntradaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteEntradaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenUnidadesVentaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteVentaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenImporteCosteMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenBeneficioMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeBeneficioMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenVentaEntradaMovimientosVentas;
  oItem.Checked := True;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeVentaEntradaMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenMargen1MovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenMargen2MovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeVendidoMovimientosVentas;
  oItem := FclbOrden.Items.Add;
  oItem.Text := SOrdenPorcentajeVentasMovimientosVentas;
  FclbOrden.OnClickCheck := OrdenClickCheck;
  FclbOrden.Hint := SHintOrdenDetalleMovimientosVentas;
  FclbOrden.ShowHint := True;
  FrgSentidoOrden := TcxRadioGroup.Create(Self);
  FrgSentidoOrden.Parent := FclbOrden.Parent;
  FrgSentidoOrden.SetBounds(410, 40, 210, 90);
  FrgSentidoOrden.Caption := SCaptionSentidoOrdenMovimientosVentas;
  FrgSentidoOrden.Properties.Items.Add.Caption :=
    SOrdenDescendenteMovimientosVentas;
  FrgSentidoOrden.Properties.Items.Add.Caption :=
    SOrdenAscendenteMovimientosVentas;
  FrgSentidoOrden.ItemIndex := 0;
  FrgSentidoOrden.Hint := SHintOrdenDetalleMovimientosVentas;
  FrgSentidoOrden.ShowHint := True;
  lblPeriodo := TcxLabel.Create(Self);
  lblPeriodo.Parent := FclbOrden.Parent;
  lblPeriodo.SetBounds(410, 142, 330, 44);
  lblPeriodo.AutoSize := False;
  lblPeriodo.Properties.WordWrap := True;
  lblPeriodo.Transparent := True;
  lblPeriodo.Caption := SCaptionPeriodoOrdenMovimientosVentas;
end;

procedure TfrmPrintMovVentasArt.OrdenClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
var
  iOrden: Integer;
begin
  if (FclbOrden <> nil) and (ANewState = cbsChecked) then
    for iOrden := 0 to FclbOrden.Items.Count - 1 do
      if iOrden <> AIndex then
        FclbOrden.Items[iOrden].State := cbsUnchecked;
end;

// FZ-ISSUE-935: sin almacenes elegidos las entradas son de toda la
// empresa; al elegir almacenes concretos, las de esos almacenes. Si el
// usuario cambia la casilla, se respeta su eleccion.
procedure TfrmPrintMovVentasArt.AjustarEntradasGlobales;
begin
  if FchkEntradasGlobales <> nil then
  begin
    FAjustandoEntradasGlobales := True;
    try
      FchkEntradasGlobales.Checked := CSVAlmacenes = '';
    finally
      FAjustandoEntradasGlobales := False;
    end;
  end;
end;

procedure TfrmPrintMovVentasArt.AlmacenesCambiados;
begin
  inherited;
  if not FEntradasGlobalesManual then
    AjustarEntradasGlobales;
end;

procedure TfrmPrintMovVentasArt.chkEntradasGlobalesChange(Sender: TObject);
begin
  if not FAjustandoEntradasGlobales then
    FEntradasGlobalesManual := True;
end;

procedure TfrmPrintMovVentasArt.chkIniComprasChange(Sender: TObject);
begin
  if FdteIniCompras <> nil then
    FdteIniCompras.Enabled := (FchkIniCompras <> nil)
      and (FchkIniCompras.Checked);
end;

function TfrmPrintMovVentasArt.OrdenSeleccionado(
  out AOrden: TOrdenMovVentasArt): Boolean;
var
  iOrden: Integer;
begin
  Result := False;
  AOrden := Low(TOrdenMovVentasArt);
  if FclbOrden <> nil then
    for iOrden := Ord(Low(TOrdenMovVentasArt)) to
      Ord(High(TOrdenMovVentasArt)) do
      if (not Result) and FclbOrden.Items[iOrden].Checked then
      begin
        AOrden := TOrdenMovVentasArt(iOrden);
        Result := True;
      end;
end;

procedure TfrmPrintMovVentasArt.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
var
  eOrden: TOrdenMovVentasArt;
begin
  inherited;
  AResumen.Anadir(SCaptionOrigenVentasInforme,
    SAlcanceVentasFacturadasInforme);
  if (FchkIniCompras <> nil) and FchkIniCompras.Checked and
     (FdteIniCompras <> nil) then
    AResumen.Anadir(
      FchkIniCompras.Caption, DateToStr(FdteIniCompras.Date))
  else
    AnadirCasilla(AResumen, FchkIniCompras);
  AnadirCasilla(AResumen, FchkEntradasGlobales);
  AnadirCasilla(AResumen, FchkSoloVentas);
  AnadirCasilla(AResumen, FchkConImpuestos);
  if OrdenSeleccionado(eOrden) then
  begin
    AResumen.Anadir(
      STituloOrdenacionMovimientosVentas,
      FclbOrden.Items[Ord(eOrden)].Text);
    AnadirOpcionRadio(AResumen, FrgSentidoOrden);
  end
  else
    AResumen.Anadir(
      STituloOrdenacionMovimientosVentas,
      SResumenSeleccionesNinguna);
  AResumen.Anadir(
    SResumenSeleccionesTarifa,
    ParametrosCaja.TarifaDefecto);
end;

procedure TfrmPrintMovVentasArt.preparar_consulta;
var
  criterios: TCriteriosInformeMovimientosVentasArticulo;
  niveles: TArray<string>;
  function NivelN(idx: Integer): string;
  begin
    if (idx >= 0) and (idx < Length(niveles)) then
      Result := niveles[idx]
    else
      Result := '';
  end;
begin
  inherited;
  niveles := NivelesAgrupacion;
  criterios.FechaDesde := FechaDesde;
  criterios.FechaHasta := FechaHasta;
  criterios.UsarInicioCompras := (FchkIniCompras <> nil) and
    FchkIniCompras.Checked and (FdteIniCompras <> nil);
  if criterios.UsarInicioCompras then
    criterios.InicioCompras := FdteIniCompras.Date;
  criterios.EntradasGlobales := (FchkEntradasGlobales = nil) or
    FchkEntradasGlobales.Checked;
  criterios.Almacenes := CSVAlmacenes;
  criterios.Familias := CSVFamilias;
  criterios.Proveedores := CSVProveedores;
  criterios.Temporadas := CSVTemporadas;
  criterios.Articulos := CSVArticulos;
  criterios.Nivel1 := NivelN(0);
  criterios.Nivel2 := NivelN(1);
  criterios.Nivel3 := NivelN(2);
  criterios.NivelFamilia := NivelFamilia;
  criterios.SoloVentas := (FchkSoloVentas <> nil) and
    FchkSoloVentas.Checked;
  criterios.ConImpuestos := (FchkConImpuestos <> nil) and
    FchkConImpuestos.Checked;
  criterios.UsarOrden := OrdenSeleccionado(criterios.Orden);
  criterios.OrdenDescendente := (FrgSentidoOrden <> nil) and
    (FrgSentidoOrden.ItemIndex = 0);
  // PVP y precio de salida: tarifa por defecto de caja, con el IVA de la
  // zona de la empresa de la sesión (FZ-ISSUE-083/086).
  criterios.Tarifa := ParametrosCaja.TarifaDefecto;
  criterios.Empresa := UbicacionSesion.Empresa;
  PrepararMovimientosEnSegundoPlano(criterios);
  fxdsMovVentas.UpdateBounds;
end;

procedure TfrmPrintMovVentasArt.PrepararMovimientosEnSegundoPlano(
  const ACriterios: TCriteriosInformeMovimientosVentasArticulo);
var
  crCursorAnterior: TCursor;
  oConexionNueva: TUniConnection;
  oConexiones: IServicioConexiones;
  oRepositorioNuevo: IRepositorioInformeMovimientosVentasArticulo;
  oResultadoNuevo: IResultadoInformeMovimientosVentasArticulo;
  oTarea: ITask;
  iNumeroFilas: Integer;
  nInicioCarga: UInt64;
  nTiempoCarga: Int64;
  sError: string;
begin
  oConexiones := Conexiones;
  if not Assigned(oConexiones) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
  oConexionNueva := nil;
  try
    crCursorAnterior := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    try
      oTarea := TTask.Run(
        procedure
        begin
          try
            nInicioCarga := GetTickCount64;
            oConexionNueva := oConexiones.CrearConexion(
              nil, uctSegundoPlano);
            oRepositorioNuevo :=
              CrearRepositorioInformeMovimientosVentasArticuloUniDAC(
                oConexionNueva);
            oResultadoNuevo := oRepositorioNuevo.Preparar(ACriterios);
            iNumeroFilas := oResultadoNuevo.DataSet.RecordCount;
            nTiempoCarga := Int64(GetTickCount64 - nInicioCarga);
          except
            on E: Exception do
            begin
              sError := E.Message;
              if sError = '' then
                sError := E.ClassName;
              oResultadoNuevo := nil;
              oRepositorioNuevo := nil;
              FreeAndNil(oConexionNueva);
            end;
          end;
        end);
      // La ventana de espera vive en su propio hilo; mientras, el
      // principal atiende lo que la tarea le pide (el monitor SQL escribe
      // en el memo del principal desde el hilo de la consulta) sin
      // despachar teclado ni ratón.
      EsperarTareaAtendiendoMensajes(oTarea);
    finally
      Screen.Cursor := crCursorAnterior;
    end;
    if sError <> '' then
      raise Exception.Create(sError);
    if not Assigned(oResultadoNuevo) then
      raise Exception.Create(SCaptionCargandoDatosEspere);
    RegistroLog.RegistrarRendimiento(
      'MovVentasArt.Carga',
      Format('filas=%d; resultado completo', [iNumeroFilas]),
      nTiempoCarga);
    fxdsMovVentas.DataSet := nil;
    FResultadoMovimientos := nil;
    FRepositorioMovimientos := nil;
    FreeAndNil(FConexionMovimientos);
    FConexionMovimientos := oConexionNueva;
    oConexionNueva := nil;
    FRepositorioMovimientos := oRepositorioNuevo;
    FResultadoMovimientos := oResultadoNuevo;
  finally
    oResultadoNuevo := nil;
    oRepositorioNuevo := nil;
    FreeAndNil(oConexionNueva);
  end;
end;

procedure TfrmPrintMovVentasArt.AfterReportLoaded;
var
  Titulo: TfrxComponent;
begin
  inherited;
  Titulo := frxrprt1.FindObject('MemoTitulo');
  if Titulo is TfrxMemoView then
    TfrxMemoView(Titulo).Text := STituloMovimientosVentasFacturadas;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsMovVentas.DataSet := FResultadoMovimientos.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsMovVentas);
  ConfigurarDetalleArticuloAtributos;
  CompletarSubtotales;
  ActualizarFormulasPorcentajes;
  IncluirDetalleOcultoEnAcumulados;
  // Sustituimos el OnBeforePrint del base (fotos) por el nuestro, que encadena
  // las fotos y oculta las bandas de grupo de los niveles inactivos.
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  // Precarga de fotos a nivel artículo en UNA consulta (evita el N+1).
  PrecargarFotosArticulos;
end;

procedure TfrmPrintMovVentasArt.CompletarSubtotales;
const
  Sufijos: array[0..6] of string = (
    'UniEnt', 'UdsVta', 'ImpCos', 'PctBnf', 'VentEnt',
    'PctVdto', 'PctVlast');
var
  iNivel: Integer;
  iSufijo: Integer;
  oDestino: TfrxComponent;
  oOrigen: TfrxComponent;
  oPie: TfrxComponent;
  sNombreDestino: string;
  sPrefijoOrigen: string;
begin
  for iNivel := 1 to 2 do
  begin
    if iNivel = 1 then
      sPrefijoOrigen := 'MemoRS'
    else
      sPrefijoOrigen := 'MemoGF3';
    oPie := frxrprt1.FindObject(Format('GroupFooterG%d', [iNivel]));
    if oPie <> nil then
      for iSufijo := Low(Sufijos) to High(Sufijos) do
      begin
        sNombreDestino := Format(
          'MemoGF%d%s', [iNivel, Sufijos[iSufijo]]);
        oDestino := frxrprt1.FindObject(sNombreDestino);
        oOrigen := frxrprt1.FindObject(sPrefijoOrigen + Sufijos[iSufijo]);
        if (oDestino = nil) and (oOrigen is TfrxMemoView) then
        begin
          oDestino := TfrxMemoView.Create(oPie);
          oDestino.Assign(oOrigen);
          oDestino.Parent := oPie;
          oDestino.Name := sNombreDestino;
        end;
      end;
  end;
end;

procedure TfrmPrintMovVentasArt.ActualizarFormulasPorcentajes;
const
  DenominadorVentas: array[1..3] of string = (
    'UDS_VENTA_GLOBAL', 'UDS_VENTA_G1', 'UDS_VENTA_G2');
var
  iNivel: Integer;
  sPrefijo: string;
  sVentaRegimen: string;
  function Suma(const ACampo: string): string;
  begin
    Result := Format('SUM(<MovVentas."%s">,MasterData1)', [ACampo]);
  end;
  function Maximo(const ACampo: string): string;
  begin
    Result := Format('MAX(<MovVentas."%s">,MasterData1)', [ACampo]);
  end;
  function Porcentaje(const ANumerador, ADenominador: string): string;
  begin
    Result := Format('[IIF(%s<>0,%s/%s*100,0)]',
      [ADenominador, ANumerador, ADenominador]);
  end;
  procedure PonerFormula(const ANombre, AFormula: string);
  var
    oComponente: TfrxComponent;
  begin
    oComponente := frxrprt1.FindObject(ANombre);
    if oComponente is TfrxMemoView then
      TfrxMemoView(oComponente).Memo.Text := AFormula;
  end;
  procedure PonerFormulas(const APrefijo: string);
  begin
    PonerFormula(APrefijo + 'PctBnf',
      Porcentaje(Suma('BENEFICIO'), Suma(sVentaRegimen)));
    PonerFormula(APrefijo + 'VentEnt',
      Porcentaje(Suma(sVentaRegimen), Suma('IMP_ENT_TOT')));
    PonerFormula(APrefijo + 'Marg1',
      Porcentaje(Suma('BENEFICIO'), Suma('IMP_COSTE')));
    PonerFormula(APrefijo + 'Marg2',
      Porcentaje(Suma('VENTA_ENT'), Suma('IMP_ENT_TOT')));
  end;
begin
  // El beneficio sale de la venta según el régimen de IVA de la empresa
  // (IMP_VENTA_REGIMEN, FZ-ISSUE-084), no de la casilla «Con impuestos».
  // Sin el script 743 el procedimiento no la devuelve: IMP_VENTA.
  sVentaRegimen := 'IMP_VENTA';
  if Assigned(fxdsMovVentas.DataSet) and
    Assigned(fxdsMovVentas.DataSet.FindField('IMP_VENTA_REGIMEN')) then
    sVentaRegimen := 'IMP_VENTA_REGIMEN';
  for iNivel := 1 to 3 do
  begin
    sPrefijo := Format('MemoGF%d', [iNivel]);
    PonerFormulas(sPrefijo);
    PonerFormula(sPrefijo + 'PctVlast',
      Porcentaje(Suma('UDS_VENTA'),
        Maximo(DenominadorVentas[iNivel])));
  end;
  PonerFormulas('MemoRS');
  PonerFormula('MemoRSPctVlast',
    Format('[IIF(%s<>0,100,0)]', [Suma('UDS_VENTA')]));
  PonerFormula('MemoHPctVdto', '% Vdo');
  PonerFormula('MemoHPctVlast', '% Vtas');
end;

procedure TfrmPrintMovVentasArt.IncluirDetalleOcultoEnAcumulados;
const
  SReferenciaDetalle = ',MasterData1)';
  SReferenciaDetalleOculto = ',MasterData1,1)';
var
  iComponente: Integer;
  oMemo: TfrxMemoView;
begin
  if FResumenAgrupado then
  begin
    for iComponente := 0 to frxrprt1.AllObjects.Count - 1 do
    begin
      if TObject(frxrprt1.AllObjects[iComponente]) is TfrxMemoView then
      begin
        oMemo := TfrxMemoView(frxrprt1.AllObjects[iComponente]);
        oMemo.Memo.Text := StringReplace(
          oMemo.Memo.Text, SReferenciaDetalle,
          SReferenciaDetalleOculto, [rfReplaceAll, rfIgnoreCase]);
      end;
    end;
  end;
end;

procedure TfrmPrintMovVentasArt.ConfigurarDetalleArticuloAtributos;
var
  aNiveles: TArray<string>;
  bAgruparArticulo: Boolean;
  bMostrarColor: Boolean;
  bMostrarTalla: Boolean;
  iNivel: Integer;
  iNivelArticulo: Integer;
  oComponente: TfrxComponent;
  sCampoColor: string;
  sCampoTalla: string;
  sPrefijoCopa: string;
  sDetalle: string;
  function TituloDetalle: string;
  var
    sNivel: string;
  begin
    Result := SCaptionArticuloAgrupacionMovimientosVentas;
    if FResumenAgrupado then
    begin
      sNivel := aNiveles[FNivelDetalleAgrupacion - 1];
      if SameText(sNivel, 'ALM') then
        Result := SCaptionAlmacenAgrupacionMovimientosVentas
      else if SameText(sNivel, 'PRV') then
        Result := SCaptionProveedorAgrupacionMovimientosVentas
      else if SameText(sNivel, 'FAM') then
        Result := SCaptionFamiliaAgrupacionMovimientosVentas
      else if SameText(sNivel, 'TMP') then
        Result := SCaptionTemporadaAgrupacionMovimientosVentas
      else if SameText(sNivel, 'COL') then
        Result := SCaptionColorAgrupacionMovimientosVentas
      else if SameText(sNivel, 'COP') then
        Result := SCaptionCopaAgrupacionMovimientosVentas
      else if SameText(sNivel, 'TAL') then
        Result := SCaptionTallaAgrupacionMovimientosVentas;
    end;
  end;
  procedure AnadirFragmento(const AFragmento: string);
  begin
    if AFragmento <> '' then
    begin
      if sDetalle <> '' then
        sDetalle := sDetalle + '  ';
      sDetalle := sDetalle + AFragmento;
    end;
  end;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active then
  begin
    aNiveles := NivelesAgrupacion;
    FNivelDetalleAgrupacion := Length(aNiveles);
    iNivelArticulo := IndexText('ART', aNiveles) + 1;
    bAgruparArticulo := iNivelArticulo > 0;
    FResumenAgrupado :=
      (FNivelDetalleAgrupacion > 0) and (not bAgruparArticulo);
    bMostrarColor := MatchText('COL', aNiveles) or
      MatchText('COP', aNiveles);
    bMostrarTalla := MatchText('TAL', aNiveles) or
      MatchText('COP', aNiveles);
    sCampoColor := '';
    if bMostrarColor and
       (FResultadoMovimientos.DataSet.FindField('COLOR_ETIQUETA') <> nil) then
      sCampoColor := 'COLOR_ETIQUETA'
    else if bMostrarColor and
            (FResultadoMovimientos.DataSet.FindField('COLOR') <> nil) then
      sCampoColor := 'COLOR';
    sCampoTalla := '';
    if bMostrarTalla and
       (FResultadoMovimientos.DataSet.FindField('TALLA_ETIQUETA') <> nil) then
      sCampoTalla := 'TALLA_ETIQUETA'
    else if bMostrarTalla and
            (FResultadoMovimientos.DataSet.FindField('TALLA') <> nil) then
      sCampoTalla := 'TALLA';
    for iNivel := 1 to 3 do
    begin
      oComponente := frxrprt1.FindObject(
        Format('MemoGF%dLbl', [iNivel]));
      if oComponente is TfrxMemoView then
      begin
        if FResumenAgrupado and
           (iNivel = FNivelDetalleAgrupacion) then
          TfrxMemoView(oComponente).Memo.Text := Format(
            '[MovVentas."GRUPO%d_ETIQ"]', [iNivel])
        else
          TfrxMemoView(oComponente).Memo.Text := Format(
            'TOTAL [MovVentas."GRUPO%d_ETIQ"]', [iNivel]);
      end;
    end;
    if bAgruparArticulo then
    begin
      oComponente := frxrprt1.FindObject(
        Format('MemoGF%dLbl', [iNivelArticulo]));
      if oComponente is TfrxMemoView then
        TfrxMemoView(oComponente).Memo.Text := Format(
          'TOTAL ARTÍCULO [MovVentas."GRUPO%d_COD"]',
          [iNivelArticulo]);
    end;
    oComponente := frxrprt1.FindObject('MemoHDesc');
    if oComponente is TfrxMemoView then
      TfrxMemoView(oComponente).Memo.Text := TituloDetalle;
    oComponente := frxrprt1.FindObject('MemoArtDesc');
    if oComponente is TfrxMemoView then
    begin
      sDetalle := '';
      if not bAgruparArticulo then
        AnadirFragmento('[MovVentas."CODIGO_ART_ART"]');
      if sCampoColor <> '' then
        AnadirFragmento('[MovVentas."' + sCampoColor + '"]');
      sPrefijoCopa := '';
      if FResultadoMovimientos.DataSet.FindField('COPA') <> nil then
        sPrefijoCopa := '[IIF(<MovVentas."COPA"> = '''', '''', ' +
          '''Copa: '' + <MovVentas."COPA"> + '' / '')]';
      if sCampoTalla <> '' then
        AnadirFragmento(sPrefijoCopa +
          'Talla: [MovVentas."' + sCampoTalla + '"]');
      if not bAgruparArticulo then
        sDetalle := sDetalle + sLineBreak +
          '[MovVentas."DESCRIPCION_ART"]';
      TfrxMemoView(oComponente).Memo.Text := sDetalle;
    end;
  end;
end;

destructor TfrmPrintMovVentasArt.Destroy;
begin
  FotosArticulos.LimpiarPrecargaFotos;
  fxdsMovVentas.DataSet := nil;
  FResultadoMovimientos := nil;
  FRepositorioMovimientos := nil;
  FreeAndNil(FConexionMovimientos);
  inherited Destroy;
end;

procedure TfrmPrintMovVentasArt.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active and
     (not FResumenAgrupado) and
     (not FResultadoMovimientos.DataSet.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      FResultadoMovimientos.DataSet.DisableControls;
      try
        FResultadoMovimientos.DataSet.First;
        while not FResultadoMovimientos.DataSet.Eof do
        begin
          slCod.Add(FResultadoMovimientos.DataSet.FieldByName(
            'CODIGO_ART_ART').AsString);
          FResultadoMovimientos.DataSet.Next;
        end;
      finally
        FResultadoMovimientos.DataSet.EnableControls;
      end;
      FotosArticulos.PrecargarFotosLote(slCod.ToStringArray);
    finally
      FreeAndNil(slCod);
    end;
  end;
end;

function TfrmPrintMovVentasArt.RutaFotoArticulo(
  const ACodigoArticulo: string): string;
var
  oInfo: TFotoInfo;
begin
  Result := '';
  oInfo := FotosArticulos.Resolver(ACodigoArticulo, '');
  if oInfo.Encontrada then
    Result := FotosArticulos.RutaFoto(oInfo, frPx300);
end;

procedure TfrmPrintMovVentasArt.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  sNom : string;
  nivel: Integer;
begin
  FotosArticulos.HandlerReportBeforePrint(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if sNom = 'MasterData1' then
    begin
      TfrxBand(Component).Visible := not FResumenAgrupado;
      ActualizarDetalleEspera(DetalleProgresoInforme);
    end
    else if (Pos('GroupHeaderG', sNom) = 1) or
            (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       (FResultadoMovimientos <> nil) and
       FResultadoMovimientos.DataSet.Active then
    begin
      TfrxBand(Component).Visible :=
        FResultadoMovimientos.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> '';
      if FResumenAgrupado and
         (nivel = FNivelDetalleAgrupacion) and
         (Pos('GroupHeaderG', sNom) = 1) then
        TfrxBand(Component).Visible := False;
    end
    else if (sNom = 'GroupHeaderFam') or (sNom = 'GroupFooterFam') then
      // La familia NO agrupa por sí sola: solo se agrupa por familia si se
      // elige FAM en la pestaña Agrupaciones (sale como "Familia: ...").
      TfrxBand(Component).Visible := False;
  end;
end;

function TfrmPrintMovVentasArt.DetalleProgresoInforme: string;
var
  oDatos: TDataSet;
begin
  Result := inherited DetalleProgresoInforme;
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active and
     (not FResultadoMovimientos.DataSet.IsEmpty) then
  begin
    oDatos := FResultadoMovimientos.DataSet;
    Result := Format(SCaptionEsperaSeleccionandoArticulo,
      [Result, Trim(
        oDatos.FieldByName('CODIGO_ART_ART').AsString + ' ' +
        oDatos.FieldByName('DESCRIPCION_ART').AsString)]);
  end;
end;

procedure TfrmPrintMovVentasArt.GenerarHojaExcelMovVentas(
  APreview: TfrmMtoPreviewExcel);
var
  aNiveles: TArray<string>;
  bFinalizado: Boolean;
  fnRutaFoto: TRutaFotoArticuloExcel;
  iLotesExcel: Integer;
  iNumeroFilas: Integer;
  nInicioExportacion: UInt64;
  oDatos: TDataSet;
  oExportacion: IExportacionMovVentasArtPorLotes;
  oServiciosHoja: TServiciosHojaCalculo;
  sTotalFilas: string;
begin
  APreview.DialogoGuardar.InitialDir :=
    ParametrosApp.GetPath('appDirExcel');
  APreview.DialogoGuardar.FileName :=
    SNombreArchivoMovimientosVentasArticulos;
  oServiciosHoja := CrearServiciosHojaCalculoDevEx(APreview.dxSpreadSheet1);
  oDatos := FResultadoMovimientos.DataSet;
  // Miniaturas en las filas de artículo, como en el informe. Sin artículos
  // (resumen agrupado sin ART) no hay nada que precargar.
  aNiveles := NivelesAgrupacion;
  FResumenAgrupado := (Length(aNiveles) > 0) and
    (not MatchText('ART', aNiveles));
  fnRutaFoto := nil;
  if not FResumenAgrupado then
  begin
    PrecargarFotosArticulos;
    fnRutaFoto := RutaFotoArticulo;
  end;
  oExportacion := CrearExportacionMovVentasArtExcelPorLotes(
    oServiciosHoja.Escritor,
    oServiciosHoja.Formateador,
    oDatos,
    aNiveles,
    fnRutaFoto,
    LineasResumenSelecciones);
  iNumeroFilas := oDatos.RecordCount;
  sTotalFilas := FormatFloat('#,##0', iNumeroFilas);
  iLotesExcel := 0;
  nInicioExportacion := GetTickCount64;
  IniciarEspera(SCaptionEsperaGenerandoHojaCalculo);
  repeat
    bFinalizado := oExportacion.ProcesarLote(FILAS_POR_LOTE_EXCEL);
    Inc(iLotesExcel);
    ActualizarDetalleEspera(Format(
      SCaptionEsperaExportandoFilas,
      [FormatFloat('#,##0', EnsureRange(oDatos.RecNo, 0, iNumeroFilas)),
       sTotalFilas]));
  until bFinalizado;
  RegistroLog.RegistrarRendimiento(
    'MovVentasArt.Excel',
    Format('filas=%d; lotes=%d', [iNumeroFilas, iLotesExcel]),
    GetTickCount64 - nInicioExportacion);
end;

procedure TfrmPrintMovVentasArt.MostrarPreviewExcel(
  APreview: TfrmMtoPreviewExcel);
begin
  APreview.ShowModal;
end;

procedure TfrmPrintMovVentasArt.ExportarExcelMovVentas(Sender: TObject);
var
  crCursorAnterior: TCursor;
  fPreview: TfrmMtoPreviewExcel;
begin
  crCursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  fPreview := nil;
  try
    IniciarEspera(SCaptionEsperaConsultandoDatosInforme);
    IniciarMedicionDatos;
    preparar_consulta;
    PausarMedicionDatos;
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    GenerarHojaExcelMovVentas(fPreview);
    TerminarEspera;
    MostrarPreviewExcel(fPreview);
  finally
    TerminarEspera;
    FreeAndNil(fPreview);
    Screen.Cursor := crCursorAnterior;
  end;
end;

end.
