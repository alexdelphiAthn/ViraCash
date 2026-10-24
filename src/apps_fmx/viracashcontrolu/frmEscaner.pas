unit frmEscaner;

{
  Pantalla de escaneo de codigos EAN-8 y EAN-13 con la camara.

  Ajustado para Delphi 13 Florence:
  - Las firmas usan TClassicStringDynArray (System.Types) y
    TClassicPermissionStatusDynArray (System.Permissions), que son los
    tipos exactos que espera la sobrecarga anonimo de RequestPermissions.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Permissions, System.Generics.Collections, System.Math,
  System.SyncObjs, System.Threading,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Media, FMX.Graphics,
  FMX.DialogService,
  {$IFDEF ANDROID}
  Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes,
  {$ENDIF}
  ZXing.ScanManager, ZXing.BarcodeFormat, ZXing.ReadResult,
  ZXing.DecodeHintType;

type
  TCodigoEscaneadoEvent = procedure(const Codigo: string) of object;
  TEscanerOcultadoEvent = procedure of object;

  TFormEscaner = class(TForm)
    pnlTop: TPanel;
    btnCancelar: TButton;
    lblEstado: TLabel;
    imgPreview: TImage;
    pnlBottom: TPanel;
    btnCapturar: TButton;
    btnLinterna: TButton;
    cam: TCameraComponent;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnCapturarClick(Sender: TObject);
    procedure btnLinternaClick(Sender: TObject);
    procedure camSampleBufferReady(Sender: TObject; const ATime: TMediaTime);
  private
    FOnCodigoEscaneado: TCodigoEscaneadoEvent;
    FOnEscanerOcultado: TEscanerOcultadoEvent;
    FScanManager: TScanManager;
    FActiva: Boolean;
    FDecodificando: Integer;
    FGeneracion: Integer;
    FPeticionManual: Integer;
    FTareaEscaneo: ITask;
    FUltimaPrevisualizacion: UInt64;
    FUltimoEscaneo: UInt64;
    FUltimoCodigo: string;
    FPrimerFotograma: Boolean;
    FSoportaLinterna: Boolean;
    FLinternaEncendida: Boolean;
    procedure AplicarCodigo(const Codigo: string);
    procedure ActivarCamara;
    procedure ActualizarBotonLinterna;
    procedure ActualizarDisposicion;
    procedure ApagarLinterna;
    procedure DesactivarCamara;
    procedure DetectarLinterna;
    procedure IniciarDecodificacion(const Forzada: Boolean);
    procedure OcultarEscaner;
    procedure ProcesarSampleBuffer;
    {$IFDEF ANDROID}
    procedure SinPermiso;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    property OnCodigoEscaneado: TCodigoEscaneadoEvent
      read FOnCodigoEscaneado write FOnCodigoEscaneado;
    property OnEscanerOcultado: TEscanerOcultadoEvent
      read FOnEscanerOcultado write FOnEscanerOcultado;
  end;

var
  FormEscaner: TFormEscaner;

implementation

{$R *.fmx}

uses
  TraduccionMovil;

constructor TFormEscaner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TraducirFormulario(Self);
end;

procedure TFormEscaner.FormShow(Sender: TObject);
var
  Formatos: TList<TBarcodeFormat>;
  OpcionesEscaneo: TDictionary<TDecodeHintType, TObject>;
begin
  TInterlocked.Increment(FGeneracion);
  FActiva := True;
  TInterlocked.Exchange(FPeticionManual, 0);
  FUltimoCodigo := '';
  FUltimaPrevisualizacion := 0;
  FUltimoEscaneo := 0;
  FPrimerFotograma := False;
  FSoportaLinterna := False;
  FLinternaEncendida := False;
  lblEstado.Text := Tr('Apunta al código de barras');
  ActualizarBotonLinterna;
  ActualizarDisposicion;

  if FScanManager = nil then
  begin
    Formatos := TList<TBarcodeFormat>.Create;
    OpcionesEscaneo := TDictionary<TDecodeHintType, TObject>.Create;
    try
      Formatos.Add(TBarcodeFormat.EAN_13);
      Formatos.Add(TBarcodeFormat.EAN_8);
      OpcionesEscaneo.Add(
        TDecodeHintType.POSSIBLE_FORMATS,
        Formatos);
      Formatos := nil;
      FScanManager := TScanManager.Create(
        TBarcodeFormat.Auto,
        OpcionesEscaneo);
      OpcionesEscaneo := nil;
    finally
      Formatos.Free;
      OpcionesEscaneo.Free;
    end;
  end;

  {$IFDEF ANDROID}
  PermissionsService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.CAMERA)],
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) >= 1) and
         (AGrantResults[0] = TPermissionStatus.Granted) then
        ActivarCamara
      else
        SinPermiso;
    end,
    procedure(const APermissions: TClassicStringDynArray;
              const APostRationaleProc: TProc)
    begin
      // Mostrar al usuario por que necesitamos la camara, y luego
      // llamar a APostRationaleProc para que aparezca el dialogo del SO
      TDialogService.ShowMessage(
        Tr('ViraCash necesita acceso a la cámara para escanear códigos.'),
        procedure(const AResult: TModalResult)
        begin
          APostRationaleProc;
        end);
    end
  );
  {$ELSE}
  ActivarCamara;
  {$ENDIF}
end;

{$IFDEF ANDROID}
procedure TFormEscaner.SinPermiso;
begin
  lblEstado.Text := Tr('Sin permiso de cámara');
  TDialogService.ShowMessage(
    Tr('ViraCash necesita permiso de cámara para escanear códigos.'));
end;
{$ENDIF}

procedure TFormEscaner.ActivarCamara;
begin
  try
    cam.Kind := FMX.Media.TCameraKind.BackCamera;
    cam.CaptureSettingPriority :=
      FMX.Media.TVideoCaptureSettingPriority.Resolution;
    if not cam.SetCaptureSetting(
      FMX.Media.TVideoCaptureSetting.Create(1280, 720, 24)) then
      cam.Quality := FMX.Media.TVideoCaptureQuality.MediumQuality;
    cam.FocusMode := FMX.Media.TFocusMode.ContinuousAutoFocus;
    cam.Active := True;
  except
    on E: Exception do
      lblEstado.Text := TrF('Error de cámara: %s', [E.Message]);
  end;
end;

procedure TFormEscaner.ActualizarBotonLinterna;
begin
  btnLinterna.Enabled := FActiva and FPrimerFotograma and
    FSoportaLinterna;
  if not FPrimerFotograma then
    btnLinterna.Text := Tr('Linterna OFF')
  else if not FSoportaLinterna then
    btnLinterna.Text := Tr('Sin linterna')
  else if FLinternaEncendida then
    btnLinterna.Text := Tr('Linterna ON')
  else
    btnLinterna.Text := Tr('Linterna OFF');
end;

procedure TFormEscaner.ActualizarDisposicion;
var
  AnchoBotones: Single;
  AnchoGrupo: Single;
  MargenIzquierdo: Single;
begin
  btnCancelar.Position.X := 8;
  btnCancelar.Position.Y := 10;
  lblEstado.Position.X := btnCancelar.Position.X +
    btnCancelar.Width + 8;
  lblEstado.Width := Max(80, pnlTop.Width - lblEstado.Position.X - 8);

  AnchoGrupo := Min(480, Max(240, pnlBottom.Width - 24));
  AnchoBotones := (AnchoGrupo - 8) / 2;
  MargenIzquierdo := (pnlBottom.Width - AnchoGrupo) / 2;
  btnCapturar.Position.X := MargenIzquierdo;
  btnCapturar.Width := AnchoBotones;
  btnLinterna.Position.X := MargenIzquierdo + AnchoBotones + 8;
  btnLinterna.Width := AnchoBotones;
end;

procedure TFormEscaner.ApagarLinterna;
begin
  if FLinternaEncendida and FPrimerFotograma and cam.Active then
  begin
    try
      cam.TorchMode := FMX.Media.TTorchMode.ModeOff;
      FLinternaEncendida := False;
    except
      on E: Exception do
        lblEstado.Text := TrF('No se pudo apagar la linterna: %s',
          [E.Message]);
    end;
  end;
  ActualizarBotonLinterna;
end;

procedure TFormEscaner.DesactivarCamara;
begin
  ApagarLinterna;
  if Assigned(cam) and cam.Active then
    cam.Active := False;
  FPrimerFotograma := False;
  FSoportaLinterna := False;
  FLinternaEncendida := False;
  ActualizarBotonLinterna;
end;

procedure TFormEscaner.DetectarLinterna;
begin
  FSoportaLinterna := False;
  try
    if cam.Active then
      FSoportaLinterna := cam.HasTorch;
  except
    on E: Exception do
      lblEstado.Text := TrF('Linterna no disponible: %s', [E.Message]);
  end;
  ActualizarBotonLinterna;
end;

procedure TFormEscaner.ProcesarSampleBuffer;
var
  Ahora: UInt64;
begin
  Ahora := TThread.GetTickCount64;
  if FActiva and not FPrimerFotograma then
  begin
    FPrimerFotograma := True;
    DetectarLinterna;
  end;
  if FActiva and (Ahora - FUltimaPrevisualizacion >= 100) then
  begin
    FUltimaPrevisualizacion := Ahora;
    cam.SampleBufferToBitmap(imgPreview.Bitmap, True);
    IniciarDecodificacion(False);
  end;
end;

procedure TFormEscaner.camSampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  // FMX.Media.Android ya entrega este evento sincronizado con el hilo UI.
  ProcesarSampleBuffer;
end;

procedure TFormEscaner.AplicarCodigo(const Codigo: string);
begin
  if FActiva and (Codigo <> '') and (Codigo <> FUltimoCodigo) then
  begin
    FUltimoCodigo := Codigo;
    lblEstado.Text := TrF('Código: %s', [Codigo]);
    OcultarEscaner;
    if Assigned(FOnCodigoEscaneado) then
      FOnCodigoEscaneado(Codigo);
  end;
end;

procedure TFormEscaner.OcultarEscaner;
begin
  FActiva := False;
  TInterlocked.Increment(FGeneracion);
  TInterlocked.Exchange(FPeticionManual, 0);
  DesactivarCamara;
  Hide;
  if Assigned(FOnEscanerOcultado) then
    FOnEscanerOcultado;
end;

procedure TFormEscaner.IniciarDecodificacion(const Forzada: Boolean);
var
  Ahora: UInt64;
  Frame: TBitmap;
  Generacion: Integer;
  AltoRegion: Integer;
  AnchoRegion: Integer;
  Izquierda: Integer;
  Superior: Integer;
begin
  if Forzada then
    TInterlocked.Exchange(FPeticionManual, 1);
  Ahora := TThread.GetTickCount64;
  if FActiva and (imgPreview.Bitmap <> nil) and
     not imgPreview.Bitmap.IsEmpty and
     (Forzada or (Ahora - FUltimoEscaneo >= 300)) and
     (TInterlocked.CompareExchange(FDecodificando, 1, 0) = 0) then
  begin
    FUltimoEscaneo := Ahora;
    Frame := TBitmap.Create;
    try
      AnchoRegion := Max(1, Round(imgPreview.Bitmap.Width * 0.90));
      AltoRegion := Max(1, Round(imgPreview.Bitmap.Height * 0.45));
      Izquierda := (imgPreview.Bitmap.Width - AnchoRegion) div 2;
      Superior := (imgPreview.Bitmap.Height - AltoRegion) div 2;
      Frame.SetSize(AnchoRegion, AltoRegion);
      Frame.CopyFromBitmap(
        imgPreview.Bitmap,
        TRect.Create(
          Izquierda,
          Superior,
          Izquierda + AnchoRegion,
          Superior + AltoRegion),
        0,
        0);
    except
      Frame.Free;
      TInterlocked.Exchange(FDecodificando, 0);
      raise;
    end;
    Generacion := TInterlocked.CompareExchange(FGeneracion, 0, 0);
    FTareaEscaneo := TTask.Run(
      procedure
      var
        Codigo: string;
        ErrorEscaneo: string;
        MostrarFallo: Boolean;
        Resultado: TReadResult;
      begin
        Codigo := '';
        ErrorEscaneo := '';
        Resultado := nil;
        try
          try
            Resultado := FScanManager.Scan(Frame);
            if Resultado <> nil then
              Codigo := Resultado.Text;
          except
            on E: Exception do
              ErrorEscaneo := E.Message;
          end;
        finally
          Resultado.Free;
          Frame.Free;
          MostrarFallo :=
            TInterlocked.Exchange(FPeticionManual, 0) <> 0;
          TInterlocked.Exchange(FDecodificando, 0);
        end;
        if (Codigo <> '') or MostrarFallo or (ErrorEscaneo <> '') then
        begin
          TThread.Queue(nil,
            procedure
            begin
              if (Generacion = TInterlocked.CompareExchange(
                   FGeneracion, 0, 0)) and FActiva then
              begin
                if Codigo <> '' then
                  AplicarCodigo(Codigo)
                else if ErrorEscaneo <> '' then
                  lblEstado.Text := TrF('Error de lectura: %s',
                    [ErrorEscaneo])
                else if MostrarFallo then
                  lblEstado.Text := Tr('No detectado, prueba de nuevo');
              end;
            end);
        end;
      end);
  end;
end;

procedure TFormEscaner.btnCapturarClick(Sender: TObject);
begin
  lblEstado.Text := Tr('Analizando código...');
  IniciarDecodificacion(True);
end;

procedure TFormEscaner.btnLinternaClick(Sender: TObject);
begin
  if FActiva and FPrimerFotograma and FSoportaLinterna and
     cam.Active then
  begin
    try
      if FLinternaEncendida then
      begin
        cam.TorchMode := FMX.Media.TTorchMode.ModeOff;
        FLinternaEncendida := False;
      end
      else
      begin
        cam.TorchMode := FMX.Media.TTorchMode.ModeOn;
        FLinternaEncendida := True;
      end;
    except
      on E: Exception do
        lblEstado.Text := TrF('Error de linterna: %s', [E.Message]);
    end;
    ActualizarBotonLinterna;
  end;
end;

procedure TFormEscaner.btnCancelarClick(Sender: TObject);
begin
  OcultarEscaner;
end;

procedure TFormEscaner.FormResize(Sender: TObject);
begin
  ActualizarDisposicion;
end;

procedure TFormEscaner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FActiva := False;
  TInterlocked.Increment(FGeneracion);
  TInterlocked.Exchange(FPeticionManual, 0);
  DesactivarCamara;
  Action := TCloseAction.caHide;
  if Assigned(FOnEscanerOcultado) then
    FOnEscanerOcultado;
end;

procedure TFormEscaner.FormDestroy(Sender: TObject);
begin
  FActiva := False;
  TInterlocked.Increment(FGeneracion);
  DesactivarCamara;
  if Assigned(FTareaEscaneo) then
  begin
    try
      TTask.WaitForAll([FTareaEscaneo], 5000);
    except
      // Al cerrar la aplicacion se libera el lector aunque la tarea fallase.
    end;
  end;
  FreeAndNil(FScanManager);
end;

end.
