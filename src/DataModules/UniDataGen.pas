{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGen                                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module base de los mantenimientos (TdmBase).                         }
{    Provee unqryTablaG y servicios comunes (perfiles, GetOwnerForm) que       }
{    heredan los Mtos.                                                         }
{******************************************************************************}
unit UniDataGen;

interface

uses
  System.SysUtils, System.Classes, System.TypInfo, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, inLibWin, inLibAnfitrionDatosIntf,
  inLibAuditoriaDatosIntf, inLibConexionesIntf, inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf, inLibParametrosIntf,
  inLibFotos, inLibUnidadesMedida, inLibInteraccionDatosIntf,
  inLibLogIntf, inLibMtoGenAplicacionIntf,
  UniDataTotalMaximoLinea;

type
  TdmBase = class(
    TDataModule,
    IAnfitrionDatosDocumento,
    IProveedorAuditoriaDatos,
    IProveedorConexiones,
    IProveedorContextoSesion,
    IProveedorPerfilesUsuario,
    IProveedorParametros,
    IProveedorRegistroLog,
    IProveedorFotosArticulos,
    IProveedorUnidadesMedida
  )
    unqryTablaG: TUniQuery;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
  private
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FPerfilesLectura: ILectorPerfilesUsuario;
    FPerfilesEscritura: IEscritorPerfilesUsuario;
    FCachePerfiles: ICachePerfilesUsuario;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FRegistroLog: IRegistroLog;
    FFotosArticulos: TFotosArticulos;
    FUnidadesMedida: TUnidadesMedida;
    FSqlBaseBusquedaExterna: string;
    FTablaActualizableBusquedaExterna: string;
    FOnActivarFicha: TNotifyEvent;
    FOnNotificarMensaje: TNotificarMensajeDatosEvent;
    FOnConfirmarMensaje: TConfirmarMensajeDatosEvent;
    FBorradoTransaccionPropia: Boolean;
    FVigilanteTotalLinea: TVigilanteTotalMaximoLinea;
    function GetCurrentForm: TComponent;
    function GetAuditoriaDatos: IServicioAuditoriaDatos;
    function GetConexiones: IServicioConexiones;
    function GetContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    function GetUbicacionSesion: TUbicacionSesion;
    function GetPerfilesLectura: ILectorPerfilesUsuario;
    function GetServiciosPerfilesUsuario: TServiciosPerfilesUsuario;
    function GetParametrosApp: IParametrosAplicacion;
    function GetParametrosCaja: IParametrosCaja;
    function GetRegistroLog: IRegistroLog;
    function GetFotosArticulos: TFotosArticulos;
    function GetUnidadesMedida: TUnidadesMedida;
    function GetConexionPrincipal: TUniConnection;
    procedure SetCurrentForm(const Value: TComponent);
    procedure HeredarAuditoriaDatos(AOwner: TComponent);
    procedure HeredarConexiones(AOwner: TComponent);
    procedure HeredarContextoSesion(AOwner: TComponent);
    procedure HeredarPerfilesUsuario(AOwner: TComponent);
    procedure HeredarParametros(AOwner: TComponent);
    procedure HeredarRegistroLog(AOwner: TComponent);
    procedure HeredarFotosArticulos(AOwner: TComponent);
    procedure HeredarUnidadesMedida(AOwner: TComponent);
    procedure NotificarMensaje(const AMensaje: string;
      ASeveridad: TSeveridadMensajeDatos);
  protected
    // DataSource de la cabecera (dsTablaG del Mto), empujado por el
    // form via AsignarMaestroCabecera.
    FMaestroCabecera: TDataSource;
    procedure DoCreate; reintroduce; virtual;
    function GetOwnerForm<T: TComponent>: T;
    function HasOwnerForm: Boolean;
    procedure ActualizarAuditoria(DataSet: TDataSet);
    procedure NotificarInformacion(const AMensaje: string);
    procedure NotificarAdvertencia(const AMensaje: string);
    procedure NotificarError(const AMensaje: string);
    function SolicitarConfirmacion(const AMensaje: string): Boolean;
    procedure EjecutarContadorDocumento(AProcedimiento: TUniStoredProc);
    // FZ-ISSUE-255: pide confirmación al grabar una línea cuyo total sube
    // por encima del máximo de la empresa de la sesión. Se llama al final
    // del DataModuleCreate, cuando ya están asignados los manejadores de
    // las líneas.
    procedure VigilarTotalMaximoLinea(ALineas: TUniQuery;
      const ACampoTotal: string);
    // Borrado de una cabecera de documento todo o nada (FZ-ISSUE-154):
    // el BeforeDelete abre la transacción en la conexión de unqryTablaG
    // antes de su primera escritura; AfterDelete la confirma y
    // OnDeleteError (o cualquier excepción del BeforeDelete) la revierte.
    procedure IniciarBorradoTransaccional;
    procedure RevertirBorradoTransaccional;
    procedure ConfirmarBorradoTransaccional(DataSet: TDataSet);
    procedure ErrorBorradoTransaccional(DataSet: TDataSet;
      E: EDatabaseError; var Action: TDataAction);
  public
    constructor Create(AOwner: TComponent); override;
    // FZ-ISSUE-255: confirma un total de línea antes de que llegue al
    // dataset (matriz de tallas). True si no hay vigilancia.
    function ConfirmarTotalLineaPendiente(ATotalNuevo: Currency): Boolean;
    property CurrentForm: TComponent read GetCurrentForm write SetCurrentForm;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read GetAuditoriaDatos;
    property Conexiones: IServicioConexiones read GetConexiones;
    property ContextoSesion: IContextoSesionAplicacion
      read GetContextoSesion;
    property IdentidadSesion: TIdentidadSesion
      read GetIdentidadSesion;
    property UbicacionSesion: TUbicacionSesion
      read GetUbicacionSesion;
    property PerfilesLectura: ILectorPerfilesUsuario
      read GetPerfilesLectura;
    property ParametrosApp: IParametrosAplicacion read GetParametrosApp;
    property ParametrosCaja: IParametrosCaja read GetParametrosCaja;
    property RegistroLog: IRegistroLog read GetRegistroLog;
    property FotosArticulos: TFotosArticulos read GetFotosArticulos;
    property UnidadesMedida: TUnidadesMedida read GetUnidadesMedida;
    property ConexionPrincipal: TUniConnection
      read GetConexionPrincipal;
    procedure AsignarAuditoriaDatos(
      const AAuditoriaDatos: IServicioAuditoriaDatos);
    procedure AsignarConexiones(
      const AConexiones: IServicioConexiones);
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
    procedure AsignarPerfilesUsuario(
      const AServicios: TServiciosPerfilesUsuario);
    procedure AsignarParametros(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja);
    procedure AsignarRegistroLog(
      const ARegistroLog: IRegistroLog);
    // El form empuja el DataSource de su cabecera (dsTablaG); el DM ya
    // no sube a buscarlo con GetOwnerForm. Cada TdmXxx sobreescribe
    // para cablear los MasterSource de sus detalles.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); virtual;
    function UsaCambiosDiferidos: Boolean; virtual;
    procedure AplicarCambiosDiferidos; virtual;
    procedure ConfirmarCambiosDiferidos; virtual;
    procedure RestaurarCambiosDiferidos; virtual;
    // Tabla principal del documento, expuesta por el contrato
    // IAnfitrionDatosDocumento para que inLib* cablee sin conocer
    // TdmBase.
    function ObtenerTablaPrincipal: TDataSet;
    // Aviso al insertar en la tabla principal: el form suscrito activa
    // su pestania de ficha (antes el DM tocaba pcPantalla del form).
    property OnActivarFicha: TNotifyEvent
      read FOnActivarFicha write FOnActivarFicha;
    property OnNotificarMensaje: TNotificarMensajeDatosEvent
      read FOnNotificarMensaje write FOnNotificarMensaje;
    property OnConfirmarMensaje: TConfirmarMensajeDatosEvent
      read FOnConfirmarMensaje write FOnConfirmarMensaje;
    function CrearConexionTrabajo(
      AOwner: TComponent;
      AUso: TUsoConexionTrabajo
    ): TUniConnection;
    procedure ResetGridsProfile(sGrid, sForm, sPermisos:String);
    // Reasigna la conexion (TUniConnection) de todos los datasets/SQL del
    // data module a `NewConn`. Lo usa TfrmMtoGen tras crear el data module
    // para que cada pestaña use una conexion propia del pool en lugar de
    // la conexion principal compartida (asi dos tabs no se serializan).
    procedure ReasignarConexion(NewConn: TUniConnection);
    // Corta consultas/procedimientos UniDAC en curso antes de destruir el
    // mantenimiento. Se llama desde el hilo principal mientras la tarea BBDD
    // corre en background.
    procedure CancelarEjecucionActiva;
    procedure PrepararBusquedaExterna(
      const ACamposClave, AValoresClave: string);
    function RestaurarListaTrasBusquedaExterna: Boolean;
    function AplicarRestriccionUsuario(
      const AFiltro: string): Boolean;
    // Abre las queries detalle/lookup propias del Mto. Default no hace
    // nada; cada TdmXxx override para listar sus queries en el orden
    // adecuado. Lo invoca TfrmMtoGen.AbrirTablaPrincipalAsync DENTRO del
    // thread tras abrir unqryTablaG, asi todas las queries se abren en
    // background mientras la UI muestra el overlay y otros tabs siguen
    // interactivos. Antes esto ocurria sincrono en DataModuleCreate (y
    // congelaba la UI 21s en Articulos).
    procedure AbrirDetalles; virtual;
    // Reactiva los TDataSource y dispara cualquier AfterScroll que se
    // hubiera suprimido durante AbrirDetalles. Se invoca en MAIN thread
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync. Cada Mto override para
    // recorrer sus DataSource concretos.
    procedure ReactivarControlesTrasAbrir; virtual;
  public
    FCurrentForm: TComponent;
    FoPerfilDic: TProfileDicc;
  end;

  // Referencia de clase del data module de documento; los formularios
  // la pasan a AsegurarDataModuleDocumento (movida desde
  // inLibColumnasDocumento en la Fase 2b).
  TClaseDataModuleDocumento = class of TdmBase;

// Reutiliza o crea el data module del documento validando su clase.
function AsegurarDataModuleDocumento(
  APropietario: TComponent; var ADataModule: TObject;
  AClaseDataModule: TClaseDataModuleDocumento): TdmBase;
function CrearConsultaBusquedaMtoGenUniDAC(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const ASql: string): TDataSet;
function CrearCasoUsoGuardadoMtoGenUniDAC(
  AConexion: TUniConnection): ICasoUsoGuardadoMtoGen;
procedure CargarConfiguracionAltaRapidaMtoGenUniDAC(
  AConexion: TUniConnection;
  const ANombreTabla: string;
  out AConfiguracion: TConfiguracionAltaRapidaMtoGen);
function EjecutarAltaRapidaMtoGenUniDAC(
  AConexion: TUniConnection;
  AConexionContadores: TUniConnection;
  const AConfiguracion: TConfiguracionAltaRapidaMtoGen;
  const ACodigo, ADescripcion, AUsuario: string;
  const AAuditoria: IServicioAuditoriaDatos): TResultadoAltaRapidaMtoGen;

//var
//  dmBase: TdmBase;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  Vcl.Forms, UniDataAlmacenesEmpresaRepositorio,
  inLibMsgComun, inLibRegistroLogNulo,
  inLibDatasets, inLibFiltroUsuario, inLibMtoGenAplicacion,
  inLibPrestaShopColaSenal,
  UniDataValoresAutomaticosRepositorio;

{$R *.dfm}

type
  TUnidadTrabajoMtoGenUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoMtoGen)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

constructor TUnidadTrabajoMtoGenUniDAC.Create(AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TUnidadTrabajoMtoGenUniDAC.EstaActiva: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TUnidadTrabajoMtoGenUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoMtoGenUniDAC.Confirmar;
begin
  FConexion.Commit;
  SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoMtoGenUniDAC.Revertir;
begin
  FConexion.Rollback;
end;

function CrearCasoUsoGuardadoMtoGenUniDAC(
  AConexion: TUniConnection): ICasoUsoGuardadoMtoGen;
begin
  Result := CrearCasoUsoGuardadoMtoGen(
    TUnidadTrabajoMtoGenUniDAC.Create(AConexion));
end;

function CrearConsultaBusquedaMtoGenUniDAC(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const ASql: string): TDataSet;
var
  oConsulta: TUniQuery;
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  oConsulta := TUniQuery.Create(AOwner);
  oConsulta.Connection := AConexion;
  oConsulta.SQL.Text := ASql;
  Result := oConsulta;
end;

function ProcesarValorAltaRapidaMtoGen(
  const AValor, ATipo: string): Variant;
begin
  if SameText(ATipo, 'INTEGER') then
    Result := StrToIntDef(AValor, 0)
  else if SameText(ATipo, 'FLOAT') then
    Result := StrToFloatDef(AValor, 0.0)
  else if SameText(ATipo, 'BOOLEAN') then
    Result := SameText(AValor, 'TRUE') or (AValor = '1')
  else
    Result := AValor;
end;

procedure CargarConfiguracionAltaRapidaMtoGenUniDAC(
  AConexion: TUniConnection;
  const ANombreTabla: string;
  out AConfiguracion: TConfiguracionAltaRapidaMtoGen);
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  AConfiguracion := Default(TConfiguracionAltaRapidaMtoGen);
  AConfiguracion.Tabla := ANombreTabla;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CAMPO_OBJETIVO_DEF_VD, VALOR_DEF_VD, ' +
      'TIPO_DATO_DEF_VD, VALORES_POSIBLES_DEF_VD ' +
      'FROM fza_gen_defaults ' +
      'WHERE TABLA_OBJETIVO_DEF_VD = :Tabla';
    oConsulta.ParamByName('Tabla').AsString := ANombreTabla;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(AConfiguracion.Valores);
      SetLength(AConfiguracion.Valores, iIndice + 1);
      AConfiguracion.Valores[iIndice].Campo :=
        oConsulta.FieldByName('CAMPO_OBJETIVO_DEF_VD').AsString;
      AConfiguracion.Valores[iIndice].Valor :=
        ProcesarValorAltaRapidaMtoGen(
          oConsulta.FieldByName('VALOR_DEF_VD').AsString,
          oConsulta.FieldByName('TIPO_DATO_DEF_VD').AsString);
      AConfiguracion.Valores[iIndice].Opciones :=
        oConsulta.FieldByName('VALORES_POSIBLES_DEF_VD').AsString;
      oConsulta.Next;
    end;
    oConsulta.Close;
    oConsulta.SQL.Text :=
      'SELECT TIPO_DOC_CON FROM fza_contadores ' +
      'WHERE TABLAORIGEN_CONTADOR = :Tabla AND SERIE_CON = ''-''';
    oConsulta.ParamByName('Tabla').AsString := ANombreTabla;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      AConfiguracion.TipoDocumentoContador :=
        oConsulta.FieldByName('TIPO_DOC_CON').AsString;
  finally
    oConsulta.Free;
  end;
end;

function EjecutarAltaRapidaMtoGenUniDAC(
  AConexion: TUniConnection;
  AConexionContadores: TUniConnection;
  const AConfiguracion: TConfiguracionAltaRapidaMtoGen;
  const ACodigo, ADescripcion, AUsuario: string;
  const AAuditoria: IServicioAuditoriaDatos): TResultadoAltaRapidaMtoGen;
var
  oConsulta: TUniQuery;
  sCodigoFinal: string;
  i: Integer;
  bTransaccionPropia: Boolean;
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  Result := Default(TResultadoAltaRapidaMtoGen);
  sCodigoFinal := ACodigo;
  oConsulta := TUniQuery.Create(nil);
  bTransaccionPropia := not AConexion.InTransaction;
  try
    try
      oConsulta.Connection := AConexion;
      if bTransaccionPropia then
        AConexion.StartTransaction;
      if ((Trim(sCodigoFinal) = '0') or
          (Trim(sCodigoFinal) = '')) and
         (AConfiguracion.TipoDocumentoContador <> '') then
      begin
        sCodigoFinal := ObtenerSiguienteContador(
          AConexionContadores,
          AConfiguracion.TipoDocumentoContador,
          AUsuario);
        if sCodigoFinal = '' then
          raise Exception.Create(SErrorContadorAutomaticoBusqueda);
      end;
      oConsulta.SQL.Text := 'SELECT * FROM ' + AConfiguracion.Tabla +
        ' WHERE 1=0';
      oConsulta.Open;
      oConsulta.Insert;
      if oConsulta.FindField(AConfiguracion.CampoCodigo) <> nil then
        oConsulta.FieldByName(
          AConfiguracion.CampoCodigo).AsString := sCodigoFinal;
      if oConsulta.FindField(AConfiguracion.CampoDescripcion) <> nil then
        oConsulta.FieldByName(
          AConfiguracion.CampoDescripcion).AsString := ADescripcion;
      for i := 0 to High(AConfiguracion.Valores) do
      begin
        if oConsulta.FindField(AConfiguracion.Valores[i].Campo) <> nil then
          oConsulta.FieldByName(
            AConfiguracion.Valores[i].Campo).Value :=
            AConfiguracion.Valores[i].Valor;
      end;
      if AAuditoria <> nil then
        AAuditoria.Actualizar(oConsulta);
      oConsulta.Post;
      if bTransaccionPropia then
        AConexion.Commit;
      Result.Exito := True;
      Result.Codigo := sCodigoFinal;
    except
      on E: Exception do
      begin
        if bTransaccionPropia and AConexion.InTransaction then
          AConexion.Rollback;
        if oConsulta.State in [dsInsert, dsEdit] then
          oConsulta.Cancel;
        Result.Error := E.Message;
      end;
    end;
  finally
    oConsulta.Free;
  end;
end;

constructor TdmBase.Create(AOwner: TComponent);
begin
  HeredarAuditoriaDatos(AOwner);
  HeredarConexiones(AOwner);
  HeredarContextoSesion(AOwner);
  HeredarPerfilesUsuario(AOwner);
  HeredarParametros(AOwner);
  HeredarRegistroLog(AOwner);
  HeredarFotosArticulos(AOwner);
  HeredarUnidadesMedida(AOwner);
  inherited Create(AOwner);
end;

procedure TdmBase.HeredarAuditoriaDatos(AOwner: TComponent);
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

procedure TdmBase.HeredarConexiones(AOwner: TComponent);
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

procedure TdmBase.HeredarContextoSesion(AOwner: TComponent);
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

procedure TdmBase.HeredarPerfilesUsuario(AOwner: TComponent);
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

procedure TdmBase.HeredarParametros(AOwner: TComponent);
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

procedure TdmBase.HeredarRegistroLog(AOwner: TComponent);
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

procedure TdmBase.AsignarAuditoriaDatos(
  const AAuditoriaDatos: IServicioAuditoriaDatos);
begin
  FAuditoriaDatos := AAuditoriaDatos;
end;

function TdmBase.GetAuditoriaDatos: IServicioAuditoriaDatos;
begin
  Result := FAuditoriaDatos;
end;

procedure TdmBase.AsignarConexiones(
  const AConexiones: IServicioConexiones);
begin
  FConexiones := AConexiones;
end;

function TdmBase.GetConexiones: IServicioConexiones;
begin
  Result := FConexiones;
end;

procedure TdmBase.AsignarContextoSesion(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  FContextoSesion := AContextoSesion;
end;

procedure TdmBase.AsignarPerfilesUsuario(
  const AServicios: TServiciosPerfilesUsuario);
begin
  FPerfilesLectura := AServicios.Lectura;
  FPerfilesEscritura := AServicios.Escritura;
  FCachePerfiles := AServicios.Cache;
end;

procedure TdmBase.AsignarParametros(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja);
begin
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
end;

procedure TdmBase.AsignarRegistroLog(
  const ARegistroLog: IRegistroLog);
begin
  if Assigned(ARegistroLog) then
    FRegistroLog := ARegistroLog
  else
    FRegistroLog := CrearRegistroLogNulo;
end;

function TdmBase.GetContextoSesion: IContextoSesionAplicacion;
begin
  Result := FContextoSesion;
end;

function TdmBase.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionModuloDatosNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function TdmBase.GetUbicacionSesion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionModuloDatosNoConfigurado);
  Result := FContextoSesion.Ubicacion;
end;

function TdmBase.GetPerfilesLectura: ILectorPerfilesUsuario;
begin
  Result := FPerfilesLectura;
end;

procedure TdmBase.HeredarFotosArticulos(AOwner: TComponent);
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

procedure TdmBase.HeredarUnidadesMedida(AOwner: TComponent);
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

function TdmBase.GetServiciosPerfilesUsuario:
  TServiciosPerfilesUsuario;
begin
  Result := CrearServiciosPerfilesUsuario(
    FPerfilesLectura,
    FPerfilesEscritura,
    FCachePerfiles);
end;

function TdmBase.GetParametrosApp: IParametrosAplicacion;
begin
  Result := FParametrosApp;
end;

function TdmBase.GetParametrosCaja: IParametrosCaja;
begin
  Result := FParametrosCaja;
end;

function TdmBase.GetRegistroLog: IRegistroLog;
begin
  Result := FRegistroLog;
end;

function TdmBase.GetFotosArticulos: TFotosArticulos;
begin
  Result := FFotosArticulos;
end;

function TdmBase.GetUnidadesMedida: TUnidadesMedida;
begin
  Result := FUnidadesMedida;
end;

function TdmBase.GetConexionPrincipal: TUniConnection;
begin
  Result := nil;
  if Assigned(FConexiones) then
    Result := FConexiones.ConexionPrincipal;
  if not Assigned(Result) and
     not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
end;

function TdmBase.CrearConexionTrabajo(
  AOwner: TComponent;
  AUso: TUsoConexionTrabajo): TUniConnection;
begin
  if not Assigned(FConexiones) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
  Result := FConexiones.CrearConexion(AOwner, AUso);
end;

procedure TdmBase.ActualizarAuditoria(DataSet: TDataSet);
begin
  if Assigned(FAuditoriaDatos) then
    FAuditoriaDatos.Actualizar(DataSet)
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioAuditoriaDatosNoConfigurado);
end;

procedure TdmBase.NotificarMensaje(const AMensaje: string;
  ASeveridad: TSeveridadMensajeDatos);
begin
  if Assigned(FOnNotificarMensaje) then
    FOnNotificarMensaje(Self, AMensaje, ASeveridad)
  else
  begin
    case ASeveridad of
      smdInformacion:
        FRegistroLog.RegistrarInformacion(AMensaje);
      smdAdvertencia:
        FRegistroLog.RegistrarAviso(AMensaje);
      smdError:
        FRegistroLog.RegistrarError(AMensaje);
    end;
  end;
end;

procedure TdmBase.NotificarInformacion(const AMensaje: string);
begin
  NotificarMensaje(AMensaje, smdInformacion);
end;

procedure TdmBase.NotificarAdvertencia(const AMensaje: string);
begin
  NotificarMensaje(AMensaje, smdAdvertencia);
end;

procedure TdmBase.NotificarError(const AMensaje: string);
begin
  NotificarMensaje(AMensaje, smdError);
end;

function TdmBase.SolicitarConfirmacion(
  const AMensaje: string): Boolean;
begin
  Result := False;
  if Assigned(FOnConfirmarMensaje) then
    Result := FOnConfirmarMensaje(Self, AMensaje)
  else
    FRegistroLog.RegistrarAviso(
      'Confirmación de datos sin presentador: ' + AMensaje);
end;

procedure TdmBase.VigilarTotalMaximoLinea(ALineas: TUniQuery;
  const ACampoTotal: string);
begin
  FVigilanteTotalLinea := TVigilanteTotalMaximoLinea.Create(Self, ALineas,
    ACampoTotal,
    function: Currency
    var
      oArticulo: TField;
      sArticulo: string;
    begin
      // TOTAL_ALBLIN -> CODIGO_ART_ALBLIN: el artículo de la línea para el
      // máximo automático (FZ-ISSUE-331).
      sArticulo := '';
      oArticulo := ALineas.FindField(
        'CODIGO_ART_' + Copy(ACampoTotal, Length('TOTAL_') + 1, MaxInt));
      if Assigned(oArticulo) then
        sArticulo := oArticulo.AsString;
      Result := LeerTotalMaximoLinea(ALineas.Connection,
        UbicacionSesion.Empresa, sArticulo);
    end,
    function(const AMensaje: string): Boolean
    begin
      Result := SolicitarConfirmacion(AMensaje);
    end);
end;

function TdmBase.ConfirmarTotalLineaPendiente(
  ATotalNuevo: Currency): Boolean;
begin
  Result := (not Assigned(FVigilanteTotalLinea)) or
            FVigilanteTotalLinea.ConfirmarTotalPendiente(ATotalNuevo);
end;

procedure TdmBase.EjecutarContadorDocumento(AProcedimiento: TUniStoredProc);
begin
  EjecutarContadorDocumentoUniDAC(AProcedimiento,
    IdentidadSesion.EsAdministrador,
    function(AMensaje: string): Boolean
    begin
      Result := SolicitarConfirmacion(AMensaje);
    end);
end;

procedure TdmBase.DoCreate;
var
  Conexion: TUniConnection;
begin
  FoPerfilDic := nil;
  Conexion := ConexionPrincipal;
  if Assigned(Conexion) then
  begin
    unqryTablaG.Connection := Conexion;
    unqryPerfiles.Connection := Conexion;
  end;
end;

procedure TdmBase.DataModuleCreate(Sender: TObject);
begin
  DoCreate;
end;

procedure TdmBase.DataModuleDestroy(Sender: TObject);
begin
  unqryTablaG.Close;
  unqryPerfiles.Close;
  if (FoPerfilDic <> nil) then
    FreeAndNil(FoPerfilDic);
//  oPerfilDic.Free;
end;

function TdmBase.GetCurrentForm: TComponent;
begin
  Result := FCurrentForm;
end;

procedure TdmBase.SetCurrentForm(const Value: TComponent);
begin
  FCurrentForm := Value;
end;

function TdmBase.GetOwnerForm<T>: T;
begin
  Result := nil;
  if Assigned(FCurrentForm) and (FCurrentForm is T) then
    Result := T(FCurrentForm)
  else if (Self.Owner <> nil) and (Self.Owner is T) then
    Result := T(Self.Owner);
end;

function TdmBase.HasOwnerForm: Boolean;
begin
  Result := Assigned(FCurrentForm) and
            not (csDestroying in FCurrentForm.ComponentState);
end;

procedure TdmBase.IniciarBorradoTransaccional;
begin
  FBorradoTransaccionPropia := not unqryTablaG.Connection.InTransaction;
  if FBorradoTransaccionPropia then
    unqryTablaG.Connection.StartTransaction;
end;

procedure TdmBase.RevertirBorradoTransaccional;
begin
  if FBorradoTransaccionPropia then
  begin
    if unqryTablaG.Connection.InTransaction then
      unqryTablaG.Connection.Rollback;
    FBorradoTransaccionPropia := False;
  end;
end;

procedure TdmBase.ConfirmarBorradoTransaccional(DataSet: TDataSet);
begin
  if FBorradoTransaccionPropia then
  begin
    try
      unqryTablaG.Connection.Commit;
      FBorradoTransaccionPropia := False;
    except
      RevertirBorradoTransaccional;
      raise;
    end;
    SolicitarProcesadoPrestaShop;
  end;
end;

procedure TdmBase.ErrorBorradoTransaccional(DataSet: TDataSet;
  E: EDatabaseError; var Action: TDataAction);
begin
  RevertirBorradoTransaccional;
  Action := daFail;
end;

procedure TdmBase.ReasignarConexion(NewConn: TUniConnection);
var
  i: Integer;
  Comp: TComponent;
  ds: TCustomDADataSet;
  sql: TCustomDASQL;
begin
  if NewConn <> nil then
  begin
    for i := 0 to ComponentCount - 1 do
    begin
      Comp := Components[i];
      // TUniQuery, TUniTable y TUniStoredProc derivan de este tipo.
      if Comp is TCustomDADataSet then
      begin
        ds := TCustomDADataSet(Comp);
        // Los datasets activos conservan la conexion con la que abrieron.
        if not ds.Active then
          ds.Connection := NewConn;
      end
      // TUniSQL y TUniScript no tienen estado activo.
      else if Comp is TCustomDASQL then
      begin
        sql := TCustomDASQL(Comp);
        sql.Connection := NewConn;
      end;
    end;
  end;
end;

procedure TdmBase.AbrirDetalles;
begin
  // Default: nada. Los Mtos con queries detalle/lookup override este metodo.
end;

procedure TdmBase.ReactivarControlesTrasAbrir;
begin
  // Default: nada.
end;

procedure TdmBase.CancelarEjecucionActiva;
var
  i: Integer;
  Comp: TComponent;
begin
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];
    try
      if Comp is TUniQuery then
        TUniQuery(Comp).BreakExec
      else if Comp is TUniStoredProc then
        TUniStoredProc(Comp).BreakExec;
    except
      on E: Exception do
        FRegistroLog.RegistrarError('No se pudo cancelar ' + Comp.Name + ': ' +
                              E.Message);
    end;
  end;
end;

// Alias de la tabla derivada de la busqueda externa. MariaDB atribuye las
// columnas de una tabla derivada a su alias; si el alias no coincide con
// UpdatingTable, UniDAC deja los campos en solo lectura (SetFieldsReadOnly)
// y la instancia de busqueda (Clientes 1, Proveedores 1...) no se puede
// editar. Con el nombre de la tabla los metadatos son los del modo normal.
// Si el modulo no fija UpdatingTable, no se le asigna aqui: con la tabla
// derivada como unica tabla exterior UniDAC ya actualiza sobre su alias
// (= la tabla), y forzarla cuando la consulta interna la nombra con alias
// ('FROM vi_albaranes_compra V') dejaba todos los campos en solo lectura
// ("Field 'NUMERO_ALBC' cannot be modified" al pulsar + en el albaran de
// compra abierto con Ir al documento, FZ-ISSUE-214).
// Si el modulo si la fija, se retira mientras dura la busqueda y se repone
// al restaurar la lista: cuando la consulta nombra la tabla con alias
// ('FROM fza_facturas_compra F') UniDAC la ve dos veces, dentro y como
// alias de la derivada, y no abre ("Ambiguous UpdatingTable value" al
// abrir el borrador de factura de compra recien creado, FZ-ISSUE-417).
function AliasBusquedaExterna(const ATabla: string): string;
var
  c: Char;
begin
  Result := Trim(ATabla);
  if LastDelimiter('.', Result) > 0 then
    Result := Copy(Result, LastDelimiter('.', Result) + 1, MaxInt);
  Result := StringReplace(Result, '`', '', [rfReplaceAll]);
  for c in Result do
    if not CharInSet(c, ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      Result := '';
  if Result = '' then
    Result := 'sub_busqueda'
  else
    Result := '`' + Result + '`';
end;

procedure TdmBase.PrepararBusquedaExterna(
  const ACamposClave, AValoresClave: string);
var
  aCampos: TArray<string>;
  aValores: TArray<string>;
  i: Integer;
  sBase: string;
  sTabla: string;
  sWhere: string;
begin
  if (ACamposClave <> '') and (AValoresClave <> '') and
     Assigned(unqryTablaG) then
  begin
    unqryTablaG.Close;
    if FSqlBaseBusquedaExterna = '' then
    begin
      FSqlBaseBusquedaExterna := unqryTablaG.SQL.Text;
      FTablaActualizableBusquedaExterna := unqryTablaG.UpdatingTable;
    end
    else
      unqryTablaG.SQL.Text := FSqlBaseBusquedaExterna;
    aCampos := ACamposClave.Split([';']);
    aValores := AValoresClave.Split([',']);
    sWhere := '';
    for i := 0 to High(aCampos) do
    begin
      if (i <= High(aValores)) and (Trim(aCampos[i]) <> '') then
      begin
        if sWhere <> '' then
          sWhere := sWhere + ' AND ';
        sWhere := sWhere + Trim(aCampos[i]) + ' = ' +
          QuotedStr(Trim(aValores[i]));
      end;
    end;
    if sWhere <> '' then
    begin
      sBase := TrimRight(FSqlBaseBusquedaExterna);
      while (sBase <> '') and (sBase[Length(sBase)] = ';') do
        sBase := TrimRight(Copy(sBase, 1, Length(sBase) - 1));
      sTabla := FTablaActualizableBusquedaExterna;
      if sTabla = '' then
        sTabla := ExtraerTablaDeSQL(FSqlBaseBusquedaExterna);
      unqryTablaG.UpdatingTable := '';
      unqryTablaG.SQL.Text := 'SELECT * FROM (' + sLineBreak +
        sBase + sLineBreak + ') ' +
        AliasBusquedaExterna(sTabla) +
        ' WHERE ' + sWhere;
    end;
  end;
end;

function TdmBase.RestaurarListaTrasBusquedaExterna: Boolean;
begin
  Result := False;
  if Assigned(unqryTablaG) and (FSqlBaseBusquedaExterna <> '') then
  begin
    if (unqryTablaG.State in dsEditModes) or CheckOpenDatasets(Self) then
      raise EDatabaseError.Create(SErrorRestaurarListaEnEdicion);
    unqryTablaG.Close;
    unqryTablaG.SQL.Text := FSqlBaseBusquedaExterna;
    unqryTablaG.UpdatingTable := FTablaActualizableBusquedaExterna;
    FSqlBaseBusquedaExterna := '';
    FTablaActualizableBusquedaExterna := '';
    Result := True;
  end;
end;

function TdmBase.AplicarRestriccionUsuario(
  const AFiltro: string): Boolean;
begin
  Result := False;
  if Assigned(unqryTablaG) and (AFiltro <> '') and
     (Pos(AFiltro, unqryTablaG.SQL.Text) = 0) then
  begin
    if unqryTablaG.Active then
      unqryTablaG.Close;
    unqryTablaG.SQL.Text := InyectarFiltroSql(
      unqryTablaG.SQL.Text,
      AFiltro);
    Result := True;
  end;
end;

procedure TdmBase.ResetGridsProfile(sGrid, sForm, sPermisos: String);
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := ConexionPrincipal;
  unqrySol.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                       '      WHERE USUARIO_GRUPO_USUPER = :user ' +
                       '        AND KEY_USUPER = :form ';
//                       '        AND SUBKEY_USUPER LIKE ' +
//                                                      QuotedSTr(sGrid + '_%');
  unqrysol.ParamByName('user').AsString := sPermisos;
  unqrysol.ParamByName('form').AsString := sForm;
  unqrySol.Execute;
  FreeAndNil(unqrySol);
end;

procedure TdmBase.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  ActualizarAuditoria(DataSet);
  FRegistroLog.RegistrarEvento(
    Self.UnitName,
    DataSet.Name,
    'BeforePost',
    'state=' + GetEnumName(
      TypeInfo(TDataSetState),
      Ord(DataSet.State)));
end;

// Guarda el maestro empujado por el form; los TdmXxx sobreescriben y
// cablean aqui los MasterSource de sus queries de detalle.
procedure TdmBase.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  FMaestroCabecera := ADataSource;
end;

procedure TdmBase.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  // El DM ya no toca la UI: avisa y el form activa su pestania Ficha.
  if Assigned(FOnActivarFicha) then
    FOnActivarFicha(Self);
  FRegistroLog.RegistrarEvento(
    Self.UnitName,
    DataSet.Name,
    'BeforeInsert',
    '');
end;

procedure TdmBase.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  AjustarEmpresasAlmacenesDocumento(unqryTablaG.Connection, DataSet);
  ActualizarAuditoria(DataSet);
  FRegistroLog.RegistrarEvento(
    Self.UnitName,
    DataSet.Name,
    'BeforePost',
    'state=' + GetEnumName(
      TypeInfo(TDataSetState),
      Ord(DataSet.State)));
end;

function TdmBase.UsaCambiosDiferidos: Boolean;
begin
  Result := False;
end;

procedure TdmBase.AplicarCambiosDiferidos;
begin
end;

procedure TdmBase.ConfirmarCambiosDiferidos;
begin
end;

procedure TdmBase.RestaurarCambiosDiferidos;
begin
end;

function TdmBase.ObtenerTablaPrincipal: TDataSet;
begin
  Result := unqryTablaG;
end;

function AsegurarDataModuleDocumento(
  APropietario: TComponent; var ADataModule: TObject;
  AClaseDataModule: TClaseDataModuleDocumento): TdmBase;
begin
  if not Assigned(AClaseDataModule) then
    raise EArgumentNilException.Create(
      'No se ha indicado la clase del data module.');
  if Assigned(ADataModule) then
  begin
    if ADataModule.ClassType.InheritsFrom(AClaseDataModule) then
      Result := TdmBase(ADataModule)
    else
      raise EInvalidCast.CreateFmt(
        'El data module %s no es de la clase %s.',
        [ADataModule.ClassName, AClaseDataModule.ClassName]);
  end
  else
  begin
    Result := AClaseDataModule.Create(APropietario);
    ADataModule := Result;
  end;
end;

end.
