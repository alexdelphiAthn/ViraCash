{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuIntf                                          }
{    Tipo:       Libreria (interfaces)                                         }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: contratos (interfaces con GUID) para montar la    }
{    entrada de articulos sobre el cxGrid de CUALQUIER documento (pedido,      }
{    albaran, factura, traspaso...) en dos modos intercambiables:              }
{                                                                              }
{      - mcsSku:      articulo/color/talla en UNA columna (el SKU completo)    }
{                     con busqueda incremental por CODIGO_UNIDAD_SKU.          }
{      - mcsDesglose: columna de articulo + columnas de color y talla          }
{                     (delega en inLibGridArticulos, ya en produccion).        }
{                                                                              }
{    El documento no conoce la implementacion: recibe un IModoEntradaGrid de   }
{    la factoria (inLibColumnasSku) y trabaja contra el contrato.              }
{    Documentado en DESARROLLOS EN CURSO/ColumnSKUcxGrid/ColumnSKUcxGrid.md.   }
{******************************************************************************}
unit inLibColumnasSkuIntf;

interface

uses
  System.Classes, Data.DB, cxGraphics, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibContextoSesionIntf, inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf, inLibGenBusq,
  inLibDistribuidorTallas, inLibModoTallasIntf, inLibLogIntf;

type
  IModoEntradaGrid = interface;
  IFabricaModoEntradaDesglose = interface;
  TAnclajeSelectorAtributo = record
    IzquierdaPantalla: Integer;
    ArribaPantalla: Integer;
    Ancho: Integer;
    Valido: Boolean;
  end;
  IPresentacionAtributosSku = interface(ISelectorValorAtributo)
    ['{86869E2F-9B9F-4F90-B9D4-E3C48DF48E34}']
    function PintarCeldaArticulo(
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      const ACodigoArticulo, ATexto: string): Boolean;
  end;
  ISelectorValorAtributoAnclado = interface
    ['{B7D0DFA8-6E9B-4E79-8CB2-98A8CC653734}']
    function SeleccionarEn(
      const ANombreAtributo: string;
      const AValores: TArray<string>;
      const AAnclaje: TAnclajeSelectorAtributo;
      out AValor: string): Boolean;
  end;
  TServiciosColumnasSku = record
    Busqueda: IFabricaBusquedaTallas;
    Paleta: IPresentacionAtributosSku;
    // Variante anclada del selector de valores. No todos los
    // proveedores de paleta la ofrecen, por eso viaja aparte.
    PaletaAnclada: ISelectorValorAtributoAnclado;
    PersistenciaTallas: IFabricaPersistenciaTallas;
    ModoDesglose: IFabricaModoEntradaDesglose;
  end;
  // Modo de entrada de articulos en el grid del documento.
  TModoColumnasSku = (
    mcsAuto,        // decidir segun los campos disponibles en el cds
    mcsSku,         // articulo/color/talla en UNA columna (SKU completo)
    mcsDesglose,     // columna articulo + columnas color / talla
    mcsTallasInline, // articulo + N columnas de talla en horizontal
                     // (pivote estilo compras; requiere tabla de celdas
                     // y factoria propia: CrearModoEntradaGridTallas)
    mcsTallasHorPed  // pedidos de venta: pivot visual sobre lineas SKU
                     // reales, sin tabla de celdas
  );

  // Nombres de los campos del cds del documento. Cada documento rellena
  // los suyos (pedido: CODIGO_ART, CODIGO_UNIDAD, ...). AttrValor y
  // AttrNombre pueden quedar vacios si el documento no desglosa
  // atributos (modo SKU puro).
  TCamposColumnasSku = record
    CodigoArt: string;
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: string;
    // Almacen de la LINEA (modelo de compras: una fila horizontal por
    // articulo+color+almacen; la distribucion por almacen va por
    // lineas, no por celdas). Vacio si el documento no lo usa.
    Almacen: string;
    NumAtributos: string;
    AttrValor: array[1..5] of string;
    AttrNombre: array[1..5] of string;
  end;

  // Precio unitario que el documento aplicara al SKU (su tarifa, su
  // fecha). Lo usa el modo tallas para que la consolidacion del escaneo
  // NO fusione en una linea de precio distinto: una fila pivotada por
  // precio. Sin asignar, la consolidacion ignora el precio.
  TObtenerPrecioSkuEvent = function(const ACodigoArticulo,
                                    ACodigoSku: string): Double of object;

  // Todo lo que necesita un modo para montarse sobre el grid del documento.
  TConfigColumnasSku = record
    Servicios: TServiciosColumnasSku;
    ContextoSesion: IContextoSesionAplicacion;
    RegistroLog: IRegistroLog;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    BusquedaVisual: IBusquedaVisual;
    DistribuidorTallasVisual: IDistribuidorTallasVisual;
    View: TcxGridDBTableView;
    Cds: TDataSet;
    Campos: TCamposColumnasSku;
    Modo: TModoColumnasSku;
    // Almacen cuyo stock se muestra en el buscador (vacio = sin stock).
    AlmacenStock: string;
    // Formato distribuido (solo modo tallas, como ESFORMATO_
    // DISTRIBUIDO_SES de sesiones): las cantidades se reparten por
    // almacen con el modal distribuidor; la edicion inline de celdas
    // de talla queda bloqueada y el grid muestra la SUMA por talla.
    Distribuido: Boolean;
    // El documento admite lineas de articulos fuera del catalogo: una
    // entrada no encontrada se acepta como codigo libre en la linea
    // (sin SKU: no mueve stock) en vez de descartarse. OnResuelto llega
    // con ASku='' y ACompleto=True para que el documento complete la
    // fiscalidad. Lo activan las facturas de venta mayor.
    AceptarNoCatalogo: Boolean;
    // Al resolver una entrada con Enter, avanza con la misma navegacion
    // nativa del grid en vez de volver a abrir el editor de SKU.
    AvanzarConEnterTrasResolver: Boolean;
    // En modo desglose, presenta los atributos como combos de seleccion
    // fija con filtrado por prefijo. False conserva la paleta tradicional.
    UsarCombosAtributos: Boolean;
    // En ventas, el desplegable incremental del modo desglose devuelve una
    // fila por articulo padre. False conserva la busqueda historica de SKU.
    BuscarSoloPadresEnDesglose: Boolean;
    // Las columnas conservan su ancho y el grid se desplaza en
    // horizontal (ColumnAutoWidth = False): ensanchar una columna no
    // encoge las demas. Lo activa inventarios; False reparte el ancho
    // del grid entre las columnas, como en caja y ventas.
    DesplazamientoHorizontal: Boolean;
    // Precio del SKU segun el documento (ver TObtenerPrecioSkuEvent).
    ObtenerPrecioSku: TObtenerPrecioSkuEvent;
    // FZ-ISSUE-341: el documento guarda el lote o la serie que trae la
    // lectura (inventarios). Asignado, una lectura con lote no se acumula
    // en otra linea del mismo SKU: cada lote o serie va en su linea.
    OnLoteLeido: TArtLoteLeidoEvent;
  end;

  // Aviso al documento al resolver una entrada. ACompleto = SKU cerrado
  // (articulo sin variacion o con todos los atributos elegidos).
  TSkuResueltoEvent = procedure(const ACodArt, ASku, ADescripcion: string;
                                ACompleto: Boolean) of object;

  // Valores disponibles (colores, tallas, ...) de un articulo, para que
  // cualquier consumidor los muestre sin duplicar SQL. Implementado sobre
  // inLibArticulosAtributosIntf (desarrollo ya hecho).
  IProveedorValoresSku = interface
    ['{B4A7C9E1-3D52-4F60-8A17-59C2E6D0B833}']
    // Nombres de los atributos de variacion (Color, Talla, ...) en orden.
    function ObtenerNombresAtributos(const ACodigoArticulo: string)
                                                       : TArray<string>;
    // Valores del atributo AOrden (1..N) presentes en SKUs del articulo.
    function ObtenerValoresDisponibles(const ACodigoArticulo: string;
                                       AOrden: Integer): TArray<string>;
  end;

  // Ciclo de vida que consumen los formularios de documento. Los eventos
  // se inyectan al construir; el resto de operaciones queda encapsulado en
  // cada modo.
  IModoEntradaGrid = interface
    ['{5E92D8F4-71A6-4BC3-9D08-E4F1A27C6B50}']
    // Crea sus columnas sobre el View. El documento anade las suyas
    // (cantidad, precio, ...) DESPUES sobre el mismo View.
    procedure Construir(
      AOnResuelto: TSkuResueltoEvent;
      AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
    // Prepara el abandono del modo ANTES de reconstruir en otro. El
    // modo tallas des-pivota: expande cada celda con cantidad en una
    // linea por SKU (cantidad plana) y limpia su tabla de celdas, para
    // que SKU/Desglose muestren las mismas unidades. El resto de modos
    // no hace nada.
    procedure Desmontar;
    // Deja el editor de entrada abierto, listo para teclear o escanear.
    procedure MostrarEditor;
    // Resuelve una entrada (articulo, SKU, codigo de barras o modelo de
    // proveedor) sobre la linea actual como si se hubiera tecleado en la
    // celda: escribe la linea y avisa por OnResuelto. True si la escribio.
    // Lo usa el lector de codigo de barras a nivel de formulario.
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;
  // FZ-ISSUE-232: lectura de lector (pistola). Solo una lectura suma 1 a
  // la linea que ya tiene el mismo SKU; lo tecleado nunca fusiona lineas
  // (borraba la fila nueva y sumaba 1 a otra, tambien en metros).
  ILecturaModoEntrada = interface
    ['{6E0C5B1A-3F7D-4C2E-9A81-5D2B7F4E9C13}']
    function ResolverLectura(const AEntrada: string): Boolean;
  end;
  IFabricaModoEntradaDesglose = interface
    ['{D73BB57F-91D2-4DF2-97C3-8AE68C444995}']
    function CrearModoDesglose(
      const AConfig: TConfigColumnasSku): IModoEntradaGrid;
  end;

implementation

end.
