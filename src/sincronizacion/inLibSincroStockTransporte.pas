{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroStockTransporte                                    }
{    Tipo:       Librería (simulación)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Red poco fiable para IServicioStock. Mismos fallos y mismo generador     }
{    que inLibSincroTransporteSimulado (sin conexión, petición perdida,        }
{    respuesta perdida, duplicado), aplicados a las cinco operaciones.         }
{******************************************************************************}
unit inLibSincroStockTransporte;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses
  {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF},
  inLibSincroProtocolo, inLibSincroStockProtocolo,
  inLibSincroTransporteSimulado;

type
  TTransporteStock = class(TInterfacedObject, IServicioStock)
  private
    FServidor: IServicioStock;
    FAleatorio: TAleatorio;
    FConfig: TConfigFallos;
    FConectado: Boolean;
    FFalloForzado: TFalloForzado;
    FLlamadasAntesDelFallo: Integer;
    FEstadisticas: TEstadisticasTransporte;
    procedure Antes(out ARespuestaPerdida, ADuplicar: Boolean);
    procedure Despues(ARespuestaPerdida: Boolean);
  public
    constructor Create(const AServidor: IServicioStock; ASemilla: UInt64);
    destructor Destroy; override;
    function EnviarEventos(const ATerminal: string;
      const AEventos: TEventosStock): TRespuestaEventos;
    function PedirNovedades(const ATerminal: string;
      ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedadesStock;
    procedure ConfirmarNovedades(const ATerminal: string;
      AHastaVersion: Int64);
    function Reservar(const ATerminal, AIdReserva, AArticulo,
      AAlmacen: string; ACantidad: Integer): TRespuestaReserva;
    function ConsultarStock(const AArticulo, AAlmacen: string): TConsultaStock;
    procedure ForzarFallo(AFallo: TFalloForzado; ALlamadasAntes: Integer = 0);
    property Config: TConfigFallos read FConfig write FConfig;
    property Conectado: Boolean read FConectado write FConectado;
    property Estadisticas: TEstadisticasTransporte read FEstadisticas;
  end;

implementation

constructor TTransporteStock.Create(const AServidor: IServicioStock;
  ASemilla: UInt64);
begin
  inherited Create;
  FServidor := AServidor;
  FAleatorio := TAleatorio.Create(ASemilla);
  FConfig := ConfigSinFallos;
  FConectado := True;
  FFalloForzado := ffNinguno;
end;

destructor TTransporteStock.Destroy;
begin
  FAleatorio.Free;
  inherited Destroy;
end;

procedure TTransporteStock.ForzarFallo(AFallo: TFalloForzado;
  ALlamadasAntes: Integer);
begin
  FFalloForzado := AFallo;
  FLlamadasAntesDelFallo := ALlamadasAntes;
end;

procedure TTransporteStock.Antes(out ARespuestaPerdida, ADuplicar: Boolean);
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
    raise ETransporteSincro.Create('sin conexion con la central');
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
end;

procedure TTransporteStock.Despues(ARespuestaPerdida: Boolean);
begin
  if ARespuestaPerdida then
  begin
    Inc(FEstadisticas.RespuestasPerdidas);
    raise ETransporteSincro.Create(
      'tiempo agotado: respuesta perdida (la central si proceso)');
  end;
end;

function TTransporteStock.EnviarEventos(const ATerminal: string;
  const AEventos: TEventosStock): TRespuestaEventos;
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  Result := FServidor.EnviarEventos(ATerminal, AEventos);
  if bDuplicar then
    Result := FServidor.EnviarEventos(ATerminal, AEventos);
  Despues(bPerdida);
end;

function TTransporteStock.PedirNovedades(const ATerminal: string;
  ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedadesStock;
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  Result := FServidor.PedirNovedades(ATerminal, ADesdeVersion, AMaximo);
  if bDuplicar then
    Result := FServidor.PedirNovedades(ATerminal, ADesdeVersion, AMaximo);
  Despues(bPerdida);
end;

procedure TTransporteStock.ConfirmarNovedades(const ATerminal: string;
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

function TTransporteStock.Reservar(const ATerminal, AIdReserva, AArticulo,
  AAlmacen: string; ACantidad: Integer): TRespuestaReserva;
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  Result := FServidor.Reservar(ATerminal, AIdReserva, AArticulo, AAlmacen,
    ACantidad);
  if bDuplicar then
    Result := FServidor.Reservar(ATerminal, AIdReserva, AArticulo, AAlmacen,
      ACantidad);
  Despues(bPerdida);
end;

function TTransporteStock.ConsultarStock(const AArticulo,
  AAlmacen: string): TConsultaStock;
var
  bPerdida, bDuplicar: Boolean;
begin
  Antes(bPerdida, bDuplicar);
  Result := FServidor.ConsultarStock(AArticulo, AAlmacen);
  Despues(bPerdida);
end;

end.
