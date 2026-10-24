{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConn                                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/03/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para realizar la conexión     }
{    principal de todos los datos, por aquí pasa todo desde que se hizo login. }
{******************************************************************************}
unit UniDataConn;

interface

uses
  SysUtils, Classes, DBAccess, Uni, DASQLMonitor, UniSQLMonitor,
  inLibMonitorSQLIntf, inLibParametrosIntf, inLibLogIntf,
  inLibConexionesIntf, Data.DB;

type
  TdmConn = class(TDataModule)
    conUni: TUniConnection;
    UniSQLMonitor1: TUniSQLMonitor;
    procedure connBeforeConnect(Sender: TObject);
    procedure UniSQLMonitor1SQL(Sender: TObject; Text: string;
      Flag: TDATraceFlag);
    procedure DataModuleCreate(Sender: TObject);
    procedure conUniError(Sender: TObject; E: EDAError; var Fail: Boolean);
    procedure conUniAfterConnect(Sender: TObject);
  private
    FFabrica: IFabricaConexionesUniDAC;
    FParametrosApp: IParametrosAplicacion;
    FReceptorMonitorSQL: IReceptorEventosMonitorSQL;
    FRegistroLog: IRegistroLog;
    procedure HeredarRegistroLog;
  public
    destructor Destroy; override;
    procedure AsignarFabrica(
      const AFabrica: IFabricaConexionesUniDAC);
    procedure AsignarParametrosApp(
      const AParametrosApp: IParametrosAplicacion);
    procedure AsignarReceptorMonitorSQL(
      const AReceptor: IReceptorEventosMonitorSQL);
  end;

implementation

uses
  inLibConexionPerfilIntf,
  inLibErroresBBDD,
  inLibMsgConexion,
  inLibRegistroLogNulo;

{$R *.dfm}

procedure TdmConn.AsignarFabrica(
  const AFabrica: IFabricaConexionesUniDAC);
begin
  if not Assigned(AFabrica) then
    raise EArgumentException.Create(
      SErrorFabricaConexionesNoAsignada);
  FFabrica := AFabrica;
end;

procedure TdmConn.AsignarParametrosApp(
  const AParametrosApp: IParametrosAplicacion);
begin
  FParametrosApp := AParametrosApp;
end;

procedure TdmConn.AsignarReceptorMonitorSQL(
  const AReceptor: IReceptorEventosMonitorSQL);
begin
  FReceptorMonitorSQL := AReceptor;
end;

destructor TdmConn.Destroy;
var
  ServicioMonitorSQL: IServicioMonitorSQL;
begin
  if Supports(
       FReceptorMonitorSQL,
       IServicioMonitorSQL,
       ServicioMonitorSQL) then
    ServicioMonitorSQL.Invalidar;
  FReceptorMonitorSQL := nil;
  FRegistroLog := nil;
  FParametrosApp := nil;
  FFabrica := nil;
  inherited;
end;

procedure TdmConn.connBeforeConnect(Sender: TObject);
var
  oConexion: TUniConnection;
begin
  if not Assigned(FFabrica) then
    raise EInvalidOpException.Create(
      SErrorFabricaConexionesNoAsignada);
  if Sender is TUniConnection then
    oConexion := TUniConnection(Sender)
  else
    oConexion := conUni;
  FFabrica.ConfigurarConexion(oConexion);
end;

procedure TdmConn.conUniAfterConnect(Sender: TObject);
var
  oConexion: TUniConnection;
begin
  if not Assigned(FFabrica) then
    raise EInvalidOpException.Create(
      SErrorFabricaConexionesNoAsignada);
  if Sender is TUniConnection then
    oConexion := TUniConnection(Sender)
  else
    oConexion := conUni;
  FFabrica.InicializarSesion(oConexion);
end;

procedure TdmConn.conUniError(Sender: TObject; E: EDAError; var Fail: Boolean);
var
  bIncluirDetalle: Boolean;
  sValidacion: string;
begin
  if not Assigned(FFabrica) then
    raise EInvalidOpException.Create(
      SErrorFabricaConexionesNoAsignada);
  bIncluirDetalle := {$IFDEF DEBUG}True{$ELSE}
    Assigned(FParametrosApp) and
    FParametrosApp.GetBool('appModoDebug', False){$ENDIF};
  FRegistroLog.RegistrarError(
    FFabrica.FormatearError(E.ErrorCode, E.Message, True));
  Fail := False;
  if (FFabrica.Perfil.Motor = mbMariaDB) and
     ((E.ErrorCode = 1040) or (E.ErrorCode = 1226)) then
    raise ELimiteConexionesBBDD.Create(
      FFabrica.FormatearError(E.ErrorCode, E.Message, False));
  // Mantener el rechazo como excepción para abortar la operación y permitir
  // su rollback; el gestor de UI lo presenta como aviso, también en Release.
  if (FFabrica.Perfil.Motor = mbMariaDB) and
     ObtenerMensajeValidacionBBDD(E.ErrorCode, E.Message,
       sValidacion) then
    raise EValidacionBBDD.Create(
      FFabrica.FormatearError(E.ErrorCode, E.Message, False));
  // Un bloqueo del motor no dice nada del dato ni de la petición: se
  // distingue por su clase para que quien reintente no lo confunda
  // con un rechazo y gaste intentos de más
  if (FFabrica.Perfil.Motor = mbMariaDB) and
     EsBloqueoTemporalBBDD(E.ErrorCode) then
    raise EBloqueoBBDDTemporal.Create(
      E.ErrorCode,
      FFabrica.FormatearError(
        E.ErrorCode, E.Message, bIncluirDetalle));
  if (FFabrica.Perfil.Motor = mbMariaDB) and
     EsConexionPerdidaBBDD(E.ErrorCode) then
    raise EConexionPerdidaBBDD.Create(
      FFabrica.FormatearError(E.ErrorCode, E.Message, False));
  raise EErrorBBDD.Create(
    FFabrica.FormatearError(
      E.ErrorCode, E.Message, bIncluirDetalle));
end;

procedure TdmConn.DataModuleCreate(Sender: TObject);
begin
  HeredarRegistroLog;
  // El monitor se queda activo siempre; el filtrado real lo hace TLog
  // segun IsLogTypeEnabled(ltSQL). El estado del monitor lo reajusta
  // IRegistroLog reajusta el modo al cargar o cambiar los parámetros.
  UniSQLMonitor1.Active := True;
end;

procedure TdmConn.HeredarRegistroLog;
var
  Proveedor: IProveedorRegistroLog;
begin
  FRegistroLog := nil;
  if Supports(Owner, IProveedorRegistroLog, Proveedor) then
    FRegistroLog := Proveedor.RegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
end;

procedure TdmConn.UniSQLMonitor1SQL(Sender: TObject; Text: string;
  Flag: TDATraceFlag);
var
  Evento: TEventoMonitorSQL;
begin
  Evento := emsOtro;
  case Flag of
    tfQExecute:
      Evento := emsEjecutar;
    tfConnect, tfQFetch, tfObjDestroy:
      Evento := emsFinalizar;
    tfError:
      Evento := emsError;
  end;
  if Assigned(FReceptorMonitorSQL) then
    FReceptorMonitorSQL.ProcesarEvento(Text, Evento);
end;

end.
