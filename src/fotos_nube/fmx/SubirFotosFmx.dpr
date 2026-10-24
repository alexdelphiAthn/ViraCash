program SubirFotosFmx;

uses
  System.StartUpCopy,
  FMX.Forms,
  SesionClienteMovil in '..\..\apps_fmx\SesionClienteMovil.pas',
  ConfiguracionClienteMovil in '..\..\apps_fmx\ConfiguracionClienteMovil.pas',
  TraduccionMovil in '..\..\apps_fmx\TraduccionMovil.pas',
  TextosFotos in 'TextosFotos.pas',
  UPrincipal in 'UPrincipal.pas' {frmPrincipal},
  UConfigFotos in 'UConfigFotos.pas',
  UImagenUtil in 'UImagenUtil.pas',
  UColaFotosNube in 'UColaFotosNube.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
