{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesLecturasIntf                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de lectura para materializar sesiones de compra.                }
{******************************************************************************}
unit inLibComprasSesionesLecturasIntf;
interface
type
  TColorLineaMaterializacion = record
    Texto: string;
    CodigoBasico: string;
    // Valor de pestañas de la línea (la copa); '' sin pestañas.
    PestanaTexto: string;
  end;
  TValorColorMaterializacion = record
    IdValor: Integer;
    IdColorBasico: Integer;
    TieneColorBasico: Boolean;
  end;
  TSkuSesionMaterializacion = record
    IdFila: Integer;
    IdAvPivot: Integer;
    CantidadTotal: Double;
    ValorPivot: string;
    ValorFila: string;
    IdAvFila: Integer;
    // Coste neto y PVP efectivos: los de la talla o los de la línea
    // (FZ-ISSUE-638).
    Coste: Double;
    Pvp: Double;
  end;
  TSkusSesionMaterializacion = array of TSkuSesionMaterializacion;
  TLineaArticuloMaterializacion = record
    Linea: Integer;
    PrecioCosteProveedor: Double;
    AccionDuplicado: string;
    CodigoArticuloReusar: string;
    CodigoArticuloTentativo: string;
    TipoLinea: string;
    ReferenciaProveedor: string;
    PrecioVenta: Double;
    // Tipo de variación de la línea; vacío, el de la cabecera.
    CodigoVariacion: string;
  end;
  TLineasArticuloMaterializacion =
    array of TLineaArticuloMaterializacion;
  TLineaDocumentoCompraMaterializacion = record
    Trazabilidad: string;
    Lote: string;
    Caducidad: TDateTime;
    Series: string;
    CodigoArticulo: string;
    IdAvPivot: Integer;
    IdAcPivot: Integer;
    CodigoColor: string;
    ColorTexto: string;
    PestanaTexto: string;
    Almacen: string;
    Cantidad: Double;
    PrecioCompra: Double;
    PorcentajeDto: Double;
    Descripcion: string;
    CodigoFamilia: string;
    TipoIva: string;
    TipoLinea: string;
    ReferenciaProveedor: string;
  end;
  TLineasDocumentoCompraMaterializacion =
    array of TLineaDocumentoCompraMaterializacion;
  TPendienteRecibirMaterializacion = record
    Linea: Integer;
    IdAvPivot: Integer;
    Cantidad: Double;
    Almacen: string;
    CodigoArticuloTentativo: string;
    CodigoArticuloReusar: string;
    AccionDuplicado: string;
    PrecioCompra: Double;
    TipoLinea: string;
    IdAvFila: Integer;
    ColorTexto: string;
    CodigoColor: string;
    PestanaTexto: string;
  end;
  TPendientesRecibirMaterializacion =
    array of TPendienteRecibirMaterializacion;
  TDocumentoReversionMaterializacion = record
    Tipo: string;
    Serie: string;
    Numero: string;
  end;
  TDocumentosReversionMaterializacion =
    array of TDocumentoReversionMaterializacion;
  ILecturasArticulosMaterializacion = interface
    ['{823D7E9F-C5CB-4132-9B95-FCE88EDB9F94}']
    function ObtenerSiguienteSecuenciaEan(
      const APrefijo: string;
      ALongitudSecuencia: Integer): Int64;
    function ObtenerIdColorBasico(
      const ACodigoColor: string): Integer;
    // Con varios ID_AV de color con el mismo texto devuelve el que ya usa
    // el articulo (sus SKU, luego su conjunto de colores) y si no, el menor.
    function BuscarValorColor(
      const ACodigoArticulo, AValor: string): TValorColorMaterializacion;
    function ObtenerColorLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TColorLineaMaterializacion;
    function ConsultarSkusSesion(
      const ASerie, ANumero: string;
      ALinea: Integer): TSkusSesionMaterializacion;
    function ExisteEan13Sku(
      const ACodigoSku: string): Boolean;
    function ExisteProveedorPrincipalDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): Boolean;
    function ObtenerCodigoUnicoTarifa(
      const ACodigoArticulo,
      ACodigoTarifa: string): Integer;
    // AIdAvPestana: valor de pestañas (copa) de la línea; 0 si no tiene.
    // Con varios SKU de un tipo con pestañas lanza ESkuAmbiguo.
    function ResolverCodigoSku(
      const ACodigoArticulo: string;
      AIdAvPivot, AIdAvFila, AIdAvPestana: Integer): string;
    function ConsultarLineasArticulos(
      const ASerie, ANumero: string):
      TLineasArticuloMaterializacion;
  end;
  ILecturasDocumentosMaterializacion = interface
    ['{4C218CB4-28AF-4490-9619-99B879A91EED}']
    function ConsultarLineasDocumento(
      const ASerie, ANumero, AAlmacenCabecera,
      AFiltroAlmacen: string):
      TLineasDocumentoCompraMaterializacion;
  end;
  ILecturasEstadoMaterializacion = interface
    ['{B94239E4-389A-4B5D-BFA9-FC84144DE85F}']
    function ConsultarAlmacenes(
      const ASerie, ANumero,
      AAlmacenCabecera: string): TArray<string>;
  end;
  ILecturasPendientesMaterializacion = interface
    ['{31A6E4AB-9BB3-4020-9900-716551021E9C}']
    function ConsultarPendientesRecibir(
      const ASerie, ANumero,
      AAlmacenCabecera: string):
      TPendientesRecibirMaterializacion;
  end;
  ILecturasReversionMaterializacion = interface
    ['{6DD05B46-E5C9-4F89-9813-2BC8B7762A72}']
    function ExisteTabla(
      const ATabla: string): Boolean;
    function BloqueosReversionVigentes: Boolean;
    function ConsultarDocumentosSesion(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
    function ConsultarFacturasCompraAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarSalidasPosterioresAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarAlbaranesPedido(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
  end;
  TLecturasAlbaranesMaterializacion = record
    Articulos: ILecturasArticulosMaterializacion;
    Documentos: ILecturasDocumentosMaterializacion;
  end;
  TLecturasPedidosMaterializacion = record
    Articulos: ILecturasArticulosMaterializacion;
    Documentos: ILecturasDocumentosMaterializacion;
    Pendientes: ILecturasPendientesMaterializacion;
  end;
  TServiciosLecturasMaterializacion = record
    Articulos: ILecturasArticulosMaterializacion;
    Albaranes: TLecturasAlbaranesMaterializacion;
    Estado: ILecturasEstadoMaterializacion;
    Pedidos: TLecturasPedidosMaterializacion;
    Reversion: ILecturasReversionMaterializacion;
  end;
implementation
end.
