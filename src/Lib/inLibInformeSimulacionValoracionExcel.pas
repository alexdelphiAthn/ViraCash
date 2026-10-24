{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInformeSimulacionValoracionExcel                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Vuelca el listado de una simulación de valoración en una hoja de cálculo }
{    a través del puerto IEscritorHojaCalculo (sin dependencia de DevExpress). }
{******************************************************************************}
unit inLibInformeSimulacionValoracionExcel;

interface

uses
  inLibHojaCalculoIntf,
  inLibInformeSimulacionValoracion;

procedure ExportarInformeSimulacionValoracionExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const ADatos: TDatosInformeSimulacionValoracion);

implementation

uses
  System.SysUtils;

const
  COL_LINEA = 0;
  COL_ARTICULO = 1;
  COL_SKU = 2;
  COL_DESCRIPCION = 3;
  COL_UNIDADES = 4;
  COL_ULTIMA_COMPRA = 5;
  COL_PRECIO_MEDIO = 6;
  COL_PRECIO_SIMULADO = 7;
  COL_SIMULADA = 8;
  ANCHOS_COLUMNAS: array[COL_LINEA..COL_SIMULADA] of Integer = (
    60, 110, 150, 300, 80, 110, 110, 110, 70);
  FILA_TITULO = 0;
  FILA_IDENTIFICACION = 1;
  FILA_OPERACION = 2;
  FILA_FECHA = 3;
  FILA_CABECERA = 5;
  FILA_PRIMERA_LINEA = 6;
  FORMATO_UNIDADES = '#,##0.####';
  FORMATO_PRECIO = '#,##0.0000';
  FORMATO_IMPORTE = '#,##0.00 €';
  FORMATO_ENTERO = '0';
  COLOR_CABECERA = $00EEEEEE;

procedure ExportarInformeSimulacionValoracionExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const ADatos: TDatosInformeSimulacionValoracion);
var
  iFila: Integer;
  iLinea: Integer;

  procedure EscribirCabecera(
    AColumna: Integer;
    const ATexto: string;
    AAlineacion: TAlineacionCelda);
  begin
    AEscritor.Escribir(FILA_CABECERA, AColumna, ATexto);
    AFormateador.Negrita(FILA_CABECERA, AColumna);
    AFormateador.FondoCelda(FILA_CABECERA, AColumna, COLOR_CABECERA);
    AFormateador.Alinear(FILA_CABECERA, AColumna, AAlineacion);
    AFormateador.AnchoColumna(AColumna, ANCHOS_COLUMNAS[AColumna]);
  end;

  procedure EscribirNumero(
    AFila, AColumna: Integer;
    const AValor: Currency;
    const AFormato: string);
  begin
    AEscritor.Escribir(AFila, AColumna, AValor);
    AFormateador.AplicarFormato(AFila, AColumna, AFormato);
    AFormateador.Alinear(AFila, AColumna, acDerecha);
  end;

  procedure EscribirResumen(
    AFila: Integer;
    const AEtiqueta: string;
    const AValor: Currency;
    const AFormato: string);
  begin
    AEscritor.Escribir(AFila, COL_PRECIO_MEDIO, AEtiqueta);
    AFormateador.Negrita(AFila, COL_PRECIO_MEDIO);
    AFormateador.Alinear(AFila, COL_PRECIO_MEDIO, acDerecha);
    EscribirNumero(AFila, COL_PRECIO_SIMULADO, AValor, AFormato);
    AFormateador.Negrita(AFila, COL_PRECIO_SIMULADO);
  end;

begin
  AEscritor.NuevaHoja(SNombreHojaInformeValoracion);
  AEscritor.IniciarLote;
  try
    AEscritor.Escribir(FILA_TITULO, COL_LINEA, ADatos.Titulo);
    AFormateador.Negrita(FILA_TITULO, COL_LINEA);
    AFormateador.TamanoFuente(FILA_TITULO, COL_LINEA, 14);
    AEscritor.Escribir(FILA_IDENTIFICACION, COL_LINEA,
      ADatos.Identificacion);
    AEscritor.Escribir(FILA_OPERACION, COL_LINEA, ADatos.Operacion);
    AEscritor.Escribir(FILA_FECHA, COL_LINEA,
      SCaptionFechaInformeValoracion + ' ' +
      FormatDateTime('dd/mm/yyyy hh:nn', ADatos.Fecha));

    EscribirCabecera(COL_LINEA,
      SCaptionColLineaInformeValoracion, acIzquierda);
    EscribirCabecera(COL_ARTICULO,
      SCaptionColArticuloInformeValoracion, acIzquierda);
    EscribirCabecera(COL_SKU,
      SCaptionColSkuInformeValoracion, acIzquierda);
    EscribirCabecera(COL_DESCRIPCION,
      SCaptionColDescripcionInformeValoracion, acIzquierda);
    EscribirCabecera(COL_UNIDADES,
      SCaptionColUnidadesInformeValoracion, acDerecha);
    EscribirCabecera(COL_ULTIMA_COMPRA,
      SCaptionColUltimaCompraInformeValoracion, acDerecha);
    EscribirCabecera(COL_PRECIO_MEDIO,
      ADatos.CaptionPrecioMedio, acDerecha);
    EscribirCabecera(COL_PRECIO_SIMULADO,
      SCaptionColPrecioSimuladoInformeValoracion, acDerecha);
    EscribirCabecera(COL_SIMULADA,
      SCaptionColSimuladaInformeValoracion, acCentro);

    iFila := FILA_PRIMERA_LINEA;
    for iLinea := 0 to High(ADatos.Lineas) do
    begin
      AEscritor.Escribir(iFila, COL_LINEA, ADatos.Lineas[iLinea].Linea);
      AEscritor.Escribir(iFila, COL_ARTICULO,
        ADatos.Lineas[iLinea].CodigoArticulo);
      AEscritor.Escribir(iFila, COL_SKU,
        ADatos.Lineas[iLinea].CodigoUnidad);
      AEscritor.Escribir(iFila, COL_DESCRIPCION,
        ADatos.Lineas[iLinea].Descripcion);
      EscribirNumero(iFila, COL_UNIDADES,
        ADatos.Lineas[iLinea].Unidades, FORMATO_UNIDADES);
      EscribirNumero(iFila, COL_ULTIMA_COMPRA,
        ADatos.Lineas[iLinea].PrecioUltimaCompra, FORMATO_PRECIO);
      EscribirNumero(iFila, COL_PRECIO_MEDIO,
        ADatos.Lineas[iLinea].PrecioMedio, FORMATO_PRECIO);
      if ADatos.Lineas[iLinea].Simulada then
      begin
        EscribirNumero(iFila, COL_PRECIO_SIMULADO,
          ADatos.Lineas[iLinea].PrecioSimulado, FORMATO_PRECIO);
        AEscritor.Escribir(iFila, COL_SIMULADA, STextoSiInformeValoracion);
        AFormateador.Alinear(iFila, COL_SIMULADA, acCentro);
      end;
      Inc(iFila);
    end;

    Inc(iFila);
    EscribirResumen(iFila, SCaptionLineasSimuladasInformeValoracion,
      ADatos.NumeroLineasSimuladas, FORMATO_ENTERO);
    Inc(iFila);
    EscribirResumen(iFila, SCaptionValorAnteriorInformeValoracion,
      ADatos.ValorAnterior, FORMATO_IMPORTE);
    Inc(iFila);
    EscribirResumen(iFila, SCaptionValorSimuladoInformeValoracion,
      ADatos.ValorSimulado, FORMATO_IMPORTE);
    Inc(iFila);
    EscribirResumen(iFila, SCaptionDiferenciaInformeValoracion,
      ADatos.DiferenciaValor, FORMATO_IMPORTE);
  finally
    AEscritor.FinalizarLote;
  end;
end;

end.
