program PruebaVentasWs;

uses
  Vcl.Forms,
  UPrincipal in 'UPrincipal.pas' {frmPrincipal},
  UParametrosPrueba in 'UParametrosPrueba.pas',
  inLibParametrosIntf in '..\Lib\inLibParametrosIntf.pas',
  inLibViraCashApi in '..\Lib\inLibViraCashApi.pas',
  inLibVentasWsJsonIntf in '..\Lib\inLibVentasWsJsonIntf.pas',
  inLibVentasWsJson in '..\Lib\inLibVentasWsJson.pas',
  UniDataVentasWsJson in '..\DataModules\UniDataVentasWsJson.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'PruebaVentasWs';
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
