uses Forms, Historial;

var
  Ventana: THistorial;
begin
  Ventana := THistorial.Create(nil);
  try
    Ventana.ShowModal;
  finally
    Ventana.Free;
  end;
end;
