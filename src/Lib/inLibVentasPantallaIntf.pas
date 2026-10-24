{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVentasPantallaIntf                                       }
{    Tipo:       Contratos                                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Contextos minimos y contratos de presentacion para ventas y documentos.  }
{    Cada pantalla conserva solo el contexto que consume.                      }
{******************************************************************************}
unit inLibVentasPantallaIntf;

interface

uses
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibColumnasSkuIntf,
  inLibEntradaAlbaranVentaPersistenciaIntf,
  inLibClientesPersistenciaIntf,
  inLibDestinoEnvioPersistenciaIntf,
  inLibFacturacionAlbaranesFechasPersistenciaIntf,
  inLibFacturacionAlbaranesCompraPersistenciaIntf,
  inLibFacturacionTicketPersistenciaIntf,
  inLibSerieFechaFacturaPersistenciaIntf,
  inLibSeleccionFamiliaPersistenciaIntf,
  inLibSeleccionAlmacenPersistenciaIntf,
  inLibListadoVentasPersistenciaIntf,
  inLibDocumentosTrabajo,
  inLibImpresionPersistenciaIntf,
  inLibVentasPantallaCrearAlbaran;

type
  TAlmacenFiltroFacturaSimplificada = record
    Codigo: string;
    Nombre: string;
  end;

  TAlmacenesFiltroFacturaSimplificada =
    TArray<TAlmacenFiltroFacturaSimplificada>;

  TFiltrosFacturasSimplificadas = record
    Anyos: TArray<Integer>;
    Almacenes: TArray<string>;
  end;

  IRepositorioFacturasSimplificadasPantalla = interface
    ['{9D5C2D97-B77F-4D1A-9F3B-4C63B2D621E8}']
    function ListarAnyos: TArray<Integer>;
    function ListarAlmacenes: TAlmacenesFiltroFacturaSimplificada;
    function ConfigurarListado(
      const AFiltros: TFiltrosFacturasSimplificadas): Boolean;
    function Contar(
      const AFiltros: TFiltrosFacturasSimplificadas): Integer;
  end;

  TContextoAlbaranesVentasPantalla = record
    ResolverArticulos: IArticulosResolver;
    ValidadorArticulos: IArticulosValidador;
    AtributosArticulos: IArticulosAtributosLookup;
    ColumnasSku: TServiciosColumnasSku;
    EntradaArticulos: IRepositorioEntradaAlbaranVenta;
  end;

  TContextoPedidosVentasPantalla = record
    ResolverArticulos: IArticulosResolver;
    ValidadorArticulos: IArticulosValidador;
    AtributosArticulos: IArticulosAtributosLookup;
    ColumnasSku: TServiciosColumnasSku;
    EntradaArticulos: IRepositorioEntradaAlbaranVenta;
    CrearAlbaran: ICasoUsoCrearAlbaranPedido;
  end;

  TContextoClientesVentasPantalla = record
    Repositorio: IRepositorioClientes;
  end;

  TContextoFacturasSimplificadasVentasPantalla = record
    Repositorio: IRepositorioFacturasSimplificadasPantalla;
  end;

  TContextoDestinoEnvioVentasPantalla = record
    Repositorio: IRepositorioDestinoEnvio;
  end;

  TContextoFacturacionAlbaranesFechasVentasPantalla = record
    Repositorio: IRepositorioFacturacionAlbaranesFechas;
  end;

  TContextoFacturacionAlbaranesCompraVentasPantalla = record
    Repositorio: IRepositorioFacturacionAlbaranesCompra;
  end;

  TContextoFacturacionTicketVentasPantalla = record
    Series: IRepositorioSerieFechaFactura;
    Facturacion: IServicioFacturacionTicket;
  end;

  TContextoSerieFechaFacturaVentasPantalla = record
    Repositorio: IRepositorioSerieFechaFactura;
  end;

  TContextoSeleccionFamiliaVentasPantalla = record
    Repositorio: IRepositorioSeleccionFamilia;
  end;

  TContextoSeleccionAlmacenVentasPantalla = record
    Repositorio: IRepositorioSeleccionAlmacen;
  end;

  TContextoListadoVentasPantalla = record
    Listado: IRepositorioListadoVentas;
    DocumentosTrabajo: TRepositoriosDocumentosTrabajo;
    ResolverArticulos: IArticulosResolver;
  end;

  TContextoImpresionVentasPantalla = record
    Persistencia: TServiciosPersistenciaImpresion;
  end;

implementation

end.
