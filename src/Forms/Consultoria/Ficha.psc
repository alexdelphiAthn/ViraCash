{$FORM TFicha, Ficha.sfm}
uses Classes, SysUtils, Forms;

procedure AlMostrar(Sender: TObject);
begin
  edtCliente.Text := Llamadas.ClienteInicial;
  edtCliente.Enabled := Llamadas.ClienteEditable;
  edtFecha.Text := Llamadas.Campo('FECHA_CLLAM');
  if edtFecha.Text = '' then
    edtFecha.Text := DateTimeToStr(Now);
  edtTelefono.Text := Llamadas.Campo('TELEFONO_CLLAM');
  edtMotivo.Text := Llamadas.Campo('MOTIVO_CLLAM');
  edtResultado.Text := Llamadas.Campo('RESULTADO_CLLAM');
  edtSeguimiento.TextHint := Llamadas.AyudaSeguimiento;
  edtSeguimiento.Text := Llamadas.Campo('SEGUIMIENTO_CLLAM');
end;

procedure Guardar(Sender: TObject);
begin
  if Llamadas.IntentarGuardar(edtCliente.Text, edtFecha.Text, edtTelefono.Text,
    edtMotivo.Text, edtResultado.Text, edtSeguimiento.Text) then
    ModalResult := 1;
end;

begin
end;
