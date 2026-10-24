unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.NetEncoding, System.Hash,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Mask, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  System.Net.HttpClient, System.Net.URLClient, System.Net.Mime;

type
  TForm1 = class(TForm)
    pcMain: TPageControl;
    tsSubir: TTabSheet;
    tsVer: TTabSheet;

    // --- Pestaña Subir ---
    edUrl: TLabeledEdit;
    edKey: TLabeledEdit;
    edCarpetaCliente: TLabeledEdit;
    edNombre: TLabeledEdit;
    edArchivo: TLabeledEdit;
    btnSel: TButton;
    btnSubir: TButton;
    mLogs: TMemo;

    // --- Pestaña Ver ---
    edUrlVer: TLabeledEdit;
    edKeyVer: TLabeledEdit;
    edCarpetaClienteVer: TLabeledEdit;
    edNombreVer: TLabeledEdit;
    cbResolucion: TComboBox;
    lblResolucion: TLabel;
    btnVer: TButton;
    imgFoto: TImage;
    mLogsVer: TMemo;

    procedure btnSelClick(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnVerClick(Sender: TObject);
    procedure HTTPValidateServerCertificate(const Sender: TObject;
      const ARequest: TURLRequest; const Certificate: TCertificate;
      var Accepted: Boolean);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
  cMascaraImagenes = '*.jpg;*.jpeg;*.png;*.gif;*.webp';
  cMascaraTodosArchivos = '*.*';

resourcestring
  SFiltroSeleccionImagen =
    'Imágenes (%s)|%s|Todos los archivos (%s)|%s';

// ----------------------------------------------------------------------
// Aceptar certificados autofirmados (solo para pruebas)
// ----------------------------------------------------------------------
procedure TForm1.HTTPValidateServerCertificate(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

// ----------------------------------------------------------------------
// Seleccionar archivo
// ----------------------------------------------------------------------
procedure TForm1.btnSelClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Filter := Format(SFiltroSeleccionImagen,
      [cMascaraImagenes, cMascaraImagenes,
       cMascaraTodosArchivos, cMascaraTodosArchivos]);
    if OpenDlg.Execute then
      edArchivo.Text := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;
end;

// ----------------------------------------------------------------------
// Subir foto
// ----------------------------------------------------------------------
procedure TForm1.btnSubirClick(Sender: TObject);
var
  HTTP: THTTPClient;
  Form: TMultipartFormData;
  Res: IHTTPResponse;
  Response: TStringStream;
begin
  if not FileExists(edArchivo.Text) then
  begin
    mLogs.Lines.Add('Archivo no existe: ' + edArchivo.Text);
    Exit;
  end;

  if Trim(edCarpetaCliente.Text) = '' then
  begin
    mLogs.Lines.Add('Falta la carpeta_cliente.');
    Exit;
  end;

  if Trim(edNombre.Text) = '' then
  begin
    mLogs.Lines.Add('Falta el nombre.');
    Exit;
  end;

  HTTP := THTTPClient.Create;
  Form := TMultipartFormData.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key'] := edKey.Text;

    Form.AddField('nombre',          edNombre.Text);
    Form.AddField('carpeta_cliente', edCarpetaCliente.Text);
    Form.AddFile ('imagen',          edArchivo.Text);

    mLogs.Lines.Add('POST ' + edUrl.Text);
    Res := HTTP.Post(edUrl.Text, Form, Response);

    mLogs.Lines.Add(Format('HTTP %d %s', [Res.StatusCode, Res.StatusText]));
    mLogs.Lines.Add('--- Respuesta ---');
    mLogs.Lines.Add(Response.DataString);
    mLogs.Lines.Add('');
  finally
    Response.Free;
    Form.Free;
    HTTP.Free;
  end;
end;

// ----------------------------------------------------------------------
// Ver foto
// ----------------------------------------------------------------------
procedure TForm1.btnVerClick(Sender: TObject);
function CalcularSHA1Stream(Stream: TStream): string;
const
  BUFFER_SIZE = 64 * 1024;
var
  Hash: THashSHA1;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Hash := THashSHA1.Create;
  SetLength(Buffer, BUFFER_SIZE);
  Stream.Position := 0;
  repeat
    BytesRead := Stream.Read(Buffer[0], BUFFER_SIZE);
    if BytesRead > 0 then
      Hash.Update(Buffer[0], BytesRead);
  until BytesRead = 0;
  Result := Hash.HashAsString;
end;
var
  HTTP: THTTPClient;
  Res: IHTTPResponse;
  Stream: TMemoryStream;
  ErrStream: TStringStream;
  PNG: TPngImage;
  Url, Nombre, Resolucion, Carpeta: string;
  HashLocal, HashServer: string;
begin
  Nombre     := Trim(edNombreVer.Text);
  Resolucion := Trim(cbResolucion.Text);
  Carpeta    := Trim(edCarpetaClienteVer.Text);

  if (Nombre = '') or (Resolucion = '') or (Carpeta = '') then
  begin
    mLogsVer.Lines.Add('Falta nombre, resolución o carpeta_cliente.');
    Exit;
  end;

  Url := edUrlVer.Text +
         '?nombre='          + TNetEncoding.URL.Encode(Nombre) +
         '&resolucion='      + TNetEncoding.URL.Encode(Resolucion) +
         '&carpeta_cliente=' + TNetEncoding.URL.Encode(Carpeta);

  HTTP   := THTTPClient.Create;
  Stream := TMemoryStream.Create;
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key']  := edKeyVer.Text;

    mLogsVer.Lines.Add('GET ' + Url);
    Res := HTTP.Get(Url, Stream);
    mLogsVer.Lines.Add(Format('HTTP %d %s', [Res.StatusCode, Res.StatusText]));

    if Res.StatusCode <> 200 then
    begin
      Stream.Position := 0;
      ErrStream := TStringStream.Create('', TEncoding.UTF8);
      try
        ErrStream.CopyFrom(Stream, 0);
        mLogsVer.Lines.Add('Respuesta: ' + ErrStream.DataString);
      finally
        ErrStream.Free;
      end;
      Exit;
    end;

    HashServer := LowerCase(Trim(Res.HeaderValue['X-Content-SHA1']));
    if HashServer <> '' then
    begin
      HashLocal := LowerCase(CalcularSHA1Stream(Stream));
      if HashLocal <> HashServer then
      begin
        mLogsVer.Lines.Add('¡SHA1 no coincide! Imagen corrupta o alterada.');
        Exit;
      end;
      mLogsVer.Lines.Add('SHA1 verificado: ' + HashServer);
    end;

    // Cargar PNG en el TImage
    Stream.Position := 0;
    PNG := TPngImage.Create;
    try
      PNG.LoadFromStream(Stream);
      imgFoto.Picture.Assign(PNG);
    finally
      PNG.Free;
    end;

    mLogsVer.Lines.Add('Imagen cargada correctamente.');
    mLogsVer.Lines.Add('');
  finally
    Stream.Free;
    HTTP.Free;
  end;
end;

end.
