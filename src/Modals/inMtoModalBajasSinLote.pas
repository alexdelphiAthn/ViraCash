unit inMtoModalBajasSinLote;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Uni, inMtoFrmBase,
  cxControls, cxContainer, cxEdit, cxButtons, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookAndFeels, cxLookAndFeelPainters,
  cxGraphics, cxClasses, cxListBox, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView,
  inLibRetiradaLotesIntf, UniDataRetiradaLotesRepositorio;

type
  TfrmModalBajasSinLote = class(TfrmBase)
    lblAlmacen: TcxLabel;
    lblSku: TcxLabel;
    lblCantidad: TcxLabel;
    lblMotivo: TcxLabel;
    lblEstado: TcxLabel;
    cboAlmacen: TcxComboBox;
    edtSku: TcxTextEdit;
    edtCantidad: TcxTextEdit;
    cboMotivo: TcxComboBox;
    btnStock: TcxButton;
    btnRegistrar: TcxButton;
    lblHistorial: TcxLabel;
    lblDesde: TcxLabel;
    lblHasta: TcxLabel;
    lblFiltroAlmacen: TcxLabel;
    lblFiltroMotivo: TcxLabel;
    dteDesde: TcxDateEdit;
    dteHasta: TcxDateEdit;
    cboFiltroAlmacen: TcxComboBox;
    cboFiltroMotivo: TcxComboBox;
    btnBuscar: TcxButton;
    gridBajas: TcxGrid;
    tvBajas: TcxGridTableView;
    nivelBajas: TcxGridLevel;
    colFecha: TcxGridColumn;
    colAlmacen: TcxGridColumn;
    colSku: TcxGridColumn;
    colMotivo: TcxGridColumn;
    colCantidad: TcxGridColumn;
    colUsuario: TcxGridColumn;
    colMovimiento: TcxGridColumn;
    lblTotales: TcxLabel;
    lstTotales: TcxListBox;
    btnCerrar: TcxButton;
    procedure StockClick(Sender: TObject);
    procedure RegistrarClick(Sender: TObject);
    procedure BuscarClick(Sender: TObject);
  private
    FRepositorio: TRepositorioRetiradaLotes;
    FAlmacenes: TArray<TAlmacenRetiradaLotes>;
    FEmpresa: string;
    FUsuario: string;
    procedure Inicializar(const AAlmacenActual: string);
    function AlmacenEntrada: string;
  protected
    procedure DoCreate; override;
  public
    class procedure Ejecutar(AOwner: TComponent; AConexion: TUniConnection;
      const AEmpresa, AAlmacenActual, AAlmacenRestringido, AUsuario: string);
  end;

implementation

uses
  System.SysUtils, System.UITypes, System.DateUtils,
  System.Generics.Collections, Data.DB, Vcl.Dialogs,
  inLibRetiradaLotes, inLibMsgRetiradaLotes;

{$R *.dfm}

resourcestring
  SFaltaAlmacen = 'Seleccione un almacén.';
  SFaltaSku = 'Introduzca el SKU del artículo.';
  SFechasInvalidas = 'Indique un intervalo de fechas válido.';
  SStockDisponible = 'Existencias sin lote en %s: %g';
  SConfirmarBaja = '¿Dar de baja %g de %s en %s por %s?';
  SBajaRegistrada = 'Baja registrada. Movimiento %s.';

procedure TfrmModalBajasSinLote.DoCreate;
begin
  inherited;
  Caption := STituloBajasSinLote;
end;

class procedure TfrmModalBajasSinLote.Ejecutar(AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa, AAlmacenActual, AAlmacenRestringido, AUsuario: string);
var
  Formulario: TfrmModalBajasSinLote;
begin
  Formulario := TfrmModalBajasSinLote.Create(AOwner);
  try
    Formulario.FRepositorio := TRepositorioRetiradaLotes.Create(
      AConexion, AEmpresa, AAlmacenRestringido);
    Formulario.FEmpresa := AEmpresa;
    Formulario.FUsuario := AUsuario;
    Formulario.Inicializar(AAlmacenActual);
    Formulario.ShowModal;
  finally
    Formulario.FRepositorio.Free;
    Formulario.Free;
  end;
end;

procedure TfrmModalBajasSinLote.Inicializar(const AAlmacenActual: string);
var
  I: Integer;
  Rotulo: string;
  Motivo: TMotivoRetiradaLote;
begin
  FAlmacenes := FRepositorio.AlmacenesBaja;
  for I := 0 to High(FAlmacenes) do
  begin
    Rotulo := FAlmacenes[I].Codigo + ' - ' + FAlmacenes[I].Nombre;
    cboAlmacen.Properties.Items.Add(Rotulo);
    cboFiltroAlmacen.Properties.Items.Add(Rotulo);
    if SameText(FAlmacenes[I].Codigo, AAlmacenActual) then
      cboAlmacen.ItemIndex := I;
  end;
  if (cboAlmacen.ItemIndex < 0) and (Length(FAlmacenes) = 1) then
    cboAlmacen.ItemIndex := 0;
  for Motivo in MOTIVOS_BAJA_SIN_LOTE do
  begin
    cboMotivo.Properties.Items.Add(TextoMotivoRetirada(Motivo));
    cboFiltroMotivo.Properties.Items.Add(TextoMotivoRetirada(Motivo));
  end;
  cboFiltroAlmacen.ItemIndex := 0;
  cboFiltroMotivo.ItemIndex := 0;
  dteDesde.Date := StartOfTheMonth(Date);
  dteHasta.Date := Date;
  BuscarClick(Self);
end;

function TfrmModalBajasSinLote.AlmacenEntrada: string;
begin
  if cboAlmacen.ItemIndex < 0 then
    raise EArgumentException.Create(SFaltaAlmacen);
  Result := FAlmacenes[cboAlmacen.ItemIndex].Codigo;
end;

procedure TfrmModalBajasSinLote.StockClick(Sender: TObject);
var
  Almacen, Sku: string;
begin
  Almacen := AlmacenEntrada;
  Sku := Trim(edtSku.Text);
  if Sku = '' then
    raise EArgumentException.Create(SFaltaSku);
  lblEstado.Caption := Format(SStockDisponible,
    [Almacen, FRepositorio.StockSinLote(Almacen, Sku)]);
end;

procedure TfrmModalBajasSinLote.RegistrarClick(Sender: TObject);
var
  Orden: TOrdenRetiradaLotes;
  Linea: TLineaRetiradaLote;
  Resultado: string;
begin
  Orden := Default(TOrdenRetiradaLotes);
  Linea := Default(TLineaRetiradaLote);
  Orden.Id := CrearIdRetirada;
  Orden.Empresa := FEmpresa;
  Orden.Usuario := FUsuario;
  Orden.Empleado := FUsuario;
  Orden.EsBajaSinLote := True;
  if cboMotivo.ItemIndex < 0 then
    raise EArgumentException.Create(SErrorBajaSinLoteMotivo);
  Orden.Motivo := MOTIVOS_BAJA_SIN_LOTE[cboMotivo.ItemIndex];
  Linea.CodigoAlmacen := AlmacenEntrada;
  Linea.CodigoSku := Trim(edtSku.Text);
  if not TryStrToFloat(Trim(edtCantidad.Text), Linea.Cantidad) then
    raise EArgumentException.Create(SErrorBajaSinLoteLinea);
  Orden.Lineas := [Linea];
  Resultado := ValidarOrdenRetirada(Orden);
  if Resultado <> '' then
    raise EArgumentException.Create(Resultado);

  if MessageDlg(Format(SConfirmarBaja, [Linea.Cantidad, Linea.CodigoSku,
      Linea.CodigoAlmacen, TextoMotivoRetirada(Orden.Motivo)]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Orden := FRepositorio.Guardar(Orden);
    edtCantidad.Text := '';
    lblEstado.Caption := Format(SBajaRegistrada,
      [Orden.Lineas[0].NumeroMovimiento]);
    if (dteDesde.Date > 0) and (dteHasta.Date >= dteDesde.Date) then
      BuscarClick(Self);
  end;
end;

procedure TfrmModalBajasSinLote.BuscarClick(Sender: TObject);
var
  Datos: TDataSet;
  Totales: TDictionary<string, Double>;
  Claves: TStringList;
  Almacen, Motivo, Unidad, Clave: string;
  Indice, FiltroMotivo: Integer;
  Cantidad, Suma: Double;
begin
  if (dteDesde.Date <= 0) or (dteHasta.Date < dteDesde.Date) then
    raise EArgumentException.Create(SFechasInvalidas);
  Almacen := '';
  if cboFiltroAlmacen.ItemIndex > 0 then
    Almacen := FAlmacenes[cboFiltroAlmacen.ItemIndex - 1].Codigo;
  FiltroMotivo := -1;
  if cboFiltroMotivo.ItemIndex > 0 then
    FiltroMotivo := Ord(MOTIVOS_BAJA_SIN_LOTE[cboFiltroMotivo.ItemIndex - 1]);

  Datos := FRepositorio.ConsultarBajas(Almacen, dteDesde.Date, dteHasta.Date,
    FiltroMotivo);
  Totales := TDictionary<string, Double>.Create;
  Claves := TStringList.Create;
  tvBajas.DataController.BeginUpdate;
  lstTotales.Items.BeginUpdate;
  try
    tvBajas.DataController.RecordCount := 0;
    lstTotales.Items.Clear;
    Claves.Sorted := True;
    Claves.Duplicates := dupIgnore;
    while not Datos.Eof do
    begin
      Motivo := TextoMotivoRetirada(TMotivoRetiradaLote(
        Datos.FieldByName('MOTIVO_LRET').AsInteger));
      Unidad := Datos.FieldByName('UNIDAD').AsString;
      Cantidad := Datos.FieldByName('CANTIDAD_LRET').AsFloat;
      Clave := Motivo + ' · ' + Unidad;
      if not Totales.TryGetValue(Clave, Suma) then
        Suma := 0;
      Totales.AddOrSetValue(Clave, Suma + Cantidad);
      Claves.Add(Clave);

      Indice := tvBajas.DataController.RecordCount;
      tvBajas.DataController.RecordCount := Indice + 1;
      tvBajas.DataController.Values[Indice, colFecha.Index] :=
        Datos.FieldByName('INSTANTE_LRET').AsDateTime;
      tvBajas.DataController.Values[Indice, colAlmacen.Index] :=
        Datos.FieldByName('CODIGO_ALM_LRET').AsString;
      tvBajas.DataController.Values[Indice, colSku.Index] :=
        Datos.FieldByName('CODIGO_UNIDAD_LRET').AsString;
      tvBajas.DataController.Values[Indice, colMotivo.Index] := Motivo;
      tvBajas.DataController.Values[Indice, colCantidad.Index] := Cantidad;
      tvBajas.DataController.Values[Indice, colUsuario.Index] :=
        Datos.FieldByName('USUARIO_ALTA').AsString;
      tvBajas.DataController.Values[Indice, colMovimiento.Index] :=
        Datos.FieldByName('NUMERO_MOV_LRET').AsString;
      Datos.Next;
    end;
    for Clave in Claves do
      lstTotales.Items.Add(Format('%s    %g', [Clave, Totales[Clave]]));
  finally
    lstTotales.Items.EndUpdate;
    tvBajas.DataController.EndUpdate;
    Claves.Free;
    Totales.Free;
    Datos.Free;
  end;
end;

end.
