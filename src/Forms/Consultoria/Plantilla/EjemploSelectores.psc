// Ejemplo de relación. El registro guarda el código y la ficha muestra el nombre.
// Cambia estas cadenas para consultar cualquier otra tabla o vista accesible.
// Para seguir este ejemplo, marca empleado y motivo en Datos y publicación.
begin
  if Consultoria.TieneCampo('empleado') then
    Consultoria.Selector('empleado', 'Empleado', 'fza_empleados',
    'CODIGO_EMPL', 'NOMBRE_EMPL', 'ESACTIVO_EMPL', 'S');
end.
