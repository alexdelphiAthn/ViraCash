{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosOperacionesPantalla                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de operaciones requeridos por las pantallas.                  }
{******************************************************************************}
unit UniDataRepositoriosOperacionesPantalla;

interface

uses
  Uni, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibLogIntf,
  inLibConsultaFacturasOperacionesPersistenciaIntf,
  inLibVentasCalendarioIntf, inLibEmisionFiscalIntf,
  inLibCajaArticulosOperacionIntf,
  inLibOperacionesCajaSkuPersistenciaIntf,
  inLibMovimientosSkuPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosOperacionesPantalla = interface
    ['{AF97D4E0-A6D6-49C8-9070-1763E7BF95B1}']
    function CrearRepositorioConsultaFacturas:
      IRepositorioConsultaFacturasOperaciones;
    function CrearRepositorioVentasCalendario:
      IRepositorioVentasCalendario;
    function CrearServicioEmisionFiscal: IServicioEmisionFiscal;
    function CrearRepositorioOperacionesCajaSku(
      AConexion: TUniConnection = nil): IRepositorioOperacionesCajaSku;
    function CrearRepositorioMovimientosSku(
      AConexion: TUniConnection = nil): IRepositorioMovimientosSku;
    function CrearConsultaArticulosOperacion(
      AConexion: TUniConnection = nil): IConsultaArticulosOperacionCaja;
  end;

  TRepositoriosOperacionesPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosOperacionesPantalla)
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
    function CrearRepositorioConsultaFacturas:
      IRepositorioConsultaFacturasOperaciones;
    function CrearRepositorioVentasCalendario:
      IRepositorioVentasCalendario;
    function CrearServicioEmisionFiscal: IServicioEmisionFiscal;
    function CrearRepositorioOperacionesCajaSku(
      AConexion: TUniConnection = nil): IRepositorioOperacionesCajaSku;
    function CrearRepositorioMovimientosSku(
      AConexion: TUniConnection = nil): IRepositorioMovimientosSku;
    function CrearConsultaArticulosOperacion(
      AConexion: TUniConnection = nil): IConsultaArticulosOperacionCaja;
  end;

implementation

uses
  UniDataCajaArticulosOperacionRepositorio,
  UniDataConsultaFacturasOperacionesRepositorio,
  UniDataVentasCalendario, UniDataOperacionesCajaSkuRepositorio,
  UniDataMovimientosSkuRepositorio,
  UniDataVerifactuColaRepositorio, inLibEmisionFiscal,
  inLibVerifactuColaIntf;

constructor TRepositoriosOperacionesPantallaUniDAC.Create(
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

destructor TRepositoriosOperacionesPantallaUniDAC.Destroy;
begin
  FRegistroLog := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  inherited;
end;

function TRepositoriosOperacionesPantallaUniDAC.
  CrearConsultaArticulosOperacion(
  AConexion: TUniConnection): IConsultaArticulosOperacionCaja;
begin
  Result := CrearConsultaArticulosOperacionCajaUniDAC(Conexion(AConexion));
end;

function TRepositoriosOperacionesPantallaUniDAC.
  CrearRepositorioConsultaFacturas:
  IRepositorioConsultaFacturasOperaciones;
begin
  Result := CrearRepositorioConsultaFacturasOperacionesUniDAC(
    FConexionPrincipal);
end;

function TRepositoriosOperacionesPantallaUniDAC.
  CrearRepositorioVentasCalendario: IRepositorioVentasCalendario;
begin
  Result := CrearRepositorioVentasCalendarioUniDAC(FConexionPrincipal);
end;

function TRepositoriosOperacionesPantallaUniDAC.CrearServicioEmisionFiscal:
  IServicioEmisionFiscal;
var
  oCola: IServicioVerifactuCola;
begin
  oCola := CrearServicioVerifactuColaUniDAC(
    FConexionPrincipal, FRegistroLog);
  Result := inLibEmisionFiscal.CrearServicioEmisionFiscal(
    FParametrosApp, FParametrosCaja, FConexionPrincipal, oCola);
end;

function TRepositoriosOperacionesPantallaUniDAC.
  CrearRepositorioOperacionesCajaSku(
  AConexion: TUniConnection): IRepositorioOperacionesCajaSku;
begin
  Result := CrearRepositorioOperacionesCajaSkuUniDAC(
    Conexion(AConexion));
end;

function TRepositoriosOperacionesPantallaUniDAC.
  CrearRepositorioMovimientosSku(
  AConexion: TUniConnection): IRepositorioMovimientosSku;
begin
  Result := CrearRepositorioMovimientosSkuUniDAC(
    Conexion(AConexion));
end;

end.
