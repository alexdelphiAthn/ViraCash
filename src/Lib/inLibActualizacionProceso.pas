{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionProceso                                     }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta comprobar, instalar, aplicar y revertir una actualización.       }
{******************************************************************************}
unit inLibActualizacionProceso;

interface

uses
  Uni,
  inLibActualizacionEstado,
  inLibActualizacionIntf,
  inLibActualizacionScriptsLectura,
  inLibActualizacionScripts,
  inLibMotorBaseDatos,
  inLibVentanaEspera;

type
  // Qué se le pide al proceso: comprobar e instalar, aplicar lo que
  // quedó pendiente, o deshacer la última actualización.
  TModoPantallaActualizacion = (
    mpaComprobar,
    mpaAplicarPendientes,
    mpaRevertir);

  TDecisionScriptsActualizacion = (
    dsaAplazar,
    dsaAhora,
    // Generar con DBComparer un script contra el modelo de la versión y
    // aplicarlo; después, los scripts que sigan faltando.
    dsaComparacion);

  TContextoActualizacion = record
    Servicio: IServicioActualizaciones;
    Conexion: TUniConnection;
    VersionInstalada: string;
    RutaEjecutable: string;
    // Parámetro appMotorBaseDatos. Con otro que no sea MariaDB 12.13, los
    // scripts se convierten antes de aplicarlos y la comparación convierte
    // el modelo a ese motor.
    Motor: TMotorBaseDatos;
  end;

  TConfirmarInstalacionActualizacion = reference to function(
    const AManifiesto: TManifiestoActualizacion): Boolean;

  // AHayVersionNueva distingue las dos situaciones: acompañar a una
  // versión recién instalada, o poner al día la base sin cambiar el
  // programa (misma versión). Lo que se le advierte al usuario cambia.
  TDecidirScriptsActualizacion = reference to function(
    const AFaltantes: TArray<TScriptFaltante>;
    AHayVersionNueva: Boolean):
    TDecisionScriptsActualizacion;

  // La pantalla abre la ventana del proceso (la misma que el generador);
  // el dominio solo le va diciendo por dónde va. Puede no haberla: sin
  // ella los scripts se aplican igual, solo que sin nada que mirar.
  TCrearVentanaProcesoActualizacion = reference to function(
    const ATitulo: string): IVentanaEspera;

  // La ventana de espera que acompaña a la pantalla, en movimiento
  // mientras dura lo que no se sabe cuánto va a tardar: mirar qué le falta
  // a la base (minutos en una grande) y las descargas.
  TCrearVentanaEsperaActualizacion = reference to function: IVentanaEspera;

  // Como TDecidirScriptsActualizacion, pero con la comparación entre las
  // respuestas. Solo se pregunta así si la versión trae modelo.
  TDecidirModoActualizacion = reference to function(
    const AFaltantes: TArray<TScriptFaltante>;
    AHayVersionNueva: Boolean;
    const AVersion: string): TDecisionScriptsActualizacion;

  // Enseña el script que ha generado DBComparer y pregunta si se aplica.
  TConfirmarScriptComparacion = reference to function(
    const AVersion, ARutaScript, ASalida: string;
    AConAvisos: Boolean): Boolean;

  TSolicitarCopiaPreviaActualizacion = reference to function(
    out ARutaCopia: string): Boolean;

  TConfirmarReversionActualizacion = reference to function(
    const AEstado: TEstadoActualizacion): Boolean;

  // Devuelve True si el usuario prefiere restaurar la copia previa en
  // lugar de conformarse con los rollbacks disponibles.
  TConsultarRestaurarCopiaActualizacion = reference to function(
    const ASinRollback: TArray<string>;
    const ARutaCopia: string): Boolean;

  // Todo lo que el proceso necesita preguntarle al usuario. Lo rellena
  // la pantalla; el dominio no sabe nada de la VCL.
  TInteraccionActualizacion = record
    Progreso: TProgresoActualizacion;
    ConfirmarInstalacion: TConfirmarInstalacionActualizacion;
    DecidirScripts: TDecidirScriptsActualizacion;
    SolicitarCopiaPrevia: TSolicitarCopiaPreviaActualizacion;
    ConfirmarReversion: TConfirmarReversionActualizacion;
    ConsultarRestaurarCopia: TConsultarRestaurarCopiaActualizacion;
    // Opcionales: sin pantalla (las pruebas) no hay ventanas que abrir.
    CrearVentanaProceso: TCrearVentanaProcesoActualizacion;
    CrearVentanaEspera: TCrearVentanaEsperaActualizacion;
    // Opcionales: sin ellos no se ofrece la comparación y, si se pide, el
    // script generado se aplica sin enseñarlo.
    DecidirModo: TDecidirModoActualizacion;
    ConfirmarScriptComparacion: TConfirmarScriptComparacion;
    function Completa: Boolean;
  end;

  TResultadoActualizacion = record
    Ok: Boolean;
    Cancelado: Boolean;
    HayActualizacion: Boolean;
    RequiereSalir: Boolean;
    SolicitaRestaurarCopia: Boolean;
    RutaCopiaPrevia: string;
    Version: string;
    Mensaje: string;
  end;

function ComprobarEInstalarActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  AAlArrancar: Boolean = False): TResultadoActualizacion;
function AplicarScriptsPendientesActualizacion(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
function RevertirActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Threading,
  inLibActualizacionComparacion,
  inLibActualizacionInstalacion,
  inLibActualizacionPrecedencia,
  inLibActualizacionVersion,
  inLibMsgIntegraciones;

{ TInteraccionActualizacion }

function TInteraccionActualizacion.Completa: Boolean;
begin
  Result := Assigned(Progreso) and
    Assigned(ConfirmarInstalacion) and
    Assigned(DecidirScripts) and
    Assigned(SolicitarCopiaPrevia) and
    Assigned(ConfirmarReversion) and
    Assigned(ConsultarRestaurarCopia);
end;

function RutaDescarga(
  const AVersion, ANombre: string): string;
begin
  Result := TPath.Combine(
    CarpetaDescargasActualizacion(AVersion),
    ANombre);
end;

// Lo que tarda (mirar la base, descargar, aplicar un script) corre en su
// propio hilo: la ventana de espera se mueve, Windows no da el programa
// por colgado y se puede minimizar mientras tanto. No se despacha teclado
// ni ratón, así que nadie puede reentrar en la pantalla. ATrabajo tiene
// que quedarse con sus excepciones: aquí nadie las recoge.
procedure EsperarEnSuHilo(
  const ATrabajo: TProc;
  const AVigilar: TProc);
var
  Tarea: ITask;
begin
  Tarea := TTask.Run(ATrabajo);
  EsperarTareaAtendiendoMensajes(
    Tarea,
    procedure
    begin
      AtenderMinimizarYRestaurar;
      if Assigned(AVigilar) then
        AVigilar();
    end);
end;

// La ventana de espera de la pantalla. Puede no haberla (las pruebas): lo
// que tarda se hace igual, solo que sin nada que mirar.
function AbrirVentanaEspera(
  const AInteraccion: TInteraccionActualizacion;
  const AFase: string): IVentanaEspera;
begin
  Result := nil;
  if Assigned(AInteraccion.CrearVentanaEspera) then
    Result := AInteraccion.CrearVentanaEspera();
  if Assigned(Result) then
    Result.Mostrar(AFase);
end;

procedure CerrarVentanaEspera(var AVentana: IVentanaEspera);
begin
  if Assigned(AVentana) then
    AVentana.Ocultar;
  AVentana := nil;
end;

// El ejecutable son decenas de megas: con la descarga en el hilo principal
// la pantalla se quedaba como «No responde» lo que durase. La ventana de
// espera, si la hay, dice qué fichero se está bajando.
function DescargarEnSuHilo(
  const AContexto: TContextoActualizacion;
  const AVentana: IVentanaEspera;
  const AVersion, ATipo: string;
  const AEntrada: TEntradaActualizacion;
  const ARutaDestino: string;
  out AError: string): Boolean;
var
  bOk: Boolean;
  Entrada: TEntradaActualizacion;
  sError: string;
  Servicio: IServicioActualizaciones;
begin
  bOk := False;
  sError := '';
  Entrada := AEntrada;
  Servicio := AContexto.Servicio;
  if Assigned(AVentana) then
    AVentana.ActualizarDetalle(Entrada.Nombre);
  EsperarEnSuHilo(
    procedure
    begin
      try
        bOk := Servicio.DescargarEntrada(
          AVersion,
          ATipo,
          Entrada,
          ARutaDestino,
          sError);
      except
        on E: Exception do
        begin
          bOk := False;
          sError := E.Message;
        end;
      end;
    end,
    nil);
  AError := sError;
  Result := bOk;
end;

// Deja en otro fichero el script de ARuta convertido al motor y, si sale
// bien, ARuta pasa a ser ese fichero.
function ConvertirScriptEnSuHilo(
  const AVentana: IVentanaEspera;
  const AComparador: string;
  AMotor: TMotorBaseDatos;
  var ARuta: string;
  out AError: string): Boolean;
var
  Conversion: TResultadoComparacionActualizacion;
  sConvertido: string;
  sDestino: string;
  sOrigen: string;
begin
  sOrigen := ARuta;
  sConvertido := ChangeFileExt(sOrigen, '') + '.' +
    TextoMotorBaseDatos(AMotor) + '.sql';
  sDestino := DestinoComparadorMotor(AMotor);
  if Assigned(AVentana) then
    AVentana.ActualizarDetalle(ExtractFileName(sOrigen));
  EsperarEnSuHilo(
    procedure
    begin
      Conversion := ConvertirScriptActualizacion(
        AComparador,
        sOrigen,
        sConvertido,
        sDestino);
    end,
    nil);
  Result := Conversion.Ok;
  AError := Conversion.Error;
  if Result then
    ARuta := sConvertido;
end;

{ Los scripts publicados están escritos para MariaDB 12.13, como el modelo.
  Con otro motor se pasan por DBComparer --convertir recién bajados y lo
  pendiente apunta a la copia convertida, rollback incluido: lo que quede
  para otro día ya está en el dialecto de la base. }
function ConvertirScriptsAlMotor(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AVentana: IVentanaEspera;
  var AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  iIndice: Integer;
  sComparador: string;
begin
  AError := '';
  Result := AManifiesto.Comparador.Declarada;
  if not Result then
    AError := Format(
      SErrorConversionSinComparador,
      [DescripcionMotorBaseDatos(AContexto.Motor), AManifiesto.Version])
  else
  begin
    sComparador := RutaDescarga(
      AManifiesto.Version,
      AManifiesto.Comparador.Nombre);
    Result := DescargarEnSuHilo(
      AContexto,
      AVentana,
      AManifiesto.Version,
      cTipoActualizacionComparador,
      AManifiesto.Comparador,
      sComparador,
      AError);
    if Result and Assigned(AVentana) then
      AVentana.Mostrar(Format(
        SFaseConvirtiendoScriptsActualizacion,
        [DescripcionMotorBaseDatos(AContexto.Motor)]));
    for iIndice := Low(AEstado.Pendientes) to High(AEstado.Pendientes) do
    begin
      if Result then
        Result := ConvertirScriptEnSuHilo(
          AVentana,
          sComparador,
          AContexto.Motor,
          AEstado.Pendientes[iIndice].Ruta,
          AError);
      if Result and (AEstado.Pendientes[iIndice].RutaRollback <> '') then
        Result := ConvertirScriptEnSuHilo(
          AVentana,
          sComparador,
          AContexto.Motor,
          AEstado.Pendientes[iIndice].RutaRollback,
          AError);
    end;
  end;
end;

function DescargarScriptsFaltantes(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AFaltantes: TArray<TScriptFaltante>;
  const AVentana: IVentanaEspera;
  var AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  iIndice: Integer;
  iPendiente: Integer;
  Script: TScriptActualizacion;
begin
  Result := True;
  AError := '';
  AEstado.Pendientes := nil;
  if Assigned(AVentana) and (Length(AFaltantes) > 0) then
    AVentana.Mostrar(SFaseDescargandoScriptsActualizacion);
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
  begin
    if Result and AManifiesto.BuscarScript(AFaltantes[iIndice].Nombre,
         Script) then
    begin
      iPendiente := Length(AEstado.Pendientes);
      SetLength(AEstado.Pendientes, iPendiente + 1);
      AEstado.Pendientes[iPendiente].Nombre := Script.Entrada.Nombre;
      AEstado.Pendientes[iPendiente].Orden := AFaltantes[iIndice].Orden;
      AEstado.Pendientes[iPendiente].Ruta := RutaDescarga(
        AManifiesto.Version,
        Script.Entrada.Nombre);
      AEstado.Pendientes[iPendiente].RutaRollback := '';
      Result := DescargarEnSuHilo(
        AContexto,
        AVentana,
        AManifiesto.Version,
        cTipoActualizacionScript,
        Script.Entrada,
        AEstado.Pendientes[iPendiente].Ruta,
        AError);
      if Result and Script.Rollback.Declarada then
      begin
        AEstado.Pendientes[iPendiente].RutaRollback := RutaDescarga(
          AManifiesto.Version,
          Script.Rollback.Nombre);
        Result := DescargarEnSuHilo(
          AContexto,
          AVentana,
          AManifiesto.Version,
          cTipoActualizacionRollback,
          Script.Rollback,
          AEstado.Pendientes[iPendiente].RutaRollback,
          AError);
      end;
    end
    else if Result then
    begin
      Result := False;
      AError := Format(
        SErrorScriptFaltanteNoPublicado,
        [AFaltantes[iIndice].Nombre, AManifiesto.Version]);
    end;
  end;
  if Result and (Length(AEstado.Pendientes) > 0) and
     MotorRequiereConversion(AContexto.Motor) then
    Result := ConvertirScriptsAlMotor(
      AContexto,
      AManifiesto,
      AVentana,
      AEstado,
      AError);
end;

function DescargarEjecutables(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AVentana: IVentanaEspera;
  out ARutaEjecutable: string;
  out AError: string): Boolean;
var
  iIndice: Integer;
begin
  ARutaEjecutable := RutaDescarga(
    AManifiesto.Version,
    AManifiesto.Ejecutable.Nombre);
  Result := DescargarEnSuHilo(
    AContexto,
    AVentana,
    AManifiesto.Version,
    cTipoActualizacionEjecutable,
    AManifiesto.Ejecutable,
    ARutaEjecutable,
    AError);
  for iIndice := Low(AManifiesto.Auxiliares) to
                 High(AManifiesto.Auxiliares) do
  begin
    if Result then
      Result := DescargarEnSuHilo(
        AContexto,
        AVentana,
        AManifiesto.Version,
        cTipoActualizacionAuxiliar,
        AManifiesto.Auxiliares[iIndice],
        RutaDescarga(
          AManifiesto.Version,
          AManifiesto.Auxiliares[iIndice].Nombre),
        AError);
  end;
end;

function ComponerSustituciones(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const ARutaEjecutable: string): TArray<TSustitucionEjecutable>;
var
  iIndice: Integer;
begin
  SetLength(Result, Length(AManifiesto.Auxiliares) + 1);
  Result[0].Destino := AContexto.RutaEjecutable;
  Result[0].Origen := ARutaEjecutable;
  for iIndice := Low(AManifiesto.Auxiliares) to
                 High(AManifiesto.Auxiliares) do
  begin
    Result[iIndice + 1].Destino := TPath.Combine(
      ExtractFilePath(AContexto.RutaEjecutable),
      AManifiesto.Auxiliares[iIndice].Nombre);
    Result[iIndice + 1].Origen := RutaDescarga(
      AManifiesto.Version,
      AManifiesto.Auxiliares[iIndice].Nombre);
  end;
end;

{ El programa suele estar en Archivos de programa, donde no se puede
  escribir sin elevar: en ese caso la sustitución la hace una instancia
  del propio ViraCash lanzada con permisos de administrador. }
function SustituirEjecutables(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const ARutaEjecutable: string;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  out AError: string): Boolean;
var
  aAnteriores: TArray<string>;
  aHuellas: TArray<string>;
  aSustituciones: TArray<TSustitucionEjecutable>;
  iIndice: Integer;
begin
  aSustituciones := ComponerSustituciones(
    AContexto,
    AManifiesto,
    ARutaEjecutable);
  SetLength(aHuellas, Length(aSustituciones));
  aHuellas[0] := AManifiesto.Ejecutable.Sha256;
  for iIndice := Low(AManifiesto.Auxiliares) to
                 High(AManifiesto.Auxiliares) do
    aHuellas[iIndice + 1] := AManifiesto.Auxiliares[iIndice].Sha256;
  if CarpetaEscribible(ExtractFilePath(AContexto.RutaEjecutable)) then
    Result := AplicarSustituciones(aSustituciones, aAnteriores, AError)
  else
  begin
    AInteraccion.Progreso(SAvisoSustitucionNecesitaElevacion, -1);
    Result := AplicarSustitucionesElevado(
      aSustituciones,
      CarpetaActualizaciones,
      aAnteriores,
      AError);
  end;
  for iIndice := Low(aSustituciones) to High(aSustituciones) do
  begin
    if iIndice <= High(aAnteriores) then
      AEstado.AnadirEjecutable(
        aSustituciones[iIndice].Destino,
        aAnteriores[iIndice],
        aHuellas[iIndice]);
  end;
end;

// La ventana del proceso es la del generador: cronómetro propio, se
// puede apartar y enseña el script que se está ejecutando.
function AbrirVentanaScripts(
  const AInteraccion: TInteraccionActualizacion): IVentanaEspera;
begin
  Result := nil;
  if Assigned(AInteraccion.CrearVentanaProceso) then
    Result := AInteraccion.CrearVentanaProceso(
      STituloProcesoScriptsActualizacion);
  if Assigned(Result) then
  begin
    Result.Mostrar(SFaseAplicandoScriptsActualizacion);
    Result.PermitirCancelar(True);
  end;
end;

function TextoScriptEnMarcha(const ARuta: string): string;
begin
  try
    Result := TextoScriptParaVentana(LeerTextoScriptSql(ARuta));
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

// El script corre en su propio hilo para que la ventana se mueva y el
// programa atienda lo que ese hilo le pida (el monitor SQL escribe en el
// principal).
function EjecutarScriptEnSuHilo(
  AConexion: TUniConnection;
  const ARuta: string;
  out AError: string): Boolean;
var
  bOk: Boolean;
  sError: string;
begin
  bOk := False;
  sError := '';
  EsperarEnSuHilo(
    procedure
    begin
      bOk := EjecutarScriptActualizacion(AConexion, ARuta, '', sError);
    end,
    nil);
  AError := sError;
  Result := bOk;
end;

procedure AnunciarScriptEnMarcha(
  const AInteraccion: TInteraccionActualizacion;
  const AVentana: IVentanaEspera;
  const APendiente: TScriptPendienteActualizacion;
  AIndice, ATotal: Integer);
var
  sTexto: string;
begin
  sTexto := Format(
    SInfoAplicandoScriptActualizacion,
    [APendiente.Nombre, AIndice, ATotal]);
  AInteraccion.Progreso(sTexto, -1);
  if Assigned(AVentana) then
  begin
    AVentana.ActualizarDetalle(sTexto);
    AVentana.MostrarTexto(TextoScriptEnMarcha(APendiente.Ruta));
  end;
end;

procedure AnotarScriptAplicado(
  var AEstado: TEstadoActualizacion;
  AIndice: Integer;
  AOk: Boolean;
  const ADetalle: string;
  var AError: string);
begin
  if AOk then
    AEstado.AnadirAplicado(
      AEstado.Pendientes[AIndice].Nombre,
      AEstado.Pendientes[AIndice].Orden,
      cResultadoScriptActualizacionOk,
      '',
      AEstado.Pendientes[AIndice].RutaRollback)
  else
  begin
    AError := Format(
      SErrorAplicarScriptActualizacion,
      [AEstado.Pendientes[AIndice].Nombre, ADetalle]);
    AEstado.AnadirAplicado(
      AEstado.Pendientes[AIndice].Nombre,
      AEstado.Pendientes[AIndice].Orden,
      cResultadoScriptActualizacionError,
      ADetalle,
      AEstado.Pendientes[AIndice].RutaRollback);
  end;
end;

function AplicarPendientes(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  out ACancelado: Boolean;
  out AError: string): Boolean;
var
  aRestantes: TArray<TScriptPendienteActualizacion>;
  iIndice: Integer;
  iRestante: Integer;
  iTotal: Integer;
  sDetalle: string;
  Ventana: IVentanaEspera;
begin
  Result := True;
  ACancelado := False;
  AError := '';
  aRestantes := nil;
  iTotal := Length(AEstado.Pendientes);
  Ventana := AbrirVentanaScripts(AInteraccion);
  try
    for iIndice := Low(AEstado.Pendientes) to High(AEstado.Pendientes) do
    begin
      if Result and not ACancelado then
      begin
        // Cancelar no corta la sentencia en marcha: un cambio de esquema
        // a medias no se deshace. Lo que hace es no empezar el siguiente.
        ACancelado := Assigned(Ventana) and Ventana.Cancelado;
        if not ACancelado then
        begin
          AnunciarScriptEnMarcha(
            AInteraccion,
            Ventana,
            AEstado.Pendientes[iIndice],
            iIndice + 1,
            iTotal);
          Result := EjecutarScriptEnSuHilo(
            AConexion,
            AEstado.Pendientes[iIndice].Ruta,
            sDetalle);
          AnotarScriptAplicado(AEstado, iIndice, Result, sDetalle, AError);
        end;
      end;
      if not Result or ACancelado then
      begin
        // Lo que no ha llegado a aplicarse sigue pendiente.
        iRestante := Length(aRestantes);
        SetLength(aRestantes, iRestante + 1);
        aRestantes[iRestante] := AEstado.Pendientes[iIndice];
      end;
    end;
  finally
    if Assigned(Ventana) then
      Ventana.Ocultar;
    Ventana := nil;
  end;
  if Result and not ACancelado then
    AEstado.Pendientes := nil
  else
    AEstado.Pendientes := aRestantes;
end;

// Mensaje con el que se despide un intento de aplicar scripts que no
// llega a ejecutarlos todos.
function MensajeScriptsSinAplicar(
  ACancelado: Boolean;
  APendientes: Integer): string;
begin
  if ACancelado then
    Result := Format(SInfoScriptsActualizacionCancelados, [APendientes])
  else
    Result := Format(SInfoScriptsActualizacionAplazados, [APendientes]);
end;

{ Baja la comprobación de la versión publicada y mira en la base qué scripts
  faltan. La consulta recorre INFORMATION_SCHEMA entero: en una base grande
  y un equipo modesto son minutos, así que corre en su hilo, con la ventana
  de espera moviéndose, y se puede cancelar. }
function ConsultarFaltantes(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  const AVentana: IVentanaEspera;
  out ARutaComprobacion: string;
  out AFaltantes: TArray<TScriptFaltante>;
  out ACancelado: Boolean;
  out AError: string): Boolean;
var
  aLeidos: TArray<TScriptFaltante>;
  bOk: Boolean;
  Consulta: IConsultaScriptsFaltantes;
  sError: string;
  Ventana: IVentanaEspera;
begin
  AFaltantes := nil;
  ACancelado := False;
  Ventana := AVentana;
  ARutaComprobacion := RutaDescarga(
    AManifiesto.Version,
    AManifiesto.Comprobacion.Nombre);
  Result := DescargarEnSuHilo(
    AContexto,
    Ventana,
    AManifiesto.Version,
    cTipoActualizacionComprobacion,
    AManifiesto.Comprobacion,
    ARutaComprobacion,
    AError);
  if Result then
  begin
    AInteraccion.Progreso(SInfoComprobandoScriptsAplicados, -1);
    if Assigned(Ventana) then
    begin
      Ventana.Mostrar(SInfoComprobandoScriptsAplicados);
      Ventana.PermitirCancelar(True);
    end;
    Consulta := CrearConsultaScriptsFaltantes(
      AContexto.Conexion,
      LeerTextoScriptSql(ARutaComprobacion));
    bOk := False;
    sError := '';
    EsperarEnSuHilo(
      procedure
      begin
        bOk := Consulta.Ejecutar(aLeidos, sError);
      end,
      procedure
      begin
        if Assigned(Ventana) and Ventana.Cancelado then
          Consulta.Cancelar;
      end);
    if Assigned(Ventana) then
      Ventana.PermitirCancelar(False);
    ACancelado := Consulta.Cancelada;
    // Lo que declara cada script en «-- @requiere:» manda sobre el
    // orden_aplicacion de la comprobación.
    AFaltantes := OrdenarScriptsPorPrecedencia(aLeidos, AManifiesto);
    AError := sError;
    Result := bOk and not ACancelado;
  end;
end;

// Las descargas y la comprobación no han llegado al final: o las ha
// cancelado el usuario, que no es un error, o algo ha fallado.
procedure AnotarPreparacionInterrumpida(
  ACancelado: Boolean;
  const AError: string;
  var AResultado: TResultadoActualizacion);
begin
  AResultado.Ok := ACancelado;
  AResultado.Cancelado := ACancelado;
  if ACancelado then
    AResultado.Mensaje := SInfoComprobacionScriptsCancelada
  else
    AResultado.Mensaje := AError;
end;

// Algún script de AFaltantes que no estuviera en AIntentados.
function HayScriptsNuevos(
  const AFaltantes, AIntentados: TArray<TScriptFaltante>): Boolean;
var
  bEsta: Boolean;
  iFaltante: Integer;
  iIntentado: Integer;
begin
  Result := False;
  for iFaltante := Low(AFaltantes) to High(AFaltantes) do
  begin
    bEsta := False;
    for iIntentado := Low(AIntentados) to High(AIntentados) do
      bEsta := bEsta or SameText(
        AFaltantes[iFaltante].Nombre,
        AIntentados[iIntentado].Nombre);
    Result := Result or not bEsta;
  end;
end;

{ Reaplicar un script antiguo puede reponer procedimientos que ya había
  cambiado otro posterior, que la comprobación daba por aplicado (570
  inventarios_retroactivos_pmp quitaba lo que pone 577 prestashop_cola).
  Tras la tanda se vuelve a mirar la base y se aplica lo que falte, en su
  orden, si entre ello hay algún script que no se acababa de intentar. Si
  solo falta lo ya intentado (un script que falla o que su comprobación no
  reconoce) no se insiste; como mucho, cRepasosScripts pasadas. }
procedure RepasarScriptsAplicados(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  const AIntentados: TArray<TScriptFaltante>;
  var AEstado: TEstadoActualizacion;
  var AOk: Boolean;
  var ACancelado: Boolean;
  var AError: string);
const
  cRepasosScripts = 3;
var
  aFaltantes: TArray<TScriptFaltante>;
  aUltimos: TArray<TScriptFaltante>;
  bAplicar: Boolean;
  bCancelado: Boolean;
  iRepaso: Integer;
  sError: string;
  sRutaComprobacion: string;
  Ventana: IVentanaEspera;
begin
  aUltimos := AIntentados;
  iRepaso := 0;
  bAplicar := True;
  while bAplicar and not ACancelado and (iRepaso < cRepasosScripts) do
  begin
    Inc(iRepaso);
    bAplicar := False;
    Ventana := AbrirVentanaEspera(
      AInteraccion,
      SInfoComprobandoScriptsAplicados);
    try
      // Si no se puede volver a mirar, queda lo que dijo la tanda.
      if ConsultarFaltantes(
           AContexto,
           AManifiesto,
           AInteraccion,
           Ventana,
           sRutaComprobacion,
           aFaltantes,
           bCancelado,
           sError) then
      begin
        if Length(aFaltantes) = 0 then
        begin
          AOk := True;
          AError := '';
          AEstado.Pendientes := nil;
        end
        else if HayScriptsNuevos(aFaltantes, aUltimos) then
        begin
          bAplicar := DescargarScriptsFaltantes(
            AContexto,
            AManifiesto,
            aFaltantes,
            Ventana,
            AEstado,
            sError);
          if not bAplicar then
          begin
            AOk := False;
            AError := sError;
          end;
        end;
      end;
    finally
      CerrarVentanaEspera(Ventana);
    end;
    if bAplicar then
    begin
      AOk := AplicarPendientes(
        AContexto.Conexion,
        AInteraccion,
        AEstado,
        ACancelado,
        AError);
      aUltimos := aFaltantes;
    end;
  end;
end;

// Por comparación solo si la versión trae modelo y la pantalla sabe
// ofrecerlo; si no, la pregunta de siempre.
function DecidirAplicacion(
  const AInteraccion: TInteraccionActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AFaltantes: TArray<TScriptFaltante>;
  AHayVersionNueva: Boolean): TDecisionScriptsActualizacion;
begin
  if AManifiesto.ComparacionDisponible and
     Assigned(AInteraccion.DecidirModo) then
    Result := AInteraccion.DecidirModo(
      AFaltantes,
      AHayVersionNueva,
      AManifiesto.Version)
  else
    Result := AInteraccion.DecidirScripts(AFaltantes, AHayVersionNueva);
end;

{ Baja el modelo y DBComparer de la versión y genera el script. Todo con
  la ventana de espera: la comparación carga el modelo en un esquema
  temporal del servidor y puede tardar. }
function PrepararScriptComparacion(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  out AComparacion: TResultadoComparacionActualizacion;
  out AError: string): Boolean;
var
  Comparacion: TResultadoComparacionActualizacion;
  Conexion: TUniConnection;
  sCarpeta: string;
  sComparador: string;
  sDestino: string;
  sModelo: string;
  sScript: string;
  Ventana: IVentanaEspera;
begin
  AComparacion := Default(TResultadoComparacionActualizacion);
  // El modelo (factuzam_original.sql) es de MariaDB 12.13: DBComparer lo
  // convierte a este motor antes de comparar.
  sDestino := DestinoComparadorMotor(AContexto.Motor);
  AError := '';
  Result := AManifiesto.ComparacionDisponible;
  if not Result then
    AError := Format(SErrorComparacionNoPublicada, [AManifiesto.Version])
  else
  begin
    // Cada base compara en su carpeta: con dos programas abiertos contra
    // bases distintas, uno borraba el script que el otro iba a aplicar.
    sCarpeta := CarpetaComparacionActualizacion(
      AContexto.Conexion,
      AManifiesto.Version);
    TDirectory.CreateDirectory(sCarpeta);
    sModelo := TPath.Combine(sCarpeta, AManifiesto.Modelo.Nombre);
    sComparador := TPath.Combine(sCarpeta, AManifiesto.Comparador.Nombre);
    sScript := TPath.Combine(
      sCarpeta,
      NombreScriptComparacion(AManifiesto.Version));
    Ventana := AbrirVentanaEspera(AInteraccion, SFaseDescargandoComparacion);
    try
      Result := DescargarEnSuHilo(AContexto, Ventana, AManifiesto.Version,
        cTipoActualizacionModelo, AManifiesto.Modelo, sModelo, AError);
      if Result then
        Result := DescargarEnSuHilo(AContexto, Ventana, AManifiesto.Version,
          cTipoActualizacionComparador, AManifiesto.Comparador, sComparador,
          AError);
      if Result then
      begin
        AInteraccion.Progreso(SFaseGenerandoComparacion, -1);
        if Assigned(Ventana) then
          Ventana.Mostrar(SFaseGenerandoComparacion);
        Conexion := AContexto.Conexion;
        EsperarEnSuHilo(
          procedure
          begin
            Comparacion := GenerarScriptComparacion(
              Conexion,
              sComparador,
              sModelo,
              sScript,
              sDestino);
          end,
          nil);
        AComparacion := Comparacion;
        Result := Comparacion.Ok;
        AError := Comparacion.Error;
      end;
    finally
      CerrarVentanaEspera(Ventana);
    end;
  end;
end;

{ Actualización por comparación: el script que genera DBComparer pone
  tablas, vistas y procedimientos al nivel del modelo; lo que la
  comprobación siga echando en falta (los scripts de datos) se aplica
  después por el camino de siempre. Mientras el script generado no se
  aplique, lo pendiente siguen siendo los scripts: un script de
  comparación no se guarda para otro día, se genera de nuevo. }
procedure AplicarPorComparacion(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  var AOk: Boolean;
  var ACancelado: Boolean;
  var AError: string);
var
  aScripts: TArray<TScriptPendienteActualizacion>;
  bAplicada: Boolean;
  Comparacion: TResultadoComparacionActualizacion;
  Pendiente: TScriptPendienteActualizacion;
begin
  ACancelado := False;
  bAplicada := False;
  aScripts := AEstado.Pendientes;
  AOk := PrepararScriptComparacion(
    AContexto,
    AManifiesto,
    AInteraccion,
    Comparacion,
    AError);
  if AOk and Assigned(AInteraccion.ConfirmarScriptComparacion) and
     not AInteraccion.ConfirmarScriptComparacion(
       AManifiesto.Version,
       Comparacion.RutaScript,
       Comparacion.Salida,
       Comparacion.ConAvisos) then
  begin
    ACancelado := True;
    AError := SInfoComparacionNoAplicada;
  end
  else if AOk then
  begin
    Pendiente := Default(TScriptPendienteActualizacion);
    Pendiente.Nombre := NombreScriptComparacion(AManifiesto.Version);
    Pendiente.Ruta := Comparacion.RutaScript;
    AEstado.Pendientes := [Pendiente];
    AOk := AplicarPendientes(
      AContexto.Conexion,
      AInteraccion,
      AEstado,
      ACancelado,
      AError);
    bAplicada := AOk and not ACancelado;
    if bAplicada then
      RepasarScriptsAplicados(
        AContexto,
        AManifiesto,
        AInteraccion,
        nil,
        AEstado,
        AOk,
        ACancelado,
        AError);
  end;
  if not bAplicada then
    AEstado.Pendientes := aScripts;
end;

procedure AplicarFaltantesSinInstalacion(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  const AFaltantes: TArray<TScriptFaltante>;
  var AEstado: TEstadoActualizacion;
  var AResultado: TResultadoActualizacion);
var
  bCancelado: Boolean;
  Decision: TDecisionScriptsActualizacion;
  sError: string;
begin
  AResultado.Ok := True;
  bCancelado := False;
  Decision := DecidirAplicacion(AInteraccion, AManifiesto, AFaltantes, False);
  if Decision = dsaAplazar then
    AResultado.Mensaje := MensajeScriptsSinAplicar(
      False,
      Length(AEstado.Pendientes))
  else if not AInteraccion.SolicitarCopiaPrevia(AEstado.RutaCopiaPrevia) then
  begin
    AResultado.Cancelado := True;
    AResultado.Mensaje := MensajeScriptsSinAplicar(
      False,
      Length(AEstado.Pendientes));
  end
  else
  begin
    if Decision = dsaComparacion then
      AplicarPorComparacion(
        AContexto,
        AManifiesto,
        AInteraccion,
        AEstado,
        AResultado.Ok,
        bCancelado,
        sError)
    else
    begin
      AResultado.Ok := AplicarPendientes(
        AContexto.Conexion,
        AInteraccion,
        AEstado,
        bCancelado,
        sError);
      RepasarScriptsAplicados(
        AContexto,
        AManifiesto,
        AInteraccion,
        AFaltantes,
        AEstado,
        AResultado.Ok,
        bCancelado,
        sError);
    end;
    AResultado.Cancelado := bCancelado;
    AResultado.Mensaje := sError;
    // Sin ejecutable nuevo no hace falta salir del programa: lo que ha
    // cambiado es la base de datos.
    if AResultado.Ok and (AResultado.Mensaje = '') then
    begin
      if bCancelado then
        AResultado.Mensaje := MensajeScriptsSinAplicar(
          True,
          Length(AEstado.Pendientes))
      else
        AResultado.Mensaje := SInfoScriptsPendientesAplicados;
    end;
  end;
  if AEstado.HayScriptsPendientes then
    AEstado.Estado := cEstadoActualizacionPendiente
  else
    AEstado.Estado := cEstadoActualizacionCompletada;
  if not GuardarEstadoActualizacion(AEstado, sError) then
    AResultado.Mensaje := AResultado.Mensaje + sLineBreak + sError;
end;

{ No hay versión nueva que instalar, pero la base de datos puede seguir
  sin los cambios de esquema de la última publicada: se comprueban igual
  y se ofrecen, que es la forma de poner al día una instalación sin
  esperar a que salga otra versión. }
function ComprobarScriptsSinInstalacion(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  aFaltantes: TArray<TScriptFaltante>;
  bCancelado: Boolean;
  bDescargados: Boolean;
  Estado: TEstadoActualizacion;
  sError: string;
  sRutaComprobacion: string;
  Ventana: IVentanaEspera;
begin
  Result := Default(TResultadoActualizacion);
  Result.Version := AManifiesto.Version;
  if not AManifiesto.Comprobacion.Declarada then
  begin
    Result.Ok := True;
    Result.Mensaje := Format(
      SInfoVersionInstaladaAlDia,
      [AContexto.VersionInstalada]);
  end
  else
  begin
    TDirectory.CreateDirectory(
      CarpetaDescargasActualizacion(AManifiesto.Version));
    bDescargados := False;
    Ventana := AbrirVentanaEspera(
      AInteraccion,
      SInfoComprobandoScriptsAplicados);
    try
      if not ConsultarFaltantes(
               AContexto,
               AManifiesto,
               AInteraccion,
               Ventana,
               sRutaComprobacion,
               aFaltantes,
               bCancelado,
               sError) then
        AnotarPreparacionInterrumpida(bCancelado, sError, Result)
      else if Length(aFaltantes) = 0 then
      begin
        Result.Ok := True;
        Result.Mensaje := Format(
          SInfoVersionAlDiaSinScripts,
          [AContexto.VersionInstalada]);
      end
      else
      begin
        // El estado que hubiera se conserva: aquí no se sustituye ningún
        // ejecutable, así que no hay por qué perder con qué revertir.
        Estado := EstadoParaScriptsSinInstalacion(
          LeerEstadoActualizacion,
          AContexto.VersionInstalada,
          AManifiesto.Version,
          AManifiesto.Arquitectura);
        Estado.RutaComprobacion := sRutaComprobacion;
        if not Estado.CorrespondeABase(AContexto.Conexion.Server,
             AContexto.Conexion.Port, AContexto.Conexion.Database) then
        begin
          Estado.Aplicados := nil;
          Estado.RutaCopiaPrevia := '';
        end;
        Estado.ServidorBase := AContexto.Conexion.Server;
        Estado.PuertoBase := AContexto.Conexion.Port;
        Estado.NombreBase := AContexto.Conexion.Database;
        Estado.Instante := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
        bDescargados := DescargarScriptsFaltantes(
          AContexto,
          AManifiesto,
          aFaltantes,
          Ventana,
          Estado,
          sError);
        if not bDescargados then
          Result.Mensaje := sError;
      end;
    finally
      // Antes de preguntar nada: la espera no puede quedarse encima de
      // un diálogo.
      CerrarVentanaEspera(Ventana);
    end;
    if bDescargados then
      AplicarFaltantesSinInstalacion(
        AContexto,
        AManifiesto,
        AInteraccion,
        aFaltantes,
        Estado,
        Result);
  end;
end;

// Todo lo que hay que tener en disco antes de tocar ningún ejecutable: la
// versión nueva, la lista de lo que le falta a la base y esos scripts. Es
// lo que tarda, y va entero con la ventana de espera a la vista.
function DescargarInstalacion(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  out ARutaEjecutable: string;
  out AFaltantes: TArray<TScriptFaltante>;
  out ACancelado: Boolean;
  out AError: string): Boolean;
var
  sRutaComprobacion: string;
  Ventana: IVentanaEspera;
begin
  AFaltantes := nil;
  ACancelado := False;
  Ventana := AbrirVentanaEspera(
    AInteraccion,
    SFaseDescargandoVersionActualizacion);
  try
    Result := DescargarEjecutables(
      AContexto,
      AManifiesto,
      Ventana,
      ARutaEjecutable,
      AError);
    if Result then
      Result := ConsultarFaltantes(
        AContexto,
        AManifiesto,
        AInteraccion,
        Ventana,
        sRutaComprobacion,
        AFaltantes,
        ACancelado,
        AError);
    if Result then
    begin
      AEstado.RutaComprobacion := sRutaComprobacion;
      Result := DescargarScriptsFaltantes(
        AContexto,
        AManifiesto,
        AFaltantes,
        Ventana,
        AEstado,
        AError);
    end;
  finally
    // Lo siguiente puede pedir permisos de administrador o preguntar: la
    // espera no puede quedarse encima.
    CerrarVentanaEspera(Ventana);
  end;
end;

function InstalarVersionPublicada(
  const AContexto: TContextoActualizacion;
  const AManifiesto: TManifiestoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  AAlArrancar: Boolean): TResultadoActualizacion;
var
  aFaltantes: TArray<TScriptFaltante>;
  bCancelado: Boolean;
  Decision: TDecisionScriptsActualizacion;
  Estado: TEstadoActualizacion;
  sError: string;
  sRutaEjecutable: string;
begin
  Result := Default(TResultadoActualizacion);
  Result.Version := AManifiesto.Version;
  if not AManifiesto.Ejecutable.Declarada then
    Result.Mensaje := SErrorEntradaActualizacionNoDeclarada
  else
  begin
    Result.HayActualizacion := True;
    if not AInteraccion.ConfirmarInstalacion(AManifiesto) then
    begin
      Result.Ok := True;
      Result.Cancelado := True;
    end
    else
    begin
      Estado := Default(TEstadoActualizacion);
      Estado.VersionOrigen := AContexto.VersionInstalada;
      Estado.VersionDestino := AManifiesto.Version;
      Estado.Arquitectura := AManifiesto.Arquitectura;
      Estado.ServidorBase := AContexto.Conexion.Server;
      Estado.PuertoBase := AContexto.Conexion.Port;
      Estado.NombreBase := AContexto.Conexion.Database;
      Estado.Instante := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
      TDirectory.CreateDirectory(
        CarpetaDescargasActualizacion(AManifiesto.Version));
      // Primero se descarga y se mira qué falta en la base: mientras no
      // esté todo en su sitio no se toca ningún ejecutable.
      if not DescargarInstalacion(
               AContexto,
               AManifiesto,
               AInteraccion,
               Estado,
               sRutaEjecutable,
               aFaltantes,
               bCancelado,
               sError) then
        AnotarPreparacionInterrumpida(bCancelado, sError, Result)
      else if not SustituirEjecutables(
                    AContexto,
                    AManifiesto,
                    sRutaEjecutable,
                    AInteraccion,
                    Estado,
                    sError) then
        Result.Mensaje := sError
      else
      begin
        Result.Ok := True;
        // Desde el login se termina con el binario instalado. Los scripts
        // pendientes se ofrecen al abrir la versión nueva.
        Result.RequiereSalir := AAlArrancar;
        Estado.Estado := cEstadoActualizacionCompletada;
        if Estado.HayScriptsPendientes then
        begin
          Decision := dsaAplazar;
          if not AAlArrancar then
            Decision := DecidirAplicacion(
              AInteraccion, AManifiesto, aFaltantes, True);
          if (Decision <> dsaAplazar) and
             AInteraccion.SolicitarCopiaPrevia(
               Estado.RutaCopiaPrevia) then
          begin
            if Decision = dsaComparacion then
              AplicarPorComparacion(
                AContexto,
                AManifiesto,
                AInteraccion,
                Estado,
                Result.Ok,
                bCancelado,
                sError)
            else
            begin
              Result.Ok := AplicarPendientes(
                AContexto.Conexion,
                AInteraccion,
                Estado,
                bCancelado,
                sError);
              RepasarScriptsAplicados(
                AContexto,
                AManifiesto,
                AInteraccion,
                aFaltantes,
                Estado,
                Result.Ok,
                bCancelado,
                sError);
            end;
            Result.Cancelado := bCancelado;
            Result.Mensaje := sError;
            Result.RequiereSalir := True;
          end;
          if Estado.HayScriptsPendientes then
            Estado.Estado := cEstadoActualizacionPendiente;
        end;
        if Result.Mensaje = '' then
          Result.Mensaje := Format(
            SInfoActualizacionInstalada,
            [AManifiesto.Version]);
        if not GuardarEstadoActualizacion(Estado, sError) then
          Result.Mensaje := Result.Mensaje + sLineBreak + sError;
      end;
    end;
  end;
end;

function ComprobarEInstalarActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion;
  AAlArrancar: Boolean): TResultadoActualizacion;
var
  Manifiesto: TManifiestoActualizacion;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Manifiesto := AContexto.Servicio.ConsultarUltima(
    AContexto.VersionInstalada);
  Result.Version := Manifiesto.Version;
  if not Manifiesto.Ok then
    Result.Mensaje := Manifiesto.Mensaje
  else
    case CaminoComprobacionActualizacion(
           Manifiesto.HayVersion,
           Manifiesto.Version,
           AContexto.VersionInstalada) of
      ccaSinVersiones:
        begin
          Result.Ok := True;
          Result.Mensaje := SInfoSinVersionesPublicadas;
        end;
      ccaSoloScripts:
        Result := ComprobarScriptsSinInstalacion(
          AContexto,
          Manifiesto,
          AInteraccion);
      ccaInstalarVersion:
        Result := InstalarVersionPublicada(
          AContexto,
          Manifiesto,
          AInteraccion, AAlArrancar);
    end;
end;

function AplicarScriptsPendientesActualizacion(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  bCancelado: Boolean;
  Estado: TEstadoActualizacion;
  sError: string;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Estado := LeerEstadoActualizacion;
  Result.Version := Estado.VersionDestino;
  if not Estado.Existe or not Estado.HayScriptsPendientes then
  begin
    Result.Ok := True;
    Result.Mensaje := SInfoSinScriptsPendientes;
  end
  else if not Estado.CorrespondeABase(AConexion.Server,
    AConexion.Port, AConexion.Database) then
    Result.Mensaje := SErrorPendientesOtraBase
  else if not AInteraccion.SolicitarCopiaPrevia(Estado.RutaCopiaPrevia) then
  begin
    Result.Ok := True;
    Result.Cancelado := True;
  end
  else
  begin
    Result.Ok := AplicarPendientes(
      AConexion,
      AInteraccion,
      Estado,
      bCancelado,
      sError);
    Result.Cancelado := bCancelado;
    Result.Mensaje := sError;
    // Solo hay que salir si estos scripts acompañan a un ejecutable
    // nuevo; los de una base que se pone al día no obligan a nada.
    Result.RequiereSalir := Length(Estado.Ejecutables) > 0;
    if Estado.HayScriptsPendientes then
    begin
      Estado.Estado := cEstadoActualizacionPendiente;
      if bCancelado and (Result.Mensaje = '') then
        Result.Mensaje := MensajeScriptsSinAplicar(
          True,
          Length(Estado.Pendientes));
    end
    else
    begin
      Estado.Estado := cEstadoActualizacionCompletada;
      if Result.Mensaje = '' then
        Result.Mensaje := SInfoScriptsPendientesAplicados;
    end;
    if not GuardarEstadoActualizacion(Estado, sError) then
      Result.Mensaje := Result.Mensaje + sLineBreak + sError;
  end;
end;

function RevertirScripts(
  AConexion: TUniConnection;
  const AInteraccion: TInteraccionActualizacion;
  var AEstado: TEstadoActualizacion;
  var AResultado: TResultadoActualizacion): Boolean;
var
  aSinRollback: TArray<string>;
  iIndice: Integer;
  iSin: Integer;
  sDetalle: string;
begin
  Result := True;
  aSinRollback := nil;
  for iIndice := High(AEstado.Aplicados) downto Low(AEstado.Aplicados) do
  begin
    if SameText(
         AEstado.Aplicados[iIndice].Resultado,
         cResultadoScriptActualizacionOk) then
    begin
      if (Trim(AEstado.Aplicados[iIndice].RutaRollback) = '') or
         not TFile.Exists(AEstado.Aplicados[iIndice].RutaRollback) then
      begin
        iSin := Length(aSinRollback);
        SetLength(aSinRollback, iSin + 1);
        aSinRollback[iSin] := AEstado.Aplicados[iIndice].Nombre;
      end
      else if Result then
      begin
        AInteraccion.Progreso(
          Format(
            SInfoRevirtiendoScriptActualizacion,
            [AEstado.Aplicados[iIndice].Nombre]),
          -1);
        Result := EjecutarScriptActualizacion(
          AConexion,
          AEstado.Aplicados[iIndice].RutaRollback,
          '',
          sDetalle);
        if not Result then
          AResultado.Mensaje := Format(
            SErrorRevertirScriptActualizacion,
            [AEstado.Aplicados[iIndice].Nombre, sDetalle]);
      end;
    end;
  end;
  if Result and (Length(aSinRollback) > 0) then
  begin
    AResultado.SolicitaRestaurarCopia := AInteraccion.ConsultarRestaurarCopia(
      aSinRollback,
      AEstado.RutaCopiaPrevia);
    AResultado.RutaCopiaPrevia := AEstado.RutaCopiaPrevia;
  end;
end;

function RevertirEjecutables(
  const AEstado: TEstadoActualizacion;
  var AResultado: TResultadoActualizacion): Boolean;
var
  iIndice: Integer;
  sDescartada: string;
  sError: string;
begin
  Result := True;
  for iIndice := High(AEstado.Ejecutables) downto
                 Low(AEstado.Ejecutables) do
  begin
    // Un auxiliar que antes no estaba instalado se retira sin mas.
    if (Trim(AEstado.Ejecutables[iIndice].RutaAnterior) = '') and
       TFile.Exists(AEstado.Ejecutables[iIndice].Ruta) then
      TFile.Delete(AEstado.Ejecutables[iIndice].Ruta);
    if not RestaurarEjecutableAnterior(
             AEstado.Ejecutables[iIndice].Ruta,
             AEstado.VersionDestino,
             sDescartada,
             sError) then
    begin
      Result := False;
      if AResultado.Mensaje <> '' then
        AResultado.Mensaje := AResultado.Mensaje + sLineBreak;
      AResultado.Mensaje := AResultado.Mensaje + sError;
    end;
  end;
end;

function RevertirActualizacion(
  const AContexto: TContextoActualizacion;
  const AInteraccion: TInteraccionActualizacion): TResultadoActualizacion;
var
  Estado: TEstadoActualizacion;
  sError: string;
begin
  Result := Default(TResultadoActualizacion);
  if not AInteraccion.Completa then
    raise EArgumentException.Create(SErrorInteraccionActualizacionIncompleta);
  Estado := LeerEstadoActualizacion;
  Result.Version := Estado.VersionDestino;
  if not Estado.SePuedeRevertir then
    Result.Mensaje := SErrorSinActualizacionRevertible
  else if Estado.HayScriptsAplicados and
    not Estado.CorrespondeABase(AContexto.Conexion.Server,
      AContexto.Conexion.Port, AContexto.Conexion.Database) then
    Result.Mensaje := SErrorPendientesOtraBase
  else if not AInteraccion.ConfirmarReversion(Estado) then
  begin
    Result.Ok := True;
    Result.Cancelado := True;
  end
  else
  begin
    Result.Ok := RevertirScripts(
      AContexto.Conexion,
      AInteraccion,
      Estado,
      Result);
    if Result.Ok then
    begin
      Result.Ok := RevertirEjecutables(Estado, Result);
      Result.RequiereSalir := True;
      Estado.Estado := cEstadoActualizacionRevertida;
      Estado.Pendientes := nil;
      if not GuardarEstadoActualizacion(Estado, sError) then
        Result.Mensaje := Result.Mensaje + sLineBreak + sError;
      if Result.Ok and (Result.Mensaje = '') then
        Result.Mensaje := Format(
          SInfoActualizacionRevertida,
          [Estado.VersionOrigen]);
    end;
  end;
end;
end.
