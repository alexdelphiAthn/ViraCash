{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionComposicion                     }
{    Tipo:       Composicion de pantalla                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Unico punto donde la consulta de stock resuelve sus adaptadores de        }
{    persistencia. Devuelve un contexto de feature cerrado para que la         }
{    pantalla no vuelva a descubrir repositorios durante un evento.            }
{******************************************************************************}
unit inMtoStockConsultaPresentacionComposicion;

interface

uses
  Uni,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibDocumentosTrabajo,
  inLibLectorScanner,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosOperacionesPantalla,
  inLibOperacionesCajaSkuPersistenciaIntf,
  inLibMovimientosSkuPersistenciaIntf,
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaInfo,
  inLibStockConsultaPersistenciaIntf;

type
  // Resumen de cabecera (propiedades, tarifas y proveedores) detras de un
  // contrato propio: la pantalla no conoce el data module que lo lee.
  ILectorInfoCabeceraStock = interface
    ['{6E1B4C7A-0D2F-49B8-9C31-5A70F4E2D118}']
    function Cargar(
      const ACodigoArticulo: string): TInfoCabeceraStock;
  end;

  // Capacidades que la consulta de stock necesita del exterior. Los
  // adaptadores de persistencia los resuelve CrearContextoStockConsulta y
  // el lector y la aplicacion de entrada se completan al componer los
  // presentadores. La pantalla no las localiza por su cuenta durante un
  // evento: solo lee este contexto.
  TContextoDependenciasStockConsulta = record
    Catalogos: ILectorCatalogosStockConsulta;
    Pivote: IRepositorioPivoteStock;
    InfoCabecera: ILectorInfoCabeceraStock;
    Validador: IArticulosValidador;
    ResolverArticulos: IArticulosResolver;
    DocumentosTrabajo: TRepositoriosDocumentosTrabajo;
    OperacionesCaja: IRepositorioOperacionesCajaSku;
    Movimientos: IRepositorioMovimientosSku;
    Lector: TLectorScanner;
    Entrada: IAplicacionEntradaStock;
    class function Crear(
      const AServicios: TServiciosStockConsulta;
      const AInfoCabecera: ILectorInfoCabeceraStock;
      const AValidador: IArticulosValidador;
      const AResolverArticulos: IArticulosResolver;
      const ADocumentosTrabajo: TRepositoriosDocumentosTrabajo;
      const AOperacionesCaja: IRepositorioOperacionesCajaSku;
      const AMovimientos: IRepositorioMovimientosSku
    ): TContextoDependenciasStockConsulta; static;
    procedure Validar;
    procedure Liberar;
  end;

function CrearContextoStockConsulta(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ADocumentos: IRepositoriosDocumentosPantalla;
  const AOperaciones: IRepositoriosOperacionesPantalla;
  AConexion: TUniConnection): TContextoDependenciasStockConsulta;

implementation

uses
  System.SysUtils,
  UniDataStockConsultaInfo;

resourcestring
  SErrorCatalogosStockConsultaNoDisponibles =
    'No se proporcionó el catálogo de la consulta de stock.';
  SErrorPivoteStockConsultaNoDisponible =
    'No se proporcionó el repositorio de stock pivotado.';
  SErrorInfoStockConsultaNoDisponible =
    'No se proporcionó el lector de cabecera de la consulta de stock.';
  SErrorValidadorStockConsultaNoDisponible =
    'No se proporcionó el validador de artículos.';
  SErrorResolutorStockConsultaNoDisponible =
    'No se proporcionó el resolutor de artículos.';
  SErrorDocumentosStockConsultaNoDisponibles =
    'No se proporcionaron los repositorios de documentos de trabajo.';
  SErrorOperacionesCajaStockConsultaNoDisponibles =
    'No se proporcionó la consulta de operaciones de caja por SKU.';
  SErrorMovimientosStockConsultaNoDisponibles =
    'No se proporcionó la consulta de movimientos por SKU.';

type
  TLectorInfoCabeceraStockUniData = class(
    TInterfacedObject,
    ILectorInfoCabeceraStock)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Cargar(
      const ACodigoArticulo: string): TInfoCabeceraStock;
  end;

constructor TLectorInfoCabeceraStockUniData.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLectorInfoCabeceraStockUniData.Cargar(
  const ACodigoArticulo: string): TInfoCabeceraStock;
begin
  Result := CargarInfoCabeceraStock(FConexion, ACodigoArticulo);
end;

class function TContextoDependenciasStockConsulta.Crear(
  const AServicios: TServiciosStockConsulta;
  const AInfoCabecera: ILectorInfoCabeceraStock;
  const AValidador: IArticulosValidador;
  const AResolverArticulos: IArticulosResolver;
  const ADocumentosTrabajo: TRepositoriosDocumentosTrabajo;
  const AOperacionesCaja: IRepositorioOperacionesCajaSku;
  const AMovimientos: IRepositorioMovimientosSku
): TContextoDependenciasStockConsulta;
begin
  Result := Default(TContextoDependenciasStockConsulta);
  Result.Catalogos := AServicios.Catalogos;
  Result.Pivote := AServicios.Pivote;
  Result.InfoCabecera := AInfoCabecera;
  Result.Validador := AValidador;
  Result.ResolverArticulos := AResolverArticulos;
  Result.DocumentosTrabajo := ADocumentosTrabajo;
  Result.OperacionesCaja := AOperacionesCaja;
  Result.Movimientos := AMovimientos;
  Result.Validar;
end;

procedure TContextoDependenciasStockConsulta.Validar;
begin
  if not Assigned(Catalogos) then
    raise EArgumentNilException.Create(
      SErrorCatalogosStockConsultaNoDisponibles);
  if not Assigned(Pivote) then
    raise EArgumentNilException.Create(
      SErrorPivoteStockConsultaNoDisponible);
  if not Assigned(InfoCabecera) then
    raise EArgumentNilException.Create(
      SErrorInfoStockConsultaNoDisponible);
  if not Assigned(Validador) then
    raise EArgumentNilException.Create(
      SErrorValidadorStockConsultaNoDisponible);
  if not Assigned(ResolverArticulos) then
    raise EArgumentNilException.Create(
      SErrorResolutorStockConsultaNoDisponible);
  if not Assigned(DocumentosTrabajo.Lecturas) or
     not Assigned(DocumentosTrabajo.Escritura) or
     not Assigned(DocumentosTrabajo.Materializacion) then
  begin
    raise EArgumentNilException.Create(
      SErrorDocumentosStockConsultaNoDisponibles);
  end;
  if not Assigned(OperacionesCaja) then
    raise EArgumentNilException.Create(
      SErrorOperacionesCajaStockConsultaNoDisponibles);
  if not Assigned(Movimientos) then
    raise EArgumentNilException.Create(
      SErrorMovimientosStockConsultaNoDisponibles);
end;

// El contexto es propietario del lector; el resto son contratos que solo
// hay que soltar.
procedure TContextoDependenciasStockConsulta.Liberar;
begin
  Entrada := nil;
  FreeAndNil(Lector);
  Catalogos := nil;
  Pivote := nil;
  InfoCabecera := nil;
  Validador := nil;
  ResolverArticulos := nil;
  OperacionesCaja := nil;
  Movimientos := nil;
  DocumentosTrabajo.Lecturas := nil;
  DocumentosTrabajo.Escritura := nil;
  DocumentosTrabajo.Materializacion := nil;
end;

function CrearContextoStockConsulta(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ADocumentos: IRepositoriosDocumentosPantalla;
  const AOperaciones: IRepositoriosOperacionesPantalla;
  AConexion: TUniConnection): TContextoDependenciasStockConsulta;
var
  Servicios: TServiciosStockConsulta;
begin
  if not Assigned(AArticulos) then
    raise EArgumentNilException.Create('AArticulos');
  if not Assigned(ADocumentos) then
    raise EArgumentNilException.Create('ADocumentos');
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Servicios := AArticulos.CrearServiciosStockConsulta(AConexion);
  Result := TContextoDependenciasStockConsulta.Crear(
    Servicios,
    TLectorInfoCabeceraStockUniData.Create(AConexion),
    AArticulos.CrearValidadorArticulos(AConexion),
    AArticulos.CrearResolverArticulos(AConexion),
    ADocumentos.CrearRepositoriosDocumentosTrabajo(AConexion),
    AOperaciones.CrearRepositorioOperacionesCajaSku(AConexion),
    AOperaciones.CrearRepositorioMovimientosSku(AConexion));
end;

end.
