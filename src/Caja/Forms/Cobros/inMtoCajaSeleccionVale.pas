{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaSeleccionVale                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Busqueda y seleccion de vales pendientes de redencion.                    }
{    Filtra por codigo y devuelve el vale al formulario de cobro.              }
{******************************************************************************}
unit inMtoCajaSeleccionVale;

{
  Formulario modal para buscar y seleccionar un vale pendiente de redención.

  Flujo:
  - Se carga el grid con vales de estado PENDIENTE (y no caducados).
  - El usuario puede filtrar por código/barras escribiendo en el campo de
    búsqueda.
  - Al seleccionar un vale y pulsar Aceptar (o doble clic / Enter), se devuelve
    el vale al formulario llamante mediante el record TValeSeleccionado.
  - Se admite el paso de un PIN de seguridad (CVV) como validación extra.

  Integración en TfrmMtoCajaFaseCobro:
    if TfrmMtoCajaSeleccionVale.Ejecutar(ValeSeleccionado) then
      FDatosCobro.RegistrarValeRecogido(ValeSeleccionado.CodigoVale,
                                         ValeSeleccionado.PinSeguridad,
                                         ImporteAplicar);
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.DB,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid,
  inMtoFrmBase, Vcl.Menus, cxStyles, dxDateRanges,
  dxScrollbarAnnotations, inLibInformesCajaPersistenciaIntf,
  inLibCajaPantallaInyeccion, inLibFaseCobroPersistenciaIntf;

type
  // Record con los datos del vale seleccionado que se devuelve al formulario
  // padre
  TValeSeleccionado = record
    CodigoVale:   string;
    PinSeguridad: string;
    Importe:      Currency;
    Descripcion:  string;
  end;

  TfrmMtoCajaSeleccionVale = class(TfrmBase)
    pnlPrincipal:   TPanel;
    pnlSuperior:    TPanel;
    pnlBotones:     TPanel;
    lblBuscar:      TcxLabel;
    edtBuscar:      TcxTextEdit;
    btnBuscar:      TcxButton;
    cxgrdVales:     TcxGrid;
    dbtvVales:      TcxGridDBTableView;
    cxgrdlvlVales:  TcxGridLevel;
    colCodigo:      TcxGridDBColumn;
    colEmpresa:     TcxGridDBColumn;
    colAlmacenEmisor:TcxGridDBColumn;
    colEstado:      TcxGridDBColumn;
    colImporte:     TcxGridDBColumn;
    colFechaEmision:TcxGridDBColumn;
    colCaducidad:   TcxGridDBColumn;
    colObservaciones:TcxGridDBColumn;
    dsVales:        TDataSource;
    btnAceptar:     TcxButton;
    btnCancelar:    TcxButton;
    lblPin: TcxLabel;
    edtPin: TcxTextEdit;
    cxLabel1: TcxLabel; // Etiqueta F2 → Cancelar / ESC
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure edtBuscarPropertiesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dbtvValesDblClick(Sender: TObject);
    procedure dbtvValesFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure btnESCClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FDatos: TDataSet;
    FRestriccionVales: TRestriccionCanjeVale;
    FValeSeleccionado: TValeSeleccionado;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FResultado: IResultadoInformeCaja;
    procedure CargarVales(const AFiltro: string = '');
    procedure ActualizarBotonAceptar;
    function  ValidarPinYSeleccionar: Boolean;
    procedure ConfigurarGrid;
  public
    constructor Create(
      AOwner: TComponent;
      const ARepositorio: IRepositorioInformesCaja;
      const ARestriccion: TRestriccionCanjeVale); reintroduce;
      overload;
    class function Ejecutar(
      out AValeSeleccionado: TValeSeleccionado): Boolean; overload;
    class function Ejecutar(
      const ARepositorio: IRepositorioInformesCaja;
      const ARestriccion: TRestriccionCanjeVale;
      out AValeSeleccionado: TValeSeleccionado): Boolean; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgCaja;

{ TfrmMtoCajaSeleccionVale }

constructor TfrmMtoCajaSeleccionVale.Create(
  AOwner: TComponent;
  const ARepositorio: IRepositorioInformesCaja;
  const ARestriccion: TRestriccionCanjeVale);
begin
  ValidarDependenciaCaja(ARepositorio, 'selección de vales');
  FRepositorioPersistencia := ARepositorio;
  FRestriccionVales := ARestriccion;
  inherited Create(AOwner);
end;

class function TfrmMtoCajaSeleccionVale.Ejecutar(
  out AValeSeleccionado: TValeSeleccionado): Boolean;
begin
  ValidarDependenciaCaja(nil, 'selección de vales');
  Result := False;
end;

class function TfrmMtoCajaSeleccionVale.Ejecutar(
  const ARepositorio: IRepositorioInformesCaja;
  const ARestriccion: TRestriccionCanjeVale;
  out AValeSeleccionado: TValeSeleccionado): Boolean;
var
  Frm: TfrmMtoCajaSeleccionVale;
begin
  ValidarDependenciaCaja(ARepositorio, 'selección de vales');
  Result := False;
  Frm := TfrmMtoCajaSeleccionVale.Create(Application, ARepositorio,
    ARestriccion);
  try
    if Frm.ShowModal = mrOk then
    begin
      AValeSeleccionado := Frm.FValeSeleccionado;
      Result := True;
    end;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmMtoCajaSeleccionVale.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F12:
      begin
        Key := 0; // Consumimos la tecla
        // Solo ejecuta la acción si el botón aceptar está activo (hay un vale
        // válido seleccionado)
        if btnAceptar.Enabled then
          btnAceptarClick(Self);
      end;
    VK_ESCAPE:
      begin
        Key := 0; // Consumimos la tecla
        btnCancelarClick(Self);
      end;
  end;
end;

procedure TfrmMtoCajaSeleccionVale.FormCreate(Sender: TObject);
begin
  inherited;
  ValidarDependenciaCaja(
    FRepositorioPersistencia,
    'selección de vales');
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
  ConfigurarGrid;
end;

procedure TfrmMtoCajaSeleccionVale.FormDestroy(Sender: TObject);
begin
  dsVales.DataSet := nil;
  FDatos := nil;
  FResultado := nil;
  FRepositorioPersistencia := nil;
  inherited;
end;

procedure TfrmMtoCajaSeleccionVale.FormShow(Sender: TObject);
var
  bPinObligatorio: Boolean;
begin
  inherited;
  bPinObligatorio :=
    ParametrosCaja.GetBool('vgerRecuperaValePIN', False);
  lblPin.Visible := bPinObligatorio;
  edtPin.Visible := bPinObligatorio;
  CargarVales;
  ActualizarBotonAceptar;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
end;

procedure TfrmMtoCajaSeleccionVale.ConfigurarGrid;
begin
  colCodigo.Caption        := SCaptionColCodigoVale;
  colEmpresa.Caption       := SCaptionColEmpresaVale;
  colAlmacenEmisor.Caption := SCaptionColAlmacenEmisorVale;
  colEstado.Caption        := SCaptionColEstadoVale;
  colImporte.Caption       := SCaptionColImporteVale;
  colFechaEmision.Caption  := SCaptionColFechaEmisionVale;
  colCaducidad.Caption     := SCaptionColCaducidadVale;
  colObservaciones.Caption := SCaptionColObservacionesVale;
  colImporte.PropertiesClassName := 'TcxCurrencyEditProperties';
end;

procedure TfrmMtoCajaSeleccionVale.CargarVales(const AFiltro: string);
var
  sPin: string;
begin
  sPin := Trim(edtPin.Text);
  dsVales.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorioPersistencia.ConsultarValesPendientes(
    AFiltro,
    sPin, FRestriccionVales);
  FDatos := FResultado.DataSet;
  dsVales.DataSet := FDatos;
  // FZ-ISSUE-380: reasignar el DataSet mueve el foco de la rejilla y
  // dbtvValesFocusedRecordChanged borra el PIN; se repone el tecleado
  // para que el vale encontrado por PIN se seleccione sin volver a pedirlo.
  if sPin <> '' then
    edtPin.Text := sPin;
  ActualizarBotonAceptar;
  if (sPin <> '') and (FDatos.RecordCount = 1) then
  begin
    if ValidarPinYSeleccionar then
      ModalResult := mrOk;
  end;
end;

procedure TfrmMtoCajaSeleccionVale.ActualizarBotonAceptar;
begin
  btnAceptar.Enabled := Assigned(FDatos) and
                        (FDatos.RecordCount > 0) and
                        (dbtvVales.Controller.FocusedRecord <> nil);
end;

procedure TfrmMtoCajaSeleccionVale.btnBuscarClick(Sender: TObject);
begin
  CargarVales(Trim(edtBuscar.Text));
end;

procedure TfrmMtoCajaSeleccionVale.edtBuscarPropertiesKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    // Si hay texto, filtrar; si está vacío, cargar todos
    CargarVales(Trim(edtBuscar.Text));
  end;
end;

procedure TfrmMtoCajaSeleccionVale.dbtvValesFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  ActualizarBotonAceptar;
  // Limpiar el PIN cuando se cambia de registro
  edtPin.Text := '';
end;

procedure TfrmMtoCajaSeleccionVale.dbtvValesDblClick(Sender: TObject);
begin
  if btnAceptar.Enabled then
    btnAceptarClick(Sender);
end;

function TfrmMtoCajaSeleccionVale.ValidarPinYSeleccionar: Boolean;
var
  PinIntroducido: string;
  PinReal:        string;
  bPinObligatorio: Boolean;
begin
  Result := False;
  if (not Assigned(FDatos)) or
     FDatos.IsEmpty or
     (FDatos.Bof and FDatos.Eof) then
  begin
    ShowMessage_fza(SErrorValeCajaNoSeleccionado);
  end
  else
  begin
    bPinObligatorio :=
      ParametrosCaja.GetBool('vgerRecuperaValePIN', False);
    PinIntroducido := Trim(edtPin.Text);
    PinReal := FDatos.FieldByName('PIN_SEGURIDAD_VL').AsString;
    if bPinObligatorio and (PinReal <> '') and
       (PinIntroducido = '') then
    begin
      ShowMessage_fza(SErrorPinValeCajaNoIndicado);
      edtPin.SetFocus;
    end
    else if bPinObligatorio and (PinReal <> '') and
            not SameText(PinIntroducido, PinReal) then
    begin
      ShowMessage_fza(SErrorPinValeCajaIncorrecto);
      edtPin.Text := '';
      edtPin.SetFocus;
    end
    else
    begin
      FValeSeleccionado.CodigoVale :=
        FDatos.FieldByName('CODIGO_VL').AsString;
      FValeSeleccionado.PinSeguridad := PinReal;
      FValeSeleccionado.Importe :=
        FDatos.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency;
      FValeSeleccionado.Descripcion :=
        FValeSeleccionado.CodigoVale;
      Result := True;
    end;
  end;
end;

procedure TfrmMtoCajaSeleccionVale.btnAceptarClick(Sender: TObject);
begin
  if ValidarPinYSeleccionar then
    ModalResult := mrOk;
end;

procedure TfrmMtoCajaSeleccionVale.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMtoCajaSeleccionVale.btnESCClick(Sender: TObject);
begin
  inherited;
  ModalResult := mrCancel;
end;

end.
