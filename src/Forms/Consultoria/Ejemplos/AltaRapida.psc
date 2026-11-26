{$FORM TAltaRapida, AltaRapida.sfm}
uses Classes, Forms, SysUtils;

procedure MostrarAlta(Sender: TObject);
begin
  edtCliente.Text := Llamadas.ClienteInicial;
  edtCliente.Enabled := Llamadas.ClienteEditable;
end;

procedure GuardarAlta(Sender: TObject);
begin
  if Llamadas.IntentarGuardar(edtCliente.Text, DateTimeToStr(Now), edtTelefono.Text,
    edtMotivo.Text, '', '') then
    ModalResult := 1;
end;

begin
end;
