unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.NetEncoding, System.Hash, System.SyncObjs,
  System.Generics.Collections, System.JSON,
  System.IOUtils, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Mask, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  Vcl.FileCtrl,
  System.Net.HttpClient, System.Net.URLClient, System.Net.Mime,
  // UniDAC
  Uni, UniProvider, SQLServerUniProvider, DBAccess,
  // OmniThreadLibrary
  OtlCommon, OtlTask, OtlTaskControl, OtlParallel, OtlSync, OtlCollections,
  // Worker
  UFotoUploader;

type
  TFotoJob = record
    Articulo : string;
    Color    : string;
    Indice   : Integer;
    Archivo  : string;     // ruta sin prefijo, tal cual viene de la BD
    SHA1     : string;     // SHA1 del archivo LOCAL (ya calculado)
  end;

  TJobList = TList<TFotoJob>;

  TForm1 = class(TForm)
    pcMain: TPageControl;
    tsSubir: TTabSheet;
    tsVer: TTabSheet;
    tsBatch: TTabSheet;

    // --- Pestaña Subir ---
    edUrl: TLabeledEdit;
    edKey: TLabeledEdit;
    edCarpetaCliente: TLabeledEdit;
    edArticulo: TLabeledEdit;
    edColor: TLabeledEdit;
    edIndice: TLabeledEdit;
    edArchivo: TLabeledEdit;
    btnSel: TButton;
    btnSubir: TButton;
    mLogs: TMemo;

    // --- Pestaña Ver ---
    edUrlVer: TLabeledEdit;
    edKeyVer: TLabeledEdit;
    edCarpetaClienteVer: TLabeledEdit;
    edArticuloVer: TLabeledEdit;
    edColorVer: TLabeledEdit;
    edIndiceVer: TLabeledEdit;
    cbResolucion: TComboBox;
    lblResolucion: TLabel;
    btnVer: TButton;
    imgFoto: TImage;
    mLogsVer: TMemo;

    // --- Pestaña Batch ---
    edUrlBatch: TLabeledEdit;
    edUrlListBatch: TLabeledEdit;
    edKeyBatch: TLabeledEdit;
    edCarpetaClienteBatch: TLabeledEdit;
    edPrefijoLocal: TLabeledEdit;
    edSqlServer: TLabeledEdit;
    edSqlDatabase: TLabeledEdit;
    edSqlUser: TLabeledEdit;
    edSqlPassword: TLabeledEdit;
    chkSqlWindowsAuth: TCheckBox;
    lblConcurrencia: TLabel;
    cbConcurrencia: TComboBox;
    btnLanzar: TButton;
    btnCancelar: TButton;
    pbBatch: TProgressBar;
    sbSlots: TScrollBox;
    lblBatchStatus: TLabel;
    mLogsBatch: TMemo;
    edDemoCarpeta: TLabeledEdit;
    btnDemoSel: TButton;
    btnDemoLanzar: TButton;

    // --- Pestaña Backup ---
    tsBackup: TTabSheet;
    edUrlGenBackup: TLabeledEdit;
    edUrlEstadoBackup: TLabeledEdit;
    edKeyBackup: TLabeledEdit;
    edCarpetaClienteBackup: TLabeledEdit;
    edPasswordBackup: TLabeledEdit;
    btnGenerarBackup: TButton;
    pbBackup: TProgressBar;
    lblBackupStatus: TLabel;
    mLogsBackup: TMemo;
    tmrBackup: TTimer;

    procedure btnSelClick(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnVerClick(Sender: TObject);
    procedure btnLanzarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnDemoSelClick(Sender: TObject);
    procedure btnDemoLanzarClick(Sender: TObject);
    procedure btnGenerarBackupClick(Sender: TObject);
    procedure tmrBackupTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure HTTPValidateServerCertificate(const Sender: TObject;
      const ARequest: TURLRequest; const Certificate: TCertificate;
      var Accepted: Boolean);
  private
    FBatchJobs    : TJobList;       // solo lo que toca subir
    FBatchCancel  : IOmniCancellationToken;
    FBatchTotal   : Integer;
    FBatchOK      : Integer;
    FBatchSkipped : Integer;        // contadas en pre-filtrado
    FBatchError   : Integer;
    FBatchRunning : Boolean;
    // --- Visualización por hilo ---
    FSlotLabels   : array of TLabel;
    FSlotBars     : array of TProgressBar;
    FSlotFiles    : array of TLabel;
    FSlotsBox     : TScrollBox;
    // Backup
    FBackupJobId  : string;
    procedure LogBackup(const S: string);
    procedure LogBatch(const S: string);
    procedure ActualizarProgreso;
    procedure ProcesarResultado(const R: TFotoUploadResult);
    procedure BatchTerminado;
    procedure ConfigurarSlots(N: Integer);
    procedure LimpiarSlots;
    procedure ActualizarSlot(Slot: Integer; const Archivo: string;
                             BytesSent, BytesTotal: Int64; const Fase: string);
    procedure LanzarPoolFotos(const Cfg: TFotoUploadConfig; N: Integer;
                              OnEnd: TProc);
    function ObtenerInventarioServidor(const Url, ApiKey, Carpeta: string;
                                       Inv: TDictionary<string,string>;
                                       out ErrorMsg: string): Boolean;
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
  SPreguntaCancelarSubidaMasiva =
    'Hay una subida masiva en curso. ¿Cancelar y salir?';
  SPromptSeleccionarCarpetaFotosDemo = 'Carpeta con fotos para la demo';

// ----------------------------------------------------------------------
procedure TForm1.HTTPValidateServerCertificate(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

// ----------------------------------------------------------------------
procedure TForm1.FormCreate(Sender: TObject);
begin
  cbConcurrencia.Items.Clear;
  cbConcurrencia.Items.Add('5');
  cbConcurrencia.Items.Add('10');
  cbConcurrencia.Items.Add('15');
  cbConcurrencia.Items.Add('20');
  cbConcurrencia.ItemIndex := 0;

  btnCancelar.Enabled := False;

  FSlotsBox := sbSlots;

  tmrBackup.Enabled  := False;
  tmrBackup.Interval := 1000;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBatchRunning then
  begin
    if MessageDlg(SPreguntaCancelarSubidaMasiva,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if Assigned(FBatchCancel) then
        FBatchCancel.Signal;
      while FBatchRunning do
      begin
        Sleep(50);
        Application.ProcessMessages;
      end;
      CanClose := True;
    end
    else
      CanClose := False;
  end
  else
    CanClose := True;

  if CanClose then
    FreeAndNil(FBatchJobs);
end;

// ----------------------------------------------------------------------
// Pestaña SUBIR (sin cambios)
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

procedure TForm1.btnSubirClick(Sender: TObject);
var
  HTTP: THTTPClient;
  Form: TMultipartFormData;
  Res: IHTTPResponse;
  Response: TStringStream;
  Articulo, Color, Indice, OSha1: string;
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

  Articulo := Trim(edArticulo.Text);
  Color    := Trim(edColor.Text);
  Indice   := Trim(edIndice.Text);
  if Indice = '' then Indice := '1';

  if (Articulo = '') or (Color = '') then
  begin
    mLogs.Lines.Add('Falta artículo o color.');
    Exit;
  end;

  // SHA1 del archivo local (lo enviamos como osha1 para que el servidor
  // lo guarde y futuras subidas masivas puedan saltarse este registro)
  try
    OSha1 := CalcularSHA1Archivo(edArchivo.Text);
  except
    on E: Exception do
    begin
      mLogs.Lines.Add('Error SHA1 local: ' + E.Message);
      OSha1 := '';
    end;
  end;

  HTTP := THTTPClient.Create;
  Form := TMultipartFormData.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key'] := edKey.Text;

    Form.AddField('articulo',        Articulo);
    Form.AddField('color',           Color);
    Form.AddField('indice',          Indice);
    Form.AddField('carpeta_cliente', edCarpetaCliente.Text);
    if OSha1 <> '' then
      Form.AddField('osha1', OSha1);
    Form.AddField('nombre_original', ExtractFileName(edArchivo.Text));
    Form.AddField('carpeta_base',    ExtractFileDir(edArchivo.Text));
    Form.AddField('subcarpeta',      '');  // no aplica en subida individual
    Form.AddField('ruta_completa',   edArchivo.Text);
    Form.AddFile ('imagen', edArchivo.Text);

    mLogs.Lines.Add(Format('POST %s  ->  %s_%s_%s',
                    [edUrl.Text, Articulo, Color, Indice]));
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
// Pestaña VER (sin cambios)
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
  Url, Articulo, Color, Indice, Resolucion, Carpeta: string;
  HashLocal, HashServer: string;
begin
  Articulo   := Trim(edArticuloVer.Text);
  Color      := Trim(edColorVer.Text);
  Indice     := Trim(edIndiceVer.Text);
  if Indice = '' then Indice := '1';
  Resolucion := Trim(cbResolucion.Text);
  Carpeta    := Trim(edCarpetaClienteVer.Text);

  if (Articulo = '') or (Color = '') or (Resolucion = '') or (Carpeta = '') then
  begin
    mLogsVer.Lines.Add('Falta artículo, color, resolución o carpeta_cliente.');
    Exit;
  end;

  Url := edUrlVer.Text +
         '?articulo='        + TNetEncoding.URL.Encode(Articulo) +
         '&color='           + TNetEncoding.URL.Encode(Color) +
         '&indice='          + TNetEncoding.URL.Encode(Indice) +
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

// ----------------------------------------------------------------------
// Pestaña BATCH
// ----------------------------------------------------------------------

procedure TForm1.LogBatch(const S: string);
begin
  mLogsBatch.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

procedure TForm1.ActualizarProgreso;
var
  Hecho: Integer;
begin
  Hecho := FBatchOK + FBatchError;
  pbBatch.Position := Hecho;
  lblBatchStatus.Caption := Format(
    'Subidas %d/%d  |  OK: %d  |  Errores: %d  |  Saltadas previas: %d',
    [Hecho, FBatchTotal, FBatchOK, FBatchError, FBatchSkipped]);
end;

procedure TForm1.ProcesarResultado(const R: TFotoUploadResult);
var
  Linea: string;
begin
  case R.Status of
    fusOK:    Inc(FBatchOK);
    fusError: Inc(FBatchError);
  end;

  case R.Status of
    fusOK:
      Linea := Format('[OK]   %s / %s #%d  %s',
                      [R.Articulo, R.Color, R.Indice, R.Archivo]);
    fusError:
      Linea := Format('[ERR]  %s / %s #%d  %s  ->  %s',
                      [R.Articulo, R.Color, R.Indice, R.Archivo, R.Mensaje]);
  end;

  LogBatch(Linea);
  ActualizarProgreso;
end;

procedure TForm1.BatchTerminado;
begin
  LogBatch(Format(
    '== FIN ==  OK: %d   Errores: %d   (Saltadas en pre-filtro: %d)   Total subidas intentadas: %d',
    [FBatchOK, FBatchError, FBatchSkipped, FBatchTotal]));
  btnLanzar.Enabled   := True;
  btnCancelar.Enabled := False;
  FBatchRunning       := False;
  FBatchCancel        := nil;
  FreeAndNil(FBatchJobs);
end;

// ----------------------------------------------------------------------
// Pool de subida: N tareas independientes consumiendo de una cola.
// Este patrón sí paraleliza de verdad con OmniThreadLibrary, a
// diferencia de Parallel.ForEach sobre rango de enteros que puede
// asignar todos los items al primer worker si los demás aún no han
// arrancado.
//
// Crea N IOmniTaskControl. Cada tarea bucle:
//   - Toma un índice de la cola.
//   - Sube la foto FBatchJobs[index] llamando a SubirFoto del worker.
//   - Reenvía progreso y resultado al hilo principal con TThread.Queue.
// Cuando todas las tareas terminan, llama a OnEnd en el hilo principal.
// ----------------------------------------------------------------------
procedure TForm1.LanzarPoolFotos(const Cfg: TFotoUploadConfig; N: Integer;
                                 OnEnd: TProc);
var
  Cola : IOmniBlockingCollection;
  i    : Integer;
  Finalizadas: IOmniCounter;
begin
  // 1) Crear la cola y meter todos los índices
  Cola := TOmniBlockingCollection.Create;
  for i := 0 to FBatchJobs.Count - 1 do
    Cola.Add(i);
  Cola.CompleteAdding;  // así los consumidores saben cuándo parar

  // 2) Contador atómico de tareas finalizadas
  Finalizadas := CreateCounter(0);

  // 3) Lanzar N tareas trabajadoras
  for i := 0 to N - 1 do
  begin
    CreateTask(
      procedure (const task: IOmniTask)
      var
        Item   : TOmniValue;
        MySlot : Integer;
        Idx    : Integer;
        LocalJob: TFotoJob;
        R      : TFotoUploadResult;
        Restantes: Integer;
      begin
        // Slot = (id de tarea), estable durante toda su vida
        MySlot := task.Param['Slot'].AsInteger;

        while (not task.CancellationToken.IsSignalled) and
              Cola.Take(Item) do
        begin
          Idx := Item.AsInteger;
          if (Idx < 0) or (Idx >= FBatchJobs.Count) then
            Continue;

          LocalJob := FBatchJobs[Idx];

          try
            R := SubirFoto(
              Cfg,
              LocalJob.Articulo,
              LocalJob.Color,
              LocalJob.Indice,
              LocalJob.Archivo,
              LocalJob.SHA1,
              MySlot,
              procedure(Slot: Integer; const Archivo: string;
                        BytesSent, BytesTotal: Int64; const Fase: string)
              begin
                TThread.Queue(nil,
                  procedure
                  begin
                    ActualizarSlot(Slot, Archivo, BytesSent, BytesTotal, Fase);
                  end);
              end);
          except
            on E: Exception do
            begin
              R := Default(TFotoUploadResult);
              R.Articulo := LocalJob.Articulo;
              R.Color    := LocalJob.Color;
              R.Indice   := LocalJob.Indice;
              R.Archivo  := LocalJob.Archivo;
              R.Status   := fusError;
              R.Mensaje  := 'Excepción: ' + E.Message;
            end;
          end;

          TThread.Queue(nil,
            procedure
            begin
              ProcesarResultado(R);
            end);
        end;

        // Esta tarea ha terminado. ¿Soy la última? -> disparar OnEnd
        Restantes := Finalizadas.Increment;
        if Restantes >= task.Param['Total'].AsInteger then
          TThread.Queue(nil,
            procedure
            begin
              if Assigned(OnEnd) then OnEnd();
            end);
      end)
      .SetParameter('Slot',  i)
      .SetParameter('Total', N)
      .CancelWith(FBatchCancel)
      .Unobserved
      .Run;
  end;
end;

// ----------------------------------------------------------------------
// Slots de visualización por hilo
// ----------------------------------------------------------------------

procedure TForm1.LimpiarSlots;
var
  i: Integer;
begin
  for i := 0 to High(FSlotLabels) do FSlotLabels[i].Free;
  for i := 0 to High(FSlotBars)   do FSlotBars[i].Free;
  for i := 0 to High(FSlotFiles)  do FSlotFiles[i].Free;
  SetLength(FSlotLabels, 0);
  SetLength(FSlotBars,   0);
  SetLength(FSlotFiles,  0);
end;

procedure TForm1.ConfigurarSlots(N: Integer);
const
  ROW_H = 22;
  PAD   = 2;
var
  i, y : Integer;
begin
  LimpiarSlots;
  if FSlotsBox = nil then Exit;

  SetLength(FSlotLabels, N);
  SetLength(FSlotBars,   N);
  SetLength(FSlotFiles,  N);

  for i := 0 to N - 1 do
  begin
    y := i * (ROW_H + PAD) + 2;

    FSlotLabels[i] := TLabel.Create(Self);
    FSlotLabels[i].Parent     := FSlotsBox;
    FSlotLabels[i].Left       := 4;
    FSlotLabels[i].Top        := y + 4;
    FSlotLabels[i].Width      := 60;
    FSlotLabels[i].AutoSize   := False;
    FSlotLabels[i].Caption    := Format('Hilo %d', [i + 1]);

    FSlotBars[i] := TProgressBar.Create(Self);
    FSlotBars[i].Parent   := FSlotsBox;
    FSlotBars[i].Left     := 68;
    FSlotBars[i].Top      := y;
    FSlotBars[i].Width    := 280;
    FSlotBars[i].Height   := ROW_H;
    FSlotBars[i].Min      := 0;
    FSlotBars[i].Max      := 1000;
    FSlotBars[i].Position := 0;
    FSlotBars[i].Smooth   := True;

    FSlotFiles[i] := TLabel.Create(Self);
    FSlotFiles[i].Parent     := FSlotsBox;
    FSlotFiles[i].Left       := 356;
    FSlotFiles[i].Top        := y + 4;
    FSlotFiles[i].Width      := FSlotsBox.ClientWidth - 360;
    FSlotFiles[i].AutoSize   := False;
    FSlotFiles[i].EllipsisPosition := epPathEllipsis;
    FSlotFiles[i].Caption    := '(esperando)';
  end;

  FSlotsBox.VertScrollBar.Range := N * (ROW_H + PAD) + 8;
end;

procedure TForm1.ActualizarSlot(Slot: Integer; const Archivo: string;
                                BytesSent, BytesTotal: Int64;
                                const Fase: string);
var
  Pos: Integer;
begin
  if (Slot < 0) or (Slot > High(FSlotBars)) then Exit;

  if Fase = 'start' then
  begin
    FSlotFiles[Slot].Caption  := Archivo;
    FSlotBars[Slot].Position := 0;
    Exit;
  end;

  if Fase = 'done' then
  begin
    FSlotBars[Slot].Position := FSlotBars[Slot].Max;
    Exit;
  end;

  if Fase = 'error' then
  begin
    FSlotFiles[Slot].Caption := Archivo + '  (error)';
    FSlotBars[Slot].Position := 0;
    Exit;
  end;

  // 'sending'
  if BytesTotal > 0 then
  begin
    Pos := Round(BytesSent * FSlotBars[Slot].Max / BytesTotal);
    if Pos < 0 then Pos := 0;
    if Pos > FSlotBars[Slot].Max then Pos := FSlotBars[Slot].Max;
    FSlotBars[Slot].Position := Pos;
  end;
end;

// ----------------------------------------------------------------------
// Llama a listar_fotos.php y devuelve un diccionario:
//   nombre (p.ej. "A1234_ROJO_1")  ->  osha1 (SHA1 del archivo local
//   original con que se subió, vacío si no se registró).
// Solo nos interesa el osha1 para decidir si saltar o no.
// ----------------------------------------------------------------------
function TForm1.ObtenerInventarioServidor(const Url, ApiKey, Carpeta: string;
                                          Inv: TDictionary<string,string>;
                                          out ErrorMsg: string): Boolean;
var
  HTTP    : THTTPClient;
  Res     : IHTTPResponse;
  Stream  : TStringStream;
  FullUrl : string;
  Root    : TJSONObject;
  Fotos   : TJSONArray;
  Item    : TJSONValue;
  Obj     : TJSONObject;
  V       : TJSONValue;
  Nombre  : string;
  OSha1   : string;
begin
  Result   := False;
  ErrorMsg := '';
  FullUrl := Url + '?carpeta_cliente=' + TNetEncoding.URL.Encode(Carpeta);
  HTTP   := THTTPClient.Create;
  Stream := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key']  := ApiKey;
    HTTP.ConnectionTimeout := 15000;
    HTTP.ResponseTimeout   := 60000;
    try
      Res := HTTP.Get(FullUrl, Stream);
    except
      on E: Exception do
      begin
        ErrorMsg := E.Message;
        Exit;
      end;
    end;

    if Res.StatusCode <> 200 then
    begin
      ErrorMsg := Format('HTTP %d: %s',
                  [Res.StatusCode, Copy(Stream.DataString, 1, 300)]);
      Exit;
    end;

    Root := TJSONObject.ParseJSONValue(Stream.DataString) as TJSONObject;
    if Root = nil then
    begin
      ErrorMsg := 'JSON inválido';
      Exit;
    end;
    try
      V := Root.GetValue('fotos');
      if not (V is TJSONArray) then
      begin
        ErrorMsg := 'Sin array "fotos"';
        Exit;
      end;
      Fotos := TJSONArray(V);
      for Item in Fotos do
      begin
        if not (Item is TJSONObject) then Continue;
        Obj := TJSONObject(Item);

        V := Obj.GetValue('nombre');
        if V = nil then Continue;
        Nombre := V.Value;

        OSha1 := '';
        V := Obj.GetValue('osha1');
        if V <> nil then
          OSha1 := LowerCase(V.Value);

        Inv.AddOrSetValue(Nombre, OSha1);
      end;
      Result := True;
    finally
      Root.Free;
    end;
  finally
    Stream.Free;
    HTTP.Free;
  end;
end;

procedure TForm1.btnLanzarClick(Sender: TObject);
var
  Conn       : TUniConnection;
  Query      : TUniQuery;
  Job        : TFotoJob;
  Cfg        : TFotoUploadConfig;
  N          : Integer;
  Total      : Integer;
  Inventario : TDictionary<string,string>;
  ErrorMsg   : string;
  Nombre     : string;
  Archivo    : string;
  OSha1Srv   : string;
  SHA1Local  : string;
  TotalSql   : Integer;
  Faltantes  : Integer;
  Saltadas   : Integer;
  NoExisten  : Integer;
begin
  if FBatchRunning then
  begin
    LogBatch('Ya hay una subida en curso.');
    Exit;
  end;

  // ---- Validar parámetros ----
  Cfg.UrlUpload      := Trim(edUrlBatch.Text);
  Cfg.ApiKey         := Trim(edKeyBatch.Text);
  Cfg.CarpetaCliente := Trim(edCarpetaClienteBatch.Text);
  Cfg.PrefijoLocal   := Trim(edPrefijoLocal.Text);

  if (Cfg.UrlUpload = '') or (Trim(edUrlListBatch.Text) = '') or
     (Cfg.CarpetaCliente = '') or (Cfg.PrefijoLocal = '') then
  begin
    LogBatch('Faltan parámetros de configuración.');
    Exit;
  end;

  N := StrToIntDef(cbConcurrencia.Text, 5);
  if N < 1 then N := 1;
  if N > 50 then N := 50;

  mLogsBatch.Clear;
  FBatchOK      := 0;
  FBatchSkipped := 0;
  FBatchError   := 0;
  FBatchTotal   := 0;

  // ----------------------------------------------------------
  // PASO 1: inventario del servidor
  // ----------------------------------------------------------
  LogBatch('Pidiendo inventario al servidor...');
  Inventario := TDictionary<string,string>.Create;
  try
    if not ObtenerInventarioServidor(Trim(edUrlListBatch.Text),
                                     Cfg.ApiKey,
                                     Cfg.CarpetaCliente,
                                     Inventario,
                                     ErrorMsg) then
    begin
      LogBatch('No se pudo obtener inventario: ' + ErrorMsg);
      LogBatch('Abortando para no resubir lo que pueda ya existir.');
      Inventario.Free;
      Exit;
    end;
    LogBatch(Format('Inventario: %d fotos en servidor.', [Inventario.Count]));

    // ----------------------------------------------------------
    // PASO 2: SELECT en SQL Server
    // ----------------------------------------------------------
    FreeAndNil(FBatchJobs);
    FBatchJobs := TJobList.Create;

    Conn  := TUniConnection.Create(nil);
    Query := TUniQuery.Create(nil);
    try
      Conn.ProviderName := 'SQL Server';
      Conn.Server       := Trim(edSqlServer.Text);
      Conn.Database     := Trim(edSqlDatabase.Text);
      if chkSqlWindowsAuth.Checked then
        Conn.SpecificOptions.Values['AuthenticationType'] := 'auWindows'
      else
      begin
        Conn.Username := Trim(edSqlUser.Text);
        Conn.Password := edSqlPassword.Text;
      end;

      LogBatch('Conectando a SQL Server...');
      try
        Conn.Connect;
      except
        on E: Exception do
        begin
          LogBatch('Error conectando: ' + E.Message);
          FreeAndNil(FBatchJobs);
          Exit;
        end;
      end;

      Query.Connection := Conn;
      Query.SQL.Text :=
        'SELECT articulo, color, ArchivoFoto ' +
        'FROM ocartcol ' +
        'WHERE ArchivoFoto IS NOT NULL AND ArchivoFoto <> '''' ' +
        '  AND articulo IN (SELECT articulo FROM ocartacp WHERE UnidadesStock > 0)';
      try
        Query.Open;
      except
        on E: Exception do
        begin
          LogBatch('Error en SELECT: ' + E.Message);
          FreeAndNil(FBatchJobs);
          Exit;
        end;
      end;

      // ----------------------------------------------------------
      // PASO 3: filtrar contra el inventario
      // ----------------------------------------------------------
      TotalSql  := 0;
      Saltadas  := 0;
      NoExisten := 0;
      Faltantes := 0;

      while not Query.Eof do
      begin
        Inc(TotalSql);

        Job.Articulo := Trim(Query.FieldByName('articulo').AsString);
        Job.Color    := Trim(Query.FieldByName('color').AsString);
        Job.Indice   := 1;
        Job.Archivo  := Trim(Query.FieldByName('ArchivoFoto').AsString);

        if (Job.Articulo = '') or (Job.Color = '') or (Job.Archivo = '') then
        begin
          Query.Next;
          Continue;
        end;

        // Nombre interno que tendrá en el servidor
        Nombre := Job.Articulo + '_' + Job.Color + '_' + IntToStr(Job.Indice);

        // Ruta local con prefijo
        Archivo := Cfg.PrefijoLocal;
        if (Archivo <> '') and (Archivo[Length(Archivo)] <> PathDelim) then
          Archivo := Archivo + PathDelim;
        Archivo := Archivo + Job.Archivo;

        if not FileExists(Archivo) then
        begin
          Inc(NoExisten);
          LogBatch('[!] Falta local: ' + Archivo);
          Query.Next;
          Continue;
        end;

        // SHA1 del archivo local actual
        try
          SHA1Local := CalcularSHA1Archivo(Archivo);
        except
          on E: Exception do
          begin
            LogBatch('[!] Error SHA1 local de ' + Archivo + ': ' + E.Message);
            Inc(FBatchError);
            Query.Next;
            Continue;
          end;
        end;

        // ¿Está ya en el servidor con el mismo SHA1 de origen?
        if Inventario.TryGetValue(Nombre, OSha1Srv) and
           (OSha1Srv <> '') and (OSha1Srv = SHA1Local) then
        begin
          Inc(Saltadas);
          Query.Next;
          Continue;
        end;

        // Hay que subirla
        Job.SHA1 := SHA1Local;
        FBatchJobs.Add(Job);
        Inc(Faltantes);

        Query.Next;
      end;
    finally
      Query.Free;
      Conn.Free;
    end;
  finally
    Inventario.Free;
  end;

  FBatchSkipped := Saltadas;

  LogBatch(Format('SQL: %d filas  |  Saltadas (ya estaban): %d  |  Sin archivo local: %d  |  A subir: %d',
                  [TotalSql, Saltadas, NoExisten, Faltantes]));

  Total := FBatchJobs.Count;
  if Total = 0 then
  begin
    LogBatch('No hay nada que subir.');
    ActualizarProgreso;
    FreeAndNil(FBatchJobs);
    Exit;
  end;

  FBatchTotal      := Total;
  pbBatch.Min      := 0;
  pbBatch.Max      := Total;
  pbBatch.Position := 0;
  ActualizarProgreso;

  btnLanzar.Enabled   := False;
  btnCancelar.Enabled := True;
  FBatchRunning       := True;
  FBatchCancel        := CreateOmniCancellationToken;

  // Resetear las barras
  ConfigurarSlots(N);

  // ----------------------------------------------------------
  // PASO 4: lanzar pool OTL solo con lo que toca subir
  // ----------------------------------------------------------
  LanzarPoolFotos(Cfg, N,
    procedure
    begin
      BatchTerminado;
    end);
end;

procedure TForm1.btnCancelarClick(Sender: TObject);
begin
  if Assigned(FBatchCancel) then
  begin
    FBatchCancel.Signal;
    LogBatch('Cancelación solicitada...');
    btnCancelar.Enabled := False;
  end;
end;

// ----------------------------------------------------------------------
// DEMO: subir los PNGs (y demás imágenes) que haya en una carpeta,
// sin SQL Server. Útil para probar el multihilo.
// ----------------------------------------------------------------------

procedure TForm1.btnDemoSelClick(Sender: TObject);
var
  S: string;
begin
  S := edDemoCarpeta.Text;
  if SelectDirectory(SPromptSeleccionarCarpetaFotosDemo, '', S,
    [sdNewUI]) then
    edDemoCarpeta.Text := S;
end;

procedure TForm1.btnDemoLanzarClick(Sender: TObject);
const
  EXTS_OK: array[0..4] of string = ('.png', '.jpg', '.jpeg', '.webp', '.gif');
var
  CarpetaDemo : string;
  Ficheros    : TStringDynArray;
  Ext         : string;
  Job         : TFotoJob;
  Cfg         : TFotoUploadConfig;
  Inventario  : TDictionary<string,string>;
  ErrorMsg    : string;
  Nombre      : string;
  OSha1Srv    : string;
  SHA1Local   : string;
  Total       : Integer;
  Saltadas    : Integer;
  Faltantes   : Integer;
  ContadorArt : Integer;
  N           : Integer;
  i           : Integer;
  FicherosFlt : TList<string>;
  EsImagen    : Boolean;
  j           : Integer;
begin
  if FBatchRunning then
  begin
    LogBatch('Ya hay una subida en curso.');
    Exit;
  end;

  CarpetaDemo := Trim(edDemoCarpeta.Text);
  if (CarpetaDemo = '') or not System.SysUtils.DirectoryExists(CarpetaDemo) then
  begin
    LogBatch('Carpeta de demo inválida.');
    Exit;
  end;

  // Reusar los parámetros del batch normal
  Cfg.UrlUpload      := Trim(edUrlBatch.Text);
  Cfg.ApiKey         := Trim(edKeyBatch.Text);
  Cfg.CarpetaCliente := Trim(edCarpetaClienteBatch.Text);
  // En la demo el "prefijo local" es la propia carpeta de demo
  Cfg.PrefijoLocal   := CarpetaDemo;

  if (Cfg.UrlUpload = '') or (Trim(edUrlListBatch.Text) = '') or
     (Cfg.CarpetaCliente = '') then
  begin
    LogBatch('Faltan parámetros (URL, carpeta_cliente).');
    Exit;
  end;

  N := StrToIntDef(cbConcurrencia.Text, 5);
  if N < 1 then N := 1;
  if N > 50 then N := 50;

  mLogsBatch.Clear;
  FBatchOK      := 0;
  FBatchSkipped := 0;
  FBatchError   := 0;
  FBatchTotal   := 0;

  // ---- Listar ficheros (recursivo) ----
  LogBatch('Escaneando ' + CarpetaDemo + ' ...');
  try
    Ficheros := TDirectory.GetFiles(CarpetaDemo, '*.*',
                                    TSearchOption.soAllDirectories);
  except
    on E: Exception do
    begin
      LogBatch('Error escaneando carpeta: ' + E.Message);
      Exit;
    end;
  end;

  // Filtrar por extensión soportada
  FicherosFlt := TList<string>.Create;
  try
    for i := 0 to High(Ficheros) do
    begin
      Ext := LowerCase(ExtractFileExt(Ficheros[i]));
      EsImagen := False;
      for j := Low(EXTS_OK) to High(EXTS_OK) do
        if Ext = EXTS_OK[j] then
        begin
          EsImagen := True;
          Break;
        end;
      if EsImagen then
        FicherosFlt.Add(Ficheros[i]);
    end;

    LogBatch(Format('Encontradas %d imágenes.', [FicherosFlt.Count]));
    if FicherosFlt.Count = 0 then
    begin
      LogBatch('No hay imágenes que subir.');
      Exit;
    end;

    // ---- Inventario del servidor ----
    LogBatch('Pidiendo inventario al servidor...');
    Inventario := TDictionary<string,string>.Create;
    try
      if not ObtenerInventarioServidor(Trim(edUrlListBatch.Text),
                                       Cfg.ApiKey,
                                       Cfg.CarpetaCliente,
                                       Inventario,
                                       ErrorMsg) then
      begin
        LogBatch('No se pudo obtener inventario: ' + ErrorMsg);
        LogBatch('Abortando para no resubir lo que pueda ya existir.');
        Exit;
      end;
      LogBatch(Format('Inventario: %d fotos en servidor.', [Inventario.Count]));

      // ---- Montar jobs con DEMO1, DEMO2... ----
      FreeAndNil(FBatchJobs);
      FBatchJobs  := TJobList.Create;
      ContadorArt := 0;
      Saltadas    := 0;
      Faltantes   := 0;

      for i := 0 to FicherosFlt.Count - 1 do
      begin
        Inc(ContadorArt);
        Job.Articulo := 'DEMO' + IntToStr(ContadorArt);
        Job.Color    := 'SINCOLOR';
        Job.Indice   := 1;

        // Archivo se pasa al worker como "ruta sin prefijo"; ya que
        // PrefijoLocal = CarpetaDemo, le pasamos solo la parte relativa.
        Job.Archivo := Copy(FicherosFlt[i],
                            Length(CarpetaDemo) + 1,
                            MaxInt);
        if (Length(Job.Archivo) > 0) and (Job.Archivo[1] = PathDelim) then
          Delete(Job.Archivo, 1, 1);

        // SHA1 local
        try
          SHA1Local := CalcularSHA1Archivo(FicherosFlt[i]);
        except
          on E: Exception do
          begin
            LogBatch('[!] SHA1 falló: ' + FicherosFlt[i] + ' -> ' + E.Message);
            Inc(FBatchError);
            Continue;
          end;
        end;

        Nombre := Job.Articulo + '_' + Job.Color + '_' + IntToStr(Job.Indice);

        // ¿Ya está y coincide?
        if Inventario.TryGetValue(Nombre, OSha1Srv) and
           (OSha1Srv <> '') and (OSha1Srv = SHA1Local) then
        begin
          Inc(Saltadas);
          Continue;
        end;

        Job.SHA1 := SHA1Local;
        FBatchJobs.Add(Job);
        Inc(Faltantes);
      end;
    finally
      Inventario.Free;
    end;
  finally
    FicherosFlt.Free;
  end;

  FBatchSkipped := Saltadas;
  LogBatch(Format(
    'DEMO: %d imágenes  |  Saltadas: %d  |  A subir: %d  |  Concurrencia: %d',
    [FBatchSkipped + Faltantes, Saltadas, Faltantes, N]));

  Total := FBatchJobs.Count;
  if Total = 0 then
  begin
    LogBatch('No hay nada que subir.');
    ActualizarProgreso;
    FreeAndNil(FBatchJobs);
    Exit;
  end;

  FBatchTotal      := Total;
  pbBatch.Min      := 0;
  pbBatch.Max      := Total;
  pbBatch.Position := 0;
  ActualizarProgreso;

  btnLanzar.Enabled     := False;
  btnDemoLanzar.Enabled := False;
  btnCancelar.Enabled   := True;
  FBatchRunning         := True;
  FBatchCancel          := CreateOmniCancellationToken;

  // Resetear las barras
  ConfigurarSlots(N);

  // ---- Pool OTL ----
  LanzarPoolFotos(Cfg, N,
    procedure
    begin
      BatchTerminado;
      btnDemoLanzar.Enabled := True;
    end);
end;

// ----------------------------------------------------------------------
// Pestaña BACKUP
// ----------------------------------------------------------------------

procedure TForm1.LogBackup(const S: string);
begin
  mLogsBackup.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

procedure TForm1.btnGenerarBackupClick(Sender: TObject);
var
  HTTP    : THTTPClient;
  Form    : TMultipartFormData;
  Res     : IHTTPResponse;
  Response: TStringStream;
  J       : TJSONObject;
  V       : TJSONValue;
  Carpeta, Pwd: string;
begin
  Carpeta := Trim(edCarpetaClienteBackup.Text);
  Pwd     := edPasswordBackup.Text;

  if (Carpeta = '') or (Pwd = '') then
  begin
    LogBackup('Falta carpeta_cliente o password.');
    Exit;
  end;

  if Trim(edUrlGenBackup.Text) = '' then
  begin
    LogBackup('Falta URL de generar_backup.');
    Exit;
  end;

  mLogsBackup.Clear;
  pbBackup.Position := 0;
  lblBackupStatus.Caption := 'Lanzando...';
  btnGenerarBackup.Enabled := False;
  HTTP     := THTTPClient.Create;
  Form     := TMultipartFormData.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key']  := edKeyBackup.Text;
    HTTP.ConnectionTimeout := 30000;
    HTTP.ResponseTimeout   := 60000;

    Form.AddField('carpeta_cliente', Carpeta);
    Form.AddField('password',        Pwd);
    LogBackup('POST ' + edUrlGenBackup.Text);
    try
      Res := HTTP.Post(edUrlGenBackup.Text, Form, Response);
    except
      on E: Exception do
      begin
        LogBackup('Error: ' + E.Message);
        btnGenerarBackup.Enabled := True;
        Exit;
      end;
    end;
    if Res.StatusCode <> 200 then
    begin
      LogBackup(Format('HTTP %d: %s',
                [Res.StatusCode, Copy(Response.DataString, 1, 300)]));
      btnGenerarBackup.Enabled := True;
      Exit;
    end;
    J := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
    if J = nil then
    begin
      LogBackup('Respuesta no es JSON: ' + Response.DataString);
      btnGenerarBackup.Enabled := True;
      Exit;
    end;
    try
      V := J.GetValue('job_id');
      if V = nil then
      begin
        LogBackup('No hay job_id en la respuesta.');
        btnGenerarBackup.Enabled := True;
        Exit;
      end;
      FBackupJobId := V.Value;
      LogBackup('Job lanzado: ' + FBackupJobId);
      V := J.GetValue('archivo');
      if V <> nil then
        LogBackup('Archivo destino: ' + V.Value);
    finally
      J.Free;
    end;
  finally
    Response.Free;
    Form.Free;
    HTTP.Free;
  end;
  // Arrancar polling cada segundo
  tmrBackup.Enabled := True;
end;

procedure TForm1.tmrBackupTimer(Sender: TObject);
var
  HTTP    : THTTPClient;
  Res     : IHTTPResponse;
  Response: TStringStream;
  Url     : string;
  J       : TJSONObject;
  V       : TJSONValue;
  Status, Mensaje, Archivo, ErrorMsg: string;
  Progress, Total: Integer;
begin
  if FBackupJobId = '' then
  begin
    tmrBackup.Enabled := False;
    Exit;
  end;
  Url := Trim(edUrlEstadoBackup.Text) +
         '?job_id=' + TNetEncoding.URL.Encode(FBackupJobId);
  HTTP     := THTTPClient.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key']  := edKeyBackup.Text;
    HTTP.ConnectionTimeout := 10000;
    HTTP.ResponseTimeout   := 15000;
    try
      Res := HTTP.Get(Url, Response);
    except
      on E: Exception do
      begin
        LogBackup('Polling error: ' + E.Message);
        Exit;
      end;
    end;
    if Res.StatusCode <> 200 then
    begin
      LogBackup(Format('Polling HTTP %d', [Res.StatusCode]));
      Exit;
    end;
    J := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
    if J = nil then Exit;
    try
      Status   := ''; Mensaje := ''; Archivo := ''; ErrorMsg := '';
      Progress := 0;  Total := 0;
      V := J.GetValue('status');
      if V <> nil then
        Status   := V.Value;
      V := J.GetValue('mensaje');
      if V <> nil then
        Mensaje  := V.Value;
      V := J.GetValue('archivo');
      if V <> nil then
        Archivo  := V.Value;
      V := J.GetValue('error');
      if (V <> nil) and not (V is TJSONNull) then
        ErrorMsg := V.Value;
      V := J.GetValue('progress');
      if (V <> nil) and (V is TJSONNumber) then
        Progress := TJSONNumber(V).AsInt;
      V := J.GetValue('total');
      if (V <> nil) and (V is TJSONNumber) then
        Total    := TJSONNumber(V).AsInt;
      if (Total > 0) then
      begin
        pbBackup.Max := Total;
        pbBackup.Position := Progress;
      end;
      lblBackupStatus.Caption := Format('[%s] %s  (%d/%d)',
                                        [Status, Mensaje, Progress, Total]);
      if Status = 'done' then
      begin
        tmrBackup.Enabled := False;
        btnGenerarBackup.Enabled := True;
        LogBackup('TERMINADO. Archivo: ' + Archivo);
        FBackupJobId := '';
      end
      else if Status = 'error' then
      begin
        tmrBackup.Enabled := False;
        btnGenerarBackup.Enabled := True;
        LogBackup('ERROR: ' + ErrorMsg);
        FBackupJobId := '';
      end;
    finally
      J.Free;
    end;
  finally
    Response.Free;
    HTTP.Free;
  end;
end;

end.
