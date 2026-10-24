{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoGenPresentacionFiltrosVcl                               }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta los modales de guardado y gestion de filtros al gestor del Mto.    }
{    Recibe capacidades explicitas; nunca el formulario.                      }
{******************************************************************************}
unit inMtoGenPresentacionFiltrosVcl;

interface

uses
  System.Classes,
  cxGridDBTableView,
  inLibDestinosFiltrosPersistenciaIntf,
  inLibGestorFiltrosMto;

type
  TInteraccionFiltrosMtoVcl = class
  private
    FPropietario: TComponent;
    FMantenimiento: string;
    FNombreVista: string;
    FVista: TcxGridDBTableView;
    FDestinos: IRepositorioDestinosFiltros;
  public
    constructor Create(
      APropietario: TComponent;
      const AMantenimiento, ANombreVista: string;
      AVista: TcxGridDBTableView;
      const ADestinos: IRepositorioDestinosFiltros);
    function SolicitarDatosFiltro: TDatosGuardadoFiltroMto;
    function EjecutarGestionFiltros(
      const AFiltroActualBase64: string):
      TResultadoGestionFiltroMto;
  end;

function CrearDatosGuardadoFiltroMto(
  AAceptado: Boolean;
  const ANombre, ADescripcion: string): TDatosGuardadoFiltroMto;
function CrearResultadoGestionFiltroMto(
  AAplicado: Boolean;
  const AFiltroBase64: string): TResultadoGestionFiltroMto;

implementation

uses
  System.SysUtils,
  inMtoModalGestionFiltros,
  inMtoModalGuardarFiltro;

resourcestring
  SErrorVistaFiltrosMtoNoDisponible =
    'No se proporciono la vista de los filtros del mantenimiento.';
  SErrorDestinosFiltrosMtoNoDisponibles =
    'No se proporciono el repositorio de destinos de filtros.';

function CrearDatosGuardadoFiltroMto(
  AAceptado: Boolean;
  const ANombre, ADescripcion: string): TDatosGuardadoFiltroMto;
begin
  Result := Default(TDatosGuardadoFiltroMto);
  Result.Aceptado := AAceptado;
  Result.Nombre := ANombre;
  Result.Descripcion := ADescripcion;
end;

function CrearResultadoGestionFiltroMto(
  AAplicado: Boolean;
  const AFiltroBase64: string): TResultadoGestionFiltroMto;
begin
  Result := Default(TResultadoGestionFiltroMto);
  Result.Aplicado := AAplicado;
  Result.FiltroBase64 := AFiltroBase64;
end;

constructor TInteraccionFiltrosMtoVcl.Create(
  APropietario: TComponent;
  const AMantenimiento, ANombreVista: string;
  AVista: TcxGridDBTableView;
  const ADestinos: IRepositorioDestinosFiltros);
begin
  inherited Create;
  if AVista = nil then
    raise EArgumentNilException.Create(
      SErrorVistaFiltrosMtoNoDisponible);
  if not Assigned(ADestinos) then
    raise EArgumentNilException.Create(
      SErrorDestinosFiltrosMtoNoDisponibles);
  FPropietario := APropietario;
  FMantenimiento := AMantenimiento;
  FNombreVista := ANombreVista;
  FVista := AVista;
  FDestinos := ADestinos;
end;

function TInteraccionFiltrosMtoVcl.SolicitarDatosFiltro:
  TDatosGuardadoFiltroMto;
var
  Resultado: TGuardarFiltroResult;
begin
  Resultado := TfrmModalGuardarFiltro.Ejecutar(FPropietario);
  Result := CrearDatosGuardadoFiltroMto(
    Resultado.Aceptado,
    Resultado.Nombre,
    Resultado.Descripcion);
end;

function TInteraccionFiltrosMtoVcl.EjecutarGestionFiltros(
  const AFiltroActualBase64: string):
  TResultadoGestionFiltroMto;
var
  Resultado: TGestionFiltrosResult;
begin
  Resultado := TfrmModalGestionFiltros.Ejecutar(
    FPropietario,
    FMantenimiento,
    FNombreVista,
    FVista,
    AFiltroActualBase64,
    FDestinos);
  Result := CrearResultadoGestionFiltroMto(
    Resultado.Aplicado,
    Resultado.FiltroBase64);
end;

end.
