{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosNube                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Descarga de fotos de artículo desde el servicio web general.              }
{    Pide el ZIP con las fotos del artículo, lo descomprime en appDirFotos     }
{    dejando los PNG sueltos y borra el ZIP temporal. La integración en el     }
{    persistencia del servicio de fotos (Guardar / GuardarSesion) la hace el  }
{    formulario.                                                              }
{    que invoca, según su contexto (sesión de compras o ficha de fotos).       }
{                                                                              }
{    Contrato de /fotos/descargar.php:                                         }
{      GET  ?referencia=..&articulo=..&resolucion=real                         }
{      Header X-API-Key con la clave.                                          }
{      200 application/zip con los PNG; 4xx application/json [message].        }
{******************************************************************************}
unit inLibFotosNube;

interface

uses
  System.SysUtils, System.Classes, inLibParametrosIntf;

// Comprueba que los parámetros necesarios (URL general, clave X-API-Key,
// referencia de instalación y carpeta de fotos) están configurados. Si falta
// alguno devuelve False y deja en AMensaje la lista de lo que falta.
function FotosNubeConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;

// Descarga del servidor todas las fotos del artículo ACodArt (resolución
// real), las descomprime en una carpeta TEMPORAL (no en appDirFotos) y borra
// el ZIP. Deja en AArchivos las rutas de los PNG extraídos; el llamante
// integra la elegida y luego llama a LimpiarDescargaTemporal(AArchivos) para
// borrar los temporales y no dejar huérfanos. False con el error en AMensaje.
function DescargarFotosArticulo(
                                const AParametrosApp:
                                IParametrosAplicacion;
                                const ACodArt: string;
                                out AArchivos: TArray<string>;
                                out AMensaje: string;
                                AReparacion: Int64 = 0): Boolean;

// Borra los PNG temporales extraídos por DescargarFotosArticulo y su carpeta
// temporal (solo si es una "viracash_fotos_*"). Llamar tras integrar la foto
// elegida para no dejar ficheros sueltos en disco.
procedure LimpiarDescargaTemporal(const AArchivos: TArray<string>);

// De la lista de PNG descargados elige uno representativo para integrarlo
// como foto del artículo: prioriza los terminados en '_real' y, dentro de
// ellos, el primero por orden alfabético. Devuelve '' si la lista está
// vacía.
function ElegirFotoRepresentativa(const AArchivos: TArray<string>): string;

// Elige el PNG descargado cuyo color (token <color> del nombre
// ARTICULO_COLOR_INDICE_real.png) case con AColor. Si AColor = '' o no hay
// coincidencia, cae en ElegirFotoRepresentativa. Sirve para integrar al
// nivel artículo/color que muestra el visor de fotos.
// AColor es el segmento de color del SKU, que es el TEXTO DEL PROVEEDOR
// saneado (persistido como fza_atributos_valores.AV; el color básico es solo
// un helper de clasificación). El servidor nombra el fichero con ese mismo
// token saneado (misma regla que SanearColorFoto) para que case.
function ElegirFotoNubePorColor(const AArchivos: TArray<string>;
                                const AColor: string): string;

function FiltrarFotosNube(const AArchivos: TArray<string>;
  const AArticulo, AColor: string): TArray<string>;

implementation

uses
  System.IOUtils, System.StrUtils, System.JSON,
  System.Net.HttpClient, System.Net.URLClient, System.NetEncoding,
  System.Zip,
  inLibViraCashApi, inLibMsgArticulos;

const
  cParDirFotos = 'appDirFotos';
  cRutaDescarga = 'fotos/descargar.php';

function FotosNubeConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
var
  faltan: TStringList;
begin
  AMensaje := '';
  faltan := TStringList.Create;
  try
    if TClienteViraCashApi.UrlBase(AParametrosApp) = '' then
      faltan.Add(STextoParametroUrlFotosNube);
    if TClienteViraCashApi.Token(AParametrosApp) = '' then
      faltan.Add(STextoParametroTokenFotosNube);
    if TClienteViraCashApi.Referencia(AParametrosApp) = '' then
      faltan.Add(STextoParametroReferenciaFotosNube);
    if Trim(AParametrosApp.GetPath(cParDirFotos)) = '' then
      faltan.Add(STextoParametroCarpetaFotosNube);
    Result := faltan.Count = 0;
    if not Result then
      AMensaje := Format(SErrorParametrosFotosNubeFaltantes,
        [faltan.Text]);
  finally
    FreeAndNil(faltan);
  end;
end;

// Un ZIP empieza siempre por la firma 'PK' (0x50 0x4B). Lo usamos para
// distinguir la respuesta binaria correcta del JSON de error 4xx.
function ContenidoEsZip(AStream: TStream): Boolean;
var
  firma : array[0..1] of Byte;
  leidos: Integer;
begin
  Result := False;
  if AStream.Size >= 2 then
  begin
    AStream.Position := 0;
    leidos := AStream.Read(firma, 2);
    Result := (leidos = 2) and (firma[0] = Ord('P')) and (firma[1] = Ord('K'));
    AStream.Position := 0;
  end;
end;

// Extrae el campo "message" del JSON de error del servidor. Si no se puede
// interpretar, devuelve un mensaje genérico con el código HTTP.
function MensajeErrorServidor(AStream: TStream; AStatus: Integer): string;
var
  texto: TStringStream;
  jerror: TJSONValue;
  jval : TJSONValue;
  jmsg : TJSONValue;
begin
  Result := '';
  texto := TStringStream.Create('', TEncoding.UTF8);
  try
    AStream.Position := 0;
    if AStream.Size > 0 then
      texto.CopyFrom(AStream, AStream.Size);
    jval := TJSONObject.ParseJSONValue(texto.DataString);
    try
      if jval <> nil then
      begin
        jmsg := jval.FindValue('message');
        if jmsg <> nil then
          Result := jmsg.Value;
        if Result = '' then
        begin
          jerror := jval.FindValue('error');
          if jerror <> nil then
          begin
            jmsg := jerror.FindValue('mensaje');
            if jmsg <> nil then
              Result := jmsg.Value;
          end;
        end;
      end;
    finally
      FreeAndNil(jval);
    end;
  finally
    FreeAndNil(texto);
  end;
  if Result = '' then
    Result := Format(SErrorServidorFotosNubeHttp, [AStatus]);
end;

function DescargarFotosArticulo(
                                const AParametrosApp:
                                IParametrosAplicacion;
                                const ACodArt: string;
                                out AArchivos: TArray<string>;
                                out AMensaje: string;
                                AReparacion: Int64): Boolean;
var
  sKey, sReferencia, sDir, sUrlFull, sZipTmp, sTs: string;
  http   : THTTPClient;
  resp   : IHTTPResponse;
  cuerpo : TMemoryStream;
  zip    : TZipFile;
  lista  : TStringList;
  nombres: TArray<string>;
  i      : Integer;
begin
  Result    := False;
  AArchivos := nil;
  if FotosNubeConfigurado(AParametrosApp, AMensaje) then
  begin
    sKey := TClienteViraCashApi.Token(AParametrosApp);
    sReferencia := TClienteViraCashApi.Referencia(AParametrosApp);
    // Pedimos resolución 'real' (calidad original): el sistema de fotos
    // ya genera 300/600 al integrar la foto representativa.
    sUrlFull := TClienteViraCashApi.ComponerUrl(
      AParametrosApp,
      cRutaDescarga) +
      '?referencia=' + TNetEncoding.URL.Encode(sReferencia) +
      '&articulo=' + TNetEncoding.URL.Encode(ACodArt) +
      '&resolucion=real';
    if AReparacion > 0 then
      sUrlFull := sUrlFull + '&reparacion=' + IntToStr(AReparacion);
    http   := THTTPClient.Create;
    cuerpo := TMemoryStream.Create;
    try
      http.CustomHeaders['X-API-Key'] := sKey;
      resp := nil;
      try
        resp := http.Get(sUrlFull, cuerpo);
      except
        on E: Exception do
          AMensaje := Format(SErrorConexionServidorFotosNube, [E.Message]);
      end;
      if resp <> nil then
      begin
        if (resp.StatusCode <> 200) or (not ContenidoEsZip(cuerpo)) then
          AMensaje := MensajeErrorServidor(cuerpo, resp.StatusCode)
        else
        begin
          sTs     := FormatDateTime('yyyymmdd_hhnnss_zzz', Now);
          sZipTmp := TPath.Combine(TPath.GetTempPath,
                       'viracash_fotos_' + sTs + '.zip');
          // Carpeta temporal unica (NO appDirFotos): el sistema de fotos
          // copia la elegida a real/300/600 al integrar; el llamante borra
          // esta temporal despues (LimpiarDescargaTemporal).
          sDir := IncludeTrailingPathDelimiter(
                    TPath.Combine(TPath.GetTempPath, 'viracash_fotos_' + sTs));
          ForceDirectories(sDir);
          cuerpo.Position := 0;
          cuerpo.SaveToFile(sZipTmp);
          lista := TStringList.Create;
          zip   := TZipFile.Create;
          try
            zip.Open(sZipTmp, zmRead);
            nombres := zip.FileNames;
            for i := 0 to High(nombres) do
            begin
              if (ExtractFileName(nombres[i]) <> nombres[i]) or
                 (Pos('..', nombres[i]) > 0) or
                 (Pos(':', nombres[i]) > 0) then
                raise EArgumentException.Create('Nombre de foto inválido');
              if SameText(ExtractFileExt(nombres[i]), '.png') or
                 ((AReparacion > 0) and
                  SameText(ExtractFileExt(nombres[i]), '.json')) then
              begin
                zip.Extract(nombres[i], sDir, False);
                lista.Add(sDir + nombres[i]);
              end;
            end;
            zip.Close;
            AArchivos := lista.ToStringArray;
            Result    := True;
          finally
            FreeAndNil(zip);
            FreeAndNil(lista);
            // "Dejar las fotos, borrar el zip": eliminamos el temporal.
            if FileExists(sZipTmp) then
              DeleteFile(sZipTmp);
          end;
        end;
      end;
    finally
      FreeAndNil(cuerpo);
      FreeAndNil(http);
    end;
  end;
end;

procedure LimpiarDescargaTemporal(const AArchivos: TArray<string>);
var
  i    : Integer;
  sDir : string;
begin
  for i := 0 to High(AArchivos) do
  begin
    if FileExists(AArchivos[i]) then
      DeleteFile(AArchivos[i]);
  end;
  if Length(AArchivos) > 0 then
  begin
    sDir := ExtractFileDir(AArchivos[0]);
    // Solo borramos la carpeta si es una temporal nuestra y queda vacia.
    if (sDir <> '') and
       (Pos('viracash_fotos_', LowerCase(ExtractFileName(sDir))) > 0) and
       TDirectory.Exists(sDir) and
       (Length(TDirectory.GetFiles(sDir)) = 0) then
      TDirectory.Delete(sDir, False);
  end;
end;

function ElegirFotoRepresentativa(const AArchivos: TArray<string>): string;
var
  orden: TStringList;
  i    : Integer;
  sReal: string;
begin
  Result := '';
  orden := TStringList.Create;
  try
    orden.Sorted := True;
    orden.Duplicates := dupAccept;
    for i := 0 to High(AArchivos) do
      orden.Add(AArchivos[i]);
    sReal := '';
    for i := 0 to orden.Count - 1 do
    begin
      if (sReal = '') and EndsText('_real.png', orden[i]) then
        sReal := orden[i];
    end;
    if sReal <> '' then
      Result := sReal
    else if orden.Count > 0 then
      Result := orden[0];
  finally
    FreeAndNil(orden);
  end;
end;

function SanearColorFoto(const AValor: string): string;
var
  i        : Integer;
  sParcial : string;
  c        : Char;
begin
  // Misma regla que SanearColorSku (inLibComprasSesionesReglas) y que
  // debe usar el servidor de fotos al nombrar el token COLOR: mayusculas;
  // espacios -> '-'; se conservan letras, digitos, '-' y '_'; el resto de
  // simbolos (/, %, EUR, ...) se descarta. Asi el color del SKU y el de la
  // foto casan exactamente.
  sParcial := UpperCase(Trim(AValor));
  Result := '';
  for i := 1 to Length(sParcial) do
  begin
    c := sParcial[i];
    if c = ' ' then
      Result := Result + '-'
    else if CharInSet(c, ['A'..'Z', '0'..'9', '-', '_']) then
      Result := Result + c;
  end;
  while Pos('--', Result) > 0 do
    Result := StringReplace(Result, '--', '-', [rfReplaceAll]);
  while Pos('__', Result) > 0 do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);
  while (Result <> '') and CharInSet(Result[1], ['-', '_']) do
    Delete(Result, 1, 1);
  while (Result <> '') and CharInSet(Result[Length(Result)], ['-', '_']) do
    Delete(Result, Length(Result), 1);
end;

function ElegirFotoNubePorColor(const AArchivos: TArray<string>;
                                const AColor: string): string;
var
  orden : TStringList;
  i     : Integer;
  sColor: string;
  sBase : string;
begin
  Result := '';
  sColor := SanearColorFoto(AColor);
  if sColor = '' then
    Result := ElegirFotoRepresentativa(AArchivos)
  else
  begin
    orden := TStringList.Create;
    try
      orden.Sorted := True;
      orden.Duplicates := dupAccept;
      for i := 0 to High(AArchivos) do
        orden.Add(AArchivos[i]);
      // Buscamos un '_real' cuyo nombre contenga el token _COLOR_, donde
      // COLOR es el color del SKU (texto del proveedor saneado).
      for i := 0 to orden.Count - 1 do
      begin
        sBase := UpperCase(ExtractFileName(orden[i]));
        if (Result = '') and EndsText('_REAL.PNG', sBase) and
           (Pos('_' + sColor + '_', sBase) > 0) then
          Result := orden[i];
      end;
      if Result = '' then
        Result := ElegirFotoRepresentativa(AArchivos);
    finally
      FreeAndNil(orden);
    end;
  end;
end;

function SegmentoServidorFoto(const ATexto: string): string;
var
  cLetra: Char;
begin
  Result := '';
  for cLetra in Trim(ATexto) do
    if CharInSet(cLetra, ['a'..'z', 'A'..'Z', '0'..'9', '_', '-']) then
      Result := Result + cLetra
    else
      Result := Result + '_';
  Result := Result.Trim(['_', '-']);
end;

function FiltrarFotosNube(const AArchivos: TArray<string>;
  const AArticulo, AColor: string): TArray<string>;
var
  oLista: TStringList;
  sArchivo, sPrefijo, sNombre, sIndice: string;
  iIndice: Integer;
begin
  oLista := TStringList.Create;
  try
    sPrefijo := SegmentoServidorFoto(AArticulo) + '_';
    if AColor = '' then
      sPrefijo := sPrefijo + 'GENERAL_'
    else
      sPrefijo := sPrefijo + SegmentoServidorFoto(AColor) + '_';
    for sArchivo in AArchivos do
    begin
      sNombre := ExtractFileName(sArchivo);
      if StartsText(sPrefijo, sNombre) and
         EndsText('_real.png', sNombre) then
      begin
        sIndice := Copy(sNombre, Length(sPrefijo) + 1,
          Length(sNombre) - Length(sPrefijo) - Length('_real.png'));
        if TryStrToInt(sIndice, iIndice) and (iIndice > 0) then
          oLista.Add(sArchivo);
      end;
    end;
    oLista.Sort;
    Result := oLista.ToStringArray;
  finally
    FreeAndNil(oLista);
  end;
end;

end.
