{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesPresentacion                              }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones de presentacion de la sesion de compra sin VCL, sin SQL y      }
{    sin UniDAC: estado de la busqueda incremental de modelos y lectura de     }
{    teclas del selector de tallaje. El formulario y sus adaptadores solo      }
{    ejecutan el efecto.                                                       }
{******************************************************************************}
unit inLibComprasSesionesPresentacion;

interface

uses
  Winapi.Windows,
  System.Classes,
  inLibComprasSesionesPresentacionIntf;

type
  // Estado de la busqueda incremental de modelos del proveedor. Decide
  // cuando rearmar el debounce de apertura del desplegable, cuando
  // rearmar la resolucion diferida y si la lista cargada sigue siendo
  // valida para el proveedor de la cabecera. No toca controles ni datos.
  TNucleoBusquedaModeloSesion = class
  private
    FPlanificadorBusqueda: IPlanificadorDiferido;
    FPlanificadorResolucion: IPlanificadorDiferido;
    FProveedorCargado: string;
    FModeloPendiente: string;
    FArticuloPendiente: string;
    FResolucionPendiente: Boolean;
  public
    constructor Create(
      const APlanificadorBusqueda: IPlanificadorDiferido;
      const APlanificadorResolucion: IPlanificadorDiferido);
    // El usuario ha tecleado en la celda: reinicia el debounce que
    // abre el desplegable ya filtrado.
    procedure RegistrarTecleo;
    // El usuario ha elegido una fila del desplegable.
    procedure RegistrarSeleccion(
      const AModelo: string;
      const ACodigoArticulo: string);
    // El usuario ha confirmado texto libre (Tab / Enter / clic fuera).
    // Si la seleccion del desplegable ya armo este mismo texto se
    // respeta, porque aquella lleva ademas el codigo de articulo.
    procedure RegistrarConfirmacion(const ATexto: string);
    // Consume la resolucion pendiente. Un modelo vacio representa que
    // el usuario ha borrado el dato y debe invalidarse el codigo derivado.
    function TomarPendiente(
      out AModelo: string;
      out ACodigoArticulo: string): Boolean;
    // La lista del desplegable se recarga si cambia el proveedor de la
    // cabecera o si el cursor quedo cerrado tras un ResetForm.
    function DebeRecargarLista(
      const AProveedor: string;
      AListaAbierta: Boolean): Boolean;
    procedure MarcarListaCargada(const AProveedor: string);
    property ProveedorCargado: string read FProveedorCargado;
  end;


implementation

uses
  System.SysUtils;

// Centinela imposible como codigo de proveedor: fuerza la primera
// carga de la lista de modelos aunque la sesion no tenga proveedor.
const
  cProveedorSinCargar = #1;

constructor TNucleoBusquedaModeloSesion.Create(
  const APlanificadorBusqueda: IPlanificadorDiferido;
  const APlanificadorResolucion: IPlanificadorDiferido);
begin
  inherited Create;
  if not Assigned(APlanificadorBusqueda) then
    raise EArgumentNilException.Create('APlanificadorBusqueda');
  if not Assigned(APlanificadorResolucion) then
    raise EArgumentNilException.Create('APlanificadorResolucion');
  FPlanificadorBusqueda := APlanificadorBusqueda;
  FPlanificadorResolucion := APlanificadorResolucion;
  FProveedorCargado := cProveedorSinCargar;
  FModeloPendiente := '';
  FArticuloPendiente := '';
  FResolucionPendiente := False;
end;

procedure TNucleoBusquedaModeloSesion.RegistrarTecleo;
begin
  FPlanificadorBusqueda.Rearmar;
end;

procedure TNucleoBusquedaModeloSesion.RegistrarSeleccion(
  const AModelo: string;
  const ACodigoArticulo: string);
begin
  FModeloPendiente := AModelo;
  FArticuloPendiente := ACodigoArticulo;
  FResolucionPendiente := Trim(FModeloPendiente) <> '';
  if FResolucionPendiente then
    FPlanificadorResolucion.Rearmar;
end;

procedure TNucleoBusquedaModeloSesion.RegistrarConfirmacion(
  const ATexto: string);
var
  sTexto: string;
begin
  sTexto := Trim(ATexto);
  if (not FResolucionPendiente) or
     (not FPlanificadorResolucion.Armado) or
     (FModeloPendiente <> sTexto) then
  begin
    FModeloPendiente := sTexto;
    FArticuloPendiente := '';
    FResolucionPendiente := True;
    FPlanificadorResolucion.Rearmar;
  end;
end;

function TNucleoBusquedaModeloSesion.TomarPendiente(
  out AModelo: string;
  out ACodigoArticulo: string): Boolean;
begin
  AModelo := Trim(FModeloPendiente);
  ACodigoArticulo := Trim(FArticuloPendiente);
  FModeloPendiente := '';
  FArticuloPendiente := '';
  Result := FResolucionPendiente;
  FResolucionPendiente := False;
end;

function TNucleoBusquedaModeloSesion.DebeRecargarLista(
  const AProveedor: string;
  AListaAbierta: Boolean): Boolean;
begin
  Result := (AProveedor <> FProveedorCargado) or (not AListaAbierta);
end;

procedure TNucleoBusquedaModeloSesion.MarcarListaCargada(
  const AProveedor: string);
begin
  FProveedorCargado := AProveedor;
end;

end.
