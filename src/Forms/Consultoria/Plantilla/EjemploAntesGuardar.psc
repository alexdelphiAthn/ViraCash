// Ejemplo para una tabla que tenga un campo llamado motivo.
// Adapta el nombre del campo a tu tabla antes de publicar.
begin
  if Registro.TieneCampo('motivo') then
    if Registro.Texto('motivo') = '' then
      Error := 'Indique el motivo antes de guardar.';
end.
