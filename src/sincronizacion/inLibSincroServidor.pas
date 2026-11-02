{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroServidor                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servidor de sincronización en memoria. Reproduce las reglas que debe      }
{    cumplir la implementación real sobre MySQL (sql/esquema_sincro.sql):      }
{      - Ventas: idempotencia por IdEvento (INSERT IGNORE + ROW_COUNT).        }
{      - Novedades: registro de solo añadir con versión creciente.             }
{      - Cursores: versión confirmada por terminal, que solo avanza.           }
{******************************************************************************}
unit inLibSincroServidor;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Generics.Collections,
  {$ELSE}
  System.SysUtils, System.Generics.Collections,
  {$ENDIF}
  inLibSincroProtocolo;

type
  TEstadisticasServidor = record
    LotesRecibidos: Integer;
    VentasAceptadas: Integer;
    VentasRepetidas: Integer;
    VentasRechazadas: Integer;
    PeticionesNovedades: Integer;
    Confirmaciones: Integer;
  end;

  TServidorSincro = class(TInterfacedObject, IServicioSincro)
  private
    FVentas: TDictionary<string, TVentaSincro>;
    FSecuencias: TDictionary<string, string>; // Terminal|Secuencia -> IdEvento
    FNovedades: TList<TNovedadSincro>;
    FCatalogo: TDictionary<string, string>;
    FCursores: TDictionary<string, Int64>;
    FUltimaVersion: Int64;
    FEstadisticas: TEstadisticasServidor;
    function ValidarVenta(const ATerminal: string;
      const AVenta: TVentaSincro): string;
  public
    constructor Create;
    destructor Destroy; override;
    { IServicioSincro }
    function EnviarVentas(const ATerminal: string;
      const AVentas: TVentasSincro): TRespuestaVentas;
    function PedirNovedades(const ATerminal: string;
      ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedades;
    procedure ConfirmarNovedades(const ATerminal: string;
      AHastaVersion: Int64);
    { Backoffice y consultas }
    function PublicarNovedad(ATipo: TTipoNovedad;
      const AClave, AValor: string): Int64;
    function ExisteVenta(const AIdEvento: string;
      out AVenta: TVentaSincro): Boolean;
    function NumeroVentas: Integer;
    function CursorConfirmado(const ATerminal: string): Int64;
    function Catalogo: TDictionary<string, string>;
    property UltimaVersion: Int64 read FUltimaVersion;
    property Estadisticas: TEstadisticasServidor read FEstadisticas;
  end;

implementation

const
  CMaximoPagina = 500;

constructor TServidorSincro.Create;
begin
  inherited Create;
  FVentas := TDictionary<string, TVentaSincro>.Create;
  FSecuencias := TDictionary<string, string>.Create;
  FNovedades := TList<TNovedadSincro>.Create;
  FCatalogo := TDictionary<string, string>.Create;
  FCursores := TDictionary<string, Int64>.Create;
end;

destructor TServidorSincro.Destroy;
begin
  FCursores.Free;
  FCatalogo.Free;
  FNovedades.Free;
  FSecuencias.Free;
  FVentas.Free;
  inherited Destroy;
end;

function TServidorSincro.ValidarVenta(const ATerminal: string;
  const AVenta: TVentaSincro): string;
var
  sIdPrevio: string;
begin
  Result := '';
  if AVenta.IdEvento = '' then
    Result := 'id_evento obligatorio'
  else if not SameText(AVenta.Terminal, ATerminal) then
    Result := 'la venta pertenece a otro terminal'
  else if AVenta.Importe <= 0 then
    Result := 'importe no valido'
  else if FSecuencias.TryGetValue(
            ATerminal + '|' + IntToStr(AVenta.Secuencia), sIdPrevio) and
          (sIdPrevio <> AVenta.IdEvento) then
    Result := 'secuencia ya usada por otro evento';
end;

function TServidorSincro.EnviarVentas(const ATerminal: string;
  const AVentas: TVentasSincro): TRespuestaVentas;
var
  iIndice: Integer;
  oVenta: TVentaSincro;
  sMotivo: string;
begin
  // En MySQL todo el lote va en una transacción; el acuse solo se
  // devuelve tras el COMMIT. Si la respuesta se pierde, el reenvío
  // obtiene rvRepetida y el terminal la da igualmente por confirmada.
  Result := Default(TRespuestaVentas);
  Inc(FEstadisticas.LotesRecibidos);
  SetLength(Result.Acks, Length(AVentas));
  for iIndice := 0 to High(AVentas) do
  begin
    oVenta := AVentas[iIndice];
    Result.Acks[iIndice].IdEvento := oVenta.IdEvento;
    Result.Acks[iIndice].Motivo := '';
    if FVentas.ContainsKey(oVenta.IdEvento) then
    begin
      Result.Acks[iIndice].Resultado := rvRepetida;
      Inc(FEstadisticas.VentasRepetidas);
      Continue;
    end;
    sMotivo := ValidarVenta(ATerminal, oVenta);
    if sMotivo <> '' then
    begin
      Result.Acks[iIndice].Resultado := rvRechazada;
      Result.Acks[iIndice].Motivo := sMotivo;
      Inc(FEstadisticas.VentasRechazadas);
      Continue;
    end;
    FVentas.Add(oVenta.IdEvento, oVenta);
    FSecuencias.Add(
      ATerminal + '|' + IntToStr(oVenta.Secuencia), oVenta.IdEvento);
    Result.Acks[iIndice].Resultado := rvAceptada;
    Inc(FEstadisticas.VentasAceptadas);
  end;
end;

function TServidorSincro.PedirNovedades(const ATerminal: string;
  ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedades;
var
  iIndice: Integer;
  iCuenta: Integer;
begin
  Result := Default(TRespuestaNovedades);
  Inc(FEstadisticas.PeticionesNovedades);
  if (AMaximo <= 0) or (AMaximo > CMaximoPagina) then
    AMaximo := CMaximoPagina;
  SetLength(Result.Novedades, 0);
  Result.HayMas := False;
  Result.UltimaVersion := FUltimaVersion;
  iCuenta := 0;
  // Equivale a: SELECT ... WHERE VERSION > :desde ORDER BY VERSION LIMIT :max+1
  for iIndice := 0 to FNovedades.Count - 1 do
    if FNovedades[iIndice].Version > ADesdeVersion then
    begin
      if iCuenta = AMaximo then
      begin
        Result.HayMas := True;
        Break;
      end;
      SetLength(Result.Novedades, iCuenta + 1);
      Result.Novedades[iCuenta] := FNovedades[iIndice];
      Inc(iCuenta);
    end;
end;

procedure TServidorSincro.ConfirmarNovedades(const ATerminal: string;
  AHastaVersion: Int64);
var
  iActual: Int64;
begin
  // Solo avanza: UPDATE ... SET VERSION = GREATEST(VERSION, :hasta).
  // Un acuse viejo que llega tarde o duplicado no hace retroceder.
  Inc(FEstadisticas.Confirmaciones);
  if AHastaVersion > FUltimaVersion then
    AHastaVersion := FUltimaVersion;
  if not FCursores.TryGetValue(ATerminal, iActual) then
    iActual := 0;
  if AHastaVersion > iActual then
    FCursores.AddOrSetValue(ATerminal, AHastaVersion);
end;

function TServidorSincro.PublicarNovedad(ATipo: TTipoNovedad;
  const AClave, AValor: string): Int64;
var
  oNovedad: TNovedadSincro;
begin
  // La versión se asigna dentro de la transacción con el contador
  // bloqueado (SELECT ... FOR UPDATE). Con AUTO_INCREMENT a secas, una
  // transacción con id menor podría confirmarse después de otra con id
  // mayor y el terminal que ya hubiese leído la mayor se la saltaría.
  Inc(FUltimaVersion);
  oNovedad.Version := FUltimaVersion;
  oNovedad.Tipo := ATipo;
  oNovedad.Clave := AClave;
  oNovedad.Valor := AValor;
  FNovedades.Add(oNovedad);
  case ATipo of
    tnPrecio: FCatalogo.AddOrSetValue(AClave, AValor);
    tnBajaArticulo: FCatalogo.Remove(AClave);
  end;
  Result := FUltimaVersion;
end;

function TServidorSincro.ExisteVenta(const AIdEvento: string;
  out AVenta: TVentaSincro): Boolean;
begin
  Result := FVentas.TryGetValue(AIdEvento, AVenta);
end;

function TServidorSincro.NumeroVentas: Integer;
begin
  Result := FVentas.Count;
end;

function TServidorSincro.CursorConfirmado(const ATerminal: string): Int64;
begin
  if not FCursores.TryGetValue(ATerminal, Result) then
    Result := 0;
end;

function TServidorSincro.Catalogo: TDictionary<string, string>;
begin
  Result := FCatalogo;
end;

end.
