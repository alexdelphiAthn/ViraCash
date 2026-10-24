{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaProcesador                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Procesador UniDAC de la cola Verifactu y worker con conexión propia.      }
{******************************************************************************}
unit UniDataVerifactuColaProcesador;
interface
uses
  System.Classes, Uni, inLibConexionesIntf, inLibParametrosIntf,
  inLibContextoSesionIntf, inLibVerifactuColaIntf, inLibLogIntf,
  inLibVerifactuEnvio, inLibEstadoColasIntf;
type
  TContextoProcesadorVerifactuCola = record
    Conexiones: IServicioConexiones;
    ContextoSesion: IContextoSesionAplicacion;
    ParametrosApp: IParametrosAplicacion;
    ParametrosCaja: IParametrosCaja;
    RegistroLog: IRegistroLog;
    Estado: IEstadoCola;
    Usuario: string;
  end;
  THiloVerifactuCola = class(TThread)
  private
    FConn: TUniConnection;
    FContexto: TContextoProcesadorVerifactuCola;
    FAvisoNoDisponible: Boolean;
    // La cola tiene SISTEMA_VFCOLA (script 791); se mira en cada ciclo
    FColaConSistema: Boolean;
    function PuedeContinuar: Boolean;
    function ColumnaSistema: string;
    procedure ProcesarPendientes;
    procedure VaciarCola;
    procedure ProcesarRegistroEnVuelo(AQry: TUniQuery);
    procedure ProcesarPendientesOrdenados(AQry: TUniQuery);
    function ReclamarFila(AIdCola: Int64; ASii: Boolean;
      out AFechaHoraGen: string): Boolean;
    procedure LiberarRegistroEnVuelo(AIdCola: Int64);
    function ProcesarFila(AIdCola: Int64;
      const ASistema, ASerie, ANumero, ATipoOperacion: string;
      AIntentos: Integer): Integer;
    procedure ConservarIntentoFallido(AIdCola: Int64;
      const ASerie, ANumero, ATipoOperacion: string;
      const AResultado: TResultadoEnvioVerifactu);
    procedure PublicarResultado(AIdCola: Int64;
      const AResultado: TResultadoEnvioVerifactu);
    procedure EsperarCiclo;
    procedure EsperarSegundos(ASegundos: Integer;
      AAtenderSenal: Boolean = False);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContexto: TContextoProcesadorVerifactuCola); reintroduce;
    destructor Destroy; override;
  end;
function CrearProcesadorVerifactuColaUniDAC(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog = nil;
  const AEstado: IEstadoCola = nil): IProcesadorVerifactuCola;
implementation
uses
  inLibEstadoColas, UniDataEstadoColas, inLibMsgIntegraciones,
  Winapi.Windows, System.SysUtils, Data.DB, inLibVerifactu,
  inLibColaTurnoIntf,
  UniDataColaTurno, inLibErroresBBDD, inLibVerifactuTipos,
  UniDataVerifactuColaResultados, inLibErroresHttp, inLibColasSenal,
  System.SyncObjs,
  UniDataVerifactuSubsanacionResultados, inLibVerifactuReintentos,
  UniDataVerifactuColaRepositorio, inLibSiiConstruccionEnvio;
const
  CResultadoFilaSinConexion = -1;
  // Contención con otro puesto: se repite antes que un fallo de red,
  // porque el bloqueo se suelta en cuanto el otro envío termina
  CResultadoFilaBloqueoBBDD = -2;
  CSegundosReintentoSinConexion = 300;
  CSegundosReintentoBloqueo = 60;
  // Reintento tras un cierre de la app o un fallo local con el registro
  // ya enviado: no hay que esperar a la red, solo al siguiente arranque
  CSegundosReintentoInterrumpido = 60;
  fidvfcola       = 'ID_VFCOLA';
  fserievfcola    = 'SERIE_FAC_VFCOLA';
  fnumerovfcola   = 'NUMERO_FAC_VFCOLA';
  ftipoopvfcola   = 'TIPO_OPERACION_VFCOLA';
  fintentosvfcola = 'CONTADOR_INTENTOS_VFCOLA';
  fsistemavfcola  = 'SISTEMA_VFCOLA';
type
  TProcesadorVerifactuColaUniDAC = class(
    TInterfacedObject,
    IProcesadorVerifactuCola)
  private
    FContexto: TContextoProcesadorVerifactuCola;
    FHilo: THiloVerifactuCola;
    FIniciado: Boolean;
  public
    constructor Create(
      const AContexto: TContextoProcesadorVerifactuCola);
    destructor Destroy; override;
    procedure Iniciar;
    procedure Detener;
  end;
function CrearProcesadorVerifactuColaUniDAC(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog;
  const AEstado: IEstadoCola): IProcesadorVerifactuCola;
var
  oContexto: TContextoProcesadorVerifactuCola;
begin
  oContexto := Default(TContextoProcesadorVerifactuCola);
  oContexto.Conexiones := AConexiones;
  oContexto.ContextoSesion := AContextoSesion;
  oContexto.ParametrosApp := AParametrosApp;
  oContexto.ParametrosCaja := AParametrosCaja;
  oContexto.Usuario := AUsuario;
  oContexto.RegistroLog := ARegistroLog;
  oContexto.Estado := AEstado;
  if not Assigned(oContexto.Estado) then
    oContexto.Estado := CrearEstadoCola;
  Result := TProcesadorVerifactuColaUniDAC.Create(oContexto);
end;
constructor TProcesadorVerifactuColaUniDAC.Create(
  const AContexto: TContextoProcesadorVerifactuCola);
begin
  if not Assigned(AContexto.Conexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContexto.ContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AContexto.ParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AContexto.ParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create;
  FContexto := AContexto;
  if not Assigned(FContexto.Estado) then
    FContexto.Estado := CrearEstadoCola;
  FHilo := nil;
  FIniciado := False;
end;
destructor TProcesadorVerifactuColaUniDAC.Destroy;
begin
  Detener;
  FContexto := Default(TContextoProcesadorVerifactuCola);
  inherited;
end;
procedure TProcesadorVerifactuColaUniDAC.Iniciar;
begin
  if not FIniciado then
  begin
    FHilo := THiloVerifactuCola.Create(FContexto);
    try
      FHilo.FreeOnTerminate := False;
      FHilo.Start;
      FIniciado := True;
      if Assigned(FContexto.RegistroLog) then
        FContexto.RegistroLog.RegistrarInformacion(
          'Cola Verifactu: hilo iniciado');
    except
      FreeAndNil(FHilo);
      raise;
    end;
  end;
end;
procedure TProcesadorVerifactuColaUniDAC.Detener;
begin
  if FIniciado then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    FIniciado := False;
    if Assigned(FContexto.RegistroLog) then
      FContexto.RegistroLog.RegistrarInformacion(
        'Cola Verifactu: hilo detenido');
  end;
end;
// ===========================================================================
//   THiloVerifactuCola — worker en segundo plano
// ===========================================================================
constructor THiloVerifactuCola.Create(
  const AContexto: TContextoProcesadorVerifactuCola);
begin
  if not Assigned(AContexto.Conexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContexto.ContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AContexto.ParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AContexto.ParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create(True);
  FContexto := AContexto;
  if not Assigned(FContexto.Estado) then
    FContexto.Estado := CrearEstadoCola;
end;
destructor THiloVerifactuCola.Destroy;
begin
  FreeAndNil(FConn);
  FContexto := Default(TContextoProcesadorVerifactuCola);
  inherited;
end;
procedure THiloVerifactuCola.Execute;
begin
  NameThreadForDebugging('VerifactuCola');
  FAvisoNoDisponible := False;
  while (not Terminated) and
        (not FContexto.ContextoSesion.CerrandoAplicacion) do
  begin
    // La espera va primero: deja respirar el arranque de la app y
    // permite cerrar sin procesar nada a medias
    EsperarCiclo;
    if (not Terminated) and
       (not FContexto.ContextoSesion.CerrandoAplicacion) and
       // En SII también se terminan de enviar las filas que quedaran
       // de VERI*FACTU (y al revés): cada fila sale por su sistema
       (ModoVerifactu(FContexto.ParametrosApp) in
         [mvVerifactu, mvSii]) then
    begin
      try
        FContexto.Estado.IniciarCiclo;
        ProcesarPendientes;
      except
        on E: Exception do
        begin
          if Assigned(FContexto.RegistroLog) then
            FContexto.RegistroLog.RegistrarError(
              'Cola Verifactu: ' + E.Message);
          FContexto.Estado.Publicar(acIncidencia, E.Message);
          // Si la conexión propia quedó inservible se recrea al
          // siguiente ciclo
          FreeAndNil(FConn);
        end;
      end;
    end;
  end;
end;
procedure THiloVerifactuCola.EsperarCiclo;
var
  iSegundos: Integer;
begin
  iSegundos := FContexto.ParametrosApp.GetInt('appVerifactuSegundosCiclo', 60);
  if iSegundos < 5 then
    iSegundos := 5;
  // FZ-ISSUE-310: «Enviar ya» de la pantalla de la cola corta la espera
  EsperarSegundos(iSegundos, True);
end;
// Sin SISTEMA_VFCOLA todas las filas son de VERI*FACTU
function THiloVerifactuCola.ColumnaSistema: string;
begin
  if FColaConSistema then
    Result := fsistemavfcola
  else
    Result := '''' + cSistemaColaVerifactu + ''' AS ' + fsistemavfcola;
end;

function THiloVerifactuCola.PuedeContinuar: Boolean;
begin
  Result := not Terminated;
  if Result then
    Result := not FContexto.ContextoSesion.CerrandoAplicacion;
end;
procedure THiloVerifactuCola.EsperarSegundos(ASegundos: Integer;
  AAtenderSenal: Boolean);
var
  iPasos: Integer;
  iPaso:  Integer;
begin
  // Tope de cordura y espera troceada en pasos de 100 ms para
  // reaccionar rápido a la parada del hilo
  if ASegundos > 300 then
    ASegundos := 300;
  iPasos := ASegundos * 10;
  iPaso  := 0;
  // La espera del control de flujo de la AEAT entre envíos no atiende
  // la señal: solo la del ciclo
  while (iPaso < iPasos) and PuedeContinuar do
  begin
    if AAtenderSenal then
    begin
      if EsperarProcesadoCola(ccsVerifactu, 100) = wrSignaled then
        Break;
    end
    else
      Sleep(100);
    Inc(iPaso);
  end;
end;
procedure THiloVerifactuCola.ProcesarPendientes;
var
  oTurno: ITurnoCola;
  iHorasIncidencias: Integer;
begin
  if FConn = nil then
    FConn := FContexto.Conexiones.CrearConexion(
      nil,
      uctSegundoPlano);
  if not EnvioVerifactuDisponible then
  begin
    // Cliente de envío desactivado: la cola se acumula en PENDIENTE.
    // Se deja constancia una sola vez por sesión.
    if not FAvisoNoDisponible then
    begin
      RegistrarEventoVerifactu(
        FContexto.ParametrosApp, FConn, FContexto.Usuario,
        cEventoVerifactuInfo,
        'Cola Verifactu activa sin cliente de envío AEAT disponible: ' +
        'las facturas quedan en estado PENDIENTE');
      FContexto.Estado.Publicar(acIncidencia,
        SColaHaciendaNoDisponible);
      FAvisoNoDisponible := True;
    end;
  end
  else
  begin
    // Un solo puesto vacía la cola en cada ciclo. El encadenamiento ya
    // serializa los envíos con el FOR UPDATE de fza_verifactu_cadena, así
    // que tener a los demás esperando ese bloqueo mientras uno habla con la
    // AEAT no adelanta ningún envío y sí agota esperas de bloqueo. Quien no
    // consigue el turno se salta el ciclo; el trabajo sigue ahí.
    oTurno := CrearTurnoColaUniDAC(
      FConn, 'vfcola', FContexto.RegistroLog);
    if oTurno.Intentar then
    try
      VaciarCola;
    finally
      oTurno.Liberar;
    end;
    FAvisoNoDisponible := False;
    if PuedeContinuar then
    begin
      iHorasIncidencias := HorasIncidenciasColas(FContexto.ParametrosApp);
      FContexto.Estado.FinalizarCiclo(
        LeerIncidenciaCola(FConn, tceHacienda, iHorasIncidencias),
        iHorasIncidencias);
    end;
  end;
end;

procedure THiloVerifactuCola.VaciarCola;
var
  Qry: TUniQuery;
begin
  FColaConSistema := ColaVerifactuTieneSistema(FConn);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    // Rescate de filas PROCESANDO huérfanas (cierre brusco de la app)
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
      '     INSTANTE_MODIF = NOW() ' +
      ' WHERE ESTADO_VFCOLA = ''PROCESANDO'' ' +
      '   AND INSTANTE_MODIF < DATE_SUB(NOW(), INTERVAL 10 MINUTE)';
    Qry.Execute;
    // Reproceso: filas en ERROR con menos intentos que el máximo
    // vigente vuelven a la cola (p.ej. tras corregir configuración,
    // resetear intentos a mano o subir appVerifactuMaxIntentos)
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
      '     INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
      '     INSTANTE_MODIF = NOW() ' +
      ' WHERE ESTADO_VFCOLA = ''ERROR'' ' +
      '   AND CONTADOR_INTENTOS_VFCOLA < :MAXINTENTOS';
    Qry.ParamByName('MAXINTENTOS').AsInteger :=
      FContexto.ParametrosApp.GetInt('appVerifactuMaxIntentos', 10);
    Qry.Execute;
    // Registro en vuelo: salió hacia la AEAT sin respuesta definitiva y
    // pudo quedar registrado. Hasta resolverlo no se envía ninguna otra
    // fila: la siguiente se encadenaría a una huella que quizá no es la
    // última registrada, o adelantaría a una factura anterior. Bloquea la
    // cola entera aunque haya varios emisores: prima el orden.
    Qry.SQL.Text :=
      ' SELECT ID_VFCOLA, SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, ' +
      '        TIPO_OPERACION_VFCOLA, CONTADOR_INTENTOS_VFCOLA, ' +
      '        ESTADO_VFCOLA, ' + ColumnaSistema + ', ' +
      '        CASE WHEN INSTANTE_PROXIMO_INTENTO_VFCOLA IS NULL ' +
      '               OR INSTANTE_PROXIMO_INTENTO_VFCOLA <= NOW() ' +
      '             THEN ''S'' ELSE ''N'' END AS ESVENCIDA ' +
      ' FROM fza_verifactu_cola ' +
      ' WHERE ESTADO_VFCOLA IN (''PENDIENTE'', ''PROCESANDO'') ' +
      '   AND FECHA_HORA_GEN_VFCOLA IS NOT NULL ' +
      ' ORDER BY ID_VFCOLA ' +
      ' LIMIT 1';
    Qry.Open;
    if Qry.IsEmpty then
      ProcesarPendientesOrdenados(Qry)
    else
      ProcesarRegistroEnVuelo(Qry);
  finally
    FreeAndNil(Qry);
  end;
end;

procedure THiloVerifactuCola.ProcesarRegistroEnVuelo(AQry: TUniQuery);
begin
  // PROCESANDO: otro puesto lo está enviando, o quedó huérfano y lo
  // rescatará el reproceso de filas caducadas. Fuera de plazo: espera de
  // reintento. En ambos casos el ciclo termina sin tocar otras filas.
  if (AQry.FieldByName('ESTADO_VFCOLA').AsString = 'PENDIENTE') and
     (AQry.FieldByName('ESVENCIDA').AsString = 'S') and
     PuedeContinuar then
    ProcesarFila(AQry.FieldByName(fidvfcola).AsLargeInt,
                 AQry.FieldByName(fsistemavfcola).AsString,
                 AQry.FieldByName(fserievfcola).AsString,
                 AQry.FieldByName(fnumerovfcola).AsString,
                 AQry.FieldByName(ftipoopvfcola).AsString,
                 AQry.FieldByName(fintentosvfcola).AsInteger);
end;

procedure THiloVerifactuCola.ProcesarPendientesOrdenados(AQry: TUniQuery);
var
  iEspera: Integer;
  bSeguir: Boolean;
begin
  AQry.Close;
  AQry.SQL.Text :=
    ' SELECT ID_VFCOLA, SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, ' +
    '        TIPO_OPERACION_VFCOLA, CONTADOR_INTENTOS_VFCOLA, ' +
    '        ' + ColumnaSistema +
    ' FROM fza_verifactu_cola ' +
    ' WHERE ESTADO_VFCOLA = ''PENDIENTE'' ' +
    '   AND (INSTANTE_PROXIMO_INTENTO_VFCOLA IS NULL ' +
    '        OR INSTANTE_PROXIMO_INTENTO_VFCOLA <= NOW()) ' +
    ' ORDER BY ID_VFCOLA ' +
    ' LIMIT 25';
  AQry.Open;
  bSeguir := True;
  while bSeguir and (not AQry.Eof) and PuedeContinuar do
  begin
    iEspera := ProcesarFila(AQry.FieldByName(fidvfcola).AsLargeInt,
                            AQry.FieldByName(fsistemavfcola).AsString,
                            AQry.FieldByName(fserievfcola).AsString,
                            AQry.FieldByName(fnumerovfcola).AsString,
                            AQry.FieldByName(ftipoopvfcola).AsString,
                            AQry.FieldByName(fintentosvfcola).AsInteger);
    // Un fallo de transporte, un bloqueo del encadenamiento o un
    // registro que queda en vuelo abren el circuito: el ciclo siguiente
    // empieza por esa fila y no se prueba ninguna otra.
    bSeguir := iEspera >= 0;
    if bSeguir then
    begin
      // Control de flujo de la AEAT entre envíos consecutivos
      if iEspera > 0 then
        EsperarSegundos(iEspera);
      AQry.Next;
    end;
  end;
end;

procedure THiloVerifactuCola.ConservarIntentoFallido(AIdCola: Int64;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
var
  oContexto: TContextoSubsanacionFiscal;
begin
  if ATipoOperacion = 'SUBSANACION' then
  begin
    oContexto.IdCola := AIdCola;
    oContexto.Serie := ASerie;
    oContexto.Numero := ANumero;
    oContexto.Usuario := FContexto.Usuario;
    GuardarIntentoSubsanacion(FConn, oContexto, AResultado);
  end;
end;

function THiloVerifactuCola.ReclamarFila(AIdCola: Int64; ASii: Boolean;
  out AFechaHoraGen: string): Boolean;
var
  Qry: TUniQuery;
begin
  AFechaHoraGen := '';
  Qry := TUniQuery.Create(nil);
  try
    // Reclamo optimista: si otro puesto se adelantó, aquí no se procesa.
    // Fuera de transacción, antes del envío: el instante de generación
    // queda confirmado aunque la app muera durante la llamada a la AEAT,
    // y todo reintento compone el mismo registro con la misma huella.
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''PROCESANDO'', ' +
      '     FECHA_HORA_GEN_VFCOLA = ' +
      '       COALESCE(FECHA_HORA_GEN_VFCOLA, :FECHAHORAGEN), ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID ' +
      '   AND ESTADO_VFCOLA = ''PENDIENTE''';
    // En SII no hay huella que reproducir: sin instante de generación la
    // fila nunca queda en vuelo y el reenvío lo resuelve el duplicado
    if ASii then
    begin
      Qry.ParamByName('FECHAHORAGEN').DataType := ftString;
      Qry.ParamByName('FECHAHORAGEN').Clear;
    end
    else
      Qry.ParamByName('FECHAHORAGEN').AsString :=
        NuevaFechaHoraGenRegistro;
    Qry.ParamByName('USUARIO').AsString := FContexto.Usuario;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
    Result := Qry.RowsAffected = 1;
    if Result then
    begin
      Qry.SQL.Text :=
        ' SELECT FECHA_HORA_GEN_VFCOLA ' +
        ' FROM fza_verifactu_cola ' +
        ' WHERE ID_VFCOLA = :ID';
      Qry.ParamByName('ID').AsLargeInt := AIdCola;
      Qry.Open;
      AFechaHoraGen := Qry.Fields[0].AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure THiloVerifactuCola.LiberarRegistroEnVuelo(AIdCola: Int64);
var
  Qry: TUniQuery;
begin
  // La AEAT ha resuelto el envío (aceptado, duplicado o rechazado) o el
  // fallo fue previo a enviar: el próximo intento, si lo hay, compondrá
  // un registro nuevo sobre la cadena vigente
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET FECHA_HORA_GEN_VFCOLA = NULL ' +
      ' WHERE ID_VFCOLA = :ID';
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

function THiloVerifactuCola.ProcesarFila(AIdCola: Int64;
  const ASistema, ASerie, ANumero, ATipoOperacion: string;
  AIntentos: Integer): Integer;
var
  oResultado: TResultadoEnvioVerifactu;
  sFechaHoraGen: string;
  fCancelar: TConsultarCancelacionVerifactu;
  bSii: Boolean;
  bRechazoDefinitivo: Boolean;
begin
  Result := 0;
  bSii := SameText(ASistema, cSistemaColaSii);
  oResultado := Default(TResultadoEnvioVerifactu);
  fCancelar :=
    function: Boolean
    begin
      Result := not PuedeContinuar;
    end;
  if ReclamarFila(AIdCola, bSii, sFechaHoraGen) then
  begin
    FContexto.Estado.Publicar(acOcupada,
      Format(SColaEnviandoRegistro, [AIdCola]));
    // Transacción del envío: el FOR UPDATE de fza_verifactu_cadena que
    // toma EnviarRegistroFactura serializa el encadenamiento entre
    // puestos hasta el commit/rollback
    FConn.StartTransaction;
    try
      if bSii then
        EnviarRegistroSiiConResultado(FContexto.ParametrosApp, FConn,
          ASerie, ANumero, ATipoOperacion, oResultado, fCancelar)
      else
        EnviarRegistroFacturaConResultado(FContexto.ParametrosApp, FConn,
          FContexto.Usuario, ASerie, ANumero, ATipoOperacion, oResultado,
          sFechaHoraGen, fCancelar);
      if oResultado.Ok then
      begin
        // El registro YA está aceptado por la AEAT: si fallara la
        // persistencia local sigue en vuelo y el reintento reenvía el
        // mismo registro, que la AEAT contestará como duplicado con la
        // misma huella; ese duplicado conserva la consolidación
        try
          TResultadosVerifactuColaUniDAC.GuardarEnvioOk(
            FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
            FContexto.Usuario,
            AIdCola, ASerie, ANumero, ATipoOperacion, oResultado,
            FContexto.RegistroLog);
          LiberarRegistroEnVuelo(AIdCola);
          FConn.Commit;
          PublicarResultado(AIdCola, oResultado);
          Result := oResultado.EsperaSegundos;
        except
          on E: Exception do
          begin
            if FConn.InTransaction then
              FConn.Rollback;
            // FZ-ISSUE-319: la respuesta de la AEAT, entera, en el log
            if (oResultado.RespuestaCompleta <> '') and
               Assigned(FContexto.RegistroLog) then
              FContexto.RegistroLog.RegistrarAviso(Format(
                'Cola Verifactu: aceptado por la AEAT pero no se pudo ' +
                'guardar %s/%s (%s): %s. Respuesta: %s',
                [ASerie, ANumero, ASistema, E.Message,
                 oResultado.RespuestaCompleta]));
            oResultado.MensajeError := E.Message;
            ConservarIntentoFallido(AIdCola, ASerie, ANumero,
              ATipoOperacion, oResultado);
            // Gasta intento con la espera creciente de los reintentos: un
            // fallo local que se repite no puede reenviar al infinito
            // (FZ-ISSUE-319). Al agotarlos la fila queda en ERROR.
            TResultadosVerifactuColaUniDAC.GuardarEnvioError(
              FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
              FContexto.Usuario,
              AIdCola, ASerie, ANumero,
              'Aceptado por la AEAT pero falló la persistencia ' +
              'local: ' + E.Message, AIntentos, FContexto.RegistroLog);
            Result := CResultadoFilaSinConexion;
          end;
        end;
      end
      else
      begin
        // La AEAT ha contestado sin aceptarlo: no quedó registrado. Si lo
        // rechaza por sus datos (1xxx) reenviarlo daría lo mismo, así que
        // la fila pasa a ERROR sin agotar los reintentos
        FConn.Rollback;
        ConservarIntentoFallido(AIdCola, ASerie, ANumero,
          ATipoOperacion, oResultado);
        if bSii then
          bRechazoDefinitivo := EsRechazoDefinitivoSii(
            oResultado.EstadoRegistro, oResultado.CodigoError)
        else
          bRechazoDefinitivo := EsRechazoDefinitivoVerifactu(
            oResultado.EstadoRegistro, oResultado.CodigoError);
        TResultadosVerifactuColaUniDAC.GuardarEnvioError(
          FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
          FContexto.Usuario,
          AIdCola, ASerie, ANumero, oResultado.MensajeError, AIntentos,
          FContexto.RegistroLog, False, 0, bRechazoDefinitivo);
        LiberarRegistroEnVuelo(AIdCola);
      end;
    except
      on E: EConexionHttpTemporal do
      begin
        // Corte de red o respuesta ajena a la AEAT: el registro sigue en
        // vuelo y no se gasta intento
        if FConn.InTransaction then
          FConn.Rollback;
        // FZ-ISSUE-308: lo que ha llegado, entero, para el diagnóstico
        if (oResultado.RespuestaCompleta <> '') and
           Assigned(FContexto.RegistroLog) then
          FContexto.RegistroLog.RegistrarAviso(Format(
            'Cola Verifactu: respuesta no válida para %s/%s (%s): %s',
            [ASerie, ANumero, ASistema, oResultado.RespuestaCompleta]));
        oResultado.MensajeError := E.Message;
        ConservarIntentoFallido(AIdCola, ASerie, ANumero,
          ATipoOperacion, oResultado);
        TResultadosVerifactuColaUniDAC.GuardarEnvioError(
          FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
          FContexto.Usuario,
          AIdCola, ASerie, ANumero, E.Message, AIntentos,
          FContexto.RegistroLog, True,
          CSegundosReintentoSinConexion);
        Result := CResultadoFilaSinConexion;
      end;
      on E: EPeticionHttpCancelada do
      begin
        // Cierre de la aplicación durante la llamada: sigue en vuelo
        if FConn.InTransaction then
          FConn.Rollback;
        oResultado.MensajeError := E.Message;
        TResultadosVerifactuColaUniDAC.GuardarEnvioError(
          FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
          FContexto.Usuario,
          AIdCola, ASerie, ANumero, E.Message, AIntentos,
          FContexto.RegistroLog, True,
          CSegundosReintentoInterrumpido);
        Result := CResultadoFilaSinConexion;
      end;
      on E: EBloqueoBBDDTemporal do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        // Contención, no rechazo: la AEAT ni se ha enterado. La fila
        // vuelve a PENDIENTE sin gastar intento, que si no una racha de
        // esperas agotadas consumiría appVerifactuMaxIntentos y dejaría
        // la factura parada hasta reponer el contador a mano.
        oResultado.MensajeError := E.Message;
        ConservarIntentoFallido(AIdCola, ASerie, ANumero,
          ATipoOperacion, oResultado);
        TResultadosVerifactuColaUniDAC.GuardarEnvioError(
          FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
          FContexto.Usuario,
          AIdCola, ASerie, ANumero, E.Message, AIntentos,
          FContexto.RegistroLog, True,
          CSegundosReintentoBloqueo);
        Result := CResultadoFilaBloqueoBBDD;
      end;
      on E: Exception do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        oResultado.MensajeError := E.Message;
        ConservarIntentoFallido(AIdCola, ASerie, ANumero,
          ATipoOperacion, oResultado);
        if oResultado.PeticionEnviada then
        begin
          // Fallo local con la petición ya en la AEAT (p. ej. al tratar
          // la respuesta): pudo quedar registrado, así que sigue en vuelo
          // y no se gasta intento
          TResultadosVerifactuColaUniDAC.GuardarEnvioError(
            FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
            FContexto.Usuario,
            AIdCola, ASerie, ANumero, E.Message, AIntentos,
            FContexto.RegistroLog, True,
            CSegundosReintentoInterrumpido);
          Result := CResultadoFilaSinConexion;
        end
        else
        begin
          // Fallo antes de enviar (datos de la factura, configuración):
          // la AEAT no ha recibido nada
          TResultadosVerifactuColaUniDAC.GuardarEnvioError(
            FConn, FContexto.ParametrosApp, FContexto.ParametrosCaja,
            FContexto.Usuario,
            AIdCola, ASerie, ANumero, E.Message, AIntentos,
            FContexto.RegistroLog);
          LiberarRegistroEnVuelo(AIdCola);
        end;
      end;
    end;
    if (oResultado.MensajeError <> '') and
       (not SameText(oResultado.EstadoRegistro, 'Duplicado')) then
      FContexto.Estado.Publicar(acIncidencia,
        Format(SColaErrorRegistro, [AIdCola, oResultado.MensajeError]));
  end;
end;

procedure THiloVerifactuCola.PublicarResultado(AIdCola: Int64;
  const AResultado: TResultadoEnvioVerifactu);
var
  eActividad: TActividadCola;
begin
  eActividad := acCorrecta;
  if SameText(AResultado.EstadoRegistro, 'AceptadoConErrores') then
    eActividad := acIncidencia;
  FContexto.Estado.Publicar(eActividad,
    Format(SColaHaciendaAceptada, [AIdCola, AResultado.EstadoRegistro]));
end;
end.
