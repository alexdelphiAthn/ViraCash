program ViraCashNormalizer;

uses
  Vcl.Forms,
  UNormalizer in 'UNormalizer.pas' {FormNormalizer},
  UNormalizerEngine in 'UNormalizerEngine.pas',
  UConfigEditor in 'UConfigEditor.pas' {FormConfigEditor},
  UProjectScanner in 'UProjectScanner.pas',
  UDBObjectScanner in 'UDBObjectScanner.pas',
  UFR3SQLDumpPatcher in 'UFR3SQLDumpPatcher.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'ViraCash Normalizer';
  Application.CreateForm(TFormNormalizer, FormNormalizer);
  Application.Run;
end.
