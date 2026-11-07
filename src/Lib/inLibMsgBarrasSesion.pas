{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgBarrasSesion                                          }
{  Versión:      1.0.0                                                         }
{  Fecha:        06/11/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Códigos de barras de fabricante en sesiones de compra.        }
{******************************************************************************}
unit inLibMsgBarrasSesion;

interface

resourcestring
  SBarrasTitulo = '&8. Códigos de barras';
  SBarrasImportar = 'Importar CSV';
  SBarrasAutomatico = 'Crear automáticamente';
  SBarrasActualizar = 'Actualizar';
  SBarrasCodigo = 'Código de barras';
  SBarrasArticulo = 'Artículo';
  SBarrasModeloProveedor = 'Modelo del proveedor';
  SBarrasCodigoInterno = 'Código interno';
  SBarrasIdentificarPor = 'Identificar artículos por';
  SBarrasColumnaArticulo = 'Columna del modelo / artículo';
  SBarrasIdentificadorVacio = 'Falta el modelo o código de artículo.';
  SBarrasColor = 'Color / variante';
  SBarrasTalla = 'Talla';
  SBarrasSinColor = '(sin color)';
  SBarrasSinTalla = '(sin talla)';
  SBarrasColumna = 'Columna del código de barras';
  SBarrasCabecera = 'Primera fila contiene títulos';
  SBarrasAsignar = 'Asignar a la fila seleccionada';
  SBarrasQuitar = 'Quitar asignación';
  SBarrasAyuda = 'Indique las columnas del fichero. Al aceptar se importan ' +
    'todas las filas por modelo o código interno, color y talla.';
  SBarrasCodigoLargo = 'El código de barras admite como máximo 50 caracteres.';
  SBarrasCodigoControl = 'El código contiene caracteres de control.';
  SBarrasCsvComillas = 'El CSV contiene comillas sin cerrar o mal colocadas.';
  SBarrasCsvVacio = 'El fichero no contiene filas para importar.';
  SBarrasDuplicado = 'El código %s ya está asignado a otra combinación.';
  SBarrasOcupada = 'La combinación ya tiene otro código. ' +
    'Puede cambiarlo manualmente en la pestaña Códigos de barras.';
  SBarrasSeleccion = 'Seleccione artículo, color y talla de la sesión.';
  SBarrasSinAsignar = 'No hay filas asignadas para importar.';
  SBarrasVacio = 'La fila seleccionada no contiene un código de barras.';
  SBarrasAmbigua = 'Hay varias líneas con esta combinación. ' +
    'Asígnela desde la pestaña Códigos de barras.';
  SBarrasCerrada = 'La sesión está cerrada o ya no existe.';
  SBarrasCambios = 'Las combinaciones de la sesión han cambiado. Actualice ' +
    'la pestaña y vuelva a asignar los códigos.';
  SBarrasConflicto = 'El código %s pertenece al SKU %s.';
  SBarrasPrefijo = 'El prefijo EAN debe tener de 1 a 11 dígitos.';
  SBarrasBloqueo = 'No se pudo reservar la secuencia de códigos de barras.';
  SBarrasGenerados = 'Se han completado %d códigos vacíos.';
  SBarrasColumnaNumero = 'Columna %d';
  SBarrasSeparador = 'Separador CSV';
  SBarrasLinea = 'Línea';
  SBarrasDescripcion = 'Descripción';
  SBarrasFiltroCsv = 'CSV (*.csv;*.txt)|*.csv;*.txt';
  SBarrasSinColumna = '(sin columna)';
  SBarrasColorFijo = 'Color / variante si falta la columna';
  SBarrasColorAutomatico = 'Automático (si es único)';
  SBarrasColumnasObligatorias =
    'Seleccione las columnas del código de barras y del modelo / artículo.';
  SBarrasColumnasRepetidas = 'Seleccione columnas diferentes para cada dato.';
  SBarrasFilaIncompleta = 'Faltan columnas en esta fila del CSV.';
  SBarrasSinCoincidencia =
    'No existe en la sesión: modelo / artículo %s, color %s, talla %s.';
  SBarrasErrorFila = 'Fila %d: %s';
  SBarrasAmbiguaCsv = 'Hay varias combinaciones posibles. ' +
    'Indique el color fijo o las columnas de color / variante y talla.';
  SBarrasMigracion = 'Para usar los códigos de barras de sesiones, ' +
    'actualice la base de datos con la migración ' +
    '20261106_sesiones_codigos_barras.sql.';

implementation

end.
