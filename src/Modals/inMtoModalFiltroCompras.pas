{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFiltroCompras                                       }
{  Tipo:         Formulario modal                                              }
{  Versión:      1.0.0                                                         }
{  Fecha:        27/08/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:  Selección de series antes de cargar documentos de compra.     }
{    Construido con CreateNew; no abre consultas ni modifica documentos.       }
{******************************************************************************}
unit inMtoModalFiltroCompras;

interface

uses
  System.Classes,
  Vcl.Controls, Vcl.ExtCtrls,
  cxLabel, cxCheckBox, cxCheckListBox, cxDropDownEdit,
  inMtoFrmBase, inLibPrecargaComprasIntf, inLibDocumentoIntf;

type
  TfrmModalFiltroCompras = class(TfrmBase)
  private
    FCatalogo: TSeriesPrecargaCompra;
    FSeleccionAceptada: TArray<string>;
    FRepositorio: IRepositorioPrecargaCompras;
    FAnyos: TArray<Integer>;
    FSincronizandoSeleccion: Boolean;
    FEtiquetaCabecera: TcxLabel;
    FEtiquetaResultado: TcxLabel;
    FListaSeries: TcxCheckListBox;
    FCasillaTodas: TcxCheckBox;
    FSelectorAnyo: TcxComboBox;
    function Escalar(AValor: Integer): Integer;
    procedure ConstruirInterfaz;
    procedure CrearCabecera;
    procedure CrearSelectorAnyo(APanel: TPanel);
    procedure CrearLista;
    procedure CrearPie;
    procedure CrearBotones(APanel: TPanel);
    procedure AjustarAreaTrabajo;
    procedure CargarCatalogo(const ASeleccion: TArray<string>);
    procedure CargarAnyos;
    procedure MarcarAnyo;
    procedure MarcarSeriesDelAnyo(AAnyo: Integer);
    procedure IndicarSeleccionManual;
    function TextoSerie(const ASerie: TSeriePrecargaCompra): string;
    function SeriesMarcadas: TArray<string>;
    function LeerSeleccion: TArray<string>;
    function SeleccionValida(const ASeries: TArray<string>): Boolean;
    function ContarSeleccion(const ASeries: TArray<string>): Integer;
    procedure MostrarCantidad(ACantidad: Integer);
    procedure ActualizarResultado;
    procedure ConfirmarSeleccion;
    procedure DesmarcarSeries;
    procedure TodasClick(Sender: TObject);
    procedure AnyoCambiado(Sender: TObject);
    procedure SeleccionCambiada(Sender: TObject);
    procedure NingunaClick(Sender: TObject);
    procedure CalcularClick(Sender: TObject);
    procedure CargarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    class function Ejecutar(AOwner: TComponent;
      const ANombreDocumento: string;
      const ACatalogo: TSeriesPrecargaCompra;
      const ASeleccion: TArray<string>;
      const ARepositorio: IRepositorioPrecargaCompras;
      out ANuevaSeleccion: TArray<string>): Boolean;
  end;

function NombreDocumentoPrecargaCompras(
  const AConfiguracion: TConfiguracionDocumento): string;
function TituloSelectorSeriesCompras(const ANombreDocumento: string): string;

implementation

uses
  inLibMensajesVcl,
  Winapi.Windows,
  System.SysUtils, System.Math, System.UITypes, System.Types,
  System.Generics.Collections,
  Vcl.Forms, Vcl.Graphics, Vcl.Dialogs,
  cxButtons, cxLookAndFeelPainters,
  inLibLogIntf, inLibMsgCompras, inLibPrecargaMantenimientos,
  inLibMsgArticulos;

function NombreDocumentoPrecargaCompras(
  const AConfiguracion: TConfiguracionDocumento): string;
begin
  Result := AConfiguracion.NombreSingular;
  if AConfiguracion.Sentido = sdCompra then
    case AConfiguracion.TipoDocumento of
      tdPedido: Result := SNombreCorreoPedidoCompra;
      tdAlbaran: Result := SNombreCorreoAlbaranCompra;
      tdFactura: Result := SNombreCorreoFacturaCompra;
      tdDevolucion: Result := SNombreCorreoDevolucionCompra;
    end;
end;

function TituloSelectorSeriesCompras(const ANombreDocumento: string): string;
var
  Nombre: string;
begin
  Nombre := ANombreDocumento;
  if Nombre <> '' then
    Nombre := UpperCase(Copy(Nombre, 1, 1)) + Copy(Nombre, 2, MaxInt);
  Result := Format(STituloPrecargaCompras, [Nombre]);
end;

constructor TfrmModalFiltroCompras.Create(AOwner: TComponent);
var
  ProveedorRegistro: IProveedorRegistroLog;
begin
  inherited CreateNew(AOwner);
  // CreateNew no ejecuta el constructor de servicios de TfrmBase.
  AsignarRegistroLog(nil);
  if Supports(AOwner, IProveedorRegistroLog, ProveedorRegistro) then
    AsignarRegistroLog(ProveedorRegistro.RegistroLog);
  Name := 'frmModalFiltroCompras';
  Font.Assign(Screen.MessageFont);
  if Font.Size < 10 then
    Font.Size := 10;
  Position := poOwnerFormCenter;
  if AOwner is TCustomForm then
  begin
    PopupMode := pmExplicit;
    PopupParent := TCustomForm(AOwner);
  end;
  ConstruirInterfaz;
end;

function TfrmModalFiltroCompras.Escalar(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

procedure TfrmModalFiltroCompras.ConstruirInterfaz;
begin
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  // El desplazamiento pertenece a la lista, no al formulario completo.
  AutoScroll := False;
  ClientWidth := Escalar(700);
  ClientHeight := Escalar(480);
  Padding.SetBounds(Escalar(16), Escalar(16), Escalar(16), Escalar(16));
  CrearCabecera;
  CrearPie;
  CrearLista;
  AjustarAreaTrabajo;
  // No hay DFM ni dimensiones de lectura pendientes al cambiar de DPI.
  ScalingFlags := [];
end;

procedure TfrmModalFiltroCompras.CrearCabecera;
var
  PanelCabecera: TPanel;
  EtiquetaOrden: TcxLabel;
begin
  PanelCabecera := TPanel.Create(Self);
  PanelCabecera.Parent := Self;
  PanelCabecera.Align := alTop;
  PanelCabecera.Height := Escalar(168);
  PanelCabecera.BevelOuter := bvNone;
  FEtiquetaCabecera := TcxLabel.Create(Self);
  FEtiquetaCabecera.Parent := PanelCabecera;
  FEtiquetaCabecera.Name := 'lblCabecera';
  FEtiquetaCabecera.Transparent := True;
  FEtiquetaCabecera.AutoSize := False;
  FEtiquetaCabecera.Properties.WordWrap := True;
  FEtiquetaCabecera.SetBounds(0, 0, PanelCabecera.Width, Escalar(60));
  FEtiquetaCabecera.Anchors := [akLeft, akTop, akRight];
  EtiquetaOrden := TcxLabel.Create(Self);
  EtiquetaOrden.Parent := PanelCabecera;
  EtiquetaOrden.Transparent := True;
  EtiquetaOrden.Caption := SOrdenSeriesCompras;
  EtiquetaOrden.Style.Font.Style := [fsBold];
  EtiquetaOrden.SetBounds(0, Escalar(64), PanelCabecera.Width,
    Escalar(26));
  CrearSelectorAnyo(PanelCabecera);
  FCasillaTodas := TcxCheckBox.Create(Self);
  FCasillaTodas.Parent := PanelCabecera;
  FCasillaTodas.Name := 'chkTodas';
  FCasillaTodas.Caption := STodasSeriesCompras;
  FCasillaTodas.SetBounds(0, Escalar(130), PanelCabecera.Width,
    Escalar(30));
  FCasillaTodas.Anchors := [akLeft, akTop, akRight];
  FCasillaTodas.Properties.OnEditValueChanged := TodasClick;
end;

procedure TfrmModalFiltroCompras.CrearSelectorAnyo(APanel: TPanel);
var
  EtiquetaAnyo: TcxLabel;
begin
  EtiquetaAnyo := TcxLabel.Create(Self);
  EtiquetaAnyo.Parent := APanel;
  EtiquetaAnyo.Name := 'lblAnyo';
  EtiquetaAnyo.Transparent := True;
  EtiquetaAnyo.Caption := SMarcarAnyoCompras;
  EtiquetaAnyo.SetBounds(0, Escalar(98), Escalar(190), Escalar(26));
  FSelectorAnyo := TcxComboBox.Create(Self);
  FSelectorAnyo.Parent := APanel;
  FSelectorAnyo.Name := 'cbbAnyo';
  FSelectorAnyo.SetBounds(Escalar(200), Escalar(94), Escalar(260),
    Escalar(30));
  FSelectorAnyo.Properties.DropDownListStyle := lsFixedList;
  FSelectorAnyo.Properties.OnEditValueChanged := AnyoCambiado;
  EtiquetaAnyo.FocusControl := FSelectorAnyo;
end;

procedure TfrmModalFiltroCompras.CrearLista;
begin
  FListaSeries := TcxCheckListBox.Create(Self);
  FListaSeries.Parent := Self;
  FListaSeries.Name := 'clbSeries';
  FListaSeries.Align := alClient;
  // cvfInteger limita la selección a 64 series; leemos estados por índice.
  FListaSeries.EditValueFormat := cvfIndices;
  FListaSeries.IntegralHeight := False;
  FListaSeries.AllowGrayed := False;
  FListaSeries.OnEditValueChanged := SeleccionCambiada;
  FListaSeries.TabOrder := 1;
end;

procedure TfrmModalFiltroCompras.CrearPie;
var
  PanelPie: TPanel;
begin
  PanelPie := TPanel.Create(Self);
  PanelPie.Parent := Self;
  PanelPie.Align := alBottom;
  PanelPie.Height := Escalar(100);
  PanelPie.BevelOuter := bvNone;
  FEtiquetaResultado := TcxLabel.Create(Self);
  FEtiquetaResultado.Parent := PanelPie;
  FEtiquetaResultado.Name := 'lblResultado';
  FEtiquetaResultado.Transparent := True;
  FEtiquetaResultado.AutoSize := False;
  FEtiquetaResultado.Properties.WordWrap := True;
  FEtiquetaResultado.Caption := SResultadoPendienteCompras;
  FEtiquetaResultado.SetBounds(0, Escalar(10), PanelPie.Width,
    Escalar(38));
  FEtiquetaResultado.Anchors := [akLeft, akTop, akRight];
  CrearBotones(PanelPie);
end;

procedure TfrmModalFiltroCompras.CrearBotones(APanel: TPanel);
var
  BotonCalcular: TcxButton;
  BotonNinguna: TcxButton;
  BotonCargar: TcxButton;
  BotonCancelar: TcxButton;
begin
  BotonCalcular := TcxButton.Create(Self);
  BotonCalcular.Parent := APanel;
  BotonCalcular.Name := 'btnCalcular';
  BotonCalcular.Caption := SBotonCalcularCompras;
  BotonCalcular.SetBounds(0, Escalar(58), Escalar(110), Escalar(34));
  BotonCalcular.OnClick := CalcularClick;
  BotonNinguna := TcxButton.Create(Self);
  BotonNinguna.Parent := APanel;
  BotonNinguna.Name := 'btnNinguna';
  BotonNinguna.Caption := SBotonNingunaCompras;
  BotonNinguna.SetBounds(Escalar(120), Escalar(58), Escalar(110),
    Escalar(34));
  BotonNinguna.OnClick := NingunaClick;
  BotonCargar := TcxButton.Create(Self);
  BotonCargar.Parent := APanel;
  BotonCargar.Name := 'btnCargar';
  BotonCargar.Caption := SBotonCargarCompras;
  BotonCargar.Default := True;
  BotonCargar.SetBounds(APanel.Width - Escalar(230), Escalar(58),
    Escalar(110), Escalar(34));
  BotonCargar.Anchors := [akTop, akRight];
  BotonCargar.OnClick := CargarClick;
  BotonCancelar := TcxButton.Create(Self);
  BotonCancelar.Parent := APanel;
  BotonCancelar.Name := 'btnCancelar';
  BotonCancelar.Caption := SBotonCancelarCompras;
  BotonCancelar.Cancel := True;
  BotonCancelar.ModalResult := mrCancel;
  BotonCancelar.SetBounds(APanel.Width - Escalar(110), Escalar(58),
    Escalar(110), Escalar(34));
  BotonCancelar.Anchors := [akTop, akRight];
end;

procedure TfrmModalFiltroCompras.AjustarAreaTrabajo;
var
  AreaTrabajo: TRect;
begin
  AreaTrabajo := Monitor.WorkareaRect;
  Constraints.MinWidth := Min(Escalar(620) + Width - ClientWidth,
    AreaTrabajo.Width);
  Constraints.MinHeight := Min(Escalar(420) + Height - ClientHeight,
    AreaTrabajo.Height);
  Width := Min(Width, AreaTrabajo.Width);
  Height := Min(Height, AreaTrabajo.Height);
end;

function TfrmModalFiltroCompras.TextoSerie(
  const ASerie: TSeriePrecargaCompra): string;
var
  Codigo: string;
  Fecha: string;
begin
  Codigo := ASerie.Codigo;
  if Codigo = '' then
    Codigo := SSerieSinCodigoCompras;
  Fecha := SFechaNoDisponibleCompras;
  if ASerie.UltimoDocumento > 0 then
    Fecha := FormatDateTime('dd/mm/yyyy hh:nn', ASerie.UltimoDocumento);
  Result := Format(SSerieConFechaCompras, [Codigo, Fecha]);
end;

procedure TfrmModalFiltroCompras.CargarCatalogo(
  const ASeleccion: TArray<string>);
var
  Seleccion: TStringList;
  Elemento: TcxCheckListBoxItem;
  Codigo: string;
  Indice: Integer;
  Ancho: Integer;
begin
  Seleccion := TStringList.Create;
  try
    Seleccion.CaseSensitive := True;
    for Codigo in ASeleccion do
      Seleccion.Add(Codigo);
    Canvas.Font.Assign(Font);
    Ancho := 0;
    FListaSeries.Items.BeginUpdate;
    try
      for Indice := 0 to High(FCatalogo) do
      begin
        Elemento := FListaSeries.Items.Add;
        Elemento.Text := TextoSerie(FCatalogo[Indice]);
        if Seleccion.IndexOf(FCatalogo[Indice].Codigo) >= 0 then
          Elemento.State := cbsChecked;
        Ancho := Max(Ancho, Canvas.TextWidth(Elemento.Text));
      end;
    finally
      FListaSeries.Items.EndUpdate;
    end;
    FListaSeries.ScrollWidth := Ancho + Escalar(48);
  finally
    FreeAndNil(Seleccion);
  end;
  CargarAnyos;
  FCasillaTodas.Checked := Length(ASeleccion) = 0;
  TodasClick(FCasillaTodas);
  if FListaSeries.Enabled then
    ActiveControl := FListaSeries
  else
    ActiveControl := FCasillaTodas;
end;

procedure TfrmModalFiltroCompras.CargarAnyos;
var
  Anyos: TList<Integer>;
  Serie: TSeriePrecargaCompra;
  Anyo: Integer;
  Indice: Integer;
  Posicion: Integer;
  HaySinAnyo: Boolean;
begin
  Anyos := TList<Integer>.Create;
  try
    HaySinAnyo := False;
    for Serie in FCatalogo do
    begin
      Anyo := AnyoEnSerie(Serie.Codigo);
      HaySinAnyo := HaySinAnyo or (Anyo = 0);
      if (Anyo > 0) and (Anyos.IndexOf(Anyo) < 0) then
        Anyos.Add(Anyo);
    end;
    Anyos.Sort;
    SetLength(FAnyos, 1 + Anyos.Count + Ord(HaySinAnyo));
    FAnyos[0] := -1;
    FSelectorAnyo.Properties.Items.Add(SSeleccionManualCompras);
    Posicion := 1;
    for Indice := Anyos.Count - 1 downto 0 do
    begin
      FAnyos[Posicion] := Anyos[Indice];
      FSelectorAnyo.Properties.Items.Add(IntToStr(Anyos[Indice]));
      Inc(Posicion);
    end;
    if HaySinAnyo then
    begin
      FAnyos[Posicion] := 0;
      FSelectorAnyo.Properties.Items.Add(SSeriesSinAnyoCompras);
    end;
  finally
    FreeAndNil(Anyos);
  end;
  FSelectorAnyo.ItemIndex := 0;
end;

procedure TfrmModalFiltroCompras.MarcarSeriesDelAnyo(AAnyo: Integer);
var
  Indice: Integer;
begin
  FListaSeries.Items.BeginUpdate;
  try
    for Indice := 0 to High(FCatalogo) do
      if AnyoEnSerie(FCatalogo[Indice].Codigo) = AAnyo then
        FListaSeries.Items[Indice].State := cbsChecked
      else
        FListaSeries.Items[Indice].State := cbsUnchecked;
  finally
    FListaSeries.Items.EndUpdate;
  end;
end;

procedure TfrmModalFiltroCompras.MarcarAnyo;
begin
  if (FSelectorAnyo.ItemIndex > 0) and
     (FSelectorAnyo.ItemIndex < Length(FAnyos)) then
  begin
    FSincronizandoSeleccion := True;
    try
      FCasillaTodas.Checked := False;
      FListaSeries.Enabled := True;
      MarcarSeriesDelAnyo(FAnyos[FSelectorAnyo.ItemIndex]);
    finally
      FSincronizandoSeleccion := False;
    end;
    FEtiquetaResultado.Caption := SResultadoPendienteCompras;
  end;
end;

procedure TfrmModalFiltroCompras.IndicarSeleccionManual;
begin
  if not FSincronizandoSeleccion and
     (FSelectorAnyo.Properties.Items.Count > 0) then
  begin
    FSincronizandoSeleccion := True;
    try
      FSelectorAnyo.ItemIndex := 0;
    finally
      FSincronizandoSeleccion := False;
    end;
  end;
end;

function TfrmModalFiltroCompras.SeriesMarcadas: TArray<string>;
var
  Indice: Integer;
  Cantidad: Integer;
begin
  SetLength(Result, Length(FCatalogo));
  Cantidad := 0;
  for Indice := 0 to High(FCatalogo) do
    if FListaSeries.Items[Indice].State = cbsChecked then
    begin
      Result[Cantidad] := FCatalogo[Indice].Codigo;
      Inc(Cantidad);
    end;
  SetLength(Result, Cantidad);
end;

function TfrmModalFiltroCompras.LeerSeleccion: TArray<string>;
begin
  if FCasillaTodas.Checked then
    Result := nil
  else
    Result := SeriesMarcadas;
end;

function TfrmModalFiltroCompras.SeleccionValida(
  const ASeries: TArray<string>): Boolean;
begin
  Result := FCasillaTodas.Checked or (Length(ASeries) > 0);
  if not Result then
  begin
    MessageDlg_fza(SSeleccionVaciaCompras, mtWarning, [mbOK], 0);
    ActiveControl := FListaSeries;
  end;
end;

function TfrmModalFiltroCompras.ContarSeleccion(
  const ASeries: TArray<string>): Integer;
var
  CursorAnterior: TCursor;
begin
  CursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    Result := FRepositorio.ContarHastaUmbral(ASeries);
  finally
    Screen.Cursor := CursorAnterior;
  end;
end;

procedure TfrmModalFiltroCompras.MostrarCantidad(ACantidad: Integer);
begin
  if ACantidad > UMBRAL_PRECARGA_COMPRAS then
    FEtiquetaResultado.Caption := Format(SCantidadExcesivaCompras,
      [FormatFloat('#,##0', UMBRAL_PRECARGA_COMPRAS)])
  else
    FEtiquetaResultado.Caption := Format(SCantidadDocumentosCompras,
      [FormatFloat('#,##0', ACantidad)]);
end;

procedure TfrmModalFiltroCompras.ActualizarResultado;
var
  Series: TArray<string>;
begin
  Series := LeerSeleccion;
  if SeleccionValida(Series) then
    MostrarCantidad(ContarSeleccion(Series));
end;

procedure TfrmModalFiltroCompras.ConfirmarSeleccion;
var
  Series: TArray<string>;
  Cantidad: Integer;
  Confirmada: Boolean;
begin
  Series := LeerSeleccion;
  Confirmada := SeleccionValida(Series);
  if Confirmada then
  begin
    Cantidad := ContarSeleccion(Series);
    MostrarCantidad(Cantidad);
    if Cantidad > UMBRAL_PRECARGA_COMPRAS then
      Confirmada := MessageDlg_fza(Format(SPreguntaCargaExcesivaCompras,
        [FormatFloat('#,##0', UMBRAL_PRECARGA_COMPRAS)]),
        mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
  end;
  if Confirmada then
  begin
    FSeleccionAceptada := Series;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalFiltroCompras.DesmarcarSeries;
var
  Indice: Integer;
begin
  FCasillaTodas.Checked := False;
  FListaSeries.Items.BeginUpdate;
  try
    for Indice := 0 to FListaSeries.Items.Count - 1 do
      FListaSeries.Items[Indice].State := cbsUnchecked;
  finally
    FListaSeries.Items.EndUpdate;
  end;
  TodasClick(FCasillaTodas);
end;

procedure TfrmModalFiltroCompras.TodasClick(Sender: TObject);
begin
  FListaSeries.Enabled := not FCasillaTodas.Checked;
  SeleccionCambiada(Sender);
end;

procedure TfrmModalFiltroCompras.AnyoCambiado(Sender: TObject);
begin
  if not FSincronizandoSeleccion then
    MarcarAnyo;
end;

procedure TfrmModalFiltroCompras.SeleccionCambiada(Sender: TObject);
begin
  IndicarSeleccionManual;
  FEtiquetaResultado.Caption := SResultadoPendienteCompras;
end;

procedure TfrmModalFiltroCompras.NingunaClick(Sender: TObject);
begin
  DesmarcarSeries;
end;

procedure TfrmModalFiltroCompras.CalcularClick(Sender: TObject);
begin
  ActualizarResultado;
end;

procedure TfrmModalFiltroCompras.CargarClick(Sender: TObject);
begin
  ConfirmarSeleccion;
end;

class function TfrmModalFiltroCompras.Ejecutar(AOwner: TComponent;
  const ANombreDocumento: string;
  const ACatalogo: TSeriesPrecargaCompra;
  const ASeleccion: TArray<string>;
  const ARepositorio: IRepositorioPrecargaCompras;
  out ANuevaSeleccion: TArray<string>): Boolean;
var
  Formulario: TfrmModalFiltroCompras;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create(SRepositorioComprasObligatorio);
  ANuevaSeleccion := Copy(ASeleccion);
  Formulario := TfrmModalFiltroCompras.Create(AOwner);
  try
    Formulario.FRepositorio := ARepositorio;
    Formulario.FCatalogo := Copy(ACatalogo);
    Formulario.Caption := TituloSelectorSeriesCompras(ANombreDocumento);
    Formulario.FEtiquetaCabecera.Caption :=
      Format(SExplicacionPrecargaCompras, [ANombreDocumento]);
    Formulario.CargarCatalogo(ASeleccion);
    Result := Formulario.ShowModal = mrOk;
    if Result then
      ANuevaSeleccion := Copy(Formulario.FSeleccionAceptada);
  finally
    FreeAndNil(Formulario);
  end;
end;

end.
