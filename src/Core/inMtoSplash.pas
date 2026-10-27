{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoSplash                                                   }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Este formulario es un formulario de información sobre el autor.           }
{    No tiene ningún propósito funcional, pero es importante agradecer a quien }
{    te ha dado una mano.                                                      }
{******************************************************************************}
unit inMtoSplash;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, jpeg, StdCtrls, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, JvExControls,
  JvAnimatedImage, JvGIFCtrl, cxTextEdit, cxHyperLinkEdit, Vcl.Menus, cxButtons,
  Vcl.Imaging.pngimage, inLibLogIntf;

type
  TfrmSplash = class(TForm)
    Panel1: TPanel;
    Panel3: TPanel;
    cxLabel1: TcxLabel;
    hlEmail: TcxHyperLinkEdit;
    cxLabel2: TcxLabel;
    btnAceptar: TcxButton;
    Panel2: TPanel;
    pnlDatosAutor: TPanel;
    lblNombreAutor: TcxLabel;
    lblVersion: TcxLabel;
    procedure JvGIFAnimator1Click(Sender: TObject);
    procedure cxLabel1Click(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FimgLogo:    TImage;
    FRegistroLog: IRegistroLog;
  public
    constructor Create(
      AOwner: TComponent;
      const ARegistroLog: IRegistroLog); reintroduce;
  end;

implementation

uses
  inLibGlobalVar, inLibDir, inLibImagen,
  inLibTraducciones, inLibMsgComun;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmSplash.Create(
  AOwner: TComponent;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FRegistroLog := ARegistroLog;
  inherited Create(AOwner);
end;

procedure TfrmSplash.cxLabel1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.JvGIFAnimator1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.btnAceptarClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.FormCreate(Sender: TObject);
const
  CNombre: string = 'Alejandro Laorden Hidalgo';
  CEmail:  string = 'alejandro.laorden@protonmail.com';
  CRutas:  array[0..3] of string = (
    'fondo_viracash.png',
    '..\..\fondo_viracash.png',
    'icon-viracash-256.png',
    '..\..\icon-viracash-256.png'
  );
var
  sBase, sRuta: string;
  i: Integer;
  bCargado: Boolean;
  oRes: TResourceStream;
  oPng: TPngImage;
  oEscalado: TBitmap;
begin
  // El email del .dfm se sobreescribe en runtime para no quedar atado al
  // valor cableado (que ademas en versiones antiguas era una direccion
  // de batch antigua).
  hlEmail.Text := CEmail;
  // Cargamos fondo_viracash.png (recurso RCDATA 'FONDO' embebido via {$R fondo.res}
  // en vcash.dpr, o fichero suelto con las mismas rutas que
  // TfrmMtoPrincipal.CargarFondoLogo) en un PNG original y lo escalamos al
  // area de imagen con GDI+ (bicubica, alfa preservado) en vez de dejar que
  // el TImage lo estire con StretchBlt, que es lo que lo dejaba pixelado.
  bCargado := False;
  FimgLogo := TImage.Create(Self);
  FimgLogo.Parent := Panel2;
  FimgLogo.SetBounds(0, 0, Panel2.ClientWidth, Panel2.ClientHeight);
  FimgLogo.Align := alClient;
  FimgLogo.Proportional := False;
  FimgLogo.Stretch      := False;
  FimgLogo.Center       := True;
  oPng := TPngImage.Create;
  try
    try
      oRes := TResourceStream.Create(HInstance, 'FONDO', RT_RCDATA);
      try
        oPng.LoadFromStream(oRes);
        bCargado := True;
      finally
        oRes.Free;
      end;
    except
      // Recurso no presente (build sin fondo.res); seguimos a disco.
      on E: Exception do
        FRegistroLog.RegistrarInformacion(
          'Splash: recurso FONDO no disponible (' + E.Message +
          '); se intenta cargar de disco.');
    end;
    if not bCargado then
    begin
      sBase := inLibDir.DirApp;
      for i := 0 to High(CRutas) do
      begin
        sRuta := sBase + CRutas[i];
        if FileExists(sRuta) then
        try
          oPng.LoadFromFile(sRuta);
          bCargado := True;
          Break;
        except
          on E: Exception do
            FRegistroLog.RegistrarAviso('Splash: no se pudo cargar ' + sRuta +
                                    ': ' + E.Message);
        end;
      end;
    end;
    if bCargado then
    begin
      // Escalado suavizado al area de imagen del splash, alfa preservado.
      oEscalado := inLibImagen.EscalarSuavizado(oPng,
        Panel2.ClientWidth, Panel2.ClientHeight);
      if oEscalado <> nil then
      try
        FimgLogo.Picture.Assign(oEscalado);
      finally
        oEscalado.Free;
      end
      else
      begin
        // Fallback si GDI+ no pudo escalar: PNG tal cual estirado por el
        // TImage (menos nitido pero visible).
        FimgLogo.Proportional := True;
        FimgLogo.Stretch      := True;
        FimgLogo.Picture.Assign(oPng);
      end;
    end;
  finally
    oPng.Free;
  end;
  // Los textos viven en su propia franja del DFM. VCL escala tanto
  // sus fuentes como sus alturas, sin superponerlos al panel del logo.
  lblNombreAutor.Caption := CNombre;
  lblVersion.Caption := Format(SCaptionVersion, [oVersion]);
  AplicarTraducciones(Self, Owner);
end;

initialization
  ForceReferenceToClass(TfrmSplash);

end.
