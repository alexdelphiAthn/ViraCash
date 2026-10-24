program ViraCashControlU;

uses
  System.StartUpCopy,
  FMX.Forms,
  TraduccionMovil in '..\TraduccionMovil.pas',
  TextosControlU in 'TextosControlU.pas',
  uSettings in 'uSettings.pas',
  uAuthService in 'uAuthService.pas',
  uApiClient in 'uApiClient.pas',
  frmLogin in 'frmLogin.pas' {FormLogin},
  frmStock in 'frmStock.pas' {FormStock},
  frmFiltrosStock in 'frmFiltrosStock.pas' {FormFiltrosStock},
  frmEscaner in 'frmEscaner.pas' {FormEscaner};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormLogin, FormLogin);
  Application.Run;
end.
