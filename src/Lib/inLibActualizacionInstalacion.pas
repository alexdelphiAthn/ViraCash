{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionInstalacion                                 }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sustituye y restaura ejecutables renombrando el anterior con un guion     }
{    bajo delante. La sustitución es diferida: el programa en curso sigue      }
{    funcionando y la versión nueva entra en el siguiente arranque.            }
{******************************************************************************}
unit inLibActualizacionInstalacion;

interface

const
  cMaximoGuionesBajosEjecutable = 9;
  cConmutadorSustitucionElevada = 'actualizacion-sustituir';

type
  TSustitucionEjecutable = record
    Destino: string;
    Origen: string;
  end;

// Ruta única en la carpeta temporal para lo que se está bajando.
function RutaTemporalActualizacion(const AExtension: string): string;
function CabeceraEjecutableValida(const ARuta: string): Boolean;
function MismaArquitecturaEjecutable(
  const ARutaActual, ARutaNueva: string): Boolean;
// Ruta del ejecutable conservado: _nombre.exe. Si ya hay uno y no se puede
// borrar porque está en uso, se añade otro guion bajo.
function RutaEjecutableAnterior(const ARutaActual: string): string;
function RutaEjecutableAnteriorExistente(
  const ARutaActual: string): string;
function SustituirEjecutable(
  const ARutaActual, ARutaNueva: string;
  out ARutaAnterior, AError: string): Boolean;
// Devuelve el ejecutable anterior a su sitio y guarda el descartado como
// nombre_<version>.exe.
function RestaurarEjecutableAnterior(
  const ARutaActual, AVersionDescartada: string;
  out ARutaDescartada, AError: string): Boolean;
// Deja solo el ejecutable anterior más reciente y lo renombra a
// _nombre.exe para que los guiones bajos no se acumulen.
procedure LimpiarEjecutablesAnteriores(const ARutaActual: string);
// Cierto cuando se puede crear un archivo en la carpeta sin elevar.
function CarpetaEscribible(const ACarpeta: string): Boolean;
// Sustituye varios ejecutables de una vez. Devuelve dónde quedó cada
// anterior, en el mismo orden.
function AplicarSustituciones(
  const ASustituciones: TArray<TSustitucionEjecutable>;
  out AAnteriores: TArray<string>;
  out AError: string): Boolean;
// Repite lo anterior en una instancia elevada del propio programa: es
// lo que hace falta cuando está instalado en Archivos de programa.
function AplicarSustitucionesElevado(
  const ASustituciones: TArray<TSustitucionEjecutable>;
  const ACarpetaTrabajo: string;
  out AAnteriores: TArray<string>;
  out AError: string): Boolean;
// Punto de entrada de la instancia elevada. Si el programa se ha
// lanzado con /actualizacion-sustituir=<plan>, aplica el plan, escribe
// el resultado junto a él y termina.
procedure ProcesarArranqueSustitucionElevada;

implementation

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  System.SysUtils,
  inLibMsgIntegraciones;

function RutaConGuionesBajos(
  const ARutaActual: string;
  ACantidad: Integer): string;
begin
  Result := TPath.Combine(
    ExtractFilePath(ARutaActual),
    StringOfChar('_', ACantidad) + ExtractFileName(ARutaActual));
end;

function RutaTemporalActualizacion(const AExtension: string): string;
var
  Identificador: TGUID;
begin
  CreateGUID(Identificador);
  Result := TPath.Combine(
    TPath.GetTempPath,
    'ViraCash_Actualizacion_' +
    StringReplace(
      StringReplace(GUIDToString(Identificador), '{', '', []),
      '}',
      '',
      []) + AExtension);
end;

function CabeceraEjecutableValida(const ARuta: string): Boolean;
var
  aCabecera: array[0..1] of Byte;
  oFlujo: TFileStream;
begin
  Result := False;
  oFlujo := TFileStream.Create(ARuta, fmOpenRead or fmShareDenyNone);
  try
    if oFlujo.Size >= 2 then
    begin
      oFlujo.ReadBuffer(aCabecera, SizeOf(aCabecera));
      Result := (aCabecera[0] = Ord('M')) and
        (aCabecera[1] = Ord('Z'));
    end;
  finally
    oFlujo.Free;
  end;
end;

function MismaArquitecturaEjecutable(
  const ARutaActual, ARutaNueva: string): Boolean;
var
  iTipoActual: DWORD;
  iTipoNuevo: DWORD;
begin
  iTipoActual := 0;
  iTipoNuevo := 0;
  Result := GetBinaryType(PChar(ARutaActual), iTipoActual) and
    GetBinaryType(PChar(ARutaNueva), iTipoNuevo) and
    (iTipoActual = iTipoNuevo);
end;

function RutaEjecutableAnterior(const ARutaActual: string): string;
var
  iGuiones: Integer;
  sCandidata: string;
begin
  Result := '';
  iGuiones := 1;
  while (Result = '') and (iGuiones <= cMaximoGuionesBajosEjecutable) do
  begin
    sCandidata := RutaConGuionesBajos(ARutaActual, iGuiones);
    // Si ya hay un ejecutable conservado se borra, para que no se
    // acumulen; solo si está en uso se recurre a otro guion bajo.
    if not TFile.Exists(sCandidata) then
      Result := sCandidata
    else if DeleteFile(PChar(sCandidata)) then
      Result := sCandidata;
    Inc(iGuiones);
  end;
end;

function RutaEjecutableAnteriorExistente(
  const ARutaActual: string): string;
var
  iGuiones: Integer;
  sCandidata: string;
begin
  Result := '';
  for iGuiones := 1 to cMaximoGuionesBajosEjecutable do
  begin
    sCandidata := RutaConGuionesBajos(ARutaActual, iGuiones);
    if TFile.Exists(sCandidata) then
      Result := sCandidata;
  end;
end;

function RutaDescartadaUnica(
  const ARutaActual, AVersionDescartada: string): string;
var
  iIntento: Integer;
  sBase: string;
  sSufijo: string;
begin
  sSufijo := Trim(AVersionDescartada);
  if sSufijo = '' then
    sSufijo := FormatDateTime('yyyymmddhhnnss', Now);
  sBase := TPath.Combine(
    ExtractFilePath(ARutaActual),
    ChangeFileExt(ExtractFileName(ARutaActual), '') + '_' + sSufijo);
  Result := sBase + ExtractFileExt(ARutaActual);
  iIntento := 1;
  while TFile.Exists(Result) and (iIntento < 100) do
  begin
    Result := sBase + '_' + iIntento.ToString + ExtractFileExt(ARutaActual);
    Inc(iIntento);
  end;
end;

function SustituirEjecutable(
  const ARutaActual, ARutaNueva: string;
  out ARutaAnterior, AError: string): Boolean;
begin
  Result := False;
  ARutaAnterior := '';
  AError := '';
  if not TFile.Exists(ARutaNueva) then
    AError := Format(SErrorEjecutableNuevoAusente, [ARutaNueva])
  else if not CabeceraEjecutableValida(ARutaNueva) then
    AError := SErrorArchivoActualizacionNoEjecutable
  else if TFile.Exists(ARutaActual) and
          not MismaArquitecturaEjecutable(ARutaActual, ARutaNueva) then
    AError := SErrorArquitecturaActualizacionNoCoincide
  else if not TFile.Exists(ARutaActual) then
  begin
    // Un auxiliar que todavía no estaba instalado: solo hay que copiarlo.
    if CopyFile(PChar(ARutaNueva), PChar(ARutaActual), True) then
      Result := True
    else
      AError := Format(
        SErrorCopiarEjecutableNuevo,
        [SysErrorMessage(GetLastError)]);
  end
  else
  begin
    ARutaAnterior := RutaEjecutableAnterior(ARutaActual);
    if ARutaAnterior = '' then
      AError := SErrorSitioEjecutableAnteriorOcupado
    else if not MoveFileEx(
                  PChar(ARutaActual),
                  PChar(ARutaAnterior),
                  MOVEFILE_WRITE_THROUGH) then
    begin
      AError := Format(
        SErrorRenombrarEjecutableActual,
        [SysErrorMessage(GetLastError)]);
      ARutaAnterior := '';
    end
    else if not CopyFile(PChar(ARutaNueva), PChar(ARutaActual), True) then
    begin
      AError := Format(
        SErrorCopiarEjecutableNuevo,
        [SysErrorMessage(GetLastError)]);
      if not MoveFileEx(
               PChar(ARutaAnterior),
               PChar(ARutaActual),
               MOVEFILE_WRITE_THROUGH) then
        AError := AError + sLineBreak +
          Format(SErrorRestaurarEjecutableAnterior, [ARutaAnterior]);
      ARutaAnterior := '';
    end
    else
      Result := True;
  end;
end;

function RestaurarEjecutableAnterior(
  const ARutaActual, AVersionDescartada: string;
  out ARutaDescartada, AError: string): Boolean;
var
  sAnterior: string;
begin
  Result := False;
  ARutaDescartada := '';
  AError := '';
  sAnterior := RutaEjecutableAnteriorExistente(ARutaActual);
  if (sAnterior = '') and not TFile.Exists(ARutaActual) then
    Result := True
  else if sAnterior = '' then
    AError := Format(
      SErrorEjecutableAnteriorAusente,
      [ExtractFileName(ARutaActual)])
  else
  begin
    if TFile.Exists(ARutaActual) then
    begin
      ARutaDescartada := RutaDescartadaUnica(
        ARutaActual,
        AVersionDescartada);
      if not MoveFileEx(
               PChar(ARutaActual),
               PChar(ARutaDescartada),
               MOVEFILE_WRITE_THROUGH) then
      begin
        AError := Format(
          SErrorRenombrarEjecutableActual,
          [SysErrorMessage(GetLastError)]);
        ARutaDescartada := '';
      end;
    end;
    if AError = '' then
    begin
      if MoveFileEx(
           PChar(sAnterior),
           PChar(ARutaActual),
           MOVEFILE_WRITE_THROUGH) then
        Result := True
      else
      begin
        AError := Format(
          SErrorRestaurarEjecutableAnterior,
          [sAnterior]);
        if ARutaDescartada <> '' then
        begin
          MoveFileEx(
            PChar(ARutaDescartada),
            PChar(ARutaActual),
            MOVEFILE_WRITE_THROUGH);
          ARutaDescartada := '';
        end;
      end;
    end;
  end;
end;

procedure LimpiarEjecutablesAnteriores(const ARutaActual: string);
var
  iGuiones: Integer;
  sCandidata: string;
  sSuperviviente: string;
begin
  sSuperviviente := RutaEjecutableAnteriorExistente(ARutaActual);
  if sSuperviviente <> '' then
  begin
    for iGuiones := 1 to cMaximoGuionesBajosEjecutable do
    begin
      sCandidata := RutaConGuionesBajos(ARutaActual, iGuiones);
      if not SameText(sCandidata, sSuperviviente) and
         TFile.Exists(sCandidata) then
        DeleteFile(PChar(sCandidata));
    end;
    sCandidata := RutaConGuionesBajos(ARutaActual, 1);
    if not SameText(sCandidata, sSuperviviente) and
       not TFile.Exists(sCandidata) then
      MoveFileEx(
        PChar(sSuperviviente),
        PChar(sCandidata),
        MOVEFILE_WRITE_THROUGH);
  end;
end;
function CarpetaEscribible(const ACarpeta: string): Boolean;
var
  sPrueba: string;
begin
  Result := False;
  if TDirectory.Exists(ACarpeta) then
  begin
    sPrueba := TPath.Combine(
      ACarpeta,
      'viracash_escritura_' + FormatDateTime('hhnnsszzz', Now) + '.tmp');
    try
      TFile.WriteAllText(sPrueba, 'x');
      Result := True;
    except
      on E: Exception do
        Result := False;
    end;
    if Result and TFile.Exists(sPrueba) then
      DeleteFile(PChar(sPrueba));
  end;
end;

function AplicarSustituciones(
  const ASustituciones: TArray<TSustitucionEjecutable>;
  out AAnteriores: TArray<string>;
  out AError: string): Boolean;
var
  iHechas: Integer;
  iIndice: Integer;
  sAnterior: string;
begin
  Result := True;
  AError := '';
  iHechas := 0;
  SetLength(AAnteriores, Length(ASustituciones));
  for iIndice := Low(ASustituciones) to High(ASustituciones) do
  begin
    if Result then
    begin
      Result := SustituirEjecutable(
        ASustituciones[iIndice].Destino,
        ASustituciones[iIndice].Origen,
        sAnterior,
        AError);
      if Result then
      begin
        AAnteriores[iIndice] := sAnterior;
        Inc(iHechas);
      end;
    end;
  end;
  // Si algo ha fallado, solo se devuelven las sustituciones hechas: son
  // las unicas que hay que deshacer despues.
  SetLength(AAnteriores, iHechas);
end;

function RutaResultadoPlan(const ARutaPlan: string): string;
begin
  Result := ARutaPlan + '.resultado';
end;

// El plan lo ejecuta un proceso elevado: solo se aceptan destinos en la
// carpeta del programa y origenes dentro de ACarpetaTrabajo.
function SustitucionAdmisible(
  const ASustitucion: TSustitucionEjecutable;
  const ACarpetaPrograma, ACarpetaTrabajo: string): Boolean;
begin
  Result := SameText(
      ExcludeTrailingPathDelimiter(
        ExtractFilePath(ExpandFileName(ASustitucion.Destino))),
      ExcludeTrailingPathDelimiter(ACarpetaPrograma)) and
    SameText(ExtractFileExt(ASustitucion.Destino), '.exe') and
    StartsText(
      IncludeTrailingPathDelimiter(ExpandFileName(ACarpetaTrabajo)),
      ExpandFileName(ASustitucion.Origen));
end;

function GuardarPlanSustitucion(
  const ARutaPlan, ACarpetaTrabajo: string;
  const ASustituciones: TArray<TSustitucionEjecutable>;
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
      oPlan.AddPair('carpeta_trabajo', ACarpetaTrabajo);
      oLista := TJSONArray.Create;
      for iIndice := Low(ASustituciones) to High(ASustituciones) do
      begin
        oElemento := TJSONObject.Create;
        oElemento.AddPair('destino', ASustituciones[iIndice].Destino);
        oElemento.AddPair('origen', ASustituciones[iIndice].Origen);
        oLista.AddElement(oElemento);
      end;
      oPlan.AddPair('sustituciones', oLista);
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

function TextoPlan(AJson: TJSONObject; const ANombre: string): string;
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

function CargarPlanSustitucion(
  const ARutaPlan: string;
  out ACarpetaTrabajo: string;
  out ASustituciones: TArray<TSustitucionEjecutable>;
  out AError: string): Boolean;
var
  iIndice: Integer;
  oJson: TJSONValue;
  oLista: TJSONValue;
  oPlan: TJSONObject;
begin
  Result := False;
  AError := '';
  ACarpetaTrabajo := '';
  ASustituciones := nil;
  try
    oJson := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(ARutaPlan, TEncoding.UTF8));
    try
      if not (oJson is TJSONObject) then
        AError := SErrorPlanSustitucionNoValido
      else
      begin
        oPlan := TJSONObject(oJson);
        ACarpetaTrabajo := TextoPlan(oPlan, 'carpeta_trabajo');
        oLista := oPlan.GetValue('sustituciones');
        if not (oLista is TJSONArray) then
          AError := SErrorPlanSustitucionNoValido
        else
        begin
          SetLength(ASustituciones, TJSONArray(oLista).Count);
          for iIndice := 0 to TJSONArray(oLista).Count - 1 do
          begin
            if TJSONArray(oLista).Items[iIndice] is TJSONObject then
            begin
              ASustituciones[iIndice].Destino := TextoPlan(
                TJSONObject(TJSONArray(oLista).Items[iIndice]), 'destino');
              ASustituciones[iIndice].Origen := TextoPlan(
                TJSONObject(TJSONArray(oLista).Items[iIndice]), 'origen');
            end;
          end;
          Result := True;
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

procedure GuardarResultadoPlan(
  const ARutaPlan: string;
  AOk: Boolean;
  const AAnteriores: TArray<string>;
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
      for iIndice := Low(AAnteriores) to High(AAnteriores) do
        oLista.Add(AAnteriores[iIndice]);
      oResultado.AddPair('anteriores', oLista);
      TFile.WriteAllText(
        RutaResultadoPlan(ARutaPlan),
        oResultado.ToJSON,
        TEncoding.UTF8);
    except
      on E: Exception do
        // Sin resultado escrito, el llamador lo detecta por su ausencia.
        OutputDebugString(PChar(E.Message));
    end;
  finally
    oResultado.Free;
  end;
end;

function LeerResultadoPlan(
  const ARutaPlan: string;
  out AAnteriores: TArray<string>;
  out AError: string): Boolean;
var
  iIndice: Integer;
  oJson: TJSONValue;
  oLista: TJSONValue;
  oResultado: TJSONObject;
begin
  Result := False;
  AError := '';
  AAnteriores := nil;
  if not TFile.Exists(RutaResultadoPlan(ARutaPlan)) then
    AError := SErrorSustitucionElevadaSinRespuesta
  else
  begin
    try
      oJson := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(RutaResultadoPlan(ARutaPlan), TEncoding.UTF8));
      try
        if not (oJson is TJSONObject) then
          AError := SErrorSustitucionElevadaSinRespuesta
        else
        begin
          oResultado := TJSONObject(oJson);
          Result := oResultado.GetValue('ok') is TJSONTrue;
          AError := TextoPlan(oResultado, 'error');
          oLista := oResultado.GetValue('anteriores');
          if oLista is TJSONArray then
          begin
            SetLength(AAnteriores, TJSONArray(oLista).Count);
            for iIndice := 0 to TJSONArray(oLista).Count - 1 do
              AAnteriores[iIndice] :=
                TJSONArray(oLista).Items[iIndice].Value;
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

function LanzarInstanciaElevada(
  const ARutaPlan: string;
  out AError: string): Boolean;
var
  Informacion: TShellExecuteInfo;
  iCodigo: DWORD;
  sParametros: string;
  sRutaActual: string;
begin
  Result := False;
  AError := '';
  sRutaActual := ExpandFileName(ParamStr(0));
  sParametros := '/' + cConmutadorSustitucionElevada + '="' +
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
      AError := SErrorSustitucionElevadaRechazada
    else
      AError := SysErrorMessage(GetLastError);
  end
  else
  begin
    WaitForSingleObject(Informacion.hProcess, INFINITE);
    if GetExitCodeProcess(Informacion.hProcess, iCodigo) then
      Result := iCodigo = 0
    else
      AError := SysErrorMessage(GetLastError);
    CloseHandle(Informacion.hProcess);
  end;
end;

function AplicarSustitucionesElevado(
  const ASustituciones: TArray<TSustitucionEjecutable>;
  const ACarpetaTrabajo: string;
  out AAnteriores: TArray<string>;
  out AError: string): Boolean;
var
  sPlan: string;
begin
  AAnteriores := nil;
  sPlan := RutaTemporalActualizacion('.plan');
  Result := GuardarPlanSustitucion(
    sPlan,
    ACarpetaTrabajo,
    ASustituciones,
    AError);
  if Result then
  begin
    if LanzarInstanciaElevada(sPlan, AError) then
      Result := LeerResultadoPlan(sPlan, AAnteriores, AError)
    else
      Result := False;
  end;
  if TFile.Exists(sPlan) then
    DeleteFile(PChar(sPlan));
  if TFile.Exists(RutaResultadoPlan(sPlan)) then
    DeleteFile(PChar(RutaResultadoPlan(sPlan)));
end;

procedure ProcesarArranqueSustitucionElevada;
var
  aAnteriores: TArray<string>;
  aSustituciones: TArray<TSustitucionEjecutable>;
  bOk: Boolean;
  iIndice: Integer;
  sCarpetaTrabajo: string;
  sError: string;
  sPlan: string;
begin
  sPlan := '';
  if FindCmdLineSwitch(cConmutadorSustitucionElevada, sPlan, True) and
     (Trim(sPlan) <> '') then
  begin
    bOk := CargarPlanSustitucion(
      sPlan,
      sCarpetaTrabajo,
      aSustituciones,
      sError);
    for iIndice := Low(aSustituciones) to High(aSustituciones) do
    begin
      if bOk and not SustitucionAdmisible(
                     aSustituciones[iIndice],
                     ExcludeTrailingPathDelimiter(
                       ExtractFilePath(ExpandFileName(ParamStr(0)))),
                     sCarpetaTrabajo) then
      begin
        bOk := False;
        sError := SErrorPlanSustitucionNoAdmisible;
      end;
    end;
    if bOk then
      bOk := AplicarSustituciones(aSustituciones, aAnteriores, sError);
    GuardarResultadoPlan(sPlan, bOk, aAnteriores, sError);
    if bOk then
      Halt(0)
    else
      Halt(1);
  end;
end;

end.
