unit inMtoIdiomasProyecto;

interface

uses
  System.Classes, System.JSON;

procedure EditarIdiomasProyecto(AOwner: TComponent; Archivos: TJSONObject);

implementation

uses
  System.SysUtils, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.Dialogs, cxButtons, cxGrid, cxGridLevel, cxGridTableView,
  inMtoFrmBase, inLibIdiomaConsultoria, inLibTextosProyecto;

type
  TEditorIdiomasProyecto = class(TfrmBase)
  private
    FVista: TcxGridTableView;
    procedure AnadirFila(Sender: TObject);
    function LeerFilas: TJSONObject;
  public
    procedure Preparar(Archivos: TJSONObject);
  end;

const
  Idiomas: array[1..4] of string = ('es-ES', 'ca-ES', 'en-GB', 'zh-CN');
  Titulos: array[0..4] of string = ('Clave', 'Español', 'Catalán',
    'Inglés', 'Chino simplificado');

procedure TEditorIdiomasProyecto.AnadirFila(Sender: TObject);
begin
  FVista.DataController.PostEditingData;
  FVista.DataController.RecordCount := FVista.DataController.RecordCount + 1;
  FVista.DataController.FocusedRecordIndex :=
    FVista.DataController.RecordCount - 1;
  FVista.Controller.FocusedItem := FVista.Columns[0];
end;

procedure TEditorIdiomasProyecto.Preparar(Archivos: TJSONObject);
var
  Rejilla: TcxGrid;
  Barra: TPanel;
  Catalogo: TJSONValue;
  Par: TJSONPair;
  I, Fila: Integer;

  procedure Boton(const Rotulo: string; X, Resultado: Integer);
  var
    B: TcxButton;
  begin
    B := TcxButton.Create(Self);
    B.Parent := Barra;
    B.SetBounds(ScaleValue(X), ScaleValue(6), ScaleValue(125), ScaleValue(30));
    B.Caption := TextoConsultoria(Rotulo);
    B.ModalResult := Resultado;
    if Resultado = mrNone then B.OnClick := AnadirFila;
    B.Cancel := Resultado = mrCancel;
  end;

begin
  Caption := TextoConsultoria('Editor de idiomas');
  Position := poOwnerFormCenter;
  ClientWidth := ScaleValue(900);
  ClientHeight := ScaleValue(410);
  Barra := TPanel.Create(Self);
  Barra.Parent := Self;
  Barra.Align := alBottom;
  Barra.Height := ScaleValue(42);
  Boton('Añadir texto', 6, mrNone);
  Boton('Aceptar', 140, mrOk);
  Boton('Cancelar', 274, mrCancel);
  Rejilla := TcxGrid.Create(Self);
  Rejilla.Parent := Self;
  Rejilla.Align := alClient;
  FVista := Rejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  Rejilla.Levels.Add.GridView := FVista;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsView.ColumnAutoWidth := True;
  for I := Low(Titulos) to High(Titulos) do
  begin
    FVista.CreateColumn.Caption := TextoConsultoria(Titulos[I]);
    FVista.Columns[I].DataBinding.ValueType := 'String';
  end;
  Catalogo := Archivos.GetValue(ClaveIdiomasProyecto);
  if Catalogo is TJSONObject then
    for Par in TJSONObject(Catalogo) do
      if Par.JsonValue is TJSONObject then
      begin
        Fila := FVista.DataController.RecordCount;
        FVista.DataController.RecordCount := Fila + 1;
        FVista.DataController.Values[Fila, 0] := Par.JsonString.Value;
        for I := Low(Idiomas) to High(Idiomas) do
          FVista.DataController.Values[Fila, I] :=
            TJSONObject(Par.JsonValue).GetValue<string>(Idiomas[I], '');
      end;
  if FVista.DataController.RecordCount = 0 then AnadirFila(nil);
end;

function TEditorIdiomasProyecto.LeerFilas: TJSONObject;
var
  Fila, I: Integer;
  Clave, Valor: string;
  Textos: TJSONObject;
begin
  FVista.DataController.PostEditingData;
  Result := TJSONObject.Create;
  try
    for Fila := 0 to FVista.DataController.RecordCount - 1 do
    begin
      Clave := Trim(VarToStr(FVista.DataController.Values[Fila, 0]));
      Textos := TJSONObject.Create;
      try
        for I := Low(Idiomas) to High(Idiomas) do
        begin
          Valor := VarToStr(FVista.DataController.Values[Fila, I]);
          if Valor <> '' then Textos.AddPair(Idiomas[I], Valor);
        end;
        if (Clave = '') and (Textos.Count > 0) or
          Assigned(Result.GetValue(Clave)) then
          raise EConvertError.Create(
            TextoConsultoria('Cada fila necesita una clave única.'));
        if Clave <> '' then
        begin
          Result.AddPair(Clave, Textos);
          Textos := nil;
        end;
      finally
        Textos.Free;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure EditarIdiomasProyecto(AOwner: TComponent; Archivos: TJSONObject);
var
  F: TEditorIdiomasProyecto;
  Nuevo: TJSONObject;
  Terminado: Boolean;
begin
  F := TEditorIdiomasProyecto.Create(AOwner);
  try
    F.Preparar(Archivos);
    repeat
      Terminado := F.ShowModal <> mrOk;
      if not Terminado then
      try
        Nuevo := F.LeerFilas;
        if (Nuevo.Count > 0) or Assigned(Archivos.GetValue(ClaveIdiomasProyecto)) then
        begin
          Archivos.RemovePair(ClaveIdiomasProyecto).Free;
          Archivos.AddPair(ClaveIdiomasProyecto, Nuevo);
        end
        else Nuevo.Free;
        Terminado := True;
      except
        on E: EConvertError do ShowMessage(E.Message);
      end;
    until Terminado;
  finally
    F.Free;
  end;
end;

end.
