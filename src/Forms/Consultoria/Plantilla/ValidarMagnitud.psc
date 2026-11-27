begin
  if Registro.Texto('ESACTIVO_CMM') = '' then Registro.Asignar('ESACTIVO_CMM', 'S');
  if Registro.Texto('VALOR_MINIMO_CMM') = '' then Registro.Asignar('VALOR_MINIMO_CMM', 0);
  if Registro.Texto('VALOR_MAXIMO_CMM') = '' then Registro.Asignar('VALOR_MAXIMO_CMM', 300);
  if Registro.Texto('ORDEN_CMM') = '' then Registro.Asignar('ORDEN_CMM', 0);
  if (Registro.Texto('CODIGO_CMM') = '') or (Registro.Texto('NOMBRE_CMM') = '') or
     (Registro.Texto('UNIDAD_CMM') = '') then
    Error := Idiomas.Texto('medida.campos',
      'Indique el código, el nombre y la unidad de medida.')
  else if (Registro.Campo('VALOR_MINIMO_CMM') < 0) or
          (Registro.Campo('VALOR_MAXIMO_CMM') < Registro.Campo('VALOR_MINIMO_CMM')) then
    Error := Idiomas.Texto('medida.limites',
      'Revise el mínimo y el máximo de la medida.')
  else if (Registro.Texto('ESACTIVO_CMM') <> 'S') and (Registro.Texto('ESACTIVO_CMM') <> 'N') then
    Error := Idiomas.Texto('medida.activa',
      'Indique S o N en Activa.');
end.
