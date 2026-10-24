{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoConsultaOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta de operaciones de venta.                                         }
{    Vista maestro-detalle de operaciones con filtros de fecha.                }
{******************************************************************************}
unit inMtoConsultaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  cxDBData, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxCalendar, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtonEdit, cxContainer, cxLabel,
  cxSplitter, cxButtons, cxCheckBox, Vcl.Imaging.PngImage,
  inMtoFrmBase, inLibVentasCalendario, inLibLayoutForm,
  UniDataConsultaOpe, UniDataCaja, dxCore, cxDateUtils, dxCoreGraphics,
  cxCurrencyEdit, cxClasses, cxGridCustomView, JvComponentBase, JvEnterTab,
  cxLocalization, Vcl.Menus, inLibCajaTipos, inLibCajaVentanasIntf,
  inLibInteraccionDatosIntf,
  inLibConsultaFacturasOperacionesPersistenciaIntf,
  inLibEmisionFiscalIntf, inLibGenerarTicketIntf,
  inLibTraspasoTicketIntf, inLibTicketsCajaIntf,
  inLibVentasCalendarioIntf, inLibPermisosIntf,
  inLibCajaPantallaInyeccion,
  inLibCajaArticulosOperacionIntf,
  inLibCajaFotosOperacionGridVcl,
  inLibFotosMiniaturasGridVcl,
  inLibCajaSubsanacionIntf;

type
  TfrmConsultaOpe = class(TfrmBase, IConsultaOperacionesCaja)
    pnlFiltros:       TPanel;
    lblFecha:         TcxLabel;
    lblBuscar:        TcxLabel;
    edtBuscar:        TcxButtonEdit;
    chkVerTodos:      TcxCheckBox;
    chkVerMiniaturas: TcxCheckBox;
    pnlMaestro:       TPanel;
    cxGridMaestro:    TcxGrid;
    cxViewMaestro:    TcxGridDBTableView;
    cxLevelMaestro:   TcxGridLevel;
    splPrincipal:         TSplitter;
    pcHijos:          TcxPageControl;
    tsOperacion:      TcxTabSheet;
    tsPagos:          TcxTabSheet;
    tsVales:          TcxTabSheet;
    tsMovimientos:    TcxTabSheet;
    tsCliente:        TcxTabSheet;
    tsDepositos:      TcxTabSheet;
    tsFactura:        TcxTabSheet;
    dtpFecha: TcxDateEdit;
    cxGridOpe:        TcxGrid;
    cxViewOpe:        TcxGridDBTableView;
    cxLevelOpe:       TcxGridLevel;
    cxGridPagos:      TcxGrid;
    cxViewPagos:      TcxGridDBTableView;
    cxLevelPagos:     TcxGridLevel;
    cxGridVales:      TcxGrid;
    cxViewVales:      TcxGridDBTableView;
    cxLevelVales:     TcxGridLevel;
    cxGridMov:        TcxGrid;
    cxViewMov:        TcxGridDBTableView;
    cxLevelMov:       TcxGridLevel;
    cxGridCli:        TcxGrid;
    cxViewCli:        TcxGridDBTableView;
    cxLevelCli:       TcxGridLevel;
    cxGridDep:        TcxGrid;
    cxViewDep:        TcxGridDBTableView;
    cxLevelDep:       TcxGridLevel;
    pnlFacCabecera:   TPanel;
    cxGridFacCab:     TcxGrid;
    cxViewFacCab:     TcxGridDBTableView;
    cxLevelFacCab:    TcxGridLevel;
    cxGridFacLin:     TcxGrid;
    cxViewFacLin:     TcxGridDBTableView;
    cxLevelFacLin:    TcxGridLevel;
    splFotoConsulta:  TcxSplitter;
    pnlFotoConsulta:  TPanel;
    imgFotoConsulta:  TImage;
    pnlPie:           TPanel;
    btnReimprimir:    TcxButton;
    btnReimprimirOtros: TcxButton;
    btnCerrar:        TcxButton;
    tmrBusqueda:      TTimer;
    btnDevolverAbonar: TcxButton;
    btnAnularVerifactu: TcxButton;
    btnFacturarTicket: TcxButton;
    btnRectificar: TcxButton;
    btnEnviarEmail: TcxButton;
    btnSubsanar: TcxButton;
    colFaseFactura: TcxGridDBColumn;
    colMovColor: TcxGridDBColumn;
    colMovTalla: TcxGridDBColumn;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnRefrescarClick(Sender: TObject);
    procedure edtBuscarPropertiesChange(Sender: TObject);
    procedure chkVerTodosPropertiesChange(Sender: TObject);
    procedure chkVerMiniaturasPropertiesChange(Sender: TObject);
    procedure tmrBusquedaTimer(Sender: TObject);
    procedure btnReimprimirClick(Sender: TObject);
    procedure btnReimprimirOtrosClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure dtpFechaPropertiesGetDayState(Sender: TObject; ADate: TDateTime;
      AState: TCustomDrawState; AFont: TFont; var ABackgroundColor: TColor);
    procedure dtpFechaPropertiesEditValueChanged(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAnularVerifactuClick(Sender: TObject);
    procedure btnFacturarTicketClick(Sender: TObject);
    procedure btnDevolverAbonarClick(Sender: TObject);
    procedure btnRectificarClick(Sender: TObject);
    procedure btnEnviarEmailClick(Sender: TObject);
    procedure btnSubsanarClick(Sender: TObject);
    procedure cxViewMovCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FdmConsulta: TdmConsultaOpe;
    FEmpresa:    string;
    FAlmacen:    string;
    FCaja:       string;
    FRepositorioFacturas: IRepositorioConsultaFacturasOperaciones;
    FRepositorioVentasCalendario: IRepositorioVentasCalendario;
    FServicioEmisionFiscal: IServicioEmisionFiscal;
    FRepositorioTraspasoTicket: IRepositorioTraspasoTicket;
    FRepositoriosTicketsCaja: TRepositoriosTicketsCaja;
    FLecturasImpresionTicket: ILecturasImpresionTicket;
    FServicioSubsanacion: IServicioSubsanacionCaja;
    FArticulosOperacion: IConsultaArticulosOperacionCaja;
    // Columna "Fotos" de la rejilla maestra (nil si el parametro de caja
    // la apaga o no hay servicio de fotos).
    FFotosOperacion: TTiraMiniaturasFotosGrid;
    procedure SubsanarOperacion;
    procedure AbrirOperacionSubsanacion(
      const AOperacion: TOperacionSubsanacionCaja);
    function ClaveOperacionSubsanacion: TClaveOperacionSubsanacionCaja;
    procedure ValidarDependencias;
    // Factura de la operación seleccionada (pestaña Factura)
    procedure NotificarMensajeDesdeDM(
      Sender: TObject;
      const AMensaje: string;
      ASeveridad: TSeveridadMensajeDatos);
    function FacturaSeleccionada(out ASerie, ANumero: string): Boolean;
    function SeleccionarTipoRectificativa(
      const ASerie, ANumero: string;
      out ATipoRectificativa: TTipoRectificativaCaja): Boolean;
    procedure ActivarOperacionCaja(AFormularioCaja: TCustomForm);
    procedure RecargarMaestro;
    procedure AjustarVisibilidadColumnasCliente;
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure AplicarRotulosEjesMovimientos;
    procedure AjustarVisibilidadPestanas;
    // Cada boton de accion tiene su permiso caja.buscar.<boton>; sin regla
    // se permite (inLibPermisosIntf, script 20260928).
    function PuedeUsarBoton(const ACodigoPermiso: string): Boolean;
    procedure AplicarPermisosBotones;
    procedure AplicarAnchosPestanasHijas;
    procedure AjustarAPantalla;
    procedure ReimprimirOperacion(const ANombreImpresora: string);
    procedure OnMaestroDataChange(Sender: TObject; Field: TField);
    procedure OnMovimientoDataChange(Sender: TObject; Field: TField);
    procedure RefrescarFotoConsulta;
    procedure CrearColumnaFotosOperacion;
    procedure AplicarVisibilidadMiniaturas;
    // Lee el ARTICULO / SKU del movimiento activo en cxViewMov para
    // alimentar la pantalla flotante de fotos (Ctrl + F).
    procedure ResolverArtSkuDeMovimiento(out ACodArt, ACodSku: string);
    // Ctrl+R / Ctrl+M (pestana Movimientos) y Ctrl+Shift+F (pestana
    // Factura): saltan a la ficha del articulo, del movimiento de almacen o
    // de la factura del registro activo, abriendola como pestana en el
    // formulario principal via ShowMto.
    procedure AbrirArticuloDeMovimiento;
    procedure AbrirMovimientoActivo;
    procedure AbrirFacturaActiva;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion); reintroduce; overload;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion;
      const ADependencias: TDependenciasConsultaOperacionesCaja);
      reintroduce; overload;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    function FormularioConsultaCaja: TCustomForm;
    procedure PrepararValores(const AEmpresa,
                                    AAlmacen,
                                    ACaja: string;
                                    AFecha: TDateTime);
    procedure RefrescarOperaciones;
  private
    FLayout: TLayoutLoader;
    FVentasCal: TVentasCalendarioCache;
    procedure AplicarEstiloCaja;
    procedure dtpFechaGetDayState(Sender: TObject; ADate: TDateTime;
      AState: TCustomDrawState; AFont: TFont; var ABackgroundColor: TColor);
  end;

implementation

{$R *.dfm}

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  UniDataColumnasDocumentoRepositorio,
  System.StrUtils,
  inLibMensajesVcl,
  inLibGenerarTicketBD, inLibGenerarTicketCaja,
     inLibFotos, inMtoFotoArticulo,
     inLibTraspasoTicket, inLibShowMto, inLibReimpresionOperacionCaja,
     inLibVerifactu, inLibVerifactuTipos, inMtoModalFacturarTicket,
  inLibCorreoTickets, UniDataCorreoTicketsRepositorio,
  inLibAtributosPaleta, inLibMsgComun,
  inLibMsgCaja, inLibMsgConfiguracion, inLibMsgFacturas,
  inLibMsgSubsanacionCaja, inLibCajaEstiloVcl;

const
  // Parametro de caja que enciende la columna de miniaturas de la rejilla
  // principal (Avisos y Busquedas).
  cParamVerMiniaturasGrids = 'appVerMiniaturasGrids';
  // Clave del check en el perfil de la pantalla.
  cPerfilVerMiniaturas = 'VerMiniaturas';

resourcestring
  STituloPersonalizacionConsultaOperaciones =
    'Personalizacion Consulta Operaciones';

// -----------------------------------------------------------------------------
constructor TfrmConsultaOpe.Create(AOwner: TComponent);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de consulta de operaciones de Caja');
end;

constructor TfrmConsultaOpe.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de consulta de operaciones de Caja');
end;

constructor TfrmConsultaOpe.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasConsultaOperacionesCaja);
begin
  ADependencias.Validar;
  FRepositorioFacturas := ADependencias.Facturas;
  FRepositorioVentasCalendario := ADependencias.VentasCalendario;
  FServicioEmisionFiscal := ADependencias.EmisionFiscal;
  FRepositorioTraspasoTicket := ADependencias.TraspasoTicket;
  FRepositoriosTicketsCaja := ADependencias.Tickets;
  FLecturasImpresionTicket := ADependencias.LecturasTicket;
  FServicioSubsanacion := ADependencias.Subsanacion;
  FArticulosOperacion := ADependencias.ArticulosOperacion;
  inherited Create(AOwner, APermisos);
end;

procedure TfrmConsultaOpe.ValidarDependencias;
var
  Dependencias: TDependenciasConsultaOperacionesCaja;
begin
  Dependencias.Facturas := FRepositorioFacturas;
  Dependencias.VentasCalendario := FRepositorioVentasCalendario;
  Dependencias.EmisionFiscal := FServicioEmisionFiscal;
  Dependencias.TraspasoTicket := FRepositorioTraspasoTicket;
  Dependencias.Tickets := FRepositoriosTicketsCaja;
  Dependencias.LecturasTicket := FLecturasImpresionTicket;
  Dependencias.Subsanacion := FServicioSubsanacion;
  Dependencias.Validar;
end;

procedure TfrmConsultaOpe.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := CaFree;
end;

// FZ-ISSUE-439: la rejilla de movimientos mezcla artículos de variaciones
// distintas; el título solo cambia si alguna llama a sus ejes de otra
// forma.
procedure TfrmConsultaOpe.AplicarRotulosEjesMovimientos;
var
  sRotuloEje: string;
begin
  sRotuloEje := RotuloGlobalEje(ConexionPrincipal, 'F', '');
  if (sRotuloEje <> '') and not SameText(sRotuloEje, 'Color') then
    colMovColor.Caption := sRotuloEje;
  sRotuloEje := RotuloGlobalEje(ConexionPrincipal, 'P', '');
  if (sRotuloEje <> '') and not SameText(sRotuloEje, 'Talla') then
    colMovTalla.Caption := sRotuloEje;
end;

procedure TfrmConsultaOpe.FormCreate(Sender: TObject);
begin
  inherited;
  ValidarDependencias;
  FdmConsulta := TdmConsultaOpe.Create(
    Self,
    ConexionPrincipal,
    RegistroLog);
  FdmConsulta.OnNotificarMensaje := NotificarMensajeDesdeDM;
  FLayout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  FVentasCal := TVentasCalendarioCache.Create(
    ConexionPrincipal,
    FRepositorioVentasCalendario);
  dtpFecha.Properties.OnGetDayState := dtpFechaGetDayState;
  cxViewMaestro.DataController.DataSource := FdmConsulta.dsMaestro;
  cxViewOpe.DataController.DataSource     := FdmConsulta.dsOperacion;
  cxViewPagos.DataController.DataSource   := FdmConsulta.dsPagos;
  cxViewVales.DataController.DataSource   := FdmConsulta.dsVales;
  cxViewMov.DataController.DataSource     := FdmConsulta.dsMovimientos;
  AplicarRotulosEjesMovimientos;
  cxViewCli.DataController.DataSource     := FdmConsulta.dsCliente;
  cxViewDep.DataController.DataSource     := FdmConsulta.dsDepositos;
  cxViewFacCab.DataController.DataSource  := FdmConsulta.dsFactura;
  cxViewFacLin.DataController.DataSource  := FdmConsulta.dsFacturaLin;
  FdmConsulta.dsMaestro.OnDataChange    := OnMaestroDataChange;
  FdmConsulta.dsMovimientos.OnDataChange := OnMovimientoDataChange;
  tmrBusqueda.Enabled  := False;
  tmrBusqueda.Interval := 400;
  KeyPreview := True;   // para que FormKeyDown capture F5/ESC aunque el foco
                        // este en el grid o en el edit de busqueda
  CrearColumnaFotosOperacion;
  // El check solo aparece si hay columna de miniaturas; arranca marcado.
  chkVerMiniaturas.Visible := Assigned(FFotosOperacion);
  chkVerMiniaturas.Checked := True;
  AplicarEstiloCaja;
end;

// Mismo aspecto que el menú y la operación de caja: textos en Source Sans 3,
// cabeceras en negrita y botones como tarjetas. "Cerrar (ESC)" pasa a la
// segunda fila, a la derecha, con la tecla en una píldora.
procedure TfrmConsultaOpe.AplicarEstiloCaja;
const
  ALTO_BOTON = 36;
  ALTO_FUENTE_BOTON = 15;
var
  Estilo: TEstiloCaja;
  Boton: TcxButton;
  Vista: TcxGridTableView;
  iMargen, iHueco, iAlto: Integer;
begin
  Estilo := TEstiloCaja.Create(Self);
  QuitarBiselesCaja([pnlFotoConsulta]);
  EstilarEtiquetaCaja(lblFecha, 16, True);
  EstilarEtiquetaCaja(lblBuscar, 16, True);
  for Vista in TArray<TcxGridTableView>.Create(cxViewMaestro, cxViewOpe,
    cxViewPagos, cxViewVales, cxViewMov, cxViewCli, cxViewDep, cxViewFacCab,
    cxViewFacLin) do
    Estilo.EstilarRejilla(Vista);
  for Boton in TArray<TcxButton>.Create(btnReimprimir, btnReimprimirOtros,
    btnEnviarEmail, btnDevolverAbonar, btnRectificar, btnAnularVerifactu,
    btnFacturarTicket, btnSubsanar, btnCerrar) do
    Estilo.EstilarBoton(Boton, '', nil, ALTO_FUENTE_BOTON);
  iMargen := EscalarCaja(Self, 12);
  iHueco := EscalarCaja(Self, 8);
  iAlto := EscalarCaja(Self, ALTO_BOTON);
  pnlPie.Height := 2 * iAlto + 3 * iHueco;
  ColocarFilaBotonesCaja([btnReimprimir, btnReimprimirOtros, btnEnviarEmail,
    btnDevolverAbonar, btnRectificar, btnAnularVerifactu, btnFacturarTicket],
    iMargen, iHueco, iAlto, ALTO_FUENTE_BOTON);
  ColocarFilaBotonesCaja([btnSubsanar], iMargen,
    2 * iHueco + iAlto, iAlto, ALTO_FUENTE_BOTON);
  ColocarFilaBotonesCaja([btnCerrar], 0, 2 * iHueco + iAlto, iAlto,
    ALTO_FUENTE_BOTON);
  btnCerrar.Left := pnlPie.ClientWidth - iMargen - btnCerrar.Width;
  btnCerrar.Anchors := [akTop, akRight];
end;

procedure TfrmConsultaOpe.NotificarMensajeDesdeDM(
  Sender: TObject;
  const AMensaje: string;
  ASeveridad: TSeveridadMensajeDatos);
var
  TipoMensaje: TMsgDlgType;
begin
  case ASeveridad of
    smdInformacion:
      TipoMensaje := mtInformation;
    smdAdvertencia:
      TipoMensaje := mtWarning;
    smdError:
      TipoMensaje := mtError;
  else
    TipoMensaje := mtInformation;
  end;
  MessageDlg_fza(AMensaje, TipoMensaje, [mbOK], 0);
end;

function TfrmConsultaOpe.FormularioConsultaCaja: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmConsultaOpe.FormDestroy(Sender: TObject);
begin
  // Antes que nada: la tira suelta los eventos de la vista y de su
  // columna, que siguen vivas mientras no se destruyan los componentes.
  FreeAndNil(FFotosOperacion);
  FArticulosOperacion := nil;
  FServicioSubsanacion := nil;
  FLecturasImpresionTicket := nil;
  FRepositoriosTicketsCaja.Impresion := nil;
  FRepositoriosTicketsCaja.Recordatorios := nil;
  FRepositoriosTicketsCaja.Tickets := nil;
  FRepositoriosTicketsCaja.Resguardos := nil;
  FRepositorioTraspasoTicket := nil;
  FServicioEmisionFiscal := nil;
  FRepositorioVentasCalendario := nil;
  FRepositorioFacturas := nil;
  inherited;
  FreeAndNil(FLayout);
  FreeAndNil(FVentasCal);
end;

procedure TfrmConsultaOpe.dtpFechaGetDayState(Sender: TObject;
  ADate: TDateTime; AState: TCustomDrawState; AFont: TFont;
  var ABackgroundColor: TColor);
begin
  FVentasCal.AplicarEstiloDia(ADate, AFont, ABackgroundColor);
end;

procedure TfrmConsultaOpe.PrepararValores(const AEmpresa,
                                                AAlmacen,
                                                ACaja: string;
                                                AFecha: TDateTime);
begin
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja    := ACaja;
  dtpFecha.Date := AFecha;
  FVentasCal.Reconfigurar(AEmpresa, AAlmacen, ACaja);
end;

procedure TfrmConsultaOpe.RefrescarOperaciones;
begin
  if Assigned(FVentasCal) then
    FVentasCal.InvalidarTodo;
  if Assigned(FdmConsulta) then
  begin
    FdmConsulta.InvalidarCacheMaestro;
    RecargarMaestro;
  end;
end;

procedure TfrmConsultaOpe.FormShow(Sender: TObject);
var
  ColumnaFormaPago: TcxGridDBColumn;
begin
  inherited;
  RegistroLog.RegistrarInformacion(
    Format('frmConsultaOpe.FormShow: INICIO emp="%s" alm="%s" ' +
                     'caja="%s" fecha=%s',
                     [FEmpresa, FAlmacen, FCaja, DateToStr(dtpFecha.Date)]));
  Caption := Format(STituloBuscarOperacionesCaja,
    [FEmpresa, FAlmacen, FCaja]);
  AplicarPermisosBotones;
  RecargarMaestro;
  pcHijos.ActivePage := tsMovimientos;
  RestaurarLayout;
  ColumnaFormaPago := cxViewMaestro.GetColumnByFieldName('FORMAS_PAGO');
  if ColumnaFormaPago <> nil then
    ColumnaFormaPago.ApplyBestFit;
  AjustarAPantalla;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
  RegistroLog.RegistrarInformacion('frmConsultaOpe.FormShow: FIN');
end;

function TfrmConsultaOpe.IsShortCut(var Message: TWMKey): Boolean;
var
  Tecla: Word;
begin
  // El menu general tambien usa Ctrl+R. Consumirlo antes de OnKeyDown
  // conserva el articulo seleccionado en Buscar/Modificar.
  if ShortCutFromMessage(Message) = ShortCut(Ord('R'), [ssCtrl]) then
  begin
    Tecla := Message.CharCode;
    FormKeyDown(Self, Tecla, [ssCtrl]);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmConsultaOpe.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  FormularioFoto: TfrmFotoArticulo;
  sArt, sSku: string;
begin
  // Ctrl + Shift + F -> ficha de la factura (normal o simplificada) que se
  // muestra en la pestana Factura.
  if (Key = Ord('F')) and (ssCtrl in Shift) and (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    AbrirFacturaActiva;
    Key := 0;
  end
  // Ctrl + R -> ficha del articulo del movimiento activo (pestana Movimientos).
  else if (Key = Ord('R')) and (ssCtrl in Shift) and
     not (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    AbrirArticuloDeMovimiento;
    Key := 0;
  end
  // Ctrl + M -> ficha del movimiento de almacen activo (pestana Movimientos).
  else if (Key = Ord('M')) and (ssCtrl in Shift) and
     not (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    AbrirMovimientoActivo;
    Key := 0;
  end
  // Ctrl + F (sin Shift) -> Foto del articulo / SKU del movimiento
  // activa. Toggle: si la foto ya esta visible, ocultarla.
  else if (Key = Ord('F')) and (ssCtrl in Shift) and
     not (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    FormularioFoto := FotoFlotanteActual;
    if (FormularioFoto <> nil) and FormularioFoto.Visible then
      FormularioFoto.Hide
    else
    begin
      ResolverArtSkuDeMovimiento(sArt, sSku);
      if sArt <> '' then
      begin
        MostrarFotoFlotante(Self, sArt, sSku);
        FormularioFoto := FotoFlotanteActual;
        if FormularioFoto <> nil then
          FormularioFoto.VincularMtoPadre(FdmConsulta.dsMovimientos,
                                          ResolverArtSkuDeMovimiento);
      end;
    end;
    Key := 0;
  end
  else
  begin
    case Key of
      VK_ESCAPE: Close;
      VK_F5: RecargarMaestro;
      VK_F12:
        if (ssAlt in Shift) and not (ssCtrl in Shift) then
          GuardarLayout
        else if (ssCtrl in Shift) and not (ssAlt in Shift) then
          ResetearLayout(
            Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
    end;
  end;
end;

procedure TfrmConsultaOpe.ResolverArtSkuDeMovimiento(out ACodArt,
                                                     ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(FdmConsulta) then
    LeerArtSkuDeDataSet(
      FdmConsulta.dsMovimientos.DataSet, ACodArt, ACodSku);
end;

// Ctrl + R: abre la ficha del articulo (Mto Articulos) del movimiento
// activo en Movimientos o Factura, segun la pestana seleccionada.
procedure TfrmConsultaOpe.AbrirArticuloDeMovimiento;
var
  ds  : TDataSet;
  sArt: string;
begin
  if Assigned(FdmConsulta) then
  begin
    if Assigned(pcHijos) and (pcHijos.ActivePage = tsFactura) then
      ds := FdmConsulta.dsFacturaLin.DataSet
    else
      ds := FdmConsulta.dsMovimientos.DataSet;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
      if Assigned(pcHijos) and (pcHijos.ActivePage = tsFactura) then
        sArt := ds.FieldByName('CODIGO_ART_FACLIN').AsString
      else
        sArt := ds.FieldByName('CODIGO_ART_MOV').AsString;
      if sArt <> '' then
        ShowMto(Application.MainForm, 'Articulos', sArt);
    end;
  end;
end;

// Ctrl + M: abre el Mto de Movimientos de Almacen posicionado en el
// movimiento (NUMERO_MOV) activo en la pestana Movimientos.
procedure TfrmConsultaOpe.AbrirMovimientoActivo;
var
  ds     : TDataSet;
  sNumMov: string;
begin
  if Assigned(FdmConsulta) then
  begin
    ds := FdmConsulta.dsMovimientos.DataSet;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
      sNumMov := ds.FieldByName('NUMERO_MOV').AsString;
      if sNumMov <> '' then
        ShowMto(Application.MainForm, 'MovimientosAlmacen', sNumMov);
    end;
  end;
end;

// Ctrl + Shift + F: abre la factura SIMPLIFICADA que se muestra en la
// pestana Factura. En la consulta de operaciones de caja las facturas son
// siempre simplificadas, asi que vamos directos a 'FacturasSimplif'.
procedure TfrmConsultaOpe.AbrirFacturaActiva;
var
  ds  : TDataSet;
  sNum: string;
  sSer: string;
begin
  if Assigned(FdmConsulta) then
  begin
    ds := FdmConsulta.dsFactura.DataSet;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
      sNum := ds.FieldByName('NUMERO_FAC').AsString;
      sSer := ds.FieldByName('SERIE_FAC').AsString;
      if (sNum <> '') and (sSer <> '') then
        ShowMto(
          Application.MainForm, 'FacturasSimplif', sNum + ',' + sSer);
    end;
  end;
end;

function TfrmConsultaOpe.FacturaSeleccionada(out ASerie,
                                             ANumero: string): Boolean;
var
  ds: TDataSet;
begin
  ASerie  := '';
  ANumero := '';
  if Assigned(FdmConsulta) then
  begin
    ds := FdmConsulta.dsFactura.DataSet;
    if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    begin
      ASerie  := ds.FieldByName('SERIE_FAC').AsString;
      ANumero := ds.FieldByName('NUMERO_FAC').AsString;
    end;
  end;
  Result := (Trim(ASerie) <> '') and (Trim(ANumero) <> '');
end;

function TfrmConsultaOpe.ClaveOperacionSubsanacion:
  TClaveOperacionSubsanacionCaja;
begin
  Result := Default(TClaveOperacionSubsanacionCaja);
  if not FacturaSeleccionada(Result.SerieFactura, Result.NumeroFactura) then
    raise EInvalidOpException.Create(SSubsanacionNoPermitida);
  Result.Empresa := FdmConsulta.qryMaestro.FieldByName(
    'CODIGO_EMP_OPCAJA').AsString;
  Result.Almacen := FdmConsulta.qryMaestro.FieldByName(
    'CODIGO_ALM_OPCAJA').AsString;
  Result.Caja := FdmConsulta.qryMaestro.FieldByName(
    'CODIGO_CAJA_OPCAJA').AsString;
  Result.NumeroOperacion := FdmConsulta.qryMaestro.FieldByName(
    'NUMERO_OPERACION_OPCAJA').AsString;
end;

procedure TfrmConsultaOpe.AbrirOperacionSubsanacion(
  const AOperacion: TOperacionSubsanacionCaja);
var
  oAnfitrion: IAnfitrionCajaVentanas;
  oOperacion: IOperacionCaja;
  oFormulario: TCustomForm;
begin
  oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
  oOperacion := oAnfitrion.CrearOperacionCaja(Application, Permisos);
  oFormulario := oOperacion.FormularioCaja;
  try
    oOperacion.PrepararValores(AOperacion.Clave.Empresa,
      AOperacion.Clave.Almacen, AOperacion.Clave.Caja, Now);
    oOperacion.CargarSubsanacion(AOperacion, FServicioSubsanacion);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarError('AbrirOperacionSubsanacion: ' + E.Message);
      oOperacion := nil;
      FreeAndNil(oFormulario);
      raise;
    end;
  end;
  ActivarOperacionCaja(oFormulario);
end;

procedure TfrmConsultaOpe.SubsanarOperacion;
var
  rOperacion: TOperacionSubsanacionCaja;
  rClave: TClaveOperacionSubsanacionCaja;
  rFactura: TFacturaConsultaOperacion;
  bPuedeSubsanar: Boolean;
  sMotivoRechazo: string;
begin
  rClave := ClaveOperacionSubsanacion;
  rFactura := FRepositorioFacturas.ConsultarFactura(
    rClave.SerieFactura, rClave.NumeroFactura);
  if not rFactura.Existe then
    raise EInvalidOpException.Create(SSubsanacionNoPermitida);
  case ModoVerifactu(ParametrosApp) of
    mvSinVerifactu:
    begin
      bPuedeSubsanar := rFactura.PuedeSubsanarSinVerifactu;
      sMotivoRechazo := SSubsanacionNoPermitidaSinVerifactu;
    end;
    mvNoVerifactu:
    begin
      bPuedeSubsanar := rFactura.PuedeSubsanarNoVerifactu;
      sMotivoRechazo := SSubsanacionNoPermitidaNoVerifactu;
    end;
  else
    bPuedeSubsanar := rFactura.PuedeSubsanar;
    sMotivoRechazo := SSubsanacionNoPermitidaVerifactu;
  end;
  if not bPuedeSubsanar then
    raise EInvalidOpException.CreateFmt(sMotivoRechazo,
      [rClave.SerieFactura, rClave.NumeroFactura, rFactura.Fase]);
  rOperacion := FServicioSubsanacion.Cargar(rClave);
  AbrirOperacionSubsanacion(rOperacion);
end;

procedure TfrmConsultaOpe.btnSubsanarClick(Sender: TObject);
begin
  // Las validaciones de negocio se informan con un aviso, no como error.
  try
    SubsanarOperacion;
  except
    on E: EInvalidOpException do
      ShowMessage_fza(E.Message);
    on E: EArgumentException do
      ShowMessage_fza(E.Message);
  end;
end;

procedure TfrmConsultaOpe.ActivarOperacionCaja(
  AFormularioCaja: TCustomForm);
begin
  if AFormularioCaja.WindowState = wsMinimized then
    AFormularioCaja.WindowState := wsNormal;
  AFormularioCaja.Show;
  // Buscar operaciones puede ser un popup de esta misma operacion. Mientras
  // siga visible, Windows impide que su ventana propietaria quede por encima.
  Hide;
  AFormularioCaja.BringToFront;
  Close;
end;

procedure TfrmConsultaOpe.btnAnularVerifactuClick(Sender: TObject);
var
  Factura: TFacturaConsultaOperacion;
  sSerie: string;
  sNumero: string;
  Resultado: TResultadoEmisionFiscal;
  Solicitud: TSolicitudEmisionFiscal;
begin
  // Anulación fiscal y retirada operativa de la venta.
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage_fza(SErrorOperacionSinBorrador)
  else
  begin
    Factura := FRepositorioFacturas.ConsultarFactura(sSerie, sNumero);
    if (not Factura.Existe) or (not Factura.Consolidada) then
      ShowMessage_fza(FormatearMensajeDocumentos(
        CrearFormatoDocumentoLecturas(ConexionPrincipal)
        .LeerFormatoEmpresa(FEmpresa),
        SErrorBorradorNoCerradoFiscalmente,
        [sSerie, sNumero]))
    else if MessageDlg_fza(FormatearMensajeDocumentos(
      CrearFormatoDocumentoLecturas(ConexionPrincipal)
      .LeerFormatoEmpresa(FEmpresa),
      SPreguntaAnularFiscalmenteBorrador,
      [sSerie, sNumero]), mtConfirmation,
                       [mbYes, mbNo], 0) = mrYes then
    begin
      Solicitud := TSolicitudEmisionFiscal.ParaOperacion(
        sSerie,
        sNumero,
        IdentidadSesion.Usuario,
        'ANULACION',
        'Anulación',
        True,
        'Anulación encolada desde Buscar operaciones');
      Resultado := FServicioEmisionFiscal.Emitir(Solicitud);
      ShowMessage_fza(Resultado.Mensaje);
      RefrescarOperaciones;
    end;
  end;
end;

procedure TfrmConsultaOpe.btnFacturarTicketClick(Sender: TObject);
var
  Factura: TFacturaConsultaOperacion;
  oRes:    TFacturarTicketResult;
  sSerie:  string;
  sNumero: string;
  bSigue:  Boolean;
begin
  //Factura completa (F3) en sustitución del ticket de la operación
  bSigue  := False;
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage_fza(SErrorOperacionSinBorrador)
  else
  begin
    Factura := FRepositorioFacturas.ConsultarFactura(sSerie, sNumero);
    if (not Factura.Existe) or
       (not SameText(Factura.Tipo, 'SIMPLIFICADA')) then
      ShowMessage_fza(SErrorFacturarTicketRequiereSimplificado)
    else
      bSigue := True;
    if bSigue then
    begin
      oRes := TfrmModalFacturarTicket.Ejecutar(Self, sSerie, sNumero,
                                               FEmpresa, FAlmacen);
      if oRes.Aceptado then
        ShowMessage_fza(FormatearMensajeDocumentos(
          oRes.FormatoDocumento,
          SInfoBorradorSustitucionTicketCreado,
          [oRes.SerieNueva, oRes.NumeroNueva,
          sSerie, sNumero,
          ModoVerifactuTexto(ParametrosApp)]));
    end;
  end;
end;

procedure TfrmConsultaOpe.btnDevolverAbonarClick(Sender: TObject);
var
  oAnfitrion: IAnfitrionCajaVentanas;
  oOperacionCaja: IOperacionCaja;
  oFormularioCaja: TCustomForm;
  sSerie: string;
  sNumero: string;
begin
  // Abre la caja con las lineas pendientes de devolver del ticket, en
  // negativo. Si el ticket es de la empresa de la caja sale como
  // rectificativa por diferencias enlazada al original (FZ-ISSUE-392);
  // si es de otra empresa, como devolucion comercial con la referencia
  // en la operacion DV.
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage_fza(SErrorOperacionSinBorrador)
  else
  begin
    oOperacionCaja := BuscarOperacionCajaVacia;
    if oOperacionCaja = nil then
    begin
      oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
      oOperacionCaja :=
        oAnfitrion.CrearOperacionCaja(Application, Permisos);
      oFormularioCaja := oOperacionCaja.FormularioCaja;
      oFormularioCaja.Caption :=
        Format(STituloOperacionCajaReal, [FCaja]);
      oOperacionCaja.PrepararValores(
        FEmpresa, FAlmacen, FCaja, Now);
    end;
    oFormularioCaja := oOperacionCaja.FormularioCaja;
    oOperacionCaja.CargarDevolucion(
      sSerie,
      sNumero,
      FEmpresa,
      FAlmacen);
    ActivarOperacionCaja(oFormularioCaja);
  end;
end;

procedure TfrmConsultaOpe.btnRectificarClick(Sender: TObject);
var
  Factura: TFacturaConsultaOperacion;
  oAnfitrion: IAnfitrionCajaVentanas;
  oOperacionCaja: IOperacionCaja;
  oFormularioCaja: TCustomForm;
  sSerie:  string;
  sNumero: string;
  bSigue:  Boolean;
  TipoRectificativa: TTipoRectificativaCaja;
  TratamientoMovimientos: TTratamientoMovimientosRectificativa;
begin
  // Rectificar carga la venta con el signo del tipo elegido; al cobrar
  // saldrá con serie rectificativa y quedará enlazada.
  bSigue := False;
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage_fza(SErrorOperacionSinBorrador)
  else
  begin
    Factura := FRepositorioFacturas.ConsultarFactura(sSerie, sNumero);
    if (not Factura.Existe) or
       SameText(Factura.Tipo, 'RECTIFICATIVA') then
      ShowMessage_fza(SErrorRectificarRectificativa)
    else
      bSigue := True;
  end;
  if bSigue and SeleccionarTipoRectificativa(
    sSerie, sNumero, TipoRectificativa) then
  begin
    TratamientoMovimientos := tmrMantenerOriginales;
    if TipoRectificativa = trcSustitutiva then
      TratamientoMovimientos := tmrReemplazarOriginales;
    if bSigue then
    begin
      // Ventana de ventas libre, o una nueva si todas están ocupadas
      oOperacionCaja := BuscarOperacionCajaVacia;
      if oOperacionCaja = nil then
      begin
        oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
        oOperacionCaja :=
          oAnfitrion.CrearOperacionCaja(Application, Permisos);
        oFormularioCaja := oOperacionCaja.FormularioCaja;
        oFormularioCaja.Caption :=
          Format(STituloOperacionCajaReal, [FCaja]);
        oOperacionCaja.PrepararValores(FEmpresa, FAlmacen, FCaja, Now);
      end;
      oFormularioCaja := oOperacionCaja.FormularioCaja;
      oOperacionCaja.CargarRectificacion(
        sSerie, sNumero, TipoRectificativa, TratamientoMovimientos);
      ActivarOperacionCaja(oFormularioCaja);
    end;
  end;
end;

function TfrmConsultaOpe.SeleccionarTipoRectificativa(
  const ASerie, ANumero: string;
  out ATipoRectificativa: TTipoRectificativaCaja): Boolean;
const
  AnchoBoton = 125;
  SeparacionBotones = 8;
var
  oDialogo: TForm;
  oBoton: TButton;
  i: Integer;
  iBotones: Integer;
  iIzquierda: Integer;
begin
  Result := False;
  ATipoRectificativa := trcNinguna;
  oDialogo := CreateMessageDialog(
    FormatearMensajeDocumentos(
      CrearFormatoDocumentoLecturas(ConexionPrincipal)
      .LeerFormatoEmpresa(FEmpresa),
      SPreguntaRectificarBorrador, [ASerie, ANumero]),
    mtConfirmation, [mbYes, mbNo, mbCancel]);
  try
    oDialogo.Caption := STituloTipoRectificativa;
    if oDialogo.ClientWidth < 440 then
      oDialogo.ClientWidth := 440;
    iBotones := 0;
    for i := 0 to oDialogo.ComponentCount - 1 do
    begin
      if oDialogo.Components[i] is TButton then
        Inc(iBotones);
    end;
    iIzquierda := (oDialogo.ClientWidth -
      (iBotones * AnchoBoton) -
      ((iBotones - 1) * SeparacionBotones)) div 2;
    for i := 0 to oDialogo.ComponentCount - 1 do
    begin
      if oDialogo.Components[i] is TButton then
      begin
        oBoton := TButton(oDialogo.Components[i]);
        case oBoton.ModalResult of
          mrYes:
            oBoton.Caption := SCaptionPorDiferencias;
          mrNo:
            oBoton.Caption := SCaptionSustitutiva;
          mrCancel:
            oBoton.Caption := SCaptionCancelar;
        end;
        oBoton.SetBounds(iIzquierda, oBoton.Top, AnchoBoton, oBoton.Height);
        Inc(iIzquierda, AnchoBoton + SeparacionBotones);
      end;
    end;
    case oDialogo.ShowModal of
      mrYes:
        begin
          ATipoRectificativa := trcDiferencias;
          Result := True;
        end;
      mrNo:
        begin
          ATipoRectificativa := trcSustitutiva;
          Result := True;
        end;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

// Enciende y apaga la columna de miniaturas sin deshacer la tira: asi el
// check no tira la cache de fotos ya calculada.
procedure TfrmConsultaOpe.AplicarVisibilidadMiniaturas;
begin
  if Assigned(FFotosOperacion) and Assigned(FFotosOperacion.Columna) then
    FFotosOperacion.Columna.Visible := chkVerMiniaturas.Checked;
end;

procedure TfrmConsultaOpe.chkVerMiniaturasPropertiesChange(
  Sender: TObject);
begin
  AplicarVisibilidadMiniaturas;
end;

// Columna "Fotos" al final de la rejilla maestra: una tira con las fotos
// de los articulos de cada operacion. La tira se engancha al
// OnCustomDrawCell de su propia columna y cachea rutas y bitmaps; sin
// servicio de fotos o con el parametro apagado no se crea.
procedure TfrmConsultaOpe.CrearColumnaFotosOperacion;
begin
  if (not Assigned(FotosArticulos)) or
     (not Assigned(FArticulosOperacion)) or
     (not Assigned(ParametrosApp)) then
    Exit;
  if not ParametrosApp.GetBool(cParamVerMiniaturasGrids, True) then
    Exit;
  // La rejilla maestra solo trae el numero de operacion y la factura:
  // empresa, almacen y caja no son columnas aqui, son el contexto fijo de
  // la pantalla (una instancia por caja), que llega en PrepararValores,
  // despues de montarse la columna.
  FFotosOperacion := CrearColumnaFotosOperacionCaja(
    cxViewMaestro,
    FotosArticulos,
    FArticulosOperacion,
    'colBuscarOpeFotos',
    SCaptionColumnaFotos,
    function: TClaveOperacionCaja
    begin
      Result := Default(TClaveOperacionCaja);
      Result.Empresa := FEmpresa;
      Result.Almacen := FAlmacen;
      Result.Caja := FCaja;
    end);
end;

// Recarga imgFotoConsulta con la foto a 300 px del articulo / SKU del
// movimiento activo. Lo invoca OnMovimientoDataChange.
procedure TfrmConsultaOpe.RefrescarFotoConsulta;
var
  sArt, sSku: string;
  info: TFotoInfo;
  sRuta: string;
  png: TPngImage;
begin
  if Assigned(imgFotoConsulta) then
  begin
    imgFotoConsulta.Picture.Assign(nil);
    ResolverArtSkuDeMovimiento(sArt, sSku);
    if sArt <> '' then
    begin
      info := FotosArticulos.Resolver(sArt, sSku);
      sRuta := FotosArticulos.RutaFoto(info, frPx300);
      if sRuta <> '' then
      begin
        png := TPngImage.Create;
        try
          png.LoadFromFile(sRuta);
          imgFotoConsulta.Picture.Assign(png);
        finally
          FreeAndNil(png);
        end;
      end;
    end;
  end;
end;

procedure TfrmConsultaOpe.OnMovimientoDataChange(Sender: TObject;
                                                 Field: TField);
begin
  if Field = nil then
    RefrescarFotoConsulta;
end;

procedure TfrmConsultaOpe.cxViewMovCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  colArticulo: TcxGridDBColumn;
  sArticulo: string;
  sColor: string;
begin
  ADone := False;
  if (AViewInfo <> nil) and
     (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item = colMovColor) then
  begin
    colArticulo := cxViewMov.GetColumnByFieldName('CODIGO_ART_MOV');
    if colArticulo <> nil then
    begin
      sArticulo := VarToStr(
        AViewInfo.GridRecord.Values[colArticulo.Index]);
      sColor := VarToStr(
        AViewInfo.GridRecord.Values[colMovColor.Index]);
      if PintarCeldaSwatchArticuloSiAplica(
        ConexionPrincipal,
        ACanvas,
        AViewInfo,
        sArticulo,
        sColor,
        nil) then
        ADone := True;
    end;
  end;
end;

procedure TfrmConsultaOpe.RestaurarLayout;
begin
  if not FLayout.Disponible then
    RegistroLog.RegistrarInformacion(
      'RestaurarLayout: SKIP (FLayout no disponible)')
  else
  begin
    RegistroLog.RegistrarInformacion(
      'RestaurarLayout: aplicando geometria + 9 grids');
    FLayout.RestaurarGeometria(Self);
    FLayout.RestaurarAlturaPanel('PnlMaestroHeight', pnlMaestro, 80);
    FLayout.RestaurarAnchoPanel('FotoConsultaWidth', pnlFotoConsulta, 50);
    FLayout.RestaurarGrid('Maestro', cxViewMaestro);
    if chkVerMiniaturas.Visible then
      chkVerMiniaturas.Checked :=
        FLayout.RestaurarValor(cPerfilVerMiniaturas, 'S') = 'S';
    AplicarAnchosPestanasHijas;
    RegistroLog.RegistrarInformacion('RestaurarLayout: FIN');
  end;
end;

// Encaja el formulario en el area de trabajo del monitor actual. En
// resoluciones pequenas (1366x768, 1280x720...) el tamano de diseno deja la
// botonera inferior fuera de pantalla; aqui se recorta la ventana y se
// recoloca para que se vea entera. Se invoca tras RestaurarLayout porque el
// perfil guardado puede traer una geometria mayor que la pantalla del puesto.
procedure TfrmConsultaOpe.AjustarAPantalla;
var
  rArea: TRect;
begin
  if WindowState = wsNormal then
  begin
    rArea := Monitor.WorkareaRect;
    if Width > rArea.Width then
      Width := rArea.Width;
    if Height > rArea.Height then
      Height := rArea.Height;
    if Left + Width > rArea.Right then
      Left := rArea.Right - Width;
    if Top + Height > rArea.Bottom then
      Top := rArea.Bottom - Height;
    if Left < rArea.Left then
      Left := rArea.Left;
    if Top < rArea.Top then
      Top := rArea.Top;
  end;
end;

procedure TfrmConsultaOpe.AplicarAnchosPestanasHijas;
begin
  if FLayout.Disponible then
  begin
    FLayout.RestaurarGrid('Operacion', cxViewOpe);
    FLayout.RestaurarGrid('Pagos', cxViewPagos);
    FLayout.RestaurarGrid('Vales', cxViewVales);
    FLayout.RestaurarGrid('Movimientos', cxViewMov);
    // La disposición guardada puede traer el título antiguo.
    AplicarRotulosEjesMovimientos;
    FLayout.RestaurarGrid('Cliente', cxViewCli);
    FLayout.RestaurarGrid('Depositos', cxViewDep);
    FLayout.RestaurarGrid('FacturaCab', cxViewFacCab);
    FLayout.RestaurarGrid('FacturaLin', cxViewFacLin);
  end;
end;

procedure TfrmConsultaOpe.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarAlturaPanel('PnlMaestroHeight', pnlMaestro);
    Layout.GuardarAnchoPanel('FotoConsultaWidth', pnlFotoConsulta);
    Layout.GuardarGrid('Maestro',     cxViewMaestro);
    if chkVerMiniaturas.Visible then
      Layout.GuardarValor(
        cPerfilVerMiniaturas,
        IfThen(chkVerMiniaturas.Checked, 'S', 'N'));
    Layout.GuardarGrid('Operacion',   cxViewOpe);
    Layout.GuardarGrid('Pagos',       cxViewPagos);
    Layout.GuardarGrid('Vales',       cxViewVales);
    Layout.GuardarGrid('Movimientos', cxViewMov);
    Layout.GuardarGrid('Cliente',     cxViewCli);
    Layout.GuardarGrid('Depositos',   cxViewDep);
    Layout.GuardarGrid('FacturaCab',  cxViewFacCab);
    Layout.GuardarGrid('FacturaLin',  cxViewFacLin);
    if Layout.PreguntarYGrabar(
      STituloPersonalizacionConsultaOperaciones) then
      ShowMessage_fza(SInfoLayoutGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmConsultaOpe.chkVerTodosPropertiesChange(Sender: TObject);
begin
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.RecargarMaestro;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
    RegistroLog.RegistrarInformacion(
      'RecargarMaestro: SKIP (contexto vacio)')
  else
  begin
    RegistroLog.RegistrarInformacion(
      Format('RecargarMaestro: emp="%s" alm="%s" caja="%s" ' +
        'fecha=%s txt="%s"',
        [FEmpresa, FAlmacen, FCaja, DateToStr(dtpFecha.Date),
         Trim(edtBuscar.Text)]));
    Screen.Cursor := crHourGlass;
    try
      FdmConsulta.CargarMaestro(
        dtpFecha.Date, FEmpresa, FAlmacen, FCaja, Trim(edtBuscar.Text),
        chkVerTodos.Checked);
      // Recargar es el momento de tirar la cache de fotos: asi una foto
      // anadida o rotada desde otra pantalla se ve sin reabrir.
      if Assigned(FFotosOperacion) then
        FFotosOperacion.Limpiar;
      AjustarVisibilidadColumnasCliente;
      AjustarVisibilidadPestanas;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmConsultaOpe.OnMaestroDataChange(Sender: TObject; Field: TField);
begin
  // Field=nil => cambio de fila (no de celda). Refrescamos hijas y visibilidad.
  // El escudo FUltimaClaveHijas en el dm evita relanzar las 8 queries si la
  // operacion activa no ha cambiado realmente.
  if Field = nil then
  begin
    RegistroLog.RegistrarInformacion(
      'OnMaestroDataChange: Field=nil -> RefrescarPestanasHijas');
    FdmConsulta.RefrescarPestanasHijas;
    AjustarVisibilidadPestanas;
  end;
end;

// Las columnas de cliente se muestran solo si el dia tiene alguna venta
// a cliente identificado; con todo a mostrador estorban.
procedure TfrmConsultaOpe.AjustarVisibilidadColumnasCliente;
var
  bVisible: Boolean;
  ColCliente, ColRazonSocial: TcxGridDBColumn;
begin
  bVisible := FdmConsulta.HayClienteIdentificado;
  ColCliente := cxViewMaestro.GetColumnByFieldName('CLIENTE');
  ColRazonSocial :=
    cxViewMaestro.GetColumnByFieldName('RAZON_SOCIAL_CLI');
  if Assigned(ColCliente) then
    ColCliente.Visible := bVisible;
  if Assigned(ColRazonSocial) then
    ColRazonSocial.Visible := bVisible;
end;

procedure TfrmConsultaOpe.AjustarVisibilidadPestanas;
var
  bHayDocumento: Boolean;
  PagActiva: TcxTabSheet;
begin
  PagActiva := pcHijos.ActivePage;
  tsOperacion.TabVisible   := True;   // siempre visible
  tsPagos.TabVisible       := True;  // siempre visible
  tsVales.TabVisible       := FdmConsulta.TieneVales;
  tsMovimientos.TabVisible := True;  // siempre visible y pestaña inicial
  tsCliente.TabVisible     := FdmConsulta.TieneCliente;
  tsDepositos.TabVisible   := FdmConsulta.TieneDepositos;
  tsFactura.TabVisible     := FdmConsulta.TieneFactura;

  if (PagActiva <> nil) and (not PagActiva.TabVisible) then
    pcHijos.ActivePage := tsOperacion;

  bHayDocumento :=
    FdmConsulta.TieneFactura
    or FdmConsulta.TieneDepositos
    or FdmConsulta.EsOperacionCaja
    or FdmConsulta.EsTraspaso;
  btnReimprimir.Enabled := bHayDocumento and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_REIMPRIMIR);
  btnReimprimirOtros.Enabled := bHayDocumento and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_PREVISUALIZAR);
  btnEnviarEmail.Enabled := bHayDocumento and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_EMAIL);
  btnSubsanar.Caption := SSubsanacionBoton;
  btnSubsanar.Enabled := FdmConsulta.TieneFactura and
    FServicioSubsanacion.Permitida and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_SUBSANAR);
end;

function TfrmConsultaOpe.PuedeUsarBoton(
  const ACodigoPermiso: string): Boolean;
begin
  Result := Assigned(Permisos) and
            Permisos.TienePermiso(
              ACodigoPermiso,
              PermisoAusenteCodigo(ACodigoPermiso));
end;

// Los botones que no dependen de la operacion seleccionada solo dependen
// del permiso; los demas los recalcula AjustarVisibilidadPestanas.
procedure TfrmConsultaOpe.AplicarPermisosBotones;
begin
  btnDevolverAbonar.Enabled :=
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_DEVOLVER_ABONAR);
  btnRectificar.Enabled :=
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_RECTIFICAR);
  btnAnularVerifactu.Enabled :=
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_ANULAR_FISCAL);
  btnFacturarTicket.Enabled :=
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_CONVERTIR_NORMAL);
  btnReimprimir.Enabled := btnReimprimir.Enabled and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_REIMPRIMIR);
  btnReimprimirOtros.Enabled := btnReimprimirOtros.Enabled and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_PREVISUALIZAR);
  btnEnviarEmail.Enabled := btnEnviarEmail.Enabled and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_EMAIL);
  btnSubsanar.Enabled := btnSubsanar.Enabled and
    PuedeUsarBoton(PERMISO_CAJA_BUSCAR_SUBSANAR);
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.btnRefrescarClick(Sender: TObject);
begin
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.dtpFechaPropertiesEditValueChanged(Sender: TObject);
begin
  inherited;
  // Antes habia tambien un handler dtpFechaPropertiesChange (Properties.
  // OnChange en el dfm) llamando a RecargarMaestro. Disparaba la carga del
  // maestro dos veces seguidas con los mismos parametros porque tanto
  // OnChange como OnEditValueChanged se activan al setear dtpFecha.Date.
  // Eliminado el handler OnChange; este (OnEditValueChanged) es suficiente.
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.dtpFechaPropertiesGetDayState(Sender: TObject;
  ADate: TDateTime; AState: TCustomDrawState; AFont: TFont;
  var ABackgroundColor: TColor);
begin
  inherited;
  FVentasCal.AplicarEstiloDia(ADate, AFont, ABackgroundColor);
end;

procedure TfrmConsultaOpe.edtBuscarPropertiesChange(Sender: TObject);
begin
  tmrBusqueda.Enabled := False;
  tmrBusqueda.Enabled := True;
end;

procedure TfrmConsultaOpe.tmrBusquedaTimer(Sender: TObject);
begin
  tmrBusqueda.Enabled := False;
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.btnReimprimirClick(Sender: TObject);
begin
  ReimprimirOperacion(ParametrosCaja.ImpresoraCaja);
end;

procedure TfrmConsultaOpe.btnReimprimirOtrosClick(Sender: TObject);
begin
  ReimprimirOperacion('DEBUG');
end;

procedure TfrmConsultaOpe.btnEnviarEmailClick(Sender: TObject);
var
  Datos: TDatosCorreoOperacion;
  sEmp, sAlm, sCaja, sNumOp, sEmail, sMensaje: string;
  bContinuar: Boolean;
begin
  if not FdmConsulta.qryMaestro.IsEmpty then
  begin
    bContinuar := CorreoTicketsConfigurado(ParametrosApp, sMensaje);
    if not bContinuar then
      ShowMessage_fza(sMensaje)
    else
    begin
      sEmp := FdmConsulta.qryMaestro.
        FieldByName('CODIGO_EMP_OPCAJA').AsString;
      sAlm := FdmConsulta.qryMaestro.
        FieldByName('CODIGO_ALM_OPCAJA').AsString;
      sCaja := FdmConsulta.qryMaestro.
        FieldByName('CODIGO_CAJA_OPCAJA').AsString;
      sNumOp := FdmConsulta.qryMaestro.
        FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Datos := CrearCorreoTicketsLecturas(ConexionPrincipal).
        CargarDatosOperacion(sEmp, sAlm, sCaja, sNumOp);
      sEmail := Datos.EmailCliente;
      bContinuar := Datos.Encontrada;
      if not bContinuar then
        ShowMessage_fza(SErrorOperacionCorreoNoEncontrada)
      else if sEmail = '' then
        bContinuar := InputQuery_fza(STituloEnviarDocumentacion,
          SSolicitudCorreoElectronico, sEmail);
      if bContinuar and (Trim(sEmail) = '') then
      begin
        ShowMessage_fza(SErrorCorreoElectronicoObligatorio);
        bContinuar := False;
      end;
      if bContinuar then
      begin
        Screen.Cursor := crHourGlass;
        try
          if EnviarDocumentacionOperacion(
            ParametrosApp,
            PreviewTicket,
            UnidadesMedida,
            FRepositorioTraspasoTicket,
            FRepositoriosTicketsCaja,
            RegistroLog,
            ConexionPrincipal,
            Datos,
            sEmp,
            sAlm,
            sCaja, sNumOp,
            sEmail, sMensaje, ParametrosCaja.GetBool(
              'vgerImprimirLoteCaducidadTicket', True)) then
            ShowMessage_fza(sMensaje)
          else
            ShowMessage_fza(Format(SErrorEnviarCorreoOperacion, [sMensaje]));
        finally
          Screen.Cursor := crDefault;
        end;
      end;
    end;
  end;
end;

procedure TfrmConsultaOpe.ReimprimirOperacion(
  const ANombreImpresora: string);
var
  Entorno: TEntornoReimpresionCaja;
  Dependencias: TDependenciasReimpresionCaja;
  Operacion: TOperacionReimpresionCaja;
begin
  if not FdmConsulta.qryMaestro.IsEmpty then
  begin
    Operacion := Default(TOperacionReimpresionCaja);
    Operacion.Empresa :=
      FdmConsulta.qryMaestro.FieldByName('CODIGO_EMP_OPCAJA').AsString;
    Operacion.Almacen :=
      FdmConsulta.qryMaestro.FieldByName('CODIGO_ALM_OPCAJA').AsString;
    Operacion.Caja :=
      FdmConsulta.qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
    Operacion.NumeroOperacion := FdmConsulta.qryMaestro.
      FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
    Operacion.Tipos :=
      FdmConsulta.qryMaestro.FieldByName('TIPOS_OP').AsString;
    Operacion.Cliente :=
      FdmConsulta.qryMaestro.FieldByName('CLIENTE').AsString;
    Operacion.TieneFactura := FdmConsulta.TieneFactura;
    Operacion.TieneDepositos := FdmConsulta.TieneDepositos;
    Entorno := Default(TEntornoReimpresionCaja);
    Entorno.ParametrosApp := ParametrosApp;
    Entorno.ParametrosCaja := ParametrosCaja;
    Entorno.Preview := PreviewTicket;
    Entorno.Unidades := UnidadesMedida;
    Entorno.EmpresaSesion := UbicacionSesion.Empresa;
    Dependencias := Default(TDependenciasReimpresionCaja);
    Dependencias.TraspasoTicket := FRepositorioTraspasoTicket;
    Dependencias.Tickets := FRepositoriosTicketsCaja;
    Dependencias.LecturasTicket := FLecturasImpresionTicket;
    if not ReimprimirOperacionCaja(
      Entorno,
      Dependencias,
      Operacion,
      ANombreImpresora) then
      ShowMessage_fza(SErrorOperacionSinTicket);
  end;
end;

procedure TfrmConsultaOpe.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
