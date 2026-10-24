unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, 
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxFilter, dxScrollbarAnnotations, cxEdit,
  cxCheckBox, cxVGrid, cxInplaceContainer, cxTextEdit, cxContainer, 
  dxCoreGraphics, cxMaskEdit, cxButtonEdit, cxSpinEdit,
  Vcl.ExtCtrls, inMtoFrmBase;

type
  TForm1 = class(TFrmBase)
    Panel1: TPanel;
    cxButtonEdit1: TcxButtonEdit;
    Panel2: TPanel;
    cxVerticalGrid1: TcxVerticalGrid;
    cxVerticalGrid1EditorRow1: TcxEditorRow;
    cxVerticalGrid1EditorRow2: TcxEditorRow;
    cxVerticalGrid1EditorRow3: TcxEditorRow;
    cxVerticalGrid1EditorRow4: TcxEditorRow;
    cxVerticalGrid1EditorRow5: TcxEditorRow;
    cxVerticalGrid1EditorRow6: TcxEditorRow;
    cxVerticalGrid1EditorRow7: TcxEditorRow;
    cxVerticalGrid1EditorRow8: TcxEditorRow;
    cxVerticalGrid1EditorRow9: TcxEditorRow;
    cxVerticalGrid1EditorRow10: TcxEditorRow;
    cxVerticalGrid1EditorRow11: TcxEditorRow;
    cxVerticalGrid1EditorRow12: TcxEditorRow;
    cxVerticalGrid1EditorRow13: TcxEditorRow;
    cxVerticalGrid1EditorRow14: TcxEditorRow;
    cxVerticalGrid1EditorRow15: TcxEditorRow;
    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure cxButtonEdit1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    procedure FiltrarVerticalGrid(Grid: TcxVerticalGrid; Texto: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  StrUtils; // Necesario para la función AnsiContainsText (búsqueda insensible a mayúsculas)

// ...

procedure TForm1.cxButtonEdit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

procedure TForm1.cxButtonEdit1PropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(cxVerticalGrid1, cxButtonEdit1.Text);
end;

procedure TForm1.FiltrarVerticalGrid(Grid: TcxVerticalGrid; Texto: string);
var
  i: Integer;

  // Función local recursiva para revisar filas y sus hijos
 function ProcesarFila(Row: TcxCustomRow): Boolean;
  var
    j: Integer;
    Coincide: Boolean;
    HijoVisible: Boolean;
    TextoFila: string;
  begin
    // 1. Obtenemos el texto de la fila de forma segura según su tipo
    TextoFila := '';
    if Row is TcxEditorRow then
      TextoFila := TcxEditorRow(Row).Properties.Caption
    else if Row is TcxCategoryRow then
      TextoFila := TcxCategoryRow(Row).Properties.Caption;

    // 2. Comprobamos coincidencia (usando la variable TextoFila)
    Coincide := (AnsiContainsText(TextoFila, Texto));
	//(Texto = '') or (AnsiContainsText(TextoFila, Texto));

    {// 3. Revisamos los hijos (recursividad)
    HijoVisible := False;
    for j := 0 to Row.Count - 1 do
    begin
      if ProcesarFila(Row.Rows[j]) then
        HijoVisible := True;
    end;}

    // 4. Asignar visibilidad
    Row.Visible := Coincide;// or HijoVisible;
    Result := Row.Visible;
  end;

begin
  Grid.BeginUpdate; // Congela el pintado para que sea rápido y no parpadee
  try
    for i := 0 to Grid.Rows.Count - 1 do
      ProcesarFila(Grid.Rows[i]);
  finally
    Grid.EndUpdate;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if cxbuttonedit1.CanFocus then
    cxbuttonedit1.SetFocus;
end;

end.
