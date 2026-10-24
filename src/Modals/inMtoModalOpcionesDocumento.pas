{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalOpcionesDocumento                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Diálogo común antes de crear un documento: empresa, almacén, tipo,        }
{    serie, número (automático o manual), fecha, forma de pago y, en           }
{    facturas, si genera movimientos de stock. Al cambiar empresa, tipo o      }
{    almacén se recargan las series y se propone la del almacén. El            }
{    llamador decide qué campos se ven y cuáles quedan fijos.                  }
{******************************************************************************}
unit inMtoModalOpcionesDocumento;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCalendar, cxLabel, cxCheckBox, cxButtons, dxCore, cxDateUtils,
  cxSpinEdit, cxTimeEdit,
  inMtoFrmBase, inLibOpcionesDocumentoIntf,
  inLibCamposAdicionalesDocumentoVcl;

type
  TfrmModalOpcionesDocumento = class(TfrmBase)
    lblEmpresa: TcxLabel;
    cbbEmpresa: TcxComboBox;
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxComboBox;
    lblTipoDocumento: TcxLabel;
    cbbTipoDocumento: TcxComboBox;
    lblSerie: TcxLabel;
    cbbSerie: TcxComboBox;
    lblNumero: TcxLabel;
    chkNumeroAutomatico: TcxCheckBox;
    txtNumero: TcxTextEdit;
    lblFecha: TcxLabel;
    dteFecha: TcxDateEdit;
    lblHora: TcxLabel;
    tmeHora: TcxTimeEdit;
    lblFormaPago: TcxLabel;
    cbbFormaPago: TcxComboBox;
    chkMueveStock: TcxCheckBox;
    btnCancelar: TcxButton;
    btnAceptar: TcxButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cbbEmpresaPropertiesEditValueChanged(Sender: TObject);
    procedure cbbAlmacenPropertiesEditValueChanged(Sender: TObject);
    procedure cbbTipoDocumentoPropertiesEditValueChanged(Sender: TObject);
    procedure chkNumeroAutomaticoPropertiesEditValueChanged(
      Sender: TObject);
  private
    FAceptado: Boolean;
    FCargando: Boolean;
    FLector: ILectorOpcionesDocumento;
    FConfiguracion: TConfiguracionOpcionesDocumento;
    // Códigos de cada elemento de los combos, por índice.
    FEmpresas: TArray<string>;
    FAlmacenes: TArray<string>;
    FFormasPago: TArray<string>;
    FAdicionales: TCamposAdicionalesDocumentoVcl;
    FAviso: TcxLabel;
    FConsolidar: TcxCheckBox;
    procedure Preparar(const ALector: ILectorOpcionesDocumento;
      const AConfiguracion: TConfiguracionOpcionesDocumento);
    procedure TraducirTextos;
    procedure CrearCamposPropios;
    procedure CamposPropiosCambiados(Sender: TObject);
    procedure ColocarAviso(var ATop: Integer);
    procedure CargarEmpresas;
    procedure CargarAlmacenes;
    procedure CargarTipos;
    procedure CargarFormasPago;
    procedure CargarSeries;
    procedure ProponerSerie;
    procedure AplicarVisibles;
    procedure ColocarFila(AEtiqueta: TcxLabel;
      const AEditores: array of TControl; var ATop: Integer);
    procedure ActualizarHabilitados;
    function TipoElegido(out ATipo: TTipoOpcionesDocumento): Boolean;
    function OpcionesElegidas: TOpcionesDocumento;
    function ControlDeCampo(ACampo: TCampoOpcionesDocumento): TWinControl;
    function Validar: Boolean;
    procedure EnfocarControl(AControl: TWinControl);
  protected
    // Ctrl+Enter sobre un campo con búsqueda la abre.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    destructor Destroy; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    class function Solicitar(AOwner: TComponent;
      const ALector: ILectorOpcionesDocumento;
      const AConfiguracion: TConfiguracionOpcionesDocumento;
      out AOpciones: TOpcionesDocumento): Boolean; static;
  end;

implementation

uses
  inLibMensajesVcl, inLibOpcionesDocumento, inLibMsgOpcionesDocumento;

{$R *.dfm}

const
  ALTO_FILA = 40;

function CodigoElegido(const ACodigos: TArray<string>;
  ACombo: TcxComboBox): string;
begin
  Result := '';
  if (ACombo.ItemIndex >= 0) and (ACombo.ItemIndex < Length(ACodigos)) then
    Result := ACodigos[ACombo.ItemIndex];
end;

procedure ElegirCodigo(const ACodigos: TArray<string>;
  ACombo: TcxComboBox; const ACodigo: string);
var
  iIndice: Integer;
begin
  ACombo.ItemIndex := -1;
  for iIndice := 0 to High(ACodigos) do
  begin
    if SameText(ACodigos[iIndice], ACodigo) then
      ACombo.ItemIndex := iIndice;
  end;
end;

// Rellena el combo con «código - nombre» y devuelve los códigos por
// índice. Con AConVacio el primer elemento es «sin valor».
function LlenarCombo(ACombo: TcxComboBox;
  const AElementos: TElementosOpcionesDocumento;
  AConVacio: Boolean): TArray<string>;
var
  oElemento: TElementoOpcionesDocumento;
begin
  Result := nil;
  ACombo.Properties.Items.BeginUpdate;
  try
    ACombo.Properties.Items.Clear;
    if AConVacio then
    begin
      Result := Result + [''];
      ACombo.Properties.Items.Add('');
    end;
    for oElemento in AElementos do
    begin
      Result := Result + [oElemento.Codigo];
      if Trim(oElemento.Nombre) = '' then
        ACombo.Properties.Items.Add(oElemento.Codigo)
      else
        ACombo.Properties.Items.Add(
          oElemento.Codigo + ' - ' + oElemento.Nombre);
    end;
  finally
    ACombo.Properties.Items.EndUpdate;
  end;
end;

class function TfrmModalOpcionesDocumento.Solicitar(AOwner: TComponent;
  const ALector: ILectorOpcionesDocumento;
  const AConfiguracion: TConfiguracionOpcionesDocumento;
  out AOpciones: TOpcionesDocumento): Boolean;
var
  frm: TfrmModalOpcionesDocumento;
begin
  AOpciones := AConfiguracion.Propuesta;
  frm := TfrmModalOpcionesDocumento.Create(AOwner);
  try
    frm.Preparar(ALector, AConfiguracion);
    frm.ShowModal;
    Result := frm.FAceptado;
    if Result then
      AOpciones := frm.OpcionesElegidas;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalOpcionesDocumento.Preparar(
  const ALector: ILectorOpcionesDocumento;
  const AConfiguracion: TConfiguracionOpcionesDocumento);
begin
  FLector := ALector;
  FConfiguracion := AConfiguracion;
  FAceptado := False;
  FCargando := True;
  try
    // Los textos se ponen aqui, despues de la traduccion de la ventana,
    // que pisaria los asignados en el constructor.
    TraducirTextos;
    CrearCamposPropios;
    FConsolidar := TcxCheckBox.Create(Self);
    FConsolidar.Parent := Self;
    FConsolidar.Name := 'chkConsolidarAlCrear';
    // Como las casillas del DFM: sin fondo propio, que en los temas
    // oscuros quedaba blanco y tapaba el texto.
    FConsolidar.Transparent := True;
    FConsolidar.Left := lblEmpresa.Left;
    FConsolidar.Width := cbbEmpresa.Left + cbbEmpresa.Width -
      lblEmpresa.Left;
    FConsolidar.Caption := FConfiguracion.TextoConsolidar;
    FConsolidar.Checked := False;
    CargarEmpresas;
    CargarTipos;
    CargarAlmacenes;
    CargarFormasPago;
    chkNumeroAutomatico.Checked := AConfiguracion.Propuesta.NumeroAutomatico
      or (not AConfiguracion.PermiteNumeroManual);
    txtNumero.Text := AConfiguracion.Propuesta.Numero;
    dteFecha.Date := AConfiguracion.Propuesta.Fecha;
    if dteFecha.Date <= 0 then
      dteFecha.Date := Date;
    tmeHora.Time := Frac(AConfiguracion.Propuesta.Hora);
    chkMueveStock.Checked := AConfiguracion.Propuesta.MueveStock;
    CargarSeries;
    if (AConfiguracion.Propuesta.Serie <> '') or
       AConfiguracion.SerieOpcional then
      cbbSerie.Text := AConfiguracion.Propuesta.Serie
    else
      ProponerSerie;
  finally
    FCargando := False;
  end;
  AplicarVisibles;
  ActualizarHabilitados;
end;

procedure TfrmModalOpcionesDocumento.TraducirTextos;
begin
  Caption := FConfiguracion.Titulo;
  if Caption = '' then
    Caption := SCaptionOpcionesDocumento;
  lblEmpresa.Caption := SCaptionEmpresaOpcionesDocumento;
  lblAlmacen.Caption := SCaptionAlmacenOpcionesDocumento;
  lblTipoDocumento.Caption := SCaptionTipoOpcionesDocumento;
  lblSerie.Caption := SCaptionSerieOpcionesDocumento;
  lblNumero.Caption := SCaptionNumeroOpcionesDocumento;
  chkNumeroAutomatico.Caption := SCaptionNumeroAutomaticoOpcionesDocumento;
  lblFecha.Caption := SCaptionFechaOpcionesDocumento;
  lblHora.Caption := SCaptionHoraOpcionesDocumento;
  lblFormaPago.Caption := SCaptionFormaPagoOpcionesDocumento;
  chkMueveStock.Caption := SCaptionMueveStockOpcionesDocumento;
  btnAceptar.Caption := SCaptionAceptarOpcionesDocumento;
  btnCancelar.Caption := SCaptionCancelarOpcionesDocumento;
end;

destructor TfrmModalOpcionesDocumento.Destroy;
begin
  FreeAndNil(FAdicionales);
  inherited;
end;

// Los campos propios del llamador se crean con la geometría del DFM ya
// escalada; los de búsqueda comparten fila con el nombre del elegido.
procedure TfrmModalOpcionesDocumento.CrearCamposPropios;
var
  oGeometria: TGeometriaCamposAdicionales;
begin
  oGeometria.IzquierdaEtiqueta := lblEmpresa.Left;
  oGeometria.IzquierdaEditor := cbbEmpresa.Left;
  oGeometria.AnchoEditor := cbbEmpresa.Width;
  oGeometria.AnchoCodigo := cbbSerie.Width;
  oGeometria.AltoFila := ScaleValue(ALTO_FILA);
  oGeometria.DesfaseEtiqueta := ScaleValue(3);
  FAdicionales := TCamposAdicionalesDocumentoVcl.Create(Self, Self,
    FConfiguracion.Propuesta.Adicionales, oGeometria,
    CamposPropiosCambiados);
  if FConfiguracion.Aviso <> '' then
  begin
    FAviso := TcxLabel.Create(Self);
    FAviso.Parent := Self;
    FAviso.Transparent := True;
    FAviso.Properties.WordWrap := True;
    FAviso.AutoSize := True;
    FAviso.Left := lblEmpresa.Left;
    FAviso.Width := cbbEmpresa.Left + cbbEmpresa.Width - lblEmpresa.Left;
    FAviso.Caption := FConfiguracion.Aviso;
  end;
end;

procedure TfrmModalOpcionesDocumento.CamposPropiosCambiados(
  Sender: TObject);
var
  sFormaPago: string;
begin
  if not FCargando then
  begin
    if Assigned(FConfiguracion.FormaPagoAlCambiarAdicional) and
       FConfiguracion.FormaPagoAlCambiarAdicional(
         OpcionesElegidas, sFormaPago) then
      ElegirCodigo(FFormasPago, cbbFormaPago, sFormaPago);
    ActualizarHabilitados;
  end;
end;

procedure TfrmModalOpcionesDocumento.ColocarAviso(var ATop: Integer);
begin
  if Assigned(FAviso) then
  begin
    FAviso.Top := ATop;
    Inc(ATop, FAviso.Height + ScaleValue(12));
  end;
end;

procedure TfrmModalOpcionesDocumento.CargarEmpresas;
begin
  FEmpresas := LlenarCombo(cbbEmpresa, FLector.ListarEmpresas, False);
  ElegirCodigo(FEmpresas, cbbEmpresa, FConfiguracion.Propuesta.Empresa);
end;

// La lista lleva un elemento vacío si algún tipo admite documento sin
// almacén (factura sin movimientos).
procedure TfrmModalOpcionesDocumento.CargarAlmacenes;
var
  oTipo: TTipoOpcionesDocumento;
  bConVacio: Boolean;
  sAlmacen: string;
begin
  sAlmacen := CodigoElegido(FAlmacenes, cbbAlmacen);
  if FCargando then
    sAlmacen := FConfiguracion.Propuesta.Almacen;
  bConVacio := False;
  for oTipo in FConfiguracion.Tipos do
  begin
    if oTipo.MueveStockOpcional or (not oTipo.AlmacenObligatorio) then
      bConVacio := True;
  end;
  FAlmacenes := LlenarCombo(cbbAlmacen,
    FLector.ListarAlmacenes(CodigoElegido(FEmpresas, cbbEmpresa)),
    bConVacio);
  ElegirCodigo(FAlmacenes, cbbAlmacen, sAlmacen);
end;

procedure TfrmModalOpcionesDocumento.CargarTipos;
var
  iIndice: Integer;
begin
  cbbTipoDocumento.Properties.Items.Clear;
  cbbTipoDocumento.ItemIndex := -1;
  for iIndice := 0 to High(FConfiguracion.Tipos) do
  begin
    cbbTipoDocumento.Properties.Items.Add(
      FConfiguracion.Tipos[iIndice].Nombre);
    if SameText(FConfiguracion.Tipos[iIndice].Codigo,
                FConfiguracion.Propuesta.Tipo) then
      cbbTipoDocumento.ItemIndex := iIndice;
  end;
  if (cbbTipoDocumento.ItemIndex < 0) and
     (Length(FConfiguracion.Tipos) > 0) then
    cbbTipoDocumento.ItemIndex := 0;
end;

procedure TfrmModalOpcionesDocumento.CargarFormasPago;
begin
  FFormasPago := LlenarCombo(cbbFormaPago, FLector.ListarFormasPago,
    not FConfiguracion.FormaPagoObligatoria);
  ElegirCodigo(FFormasPago, cbbFormaPago,
    FConfiguracion.Propuesta.FormaPago);
end;

function TfrmModalOpcionesDocumento.TipoElegido(
  out ATipo: TTipoOpcionesDocumento): Boolean;
var
  iIndice: Integer;
begin
  ATipo := Default(TTipoOpcionesDocumento);
  iIndice := cbbTipoDocumento.ItemIndex;
  Result := (iIndice >= 0) and (iIndice < Length(FConfiguracion.Tipos));
  if Result then
    ATipo := FConfiguracion.Tipos[iIndice];
end;

procedure TfrmModalOpcionesDocumento.CargarSeries;
var
  oTipo: TTipoOpcionesDocumento;
  sSerie: string;
begin
  cbbSerie.Properties.Items.BeginUpdate;
  try
    cbbSerie.Properties.Items.Clear;
    if TipoElegido(oTipo) then
    begin
      for sSerie in FLector.ListarSeries(
          CodigoElegido(FEmpresas, cbbEmpresa), oTipo.TipoContador,
          oTipo.Subtipo) do
        cbbSerie.Properties.Items.Add(sSerie);
    end;
  finally
    cbbSerie.Properties.Items.EndUpdate;
  end;
end;

// La factura normal prioriza su serie general sobre la del almacén.
// Los demás documentos conservan la propuesta propia del almacén.
procedure TfrmModalOpcionesDocumento.ProponerSerie;
var
  oTipo: TTipoOpcionesDocumento;
  sSerieAlmacen, sSerieGeneralFactura: string;
begin
  sSerieAlmacen := '';
  sSerieGeneralFactura := '';
  if TipoElegido(oTipo) then
  begin
    sSerieAlmacen := FLector.ObtenerSerieAlmacen(
      CodigoElegido(FEmpresas, cbbEmpresa), oTipo.TipoContador,
      oTipo.Subtipo, CodigoElegido(FAlmacenes, cbbAlmacen));
    if SameText(oTipo.TipoContador, 'FC') and
       ((oTipo.Subtipo = '') or SameText(oTipo.Subtipo, 'NORMAL')) then
      sSerieGeneralFactura := FLector.ObtenerSerieGeneralFactura(
        CodigoElegido(FEmpresas, cbbEmpresa));
  end;
  cbbSerie.Text := ProponerSerieOpcionesDocumento(
    cbbSerie.Properties.Items.ToStringArray, sSerieAlmacen,
    sSerieGeneralFactura);
end;

procedure TfrmModalOpcionesDocumento.ColocarFila(AEtiqueta: TcxLabel;
  const AEditores: array of TControl; var ATop: Integer);
var
  oEditor: TControl;
begin
  if Assigned(AEtiqueta) then
    AEtiqueta.Top := ATop + ScaleValue(3);
  for oEditor in AEditores do
    oEditor.Top := ATop;
  Inc(ATop, ScaleValue(ALTO_FILA));
end;

// Oculta las filas que el llamador no pide y compacta el resto.
procedure TfrmModalOpcionesDocumento.AplicarVisibles;
var
  oTipo: TTipoOpcionesDocumento;
  iTop: Integer;
  bVisible: Boolean;
begin
  iTop := ScaleValue(24);
  ColocarAviso(iTop);
  TipoElegido(oTipo);
  bVisible := codEmpresa in FConfiguracion.Visibles;
  lblEmpresa.Visible := bVisible;
  cbbEmpresa.Visible := bVisible;
  if bVisible then
    ColocarFila(lblEmpresa, [cbbEmpresa], iTop);
  FAdicionales.Colocar(True, iTop, oTipo.Codigo);
  bVisible := codAlmacen in FConfiguracion.Visibles;
  lblAlmacen.Visible := bVisible;
  cbbAlmacen.Visible := bVisible;
  if bVisible then
    ColocarFila(lblAlmacen, [cbbAlmacen], iTop);
  // Con un solo tipo posible no hay nada que elegir.
  bVisible := (codTipo in FConfiguracion.Visibles) and
    (Length(FConfiguracion.Tipos) > 1);
  lblTipoDocumento.Visible := bVisible;
  cbbTipoDocumento.Visible := bVisible;
  if bVisible then
    ColocarFila(lblTipoDocumento, [cbbTipoDocumento], iTop);
  bVisible := codSerie in FConfiguracion.Visibles;
  lblSerie.Visible := bVisible;
  cbbSerie.Visible := bVisible;
  if bVisible then
    ColocarFila(lblSerie, [cbbSerie], iTop);
  bVisible := codNumero in FConfiguracion.Visibles;
  lblNumero.Visible := bVisible;
  chkNumeroAutomatico.Visible := bVisible;
  txtNumero.Visible := bVisible;
  if bVisible then
    ColocarFila(lblNumero, [chkNumeroAutomatico, txtNumero], iTop);
  bVisible := codFecha in FConfiguracion.Visibles;
  lblFecha.Visible := bVisible;
  dteFecha.Visible := bVisible;
  if bVisible then
    ColocarFila(lblFecha, [dteFecha], iTop);
  bVisible := codHora in FConfiguracion.Visibles;
  lblHora.Visible := bVisible;
  tmeHora.Visible := bVisible;
  if bVisible then
    ColocarFila(lblHora, [tmeHora], iTop);
  bVisible := codFormaPago in FConfiguracion.Visibles;
  lblFormaPago.Visible := bVisible;
  cbbFormaPago.Visible := bVisible;
  if bVisible then
    ColocarFila(lblFormaPago, [cbbFormaPago], iTop);
  FAdicionales.Colocar(False, iTop, oTipo.Codigo);
  bVisible := (codMueveStock in FConfiguracion.Visibles) and
    TipoElegido(oTipo) and oTipo.MueveStockOpcional;
  chkMueveStock.Visible := bVisible;
  if bVisible then
    ColocarFila(nil, [chkMueveStock], iTop);
  bVisible := (codConsolidar in FConfiguracion.Visibles) and
    TipoElegido(oTipo) and SameText(oTipo.TipoContador, 'FC');
  FConsolidar.Visible := bVisible;
  if bVisible then
    ColocarFila(nil, [FConsolidar], iTop)
  else
    FConsolidar.Checked := False;
  Inc(iTop, ScaleValue(6));
  btnCancelar.Top := iTop;
  btnAceptar.Top := iTop;
  ClientHeight := iTop + btnAceptar.Height + ScaleValue(20);
end;

// Fijos del llamador más los que deja sin uso un campo propio con valor
// (p. ej. añadir a un documento existente).
procedure TfrmModalOpcionesDocumento.ActualizarHabilitados;
var
  oOpciones: TOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
  sBloqueados: TCamposOpcionesDocumento;
begin
  oOpciones := Default(TOpcionesDocumento);
  if TipoElegido(oTipo) then
    oOpciones.Tipo := oTipo.Codigo;
  if Assigned(FAdicionales) then
    oOpciones.Adicionales := FAdicionales.Valores;
  sBloqueados := FConfiguracion.Fijos +
    CamposDeshabilitadosOpcionesDocumento(oOpciones);
  cbbEmpresa.Enabled := not (codEmpresa in sBloqueados);
  cbbAlmacen.Enabled := not (codAlmacen in sBloqueados);
  cbbTipoDocumento.Enabled := not (codTipo in sBloqueados);
  cbbSerie.Enabled := not (codSerie in sBloqueados);
  chkNumeroAutomatico.Enabled := FConfiguracion.PermiteNumeroManual and
    (not (codNumero in sBloqueados));
  txtNumero.Enabled := chkNumeroAutomatico.Enabled and
    (not chkNumeroAutomatico.Checked);
  dteFecha.Enabled := not (codFecha in sBloqueados);
  tmeHora.Enabled := dteFecha.Enabled and (not (codHora in sBloqueados));
  cbbFormaPago.Enabled := not (codFormaPago in sBloqueados);
  chkMueveStock.Enabled := not (codMueveStock in sBloqueados);
  if Assigned(FConsolidar) then
    FConsolidar.Enabled := not (codConsolidar in sBloqueados);
  if Assigned(FAdicionales) then
    FAdicionales.Habilitar(not (codAdicional in FConfiguracion.Fijos));
end;

function TfrmModalOpcionesDocumento.OpcionesElegidas: TOpcionesDocumento;
var
  oTipo: TTipoOpcionesDocumento;
begin
  Result := FConfiguracion.Propuesta;
  if codEmpresa in FConfiguracion.Visibles then
    Result.Empresa := CodigoElegido(FEmpresas, cbbEmpresa);
  if codAlmacen in FConfiguracion.Visibles then
    Result.Almacen := CodigoElegido(FAlmacenes, cbbAlmacen);
  Result.Tipo := '';
  if TipoElegido(oTipo) then
    Result.Tipo := oTipo.Codigo;
  if codSerie in FConfiguracion.Visibles then
    Result.Serie := Trim(cbbSerie.Text);
  Result.Numero := '';
  if (codNumero in FConfiguracion.Visibles) and
     (not chkNumeroAutomatico.Checked) then
    Result.Numero := Trim(txtNumero.Text);
  if codFecha in FConfiguracion.Visibles then
    Result.Fecha := Trunc(dteFecha.Date);
  Result.ConHora := codHora in FConfiguracion.Visibles;
  if Result.ConHora then
    Result.Hora := Frac(tmeHora.Time);
  if codFormaPago in FConfiguracion.Visibles then
    Result.FormaPago := CodigoElegido(FFormasPago, cbbFormaPago);
  Result.MueveStock := MueveStockOpcionesDocumento(oTipo,
    chkMueveStock.Checked);
  Result.Adicionales := AdicionalesDelTipoOpcionesDocumento(
    FAdicionales.Valores, Result.Tipo);
  Result.ConsolidarAlCrear := Assigned(FConsolidar) and
    FConsolidar.Visible and FConsolidar.Enabled and FConsolidar.Checked;
end;

function TfrmModalOpcionesDocumento.ControlDeCampo(
  ACampo: TCampoOpcionesDocumento): TWinControl;
begin
  case ACampo of
    codEmpresa:
      Result := cbbEmpresa;
    codAlmacen:
      Result := cbbAlmacen;
    codTipo:
      Result := cbbTipoDocumento;
    codSerie:
      Result := cbbSerie;
    codNumero:
      Result := txtNumero;
    codFecha:
      Result := dteFecha;
    codHora:
      Result := tmeHora;
    codFormaPago:
      Result := cbbFormaPago;
  else
    Result := chkMueveStock;
  end;
end;

procedure TfrmModalOpcionesDocumento.EnfocarControl(AControl: TWinControl);
begin
  if AControl.CanFocus then
    AControl.SetFocus;
end;

function TfrmModalOpcionesDocumento.Validar: Boolean;
var
  oResultado: TResultadoValidacionOpcionesDocumento;
  sMensaje: string;
begin
  oResultado := ValidarOpcionesDocumento(FConfiguracion, OpcionesElegidas,
    chkNumeroAutomatico.Checked);
  Result := oResultado.EsValido;
  if Result and Assigned(FConfiguracion.Validar) and
     (not FConfiguracion.Validar(OpcionesElegidas, sMensaje)) then
  begin
    Result := False;
    if sMensaje <> '' then
      ShowMessage_fza(sMensaje);
  end
  else if not Result then
  begin
    ShowMessage_fza(oResultado.Mensaje);
    if oResultado.Campo = codAdicional then
      EnfocarControl(FAdicionales.Editor(oResultado.IndiceAdicional))
    else
      EnfocarControl(ControlDeCampo(oResultado.Campo));
  end;
end;

procedure TfrmModalOpcionesDocumento.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) and
     FAdicionales.BuscarEnfocado then
    Key := 0
  else
    inherited;
end;

function TfrmModalOpcionesDocumento.IsShortCut(
  var Message: TWMKey): Boolean;
begin
  // La acción F12 heredada cerraría como Cancelar.
  if Message.CharCode = VK_F12 then
  begin
    btnAceptarClick(Self);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmModalOpcionesDocumento.btnAceptarClick(Sender: TObject);
begin
  if Validar then
  begin
    FAceptado := True;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalOpcionesDocumento.btnCancelarClick(Sender: TObject);
begin
  FAceptado := False;
  ModalResult := mrCancel;
end;

procedure TfrmModalOpcionesDocumento.cbbEmpresaPropertiesEditValueChanged(
  Sender: TObject);
begin
  if not FCargando then
  begin
    FCargando := True;
    try
      CargarAlmacenes;
      // La nueva empresa propone su primer almacén estándar activo.
      ElegirCodigo(FAlmacenes, cbbAlmacen, FLector.PrimerAlmacenEstandar(
        CodigoElegido(FEmpresas, cbbEmpresa)));
      CargarSeries;
      ProponerSerie;
    finally
      FCargando := False;
    end;
  end;
end;

procedure TfrmModalOpcionesDocumento.cbbAlmacenPropertiesEditValueChanged(
  Sender: TObject);
begin
  if not FCargando then
    ProponerSerie;
end;

procedure TfrmModalOpcionesDocumento.
  cbbTipoDocumentoPropertiesEditValueChanged(Sender: TObject);
begin
  if not FCargando then
  begin
    CargarSeries;
    ProponerSerie;
    AplicarVisibles;
    ActualizarHabilitados;
  end;
end;

procedure TfrmModalOpcionesDocumento.
  chkNumeroAutomaticoPropertiesEditValueChanged(Sender: TObject);
begin
  ActualizarHabilitados;
  if (not FCargando) and (not chkNumeroAutomatico.Checked) then
    EnfocarControl(txtNumero);
end;

end.
