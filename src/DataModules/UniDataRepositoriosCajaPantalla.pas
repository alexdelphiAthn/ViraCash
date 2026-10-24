{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosCajaPantalla                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de operación de caja requeridos por las pantallas.            }
{******************************************************************************}
unit UniDataRepositoriosCajaPantalla;

interface

uses
  Data.DB, Uni,
  inLibCajasDefectoPersistenciaIntf, inLibFaseCobroPersistenciaIntf,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPagosHistPersistenciaIntf, inLibCajaVentaIntf,
  inLibTraspasoOpePersistenciaIntf, inLibModalArqueoPersistenciaIntf,
  inLibArqueoPersistencia, inLibInformesCajaPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosCajaPantalla = interface
    ['{6348B7FD-E5FE-48AC-85CB-7B85AD979A44}']
    function CrearRepositorioCajasDefecto(
      AConexion: TUniConnection = nil): IRepositorioCajasDefecto;
    function CrearRepositorioFaseCobro(
      AConexion: TUniConnection = nil): IRepositorioFaseCobro;
    function CrearRepositorioCajaOperacionesHist(
      ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
    function CrearRepositorioCajaPagosHist(
      ADataSet: TDataSet): IRepositorioCajaPagosHist;
    function CrearRepositorioConsultasCaja(
      AConexion: TUniConnection = nil): IRepositorioConsultasCaja;
    function CrearRepositorioArticulosCaja(
      AConexion: TUniConnection = nil): IRepositorioArticulosCaja;
    function CrearRepositorioTraspasoOpe(
      AConexion: TUniConnection = nil): IRepositorioTraspasoOpe;
    function CrearRepositorioModalArqueo(
      AConexion: TUniConnection = nil): IRepositorioModalArqueo;
    function CrearPersistenciaArqueoCaja(
      AConexion: TUniConnection = nil;
      AEnviarVentasWs: Boolean = False): IArqueoPersistencia;
    function CrearRepositorioInformesCaja(
      AConexion: TUniConnection = nil): IRepositorioInformesCaja;
  end;

  TRepositoriosCajaPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosCajaPantalla)
  public
    function CrearRepositorioCajasDefecto(
      AConexion: TUniConnection = nil): IRepositorioCajasDefecto;
    function CrearRepositorioFaseCobro(
      AConexion: TUniConnection = nil): IRepositorioFaseCobro;
    function CrearRepositorioCajaOperacionesHist(
      ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
    function CrearRepositorioCajaPagosHist(
      ADataSet: TDataSet): IRepositorioCajaPagosHist;
    function CrearRepositorioConsultasCaja(
      AConexion: TUniConnection = nil): IRepositorioConsultasCaja;
    function CrearRepositorioArticulosCaja(
      AConexion: TUniConnection = nil): IRepositorioArticulosCaja;
    function CrearRepositorioTraspasoOpe(
      AConexion: TUniConnection = nil): IRepositorioTraspasoOpe;
    function CrearRepositorioModalArqueo(
      AConexion: TUniConnection = nil): IRepositorioModalArqueo;
    function CrearPersistenciaArqueoCaja(
      AConexion: TUniConnection = nil;
      AEnviarVentasWs: Boolean = False): IArqueoPersistencia;
    function CrearRepositorioInformesCaja(
      AConexion: TUniConnection = nil): IRepositorioInformesCaja;
  end;

implementation

uses
  System.SysUtils, UniDataCajasDefectoRepositorio,
  UniDataFaseCobroRepositorio, UniDataCajaOperacionesHistRepositorio,
  UniDataCajaPagosHistRepositorio, UniDataCajaConsultasRepositorio,
  UniDataTraspasoOpeRepositorio, UniDataModalArqueoRepositorio,
  UniDataArqueoPersistencia, UniDataInformesCajaRepositorio,
  UniDataVentasWsCola, inLibVentasWsColaIntf;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioCajasDefecto(
  AConexion: TUniConnection): IRepositorioCajasDefecto;
begin
  Result := CrearRepositorioCajasDefectoUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioFaseCobro(
  AConexion: TUniConnection): IRepositorioFaseCobro;
begin
  Result := CrearRepositorioFaseCobroUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioCajaOperacionesHist(
  ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
begin
  if not (ADataSet is TUniQuery) then
    raise Exception.Create(
      'La consulta del histórico de caja no es compatible con UniDAC.');
  Result := CrearRepositorioCajaOperacionesHistUniDAC(TUniQuery(ADataSet));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioCajaPagosHist(
  ADataSet: TDataSet): IRepositorioCajaPagosHist;
begin
  if not (ADataSet is TUniQuery) then
    raise Exception.Create(
      'La consulta del histórico de pagos de caja no es compatible ' +
      'con UniDAC.');
  Result := CrearRepositorioCajaPagosHistUniDAC(TUniQuery(ADataSet));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioConsultasCaja(
  AConexion: TUniConnection): IRepositorioConsultasCaja;
begin
  Result := TRepositorioConsultasCaja.Create(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioArticulosCaja(
  AConexion: TUniConnection): IRepositorioArticulosCaja;
begin
  Result := CrearRepositorioArticulosCajaUniDAC(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioTraspasoOpe(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;
begin
  Result := CrearRepositorioTraspasoOpeUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioModalArqueo(
  AConexion: TUniConnection): IRepositorioModalArqueo;
begin
  Result := CrearRepositorioModalArqueoUniDAC(Conexion(AConexion));
end;

function TRepositoriosCajaPantallaUniDAC.CrearPersistenciaArqueoCaja(
  AConexion: TUniConnection;
  AEnviarVentasWs: Boolean): IArqueoPersistencia;
var
  ConexionArqueo: TUniConnection;
  RepositorioVentasWs: IAltaVentasWsCola;
begin
  ConexionArqueo := Conexion(AConexion);
  RepositorioVentasWs := nil;
  if AEnviarVentasWs then
    RepositorioVentasWs :=
      CrearRepositorioVentasWsColaUniDAC(ConexionArqueo);
  Result := CrearPersistenciaArqueo(
    ConexionArqueo,
    RepositorioVentasWs,
    AEnviarVentasWs);
end;

function TRepositoriosCajaPantallaUniDAC.CrearRepositorioInformesCaja(
  AConexion: TUniConnection): IRepositorioInformesCaja;
begin
  Result := CrearRepositorioInformesCajaUniDAC(Conexion(AConexion));
end;

end.
