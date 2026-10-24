{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasPantallaIntf                                     }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Dependencias estrechas de las pantallas de documentos de compra.         }
{******************************************************************************}
unit inLibComprasPantallaIntf;

interface

uses
  System.SysUtils, Data.DB,
  inLibAplicacionArticuloCompraIntf,
  inLibArticulosAtributosIntf,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDevolucionesCompraStock,
  inLibDocumentosTrabajo,
  inLibPedidosCompraIntf;

type
  IConsultaComprasPantalla = interface
    ['{47B28E88-32D4-4F4D-9327-F8EE497EFC37}']
    function DataSet: TDataSet;
  end;

  IBusquedaEmpresasComprasPantalla = interface
    ['{AC88B005-70C7-4FD3-9542-CE146002782A}']
    function ConsultarEmpresas: IConsultaComprasPantalla;
  end;

  IBusquedaProveedoresComprasPantalla = interface
    ['{BF051B3A-C494-4BF1-B4A9-55B538EC8C46}']
    function ConsultarProveedores: IConsultaComprasPantalla;
  end;

  IConsultasPedidoCompraPantalla = interface
    ['{8D70BC3D-8D58-4AD5-B082-8D5BF1C4BF66}']
    function ColumnaLineasExiste(const ANombreColumna: string): Boolean;
    function AlmacenEfectivoPrimeraLinea(
      const ASerie, ANumero: string): string;
  end;

  IPersistenciaPlantillasCompraPantalla = interface
    ['{9E836334-1973-4216-8767-A446F21DB7CB}']
    function DataSetPlantillas: TDataSet;
    function DataSourcePropiedades: TDataSource;
    function DataSourceKits: TDataSource;
    function DataSourceDetalleKits: TDataSource;
    procedure Abrir;
    procedure AnadirPropiedad;
    procedure BorrarPropiedad;
    procedure AnadirKit;
    procedure BorrarKit;
  end;

  IUnidadTrabajoComprasPantalla = interface
    ['{BB139078-C85A-45CA-B21D-17AE2B6D23F8}']
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

  TEntradaArticuloDevolucionCompra = record
    CodigoIntroducido: string;
    CodigoProveedor: string;
    CodigoAlmacen: string;
    Fecha: TDateTime;
    CantidadActual: Double;
  end;

  TLineaArticuloDevolucionCompra = record
    CodigoArticulo: string;
    CodigoSku: string;
    ReferenciaProveedor: string;
    CodigoFamilia: string;
    DescripcionArticulo: string;
    TipoCantidad: string;
    TipoIva: string;
    CodigoAlmacen: string;
    IdConjuntoPivote: Integer;
    Cantidad: Double;
    TotalUnidades: Double;
    PrecioCompra: Double;
    Total: Double;
    AsignarAlmacen: Boolean;
    AsignarCantidad: Boolean;
    AsignarTotalUnidades: Boolean;
  end;

  TResultadoArticuloDevolucionCompra = record
    Aplicado: Boolean;
    RequiereSku: Boolean;
    PrepararColor: Boolean;
    Mensaje: string;
    Linea: TLineaArticuloDevolucionCompra;
  end;

  IAplicacionArticuloDevolucionCompra = interface
    ['{F33410A7-4FB6-4204-91ED-D8AA25B4BAE2}']
    function Ejecutar(
      const AEntrada: TEntradaArticuloDevolucionCompra):
      TResultadoArticuloDevolucionCompra;
  end;

  TServiciosDocumentoCompraPantalla = record
    AplicacionArticulo: IAplicacionArticuloCompra;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    BusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    BusquedasArticulos: IBusquedasCompraPersistencia;
  end;

  TServiciosPedidoCompraPantalla = record
    Documento: TServiciosDocumentoCompraPantalla;
    Recepcion: IRecepcionPedidoCompra;
    Consultas: IConsultasPedidoCompraPantalla;
  end;

  TServiciosDevolucionCompraPantalla = record
    AplicacionArticulo: IAplicacionArticuloDevolucionCompra;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    Datos: IRepositorioDatosDevolucionCompra;
    Stock: IPersistenciaStockDevolucionCompra;
    BusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    BusquedasArticulos: IBusquedasCompraPersistencia;
  end;

  TServiciosDocumentosTrabajoPantalla = record
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    Lecturas: ILecturasDocumentosTrabajo;
    Materializacion: IMaterializacionDocumentosTrabajo;
  end;

  TServiciosComprasPantalla = record
    Documento: TServiciosDocumentoCompraPantalla;
    Pedido: TServiciosPedidoCompraPantalla;
    Devolucion: TServiciosDevolucionCompraPantalla;
    DocumentosTrabajo: TServiciosDocumentosTrabajoPantalla;
    Plantillas: IPersistenciaPlantillasCompraPantalla;
  end;

implementation

end.
