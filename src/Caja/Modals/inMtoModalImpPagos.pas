{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpPagos                                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del histórico de pagos de caja (FastReport).           }
{    Informe A4 horizontal con los pagos del TPV, filtrados por empresa /      }
{    almacén / caja, rango de fechas y forma(s) de pago. El usuario puede      }
{    retocar el formato con el diseñador (botón Editar) y guardarlo.           }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo. Lee    }
{    de la vista vi_caja_pagos (DESARROLLOS EN CURSO/vista_caja_pagos.sql).    }
{******************************************************************************}
unit inMtoModalImpPagos;

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
  cxDateUtils, cxCheckListBox, cxCheckBox,
  Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, inLibInformesCajaPersistenciaIntf,
  inLibCajasDefectoPersistenciaIntf, inLibCajaPantallaInyeccion,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintPagos = class(TfrmPrint)
    dsPagosPrint: TDataSource;
    fxdsPagos: TfrxDBDataset;
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
    lblFormasPago: TcxLabel;
    clbFormasPago: TcxCheckListBox;
    dsTotalesPagosPrint: TDataSource;
    fxdsTotalesPagos: TfrxDBDataset;
    procedure bedAlmacenPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure bedCajaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure dtFechasPropertiesEditValueChanged(Sender: TObject);
  private
    // Fija los valores por defecto una sola vez al abrir; evita pisarlos en el
    // ciclo Hide/Show que hacen los botones del padre (Imprimir / PDF / etc.).
    FInicializado: Boolean;
    // Codigo de forma de pago de cada item de clbFormasPago, en el mismo
    // orden (el item solo guarda el texto "COD - Descripcion").
    FCodigosFP: TStringList;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FRepositorioCajasDefecto: IRepositorioCajasDefecto;
    FResultado: IResultadoInformeCaja;
    // Totales por forma de pago (y, sumados en el informe, el general).
    FResultadoTotales: IResultadoInformeCaja;
    procedure ComponerDependencias;
    // Abre el selector estandar de caja (inMtoModalCajDef) acotado a la
    // empresa del usuario y vuelca el almacen y la caja en bedAlmacen/bedCaja.
    procedure SeleccionarAlmacenCaja;
    // Rellena el listbox con las formas de pago presentes en los pagos del
    // periodo / caja actuales (todas marcadas por defecto).
    procedure CargarFormasPago;
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
    destructor Destroy; override;
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

uses
  inMtoModalCajDef, inLibResumenSeleccionesVcl;

{ TfrmPrintPagos }

constructor TfrmPrintPagos.Create(
  AOwner: TComponent;
  const ADependencias: TDependenciasInformeCaja);
begin
  ADependencias.Validar;
  FRepositorioPersistencia := ADependencias.Repositorio;
  FRepositorioCajasDefecto := ADependencias.CajasDefecto;
  inherited Create(AOwner);
end;

destructor TfrmPrintPagos.Destroy;
begin
  FreeAndNil(FCodigosFP);
  inherited;
end;

procedure TfrmPrintPagos.DoShow;
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
    CargarFormasPago;
  end;
end;

procedure TfrmPrintPagos.ComponerDependencias;
var
  Dependencias: TDependenciasInformeCaja;
begin
  Dependencias.Repositorio := FRepositorioPersistencia;
  Dependencias.CajasDefecto := FRepositorioCajasDefecto;
  Dependencias.Validar;
end;

procedure TfrmPrintPagos.CargarFormasPago;
var
  FormasPago: TFormasPagoInformeCaja;
  FormaPago: TFormaPagoInformeCaja;
  item: TcxCheckListBoxItem;
begin
  // Listamos las formas de pago distintas que aparecen en los pagos del
  // periodo / caja seleccionados, con su descripcion. Todas marcadas: por
  // defecto no se filtra por forma de pago.
  if FCodigosFP = nil then
    FCodigosFP := TStringList.Create;
  clbFormasPago.Items.BeginUpdate;
  try
    clbFormasPago.Items.Clear;
    FCodigosFP.Clear;
    FormasPago := FRepositorioPersistencia.ListarFormasPago(
      ConstruirSolicitud);
    for FormaPago in FormasPago do
    begin
      item := clbFormasPago.Items.Add;
      item.Text := FormaPago.Codigo + ' - ' + FormaPago.Descripcion;
      item.Checked := True;
      FCodigosFP.Add(FormaPago.Codigo);
    end;
  finally
    clbFormasPago.Items.EndUpdate;
  end;
end;

procedure TfrmPrintPagos.SeleccionarAlmacenCaja;
var
  frm: TfrmMtoModalCajDef;
  bCambio: Boolean;
begin
  // No se permite cambiar de empresa: acotamos el selector a la empresa
  // del usuario. De la fila elegida tomamos almacen y caja.
  bCambio := False;
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
      bCambio         := True;
    end;
  finally
    FreeAndNil(frm);
  end;
  // Si cambio la caja, refrescamos las formas de pago de ese contexto.
  if bCambio and FInicializado then
    CargarFormasPago;
end;

procedure TfrmPrintPagos.bedAlmacenPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintPagos.bedCajaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintPagos.dtFechasPropertiesEditValueChanged(Sender: TObject);
begin
  // Al cambiar el rango refrescamos las formas de pago del periodo. El guard
  // evita ejecutarlo mientras DoShow fija los valores por defecto (cuando
  // aun no estan puestos empresa / almacen / caja).
  if FInicializado then
    CargarFormasPago;
end;

procedure TfrmPrintPagos.preparar_consulta;
var
  CodigosSeleccionados: TCodigosFormaPagoInformeCaja;
  i: Integer;
  nMarcadas: Integer;
begin
  inherited;
  // Forma(s) de pago marcadas en el listbox. Solo se filtra cuando la
  // seleccion es parcial: si estan todas (o ninguna) marcadas no se filtra,
  // de modo que el listado no sale vacio por descuido.
  nMarcadas := 0;
  SetLength(CodigosSeleccionados, 0);
  for i := 0 to clbFormasPago.Items.Count - 1 do
  begin
    if clbFormasPago.Items[i].Checked then
    begin
      Inc(nMarcadas);
      SetLength(
        CodigosSeleccionados,
        Length(CodigosSeleccionados) + 1);
      CodigosSeleccionados[High(CodigosSeleccionados)] :=
        FCodigosFP[i];
    end;
  end;
  // fza_caja_pagos no tiene fecha propia: leemos de vi_caja_pagos, que expone
  // FECHA_PAGO (de la operacion asociada) y NUMERO_FAC_PAGO / SERIE_FAC_PAGO.
  // El rango se aplica sobre DATE(FECHA_PAGO) para ser inclusivo por dia.
  if (nMarcadas = 0) or
     (nMarcadas = clbFormasPago.Items.Count) then
  begin
    SetLength(CodigosSeleccionados, 0);
  end;
  dsPagosPrint.DataSet := nil;
  dsTotalesPagosPrint.DataSet := nil;
  FResultado := FRepositorioPersistencia.ConsultarPagos(
    ConstruirSolicitud,
    CodigosSeleccionados);
  FResultadoTotales := FRepositorioPersistencia.ConsultarTotalesPagos(
    ConstruirSolicitud,
    CodigosSeleccionados);
  dsPagosPrint.DataSet := FResultado.DataSet;
  dsTotalesPagosPrint.DataSet := FResultadoTotales.DataSet;
  fxdsPagos.UpdateBounds;
  fxdsTotalesPagos.UpdateBounds;
end;

procedure TfrmPrintPagos.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AResumen.AnadirRangoFechas(
    lblFechas.Caption, dteDesde.Date, dteHasta.Date);
  AResumen.Anadir(lblEmpresa.Caption, edtEmpresa.Text);
  AResumen.Anadir(lblAlmacen.Caption, bedAlmacen.Text);
  AResumen.Anadir(lblCaja.Caption, bedCaja.Text);
  // Ninguna o todas marcadas: la consulta no filtra.
  AnadirMarcados(
    AResumen,
    lblFormasPago.Caption,
    clbFormasPago,
    SResumenSeleccionesTodas,
    True);
end;

function TfrmPrintPagos.ConstruirSolicitud: TSolicitudInformeCaja;
begin
  Result.Empresa := edtEmpresa.Text;
  Result.Almacen := bedAlmacen.Text;
  Result.Caja := bedCaja.Text;
  Result.FechaDesde := dteDesde.Date;
  Result.FechaHasta := dteHasta.Date;
end;

end.
