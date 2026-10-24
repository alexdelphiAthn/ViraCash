{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGen                                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario base de los mantenimientos de ViraCash.                        }
{    Define grid, navegador, edicion CRUD y comportamiento heredable.          }
{******************************************************************************}
unit inMtoGen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxSkinsCore,
  dxSkinsDefaultPainters, cxPC, cxControls, cxScrollBox,
  Vcl.ExtCtrls, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxNavigator, cxDBNavigator, Vcl.StdCtrls, Vcl.Buttons,
  cxContainer, cxEdit, cxLabel, Vcl.Menus, cxButtons,
  dxSkinsLookAndFeelPainter, cxStyles, dxSkinscxPCPainter,
  dxSkinsForm, cxCustomData, cxFilter, cxData, cxDataStorage, dxDateRanges,
  Data.DB, cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridDBDataDefinitions, cxGrid, dxmdaset,
  cxTextEdit, dxBevel, cxImage,
  inLibDevExp, cxGridExportLink, inLibUser, System.UITypes, System.Types,
  inLibPerfilesUsuarioIntf, inLibAnfitrionMtoIntf, Uni, inLibDir,
  inLibDatasets,
  Data.DBCommon, inLibWin,
  UniDataConn, cxBlobEdit, dxCore, dxScrollbarAnnotations, cxRadioGroup,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs, dxSkinBlue,
  cxDBEdit, dxSkinBasic, dxSkinBlack,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, System.Actions, Vcl.ActnList,
  inLibPermisosIntf, inLibVentanaEmbebidaIntf,
  inLibAtributosPaleta,
  inLibGestorFiltrosMto, inLibGestorPerfilesMto,
  inLibGestorGuiasGridMto, inLibGestorTareasMto,
  inLibGestorGuardianBorradoMto,
  inLibGestorArticulosMto, inLibInteraccionDatosIntf,
  inLibMtoGenAplicacionIntf,
  inMtoGenPresentacionFiltrosVcl, inLibVentanaSeparadaVcl;
type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  THackWinControl = class(TWinControl);
  TfrmMtoGen = class(TfrmBase, IMantenimientoEmbebido,
    IVentanaSeparable)
    pButtonPage: TPanel;
    pButtonRightBar: TPanel;
    pButtonBDStat: TPanel;
    pButtonGen: TPanel;
    pnStateDataSet: TPanel;
    lblEditMode: TcxLabel;
    imgIconoPantalla: TcxImage;
    pcPantalla: TcxPageControl;
    tsLista: TcxTabSheet;
    tsFicha: TcxTabSheet;
    btnGrabar: TcxButton;
    btnCancelar: TcxButton;
    cxGrdDBTabPrin: TcxGridDBTableView;
    cxGrdLvPrin: TcxGridLevel;
    cxgrdPrincipal: TcxGrid;
    dsTablaG: TDataSource;
    pnlTopPage: TPanel;
    pnlTopGrid: TPanel;
    sbFiltros: TSpeedButton;
    sbExportExcel: TSpeedButton;
    edtBusqGlobal: TcxTextEdit;
    nvNavegador: TcxDBNavigator;
    lblTextoaBuscar: TcxLabel;
    tsPerfil: TcxTabSheet;
    pnlPerfilTop: TPanel;
    edtPerfilBusq: TcxTextEdit;
    lblTextoaBuscarPerfil: TcxLabel;
    pnlPerfilDetail: TPanel;
    cxgrdPerfil: TcxGrid;
    tvPerfil: TcxGridDBTableView;
    cxgrdlvlPerfil: TcxGridLevel;
    btnCargarColumnas: TcxButton;
    btnCargarCaptions: TcxButton;
    btnCargarVblesGlob: TcxButton;
    tvPerfilUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    tvPerfilKEY_PERFILES: TcxGridDBColumn;
    tvPerfilSUBKEY_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_TEXT_PERFILES: TcxGridDBColumn;
    tvPerfilTYPE_BLOB_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_BLOB_PERFILES: TcxGridDBColumn;
    rbBBDD: TcxRadioButton;
    rbGrid: TcxRadioButton;
    sbGrabarGrid: TSpeedButton;
    sbResetGrid: TSpeedButton;
    sbBestFit: TSpeedButton;
    pnlDataSetName: TPanel;
    lblTablaOrigen: TcxLabel;
    saveDialog: TdxSaveFileDialog;
    pmFiltros: TPopupMenu;
    tmrBusqGlobal: TTimer;
    alMtoGen: TActionList;
    actEliminarRegistro: TAction;
    actRegistroAnterior: TAction;
    actRegistroSiguiente: TAction;
    actInsertarRegistro: TAction;
    actPrimerRegistro: TAction;
    actUltimoRegistro: TAction;
    actEditarRegistro: TAction;
    actGrabarRegistro: TAction;
    actFotoArticulo: TAction;
    actConsultaStock: TAction;
    actRetrocederBloque: TAction;
    actAvanzarBloque: TAction;
    actRefrescar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinDblClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure sbExportExcelClick(Sender: TObject);
    procedure sbFiltrosClick(Sender: TObject);
    procedure btnCargarColumnasClick(Sender: TObject);
    procedure btnCargarCaptionsClick(Sender: TObject);
    procedure btnCargarVblesGlobClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rbGridClick(Sender: TObject);
    procedure rbBBDDClick(Sender: TObject);
    procedure pcPantallaPageChanging(Sender: TObject;
                                     NewPage: TcxTabSheet;
                                     var AllowChange: Boolean);
    procedure sbResetGridClick(Sender: TObject);
    procedure sbBestFitClick(Sender: TObject);
    procedure sbGrabarGridClick(Sender: TObject);
    procedure edtBusqGlobalPropertiesChange(Sender: TObject);
    procedure tmrBusqGlobalTimer(Sender: TObject);
    procedure tsFichaShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSalirClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actEliminarRegistroExecute(Sender: TObject);
    procedure actEliminarRegistroUpdate(Sender: TObject);
    procedure actNavBrowseUpdate(Sender: TObject);
    procedure actRegistroAnteriorExecute(Sender: TObject);
    procedure actRegistroSiguienteExecute(Sender: TObject);
    procedure actInsertarRegistroExecute(Sender: TObject);
    procedure actPrimerRegistroExecute(Sender: TObject);
    procedure actUltimoRegistroExecute(Sender: TObject);
    procedure actEditarRegistroExecute(Sender: TObject);
    procedure actGrabarRegistroExecute(Sender: TObject);
    procedure actGrabarRegistroUpdate(Sender: TObject);
    procedure actFotoArticuloExecute(Sender: TObject);
    procedure actConsultaStockExecute(Sender: TObject);
    procedure actAvanzarBloqueExecute(Sender: TObject);
    procedure actRetrocederBloqueExecute(Sender: TObject);
    procedure actRefrescarExecute(Sender: TObject);
    procedure actRefrescarUpdate(Sender: TObject);
  private
    FConn: TUniConnection;
    FCasoUsoGuardado: ICasoUsoGuardadoMtoGen;
    FGuardianBorrado: TGestorGuardianBorradoMto;
    FGestorFiltros: TGestorFiltrosMto;
    FGestorPerfiles: TGestorPerfilesMto;
    FGestorGuias: TGestorGuiasGridMto;
    FGestorTareas: TGestorTareasMto;
    FGestorArticulos: TGestorArticulosMto;
    FInteraccionFiltros: TInteraccionFiltrosMtoVcl;
    FDesplazamientoBarra: TcxScrollBox;
    FActualizandoAltoBarra: Boolean;
    FBotonesBarra: TArray<TcxButton>;
    FFotoBarra: TControl;
    FVentanaSeparada: TPresentacionVentanaSeparada;
    FCambiandoContenedor: Boolean;
    FConsultandoCierre: Boolean;
    function HayEdicionesPendientes: Boolean;
    procedure InicializarMantenimiento;
    procedure AjustarBarraLateral;
    procedure PrepararDesplazamientoBarraLateral;
    procedure ActualizarAltoBarraLateral(Sender: TObject);
    function AltoMinimoBarra(AContenedor: TWinControl): Integer;
    procedure PrepararDesplazamientoVerticalFichas;
    procedure PrepararPaginaDesplazable(APagina: TcxTabSheet);
    procedure CargarIconoPantalla;
    procedure ConfigurarModoBusqueda;
    function GetConexionTrabajo: TUniConnection;
    function AplicacionCerrando: Boolean;
    function ObtenerConsultaGuias: TUniQuery;
    function FiltroGridActivo: Boolean;
    function FotoArticuloVisible: Boolean;
    function SolicitarDestinoPerfil(
      const ADescripcion: string;
      ADescripcionEditable: Boolean;
      out APermisos: string): Boolean;
    procedure MoverRegistroGridFiltrado(AAvanzar: Boolean);
    procedure InsertarRegistroSinQuedarAMedias;
    procedure NavegadorButtonClick(Sender: TObject;
                                   AButtonIndex: Integer;
                                   var ADone: Boolean);
    procedure OcultarComponentesPorTexto(
      const AFragmentos: array of string);
    procedure CancelarTareasActivas;
    procedure EjecutarModalGuias;
    procedure OcultarFotoArticulo;
    procedure MostrarFotoArticulo(const ACodArt, ACodSku: string);
    procedure VincularFotoArticulo(
      const ADataSources: TArray<TDataSource>);
    procedure MostrarStockArticulo(const ACodArt, ACodSku: string);
  protected
    // Para pantallas cuyo artículo / SKU depende de la pestaña activa:
    // el visor Ctrl+F vuelve a preguntarlo si sigue a este Mto.
    procedure RefrescarFotoArticulo;
  private
    procedure ResetearGridPerfil(
      const ANombreGrid, ANombreFormulario, APermisos: string);
    function ControlConFoco: TWinControl;
    function FocoEnRejillaSecundaria(AControl: TWinControl): Boolean;
    function FocoEnRejilla(AControl: TWinControl): Boolean;
    function HayDetalleEnEdicion: Boolean;
    procedure CMDialogChar(var Message: TCMDialogChar);
      message CM_DIALOGCHAR;
    function CampoObligatorioDeDataSet(E: Exception;
      ADataSet: TDataSet): TField;
    function CampoObligatorioSinValor(E: Exception): TField;
    function ColumnaDeCampo(ACampo: TField): TcxGridDBColumn;
    function ControlDeCampo(ACampo: TField): TWinControl;
    function EtiquetaCampo(ACampo: TField): string;
    procedure MostrarControl(AControl: TWinControl);
    procedure EnfocarCampo(ACampo: TField);
    function FocoEnEditorTexto: Boolean;
    function PuedeCambiarRegistroPorTecla: Boolean;
    procedure MoverFocoGridBloque(AAvanzar: Boolean);
    procedure ActivarFichaDesdeDM(Sender: TObject);
    procedure NotificarMensajeDesdeDM(Sender: TObject;
      const AMensaje: string; ASeveridad: TSeveridadMensajeDatos);
    function ConfirmarMensajeDesdeDM(Sender: TObject;
      const AMensaje: string): Boolean;
  protected
    FAnfitrionMto: IAnfitrionMantenimiento;
    FProveedorMenu: IProveedorMenuPantallas;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WndProc(var Message: TMessage); override;
    procedure DoShow; override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure Activate; override;
    function ConfirmarCierreConCambios: Integer; virtual;
    property ConexionTrabajo: TUniConnection read GetConexionTrabajo;
    function PermitirNavegacionTeclas: Boolean; virtual;
    function HandleCreateException: Boolean; override;
    procedure BloquearTabPorOcupado(Bloquear: Boolean);
    function PuedeAccionMto(AAccion: TAccionPermisoMto): Boolean;
    // Si E es un campo obligatorio vacío, le da el foco y lanza el aviso
    // de validación que lo nombra; si no, no hace nada (FZ-ISSUE-623).
    procedure AvisarSiCampoObligatorio(E: Exception);
    // Crea la conexión propia del Mto si aún no existe. CrearTablaPrincipal
    // la crea cuando el catálogo resuelve el data module; la pantalla que
    // crea el suyo en código la pide antes de usar ConexionTrabajo
    // (FZ-ISSUE-536).
    procedure AsegurarConexionTrabajo;
  public
    tdmDataModule:TObject;
    sDataModuleName:string;
    oPerfilDic : TProfileDicc;
    sUso:string;
    pkFieldName:string;
    tsFichCab:TcxTabSheet;
    tsFichBut:TcxTabSheet;
    EsInstanciaBusqueda: Boolean;
    function CloseQuery: Boolean; override;
    procedure ConfigurarVentanaGestionada(
      const AConfiguracion: TConfiguracionVentanaGestionada);
    procedure CambiarContenedor(ACambiando: Boolean);
    procedure UpdateActions; override;
    procedure SimulateTabKey;
    procedure ProcesarPerfiles;
    // inLibContratoMtoGenHerencia define el orden de todos estos hooks.
    procedure AplicarEtiquetas;     virtual;
    procedure AplicarTraduccionActual; override;
    procedure CrearTablaPrincipal;  virtual;
    procedure ResetForm;  virtual;
    procedure AplicarPermisosPantalla;
    function PuedeImprimir: Boolean;
    function PuedeExportar: Boolean;
    procedure AbrirPerfiles(bTabVisible:Boolean);
    procedure CargarPerfilesParticulares; virtual;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); virtual;
    procedure PrepararBusquedaExterna(const ABusq: string); virtual;
    function InterceptarCierre: Boolean; virtual;
    procedure ActivarModoBusqueda(AAplicarLayout: Boolean);
    procedure DesactivarModoBusqueda;
    procedure AbrirTablaPrincipal(ASincrono: Boolean);
    function LocalizarYEnfocar(const ABusq: string): Boolean;
    function PrepararPrecarga(
      ARol: TRolAperturaMantenimiento): Boolean; virtual;
    procedure AplicarLayoutInstanciaBusqueda; virtual;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); virtual;
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; virtual;
    function NombreCampoESACTIVO: string; virtual;
    function ContarHijosActivos: Integer; virtual;
    function DescripcionHijos: string; virtual;
    procedure EjecutarEnBackground(AccionBG: TProc;
                                   AlTerminar: TProc<string>);
    procedure AbrirTablaPrincipalAsync;
    procedure AbrirTablaPrincipalSincrono;
    procedure TrasPrecargaAsync; virtual;
    procedure TrasErrorPrecargaAsync(const AError: string); virtual;
    function SqlRestriccionUsuario: string; virtual;
  public
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl, inLibErroresBBDD,
  inLibEnterComoTabDesplegables,
  inLibData,
     inLibConexionesIntf,
     inLibUnitForm,
     inLibShowMto,

     UniDataGen, UniDataNumeracionDocumentos, uGenericIfThen,
     UniDataGuiasGridRepositorio,
     UniDataPerfilesMtoRepositorio,
     inMtoFotoArticulo, inMtoStockConsulta,
     inMtoModalGridGuias,
     inMtoGenPresentacionPerfilesVcl,
     System.Diagnostics,    // TStopwatch para cronometrar carga inicial
     System.TypInfo, inLibDiag,
  inLibMsgComun, inLibMsgConfiguracion, inLibMenuIconos,
  inLibExcepcionesAplicacionIntf;

function TfrmMtoGen.GetConexionTrabajo: TUniConnection;
begin
  Result := FConn;
  if not Assigned(Result) then
    raise Exception.Create(SErrorConexionTrabajoNoDisponible);
end;

procedure TfrmMtoGen.AsegurarConexionTrabajo;
begin
  if FConn = nil then
  try
    if not Assigned(Conexiones) then
      raise Exception.Create(SErrorServicioConexionesNoDisponible);
    FConn := Conexiones.CrearConexion(
      Self,
      uctMantenimiento);
    if not Assigned(FConn) then
      raise Exception.Create(SErrorConexionTrabajoNoDisponible);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarError('No se pudo crear conexión propia para ' +
        Self.Name + ': ' + E.Message);
      FConn := nil;
      // FZ-ISSUE-337: el pool agotado también es un límite de conexiones:
      // el aviso pide cerrar pantallas en vez del texto de UniDAC.
      raise EConexionMantenimientoBBDD.Create(E.Message,
        (E is ELimiteConexionesBBDD) or
        EsAgotamientoPoolConexiones(E.Message));
    end;
  end;
end;

function TfrmMtoGen.AplicacionCerrando: Boolean;
begin
  Result := ContextoSesion.CerrandoAplicacion;
end;

procedure TfrmMtoGen.CancelarTareasActivas;
begin
  if (tdmDataModule <> nil) and
     (tdmDataModule is TdmBase) then
    TdmBase(tdmDataModule).CancelarEjecucionActiva;
end;

function TfrmMtoGen.FotoArticuloVisible: Boolean;
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  Result := (FormularioFoto <> nil) and FormularioFoto.Visible;
end;

procedure TfrmMtoGen.OcultarFotoArticulo;
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  if FormularioFoto <> nil then
    FormularioFoto.Hide;
end;

procedure TfrmMtoGen.MostrarFotoArticulo(const ACodArt, ACodSku: string);
begin
  MostrarFotoFlotante(Self, ACodArt, ACodSku);
end;

procedure TfrmMtoGen.VincularFotoArticulo(
  const ADataSources: TArray<TDataSource>);
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  if FormularioFoto <> nil then
    FormularioFoto.VincularDataSources(ADataSources,
      ResolverArtSkuActivo);
end;

procedure TfrmMtoGen.RefrescarFotoArticulo;
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  if (FormularioFoto <> nil) and FormularioFoto.Visible then
    FormularioFoto.RefrescarDesdePadre(Self);
end;

procedure TfrmMtoGen.MostrarStockArticulo(const ACodArt, ACodSku: string);
begin
  inMtoStockConsulta.MostrarStockConsulta(ACodArt, ACodSku);
end;

function TfrmMtoGen.ObtenerConsultaGuias: TUniQuery;
begin
  Result := nil;
  if (tdmDataModule <> nil) and
     (tdmDataModule is TdmBase) then
    Result := TdmBase(tdmDataModule).unqryTablaG
  else if Assigned(dsTablaG) and
          Assigned(dsTablaG.DataSet) and
          (dsTablaG.DataSet is TUniQuery) then
    Result := TUniQuery(dsTablaG.DataSet);
end;

procedure TfrmMtoGen.AbrirPerfiles(bTabVisible:Boolean);
begin
  if tdmDataModule <> nil then
  begin
    tvPerfil.DataController.DataSource :=
      (tdmDataModule as TdmBase).dsPerfiles;
    FGestorPerfiles.AbrirPerfiles(
      bTabVisible,
      (tdmDataModule as TdmBase).Name);
  end;
end;

procedure TfrmMtoGen.AplicarEtiquetas;
begin
  FGestorPerfiles.AplicarEtiquetas;
  if Assigned(Traducciones) then
    Traducciones.Aplicar(Self);
end;

procedure TfrmMtoGen.btnCargarCaptionsClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.CargarCaptions;
end;

procedure TfrmMtoGen.btnCargarColumnasClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.CargarColumnas;
end;

procedure TfrmMtoGen.btnCargarVblesGlobClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.CargarPerfilesComunes;
  CargarPerfilesParticulares;
end;

procedure TfrmMtoGen.btnGrabarClick(Sender: TObject);
var
  Resultado: TResultadoGuardadoMtoGen;
  Ediciones: TEdicionesDataSetsPendientes;
  bTransaccionExterior: Boolean;
  Serie, MensajeBloqueo: string;
  i: Integer;
begin
  inherited;
  if tdmDataModule <> nil then
  begin
    FGuardianBorrado.ComprobarPermisoGrabar(dsTablaG.State);
    if FCasoUsoGuardado = nil then
      FCasoUsoGuardado := CrearCasoUsoGuardadoMtoGenUniDAC(
        ConexionTrabajo);
    bTransaccionExterior := ConexionTrabajo.InTransaction;
    Ediciones := CapturarEdicionesDataSets(tdmDataModule as TDataModule);
    Serie := '';
    for i := 0 to dsTablaG.DataSet.FieldCount - 1 do
      if (Serie = '') and
         (Pos('SERIE_', dsTablaG.DataSet.Fields[i].FieldName) = 1) then
        Serie := dsTablaG.DataSet.Fields[i].AsString;
    Screen.Cursor := crHourGlass;
    try
      try
        Resultado := rgmAbortado;
        EjecutarConReintentoBloqueoBBDD(
          procedure
          begin
            try
              EjecutarConEsperaBloqueoCorta(ConexionTrabajo,
                procedure
                begin
                  EjecutarConRecuperacionNumeracion(ConexionTrabajo,
                    procedure
                    begin
                      Resultado := FCasoUsoGuardado.Ejecutar(
                        procedure
                        begin
                          GrabarDatasets(tdmDataModule as TDataModule);
                          TdmBase(tdmDataModule).AplicarCambiosDiferidos;
                        end);
                    end,
                    procedure
                    begin
                      RestaurarEdicionesDataSets(Ediciones);
                    end);
                end, TdmBase(tdmDataModule).RegistroLog);
            except
              on E: Exception do
              begin
                TdmBase(tdmDataModule).RestaurarCambiosDiferidos;
                if E is EBloqueoBBDDTemporal then
                begin
                  // La transaccion exterior pertenece al llamador.
                  if bTransaccionExterior then
                    raise Exception.Create(E.Message);
                end;
                if (E is EBloqueoBBDDTemporal) or
                   TdmBase(tdmDataModule).UsaCambiosDiferidos then
                  RestaurarEdicionesDataSets(Ediciones);
                raise;
              end;
            end;
          end,
          function: Boolean
          begin
            if Trim(Serie) = '' then
              MensajeBloqueo := SAvisoDatosOcupados
            else
              MensajeBloqueo := Format(SAvisoSerieOcupada, [Serie]);
            Result := MessageDlg_fza(MensajeBloqueo,
              mtWarning, [mbRetry, mbCancel], 0, mbRetry) = mrRetry;
          end);
        if Resultado = rgmGuardado then
        begin
          if not bTransaccionExterior then
            TdmBase(tdmDataModule).ConfirmarCambiosDiferidos;
          ShowMessage_fza(SInfoDatosGuardados);
        end
        else if TdmBase(tdmDataModule).UsaCambiosDiferidos then
        begin
          TdmBase(tdmDataModule).RestaurarCambiosDiferidos;
          RestaurarEdicionesDataSets(Ediciones);
        end;
      except
        on E: Exception do
        begin
          // Un campo obligatorio vacío es un aviso con el foco en el campo,
          // no un error del programa (FZ-ISSUE-623).
          AvisarSiCampoObligatorio(E);
          // Una validación de datos se relanza tal cual para que el gestor
          // global la muestre como aviso y no como error (FZ-ISSUE-120).
          if EsValidacionAplicacionEsperada(E) then
            raise;
          raise Exception.Create(Format(SErrorGrabarDatos, [E.Message]));
        end;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoGen.btnSalirClick(Sender: TObject);
begin
  inherited;
  Close;
end;

function TfrmMtoGen.CloseQuery: Boolean;
var
  oModulo: TDataModule;
  oPrincipal: TDataSet;
  iRespuesta: Integer;
begin
  Result := not FConsultandoCierre;
  if Result then
  begin
    FConsultandoCierre := True;
    try
      Result := inherited CloseQuery;
      if Result and HayEdicionesPendientes then
      begin
        iRespuesta := ConfirmarCierreConCambios;
        Result := iRespuesta <> mrCancel;
        if iRespuesta = mrYes then
        begin
          btnGrabarClick(Self);
          Result := not HayEdicionesPendientes;
        end
        else if iRespuesta = mrNo then
        begin
          oModulo := nil;
          if tdmDataModule is TDataModule then
            oModulo := TDataModule(tdmDataModule);
          oPrincipal := nil;
          if Assigned(dsTablaG) then
            oPrincipal := dsTablaG.DataSet;
          CancelarDatasets(oModulo, oPrincipal);
        end;
      end;
    finally
      FConsultandoCierre := False;
    end;
  end;
end;

function TfrmMtoGen.HayEdicionesPendientes: Boolean;
begin
  Result := Assigned(dsTablaG) and Assigned(dsTablaG.DataSet) and
    (dsTablaG.DataSet.State in [dsEdit, dsInsert]);
  if not Result and (tdmDataModule is TDataModule) then
    Result := CheckOpenDatasets(TDataModule(tdmDataModule));
end;

function TfrmMtoGen.ConfirmarCierreConCambios: Integer;
begin
  Result := MessageDlg_fza(
    Format(SPreguntaCerrarPantallaConCambios, [Caption]),
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);
end;

procedure TfrmMtoGen.ConfigurarVentanaGestionada(
  const AConfiguracion: TConfiguracionVentanaGestionada);
begin
  if not Assigned(FVentanaSeparada) then
    FVentanaSeparada := TPresentacionVentanaSeparada.Create;
  FVentanaSeparada.Configurar(AConfiguracion);
end;

procedure TfrmMtoGen.CambiarContenedor(ACambiando: Boolean);
begin
  FCambiandoContenedor := ACambiando;
end;

procedure TfrmMtoGen.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if Assigned(FVentanaSeparada) then
    FVentanaSeparada.PrepararParametros(Params);
end;

procedure TfrmMtoGen.CreateWnd;
begin
  inherited;
  if Assigned(FVentanaSeparada) then
    FVentanaSeparada.CrearManejador(Handle);
end;

procedure TfrmMtoGen.DestroyWnd;
begin
  if Assigned(FVentanaSeparada) then
    FVentanaSeparada.DestruirManejador(Handle);
  inherited;
end;

procedure TfrmMtoGen.WndProc(var Message: TMessage);
begin
  if not (HandleAllocated and Assigned(FVentanaSeparada) and
    FVentanaSeparada.ProcesarMensaje(Handle, Message)) then
    inherited;
end;

procedure TfrmMtoGen.DoShow;
begin
  // Cambiar de contenedor conserva la pantalla: OnShow no debe volver a
  // cargar perfiles, consultas o valores iniciales de sus descendientes.
  if not FCambiandoContenedor then
    inherited;
end;

procedure TfrmMtoGen.Activate;
begin
  inherited;
  if not FCambiandoContenedor and Assigned(FVentanaSeparada) and
     FVentanaSeparada.EstaSeparada then
  begin
    PestanaActivada;
    if Assigned(FAnfitrionMto) then
      FAnfitrionMto.VincularFotoMantenimiento(Self);
  end;
end;

procedure TfrmMtoGen.DoClose(var Action: TCloseAction);
begin
  if Assigned(FVentanaSeparada) and
     FVentanaSeparada.SolicitarCierre then
    Action := caNone
  else
    inherited;
end;

procedure TfrmMtoGen.sbGrabarGridClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.GrabarLayout(
    'Grabar Grids');
end;

procedure TfrmMtoGen.sbResetGridClick(Sender: TObject);
begin
  inherited;
  FGestorPerfiles.ResetearLayout('Reset Grids');
end;

procedure TfrmMtoGen.sbBestFitClick(Sender: TObject);
const
  ANCHO_MIN_SISTEMA_TALLAS_96_DPI = 270;

  procedure AjustarGrid(AGrid: TcxCustomGrid);
  var
    iVista, iItem: Integer;
    oVista: TcxCustomGridTableView;
    oItem: TcxGridColumn;
  begin
    for iVista := 0 to AGrid.ViewCount - 1 do
    begin
      if AGrid.Views[iVista] is TcxCustomGridTableView then
      begin
        oVista := TcxCustomGridTableView(AGrid.Views[iVista]);
        oVista.BeginUpdate;
        try
          AplicarBestFitConMargen(oVista);

          // ApplyBestFit solo mide el texto. Las columnas Color pintan antes
          // un cuadradito que tambien necesita espacio; el evento de dibujo
          // puede estar asociado a la columna o a la vista, por lo que las
          // identificamos por nombre/caption y no por OnCustomDrawCell.
          for iItem := 0 to oVista.ItemCount - 1 do
          begin
            if (oVista.Items[iItem] is TcxGridColumn) and
               oVista.Items[iItem].ActuallyVisible and
               not oVista.IsPattern and
               TcxCustomGridTableItemAccess.CanHorzSize(
                 oVista.Items[iItem]) then
            begin
              oItem := TcxGridColumn(oVista.Items[iItem]);
              if (Pos('COLOR', UpperCase(oItem.Name)) > 0) or
                 SameText(Trim(oItem.Caption), 'Color') then
                oItem.Width := oItem.Width + ANCHO_SWATCH_PX;

              // En varias vistas el campo guarda el identificador y el texto
              // mostrado (p. ej. "Calzado Mujer EU 39-44") se resuelve en el
              // editor. ApplyBestFit mide el ID y deja la columna demasiado
              // estrecha, por lo que conservamos un minimo legible escalado.
              if SameText(Trim(oItem.Caption), 'Sistema tallas') and
                 (oItem.Width < MulDiv(ANCHO_MIN_SISTEMA_TALLAS_96_DPI,
                   CurrentPPI, USER_DEFAULT_SCREEN_DPI)) then
                oItem.Width := MulDiv(ANCHO_MIN_SISTEMA_TALLAS_96_DPI,
                  CurrentPPI, USER_DEFAULT_SCREEN_DPI);
            end;
          end;
        finally
          oVista.EndUpdate;
        end;

        // ApplyBestFit conserva la posicion horizontal anterior. Volvemos a
        // mostrar la primera columna visible para que el usuario no pierda el
        // inicio de la rejilla tras pulsar el boton <->.
        for iItem := 0 to oVista.ItemCount - 1 do
          if oVista.Items[iItem].ActuallyVisible then
          begin
            oVista.Controller.MakeItemVisible(oVista.Items[iItem]);
            Break;
          end;
      end;
    end;
  end;

  procedure RecorrerControles(AContenedor: TWinControl);
  var
    iControl: Integer;
    oControl: TControl;
  begin
    for iControl := 0 to AContenedor.ControlCount - 1 do
    begin
      oControl := AContenedor.Controls[iControl];
      if oControl is TcxCustomGrid then
        AjustarGrid(TcxCustomGrid(oControl));

      // Tambien entra en frames y paneles. Las paginas que no estan activas
      // siguen formando parte del arbol y, por tanto, se ajustan igualmente.
      if oControl is TWinControl then
        RecorrerControles(TWinControl(oControl));
    end;
  end;
begin
  // Recorremos el arbol visual completo, no solo Components de este form.
  // Esto incluye grids alojados en frames, paneles y pestanas de detalle, y
  // las vistas creadas en ejecucion cuyo Owner es el propio TcxGrid.
  RecorrerControles(Self);
end;

procedure TfrmMtoGen.tsFichaShow(Sender: TObject);
var
  FocusControl: TWinControl;
  function FindNextFocusableControl(AParent: TWinControl): TWinControl;
  var
    I: Integer;
    Control: TControl;
    MinTabOrder: Integer;
  begin
    Result := nil;
    MinTabOrder := High(Integer);
    for I := 0 to AParent.ControlCount - 1 do
    begin
      Control := AParent.Controls[I];
      if (Control is TWinControl) and
         not (Control is TPanel) and          // Excluir TPanels
         not (Control is TcxPageControl) and  // Excluir TcxPageControl
         not (Control is TcxTabSheet) and     // Excluir TcxTabSheet
         TWinControl(Control).CanFocus and
         (TWinControl(Control).TabOrder > AParent.TabOrder) and
         (TWinControl(Control).TabOrder < MinTabOrder) then
      begin
        Result := TWinControl(Control);
        MinTabOrder := Result.TabOrder;
      end;
      if (Control is TWinControl) and
         (TWinControl(Control).ControlCount > 0) then
      begin
        Control := FindNextFocusableControl(TWinControl(Control));
        if Assigned(Control) and
           (TWinControl(Control).TabOrder > AParent.TabOrder) and
           (TWinControl(Control).TabOrder < MinTabOrder) then
        begin
          Result := TWinControl(Control);
          MinTabOrder := Result.TabOrder;
        end;
      end;
    end;
  end;
begin
    FGuardianBorrado.Instalar;
    FocusControl := FindNextFocusableControl(tsFicha);
    if Assigned(FocusControl) then
    begin
      if FocusControl.CanFocus then
      begin
        FocusControl.SetFocus;
      end;
    end;
end;

procedure TfrmMtoGen.OcultarComponentesPorTexto(
  const AFragmentos: array of string);
var
  i: Integer;
  j: Integer;
  sTexto: string;
  bCoincide: Boolean;
  function TextoPublicado(AComponente: TComponent;
                          const APropiedad: string): string;
  begin
    Result := '';
    if IsPublishedProp(AComponente, APropiedad) then
      Result := GetStrProp(AComponente, APropiedad);
  end;
begin
  for i := 0 to Self.ComponentCount - 1 do
  begin
    sTexto := Self.Components[i].Name + ' ' +
              TextoPublicado(Self.Components[i], 'Caption') + ' ' +
              TextoPublicado(Self.Components[i], 'Hint');
    sTexto := LowerCase(sTexto);
    sTexto := StringReplace(sTexto, '&', '', [rfReplaceAll]);
    sTexto := StringReplace(sTexto, '.', '', [rfReplaceAll]);
    bCoincide := False;
    for j := Low(AFragmentos) to High(AFragmentos) do
      if Pos(LowerCase(AFragmentos[j]), sTexto) > 0 then
        bCoincide := True;
    if bCoincide then
    begin
      if Self.Components[i] is TControl then
        TControl(Self.Components[i]).Visible := False
      else if Self.Components[i] is TCustomAction then
        TCustomAction(Self.Components[i]).Enabled := False
      else if Self.Components[i] is TMenuItem then
      begin
        TMenuItem(Self.Components[i]).Visible := False;
        TMenuItem(Self.Components[i]).Enabled := False;
      end;
    end;
  end;
end;

function TfrmMtoGen.PuedeAccionMto(
  AAccion: TAccionPermisoMto): Boolean;
var
  sCall: string;
begin
  sCall := '';
  if Assigned(FAnfitrionMto) then
    sCall := ResolverCallPantallaPorJerarquia(
      FAnfitrionMto, Self.ClassType);
  if sCall = '' then
    Result := True
  else
    Result := Assigned(Permisos) and
              Permisos.TienePermiso(
                CodigoPermisoMto(sCall, AAccion),
                PermisoAusenteCodigo(CodigoPermisoMto(sCall, AAccion)));
end;

procedure TfrmMtoGen.CargarPerfilesParticulares;
begin
  if (tdmDataModule <> nil) then
    GrabarPerfilDatam(
      tdmDataModule as TdmBase,
      Self.Owner,
      PerfilesEscritura);
end;

procedure TfrmMtoGen.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                 const sPermisos: string);
begin
end;

procedure TfrmMtoGen.ResetearGridPerfil(
  const ANombreGrid, ANombreFormulario, APermisos: string);
begin
  if not Assigned(PerfilesEscritura) then
    raise Exception.Create(
      SErrorServicioPerfilesUsuarioNoConfigurado);
  PerfilesEscritura.EliminarPerfil(
    APermisos, ANombreFormulario);
end;

procedure TfrmMtoGen.PrepararBusquedaExterna(const ABusq: string);
begin
  if (ABusq <> '') and (pkFieldName <> '') and
     (tdmDataModule is TdmBase) then
    TdmBase(tdmDataModule).PrepararBusquedaExterna(
      pkFieldName,
      ABusq);
end;

// Precarga opcional antes del primer Open. Sin precarga no hay nada
// que preparar y la apertura sigue adelante.
function TfrmMtoGen.PrepararPrecarga(
  ARol: TRolAperturaMantenimiento): Boolean;
begin
  Result := True;
end;

// La primera pulsacion de cierre desde la ficha vuelve a la lista; el
// gestor de ventanas pregunta por esta interfaz en vez de conocer la
// clase (antes ese if vivia en inLibFormManager con un cast directo).
function TfrmMtoGen.InterceptarCierre: Boolean;
begin
  Result := False;
  if pcPantalla.ActivePage = tsFicha then
  begin
    pcPantalla.ActivePage := tsLista;
    Result := True;
  end;
end;

procedure TfrmMtoGen.ActivarModoBusqueda(AAplicarLayout: Boolean);
begin
  EsInstanciaBusqueda := True;
  if AAplicarLayout then
    AplicarLayoutInstanciaBusqueda;
end;

procedure TfrmMtoGen.DesactivarModoBusqueda;
begin
  EsInstanciaBusqueda := False;
end;

procedure TfrmMtoGen.AbrirTablaPrincipal(ASincrono: Boolean);
begin
  if ASincrono then
    AbrirTablaPrincipalSincrono
  else
    AbrirTablaPrincipalAsync;
end;

// False SOLO si se busco y no se encontro (inLibShowMto avisa entonces
// al usuario); True si se encontro o si no procedia buscar.
function TfrmMtoGen.LocalizarYEnfocar(const ABusq: string): Boolean;
begin
  Result := True;
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    Result := BuscarTabla(TdmBase(tdmDataModule).unqryTablaG,
                          pkFieldName, ABusq);
    if Result then
    begin
      if (tsFicha <> nil) and tsFicha.TabVisible then
        pcPantalla.ActivePage := tsFicha;
      if CanFocus then
        SetFocus;
    end;
  end;
end;

procedure TfrmMtoGen.AplicarLayoutInstanciaBusqueda;
begin
  // Lista: la instancia de busqueda llega directa a la Ficha del registro
  // localizado, no se navega por el grid. Las pantallas sin ficha (p. ej.
  // el historico de vales) se quedan en la lista, ya filtrada por la clave:
  // ocultarla dejaba el control de pestanas sin ninguna visible, en blanco.
  if tsFicha.TabVisible then
    tsLista.TabVisible := False
  else
    pcPantalla.ActivePage := tsLista;
  // Busqueda global: el filtro ya viene impuesto por PrepararBusquedaExterna.
  edtBusqGlobal.Visible    := False;
  lblTextoaBuscar.Visible  := False;
  rbBBDD.Visible           := False;
  rbGrid.Visible           := False;
  // Exportar a Excel y botones de configuracion de grid: no aplican sin
  // grid visible. Las shortcuts Alt+F12/Ctrl+F12/Ctrl+F10 siguen vivas en
  // FormKeyDown — disparan los handlers sin necesidad del boton visible.
  sbExportExcel.Visible := False;
  sbGrabarGrid.Visible  := False;
  sbResetGrid.Visible   := False;
  sbBestFit.Visible     := False;
  // Navegador reducido a Insert/Delete/Edit/Post/Cancel.
  nvNavegador.Buttons.First.Visible        := False;
  nvNavegador.Buttons.PriorPage.Visible    := False;
  nvNavegador.Buttons.Prior.Visible        := False;
  nvNavegador.Buttons.Next.Visible         := False;
  nvNavegador.Buttons.NextPage.Visible     := False;
  nvNavegador.Buttons.Last.Visible         := False;
  nvNavegador.Buttons.Insert.Visible       := True;
  nvNavegador.Buttons.Append.Visible       := False;
  nvNavegador.Buttons.Delete.Visible       := True;
  nvNavegador.Buttons.Edit.Visible         := True;
  nvNavegador.Buttons.Post.Visible         := True;
  nvNavegador.Buttons.Cancel.Visible       := True;
  nvNavegador.Buttons.Refresh.Visible      := False;
  nvNavegador.Buttons.SaveBookmark.Visible := False;
  nvNavegador.Buttons.GotoBookmark.Visible := False;
  nvNavegador.Buttons.Filter.Visible       := False;
  // Re-aplicar permisos de pantalla: este metodo acaba de volver a mostrar
  // Insert/Delete/Edit/Post, asi que hay que ocultarlos de nuevo si el
  // usuario no tiene insertar/modificar/borrar.
  AplicarPermisosPantalla;
end;

// El TdmBase avisa al insertar en la tabla principal; el form decide
// la pestania (antes TdmBase tocaba pcPantalla/tsFicha directamente).
procedure TfrmMtoGen.ActivarFichaDesdeDM(Sender: TObject);
begin
  if tsFicha.TabVisible then
    pcPantalla.ActivePage := tsFicha;
end;

procedure TfrmMtoGen.NotificarMensajeDesdeDM(Sender: TObject;
  const AMensaje: string; ASeveridad: TSeveridadMensajeDatos);
var
  eTipoDialogo: TMsgDlgType;
begin
  case ASeveridad of
    smdInformacion:
      eTipoDialogo := mtInformation;
    smdAdvertencia:
      eTipoDialogo := mtWarning;
  else
    eTipoDialogo := mtError;
  end;
  MessageDlg_fza(AMensaje, eTipoDialogo, [mbOk], 0);
end;

function TfrmMtoGen.ConfirmarMensajeDesdeDM(Sender: TObject;
  const AMensaje: string): Boolean;
begin
  Result := MessageDlg_fza(
    AMensaje, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmMtoGen.CrearTablaPrincipal;
var
  sNameModule: string;
  swTotal, swTramo: TStopwatch;
  msCrearDM, msFConn, msReasignar: Int64;
begin
  swTotal := TStopwatch.StartNew;
  msCrearDM := 0; msFConn := 0; msReasignar := 0;
  tdmDataModule := nil;
  sNameModule := '';
  // Los proyectos independientes no implementan el contrato anfitrión.
  if Assigned(FAnfitrionMto) then
    sNameModule := ResolverDataModulePantallaPorJerarquia(
      FAnfitrionMto, Self.ClassType);
  if (sNameModule <> '') then
  begin
    swTramo := TStopwatch.StartNew;
    tdmDataModule := CrearDataModule(sNameModule, Self);
    msCrearDM := swTramo.ElapsedMilliseconds;
    if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
    begin
      // Cableado que antes hacia inLibShowMto.CrearDataModule tocando
      // este form: ahora el form se cablea a si mismo.
      TdmBase(tdmDataModule).FCurrentForm := Self;
      if Assigned(dsTablaG) then
        dsTablaG.DataSet := TdmBase(tdmDataModule).unqryTablaG;
      if FGestorPerfiles.Valor(
           'oGetSQLFromDB', 'False') = 'True' then
      begin
        GetFormUserProfile(TdmBase(tdmDataModule).FoPerfilDic,
                           TdmBase(tdmDataModule).Name,
                           PerfilesLectura);
        LoadSQLFromProfile(TdmBase(tdmDataModule),
                           TdmBase(tdmDataModule).FoPerfilDic);
      end;
    end;
    // La conexión persistente dmConn.conUni mantiene operativos los DFM en
    // diseño. En ejecución el servicio crea la conexión propia del Mto y se
    // inyecta antes de abrir la tabla principal.
    swTramo := TStopwatch.StartNew;
    AsegurarConexionTrabajo;
    msFConn := swTramo.ElapsedMilliseconds;
    if Assigned(FConn) then
    begin
      swTramo := TStopwatch.StartNew;
      (tdmDataModule as TdmBase).ReasignarConexion(FConn);
      msReasignar := swTramo.ElapsedMilliseconds;
    end;
    if Assigned(tdmDataModule) then
    begin
      FGestorGuias.AsignarPersistencia(
        CrearPersistenciaGuiasGridUniDAC(
          ConexionTrabajo));
      FGestorPerfiles.AsignarPersistencia(
        CrearPersistenciaPerfilesMtoUniDAC(
          ConexionPrincipal,
          ConexionTrabajo,
          TdmBase(tdmDataModule).unqryPerfiles));
      // El DM ya no busca dsTablaG con GetOwnerForm: el form empuja el
      // maestro y se suscribe al aviso de insercion (misma pauta que
      // TdmFacturas en la Fase 3).
      (tdmDataModule as TdmBase).AsignarMaestroCabecera(dsTablaG);
      (tdmDataModule as TdmBase).OnActivarFicha := ActivarFichaDesdeDM;
      (tdmDataModule as TdmBase).OnNotificarMensaje :=
        NotificarMensajeDesdeDM;
      (tdmDataModule as TdmBase).OnConfirmarMensaje :=
        ConfirmarMensajeDesdeDM;
    end;
  end;
  inherited;
  RegistroLog.RegistrarRendimiento(Self.Name + '.CrearTablaPrincipal',
    Format('CrearDM=%d ms | FConn.Connect=%d ms | ReasignarConexion=%d ms',
           [msCrearDM, msFConn, msReasignar]),
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.AplicarPermisosPantalla;
var
  sCall: string;
begin
  FGuardianBorrado.Instalar;
  // CALL de la pantalla (Clientes, Articulos...). Los Mtos sin registro
  // en fza_winforms (p.ej. cajas de busqueda) no tienen CALL: todo activo.
  sCall := '';
  if Assigned(FAnfitrionMto) then
    sCall := ResolverCallPantallaPorJerarquia(
      FAnfitrionMto, Self.ClassType);
  if sCall <> '' then
  begin
    // Consultar/buscar: solo se quita el buscador global. NO se bloquea la
    // apertura ni la carga, asi se puede llegar a una ficha navegando
    // desde otro Mto (Ctrl+R, ir a factura...).
    if not PuedeAccionMto(apmConsultar) then
    begin
      edtBusqGlobal.Visible   := False;
      lblTextoaBuscar.Visible := False;
      rbBBDD.Visible          := False;
      rbGrid.Visible          := False;
    end;
    // Alta. Enabled:=False en la accion neutraliza tambien su atajo.
    if not PuedeAccionMto(apmInsertar) then
    begin
      actInsertarRegistro.Enabled        := False;
      nvNavegador.Buttons.Insert.Visible := False;
      nvNavegador.Buttons.Append.Visible := False;
    end;
    // Modificacion.
    if not PuedeAccionMto(apmModificar) then
    begin
      actEditarRegistro.Enabled        := False;
      actGrabarRegistro.Enabled        := False;
      nvNavegador.Buttons.Edit.Visible := False;
      nvNavegador.Buttons.Post.Visible := False;
    end;
    // Borrado.
    if not PuedeAccionMto(apmBorrar) then
    begin
      actEliminarRegistro.Enabled        := False;
      nvNavegador.Buttons.Delete.Visible := False;
    end;
    // Exportar a Excel.
    if not PuedeExportar then
    begin
      sbExportExcel.Visible := False;
      OcultarComponentesPorTexto(['export', 'exp excel']);
    end;
    // Impresion.
    if not PuedeImprimir then
      OcultarComponentesPorTexto(['imprim', 'print', 'pegatin']);
  end;
end;

function TfrmMtoGen.PuedeImprimir: Boolean;
begin
  Result := PuedeAccionMto(apmImprimir);
end;

function TfrmMtoGen.PuedeExportar: Boolean;
begin
  Result := PuedeAccionMto(apmExcel);
end;

procedure TfrmMtoGen.BloquearTabPorOcupado(Bloquear: Boolean);
begin
  FGestorTareas.Bloquear(Bloquear);
end;

procedure TfrmMtoGen.EjecutarEnBackground(AccionBG: TProc;
                                          AlTerminar: TProc<string>);
begin
  FGestorTareas.Ejecutar(AccionBG, AlTerminar);
end;

procedure TfrmMtoGen.AbrirTablaPrincipalAsync;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  yaActiva: Boolean;
  bSinError: Boolean;
begin
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    dmDat := TdmBase(tdmDataModule);
    unqry := dmDat.unqryTablaG;
    if unqry <> nil then
    begin
  if dmDat.AplicarRestriccionUsuario(SqlRestriccionUsuario) then
    RegistroLog.RegistrarInformacion(Self.Name +
      ': precarga restringida por usuario (appRestringirEmpAlmCaja)');
  yaActiva := unqry.Active;
  if (not yaActiva) and Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  unqry.DisableControls;
  sw := TStopwatch.StartNew;
  EjecutarEnBackground(
    procedure
    begin
      // DevExpress exige abrir los detalles en el hilo principal.
      if not unqry.Active then
        unqry.Open;
    end,
    procedure(ErrMsg: string)
    begin
      if not (csDestroying in ComponentState) then
      begin
      if Assigned(unqry) then
        unqry.EnableControls;
      bSinError := ErrMsg = '';
      if bSinError then
        RegistroLog.RegistrarRendimiento('Carga/async', Self.Name + ' | OK',
          sw.ElapsedMilliseconds)
      else
      begin
        RegistroLog.RegistrarRendimiento('Carga/async',
          Self.Name + ' | error=' + ErrMsg,
          sw.ElapsedMilliseconds);
        TrasErrorPrecargaAsync(ErrMsg);
      end;
      if bSinError then
      begin
      if Assigned(dmDat) then
        try
          dmDat.AbrirDetalles;
        except
          on E: Exception do
            RegistroLog.RegistrarError(
              '[AbrirDetalles] ' + Self.Name + ': ' + E.Message);
        end;
      inLibDiag.DiagnosticarCamposBooleanos(
        unqry, Self.Name, RegistroLog);
      FGestorGuias.Aplicar(unqry);
      if (not yaActiva) and Assigned(dsTablaG) and Assigned(unqry) then
        dsTablaG.DataSet := unqry;
      if Assigned(dmDat) then
        try
          dmDat.ReactivarControlesTrasAbrir;
        except
          on E: Exception do
            RegistroLog.RegistrarError(
              '[ReactivarControlesTrasAbrir] ' + Self.Name + ': ' + E.Message);
        end;
      FGestorPerfiles.RestaurarFoco(cxGrdDBTabPrin);
      FGuardianBorrado.Instalar;
      TrasPrecargaAsync;
      end;
      end;
    end);
    end;
  end;
end;

procedure TfrmMtoGen.TrasPrecargaAsync;
begin
end;

// Por defecto el fallo de la precarga solo queda en el log; las pantallas
// en las que una rejilla vacía engaña al usuario lo muestran aquí.
procedure TfrmMtoGen.TrasErrorPrecargaAsync(const AError: string);
begin
end;

function TfrmMtoGen.SqlRestriccionUsuario: string;
begin
  Result := '';
end;

procedure TfrmMtoGen.AbrirTablaPrincipalSincrono;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  CursorPrev: TCursor;
begin
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    dmDat := TdmBase(tdmDataModule);
    unqry := dmDat.unqryTablaG;
    if unqry <> nil then
    begin
  if dmDat.AplicarRestriccionUsuario(SqlRestriccionUsuario) then
    RegistroLog.RegistrarInformacion(Self.Name +
      ': precarga restringida por usuario (appRestringirEmpAlmCaja)');
  CursorPrev := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  sw := TStopwatch.StartNew;
  try
    try
      if not unqry.Active then
        unqry.Open;
      dmDat.AbrirDetalles;
      inLibDiag.DiagnosticarCamposBooleanos(
        unqry, Self.Name, RegistroLog);
      FGestorGuias.Aplicar(unqry);
      FGestorPerfiles.RestaurarFoco(cxGrdDBTabPrin);
      FGuardianBorrado.Instalar;
      RegistroLog.RegistrarRendimiento('Carga/sync', Self.Name + ' | OK',
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Carga/sync',
          Self.Name + ' | error=' + E.Message,
          sw.ElapsedMilliseconds);
        raise;
      end;
    end;
  finally
    Screen.Cursor := CursorPrev;
  end;
    end;
  end;
end;

procedure TfrmMtoGen.cxGrdDBTabPrinDblClick(Sender: TObject);
begin
  inherited;
  if (tsFicha.TabVisible = True) then
    pcPantalla.ActivePage := tsFicha;
end;

destructor TfrmMtoGen.Destroy;
var
  bTareasVivas: Boolean;
begin
  // Los iconos se retiran antes de que desaparezca el colaborador.
  if Assigned(FVentanaSeparada) and HandleAllocated then
    FVentanaSeparada.DestruirManejador(Handle);
  FreeAndNil(FVentanaSeparada);
  if Assigned(tmrBusqGlobal) then
    tmrBusqGlobal.Enabled := False;
  bTareasVivas := False;
  FCasoUsoGuardado := nil;
  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  if Assigned(FGestorTareas) then
    bTareasVivas := FGestorTareas.EsperarFinalizacion(
      CancelarTareasActivas,
      ContextoSesion.CerrandoAplicacion);
  FreeAndNil(FGestorTareas);
  FreeAndNil(FGestorArticulos);
  oPerfilDic := nil;
  FreeAndNil(FGestorPerfiles);
  FreeAndNil(FGestorFiltros);
  FreeAndNil(FInteraccionFiltros);
  FreeAndNil(FGestorGuias);
  if bTareasVivas then
  begin
    // Tarea de fondo aun bloqueada (p.ej. consulta MySQL atascada): la
    // tarea sigue usando el data module y FConn, y liberarlos provoca
    // AVs y cuelgues del cierre. Se sueltan del Owner y NO se liberan:
    // fuga controlada que el SO recupera al terminar el proceso.
    RegistroLog.RegistrarAviso('Tareas de fondo aun vivas al destruir "' +
                            Self.Name + '": se dejan sin liberar su ' +
                            'data module y su conexion.');
    // tdmDataModule esta declarado como TObject: cast a TComponent para
    // consultar el Owner y soltarlo del form (en runtime siempre es un
    // TDataModule creado por CrearDataModule).
    if (tdmDataModule is TComponent) and
       (TComponent(tdmDataModule).Owner = Self) then
      RemoveComponent(TComponent(tdmDataModule));
    tdmDataModule := nil;
    if Assigned(FConn) then
    begin
      if FConn.Owner = Self then
        RemoveComponent(FConn);
      FConn := nil;
    end;
  end;
  if (tdmDataModule <> nil) then
  begin
    FreeAndNil(tdmDataModule);
    // El guardian engancha los eventos del dataset del data module: se
    // libera despues que el, nunca antes. Si el data module se deja sin
    // liberar (tareas vivas), el guardian se queda con el.
    FreeAndNil(FGuardianBorrado);
  end;
  // Liberar la conexion propia DESPUES del data module: las queries del
  // data module aun referencian FConn durante su destrucion para los Close
  // implicitos. Si soltamos antes, AVs garantizados.
  if Assigned(FConn) then
  begin
    try
      if FConn.Connected then
        FConn.Disconnect;
    except
      // Disconnect en pool no deberia fallar, pero si lo hace no queremos
      // que el destructor lance.
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'MtoGen.Destroy: Disconnect fallo: ' + E.Message);
    end;
    FreeAndNil(FConn);
  end;
  RegistroLog.RegistrarInformacion('Ventana de mantenimiento: ' +
                                                   Self.Caption + ' Cerrada');
  inherited;
end;

procedure TfrmMtoGen.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.Dataset <> nil) then
  begin
    if (dsTablaG.DataSet.State = dsInsert) then
    begin
      lblEditMode.Caption := SCaptionEstadoInsertando;
    end;
    if (dsTablaG.DataSet.State = dsEdit) then
    begin
      lblEditMode.Caption := SCaptionEstadoEditando;
    end;
    if (dsTablaG.DataSet.State = dsBrowse) then
    begin
      lblEditMode.Caption := SCaptionEstadoNavegando;
    end;
      if (dsTablaG.DataSet.State = dsInactive) then
    begin
      lblEditMode.Caption := SCaptionEstadoInactivo;
    end;
  end;
end;

procedure TfrmMtoGen.AplicarTraduccionActual;
begin
  inherited;
  if Assigned(FGestorPerfiles) then
    AplicarEtiquetas;
  if Assigned(dsTablaG) then
    dsTablaGStateChange(nil);
end;

procedure TfrmMtoGen.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrBusqGlobal.Enabled := False;
  inherited;
  SendMessage(Self.Handle, WM_SETREDRAW, WPARAM(False), 0);
  // Si la pantalla flotante de fotos estaba enganchada a DataSources
  // de este Mto (vinculados con Ctrl+F), la desenganchamos antes
  // de que sus DataSources se liberen con el data module. Asi no
  // quedan punteros colgando en FHooksDataSource.
  if Assigned(FGestorArticulos) then
    FGestorArticulos.DesvincularFoto;
  if Assigned(cxGrdDBTabPrin) then
    cxGrdDBTabPrin.DataController.DataSource := nil;

  if Assigned(tvPerfil) then
    tvPerfil.DataController.DataSource := nil;

  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  Action := caFree;
end;

procedure TfrmMtoGen.FormCreate(Sender: TObject);
begin
  inherited;
  InicializarMantenimiento;
end;

function TfrmMtoGen.HandleCreateException: Boolean;
begin
  // La apertura debe recibir el fallo y el constructor liberar la pantalla.
  // La VCL no debe absorberlo ni mostrar el diálogo técnico de aplicación.
  if ExceptObject is EConexionMantenimientoBBDD then
    Result := False
  else
    Result := inherited HandleCreateException;
end;

procedure TfrmMtoGen.InicializarMantenimiento;
var
  swTotal, swTramo: TStopwatch;
  msProcesarPerfiles: Int64;
begin
  swTotal := TStopwatch.StartNew;
  // Descubrir el anfitrion UNA vez; el resto de metodos usa el campo.
  // Fuera de viracash (pruebas, proyectos independientes) no existe.
  if not Supports(Self.Owner, IAnfitrionMantenimiento, FAnfitrionMto) then
    RegistroLog.RegistrarInformacion(
      'Sin anfitrion de mantenimiento (standalone): ' + Self.ClassName);
  // El proveedor del menu se descubre aqui por el mismo motivo: las
  // pantallas usan el campo y no localizan el servicio por su cuenta.
  if not Supports(Self.Owner, IProveedorMenuPantallas,
                  FProveedorMenu) then
    FProveedorMenu := nil;
  FGestorTareas := TGestorTareasMto.Create(
    Self, AplicacionCerrando, RegistroLog);
  FGestorArticulos := TGestorArticulosMto.Create(
    dsTablaG, ResolverArtSkuActivo,
    DataSourcesParaFoto, FotoArticuloVisible,
    OcultarFotoArticulo, MostrarFotoArticulo,
    VincularFotoArticulo, MostrarStockArticulo);
  FGuardianBorrado := TGestorGuardianBorradoMto.Create(
    dsTablaG, nvNavegador, cxGrdDBTabPrin,
    PuedeAccionMto, NombreCampoESACTIVO,
    ContarHijosActivos, DescripcionHijos);
  FGestorGuias := TGestorGuiasGridMto.Create(
    Self, cxgrdPrincipal, cxGrdDBTabPrin,
    InformesGuiasCache, ObtenerConsultaGuias,
    EjecutarModalGuias, RegistroLog);
  FGestorPerfiles := TGestorPerfilesMto.Create(
    Self, dsTablaG, lblTablaOrigen,
    PerfilesLectura, PerfilesEscritura,
    ConfiguracionCampos, RegistroLog,
    SolicitarDestinoPerfil, RecogerPerfilesParticulares,
    ResetearGridPerfil, FGestorGuias.BorrarGuias);
  FInteraccionFiltros := TInteraccionFiltrosMtoVcl.Create(
    Self.Owner,
    Self.Name,
    cxGrdDBTabPrin.Name,
    cxGrdDBTabPrin,
    FiltrosDestinos);
  FGestorFiltros := TGestorFiltrosMto.Create(
    Self, cxGrdDBTabPrin, edtBusqGlobal, tmrBusqGlobal,
    pmFiltros, FiltrosLectura, FiltrosEscritura,
    FInteraccionFiltros.SolicitarDatosFiltro,
    FInteraccionFiltros.EjecutarGestionFiltros);
  btnCargarCaptions.Enabled := False;
  Self.HandleNeeded; //da problemas
  nvNavegador.Buttons.OnButtonClick := NavegadorButtonClick;
  RegistroLog.RegistrarInformacion('Ventana de mantenimiento: ' +
                                                     Self.Caption + ' Abierta');
  tsFichCab := nil;
  tsFichBut := nil;
  Self.Position  := poScreenCenter;
  swTramo := TStopwatch.StartNew;
  ProcesarPerfiles;
  msProcesarPerfiles := swTramo.ElapsedMilliseconds;
  ConfigurarModoBusqueda;
  AjustarBarraLateral;
  PrepararDesplazamientoBarraLateral;
  PrepararDesplazamientoVerticalFichas;
  CargarIconoPantalla;
  RegistroLog.RegistrarRendimiento(Self.Name + '.FormCreate',
    'ProcesarPerfiles=' + IntToStr(msProcesarPerfiles) + ' ms',
    swTotal.ElapsedMilliseconds);
end;

// Las fichas se muestran embebidas y, por tanto, adoptan la altura que deja
// libre la ventana principal. Las paginas formadas solo por controles de
// posicion fija no pueden reducirse como una rejilla o un panel alClient. En
// esos casos conservamos el alto de diseño dentro de una zona desplazable.
procedure TfrmMtoGen.PrepararDesplazamientoVerticalFichas;
var
  oPaginas: TList<TcxTabSheet>;

  procedure RecogerPaginas(AContenedor: TWinControl);
  var
    iControl: Integer;
    oControl: TControl;
  begin
    if AContenedor is TcxTabSheet then
      oPaginas.Add(TcxTabSheet(AContenedor));
    for iControl := 0 to AContenedor.ControlCount - 1 do
    begin
      oControl := AContenedor.Controls[iControl];
      if oControl is TWinControl then
        RecogerPaginas(TWinControl(oControl));
    end;
  end;

var
  oPagina: TcxTabSheet;
begin
  oPaginas := TList<TcxTabSheet>.Create;
  try
    RecogerPaginas(tsFicha);
    for oPagina in oPaginas do
      PrepararPaginaDesplazable(oPagina);
  finally
    oPaginas.Free;
  end;
end;

procedure TfrmMtoGen.PrepararPaginaDesplazable(APagina: TcxTabSheet);
const
  ALTO_MINIMO_CONTENIDO_96_DPI = 240;
var
  aControles: TArray<TControl>;
  iAltoContenido: Integer;
  iAltoMinimo: Integer;
  iAnchoContenido: Integer;
  iControl: Integer;
  oContenido: TPanel;
  oControl: TControl;
  oDesplazamiento: TcxScrollBox;
begin
  SetLength(aControles, APagina.ControlCount);
  iAltoContenido := 0;
  iAnchoContenido := 0;
  for iControl := 0 to APagina.ControlCount - 1 do
  begin
    oControl := APagina.Controls[iControl];
    aControles[iControl] := oControl;
    if (oControl is TcxScrollBox) and
       (oControl.Align = alClient) then
      Exit;
    if oControl.Align <> alNone then
      Exit;
    if oControl.Top + oControl.Height > iAltoContenido then
      iAltoContenido := oControl.Top + oControl.Height;
    if oControl.Left + oControl.Width > iAnchoContenido then
      iAnchoContenido := oControl.Left + oControl.Width;
  end;

  iAltoMinimo := MulDiv(
    ALTO_MINIMO_CONTENIDO_96_DPI,
    CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  if (Length(aControles) = 0) or
     (iAltoContenido < iAltoMinimo) then
    Exit;
  if APagina.ClientHeight > iAltoContenido then
    iAltoContenido := APagina.ClientHeight;
  if APagina.ClientWidth > iAnchoContenido then
    iAnchoContenido := APagina.ClientWidth;

  oDesplazamiento := TcxScrollBox.Create(APagina);
  oDesplazamiento.Parent := APagina;
  oDesplazamiento.Align := alClient;
  oDesplazamiento.BorderStyle := cxcbsNone;
  oDesplazamiento.HorzScrollBar.Visible := False;
  oDesplazamiento.VertScrollBar.Tracking := True;
  oDesplazamiento.TabOrder := 0;

  oContenido := TPanel.Create(APagina);
  oContenido.Parent := oDesplazamiento;
  oContenido.SetBounds(
    0,
    0,
    iAnchoContenido,
    iAltoContenido);
  oContenido.BevelOuter := bvNone;
  oContenido.ParentBackground := True;
  oContenido.DisableAlign;
  try
    for iControl := 0 to High(aControles) do
      aControles[iControl].Parent := oContenido;
  finally
    oContenido.EnableAlign;
  end;
  oContenido.Align := alTop;
end;

procedure TfrmMtoGen.CargarIconoPantalla;
var
  oRegistro: TfzaWinF;
  oPantalla: TfzaForm;
  sCall: string;
begin
  imgIconoPantalla.Visible := False;
  imgIconoPantalla.Picture.Assign(nil);
  if Assigned(FProveedorMenu) then
  begin
    oRegistro := FProveedorMenu.RegistroPantallas;
    sCall := ResolverCallPantallaPorJerarquia(FAnfitrionMto, ClassType);
    if Assigned(oRegistro) and (sCall <> '') then
    begin
      oPantalla := oRegistro.GetElement(sCall);
      if Assigned(oPantalla) and Assigned(oPantalla.mnMenuItem) then
        imgIconoPantalla.Visible := CargarIconoMenuMaximaResolucion(
          oPantalla.mnMenuItem.Name, imgIconoPantalla.Picture);
    end;
  end;
end;

// La barra heredada se diseno con 140 px. Varias pantallas anaden botones
// como "Imprimir etiqueta", "Enviar comentario" o "Abrir seguimiento" que
// no caben con la fuente normal, especialmente con DPI alto. Se reserva un
// ancho minimo escalado y se estiran los botones que ocupan una fila completa;
// asi mantenemos la tipografia y el mismo criterio en todos los Mtos.
procedure TfrmMtoGen.AjustarBarraLateral;
const
  ANCHO_BARRA_96_DPI = 156;
var
  iAnchoMinimo: Integer;

  procedure AjustarBotonesDe(AContenedor: TWinControl);
  var
    iControl: Integer;
    iMargenDerecho: Integer;
    iNuevoAncho: Integer;
    oControl: TControl;
  begin
    for iControl := 0 to AContenedor.ControlCount - 1 do
    begin
      oControl := AContenedor.Controls[iControl];
      if (oControl is TcxButton) and
         (oControl.Align = alNone) and
         (oControl.Left <= 7) and
         (oControl.Width >= 100) then
      begin
        iMargenDerecho := oControl.Left;
        if iMargenDerecho < 2 then
          iMargenDerecho := 2;
        iNuevoAncho := AContenedor.ClientWidth - oControl.Left -
          iMargenDerecho;
        if iNuevoAncho > oControl.Width then
          oControl.Width := iNuevoAncho;
      end;
      if oControl is TWinControl then
        AjustarBotonesDe(TWinControl(oControl));
    end;
  end;

begin
  iAnchoMinimo := MulDiv(
    ANCHO_BARRA_96_DPI, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  if pButtonRightBar.Width < iAnchoMinimo then
    pButtonRightBar.Width := iAnchoMinimo;
  AjustarBotonesDe(pButtonRightBar);
end;

procedure TfrmMtoGen.PrepararDesplazamientoBarraLateral;
var
  iControl: Integer;
  iPosicion: Integer;
  oControl: TControl;
begin
  if not Assigned(FDesplazamientoBarra) then
  begin
    // Conservar el orden de diseno, incluso de las acciones ocultas.
    for iControl := 0 to pButtonRightBar.ControlCount - 1 do
    begin
      oControl := pButtonRightBar.Controls[iControl];
      if (oControl is TcxButton) and (oControl.Align = alNone) then
      begin
        iPosicion := Length(FBotonesBarra);
        SetLength(FBotonesBarra, iPosicion + 1);
        while (iPosicion > 0) and
          (FBotonesBarra[iPosicion - 1].Top > oControl.Top) do
        begin
          FBotonesBarra[iPosicion] := FBotonesBarra[iPosicion - 1];
          Dec(iPosicion);
        end;
        FBotonesBarra[iPosicion] := TcxButton(oControl);
      end
      else if (oControl is TcxImage) or (oControl is TImage) then
        FFotoBarra := oControl;
    end;
    FDesplazamientoBarra := TcxScrollBox.Create(Self);
    FDesplazamientoBarra.Parent := pButtonRightBar.Parent;
    FDesplazamientoBarra.SetBounds(pButtonRightBar.Left,
      pButtonRightBar.Top, pButtonRightBar.Width +
      GetSystemMetricsForDpi(SM_CXVSCROLL, CurrentPPI),
      pButtonRightBar.Height);
    FDesplazamientoBarra.Align := alRight;
    FDesplazamientoBarra.BorderStyle := cxcbsNone;
    FDesplazamientoBarra.HorzScrollBar.Visible := False;
    FDesplazamientoBarra.VertScrollBar.Tracking := True;
    FDesplazamientoBarra.TabOrder := pButtonRightBar.TabOrder;
    FDesplazamientoBarra.Visible := pButtonRightBar.Visible;
    // Se conserva el panel para los descendientes que anaden botones
    // o la miniatura de articulo en tiempo de ejecucion.
    pButtonRightBar.Parent := FDesplazamientoBarra;
    pButtonRightBar.Align := alTop;
    pButtonRightBar.TabOrder := 0;
    pButtonGen.Constraints.MinHeight := 0;
    FDesplazamientoBarra.OnResize := ActualizarAltoBarraLateral;
    ActualizarAltoBarraLateral(nil);
  end;
end;

function TfrmMtoGen.AltoMinimoBarra(AContenedor: TWinControl): Integer;
var
  iControl: Integer;
  iSuperior: Integer;
  iInferior: Integer;
  iCentro: Integer;
  iAlto: Integer;
  oControl: TControl;
begin
  Result := 0;
  iSuperior := 0;
  iInferior := 0;
  iCentro := 0;
  for iControl := 0 to AContenedor.ControlCount - 1 do
  begin
    oControl := AContenedor.Controls[iControl];
    if oControl.Visible then
    begin
      iAlto := oControl.Height;
      if oControl.AlignWithMargins then
        Inc(iAlto, oControl.Margins.Top + oControl.Margins.Bottom);
      case oControl.Align of
        alTop: Inc(iSuperior, iAlto);
        alBottom: Inc(iInferior, iAlto);
        alNone:
          if oControl.Top + iAlto > Result then
            Result := oControl.Top + iAlto;
        alClient:
          begin
            iAlto := oControl.Constraints.MinHeight;
            if (oControl is TImage) or (oControl is TcxImage) then
              iAlto := MulDiv(48, CurrentPPI, USER_DEFAULT_SCREEN_DPI)
            else if oControl is TWinControl then
              iAlto := AltoMinimoBarra(TWinControl(oControl));
            if iAlto > iCentro then
              iCentro := iAlto;
          end;
      end;
    end;
  end;
  if iSuperior + iCentro > Result then
    Result := iSuperior + iCentro;
  Inc(Result, iInferior + AContenedor.Height - AContenedor.ClientHeight);
end;

procedure TfrmMtoGen.ActualizarAltoBarraLateral(Sender: TObject);
var
  iControl: Integer;
  iMargen: Integer;
  iTop: Integer;
  iAltoAcciones: Integer;
  iAltoEstado: Integer;
  iAltoIcono: Integer;
  iAltoFoto: Integer;
  iFotoMinima: Integer;
  iFalta: Integer;
  iAltoBarra: Integer;
  bHayFoto: Boolean;
  oBoton: TcxButton;
  oControl: TControl;
begin
  if Assigned(FDesplazamientoBarra) and
     not FActualizandoAltoBarra and
     not (csDestroying in ComponentState) then
  begin
    FActualizandoAltoBarra := True;
    pButtonRightBar.DisableAlign;
    try
      iMargen := MulDiv(4, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
      // Quitar el hueco superior de la botonera comun y evitar sus solapes.
      iTop := iMargen;
      for iControl := 0 to pButtonGen.ControlCount - 1 do
      begin
        oControl := pButtonGen.Controls[iControl];
        if (oControl is TcxButton) and oControl.Visible then
        begin
          oControl.SetBounds(iMargen, iTop,
            pButtonGen.ClientWidth - 2 * iMargen, oControl.Height);
          Inc(iTop, oControl.Height + iMargen);
        end;
      end;
      if iTop = iMargen then
        iTop := 0;
      pButtonGen.Height := iTop;

      iAltoAcciones := 2 * iMargen;
      for oBoton in FBotonesBarra do
        if oBoton.Visible then
          Inc(iAltoAcciones, oBoton.Height + iMargen);
      iAltoEstado := pnlDataSetName.Height + pnStateDataSet.Height;
      iAltoIcono := 0;
      if imgIconoPantalla.Visible then
        iAltoIcono := MulDiv(48, CurrentPPI, USER_DEFAULT_SCREEN_DPI) +
          imgIconoPantalla.Margins.Top + imgIconoPantalla.Margins.Bottom;
      iAltoFoto := 0;
      bHayFoto := False;
      if Assigned(FFotoBarra) and FFotoBarra.Visible then
      begin
        if FFotoBarra is TcxImage then
          bHayFoto := Assigned(TcxImage(FFotoBarra).Picture.Graphic) and
            not TcxImage(FFotoBarra).Picture.Graphic.Empty
        else if FFotoBarra is TImage then
          bHayFoto := Assigned(TImage(FFotoBarra).Picture.Graphic) and
            not TImage(FFotoBarra).Picture.Graphic.Empty;
      end;
      if bHayFoto then
      begin
        iFotoMinima := MulDiv(48, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
        iAltoFoto := FDesplazamientoBarra.ClientHeight -
          pButtonGen.Height - iAltoEstado - iAltoIcono -
          iAltoAcciones - iMargen;
        if iAltoFoto > MulDiv(140, CurrentPPI, USER_DEFAULT_SCREEN_DPI) then
          iAltoFoto := MulDiv(140, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
        if iAltoFoto < iFotoMinima then
          iAltoFoto := iFotoMinima;
      end;
      // Reducir primero foto e icono; la fuente y el alto de los botones
      // se mantienen. Si aun no caben, entra el desplazamiento vertical.
      iFalta := pButtonGen.Height + iAltoEstado + iAltoIcono +
        iAltoAcciones + iAltoFoto + iMargen -
        FDesplazamientoBarra.ClientHeight;
      if (iFalta > 0) and (iAltoIcono > 0) then
      begin
        Dec(iAltoIcono, iFalta);
        iTop := MulDiv(24, CurrentPPI, USER_DEFAULT_SCREEN_DPI) +
          imgIconoPantalla.Margins.Top + imgIconoPantalla.Margins.Bottom;
        if iAltoIcono < iTop then
          iAltoIcono := iTop;
      end;
      pButtonBDStat.Height := iAltoEstado + iAltoIcono;
      iTop := pButtonBDStat.Height + iMargen;
      if Assigned(FFotoBarra) then
      begin
        FFotoBarra.SetBounds(iMargen, iTop,
          pButtonRightBar.ClientWidth - 2 * iMargen, iAltoFoto);
        if iAltoFoto > 0 then
          Inc(iTop, iAltoFoto + iMargen);
      end;
      for oBoton in FBotonesBarra do
        if oBoton.Visible then
        begin
          oBoton.SetBounds(iMargen, iTop,
            pButtonRightBar.ClientWidth - 2 * iMargen, oBoton.Height);
          Inc(iTop, oBoton.Height + iMargen);
        end;
      // Tambien contar los paneles anidados de Documentos de trabajo.
      iAltoBarra := AltoMinimoBarra(pButtonRightBar) + iMargen;
      if iAltoBarra < FDesplazamientoBarra.ClientHeight then
        iAltoBarra := FDesplazamientoBarra.ClientHeight;
      pButtonRightBar.Height := iAltoBarra;
    finally
      try
        pButtonRightBar.EnableAlign;
      finally
        FActualizandoAltoBarra := False;
      end;
    end;
  end;
end;

procedure TfrmMtoGen.UpdateActions;
begin
  inherited;
  if Showing then
    ActualizarAltoBarraLateral(nil);
end;

procedure TfrmMtoGen.ConfigurarModoBusqueda;
var
  sModoBusq: String;
begin
  sModoBusq := FGestorPerfiles.Valor(
    'oBusqGlobal', 'Database');
  if sModoBusq = 'DataBase' then
  begin
    rbBBDD.Checked := true;
    rbGrid.Checked := false;
  end
  else
  begin
    rbBBDD.Checked := false;
    rbGrid.Checked := true;
  end;
end;

procedure TfrmMtoGen.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  // La lista abierta cancela primero; el siguiente Esc cancela el grid.
  if (Key = VK_ESCAPE) and
     not EsDesplegableAbierto(Screen.ActiveControl) then
  begin
    // Fuera de viracash no hay anfitrion: nada global que cancelar.
    if Assigned(FAnfitrionMto) then
      FAnfitrionMto.CancelarEdicionesPantallas;
    Key := 0;
  end
  // RETURN sin control activo -> simular Tab. Los modificadores se respetan:
  // Ctrl+Enter es el ClickKey estandar de los EditButton y Alt+Enter tampoco
  // debe convertirse en una combinacion de navegacion. En una pestana
  // embebida ActiveControl es nil aunque haya foco: con un desplegable
  // abierto el Enter es suyo (elige de la lista), no un Tab.
  else if (Key = VK_RETURN) and
          not (ssCtrl in Shift) and not (ssAlt in Shift) and
          (ActiveControl = nil) and
          not EsDesplegableAbierto(Screen.ActiveControl) then
  begin
    Key := 0;
    SimulateTabKey;
  end
  // Ctrl+Inicio / Ctrl+Fin -> primer / ultimo registro del grid.
  // En editores de texto dejamos el comportamiento nativo del control.
  else if (Key in [VK_HOME, VK_END]) and (ssCtrl in Shift) and
     not (ssAlt in Shift) and PuedeCambiarRegistroPorTecla then
  begin
    // Usar DataController para respetar la ordenacion del grid
    if Key = VK_HOME then
      cxGrdDBTabPrin.DataController.FocusedRowIndex := 0
    else
      cxGrdDBTabPrin.DataController.FocusedRowIndex :=
        cxGrdDBTabPrin.DataController.RowCount - 1;
    Key := 0;
  end
  // Alt+F12 -> Guardar layout (equivalente al botón sbGrabarGrid)
  else if (Key = VK_F12) and (ssAlt in Shift) and
     not (ssCtrl in Shift) then
  begin
    sbGrabarGridClick(nil);
    Key := 0;
  end
  // Ctrl+F12 -> Resetear layout (equivalente al botón sbResetGrid)
  else if (Key = VK_F12) and (ssCtrl in Shift) and
     not (ssAlt in Shift) then
  begin
    sbResetGridClick(nil);
    Key := 0;
  end
  // Ctrl+F10 -> BestFit anchos de columna
  else if (Key = VK_F10) and (ssCtrl in Shift) and
     not (ssAlt in Shift) then
  begin
    sbBestFitClick(nil);
    Key := 0;
  end;
end;

// ---------------------------------------------------------------------------
// Acciones del TActionList base (alMtoGen)
// Sustituyen al antiguo FormKeyDown para que inMtoPrincipal.IsShortCut
// enrute siempre al formulario activo en la pestaña correcta.
// ---------------------------------------------------------------------------

function TfrmMtoGen.PermitirNavegacionTeclas: Boolean;
begin
  Result := True;
end;

// En una pantalla embebida en pestana del principal ActiveControl es nil
// aunque haya foco: se toma el de la pantalla si es un control propio.
function TfrmMtoGen.ControlConFoco: TWinControl;
begin
  Result := ActiveControl;
  if (Result = nil) and Assigned(Screen.ActiveControl) and
     ContainsControl(Screen.ActiveControl) then
    Result := Screen.ActiveControl;
end;

// Inicio/Fin/RePag/AvPag dentro de una rejilla de detalle (lineas) son de
// esa rejilla, no cambian el registro de la cabecera.
function TfrmMtoGen.FocoEnRejillaSecundaria(
  AControl: TWinControl): Boolean;
var
  oControl: TWinControl;
begin
  Result := False;
  oControl := AControl;
  while (oControl <> nil) and (not Result) do
  begin
    Result := (oControl is TcxGrid) and (oControl <> cxgrdPrincipal);
    oControl := oControl.Parent;
  end;
end;

function TfrmMtoGen.FocoEnRejilla(AControl: TWinControl): Boolean;
var
  oControl: TWinControl;
begin
  Result := False;
  oControl := AControl;
  while (oControl <> nil) and (not Result) do
  begin
    Result := oControl is TcxGrid;
    oControl := oControl.Parent;
  end;
end;

// Un detalle (no la cabecera) con una fila en alta o edición pendiente.
function TfrmMtoGen.HayDetalleEnEdicion: Boolean;
var
  oModulo: TDataModule;
  oDataSet: TDataSet;
  i: Integer;
begin
  Result := False;
  if tdmDataModule is TDataModule then
  begin
    oModulo := TDataModule(tdmDataModule);
    i := 0;
    while (not Result) and (i < oModulo.ComponentCount) do
    begin
      if oModulo.Components[i] is TDataSet then
      begin
        oDataSet := TDataSet(oModulo.Components[i]);
        Result := (oDataSet <> dsTablaG.DataSet) and oDataSet.Active and
          (oDataSet.State in dsEditModes);
      end;
      Inc(i);
    end;
  end;
end;

// La VCL convierte una tecla suelta que el control con foco no procesa en
// un atajo de la ficha: un «1» tecleado en una rejilla de detalle sin la
// celda en edición activaba la pestaña «&1». Dentro de una rejilla la
// tecla es suya (empieza a editar la celda) y, con una fila de detalle
// pendiente, un dígito tampoco cambia de pestaña. Los atajos siguen
// disponibles con Alt (FZ-ISSUE-625).
procedure TfrmMtoGen.CMDialogChar(var Message: TCMDialogChar);
var
  bTeclaDeRejilla: Boolean;
begin
  bTeclaDeRejilla := False;
  if not (ssAlt in KeyDataToShiftState(Message.KeyData)) then
    bTeclaDeRejilla := FocoEnRejilla(ControlConFoco) or
      ((Message.CharCode >= Ord('0')) and
       (Message.CharCode <= Ord('9')) and
       HayDetalleEnEdicion);
  if bTeclaDeRejilla then
    Message.Result := 0
  else
    inherited;
end;

function TfrmMtoGen.CampoObligatorioDeDataSet(E: Exception;
  ADataSet: TDataSet): TField;
var
  oCampo: TField;
  i: Integer;
begin
  Result := nil;
  if E is ECampoObligatorioBBDD then
    Result := ADataSet.FindField(ECampoObligatorioBBDD(E).NombreCampo)
  else
  begin
    // TDataSet.CheckRequiredFields lanza un EDatabaseError exacto por el
    // primer campo Required vacío: se busca con su misma condición.
    i := 0;
    while (Result = nil) and (i < ADataSet.FieldCount) do
    begin
      oCampo := ADataSet.Fields[i];
      if oCampo.Required and (not oCampo.ReadOnly) and
         (oCampo.FieldKind = fkData) and oCampo.IsNull then
        Result := oCampo;
      Inc(i);
    end;
  end;
end;

function TfrmMtoGen.CampoObligatorioSinValor(E: Exception): TField;
var
  oModulo: TDataModule;
  oDataSet: TDataSet;
  i: Integer;
begin
  Result := nil;
  if ((E is ECampoObligatorioBBDD) or (E.ClassType = EDatabaseError)) and
     (tdmDataModule is TDataModule) then
  begin
    oModulo := TDataModule(tdmDataModule);
    i := 0;
    while (Result = nil) and (i < oModulo.ComponentCount) do
    begin
      if oModulo.Components[i] is TDataSet then
      begin
        oDataSet := TDataSet(oModulo.Components[i]);
        if oDataSet.Active and (oDataSet.State in dsEditModes) then
          Result := CampoObligatorioDeDataSet(E, oDataSet);
      end;
      Inc(i);
    end;
  end;
end;

// Columna de una rejilla de la pantalla enlazada al campo: da la etiqueta
// visible y, si no hay un editor de ficha para él, la celda que enfocar.
function TfrmMtoGen.ColumnaDeCampo(ACampo: TField): TcxGridDBColumn;
var
  oVista: TcxGridDBTableView;
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and (i < ComponentCount) do
  begin
    if Components[i] is TcxGridDBTableView then
    begin
      oVista := TcxGridDBTableView(Components[i]);
      if Assigned(oVista.DataController.DataSource) and
         (oVista.DataController.DataSource.DataSet = ACampo.DataSet) then
        Result := oVista.GetColumnByFieldName(ACampo.FieldName);
    end;
    Inc(i);
  end;
end;

function ControlEnlazadoACampo(AControl: TWinControl;
  ACampo: TField): Boolean;
var
  oEnlace: TObject;
  oOrigen: TObject;
begin
  Result := False;
  // Los editores cx publican DataBinding; los DB de la VCL, DataSource y
  // DataField en el propio control.
  oEnlace := AControl;
  if IsPublishedProp(AControl, 'DataBinding') then
    oEnlace := GetObjectProp(AControl, 'DataBinding');
  if Assigned(oEnlace) and
     IsPublishedProp(oEnlace, 'DataSource') and
     IsPublishedProp(oEnlace, 'DataField') then
  begin
    oOrigen := GetObjectProp(oEnlace, 'DataSource');
    Result := (oOrigen is TDataSource) and
      (TDataSource(oOrigen).DataSet = ACampo.DataSet) and
      SameText(GetStrProp(oEnlace, 'DataField'), ACampo.FieldName);
  end;
end;

function TfrmMtoGen.ControlDeCampo(ACampo: TField): TWinControl;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and (i < ComponentCount) do
  begin
    if (Components[i] is TWinControl) and
       ControlEnlazadoACampo(TWinControl(Components[i]), ACampo) then
      Result := TWinControl(Components[i]);
    Inc(i);
  end;
end;

function TfrmMtoGen.EtiquetaCampo(ACampo: TField): string;
var
  oColumna: TcxGridDBColumn;
begin
  Result := '';
  oColumna := ColumnaDeCampo(ACampo);
  if Assigned(oColumna) then
    Result := Trim(oColumna.Caption);
  if Result = '' then
    Result := ACampo.DisplayName;
end;

// Activa las pestañas que contienen el control antes de enfocarlo.
procedure TfrmMtoGen.MostrarControl(AControl: TWinControl);
var
  oPadre: TWinControl;
  oPagina: TcxTabSheet;
begin
  oPadre := AControl.Parent;
  while Assigned(oPadre) and (oPadre <> Self) do
  begin
    if oPadre is TcxTabSheet then
    begin
      oPagina := TcxTabSheet(oPadre);
      if oPagina.TabVisible and Assigned(oPagina.PageControl) then
        oPagina.PageControl.ActivePage := oPagina;
    end;
    oPadre := oPadre.Parent;
  end;
  if AControl.CanFocus then
    AControl.SetFocus;
end;

procedure TfrmMtoGen.EnfocarCampo(ACampo: TField);
var
  oControl: TWinControl;
  oColumna: TcxGridDBColumn;
begin
  oControl := ControlDeCampo(ACampo);
  oColumna := ColumnaDeCampo(ACampo);
  if Assigned(oControl) then
    MostrarControl(oControl)
  else if Assigned(oColumna) then
  begin
    MostrarControl(TWinControl(oColumna.GridView.Control));
    oColumna.Focused := True;
  end;
end;

procedure TfrmMtoGen.AvisarSiCampoObligatorio(E: Exception);
var
  oCampo: TField;
  sMensaje: string;
begin
  oCampo := CampoObligatorioSinValor(E);
  if Assigned(oCampo) then
  begin
    // El data module ya redacta su aviso; el de TField.Required se nombra
    // con la etiqueta que ve el usuario.
    if E is ECampoObligatorioBBDD then
      sMensaje := E.Message
    else
      sMensaje := Format(SErrorBBDDCampoObligatorio,
        [EtiquetaCampo(oCampo)]);
    EnfocarCampo(oCampo);
    raise EValidacionBBDD.Create(sMensaje);
  end;
end;

function TfrmMtoGen.FocoEnEditorTexto: Boolean;
var
  oControl: TWinControl;
  sClase: string;
begin
  Result := False;
  oControl := ControlConFoco;
  if Assigned(oControl) then
  begin
    sClase := oControl.ClassName;
    // Sin esto, Fin en una celda de las lineas de un inventario saltaba
    // al ultimo inventario y perdia la linea (FZ-ISSUE-009).
    Result := (oControl is TCustomEdit) or
              FocoEnRejillaSecundaria(oControl) or
              (Pos('TextEdit', sClase) > 0) or
              (Pos('Memo', sClase) > 0) or
              (Pos('SynEdit', sClase) > 0) or
              (Pos('ComboBox', sClase) > 0) or
              (Pos('LookupComboBox', sClase) > 0) or
              (Pos('ButtonEdit', sClase) > 0) or
              (Pos('DateEdit', sClase) > 0) or
              (Pos('CurrencyEdit', sClase) > 0);
  end;
end;

function TfrmMtoGen.PuedeCambiarRegistroPorTecla: Boolean;
begin
  Result := Assigned(dsTablaG.DataSet) and
            dsTablaG.DataSet.Active and
            (dsTablaG.State = dsBrowse) and
            PermitirNavegacionTeclas and
            not FocoEnEditorTexto;
end;

function TfrmMtoGen.FiltroGridActivo: Boolean;
begin
  Result := Assigned(cxGrdDBTabPrin) and
            cxGrdDBTabPrin.DataController.Filter.Active and
            not cxGrdDBTabPrin.DataController.Filter.IsEmpty;
end;

procedure TfrmMtoGen.MoverRegistroGridFiltrado(AAvanzar: Boolean);
var
  iFila: Integer;
  iUltimaFila: Integer;
begin
  iUltimaFila := cxGrdDBTabPrin.DataController.RowCount - 1;
  if iUltimaFila >= 0 then
  begin
    iFila := cxGrdDBTabPrin.DataController.FocusedRowIndex;
    if iFila < 0 then
      iFila := 0
    else if AAvanzar then
      Inc(iFila)
    else
      Dec(iFila);
    if iFila < 0 then
      iFila := 0;
    if iFila > iUltimaFila then
      iFila := iUltimaFila;
    cxGrdDBTabPrin.DataController.FocusedRowIndex := iFila;
  end;
end;

// Si algo falla despues de entrar en insercion (AfterInsert de un modulo:
// valores por defecto, serie, BBDD sin una migracion...), la ficha no se
// queda «Insertando» con la cabecera a medias: se cancela el alta y el
// error se muestra igual (FZ-ISSUE-237).
procedure TfrmMtoGen.InsertarRegistroSinQuedarAMedias;
var
  oDataSet: TDataSet;
begin
  oDataSet := dsTablaG.DataSet;
  try
    oDataSet.Insert;
  except
    if oDataSet.State = dsInsert then
      oDataSet.Cancel;
    raise;
  end;
end;

procedure TfrmMtoGen.NavegadorButtonClick(Sender: TObject;
  AButtonIndex: Integer; var ADone: Boolean);
begin
  // El filtro pertenece al grid, no al dataset del navegador.
  if FiltroGridActivo and
     (AButtonIndex in [NBDI_PRIOR, NBDI_NEXT]) then
  begin
    MoverRegistroGridFiltrado(AButtonIndex = NBDI_NEXT);
    ADone := True;
  end
  else if (AButtonIndex = NBDI_INSERT) and
          Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active then
  begin
    ADone := True;
    InsertarRegistroSinQuedarAMedias;
  end;
end;

procedure TfrmMtoGen.actNavBrowseUpdate(Sender: TObject);
var
  bPermitido: Boolean;
begin
  bPermitido := True;
  // Ins dentro de una rejilla de detalle es de esa rejilla: no da de alta
  // otra cabecera.
  if Sender = actInsertarRegistro then
    bPermitido := PuedeAccionMto(apmInsertar) and
      not FocoEnRejillaSecundaria(ControlConFoco)
  else if Sender = actEditarRegistro then
    bPermitido := PuedeAccionMto(apmModificar) and
      not FocoEnRejillaSecundaria(ControlConFoco)
  else if (Sender = actRegistroAnterior) or
          (Sender = actRegistroSiguiente) or
          (Sender = actPrimerRegistro) or
          (Sender = actUltimoRegistro) then
    // Deshabilitadas, sus atajos (RePag/AvPag) llegan al editor o a la
    // rejilla de lineas con el foco. Primero/ultimo van con Ctrl+Inicio y
    // Ctrl+Fin en FormKeyDown: Inicio y Fin sueltos son del editor.
    bPermitido := not FocoEnEditorTexto;
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (dsTablaG.State = dsBrowse) and
    PermitirNavegacionTeclas and
    bPermitido;
end;

procedure TfrmMtoGen.actEliminarRegistroUpdate(Sender: TObject);
begin
  // Ctrl+Supr en una rejilla de detalle borra su fila, no la cabecera.
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty and
    (dsTablaG.State = dsBrowse) and
    PuedeAccionMto(apmBorrar) and
    not FocoEnRejillaSecundaria(ControlConFoco);
end;

procedure TfrmMtoGen.actEliminarRegistroExecute(Sender: TObject);
begin
  // El guardian de borrado (TGestorGuardianBorradoMto) hace la pregunta
  // y, segun la respuesta, aborta, desactiva o continua con el delete
  // original. No duplicamos aqui la logica para que el flujo sea
  // identico cuando el usuario pulsa el boton de borrar del navegador
  // (que llama directamente a DataSet.Delete sin pasar por esta accion).
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty and
     PuedeAccionMto(apmBorrar) then
    dsTablaG.DataSet.Delete;
end;

procedure TfrmMtoGen.actRegistroAnteriorExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    nvNavegador.Buttons.Prior.Click;
end;

procedure TfrmMtoGen.actRegistroSiguienteExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    nvNavegador.Buttons.Next.Click;
end;

procedure TfrmMtoGen.actInsertarRegistroExecute(Sender: TObject);
begin
  if Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     PuedeAccionMto(apmInsertar) then
    InsertarRegistroSinQuedarAMedias;
end;

procedure TfrmMtoGen.actPrimerRegistroExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    dsTablaG.DataSet.First;
end;

procedure TfrmMtoGen.actUltimoRegistroExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    dsTablaG.DataSet.Last;
end;

// Ctrl+AvPag / Ctrl+RePag: salto de bloque en el grid principal. Las teclas
// AvPag / RePag sueltas ya mueven de registro en registro
// (actRegistroSiguiente / actRegistroAnterior); con Ctrl saltan un bloque de
// SALTO_BLOQUE filas de una vez.
procedure TfrmMtoGen.actAvanzarBloqueExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    MoverFocoGridBloque(True);
end;

procedure TfrmMtoGen.actRetrocederBloqueExecute(Sender: TObject);
begin
  if PuedeCambiarRegistroPorTecla then
    MoverFocoGridBloque(False);
end;

// Alt+F5: vuelve a leer de la base de datos la tabla principal (lo que
// hayan grabado otros puestos u otras pantallas). Solo en consulta: con
// un registro en edicion se perderian los cambios sin grabar. UniDAC
// conserva el registro activo por su clave al refrescar.
procedure TfrmMtoGen.actRefrescarUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (dsTablaG.State = dsBrowse);
end;

procedure TfrmMtoGen.actRefrescarExecute(Sender: TObject);
var
  crAnterior: TCursor;
begin
  crAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    dsTablaG.DataSet.Refresh;
  finally
    Screen.Cursor := crAnterior;
  end;
end;

// Mueve el foco del grid principal un bloque de filas respetando la
// ordenacion visual del grid via FocusedRowIndex (igual que Ctrl+Inicio /
// Ctrl+Fin). Clampa a [0, ultima fila] para no salirse del dataset.
procedure TfrmMtoGen.MoverFocoGridBloque(AAvanzar: Boolean);
const
  SALTO_BLOQUE = 10;  // filas por pulsacion de Ctrl+AvPag / Ctrl+RePag
var
  iDelta  : Integer;
  iNuevo  : Integer;
  iUltimo : Integer;
begin
  if AAvanzar then
    iDelta := SALTO_BLOQUE
  else
    iDelta := -SALTO_BLOQUE;
  if Assigned(cxGrdDBTabPrin) then
  begin
    iUltimo := cxGrdDBTabPrin.DataController.RowCount - 1;
    if iUltimo >= 0 then
    begin
      iNuevo := cxGrdDBTabPrin.DataController.FocusedRowIndex + iDelta;
      if iNuevo < 0 then
        iNuevo := 0;
      if iNuevo > iUltimo then
        iNuevo := iUltimo;
      cxGrdDBTabPrin.DataController.FocusedRowIndex := iNuevo;
    end;
  end;
end;

procedure TfrmMtoGen.actEditarRegistroExecute(Sender: TObject);
begin
  if Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     PuedeAccionMto(apmModificar) then
    dsTablaG.DataSet.Edit;
end;

procedure TfrmMtoGen.actGrabarRegistroUpdate(Sender: TObject);
var
  bPermitido: Boolean;
begin
  bPermitido :=
    ((dsTablaG.State = dsInsert) and
     PuedeAccionMto(apmInsertar)) or
    ((dsTablaG.State = dsEdit) and
     PuedeAccionMto(apmModificar));
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    bPermitido;
end;

procedure TfrmMtoGen.actGrabarRegistroExecute(Sender: TObject);
begin
  if Assigned(dsTablaG.DataSet) and
     (((dsTablaG.State = dsInsert) and
       PuedeAccionMto(apmInsertar)) or
      ((dsTablaG.State = dsEdit) and
       PuedeAccionMto(apmModificar))) then
    btnGrabarClick(Sender);
end;

procedure TfrmMtoGen.actFotoArticuloExecute(Sender: TObject);
begin
  FGestorArticulos.AlternarFoto;
end;

procedure TfrmMtoGen.actConsultaStockExecute(Sender: TObject);
begin
  FGestorArticulos.ConsultarStock;
end;

procedure TfrmMtoGen.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
begin
  FGestorArticulos.ResolverPorDefecto(
    ACodArt, ACodSku);
end;

procedure TfrmMtoGen.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  ResolverArtSkuActivo(ACodArt, ACodSku);
end;

function TfrmMtoGen.DataSourcesParaFoto: TArray<TDataSource>;
begin
  Result := FGestorArticulos.DataSourcesPorDefecto;
end;

function TfrmMtoGen.NombreCampoESACTIVO: string;
begin
  Result := '';
end;

function TfrmMtoGen.ContarHijosActivos: Integer;
begin
  Result := 0;
end;

function TfrmMtoGen.DescripcionHijos: string;
begin
  Result := '';
end;

procedure TfrmMtoGen.SimulateTabKey;
var
  Inputs: array[0..1] of TInput;
begin
  ZeroMemory(@Inputs, SizeOf(Inputs));
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_TAB;
  Inputs[1].Itype := INPUT_KEYBOARD;
  Inputs[1].ki.wVk := VK_TAB;
  Inputs[1].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(2, Inputs[0], SizeOf(TInput));
end;

procedure TfrmMtoGen.FormShow(Sender: TObject);
begin
  inherited;
  ResetForm;
  ActualizarAltoBarraLateral(nil);
  // Si la pantalla flotante de fotos ya esta abierta (el usuario
  // pulso Ctrl+F en otro Mto), la re-vinculamos a este. Si no
  // esta abierta, no la abrimos: que aparezca solo cuando el usuario
  // lo pida con Ctrl+F.
  if Assigned(FAnfitrionMto) then
    FAnfitrionMto.VincularFotoMantenimiento(Self);
  // Foco inicial en la busqueda global del Mto. Se difiere con ForceQueue
  // porque el Mto se acaba de embeber en su TcxTabSheet (inLibFormManager)
  // y la cadena de foco aun no esta asentada: un SetFocus sincrono aqui no
  // "pega" (por eso seguia desactivado en ResetForm). La carga async de la
  // lista no roba el foco de ventana, asi que al drenar la cola el foco
  // queda en la busqueda. CanFocus salta la instancia de busqueda (Ctrl+R),
  // donde edtBusqGlobal va oculto.
  TThread.ForceQueue(nil,
    procedure
    begin
      if (not (csDestroying in ComponentState)) and
         edtBusqGlobal.CanFocus then
        edtBusqGlobal.SetFocus;
    end);
end;

procedure TfrmMtoGen.pcPantallaPageChanging(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);
begin
  inherited;
  if ( (not NewPage.Visible) and
       (not NewPage.Enabled) and
       (NewPage.Name = 'tsFicha')) then
    AllowChange := False;
end;

procedure TfrmMtoGen.ProcesarPerfiles;
begin
  FGestorPerfiles.CargarPerfil(
    IdentidadSesion.Usuario, IdentidadSesion.Grupo);
  oPerfilDic := FGestorPerfiles.Perfil;
  CrearTablaPrincipal;
  AplicarEtiquetas;
  // Alto/ancho de los paneles con separador grabado con Alt+F12.
  FGestorPerfiles.RestaurarSeparadores;
  FGestorGuias.ReaplicarVisibilidad;
  // Permisos por pantalla: ocultan/deshabilitan los controles segun
  // consultar, insertar, modificar, borrar, excel e imprimir.
  AplicarPermisosPantalla;
end;

procedure TfrmMtoGen.rbBBDDClick(Sender: TObject);
begin
  inherited;
  if (rbBBDD.Checked = true) then
    rbGrid.Checked := false
  else
    rbGrid.Checked := true;
end;

procedure TfrmMtoGen.rbGridClick(Sender: TObject);
begin
  inherited;
  if rbGrid.Checked = true then
    rbBBDD.Checked := false
  else
    rbBBDD.Checked := true;
end;

procedure TfrmMtoGen.ResetForm;
begin
  if ((pcPantalla.ActivePage <> tsLista) and (tsLista.TabVisible = true)) then
    pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoGen.edtBusqGlobalPropertiesChange(Sender: TObject);
begin
  inherited;
  tmrBusqGlobal.Enabled := False;
  if not (csDestroying in ComponentState) then
    tmrBusqGlobal.Enabled := True;
end;

procedure TfrmMtoGen.tmrBusqGlobalTimer(Sender: TObject);
begin
  inherited;
  tmrBusqGlobal.Enabled := False;
  if not (csDestroying in ComponentState) and
     Assigned(cxGrdDBTabPrin.DataController.DataSource) and
     Assigned(cxGrdDBTabPrin.DataController.DataSet) then
  begin
    // El filtro de cxGrid hace Post implícito. Esperar a que el usuario
    // guarde o cancele, incluyendo las ediciones del detalle.
    if HayEdicionesPendientes or
       (cxGrdDBTabPrin.DataController.DataSet.State in dsEditModes) then
      tmrBusqGlobal.Enabled := True
    else if cxGrdDBTabPrin.DataController.DataSet.Active then
    begin
      BusqAllGrid(cxGrdDBTabPrin, edtBusqGlobal.Text);
      if (pcPantalla.ActivePage <> tsLista) and tsLista.TabVisible then
        pcPantalla.ActivePage := tsLista;
    end;
  end;
end;

procedure TfrmMtoGen.btnCancelarClick(Sender: TObject);
var
  i: Integer;
begin
  inherited;
  // Flujo normal dentro de viracash: cancela el Mto activo del principal.
  if Assigned(FAnfitrionMto) then
    FAnfitrionMto.CancelarEdicionesPantallas
  else
    // Fuera de viracash (pruebas standalone, DESARROLLOS EN CURSO) Owner no
    // es el principal y no hay pcPrincipal al que cancelar:
    // se cancelan los datasets en edicion de los grids de ESTE form.
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TcxGridDBTableView then
        if (TcxGridDBTableView(Components[i]).DataController.DataSource <>
            nil) and
           (TcxGridDBTableView(Components[i]).DataController.DataSet <>
            nil) and
           (TcxGridDBTableView(Components[i]).DataController.DataSet.State in
            [dsEdit, dsInsert]) then
          TcxGridDBTableView(Components[i]).DataController.DataSet.Cancel;
end;

procedure TfrmMtoGen.sbExportExcelClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxGrdPrincipal, 'Listado');
end;

procedure TfrmMtoGen.EjecutarModalGuias;
var
  oFormulario: TfrmModalGridGuias;
begin
  oFormulario := TfrmModalGridGuias.Create(
    Application,
    FiltrosGuias);
  try
    oFormulario.sFormulario := Self.Name;
    oFormulario.FDataSet := nil;
    if Assigned(dsTablaG) and
       Assigned(dsTablaG.DataSet) then
      oFormulario.FDataSet := dsTablaG.DataSet;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

function TfrmMtoGen.SolicitarDestinoPerfil(
  const ADescripcion: string;
  ADescripcionEditable: Boolean;
  out APermisos: string): Boolean;
begin
  Result := SolicitarDestinoPerfilMto(
    Application,
    Self.Name,
    ADescripcion,
    ADescripcionEditable,
    APermisos);
end;

// ===========================================================================
//   Filtros guardados (desplegable junto a "Guardar Excel")
// ===========================================================================
// Guardan y comparten DataController.Filter de la lista principal con
// nombre propio. Independientes del filtro incidental que ya guarda
// "Grabar Grid" (sbGrabarGridClick) junto con el layout. Ver
// Los contratos de lectura, escritura y comparticion dan acceso a BBDD
// (fza_filtros_guardados / fza_filtros_guardados_compartidos).

procedure TfrmMtoGen.sbFiltrosClick(Sender: TObject);
begin
  FGestorFiltros.MostrarMenu(sbFiltros);
end;

initialization

finalization

end.
