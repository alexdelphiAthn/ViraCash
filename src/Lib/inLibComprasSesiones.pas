{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesiones                                          }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Casos de uso de sesiones de compra sobre un repositorio inyectado.        }
{******************************************************************************}
unit inLibComprasSesiones;

interface

uses
  System.Classes,
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf,
  inLibComprasSesionesMaterializar;

type
  TServicioComprasSesiones = class
  private
    FRepositorio: IRepositorioComprasSesiones;
    FMaterializador: TMaterializadorComprasSesiones;
    FRevertidor: TRevertidorComprasSesiones;
  public
    constructor Create(
      const ARepositorio: IRepositorioComprasSesiones;
      const APersistenciaMaterializacion:
        IPersistenciaMaterializacionComprasSesiones;
      const APersistenciaReversion:
        IPersistenciaReversionComprasSesiones;
      const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
    destructor Destroy; override;
    procedure AplicarDuplicadoEnLinea(
      const AResultado: TResolverDuplicadoSesion);
    procedure BorrarCeldasLinea(
      const ASerie, ANumero: string;
      ALinea: Integer);
    procedure CopiarCeldasDistribuidas(
      const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
      ALineaOrigen, ALineaDestino: Integer);
    function RenumerarLineas(
      const ASerie, ANumero: string): TCambiosLineaSesion;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    function ConsultarCodigosBasicosActivos(
      const AIdVariacion: string): TArray<string>;
    function ConsultarKitProveedor(
      const ACodigoProveedor, ACodigoKit: string;
      AIdAcLinea: Integer): TKitProveedorSesion;
    function ConsultarDetallesKitProveedor(
      const ACodigoProveedor, ACodigoKit: string):
      TDetallesKitProveedorSesion;
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ObtenerNombreFamilia(
      const ACodigoFamilia: string): string;
    function ObtenerDescripcionFamilia(
      const ACodigoFamilia: string): string;
    function ResolverCodigoFamilia(
      const ACodigoTecleado, AUsuario: string;
      out ACodigoGenerado: string): Boolean;
    function ResolverDuplicado(
      const ACodigoBuscado, ACodigoProveedor: string;
      ASoloRefProveedor: Boolean = False;
      const ACodigoArticuloPreferido: string = ''):
      TResolverDuplicadoSesion;
    function ResolverDuplicadoIntraSesion(
      const ASerie, ANumero: string;
      ALineaActual: Integer;
      const AModelo, ACodigoArticulo: string):
      TResolverDuplicadoSesion;
    function NormalizarDuplicadosIntraSesion(
      const AUsuario, ASerie, ANumero: string): Integer;
    function ValidarSesionDetallado(
      AIncidencias: TStrings): Boolean;
    function EjecutarMaterializacion(
      const AParametros: TParametrosMaterializacionSesion;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    function AlmacenesSinSeriePropia(
      const AParametros: TParametrosMaterializacionSesion;
      const AEmpresa: string;
      AGeneraPedido, AGeneraAlbaran: Boolean): TSeriesAlmacenesSinPropia;
    function ReintentarFotos(const AUsuario: string;
      out AAviso: string): Boolean;
    function RevertirMaterializacion(
      const AUsuario: string;
      out AMensajeError: string): Boolean;
  end;

function CalcularPrecioVenta(
  ACoste, AMargenPorcentaje, AMultiplo, AAjuste: Double): Double;

function CoeficienteDesdeMargenVenta(AMargen: Double): Double;
function MargenVentaDesdeCoeficiente(ACoeficiente: Double): Double;

implementation

uses
  System.Math, System.SysUtils;

constructor TServicioComprasSesiones.Create(
  const ARepositorio: IRepositorioComprasSesiones;
  const APersistenciaMaterializacion:
    IPersistenciaMaterializacionComprasSesiones;
  const APersistenciaReversion:
    IPersistenciaReversionComprasSesiones;
  const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
  FMaterializador := TMaterializadorComprasSesiones.Create(
    APersistenciaMaterializacion,
    AUnidadTrabajo);
  FRevertidor := TRevertidorComprasSesiones.Create(
    APersistenciaReversion,
    AUnidadTrabajo);
end;

destructor TServicioComprasSesiones.Destroy;
begin
  FreeAndNil(FRevertidor);
  FreeAndNil(FMaterializador);
  inherited Destroy;
end;

procedure TServicioComprasSesiones.AplicarDuplicadoEnLinea(
  const AResultado: TResolverDuplicadoSesion);
begin
  FRepositorio.AplicarDuplicadoEnLinea(AResultado);
end;

procedure TServicioComprasSesiones.BorrarCeldasLinea(
  const ASerie, ANumero: string;
  ALinea: Integer);
begin
  FRepositorio.BorrarCeldasLinea(
    Trim(ASerie),
    Trim(ANumero),
    ALinea);
end;

procedure TServicioComprasSesiones.CopiarCeldasDistribuidas(
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);
begin
  FRepositorio.CopiarCeldasDistribuidas(
    Trim(ASerie),
    Trim(ANumero),
    Trim(AAlmacenCabecera),
    Trim(AUsuario),
    ALineaOrigen,
    ALineaDestino);
end;

function TServicioComprasSesiones.RenumerarLineas(
  const ASerie, ANumero: string): TCambiosLineaSesion;
begin
  Result := FRepositorio.RenumerarLineas(Trim(ASerie), Trim(ANumero));
end;

function TServicioComprasSesiones.ConsultarCantidadesLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
begin
  Result := FRepositorio.ConsultarCantidadesLinea(
    Trim(ASerie),
    Trim(ANumero),
    ALinea);
end;

function TServicioComprasSesiones.ConsultarCodigosBasicosActivos(
  const AIdVariacion: string): TArray<string>;
begin
  Result := FRepositorio.ConsultarCodigosBasicosActivos(
    Trim(AIdVariacion));
end;

function TServicioComprasSesiones.ConsultarKitProveedor(
  const ACodigoProveedor, ACodigoKit: string;
  AIdAcLinea: Integer): TKitProveedorSesion;
begin
  Result := FRepositorio.ConsultarKitProveedor(
    Trim(ACodigoProveedor),
    Trim(ACodigoKit),
    AIdAcLinea);
end;

function TServicioComprasSesiones.
  ConsultarDetallesKitProveedor(
  const ACodigoProveedor, ACodigoKit: string):
  TDetallesKitProveedorSesion;
begin
  Result := FRepositorio.ConsultarDetallesKitProveedor(
    Trim(ACodigoProveedor),
    Trim(ACodigoKit));
end;

function TServicioComprasSesiones.ObtenerSiguienteLinea(
  const ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
begin
  Result := FRepositorio.ObtenerSiguienteLinea(
    Trim(ASerie),
    Trim(ANumero),
    ALineaActual);
end;

function TServicioComprasSesiones.ObtenerNombreFamilia(
  const ACodigoFamilia: string): string;
begin
  Result := FRepositorio.ObtenerNombreFamilia(
    Trim(ACodigoFamilia));
end;

function TServicioComprasSesiones.ObtenerDescripcionFamilia(
  const ACodigoFamilia: string): string;
begin
  Result := FRepositorio.ObtenerDescripcionFamilia(
    Trim(ACodigoFamilia));
end;

function TServicioComprasSesiones.ResolverCodigoFamilia(
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
begin
  Result := FRepositorio.ResolverCodigoFamilia(
    Trim(ACodigoTecleado),
    Trim(AUsuario),
    ACodigoGenerado);
end;

function TServicioComprasSesiones.ResolverDuplicado(
  const ACodigoBuscado, ACodigoProveedor: string;
  ASoloRefProveedor: Boolean;
  const ACodigoArticuloPreferido: string):
  TResolverDuplicadoSesion;
begin
  Result := FRepositorio.ResolverDuplicado(
    Trim(ACodigoBuscado),
    Trim(ACodigoProveedor),
    ASoloRefProveedor,
    Trim(ACodigoArticuloPreferido));
end;

function TServicioComprasSesiones.ResolverDuplicadoIntraSesion(
  const ASerie, ANumero: string;
  ALineaActual: Integer;
  const AModelo, ACodigoArticulo: string):
  TResolverDuplicadoSesion;
begin
  Result := FRepositorio.ResolverDuplicadoIntraSesion(
    Trim(ASerie),
    Trim(ANumero),
    ALineaActual,
    Trim(AModelo),
    Trim(ACodigoArticulo));
end;

function TServicioComprasSesiones.NormalizarDuplicadosIntraSesion(
  const AUsuario, ASerie, ANumero: string): Integer;
begin
  Result := FRepositorio.NormalizarDuplicadosIntraSesion(
    Trim(AUsuario),
    Trim(ASerie),
    Trim(ANumero));
end;

function TServicioComprasSesiones.ValidarSesionDetallado(
  AIncidencias: TStrings): Boolean;
var
  iIncidencia: Integer;
  oIncidencias: TIncidenciasSesionCompra;
begin
  if not Assigned(AIncidencias) then
    raise EArgumentNilException.Create('AIncidencias');
  AIncidencias.Clear;
  oIncidencias := FRepositorio.ValidarSesionDetallado;
  for iIncidencia := 0 to High(oIncidencias) do
    AIncidencias.Add(oIncidencias[iIncidencia]);
  Result := Length(oIncidencias) = 0;
end;

function TServicioComprasSesiones.EjecutarMaterializacion(
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
begin
  Result := FMaterializador.Ejecutar(
    AParametros,
    AResultado);
end;

function TServicioComprasSesiones.AlmacenesSinSeriePropia(
  const AParametros: TParametrosMaterializacionSesion;
  const AEmpresa: string;
  AGeneraPedido, AGeneraAlbaran: Boolean): TSeriesAlmacenesSinPropia;
begin
  Result := FMaterializador.AlmacenesSinSeriePropia(
    AParametros,
    AEmpresa,
    AGeneraPedido,
    AGeneraAlbaran);
end;

function TServicioComprasSesiones.ReintentarFotos(
  const AUsuario: string; out AAviso: string): Boolean;
begin
  Result := FMaterializador.ReintentarFotos(AUsuario, AAviso);
end;

function TServicioComprasSesiones.RevertirMaterializacion(
  const AUsuario: string;
  out AMensajeError: string): Boolean;
begin
  Result := FRevertidor.Ejecutar(
    Trim(AUsuario),
    AMensajeError);
end;

function CoeficienteDesdeMargenVenta(AMargen: Double): Double;
begin
  if AMargen >= 100 then
    raise EArgumentOutOfRangeException.Create('Margen >= 100');
  Result := 100 / (1 - AMargen / 100);
end;

function MargenVentaDesdeCoeficiente(ACoeficiente: Double): Double;
begin
  if ACoeficiente > 0 then
    Result := 100 * (1 - 100 / ACoeficiente)
  else
    Result := 0;
end;

function CalcularPrecioVenta(
  ACoste, AMargenPorcentaje, AMultiplo, AAjuste: Double): Double;
var
  dBase: Double;
begin
  dBase := ACoste * AMargenPorcentaje / 100;
  if AMultiplo > 0 then
    dBase := Ceil(dBase / AMultiplo) * AMultiplo;
  Result := dBase - AAjuste;
  if Result < 0 then
    Result := 0;
end;

end.
