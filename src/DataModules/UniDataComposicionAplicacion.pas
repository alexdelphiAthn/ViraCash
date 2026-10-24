{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComposicionAplicacion                                  }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Raíz de composición de servicios, adaptadores y procesos de ViraCash.     }
{    Su fan-out alto es intencionado porque construye implementaciones         }
{    concretas y las expone mediante contratos estrechos; no aloja navegación  }
{    ni lógica de pantallas. Los procesos en segundo plano se delegan en una   }
{    subraíz con dependencias explícitas y ciclo de vida propio.               }
{******************************************************************************}
unit UniDataComposicionAplicacion;

interface

uses
  System.Classes,
  System.SysUtils,
  Uni,
  inLibContextoSesionIntf,
  inLibLicenciaAplicacion,
  inLibExcepcionesAplicacionIntf,
  inLibEnvioErroresIntf,
  inLibCopiasSeguridadIntf,
  inLibOperacionesAplicacionIntf,
  inLibConexionesIntf,
  inLibAuditoriaDatosIntf,
  inLibMonitorSQLIntf,
  inLibLogIntf,
  inLibConfigCamposIntf,
  inLibConfigCampos,
  inLibRepositoriosPantallaIntf,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosConfiguracionPantalla,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosRemesasPantalla,
  UniDataRepositoriosOperacionesPantalla,
  UniDataRepositoriosVentasPantalla,
  UniDataRepositoriosCajaPantalla,
  UniDataRepositoriosTicketsCajaPantalla,
  inLibParametrosIntf,
  inLibPerfilesUsuarioIntf,
  inLibFiltrosGuardadosIntf,
  inLibInformesGuiasCache,
  inLibTraduccionesIntf,
  inLibPermisosIntf,
  inLibFotos,
  inLibUnidadesMedida,
  inLibPreviewTicket,
  inLibUnitForm,
  inLibPrestaShopCierre, inLibEstadoColasIntf,
  UniDataConn,
  UniDataComposicionAplicacionProcesosSegundoPlano;

type
  // Marca compartida con una tarea en segundo plano: la composición la
  // cancela al cerrar y la tarea la consulta, ya en el hilo principal,
  // antes de tocar la composición.
  IMarcaCancelacion = interface
    ['{6F3B2A41-8C1D-4E57-9A0B-3D2C7E4F5A18}']
    function Cancelada: Boolean;
    procedure Cancelar;
  end;

  TComposicionAplicacion = class
  private
    FOwner: TComponent;
    FFabricaConexiones: IFabricaConexionesUniDAC;
    FContextoSesion: IContextoSesionAplicacion;
    FRegistroLog: IRegistroLog;
    FPreviewTicket: IPreviewTicket;
    FRegistroMonitorSQL: IRegistroMonitorSQL;
    FConfigCampos: IConfiguracionCampos;
    FConfigCamposCarga: TConfigCamposCache;
    FDmConn: TdmConn;
    FDmPerfiles: TDataModule;
    FDmFiltros: TDataModule;
    FConexiones: IServicioConexiones;
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FMonitorSQL: IServicioMonitorSQL;
    FServiciosParametrosApp: TServiciosParametrosAplicacion;
    FServiciosParametrosCaja: TServiciosParametrosCaja;
    FServiciosPerfiles: TServiciosPerfilesUsuario;
    FServiciosFiltros: TServiciosFiltrosGuardados;
    FInformesGuias: IInformesGuiasCache;
    FTraducciones: IServicioTraducciones;
    FPermisos: IPermisosAplicacion;
    FFotos: TFotosArticulos;
    FUnidades: TUnidadesMedida;
    FRegistroPantallas: TfzaWinF;
    FGestorExcepciones: IGestorExcepcionesAplicacion;
    FServicioEnvioErrores: IServicioEnvioErrores;
    FRepositorioCopias: IRepositorioCopiasSeguridad;
    FOperaciones: ICasoUsoCopiasSeguridad;
    FProcesosSegundoPlano: TProcesosSegundoPlanoAplicacion;
    FCerrada: Boolean;
    FCancelacionFiscal: IMarcaCancelacion;
    FAvisarFalloSif: TProc<string>;
    FErrorSif: string;
    FComprobacionFiscalEnCurso: Boolean;
    FInicioFiscalPendiente: Boolean;
    FArranqueFiscalFinalizado: Boolean;
    procedure LanzarComprobacionFiscal(const AVersion: string);
    procedure TerminarComprobacionFiscal(
      const AErrorSincronizacion, AErrorDeclaracion: string);
    procedure RegistrarEventoInicioFiscal;
    procedure AvisarFalloSif;
    function PrecargarCachesSerie: string;
    function CrearSqlPantalla(
      const ANombrePantalla: string): TServiciosSqlPantalla;
    procedure LiberarRegistrosServicios;
  public
    constructor Create(
      AOwner: TComponent;
      const AFabricaConexiones: IFabricaConexionesUniDAC;
      const AContextoSesion: IContextoSesionAplicacion;
      const ARegistroLog: IRegistroLog;
      const APreviewTicket: IPreviewTicket;
      const ARegistroMonitorSQL: IRegistroMonitorSQL;
      const AGestorExcepciones: IGestorExcepcionesAplicacion;
      const APresentacionOperaciones:
        IPresentacionOperacionesAplicacion);
    destructor Destroy; override;
    procedure CrearInfraestructura;
    procedure CrearPerfiles;
    procedure CrearParametros(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure CrearServiciosSesion;
    procedure ComprobarConfiguracionFiscal(
      const AVersion: string;
      const AAvisarFalloSif: TProc<string>);
    function CargarDatosArranque: string;
    function LeerEstadosColas: TEstadosColas;
    procedure IniciarProcesosSegundoPlano;
    function PrepararCierrePrestaShop(
      const AConsultarDecision:
        TConsultarDecisionCierrePrestaShop): Boolean;
    procedure RegistrarInicioFiscal;
    procedure FinalizarArranqueFiscal;
    procedure RegistrarCierreFiscal;
    procedure DetenerProcesosSegundoPlano;
    procedure Cerrar;
    function CrearServiciosSqlPantalla(
      const ANombrePantalla: string): TServiciosSqlPantalla;
    function CrearRepositoriosArticulosPantalla(
      const ANombrePantalla: string): IRepositoriosArticulosPantalla;
    function CrearRepositoriosConfiguracionPantalla(
      const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
    function CrearRepositoriosDocumentosPantalla(
      const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
    function CrearRepositoriosRemesasPantalla(
      const ANombrePantalla: string): IRepositoriosRemesasPantalla;
    function CrearRepositoriosOperacionesPantalla(
      const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
    function CrearRepositoriosVentasPantalla(
      const ANombrePantalla: string): IRepositoriosVentasPantalla;
    function CrearRepositoriosCajaPantalla(
      const ANombrePantalla: string): IRepositoriosCajaPantalla;
    function CrearRepositoriosTicketsCajaPantalla(
      const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
    property DmConn: TdmConn read FDmConn;
    property Conexiones: IServicioConexiones read FConexiones;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read FAuditoriaDatos;
    property MonitorSQL: IServicioMonitorSQL read FMonitorSQL;
    property ConfiguracionCampos: IConfiguracionCampos
      read FConfigCampos;
    property ParametrosApp: IParametrosAplicacion
      read FServiciosParametrosApp.Lectura;
    property ParametrosCaja: IParametrosCaja
      read FServiciosParametrosCaja.Lectura;
    property ParametrosAppEdicion: IParametrosEdicion
      read FServiciosParametrosApp.Edicion;
    property ParametrosCajaEdicion: IParametrosEdicion
      read FServiciosParametrosCaja.Edicion;
    property ServiciosPerfiles: TServiciosPerfilesUsuario
      read FServiciosPerfiles;
    property ServiciosFiltros: TServiciosFiltrosGuardados
      read FServiciosFiltros;
    property InformesGuias: IInformesGuiasCache read FInformesGuias;
    property Traducciones: IServicioTraducciones read FTraducciones;
    property Permisos: IPermisosAplicacion read FPermisos;
    property Fotos: TFotosArticulos read FFotos;
    property Unidades: TUnidadesMedida read FUnidades;
    property RegistroPantallas: TfzaWinF read FRegistroPantallas;
    property GestorExcepciones: IGestorExcepcionesAplicacion
      read FGestorExcepciones;
    property Operaciones: ICasoUsoCopiasSeguridad
      read FOperaciones;
    property ContextoSesion: IContextoSesionAplicacion
      read FContextoSesion;
    property RegistroLog: IRegistroLog read FRegistroLog;
  end;

implementation

uses
  System.Diagnostics,
  inLibConexionesUniDAC,
  inLibAuditoriaDatos,
  inLibMonitorSQLUniDAC,
  inLibVerifactu,
  inLibVerifactuInstalacion,
  UniDataConfigCamposRepositorio,
  UniDataUnidadesMedidaRepositorio,
  UniDataRegistroPantallasRepositorio,
  UniDataRepositoriosConfiguracionAplicacionPantalla,
  UniDataRepositoriosOperacionesAplicacionPantalla,
  UniDataRepositoriosPantalla,
  inLibMsgConexion;

type
  TMarcaCancelacion = class(TInterfacedObject, IMarcaCancelacion)
  private
    FCancelada: Boolean;
  public
    function Cancelada: Boolean;
    procedure Cancelar;
  end;

function TMarcaCancelacion.Cancelada: Boolean;
begin
  Result := FCancelada;
end;

procedure TMarcaCancelacion.Cancelar;
begin
  FCancelada := True;
end;

function EsEventoNoVerifactuArranqueCierre(
  ATipoEvento: Integer): Boolean;
begin
  Result := (ATipoEvento = cEventoNoVerifactuInicio) or
            (ATipoEvento = cEventoNoVerifactuFin);
end;

function PuedeRegistrarEventoFiscalSeguro(
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  ATipoEvento: Integer;
  const ADescripcion: string): Boolean;
var
  sNifProductor: string;
begin
  Result := True;
  if EsEventoNoVerifactuArranqueCierre(ATipoEvento) then
  begin
    if not NoVerifactuActivo(AParametrosApp) then
      Result := False
    else
    begin
      sNifProductor := AParametrosApp.GetString('appVerifactuSifNif', '');
      if not EsNifProductorSoftwareVerifactu(sNifProductor) then
      begin
        Result := False;
        ARegistroLog.RegistrarAviso(
          'No se registra evento fiscal "' + ADescripcion +
          '": appVerifactuSifNif no corresponde al productor para el perfil ' +
          'actual.');
      end;
    end;
  end;
end;

constructor TComposicionAplicacion.Create(
  AOwner: TComponent;
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog;
  const APreviewTicket: IPreviewTicket;
  const ARegistroMonitorSQL: IRegistroMonitorSQL;
  const AGestorExcepciones: IGestorExcepcionesAplicacion;
  const APresentacionOperaciones:
    IPresentacionOperacionesAplicacion);
begin
  inherited Create;
  if not Assigned(AOwner) then
    raise EArgumentNilException.Create('AOwner');
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  if not Assigned(ARegistroMonitorSQL) then
    raise EArgumentNilException.Create('ARegistroMonitorSQL');
  if not Assigned(AGestorExcepciones) then
    raise EArgumentNilException.Create('AGestorExcepciones');
  FOwner := AOwner;
  FFabricaConexiones := AFabricaConexiones;
  FContextoSesion := AContextoSesion;
  FRegistroLog := ARegistroLog;
  FPreviewTicket := APreviewTicket;
  FRegistroMonitorSQL := ARegistroMonitorSQL;
  FGestorExcepciones := AGestorExcepciones;
  FDmConn := TdmConn.Create(FOwner);
  FDmConn.AsignarFabrica(AFabricaConexiones);
  FRepositorioCopias := CrearRepositorioCopiasAplicacionPantalla(
    FContextoSesion,
    FDmConn.conUni);
  FOperaciones := CrearOperacionesCopiasAplicacionPantalla(
    FRepositorioCopias,
    APresentacionOperaciones);
  CrearInfraestructura;
  FCerrada := False;
end;

destructor TComposicionAplicacion.Destroy;
begin
  Cerrar;
  inherited;
end;

procedure TComposicionAplicacion.CrearInfraestructura;
begin
  FMonitorSQL := TServicioMonitorSQLUniDAC.Create(
    FDmConn.UniSQLMonitor1,
    FRegistroMonitorSQL);
  FDmConn.AsignarReceptorMonitorSQL(
    FMonitorSQL as IReceptorEventosMonitorSQL);
  FDmConn.conUni.Connect;
  FConexiones := TServicioConexionesUniDAC.Create(
    FDmConn.conUni,
    FFabricaConexiones);
  FConfigCamposCarga := TConfigCamposCache.Create(
    TRepositorioConfigCamposUniDAC.Create(FDmConn.conUni),
    FRegistroLog);
  FConfigCampos := FConfigCamposCarga;
  FUnidades := TUnidadesMedida.Create(
    TRepositorioUnidadesMedidaUniDAC.Create(FDmConn.conUni),
    FRegistroLog);
  FAuditoriaDatos := TServicioAuditoriaDatos.Create(FContextoSesion);
end;

function TComposicionAplicacion.CrearSqlPantalla(
  const ANombrePantalla: string): TServiciosSqlPantalla;
begin
  Result := CrearServiciosSqlPantallaUniDAC(
    ANombrePantalla,
    FServiciosPerfiles.Lectura,
    FServiciosPerfiles.Escritura,
    FRegistroLog,
    FFabricaConexiones.Perfil.Motor);
end;

function TComposicionAplicacion.CrearServiciosSqlPantalla(
  const ANombrePantalla: string): TServiciosSqlPantalla;
begin
  Result := CrearSqlPantalla(ANombrePantalla);
end;

function TComposicionAplicacion.CrearRepositoriosArticulosPantalla(
  const ANombrePantalla: string): IRepositoriosArticulosPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosArticulosPantallaUniDAC(
    FDmConn.conUni, FServiciosParametrosCaja.Lectura, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosConfiguracionPantalla(
  const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosConfiguracionPantallaUniDAC(
    FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosDocumentosPantalla(
  const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosDocumentosPantallaUniDAC(
    FDmConn.conUni,
    FServiciosParametrosApp.Lectura,
    FServiciosParametrosCaja.Lectura,
    FRegistroLog,
    oSql);
end;

function TComposicionAplicacion.CrearRepositoriosRemesasPantalla(
  const ANombrePantalla: string): IRepositoriosRemesasPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosRemesasPantallaUniDAC(
    FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosOperacionesPantalla(
  const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosOperacionesPantallaUniDAC(
    FDmConn.conUni,
    FServiciosParametrosApp.Lectura,
    FServiciosParametrosCaja.Lectura,
    FRegistroLog,
    oSql);
end;

function TComposicionAplicacion.CrearRepositoriosVentasPantalla(
  const ANombrePantalla: string): IRepositoriosVentasPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosVentasPantallaUniDAC(FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosCajaPantalla(
  const ANombrePantalla: string): IRepositoriosCajaPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosCajaPantallaUniDAC(FDmConn.conUni, oSql);
end;

function TComposicionAplicacion.CrearRepositoriosTicketsCajaPantalla(
  const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
var
  oSql: TServiciosSqlPantalla;
begin
  oSql := CrearSqlPantalla(ANombrePantalla);
  Result := CrearRepositoriosTicketsCajaPantallaUniDAC(
    FDmConn.conUni,
    FServiciosParametrosApp.Lectura,
    FServiciosParametrosCaja.Lectura,
    FContextoSesion,
    FPreviewTicket,
    oSql);
end;

procedure TComposicionAplicacion.CrearPerfiles;
var
  oComposicion: TComposicionPerfilesAplicacionPantalla;
begin
  oComposicion := CrearPerfilesAplicacionPantalla(FOwner);
  FDmPerfiles := oComposicion.DataModule;
  FServiciosPerfiles := oComposicion.Servicios;
end;

procedure TComposicionAplicacion.CrearParametros(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
var
  Identidad: TIdentidadSesion;
begin
  Identidad := FContextoSesion.Identidad;
  FRegistroLog.RegistrarInformacion(
    'Arranque: creando parámetros de aplicación');
  FServiciosParametrosApp := CrearParametrosAplicacionPantalla(
    FServiciosPerfiles,
    FRegistroLog,
    Identidad);
  FServiciosParametrosApp.GestorLicencia.EstablecerLicencia(
    AResultadoLicencia);
  FServicioEnvioErrores := CrearServicioEnvioErroresAplicacionPantalla(
    FContextoSesion,
    FServiciosParametrosApp.Lectura,
    FRegistroLog,
    FRepositorioCopias,
    FDmConn.conUni);
  FGestorExcepciones.AsignarServicioEnvioErrores(
    FServicioEnvioErrores);
  FRegistroLog.RegistrarInformacion(
    'Arranque: creando parámetros de caja');
  FServiciosParametrosCaja := CrearParametrosCajaPantalla(
    FServiciosPerfiles,
    FContextoSesion,
    Identidad);
  FDmConn.AsignarParametrosApp(FServiciosParametrosApp.Lectura);
  FTraducciones := CrearTraduccionesAplicacionPantalla(
    FConexiones,
    FRegistroLog,
    FServiciosParametrosApp.Lectura);
  FConfigCamposCarga.AsignarTraducciones(FTraducciones);
end;

procedure TComposicionAplicacion.CrearServiciosSesion;
var
  bCatalogoActivo: Boolean;
  oComposicionFiltros: TComposicionFiltrosAplicacionPantalla;
begin
  bCatalogoActivo := False;
  try
    bCatalogoActivo := SameText(
      FServiciosPerfiles.Lectura.ObtenerValorPerfil(
        FOwner.Name,
        'oGetSQLFromDB',
        'False'),
      'True');
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo leer oGetSQLFromDB de ' + FOwner.Name + ': ' +
        E.Message);
  end;
  FFotos := CrearFotosAplicacionPantalla(
    FDmConn.conUni,
    FServiciosPerfiles,
    FServiciosParametrosApp.Lectura,
    FRegistroLog,
    bCatalogoActivo,
    FFabricaConexiones.Perfil.Motor);
  oComposicionFiltros := CrearFiltrosAplicacionPantalla(FOwner);
  FDmFiltros := oComposicionFiltros.DataModule;
  FServiciosFiltros := oComposicionFiltros.Servicios;
  FServiciosFiltros.Destinos :=
    CrearRepositoriosConfiguracionPantalla('GestionFiltros').
    CrearRepositorioDestinosFiltros;
  FServiciosFiltros.Guias :=
    CrearRepositoriosConfiguracionPantalla('Guias').
    CrearRepositorioGuias;
  FRegistroPantallas := TfzaWinF.Create(
    FOwner,
    FRegistroLog,
    CrearLectorRegistroPantallasUniDAC(FDmConn.conUni));
  FRegistroPantallas.Charge;
  FRegistroPantallas.ComprobarRegistradas;
end;

// La sincronización del número de instalación y la declaración
// responsable llaman al servicio del productor: con la red cortada (una
// VPN, por ejemplo) la petición tardaba 45 s en fallar y el arranque
// esperaba. Van a un hilo con su propia conexión y, si la versión ya
// está registrada en todas las empresas, ni siquiera se llama al
// servicio. El fallo se avisa al terminar el arranque.
// Sin VERI*FACTU (modo SIN) nada usa el número de instalación ni la
// declaración responsable: no se llama al servicio ni se avisa. En SII
// tampoco: el SII no es un sistema informático de facturación (SIF).
procedure TComposicionAplicacion.ComprobarConfiguracionFiscal(
  const AVersion: string;
  const AAvisarFalloSif: TProc<string>);
begin
  FAvisarFalloSif := AAvisarFalloSif;
  if SinVerifactuActivo(FServiciosParametrosApp.Lectura) then
    FRegistroLog.RegistrarInformacion(
      'Sin VERI*FACTU: no se sincroniza la versión SIF ni la ' +
      'declaración responsable')
  else if SiiActivo(FServiciosParametrosApp.Lectura) then
    FRegistroLog.RegistrarInformacion(
      'SII: no se sincroniza la versión SIF ni la declaración responsable')
  else
    LanzarComprobacionFiscal(AVersion);
end;

procedure TComposicionAplicacion.LanzarComprobacionFiscal(
  const AVersion: string);
var
  bSincronizar: Boolean;
  oCancelacion: IMarcaCancelacion;
  oConexiones: IServicioConexiones;
  oParametros: IParametrosAplicacion;
  oRegistroLog: IRegistroLog;
  sUsuario: string;
begin
  bSincronizar := True;
  try
    bSincronizar := not InstalacionesSifAlDia(FDmConn.conUni);
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo comprobar la versión SIF de las empresas: ' +
        E.Message);
  end;
  FCancelacionFiscal := TMarcaCancelacion.Create;
  FComprobacionFiscalEnCurso := bSincronizar;
  oCancelacion := FCancelacionFiscal;
  oConexiones := FConexiones;
  oParametros := FServiciosParametrosApp.Lectura;
  oRegistroLog := FRegistroLog;
  sUsuario := FContextoSesion.Identidad.Usuario;
  TThread.CreateAnonymousThread(
    procedure
    var
      oConexion: TUniConnection;
      sErrorSincronizacion: string;
      sErrorDeclaracion: string;
    begin
      sErrorSincronizacion := '';
      sErrorDeclaracion := '';
      if bSincronizar then
      begin
        oConexion := nil;
        try
          try
            oConexion := oConexiones.CrearConexion(nil, uctPrecarga);
            SincronizarVersionInstalacionesSif(
              oParametros,
              oConexion,
              sUsuario);
          except
            on E: Exception do
              sErrorSincronizacion := E.Message;
          end;
        finally
          FreeAndNil(oConexion);
        end;
      end;
      try
        AsegurarDeclaracionResponsableSif(
          oParametros,
          AVersion,
          oRegistroLog);
      except
        on E: Exception do
          sErrorDeclaracion := E.Message;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if not oCancelacion.Cancelada then
            TerminarComprobacionFiscal(
              sErrorSincronizacion,
              sErrorDeclaracion);
        end);
    end).Start;
end;

// Hilo principal. El inicio fiscal (NO VERI*FACTU) valida el número de
// instalación, así que espera a la sincronización si estaba en curso.
procedure TComposicionAplicacion.TerminarComprobacionFiscal(
  const AErrorSincronizacion, AErrorDeclaracion: string);
begin
  FComprobacionFiscalEnCurso := False;
  if AErrorSincronizacion <> '' then
  begin
    FRegistroLog.RegistrarAviso(
      'No se pudo sincronizar la versión SIF: ' + AErrorSincronizacion);
    FErrorSif := AErrorSincronizacion;
  end;
  if AErrorDeclaracion <> '' then
    FRegistroLog.RegistrarAviso(
      'No se pudo disponer de la declaración responsable de esta ' +
      'versión: ' + AErrorDeclaracion);
  if FInicioFiscalPendiente then
  begin
    FInicioFiscalPendiente := False;
    RegistrarEventoInicioFiscal;
  end;
  if FArranqueFiscalFinalizado then
    AvisarFalloSif;
end;

procedure TComposicionAplicacion.AvisarFalloSif;
var
  sError: string;
begin
  if (FErrorSif <> '') and Assigned(FAvisarFalloSif) then
  begin
    sError := FErrorSif;
    FErrorSif := '';
    FAvisarFalloSif(sError);
  end;
end;

// Se llama con la ventana principal ya visible y el splash cerrado, para
// que el aviso de fallo no quede debajo del splash.
procedure TComposicionAplicacion.FinalizarArranqueFiscal;
begin
  FArranqueFiscalFinalizado := True;
  if not FComprobacionFiscalEnCurso then
    AvisarFalloSif;
end;

function TComposicionAplicacion.PrecargarCachesSerie: string;
var
  IdentidadSesion: TIdentidadSesion;
  swTotal: TStopwatch;
begin
  Result := '';
  swTotal := TStopwatch.StartNew;
  FRegistroLog.RegistrarInformacion(
    'Arranque: PrecargarCachesSerie INICIO');
  FServiciosPerfiles.Cache.PrecargarPerfilesUsuario;
  FInformesGuias := CrearInformesGuiasAplicacionPantalla(
    FDmConn.conUni);
  FInformesGuias.Precargar;
  FConfigCamposCarga.Precargar;
  IdentidadSesion := FContextoSesion.Identidad;
  try
    FPermisos := CargarPermisosAplicacionPantalla(
      FDmConn.conUni,
      IdentidadSesion);
  except
    on E: Exception do
    begin
      FPermisos := CrearPermisosNoDisponiblesPantalla(
        IdentidadSesion);
      Result := E.ClassName + ': ' + E.Message;
    end;
  end;
  FRegistroLog.RegistrarInformacion(
    Format(
      'PrecargaSerie: total=%d ms',
      [swTotal.ElapsedMilliseconds]));
end;

function TComposicionAplicacion.CargarDatosArranque: string;
begin
  Result := PrecargarCachesSerie;
  FUnidades.Cargar;
  FRegistroLog.RegistrarInformacion(
    'Arranque: detección diferida de impresora de caja; valor actual = "' +
    FServiciosParametrosCaja.Lectura.ImpresoraCaja + '"');
  FRegistroLog.RegistrarInformacion(
    'Arranque: detección diferida de impresora de documentos; ' +
    'valor actual = "' +
    FServiciosParametrosApp.Lectura.ImpresoraDocumentos + '"');
end;

function TComposicionAplicacion.LeerEstadosColas: TEstadosColas;
begin
  Result := Default(TEstadosColas);
  if Assigned(FProcesosSegundoPlano) then
    Result := FProcesosSegundoPlano.LeerEstadosColas;
end;

procedure TComposicionAplicacion.IniciarProcesosSegundoPlano;
begin
  if not Assigned(FProcesosSegundoPlano) then
    FProcesosSegundoPlano := TProcesosSegundoPlanoAplicacion.Create(
      FConexiones,
      FContextoSesion,
      FServiciosParametrosApp.Lectura,
      FServiciosParametrosCaja.Lectura,
      FRegistroLog);
  FProcesosSegundoPlano.Iniciar;
end;

function TComposicionAplicacion.PrepararCierrePrestaShop(
  const AConsultarDecision:
    TConsultarDecisionCierrePrestaShop): Boolean;
begin
  Result := True;
  if Assigned(FProcesosSegundoPlano) then
    Result := FProcesosSegundoPlano.PrepararCierrePrestaShop(
      AConsultarDecision);
end;

procedure TComposicionAplicacion.RegistrarInicioFiscal;
begin
  FRegistroLog.RegistrarInformacion('Arranque del sistema');
  if FComprobacionFiscalEnCurso then
  begin
    FInicioFiscalPendiente := True;
    FRegistroLog.RegistrarInformacion(
      'Inicio fiscal diferido hasta sincronizar la versión SIF');
  end
  else
    RegistrarEventoInicioFiscal;
end;

procedure TComposicionAplicacion.RegistrarEventoInicioFiscal;
begin
  if PuedeRegistrarEventoFiscalSeguro(
       FServiciosParametrosApp.Lectura,
       FRegistroLog,
       cEventoNoVerifactuInicio,
       'Inicio del sistema') then
  begin
    try
      RegistrarEventoVerifactu(
        FServiciosParametrosApp.Lectura,
        FDmConn.conUni,
        FContextoSesion.Identidad.Usuario,
        cEventoNoVerifactuInicio,
        'Inicio del sistema');
    except
      on E: Exception do
        FRegistroLog.RegistrarError(
          'No se pudo registrar el inicio fiscal: ' + E.Message);
    end;
  end;
end;

procedure TComposicionAplicacion.RegistrarCierreFiscal;
begin
  if PuedeRegistrarEventoFiscalSeguro(
       FServiciosParametrosApp.Lectura,
       FRegistroLog,
       cEventoNoVerifactuFin,
       'Cierre del sistema') then
  begin
    try
      RegistrarEventoVerifactu(
        FServiciosParametrosApp.Lectura,
        FDmConn.conUni,
        FContextoSesion.Identidad.Usuario,
        cEventoNoVerifactuFin,
        'Cierre del sistema');
    except
      on E: Exception do
        FRegistroLog.RegistrarError(
          'No se pudo registrar el cierre fiscal: ' + E.Message);
    end;
  end;
end;

procedure TComposicionAplicacion.DetenerProcesosSegundoPlano;
begin
  if Assigned(FProcesosSegundoPlano) then
    FProcesosSegundoPlano.Detener;
end;

procedure TComposicionAplicacion.LiberarRegistrosServicios;
begin
  FServiciosFiltros := CrearServiciosFiltrosGuardados(nil, nil, nil);
  FServiciosPerfiles := CrearServiciosPerfilesUsuario(nil, nil, nil);
  FServiciosParametrosApp.Lectura := nil;
  FServiciosParametrosApp.Edicion := nil;
  FServiciosParametrosApp.GestorLicencia := nil;
  FServiciosParametrosCaja.Lectura := nil;
  FServiciosParametrosCaja.Edicion := nil;
end;

procedure TComposicionAplicacion.Cerrar;
begin
  if not FCerrada then
  begin
    FCerrada := True;
    // El hilo de la comprobación fiscal no se espera: puede seguir
    // colgado del servicio. Su resultado se descarta.
    if Assigned(FCancelacionFiscal) then
      FCancelacionFiscal.Cancelar;
    FAvisarFalloSif := nil;
    DetenerProcesosSegundoPlano;
    FreeAndNil(FProcesosSegundoPlano);
    FreeAndNil(FRegistroPantallas);
    if Assigned(FFotos) then
      FFotos.LiberarServicios;
    FreeAndNil(FFotos);
    FreeAndNil(FUnidades);
    if Assigned(FDmConn) then
      FDmConn.AsignarParametrosApp(nil);
    FTraducciones := nil;
    FPermisos := nil;
    FInformesGuias := nil;
    FOperaciones := nil;
    if Assigned(FGestorExcepciones) then
      FGestorExcepciones.AsignarServicioEnvioErrores(nil);
    FServicioEnvioErrores := nil;
    FRepositorioCopias := nil;
    LiberarRegistrosServicios;
    FreeAndNil(FDmFiltros);
    FreeAndNil(FDmPerfiles);
    FAuditoriaDatos := nil;
    if Assigned(FMonitorSQL) then
    begin
      FMonitorSQL.CerrarPendiente;
      FMonitorSQL.EstablecerActivo(False);
      FMonitorSQL.Invalidar;
    end;
    if Assigned(FDmConn) then
      FDmConn.AsignarReceptorMonitorSQL(nil);
    FMonitorSQL := nil;
    if Assigned(FConexiones) then
      FConexiones.Invalidar;
    FConexiones := nil;
    FConfigCampos := nil;
    FConfigCamposCarga := nil;
    FreeAndNil(FDmConn);
    FFabricaConexiones := nil;
    FGestorExcepciones := nil;
    FRegistroMonitorSQL := nil;
    FPreviewTicket := nil;
    FRegistroLog := nil;
    FContextoSesion := nil;
    FOwner := nil;
  end;
end;

end.
