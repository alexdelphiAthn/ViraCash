{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGastoCaja                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       4.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F7 del menú de caja: gastos por caja y retiradas de efectivo.       }
{    Tipos: Pago proveedor, Gastos limpieza, Retirada banco, Retirada         }
{    encargado, Caja fuerte. Campo empleado con búsqueda (...).               }
{******************************************************************************}
unit inMtoModalGastoCaja;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxRadioGroup, cxButtonEdit, Uni,
  inMtoFrmBase, dxCoreGraphics, Vcl.Menus, cxMaskEdit, cxGroupBox,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization,
  inLibCajaVentaIntf, inLibGastoCajaPersistenciaIntf,
  inLibGenerarTicketIntf, inLibCajaPantallaInyeccion;

type
  TfrmModalGastoCaja = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblTipoLbl: TcxLabel;
    rgTipo: TcxRadioGroup;
    lblEmpleadoLbl: TcxLabel;
    btnEmpleado: TcxButtonEdit;
    lblEmpleadoNombre: TcxLabel;
    lblImporteLbl: TcxLabel;
    txtImporte: TcxCurrencyEdit;
    lblConceptoLbl: TcxLabel;
    txtConcepto: TcxTextEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AplicarEstiloCaja;
    procedure btnEmpleadoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFechaOperacion: TDateTime;
    FCodigoEmpleado: string;
    FRepositorioConsultas: IRepositorioConsultasCaja;
    FRepositorioPersistencia: IRepositorioGastoCaja;
    FLecturasImpresionTicket: ILecturasImpresionTicket;
    procedure ComponerDependencias;
    procedure BuscarEmpleados;
    procedure ProponerEmpleado;
    function ValidarEmpleado: Boolean;
    procedure Grabar;
    function ObtenerTipoTexto: string;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaOperacion: TDateTime = 0): Boolean; overload;
    class function Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ADependencias: TDependenciasGastoCaja;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaOperacion: TDateTime = 0): Boolean; overload;
    class function EjecutarConImporte(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AImporte: Currency;
      AFechaOperacion: TDateTime = 0): Boolean; overload;
    class function EjecutarConImporte(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ADependencias: TDependenciasGastoCaja;
      const AEmpresa, AAlmacen, ACaja: string;
      AImporte: Currency;
      AFechaOperacion: TDateTime = 0): Boolean; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibGenerarTicketCaja, inMtoGenSearch, Data.DB,
  inLibMsgCaja, inLibMsgComun, inLibCajaEstiloVcl, inLibPosicionFormulario,
  inLibCajaEmpleadoOperacion;

resourcestring
  SConceptoPagoProveedorGastoCaja = 'Pago proveedor';
  SConceptoGastosLimpiezaGastoCaja = 'Gastos limpieza';
  SConceptoRetiradaBancoGastoCaja = 'Retirada banco';
  SConceptoRetiradaEncargadoGastoCaja = 'Retirada encargado';
  SConceptoCajaFuerteGastoCaja = 'Caja fuerte';

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalGastoCaja.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime): Boolean;
begin
  ValidarDependenciaCaja(nil, 'contexto del gasto de Caja');
  Result := False;
end;

class function TfrmModalGastoCaja.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ADependencias: TDependenciasGastoCaja;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime): Boolean;
var
  frm: TfrmModalGastoCaja;
begin
  ADependencias.Validar;
  Result := False;
  frm := TfrmModalGastoCaja.Create(AOwner);
  try
    AsociarVentanaPropietaria(frm, AOwner);
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.FRepositorioConsultas := ADependencias.Consultas;
    frm.FRepositorioPersistencia := ADependencias.Persistencia;
    frm.FLecturasImpresionTicket := ADependencias.LecturasTicket;
    frm.ComponerDependencias;
    frm.ProponerEmpleado;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

class function TfrmModalGastoCaja.EjecutarConImporte(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AImporte: Currency;
  AFechaOperacion: TDateTime): Boolean;
begin
  ValidarDependenciaCaja(nil, 'contexto del gasto de Caja');
  Result := False;
end;

class function TfrmModalGastoCaja.EjecutarConImporte(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ADependencias: TDependenciasGastoCaja;
  const AEmpresa, AAlmacen, ACaja: string;
  AImporte: Currency;
  AFechaOperacion: TDateTime): Boolean;
var
  frm: TfrmModalGastoCaja;
begin
  ADependencias.Validar;
  Result := False;
  frm := TfrmModalGastoCaja.Create(AOwner);
  try
    AsociarVentanaPropietaria(frm, AOwner);
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.FRepositorioConsultas := ADependencias.Consultas;
    frm.FRepositorioPersistencia := ADependencias.Persistencia;
    frm.FLecturasImpresionTicket := ADependencias.LecturasTicket;
    frm.ComponerDependencias;
    frm.ProponerEmpleado;
    frm.txtImporte.Value := Double(AImporte);
    frm.lblTitulo.Caption := SCaptionRetirarSobranteRecuento;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalGastoCaja.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
  AplicarEstiloCaja;
end;

// Mismo aspecto que el resto de pantallas de caja: títulos en negrita con
// los colores del skin y botones como tarjetas con la tecla en una píldora.
procedure TfrmModalGastoCaja.AplicarEstiloCaja;
var
  Estilo: TEstiloCaja;
begin
  Estilo := TEstiloCaja.Create(Self);
  EstilarEtiquetaCaja(lblTitulo, 16, True);
  EstilarEtiquetaCaja(lblEmpleadoNombre, 15, True);
  EstilarEtiquetaCaja(lblTipoLbl, 15, False);
  rgTipo.Transparent := True;
  Estilo.EstilarBoton(btnAceptar, '', nil, 15);
  Estilo.EstilarBoton(btnCancelar, '', nil, 15);
  ColocarBotoneraDerechaCaja(btnAceptar.Parent, [btnAceptar, btnCancelar]);
end;

procedure TfrmModalGastoCaja.ComponerDependencias;
var
  Dependencias: TDependenciasGastoCaja;
begin
  Dependencias.Consultas := FRepositorioConsultas;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.LecturasTicket := FLecturasImpresionTicket;
  Dependencias.Validar;
end;

procedure TfrmModalGastoCaja.btnEmpleadoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmModalGastoCaja.btnEmpleadoPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  ValidarEmpleado;
end;

procedure TfrmModalGastoCaja.BuscarEmpleados;
var
  formulario: TfrmMtoSearch;
  oResultado: IResultadoConsultaCaja;
begin
  oResultado := FRepositorioConsultas.ConsultarEmpleados;
  formulario := TfrmMtoSearch.Create(nil);
  try
    formulario.Caption := STituloBusquedaEmpleados;
    formulario.dsTablaG.DataSet := oResultado.DataSet;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
    begin
      btnEmpleado.Text := oResultado.DataSet.Fields[0].AsString;
      ValidarEmpleado;
    end;
  finally
    FreeAndNil(formulario);
  end;
end;

// FZ-ISSUE-396: se propone el empleado por defecto de la caja si
// existe, o ninguno; el nombre del usuario no es un empleado.
procedure TfrmModalGastoCaja.ProponerEmpleado;
begin
  btnEmpleado.Text := '';
  if Assigned(ParametrosCaja) then
    btnEmpleado.Text := ProponerEmpleadoOperacionCaja(
      FRepositorioConsultas,
      ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False),
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', ''));
  ValidarEmpleado;
end;

function TfrmModalGastoCaja.ValidarEmpleado: Boolean;
var
  oEmpleado: TEmpleadoCaja;
begin
  Result := ResolverEmpleadoOperacionCaja(
    FRepositorioConsultas, btnEmpleado.Text, oEmpleado);
  FCodigoEmpleado := oEmpleado.Codigo;
  if Result then
    lblEmpleadoNombre.Caption := oEmpleado.Nombre
  else if Trim(btnEmpleado.Text) = '' then
    lblEmpleadoNombre.Caption := ''
  else
    lblEmpleadoNombre.Caption := SCaptionEmpleadoNoEncontrado;
end;

function TfrmModalGastoCaja.ObtenerTipoTexto: string;
begin
  case rgTipo.ItemIndex of
    0: Result := SConceptoPagoProveedorGastoCaja;
    1: Result := SConceptoGastosLimpiezaGastoCaja;
    2: Result := SConceptoRetiradaBancoGastoCaja;
    3: Result := SConceptoRetiradaEncargadoGastoCaja;
    4: Result := SConceptoCajaFuerteGastoCaja;
  else
    Result := '';
  end;
end;

procedure TfrmModalGastoCaja.actAceptarExecute(Sender: TObject);
begin
  if Trim(btnEmpleado.Text) = '' then
  begin
    MessageBox_fza(
      PChar(SErrorEmpleadoGastoCajaNoIndicado),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
  end
  else if not ValidarEmpleado then
  begin
    MessageBox_fza(
      PChar(Format(SErrorEmpleadoTraspasoNoEncontrado,
        [Trim(btnEmpleado.Text)])),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
  end
  else if txtImporte.Value <= 0 then
  begin
    MessageBox_fza(
      PChar(SErrorImporteGastoCajaNoValido),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    txtImporte.SetFocus;
  end
  else
  begin
    Grabar;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalGastoCaja.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalGastoCaja.Grabar;
var
  oSolicitud: TSolicitudGastoCaja;
  sNumOp: string;
  sTipo: string;
begin
  oSolicitud := Default(TSolicitudGastoCaja);
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.Almacen := FAlmacen;
  oSolicitud.Caja := FCaja;
  oSolicitud.Empleado := FCodigoEmpleado;
  oSolicitud.FechaOperacion := FFechaOperacion;
  oSolicitud.Importe := Currency(txtImporte.Value);
  sTipo := ObtenerTipoTexto;
  oSolicitud.Concepto := Trim(txtConcepto.Text);
  if oSolicitud.Concepto <> '' then
  begin
    oSolicitud.Concepto := sTipo + ': ' + oSolicitud.Concepto;
  end
  else
  begin
    oSolicitud.Concepto := sTipo;
  end;
  sNumOp := FRepositorioPersistencia.Registrar(oSolicitud);
  ImprimirTicketOperacionCaja(
    PreviewTicket,
    ConexionPrincipal,
    FLecturasImpresionTicket,
    FEmpresa,
    FAlmacen,
    FCaja,
    sNumOp,
    ParametrosCaja.ImpresoraCaja);
end;

initialization
  ForceReferenceToClass(TfrmModalGastoCaja);
end.
