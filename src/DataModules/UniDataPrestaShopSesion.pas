{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopSesion                                     }
{    Tipo:       Composición de persistencia                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Crea una sesión de cola PrestaShop con una conexión UniDAC propia para    }
{    el trabajo en segundo plano.                                              }
{******************************************************************************}
unit UniDataPrestaShopSesion;

interface

uses
  inLibConexionesIntf, inLibPrestaShopColaIntf,
  inLibPrestaShopAltaArticuloIntf,
  inLibPrestaShopColaHistorialIntf;

function CrearFabricaSesionPrestaShopColaUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionPrestaShopCola;

implementation

uses
  inLibEstadoColasIntf, UniDataEstadoColas,
  System.SysUtils, Uni, UniDataPrestaShopCola,
  UniDataPrestaShopAltaArticulo,
  UniDataPrestaShopColaHistorial;

type
  TSesionPrestaShopColaUniDAC = class(
    TInterfacedObject,
    ISesionPrestaShopCola)
  private
    FConexion: TUniConnection;
    FRepositorio: IRepositorioPrestaShopCola;
    FRepositorioAlta: IRepositorioAltaArticuloPresta;
    FRegistradorEventos: IRegistradorEventosPrestaShopCola;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function LeerIncidencia(const AInstalacion: string;
      ATienda, AHorasIncidencias: Integer): string;
    function GetRepositorio: IRepositorioPrestaShopCola;
    function GetRepositorioAlta: IRepositorioAltaArticuloPresta;
    function GetRegistradorEventos:
      IRegistradorEventosPrestaShopCola;
  end;

  TFabricaSesionPrestaShopColaUniDAC = class(
    TInterfacedObject,
    IFabricaSesionPrestaShopCola)
  private
    FConexiones: IServicioConexiones;
  public
    constructor Create(const AConexiones: IServicioConexiones);
    destructor Destroy; override;
    function CrearSesion: ISesionPrestaShopCola;
  end;

function TSesionPrestaShopColaUniDAC.LeerIncidencia(const AInstalacion: string;
  ATienda, AHorasIncidencias: Integer): string;
begin
  Result := LeerIncidenciaCola(FConexion, tcePrestaShop,
    AHorasIncidencias, AInstalacion, ATienda);
end;

constructor TSesionPrestaShopColaUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexion := AConexiones.CrearConexion(nil, uctSegundoPlano);
  FRepositorio := CrearRepositorioPrestaShopColaUniDAC(FConexion);
  FRepositorioAlta :=
    CrearRepositorioAltaArticuloPrestaUniDAC(FConexion);
  FRegistradorEventos :=
    CrearRegistradorEventosPrestaShopColaUniDAC(FConexion);
end;

destructor TSesionPrestaShopColaUniDAC.Destroy;
begin
  FRegistradorEventos := nil;
  FRepositorioAlta := nil;
  FRepositorio := nil;
  FreeAndNil(FConexion);
  inherited;
end;

function TSesionPrestaShopColaUniDAC.GetRegistradorEventos:
  IRegistradorEventosPrestaShopCola;
begin
  Result := FRegistradorEventos;
end;

function TSesionPrestaShopColaUniDAC.GetRepositorioAlta:
  IRepositorioAltaArticuloPresta;
begin
  Result := FRepositorioAlta;
end;

function TSesionPrestaShopColaUniDAC.GetRepositorio:
  IRepositorioPrestaShopCola;
begin
  Result := FRepositorio;
end;

constructor TFabricaSesionPrestaShopColaUniDAC.Create(
  const AConexiones: IServicioConexiones);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  inherited Create;
  FConexiones := AConexiones;
end;

destructor TFabricaSesionPrestaShopColaUniDAC.Destroy;
begin
  FConexiones := nil;
  inherited;
end;

function TFabricaSesionPrestaShopColaUniDAC.CrearSesion:
  ISesionPrestaShopCola;
begin
  Result := TSesionPrestaShopColaUniDAC.Create(FConexiones);
end;

function CrearFabricaSesionPrestaShopColaUniDAC(
  const AConexiones: IServicioConexiones): IFabricaSesionPrestaShopCola;
begin
  Result := TFabricaSesionPrestaShopColaUniDAC.Create(AConexiones);
end;

end.
