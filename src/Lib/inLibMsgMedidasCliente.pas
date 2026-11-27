{******************************************************************************}
{  Módulo: inLibMsgMedidasCliente. Fecha: 02/11/2026                            }
{  Descripción: Textos traducibles de medidas de clientes.                     }
{******************************************************************************}
unit inLibMsgMedidasCliente;
interface
resourcestring
  SMedidasClaseTraje = 'Traje (medidas del cliente)';
  SMedidasEnviar = 'Enviar medidas del cliente';
  SMedidasCompletar = 'Completar medidas';
  SMedidasTitulo = 'Medidas del cliente';
  SMedidasImprimir = 'Imprimir medición';
  SMedidasPieIzquierdo = 'Ficha de pie izquierdo';
  SMedidasPieDerecho = 'Ficha de pie derecho';
  SMedidasTraje = 'Ficha de traje';
  SMedidasRopa = 'Medidas generales de ropa';
  SMedidasGuia = 'Puntos de medida';
  SMedidasPrueba = 'Ajustes para la próxima prueba';
  SMedidasGuiaPie = '1   Longitud del pie|2   Ancho de antepié|3   Contorno de empeine';
  SMedidasGuiaRopa = '1   Hombros|2   Pecho|3   Cintura|4   Manga|5   Largo';
  SMedidasGuiaCadera = '6   Cadera';
  SMedidasCliente = 'Cliente';
  SMedidasMagnitud = 'Medida';
  SMedidasValor = 'Valor';
  SMedidasUnidad = 'Unidad';
  SMedidasNueva = 'Nueva medición';
  SMedidasSeleccioneCliente = 'Seleccione un cliente guardado para ver sus medidas.';
  SMedidasSinMediciones = 'Todavía no hay mediciones para este cliente.';
  SMedidasCorregir = 'Corregir seleccionada';
  SMedidasVincular = 'Usar en esta orden';
  SMedidasCerrar = 'Cerrar';
  SMedidasFecha = 'Fecha de medición';
  SMedidasPersona = 'Persona que mide';
  SMedidasObservaciones = 'Observaciones';
  SMedidasMotivo = 'Motivo de la corrección';
  SMedidasDesconocida = 'Sin medir';
  SMedidasVacia = 'Deje en blanco las medidas desconocidas.';
  SMedidasDatosObligatorios =
    'Indique cliente, fecha, persona y las magnitudes medidas.';
  SMedidasMotivoCorreccion = 'Indique el motivo de la corrección.';
  SMedidasMagnitudInvalida = 'Magnitud inexistente, inactiva o repetida.';
  SMedidasValorNegativo = 'Las medidas no pueden ser negativas.';
  SMedidasFueraRango =
    'Estas medidas están fuera de los límites configurados:';
  SMedidasConfirmarRango = '¿Desea conservar estos valores?';
  SMedidasSinPermiso = 'No tiene permiso para esta operación de medidas.';
  SMedidasClienteInexistente = 'El cliente no existe o no se ha guardado.';
  SMedidasOrigenInvalido =
    'La medición original no pertenece al cliente o ya está corregida.';
  SMedidasOrdenInvalida =
    'La orden no pertenece al cliente o ya tiene una medición vinculada.';
  SMedidasMigracionPendiente =
    'Falta aplicar la actualización de medidas de clientes.';
  SMedidasFechaInvalida = 'La fecha de medición no es válida.';
  SMedidasValorInvalido = 'La medida debe ser numérica o quedar en blanco.';
  SMedidasSesionInexistente = 'No se ha encontrado la sesión de medidas.';
  SMedidasGuardadas = 'Medición guardada conservando el historial.';
  SMedidasVinculadas = 'Medición vinculada a la orden.';
implementation
end.
