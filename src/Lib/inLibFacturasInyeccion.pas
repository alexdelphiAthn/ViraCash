{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasInyeccion                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Capacidades explícitas requeridas por la pantalla de facturas.            }
{******************************************************************************}
unit inLibFacturasInyeccion;

interface

uses
  inLibArticulosAtributosIntf,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibColumnasDocumentoLecturasIntf,
  inLibColumnasSkuIntf,
  inLibEmisionFiscalIntf,
  inLibFacturasIncidenciaFiscalIntf,
  inLibFacturasLecturasIntf,
  inLibFacturasPersistenciaIntf,
  inLibFacturasPresentadorListado,
  inLibFacturasRectificativaIntf,
  inLibFacturasServiciosIntf,
  inLibFacturasSubsanacionIntf,
  inLibGenBusq,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  inLibPivoteVentaComposicionIntf;

type
  ICreadorPivoteVentaFactura = interface
    ['{8E27204A-C665-438E-BB65-3849CBA7CF91}']
    function Crear(
      const AUsuario: string;
      const ABusquedaVisual: IBusquedaVisual
    ): TRepositoriosPivoteVenta;
  end;

  TDependenciasArticulosFactura = record
    Resolver: IArticulosResolver;
    Validador: IArticulosValidador;
    Atributos: IArticulosAtributosLookup;
    procedure Validar;
    procedure Liberar;
  end;

  TDependenciasLineasFactura = record
    Lecturas: IRepositorioLecturasFactura;
    Articulos: TDependenciasArticulosFactura;
    ColumnasSku: TServiciosColumnasSku;
    AtributosGlobales: IColumnasDocumentoLecturas;
    Pivote: ICreadorPivoteVentaFactura;
    procedure Validar;
    procedure Liberar;
  end;

  TDependenciasFacturas = record
    Listado: IPreparadorListadoFacturas;
    Lineas: TDependenciasLineasFactura;
    ServiciosDataModule: TServiciosFactura;
    Persistencia: TPersistenciaFacturas;
    Consolidacion: ICasoUsoConsolidacionFactura;
    EmisionFiscal: IServicioEmisionFiscal;
    Cobros: IServicioEfectosFactura;
    Reapertura: IServicioReaperturaBorrador;
    IncidenciaFiscal: IServicioIncidenciaFiscalFactura;
    Rectificativa: IServicioRectificativaFactura;
    Subsanacion: IServicioSubsanacionFactura;
    SeleccionBanco: IRepositorioSeleccionBancoEmpresa;
    procedure Validar;
    procedure Liberar;
  end;

  TContextoDependenciasFacturas = TDependenciasFacturas;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorListadoFacturasNoDisponible =
    'No se proporcionó la capacidad de listado de facturas.';
  SErrorLecturasFacturasNoDisponibles =
    'No se proporcionaron las lecturas de líneas de facturas.';
  SErrorResolverArticulosFacturaNoDisponible =
    'No se proporcionó la resolución de artículos de facturas.';
  SErrorValidadorArticulosFacturaNoDisponible =
    'No se proporcionó la validación de artículos de facturas.';
  SErrorAtributosArticulosFacturaNoDisponibles =
    'No se proporcionaron los atributos de artículos de facturas.';
  SErrorColumnasSkuFacturaNoDisponibles =
    'No se proporcionaron los servicios de columnas SKU de facturas.';
  SErrorAtributosGlobalesFacturaNoDisponibles =
    'No se proporcionaron los atributos globales de facturas.';
  SErrorPivoteFacturaNoDisponible =
    'No se proporcionó la capacidad de pivote de facturas.';
  SErrorServiciosFacturaNoDisponibles =
    'No se proporcionaron los servicios del módulo de facturas.';
  SErrorPersistenciaFacturaNoDisponible =
    'No se proporcionó la persistencia de facturas.';
  SErrorConsolidacionFacturaNoDisponible =
    'No se proporcionó la consolidación de facturas.';
  SErrorEmisionFiscalFacturaNoDisponible =
    'No se proporcionó la emisión fiscal de facturas.';
  SErrorCobrosFacturaNoDisponibles =
    'No se proporcionó la capacidad de cobros de facturas.';
  SErrorReaperturaFacturaNoDisponible =
    'No se proporcionó la reapertura de facturas.';
  SErrorIncidenciaFiscalFacturaNoDisponible =
    'No se proporcionó la resolución de incidencias fiscales.';
  SErrorRectificativaFacturaNoDisponible =
    'No se proporcionó el servicio de rectificativas de facturas.';
  SErrorSubsanacionFacturaNoDisponible =
    'No se proporcionó el servicio de subsanación de facturas.';
  SErrorSeleccionBancoFacturaNoDisponible =
    'No se proporcionó la selección de banco de facturas.';

procedure TDependenciasArticulosFactura.Validar;
begin
  if not Assigned(Resolver) then
    raise EArgumentNilException.Create(
      SErrorResolverArticulosFacturaNoDisponible);
  if not Assigned(Validador) then
    raise EArgumentNilException.Create(
      SErrorValidadorArticulosFacturaNoDisponible);
  if not Assigned(Atributos) then
    raise EArgumentNilException.Create(
      SErrorAtributosArticulosFacturaNoDisponibles);
end;

procedure TDependenciasArticulosFactura.Liberar;
begin
  Resolver := nil;
  Validador := nil;
  Atributos := nil;
end;

procedure TDependenciasLineasFactura.Validar;
begin
  if not Assigned(Lecturas) then
    raise EArgumentNilException.Create(
      SErrorLecturasFacturasNoDisponibles);
  Articulos.Validar;
  if not Assigned(ColumnasSku.Busqueda) or
     not Assigned(ColumnasSku.Paleta) or
     not Assigned(ColumnasSku.PersistenciaTallas) or
     not Assigned(ColumnasSku.ModoDesglose) then
  begin
    raise EArgumentNilException.Create(
      SErrorColumnasSkuFacturaNoDisponibles);
  end;
  if not Assigned(AtributosGlobales) then
    raise EArgumentNilException.Create(
      SErrorAtributosGlobalesFacturaNoDisponibles);
  if not Assigned(Pivote) then
    raise EArgumentNilException.Create(
      SErrorPivoteFacturaNoDisponible);
end;

procedure TDependenciasLineasFactura.Liberar;
begin
  Lecturas := nil;
  Articulos.Liberar;
  ColumnasSku.Busqueda := nil;
  ColumnasSku.Paleta := nil;
  ColumnasSku.PaletaAnclada := nil;
  ColumnasSku.PersistenciaTallas := nil;
  ColumnasSku.ModoDesglose := nil;
  AtributosGlobales := nil;
  Pivote := nil;
end;

procedure TDependenciasFacturas.Validar;
begin
  if not Assigned(Listado) then
    raise EArgumentNilException.Create(
      SErrorListadoFacturasNoDisponible);
  Lineas.Validar;
  if not Assigned(ServiciosDataModule.Repositorio) or
     not Assigned(ServiciosDataModule.ArticulosResolver) or
     not Assigned(ServiciosDataModule.ValidadorFiscal) or
     not Assigned(ServiciosDataModule.Calculador) or
     not Assigned(ServiciosDataModule.Borrado) or
     not Assigned(ServiciosDataModule.Efectos) then
  begin
    raise EArgumentNilException.Create(
      SErrorServiciosFacturaNoDisponibles);
  end;
  if not Assigned(Persistencia.UnidadTrabajo) or
     not Assigned(Persistencia.Borrado) or
     not Assigned(Persistencia.Reapertura) or
     not Assigned(Persistencia.Consolidacion) or
     not Assigned(Persistencia.Efectos) or
     not Assigned(Persistencia.Movimientos) or
     not Assigned(Persistencia.Pdf) then
  begin
    raise EArgumentNilException.Create(
      SErrorPersistenciaFacturaNoDisponible);
  end;
  if not Assigned(Consolidacion) then
    raise EArgumentNilException.Create(
      SErrorConsolidacionFacturaNoDisponible);
  if not Assigned(EmisionFiscal) then
    raise EArgumentNilException.Create(
      SErrorEmisionFiscalFacturaNoDisponible);
  if not Assigned(Cobros) then
    raise EArgumentNilException.Create(
      SErrorCobrosFacturaNoDisponibles);
  if not Assigned(Reapertura) then
    raise EArgumentNilException.Create(
      SErrorReaperturaFacturaNoDisponible);
  if not Assigned(IncidenciaFiscal) then
    raise EArgumentNilException.Create(
      SErrorIncidenciaFiscalFacturaNoDisponible);
  if not Assigned(Rectificativa) then
    raise EArgumentNilException.Create(
      SErrorRectificativaFacturaNoDisponible);
  if not Assigned(Subsanacion) then
    raise EArgumentNilException.Create(
      SErrorSubsanacionFacturaNoDisponible);
  if not Assigned(SeleccionBanco) then
    raise EArgumentNilException.Create(
      SErrorSeleccionBancoFacturaNoDisponible);
end;

procedure TDependenciasFacturas.Liberar;
begin
  Listado := nil;
  Lineas.Liberar;
  ServiciosDataModule.Repositorio := nil;
  ServiciosDataModule.ArticulosResolver := nil;
  ServiciosDataModule.ValidadorFiscal := nil;
  ServiciosDataModule.Calculador := nil;
  ServiciosDataModule.Borrado := nil;
  ServiciosDataModule.Efectos := nil;
  Persistencia.UnidadTrabajo := nil;
  Persistencia.Borrado := nil;
  Persistencia.Reapertura := nil;
  Persistencia.Consolidacion := nil;
  Persistencia.Efectos := nil;
  Persistencia.Movimientos := nil;
  Persistencia.Pdf := nil;
  Consolidacion := nil;
  EmisionFiscal := nil;
  Cobros := nil;
  Reapertura := nil;
  IncidenciaFiscal := nil;
  Rectificativa := nil;
  Subsanacion := nil;
  SeleccionBanco := nil;
end;

end.
