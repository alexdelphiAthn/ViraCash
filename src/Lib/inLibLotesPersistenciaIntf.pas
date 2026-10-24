{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLotesPersistenciaIntf                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Puerto de persistencia de lotes y seriess (F-LOTEC):           }
{    catálogo fza_articulos_lotes y procedimientos PRC_FZA_LOTES_*. El        }
{    adaptador UniData llega con F-LOTEC-010.                                  }
{******************************************************************************}
unit inLibLotesPersistenciaIntf;

interface

uses
  inLibTrazabilidad;

type
  // Fila del catálogo fza_articulos_lotes. Fechas a 0 = NULL.
  TLoteCatalogo = record
    CodigoSku: string;
    Lote: string;
    Modo: TModoTrazabilidad;
    FechaCaducidad: TDate;
    FechaEntrada: TDate;
    CodigoProveedor: string;
    TipoDocumentoOrigen: string;
    SerieDocumentoOrigen: string;
    NumeroDocumentoOrigen: string;
    EsActivo: Boolean;
    Observaciones: string;
  end;

  TResultadoAsegurarLote = (
    ralCreado,
    ralActualizado,
    // La serie ya existe en otro SKU (las series son únicas en la base).
    ralSerieEnOtroArticulo,
    // La serie ya tiene existencias: no puede volver a entrar.
    ralSerieYaEnStock
  );

  TResultadoSalidaLote = (
    rslCorrecta,
    rslLoteInexistente,
    rslSinStockSuficiente,
    rslCantidadSerie
  );

  TValidacionSalidaLote = record
    Resultado: TResultadoSalidaLote;
    // Caducado avisa, no bloquea: puede ser True con rslCorrecta.
    EsCaducado: Boolean;
    StockDisponible: Double;
    FechaCaducidad: TDate;
  end;

  // Movimiento de almacén de un lote o serie (PRC_FZA_LOTES_HISTORICO).
  TMovimientoLote = record
    NumeroMovimiento: string;
    Fecha: TDateTime;
    TipoDocumento: string;
    SerieDocumento: string;
    NumeroDocumento: string;
    Linea: Integer;
    CodigoSku: string;
    CodigoArticulo: string;
    CodigoAlmacen: string;
    CodigoAlmacenContra: string;
    TipoMovimiento: string;
    Cantidad: Double;
    FechaCaducidad: TDate;
    CodigoCliente: string;
    RazonSocialCliente: string;
    CodigoProveedor: string;
    NombreProveedor: string;
  end;

  // Dónde está una serie: catálogo y, si queda stock, el almacén.
  TUbicacionSerie = record
    Catalogo: TLoteCatalogo;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    // Vacío si la serie ya no tiene existencias (vendida, devuelta...).
    CodigoAlmacen: string;
    Stock: Double;
  end;

  // Lote o serie de un artículo con sus existencias en un almacén (una
  // fila por almacén con stock, o una sin almacén si no queda).
  TLoteArticulo = record
    CodigoSku: string;
    Lote: string;
    Modo: TModoTrazabilidad;
    FechaCaducidad: TDate;
    FechaEntrada: TDate;
    EsActivo: Boolean;
    CodigoAlmacen: string;
    Stock: Double;
  end;

  // Modo de trazabilidad de un artículo (F-LOTEC-013).
  TTrazabilidadArticulo = record
    Modo: TModoTrazabilidad;
    EsCaducidadObligatoria: Boolean;
    // DIAS_AVISO_SIN_VALOR si DIAS_AVISO_CADUCIDAD_ART es NULL.
    DiasAviso: Integer;
  end;

  ILecturaTrazabilidadArticulo = interface
    ['{E770935F-6BBA-4F7B-90E3-452CFFDAE34C}']
    // Artículo inexistente o vacío: NINGUNA.
    function Leer(const ACodigoArticulo: string): TTrazabilidadArticulo;
    // Lotes o series de las demás líneas de un documento (para no repetir
    // una serie). ATabla y los campos son identificadores fijos del
    // llamante, nunca datos del usuario.
    function LotesOtrasLineas(const ATabla, ACampoSerie, ACampoNumero,
      ACampoLinea, ACampoLote, ASerie, ANumero, ALinea: string):
      TArray<string>;
  end;

  // Pestaña «Lotes / Series» de la ficha de artículo (F-LOTEC-011).
  IConsultaLotesArticulo = interface
    ['{69A54BB8-5BF2-4302-A9B3-DC2EE7F8507D}']
    // Orden: caducidad (sin caducidad al final), lote, SKU, almacén.
    function Lotes(const ACodigoArticulo: string): TArray<TLoteArticulo>;
    function Skus(const ACodigoArticulo: string): TArray<string>;
  end;

  IRepositorioLotes = interface
    ['{C590EE4B-75D2-496B-95AB-0E2703EFF1F2}']
    // Alta o actualización del catálogo en una entrada (compra,
    // inventario, traspaso recibido).
    function Asegurar(
      const ALote: TLoteCatalogo;
      const AUsuario: string): TResultadoAsegurarLote;
    // Lotes con existencias del SKU en el almacén, sin ordenar: el orden
    // El orden FEFO lo decide SeleccionarFefo.
    function Disponibles(
      const ACodigoSku, ACodigoAlmacen: string): TLotesDisponibles;
    function ValidarSalida(
      const ACodigoSku, ACodigoAlmacen, ALote: string;
      const ACantidad: Double): TValidacionSalidaLote;
    // Orden cronológico. ACodigoSku vacío: todos los SKU con ese lote.
    function Historico(
      const ACodigoSku, ALote: string): TArray<TMovimientoLote>;
    // False si la serie no está en el catálogo. Si tiene existencias,
    // AUbicacion trae el almacén donde están.
    function BuscarSerie(
      const ASerie: string;
      out AUbicacion: TUbicacionSerie): Boolean;
  end;

implementation

end.
