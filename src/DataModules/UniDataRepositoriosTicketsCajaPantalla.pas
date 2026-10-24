{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosTicketsCajaPantalla                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de tickets de caja requeridos por las pantallas.              }
{******************************************************************************}
unit UniDataRepositoriosTicketsCajaPantalla;

interface

uses
  Uni, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibContextoSesionIntf, inLibPreviewTicket,
  inLibGastoCajaPersistenciaIntf, inLibEntradaCambioPersistenciaIntf,
  inLibGenerarTicketIntf, inLibTraspasoTicketIntf, inLibArqueoIntf,
  inLibArqueoTicketIntf, inLibTiraCajaTicketIntf,
  inLibTicketsCajaIntf, UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosTicketsCajaPantalla = interface
    ['{E2452458-D235-4816-9EEE-40FF9C4E3826}']
    function CrearRepositorioGastoCaja(
      AConexion: TUniConnection = nil): IRepositorioGastoCaja;
    function CrearRepositorioEntradaCambio(
      AConexion: TUniConnection = nil): IRepositorioEntradaCambio;
    function CrearLecturasImpresionTicketCaja(
      AConexion: TUniConnection = nil): ILecturasImpresionTicket;
    function CrearRepositorioTraspasoTicket(
      AConexion: TUniConnection = nil): IRepositorioTraspasoTicket;
    function CrearRepositorioArqueoCaja(
      AConexion: TUniConnection = nil): IRepositorioArqueoCaja;
    function CrearRepositorioArqueoTicket(
      AConexion: TUniConnection = nil): IRepositorioArqueoTicket;
    function CrearRepositorioTiraCajaTicket(
      AConexion: TUniConnection = nil): IRepositorioTiraCajaTicket;
    function CrearRepositorioTicketsCaja(
      AConexion: TUniConnection = nil): TRepositoriosTicketsCaja;
  end;

  TRepositoriosTicketsCajaPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosTicketsCajaPantalla)
  private
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FContextoSesion: IContextoSesionAplicacion;
    FPreviewTicket: IPreviewTicket;
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const APreviewTicket: IPreviewTicket;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql);
    destructor Destroy; override;
    function CrearRepositorioGastoCaja(
      AConexion: TUniConnection = nil): IRepositorioGastoCaja;
    function CrearRepositorioEntradaCambio(
      AConexion: TUniConnection = nil): IRepositorioEntradaCambio;
    function CrearLecturasImpresionTicketCaja(
      AConexion: TUniConnection = nil): ILecturasImpresionTicket;
    function CrearRepositorioTraspasoTicket(
      AConexion: TUniConnection = nil): IRepositorioTraspasoTicket;
    function CrearRepositorioArqueoCaja(
      AConexion: TUniConnection = nil): IRepositorioArqueoCaja;
    function CrearRepositorioArqueoTicket(
      AConexion: TUniConnection = nil): IRepositorioArqueoTicket;
    function CrearRepositorioTiraCajaTicket(
      AConexion: TUniConnection = nil): IRepositorioTiraCajaTicket;
    function CrearRepositorioTicketsCaja(
      AConexion: TUniConnection = nil): TRepositoriosTicketsCaja;
  end;

implementation

uses
  UniDataGastoCajaRepositorio, UniDataEntradaCambioRepositorio,
  UniDataGenerarTicketRepositorio, UniDataTraspasoTicketRepositorio,
  UniDataArqueoRepositorio, UniDataArqueoTicketRepositorio,
  UniDataTiraCajaTicketRepositorio, UniDataTicketsCajaRepositorio;

constructor TRepositoriosTicketsCajaPantallaUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const APreviewTicket: IPreviewTicket;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create(
    AConexionPrincipal, ACatalogoSql, AIncidenciasSql);
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FContextoSesion := AContextoSesion;
  FPreviewTicket := APreviewTicket;
end;

destructor TRepositoriosTicketsCajaPantallaUniDAC.Destroy;
begin
  FPreviewTicket := nil;
  FContextoSesion := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  inherited;
end;

function TRepositoriosTicketsCajaPantallaUniDAC.CrearRepositorioGastoCaja(
  AConexion: TUniConnection): IRepositorioGastoCaja;
begin
  Result := CrearRepositorioGastoCajaUniDAC(
    Conexion(AConexion), FParametrosApp, FParametrosCaja,
    FPreviewTicket, FContextoSesion);
end;

function TRepositoriosTicketsCajaPantallaUniDAC.CrearRepositorioEntradaCambio(
  AConexion: TUniConnection): IRepositorioEntradaCambio;
begin
  Result := CrearRepositorioEntradaCambioUniDAC(
    Conexion(AConexion), FParametrosApp, FParametrosCaja,
    FPreviewTicket, FContextoSesion);
end;

function TRepositoriosTicketsCajaPantallaUniDAC.
  CrearLecturasImpresionTicketCaja(
  AConexion: TUniConnection): ILecturasImpresionTicket;
begin
  Result := UniDataGenerarTicketRepositorio.CrearLecturasImpresionTicket(
    Conexion(AConexion));
end;

function TRepositoriosTicketsCajaPantallaUniDAC.
  CrearRepositorioTraspasoTicket(
  AConexion: TUniConnection): IRepositorioTraspasoTicket;
begin
  Result := TRepositorioTraspasoTicket.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosTicketsCajaPantallaUniDAC.CrearRepositorioArqueoCaja(
  AConexion: TUniConnection): IRepositorioArqueoCaja;
begin
  Result := TRepositorioArqueoCaja.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosTicketsCajaPantallaUniDAC.CrearRepositorioArqueoTicket(
  AConexion: TUniConnection): IRepositorioArqueoTicket;
begin
  Result := TRepositorioArqueoTicket.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosTicketsCajaPantallaUniDAC.
  CrearRepositorioTiraCajaTicket(
  AConexion: TUniConnection): IRepositorioTiraCajaTicket;
begin
  Result := TRepositorioTiraCajaTicket.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosTicketsCajaPantallaUniDAC.CrearRepositorioTicketsCaja(
  AConexion: TUniConnection): TRepositoriosTicketsCaja;
begin
  Result := UniDataTicketsCajaRepositorio.CrearRepositoriosTicketsCaja(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

end.
