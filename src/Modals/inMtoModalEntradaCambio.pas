{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalEntradaCambio                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       3.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F6 del menú de caja: entrada de cambio. Campo empleado con          }
{    búsqueda (...) igual que en operaciones de caja.                          }
{******************************************************************************}
unit inMtoModalEntradaCambio;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxButtonEdit, Uni,
  inMtoFrmBase, inLibCajaVentaIntf,
  inLibEntradaCambioPersistenciaIntf, inLibGenerarTicketIntf,
  inLibCajaPantallaInyeccion;

type
  TfrmModalEntradaCambio = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
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
    FConceptoPredeterminado: string;
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFechaOperacion: TDateTime;
    FCodigoEmpleado: string;
    FRepositorioConsultas: IRepositorioConsultasCaja;
    FRepositorioEntrada: IRepositorioEntradaCambio;
    FLecturasImpresionTicket: ILecturasImpresionTicket;
    procedure ComponerDependencias;
    procedure BuscarEmpleados;
    procedure ProponerEmpleado;
    function ValidarEmpleado: Boolean;
    procedure Grabar;
  public
    procedure AplicarTraduccionActual; override;
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const AEmpresa, AAlmacen, ACaja: string;
                            AFechaOperacion: TDateTime = 0
                            ): Boolean; overload;
    class function Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ADependencias: TDependenciasEntradaCambio;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaOperacion: TDateTime = 0): Boolean; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibGenerarTicketCaja, inMtoGenSearch, inLibMsgComun, inLibMsgCaja,
  inLibCajaEstiloVcl, inLibPosicionFormulario,
  inLibCajaEmpleadoOperacion;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalEntradaCambio.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime): Boolean;
begin
  ValidarDependenciaCaja(nil, 'contexto de entrada de cambio');
  Result := False;
end;

class function TfrmModalEntradaCambio.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ADependencias: TDependenciasEntradaCambio;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime): Boolean;
var
  frm: TfrmModalEntradaCambio;
begin
  ADependencias.Validar;
  Result := False;
  frm := TfrmModalEntradaCambio.Create(AOwner);
  try
    AsociarVentanaPropietaria(frm, AOwner);
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.FRepositorioConsultas := ADependencias.Consultas;
    frm.FRepositorioEntrada := ADependencias.Persistencia;
    frm.FLecturasImpresionTicket := ADependencias.LecturasTicket;
    frm.ComponerDependencias;
    frm.ProponerEmpleado;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
    if Assigned(Application.MainForm) and
       Application.MainForm.HandleAllocated then
      RedrawWindow(Application.MainForm.Handle, nil, 0,
        RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or
        RDW_ALLCHILDREN or RDW_UPDATENOW);
  end;
end;

procedure TfrmModalEntradaCambio.ComponerDependencias;
var
  Dependencias: TDependenciasEntradaCambio;
begin
  Dependencias.Consultas := FRepositorioConsultas;
  Dependencias.Persistencia := FRepositorioEntrada;
  Dependencias.LecturasTicket := FLecturasImpresionTicket;
  Dependencias.Validar;
end;

procedure TfrmModalEntradaCambio.AplicarTraduccionActual;
begin
  inherited;
  if Assigned(txtConcepto) then
  begin
    if (txtConcepto.Text = '') or
       (txtConcepto.Text = FConceptoPredeterminado) then
      txtConcepto.Text := SConceptoEntradaCambio;
    FConceptoPredeterminado := SConceptoEntradaCambio;
  end;
end;

procedure TfrmModalEntradaCambio.FormCreate(Sender: TObject);
begin
  inherited;
  AplicarTraduccionActual;
  KeyPreview := True;
  Position := poScreenCenter;
  AplicarEstiloCaja;
end;

// Mismo aspecto que el resto de pantallas de caja: títulos en negrita con
// los colores del skin y botones como tarjetas con la tecla en una píldora.
procedure TfrmModalEntradaCambio.AplicarEstiloCaja;
var
  Estilo: TEstiloCaja;
begin
  Estilo := TEstiloCaja.Create(Self);
  EstilarEtiquetaCaja(lblTitulo, 16, True);
  EstilarEtiquetaCaja(lblEmpleadoNombre, 15, True);
  Estilo.EstilarBoton(btnAceptar, '', nil, 15);
  Estilo.EstilarBoton(btnCancelar, '', nil, 15);
  ColocarBotoneraDerechaCaja(btnAceptar.Parent, [btnAceptar, btnCancelar]);
end;

procedure TfrmModalEntradaCambio.btnEmpleadoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmModalEntradaCambio.btnEmpleadoPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  ValidarEmpleado;
end;

procedure TfrmModalEntradaCambio.BuscarEmpleados;
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
procedure TfrmModalEntradaCambio.ProponerEmpleado;
begin
  btnEmpleado.Text := '';
  if Assigned(ParametrosCaja) then
    btnEmpleado.Text := ProponerEmpleadoOperacionCaja(
      FRepositorioConsultas,
      ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False),
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', ''));
  ValidarEmpleado;
end;

function TfrmModalEntradaCambio.ValidarEmpleado: Boolean;
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

procedure TfrmModalEntradaCambio.actAceptarExecute(Sender: TObject);
begin
  if Trim(btnEmpleado.Text) = '' then
  begin
    MessageBox_fza(
      PChar(SErrorEmpleadoEntradaCambioNoIndicado),
      PChar(STituloAvisoEntradaCambio), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
  end
  else if not ValidarEmpleado then
  begin
    MessageBox_fza(
      PChar(Format(SErrorEmpleadoTraspasoNoEncontrado,
        [Trim(btnEmpleado.Text)])),
      PChar(STituloAvisoEntradaCambio), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
  end
  else if txtImporte.Value <= 0 then
  begin
    MessageBox_fza(
      PChar(SErrorImporteEntradaCambioNoValido),
      PChar(STituloAvisoEntradaCambio), MB_OK or MB_ICONWARNING);
    txtImporte.SetFocus;
  end
  else
  begin
    Grabar;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalEntradaCambio.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalEntradaCambio.Grabar;
var
  oSolicitud: TSolicitudEntradaCambio;
  sNumOp: string;
  sConcepto, sEmpleado: string;
begin
  sEmpleado := FCodigoEmpleado;
  sConcepto := Trim(txtConcepto.Text);
  if sConcepto = '' then
  begin
    sConcepto := SConceptoEntradaCambio;
  end;
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.Almacen := FAlmacen;
  oSolicitud.Caja := FCaja;
  oSolicitud.Empleado := sEmpleado;
  oSolicitud.Concepto := sConcepto;
  oSolicitud.FechaOperacion := FFechaOperacion;
  oSolicitud.Importe := Currency(txtImporte.Value);
  sNumOp := FRepositorioEntrada.Registrar(oSolicitud);
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
  ForceReferenceToClass(TfrmModalEntradaCambio);
end.
