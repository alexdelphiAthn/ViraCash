{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsSesion                                         }
{    Tipo:       Composición de persistencia                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Crea una sesión VentasWs de segundo plano y conserva la conexión UniDAC   }
{    como detalle privado durante la vida del repositorio y el serializador.   }
{******************************************************************************}
unit UniDataVentasWsSesion;

interface

uses
  inLibConexionesIntf, inLibVentasWsColaIntf;

function CrearFabricaSesionVentasWsUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionVentasWs;

implementation

uses
  inLibEstadoColasIntf, UniDataEstadoColas,
  System.SysUtils, Uni, inLibVentasWsJsonIntf,
  inLibVentasWsColaHistorialIntf, UniDataVentasWsCola,
  UniDataVentasWsColaHistorial, UniDataVentasWsJson;

type
  TSesionVentasWsUniDAC = class(TInterfacedObject, ISesionVentasWs)
  private
    FConexion: TUniConnection;
    FRepositorio: IDespachoVentasWsCola;
    FJson: IVentasWsJson;
    FRegistradorIntentos: IRegistradorIntentosVentasWsCola;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function LeerIncidencia(AHorasIncidencias: Integer): string;
    function GetRepositorio: IDespachoVentasWsCola;
    function GetJson: IVentasWsJson;
    function GetRegistradorIntentos:
      IRegistradorIntentosVentasWsCola;
  end;
  TFabricaSesionVentasWsUniDAC = class(
    TInterfacedObject,
    IFabricaSesionVentasWs)
  private
    FConexiones: IServicioConexiones;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function CrearSesion: ISesionVentasWs;
  end;

function TSesionVentasWsUniDAC.LeerIncidencia(
  AHorasIncidencias: Integer): string;
begin
  Result := LeerIncidenciaCola(FConexion, tceWs, AHorasIncidencias);
end;

constructor TSesionVentasWsUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexion := AConexiones.CrearConexion(nil, uctSegundoPlano);
  FRepositorio := CrearRepositorioVentasWsColaUniDAC(FConexion);
  FRegistradorIntentos :=
    CrearRegistradorIntentosVentasWsColaUniDAC(FConexion);
  FJson := CrearVentasWsJsonUniDAC(FConexion);
end;

destructor TSesionVentasWsUniDAC.Destroy;
begin
  FJson := nil;
  FRegistradorIntentos := nil;
  FRepositorio := nil;
  FreeAndNil(FConexion);
  inherited;
end;

function TSesionVentasWsUniDAC.GetRepositorio:
  IDespachoVentasWsCola;
begin
  Result := FRepositorio;
end;

function TSesionVentasWsUniDAC.GetJson: IVentasWsJson;
begin
  Result := FJson;
end;

function TSesionVentasWsUniDAC.GetRegistradorIntentos:
  IRegistradorIntentosVentasWsCola;
begin
  Result := FRegistradorIntentos;
end;

constructor TFabricaSesionVentasWsUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexiones := AConexiones;
end;

destructor TFabricaSesionVentasWsUniDAC.Destroy;
begin
  FConexiones := nil;
  inherited;
end;

function TFabricaSesionVentasWsUniDAC.CrearSesion: ISesionVentasWs;
begin
  Result := TSesionVentasWsUniDAC.Create(FConexiones);
end;

function CrearFabricaSesionVentasWsUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionVentasWs;
begin
  Result := TFabricaSesionVentasWsUniDAC.Create(AConexiones);
end;

end.
