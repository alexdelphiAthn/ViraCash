{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraducciones                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla sencilla para editar el catálogo de traducciones de ViraCash.    }
{******************************************************************************}
unit inMtoTraducciones;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Dialogs, Vcl.Grids, Vcl.DBGrids, Vcl.DBCtrls, Data.DB,
  Datasnap.DBClient,
  inMtoFrmBaseTraduc, UniDataTraducciones, inLibConexionIniTraduc;

type
  TfrmTraducciones = class(TfrmBase)
    pnlConexion: TPanel;
    lblIni: TLabel;
    edtIni: TEdit;
    btnBuscarIni: TButton;
    btnConectar: TButton;
    lblIdioma: TLabel;
    cbbIdioma: TComboBox;
    chkSoloPendientes: TCheckBox;
    btnCargar: TButton;
    btnGuardar: TButton;
    btnImportarCatalogo: TButton;
    dbgrdClaves: TDBGrid;
    splVertical: TSplitter;
    pnlEditor: TPanel;
    lblOrigen: TLabel;
    dbmOrigen: TDBMemo;
    splHorizontal: TSplitter;
    lblDestino: TLabel;
    dbmDestino: TDBMemo;
    stbEstado: TStatusBar;
    dsTraducciones: TDataSource;
    cdsTraducciones: TClientDataSet;
    dlgAbrirIni: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnBuscarIniClick(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnCargarClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnImportarCatalogoClick(Sender: TObject);
  private
    FConfiguracion: TConfiguracionConexionTraduc;
    FDataModule: TdmTraducciones;
    procedure ActualizarEstado(const AMensaje: string);
    function CambiosValidos(
      out ACambios, AIdenticas: Integer): Boolean;
    function IdiomaDestinoValido: Boolean;
  end;

implementation

uses
  System.SysUtils, System.UITypes,
  inLibMsgTraduc, inLibTraducValidacion;

{$R *.dfm}

procedure TfrmTraducciones.FormCreate(Sender: TObject);
begin
  FDataModule := TdmTraducciones.Create(Self);
  edtIni.Text := RutaIniViraCashPredeterminada;
  cbbIdioma.ItemIndex := 0;
  btnCargar.Enabled := False;
  btnGuardar.Enabled := False;
  btnImportarCatalogo.Enabled := False;
  ActualizarEstado(SEstadoDesconectado);
end;

procedure TfrmTraducciones.ActualizarEstado(const AMensaje: string);
begin
  stbEstado.SimpleText := AMensaje;
end;

procedure TfrmTraducciones.btnBuscarIniClick(Sender: TObject);
begin
  dlgAbrirIni.FileName := Trim(edtIni.Text);
  if dlgAbrirIni.Execute then
    edtIni.Text := dlgAbrirIni.FileName;
end;

function TfrmTraducciones.IdiomaDestinoValido: Boolean;
begin
  Result := False;
  if Trim(cbbIdioma.Text) = '' then
    MessageDlg(
      SAvisoIdiomaDestinoNoIndicado,
      mtWarning,
      [mbOK],
      0)
  else if SameText(Trim(cbbIdioma.Text), 'es-ES') then
    MessageDlg(
      SAvisoIdiomaDestinoIgualOrigen,
      mtWarning,
      [mbOK],
      0)
  else
    Result := True;
end;

procedure TfrmTraducciones.btnConectarClick(Sender: TObject);
begin
  if Trim(edtIni.Text) <> '' then
  begin
    try
      FConfiguracion :=
        LeerConfiguracionConexionViraCash(
          Trim(edtIni.Text));
      FDataModule.Conectar(
        FConfiguracion.Servidor,
        FConfiguracion.Puerto,
        FConfiguracion.BaseDatos,
        FConfiguracion.Usuario,
        FConfiguracion.Clave);
      FDataModule.CargarIdiomasDestino(
        cbbIdioma.Items);
      if cbbIdioma.Items.Count > 0 then
        cbbIdioma.ItemIndex := 0
      else
        cbbIdioma.Text := 'en-GB';
      btnCargar.Enabled := True;
      btnGuardar.Enabled := False;
      btnImportarCatalogo.Enabled := True;
      ActualizarEstado(
        Format(
          SInfoConexionCorrecta,
          [
            FConfiguracion.BaseDatos,
            FConfiguracion.Servidor,
            FConfiguracion.Puerto
          ]));
    except
      on E: Exception do
      begin
        btnCargar.Enabled := False;
        btnGuardar.Enabled := False;
        btnImportarCatalogo.Enabled := False;
        MessageDlg(
          Format(SErrorConexion, [E.Message]),
          mtError,
          [mbOK],
          0);
      end;
    end;
  end
  else
    MessageDlg(
      SAvisoIniViraCashNoIndicado,
      mtWarning,
      [mbOK],
      0);
end;

procedure TfrmTraducciones.btnCargarClick(Sender: TObject);
begin
  if not FDataModule.Conectado then
    MessageDlg(
      SAvisoConectarPrimero,
      mtWarning,
      [mbOK],
      0)
  else if IdiomaDestinoValido then
  begin
    try
      FDataModule.CargarTraducciones(
        cdsTraducciones,
        Trim(cbbIdioma.Text),
        chkSoloPendientes.Checked);
      btnGuardar.Enabled := cdsTraducciones.RecordCount > 0;
      ActualizarEstado(
        Format(
          SInfoTraduccionesCargadas,
          [
            cdsTraducciones.RecordCount,
            Trim(cbbIdioma.Text)
          ]));
    except
      on E: Exception do
        MessageDlg(
          Format(SErrorCargarTraducciones, [E.Message]),
          mtError,
          [mbOK],
          0);
    end;
  end;
end;

procedure TfrmTraducciones.btnImportarCatalogoClick(
  Sender: TObject);
var
  Importadas: Integer;
begin
  if not FDataModule.Conectado then
    MessageDlg(
      SAvisoConectarPrimero,
      mtWarning,
      [mbOK],
      0)
  else if MessageDlg(
            SPreguntaImportarCatalogo,
            mtConfirmation,
            [mbYes, mbNo],
            0) = mrYes then
  begin
    try
      Importadas := FDataModule.ImportarCatalogoEspanol(
        FConfiguracion.Usuario);
      ActualizarEstado(
        Format(
          SInfoCatalogoImportado,
          [Importadas]));
    except
      on E: Exception do
        MessageDlg(
          Format(SErrorImportarCatalogo, [E.Message]),
          mtError,
          [mbOK],
          0);
    end;
  end;
end;

function TfrmTraducciones.CambiosValidos(
  out ACambios, AIdenticas: Integer): Boolean;
var
  ClaveActual: string;
  ClaveTraduccion: string;
  TextoDestino: string;
  TextoOrigen: string;
begin
  Result := True;
  ACambios := 0;
  AIdenticas := 0;
  cdsTraducciones.CheckBrowseMode;
  ClaveActual := cdsTraducciones.FieldByName('CLAVE_TRAD').AsString;
  cdsTraducciones.DisableControls;
  try
    cdsTraducciones.First;
    while not cdsTraducciones.Eof and Result do
    begin
      if cdsTraducciones.UpdateStatus = usModified then
      begin
        ClaveTraduccion :=
          cdsTraducciones.FieldByName('CLAVE_TRAD').AsString;
        TextoOrigen :=
          cdsTraducciones.FieldByName('TEXTO_ORIGEN').AsWideString;
        TextoDestino :=
          cdsTraducciones.FieldByName('TEXTO_DESTINO').AsWideString;
        Inc(ACambios);
        if Trim(TextoDestino) = '' then
        begin
          Result := False;
          MessageDlg(
            Format(SErrorTraduccionVacia, [ClaveTraduccion]),
            mtError,
            [mbOK],
            0);
        end
        else if not MarcadoresFormatoCompatibles(
                      TextoOrigen,
                      TextoDestino) then
        begin
          Result := False;
          MessageDlg(
            Format(SErrorMarcadoresDistintos, [ClaveTraduccion]),
            mtError,
            [mbOK],
            0);
        end
        else if SameText(
                  Trim(TextoOrigen),
                  Trim(TextoDestino)) then
          Inc(AIdenticas);
      end;
      cdsTraducciones.Next;
    end;
  finally
    if ClaveActual <> '' then
      cdsTraducciones.Locate('CLAVE_TRAD', ClaveActual, []);
    cdsTraducciones.EnableControls;
  end;
end;

procedure TfrmTraducciones.btnGuardarClick(Sender: TObject);
var
  Cambios: Integer;
  Guardadas: Integer;
  Identicas: Integer;
  PuedeGuardar: Boolean;
begin
  PuedeGuardar := CambiosValidos(Cambios, Identicas);
  if PuedeGuardar and (Cambios = 0) then
  begin
    PuedeGuardar := False;
    MessageDlg(
      SAvisoSinCambiosTraducciones,
      mtInformation,
      [mbOK],
      0);
  end;
  if PuedeGuardar and (Identicas > 0) then
    PuedeGuardar :=
      MessageDlg(
        Format(SPreguntaTraduccionesIguales, [Identicas]),
        mtConfirmation,
        [mbYes, mbNo],
        0) = mrYes;
  if PuedeGuardar then
  begin
    try
      Guardadas := FDataModule.GuardarTraducciones(
        cdsTraducciones,
        Trim(cbbIdioma.Text),
        FConfiguracion.Usuario);
      ActualizarEstado(
        Format(SInfoTraduccionesGuardadas, [Guardadas]));
    except
      on E: Exception do
        MessageDlg(
          Format(SErrorGuardarTraducciones, [E.Message]),
          mtError,
          [mbOK],
          0);
    end;
  end;
end;

end.
