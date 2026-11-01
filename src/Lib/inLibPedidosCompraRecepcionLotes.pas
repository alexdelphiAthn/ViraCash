{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraRecepcionLotes                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lote, serie y caducidad al recibir un pedido de compra (FZ-ISSUE-434).   }
{    El pedido no lleva lote: se pide al dar entrada a la mercancía, antes    }
{    de crear el albarán o de incorporar las líneas a uno abierto. Decide     }
{    qué celdas necesitan datos, aplica los que da el usuario y valida lo     }
{    que se va a grabar. Con los interruptores apagados no hace nada.         }
{******************************************************************************}
unit inLibPedidosCompraRecepcionLotes;

interface

uses
  inLibTrazabilidad, inLibLotesPersistenciaIntf, inLibGridPivoteCompraTipos,
  inLibPedidosCompraRecepcionIntf;

type
  // Línea del pedido con unidades pendientes en el almacén que se recibe.
  TLineaPedidoRecepcionLote = record
    LineaPedido: string;
    CodigoArticulo: string;
    CodigoSku: string;
    Descripcion: string;
    TipoCantidad: string;
    Pendiente: Double;
    Lote: string;
    FechaCaducidad: TDate;
  end;
  TLineasPedidoRecepcionLote = TArray<TLineaPedidoRecepcionLote>;

  ILecturaLineasRecepcionPedidoCompra = interface
    ['{5B0C0A8E-0C1B-4D0E-9E8B-3D3C7B1E6A42}']
    function LineasPendientes(const ASeriePedido, ANumeroPedido,
      ACodigoAlmacen: string): TLineasPedidoRecepcionLote;
  end;

  // Celda que entraría en stock sin el lote, la serie o la caducidad que
  // exige su artículo.
  TPeticionLoteRecepcion = record
    IndiceCelda: Integer;
    CodigoArticulo: string;
    CodigoSku: string;
    Descripcion: string;
    TipoCantidad: string;
    Cantidad: Double;
    // Modo efectivo: mtLote o mtSerie.
    Modo: TModoTrazabilidad;
    ExigeCaducidad: Boolean;
    // Respuesta. En mtLote, Lote y FechaCaducidad (Lote llega relleno si
    // solo falta la caducidad); en mtSerie, una serie por unidad.
    Lote: string;
    FechaCaducidad: TDate;
    Series: TArray<string>;
  end;
  TPeticionesLoteRecepcion = TArray<TPeticionLoteRecepcion>;

  IPeticionLotesRecepcionVisual = interface
    ['{C2B0F5B1-6B5E-4E0B-8C0F-5B6E9B7C1D23}']
    // False = el usuario cancela (no se recibe nada).
    function Pedir(var APeticion: TPeticionLoteRecepcion): Boolean;
  end;

  // Paso previo a la recepción: completa las celdas con sus lotes.
  ICompletadoLotesRecepcionPedidoCompra = interface
    ['{7E0B8C55-70A5-4B0C-9D3A-0A9B1F3E5C64}']
    // False = cancelado.
    function Completar(
      var AParametros: TParametrosRecepcionPedidoCompra): Boolean;
  end;

// Lo que se va a recibir: las celdas con cantidad del almacén o, si no hay
// ninguna, todo lo pendiente (una celda por línea).
function CeldasEfectivasRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const ALineas: TLineasPedidoRecepcionLote;
  const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
function PeticionesLoteRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const ALineas: TLineasPedidoRecepcionLote;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo): TPeticionesLoteRecepcion;
// Cada celda con su lote y caducidad; la de un artículo con serie se parte
// en una celda de una unidad por serie.
function AplicarLotesRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const APeticiones: TPeticionesLoteRecepcion): TArray<TCeldaARecibir>;
// '' si todo lo que se recibe lleva el lote, la serie y la caducidad que
// pide su artículo; si no, el texto que se muestra. ACeldas como en
// CeldasEfectivasRecepcion.
function ValidarLotesRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const ALineas: TLineasPedidoRecepcionLote;
  const ACodigoAlmacen: string;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo): string;
function CrearCompletadoLotesRecepcionPedidoCompra(
  const ALineas: ILecturaLineasRecepcionPedidoCompra;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo;
  const AVisual: IPeticionLotesRecepcionVisual):
  ICompletadoLotesRecepcionPedidoCompra;

implementation

uses
  System.SysUtils, System.Generics.Collections, inLibLotesLineaDocumento,
  inLibMsgTrazabilidad;

const
  // Problemas que se enumeran; del resto solo se da la cuenta.
  MAXIMO_LINEAS_LISTADAS = 10;

type
  TCompletadoLotesRecepcionPedidoCompra = class(TInterfacedObject,
    ICompletadoLotesRecepcionPedidoCompra)
  private
    FLineas: ILecturaLineasRecepcionPedidoCompra;
    FActivacion: TActivacionTrazabilidad;
    FLectura: ILecturaTrazabilidadArticulo;
    FVisual: IPeticionLotesRecepcionVisual;
  public
    constructor Create(const ALineas: ILecturaLineasRecepcionPedidoCompra;
      const AActivacion: TActivacionTrazabilidad;
      const ALectura: ILecturaTrazabilidadArticulo;
      const AVisual: IPeticionLotesRecepcionVisual);
    function Completar(
      var AParametros: TParametrosRecepcionPedidoCompra): Boolean;
  end;

function BuscarLinea(const ALineas: TLineasPedidoRecepcionLote;
  const ALineaPedido: string; out ALinea: TLineaPedidoRecepcionLote): Boolean;
var
  rLinea: TLineaPedidoRecepcionLote;
begin
  Result := False;
  ALinea := Default(TLineaPedidoRecepcionLote);
  for rLinea in ALineas do
  begin
    if (not Result) and SameText(rLinea.LineaPedido, ALineaPedido) then
    begin
      ALinea := rLinea;
      Result := True;
    end;
  end;
end;

function CeldasEfectivasRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const ALineas: TLineasPedidoRecepcionLote;
  const ACodigoAlmacen: string): TArray<TCeldaARecibir>;
var
  rCelda: TCeldaARecibir;
  rLinea: TLineaPedidoRecepcionLote;
begin
  Result := [];
  for rCelda in ACeldas do
  begin
    if SameText(rCelda.CodigoAlmacen, ACodigoAlmacen) and
       (rCelda.Cantidad > 0) then
      Result := Result + [rCelda];
  end;
  if Length(Result) = 0 then
  begin
    for rLinea in ALineas do
    begin
      if rLinea.Pendiente > 0 then
      begin
        rCelda := Default(TCeldaARecibir);
        rCelda.LineaPedido := rLinea.LineaPedido;
        rCelda.CodigoSku := rLinea.CodigoSku;
        rCelda.CodigoAlmacen := ACodigoAlmacen;
        rCelda.Cantidad := rLinea.Pendiente;
        Result := Result + [rCelda];
      end;
    end;
  end;
end;

// Lote y caducidad con que se grabaría la celda: los suyos o, si no trae,
// los de la línea del pedido.
procedure LoteDeCelda(const ACelda: TCeldaARecibir;
  const ALinea: TLineaPedidoRecepcionLote; out ALote: string;
  out AFechaCaducidad: TDate);
begin
  ALote := NormalizarLote(ACelda.Lote);
  AFechaCaducidad := Trunc(ACelda.FechaCaducidad);
  if ALote = '' then
  begin
    ALote := NormalizarLote(ALinea.Lote);
    AFechaCaducidad := ALinea.FechaCaducidad;
  end;
end;

// Validación de una celda con el modo efectivo de su artículo. La
// Solo se exigen datos de lote o serie al recibir mercancía.
function ValidarCelda(const ACelda: TCeldaARecibir;
  const ALinea: TLineaPedidoRecepcionLote;
  const AActivacion: TActivacionTrazabilidad;
  const ATrazabilidad: TTrazabilidadArticulo;
  out AModo: TModoTrazabilidad): TValidacionLineaLote;
var
  dtCaducidad: TDate;
  sLote: string;
begin
  Result := vllCorrecta;
  AModo := AActivacion.ModoEfectivo(ATrazabilidad.Modo);
  if AModo in [mtLote, mtSerie] then
  begin
    LoteDeCelda(ACelda, ALinea, sLote, dtCaducidad);
    Result := ValidarLineaLote(AModo, ATrazabilidad.EsCaducidadObligatoria,
      sLote, dtCaducidad, ACelda.Cantidad);
  end;
end;

function PeticionesLoteRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const ALineas: TLineasPedidoRecepcionLote;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo): TPeticionesLoteRecepcion;
var
  dtCaducidad: TDate;
  iCelda: Integer;
  oModo: TModoTrazabilidad;
  rLinea: TLineaPedidoRecepcionLote;
  rPeticion: TPeticionLoteRecepcion;
  rTrazabilidad: TTrazabilidadArticulo;
  sLote: string;
begin
  Result := [];
  if AActivacion.AlgunModoActivo then
  begin
    if not Assigned(ALectura) then
      raise EArgumentNilException.Create('ALectura');
    for iCelda := 0 to High(ACeldas) do
    begin
      if BuscarLinea(ALineas, ACeldas[iCelda].LineaPedido, rLinea) and
         (Trim(rLinea.CodigoArticulo) <> '') then
      begin
        rTrazabilidad := ALectura.Leer(rLinea.CodigoArticulo);
        if ValidarCelda(ACeldas[iCelda], rLinea, AActivacion, rTrazabilidad,
                        oModo) <> vllCorrecta then
        begin
          LoteDeCelda(ACeldas[iCelda], rLinea, sLote, dtCaducidad);
          rPeticion := Default(TPeticionLoteRecepcion);
          rPeticion.IndiceCelda := iCelda;
          rPeticion.CodigoArticulo := rLinea.CodigoArticulo;
          rPeticion.CodigoSku := ACeldas[iCelda].CodigoSku;
          rPeticion.Descripcion := rLinea.Descripcion;
          rPeticion.TipoCantidad := rLinea.TipoCantidad;
          rPeticion.Cantidad := ACeldas[iCelda].Cantidad;
          rPeticion.Modo := oModo;
          rPeticion.ExigeCaducidad := RequiereCaducidad(oModo,
            rTrazabilidad.EsCaducidadObligatoria);
          if oModo = mtLote then
          begin
            rPeticion.Lote := sLote;
            rPeticion.FechaCaducidad := dtCaducidad;
          end;
          Result := Result + [rPeticion];
        end;
      end;
    end;
  end;
end;

function AplicarLotesRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const APeticiones: TPeticionesLoteRecepcion): TArray<TCeldaARecibir>;
var
  bPedida: Boolean;
  iCelda: Integer;
  rCelda: TCeldaARecibir;
  rPeticion: TPeticionLoteRecepcion;
  sSerie: string;
begin
  Result := [];
  for iCelda := 0 to High(ACeldas) do
  begin
    bPedida := False;
    for rPeticion in APeticiones do
    begin
      if (not bPedida) and (rPeticion.IndiceCelda = iCelda) then
      begin
        bPedida := True;
        rCelda := ACeldas[iCelda];
        if rPeticion.Modo = mtSerie then
        begin
          // Una celda de una unidad por serie; lo que no tenga serie
          // sigue pendiente en el pedido.
          for sSerie in rPeticion.Series do
          begin
            rCelda.Lote := NormalizarLote(sSerie);
            rCelda.FechaCaducidad := SIN_FECHA;
            rCelda.Cantidad := 1;
            Result := Result + [rCelda];
          end;
        end
        else
        begin
          rCelda.Lote := NormalizarLote(rPeticion.Lote);
          rCelda.FechaCaducidad := rPeticion.FechaCaducidad;
          Result := Result + [rCelda];
        end;
      end;
    end;
    if not bPedida then
      Result := Result + [ACeldas[iCelda]];
  end;
end;

function ValidarLotesRecepcion(const ACeldas: TArray<TCeldaARecibir>;
  const ALineas: TLineasPedidoRecepcionLote;
  const ACodigoAlmacen: string;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo): string;
var
  dtCaducidad: TDate;
  iProblemas: Integer;
  oModo: TModoTrazabilidad;
  oValidacion: TValidacionLineaLote;
  rCelda: TCeldaARecibir;
  rLinea: TLineaPedidoRecepcionLote;
  sLote: string;
begin
  Result := '';
  iProblemas := 0;
  if AActivacion.AlgunModoActivo then
  begin
    if not Assigned(ALectura) then
      raise EArgumentNilException.Create('ALectura');
    for rCelda in CeldasEfectivasRecepcion(ACeldas, ALineas,
                                           ACodigoAlmacen) do
    begin
      if BuscarLinea(ALineas, rCelda.LineaPedido, rLinea) and
         (Trim(rLinea.CodigoArticulo) <> '') then
      begin
        oValidacion := ValidarCelda(rCelda, rLinea, AActivacion,
          ALectura.Leer(rLinea.CodigoArticulo), oModo);
        if oValidacion <> vllCorrecta then
        begin
          Inc(iProblemas);
          LoteDeCelda(rCelda, rLinea, sLote, dtCaducidad);
          if iProblemas <= MAXIMO_LINEAS_LISTADAS then
            Result := Result + sLineBreak + Format(SErrorLineaNumeroLote,
              [rCelda.LineaPedido, TextoValidacionLineaLote(oValidacion,
                rCelda.CodigoSku, sLote)]);
        end;
      end;
    end;
  end;
  if iProblemas > MAXIMO_LINEAS_LISTADAS then
    Result := Result + sLineBreak + Format(SErrorMasLineasSinLote,
      [iProblemas - MAXIMO_LINEAS_LISTADAS]);
  if Result <> '' then
    Result := SErrorRecepcionPedidoLineasSinLote + sLineBreak + Result;
end;

{ TCompletadoLotesRecepcionPedidoCompra }

constructor TCompletadoLotesRecepcionPedidoCompra.Create(
  const ALineas: ILecturaLineasRecepcionPedidoCompra;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo;
  const AVisual: IPeticionLotesRecepcionVisual);
begin
  inherited Create;
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create('ALineas');
  if not Assigned(AVisual) then
    raise EArgumentNilException.Create('AVisual');
  FLineas := ALineas;
  FActivacion := AActivacion;
  FLectura := ALectura;
  FVisual := AVisual;
end;

function TCompletadoLotesRecepcionPedidoCompra.Completar(
  var AParametros: TParametrosRecepcionPedidoCompra): Boolean;
var
  aCeldas: TArray<TCeldaARecibir>;
  aLineas: TLineasPedidoRecepcionLote;
  aPeticiones: TPeticionesLoteRecepcion;
  iPeticion: Integer;
begin
  Result := True;
  if FActivacion.AlgunModoActivo then
  begin
    aLineas := FLineas.LineasPendientes(AParametros.SeriePedido,
      AParametros.NumeroPedido, AParametros.CodigoAlmacen);
    aCeldas := CeldasEfectivasRecepcion(AParametros.Celdas, aLineas,
      AParametros.CodigoAlmacen);
    aPeticiones := PeticionesLoteRecepcion(aCeldas, aLineas, FActivacion,
      FLectura);
    for iPeticion := 0 to High(aPeticiones) do
    begin
      if Result then
        Result := FVisual.Pedir(aPeticiones[iPeticion]);
    end;
    // Sin peticiones las celdas no cambian (vacías = todo lo pendiente).
    if Result and (Length(aPeticiones) > 0) then
      AParametros.Celdas := AplicarLotesRecepcion(aCeldas, aPeticiones);
  end;
end;

function CrearCompletadoLotesRecepcionPedidoCompra(
  const ALineas: ILecturaLineasRecepcionPedidoCompra;
  const AActivacion: TActivacionTrazabilidad;
  const ALectura: ILecturaTrazabilidadArticulo;
  const AVisual: IPeticionLotesRecepcionVisual):
  ICompletadoLotesRecepcionPedidoCompra;
begin
  Result := TCompletadoLotesRecepcionPedidoCompra.Create(ALineas,
    AActivacion, ALectura, AVisual);
end;

end.
