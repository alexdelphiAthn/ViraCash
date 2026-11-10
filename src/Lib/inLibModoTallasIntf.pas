{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasIntf                                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y tipos del modo de entrada de tallas en horizontal. No usa     }
{    UniDAC, VCL ni DevExpress: el dominio y sus pruebas trabajan aquí.        }
{******************************************************************************}
unit inLibModoTallasIntf;

interface

uses
  System.SysUtils, Data.DB;

type
  // Valores / nombres de los 5 atributos posibles de una linea.
  TValoresAttrTallas = array[1..5] of string;
  // Unidades acumuladas en las celdas de una linea del documento.
  TTotalLineaTallas = record
    Linea: Integer;
    Total: Double;
  end;
  TPosicionConjuntoTallas = record
    IdAv: Integer;
    Valor: string;
  end;
  // Cantidad viva en la propia linea (la que no tiene celdas).
  TCantidadLineaTallas = record
    Linea: Integer;
    Cantidad: Double;
  end;
  // Celda de talla agrupada. Almacen '' fuera del formato distribuido.
  TCeldaTallas = record
    Linea: Integer;
    Almacen: string;
    IdAv: Integer;
    ValorTalla: string;
    Cantidad: Double;
  end;
  // Linea de origen durante el des-pivote. OrdenTalla y NombreTalla los
  // rellena el caso de uso con el modelo; el puerto de lineas no conoce
  // el catalogo de atributos.
  TDatosLineaExpansion = record
    Numero: Integer;
    Encontrada: Boolean;
    Primera: Boolean;
    Articulo: string;
    Descripcion: string;
    Almacen: string;
    NombreTalla: string;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    OrdenTalla: Integer;
    Precio: Double;
    PorcentajeDto: Double;
  end;
  // Atributos calculados de una linea, SIN escribir en el dataset.
  TAtributosLineaTallas = record
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    OrdenTalla: Integer;
  end;
  // Lectura de la linea sobre la que trabaja la rederivacion.
  TLineaDocumentoTallas = record
    Numero: Integer;
    Articulo: string;
    Sku: string;
    Almacen: string;
    Cantidad: Double;
    Precio: Double;
    TieneAlmacen: Boolean;
    TienePrecio: Boolean;
    TieneCantidad: Boolean;
    PorcentajeDto: Double;
  end;
  // Escritura de la linea maestra tras rederivarla.
  TEscrituraLineaTallas = record
    Almacen: string;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    OrdenTalla: Integer;
    PonerCantidadCero: Boolean;
  end;
  // Alta o consolidacion de la linea que resuelve una entrada.
  TAltaLineaTallas = record
    Articulo: string;
    CodigoSku: string;
    Descripcion: string;
    Almacen: string;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    OrdenTalla: Integer;
    Precio: Double;
    TienePrecio: Boolean;
  end;
  // Aviso de que una linea ha quedado con estos atributos, para que la
  // presentacion rotule y muestre sus columnas.
  TAtributosEscritosTallas = procedure(
    const AValores, ANombres: TValoresAttrTallas) of object;
  // Nombres de los campos del cds que necesita el adaptador de lineas.
  TCamposLineasTallas = record
    CodigoArt: string;
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: string;
    Almacen: string;
    NumAtributos: string;
    AttrValor: TValoresAttrTallas;
    AttrNombre: TValoresAttrTallas;
    Linea: string;
    ConjuntoPivot: string;
    PrecioBase: string;
    CampoPorcentajeDto: string;
    TotalUds: string;
    TotalLinea: string;
  end;
  // Traza de sesion; el dominio no conoce el contexto de la aplicacion.
  TRegistroTallas = procedure(const ATexto: string) of object;
  // Entrada elegida en el desplegable o tecleada con Enter.
  TEntradaElegidaTallas = procedure(const AEntrada: string) of object;
  // Eleccion visual de un valor de atributo cuando hay varios posibles.
  // La implementacion vive en la capa de presentacion (paleta).
  ISelectorValorAtributo = interface
    ['{0B0D6F1E-6C4B-4E42-9B2A-3F71C0A5D914}']
    function Seleccionar(const ANombreAtributo: string;
      const AValores: TArray<string>; out AValor: string): Boolean;
  end;
  // Puertos de persistencia segregados por consumidor. El adaptador
  // UniDAC implementa todos, pero cada caso de uso solo recibe lo que usa.
  IPersistenciaModeloTallas = interface
    ['{78A7F401-A818-46D3-8777-01268F85A315}']
    function BuscarConjuntoParaAvs(
      const AIdsValores: TArray<Integer>): Integer;
    function ConjuntoCubreAvs(AIdConjunto: Integer;
      const AIdsValores: TArray<Integer>): Boolean;
  end;
  IPersistenciaRederivacionTallas = interface
    ['{10CB888B-A7BF-4097-B060-64BD9444AFF9}']
    function LineaTieneCeldas(ALinea: Integer): Boolean;
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACantidad: Double;
      const AAlmacen: string);
    procedure MoverCeldasALinea(AOrigen, ADestino: Integer);
  end;
  IPersistenciaDesmontajeTallas = interface
    ['{9D74530D-14D4-4C27-9106-AB3FE846C079}']
    function ConsultarTotalesPorLinea: TArray<TTotalLineaTallas>;
    function ConsultarCeldasDocumento: TArray<TCeldaTallas>;
    procedure BorrarCeldasDocumento;
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  IPersistenciaEntradaTallas = interface
    ['{4FC41EBE-080E-488A-9EB4-0AFDAD21C1D1}']
    function ConsultarTotalesPorLinea: TArray<TTotalLineaTallas>;
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACantidad: Double;
      const AAlmacen: string);
    function MigrarCeldasFormato(ADistribuido: Boolean;
      const AAlmacenDefecto: string): Integer;
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  IPersistenciaPresentacionTallas = interface
    ['{819C35F2-B1D2-43C0-B2A6-5BC9B46710C4}']
    function ConsultarTotalesPorLinea: TArray<TTotalLineaTallas>;
    function PrimerAlmacenEstandar: string;
  end;
  IPersistenciaGridTallasInline = interface
    ['{BD596DBD-6EC7-4907-9BA4-EEFD64F34233}']
    function ConsultarPosicionesConjunto(
      AIdConjunto: Integer;
      const AArticulo: string = ''): TArray<TPosicionConjuntoTallas>;
    function ConsultarCeldasLinea(
      ALinea: Integer): TArray<TCeldaTallas>;
    procedure FijarCantidadCelda(ALinea, AIdAv: Integer;
      ACantidad: Double; const AAlmacen: string);
  end;
  // Puertos de lineas segregados por los cuatro consumidores reales.
  ILineasRederivacionTallas = interface
    ['{F2D70385-D065-409A-B0DA-B5D604F41A86}']
    function HayLineas: Boolean;
    function ContarLineas: Integer;
    procedure PosicionarEn(APosicion: Integer);
    function LeerLineaActual: TLineaDocumentoTallas;
    procedure EscribirLineaActual(const ADatos: TEscrituraLineaTallas);
    procedure BorrarLineaActual;
    procedure IrAlPrimero;
    procedure SuspenderRefrescoVisual;
    procedure ReanudarRefrescoVisual;
  end;
  ILineasDesmontajeTallas = interface
    ['{02E7EB94-80DF-4FB5-83A0-F9B7FE2D0624}']
    function MaximaLinea: Integer;
    function LeerDatosLinea(ALinea: Integer): TDatosLineaExpansion;
    function CantidadesPorLinea: TArray<TCantidadLineaTallas>;
    procedure ActualizarLineaExpandida(const ACelda: TCeldaTallas;
      const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure CrearLineaExpandida(ANuevaLinea: Integer;
      const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
      const ASku, AAlmacen: string);
    procedure IniciarProceso;
    procedure TerminarProceso;
    procedure NotificarPostsSilenciados;
  end;
  ILineasEntradaTallas = interface
    ['{F0C556A0-F7A6-4B06-B0AD-CB6A51F1A70D}']
    function CantidadesPorLinea: TArray<TCantidadLineaTallas>;
    procedure CancelarEdicionPendiente;
    procedure ConfirmarEdicionPendiente;
    function LocalizarLineaConsolidable(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
      APrecio: Double): Boolean;
    procedure AltaLineaResuelta(const ADatos: TAltaLineaTallas);
    function NumeroLineaActual: Integer;
    function AlmacenLineaActual(const ADefecto: string): string;
    procedure IniciarProceso;
  end;
  ILineasPresentacionTallas = interface
    ['{4E497321-9EB7-47BA-A26B-1184DF5F4E92}']
    procedure ConfirmarEdicionPendiente;
    function NumeroLineaActual: Integer;
    function ConjuntoPivotActual: Integer;
    procedure IrALineaEnBlanco;
    procedure RefrescarTotales(
      const ATotales: TArray<TTotalLineaTallas>);
    procedure IrAlPrimero;
    procedure TerminarProceso;
    procedure NotificarPostsSilenciados;
  end;
  TServiciosPersistenciaModoTallas = record
    Modelo: IPersistenciaModeloTallas;
    Rederivacion: IPersistenciaRederivacionTallas;
    Desmontaje: IPersistenciaDesmontajeTallas;
    Entrada: IPersistenciaEntradaTallas;
    Presentacion: IPersistenciaPresentacionTallas;
    GridInline: IPersistenciaGridTallasInline;
  end;
  TServiciosLineasDocumentoTallas = record
    Rederivacion: ILineasRederivacionTallas;
    Desmontaje: ILineasDesmontajeTallas;
    Entrada: ILineasEntradaTallas;
    Presentacion: ILineasPresentacionTallas;
  end;
  // Desplegable de busqueda incremental de SKUs. Devuelve un TDataSet
  // porque el lookup de DevExpress necesita un origen vivo; el SQL vive
  // en el adaptador UniData*, nunca en el modo de entrada.
  IBusquedaSkusTallas = interface
    ['{2D94B71A-8E36-4F5D-B0C7-16A9E3852F40}']
    function Dataset: TDataSet;
    procedure Aplicar(const ATexto, AAlmacenStock: string);
    procedure Invalidar;
  end;
  // Coordenadas del documento y de su tabla de celdas. El adaptador
  // UniData* lee serie, numero y clave extra del master en cada
  // operacion, como hacia el modo antes de extraer el SQL.
  TConfigPersistenciaTallas = record
    Master: TDataSet;
    Usuario: string;
    CampoSerieMaster: string;
    CampoNumeroMaster: string;
    CamposDocExtraMaster: TArray<string>;
    TablaCeldas: string;
    CampoSerieCel: string;
    CampoNumeroCel: string;
    CampoLineaCel: string;
    CampoFilaCel: string;
    CampoAvPivotCel: string;
    CampoCantidadCel: string;
    CampoAlmacenCel: string;
    CamposDocExtraCel: TArray<string>;
    IdFilaFijo: Integer;
  end;
  IFabricaPersistenciaTallas = interface
    ['{B269FE09-C9BC-4E64-97A4-02C5967E1111}']
    function CrearPersistencia(
      const AConfig: TConfigPersistenciaTallas):
      TServiciosPersistenciaModoTallas;
  end;
  IFabricaBusquedaTallas = interface
    ['{6410DE3B-0FA6-40AA-B50E-13FD20C7C498}']
    function CrearBusqueda: IBusquedaSkusTallas;
  end;

implementation
end.
