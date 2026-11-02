{******************************************************************************}
{  Módulo: inLibMsgMedidasCliente. Fecha: 02/11/2026                            }
{  Descripción: Textos traducibles de medidas de clientes.                     }
{******************************************************************************}
unit inLibMsgMedidasCliente;
interface
resourcestring
  SMedidasTitulo = 'Medidas del cliente';
  SMedidasNueva = 'Nueva medición';
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
