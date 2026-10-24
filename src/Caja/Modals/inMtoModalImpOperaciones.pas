{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpOperaciones                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del histórico de operaciones de caja (FastReport).     }
{    Informe A4 horizontal con las operaciones del TPV, filtradas por empresa  }
{    / almacén / caja y rango de fechas. El usuario puede retocar el formato   }
{    con el diseñador (botón Editar) y guardarlo como formato propio.          }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo.        }
{******************************************************************************}
unit inMtoModalImpOperaciones;

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
  TfrmPrintOperaciones = class(TfrmPrint)
    dsOperacionesPrint: TDataSource;
    fxdsOperaciones: TfrxDBDataset;
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
    dsTotalesOperacionesPrint: TDataSource;
    fxdsTotalesOperaciones: TfrxDBDataset;
    procedure bedAlmacenPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure bedCajaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnExcelNativoClick(Sender: TObject);
  private
    // Fija los valores por defecto (rango de fechas y empresa/almacen/caja
    // del usuario) una sola vez al abrir; evita pisarlos en el ciclo
    // Hide/Show que hacen los botones del padre (Imprimir / PDF / etc.).
    FInicializado: Boolean;
    FPuedeImprimir: Boolean;
    FPuedeExportar: Boolean;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FRepositorioCajasDefecto: IRepositorioCajasDefecto;
    FResultado: IResultadoInformeCaja;
    // Totales por tipo de operacion (y, sumados en el informe, el general).
    FResultadoTotales: IResultadoInformeCaja;
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
      const ADependencias: TDependenciasInformeCaja;
      APuedeImprimir, APuedeExportar: Boolean); reintroduce;
      overload;
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

uses
  inMtoModalCajDef, inMtoPreviewExcel, inLibOperacionesCajaExcel;

resourcestring
  SFormatoNombreArchivoOperacionesCaja = 'Operaciones_caja_%s_%s_%s_%s';

{ TfrmPrintOperaciones }

constructor TfrmPrintOperaciones.Create(
  AOwner: TComponent;
  const ADependencias: TDependenciasInformeCaja;
  APuedeImprimir, APuedeExportar: Boolean);
begin
  ADependencias.Validar;
  FRepositorioPersistencia := ADependencias.Repositorio;
  FRepositorioCajasDefecto := ADependencias.CajasDefecto;
  FPuedeImprimir := APuedeImprimir;
  FPuedeExportar := APuedeExportar;
  inherited Create(AOwner);
end;

// Excel nativo DevExpress en lugar de la exportacion XLSX de FastReport:
// una fila por operacion con fechas e importes tipados y el total.
procedure TfrmPrintOperaciones.btnExcelNativoClick(Sender: TObject);
var
  oPreview: TfrmMtoPreviewExcel;
  rCabecera: TCabeceraListadoOperacionesCaja;
begin
  if FPuedeExportar then
  begin
    IniciarMedicionDatos;
    preparar_consulta;
    PausarMedicionDatos;
    rCabecera.Empresa := edtEmpresa.Text;
    rCabecera.Almacen := bedAlmacen.Text;
    rCabecera.Caja := bedCaja.Text;
    rCabecera.FechaDesde := Trunc(dteDesde.Date);
    rCabecera.FechaHasta := Trunc(dteHasta.Date);
    Self.Hide;
    try
      oPreview := TfrmMtoPreviewExcel.Create(Self);
      try
        oPreview.PopupParent := Self;
        oPreview.DialogoGuardar.InitialDir :=
          ParametrosApp.GetPath('appDirExcel');
        oPreview.DialogoGuardar.FileName := Format(
          SFormatoNombreArchivoOperacionesCaja,
          [rCabecera.Empresa,
           rCabecera.Almacen,
           rCabecera.Caja,
           FormatDateTime('yyyymmdd_hhnnss', Now)]);
        Screen.Cursor := crHourGlass;
        try
          ExportarOperacionesCajaExcel(
            oPreview.dxSpreadSheet1,
            FResultado.DataSet,
            rCabecera,
            LineasResumenSelecciones);
        finally
          Screen.Cursor := crDefault;
        end;
        oPreview.ShowModal;
      finally
        FreeAndNil(oPreview);
      end;
    finally
      Self.Show;
    end;
  end;
end;

procedure TfrmPrintOperaciones.DoShow;
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
    btnVistaPreliminar.Visible := FPuedeImprimir;
    btnPDF.Visible := FPuedeImprimir;
    btnEditar.Visible := FPuedeImprimir;
    btnImprimir.Visible := FPuedeImprimir;
    btnExcel.Visible := FPuedeExportar;
    FInicializado   := True;
  end;
end;

procedure TfrmPrintOperaciones.ComponerDependencias;
var
  Dependencias: TDependenciasInformeCaja;
begin
  Dependencias.Repositorio := FRepositorioPersistencia;
  Dependencias.CajasDefecto := FRepositorioCajasDefecto;
  Dependencias.Validar;
end;

procedure TfrmPrintOperaciones.SeleccionarAlmacenCaja;
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

procedure TfrmPrintOperaciones.bedAlmacenPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintOperaciones.bedCajaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintOperaciones.preparar_consulta;
begin
  inherited;
  // Filtro por empresa / almacen / caja (los tres exactos) y por la fecha
  // de la operacion. FECHA_OPERACION_OPCAJA es datetime, por eso el rango
  // se aplica sobre DATE(...) para que el BETWEEN sea inclusivo por dia.
  dsOperacionesPrint.DataSet := nil;
  dsTotalesOperacionesPrint.DataSet := nil;
  FResultado := FRepositorioPersistencia.ConsultarOperaciones(
    ConstruirSolicitud);
  FResultadoTotales :=
    FRepositorioPersistencia.ConsultarTotalesOperaciones(
      ConstruirSolicitud);
  dsOperacionesPrint.DataSet := FResultado.DataSet;
  dsTotalesOperacionesPrint.DataSet := FResultadoTotales.DataSet;
  fxdsOperaciones.UpdateBounds;
  fxdsTotalesOperaciones.UpdateBounds;
end;

procedure TfrmPrintOperaciones.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AResumen.AnadirRangoFechas(
    lblFechas.Caption, dteDesde.Date, dteHasta.Date);
  AResumen.Anadir(lblEmpresa.Caption, edtEmpresa.Text);
  AResumen.Anadir(lblAlmacen.Caption, bedAlmacen.Text);
  AResumen.Anadir(lblCaja.Caption, bedCaja.Text);
end;

function TfrmPrintOperaciones.ConstruirSolicitud:
  TSolicitudInformeCaja;
begin
  Result.Empresa := edtEmpresa.Text;
  Result.Almacen := bedAlmacen.Text;
  Result.Caja := bedCaja.Text;
  Result.FechaDesde := dteDesde.Date;
  Result.FechaHasta := dteHasta.Date;
end;

end.
