{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCargaMasivaArticulosPersistenciaIntf                    }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos para la carga masiva de articulos.                        }
{******************************************************************************}
unit inLibCargaMasivaArticulosPersistenciaIntf;

interface

uses
  Data.DB;

type
  TModoCargaMasivaArticulos = (
    mcTarifa,
    mcInventario,
    mcDocumentoTrabajo,
    mcSesionTarifa
  );

  TStockCombinacionCargaMasiva = (
    scCualquiera,
    scTodos,
    scSumaPositiva
  );

  TAjusteAlcanceCargaMasiva = (
    aaSoloFinal,
    aaSoloSalida,
    aaAmbos
  );

  TFiltrosCargaMasivaArticulos = record
    SoloActivos: Boolean;
    ExcluirYaCargados: Boolean;
    SoloConStock: Boolean;
    SoloNegativos: Boolean;
    PropagarFamilias: Boolean;
    SoloProveedorPrincipal: Boolean;
    AplicarFechaAlta: Boolean;
    FiltrarVentas: Boolean;
    ConVentas: Boolean;
    FiltrarStockAlmacenVenta: Boolean;
    FechaAltaDesde: TDateTime;
    FechaAltaHasta: TDateTime;
    VentaDesde: TDateTime;
    VentaHasta: TDateTime;
    NumeroMinimoVentas: Integer;
    ReservaStockOrigen: Double;
    MaximoServirPorSku: Double;
    StockMaximoAlmacenVenta: Double;
    StockCombinacion: TStockCombinacionCargaMasiva;
    CodigosFamilia: TArray<string>;
    CodigosProveedor: TArray<string>;
    IdsValorPropiedad: TArray<Integer>;
    CodigosAlmacen: TArray<string>;
    CodigosAlmacenVenta: TArray<string>;
  end;

  TContextoCargaMasivaArticulos = record
    Modo: TModoCargaMasivaArticulos;
    CodigoTarifa: string;
    CodigoTarifaOrigen: string;
    EmpresaInventario: string;
    AlmacenInventario: string;
    SerieInventario: string;
    NumeroInventario: string;
    IdDocumentoTrabajo: Int64;
    CodigoSesionTarifa: Integer;
    TarifaOrigenSesion: string;
    TarifaDestinoSesion: string;
  end;

  TParametrosInsercionTarifa = record
    CodigoTarifa: string;
    CodigoTarifaOrigen: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    UsaFechaHasta: Boolean;
    PorcentajeDescuento: Double;
    AjustarPrecio: Boolean;
    MultiploAjuste: Double;
    RestarAjuste: Double;
    AlcanceAjuste: TAjusteAlcanceCargaMasiva;
    Usuario: string;
  end;

  TParametrosInsercionInventario = record
    SoloNegativos: Boolean;
    // FZ-ISSUE-622: solo los SKU con stock > 0 en el almacén del
    // inventario (casilla «Sólo artículos con stock»).
    SoloConStock: Boolean;
    Empresa: string;
    Almacen: string;
    Serie: string;
    Numero: string;
    Usuario: string;
  end;

  TParametrosInsercionDocumentoTrabajo = record
    IdDocumento: Int64;
    CodigosAlmacen: TArray<string>;
    ReservaStockOrigen: Double;
    MaximoServirPorSku: Double;
    Usuario: string;
  end;

  TParametrosInsercionSesionTarifa = record
    CodigoSesion: Integer;
    TarifaOrigen: string;
    TarifaDestino: string;
    Usuario: string;
  end;

  TResultadoInsercionCargaMasiva = record
    NumeroLineas: Integer;
    NumeroArticulos: Integer;
    CodigosArticulo: TArray<string>;
  end;

  TPropiedadCargaMasiva = record
    Codigo: string;
    Nombre: string;
  end;

  TAlmacenCargaMasiva = record
    Codigo: string;
    Nombre: string;
  end;

  TTarifaCargaMasiva = record
    Codigo: string;
    Nombre: string;
  end;

  TPropiedadesCargaMasiva = TArray<TPropiedadCargaMasiva>;
  TAlmacenesCargaMasiva = TArray<TAlmacenCargaMasiva>;
  TTarifasCargaMasiva = TArray<TTarifaCargaMasiva>;

  IConsultaCargaMasivaArticulos = interface
    ['{BB0FDCE1-C0B0-475F-B728-E89C463CE830}']
    function DataSet: TDataSet;
  end;

  IConsultasCargaMasivaArticulos = interface
    ['{A69A0C74-53EB-4184-BDB2-E39770E93C35}']
    function ConsultarFamilias: IConsultaCargaMasivaArticulos;
    function ConsultarProveedores: IConsultaCargaMasivaArticulos;
    function ConsultarValoresPropiedad(
      const ACodigoPropiedad: string): IConsultaCargaMasivaArticulos;
    function ListarPropiedades: TPropiedadesCargaMasiva;
    function ListarAlmacenes: TAlmacenesCargaMasiva;
    function ListarTarifas: TTarifasCargaMasiva;
    function Previsualizar(
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos
    ): IConsultaCargaMasivaArticulos;
  end;

  IInsercionesCargaMasivaArticulos = interface
    ['{54B5637D-75E8-4FFD-BF11-0ED6D0572452}']
    function InsertarTarifa(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionTarifa
    ): TResultadoInsercionCargaMasiva;
    function InsertarInventario(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionInventario
    ): TResultadoInsercionCargaMasiva;
    function InsertarDocumentoTrabajo(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionDocumentoTrabajo
    ): TResultadoInsercionCargaMasiva;
    function InsertarSesionTarifa(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionSesionTarifa
    ): TResultadoInsercionCargaMasiva;
  end;

  TServiciosCargaMasivaArticulos = record
    Consultas: IConsultasCargaMasivaArticulos;
    Inserciones: IInsercionesCargaMasivaArticulos;
  end;

implementation

end.
