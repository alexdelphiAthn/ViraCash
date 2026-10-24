{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosAplicacionIntf                                }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos puros para resolver y aplicar una entrada de articulo o SKU,      }
{    importar un recuento y publicarlo en el recuento remoto.                  }
{******************************************************************************}
unit inLibInventariosAplicacionIntf;

interface

uses
  Data.DB,
  inLibTrazabilidad;

type
  TErrorEntradaInventario = (
    eeiNinguno,
    eeiArticuloNoEncontrado,
    eeiTipoArticuloSinStock,
    eeiAtributosRequierenSku,
    eeiLineasNoAbiertas,
    eeiLineaNoEditable);

  TResultadoEntradaInventario = record
    Error: TErrorEntradaInventario;
    CodigoArticulo: string;
    CodigoSku: string;
    CodigoUnidad: string;
    Descripcion: string;
    TipoArticulo: string;
    // Lote o serie que trae la lectura y queda en la línea (FZ-ISSUE-341).
    Lote: string;
  end;

  IOperacionesEntradaInventario = interface
    ['{A4D98BCD-1A17-4AE0-A72A-21EECCF45B9D}']
    function MuestraAtributos: Boolean;
    function ObtenerNumeroAtributos(
      const ACodigoArticulo: string): Integer;
    function AsegurarEdicion: TErrorEntradaInventario;
    procedure EscribirArticulo(
      const ACodigoArticulo, ADescripcion: string);
    procedure ActualizarColumnas(const ACodigoArticulo: string);
    function NumeroAtributosActual: Integer;
    procedure EscribirUnidad(const ACodigoUnidad: string);
    procedure CargarStock(const ACodigoUnidad: string);
    procedure RellenarAtributos(const ACodigoSku: string);
    // FZ-ISSUE-341: modo de trazabilidad efectivo (interruptores vigentes)
    // del artículo y escritura del lote leído con el teórico de ese lote.
    function ModoTrazabilidadEfectivo(
      const ACodigoArticulo: string): TModoTrazabilidad;
    procedure EscribirLoteLeido(
      const ACodigoUnidad, ALote: string;
      AFechaCaducidad: TDate;
      AEsSerie: Boolean);
  end;

  IAplicacionEntradaInventario = interface
    ['{022E8C10-F491-40D1-914D-62AA09DB8D58}']
    function Procesar(
      const AEntrada: string): TResultadoEntradaInventario;
  end;

  TClaveInventario = record
    Empresa: string;
    Almacen: string;
    Serie: string;
    Numero: string;
  end;

  // === IMPORTACION DE RECUENTOS (Excel / CSV / app remota) ===
  TIdentidadImportacionInventario = record
    Clave: TClaveInventario;
    TieneEmpresa: Boolean;
    TieneAlmacen: Boolean;
    TieneSerie: Boolean;
    TieneNumero: Boolean;
    TieneConflictos: Boolean;
  end;

  TEstadoIdentidadImportacionInventario = (
    eiiiCorrecta,
    eiiiIncompleta,
    eiiiContradictoria,
    eiiiInventarioDistinto);

  TLineaImportacionInventario = record
    CodigoLinea: string;
    CodigoUnidad: string;
    Cantidad: Double;
    PrecioMedioNuevo: Double;
    FechaRecuento: TDateTime;
    TienePrecioMedio: Boolean;
    TieneFechaRecuento: Boolean;
    TextoOriginal: string;
    // F-LOTEC-014: lote o serie contado y su caducidad (0 = sin ella).
    Lote: string;
    FechaCaducidad: TDateTime;
  end;

  TLineasImportacionInventario = TArray<TLineaImportacionInventario>;

  TSolicitarFechaRecuentoInventario = reference to function(
    out AFechaRecuento: TDateTime): Boolean;

  TResumenImportacionInventario = record
    Actualizadas: Integer;
    Nuevas: Integer;
  end;

  // Escrituras que la importacion necesita sobre las lineas ya cargadas.
  // La implementacion real trabaja sobre el cds del data module.
  IOperacionesImportacionInventario = interface
    ['{0C6E7A2D-3B2F-4A8B-9E45-1D1F53C0B7A2}']
    // Sin código de línea, la del SKU con el mismo lote ('' = sin lote).
    function LocalizarLinea(
      const ACodigoLinea, ACodigoUnidad, ALote: string): Boolean;
    procedure IniciarEdicionLinea;
    procedure EscribirCantidadFisica(ACantidad: Double);
    procedure EscribirPrecioMedioNuevo(APrecio: Double);
    procedure EscribirFechaRecuento(AFecha: TDateTime);
    procedure UsarPrecioMedioHistorico;
    procedure ConfirmarLinea;
    procedure ConsolidarCambios;
    procedure AnadirUnidadPendiente(const ATextoOriginal: string);
  end;

  // === RECUENTO REMOTO ===
  IRepositorioRecuentoRemotoInventario = interface
    ['{2A4B9C31-7D18-4C0E-8F6A-53B7E0D9C114}']
    procedure MarcarEnviado(
      const AClave: TClaveInventario; AIdRecuento: Int64);
    procedure MarcarRecogido(const AClave: TClaveInventario);
  end;

  // === BUSQUEDAS VISUALES ===
  // Envuelve el dataset abierto por el adaptador de persistencia para que
  // la pantalla no cree ni libere consultas.
  IResultadoConsultaInventario = interface
    ['{9B3D6E70-42A1-4F1D-B6C8-2E7A0F4D5C63}']
    function DataSet: TDataSet;
  end;

  IBusquedasInventario = interface
    ['{D5A1F082-6C39-4B7E-A0D2-8F41C6B93E57}']
    function ConsultarArticulos: IResultadoConsultaInventario;
    function ConsultarSkus(
      const ACodigoAlmacen: string): IResultadoConsultaInventario;
  end;

implementation

end.
