{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFrmBase                                                  }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario base que distribuye servicios y aplica el idioma central a     }
{    controles propios, resourcestring y recursos de Developer Express.       }
{******************************************************************************}
unit inMtoFrmBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Data.DB, Vcl.Graphics, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxClasses, cxLocalization, cxContainer,
  cxEdit, cxLabel, cxDropDownEdit, dxSkinsCore, dxSkinsDefaultPainters,
  cxLookAndFeels, dxSkinsForm, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinDarkRoom, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinHighContrast, dxSkinMetropolis, dxSkinMetropolisDark,
  dxSkinOffice2010Black, dxSkinOffice2010Blue, dxSkinOffice2010Silver,
  dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp,
  dxSkinSharpPlus, dxSkinSpringTime, dxSkinTheAsphaltWorld, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinStardust, dxSkinSummer2008,
  dxSkinValentine, dxSkinXmas2008Blue, dxSkinscxPCPainter, dxCore, cxStyles,
  dxSkinBasic, dxSkinCaramel, dxSkinCoffee, dxSkinDarkSide, dxSkinGlassOceans,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMoneyTwins, dxSkinOffice2007Black, dxSkinOffice2007Blue,
  dxSkinOffice2007Green, dxSkinOffice2007Pink, dxSkinOffice2007Silver,
  dxSkinOffice2016Colorful, dxSkinOffice2016Dark, dxSkinOffice2019Black,
  dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSilver, dxSkinTheBezier, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, JvComponentBase,
  JvEnterTab, Uni, inLibPermisosIntf, inLibConexionesIntf,
  inLibAuditoriaDatosIntf, inLibMonitorSQLIntf,
  inLibContextoSesionIntf, inLibFiltrosGuardadosIntf,
  inLibDestinosFiltrosPersistenciaIntf,
  inLibGuiasPersistenciaIntf,
  inLibPerfilesUsuarioIntf, inLibParametrosIntf,
  inLibInformesGuiasCache, inLibTraduccionesIntf,
  inLibLogIntf,
  inLibConfigCamposIntf,
  inLibFotos, inLibUnidadesMedida,
  inLibGenBusq, inLibDistribuidorTallas, inLibLayoutForm,
  inLibPreviewTicket, inLibPreviewExcel, inLibResplandorBordesVcl,
  inLibReagpVcl, cxGridCustomTableView, cxGraphics;

type
  TEnterAsTabEstado = record
    Componente : TJvEnterAsTab;
    EnterAsTab : Boolean;
  end;

  TfrmBase = class(
    TForm,
    IProveedorPermisosAplicacion,
    IProveedorConexiones,
    IProveedorAuditoriaDatos,
    IProveedorMonitorSQL,
    IProveedorContextoSesion,
    IProveedorFiltrosGuardados,
    IProveedorPerfilesUsuario,
    IProveedorParametros,
    IProveedorInformesGuiasCache,
    IProveedorTraducciones,
    IProveedorRegistroLog,
    IProveedorConfiguracionCampos,
    IProveedorFotosArticulos,
    IProveedorUnidadesMedida,
    IProveedorBusquedaVisual,
    IProveedorDistribuidorTallasVisual,
    IProveedorSolicitudPermisoLayout,
    IProveedorPreviewTicket,
    IContenedorProveedorPreviewExcel
  )
    Localizer1: TcxLocalizer;
    jvntrstb1: TJvEnterAsTab;
    procedure FormCreate(Sender: TObject);
  private
    FPermisos: IPermisosAplicacion;
    FConexiones: IServicioConexiones;
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FMonitorSQL: IServicioMonitorSQL;
    FContextoSesion: IContextoSesionAplicacion;
    FFiltrosLectura: ILectorFiltrosGuardados;
    FFiltrosEscritura: IEscritorFiltrosGuardados;
    FFiltrosComparticion: ICompartidorFiltrosGuardados;
    FFiltrosDestinos: IRepositorioDestinosFiltros;
    FFiltrosGuias: IRepositorioGuias;
    FPerfilesLectura: ILectorPerfilesUsuario;
    FPerfilesEscritura: IEscritorPerfilesUsuario;
    FCachePerfiles: ICachePerfilesUsuario;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FInformesGuiasCache: IInformesGuiasCache;
    FTraducciones: IServicioTraducciones;
    FFotosArticulos: TFotosArticulos;
    FUnidadesMedida: TUnidadesMedida;
    FBusquedaVisual: IBusquedaVisual;
    FDistribuidorTallasVisual: IDistribuidorTallasVisual;
    FSolicitudPermisoLayout: ISolicitudPermisoLayout;
    FPreviewTicket: IPreviewTicket;
    FProveedorPreviewExcel: IProveedorPreviewExcel;
    FRegistroLog: IRegistroLog;
    FConfiguracionCampos: IConfiguracionCampos;
    FEnterAsTabEstados: array of TEnterAsTabEstado;
    FEnterAsTabTemporalActivo: Boolean;
    FResplandorBordes: TResplandorBordesVentana;
    FEstiloSeleccionInactiva: TcxStyle;
    procedure SeleccionInactivaGetStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TObject; var AStyle: TcxStyle);
    procedure SeleccionInactivaCustomDraw(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    function GetPermisos: IPermisosAplicacion;
    function GetConexiones: IServicioConexiones;
    function GetAuditoriaDatos: IServicioAuditoriaDatos;
    function GetMonitorSQL: IServicioMonitorSQL;
    function GetContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    function GetUbicacionSesion: TUbicacionSesion;
    function GetFiltrosLectura: ILectorFiltrosGuardados;
    function GetFiltrosEscritura: IEscritorFiltrosGuardados;
    function GetFiltrosComparticion: ICompartidorFiltrosGuardados;
    function GetServiciosFiltrosGuardados: TServiciosFiltrosGuardados;
    function GetPerfilesLectura: ILectorPerfilesUsuario;
    function GetPerfilesEscritura: IEscritorPerfilesUsuario;
    function GetCachePerfiles: ICachePerfilesUsuario;
    function GetServiciosPerfilesUsuario: TServiciosPerfilesUsuario;
    function GetParametrosApp: IParametrosAplicacion;
    function GetParametrosCaja: IParametrosCaja;
    function GetInformesGuiasCache: IInformesGuiasCache;
    function GetTraducciones: IServicioTraducciones;
    function GetFotosArticulos: TFotosArticulos;
    function GetUnidadesMedida: TUnidadesMedida;
    function GetBusquedaVisual: IBusquedaVisual;
    function GetDistribuidorTallasVisual: IDistribuidorTallasVisual;
    function GetSolicitudPermisoLayout: ISolicitudPermisoLayout;
    function GetPreviewTicket: IPreviewTicket;
    function GetProveedorPreviewExcel: IProveedorPreviewExcel;
    function GetRegistroLog: IRegistroLog;
    function GetConfiguracionCampos: IConfiguracionCampos;
    function GetConexionPrincipal: TUniConnection;
    function NormalizarSegmentoClaveTraduccion(
      const ATexto: string): string;
    procedure HeredarServicios(
      AOwner: TComponent;
      AResolverPermisos: Boolean);
    procedure HeredarConexiones(AOwner: TComponent);
    procedure HeredarAuditoriaDatos(AOwner: TComponent);
    procedure HeredarMonitorSQL(AOwner: TComponent);
    procedure HeredarContextoSesion(AOwner: TComponent);
    procedure HeredarFiltrosGuardados(AOwner: TComponent);
    procedure HeredarPerfilesUsuario(AOwner: TComponent);
    procedure HeredarParametros(AOwner: TComponent);
    procedure HeredarInformesGuiasCache(AOwner: TComponent);
    procedure HeredarTraducciones(AOwner: TComponent);
    procedure HeredarRegistroLog(AOwner: TComponent);
    procedure HeredarConfiguracionCampos(AOwner: TComponent);
    procedure HeredarFotosArticulos(AOwner: TComponent);
    procedure HeredarUnidadesMedida(AOwner: TComponent);
    procedure HeredarBusquedaVisual(AOwner: TComponent);
    procedure HeredarDistribuidorTallasVisual(AOwner: TComponent);
    procedure HeredarSolicitudPermisoLayout(AOwner: TComponent);
    procedure HeredarPreviewTicket(AOwner: TComponent);
    procedure HeredarProveedorPreviewExcel(AOwner: TComponent);
    procedure GuardarEnterAsTabDe(AOwner: TComponent);
    procedure AplicarIdiomaDevExpress;
    procedure TraducirDevExpress(
      const AResStringName: string;
      var AResStringValue: string;
      var AHandled: Boolean);
    function EnterAsTabGuardado(AComp: TJvEnterAsTab): Boolean;
    // Fin de la sesión de Windows (cierre de sesión de Terminal Server,
    // apagado): ninguna ventana lo veta, aunque haya cambios sin grabar.
    procedure WMQueryEndSession(
      var Message: TWMQueryEndSession); message WM_QUERYENDSESSION;
  protected
    procedure Loaded; override;
    /// Nivel del parámetro appDegradadoBordes (suave si aún no hay
    /// parámetros).
    function IntensidadDegradadoBordes: TIntensidadResplandor;
    // Hooks de log avanzado a nivel de formulario. Se loguean solo si
    // ltAvanzado esta activo en TLog (parametro appLogAvanzado).
    procedure DoShow; override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    // Degradado de los bordes (inLibResplandorBordesVcl): sigue la ventana.
    procedure WndProc(var Message: TMessage); override;
    procedure ConfigurarBotonBusquedaDesplegable(
      AControl: TcxCustomDropDownEdit;
      AEvento: TcxEditButtonClickEvent);
    procedure DesactivarEnterAsTabTemporal(Sender: TObject);
    procedure RestaurarEnterAsTabTemporal(Sender: TObject);
    procedure ActualizarAuditoria(DataSet: TDataSet);
    procedure CerrarMonitorSQLPendiente;
    function TraducirCategoriaParametro(
      const AUnidad, ACategoria: string): string;
    function TraducirDescripcionParametro(
      const AUnidad: string;
      const AParametro: TParamInfo): string;
    property RegistroLog: IRegistroLog read GetRegistroLog;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent;
                       const APermisos: IPermisosAplicacion); reintroduce;
                       overload;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla); reintroduce;
      overload;
    destructor Destroy; override;
    /// Vuelve a leer el parámetro appDegradadoBordes y repinta los bordes.
    /// La principal lo amplía al degradado de su fondo.
    procedure AplicarDegradadoBordes; virtual;
    procedure AsignarPermisos(const APermisos: IPermisosAplicacion);
    procedure AsignarConexiones(
      const AConexiones: IServicioConexiones);
    procedure AsignarAuditoriaDatos(
      const AAuditoriaDatos: IServicioAuditoriaDatos);
    procedure AsignarMonitorSQL(
      const AMonitorSQL: IServicioMonitorSQL);
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
    procedure AsignarFiltrosGuardados(
      const AServicios: TServiciosFiltrosGuardados);
    procedure AsignarPerfilesUsuario(
      const AServicios: TServiciosPerfilesUsuario);
    procedure AsignarParametros(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja);
    procedure AsignarInformesGuiasCache(
      const AInformesGuiasCache: IInformesGuiasCache);
    procedure AsignarTraducciones(
      const ATraducciones: IServicioTraducciones);
    procedure AsignarRegistroLog(
      const ARegistroLog: IRegistroLog);
    procedure AsignarConfiguracionCampos(
      const AConfiguracionCampos: IConfiguracionCampos);
    procedure AplicarTraduccionActual; virtual;
    procedure AplicarContrasteSeleccionInactiva;
    procedure AsignarFotosArticulos(AFotos: TFotosArticulos);
    procedure AsignarUnidadesMedida(AUnidades: TUnidadesMedida);
    procedure AsignarServiciosVisuales(
      const ABusqueda: IBusquedaVisual;
      const ADistribuidorTallas: IDistribuidorTallasVisual;
      const ASolicitudPermisoLayout: ISolicitudPermisoLayout;
      const APreviewTicket: IPreviewTicket;
      const AProveedorPreviewExcel: IProveedorPreviewExcel);
    // Articulo/sku del registro/linea en foco, para la consulta de stock
    // global (Ctrl+U, capturado en inMtoPrincipal). Por defecto vacio; los
    // formularios con articulo activo lo sobreescriben.
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); virtual;
    // KeyPreview prestado: en las pantallas embebidas en pestanas del
    // principal la VCL entrega el OnKeyPress de los controles a la
    // ventana superior, no a este formulario. inMtoPrincipal se lo
    // reenvia aqui para que su propio OnKeyPress (p. ej. el lector de
    // codigo de barras de inLibLectorDocumento) vea la tecla antes que
    // el control con foco.
    procedure PrevisualizarTeclaEmbebida(var Key: Char); virtual;
    // FZ-ISSUE-435: la pestaña de este formulario vuelve a ser la activa
    // del principal. Para releer lo que otra pantalla pudo cambiar; por
    // defecto no hace nada.
    procedure PestanaActivada; virtual;
    // FZ-ISSUE-430: Esc en una pestaña embebida. True si el formulario
    // tenia una edicion sin grabar y la ha descartado: el principal no
    // cierra entonces la ficha. Por defecto no hay nada que descartar.
    function CancelarEdicionConEscape: Boolean; virtual;
    property Permisos: IPermisosAplicacion read GetPermisos;
    property Conexiones: IServicioConexiones read GetConexiones;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read GetAuditoriaDatos;
    property MonitorSQL: IServicioMonitorSQL read GetMonitorSQL;
    property ContextoSesion: IContextoSesionAplicacion
      read GetContextoSesion;
    property IdentidadSesion: TIdentidadSesion
      read GetIdentidadSesion;
    property UbicacionSesion: TUbicacionSesion
      read GetUbicacionSesion;
    property FiltrosLectura: ILectorFiltrosGuardados
      read GetFiltrosLectura;
    property FiltrosEscritura: IEscritorFiltrosGuardados
      read GetFiltrosEscritura;
    property FiltrosComparticion: ICompartidorFiltrosGuardados
      read GetFiltrosComparticion;
    property FiltrosDestinos: IRepositorioDestinosFiltros
      read FFiltrosDestinos;
    property FiltrosGuias: IRepositorioGuias read FFiltrosGuias;
    property PerfilesLectura: ILectorPerfilesUsuario
      read GetPerfilesLectura;
    property PerfilesEscritura: IEscritorPerfilesUsuario
      read GetPerfilesEscritura;
    property CachePerfiles: ICachePerfilesUsuario
      read GetCachePerfiles;
    property ParametrosApp: IParametrosAplicacion read GetParametrosApp;
    property ParametrosCaja: IParametrosCaja read GetParametrosCaja;
    property InformesGuiasCache: IInformesGuiasCache
      read GetInformesGuiasCache;
    property Traducciones: IServicioTraducciones
      read GetTraducciones;
    property FotosArticulos: TFotosArticulos
      read GetFotosArticulos;
    property UnidadesMedida: TUnidadesMedida
      read GetUnidadesMedida;
    property BusquedaVisual: IBusquedaVisual
      read GetBusquedaVisual;
    property DistribuidorTallasVisual: IDistribuidorTallasVisual
      read GetDistribuidorTallasVisual;
    property SolicitudPermisoLayout: ISolicitudPermisoLayout
      read GetSolicitudPermisoLayout;
    property PreviewTicket: IPreviewTicket read GetPreviewTicket;
    property ProveedorPreviewExcel: IProveedorPreviewExcel
      read GetProveedorPreviewExcel;
    property ConexionPrincipal: TUniConnection read GetConexionPrincipal;
    property ConfiguracionCampos: IConfiguracionCampos
      read GetConfiguracionCampos;
  end;

implementation

uses
  inLibRegistroLogNulo, inLibMsgComun, inLibTraducciones,
  inLibPosicionFormulario, inLibEditorCodigoSkin, System.Math,
  cxLookAndFeelPainters, inLibFuenteInterfaz;

{$R *.dfm}

type
  TControlFuenteAcceso = class(TControl);
  TVistaContrasteAcceso = class(TcxCustomGridTableView);
  TContrasteDibujoVista = class(TComponent)
  private
    FFormulario: TfrmBase;
    FAnterior: TcxGridTableDataCellCustomDrawEvent;
    procedure Dibujar(Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
  public
    constructor Crear(AVista: TcxCustomGridTableView; AFormulario: TfrmBase);
    procedure Actualizar(AVista: TcxCustomGridTableView);
  end;

constructor TContrasteDibujoVista.Crear(AVista: TcxCustomGridTableView;
  AFormulario: TfrmBase);
begin
  inherited Create(AVista);
  FFormulario := AFormulario;
  Actualizar(AVista);
end;

procedure TContrasteDibujoVista.Actualizar(AVista: TcxCustomGridTableView);
var
  Actual, Propio: TcxGridTableDataCellCustomDrawEvent;
begin
  Actual := AVista.OnCustomDrawCell;
  Propio := Dibujar;
  if (TMethod(Actual).Code <> TMethod(Propio).Code) or
     (TMethod(Actual).Data <> TMethod(Propio).Data) then
  begin
    FAnterior := Actual;
    AVista.OnCustomDrawCell := Propio;
  end;
end;

procedure TContrasteDibujoVista.Dibujar(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  if Assigned(FAnterior) then
    FAnterior(Sender, ACanvas, AViewInfo, ADone);
  FFormulario.SeleccionInactivaCustomDraw(Sender, ACanvas, AViewInfo, ADone);
end;

function LuminanciaSeleccion(AColor: TColor): Double;
var
  ColorRgb: Cardinal;
  Canales: array[0..2] of Double;
  Indice: Integer;
begin
  ColorRgb := ColorToRGB(AColor);
  Canales[0] := GetRValue(ColorRgb) / 255;
  Canales[1] := GetGValue(ColorRgb) / 255;
  Canales[2] := GetBValue(ColorRgb) / 255;
  for Indice := 0 to 2 do
    if Canales[Indice] <= 0.04045 then
      Canales[Indice] := Canales[Indice] / 12.92
    else
      Canales[Indice] := Power((Canales[Indice] + 0.055) / 1.055, 2.4);
  Result := Canales[0] * 0.2126 + Canales[1] * 0.7152 +
    Canales[2] * 0.0722;
end;

function TextoSeleccionLegible(AFondo, ATexto: TColor): TColor;
var
  LuzFondo, LuzTexto, Razon: Double;
begin
  Result := ATexto;
  LuzFondo := LuminanciaSeleccion(AFondo);
  LuzTexto := LuminanciaSeleccion(ATexto);
  Razon := (Max(LuzFondo, LuzTexto) + 0.05) /
    (Min(LuzFondo, LuzTexto) + 0.05);
  if Razon < 7.0 then
  begin
    if (LuzFondo + 0.05) / 0.05 > 1.05 / (LuzFondo + 0.05) then
      Result := clBlack
    else
      Result := clWhite;
  end;
end;

procedure TfrmBase.SeleccionInactivaGetStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TObject; var AStyle: TcxStyle);
var
  Pintor: TcxCustomLookAndFeelPainter;
  Fondo, Texto: TColor;
begin
  Pintor := Sender.LookAndFeelPainter;
  Fondo := Pintor.DefaultInactiveColor;
  Texto := Pintor.DefaultInactiveTextColor;
  if Sender.Styles.Inactive <> nil then
  begin
    if svColor in Sender.Styles.Inactive.AssignedValues then
      Fondo := Sender.Styles.Inactive.Color;
    if svTextColor in Sender.Styles.Inactive.AssignedValues then
      Texto := Sender.Styles.Inactive.TextColor;
  end;
  FEstiloSeleccionInactiva.Color := Fondo;
  FEstiloSeleccionInactiva.TextColor := TextoSeleccionLegible(Fondo, Texto);
  AStyle := FEstiloSeleccionInactiva;
end;

procedure TfrmBase.SeleccionInactivaCustomDraw(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  if not ADone and AViewInfo.Selected and
     not TVistaContrasteAcceso(Sender).DrawRecordActive(
       AViewInfo.GridRecord) then
    // DevExpress devuelve estos colores al editor en AfterCustomDraw.
    // Medir el fondo real evita depender del color teórico del skin.
    ACanvas.Font.Color := TextoSeleccionLegible(
      ACanvas.Brush.Color, ACanvas.Font.Color);
end;

procedure TfrmBase.AplicarContrasteSeleccionInactiva;

  procedure Aplicar(AComponente: TComponent);
  var
    Indice, IndiceAdaptador: Integer;
    Vista: TcxCustomGridTableView;
    Adaptador: TContrasteDibujoVista;
  begin
    if AComponente is TcxCustomGridTableView then
    begin
      Vista := TcxCustomGridTableView(AComponente);
      if not Assigned(Vista.Styles.OnGetInactiveStyle) then
        Vista.Styles.OnGetInactiveStyle := SeleccionInactivaGetStyle;
      Adaptador := nil;
      for IndiceAdaptador := 0 to Vista.ComponentCount - 1 do
        if Vista.Components[IndiceAdaptador] is TContrasteDibujoVista then
          Adaptador := TContrasteDibujoVista(
            Vista.Components[IndiceAdaptador]);
      if Adaptador = nil then
        TContrasteDibujoVista.Crear(Vista, Self)
      else
        Adaptador.Actualizar(Vista);
    end;
    for Indice := 0 to AComponente.ComponentCount - 1 do
      Aplicar(AComponente.Components[Indice]);
  end;

begin
  if FEstiloSeleccionInactiva = nil then
  begin
    FEstiloSeleccionInactiva := TcxStyle.Create(Self);
    FEstiloSeleccionInactiva.AssignedValues := [svColor, svTextColor];
  end;
  Aplicar(Self);
end;
{$R CXLOCALIZATION.res}

procedure TfrmBase.Loaded;
var
  oControl: TControlFuenteAcceso;
  i: Integer;
begin
  // Antes de que VCL escale el DFM: una altura de texto cero deforma
  // el formulario completo, no solo sus etiquetas y botones.
  if not (csDesigning in ComponentState) then
  begin
    Font.Name := NombreFuenteInterfaz(Font.Name);
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TControl then
      begin
        oControl := TControlFuenteAcceso(Components[i]);
        oControl.Font.Name := NombreFuenteInterfaz(oControl.Font.Name);
      end;
  end;
  inherited;
end;

constructor TfrmBase.Create(AOwner: TComponent);
begin
  FPermisos := nil;
  HeredarServicios(AOwner, True);
  inherited Create(AOwner);
end;

constructor TfrmBase.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion);
begin
  FPermisos := APermisos;
  HeredarServicios(AOwner, False);
  inherited Create(AOwner);
end;

procedure TfrmBase.HeredarServicios(
  AOwner: TComponent;
  AResolverPermisos: Boolean);
var
  ProveedorPermisos: IProveedorPermisosAplicacion;
begin
  HeredarRegistroLog(AOwner);
  HeredarConfiguracionCampos(AOwner);
  if AResolverPermisos and
     Supports(
       AOwner,
       IProveedorPermisosAplicacion,
       ProveedorPermisos) then
    FPermisos := ProveedorPermisos.Permisos;
  HeredarConexiones(AOwner);
  HeredarAuditoriaDatos(AOwner);
  HeredarMonitorSQL(AOwner);
  HeredarContextoSesion(AOwner);
  HeredarFiltrosGuardados(AOwner);
  HeredarPerfilesUsuario(AOwner);
  HeredarParametros(AOwner);
  HeredarInformesGuiasCache(AOwner);
  HeredarTraducciones(AOwner);
  HeredarFotosArticulos(AOwner);
  HeredarUnidadesMedida(AOwner);
  HeredarBusquedaVisual(AOwner);
  HeredarDistribuidorTallasVisual(AOwner);
  HeredarSolicitudPermisoLayout(AOwner);
  HeredarPreviewTicket(AOwner);
  HeredarProveedorPreviewExcel(AOwner);
end;

constructor TfrmBase.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla);
begin
  Create(AOwner, AContexto.Permisos);
end;

destructor TfrmBase.Destroy;
begin
  // Ningun cierre puede dejar desactivado el EnterAsTab del propietario
  // o del formulario principal por un editor temporal ya destruido.
  RestaurarEnterAsTabTemporal(Self);
  FreeAndNil(FResplandorBordes);
  FRegistroLog := nil;
  FConfiguracionCampos := nil;
  FFotosArticulos := nil;
  FUnidadesMedida := nil;
  FBusquedaVisual := nil;
  FDistribuidorTallasVisual := nil;
  FSolicitudPermisoLayout := nil;
  FPreviewTicket := nil;
  FProveedorPreviewExcel := nil;
  inherited;
end;

function TfrmBase.NormalizarSegmentoClaveTraduccion(
  const ATexto: string): string;
var
  Caracter: Char;
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(ATexto) do
  begin
    Caracter := ATexto[i];
    case Caracter of
      'á', 'à', 'ä', 'â':
        Caracter := 'a';
      'é', 'è', 'ë', 'ê':
        Caracter := 'e';
      'í', 'ì', 'ï', 'î':
        Caracter := 'i';
      'ó', 'ò', 'ö', 'ô':
        Caracter := 'o';
      'ú', 'ù', 'ü', 'û':
        Caracter := 'u';
      'Á', 'À', 'Ä', 'Â':
        Caracter := 'A';
      'É', 'È', 'Ë', 'Ê':
        Caracter := 'E';
      'Í', 'Ì', 'Ï', 'Î':
        Caracter := 'I';
      'Ó', 'Ò', 'Ö', 'Ô':
        Caracter := 'O';
      'Ú', 'Ù', 'Ü', 'Û':
        Caracter := 'U';
    end;
    if CharInSet(
      Caracter,
      ['A'..'Z', 'a'..'z', '0'..'9']) then
      Result := Result + Caracter;
  end;
end;

function TfrmBase.TraducirCategoriaParametro(
  const AUnidad, ACategoria: string): string;
var
  Clave: string;
begin
  Result := ACategoria;
  if Assigned(FTraducciones) and
     (ACategoria <> '') then
  begin
    Clave := AUnidad + '.Parametros.Categoria.' +
             NormalizarSegmentoClaveTraduccion(ACategoria);
    Result := FTraducciones.Traducir(
      Clave,
      ACategoria);
  end;
end;

function TfrmBase.TraducirDescripcionParametro(
  const AUnidad: string;
  const AParametro: TParamInfo): string;
var
  Clave: string;
begin
  Result := AParametro.Descripcion;
  if Assigned(FTraducciones) then
  begin
    Clave := AUnidad + '.Parametros.' +
             AParametro.Nombre + '.Descripcion';
    Result := FTraducciones.Traducir(
      Clave,
      AParametro.Descripcion);
  end;
end;

procedure TfrmBase.HeredarConexiones(AOwner: TComponent);
var
  Proveedor: IProveedorConexiones;
begin
  FConexiones := nil;
  if Supports(AOwner, IProveedorConexiones, Proveedor) then
    FConexiones := Proveedor.Conexiones;
  if not Assigned(FConexiones) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorConexiones,
       Proveedor) then
    FConexiones := Proveedor.Conexiones;
end;

procedure TfrmBase.HeredarAuditoriaDatos(AOwner: TComponent);
var
  Proveedor: IProveedorAuditoriaDatos;
begin
  FAuditoriaDatos := nil;
  if Supports(AOwner, IProveedorAuditoriaDatos, Proveedor) then
    FAuditoriaDatos := Proveedor.AuditoriaDatos;
  if not Assigned(FAuditoriaDatos) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorAuditoriaDatos,
       Proveedor) then
    FAuditoriaDatos := Proveedor.AuditoriaDatos;
end;

procedure TfrmBase.HeredarMonitorSQL(AOwner: TComponent);
var
  Proveedor: IProveedorMonitorSQL;
begin
  FMonitorSQL := nil;
  if Supports(AOwner, IProveedorMonitorSQL, Proveedor) then
    FMonitorSQL := Proveedor.MonitorSQL;
  if not Assigned(FMonitorSQL) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorMonitorSQL,
       Proveedor) then
    FMonitorSQL := Proveedor.MonitorSQL;
end;

procedure TfrmBase.HeredarContextoSesion(AOwner: TComponent);
var
  Proveedor: IProveedorContextoSesion;
begin
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, Proveedor) then
    FContextoSesion := Proveedor.ContextoSesion;
  if not Assigned(FContextoSesion) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorContextoSesion,
       Proveedor) then
    FContextoSesion := Proveedor.ContextoSesion;
end;

procedure TfrmBase.HeredarFiltrosGuardados(AOwner: TComponent);
var
  Proveedor: IProveedorFiltrosGuardados;
  Servicios: TServiciosFiltrosGuardados;
begin
  FFiltrosLectura := nil;
  FFiltrosEscritura := nil;
  FFiltrosComparticion := nil;
  FFiltrosDestinos := nil;
  FFiltrosGuias := nil;
  if Supports(AOwner, IProveedorFiltrosGuardados, Proveedor) then
  begin
    Servicios := Proveedor.ServiciosFiltrosGuardados;
    FFiltrosLectura := Servicios.Lectura;
    FFiltrosEscritura := Servicios.Escritura;
    FFiltrosComparticion := Servicios.Comparticion;
    FFiltrosDestinos := Servicios.Destinos;
    FFiltrosGuias := Servicios.Guias;
  end;
  if not Assigned(FFiltrosLectura) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorFiltrosGuardados,
       Proveedor) then
  begin
    Servicios := Proveedor.ServiciosFiltrosGuardados;
    FFiltrosLectura := Servicios.Lectura;
    FFiltrosEscritura := Servicios.Escritura;
    FFiltrosComparticion := Servicios.Comparticion;
    FFiltrosDestinos := Servicios.Destinos;
    FFiltrosGuias := Servicios.Guias;
  end;
end;

procedure TfrmBase.HeredarPerfilesUsuario(AOwner: TComponent);
var
  Proveedor: IProveedorPerfilesUsuario;
  Servicios: TServiciosPerfilesUsuario;
begin
  FPerfilesLectura := nil;
  FPerfilesEscritura := nil;
  FCachePerfiles := nil;
  if Supports(AOwner, IProveedorPerfilesUsuario, Proveedor) then
  begin
    Servicios := Proveedor.ServiciosPerfilesUsuario;
    FPerfilesLectura := Servicios.Lectura;
    FPerfilesEscritura := Servicios.Escritura;
    FCachePerfiles := Servicios.Cache;
  end;
  if not Assigned(FPerfilesLectura) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorPerfilesUsuario,
       Proveedor) then
  begin
    Servicios := Proveedor.ServiciosPerfilesUsuario;
    FPerfilesLectura := Servicios.Lectura;
    FPerfilesEscritura := Servicios.Escritura;
    FCachePerfiles := Servicios.Cache;
  end;
end;

procedure TfrmBase.HeredarParametros(AOwner: TComponent);
var
  Proveedor: IProveedorParametros;
begin
  FParametrosApp := nil;
  FParametrosCaja := nil;
  if Supports(AOwner, IProveedorParametros, Proveedor) then
  begin
    FParametrosApp := Proveedor.ParametrosApp;
    FParametrosCaja := Proveedor.ParametrosCaja;
  end;
  if (not Assigned(FParametrosApp) or
      not Assigned(FParametrosCaja)) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorParametros,
       Proveedor) then
  begin
    FParametrosApp := Proveedor.ParametrosApp;
    FParametrosCaja := Proveedor.ParametrosCaja;
  end;
end;

procedure TfrmBase.HeredarInformesGuiasCache(AOwner: TComponent);
var
  Proveedor: IProveedorInformesGuiasCache;
begin
  FInformesGuiasCache := nil;
  if Supports(
    AOwner,
    IProveedorInformesGuiasCache,
    Proveedor
  ) then
    FInformesGuiasCache := Proveedor.InformesGuiasCache;
  if not Assigned(FInformesGuiasCache) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorInformesGuiasCache,
       Proveedor
     ) then
    FInformesGuiasCache := Proveedor.InformesGuiasCache;
end;

procedure TfrmBase.HeredarTraducciones(AOwner: TComponent);
var
  Proveedor: IProveedorTraducciones;
begin
  FTraducciones := nil;
  if Supports(AOwner, IProveedorTraducciones, Proveedor) then
    FTraducciones := Proveedor.Traducciones;
  if not Assigned(FTraducciones) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorTraducciones,
       Proveedor) then
    FTraducciones := Proveedor.Traducciones;
end;

procedure TfrmBase.HeredarFotosArticulos(AOwner: TComponent);
var
  Proveedor: IProveedorFotosArticulos;
begin
  FFotosArticulos := nil;
  if Supports(AOwner, IProveedorFotosArticulos, Proveedor) then
    FFotosArticulos := Proveedor.FotosArticulos;
  if not Assigned(FFotosArticulos) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorFotosArticulos,
       Proveedor) then
    FFotosArticulos := Proveedor.FotosArticulos;
end;

procedure TfrmBase.HeredarUnidadesMedida(AOwner: TComponent);
var
  Proveedor: IProveedorUnidadesMedida;
begin
  FUnidadesMedida := nil;
  if Supports(AOwner, IProveedorUnidadesMedida, Proveedor) then
    FUnidadesMedida := Proveedor.UnidadesMedida;
  if not Assigned(FUnidadesMedida) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorUnidadesMedida,
       Proveedor) then
    FUnidadesMedida := Proveedor.UnidadesMedida;
end;

procedure TfrmBase.HeredarBusquedaVisual(AOwner: TComponent);
var
  Proveedor: IProveedorBusquedaVisual;
begin
  FBusquedaVisual := nil;
  if Supports(AOwner, IProveedorBusquedaVisual, Proveedor) then
    FBusquedaVisual := Proveedor.BusquedaVisual;
  if not Assigned(FBusquedaVisual) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorBusquedaVisual,
       Proveedor) then
    FBusquedaVisual := Proveedor.BusquedaVisual;
end;

procedure TfrmBase.HeredarDistribuidorTallasVisual(AOwner: TComponent);
var
  Proveedor: IProveedorDistribuidorTallasVisual;
begin
  FDistribuidorTallasVisual := nil;
  if Supports(AOwner, IProveedorDistribuidorTallasVisual, Proveedor) then
    FDistribuidorTallasVisual := Proveedor.DistribuidorTallasVisual;
  if not Assigned(FDistribuidorTallasVisual) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorDistribuidorTallasVisual,
       Proveedor) then
    FDistribuidorTallasVisual := Proveedor.DistribuidorTallasVisual;
end;

procedure TfrmBase.HeredarSolicitudPermisoLayout(AOwner: TComponent);
var
  Proveedor: IProveedorSolicitudPermisoLayout;
begin
  FSolicitudPermisoLayout := nil;
  if Supports(AOwner, IProveedorSolicitudPermisoLayout, Proveedor) then
    FSolicitudPermisoLayout := Proveedor.SolicitudPermisoLayout;
  if not Assigned(FSolicitudPermisoLayout) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorSolicitudPermisoLayout,
       Proveedor) then
    FSolicitudPermisoLayout := Proveedor.SolicitudPermisoLayout;
end;

procedure TfrmBase.HeredarPreviewTicket(AOwner: TComponent);
var
  Proveedor: IProveedorPreviewTicket;
begin
  FPreviewTicket := nil;
  if Supports(AOwner, IProveedorPreviewTicket, Proveedor) then
    FPreviewTicket := Proveedor.PreviewTicket;
  if not Assigned(FPreviewTicket) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorPreviewTicket,
       Proveedor) then
    FPreviewTicket := Proveedor.PreviewTicket;
end;

procedure TfrmBase.HeredarProveedorPreviewExcel(AOwner: TComponent);
var
  Contenedor: IContenedorProveedorPreviewExcel;
begin
  FProveedorPreviewExcel := nil;
  if Supports(AOwner, IContenedorProveedorPreviewExcel, Contenedor) then
    FProveedorPreviewExcel := Contenedor.ProveedorPreviewExcel;
  if not Assigned(FProveedorPreviewExcel) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IContenedorProveedorPreviewExcel,
       Contenedor) then
    FProveedorPreviewExcel := Contenedor.ProveedorPreviewExcel;
end;

procedure TfrmBase.HeredarRegistroLog(AOwner: TComponent);
var
  Proveedor: IProveedorRegistroLog;
begin
  FRegistroLog := nil;
  if Supports(AOwner, IProveedorRegistroLog, Proveedor) then
    FRegistroLog := Proveedor.RegistroLog;
  if not Assigned(FRegistroLog) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorRegistroLog,
       Proveedor) then
    FRegistroLog := Proveedor.RegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
end;

procedure TfrmBase.HeredarConfiguracionCampos(AOwner: TComponent);
var
  Proveedor: IProveedorConfiguracionCampos;
begin
  FConfiguracionCampos := nil;
  if Supports(
       AOwner,
       IProveedorConfiguracionCampos,
       Proveedor) then
    FConfiguracionCampos := Proveedor.ConfiguracionCampos;
  if not Assigned(FConfiguracionCampos) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorConfiguracionCampos,
       Proveedor) then
    FConfiguracionCampos := Proveedor.ConfiguracionCampos;
end;

procedure TfrmBase.AsignarPermisos(
  const APermisos: IPermisosAplicacion);
begin
  FPermisos := APermisos;
end;

procedure TfrmBase.AsignarConexiones(
  const AConexiones: IServicioConexiones);
begin
  FConexiones := AConexiones;
end;

procedure TfrmBase.AsignarAuditoriaDatos(
  const AAuditoriaDatos: IServicioAuditoriaDatos);
begin
  FAuditoriaDatos := AAuditoriaDatos;
end;

procedure TfrmBase.AsignarMonitorSQL(
  const AMonitorSQL: IServicioMonitorSQL);
begin
  FMonitorSQL := AMonitorSQL;
end;

procedure TfrmBase.AsignarContextoSesion(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  FContextoSesion := AContextoSesion;
end;

procedure TfrmBase.AsignarFiltrosGuardados(
  const AServicios: TServiciosFiltrosGuardados);
begin
  FFiltrosLectura := AServicios.Lectura;
  FFiltrosEscritura := AServicios.Escritura;
  FFiltrosComparticion := AServicios.Comparticion;
  FFiltrosDestinos := AServicios.Destinos;
  FFiltrosGuias := AServicios.Guias;
end;

procedure TfrmBase.AsignarPerfilesUsuario(
  const AServicios: TServiciosPerfilesUsuario);
begin
  FPerfilesLectura := AServicios.Lectura;
  FPerfilesEscritura := AServicios.Escritura;
  FCachePerfiles := AServicios.Cache;
end;

procedure TfrmBase.AsignarParametros(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja);
begin
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
end;

procedure TfrmBase.AsignarInformesGuiasCache(
  const AInformesGuiasCache: IInformesGuiasCache);
begin
  FInformesGuiasCache := AInformesGuiasCache;
end;

procedure TfrmBase.AsignarTraducciones(
  const ATraducciones: IServicioTraducciones);
begin
  FTraducciones := ATraducciones;
  if Assigned(FTraducciones) then
    ActivarTraduccionResourcestrings(FTraducciones);
  if Assigned(Localizer1) then
    AplicarIdiomaDevExpress;
end;

procedure TfrmBase.AsignarRegistroLog(
  const ARegistroLog: IRegistroLog);
begin
  if Assigned(ARegistroLog) then
    FRegistroLog := ARegistroLog
  else
    FRegistroLog := CrearRegistroLogNulo;
end;

procedure TfrmBase.AsignarConfiguracionCampos(
  const AConfiguracionCampos: IConfiguracionCampos);
begin
  FConfiguracionCampos := AConfiguracionCampos;
end;

procedure TfrmBase.AplicarTraduccionActual;
begin
  if Assigned(FTraducciones) then
  begin
    ActivarTraduccionResourcestrings(FTraducciones);
    AplicarIdiomaDevExpress;
    FTraducciones.Aplicar(Self);
  end;
end;

function TfrmBase.GetPermisos: IPermisosAplicacion;
begin
  Result := FPermisos;
end;

function TfrmBase.GetConexiones: IServicioConexiones;
begin
  Result := FConexiones;
end;

function TfrmBase.GetAuditoriaDatos: IServicioAuditoriaDatos;
begin
  Result := FAuditoriaDatos;
end;

function TfrmBase.GetMonitorSQL: IServicioMonitorSQL;
begin
  Result := FMonitorSQL;
end;

function TfrmBase.GetContextoSesion: IContextoSesionAplicacion;
begin
  Result := FContextoSesion;
end;

function TfrmBase.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionFormularioNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function TfrmBase.GetUbicacionSesion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionFormularioNoConfigurado);
  Result := FContextoSesion.Ubicacion;
end;

function TfrmBase.GetFiltrosLectura: ILectorFiltrosGuardados;
begin
  Result := FFiltrosLectura;
end;

procedure TfrmBase.AsignarFotosArticulos(AFotos: TFotosArticulos);
begin
  FFotosArticulos := AFotos;
end;

procedure TfrmBase.AsignarUnidadesMedida(
  AUnidades: TUnidadesMedida);
begin
  FUnidadesMedida := AUnidades;
end;

procedure TfrmBase.AsignarServiciosVisuales(
  const ABusqueda: IBusquedaVisual;
  const ADistribuidorTallas: IDistribuidorTallasVisual;
  const ASolicitudPermisoLayout: ISolicitudPermisoLayout;
  const APreviewTicket: IPreviewTicket;
  const AProveedorPreviewExcel: IProveedorPreviewExcel);
begin
  FBusquedaVisual := ABusqueda;
  FDistribuidorTallasVisual := ADistribuidorTallas;
  FSolicitudPermisoLayout := ASolicitudPermisoLayout;
  FPreviewTicket := APreviewTicket;
  FProveedorPreviewExcel := AProveedorPreviewExcel;
end;

function TfrmBase.GetFiltrosEscritura: IEscritorFiltrosGuardados;
begin
  Result := FFiltrosEscritura;
end;

function TfrmBase.GetFiltrosComparticion: ICompartidorFiltrosGuardados;
begin
  Result := FFiltrosComparticion;
end;

function TfrmBase.GetServiciosFiltrosGuardados:
  TServiciosFiltrosGuardados;
begin
  Result := CrearServiciosFiltrosGuardados(
    FFiltrosLectura,
    FFiltrosEscritura,
    FFiltrosComparticion,
    FFiltrosDestinos);
  Result.Guias := FFiltrosGuias;
end;

function TfrmBase.GetPerfilesLectura: ILectorPerfilesUsuario;
begin
  Result := FPerfilesLectura;
end;

function TfrmBase.GetPerfilesEscritura: IEscritorPerfilesUsuario;
begin
  Result := FPerfilesEscritura;
end;

function TfrmBase.GetCachePerfiles: ICachePerfilesUsuario;
begin
  Result := FCachePerfiles;
end;

function TfrmBase.GetServiciosPerfilesUsuario:
  TServiciosPerfilesUsuario;
begin
  Result := CrearServiciosPerfilesUsuario(
    FPerfilesLectura,
    FPerfilesEscritura,
    FCachePerfiles);
end;

function TfrmBase.GetParametrosApp: IParametrosAplicacion;
begin
  Result := FParametrosApp;
end;

function TfrmBase.GetParametrosCaja: IParametrosCaja;
begin
  Result := FParametrosCaja;
end;

function TfrmBase.GetInformesGuiasCache: IInformesGuiasCache;
begin
  Result := FInformesGuiasCache;
end;

function TfrmBase.GetTraducciones: IServicioTraducciones;
begin
  Result := FTraducciones;
end;

function TfrmBase.GetFotosArticulos: TFotosArticulos;
begin
  Result := FFotosArticulos;
end;

function TfrmBase.GetUnidadesMedida: TUnidadesMedida;
begin
  Result := FUnidadesMedida;
end;

function TfrmBase.GetBusquedaVisual: IBusquedaVisual;
begin
  Result := FBusquedaVisual;
end;

function TfrmBase.GetDistribuidorTallasVisual: IDistribuidorTallasVisual;
begin
  Result := FDistribuidorTallasVisual;
end;

function TfrmBase.GetSolicitudPermisoLayout: ISolicitudPermisoLayout;
begin
  Result := FSolicitudPermisoLayout;
end;

function TfrmBase.GetPreviewTicket: IPreviewTicket;
begin
  Result := FPreviewTicket;
end;

function TfrmBase.GetProveedorPreviewExcel: IProveedorPreviewExcel;
begin
  Result := FProveedorPreviewExcel;
end;

function TfrmBase.GetRegistroLog: IRegistroLog;
begin
  Result := FRegistroLog;
end;

function TfrmBase.GetConfiguracionCampos: IConfiguracionCampos;
begin
  Result := FConfiguracionCampos;
end;

function TfrmBase.GetConexionPrincipal: TUniConnection;
begin
  Result := nil;
  if Assigned(FConexiones) then
    Result := FConexiones.ConexionPrincipal;
end;

procedure TfrmBase.ActualizarAuditoria(DataSet: TDataSet);
begin
  if Assigned(FAuditoriaDatos) then
    FAuditoriaDatos.Actualizar(DataSet)
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioAuditoriaDatosNoConfigurado);
end;

procedure TfrmBase.CerrarMonitorSQLPendiente;
begin
  if Assigned(FMonitorSQL) then
    FMonitorSQL.CerrarPendiente;
end;

procedure TfrmBase.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  KeyPreview := True;
  FEnterAsTabTemporalActivo := False;
  AplicarIdiomaDevExpress;
  // Etiquetas TcxLabel transparentes (sin fondo solido) en toda la jerarquia
  // que herede de TfrmBase. Centralizado aqui para no repetirlo pantalla a
  // pantalla y cubrir tambien los labels que se anadan en el futuro.
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TcxLabel then
      TcxLabel(Components[i]).Transparent := True;
  if Assigned(FTraducciones) then
    FTraducciones.Aplicar(Self);
end;

procedure TfrmBase.AplicarIdiomaDevExpress;
begin
  Localizer1.OnTranslate := TraducirDevExpress;
  if not Localizer1.Active then
    Localizer1.Active := True;
  if Assigned(FTraducciones) and
     SameText(FTraducciones.Idioma, IDIOMA_INGLES) then
    Localizer1.LanguageIndex := -1
  else
    Localizer1.Locale := 1034;
  Localizer1.Translate;
end;

procedure TfrmBase.TraducirDevExpress(
  const AResStringName: string;
  var AResStringValue: string;
  var AHandled: Boolean);
var
  Clave: string;
begin
  AHandled := False;
  if Assigned(FTraducciones) and
     (AResStringName <> '') then
  begin
    Clave := 'DevExpress.' + AResStringName;
    if FTraducciones.ExisteTraduccion(Clave) then
    begin
      AResStringValue := FTraducciones.Traducir(
        Clave,
        AResStringValue);
      AHandled := True;
    end;
  end;
end;

function TfrmBase.EnterAsTabGuardado(AComp: TJvEnterAsTab): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Length(FEnterAsTabEstados) - 1 do
    if FEnterAsTabEstados[i].Componente = AComp then
      Result := True;
end;

procedure TfrmBase.GuardarEnterAsTabDe(AOwner: TComponent);
var
  i: Integer;
  n: Integer;
  Comp: TJvEnterAsTab;
begin
  if Assigned(AOwner) then
    for i := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[i] is TJvEnterAsTab then
      begin
        Comp := TJvEnterAsTab(AOwner.Components[i]);
        if not EnterAsTabGuardado(Comp) then
        begin
          n := Length(FEnterAsTabEstados);
          SetLength(FEnterAsTabEstados, n + 1);
          FEnterAsTabEstados[n].Componente := Comp;
          FEnterAsTabEstados[n].EnterAsTab := Comp.EnterAsTab;
          Comp.EnterAsTab := False;
        end;
      end;
end;

procedure TfrmBase.ConfigurarBotonBusquedaDesplegable(
  AControl: TcxCustomDropDownEdit;
  AEvento: TcxEditButtonClickEvent);
var
  Boton: TcxEditButton;
begin
  if Assigned(AControl) then
  begin
    AControl.Properties.BeginUpdate;
    try
      AControl.Properties.Buttons.Clear;
      Boton := AControl.Properties.Buttons.Add;
      Boton.Kind := bkDown;
      Boton := AControl.Properties.Buttons.Add;
      Boton.Kind := bkEllipsis;
      AControl.Properties.OnButtonClick := AEvento;
    finally
      AControl.Properties.EndUpdate;
    end;
  end;
end;

procedure TfrmBase.DesactivarEnterAsTabTemporal(Sender: TObject);
begin
  if not FEnterAsTabTemporalActivo then
  begin
    SetLength(FEnterAsTabEstados, 0);
    GuardarEnterAsTabDe(Self);
    GuardarEnterAsTabDe(Owner);
    GuardarEnterAsTabDe(Application.MainForm);
    FEnterAsTabTemporalActivo := True;
  end;
end;

procedure TfrmBase.RestaurarEnterAsTabTemporal(Sender: TObject);
var
  i: Integer;
  MantenerDesactivado: Boolean;
begin
  MantenerDesactivado := False;
  if Sender is TcxCustomDropDownEdit then
    MantenerDesactivado := TcxCustomDropDownEdit(Sender).DroppedDown;
  if FEnterAsTabTemporalActivo and not MantenerDesactivado then
  begin
    for i := 0 to Length(FEnterAsTabEstados) - 1 do
      if Assigned(FEnterAsTabEstados[i].Componente) then
        FEnterAsTabEstados[i].Componente.EnterAsTab :=
          FEnterAsTabEstados[i].EnterAsTab;
    SetLength(FEnterAsTabEstados, 0);
    FEnterAsTabTemporalActivo := False;
  end;
end;

procedure TfrmBase.DoShow;
begin
  // Centrada en pantalla por defecto. Antes de inherited (que lanza OnShow):
  // si OnShow restaura una geometría grabada, la deja en poDesigned.
  CentrarFormularioPorDefecto(Self);
  // El degradado pudo crearse antes de que llegaran los parámetros.
  AplicarDegradadoBordes;
  // Modales del arranque sin ninguna ventana visible (integridad,
  // actualización, nuevo equipo, error): botón en la barra de tareas.
  if fsModal in FormState then
    AsegurarBotonBarraTareas(Self);
  inherited;
  // Después de inherited: OnShow restaura la disposición guardada de las
  // rejillas y volvería a enseñar las columnas.
  AplicarContrasteSeleccionInactiva;
  // SynEdit, TTreeView y TScrollBar no los pinta el skin.
  AplicarSkinEditoresCodigo(Self);
  if not ReagpEnUso(ParametrosApp) then
    OcultarControlesReagp(Self);
  FRegistroLog.RegistrarEvento(
    Self.UnitName,
    Self.ClassName,
    'Show',
    Self.Name);
end;

procedure TfrmBase.DoClose(var Action: TCloseAction);
begin
  FRegistroLog.RegistrarEvento(
    Self.UnitName,
    Self.ClassName,
    'Close',
    Self.Name);
  inherited;
end;

procedure TfrmBase.WndProc(var Message: TMessage);
begin
  inherited;
  if (Message.Msg = WM_WINDOWPOSCHANGED) and
     not Assigned(FResplandorBordes) and
     not (csDestroying in ComponentState) and
     not (csDesigning in ComponentState) then
  begin
    FResplandorBordes := TResplandorBordesVentana.Create(Self);
    FResplandorBordes.Intensidad := IntensidadDegradadoBordes;
  end;
  if Assigned(FResplandorBordes) then
    FResplandorBordes.Procesar(Message);
end;

procedure TfrmBase.WMQueryEndSession(var Message: TWMQueryEndSession);
begin
  // La VCL respondería con CloseQuery, que pregunta si salir, por las
  // operaciones de caja o por los cambios pendientes: Windows lo toma
  // como un veto y deja la sesión sin cerrar. La salida la hace
  // WM_ENDSESSION (TfrmMtoPrincipal), y solo si el fin de sesión sigue.
  Message.Result := 1;
end;

function TfrmBase.IntensidadDegradadoBordes: TIntensidadResplandor;
begin
  // Sin parámetros todavía (login, arranque): el valor por defecto.
  if Assigned(FParametrosApp) then
    Result := IntensidadResplandorDeTexto(FParametrosApp.GetString(
      PARAMETRO_DEGRADADO_BORDES, DEGRADADO_BORDES_SUAVE))
  else
    Result := irSuave;
end;

procedure TfrmBase.AplicarDegradadoBordes;
begin
  if Assigned(FResplandorBordes) then
    FResplandorBordes.Intensidad := IntensidadDegradadoBordes;
end;

procedure TfrmBase.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (fsModal in FormState) then
  begin
    Key := 0;
    if CloseQuery then
      ModalResult := mrCancel;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmBase.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  // Por defecto un formulario no aporta articulo en foco para Ctrl+U.
  ACodArt := '';
  ACodSku := '';
end;

procedure TfrmBase.PestanaActivada;
begin
end;

function TfrmBase.CancelarEdicionConEscape: Boolean;
begin
  Result := False;
end;

procedure TfrmBase.PrevisualizarTeclaEmbebida(var Key: Char);
begin
  // Solo si el formulario pidio previsualizar teclas: como ventana
  // propia la VCL tampoco le daria OnKeyPress con KeyPreview
  // desactivado, y el reenvio de la pestana no debe cambiar ese
  // criterio. Key := #0 en el manejador consume la tecla.
  if KeyPreview and Assigned(OnKeyPress) then
    OnKeyPress(Self, Key);
end;

{
Cómo heredar un form sin haber pasado por File New Others Inheritance.....
Primero poniendo en la definición de la clase, añadiendo el unit a uses y luego
TFormOtherType = class(InheritedFormType)
y después pasando por el dfm coomo se explica a continuación

https://stackoverflow.com/questions/70742195/
                                    how-to-make-an-old-form-inherit-from-another


Open dfm file in some other text editor and replace object with inherited

object FrmMyForm : TFrmMyForm

to

inherited FrmMyForm : TFrmMyForm

However, Delphi has issues with opening such forms
if they don't belong to the same project. For instance,
if you have base form declared in a package and you are
using it to inherit forms in application or another package.

If you have problem opening such forms, make sure that you first
open base form and then inherited.
}
end.
