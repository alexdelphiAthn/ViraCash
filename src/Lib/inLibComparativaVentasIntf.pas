{******************************************************************************}
{                                                                              }
{  Módulo: inLibComparativaVentasIntf                                          }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inLibComparativaVentasIntf;

interface

type
  TCriterioComparativaVentas = (ccvFacturadoSinImpuestos,
    ccvFacturadoConImpuestos, ccvIngresosCaja);

  TFiltroComparativaVentas = record
    Desde: TDateTime;
    Hasta: TDateTime;
    DesdeAnterior: TDateTime;
    HastaAnterior: TDateTime;
    Empresa: string;
    Almacenes: string;
    Familias: string;
    Articulos: string;
    Criterio: TCriterioComparativaVentas;
  end;

  TVentaDiariaComparativa = record
    Fecha: TDateTime;
    Venta: Currency;
    Unidades: Double;
  end;
  TVentasDiariasComparativa = TArray<TVentaDiariaComparativa>;

  TFilaComparativaVentas = record
    Fecha: TDateTime;
    FechaAnterior: TDateTime;
    TieneFecha: Boolean;
    TieneFechaAnterior: Boolean;
    Venta: Currency;
    VentaAnterior: Currency;
    Acumulado: Currency;
    AcumuladoAnterior: Currency;
    Unidades: Double;
    UnidadesAnterior: Double;
    UnidadesAcumuladas: Double;
    UnidadesAcumuladasAnterior: Double;
  end;
  TFilasComparativaVentas = TArray<TFilaComparativaVentas>;

  IRepositorioComparativaVentas = interface
    ['{45002B4C-F710-4E4E-9681-A8B291DF88A6}']
    function Consultar(const AFiltro: TFiltroComparativaVentas;
      ADesde, AHasta: TDateTime): TVentasDiariasComparativa;
  end;

implementation

end.
