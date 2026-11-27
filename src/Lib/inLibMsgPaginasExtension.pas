{ Mensajes de validación, guardado y publicación de las páginas
  de consultoría. }
unit inLibMsgPaginasExtension;

interface

resourcestring
  SDefinicionIlegible = 'Definición ilegible de «%s».';
  SProyectoGuardadoIlegible = 'El proyecto guardado es ilegible.';
  SFaltaPermisoDiseno = 'Falta el permiso de diseño.';
  SFaltaPermisoConsulta = 'Falta el permiso de consulta.';
  SSeleccioneValor = 'Seleccione un valor para %s.';
  SValorNoDisponible = 'El valor de %s ya no está disponible.';
  SIndiqueNombre = 'Indique un nombre de hasta 53 caracteres.';
  SIndiqueNombreProyecto =
    'Indique un nombre de proyecto de hasta 53 caracteres.';
  SIndiqueNombreElemento =
    'Indique un nombre de hasta 53 caracteres para el elemento %d (%s).';
  SNombresDistintos = 'Cada elemento del proyecto necesita un nombre distinto.';
  SElijaDestino = 'Elija un destino para la publicación.';
  SElijaOrigen =
    'Elija el origen en Proyecto > Datos y publicación > Lista y ficha.';
  STipoOrigenDesconocido = 'Tipo de origen desconocido.';
  SOrigenNoDisponible =
    'El origen «%s» ya no está disponible. Revíselo en Datos y publicación.';
  SSeleccioneCampoEnlace = 'Seleccione el campo de enlace.';
  SPestanaUnaEntrada =
    'La pestaña requiere una sola entrada IN vinculada al registro ' +
    'principal.';
  SMarqueCampoSeleccion =
    'Marque el campo de la lista de selección y elija un campo de enlace ' +
    'distinto.';
  SMarqueCampos = 'Marque los campos de la lista y ficha.';
  SCampoNoDisponible = 'Campo no disponible: %s.';
  SReviseListaSeleccion =
    'Revise el origen y los campos de la lista de selección.';
  SOtraSesionConsultoria = 'Otra sesión modificó esta consultoría.';
  SPaginaYaExiste = 'Ya existe una página con ese nombre.';
  SOtraSesionPagina =
    'Otra sesión modificó esta página. Vuelva a abrirla antes de publicar.';
  STermineAntesGuardar = 'Termine la operación en curso antes de guardar.';
  STermineAntesPublicar = 'Termine la operación en curso antes de publicar.';
  SProyectoCambiado = 'El proyecto ha cambiado. Vuelva a abrirlo.';
  SPublicacionCambiada =
    'La publicación ha cambiado. Vuelva a abrir el elemento.';
  SFaltanParametros = 'Faltan parámetros del procedimiento.';

implementation

end.
