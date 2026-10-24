{******************************************************************************}
{                                                                              }
{  Módulo:       inLibProcesoGeneradorEnMarcha                                 }
{    Tipo:       Librería de aplicación                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Un script del generador corriendo por su cuenta: su hilo, su ventana y    }
{    su ejecutor. Se pueden tener varios a la vez; la pantalla los repasa de   }
{    vez en cuando para ver si les han dado a Cancelar o si ya han acabado.    }
{******************************************************************************}
unit inLibProcesoGeneradorEnMarcha;

interface

uses
  System.Classes,
  System.SyncObjs,
  inLibGeneradorProcesosAplicacion,
  inLibVentanaEspera;

type
  // Crea el ejecutor del proceso ya dentro de su hilo y deja en ARecursos
  // lo que haya que conservar mientras se vean sus resultados (la conexión
  // propia). Quien recoge el proceso decide qué hacer con ello.
  TFabricaEjecutorProceso = function(
    out ARecursos: TObject): IRepositorioGeneradorProcesos of object;
  // Pregunta si continuar tras el error de una sentencia, diciendo de qué
  // proceso viene. Se atiende siempre en el hilo principal.
  TPreguntaErrorProceso = function(
    ANumero: Integer;
    const AResultado: IResultadoSentenciaProceso;
    AIndice: Integer): Boolean of object;

  TProcesoGeneradorEnMarcha = class
  private
    FBloqueado: Boolean;
    FCancelacionAvisada: Boolean;
    FCancelacionPedida: Boolean;
    FError: string;
    FFabrica: TFabricaEjecutorProceso;
    FHilo: TThread;
    FNumero: Integer;
    FPreguntar: TPreguntaErrorProceso;
    FRecursos: TObject;
    FRepositorio: IRepositorioGeneradorProcesos;
    FResultado: TResultadoEjecucionProceso;
    FScript: string;
    FSeccion: TCriticalSection;
    FVentana: IVentanaEspera;
    procedure Trabajar;
    procedure AnotarRepositorio(
      const ARepositorio: IRepositorioGeneradorProcesos);
    function Confirmar(
      const AResultado: IResultadoSentenciaProceso;
      AIndice: Integer): Boolean;
    procedure Avisar(
      ANumero, ATotal: Integer;
      const ASentencia: string);
  public
    constructor Create(
      ANumero: Integer;
      const AScript: string;
      const AFabrica: TFabricaEjecutorProceso;
      const APreguntar: TPreguntaErrorProceso;
      const AVentana: IVentanaEspera);
    destructor Destroy; override;
    // Arranca el hilo. La ventana la muestra quien lo crea.
    procedure Lanzar;
    // Corta la sentencia en marcha y evita las siguientes.
    procedure PedirCancelacion;
    // Mira el botón Cancelar de su ventana. La llama la pantalla desde su
    // temporizador, en el hilo principal.
    procedure VigilarCancelacion;
    function Terminado: Boolean;
    // Entrega lo que hay que conservar con los resultados; a partir de
    // aquí el proceso ya no lo libera.
    function EntregarRecursos: TObject;
    property Numero: Integer read FNumero;
    property Script: string read FScript;
    property Bloqueado: Boolean read FBloqueado;
    property Error: string read FError;
    property Resultado: TResultadoEjecucionProceso read FResultado;
    property Ventana: IVentanaEspera read FVentana;
  end;

implementation

uses
  System.SysUtils,
  inLibProteccionDatosFacturacion;

resourcestring
  SDetalleSentenciaProceso = 'Sentencia %d de %d';

constructor TProcesoGeneradorEnMarcha.Create(
  ANumero: Integer;
  const AScript: string;
  const AFabrica: TFabricaEjecutorProceso;
  const APreguntar: TPreguntaErrorProceso;
  const AVentana: IVentanaEspera);
begin
  inherited Create;
  if not Assigned(AFabrica) then
    raise EArgumentNilException.Create('AFabrica');
  FNumero := ANumero;
  FScript := AScript;
  FFabrica := AFabrica;
  FPreguntar := APreguntar;
  FVentana := AVentana;
  FSeccion := TCriticalSection.Create;
end;

destructor TProcesoGeneradorEnMarcha.Destroy;
begin
  PedirCancelacion;
  if Assigned(FHilo) then
  begin
    FHilo.WaitFor;
    FreeAndNil(FHilo);
  end;
  FRepositorio := nil;
  FVentana := nil;
  // Si nadie los ha recogido, aquí se cierran.
  FreeAndNil(FRecursos);
  FreeAndNil(FSeccion);
  inherited Destroy;
end;

procedure TProcesoGeneradorEnMarcha.Lanzar;
begin
  FHilo := TThread.CreateAnonymousThread(
    procedure
    begin
      Trabajar;
    end);
  FHilo.FreeOnTerminate := False;
  FHilo.Start;
end;

// Todo esto ocurre en el hilo del proceso: la conexión se crea aquí, de
// modo que ni siquiera conectar detiene la pantalla.
procedure TProcesoGeneradorEnMarcha.Trabajar;
var
  oServicio: TServicioGeneradorProcesos;
begin
  try
    AnotarRepositorio(FFabrica(FRecursos));
    oServicio := TServicioGeneradorProcesos.Create(FRepositorio);
    try
      FResultado := oServicio.Ejecutar(FScript, Confirmar, Avisar);
    finally
      oServicio.Free;
    end;
  except
    on E: Exception do
    begin
      FBloqueado := E is EModificacionTablaFacturacionProtegida;
      FError := E.Message;
      if FError = '' then
        FError := E.ClassName;
    end;
  end;
end;

// El ejecutor aparece cuando el hilo ya está en marcha: si mientras tanto
// han dado a Cancelar, se le pide nada más nacer.
procedure TProcesoGeneradorEnMarcha.AnotarRepositorio(
  const ARepositorio: IRepositorioGeneradorProcesos);
begin
  FSeccion.Enter;
  try
    FRepositorio := ARepositorio;
    if FCancelacionPedida and Assigned(FRepositorio) then
      FRepositorio.PedirCancelacion;
  finally
    FSeccion.Leave;
  end;
end;

procedure TProcesoGeneradorEnMarcha.PedirCancelacion;
begin
  FSeccion.Enter;
  try
    FCancelacionPedida := True;
    if Assigned(FRepositorio) then
      FRepositorio.PedirCancelacion;
  finally
    FSeccion.Leave;
  end;
end;

procedure TProcesoGeneradorEnMarcha.VigilarCancelacion;
begin
  if Assigned(FVentana) and (not FCancelacionAvisada) and
     FVentana.Cancelado then
  begin
    FCancelacionAvisada := True;
    PedirCancelacion;
  end;
end;

function TProcesoGeneradorEnMarcha.Terminado: Boolean;
begin
  Result := Assigned(FHilo) and FHilo.Finished;
end;

function TProcesoGeneradorEnMarcha.EntregarRecursos: TObject;
begin
  Result := FRecursos;
  FRecursos := nil;
end;

// La pregunta viene del hilo del proceso y el diálogo se abre en el
// principal, que aquí no está esperando a nadie.
function TProcesoGeneradorEnMarcha.Confirmar(
  const AResultado: IResultadoSentenciaProceso;
  AIndice: Integer): Boolean;
var
  bContinuar: Boolean;
  oResultado: IResultadoSentenciaProceso;
begin
  bContinuar := False;
  oResultado := AResultado;
  if Assigned(FPreguntar) then
    TThread.Synchronize(nil,
      procedure
      begin
        bContinuar := FPreguntar(FNumero, oResultado, AIndice);
      end);
  Result := bContinuar;
end;

// También desde el hilo del proceso: la ventana vive en el suyo propio y
// estas llamadas solo le mandan un mensaje.
procedure TProcesoGeneradorEnMarcha.Avisar(
  ANumero, ATotal: Integer;
  const ASentencia: string);
begin
  if Assigned(FVentana) then
  begin
    if ATotal > 1 then
      FVentana.ActualizarDetalle(
        Format(SDetalleSentenciaProceso, [ANumero, ATotal]))
    else
      FVentana.ActualizarDetalle('');
    FVentana.MostrarTexto(ASentencia);
  end;
end;

end.
