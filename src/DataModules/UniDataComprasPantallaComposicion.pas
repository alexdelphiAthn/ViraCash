{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasPantallaComposicion                            }
{    Tipo:       Composición                                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Compone contextos explícitos para cada documento de compra.              }
{******************************************************************************}
unit UniDataComprasPantallaComposicion;

interface

uses
  Data.DB, Uni,
  inLibAplicacionArticuloCompraIntf,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibComprasPantallaIntf,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDevolucionesCompraStock,
  inLibDocumentosTrabajo,
  inLibPedidosCompraRecepcionIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  UniDataRepositoriosArticulosPantalla;

type
  TEntradaDocumentoCompraPantalla = record
    Conexion: TUniConnection;
    Cabecera: TDataSet;
    Lineas: TDataSet;
  end;

  TEntradaPlantillasCompraPantalla = record
    Conexion: TUniConnection;
    Maestro: TDataSource;
  end;

  TContextoAlbaranCompraPantalla = record
    AplicacionArticulo: IAplicacionArticuloCompra;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    BusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    BusquedasArticulos: IBusquedasCompraPersistencia;
    procedure Validar;
  end;

  TContextoFacturaCompraPantalla = record
    AplicacionArticulo: IAplicacionArticuloCompra;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    BusquedasArticulos: IBusquedasCompraPersistencia;
    SeleccionBanco: IRepositorioSeleccionBancoEmpresa;
    procedure Validar;
  end;

  TContextoPedidoCompraPantalla = record
    AplicacionArticulo: IAplicacionArticuloCompra;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    BusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    BusquedasArticulos: IBusquedasCompraPersistencia;
    Recepcion: IRecepcionPedidoCompra;
    Consultas: IConsultasPedidoCompraPantalla;
    procedure Validar;
  end;

  TContextoDevolucionCompraPantalla = record
    AplicacionArticulo: IAplicacionArticuloDevolucionCompra;
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    Datos: IRepositorioDatosDevolucionCompra;
    Stock: IPersistenciaStockDevolucionCompra;
    BusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    BusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    BusquedasArticulos: IBusquedasCompraPersistencia;
    procedure Validar;
  end;

  TContextoDocumentosTrabajoCompraPantalla = record
    ValidadorArticulos: IArticulosValidador;
    LookupAtributos: IArticulosAtributosLookup;
    Lecturas: ILecturasDocumentosTrabajo;
    Materializacion: IMaterializacionDocumentosTrabajo;
    CargaMasiva: TServiciosCargaMasivaArticulos;
    CargaOrigen: ICargaOrigenDocumentosTrabajo;
    procedure Validar;
  end;

  TContextoPlantillasCompraPantalla = record
    Persistencia: IPersistenciaPlantillasCompraPantalla;
    procedure Validar;
  end;

  TComponerAlbaranCompraPantalla = reference to procedure(
    const AEntrada: TEntradaDocumentoCompraPantalla;
    out AContexto: TContextoAlbaranCompraPantalla);
  TComponerFacturaCompraPantalla = reference to procedure(
    const AEntrada: TEntradaDocumentoCompraPantalla;
    out AContexto: TContextoFacturaCompraPantalla);
  TComponerPedidoCompraPantalla = reference to procedure(
    const AEntrada: TEntradaDocumentoCompraPantalla;
    out AContexto: TContextoPedidoCompraPantalla);
  TComponerDevolucionCompraPantalla = reference to procedure(
    AConexion: TUniConnection;
    out AContexto: TContextoDevolucionCompraPantalla);
  TComponerDocumentosTrabajoPantalla = reference to procedure(
    AConexion: TUniConnection;
    out AContexto: TContextoDocumentosTrabajoCompraPantalla);

function CrearCompositorAlbaranCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerAlbaranCompraPantalla;
function CrearCompositorFacturaCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ASeleccionBanco: IRepositorioSeleccionBancoEmpresa):
  TComponerFacturaCompraPantalla;
function CrearCompositorPedidoCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerPedidoCompraPantalla;
function CrearCompositorDevolucionCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerDevolucionCompraPantalla;
function CrearCompositorDocumentosTrabajoPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerDocumentosTrabajoPantalla;

procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaDocumentoCompraPantalla;
  out AContexto: TContextoAlbaranCompraPantalla); overload;
procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ASeleccionBanco: IRepositorioSeleccionBancoEmpresa;
  const AEntrada: TEntradaDocumentoCompraPantalla;
  out AContexto: TContextoFacturaCompraPantalla); overload;
procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaDocumentoCompraPantalla;
  out AContexto: TContextoPedidoCompraPantalla); overload;
procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out AContexto: TContextoDevolucionCompraPantalla); overload;
procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out AContexto: TContextoDocumentosTrabajoCompraPantalla); overload;
procedure ComponerComprasPantalla(
  const AEntrada: TEntradaPlantillasCompraPantalla;
  out AContexto: TContextoPlantillasCompraPantalla); overload;

implementation

uses
  System.SysUtils,
  inLibAplicacionArticuloCompra,
  inLibArticulosResolverIntf,
  inLibComprasPantallaArticuloDevolucion,
  inLibComprasPantallaTransaccion,
  UniDataAplicacionArticuloCompra,
  UniDataBusquedasCompraRepositorio,
  UniDataComprasPantallaPersistencia,
  UniDataDevolucionesCompraRepositorio,
  UniDataDocumentosTrabajoRepositorio,
  UniDataPedidosCompraRecepcion;

procedure ComprobarConexion(AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
end;

procedure ComprobarArticulos(
  const AArticulos: IRepositoriosArticulosPantalla);
begin
  if not Assigned(AArticulos) then
    raise EArgumentNilException.Create('AArticulos');
end;

function CrearCompositorAlbaranCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerAlbaranCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  Result :=
    procedure(
      const AEntrada: TEntradaDocumentoCompraPantalla;
      out AContexto: TContextoAlbaranCompraPantalla)
    begin
      ComponerComprasPantalla(AArticulos, AEntrada, AContexto);
    end;
end;

function CrearCompositorFacturaCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ASeleccionBanco: IRepositorioSeleccionBancoEmpresa):
  TComponerFacturaCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  if not Assigned(ASeleccionBanco) then
    raise EArgumentNilException.Create('ASeleccionBanco');
  Result :=
    procedure(
      const AEntrada: TEntradaDocumentoCompraPantalla;
      out AContexto: TContextoFacturaCompraPantalla)
    begin
      ComponerComprasPantalla(
        AArticulos, ASeleccionBanco, AEntrada, AContexto);
    end;
end;

function CrearCompositorPedidoCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerPedidoCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  Result :=
    procedure(
      const AEntrada: TEntradaDocumentoCompraPantalla;
      out AContexto: TContextoPedidoCompraPantalla)
    begin
      ComponerComprasPantalla(AArticulos, AEntrada, AContexto);
    end;
end;

function CrearCompositorDevolucionCompraPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerDevolucionCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  Result :=
    procedure(
      AConexion: TUniConnection;
      out AContexto: TContextoDevolucionCompraPantalla)
    begin
      ComponerComprasPantalla(AArticulos, AConexion, AContexto);
    end;
end;

function CrearCompositorDocumentosTrabajoPantalla(
  const AArticulos: IRepositoriosArticulosPantalla):
  TComponerDocumentosTrabajoPantalla;
begin
  ComprobarArticulos(AArticulos);
  Result :=
    procedure(
      AConexion: TUniConnection;
      out AContexto: TContextoDocumentosTrabajoCompraPantalla)
    begin
      ComponerComprasPantalla(AArticulos, AConexion, AContexto);
    end;
end;

procedure ComprobarEntradaDocumento(
  const AEntrada: TEntradaDocumentoCompraPantalla);
begin
  ComprobarConexion(AEntrada.Conexion);
  if AEntrada.Cabecera = nil then
    raise EArgumentNilException.Create('AEntrada.Cabecera');
  if AEntrada.Lineas = nil then
    raise EArgumentNilException.Create('AEntrada.Lineas');
end;

function CrearServiciosArticuloDocumento(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaDocumentoCompraPantalla):
  TServiciosDocumentoCompraPantalla;
var
  oResolver: IArticulosResolver;
begin
  Result := Default(TServiciosDocumentoCompraPantalla);
  Result.ValidadorArticulos := AArticulos.CrearValidadorArticulos(
    AEntrada.Conexion);
  oResolver := AArticulos.CrearResolverArticulos(AEntrada.Conexion);
  Result.LookupAtributos := AArticulos.CrearLookupAtributosArticulos(
    AEntrada.Conexion);
  Result.AplicacionArticulo := CrearAplicacionArticuloCompra(
    CrearRepositorioLecturasArticuloCompraUniDAC(
      AEntrada.Conexion,
      Result.ValidadorArticulos,
      oResolver),
    CrearPuertoLineaArticuloCompraUniDAC(
      AEntrada.Conexion,
      AEntrada.Cabecera,
      AEntrada.Lineas));
  Result.BusquedasArticulos := CrearBusquedasCompraPersistenciaUniDAC(
    AEntrada.Conexion);
end;

procedure AsignarBusquedas(
  AConexion: TUniConnection;
  out AEmpresas: IBusquedaEmpresasComprasPantalla;
  out AProveedores: IBusquedaProveedoresComprasPantalla);
begin
  CrearBusquedasComprasPantallaUniDAC(
    AConexion,
    AEmpresas,
    AProveedores);
end;

procedure CopiarDocumentoAlbaran(
  const AServicios: TServiciosDocumentoCompraPantalla;
  out AContexto: TContextoAlbaranCompraPantalla);
begin
  AContexto := Default(TContextoAlbaranCompraPantalla);
  AContexto.AplicacionArticulo := AServicios.AplicacionArticulo;
  AContexto.ValidadorArticulos := AServicios.ValidadorArticulos;
  AContexto.LookupAtributos := AServicios.LookupAtributos;
  AContexto.BusquedaEmpresas := AServicios.BusquedaEmpresas;
  AContexto.BusquedaProveedores := AServicios.BusquedaProveedores;
  AContexto.BusquedasArticulos := AServicios.BusquedasArticulos;
end;

procedure CopiarDocumentoFactura(
  const AServicios: TServiciosDocumentoCompraPantalla;
  out AContexto: TContextoFacturaCompraPantalla);
begin
  AContexto := Default(TContextoFacturaCompraPantalla);
  AContexto.AplicacionArticulo := AServicios.AplicacionArticulo;
  AContexto.ValidadorArticulos := AServicios.ValidadorArticulos;
  AContexto.LookupAtributos := AServicios.LookupAtributos;
  AContexto.BusquedaProveedores := AServicios.BusquedaProveedores;
  AContexto.BusquedasArticulos := AServicios.BusquedasArticulos;
end;

procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaDocumentoCompraPantalla;
  out AContexto: TContextoAlbaranCompraPantalla);
var
  oServicios: TServiciosDocumentoCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  ComprobarEntradaDocumento(AEntrada);
  oServicios := CrearServiciosArticuloDocumento(AArticulos, AEntrada);
  AsignarBusquedas(
    AEntrada.Conexion,
    oServicios.BusquedaEmpresas,
    oServicios.BusquedaProveedores);
  CopiarDocumentoAlbaran(oServicios, AContexto);
  AContexto.Validar;
end;

procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ASeleccionBanco: IRepositorioSeleccionBancoEmpresa;
  const AEntrada: TEntradaDocumentoCompraPantalla;
  out AContexto: TContextoFacturaCompraPantalla);
var
  oEmpresas: IBusquedaEmpresasComprasPantalla;
  oServicios: TServiciosDocumentoCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  if not Assigned(ASeleccionBanco) then
    raise EArgumentNilException.Create('ASeleccionBanco');
  ComprobarEntradaDocumento(AEntrada);
  oServicios := CrearServiciosArticuloDocumento(AArticulos, AEntrada);
  AsignarBusquedas(
    AEntrada.Conexion,
    oEmpresas,
    oServicios.BusquedaProveedores);
  CopiarDocumentoFactura(oServicios, AContexto);
  AContexto.SeleccionBanco := ASeleccionBanco;
  AContexto.Validar;
end;

procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const AEntrada: TEntradaDocumentoCompraPantalla;
  out AContexto: TContextoPedidoCompraPantalla);
var
  oServicios: TServiciosDocumentoCompraPantalla;
begin
  ComprobarArticulos(AArticulos);
  ComprobarEntradaDocumento(AEntrada);
  oServicios := CrearServiciosArticuloDocumento(AArticulos, AEntrada);
  AsignarBusquedas(
    AEntrada.Conexion,
    oServicios.BusquedaEmpresas,
    oServicios.BusquedaProveedores);
  AContexto := Default(TContextoPedidoCompraPantalla);
  AContexto.AplicacionArticulo := oServicios.AplicacionArticulo;
  AContexto.ValidadorArticulos := oServicios.ValidadorArticulos;
  AContexto.LookupAtributos := oServicios.LookupAtributos;
  AContexto.BusquedaEmpresas := oServicios.BusquedaEmpresas;
  AContexto.BusquedaProveedores := oServicios.BusquedaProveedores;
  AContexto.BusquedasArticulos := oServicios.BusquedasArticulos;
  AContexto.Recepcion := ProtegerRecepcionPedidoCompra(
    CrearRecepcionPedidoCompraUniDAC(AEntrada.Conexion),
    CrearUnidadTrabajoComprasPantallaUniDAC(AEntrada.Conexion));
  AContexto.Consultas := CrearConsultasPedidoCompraPantallaUniDAC(
    AEntrada.Conexion);
  AContexto.Validar;
end;

procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out AContexto: TContextoDevolucionCompraPantalla);
var
  oPersistencia: TServiciosPersistenciaDevolucionCompra;
  oResolver: IArticulosResolver;
begin
  ComprobarArticulos(AArticulos);
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoDevolucionCompraPantalla);
  AContexto.ValidadorArticulos :=
    AArticulos.CrearValidadorArticulos(AConexion);
  AContexto.LookupAtributos :=
    AArticulos.CrearLookupAtributosArticulos(AConexion);
  oResolver := AArticulos.CrearResolverArticulos(AConexion);
  oPersistencia := CrearServiciosPersistenciaDevolucionCompraUniDAC(
    AConexion);
  AContexto.Datos := oPersistencia.Datos;
  AContexto.Stock := ProtegerStockDevolucionCompra(
    oPersistencia.Stock,
    CrearUnidadTrabajoComprasPantallaUniDAC(AConexion));
  AContexto.AplicacionArticulo :=
    CrearAplicacionArticuloDevolucionCompra(
      AContexto.ValidadorArticulos,
      oResolver,
      AContexto.Datos);
  AContexto.BusquedasArticulos :=
    CrearBusquedasCompraPersistenciaUniDAC(AConexion);
  AsignarBusquedas(
    AConexion,
    AContexto.BusquedaEmpresas,
    AContexto.BusquedaProveedores);
  AContexto.Validar;
end;

procedure ComponerComprasPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out AContexto: TContextoDocumentosTrabajoCompraPantalla);
var
  oRepositorios: TRepositoriosDocumentosTrabajo;
begin
  ComprobarArticulos(AArticulos);
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoDocumentosTrabajoCompraPantalla);
  AContexto.ValidadorArticulos :=
    AArticulos.CrearValidadorArticulos(AConexion);
  AContexto.LookupAtributos :=
    AArticulos.CrearLookupAtributosArticulos(AConexion);
  oRepositorios := CrearRepositoriosDocumentosTrabajo(AConexion,
    AArticulos.CrearResolverArticulos(AConexion));
  AContexto.Lecturas := oRepositorios.Lecturas;
  AContexto.Materializacion := oRepositorios.Materializacion;
  AContexto.CargaOrigen := oRepositorios.CargaOrigen;
  AContexto.CargaMasiva :=
    AArticulos.CrearServicioCargaMasivaArticulos;
  AContexto.Validar;
end;

procedure ComponerComprasPantalla(
  const AEntrada: TEntradaPlantillasCompraPantalla;
  out AContexto: TContextoPlantillasCompraPantalla);
begin
  ComprobarConexion(AEntrada.Conexion);
  if AEntrada.Maestro = nil then
    raise EArgumentNilException.Create('AEntrada.Maestro');
  AContexto := Default(TContextoPlantillasCompraPantalla);
  AContexto.Persistencia :=
    CrearPersistenciaPlantillasCompraPantallaUniDAC(
      AEntrada.Conexion,
      AEntrada.Maestro);
  AContexto.Validar;
end;

procedure TContextoAlbaranCompraPantalla.Validar;
begin
  if not Assigned(AplicacionArticulo) then
    raise EArgumentNilException.Create('AplicacionArticulo');
  if not Assigned(ValidadorArticulos) then
    raise EArgumentNilException.Create('ValidadorArticulos');
  if not Assigned(LookupAtributos) then
    raise EArgumentNilException.Create('LookupAtributos');
  if not Assigned(BusquedaEmpresas) then
    raise EArgumentNilException.Create('BusquedaEmpresas');
  if not Assigned(BusquedaProveedores) then
    raise EArgumentNilException.Create('BusquedaProveedores');
  if not Assigned(BusquedasArticulos) then
    raise EArgumentNilException.Create('BusquedasArticulos');
end;

procedure TContextoFacturaCompraPantalla.Validar;
begin
  if not Assigned(AplicacionArticulo) then
    raise EArgumentNilException.Create('AplicacionArticulo');
  if not Assigned(ValidadorArticulos) then
    raise EArgumentNilException.Create('ValidadorArticulos');
  if not Assigned(LookupAtributos) then
    raise EArgumentNilException.Create('LookupAtributos');
  if not Assigned(BusquedaProveedores) then
    raise EArgumentNilException.Create('BusquedaProveedores');
  if not Assigned(BusquedasArticulos) then
    raise EArgumentNilException.Create('BusquedasArticulos');
  if not Assigned(SeleccionBanco) then
    raise EArgumentNilException.Create('SeleccionBanco');
end;

procedure TContextoPedidoCompraPantalla.Validar;
begin
  if not Assigned(AplicacionArticulo) then
    raise EArgumentNilException.Create('AplicacionArticulo');
  if not Assigned(ValidadorArticulos) then
    raise EArgumentNilException.Create('ValidadorArticulos');
  if not Assigned(LookupAtributos) then
    raise EArgumentNilException.Create('LookupAtributos');
  if not Assigned(BusquedaEmpresas) then
    raise EArgumentNilException.Create('BusquedaEmpresas');
  if not Assigned(BusquedaProveedores) then
    raise EArgumentNilException.Create('BusquedaProveedores');
  if not Assigned(BusquedasArticulos) then
    raise EArgumentNilException.Create('BusquedasArticulos');
  if not Assigned(Recepcion) then
    raise EArgumentNilException.Create('Recepcion');
  if not Assigned(Consultas) then
    raise EArgumentNilException.Create('Consultas');
end;

procedure TContextoDevolucionCompraPantalla.Validar;
begin
  if not Assigned(AplicacionArticulo) then
    raise EArgumentNilException.Create('AplicacionArticulo');
  if not Assigned(ValidadorArticulos) then
    raise EArgumentNilException.Create('ValidadorArticulos');
  if not Assigned(LookupAtributos) then
    raise EArgumentNilException.Create('LookupAtributos');
  if not Assigned(Datos) then
    raise EArgumentNilException.Create('Datos');
  if not Assigned(Stock) then
    raise EArgumentNilException.Create('Stock');
  if not Assigned(BusquedaEmpresas) then
    raise EArgumentNilException.Create('BusquedaEmpresas');
  if not Assigned(BusquedaProveedores) then
    raise EArgumentNilException.Create('BusquedaProveedores');
  if not Assigned(BusquedasArticulos) then
    raise EArgumentNilException.Create('BusquedasArticulos');
end;

procedure TContextoDocumentosTrabajoCompraPantalla.Validar;
begin
  if not Assigned(ValidadorArticulos) then
    raise EArgumentNilException.Create('ValidadorArticulos');
  if not Assigned(LookupAtributos) then
    raise EArgumentNilException.Create('LookupAtributos');
  if not Assigned(Lecturas) then
    raise EArgumentNilException.Create('Lecturas');
  if not Assigned(Materializacion) then
    raise EArgumentNilException.Create('Materializacion');
  if not Assigned(CargaOrigen) then
    raise EArgumentNilException.Create('CargaOrigen');
  if not Assigned(CargaMasiva.Consultas) or
     not Assigned(CargaMasiva.Inserciones) then
  begin
    raise EArgumentNilException.Create('CargaMasiva');
  end;
end;

procedure TContextoPlantillasCompraPantalla.Validar;
begin
  if not Assigned(Persistencia) then
    raise EArgumentNilException.Create('Persistencia');
end;

end.
