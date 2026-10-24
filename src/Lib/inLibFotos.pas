{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotos                                                    }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada compatible del servicio de fotografías de artículos y sesiones. }
{    Delega consulta, edición, almacenamiento, sesión y presentación.         }
{******************************************************************************}
unit inLibFotos;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni,
  frxClass,
  inLibParametrosIntf, inLibArticulosValidadorIntf,
  inLibFotosPersistenciaIntf, inLibFotosTipos,
  inLibFotosConsulta, inLibFotosAlmacenamiento,
  inLibFotosEdicion, inLibFotosSesion,
  inLibFotosPresentacion;

type
  TFotoResolucion = inLibFotosTipos.TFotoResolucion;
  TFotoOrigen = inLibFotosTipos.TFotoOrigen;
  TFotoInfo = inLibFotosTipos.TFotoInfo;
  TFotoEmbebida = inLibFotosPresentacion.TFotoEmbebida;
  TSolicitudFotoSesion = inLibFotosSesion.TSolicitudFotoSesion;
  TSolicitudesFotosSesion = inLibFotosSesion.TSolicitudesFotosSesion;

const
  frPx300 = inLibFotosTipos.frPx300;
  frPx600 = inLibFotosTipos.frPx600;
  frReal = inLibFotosTipos.frReal;
  foSinFoto = inLibFotosTipos.foSinFoto;
  foArticulo = inLibFotosTipos.foArticulo;
  foSkuPrefijo = inLibFotosTipos.foSkuPrefijo;
  foSku = inLibFotosTipos.foSku;
  fcodartfot = inLibFotosTipos.fcodartfot;
  fcodunidadfot = inLibFotosTipos.fcodunidadfot;
  fordenfot = inLibFotosTipos.fordenfot;
  fnomfot = inLibFotosTipos.fnomfot;
  fextfot = inLibFotosTipos.fextfot;
  finstalta = inLibFotosTipos.finstalta;
  finstmodif = inLibFotosTipos.finstmodif;
  fusralta = inLibFotosTipos.fusralta;
  fusrmodif = inLibFotosTipos.fusrmodif;
  cSubdir300 = inLibFotosTipos.cSubdir300;
  cSubdir600 = inLibFotosTipos.cSubdir600;
  cSubdirReal = inLibFotosTipos.cSubdirReal;
  cLado300 = inLibFotosTipos.cLado300;
  cLado600 = inLibFotosTipos.cLado600;

type
  TFotosArticulos = class(TProveedorFotosPresentacion)
  private
    FConexion       : TUniConnection;
    FValidador      : IArticulosValidador;
    FConsulta       : TConsultaFotos;
    FAlmacenamiento : TAlmacenamientoFotos;
    FEdicion        : TEdicionFotos;
    FSesion         : TSesionFotos;
    FPresentacion   : TPresentacionFotos;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AsignarConexion(AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AValidador: IArticulosValidador;
      const ARepositorio: TRepositoriosFotos);
    procedure LiberarServicios;
    function RutaFoto(const AInfo: TFotoInfo;
      AResolucion: TFotoResolucion): string; override;
    function Resolver(const ACodArt,
      ACodSku: string): TFotoInfo; override;
    function ResolverColeccion(const ACodArt,
      ACodSku: string): TArray<TFotoInfo>;
    function ResolverFotosVariaciones(
      const ACodArt: string): TArray<TFotoInfo>;
    function ResolverArticulosLote(
      const ACodigos: TArray<string>): TDictionary<string, TFotoInfo>;
    procedure PrecargarFotosLote(const ACodigos: TArray<string>);
    procedure LimpiarPrecargaFotos;
    function Guardar(const ACodArt, ACodSku, AFicheroOrigen,
      AUsuario: string): TFotoInfo;
    function Anadir(const ACodArt, ACodSku, AFicheroOrigen,
      AUsuario: string): TFotoInfo;
    function Rotar(const ACodArt, ACodSku: string;
      AHorario: Boolean; const AUsuario: string): TFotoInfo; overload;
    function Rotar(const AInfo: TFotoInfo; AHorario: Boolean;
      const AUsuario: string): TFotoInfo; overload;
    procedure Eliminar(const ACodArt, ACodUnidad: string); overload;
    procedure Eliminar(const AInfo: TFotoInfo); overload;
    function MarcarPredeterminada(const AInfo: TFotoInfo;
      const AUsuario: string): TFotoInfo;
    procedure HandlerReportBeforePrint(
      Component: TfrxReportComponent);
    procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
      out ACodArt, ACodSku: string); override;
    property Conexion: TUniConnection read FConexion;
    property Sesion: TSesionFotos read FSesion;
    property Validador: IArticulosValidador read FValidador;
  end;

  IProveedorFotosArticulos = interface
    ['{1F76441D-366B-4D67-81CF-CB4107B824F7}']
    function GetFotosArticulos: TFotosArticulos;
    property FotosArticulos: TFotosArticulos
      read GetFotosArticulos;
  end;

procedure EngancharFotosEnReport(AFotos: TFotosArticulos;
  Report: TfrxReport);
function ObtenerDataSetDeBandaPadre(AObj: TfrxComponent): TDataSet;
function GenerarPrefijosSku(const ACodSku: string): TArray<string>;
procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
  out ACodArt, ACodSku: string; AFotos: TFotosArticulos = nil);

implementation

constructor TFotosArticulos.Create;
begin
  inherited Create;
  FConsulta := TConsultaFotos.Create;
  FAlmacenamiento := TAlmacenamientoFotos.Create;
  FEdicion := TEdicionFotos.Create(FConsulta, FAlmacenamiento);
  FSesion := TSesionFotos.Create(FAlmacenamiento);
  FPresentacion := TPresentacionFotos.Create;
end;

destructor TFotosArticulos.Destroy;
begin
  FreeAndNil(FPresentacion);
  FreeAndNil(FSesion);
  FreeAndNil(FEdicion);
  FreeAndNil(FAlmacenamiento);
  FreeAndNil(FConsulta);
  inherited;
end;

procedure TFotosArticulos.AsignarConexion(AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AValidador: IArticulosValidador;
  const ARepositorio: TRepositoriosFotos);
begin
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if (not Assigned(ARepositorio.Consulta)) or
     (not Assigned(ARepositorio.Edicion)) or
     (not Assigned(ARepositorio.Sesion)) then
    raise EArgumentNilException.Create('ARepositorio');
  FConexion := AConexion;
  FValidador := AValidador;
  FAlmacenamiento.AsignarParametros(AParametrosApp);
  FConsulta.AsignarServicios(
    AConexion, AValidador, ARepositorio.Consulta);
  FEdicion.AsignarRepositorio(ARepositorio.Edicion);
  FSesion.AsignarRepositorios(
    ARepositorio.Sesion, ARepositorio.Edicion);
end;

procedure TFotosArticulos.LiberarServicios;
begin
  FSesion.LiberarServicios;
  FEdicion.LiberarServicios;
  FConsulta.LiberarServicios;
  FAlmacenamiento.LiberarServicios;
  FConexion := nil;
  FValidador := nil;
end;

function TFotosArticulos.RutaFoto(const AInfo: TFotoInfo;
  AResolucion: TFotoResolucion): string;
begin
  Result := FAlmacenamiento.RutaFoto(AInfo, AResolucion);
end;

function TFotosArticulos.Resolver(const ACodArt,
  ACodSku: string): TFotoInfo;
begin
  Result := FConsulta.Resolver(ACodArt, ACodSku);
end;

function TFotosArticulos.ResolverColeccion(const ACodArt,
  ACodSku: string): TArray<TFotoInfo>;
begin
  Result := FConsulta.ResolverColeccion(ACodArt, ACodSku);
end;

function TFotosArticulos.ResolverFotosVariaciones(
  const ACodArt: string): TArray<TFotoInfo>;
begin
  Result := FConsulta.ResolverFotosVariaciones(ACodArt);
end;

function TFotosArticulos.ResolverArticulosLote(
  const ACodigos: TArray<string>): TDictionary<string, TFotoInfo>;
begin
  Result := FConsulta.ResolverArticulosLote(ACodigos);
end;

procedure TFotosArticulos.PrecargarFotosLote(
  const ACodigos: TArray<string>);
begin
  FConsulta.PrecargarFotosLote(ACodigos);
end;

procedure TFotosArticulos.LimpiarPrecargaFotos;
begin
  FConsulta.LimpiarPrecargaFotos;
end;

function TFotosArticulos.Guardar(const ACodArt, ACodSku,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
begin
  Result := FEdicion.Guardar(
    ACodArt, ACodSku, AFicheroOrigen, AUsuario);
end;

function TFotosArticulos.Anadir(const ACodArt, ACodSku,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
begin
  Result := FEdicion.Anadir(
    ACodArt, ACodSku, AFicheroOrigen, AUsuario);
end;

function TFotosArticulos.Rotar(const ACodArt, ACodSku: string;
  AHorario: Boolean; const AUsuario: string): TFotoInfo;
begin
  Result := FEdicion.Rotar(
    ACodArt, ACodSku, AHorario, AUsuario);
end;

function TFotosArticulos.Rotar(const AInfo: TFotoInfo;
  AHorario: Boolean; const AUsuario: string): TFotoInfo;
begin
  Result := FEdicion.Rotar(AInfo, AHorario, AUsuario);
end;

procedure TFotosArticulos.Eliminar(const ACodArt,
  ACodUnidad: string);
begin
  FEdicion.Eliminar(ACodArt, ACodUnidad);
end;

procedure TFotosArticulos.Eliminar(const AInfo: TFotoInfo);
begin
  FEdicion.Eliminar(AInfo);
end;

function TFotosArticulos.MarcarPredeterminada(
  const AInfo: TFotoInfo;
  const AUsuario: string): TFotoInfo;
begin
  Result := FEdicion.MarcarPredeterminada(AInfo, AUsuario);
end;

procedure TFotosArticulos.HandlerReportBeforePrint(
  Component: TfrxReportComponent);
begin
  FPresentacion.AntesDeImprimir(Self, Component);
end;

procedure TFotosArticulos.LeerArtSkuDeDataSet(ADataSet: TDataSet;
  out ACodArt, ACodSku: string);
begin
  FConsulta.LeerArtSkuDeDataSet(ADataSet, ACodArt, ACodSku);
end;

procedure EngancharFotosEnReport(AFotos: TFotosArticulos;
  Report: TfrxReport);
begin
  if Assigned(Report) and Assigned(AFotos) then
    Report.OnBeforePrint := AFotos.HandlerReportBeforePrint;
end;

function ObtenerDataSetDeBandaPadre(
  AObj: TfrxComponent): TDataSet;
begin
  Result := inLibFotosPresentacion.ObtenerDataSetDeBandaPadre(AObj);
end;

function GenerarPrefijosSku(const ACodSku: string): TArray<string>;
begin
  Result := inLibFotosConsulta.GenerarPrefijosSku(ACodSku);
end;

procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
  out ACodArt, ACodSku: string; AFotos: TFotosArticulos);
begin
  if Assigned(AFotos) then
    AFotos.LeerArtSkuDeDataSet(ADataSet, ACodArt, ACodSku)
  else
    LeerArtSkuBasicoDeDataSet(ADataSet, ACodArt, ACodSku);
end;

end.
