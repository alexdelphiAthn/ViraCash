{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpLibrosIva                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del listado «Libros de IVA» (FZ-ISSUE-262): IVA       }
{    repercutido (facturas de venta y simplificadas) e IVA soportado          }
{    (facturas de compra) de un ejercicio completo, un trimestre o un mes,    }
{    por factura y tramo de IVA y con resumen por porcentaje. Filtros de      }
{    empresa y libro. Exporta a PDF (FastReport) y a Excel nativo.            }
{******************************************************************************}
unit inMtoModalImpLibrosIva;

interface

uses
  inLibMsgCompras,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxSpinEdit,
  cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses, dxSkinsForm,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization,
  frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab,
  cxLocalization, inLibInformeLibrosIvaPersistenciaIntf,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintLibrosIva = class(TfrmPrintMultiFiltro)
    fxdsLibrosIva: TfrxDBDataset;
    fxdsResumenIva: TfrxDBDataset;
    // FZ-ISSUE-372: cuadro de liquidación por empresa.
    fxdsLiquidacionIva: TfrxDBDataset;
    procedure btnExcelNativoClick(Sender: TObject);
  private
    FInicializado: Boolean;
    FRepositorio: IRepositorioInformeLibrosIva;
    FResultado: IResultadoInformeLibrosIva;
    FclbEmpresas: TcxCheckListBox;
    FclbLibros: TcxCheckListBox;
    FseEjercicio: TcxSpinEdit;
    FcbPeriodo: TcxComboBox;
    function Repositorio: IRepositorioInformeLibrosIva;
    function Ejercicio: Integer;
    function TextoPeriodo: string;
    procedure CrearControlesPropios;
    procedure CrearSelectorPeriodo;
    procedure CargarEmpresas;
    procedure CargarLibros;
    procedure AplicarPeriodo;
    procedure PeriodoCambiado(Sender: TObject);
    function CriteriosActuales: TCriteriosInformeLibrosIva;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure AvisarAntesDeConsulta; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  System.DateUtils,
  UniDataInformeLibrosIvaRepositorio,
  inLibLibrosIva, inLibLibrosIvaExcel, inLibVerifactu,
  inLibResumenSeleccionesVcl, inMtoPreviewExcel, inLibMensajesVcl;

const
  // FZ-ISSUE-632: facturas sin n.º de proveedor listadas en el aviso.
  CMaxFacturasSinNumeroProveedorAviso = 15;

{$R *.dfm}

{ TfrmPrintLibrosIva }

function TfrmPrintLibrosIva.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas];
end;

procedure TfrmPrintLibrosIva.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    FInicializado := True;
  end;
end;

function TfrmPrintLibrosIva.Repositorio: IRepositorioInformeLibrosIva;
begin
  if FRepositorio = nil then
    FRepositorio := CrearRepositorioInformeLibrosIvaUniDAC(
      ConexionPrincipal);
  Result := FRepositorio;
end;

procedure TfrmPrintLibrosIva.CrearControlesPropios;
begin
  CrearSelectorPeriodo;
  FclbEmpresas := CrearTabChecklist(STituloEmpresasLibrosIva);
  CargarEmpresas;
  FclbLibros := CrearTabChecklist(STituloLibrosLibrosIva);
  CargarLibros;
end;

// Ejercicio y periodo a la derecha de las fechas, que pasan a ser solo de
// lectura: el rango sale siempre del periodo elegido.
procedure TfrmPrintLibrosIva.CrearSelectorPeriodo;
var
  lblEjercicio: TcxLabel;
  lblPeriodo: TcxLabel;
  sNombre: string;
begin
  lblEjercicio := TcxLabel.Create(Self);
  lblEjercicio.Parent := TabFechas;
  lblEjercicio.Transparent := True;
  lblEjercicio.Caption := SCaptionEjercicioLibrosIva;
  lblEjercicio.Left := 200;
  lblEjercicio.Top := 16;
  FseEjercicio := TcxSpinEdit.Create(Self);
  FseEjercicio.Parent := TabFechas;
  FseEjercicio.Left := 200;
  FseEjercicio.Top := 38;
  FseEjercicio.Width := 90;
  FseEjercicio.Properties.MinValue := 2000;
  FseEjercicio.Properties.MaxValue := 2100;
  FseEjercicio.Value := YearOf(Date);
  lblPeriodo := TcxLabel.Create(Self);
  lblPeriodo.Parent := TabFechas;
  lblPeriodo.Transparent := True;
  lblPeriodo.Caption := SCaptionPeriodoLibrosIva;
  lblPeriodo.Left := 200;
  lblPeriodo.Top := 70;
  FcbPeriodo := TcxComboBox.Create(Self);
  FcbPeriodo.Parent := TabFechas;
  FcbPeriodo.Left := 200;
  FcbPeriodo.Top := 92;
  FcbPeriodo.Width := 200;
  FcbPeriodo.Properties.DropDownListStyle := lsFixedList;
  FcbPeriodo.Properties.DropDownRows := 17;
  for sNombre in NombresPeriodosLibrosIva do
    FcbPeriodo.Properties.Items.Add(sNombre);
  FcbPeriodo.ItemIndex := PeriodoDeFechaLibrosIva(Date, True);
  DteDesde.Properties.ReadOnly := True;
  DteHasta.Properties.ReadOnly := True;
  FseEjercicio.Properties.OnChange := PeriodoCambiado;
  FcbPeriodo.Properties.OnChange := PeriodoCambiado;
  AplicarPeriodo;
end;

function TfrmPrintLibrosIva.Ejercicio: Integer;
begin
  Result := FseEjercicio.Value;
end;

procedure TfrmPrintLibrosIva.AplicarPeriodo;
var
  dDesde: TDateTime;
  dHasta: TDateTime;
begin
  if (FseEjercicio <> nil) and (FcbPeriodo <> nil) and
     (FcbPeriodo.ItemIndex >= 0) then
  begin
    RangoPeriodoLibrosIva(Ejercicio, FcbPeriodo.ItemIndex, dDesde, dHasta);
    DteDesde.Date := dDesde;
    DteHasta.Date := dHasta;
  end;
end;

procedure TfrmPrintLibrosIva.PeriodoCambiado(Sender: TObject);
begin
  AplicarPeriodo;
end;

function TfrmPrintLibrosIva.TextoPeriodo: string;
begin
  Result := Format(SFormatoPeriodoLibrosIva, [Ejercicio, FcbPeriodo.Text]);
end;

// Todas las empresas en la lista; marcada solo la de la sesión.
procedure TfrmPrintLibrosIva.CargarEmpresas;
var
  aEmpresas: TEmpresasInformeLibrosIva;
  oElemento: TcxCheckListBoxItem;
  rEmpresa: TEmpresaInformeLibrosIva;
begin
  FclbEmpresas.Items.Clear;
  aEmpresas := Repositorio.ListarEmpresas;
  for rEmpresa in aEmpresas do
  begin
    oElemento := FclbEmpresas.Items.Add;
    oElemento.Text := rEmpresa.Codigo + ' - ' + rEmpresa.RazonSocial;
    if SameText(rEmpresa.Codigo, UbicacionSesion.Empresa) then
      oElemento.State := cbsChecked
    else
      oElemento.State := cbsUnchecked;
  end;
end;

procedure TfrmPrintLibrosIva.CargarLibros;

  procedure Agregar(const ACodigo: string);
  var
    oElemento: TcxCheckListBoxItem;
  begin
    oElemento := FclbLibros.Items.Add;
    oElemento.Text := ACodigo + ' - ' + NombreLibroIva(ACodigo);
    oElemento.State := cbsChecked;
  end;

begin
  FclbLibros.Items.Clear;
  Agregar(CLibroIvaRepercutido);
  Agregar(CLibroIvaSoportado);
end;

procedure TfrmPrintLibrosIva.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  if FcbPeriodo <> nil then
    AResumen.Anadir(SEtiquetaPeriodoLibrosIva, TextoPeriodo);
  inherited;
  AnadirMarcados(AResumen, STituloEmpresasLibrosIva, FclbEmpresas);
  AnadirMarcados(AResumen, STituloLibrosLibrosIva, FclbLibros);
end;

function TfrmPrintLibrosIva.CriteriosActuales: TCriteriosInformeLibrosIva;
begin
  Result.FechaDesde := FechaDesde;
  Result.FechaHasta := FechaHasta;
  Result.Empresas := SeleccionadosCSV(FclbEmpresas);
  Result.Libros := SeleccionadosCSV(FclbLibros);
  Result.IncluirSinFase := SinVerifactuActivo(ParametrosApp);
end;

procedure AgregarFacturasAviso(AMensaje: TStrings;
  const ACabecera: string;
  const AFacturas: TFacturasSinNumeroProveedorLibrosIva);
var
  i: Integer;
begin
  if Length(AFacturas) > 0 then
  begin
    if AMensaje.Count > 0 then
      AMensaje.Add('');
    AMensaje.Add(Format(ACabecera, [Length(AFacturas)]));
    AMensaje.Add('');
    i := 0;
    while (i < Length(AFacturas)) and
          (i < CMaxFacturasSinNumeroProveedorAviso) do
    begin
      AMensaje.Add(Format(SLineaSinNumeroProveedorLibrosIva,
        [AFacturas[i].Empresa, AFacturas[i].Serie, AFacturas[i].Numero,
         FormatDateTime('dd/mm/yyyy', AFacturas[i].Fecha),
         AFacturas[i].Proveedor]));
      Inc(i);
    end;
    if Length(AFacturas) > CMaxFacturasSinNumeroProveedorAviso then
      AMensaje.Add(Format(SRestoSinNumeroProveedorLibrosIva,
        [Length(AFacturas) - CMaxFacturasSinNumeroProveedorAviso]));
  end;
end;

// FZ-ISSUE-632: el n.º de factura del proveedor es obligatorio en el libro
// registro de facturas recibidas. FZ-ISSUE-733: los borradores sin cerrar
// también entran. Aviso no bloqueante con las facturas del periodo en cada
// caso, para que el usuario las complete; el informe se emite igualmente.
procedure TfrmPrintLibrosIva.AvisarAntesDeConsulta;
var
  oMensaje: TStringList;
begin
  inherited;
  if (FclbEmpresas <> nil) and (FclbLibros <> nil) then
  begin
    oMensaje := TStringList.Create;
    try
      AgregarFacturasAviso(oMensaje, SAvisoSinNumeroProveedorLibrosIva,
        Repositorio.ListarFacturasSinNumeroProveedor(CriteriosActuales));
      AgregarFacturasAviso(oMensaje, SAvisoFacturasAbiertasLibrosIva,
        Repositorio.ListarFacturasAbiertas(CriteriosActuales));
      if oMensaje.Count > 0 then
      begin
        // Ninguna ventana de progreso debe cubrir el aviso modal.
        OcultarEspera;
        ShowMessage_fza(TrimRight(oMensaje.Text));
      end;
    finally
      FreeAndNil(oMensaje);
    end;
  end;
end;

procedure TfrmPrintLibrosIva.preparar_consulta;
begin
  inherited;
  FResultado := Repositorio.Preparar(CriteriosActuales);
  fxdsLibrosIva.UpdateBounds;
  fxdsResumenIva.UpdateBounds;
  fxdsLiquidacionIva.UpdateBounds;
end;

procedure TfrmPrintLibrosIva.AfterReportLoaded;
begin
  inherited;
  fxdsLibrosIva.DataSet := FResultado.Detalle;
  fxdsResumenIva.DataSet := FResultado.Resumen;
  fxdsLiquidacionIva.DataSet := FResultado.Liquidacion;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsLibrosIva);
  frxrprt1.DataSets.Add(fxdsResumenIva);
  frxrprt1.DataSets.Add(fxdsLiquidacionIva);
end;

// Excel nativo DevExpress en lugar de la exportación XLSX de FastReport:
// detalle por libro con importes tipados y hoja de resumen por porcentaje.
procedure TfrmPrintLibrosIva.btnExcelNativoClick(Sender: TObject);
var
  oPreview: TfrmMtoPreviewExcel;
  rCabecera: TCabeceraLibrosIvaExcel;
begin
  AvisarAntesDeConsulta;
  IniciarMedicionDatos;
  preparar_consulta;
  PausarMedicionDatos;
  rCabecera.Periodo := TextoPeriodo;
  rCabecera.FechaDesde := Trunc(FechaDesde);
  rCabecera.FechaHasta := Trunc(FechaHasta);
  Self.Hide;
  try
    oPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      oPreview.PopupParent := Self;
      oPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      oPreview.DialogoGuardar.FileName := Format(
        SFormatoNombreArchivoLibrosIva,
        [Ejercicio,
         FormatDateTime('mmdd', rCabecera.FechaDesde),
         FormatDateTime('yyyymmdd_hhnnss', Now)]);
      Screen.Cursor := crHourGlass;
      try
        ExportarLibrosIvaExcel(
          oPreview.dxSpreadSheet1,
          FResultado.Detalle,
          FResultado.Resumen,
          rCabecera,
          LineasResumenSelecciones,
          FResultado.Liquidacion);
      finally
        Screen.Cursor := crDefault;
      end;
      oPreview.ShowModal;
    finally
      FreeAndNil(oPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
