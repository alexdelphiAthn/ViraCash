unit inMtoModalAjusteDepositos;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Uni, inMtoFrmBase,
  cxControls, cxContainer, cxEdit, cxCheckListBox, cxButtons, cxLabel,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookAndFeels,
  cxLookAndFeelPainters, cxGraphics, UniDataAjusteDepositos;

type
  TfrmModalAjusteDepositos = class(TfrmBase)
    lblDesde: TcxLabel;
    lblHasta: TcxLabel;
    lblOrigen: TcxLabel;
    lblTipo: TcxLabel;
    lblDestino: TcxLabel;
    lblResultado: TcxLabel;
    dteDesde: TcxDateEdit;
    dteHasta: TcxDateEdit;
    cboOrigen: TcxComboBox;
    cboTipo: TcxComboBox;
    cboDestino: TcxComboBox;
    chkDepositos: TcxCheckListBox;
    btnBuscar: TcxButton;
    btnMarcar: TcxButton;
    btnTrasladar: TcxButton;
    btnCerrar: TcxButton;
    procedure BuscarClick(Sender: TObject);
    procedure FiltroCambiado(Sender: TObject);
    procedure MarcarClick(Sender: TObject);
    procedure TrasladarClick(Sender: TObject);
  private
    FRepositorio: TRepositorioAjusteDepositos;
    FUsuario: string;
    FOrigenes: TArray<TAlmacenAjusteDepositos>;
    FDestinos: TArray<TAlmacenAjusteDepositos>;
    FDepositos: TArray<TDepositoAjustable>;
    FFiltro: TFiltroAjusteDepositos;
    procedure CargarAlmacenes;
  public
    class procedure Ejecutar(AOwner: TComponent; AConexion: TUniConnection;
      const AEmpresa, ATiendaRestringida, AUsuario: string);
  end;

implementation

uses
  System.SysUtils, System.UITypes, System.DateUtils, Vcl.Dialogs;

{$R *.dfm}

resourcestring
  SEntradaInicial = 'Entrada original';
  SEntradaPorAjuste = 'Entrada por cambio de almacén';
  SResultadoAbiertos = '%d depósitos abiertos. Marca los que deseas trasladar.';
  SSeleccionNecesaria = 'Marca al menos un depósito.';
  SDestinoNecesario = 'Selecciona un almacén de destino.';
  SDestinoIgualOrigen = 'El destino debe ser distinto del almacén de origen.';
  SConfirmarTraslado = '¿Trasladar %d depósitos de %s a %s?' + sLineBreak +
    'Se registrará una salida del origen y una entrada en el destino.';
  STrasladoCompletado = 'Traslado completado para %d depósitos.';

class procedure TfrmModalAjusteDepositos.Ejecutar(AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa, ATiendaRestringida, AUsuario: string);
var
  Formulario: TfrmModalAjusteDepositos;
begin
  Formulario := TfrmModalAjusteDepositos.Create(AOwner);
  try
    Formulario.FRepositorio := TRepositorioAjusteDepositos.Create(
      AConexion, AEmpresa, ATiendaRestringida);
    Formulario.FUsuario := AUsuario;
    Formulario.CargarAlmacenes;
    Formulario.dteDesde.Date := StartOfTheMonth(Date);
    Formulario.dteHasta.Date := Date;
    Formulario.cboTipo.ItemIndex := Ord(tmdTodos);
    Formulario.ShowModal;
  finally
    Formulario.FRepositorio.Free;
    Formulario.Free;
  end;
end;

procedure TfrmModalAjusteDepositos.CargarAlmacenes;
var
  Almacen: TAlmacenAjusteDepositos;
  Rotulo: string;
begin
  FOrigenes := FRepositorio.ListarAlmacenes;
  FDestinos := nil;
  for Almacen in FOrigenes do
  begin
    Rotulo := Almacen.Codigo + ' - ' + Almacen.Nombre;
    cboOrigen.Properties.Items.Add(Rotulo);
    if Almacen.Activo then
    begin
      cboDestino.Properties.Items.Add(Rotulo);
      FDestinos := FDestinos + [Almacen];
    end;
  end;
  cboOrigen.ItemIndex := -1;
  cboDestino.ItemIndex := -1;
end;

procedure TfrmModalAjusteDepositos.FiltroCambiado(Sender: TObject);
begin
  if Assigned(FRepositorio) then
  begin
    FDepositos := nil;
    chkDepositos.Items.Clear;
    lblResultado.Caption := '';
    btnTrasladar.Enabled := False;
    btnMarcar.Enabled := False;
    btnBuscar.Enabled := cboOrigen.ItemIndex >= 0;
  end;
end;

procedure TfrmModalAjusteDepositos.BuscarClick(Sender: TObject);
var
  Deposito: TDepositoAjustable;
  Item: TcxCheckListBoxItem;
  Tipo: string;
begin
  if cboOrigen.ItemIndex >= 0 then
  begin
    FiltroCambiado(Sender);
    FFiltro.Origen := FOrigenes[cboOrigen.ItemIndex].Codigo;
    FFiltro.Desde := dteDesde.Date;
    FFiltro.Hasta := dteHasta.Date;
    FFiltro.Tipo := TTipoMovimientoDeposito(cboTipo.ItemIndex);
    FDepositos := FRepositorio.ListarDepositos(FFiltro);
    chkDepositos.Items.BeginUpdate;
    try
      for Deposito in FDepositos do
      begin
        if Deposito.EsAjuste then
          Tipo := SEntradaPorAjuste
        else
          Tipo := SEntradaInicial;
        Item := chkDepositos.Items.Add;
        Item.Text := Format('%s    %s    %s    %s    %g    %s',
          [DateToStr(Deposito.Fecha), Deposito.Id, Deposito.Tienda,
           Deposito.Sku, Deposito.Cantidad, Tipo]);
      end;
    finally
      chkDepositos.Items.EndUpdate;
    end;
    lblResultado.Caption := Format(SResultadoAbiertos, [Length(FDepositos)]);
    btnTrasladar.Enabled := Length(FDepositos) > 0;
    btnMarcar.Enabled := btnTrasladar.Enabled;
  end;
end;

procedure TfrmModalAjusteDepositos.MarcarClick(Sender: TObject);
var
  I: Integer;
begin
  chkDepositos.Items.BeginUpdate;
  try
    for I := 0 to chkDepositos.Items.Count - 1 do
      chkDepositos.Items[I].State := cbsChecked;
  finally
    chkDepositos.Items.EndUpdate;
  end;
end;

procedure TfrmModalAjusteDepositos.TrasladarClick(Sender: TObject);
var
  Seleccion: TArray<TDepositoAjustable>;
  I, Total: Integer;
  Destino: string;
begin
  if cboDestino.ItemIndex < 0 then
    raise EArgumentException.Create(SDestinoNecesario);
  Destino := FDestinos[cboDestino.ItemIndex].Codigo;
  if SameText(FFiltro.Origen, Destino) then
    raise EArgumentException.Create(SDestinoIgualOrigen);
  SetLength(Seleccion, Length(FDepositos));
  Total := 0;
  for I := 0 to High(FDepositos) do
    if chkDepositos.Items[I].State = cbsChecked then
    begin
      Seleccion[Total] := FDepositos[I];
      Inc(Total);
    end;
  SetLength(Seleccion, Total);
  if Total = 0 then
    raise EArgumentException.Create(SSeleccionNecesaria);
  if MessageDlg(Format(SConfirmarTraslado, [Total, FFiltro.Origen, Destino]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FRepositorio.CambiarAlmacen(FFiltro, Destino, FUsuario, Seleccion);
    FiltroCambiado(Sender);
    lblResultado.Caption := Format(STrasladoCompletado, [Total]);
  end;
end;

end.
