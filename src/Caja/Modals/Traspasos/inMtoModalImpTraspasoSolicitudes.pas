{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpTraspasoSolicitudes                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Informe de solicitudes de traspaso con cabecera, artículos, fotografía   }
{    y filtros de ubicación, fechas y estado.                                  }
{******************************************************************************}
unit inMtoModalImpTraspasoSolicitudes;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.DateUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus,
  Data.DB,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCalendar, cxLabel, cxButtons, cxClasses, cxLocalization, cxPC,
  cxCheckListBox, cxCheckBox,
  dxSkinsForm, dxCore,
  frxClass, frxDBSet, frxDesgn, frxExportXLSX,
  frxExportBaseDialog, frxExportPDF, frxSmartMemo, frLocalization,
  frLanguageSpanish, frxExportBaseImageSettingsDialog, frCoreClasses,
  JvComponentBase, JvEnterTab,
  System.Actions, Vcl.ActnList,
  inMtoModalGenImp, inLibInformesCajaPersistenciaIntf,
  inLibCajaPantallaInyeccion, inLibResumenSeleccionesInforme;

type
  TfrmPrintTraspasoSolicitudes = class(TfrmPrint)
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblContexto: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    edtAlmacen: TcxTextEdit;
    lblCaja: TcxLabel;
    edtCaja: TcxTextEdit;
    pcOpciones: TcxPageControl;
    tsUbicaciones: TcxTabSheet;
    lblUbicaciones: TcxLabel;
    clbUbicaciones: TcxCheckListBox;
    btnMarcarUbicaciones: TcxButton;
    btnDesmarcarUbicaciones: TcxButton;
    tsEstados: TcxTabSheet;
    lblEstados: TcxLabel;
    clbEstados: TcxCheckListBox;
    btnMarcarEstados: TcxButton;
    btnDesmarcarEstados: TcxButton;
    dsSolicitudesPrint: TDataSource;
    fxdsSolicitudes: TfrxDBDataset;
    procedure btnMarcarUbicacionesClick(Sender: TObject);
    procedure btnDesmarcarUbicacionesClick(Sender: TObject);
    procedure btnMarcarEstadosClick(Sender: TObject);
    procedure btnDesmarcarEstadosClick(Sender: TObject);
    procedure btnEditarSolicitudesClick(Sender: TObject);
    procedure btnExcelNativoClick(Sender: TObject);
  private
    FAlmacenesUbicacion: TStringList;
    FCajasUbicacion: TStringList;
    FEmpresasUbicacion: TStringList;
    FInicializado: Boolean;
    FPuedeExportar: Boolean;
    FPuedeImprimir: Boolean;
    FRepositorio: IRepositorioInformesCaja;
    FResultado: IResultadoInformeCaja;
    FDatos: TDataSet;
    FRestringido: Boolean;
    procedure AsegurarUbicacionSeleccionada;
    procedure CargarEstados;
    procedure CargarUbicaciones;
    function ConstruirSolicitud: TSolicitudTraspasosInformeCaja;
    function NumeroEstadosMarcados: Integer;
    function NumeroUbicacionesMarcadas: Integer;
    procedure PrecargarFotosArticulos;
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
    destructor Destroy; override;
    procedure AfterReportLoaded; override;
    procedure preparar_consulta; override;
  end;

implementation

uses
  inLibFiltroUsuario, inLibTraspasoSolicitudesExcel,
  inMtoPreviewExcel, inLibResumenSeleccionesCaja;

{$R *.dfm}

resourcestring
  SSeleccioneEstadoSolicitud =
    'Seleccione al menos un estado para generar el listado.';
  SFormatoNombreArchivoSolicitudesTraspaso =
    'Solicitudes_traspaso_%s';

constructor TfrmPrintTraspasoSolicitudes.Create(
  AOwner: TComponent;
  const ADependencias: TDependenciasInformeCaja;
  APuedeImprimir, APuedeExportar: Boolean);
begin
  ADependencias.Validar;
  FRepositorio := ADependencias.Repositorio;
  FPuedeImprimir := APuedeImprimir;
  FPuedeExportar := APuedeExportar;
  inherited Create(AOwner);
  frxpdfxprtPedWeb.PrintOptimized := False;
  frxpdfxprtPedWeb.PictureDPI := 300;
  frxpdfxprtPedWeb.Quality := 100;
end;

destructor TfrmPrintTraspasoSolicitudes.Destroy;
begin
  if Assigned(FotosArticulos) then
    FotosArticulos.LimpiarPrecargaFotos;
  FreeAndNil(FEmpresasUbicacion);
  FreeAndNil(FAlmacenesUbicacion);
  FreeAndNil(FCajasUbicacion);
  inherited;
end;

procedure TfrmPrintTraspasoSolicitudes.AsegurarUbicacionSeleccionada;
var
  iUbicacion: Integer;
begin
  if not FRestringido then
  begin
    if NumeroUbicacionesMarcadas = 0 then
    begin
      for iUbicacion := 0 to clbUbicaciones.Items.Count - 1 do
      begin
        if SameText(
             FEmpresasUbicacion[iUbicacion],
             UbicacionSesion.Empresa) and
           SameText(
             FAlmacenesUbicacion[iUbicacion],
             UbicacionSesion.Almacen) and
           SameText(
             FCajasUbicacion[iUbicacion],
             UbicacionSesion.Caja) then
          clbUbicaciones.Items[iUbicacion].State := cbsChecked;
      end;
    end;
    if (NumeroUbicacionesMarcadas = 0) and
       (clbUbicaciones.Items.Count > 0) then
      clbUbicaciones.Items[0].State := cbsChecked;
  end;
end;

procedure TfrmPrintTraspasoSolicitudes.AfterReportLoaded;
begin
  inherited;
  if not Assigned(FotosArticulos) then
    frxrprt1.OnBeforePrint := nil;
  fxdsSolicitudes.DataSet := FDatos;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsSolicitudes);
end;

procedure TfrmPrintTraspasoSolicitudes.btnEditarSolicitudesClick(
  Sender: TObject);
begin
  preparar_consulta;
  inherited btnEditarClick(Sender);
end;

procedure TfrmPrintTraspasoSolicitudes.btnDesmarcarEstadosClick(
  Sender: TObject);
var
  iEstado: Integer;
begin
  for iEstado := 0 to clbEstados.Items.Count - 1 do
    clbEstados.Items[iEstado].State := cbsUnchecked;
end;

procedure TfrmPrintTraspasoSolicitudes.btnDesmarcarUbicacionesClick(
  Sender: TObject);
var
  iUbicacion: Integer;
begin
  for iUbicacion := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[iUbicacion].State := cbsUnchecked;
end;

procedure TfrmPrintTraspasoSolicitudes.btnExcelNativoClick(
  Sender: TObject);
var
  oPreview: TfrmMtoPreviewExcel;
begin
  if FPuedeExportar then
  begin
    IniciarMedicionDatos;
    preparar_consulta;
    PausarMedicionDatos;
    Self.Hide;
    try
      oPreview := TfrmMtoPreviewExcel.Create(Self);
      try
        oPreview.PopupParent := Self;
        oPreview.DialogoGuardar.InitialDir :=
          ParametrosApp.GetPath('appDirExcel');
        oPreview.DialogoGuardar.FileName := Format(
          SFormatoNombreArchivoSolicitudesTraspaso,
          [FormatDateTime('yyyymmdd_hhnnss', Now)]);
        Screen.Cursor := crHourGlass;
        try
          ExportarSolicitudesTraspasoExcel(
            oPreview.dxSpreadSheet1,
            FDatos,
            FotosArticulos,
            Trunc(dteDesde.Date),
            Trunc(dteHasta.Date),
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

procedure TfrmPrintTraspasoSolicitudes.btnMarcarEstadosClick(
  Sender: TObject);
var
  iEstado: Integer;
begin
  for iEstado := 0 to clbEstados.Items.Count - 1 do
    clbEstados.Items[iEstado].State := cbsChecked;
end;

procedure TfrmPrintTraspasoSolicitudes.btnMarcarUbicacionesClick(
  Sender: TObject);
var
  iUbicacion: Integer;
begin
  for iUbicacion := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[iUbicacion].State := cbsChecked;
end;

procedure TfrmPrintTraspasoSolicitudes.CargarEstados;
var
  aEstados: TEstadosSolicitudTraspasoCaja;
  item: TcxCheckListBoxItem;
  sEstado: string;
begin
  clbEstados.Items.BeginUpdate;
  try
    clbEstados.Items.Clear;
    aEstados := FRepositorio.ListarEstadosSolicitudesTraspaso;
    for sEstado in aEstados do
    begin
      item := clbEstados.Items.Add;
      item.Text := sEstado;
      item.State := cbsChecked;
    end;
  finally
    clbEstados.Items.EndUpdate;
  end;
end;

procedure TfrmPrintTraspasoSolicitudes.CargarUbicaciones;
var
  aUbicaciones: TUbicacionesInformeCaja;
  item: TcxCheckListBoxItem;
  oUbicacion: TUbicacionInformeCaja;
begin
  if FEmpresasUbicacion = nil then
    FEmpresasUbicacion := TStringList.Create;
  if FAlmacenesUbicacion = nil then
    FAlmacenesUbicacion := TStringList.Create;
  if FCajasUbicacion = nil then
    FCajasUbicacion := TStringList.Create;
  clbUbicaciones.Items.BeginUpdate;
  try
    clbUbicaciones.Items.Clear;
    FEmpresasUbicacion.Clear;
    FAlmacenesUbicacion.Clear;
    FCajasUbicacion.Clear;
    aUbicaciones := FRepositorio.ListarUbicaciones;
    for oUbicacion in aUbicaciones do
    begin
      item := clbUbicaciones.Items.Add;
      item.Text := Format(
        '%s - %s  |  %s - %s  |  %s - %s',
        [oUbicacion.Empresa, oUbicacion.NombreEmpresa,
         oUbicacion.Almacen, oUbicacion.NombreAlmacen,
         oUbicacion.Caja, oUbicacion.NombreCaja]);
      item.State := cbsUnchecked;
      if SameText(oUbicacion.Empresa, UbicacionSesion.Empresa) and
         SameText(oUbicacion.Almacen, UbicacionSesion.Almacen) and
         SameText(oUbicacion.Caja, UbicacionSesion.Caja) then
        item.State := cbsChecked;
      FEmpresasUbicacion.Add(oUbicacion.Empresa);
      FAlmacenesUbicacion.Add(oUbicacion.Almacen);
      FCajasUbicacion.Add(oUbicacion.Caja);
    end;
  finally
    clbUbicaciones.Items.EndUpdate;
  end;
  AsegurarUbicacionSeleccionada;
end;

procedure TfrmPrintTraspasoSolicitudes.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
var
  oEstados: TStringList;
  oSolicitud: TSolicitudTraspasosInformeCaja;
  sEstado: string;
begin
  inherited;
  // La misma solicitud que la consulta (ubicación de la sesión si no
  // hay ninguna marcada; sin estados = todos).
  oSolicitud := ConstruirSolicitud;
  AResumen.AnadirRangoFechas(
    lblFechas.Caption, oSolicitud.FechaDesde, oSolicitud.FechaHasta);
  AnadirUbicacionesInformeCaja(
    AResumen, tsUbicaciones.Caption, oSolicitud.Ubicaciones);
  oEstados := TStringList.Create;
  try
    for sEstado in oSolicitud.Estados do
      oEstados.Add(sEstado);
    AResumen.AnadirLista(tsEstados.Caption, oEstados);
  finally
    FreeAndNil(oEstados);
  end;
end;

function TfrmPrintTraspasoSolicitudes.ConstruirSolicitud:
  TSolicitudTraspasosInformeCaja;
var
  iEstado: Integer;
  iUbicacion: Integer;
begin
  Result.FechaDesde := Trunc(dteDesde.Date);
  Result.FechaHasta := Trunc(dteHasta.Date);
  SetLength(Result.Ubicaciones, 0);
  SetLength(Result.Estados, 0);
  if FRestringido or (NumeroUbicacionesMarcadas = 0) then
  begin
    SetLength(Result.Ubicaciones, 1);
    Result.Ubicaciones[0].Empresa := UbicacionSesion.Empresa;
    Result.Ubicaciones[0].Almacen := UbicacionSesion.Almacen;
    Result.Ubicaciones[0].Caja := UbicacionSesion.Caja;
  end
  else
  begin
    for iUbicacion := 0 to clbUbicaciones.Items.Count - 1 do
    begin
      if clbUbicaciones.Items[iUbicacion].State = cbsChecked then
      begin
        SetLength(
          Result.Ubicaciones,
          Length(Result.Ubicaciones) + 1);
        Result.Ubicaciones[High(Result.Ubicaciones)].Empresa :=
          FEmpresasUbicacion[iUbicacion];
        Result.Ubicaciones[High(Result.Ubicaciones)].Almacen :=
          FAlmacenesUbicacion[iUbicacion];
        Result.Ubicaciones[High(Result.Ubicaciones)].Caja :=
          FCajasUbicacion[iUbicacion];
      end;
    end;
  end;
  if (NumeroEstadosMarcados > 0) and
     (NumeroEstadosMarcados < clbEstados.Items.Count) then
  begin
    for iEstado := 0 to clbEstados.Items.Count - 1 do
    begin
      if clbEstados.Items[iEstado].State = cbsChecked then
      begin
        SetLength(Result.Estados, Length(Result.Estados) + 1);
        Result.Estados[High(Result.Estados)] :=
          clbEstados.Items[iEstado].Text;
      end;
    end;
  end;
end;

procedure TfrmPrintTraspasoSolicitudes.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    dteDesde.Date := EncodeDate(YearOf(Date), MonthOf(Date), 1);
    dteHasta.Date := Date;
    edtEmpresa.Text := UbicacionSesion.Empresa;
    edtAlmacen.Text := UbicacionSesion.Almacen;
    edtCaja.Text := UbicacionSesion.Caja;
    FRestringido := RestriccionEmpAlmCajaActiva(
      ContextoSesion,
      ParametrosApp);
    tsUbicaciones.TabVisible := not FRestringido;
    if FRestringido then
      pcOpciones.ActivePage := tsEstados
    else
    begin
      CargarUbicaciones;
      pcOpciones.ActivePage := tsUbicaciones;
    end;
    CargarEstados;
    btnVistaPreliminar.Visible := FPuedeImprimir;
    btnPDF.Visible := FPuedeImprimir;
    btnEditar.Visible := FPuedeImprimir;
    btnImprimir.Visible := FPuedeImprimir;
    btnExcel.Visible := FPuedeExportar;
    FInicializado := True;
  end;
end;

function TfrmPrintTraspasoSolicitudes.NumeroEstadosMarcados: Integer;
var
  iEstado: Integer;
begin
  Result := 0;
  for iEstado := 0 to clbEstados.Items.Count - 1 do
  begin
    if clbEstados.Items[iEstado].State = cbsChecked then
      Inc(Result);
  end;
end;

function TfrmPrintTraspasoSolicitudes.NumeroUbicacionesMarcadas:
  Integer;
var
  iUbicacion: Integer;
begin
  Result := 0;
  for iUbicacion := 0 to clbUbicaciones.Items.Count - 1 do
  begin
    if clbUbicaciones.Items[iUbicacion].State = cbsChecked then
      Inc(Result);
  end;
end;

procedure TfrmPrintTraspasoSolicitudes.PrecargarFotosArticulos;
var
  slArticulos: TStringList;
begin
  if Assigned(FotosArticulos) then
  begin
    FotosArticulos.LimpiarPrecargaFotos;
    if Assigned(FDatos) and FDatos.Active and not FDatos.IsEmpty then
    begin
      slArticulos := TStringList.Create;
      try
        slArticulos.Sorted := True;
        slArticulos.Duplicates := dupIgnore;
        FDatos.DisableControls;
        try
          FDatos.First;
          while not FDatos.Eof do
          begin
            slArticulos.Add(
              FDatos.FieldByName('CODIGO_ART').AsString);
            FDatos.Next;
          end;
          FDatos.First;
        finally
          FDatos.EnableControls;
        end;
        FotosArticulos.PrecargarFotosLote(slArticulos.ToStringArray);
      finally
        FreeAndNil(slArticulos);
      end;
    end;
  end;
end;

procedure TfrmPrintTraspasoSolicitudes.preparar_consulta;
begin
  inherited;
  if dteDesde.Date <= 0 then
    dteDesde.Date := EncodeDate(YearOf(Date), MonthOf(Date), 1);
  if dteHasta.Date <= 0 then
    dteHasta.Date := Date;
  if dteHasta.Date < dteDesde.Date then
    dteHasta.Date := dteDesde.Date;
  if (clbEstados.Items.Count > 0) and
     (NumeroEstadosMarcados = 0) then
    raise EArgumentException.Create(SSeleccioneEstadoSolicitud);
  AsegurarUbicacionSeleccionada;
  dsSolicitudesPrint.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorio.ConsultarSolicitudesTraspaso(
    ConstruirSolicitud);
  FDatos := FResultado.DataSet;
  dsSolicitudesPrint.DataSet := FDatos;
  fxdsSolicitudes.DataSet := FDatos;
  fxdsSolicitudes.UpdateBounds;
  PrecargarFotosArticulos;
end;

end.
