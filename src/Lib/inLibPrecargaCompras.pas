{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrecargaCompras                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina el filtro previo por series sin abrir la lista de compras.       }
{******************************************************************************}
unit inLibPrecargaCompras;

interface

uses
  inLibPrecargaComprasIntf,
  inLibVentanaEmbebidaIntf;

type
  TPrecargaCompras = class
  private
    FRepositorio: IRepositorioPrecargaCompras;
    FComprobada: Boolean;
    FOfreceFiltro: Boolean;
    FSeriesSeleccionadas: TArray<string>;
    FHayRol: Boolean;
    FUltimoRol: TRolAperturaMantenimiento;
    FHayEstadoSuspendido: Boolean;
    FRolSuspendido: TRolAperturaMantenimiento;
    FOfreceFiltroSuspendido: Boolean;
    FSeriesSuspendidas: TArray<string>;
    function ObtenerSeriesSeleccionadas: TArray<string>;
    function ProponerSeriesIniciales(
      const ACatalogo: TSeriesPrecargaCompra): TArray<string>;
    function SeleccionarSeries(
      const ASeleccionar: TSeleccionarSeriesPrecarga;
      AProponerInicial: Boolean): Boolean;
    function PrepararPrimeraLista(
      const ASeleccionar: TSeleccionarSeriesPrecarga): Boolean;
    procedure LimpiarEstadoActual;
    procedure DescartarEstadoSuspendido;
    procedure RestaurarEstadoSuspendido;
  public
    constructor Create(const ARepositorio: IRepositorioPrecargaCompras);
    function Preparar(ARol: TRolAperturaMantenimiento;
      const ASeleccionar: TSeleccionarSeriesPrecarga): Boolean;
    function CambiarSeries(
      const ASeleccionar: TSeleccionarSeriesPrecarga): Boolean;
    procedure EstablecerFiltroUsuario(const ASeries: TArray<string>);
    procedure RespetarFiltroExistente;
    procedure PrepararBusquedaExterna;
    property OfreceFiltro: Boolean read FOfreceFiltro;
    property SeriesSeleccionadas: TArray<string>
      read ObtenerSeriesSeleccionadas;
  end;

implementation

uses
  System.SysUtils,
  inLibPrecargaMantenimientos;

constructor TPrecargaCompras.Create(
  const ARepositorio: IRepositorioPrecargaCompras);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

function TPrecargaCompras.ObtenerSeriesSeleccionadas: TArray<string>;
begin
  Result := Copy(FSeriesSeleccionadas);
end;

function TPrecargaCompras.ProponerSeriesIniciales(
  const ACatalogo: TSeriesPrecargaCompra): TArray<string>;
var
  iSerie: Integer;
  iAnyo: Integer;
  iAnyoMayor: Integer;
  iElegidas: Integer;
begin
  SetLength(Result, Length(ACatalogo));
  iAnyoMayor := 0;
  iElegidas := 0;
  for iSerie := 0 to High(ACatalogo) do
  begin
    iAnyo := AnyoEnSerie(ACatalogo[iSerie].Codigo);
    if iAnyo > iAnyoMayor then
    begin
      iAnyoMayor := iAnyo;
      iElegidas := 0;
    end;
    if (iAnyo > 0) and (iAnyo = iAnyoMayor) then
    begin
      Result[iElegidas] := ACatalogo[iSerie].Codigo;
      Inc(iElegidas);
    end;
  end;
  SetLength(Result, iElegidas);
  if (iElegidas = 0) and (Length(ACatalogo) > 0) then
    Result := [ACatalogo[0].Codigo];
end;

function TPrecargaCompras.SeleccionarSeries(
  const ASeleccionar: TSeleccionarSeriesPrecarga;
  AProponerInicial: Boolean): Boolean;
var
  aCatalogo: TSeriesPrecargaCompra;
  aSeleccion: TArray<string>;
  aNuevaSeleccion: TArray<string>;
begin
  if not Assigned(ASeleccionar) then
    raise EArgumentNilException.Create('ASeleccionar');
  aCatalogo := FRepositorio.ListarSeries;
  aCatalogo := Copy(aCatalogo);
  aSeleccion := ObtenerSeriesSeleccionadas;
  if AProponerInicial then
    aSeleccion := ProponerSeriesIniciales(aCatalogo);
  Result := ASeleccionar(aCatalogo, aSeleccion, aNuevaSeleccion);
  if Result then
    EstablecerFiltroUsuario(aNuevaSeleccion);
end;

function TPrecargaCompras.PrepararPrimeraLista(
  const ASeleccionar: TSeleccionarSeriesPrecarga): Boolean;
begin
  if not FOfreceFiltro then
    FOfreceFiltro := SuperaUmbralPrecarga(
      FRepositorio.ContarHastaUmbral([]));
  if FOfreceFiltro then
    Result := SeleccionarSeries(ASeleccionar, True)
  else
  begin
    FComprobada := True;
    Result := True;
  end;
end;

function TPrecargaCompras.Preparar(
  ARol: TRolAperturaMantenimiento;
  const ASeleccionar: TSeleccionarSeriesPrecarga): Boolean;
begin
  Result := True;
  if ARol = ramBusqueda then
    PrepararBusquedaExterna
  else
  begin
    if FHayEstadoSuspendido and (FRolSuspendido = ARol) then
      RestaurarEstadoSuspendido
    else
    begin
      if FHayRol and (FUltimoRol <> ARol) and
         (ARol = ramListaAdicional) then
      begin
        FRepositorio.QuitarFiltro;
        LimpiarEstadoActual;
      end;
      DescartarEstadoSuspendido;
    end;
    if DebeComprobarPrecargaInicial(ARol, FComprobada) then
      Result := PrepararPrimeraLista(ASeleccionar);
  end;
  FUltimoRol := ARol;
  FHayRol := True;
end;

function TPrecargaCompras.CambiarSeries(
  const ASeleccionar: TSeleccionarSeriesPrecarga): Boolean;
begin
  // Solo la oferta automática pendiente propone el último año.
  // Una petición manual parte de la selección vigente, incluidas todas.
  Result := SeleccionarSeries(ASeleccionar,
    FOfreceFiltro and not FComprobada);
end;

procedure TPrecargaCompras.EstablecerFiltroUsuario(
  const ASeries: TArray<string>);
var
  aAceptadas: TArray<string>;
begin
  // Ni el selector ni el repositorio conservan el array del estado.
  aAceptadas := Copy(ASeries);
  FRepositorio.AplicarSeries(Copy(aAceptadas));
  FSeriesSeleccionadas := aAceptadas;
  FComprobada := True;
  FOfreceFiltro := True;
  DescartarEstadoSuspendido;
end;

procedure TPrecargaCompras.PrepararBusquedaExterna;
var
  bSuspenderEstado: Boolean;
  aSeriesParaSuspender: TArray<string>;
begin
  bSuspenderEstado := FHayRol and (FUltimoRol <> ramBusqueda) and
    FComprobada;
  if bSuspenderEstado then
    aSeriesParaSuspender := Copy(FSeriesSeleccionadas);
  FRepositorio.QuitarFiltro;
  if bSuspenderEstado then
  begin
    FHayEstadoSuspendido := True;
    FRolSuspendido := FUltimoRol;
    FOfreceFiltroSuspendido := FOfreceFiltro;
    FSeriesSuspendidas := aSeriesParaSuspender;
  end;
  LimpiarEstadoActual;
  FUltimoRol := ramBusqueda;
  FHayRol := True;
end;

procedure TPrecargaCompras.RespetarFiltroExistente;
begin
  FComprobada := True;
  FOfreceFiltro := False;
  FSeriesSeleccionadas := nil;
  DescartarEstadoSuspendido;
end;

procedure TPrecargaCompras.LimpiarEstadoActual;
begin
  FSeriesSeleccionadas := nil;
  FOfreceFiltro := False;
  FComprobada := False;
end;

procedure TPrecargaCompras.DescartarEstadoSuspendido;
begin
  FHayEstadoSuspendido := False;
  FOfreceFiltroSuspendido := False;
  FSeriesSuspendidas := nil;
end;

procedure TPrecargaCompras.RestaurarEstadoSuspendido;
var
  aRestauradas: TArray<string>;
begin
  aRestauradas := Copy(FSeriesSuspendidas);
  // Un SQL de perfil respetado no se convierte en un filtro de series.
  if FOfreceFiltroSuspendido then
    FRepositorio.AplicarSeries(Copy(aRestauradas));
  FSeriesSeleccionadas := aRestauradas;
  FOfreceFiltro := FOfreceFiltroSuspendido;
  FComprobada := True;
  DescartarEstadoSuspendido;
end;

end.
