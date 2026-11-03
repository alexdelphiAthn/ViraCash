{ Captura y confirmación de cambios de trabajo. TRJ-004, 02/11/2026. }
unit inMtoModalCambioTrabajo;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.Forms,
  cxTextEdit, cxDropDownEdit, cxButtonEdit, cxCurrencyEdit, cxLabel,
  inMtoModalAceptCancel, inLibCambiosTrabajo, UniDataCambiosTrabajo;

type
  TfrmModalCambioTrabajo = class(TfrmModalAceptCancel)
  private
    FCambio: TCambioTrabajo;
    FRepositorio: TRepositorioCambiosTrabajo;
    FResultado: Int64;
    FMotivo: TcxTextEdit;
    FTipo: TcxComboBox;
    FEjecutor: TcxButtonEdit;
    FNombreEjecutor: TcxLabel;
    FCantidad: TcxCurrencyEdit;
    FCoste: TcxCurrencyEdit;
    FResponsable: TcxButtonEdit;
    procedure CrearCampos;
    procedure ColocarCampo(AControl: TControl; const ARotulo: string;
      AFila: Integer);
    function TipoElegido: string;
    procedure TipoCambiado(Sender: TObject);
    procedure BuscarEjecutor(Sender: TObject; AButtonIndex: Integer);
    procedure BuscarResponsable(Sender: TObject; AButtonIndex: Integer);
    function ValidarCampos: Boolean;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
    procedure MostrarCampos(Sender: TObject);
  public
    function CloseQuery: Boolean; override;
    class procedure Ejecutar(AOwner: TComponent;
      ALinea: TDataSet; ARepetir: Boolean);
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs, cxEdit,
  inLibReparaciones, inLibMsgReparaciones,
  inLibMensajesVcl, inLibPermisosIntf;

procedure TfrmModalCambioTrabajo.ColocarCampo(AControl: TControl;
  const ARotulo: string; AFila: Integer);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Transparent := True;
  oRotulo.Caption := ARotulo;
  oRotulo.SetBounds(ScaleValue(12), ScaleValue(8 + AFila * 55),
    ScaleValue(430), ScaleValue(22));
  AControl.Parent := pnlBody;
  AControl.SetBounds(ScaleValue(12), ScaleValue(30 + AFila * 55),
    ScaleValue(430), ScaleValue(26));
end;

procedure TfrmModalCambioTrabajo.CrearCampos;
begin
  ClientWidth := ScaleValue(460);
  ClientHeight := ScaleValue(354) + pnlButton.Height;
  btnCancelar.Left := ScaleValue(12);
  btnAceptar.Left := ClientWidth - btnAceptar.Width - ScaleValue(12);
  FMotivo := TcxTextEdit.Create(Self);
  FMotivo.Name := 'edtMotivoCambio';
  FMotivo.Text := '';
  ColocarCampo(FMotivo, SCambioTrabajoMotivo, 0);
  FMotivo.Properties.MaxLength := 500;
  FTipo := TcxComboBox.Create(Self);
  FTipo.Name := 'cbbTipoEjecutor';
  ColocarCampo(FTipo, SCambioTrabajoTipo, 1);
  FTipo.Properties.DropDownListStyle := lsFixedList;
  FTipo.Properties.Items.Add(
    TextoEjecutorReparacion(EJECUTOR_REPARACION_OPERARIO));
  FTipo.Properties.Items.Add(
    TextoEjecutorReparacion(EJECUTOR_REPARACION_EXTERNO));
  FTipo.ItemIndex := -1;
  FTipo.Text := '';
  FEjecutor := TcxButtonEdit.Create(Self);
  FEjecutor.Name := 'btnEjecutorCambio';
  FEjecutor.Text := '';
  ColocarCampo(FEjecutor, SCambioTrabajoCodigo, 2);
  FEjecutor.Width := ScaleValue(130);
  FEjecutor.Properties.ReadOnly := True;
  FEjecutor.Properties.MaxLength := 20;
  FEjecutor.Properties.Buttons.Clear;
  FEjecutor.Properties.Buttons.Add.Kind := bkEllipsis;
  FEjecutor.Properties.OnButtonClick := BuscarEjecutor;
  FNombreEjecutor := TcxLabel.Create(Self);
  FNombreEjecutor.Name := 'lblNombreEjecutorCambio';
  FNombreEjecutor.Parent := pnlBody;
  FNombreEjecutor.Caption := '';
  FNombreEjecutor.Transparent := True;
  FNombreEjecutor.AutoSize := False;
  FNombreEjecutor.ShowHint := True;
  FNombreEjecutor.SetBounds(ScaleValue(152), FEjecutor.Top,
    ScaleValue(290), ScaleValue(26));
  FTipo.Properties.OnChange := TipoCambiado;
  if FCambio.TipoEjecutor = EJECUTOR_REPARACION_OPERARIO then
    FTipo.ItemIndex := 0
  else if FCambio.TipoEjecutor = EJECUTOR_REPARACION_EXTERNO then
    FTipo.ItemIndex := 1;
  FCantidad := TcxCurrencyEdit.Create(Self);
  FCantidad.Name := 'edtCantidadCambio';
  ColocarCampo(FCantidad, SCambioTrabajoCantidad, 3);
  FCantidad.Properties.DecimalPlaces := 6;
  FCantidad.Properties.DisplayFormat := '0.######';
  FCantidad.Value := FCambio.Cantidad;
  FCoste := TcxCurrencyEdit.Create(Self);
  FCoste.Name := 'edtCosteCambio';
  ColocarCampo(FCoste, SCambioTrabajoCoste, 4);
  FCoste.Properties.DecimalPlaces := 6;
  FCoste.Properties.DisplayFormat := '0.00####';
  FCoste.Value := 0;
  FResponsable := TcxButtonEdit.Create(Self);
  FResponsable.Name := 'btnResponsableCambio';
  ColocarCampo(FResponsable, SCambioTrabajoResponsable, 5);
  FResponsable.Properties.ReadOnly := True;
  FResponsable.Properties.MaxLength := 100;
  FResponsable.Properties.Buttons.Clear;
  FResponsable.Properties.Buttons.Add.Kind := bkEllipsis;
  FResponsable.Properties.OnButtonClick := BuscarResponsable;
  FResponsable.Text := IdentidadSesion.Usuario;
end;

function TfrmModalCambioTrabajo.TipoElegido: string;
begin
  Result := '';
  if FTipo.ItemIndex = 0 then
    Result := EJECUTOR_REPARACION_OPERARIO
  else if FTipo.ItemIndex = 1 then
    Result := EJECUTOR_REPARACION_EXTERNO;
end;

procedure TfrmModalCambioTrabajo.TipoCambiado(Sender: TObject);
begin
  FEjecutor.Text := '';
  FNombreEjecutor.Caption := '';
  FNombreEjecutor.Hint := '';
end;

procedure TfrmModalCambioTrabajo.BuscarEjecutor(Sender: TObject;
  AButtonIndex: Integer);
var
  oDatos: TDataSet;
begin
  if TipoElegido = '' then
  begin
    ShowMessage_fza(SCambioTrabajoFaltaTipo);
    FTipo.SetFocus;
  end
  else
  begin
    if not Assigned(BusquedaVisual) then
      raise EInvalidOpException.Create(SErrorBusquedaTipoServicio);
    oDatos := FRepositorio.ConsultarEjecutores(TipoElegido);
    try
      if BusquedaVisual.EjecutarBusquedaDataSet(SCambioTrabajoCodigo,
        oDatos, 'srchCambioTrabajo_' + TipoElegido, Self) then
      begin
        FEjecutor.Text := oDatos.FieldByName('CODIGO').AsString;
        FNombreEjecutor.Caption := oDatos.FieldByName('NOMBRE').AsString;
        FNombreEjecutor.Hint := FNombreEjecutor.Caption;
      end;
    finally
      FreeAndNil(oDatos);
    end;
  end;
end;

procedure TfrmModalCambioTrabajo.BuscarResponsable(Sender: TObject;
  AButtonIndex: Integer);
var
  oDatos: TDataSet;
begin
  if not Assigned(BusquedaVisual) then
    raise EInvalidOpException.Create(SErrorBusquedaTipoServicio);
  oDatos := FRepositorio.ConsultarResponsables;
  try
    if BusquedaVisual.EjecutarBusquedaDataSet(SCambioTrabajoResponsable,
      oDatos, 'srchResponsableCambioTrabajo', Self) then
      FResponsable.Text := oDatos.FieldByName('USUARIO').AsString;
  finally
    FreeAndNil(oDatos);
  end;
end;

function TfrmModalCambioTrabajo.ValidarCampos: Boolean;
var
  sError: string;
  oCampo: TWinControl;
begin
  sError := '';
  oCampo := nil;
  FCambio.Motivo := Trim(FMotivo.Text);
  FCambio.TipoEjecutor := TipoElegido;
  FCambio.Ejecutor := Trim(FEjecutor.Text);
  FCambio.Cantidad := FCantidad.Value;
  FCambio.CosteAdicional := FCoste.Value;
  FCambio.ResponsableCoste := Trim(FResponsable.Text);
  if FCambio.Motivo = '' then
  begin
    sError := SCambioTrabajoFaltaMotivo;
    oCampo := FMotivo;
  end
  else if FCambio.TipoEjecutor = '' then
  begin
    sError := SCambioTrabajoFaltaTipo;
    oCampo := FTipo;
  end
  else if FCambio.Ejecutor = '' then
  begin
    sError := SCambioTrabajoFaltaEjecutor;
    oCampo := FEjecutor;
  end
  else if (FCambio.Cantidad <= 0) or (FCambio.Cantidad > 1000000) then
  begin
    sError := SCambioTrabajoCantidadInvalida;
    oCampo := FCantidad;
  end
  else if (FCambio.CosteAdicional < 0) or
          (FCambio.CosteAdicional > 1000000) then
  begin
    sError := SCambioTrabajoCosteInvalido;
    oCampo := FCoste;
  end
  else if FCambio.ResponsableCoste = '' then
  begin
    sError := SCambioTrabajoFaltaResponsable;
    oCampo := FResponsable;
  end;
  Result := sError = '';
  if not Result then
  begin
    ShowMessage_fza(sError);
    if Assigned(oCampo) and oCampo.CanFocus then
      oCampo.SetFocus;
  end;
end;

function TfrmModalCambioTrabajo.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') and (FResultado = 0) then
  begin
    try
      Result := ValidarCampos;
      if Result then
      begin
        FCambio.Aceptado := MessageDlg_fza(SCambioTrabajoConfirmar,
          mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes;
        Result := FCambio.Aceptado;
        if Result then
          FResultado := FRepositorio.Guardar(FCambio);
      end;
    except
      on E: Exception do
      begin
        Result := False;
        ShowMessage_fza(E.Message);
      end;
    end;
    if not Result then
      sFicha := 'N';
  end;
end;

procedure TfrmModalCambioTrabajo.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TfrmModalCambioTrabajo.MostrarCampos(Sender: TObject);
begin
  FormShow(Sender);
  if FMotivo.CanFocus then
    FMotivo.SetFocus;
end;

class procedure TfrmModalCambioTrabajo.Ejecutar(AOwner: TComponent;
  ALinea: TDataSet; ARepetir: Boolean);
var
  oFormulario: TfrmModalCambioTrabajo;
  gId: TGUID;
begin
  oFormulario := TfrmModalCambioTrabajo.Create(AOwner);
  try
    if not oFormulario.Permisos.TienePermiso('reparaciones.cambiarTrabajo',
      paExigirConcesion) then
      raise EInvalidOpException.Create(SCambioTrabajoSinPermiso);
    CreateGUID(gId);
    oFormulario.FCambio.Id := Copy(GUIDToString(gId), 2, 36);
    oFormulario.FCambio.Orden :=
      ALinea.FieldByName('ID_GAR_GARLIN').AsLargeInt;
    oFormulario.FCambio.Linea := ALinea.FieldByName('ID_GARLIN').AsLargeInt;
    oFormulario.FCambio.Revision :=
      ALinea.FieldByName('REVISION_CAMBIO').AsString;
    oFormulario.FCambio.Repetir := ARepetir;
    oFormulario.FCambio.TipoEjecutor :=
      ALinea.FieldByName('TIPO_EJECUTOR_GARLIN').AsString;
    oFormulario.FCambio.Cantidad :=
      ALinea.FieldByName('CANTIDAD_GARLIN').AsCurrency;
    oFormulario.FRepositorio := TRepositorioCambiosTrabajo.Create(
      oFormulario.ConexionPrincipal, oFormulario.IdentidadSesion.Usuario,
      oFormulario.Permisos);
    oFormulario.Caption := SCambioTrabajoTitulo;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.OnShow := oFormulario.MostrarCampos;
    oFormulario.CrearCampos;
    oFormulario.ShowModal;
    if oFormulario.FResultado > 0 then
      ShowMessage_fza(Format(SCambioTrabajoGrabado,
        [oFormulario.FResultado]));
  finally
    FreeAndNil(oFormulario.FRepositorio);
    FreeAndNil(oFormulario);
  end;
end;

end.
