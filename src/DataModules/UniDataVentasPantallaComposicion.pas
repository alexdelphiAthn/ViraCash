{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasPantallaComposicion                              }
{    Tipo:       Composición                                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Compone cada pantalla de ventas con capacidades concretas y estrechas.    }
{******************************************************************************}
unit UniDataVentasPantallaComposicion;

interface

uses
  Uni,
  inLibContextoSesionIntf,
  inLibLogIntf,
  inLibParametrosIntf,
  inLibPerfilesUsuarioIntf,
  inLibVentasPantallaInyeccion,
  inLibVentasPantallaIntf,
  UniDataPedidos;

function CrearServiciosSqlVentasPantalla(
  const ANombrePantalla: string;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog): TServiciosSqlVentasPantalla;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlVentasPantalla;
  out AContexto: TContextoAlbaranesVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlVentasPantalla;
  ADataModule: TdmPedidos;
  out AContexto: TContextoPedidosVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoClientesVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  out AContexto: TContextoFacturasSimplificadasVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoDestinoEnvioVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto:
    TContextoFacturacionAlbaranesFechasVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto:
    TContextoFacturacionAlbaranesCompraVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  out AContexto: TContextoFacturacionTicketVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoSerieFechaFacturaVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionFamiliaVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionAlmacenVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlVentasPantalla;
  out AContexto: TContextoListadoVentasPantalla); overload;
procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoImpresionVentasPantalla); overload;

implementation

uses
  System.SysUtils,
  inLibEmisionFiscal,
  inLibEmisionFiscalIntf,
  inLibVentasPantallaCrearAlbaran,
  inLibVerifactuColaIntf,
  UniDataArticulosAtributosRepositorio,
  UniDataArticulosResolverRepositorio,
  UniDataArticulosValidadorRepositorio,
  UniDataClientesRepositorio,
  UniDataCatalogoSqlAplicacion,
  UniDataColumnasSkuServicios,
  UniDataDestinoEnvioRepositorio,
  UniDataDocumentosTrabajoRepositorio,
  UniDataEntradaAlbaranVentaRepositorio,
  UniDataFacturacionAlbaranesCompraRepositorio,
  UniDataFacturacionAlbaranesFechasRepositorio,
  UniDataFacturacionTicketRepositorio,
  UniDataImpresionRepositorio,
  UniDataListadoVentasRepositorio,
  UniDataSeleccionAlmacenRepositorio,
  UniDataSeleccionFamiliaRepositorio,
  UniDataSerieFechaFacturaRepositorio,
  UniDataVentasPantallaFacturasSimplificadas,
  UniDataVentasPantallaPedidos,
  UniDataVerifactuColaRepositorio;

resourcestring
  SErrorCatalogoSqlVentasPantalla =
    'No se pudo leer oGetSQLFromDB de %s: %s';

procedure ComprobarConexion(AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
end;

function CrearServiciosSqlVentasPantalla(
  const ANombrePantalla: string;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog): TServiciosSqlVentasPantalla;
var
  EsCatalogoActivo: Boolean;
begin
  Result := Default(TServiciosSqlVentasPantalla);
  EsCatalogoActivo := False;
  if Assigned(APerfilesLectura) then
  begin
    try
      EsCatalogoActivo := SameText(
        APerfilesLectura.ObtenerValorPerfil(
          ANombrePantalla,
          'oGetSQLFromDB',
          'False'),
        'True');
    except
      on E: Exception do
      begin
        if Assigned(ARegistroLog) then
        begin
          ARegistroLog.RegistrarAviso(
            Format(
              SErrorCatalogoSqlVentasPantalla,
              [ANombrePantalla, E.Message]));
        end;
      end;
    end;
  end;
  CrearCatalogoSqlAplicacion(
    APerfilesLectura,
    APerfilesEscritura,
    EsCatalogoActivo,
    Result.Catalogo,
    Result.Incidencias,
    ARegistroLog);
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlVentasPantalla;
  out AContexto: TContextoAlbaranesVentasPantalla);
var
  oContexto: TContextoAlbaranesVentasPantalla;
begin
  ComprobarConexion(AConexion);
  oContexto := Default(TContextoAlbaranesVentasPantalla);
  oContexto.ResolverArticulos :=
    TRepositorioArticulosResolver.Create(
      AConexion,
      AParametrosCaja,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  oContexto.ValidadorArticulos :=
    TRepositorioArticulosValidador.Create(
      AConexion,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  oContexto.AtributosArticulos :=
    TRepositorioArticulosAtributos.Create(
      AConexion,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  oContexto.ColumnasSku := CrearServiciosColumnasSkuUniDAC(AConexion);
  oContexto.EntradaArticulos :=
    CrearRepositorioEntradaAlbaranVentaUniDAC(AConexion);
  AContexto := PrepararContextoVentas(oContexto);
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlVentasPantalla;
  ADataModule: TdmPedidos;
  out AContexto: TContextoPedidosVentasPantalla);
var
  oContexto: TContextoPedidosVentasPantalla;
begin
  ComprobarConexion(AConexion);
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  oContexto := Default(TContextoPedidosVentasPantalla);
  oContexto.ResolverArticulos :=
    TRepositorioArticulosResolver.Create(
      AConexion,
      AParametrosCaja,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  oContexto.ValidadorArticulos :=
    TRepositorioArticulosValidador.Create(
      AConexion,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  oContexto.AtributosArticulos :=
    TRepositorioArticulosAtributos.Create(
      AConexion,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  oContexto.ColumnasSku := CrearServiciosColumnasSkuUniDAC(AConexion);
  oContexto.EntradaArticulos :=
    CrearRepositorioEntradaAlbaranVentaUniDAC(AConexion);
  oContexto.CrearAlbaran := TCasoUsoCrearAlbaranPedido.Create(
    CrearRepositorioCreacionAlbaranPedidoUniDAC(ADataModule));
  AContexto := PrepararContextoVentas(oContexto);
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoClientesVentasPantalla);
var
  oContexto: TContextoClientesVentasPantalla;
begin
  ComprobarConexion(AConexion);
  oContexto := Default(TContextoClientesVentasPantalla);
  oContexto.Repositorio := CrearRepositorioClientesUniDAC(AConexion);
  AContexto := PrepararContextoVentas(oContexto);
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  AListado: TUniQuery;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  out AContexto: TContextoFacturasSimplificadasVentasPantalla);
var
  oContexto: TContextoFacturasSimplificadasVentasPantalla;
begin
  ComprobarConexion(AConexion);
  if not Assigned(AListado) then
    raise EArgumentNilException.Create('AListado');
  oContexto := Default(TContextoFacturasSimplificadasVentasPantalla);
  oContexto.Repositorio :=
    CrearRepositorioFacturasSimplificadasPantallaUniDAC(
      AConexion,
      AListado,
      AContextoSesion,
      AParametrosApp);
  AContexto := PrepararContextoVentas(oContexto);
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoDestinoEnvioVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoDestinoEnvioVentasPantalla);
  AContexto.Repositorio := CrearRepositorioDestinoEnvioUniDAC(AConexion);
  ComprobarDependenciaVentas(AContexto.Repositorio, 'destino de envío');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoFacturacionAlbaranesFechasVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(
    TContextoFacturacionAlbaranesFechasVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositorioFacturacionAlbaranesFechasUniDAC(AConexion);
  ComprobarDependenciaVentas(
    AContexto.Repositorio,
    'facturación de albaranes por fechas');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoFacturacionAlbaranesCompraVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(
    TContextoFacturacionAlbaranesCompraVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositorioFacturacionAlbaranesCompraUniDAC(AConexion);
  ComprobarDependenciaVentas(
    AContexto.Repositorio,
    'facturación de albaranes de compra');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  out AContexto: TContextoFacturacionTicketVentasPantalla);
var
  oCola: IServicioVerifactuCola;
  oEmision: IServicioEmisionFiscal;
begin
  ComprobarConexion(AConexion);
  oCola := CrearServicioVerifactuColaUniDAC(AConexion, ARegistroLog);
  oEmision := inLibEmisionFiscal.CrearServicioEmisionFiscal(
    AParametrosApp,
    AParametrosCaja,
    AConexion,
    oCola);
  AContexto := Default(TContextoFacturacionTicketVentasPantalla);
  AContexto.Series := CrearRepositorioSerieFechaFacturaUniDAC(AConexion);
  AContexto.Facturacion := CrearServicioFacturacionTicketUniDAC(
    AConexion,
    AParametrosApp,
    oEmision,
    oCola);
  ComprobarDependenciaVentas(AContexto.Series, 'series de factura');
  ComprobarDependenciaVentas(AContexto.Facturacion, 'facturación de ticket');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoSerieFechaFacturaVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoSerieFechaFacturaVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositorioSerieFechaFacturaUniDAC(AConexion);
  ComprobarDependenciaVentas(AContexto.Repositorio, 'serie de factura');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionFamiliaVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoSeleccionFamiliaVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositorioSeleccionFamiliaUniDAC(AConexion);
  ComprobarDependenciaVentas(AContexto.Repositorio, 'selección de familia');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoSeleccionAlmacenVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoSeleccionAlmacenVentasPantalla);
  AContexto.Repositorio :=
    CrearRepositorioSeleccionAlmacenUniDAC(AConexion);
  ComprobarDependenciaVentas(AContexto.Repositorio, 'selección de almacén');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlVentasPantalla;
  out AContexto: TContextoListadoVentasPantalla);
begin
  ComprobarConexion(AConexion);
  AContexto := Default(TContextoListadoVentasPantalla);
  AContexto.Listado := CrearRepositorioListadoVentasUniDAC(AConexion);
  AContexto.DocumentosTrabajo :=
    UniDataDocumentosTrabajoRepositorio.
      CrearRepositoriosDocumentosTrabajo(AConexion);
  AContexto.ResolverArticulos :=
    TRepositorioArticulosResolver.Create(
      AConexion,
      AParametrosCaja,
      AServiciosSql.Catalogo,
      AServiciosSql.Incidencias);
  ComprobarDependenciaVentas(AContexto.Listado, 'listado de ventas');
  ComprobarDependenciaVentas(
    AContexto.DocumentosTrabajo.Lecturas,
    'lectura de documentos de trabajo');
  ComprobarDependenciaVentas(
    AContexto.DocumentosTrabajo.Escritura,
    'escritura de documentos de trabajo');
  ComprobarDependenciaVentas(
    AContexto.DocumentosTrabajo.Materializacion,
    'materialización de documentos de trabajo');
  ComprobarDependenciaVentas(
    AContexto.ResolverArticulos,
    'resolución de artículos');
end;

procedure CrearContextoVentasPantalla(
  AConexion: TUniConnection;
  out AContexto: TContextoImpresionVentasPantalla);
var
  oContexto: TContextoImpresionVentasPantalla;
begin
  ComprobarConexion(AConexion);
  oContexto := Default(TContextoImpresionVentasPantalla);
  oContexto.Persistencia :=
    CrearServiciosPersistenciaImpresionUniDAC(AConexion);
  AContexto := PrepararContextoVentas(oContexto);
end;

end.
