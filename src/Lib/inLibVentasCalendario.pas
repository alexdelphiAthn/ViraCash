{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasCalendario                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caché de operaciones de caja agrupadas por día.                           }
{    Marca en el calendario los días con actividad sin reconsultar la BBDD.    }
{******************************************************************************}
unit inLibVentasCalendario;

// =============================================================================
//  inLibVentasCalendario
//
//  Caché de operaciones de caja agrupadas por día, pensado para destacar los
//  días con actividad en controles de calendario:
//    * JvMonthCalendar  (OnGetMonthBoldInfo  -> usa MaskBoldDelMes)
//    * cxDateEdit       (Properties.OnGetDayState -> usa AplicarEstiloDia)
//
//  La consulta a fza_caja_operaciones se hace UNA SOLA VEZ por mes y por
//  contexto de caja (empresa+almacén+caja). Si el usuario navega adelante y
//  atrás por el calendario los meses ya cargados no se vuelven a pedir a
//  MySQL. Si cambia el contexto de caja (Reconfigurar) el caché se vacía.
//
//  Uso típico (en FormCreate):
//      FVentasCal := TVentasCalendarioCache.Create(ConexionPrincipal);
//      FVentasCal.Reconfigurar(FEmpresa, FAlmacen, FCaja);
//
//  En el evento OnGetMonthBoldInfo del JvMonthCalendar:
//      MonthBoldInfo := FVentasCal.MaskBoldDelMes(Year, Month);
//
//  En Properties.OnGetDayState del cxDateEdit:
//      FVentasCal.AplicarEstiloDia(ADate, AFont, ABackgroundColor);
// =============================================================================

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, Generics.Collections,
  Vcl.Graphics, Vcl.ComCtrls,
  Uni, System.UITypes,
  inLibVentasCalendarioIntf;

type
  // ---------------------------------------------------------------------------
  // Datos de un día con operaciones
  // ---------------------------------------------------------------------------
  TVentasDia = class
  private
    FFecha: TDate;
    FTotalVentas: Integer;
    FTotalCobrado: Currency;
  public
    constructor Create(const AFecha: TDate;
                       ATotalVentas: Integer;
                       ATotalCobrado: Currency);
    function GetHintText: string;
    property Fecha:        TDate    read FFecha;
    property TotalVentas:  Integer  read FTotalVentas;
    property TotalCobrado: Currency read FTotalCobrado;
  end;

  // ---------------------------------------------------------------------------
  // Caché por contexto de caja
  // ---------------------------------------------------------------------------
  TVentasCalendarioCache = class
  private
    FConn: TUniConnection;
    FRepositorio: IRepositorioVentasCalendario;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FDias: TObjectDictionary<TDate, TVentasDia>;
    FMesesCargados: TList<Integer>;
    // Estilo aplicado a los días con ventas
    FColorFondoConVentas: TColor;
    FEstiloFuenteConVentas: TFontStyles;
    FColorFuenteConVentas: TColor;
    FUsarColorFuente: Boolean;
    function ContextoValido: Boolean;
    function CodigoMes(AYear, AMonth: Word): Integer; inline;
    procedure CargarMes(AYear, AMonth: Word);
  public
    constructor Create(
      AConn: TUniConnection;
      const ARepositorio: IRepositorioVentasCalendario);
    destructor  Destroy; override;
    procedure Reconfigurar(const AEmpresa, AAlmacen, ACaja: string);
    procedure InvalidarTodo;
    procedure InvalidarMes(AYear, AMonth: Word);
    function  HasSales(const AFecha: TDate): Boolean;
    function  GetVentasDia(const AFecha: TDate): TVentasDia;
    // Helper para JvMonthCalendar (modelo Win32 — máscara de bits)
    function  MaskBoldDelMes(AYear, AMonth: Word): Cardinal;
    // Helper para cxDateEdit.Properties.OnGetDayState
    procedure AplicarEstiloDia(const ADate: TDateTime;
                               AFont: TFont;
                               var ABackgroundColor: TColor);
    property Empresa: string read FEmpresa;
    property Almacen: string read FAlmacen;
    property Caja:    string read FCaja;
    // Personalización del estilo de los días con ventas
    property ColorFondoConVentas: TColor read FColorFondoConVentas
                                         write FColorFondoConVentas;
    property EstiloFuenteConVentas: TFontStyles read FEstiloFuenteConVentas
                                                write FEstiloFuenteConVentas;
    property ColorFuenteConVentas: TColor read FColorFuenteConVentas
                                          write FColorFuenteConVentas;
    property UsarColorFuente: Boolean read FUsarColorFuente
                                      write FUsarColorFuente;
  end;

implementation

uses
  System.DateUtils;

// =============================================================================
// TVentasDia
// =============================================================================

constructor TVentasDia.Create(const AFecha: TDate;
                              ATotalVentas: Integer;
                              ATotalCobrado: Currency);
begin
  inherited Create;
  FFecha        := AFecha;
  FTotalVentas  := ATotalVentas;
  FTotalCobrado := ATotalCobrado;
end;

function TVentasDia.GetHintText: string;
begin
  Result := Format('Total Ventas: %d' + sLineBreak + 'Total Cobrado: %s €',
                   [FTotalVentas, FormatFloat('#,##0.00', FTotalCobrado)]);
end;

// =============================================================================
// TVentasCalendarioCache
// =============================================================================

constructor TVentasCalendarioCache.Create(
  AConn: TUniConnection;
  const ARepositorio: IRepositorioVentasCalendario);
begin
  inherited Create;
  FConn          := AConn;
  FRepositorio   := ARepositorio;
  FDias          := TObjectDictionary<TDate, TVentasDia>.Create([doOwnsValues]);
  FMesesCargados := TList<Integer>.Create;
  // Estilo por defecto: día con ventas en negrita y fondo amarillo crema
  FColorFondoConVentas   := $00DFFFFF;
  FEstiloFuenteConVentas := [fsBold];
  FColorFuenteConVentas  := clNavy;
  FUsarColorFuente       := False;
end;

destructor TVentasCalendarioCache.Destroy;
begin
  FreeAndNil(FDias);
  FreeAndNil(FMesesCargados);
  inherited;
end;

procedure TVentasCalendarioCache.Reconfigurar(const AEmpresa,
                                                    AAlmacen,
                                                    ACaja: string);
begin
  if (AEmpresa = FEmpresa) and
     (AAlmacen = FAlmacen) and
     (ACaja    = FCaja) then
  begin
  end
  else
  begin
    FEmpresa := AEmpresa;
    FAlmacen := AAlmacen;
    FCaja := ACaja;
    InvalidarTodo;
  end;
end;

procedure TVentasCalendarioCache.InvalidarTodo;
begin
  FDias.Clear;
  FMesesCargados.Clear;
end;

procedure TVentasCalendarioCache.InvalidarMes(AYear, AMonth: Word);
var
  PrimerDia, UltimoDia: TDate;
  D: TDate;
  Cod: Integer;
begin
  Cod := CodigoMes(AYear, AMonth);
  FMesesCargados.Remove(Cod);
  PrimerDia := EncodeDate(AYear, AMonth, 1);
  UltimoDia := IncMonth(PrimerDia, 1) - 1;
  D := PrimerDia;
  while D <= UltimoDia do
  begin
    FDias.Remove(D);
    D := D + 1;
  end;
end;

function TVentasCalendarioCache.ContextoValido: Boolean;
begin
  Result := (Trim(FEmpresa) <> '') and
            (Trim(FAlmacen) <> '') and
            (Trim(FCaja)    <> '') and
            Assigned(FConn) and
            FConn.Connected;
end;

function TVentasCalendarioCache.CodigoMes(AYear, AMonth: Word): Integer;
begin
  Result := (Integer(AYear) * 100) + Integer(AMonth);
end;

procedure TVentasCalendarioCache.CargarMes(AYear, AMonth: Word);
var
  Dias: TVentasDiasResumen;
  Resumen: TVentasDiaResumen;
  PrimerDia, UltimoDia: TDate;
  IdMes: Integer;
  VentaDia: TVentasDia;
  F: TDate;
begin
  if ContextoValido then
  begin
  IdMes := CodigoMes(AYear, AMonth);
  if not FMesesCargados.Contains(IdMes) then
  begin
  PrimerDia := EncodeDate(AYear, AMonth, 1);
  UltimoDia := IncMonth(PrimerDia, 1);
  Dias := FRepositorio.CargarDiasConVentas(
    FEmpresa,
    FAlmacen,
    FCaja,
    PrimerDia,
    UltimoDia);
  for Resumen in Dias do
  begin
    F := DateOf(Resumen.Fecha);
    VentaDia := TVentasDia.Create(
                  F,
                  Resumen.TotalVentas,
                  Resumen.TotalCobrado);
    FDias.AddOrSetValue(F, VentaDia);
  end;
  FMesesCargados.Add(IdMes);
  end;
  end;
end;

function TVentasCalendarioCache.HasSales(const AFecha: TDate): Boolean;
var
  Y, M, D: Word;
begin
  DecodeDate(AFecha, Y, M, D);
  CargarMes(Y, M);
  Result := FDias.ContainsKey(DateOf(AFecha));
end;

function TVentasCalendarioCache.GetVentasDia(const AFecha: TDate): TVentasDia;
var
  Y, M, D: Word;
begin
  DecodeDate(AFecha, Y, M, D);
  CargarMes(Y, M);
  if not FDias.TryGetValue(DateOf(AFecha), Result) then
    Result := nil;
end;

// Bitmask de 31 bits — bit i = día i+1 en negrita.
// Formato esperado por JvMonthCalendar.OnGetMonthBoldInfo (modelo Win32).
function TVentasCalendarioCache.MaskBoldDelMes(AYear, AMonth: Word): Cardinal;
var
  Dia, Dias: Integer;
  Fecha: TDate;
begin
  Result := 0;
  CargarMes(AYear, AMonth);
  Dias := DaysInAMonth(AYear, AMonth);
  for Dia := 1 to Dias do
  begin
    Fecha := EncodeDate(AYear, AMonth, Dia);
    if FDias.ContainsKey(Fecha) then
      Result := Result or (Cardinal(1) shl (Dia - 1));
  end;
end;

// Pensado para asignarse a TcxDateEdit.Properties.OnGetDayState.
// El evento se dispara una vez por cada día visible y permite modificar
// la fuente y el color de fondo de la celda. AState (no presente aquí)
// es informativo y NO modificable en esta versión de DevExpress.
procedure TVentasCalendarioCache.AplicarEstiloDia(const ADate: TDateTime;
  AFont: TFont; var ABackgroundColor: TColor);
var
  F: TDate;
begin
  F := DateOf(ADate);
  CargarMes(YearOf(F), MonthOf(F));
  if FDias.ContainsKey(F) then
  begin
    if Assigned(AFont) then
    begin
      AFont.Style := AFont.Style + FEstiloFuenteConVentas;
      if FUsarColorFuente then
        AFont.Color := FColorFuenteConVentas;
    end;
    ABackgroundColor := FColorFondoConVentas;
  end;
end;

end.

