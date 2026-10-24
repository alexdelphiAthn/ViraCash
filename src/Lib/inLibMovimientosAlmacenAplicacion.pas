{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMovimientosAlmacenAplicacion                             }
{    Tipo:       Librería de aplicación                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta y escritura atómica de movimientos sin VCL ni UniDAC.            }
{******************************************************************************}
unit inLibMovimientosAlmacenAplicacion;

interface

type
  TAlmacenFiltroMovimiento = record
    Codigo: string;
    Nombre: string;
  end;
  TFiltroMovimientosAlmacen = record
    Anyos: TArray<Integer>;
    Almacenes: TArray<string>;
  end;
  TEstadoCargaMovimientos = (
    ecmCompletada,
    ecmCancelada,
    ecmLimiteSuperado
  );
  TResultadoCargaMovimientos = record
    Estado: TEstadoCargaMovimientos;
    Total: Integer;
    Leidos: Integer;
  end;
  TNotificacionCargaMovimientos = function(
    ALeidos, ATotal: Integer): Boolean of object;
  ILectorMovimientosAlmacen = interface
    ['{18D42EF5-658D-44DA-A384-57319D403D26}']
    function ObtenerAnyos: TArray<Integer>;
    function ObtenerAlmacenes: TArray<TAlmacenFiltroMovimiento>;
    procedure Preparar(const AFiltro: TFiltroMovimientosAlmacen);
    function Contar: Integer;
    procedure IniciarCarga(ATamanoBloque: Integer);
    function HayMovimiento: Boolean;
    procedure Siguiente;
    procedure FinalizarCarga;
  end;
  TMovimientoAlmacenEscritura = record
    Numero: string;
    TipoDocumento: string;
    SerieDocumento: string;
    NumeroDocumento: string;
    Linea: string;
    Empresa: string;
    Almacen: string;
    AlmacenContrapartida: string;
    Unidad: string;
    Articulo: string;
    TipoMovimiento: string;
    Cantidad: Double;
    CosteUnitario: Currency;
    Usuario: string;
    Fecha: TDateTime;
  end;
  IEscritorMovimientosAlmacen = interface
    ['{E6CBBD08-0412-435F-9AE0-1370F452B6AC}']
    procedure Guardar(const AMovimiento: TMovimientoAlmacenEscritura);
  end;
  IUnidadTrabajoMovimientosAlmacen = interface
    ['{9FF2F3A2-F620-4818-8321-18C005FA48C1}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  TComprobarCancelacionMovimientos = function(
    AProcesados, ATotal: Integer): Boolean of object;
  TResultadoEscrituraMovimientos = record
    Generados: Integer;
    Cancelada: Boolean;
  end;
  TServicioCargaMovimientosAlmacen = class
  private
    FLector: ILectorMovimientosAlmacen;
  public
    constructor Create(const ALector: ILectorMovimientosAlmacen);
    function Cargar(
      ALimite, ATamanoBloque, AIntervaloAviso: Integer;
      ANotificar: TNotificacionCargaMovimientos):
      TResultadoCargaMovimientos;
  end;
  TServicioEscrituraMovimientosAlmacen = class
  private
    FEscritor: IEscritorMovimientosAlmacen;
    FUnidadTrabajo: IUnidadTrabajoMovimientosAlmacen;
  public
    constructor Create(
      const AEscritor: IEscritorMovimientosAlmacen;
      const AUnidadTrabajo: IUnidadTrabajoMovimientosAlmacen);
    function Generar(
      const AMovimientos: TArray<TMovimientoAlmacenEscritura>;
      AComprobarCancelacion: TComprobarCancelacionMovimientos):
      TResultadoEscrituraMovimientos;
  end;

implementation

uses
  System.SysUtils;

constructor TServicioCargaMovimientosAlmacen.Create(
  const ALector: ILectorMovimientosAlmacen);
begin
  inherited Create;
  if ALector = nil then
    raise EArgumentNilException.Create('ALector');
  FLector := ALector;
end;

function TServicioCargaMovimientosAlmacen.Cargar(
  ALimite, ATamanoBloque, AIntervaloAviso: Integer;
  ANotificar: TNotificacionCargaMovimientos):
  TResultadoCargaMovimientos;
var
  DebeCancelar: Boolean;
begin
  Result := Default(TResultadoCargaMovimientos);
  if AIntervaloAviso <= 0 then
    raise EArgumentOutOfRangeException.Create('AIntervaloAviso');
  Result.Estado := ecmCompletada;
  Result.Total := FLector.Contar;
  if Result.Total > ALimite then
    Result.Estado := ecmLimiteSuperado
  else
  begin
    FLector.IniciarCarga(ATamanoBloque);
    try
      DebeCancelar := False;
      while FLector.HayMovimiento and not DebeCancelar do
      begin
        Inc(Result.Leidos);
        if Assigned(ANotificar) and
           ((Result.Leidos mod AIntervaloAviso) = 0) then
          DebeCancelar := ANotificar(Result.Leidos, Result.Total);
        if not DebeCancelar then
          FLector.Siguiente;
      end;
      if DebeCancelar then
        Result.Estado := ecmCancelada;
    finally
      FLector.FinalizarCarga;
    end;
  end;
end;

constructor TServicioEscrituraMovimientosAlmacen.Create(
  const AEscritor: IEscritorMovimientosAlmacen;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosAlmacen);
begin
  inherited Create;
  if AEscritor = nil then
    raise EArgumentNilException.Create('AEscritor');
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FEscritor := AEscritor;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TServicioEscrituraMovimientosAlmacen.Generar(
  const AMovimientos: TArray<TMovimientoAlmacenEscritura>;
  AComprobarCancelacion: TComprobarCancelacionMovimientos):
  TResultadoEscrituraMovimientos;
var
  I: Integer;
begin
  Result := Default(TResultadoEscrituraMovimientos);
  FUnidadTrabajo.Iniciar;
  try
    for I := 0 to Length(AMovimientos) - 1 do
    begin
      if not Result.Cancelada then
      begin
        FEscritor.Guardar(AMovimientos[I]);
        Inc(Result.Generados);
        if Assigned(AComprobarCancelacion) then
          Result.Cancelada := AComprobarCancelacion(
            Result.Generados,
            Length(AMovimientos));
      end;
    end;
    if Result.Cancelada then
      FUnidadTrabajo.Revertir
    else
      FUnidadTrabajo.Confirmar;
  except
    FUnidadTrabajo.Revertir;
    raise;
  end;
end;

end.
