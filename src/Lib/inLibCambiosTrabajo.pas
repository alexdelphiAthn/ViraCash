{ Cambios explícitos de ejecutor y repeticiones. TRJ-004, 02/11/2026. }
unit inLibCambiosTrabajo;

interface

type
  TCambioTrabajo = record
    Id, Revision, Motivo, TipoEjecutor, Ejecutor: string;
    ResponsableCoste: string;
    Orden, Linea: Int64;
    Repetir, Aceptado: Boolean;
    Cantidad: Currency;
    CosteAdicional: Currency;
  end;

procedure ValidarCambioTrabajo(const ACambio: TCambioTrabajo);

resourcestring
  SCambioTrabajoTitulo = 'Reasignar o repetir trabajo';
  SCambioTrabajoAsignar = 'Asignar ejecutor al trabajo';
  SCambioTrabajoCantidadActual = 'Cantidad del trabajo';
  SCambioTrabajoCosteActual = 'Coste adicional TOTAL del trabajo';
  SCambioTrabajoConservarCantidad =
    'Al asignar el ejecutor, conserve la cantidad del trabajo.';
  SCambioTrabajoConfirmarAsignacion =
    'Se asignará el ejecutor en el mismo trabajo, sin duplicarlo. ' +
    'Coste adicional: %s. Coste total resultante: %s. ' +
    'El importe del cliente se mantiene. ¿Confirma el cambio?';
  SCambioTrabajoReasignar = 'Reasignar';
  SCambioTrabajoRepetir = 'Repetir';
  SCambioTrabajoMotivo = 'Motivo del cambio';
  SCambioTrabajoTipo = 'Tipo de ejecutor';
  SCambioTrabajoCodigo = 'Nuevo ejecutor';
  SCambioTrabajoCantidad = 'Cantidad del nuevo tramo';
  SCambioTrabajoCoste = 'Coste adicional TOTAL del nuevo tramo';
  SCambioTrabajoResponsable = 'Responsable del cambio / coste adicional';
  SCambioTrabajoFaltaMotivo = 'Indique el motivo del cambio.';
  SCambioTrabajoFaltaTipo = 'Seleccione Operario o Empresa externa.';
  SCambioTrabajoFaltaEjecutor = 'Seleccione el nuevo ejecutor con «…».';
  SCambioTrabajoFaltaResponsable = 'Seleccione el responsable del cambio.';
  SCambioTrabajoCantidadInvalida =
    'La cantidad debe ser mayor que cero y no superar 1.000.000.';
  SCambioTrabajoCosteInvalido =
    'El coste adicional debe estar entre cero y 1.000.000.';
  SCambioTrabajoConfirmar =
    'Se conservarán el trabajo, tiempos y costes anteriores. El nuevo ' +
    'tramo no se cobrará de nuevo al cliente. ¿Acepta el coste adicional ' +
    'indicado y el cambio de ejecutor?';
  SCambioTrabajoInvalido =
    'Indique motivo, ejecutor válido y responsable; confirme el cambio.';
  SCambioTrabajoSinPermiso = 'No tiene permiso para cambiar este trabajo.';
  SCambioTrabajoConflicto =
    'El trabajo ha cambiado. Actualice la lista y revise la operación.';
  SCambioTrabajoEjecutor = 'El ejecutor no existe o está inactivo.';
  SCambioTrabajoEstado =
    'Repetir exige un trabajo terminado; reasignar exige uno pendiente.';
  SCambioTrabajoCostePrevio =
    'Para asignar el ejecutor en la misma línea, conserve la cantidad ' +
    'y deje el coste adicional en cero.';
  SCambioTrabajoPendiente =
    'Hay tiempo abierto o prendas pendientes del externo. Ciérrelos antes.';
  SCambioTrabajoGrabado = 'Cambio guardado. Trabajo resultante: %d.';

implementation

uses
  System.SysUtils;

procedure ValidarCambioTrabajo(const ACambio: TCambioTrabajo);
begin
  if (Length(ACambio.Id) <> 36) or (Length(ACambio.Revision) <> 32) or
     (ACambio.Orden <= 0) or (ACambio.Linea <= 0) or
     (Trim(ACambio.Motivo) = '') or (Length(ACambio.Motivo) > 500) or
     (Trim(ACambio.Ejecutor) = '') or (Length(ACambio.Ejecutor) > 20) or
     ((ACambio.TipoEjecutor <> 'OPERARIO') and
      (ACambio.TipoEjecutor <> 'EXTERNO')) or
     (Trim(ACambio.ResponsableCoste) = '') or
     (Length(ACambio.ResponsableCoste) > 100) or not ACambio.Aceptado or
     (ACambio.Cantidad <= 0) or (ACambio.Cantidad > 1000000) or
     (ACambio.CosteAdicional < 0) or (ACambio.CosteAdicional > 1000000) then
    raise EArgumentException.Create(SCambioTrabajoInvalido);
end;

end.
