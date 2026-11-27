{$FORM TLista, Lista.sfm}
uses Classes, Forms, Ficha;

procedure AlMostrar(Sender: TObject);
begin
  // El asistente define el origen, los campos y el enlace con el registro principal.
  Consultoria.Lista(pnlLista, TFicha.Create(pnlLista));
end;

begin
end.
