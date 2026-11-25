unit inMtoModalImpSaldoVales;

interface

uses
  System.Classes, System.Variants, Vcl.Controls, Vcl.Forms,
  cxCalendar, cxCheckComboBox, frxDBSet, dxSpreadSheet, Uni,
  inLibInformeMultiFiltroPersistenciaIntf, inLibResumenSeleccionesInforme,
  inMtoModalGenImp, UniDataCajaValesHist;

type
  TfrmPrintSaldoVales = class(TfrmPrint)
  private
    FFechaCorte: TcxDateEdit;
    FEmisionDesde: TcxDateEdit;
    FEmisionHasta: TcxDateEdit;
    FAlmacenes: TcxCheckComboBox;
    FDatosInforme: TfrxDBDataset;
    FConsulta: TUniQuery;
    FDatos: TdmCajaValesHist;
    FEmpresa: string;
    FFiltroUsuario: string;
    FOpciones: TOpcionesInformeMultiFiltro;
    FFiltros: TFiltrosSaldoVales;
    procedure AnadirEtiqueta(const ATexto: string; AEditor: TWinControl);
    function CrearEditorFecha(const AEtiqueta: string; AX, AY: Integer):
      TcxDateEdit;
    procedure SeleccionarFecha(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ValidarFecha(Sender: TObject; var DisplayValue: Variant;
      var ErrorText: TCaption; var Error: Boolean);
    procedure CrearFormatoInforme;
  protected
    procedure AvisarAntesDeConsulta; override;
    procedure ConstruirExcelNativo(AControl: TdxSpreadSheet); override;
    function NombreExportacionPorDefecto(const AExtension: string):
      string; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
  public
    constructor Create(AOwner: TForm; ADatos: TdmCajaValesHist;
      const AEmpresa, AFiltroUsuario: string;
      APuedeImprimir, APuedeExportar: Boolean); reintroduce;
    destructor Destroy; override;
    procedure preparar_consulta; override;
  end;

implementation

uses
  System.SysUtils, System.DateUtils, Vcl.StdCtrls, Vcl.Graphics,
  cxDateUtils, cxEdit, cxLookAndFeelPainters, cxMaskEdit, cxCheckBox,
  frxClass, frCoreClasses, frBaseGraphicsTypes,
  inLibInformeTabular, inLibInformeTabularExcel, inLibMensajesVcl,
  inLibMsgComun;

{$R *.dfm}

resourcestring
  STituloSaldoVales = 'Vales pendientes a fecha de corte';
  SFechaSaldoVales = 'Fecha de corte';
  SFechaSaldoValesInvalida = 'Introduce una fecha de corte válida.';
  SEmisionDesdeSaldoVales = 'Emisión desde (opcional)';
  SEmisionHastaSaldoVales = 'Emisión hasta (opcional)';
  STodosAlmacenesSaldoVales = 'Todos los almacenes';
  SFechaEmisionInvalida = 'Introduce fechas de emisión válidas (dd/mm/aaaa).';
  SRangoEmisionInvalido = 'La emisión desde debe ser anterior o igual a hasta.';
  SEmisionDesdeResumen = 'Emisión desde';
  SEmisionHastaResumen = 'Emisión hasta';
  SAlmacenesSaldoValesResumen = 'Almacenes emisores';
  SVale = 'Vale';
  SFechaEmisionVale = 'Fecha de emisión';
  SHojaVales = 'Vales';
  SAlmacenSaldoVales = 'Almacén emisor';
  SImporteSaldoVales = 'Saldo pendiente';
  STotalesSaldoVales = 'Totales por almacén';


function ColumnasVales: TColumnasInformeTabular;
begin
  Result := [ColumnaInforme('CODIGO_VL', SVale, 2),
    ColumnaInforme('CODIGO_ALM_EMI_VL', SAlmacenSaldoVales, 1),
    ColumnaInforme('FECHA_EMISION_VL', SFechaEmisionVale, 1),
    ColumnaInforme('IMPORTE_NOMINAL_VL', SImporteSaldoVales, 1, '%n')];
end;

constructor TfrmPrintSaldoVales.Create(AOwner: TForm; ADatos: TdmCajaValesHist;
  const AEmpresa, AFiltroUsuario: string;
  APuedeImprimir, APuedeExportar: Boolean);
var
  rAlmacen: TOpcionInformeMultiFiltro;
  oItem: TcxCheckComboBoxItem;
begin
  inherited Create(AOwner);
  PopupMode := pmExplicit;
  PopupParent := AOwner;
  Position := poOwnerFormCenter;
  Caption := STituloSaldoVales;
  UsarFormatoOriginal := True;
  btnVistaPreliminar.Visible := APuedeImprimir;
  btnImprimir.Visible := APuedeImprimir;
  btnExcel.Visible := APuedeExportar;
  btnExcel.OnClick := btnExcelNativoClick;

  FDatos := ADatos;
  FEmpresa := AEmpresa;
  FFiltroUsuario := AFiltroUsuario;
  FOpciones := FDatos.ListarAlmacenesEmisores(FEmpresa, FFiltroUsuario);

  FFechaCorte := CrearEditorFecha(SFechaSaldoVales, 16, 34);
  FFechaCorte.Date := Date;
  FEmisionDesde := CrearEditorFecha(SEmisionDesdeSaldoVales, 16, 88);
  FEmisionHasta := CrearEditorFecha(SEmisionHastaSaldoVales, 216, 88);
  FAlmacenes := TcxCheckComboBox.Create(Self);
  FAlmacenes.Parent := Self;
  FAlmacenes.SetBounds(ScaleValue(16), ScaleValue(142), ScaleValue(384),
    ScaleValue(26));
  FAlmacenes.Properties.EmptySelectionText := STodosAlmacenesSaldoVales;
  FAlmacenes.Properties.EditValueFormat := cvfStatesString;
  FAlmacenes.Properties.DropDownRows := 8;
  for rAlmacen in FOpciones do
  begin
    oItem := FAlmacenes.Properties.Items.Add;
    oItem.Description := rAlmacen.Codigo;
    if Trim(rAlmacen.Nombre) <> '' then
      oItem.Description := rAlmacen.Codigo + ' - ' + rAlmacen.Nombre;
  end;
  FAlmacenes.Enabled := Length(FOpciones) > 0;
  AnadirEtiqueta(SAlmacenesSaldoValesResumen, FAlmacenes);
  ActiveControl := FFechaCorte;

  FDatosInforme := TfrxDBDataset.Create(Self);
  FDatosInforme.Name := 'fxdsSaldoVales';
  FDatosInforme.UserName := 'Vales';
  CrearFormatoInforme;
end;

destructor TfrmPrintSaldoVales.Destroy;
begin
  if Assigned(FDatosInforme) then
    FDatosInforme.DataSet := nil;
  FConsulta.Free;
  inherited;
end;

procedure TfrmPrintSaldoVales.AnadirEtiqueta(const ATexto: string;
  AEditor: TWinControl);
var
  oEtiqueta: TLabel;
begin
  oEtiqueta := TLabel.Create(Self);
  oEtiqueta.Parent := Self;
  oEtiqueta.Left := AEditor.Left;
  oEtiqueta.Top := AEditor.Top - ScaleValue(18);
  oEtiqueta.Caption := ATexto;
  oEtiqueta.FocusControl := AEditor;
end;

function TfrmPrintSaldoVales.CrearEditorFecha(const AEtiqueta: string;
  AX, AY: Integer): TcxDateEdit;
begin
  Result := TcxDateEdit.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(ScaleValue(AX), ScaleValue(AY), ScaleValue(184),
    ScaleValue(26));
  Result.Properties.InputKind := ikStandard;
  Result.Properties.AutoSelect := True;
  Result.Properties.SaveTime := False;
  Result.Properties.ValidationOptions := [evoShowErrorIcon];
  Result.Properties.OnValidate := ValidarFecha;
  Result.OnMouseUp := SeleccionarFecha;
  AnadirEtiqueta(AEtiqueta, Result);
end;

procedure TfrmPrintSaldoVales.SeleccionarFecha(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (Shift = []) then
    TcxDateEdit(Sender).SelectAll;
end;

procedure TfrmPrintSaldoVales.ValidarFecha(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sTexto: string;
  dFecha: TDateTime;
begin
  if Sender = FFechaCorte then
    ErrorText := SFechaSaldoValesInvalida
  else
    ErrorText := SFechaEmisionInvalida;

  sTexto := Trim(TcxDateEdit(Sender).Text);
  if VarIsType(DisplayValue, varDate) then
  begin
    dFecha := VarToDateTime(DisplayValue);
    Error := False;
  end
  else if sTexto = '' then
  begin
    dFecha := 0;
    Error := Sender = FFechaCorte;
  end
  else
    Error := not TryStrToDate(sTexto, dFecha);

  if not Error and ((sTexto <> '') or (dFecha <> 0)) then
  begin
    Error := (YearOf(dFecha) < 1000) or
      ((Sender = FFechaCorte) and (dFecha >= EncodeDate(9999, 12, 31)));
    if not Error then
      DisplayValue := DateToStr(dFecha);
  end;
end;

procedure TfrmPrintSaldoVales.AvisarAntesDeConsulta;
begin
  inherited;
  if not (FFechaCorte.ValidateEdit and FEmisionDesde.ValidateEdit and
    FEmisionHasta.ValidateEdit) then
    Abort;
  FFechaCorte.PostEditValue;
  FEmisionDesde.PostEditValue;
  FEmisionHasta.PostEditValue;
  if (FEmisionDesde.Date <> NullDate) and (FEmisionHasta.Date <> NullDate)
    and (FEmisionDesde.Date > FEmisionHasta.Date) then
  begin
    ShowMessage_fza(SRangoEmisionInvalido);
    FEmisionHasta.SetFocus;
    Abort;
  end;
end;

procedure TfrmPrintSaldoVales.preparar_consulta;
var
  iAlmacen: Integer;
  oConsulta: TUniQuery;
begin
  FFiltros := Default(TFiltrosSaldoVales);
  FFiltros.Corte := FFechaCorte.Date;
  if FEmisionDesde.Date <> NullDate then
    FFiltros.EmisionDesde := FEmisionDesde.Date;
  if FEmisionHasta.Date <> NullDate then
    FFiltros.EmisionHasta := FEmisionHasta.Date;
  for iAlmacen := 0 to High(FOpciones) do
    if FAlmacenes.States[iAlmacen] = cbsChecked then
      FFiltros.Almacenes := FFiltros.Almacenes + [FOpciones[iAlmacen].Codigo];
  oConsulta := FDatos.ConsultarSaldoVales(FEmpresa, FFiltroUsuario, FFiltros);
  FDatosInforme.DataSet := nil;
  FConsulta.Free;
  FConsulta := oConsulta;
  FDatosInforme.DataSet := FConsulta;
end;

procedure TfrmPrintSaldoVales.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AResumen.Anadir(SFechaSaldoVales, DateToStr(FFiltros.Corte));
  if FFiltros.EmisionDesde <> 0 then
    AResumen.Anadir(SEmisionDesdeResumen, DateToStr(FFiltros.EmisionDesde));
  if FFiltros.EmisionHasta <> 0 then
    AResumen.Anadir(SEmisionHastaResumen, DateToStr(FFiltros.EmisionHasta));
  if Length(FFiltros.Almacenes) > 0 then
    AResumen.Anadir(SAlmacenesSaldoValesResumen,
      string.Join(', ', FFiltros.Almacenes));
end;

procedure TfrmPrintSaldoVales.ConstruirExcelNativo(AControl: TdxSpreadSheet);
var
  aResumen: TArray<string>;
begin
  aResumen := LineasResumenSelecciones;
  AControl.ClearAll;
  AnadirResumenInformeTabularExcel(AControl, FConsulta, STotalesSaldoVales,
    [ColumnaInforme('CODIGO_ALM_EMI_VL', SAlmacenSaldoVales, 2),
     ColumnaInforme('IMPORTE_NOMINAL_VL', SImporteSaldoVales, 1, '%n')],
    '', True, aResumen);
  AnadirHojaInformeTabularExcel(AControl, FConsulta, SHojaVales, ColumnasVales,
    True, STituloSaldoVales, aResumen);
end;

function TfrmPrintSaldoVales.NombreExportacionPorDefecto(
  const AExtension: string): string;
begin
  Result := 'Vales_pendientes_' + FormatDateTime('yyyymmdd', FFiltros.Corte) +
    AExtension;
end;

procedure TfrmPrintSaldoVales.CrearFormatoInforme;
const
  cSaldo = '[FormatFloat(''#,##0.00'', ' +
    'SUM(<Vales."IMPORTE_NOMINAL_VL">, DetalleTabla))]';
var
  oPagina: TfrxReportPage;
  oGrupo: TfrxGroupHeader;
  oTexto: TfrxMemoView;

  procedure AnadirTotal(ABanda: TfrxBand; const ANombre, AEtiqueta: string;
    ATop: Double);
  var
    oTotal: TfrxMemoView;
  begin
    ABanda.Top := ATop;
    ABanda.Height := 24;
    oTotal := TfrxMemoView.Create(ABanda);
    oTotal.Name := ANombre;
    oTotal.SetBounds(0, 0, 277 * fr01cm - 3, 22);
    oTotal.Font.Style := [fsBold];
    oTotal.HAlign := haRight;
    oTotal.Text := AEtiqueta + '  ' + cSaldo;
  end;

begin
  CrearInformeTabular(frxReportOrigen, FDatosInforme, STituloSaldoVales,
    ColumnasVales);
  oPagina := frxReportOrigen.FindObject('Pagina') as TfrxReportPage;
  oTexto := frxReportOrigen.FindObject('Dato2') as TfrxMemoView;
  oTexto.DisplayFormat.Kind := fkDateTime;
  oTexto.DisplayFormat.FormatStr := 'dd/mm/yyyy';
  oGrupo := TfrxGroupHeader.Create(oPagina);
  oGrupo.Name := 'GrupoAlmacen';
  oGrupo.Condition := '<Vales."CODIGO_ALM_EMI_VL">';
  oGrupo.Top := 79;
  oGrupo.Height := 0;
  AnadirTotal(TfrxGroupFooter.Create(oPagina), 'TotalAlmacen',
    SAlmacenSaldoVales + ' [<Vales."CODIGO_ALM_EMI_VL">]', 108);
  AnadirTotal(TfrxReportSummary.Create(oPagina), 'TotalGeneral',
    STextoTotalComun, 134);
  (frxReportOrigen.FindObject('PieTabla') as TfrxPageFooter).Top := 164;
end;

end.
