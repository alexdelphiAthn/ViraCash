{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConexionFabrica                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Punto único donde un perfil independiente se traduce a una conexión       }
{    UniDAC para MariaDB/MySQL o PostgreSQL.                                   }
{******************************************************************************}
unit UniDataConexionFabrica;

interface

uses
  inLibConexionPerfilIni,
  inLibConexionesIntf;

function CrearFabricaConexionesUniDAC(
  const AConfiguracion: TConfiguracionConexionResuelta;
  const ARutaIni: string = ''): IFabricaConexionesUniDAC;
function CrearFabricaConexionesAplicacionUniDAC(
  const ADirectorioConfiguracion: string): IFabricaConexionesUniDAC;

implementation

uses
  System.Classes,
  System.SysUtils,
  MySQLUniProvider,
  PostgreSQLUniProvider,
  Uni,
  inLibConexionPerfil,
  inLibConexionPerfilIntf,
  inLibDialectoSqlIntf,
  inLibDialectosSql,
  inLibErroresBBDD,
  inLibMsgConexion,
  inLibMsgConfiguracion,
  inLibMsgSql,
  UniDataReconexionAcotada;

type
  TFabricaConexionesUniDAC = class(
    TInterfacedObject,
    IFabricaConexionesUniDAC,
    IEstadoCredencialConexion)
  private
    FConfiguracion: TConfiguracionConexionResuelta;
    FDialectoSql: IDialectoSql;
    FProveedorMariaDB: TMySQLUniProvider;
    FProveedorPostgreSQL: TPostgreSQLUniProvider;
    FRutaIni: string;
    function GetPerfil: TPerfilConexion;
    function GetCapacidades: TCapacidadesMotorBBDD;
    function GetDialectoSql: IDialectoSql;
    procedure AplicarOpcionesComunes(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure AplicarOpcionesMariaDB(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion);
    procedure AplicarOpcionesPostgreSQL(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion);
  public
    constructor Create(
      const AConfiguracion: TConfiguracionConexionResuelta;
      const ARutaIni: string);
    destructor Destroy; override;
    function CrearConexion(AOwner: TComponent): TUniConnection;
    function CrearPerfilAdministrativo(
      const APerfilBase: TPerfilConexion): TPerfilConexion;
    procedure ConfigurarConexion(AConexion: TUniConnection);
    procedure ConfigurarConexionTemporal(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure Conectar(AConexion: TUniConnection);
    procedure ConectarTemporal(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure InicializarSesion(AConexion: TUniConnection);
    procedure InicializarSesionTemporal(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion);
    procedure ActualizarConfiguracion(
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure GuardarConfiguracion;
    function FormatearError(
      ACodigo: Integer;
      const AMensaje: string;
      AIncluirDetalle: Boolean): string;
    function EtiquetaMotor: string;
    function TieneCredencial: Boolean;
  end;

procedure AsignarOpcion(
  AConexion: TUniConnection;
  const ANombre, AValor: string);
begin
  AConexion.SpecificOptions.Values[ANombre] := AValor;
end;

procedure ValidarPerfilParaAdaptador(
  const APerfil: TPerfilConexion);
var
  sMotivo: string;
begin
  if not ValidarPerfilConexion(APerfil, sMotivo) then
    raise EArgumentException.Create(
      Format(SErrorPerfilConexionNoValido, [sMotivo]));
  case APerfil.Motor of
    mbMariaDB:
      if not (APerfil.SSL in [sslDesactivado, sslRequerido]) then
        raise EArgumentException.CreateFmt(
          SErrorSSLMySQLNoSoportado,
          [NombreModoSSLConexion(APerfil.SSL)]);
    mbPostgreSQL:
      if APerfil.SSL = sslVerificarCompleto then
        raise EArgumentException.Create(
          SErrorSSLPostgreSQLVerificacionCompletaNoDisponible);
    mbSQLServer:
      raise ENotSupportedException.CreateFmt(
        SErrorMotorConexionPendiente,
        [NombreMotorBBDD(APerfil.Motor)]);
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

constructor TFabricaConexionesUniDAC.Create(
  const AConfiguracion: TConfiguracionConexionResuelta;
  const ARutaIni: string);
begin
  inherited Create;
  ValidarPerfilParaAdaptador(AConfiguracion.Perfil);
  FConfiguracion := AConfiguracion;
  FDialectoSql := CrearDialectoSql(FConfiguracion.Perfil.Motor);
  FRutaIni := ARutaIni;
  FProveedorMariaDB := TMySQLUniProvider.Create(nil);
  FProveedorPostgreSQL := TPostgreSQLUniProvider.Create(nil);
end;

destructor TFabricaConexionesUniDAC.Destroy;
begin
  FConfiguracion.Credencial := '';
  FDialectoSql := nil;
  FProveedorPostgreSQL.Free;
  FProveedorMariaDB.Free;
  inherited;
end;

function TFabricaConexionesUniDAC.GetPerfil: TPerfilConexion;
begin
  Result := FConfiguracion.Perfil;
end;

function TFabricaConexionesUniDAC.GetCapacidades: TCapacidadesMotorBBDD;
begin
  Result := ResolverCapacidadesMotorBBDD(FConfiguracion.Perfil.Motor);
end;

function TFabricaConexionesUniDAC.GetDialectoSql: IDialectoSql;
begin
  Result := FDialectoSql;
end;

procedure TFabricaConexionesUniDAC.AplicarOpcionesComunes(
  AConexion: TUniConnection;
  const APerfil: TPerfilConexion;
  const ACredencial: string);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create(
      SErrorConexionNoAsignada);
  AConexion.SpecificOptions.Clear;
  AConexion.LoginPrompt := False;
  AConexion.Server := APerfil.Servidor;
  AConexion.Port := APerfil.Puerto;
  AConexion.Database := APerfil.BaseDatos;
  AConexion.Username := APerfil.Usuario;
  AConexion.Password := ACredencial;
  AConexion.Pooling := APerfil.Pool.Habilitado;
  AConexion.PoolingOptions.Validate := APerfil.Pool.Validar;
  AConexion.PoolingOptions.MinPoolSize := APerfil.Pool.MinimoConexiones;
  AConexion.PoolingOptions.MaxPoolSize := APerfil.Pool.MaximoConexiones;
  AConexion.PoolingOptions.ConnectionLifetime :=
    APerfil.Pool.TiempoVidaSeg * 1000;
  AsignarOpcion(
    AConexion,
    'ConnectionTimeout',
    IntToStr(APerfil.TimeoutConexionSeg));
  AConexion.Options.LocalFailover := True;
  AConexion.Options.DisconnectedMode := True;
  AcotarReconexion(AConexion);
end;

procedure TFabricaConexionesUniDAC.AplicarOpcionesMariaDB(
  AConexion: TUniConnection;
  const APerfil: TPerfilConexion);
begin
  AsignarOpcion(AConexion, 'MySQL.UseUnicode', 'True');
  AsignarOpcion(AConexion, 'MySQL.Charset', 'utf8mb4');
  AsignarOpcion(AConexion, 'MySQL.Interactive', 'True');
  case APerfil.SSL of
    sslDesactivado:
      AsignarOpcion(AConexion, 'MySQL.Protocol', 'mpDefault');
    sslRequerido:
      AsignarOpcion(AConexion, 'MySQL.Protocol', 'mpSSL');
  else
    raise EArgumentException.CreateFmt(
      SErrorSSLMySQLNoSoportado,
      [NombreModoSSLConexion(APerfil.SSL)]);
  end;
  if APerfil.RutaCertificadoCA <> '' then
    AsignarOpcion(
      AConexion, 'MySQL.SSLCACert', APerfil.RutaCertificadoCA);
  if APerfil.RutaCertificadoCliente <> '' then
    AsignarOpcion(
      AConexion, 'MySQL.SSLCert', APerfil.RutaCertificadoCliente);
  if APerfil.RutaClavePrivada <> '' then
    AsignarOpcion(
      AConexion, 'MySQL.SSLKey', APerfil.RutaClavePrivada);
end;

procedure TFabricaConexionesUniDAC.AplicarOpcionesPostgreSQL(
  AConexion: TUniConnection;
  const APerfil: TPerfilConexion);
const
  MODOS_SSL: array[TModoSSLConexion] of string = (
    'smDisable',
    'smPrefer',
    'smRequire',
    'smVerifyCA',
    'smVerifyFull');
begin
  AsignarOpcion(AConexion, 'PostgreSQL.UseUnicode', 'True');
  AsignarOpcion(AConexion, 'PostgreSQL.Charset', 'UTF8');
  AsignarOpcion(AConexion, 'PostgreSQL.ApplicationName', 'ViraCash');
  AsignarOpcion(AConexion, 'PostgreSQL.Schema', APerfil.Esquema);
  AsignarOpcion(
    AConexion,
    'PostgreSQL.SSLMode',
    MODOS_SSL[APerfil.SSL]);
  if APerfil.RutaCertificadoCA <> '' then
    AsignarOpcion(
      AConexion,
      'PostgreSQL.SSLCACert',
      APerfil.RutaCertificadoCA);
  if APerfil.RutaCertificadoCliente <> '' then
    AsignarOpcion(
      AConexion,
      'PostgreSQL.SSLCert',
      APerfil.RutaCertificadoCliente);
  if APerfil.RutaClavePrivada <> '' then
    AsignarOpcion(
      AConexion,
      'PostgreSQL.SSLKey',
      APerfil.RutaClavePrivada);
end;

procedure TFabricaConexionesUniDAC.ConfigurarConexionTemporal(
  AConexion: TUniConnection;
  const APerfil: TPerfilConexion;
  const ACredencial: string);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create(
      SErrorConexionNoAsignada);
  ValidarPerfilParaAdaptador(APerfil);
  if AConexion.Connected then
    AConexion.Disconnect;
  AConexion.ConnectString := '';
  case APerfil.Motor of
    mbMariaDB:
      AConexion.ProviderName := 'MySQL';
    mbPostgreSQL:
      AConexion.ProviderName := 'PostgreSQL';
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
  AplicarOpcionesComunes(AConexion, APerfil, ACredencial);
  case APerfil.Motor of
    mbMariaDB:
      AplicarOpcionesMariaDB(AConexion, APerfil);
    mbPostgreSQL:
      AplicarOpcionesPostgreSQL(AConexion, APerfil);
  end;
end;

procedure TFabricaConexionesUniDAC.ConfigurarConexion(
  AConexion: TUniConnection);
begin
  ConfigurarConexionTemporal(
    AConexion,
    FConfiguracion.Perfil,
    FConfiguracion.Credencial);
end;

function TFabricaConexionesUniDAC.CrearConexion(
  AOwner: TComponent): TUniConnection;
begin
  Result := TUniConnection.Create(AOwner);
  try
    ConfigurarConexion(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TFabricaConexionesUniDAC.CrearPerfilAdministrativo(
  const APerfilBase: TPerfilConexion): TPerfilConexion;
begin
  Result := APerfilBase;
  case Result.Motor of
    mbMariaDB:
      begin
        Result.BaseDatos := 'information_schema';
        Result.Esquema := '';
      end;
    mbPostgreSQL:
      begin
        Result.BaseDatos := 'postgres';
        Result.Esquema := 'public';
      end;
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

procedure TFabricaConexionesUniDAC.ConectarTemporal(
  AConexion: TUniConnection;
  const APerfil: TPerfilConexion;
  const ACredencial: string);
begin
  ConfigurarConexionTemporal(AConexion, APerfil, ACredencial);
  AConexion.Connect;
  try
    InicializarSesionTemporal(AConexion, APerfil);
  except
    if AConexion.Connected then
    begin
      AConexion.RemoveFromPool;
      AConexion.Disconnect;
    end;
    raise;
  end;
end;

procedure TFabricaConexionesUniDAC.Conectar(
  AConexion: TUniConnection);
begin
  ConectarTemporal(
    AConexion,
    FConfiguracion.Perfil,
    FConfiguracion.Credencial);
end;

procedure TFabricaConexionesUniDAC.InicializarSesionTemporal(
  AConexion: TUniConnection;
  const APerfil: TPerfilConexion);
var
  i: Integer;
  oComandos: TComandosInicializacionSesionSql;
  oDialecto: IDialectoSql;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create(
      SErrorConexionNoAsignada);
  oDialecto := CrearDialectoSql(APerfil.Motor);
  oComandos := oDialecto.ComandosInicializacionSesion;
  for i := 0 to High(oComandos) do
  begin
    try
      AConexion.ExecSQL(oComandos[i].Texto);
    except
      if oComandos[i].Obligatorio then
        raise;
    end;
  end;
end;

procedure TFabricaConexionesUniDAC.InicializarSesion(
  AConexion: TUniConnection);
begin
  InicializarSesionTemporal(AConexion, FConfiguracion.Perfil);
end;

procedure TFabricaConexionesUniDAC.ActualizarConfiguracion(
  const APerfil: TPerfilConexion;
  const ACredencial: string);
begin
  ValidarPerfilParaAdaptador(APerfil);
  FConfiguracion.Perfil := APerfil;
  FConfiguracion.Credencial := ACredencial;
  FDialectoSql := CrearDialectoSql(APerfil.Motor);
  FConfiguracion.ProcedeDeFormatoLegado := False;
end;

procedure TFabricaConexionesUniDAC.GuardarConfiguracion;
begin
  if Trim(FRutaIni) = '' then
    raise EInvalidOpException.Create(
      SErrorFabricaSinRutaConfiguracion);
  GuardarConfiguracionConexionIni(FRutaIni, FConfiguracion);
  FConfiguracion.ProcedeDeFormatoLegado := False;
  FConfiguracion.ReferenciaCredencialAnterior := '';
end;

function TFabricaConexionesUniDAC.FormatearError(
  ACodigo: Integer;
  const AMensaje: string;
  AIncluirDetalle: Boolean): string;
var
  bCatalogado: Boolean;
  sMensajeSeguro: string;
begin
  sMensajeSeguro := AMensaje;
  if FConfiguracion.Credencial <> '' then
    sMensajeSeguro := StringReplace(
      sMensajeSeguro,
      FConfiguracion.Credencial,
      '***',
      [rfReplaceAll]);
  bCatalogado := False;
  if FConfiguracion.Perfil.Motor = mbMariaDB then
  begin
    bCatalogado := True;
    case ACodigo of
      1644: bCatalogado := ObtenerMensajeValidacionBBDD(
        ACodigo, sMensajeSeguro, Result);
      1062: Result := SErrorBBDDDuplicado;
      1048,
      1364: Result := SErrorBBDDCamposObligatorios;
      1054: Result := SErrorConsultaCampoDesconocido;
      1146: Result := SErrorConsultaTablaNoExiste;
      1142,
      1143: Result := SErrorBBDDSinPermisos;
      1216,
      1452: Result := SErrorBBDDClaveForaneaNoExiste;
      1217,
      1451: Result := SErrorBBDDRegistroDependiente;
      1406: Result := SErrorBBDDDatoDemasiadoLargo;
      1045: Result := SErrorBBDDCredencialesIncorrectas;
      2003: Result := SErrorConexionServidorMotor;
      2006: Result := SErrorConexionPerdidaMotor;
      2013: Result := SErrorBBDDConexionPerdidaConsulta;
      1205: Result := SErrorBBDDTimeoutBloqueo;
      1213: Result := SErrorBBDDDeadlock;
      1050: Result := SErrorConsultaTablaYaExiste;
      1304: Result := SErrorConsultaProcedimientoYaExiste;
    else
      bCatalogado := False;
    end;
  end;
  if not bCatalogado then
  begin
    if AIncluirDetalle then
      Result := Format(
        SErrorBBDDGenerico,
        [ACodigo, sMensajeSeguro])
    else
      Result := Format(
        SErrorConexionMotorSinDetalle,
        [ACodigo]);
  end;
  if AIncluirDetalle and bCatalogado and (ACodigo <> 0) then
    Result := Result + Format(
      SDetalleErrorMotorBBDD,
      [EtiquetaMotor, ACodigo, sMensajeSeguro]);
end;

function TFabricaConexionesUniDAC.EtiquetaMotor: string;
begin
  Result := NombreMotorBBDD(FConfiguracion.Perfil.Motor);
end;

function TFabricaConexionesUniDAC.TieneCredencial: Boolean;
begin
  Result := FConfiguracion.Credencial <> '';
end;

function CrearFabricaConexionesUniDAC(
  const AConfiguracion: TConfiguracionConexionResuelta;
  const ARutaIni: string): IFabricaConexionesUniDAC;
begin
  Result := TFabricaConexionesUniDAC.Create(
    AConfiguracion,
    ARutaIni);
end;

function CrearFabricaConexionesAplicacionUniDAC(
  const ADirectorioConfiguracion: string): IFabricaConexionesUniDAC;
var
  sRutaIni: string;
  oConfiguracion: TConfiguracionConexionResuelta;
begin
  sRutaIni := RutaPerfilConexionAplicacion(
    ADirectorioConfiguracion);
  oConfiguracion := CargarConfiguracionConexionIni(sRutaIni);
  Result := CrearFabricaConexionesUniDAC(
    oConfiguracion,
    sRutaIni);
end;

end.
