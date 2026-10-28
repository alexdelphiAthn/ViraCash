{ Editor de rangos periódicos de descuento. FZ-ISSUE-727. }
unit inMtoTarifasPeriodicidadVcl;

interface

uses
  System.Classes, cxPC, cxDropDownEdit, cxButtons, cxGrid,
  cxGridTableView, cxLabel, inLibTarifasPeriodicidad;

type
  TEditorPeriodicidadTarifa = class(TComponent)
  private
    FRepositorio: IRepositorioPeriodicidadTarifa;
    FTab: TcxTabSheet;
    FTipo, FDesde, FHasta: TcxComboBox;
    FLista: TcxGridTableView;
    FAnadir, FQuitar, FGuardar: TcxButton;
    FAyuda: TcxLabel;
    FPeriodos: TPeriodosTarifa;
    FCodigo: string;
    FUsuario: string;
    FPuedeEditar: Boolean;
    procedure CambiarTipo(Sender: TObject);
    procedure Anadir(Sender: TObject);
    procedure Quitar(Sender: TObject);
    procedure Guardar(Sender: TObject);
    procedure MostrarRangos;
    procedure ActualizarEstado;
  public
    constructor Create(AOwner: TComponent; APestanas: TcxPageControl;
      const ARepositorio: IRepositorioPeriodicidadTarifa;
      const AUsuario: string); reintroduce;
    procedure Cargar(const ATarifa: string; APuedeEditar: Boolean);
  end;

implementation

uses
  System.SysUtils, System.Variants, Winapi.Windows,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  cxGridLevel, cxGridCustomTableView, cxTextEdit;

procedure Limites(AControl: TControl; X, Y, Ancho, Alto, Ppi: Integer);
begin
  AControl.SetBounds(MulDiv(X, Ppi, 96), MulDiv(Y, Ppi, 96),
    MulDiv(Ancho, Ppi, 96), MulDiv(Alto, Ppi, 96));
end;

constructor TEditorPeriodicidadTarifa.Create(AOwner: TComponent;
  APestanas: TcxPageControl;
  const ARepositorio: IRepositorioPeriodicidadTarifa;
  const AUsuario: string);
var
  Cabecera, Pie: TPanel;
  Rejilla: TcxGrid;
  Nivel: TcxGridLevel;
  Columna: TcxGridColumn;
  Ppi: Integer;
  Etiqueta: TcxLabel;
begin
  inherited Create(AOwner);
  Ppi := 96;
  if Assigned(GetParentForm(APestanas)) then
    Ppi := GetParentForm(APestanas).CurrentPPI;
  FRepositorio := ARepositorio;
  FUsuario := AUsuario;
  FTab := TcxTabSheet.Create(Self);
  FTab.Name := 'tsPeriodicidad';
  FTab.PageControl := APestanas;
  FTab.Caption := 'Periodicidad';
  Cabecera := TPanel.Create(Self);
  Cabecera.Parent := FTab;
  Cabecera.Align := alTop;
  Cabecera.Height := MulDiv(196, Ppi, 96);
  Cabecera.BevelOuter := bvNone;
  FAyuda := TcxLabel.Create(Self);
  FAyuda.Parent := Cabecera;
  FAyuda.Transparent := True;
  FAyuda.Align := alTop;
  FAyuda.AutoSize := False;
  FAyuda.Height := MulDiv(80, Ppi, 96);
  FAyuda.Properties.WordWrap := True;
  FAyuda.Caption := 'Sin rangos: todos los días. Cada fila es una ' +
    'alternativa. Desde = hasta: un día. Desde > hasta: cruza el final ' +
    'de semana, mes o año. Las fechas generales también se respetan.';
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.Transparent := True;
  Limites(Etiqueta, 12, 86, 200, 22, Ppi);
  Etiqueta.Caption := 'Repetir';
  FTipo := TcxComboBox.Create(Self);
  FTipo.Name := 'cmbPeriodoTipo';
  FTipo.Parent := Cabecera;
  Limites(FTipo, 12, 112, 175, 28, Ppi);
  FTipo.Properties.DropDownListStyle := lsFixedList;
  FTipo.Properties.Items.Add('Por día de semana');
  FTipo.Properties.Items.Add('Por día de mes');
  FTipo.Properties.Items.Add('Por día de año');
  FTipo.ItemIndex := 0;
  FTipo.Properties.OnChange := CambiarTipo;
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.Transparent := True;
  Limites(Etiqueta, 204, 86, 160, 22, Ppi);
  Etiqueta.Caption := 'Desde (año: día/mes)';
  FDesde := TcxComboBox.Create(Self);
  FDesde.Name := 'cmbPeriodoDesde';
  FDesde.Parent := Cabecera;
  Limites(FDesde, 204, 112, 160, 28, Ppi);
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.Transparent := True;
  Limites(Etiqueta, 380, 86, 160, 22, Ppi);
  Etiqueta.Caption := 'Hasta (incluido)';
  FHasta := TcxComboBox.Create(Self);
  FHasta.Name := 'cmbPeriodoHasta';
  FHasta.Parent := Cabecera;
  Limites(FHasta, 380, 112, 160, 28, Ppi);
  FAnadir := TcxButton.Create(Self);
  FAnadir.Name := 'btnPeriodoAnadir';
  FAnadir.Parent := Cabecera;
  Limites(FAnadir, 12, 152, 160, 32, Ppi);
  FAnadir.Caption := 'Añadir rango';
  FAnadir.OnClick := Anadir;
  Pie := TPanel.Create(Self);
  Pie.Parent := FTab;
  Pie.Align := alBottom;
  Pie.Height := MulDiv(52, Ppi, 96);
  Pie.BevelOuter := bvNone;
  FQuitar := TcxButton.Create(Self);
  FQuitar.Name := 'btnPeriodoQuitar';
  FQuitar.Parent := Pie;
  Limites(FQuitar, 12, 8, 165, 34, Ppi);
  FQuitar.Caption := 'Quitar rango';
  FQuitar.OnClick := Quitar;
  FGuardar := TcxButton.Create(Self);
  FGuardar.Name := 'btnPeriodoGuardar';
  FGuardar.Parent := Pie;
  Limites(FGuardar, 204, 8, 220, 34, Ppi);
  FGuardar.Caption := 'Guardar periodicidad';
  FGuardar.OnClick := Guardar;
  Rejilla := TcxGrid.Create(Self);
  Rejilla.Name := 'grdPeriodicidad';
  Rejilla.Parent := FTab;
  Rejilla.Align := alClient;
  FLista := Rejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  FLista.Name := 'tvPeriodicidad';
  FLista.OptionsData.Editing := False;
  FLista.OptionsView.GroupByBox := False;
  FLista.OptionsView.ColumnAutoWidth := True;
  Columna := FLista.CreateColumn;
  Columna.Caption := 'Periodicidad';
  Columna.DataBinding.ValueType := 'String';
  Columna.Width := 240;
  Columna := FLista.CreateColumn;
  Columna.Caption := 'Desde';
  Columna.DataBinding.ValueType := 'String';
  Columna.Width := 200;
  Columna := FLista.CreateColumn;
  Columna.Caption := 'Hasta (incluido)';
  Columna.DataBinding.ValueType := 'String';
  Columna.Width := 200;
  Nivel := Rejilla.Levels.Add;
  Nivel.GridView := FLista;
  CambiarTipo(nil);
end;

procedure TEditorPeriodicidadTarifa.CambiarTipo(Sender: TObject);
var
  I, Maximo: Integer;
  Tipo: TTipoPeriodoTarifa;
begin
  FDesde.Properties.Items.Clear;
  FHasta.Properties.Items.Clear;
  Tipo := TTipoPeriodoTarifa(FTipo.ItemIndex);
  if Tipo = pptSemana then
    Maximo := 7
  else if Tipo = pptMes then
    Maximo := 31
  else
    Maximo := 0;
  for I := 1 to Maximo do
  begin
    FDesde.Properties.Items.Add(TextoDiaPeriodo(Tipo, I));
    FHasta.Properties.Items.Add(TextoDiaPeriodo(Tipo, I));
  end;
  if Tipo = pptAno then
  begin
    FDesde.Text := '01/01';
    FHasta.Text := '01/01';
  end
  else
  begin
    FDesde.ItemIndex := 0;
    FHasta.ItemIndex := 0;
  end;
end;

procedure TEditorPeriodicidadTarifa.Anadir(Sender: TObject);
var
  Periodo: TPeriodoTarifa;
  Nuevos: TPeriodosTarifa;
begin
  if FPuedeEditar then
  begin
    Periodo.Tipo := TTipoPeriodoTarifa(FTipo.ItemIndex);
    Periodo.Desde := ValorDiaPeriodo(Periodo.Tipo, FDesde.Text);
    Periodo.Hasta := ValorDiaPeriodo(Periodo.Tipo, FHasta.Text);
    Nuevos := Copy(FPeriodos);
    SetLength(Nuevos, Length(Nuevos) + 1);
    Nuevos[High(Nuevos)] := Periodo;
    ValidarPeriodosTarifa(Nuevos);
    FPeriodos := Nuevos;
    MostrarRangos;
  end;
end;

procedure TEditorPeriodicidadTarifa.Quitar(Sender: TObject);
var
  I, Posicion: Integer;
begin
  Posicion := FLista.DataController.FocusedRecordIndex;
  if FPuedeEditar and (Posicion >= 0) and
     (Posicion < Length(FPeriodos)) then
  begin
    for I := Posicion to High(FPeriodos) - 1 do
      FPeriodos[I] := FPeriodos[I + 1];
    SetLength(FPeriodos, Length(FPeriodos) - 1);
    MostrarRangos;
  end;
end;

procedure TEditorPeriodicidadTarifa.Guardar(Sender: TObject);
begin
  if FPuedeEditar then
  begin
    FRepositorio.Guardar(FCodigo, FPeriodos, FUsuario);
    FAyuda.Caption := 'Periodicidad guardada. ' +
      'Todos los rangos son alternativas y respetan las fechas generales.';
  end;
end;

procedure TEditorPeriodicidadTarifa.MostrarRangos;
var
  I: Integer;
begin
  FLista.BeginUpdate;
  try
    FLista.DataController.RecordCount := Length(FPeriodos);
    for I := 0 to High(FPeriodos) do
    begin
      FLista.DataController.Values[I, 0] :=
        FTipo.Properties.Items[Ord(FPeriodos[I].Tipo)];
      FLista.DataController.Values[I, 1] :=
        TextoDiaPeriodo(FPeriodos[I].Tipo, FPeriodos[I].Desde);
      FLista.DataController.Values[I, 2] :=
        TextoDiaPeriodo(FPeriodos[I].Tipo, FPeriodos[I].Hasta);
    end;
  finally
    FLista.EndUpdate;
  end;
end;

procedure TEditorPeriodicidadTarifa.ActualizarEstado;
begin
  FTipo.Enabled := FPuedeEditar;
  FDesde.Enabled := FPuedeEditar;
  FHasta.Enabled := FPuedeEditar;
  FAnadir.Enabled := FPuedeEditar;
  FQuitar.Enabled := FPuedeEditar;
  FGuardar.Enabled := FPuedeEditar;
end;

procedure TEditorPeriodicidadTarifa.Cargar(const ATarifa: string;
  APuedeEditar: Boolean);
begin
  if FCodigo <> ATarifa then
  begin
    FCodigo := ATarifa;
    FPeriodos := FRepositorio.Cargar(FCodigo);
    MostrarRangos;
  end;
  FPuedeEditar := APuedeEditar and (FCodigo <> '') and
    FRepositorio.Disponible;
  if not FRepositorio.Disponible then
    FAyuda.Caption := 'Periodicidad disponible al instalar la ' +
      'actualización de base de datos 727.';
  ActualizarEstado;
end;

end.
