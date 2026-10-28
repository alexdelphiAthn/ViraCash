{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraspasoSolicitudesHist                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Histórico de solicitudes de traspaso con ficha, artículos solicitados    }
{    y los traspasos de caja que se generaron para atender cada solicitud.     }
{******************************************************************************}
unit inMtoTraspasoSolicitudesHist;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Actions,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit,
  cxNavigator, cxDBData, cxContainer, cxLabel, cxTextEdit, cxDBEdit,
  cxCheckBox, cxCalendar, cxMemo, cxCurrencyEdit, cxSplitter,
  cxButtons, cxDropDownEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxClasses, cxDBNavigator,
  dxDateRanges, dxCore, dxScrollbarAnnotations, dxSkinsCore,
  dxSkinsDefaultPainters, dxSkinsForm, dxBevel, dxShellDialogs,
  dxSkinBlue, dxSkinBasic, dxSkinBlack, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin,
  dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White,
  dxSkinOffice2016Colorful, dxSkinOffice2016Dark, dxSkinOffice2019Black,
  dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008,
  dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue,
  Vcl.AppEvnts, Vcl.ActnList,
  JvComponentBase, JvEnterTab,
  inMtoGen, inLibPermisosIntf, inLibFotos, inLibRegistroPantallas,
  inLibCajaPantallaInyeccion, inLibTraspasoTicketIntf,
  UniDataTraspasoSolicitudesHist;

type
  TfrmMtoTraspasoSolicitudesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinSERIE_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMP_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_EMPRESA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALM_DESTINO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_ALMACEN_DESTINO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMP_CONTRA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_EMPRESA_CONTRA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALM_ORIGEN_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_ALMACEN_ORIGEN_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_CAJA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPLEADO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_EMPLEADO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinMODO_PETICION_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinATENDIDA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinTIENE_TRASPASO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_TRASPASOS_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_LINEAS_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinLINEAS_ATENDIDAS_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinLINEAS_SERVIDAS_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinLINEAS_RECHAZADAS_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinLINEAS_PENDIENTES_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_PEDIDA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_SERVIDA_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_PENDIENTE_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinMOTIVOS_RECHAZO_TRSOL: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_TRSOL: TcxGridDBColumn;
    pnlCabeceraSolicitud: TPanel;
    lblSolicitud: TcxLabel;
    txtSerieSolicitud: TcxDBTextEdit;
    txtNumeroSolicitud: TcxDBTextEdit;
    lblAltaSolicitud: TcxLabel;
    datAltaSolicitud: TcxDBDateEdit;
    lblEstadoSolicitud: TcxLabel;
    txtEstadoSolicitud: TcxDBTextEdit;
    txtAtendidaSolicitud: TcxDBTextEdit;
    chkTraspasoSolicitud: TcxDBCheckBox;
    lblEmpresaSolicitante: TcxLabel;
    txtEmpresaSolicitante: TcxDBTextEdit;
    txtNombreEmpresaSolicitante: TcxDBTextEdit;
    lblAlmacenSolicitante: TcxLabel;
    txtAlmacenSolicitante: TcxDBTextEdit;
    txtNombreAlmacenSolicitante: TcxDBTextEdit;
    lblEmpresaSolicitada: TcxLabel;
    txtEmpresaSolicitada: TcxDBTextEdit;
    txtNombreEmpresaSolicitada: TcxDBTextEdit;
    lblAlmacenSolicitado: TcxLabel;
    txtAlmacenSolicitado: TcxDBTextEdit;
    txtNombreAlmacenSolicitado: TcxDBTextEdit;
    lblCajaSolicitud: TcxLabel;
    txtCajaSolicitud: TcxDBTextEdit;
    txtNombreCajaSolicitud: TcxDBTextEdit;
    lblEmpleadoSolicitud: TcxLabel;
    txtEmpleadoSolicitud: TcxDBTextEdit;
    txtNombreEmpleadoSolicitud: TcxDBTextEdit;
    lblObservacionesSolicitud: TcxLabel;
    memObservacionesSolicitud: TcxDBMemo;
    lblMotivosRechazoSolicitud: TcxLabel;
    memMotivosRechazoSolicitud: TcxDBMemo;
    pcDetalleSolicitud: TcxPageControl;
    tsArticulosSolicitud: TcxTabSheet;
    cxgrdLineasSolicitud: TcxGrid;
    tvLineasSolicitud: TcxGridDBTableView;
    tvLineasLINEA_TRSOLLIN: TcxGridDBColumn;
    tvLineasCODIGO_ART_TRSOLLIN: TcxGridDBColumn;
    tvLineasCODIGO_UNIDAD_TRSOLLIN: TcxGridDBColumn;
    tvLineasDESCRIPCION_ART: TcxGridDBColumn;
    tvLineasCANTIDAD_PEDIDA_TRSOLLIN: TcxGridDBColumn;
    tvLineasCANTIDAD_SERVIDA_TRSOLLIN: TcxGridDBColumn;
    tvLineasCANTIDAD_PENDIENTE_TRSOLLIN: TcxGridDBColumn;
    tvLineasESATENDIDA_TRSOLLIN: TcxGridDBColumn;
    tvLineasMOTIVO_RECHAZO_TRSOLLIN: TcxGridDBColumn;
    tvLineasINSTANTE_MODIF: TcxGridDBColumn;
    lvLineasSolicitud: TcxGridLevel;
    splFotoArticuloSolicitud: TcxSplitter;
    pnlFotoArticuloSolicitud: TPanel;
    imgFotoArticuloSolicitud: TImage;
    tsTraspasoRealizado: TcxTabSheet;
    pnlTraspasosRealizados: TPanel;
    cxgrdTraspasosRealizados: TcxGrid;
    tvTraspasosRealizados: TcxGridDBTableView;
    tvTraspasosNUMERO_OPERACION_OPCAJA: TcxGridDBColumn;
    tvTraspasosFECHA_OPERACION_OPCAJA: TcxGridDBColumn;
    tvTraspasosCODIGO_EMP_OPCAJA: TcxGridDBColumn;
    tvTraspasosCODIGO_ALM_OPCAJA: TcxGridDBColumn;
    tvTraspasosCODIGO_EMP_CONTRA_OPCAJA: TcxGridDBColumn;
    tvTraspasosCODIGO_ALM_CONTRA_OPCAJA: TcxGridDBColumn;
    tvTraspasosCODIGO_CAJA_OPCAJA: TcxGridDBColumn;
    tvTraspasosCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn;
    tvTraspasosNOMBRE_EMPLEADO_OPCAJA: TcxGridDBColumn;
    tvTraspasosDOCUMENTO_OPCAJA: TcxGridDBColumn;
    tvTraspasosIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn;
    lvTraspasosRealizados: TcxGridLevel;
    splMovimientosTraspaso: TcxSplitter;
    pnlMovimientosTraspaso: TPanel;
    cxgrdMovimientosTraspaso: TcxGrid;
    tvMovimientosTraspaso: TcxGridDBTableView;
    tvMovimientosNUMERO_MOV: TcxGridDBColumn;
    tvMovimientosFECHA_MOV: TcxGridDBColumn;
    tvMovimientosLINEA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALM_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALM_CONTRA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ART_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_UNIDAD_MOV: TcxGridDBColumn;
    tvMovimientosDESCRIPCION_ART: TcxGridDBColumn;
    tvMovimientosTIPO_MOV: TcxGridDBColumn;
    tvMovimientosCANTIDAD_MOV: TcxGridDBColumn;
    tvMovimientosPRECIO_MEDIO_MOV: TcxGridDBColumn;
    tvMovimientosTOTAL_COSTE_MOV: TcxGridDBColumn;
    lvMovimientosTraspaso: TcxGridLevel;
    btnListadoSolicitudes: TcxButton;
    btnImprimirDuplicadoSolicitud: TcxButton;
    pnlFiltroModoPeticion: TPanel;
    lblFiltroModoPeticion: TcxLabel;
    cboFiltroModoPeticion: TcxComboBox;
    alSolicitudesTraspasoHist: TActionList;
    actImprimirDuplicadoSolicitud: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnListadoSolicitudesClick(Sender: TObject);
    procedure cboFiltroModoPeticionPropertiesChange(Sender: TObject);
    procedure actImprimirDuplicadoSolicitudExecute(Sender: TObject);
    procedure actImprimirDuplicadoSolicitudUpdate(Sender: TObject);
  private
    dmmTraspasoSolicitudesHist: TdmTraspasoSolicitudesHist;
    FFotoArticulo: TFotoEmbebida;
    FDependenciasInforme: TDependenciasInformeCaja;
    FRepositorioTraspasoTicket: IRepositorioTraspasoTicket;
    FPuedeModificar: Boolean;
    FAnteriorCambioTraspasos: TDataChangeEvent;
    procedure AsegurarDataModule;
    procedure ConfigurarEdicion;
    procedure ConfigurarFuentesDetalle;
    procedure AplicarFiltroModoPeticion;
    function DependenciasInformeDisponibles: Boolean;
    function PuedeImprimirDuplicadoSolicitud: Boolean;
    procedure ActualizarVisibilidadTraspaso;
    procedure TraspasosDataChange(Sender: TObject; Field: TField);
    procedure EditarSolicitudExecute(Sender: TObject);
    procedure EditarSolicitudUpdate(Sender: TObject);
    procedure GrabarSolicitudExecute(Sender: TObject);
    procedure GrabarSolicitudUpdate(Sender: TObject);
  public
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion;
      const ADependencias: TDependenciasInformeCaja;
      const ARepositorioTraspasoTicket:
        IRepositorioTraspasoTicket); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    procedure AplicarEtiquetas; override;
    procedure AplicarTraduccionActual; override;
    procedure TrasErrorPrecargaAsync(const AError: string); override;
  end;

implementation

uses
  inMtoModalImpTraspasoSolicitudes, inLibTraspasoTicket, inLibMensajesVcl,
  inLibMsgCaja, inLibDevExp;

{$R *.dfm}

constructor TfrmMtoTraspasoSolicitudesHist.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasInformeCaja;
  const ARepositorioTraspasoTicket: IRepositorioTraspasoTicket);
begin
  ADependencias.Validar;
  ValidarDependenciaCaja(
    ARepositorioTraspasoTicket,
    'ticket de solicitudes de traspaso');
  FDependenciasInforme := ADependencias;
  FRepositorioTraspasoTicket := ARepositorioTraspasoTicket;
  inherited Create(AOwner, APermisos);
end;

procedure TfrmMtoTraspasoSolicitudesHist.
  actImprimirDuplicadoSolicitudExecute(Sender: TObject);
var
  Datos: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if PuedeImprimirDuplicadoSolicitud then
  begin
    Datos := dsTablaG.DataSet;
    sNumero := Trim(Datos.FieldByName('NUMERO_TRSOL').AsString);
    sSerie := Trim(Datos.FieldByName('SERIE_TRSOL').AsString);
    if (sNumero <> '') and (sSerie <> '') then
    begin
      Screen.Cursor := crHourGlass;
      try
        TTraspasoTicket.ImprimirSolicitud(
          PreviewTicket,
          FRepositorioTraspasoTicket,
          sNumero,
          sSerie,
          ParametrosCaja.ImpresoraCaja,
          True);
      finally
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TfrmMtoTraspasoSolicitudesHist.
  actImprimirDuplicadoSolicitudUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := PuedeImprimirDuplicadoSolicitud;
end;

procedure TfrmMtoTraspasoSolicitudesHist.AsegurarDataModule;
begin
  if not Assigned(tdmDataModule) then
  begin
    dmmTraspasoSolicitudesHist :=
      TdmTraspasoSolicitudesHist.Create(Self);
    tdmDataModule := dmmTraspasoSolicitudesHist;
    dmmTraspasoSolicitudesHist.CurrentForm := Self;
    // FZ-ISSUE-536: el catálogo no resuelve el data module de esta pantalla
    // y la base no crea su conexión: se pide aquí antes de usarla.
    AsegurarConexionTrabajo;
    dmmTraspasoSolicitudesHist.ReasignarConexion(ConexionTrabajo);
    dsTablaG.DataSet := dmmTraspasoSolicitudesHist.unqryTablaG;
    dmmTraspasoSolicitudesHist.AsignarMaestroCabecera(dsTablaG);
  end
  else
    dmmTraspasoSolicitudesHist :=
      tdmDataModule as TdmTraspasoSolicitudesHist;
end;

procedure TfrmMtoTraspasoSolicitudesHist.ConfigurarEdicion;
begin
  FPuedeModificar := IdentidadSesion.EsAdministrador and
    PuedeAccionMto(apmModificar);
  dmmTraspasoSolicitudesHist.ConfigurarEdicion(FPuedeModificar);
  txtEmpleadoSolicitud.Properties.ReadOnly := not FPuedeModificar;
  memObservacionesSolicitud.Properties.ReadOnly := not FPuedeModificar;
  cxGrdDBTabPrin.OptionsData.Appending := False;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Edit.Visible := FPuedeModificar;
  nvNavegador.Buttons.Post.Visible := FPuedeModificar;
  nvNavegador.Buttons.Cancel.Visible := FPuedeModificar;
  btnGrabar.Visible := FPuedeModificar;
  btnCancelar.Visible := FPuedeModificar;
  actInsertarRegistro.ShortCut := 0;
  actInsertarRegistro.OnExecute := nil;
  actInsertarRegistro.OnUpdate := nil;
  actInsertarRegistro.Enabled := False;
  actEliminarRegistro.ShortCut := 0;
  actEliminarRegistro.OnExecute := nil;
  actEliminarRegistro.OnUpdate := nil;
  actEliminarRegistro.Enabled := False;
  actEditarRegistro.OnExecute := EditarSolicitudExecute;
  actEditarRegistro.OnUpdate := EditarSolicitudUpdate;
  actGrabarRegistro.OnExecute := GrabarSolicitudExecute;
  actGrabarRegistro.OnUpdate := GrabarSolicitudUpdate;
end;

procedure TfrmMtoTraspasoSolicitudesHist.ConfigurarFuentesDetalle;
begin
  tvLineasSolicitud.DataController.DataSource :=
    dmmTraspasoSolicitudesHist.dsLineas;
  tvTraspasosRealizados.DataController.DataSource :=
    dmmTraspasoSolicitudesHist.dsTraspasos;
  tvMovimientosTraspaso.DataController.DataSource :=
    dmmTraspasoSolicitudesHist.dsMovimientos;
  FAnteriorCambioTraspasos :=
    dmmTraspasoSolicitudesHist.dsTraspasos.OnDataChange;
  dmmTraspasoSolicitudesHist.dsTraspasos.OnDataChange :=
    TraspasosDataChange;
end;

procedure TfrmMtoTraspasoSolicitudesHist.AplicarFiltroModoPeticion;
const
  ModosFiltro: array[0..5] of string = (
    '',
    'PENDIENTE',
    'AUTO',
    'ATENDIDA',
    'RECHAZADA PARCIAL',
    'RECHAZADA TOTAL');
var
  Datos: TDataSet;
  Indice: Integer;
begin
  Datos := dsTablaG.DataSet;
  Indice := cboFiltroModoPeticion.ItemIndex;
  if Assigned(Datos) and Datos.Active and
     (Indice >= Low(ModosFiltro)) and
     (Indice <= High(ModosFiltro)) then
  begin
    Datos.Filtered := False;
    Datos.Filter := '';
    if ModosFiltro[Indice] <> '' then
    begin
      Datos.Filter := Format(
        'MODO_PETICION_TRSOL = ''%s''',
        [ModosFiltro[Indice]]);
      Datos.Filtered := True;
    end;
  end;
end;

procedure TfrmMtoTraspasoSolicitudesHist.
  cboFiltroModoPeticionPropertiesChange(Sender: TObject);
begin
  AplicarFiltroModoPeticion;
end;

function TfrmMtoTraspasoSolicitudesHist.
  DependenciasInformeDisponibles: Boolean;
begin
  Result := Assigned(FDependenciasInforme.Repositorio) and
    Assigned(FDependenciasInforme.CajasDefecto);
end;

function TfrmMtoTraspasoSolicitudesHist.
  PuedeImprimirDuplicadoSolicitud: Boolean;
begin
  Result := PuedeImprimir and Assigned(FRepositorioTraspasoTicket) and
    Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty and (dsTablaG.State = dsBrowse);
end;

procedure TfrmMtoTraspasoSolicitudesHist.CrearTablaPrincipal;
begin
  inherited;
  AsegurarDataModule;
  pkFieldName := 'NUMERO_TRSOL;SERIE_TRSOL';
  tsFicha.TabVisible := True;
  tsPerfil.TabVisible := False;
  ConfigurarFuentesDetalle;
  ConfigurarEdicion;
end;

procedure TfrmMtoTraspasoSolicitudesHist.AplicarEtiquetas;
begin
  inherited;
  NumerarPestanasAtajo(pcDetalleSolicitud);
end;

procedure TfrmMtoTraspasoSolicitudesHist.AplicarTraduccionActual;
var
  Indice: Integer;
  Evento: TNotifyEvent;
begin
  inherited;
  if Assigned(cboFiltroModoPeticion) and
     (cboFiltroModoPeticion.Properties.Items.Count = 6) then
  begin
    Indice := cboFiltroModoPeticion.ItemIndex;
    Evento := cboFiltroModoPeticion.Properties.OnChange;
    cboFiltroModoPeticion.Properties.OnChange := nil;
    try
      cboFiltroModoPeticion.Properties.Items[0] :=
        SCaptionTodosModosSolicitudTraspaso;
      cboFiltroModoPeticion.Properties.Items[1] :=
        SCaptionModoSolicitudPendiente;
      cboFiltroModoPeticion.Properties.Items[2] :=
        SCaptionModoSolicitudAuto;
      cboFiltroModoPeticion.Properties.Items[3] :=
        SCaptionModoSolicitudAtendida;
      cboFiltroModoPeticion.Properties.Items[4] :=
        SCaptionModoSolicitudRechazadaParcial;
      cboFiltroModoPeticion.Properties.Items[5] :=
        SCaptionModoSolicitudRechazadaTotal;
      cboFiltroModoPeticion.ItemIndex := Indice;
    finally
      cboFiltroModoPeticion.Properties.OnChange := Evento;
    end;
  end;
end;

procedure TfrmMtoTraspasoSolicitudesHist.FormCreate(Sender: TObject);
begin
  inherited;
  AplicarTraduccionActual;
  cboFiltroModoPeticion.ItemIndex := 0;
  AplicarFiltroModoPeticion;
  actImprimirDuplicadoSolicitud.Visible := PuedeImprimir;
  btnListadoSolicitudes.Visible :=
    (PuedeImprimir or PuedeExportar) and
    DependenciasInformeDisponibles;
  FFotoArticulo := TFotoEmbebida.Create(
    FotosArticulos,
    imgFotoArticuloSolicitud,
    dmmTraspasoSolicitudesHist.dsLineas);
  ActualizarVisibilidadTraspaso;
end;

procedure TfrmMtoTraspasoSolicitudesHist.btnListadoSolicitudesClick(
  Sender: TObject);
var
  oInforme: TfrmPrintTraspasoSolicitudes;
begin
  if (PuedeImprimir or PuedeExportar) and
     DependenciasInformeDisponibles then
  begin
    oInforme := TfrmPrintTraspasoSolicitudes.Create(
      Application,
      FDependenciasInforme,
      PuedeImprimir,
      PuedeExportar);
    try
      oInforme.ShowModal;
    finally
      FreeAndNil(oInforme);
    end;
  end;
end;

procedure TfrmMtoTraspasoSolicitudesHist.FormDestroy(Sender: TObject);
begin
  if Assigned(dmmTraspasoSolicitudesHist) and
     Assigned(dmmTraspasoSolicitudesHist.dsTraspasos) then
  begin
    dmmTraspasoSolicitudesHist.dsTraspasos.OnDataChange :=
      FAnteriorCambioTraspasos;
  end;
  FreeAndNil(FFotoArticulo);
  FRepositorioTraspasoTicket := nil;
  inherited;
end;

// FZ-ISSUE-536: si falla la precarga, la rejilla vacía engaña al usuario
// (la base solo lo deja en el log).
procedure TfrmMtoTraspasoSolicitudesHist.TrasErrorPrecargaAsync(
  const AError: string);
begin
  inherited;
  ShowMessage_fza(Format(SErrorCargaHistoricoSolicitudesTraspaso,
    [AError]));
end;

procedure TfrmMtoTraspasoSolicitudesHist.ActualizarVisibilidadTraspaso;
var
  bHayTraspaso: Boolean;
begin
  bHayTraspaso :=
    Assigned(dmmTraspasoSolicitudesHist) and
    Assigned(dmmTraspasoSolicitudesHist.dsTraspasos.DataSet) and
    dmmTraspasoSolicitudesHist.dsTraspasos.DataSet.Active and
    not dmmTraspasoSolicitudesHist.dsTraspasos.DataSet.IsEmpty;
  tsTraspasoRealizado.TabVisible := bHayTraspaso;
  if (not bHayTraspaso) and
     (pcDetalleSolicitud.ActivePage = tsTraspasoRealizado) then
    pcDetalleSolicitud.ActivePage := tsArticulosSolicitud;
end;

procedure TfrmMtoTraspasoSolicitudesHist.TraspasosDataChange(
  Sender: TObject; Field: TField);
begin
  if Assigned(FAnteriorCambioTraspasos) then
    FAnteriorCambioTraspasos(Sender, Field);
  if Field = nil then
    ActualizarVisibilidadTraspaso;
end;

procedure TfrmMtoTraspasoSolicitudesHist.EditarSolicitudExecute(
  Sender: TObject);
begin
  if FPuedeModificar and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and not dsTablaG.DataSet.IsEmpty and
     (dsTablaG.State = dsBrowse) then
  begin
    dsTablaG.DataSet.Edit;
    pcPantalla.ActivePage := tsFicha;
    if txtEmpleadoSolicitud.CanFocus then
      txtEmpleadoSolicitud.SetFocus;
  end;
end;

procedure TfrmMtoTraspasoSolicitudesHist.EditarSolicitudUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled :=
    FPuedeModificar and Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and not dsTablaG.DataSet.IsEmpty and
    (dsTablaG.State = dsBrowse);
end;

procedure TfrmMtoTraspasoSolicitudesHist.GrabarSolicitudExecute(
  Sender: TObject);
begin
  if FPuedeModificar and Assigned(dsTablaG.DataSet) and
     (dsTablaG.State = dsEdit) then
  begin
    dsTablaG.DataSet.Post;
    dmmTraspasoSolicitudesHist.unqryTablaG.Refresh;
  end;
end;

procedure TfrmMtoTraspasoSolicitudesHist.GrabarSolicitudUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled :=
    FPuedeModificar and Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and (dsTablaG.State = dsEdit);
end;

initialization
  RegistrarPantalla(TfrmMtoTraspasoSolicitudesHist);

end.
