{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalScriptLog                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de visualizacion del log de ejecucion de scripts SQL.               }
{    Muestra la salida con resaltado de sintaxis y autoscroll.                 }
{******************************************************************************}
unit inMtoModalScriptLog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  SynEdit, SynEditHighlighter, SynHighlighterSQL,
  inMtoFrmBase;

type
  TfrmMtoModalScriptLog = class(TfrmBase)
    pnlBotonera: TPanel;
    btnGuardarComo: TButton;
    LogMemo: TSynEdit;
    LogHigSQL: TSynSQLSyn;
    procedure FormCreate(Sender: TObject);
    procedure btnGuardarComoClick(Sender: TObject);
  private
    FOperacionEnCurso: Boolean;
    FOnCancelarOperacion: TNotifyEvent;
    FExtensionFichero: string;
    FFiltroFichero: string;
    FPrefijoFichero: string;
    function ConfirmarCerrarOperacion: Boolean;
    procedure ConfigurarComoTextoPlano;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    class procedure MostrarTexto(
      AOwner: TComponent;
      const ATitulo: string;
      ALineas: TStrings); static;
    function CloseQuery: Boolean; override;
    procedure AppendLine(const AText: string);
    procedure AppendLines(const ALines: TStrings);
    procedure ScrollToEnd;
    property OperacionEnCurso: Boolean
      read FOperacionEnCurso write FOperacionEnCurso;
    property OnCancelarOperacion: TNotifyEvent
      read FOnCancelarOperacion write FOnCancelarOperacion;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgConfiguracion;

procedure TfrmMtoModalScriptLog.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  FOperacionEnCurso := False;
  FExtensionFichero := 'sql';
  FFiltroFichero := SCaptionFiltroArchivosSqlTexto;
  FPrefijoFichero := 'log_script_';
  LogMemo.Highlighter := LogHigSQL;
  LogHigSQL.SQLDialect := sqlMySQL;
  LogHigSQL.Enabled := True;
end;

class procedure TfrmMtoModalScriptLog.MostrarTexto(
  AOwner: TComponent;
  const ATitulo: string;
  ALineas: TStrings);
var
  Formulario: TfrmMtoModalScriptLog;
begin
  Formulario := TfrmMtoModalScriptLog.Create(AOwner);
  try
    Formulario.Caption := ATitulo;
    Formulario.ConfigurarComoTextoPlano;
    if ALineas <> nil then
      Formulario.LogMemo.Lines.Assign(ALineas);
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmMtoModalScriptLog.ConfigurarComoTextoPlano;
begin
  FExtensionFichero := 'txt';
  FFiltroFichero := SCaptionFiltroArchivosTexto;
  FPrefijoFichero := 'log_';
  LogMemo.Highlighter := nil;
  LogHigSQL.Enabled := False;
end;

function TfrmMtoModalScriptLog.ConfirmarCerrarOperacion: Boolean;
begin
  Result := True;
  if FOperacionEnCurso then
  begin
    Result := MessageDlg_fza(SPreguntaCancelarOperacion,
                         mtWarning, [mbYes, mbNo], 0) = mrYes;
    if Result then
    begin
      FOperacionEnCurso := False;
      if Assigned(FOnCancelarOperacion) then
        FOnCancelarOperacion(Self);
    end;
  end;
end;

function TfrmMtoModalScriptLog.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result then
    Result := ConfirmarCerrarOperacion;
end;

procedure TfrmMtoModalScriptLog.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    if fsModal in FormState then
    begin
      if CloseQuery then
        ModalResult := mrCancel;
    end
    else
      Close;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmMtoModalScriptLog.AppendLine(const AText: string);
begin
  LogMemo.Lines.Add(AText);
  ScrollToEnd;
end;

procedure TfrmMtoModalScriptLog.AppendLines(const ALines: TStrings);
begin
  LogMemo.Lines.AddStrings(ALines);
  ScrollToEnd;
end;

procedure TfrmMtoModalScriptLog.ScrollToEnd;
begin
  LogMemo.SelStart := Length(LogMemo.Text);
  SendMessage(LogMemo.Handle, EM_SCROLLCARET, 0, 0);
end;

procedure TfrmMtoModalScriptLog.btnGuardarComoClick(Sender: TObject);
var
  dlg: TSaveDialog;
begin
  dlg := TSaveDialog.Create(Self);
  try
    dlg.Title := STituloGuardarLogComo;
    dlg.DefaultExt := FExtensionFichero;
    dlg.Filter := FFiltroFichero;
    dlg.FileName := FPrefijoFichero +
                     FormatDateTime('yyyy_mm_dd_HH_nn_ss', Now);
    if dlg.Execute then
    begin
      LogMemo.Lines.SaveToFile(dlg.FileName, TEncoding.UTF8);
      ShowMessage_fza(Format(SInfoLogGuardado, [dlg.FileName]));
    end;
  finally
    dlg.Free;
  end;
end;

end.
