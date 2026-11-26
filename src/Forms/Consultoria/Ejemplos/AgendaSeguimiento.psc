{$FORM TAgendaSeguimiento, AgendaSeguimiento.sfm}
uses Classes, Forms;

procedure MostrarAgendaSeguimiento(Sender: TObject);
begin
  Llamadas.EnlazarInforme(grdInforme, True);
  btnImprimir.Enabled := Llamadas.Puede('imprimir');
end;

procedure ImprimirAgendaSeguimiento(Sender: TObject);
begin
  Llamadas.Imprimir(grdInforme);
end;

begin
end;
