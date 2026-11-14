{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalDevolucionTicket                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Localiza el ticket de origen de una devolución (F4 en caja): por          }
{    código de barras EAN-13 (prefijo 29), por EMPRESA/ALMACÉN/CAJA/Nº de      }
{    operación o por SERIE/Nº de documento.                                    }
{******************************************************************************}
unit inMtoModalDevolucionTicket;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxGroupBox, cxButtons,
  inMtoFrmBase, inLibCajaVentaIntf, dxCoreGraphics, Vcl.Menus,
  cxClasses, cxLocalization, JvComponentBase, JvEnterTab,
  inLibLectorScanner;

type
  TTicketDevolucionSeleccionado = record
    Encontrado: Boolean;
    Serie: string;
    Numero: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
  end;
  TfrmModalDevolucionTicket = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    gbCodigo: TcxGroupBox;
    txtCodigoBarras: TcxTextEdit;
    gbOperacion: TcxGroupBox;
    lblEmpresaLbl: TcxLabel;
    txtEmpresa: TcxTextEdit;
    lblAlmacenLbl: TcxLabel;
    txtAlmacen: TcxTextEdit;
    lblCajaLbl: TcxLabel;
    txtCaja: TcxTextEdit;
    lblOperacionLbl: TcxLabel;
    txtOperacion: TcxTextEdit;
    btnBuscarOperacion: TcxButton;
    gbDocumento: TcxGroupBox;
    lblSerieLbl: TcxLabel;
    txtSerie: TcxTextEdit;
    lblNumeroLbl: TcxLabel;
    txtNumero: TcxTextEdit;
    btnBuscarDocumento: TcxButton;
    lblResultado: TcxLabel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure txtCodigoBarrasKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnBuscarOperacionClick(Sender: TObject);
    procedure btnBuscarDocumentoClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    FRepositorio: IRepositorioConsultasCaja;
    FSeleccion: TTicketDevolucionSeleccionado;
    FEsApartado: TFunc<string, string, Boolean>;
    FCapturarVentaApp: Boolean;
    FAtajoHeredado: TShortCutEvent;
    // FZ-ISSUE-453: la trama STX + código + ETX del lector busca el
    // ticket sola, con o sin CR detrás y con el foco en cualquier campo.
    FLector: TLectorScanner;
    // Con KeyPreview el formulario ve la trama antes que el campo con
    // el foco y la consume: no queda escrita en Serie, Número, etc.
    procedure TeclaLector(Sender: TObject; var Key: Char);
    procedure LectorCodigoLeido(Sender: TObject; const ACodigo: string);
    // FZ-ISSUE-453: el Intro del lector se atiende como atajo del
    // formulario; el Intro-como-tabulador lo consumía antes de OnKeyDown.
    procedure AtajoTeclado(var Msg: TWMKey; var Handled: Boolean);
    procedure CrearBotonBuscarCodigo;
    procedure BotonBuscarCodigoClick(Sender: TObject);
    procedure CrearBotonVentasApp;
    procedure BotonVentasAppClick(Sender: TObject);
    procedure LimpiarSeleccion;
    procedure MostrarResultado(ADataSet: TDataSet);
    procedure MostrarResultadoVigente(ADataSet: TDataSet);
    procedure AvisarNoEncontrado;
    procedure BuscarPorCodigoBarras;
    procedure BuscarPorOperacion;
    procedure BuscarPorDocumento;
  public
    destructor Destroy; override;
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioConsultasCaja;
      const AEmpresaDefecto, AAlmacenDefecto, ACajaDefecto: string;
      out ASeleccion: TTicketDevolucionSeleccionado;
      const AEsApartado: TFunc<string, string, Boolean> = nil;
      const AAlCapturarVentaApp: TProc = nil): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMensajesVcl,
  inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalDevolucionTicket.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const AEmpresaDefecto, AAlmacenDefecto, ACajaDefecto: string;
  out ASeleccion: TTicketDevolucionSeleccionado;
  const AEsApartado: TFunc<string, string, Boolean>;
  const AAlCapturarVentaApp: TProc): Boolean;
var
  frm: TfrmModalDevolucionTicket;
  bCapturarVentaApp: Boolean;
begin
  Result := False;
  ASeleccion := Default(TTicketDevolucionSeleccionado);
  frm := TfrmModalDevolucionTicket.Create(AOwner);
  try
    frm.FRepositorio := ARepositorio;
    frm.FEsApartado := AEsApartado;
    frm.txtEmpresa.Text := AEmpresaDefecto;
    frm.txtAlmacen.Text := AAlmacenDefecto;
    frm.txtCaja.Text := ACajaDefecto;
    if Assigned(AAlCapturarVentaApp) then
      frm.CrearBotonVentasApp;
    if frm.ShowModal = mrOk then
    begin
      ASeleccion := frm.FSeleccion;
      Result := ASeleccion.Encontrado;
    end;
    bCapturarVentaApp := frm.FCapturarVentaApp;
  finally
    FreeAndNil(frm);
  end;
  // La captura abre sus propios diálogos: se lanza con el modal cerrado
  if bCapturarVentaApp then
    AAlCapturarVentaApp();
end;

// Ventas preparadas con la app móvil: se cargan en la venta en curso
procedure TfrmModalDevolucionTicket.CrearBotonVentasApp;
var
  btnVentasApp: TcxButton;
begin
  btnVentasApp := TcxButton.Create(Self);
  btnVentasApp.Parent := pnlBotones;
  btnVentasApp.SetBounds(
    pnlBotones.Width - btnCancelar.Left - btnCancelar.Width,
    btnAceptar.Top, btnAceptar.Width, btnAceptar.Height);
  btnVentasApp.Caption := SCaptionImportarVentaAppCaja;
  btnVentasApp.OnClick := BotonVentasAppClick;
end;

procedure TfrmModalDevolucionTicket.BotonVentasAppClick(Sender: TObject);
begin
  FCapturarVentaApp := True;
  ModalResult := mrCancel;
end;

procedure TfrmModalDevolucionTicket.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
  FAtajoHeredado := OnShortCut;
  OnShortCut := AtajoTeclado;
  FLector := TLectorScanner.Create;
  FLector.OnCodigoLeido := LectorCodigoLeido;
  OnKeyPress := TeclaLector;
  CrearBotonBuscarCodigo;
  LimpiarSeleccion;
end;

procedure TfrmModalDevolucionTicket.AtajoTeclado(var Msg: TWMKey;
  var Handled: Boolean);
begin
  // El CR o LF que el lector envía tras ETX no repite la búsqueda.
  if Assigned(FLector) and FLector.AtajoTeclado(Msg) then
    Handled := True
  else if (Msg.CharCode = VK_RETURN) and txtCodigoBarras.IsFocused and
     (KeyDataToShiftState(Msg.KeyData) = []) then
  begin
    Handled := True;
    BuscarPorCodigoBarras;
  end
  else if Assigned(FAtajoHeredado) then
    FAtajoHeredado(Msg, Handled);
end;

destructor TfrmModalDevolucionTicket.Destroy;
begin
  OnKeyPress := nil;
  FreeAndNil(FLector);
  inherited;
end;

procedure TfrmModalDevolucionTicket.TeclaLector(Sender: TObject;
  var Key: Char);
begin
  if Assigned(FLector) then
    FLector.KeyPress(Key);
end;

procedure TfrmModalDevolucionTicket.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  txtCodigoBarras.Text := ACodigo;
  BuscarPorCodigoBarras;
end;

// Para quien teclea el código a mano, como en los otros dos apartados.
procedure TfrmModalDevolucionTicket.CrearBotonBuscarCodigo;
var
  btnBuscarCodigo: TcxButton;
begin
  btnBuscarCodigo := TcxButton.Create(Self);
  btnBuscarCodigo.Parent := gbCodigo;
  btnBuscarCodigo.SetBounds(btnBuscarOperacion.Left,
    txtCodigoBarras.Top - 4, btnBuscarOperacion.Width,
    btnBuscarOperacion.Height);
  btnBuscarCodigo.Caption := btnBuscarOperacion.Caption;
  btnBuscarCodigo.TabOrder := txtCodigoBarras.TabOrder + 1;
  btnBuscarCodigo.OnClick := BotonBuscarCodigoClick;
end;

procedure TfrmModalDevolucionTicket.BotonBuscarCodigoClick(Sender: TObject);
begin
  BuscarPorCodigoBarras;
end;

procedure TfrmModalDevolucionTicket.FormShow(Sender: TObject);
begin
  // El lector escribe el código y envía CR: foco directo al escaneo
  if txtCodigoBarras.CanFocus then
    txtCodigoBarras.SetFocus;
end;

procedure TfrmModalDevolucionTicket.LimpiarSeleccion;
begin
  FSeleccion := Default(TTicketDevolucionSeleccionado);
  lblResultado.Caption := '';
  actAceptar.Enabled := False;
end;

procedure TfrmModalDevolucionTicket.AvisarNoEncontrado;
begin
  LimpiarSeleccion;
  MessageBox_fza(
    PChar(SErrorTicketDevolucionCajaNoEncontrado),
    PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.MostrarResultado(ADataSet: TDataSet);
var
  Resolver: IResolverDocumentoDevolucionCaja;
  Documento: TDocumentoOrigenDevolucionCaja;
  Consulta: IResultadoConsultaCaja;
begin
  LimpiarSeleccion;
  if Assigned(ADataSet) and not ADataSet.IsEmpty and
     Supports(FRepositorio, IResolverDocumentoDevolucionCaja, Resolver) then
  begin
    Documento := Resolver.ResolverDocumentoDevolucion(
      ADataSet.FieldByName('SERIE_FAC').AsString,
      ADataSet.FieldByName('NUMERO_FAC').AsString);
    Consulta := FRepositorio.ConsultarCabeceraFactura(
      Documento.Serie, Documento.Numero);
    MostrarResultadoVigente(Consulta.DataSet);
  end
  else
    MostrarResultadoVigente(ADataSet);
end;

procedure TfrmModalDevolucionTicket.MostrarResultadoVigente(
  ADataSet: TDataSet);
begin
  if (ADataSet = nil) or ADataSet.IsEmpty then
    AvisarNoEncontrado
  else if SameText(
    Trim(ADataSet.FieldByName('TIPO_FAC').AsString),
    'RECTIFICATIVA') then
  begin
    LimpiarSeleccion;
    MessageBox_fza(
      PChar(SErrorTicketDevolucionCajaEsRectificativa),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
  end
  else
  begin
    FSeleccion.Encontrado := True;
    FSeleccion.Serie :=
      ADataSet.FieldByName('SERIE_FAC').AsString;
    FSeleccion.Numero :=
      ADataSet.FieldByName('NUMERO_FAC').AsString;
    FSeleccion.Empresa :=
      ADataSet.FieldByName('CODIGO_EMP_FAC').AsString;
    FSeleccion.Almacen :=
      ADataSet.FieldByName('CODIGO_ALM_FAC').AsString;
    FSeleccion.Caja :=
      ADataSet.FieldByName('CODIGO_CAJA_FAC').AsString;
    FSeleccion.NumeroOperacion :=
      ADataSet.FieldByName('NUMERO_OPERACION_FAC').AsString;
    lblResultado.Caption := FormatearMensajeDocumentos(
      CrearFormatoDocumentoLecturas(ConexionPrincipal)
      .LeerFormatoEmpresa(FSeleccion.Empresa),
      SInfoTicketDevolucionCajaLocalizado,
      [FSeleccion.Serie,
      FSeleccion.Numero,
      FormatDateTime(
        'dd/mm/yyyy hh:nn',
        ADataSet.FieldByName('INSTANTE_ALTA').AsDateTime),
      FSeleccion.Almacen,
      FormatFloat(
        '#,##0.00',
        ADataSet.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency)]);
    actAceptar.Enabled := True;
    // Un apartado del cliente de Varios se carga sin pasar por F12
    if Assigned(FEsApartado) and
       FEsApartado(FSeleccion.Serie, FSeleccion.Numero) then
      ModalResult := mrOk;
  end;
end;

procedure TfrmModalDevolucionTicket.BuscarPorCodigoBarras;
var
  oConsulta: IResultadoConsultaCaja;
begin
  if Trim(txtCodigoBarras.Text) <> '' then
  begin
    oConsulta := FRepositorio.ConsultarFacturaPorCodigoBarras(
      Trim(txtCodigoBarras.Text));
    MostrarResultado(oConsulta.DataSet);
    // Listo para la siguiente lectura si no era el ticket buscado.
    if (ModalResult = mrNone) and txtCodigoBarras.CanFocus then
    begin
      txtCodigoBarras.SetFocus;
      txtCodigoBarras.SelectAll;
    end;
  end;
end;

procedure TfrmModalDevolucionTicket.BuscarPorOperacion;
var
  oConsulta: IResultadoConsultaCaja;
begin
  if (Trim(txtEmpresa.Text) <> '') and
     (Trim(txtAlmacen.Text) <> '') and
     (Trim(txtCaja.Text) <> '') and
     (Trim(txtOperacion.Text) <> '') then
  begin
    oConsulta := FRepositorio.ConsultarFacturaPorOperacion(
      Trim(txtEmpresa.Text),
      Trim(txtAlmacen.Text),
      Trim(txtCaja.Text),
      Trim(txtOperacion.Text));
    MostrarResultado(oConsulta.DataSet);
  end
  else
    MessageBox_fza(
      PChar(SErrorTicketDevolucionCajaDatosOperacion),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.BuscarPorDocumento;
var
  oConsulta: IResultadoConsultaCaja;
begin
  if (Trim(txtSerie.Text) <> '') and
     (Trim(txtNumero.Text) <> '') then
  begin
    oConsulta := FRepositorio.ConsultarCabeceraFactura(
      Trim(txtSerie.Text),
      Trim(txtNumero.Text));
    MostrarResultado(oConsulta.DataSet);
  end
  else
    MessageBox_fza(
      PChar(SErrorTicketDevolucionCajaDatosDocumento),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.txtCodigoBarrasKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // El lector remata la trama con CR
  if Key = VK_RETURN then
  begin
    Key := 0;
    BuscarPorCodigoBarras;
  end;
end;

procedure TfrmModalDevolucionTicket.btnBuscarOperacionClick(
  Sender: TObject);
begin
  BuscarPorOperacion;
end;

procedure TfrmModalDevolucionTicket.btnBuscarDocumentoClick(
  Sender: TObject);
begin
  BuscarPorDocumento;
end;

procedure TfrmModalDevolucionTicket.actAceptarExecute(Sender: TObject);
begin
  if FSeleccion.Encontrado then
    ModalResult := mrOk
  else
    MessageBox_fza(
      PChar(SErrorTicketDevolucionCajaSinSeleccion),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalDevolucionTicket);
end.
