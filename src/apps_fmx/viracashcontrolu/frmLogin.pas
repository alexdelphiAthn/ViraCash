unit frmLogin;

{
  Acceso a la consulta movil de stock de ViraCash.

  Permite al usuario:
  - Editar la URL unica del servidor de la red interna.
  - Introducir usuario y contrasena.
  - Decidir si se recuerdan las credenciales en este dispositivo.

  Al pulsar Entrar:
  - Guarda la URL configurada
  - Llama a TAuthService.Login
  - Si OK, abre el formulario de stock

  En FormShow:
  - Si ya hay credenciales y token valido, salta directo al stock
  - Si solo hay credenciales, las pre-rellena
}

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.Layouts,
  FMX.ScrollBox,
  uAuthService, uSettings;

type
  TFormLogin = class(TForm)
    sb: TVertScrollBox;
    Layout1: TLayout;
    lblTitulo: TLabel;
    lblUrl: TLabel;
    edtUrl: TEdit;
    lblAvisoHttp: TLabel;
    lblUsuario: TLabel;
    edtUsuario: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    chkRecordar: TCheckBox;
    chkOcultarCeros: TCheckBox;
    btnEntrar: TButton;
    lblError: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnEntrarClick(Sender: TObject);
  public
    AlAbrirStock: TNotifyEvent;
    constructor Create(AOwner: TComponent); override;
  end;

var
  FormLogin: TFormLogin;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

uses
  frmStock, TraduccionMovil, TextosControlU;

constructor TFormLogin.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TraducirFormulario(Self);
end;

procedure TFormLogin.FormShow(Sender: TObject);
begin
  edtPassword.Password := True;
  lblError.Text := '';

  edtUrl.Text := TSettings.LeerBaseUrl;
  chkOcultarCeros.IsChecked :=
    TSettings.LeerOcultarColumnasCero;

  if TSettings.HayCredenciales then
  begin
    edtUsuario.Text  := TSettings.LeerUsuario;
    edtPassword.Text := TSettings.LeerPassword;
    chkRecordar.IsChecked := True;

    if TSettings.TokenValido then
    begin
      if not Assigned(FormStock) then
        Application.CreateForm(TFormStock, FormStock);
      Hide;
      if Assigned(AlAbrirStock) then
        AlAbrirStock(FormStock);
      FormStock.Show;
      Exit;
    end;
  end;
end;

procedure TFormLogin.btnEntrarClick(Sender: TObject);
begin
  lblError.Text := '';
  btnEntrar.Enabled := False;
  try
    try
      // Guardar la URL antes del login (TAuthService usa LeerBaseUrl).
      TSettings.GuardarBaseUrl(Trim(edtUrl.Text));
      TSettings.GuardarOcultarColumnasCero(
        chkOcultarCeros.IsChecked);

      TAuthService.Login(Trim(edtUsuario.Text), edtPassword.Text);

      if not chkRecordar.IsChecked then
        TSettings.BorrarCredenciales;

      if not Assigned(FormStock) then
        Application.CreateForm(TFormStock, FormStock);
      Hide;
      if Assigned(AlAbrirStock) then
        AlAbrirStock(FormStock);
      FormStock.Show;
    except
      on E: Exception do
        lblError.Text := E.Message;
    end;
  finally
    btnEntrar.Enabled := True;
  end;
end;

end.
