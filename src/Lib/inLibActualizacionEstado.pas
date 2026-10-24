{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionEstado                                      }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Guarda junto al ejecutable qué actualización se aplicó, qué scripts       }
{    quedan pendientes y con qué se puede revertir.                            }
{******************************************************************************}
unit inLibActualizacionEstado;

interface

const
  cEstadoActualizacionPendiente = 'PENDIENTE_SCRIPTS';
  cEstadoActualizacionCompletada = 'COMPLETADA';
  cEstadoActualizacionRevertida = 'REVERTIDA';
  cResultadoScriptActualizacionOk = 'OK';
  cResultadoScriptActualizacionError = 'ERROR';

type
  TEjecutableActualizado = record
    Ruta: string;
    RutaAnterior: string;
    // Huella publicada del contenido que debería tener el ejecutable.
    Sha256: string;
  end;

  TScriptAplicadoActualizacion = record
    Nombre: string;
    Orden: Integer;
    Resultado: string;
    Detalle: string;
    RutaRollback: string;
  end;

  TScriptPendienteActualizacion = record
    Nombre: string;
    Orden: Integer;
    Ruta: string;
    RutaRollback: string;
  end;

  TEstadoActualizacion = record
    Existe: Boolean;
    Estado: string;
    VersionOrigen: string;
    VersionDestino: string;
    Instante: string;
    Arquitectura: string;
    RutaCopiaPrevia: string;
    RutaComprobacion: string;
    IntegridadVerificada: Boolean;
    Ejecutables: TArray<TEjecutableActualizado>;
    Aplicados: TArray<TScriptAplicadoActualizacion>;
    Pendientes: TArray<TScriptPendienteActualizacion>;
    function HayScriptsPendientes: Boolean;
    function HayScriptsAplicados: Boolean;
    function SePuedeRevertir: Boolean;
    procedure AnadirEjecutable(
      const ARuta, ARutaAnterior, ASha256: string);
    procedure AnadirAplicado(
      const ANombre: string;
      AOrden: Integer;
      const AResultado, ADetalle, ARutaRollback: string);
  end;

function CarpetaActualizaciones: string;
function CarpetaDescargasActualizacion(const AVersion: string): string;
function RutaEstadoActualizacion: string;
function LeerEstadoActualizacion: TEstadoActualizacion;
// Estado sobre el que anotar los scripts que se apliquen sin instalar
// ninguna versión. Si el que hay ya habla de esta instalación se
// conserva, para no perder con qué revertir la última actualización; si
// habla de otra, se empieza uno nuevo sin ejecutables sustituidos.
function EstadoParaScriptsSinInstalacion(
  const AEstado: TEstadoActualizacion;
  const AVersionInstalada, AVersionPublicada, AArquitectura: string):
  TEstadoActualizacion;
function GuardarEstadoActualizacion(
  const AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
function BorrarDescargasActualizacion(
  const AVersion: string;
  out AError: string): Boolean;
// Comprueba, la primera vez que arranca la versión instalada, que los
// ejecutables tienen la huella SHA-256 que publicó el servicio.
function ComprobarIntegridadActualizacion(
  const AVersionEnEjecucion: string;
  out AMensaje: string): Boolean;

implementation

uses
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  inLibMsgIntegraciones;

const
  cContratoEstadoActualizacion = 1;
  cNombreCarpetaActualizaciones = 'actualizaciones';
  cVariableCarpetaActualizaciones =
    'VIRACASH_ACTUALIZACIONES_DIR';
  cNombreEstadoActualizacion = 'estado.json';

// El programa suele estar en C:\Program Files\ViraCash, donde no se
// puede escribir sin elevar: el estado y las descargas viven en la
// carpeta local del usuario. Antes estaban en ProgramData, comun a todo
// el equipo, pero alli cada fichero solo lo puede reescribir quien lo
// creo: con varias cuentas en la maquina, la segunda se encontraba un
// «Acceso denegado» sobre lo que habia dejado la primera.
function CarpetaActualizaciones: string;
var
  sDatos: string;
begin
  // Una instalacion peculiar (o las pruebas) puede fijar la carpeta.
  sDatos := Trim(GetEnvironmentVariable(cVariableCarpetaActualizaciones));
  if sDatos <> '' then
    Exit(sDatos);
  sDatos := GetEnvironmentVariable('LOCALAPPDATA');
  if Trim(sDatos) = '' then
    sDatos := ExtractFilePath(ExpandFileName(ParamStr(0)))
  else
    sDatos := TPath.Combine(sDatos, 'ViraCash');
  Result := TPath.Combine(sDatos, cNombreCarpetaActualizaciones);
end;

// Donde vivia el estado hasta ahora. Se sigue mirando, solo para leer
// -lo unico que Windows garantiza sobre lo que dejo otra cuenta-, para
// no perder con que revertir lo que ya se aplico. Vacio si la carpeta
// esta fijada a mano: entonces no hay herencia que valga.
function CarpetaActualizacionesHeredada: string;
var
  sDatos: string;
begin
  Result := '';
  if Trim(GetEnvironmentVariable(cVariableCarpetaActualizaciones)) <> '' then
    Exit;
  sDatos := Trim(GetEnvironmentVariable('ProgramData'));
  if sDatos <> '' then
    Result := TPath.Combine(
      TPath.Combine(sDatos, 'ViraCash'),
      cNombreCarpetaActualizaciones);
end;

function CarpetaDescargasActualizacion(const AVersion: string): string;
begin
  Result := TPath.Combine(CarpetaActualizaciones, Trim(AVersion));
end;

function RutaEstadoActualizacion: string;
begin
  Result := TPath.Combine(
    CarpetaActualizaciones,
    cNombreEstadoActualizacion);
end;

function TextoJson(AJson: TJSONObject; const ANombre: string): string;
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

function EnteroJson(AJson: TJSONObject; const ANombre: string): Integer;
begin
  Result := StrToIntDef(TextoJson(AJson, ANombre), 0);
end;

procedure LeerEjecutables(
  AJson: TJSONObject;
  var AEstado: TEstadoActualizacion);
var
  iIndice: Integer;
  oLista: TJSONArray;
  oValor: TJSONValue;
begin
  AEstado.Ejecutables := nil;
  oValor := AJson.GetValue('ejecutables');
  if oValor is TJSONArray then
  begin
    oLista := TJSONArray(oValor);
    SetLength(AEstado.Ejecutables, oLista.Count);
    for iIndice := 0 to oLista.Count - 1 do
    begin
      AEstado.Ejecutables[iIndice] := Default(TEjecutableActualizado);
      if oLista.Items[iIndice] is TJSONObject then
      begin
        AEstado.Ejecutables[iIndice].Ruta := TextoJson(
          TJSONObject(oLista.Items[iIndice]), 'ruta');
        AEstado.Ejecutables[iIndice].RutaAnterior := TextoJson(
          TJSONObject(oLista.Items[iIndice]), 'anterior');
        AEstado.Ejecutables[iIndice].Sha256 := TextoJson(
          TJSONObject(oLista.Items[iIndice]), 'sha256');
      end;
    end;
  end;
end;

procedure LeerAplicados(
  AJson: TJSONObject;
  var AEstado: TEstadoActualizacion);
var
  iIndice: Integer;
  oLista: TJSONArray;
  oScript: TJSONObject;
  oValor: TJSONValue;
begin
  AEstado.Aplicados := nil;
  oValor := AJson.GetValue('scripts_aplicados');
  if oValor is TJSONArray then
  begin
    oLista := TJSONArray(oValor);
    SetLength(AEstado.Aplicados, oLista.Count);
    for iIndice := 0 to oLista.Count - 1 do
    begin
      AEstado.Aplicados[iIndice] := Default(TScriptAplicadoActualizacion);
      if oLista.Items[iIndice] is TJSONObject then
      begin
        oScript := TJSONObject(oLista.Items[iIndice]);
        AEstado.Aplicados[iIndice].Nombre := TextoJson(oScript, 'nombre');
        AEstado.Aplicados[iIndice].Orden := EnteroJson(oScript, 'orden');
        AEstado.Aplicados[iIndice].Resultado := TextoJson(
          oScript, 'resultado');
        AEstado.Aplicados[iIndice].Detalle := TextoJson(oScript, 'detalle');
        AEstado.Aplicados[iIndice].RutaRollback := TextoJson(
          oScript, 'rollback');
      end;
    end;
  end;
end;

procedure LeerPendientes(
  AJson: TJSONObject;
  var AEstado: TEstadoActualizacion);
var
  iIndice: Integer;
  oLista: TJSONArray;
  oScript: TJSONObject;
  oValor: TJSONValue;
begin
  AEstado.Pendientes := nil;
  oValor := AJson.GetValue('scripts_pendientes');
  if oValor is TJSONArray then
  begin
    oLista := TJSONArray(oValor);
    SetLength(AEstado.Pendientes, oLista.Count);
    for iIndice := 0 to oLista.Count - 1 do
    begin
      AEstado.Pendientes[iIndice] := Default(TScriptPendienteActualizacion);
      if oLista.Items[iIndice] is TJSONObject then
      begin
        oScript := TJSONObject(oLista.Items[iIndice]);
        AEstado.Pendientes[iIndice].Nombre := TextoJson(oScript, 'nombre');
        AEstado.Pendientes[iIndice].Orden := EnteroJson(oScript, 'orden');
        AEstado.Pendientes[iIndice].Ruta := TextoJson(oScript, 'ruta');
        AEstado.Pendientes[iIndice].RutaRollback := TextoJson(
          oScript, 'rollback');
      end;
    end;
  end;
end;

function LeerEstadoDesde(const ARuta: string): TEstadoActualizacion;
var
  oJson: TJSONValue;
  oObjeto: TJSONObject;
  sRuta: string;
begin
  Result := Default(TEstadoActualizacion);
  sRuta := ARuta;
  if (Trim(sRuta) <> '') and TFile.Exists(sRuta) then
  begin
    try
      oJson := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(sRuta, TEncoding.UTF8));
      try
        if oJson is TJSONObject then
        begin
          oObjeto := TJSONObject(oJson);
          Result.Existe := True;
          Result.Estado := TextoJson(oObjeto, 'estado');
          Result.VersionOrigen := TextoJson(oObjeto, 'version_origen');
          Result.VersionDestino := TextoJson(oObjeto, 'version_destino');
          Result.Instante := TextoJson(oObjeto, 'instante');
          Result.Arquitectura := TextoJson(oObjeto, 'arquitectura');
          Result.RutaCopiaPrevia := TextoJson(oObjeto, 'copia_previa');
          Result.RutaComprobacion := TextoJson(oObjeto, 'comprobacion');
          Result.IntegridadVerificada :=
            oObjeto.GetValue('integridad_verificada') is TJSONTrue;
          LeerEjecutables(oObjeto, Result);
          LeerAplicados(oObjeto, Result);
          LeerPendientes(oObjeto, Result);
        end;
      finally
        oJson.Free;
      end;
    except
      on E: Exception do
        Result := Default(TEstadoActualizacion);
    end;
  end;
end;

function LeerEstadoActualizacion: TEstadoActualizacion;
var
  sCarpeta: string;
begin
  Result := LeerEstadoDesde(RutaEstadoActualizacion);
  if not Result.Existe then
  begin
    // Nada en la carpeta del usuario: puede ser una instalacion que
    // venia guardandolo en ProgramData. Se lee de alli y lo primero que
    // se guarde ya cae en la carpeta nueva.
    sCarpeta := CarpetaActualizacionesHeredada;
    if sCarpeta <> '' then
      Result := LeerEstadoDesde(
        TPath.Combine(sCarpeta, cNombreEstadoActualizacion));
  end;
end;

function ComponerJsonEstado(
  const AEstado: TEstadoActualizacion): TJSONObject;
var
  iIndice: Integer;
  oAplicados: TJSONArray;
  oEjecutables: TJSONArray;
  oElemento: TJSONObject;
  oPendientes: TJSONArray;
begin
  Result := TJSONObject.Create;
  Result.AddPair('contrato', TJSONNumber.Create(
    cContratoEstadoActualizacion));
  Result.AddPair('estado', AEstado.Estado);
  Result.AddPair('version_origen', AEstado.VersionOrigen);
  Result.AddPair('version_destino', AEstado.VersionDestino);
  Result.AddPair('instante', AEstado.Instante);
  Result.AddPair('arquitectura', AEstado.Arquitectura);
  Result.AddPair('copia_previa', AEstado.RutaCopiaPrevia);
  Result.AddPair('comprobacion', AEstado.RutaComprobacion);
  Result.AddPair(
    'integridad_verificada',
    TJSONBool.Create(AEstado.IntegridadVerificada));
  oEjecutables := TJSONArray.Create;
  for iIndice := Low(AEstado.Ejecutables) to High(AEstado.Ejecutables) do
  begin
    oElemento := TJSONObject.Create;
    oElemento.AddPair('ruta', AEstado.Ejecutables[iIndice].Ruta);
    oElemento.AddPair('anterior', AEstado.Ejecutables[iIndice].RutaAnterior);
    oElemento.AddPair('sha256', AEstado.Ejecutables[iIndice].Sha256);
    oEjecutables.AddElement(oElemento);
  end;
  Result.AddPair('ejecutables', oEjecutables);
  oAplicados := TJSONArray.Create;
  for iIndice := Low(AEstado.Aplicados) to High(AEstado.Aplicados) do
  begin
    oElemento := TJSONObject.Create;
    oElemento.AddPair('nombre', AEstado.Aplicados[iIndice].Nombre);
    oElemento.AddPair('orden', TJSONNumber.Create(
      AEstado.Aplicados[iIndice].Orden));
    oElemento.AddPair('resultado', AEstado.Aplicados[iIndice].Resultado);
    oElemento.AddPair('detalle', AEstado.Aplicados[iIndice].Detalle);
    oElemento.AddPair('rollback', AEstado.Aplicados[iIndice].RutaRollback);
    oAplicados.AddElement(oElemento);
  end;
  Result.AddPair('scripts_aplicados', oAplicados);
  oPendientes := TJSONArray.Create;
  for iIndice := Low(AEstado.Pendientes) to High(AEstado.Pendientes) do
  begin
    oElemento := TJSONObject.Create;
    oElemento.AddPair('nombre', AEstado.Pendientes[iIndice].Nombre);
    oElemento.AddPair('orden', TJSONNumber.Create(
      AEstado.Pendientes[iIndice].Orden));
    oElemento.AddPair('ruta', AEstado.Pendientes[iIndice].Ruta);
    oElemento.AddPair('rollback', AEstado.Pendientes[iIndice].RutaRollback);
    oPendientes.AddElement(oElemento);
  end;
  Result.AddPair('scripts_pendientes', oPendientes);
end;

function EstadoParaScriptsSinInstalacion(
  const AEstado: TEstadoActualizacion;
  const AVersionInstalada, AVersionPublicada, AArquitectura: string):
  TEstadoActualizacion;
begin
  if AEstado.Existe and
     not SameText(AEstado.Estado, cEstadoActualizacionRevertida) and
     (SameText(Trim(AEstado.VersionDestino), Trim(AVersionInstalada)) or
      SameText(Trim(AEstado.VersionDestino), Trim(AVersionPublicada))) then
    Result := AEstado
  else
  begin
    Result := Default(TEstadoActualizacion);
    Result.VersionOrigen := Trim(AVersionInstalada);
    Result.VersionDestino := Trim(AVersionInstalada);
    Result.Arquitectura := Trim(AArquitectura);
  end;
  // Los pendientes los vuelve a decidir la comprobación de esta pasada.
  Result.Pendientes := nil;
end;

function GuardarEstadoActualizacion(
  const AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  oJson: TJSONObject;
begin
  Result := False;
  AError := '';
  try
    if not TDirectory.Exists(CarpetaActualizaciones) then
      TDirectory.CreateDirectory(CarpetaActualizaciones);
    oJson := ComponerJsonEstado(AEstado);
    try
      TFile.WriteAllText(
        RutaEstadoActualizacion,
        oJson.Format(2),
        TEncoding.UTF8);
      Result := True;
    finally
      oJson.Free;
    end;
  except
    on E: Exception do
      AError := E.Message;
  end;
end;

function BorrarDescargasActualizacion(
  const AVersion: string;
  out AError: string): Boolean;
var
  sCarpeta: string;
begin
  Result := True;
  AError := '';
  sCarpeta := CarpetaDescargasActualizacion(AVersion);
  if (Trim(AVersion) <> '') and TDirectory.Exists(sCarpeta) then
  begin
    try
      TDirectory.Delete(sCarpeta, True);
    except
      on E: Exception do
      begin
        Result := False;
        AError := E.Message;
      end;
    end;
  end;
end;

function ComprobarIntegridadActualizacion(
  const AVersionEnEjecucion: string;
  out AMensaje: string): Boolean;
var
  Estado: TEstadoActualizacion;
  iIndice: Integer;
  sError: string;
  sHuella: string;
begin
  Result := True;
  AMensaje := '';
  Estado := LeerEstadoActualizacion;
  // Solo tiene sentido comprobarlo la primera vez que arranca la
  // version que se instalo; despues la marca queda guardada.
  if Estado.Existe and
     not Estado.IntegridadVerificada and
     not SameText(Estado.Estado, cEstadoActualizacionRevertida) and
     SameText(Trim(Estado.VersionDestino), Trim(AVersionEnEjecucion)) then
  begin
    for iIndice := Low(Estado.Ejecutables) to High(Estado.Ejecutables) do
    begin
      if Length(Trim(Estado.Ejecutables[iIndice].Sha256)) = 64 then
      begin
        if not TFile.Exists(Estado.Ejecutables[iIndice].Ruta) then
          sHuella := ''
        else
          sHuella := LowerCase(
            THashSHA2.GetHashStringFromFile(
              Estado.Ejecutables[iIndice].Ruta));
        if not SameText(sHuella, Estado.Ejecutables[iIndice].Sha256) then
        begin
          Result := False;
          if AMensaje <> '' then
            AMensaje := AMensaje + sLineBreak;
          AMensaje := AMensaje + Format(
            SErrorIntegridadEjecutableActualizado,
            [ExtractFileName(Estado.Ejecutables[iIndice].Ruta),
             Estado.VersionDestino]);
        end;
      end;
    end;
    Estado.IntegridadVerificada := True;
    GuardarEstadoActualizacion(Estado, sError);
  end;
end;

{ TEstadoActualizacion }

function TEstadoActualizacion.HayScriptsPendientes: Boolean;
begin
  Result := Length(Pendientes) > 0;
end;

function TEstadoActualizacion.HayScriptsAplicados: Boolean;
begin
  Result := Length(Aplicados) > 0;
end;

function TEstadoActualizacion.SePuedeRevertir: Boolean;
begin
  Result := Existe and
    not SameText(Estado, cEstadoActualizacionRevertida) and
    ((Length(Ejecutables) > 0) or HayScriptsAplicados);
end;

procedure TEstadoActualizacion.AnadirEjecutable(
  const ARuta, ARutaAnterior, ASha256: string);
var
  iIndice: Integer;
begin
  iIndice := Length(Ejecutables);
  SetLength(Ejecutables, iIndice + 1);
  Ejecutables[iIndice].Ruta := ARuta;
  Ejecutables[iIndice].RutaAnterior := ARutaAnterior;
  Ejecutables[iIndice].Sha256 := LowerCase(Trim(ASha256));
end;

procedure TEstadoActualizacion.AnadirAplicado(
  const ANombre: string;
  AOrden: Integer;
  const AResultado, ADetalle, ARutaRollback: string);
var
  iIndice: Integer;
begin
  iIndice := Length(Aplicados);
  SetLength(Aplicados, iIndice + 1);
  Aplicados[iIndice].Nombre := ANombre;
  Aplicados[iIndice].Orden := AOrden;
  Aplicados[iIndice].Resultado := AResultado;
  Aplicados[iIndice].Detalle := ADetalle;
  Aplicados[iIndice].RutaRollback := ARutaRollback;
end;

end.
