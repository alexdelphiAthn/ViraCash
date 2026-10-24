program utlTraduc;

uses
  Vcl.Consts in '..\vcl37\Vcl.Consts.pas',
  Vcl.Forms,
  MidasLib,
  inMtoFrmBaseTraduc in 'inMtoFrmBaseTraduc.pas',
  inMtoTraducciones in 'inMtoTraducciones.pas' {frmTraducciones},
  UniDataTraducciones in 'UniDataTraducciones.pas',
  inLibConexionIniTraduc in 'inLibConexionIniTraduc.pas',
  inLibTraducValidacion in 'inLibTraducValidacion.pas',
  inLibMsgTraduc in 'inLibMsgTraduc.pas',
  inLibRegistroResourcestringTraducciones in
    '..\Lib\inLibRegistroResourcestringTraducciones.pas',
  inLibRegistroParametrosTraducciones in
    '..\Lib\inLibRegistroParametrosTraducciones.pas',
  inLibdxSpreadSheetStrs_ESP in
    '..\Lib\inLibdxSpreadSheetStrs_ESP.pas',
  inLibCifrado in '..\Lib\inLibCifrado.pas';

{$R *.res}
{$R '..\..\CXLOCALIZATION.res'}

var
  Formulario: TfrmTraducciones;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := STituloEditorTraducciones;
  Application.CreateForm(TfrmTraducciones, Formulario);
  Application.Run;
end.
