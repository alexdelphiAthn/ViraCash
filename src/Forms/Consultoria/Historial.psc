{$FORM THistorial, Historial.sfm}
uses Classes, Forms, Ficha;

procedure AlMostrar(Sender: TObject);
begin
  Llamadas.EnlazarRejilla(grdLlamadas);
  btnNueva.Enabled := Llamadas.Puede('insertar');
  btnEditar.Enabled := Llamadas.Puede('modificar');
  btnBorrar.Enabled := Llamadas.Puede('borrar');
  btnImprimir.Enabled := Llamadas.Puede('imprimir');
end;

procedure AbrirFicha;
var
  Ventana: TFicha;
begin
  Ventana := TFicha.Create(nil);
  try
    if Ventana.ShowModal = 1 then
      Llamadas.Actualizar;
  finally
    Ventana.Free;
  end;
end;

procedure Nueva(Sender: TObject);
begin
  Llamadas.Nueva;
  AbrirFicha;
end;

procedure Editar(Sender: TObject);
begin
  if Llamadas.Seleccionar then
    AbrirFicha;
end;

procedure Borrar(Sender: TObject);
begin
  Llamadas.Borrar;
end;

procedure Actualizar(Sender: TObject);
begin
  Llamadas.Actualizar;
end;

procedure Imprimir(Sender: TObject);
begin
  Llamadas.Imprimir(grdLlamadas);
end;

begin
end;
