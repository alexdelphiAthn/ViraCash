{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesMaterializar                            }
{    Tipo:       Repositorio                                                   }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de persistencias del materializador de compras.          }
{******************************************************************************}
unit UniDataComprasSesionesMaterializar;

interface

uses
  Uni,
  inLibComprasSesionesIntf,
  inLibComprasSesionesLecturasIntf,
  inLibComprasSesionesMaterializacionIntf,
  inLibFotos,
  UniDataComprasSesiones;

type
  TPersistenciaMaterializacionComprasSesiones = class(
    TInterfacedObject,
    IPersistenciaMaterializacionComprasSesiones,
    IPersistenciaReversionComprasSesiones)
  private
    FConexion: TUniConnection;
    FDataModule: TdmComprasSesiones;
    FFotos: TFotosArticulos;
    FLecturas: TServiciosLecturasMaterializacion;
    FRepositorioSesiones: IRepositorioLecturasComprasSesiones;
  public
    // AConexion: la de la unidad de trabajo; todas las escrituras van
    // por ella para que la materialización sea todo o nada.
    constructor Create(
      ADataModule: TdmComprasSesiones;
      AConexion: TUniConnection;
      AFotos: TFotosArticulos;
      const ALecturas: TServiciosLecturasMaterializacion;
      const ARepositorioSesiones:
        IRepositorioLecturasComprasSesiones);
    function ValidarMaterializacion(
      out AMensajeError: string): Boolean;
    function CargarConfiguracion:
      TConfiguracionMaterializacionSesion;
    function ConsultarAlmacenes: TArray<string>;
    function ResolverSerieDocumento(
      const AEmpresa, ATipoDocumento, AAlmacen,
      ASerieAlternativa: string): string;
    procedure MigrarFotosConfirmadas(const AUsuario: string);
    procedure MaterializarArticulos(
      const AUsuario: string;
      const AOpcionesTarifa: TOpcionesTarifaSesion);
    function MaterializarPedido(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    // AHoraMovimiento: hora del movimiento de stock elegida en el
    // diálogo; negativa = la hora actual.
    function MaterializarAlbaran(
      const AUsuario, ASerie, AAlmacen: string;
      AHoraMovimiento: TDateTime):
      TDocumentoMaterializado;
    procedure CerrarSesion(
      const APedido, AAlbaran: TDocumentoMaterializado;
      const AUsuario: string);
    procedure RegistrarError(
      const AUsuario, AMensaje: string);
    function ValidarReversion(
      out AMensajeError: string): Boolean;
    procedure EjecutarReversion(
      const AUsuario: string);
  end;

implementation
uses
  System.SysUtils,
  UniDataComprasSesionesAlbaranes,
  UniDataComprasSesionesArticulos,
  UniDataComprasSesionesEstado,
  UniDataComprasSesionesPedidos,
  UniDataComprasSesionesReversion;
constructor TPersistenciaMaterializacionComprasSesiones.Create(
  ADataModule: TdmComprasSesiones;
  AConexion: TUniConnection;
  AFotos: TFotosArticulos;
  const ALecturas: TServiciosLecturasMaterializacion;
  const ARepositorioSesiones:
    IRepositorioLecturasComprasSesiones);
begin
  inherited Create;
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if (not Assigned(ALecturas.Articulos)) or
     (not Assigned(ALecturas.Albaranes.Articulos)) or
     (not Assigned(ALecturas.Albaranes.Documentos)) or
     (not Assigned(ALecturas.Estado)) or
     (not Assigned(ALecturas.Pedidos.Articulos)) or
     (not Assigned(ALecturas.Pedidos.Documentos)) or
     (not Assigned(ALecturas.Pedidos.Pendientes)) or
     (not Assigned(ALecturas.Reversion)) then
    raise EArgumentNilException.Create('ALecturas');
  if not Assigned(ARepositorioSesiones) then
    raise EArgumentNilException.Create('ARepositorioSesiones');
  FConexion := AConexion;
  FDataModule := ADataModule;
  FFotos := AFotos;
  FLecturas := ALecturas;
  FRepositorioSesiones := ARepositorioSesiones;
end;
function TPersistenciaMaterializacionComprasSesiones.
  ValidarMaterializacion(
    out AMensajeError: string): Boolean;
begin
  Result := ValidarMaterializacionSesion(
    FDataModule,
    FRepositorioSesiones,
    AMensajeError);
end;
function TPersistenciaMaterializacionComprasSesiones.
  CargarConfiguracion:
    TConfiguracionMaterializacionSesion;
begin
  Result := CargarConfiguracionMaterializacion(
    FDataModule);
end;
function TPersistenciaMaterializacionComprasSesiones.
  ConsultarAlmacenes: TArray<string>;
begin
  Result := ConsultarAlmacenesMaterializacion(
    FDataModule,
    FLecturas.Estado);
end;
function TPersistenciaMaterializacionComprasSesiones.
  ResolverSerieDocumento(
    const AEmpresa, ATipoDocumento, AAlmacen,
    ASerieAlternativa: string): string;
begin
  Result := ResolverSerieMaterializacion(
    FDataModule,
    FConexion,
    AEmpresa,
    ATipoDocumento,
    AAlmacen,
    ASerieAlternativa);
end;
procedure TPersistenciaMaterializacionComprasSesiones.
  MaterializarArticulos(
    const AUsuario: string;
    const AOpcionesTarifa: TOpcionesTarifaSesion);
begin
  MaterializarArticulosSesion(
    FDataModule,
    FConexion,
    FLecturas.Articulos,
    AUsuario,
    AOpcionesTarifa);
end;
procedure TPersistenciaMaterializacionComprasSesiones.
  MigrarFotosConfirmadas(const AUsuario: string);
begin
  if FConexion.InTransaction then
    raise Exception.Create(
      'Las fotos provisionales requieren confirmar la transacción.');
  MigrarFotosArticulosSesion(
    FDataModule, FFotos, FLecturas.Articulos, AUsuario);
end;
function TPersistenciaMaterializacionComprasSesiones.
  MaterializarPedido(
    const AUsuario, ASerie, AAlmacen: string):
    TDocumentoMaterializado;
begin
  Result := MaterializarPedidoSesion(
    FDataModule,
    FConexion,
    FLecturas.Pedidos,
    AUsuario,
    ASerie,
    AAlmacen);
end;
function TPersistenciaMaterializacionComprasSesiones.
  MaterializarAlbaran(
    const AUsuario, ASerie, AAlmacen: string;
    AHoraMovimiento: TDateTime):
    TDocumentoMaterializado;
begin
  Result := MaterializarAlbaranSesion(
    FDataModule,
    FConexion,
    FLecturas.Albaranes,
    AUsuario,
    ASerie,
    AAlmacen,
    AHoraMovimiento);
end;
procedure TPersistenciaMaterializacionComprasSesiones.
  CerrarSesion(
    const APedido, AAlbaran: TDocumentoMaterializado;
    const AUsuario: string);
begin
  CerrarSesionMaterializada(
    FDataModule,
    FConexion,
    APedido,
    AAlbaran,
    AUsuario);
end;
procedure TPersistenciaMaterializacionComprasSesiones.
  RegistrarError(
    const AUsuario, AMensaje: string);
begin
  PersistirErrorMaterializacion(
    FDataModule,
    FConexion,
    AUsuario,
    AMensaje);
end;
function TPersistenciaMaterializacionComprasSesiones.
  ValidarReversion(
    out AMensajeError: string): Boolean;
begin
  Result := ValidarReversionSesion(
    FDataModule,
    FConexion,
    FLecturas.Reversion,
    AMensajeError);
end;
procedure TPersistenciaMaterializacionComprasSesiones.
  EjecutarReversion(
    const AUsuario: string);
begin
  EjecutarReversionSesion(
    FDataModule,
    FConexion,
    FLecturas.Reversion,
    AUsuario);
end;
end.
