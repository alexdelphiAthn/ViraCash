{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoErroresEnvios                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historial y comunicación de los errores enviados al soporte.             }
{******************************************************************************}
unit inMtoErroresEnvios;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Data.DB,
  cxButtons,
  cxClasses,
  cxControls,
  cxDBEdit,
  cxCustomData,
  cxData,
  cxDataStorage,
  cxDBData,
  cxEdit,
  cxFilter,
  cxGraphics,
  cxGrid,
  cxGridCustomTableView,
  cxGridCustomView,
  cxGridDBTableView,
  cxGridLevel,
  cxGridTableView,
  cxLookAndFeels,
  cxLookAndFeelPainters,
  cxLabel,
  cxMemo,
  cxNavigator,
  cxPC,
  cxStyles,
  cxTextEdit,
  dxDateRanges,
  dxScrollbarAnnotations,
  dxSkinsCore,
  dxSkinsDefaultPainters,
  inMtoGen,
  UniDataErroresEnvios;

type
  TfrmMtoErroresEnvios = class(TfrmMtoGen)
    colId: TcxGridDBColumn;
    colReferencia: TcxGridDBColumn;
    colUsuario: TcxGridDBColumn;
    colInstanteError: TcxGridDBColumn;
    colEstado: TcxGridDBColumn;
    colCodigoHttp: TcxGridDBColumn;
    colClaseError: TcxGridDBColumn;
    colMensajeError: TcxGridDBColumn;
    colComentarioTecnico: TcxGridDBColumn;
    colInstanteConsulta: TcxGridDBColumn;
    colEstadoScript: TcxGridDBColumn;
    colEstadoEjecutable: TcxGridDBColumn;
    btnActualizarEstado: TcxButton;
    btnEnviarComentario: TcxButton;
    btnAbrirSeguimiento: TcxButton;
    btnEjecutarScript: TcxButton;
    btnInstalarActualizacion: TcxButton;
    pnlFichaCabecera: TPanel;
    lblReferencia: TcxLabel;
    txtReferencia: TcxDBTextEdit;
    lblEstado: TcxLabel;
    txtEstado: TcxDBTextEdit;
    lblFechaError: TcxLabel;
    txtFechaError: TcxDBTextEdit;
    lblUsuarioError: TcxLabel;
    txtUsuarioError: TcxDBTextEdit;
    lblUltimaConsulta: TcxLabel;
    txtUltimaConsulta: TcxDBTextEdit;
    lblResultadoConsulta: TcxLabel;
    txtResultadoConsulta: TcxDBTextEdit;
    lblEstadoSincronizacion: TcxLabel;
    pcFichaError: TcxPageControl;
    tsComunicacion: TcxTabSheet;
    pnlAccionesComunicacion: TPanel;
    btnFichaActualizar: TcxButton;
    btnFichaResponder: TcxButton;
    btnFichaAbrirSeguimiento: TcxButton;
    memComunicaciones: TcxDBMemo;
    tsDetalleTecnico: TcxTabSheet;
    pnlMensajeError: TPanel;
    lblMensajeError: TcxLabel;
    memMensajeError: TcxDBMemo;
    memDetalleError: TcxDBMemo;
    tsScript: TcxTabSheet;
    pnlCabeceraScript: TPanel;
    lblEstadoScript: TcxLabel;
    txtEstadoScript: TcxDBTextEdit;
    lblDescripcionScript: TcxLabel;
    txtDescripcionScript: TcxDBTextEdit;
    lblHashScript: TcxLabel;
    txtHashScript: TcxDBTextEdit;
    memScript: TcxDBMemo;
    pnlAccionScript: TPanel;
    btnFichaEjecutarScript: TcxButton;
    tsActualizacion: TcxTabSheet;
    pnlCabeceraEjecutable: TPanel;
    lblEstadoEjecutable: TcxLabel;
    txtEstadoEjecutable: TcxDBTextEdit;
    lblVersionEjecutable: TcxLabel;
    txtVersionEjecutable: TcxDBTextEdit;
    lblNombreEjecutable: TcxLabel;
    txtNombreEjecutable: TcxDBTextEdit;
    lblTamanoEjecutable: TcxLabel;
    txtTamanoEjecutable: TcxDBTextEdit;
    pnlDetalleEjecutable: TPanel;
    lblDescripcionEjecutable: TcxLabel;
    memDescripcionEjecutable: TcxDBMemo;
    lblUrlEjecutable: TcxLabel;
    txtUrlEjecutable: TcxDBTextEdit;
    lblHashEjecutable: TcxLabel;
    txtHashEjecutable: TcxDBTextEdit;
    pnlAccionEjecutable: TPanel;
    btnFichaInstalarActualizacion: TcxButton;
    procedure btnActualizarEstadoClick(Sender: TObject);
    procedure btnEnviarComentarioClick(Sender: TObject);
    procedure btnAbrirSeguimientoClick(Sender: TObject);
    procedure btnEjecutarScriptClick(Sender: TObject);
    procedure btnInstalarActualizacionClick(Sender: TObject);
    procedure tsFichaDetalleShow(Sender: TObject);
  private
    FSincronizando: Boolean;
    dmmErroresEnvios: TdmErroresEnvios;
    function CampoTexto(const ANombre: string): string;
    function HayRegistroActual(AMostrarAviso: Boolean = True): Boolean;
    procedure ActualizarAccionesFicha;
    procedure SincronizarFicha(AMostrarResultado: Boolean);
    procedure MostrarEstadoSincronizacion(
      const ATexto: string; AColor: TColor);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibMensajesVcl,
  Winapi.ShellAPI,
  System.UITypes,
  inLibActualizacionSoporte,
  inLibAnfitrionMtoIntf,
  inLibSeguimientoErrores,
  inLibMsgSeguimientoErrores,
  inMtoModalMensajeTexto;

{$R *.dfm}


procedure TfrmMtoErroresEnvios.CrearTablaPrincipal;
begin
  inherited;
  dmmErroresEnvios := tdmDataModule as TdmErroresEnvios;
  dmmErroresEnvios.ConfigurarVisibilidad(
    IdentidadSesion.Usuario,
    IdentidadSesion.EsAdministrador);
  pkFieldName := 'ID_ERENV';
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Edit.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Post.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  actInsertarRegistro.ShortCut := 0;
  actInsertarRegistro.OnExecute := nil;
  actEliminarRegistro.ShortCut := 0;
  actEliminarRegistro.OnExecute := nil;
end;

procedure TfrmMtoErroresEnvios.ResetForm;
begin
  inherited;
end;

function TfrmMtoErroresEnvios.HayRegistroActual(
  AMostrarAviso: Boolean): Boolean;
begin
  Result := Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty;
  if not Result and AMostrarAviso then
    MessageDlg_fza(
      SErrorEnvioErrorNoSeleccionado,
      mtInformation,
      [mbOk],
      0);
end;

function TfrmMtoErroresEnvios.CampoTexto(
  const ANombre: string): string;
begin
  Result := '';
  if HayRegistroActual(False) then
    Result := dsTablaG.DataSet.FieldByName(ANombre).AsString;
end;

procedure TfrmMtoErroresEnvios.ActualizarAccionesFicha;
var
  bEjecutablePendiente: Boolean;
  bScriptPendiente: Boolean;
begin
  bScriptPendiente := HayRegistroActual(False) and
    SameText(CampoTexto('ESTADO_SCRIPT_ERENV'), 'PROPUESTO') and
    (Trim(CampoTexto('SCRIPT_SQL_ERENV')) <> '');
  bEjecutablePendiente := HayRegistroActual(False) and
    SameText(CampoTexto('ESTADO_EJECUTABLE_ERENV'), 'PROPUESTO') and
    (Trim(CampoTexto('URL_EJECUTABLE_ERENV')) <> '');
  btnEjecutarScript.Enabled := bScriptPendiente;
  btnFichaEjecutarScript.Enabled := bScriptPendiente;
  btnInstalarActualizacion.Enabled := bEjecutablePendiente;
  btnFichaInstalarActualizacion.Enabled := bEjecutablePendiente;
end;

procedure TfrmMtoErroresEnvios.MostrarEstadoSincronizacion(
  const ATexto: string; AColor: TColor);
begin
  lblEstadoSincronizacion.Caption := ATexto;
  lblEstadoSincronizacion.Hint := ATexto;
  lblEstadoSincronizacion.Style.TextColor := AColor;
end;

procedure TfrmMtoErroresEnvios.SincronizarFicha(
  AMostrarResultado: Boolean);
var
  CursorAnterior: TCursor;
  sError: string;
begin
  if not FSincronizando and Assigned(dmmErroresEnvios) and
     HayRegistroActual(False) then
  begin
    FSincronizando := True;
    CursorAnterior := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    MostrarEstadoSincronizacion(
      SInfoConsultandoSeguimientoEnvioError, clNavy);
    lblEstadoSincronizacion.Repaint;
    try
      if dmmErroresEnvios.ActualizarActual(sError) then
      begin
        MostrarEstadoSincronizacion(
          SInfoSeguimientoEnvioErrorSincronizado, clGreen);
        if AMostrarResultado then
          MessageDlg_fza(
            SInfoSeguimientoEnvioErrorActualizado,
            mtInformation,
            [mbOk],
            0);
      end
      else
      begin
        MostrarEstadoSincronizacion(
          Format(SErrorSincronizarSeguimientoEnvioError, [sError]),
          clRed);
        if AMostrarResultado then
          MessageDlg_fza(sError, mtError, [mbOk], 0);
      end;
    finally
      ActualizarAccionesFicha;
      Screen.Cursor := CursorAnterior;
      FSincronizando := False;
    end;
  end;
end;

procedure TfrmMtoErroresEnvios.tsFichaDetalleShow(Sender: TObject);
begin
  inherited tsFichaShow(Sender);
  SincronizarFicha(False);
end;

procedure TfrmMtoErroresEnvios.btnActualizarEstadoClick(
  Sender: TObject);
begin
  if HayRegistroActual then
    SincronizarFicha(True);
end;

procedure TfrmMtoErroresEnvios.btnEnviarComentarioClick(
  Sender: TObject);
var
  sError: string;
  sMensaje: string;
begin
  if HayRegistroActual then
  begin
    sMensaje := '';
    if TfrmModalMensajeTexto.Solicitar(
         Self,
         STituloComentarioEnvioError,
         sMensaje) then
    begin
      if Trim(sMensaje) = '' then
        MessageDlg_fza(SErrorComentarioEnvioErrorVacio,
          mtWarning, [mbOk], 0)
      else if dmmErroresEnvios.EnviarComentarioActual(
                sMensaje,
                sError) then
      begin
        MostrarEstadoSincronizacion(
          SInfoComentarioEnvioErrorConversacion, clGreen);
        MessageDlg_fza(
          SInfoComentarioEnvioErrorEnviado,
          mtInformation,
          [mbOk],
          0);
      end
      else
        MessageDlg_fza(sError, mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrmMtoErroresEnvios.btnAbrirSeguimientoClick(
  Sender: TObject);
var
  sUrl: string;
begin
  if HayRegistroActual then
  begin
    sUrl := CampoTexto('URL_SEGUIMIENTO_ERENV');
    if Trim(sUrl) <> '' then
      ShellExecute(Handle, 'open', PChar(sUrl), nil, nil, SW_SHOWNORMAL)
    else
      MessageDlg_fza(
        SInfoEnlaceSeguimientoEnvioErrorNoDisponible,
        mtInformation,
        [mbOk],
        0);
  end;
end;

procedure TfrmMtoErroresEnvios.btnEjecutarScriptClick(
  Sender: TObject);
var
  Anfitrion: IAnfitrionMantenimiento;
  iId: Int64;
  sDescripcion: string;
  sError: string;
  sEstado: string;
  sHash: string;
  sSql: string;
  sTexto: string;
begin
  if HayRegistroActual then
  begin
    iId := dsTablaG.DataSet.FieldByName(
      'ID_SCRIPT_REMOTO_ERENV').AsLargeInt;
    sSql := CampoTexto('SCRIPT_SQL_ERENV');
    sDescripcion := CampoTexto('DESCRIPCION_SCRIPT_ERENV');
    sEstado := CampoTexto('ESTADO_SCRIPT_ERENV');
    sHash := CampoTexto('SHA256_SCRIPT_ERENV');
    if (iId <= 0) or (Trim(sSql) = '') or
       not SameText(sEstado, 'PROPUESTO') then
      MessageDlg_fza(
        SInfoScriptSoporteNoPendiente,
        mtInformation,
        [mbOk],
        0)
    else
    begin
      sTexto := Format(SDetalleScriptSoporte,
        [sDescripcion, sHash, sSql]);
      TfrmModalMensajeTexto.Mostrar(Self, sTexto);
      if MessageDlg_fza(
           SPreguntaEjecutarScriptSoporte,
           mtWarning,
           [mbYes, mbNo],
           0) = mrYes then
      begin
        Anfitrion := FAnfitrionMto;
        if not Assigned(Anfitrion) then
          MessageDlg_fza(
            SErrorServicioCopiaSeguridadNoDisponible,
            mtError,
            [mbOk],
            0)
        else if Anfitrion.CrearCopiaPreviaScriptSoporte then
        begin
          if dmmErroresEnvios.EjecutarScriptActual(sError) then
          begin
            ActualizarAccionesFicha;
            if sError = '' then
              MessageDlg_fza(
                SInfoScriptSoporteEjecutado,
                mtInformation,
                [mbOk],
                0)
            else
              MessageDlg_fza(sError, mtWarning, [mbOk], 0);
          end
          else
            MessageDlg_fza(sError, mtError, [mbOk], 0);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoErroresEnvios.btnInstalarActualizacionClick(
  Sender: TObject);
var
  iBytes: Int64;
  iId: Int64;
  sAnterior: string;
  sDescripcion: string;
  sError: string;
  sEstado: string;
  sHash: string;
  sNotificacion: string;
  sTexto: string;
  sUrl: string;
  sVersion: string;
begin
  if HayRegistroActual then
  begin
    iId := dsTablaG.DataSet.FieldByName(
      'ID_EJECUTABLE_REMOTO_ERENV').AsLargeInt;
    sUrl := CampoTexto('URL_EJECUTABLE_ERENV');
    sDescripcion := CampoTexto('DESCRIPCION_EJECUTABLE_ERENV');
    sVersion := CampoTexto('VERSION_EJECUTABLE_ERENV');
    sEstado := CampoTexto('ESTADO_EJECUTABLE_ERENV');
    sHash := CampoTexto('SHA256_EJECUTABLE_ERENV');
    iBytes := dsTablaG.DataSet.FieldByName(
      'CANTIDAD_BYTES_EJECUTABLE_ERENV').AsLargeInt;
    if (iId <= 0) or (Trim(sUrl) = '') or
       not SameText(sEstado, 'PROPUESTO') then
      MessageDlg_fza(
        SInfoActualizacionSoporteNoPendiente,
        mtInformation,
        [mbOk],
        0)
    else
    begin
      sTexto := Format(SDetalleActualizacionSoporte,
        [sVersion, sDescripcion, FormatFloat('#,##0', iBytes), sHash]);
      TfrmModalMensajeTexto.Mostrar(Self, sTexto);
      if MessageDlg_fza(
           SPreguntaInstalarActualizacionSoporte,
           mtWarning,
           [mbYes, mbNo],
           0) = mrYes then
      begin
        if InstalarActualizacionSoporte(
             sUrl,
             sHash,
             iBytes,
             sAnterior,
             sError) then
        begin
          NotificarResultadoEjecutableError(
            CampoTexto('URL_SERVICIO_ERENV'),
            CampoTexto('REFERENCIA_ERENV'),
            CampoTexto('TOKEN_SEGUIMIENTO_ERENV'),
            iId,
            'INSTALADO',
            'Actualización aceptada; ViraCash se está reiniciando.',
            sNotificacion);
          Application.Terminate;
        end
        else
        begin
          NotificarResultadoEjecutableError(
            CampoTexto('URL_SERVICIO_ERENV'),
            CampoTexto('REFERENCIA_ERENV'),
            CampoTexto('TOKEN_SEGUIMIENTO_ERENV'),
            iId,
            'ERROR',
            sError,
            sNotificacion);
          MessageDlg_fza(sError, mtError, [mbOk], 0);
        end;
      end;
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoErroresEnvios);

end.
