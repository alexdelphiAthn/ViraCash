program ViraCashMovil;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMovilMenu in 'fMovilMenu.pas';

procedure Ejecutar;
var
  oMenu: TfrmMovilMenu;
begin
  Application.Initialize;
  Application.CreateForm(TfrmMovilMenu, oMenu);
  Application.Run;
end;

begin
  Ejecutar;
end.
