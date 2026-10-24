{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasInyeccion                                     }
{    Tipo:       Composición UniDAC                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construye las capacidades UniDAC inyectadas en la pantalla de facturas.   }
{******************************************************************************}
unit UniDataFacturasInyeccion;

interface

uses
  Uni,
  inLibCatalogoSqlIntf,
  inLibFacturasInyeccion,
  inLibLogIntf,
  inLibParametrosIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf;

type
  TContextoFacturasUniDAC = record
    Conexion: TUniConnection;
    ParametrosApp: IParametrosAplicacion;
    ParametrosCaja: IParametrosCaja;
    CatalogoSql: ICatalogoSql;
    IncidenciasSql: IRegistroIncidenciasSql;
    RegistroLog: IRegistroLog;
    SeleccionBanco: IRepositorioSeleccionBancoEmpresa;
    Usuario: string;
    procedure Validar;
  end;

function CrearDependenciasFacturasUniDAC(
  const AContexto: TContextoFacturasUniDAC
): TDependenciasFacturas;

implementation

uses
  System.SysUtils,
  Data.DB,
  UniDataFacturaRecibidaInterna,
  inLibEmisionFiscal,
  inLibFacturasBorrado,
  inLibFacturasComposicion,
  inLibFacturasConsolidacion,
  inLibFacturasIncidenciaFiscal,
  inLibFacturasMovimientos,
  inLibFacturasReapertura,
  inLibFacturasRectificativa,
  inLibFacturasServiciosIntf,
  inLibFacturasSubsanacion,
  inLibGenBusq,
  inLibPivoteVentaComposicionIntf,
  inLibVerifactuColaIntf,
  UniDataArticulosAtributosRepositorio,
  UniDataArticulosResolverRepositorio,
  UniDataArticulosValidadorRepositorio,
  UniDataColumnasDocumentoRepositorio,
  UniDataColumnasSkuServicios,
  UniDataFacturasIncidenciaFiscal,
  UniDataFacturasLecturas,
  UniDataFacturasListado,
  UniDataFacturasOperaciones,
  UniDataFacturasRectificativa,
  UniDataFacturasRepositorio,
  UniDataFacturasSubsanacion,
  UniDataPivoteVenta,
  UniDataValoresAutomaticosRepositorio,
  UniDataVentasWsCola,
  UniDataVerifactuColaRepositorio,
  UniDataVerifactuSubsanacionRepositorio;

resourcestring
  SErrorConexionFacturasNoDisponible =
    'No se proporcionó la conexión de Facturas.';
  SErrorParametrosAppFacturasNoDisponibles =
    'No se proporcionaron los parámetros de aplicación de Facturas.';
  SErrorParametrosCajaFacturasNoDisponibles =
    'No se proporcionaron los parámetros de Caja para Facturas.';
  SErrorRegistroLogFacturasNoDisponible =
    'No se proporcionó el registro de actividad de Facturas.';
  SErrorSeleccionBancoFacturasNoDisponible =
    'No se proporcionó la selección de banco de Facturas.';

type
  TCreadorPivoteVentaFacturaUniDAC = class(
    TInterfacedObject,
    ICreadorPivoteVentaFactura)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Crear(
      const AUsuario: string;
      const ABusquedaVisual: IBusquedaVisual
    ): TRepositoriosPivoteVenta;
  end;

procedure TContextoFacturasUniDAC.Validar;
begin
  if not Assigned(Conexion) then
    raise EArgumentNilException.Create(
      SErrorConexionFacturasNoDisponible);
  if not Assigned(ParametrosApp) then
    raise EArgumentNilException.Create(
      SErrorParametrosAppFacturasNoDisponibles);
  if not Assigned(ParametrosCaja) then
    raise EArgumentNilException.Create(
      SErrorParametrosCajaFacturasNoDisponibles);
  if not Assigned(RegistroLog) then
    raise EArgumentNilException.Create(
      SErrorRegistroLogFacturasNoDisponible);
  if not Assigned(SeleccionBanco) then
    raise EArgumentNilException.Create(
      SErrorSeleccionBancoFacturasNoDisponible);
end;

constructor TCreadorPivoteVentaFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TCreadorPivoteVentaFacturaUniDAC.Crear(
  const AUsuario: string;
  const ABusquedaVisual: IBusquedaVisual
): TRepositoriosPivoteVenta;
begin
  if not Assigned(ABusquedaVisual) then
    raise EArgumentNilException.Create('ABusquedaVisual');
  Result := CrearRepositorioPivoteVenta(
    FConexion,
    AUsuario,
    ABusquedaVisual);
end;

function CrearDependenciasLineasFacturasUniDAC(
  const AContexto: TContextoFacturasUniDAC
): TDependenciasLineasFactura;
begin
  Result := Default(TDependenciasLineasFactura);
  Result.Articulos.Resolver :=
    TRepositorioArticulosResolver.Create(
      AContexto.Conexion,
      AContexto.ParametrosCaja,
      AContexto.CatalogoSql,
      AContexto.IncidenciasSql);
  Result.Articulos.Validador :=
    TRepositorioArticulosValidador.Create(
      AContexto.Conexion,
      AContexto.CatalogoSql,
      AContexto.IncidenciasSql);
  Result.Articulos.Atributos :=
    TRepositorioArticulosAtributos.Create(
      AContexto.Conexion,
      AContexto.CatalogoSql,
      AContexto.IncidenciasSql);
  Result.Lecturas := CrearRepositorioLecturasFacturaUniDAC(
    AContexto.Conexion);
  Result.ColumnasSku := CrearServiciosColumnasSkuUniDAC(
    AContexto.Conexion);
  Result.AtributosGlobales :=
    CrearColumnasDocumentoLecturas(AContexto.Conexion);
  Result.Pivote :=
    TCreadorPivoteVentaFacturaUniDAC.Create(AContexto.Conexion);
end;

procedure ComponerOperacionesFacturasUniDAC(
  const AContexto: TContextoFacturasUniDAC;
  var ADependencias: TDependenciasFacturas);
var
  oCola: IServicioVerifactuCola;
  oMovimientos: IServicioMovimientosFactura;
begin
  ADependencias.Persistencia := CrearPersistenciaFacturasUniDAC(
    AContexto.Conexion);
  oCola := CrearServicioVerifactuColaUniDAC(AContexto.Conexion);
  ADependencias.EmisionFiscal := CrearServicioEmisionFiscal(
    AContexto.ParametrosApp,
    AContexto.ParametrosCaja,
    AContexto.Conexion,
    oCola);
  oMovimientos := TServicioMovimientosFactura.Create(
    AContexto.Conexion,
    ADependencias.Persistencia.Movimientos,
    TRepositorioValoresAutomaticosUniDAC.Create(AContexto.Conexion));
  // Rectificativas (I/S) y duplicados de venta mayor; la consolidación
  // cierra el vínculo de las creadas sin emitir.
  ADependencias.Rectificativa := CrearServicioRectificativaFactura(
    CrearRepositorioRectificativaFacturaUniDAC(AContexto.Conexion),
    oCola,
    ADependencias.EmisionFiscal,
    AContexto.ParametrosApp,
    AContexto.ParametrosCaja,
    AContexto.Usuario,
    ADependencias.Persistencia.UnidadTrabajo);
  ADependencias.ServiciosDataModule := CrearServiciosFactura(
    AContexto.Conexion,
    TRepositorioFacturas.Create(
      AContexto.Conexion,
      AContexto.CatalogoSql,
      AContexto.IncidenciasSql),
    ADependencias.Lineas.Lecturas,
    ADependencias.Persistencia,
    ADependencias.Lineas.Articulos.Resolver,
    oCola);
  // FZ-ISSUE-322: el mismo validador fiscal que la grabación de la
  // cabecera, para no emitir una factura sin IVA que lleva cuota.
  ADependencias.Consolidacion := CrearCasoUsoConsolidacionFactura(
    ADependencias.Persistencia.UnidadTrabajo,
    ADependencias.Persistencia.Consolidacion,
    ADependencias.EmisionFiscal,
    oMovimientos,
    ADependencias.Rectificativa,
    ADependencias.ServiciosDataModule.ValidadorFiscal,
    CrearServicioFacturaRecibidaInternaUniDAC(AContexto.Conexion));
  ADependencias.ServiciosDataModule.CrearBorrado :=
    function(AConexion: TCustomConnection): IServicioBorradoFactura
    var
      oConexion: TUniConnection;
    begin
      oConexion := AConexion as TUniConnection;
      Result := TServicioBorradoFactura.Create(
        oConexion,
        CrearPersistenciaFacturasUniDAC(oConexion).Borrado,
        CrearServicioVerifactuColaUniDAC(oConexion));
    end;
  ADependencias.Cobros := ADependencias.ServiciosDataModule.Efectos;
  ADependencias.Reapertura := CrearServicioReaperturaBorrador(
    AContexto.ParametrosApp,
    AContexto.ParametrosCaja,
    AContexto.Conexion,
    ADependencias.Persistencia.Reapertura,
    CrearRepositorioVentasWsColaUniDAC(AContexto.Conexion),
    AContexto.RegistroLog);
  ADependencias.IncidenciaFiscal := CrearServicioIncidenciaFiscalFactura(
    CrearRepositorioIncidenciaFiscalFacturaUniDAC(AContexto.Conexion),
    oCola,
    CrearServicioVerifactuSubsanacionUniDAC(AContexto.Conexion),
    ADependencias.EmisionFiscal,
    AContexto.ParametrosApp,
    AContexto.ParametrosCaja,
    AContexto.Usuario,
    ADependencias.Persistencia.UnidadTrabajo);
  // Subsanación del registro fiscal con la misma identidad de factura.
  ADependencias.Subsanacion := CrearServicioSubsanacionFactura(
    CrearRepositorioSubsanacionFacturaUniDAC(AContexto.Conexion),
    ADependencias.Persistencia.UnidadTrabajo,
    CrearServicioVerifactuCorreccionRegistroUniDAC(AContexto.Conexion),
    oCola,
    oMovimientos,
    ADependencias.Persistencia.Consolidacion,
    AContexto.ParametrosApp,
    AContexto.ParametrosCaja,
    AContexto.Usuario,
    AContexto.RegistroLog);
end;

function CrearDependenciasFacturasUniDAC(
  const AContexto: TContextoFacturasUniDAC
): TDependenciasFacturas;
begin
  AContexto.Validar;
  Result := Default(TDependenciasFacturas);
  Result.Lineas := CrearDependenciasLineasFacturasUniDAC(AContexto);
  Result.Listado := CrearPreparadorListadoFacturasUniDAC(
    AContexto.Conexion);
  Result.SeleccionBanco := AContexto.SeleccionBanco;
  ComponerOperacionesFacturasUniDAC(AContexto, Result);
  Result.Validar;
end;

end.
