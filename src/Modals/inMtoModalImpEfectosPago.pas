{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpEfectosPago                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Listado de efectos de pago". Lista la cartera     }
{    de pagos a proveedor con filtros por fecha, almacén, proveedor, número    }
{    de efecto, banco/remesa, tipo y situación del efecto.                     }
{******************************************************************************}
unit inMtoModalImpEfectosPago;

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
  cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses, dxSkinsForm,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization,
  frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab,
  cxLocalization, inLibInformeEfectosPagoPersistenciaIntf,
  inLibInformeMultiFiltroPersistenciaIntf,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintEfectosPago = class(TfrmPrintMultiFiltro)
    fxdsEfectosPago: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FRepositorioEfectos: IRepositorioInformeEfectosPago;
    FResultadoEfectos: IResultadoInformeEfectosPago;
    FrgTipoFecha: TcxRadioGroup;
    FrgSituacion: TcxRadioGroup;
    FtxtNumeroDesde: TcxTextEdit;
    FtxtNumeroHasta: TcxTextEdit;
    FchkSoloTotales: TcxCheckBox;
    FclbTotales: TcxCheckListBox;
    FclbTipos: TcxCheckListBox;
    FclbSituaciones: TcxCheckListBox;
    FclbBancos: TcxCheckListBox;
    procedure CrearControlesPropios;
    procedure CargarChecklist(
      AClb: TcxCheckListBox;
      const AOpciones: TOpcionesInformeEfectosPago);
    procedure CargarTotales;
    procedure CargarTiposEfecto;
    procedure CargarSituaciones;
    procedure CargarBancosRemesa;
    function CSVTipos: string;
    function CSVSituaciones: string;
    function CSVBancos: string;
    function TextoNumero(AEdit: TcxTextEdit): string;
    function NivelesTotales: TArray<string>;
    procedure IncluirDetalleOcultoEnAcumulados;
    procedure ReportBeforePrint(Component: TfrxReportComponent);
    procedure RotularFechaElegida;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    function OrigenProveedores:
      TOrigenProveedoresInformeMultiFiltro; override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgFacturas, UniDataInformeEfectosPagoRepositorio,
  inLibResumenSeleccionesVcl;

resourcestring
  STituloTotalesInformeEfectosPago = 'Totales';
  STituloTiposInformeEfectosPago = 'Tipos de efecto';
  STituloSituacionesInformeEfectosPago = 'Situación efectos';
  STituloBancosInformeEfectosPago = 'Bancos remesa';
  SCaptionAlmacenesInformeEfectosPago = 'Almacenes';
  SCaptionFechasInformeEfectosPago = 'Fechas';
  SCaptionProveedoresInformeEfectosPago = 'Proveedores';

{ TfrmPrintEfectosPago }

function TfrmPrintEfectosPago.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frProveedores];
end;

function TfrmPrintEfectosPago.OrigenProveedores:
  TOrigenProveedoresInformeMultiFiltro;
begin
  Result := opmfEfectosPago;
end;

procedure TfrmPrintEfectosPago.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    FRepositorioEfectos := CrearRepositorioInformeEfectosPagoUniDAC(
      ConexionPrincipal);
    CrearControlesPropios;
    FInicializado := True;
  end;
end;

procedure TfrmPrintEfectosPago.CrearControlesPropios;
var
  lblDesde: TcxLabel;
  lblHasta: TcxLabel;
begin
  if TabFechas <> nil then
  begin
    FrgTipoFecha := TcxRadioGroup.Create(Self);
    FrgTipoFecha.Parent := TabFechas;
    FrgTipoFecha.Left := 190;
    FrgTipoFecha.Top := 12;
    FrgTipoFecha.Width := 155;
    FrgTipoFecha.Height := 94;
    FrgTipoFecha.Caption := SCaptionGrupoFecha;
    FrgTipoFecha.Properties.Items.Add.Caption := SCaptionFechaDocumento;
    FrgTipoFecha.Properties.Items.Add.Caption := SCaptionFechaValor;
    FrgTipoFecha.Properties.Items.Add.Caption :=
    SCaptionFechaVencimiento;
    FrgTipoFecha.ItemIndex := 2;
    FrgSituacion := TcxRadioGroup.Create(Self);
    FrgSituacion.Parent := TabFechas;
    FrgSituacion.Left := 355;
    FrgSituacion.Top := 12;
    FrgSituacion.Width := 150;
    FrgSituacion.Height := 122;
    FrgSituacion.Caption := SCaptionGrupoSituacion;
    FrgSituacion.Properties.Items.Add.Caption := SCaptionSituacionPagados;
    FrgSituacion.Properties.Items.Add.Caption :=
    SCaptionSituacionImpagados;
    FrgSituacion.Properties.Items.Add.Caption :=
    SCaptionSituacionPendientes;
    FrgSituacion.Properties.Items.Add.Caption := SCaptionSituacionTodos;
    FrgSituacion.ItemIndex := 3;
    lblDesde := TcxLabel.Create(Self);
    lblDesde.Parent := TabFechas;
    lblDesde.Transparent := True;
    lblDesde.Left := 16;
    lblDesde.Top := 132;
    lblDesde.Caption := SCaptionNumEfectoDesde;
    FtxtNumeroDesde := TcxTextEdit.Create(Self);
    FtxtNumeroDesde.Parent := TabFechas;
    FtxtNumeroDesde.Left := 16;
    FtxtNumeroDesde.Top := 154;
    FtxtNumeroDesde.Width := 160;
    lblHasta := TcxLabel.Create(Self);
    lblHasta.Parent := TabFechas;
    lblHasta.Transparent := True;
    lblHasta.Left := 190;
    lblHasta.Top := 132;
    lblHasta.Caption := SCaptionNumEfectoHasta;
    FtxtNumeroHasta := TcxTextEdit.Create(Self);
    FtxtNumeroHasta.Parent := TabFechas;
    FtxtNumeroHasta.Left := 190;
    FtxtNumeroHasta.Top := 154;
    FtxtNumeroHasta.Width := 160;
    FchkSoloTotales := TcxCheckBox.Create(Self);
    FchkSoloTotales.Parent := TabFechas;
    FchkSoloTotales.Left := 355;
    FchkSoloTotales.Top := 154;
    FchkSoloTotales.Width := 170;
    FchkSoloTotales.Caption := SCaptionMostrarSoloTotales;
  end;
  FclbTotales := CrearTabChecklist(STituloTotalesInformeEfectosPago);
  CargarTotales;
  FclbTipos := CrearTabChecklist(STituloTiposInformeEfectosPago);
  CargarTiposEfecto;
  FclbSituaciones := CrearTabChecklist(
    STituloSituacionesInformeEfectosPago);
  CargarSituaciones;
  FclbBancos := CrearTabChecklist(STituloBancosInformeEfectosPago);
  CargarBancosRemesa;
end;

procedure TfrmPrintEfectosPago.CargarChecklist(AClb: TcxCheckListBox;
  const AOpciones: TOpcionesInformeEfectosPago);
var
  i: Integer;
  item: TcxCheckListBoxItem;
  sCod: string;
  sNom: string;
begin
  if AClb <> nil then
  begin
    AClb.Items.Clear;
    for i := 0 to Length(AOpciones) - 1 do
    begin
        sCod := AOpciones[i].Codigo;
        sNom := AOpciones[i].Nombre;
        item := AClb.Items.Add;
        if (sNom <> '') and (sNom <> sCod) then
          item.Text := sCod + ' - ' + sNom
        else
          item.Text := sCod;
        item.State := cbsUnchecked;
    end;
  end;
end;

procedure TfrmPrintEfectosPago.CargarTotales;

  procedure Agregar(const ACod, AEtiq: string; AMarcado: Boolean);
  var
    item: TcxCheckListBoxItem;
  begin
    item := FclbTotales.Items.Add;
    item.Text := ACod + ' - ' + AEtiq;
    if AMarcado then
      item.State := cbsChecked
    else
      item.State := cbsUnchecked;
  end;

begin
  if FclbTotales <> nil then
  begin
    FclbTotales.Items.Clear;
    Agregar('ALM', SCaptionAlmacenesInformeEfectosPago, False);
    Agregar('FECHA', SCaptionFechasInformeEfectosPago, False);
    Agregar('PRV', SCaptionProveedoresInformeEfectosPago, False);
    Agregar('BANCO', STituloBancosInformeEfectosPago, True);
    Agregar('ESTADO', STituloSituacionesInformeEfectosPago, False);
    Agregar('TEFE', STituloTiposInformeEfectosPago, False);
  end;
end;

procedure TfrmPrintEfectosPago.CargarTiposEfecto;
begin
  CargarChecklist(FclbTipos, FRepositorioEfectos.ListarTipos);
end;

procedure TfrmPrintEfectosPago.CargarSituaciones;
begin
  CargarChecklist(FclbSituaciones, FRepositorioEfectos.ListarSituaciones);
end;

procedure TfrmPrintEfectosPago.CargarBancosRemesa;
begin
  CargarChecklist(FclbBancos, FRepositorioEfectos.ListarBancos);
end;

function TfrmPrintEfectosPago.CSVTipos: string;
begin
  Result := SeleccionadosCSV(FclbTipos);
end;

function TfrmPrintEfectosPago.CSVSituaciones: string;
begin
  Result := SeleccionadosCSV(FclbSituaciones);
end;

function TfrmPrintEfectosPago.CSVBancos: string;
begin
  Result := SeleccionadosCSV(FclbBancos);
end;

function TfrmPrintEfectosPago.TextoNumero(AEdit: TcxTextEdit): string;
begin
  if AEdit <> nil then
    Result := Trim(AEdit.Text)
  else
    Result := '';
end;

function TfrmPrintEfectosPago.NivelesTotales: TArray<string>;
var
  i: Integer;
  sl: TStringList;
  sCsv: string;
begin
  sCsv := SeleccionadosCSV(FclbTotales);
  if sCsv = '' then
  begin
    SetLength(Result, 1);
    Result[0] := 'BANCO';
  end
  else
  begin
    sl := TStringList.Create;
    try
      sl.StrictDelimiter := True;
      sl.Delimiter := ',';
      sl.DelimitedText := sCsv;
      SetLength(Result, sl.Count);
      for i := 0 to sl.Count - 1 do
        Result[i] := sl[i];
    finally
      FreeAndNil(sl);
    end;
  end;
end;

procedure TfrmPrintEfectosPago.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AnadirOpcionRadio(AResumen, FrgTipoFecha);
  AnadirOpcionRadio(AResumen, FrgSituacion);
  if TextoNumero(FtxtNumeroDesde) <> '' then
    AResumen.Anadir(
      SCaptionNumEfectoDesde, TextoNumero(FtxtNumeroDesde));
  if TextoNumero(FtxtNumeroHasta) <> '' then
    AResumen.Anadir(
      SCaptionNumEfectoHasta, TextoNumero(FtxtNumeroHasta));
  AnadirCasilla(AResumen, FchkSoloTotales);
  // Sin niveles marcados la consulta totaliza por banco.
  AnadirMarcados(
    AResumen,
    STituloTotalesInformeEfectosPago,
    FclbTotales,
    STituloBancosInformeEfectosPago);
  AnadirMarcados(
    AResumen, STituloTiposInformeEfectosPago, FclbTipos);
  AnadirMarcados(
    AResumen, STituloSituacionesInformeEfectosPago, FclbSituaciones);
  AnadirMarcados(
    AResumen, STituloBancosInformeEfectosPago, FclbBancos);
end;

procedure TfrmPrintEfectosPago.preparar_consulta;
var
  criterios: TCriteriosInformeEfectosPago;
begin
  inherited;
  criterios.FechaDesde := DateOf(FechaDesde);
  criterios.FechaHasta := DateOf(FechaHasta);
  criterios.Almacenes := CSVAlmacenes;
  criterios.Proveedores := CSVProveedores;
  criterios.Tipos := CSVTipos;
  criterios.Situaciones := CSVSituaciones;
  criterios.Bancos := CSVBancos;
  criterios.NumeroDesde := TextoNumero(FtxtNumeroDesde);
  criterios.NumeroHasta := TextoNumero(FtxtNumeroHasta);
  if FrgTipoFecha <> nil then
    criterios.TipoFecha := FrgTipoFecha.ItemIndex
  else
    criterios.TipoFecha := 2;
  if FrgSituacion <> nil then
    criterios.ModoSituacion := FrgSituacion.ItemIndex
  else
    criterios.ModoSituacion := 3;
  criterios.Niveles := NivelesTotales;
  if FRepositorioEfectos = nil then
    FRepositorioEfectos := CrearRepositorioInformeEfectosPagoUniDAC(
      ConexionPrincipal);
  FResultadoEfectos := FRepositorioEfectos.Preparar(criterios);
  fxdsEfectosPago.UpdateBounds;
end;

procedure TfrmPrintEfectosPago.AfterReportLoaded;
begin
  inherited;
  fxdsEfectosPago.DataSet := FResultadoEfectos.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsEfectosPago);
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  IncluirDetalleOcultoEnAcumulados;
  RotularFechaElegida;
end;

// FZ-ISSUE-431: el rótulo de la cabecera decía siempre «Fecha vencimiento»;
// ahora nombra la fecha por la que se filtra (documento, valor o
// vencimiento).
procedure TfrmPrintEfectosPago.RotularFechaElegida;
var
  oRotulo: TfrxComponent;
  iTipoFecha: Integer;
begin
  oRotulo := frxrprt1.FindObject('MemoFechaTitulo');
  if (oRotulo is TfrxMemoView) and (FrgTipoFecha <> nil) then
  begin
    iTipoFecha := FrgTipoFecha.ItemIndex;
    if (iTipoFecha >= 0) and
       (iTipoFecha < FrgTipoFecha.Properties.Items.Count) then
      TfrxMemoView(oRotulo).Memo.Text := Trim(SCaptionGrupoFecha) + ' ' +
        AnsiLowerCase(FrgTipoFecha.Properties.Items[iTipoFecha].Caption);
  end;
end;

// "Mostrar sólo totales" oculta MasterData1 y FastReport no acumula las
// bandas invisibles salvo con el indicador 1 de SUM (FZ-ISSUE-003).
procedure TfrmPrintEfectosPago.IncluirDetalleOcultoEnAcumulados;
const
  SReferenciaDetalle = ',MasterData1)';
  SReferenciaDetalleOculto = ',MasterData1,1)';
var
  iComponente: Integer;
  oMemo: TfrxMemoView;
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

procedure TfrmPrintEfectosPago.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  nivel: Integer;
  sNom: string;
begin
  ReportBeforePrintConQR(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if (Pos('GroupHeaderG', sNom) = 1) or
       (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       (FResultadoEfectos <> nil) and FResultadoEfectos.DataSet.Active then
      TfrxBand(Component).Visible :=
        FResultadoEfectos.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> ''
    else if sNom = 'MasterData1' then
      TfrxBand(Component).Visible :=
        (FchkSoloTotales = nil) or (not FchkSoloTotales.Checked);
  end;
end;

end.
