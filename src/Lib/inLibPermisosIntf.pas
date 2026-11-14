{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPermisosIntf                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y estructuras del sistema de permisos de la aplicación.         }
{******************************************************************************}
unit inLibPermisosIntf;

interface

type
  // paExigirConcesion: solo concede una regla 'S' del propio usuario o de
  // su grupo; la regla de 'Todos' y la ausencia de regla deniegan.
  TPermisoAusente = (
    paPermitir,
    paDenegar,
    paExigirConcesion
  );

  TOrigenPermiso = (
    opAdministrador,
    opUsuario,
    opGrupo,
    opTodos,
    opNoDefinido,
    opNoDisponible
  );

  TAccionPermisoMto = (
    apmConsultar,
    apmInsertar,
    apmModificar,
    apmBorrar,
    apmExcel,
    apmImprimir
  );

  TIdentidadPermisos = record
    Usuario        : string;
    Grupo          : string;
    EsAdministrador: Boolean;
    class function Crear(const AUsuario, AGrupo: string;
                         AEsAdministrador: Boolean): TIdentidadPermisos;
                         static;
  end;

  TReglaPermiso = record
    Sujeto   : string;
    Codigo   : string;
    Permitido: Boolean;
    class function Crear(const ASujeto, ACodigo: string;
                         APermitido: Boolean): TReglaPermiso; static;
  end;

  TResultadoPermiso = record
    Codigo   : string;
    Permitido: Boolean;
    Origen   : TOrigenPermiso;
  end;

  IPermisosAplicacion = interface
    ['{DDB43751-6161-495F-B70F-EACE1D1735E3}']
    function GetDisponible: Boolean;
    function Evaluar(const ACodigo: string;
                     APermisoAusente: TPermisoAusente): TResultadoPermiso;
    function TienePermiso(const ACodigo: string;
                          APermisoAusente: TPermisoAusente): Boolean;
    property Disponible: Boolean read GetDisponible;
  end;

  TContextoAutorizacionPantalla = record
  private
    FPermisos: IPermisosAplicacion;
  public
    class function Crear(
      const APermisos: IPermisosAplicacion
    ): TContextoAutorizacionPantalla; static;
    property Permisos: IPermisosAplicacion read FPermisos;
  end;

  IProveedorPermisosAplicacion = interface
    ['{5405FD8F-CE72-47B0-B512-E520B0B8B7AB}']
    function GetPermisos: IPermisosAplicacion;
    property Permisos: IPermisosAplicacion read GetPermisos;
  end;

const
  PERMISO_CAJA_CAMBIAR_FECHA = 'caja.cambiarFecha';
  PERMISO_CAJA_VER_COSTE = 'caja.verCoste';
  PERMISO_CAJA_ABRIR_CAJON = 'caja.abrirCajon';
  // Desbloquear una carga en transito desde la caja del origen: solo
  // el administrador o quien tenga la concesion (FZ-ISSUE-256).
  PERMISO_CAJA_TRANSITO_DESBLOQUEAR = 'caja.transito.desbloquear';
  PERMISO_ARQUEO_VER_RESUMEN = 'arqueo.verResumen';
  PERMISO_ARQUEO_VER_IMPORTES = 'arqueo.verImportes';
  PERMISO_ARTICULOS_ACTIVAR_DESACTIVAR_WEB =
    'articulos.activarDesactivarWeb';
  // Botones de Caja > Buscar / Modificar operaciones (F10). Sin regla se
  // permiten; se siembran para 'Todos' con el script 20260928.
  PERMISO_CAJA_BUSCAR_REIMPRIMIR = 'caja.buscar.reimprimir';
  PERMISO_CAJA_BUSCAR_PREVISUALIZAR = 'caja.buscar.previsualizar';
  PERMISO_CAJA_BUSCAR_EMAIL = 'caja.buscar.email';
  PERMISO_CAJA_BUSCAR_DEVOLVER_ABONAR = 'caja.buscar.devolverAbonar';
  PERMISO_CAJA_BUSCAR_RECTIFICAR = 'caja.buscar.rectificar';
  PERMISO_CAJA_BUSCAR_ANULAR_FISCAL = 'caja.buscar.anularFiscal';
  PERMISO_CAJA_BUSCAR_CONVERTIR_NORMAL = 'caja.buscar.convertirNormal';
  PERMISO_CAJA_BUSCAR_SUBSANAR = 'caja.buscar.subsanar';

  // Pantallas de administración (FZ-ISSUE-028): un usuario que no es
  // administrador solo entra con concesión expresa a su usuario o grupo.
  PERMISOS_ADMINISTRACION: array[0..9] of string = (
    'menu.mnuParmetrosdeEntorno',
    'menu.Usuarios',
    'menu.Grupos',
    'menu.UsuariosPerfiles',
    'menu.Permisos',
    'menu.PermisosTabla',
    'menu.HacerCopiadeSeguridad1',
    'menu.GeneradorProcesos',
    'menu.mnuProcesosAuxiliaresBBDD',
    'menu.mnuCambioCodigoCliente'
  );
  PERMISO_MENU_PARAMETROS_ENTORNO = 'menu.mnuParmetrosdeEntorno';
  // Mantenimientos de administración: entrar (menú) no autoriza a dar de
  // alta, modificar ni borrar; cada acción exige su propia concesión.
  PANTALLAS_ADMINISTRACION: array[0..5] of string = (
    'Usuarios',
    'Grupos',
    'UsuariosPerfiles',
    'Permisos',
    'PermisosTabla',
    'GeneradorProcesos'
  );

function CodigoPermisoMto(const ACall: string;
                           AAccion: TAccionPermisoMto): string;
function EsPermisoAdministracion(const ACodigo: string): Boolean;
// Política de ausencia que corresponde al código: paExigirConcesion para
// las pantallas de administración y paPermitir para el resto.
function PermisoAusenteCodigo(const ACodigo: string): TPermisoAusente;
// Abrir y guardar Parámetros del entorno; la comparten la composición que
// abre la pantalla y el propio formulario al guardar.
function PuedeAbrirParametrosAplicacion(
  const APermisos: IPermisosAplicacion): Boolean;

implementation

uses
  System.SysUtils;

class function TContextoAutorizacionPantalla.Crear(
  const APermisos: IPermisosAplicacion): TContextoAutorizacionPantalla;
begin
  Result.FPermisos := APermisos;
end;

class function TIdentidadPermisos.Crear(
  const AUsuario, AGrupo: string;
  AEsAdministrador: Boolean): TIdentidadPermisos;
begin
  Result.Usuario := Trim(AUsuario);
  Result.Grupo := Trim(AGrupo);
  Result.EsAdministrador := AEsAdministrador;
end;

class function TReglaPermiso.Crear(
  const ASujeto, ACodigo: string;
  APermitido: Boolean): TReglaPermiso;
begin
  Result.Sujeto := Trim(ASujeto);
  Result.Codigo := Trim(ACodigo);
  Result.Permitido := APermitido;
end;

function CodigoPermisoMto(const ACall: string;
                           AAccion: TAccionPermisoMto): string;
const
  SUFIJOS: array[TAccionPermisoMto] of string = (
    'consultar',
    'insertar',
    'modificar',
    'borrar',
    'excel',
    'imprimir'
  );
begin
  Result := Trim(ACall) + '.' + SUFIJOS[AAccion];
end;

function EsPermisoAdministracion(const ACodigo: string): Boolean;
const
  ACCIONES_EDICION: array[0..2] of TAccionPermisoMto = (
    apmInsertar,
    apmModificar,
    apmBorrar
  );
var
  Accion: TAccionPermisoMto;
  sCall: string;
  sCodigo: string;
begin
  Result := False;
  for sCodigo in PERMISOS_ADMINISTRACION do
    if SameText(sCodigo, Trim(ACodigo)) then
      Result := True;
  for sCall in PANTALLAS_ADMINISTRACION do
    for Accion in ACCIONES_EDICION do
      if SameText(CodigoPermisoMto(sCall, Accion), Trim(ACodigo)) then
        Result := True;
end;

function PermisoAusenteCodigo(const ACodigo: string): TPermisoAusente;
begin
  if EsPermisoAdministracion(ACodigo) then
    Result := paExigirConcesion
  else
    Result := paPermitir;
end;

function PuedeAbrirParametrosAplicacion(
  const APermisos: IPermisosAplicacion): Boolean;
begin
  Result := Assigned(APermisos) and
            APermisos.TienePermiso(
              PERMISO_MENU_PARAMETROS_ENTORNO,
              paExigirConcesion);
end;

end.
