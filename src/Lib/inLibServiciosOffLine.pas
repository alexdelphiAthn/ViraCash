{******************************************************************************}
{                                                                              }
{  Módulo:       inLibServiciosOffLine                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Nombres, línea de comandos y XML de las tareas de los servicios off      }
{    line. Lógica pura: no habla con el Programador de tareas de Windows.     }
{******************************************************************************}
unit inLibServiciosOffLine;

interface

uses
  inLibServiciosOffLineIntf;

const
  CARPETA_TAREAS_OFF_LINE = 'ViraCash';
  NOMBRE_TAREA_COPIA_OFF_LINE = 'Copia de seguridad';
  NOMBRE_TAREA_PRECIOS_OFF_LINE = 'Precios medios';
  EXTENSION_COPIA_OFF_LINE = '.crypt';
  NOMBRE_COPIA_OFF_LINE_PREDETERMINADO = 'copia_DIASEMANA.crypt';
  HORA_COPIA_OFF_LINE_PREDETERMINADA = 3;
  MINUTO_COPIA_OFF_LINE_PREDETERMINADO = 0;
  HORA_PRECIOS_OFF_LINE_PREDETERMINADA = 23;
  MINUTO_PRECIOS_OFF_LINE_PREDETERMINADO = 30;

type
  TErrorServicioOffLine = (
    esoNinguno,
    esoPerfil,
    esoEjecutable,
    esoCarpeta,
    esoNombre,
    esoExtension,
    esoRuta,
    esoHora
  );

function PerfilIniServiciosOffLine(
  const AEjecutable, AParametro: string): string;
function EsPerfilServiciosOffLineValido(
  const APerfil: string): Boolean;
function NombreTareaServicioOffLine(
  AServicio: TServicioOffLine): string;
function RutaTareaServicioOffLine(
  AServicio: TServicioOffLine): string;
function RutaCopiaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine): string;
function ArgumentosServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): string;
function SentenciaServicioOffLine(
  const AEjecutable, AArgumentos: string): string;
function ValidarServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): TErrorServicioOffLine;
function DescripcionErrorServicioOffLine(
  AError: TErrorServicioOffLine): string;
function ConfiguracionPredeterminadaServicioOffLine(
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine
): TConfiguracionServicioOffLine;
function ModoAccesoServiciosOffLine(
  const ACredencial: TCredencialServiciosOffLine
): TModoAccesoServicioOffLine;
function ConstruirXmlTareaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine;
  const ACredencial: TCredencialServiciosOffLine;
  AInstante: TDateTime): string;
function InterpretarXmlTareaServicioOffLine(
  const AXml: string;
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): TEstadoServicioOffLine;
function HoraTareaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine): string;

implementation

uses
  System.StrUtils,
  System.SysUtils,
  inLibComandoCopiaSeguridad,
  inLibLineaComandos,
  inLibMsgServiciosOffLine;

const
  CONMUTADOR_COPIA_OFF_LINE = '/copiaseguridad';
  CONMUTADOR_PRECIOS_OFF_LINE = '/recalcular_mov';
  LOGON_CONTRASENA_OFF_LINE = 'Password';
  LOGON_S4U_OFF_LINE = 'S4U';
  LOGON_SESION_OFF_LINE = 'InteractiveToken';
  SALTO_XML = #13#10;

function PerfilIniServiciosOffLine(
  const AEjecutable, AParametro: string): string;
begin
  if EsParametroPerfilValido(AParametro) then
    Result := Trim(AParametro)
  else
    Result := ChangeFileExt(ExtractFileName(AEjecutable), '.ini');
end;

function EsPerfilServiciosOffLineValido(
  const APerfil: string): Boolean;
begin
  Result := EsParametroPerfilValido(APerfil);
end;

function NombreTareaServicioOffLine(
  AServicio: TServicioOffLine): string;
begin
  if AServicio = soCopiaSeguridad then
    Result := NOMBRE_TAREA_COPIA_OFF_LINE
  else
    Result := NOMBRE_TAREA_PRECIOS_OFF_LINE;
end;

function RutaTareaServicioOffLine(
  AServicio: TServicioOffLine): string;
begin
  Result := '\' + CARPETA_TAREAS_OFF_LINE + '\' +
    NombreTareaServicioOffLine(AServicio);
end;

function RutaCopiaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine): string;
begin
  Result := Trim(AConfiguracion.Carpeta);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
  Result := Result + Trim(AConfiguracion.NombreFichero);
end;

function ArgumentosServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): string;
begin
  Result := AEntorno.PerfilIni + ' ';
  if AConfiguracion.Servicio = soCopiaSeguridad then
  begin
    Result := Result + CONMUTADOR_COPIA_OFF_LINE + ' "' +
      RutaCopiaServicioOffLine(AConfiguracion) + '"';
  end
  else
    Result := Result + CONMUTADOR_PRECIOS_OFF_LINE;
end;

function SentenciaServicioOffLine(
  const AEjecutable, AArgumentos: string): string;
begin
  Result := '"' + AEjecutable + '" ' + AArgumentos;
end;

function HoraTareaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine): string;
begin
  Result := Format(
    '%.2d:%.2d',
    [AConfiguracion.Hora, AConfiguracion.Minuto]);
end;

function ValidarServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): TErrorServicioOffLine;
var
  sNombre: string;
  sRuta: string;
begin
  Result := esoNinguno;
  if Trim(AEntorno.PerfilIni) = '' then
    Result := esoPerfil
  else if Trim(AEntorno.RutaEjecutable) = '' then
    Result := esoEjecutable
  else if (AConfiguracion.Hora < 0) or (AConfiguracion.Hora > 23) or
          (AConfiguracion.Minuto < 0) or (AConfiguracion.Minuto > 59) then
    Result := esoHora
  else if AConfiguracion.Servicio = soCopiaSeguridad then
  begin
    sNombre := Trim(AConfiguracion.NombreFichero);
    sRuta := ResolverPlantillaCopiaSeguridad(
      RutaCopiaServicioOffLine(AConfiguracion),
      Now);
    if Trim(AConfiguracion.Carpeta) = '' then
      Result := esoCarpeta
    else if sNombre = '' then
      Result := esoNombre
    else if not SameText(
                 ExtractFileExt(sNombre),
                 EXTENSION_COPIA_OFF_LINE) then
      Result := esoExtension
    else
    begin
      case ValidarRutaDestinoCopia(sRuta) of
        eccsNinguno:
          Result := esoNinguno;
        eccsExtension:
          Result := esoExtension;
      else
        Result := esoRuta;
      end;
    end;
  end;
end;

function DescripcionErrorServicioOffLine(
  AError: TErrorServicioOffLine): string;
begin
  case AError of
    esoPerfil:
      Result := SErrorPerfilServiciosOffLine;
    esoEjecutable:
      Result := SErrorEjecutableServiciosOffLine;
    esoCarpeta:
      Result := SErrorCarpetaServiciosOffLine;
    esoNombre:
      Result := SErrorNombreServiciosOffLine;
    esoExtension:
      Result := SErrorExtensionServiciosOffLine;
    esoRuta:
      Result := SErrorRutaServiciosOffLine;
    esoHora:
      Result := SErrorHoraServiciosOffLine;
  else
    Result := '';
  end;
end;

function ConfiguracionPredeterminadaServicioOffLine(
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine
): TConfiguracionServicioOffLine;
begin
  Result := Default(TConfiguracionServicioOffLine);
  Result.Servicio := AServicio;
  if AServicio = soCopiaSeguridad then
  begin
    Result.Hora := HORA_COPIA_OFF_LINE_PREDETERMINADA;
    Result.Minuto := MINUTO_COPIA_OFF_LINE_PREDETERMINADO;
    Result.Carpeta := ExcludeTrailingPathDelimiter(
      Trim(AEntorno.CarpetaCopiasPredeterminada));
    Result.NombreFichero := NOMBRE_COPIA_OFF_LINE_PREDETERMINADO;
  end
  else
  begin
    Result.Hora := HORA_PRECIOS_OFF_LINE_PREDETERMINADA;
    Result.Minuto := MINUTO_PRECIOS_OFF_LINE_PREDETERMINADO;
  end;
end;

function ModoAccesoServiciosOffLine(
  const ACredencial: TCredencialServiciosOffLine
): TModoAccesoServicioOffLine;
begin
  if Trim(ACredencial.Contrasena) <> '' then
    Result := masContrasena
  else
    Result := masS4U;
end;

function TextoLogonTareaServicioOffLine(
  AModo: TModoAccesoServicioOffLine): string;
begin
  if AModo = masContrasena then
    Result := LOGON_CONTRASENA_OFF_LINE
  else
    Result := LOGON_S4U_OFF_LINE;
end;

function EscaparTextoXml(const ATexto: string): string;
begin
  Result := StringReplace(ATexto, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function DesescaparTextoXml(const ATexto: string): string;
begin
  Result := StringReplace(ATexto, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
end;

function DescripcionTareaServicioOffLine(
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): string;
begin
  if AServicio = soCopiaSeguridad then
  begin
    Result := Format(
      SDescripcionTareaCopiaServiciosOffLine,
      [AEntorno.PerfilIni]);
  end
  else
  begin
    Result := Format(
      SDescripcionTareaPreciosServiciosOffLine,
      [AEntorno.PerfilIni]);
  end;
end;

function MarcaInicioTareaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  AInstante: TDateTime): string;
var
  iAnio: Word;
  iDia: Word;
  iMes: Word;
begin
  DecodeDate(AInstante, iAnio, iMes, iDia);
  Result := Format(
    '%.4d-%.2d-%.2dT%.2d:%.2d:00',
    [iAnio, iMes, iDia, AConfiguracion.Hora, AConfiguracion.Minuto]);
end;

function ConstruirXmlTareaServicioOffLine(
  const AConfiguracion: TConfiguracionServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine;
  const ACredencial: TCredencialServiciosOffLine;
  AInstante: TDateTime): string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-16"?>' + SALTO_XML +
    '<Task version="1.2" xmlns="http://schemas.microsoft.com/windows' +
    '/2004/02/mit/task">' + SALTO_XML +
    '  <RegistrationInfo>' + SALTO_XML +
    '    <Author>ViraCash</Author>' + SALTO_XML +
    '    <Description>' + EscaparTextoXml(
      DescripcionTareaServicioOffLine(
        AConfiguracion.Servicio,
        AEntorno)) + '</Description>' + SALTO_XML +
    '  </RegistrationInfo>' + SALTO_XML +
    '  <Triggers>' + SALTO_XML +
    '    <CalendarTrigger>' + SALTO_XML +
    '      <StartBoundary>' + MarcaInicioTareaServicioOffLine(
      AConfiguracion,
      AInstante) + '</StartBoundary>' + SALTO_XML +
    '      <Enabled>true</Enabled>' + SALTO_XML +
    '      <ScheduleByDay>' + SALTO_XML +
    '        <DaysInterval>1</DaysInterval>' + SALTO_XML +
    '      </ScheduleByDay>' + SALTO_XML +
    '    </CalendarTrigger>' + SALTO_XML +
    '  </Triggers>' + SALTO_XML +
    '  <Principals>' + SALTO_XML +
    '    <Principal id="Author">' + SALTO_XML +
    '      <UserId>' + EscaparTextoXml(ACredencial.Usuario) +
    '</UserId>' + SALTO_XML +
    '      <LogonType>' + TextoLogonTareaServicioOffLine(
      ModoAccesoServiciosOffLine(ACredencial)) +
    '</LogonType>' + SALTO_XML +
    '      <RunLevel>LeastPrivilege</RunLevel>' + SALTO_XML +
    '    </Principal>' + SALTO_XML +
    '  </Principals>' + SALTO_XML +
    '  <Settings>' + SALTO_XML +
    '    <MultipleInstancesPolicy>IgnoreNew' +
    '</MultipleInstancesPolicy>' + SALTO_XML +
    '    <DisallowStartIfOnBatteries>false' +
    '</DisallowStartIfOnBatteries>' + SALTO_XML +
    '    <StopIfGoingOnBatteries>false' +
    '</StopIfGoingOnBatteries>' + SALTO_XML +
    '    <AllowHardTerminate>true</AllowHardTerminate>' + SALTO_XML +
    '    <StartWhenAvailable>true</StartWhenAvailable>' + SALTO_XML +
    '    <RunOnlyIfNetworkAvailable>false' +
    '</RunOnlyIfNetworkAvailable>' + SALTO_XML +
    '    <IdleSettings>' + SALTO_XML +
    '      <StopOnIdleEnd>false</StopOnIdleEnd>' + SALTO_XML +
    '      <RestartOnIdle>false</RestartOnIdle>' + SALTO_XML +
    '    </IdleSettings>' + SALTO_XML +
    '    <AllowStartOnDemand>true</AllowStartOnDemand>' + SALTO_XML +
    '    <Enabled>true</Enabled>' + SALTO_XML +
    '    <Hidden>false</Hidden>' + SALTO_XML +
    '    <RunOnlyIfIdle>false</RunOnlyIfIdle>' + SALTO_XML +
    '    <WakeToRun>false</WakeToRun>' + SALTO_XML +
    '    <ExecutionTimeLimit>PT4H</ExecutionTimeLimit>' + SALTO_XML +
    '    <Priority>7</Priority>' + SALTO_XML +
    '  </Settings>' + SALTO_XML +
    '  <Actions Context="Author">' + SALTO_XML +
    '    <Exec>' + SALTO_XML +
    '      <Command>' + EscaparTextoXml(AEntorno.RutaEjecutable) +
    '</Command>' + SALTO_XML +
    '      <Arguments>' + EscaparTextoXml(
      ArgumentosServicioOffLine(AConfiguracion, AEntorno)) +
    '</Arguments>' + SALTO_XML +
    '      <WorkingDirectory>' + EscaparTextoXml(
      ExcludeTrailingPathDelimiter(
        ExtractFilePath(AEntorno.RutaEjecutable))) +
    '</WorkingDirectory>' + SALTO_XML +
    '    </Exec>' + SALTO_XML +
    '  </Actions>' + SALTO_XML +
    '</Task>' + SALTO_XML;
end;

function ValorElementoXml(
  const AXml, ANombre: string): string;
var
  iFin: Integer;
  iInicio: Integer;
  sCierre: string;
begin
  Result := '';
  sCierre := '</' + ANombre + '>';
  iInicio := Pos('<' + ANombre + '>', AXml);
  if iInicio > 0 then
  begin
    Inc(iInicio, Length(ANombre) + 2);
    iFin := PosEx(sCierre, AXml, iInicio);
    if iFin > iInicio then
      Result := DesescaparTextoXml(
        Copy(AXml, iInicio, iFin - iInicio));
  end;
end;

procedure InterpretarHoraTareaServicioOffLine(
  const AMarca: string;
  var AConfiguracion: TConfiguracionServicioOffLine);
var
  iHora: Integer;
  iMinuto: Integer;
begin
  if (Length(AMarca) >= 16) and
     TryStrToInt(Copy(AMarca, 12, 2), iHora) and
     TryStrToInt(Copy(AMarca, 15, 2), iMinuto) and
     (iHora >= 0) and (iHora <= 23) and
     (iMinuto >= 0) and (iMinuto <= 59) then
  begin
    AConfiguracion.Hora := iHora;
    AConfiguracion.Minuto := iMinuto;
  end;
end;

procedure InterpretarRutaCopiaServicioOffLine(
  const AArgumentos: string;
  var AConfiguracion: TConfiguracionServicioOffLine);
var
  iFin: Integer;
  iInicio: Integer;
  sRuta: string;
begin
  iInicio := Pos('"', AArgumentos);
  iFin := 0;
  if iInicio > 0 then
    iFin := PosEx('"', AArgumentos, iInicio + 1);
  if iFin > iInicio then
  begin
    sRuta := Copy(AArgumentos, iInicio + 1, iFin - iInicio - 1);
    AConfiguracion.Carpeta := ExcludeTrailingPathDelimiter(
      ExtractFilePath(sRuta));
    AConfiguracion.NombreFichero := ExtractFileName(sRuta);
  end;
end;

function InterpretarXmlTareaServicioOffLine(
  const AXml: string;
  AServicio: TServicioOffLine;
  const AEntorno: TEntornoServiciosOffLine): TEstadoServicioOffLine;
var
  sArgumentos: string;
begin
  Result := Default(TEstadoServicioOffLine);
  Result.Existe := True;
  Result.Habilitada := True;
  Result.Configuracion := ConfiguracionPredeterminadaServicioOffLine(
    AServicio,
    AEntorno);
  Result.Ejecutable := ValorElementoXml(AXml, 'Command');
  Result.Cuenta := ValorElementoXml(AXml, 'UserId');
  Result.RequiereSesionIniciada := SameText(
    ValorElementoXml(AXml, 'LogonType'),
    LOGON_SESION_OFF_LINE);
  sArgumentos := ValorElementoXml(AXml, 'Arguments');
  Result.Sentencia := SentenciaServicioOffLine(
    Result.Ejecutable,
    sArgumentos);
  Result.EsDeEstaInstalacion := SameText(
    Trim(Result.Ejecutable),
    Trim(AEntorno.RutaEjecutable));
  InterpretarHoraTareaServicioOffLine(
    ValorElementoXml(AXml, 'StartBoundary'),
    Result.Configuracion);
  if AServicio = soCopiaSeguridad then
  begin
    InterpretarRutaCopiaServicioOffLine(
      sArgumentos,
      Result.Configuracion);
  end;
end;

end.
