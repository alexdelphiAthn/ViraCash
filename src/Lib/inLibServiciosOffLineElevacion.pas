{******************************************************************************}
{                                                                              }
{  Módulo:       inLibServiciosOffLineElevacion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Plan de instalación de servicios off line y su ejecución en una          }
{    instancia elevada: sin elevación el Programador rechaza las tareas S4U.  }
{******************************************************************************}
unit inLibServiciosOffLineElevacion;

interface

uses
  inLibServiciosOffLineIntf;

const
  CONMUTADOR_SERVICIOS_OFF_LINE = 'servicios-off-line';

type
  TOperacionServicioOffLine = record
    Instalar: Boolean;
    Configuracion: TConfiguracionServicioOffLine;
  end;
  TPlanServiciosOffLine = record
    Entorno: TEntornoServiciosOffLine;
    Credencial: TCredencialServiciosOffLine;
    Operaciones: TArray<TOperacionServicioOffLine>;
  end;

procedure AnadirOperacionServiciosOffLine(
  var APlan: TPlanServiciosOffLine;
  AInstalar: Boolean;
  const AConfiguracion: TConfiguracionServicioOffLine);
function AplicarPlanServiciosOffLine(
  const AProgramador: IProgramadorServiciosOffLine;
  const APlan: TPlanServiciosOffLine;
  out AMensajes: TArray<string>): Boolean;
function EjecutarPlanServiciosOffLineElevado(
  const APlan: TPlanServiciosOffLine;
  out AMensajes: TArray<string>;
  out AError: string): Boolean;
procedure ProcesarArranqueServiciosOffLineElevado;

implementation

uses
  Winapi.ShellAPI,
  Winapi.Windows,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  inLibMsgServiciosOffLine,
  inLibProgramadorTareasWindows,
  inLibServiciosOffLine;

function RutaResultadoPlanServicios(const ARutaPlan: string): string;
begin
  Result := ARutaPlan + '.resultado';
end;

function RutaTemporalPlanServicios: string;
var
  Identificador: TGUID;
begin
  CreateGUID(Identificador);
  Result := TPath.Combine(
    TPath.GetTempPath,
    'ViraCash_ServiciosOffLine_' +
    StringReplace(
      StringReplace(GUIDToString(Identificador), '{', '', []),
      '}',
      '',
      []) + '.plan');
end;

procedure AnadirOperacionServiciosOffLine(
  var APlan: TPlanServiciosOffLine;
  AInstalar: Boolean;
  const AConfiguracion: TConfiguracionServicioOffLine);
var
  iUltima: Integer;
begin
  iUltima := Length(APlan.Operaciones);
  SetLength(APlan.Operaciones, iUltima + 1);
  APlan.Operaciones[iUltima].Instalar := AInstalar;
  APlan.Operaciones[iUltima].Configuracion := AConfiguracion;
end;

procedure AnadirMensaje(
  var AMensajes: TArray<string>;
  const AMensaje: string);
var
  iUltimo: Integer;
begin
  iUltimo := Length(AMensajes);
  SetLength(AMensajes, iUltimo + 1);
  AMensajes[iUltimo] := AMensaje;
end;

function AplicarOperacionServiciosOffLine(
  const AProgramador: IProgramadorServiciosOffLine;
  const APlan: TPlanServiciosOffLine;
  const AOperacion: TOperacionServicioOffLine;
  var AMensajes: TArray<string>): Boolean;
var
  Resultado: TResultadoServicioOffLine;
  sNombre: string;
begin
  sNombre := NombreTareaServicioOffLine(
    AOperacion.Configuracion.Servicio);
  Resultado := Default(TResultadoServicioOffLine);
  if AOperacion.Instalar and
     (ValidarServicioOffLine(
        AOperacion.Configuracion,
        APlan.Entorno) <> esoNinguno) then
  begin
    AnadirMensaje(AMensajes, Format(
      SErrorInstalarServicioOffLine,
      [sNombre, DescripcionErrorServicioOffLine(
        ValidarServicioOffLine(
          AOperacion.Configuracion,
          APlan.Entorno))]));
  end
  else if AOperacion.Instalar then
  begin
    Resultado := AProgramador.Instalar(
      AOperacion.Configuracion,
      APlan.Entorno,
      APlan.Credencial);
    if Resultado.Ok then
    begin
      AnadirMensaje(AMensajes, Format(
        SInfoServicioOffLineInstalado,
        [sNombre, HoraTareaServicioOffLine(
          AOperacion.Configuracion)]));
    end
    else
    begin
      AnadirMensaje(AMensajes, Format(
        SErrorInstalarServicioOffLine,
        [sNombre, Resultado.Mensaje]));
    end;
  end
  else
  begin
    Resultado := AProgramador.Desinstalar(
      AOperacion.Configuracion.Servicio,
      APlan.Entorno);
    if Resultado.Ok then
      AnadirMensaje(AMensajes, Format(
        SInfoServicioOffLineQuitado, [sNombre]))
    else
    begin
      AnadirMensaje(AMensajes, Format(
        SErrorQuitarServicioOffLine,
        [sNombre, Resultado.Mensaje]));
    end;
  end;
  Result := Resultado.Ok;
end;

function AplicarPlanServiciosOffLine(
  const AProgramador: IProgramadorServiciosOffLine;
  const APlan: TPlanServiciosOffLine;
  out AMensajes: TArray<string>): Boolean;
var
  iIndice: Integer;
begin
  Result := True;
  AMensajes := nil;
  for iIndice := Low(APlan.Operaciones) to High(APlan.Operaciones) do
  begin
    if not AplicarOperacionServiciosOffLine(
             AProgramador,
             APlan,
             APlan.Operaciones[iIndice],
             AMensajes) then
      Result := False;
  end;
end;

function TextoServicioPlan(AServicio: TServicioOffLine): string;
begin
  if AServicio = soCopiaSeguridad then
    Result := 'copia'
  else
    Result := 'precios';
end;

function ServicioPlanDesdeTexto(const ATexto: string): TServicioOffLine;
begin
  if SameText(ATexto, 'copia') then
    Result := soCopiaSeguridad
  else
    Result := soPreciosMedios;
end;

function TextoPlanServicios(
  AJson: TJSONObject;
  const ANombre: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  if Assigned(AJson) then
  begin
    oValor := AJson.GetValue(ANombre);
    if Assigned(oValor) and not (oValor is TJSONNull) then
      Result := oValor.Value;
  end;
end;

function EnteroPlanServicios(
  AJson: TJSONObject;
  const ANombre: string): Integer;
begin
  Result := StrToIntDef(TextoPlanServicios(AJson, ANombre), 0);
end;

function GuardarPlanServiciosOffLine(
  const ARutaPlan: string;
  const APlan: TPlanServiciosOffLine;
  out AError: string): Boolean;
var
  iIndice: Integer;
  oElemento: TJSONObject;
  oLista: TJSONArray;
  oPlan: TJSONObject;
begin
  Result := False;
  AError := '';
  oPlan := TJSONObject.Create;
  try
    try
      oPlan.AddPair('perfil', APlan.Entorno.PerfilIni);
      oPlan.AddPair('usuario_tarea', APlan.Credencial.Usuario);
      oLista := TJSONArray.Create;
      for iIndice := Low(APlan.Operaciones) to
                     High(APlan.Operaciones) do
      begin
        oElemento := TJSONObject.Create;
        oElemento.AddPair(
          'servicio',
          TextoServicioPlan(
            APlan.Operaciones[iIndice].Configuracion.Servicio));
        oElemento.AddPair(
          'instalar',
          TJSONBool.Create(APlan.Operaciones[iIndice].Instalar));
        oElemento.AddPair(
          'hora',
          IntToStr(APlan.Operaciones[iIndice].Configuracion.Hora));
        oElemento.AddPair(
          'minuto',
          IntToStr(APlan.Operaciones[iIndice].Configuracion.Minuto));
        oElemento.AddPair(
          'carpeta',
          APlan.Operaciones[iIndice].Configuracion.Carpeta);
        oElemento.AddPair(
          'nombre',
          APlan.Operaciones[iIndice].Configuracion.NombreFichero);
        oLista.AddElement(oElemento);
      end;
      oPlan.AddPair('operaciones', oLista);
      TFile.WriteAllText(ARutaPlan, oPlan.ToJSON, TEncoding.UTF8);
      Result := True;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    oPlan.Free;
  end;
end;

// El plan vive en el temporal del usuario, asi que la instancia elevada
// no se fia de el: el ejecutable es siempre el suyo propio y los
// argumentos se reconstruyen a partir del servicio y del perfil.
function CargarPlanServiciosOffLine(
  const ARutaPlan: string;
  out APlan: TPlanServiciosOffLine;
  out AError: string): Boolean;
var
  Configuracion: TConfiguracionServicioOffLine;
  iIndice: Integer;
  oElemento: TJSONObject;
  oJson: TJSONValue;
  oLista: TJSONValue;
  oPlan: TJSONObject;
begin
  Result := False;
  AError := '';
  APlan := Default(TPlanServiciosOffLine);
  try
    oJson := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(ARutaPlan, TEncoding.UTF8));
    try
      if not (oJson is TJSONObject) then
        AError := SErrorPlanServiciosOffLineNoValido
      else
      begin
        oPlan := TJSONObject(oJson);
        APlan.Entorno.RutaEjecutable := ExpandFileName(ParamStr(0));
        APlan.Entorno.PerfilIni := TextoPlanServicios(oPlan, 'perfil');
        // La contrasena nunca viaja en el plan: la instancia elevada
        // registra siempre en modo S4U.
        APlan.Credencial.Usuario := TextoPlanServicios(
          oPlan,
          'usuario_tarea');
        oLista := oPlan.GetValue('operaciones');
        if oLista is TJSONArray then
        begin
          for iIndice := 0 to TJSONArray(oLista).Count - 1 do
          begin
            oElemento := TJSONArray(oLista).Items[iIndice] as
              TJSONObject;
            Configuracion := Default(TConfiguracionServicioOffLine);
            Configuracion.Servicio := ServicioPlanDesdeTexto(
              TextoPlanServicios(oElemento, 'servicio'));
            Configuracion.Hora := EnteroPlanServicios(
              oElemento,
              'hora');
            Configuracion.Minuto := EnteroPlanServicios(
              oElemento,
              'minuto');
            Configuracion.Carpeta := TextoPlanServicios(
              oElemento,
              'carpeta');
            Configuracion.NombreFichero := TextoPlanServicios(
              oElemento,
              'nombre');
            AnadirOperacionServiciosOffLine(
              APlan,
              SameText(
                TextoPlanServicios(oElemento, 'instalar'),
                'true'),
              Configuracion);
          end;
        end;
        Result := (APlan.Credencial.Usuario <> '') and
                  (Length(APlan.Operaciones) > 0) and
                  EsPerfilServiciosOffLineValido(APlan.Entorno.PerfilIni);
        if not Result then
          AError := SErrorPlanServiciosOffLineNoValido;
      end;
    finally
      oJson.Free;
    end;
  except
    on E: Exception do
      AError := E.Message;
  end;
end;

procedure GuardarResultadoPlanServiciosOffLine(
  const ARutaPlan: string;
  AOk: Boolean;
  const AMensajes: TArray<string>;
  const AError: string);
var
  iIndice: Integer;
  oLista: TJSONArray;
  oResultado: TJSONObject;
begin
  oResultado := TJSONObject.Create;
  try
    try
      oResultado.AddPair('ok', TJSONBool.Create(AOk));
      oResultado.AddPair('error', AError);
      oLista := TJSONArray.Create;
      for iIndice := Low(AMensajes) to High(AMensajes) do
        oLista.Add(AMensajes[iIndice]);
      oResultado.AddPair('mensajes', oLista);
      TFile.WriteAllText(
        RutaResultadoPlanServicios(ARutaPlan),
        oResultado.ToJSON,
        TEncoding.UTF8);
    except
      on E: Exception do
        OutputDebugString(PChar(E.Message));
    end;
  finally
    oResultado.Free;
  end;
end;

function LeerResultadoPlanServiciosOffLine(
  const ARutaPlan: string;
  out AMensajes: TArray<string>;
  out AError: string): Boolean;
var
  iIndice: Integer;
  oJson: TJSONValue;
  oLista: TJSONValue;
  oResultado: TJSONObject;
begin
  Result := False;
  AError := '';
  AMensajes := nil;
  if not TFile.Exists(RutaResultadoPlanServicios(ARutaPlan)) then
    AError := SErrorElevacionServiciosOffLineSinRespuesta
  else
  begin
    try
      oJson := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(
          RutaResultadoPlanServicios(ARutaPlan),
          TEncoding.UTF8));
      try
        if not (oJson is TJSONObject) then
          AError := SErrorElevacionServiciosOffLineSinRespuesta
        else
        begin
          oResultado := TJSONObject(oJson);
          Result := oResultado.GetValue('ok') is TJSONTrue;
          AError := TextoPlanServicios(oResultado, 'error');
          oLista := oResultado.GetValue('mensajes');
          if oLista is TJSONArray then
          begin
            for iIndice := 0 to TJSONArray(oLista).Count - 1 do
            begin
              AnadirMensaje(
                AMensajes,
                TJSONArray(oLista).Items[iIndice].Value);
            end;
          end;
        end;
      finally
        oJson.Free;
      end;
    except
      on E: Exception do
        AError := E.Message;
    end;
  end;
end;

function LanzarInstanciaElevadaServicios(
  const ARutaPlan: string;
  out AError: string): Boolean;
var
  iCodigo: DWORD;
  Informacion: TShellExecuteInfo;
  sParametros: string;
  sRutaActual: string;
begin
  Result := False;
  AError := '';
  sRutaActual := ExpandFileName(ParamStr(0));
  sParametros := '/' + CONMUTADOR_SERVICIOS_OFF_LINE + '="' +
    ARutaPlan + '"';
  ZeroMemory(@Informacion, SizeOf(Informacion));
  Informacion.cbSize := SizeOf(Informacion);
  Informacion.fMask := SEE_MASK_NOCLOSEPROCESS;
  Informacion.lpVerb := 'runas';
  Informacion.lpFile := PChar(sRutaActual);
  Informacion.lpParameters := PChar(sParametros);
  Informacion.lpDirectory := PChar(ExtractFilePath(sRutaActual));
  Informacion.nShow := SW_SHOWNORMAL;
  if not ShellExecuteEx(@Informacion) then
  begin
    if GetLastError = ERROR_CANCELLED then
      AError := SErrorElevacionServiciosOffLineRechazada
    else
      AError := SysErrorMessage(GetLastError);
  end
  else
  begin
    WaitForSingleObject(Informacion.hProcess, INFINITE);
    if GetExitCodeProcess(Informacion.hProcess, iCodigo) then
      Result := True
    else
      AError := SysErrorMessage(GetLastError);
    CloseHandle(Informacion.hProcess);
  end;
end;

function EjecutarPlanServiciosOffLineElevado(
  const APlan: TPlanServiciosOffLine;
  out AMensajes: TArray<string>;
  out AError: string): Boolean;
var
  sPlan: string;
begin
  AMensajes := nil;
  sPlan := RutaTemporalPlanServicios;
  Result := GuardarPlanServiciosOffLine(sPlan, APlan, AError);
  if Result then
  begin
    if LanzarInstanciaElevadaServicios(sPlan, AError) then
      Result := LeerResultadoPlanServiciosOffLine(
        sPlan,
        AMensajes,
        AError)
    else
      Result := False;
  end;
  if TFile.Exists(sPlan) then
    DeleteFile(PChar(sPlan));
  if TFile.Exists(RutaResultadoPlanServicios(sPlan)) then
    DeleteFile(PChar(RutaResultadoPlanServicios(sPlan)));
end;

// FindCmdLineSwitch solo se come el separador ':' del valor pegado,
// asi que con '/conmutador=ruta' el '=' llega dentro del valor.
function ValorConmutadorPlan(const AValor: string): string;
begin
  Result := Trim(AValor);
  if (Result <> '') and CharInSet(Result[1], ['=', ':']) then
    Delete(Result, 1, 1);
  Result := Trim(Result);
end;

procedure ProcesarArranqueServiciosOffLineElevado;
var
  aMensajes: TArray<string>;
  bOk: Boolean;
  Plan: TPlanServiciosOffLine;
  sError: string;
  sPlan: string;
begin
  sPlan := '';
  if FindCmdLineSwitch(CONMUTADOR_SERVICIOS_OFF_LINE, sPlan, True) and
     (ValorConmutadorPlan(sPlan) <> '') then
  begin
    sPlan := ValorConmutadorPlan(sPlan);
    aMensajes := nil;
    bOk := CargarPlanServiciosOffLine(sPlan, Plan, sError);
    if bOk then
    begin
      bOk := AplicarPlanServiciosOffLine(
        TProgramadorServiciosOffLineWindows.Create,
        Plan,
        aMensajes);
    end;
    GuardarResultadoPlanServiciosOffLine(
      sPlan,
      bOk,
      aMensajes,
      sError);
    if bOk then
      Halt(0)
    else
      Halt(1);
  end;
end;

end.
