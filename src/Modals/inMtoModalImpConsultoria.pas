{ Impresión y hoja de cálculo de los listados de consultoría. }
unit inMtoModalImpConsultoria;

interface

uses
  System.Classes, Datasnap.DBClient, cxGridDBTableView, dxSpreadSheet,
  dxPSCore,
  inLibInformeTabular, inMtoModalGenImp;

type
  TfrmPrintConsultoria = class(TfrmPrint)
  private
    FImpresora: TdxComponentPrinter;
    FEnlaceDX: TBasedxReportLink;
    FDatos: TClientDataSet;
    FColumnas: TColumnasInformeTabular;
    procedure VistaPreviaDX(Sender: TObject);
    procedure ImprimirDX(Sender: TObject);
    procedure Preparar(AVista: TcxGridDBTableView; const ATitulo,
      AIdentificador: string; APuedeDisenar, AUsaFastReport: Boolean);
  protected
    procedure ConstruirExcelNativo(AControl: TdxSpreadSheet); override;
  public
    class procedure Abrir(AVista: TcxGridDBTableView; const ATitulo,
      AIdentificador: string; APuedeDisenar, AUsaFastReport: Boolean); static;
    procedure preparar_consulta; override;
  end;

procedure ImprimirRejillaDX(AVista: TcxGridDBTableView);

implementation

uses
  System.SysUtils, System.Math, System.Hash, System.Variants,
  Winapi.Windows, Data.DB, Vcl.Forms, Vcl.Controls, Vcl.Menus, cxLabel,
  cxLookupEdit, frxDBSet, inMtoFrmBase, inLibInformeTabularExcel,
  inLibMsgScripter, dxPScxGridLnk, dxPrintUtils;

function EnlaceImpresionDX(AImpresora: TdxComponentPrinter;
  AVista: TcxGridDBTableView): TdxGridReportLink;
begin
  Result := AImpresora.AddLink(AVista.Control) as TdxGridReportLink;
  Result.OptionsSize.AutoWidth := True;
  Result.OptionsOnEveryPage.Headers := True;
  Result.OptionsView.Caption := False;
  Result.OptionsView.FilterBar := AVista.DataController.Filter.Active and
    not AVista.DataController.Filter.IsEmpty;
end;

procedure ImprimirRejillaDX(AVista: TcxGridDBTableView);
var
  Impresora: TdxComponentPrinter;
begin
  Impresora := TdxComponentPrinter.Create(nil);
  try
    Impresora.Preview(True, EnlaceImpresionDX(Impresora, AVista));
  finally
    Impresora.Free;
  end;
end;

procedure TfrmPrintConsultoria.VistaPreviaDX(Sender: TObject);
begin
  FImpresora.Preview(True, FEnlaceDX);
end;

procedure TfrmPrintConsultoria.ImprimirDX(Sender: TObject);
begin
  FImpresora.Print(True, nil, FEnlaceDX);
end;

class procedure TfrmPrintConsultoria.Abrir(AVista: TcxGridDBTableView;
  const ATitulo, AIdentificador: string; APuedeDisenar, AUsaFastReport: Boolean);
var
  Padre: TWinControl;
  Propietario: TForm;
  Dialogo: TfrmPrintConsultoria;
begin
  Padre := AVista.Site;
  while Assigned(Padre) and not (Padre is TfrmBase) do
    Padre := Padre.Parent;
  if Assigned(Padre) then
    Propietario := TForm(Padre)
  else
    Propietario := Application.MainForm;
  Dialogo := TfrmPrintConsultoria.Create(Propietario);
  try
    Dialogo.PopupMode := pmExplicit;
    Dialogo.PopupParent := Propietario;
    Dialogo.Preparar(AVista, ATitulo, AIdentificador, APuedeDisenar,
      AUsaFastReport);
    Dialogo.ShowModal;
  finally
    Dialogo.Free;
  end;
end;

procedure TfrmPrintConsultoria.Preparar(AVista: TcxGridDBTableView;
  const ATitulo, AIdentificador: string; APuedeDisenar, AUsaFastReport: Boolean);
var
  Enlace: TfrxDBDataset;
  Columna: TcxGridDBColumn;
  Campo: TField;
  Tipo: TFieldType;
  NombreCampo, Formato, Papel: string;
  i, Fila, Registro, Ancho, AnchoTotal: Integer;
  Vertical: Boolean;
  Etiqueta: TcxLabel;
begin
  if AVista.VisibleColumnCount = 0 then
    raise EArgumentException.Create(SMarqueCampo);
  Caption := ATitulo;
  // Los formatos de cada elemento tienen la misma clave al volver a abrirlo.
  Name := 'frmCons' + Copy(THashSHA2.GetHashString(AIdentificador), 1, 24);
  MostrarDisenosGuardados := AUsaFastReport and (AIdentificador <> '');
  UsarFormatoOriginal := not MostrarDisenosGuardados;
  btnEditar.Visible := APuedeDisenar and MostrarDisenosGuardados;
  btnPDF.Enabled := AUsaFastReport;
  btnExcel.OnClick := btnExcelNativoClick;
  FDatos := TClientDataSet.Create(Self);
  SetLength(FColumnas, AVista.VisibleColumnCount);
  AnchoTotal := 0;
  for i := 0 to High(FColumnas) do
  begin
    Columna := TcxGridDBColumn(AVista.VisibleColumns[i]);
    Campo := Columna.DataBinding.Field;
    Tipo := ftWideMemo;
    Formato := '';
    if Assigned(Campo) and
      not (Columna.Properties is TcxCustomLookupEditProperties) then
    begin
      if Campo is TNumericField then
      begin
        if Campo.DataType in [ftSmallint, ftInteger, ftWord, ftAutoInc,
          ftLargeint, ftShortint, ftLongWord, ftByte] then
          Tipo := ftLargeint
        else
          Tipo := ftFloat;
        Formato := '%g';
        if Campo is TCurrencyField then
          Formato := '%n';
      end
      else if Campo.DataType in [ftBoolean, ftDate, ftTime, ftDateTime,
        ftTimeStamp] then
      begin
        Tipo := Campo.DataType;
        if Tipo = ftTimeStamp then
          Tipo := ftDateTime;
      end;
    end;
    NombreCampo := Columna.DataBinding.FieldName;
    if NombreCampo = '' then
      NombreCampo := 'Columna' + IntToStr(i + 1);
    while FDatos.FieldDefs.IndexOf(NombreCampo) >= 0 do
      NombreCampo := NombreCampo + '_';
    FDatos.FieldDefs.Add(NombreCampo, Tipo);
    Ancho := Max(1, MulDiv(Columna.Width, 96, AVista.Site.CurrentPPI));
    Inc(AnchoTotal, Ancho);
    FColumnas[i] := ColumnaInforme(NombreCampo, Columna.Caption,
      Ancho / 100, Formato);
    case Tipo of
      ftWideMemo: FColumnas[i].FormatoExcel := '@';
      ftBoolean: FColumnas[i].FormatoExcel := 'General';
      ftDate: FColumnas[i].FormatoExcel := 'dd/mm/yyyy';
      ftTime: FColumnas[i].FormatoExcel := 'hh:mm:ss';
      ftDateTime: FColumnas[i].FormatoExcel := 'dd/mm/yyyy hh:mm:ss';
    end;
  end;
  FDatos.CreateDataSet;
  FDatos.LogChanges := False;
  for Fila := 0 to AVista.DataController.FilteredRecordCount - 1 do
  begin
    Registro := AVista.DataController.FilteredRecordIndex[Fila];
    FDatos.Append;
    for i := 0 to High(FColumnas) do
    begin
      Columna := TcxGridDBColumn(AVista.VisibleColumns[i]);
      if not VarIsNull(AVista.DataController.Values[Registro,
        Columna.Index]) then
        if FDatos.Fields[i].DataType = ftWideMemo then
          FDatos.Fields[i].AsString := AVista.DataController.GetDisplayText(
            Registro, Columna.Index)
        else
          FDatos.Fields[i].Value := AVista.DataController.Values[
            Registro, Columna.Index];
    end;
    FDatos.Post;
  end;
  // A4 vertical, con diez milímetros de margen en cada lateral.
  Vertical := AnchoTotal <= Round(190 * 96 / 25.4);
  if AUsaFastReport then
  begin
    Enlace := TfrxDBDataset.Create(Self);
    Enlace.Name := 'fxdsListado';
    Enlace.UserName := 'Listado';
    Enlace.DataSet := FDatos;
    CrearInformeTabular(frxReportOrigen, Enlace, ATitulo, FColumnas, Vertical);
  end
  else
  begin
    FImpresora := TdxComponentPrinter.Create(Self);
    FEnlaceDX := EnlaceImpresionDX(FImpresora, AVista);
    FEnlaceDX.PrinterPage.DMPaper := DMPAPER_A4;
    if Vertical then
      FEnlaceDX.PrinterPage.Orientation := poPortrait
    else
      FEnlaceDX.PrinterPage.Orientation := poLandscape;
    btnVistaPreliminar.OnClick := VistaPreviaDX;
    btnImprimir.OnClick := ImprimirDX;
  end;
  ClientWidth := ScaleValue(440);
  if Vertical then
    Papel := '210 × 297 mm'
  else
    Papel := '297 × 210 mm';
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Self;
  Etiqueta.SetBounds(ScaleValue(12), ScaleValue(12),
    pnl1.Left - ScaleValue(20), ScaleValue(30));
  Etiqueta.Caption := 'A4 · ' + Papel;
  preparar_consulta;
end;

procedure TfrmPrintConsultoria.preparar_consulta;
begin
  FDatos.First;
end;

procedure TfrmPrintConsultoria.ConstruirExcelNativo(AControl: TdxSpreadSheet);
begin
  ExportarInformeTabularExcel(AControl, FDatos, Caption, FColumnas, nil);
end;

end.
