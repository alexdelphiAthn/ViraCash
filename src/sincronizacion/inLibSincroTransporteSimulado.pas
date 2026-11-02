{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroTransporteSimulado                                 }
{    Tipo:       Librería (simulación)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Red poco fiable entre un terminal y el servidor. Simula los cuatro        }
{    fallos que importan en un protocolo con acuses:                           }
{      - Sin conexión: la petición no sale.                                    }
{      - Petición perdida: el servidor no llega a enterarse.                   }
{      - Respuesta perdida: el servidor SÍ procesa, el terminal no lo sabe.   }
{      - Duplicado: la red entrega la misma petición dos veces.               }
{    El generador aleatorio es propio para que una semilla dé el mismo         }
{    resultado en Delphi y en Free Pascal.                                     }
{******************************************************************************}
unit inLibSincroTransporteSimulado;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}
{$Q-}{$R-} // el generador aleatorio desborda a propósito

interface

uses
  {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF},
  inLibSincroProtocolo;

type
  TAleatorio = class
  private
    FEstado: UInt64;
  public
    constructor Create(ASemilla: UInt64);
    function Siguiente: UInt64;
    function Real: Double;                  // [0, 1)
    function Entero(ALimite: Integer): Integer; // [0, ALimite)
    function Probable(AProbabilidad: Double): Boolean;
  end;

  TFalloForzado = (ffNinguno, ffPeticionPerdida, ffRespuestaPerdida,
    ffDuplicado);

  TConfigFallos = record
    PeticionPerdida: Double;
    RespuestaPerdida: Double;
    Duplicado: Double;
  end;

  TEstadisticasTransporte = record
    Llamadas: Integer;
    SinConexion: Integer;
    PeticionesPerdidas: Integer;
    RespuestasPerdidas: Integer;
    Duplicados: Integer;
  end;

  TTransporteSimulado = class(TInterfacedObject, IServicioSincro)
  private
    FServidor: IServicioSincro;
    FAleatorio: TAleatorio;
    FConfig: TConfigFallos;
    FConectado: Boolean;
    FFalloForzado: TFalloForzado;
    FLlamadasAntesDelFallo: Integer;
    FEstadisticas: TEstadisticasTransporte;
    // Decide qué le pasa a esta llamada. Devuelve True si la petición
    // llega al servidor; ARespuestaPerdida y ADuplicar indican el resto.
    function Antes(out ARespuestaPerdida, ADuplicar: Boolean): Boolean;
    procedure Despues(ARespuestaPerdida: Boolean);
  public
    constructor Create(const AServidor: IServicioSincro; ASemilla: UInt64);
    destructor Destroy; override;
    function EnviarVentas(const ATerminal: string;
      const AVentas: TVentasSincro): TRespuestaVentas;
    function PedirNovedades(const ATerminal: string;
      ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedades;
    procedure ConfirmarNovedades(const ATerminal: string;
      AHastaVersion: Int64);
    // Fuerza un fallo dejando pasar antes ALlamadasAntes llamadas
    // (pruebas deterministas).
    procedure ForzarFallo(AFallo: TFalloForzado; ALlamadasAntes: Integer = 0);
    property Config: TConfigFallos read FConfig write FConfig;
    property Conectado: Boolean read FConectado write FConectado;
    property Estadisticas: TEstadisticasTransporte read FEstadisticas;
  end;

function ConfigSinFallos: TConfigFallos;
function ConfigFallos(APeticion, ARespuesta, ADuplicado: Double):
  TConfigFallos;

implementation

function ConfigSinFallos: TConfigFallos;
begin
  Result := ConfigFallos(0, 0, 0);
end;

function ConfigFallos(APeticion, ARespuesta, ADuplicado: Double):
  TConfigFallos;
begin
  Result.PeticionPerdida := APeticion;
  Result.RespuestaPerdida := ARespuesta;
  Result.Duplicado := ADuplicado;
end;

{ TAleatorio: xorshift64* }

constructor TAleatorio.Create(ASemilla: UInt64);
begin
  inherited Create;
  if ASemilla = 0 then
    ASemilla := 88172645463325252;
  FEstado := ASemilla;
end;

function TAleatorio.Siguiente: UInt64;
begin
  FEstado := FEstado xor (FEstado shr 12);
  FEstado := FEstado xor (FEstado shl 25);
  FEstado := FEstado xor (FEstado shr 27);
  Result := FEstado * UInt64(2685821657736338717);
end;

function TAleatorio.Real: Double;
begin
  Result := (Siguiente shr 11) / 9007199254740992.0; // 2^53
end;

function TAleatorio.Entero(ALimite: Integer): Integer;
begin
  Result := Integer((Siguiente shr 33) mod UInt64(ALimite));
end;

function TAleatorio.Probable(AProbabilidad: Double): Boolean;
begin
  Result := Real < AProbabilidad;
end;

{ TTransporteSimulado }

constructor TTransporteSimulado.Create(const AServidor: IServicioSincro;
  ASemilla: UInt64);
begin
  inherited Create;
  FServidor := AServidor;
  FAleatorio := TAleatorio.Create(ASemilla);
  FConfig := ConfigSinFallos;
  FConectado := True;
  FFalloForzado := ffNinguno;
end;

destructor TTransporteSimulado.Destroy;
begin
  FAleatorio.Free;
  inherited Destroy;
end;

procedure TTransporteSimulado.ForzarFallo(AFallo: TFalloForzado;
  ALlamadasAntes: Integer);
begin
  FFalloForzado := AFallo;
  FLlamadasAntesDelFallo := ALlamadasAntes;
end;

function TTransporteSimulado.Antes(
  out ARespuestaPerdida, ADuplicar: Boolean): Boolean;
var
  eFallo: TFalloForzado;
begin
  Inc(FEstadisticas.Llamadas);
  eFallo := ffNinguno;
  if FFalloForzado <> ffNinguno then
  begin
    if FLlamadasAntesDelFallo > 0 then
      Dec(FLlamadasAntesDelFallo)
    else
    begin
      eFallo := FFalloForzado;
      FFalloForzado := ffNinguno;
    end;
  end;
  if not FConectado then
  begin
    Inc(FEstadisticas.SinConexion);
    raise ETransporteSincro.Create('sin conexion con el servidor');
  end;
  if (eFallo = ffPeticionPerdida) or
     ((eFallo = ffNinguno) and FAleatorio.Probable(FConfig.PeticionPerdida))
  then
  begin
    Inc(FEstadisticas.PeticionesPerdidas);
    raise ETransporteSincro.Create('tiempo agotado: peticion perdida');
  end;
  ADuplicar := (eFallo = ffDuplicado) or
    ((eFallo = ffNinguno) and FAleatorio.Probable(FConfig.Duplicado));
  ARespuestaPerdida := (eFallo = ffRespuestaPerdida) or
    ((eFallo = ffNinguno) and FAleatorio.Probable(FConfig.RespuestaPerdida));
  if ADuplicar then
    Inc(FEstadisticas.Duplicados);
  Result := True;
end;

procedure TTransporteSimulado.Despues(ARespuestaPerdida: Boolean);
begin
  if ARespuestaPerdida then
  begin
    Inc(FEstadisticas.RespuestasPerdidas);
    raise ETransporteSincro.Create(
      'tiempo agotado: respuesta perdida (el servidor si proceso)');
  end;
end;

function TTransporteSimulado.EnviarVentas(const ATerminal: string;
  const AVentas: TVentasSincro): TRespuestaVentas;
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  Result := FServidor.EnviarVentas(ATerminal, AVentas);
  if bDuplicar then
    Result := FServidor.EnviarVentas(ATerminal, AVentas);
  Despues(bPerdida);
end;

function TTransporteSimulado.PedirNovedades(const ATerminal: string;
  ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedades;
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  Result := FServidor.PedirNovedades(ATerminal, ADesdeVersion, AMaximo);
  if bDuplicar then
    Result := FServidor.PedirNovedades(ATerminal, ADesdeVersion, AMaximo);
  Despues(bPerdida);
end;

procedure TTransporteSimulado.ConfirmarNovedades(const ATerminal: string;
  AHastaVersion: Int64);
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  FServidor.ConfirmarNovedades(ATerminal, AHastaVersion);
  if bDuplicar then
    FServidor.ConfirmarNovedades(ATerminal, AHastaVersion);
  Despues(bPerdida);
end;

end.
