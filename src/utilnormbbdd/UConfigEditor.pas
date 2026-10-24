unit UConfigEditor;

{
  Editor de configuración del normalizador. Permite editar:
    - Sufijos por tabla
    - Reglas de auditoría
    - Lista de abreviaturas (regex → reemplazo)
    - Lista de excepciones (tabla, columna_vieja → columna_nueva)

  El layout se construye con un TPageControl y cuatro TStringGrid editables.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Grids,
  UNormalizerEngine;

type
  TFormConfigEditor = class(TForm)
    PageControl: TPageControl;
    tabSuffixes:    TTabSheet;
    tabAudit:       TTabSheet;
    tabAbbrev:      TTabSheet;
    tabExceptions:  TTabSheet;
    GridSuffixes:   TStringGrid;
    GridAudit:      TStringGrid;
    GridAbbrev:     TStringGrid;
    GridExceptions: TStringGrid;
    PanelButtons:   TPanel;
    btnOK:          TButton;
    btnCancel:      TButton;
    btnReset:       TButton;
    btnAddRow:      TButton;
    btnDeleteRow:   TButton;
    lblHelp:        TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnAddRowClick(Sender: TObject);
    procedure btnDeleteRowClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FNormalizer: TViraCashNormalizer;
    procedure SetupGrids;
    procedure ActiveGrid(out Grid: TStringGrid);
  public
    property Normalizer: TViraCashNormalizer read FNormalizer write FNormalizer;
    procedure LoadFromNormalizer;
    procedure ApplyToNormalizer;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes;

resourcestring
  STituloEditorConfiguracion = 'Editar configuración del normalizador';
  SColumnaTabla = 'Tabla';
  SColumnaSufijo = 'Sufijo';
  SColumnaActual = 'Columna actual';
  SColumnaNueva = 'Columna nueva';
  SColumnaPatronReemplazo = 'Patrón (palabra a reemplazar)';
  SColumnaReemplazo = 'Reemplazo';
  SPreguntaRestablecerConfiguracion =
    '¿Restablecer toda la configuración a los valores por defecto?'#13#10 +
    'Se perderán los cambios que hayas hecho en esta ventana.';

procedure TFormConfigEditor.FormCreate(Sender: TObject);
begin
  Caption  := STituloEditorConfiguracion;
  Position := poOwnerFormCenter;
  Width    := 800;
  Height   := 560;
  SetupGrids;
end;

procedure TFormConfigEditor.SetupGrids;

  procedure CfgGrid(G: TStringGrid; const Headers: array of string;
                    const Widths: array of Integer);
  var
    i: Integer;
  begin
    G.ColCount  := Length(Headers);
    G.RowCount  := 2;
    G.FixedRows := 1;
    G.FixedCols := 0;
    G.Options   := G.Options + [goEditing, goAlwaysShowEditor, goRowSelect,
                                 goColSizing, goThumbTracking];
    for i := 0 to Length(Headers) - 1 do
    begin
      G.Cells[i, 0] := Headers[i];
      if i < Length(Widths) then G.ColWidths[i] := Widths[i];
    end;
  end;

begin
  CfgGrid(GridSuffixes, [SColumnaTabla, SColumnaSufijo], [400, 120]);
  CfgGrid(GridAudit, [SColumnaActual, SColumnaNueva], [220, 220]);
  CfgGrid(GridAbbrev, [SColumnaPatronReemplazo, SColumnaReemplazo],
    [260, 260]);
  CfgGrid(GridExceptions,
    [SColumnaTabla, SColumnaActual, SColumnaNueva], [240, 240, 240]);
end;

procedure TFormConfigEditor.ActiveGrid(out Grid: TStringGrid);
begin
  if PageControl.ActivePage = tabSuffixes then       Grid := GridSuffixes
  else if PageControl.ActivePage = tabAudit then     Grid := GridAudit
  else if PageControl.ActivePage = tabAbbrev then    Grid := GridAbbrev
  else                                                Grid := GridExceptions;
end;

procedure TFormConfigEditor.LoadFromNormalizer;
var
  Pair:  TPair<string, string>;
  KV:    TKVPair;
  E:     TExceptionEntry;
  Row:   Integer;
begin
  // Sufijos
  GridSuffixes.RowCount := FNormalizer.TableSuffixes.Count + 1;
  Row := 1;
  for Pair in FNormalizer.TableSuffixes do
  begin
    GridSuffixes.Cells[0, Row] := Pair.Key;
    GridSuffixes.Cells[1, Row] := Pair.Value;
    Inc(Row);
  end;

  // Auditoría
  GridAudit.RowCount := FNormalizer.AuditRenames.Count + 1;
  Row := 1;
  for Pair in FNormalizer.AuditRenames do
  begin
    GridAudit.Cells[0, Row] := Pair.Key;
    GridAudit.Cells[1, Row] := Pair.Value;
    Inc(Row);
  end;

  // Abreviaturas
  GridAbbrev.RowCount := FNormalizer.Abbreviations.Count + 1;
  Row := 1;
  for KV in FNormalizer.Abbreviations do
  begin
    GridAbbrev.Cells[0, Row] := KV.Key;
    GridAbbrev.Cells[1, Row] := KV.Value;
    Inc(Row);
  end;

  // Excepciones
  GridExceptions.RowCount := FNormalizer.Exceptions.Count + 1;
  Row := 1;
  for E in FNormalizer.Exceptions do
  begin
    GridExceptions.Cells[0, Row] := E.TableName;
    GridExceptions.Cells[1, Row] := E.OldColumn;
    GridExceptions.Cells[2, Row] := E.NewColumn;
    Inc(Row);
  end;
end;

procedure TFormConfigEditor.ApplyToNormalizer;
var
  i: Integer;
  K, V: string;
begin
  // Reescribimos todas las colecciones desde lo que muestra la UI
  FNormalizer.TableSuffixes.Clear;
  for i := 1 to GridSuffixes.RowCount - 1 do
  begin
    K := GridSuffixes.Cells[0, i].Trim;
    V := GridSuffixes.Cells[1, i].Trim;
    if (K <> '') and (V <> '') then
      FNormalizer.SetTableSuffix(K, V);
  end;

  FNormalizer.AuditRenames.Clear;
  for i := 1 to GridAudit.RowCount - 1 do
  begin
    K := GridAudit.Cells[0, i].Trim;
    V := GridAudit.Cells[1, i].Trim;
    if (K <> '') and (V <> '') then
      FNormalizer.SetAuditRename(K, V);
  end;

  FNormalizer.ClearAbbreviations;
  for i := 1 to GridAbbrev.RowCount - 1 do
  begin
    K := GridAbbrev.Cells[0, i].Trim;
    V := GridAbbrev.Cells[1, i].Trim;
    if (K <> '') and (V <> '') then
      FNormalizer.AddAbbreviation(K, V);
  end;

  FNormalizer.ClearExceptions;
  for i := 1 to GridExceptions.RowCount - 1 do
  begin
    K := GridExceptions.Cells[0, i].Trim;
    if K = '' then Continue;
    FNormalizer.AddException(K,
      GridExceptions.Cells[1, i].Trim,
      GridExceptions.Cells[2, i].Trim);
  end;
end;

procedure TFormConfigEditor.btnAddRowClick(Sender: TObject);
var
  G: TStringGrid;
begin
  ActiveGrid(G);
  G.RowCount := G.RowCount + 1;
  G.Row := G.RowCount - 1;
  G.SetFocus;
end;

procedure TFormConfigEditor.btnDeleteRowClick(Sender: TObject);
var
  G: TStringGrid;
  i: Integer;
begin
  ActiveGrid(G);
  if (G.Row < 1) or (G.Row >= G.RowCount) then Exit;
  for i := G.Row to G.RowCount - 2 do
  begin
    G.Rows[i].Assign(G.Rows[i + 1]);
  end;
  if G.RowCount > 2 then
    G.RowCount := G.RowCount - 1
  else
  begin
    // Dejar una fila vacía
    G.Cells[0, 1] := '';
    G.Cells[1, 1] := '';
    if G.ColCount > 2 then G.Cells[2, 1] := '';
  end;
end;

procedure TFormConfigEditor.btnResetClick(Sender: TObject);
begin
  if MessageDlg(SPreguntaRestablecerConfiguracion,
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  FNormalizer.ResetToDefaults;
  LoadFromNormalizer;
end;

procedure TFormConfigEditor.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TFormConfigEditor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
