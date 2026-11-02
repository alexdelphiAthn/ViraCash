{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroCliente                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Terminal de sincronización tolerante a desconexiones.                     }
{                                                                              }
{    TAlmacenCliente es el estado persistente del terminal (en producción,     }
{    las tablas fza_sincro_salida y fza_sincro_cursor). Sobrevive a la         }
{    destrucción de TClienteSincro, lo que permite simular un reinicio.        }
{                                                                              }
{    Reglas:                                                                   }
{      1. La venta se graba en la bandeja de salida en la misma transacción   }
{         que la propia venta. Vender nunca depende de la red.                 }
{      2. Una venta solo sale de PENDIENTE con un acuse del servidor           }
{         (ACEPTADA o REPETIDA -> CONFIRMADA; RECHAZADA -> RECHAZADA).        }
{      3. Si falla la red, la venta sigue PENDIENTE y se reintenta con         }
{         espera exponencial. Reenviar es seguro: el IdEvento no cambia.      }
{      4. Una novedad se aplica y el cursor avanza en la misma transacción.    }
{         Las novedades con versión <= cursor se ignoran (duplicados).         }
{      5. La confirmación de novedades al servidor es informativa: si se      }
{         pierde, la siguiente la sustituye.                                   }
{******************************************************************************}
unit inLibSincroCliente;

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
  TEstadoSalida = (esPendiente, esConfirmada, esRechazada);

  TEntradaSalida = class
  public
    Venta: TVentaSincro;
    Estado: TEstadoSalida;
    Intentos: Integer;
    ProximoIntento: Int64;
    Motivo: string;
  end;

  TAlmacenCliente = class
  private
    FTerminal: string;
    FSalida: TObjectList<TEntradaSalida>;
    FIndice: TDictionary<string, TEntradaSalida>;
    FUltimaSecuencia: Int64;
    FCursor: Int64;
    FCatalogo: TDictionary<string, string>;
  public
    constructor Create(const ATerminal: string);
    destructor Destroy; override;
    function RegistrarVenta(const ASerie: string; ANumero: Integer;
      AImporte: Currency; AInstante: Int64): TVentaSincro;
    function Pendientes(AAhora: Int64; AMaximo: Integer): TVentasSincro;
    function NumeroPendientes: Integer;
    function Buscar(const AIdEvento: string): TEntradaSalida;
    procedure AplicarNovedad(const ANovedad: TNovedadSincro);
    property Terminal: string read FTerminal;
    property Salida: TObjectList<TEntradaSalida> read FSalida;
    property Cursor: Int64 read FCursor;
    property Catalogo: TDictionary<string, string> read FCatalogo;
  end;

  TEstadisticasCliente = record
    Ciclos: Integer;
    LotesEnviados: Integer;
    FallosEnvio: Integer;
    VentasConfirmadas: Integer;
    VentasRechazadas: Integer;
    AcusesRepetida: Integer;
    FallosNovedades: Integer;
    NovedadesAplicadas: Integer;
    NovedadesIgnoradas: Integer;
    FallosConfirmacion: Integer;
  end;

  TClienteSincro = class
  private
    FAlmacen: TAlmacenCliente;
    FServicio: IServicioSincro;
    FTamanoLote: Integer;
    FTamanoPagina: Integer;
    FEsperaMaxima: Integer;
    FUltimoError: string;
    FCursorConfirmado: Int64; // en memoria: tras reiniciar se reconfirma
    FEstadisticas: TEstadisticasCliente;
    function EsperaReintento(AIntentos: Integer): Int64;
    function SubirVentas(AAhora: Int64): Boolean;
    function BajarNovedades: Boolean;
  public
    constructor Create(AAlmacen: TAlmacenCliente;
      const AServicio: IServicioSincro);
    // Un ciclo completo: vacía la bandeja de salida (lo que permita la
    // red) y trae novedades. Devuelve False si hubo algún fallo de red.
    function Sincronizar(AAhora: Int64): Boolean;
    property TamanoLote: Integer read FTamanoLote write FTamanoLote;
    property TamanoPagina: Integer read FTamanoPagina write FTamanoPagina;
    property EsperaMaxima: Integer read FEsperaMaxima write FEsperaMaxima;
    property UltimoError: string read FUltimoError;
    property Estadisticas: TEstadisticasCliente read FEstadisticas;
  end;

function NuevoIdEvento: string;

implementation

function NuevoIdEvento: string;
var
  oGuid: TGUID;
begin
  CreateGUID(oGuid);
  Result := Copy(GUIDToString(oGuid), 2, 36);
end;

{ TAlmacenCliente }

constructor TAlmacenCliente.Create(const ATerminal: string);
begin
  inherited Create;
  FTerminal := ATerminal;
  FSalida := TObjectList<TEntradaSalida>.Create(True);
  FIndice := TDictionary<string, TEntradaSalida>.Create;
  FCatalogo := TDictionary<string, string>.Create;
end;

destructor TAlmacenCliente.Destroy;
begin
  FCatalogo.Free;
  FIndice.Free;
  FSalida.Free;
  inherited Destroy;
end;

function TAlmacenCliente.RegistrarVenta(const ASerie: string;
  ANumero: Integer; AImporte: Currency; AInstante: Int64): TVentaSincro;
var
  oEntrada: TEntradaSalida;
begin
  // Producción: INSERT en fza_sincro_salida dentro de la transacción
  // que graba la factura/ticket. Si la venta hace ROLLBACK, el evento
  // desaparece con ella; si hace COMMIT, el evento existe seguro.
  Inc(FUltimaSecuencia);
  Result.IdEvento := NuevoIdEvento;
  Result.Terminal := FTerminal;
  Result.Secuencia := FUltimaSecuencia;
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Importe := AImporte;
  Result.Instante := AInstante;
  oEntrada := TEntradaSalida.Create;
  oEntrada.Venta := Result;
  oEntrada.Estado := esPendiente;
  oEntrada.Intentos := 0;
  oEntrada.ProximoIntento := 0;
  FSalida.Add(oEntrada);
  FIndice.Add(Result.IdEvento, oEntrada);
end;

function TAlmacenCliente.Pendientes(AAhora: Int64;
  AMaximo: Integer): TVentasSincro;
var
  iIndice: Integer;
  iCuenta: Integer;
begin
  // SELECT ... WHERE ESTADO='PENDIENTE' AND PROXIMO_INTENTO <= NOW()
  //   ORDER BY SECUENCIA LIMIT :max
  SetLength(Result, 0);
  iCuenta := 0;
  for iIndice := 0 to FSalida.Count - 1 do
  begin
    if iCuenta >= AMaximo then
      Break;
    if (FSalida[iIndice].Estado = esPendiente) and
       (FSalida[iIndice].ProximoIntento <= AAhora) then
    begin
      SetLength(Result, iCuenta + 1);
      Result[iCuenta] := FSalida[iIndice].Venta;
      Inc(iCuenta);
    end;
  end;
end;

function TAlmacenCliente.NumeroPendientes: Integer;
var
  iIndice: Integer;
begin
  Result := 0;
  for iIndice := 0 to FSalida.Count - 1 do
    if FSalida[iIndice].Estado = esPendiente then
      Inc(Result);
end;

function TAlmacenCliente.Buscar(const AIdEvento: string): TEntradaSalida;
begin
  if not FIndice.TryGetValue(AIdEvento, Result) then
    Result := nil;
end;

procedure TAlmacenCliente.AplicarNovedad(const ANovedad: TNovedadSincro);
begin
  // Producción: START TRANSACTION; aplicar el cambio al artículo;
  // UPDATE fza_sincro_cursor SET ULTIMA_VERSION = :version; COMMIT.
  // Cambio y cursor son atómicos: nunca queda uno sin el otro.
  case ANovedad.Tipo of
    tnPrecio: FCatalogo.AddOrSetValue(ANovedad.Clave, ANovedad.Valor);
    tnBajaArticulo: FCatalogo.Remove(ANovedad.Clave);
  end;
  FCursor := ANovedad.Version;
end;

{ TClienteSincro }

constructor TClienteSincro.Create(AAlmacen: TAlmacenCliente;
  const AServicio: IServicioSincro);
begin
  inherited Create;
  FAlmacen := AAlmacen;
  FServicio := AServicio;
  FTamanoLote := 20;
  FTamanoPagina := 50;
  FEsperaMaxima := 60;
  FCursorConfirmado := 0;
end;

function TClienteSincro.EsperaReintento(AIntentos: Integer): Int64;
begin
  // 1, 2, 4, 8 ... hasta EsperaMaxima.
  Result := 1;
  while (AIntentos > 1) and (Result < FEsperaMaxima) do
  begin
    Result := Result * 2;
    Dec(AIntentos);
  end;
  if Result > FEsperaMaxima then
    Result := FEsperaMaxima;
end;

function TClienteSincro.SubirVentas(AAhora: Int64): Boolean;
var
  aLote: TVentasSincro;
  oRespuesta: TRespuestaVentas;
  oEntrada: TEntradaSalida;
  iIndice: Integer;
begin
  Result := True;
  aLote := FAlmacen.Pendientes(AAhora, FTamanoLote);
  while Length(aLote) > 0 do
  begin
    Inc(FEstadisticas.LotesEnviados);
    try
      oRespuesta := FServicio.EnviarVentas(FAlmacen.Terminal, aLote);
    except
      on E: ETransporteSincro do
      begin
        // No sabemos si el servidor llegó a guardar el lote. Da igual:
        // al reenviar con el mismo IdEvento responderá REPETIDA.
        Inc(FEstadisticas.FallosEnvio);
        FUltimoError := E.Message;
        for iIndice := 0 to High(aLote) do
        begin
          oEntrada := FAlmacen.Buscar(aLote[iIndice].IdEvento);
          Inc(oEntrada.Intentos);
          oEntrada.ProximoIntento :=
            AAhora + EsperaReintento(oEntrada.Intentos);
        end;
        Exit(False);
      end;
    end;
    for iIndice := 0 to High(oRespuesta.Acks) do
    begin
      oEntrada := FAlmacen.Buscar(oRespuesta.Acks[iIndice].IdEvento);
      if (oEntrada = nil) or (oEntrada.Estado <> esPendiente) then
        Continue; // acuse desconocido o ya tratado: se ignora
      case oRespuesta.Acks[iIndice].Resultado of
        rvAceptada, rvRepetida:
          begin
            oEntrada.Estado := esConfirmada;
            Inc(FEstadisticas.VentasConfirmadas);
            if oRespuesta.Acks[iIndice].Resultado = rvRepetida then
              Inc(FEstadisticas.AcusesRepetida);
          end;
        rvRechazada:
          begin
            oEntrada.Estado := esRechazada;
            oEntrada.Motivo := oRespuesta.Acks[iIndice].Motivo;
            Inc(FEstadisticas.VentasRechazadas);
          end;
      end;
    end;
    // Las ventas del lote sin acuse siguen PENDIENTES y se reintentan.
    for iIndice := 0 to High(aLote) do
    begin
      oEntrada := FAlmacen.Buscar(aLote[iIndice].IdEvento);
      if oEntrada.Estado = esPendiente then
      begin
        Inc(oEntrada.Intentos);
        oEntrada.ProximoIntento :=
          AAhora + EsperaReintento(oEntrada.Intentos);
      end;
    end;
    aLote := FAlmacen.Pendientes(AAhora, FTamanoLote);
  end;
end;

function TClienteSincro.BajarNovedades: Boolean;
var
  oRespuesta: TRespuestaNovedades;
  iIndice: Integer;
  iCursorInicial: Int64;
begin
  Result := True;
  iCursorInicial := FAlmacen.Cursor;
  repeat
    try
      oRespuesta := FServicio.PedirNovedades(
        FAlmacen.Terminal, FAlmacen.Cursor, FTamanoPagina);
    except
      on E: ETransporteSincro do
      begin
        Inc(FEstadisticas.FallosNovedades);
        FUltimoError := E.Message;
        Result := False;
        Break; // lo ya aplicado queda aplicado; se confirma abajo
      end;
    end;
    for iIndice := 0 to High(oRespuesta.Novedades) do
      if oRespuesta.Novedades[iIndice].Version <= FAlmacen.Cursor then
        Inc(FEstadisticas.NovedadesIgnoradas)
      else
      begin
        FAlmacen.AplicarNovedad(oRespuesta.Novedades[iIndice]);
        Inc(FEstadisticas.NovedadesAplicadas);
      end;
  until not oRespuesta.HayMas;

  // Se confirma cuando el cursor local va por delante de lo último que
  // el servidor ha acusado (también tras un fallo parcial de la bajada).
  if FAlmacen.Cursor > FCursorConfirmado then
    try
      FServicio.ConfirmarNovedades(FAlmacen.Terminal, FAlmacen.Cursor);
      FCursorConfirmado := FAlmacen.Cursor;
    except
      on E: ETransporteSincro do
      begin
        Inc(FEstadisticas.FallosConfirmacion);
        FUltimoError := E.Message;
        Result := False;
      end;
    end;
  if iCursorInicial > FAlmacen.Cursor then
    raise Exception.Create('El cursor de novedades no puede retroceder');
end;

function TClienteSincro.Sincronizar(AAhora: Int64): Boolean;
var
  bSubida: Boolean;
  bBajada: Boolean;
begin
  Inc(FEstadisticas.Ciclos);
  FUltimoError := '';
  bSubida := SubirVentas(AAhora);
  // Las novedades se intentan aunque falle la subida: son canales
  // independientes y un precio nuevo no debe esperar a que suban ventas.
  bBajada := BajarNovedades;
  Result := bSubida and bBajada;
end;

end.
