{******************************************************************************}
{                                                                              }
{  Módulo:       UPrincipal                                                    }
{    Tipo:       Formulario principal (FMX, Android)                           }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla principal de la app FMX de fotos a la nube. Permite hacer        }
{    fotos con la cámara (o elegirlas de la galería) asociándolas a un código  }
{    de artículo y un color, las reduce a la resolución máxima configurada     }
{    (por defecto 1000 px), las acumula en una cola por lotes y las sube al    }
{    endpoint de fotos de la API v1 de ViraCash. El índice visible identifica }
{    cada foto y vale 1 por defecto.                                           }
{******************************************************************************}
unit UPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.IOUtils, System.Actions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.Objects, FMX.TabControl, FMX.ScrollBox, FMX.Memo, FMX.Memo.Types,
  FMX.ListBox, FMX.ActnList, FMX.MediaLibrary.Actions, FMX.Layouts,
  SesionClienteMovil, UConfigFotos, UColaFotosNube, UImagenUtil, FMX.MediaLibrary, FMX.StdActns;

type
  TfrmPrincipal = class(TForm)
    TabControl1: TTabControl;
    tabCapturar: TTabItem;
    tabConfig: TTabItem;
    cajaCaptura: TVertScrollBox;
    lytCaptura: TLayout;
    lblArticulo: TLabel;
    edArticulo: TEdit;
    lblColor: TLabel;
    edColor: TEdit;
    lblIndice: TLabel;
    edIndice: TEdit;
    imgPrevia: TImage;
    btnCamara: TButton;
    btnGaleria: TButton;
    lstCola: TListView;
    btnSubir: TButton;
    cajaConfig: TVertScrollBox;
    lblUrl: TLabel;
    edUrl: TEdit;
    lblApiKey: TLabel;
    edApiKey: TEdit;
    lblCarpetaCliente: TLabel;
    edCarpetaCliente: TEdit;
    lblResolucion: TLabel;
    edResolucion: TEdit;
    btnGuardarConfig: TButton;
    lblRutaIni: TLabel;
    memoLog: TMemo;
    ActionList1: TActionList;
    actHacerFoto: TTakePhotoFromCameraAction;
    actElegirFoto: TTakePhotoFromLibraryAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnCamaraClick(Sender: TObject);
    procedure btnGaleriaClick(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnGuardarConfigClick(Sender: TObject);
    procedure actHacerFotoDidFinishTaking(Image: TBitmap);
    procedure actElegirFotoDidFinishTaking(Image: TBitmap);
  private
    FDestino: TComboBox;
    FSecuencia: TButton;
    FComentario: TEdit;
    FComentarioSolo: TButton;
    FComentarioCaptura: string;
    FReparacionCaptura: Boolean;
    FFaseCaptura: string;
    FConfig: TConfigFotos;
    FCola: TColaFotos;
    FArticuloCaptura: string;
    FColorCaptura: string;
    FIndiceCaptura: Integer;
    FSubidaEnCurso: Boolean;
    procedure CrearDestino;
    procedure CrearComentario;
    procedure ComentarioClick(Sender: TObject);
    procedure CambiarSecuenciaClick(Sender: TObject);
    procedure DestinoCambiado(Sender: TObject);
    procedure Log(const S: string);
    procedure ConfigAUI;
    procedure UIAConfig;
    procedure RefrescarCola;
    procedure ProcesarImagen(const AImagen: TBitmap);
    procedure EstablecerSubidaEnCurso(const AValor: Boolean);
    // Pide el permiso de camara (Android) y, si se concede, ejecuta
    // ATrasConceder. En el resto de plataformas ejecuta directamente.
    procedure ConPermisoCamara(const ATrasConceder: TProc);
    function ValidarDatosFoto: Boolean;
  public
    procedure ConfigurarModulo(const AUrl, AToken, AReferencia,
      ARutaCola: string; const ASesion: ISesionClienteMovil);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

uses
  TraduccionMovil, TextosFotos
{$IFDEF ANDROID}
  , System.Permissions, FMX.Helpers.Android, Androidapi.Helpers,
  Androidapi.JNI.Os, Androidapi.JNI.JavaTypes
{$ENDIF}
  ;

const
  cVersionApp = '1.1.0.202610300001.alpha';

procedure TfrmPrincipal.ConfigurarModulo(const AUrl, AToken,
  AReferencia, ARutaCola: string; const ASesion: ISesionClienteMovil);
begin
  FConfig.Url := AUrl + 'fotos/subir.php';
  FConfig.ApiKey := AToken;
  FConfig.CarpetaCliente := AReferencia;
  FCola.Sesion := ASesion;
  FCola.AbrirCola(ARutaCola);
  ConfigAUI;
  tabConfig.Visible := False;
  TabControl1.ActiveTab := tabCapturar;
  RefrescarCola;
end;

procedure TfrmPrincipal.Log(const S: string);
begin
  memoLog.Lines.Add(Format('[%s] %s',
    [FormatDateTime('hh:nn:ss', Now), S]));
  memoLog.GoToTextEnd;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  TraducirFormulario(Self);
  FConfig := TConfigFotos.Create;
  FConfig.Cargar;
  FCola := TColaFotos.Create;
  CrearDestino;
  EstablecerSubidaEnCurso(False);
  ConfigAUI;
  RefrescarCola;
  Log(TrF('ViraCash Fotos Nube %s', [cVersionApp]));
  Log(TrF('Configuración: %s', [FConfig.RutaIni]));
end;

procedure TfrmPrincipal.CrearDestino;
begin
  FDestino := TComboBox.Create(Self);
  FDestino.Parent := lytCaptura;
  FDestino.Align := TAlignLayout.Top;
  FDestino.Position.Y := -100;
  FDestino.Height := 44;
  FDestino.Items.Add(Tr('Artículo / color'));
  FDestino.Items.Add(Tr('Reparación · Antes'));
  FDestino.Items.Add(Tr('Reparación · Después'));
  FDestino.Items.Add(Tr('Reparación · Otra fase'));
  FDestino.ItemIndex := 0;
  FDestino.OnChange := DestinoCambiado;
  FSecuencia := TButton.Create(Self);
  FSecuencia.Parent := lytCaptura;
  FSecuencia.Align := TAlignLayout.Bottom;
  FSecuencia.Height := 44;
  FSecuencia.Text := Tr('Aplicar secuencia a la foto seleccionada');
  FSecuencia.OnClick := CambiarSecuenciaClick;
  CrearComentario;
  lytCaptura.Height := lytCaptura.Height + 202;
end;

procedure TfrmPrincipal.CambiarSecuenciaClick(Sender: TObject);
begin
  try
    FCola.CambiarSecuencia(lstCola.ItemIndex,
      StrToIntDef(edIndice.Text, 0));
    RefrescarCola;
  except
    on E: EArgumentException do
      Log(E.Message);
  end;
end;

procedure TfrmPrincipal.CrearComentario;
var
  oPanel: TLayout;
  oRotulo: TLabel;
begin
  oPanel := TLayout.Create(Self);
  oPanel.Parent := lytCaptura;
  oPanel.Align := TAlignLayout.Top;
  oPanel.Position.Y := edIndice.Position.Y + edIndice.Height + 1;
  oPanel.Height := 70;
  oRotulo := TLabel.Create(Self);
  oRotulo.Parent := oPanel;
  oRotulo.Align := TAlignLayout.Top;
  oRotulo.Text := Tr('Comentario (opcional)');
  oRotulo.Height := 24;
  FComentario := TEdit.Create(Self);
  FComentario.Parent := oPanel;
  FComentario.Align := TAlignLayout.Client;
  FComentario.MaxLength := 2000;
  FComentarioSolo := TButton.Create(Self);
  FComentarioSolo.Parent := lytCaptura;
  FComentarioSolo.Align := TAlignLayout.Bottom;
  FComentarioSolo.Height := 44;
  FComentarioSolo.Text := Tr('Añadir comentario sin foto');
  FComentarioSolo.OnClick := ComentarioClick;
  FComentarioSolo.Enabled := False;
end;

procedure TfrmPrincipal.ComentarioClick(Sender: TObject);
begin
  if ValidarDatosFoto and FReparacionCaptura then
  begin
    if Trim(FComentarioCaptura) = '' then
      Log(Tr('Escriba el comentario.'))
    else
    begin
      FCola.AddReparacion('', FArticuloCaptura, FFaseCaptura,
        FIndiceCaptura, FComentarioCaptura);
      edIndice.Text := IntToStr(FIndiceCaptura + 1);
      RefrescarCola;
    end;
  end;
end;

procedure TfrmPrincipal.DestinoCambiado(Sender: TObject);
begin
  edColor.Visible := True;
  lblColor.Visible := True;
  if FDestino.ItemIndex = 0 then
  begin
    lblArticulo.Text := Tr('Código de artículo (obligatorio)');
    lblColor.Text := Tr('Color (obligatorio)');
    edColor.Text := '';
  end
  else
  begin
    lblArticulo.Text := Tr('Número de reparación (obligatorio)');
    lblColor.Text := Tr('Fase de la reparación');
    edColor.Text := '';
    if FDestino.ItemIndex = 1 then
      edColor.Text := 'ANTES'
    else if FDestino.ItemIndex = 2 then
      edColor.Text := 'DESPUES';
  end;
  FComentarioSolo.Enabled := FDestino.ItemIndex > 0;
  edColor.TextPrompt := lblColor.Text;
  edArticulo.TextPrompt := lblArticulo.Text;
  edIndice.Text := '1';
end;

procedure TfrmPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FSubidaEnCurso;
  if not CanClose then
    Log(Tr('Espera a que termine la subida antes de cerrar la aplicación'));
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  FCola.Free;
  FConfig.Free;
end;

procedure TfrmPrincipal.EstablecerSubidaEnCurso(const AValor: Boolean);
begin
  FSubidaEnCurso := AValor;
  btnCamara.Enabled := not AValor;
  btnGaleria.Enabled := not AValor;
  FComentarioSolo.Enabled := not AValor and (FDestino.ItemIndex > 0);
  btnSubir.Enabled := not AValor;
end;

procedure TfrmPrincipal.ConfigAUI;
begin
  edUrl.Text := FConfig.Url;
  edApiKey.Text := FConfig.ApiKey;
  edCarpetaCliente.Text := FConfig.CarpetaCliente;
  edResolucion.Text := IntToStr(FConfig.ResolucionMaxima);
  lblRutaIni.Text := TrF('INI: %s', [FConfig.RutaIni]);
end;

procedure TfrmPrincipal.UIAConfig;
var
  Resol: Integer;
begin
  FConfig.Url := Trim(edUrl.Text);
  FConfig.ApiKey := Trim(edApiKey.Text);
  FConfig.CarpetaCliente := Trim(edCarpetaCliente.Text);
  // Si el texto no es un entero válido usamos el valor por defecto.
  if not TryStrToInt(Trim(edResolucion.Text), Resol) then
    Resol := cResolucionMaximaDefecto;
  FConfig.ResolucionMaxima := Resol;
end;

procedure TfrmPrincipal.btnGuardarConfigClick(Sender: TObject);
begin
  UIAConfig;
  FConfig.Guardar;
  // Reflejamos el valor ya saneado (por si se topó o corrigió).
  edResolucion.Text := IntToStr(FConfig.ResolucionMaxima);
  Log(TrF('Configuración guardada (resolución máx. %d px)',
    [FConfig.ResolucionMaxima]));
end;

procedure TfrmPrincipal.ConPermisoCamara(const ATrasConceder: TProc);
begin
  // En Android se pide el permiso de cámara en tiempo de ejecución, justo
  // al ir a usarla, y solo si se concede se ejecuta la acción. En el resto
  // de plataformas se ejecuta directamente.
{$IFDEF ANDROID}
  PermissionsService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.CAMERA)],
    procedure(const APermissions: TClassicStringDynArray;
      const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) = 1) and
         (AGrantResults[0] = TPermissionStatus.Granted) then
      begin
        if Assigned(ATrasConceder) then
          ATrasConceder();
      end
      else
        Log(Tr('Permiso de cámara no concedido. ' +
          'Actívalo en Ajustes de Android.'));
    end);
{$ELSE}
  if Assigned(ATrasConceder) then
    ATrasConceder();
{$ENDIF}
end;

function TfrmPrincipal.ValidarDatosFoto: Boolean;
var
  Indice: Integer;
  iReparacion: Int64;
begin
  // El webservice nombra el fichero como ARTICULO_COLOR_INDICE y exige los
  // tres valores. El índice debe ser un entero positivo.
  Result := True;
  if Trim(edArticulo.Text) = '' then
  begin
    if FDestino.ItemIndex = 0 then
      Log(Tr('Indica el código de artículo antes de hacer la foto'))
    else
      Log(Tr('Indique un número de reparación válido.'));
    edArticulo.SetFocus;
    Result := False;
  end
  else if Trim(edColor.Text) = '' then
  begin
    if FDestino.ItemIndex = 0 then
      Log(Tr('Indica el color antes de hacer la foto'))
    else
      Log(Tr('Indique la fase de la reparación.'));
    edColor.SetFocus;
    Result := False;
  end
  else if (FDestino.ItemIndex > 0) and
    (not TryStrToInt64(Trim(edArticulo.Text), iReparacion) or
     (iReparacion < 1)) then
  begin
    Log(Tr('Indique un número de reparación válido.'));
    Result := False;
  end
  else if (not TryStrToInt(Trim(edIndice.Text), Indice)) or
    (Indice < 1) or (Indice > 9999) then
  begin
    Log(Tr('El índice de foto debe ser un número entero mayor o igual ' +
      'que 1'));
    edIndice.SetFocus;
    Result := False;
  end
  else
  begin
    // Normaliza ceros a la izquierda y espacios antes de encolar.
    edIndice.Text := IntToStr(Indice);
    FReparacionCaptura := FDestino.ItemIndex > 0;
    FFaseCaptura := UpperCase(Trim(edColor.Text));
    FComentarioCaptura := Trim(FComentario.Text);
    FArticuloCaptura := Trim(edArticulo.Text);
    FColorCaptura := Trim(edColor.Text);
    FIndiceCaptura := Indice;
  end;
end;

procedure TfrmPrincipal.btnCamaraClick(Sender: TObject);
begin
  if ValidarDatosFoto then
    // Pedimos el permiso al ir a usar la cámara; si se concede, dispara.
    ConPermisoCamara(
      procedure
      begin
        // Limitamos la resolución ya en la captura para gastar memoria.
        actHacerFoto.MaxWidth := FConfig.ResolucionMaxima;
        actHacerFoto.MaxHeight := FConfig.ResolucionMaxima;
        actHacerFoto.ExecuteTarget(Self);
      end);
end;

procedure TfrmPrincipal.btnGaleriaClick(Sender: TObject);
begin
  if ValidarDatosFoto then
  begin
    actElegirFoto.MaxWidth := FConfig.ResolucionMaxima;
    actElegirFoto.MaxHeight := FConfig.ResolucionMaxima;
    actElegirFoto.ExecuteTarget(Self);
  end;
end;

procedure TfrmPrincipal.actHacerFotoDidFinishTaking(Image: TBitmap);
begin
  ProcesarImagen(Image);
end;

procedure TfrmPrincipal.actElegirFotoDidFinishTaking(Image: TBitmap);
begin
  ProcesarImagen(Image);
end;

procedure TfrmPrincipal.ProcesarImagen(const AImagen: TBitmap);
var
  Reducida: TBitmap;
  Ruta: string;
begin
  // La actividad de cámara/galería puede devolver el resultado después de
  // haber empezado un lote. No se modifica la cola mientras el hilo la usa.
  if FSubidaEnCurso then
  begin
    Log(Tr('Foto descartada: hay una subida en curso'));
    Exit;
  end;

  // Aplicamos el tope de resolución (defensivo, además del de la
  // captura) y guardamos la foto en JPG para encolarla con su
  // artículo+color.
  Reducida := RedimensionarMax(AImagen, FConfig.ResolucionMaxima);
  try
    imgPrevia.Bitmap.Assign(Reducida);
    // Cualificamos System.IOUtils.TPath: FMX.Objects tambien declara un
    // TPath (la forma vectorial) y, al ir despues en el uses, taparia este.
    Ruta := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath,
      'foto_' + Copy(TGUID.NewGuid.ToString, 2, 36) + '.jpg');
    Reducida.SaveToFile(Ruta);
    try
      if FReparacionCaptura then
        FCola.AddReparacion(Ruta, FArticuloCaptura, FFaseCaptura,
          FIndiceCaptura, FComentarioCaptura)
      else
        FCola.Add(Ruta, FArticuloCaptura, FColorCaptura, FIndiceCaptura);
    except
      on E: Exception do
      begin
        if System.IOUtils.TFile.Exists(Ruta) then
          System.IOUtils.TFile.Delete(Ruta);
        Log(TrF('Foto no encolada: %s', [E.Message]));
        Exit;
      end;
    end;
    RefrescarCola;
    Log(TrF('Foto encolada %dx%d: %s / %s / índice %d',
      [Reducida.Width, Reducida.Height, FArticuloCaptura,
       FColorCaptura, FIndiceCaptura]));
    if FIndiceCaptura < 9999 then
      edIndice.Text := IntToStr(FIndiceCaptura + 1);
  finally
    Reducida.Free;
  end;
end;

procedure TfrmPrincipal.RefrescarCola;
var
  Item: TFotoItem;
  Fila: TListViewItem;
  Etiqueta: string;
begin
  lstCola.BeginUpdate;
  try
    lstCola.Items.Clear;
    for Item in FCola.Items do
    begin
      Etiqueta := Item.Articulo;
      if Item.Reparacion <> '' then
        Etiqueta := Tr('Reparación') + ' ' + Item.Reparacion +
          ' / ' + Item.Fase;
      if Item.Color <> '' then
        Etiqueta := Etiqueta + ' / ' + Item.Color;
      Etiqueta := TrF('%s / foto %s', [Etiqueta, Item.Indice]);
      if Item.SoloComentario then
        Etiqueta := Etiqueta + ' · ' + Tr('Comentario');
      // La apariencia por defecto del TListView solo muestra Text, asi
      // que metemos el estado en la misma linea para no perderlo.
      Etiqueta := Etiqueta + '  [' + EstadoTexto(Item.Estado) + ']';
      Fila := lstCola.Items.Add;
      Fila.Text := Etiqueta;
    end;
  finally
    lstCola.EndUpdate;
  end;
  btnSubir.Text := TrF('Subir todas (%d)', [FCola.PendientesCount]);
end;

procedure TfrmPrincipal.btnSubirClick(Sender: TObject);
begin
  if FSubidaEnCurso then
    Exit;

  UIAConfig;
  if FConfig.Url = '' then
  begin
    Log(Tr('Falta la URL del webservice (pestaña Configuración)'));
  end
  else if FConfig.CarpetaCliente = '' then
  begin
    Log(Tr('Falta la carpeta de cliente (pestaña Configuración)'));
  end
  else if FCola.PendientesCount = 0 then
  begin
    Log(Tr('No hay fotos pendientes de subir'));
  end
  else
  begin
    FCola.Url := FConfig.Url;
    FCola.ApiKey := FConfig.ApiKey;
    FCola.CarpetaCliente := FConfig.CarpetaCliente;
    try
      EstablecerSubidaEnCurso(True);
      Log(Tr('Subiendo lote de fotos...'));
      FCola.SubirTodasAsync(
        procedure(const AItem: TFotoItem)
        begin
          RefrescarCola;
          if AItem.Estado = esError then
            Log(TrF('Error en %s: %s', [AItem.Articulo, AItem.Mensaje]))
          else if AItem.Estado = esOk then
            Log(TrF('OK %s (sha1 %s)', [AItem.Articulo, AItem.Hash]));
        end,
        procedure(const AOk, AError: Integer)
        begin
          // Se desbloquea primero para que incluso un fallo al refrescar o
          // escribir el log no deje la aplicación atrapada.
          EstablecerSubidaEnCurso(False);
          RefrescarCola;
          Log(TrF('Lote finalizado: %d OK, %d con error',
            [AOk, AError]));
        end);
    except
      on E: Exception do
      begin
        EstablecerSubidaEnCurso(False);
        Log(TrF('No se pudo iniciar la subida: %s', [E.Message]));
      end;
    end;
  end;
end;

end.
