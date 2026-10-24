{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosDocumentosPantalla                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de documentos requeridos por las pantallas.                   }
{******************************************************************************}
unit UniDataRepositoriosDocumentosPantalla;

interface

uses
  Uni, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibLogIntf,
  inLibImpresionPersistenciaIntf,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDestinoEnvioPersistenciaIntf,
  inLibSeleccionFamiliaPersistenciaIntf,
  inLibSerieFechaFacturaPersistenciaIntf,
  inLibSeleccionAlmacenPersistenciaIntf,
  inLibFacturacionAlbaranesFechasPersistenciaIntf,
  inLibFacturacionAlbaranesCompraPersistenciaIntf,
  inLibFacturacionTicketPersistenciaIntf, inLibDocumentosTrabajo,
  UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosDocumentosPantalla = interface
    ['{62FEB439-E697-482A-9A0B-D986CE865B48}']
    function CrearServiciosPersistenciaImpresion(
      AConexion: TUniConnection = nil): TServiciosPersistenciaImpresion;
    function CrearServiciosPersistenciaDevolucionCompra(
      AConexion: TUniConnection = nil
    ): TServiciosPersistenciaDevolucionCompra;
    function CrearRepositorioDestinoEnvio(
      AConexion: TUniConnection = nil): IRepositorioDestinoEnvio;
    function CrearRepositorioSeleccionFamilia(
      AConexion: TUniConnection = nil): IRepositorioSeleccionFamilia;
    function CrearRepositorioSerieFechaFactura(
      AConexion: TUniConnection = nil): IRepositorioSerieFechaFactura;
    function CrearRepositorioSeleccionAlmacen(
      AConexion: TUniConnection = nil): IRepositorioSeleccionAlmacen;
    function CrearRepositorioFacturacionAlbaranesFechas(
      AConexion: TUniConnection = nil
    ): IRepositorioFacturacionAlbaranesFechas;
    function CrearRepositorioFacturacionAlbaranesCompra(
      AConexion: TUniConnection = nil
    ): IRepositorioFacturacionAlbaranesCompra;
    function CrearServicioFacturacionTicket(
      AConexion: TUniConnection = nil): IServicioFacturacionTicket;
    function CrearRepositoriosDocumentosTrabajo(
      AConexion: TUniConnection = nil): TRepositoriosDocumentosTrabajo;
  end;

  TRepositoriosDocumentosPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosDocumentosPantalla)
  private
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FRegistroLog: IRegistroLog;
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const ARegistroLog: IRegistroLog;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql);
    destructor Destroy; override;
    function CrearServiciosPersistenciaImpresion(
      AConexion: TUniConnection = nil): TServiciosPersistenciaImpresion;
    function CrearServiciosPersistenciaDevolucionCompra(
      AConexion: TUniConnection = nil
    ): TServiciosPersistenciaDevolucionCompra;
    function CrearRepositorioDestinoEnvio(
      AConexion: TUniConnection = nil): IRepositorioDestinoEnvio;
    function CrearRepositorioSeleccionFamilia(
      AConexion: TUniConnection = nil): IRepositorioSeleccionFamilia;
    function CrearRepositorioSerieFechaFactura(
      AConexion: TUniConnection = nil): IRepositorioSerieFechaFactura;
    function CrearRepositorioSeleccionAlmacen(
      AConexion: TUniConnection = nil): IRepositorioSeleccionAlmacen;
    function CrearRepositorioFacturacionAlbaranesFechas(
      AConexion: TUniConnection = nil
    ): IRepositorioFacturacionAlbaranesFechas;
    function CrearRepositorioFacturacionAlbaranesCompra(
      AConexion: TUniConnection = nil
    ): IRepositorioFacturacionAlbaranesCompra;
    function CrearServicioFacturacionTicket(
      AConexion: TUniConnection = nil): IServicioFacturacionTicket;
    function CrearRepositoriosDocumentosTrabajo(
      AConexion: TUniConnection = nil): TRepositoriosDocumentosTrabajo;
  end;

implementation

uses
  UniDataImpresionRepositorio, UniDataDevolucionesCompraRepositorio,
  UniDataDestinoEnvioRepositorio, UniDataSeleccionFamiliaRepositorio,
  UniDataSerieFechaFacturaRepositorio, UniDataSeleccionAlmacenRepositorio,
  UniDataFacturacionAlbaranesFechasRepositorio,
  UniDataFacturacionAlbaranesCompraRepositorio,
  UniDataFacturacionTicketRepositorio,
  UniDataVerifactuColaRepositorio, UniDataDocumentosTrabajoRepositorio,
  inLibEmisionFiscal, inLibEmisionFiscalIntf,
  inLibVerifactuColaIntf;

constructor TRepositoriosDocumentosPantallaUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create(
    AConexionPrincipal, ACatalogoSql, AIncidenciasSql);
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FRegistroLog := ARegistroLog;
end;

destructor TRepositoriosDocumentosPantallaUniDAC.Destroy;
begin
  FRegistroLog := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  inherited;
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearServiciosPersistenciaImpresion(
  AConexion: TUniConnection): TServiciosPersistenciaImpresion;
begin
  Result := CrearServiciosPersistenciaImpresionUniDAC(Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearServiciosPersistenciaDevolucionCompra(
  AConexion: TUniConnection): TServiciosPersistenciaDevolucionCompra;
begin
  Result := CrearServiciosPersistenciaDevolucionCompraUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.CrearRepositorioDestinoEnvio(
  AConexion: TUniConnection): IRepositorioDestinoEnvio;
begin
  Result := CrearRepositorioDestinoEnvioUniDAC(Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearRepositorioSeleccionFamilia(
  AConexion: TUniConnection): IRepositorioSeleccionFamilia;
begin
  Result := CrearRepositorioSeleccionFamiliaUniDAC(Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearRepositorioSerieFechaFactura(
  AConexion: TUniConnection): IRepositorioSerieFechaFactura;
begin
  Result := CrearRepositorioSerieFechaFacturaUniDAC(Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearRepositorioSeleccionAlmacen(
  AConexion: TUniConnection): IRepositorioSeleccionAlmacen;
begin
  Result := CrearRepositorioSeleccionAlmacenUniDAC(Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearRepositorioFacturacionAlbaranesFechas(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;
begin
  Result := CrearRepositorioFacturacionAlbaranesFechasUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearRepositorioFacturacionAlbaranesCompra(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesCompra;
begin
  Result := CrearRepositorioFacturacionAlbaranesCompraUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearServicioFacturacionTicket(
  AConexion: TUniConnection): IServicioFacturacionTicket;
var
  oCola: IServicioVerifactuCola;
  oConexion: TUniConnection;
  oEmision: IServicioEmisionFiscal;
begin
  oConexion := Conexion(AConexion);
  oCola := CrearServicioVerifactuColaUniDAC(oConexion, FRegistroLog);
  oEmision := inLibEmisionFiscal.CrearServicioEmisionFiscal(
    FParametrosApp, FParametrosCaja, oConexion, oCola);
  Result := CrearServicioFacturacionTicketUniDAC(
    oConexion, FParametrosApp, oEmision, oCola);
end;

function TRepositoriosDocumentosPantallaUniDAC.
  CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;
begin
  Result :=
    UniDataDocumentosTrabajoRepositorio.CrearRepositoriosDocumentosTrabajo(
      Conexion(AConexion));
end;

end.
