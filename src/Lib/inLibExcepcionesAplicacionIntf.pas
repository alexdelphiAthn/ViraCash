{******************************************************************************}
{                                                                              }
{  Módulo:       inLibExcepcionesAplicacionIntf                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato y reglas puras de gestión global de excepciones.                 }
{******************************************************************************}
unit inLibExcepcionesAplicacionIntf;

interface

uses
  System.SysUtils,
  inLibContextoSesionIntf,
  inLibEnvioErroresIntf;

type
  TNivelEstadoVistaErrorAplicacion = (
    nevaInformacion,
    nevaCorrecto,
    nevaError);

  TAccionesVistaErrorAplicacion = record
    ActivarLog: TProc;
    CambiarCopiaSeguridad: TProc;
    CopiarDetalle: TProc;
    EnviarError: TProc;
    SalirAplicacion: TProc;
  end;

  TConfiguracionVistaErrorAplicacion = record
    Titulo: string;
    EtiquetaEmail: string;
    EtiquetaTelefono: string;
    EtiquetaDescripcion: string;
    TextoCerrar: string;
    TextoSalirAplicacion: string;
    TextoCopiar: string;
    TextoEnviar: string;
    TextoActivarLog: string;
    TextoEnviarCopia: string;
    PuedeEnviar: Boolean;
    Acciones: TAccionesVistaErrorAplicacion;
  end;

  TEstadoVistaErrorAplicacion = record
    Evidencias: string;
    EstadoLog: string;
    NivelEstado: TNivelEstadoVistaErrorAplicacion;
    PuedeEnviar: Boolean;
    ActivarLogVisible: Boolean;
    ActivarLogHabilitado: Boolean;
  end;

  IVistaErrorAplicacion = interface
    ['{45BB3FB7-298A-4D15-BA52-A8CF53891E89}']
    procedure Configurar(
      const AConfiguracion: TConfiguracionVistaErrorAplicacion);
    procedure Mostrar;
    procedure EstablecerDetalle(const ATexto: string);
    procedure InsertarDetalle(const ATexto: string);
    function TextoDetalle: string;
    function Email: string;
    function Telefono: string;
    function Descripcion: string;
    function EnviarCopiaSeguridad: Boolean;
    procedure AplicarEstado(
      const AEstado: TEstadoVistaErrorAplicacion);
  end;

  IPresentacionExcepcionesAplicacion = interface
    ['{8FD42A41-8514-4CB2-B576-AF4D443484B4}']
    function CrearVistaError: IVistaErrorAplicacion;
    procedure MostrarMensaje(const ATexto: string);
  end;

  IGestorExcepcionesAplicacion = interface
    ['{6A758B40-A4C8-43A0-B006-D59744479228}']
    procedure Gestionar(
      Sender: TObject;
      E: Exception);
    procedure AsignarServicioEnvioErrores(
      const AServicio: IServicioEnvioErrores);
  end;

function EsRuidoEditorInplace(
  E: Exception): Boolean;
function EsValidacionEditorEsperada(
  E: Exception): Boolean;
function EsValidacionAplicacionEsperada(E: Exception): Boolean;
function ConstruirDetalleExcepcionAplicacion(
  Sender: TObject;
  E: Exception;
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion;
  const ANombreAplicacion, AVersion, AEquipo: string;
  AFechaHora: TDateTime;
  ADireccion: Pointer): string;

implementation

uses
  System.Classes,
  cxEdit,
  inLibErroresBBDD;

function EsRuidoEditorInplace(
  E: Exception): Boolean;
begin
  Result := Assigned(E) and
    (E is EInvalidOperation) and
    (Pos(
      'no tiene ventana principal',
      E.Message) > 0);
end;

function EsValidacionAplicacionEsperada(E: Exception): Boolean;
begin
  Result := EsValidacionEditorEsperada(E) or (E is EValidacionBBDD);
end;

function EsValidacionEditorEsperada(
  E: Exception): Boolean;
begin
  Result := Assigned(E) and
    (E is EcxEditValidationError);
end;

function ConstruirDetalleExcepcionAplicacion(
  Sender: TObject;
  E: Exception;
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion;
  const ANombreAplicacion, AVersion, AEquipo: string;
  AFechaHora: TDateTime;
  ADireccion: Pointer): string;
var
  ClaseSender: string;
  NombreSender: string;
  ExcepcionInterna: Exception;
  Nivel: Integer;
begin
  if Assigned(Sender) then
  begin
    ClaseSender := Sender.ClassName;
    if (Sender is TComponent) and
       (TComponent(Sender).Name <> '') then
    begin
      NombreSender := TComponent(Sender).Name;
    end
    else
    begin
      NombreSender := '(sin nombre)';
    end;
  end
  else
  begin
    ClaseSender := '(nil)';
    NombreSender := '(nil)';
  end;
  Result :=
    '=== Detalle del error ===' + sLineBreak +
    'Aplicación   : ' + ANombreAplicacion + ' ' +
      AVersion + sLineBreak +
    'Fecha / hora : ' +
      FormatDateTime(
        'yyyy-mm-dd hh:nn:ss.zzz',
        AFechaHora) + sLineBreak +
    'Usuario      : ' + AIdentidad.Usuario + ' (' +
      AIdentidad.Grupo + ')' + sLineBreak +
    'Empresa      : ' + AUbicacion.Empresa + sLineBreak +
    'Almacén/Caja : ' + AUbicacion.Almacen + ' / ' +
      AUbicacion.Caja + sLineBreak +
    'Equipo       : ' + AEquipo + sLineBreak +
    sLineBreak +
    '--- Excepción ---' + sLineBreak +
    'Clase        : ' + E.ClassName + sLineBreak +
    'Mensaje      : ' + E.Message + sLineBreak +
    'Dirección    : $' +
      IntToHex(
        NativeUInt(ADireccion),
        SizeOf(Pointer) * 2) + sLineBreak +
    sLineBreak +
    '--- Sender ---' + sLineBreak +
    'Clase        : ' + ClaseSender + sLineBreak +
    'Nombre       : ' + NombreSender + sLineBreak;
  if E.StackTrace <> '' then
  begin
    Result := Result + sLineBreak +
      '--- Stack ---' + sLineBreak +
      E.StackTrace + sLineBreak;
  end;
  ExcepcionInterna := E.InnerException;
  Nivel := 1;
  while Assigned(ExcepcionInterna) and
        (Nivel <= 5) do
  begin
    Result := Result + sLineBreak +
      Format(
        '--- Inner exception #%d ---',
        [Nivel]) + sLineBreak +
      'Clase   : ' +
        ExcepcionInterna.ClassName + sLineBreak +
      'Mensaje : ' +
        ExcepcionInterna.Message + sLineBreak;
    if ExcepcionInterna.StackTrace <> '' then
    begin
      Result := Result +
        'Stack   :' + sLineBreak +
        ExcepcionInterna.StackTrace +
        sLineBreak;
    end;
    ExcepcionInterna :=
      ExcepcionInterna.InnerException;
    Inc(Nivel);
  end;
end;

end.
