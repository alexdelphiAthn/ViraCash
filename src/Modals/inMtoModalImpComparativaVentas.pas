{******************************************************************************}
{                                                                              }
{  Módulo: inMtoModalImpComparativaVentas                                      }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inMtoModalImpComparativaVentas;

interface

uses
  System.Classes, Vcl.Controls, Data.DB, Datasnap.DBClient,
  cxCalendar, cxDropDownEdit, cxButtons, frxClass, frxDBSet,
  inMtoModalImpMultiFiltro, inLibComparativaVentasIntf,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintComparativaVentas = class(TfrmPrintMultiFiltro)
  private
    FInicializado: Boolean;
    FDesdeAnterior: TcxDateEdit;
    FHastaAnterior: TcxDateEdit;
    FCriterio: TcxComboBox;
    FTemporadasP1: TFiltroChecklist;
    FTemporadasP2: TFiltroChecklist;
    FDatos: TClientDataSet;
    FDatosInforme: TfrxDBDataset;
    FRepositorio: IRepositorioComparativaVentas;
    FFiltro: TFiltroComparativaVentas;
    procedure CrearControles;
    procedure ExportarExcelComparativa(Sender: TObject);
    procedure AplicarAnioAnterior(Sender: TObject);
    function LeerFiltro: TFiltroComparativaVentas;
  protected
    procedure DoShow; override;
    function FiltrosUsados: TFiltrosReport; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  inLibMsgInformesCliente,
  System.SysUtils, System.DateUtils, System.Variants, System.Math,
  cxLabel, cxTextEdit,
  inLibComparativaVentas, inLibComparativaVentasInforme,
  inLibInformeTabular, UniDataComparativaVentasRepositorio;

{$R *.dfm}

function TfrmPrintComparativaVentas.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frArticulos];
end;

procedure TfrmPrintComparativaVentas.CrearControles;
var
  oEtiqueta: TcxLabel;
  oBoton: TcxButton;
  eCriterio: TCriterioComparativaVentas;
begin
  oEtiqueta := TcxLabel.Create(Self);
  oEtiqueta.Parent := TabFechas;
  oEtiqueta.Transparent := True;
  oEtiqueta.SetBounds(220, 12, 200, 20);
  oEtiqueta.Caption := SInformeSegundoDesdeHasta;
  FDesdeAnterior := TcxDateEdit.Create(Self);
  FDesdeAnterior.Parent := TabFechas;
  FDesdeAnterior.SetBounds(220, 36, 140, 24);
  FHastaAnterior := TcxDateEdit.Create(Self);
  FHastaAnterior.Parent := TabFechas;
  FHastaAnterior.SetBounds(370, 36, 140, 24);
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := TabFechas;
  oBoton.SetBounds(220, 76, 290, 28);
  oBoton.Caption := SInformeAnioAnterior;
  oBoton.OnClick := AplicarAnioAnterior;
  FCriterio := TcxComboBox.Create(Self);
  FCriterio.Parent := TabFechas;
  FCriterio.SetBounds(220, 124, 380, 24);
  FCriterio.Properties.DropDownListStyle := lsFixedList;
  for eCriterio := Low(TCriterioComparativaVentas) to
    High(TCriterioComparativaVentas) do
    FCriterio.Properties.Items.Add(NombreCriterioComparativa(eCriterio));
  FCriterio.ItemIndex := Ord(ccvFacturadoConImpuestos);
  oEtiqueta := TcxLabel.Create(Self);
  oEtiqueta.Parent := TabFechas;
  oEtiqueta.Transparent := True;
  oEtiqueta.AutoSize := False;
  oEtiqueta.SetBounds(220, 166,
    Max(200, TabFechas.ClientWidth - 236),
    Max(140, TabFechas.ClientHeight - 182));
  oEtiqueta.Anchors := [akLeft, akTop, akRight, akBottom];
  oEtiqueta.Properties.WordWrap := True;
  oEtiqueta.Caption :=
    SInformeAyudaComparacion + sLineBreak +
    SInformeAyudaCaja;
  AplicarAnioAnterior(nil);
end;

procedure TfrmPrintComparativaVentas.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControles;
    FTemporadasP1 := CrearFiltroTemporadas(SInformeTemporadaP1);
    FTemporadasP2 := CrearFiltroTemporadas(SInformeTemporadaP2);
    btnExcel.OnClick := ExportarExcelComparativa;
    FDatos := TClientDataSet.Create(Self);
    FDatosInforme := TfrxDBDataset.Create(Self);
    FDatosInforme.Name := 'fxdsComparativa';
    FDatosInforme.UserName := 'Comparativa';
    FDatosInforme.DataSet := FDatos;
    CrearInformeTabular(frxReportOrigen, FDatosInforme,
      SInformeComparativa, ColumnasComparativaInforme);
    frxrprt1.AssignAll(frxReportOrigen);
    FRepositorio := CrearRepositorioComparativaVentas(ConexionPrincipal);
    FInicializado := True;
  end;
end;

procedure TfrmPrintComparativaVentas.ExportarExcelComparativa(
  Sender: TObject);
begin
  ExportarExcelTabular(FDatos, SInformeComparativa,
    'Comparativa_ventas.xlsx', ColumnasComparativaInforme);
end;

procedure TfrmPrintComparativaVentas.AplicarAnioAnterior(Sender: TObject);
begin
  FDesdeAnterior.Date := IncYear(DteDesde.Date, -1);
  FHastaAnterior.Date := IncYear(DteHasta.Date, -1);
end;

function TfrmPrintComparativaVentas.LeerFiltro: TFiltroComparativaVentas;
begin
  Result := Default(TFiltroComparativaVentas);
  Result.Desde := FechaDesde;
  Result.Hasta := FechaHasta;
  if VarIsNull(FDesdeAnterior.EditValue) or
     VarIsNull(FHastaAnterior.EditValue) then
    raise EArgumentException.Create(SInformeIndicarSegundo);
  Result.DesdeAnterior := FDesdeAnterior.Date;
  Result.HastaAnterior := FHastaAnterior.Date;
  Result.Empresa := UbicacionSesion.Empresa;
  Result.Almacenes := CSVAlmacenes;
  Result.Familias := CSVFamilias;
  Result.Articulos := CSVArticulos;
  Result.Proveedores := CSVProveedores;
  Result.Temporadas := CSVDe(FTemporadasP1);
  Result.TemporadasAnteriores := CSVDe(FTemporadasP2);
  Result.Criterio := TCriterioComparativaVentas(FCriterio.ItemIndex);
  ValidarComparativaVentas(Result);
end;

procedure TfrmPrintComparativaVentas.preparar_consulta;
var
  oActual, oAnterior: TVentasDiariasComparativa;
begin
  inherited;
  FFiltro := LeerFiltro;
  oActual := FRepositorio.Consultar(FFiltro, FFiltro.Desde, FFiltro.Hasta);
  oAnterior := FRepositorio.Consultar(FFiltro,
    FFiltro.DesdeAnterior, FFiltro.HastaAnterior, pcvSegundo);
  CargarComparativaInforme(FDatos,
    CalcularComparativaVentas(FFiltro, oActual, oAnterior));
end;

procedure TfrmPrintComparativaVentas.AfterReportLoaded;
var
  oTitulo: TfrxComponent;
begin
  inherited;
  frxrprt1.EngineOptions.UseGlobalDataSetList := False;
  frxrprt1.EnabledDataSets.Clear;
  frxrprt1.EnabledDataSets.Add(FDatosInforme);
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(FDatosInforme);
  oTitulo := frxrprt1.FindObject('TituloTabla');
  if oTitulo is TfrxMemoView then
    TfrxMemoView(oTitulo).Text := SInformeTituloComparativa +
      NombreCriterioComparativa(FFiltro.Criterio);
end;

procedure TfrmPrintComparativaVentas.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  DescribirFiltro(AResumen, FTemporadasP1);
  DescribirFiltro(AResumen, FTemporadasP2);
  AResumen.Anadir(SInformeEmpresa, FFiltro.Empresa);
  AResumen.Anadir(SInformeSegundoPeriodo, DateToStr(FFiltro.DesdeAnterior) +
    ' - ' + DateToStr(FFiltro.HastaAnterior));
  AResumen.Anadir(SInformeCriterio,
    NombreCriterioComparativa(FFiltro.Criterio));
  AResumen.Anadir(SInformeComparacion, SInformeDiasPosicion);
  AResumen.Anadir(SInformeVariacion, SInformeFormulaVariacion);
  if FFiltro.Criterio = ccvIngresosCaja then
    AResumen.Anadir(SInformeAlcanceCaja,
      SInformeCobrosNetos);
end;

end.
