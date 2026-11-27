{******************************************************************************}
{  Módulo: inMtoModalMedidasCliente. Fecha: 02/11/2026                          }
{  Descripción: Historial de medidas, nueva sesión, corrección y vínculo.      }
{******************************************************************************}
unit inMtoModalMedidasCliente;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Data.DB, cxPC,
  inMtoFrmBase, inMtoModalAceptCancel;

type
  TfrmModalMedidasCliente = class(TfrmModalAceptCancel)
  private
    FIdElegido: string;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
    procedure PrepararDialogo(const ACliente: string);
  public
    class function Elegir(AOwner: TComponent; const ACliente: string;
      out AId: string): Boolean;
    class procedure Ejecutar(AOwner: TComponent; const ACliente: string;
      AOrden: Int64 = 0);
  end;

function CrearPestanaMedidas(AFormulario: TfrmBase; APaginas: TcxPageControl;
  AOrigen: TDataSource; const ACampoCliente: string): TcxTabSheet;

implementation

uses
  System.SysUtils, System.UITypes, System.Variants, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.Menus, cxLabel, cxGroupBox, cxDropDownEdit, cxMemo, cxButtons,
  inLibPermisosIntf, inLibMsgMedidasCliente, inLibMensajesVcl,
  inLibMedidasCliente, UniDataMedidasCliente, inMtoModalDatosOrden,
  inMtoModalImpMedidasCliente, inMtoPaginaExtension;

type
  TPanelMedidas = class(TPanel)
  private
    FAnfitrion: TfrmBase;
    FRepositorio: TRepositorioMedidasCliente;
    FCliente: string;
    FOrden: Int64;
    FElegir: Boolean;
    FSesiones: TSesionesMedidasCliente;
    FSelector: TcxComboBox;
    FDetalle: TcxMemo;
    FImprimir, FCorregir: TcxButton;
    procedure CrearInterfaz;
    procedure CargarHistorial;
    procedure SeleccionCambio(Sender: TObject);
    procedure NuevaClick(Sender: TObject);
    procedure CorregirClick(Sender: TObject);
    procedure ImprimirClick(Sender: TObject);
    procedure VincularClick(Sender: TObject);
    procedure EditarSesion(ACorregir: Boolean);
    function CapturarSesion(var ASesion: TSesionMedidasCliente): Boolean;
    procedure CamposSesion(const ASesion: TSesionMedidasCliente;
      const AMagnitudes: TMagnitudesCliente;
      out ARotulos, AValores: TArray<string>);
    procedure LeerCampos(var ASesion: TSesionMedidasCliente;
      const AMagnitudes: TMagnitudesCliente; const AValores: TArray<string>);
  public
    constructor CrearEn(AAnfitrion: TfrmBase; AContenedor: TWinControl;
      const ACliente: string; AOrden: Int64; AElegir: Boolean);
    destructor Destroy; override;
  end;

  TPestanaMedidas = class(TPestanaVinculada)
  private
    FAnfitrion: TfrmBase;
  protected
    function Montar(const AClave: Variant): TComponent; override;
  end;

function CrearPestanaMedidas(AFormulario: TfrmBase; APaginas: TcxPageControl;
  AOrigen: TDataSource; const ACampoCliente: string): TcxTabSheet;
var
  Tab: TPestanaMedidas;
begin
  Tab := TPestanaMedidas.Create(APaginas);
  try
    Tab.FAnfitrion := AFormulario;
    Tab.Vincular(APaginas, AOrigen, ACampoCliente, SMedidasTitulo,
      SMedidasSeleccioneCliente);
    Result := Tab;
  except
    Tab.Free;
    raise;
  end;
end;

function TPestanaMedidas.Montar(const AClave: Variant): TComponent;
begin
  Result := TPanelMedidas.CrearEn(FAnfitrion, Self, VarToStr(AClave), 0, False);
end;

constructor TPanelMedidas.CrearEn(AAnfitrion: TfrmBase;
  AContenedor: TWinControl; const ACliente: string; AOrden: Int64;
  AElegir: Boolean);
begin
  inherited Create(AContenedor);
  FAnfitrion := AAnfitrion;
  FCliente := ACliente;
  FOrden := AOrden;
  FElegir := AElegir;
  FRepositorio := TRepositorioMedidasCliente.Create(AAnfitrion.ConexionPrincipal,
    AAnfitrion.Permisos, AAnfitrion.IdentidadSesion.Usuario);
  if not AAnfitrion.Permisos.TienePermiso('clientes.medidas.consultar',
    paExigirConcesion) then
    raise EInvalidOpException.Create(SMedidasSinPermiso);
  if not FRepositorio.Disponible then
    raise EInvalidOpException.Create(SMedidasMigracionPendiente);
  Parent := AContenedor;
  Align := alClient;
  BevelOuter := bvNone;
  ShowCaption := False;
  CrearInterfaz;
  CargarHistorial;
end;

procedure TfrmModalMedidasCliente.PrepararDialogo(const ACliente: string);
begin
  Caption := SMedidasTitulo + ' - ' + ACliente;
  ClientWidth := ScaleValue(760);
  ClientHeight := ScaleValue(520);
  OnClose := CerrarSinLiberar;
  btnAceptar.Visible := False;
  btnCancelar.Caption := SMedidasCerrar;
  btnCancelar.Left := ScaleValue(12);
end;

class procedure TfrmModalMedidasCliente.Ejecutar(AOwner: TComponent;
  const ACliente: string; AOrden: Int64);
var
  oFormulario: TfrmModalMedidasCliente;
begin
  if Trim(ACliente) = '' then
    raise EArgumentException.Create(SMedidasClienteInexistente);
  oFormulario := TfrmModalMedidasCliente.Create(AOwner);
  try
    oFormulario.PrepararDialogo(ACliente);
    TPanelMedidas.CrearEn(oFormulario, oFormulario.pnlBody,
      ACliente, AOrden, False);
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

class function TfrmModalMedidasCliente.Elegir(AOwner: TComponent;
  const ACliente: string; out AId: string): Boolean;
var
  oFormulario: TfrmModalMedidasCliente;
  Panel: TPanelMedidas;
begin
  AId := '';
  if Trim(ACliente) = '' then
    raise EArgumentException.Create(SMedidasClienteInexistente);
  oFormulario := TfrmModalMedidasCliente.Create(AOwner);
  try
    oFormulario.PrepararDialogo(ACliente);
    if not oFormulario.Permisos.TienePermiso(
      'clientes.medidas.vincular', paExigirConcesion) then
      raise EInvalidOpException.Create(SMedidasSinPermiso);
    Panel := TPanelMedidas.CrearEn(oFormulario, oFormulario.pnlBody,
      ACliente, 0, True);
    if (Length(Panel.FSesiones) = 0) and
       oFormulario.Permisos.TienePermiso('clientes.medidas.alta',
         paExigirConcesion) then
      Panel.EditarSesion(False);
    Result := oFormulario.ShowModal = mrOk;
    if Result then
      AId := oFormulario.FIdElegido;
    Result := Result and (AId <> '');
  finally
    oFormulario.Free;
  end;
end;

destructor TPanelMedidas.Destroy;
begin
  FreeAndNil(FRepositorio);
  inherited;
end;

procedure TfrmModalMedidasCliente.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TPanelMedidas.CrearInterfaz;
var
  oBarra: TcxGroupBox;
  oBoton: TcxButton;
  Menu: TPopupMenu;
  Opcion: TMenuItem;
  Ficha: TFichaMedidas;
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
    oBoton.Enabled := FAnfitrion.Permisos.TienePermiso(
      'clientes.medidas.' + APermiso, paExigirConcesion);
  end;
begin
  FSelector := TcxComboBox.Create(Self);
  FSelector.Parent := Self;
  FSelector.Align := alTop;
  FSelector.Properties.DropDownListStyle := lsFixedList;
  FSelector.Properties.OnChange := SeleccionCambio;
  oBarra := TcxGroupBox.Create(Self);
  oBarra.Parent := Self;
  oBarra.PanelStyle.Active := True;
  oBarra.Align := alBottom;
  oBarra.Height := ScaleValue(45);
  if FElegir then
    Boton(SMedidasCompletar, 'alta', NuevaClick, True)
  else
    Boton(SMedidasNueva, 'alta', NuevaClick, True);
  Boton(SMedidasCorregir, 'corregir', CorregirClick, True);
  FCorregir := oBoton;
  Boton(SMedidasEnviar, 'vincular', VincularClick,
    (FOrden > 0) or FElegir);
  Boton(SMedidasImprimir, 'consultar', nil, True);
  FImprimir := oBoton;
  FImprimir.Width := ScaleValue(150);
  Menu := TPopupMenu.Create(Self);
  for Ficha := Low(TFichaMedidas) to High(TFichaMedidas) do
  begin
    Opcion := TMenuItem.Create(Menu);
    Opcion.Caption := TituloFichaMedidas(Ficha);
    Opcion.Tag := Ord(Ficha);
    Opcion.OnClick := ImprimirClick;
    Menu.Items.Add(Opcion);
  end;
  FImprimir.Kind := cxbkDropDown;
  FImprimir.DropDownMenu := Menu;
  FDetalle := TcxMemo.Create(Self);
  FDetalle.Parent := Self;
  FDetalle.Align := alClient;
  FDetalle.Properties.ReadOnly := True;
end;

procedure TPanelMedidas.CargarHistorial;
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

procedure TPanelMedidas.SeleccionCambio(Sender: TObject);
var
  rSesion: TSesionMedidasCliente;
  sFoto: string;
  Ficha: TFichaMedidas;
  Valor: TMedidaCliente;
begin
  FDetalle.Clear;
  FImprimir.Enabled := (FSelector.ItemIndex >= 0) and
    (FSelector.ItemIndex < Length(FSesiones));
  FCorregir.Enabled := FImprimir.Enabled and
    FAnfitrion.Permisos.TienePermiso('clientes.medidas.corregir',
      paExigirConcesion);
  if FImprimir.Enabled then
  begin
    rSesion := FRepositorio.Leer(FCliente, FSesiones[FSelector.ItemIndex].Id);
    for Ficha := Low(TFichaMedidas) to High(TFichaMedidas) do
    begin
      TPopupMenu(FImprimir.DropDownMenu).Items[Ord(Ficha)].Enabled :=
        Ficha = fmCompleta;
      for Valor in rSesion.Valores do
        if IncluyeMagnitud(Ficha, Valor.Codigo) then
          TPopupMenu(FImprimir.DropDownMenu).Items[Ord(Ficha)].Enabled := True;
    end;
    FDetalle.Text := TextoSesionMedidas(rSesion) + sLineBreak +
      SMedidasMotivo + ': ' + rSesion.Motivo;
  end;
  if Length(FSesiones) = 0 then
    FDetalle.Text := SMedidasSinMediciones;
  if FOrden > 0 then
  begin
    sFoto := FRepositorio.Fotografia(FOrden, FCliente);
    if sFoto <> '' then
      FDetalle.Text := FDetalle.Text + sLineBreak + sLineBreak +
        SMedidasVinculadas + sLineBreak + sFoto;
  end;
end;

procedure TPanelMedidas.ImprimirClick(Sender: TObject);
begin
  if (FSelector.ItemIndex >= 0) and (FSelector.ItemIndex < Length(FSesiones)) then
    TfrmPrintMedidasCliente.Abrir(FAnfitrion,
      FRepositorio.Leer(FCliente, FSesiones[FSelector.ItemIndex].Id),
      FRepositorio.NombreCliente(FCliente), TFichaMedidas(TMenuItem(Sender).Tag));
end;

procedure TPanelMedidas.NuevaClick(Sender: TObject);
begin
  EditarSesion(False);
end;

procedure TPanelMedidas.CorregirClick(Sender: TObject);
begin
  if FSelector.ItemIndex >= 0 then
    EditarSesion(True);
end;

procedure TPanelMedidas.VincularClick(Sender: TObject);
begin
  if FSelector.ItemIndex >= 0 then
  begin
    if FElegir then
    begin
      TfrmModalMedidasCliente(FAnfitrion).FIdElegido := FSesiones[FSelector.ItemIndex].Id;
      FAnfitrion.ModalResult := mrOk;
    end
    else
    begin
      FRepositorio.Vincular(FOrden, FCliente,
        FSesiones[FSelector.ItemIndex].Id);
      SeleccionCambio(nil);
      ShowMessage_fza(SMedidasVinculadas);
    end;
  end;
end;

procedure TPanelMedidas.EditarSesion(ACorregir: Boolean);
var
  rSesion: TSesionMedidasCliente;
  i: Integer;
begin
  rSesion := Default(TSesionMedidasCliente);
  rSesion.Cliente := FCliente;
  rSesion.Fecha := Date;
  rSesion.Persona := FAnfitrion.IdentidadSesion.Usuario;
  if FElegir and not ACorregir and (FSelector.ItemIndex >= 0) then
  begin
    rSesion := FRepositorio.Leer(FCliente, FSesiones[FSelector.ItemIndex].Id);
    rSesion.Id := '';
    rSesion.Origen := '';
    rSesion.Motivo := '';
    rSesion.Fecha := Date;
    rSesion.Persona := FAnfitrion.IdentidadSesion.Usuario;
  end;
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
    for i := 0 to High(FSesiones) do
      if FSesiones[i].Id = rSesion.Id then
        FSelector.ItemIndex := i;
    ShowMessage_fza(SMedidasGuardadas);
  end;
end;

procedure TPanelMedidas.CamposSesion(
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

procedure TPanelMedidas.LeerCampos(
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

function TPanelMedidas.CapturarSesion(
  var ASesion: TSesionMedidasCliente): Boolean;
var
  aMagnitudes: TMagnitudesCliente;
  aRotulos, aValores: TArray<string>;
  rSesion: TSesionMedidasCliente;
begin
  aMagnitudes := FRepositorio.Magnitudes;
  CamposSesion(ASesion, aMagnitudes, aRotulos, aValores);
  rSesion := ASesion;
  Result := TfrmModalDatosOrden.Ejecutar(FAnfitrion,
    SMedidasTitulo + '. ' + SMedidasVacia, aRotulos, aValores, [],
    function(const AEntrada: TArray<string>; out AIndice: Integer): Boolean
    var
      i: Integer;
      rValor: Currency;
      sAviso: string;
    begin
      Result := True;
      AIndice := 0;
      for i := 4 to High(AEntrada) do
        if Result and (AEntrada[i] <> '') then
        begin
          Result := TryStrToCurr(AEntrada[i], rValor);
          if not Result then
          begin
            AIndice := i;
            ShowMessage_fza(SMedidasValorInvalido);
          end
          else if rValor < 0 then
          begin
            Result := False;
            AIndice := i;
            ShowMessage_fza(SMedidasValorNegativo);
          end;
        end;
      if Result then
      begin
        try
          LeerCampos(rSesion, aMagnitudes, AEntrada);
          sAviso := ValidarSesionMedidas(rSesion, aMagnitudes);
          if sAviso <> '' then
          begin
            AIndice := -1;
            for i := 0 to High(aMagnitudes) do
              if (AIndice < 0) and
                 rSesion.Valores[i].Conocida and
                 ((rSesion.Valores[i].Valor < aMagnitudes[i].Minimo) or
                  (rSesion.Valores[i].Valor > aMagnitudes[i].Maximo)) then
                AIndice := i + 4;
            Result := MessageDlg_fza(SMedidasFueraRango + sLineBreak +
              sAviso + sLineBreak + SMedidasConfirmarRango, mtWarning,
              [mbYes, mbNo], 0, mbNo) = mrYes;
            rSesion.AceptaFueraRango := Result;
          end;
        except
          on E: EArgumentException do
          begin
            Result := False;
            ShowMessage_fza(E.Message);
          end;
        end;
      end;
    end);
  if Result then
    ASesion := rSesion;
end;

end.
