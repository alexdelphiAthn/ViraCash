{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaPagosHist                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de pagos de caja.                                               }
{    Consulta de pagos asociados a operaciones del TPV.                        }
{******************************************************************************}
unit inMtoCajaPagosHist;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls,
  inLibPerfilesUsuarioIntf, inLibCajaPagosHistPersistenciaIntf,
  inLibCajaPantallaHistoricosIntf, inLibPermisosIntf,
  inLibCajaPantallaInyeccion,
  cxCheckBox, cxCalendar,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxDBEdit, cxCurrencyEdit, UniDataCajaPagosHist,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoCajaPagosHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPRESA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_OPERACION_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_LINEA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_FORMAP: TcxGridDBColumn;
    colTipoOperacion: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_DIVISA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_FORMAP: TcxGridDBColumn;
    lblFpCodigo: TcxLabel;
    edtFpCodigo: TcxDBTextEdit;
    lblFpDescripcion: TcxLabel;
    edtFpDescripcion: TcxDBTextEdit;
    lblReferencia: TcxLabel;
    edtReferencia: TcxDBTextEdit;
    lblFechaPago: TcxLabel;
    edtFechaPago: TcxDBTextEdit;
    lblEntregado: TcxLabel;
    edtEntregado: TcxDBCurrencyEdit;
    lblCambio: TcxLabel;
    edtCambio: TcxDBCurrencyEdit;
    lblDivisa: TcxLabel;
    edtDivisa: TcxDBTextEdit;
    lblImporteDivisa: TcxLabel;
    edtImporteDivisa: TcxDBTextEdit;
    lblFactor: TcxLabel;
    edtFactor: TcxDBTextEdit;
    lblRedBlockchain: TcxLabel;
    edtRedBlockchain: TcxDBTextEdit;
    lblObservaciones: TcxLabel;
    edtObservaciones: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    edtUsuarioAlta: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    edtInstanteAlta: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    edtInstanteModif: TcxDBTextEdit;
    tsFichaPago: TcxTabSheet;
    lblOpNumero: TcxLabel;
    edtOpNumero: TcxDBTextEdit;
    lblOpSerie: TcxLabel;
    edtOpSerie: TcxDBTextEdit;
    lblOpTipo: TcxLabel;
    edtOpTipo: TcxDBTextEdit;
    lblOpEmpleado: TcxLabel;
    edtOpEmpleado: TcxDBTextEdit;
    lblOpCliente: TcxLabel;
    edtOpCliente: TcxDBTextEdit;
    lblOpImporte: TcxLabel;
    edtOpImporte: TcxDBCurrencyEdit;
    lblOpArqueo: TcxLabel;
    edtOpArqueo: TcxDBTextEdit;
    lblOpSerieOrigen: TcxLabel;
    edtOpSerieOrigen: TcxDBTextEdit;
    lblOpNumeroOrigen: TcxLabel;
    edtOpNumeroOrigen: TcxDBTextEdit;
    lblOpMotivo: TcxLabel;
    edtOpMotivo: TcxDBTextEdit;
    btnIrAOperacion: TcxButton;
    tsFichaOperacion: TcxTabSheet;
    colFacSerie: TcxGridDBColumn;
    colFacNumero: TcxGridDBColumn;
    colFacFecha: TcxGridDBColumn;
    colFacTipo: TcxGridDBColumn;
    colFacFase: TcxGridDBColumn;
    colFacConsolidada: TcxGridDBColumn;
    colFacCliente: TcxGridDBColumn;
    colFacBases: TcxGridDBColumn;
    colFacImpuestos: TcxGridDBColumn;
    colFacTotal: TcxGridDBColumn;
    colLinNumero: TcxGridDBColumn;
    colLinArticulo: TcxGridDBColumn;
    colLinDescripcion: TcxGridDBColumn;
    colLinVariacion: TcxGridDBColumn;
    colLinTipoCant: TcxGridDBColumn;
    colLinCantidad: TcxGridDBColumn;
    colLinPrecio: TcxGridDBColumn;
    colLinPrecioIva: TcxGridDBColumn;
    colLinTotal: TcxGridDBColumn;
    cxgrdFichaFactura: TcxGrid;
    lvlFichaFactura: TcxGridLevel;
    lvlFichaFacturaLineas: TcxGridLevel;
    tvFichaFactura: TcxGridDBTableView;
    tvFichaFacturaLineas: TcxGridDBTableView;
    pnlFichaFacturaBotones: TPanel;
    btnIrAFactura: TcxButton;
    tsFichaFactura: TcxTabSheet;
    pcFichaDetalle: TcxPageControl;
    pnlFichaCabecera: TPanel;
    cxGrdDBTabPrinRED_BLOCKCHAIN: TcxGridDBColumn;
    cxGrdDBTabPrinFACTOR_CAMBIO_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_DIVISA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_ENTREGADO_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_CAMBIO_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinREFERENCIA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    pnlFiltrosCaja: TPanel;
    btnToggleFiltrosCaja: TcxButton;
    pnlContFiltrosCaja: TPanel;
    lblDesde: TcxLabel;
    lblHasta: TcxLabel;
    lblAlmacenCarga: TcxLabel;
    lblCajaCarga: TcxLabel;
    dteDesde: TcxDateEdit;
    dteHasta: TcxDateEdit;
    edtAlmacen: TcxTextEdit;
    edtCaja: TcxTextEdit;
    colNetoPago: TcxGridDBColumn;
    btnCargarPagos: TcxButton;
    btnGuardarPrecargaCaja: TcxButton;
    procedure btnImprimirInformeClick(Sender: TObject);
    procedure btnToggleFiltrosCajaClick(Sender: TObject);
    procedure btnCargarPagosClick(Sender: TObject);
    procedure btnGuardarPrecargaCajaClick(Sender: TObject);
    procedure btnIrAOperacionClick(Sender: TObject);
    procedure btnIrAFacturaClick(Sender: TObject);
    procedure pcFichaDetalleChange(Sender: TObject);
  private
    dmmCajaPagosHist: TdmCajaPagosHist;
    FCargandoPagos: Boolean;
    FRepositorioPersistencia: IRepositorioCajaPagosHist;
    FGrabadorPerfiles: IGrabadorPerfilesHistoricoCaja;
    FDependenciasInyeccion: TDependenciasPagosHistoricosCaja;
    procedure LeerFiltrosPerfil;
    function ObtenerFiltros: TFiltrosCajaPagosHist;
    function FiltrosSesion: TFiltrosCajaPagosHist;
    procedure AplicarFiltrosPagos;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasPagosHistoricosCaja); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    function CloseQuery: Boolean; override;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin, inLibUser,
  inMtoModalGenImpSave, inMtoModalImpPagos, inLibFiltroUsuario,
  inLibMsgCaja, inLibMsgComun, inLibShowMto, System.Threading,
  inLibVentanaEspera;

{$R *.dfm}

resourcestring
  SCargandoPagosHistoricos = 'Cargando pagos de caja...';
  SDescripcionGuardarPrecargaPagosCaja =
    'Guardar precarga';

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaPagosHist }

constructor TfrmMtoCajaPagosHist.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasPagosHistoricosCaja);
begin
  ADependencias.Validar;
  FDependenciasInyeccion := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoCajaPagosHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintPagos;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Informe A4 horizontal (FastReport) de los pagos de caja. El usuario
  // filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintPagos.Create(
    Application,
    FDependenciasInyeccion.Informe);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoCajaPagosHist.CrearTablaPrincipal;
var
  rFiltros: TFiltrosCajaPagosHist;
begin
  inherited;
  dmmCajaPagosHist := tdmDataModule as TdmCajaPagosHist;
  // Las consultas de la factura se crean en codigo, asi que el DFM
  // no puede apuntarlas: se enlazan aqui.
  dmmCajaPagosHist.PrepararConsultasFactura(dsTablaG);
  tvFichaFactura.DataController.DataSource :=
    dmmCajaPagosHist.dsFacturaPago;
  tvFichaFacturaLineas.DataController.DataSource :=
    dmmCajaPagosHist.dsLineasFacturaPago;
  FDependenciasInyeccion.Validar;
  FRepositorioPersistencia :=
    FDependenciasInyeccion.CrearPersistencia(dsTablaG.DataSet);
  FGrabadorPerfiles := FDependenciasInyeccion.CrearPerfiles();
  pkFieldName := 'CODIGO_EMP_PAGO;CODIGO_ALM_PAGO;CODIGO_CAJA_PAGO;' +
                 'SERIE_OPERACION_PAGO;NUMERO_OPERACION_PAGO;NUMERO_LINEA_PAGO';
  btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaExpandido;
  LeerFiltrosPerfil;
  rFiltros := FiltrosSesion;
  rFiltros.SinFilas := True;
  FRepositorioPersistencia.PrepararConsulta(rFiltros);
end;

procedure TfrmMtoCajaPagosHist.LeerFiltrosPerfil;
var
  dFecha: TDateTime;
  sAlmacen, sCaja: string;
begin
  dteDesde.Date := StartOfTheMonth(Date);
  dteHasta.Date := Date;
  if TryISO8601ToDate(GetPerfilValueDef(oPerfilDic, 'oFiltroDesde', ''),
    dFecha, False) then
    dteDesde.Date := DateOf(dFecha);
  if TryISO8601ToDate(GetPerfilValueDef(oPerfilDic, 'oFiltroHasta', ''),
    dFecha, False) then
    dteHasta.Date := DateOf(dFecha);
  sAlmacen := AlmacenRestringido(ContextoSesion, ParametrosApp);
  sCaja := CajaRestringida(ContextoSesion, ParametrosApp);
  edtAlmacen.Properties.ReadOnly := sAlmacen <> '';
  edtCaja.Properties.ReadOnly := sCaja <> '';
  if sAlmacen = '' then
    sAlmacen := GetPerfilValueDef(oPerfilDic, 'oFiltroAlmacen', '');
  if sCaja = '' then
    sCaja := GetPerfilValueDef(oPerfilDic, 'oFiltroCaja', '');
  edtAlmacen.Text := sAlmacen;
  edtCaja.Text := sCaja;
end;

procedure TfrmMtoCajaPagosHist.RecogerPerfilesParticulares(
  var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;

  procedure Guardar(const AClave, AValor: string);
  begin
    item.SubKey := AClave;
    item.Value := AValor;
    oList.Add(item);
  end;

begin
  item.UserGroup := sPermisos;
  item.KeyPerfil := Self.Name;
  if dteDesde.Date > 0 then
    Guardar('oFiltroDesde', DateToISO8601(dteDesde.Date, False));
  if dteHasta.Date > 0 then
    Guardar('oFiltroHasta', DateToISO8601(dteHasta.Date, False));
  if not edtAlmacen.Properties.ReadOnly then
    Guardar('oFiltroAlmacen', Trim(edtAlmacen.Text));
  if not edtCaja.Properties.ReadOnly then
    Guardar('oFiltroCaja', Trim(edtCaja.Text));
end;

function TfrmMtoCajaPagosHist.FiltrosSesion: TFiltrosCajaPagosHist;
begin
  Result := Default(TFiltrosCajaPagosHist);
  Result.Empresa := EmpresaRestringida(ContextoSesion, ParametrosApp);
  Result.Almacen := AlmacenRestringido(ContextoSesion, ParametrosApp);
  Result.Caja := CajaRestringida(ContextoSesion, ParametrosApp);
end;

function TfrmMtoCajaPagosHist.ObtenerFiltros: TFiltrosCajaPagosHist;
begin
  Result := FiltrosSesion;
  dteDesde.ValidateEdit(True);
  dteDesde.PostEditValue;
  dteHasta.ValidateEdit(True);
  dteHasta.PostEditValue;
  Result.Desde := DateOf(dteDesde.Date);
  Result.HastaExclusiva := DateOf(dteHasta.Date) + 1;
  if (Result.Desde <= 0) or (dteHasta.Date <= 0) then
    raise EcxEditValidationError.Create(SErrorFechaFiltroInformeNoValida);
  if Result.HastaExclusiva <= Result.Desde then
    raise EcxEditValidationError.Create(SErrorRangoFechasDocumentoNoValido);
  if Result.Almacen = '' then
    Result.Almacen := Trim(edtAlmacen.Text);
  if Result.Caja = '' then
    Result.Caja := Trim(edtCaja.Text);
end;

function TfrmMtoCajaPagosHist.CloseQuery: Boolean;
begin
  Result := not FCargandoPagos;
  if Result then
    Result := inherited CloseQuery;
end;

procedure TfrmMtoCajaPagosHist.AplicarFiltrosPagos;
var
  oDatos: TDataSet;
  oVentana: IVentanaEspera;
  oTarea: ITask;
  rFiltros: TFiltrosCajaPagosHist;
  Zona: TRect;
  sError: string;
begin
  oDatos := dsTablaG.DataSet;
  if Assigned(oDatos) and not FCargandoPagos then
  begin
    rFiltros := ObtenerFiltros;
    GetWindowRect(Handle, Zona);
    oVentana := CrearVentanaProcesoSegundoPlano(Zona, CurrentPPI, Caption);
    FCargandoPagos := True;
    oDatos.DisableControls;
    try
      FRepositorioPersistencia.PrepararConsulta(rFiltros);
      oVentana.Mostrar(SCargandoPagosHistoricos);
      oVentana.PermitirCancelar(True);
      oTarea := TTask.Run(
        procedure
        begin
          try
            FRepositorioPersistencia.AbrirConsulta;
          except
            on E: Exception do
              sError := E.Message;
          end;
        end);
      try
        EsperarTareaAtendiendoMensajes(oTarea,
          procedure
          begin
            if oVentana.Cancelado then
              FRepositorioPersistencia.CancelarConsulta;
          end);
      finally
        EsperarTareaAtendiendoMensajes(oTarea);
      end;
      oVentana.PermitirCancelar(False);
      if oVentana.Cancelado or (sError <> '') then
      begin
        rFiltros := FiltrosSesion;
        rFiltros.SinFilas := True;
        FRepositorioPersistencia.PrepararConsulta(rFiltros);
        if not oVentana.Cancelado then
          raise EDatabaseError.Create(sError);
      end;
    finally
      oDatos.EnableControls;
      FCargandoPagos := False;
      oVentana.Ocultar;
    end;
  end;
end;

procedure TfrmMtoCajaPagosHist.btnToggleFiltrosCajaClick(Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  pnlContFiltrosCaja.Visible := not pnlContFiltrosCaja.Visible;
  if pnlContFiltrosCaja.Visible then
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaExpandido;
  end
  else
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA;
    btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaContraido;
  end;
end;


procedure TfrmMtoCajaPagosHist.btnCargarPagosClick(Sender: TObject);
begin
  AplicarFiltrosPagos;
end;

procedure TfrmMtoCajaPagosHist.btnGuardarPrecargaCajaClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
  oList: TPerfilList;
begin
  sPermisos := '';
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text := Self.Name;
    formulario.edtDescripcion.Text :=
      SDescripcionGuardarPrecargaPagosCaja;
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
      sPermisos := formulario.cbbPermisos.Text;
  finally
    FreeAndNil(formulario);
  end;
  if sPermisos <> '' then
  begin
    Screen.Cursor := crHourGlass;
    oList := TPerfilList.Create;
    try
      RecogerPerfilesParticulares(oList, sPermisos);
      FGrabadorPerfiles.Grabar(oList);
    finally
      FreeAndNil(oList);
      Screen.Cursor := crDefault;
    end;
    ShowMessage_fza(SInfoPrecargaCajaGuardada);
  end;
end;

procedure TfrmMtoCajaPagosHist.PrepararBusquedaExterna(const ABusq: string);
begin
  FRepositorioPersistencia.PrepararConsulta(FiltrosSesion);
  inherited;
end;

procedure TfrmMtoCajaPagosHist.AplicarLayoutInstanciaBusqueda;
begin
  // Antes esta pantalla no tenia ficha y la instancia de busqueda se
  // quedaba en el listado. Ahora la tiene, asi que se comporta como
  // el resto: quien llega buscando un pago aterriza en su ficha.
  inherited;
  tsPerfil.TabVisible := False;
  // El panel de filtros de carga no aplica: el filtro ya viene dado.
  pnlFiltrosCaja.Visible := False;
end;

procedure TfrmMtoCajaPagosHist.pcFichaDetalleChange(Sender: TObject);
begin
  // La factura y sus lineas se leen al entrar en su pestana, no
  // antes: son dos consultas mas por cada pago que se visita.
  if (pcFichaDetalle.ActivePage = tsFichaFactura) and
     Assigned(dmmCajaPagosHist) then
  begin
    dmmCajaPagosHist.AsegurarFacturaPagoAbierta;
  end;
end;

procedure TfrmMtoCajaPagosHist.btnIrAOperacionClick(Sender: TObject);
var
  oPago: TDataSet;
  sClave: string;
begin
  // El historico de operaciones localiza por empresa, almacen, caja y
  // numero de operacion, en ese orden y separados por comas.
  oPago := dsTablaG.DataSet;
  sClave := '';
  if (oPago <> nil) and oPago.Active and (not oPago.IsEmpty) then
    sClave :=
      Trim(oPago.FieldByName('CODIGO_EMP_PAGO').AsString) + ',' +
      Trim(oPago.FieldByName('CODIGO_ALM_PAGO').AsString) + ',' +
      Trim(oPago.FieldByName('CODIGO_CAJA_PAGO').AsString) + ',' +
      Trim(oPago.FieldByName('NUMERO_OPERACION_PAGO').AsString);
  // Sin clave, ShowMto abre el listado sin situarse en ninguna fila.
  ShowMto(Self.Owner, 'CajaOperacionesHist', sClave);
end;

procedure TfrmMtoCajaPagosHist.btnIrAFacturaClick(Sender: TObject);
var
  oPago: TDataSet;
  sSerie: string;
  sNumero: string;
begin
  oPago := dsTablaG.DataSet;
  sSerie := '';
  sNumero := '';
  if (oPago <> nil) and oPago.Active and (not oPago.IsEmpty) then
  begin
    sSerie := Trim(oPago.FieldByName('SERIE_FAC_PAGO').AsString);
    sNumero := Trim(oPago.FieldByName('NUMERO_FAC_PAGO').AsString);
  end;
  // La pantalla de simplificadas espera numero y serie, en ese orden.
  if (sSerie <> '') and (sNumero <> '') then
    ShowMto(Self.Owner, 'FacturasSimplif', sNumero + ',' + sSerie)
  else
    ShowMto(Self.Owner, 'FacturasSimplif');
end;

initialization
  RegistrarPantalla(TfrmMtoCajaPagosHist);
  ForceReferenceToClass(TfrmMtoCajaPagosHist);
end.
