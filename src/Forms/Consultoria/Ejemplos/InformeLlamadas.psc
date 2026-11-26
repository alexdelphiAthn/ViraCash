{$FORM TInformeLlamadas, InformeLlamadas.sfm}
uses Classes, Forms;

procedure MostrarInformeLlamadas(Sender: TObject);
begin
  Llamadas.EnlazarInforme(grdInforme, False);
  btnImprimir.Enabled := Llamadas.Puede('imprimir');
end;

procedure ImprimirInformeLlamadas(Sender: TObject);
begin
  Llamadas.Imprimir(grdInforme);
end;

begin
end;
