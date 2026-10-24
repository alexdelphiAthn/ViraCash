{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpDepositos                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del histórico de depósitos de clientes (FastReport).   }
{    Informe A4 horizontal con los depósitos, filtrados por empresa /          }
{    almacén / caja y rango de fechas. El usuario puede retocar el formato     }
{    con el diseñador (botón Editar) y guardarlo como formato propio.          }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo.        }
{******************************************************************************}
unit inMtoModalImpDepositos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxButtonEdit,
  cxDateUtils,
  Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, inLibInformesCajaPersistenciaIntf,
  inLibCajasDefectoPersistenciaIntf, inLibCajaPantallaInyeccion,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintDepositos = class(TfrmPrint)
    dsDepositosPrint: TDataSource;
    fxdsDepositos: TfrxDBDataset;
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblCajaTit: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    bedAlmacen: TcxButtonEdit;
    lblCaja: TcxLabel;
    bedCaja: TcxButtonEdit;
    procedure bedAlmacenPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure bedCajaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  private
    // Fija los valores por defecto (rango de fechas y empresa/almacen/caja
    // del usuario) una sola vez al abrir; evita pisarlos en el ciclo
    // Hide/Show que hacen los botones del padre (Imprimir / PDF / etc.).
    FInicializado: Boolean;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FRepositorioCajasDefecto: IRepositorioCajasDefecto;
    FResultado: IResultadoInformeCaja;
    procedure ComponerDependencias;
    // Abre el selector estandar de caja (inMtoModalCajDef sobre la vista
    // vi_cajasdef) acotado a la empresa del usuario y vuelca el almacen y
    // la caja elegidos en bedAlmacen / bedCaja.
    procedure SeleccionarAlmacenCaja;
    function ConstruirSolicitud: TSolicitudInformeCaja;
  protected
    procedure DoShow; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
  public
    constructor Create(
      AOwner: TComponent;
      const ADependencias: TDependenciasInformeCaja); reintroduce;
      overload;
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

uses
  inMtoModalCajDef;

{ TfrmPrintDepositos }

constructor TfrmPrintDepositos.Create(
  AOwner: TComponent;
  const ADependencias: TDependenciasInformeCaja);
begin
  ADependencias.Validar;
  FRepositorioPersistencia := ADependencias.Repositorio;
  FRepositorioCajasDefecto := ADependencias.CajasDefecto;
  inherited Create(AOwner);
end;

procedure TfrmPrintDepositos.DoShow;
begin
  inherited;
  ComponerDependencias;
  // Por defecto: rango del primer dia del mes en curso hasta hoy, y la
  // empresa / almacen / caja activos del usuario. El usuario puede ampliar
  // las fechas y cambiar almacen / caja con el boton '...' antes de imprimir.
  if not FInicializado then
  begin
    dteDesde.Date   := EncodeDate(YearOf(Date), MonthOf(Date), 1);
    dteHasta.Date   := Date;
    edtEmpresa.Text := UbicacionSesion.Empresa;
    bedAlmacen.Text := UbicacionSesion.Almacen;
    bedCaja.Text    := UbicacionSesion.Caja;
    FInicializado   := True;
  end;
end;

procedure TfrmPrintDepositos.ComponerDependencias;
var
  Dependencias: TDependenciasInformeCaja;
begin
  Dependencias.Repositorio := FRepositorioPersistencia;
  Dependencias.CajasDefecto := FRepositorioCajasDefecto;
  Dependencias.Validar;
end;

procedure TfrmPrintDepositos.SeleccionarAlmacenCaja;
var
  frm: TfrmMtoModalCajDef;
begin
  // No se permite cambiar de empresa: acotamos el selector a la empresa
  // del usuario. De la fila elegida tomamos almacen y caja.
  frm := TfrmMtoModalCajDef.Create(
    Self,
    FRepositorioCajasDefecto);
  try
    frm.Cargar(edtEmpresa.Text);
    // Cierra el cronometro SQL antes de entrar en el selector modal.
    CerrarMonitorSQLPendiente;
    frm.sEmpresa := edtEmpresa.Text;
    frm.sAlmacen := bedAlmacen.Text;
    frm.sCaja    := bedCaja.Text;
    frm.ShowModal;
    if frm.sFicha = 'S' then
    begin
      bedAlmacen.Text := frm.AlmacenSeleccionado;
      bedCaja.Text    := frm.CajaSeleccionada;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmPrintDepositos.bedAlmacenPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintDepositos.bedCajaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintDepositos.preparar_consulta;
begin
  inherited;
  // Filtro por empresa / almacen / caja (los tres exactos) y por la fecha de
  // creacion del deposito. FECHA_CREACION_DEP es datetime, por eso el rango
  // se aplica sobre DATE(...) para que el BETWEEN sea inclusivo por dia.
  dsDepositosPrint.DataSet := nil;
  FResultado := FRepositorioPersistencia.ConsultarDepositos(
    ConstruirSolicitud);
  dsDepositosPrint.DataSet := FResultado.DataSet;
  fxdsDepositos.UpdateBounds;
end;

procedure TfrmPrintDepositos.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AResumen.AnadirRangoFechas(
    lblFechas.Caption, dteDesde.Date, dteHasta.Date);
  AResumen.Anadir(lblEmpresa.Caption, edtEmpresa.Text);
  AResumen.Anadir(lblAlmacen.Caption, bedAlmacen.Text);
  AResumen.Anadir(lblCaja.Caption, bedCaja.Text);
end;

function TfrmPrintDepositos.ConstruirSolicitud: TSolicitudInformeCaja;
begin
  Result.Empresa := edtEmpresa.Text;
  Result.Almacen := bedAlmacen.Text;
  Result.Caja := bedCaja.Text;
  Result.FechaDesde := dteDesde.Date;
  Result.FechaHasta := dteHasta.Date;
end;

end.
