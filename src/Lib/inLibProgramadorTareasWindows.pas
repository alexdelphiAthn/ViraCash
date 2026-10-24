{******************************************************************************}
{                                                                              }
{  Módulo:       inLibProgramadorTareasWindows                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Instala, consulta y quita los servicios off line en el Programador de     }
{    tareas de Windows (interfaz de automatización Schedule.Service).          }
{******************************************************************************}
unit inLibProgramadorTareasWindows;

interface

uses
  inLibServiciosOffLineIntf;

type
  TProgramadorServiciosOffLineWindows = class(
    TInterfacedObject,
    IProgramadorServiciosOffLine)
  private
    function ConectarProgramador: OleVariant;
    procedure Trazar(const APaso: string);
    procedure AsegurarCom;
    function ObtenerCarpetaTareas(
      const AProgramador: OleVariant;
      ACrear: Boolean;
      out ACarpeta: OleVariant): Boolean;
    function ObtenerTarea(
      const ACarpeta: OleVariant;
      const ANombre: string;
      out ATarea: OleVariant): Boolean;
    function ProximaEjecucion(const ATarea: OleVariant): string;
  public
    function Consultar(
      AServicio: TServicioOffLine;
      const AEntorno: TEntornoServiciosOffLine
    ): TEstadoServicioOffLine;
    function Instalar(
      const AConfiguracion: TConfiguracionServicioOffLine;
      const AEntorno: TEntornoServiciosOffLine;
      const ACredencial: TCredencialServiciosOffLine
    ): TResultadoServicioOffLine;
    function Desinstalar(
      AServicio: TServicioOffLine;
      const AEntorno: TEntornoServiciosOffLine
    ): TResultadoServicioOffLine;
  end;

function UsuarioWindowsActual: string;
function ProcesoElevado: Boolean;

implementation

uses
  System.SysUtils,
  System.Variants,
  System.Win.ComObj,
  Winapi.ActiveX,
  Winapi.Windows,
  inLibServiciosOffLine;

const
  PROGID_PROGRAMADOR_TAREAS = 'Schedule.Service';
  CLSID_PROGRAMADOR_TAREAS = '{0F87369F-A4E5-4CFC-BD3E-73E6154572DD}';
  TAREA_CREAR_O_ACTUALIZAR = 6;
  TAREA_ACCESO_CONTRASENA = 1;
  TAREA_ACCESO_S4U = 2;

function UsuarioWindowsActual: string;
var
  sDominio: string;
  sUsuario: string;
begin
  sDominio := Trim(GetEnvironmentVariable('USERDOMAIN'));
  sUsuario := Trim(GetEnvironmentVariable('USERNAME'));
  if sDominio = '' then
    sDominio := Trim(GetEnvironmentVariable('COMPUTERNAME'));
  if (sDominio <> '') and (sUsuario <> '') then
    Result := sDominio + '\' + sUsuario
  else
    Result := sUsuario;
end;

// El codigo de error de COM hace falta para diagnosticar: el texto
// del sistema por si solo no dice cual fue.
function MensajeErrorCom(AExcepcion: Exception): string;
begin
  Result := AExcepcion.Message;
  if AExcepcion is EOleSysError then
  begin
    Result := Result + Format(
      ' (0x%.8x)',
      [Cardinal(EOleSysError(AExcepcion).ErrorCode)]);
  end;
end;

function TProgramadorServiciosOffLineWindows.ObtenerCarpetaTareas(
  const AProgramador: OleVariant;
  ACrear: Boolean;
  out ACarpeta: OleVariant): Boolean;
begin
  Result := True;
  try
    Trazar('GetFolder');
    ACarpeta := AProgramador.GetFolder(
      '\' + CARPETA_TAREAS_OFF_LINE);
  except
    on EOleSysError do
    begin
      if ACrear then
      begin
        ACarpeta := AProgramador.GetFolder('\').CreateFolder(
          CARPETA_TAREAS_OFF_LINE);
      end
      else
      begin
        ACarpeta := Unassigned;
        Result := False;
      end;
    end;
  end;
end;

function TProgramadorServiciosOffLineWindows.ObtenerTarea(
  const ACarpeta: OleVariant;
  const ANombre: string;
  out ATarea: OleVariant): Boolean;
begin
  Result := True;
  try
    Trazar('GetTask ' + ANombre);
    ATarea := ACarpeta.GetTask(ANombre);
  except
    on EOleSysError do
    begin
      ATarea := Unassigned;
      Result := False;
    end;
  end;
end;

function TProgramadorServiciosOffLineWindows.ProximaEjecucion(
  const ATarea: OleVariant): string;
var
  dtProxima: TDateTime;
begin
  Result := '';
  try
    dtProxima := ATarea.NextRunTime;
    if dtProxima > 0 then
      Result := DateTimeToStr(dtProxima);
  except
    on EOleSysError do
      Result := '';
  end;
end;

// Las trazas salen por OutputDebugString: aparecen en el panel
// Events del IDE y en cualquier visor de depuracion, y no molestan
// en produccion. Sirven para saber en que llamada de COM falla una
// instalacion concreta.
procedure TProgramadorServiciosOffLineWindows.Trazar(
  const APaso: string);
begin
  OutputDebugString(PChar('ServiciosOffLine: ' + APaso));
end;

// El hilo que abre la pantalla no siempre trae COM inicializado.
// No se llama a CoUninitialize: despues de despachar por variantes
// deja la automatizacion en un estado que revienta al finalizar el
// proceso, y en el hilo de la VCL COM debe seguir vivo de todos
// modos mientras dure la aplicacion.
procedure TProgramadorServiciosOffLineWindows.AsegurarCom;
var
  hResultado: HRESULT;
begin
  hResultado := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  Trazar(Format('CoInitializeEx = 0x%.8x', [Cardinal(hResultado)]));
end;

// Sin elevacion, el Programador rechaza registrar una tarea S4U
// (la que corre sin sesion y sin contrasena).
function ProcesoElevado: Boolean;
var
  Elevacion: TOKEN_ELEVATION;
  hToken: THandle;
  iDevueltos: DWORD;
begin
  Result := False;
  hToken := 0;
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
  begin
    try
      iDevueltos := 0;
      if GetTokenInformation(
           hToken,
           TokenElevation,
           @Elevacion,
           SizeOf(Elevacion),
           iDevueltos) then
        Result := Elevacion.TokenIsElevated <> 0;
    finally
      CloseHandle(hToken);
    end;
  end;
end;

// Hay equipos donde el ProgID no resuelve y COM responde 'clase no
// registrada': se reintenta con el CLSID del Programador de tareas.
function TProgramadorServiciosOffLineWindows.ConectarProgramador:
  OleVariant;
begin
  try
    Trazar('CreateOleObject por ProgID');
    Result := CreateOleObject(PROGID_PROGRAMADOR_TAREAS);
  except
    on E: EOleSysError do
    begin
      Trazar('ProgID fallido: ' + MensajeErrorCom(E));
      Trazar('CreateComObject por CLSID');
      Result := CreateComObject(
        StringToGUID(CLSID_PROGRAMADOR_TAREAS)) as IDispatch;
    end;
  end;
  Trazar('Connect');
  Result.Connect;
  Trazar('Connect correcto');
end;

function TProgramadorServiciosOffLineWindows.Consultar(
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): TEstadoServicioOffLine;
var
  oCarpeta: OleVariant;
  oProgramador: OleVariant;
  oTarea: OleVariant;
begin
  Result := Default(TEstadoServicioOffLine);
  Result.Configuracion := ConfiguracionPredeterminadaServicioOffLine(
    AServicio,
    AEntorno);
  try
    AsegurarCom;
    try
      oProgramador := ConectarProgramador;
      if ObtenerCarpetaTareas(oProgramador, False, oCarpeta) and
         ObtenerTarea(
           oCarpeta,
           NombreTareaServicioOffLine(AServicio),
           oTarea) then
      begin
        Result := InterpretarXmlTareaServicioOffLine(
          oTarea.Xml,
          AServicio,
          AEntorno);
        Result.Habilitada := oTarea.Enabled;
        Result.ProximaEjecucion := ProximaEjecucion(oTarea);
      end;
    finally
      // Las variantes sueltan su interfaz al limpiarse.
      oTarea := Unassigned;
      oCarpeta := Unassigned;
      oProgramador := Unassigned;
    end;
  except
    on E: Exception do
    begin
      Result.Error := MensajeErrorCom(E);
      Trazar('Consultar ha fallado: ' + Result.Error);
    end;
  end;
end;

function TProgramadorServiciosOffLineWindows.Instalar(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine;
  const ACredencial: TCredencialServiciosOffLine
): TResultadoServicioOffLine;
var
  oCarpeta: OleVariant;
  oDefinicion: OleVariant;
  oProgramador: OleVariant;
  oTareaRegistrada: OleVariant;
begin
  Result := Default(TResultadoServicioOffLine);
  try
    AsegurarCom;
    try
      oProgramador := ConectarProgramador;
      ObtenerCarpetaTareas(oProgramador, True, oCarpeta);
      oDefinicion := oProgramador.NewTask(0);
      oDefinicion.XmlText := ConstruirXmlTareaServicioOffLine(
        AConfiguracion,
        AEntorno,
        ACredencial,
        Now);
      // El registro devuelve la tarea creada: se guarda en una
      // variante propia para soltarla al salir.
      // Ojo: el despacho por variantes pasa las VARIABLES por
      // referencia y el Programador responde 'los tipos no
      // coinciden'; por eso el modo va como constante en cada rama.
      if ModoAccesoServiciosOffLine(ACredencial) = masContrasena then
      begin
        oTareaRegistrada := oCarpeta.RegisterTaskDefinition(
          NombreTareaServicioOffLine(AConfiguracion.Servicio),
          oDefinicion,
          TAREA_CREAR_O_ACTUALIZAR,
          ACredencial.Usuario,
          ACredencial.Contrasena,
          TAREA_ACCESO_CONTRASENA,
          Null);
      end
      else
      begin
        oTareaRegistrada := oCarpeta.RegisterTaskDefinition(
          NombreTareaServicioOffLine(AConfiguracion.Servicio),
          oDefinicion,
          TAREA_CREAR_O_ACTUALIZAR,
          ACredencial.Usuario,
          Null,
          TAREA_ACCESO_S4U,
          Null);
      end;
      Result.Ok := True;
    finally
      oTareaRegistrada := Unassigned;
      oDefinicion := Unassigned;
      oCarpeta := Unassigned;
      oProgramador := Unassigned;
    end;
  except
    on E: Exception do
    begin
      Result.Mensaje := MensajeErrorCom(E);
      Trazar('Operacion fallida: ' + Result.Mensaje);
    end;
  end;
end;

function TProgramadorServiciosOffLineWindows.Desinstalar(
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): TResultadoServicioOffLine;
var
  oCarpeta: OleVariant;
  oProgramador: OleVariant;
  oTarea: OleVariant;
begin
  Result := Default(TResultadoServicioOffLine);
  try
    AsegurarCom;
    try
      oProgramador := ConectarProgramador;
      if ObtenerCarpetaTareas(oProgramador, False, oCarpeta) and
         ObtenerTarea(
           oCarpeta,
           NombreTareaServicioOffLine(AServicio),
           oTarea) then
      begin
        oCarpeta.DeleteTask(
          NombreTareaServicioOffLine(AServicio),
          0);
      end;
      Result.Ok := True;
    finally
      oTarea := Unassigned;
      oCarpeta := Unassigned;
      oProgramador := Unassigned;
    end;
  except
    on E: Exception do
    begin
      Result.Mensaje := MensajeErrorCom(E);
      Trazar('Operacion fallida: ' + Result.Mensaje);
    end;
  end;
end;

end.
