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
  System.SysUtils, System.Variants, Vcl.Controls, Vcl.ExtCtrls,
  cxGridLevel, cxGridCustomTableView, cxTextEdit,
  inLibMensajesVcl;

constructor TEditorPeriodicidadTarifa.Create(AOwner: TComponent;
  APestanas: TcxPageControl;
  const ARepositorio: IRepositorioPeriodicidadTarifa;
  const AUsuario: string);
var
  Cabecera, Pie: TPanel;
  Rejilla: TcxGrid;
  Nivel: TcxGridLevel;
  Columna: TcxGridColumn;
  Etiqueta: TcxLabel;
begin
  inherited Create(AOwner);
  FRepositorio := ARepositorio;
  FUsuario := AUsuario;
  FTab := TcxTabSheet.Create(Self);
  FTab.Name := 'tsPeriodicidad';
  FTab.PageControl := APestanas;
  FTab.Caption := 'Periodicidad';
  Cabecera := TPanel.Create(Self);
  Cabecera.Parent := FTab;
  Cabecera.Align := alTop;
  Cabecera.Height := 145;
  Cabecera.BevelOuter := bvNone;
  FAyuda := TcxLabel.Create(Self);
  FAyuda.Parent := Cabecera;
  FAyuda.Align := alTop;
  FAyuda.AutoSize := False;
  FAyuda.Height := 58;
  FAyuda.Properties.WordWrap := True;
  FAyuda.Caption := 'Sin rangos: todos los días. Cada fila es una ' +
    'alternativa. Desde = hasta: un día. Desde > hasta: cruza el final ' +
    'de semana, mes o año. Las fechas generales también se respetan.';
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.SetBounds(12, 62, 200, 22);
  Etiqueta.Caption := 'Repetir';
  FTipo := TcxComboBox.Create(Self);
  FTipo.Parent := Cabecera;
  FTipo.SetBounds(12, 90, 175, 28);
  FTipo.Properties.DropDownListStyle := lsFixedList;
  FTipo.Properties.Items.Add('Por día de semana');
  FTipo.Properties.Items.Add('Por día de mes');
  FTipo.Properties.Items.Add('Por día de año');
  FTipo.ItemIndex := 0;
  FTipo.Properties.OnChange := CambiarTipo;
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.SetBounds(204, 62, 160, 22);
  Etiqueta.Caption := 'Desde (año: día/mes)';
  FDesde := TcxComboBox.Create(Self);
  FDesde.Parent := Cabecera;
  FDesde.SetBounds(204, 90, 160, 28);
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.SetBounds(380, 62, 160, 22);
  Etiqueta.Caption := 'Hasta (incluido)';
  FHasta := TcxComboBox.Create(Self);
  FHasta.Parent := Cabecera;
  FHasta.SetBounds(380, 90, 160, 28);
  FAnadir := TcxButton.Create(Self);
  FAnadir.Parent := Cabecera;
  FAnadir.SetBounds(556, 88, 120, 32);
  FAnadir.Caption := 'Añadir rango';
  FAnadir.OnClick := Anadir;
  Pie := TPanel.Create(Self);
  Pie.Parent := FTab;
  Pie.Align := alBottom;
  Pie.Height := 52;
  Pie.BevelOuter := bvNone;
  FQuitar := TcxButton.Create(Self);
  FQuitar.Parent := Pie;
  FQuitar.SetBounds(12, 8, 165, 34);
  FQuitar.Caption := 'Quitar rango';
  FQuitar.OnClick := Quitar;
  FGuardar := TcxButton.Create(Self);
  FGuardar.Parent := Pie;
  FGuardar.SetBounds(204, 8, 220, 34);
  FGuardar.Caption := 'Guardar periodicidad';
  FGuardar.OnClick := Guardar;
  Rejilla := TcxGrid.Create(Self);
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
    ShowMessage_fza('Periodicidad guardada.');
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
