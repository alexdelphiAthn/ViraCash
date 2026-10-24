{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeleccionarBanco                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selección manual de la cuenta bancaria de la empresa al generar un        }
{    efecto de pago (compras, uso PAGO/cargo) o un recibo de cobro (ventas,    }
{    uso COBRO/ingreso). Lista las cuentas activas de la empresa desde         }
{    vi_empresas_bancos y preselecciona la marcada por defecto según el uso.   }
{    Si la empresa no tiene cuentas, informa y deja seguir sin banco.          }
{******************************************************************************}
unit inMtoModalSeleccionarBanco;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, Uni,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, inLibSeleccionBancoEmpresaPersistenciaIntf;

type
  TUsoBancoEmpresa =
    inLibSeleccionBancoEmpresaPersistenciaIntf.TUsoBancoEmpresa;

const
  ubeCobro = inLibSeleccionBancoEmpresaPersistenciaIntf.ubeCobro;
  ubePago = inLibSeleccionBancoEmpresaPersistenciaIntf.ubePago;

type
  TSeleccionBancoResult = record
    Aceptado:      Boolean;
    CodigoEmpban:  string;
    Iban:          string;
    Entidad:       string;
    Oficina:       string;
    DigitoControl: string;
    Cuenta:        string;
    Nombre:        string;
    NombreBanco:   string;
  end;

  TfrmModalSeleccionarBanco = class(TfrmBase)
    pnlInfo:      TPanel;
    lblInfo:      TcxLabel;
    pnlGrid:      TPanel;
    cxgrdBancos:  TcxGrid;
    tvBancos:     TcxGridDBTableView;
    lvlBancos:    TcxGridLevel;
    colNombre:    TcxGridDBColumn;
    colIban:      TcxGridDBColumn;
    colBanco:     TcxGridDBColumn;
    colCobro:     TcxGridDBColumn;
    colPago:      TcxGridDBColumn;
    pnlButton:    TPanel;
    btnCancelar:  TcxButton;
    btnAceptar:   TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure tvBancosDblClick(Sender: TObject);
  private
    // Campos primero (E2169).
    FRepositorio: IRepositorioSeleccionBancoEmpresa;
    FConsulta:  IConsultaBancosEmpresa;
    FDatos:     TDataSet;
    FDs:        TDataSource;
    FEmpresa:   string;
    FUso:       TUsoBancoEmpresa;
    FResultado: TSeleccionBancoResult;
    procedure CargarCuentas;
  public
    class function Ejecutar(
      AOwner               : TComponent;
      AConn                : TUniConnection;
      const ACodigoEmpresa : string;
      AUso                 : TUsoBancoEmpresa;
      const APreferEmpban  : string = ''): TSeleccionBancoResult; overload;
    class function Ejecutar(
      AOwner               : TComponent;
      const ACodigoEmpresa : string;
      AUso                 : TUsoBancoEmpresa;
      const ARepositorio   : IRepositorioSeleccionBancoEmpresa;
      const APreferEmpban  : string = ''): TSeleccionBancoResult; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgComun, inLibMsgFacturas,
  UniDataConfiguracionPantalla;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalSeleccionarBanco.Ejecutar(
  AOwner               : TComponent;
  AConn                : TUniConnection;
  const ACodigoEmpresa : string;
  AUso                 : TUsoBancoEmpresa;
  const APreferEmpban  : string): TSeleccionBancoResult;
begin
  Result := Default(TSeleccionBancoResult);
  ValidarDependenciaConfiguracion(
    nil,
    'selección de banco de empresa');
end;

class function TfrmModalSeleccionarBanco.Ejecutar(
  AOwner               : TComponent;
  const ACodigoEmpresa : string;
  AUso                 : TUsoBancoEmpresa;
  const ARepositorio   : IRepositorioSeleccionBancoEmpresa;
  const APreferEmpban  : string): TSeleccionBancoResult;
var
  frm: TfrmModalSeleccionarBanco;
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'selección de banco de empresa');
  frm := TfrmModalSeleccionarBanco.Create(AOwner);
  try
    frm.FRepositorio := ARepositorio;
    frm.FEmpresa := ACodigoEmpresa;
    frm.FUso     := AUso;
    frm.CargarCuentas;
    if frm.FDatos.IsEmpty then
    begin
      // Sin cuentas activas: se informa y se sigue sin banco asignado.
      ShowMessage_fza(SInfoEmpresaSinCuentasBancarias);
      frm.FResultado.Aceptado := True;
    end
    else
    begin
      // Pre-selecciona el banco por defecto del proveedor/cliente si se pasa
      // y pertenece a la empresa; si no, queda el ESDEFECTO segun el uso.
      if (APreferEmpban <> '') then
        frm.FDatos.Locate('CODIGO_EMPBAN', APreferEmpban, []);
      frm.ShowModal;
    end;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSeleccionarBanco.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FResultado.Aceptado := False;
  FDs  := TDataSource.Create(Self);
  tvBancos.DataController.DataSource := FDs;
end;

procedure TfrmModalSeleccionarBanco.CargarCuentas;
begin
  if FUso = ubePago then
    lblInfo.Caption := SCaptionCuentaEmpresaPagoEfectos
  else
    lblInfo.Caption := SCaptionCuentaEmpresaCobroRecibos;
  ValidarDependenciaConfiguracion(
    FRepositorio,
    'selección de banco de empresa');
  FConsulta := FRepositorio.ConsultarCuentas(FEmpresa, FUso);
  FDatos := FConsulta.DataSet;
  FDs.DataSet := FDatos;
end;

procedure TfrmModalSeleccionarBanco.btnAceptarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := True;
  if not FDatos.IsEmpty then
  begin
    FResultado.CodigoEmpban  := FDatos.FieldByName('CODIGO_EMPBAN').AsString;
    FResultado.Iban          := FDatos.FieldByName('IBAN_EMPBAN').AsString;
    FResultado.Entidad       := FDatos.FieldByName('ENTIDAD_EMPBAN').AsString;
    FResultado.Oficina       := FDatos.FieldByName('OFICINA_EMPBAN').AsString;
    FResultado.DigitoControl :=
                       FDatos.FieldByName('DIGITO_CONTROL_EMPBAN').AsString;
    FResultado.Cuenta        := FDatos.FieldByName('CUENTA_EMPBAN').AsString;
    FResultado.Nombre        := FDatos.FieldByName('NOMBRE_EMPBAN').AsString;
    FResultado.NombreBanco   :=
                       FDatos.FieldByName('NOMBRE_BAN_VIEW_EMPBAN').AsString;
  end;
  ModalResult := mrOk;
end;

procedure TfrmModalSeleccionarBanco.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := False;
  ModalResult := mrCancel;
end;

procedure TfrmModalSeleccionarBanco.tvBancosDblClick(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

initialization
  ForceReferenceToClass(TfrmModalSeleccionarBanco);
end.
