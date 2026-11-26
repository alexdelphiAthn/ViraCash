{$FORM TEditarResultado, EditarResultado.sfm}
uses Classes, Forms;

procedure MostrarResultado(Sender: TObject);
begin
  lblMotivo.Caption := Llamadas.Campo('MOTIVO_CLLAM');
  edtResultado.Text := Llamadas.Campo('RESULTADO_CLLAM');
end;

procedure GuardarResultado(Sender: TObject);
begin
  if Llamadas.IntentarGuardar(Llamadas.ClienteInicial, Llamadas.Campo('FECHA_CLLAM'),
    Llamadas.Campo('TELEFONO_CLLAM'), Llamadas.Campo('MOTIVO_CLLAM'),
    edtResultado.Text, Llamadas.Campo('SEGUIMIENTO_CLLAM')) then
    ModalResult := 1;
end;

begin
end;
