unit UFotoUploader;

// ----------------------------------------------------------------------
// UFotoUploader
// Lógica de subida de UNA foto al servidor PHP. Sin VCL.
// Pensado para correr dentro de tareas OmniThreadLibrary: cada llamada
// crea su propio THTTPClient (cada hilo SU instancia).
//
// La decisión de "saltar si ya existe" se toma ANTES de llamar aquí,
// usando el inventario que devuelve listar_fotos.php (ver UPrincipal).
// Este worker solo sube.
// ----------------------------------------------------------------------

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.JSON,
  System.Net.HttpClient, System.Net.URLClient, System.Net.Mime;

type
  TFotoUploadStatus = (fusOK, fusError);

  TFotoUploadResult = record
    Articulo  : string;
    Color     : string;
    Indice    : Integer;
    Archivo   : string;
    Status    : TFotoUploadStatus;
    Mensaje   : string;
    SHA1Local : string;   // SHA1 del archivo local original
    SHA1Server: string;   // SHA1 del PNG _real procesado por el servidor
  end;

  TFotoUploadConfig = record
    UrlUpload      : string;
    ApiKey         : string;
    CarpetaCliente : string;
    PrefijoLocal   : string;
  end;

  // Callback de progreso por hilo. Lo invoca el worker desde su hilo;
  // el receptor (UI) debe re-encolar al hilo principal si lo necesita.
  // - Slot:        identificador estable del hilo (0..N-1)
  // - Archivo:     ruta o nombre del fichero que está subiendo
  // - BytesSent:   bytes ya enviados
  // - BytesTotal:  bytes totales (0 si desconocido)
  // - Fase:        'start' | 'sending' | 'done' | 'error'
  TFotoUploadProgress = reference to procedure(
    Slot: Integer;
    const Archivo: string;
    BytesSent, BytesTotal: Int64;
    const Fase: string);

function CalcularSHA1Archivo(const FileName: string): string;

function CalcularSubcarpeta(const RutaCompleta, CarpetaBase: string): string;

function SubirFoto(const Cfg: TFotoUploadConfig;
                   const Articulo, Color: string;
                   Indice: Integer;
                   const NombreArchivoSinPrefijo: string;
                   const SHA1LocalYaCalculado: string = '';
                   Slot: Integer = -1;
                   OnProgress: TFotoUploadProgress = nil): TFotoUploadResult;

implementation

// ----------------------------------------------------------------------
// Helper para aceptar certificados autofirmados y canalizar el progreso
// del HTTPClient hacia el callback del usuario.
// ----------------------------------------------------------------------
type
  TCertHelper = class
    Slot       : Integer;
    Archivo    : string;
    OnProgress : TFotoUploadProgress;
    procedure Accept(const Sender: TObject; const ARequest: TURLRequest;
      const Certificate: TCertificate; var Accepted: Boolean);
    procedure SendData(const Sender: TObject; AContentLength: Int64;
      AWriteCount: Int64; var AAbort: Boolean);
  end;

procedure TCertHelper.Accept(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

procedure TCertHelper.SendData(const Sender: TObject;
  AContentLength: Int64; AWriteCount: Int64; var AAbort: Boolean);
begin
  if Assigned(OnProgress) then
    OnProgress(Slot, Archivo, AWriteCount, AContentLength, 'sending');
end;

// ----------------------------------------------------------------------
function CalcularSHA1Archivo(const FileName: string): string;
const
  BUFFER_SIZE = 64 * 1024;
var
  Hash: THashSHA1;
  Stream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Hash := THashSHA1.Create;
  SetLength(Buffer, BUFFER_SIZE);
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    repeat
      BytesRead := Stream.Read(Buffer[0], BUFFER_SIZE);
      if BytesRead > 0 then
        Hash.Update(Buffer[0], BytesRead);
    until BytesRead = 0;
  finally
    Stream.Free;
  end;
  Result := LowerCase(Hash.HashAsString);
end;

// ----------------------------------------------------------------------
// Devuelve la subcarpeta entre la carpeta base y el fichero.
//   RutaCompleta = 'C:\FOTOS\temporada121\proveedor12\art.jpg'
//   CarpetaBase  = 'C:\FOTOS'   (con o sin barra final)
//   Resultado    = 'temporada121\proveedor12'
// Si no hay subcarpeta intermedia, devuelve ''.
// Si CarpetaBase no es prefijo de RutaCompleta, devuelve '' también
// (caso raro: protege contra inconsistencias).
// ----------------------------------------------------------------------
function CalcularSubcarpeta(const RutaCompleta, CarpetaBase: string): string;
var
  Base, Resto, Dir: string;
begin
  Result := '';
  if (RutaCompleta = '') or (CarpetaBase = '') then
    Exit;

  Base := CarpetaBase;
  if (Length(Base) > 0) and (Base[Length(Base)] <> PathDelim) then
    Base := Base + PathDelim;

  // ¿Es CarpetaBase prefijo de RutaCompleta? (case-insensitive en Windows)
  if AnsiCompareText(Copy(RutaCompleta, 1, Length(Base)), Base) <> 0 then
    Exit;

  Resto := Copy(RutaCompleta, Length(Base) + 1, MaxInt);
  Dir   := ExtractFilePath(Resto);
  // Dir viene con barra final; la quitamos
  if (Length(Dir) > 0) and (Dir[Length(Dir)] = PathDelim) then
    SetLength(Dir, Length(Dir) - 1);
  Result := Dir;
end;

// ----------------------------------------------------------------------
function SubirFoto(const Cfg: TFotoUploadConfig;
                   const Articulo, Color: string;
                   Indice: Integer;
                   const NombreArchivoSinPrefijo: string;
                   const SHA1LocalYaCalculado: string;
                   Slot: Integer;
                   OnProgress: TFotoUploadProgress): TFotoUploadResult;
var
  FileName: string;
  HTTP    : THTTPClient;
  Helper  : TCertHelper;
  Form    : TMultipartFormData;
  Res     : IHTTPResponse;
  Response: TStringStream;
  J       : TJSONObject;
  V       : TJSONValue;
  StatusV : string;
begin
  Result := Default(TFotoUploadResult);
  Result.Articulo := Articulo;
  Result.Color    := Color;
  Result.Indice   := Indice;
  Result.Status   := fusError;

  // Componer ruta local con prefijo
  FileName := Cfg.PrefijoLocal;
  if (FileName <> '') and (FileName[Length(FileName)] <> PathDelim) then
    FileName := FileName + PathDelim;
  FileName := FileName + NombreArchivoSinPrefijo;
  Result.Archivo := FileName;

  if not FileExists(FileName) then
  begin
    Result.Mensaje := 'Archivo local no encontrado';
    Exit;
  end;

  // SHA1 local (usar el ya calculado si nos lo pasaron, evita recalcular)
  if SHA1LocalYaCalculado <> '' then
    Result.SHA1Local := LowerCase(SHA1LocalYaCalculado)
  else
  begin
    try
      Result.SHA1Local := CalcularSHA1Archivo(FileName);
    except
      on E: Exception do
      begin
        Result.Mensaje := 'SHA1 local: ' + E.Message;
        Exit;
      end;
    end;
  end;

  // ---- Subir ----
  HTTP     := THTTPClient.Create;
  Helper   := TCertHelper.Create;
  Form     := TMultipartFormData.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Helper.Slot       := Slot;
    Helper.Archivo    := ExtractFileName(FileName);
    Helper.OnProgress := OnProgress;

    HTTP.OnValidateServerCertificate := Helper.Accept;
    HTTP.OnSendData                  := Helper.SendData;
    HTTP.CustomHeaders['X-API-Key']  := Cfg.ApiKey;
    HTTP.ConnectionTimeout := 30000;
    HTTP.ResponseTimeout   := 120000;

    Form.AddField('articulo',        Articulo);
    Form.AddField('color',           Color);
    Form.AddField('indice',          IntToStr(Indice));
    Form.AddField('carpeta_cliente', Cfg.CarpetaCliente);
    Form.AddField('osha1',           Result.SHA1Local);
    Form.AddField('nombre_original', ExtractFileName(FileName));
    Form.AddField('carpeta_base',    Cfg.PrefijoLocal);
    Form.AddField('subcarpeta',      CalcularSubcarpeta(FileName, Cfg.PrefijoLocal));
    Form.AddField('ruta_completa',   FileName);
    Form.AddFile ('imagen',          FileName);

    // Notificar al UI que este slot acaba de empezar este archivo
    if Assigned(OnProgress) then
      OnProgress(Slot, Helper.Archivo, 0, 0, 'start');

    try
      Res := HTTP.Post(Cfg.UrlUpload, Form, Response);
    except
      on E: Exception do
      begin
        Result.Mensaje := 'Upload error: ' + E.Message;
        if Assigned(OnProgress) then
          OnProgress(Slot, Helper.Archivo, 0, 0, 'error');
        Exit;
      end;
    end;

    if Res.StatusCode <> 200 then
    begin
      Result.Mensaje := Format('Upload HTTP %d: %s',
                       [Res.StatusCode, Copy(Response.DataString, 1, 500)]);
      if Assigned(OnProgress) then
        OnProgress(Slot, Helper.Archivo, 0, 0, 'error');
      Exit;
    end;

    J := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
    if J = nil then
    begin
      Result.Mensaje := 'Upload: JSON inválido';
      Exit;
    end;
    try
      V := J.GetValue('status');
      if V = nil then
      begin
        Result.Mensaje := 'Upload: sin status';
        Exit;
      end;
      StatusV := V.Value;
      if StatusV <> 'success' then
      begin
        V := J.GetValue('message');
        if V <> nil then
          Result.Mensaje := 'Upload: ' + V.Value
        else
          Result.Mensaje := 'Upload: status=' + StatusV;
        Exit;
      end;
      V := J.GetValue('sha1');
      if V <> nil then
        Result.SHA1Server := LowerCase(V.Value);
    finally
      J.Free;
    end;
  finally
    Response.Free;
    Form.Free;
    Helper.Free;
    HTTP.Free;
  end;

  Result.Status  := fusOK;
  Result.Mensaje := 'Subida OK';
  if Assigned(OnProgress) then
    OnProgress(Slot, ExtractFileName(FileName), 1, 1, 'done');
end;

end.
