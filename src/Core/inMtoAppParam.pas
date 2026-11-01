{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAppParam                                                 }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario de mantenimiento de parametros de la aplicacion.               }
{    Editor tipo inspector con categorias por usuario y grupo.                 }
{******************************************************************************}
unit inMtoAppParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxFilter,
  dxScrollbarAnnotations, cxEdit, cxCheckBox, cxInplaceContainer,
  cxTextEdit, cxContainer, inLibGlobalVar, dxCoreGraphics, cxMaskEdit,
  cxButtonEdit, cxSpinEdit, Vcl.ExtCtrls, inMtoFrmBase, Uni,
  cxDropDownEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  JvComponentBase, JvInspector, JvExControls, System.Actions,
  Vcl.ActnList, dxSkinsCore, System.UITypes, inLibParametrosIntf,
  inLibAppParamPersistenciaIntf, inLibPermisosIntf;

type
  PBoolean = ^Boolean;
  PInteger = ^Integer;
  PString  = ^String;
  TInspectorItemEvent = procedure(Sender: TJvCustomInspectorItem) of object;
  TValoresApiHistoricos = record
    UrlFotos: string;
    TokenFotos: string;
    ReferenciaFotos: string;
    UrlRecuentos: string;
    TokenRecuentos: string;
    ReferenciaRecuentos: string;
    UrlComunConfigurada: Boolean;
    TokenComunConfigurado: Boolean;
    ReferenciaComunConfigurada: Boolean;
  end;
  TCambiosAppParam = record
    ValoresPerfil: TValoresPerfilAppParam;
    Guardados: Integer;
    Ignorados: Integer;
    CambioVerifactu: Boolean;
    CambioTrazabilidad: Boolean;
  end;
  TfrmMtoAppParam = class(TFrmBase)
    JvInspectorDotNETPainter1: TJvInspectorDotNETPainter;
    ActionList1    : TActionList;
    actGuardar       : TAction;
    actSalir         : TAction;
    actGuardarLayout : TAction;
    JvInspector1: TJvInspector;
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
                                                 AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject; var Key: Word;
                                 Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cmbGrupoUsuarioPropertiesChange(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnChangeIdClick(Sender: TObject);
    procedure actGuardarExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure actGuardarLayoutExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
                          Shift: TShiftState);
//    procedure InspectorEditButtonClick(Sender: TObject;
//                                       Item: TJvCustomInspectorItem);
  private
    FBools            : TList<PBoolean>;
    FInts             : TList<PInteger>;
    FStrs             : TList<PString>;
    FValoresOriginales: TDictionary<string, string>;
    FParametrosEdicion: IParametrosEdicion;
    FRepositorioPersistencia: IRepositorioAppParam;
    FCargandoParametros: Boolean;
    FIdiomaInspectorAnterior: string;
    FProcesandoIdioma: Boolean;
    // False hasta que el ámbito del desplegable se carga sin error: sin
    // carga correcta el inspector no se edita ni se guarda.
    FCargaCorrecta: Boolean;
    procedure InspectorAntesCrearItem(Sender: TObject;
      Data: TJvCustomInspectorData;
      var ItemClass: TJvInspectorItemClass);
    function DescripcionParametroInspector(
      const AParametro: TParamInfo): string;
    procedure InspectorItemEdit(Sender: TJvCustomInspector;
                                Item: TJvCustomInspectorItem;
                                var DisplayStr: string);
    procedure InspectorItemValueChanged(
      Sender: TObject;
      Item: TJvCustomInspectorItem);
    procedure CapturarValoresOriginales;
    function  HayCambiosPendientes: Boolean;
    procedure LimpiarMemoria;
    procedure ResetearADefectos;
    function  ObtenerCategoria(const NombreCat: string)
                : TJvInspectorCustomCategoryItem;
    function  QuitarTildes(const Texto: string): string;
    function  BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem;
                const Nombre: string): TJvCustomInspectorItem;
    procedure FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
    procedure AplicarBloqueoParametros;
    function ObtenerGrupoUsuario(
      const AUsuario: string): string;
    function UsuarioPuedeEditarParametro(const ANombre: string): Boolean;
    function NombreCategoriaInspector(
      const AParametro: TParamInfo): string;
    function CrearItemInspector(
      ACategoria: TJvInspectorCustomCategoryItem;
      const AParametro: TParamInfo): TJvCustomInspectorItem;
    procedure ConfigurarItemCadena(
      AItem: TJvCustomInspectorItem;
      const ANombre: string);
    procedure ValidarFormulaCodigoArticulo;
    procedure AgregarParametroInspector(const AParametro: TParamInfo);
    procedure ConfigurarVisibilidadParametro(
      AItem: TJvCustomInspectorItem);
    procedure InicializarValoresApiHistoricos(
      var AValores: TValoresApiHistoricos);
    procedure RegistrarValorApiHistorico(
      const ANombre, AValor: string;
      var AValores: TValoresApiHistoricos);
    procedure AplicarValorInspector(
      AInspector: TJvInspector;
      const ANombre, AValor: string);
    procedure AplicarValorHistorico(
      AInspector: TJvInspector;
      const ANombre, AValorFotos, AValorRecuentos: string;
      AConfigurado: Boolean);
    procedure AplicarValoresPerfil(
      AInspector: TJvInspector;
      const AValores: TValoresPerfilAppParam;
      var AValoresApi: TValoresApiHistoricos);
    procedure AplicarValoresApiHistoricos(
      AInspector: TJvInspector;
      var AValores: TValoresApiHistoricos);
    procedure CargarParametros(Grid: TJvInspector;
                               const pUsuario, pGrupo: string);
    procedure CargarParametrosAmbito(const AUsuario, AGrupo: string);
    procedure ActualizarEdicionParametros;
    procedure ConstruirInspector;
    procedure InicializarCambiosParametros(
      var ACambios: TCambiosAppParam);
    procedure ClasificarCambioParametro(
      AItem: TJvCustomInspectorItem;
      var ACambios: TCambiosAppParam);
    procedure ClasificarCambiosInspector(
      var ACambios: TCambiosAppParam);
    procedure ActualizarOriginalesParametros(
      const AValores: TValoresPerfilAppParam);
    procedure GuardarCambiosPerfil(
      const AAmbito: string;
      const AValores: TValoresPerfilAppParam);
    procedure AplicarCambiosPrestaShopGuardados(
      const AAmbito: string;
      const AValores: TValoresPerfilAppParam);
    function AmbitoMensajeGuardado(
      const AAmbito: string;
      const ACambios: TCambiosAppParam): string;
    procedure RecargarParametrosGuardados(
      const AAmbito: string;
      const ACambios: TCambiosAppParam);
    procedure RegistrarCambioVerifactuGuardado(
      const AAmbito: string;
      const ACambios: TCambiosAppParam);
    procedure MostrarResultadoGuardado(
      const AAmbito: string;
      const ACambios: TCambiosAppParam);
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure AplicarIdiomaInterfaz(const AIdioma: string);
    function EsIdiomaDescargable(const AIdioma: string): Boolean;
    function ValorParametroInspector(
      const ANombre, ADefecto: string): string;

    // Handlers de listas desplegables
    procedure GetFormulasCodigoArticuloList(
      Sender: TJvCustomInspectorItem;
      Strings: TStrings);
    procedure GetImpresorasInformesList(Sender: TJvCustomInspectorItem;
                                        Strings: TStrings);
    procedure GetIdiomasList(Sender: TJvCustomInspectorItem;
                             Strings: TStrings);
    procedure GetTemasList(Sender: TJvCustomInspectorItem;
                           Strings: TStrings);
    procedure GetPaletasList(Sender: TJvCustomInspectorItem;
                              Strings: TStrings);
    procedure GetDegradadosBordesList(Sender: TJvCustomInspectorItem;
                                      Strings: TStrings);
    procedure GetModosVentanasList(Sender: TJvCustomInspectorItem;
      Strings: TStrings);
    procedure GetModosCalculoPrecioList(Sender: TJvCustomInspectorItem;
      Strings: TStrings);
    procedure GetMotoresBaseDatosList(Sender: TJvCustomInspectorItem;
                                      Strings: TStrings);
    procedure GetTemporadasList(Sender: TJvCustomInspectorItem;
                                Strings: TStrings);
    procedure GetNifsEmpresasList(Sender: TJvCustomInspectorItem;
                                  Strings: TStrings);
    procedure GetModosVerifactuList(Sender: TJvCustomInspectorItem;
                                    Strings: TStrings);
    // Handler para el botón de selección de carpeta
//    procedure OnDirButtonClick(Sender: TObject;
//                               Index: Integer);
  public
    procedure AplicarTraduccionActual; override;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ARepositorio: IRepositorioAppParam); reintroduce; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl, inLibInspectorSkin, inLibTemaAplicacion,
  StrUtils, Vcl.Printers,
   dxSkinsLookAndFeelPainter,
   dxSkinsDefaultPainters, dxSkinsForm,
  FileCtrl, inLibPathTokens,               // SelectDirectory
   inLibLayoutForm, inLibVerifactu, inLibViraCashApi,
   inLibMsgConfiguracion, inLibMsgComun,
   inLibTraducciones, inLibTraduccionesIntf,
   inLibTraduccionesDescargaPersistenciaIntf,
   inMtoModalDescargaTraduccion, inLibLogIntf,
   inLibComprasSesionesCodigoArticulo,
   UniDataAppParamGrupoUsuarioConsulta,
   UniDataConfiguracionPantalla,
   UniDataTraduccionesDescargaRepositorio,
   UniDataPrestaShopEncolado, inLibResplandorBordesVcl,
   inLibMotorBaseDatos, inLibTrazabilidad, inLibReparaciones,
   inLibTraduccionesFastReport,
   inLibMargenTarifa, inLibListasRegalos, inLibMsgListasRegalos;

resourcestring
  SSolicitudSeleccionarCarpetaParametros =
    'Seleccione una carpeta';
  SDescripcionPersonalizacionParametrosAplicacion =
    'Personalización Parámetros Aplicación';

function EsParametroPrestaShop(const ANombre: string): Boolean;
begin
  Result := StartsText('appPrestaShop', ANombre);
end;

procedure TfrmMtoAppParam.InspectorAntesCrearItem(
  Sender: TObject;
  Data: TJvCustomInspectorData;
  var ItemClass: TJvInspectorItemClass);
begin
  if SameText(Data.Name, PARAMETRO_DEGRADADO_BORDES) then
    ItemClass := TInspectorDegradadoBordes;
end;

function TfrmMtoAppParam.DescripcionParametroInspector(
  const AParametro: TParamInfo): string;
var
  Parametro: TParamInfo;
begin
  Parametro := AParametro;
  // La definición puede haberse creado con otro idioma activo.
  if SameText(Parametro.Nombre, 'appIdioma') then
    Parametro.Descripcion := SDescripcionParametroIdioma;
  Result := TraducirDescripcionParametro('inMtoAppParam', Parametro);
  if EsParametroInstalacionListas(AParametro.Nombre) then
    Result := Result + SDescripcionParametrosInstalacionListas;
end;

function CambioPrestaShopRequiereReencolado(
  const ANombre: string): Boolean;
begin
  Result := SameText(
    ANombre,
    'appPrestaShopSincronizarStockPrecios') or
    SameText(ANombre, 'appPrestaShopCrearArticulos') or
    SameText(ANombre, 'appPrestaShopActivo') or
    SameText(ANombre, 'appPrestaShopStockActivo') or
    SameText(ANombre, 'appPrestaShopUrl') or
    SameText(ANombre, 'appPrestaShopApiKey') or
    SameText(ANombre, 'appPrestaShopTarifa') or
    SameText(ANombre, 'appPrestaShopReglaIvaNormal') or
    SameText(ANombre, 'appPrestaShopReglaIvaReducido') or
    SameText(ANombre, 'appPrestaShopReglaIvaSuperreducido') or
    SameText(ANombre, 'appPrestaShopReglaIvaExento') or
    SameText(ANombre, 'appPrestaShopEmpresa') or
    SameText(ANombre, 'appPrestaShopIdTienda') or
    SameText(ANombre, 'appPrestaShopIdIdioma') or
    SameText(ANombre, 'appPrestaShopIdCategoriaRaiz');
end;

function ValoresIncluyenReencoladoPrestaShop(
  const AValores: TValoresPerfilAppParam): Boolean;
var
  oValor: TValorPerfilAppParam;
begin
  Result := False;
  for oValor in AValores do
    Result := Result or
      CambioPrestaShopRequiereReencolado(oValor.Subclave);
end;

function EsAmbitoSesionParametros(
  const AAmbito, AUsuario, AGrupo, ATodos: string): Boolean; forward;

constructor TfrmMtoAppParam.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ARepositorio: IRepositorioAppParam);
begin
  FRepositorioPersistencia := ARepositorio;
  ValidarDependenciaConfiguracion(
    FRepositorioPersistencia,
    'persistencia de parámetros de aplicación');
  inherited Create(AOwner, AContexto);
end;

function TfrmMtoAppParam.ObtenerGrupoUsuario(
  const AUsuario: string): string;
begin
  Result := ConsultarGrupoUsuarioUniDAC(
    ConexionPrincipal,
    AUsuario);
end;

procedure RegistrarCambioConfiguracionVerifactuSeguro(
  const ARegistroLog: IRegistroLog;
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AUsuario: string;
  const ADetalle: string);
begin
  try
    if AConexion <> nil then
      RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
        cEventoNoVerifactuCambioConfig,
        'Cambio de configuración Verifactu', ADetalle);
  except
    on E: Exception do
      ARegistroLog.RegistrarError(
        'No se pudo registrar el cambio de configuración Verifactu: ' +
        E.Message);
  end;
end;

function TfrmMtoAppParam.UsuarioPuedeEditarParametro(
  const ANombre: string): Boolean;
begin
  Result := True;
  // Las integraciones fiscales y de comercio electrónico, la restricción
  // por empresa/almacén/caja y el motor de la base de datos solo los
  // puede cambiar un administrador.
  if StartsText('appVerifactu', ANombre) or
     StartsText('appSii', ANombre) or
     EsParametroPrestaShop(ANombre) or
     EsParametroInstalacionListas(ANombre) or
     SameText(ANombre, 'appRestringirEmpAlmCaja') or
     SameText(ANombre, PARAMETRO_MOTOR_BASE_DATOS) then
    Result := SameText(IdentidadSesion.GrupoRaiz, 'S');
  if EsParametroInstalacionListas(ANombre) then
    Result := Result and SameText(cmbGrupoUsuario.Text, oAll);
end;

// -----------------------------------------------------------------------
// CICLO DE VIDA
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.FormCreate(Sender: TObject);
var
  Proveedor: IProveedorParametrosEdicion;
begin
  inherited;
  if not Supports(Owner, IProveedorParametrosEdicion, Proveedor) then
    raise Exception.Create(SErrorProveedorEdicionParametrosNoConfigurado);
  FParametrosEdicion := Proveedor.ParametrosAppEdicion;
  ValidarDependenciaConfiguracion(
    FRepositorioPersistencia,
    'persistencia de parámetros de aplicación');
  if not Assigned(FParametrosEdicion) then
    raise Exception.Create(
      SErrorParametrosAplicacionEditablesNoConfigurados);
  if jvntrstb1 <> nil then
    jvntrstb1.EnterAsTab := False;
  FBools             := TList<PBoolean>.Create;
  FInts              := TList<PInteger>.Create;
  FStrs              := TList<PString>.Create;
  FValoresOriginales := TDictionary<string, string>.Create;
  AplicarPintorSkin(JvInspector1, JvInspectorDotNETPainter1);
  JvInspector1.OnItemEdit := InspectorItemEdit;
  JvInspector1.BeforeItemCreate := InspectorAntesCrearItem;
  JvInspector1.OnItemValueChanged := InspectorItemValueChanged;
  FIdiomaInspectorAnterior := IDIOMA_ESPANOL;
//  JvInspector1.OnEditButtonClick := InspectorEditButtonClick;
end;

procedure TfrmMtoAppParam.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  ControlActivo: TWinControl;
  EsBoton      : Boolean;
  EsInspector  : Boolean;
begin
  if (Key = VK_RETURN) and
     (not (ssCtrl in Shift)) and
     (not (ssAlt in Shift)) then
  begin
    ControlActivo := Screen.ActiveControl;
    EsBoton       := (ControlActivo <> nil) and
                     (ControlActivo is TcxButton);
    EsInspector   := (ControlActivo <> nil) and
                     ((ControlActivo = JvInspector1) or
                      JvInspector1.ContainsControl(ControlActivo));
    if (ControlActivo = edtBusqueda) or
       edtBusqueda.ContainsControl(ControlActivo) then
      edtBusquedaKeyDown(Sender, Key, Shift)
    else if (not EsBoton) and (not EsInspector) then
    begin
      Key := 0;
      if ActiveControl <> nil then
        SelectNext(ActiveControl, not (ssShift in Shift), True)
      else
        SelectNext(Self, True, True);
    end;
  end;
end;

procedure TfrmMtoAppParam.FormDestroy(Sender: TObject);
begin
  FCargandoParametros := True;
  JvInspector1.OnItemValueChanged := nil;
  JvInspector1.Root.Clear;
  FParametrosEdicion := nil;
  FRepositorioPersistencia := nil;
  LimpiarMemoria;
  FreeAndNil(FBools);
  FreeAndNil(FInts);
  FreeAndNil(FStrs);
  FreeAndNil(FValoresOriginales);
  inherited;
end;

procedure TfrmMtoAppParam.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  // Sin caFree: el form se muestra con ShowModal y lo libera el caller
  // (FreeAndNil). caFree aqui provocaba Release + FreeAndNil dobles y
  // el boton X no cerraba la ventana a la primera (bug M2).
end;

procedure TfrmMtoAppParam.LimpiarMemoria;
var
  pB: PBoolean; pI: PInteger; pS: PString;
begin
  for pB in FBools do Dispose(pB);  FBools.Clear;
  for pI in FInts  do Dispose(pI);  FInts.Clear;
  for pS in FStrs  do Dispose(pS);  FStrs.Clear;
end;

// -----------------------------------------------------------------------
// CONSTRUCCIÓN DEL INSPECTOR
// -----------------------------------------------------------------------

function TfrmMtoAppParam.ObtenerCategoria(
  const NombreCat: string): TJvInspectorCustomCategoryItem;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (i < JvInspector1.Root.Count) and (Result = nil) do
  begin
    if (JvInspector1.Root.Items[i] is TJvInspectorCustomCategoryItem) and
       SameText(JvInspector1.Root.Items[i].DisplayName, NombreCat) then
      Result := TJvInspectorCustomCategoryItem(JvInspector1.Root.Items[i]);
    Inc(i);
  end;
  if Result = nil then
  begin
    Result := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    Result.DisplayName := NombreCat;
    Result.Expanded    := True;
  end;
end;

function TfrmMtoAppParam.NombreCategoriaInspector(
  const AParametro: TParamInfo): string;
begin
  Result := TraducirCategoriaParametro(
    'inMtoAppParam',
    AParametro.Categoria);
end;

function TfrmMtoAppParam.CrearItemInspector(
  ACategoria: TJvInspectorCustomCategoryItem;
  const AParametro: TParamInfo): TJvCustomInspectorItem;
var
  pBool: PBoolean;
  pInt: PInteger;
  pStr: PString;
begin
  Result := nil;
  case AParametro.Tipo of
    tpBoolean:
      begin
        New(pBool);
        FBools.Add(pBool);
        pBool^ := SameText(AParametro.ValorPorDefecto, 'True') or
          (AParametro.ValorPorDefecto = '1');
        Result := TJvInspectorVarData.New(
          ACategoria, AParametro.Nombre, TypeInfo(Boolean), pBool);
      end;
    tpInteger:
      begin
        New(pInt);
        FInts.Add(pInt);
        pInt^ := StrToIntDef(AParametro.ValorPorDefecto, 0);
        Result := TJvInspectorVarData.New(
          ACategoria, AParametro.Nombre, TypeInfo(Integer), pInt);
      end;
    tpString:
      begin
        New(pStr);
        FStrs.Add(pStr);
        pStr^ := AParametro.ValorPorDefecto;
        Result := TJvInspectorVarData.New(
          ACategoria, AParametro.Nombre, TypeInfo(string), pStr);
      end;
  end;
end;

procedure TfrmMtoAppParam.ConfigurarItemCadena(
  AItem: TJvCustomInspectorItem;
  const ANombre: string);
begin
  if SameText(
       ANombre,
       CLAVE_FORMULA_CODIGO_ARTICULO_SESION) then
  begin
    AItem.Flags := AItem.Flags +
      [iifValueList, iifAllowNonListValues];
    AItem.OnGetValueList := GetFormulasCodigoArticuloList;
  end
  else if SameText(ANombre, 'appImpresoraInformes') then
  begin
    AItem.Flags := AItem.Flags +
      [iifValueList, iifAllowNonListValues];
    AItem.OnGetValueList := GetImpresorasInformesList;
  end
  else if SameText(ANombre, 'appTema') then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetTemasList;
  end
  else if SameText(ANombre, 'appModoVentanas') then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetModosVentanasList;
  end
  else if SameText(ANombre, PARAMETRO_DEGRADADO_BORDES) then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetDegradadosBordesList;
  end
  else if SameText(ANombre, PARAMETRO_MARGEN_TARIFAS_COEFICIENTE) then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetModosCalculoPrecioList;
  end
  else if SameText(ANombre, PARAMETRO_MOTOR_BASE_DATOS) then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetMotoresBaseDatosList;
  end
  else if SameText(ANombre, 'appPaleta') then
  begin
    AItem.Flags := AItem.Flags +
      [iifValueList, iifAllowNonListValues];
    AItem.OnGetValueList := GetPaletasList;
  end
  else if SameText(ANombre, 'appIdioma') then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetIdiomasList;
  end
  else if SameText(ANombre, 'appTemporadaDefecto') then
  begin
    AItem.Flags := AItem.Flags +
      [iifValueList, iifAllowNonListValues];
    AItem.OnGetValueList := GetTemporadasList;
  end
  else if SameText(ANombre, 'appVerifactuModo') then
  begin
    AItem.Flags := AItem.Flags + [iifValueList];
    AItem.OnGetValueList := GetModosVerifactuList;
  end
  else if SameText(ANombre, 'appVerifactuSifNif') then
  begin
    AItem.Flags := AItem.Flags +
      [iifValueList, iifAllowNonListValues];
    AItem.OnGetValueList := GetNifsEmpresasList;
  end
  else if StartsText('appDir', ANombre) then
    AItem.Flags := AItem.Flags + [iifEditButton];
end;

procedure TfrmMtoAppParam.ValidarFormulaCodigoArticulo;
var
  oItem: TJvCustomInspectorItem;
begin
  oItem := BuscarItemPorNombre(
    JvInspector1.Root,
    CLAVE_FORMULA_CODIGO_ARTICULO_SESION);
  if Assigned(oItem) and Assigned(oItem.Data) then
    TFormulaCodigoArticuloSesion.Validar(oItem.Data.AsString);
end;

procedure TfrmMtoAppParam.AgregarParametroInspector(
  const AParametro: TParamInfo);
var
  oCategoria: TJvInspectorCustomCategoryItem;
  oItem: TJvCustomInspectorItem;
begin
  // Categoría vacía = parámetro histórico cargado solo como respaldo.
  if AParametro.Categoria <> '' then
  begin
    oCategoria := ObtenerCategoria(
      NombreCategoriaInspector(AParametro));
    oItem := CrearItemInspector(oCategoria, AParametro);
    oItem.DisplayName := DescripcionParametroInspector(AParametro);
    if AParametro.Tipo = tpString then
      ConfigurarItemCadena(oItem, AParametro.Nombre);
  end;
end;

procedure TfrmMtoAppParam.ConstruirInspector;
var
  oParametro: TParamInfo;
  aParametros: TArray<TParamInfo>;
begin
  aParametros := FParametrosEdicion.ListarDefiniciones;
  FCargandoParametros := True;
  JvInspector1.BeginUpdate;
  try
    JvInspector1.Root.Clear;
    LimpiarMemoria;
    for oParametro in aParametros do
      AgregarParametroInspector(oParametro);
    AplicarBloqueoParametros;
  finally
    JvInspector1.EndUpdate;
    FCargandoParametros := False;
  end;
end;

procedure TfrmMtoAppParam.ConfigurarVisibilidadParametro(
  AItem: TJvCustomInspectorItem);
begin
  AItem.ReadOnly := not UsuarioPuedeEditarParametro(AItem.Name);
  // F-LOTEC: los parámetros de lotes y series solo se ven con
  // su interruptor encendido.
  AItem.Hidden :=
    (SameText(AItem.Name, 'appPrestaShopApiKey') and
     (IdentidadSesion.GrupoRaiz <> 'S')) or
    not TActivacionTrazabilidad.Leer(ParametrosApp).ParametroVisible(
      AItem.Name);
end;

procedure TfrmMtoAppParam.AplicarBloqueoParametros;
var
  i: Integer;
  j: Integer;
  NodoPrincipal: TJvCustomInspectorItem;
  ParamItem: TJvCustomInspectorItem;
begin
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if NodoPrincipal is TJvInspectorCustomCategoryItem then
    begin
      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        ConfigurarVisibilidadParametro(ParamItem);
      end;
    end;
  end;
end;

// -----------------------------------------------------------------------
// HANDLERS DE LISTAS
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.GetFormulasCodigoArticuloList(
  Sender: TJvCustomInspectorItem;
  Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add(FORMULA_CODIGO_ARTICULO_SESION_DEFECTO);
  Strings.Add(FORMULA_CODIGO_ARTICULO_MODELO_PROVEEDOR);
end;

procedure TfrmMtoAppParam.GetImpresorasInformesList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  i: Integer;
begin
  Strings.Clear;
  Strings.Add('');
  for i := 0 to Printer.Printers.Count - 1 do
    Strings.Add(Printer.Printers[i]);
end;

procedure TfrmMtoAppParam.GetIdiomasList(
  Sender: TJvCustomInspectorItem;
  Strings: TStrings);
var
  arrIdiomas: TCadenasAppParam;
  sIdioma: string;
begin
  Strings.Clear;
  Strings.Add(IDIOMA_ESPANOL);
  Strings.Add(IDIOMA_INGLES);
  Strings.Add(IDIOMA_CATALAN);
  Strings.Add(IDIOMA_CHINO_SIMPLIFICADO);
  arrIdiomas := FRepositorioPersistencia.ListarIdiomas;
  for sIdioma in arrIdiomas do
  begin
    if (Trim(sIdioma) <> '') and
       (Strings.IndexOf(Trim(sIdioma)) < 0) then
    begin
      Strings.Add(Trim(sIdioma));
    end;
  end;
  if Strings.IndexOf(IDIOMA_PSEUDO) < 0 then
  begin
    Strings.Add(IDIOMA_PSEUDO);
  end;
end;
function TfrmMtoAppParam.EsIdiomaDescargable(
  const AIdioma: string): Boolean;
begin
  Result :=
    SameText(AIdioma, IDIOMA_INGLES) or
    SameText(AIdioma, IDIOMA_CATALAN) or
    SameText(AIdioma, IDIOMA_CHINO_SIMPLIFICADO);
end;

function TfrmMtoAppParam.ValorParametroInspector(
  const ANombre, ADefecto: string): string;
var
  oItem: TJvCustomInspectorItem;
begin
  Result := ADefecto;
  oItem := BuscarItemPorNombre(JvInspector1.Root, ANombre);
  if Assigned(oItem) and Assigned(oItem.Data) then
    Result := oItem.Data.AsString;
end;

procedure TfrmMtoAppParam.AplicarIdiomaInterfaz(
  const AIdioma: string);
var
  iFormulario: Integer;
begin
  if Assigned(Traducciones) then
  begin
    Traducciones.EstablecerIdioma(AIdioma);
    Traducciones.Recargar;
    AplicarIdiomaFastReport(Traducciones.Idioma);
    for iFormulario := 0 to Screen.FormCount - 1 do
    begin
      if Screen.Forms[iFormulario] is TfrmBase then
        TfrmBase(Screen.Forms[iFormulario]).AplicarTraduccionActual;
    end;
  end;
end;

procedure TfrmMtoAppParam.AplicarTraduccionActual;
var
  rParametro: TParamInfo;
  oItem: TJvCustomInspectorItem;
begin
  inherited;
  if Assigned(FParametrosEdicion) then
  begin
    JvInspector1.BeginUpdate;
    try
      for rParametro in FParametrosEdicion.ListarDefiniciones do
      begin
        oItem := BuscarItemPorNombre(JvInspector1.Root, rParametro.Nombre);
        if Assigned(oItem) then
        begin
          oItem.DisplayName := DescripcionParametroInspector(rParametro);
          if Assigned(oItem.Parent) then
            oItem.Parent.DisplayName := NombreCategoriaInspector(rParametro);
        end;
      end;
    finally
      JvInspector1.EndUpdate;
    end;
  end;
end;

procedure TfrmMtoAppParam.InspectorItemValueChanged(
  Sender: TObject;
  Item: TJvCustomInspectorItem);
var
  bAplicado: Boolean;
  bDescargar: Boolean;
  oInstalador: IInstaladorTraduccionesPersistencia;
  sError: string;
  sIdioma: string;
  sToken: string;
  sUrlBase: string;
begin
  if (not FCargandoParametros) and
     (not FProcesandoIdioma) and
     Assigned(Item) and
     Assigned(Item.Data) and
     SameText(Item.Name, 'appIdioma') then
  begin
    sIdioma := NormalizarIdiomaAplicacion(Item.Data.AsString);
    if not SameText(sIdioma, FIdiomaInspectorAnterior) then
    begin
      FProcesandoIdioma := True;
      try
        bAplicado := True;
        sError := '';
        try
          if EsIdiomaDescargable(sIdioma) then
          begin
            sUrlBase := Trim(
              ValorParametroInspector(
                'appApiUrl',
                cUrlViraCashApiDefecto));
            if sUrlBase = '' then
              sUrlBase := cUrlViraCashApiDefecto;
            sToken := Trim(
              ValorParametroInspector('appApiToken', ''));
            oInstalador := TInstaladorTraduccionesUniDAC.Create(
              ConexionPrincipal);
            bDescargar := not oInstalador.DisponibleLocalmente(
              sIdioma);
            bAplicado := TfrmModalDescargaTraduccion.Ejecutar(
              Self,
              oInstalador,
              sUrlBase,
              sToken,
              sIdioma,
              bDescargar,
              AplicarIdiomaInterfaz,
              sError);
          end
          else
            AplicarIdiomaInterfaz(sIdioma);
        except
          on E: Exception do
          begin
            bAplicado := False;
            sError := E.Message;
            RegistroLog.RegistrarError(
              'Aplicación del idioma ' + sIdioma + ': ' + E.Message);
          end;
        end;
        if bAplicado then
          FIdiomaInspectorAnterior := sIdioma
        else
        begin
          Item.DisplayValue := FIdiomaInspectorAnterior;
          ShowMessage_fza(
            Format(
              SErrorSeleccionIdiomaNoAplicado,
              [sIdioma, sError]));
        end;
      finally
        FProcesandoIdioma := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAppParam.GetTemasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  I: Integer;
  LSorted: TStringList;
begin
  // Enumeración dinámica: muestra todos los skins registrados en la app
  LSorted := TStringList.Create;
  try
    LSorted.Sorted := True;
    LSorted.Duplicates := dupIgnore;
    for I := 0 to cxLookAndFeelPaintersManager.Count - 1 do
    begin
      if cxLookAndFeelPaintersManager[I].LookAndFeelStyle = lfsSkin then
        LSorted.Add(cxLookAndFeelPaintersManager[I].LookAndFeelName);
    end;
    Strings.Assign(LSorted);
  finally
    LSorted.Free;
  end;
end;

procedure TfrmMtoAppParam.GetPaletasList(Sender: TJvCustomInspectorItem;
                                         Strings: TStrings);
var
  LSkinName: string;
  LItemTema: TJvCustomInspectorItem;
  LPainter: TcxCustomLookAndFeelPainter;
  // Usamos la clase de información de tu unidad
  LPainterInfo: TdxSkinLookAndFeelPainterInfo;
  I: Integer;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    Strings.Add('Default');

    // 1. Obtener el nombre del skin seleccionado actualmente en el inspector
    LItemTema := BuscarItemPorNombre(JvInspector1.Root, 'appTema');

    if (LItemTema <> nil) and Assigned(LItemTema.Data) then
      LSkinName := LItemTema.Data.AsString
    else
      LSkinName := ParametrosApp.GetString('appTema');

    if Trim(LSkinName) <> '' then
    begin
      // 2. Usar el manager global nativo disponible en esta versión
      if cxLookAndFeelPaintersManager.GetPainter(LSkinName, LPainter) then
      begin
        // 3. Extraer la información interna del Skin de forma segura
        if LPainter.GetPainterData(LPainterInfo) then
        begin
          if Assigned(LPainterInfo.Skin) and
             (LPainterInfo.Skin.ColorPalettes.Count > 0) then
          begin
            for I := 0 to LPainterInfo.Skin.ColorPalettes.Count - 1 do
              Strings.Add(LPainterInfo.Skin.ColorPalettes[I].Name);
          end;
        end;
      end;
    end;
  finally
    Strings.EndUpdate;
  end;
end;

procedure TfrmMtoAppParam.GetModosVerifactuList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add(cModoVerifactuSin);
  Strings.Add(cModoVerifactuVerifactu);
  Strings.Add(cModoVerifactuNoVerifactu);
  Strings.Add(cModoVerifactuSii);
end;

procedure TfrmMtoAppParam.GetModosVentanasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add('MDI');
  Strings.Add('SDI');
end;

procedure TfrmMtoAppParam.GetDegradadosBordesList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add(SDegradadoBordesSin);
  Strings.Add(SDegradadoBordesSuave);
  Strings.Add(SDegradadoBordesIntenso);
end;

procedure TfrmMtoAppParam.GetModosCalculoPrecioList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add(MODO_CALCULO_PRECIO_MARGEN);
  Strings.Add(MODO_CALCULO_PRECIO_COEFICIENTE);
end;

procedure TfrmMtoAppParam.GetMotoresBaseDatosList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  Motor: TMotorBaseDatos;
begin
  Strings.Clear;
  for Motor := Low(TMotorBaseDatos) to High(TMotorBaseDatos) do
    Strings.Add(TextoMotorBaseDatos(Motor));
end;

procedure TfrmMtoAppParam.GetTemporadasList(
  Sender: TJvCustomInspectorItem;
  Strings: TStrings);
var
  arrTemporadas: TCadenasAppParam;
  sTemporada: string;
begin
  Strings.Clear;
  Strings.Add('');
  arrTemporadas := FRepositorioPersistencia.ListarTemporadas;
  for sTemporada in arrTemporadas do
  begin
    Strings.Add(sTemporada);
  end;
end;

procedure TfrmMtoAppParam.GetNifsEmpresasList(
  Sender: TJvCustomInspectorItem;
  Strings: TStrings);
var
  arrNifs: TCadenasAppParam;
  sNif: string;
begin
  Strings.Clear;
  Strings.Add('');
  arrNifs := FRepositorioPersistencia.ListarNifsEmpresas;
  for sNif in arrNifs do
  begin
    Strings.Add(sNif);
  end;
end;
procedure TfrmMtoAppParam.InspectorItemEdit(Sender: TJvCustomInspector;
  Item: TJvCustomInspectorItem; var DisplayStr: string);
var
  Dir: string;
begin
  if (Item <> nil) and StartsText('appDir', Item.Name) then
  begin
    // El valor guardado puede contener un token: se expande para el diálogo
    Dir := ExpandPathTokens(DisplayStr);
    if SelectDirectory(SSolicitudSeleccionarCarpetaParametros, '', Dir,
                       [sdNewUI, sdNewFolder]) then
      DisplayStr := PathToToken(Dir);
  end;
end;


// -----------------------------------------------------------------------
// CARGA Y GUARDADO  (idéntico al de CajaParam)
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.CapturarValoresOriginales;
var
  i, j        : Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorExtraido: string;
begin
  FValoresOriginales.Clear;
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if NodoPrincipal is TJvInspectorCustomCategoryItem then
      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        if ParamItem.Data <> nil then
        begin
          case ParamItem.Data.TypeInfo.Kind of
            tkEnumeration:
              if ParamItem.Data.AsOrdinal <> 0 then
                ValorExtraido := 'True'
              else
                ValorExtraido := 'False';
            tkInteger:
              ValorExtraido := IntToStr(ParamItem.Data.AsOrdinal);
          else
            ValorExtraido := ParamItem.Data.AsString;
          end;
          FValoresOriginales.AddOrSetValue(ParamItem.Name, ValorExtraido);
        end;
      end;
  end;
end;

procedure TfrmMtoAppParam.ResetearADefectos;
var
  Parametros: TArray<TParamInfo>;
  Param: TParamInfo;
  ItemData: TJvCustomInspectorItem;
begin
  Parametros := FParametrosEdicion.ListarDefiniciones;
  for Param in Parametros do
  begin
    ItemData := BuscarItemPorNombre(JvInspector1.Root, Param.Nombre);
    if ItemData <> nil then
      ItemData.DisplayValue := Param.ValorPorDefecto;
  end;
end;

procedure TfrmMtoAppParam.InicializarValoresApiHistoricos(
  var AValores: TValoresApiHistoricos);
begin
  AValores.UrlFotos := cUrlViraCashApiDefecto;
  AValores.TokenFotos := '';
  AValores.ReferenciaFotos := '';
  AValores.UrlRecuentos := '';
  AValores.TokenRecuentos := '';
  AValores.ReferenciaRecuentos := '';
  AValores.UrlComunConfigurada := False;
  AValores.TokenComunConfigurado := False;
  AValores.ReferenciaComunConfigurada := False;
end;

procedure TfrmMtoAppParam.RegistrarValorApiHistorico(
  const ANombre, AValor: string;
  var AValores: TValoresApiHistoricos);
begin
  if SameText(ANombre, 'appApiUrl') then
    AValores.UrlComunConfigurada := Trim(AValor) <> ''
  else if SameText(ANombre, 'appApiToken') then
    AValores.TokenComunConfigurado := Trim(AValor) <> ''
  else if SameText(ANombre, 'appApiReferencia') then
    AValores.ReferenciaComunConfigurada := Trim(AValor) <> ''
  else if SameText(ANombre, 'appFotosUrlDescarga') then
    AValores.UrlFotos := AValor
  else if SameText(ANombre, 'appFotosApiKey') then
    AValores.TokenFotos := AValor
  else if SameText(ANombre, 'appFotosCarpetaCliente') then
    AValores.ReferenciaFotos := AValor
  else if SameText(ANombre, 'appRecuentoUrl') then
    AValores.UrlRecuentos := AValor
  else if SameText(ANombre, 'appRecuentoApiKey') then
    AValores.TokenRecuentos := AValor
  else if SameText(ANombre, 'appRecuentoCarpetaCliente') then
    AValores.ReferenciaRecuentos := AValor;
end;

procedure TfrmMtoAppParam.AplicarValorInspector(
  AInspector: TJvInspector;
  const ANombre, AValor: string);
var
  oItem: TJvCustomInspectorItem;
  sValor: string;
begin
  sValor := AValor;
  if SameText(ANombre, PARAMETRO_MARGEN_TARIFAS_COEFICIENTE) then
    sValor := NombreModoCalculoPrecio(sValor);
  oItem := BuscarItemPorNombre(AInspector.Root, ANombre);
  if (oItem <> nil) and (oItem.Data <> nil) then
  begin
    try
      if (sValor = '') and
         (oItem.Data.TypeInfo.Kind in [tkInteger, tkFloat]) then
        sValor := '0';
      oItem.DisplayValue := sValor;
    except
      // El resto de parámetros se sigue aplicando.
      on E: Exception do
        RegistroLog.RegistrarAviso(
          'AppParam: no se pudo aplicar el parámetro "' +
          ANombre + '": ' + E.Message);
    end;
  end;
end;

procedure TfrmMtoAppParam.AplicarValorHistorico(
  AInspector: TJvInspector;
  const ANombre, AValorFotos, AValorRecuentos: string;
  AConfigurado: Boolean);
var
  oItem: TJvCustomInspectorItem;
  sValor: string;
begin
  if not AConfigurado then
  begin
    sValor := AValorFotos;
    if Trim(sValor) = '' then
      sValor := AValorRecuentos;
    oItem := BuscarItemPorNombre(AInspector.Root, ANombre);
    if (Trim(sValor) <> '') and (oItem <> nil) and
       (oItem.Data <> nil) then
      oItem.DisplayValue := sValor;
  end;
end;

procedure TfrmMtoAppParam.AplicarValoresPerfil(
  AInspector: TJvInspector;
  const AValores: TValoresPerfilAppParam;
  var AValoresApi: TValoresApiHistoricos);
var
  oValor: TValorPerfilAppParam;
begin
  for oValor in AValores do
  begin
    RegistrarValorApiHistorico(
      oValor.Subclave, oValor.Valor, AValoresApi);
    if not EsParametroInstalacionListas(oValor.Subclave) then
      AplicarValorInspector(
        AInspector, oValor.Subclave, oValor.Valor);
  end;
end;

procedure TfrmMtoAppParam.AplicarValoresApiHistoricos(
  AInspector: TJvInspector;
  var AValores: TValoresApiHistoricos);
begin
  if (Trim(AValores.UrlFotos) = '') and
     (Trim(AValores.UrlRecuentos) = '') then
    AValores.UrlFotos := cUrlViraCashApiDefecto;
  AplicarValorHistorico(
    AInspector, 'appApiUrl', AValores.UrlFotos,
    AValores.UrlRecuentos, AValores.UrlComunConfigurada);
  AplicarValorHistorico(
    AInspector, 'appApiToken', AValores.TokenFotos,
    AValores.TokenRecuentos, AValores.TokenComunConfigurado);
  AplicarValorHistorico(
    AInspector, 'appApiReferencia', AValores.ReferenciaFotos,
    AValores.ReferenciaRecuentos,
    AValores.ReferenciaComunConfigurada);
end;

procedure TfrmMtoAppParam.CargarParametros(
  Grid: TJvInspector;
  const pUsuario, pGrupo: string);
var
  oValoresApi: TValoresApiHistoricos;
  aValores: TValoresPerfilAppParam;
  ValoresInstalacion: TValoresPerfilAppParam;
  ValorInstalacion: TValorPerfilAppParam;
begin
  // Primero se leen los valores y solo después se resetea el inspector:
  // si la lectura falla, conserva lo que mostraba y FCargaCorrecta queda
  // en False. Resetear antes dejaba los valores por defecto frente a los
  // originales del ámbito anterior y Guardar los grababa como cambios
  // (FZ-ISSUE-125: Verifactu pasaba a SIN).
  FCargaCorrecta := False;
  aValores := FRepositorioPersistencia.CargarValores(
    pUsuario, pGrupo, 'frmMtoAppParam');
  ValoresInstalacion := FRepositorioPersistencia.CargarValores(
    '', oAll, 'frmMtoAppParam');
  FCargandoParametros := True;
  try
    if Assigned(Grid.Selected) and Grid.Selected.Editing then
      Grid.Selected.DoneEdit(True);
    ResetearADefectos;
    Grid.Refresh;
    InicializarValoresApiHistoricos(oValoresApi);
    Grid.BeginUpdate;
    try
      AplicarValoresPerfil(Grid, aValores, oValoresApi);
      for ValorInstalacion in ValoresInstalacion do
        if EsParametroInstalacionListas(ValorInstalacion.Subclave) then
          AplicarValorInspector(Grid, ValorInstalacion.Subclave,
            ValorInstalacion.Valor);
      AplicarValoresApiHistoricos(Grid, oValoresApi);
    finally
      Grid.EndUpdate;
    end;
    CapturarValoresOriginales;
    // La previsualización pertenece a la sesión, no al perfil compartido.
    if SameText(pUsuario, IdentidadSesion.Usuario) and
       Assigned(Traducciones) then
      AplicarValorInspector(Grid, 'appIdioma', Traducciones.Idioma);
    Grid.RefreshValues;
    FIdiomaInspectorAnterior := NormalizarIdiomaAplicacion(
      ValorParametroInspector('appIdioma', IDIOMA_ESPANOL));
    FCargaCorrecta := True;
  finally
    FCargandoParametros := False;
  end;
end;

procedure TfrmMtoAppParam.CargarParametrosAmbito(
  const AUsuario, AGrupo: string);
begin
  try
    CargarParametros(JvInspector1, AUsuario, AGrupo);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarError(
        'AppParam: no se pudieron cargar los parámetros de "' +
        cmbGrupoUsuario.Text + '": ' + E.Message);
      ShowMessage_fza(Format(
        SErrorCargarParametrosAmbito,
        [cmbGrupoUsuario.Text, E.Message]));
    end;
  end;
  ActualizarEdicionParametros;
end;

procedure TfrmMtoAppParam.ActualizarEdicionParametros;
var
  bSoloLectura: Boolean;
begin
  // Un usuario normal edita lo suyo y lo de su grupo; los parametros de
  // 'Todos' (y cualquier otro sujeto) solo los ve en modo lectura. Los
  // administradores editan todo. Sin una carga correcta nadie edita.
  bSoloLectura := (not FCargaCorrecta) or
                  ((IdentidadSesion.GrupoRaiz <> 'S') and
                   (not SameText(cmbGrupoUsuario.Text,
                                 IdentidadSesion.Usuario)) and
                   (not SameText(cmbGrupoUsuario.Text,
                                 IdentidadSesion.Grupo)));
  JvInspector1.ReadOnly := bSoloLectura;
  AplicarBloqueoParametros;
  btnGuardar.Enabled := not bSoloLectura;
  actGuardar.Enabled := not bSoloLectura;
end;

function ValorInspectorParaGuardar(
  AItem: TJvCustomInspectorItem): string;
begin
  Result := '';
  if AItem.Data <> nil then
  begin
    case AItem.Data.TypeInfo.Kind of
      tkEnumeration:
        if AItem.Data.AsOrdinal <> 0 then
          Result := 'True'
        else
          Result := 'False';
      tkInteger:
        Result := IntToStr(AItem.Data.AsOrdinal);
    else
      Result := AItem.Data.AsString;
    end;
  end;
end;

procedure TfrmMtoAppParam.InicializarCambiosParametros(
  var ACambios: TCambiosAppParam);
begin
  SetLength(ACambios.ValoresPerfil, 0);
  ACambios.Guardados := 0;
  ACambios.Ignorados := 0;
  ACambios.CambioVerifactu := False;
  ACambios.CambioTrazabilidad := False;
end;

procedure TfrmMtoAppParam.ClasificarCambioParametro(
  AItem: TJvCustomInspectorItem;
  var ACambios: TCambiosAppParam);
var
  EsCambioReal: Boolean;
  sValor: string;
begin
  sValor := ValorInspectorParaGuardar(AItem);
  EsCambioReal := True;
  if FValoresOriginales.ContainsKey(AItem.Name) then
    EsCambioReal := not SameText(
      FValoresOriginales[AItem.Name], sValor);
  if EsCambioReal then
  begin
    if UsuarioPuedeEditarParametro(AItem.Name) then
    begin
      SetLength(
        ACambios.ValoresPerfil,
        Length(ACambios.ValoresPerfil) + 1);
      ACambios.ValoresPerfil[
        High(ACambios.ValoresPerfil)].Subclave := AItem.Name;
      ACambios.ValoresPerfil[
        High(ACambios.ValoresPerfil)].Valor := sValor;
      Inc(ACambios.Guardados);
      if SameText(AItem.Name, PARAMETRO_GARANTIAS) or
         SameText(AItem.Name, PARAMETRO_REPARACIONES) or
         SameText(AItem.Name, PARAMETRO_TRAZABILIDAD_LOTES) or
         SameText(AItem.Name, PARAMETRO_TRAZABILIDAD_SERIES) then
        ACambios.CambioTrazabilidad := True;
      if StartsText('appVerifactu', AItem.Name) or
         StartsText('appSii', AItem.Name) then
        ACambios.CambioVerifactu := True;
    end
    else
      Inc(ACambios.Ignorados);
  end;
end;

procedure TfrmMtoAppParam.ClasificarCambiosInspector(
  var ACambios: TCambiosAppParam);
var
  i: Integer;
  j: Integer;
  oCategoria: TJvCustomInspectorItem;
begin
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    oCategoria := JvInspector1.Root.Items[i];
    if oCategoria is TJvInspectorCustomCategoryItem then
    begin
      for j := 0 to oCategoria.Count - 1 do
        ClasificarCambioParametro(oCategoria.Items[j], ACambios);
    end;
  end;
end;

procedure TfrmMtoAppParam.ActualizarOriginalesParametros(
  const AValores: TValoresPerfilAppParam);
var
  oValor: TValorPerfilAppParam;
begin
  for oValor in AValores do
    FValoresOriginales.AddOrSetValue(oValor.Subclave, oValor.Valor);
end;

procedure TfrmMtoAppParam.GuardarCambiosPerfil(
  const AAmbito: string;
  const AValores: TValoresPerfilAppParam);
begin
  if Length(AValores) > 0 then
  begin
    FRepositorioPersistencia.GuardarValores(
      AAmbito, 'frmMtoAppParam', AValores);
    ActualizarOriginalesParametros(AValores);
  end;
end;

procedure TfrmMtoAppParam.AplicarCambiosPrestaShopGuardados(
  const AAmbito: string;
  const AValores: TValoresPerfilAppParam);
var
  bCrearArticulos: Boolean;
  bSincronizar: Boolean;
begin
  if ValoresIncluyenReencoladoPrestaShop(AValores) and
     EsAmbitoSesionParametros(
       AAmbito,
       IdentidadSesion.Usuario,
       IdentidadSesion.Grupo,
       oAll) then
  begin
    FParametrosEdicion.Recargar(
      IdentidadSesion.Usuario,
      IdentidadSesion.Grupo);
    bSincronizar := ParametrosApp.GetBool(
      'appPrestaShopSincronizarStockPrecios', False);
    bCrearArticulos := ParametrosApp.GetBool(
      'appPrestaShopCrearArticulos', False);
    if bSincronizar or bCrearArticulos then
      EncolarTodosWebPrestaShop(
        ConexionPrincipal,
        True,
        bSincronizar,
        IdentidadSesion.Usuario);
  end;
end;

function EsAmbitoSesionParametros(
  const AAmbito, AUsuario, AGrupo, ATodos: string): Boolean;
begin
  Result := SameText(AAmbito, AUsuario) or
    SameText(AAmbito, AGrupo) or
    SameText(AAmbito, ATodos);
end;

function TfrmMtoAppParam.AmbitoMensajeGuardado(
  const AAmbito: string;
  const ACambios: TCambiosAppParam): string;
begin
  Result := AAmbito;
end;

procedure TfrmMtoAppParam.RecargarParametrosGuardados(
  const AAmbito: string;
  const ACambios: TCambiosAppParam);
var
  sTema: string;
  sPaleta: string;
  I: Integer;
begin
  if EsAmbitoSesionParametros(
       AAmbito,
       IdentidadSesion.Usuario,
       IdentidadSesion.Grupo,
       oAll) then
  begin
    FParametrosEdicion.Recargar(
      IdentidadSesion.Usuario,
      IdentidadSesion.Grupo);
    // El degradado de los bordes sí cambia en caliente, en todas las
    // ventanas abiertas.
    for I := 0 to Screen.FormCount - 1 do
      if Screen.Forms[I] is TfrmBase then
        TfrmBase(Screen.Forms[I]).AplicarDegradadoBordes;
    // Tema y paleta, también en caliente: los controladores del skin
    // delegan en RootLookAndFeel y los editores de código lo escuchan.
    if ACambios.CambioTrazabilidad then
      ShowMessage_fza(SAvisoReiniciarMenusTrazabilidad);
    sTema := ParametrosApp.GetString('appTema');
    sPaleta := ParametrosApp.GetString('appPaleta');
    if TemaAplicacionCambia(sTema, sPaleta) then
    begin
      try
        AplicarTemaAplicacion(sTema, sPaleta);
      except
        on E: Exception do
          RegistroLog.RegistrarAviso(
            'Error al cambiar el skin en caliente: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoAppParam.RegistrarCambioVerifactuGuardado(
  const AAmbito: string;
  const ACambios: TCambiosAppParam);
begin
  if ACambios.CambioVerifactu then
    RegistrarCambioConfiguracionVerifactuSeguro(
      RegistroLog,
      ParametrosApp,
      ConexionPrincipal,
      IdentidadSesion.Usuario,
      'Parámetros guardados para ' + AAmbito + ': ' +
      IntToStr(ACambios.Guardados));
end;

procedure TfrmMtoAppParam.MostrarResultadoGuardado(
  const AAmbito: string;
  const ACambios: TCambiosAppParam);
begin
  if ACambios.Guardados > 0 then
  begin
    ShowMessage_fza(Format(
      SInfoParametrosGuardados,
      [ACambios.Guardados, AmbitoMensajeGuardado(AAmbito, ACambios)]));
    RecargarParametrosGuardados(AAmbito, ACambios);
    RegistrarCambioVerifactuGuardado(AAmbito, ACambios);
    if ACambios.Ignorados > 0 then
      ShowMessage_fza(Format(
        SAvisoParametrosRestringidosIgnorados,
        [ACambios.Ignorados]));
  end
  else if ACambios.Ignorados > 0 then
    ShowMessage_fza(Format(
      SAvisoParametrosRestringidosNoGuardados,
      [ACambios.Ignorados]))
  else
    ShowMessage_fza(SInfoSinCambiosParametros);
end;

procedure TfrmMtoAppParam.btnGuardarClick(Sender: TObject);
var
  oCambios: TCambiosAppParam;
  sAmbito: string;
begin
  if FCargandoParametros or FProcesandoIdioma then
    raise EInvalidOperation.Create(
      SCaptionCargandoDatosEspere);
  JvInspector1.SaveValues;
  ValidarFormulaCodigoArticulo;
  if not PuedeAbrirParametrosAplicacion(Permisos) then
    ShowMessage_fza(SErrorPermisoGuardarParametros)
  else if not FCargaCorrecta then
    ShowMessage_fza(Format(
      SErrorGuardarParametrosSinCarga,
      [cmbGrupoUsuario.Text]))
  else if cmbGrupoUsuario.ItemIndex >= 0 then
  begin
    sAmbito := cmbGrupoUsuario.Text;
    InicializarCambiosParametros(oCambios);
    ClasificarCambiosInspector(oCambios);
    GuardarCambiosPerfil(sAmbito, oCambios.ValoresPerfil);
    AplicarCambiosPrestaShopGuardados(
      sAmbito,
      oCambios.ValoresPerfil);
    MostrarResultadoGuardado(sAmbito, oCambios);
  end;
end;

// -----------------------------------------------------------------------
// LAYOUT (geometría + divider del inspector)
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarDividerInspector('Divider', JvInspector1);
    if Layout.PreguntarYGrabar(
         SDescripcionPersonalizacionParametrosAplicacion) then
      ShowMessage_fza(SInfoLayoutGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoAppParam.RestaurarLayout;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  try
    if Layout.Disponible then
    begin
      Layout.RestaurarGeometria(Self);
      Layout.RestaurarDividerInspector('Divider', JvInspector1);
    end;
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoAppParam.actGuardarLayoutExecute(Sender: TObject);
begin
  GuardarLayout;
end;

// -----------------------------------------------------------------------
// EVENTOS DE FORMULARIO
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.FormShow(Sender: TObject);
var
  Ambitos: TCadenasAppParam;
  s: string;
begin
  ConstruirInspector;
  cmbGrupoUsuario.Properties.Items.Clear;
  // Todo usuario gestiona sus propios parametros (IdentidadSesion.Usuario) y
  // los de su
  // grupo (IdentidadSesion.Grupo), y puede consultar los de 'Todos' (oAll) en
  // modo
  // solo lectura (lo aplica cmbGrupoUsuarioPropertiesChange).
  cmbGrupoUsuario.Properties.Items.Add(IdentidadSesion.Usuario);
  cmbGrupoUsuario.Properties.Items.Add(IdentidadSesion.Grupo);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  // Solo los administradores ven ademas la lista completa de usuarios y
  // grupos del sistema (y pueden editarla).
  if IdentidadSesion.GrupoRaiz = 'S' then
  begin
    Ambitos := FRepositorioPersistencia.ListarAmbitos;
    for s in Ambitos do
    begin
      if cmbGrupoUsuario.Properties.Items.IndexOf(s) < 0 then
      begin
        cmbGrupoUsuario.Properties.Items.Add(s);
      end;
    end;
  end;
  cmbGrupoUsuario.Visible := True;
  cmbGrupoUsuario.ItemIndex := 0;
  btnChangeId.Visible := False;
  CargarParametrosAmbito(
    IdentidadSesion.Usuario,
    IdentidadSesion.Grupo);
  RestaurarLayout;
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

procedure TfrmMtoAppParam.cmbGrupoUsuarioPropertiesChange(Sender: TObject);
var
  sUsuario, sGrupo: string;
begin
  if cmbGrupoUsuario.ItemIndex >= 0 then
  begin
    case cmbGrupoUsuario.ItemIndex of
      0: begin
           sUsuario := IdentidadSesion.Usuario;
           sGrupo := IdentidadSesion.Grupo;
         end;
      1: begin sUsuario := '';     sGrupo := IdentidadSesion.Grupo; end;
      2: begin sUsuario := '';     sGrupo := oAll;   end;
    else
      begin
        // Sujeto del desplegable completo (solo visible a administradores):
        // se carga por su nombre tal cual.
        sUsuario := cmbGrupoUsuario.Text;
        sGrupo := ObtenerGrupoUsuario(sUsuario);
        if sGrupo = '' then
        begin
          sGrupo := sUsuario;
          sUsuario := '';
        end;
      end;
    end;
    CargarParametrosAmbito(sUsuario, sGrupo);
  end;
end;

procedure TfrmMtoAppParam.actGuardarExecute(Sender: TObject);
begin
  inherited;
  btnGuardarClick(Sender);
  Close;
end;

procedure TfrmMtoAppParam.actSalirExecute(Sender: TObject);
begin
  inherited;
  // Solo pedimos confirmación si hay cambios reales sin guardar
  if not HayCambiosPendientes then
    Close
  else if MessageDlg_fza(SPreguntaSalirSinGuardar,
                     mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    Close;
end;

function TfrmMtoAppParam.HayCambiosPendientes: Boolean;
var
  i, j         : Integer;
  NodoPrincipal: TJvCustomInspectorItem;
  ParamItem    : TJvCustomInspectorItem;
  ValorActual  : string;
begin
  // Recorremos los items igual que en btnGuardarClick comparando contra los
  // valores capturados al cargar; basta un cambio para devolver True
  Result := False;
  if FValoresOriginales <> nil then
  begin
    JvInspector1.SaveValues;
    for i := 0 to JvInspector1.Root.Count - 1 do
    begin
      NodoPrincipal := JvInspector1.Root.Items[i];
      if NodoPrincipal is TJvInspectorCustomCategoryItem then
      begin
        for j := 0 to NodoPrincipal.Count - 1 do
        begin
          ParamItem := NodoPrincipal.Items[j];
          if ParamItem.Data <> nil then
            case ParamItem.Data.TypeInfo.Kind of
              tkEnumeration:
                if ParamItem.Data.AsOrdinal <> 0 then
                  ValorActual := 'True'
                else
                  ValorActual := 'False';
              tkInteger:
                ValorActual := IntToStr(ParamItem.Data.AsOrdinal);
            else
              ValorActual := ParamItem.Data.AsString;
            end
          else
            ValorActual := '';
          if UsuarioPuedeEditarParametro(ParamItem.Name) and
             FValoresOriginales.ContainsKey(ParamItem.Name) then
            Result := Result or not SameText(
              FValoresOriginales[ParamItem.Name], ValorActual)
          else if UsuarioPuedeEditarParametro(ParamItem.Name) then
            Result := Result or (ValorActual <> '');
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoAppParam.btnChangeIdClick(Sender: TObject);
var
  Ambitos: TCadenasAppParam;
  usuarios: TStringList;
  sAmbito: string;
  sUsuario: string;
begin
  usuarios := TStringList.Create;
  try
    Ambitos := FRepositorioPersistencia.ListarAmbitos;
    for sAmbito in Ambitos do
    begin
      usuarios.Add(sAmbito);
    end;

    if usuarios.Count = 0 then
      ShowMessage_fza(SAvisoSinUsuariosParametrosGuardados)
    else
    begin
      sUsuario := usuarios[0];
      if InputQuery_fza(STituloCambiarUsuario,
                        Format(SSolicitudCambiarUsuario, [usuarios.CommaText]),
                        sUsuario) then
      begin
        if usuarios.IndexOf(sUsuario) < 0 then
          ShowMessage_fza(Format(SErrorUsuarioNoEncontrado, [sUsuario]))
        else
        begin
          CargarParametrosAmbito(
            sUsuario,
            ObtenerGrupoUsuario(sUsuario));
          if cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario) < 0 then
            cmbGrupoUsuario.Properties.Items.Add(sUsuario);
          cmbGrupoUsuario.ItemIndex :=
            cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario);
        end;
      end;
    end;
  finally
    FreeAndNil(usuarios);
  end;
end;

// -----------------------------------------------------------------------
// FILTRADO Y BÚSQUEDA
// -----------------------------------------------------------------------

function TfrmMtoAppParam.QuitarTildes(const Texto: string): string;
var
  i: Integer;
begin
  Result := Texto;
  for i := 1 to Length(Result) do
    case Result[i] of
      'á','à','ä','â': Result[i] := 'a';
      'é','è','ë','ê': Result[i] := 'e';
      'í','ì','ï','î': Result[i] := 'i';
      'ó','ò','ö','ô': Result[i] := 'o';
      'ú','ù','ü','û': Result[i] := 'u';
      'Á','À','Ä','Â': Result[i] := 'A';
      'É','È','Ë','Ê': Result[i] := 'E';
      'Í','Ì','Ï','Î': Result[i] := 'I';
      'Ó','Ò','Ö','Ô': Result[i] := 'O';
      'Ú','Ù','Ü','Û': Result[i] := 'U';
    end;
end;

function TfrmMtoAppParam.BuscarItemPorNombre(
  ItemPadre: TJvCustomInspectorItem;
  const Nombre: string): TJvCustomInspectorItem;
var
  i        : Integer;
  Encontrado: TJvCustomInspectorItem;
begin
  Result := nil;
  i := 0;
  while (i < ItemPadre.Count) and (Result = nil) do
  begin
    if SameText(ItemPadre.Items[i].Name, Nombre) then
      Result := ItemPadre.Items[i]
    else if ItemPadre.Items[i] is TJvInspectorCustomCategoryItem then
    begin
      Encontrado := BuscarItemPorNombre(ItemPadre.Items[i], Nombre);
      if Encontrado <> nil then
        Result := Encontrado;
    end;
    Inc(i);
  end;
end;

procedure TfrmMtoAppParam.FiltrarVerticalGrid(Grid: TJvInspector;
                                              Texto: string);
var
  TextoBusquedaLimpio: string;

  function ProcesarFila(Row: TJvCustomInspectorItem): Boolean;
  var
    Coincide, HijoVisible: Boolean;
    i: Integer;
  begin
    Coincide     := (Texto = '') or
                    AnsiContainsText(QuitarTildes(Row.DisplayName),
                                     TextoBusquedaLimpio);
    HijoVisible  := False;
    if Row is TJvInspectorCustomCategoryItem then
      for i := 0 to Row.Count - 1 do
        if ProcesarFila(Row.Items[i]) then HijoVisible := True;
    Row.Visible := Coincide or HijoVisible;
    if (Row is TJvInspectorCustomCategoryItem) and
       HijoVisible and (Texto <> '') then
      Row.Expanded := True;
    Result := Row.Visible;
  end;

var
  i: Integer;
begin
  Grid.BeginUpdate;
  try
    TextoBusquedaLimpio := QuitarTildes(Texto);
    for i := 0 to Grid.Root.Count - 1 do
      ProcesarFila(Grid.Root.Items[i]);
  finally
    Grid.EndUpdate;
  end;
end;

procedure TfrmMtoAppParam.cxButtonEdit1PropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(JvInspector1, edtBusqueda.Text);
end;

procedure TfrmMtoAppParam.edtBusquedaKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

end.
