{******************************************************************************}
{  Módulo: inMtoModalMedidasCliente. Fecha: 02/11/2026                          }
{  Descripción: Historial de medidas, nueva sesión, corrección y vínculo.      }
{******************************************************************************}
unit inMtoModalMedidasCliente;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, cxDropDownEdit, cxMemo,
  cxButtons, inMtoModalAceptCancel, UniDataMedidasCliente,
  inLibMedidasCliente;

type
  TfrmModalMedidasCliente = class(TfrmModalAceptCancel)
  private
    FRepositorio: TRepositorioMedidasCliente;
    FCliente: string;
    FOrden: Int64;
    FSesiones: TSesionesMedidasCliente;
    FSelector: TcxComboBox;
    FDetalle: TcxMemo;
    procedure CrearInterfaz;
    procedure CargarHistorial;
    procedure SeleccionCambio(Sender: TObject);
    procedure NuevaClick(Sender: TObject);
    procedure CorregirClick(Sender: TObject);
    procedure VincularClick(Sender: TObject);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
    procedure EditarSesion(ACorregir: Boolean);
    function CapturarSesion(var ASesion: TSesionMedidasCliente): Boolean;
    procedure CamposSesion(const ASesion: TSesionMedidasCliente;
      const AMagnitudes: TMagnitudesCliente;
      out ARotulos, AValores: TArray<string>);
    procedure LeerCampos(var ASesion: TSesionMedidasCliente;
      const AMagnitudes: TMagnitudesCliente; const AValores: TArray<string>);
  public
    destructor Destroy; override;
    class procedure Ejecutar(AOwner: TComponent; const ACliente: string;
      AOrden: Int64 = 0);
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs, cxLabel, cxGroupBox,
  inLibPermisosIntf, inLibMsgMedidasCliente, inLibMensajesVcl,
  inMtoModalDatosOrden;

class procedure TfrmModalMedidasCliente.Ejecutar(AOwner: TComponent;
  const ACliente: string; AOrden: Int64);
var
  oFormulario: TfrmModalMedidasCliente;
begin
  if Trim(ACliente) = '' then
    raise EArgumentException.Create(SMedidasClienteInexistente);
  oFormulario := TfrmModalMedidasCliente.Create(AOwner);
  try
    oFormulario.FCliente := ACliente;
    oFormulario.FOrden := AOrden;
    oFormulario.FRepositorio := TRepositorioMedidasCliente.Create(
      oFormulario.ConexionPrincipal, oFormulario.Permisos,
      oFormulario.IdentidadSesion.Usuario);
    if not oFormulario.FRepositorio.Disponible then
      raise EInvalidOpException.Create(SMedidasMigracionPendiente);
    oFormulario.CrearInterfaz;
    oFormulario.CargarHistorial;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

destructor TfrmModalMedidasCliente.Destroy;
begin
  FreeAndNil(FRepositorio);
  inherited;
end;

procedure TfrmModalMedidasCliente.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TfrmModalMedidasCliente.CrearInterfaz;
var
  oBarra: TcxGroupBox;
  oBoton: TcxButton;
  procedure Boton(const ATexto, APermiso: string; AClick: TNotifyEvent;
    AVisible: Boolean);
  begin
    oBoton := TcxButton.Create(Self);
    oBoton.Parent := oBarra;
    oBoton.Align := alLeft;
    oBoton.Width := ScaleValue(190);
    oBoton.Caption := ATexto;
    oBoton.OnClick := AClick;
    oBoton.Visible := AVisible;
    oBoton.Enabled := Permisos.TienePermiso(
      'clientes.medidas.' + APermiso, paExigirConcesion);
  end;
begin
  Caption := SMedidasTitulo + ' - ' + FCliente;
  ClientWidth := ScaleValue(760);
  ClientHeight := ScaleValue(520);
  OnClose := CerrarSinLiberar;
  btnAceptar.Visible := False;
  btnCancelar.Caption := SMedidasCerrar;
  btnCancelar.Left := ScaleValue(12);
  FSelector := TcxComboBox.Create(Self);
  FSelector.Parent := pnlBody;
  FSelector.Align := alTop;
  FSelector.Properties.DropDownListStyle := lsFixedList;
  FSelector.Properties.OnChange := SeleccionCambio;
  oBarra := TcxGroupBox.Create(Self);
  oBarra.Parent := pnlBody;
  oBarra.PanelStyle.Active := True;
  oBarra.Align := alBottom;
  oBarra.Height := ScaleValue(45);
  Boton(SMedidasNueva, 'alta', NuevaClick, True);
  Boton(SMedidasCorregir, 'corregir', CorregirClick, True);
  Boton(SMedidasVincular, 'vincular', VincularClick, FOrden > 0);
  FDetalle := TcxMemo.Create(Self);
  FDetalle.Parent := pnlBody;
  FDetalle.Align := alClient;
  FDetalle.Properties.ReadOnly := True;
end;

procedure TfrmModalMedidasCliente.CargarHistorial;
var
  rSesion: TSesionMedidasCliente;
begin
  FSesiones := FRepositorio.Historial(FCliente);
  FSelector.Properties.Items.Clear;
  for rSesion in FSesiones do
    FSelector.Properties.Items.Add(DateToStr(rSesion.Fecha) + ' - ' +
      rSesion.Persona + ' - ' + rSesion.Usuario + ' - ' + rSesion.Id);
  if Length(FSesiones) > 0 then
    FSelector.ItemIndex := 0;
  SeleccionCambio(nil);
end;

procedure TfrmModalMedidasCliente.SeleccionCambio(Sender: TObject);
var
  rSesion: TSesionMedidasCliente;
  sFoto: string;
begin
  FDetalle.Clear;
  if (FSelector.ItemIndex >= 0) and
     (FSelector.ItemIndex < Length(FSesiones)) then
  begin
    rSesion := FRepositorio.Leer(FCliente, FSesiones[FSelector.ItemIndex].Id);
    FDetalle.Text := TextoSesionMedidas(rSesion) + sLineBreak +
      SMedidasMotivo + ': ' + rSesion.Motivo;
  end;
  if FOrden > 0 then
  begin
    sFoto := FRepositorio.Fotografia(FOrden, FCliente);
    if sFoto <> '' then
      FDetalle.Text := FDetalle.Text + sLineBreak + sLineBreak +
        SMedidasVinculadas + sLineBreak + sFoto;
  end;
end;

procedure TfrmModalMedidasCliente.NuevaClick(Sender: TObject);
begin
  EditarSesion(False);
end;

procedure TfrmModalMedidasCliente.CorregirClick(Sender: TObject);
begin
  if FSelector.ItemIndex >= 0 then
    EditarSesion(True);
end;

procedure TfrmModalMedidasCliente.VincularClick(Sender: TObject);
begin
  if FSelector.ItemIndex >= 0 then
  begin
    FRepositorio.Vincular(FOrden, FCliente,
      FSesiones[FSelector.ItemIndex].Id);
    SeleccionCambio(nil);
    ShowMessage_fza(SMedidasVinculadas);
  end;
end;

procedure TfrmModalMedidasCliente.EditarSesion(ACorregir: Boolean);
var
  rSesion: TSesionMedidasCliente;
begin
  rSesion := Default(TSesionMedidasCliente);
  rSesion.Cliente := FCliente;
  rSesion.Fecha := Date;
  rSesion.Persona := IdentidadSesion.Usuario;
  if ACorregir then
  begin
    rSesion := FRepositorio.Leer(FCliente, FSesiones[FSelector.ItemIndex].Id);
    rSesion.Origen := rSesion.Id;
    rSesion.Id := '';
    rSesion.Motivo := '';
  end;
  if CapturarSesion(rSesion) then
  begin
    FRepositorio.Guardar(rSesion);
    CargarHistorial;
    ShowMessage_fza(SMedidasGuardadas);
  end;
end;

procedure TfrmModalMedidasCliente.CamposSesion(
  const ASesion: TSesionMedidasCliente;
  const AMagnitudes: TMagnitudesCliente;
  out ARotulos, AValores: TArray<string>);
var
  iIndice: Integer;
  rValor: TMedidaCliente;
begin
  SetLength(ARotulos, Length(AMagnitudes) + 4);
  SetLength(AValores, Length(ARotulos));
  ARotulos[0] := SMedidasFecha;
  ARotulos[1] := SMedidasPersona;
  ARotulos[2] := SMedidasObservaciones;
  ARotulos[3] := SMedidasMotivo;
  AValores[0] := DateToStr(ASesion.Fecha);
  AValores[1] := ASesion.Persona;
  AValores[2] := ASesion.Observaciones;
  AValores[3] := ASesion.Motivo;
  for iIndice := 0 to High(AMagnitudes) do
  begin
    ARotulos[iIndice + 4] := AMagnitudes[iIndice].Nombre + ' (' +
      AMagnitudes[iIndice].Unidad + ')';
    for rValor in ASesion.Valores do
      if (rValor.Codigo = AMagnitudes[iIndice].Codigo) and rValor.Conocida then
        AValores[iIndice + 4] := CurrToStr(rValor.Valor);
  end;
end;

procedure TfrmModalMedidasCliente.LeerCampos(
  var ASesion: TSesionMedidasCliente;
  const AMagnitudes: TMagnitudesCliente; const AValores: TArray<string>);
var
  iIndice: Integer;
begin
  if not TryStrToDate(AValores[0], ASesion.Fecha) then
    raise EArgumentException.Create(SMedidasFechaInvalida);
  ASesion.Persona := Trim(AValores[1]);
  ASesion.Observaciones := AValores[2];
  ASesion.Motivo := Trim(AValores[3]);
  SetLength(ASesion.Valores, Length(AMagnitudes));
  for iIndice := 0 to High(AMagnitudes) do
  begin
    ASesion.Valores[iIndice].Codigo := AMagnitudes[iIndice].Codigo;
    ASesion.Valores[iIndice].Nombre := AMagnitudes[iIndice].Nombre;
    ASesion.Valores[iIndice].Unidad := AMagnitudes[iIndice].Unidad;
    ASesion.Valores[iIndice].Conocida := Trim(AValores[iIndice + 4]) <> '';
    if ASesion.Valores[iIndice].Conocida and
       not TryStrToCurr(AValores[iIndice + 4],
         ASesion.Valores[iIndice].Valor) then
      raise EArgumentException.Create(SMedidasValorInvalido);
  end;
end;

function TfrmModalMedidasCliente.CapturarSesion(
  var ASesion: TSesionMedidasCliente): Boolean;
var
  aMagnitudes: TMagnitudesCliente;
  aRotulos, aValores: TArray<string>;
  sAviso: string;
begin
  aMagnitudes := FRepositorio.Magnitudes;
  CamposSesion(ASesion, aMagnitudes, aRotulos, aValores);
  Result := TfrmModalDatosOrden.Ejecutar(Self,
    SMedidasTitulo + '. ' + SMedidasVacia, aRotulos, aValores);
  if Result then
  begin
    LeerCampos(ASesion, aMagnitudes, aValores);
    sAviso := ValidarSesionMedidas(ASesion, aMagnitudes);
    if sAviso <> '' then
    begin
      Result := MessageDlg_fza(SMedidasFueraRango + sLineBreak + sAviso +
        sLineBreak + SMedidasConfirmarRango, mtWarning,
        [mbYes, mbNo], 0, mbNo) = mrYes;
      ASesion.AceptaFueraRango := Result;
    end;
  end;
end;

end.
