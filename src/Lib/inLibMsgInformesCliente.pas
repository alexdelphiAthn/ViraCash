{******************************************************************************}
{                                                                              }
{  Módulo: inLibMsgInformesCliente                                             }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inLibMsgInformesCliente;

interface

resourcestring
  SInformeHojaDatos = 'Datos';
  SInformeHojaSeleccion = 'Selección';
  SInformeFechasAmbosPeriodos = 'Indique las fechas de ambos períodos.';
  SInformeFechasInvertidas = 'La fecha final precede a la inicial.';
  SInformePeriodoMaximo = 'El período no puede superar diez años.';
  SInformeFaltaEmpresa = 'Falta la empresa de la sesión.';
  SInformeSinImpuestos = 'Ventas facturadas sin impuestos';
  SInformeConImpuestos = 'Ventas facturadas con impuestos';
  SInformeIngresosCaja = 'Ingresos de operaciones de venta de caja';
  SInformeSegundoDesdeHasta = 'Segundo período: desde / hasta';
  SInformeAnioAnterior = 'Mismo período del año anterior';
  SInformeAyudaComparacion =
    'Se compara el primer día con el primer día de cada período. ' +
    'Variación = (actual - anterior) / valor absoluto anterior. ' +
    'Si el anterior es cero, el porcentaje queda vacío.';
  SInformeAyudaCaja =
    'Caja: cobros netos de operaciones VE/DV/DE, por fecha de operación; ' +
    'excluye anticipos aislados y otros movimientos de tesorería.';
  SInformeComparativa = 'Comparativa de ventas entre períodos';
  SInformeIndicarSegundo = 'Indique el segundo período.';
  SInformeTituloComparativa = 'Comparativa: ';
  SInformeSegundoPeriodo = 'Segundo período';
  SInformeEmpresa = 'Empresa';
  SInformeCriterio = 'Criterio';
  SInformeComparacion = 'Comparación';
  SInformeDiasPosicion = 'Días por posición dentro de cada período';
  SInformeVariacion = 'Variación %';
  SInformeFormulaVariacion =
    '(actual - anterior) / abs(anterior) * 100; vacío si anterior = 0';
  SInformeAlcanceCaja = 'Alcance de caja';
  SInformeCobrosNetos =
    'Cobros netos VE/DV/DE por fecha de operación; sin anticipos aislados';
  SInformeFechaActual = 'Fecha actual';
  SInformeFechaAnterior = 'Fecha anterior';
  SInformeVenta = 'Venta';
  SInformeVentaAcumulada = 'Venta acum.';
  SInformeUnidades = 'Uds.';
  SInformeUnidadesAcumuladas = 'Uds. acum.';
  SInformeVentaAnterior = 'Venta ant.';
  SInformeVentaAcumuladaAnterior = 'Venta acum. ant.';
  SInformeUnidadesAnterior = 'Uds. ant.';
  SInformeUnidadesAcumuladasAnterior = 'Uds. acum. ant.';
  SInformeVariacionVenta = 'Var. venta %';
  SInformeVariacionUnidades = 'Var. uds. %';
  SInformeTotal = 'TOTAL';
  SInformeTotalGeneral = 'TOTAL GENERAL';
  SInformeAgrupacionTotal = 'Agrupación / total';
  SInformeInicialUnidades = 'Inicial uds.';
  SInformeInicialImporte = 'Inicial importe';
  SInformePendienteRecibir = 'Pte. recibir';
  SInformeCosteSalidas = 'Coste salidas';
  SInformeResultado = 'Resultado';
  SInformeCriterioComplementos =
    'Pendientes: pedidos vigentes menos recepciones hasta la fecha final. ' +
    'Coste: movimientos de venta/albarán, netos de devoluciones. ' +
    'Resultado: ventas del balance menos coste de salidas.';
  SInformeEntradasUnidades = 'Entradas uds.';
  SInformeEntradasImporte = 'Entradas importe';
  SInformeVentasUnidades = 'Ventas uds.';
  SInformeVentasImporte = 'Ventas importe';
  SInformeFinalUnidades = 'Final uds.';
  SInformeFinalImporte = 'Final importe';
  SInformeFinalPrecio = 'Final precio medio';
  SInformeAviso = 'AVISO: ';
  SInformePaginas = 'Página [Page#] de [TotalPages#]';
  SInformeRankingProveedor = 'Preparar ranking por proveedor';
  SInformeRankingFamilia = 'Preparar ranking por familia';
  SInformeResumenColumnas = 'Resumen por agrupaciones en columnas';
  SInformeTituloResumenBalance =
    'Balance de almacén: resumen por agrupaciones';
  SInformePresentacion = 'Presentación';
  SInformeMagnitudes = 'Magnitudes';
  SInformeMagnitudesBalance =
    'Existencias iniciales, entradas, ventas y existencias finales';
  SInformeMedidas = 'Unidades';
  SInformeMedidasIncompatibles =
    'Cantidades y precio medio vacíos si se mezclan unidades de medida';

implementation

end.
